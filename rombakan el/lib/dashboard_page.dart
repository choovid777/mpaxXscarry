import 'dart:convert';
import 'dart:io';
import 'dart:async'; // <--- Ditambahkan untuk real-time countdown timer
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'anime.dart';
import 'thanks_to.dart';
import 'spotify_music.dart';
import 'room_public.dart';
import 'hadis_page.dart'; 

// Constants for colors - MODERN THEME
const Color accentRedGlobal = Color(0xFF00BFFF);
const Color darkRedGlobal = Color(0xFF0B1120);
const Color softRedGlobal = Color(0xFF7FFFD4);
const Color primaryWhiteGlobal = Color(0xFFFFFFFF);

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  WebSocketChannel? channel;
  
  // --- Video Background Controller ---
  late VideoPlayerController _videoController;

  // --- State Variables ---
  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  // --- Profile & Menu Features ---
  String androidId = "unknown";
  File? profileImage;

  int bottomNavIndex = 0;
  Widget selectedPage = const SizedBox();

  int onlineUsers = 0;
  int activeConnections = 0;

  // --- Banner Carousel State ---
  final PageController _bannerPageController = PageController(viewportFraction: 0.9);
  int _currentBannerIndex = 0;

  final List<Map<String, String>> _bannerItems = [
    {"img": "assets/images/gojo.jpg", "title": "Mpax X scary Project", "sub": "hi, haters!"},
  ];

  // --- Quick Menu State Variables ---
  final PageController _quickMenuController = PageController();
  int _currentQuickMenuIndex = 0;
  final String _font = 'Sans-Serif';
  final Color _cBlue = const Color(0xFF00BFFF);

  // --- State Variables Untuk Jadwal Sholat ---
  String selectedCity = "JAKARTA";
  Timer? _countdownTimer;
  String _nextSholatName = "ASHAR";
  String _countdownString = "00:00:00";
  String _currentDigitalTime = "00:00:00"; // <--- Menyimpan waktu jam dinding digital

  // Daftar Kota Indonesia Diperluas Sesuai Permintaan
  final List<String> indonesiaCities = [
    "JAKARTA", "BANDUNG", "MEDAN", "MAKASSAR", "DENPASAR", 
    "PALEMBANG", "MATARAM", "AMBON", "PADANG", "PEKANBARU", 
    "KENDARI", "SURABAYA", "KUPANG", "SORONG"
  ];

  // Database Simulasi Waktu Sholat untuk Setiap Kota Baru
  final Map<String, Map<String, String>> prayerTimesDatabase = {
    "JAKARTA": {"SUBUH": "04:32", "DZUHUR": "11:45", "ASHAR": "15:05", "MAGHRIB": "17:55", "ISYA": "19:08"},
    "SURABAYA": {"SUBUH": "04:12", "DZUHUR": "11:28", "ASHAR": "14:48", "MAGHRIB": "17:36", "ISYA": "18:50"},
    "BANDUNG": {"SUBUH": "04:34", "DZUHUR": "11:48", "ASHAR": "15:08", "MAGHRIB": "17:56", "ISYA": "19:10"},
    "MEDAN": {"SUBUH": "04:52", "DZUHUR": "12:18", "ASHAR": "15:42", "MAGHRIB": "18:27", "ISYA": "19:41"},
    "MAKASSAR": {"SUBUH": "04:41", "DZUHUR": "11:59", "ASHAR": "15:21", "MAGHRIB": "17:58", "ISYA": "19:12"},
    "DENPASAR": {"SUBUH": "04:55", "DZUHUR": "12:15", "ASHAR": "15:35", "MAGHRIB": "18:15", "ISYA": "19:28"},
    "PALEMBANG": {"SUBUH": "04:38", "DZUHUR": "12:05", "ASHAR": "15:28", "MAGHRIB": "18:12", "ISYA": "19:25"},
    "MATARAM": {"SUBUH": "04:52", "DZUHUR": "12:12", "ASHAR": "15:32", "MAGHRIB": "18:12", "ISYA": "19:25"},
    "AMBON": {"SUBUH": "04:50", "DZUHUR": "12:15", "ASHAR": "15:40", "MAGHRIB": "18:25", "ISYA": "19:35"},
    "PADANG": {"SUBUH": "04:58", "DZUHUR": "12:22", "ASHAR": "15:48", "MAGHRIB": "18:28", "ISYA": "19:40"},
    "PEKANBARU": {"SUBUH": "04:48", "DZUHUR": "12:15", "ASHAR": "15:42", "MAGHRIB": "18:18", "ISYA": "19:30"},
    "KENDARI": {"SUBUH": "04:38", "DZUHUR": "12:05", "ASHAR": "15:25", "MAGHRIB": "18:05", "ISYA": "19:18"},
    "KUPANG": {"SUBUH": "04:35", "DZUHUR": "11:58", "ASHAR": "15:22", "MAGHRIB": "17:58", "ISYA": "19:10"},
    "SORONG": {"SUBUH": "04:45", "DZUHUR": "12:12", "ASHAR": "15:38", "MAGHRIB": "18:18", "ISYA": "19:30"},
  };

  // --- MODERN THEME dengan Glassmorphism ---
  static const Color bgDark = Color(0xFF0A0E27);
  static const Color accentRed = Color(0xFF00BFFF);
  static const Color darkRed = Color(0xFF1E3A5F);
  static const Color softRed = Color(0xFF7FFFD4);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFF94A3B8);
  
  // Glassmorphism colors
  Color get glassPrimary => Colors.white.withOpacity(0.08);
  Color get glassSecondary => Colors.white.withOpacity(0.04);
  Color get glassBorder => Colors.white.withOpacity(0.12);
  Color get glassHover => Colors.white.withOpacity(0.12);

  LinearGradient get redGradient => const LinearGradient(
    colors: [Color(0xFF00BFFF), Color(0xFF1E3A5F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get secondaryGradient => const LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF7FFFD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();

    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    initAnimations();
    initVideoBackground();
    selectedPage = buildHomePage();

    initAndroidIdAndConnect();
    loadProfileImage();
    startPrayerCountdown(); // Jalankan real-time countdown tracker
  }

  void initAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  void initVideoBackground() {
    _videoController = VideoPlayerController.asset('assets/videos/background.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.setLooping(true);
          _videoController.setVolume(5.0);
          _videoController.play();
        }
      }).catchError((error) {
        debugPrint("Background video error: $error");
        if (mounted) {
          setState(() {});
        }
      });
  }

  // Engine Perhitungan Mundur Waktu Ibadah & Jam Dinding Digital Real-Time
  void startPrayerCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final now = DateTime.now();

      // Logika Pembaruan Jam Dinding Digital Real-time
      final String clockHours = now.hour.toString().padLeft(2, '0');
      final String clockMinutes = now.minute.toString().padLeft(2, '0');
      final String clockSeconds = now.second.toString().padLeft(2, '0');
      final String currentClockString = "$clockHours:$clockMinutes:$clockSeconds";

      // Logika Pemrosesan Jadwal Ibadah Sholat
      final currentCityTimes = prayerTimesDatabase[selectedCity]!;
      
      DateTime? targetTime;
      String nextSholat = "SUBUH";

      List<String> order = ["SUBUH", "DZUHUR", "ASHAR", "MAGHRIB", "ISYA"];
      
      for (String sholat in order) {
        final timeParts = currentCityTimes[sholat]!.split(":");
        final sholatDateTime = DateTime(
          now.year, now.month, now.day,
          int.parse(timeParts[0]), int.parse(timeParts[1]),
        );

        if (sholatDateTime.isAfter(now)) {
          targetTime = sholatDateTime;
          nextSholat = sholat;
          break;
        }
      }

      // Jika melewati waktu Isya, maka target berikutnya adalah Subuh besok hari
      if (targetTime == null) {
        final timeParts = currentCityTimes["SUBUH"]!.split(":");
        targetTime = DateTime(
          now.year, now.month, now.day + 1,
          int.parse(timeParts[0]), int.parse(timeParts[1]),
        );
        nextSholat = "SUBUH";
      }

      final difference = targetTime.difference(now);
      
      final hours = difference.inHours.toString().padLeft(2, '0');
      final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

      setState(() {
        _nextSholatName = nextSholat;
        _countdownString = "$hours:$minutes:$seconds";
        _currentDigitalTime = currentClockString; // Update data waktu jam dinding asli
      });
    });
  }

  // Fungsi untuk mendeteksi icon visual berdasarkan nama ibadah sholat
  IconData getPrayerIcon(String name) {
    switch (name) {
      case "SUBUH": return Icons.brightness_3_rounded;
      case "DZUHUR": return Icons.wb_sunny_rounded;
      case "ASHAR": return Icons.cloud_rounded;
      case "MAGHRIB": return Icons.dark_mode_rounded;
      default: return Icons.nightlight_round;
    }
  }

  // Memeriksa status interval waktu aktif saat ini untuk diberikan highlight border gold
  bool isCurrentActivePrayer(String sholatName) {
    final now = DateTime.now();
    final times = prayerTimesDatabase[selectedCity]!;
    
    int getMinutes(String timeStr) {
      final parts = timeStr.split(":");
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final currentMinutes = now.hour * 60 + now.minute;
    final subuh = getMinutes(times["SUBUH"]!);
    final dzuhur = getMinutes(times["DZUHUR"]!);
    final ashar = getMinutes(times["ASHAR"]!);
    final maghrib = getMinutes(times["MAGHRIB"]!);
    final isya = getMinutes(times["ISYA"]!);

    if (sholatName == "SUBUH" && currentMinutes >= subuh && currentMinutes < dzuhur) return true;
    if (sholatName == "DZUHUR" && currentMinutes >= dzuhur && currentMinutes < ashar) return true;
    if (sholatName == "ASHAR" && currentMinutes >= ashar && currentMinutes < maghrib) return true;
    if (sholatName == "MAGHRIB" && currentMinutes >= maghrib && currentMinutes < isya) return true;
    if (sholatName == "ISYA" && (currentMinutes >= isya || currentMinutes < subuh)) return true;

    return false;
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (!mounted) return;
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        profileImage = File(imagePath);
      });
    }
  }

  Future<void> initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    connectToWebSocket();
  }

  void connectToWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://ws-queen.official.com'),
    );
    channel?.sink.add(
      jsonEncode({
        "type": "validate",
        "key": sessionKey,
        "androidId": androidId,
      }),
    );
    channel?.sink.add(jsonEncode({"type": "stats"}));

    channel?.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          if (data['reason'] == 'androidIdMismatch') {
            handleInvalidSession("Your account has logged on another device.");
          } else if (data['reason'] == 'keyInvalid') {
            handleInvalidSession("Key is not valid. Please login again.");
          }
        }
      }
      if (data['type'] == 'stats') {
        if (!mounted) return;
        setState(() {
          onlineUsers = data['onlineUsers'] ?? 0;
          activeConnections = data['activeConnections'] ?? 0;
        });
      }
    });
  }

  Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  void handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: glassPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: glassBorder, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Session Expired",
              style: TextStyle(
                color: accentRed,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: softGrey, fontSize: 14),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: redGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                "OK",
                style: TextStyle(
                  color: primaryWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onBottomNavTapped(int index) {
    setState(() {
      bottomNavIndex = index;
      if (index == 0) {
        selectedPage = buildHomePage();
      } else if (index == 1) {
        selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        selectedPage = InfoPage(sessionKey: sessionKey);
      } else if (index == 3) {
        selectedPage = ToolsPage(
          sessionKey: sessionKey,
          userRole: role,
          listDoos: listDoos,
        );
      }
    });
  }

  void onSidebarTabSelected(int index) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        if (index == 1) {
          selectedPage = SellerPage(keyToken: sessionKey);
        } else if (index == 2) {
          selectedPage = AdminPage(sessionKey: sessionKey);
        } else if (index == 3) {
          selectedPage = OwnerPage(sessionKey: sessionKey, username: username);
        }
      });
    });
  }

  List<Map<String, dynamic>> get quickActions {
    return [
      {
        "icon": Icons.bug_report_rounded,
        "label": "Manage Bug",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BugSenderPage(
                sessionKey: sessionKey,
                username: username,
                role: role,
              ),
            ),
          );
        },
      },
      {
        "icon": FontAwesomeIcons.telegram,
        "label": "Join Channel",
        "onTap": () => openUrl("https://t.me/TeamPaii"),
      },
      {
        "icon": Icons.chat_rounded,
        "label": "Room Public",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RoomPublicPage()),
          );
        },
      },
      {
        "icon": Icons.access_time_filled_rounded,
        "label": "Jadwal Sholat",
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Menampilkan panel informasi ibadah di Dashboard!")),
          );
        },
      },
      {
        "icon": Icons.menu_book_rounded,
        "label": "Hadis Shahih",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HadisPage()),
          );
        },
      },
      {
        "icon": Icons.movie_rounded,
        "label": "Anime List",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeAnimePage()),
          );
        },
      },
      {
        "icon": Icons.favorite_rounded,
        "label": "Thanks To",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ThanksToPage()),
          );
        },
      },
      {
        "icon": Icons.music_note_rounded,
        "label": "Spotify",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpotifyMusicPage(),
            ),
          );
        },
      },
    ];
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fitur ini akan segera hadir!")),
    );
  }

  Widget _bubble(double radius, Color color) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // --- WIDGET KOMPONEN JADWAL SHOLAT & JAM DIGITAL TRANSPARAN ---
  Widget _buildJadwalSholatWidget() {
    final currentTimes = prayerTimesDatabase[selectedCity]!;
    final List<String> prayers = ["SUBUH", "DZUHUR", "ASHAR", "MAGHRIB", "ISYA"];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D122B).withOpacity(0.65), // Ditingkatkan kadar transparansinya
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Widget Tampilan Jam Digital Transparan (Seperti Jam Dinding Asli Berjalan)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              _currentDigitalTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace', // Style khas jam digital listrik/dinding
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Row Bagian Atas Header Judul & Countdown Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mosque_rounded, color: Color(0xFF00BFFF), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    "JADWAL SHOLAT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: _font,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF7FFFD4), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "MUNDUR : ",
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _countdownString,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Baris Kotak-Kotak Jam Sholat (Bisa digeser horizontal)
          SizedBox(
            height: 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: prayers.length,
              itemBuilder: (context, index) {
                final name = prayers[index];
                final time = currentTimes[name]!;
                final bool isActive = isCurrentActivePrayer(name);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 82,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF25211D).withOpacity(0.9) : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.05),
                      width: isActive ? 1.8 : 1.0,
                    ),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        getPrayerIcon(name),
                        color: isActive ? const Color(0xFFFFD700) : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: isActive ? const Color(0xFFFFD700) : const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Komponen Dropdown Pemilihan Wilayah Lokasi Area Indonesia (Termasuk Kota Baru)
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCity,
                dropdownColor: const Color(0xFF0A0E27),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 18),
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                items: indonesiaCities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF00BFFF), size: 15),
                        const SizedBox(width: 8),
                        Text(city, style: TextStyle(fontFamily: _font, letterSpacing: 0.5)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedCity = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenuSlider() {
    final menus = [
      {
        "icon": Icons.movie_rounded,
        "title": "Menu Streaming",
        "color": const Color(0xFFF9A825),
        "items": ["Film Terbaru", "Drama Series", "Anime"],
      },
      {
        "icon": Icons.download_rounded,
        "title": "Downloader Menu",
        "color": const Color(0xFF1565C0),
        "items": ["Video Download", "Audio Download", "Image Batch"],
      },
      {
        "icon": Icons.menu_book_rounded,
        "title": "Hadits Menu",
        "color": const Color(0xFF00E676),
        "items": ["Al-Quran Digital", "Hadits Shahih", "Doa Harian"],
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _quickMenuController,
            itemCount: menus.length,
            onPageChanged: (i) => setState(() => _currentQuickMenuIndex = i),
            itemBuilder: (context, index) {
              final m = menus[index];
              final Color themeColor = m["color"] as Color;
              final items = m["items"] as List<String>;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: glassPrimary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: themeColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(bottom: -10, right: -10, child: _bubble(30, themeColor.withOpacity(0.05))),
                      Positioned(top: 20, right: 30, child: _bubble(15, themeColor.withOpacity(0.03))),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: themeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
                                  ),
                                  child: Icon(m["icon"] as IconData, color: themeColor, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  m["title"] as String,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: _font,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withOpacity(0.05), thickness: 1),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: items.map((item) {
                                final bool isHadis = item == "Hadits Shahih";
                                
                                return InkWell(
                                  onTap: isHadis 
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const HadisPage()),
                                          );
                                        }
                                      : _showComingSoon,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isHadis ? themeColor.withOpacity(0.2) : Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isHadis ? themeColor.withOpacity(0.4) : Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isHadis ? Icons.menu_book_rounded : Icons.lock_outline_rounded, 
                                          color: themeColor.withOpacity(0.8), 
                                          size: 12,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11,
                                            fontFamily: _font,
                                            fontWeight: isHadis ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(menus.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentQuickMenuIndex == i ? 20 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _currentQuickMenuIndex == i ? _cBlue : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildConnectMantaTeamCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: glassPrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: glassBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShape.circle == false ? BoxShadow(
            color: const Color(0xFF00BFFF).withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 1,
          ) : const BoxShadow(),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(
                Icons.hub_outlined, 
                color: Color(0xFFFF2A6D),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                "CONNECT WITH MPAXX TEAM",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: _font,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialCircleItem(
                icon: FontAwesomeIcons.telegram,
                label: "Telegram",
                iconColor: const Color(0xFF2EA6DA),
                onTap: () => openUrl("https://t.me/elnichol_md"),
              ),
              _buildSocialCircleItem(
                icon: FontAwesomeIcons.youtube,
                label: "YouTube",
                iconColor: const Color(0xFFFF0000),
                onTap: () => openUrl("https://youtube.com/elnichol_md"),
              ),
              _buildSocialCircleItem(
                icon: FontAwesomeIcons.tiktok,
                label: "TikTok",
                iconColor: Colors.white,
                onTap: () => openUrl("https://tiktok.com/@elnicholmd"),
              ),
              _buildSocialCircleItem(
                icon: Icons.favorite_rounded,
                label: "Thanks To",
                iconColor: const Color(0xFFFF2A6D),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ThanksToPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.05), thickness: 1),
          const SizedBox(height: 8),
          Text(
            "Selalu nantikan project terbaru dari Team Mpax X scary",
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11.5,
              fontFamily: _font,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCircleItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glassSecondary,
              border: Border.all(
                color: iconColor.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontFamily: _font,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Profile Card with Glass Effect
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20), 
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: glassPrimary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: glassBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFFF).withOpacity(0.08),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -25,
                        bottom: -25,
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 140,
                        child: CustomPaint(painter: HoneycombPainter()),
                      ),
                      Positioned(
                        right: -20,
                        top: -20,
                        width: MediaQuery.of(context).size.width * 0.45,
                        height: 140,
                        child: CustomPaint(painter: HoneycombPainter()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00BFFF).withOpacity(0.08),
                                    border: Border.all(
                                      color: const Color(0xFF00BFFF).withOpacity(0.3),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    color: Color(0xFF00BFFF),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "hi haters, I'm back",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 21,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF2979FF),
                                            size: 17,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D47A1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          role.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Expired: $expiredDate",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.35),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                                decoration: BoxDecoration(
                                  color: glassSecondary,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: glassBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.hexagon_outlined, color: Colors.white.withOpacity(0.6), size: 13),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Mpax X scary, Alergi Meninggi",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.hexagon_outlined, color: Colors.white.withOpacity(0.6), size: 13),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Divider(color: glassBorder, thickness: 0.8),
                            const SizedBox(height: 8),
                            Center(
                              child: GestureDetector(
                                onTap: () => openUrl("https://t.me/TeamPaii"),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12.5, fontFamily: 'Sans-Serif'),
                                    children: [
                                      TextSpan(
                                        text: "Up Role? Chat Owner Kami ",
                                        style: TextStyle(color: Colors.white.withOpacity(0.55)),
                                      ),
                                      const TextSpan(
                                        text: "@Mpax_cruel",
                                        style: TextStyle(
                                          color: Color(0xFF00BFFF),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Banner Slider
          Column(
            children: [
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _bannerPageController,
                  itemCount: _bannerItems.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentBannerIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _bannerItems[index];
                    return AnimatedBuilder(
                      animation: _bannerPageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_bannerPageController.position.haveDimensions) {
                          value = _bannerPageController.page! - index;
                          value = (1 - (value.abs() * 0.05)).clamp(0.0, 1.0);
                        }
                        return Center(
                          child: SizedBox(
                            height: Curves.easeOut.transform(value) * 200,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            children: [
                              Image.asset(
                                item['img']!, 
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [darkRed, accentRed.withOpacity(0.5)],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      color: primaryWhite,
                                      size: 50,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 20,
                                bottom: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title']!,
                                      style: const TextStyle(
                                        color: primaryWhite,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 4,
                                            color: Colors.black45,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['sub']!, 
                                      style: const TextStyle(
                                        color: softGrey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 3,
                                            color: Colors.black45,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_bannerItems.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentBannerIndex == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentBannerIndex == index
                          ? accentRed
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),

              // Online Status Card with Glass Effect
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: glassPrimary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: glassBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BFFF).withOpacity(0.08),
                        blurRadius: 15,
                        spreadRadius: 1,
                    ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: const Color(0xFF00BFFF),
                            size: 10,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00BFFF).withOpacity(0.8),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Online : $onlineUsers",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 16,
                        width: 1,
                        color: glassBorder,
                      ),
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF00BFFF), Color(0xFF7FFFD4)],
                            ).createShader(bounds),
                            child: const Text(
                              "Connected",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.bolt_rounded,
                            color: const Color(0xFF7FFFD4),
                            size: 16,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF7FFFD4).withOpacity(0.8),
                                blurRadius: 6,
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // QUICK ACTIONS Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: redGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "QUICK ACTIONS",
                  style: TextStyle(
                    color: softGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.touch_app_rounded,
                  color: accentRed,
                  size: 18,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Horizontal Scroll Quick Actions
          SizedBox(
            height: 105, 
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: () {
                  final List<Color> customColors = [
                    Colors.blue, Colors.red, Colors.green, Colors.indigo, Colors.teal, Colors.orange, Colors.purple, Colors.cyan,
                  ];

                  List<Widget> items = [];
                  for (int i = 0; i < quickActions.length; i++) {
                    final action = quickActions[i];
                    final Color assignedColor = customColors[i % customColors.length];

                    items.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: buildModernQuickAction(
                          icon: action['icon'] as IconData,
                          label: action['label'] as String,
                          color: assignedColor, 
                          onTap: action['onTap'] as VoidCallback,
                        ),
                      ),
                    );
                  }
                  return items;
                }(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- MEMASANG WIDGET JADWAL SHOLAT INTERAKTIF DI HOMEPAGE ---
          _buildJadwalSholatWidget(),

          const SizedBox(height: 20),

          // QUICK MENU Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: redGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "QUICK MENU",
                  style: TextStyle(
                    color: softGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildQuickMenuSlider(),

          const SizedBox(height: 32),

          _buildConnectMantaTeamCard(),

          const SizedBox(height: 20),
          
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22.0),
              decoration: BoxDecoration(
                color: glassPrimary,
                borderRadius: BorderRadius.circular(26.0),
                border: Border.all(
                  color: glassBorder,
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'MPAXX TEAMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'by @elnichol_md',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8).withOpacity(0.55),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget buildModernQuickAction({
    required IconData icon,
    required String label,
    required Color color, 
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 125, 
        height: 85,  
        decoration: BoxDecoration(
          color: glassPrimary,
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(
            color: color.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color, 
              size: 26,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCustomDrawer() {
    return Drawer(
      backgroundColor: bgDark.withOpacity(0.95),
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(gradient: redGradient),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryWhite, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: accentRed.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profileImage != null
                            ? Image.file(profileImage!, fit: BoxFit.cover)
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: secondaryGradient,
                                ),
                                child: Icon(
                                  FontAwesomeIcons.userAstronaut,
                                  size: 45,
                                  color: primaryWhite.withOpacity(0.9),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      username,
                      style: const TextStyle(
                        color: primaryWhiteGlobal,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryWhite.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: primaryWhiteGlobal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: bgDark.withOpacity(0.95),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  if (role == "reseller")
                    buildGlassMenuItem(
                      icon: Icons.storefront_rounded,
                      label: "Seller Page",
                      onTap: () => onSidebarTabSelected(1),
                    ),
                  if (role == "admin")
                    buildGlassMenuItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: "Admin Page",
                      onTap: () => onSidebarTabSelected(2),
                    ),
                  if (role == "owner")
                    buildGlassMenuItem(
                      icon: Icons.workspace_premium_rounded,
                      label: "Owner Page",
                      onTap: () => onSidebarTabSelected(3),
                    ),
                  buildGlassMenuItem(
                    icon: Icons.history_rounded,
                    label: "Riwayat Aktivitas",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RiwayatPage(sessionKey: sessionKey, role: role),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    color: Colors.white10,
                    height: 32,
                    thickness: 0.5,
                  ),
                  buildGlassMenuItem(
                    icon: Icons.logout_rounded,
                    label: "Log Out",
                    isLogout: true,
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGlassMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isLogout ? Colors.red.withOpacity(0.1) : glassSecondary,
        borderRadius: BorderRadius.circular(16),
        border: isLogout
            ? null
            : Border.all(color: glassBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout
                ? Colors.red.withOpacity(0.15)
                : accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.redAccent : accentRed,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout ? Colors.redAccent : primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        trailing: isLogout
            ? null
            : const Icon(Icons.chevron_right_rounded, color: softGrey, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCustomBottomNavigationBar() {
    final List<IconData> navIcons = [
      Icons.home_rounded,
      FontAwesomeIcons.whatsapp,
      Icons.people_alt_rounded,
      Icons.build_rounded,
    ];

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      height: 65,
      decoration: BoxDecoration(
        color: glassPrimary,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navIcons.length, (index) {
          final bool isSelected = bottomNavIndex == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onBottomNavTapped(index),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 65,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFFF).withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7FFFD4).withOpacity(0.12),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            navIcons[index],
                            size: isSelected ? 24 : 21,
                            color: isSelected 
                                ? const Color(0xFF00BFFF) 
                                : const Color(0xFF7FFFD4).withOpacity(0.45),
                          ),
                          if (index == 0)
                            Positioned(
                              top: -2,
                              right: -4,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00BFFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isSelected) const SizedBox(height: 5),
                      if (isSelected)
                        Container(
                          width: 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7FFFD4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: redGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: accentRed.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            "Mpax X scary",
            style: TextStyle(
              color: primaryWhiteGlobal,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryWhiteGlobal),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: glassBorder),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.headset_mic_rounded,
                color: accentRed,
                size: 20,
              ),
              tooltip: 'Customer Service',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactPage()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: glassBorder),
            ),
            child: IconButton(
              icon: const Icon(
                FontAwesomeIcons.circleUser,
                color: accentRed,
                size: 20,
              ),
              tooltip: 'My Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      username: username,
                      password: password,
                      role: role,
                      expiredDate: expiredDate,
                      sessionKey: sessionKey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: buildCustomDrawer(),
      
      body: Stack(
        children: [
          // Background Video Full Screen
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: bgDark),

          // Overlay gelap untuk membuat teks lebih terbaca
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // Gradient Overlay untuk transisi yang halus
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),

          // Main Content dengan Animasi
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: selectedPage,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // <--- Batalkan timer saat halaman dihancurkan
    channel?.sink.close(status.goingAway);
    animationController.dispose();
    _videoController.dispose();
    _bannerPageController.dispose();
    _quickMenuController.dispose(); 
    super.dispose();
  }
}

class HoneycombPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BFFF).withOpacity(0.14)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double radius = 12.0; 
    final double hexWidth = radius * math.sqrt(3);
    final double hexHeight = radius * 2;

    for (double y = -radius; y < size.height + radius; y += hexHeight * 0.75) {
      final bool isEven = ((y + radius) / (hexHeight * 0.75)).round() % 2 == 0;
      final double startX = isEven ? 0 : hexWidth / 2;

      for (double x = startX - hexWidth; x < size.width + hexWidth; x += hexWidth) {
        _drawHexagon(canvas, Offset(x, y), radius, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final Path path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (i * 60) * math.pi / 180;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}