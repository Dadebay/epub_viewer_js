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
  String? _currentHref;
  Key _epubKey = UniqueKey();
  EpubSource? _epubSource;
  String? _initialCfi;
  bool _showControls = true;
  String _titleText = 'EPUB Kitap Okuyucu';
  bool _isDraggingSlider = false;
  bool _isProgressLongPressed = false;
  double _tempSliderValue = 0.0;
  List<EpubChapter> _chapters = [];
  String _currentChapterTitle = '';

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
          print('🎨 Theme değişti: ${theme.name}');
          print('   Font-family: ${theme.fontFamily}');
          print('   Font-weight: ${theme.fontWeight}');
          print('   CustomCss: ${theme.epubTheme.customCss}');
          setState(() {
            currentTheme = theme;
          });
          epubController.updateTheme(theme: theme.epubTheme);
        },
        onFontSizeChanged: (size) {
          print('📏 Font size değişti: $size');
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

        // If we got real page count (more than initial placeholder), hide loading
        if (totalPages > 10 && isLoadingPages) {
          isLoadingPages = false;
        }
      });

      print('✅ State güncellendi - currentPage: $currentPage, totalPages: $totalPages');
    } catch (e) {
      print('❌ Error getting page info: $e');
    }
  }

  Future<void> _jumpToPage(int page) async {
    if (page >= 1 && page <= totalPages && page != currentPage) {
      await _updatePageInfo();
    }
  }

  // Find chapter by href
  String _getChapterTitleByHref(String? href) {
    if (href == null || href.isEmpty || _chapters.isEmpty) {
      return _titleText;
    }

    // Remove fragment identifier (#...) from href if present
    String cleanHref = href.split('#').first;

    // Flatten chapters with parent info
    List<Map<String, dynamic>> flatChapters = [];
    void addChapters(List<EpubChapter> chapters, {EpubChapter? parent}) {
      for (var chapter in chapters) {
        flatChapters.add({'chapter': chapter, 'parent': parent});
        if (chapter.subitems.isNotEmpty) {
          addChapters(chapter.subitems, parent: chapter);
        }
      }
    }

    addChapters(_chapters);

    // Find the chapter matching this href
    Map<String, dynamic>? currentChapterInfo;

    for (var info in flatChapters) {
      EpubChapter chapter = info['chapter'];
      String chapterHref = chapter.href.split('#').first;

      if (chapterHref == cleanHref || cleanHref.endsWith(chapterHref)) {
        currentChapterInfo = info;
        break;
      }
    }

    if (currentChapterInfo == null) return _titleText;

    EpubChapter currentChapter = currentChapterInfo['chapter'];
    EpubChapter? parentChapter = currentChapterInfo['parent'];

    // If there's a parent, show both
    if (parentChapter != null) {
      return '${parentChapter.title.trim()}\n${currentChapter.title.trim()}';
    }

    return currentChapter.title.trim();
  }

  void _updateCurrentChapter() {
    if (_chapters.isEmpty) {
      setState(() {
        _currentChapterTitle = _titleText;
      });
      return;
    }

    // Use href to find chapter (more accurate than page numbers)
    String chapterTitle = _getChapterTitleByHref(_currentHref);
    setState(() {
      _currentChapterTitle = chapterTitle;
    });
    print('📖 Current chapter updated: $_currentChapterTitle (href: $_currentHref)');
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
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
            ),
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
                _chapters = chapters;
                isLoading = false;
              });
              _updateCurrentChapter();
            },
            onEpubLoaded: () async {
              print('✓ EPUB başarıyla yüklendi');
            },
            onRelocated: (value) {
              print("Relocated to $value");
              print("Relocated href: ${value.href}");
              setState(() {
                progress = value.progress;
                _currentCfi = value.startCfi;
                _currentHref = value.href;
              });
              _updatePageInfo();
              _updateCurrentChapter();
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
              _updatePageInfo();
              _updateCurrentChapter();
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
              // Toggle controls visibility on tap (but not if dragging slider)
              if (!_isDraggingSlider && !_isProgressLongPressed) {
                setState(() {
                  _showControls = !_showControls;
                });
              }
            },
            selectAnnotationRange: true,
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

          // Minimal chapter title for focus reading mode (when controls are hidden)
          if (!_showControls && _currentChapterTitle.isNotEmpty)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showControls ? -100 : 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      currentTheme.backgroundColor.withOpacity(0.9),
                      currentTheme.backgroundColor.withOpacity(0.0),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      _currentChapterTitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: currentTheme.textColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Page indicator popup when dragging
          if (_isProgressLongPressed)
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.65,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xffd4d4d5),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Page ${(_tempSliderValue * totalPages).round().clamp(1, totalPages)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.bold,
                          color: currentTheme.textColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _currentChapterTitle.isNotEmpty ? _currentChapterTitle : _titleText,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            color: currentTheme.textColor.withOpacity(0.6),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom overlay bar (hamburger menu, page indicator, Aa)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: (_showControls || _isProgressLongPressed) ? 0 : -100,
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
                      if (_showControls)
                        AnimatedOpacity(
                          opacity: _isProgressLongPressed ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: GestureDetector(
                            onTap: () => ChapterDrawer.show(
                              context,
                              epubController,
                              bookTitle: _titleText,
                              currentPage: currentPage,
                              totalPages: totalPages,
                              currentCfi: _currentCfi,
                              currentHref: _currentHref,
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
                        ),
                      pageSlider(context),

                      // Aa (theme settings)
                      if (_showControls)
                        AnimatedOpacity(
                          opacity: _isProgressLongPressed ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: GestureDetector(
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
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Minimal page indicator for focus reading mode (when controls are hidden)
          if (!_showControls && !isLoadingPages)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showControls ? -100 : 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      currentTheme.backgroundColor.withOpacity(0.9),
                      currentTheme.backgroundColor.withOpacity(0.0),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12).copyWith(bottom: 24),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          print('📍 BOTTOM PAGE INDICATOR: $currentPage / $totalPages');
                          print('📚 Current chapter (from bottom): $_currentChapterTitle');
                          print('🔗 Current href: $_currentHref');
                        },
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$currentPage',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  color: currentTheme.textColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget pageSlider(BuildContext context) {
    final displayPage = _isProgressLongPressed ? (_tempSliderValue * totalPages).round().clamp(1, totalPages) : currentPage;

    return Expanded(
      child: GestureDetector(
        onLongPressStart: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localX = details.localPosition.dx;
          final percentage = (localX / box.size.width).clamp(0.0, 1.0);

          setState(() {
            _isProgressLongPressed = true;
            _isDraggingSlider = true;
            _tempSliderValue = percentage;
          });
        },
        onLongPressMoveUpdate: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localX = details.localPosition.dx;
          final percentage = (localX / box.size.width).clamp(0.0, 1.0);

          setState(() {
            _tempSliderValue = percentage;
          });
        },
        onLongPressEnd: (details) {
          final targetPage = (_tempSliderValue * totalPages).round().clamp(1, totalPages);
          if (targetPage != currentPage) {
            _jumpToPage(targetPage);
          }
          setState(() {
            _isDraggingSlider = false;
            _isProgressLongPressed = false;
          });
        },
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: _isProgressLongPressed ? 6 : 18),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: currentTheme.buttonBackgroundColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Full width background progress bar
                if (!isLoadingPages)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Row(
                        children: [
                          // Filled portion
                          Expanded(
                            flex: totalPages > 0 ? displayPage : 1,
                            child: Container(
                              color: currentTheme.buttonColor.withOpacity(0.15),
                            ),
                          ),
                          // Unfilled portion
                          Expanded(
                            flex: totalPages > 0 ? (totalPages - displayPage).clamp(1, totalPages) : 1,
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Page text centered
                if (!isLoadingPages)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$displayPage',
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
                  )
                else
                  Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(currentTheme.buttonColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
