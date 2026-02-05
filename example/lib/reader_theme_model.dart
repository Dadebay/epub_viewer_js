import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

class ReaderThemeModel {
  final String name;
  final EpubTheme epubTheme;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final Color buttonBackgroundColor;
  final String? fontFamily;
  final FontWeight fontWeight;

  const ReaderThemeModel({
    required this.name,
    required this.epubTheme,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonColor,
    required this.buttonBackgroundColor,
    this.fontFamily,
    this.fontWeight = FontWeight.w400,
  });

  // Light Mode Themes
  static List<ReaderThemeModel> lightThemes = [
    ReaderThemeModel(
      name: 'Original',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Colors.white),
        foregroundColor: Colors.black,
        customCss: {'font-family': 'SFPro'},
      ),
      backgroundColor: Color(0xffededee),
      textColor: Colors.black,
      buttonColor: Colors.black,
      buttonBackgroundColor: const Color(0xffededee),
      fontFamily: 'SFPro',
    ),
    ReaderThemeModel(
      name: 'Quite',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF4a4a4c)),
        foregroundColor: Colors.white,
        customCss: {'font-family': 'NewYork'},
      ),
      backgroundColor: const Color(0xFF4a4a4c),
      textColor: Colors.white,
      buttonColor: Colors.white,
      buttonBackgroundColor: const Color(0xFF505052),
      fontFamily: 'NewYork',
    ),
    ReaderThemeModel(
      name: 'Paper',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFFf0eced)),
        foregroundColor: Colors.black,
        customCss: {'font-family': 'NewYork'},
      ),
      backgroundColor: const Color(0xFFf0eced),
      textColor: Colors.black,
      buttonColor: Colors.black,
      buttonBackgroundColor: const Color(0xFfe2dee0),
      fontFamily: 'NewYork',
    ),
    ReaderThemeModel(
      name: 'Bold',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Colors.white),
        foregroundColor: Colors.black,
        customCss: {'font-family': 'SFPro', 'font-weight': 'bold'},
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      textColor: Colors.black,
      buttonColor: Colors.black,
      buttonBackgroundColor: const Color(0xFFe7e8e9),
      fontFamily: 'SFPro',
      fontWeight: FontWeight.bold,
    ),
    ReaderThemeModel(
      name: 'Calm',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFff5ebda)),
        foregroundColor: const Color(0xFF3E3329),
        customCss: {'font-family': 'NewYork'},
      ),
      backgroundColor: const Color(0xFff5ebda),
      textColor: const Color(0xFF3E3329),
      buttonColor: const Color(0xFF3E3329),
      buttonBackgroundColor: const Color(0xFFe3dacc),
      fontFamily: 'NewYork',
    ),
    ReaderThemeModel(
      name: 'Focus',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFFfffcf4)),
        foregroundColor: Colors.black,
        customCss: {'font-family': 'NewYork'},
      ),
      backgroundColor: const Color(0xFFfffcf4),
      textColor: Colors.black,
      buttonColor: Colors.black,
      buttonBackgroundColor: const Color(0xFFe1dfd8),
      fontFamily: 'NewYork',
    ),
  ];

  // Dark Mode Themes
  static List<ReaderThemeModel> darkThemes = [
    ReaderThemeModel(
      name: 'Night',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF1C1C1E)),
        foregroundColor: Colors.white,
        customCss: {'font-family': 'NewYork'},
      ),
      backgroundColor: const Color(0xFF1C1C1E),
      textColor: Colors.white,
      buttonColor: Colors.white,
      buttonBackgroundColor: const Color(0xFF38383A),
      fontFamily: 'NewYork',
    ),
    ReaderThemeModel(
      name: 'Quite',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF2C2C2E)),
        foregroundColor: const Color(0xFFE5E5EA),
        customCss: {'font-family': 'Literata'},
      ),
      backgroundColor: const Color(0xFF2C2C2E),
      textColor: const Color(0xFFE5E5EA),
      buttonColor: const Color(0xFFE5E5EA),
      buttonBackgroundColor: const Color(0xFF48484A),
      fontFamily: 'Literata',
    ),
    ReaderThemeModel(
      name: 'Paper',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF1F1F1F)),
        foregroundColor: const Color(0xFFD4D4D4),
        customCss: {'font-family': 'Lora'},
      ),
      backgroundColor: const Color(0xFF1F1F1F),
      textColor: const Color(0xFFD4D4D4),
      buttonColor: const Color(0xFFD4D4D4),
      buttonBackgroundColor: const Color(0xFF3A3A3A),
      fontFamily: 'Lora',
    ),
    ReaderThemeModel(
      name: 'Bold',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        foregroundColor: Colors.white,
        customCss: {'font-family': 'IBM Plex Sans', 'font-weight': 'bold'},
      ),
      backgroundColor: Colors.black,
      textColor: Colors.white,
      buttonColor: Colors.white,
      buttonBackgroundColor: const Color(0xFF2C2C2E),
      fontFamily: 'IBM Plex Sans',
      fontWeight: FontWeight.bold,
    ),
    ReaderThemeModel(
      name: 'Calm',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF3A2E2A)),
        foregroundColor: const Color(0xFFD9C5B2),
        customCss: {'font-family': 'Bookerly'},
      ),
      backgroundColor: const Color(0xFF3A2E2A),
      textColor: const Color(0xFFD9C5B2),
      buttonColor: const Color(0xFFD9C5B2),
      buttonBackgroundColor: const Color(0xFF4D3F37),
      fontFamily: 'Bookerly',
    ),
    ReaderThemeModel(
      name: 'Focus',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF000000)),
        foregroundColor: const Color(0xFF8E8E93),
        customCss: {'font-family': 'EB Garamond'},
      ),
      backgroundColor: const Color(0xFF000000),
      textColor: const Color(0xFF8E8E93),
      buttonColor: const Color(0xFF8E8E93),
      buttonBackgroundColor: const Color(0xFF1C1C1E),
      fontFamily: 'EB Garamond',
    ),
  ];
}
