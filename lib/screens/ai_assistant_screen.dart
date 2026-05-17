import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ── Colors (matches your app palette) ────────────────────────────────────────
class _C {
  static const pastelBlue   = Color(0xFFAEC6E8);
  static const pastelOrange = Color(0xFFFFCBA4);
  static const deepBlue     = Color(0xFF3A5A8A);
  static const deepOrange   = Color(0xFFD4845A);
  static const delivered    = Color(0xFF5A8A6A);
  static const lowStock     = Color(0xFFCB9A50);
  static const outOfStock   = Color(0xFFCC6666);
}

const _kBgGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.40, 0.75, 1.0],
  colors: [
    Color(0xFFDCEAF7),
    Color(0xFFEAD5F0),
    Color(0xFFFFE5CC),
    Color(0xFFFFD6B0),
  ],
);

// ── Data model ────────────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser})
      : time = DateTime.now();
}

// ── AI Assistant Screen ───────────────────────────────────────────────────────
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  // ── API key loaded safely from .env file — never hardcoded ───────────────
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl     = ScrollController();
  final List<_ChatMessage> _messages     = [];
  bool _isLoading = false;

  final List<String> _suggestions = [
    'How many orders are processing?',
    'Which products are low in stock?',
    'Give me a business summary',
    'How many customers do we have?',
    'Any out-of-stock products?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text:
          "Hi! I'm your Business Assistant 🤖\n\nI can answer questions about your orders, inventory, and customers. Try asking me anything!",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Fetch live Firestore data ─────────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchBusinessData() async {
    final firestore = FirebaseFirestore.instance;

    final ordersSnap    = await firestore.collection('customer_orders').get();
    final inventorySnap = await firestore.collection('checkin_logs').get();
    final customersSnap = await firestore.collection('customers').get();

    return {
      'orders':    ordersSnap.docs.map((d) => d.data()).toList(),
      'inventory': inventorySnap.docs.map((d) => d.data()).toList(),
      'customers': customersSnap.docs.map((d) => d.data()).toList(),
    };
  }

  // ── Build context string for the AI ──────────────────────────────────────
  String _buildContext(Map<String, dynamic> data) {
    final orders    = data['orders']    as List;
    final inventory = data['inventory'] as List;
    final customers = data['customers'] as List;

    final processing = orders.where((o) => o['orderStatus'] == 'Processing').length;
    final shipped    = orders.where((o) => o['orderStatus'] == 'Shipped').length;
    final delivered  = orders.where((o) => o['orderStatus'] == 'Delivered').length;

    final lowStock = inventory.where((i) =>
        i['stockStatus'] == 'Low stock' ||
        i['stockStatus'] == 'Low Stock').toList();
    final outStock = inventory.where((i) =>
        i['stockStatus'] == 'Out-of-stock' ||
        i['stockStatus'] == 'Out of stock').toList();
    final inStock = inventory.where((i) =>
        i['stockStatus'] == 'In-stock' ||
        i['stockStatus'] == 'In stock').toList();

    final lowStockNames =
        lowStock.map((i) => i['productName'] ?? 'Unknown').join(', ');
    final outStockNames =
        outStock.map((i) => i['productName'] ?? 'Unknown').join(', ');

    final orderDetails = orders.take(10).map((o) =>
        '- ${o['productName'] ?? 'Unknown'} | Qty: ${o['quantity'] ?? '?'} | '
        'Status: ${o['orderStatus'] ?? '?'} | Customer: ${o['customerName'] ?? '?'}')
        .join('\n');

    return '''
BUSINESS DATA SNAPSHOT (as of now):

ORDERS:
- Total orders: ${orders.length}
- Processing: $processing
- Shipped: $shipped
- Delivered: $delivered

Recent order details:
$orderDetails

INVENTORY:
- Total items tracked: ${inventory.length}
- In-stock: ${inStock.length}
- Low stock (${lowStock.length}): $lowStockNames
- Out-of-stock (${outStock.length}): $outStockNames

CUSTOMERS:
- Total customers: ${customers.length}
''';
  }

  // ── Send message to Groq API ──────────────────────────────────────────────
  Future<void> _sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    // Guard: check key is loaded
    if (_apiKey.isEmpty) {
      setState(() => _messages.add(_ChatMessage(
        text: '⚠️ API key not found. Make sure your .env file has GROQ_API_KEY set.',
        isUser: false,
      )));
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: userText, isUser: true));
      _isLoading = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      // 1. Fetch live Firestore data
      final businessData = await _fetchBusinessData();
      final context      = _buildContext(businessData);

      // 2. Call Groq API (free — very generous rate limits, no quota issues)
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'max_tokens': 512,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful business assistant for a small business mobile app called Markify. '
                  'Answer questions clearly and concisely. Use emojis sparingly. '
                  'Keep answers brief (2-5 sentences max unless a list is needed). '
                  'If data is missing or zero, say so honestly.\n\n'
                  'Live business data:\n$context',
            },
            {
              'role': 'user',
              'content': userText,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final body    = jsonDecode(response.body);
        final aiReply = body['choices'][0]['message']['content'] as String;
        setState(() =>
            _messages.add(_ChatMessage(text: aiReply, isUser: false)));
      } else {
        final err = jsonDecode(response.body);
        setState(() => _messages.add(_ChatMessage(
          text:
              '⚠️ API Error ${response.statusCode}: ${err['error']?['message'] ?? 'Unknown error'}',
          isUser: false,
        )));
      }
    } catch (e) {
      setState(() => _messages.add(_ChatMessage(
        text:
            '⚠️ Could not connect. Check your internet connection.\n\nError: $e',
        isUser: false,
      )));
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text('Powered by Groq',
                    style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        backgroundColor: _C.deepBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _kBgGradient),
        child: Column(
          children: [
            // ── Chat messages ──────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),

            // ── Suggestion chips (shown on first open) ─────────────────
            if (_messages.length == 1)
              _SuggestionChips(
                suggestions: _suggestions,
                onTap: _sendMessage,
              ),

            // ── Input bar ──────────────────────────────────────────────
            SafeArea(
              top: false,
              child: _InputBar(
                controller: _inputCtrl,
                isLoading: _isLoading,
                onSend: () => _sendMessage(_inputCtrl.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _C.deepBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _C.deepBlue : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : _C.deepBlue,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: _C.pastelOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline,
                  color: _C.deepOrange, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _C.deepBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 16),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    color: _C.deepBlue,
                    backgroundColor: _C.pastelBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: TextStyle(
                    fontSize: 13,
                    color: _C.deepBlue.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Suggestion Chips ──────────────────────────────────────────────────────────
class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;

  const _SuggestionChips(
      {required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => onTap(suggestions[i]),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.pastelBlue),
              ),
              child: Text(
                suggestions[i],
                style: const TextStyle(
                  fontSize: 12,
                  color: _C.deepBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            border: const Border(
                top: BorderSide(color: Colors.white54, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isLoading,
                  onSubmitted: (_) => onSend(),
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Ask about your business...',
                    hintStyle: TextStyle(
                        color: _C.deepBlue.withOpacity(0.45), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.80),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                          color: _C.pastelBlue.withOpacity(0.60)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: _C.deepBlue, width: 1.5),
                    ),
                  ),
                  style: const TextStyle(color: _C.deepBlue, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isLoading ? null : onSend,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isLoading
                        ? _C.pastelBlue.withOpacity(0.50)
                        : _C.deepBlue,
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}