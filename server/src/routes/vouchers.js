const express = require('express');
const prisma = require('../services/prisma');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

const VOUCHER_COOLDOWN_HOURS = 48;

// Lottery config
const LOTTERY_MIN_SCORE = 500;
const LOTTERY_BASE_PERCENT_PER_100 = 1; // 1% per 100 score
const LOTTERY_MAX_BASE_PERCENT = 15;
const LOTTERY_AD_BONUS_PERCENT = 10;
const LOTTERY_MAX_PERCENT = 30;
const LOTTERY_COOLDOWN_HOURS = 24;

function computeLotteryChance({ score, adWatched }) {
  if (score < LOTTERY_MIN_SCORE) return 0;
  const base = Math.min(
    LOTTERY_MAX_BASE_PERCENT,
    Math.floor(score / 100) * LOTTERY_BASE_PERCENT_PER_100
  );
  const bonus = adWatched ? LOTTERY_AD_BONUS_PERCENT : 0;
  return Math.min(LOTTERY_MAX_PERCENT, base + bonus);
}

// POST /api/vouchers/lottery - tirage au sort d'un bon apres une partie
router.post('/lottery', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { sessionId, adWatched } = req.body;

    if (!sessionId) {
      return res.status(400).json({ error: 'sessionId required' });
    }

    // 1. Load session and verify ownership + validation
    const session = await prisma.gameSession.findUnique({
      where: { id: sessionId },
    });

    if (!session || session.userId !== userId) {
      return res.status(404).json({ error: 'Session not found' });
    }
    if (!session.serverValidated || session.flaggedSuspicious) {
      return res.status(400).json({ error: 'Session not eligible' });
    }

    // 2. Cooldown: user can only do lottery once per N hours
    const cooldownStart = new Date(
      Date.now() - LOTTERY_COOLDOWN_HOURS * 60 * 60 * 1000
    );
    const recentLotteryWin = await prisma.voucher.findFirst({
      where: {
        claimedById: userId,
        claimedAt: { gte: cooldownStart },
      },
    });
    if (recentLotteryWin) {
      return res.status(429).json({
        error: 'Lottery cooldown active',
        availableAt: new Date(
          recentLotteryWin.claimedAt.getTime() +
            LOTTERY_COOLDOWN_HOURS * 60 * 60 * 1000
        ).toISOString(),
      });
    }

    // 3. Compute chance server-side (client-sent score is ignored)
    const chancePercent = computeLotteryChance({
      score: session.score,
      adWatched: adWatched === true,
    });

    if (chancePercent === 0) {
      return res.json({
        won: false,
        chancePercent: 0,
        reason: 'score_too_low',
        minScore: LOTTERY_MIN_SCORE,
      });
    }

    // 4. Roll the dice
    const roll = Math.random() * 100;
    const won = roll < chancePercent;

    if (!won) {
      return res.json({
        won: false,
        chancePercent,
        roll: Math.round(roll * 10) / 10,
      });
    }

    // 5. Won! Atomically pick + claim a voucher
    const voucher = await prisma.$transaction(async (tx) => {
      const available = await tx.voucher.findFirst({
        where: {
          status: 'available',
          expiresAt: { gt: new Date() },
        },
      });
      if (!available) throw new Error('NO_VOUCHERS');

      const claimed = await tx.voucher.update({
        where: { id: available.id },
        data: {
          status: 'claimed',
          claimedById: userId,
          claimedAt: new Date(),
        },
      });

      await tx.user.update({
        where: { id: userId },
        data: { vouchersEarned: { increment: 1 } },
      });

      return claimed;
    });

    res.json({
      won: true,
      chancePercent,
      voucher: {
        id: voucher.id,
        code: voucher.code,
        value_amount: voucher.valueAmount,
        currency: voucher.currency,
        station_partner: voucher.stationPartner,
        status: voucher.status,
        claimed_at: voucher.claimedAt?.toISOString(),
        expires_at: voucher.expiresAt.toISOString(),
        created_at: voucher.createdAt.toISOString(),
      },
    });
  } catch (err) {
    if (err.message === 'NO_VOUCHERS') {
      return res.status(404).json({ error: 'No vouchers available' });
    }
    console.error('Lottery error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/vouchers/claim - claim a voucher when tank is full
router.post('/claim', authMiddleware, async (req, res) => {
  try {
    const userId = req.userId;

    // 1. Check fuel balance
    const balance = await prisma.fuelBalance.findUnique({
      where: { userId },
    });

    if (!balance || balance.currentFuel < balance.tankCapacity) {
      return res.status(400).json({
        error: 'Tank not full',
        current: balance?.currentFuel || 0,
        required: balance?.tankCapacity || 1000,
      });
    }

    // 2. Check cooldown
    const lastVoucher = await prisma.voucher.findFirst({
      where: { claimedById: userId },
      orderBy: { claimedAt: 'desc' },
    });

    if (lastVoucher?.claimedAt) {
      const cooldownEnd = new Date(
        lastVoucher.claimedAt.getTime() + VOUCHER_COOLDOWN_HOURS * 60 * 60 * 1000
      );
      if (new Date() < cooldownEnd) {
        return res.status(429).json({
          error: 'Cooldown active',
          availableAt: cooldownEnd.toISOString(),
        });
      }
    }

    // 3. Atomic transaction: find voucher + claim + reset fuel
    const result = await prisma.$transaction(async (tx) => {
      // Find an available, non-expired voucher
      const voucher = await tx.voucher.findFirst({
        where: {
          status: 'available',
          expiresAt: { gt: new Date() },
        },
      });

      if (!voucher) {
        throw new Error('NO_VOUCHERS');
      }

      // Claim the voucher
      const claimed = await tx.voucher.update({
        where: { id: voucher.id },
        data: {
          status: 'claimed',
          claimedById: userId,
          claimedAt: new Date(),
        },
      });

      // Reset fuel balance
      await tx.fuelBalance.update({
        where: { userId },
        data: {
          currentFuel: 0,
          lastUpdated: new Date(),
        },
      });

      // Record redemption
      await tx.voucherRedemption.create({
        data: {
          voucherId: voucher.id,
          userId,
          fuelSpent: balance.tankCapacity,
        },
      });

      // Update profile voucher count
      await tx.user.update({
        where: { id: userId },
        data: { vouchersEarned: { increment: 1 } },
      });

      return claimed;
    });

    res.json({
      success: true,
      voucher: {
        id: result.id,
        code: result.code,
        value_amount: result.valueAmount,
        currency: result.currency,
        station_partner: result.stationPartner,
        status: result.status,
        claimed_at: result.claimedAt?.toISOString(),
        expires_at: result.expiresAt.toISOString(),
        created_at: result.createdAt.toISOString(),
      },
    });
  } catch (err) {
    if (err.message === 'NO_VOUCHERS') {
      return res.status(404).json({ error: 'No vouchers available' });
    }
    console.error('Claim voucher error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/vouchers - get my vouchers
router.get('/', authMiddleware, async (req, res) => {
  try {
    const vouchers = await prisma.voucher.findMany({
      where: { claimedById: req.userId },
      orderBy: { claimedAt: 'desc' },
    });

    res.json({
      vouchers: vouchers.map((v) => ({
        id: v.id,
        code: v.code,
        value_amount: v.valueAmount,
        currency: v.currency,
        station_partner: v.stationPartner,
        status: v.status,
        claimed_at: v.claimedAt?.toISOString(),
        expires_at: v.expiresAt.toISOString(),
        created_at: v.createdAt.toISOString(),
      })),
    });
  } catch (err) {
    console.error('Get vouchers error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
