import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:screen_brightness/screen_brightness.dart';

class ThemeSettingsSheet extends StatefulWidget {
  final EpubTheme currentTheme;
  final int currentFontSize;
  final Function(EpubTheme) onThemeChanged;
  final Function(int) onFontSizeChanged;

  const ThemeSettingsSheet({
    super.key,
    required this.currentTheme,
    required this.currentFontSize,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<ThemeSettingsSheet> createState() => _ThemeSettingsSheetState();
}

class _ThemeSettingsSheetState extends State<ThemeSettingsSheet> {
  late int fontSize;
  late EpubTheme selectedTheme;
  bool isDarkMode = false;
  double brightnessLevel = 0.7;

  @override
  void initState() {
    super.initState();
    fontSize = widget.currentFontSize;
    selectedTheme = widget.currentTheme;
    _initBrightness();
  }

  Future<void> _initBrightness() async {
    try {
      final currentBrightness = await ScreenBrightness().current;
      setState(() {
        brightnessLevel = currentBrightness;
      });
    } catch (e) {
      // If brightness cannot be read, keep default value
      debugPrint('Failed to get brightness: $e');
    }
  }

  Future<void> _setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
    } catch (e) {
      debugPrint('Failed to set brightness: $e');
    }
  }

  void _decreaseFontSize() {
    if (fontSize > 12) {
      setState(() {
        fontSize -= 2;
      });
      widget.onFontSizeChanged(fontSize);
    }
  }

  void _increaseFontSize() {
    if (fontSize < 32) {
      setState(() {
        fontSize += 2;
      });
      widget.onFontSizeChanged(fontSize);
    }
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _selectTheme(EpubTheme theme) {
    setState(() {
      selectedTheme = theme;
    });
    widget.onThemeChanged(theme);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tema sazlamalary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Font size controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFontSizeButton('A', 16, _decreaseFontSize),
              _buildFontSizeButton('A', 24, _increaseFontSize),
              InkWell(
                onTap: _toggleDarkMode,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode_outlined,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Brightness slider
          _buildBrightnessSlider(),
          const SizedBox(height: 20),
          // Theme grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: isDarkMode ? _buildDarkThemes() : _buildLightThemes(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBrightnessSlider() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            double newValue = brightnessLevel - 0.1;
            if (newValue < 0.0) newValue = 0.0;
            setState(() {
              brightnessLevel = newValue;
            });
            _setBrightness(newValue);
          },
          child: Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(0.6),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 15.0,
              activeTrackColor: Colors.grey.shade500,
              inactiveTrackColor: Colors.grey.shade300,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 0, // Hidden thumb
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: brightnessLevel.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() {
                  brightnessLevel = value;
                });
                _setBrightness(value);
              },
            ),
          ),
        ),
        const SizedBox(width: 15),
        GestureDetector(
          onTap: () {
            double newValue = brightnessLevel + 0.1;
            if (newValue > 1.0) newValue = 1.0;
            setState(() {
              brightnessLevel = newValue;
            });
            _setBrightness(newValue);
          },
          child: Icon(
            Icons.wb_sunny_outlined,
            size: 22,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLightThemes() {
    return [
      _buildThemeCard(
          'Original', EpubTheme.light(), Colors.white, Colors.black),
      _buildThemeCard(
          'Paper', EpubTheme.grey(), const Color(0xFFF2F2F7), Colors.black),
      _buildThemeCard('Bold', EpubTheme.sepia(), const Color(0xFFF4ECD8),
          const Color(0xFF5B4636),
          fontWeight: FontWeight.bold),
      _buildThemeCard(
          'Calm', EpubTheme.tan(), const Color(0xFFFBF1E6), Colors.black),
      _buildThemeCard(
          'Focus', EpubTheme.mint(), const Color(0xFFF8F8F8), Colors.black),
      _buildThemeCard('Sepia', EpubTheme.sepia(), const Color(0xFFF4ECD8),
          const Color(0xFF5B4636)),
    ];
  }

  List<Widget> _buildDarkThemes() {
    return [
      _buildThemeCard(
          'Quite', EpubTheme.dark(), const Color(0xFF1C1C1E), Colors.white),
      _buildThemeCard(
          'Paper',
          EpubTheme.custom(
            backgroundDecoration: const BoxDecoration(color: Color(0xFF2C2C2E)),
            foregroundColor: Colors.white,
          ),
          const Color(0xFF2C2C2E),
          Colors.white),
      _buildThemeCard(
          'Bold',
          EpubTheme.custom(
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            foregroundColor: Colors.white,
          ),
          Colors.black,
          Colors.white,
          fontWeight: FontWeight.bold),
      _buildThemeCard(
          'Calm',
          EpubTheme.custom(
            backgroundDecoration: const BoxDecoration(color: Color(0xFF3A2E2A)),
            foregroundColor: const Color(0xFFD9C5B2),
          ),
          const Color(0xFF3A2E2A),
          const Color(0xFFD9C5B2)),
      _buildThemeCard(
          'Focus',
          EpubTheme.custom(
            backgroundDecoration: const BoxDecoration(color: Color(0xFF1C1C1E)),
            foregroundColor: Colors.white,
          ),
          const Color(0xFF1C1C1E),
          Colors.white),
      _buildThemeCard('Night', EpubTheme.dark(), const Color(0xFF000000),
          const Color(0xFF8E8E93)),
    ];
  }

  Widget _buildFontSizeButton(String text, double size, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    String name,
    EpubTheme theme,
    Color bgColor,
    Color textColor, {
    FontWeight fontWeight = FontWeight.bold,
  }) {
    final isSelected = selectedTheme.themeType == theme.themeType;

    return InkWell(
      onTap: () => _selectTheme(theme),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
