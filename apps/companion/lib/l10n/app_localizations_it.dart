// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'RGCompanion';

  @override
  String get tabTeam => 'Squadra';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabInbox => 'Da te';

  @override
  String get tabActivity => 'Attività';

  @override
  String get tabYou => 'Tu';

  @override
  String get composerHint => 'Scrivi alla Chat…';

  @override
  String get composerSend => 'Invia';

  @override
  String get noServer => 'Nessun RedGiant collegato';

  @override
  String get connectFromYou => 'Collegalo da Tu.';

  @override
  String get statusConnected => 'collegato';

  @override
  String get statusUnreachable => 'non raggiungibile';

  @override
  String get pillInbox => 'Da te';

  @override
  String get pillRunning => 'In corso';

  @override
  String get stateIdle => 'fermo';

  @override
  String get stateThink => 'pensa';

  @override
  String get stateWork => 'lavora';

  @override
  String get stateWait => 'aspetta te';

  @override
  String get stateError => 'bloccato';

  @override
  String mascotLabel(String name, String state) {
    return 'Mascotte di $name, $state';
  }

  @override
  String get teamEmpty => 'Ancora nessun agente.';

  @override
  String get chatNew => 'Nuova conversazione';

  @override
  String get chatEmpty => 'Le conversazioni con la Chat, giorno per giorno, compaiono qui.';

  @override
  String get chatDraftNote =>
      'Messaggio pronto: l\'invio arriva con la prossima versione dell\'app.';

  @override
  String get inboxEmpty => 'Niente da decidere: quando un agente ti chiede qualcosa, lo trovi qui.';

  @override
  String get activityEmpty => 'I compiti in corso e finiti, raggruppati per agente, compaiono qui.';

  @override
  String get sectionAppearance => 'Aspetto';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get languageLabel => 'Lingua';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get reduceMotion => 'Riduci movimento';

  @override
  String get reduceMotionHint => 'Le mascotte restano ferme; lo stato si riconosce dal segno.';

  @override
  String get sectionServer => 'RedGiant';

  @override
  String get serverAddress => 'Indirizzo';

  @override
  String get serverAddressHint => 'redgiant.local:8787';

  @override
  String get serverPassword => 'Password';

  @override
  String get serverCode => 'Codice dell\'app di autenticazione';

  @override
  String get connect => 'Collega';

  @override
  String get connecting => 'Collegamento…';

  @override
  String get disconnect => 'Scollega';

  @override
  String connectedTo(String machine) {
    return 'Collegato a $machine';
  }

  @override
  String get errUnreachable => 'RedGiant non risponde a questo indirizzo.';

  @override
  String get errWrong => 'Password o codice sbagliati.';

  @override
  String get errCodeNeeded => 'Serve anche il codice dell\'app di autenticazione.';

  @override
  String get errTooMany => 'Troppi tentativi: riprova tra qualche minuto.';

  @override
  String get errNoPassword =>
      'Questo RedGiant non ha ancora una password: completa il primo avvio.';

  @override
  String get errServerTooOld => 'Questo RedGiant è troppo vecchio per l\'app: aggiornalo.';

  @override
  String get errServerTooNew => 'Questa app è troppo vecchia per questo RedGiant: aggiornala.';

  @override
  String errGeneric(String message) {
    return 'Non è andata: $message';
  }

  @override
  String get appVersion => 'Versione dell\'app';
}
