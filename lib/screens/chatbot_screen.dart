import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => debugPrint("Chatbot loaded"),
      ))
      ..loadFlutterAsset('assets/chatbot.html'); // ✅ Load directly
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SkillBot")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
