import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class NikCheckerPage extends StatefulWidget {
  const NikCheckerPage({super.key});

  @override
  State<NikCheckerPage> createState() => _NikCheckerPageState();
}

class _NikCheckerPageState extends State<NikCheckerPage> with SingleTickerProviderStateMixin {
  final TextEditingController _nikController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  String? _errorMessage;

  // --- TEMA DEEP PURPLE MODERN ---
  final Color bgDark = const Color(0xFF0A0A2A);
  final Color deepPurple = const Color(0xFF6B3FA0);
  final Color lightPurple = const Color(0xFF9B6BFF);
  final Color primaryWhite = Colors.white;
  final Color textGrey = Colors.grey.shade400;
  final Color subtleGlass = Colors.white.withOpacity(0.03);
  final Color borderSubtle = Colors.white.withOpacity(0.08);

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _nikController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkNik() async {
    final nik = _nikController.text.trim();
    if (nik.isEmpty) {
      setState(() {
        _errorMessage = "NIK cannot be empty.";
        _data = null;
      });
      return;
    }

    if (nik.length != 16) {
      setState(() {
        _errorMessage = "NIK must be 16 digits.";
        _data = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _data = null;
    });

    final url = Uri.parse("https://api.siputzx.my.id/api/tools/nik-checker?nik=$nik");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          setState(() {
            _data = json['data'];
            _errorMessage = null;
          });
          _animController.forward(from: 0);
        } else {
          setState(() {
            _errorMessage = "Data not found or invalid NIK.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to fetch data from server.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString().replaceAll('TimeoutException', 'Request timeout')}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: subtleGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: subtleGlass,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: deepPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: lightPurple, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Category Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveInfoRow({
    required String label,
    required String? value,
    IconData? copyIcon = Icons.copy,
    VoidCallback? onCopy,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: subtleGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: Icon(copyIcon, color: lightPurple, size: 16),
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Copy $label',
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied to clipboard',
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          'NIK Checker',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
            color: primaryWhite,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: lightPurple, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgDark,
              deepPurple.withOpacity(0.05),
              bgDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Input Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: subtleGlass,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: primaryWhite, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Enter NIK',
                          labelStyle: TextStyle(color: lightPurple, fontSize: 12),
                          hintText: 'Example: 5206085405880001',
                          hintStyle: TextStyle(color: textGrey.withOpacity(0.5), fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderSubtle),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: lightPurple, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: subtleGlass,
                          prefixIcon: Icon(Icons.numbers, color: lightPurple, size: 18),
                          suffixIcon: _isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: lightPurple,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _checkNik(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [deepPurple, lightPurple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _checkNik,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isLoading ? Icons.hourglass_top : Icons.search, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _isLoading ? 'PROCESSING...' : 'CHECK NIK',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
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

                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: textGrey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Results Section
                if (_data != null)
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Personal Identity
                            _buildCategoryCard(
                              title: "PERSONAL IDENTITY",
                              icon: Icons.person,
                              children: [
                                _buildInteractiveInfoRow(
                                  label: "NIK",
                                  value: _data!["nik"]?.toString(),
                                  onCopy: () => _copyToClipboard(_data!["nik"]?.toString() ?? "", "NIK"),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "Full Name",
                                  value: _data!["data"]["nama"]?.toString(),
                                  onCopy: () => _copyToClipboard(_data!["data"]["nama"]?.toString() ?? "", "Name"),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "Gender",
                                  value: _data!["data"]["kelamin"]?.toString(),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "Birth Place",
                                  value: _data!["data"]["tempat_lahir"]?.toString(),
                                  onCopy: () => _copyToClipboard(_data!["data"]["tempat_lahir"]?.toString() ?? "", "Birth Place"),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "Age",
                                  value: _data!["data"]["usia"]?.toString(),
                                ),
                              ],
                            ),

                            // Domicile Data
                            _buildCategoryCard(
                              title: "DOMICILE DATA",
                              icon: Icons.location_on,
                              children: [
                                _buildInteractiveInfoRow(
                                  label: "Province",
                                  value: _data!["data"]["provinsi"]?.toString(),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "City/Regency",
                                  value: _data!["data"]["kabupaten"]?.toString(),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "District",
                                  value: _data!["data"]["kecamatan"]?.toString(),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "Village",
                                  value: _data!["data"]["kelurahan"]?.toString(),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "Full Address",
                                  value: _data!["data"]["alamat"]?.toString(),
                                  onCopy: () => _copyToClipboard(_data!["data"]["alamat"]?.toString() ?? "", "Address"),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "Polling Station",
                                  value: _data!["data"]["tps"]?.toString(),
                                ),
                              ],
                            ),

                            // Additional Information
                            _buildCategoryCard(
                              title: "ADDITIONAL INFO",
                              icon: Icons.info,
                              children: [
                                _buildInteractiveInfoRow(
                                  label: "Zodiac",
                                  value: _data!["data"]["zodiak"]?.toString(),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "Next Birthday",
                                  value: _data!["data"]["ultah_mendatang"]?.toString(),
                                ),
                                _buildInteractiveInfoRow(
                                  label: "Pasaran",
                                  value: _data!["data"]["pasaran"]?.toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}