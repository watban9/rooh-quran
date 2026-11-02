import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/audio_download_service.dart';
import '../services/quran_local_service.dart';

const Color reciterForest = Color(0xFF0B3D2E);
const Color reciterGreen = Color(0xFF176B4D);
const Color reciterGold = Color(0xFFD6B15E);
const Color reciterCream = Color(0xFFF8F7F1);

class QuranReciter {
  final String name;
  final String folder;

  const QuranReciter({
    required this.name,
    required this.folder,
  });
}

class QuranRecitersPage extends StatefulWidget {
  const QuranRecitersPage({super.key});

  @override
  State<QuranRecitersPage> createState() => _QuranRecitersPageState();
}

class _QuranRecitersPageState extends State<QuranRecitersPage> {
  final AudioPlayer player = AudioPlayer();

  final List<QuranReciter> reciters = const [
    QuranReciter(
      name: 'مشاري العفاسي',
      folder: 'Alafasy_128kbps',
    ),
    QuranReciter(
      name: 'عبد الرحمن السديس',
      folder: 'Abdurrahmaan_As-Sudais_192kbps',
    ),
    QuranReciter(
      name: 'ماهر المعيقلي',
      folder: 'MaherAlMuaiqly128kbps',
    ),
    QuranReciter(
      name: 'عبد الباسط عبد الصمد',
      folder: 'Abdul_Basit_Murattal_192kbps',
    ),
    QuranReciter(
      name: 'محمود خليل الحصري',
      folder: 'Husary_128kbps',
    ),
  ];

  List<QuranSurah> surahs = [];

  int selectedReciter = 0;
  int selectedSurah = 1;

  bool loading = true;
  bool downloading = false;

  double downloadProgress = 0;

  String statusMessage = 'اختر القارئ والسورة للاستماع';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final loaded = await QuranLocalService.loadSurahs();
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      final lastReciter = prefs.getInt('lastReciter') ?? 0;
      final lastSurah = prefs.getInt('lastAudioSurah') ?? 1;

