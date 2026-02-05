import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

class ChapterDrawer {
  static Future<void> show(
    BuildContext context,
    EpubController controller, {
    String? bookTitle,
    int? currentPage,
    int? totalPages,
    String? currentCfi,
  }) async {
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
            color: Colors.white,
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
                    _CoverImage(coverBase64: metadata.coverImage),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookTitle ?? metadata.title ?? 'Contents',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
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
                                  color: Colors.black.withOpacity(0.55),
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${currentPage ?? 1} of $totalPages',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
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
                        backgroundColor: Colors.grey[300],
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),
              Expanded(
                child: FutureBuilder<Map<String, int>>(
                  future: _getChapterPages(controller, chapters),
                  builder: (context, snapshot) {
                    final chapterPages = snapshot.data ?? {};
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;

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
                            color: Colors.grey.withOpacity(0.2),
                            indent: 16,
                            endIndent: 16,
                          );
                        }

                        return Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey.withOpacity(0.3),
                          indent: 16,
                        );
                      },
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        final level = _getChapterLevel(chapter);
                        final pageNumber = chapterPages[chapter.href];

                        // Determine if this is the current chapter based on current page
                        final bool isCurrentChapter = _isCurrentChapter(
                          pageNumber,
                          currentPage,
                          index,
                          chapters.length,
                          chapterPages,
                          currentCfi,
                          chapter,
                        );

                        return GestureDetector(
                          onTap: () {
                            controller.display(cfi: chapter.href);
                            Navigator.pop(context);
                          },
                          child: Container(
                            color: isCurrentChapter ? Colors.grey[200] : Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 25, horizontal: 25),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    chapter.title.trim(),
                                    textAlign: TextAlign.start,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isCurrentChapter ? Colors.black : Colors.grey,
                                      fontSize: level > 0 ? 14 : 16,
                                      fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (pageNumber != null)
                                  Text(
                                    '$pageNumber',
                                    style: TextStyle(
                                      color: isCurrentChapter ? Colors.black : Color(0xff3C3C434D).withOpacity(0.3),
                                      fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.w400,
                                      fontSize: level > 0 ? 14 : 16,
                                    ),
                                  )
                                else if (isLoading)
                                  Container(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(isCurrentChapter ? Colors.black : Color(0xff3C3C434D).withOpacity(0.3)),
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
  ) {
    // First try to match by CFI if available
    if (currentCfi != null && currentCfi.isNotEmpty) {
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
  ) async {
    final Map<String, int> chapterPages = {};

    try {
      final pageInfo = await controller.getPageInfo();
      final totalPages = pageInfo['totalPages'] ?? 1;

      // Simple estimation: distribute pages evenly across chapters
      for (int i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];
        // Distribute pages more evenly
        final estimatedPage = ((i * totalPages) / chapters.length).ceil() + 1;
        chapterPages[chapter.href] = estimatedPage.clamp(1, totalPages);
      }
    } catch (e) {
      for (int i = 0; i < chapters.length; i++) {
        chapterPages[chapters[i].href] = i + 1;
      }
    }

    return chapterPages;
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverBase64});

  final String? coverBase64;

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
            color: Colors.grey[300],
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
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: const Center(
        child: Icon(Icons.book, size: 40, color: Colors.white),
      ),
    );
  }
}
