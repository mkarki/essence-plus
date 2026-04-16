const express = require('express');
const prisma = require('../services/prisma');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

const VOUCHER_COOLDOWN_HOURS = 48;

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
