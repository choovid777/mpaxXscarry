import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class DomainOsintPage extends StatefulWidget {
  const DomainOsintPage({super.key});

  @override
  State<DomainOsintPage> createState() => _DomainOsintPageState();
}

class _DomainOsintPageState extends State<DomainOsintPage> {
  final TextEditingController _domainController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _dnsData;
  List<dynamic>? _subdomainsData;
  String? _errorMessage;

  // --- TEMA DEEP PURPLE MODERN ---
  final Color bgDark = const Color(0xFF0A0A2A);
  final Color deepPurple = const Color(0xFF6B3FA0);
  final Color lightPurple = const Color(0xFF9B6BFF);
  final Color primaryWhite = Colors.white;
  final Color subtleGlass = Colors.white.withOpacity(0.03);
  final Color borderSubtle = Colors.white.withOpacity(0.08);

  Future<void> _checkDomain() async {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) {
      setState(() {
        _errorMessage = "Domain tidak boleh kosong.";
        _dnsData = null;
        _subdomainsData = null;
      });
      return;
    }

    // Validate domain format
    final domainRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$');
    if (!domainRegex.hasMatch(domain)) {
      setState(() {
        _errorMessage = "Format domain tidak valid. Contoh: example.com";
        _dnsData = null;
        _subdomainsData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dnsData = null;
      _subdomainsData = null;
    });

    try {
      // Call both APIs simultaneously with timeout
      final results = await Future.wait([
        _fetchDnsInfo(domain).timeout(const Duration(seconds: 30)),
        _fetchSubdomains(domain).timeout(const Duration(seconds: 30)),
      ]);

      final dnsResult = results[0] as Map<String, dynamic>?;
      final subdoResult = results[1] as List<dynamic>?;

      if (dnsResult != null) {
        setState(() {
          _dnsData = dnsResult;
          _subdomainsData = subdoResult;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data domain. Silakan coba lagi.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "server sedang offline": ${e.toString().replaceAll('TimeoutException', 'Request timeout')}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchDnsInfo(String domain) async {
    try {
      final url = Uri.parse("https://api.siputzx.my.id/api/tools/dns?domain=$domain");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          return json['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint("DNS fetch error: $e");
      return null;
    }
  }

  Future<List<dynamic>?> _fetchSubdomains(String domain) async {
    try {
      final url = Uri.parse("http://188.166.180.7:3000/api/tools/subdomains?domain=$domain");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          return json['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint("Subdomains fetch error: $e");
      return null;
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin ke clipboard'),
        backgroundColor: deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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

  Widget _buildInfoRow({
    required String label,
    required String? value,
    bool showCopyButton = false,
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
                    color: primaryWhite.withOpacity(0.6),
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
          if (showCopyButton)
            IconButton(
              icon: Icon(Icons.copy, color: lightPurple, size: 16),
              onPressed: () => _copyToClipboard(value, label),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
              tooltip: 'Salin $label',
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDnsRecords() {
    if (_dnsData == null || _dnsData!['records'] == null) return [];

    final records = _dnsData!['records'] as Map<String, dynamic>;
    final widgets = <Widget>[];

    // NS Records
    if (records['ns']?['response']?['answer'] != null) {
      final nsRecords = records['ns']!['response']!['answer'] as List;
      if (nsRecords.isNotEmpty) {
        widgets.addAll([
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Name Servers',
              style: TextStyle(
                color: lightPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...nsRecords.map((record) => _buildInfoRow(
            label: 'NS Record',
            value: record['record']?['target']?.toString(),
            showCopyButton: true,
          )),
          const SizedBox(height: 12),
        ]);
      }
    }

    // SOA Record
    if (records['soa']?['response']?['answer'] != null) {
      final soaRecords = records['soa']!['response']!['answer'] as List;
      if (soaRecords.isNotEmpty) {
        final soa = soaRecords.first['record'];
        widgets.addAll([
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'SOA Record',
              style: TextStyle(
                color: lightPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildInfoRow(
            label: 'Primary NS',
            value: soa?['host']?.toString(),
            showCopyButton: true,
          ),
          _buildInfoRow(
            label: 'Admin Email',
            value: soa?['admin']?.toString(),
            showCopyButton: true,
          ),
          _buildInfoRow(
            label: 'Serial',
            value: soa?['serial']?.toString(),
          ),
          _buildInfoRow(
            label: 'Refresh',
            value: soa?['refresh']?.toString(),
          ),
          _buildInfoRow(
            label: 'Retry',
            value: soa?['retry']?.toString(),
          ),
          _buildInfoRow(
            label: 'Expire',
            value: soa?['expire']?.toString(),
          ),
          _buildInfoRow(
            label: 'Minimum TTL',
            value: soa?['minimum']?.toString(),
          ),
          const SizedBox(height: 12),
        ]);
      }
    }

    // A Records
    if (records['a']?['response']?['answer'] != null) {
      final aRecords = records['a']!['response']!['answer'] as List;
      if (aRecords.isNotEmpty) {
        widgets.addAll([
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'A Records',
              style: TextStyle(
                color: lightPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...aRecords.map((record) => _buildInfoRow(
            label: 'A Record',
            value: record['record']?['data']?.toString(),
            showCopyButton: true,
          )),
        ]);
      }
    }

    // AAAA Records (IPv6)
    if (records['aaaa']?['response']?['answer'] != null) {
      final aaaaRecords = records['aaaa']!['response']!['answer'] as List;
      if (aaaaRecords.isNotEmpty) {
        widgets.addAll([
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'AAAA Records (IPv6)',
              style: TextStyle(
                color: lightPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...aaaaRecords.map((record) => _buildInfoRow(
            label: 'AAAA Record',
            value: record['record']?['data']?.toString(),
            showCopyButton: true,
          )),
        ]);
      }
    }

    // MX Records
    if (records['mx']?['response']?['answer'] != null) {
      final mxRecords = records['mx']!['response']!['answer'] as List;
      if (mxRecords.isNotEmpty) {
        widgets.addAll([
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'MX Records',
              style: TextStyle(
                color: lightPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...mxRecords.map((record) => _buildInfoRow(
            label: 'MX Record',
            value: record['record']?['exchange']?.toString(),
            showCopyButton: true,
          )),
        ]);
      }
    }

    return widgets;
  }

  List<Widget> _buildSubdomainsList() {
    if (_subdomainsData == null) return [];

    // Clean and filter subdomains
    final cleanSubdomains = _subdomainsData!
        .expand((item) {
          final str = item.toString();
          return str.split('\n').where((s) => s.trim().isNotEmpty);
        })
        .map((subdomain) => subdomain.trim())
        .where((subdomain) => 
            subdomain.isNotEmpty && 
            !subdomain.startsWith('*') &&
            !subdomain.contains('error') &&
            subdomain.contains('.'))
        .toSet()
        .toList()
      ..sort();

    if (cleanSubdomains.isEmpty) {
      return [
        Center(
          child: Text(
            'Tidak ditemukan subdomain',
            style: TextStyle(
              color: primaryWhite.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ),
      ];
    }

    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Subdomain',
              style: TextStyle(
                color: primaryWhite.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: lightPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${cleanSubdomains.length}',
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      ...cleanSubdomains.map((subdomain) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: subtleGlass,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.link, color: lightPurple, size: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subdomain,
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy, color: lightPurple, size: 14),
              onPressed: () => _copyToClipboard(subdomain, 'Subdomain'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
              tooltip: 'Salin subdomain',
            ),
          ],
        ),
      )).toList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          'Domain OSINT',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
            color: Colors.white,
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
                        controller: _domainController,
                        style: TextStyle(color: primaryWhite, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Masukkan Domain',
                          labelStyle: TextStyle(color: primaryWhite.withOpacity(0.6), fontSize: 12),
                          hintText: 'Contoh: example.com',
                          hintStyle: TextStyle(color: primaryWhite.withOpacity(0.3), fontSize: 12),
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
                        onSubmitted: (_) => _checkDomain(),
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
                            onPressed: _isLoading ? null : _checkDomain,
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
                                  _isLoading ? 'MEMPROSES...' : 'CEK DOMAIN',
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
                      color: subtleGlass,
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
                            style: TextStyle(color: primaryWhite, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Results Section
                if (_dnsData != null || _subdomainsData != null)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Domain Information
                          if (_dnsData != null)
                            _buildCategoryCard(
                              title: "INFORMASI DOMAIN",
                              icon: Icons.domain,
                              children: [
                                _buildInfoRow(
                                  label: "Domain",
                                  value: _dnsData!['unicodeDomain']?.toString(),
                                  showCopyButton: true,
                                ),
                                _buildInfoRow(
                                  label: "Punycode",
                                  value: _dnsData!['punycodeDomain']?.toString(),
                                  showCopyButton: true,
                                ),
                                ..._buildDnsRecords(),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // Subdomains
                          if (_subdomainsData != null)
                            _buildCategoryCard(
                              title: "SUBDOMAINS",
                              icon: Icons.list,
                              children: _buildSubdomainsList(),
                            ),
                        ],
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