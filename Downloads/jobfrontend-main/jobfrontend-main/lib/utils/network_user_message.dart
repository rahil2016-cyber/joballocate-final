import 'dart:async';
import 'dart:io';

/// Maps low-level [SocketException], timeouts, and typical [http] client errors
/// into copy users understand (Wi‑Fi / mobile data / server unreachable).
class NetworkUserMessage {
  NetworkUserMessage._();

  static const String connectivityTitle = 'No connection';
  static const String connectivityBody =
      'We could not reach the server. Turn on Wi‑Fi or mobile data, check that you have signal, then try again.';

  static const String timeoutTitle = 'Request timed out';
  static const String timeoutBody =
      'The server took too long to respond. Check your internet connection and try again.';

  static const String serverUnreachableTitle = 'Server unreachable';
  static const String serverUnreachableBody =
      'The app cannot load data right now. If you are on a company or guest network, it may block access — try another network or try again later.';

  /// Non-null when [error] looks like a connectivity / reachability problem.
  static ({String title, String message})? describe(Object error) {
    if (error is SocketException) {
      return (title: connectivityTitle, message: connectivityBody);
    }
    if (error is TimeoutException) {
      return (title: timeoutTitle, message: timeoutBody);
    }

    final raw = error.toString();
    final s = raw.toLowerCase();

    if (s.contains('socketexception') ||
        s.contains('connection timed out') ||
        s.contains('connection refused') ||
        s.contains('network is unreachable') ||
        s.contains('host lookup failed') ||
        s.contains('failed host lookup') ||
        s.contains('name or service not known')) {
      return (title: connectivityTitle, message: connectivityBody);
    }

    if (s.contains('timeoutexception') || s.contains('timed out')) {
      return (title: timeoutTitle, message: timeoutBody);
    }

    if (s.contains('clientexception') &&
        (s.contains('connection') ||
            s.contains('socket') ||
            s.contains('timed out') ||
            s.contains('failed'))) {
      return (title: serverUnreachableTitle, message: serverUnreachableBody);
    }

    return null;
  }

  /// Short paragraph for snackbars / single-line contexts.
  static String shortSummary(Object error) {
    final d = describe(error);
    if (d != null) return d.message;
    const prefix = 'Exception: ';
    final t = error.toString();
    if (t.startsWith(prefix)) return t.substring(prefix.length);
    return t;
  }

  /// Prefer [describe]; otherwise a generic fallback (no raw stack in UI).
  static String fullUserMessage(Object error) {
    final d = describe(error);
    if (d != null) return '${d.title}\n\n${d.message}';
    return 'Something went wrong while loading data. Please try again.\n\n'
        'If this keeps happening, check your internet connection or try again later.';
  }

  static bool looksLikeNetwork(Object error) => describe(error) != null;
}
