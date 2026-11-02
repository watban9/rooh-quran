
class QuranPages {
  static const int totalPages = 604;

  static String assetPath(int page) {
    if (page < 1 || page > totalPages) {
      throw RangeError.range(page, 1, totalPages, 'page');
    }

    return 'assets/quran_pages/$page.png';
  }
}
