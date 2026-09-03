import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../cord/http_persona.dart';
import '../cord/reach_feel.dart';
import '../veil/href_guard.dart';
import '../veil/kine_log.dart';
import '../vault/lane_chest.dart';
import '../vault/push_hub.dart';
import 'void_page.dart';

const Set<String> _paneSchemes = <String>{
  '',
  'http',
  'https',
  'about',
  'data',
  'blob',
};

class WebChamber extends StatefulWidget {
  const WebChamber({
    super.key,
    required this.url,
    required this.locker,
    required this.beacon,
    required this.scout,
    required this.agent,
    this.coldLaunch = false,
  });

  final String url;
  final LaneChest locker;
  final PushHub beacon;
  final ReachFeel scout;
  final HttpPersona agent;
  final bool coldLaunch;

  @override
  State<WebChamber> createState() => _WebChamberState();
}

class _WebChamberState extends State<WebChamber> with WidgetsBindingObserver {
  late final WebViewController _controller;
  StreamSubscription<List<ConnectivityResult>>? _linkSubscription;

  bool _viewportReady = false;
  bool _coldReloadDone = false;
  bool _offlineShown = false;
  int _redirectHops = 0;
  int _pageFinishes = 0;
  int _blankRetries = 0;
  String? _lastMainUrl;
  Size? _lastMetrics;
  double? _pinnedCssWidth;

  late final void Function(String url) _tapHandler = _onLiveTap;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _goImmersive();
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final PlatformWebViewControllerCreationParams params = Platform.isIOS
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();

    _controller =
        WebViewController.fromPlatformCreationParams(
            params,
            onPermissionRequest: (WebViewPermissionRequest req) => req.grant(),
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setUserAgent(widget.agent.userAgent)
          ..enableZoom(false)
          ..setNavigationDelegate(_navigationDelegate());

    final Object platform = _controller.platform;
    if (platform is WebKitWebViewController) {
      platform.setAllowsBackForwardNavigationGestures(true);
    }

    widget.beacon.onDestination = _tapHandler;
    _linkSubscription = widget.scout.changes.listen((
      List<ConnectivityResult> states,
    ) {
      if (states.every((ConnectivityResult s) => s == ConnectivityResult.none)) {
        _showOfflineNow();
      }
    });

    if (widget.coldLaunch) {
      _settleAndOpen();
    } else {
      _viewportReady = true;
      _load(widget.url);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainParked());
  }

