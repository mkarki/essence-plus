const express = require('express');
const prisma = require('../services/prisma');
const { authMiddleware } = require('../middleware/auth');
const rateLimit = require('express-rate-limit');

const router = express.Router();

// Rate limit: max 60 session submissions per hour
const sessionLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 60,
  keyGenerator: (req) => req.userId,
  message: { error: 'Too many game sessions, try again later' },
});

// Anti-cheat thresholds
// Hormuz Run: barrels can spike from offshore platforms (+50 each, ~every 30s)
// in addition to drops. Threshold raised so legit platform grazes don't trip
// the rate check; daily/score caps still apply.
const MAX_FUEL_PER_SECOND = 8.0;
const MAX_SESSIONS_PER_DAY = 50;
const MIN_DURATION_SECONDS = 10;
const MAX_SCORE_PER_METER = 12;

// POST /api/game/session - submit game results
router.post('/session', authMiddleware, sessionLimiter, async (req, res) => {
  try {
    const { fuelCollected, score, distanceMeters, durationSeconds, obstaclesDodged } = req.body;
    const userId = req.userId;

    // Basic validation
    if (fuelCollected == null || score == null || distanceMeters == null || durationSeconds == null) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // --- Anti-cheat checks ---

    // 1. Duration too short
    if (durationSeconds < MIN_DURATION_SECONDS) {
      return res.status(400).json({ error: 'Session too short', valid: false });
    }

    // 2. Fuel rate check
    const fuelRate = fuelCollected / durationSeconds;
    let flaggedSuspicious = false;

    if (fuelRate > MAX_FUEL_PER_SECOND) {
      flaggedSuspicious = true;
    }

    // 3. Score/distance ratio
    if (distanceMeters > 0 && score / distanceMeters > MAX_SCORE_PER_METER) {
      flaggedSuspicious = true;
    }

    // 4. Daily session limit
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayCount = await prisma.gameSession.count({
      where: {
        userId,
        createdAt: { gte: todayStart },
      },
    });

    if (todayCount >= MAX_SESSIONS_PER_DAY) {
      return res.status(429).json({ error: 'Daily session limit reached', valid: false });
    }

    // If suspicious, record but don't credit fuel
    if (flaggedSuspicious) {
      await prisma.gameSession.create({
        data: {
          userId,
          fuelCollected,
          score,
          distanceMeters,
          durationSeconds,
          obstaclesDodged: obstaclesDodged || 0,
          serverValidated: false,
          flaggedSuspicious: true,
        },
      });
      return res.status(400).json({ error: 'Suspicious activity detected', valid: false });
    }

    // --- Valid session: record + credit fuel ---
    const [session, fuelBalance] = await prisma.$transaction(async (tx) => {
      // Insert game session
      const session = await tx.gameSession.create({
        data: {
          userId,
          fuelCollected,
          score,
          distanceMeters,
          durationSeconds,
          obstaclesDodged: obstaclesDodged || 0,
          serverValidated: true,
          flaggedSuspicious: false,
        },
      });

      // Increment fuel balance (capped at tank capacity)
      const currentBalance = await tx.fuelBalance.findUnique({
        where: { userId },
      });

      const cap = currentBalance?.tankCapacity || 1000;
      const currentFuel = currentBalance?.currentFuel || 0;
      const newFuel = Math.min(currentFuel + fuelCollected, cap);

      const fuelBalance = await tx.fuelBalance.upsert({
        where: { userId },
        update: {
          currentFuel: newFuel,
          lastUpdated: new Date(),
        },
        create: {
          userId,
          currentFuel: fuelCollected,
          tankCapacity: 1000,
        },
      });

      // Update profile stats
      await tx.user.update({
        where: { id: userId },
        data: {
          totalFuelCollected: { increment: fuelCollected },
          gamesPlayed: { increment: 1 },
        },
      });

      return [session, fuelBalance];
    });

    res.json({
      valid: true,
      session: {
        id: session.id,
        score: session.score,
        fuelCollected: session.fuelCollected,
      },
      fuelBalance: {
        user_id: fuelBalance.userId,
        current_fuel: fuelBalance.currentFuel,
        tank_capacity: fuelBalance.tankCapacity,
        last_updated: fuelBalance.lastUpdated.toISOString(),
      },
    });
  } catch (err) {
    console.error('Session submit error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/game/balance - get fuel balance
router.get('/balance', authMiddleware, async (req, res) => {
  try {
    const balance = await prisma.fuelBalance.findUnique({
      where: { userId: req.userId },
    });

    if (!balance) {
      return res.json({
        user_id: req.userId,
        current_fuel: 0,
        tank_capacity: 1000,
        last_updated: new Date().toISOString(),
      });
    }

    res.json({
      user_id: balance.userId,
      current_fuel: balance.currentFuel,
      tank_capacity: balance.tankCapacity,
      last_updated: balance.lastUpdated.toISOString(),
    });
  } catch (err) {
    console.error('Balance error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/game/sessions - get recent sessions
router.get('/sessions', authMiddleware, async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);

    const sessions = await prisma.gameSession.findMany({
      where: { userId: req.userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    res.json({ sessions });
  } catch (err) {
    console.error('Sessions error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/game/leaderboard
router.get('/leaderboard', async (req, res) => {
  try {
    const leaders = await prisma.user.findMany({
      select: {
        displayName: true,
        totalFuelCollected: true,
        gamesPlayed: true,
        vouchersEarned: true,
      },
      orderBy: { totalFuelCollected: 'desc' },
      take: 100,
    });

    res.json({ leaderboard: leaders });
  } catch (err) {
    console.error('Leaderboard error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
