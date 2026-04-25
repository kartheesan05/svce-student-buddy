part of 'app_state.dart';

String _userVisibleNetworkError(Object error) {
  final s = error.toString();
  if (s.contains('Failed host lookup') ||
      s.contains('SocketException') ||
      s.contains('ClientException') ||
      s.contains('Network is unreachable') ||
      s.contains('Connection timed out')) {
    return "Can't reach the server. Check your internet connection and try again.";
  }
  return s;
}

bool _isLikelyNetworkIssue(Object error) {
  if (error is ApiException) {
    final message = error.message.toLowerCase();
    if (message.contains("can't reach the server") ||
        message.contains('check your internet connection')) {
      return true;
    }
  }
  final s = error.toString();
  return s.contains('Failed host lookup') ||
      s.contains('SocketException') ||
      s.contains('ClientException') ||
      s.contains('Network is unreachable') ||
      s.contains('Connection timed out');
}

Future<void> _handleApiErrorImpl(
  AppState state,
  Object error,
  StackTrace stackTrace,
  String context,
) async {
  debugPrint('$context error: $error\n$stackTrace');
  state._maybeQueueNetworkIssueToast(error);
  if (state._isHandlingSessionExpiry) return;
  if (error is! ApiException || !error.message.toLowerCase().contains('session expired')) {
    return;
  }
  state._isHandlingSessionExpiry = true;
  state.error = error.message;
  try {
    final refreshed = await state._tryRefreshSessionWithStoredCredentials();
    if (refreshed) {
      state._sessionRefreshTriggeredDuringReload = true;
    }
  } finally {
    state._isHandlingSessionExpiry = false;
  }
}

void _maybeQueueNetworkIssueToastImpl(AppState state, Object error) {
  if (!_isLikelyNetworkIssue(error)) return;
  final now = DateTime.now();
  final lastShownAt = state._lastNetworkToastAt;
  if (lastShownAt != null &&
      now.difference(lastShownAt) < const Duration(seconds: 6)) {
    return;
  }
  state._lastNetworkToastAt = now;
  state._queueToast(
    "Can't reach the server. Check your internet connection and try again.",
  );
}

void _queueToastImpl(AppState state, String message) {
  state._pendingToastMessage = message;
  state._notifyDirect();
}