  void _goImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _settleAndOpen() async {
    _goImmersive();
    await Future<void>.delayed(const Duration(milliseconds: 345));
    if (!mounted) return;
    setState(() => _viewportReady = true);
    await _load(widget.url);
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    setState(() {});
    final Size size = View.of(context).physicalSize;
    final bool rotated =
        _lastMetrics != null &&
        ((_lastMetrics!.width < _lastMetrics!.height) !=
            (size.width < size.height));
    _lastMetrics = size;
    if (rotated) _goImmersive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _goImmersive();
      _drainParked();
    }
  }

  Future<void> _drainParked() async {
    final String? parked = await widget.locker.takeParkedUrl();
    if (parked != null) await _load(parked);
  }

  void _onLiveTap(String url) => unawaited(_load(url));

  Future<void> _load(String url) async {
    final String? clean = HrefGuard.sanitize(url);
    final Uri? uri = clean == null ? null : Uri.tryParse(clean);
    if (!mounted || uri == null) {
      kineLog(() => '[KINE.PANE] refused url "$url"');
      return;
    }
    kineLog(() => '[KINE.PANE] load $clean');
    _lastMainUrl = uri.toString();
    _redirectHops = 0;
    await _controller.loadRequest(uri);
  }

  NavigationDelegate _navigationDelegate() {
    return NavigationDelegate(
      onPageStarted: (String url) {
        _lastMainUrl = url;
      },
      onPageFinished: (String url) {
        _redirectHops = 0;
        _pageFinishes++;
        kineLog(() => '[KINE.PANE] finished $url');
        _paintShell();
        Future<void>.delayed(const Duration(milliseconds: 1210), () async {
          if (!mounted) return;
          setState(() {});
          _paintShell();
          await _recoverBlankCold();
        });
      },
      onWebResourceError: (WebResourceError error) {
        final bool mainFrame = error.isForMainFrame ?? true;
        kineLog(
          () =>
              '[KINE.PANE] error ${error.errorCode} main=$mainFrame '
              '${error.description}',
        );
        if (error.errorCode == -999) {
          _rescueCancelledFirstLoad(mainFrame);
          return;
        }
        final String lower = error.description.toLowerCase();
        final bool tooManyRedirects =
            error.errorCode == -1007 ||
            lower.contains('too_many_redirects') ||
            lower.contains('too many redirects');
        if (tooManyRedirects &&
            _lastMainUrl != null &&
            _redirectHops < 5) {
          _redirectHops++;
          _controller.loadRequest(Uri.parse(_lastMainUrl!));
          return;
        }
        if (!mainFrame) return;
        _confirmOfflineThenSwitch();
      },
      onNavigationRequest: (NavigationRequest request) {
        final String target = request.url;
        final String scheme = _extractScheme(target);
        if (scheme == 'javascript') return NavigationDecision.prevent;

        if (_paneSchemes.contains(scheme)) {
          if (request.isMainFrame) _lastMainUrl = target;
          return NavigationDecision.navigate;
        }

        final Uri? external = Uri.tryParse(target);
        kineLog(() => '[KINE.PANE] handing off scheme=$scheme');
        if (external != null) {
          launchUrl(external, mode: LaunchMode.externalApplication);
        }
        return NavigationDecision.prevent;
      },
    );
  }

  static String _extractScheme(String url) {
    final int colon = url.indexOf(':');
    if (colon <= 0) return '';
    final String head = url.substring(0, colon);
    return RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*$').hasMatch(head)
        ? head.toLowerCase()
        : '';
  }

  Future<void> _rescueCancelledFirstLoad(bool mainFrame) async {
    if (!mainFrame || _pageFinishes > 0 || _blankRetries >= 1) return;
    final String target = _lastMainUrl ?? widget.url;
    _blankRetries++;
    await Future<void>.delayed(const Duration(milliseconds: 430));
    if (!mounted || _pageFinishes > 0) return;
    kineLog(() => '[KINE.PANE] first load was cancelled; retrying');
    await _load(target);
  }

  Future<void> _recoverBlankCold() async {
    if (!widget.coldLaunch || _coldReloadDone || !mounted) return;
    _coldReloadDone = true;
    final Object? measured;
    try {
      measured = await _controller.runJavaScriptReturningResult(
        '(function(){var b=document.body;return b?b.scrollHeight:0;})()',
      );
    } catch (_) {
      return;
    }
    final double height = switch (measured) {
      num v => v.toDouble(),
      String v => double.tryParse(v) ?? 1,
      _ => 1,
    };
    if (height > 0 || !mounted) return;
    await _controller.reload();
  }

  Future<void> _confirmOfflineThenSwitch() async {
    if (_offlineShown) return;
    bool online = true;
    try {
      online = await widget.scout.reachesNetwork();
    } catch (_) {
      online = false;
    }
    if (online) return;
    _showOfflineNow();
  }

  Future<void> _showOfflineNow() async {
    if (_offlineShown || !mounted) return;
    _offlineShown = true;
    String current;
    try {
      current = await _controller.currentUrl() ?? widget.url;
    } catch (_) {
      current = widget.url;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VoidPage(
          scout: widget.scout,
          retryBuilder: (_) => WebChamber(
            url: current,
            locker: widget.locker,
            beacon: widget.beacon,
            scout: widget.scout,
            agent: widget.agent,
          ),
        ),
      ),
    );
  }

  void _paintShell() {
    if (!mounted) return;
    final MediaQueryData media = MediaQuery.of(context);
    _pinnedCssWidth ??= (media.size.width - media.viewPadding.horizontal)
        .clamp(320.0, 430.0);
    final int widthPx = _pinnedCssWidth!.round();

    const List<String> insetNames = <String>[
      'vx-safe-top',
      'vx-safe-right',
      'vx-safe-bottom',
      'vx-safe-left',
      'safe-area-inset-top',
      'safe-area-inset-right',
      'safe-area-inset-bottom',
      'safe-area-inset-left',
      'sat',
      'sar',
      'sab',
      'sal',
    ];
    final String insetCss = insetNames
        .map((String n) => '--$n:0px!important;')
        .join();

    _controller.runJavaScript('''
(() => {
  const root = window;
  const layoutWidth = $widthPx;
  if (root.__vtDropShell) {
    if (typeof root.__vtDropRepaint === 'function') root.__vtDropRepaint();
    return;
  }
  root.__vtDropShell = 1;
  const sheetName = 'vt-ink-sheet';
  const cssBits = [
    '::-webkit-scrollbar{width:5px;height:5px;}',
    '::-webkit-scrollbar-thumb{background:rgba(0,232,255,.38);border-radius:3px;}',
    '*{-webkit-tap-highlight-color:transparent!important;}',
    'input,textarea,select,[contenteditable="true"]{font-size:max(1em,16px)!important;}',
    'html,body{overscroll-behavior:none!important;overscroll-behavior-y:none!important;}',
    '*:not(input):not(textarea):not([contenteditable="true"]){-webkit-touch-callout:none!important;}',
    ':root{$insetCss}',
    '::selection{background:rgba(178,77,255,.34);}'
  ];
  const css = cssBits.join('');
  const kbOpen = () => {
    const visual = root.visualViewport;
    return !!visual && visual.height < root.innerHeight * 0.72;
  };
  const pinViewport = () => {
    const host = document.head || document.documentElement;
    if (!host) return;
    let vp = document.querySelector('meta[name="viewport"]');
    if (!vp) {
      vp = document.createElement('meta');
      vp.setAttribute('name', 'viewport');
      host.appendChild(vp);
    }
    if (vp.getAttribute('data-vt-lock') === '1') return;
    vp.setAttribute('data-vt-lock', '1');
    vp.setAttribute(
      'content',
      'width=' + layoutWidth + ', initial-scale=1.0, maximum-scale=1.0, ' +
      'minimum-scale=1.0, user-scalable=no, viewport-fit=cover'
    );
  };
  const paint = () => {
    if (kbOpen()) return;
    const host = document.head || document.documentElement;
    if (!host) return;
    pinViewport();
    let sheet = document.getElementById(sheetName);
    if (!sheet) {
      sheet = document.createElement('style');
      sheet.id = sheetName;
      host.appendChild(sheet);
    }
    sheet.textContent = css;
  };
  const later = () => {
    root.setTimeout(paint, 203);
    root.setTimeout(paint, 687);
  };
  const halt = (evt) => { evt.preventDefault(); };
  const editable = (node) => !!node && (
    node.matches && node.matches('input, textarea, select, [contenteditable="true"]')
  );
  let lastTap = 0;
  document.addEventListener('touchend', (evt) => {
    const now = Date.now();
    if (now - lastTap <= 268) evt.preventDefault();
    lastTap = now;
  }, {passive: false});
  document.addEventListener('touchmove', (evt) => {
    if (evt.scale !== undefined && evt.scale !== 1) evt.preventDefault();
  }, {passive: false});
  document.addEventListener('focusin', (evt) => {
    if (!editable(evt.target)) return;
    root.setTimeout(() => {
      const active = document.activeElement;
      if (editable(active)) active.scrollIntoView({behavior: 'auto', block: 'nearest'});
    }, 445);
  }, true);
  ['gesturestart', 'gesturechange', 'gestureend'].forEach((name) => {
    document.addEventListener(name, halt, {passive: false});
  });
  ['pushState', 'replaceState'].forEach((name) => {
    const original = history[name];
    history[name] = function () {
      const out = original.apply(this, arguments);
      later();
      return out;
    };
  });
  root.addEventListener('popstate', later);
  paint();
  root.__vtDropRepaint = paint;
  root.setInterval(paint, 2640);
})();
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    if (widget.beacon.onDestination == _tapHandler) {
      widget.beacon.onDestination = null;
    }
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.of(context).viewPadding;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) await _controller.goBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: ColoredBox(
          color: Colors.black,
          child: _viewportReady
              ? Padding(
                  padding: EdgeInsets.only(
                    top: safe.top,
                    bottom: safe.bottom,
                    left: safe.left,
                    right: safe.right,
                  ),
                  child: WebViewWidget(controller: _controller),
                )
              : const ColoredBox(color: Colors.black),
        ),
      ),
    );
  }
}
