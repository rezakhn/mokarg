import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Prevent instantiation

  static final Color _lightPrimaryColor = Colors.indigo.shade500; // Explicit shade
  static final Color _lightPrimaryVariantColor = Colors.indigo.shade700;
  static final Color _lightSecondaryColor = Colors.pinkAccent.shade400;
  static const Color _lightOnPrimaryColor = Colors.white; // Made const
  static final Color _lightBackground = Colors.grey.shade100; // Lightened background slightly
  static const Color _lightSurface = Colors.white; // Made const
  static const Color _lightOnError = Colors.white; // Made const
  static final Color _lightError = Colors.red.shade700;

  // Define common text styles (can be customized further)
  static const TextTheme _lightTextTheme = TextTheme(
    // Display styles (very large text, typically for titles on large screens or special emphasis)
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.w400, letterSpacing: -0.25 /*, color: Colors.black87 */), // Color will be from ColorScheme.onBackground/onSurface
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.w400 /*, letterSpacing: 0.0, color: Colors.black87 */),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w400 /*, letterSpacing: 0.0, color: Colors.black87 */),

    // Headline styles (for prominent text like screen titles)
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.w400 /*, letterSpacing: 0.0, color: Colors.black87 */),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w400 /*, letterSpacing: 0.0, color: Colors.black87 */),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500 /*, letterSpacing: 0.0, color: Colors.black87 */), // Good for AppBar titles

    // Title styles (smaller than headlines, good for section titles, card titles)
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w500 /*, letterSpacing: 0.15, color: Colors.black87 */), // Good for Dialog Titles
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, letterSpacing: 0.15 /*, color: Colors.black87 */), // Good for ListTile titles, Card titles
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, letterSpacing: 0.1 /*, color: Colors.black87 */),

    // Body styles (for normal text content)
    bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400, letterSpacing: 0.5 /*, color: Colors.black87 */),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400, letterSpacing: 0.25 /*, color: Colors.black87 */), // Default for Text()
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, letterSpacing: 0.4 /*, color: Colors.black54 */), // Good for captions, subtitles

    // Label styles (for buttons, captions, overlines)
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, letterSpacing: 0.1 /*, color: _lightPrimaryColor */), // Good for buttons
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, letterSpacing: 0.5 /*, color: Colors.black54 */),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, letterSpacing: 0.5 /*, color: Colors.black54 */),
  );


  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: _lightPrimaryColor,
      primaryContainer: _lightPrimaryVariantColor,
      secondary: _lightSecondaryColor,
      secondaryContainer: Colors.pinkAccent.shade700,
      surface: _lightSurface,
      background: _lightBackground,
      error: _lightError,
      onPrimary: _lightOnPrimaryColor,
      onSecondary: Colors.white,
      onSurface: Colors.black87, // Default text color on surfaces like cards
      onBackground: Colors.black87, // Default text color on background
      onError: _lightOnError,
      brightness: Brightness.light,
    );

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _lightPrimaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightBackground,

      fontFamily: null, // Use system default fonts

      textTheme: _lightTextTheme.apply(
        bodyColor: colorScheme.onSurface, // Default color for body text
        displayColor: colorScheme.onSurface, // Default color for display text
        // You can override specific text styles' colors here if needed,
        // but usually, they should adapt based on where they are used (onPrimary, onSurface etc.)
      ),

      appBarTheme: AppBarTheme(
        color: _lightPrimaryColor, // Or use colorScheme.primary
        foregroundColor: colorScheme.onPrimary, // For title text and icons
        elevation: 2.0, // Subtle shadow
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actionsIconTheme: IconThemeData(color: colorScheme.onPrimary),
        titleTextStyle: _lightTextTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary), // Use defined text style
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: _lightTextTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: _lightTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600), // Ensure labelLarge is used
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: _lightTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        labelStyle: _lightTextTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        floatingLabelStyle: _lightTextTheme.bodySmall?.copyWith(color: colorScheme.primary), // When label floats
        hintStyle: _lightTextTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
        // filled: true,
        // fillColor: Colors.grey.shade50, // Slightly different from background
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),

      cardTheme: CardThemeData( // Removed const temporarily to diagnose "isn't a class" error
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))), // Kept inner const
        surfaceTintColor: Colors.transparent,
        color: _lightSurface,
      ),

      listTileTheme: ListTileThemeData(
        // dense: true, // Makes list tiles more compact
        iconColor: colorScheme.primary,
        titleTextStyle: _lightTextTheme.titleMedium, // Default title style for ListTiles
        subtitleTextStyle: _lightTextTheme.bodySmall, // Default subtitle style
      ),

      drawerTheme: const DrawerThemeData( // Made const
        backgroundColor: _lightSurface, // Or _lightBackground
      ),

      dialogTheme: DialogThemeData( // Corrected: DialogTheme -> DialogThemeData
        backgroundColor: _lightSurface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))), // Made const compatible
        titleTextStyle: _lightTextTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: _lightSurface,
        textStyle: _lightTextTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          // backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          //   // Converted .withOpacity(0.12) to .withAlpha((0.12 * 255).round()) which is 31
          //   if (states.contains(WidgetState.selected)) return colorScheme.primary.withAlpha(31);
          //   return null; // Use default for unselected
          // }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) return colorScheme.primary;
            // Converted .withOpacity(0.6) to .withAlpha((0.6 * 255).round()) which is 153
            return colorScheme.onSurface.withAlpha(153);
          }),
          iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) return colorScheme.primary;
            // Converted .withOpacity(0.6) to .withAlpha((0.6 * 255).round()) which is 153
            return colorScheme.onSurface.withAlpha(153);
          }),
          textStyle: WidgetStateProperty.all(_lightTextTheme.labelMedium),
        )
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
