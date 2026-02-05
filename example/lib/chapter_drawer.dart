import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter/material.dart';

class ChapterDrawer {
  static void show(BuildContext context, EpubController controller) {
    final chapters = controller.getChapters();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header with book info
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Book cover placeholder
                    Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.book, size: 40),
                    ),
                    const SizedBox(width: 16),
                    // Book title
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konstruirovanie yazykov:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ot esperanto do dotrakiiskogo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sahypa 11 dan 213',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Chapters list
              Expanded(
                child: FutureBuilder<Map<String, int>>(
                  future: _getChapterPages(controller, chapters),
                  builder: (context, snapshot) {
                    final chapterPages = snapshot.data ?? {};

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        final level = _getChapterLevel(chapter);
                        final pageNumber = chapterPages[chapter.href];

                        return ListTile(
                          contentPadding: EdgeInsets.only(
                            left: 20 + (level * 20.0),
                            right: 20,
                          ),
                          leading: level > 0 ? const Icon(Icons.circle, size: 6) : null,
                          title: Text(
                            chapter.title,
                            style: TextStyle(
                              fontSize: level > 0 ? 14 : 16,
                              fontWeight: level > 0 ? FontWeight.normal : FontWeight.w500,
                            ),
                          ),
                          trailing: pageNumber != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Syf $pageNumber',
                                    style: TextStyle(
                                      color: Colors.deepPurple.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                          onTap: () {
                            controller.display(cfi: chapter.href);
                            Navigator.pop(context);
                          },
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
    // Simple heuristic: count dots or check if it's a subchapter
    if (chapter.title.startsWith('•') || chapter.title.contains('  ')) {
      return 1;
    }
    return 0;
  }

  static Future<Map<String, int>> _getChapterPages(
    EpubController controller,
    List<EpubChapter> chapters,
  ) async {
    final Map<String, int> chapterPages = {};

    try {
      // Get total pages first
      final pageInfo = await controller.getPageInfo();
      final totalPages = pageInfo['totalPages'] ?? 1;

      // Estimate page numbers based on chapter position
      // This is a rough estimation: distribute chapters evenly
      if (chapters.isNotEmpty && totalPages > 1) {
        final pagesPerChapter = totalPages / chapters.length;

        for (int i = 0; i < chapters.length; i++) {
          final chapter = chapters[i];
          // Estimate page: 1-based index
          final estimatedPage = (i * pagesPerChapter).round() + 1;
          chapterPages[chapter.href] = estimatedPage.clamp(1, totalPages);
        }
      } else {
        // Fallback: just number them sequentially
        for (int i = 0; i < chapters.length; i++) {
          chapterPages[chapters[i].href] = i + 1;
        }
      }
    } catch (e) {
      print('Error getting chapter pages: $e');
      // Fallback: sequential numbering
      for (int i = 0; i < chapters.length; i++) {
        chapterPages[chapters[i].href] = i + 1;
      }
    }

    return chapterPages;
  }
}
