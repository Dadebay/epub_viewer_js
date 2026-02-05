import 'dart:io';

import 'package:example/global_safe_area_wrapper.dart';
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
  final epubController = EpubController();

  var textSelectionCfi = '';

  bool isLoading = true;
  bool isLoadingPages = true;

  double progress = 0.0;

  EpubTheme currentTheme = EpubTheme.sepia();
  int currentFontSize = 18;

  int currentPage = 1;
  int totalPages = 1;

  EpubSource? _epubSource;
  String _titleText = 'EPUB Kitap Okuyucu';
  String? _initialCfi;
  Key _epubKey = UniqueKey();

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
          epubController.updateTheme(theme: theme);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() {
              _epubSource = null;
              _titleText = 'EPUB Kitap Okuyucu';
              _initialCfi = null;
              isLoading = true;
              isLoadingPages = true;
              progress = 0.0;
              currentPage = 1;
              totalPages = 1;
            });
          },
          tooltip: 'Geri dön',
        ),
        title: Text(
          _titleText,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.black),
            onPressed: _pickAndOpenEpub,
            tooltip: 'Cihazdan EPUB seç',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                EpubViewer(
                  key: _epubKey,
                  initialCfi: _initialCfi,
                  epubSource: _epubSource!,
                  epubController: epubController,
                  displaySettings:
                      EpubDisplaySettings(flow: EpubFlow.paginated, useSnapAnimationAndroid: false, snap: true, theme: currentTheme, fontSize: currentFontSize, allowScriptedContent: true),
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
                    print("Touch down at $x , $y");
                  },
                  onTouchUp: (x, y) {
                    print("Touch up at $x , $y");
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
          // Bottom navigation bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chapters button
                IconButton(
                  icon: const Icon(Icons.menu, size: 28),
                  onPressed: () => ChapterDrawer.show(context, epubController),
                ),
                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoadingPages)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(
                          Icons.library_books,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '$currentPage / $totalPages',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Theme settings button
                IconButton(
                  icon: const Icon(Icons.text_fields, size: 28),
                  onPressed: _showThemeSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
