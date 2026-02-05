import 'dart:io';

import 'package:example/global_safe_area_wrapper.dart';
import 'package:example/reader_theme_model.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:example/chapter_drawer.dart';
import 'package:example/theme_settings_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return GlobalSafeAreaWrapper(
          top: false,
          bottom: Platform.isIOS ? false : true,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Epub Viewer Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentFontSize = 12;
  int currentPage = 1;
  ReaderThemeModel currentTheme = ReaderThemeModel.lightThemes.first;
  final epubController = EpubController();
  bool isLoading = true;
  bool isLoadingPages = true;
  double progress = 0.0;
  var textSelectionCfi = '';
  int totalPages = 1;

  String? _currentCfi;
  Key _epubKey = UniqueKey();
  EpubSource? _epubSource;
  String? _initialCfi;
  bool _showControls = true;
  String _titleText = 'EPUB Kitap Okuyucu';

  Future<void> _pickAndOpenEpub() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.single;
    File? file;

    if (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty) {
      final tempDir = await getTemporaryDirectory();
      file = File('${tempDir.path}/${pickedFile.name}');
      await file.writeAsBytes(pickedFile.bytes!, flush: true);
    } else if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
      file = File(pickedFile.path!);
    }

    if (file == null || !file.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya bulunamadı.')),
        );
      }
      return;
    }

    print('EPUB seçildi: ${file.path}');
    print('Dosya boyutu: ${file.lengthSync()} bytes');

    setState(() {
      isLoading = true;
      progress = 0.0;
      _epubSource = EpubSource.fromFile(file!);
      _titleText = pickedFile.name;
      _initialCfi = null;
      _epubKey = UniqueKey(); // Force widget rebuild
    });
  }

  void _showThemeSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeSettingsSheet(
        currentTheme: currentTheme,
        currentFontSize: currentFontSize,
        onThemeChanged: (theme) {
          setState(() {
            currentTheme = theme;
          });
          epubController.updateTheme(theme: theme.epubTheme);
        },
        onFontSizeChanged: (size) {
          setState(() {
            currentFontSize = size;
          });
          epubController.setFontSize(fontSize: size.toDouble());
        },
      ),
    );
  }

  Future<void> _updatePageInfo() async {
    print('📖 _updatePageInfo çağrıldı');
    try {
      final pageInfo = await epubController.getPageInfo();
      print('📄 Alınan sayfa bilgisi: $pageInfo');
      print('📍 Aktif sayfa: ${pageInfo['currentPage']}');
      print('📚 Toplam sayfa: ${pageInfo['totalPages']}');

      setState(() {
        currentPage = pageInfo['currentPage'] ?? 1;
        totalPages = pageInfo['totalPages'] ?? 1;
      });

      print('✅ State güncellendi - currentPage: $currentPage, totalPages: $totalPages');
    } catch (e) {
      print('❌ Error getting page info: $e');
    }
  }

  Future<void> _goToNextPage() async {
    if (currentPage < totalPages) {
      // await epubController.nextPage();
      await _updatePageInfo();
    }
  }

  Future<void> _goToPreviousPage() async {
    if (currentPage > 1) {
      // await epubController.previousPage();
      await _updatePageInfo();
    }
  }

  Future<void> _jumpToPage(int page) async {
    if (page >= 1 && page <= totalPages && page != currentPage) {
      // Calculate progress based on page
      double targetProgress = (page - 1) / (totalPages - 1);
      // await epubController.gotoProgress(targetProgress);
      await _updatePageInfo();
    }
  }

  void _showMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'description',
          child: Row(
            children: [
              Icon(Icons.description_outlined),
              SizedBox(width: 12),
              Text('Kitap beýany'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'bookmark',
          child: Row(
            children: [
              Icon(Icons.bookmark_outline),
              SizedBox(width: 12),
              Text('Tekja goş'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'library',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline),
              SizedBox(width: 12),
              Text('Kitaplaryma goş'),
            ],
          ),
        ),
      ],
    ).then((value) {
      // Handle menu selection
      if (value != null) {
        // TODO: Implement menu actions
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If no epub source is selected, show the start screen
    if (_epubSource == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: 120,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 32),
              Text(
                'EPUB Kitap Okuyucu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Okumak için bir kitap seçin',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _pickAndOpenEpub,
                icon: const Icon(Icons.folder_open, size: 24),
                label: const Text(
                  'Kitap Seç',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show the epub reader when a book is selected
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main EPUB Viewer - full screen
          Positioned.fill(
            child: Stack(
              children: [
                EpubViewer(
                  key: _epubKey,
                  initialCfi: _initialCfi,
                  epubSource: _epubSource!,
                  epubController: epubController,
                  displaySettings:
                      EpubDisplaySettings(flow: EpubFlow.paginated, useSnapAnimationAndroid: false, snap: true, theme: currentTheme.epubTheme, fontSize: currentFontSize, allowScriptedContent: true),
                  selectionContextMenu: ContextMenu(
                    menuItems: [
                      ContextMenuItem(
                        title: "Highlight",
                        id: 1,
                        action: () async {
                          epubController.addHighlight(cfi: textSelectionCfi);
                        },
                      ),
                    ],
                    settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
                  ),
                  onChaptersLoaded: (chapters) {
                    print('Chapters yüklendi: ${chapters.length} bölüm');
                    setState(() {
                      isLoading = false;
                    });
                  },
                  onEpubLoaded: () async {
                    print('✓ EPUB başarıyla yüklendi');
                  },
                  onRelocated: (value) {
                    print("Reloacted to $value");
                    setState(() {
                      progress = value.progress;
                      _currentCfi = value.startCfi;
                    });
                    _updatePageInfo();
                  },
                  onAnnotationClicked: (cfi, data) {
                    print("Annotation clicked $cfi");
                  },
                  onTextSelected: (epubTextSelection) {
                    textSelectionCfi = epubTextSelection.selectionCfi;
                    print(textSelectionCfi);
                  },
                  onLocationLoaded: () {
                    /// progress will be available after this callback
                    print('✓ Location yüklendi');
                    if (isLoading) {
                      setState(() {
                        isLoading = false;
                      });
                    }
                    // Mark loading pages as complete
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        setState(() {
                          isLoadingPages = false;
                        });
                      }
                    });
                    _updatePageInfo();
                  },
                  onSelection: (selectedText, cfiRange, selectionRect, viewRect) {
                    print("On selection changes");
                  },
                  onDeselection: () {
                    print("on delection");
                  },
                  onSelectionChanging: () {
                    print("on slection chnages");
                  },
                  onTouchDown: (x, y) {
                    // Track tap for toggle
                  },
                  onTouchUp: (x, y) {
                    // Toggle controls visibility on tap
                    setState(() {
                      _showControls = !_showControls;
                    });
                  },
                  selectAnnotationRange: true,
                ),
                Visibility(
                  visible: isLoading,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              ],
            ),
          ),

          // Top overlay bar (X button, title, ... menu)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    currentTheme.backgroundColor.withOpacity(0.95),
                    currentTheme.backgroundColor.withOpacity(0.0),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(color: currentTheme.buttonBackgroundColor, shape: BoxShape.circle),
                          child: Image.asset(
                            'assets/images/x.png',
                            width: 10,
                            height: 10,
                            color: currentTheme.buttonColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showMenu,
                        child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(color: currentTheme.buttonBackgroundColor, shape: BoxShape.circle),
                            child: Icon(Icons.more_horiz, color: currentTheme.buttonColor, size: 20)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom overlay bar (hamburger menu, page indicator, Aa)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    currentTheme.backgroundColor.withOpacity(0.95),
                    currentTheme.backgroundColor.withOpacity(0.0),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hamburger menu (chapters)
                      GestureDetector(
                        onTap: () => ChapterDrawer.show(
                          context,
                          epubController,
                          bookTitle: _titleText,
                          currentPage: currentPage,
                          totalPages: totalPages,
                          currentCfi: _currentCfi,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(13),
                          decoration: BoxDecoration(color: currentTheme.buttonBackgroundColor, shape: BoxShape.circle),
                          child: Image.asset(
                            'assets/images/content_list.png',
                            width: 15,
                            height: 15,
                            color: currentTheme.buttonColor,
                          ),
                        ),
                      ),
                      pageSlider(context),

                      // Aa (theme settings)
                      GestureDetector(
                        onTap: () => _showThemeSettings(),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(color: currentTheme.buttonBackgroundColor, shape: BoxShape.circle),
                          child: Image.asset(
                            'assets/images/font_logo.png',
                            width: 24,
                            height: 24,
                            color: currentTheme.buttonColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Centered page indicator with navigation
        ],
      ),
    );
  }

  Expanded pageSlider(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        height: 40,
        decoration: BoxDecoration(
          color: currentTheme.buttonBackgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: GestureDetector(
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = details.localPosition;
            final barWidth = box.size.width - 40;
            final tapX = localPosition.dx - 20;

            if (tapX >= 0 && tapX <= barWidth) {
              final percentage = tapX / barWidth;
              final targetPage = (percentage * totalPages).round().clamp(1, totalPages);
              if (targetPage != currentPage) {
                _jumpToPage(targetPage);
              }
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full width background progress bar
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Row(
                    children: [
                      // Filled portion
                      Expanded(
                        flex: totalPages > 0 ? currentPage : 1,
                        child: Container(
                          color: currentTheme.buttonColor.withOpacity(0.15),
                        ),
                      ),
                      // Unfilled portion
                      Expanded(
                        flex: totalPages > 0 ? (totalPages - currentPage).clamp(1, totalPages) : 1,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Page text centered
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$currentPage',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: currentTheme.textColor,
                      ),
                    ),
                    TextSpan(
                      text: ' / ',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: currentTheme.textColor.withOpacity(0.4),
                      ),
                    ),
                    TextSpan(
                      text: '$totalPages',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                        color: currentTheme.textColor.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
