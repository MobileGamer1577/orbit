import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ══════════════════════════════════════════════════════════════
//
//  🌐 FORTNITE LOGIN WEBVIEW
//  Datei: lib/screens/fortnite_login_webview.dart
//
//  Öffnet die Epic Games Login-Seite in einem In-App-Browser.
//
//  Ablauf:
//    1. Lädt loginUrl (Epic OAuth Authorize-Seite)
//    2. User loggt sich ein
//    3. Epic leitet auf https://localhost/callback?code=... weiter
//    4. WebView fängt den Code ab und schließt sich
//
//  Rückgabe: Der Code als String, oder null wenn abgebrochen.
//
// ══════════════════════════════════════════════════════════════

class FortniteLoginWebView extends StatefulWidget {
  final String loginUrl;

  const FortniteLoginWebView({super.key, required this.loginUrl});

  @override
  State<FortniteLoginWebView> createState() =>
      _FortniteLoginWebViewState();
}

class _FortniteLoginWebViewState extends State<FortniteLoginWebView> {
  late final WebViewController _controller;
  bool _pageLoading = true;
  bool _codeFound   = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF07020F))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _pageLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _pageLoading = false);
          },
          onWebResourceError: (error) {
            // localhost/callback ergibt immer einen Fehler → ignorieren
            if (error.isForMainFrame == true &&
                !(error.url?.contains('localhost') ?? false)) {
              debugPrint('WebView Fehler: ${error.description}');
            }
          },
          onNavigationRequest: (request) {
            return _handleNavigation(request.url);
          },
          onUrlChange: (change) {
            if (change.url != null) _checkUrl(change.url!);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginUrl));
  }

  NavigationDecision _handleNavigation(String url) {
    final intercept = _checkUrl(url);
    return intercept
        ? NavigationDecision.prevent
        : NavigationDecision.navigate;
  }

  /// Prüft ob die URL den Auth-Code enthält.
  /// Gibt true zurück wenn Code gefunden und Pop ausgelöst wurde.
  bool _checkUrl(String url) {
    if (_codeFound) return true;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Epic leitet auf https://localhost/callback?code=... weiter
    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      _codeFound = true;
      Future.microtask(() {
        if (mounted) Navigator.pop(context, code);
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07020F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1026),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, null),
          tooltip: 'Abbrechen',
        ),
        title: const Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Color(0xFF00D4FF),
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Epic Games Login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _pageLoading
              ? const LinearProgressIndicator(
                  color: Color(0xFF00D4FF),
                  backgroundColor: Colors.transparent,
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_pageLoading)
            Container(
              color: const Color(0xFF07020F),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00D4FF)),
                    SizedBox(height: 16),
                    Text(
                      'Epic Games wird geladen…',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
