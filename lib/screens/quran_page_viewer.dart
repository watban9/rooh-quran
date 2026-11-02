
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quran_pages.dart';

class QuranPageViewer extends StatefulWidget {
  final int initialPage;

  const QuranPageViewer({
    super.key,
    this.initialPage = 1,
  });

  @override
  State<QuranPageViewer> createState() => _QuranPageViewerState();
}

class _QuranPageViewerState extends State<QuranPageViewer> {
  late final PageController controller;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage.clamp(1, 604);
    controller = PageController(initialPage: currentPage - 1);
  }

  Future<void> savePage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastQuranPage', page);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F7F1),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B3D2E),
          foregroundColor: Colors.white,
          title: Text('المصحف الشريف - صفحة $currentPage'),
        ),
        body: PageView.builder(
          controller: controller,
          reverse: true,
          itemCount: QuranPages.totalPages,
          onPageChanged: (index) {
            setState(() => currentPage = index + 1);
            savePage(currentPage);
          },
          itemBuilder: (context, index) {
            final page = index + 1;
            return InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.asset(
                  QuranPages.assetPath(page),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'صفحة المصحف غير مضافة بعد',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          color: const Color(0xFF0B3D2E),
          padding: const EdgeInsets.all(12),
          child: Text(
            'صفحة $currentPage من 604',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
