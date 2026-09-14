import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_colors.dart';
import '../core/orientation.dart';
import '../widgets/neon_button.dart';

class SimpleWebViewScreen extends StatefulWidget {
  const SimpleWebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.readable = false,
    this.fullscreen = false,
  });

  final String title;
  final String url;
  final bool readable;
  final bool fullscreen;

  @override
  State<SimpleWebViewScreen> createState() => _SimpleWebViewScreenState();
}

class _SimpleWebViewScreenState extends State<SimpleWebViewScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _hasError = false;

  static const _readableCss = '''
    (function() {
      document.documentElement.style.background = '#ffffff';
      document.body.style.background = '#ffffff';
      document.body.style.color = '#111111';
      var s = document.createElement('style');
      s.textContent = [
        'html,body,#app,#root,main,article,section{background:#ffffff!important;color:#111111!important;}',
        'body{padding:20px 16px 40px!important;box-sizing:border-box!important;}',
        'body,p,li,h1,h2,h3,h4,h5,h6,span,div,td,th,label,small,strong,em{color:#111111!important;}',
        'a,a *{color:#0b57d0!important;}',
        'input,textarea,select{color:#111!important;background:#fff!important;border-color:#ccc!important;}'
      ].join(' ');
      document.head.appendChild(s);
    })();
  ''';

  @override
  void initState() {
    super.initState();
    VxOrientation.lockPortrait();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _progress = p / 100);
          },
          onPageFinished: (_) {
            if (widget.readable || widget.fullscreen) {
              _controller.runJavaScript(_readableCss);
            }
          },
          onPageStarted: (_) {
            if (widget.readable || widget.fullscreen) {
              _controller.runJavaScript(_readableCss);
            }
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame == false) return;
            _loadFallback();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _loadFallback() {
    setState(() => _hasError = false);
    _controller.loadHtmlString(_fallbackHtml(widget.title));
  }

  static String _fallbackHtml(String title) {
    final isPrivacy = title.toLowerCase().contains('privacy');
    final body = isPrivacy
        ? '''
<h1>Privacy Policy</h1>
<p>Vortixa Drop is an offline decision tool. Options, saved sets, history, and settings stay on this device.</p>
<p>The app does not require an account, and core features do not send your choices to a server.</p>
<p>Optional Privacy Policy and Support pages may load from vortixadrop.com when a network is available.</p>
<p>Contact: support@vortixadrop.com</p>
'''
        : '''
<h1>Support</h1>
<p>Add options, choose Quick / Multi / Split, then hold Drop. No login is required.</p>
<p>Email: support@vortixadrop.com</p>
''';
    return '''
<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body{font-family:-apple-system,sans-serif;background:#fff;color:#111;padding:20px 16px 40px;line-height:1.45}
  h1{font-size:22px}
</style></head>
<body>$body</body></html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final page = _hasError
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: Colors.black45, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "Couldn't load this page. Try again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      setState(() => _hasError = false);
                      _controller.loadRequest(Uri.parse(widget.url));
                    },
                  ),
                ],
              ),
            ),
          )
        : WebViewWidget(controller: _controller);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_progress < 1)
              LinearProgressIndicator(
                value: _progress,
                minHeight: 3,
                backgroundColor: Colors.black12,
                color: VxColors.cyan,
              ),
            Expanded(child: page),
          ],
        ),
      ),
    );
  }
}
