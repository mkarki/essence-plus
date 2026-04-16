const express = require('express');
const prisma = require('../services/prisma');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// GET /api/profile
router.get('/', authMiddleware, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      select: {
        id: true,
        email: true,
        displayName: true,
        avatarUrl: true,
        totalFuelCollected: true,
        gamesPlayed: true,
        vouchersEarned: true,
        createdAt: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user });
  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PATCH /api/profile
router.patch('/', authMiddleware, async (req, res) => {
  try {
    const { displayName, avatarUrl } = req.body;
    const data = {};
    if (displayName) data.displayName = displayName;
    if (avatarUrl !== undefined) data.avatarUrl = avatarUrl;

    const user = await prisma.user.update({
      where: { id: req.userId },
      data,
      select: {
        id: true,
        email: true,
        displayName: true,
        avatarUrl: true,
        totalFuelCollected: true,
        gamesPlayed: true,
        vouchersEarned: true,
      },
    });

    res.json({ user });
  } catch (err) {
    console.error('Profile update error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
