import 'dart:async';
import 'dart:convert'; // ✅ MENGATASI ERROR: jsonDecode & jsonEncode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;  // ✅ DITAMBAH ALIAS 'as p'
import 'package:http/http.dart' as http; // ✅ MENGATASI ERROR: http.post / http.get

class RoomPublicPage extends StatefulWidget {
  final String? username;
  
  const RoomPublicPage({super.key, this.username});

  @override
  State<RoomPublicPage> createState() => _RoomPublicPageState();
}

class _RoomPublicPageState extends State<RoomPublicPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late String currentUsername;
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSending = false;
  Database? _database;
  
  // --- BLUE THEME ---
  static const Color bgDark = Color(0xFF0B0B0E);
  static const Color glassPrimary = Color(0x1AFFFFFF);
  static const Color glassSecondary = Color(0x0DFFFFFF);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color softBlue = Color(0xFF64B5F6);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFA0A0A0);
  static const Color myMessageColor = Color(0xFF2196F3);
  static const Color otherMessageColor = Color(0xFF1A1A1E);

  LinearGradient get blueGradient => const LinearGradient(
    colors: [accentBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'chat_messages.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            isMe INTEGER NOT NULL
          )
        ''');
      },
    );
    
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (_database == null) return;
    
    final List<Map<String, dynamic>> result = await _database!.query(
      'messages',
      orderBy: 'timestamp ASC',
    );
    
    setState(() {
      messages = result;
      isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (widget.username != null && widget.username!.isNotEmpty) {
      currentUsername = widget.username!;
    } else {
      currentUsername = prefs.getString('chat_username') ?? "User${DateTime.now().millisecondsSinceEpoch % 10000}";
      await prefs.setString('chat_username', currentUsername);
    }
    
    setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _database == null) return;

    setState(() {
      isSending = true;
    });

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await _database!.insert('messages', {
        'username': currentUsername,
        'message': message,
        'timestamp': now,
        'isMe': 1,
      });
      
      setState(() {
        messages.add({
          'id': messages.length + 1,
          'username': currentUsername,
          'message': message,
          'timestamp': now,
          'isMe': 1,
        });
      });
      
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showError("Failed to send message: $e");
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(date);
    } else {
      return DateFormat('dd/MM HH:mm').format(date);
    }
  }

  Future<void> _deleteMessage(int id, bool isMe) async {
    if (!isMe) {
      _showError("You can only delete your own messages");
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: glassPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: primaryWhite.withOpacity(0.1), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 12),
            const Text("Delete Message", style: TextStyle(color: primaryWhite, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text("Are you sure you want to delete this message?", style: TextStyle(color: softGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL", style: TextStyle(color: softGrey)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true && _database != null) {
      try {
        await _database!.delete('messages', where: 'id = ?', whereArgs: [id]);
        setState(() {
          messages.removeWhere((msg) => msg['id'] == id);
        });
      } catch (e) {
        _showError("Failed to delete message: $e");
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: glassSecondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryWhite.withOpacity(0.08)),
          ),
          child: const Text(
            "Room Public (Local Chat)",
            style: TextStyle(
              color: primaryWhite,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: accentBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Local Mode",
                  style: TextStyle(color: softGrey, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              accentBlue.withOpacity(0.15),
              bgDark,
              bgDark,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: GridPainter(),
          child: Column(
            children: [
              // User Info
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: glassPrimary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryWhite.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_rounded, color: accentBlue, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      currentUsername,
                      style: const TextStyle(
                        color: softBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 20,
                      color: primaryWhite.withOpacity(0.1),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline, color: accentBlue, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "${messages.length} Messages",
                      style: const TextStyle(
                        color: primaryWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Messages Area
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: glassSecondary,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: accentBlue.withOpacity(0.2)),
                              ),
                              child: const CircularProgressIndicator(
                                color: accentBlue,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Loading messages...",
                              style: TextStyle(color: softGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: glassSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline,
                                    color: accentBlue,
                                    size: 60,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "No Messages Yet",
                                  style: TextStyle(
                                    color: primaryWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Be the first to send a message!",
                                  style: TextStyle(color: softGrey, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMyMessage = message['isMe'] == 1;
                              
                              return GestureDetector(
                                onLongPress: () => _deleteMessage(message['id'], isMyMessage),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isMyMessage) ...[
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: accentBlue.withOpacity(0.2),
                                          child: Text(
                                            (message['username']?.toString().substring(0, 1) ?? 'U').toUpperCase(),
                                            style: const TextStyle(
                                              color: accentBlue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isMyMessage ? myMessageColor : otherMessageColor,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isMyMessage ? accentBlue : primaryWhite.withOpacity(0.08),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (!isMyMessage)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 4),
                                                  child: Text(
                                                    message['username'] ?? 'Unknown',
                                                    style: const TextStyle(
                                                      color: accentBlue,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              Text(
                                                message['message'] ?? '',
                                                style: const TextStyle(
                                                  color: primaryWhite,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatTime(message['timestamp']),
                                                style: TextStyle(
                                                  color: primaryWhite.withOpacity(0.5),
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isMyMessage) ...[
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: myMessageColor.withOpacity(0.2),
                                          child: Text(
                                            currentUsername.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(
                                              color: myMessageColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              
              // Input Area
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: glassPrimary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border(top: BorderSide(color: primaryWhite.withOpacity(0.08))),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: glassSecondary,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: primaryWhite.withOpacity(0.05)),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: primaryWhite, fontSize: 14),
                            cursorColor: accentBlue,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: TextStyle(color: softGrey.withOpacity(0.5), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: blueGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isSending ? null : _sendMessage,
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: primaryWhite,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: primaryWhite,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  static const Color accentBlue = Color(0xFF2196F3);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    
    const gridSize = 30.0;
    
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    final accentPaint = Paint()
      ..color = accentBlue.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }
    
    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }
    
    final dotPaint = Paint()
      ..color = accentBlue.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    
    for (double x = 0; x <= size.width; x += gridSize) {
      for (double y = 0; y <= size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}