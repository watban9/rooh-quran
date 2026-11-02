import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_pages.dart';

const Color forest = Color(0xFF0B3D2E);
const Color gold = Color(0xFFD6B15E);
const Color cream = Color(0xFFF8F7F1);

class QuranPageViewer extends StatefulWidget {
  final int initialPage;

  const QuranPageViewer({
    super.key,
    this.initialPage = 1,
  });

  @override
  State<QuranPageViewer> createState() =>
      _QuranPageViewerState();
}

class _QuranPageViewerState extends State<QuranPageViewer> {
  late final PageController _pageController;

  int currentPage = 1;

  @override
  void initState() {
    super.initState();

    currentPage = widget.initialPage.clamp(
      1,
      QuranPages.totalPages,
    );

    _pageController = PageController(
      initialPage: currentPage - 1,
    );

    _loadLastPage();
  }

  Future<void> _loadLastPage() async {
    final prefs = await SharedPreferences.getInstance();

    final savedPage = prefs.getInt('lastQuranPage');

    if (!mounted || savedPage == null) return;

    final page = savedPage.clamp(
      1,
      QuranPages.totalPages,
    );

    setState(() {
      currentPage = page;
    });

    _pageController.jumpToPage(page - 1);
  }

  Future<void> _savePage(int page) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('lastQuranPage', page);
  }

  void _onPageChanged(int index) {
    final page = index + 1;

    setState(() {
      currentPage = page;
    });

    _savePage(page);
  }

  void _goToPage(int page) {
    final safePage = page.clamp(
      1,
      QuranPages.totalPages,
    );

    _pageController.animateToPage(
      safePage - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    if (currentPage < QuranPages.totalPages) {
      _goToPage(currentPage + 1);
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      _goToPage(currentPage - 1);
    }
  }

  Future<void> _showPagePicker() async {
    final controller = TextEditingController(
      text: currentPage.toString(),
    );

    final selectedPage = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('الانتقال إلى صفحة'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'رقم الصفحة من 1 إلى 604',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: forest,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final page = int.tryParse(
                    controller.text.trim(),
                  );

                  if (page == null ||
                      page < 1 ||
                      page > QuranPages.totalPages) {
                    ScaffoldMessenger.of(dialogContext)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'أدخل رقم صفحة صحيح من 1 إلى 604',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, page);
                },
                child: const Text('انتقال'),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (selectedPage != null) {
      _goToPage(selectedPage);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: cream,

        appBar: AppBar(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: gold,
              ),
              SizedBox(width: 10),
              Text(
                'مصحف المدينة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'الانتقال إلى صفحة',
              onPressed: _showPagePicker,
              icon: const Icon(
                Icons.grid_view_rounded,
                color: gold,
              ),
            ),
          ],
        ),

        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                reverse: true,
                itemCount: QuranPages.totalPages,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = index + 1;

                  return Container(
                    color: cream,
                    padding: const EdgeInsets.all(5),
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: SizedBox.expand(
                        child: Image.asset(
                          QuranPages.assetPath(page),
                          fit: BoxFit.contain,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 55,
                                    color: forest,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'تعذر تحميل صفحة المصحف',
                                    style: TextStyle(
                                      color: forest,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(
                14,
                8,
                14,
                12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE5E0D2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: currentPage > 1
                            ? _previousPage
                            : null,
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                        ),
                        color: forest,
                        tooltip: 'الصفحة السابقة',
                      ),

                      InkWell(
                        onTap: _showPagePicker,
                        borderRadius:
                            BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: forest,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            'صفحة $currentPage من 604',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed:
                            currentPage < QuranPages.totalPages
                                ? _nextPage
                                : null,
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                        ),
                        color: forest,
                        tooltip: 'الصفحة التالية',
                      ),
                    ],
                  ),

                  Slider(
                    value: currentPage.toDouble(),
                    min: 1,
                    max: QuranPages.totalPages.toDouble(),
                    divisions: QuranPages.totalPages - 1,
                    activeColor: forest,
                    inactiveColor: gold.withOpacity(0.3),
                    onChanged: (value) {
                      _pageController.jumpToPage(
                        value.round() - 1,
                      );
                    },
                  ),

                  const Text(
                    'اضغط على الصفحة للتكبير، واسحب للتنقل',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
