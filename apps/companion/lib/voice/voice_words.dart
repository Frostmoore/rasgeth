// The voice's failures in the person's language (G40.10): the server's codes, the same as the
// page's `err_voice_*`, with the provider's name and the status where it gives them.
import '../api/client.dart';
import '../l10n/app_localizations.dart';
import '../brand.dart';

String voiceErrorText(AppLocalizations l, Object error) {
  if (error is VoiceException) {
    final name = error.vars['name'] ?? kProductName;
    final status = error.vars['status'] ?? '${error.status}';
    switch (error.code) {
      case 'voice_no_service':
        return l.voiceErrNoService;
      case 'voice_no_key':
        return l.voiceErrNoKey(name);
      case 'voice_empty':
        return l.voiceErrEmpty;
      case 'voice_too_long':
        return l.voiceErrTooLong;
      case 'voice_convert':
        return l.voiceErrConvert;
      case 'voice_timeout':
        return l.voiceErrTimeout(name);
      case 'voice_unreachable':
        return l.voiceErrUnreachable(name);
      case 'voice_key_refused':
        return l.voiceErrKeyRefused(name);
      case 'voice_rate_limited':
        return l.voiceErrRateLimited(name);
      case 'voice_service_error':
        return l.voiceErrServiceError(name, status);
      case 'voice_provider':
        return l.voiceErrProvider;
    }
  }
  if (error is ApiException && error.unreachable) return l.voiceErrServer;
  return l.voiceErrOther;
}
