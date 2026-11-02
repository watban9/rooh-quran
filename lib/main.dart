import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/quran_page_viewer.dart';
import 'screens/quran_reciters_page.dart';
import 'services/quran_local_service.dart';

const Color forest = Color(0xFF0B3D2E);
const Color green = Color(0xFF176B4D);
const Color gold = Color(0xFFD6B15E);
const Color cream = Color(0xFFF8F7F1);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoohApp());
}

class RoohApp extends StatelessWidget {
  const RoohApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رَوْح | ROOH',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: forest,
          primary: forest,
          secondary: gold,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<QuranSurah>> surahsFuture;

  final TextEditingController searchController =
      TextEditingController();

  String search = '';
  int lastSurah = 1;

  @override
  void initState() {
    super.initState();
    surahsFuture = QuranLocalService.loadSurahs();
    loadLastSurah();
  }

  Future<void> loadLastSurah() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      lastSurah = prefs.getInt('lastSurah') ?? 1;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> openSurah(QuranSurah surah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSurah', surah.number);

    if (!mounted) return;

    setState(() {
      lastSurah = surah.number;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahPage(surah: surah),
      ),
    );
  }

  void openMushaf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuranPageViewer(),
      ),
    );
  }

  void openReciters() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuranRecitersPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: gold,
                size: 29,
              ),
              SizedBox(width: 10),
              Text(
                'رَوْح',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'ROOH',
                style: TextStyle(
                  fontSize: 13,
                  color: gold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'التلاوات القرآنية',
              onPressed: openReciters,
              icon: const Icon(
                Icons.headphones_rounded,
                color: gold,
              ),
            ),
            IconButton(
              tooltip: 'المصحف الشريف',
              onPressed: openMushaf,
              icon: const Icon(
                Icons.menu_book_rounded,
                color: gold,
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<QuranSurah>>(
          future: surahsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: green,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: forest,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'تعذر قراءة ملف القرآن',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تأكد من وجود ملف القرآن داخل assets/data',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            surahsFuture =
                                QuranLocalService.loadSurahs();
                          });
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final surahs = snapshot.data ?? [];

            final filtered = surahs.where((surah) {
              return surah.name.contains(search) ||
                  surah.number.toString() == search;
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(23),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [forest, green],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: gold,
                        size: 30,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          height: 1.8,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'رحلتك مع كتاب الله تبدأ من هنا',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'المصحف الشريف',
                  style: TextStyle(
                    color: forest,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),

                const SizedBox(height: 10),

                FeatureCard(
                  icon: Icons.menu_book_rounded,
                  title: 'فتح مصحف المدينة',
                  subtitle: '604 صفحة • تكبير وتصغير',
                  onTap: openMushaf,
                ),

                const SizedBox(height: 18),

                const Text(
                  'الاستماع إلى القرآن',
                  style: TextStyle(
                    color: forest,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),

                const SizedBox(height: 10),

                FeatureCard(
                  icon: Icons.headphones_rounded,
                  title: 'القراء والتلاوات',
                  subtitle: 'استمع إلى القراء الخمسة',
                  onTap: openReciters,
                ),

                const SizedBox(height: 22),

                const Text(
                  'تابع قراءتك',
                  style: TextStyle(
                    color: forest,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),

                const SizedBox(height: 10),

                FeatureCard(
                  icon: Icons.bookmark_rounded,
                  title: 'متابعة آخر قراءة',
                  subtitle: 'العودة إلى آخر سورة قرأتها',
                  onTap: () {
                    if (surahs.isEmpty) return;

                    final index = (lastSurah - 1)
                        .clamp(0, surahs.length - 1)
                        .toInt();

                    openSurah(surahs[index]);
                  },
                ),

                const SizedBox(height: 22),

                const Text(
                  'القرآن الكريم',
                  style: TextStyle(
                    color: forest,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      search = value.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن سورة أو رقمها...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: green,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Text(
                      'فهرس السور',
                      style: TextStyle(
                        color: forest,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length} سورة',
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ...filtered.map(
                  (surah) => SurahTile(
                    surah: surah,
                    onTap: () => openSurah(surah),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: gold.withOpacity(0.7),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: forest,
              child: Icon(
                icon,
                color: gold,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: forest,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_back_ios,
              color: gold,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class SurahTile extends StatelessWidget {
  final QuranSurah surah;
  final VoidCallback onTap;

  const SurahTile({
    super.key,
    required this.surah,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: gold.withOpacity(0.35),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: forest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${surah.number}',
            style: const TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          surah.name,
          style: const TextStyle(
            color: forest,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '${surah.verses} آية',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_back_ios,
          color: gold,
          size: 16,
        ),
      ),
    );
  }
}

class SurahPage extends StatelessWidget {
  final QuranSurah surah;

  const SurahPage({
    super.key,
    required this.surah,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          title: Text(surah.name),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: forest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: gold,
                    size: 27,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    surah.name,
                    style: const TextStyle(
                      color: gold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${surah.verses} آية',
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (surah.number != 1 && surah.number != 9)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: forest,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    height: 2,
                  ),
                ),
              ),

            ...surah.ayahs.map(
              (ayah) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: gold.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${ayah.text} ۝${ayah.ayahNumber}',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    color: forest,
                    fontSize: 21,
                    height: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
