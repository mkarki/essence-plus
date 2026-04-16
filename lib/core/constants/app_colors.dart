import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary palette - "Neon Fuel" theme
  static const electricOrange = Color(0xFFFF6B00);
  static const petroleumBlue = Color(0xFF0A1628);
  static const neonGreen = Color(0xFF39FF14);
  static const darkCharcoal = Color(0xFF1A1A2E);
  static const hotRed = Color(0xFFFF2D2D);
  static const amberGold = Color(0xFFFFD700);

  // Hormuz maritime palette
  static const oceanDeep = Color(0xFF06121F);
  static const oceanMid = Color(0xFF0F2238);
  static const oceanFoam = Color(0xFFB8D4E3);
  static const tankerOrange = Color(0xFFE85A1A);
  static const tankerDeck = Color(0xFFCC4915);
  static const hazardRed = Color(0xFFE63946);
  static const politicalAmber = Color(0xFFF4A261);
  static const civilianGray = Color(0xFF8896A6);
  static const naturalTeal = Color(0xFF2EC4B6);

  // Text
  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFF8892A0);

  // Surfaces
  static const surface = darkCharcoal;
  static const surfaceLight = Color(0xFF242442);
  static const background = petroleumBlue;

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [electricOrange, amberGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const fuelGaugeGradient = LinearGradient(
    colors: [hotRed, electricOrange, neonGreen],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const cardBorderGradient = LinearGradient(
    colors: [electricOrange, petroleumBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
