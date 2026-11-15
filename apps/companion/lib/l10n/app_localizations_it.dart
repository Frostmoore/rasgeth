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
  String get serverAddressHint => 'redgiant.local, https://…, 10.42.0.1';

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

  @override
  String get attachmentOnly => '(immagini)';

  @override
  String get sendFailed => 'Il messaggio non è partito: riprova.';

  @override
  String attachmentTooBig(String name) {
    return '$name supera i 5 MB.';
  }

  @override
  String get notLive =>
      'Qui non c\'è la connessione viva: le risposte si vedono riaprendo la conversazione.';

  @override
  String get conversationEmpty => 'Ancora niente: scrivi il primo messaggio.';

  @override
  String get loading => 'Carico…';

  @override
  String get attachmentRemove => 'Togli';

  @override
  String get back => 'Indietro';

  @override
  String get stop => 'Ferma';

  @override
  String get attach => 'Allega immagini';

  @override
  String get composerAgentHint => 'Scrivi un messaggio…';

  @override
  String fromSomeone(String from) {
    return 'da $from';
  }

  @override
  String imagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count immagini',
      one: '1 immagine',
    );
    return '$_temp0';
  }

  @override
  String get reasoning => 'Ragionamento';

  @override
  String get reasoningNow => 'Sta ragionando…';

  @override
  String get writing => 'sta scrivendo…';

  @override
  String get toolRunning => 'in corso';

  @override
  String get toolOk => 'fatto';

  @override
  String get toolFailed => 'non riuscito';

  @override
  String get open => 'Apri';

  @override
  String get linkOpenTitle => 'Aprire questo collegamento fuori dall\'app?';

  @override
  String get linkOpen => 'Apri';

  @override
  String get cancel => 'Annulla';

  @override
  String canvasFailed(String error) {
    return 'Non si può mostrare: $error';
  }

  @override
  String get openWithSystem => 'Apri con il visore del sistema';

  @override
  String get artifactSourceOnly =>
      'Su questo sistema l\'app mostra il sorgente dell\'artefatto; l\'anteprima isolata arriva con la versione per computer.';

  @override
  String get statusReconnecting => 'mi ricollego…';

  @override
  String get openFailed => 'Non si è aperto: controlla la connessione.';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get untitled => 'Conversazione';

  @override
  String requestFrom(String agent) {
    return '$agent ti chiede';
  }

  @override
  String requestCritical(String agent) {
    return 'Davvero pericolosa, da $agent';
  }

  @override
  String get no => 'No';

  @override
  String get yes => 'Sì';

  @override
  String get requestLook => 'Guardala';

  @override
  String get criticalTitle => 'Una richiesta davvero pericolosa';

  @override
  String criticalBody(String agent) {
    return '$agent chiede di fare una cosa che non si può annullare o che tocca ciò che ti protegge. Leggila tutta prima di rispondere.';
  }

  @override
  String requestClosed(String via) {
    return 'Già risposta ($via).';
  }

  @override
  String get criticalNo => 'No, non farlo';

  @override
  String get criticalYes => 'Sì, fallo';

  @override
  String get criticalConfirmTitle => 'Sei sicuro?';

  @override
  String get criticalConfirmBody => 'Non si torna indietro.';

  @override
  String get criticalSystem => 'File di sistema';

  @override
  String get criticalDelete => 'Cancellazione definitiva';

  @override
  String get criticalSecret => 'Un segreto che esce';

  @override
  String get criticalPayment => 'Un pagamento vero';

  @override
  String get criticalProtections => 'Le protezioni di RedGiant';

  @override
  String questionFrom(String agent) {
    return '$agent ti fa una domanda';
  }

  @override
  String get answer => 'Rispondi';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get taskRunning => 'in corso';

  @override
  String get taskOpen => 'aperto';

  @override
  String get taskVerified => 'verificato';

  @override
  String get taskNotTestable => 'non verificabile';

  @override
  String get taskAbandoned => 'abbandonato';

  @override
  String taskSteps(int done, int total) {
    return '$done passi su $total';
  }

  @override
  String get verifiers => 'Verificatore';

  @override
  String get noVerifier => 'Nessun verificatore eseguito finora.';

  @override
  String get openConversation => 'Apri la conversazione';

  @override
  String get reachPinned => 'https, solo con il suo certificato (CA locale)';

  @override
  String get reachPublic => 'https pubblico (proxy, Tailscale)';

  @override
  String get reachLoopback => 'questo computer';

  @override
  String get reachChannel => 'canale di configurazione cifrato';

  @override
  String get noServers => 'Ancora nessun RedGiant.';

  @override
  String get useServer => 'Usa';

  @override
  String pinnedKey(String fingerprint) {
    return 'Chiave: $fingerprint';
  }

  @override
  String get renameServer => 'Nome di questo RedGiant';

  @override
  String get save => 'Salva';

  @override
  String get rename => 'Rinomina';

  @override
  String get forgetServer => 'Scollegare questo RedGiant?';

  @override
  String forgetServerBody(String name) {
    return 'L\'app dimentica $name e il suo token del dispositivo. Per tornare serve di nuovo la password.';
  }

  @override
  String errKeyChanged(String fingerprint) {
    return 'PERICOLO: questo RedGiant ha risposto con un\'altra chiave ($fingerprint). Al suo posto potrebbe esserci un altro computer: non è stato mandato niente.';
  }

  @override
  String get errCertificate =>
      'Il certificato non è di questo RedGiant: l\'app non è andata avanti.';

  @override
  String get errBusy => 'Un altro dispositivo sta configurando questo RedGiant: uno alla volta.';

  @override
  String get errSignInAgain => 'Entra di nuovo con la password.';

  @override
  String get addServerFirst => 'Collega un RedGiant';

  @override
  String get addServer => 'Aggiungi un altro RedGiant';

  @override
  String get foundOnNetwork => 'Trovati in questa rete';

  @override
  String get pairingNote =>
      'La password serve una volta: l\'app tiene solo un token del dispositivo, revocabile da Impostazioni › Dispositivi.';
}
