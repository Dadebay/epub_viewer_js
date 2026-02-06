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
        customCss: {'font-family': 'SFPro', 'font-weight': '400'},
      ),
      backgroundColor: Colors.white,
      textColor: Colors.black,
      buttonColor: Colors.black,
      buttonBackgroundColor: const Color(0xffededee),
      fontFamily: 'SFPro',
      fontWeight: FontWeight.w400,
    ),
    ReaderThemeModel(
      name: 'Quite',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF4a4a4c)),
        foregroundColor: Colors.white,
        customCss: {'font-family': 'NewYork', 'font-weight': '400'},
      ),
      backgroundColor: const Color(0xFF4a4a4c),
      textColor: Colors.white,
      buttonColor: Colors.white,
      buttonBackgroundColor: const Color(0xFF505052),
      fontFamily: 'NewYork',
      fontWeight: FontWeight.w400,
    ),
    ReaderThemeModel(
      name: 'Paper',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFFf0eced)),
        foregroundColor: Colors.black,
        customCss: {'font-family': 'NewYork', 'font-weight': '400'},
      ),
      backgroundColor: const Color(0xFFf0eced),
      textColor: Colors.black,
      buttonColor: Colors.black,
      buttonBackgroundColor: const Color(0xFfe2dee0),
      fontFamily: 'NewYork',
      fontWeight: FontWeight.w400,
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
        customCss: {'font-family': 'NewYork', 'font-weight': '400'},
      ),
      backgroundColor: const Color(0xFff5ebda),
      textColor: const Color(0xFF3E3329),
      buttonColor: const Color(0xFF3E3329),
      buttonBackgroundColor: const Color(0xFFe3dacc),
      fontFamily: 'NewYork',
      fontWeight: FontWeight.w400,
    ),
    ReaderThemeModel(
      name: 'Focus',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFFfffcf4)),
        foregroundColor: Colors.black,
        customCss: {'font-family': 'NewYork', 'font-weight': '400'},
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
        customCss: {'font-family': 'SFPro', 'font-weight': '400'},
      ),
      backgroundColor: Colors.black,
      textColor: Colors.white,
      buttonColor: Colors.white,
      buttonBackgroundColor: const Color(0xFF2a2a2b),
      fontFamily: 'SFPro',
      fontWeight: FontWeight.w400,
    ),
    ReaderThemeModel(
      name: 'Quite',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        foregroundColor: const Color(0xFFABAAB2),
        customCss: {'font-family': 'NewYork', 'font-weight': '400'},
      ),
      backgroundColor: Colors.black,
      textColor: const Color(0xFFABAAB2),
      buttonColor: const Color(0xFFABAAB2),
      buttonBackgroundColor: const Color(0xFF2a2a2b),
      fontFamily: 'NewYork',
      fontWeight: FontWeight.w400,
    ),
    ReaderThemeModel(
      name: 'Paper',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF1c1c1d)),
        foregroundColor: const Color(0xFFF2F2F0),
        customCss: {'font-family': 'NewYork', 'font-weight': '400'},
      ),
      backgroundColor: const Color(0xFF1c1c1d),
      textColor: const Color(0xFFABAAB2),
      buttonColor: const Color(0xFFABAAB2),
      buttonBackgroundColor: const Color(0xFF2a2a2b),
      fontFamily: 'NewYork',
      fontWeight: FontWeight.w400,
    ),
    ReaderThemeModel(
      name: 'Bold',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        foregroundColor: Colors.white,
        customCss: {'font-family': 'SFPro', 'font-weight': 'bold'},
      ),
      backgroundColor: Colors.black,
      textColor: const Color(0xFFABAAB2),
      buttonColor: const Color(0xFFABAAB2),
      buttonBackgroundColor: const Color(0xFF2a2a2b),
      fontFamily: 'SFPro',
      fontWeight: FontWeight.bold,
    ),
    ReaderThemeModel(
      name: 'Calm',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF423c30)),
        foregroundColor: const Color(0xFFF5E9DA),
        customCss: {'font-family': 'NewYork', 'font-weight': '400'},
      ),
      backgroundColor: const Color(0xFF423c30),
      textColor: const Color(0xFFF5E9DA),
      buttonColor: const Color(0xFFF5E9DA),
      buttonBackgroundColor: const Color(0xFF4f4a43),
      fontFamily: 'NewYork',
      fontWeight: FontWeight.w400,
    ),
    ReaderThemeModel(
      name: 'Focus',
      epubTheme: EpubTheme.custom(
        backgroundDecoration: const BoxDecoration(color: Color(0xFF18160d)),
        foregroundColor: const Color(0xFFFEF8EA),
        customCss: {'font-family': 'NewYork', 'font-weight': '400'},
      ),
      backgroundColor: const Color(0xFF18160d),
      textColor: const Color(0xFFABAAB2),
      buttonColor: const Color(0xFFABAAB2),
      buttonBackgroundColor: const Color(0xFF31302a),
      fontFamily: 'NewYork',
      fontWeight: FontWeight.w400,
    ),
  ];
}
