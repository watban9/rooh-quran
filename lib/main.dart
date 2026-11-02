
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}

class Surah {
  final int number;
  final String name;
  final String englishName;
  final int verses;
  final String revelation;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.verses,
    required this.revelation,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      verses: json['numberOfAyahs'],
      revelation: json['revelationType'],
    );
  }
}

class QuranService {
  static Future<List<Surah>> getSurahs() async {
    final response = await http.get(
      Uri.parse('https://api.alquran.cloud/v1/surah'),
    );

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل فهرس القرآن');
    }

    final data = jsonDecode(response.body);
    return (data['data'] as List)
        .map((item) => Surah.fromJson(item))
        .toList();
  }

  static Future<List<dynamic>> getVerses(int number) async {
    final response = await http.get(
      Uri.parse('https://api.alquran.cloud/v1/surah/$number'),
    );

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل السورة');
    }

    final data = jsonDecode(response.body);
    return data['data']['ayahs'];
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Surah>> surahsFuture;
  final TextEditingController searchController = TextEditingController();
  String search = '';
  int lastSurah = 1;

  @override
  void initState() {
    super.initState();
    surahsFuture = QuranService.getSurahs();
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: gold, size: 29),
              SizedBox(width: 10),
              Text(
                'رَوْح',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 7),
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
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: FutureBuilder<List<Surah>>(
          future: surahsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: green),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 45, color: forest),
                    const SizedBox(height: 12),
                    const Text('تعذر الاتصال بالقرآن الكريم'),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          surahsFuture = QuranService.getSurahs();
                        });
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            final surahs = snapshot.data ?? [];
            final filtered = surahs.where((surah) {
              return surah.name.contains(search) ||
                  surah.englishName.toLowerCase().contains(
                    search.toLowerCase(),
                  ) ||
                  surah.number.toString() == search;
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(23),
                  decoration: BoxDecoration(
                    color: forest,
                    borderRadius: BorderRadius.circular(22),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=900',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.13,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.auto_awesome, color: gold, size: 30),
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
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'تابع قراءتك',
                  style: TextStyle(
                    color: forest,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final surah = surahs.firstWhere(
                      (s) => s.number == lastSurah,
                      orElse: () => surahs.first,
                    );
                    openSurah(surah);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gold.withValues(alpha: 0.6)),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: forest,
                          child: Icon(Icons.menu_book, color: gold),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'متابعة آخر قراءة',
                                style: TextStyle(
                                  color: forest,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'اضغط للعودة إلى آخر سورة',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_back_ios, color: gold, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 23),
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
                    setState(() => search = value.trim());
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن سورة أو رقمها...',
                    prefixIcon: const Icon(Icons.search, color: green),
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
                      style: const TextStyle(color: Colors.black54),
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
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: gold.withValues(alpha: 0.25),
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              label: 'القرآن',
            ),
            NavigationDestination(
              icon: Icon(Icons.headphones_outlined),
              label: 'التلاوة',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              label: 'المحفوظات',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openSurah(Surah surah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSurah', surah.number);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahPage(surah: surah),
      ),
    );
  }
}

class SurahTile extends StatelessWidget {
  final Surah surah;
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
        side: BorderSide(color: gold.withValues(alpha: 0.35)),
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
          '${surah.verses} آية • ${surah.revelation == 'Meccan' ? 'مكية' : 'مدنية'}',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_back_ios, color: gold, size: 16),
      ),
    );
  }
}

class SurahPage extends StatelessWidget {
  final Surah surah;

  const SurahPage({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          title: Text(surah.name),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: QuranService.getVerses(surah.number),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: green),
              );
            }

            if (snapshot.hasError) {
              return const Center(child: Text('تعذر تحميل الآيات'));
            }

            final verses = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: forest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome, color: gold, size: 27),
                      const SizedBox(height: 10),
                      Text(
                        surah.name,
                        style: const TextStyle(
                          color: gold,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${surah.verses} آية',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (surah.number != 1 && surah.number != 9)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 25),
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        height: 2,
                        color: forest,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ...verses.map(
                  (verse) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: gold.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          verse['text'],
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            color: forest,
                            fontSize: 23,
                            height: 2.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: forest,
                            child: Text(
                              '${verse['numberInSurah']}',
                              style: const TextStyle(
                                color: gold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
