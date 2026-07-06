import 'package:flutter/material.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';

class ToolsPage extends StatelessWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  // --- ASTRAL ENGINE NEON BLUE THEME ---
  static const Color bgDark = Color(0xFF09101E);
  static const Color cardColor = Color(0xFF0D192D);
  static const Color accentBlue = Color(0xFF38B6FF);
  static const Color lightBlue = Color(0xFF64D2FF);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFF8A99AD);
  static const Color glassPrimary = Color(0x1A38B6FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === ASTRAL ENGINE HEADER ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF162A45),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.shield_rounded,
                            color: primaryWhite,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "MPAXX X SCARRY",
                            style: TextStyle(
                              color: primaryWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              fontFamily: 'Courier',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Gateway Tools",
                            style: TextStyle(
                              color: softGrey,
                              fontSize: 13,
                              letterSpacing: 0.5,
                        ),
                      ),
                        ],
                      ),
                    ],
                  ),
                  // === STATUS USER BUTTON ===
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132239),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userRole.toUpperCase(),
                          style: const TextStyle(
                            color: primaryWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // === SUBTITLE TOOLS ASTRAL ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: accentBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Tools Mpax",
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    "9 item",
                    style: TextStyle(
                      color: softGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // === 3-COLUMN GRID MENU INTERFACE ===
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    buildAstralCard(
                      icon: Icons.cloud_outlined,
                      title: "Manage Server",
                      subtitle: "Server Control",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageServerPage(keyToken: sessionKey),
                          ),
                        );
                      },
                    ),
                    buildAstralCard(
                      icon: Icons.bolt_rounded,
                      title: "DDoS",
                      subtitle: "Take Down",
                      onTap: () => showDDoSTools(context),
                    ),
                    buildAstralCard(
                      icon: Icons.wifi,
                      title: "Network",
                      subtitle: "WiFi Arsenal",
                      onTap: () => showNetworkTools(context),
                    ),
                    buildAstralCard(
                      icon: Icons.search_rounded,
                      title: "OSINT",
                      subtitle: "Deep Search",
                      onTap: () => showOSINTTools(context),
                    ),
                    buildAstralCard(
                      icon: Icons.file_download_outlined,
                      title: "Downloader",
                      subtitle: "Media Saver",
                      onTap: () => showDownloaderTools(context),
                    ),
                    buildAstralCard(
                      icon: Icons.build_outlined,
                      title: "Utilities",
                      subtitle: "Extra Tools",
                      onTap: () => showUtilityTools(context),
                    ),
                    buildAstralCard(
                      icon: Icons.play_circle_outline,
                      title: "Watch Video",
                      subtitle: "Stream & Watch",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TiktokDownloaderPage()),
                        );
                      },
                    ),
                    // PERBAIKAN: Langsung panggil fungsi showComingSoon(context) saat di-tap
                    buildAstralCard(
                      icon: Icons.important_devices_rounded,
                      title: "Rat Control",
                      subtitle: "Remote Access",
                      onTap: () => showComingSoon(context),
                    ),
                    buildAstralCard(
                      icon: Icons.lock_outline_rounded,
                      title: "Adult Hub",
                      subtitle: "18+ Only",
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAstralCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF16253D),
                shape: BoxShape.circle,
                border: Border.all(color: accentBlue.withOpacity(0.15), width: 1.5),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: lightBlue,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: primaryWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: softGrey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM SHEETS & UTILITIES ---
  void showGlassBottomSheet(BuildContext context, String title, IconData icon, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: bgDark,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: accentBlue, size: 24),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: const TextStyle(color: primaryWhite, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(children: children),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showDDoSTools(BuildContext context) {
    showGlassBottomSheet(context, "DDoS Tools", Icons.bolt_rounded, [
      buildListOption(
        icon: Icons.bolt_rounded,
        label: "Attack Panel",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttackPanel(sessionKey: sessionKey, listDoos: listDoos),
            ),
          );
        },
      ),
    ]);
  }

  void showNetworkTools(BuildContext context) {
    List<Widget> options = [
      buildListOption(
        icon: Icons.message_rounded,
        label: "Spam NGL",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NglPage()));
        },
      ),
    ];

    if (userRole == "vip" || userRole == "owner") {
      options.add(
        buildListOption(
          icon: Icons.router_rounded,
          label: "WiFi Killer (External)",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WifiInternalPage(sessionKey: sessionKey)),
            );
          },
        ),
      );
    }
    showGlassBottomSheet(context, "Network Tools", Icons.wifi, options);
  }

  void showOSINTTools(BuildContext context) {
    showGlassBottomSheet(context, "OSINT Tools", Icons.search_rounded, [
      buildListOption(
        icon: Icons.badge_rounded,
        label: "NIK Detail",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NikCheckerPage()));
        },
      ),
      buildListOption(
        icon: Icons.domain_rounded,
        label: "Domain OSINT",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DomainOsintPage()));
        },
      ),
    ]);
  }

  void showDownloaderTools(BuildContext context) {
    showGlassBottomSheet(context, "Media Downloader", Icons.file_download_outlined, [
      buildListOption(
        icon: Icons.video_library_rounded,
        label: "TikTok Downloader",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TiktokDownloaderPage()));
        },
      ),
      buildListOption(
        icon: Icons.camera_alt_rounded,
        label: "Instagram Downloader",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InstagramDownloaderPage()));
        },
      ),
    ]);
  }

  void showUtilityTools(BuildContext context) {
    showGlassBottomSheet(context, "Utility Tools", Icons.build_outlined, [
      buildListOption(
        icon: Icons.qr_code_rounded,
        label: "QR Generator",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const QrGeneratorPage()));
        },
      ),
    ]);
  }

  Widget buildListOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: lightBlue),
        title: Text(label, style: const TextStyle(color: primaryWhite)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: softGrey, size: 14),
        onTap: onTap,
      ),
    );
  }

  void showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur Belum Tersedia!'),
        backgroundColor: cardColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}