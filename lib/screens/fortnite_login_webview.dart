import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ══════════════════════════════════════════════════════════════
//
//  🌐 FORTNITE LOGIN WEBVIEW
//  Datei: lib/screens/fortnite_login_webview.dart
//
//  Öffnet die Epic Games Login-Seite in einem In-App-Browser.
//  Sobald Epic nach dem Login auf eine URL mit ?code=... weiterleitet,
//  wird der Code abgefangen und die Seite geschlossen.
//
//  Verwendung:
//    final code = await Navigator.push<String?>(
//      context,
//      MaterialPageRoute(
//        builder: (_) => FortniteLoginWebView(loginUrl: url),
//      ),
//    );
//    if (code != null) { /* weiter mit POST /oauth/link */ }
//
// ══════════════════════════════════════════════════════════════

class FortniteLoginWebView extends StatefulWidget {
  /// Die Login-URL von GET /api/v1/oauth/authorize-url
  final String loginUrl;

  const FortniteLoginWebView({super.key, required this.loginUrl});

  @override
  State<FortniteLoginWebView> createState() => _FortniteLoginWebViewState();
}

class _FortniteLoginWebViewState extends State<FortniteLoginWebView> {
  late final WebViewController _controller;
  bool _pageLoading = true;
  bool _codeFound = false; // Verhindert doppeltes Pop

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
          onWebResourceError: (WebResourceError error) {
            // Nur echte Fehler loggen, Abbruch durch Interception ignorieren
            if (error.isForMainFrame == true) {
              debugPrint('WebView Fehler: ${error.description}');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigation(request.url);
          },
          onUrlChange: (UrlChange change) {
            // Zusätzliche Absicherung: auch URL-Änderungen ohne Navigation prüfen
            if (change.url != null) {
              _checkUrlForCode(change.url!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginUrl));
  }

  // ── Code-Erkennung ─────────────────────────────────────────

  NavigationDecision _handleNavigation(String url) {
    final hasCode = _checkUrlForCode(url);
    return hasCode ? NavigationDecision.prevent : NavigationDecision.navigate;
  }

  /// Gibt true zurück wenn ein Code gefunden wurde (und pop ausgeführt).
  bool _checkUrlForCode(String url) {
    if (_codeFound) return true;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      _codeFound = true;
      // Kurze Verzögerung damit WebView die Navigation sauber beenden kann
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
            Icon(Icons.lock_outline, color: Color(0xFF00D4FF), size: 18),
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

          // Erster Ladescreen (bevor die Seite startet)
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
                      style: TextStyle(color: Colors.white54, fontSize: 14),
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
