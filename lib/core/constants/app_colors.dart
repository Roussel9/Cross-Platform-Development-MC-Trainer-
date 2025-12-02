import 'package:flutter/material.dart';

class AppColors {
  // Basierend auf Colors.deepPurple (Deiner seedColor)
  static const Color primaryColorDark = Color(0xFF311B92); // DeepPurple 900
  static const Color primaryColorLight = Color(0xFF5E35B1); // DeepPurple 600
  static Color headerPrimary = Colors.blue.shade500;
  static Color headerSecondary = Colors.purple.shade600;

  // Primärer Hintergrund-Gradient, wie im Login/Home Header Mockup
  // WICHTIG: Wir verwenden hier die deckenden Farben, ABER
  // Im HomeScreen (in der Stack-Schicht 2) fügen wir die Opazität hinzu.

  // Alternativ können wir einen dunkleren, teiltransparenten Überzug definieren:
  static LinearGradient get darkOverlayGradient {
    const double opacity = 0.8; // Setze die gewünschte Deckkraft (80% deckend)
    return LinearGradient(
      colors: [
        primaryColorLight.withOpacity(opacity),
        primaryColorDark.withOpacity(opacity),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static const LinearGradient appBackgroundGradient = LinearGradient(
    colors: [
      primaryColorLight, // Oben
      primaryColorDark, // Unten
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Für den Header-Container verwenden wir weiterhin den deckenden Gradienten.
  static LinearGradient appHeaderBackgroundGradient = LinearGradient(
    colors: [
      headerPrimary, // Oben
      headerSecondary, // Unten
    ],
    begin: Alignment.topLeft,
    end: Alignment.topRight,
  );

  // Hintergrund der Hauptinhalte (hell/weiß)
  static const Color scaffoldBackgroundColor = Color(0xFFF0F2F5);

  static const LinearGradient statsCardGradient = LinearGradient(
    colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
