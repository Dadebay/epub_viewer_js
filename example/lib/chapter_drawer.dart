import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:example/reader_theme_model.dart';

class ChapterDrawer {
  static Future<void> show(
    BuildContext context,
    EpubController controller, {
    String? bookTitle,
    int? currentPage,
    int? totalPages,
    String? currentCfi,
    String? currentHref,
    bool isLoadingPages = false,
    ReaderThemeModel? theme,
  }) async {
    final ReaderThemeModel usedTheme = theme ?? ReaderThemeModel.lightThemes.first;
    final chapters = controller.getChapters();
    final metadata = await controller.getMetadata();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: usedTheme.backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CoverImage(coverBase64: metadata.coverImage, placeholderColor: usedTheme.buttonBackgroundColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookTitle ?? metadata.title ?? 'Contents',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: usedTheme.textColor,
                              fontFamily: 'Gilroy',
                              fontSize: 17,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (totalPages != null && totalPages > 0)
                            RichText(
                              text: TextSpan(
                                text: 'Page ',
                                style: TextStyle(
                                  color: usedTheme.textColor.withOpacity(0.55),
                                  fontSize: 13,
                                  fontFamily: 'Gilroy',
                                ),
                                children: [
                                  TextSpan(
                                    text: '${currentPage ?? 1} of $totalPages',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      fontFamily: 'Gilroy',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: CircleAvatar(
                        backgroundColor: usedTheme.buttonBackgroundColor,
                        child: Icon(
                          Icons.close,
                          color: usedTheme.buttonColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: usedTheme.textColor.withOpacity(0.15)),
              Expanded(
                child: FutureBuilder<Map<String, int>>(
                  future: _getChapterPages(controller, chapters, isLoadingPages),
                  builder: (context, snapshot) {
                    final chapterPages = snapshot.data ?? {};
                    final isLoading = snapshot.connectionState == ConnectionState.waiting || isLoadingPages;

                    int activeCount = 0;
                    String? firstActiveTitle;
                    for (int i = 0; i < chapters.length; i++) {
                      final chapter = chapters[i];
                      final pageNumber = chapterPages[chapter.href];
                      final isActive = _isCurrentChapter(
                        pageNumber,
                        currentPage,
                        i,
                        chapters.length,
                        chapterPages,
                        currentCfi,
                        chapter,
                        currentHref,
                      );
                      if (isActive) {
                        activeCount++;
                        firstActiveTitle ??= chapter.title;
                      }
                    }
                    print('CHAPTER DRAWER ACTIVE SUMMARY -> count: $activeCount, first: $firstActiveTitle, currentHref: $currentHref, currentCfi: $currentCfi');

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: chapters.length,
                      separatorBuilder: (context, index) {
                        final currentLevel = _getChapterLevel(chapters[index]);
                        final nextLevel = index + 1 < chapters.length ? _getChapterLevel(chapters[index + 1]) : 0;

                        if (currentLevel > 0 && nextLevel > 0) {
                          return Divider(
                            height: 1,
                            thickness: 0.3,
                            color: usedTheme.textColor.withOpacity(0.12),
                            indent: 16,
                            endIndent: 16,
                          );
                        }

                        return Divider(
                          height: 1,
                          thickness: 0.5,
                          color: usedTheme.textColor.withOpacity(0.18),
                          indent: 16,
                        );
                      },
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        final level = _getChapterLevel(chapter);
                        final pageNumber = chapterPages[chapter.href];

                        // Determine if this is the current chapter based on current href
                        final bool isCurrentChapter = _isCurrentChapter(
                          pageNumber,
                          currentPage,
                          index,
                          chapters.length,
                          chapterPages,
                          currentCfi,
                          chapter,
                          currentHref,
                        );

                        if (isCurrentChapter) {
                          print('CHAPTER DRAWER ACTIVE ROW -> title: ${chapter.title}, href: ${chapter.href}, page: $pageNumber');
                        }
                        return GestureDetector(
                          onTap: () {
                            final hasAnchor = chapter.id.isNotEmpty && !chapter.href.contains('#');
                            final target = hasAnchor ? '${chapter.href}#${chapter.id}' : chapter.href;
                            print(
                                '-------------------------------------------------------------CHAPTER DRAWER TAP -> title: ${chapter.title}, href: ${chapter.href}, id: ${chapter.id}, target: $target');
                            print('CHAPTER DRAWER STATE -> currentHref: $currentHref, currentCfi: $currentCfi');
                            controller.display(cfi: target);
                            Navigator.pop(context);
                          },
                          child: Container(
                            color: isCurrentChapter ? usedTheme.buttonBackgroundColor.withOpacity(0.4) : usedTheme.backgroundColor,
                            padding: EdgeInsets.symmetric(vertical: 25, horizontal: 25),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      chapter.title.trim(),
                                      textAlign: TextAlign.start,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isCurrentChapter ? usedTheme.textColor : usedTheme.textColor.withOpacity(0.65),
                                        fontSize: level > 0 ? 14 : 16,
                                        fontFamily: 'Gilroy',
                                        fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                                if (pageNumber != null)
                                  Text(
                                    '$pageNumber',
                                    style: TextStyle(
                                      color: isCurrentChapter ? usedTheme.textColor : usedTheme.textColor.withOpacity(0.5),
                                      fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.w400,
                                      fontFamily: 'Gilroy',
                                      fontSize: level > 0 ? 14 : 16,
                                    ),
                                  )
                                else if (isLoading)
                                  Container(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isCurrentChapter ? usedTheme.textColor : usedTheme.textColor.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _getChapterLevel(EpubChapter chapter) {
    // Check for subchapter indicators
    final title = chapter.title;

    // Count leading spaces or indentation
    if (title.startsWith('    ') || title.startsWith('\t\t')) return 2;
    if (title.startsWith('  ') || title.startsWith('\t')) return 1;

    // Check for bullet points or other indicators
    if (title.trimLeft().startsWith('•') || title.trimLeft().startsWith('-') || title.trimLeft().startsWith('○')) {
      return 1;
    }

    return 0;
  }

  static bool _isCurrentChapter(
    int? chapterPageNumber,
    int? currentPage,
    int chapterIndex,
    int totalChapters,
    Map<String, int> chapterPages,
    String? currentCfi,
    EpubChapter chapter,
    String? currentHref,
  ) {
    // First try to match by href (most accurate)
    if (currentHref != null && currentHref.isNotEmpty) {
      // Remove fragment identifiers (#...) for comparison
      String cleanCurrentHref = currentHref.split('#').first;
      String cleanChapterHref = chapter.href.split('#').first;

      // Direct match
      if (cleanChapterHref == cleanCurrentHref) {
        print('CHAPTER DRAWER ACTIVE -> title: ${chapter.title}, href: ${chapter.href} (href match)');
        return true;
      }

      // Check if current href ends with chapter href (for relative paths)
      if (cleanCurrentHref.endsWith(cleanChapterHref) || cleanChapterHref.endsWith(cleanCurrentHref)) {
        print('CHAPTER DRAWER ACTIVE -> title: ${chapter.title}, href: ${chapter.href} (href partial match)');
        return true;
      }
      // If we have a current href but no match, do not fall back to page numbers
      return false;
    }

    // Second try: match by CFI if available
    if (currentCfi != null && currentCfi.isNotEmpty) {
      // Try to match by anchor id inside CFI, e.g. [calibre_toc_2]
      final anchorMatch = RegExp(r'\[([^\]]+)\]').firstMatch(currentCfi);
      if (anchorMatch != null) {
        final anchorId = anchorMatch.group(1);
        if (anchorId != null && anchorId.isNotEmpty) {
          if (chapter.id == anchorId) {
            print('CHAPTER DRAWER ACTIVE -> title: ${chapter.title}, href: ${chapter.href} (cfi anchor match: $anchorId, id match)');
            return true;
          }
          if (chapter.href.contains('#$anchorId') || chapter.href.endsWith(anchorId)) {
            print('CHAPTER DRAWER ACTIVE -> title: ${chapter.title}, href: ${chapter.href} (cfi anchor match: $anchorId, href match)');
            return true;
          }
        }
      }

      // Extract spine index from CFI: epubcfi(/6/22!/4/56/1:214) -> 22
      final spineMatch = RegExp(r'/6/(\d+)!').firstMatch(currentCfi);
      if (spineMatch != null) {
        final spineIndex = spineMatch.group(1);
        // Check if chapter href contains this spine index
        // e.g., index_split_010.xhtml contains "010" which could match spine index
        if (chapter.href.contains('_$spineIndex.') || chapter.href.contains('_0$spineIndex.')) {
          return true;
        }
      }
    }

    // If we have a CFI but it did not match, do not fall back to page numbers
    if (currentCfi != null && currentCfi.isNotEmpty) {
      return false;
    }

    // Fallback to page number comparison
    if (chapterPageNumber == null || currentPage == null) {
      return false;
    }

    // Get next chapter's page number from the chapters list
    final sortedPages = chapterPages.values.toList()..sort();

    // Find the current chapter's position in sorted pages
    final currentChapterPageIndex = sortedPages.indexOf(chapterPageNumber);

    if (currentChapterPageIndex < 0) {
      return false;
    }

    // Get the next chapter's page
    final nextChapterPage = currentChapterPageIndex + 1 < sortedPages.length ? sortedPages[currentChapterPageIndex + 1] : null;

    // Current chapter if currentPage is between this chapter's page and next chapter's page
    if (nextChapterPage != null) {
      final isActive = currentPage >= chapterPageNumber && currentPage < nextChapterPage;
      return isActive;
    } else {
      // Last chapter - just check if current page is >= chapter page
      final isActive = currentPage >= chapterPageNumber;
      return isActive;
    }
  }

  static String? _extractHrefFromCfi(String? cfi) {
    if (cfi == null || cfi.isEmpty) return null;

    // CFI format usually contains the href in the beginning
    // Example: "epubcfi(/6/4[chapter1]!/4/2/1:0)"
    // or just the href like "chapter1.xhtml"
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(cfi);
    if (match != null) {
      return match.group(1);
    }

    // If no brackets, check if it contains .xhtml or .html
    if (cfi.contains('.xhtml') || cfi.contains('.html')) {
      final parts = cfi.split('!');
      if (parts.isNotEmpty) {
        return parts[0].replaceAll('epubcfi(', '').trim();
      }
    }

    return null;
  }

  static Future<Map<String, int>> _getChapterPages(
    EpubController controller,
    List<EpubChapter> chapters,
    bool isLoadingPages,
  ) async {
    final Map<String, int> chapterPages = {};

    if (isLoadingPages) {
      return chapterPages;
    }

    try {
      final pageInfo = await controller.getPageInfo();
      final totalPages = pageInfo['totalPages'] ?? 1;

      for (int i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];
        // Use only href without fragment to get the start page of the chapter file
        // This ensures we get the actual file start, not a mid-file anchor
        final target = chapter.href.split('#').first;
        final page = await controller.getPageFromCfi(target);
        if (page != null) {
          final clampedPage = page.clamp(1, totalPages);
          chapterPages[chapter.href] = clampedPage;
          print('CHAPTER DRAWER PAGE MAP -> title: ${chapter.title}, href: ${chapter.href}, target: $target, page: $clampedPage');
        }
      }

      if (chapterPages.isEmpty) {
        // Fallback: distribute pages evenly if no page data returned
        for (int i = 0; i < chapters.length; i++) {
          final chapter = chapters[i];
          final estimatedPage = ((i * totalPages) / chapters.length).ceil() + 1;
          chapterPages[chapter.href] = estimatedPage.clamp(1, totalPages);
        }
      }
    } catch (e) {
      for (int i = 0; i < chapters.length; i++) {
        chapterPages[chapters[i].href] = i + 1;
      }
    }

    // Log chapter titles with their starting pages when the drawer loads.
    for (final chapter in chapters) {
      final page = chapterPages[chapter.href];
      print('CHAPTER DRAWER OPEN -> title: ${chapter.title}, startPage: ${page ?? "?"}');
    }

    return chapterPages;
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverBase64, required this.placeholderColor});

  final String? coverBase64;
  final Color placeholderColor;

  @override
  Widget build(BuildContext context) {
    if (coverBase64 != null && coverBase64!.isNotEmpty) {
      try {
        final bytes = base64.decode(coverBase64!);
        return Container(
          height: 80,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: placeholderColor,
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, color: Colors.white));
            },
          ),
        );
      } catch (_) {
        // Ignore decoding errors and fall back to placeholder
      }
    }

    return Container(
      height: 80,
      width: 60,
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: const Center(
        child: Icon(Icons.book, size: 40, color: Colors.white),
      ),
    );
  }
}
