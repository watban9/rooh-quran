
import 'package:flutter/services.dart';

class QuranAyah {
  final int surahNumber;
  final int ayahNumber;
  final String text;

  const QuranAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
  });
}

class QuranSurah {
  final int number;
  final String name;
  final List<QuranAyah> ayahs;

  const QuranSurah({
    required this.number,
    required this.name,
    required this.ayahs,
  });

  int get verses => ayahs.length;
}

class QuranLocalService {
  static const String assetPath =
      'assets/data/quran-uthmani.txt';

  static const List<String> surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء',
    'المائدة', 'الأنعام', 'الأعراف', 'الأنفال',
    'التوبة', 'يونس', 'هود', 'يوسف',
    'الرعد', 'إبراهيم', 'الحجر', 'النحل',
    'الإسراء', 'الكهف', 'مريم', 'طه',
    'الأنبياء', 'الحج', 'المؤمنون', 'النور',
    'الفرقان', 'الشعراء', 'النمل', 'القصص',
    'العنكبوت', 'الروم', 'لقمان', 'السجدة',
    'الأحزاب', 'سبأ', 'فاطر', 'يس',
    'الصافات', 'ص', 'الزمر', 'غافر',
    'فصلت', 'الشورى', 'الزخرف', 'الدخان',
    'الجاثية', 'الأحقاف', 'محمد', 'الفتح',
    'الحجرات', 'ق', 'الذاريات', 'الطور',
    'النجم', 'القمر', 'الرحمن', 'الواقعة',
    'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
    'الصف', 'الجمعة', 'المنافقون', 'التغابن',
    'الطلاق', 'التحريم', 'الملك', 'القلم',
    'الحاقة', 'المعارج', 'نوح', 'الجن',
    'المزمل', 'المدثر', 'القيامة', 'الإنسان',
    'المرسلات', 'النبأ', 'النازعات', 'عبس',
    'التكوير', 'الانفطار', 'المطففين', 'الانشقاق',
    'البروج', 'الطارق', 'الأعلى', 'الغاشية',
    'الفجر', 'البلد', 'الشمس', 'الليل',
    'الضحى', 'الشرح', 'التين', 'العلق',
    'القدر', 'البينة', 'الزلزلة', 'العاديات',
    'القارعة', 'التكاثر', 'العصر', 'الهمزة',
    'الفيل', 'قريش', 'الماعون', 'الكوثر',
    'الكافرون', 'النصر', 'المسد', 'الإخلاص',
    'الفلق', 'الناس',
  ];

  static Future<List<QuranSurah>> loadSurahs() async {
    final raw = await rootBundle.loadString(assetPath);

    final Map<int, List<QuranAyah>> grouped = {};

    for (final line in raw.split('\n')) {
      final parts = line.trim().split('|');

      if (parts.length != 3) continue;

      final surahNumber = int.tryParse(parts[0]);
      final ayahNumber = int.tryParse(parts[1]);

      if (surahNumber == null ||
          ayahNumber == null ||
          surahNumber < 1 ||
          surahNumber > 114) {
        continue;
      }

      grouped.putIfAbsent(surahNumber, () => []);

      grouped[surahNumber]!.add(
        QuranAyah(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          text: parts[2],
        ),
      );
    }

    final result = <QuranSurah>[];

    for (int i = 1; i <= 114; i++) {
      final ayahs = grouped[i] ?? [];

      if (ayahs.isEmpty) {
        throw Exception(
          'بيانات سورة ${surahNames[i - 1]} غير موجودة',
        );
      }

      ayahs.sort(
        (a, b) => a.ayahNumber.compareTo(b.ayahNumber),
      );

      result.add(
        QuranSurah(
          number: i,
          name: surahNames[i - 1],
          ayahs: ayahs,
        ),
      );
    }

    return result;
  }

  static Future<QuranSurah> loadSurah(int number) async {
    if (number < 1 || number > 114) {
      throw RangeError('رقم السورة غير صحيح');
    }

    final surahs = await loadSurahs();
    return surahs[number - 1];
  }
}
