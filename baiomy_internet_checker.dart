import 'dart:async';
import 'dart:io';

/// Usage:
///   in main :
///   await BaiomyInternetChecker.instance.initialize();
///   -------------------------------------------------
///   final checker = BaiomyInternetChecker.instance;
///   await checker.initialize();
///
///   // One-time check
///   bool online = await checker.hasConnection;
///
///   // React to changes
///   checker.onStatusChanged.listen((status) { ... });
///
///   // Use named states
///   if (checker.currentStatus == InternetStatus.connected) { ... }

enum InternetStatus { connected, disconnected, checking }

class BaiomyInternetChecker {
  BaiomyInternetChecker._();
  static final BaiomyInternetChecker instance = BaiomyInternetChecker._();
  Duration pollingInterval = const Duration(seconds: 5);
  Duration lookupTimeout = const Duration(seconds: 3);

  final List<String> _hosts = [
    'google.com',
    'cloudflare.com',
    '1.1.1.1', // Cloudflare IP — works even when DNS is broken
    '8.8.8.8', // Google DNS IP
  ];

  InternetStatus _currentStatus = InternetStatus.checking;
  InternetStatus get currentStatus => _currentStatus;

  bool get isConnected => _currentStatus == InternetStatus.connected;

  bool get isDisconnected => _currentStatus == InternetStatus.disconnected;

  final StreamController<InternetStatus> _statusController =
      StreamController<InternetStatus>.broadcast();

  Stream<InternetStatus> get onStatusChanged => _statusController.stream;

  Timer? _pollingTimer;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _check();
    _startPolling();
  }

  Future<bool> get hasConnection async {
    final result = await _lookup();
    _emit(result ? InternetStatus.connected : InternetStatus.disconnected);
    return result;
  }

  void dispose() {
    _pollingTimer?.cancel();
    _statusController.close();
    _initialized = false;
  }

  Future<bool> _lookup() async {
    try {
      final futures = _hosts.map((host) => _singleLookup(host));
      final result = await Future.any(futures);
      return result;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _singleLookup(String host) async {
    try {
      final result = await InternetAddress.lookup(host).timeout(lookupTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return _socketFallback(host);
    }
  }

  Future<bool> _socketFallback(String host) async {
    try {
      final socket = await Socket.connect(host, 80, timeout: lookupTimeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(pollingInterval, (_) => _check());
  }

  Future<void> _check() async {
    final online = await _lookup();
    _emit(online ? InternetStatus.connected : InternetStatus.disconnected);
  }

  void _emit(InternetStatus status) {
    if (_currentStatus == status) return;
    _currentStatus = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}
