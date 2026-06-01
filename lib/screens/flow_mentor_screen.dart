import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../widgets/glass_widgets.dart';


// 🤖 GEMINI MODEL CONFIGURATION (Using the stable Gemini 2.5 Flash model)
const String geminiModel = 'gemini-2.5-flash';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class FlowMentorScreen extends StatefulWidget {
  const FlowMentorScreen({super.key});

  @override
  State<FlowMentorScreen> createState() => _FlowMentorScreenState();
}

class _FlowMentorScreenState extends State<FlowMentorScreen> with SingleTickerProviderStateMixin {
  late final Box<Habit> _habitBox;
  late final Box<UserProfile> _profileBox;

  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  late final AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _habitBox = Hive.box<Habit>('habits');
    _profileBox = Hive.box<UserProfile>('user_profiles');

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Initialize with customized welcome greeting from Aura using current user name
    final profile = _profileBox.get('main_profile') ?? UserProfile();
    _messages.add(ChatMessage(
      text: "Greetings, ${profile.name}! 🌌 I am Aura, your Flow Mentor. I read your active habits and leveling progress in real-time. Ask me anything to align your focus or battle the Glitch Lord!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _typingController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(String query) async {
    if (query.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Call Gemini API with dynamic RPG stats context injected
    try {
      final profile = _profileBox.get('main_profile') ?? UserProfile();
      final activeHabits = _habitBox.values.where((h) => !h.archived).toList();
      final completedCount = activeHabits.where((h) => h.isCompletedToday).length;

      final systemPrompt = "You are Aura, the Flow Mentor, a supportive RPG companion guide in a gamified habit tracking app called FlowState. "
          "The user's profile information: "
          "- Name: ${profile.name} "
          "- RPG Level: ${profile.userLevel} "
          "- Spark XP: ${profile.userSparks}/${profile.userLevel * 50} "
          "- Raid Boss HP: ${profile.bossHp}/${profile.maxBossHp} (Tier ${profile.bossTier}) "
          "- Active Habits: ${activeHabits.map((h) => '${h.name} (${h.category}, Streak: ${h.streak} days, Progress: ${h.currentProgress}/${h.targetGoal})').join(', ')} "
          "- Completed Today: $completedCount/${activeHabits.length} habits. "
          "\nProvide encouraging, personalized RPG-style guidance, suggestions, and tips. Keep your response relatively concise (2-4 sentences), motivating, and thematic (incorporate RPG, flow, stars, sparks, or freezing metaphors).";

      // 🔑 Gemini API Key loaded securely from .env file
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (geminiApiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env file. Please add it.');
      }

      // 🔑 Gemini API Endpoint Setup (Constructed dynamically from Model ID)
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$geminiApiKey');

      final client = HttpClient();
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      
      final body = {
        "contents": [
          {
            "parts": [
              {
                "text": "$systemPrompt\n\nUser Question: $query"
              }
            ]
          }
        ]
      };

      final bodyStr = jsonEncode(body);
      final bodyBytes = utf8.encode(bodyStr);
      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final jsonResponse = jsonDecode(responseBody);
        
        String text = '';
        if (jsonResponse != null &&
            jsonResponse['candidates'] != null &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0]['content'] != null &&
            jsonResponse['candidates'][0]['content']['parts'] != null &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          text = jsonResponse['candidates'][0]['content']['parts'][0]['text'] ?? '';
        }
        
        if (text.isEmpty) {
          text = "I received the stars' signals, but the response was obscured by safety filters or came back empty. Please try rephrasing your message!";
        }

        setState(() {
          _messages.add(ChatMessage(
            text: text.trim(),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        String errorMsg = "My cosmic signals are fading, adventurer. Please check your Gemini API key in flow_mentor_screen.dart.";
        try {
          final errorBody = await response.transform(utf8.decoder).join();
          final jsonError = jsonDecode(errorBody);
          if (jsonError != null && jsonError['error'] != null && jsonError['error']['message'] != null) {
            errorMsg = "Cosmic Error: ${jsonError['error']['message']}";
          }
        } catch (_) {}

        setState(() {
          _messages.add(ChatMessage(
            text: "$errorMsg (Status code: ${response.statusCode})",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "I couldn't reach the celestial grid. Check your connection or API key setup! Error: $e",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestedPrompts = [
      {"icon": "⚔️", "text": "How do I beat the Glitch Lord?"},
      {"icon": "📈", "text": "Optimize my habits schedule"},
      {"icon": "❄️", "text": "When should I use Streak Freeze?"},
    ];

    return Column(
      children: [
        // Sleek Custom Frosted Header Strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff4FACFE), Color(0xff00F2C3)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff00F2C3).withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌊', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aura, the Flow Mentor',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Context-Aware AI Companion',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Chat History Canvas
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return TweenAnimationBuilder<double>(
                key: ValueKey(message.hashCode), // Unique key per message to trigger entry animation once
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutQuart,
                builder: (context, animVal, child) {
                  return Opacity(
                    opacity: animVal,
                    child: Transform.translate(
                      offset: Offset(0.0, 18.0 * (1.0 - animVal)),
                      child: child,
                    ),
                  );
                },
                child: Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: Row(
                      mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!message.isUser) ...[
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 10, top: 4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xff4FACFE), Color(0xffC77DFF)],
                              ),
                            ),
                            child: const Center(
                              child: Text('✨', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                        ],
                        Flexible(
                          child: GlassCard(
                            borderRadius: 18.0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: message.isUser
                                ? const Color(0xff00F2C3).withOpacity(0.1)
                                : const Color(0xff4FACFE).withOpacity(0.06),
                            borderColor: message.isUser
                                ? const Color(0xff00F2C3).withOpacity(0.24)
                                : Colors.white.withOpacity(0.08),
                            child: Text(
                              message.text,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.45,
                              ),
                            ),
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

        // Typing Status Box ("Thinking...")
        if (_isTyping)
          Padding(
            padding: const EdgeInsets.only(left: 24.0, bottom: 12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xff4FACFE), Color(0xffC77DFF)],
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _typingController,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: _typingController.value * 2 * math.pi,
                          child: const Center(
                            child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                          ),
                        );
                      },
                    ),
                  ),
                  GlassCard(
                    borderRadius: 16.0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: const Color(0xff4FACFE).withOpacity(0.06),
                    borderColor: Colors.white.withOpacity(0.08),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Aura is thinking',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(3, (idx) {
                            return AnimatedBuilder(
                              animation: _typingController,
                              builder: (context, _) {
                                final delay = idx * 0.2;
                                final value = ((_typingController.value - delay) % 1.0).clamp(0.0, 1.0);
                                final opacity = value > 0.5 ? (1.0 - value) * 2.0 : value * 2.0;

                                return Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xff00F2C3).withOpacity(opacity.clamp(0.1, 1.0)),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Suggested Action Prompts
        if (!_isTyping)
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: suggestedPrompts.length,
              itemBuilder: (context, index) {
                final chip = suggestedPrompts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ActionChip(
                    avatar: Text(chip["icon"]!),
                    label: Text(
                      chip["text"]!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff4FACFE),
                      ),
                    ),
                    backgroundColor: const Color(0xff4FACFE).withOpacity(0.08),
                    side: BorderSide(color: const Color(0xff4FACFE).withOpacity(0.18)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () => _sendMessage(chip["text"]!),
                  ),
                );
              },
            ),
          ),

        // Input Keyboard Strip
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _messageController,
                  hintText: 'Ask Aura your RPG flow guide...',
                  prefixIcon: Icons.auto_awesome_outlined,
                  onChanged: (text) {},
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: _isTyping
                    ? null // Prevent prompt stacking!
                    : () {
                        HapticFeedback.lightImpact();
                        _sendMessage(_messageController.text);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _isTyping
                        ? null // Frosted when typing
                        : const LinearGradient(
                            colors: [Color(0xff4FACFE), Color(0xff00F2C3)],
                          ),
                    color: _isTyping ? Colors.white.withOpacity(0.04) : null,
                    borderRadius: BorderRadius.circular(16),
                    border: _isTyping
                        ? Border.all(color: Colors.white.withOpacity(0.08))
                        : null,
                    boxShadow: _isTyping
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xff00F2C3).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Center(
                    child: _isTyping
                        ? AnimatedBuilder(
                            animation: _typingController,
                            builder: (context, _) {
                              return CustomPaint(
                                size: const Size(22, 22),
                                painter: CosmicLoaderPainter(
                                  rotationValue: _typingController.value,
                                  color: const Color(0xff00F2C3),
                                ),
                              );
                            },
                          )
                        : const Icon(Icons.send_rounded, color: Colors.black, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80), // offset bottom nav overlap
      ],
    );
  }
}

// 🪐 PREMIUM COSMIC LOADING INDICATOR VECTOR SPINNER
class CosmicLoaderPainter extends CustomPainter {
  final double rotationValue; // 0.0 to 1.0 for continuous spin
  final Color color;

  CosmicLoaderPainter({
    required this.rotationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width * 0.38;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotationValue * 2 * math.pi);

    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    
    // Major glowing loading arc
    canvas.drawArc(rect, 0.0, 1.45 * math.pi, false, paint);
    
    // Fading minor tail arc
    paint.color = color.withOpacity(0.25);
    canvas.drawArc(rect, 1.55 * math.pi, 0.25 * math.pi, false, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CosmicLoaderPainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue || oldDelegate.color != color;
  }
}
