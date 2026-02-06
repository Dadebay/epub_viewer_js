import 'package:example/reader_theme_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:screen_brightness/screen_brightness.dart';

class ThemeSettingsSheet extends StatefulWidget {
  final ReaderThemeModel currentTheme;
  final int currentFontSize;
  final Function(ReaderThemeModel) onThemeChanged;
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
  late ReaderThemeModel selectedTheme;
  bool isDarkMode = false;
  double brightnessLevel = 0.7;
  String themeMode = 'system'; // 'light', 'dark', or 'system'

  @override
  void initState() {
    super.initState();
    fontSize = widget.currentFontSize;
    selectedTheme = widget.currentTheme;
    // Check if current theme is dark (by instance, not name, to avoid duplicates)
    isDarkMode = _isDarkTheme(selectedTheme);
    print('🌓 ThemeSettingsSheet.initState -> currentTheme: ${selectedTheme.name}, isDarkMode: $isDarkMode');
    _initBrightness();
  }

  bool _isDarkTheme(ReaderThemeModel theme) {
    return ReaderThemeModel.darkThemes.contains(theme);
  }

  Future<void> _initBrightness() async {
    try {
      final currentBrightness = await ScreenBrightness().current;
      setState(() {
        brightnessLevel = currentBrightness;
      });
    } catch (e) {
      // If brightness cannot be read, keep default value
    }
  }

  Future<void> _setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
    } catch (e) {}
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
      // Switch to first theme of the new mode
      if (isDarkMode) {
        selectedTheme = ReaderThemeModel.darkThemes.first;
      } else {
        selectedTheme = ReaderThemeModel.lightThemes.first;
      }
      widget.onThemeChanged(selectedTheme);
    });
    print('🌓 ThemeSettingsSheet._toggleDarkMode -> isDarkMode: $isDarkMode, selectedTheme: ${selectedTheme.name}');
  }

  void _selectTheme(ReaderThemeModel theme) {
    setState(() {
      selectedTheme = theme;
      // Update dark flag based on actual list membership
      isDarkMode = _isDarkTheme(theme);
    });
    widget.onThemeChanged(theme);
    print('🎨 ThemeSettingsSheet._selectTheme -> selectedTheme: ${theme.name}, isDarkModeNow: $isDarkMode');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Themes & Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Gilroy',
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2C2C2E) : Color(0xffededee), shape: BoxShape.circle),
                  child: Image.asset(
                    'assets/images/x.png',
                    width: 10,
                    height: 10,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Font size controls
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2C2C2E) : Color(0xffededee),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _decreaseFontSize,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            child: Text(
                              'A',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 18,
                        color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _increaseFontSize,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            child: Text(
                              'A',
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _toggleDarkMode,
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2C2C2E) : Color(0xffededee),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(11),
                  child: Icon(
                    isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          // Brightness slider
          _buildBrightnessSlider(),
          // Theme grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: (isDarkMode ? ReaderThemeModel.darkThemes : ReaderThemeModel.lightThemes).map((theme) => _buildThemeCard(theme)).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBrightnessSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Row(
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
                  color: (isDarkMode ? Colors.white : Colors.black),
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
                activeTrackColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
                inactiveTrackColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
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
            child: Icon(Icons.wb_sunny_outlined, size: 22, color: (isDarkMode ? Colors.white : Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(ReaderThemeModel theme) {
    final isSelected = selectedTheme.name == theme.name;

    return InkWell(
      onTap: () => _selectTheme(theme),
      child: Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDarkMode
                ? isSelected
                    ? Colors.grey.shade100
                    : Colors.grey.shade500
                : isSelected
                    ? Color(0xff98989a)
                    : Color(0xffd2d2d2),
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
                  fontWeight: theme.fontWeight,
                  color: theme.textColor,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                theme.name,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textColor.withOpacity(0.7),
                  fontWeight: theme.fontWeight,
                  fontFamily: 'Gilroy',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
