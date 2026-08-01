import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background   = Color(0xFFFAFAFA); // Light off-white
  static const Color surface      = Color(0xFFFFFFFF); // White cards
  static const Color surfaceLight = Color(0xFFF5F7FA);

  // Accents
  static const Color electricBlue = Color(0xFF4F8EF7);
  static const Color emeraldGreen = Color(0xFF059669); // Main brand green
  static const Color purpleAccent = Color(0xFFA78BFA);
  static const Color premiumGold  = Color(0xFFFBBF24);
  static const Color coral        = Color(0xFFFF6B6B);
  static const Color orange       = Color(0xFFFF9F43);
  static const Color darkText     = Color(0xFF1E293B);

  // Pastel Backgrounds
  static const Color pastelGreen  = Color(0xFFE8F5E9);
  static const Color pastelPurple = Color(0xFFF3E8FF);
  static const Color pastelOrange = Color(0xFFFFF7ED);
  static const Color pastelBlue   = Color(0xFFEFF6FF);

  // Borders & Dividers
  static const Color borderLight  = Color(0xFFF1F5F9);
  
  // Glass (Kept for compatibility, mostly unused in light theme)
  static const Color glassWhite  = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x22FFFFFF);

  // Text
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);

  // Gradients (Adjusted for light theme if needed, or keeping original for specific badges)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F8EF7), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