      setState(() {
        surahs = loaded;

        selectedReciter =
            lastReciter.clamp(0, reciters.length - 1).toInt();

        selectedSurah =
            lastSurah.clamp(1, loaded.length).toInt();

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        statusMessage = 'تعذر تحميل بيانات القرآن';
      });
    }
  }

  Future<void> saveSelection() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('lastReciter', selectedReciter);
    await prefs.setInt('lastAudioSurah', selectedSurah);
  }

  String audioFileName(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');

    return '${reciters[selectedReciter].folder}_${s}_$a.mp3';
  }

  String audioUrl(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');

    return 'https://everyayah.com/data/'
        '${reciters[selectedReciter].folder}/$s$a.mp3';
  }

  Future<Uri> getAyahUri(
    QuranAyah ayah,
    Directory directory,
  ) async {
    final fileName = audioFileName(
      ayah.surahNumber,
      ayah.ayahNumber,
    );

    final file = File(
      '${directory.path}/rooh_audio/$fileName',
    );

    if (await file.exists()) {
      return Uri.file(file.path);
    }

    return Uri.parse(
      audioUrl(
        ayah.surahNumber,
        ayah.ayahNumber,
      ),
    );
  }

  Future<void> playSurah() async {
    if (surahs.isEmpty) return;

    try {
      await saveSelection();

      if (mounted) {
        setState(() {
          statusMessage = 'جاري تجهيز التلاوة...';
        });
      }

      await player.stop();

      final surah = surahs[selectedSurah - 1];
      final directory = await getApplicationDocumentsDirectory();

      final sources = <AudioSource>[];

      for (final ayah in surah.ayahs) {
        final uri = await getAyahUri(ayah, directory);
        sources.add(AudioSource.uri(uri));
      }

      if (sources.isEmpty) {
        throw Exception('السورة لا تحتوي على آيات');
      }

      final playlist = ConcatenatingAudioSource(
        children: sources,
      );

      await player.setAudioSource(playlist);
      await player.play();

      if (!mounted) return;

      setState(() {
        statusMessage =
            'تلاوة سورة ${surah.name} بصوت '
            '${reciters[selectedReciter].name}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        statusMessage =
            'تعذر تشغيل التلاوة. تحقق من اتصال الإنترنت.';
      });
    }
  }

  Future<void> downloadSurah() async {
    if (surahs.isEmpty || downloading) return;

    final surah = surahs[selectedSurah - 1];

    setState(() {
      downloading = true;
      downloadProgress = 0;
      statusMessage = 'جاري تنزيل سورة ${surah.name}...';
    });

    try {
      int completed = 0;

      for (final ayah in surah.ayahs) {
        final fileName = audioFileName(
          ayah.surahNumber,
          ayah.ayahNumber,
        );

        final exists =
            await AudioDownloadService.isDownloaded(fileName);

        if (!exists) {
          await AudioDownloadService.downloadAudio(
            url: audioUrl(
              ayah.surahNumber,
              ayah.ayahNumber,
            ),
            fileName: fileName,
            onProgress: null,
          );
        }

        completed++;

        if (!mounted) return;

        setState(() {
          downloadProgress =
              completed / surah.ayahs.length;
        });
      }

      if (!mounted) return;

      setState(() {
        statusMessage =
            'تم تنزيل سورة ${surah.name} للاستماع دون إنترنت';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اكتمل تنزيل السورة بنجاح'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        statusMessage =
            'فشل التنزيل. تحقق من اتصال الإنترنت.';
      });
    } finally {
      if (mounted) {
        setState(() {
          downloading = false;
        });
      }
    }
  }

  Future<void> changeSurah(int? value) async {
    if (value == null) return;

    await player.stop();

    if (!mounted) return;

    setState(() {
      selectedSurah = value;
      statusMessage =
          'تم اختيار سورة ${surahs[value - 1].name}';
    });

    await saveSelection();
  }

  Future<void> changeReciter(int? value) async {
    if (value == null) return;

    await player.stop();

    if (!mounted) return;

    setState(() {
      selectedReciter = value;
      statusMessage =
          'تم اختيار ${reciters[value].name}';
    });

    await saveSelection();
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    final seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: reciterCream,
        body: Center(
          child: CircularProgressIndicator(
            color: reciterGreen,
          ),
        ),
      );
    }

    if (surahs.isEmpty) {
      return Scaffold(
        backgroundColor: reciterCream,
        appBar: AppBar(
          title: const Text('التلاوات القرآنية'),
          backgroundColor: reciterForest,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(statusMessage),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: reciterCream,
        appBar: AppBar(
          backgroundColor: reciterForest,
          foregroundColor: Colors.white,
          title: const Text(
            'التلاوات القرآنية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(
            color: reciterGold,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    reciterForest,
                    reciterGreen,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.headphones_rounded,
                    color: reciterGold,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'استمع إلى القرآن الكريم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'اختر قارئك المفضل واستمتع بالتلاوة',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'اختر القارئ',
              style: TextStyle(
                color: reciterForest,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 9),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: reciterGold),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedReciter,
                  isExpanded: true,
                  items: List.generate(
                    reciters.length,
                    (index) => DropdownMenuItem<int>(
                      value: index,
                      child: Text(reciters[index].name),
                    ),
                  ),
                  onChanged: downloading ? null : changeReciter,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'اختر السورة',
              style: TextStyle(
                color: reciterForest,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 9),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: reciterGold),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedSurah,
                  isExpanded: true,
                  items: surahs.map((surah) {
                    return DropdownMenuItem<int>(
                      value: surah.number,
                      child: Text(
                        '${surah.number}. ${surah.name}',
                      ),
                    );
                  }).toList(),
                  onChanged: downloading ? null : changeSurah,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: reciterGold.withOpacity(0.7),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.library_music_rounded,
                    color: reciterGreen,
                    size: 42,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    surahs[selectedSurah - 1].name,
                    style: const TextStyle(
                      color: reciterForest,
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'القارئ: ${reciters[selectedReciter].name}',
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: reciterGreen,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 15),

                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snapshot) {
                      final position =
                          snapshot.data ?? Duration.zero;

                      final duration =
                          player.duration ?? Duration.zero;

                      final maxValue =
                          duration.inMilliseconds > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0;

                      final currentValue = position
                          .inMilliseconds
                          .toDouble()
                          .clamp(0.0, maxValue)
                          .toDouble();

                      return Column(
                        children: [
                          Slider(
                            activeColor: reciterGreen,
                            inactiveColor:
                                reciterGold.withOpacity(0.3),
                            min: 0,
                            max: maxValue,
                            value: currentValue,
                            onChanged: (value) {
                              player.seek(
                                Duration(
                                  milliseconds: value.round(),
                                ),
                              );
                            },
                          ),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formatDuration(position)),
                              Text(formatDuration(duration)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          player.seekToPrevious();
                        },
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                        ),
                        iconSize: 35,
                        color: reciterGreen,
                      ),

                      const SizedBox(width: 15),

                      StreamBuilder<PlayerState>(
                        stream: player.playerStateStream,
                        builder: (context, snapshot) {
                          final state = snapshot.data;
                          final playing =
                              state?.playing ?? false;

                          final isLoading =
                              state?.processingState ==
                                  ProcessingState.loading ||
                              state?.processingState ==
                                  ProcessingState.buffering;

                          if (isLoading) {
                            return const SizedBox(
                              width: 62,
                              height: 62,
                              child: CircularProgressIndicator(
                                color: reciterGreen,
                              ),
                            );
                          }

                          return Container(
                            decoration: const BoxDecoration(
                              color: reciterForest,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                if (playing) {
                                  player.pause();
                                } else if (state?.processingState ==
                                    ProcessingState.completed) {
                                  player.seek(Duration.zero);
                                  player.play();
                                } else if (player.audioSource == null) {
                                  playSurah();
                                } else {
                                  player.play();
                                }
                              },
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: reciterGold,
                              ),
                              iconSize: 42,
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 15),

                      IconButton(
                        onPressed: () {
                          player.seekToNext();
                        },
                        icon: const Icon(
                          Icons.skip_next_rounded,
                        ),
                        iconSize: 35,
                        color: reciterGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: downloading ? null : playSurah,
                icon: const Icon(
                  Icons.play_circle_fill,
                ),
                label: const Text(
                  'تشغيل السورة كاملة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: reciterForest,
                  foregroundColor: reciterGold,
                  shape: RoundedRectangleBorder(
                    bord
