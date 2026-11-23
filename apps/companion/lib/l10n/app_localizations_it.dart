// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Rasgeth';

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
  String get noServer => 'Nessun Rasgeth collegato';

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
  String get accentLabel => 'Colore d\'accento';

  @override
  String get accentHint =>
      'Il colore di pulsanti, link e della barra dei titoli, in entrambi i temi.';

  @override
  String get accentRed => 'Rosso Rasgeth';

  @override
  String get accentAmber => 'Ambra';

  @override
  String get accentGreen => 'Verde';

  @override
  String get accentBlue => 'Azzurro';

  @override
  String get accentViolet => 'Viola';

  @override
  String get newText => 'Nuovo testo';

  @override
  String get languageLabel => 'Lingua';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get reduceMotion => 'Riduci movimento';

  @override
  String get reduceMotionHint => 'Le mascotte restano ferme; lo stato si riconosce dal segno.';

  @override
  String get sectionServer => 'Rasgeth';

  @override
  String get serverAddress => 'Indirizzo';

  @override
  String get serverAddressHint => 'rasgeth.local, https://…, 10.42.0.1';

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
  String get errUnreachable => 'Rasgeth non risponde a questo indirizzo.';

  @override
  String get errWrong => 'Password o codice sbagliati.';

  @override
  String get errCodeNeeded => 'Serve anche il codice dell\'app di autenticazione.';

  @override
  String get errTooMany => 'Troppi tentativi: riprova tra qualche minuto.';

  @override
  String get errNoPassword => 'Questo Rasgeth non ha ancora una password: completa il primo avvio.';

  @override
  String get errServerTooOld => 'Questo Rasgeth è troppo vecchio per l\'app: aggiornalo.';

  @override
  String get errServerTooNew => 'Questa app è troppo vecchia per questo Rasgeth: aggiornala.';

  @override
  String errGeneric(String message) {
    return 'Non è andata: $message';
  }

  @override
  String get appVersion => 'Versione dell\'app';

  @override
  String get attachmentOnly => '(allegati)';

  @override
  String get sendFailed => 'Il messaggio non è partito: riprova.';

  @override
  String attachmentTooBig(String name) {
    return '$name è troppo grande da inviare (oltre 25 MB).';
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
  String get criticalProtections => 'Le protezioni di Rasgeth';

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
  String get noServers => 'Ancora nessun Rasgeth.';

  @override
  String get useServer => 'Usa';

  @override
  String pinnedKey(String fingerprint) {
    return 'Chiave: $fingerprint';
  }

  @override
  String get renameServer => 'Nome di questo Rasgeth';

  @override
  String get save => 'Salva';

  @override
  String get rename => 'Rinomina';

  @override
  String get forgetServer => 'Scollegare questo Rasgeth?';

  @override
  String forgetServerBody(String name) {
    return 'L\'app dimentica $name e il suo token del dispositivo. Per tornare serve di nuovo la password.';
  }

  @override
  String errKeyChanged(String fingerprint) {
    return 'PERICOLO: questo Rasgeth ha risposto con un\'altra chiave ($fingerprint). Al suo posto potrebbe esserci un altro computer: non è stato mandato niente.';
  }

  @override
  String get errCertificate =>
      'Il certificato non è di questo Rasgeth: l\'app non è andata avanti.';

  @override
  String get errBusy => 'Un altro dispositivo sta configurando questo Rasgeth: uno alla volta.';

  @override
  String get errSignInAgain => 'Entra di nuovo con la password.';

  @override
  String get addServerFirst => 'Collega un Rasgeth';

  @override
  String get addServer => 'Aggiungi un altro Rasgeth';

  @override
  String get foundOnNetwork => 'Trovati in questa rete';

  @override
  String get pairingNote =>
      'La password serve una volta: l\'app tiene solo un token del dispositivo, revocabile da Impostazioni › Dispositivi.';

  @override
  String get allSettings => 'Tutte le impostazioni';

  @override
  String get allSettingsHint =>
      'La pagina Impostazioni completa di Rasgeth, dentro l\'app, con l\'accesso di questo dispositivo.';

  @override
  String get allSettingsBrowser => 'Apre la pagina di Rasgeth nel browser: lì entri come sempre.';

  @override
  String get allSettingsNoHttps =>
      'Le impostazioni complete vogliono l\'HTTPS: da qui la pagina viaggerebbe in chiaro. Accendi l\'HTTPS nella rete di casa dal computer.';

  @override
  String get close => 'Chiudi';

  @override
  String get copy => 'Copia';

  @override
  String get connectExisting => 'Collega un Rasgeth già acceso';

  @override
  String get firstStepsTitle => 'Ancora nessun Rasgeth';

  @override
  String get firstStepsLead =>
      'Configurane uno nuovo da qui (al primo avvio Rasgeth OS apre una sua rete Wi-Fi), oppure collega quello che usi già.';

  @override
  String get setupNew => 'Configura un Rasgeth nuovo';

  @override
  String get setupNewHint =>
      'Una macchina con Rasgeth OS accesa per la prima volta: l\'app entra nella sua rete temporanea e fa tutto il primo avvio.';

  @override
  String get defaultModel => 'Modello predefinito';

  @override
  String get setModel => 'Il modello che usano gli agenti quando nessuno ne ha scelto un altro';

  @override
  String get modelNone => 'Ancora nessuno: collega un modo di pensare';

  @override
  String devLastUsed(String when) {
    return 'ultimo uso $when';
  }

  @override
  String get devNeverUsed => 'mai usato';

  @override
  String get devNone => 'Nessun dispositivo con un suo accesso.';

  @override
  String get devRevoke => 'Scollega';

  @override
  String get devRevokeTitle => 'Scollegare questo dispositivo?';

  @override
  String devRevokeBody(String name) {
    return '«$name» viene scollegato subito e per tornare gli serve la password.';
  }

  @override
  String get devThis => 'questo dispositivo';

  @override
  String get fsTitle => 'Primo avvio';

  @override
  String get fsLeave => 'Esci';

  @override
  String get fsLeaveTitle => 'Uscire dal primo avvio?';

  @override
  String get fsLeaveBody =>
      'Quello che è fatto resta; puoi tornare qui, o finire dal browser, finché la rete temporanea è aperta (30 minuti da quando hai acceso Rasgeth).';

  @override
  String get fsIntroTitle => 'Configura un Rasgeth nuovo';

  @override
  String get fsIntroLead =>
      'Accendi il tuo Rasgeth: per 30 minuti apre la rete Wi-Fi Rasgeth-Setup-XXXX. L\'app ci entra, tu crei l\'accesso e scegli la rete di casa, poi Rasgeth passa lì e l\'app lo ritrova.';

  @override
  String get fsIntroSafe =>
      'Tutto quello che scrivi viaggia cifrato, con la chiave di Rasgeth controllata dall\'app: chi sta sulla rete temporanea non lo legge.';

  @override
  String get fsSeen => 'Reti temporanee qui intorno';

  @override
  String get fsNoScan =>
      'Il sistema non mostra le reti qui intorno: scrivi i quattro caratteri dopo Rasgeth-Setup- (li vedi nella lista Wi-Fi del computer).';

  @override
  String get fsLetters => 'Gli ultimi quattro caratteri';

  @override
  String get fsScanAgain => 'Cerca di nuovo';

  @override
  String get fsJoin => 'Collegati alla rete';

  @override
  String get fsByHand => 'Mi collego a mano';

  @override
  String get fsJoining => 'Mi collego alla rete temporanea…';

  @override
  String get fsJoiningSheet => 'Scegli Rasgeth-Setup nella finestra che mostra il sistema.';

  @override
  String get fsConnecting => 'Cerco Rasgeth sulla rete…';

  @override
  String get fsManualTitle => 'Collegati a mano';

  @override
  String fsManualLead(String ssid, String password) {
    return 'Collegati alla rete $ssid (password $password) dalle impostazioni Wi-Fi, poi torna qui.';
  }

  @override
  String get fsNetworkName => 'Rete';

  @override
  String get fsNetworkPassword => 'Password';

  @override
  String get fsWhereAndroid => 'Impostazioni › Rete › Wi-Fi: tocca Rasgeth-Setup-…';

  @override
  String get fsWhereIos => 'Impostazioni › Wi-Fi: tocca Rasgeth-Setup-…';

  @override
  String get fsWhereMac => 'Il menu Wi-Fi in alto a destra dello schermo: scegli Rasgeth-Setup-…';

  @override
  String get fsWhereWindows => 'L\'icona Wi-Fi in basso a destra: scegli Rasgeth-Setup-…';

  @override
  String get fsWhereOther => 'La lista Wi-Fi del sistema: scegli Rasgeth-Setup-…';

  @override
  String get fsManualNoInternet =>
      'Il sistema può dire che la rete non ha internet: è giusto, resta collegato.';

  @override
  String get fsJoinedContinue => 'Fatto, continua';

  @override
  String get fsErrNotFound =>
      'Rasgeth non risponde: sei sulla rete Rasgeth-Setup? Resta aperta per 30 minuti da quando accendi Rasgeth.';

  @override
  String get fsErrNotHere =>
      'Questo Rasgeth non lascia creare un accesso nuovo da qui: finisci dalla sua pagina.';

  @override
  String get fsErrCancelled => 'La rete non è stata collegata. Riprova, oppure collegati a mano.';

  @override
  String get fsErrDenied =>
      'All\'app serve il permesso per i dispositivi nelle vicinanze per entrare nella rete: concedilo, oppure collegati a mano.';

  @override
  String get fsErrJoinFailed =>
      'Il sistema non è riuscito a collegarsi alla rete: collegati a mano.';

  @override
  String get fsErrNoName => 'Scegli la rete, oppure scrivi i suoi ultimi quattro caratteri.';

  @override
  String get fsAccessTitle => 'Crea l\'accesso';

  @override
  String get fsAccessLead =>
      'La password che apre Rasgeth da ogni dispositivo. Tienila: è anche quella che apre il suo portachiavi.';

  @override
  String get fsPassword => 'Password';

  @override
  String get fsPasswordAgain => 'Di nuovo la password';

  @override
  String get fsPasswordNeeded => 'Serve una password.';

  @override
  String get fsPasswordWeak => 'Almeno 10 caratteri, non tutti uguali.';

  @override
  String get fsPasswordDiffer => 'Le due password sono diverse.';

  @override
  String get fsAccessSafe =>
      'Arriva cifrata a Rasgeth e resta solo lì; questo dispositivo riceve un suo accesso, che puoi scollegare da Impostazioni › Dispositivi.';

  @override
  String get fsAccessGo => 'Crea l\'accesso';

  @override
  String get fsSignInTitle => 'Entra';

  @override
  String get fsSignInLead => 'Questo Rasgeth ha già la sua password: scrivila per continuare.';

  @override
  String get fsMaintenanceTitle => 'Rasgeth ha perso la sua rete';

  @override
  String get fsMaintenanceLead =>
      'Ha aperto la rete temporanea per riceverne una nuova. Serve la password del proprietario, e non cambia nient\'altro.';

  @override
  String get fsHomeTitle => 'La rete di casa';

  @override
  String get fsHomeLead =>
      'Quale rete deve usare Rasgeth a casa? Sono quelle che ha visto intorno a sé.';

  @override
  String get fsHomeNone =>
      'Non ha visto reti intorno: usa il cavo, oppure scrivi il nome di una rete nascosta.';

  @override
  String get fsHomeUnusable => 'Rasgeth non può collegarsi a questo tipo di rete';

  @override
  String get fsHomeHidden => 'Una rete nascosta';

  @override
  String get fsHomeHiddenName => 'Nome della rete';

  @override
  String fsHomePassword(String name) {
    return 'Password di «$name»';
  }

  @override
  String get fsHomeSafe => 'La password del Wi-Fi resta solo in Rasgeth.';

  @override
  String fsHomeJoin(String name) {
    return 'Usa «$name»';
  }

  @override
  String get fsHomeCable => 'Uso il cavo';

  @override
  String fsHomeWaitWifi(String name) {
    return 'Rasgeth si sta collegando a «$name»…';
  }

  @override
  String get fsHomeWaitCable => 'Rasgeth passa alla rete di casa…';

  @override
  String get fsHomeWaitSub =>
      'Il dispositivo torna sulla sua rete e ritrova Rasgeth lì (fino a due minuti). Se non funziona, Rasgeth riapre la rete temporanea e dice perché.';

  @override
  String get fsLostTitle => 'Non trovo Rasgeth';

  @override
  String fsLostLead(String ssid) {
    return 'Né a casa né su $ssid. Controlla che questo dispositivo sia tornato sulla rete di casa, poi cerca di nuovo; oppure collegati a mano alla rete temporanea per vedere cosa è successo.';
  }

  @override
  String get fsLookAgain => 'Cerca di nuovo';

  @override
  String get fsLanguageTitle => 'Le lingue';

  @override
  String get fsLanguageLead =>
      'La lingua dell\'app e della pagina, e quella in cui ti parlano gli agenti.';

  @override
  String get fsLanguageUi => 'App e pagina';

  @override
  String get fsLanguageAgents => 'Gli agenti parlano';

  @override
  String get fsNext => 'Avanti';

  @override
  String get fsLater => 'Più tardi';

  @override
  String get fsBrainTitle => 'Come deve pensare Rasgeth?';

  @override
  String get fsBrainLead =>
      'Un abbonamento che hai già, oppure la chiave di un provider. Uno qualsiasi, o nessuno per adesso.';

  @override
  String get fsClaude => 'Claude Pro o Max';

  @override
  String get fsClaudeText => 'La pagina di Anthropic nel browser, poi il codice che mostra';

  @override
  String get fsClaudeOpen => 'Apri la pagina di Anthropic';

  @override
  String get fsClaudeCode => 'Il codice che mostra la pagina';

  @override
  String get fsChatgpt => 'ChatGPT Plus o Pro';

  @override
  String get fsChatgptText => 'Un codice da scrivere sulla pagina di OpenAI';

  @override
  String get fsChatgptOpen => 'Apri la pagina di OpenAI';

  @override
  String get fsChatgptCode =>
      'Scrivi questo codice sulla pagina; l\'app se ne accorge quando hai fatto.';

  @override
  String get fsChatgptOpenAgain => 'Riapri la pagina';

  @override
  String get fsKey => 'La chiave di un provider';

  @override
  String get fsKeyText => 'Anthropic, OpenAI, Gemini, OpenRouter…: si paga a consumo';

  @override
  String fsKeyOf(String name) {
    return 'Chiave di $name';
  }

  @override
  String fsKeySaved(String name) {
    return '$name: la chiave funziona.';
  }

  @override
  String get fsTerms =>
      'Ho letto le condizioni del provider: l\'abbonamento lo uso io, sul mio Rasgeth.';

  @override
  String get fsBrainLater =>
      'I modelli su questa macchina, un tuo server e il resto sono in Impostazioni › Modelli e abbonamenti, quando vuoi.';

  @override
  String get fsNamesTitle => 'I nomi';

  @override
  String get fsNamesLead =>
      'Chi guida il tuo Rasgeth, e chi parla per lui nelle chat. Puoi cambiarli dopo.';

  @override
  String get fsGodName => 'Il capo';

  @override
  String get fsGodHelp => 'Organizza il lavoro e lo affida agli agenti';

  @override
  String get fsDemigodName => 'Il portavoce';

  @override
  String get fsDemigodHelp => 'Ti risponde su Telegram e nelle altre chat';

  @override
  String get fsFinish => 'Fine';

  @override
  String get fsFinishing => 'Completo il primo avvio…';

  @override
  String get fsDoneTitle => 'Rasgeth è pronto';

  @override
  String get fsDoneLead =>
      'La rete temporanea è chiusa: Rasgeth è sulla tua rete di casa, e questo dispositivo è collegato.';

  @override
  String get fsDoneMaintenance =>
      'Rasgeth è di nuovo sulla sua nuova rete, e questo dispositivo è collegato.';

  @override
  String get fsDoneMore =>
      'Il resto del primo avvio (copie, chat, accesso da fuori…) è nella pagina, quando vuoi: «Impostazioni di Rasgeth» › «Tutte le impostazioni».';

  @override
  String get fsDoneGo => 'Apri la squadra';

  @override
  String get homeErrConnectFailed =>
      'La rete ha rifiutato il collegamento: controlla la password e riprova.';

  @override
  String get homeErrNotFound => 'Quella rete adesso non è a portata.';

  @override
  String get homeErrBadPassword => 'Una password Wi-Fi ha da 8 a 63 caratteri.';

  @override
  String get homeErrBadSsid => 'Il nome di una rete ha da 1 a 32 caratteri.';

  @override
  String get homeErrBusy => 'Rasgeth si sta già collegando a una rete: aspetta un momento.';

  @override
  String get homeErrWifiOff => 'Il Wi-Fi non è attivo su Rasgeth.';

  @override
  String get homeErrNoCable =>
      'Nessun cavo con un indirizzo: collegalo al router, oppure scegli una rete Wi-Fi.';

  @override
  String get homeErrFailed => 'Non ha funzionato. Riprova tra un momento.';

  @override
  String get outsideNone =>
      'Solo dalla rete di casa. Tailscale, Cloudflare o un tuo nome: in «Accesso da fuori casa».';

  @override
  String get outsideOwn => 'Il tuo modo di arrivarci';

  @override
  String get outsideOwnName => 'Un tuo nome (Caddy)';

  @override
  String get pushOff => 'Non ancora attive per questo dispositivo: attivale in Tu, Notifiche.';

  @override
  String pushOn(String target) {
    return 'Attive, attraverso $target';
  }

  @override
  String get pushBlocked =>
      'Adesso non si può inviare niente (il portachiavi è chiuso, o il ripetitore è spento).';

  @override
  String get pushTest => 'Invia una prova';

  @override
  String get pushTestSent => 'Notifica di prova inviata.';

  @override
  String pushTestFailed(String why) {
    return 'La prova non è partita: $why';
  }

  @override
  String get sectionUpdates => 'AGGIORNAMENTI';

  @override
  String get sectionDevices => 'DISPOSITIVI COLLEGATI';

  @override
  String get sectionNotifications => 'NOTIFICHE DI QUESTO DISPOSITIVO';

  @override
  String get sectionModel => 'MODELLO E VOCE';

  @override
  String get sectionOutside => 'DA FUORI CASA';

  @override
  String serverSettingsTitle(String name) {
    return 'Impostazioni di $name';
  }

  @override
  String get serverSettingsSub => 'Nome, aggiornamenti, dispositivi, modello, voce';

  @override
  String versionOf(String version) {
    return 'versione $version';
  }

  @override
  String get updLatest => 'Aggiornato';

  @override
  String updAvailable(String version) {
    return 'È disponibile la versione $version';
  }

  @override
  String updApplying(String version) {
    return 'Aggiornamento a $version…';
  }

  @override
  String updInstalled(String version) {
    return 'installata $version';
  }

  @override
  String updChecked(String when) {
    return 'controllato $when';
  }

  @override
  String get updLook => 'Cerca aggiornamenti';

  @override
  String get updLooking => 'Cerco…';

  @override
  String get updNow => 'Aggiorna';

  @override
  String get updNowTitle => 'Aggiornare Rasgeth?';

  @override
  String updNowBody(String version) {
    return 'Rasgeth scarica la $version e poi si riavvia: per un minuto o due non risponde. Ti mostro ogni passo e mi ricollego da solo appena Rasgeth torna.';
  }

  @override
  String get updStarted => 'L\'aggiornamento è partito.';

  @override
  String get updBreaking =>
      'Questa versione vuole un\'installazione pulita (prima una copia): dal computer.';

  @override
  String get updDockerHint =>
      'In Docker la versione nuova arriva con questi comandi, sul computer che lo fa girare:';

  @override
  String get updReboot => 'Un aggiornamento di sicurezza chiede un riavvio.';

  @override
  String updBytes(String done, String total) {
    return '$done MB di $total MB';
  }

  @override
  String updSpeed(String mb) {
    return '$mb MB/s';
  }

  @override
  String updEtaMin(String n) {
    return 'mancano $n min';
  }

  @override
  String updEtaSec(String n) {
    return 'mancano $n s';
  }

  @override
  String get updStepCheck => 'Controllo della versione';

  @override
  String get updStepDownload => 'Scaricamento';

  @override
  String get updStepFiles => 'I file di sistema';

  @override
  String get updStepInstall => 'Installazione';

  @override
  String get updStepRestart => 'Riavvio';

  @override
  String get updStepWait => 'Attesa che Rasgeth risponda';

  @override
  String get updStepRollback => 'Ritorno alla versione di prima';

  @override
  String get updStepScan => 'Confronto dei file';

  @override
  String get updStepBuild => 'Preparazione';

  @override
  String get updStepFailed => 'Si è fermato';

  @override
  String get voice => 'Voce';

  @override
  String voiceHear(String what) {
    return 'Ascolta con: $what';
  }

  @override
  String voiceRead(String what) {
    return 'Legge con: $what';
  }

  @override
  String get voiceNone => 'niente ancora';

  @override
  String get voiceBrowser => 'la voce del dispositivo';

  @override
  String get teamAll => 'Tutti';

  @override
  String get teamFavourites => 'Preferiti';

  @override
  String get teamFilterLabel => 'Mostra';

  @override
  String get teamNoFavourites => 'Nessun preferito: tieni premuto un agente per aggiungerlo.';

  @override
  String get teamNoneInProject => 'Nessun agente ha lavorato in questo progetto.';

  @override
  String get favouriteMark => 'preferito';

  @override
  String get agentDoing => 'Cosa sta facendo';

  @override
  String get agentIdleNow => 'Ora è fermo.';

  @override
  String get agentWaitsYou => 'Aspetta una tua risposta in «Da te».';

  @override
  String agentTask(String title) {
    return 'Compito: $title';
  }

  @override
  String agentLastAt(String when) {
    return 'Ultima attività: $when';
  }

  @override
  String get agentStop => 'Ferma';

  @override
  String agentStopped(String name) {
    return 'Interrotto: $name';
  }

  @override
  String get agentStopFailed => 'Non si è fermato: controlla la connessione.';

  @override
  String get agentOpenTask => 'Apri il compito';

  @override
  String get agentOpenChat => 'Apri la conversazione';

  @override
  String get favouriteAdd => 'Aggiungi ai preferiti';

  @override
  String get favouriteRemove => 'Togli dai preferiti';

  @override
  String inboxPosition(String n, String total) {
    return '$n di $total';
  }

  @override
  String get inboxSwipeHint => 'Scorri a destra per dire sì, a sinistra per dire no.';

  @override
  String get inboxCriticalHint => 'Davvero pericolosa: non si scorre, si guarda a schermo intero.';

  @override
  String inboxSaidYes(String name) {
    return 'Sì a $name';
  }

  @override
  String inboxSaidNo(String name) {
    return 'No a $name';
  }

  @override
  String get inboxNext => 'Dopo';

  @override
  String get modelWay => 'Da dove passa';

  @override
  String get modelWaySubscription => 'Abbonamento';

  @override
  String get modelWayKey => 'Chiave API';

  @override
  String modelWayNode(String node) {
    return 'Tramite $node';
  }

  @override
  String get modelWayLocal => 'Locale';

  @override
  String get modelWayOr => 'o';

  @override
  String get modelHintSubscription => 'Nei limiti del tuo piano: non paghi a consumo.';

  @override
  String get modelHintKey => 'A consumo con la tua chiave API: conta per il tetto di spesa.';

  @override
  String modelHintNode(String node) {
    return 'Passa dal computer $node.';
  }

  @override
  String get modelHintLocal => 'Gira su un computer tuo: niente costi a consumo.';

  @override
  String get modelHintOther => 'Tramite un fornitore collegato.';

  @override
  String get stateActive => 'attivo';

  @override
  String get teamAgents => 'Agenti';

  @override
  String get teamNewAgent => 'Nuovo agente';

  @override
  String get teamNoAgents => 'Nessun altro agente: creane uno con «Nuovo agente».';

  @override
  String get teamChatLead => 'Le tue conversazioni di ogni giorno';

  @override
  String get agentJustAnswered => 'Ti ha appena risposto.';

  @override
  String get agentBlockedNow => 'È bloccato: apri la conversazione per vedere perché.';

  @override
  String get effortLow => 'Basso';

  @override
  String get effortMedium => 'Medio';

  @override
  String get effortHigh => 'Alto';

  @override
  String get effortMax => 'Massimo';

  @override
  String get effortTitle => 'Impegno nel ragionare';

  @override
  String get agentModel => 'Modello';

  @override
  String get agentModelInherit => 'Lo stesso di chi sta sopra';

  @override
  String get agentModelDefault => 'Il modello predefinito';

  @override
  String get agentModelSaved => 'Salvato: i suoi prossimi messaggi lo usano.';

  @override
  String get agentModelFailed => 'Non sono riuscito a cambiare il modello.';

  @override
  String agentModelTitle(String name) {
    return 'Modello di $name';
  }

  @override
  String modelNow(String model) {
    return 'Ora: $model';
  }

  @override
  String modelUse(String model) {
    return 'Usa $model';
  }

  @override
  String modelInheritOf(String label, String model) {
    return '$label ($model)';
  }

  @override
  String get noModels => 'Nessun modello collegato: collegane uno nelle impostazioni.';

  @override
  String get more => 'Altri comandi';

  @override
  String get moreChanged => 'Altri comandi (qualcosa non è come all\'inizio)';

  @override
  String moreMode(String mode) {
    return 'Modalità: $mode';
  }

  @override
  String moreModeHint(String name) {
    return 'Vale per tutte le conversazioni di $name.';
  }

  @override
  String moreModel(String model) {
    return 'Modello: $model';
  }

  @override
  String get moreModelHint =>
      'Il modello di questa conversazione (modelli degli agenti: tieni premuto l\'agente nella Squadra)';

  @override
  String get moreModelBusy => 'Si cambia quando ha finito di lavorare.';

  @override
  String get moreOpen => 'aperto';

  @override
  String get moreClosed => 'chiuso';

  @override
  String get moreSectionHow => 'Come lavora';

  @override
  String get moreSectionMore => 'Altro';

  @override
  String get mode_manual => 'Chiedi';

  @override
  String get mode_auto => 'Automatico';

  @override
  String get mode_plan => 'Piano';

  @override
  String get mode_readonly => 'Sola lettura';

  @override
  String get modeFailed => 'Non sono riuscito a cambiare la modalità.';

  @override
  String get agentsModel => 'Modello dell\'agente';

  @override
  String get modelPick => 'Scegli un modello';

  @override
  String get sessionModelTitle => 'Modello di questa conversazione';

  @override
  String get sessionModelBusy => 'Sta lavorando: il modello si cambia quando ha finito.';

  @override
  String get asideChip => 'Intanto';

  @override
  String get asideHint =>
      'Una domanda al volo, anche mentre l\'agente lavora: conosce la conversazione, ma niente entra nella chat';

  @override
  String get asideTitle => 'Intanto';

  @override
  String get asideSub => 'Fuori dalla conversazione';

  @override
  String get asideEmpty =>
      'Chiedi quello che vuoi su questa conversazione. La risposta resta qui: non entra nella chat né nella memoria dell\'agente.';

  @override
  String get asidePlaceholder => 'Una domanda al volo…';

  @override
  String get asidePlaceholderBusy => 'Una domanda al volo, mentre l\'agente lavora…';

  @override
  String get asideAsk => 'Chiedi';

  @override
  String get asideThinking => 'Ci penso…';

  @override
  String asideFailed(String why) {
    return 'Nessuna risposta: $why';
  }

  @override
  String get asideToChat => 'Porta nella chat';

  @override
  String get asideBrought => 'Portato nella chat.';

  @override
  String get compactNow => 'Riassumi';

  @override
  String get compactNowHint =>
      'Riassumi adesso la parte più vecchia di questa conversazione: l\'agente tiene i giri recenti e può comunque rileggere tutto';

  @override
  String get compactNowAsk =>
      'Riassumo la conversazione adesso. Qualcosa da tenere in particolare? (facoltativo)';

  @override
  String get compactNowYes => 'Riassumi';

  @override
  String get compactNowSent => 'Sto riassumendo la conversazione.';

  @override
  String get roomFromChat => 'Aggiungi un agente';

  @override
  String get roomFromChatHint =>
      'Trasforma questa conversazione in una chat di gruppo: aggiungi altri agenti, Inspector compresi';

  @override
  String get roomPickTitle => 'Chi aggiungi alla chat di gruppo?';

  @override
  String roomAdded(String name) {
    return '$name è nella chat di gruppo: la trovi nella pagina, tra le conversazioni.';
  }

  @override
  String get roomFailed => 'Non sono riuscito a fare la chat di gruppo.';

  @override
  String get whileRunning => 'Mentre lavora non si può.';

  @override
  String get newAgentTitle => 'Nuovo agente';

  @override
  String newAgentStep(int n, int total) {
    return 'Passo $n di $total';
  }

  @override
  String get newAgentKindQ => 'Che agente ti serve?';

  @override
  String get newAgentKindAgent => 'Agente di un progetto';

  @override
  String get newAgentKindAgentText =>
      'Lavora in un progetto sotto il suo orchestratore: scrive codice, rivede, cerca, prova.';

  @override
  String get newAgentKindOrch => 'Orchestratore di un progetto';

  @override
  String get newAgentKindOrchText =>
      'Guida un progetto: divide il lavoro e lo passa ai suoi agenti. Uno per progetto.';

  @override
  String get newAgentKindAsst => 'Assistente personale';

  @override
  String get newAgentKindAsstText => 'Ti aiuta fuori dai progetti: posta, agenda, ricerche, conti.';

  @override
  String get newAgentProjectQ => 'In quale progetto?';

  @override
  String get newAgentNoOrch => 'Non ha ancora un orchestratore: creane prima uno.';

  @override
  String get newAgentHasOrch => 'Ha già un orchestratore.';

  @override
  String get newAgentNoProjects => 'Nessun progetto: crealo dalla pagina.';

  @override
  String get newAgentNameQ => 'Come si chiama e che lavoro fa?';

  @override
  String get newAgentName => 'Nome';

  @override
  String get newAgentRole => 'Il suo lavoro, in parole tue';

  @override
  String get newAgentRoleHint => 'Per esempio: scrive i test e controlla che passino';

  @override
  String get newAgentMascotPreview => 'La sua mascotte';

  @override
  String get newAgentMascotLater =>
      'La faccia la sceglie Rasgeth dal nome; dopo averlo creato la puoi cambiare.';

  @override
  String get newAgentModelQ => 'Che modello usa? (facoltativo)';

  @override
  String get newAgentModelLead => 'Di base usa quello di chi sta sopra di lui.';

  @override
  String get newAgentModelGod => 'Lo stesso di God';

  @override
  String get newAgentToolsQ => 'Strumenti da spegnere (facoltativo)';

  @override
  String get newAgentToolsLead =>
      'Di base ha tutti gli strumenti. Quelli essenziali non si spengono.';

  @override
  String newAgentToolsOff(int n) {
    return '$n spenti';
  }

  @override
  String get newAgentReview => 'Ecco il nuovo agente';

  @override
  String get newAgentBack => 'Indietro';

  @override
  String get newAgentNext => 'Avanti';

  @override
  String get newAgentCreate => 'Crea';

  @override
  String get newAgentCreating => 'Lo creo…';

  @override
  String newAgentFailed(String why) {
    return 'Non sono riuscito a crearlo: $why';
  }

  @override
  String newAgentMade(String name) {
    return '$name è nella squadra.';
  }

  @override
  String newAgentOpen(String name) {
    return 'Apri la conversazione con $name';
  }

  @override
  String get newAgentNeedsGod => 'Serve God per creare agenti: completa prima il primo avvio.';

  @override
  String get mascotChange => 'Cambia mascotte';

  @override
  String mascotChangeAsk(String name) {
    return 'Dare a $name una faccia nuova? Quella di adesso non torna più.';
  }

  @override
  String get mascotChangeYes => 'Faccia nuova';

  @override
  String mascotChanged(String name) {
    return 'Nuova faccia per $name.';
  }

  @override
  String get reviewKind => 'Tipo';

  @override
  String get reviewProject => 'Progetto';

  @override
  String get reviewTools => 'Strumenti';

  @override
  String get reviewAllTools => 'Tutti';

  @override
  String get agentInstructions => 'Istruzioni';

  @override
  String agentInstructionsOf(String name) {
    return 'Istruzioni di $name';
  }

  @override
  String get chatInstructions => 'Istruzioni della Chat';

  @override
  String get agentInstructionsRow => 'Il suo system prompt: leggilo e cambialo';

  @override
  String get promptDefault => 'Istruzioni predefinite';

  @override
  String get promptOwn => 'Istruzioni tue';

  @override
  String get promptNewChats =>
      'Le istruzioni nuove valgono per le conversazioni nuove: quelle già aperte tengono le loro. I nomi degli agenti restano giusti anche se li cambi dopo.';

  @override
  String get promptSave => 'Salva';

  @override
  String get promptSaved => 'Salvato.';

  @override
  String promptSaveFailed(String why) {
    return 'Non sono riuscito a salvarle: $why';
  }

  @override
  String get promptReset => 'Ripristina le predefinite';

  @override
  String get promptResetConfirm => 'Tornare alle istruzioni predefinite? Il tuo testo andrà perso.';

  @override
  String get promptUndo => 'Annulla le modifiche';

  @override
  String get refineOpen => 'Migliora le istruzioni';

  @override
  String get refineLead =>
      'Un modello le rilegge e propone una versione più chiara. Vedi cosa cambia prima di usarla; non si salva niente finché non salvi tu.';

  @override
  String get refineWish => 'Cosa vuoi cambiare? (puoi lasciarlo vuoto)';

  @override
  String get refineWishPlaceholder =>
      'Per esempio: più conciso; rispondi sempre con elenchi; specializzalo in fatture. Vuoto: un miglioramento generale.';

  @override
  String refineEstimate(String what) {
    return 'Stima: $what.';
  }

  @override
  String get refineNoEstimate => 'Nessuna stima: controlla che il modello sia ancora collegato.';

  @override
  String refineSpent(String what) {
    return 'Speso: $what.';
  }

  @override
  String refineCostLine(String tokens, String cost) {
    return 'circa $tokens token, $cost';
  }

  @override
  String get refineFree => 'nessuna spesa in denaro (modello locale o abbonamento)';

  @override
  String refineCost(String usd) {
    return 'circa $usd';
  }

  @override
  String get refineCostTiny => 'meno di un centesimo';

  @override
  String get refineGo => 'Migliora';

  @override
  String get refineWorking => 'Sto riscrivendo le istruzioni...';

  @override
  String get refineChanges => 'Cosa è cambiato';

  @override
  String get refineUse => 'Usa questa versione';

  @override
  String get refineRetry => 'Riprova';

  @override
  String get refineUsed => 'La versione nuova è nel campo: salva per tenerla.';

  @override
  String get refineSame => 'Il modello le ha lasciate com\'erano.';

  @override
  String get refineErr_budget => 'Il budget è finito: alzalo in Impostazioni, Budget.';

  @override
  String get refineErr_no_model =>
      'Nessun modello collegato: collegane uno in Impostazioni, Modelli.';

  @override
  String get refineErr_no_answer =>
      'Il modello non ha dato un testo utilizzabile. Riprova o scegli un altro modello.';

  @override
  String get refineErr_removed_parts =>
      'Il modello ha tolto parti che devono restare (strumenti, nomi). Non è cambiato niente: riprova o scegli un altro modello.';

  @override
  String get attachmentNotSent => 'non inviato';

  @override
  String get notificationsTitle => 'Notifiche';

  @override
  String get notificationsSub => 'Come questo dispositivo sa da Rasgeth quando l\'app è chiusa';

  @override
  String get voiceTitle => 'Voce';

  @override
  String get voiceSub => 'Chi legge le risposte ad alta voce, e quanto forte';

  @override
  String get notifyAllow => 'Sì';

  @override
  String get notifyDeny => 'No';

  @override
  String get notifyOpen => 'Apri';

  @override
  String get notifyChannelRequests => 'Richieste per te';

  @override
  String get notifyChannelUpdates => 'Messaggi e compiti';

  @override
  String get notifyAnswerFailedTitle => 'La risposta non è partita';

  @override
  String get notifyAnswerFailedBody => 'Apri l\'app per rispondere: la richiesta aspetta ancora.';

  @override
  String notifyAsksPermission(String name) {
    return '$name chiede il permesso';
  }

  @override
  String notifyAsksYou(String name) {
    return '$name ti chiede';
  }

  @override
  String get notifyCriticalTitle => 'Una richiesta davvero pericolosa: aprila per decidere';

  @override
  String get notifyTestTitle => 'Prova delle notifiche';

  @override
  String notifyTestBody(String server) {
    return 'Le notifiche di $server arrivano su questo computer.';
  }

  @override
  String get notifyTestShown => 'Una notifica di prova è sullo schermo.';

  @override
  String get pushStateHead => 'Su questo dispositivo';

  @override
  String pushOnVia(String via) {
    return 'Attive, attraverso $via';
  }

  @override
  String get pushOffHere =>
      'Spente su questo dispositivo: con l\'app chiusa Rasgeth non può avvisarti.';

  @override
  String get pushWaiting => 'Aspetto l\'indirizzo dal distributore…';

  @override
  String pushWaitingEndpoint(String name) {
    return '$name sta preparando l\'indirizzo di questo telefono: ci vuole qualche secondo.';
  }

  @override
  String get pushNowOn => 'Le notifiche sono attive: manda una prova per vederne una.';

  @override
  String get pushNowOff => 'Notifiche spente su questo dispositivo.';

  @override
  String get pushEndpointNotSent =>
      'Il distributore ha dato un indirizzo, ma Rasgeth non si raggiunge: l\'app riprova al prossimo avvio.';

  @override
  String get pushFailedNetwork => 'Il distributore adesso non ha rete: riprova fra poco.';

  @override
  String get pushFailedVapid =>
      'Il distributore vuole la chiave VAPID di Rasgeth, che sta nel portachiavi: apri il portachiavi su Rasgeth e riprova.';

  @override
  String get pushFailedAction =>
      'Il distributore ha bisogno di te: aprilo (per esempio ntfy) e segui quello che dice.';

  @override
  String get pushFailedOther =>
      'Non sono riuscito ad attivare le notifiche: riprova, o scegli un altro distributore.';

  @override
  String get pushDistributorDropped =>
      'Il distributore ha chiuso questa registrazione: riattiva le notifiche.';

  @override
  String pushTurnOn(String name) {
    return 'Attiva con $name';
  }

  @override
  String get pushTurnOff => 'Spegni';

  @override
  String pushLastError(String error) {
    return 'L\'ultima notifica non è partita: $error';
  }

  @override
  String get pushDistributorHead => 'Distributore (UnifiedPush)';

  @override
  String get pushDistributorHint =>
      'Il distributore porta le notifiche di Rasgeth su questo telefono, cifrate: lo scegli tu (ntfy, il tuo ntfy, Sunup…), senza il cloud di Google né di Rasgeth in mezzo.';

  @override
  String get pushNoDistributor => 'Su questo telefono non c\'è un distributore UnifiedPush.';

  @override
  String get pushNoDistributorMeans =>
      'Senza, Rasgeth non può raggiungerti con l\'app chiusa: richieste e risposte le vedi solo aprendo l\'app (o in una chat collegata, come Telegram).';

  @override
  String get pushNoDistributorHow =>
      'Per averle: installa ntfy (da F-Droid o dal Play Store) o un altro distributore UnifiedPush, poi torna qui e premi «Cerca di nuovo».';

  @override
  String get pushLookAgain => 'Cerca di nuovo';

  @override
  String get pushIosLater =>
      'Su iPhone le notifiche arrivano con l\'app pubblicata (il servizio push di Apple, predisposto e spento fino ad allora).';

  @override
  String get pushIosMeanwhile =>
      'Intanto vedi le richieste con l\'app aperta, o in una chat collegata (Telegram…).';

  @override
  String get pushDesktopWhat =>
      'Mentre l\'app è aperta, anche dietro altre finestre, richieste e domande arrivano come notifiche del sistema, con Sì e No per le richieste normali.';

  @override
  String get pushDesktopOn => 'Notifiche del sistema attive';

  @override
  String get pushDesktopOff => 'Notifiche del sistema spente';

  @override
  String get pushDesktopClosed =>
      'Con l\'app chiusa questo computer non riceve niente: la pagina di Rasgeth e le chat collegate sì.';

  @override
  String get pushNotHere => 'Questo sistema non ha notifiche per l\'app.';

  @override
  String get pushAboutHead => 'Come funzionano';

  @override
  String get pushAboutSealed =>
      'Ogni notifica è cifrata per questo dispositivo con chiavi fatte qui: il distributore la porta e basta.';

  @override
  String get pushAboutCritical =>
      'Una richiesta davvero pericolosa non ha mai il Sì rapido: la notifica la apre nell\'app, nella sua schermata.';

  @override
  String get pushAboutWithdrawn =>
      'Una richiesta risposta altrove (la pagina, una chat) sparisce anche da qui.';

  @override
  String get shareTitle => 'Condividi con Rasgeth';

  @override
  String get shareWhat => 'Cosa condividi';

  @override
  String get shareTo => 'A chi';

  @override
  String get shareToChatHint => 'Una conversazione nuova';

  @override
  String get shareNoteHint => 'Aggiungi una nota…';

  @override
  String get voiceReaderHead => 'Chi legge le risposte';

  @override
  String get voiceModelHead => 'Modello';

  @override
  String get voiceVoiceHead => 'Voce';

  @override
  String get voiceAccountVoice => 'La voce è quella dell\'account con la chiave.';

  @override
  String get voiceVolumeHead => 'Volume';

  @override
  String get voiceVolumeHint =>
      'Fino al volume pieno del sistema: i tasti del telefono lo alzano ancora.';

  @override
  String get voiceTry => 'Prova la voce';

  @override
  String get voiceStop => 'Ferma';

  @override
  String get voiceReadAloud => 'Leggi ad alta voce';

  @override
  String get voiceTrySentence => 'Ciao, ecco come leggo le risposte.';

  @override
  String get voiceNoReader => 'Rasgeth non ha ancora una voce per leggere.';

  @override
  String get voiceNoReaderHow =>
      'Aggiungi una chiave di OpenAI, ElevenLabs o Google Gemini nelle Impostazioni di Rasgeth, Voce: poi sceglila qui.';

  @override
  String get voiceTalkHead => 'Premi e parla';

  @override
  String get voiceTalkWhat =>
      'In una conversazione tieni premuto il microfono mentre parli: lascia e quello che hai detto è scritto nel campo, da rileggere prima di inviare.';

  @override
  String get voiceTalkWhere =>
      'Lo scrive la trascrizione di Rasgeth (Impostazioni, Voce, Trascrizione), la stessa della pagina.';

  @override
  String get voiceHoldToTalk => 'Tieni premuto per parlare';

  @override
  String get voiceListening => 'Ti ascolto… lascia per finire';

  @override
  String get voiceWriting => 'Scrivo quello che hai detto…';

  @override
  String get voiceTooShort => 'Troppo breve: tieni premuto il microfono mentre parli.';

  @override
  String get voiceHeardNothing => 'Non ho sentito parole: riprova più vicino al telefono.';

  @override
  String get voiceMicDenied =>
      'Il microfono non è permesso: permettilo nelle impostazioni del sistema per Rasgeth.';

  @override
  String get voiceMicFailed => 'Il microfono non è partito: lo sta usando un\'altra app?';

  @override
  String get voiceErrNoService =>
      'Rasgeth non ha un servizio di trascrizione: scegline uno in Impostazioni, Voce, Trascrizione.';

  @override
  String voiceErrNoKey(String name) {
    return '$name non ha ancora una chiave: aggiungila in Impostazioni, Voce.';
  }

  @override
  String get voiceErrEmpty => 'La registrazione è vuota.';

  @override
  String get voiceErrTooLong => 'La registrazione è troppo lunga.';

  @override
  String get voiceErrConvert =>
      'Non sono riuscito a convertire la registrazione per whisper sul computer di Rasgeth.';

  @override
  String voiceErrTimeout(String name) {
    return '$name ci ha messo troppo a rispondere.';
  }

  @override
  String voiceErrUnreachable(String name) {
    return '$name non si raggiunge: controlla che sia acceso e il suo indirizzo.';
  }

  @override
  String voiceErrKeyRefused(String name) {
    return '$name ha rifiutato la chiave: controllala in Impostazioni, Voce.';
  }

  @override
  String voiceErrRateLimited(String name) {
    return '$name dice troppe richieste o credito finito.';
  }

  @override
  String voiceErrServiceError(String name, String status) {
    return '$name ha risposto con un errore ($status).';
  }

  @override
  String get voiceErrProvider => 'Questo fornitore non lo sa fare: scegline un altro.';

  @override
  String get voiceErrServer => 'Rasgeth non si raggiunge: controlla la connessione.';

  @override
  String get voiceErrOther => 'La voce non ha funzionato: riprova.';

  @override
  String get notifyTestFailed =>
      'Il sistema non l\'ha mostrata: le notifiche per Rasgeth sono attive nelle sue impostazioni?';

  @override
  String get tabProjects => 'Progetti';

  @override
  String get sectionCoders => 'Per chi programma';

  @override
  String get sectionMascots => 'Mascotte';

  @override
  String get advancedTitle => 'Interfaccia avanzata';

  @override
  String get advancedNew => 'nuovo';

  @override
  String get advancedHint =>
      'Aggiunge Progetti alla barra e, nella scheda di ogni agente, File, Diff e Terminale.';

  @override
  String get advancedTerminals => 'Terminale dei miei agenti';

  @override
  String get advancedTerminalsHint => 'Solo lettura; il mio terminale ha la fila di tasti in più.';

  @override
  String get codeTabTasks => 'Compiti';

  @override
  String get codeTabFiles => 'File';

  @override
  String get codeTabDiff => 'Diff';

  @override
  String get codeTabTerminal => 'Terminale';

  @override
  String get codeTabLog => 'Log';

  @override
  String get codeTabGit => 'Git';

  @override
  String get codeArchived => 'Progetto archiviato: solo lettura finché non lo ripristini.';

  @override
  String get codeArchivedShort => 'archiviato';

  @override
  String get codeChangedMeanwhile => 'Il file è cambiato da quando l\'hai aperto: riaprilo.';

  @override
  String get codeUnreachable => 'Rasgeth non si raggiunge: controlla la connessione.';

  @override
  String get codeLoadFailed => 'Non si è caricato: tira giù per riprovare.';

  @override
  String get codeNoRepo => 'nessun repository';

  @override
  String get codeDetached => 'nessun ramo';

  @override
  String get codeClean => 'pulito';

  @override
  String codeChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche',
      one: '1 modifica',
    );
    return '$_temp0';
  }

  @override
  String codeAheadBehind(int ahead, int behind) {
    return '$ahead avanti, $behind indietro';
  }

  @override
  String get codeNoProjects => 'Ancora nessun progetto.';

  @override
  String codeOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compiti in corso',
      one: '1 compito in corso',
    );
    return '$_temp0';
  }

  @override
  String get codeNoOpenTasks => 'nessun compito in corso';

  @override
  String get codeNoTasks => 'Nessun compito in questo progetto.';

  @override
  String get codeColRunning => 'In corso';

  @override
  String get codeColToVerify => 'Da verificare';

  @override
  String get codeColDone => 'Fatti';

  @override
  String get codeTaskVerified => 'verificato · uscita 0';

  @override
  String codeTaskNotTestable(String why) {
    return '«non verificabile»: $why';
  }

  @override
  String codeTaskAbandoned(String why) {
    return 'abbandonato: $why';
  }

  @override
  String get codeTaskNoVerifier => 'verificatore non ancora eseguito';

  @override
  String codeTaskVerifier(String command, String result) {
    return 'verificatore: $command · $result';
  }

  @override
  String get codeTaskPassed => 'passato';

  @override
  String get codeTaskFailed => 'non passato';

  @override
  String get codeTaskDiff => 'Il diff del compito';

  @override
  String get codeSearchHint => 'Cerca nomi e testo';

  @override
  String get codeNoHits => 'Non ho trovato niente.';

  @override
  String get codeEmptyFolder => 'Cartella vuota.';

  @override
  String get codePickFile => 'Scegli un file a sinistra.';

  @override
  String get codeSmallEdit => 'Piccola modifica';

  @override
  String get codeSave => 'Salva';

  @override
  String get codeSaving => 'Salvo…';

  @override
  String get codeSaved => 'Salvato.';

  @override
  String get codeAsk => 'Chiedi a…';

  @override
  String get codeAskWho => 'A quale agente chiedi?';

  @override
  String codeAskDraft(String path) {
    return 'Sul file `$path`: ';
  }

  @override
  String get codeSeeDiff => 'Vedi il diff';

  @override
  String get codeCopyPath => 'Copia il percorso';

  @override
  String get codePathCopied => 'Percorso copiato.';

  @override
  String get codeNotText => 'Non è un file di testo: aprilo dalla pagina.';

  @override
  String codeModifiedAt(String when) {
    return 'modificato $when';
  }

  @override
  String get codeDiffWorking => 'Modifiche non salvate in git';

  @override
  String codeDiffTask(String title) {
    return 'Compito «$title»';
  }

  @override
  String codeDiffCommit(String hash, String subject) {
    return 'Commit $hash $subject';
  }

  @override
  String codeDiffAgent(String name) {
    return 'Il lavoro di $name';
  }

  @override
  String get codeDiffWhich => 'Quale diff?';

  @override
  String get codeDiffEmpty => 'Nessuna differenza.';

  @override
  String get codeDiffTruncated => 'Troppo lungo: si vede solo la prima parte.';

  @override
  String get codeDiffBinary => 'Un file binario: qui non c\'è niente da leggere.';

  @override
  String get codeDiffNoHunks => 'Solo rinominato o cambiati i permessi.';

  @override
  String codeFileOf(int n, int total) {
    return '$n di $total';
  }

  @override
  String get codePrevFile => 'File precedente';

  @override
  String get codeNextFile => 'File successivo';

  @override
  String get codeKeep => 'Tieni';

  @override
  String get codeKept => 'Tenuto';

  @override
  String get codeDiscard => 'Scarta';

  @override
  String get codeDiscarded => 'Scartato';

  @override
  String get codeDiscardTitle => 'Scartare questa modifica?';

  @override
  String codeDiscardBody(String path) {
    return 'La modifica a $path viene tolta dai file. Una copia resta nel cestino del progetto (.trash/diffs) per rimetterla.';
  }

  @override
  String codeDiscardCommitBody(String path) {
    return 'Questa modifica del commit viene annullata in $path (come una nuova modifica non salvata in git). Una copia resta nel cestino del progetto (.trash/diffs).';
  }

  @override
  String get codeComment => 'Commenta';

  @override
  String codeCommentHint(String name) {
    return 'Una nota per $name';
  }

  @override
  String codeCommentIntro(String path, String hunk) {
    return 'Un commento su `$path`, in $hunk:';
  }

  @override
  String codeCommentSent(String name) {
    return 'Mandato a $name.';
  }

  @override
  String get codeCommentFailed => 'Non mandato: riprova.';

  @override
  String get codeNoChat => 'Ancora nessuna conversazione con questo agente.';

  @override
  String get codeTermMine => 'Il mio';

  @override
  String get codeTextSmaller => 'Testo più piccolo';

  @override
  String get codeTextBigger => 'Testo più grande';

  @override
  String get codeTermReadOnly =>
      'Sola lettura: i comandi che l\'agente ha dato e cosa hanno scritto.';

  @override
  String get codeTermNoCommands => 'Ancora nessun comando.';

  @override
  String get codeReload => 'Ricarica';

  @override
  String get codeTermIntro =>
      'Una shell nella sandbox del progetto, come il terminale della pagina.';

  @override
  String get codeTermOpen => 'Apri il terminale';

  @override
  String get codeTermHint => 'Un comando';

  @override
  String get codeTermClosed => 'Il terminale si è chiuso.';

  @override
  String get codeLogAgent => 'Quale agente?';

  @override
  String get codeLogAllAgents => 'Tutti gli agenti';

  @override
  String get codeLogType => 'Quale tipo?';

  @override
  String get codeLogAllTypes => 'Tutti i tipi';

  @override
  String get codeLogErrors => 'Solo errori';

  @override
  String get codeLogEmpty => 'Niente nel log.';

  @override
  String get codeLogOpenChat => 'Apri la conversazione';

  @override
  String get codeBranches => 'Rami';

  @override
  String get codeCommits => 'Commit';

  @override
  String codeUpstream(String name) {
    return 'segue $name';
  }

  @override
  String get codeNoUpstream => 'non ancora mandato da nessuna parte';

  @override
  String get codeCommitHint => 'Cosa è cambiato (il messaggio del commit)';

  @override
  String get codeCommit => 'Commit';

  @override
  String codeCommitted(String hash) {
    return 'Commit $hash fatto.';
  }

  @override
  String get codeNothingToCommit => 'Niente da salvare in un commit.';

  @override
  String get codePush => 'Push';

  @override
  String get codePushAsked =>
      'Push chiesto: rispondi da «Da te» (è una richiesta a te, come quella di un agente).';

  @override
  String get codePushDone => 'Push fatto.';

  @override
  String get codePushDenied => 'Push non fatto: la risposta è stata no.';

  @override
  String codePushFailed(String error) {
    return 'Il push non è riuscito: $error';
  }

  @override
  String get codeNoRemote => 'Il progetto non ha un repository remoto dove mandare il push.';

  @override
  String get savedSave => 'Salva';

  @override
  String get savedSaveTitle => 'Salva questo passaggio';

  @override
  String get savedSaveMessageTitle => 'Salva questo messaggio';

  @override
  String get savedNote => 'Nota (facoltativa)';

  @override
  String get savedNotePlaceholder => 'Perché lo tieni, che cosa farne…';

  @override
  String get savedTags => 'Etichette (facoltative)';

  @override
  String get savedTagsPlaceholder => 'Etichette nuove, separate da virgole';

  @override
  String get savedDone => 'Salvato: è nei tuoi Salvati, con la conversazione da cui viene.';

  @override
  String get savedOpenArchive => 'Apri';

  @override
  String savedFailed(String error) {
    return 'Non salvato: $error';
  }

  @override
  String get savedTitle => 'Salvati';

  @override
  String get savedHint =>
      'I passaggi e i messaggi che hai tenuto dalle tue conversazioni: li vedi solo tu. Seleziona una parte di una risposta e scegli «Salva», oppure usa «Salva» nel menu di un messaggio.';

  @override
  String get savedSearch => 'Cerca nei Salvati';

  @override
  String get savedAllTags => 'Tutte le etichette';

  @override
  String get savedAllAgents => 'Tutti gli agenti';

  @override
  String get savedEmpty => 'Non hai ancora salvato niente.';

  @override
  String get savedNoMatch => 'Nessun salvato corrisponde.';

  @override
  String get savedMore => 'Mostra i più vecchi';

  @override
  String get savedWhole => 'Messaggio intero';

  @override
  String savedOn(String when) {
    return 'Salvato $when';
  }

  @override
  String get savedOpen => 'Apri nella conversazione';

  @override
  String get savedEdit => 'Modifica nota ed etichette';

  @override
  String get savedDelete => 'Elimina';

  @override
  String get savedDeleteTitle => 'Eliminare questo salvato?';

  @override
  String get savedDeleteText =>
      'Il passaggio esce dai tuoi Salvati; la conversazione resta com\'è.';

  @override
  String get savedUnknownOrigin => 'Una conversazione';

  @override
  String get savedFromDailyChat => 'Viene dalla chat di ogni giorno della pagina: aprila da lì.';

  @override
  String get savedNotThere => 'Il messaggio non è più nella conversazione.';

  @override
  String get savedExport => 'Esporta in Markdown';

  @override
  String get savedExportFile => 'Salva il file';

  @override
  String get savedExportCopy => 'Copia il Markdown';

  @override
  String get savedExportSaved => 'File salvato.';

  @override
  String get savedExportCopied => 'Markdown copiato: incollalo dove vuoi.';

  @override
  String savedExportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String get savedFileName => 'salvati.md';

  @override
  String get quoteReply => 'Rispondi a questo';

  @override
  String get quoteReplyingTo => 'Stai rispondendo a questo passaggio';

  @override
  String get quoteRemove => 'Togli questo passaggio';

  @override
  String get quoteJump => 'Vai al passaggio nella conversazione';

  @override
  String quoteTooMany(int n) {
    return 'Al massimo $n passaggi in un messaggio.';
  }

  @override
  String get messageMenu => 'Opzioni del messaggio';

  @override
  String get messageCopied => 'Copiato.';

  @override
  String get messageSaveHint => 'Tieni tutto il messaggio nei tuoi Salvati';

  @override
  String get productOpen => 'Apri';

  @override
  String productSource(int n) {
    return 'Fonte $n della risposta';
  }

  @override
  String get productNoPicture => 'Nessuna foto';

  @override
  String get productPrevious => 'Prodotti precedenti';

  @override
  String get productNext => 'Prodotti successivi';

  @override
  String get quoteReplyShort => 'Rispondi';

  @override
  String get savedSearchClear => 'Svuota la ricerca';

  @override
  String get metricsInput => 'letti';

  @override
  String get metricsCache => 'cache';

  @override
  String get metricsOutput => 'generati';

  @override
  String get metricsContext => 'contesto';

  @override
  String get metricsPrefill => 'lettura';

  @override
  String get metricsGeneration => 'generazione';

  @override
  String get metricsTimedByClient => 'tempi misurati dal client';

  @override
  String get metricsServerTimings => 'tempi del server';

  @override
  String get metricsStart => 'inizio';

  @override
  String get metricsFirstToken => 'primo token';

  @override
  String get metricsEnd => 'fine';

  @override
  String get metricsRestoredFromDisk =>
      'Persistar: il contesto di questa conversazione è tornato dal disco prima di questa richiesta';

  @override
  String get metricsCostUnknown => 'costo non noto';

  @override
  String get metricsCostUnknownHint =>
      'Questo modello non è ancora nel catalogo dei modelli: i prezzi non sono noti, quindi il costo non è contato.';

  @override
  String get metricsShowAll => 'Mostra tutti i dati del messaggio';

  @override
  String updNowBodyLocal(String version) {
    return 'Su questo computer l\'aggiornamento alla $version lo fa Rasgeth, con la sua finestra: scarica, si chiude e riparte con la versione nuova. Qui vedi i passi che dice.';
  }

  @override
  String get updFollow => 'Segui l\'aggiornamento';

  @override
  String upd2Title(String from, String to) {
    return 'Aggiorno Rasgeth dalla $from alla $to';
  }

  @override
  String upd2TitleTo(String to) {
    return 'Aggiorno Rasgeth alla $to';
  }

  @override
  String get upd2Starting => 'Avvio l\'aggiornamento…';

  @override
  String upd2Left(String time) {
    return 'mancano circa $time';
  }

  @override
  String upd2Total(String time) {
    return 'in tutto circa $time';
  }

  @override
  String get upd2LeftUnknown => 'calcolo quanto ci vuole…';

  @override
  String upd2Elapsed(String time) {
    return 'in corso da $time';
  }

  @override
  String upd2ToDownload(String size) {
    return '$size da scaricare';
  }

  @override
  String get upd2Steps => 'I passi dell\'aggiornamento';

  @override
  String get upd2Restarting => 'Rasgeth si sta riavviando, mi ricollego…';

  @override
  String upd2Attempt(String n, String time) {
    return 'Tentativo $n · senza risposta da $time';
  }

  @override
  String get upd2Back => 'Rasgeth risponde: controllo che sia la versione nuova…';

  @override
  String get upd2Keeps =>
      'Rasgeth continua a funzionare mentre scarica: si ferma solo per il riavvio, un minuto o due.';

  @override
  String get upd2ComesBack =>
      'Lascia aperta l\'app: si ricollega da sola appena Rasgeth risponde con la versione nuova.';

  @override
  String get upd2Local =>
      'Su questo computer l\'aggiornamento lo fa Rasgeth nella sua finestra, con la barra e il tempo: qui vedi i passi che Rasgeth dice, e se questa finestra resta aperta si ricollega da sola quando torna.';

  @override
  String get upd2Older =>
      'Questo Rasgeth non dice ancora i dettagli di ogni passo (arrivano con la 3.8.1): vedi a che punto è e da quanto.';

  @override
  String upd2Done(String version) {
    return 'Aggiornato alla $version';
  }

  @override
  String upd2DoneText(String from, String time) {
    return 'Dalla $from, in $time. Conversazioni, agenti e impostazioni sono come prima.';
  }

  @override
  String upd2DoneFrom(String from) {
    return 'Dalla $from. Conversazioni, agenti e impostazioni sono come prima.';
  }

  @override
  String get upd2Reconnected => 'L\'app si è ricollegata da sola.';

  @override
  String get upd2Reconnecting => 'Mi ricollego alla versione nuova…';

  @override
  String upd2News(String version) {
    return 'Le novità della $version';
  }

  @override
  String get upd2Notes => 'Le note della versione su GitHub';

  @override
  String get upd2BackHome => 'Torna a Rasgeth';

  @override
  String get upd2Hide => 'Nascondi: l\'aggiornamento continua';

  @override
  String get upd2Retry => 'Riprova';

  @override
  String get upd2Close => 'Torna indietro';

  @override
  String get upd2TookLess => 'meno di un minuto';

  @override
  String upd2TookMin(String min) {
    return '$min min';
  }

  @override
  String upd2TookHours(String h, String min) {
    return '$h h $min min';
  }

  @override
  String get upd2ImgHere => 'già qui';

  @override
  String get upd2ImgDone => 'scaricata';

  @override
  String get upd2ImgDatabase => 'Il database (Postgres)';

  @override
  String get upd2StepDone => 'fatto';

  @override
  String get upd2StepNow => 'in corso';

  @override
  String get upd2StepTodo => 'da fare';

  @override
  String get upd2StepFailed => 'fermo qui';

  @override
  String get upd2Step_check => 'Controllo la firma della versione nuova';

  @override
  String get upd2Step_download => 'Scarico la versione nuova';

  @override
  String get upd2Step_files => 'Scarico i file di sistema';

  @override
  String get upd2Step_install => 'Installo i file di sistema';

  @override
  String get upd2Step_restart => 'Riavvio Rasgeth con la versione nuova';

  @override
  String get upd2Step_wait => 'Controllo che Rasgeth risponda';

  @override
  String get upd2Step_rollback => 'Rimetto la versione di prima';

  @override
  String get upd2Step_scan => 'Confronto i file installati';

  @override
  String get upd2Step_build => 'Metto insieme la versione nuova';

  @override
  String get upd2Step_installer => 'Scarico il programma di installazione';

  @override
  String get upd2StepText_check => 'Si installa solo una versione firmata da Rasgeth.';

  @override
  String get upd2StepText_download => 'Rasgeth continua a funzionare mentre scarica.';

  @override
  String get upd2StepText_files => 'I programmi del sistema intorno a Rasgeth.';

  @override
  String get upd2StepText_install =>
      'Di ogni file sostituito resta una copia: se qualcosa va storto, torna com\'era.';

  @override
  String get upd2StepText_restart =>
      'Per un minuto o due Rasgeth non risponde: l\'app si ricollega da sola.';

  @override
  String get upd2StepText_wait =>
      'Se la versione nuova non risponde entro dieci minuti, torna da sola quella di prima.';

  @override
  String get upd2StepText_rollback =>
      'La versione nuova non è partita: rimetto quella di prima, non si perde niente.';

  @override
  String get upd2StepText_scan => 'Così si scarica solo quello che è cambiato.';

  @override
  String get upd2StepText_build => 'La versione nuova si prepara accanto a quella di adesso.';

  @override
  String get upd2StepText_installer => 'Il programma completo: si installa sopra quello di adesso.';

  @override
  String get upd2Why_download => 'Non sono riuscito a scaricare la versione nuova.';

  @override
  String upd2WhyText_download(String from) {
    return 'Non è cambiato niente: Rasgeth $from continua a funzionare. Controlla che la macchina arrivi a internet, poi premi «Riprova»: quello già scaricato non si riscarica.';
  }

  @override
  String get upd2Why_files => 'Non sono riuscito a installare i file di sistema nuovi.';

  @override
  String upd2WhyText_files(String from) {
    return 'Ogni file è tornato com\'era e Rasgeth $from continua a funzionare. Riprova tra un po\'; se succede ancora, scarica la diagnostica dalla pagina (Impostazioni › Generale › Diagnostica) e mandala.';
  }

  @override
  String get upd2Why_not_up => 'La versione nuova non è partita.';

  @override
  String upd2WhyText_not_up(String from) {
    return 'Rasgeth è tornato da solo alla $from: non si è perso niente. Riprova tra un po\'; se succede ancora, scarica la diagnostica dalla pagina (Impostazioni › Generale › Diagnostica) e mandala.';
  }

  @override
  String get upd2Why_no_images =>
      'Questa versione non ha niente per il processore di questa macchina.';

  @override
  String upd2WhyText_no_images(String from) {
    return 'Non è cambiato niente: Rasgeth $from continua a funzionare. Aspetta la prossima versione.';
  }

  @override
  String get upd2Why_breaking => 'Questa versione non si installa sopra quella di adesso.';

  @override
  String upd2WhyText_breaking(String from) {
    return 'Non è cambiato niente: Rasgeth $from continua a funzionare. Apri la pagina di Rasgeth dal computer: ti guida nell\'installazione da capo.';
  }

  @override
  String get upd2Why_unsigned => 'La versione nuova non è firmata.';

  @override
  String get upd2WhyText_unsigned =>
      'Per sicurezza non l\'ho installata: non è cambiato niente. Riguarda più tardi.';

  @override
  String get upd2Why_unreachable => 'GitHub non ha risposto.';

  @override
  String get upd2WhyText_unreachable =>
      'Non è cambiato niente. Controlla che la macchina arrivi a internet e premi «Riprova».';

  @override
  String get upd2Why_other => 'L\'aggiornamento non è finito.';

  @override
  String upd2WhyText_other(String from) {
    return 'Funziona la versione di prima ($from): non si è perso niente. Riprova tra un po\'.';
  }

  @override
  String get upd2Why_gone => 'Rasgeth non risponde più.';

  @override
  String get upd2WhyText_gone =>
      'Dopo il riavvio non è tornato. Controlla che la macchina sia accesa e in rete, poi premi «Riprova»: l\'app lo cerca di nuovo.';

  @override
  String get upd2Why_start => 'L\'aggiornamento non è partito.';

  @override
  String upd2WhyText_start(String from) {
    return 'Non è cambiato niente: Rasgeth $from continua a funzionare. Riprova tra un po\'.';
  }

  @override
  String upd2WhySaid(String error) {
    return 'Rasgeth ha detto: $error';
  }

  @override
  String get upd2ScreenTitle => 'Aggiornamento di Rasgeth';

  @override
  String get deskAbout => 'Informazioni su Rasgeth';

  @override
  String get deskAdvancedOff => 'Spegni l\'interfaccia avanzata';

  @override
  String get deskAdvancedOn => 'Accendi l\'interfaccia avanzata';

  @override
  String get deskAdvancedShort => 'avanzata';

  @override
  String deskAgeDays(int n) {
    return '$n g';
  }

  @override
  String deskAgeHours(int n) {
    return '$n h';
  }

  @override
  String deskAgeMinutes(int n) {
    return '$n min';
  }

  @override
  String get deskAgeNow => 'adesso';

  @override
  String get deskAgeYesterday => 'ieri';

  @override
  String deskAgentAsks(String name, String what) {
    return '$name chiede: $what';
  }

  @override
  String deskAgentsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n agenti',
      one: '1 agente',
    );
    return '$_temp0';
  }

  @override
  String get deskAgentsHead => 'Agenti';

  @override
  String get deskAgentsTerminals => 'Degli agenti';

  @override
  String get deskAllProjects => 'Tutti i progetti';

  @override
  String get deskAllProjectsLower => 'tutti i progetti';

  @override
  String get deskAskChat => 'Chiedi alla Chat';

  @override
  String get deskAskGod => 'Chiedi a God';

  @override
  String deskAskHint(String name) {
    return 'Chiedi a $name senza aprire la conversazione…';
  }

  @override
  String get deskAskInConversation => 'Chiedi nella sua conversazione';

  @override
  String deskAskTag(String name) {
    return 'A $name';
  }

  @override
  String deskAsked(String name) {
    return 'Mandato a $name';
  }

  @override
  String deskAsks(String what) {
    return 'Chiede: $what';
  }

  @override
  String get deskByProject => 'Per progetto';

  @override
  String get deskByState => 'Per stato';

  @override
  String get deskChanges => 'Modifiche';

  @override
  String get deskChatHint => 'Chiedimi qualcosa…';

  @override
  String get deskChatSub => 'per tutti i giorni';

  @override
  String get deskChosenCommit => 'Commit scelto';

  @override
  String get deskClose => 'Chiudi';

  @override
  String get deskCloseFloating => 'Chiudi i pannelli staccati';

  @override
  String get deskColAgent => 'Agente';

  @override
  String get deskColDuration => 'Durata';

  @override
  String get deskColSummary => 'Riassunto';

  @override
  String get deskColTime => 'Ora';

  @override
  String get deskColType => 'Tipo';

  @override
  String get deskCopy => 'Copia';

  @override
  String get deskCopyJson => 'Copia JSON';

  @override
  String deskCriticalCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n critiche',
      one: '1 critica',
    );
    return '$_temp0';
  }

  @override
  String get deskCriticalTitle => 'Richiesta critica';

  @override
  String get deskCut => 'Taglia';

  @override
  String get deskDiffWord => 'differenza';

  @override
  String get deskDockAll => 'Riattacca i pannelli staccati';

  @override
  String get deskDropHere => 'Rilascia per allegare';

  @override
  String deskEventN(int n) {
    return 'Evento $n';
  }

  @override
  String get deskEventStream => 'Filo degli eventi';

  @override
  String get deskFiles => 'File';

  @override
  String deskFilesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n file', one: '1 file');
    return '$_temp0';
  }

  @override
  String get deskFilterAll => 'Tutti';

  @override
  String get deskFilterBlocked => 'Bloccati';

  @override
  String get deskFilterWaiting => 'Aspettano te';

  @override
  String get deskFilterWorking => 'Al lavoro';

  @override
  String get deskFindAgent => 'Cerca un agente…';

  @override
  String deskFloatingCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pannelli staccati',
      one: '1 pannello staccato',
    );
    return '$_temp0';
  }

  @override
  String deskForYouCount(int n) {
    return '$n da te';
  }

  @override
  String get deskForYouPush => 'Da te: un invio';

  @override
  String get deskForYouShort => 'da te';

  @override
  String get deskFrozen => 'fermo';

  @override
  String get deskGitCommit => 'Fai un commit…';

  @override
  String get deskGitCommitTitle => 'Commit di tutto ciò che è cambiato';

  @override
  String get deskGitHistory => 'Mostra la storia';

  @override
  String get deskGitPush => 'Invia…';

  @override
  String get deskGoToFile => 'Vai al file…';

  @override
  String get deskGodHint => 'Chiedi a God di organizzare qualcosa…';

  @override
  String get deskGrid => 'Griglia';

  @override
  String get deskHintAsk => 'chiedi subito';

  @override
  String get deskHintChoose => 'scegli';

  @override
  String get deskHintFloat => 'in un pannello staccato';

  @override
  String get deskHintOpen => 'apri';

  @override
  String get deskHintPrefixes => 'scrivi @ per gli agenti, / per i comandi';

  @override
  String get deskHintPrefixesAdvanced => 'senza prefisso cerca tutto';

  @override
  String get deskInContainer => 'nel contenitore del progetto';

  @override
  String get deskInConversation => 'Nella conversazione';

  @override
  String get deskInline => 'In linea';

  @override
  String get deskKeyDown => 'Giù';

  @override
  String get deskKeyEnter => 'Invio';

  @override
  String get deskKeyEsc => 'Esc';

  @override
  String get deskKeyOption => 'Opz';

  @override
  String get deskKeyShift => 'Maiusc';

  @override
  String get deskKeySpace => 'Spazio';

  @override
  String get deskKeyTab => 'Tab';

  @override
  String get deskKeyUp => 'Su';

  @override
  String get deskLayoutAlways => 'Sempre';

  @override
  String deskLayoutFrom(int n) {
    return 'Da $n px';
  }

  @override
  String get deskLayoutHint =>
      'La sala di controllo quando la finestra è larga almeno così; più stretta, le schermate del telefono.';

  @override
  String get deskLayoutNever => 'Mai';

  @override
  String get deskLayoutTitle => 'Layout da computer';

  @override
  String get deskList => 'Elenco';

  @override
  String get deskLive => 'dal vivo';

  @override
  String get deskLogSearchHint => 'agente:\"Coder Web\" tipo:tool.* testo';

  @override
  String get deskMenuAgents => 'Agenti';

  @override
  String get deskMenuConversation => 'Conversazione';

  @override
  String get deskMenuEdit => 'Modifica';

  @override
  String get deskMenuFile => 'File';

  @override
  String get deskMenuHelp => 'Aiuto';

  @override
  String get deskMenuView => 'Vista';

  @override
  String get deskMenuWindow => 'Finestra';

  @override
  String deskNewAgentNamed(String name) {
    return 'Nuovo agente «$name»…';
  }

  @override
  String get deskNewConversation => 'Nuova conversazione con l\'agente aperto';

  @override
  String get deskNewTerminal => 'Nuovo terminale';

  @override
  String get deskNoActions => 'Nessuna azione recente';

  @override
  String get deskNoAgents => 'Nessun agente';

  @override
  String get deskNoChanges => 'nessuna, tutto nel commit';

  @override
  String get deskNoGit => 'senza repository: solo file';

  @override
  String get deskNoGitShort => 'senza git';

  @override
  String get deskNoKeysHere => 'Senza chiavi: le credenziali restano alle vie d\'uscita';

  @override
  String get deskNoProject => 'Senza progetto';

  @override
  String get deskNoProjects => 'Ancora nessun progetto';

  @override
  String get deskNoTask => 'nessun compito aperto';

  @override
  String get deskNoTerminals => 'Scegli un terminale a sinistra';

  @override
  String get deskNoneHere => 'Nessun agente in questo filtro';

  @override
  String get deskNothingForYou => 'niente a cui rispondere';

  @override
  String deskOfTotal(int n, int total) {
    return '$n di $total';
  }

  @override
  String get deskOnly => 'Solo';

  @override
  String get deskOnlyErrors => 'errori e falliti';

  @override
  String get deskOnlyRequests => 'richieste a te';

  @override
  String get deskOpenDetail => 'Apri il dettaglio';

  @override
  String get deskOpenInPanel => 'Apri nel pannello laterale';

  @override
  String get deskOpenTasks => 'Compiti aperti';

  @override
  String get deskPaletteAgents => 'Agenti';

  @override
  String deskPaletteAnswer(String what) {
    return 'Rispondi: $what';
  }

  @override
  String get deskPaletteCommands => 'Comandi';

  @override
  String get deskPaletteConversations => 'Conversazioni';

  @override
  String get deskPaletteEvents => 'Eventi del Log';

  @override
  String get deskPaletteFiles => 'File';

  @override
  String get deskPaletteHint => 'Agenti, conversazioni, comandi, file…';

  @override
  String get deskPaletteLines => 'Righe';

  @override
  String get deskPaletteNothing => 'Niente trovato';

  @override
  String deskPaletteOpenFile(String path) {
    return 'Apri $path';
  }

  @override
  String get deskPaletteRequests => 'Da te';

  @override
  String get deskPaletteTerminal => 'Terminale';

  @override
  String get deskPaletteTitle => 'Palette dei comandi';

  @override
  String get deskPanelClose => 'Chiudi il pannello';

  @override
  String get deskPanelDetach => 'Stacca dal pannello';

  @override
  String get deskPanelDock => 'Rimetti nel pannello laterale';

  @override
  String get deskPanelResize => 'Larghezza del pannello';

  @override
  String get deskPaste => 'Incolla';

  @override
  String get deskPickEvent => 'Scegli un evento per vederlo intero';

  @override
  String get deskProject => 'Progetto';

  @override
  String deskProjectWorking(String name, String state, int n) {
    return '$name $state · $n al lavoro';
  }

  @override
  String get deskPushAsked => 'Chiesto in «Da te»: l\'invio parte col tuo sì';

  @override
  String get deskQuickChat => 'Chat rapida';

  @override
  String get deskQuickChatExpand => 'Apri nel pannello laterale';

  @override
  String deskQuickChatHint(String keys) {
    return '$keys la richiama dentro l\'app';
  }

  @override
  String get deskReadOnly => 'sola lettura';

  @override
  String get deskRedo => 'Ripeti';

  @override
  String get deskRemotes => 'Remoti';

  @override
  String deskRequestsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n richieste',
      one: '1 richiesta',
    );
    return '$_temp0';
  }

  @override
  String deskRunInTerminal(String cmd, String project) {
    return 'Esegui «$cmd» nel tuo terminale di $project';
  }

  @override
  String get deskRunInTerminalDetail =>
      'In un tuo terminale, nel contenitore del progetto. I comandi tuoi non chiedono permesso: sei tu.';

  @override
  String get deskSameTurn => 'Nello stesso turno';

  @override
  String get deskSearchCommits => 'Cerca nei commit';

  @override
  String deskSearchEvents(String q) {
    return 'Eventi con «$q» nel Log';
  }

  @override
  String get deskSearchShort => 'Cerca';

  @override
  String get deskSelectAll => 'Seleziona tutto';

  @override
  String get deskSettings => 'Impostazioni';

  @override
  String get deskShortcuts => 'Scorciatoie da tastiera';

  @override
  String get deskSideBySide => 'Affiancato';

  @override
  String deskStatusPalette(String keys) {
    return '$keys palette';
  }

  @override
  String get deskStill => 'Fermi';

  @override
  String deskStopAgent(String name) {
    return 'Ferma $name';
  }

  @override
  String get deskStopOpen => 'Ferma l\'agente aperto';

  @override
  String get deskStreamHint => 'Fermo al passaggio del mouse · un clic apre il Log';

  @override
  String deskSubagents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sotto-agenti',
      one: '1 sotto-agente',
    );
    return '$_temp0';
  }

  @override
  String get deskTabs => 'Schede';

  @override
  String get deskTags => 'Etichette';

  @override
  String get deskTaskChanges => 'Modifiche del compito';

  @override
  String get deskTaskFailed => 'rosso';

  @override
  String get deskTaskPassed => 'verde';

  @override
  String get deskTaskRunning => 'in corso';

  @override
  String get deskTasksRule => 'si chiudono solo con un verificatore che esce con 0';

  @override
  String get deskTermAskHint => 'Per chiedergli qualcosa scrivi nella sua conversazione';

  @override
  String deskTerminalsShown(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n terminali',
      one: '1 terminale',
    );
    return '$_temp0';
  }

  @override
  String deskTheme(String name) {
    return 'Tema: $name';
  }

  @override
  String get deskTiles => 'Caselle';

  @override
  String deskToSend(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n commit da inviare',
      one: '1 commit da inviare',
      zero: 'niente da inviare',
    );
    return '$_temp0';
  }

  @override
  String get deskTogglePanel => 'Pannello laterale';

  @override
  String get deskTypeHead => 'Tipo';

  @override
  String get deskUndo => 'Annulla';

  @override
  String get deskVerifier => 'Verifica';

  @override
  String get deskViewCode => 'Codice';

  @override
  String get deskViewTerminals => 'Terminali';

  @override
  String get deskWhen => 'Quando';

  @override
  String get deskWhenAll => 'tutto';

  @override
  String get deskWhenHour => '1 ora';

  @override
  String get deskWhenToday => 'oggi';

  @override
  String get deskWhenWeek => '7 giorni';

  @override
  String get deskWithChanges => 'Con modifiche';

  @override
  String deskWorkingCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n agenti al lavoro',
      one: '1 agente al lavoro',
    );
    return '$_temp0';
  }

  @override
  String get deskYouWrite => 'puoi scrivere';

  @override
  String get deskYourTerminal => 'Il tuo terminale';

  @override
  String get deskYourTerminals => 'Tuoi';

  @override
  String get deskNewProject => 'Nuovo progetto';

  @override
  String get deskProjectName => 'Nome del progetto';

  @override
  String get deskProjectCreate => 'Crea';

  @override
  String deskProjectMade(String name) {
    return 'Progetto «$name» creato, con il suo orchestratore.';
  }

  @override
  String deskProjectFailed(String why) {
    return 'Non sono riuscito a creare il progetto: $why';
  }

  @override
  String deskProjectNoGit(String name, String why) {
    return 'Progetto «$name» creato, ma senza repository git: $why. Crealo da Impostazioni › Progetti («Inizializza git») appena git funziona.';
  }

  @override
  String get deskGitMissing => 'git non è ancora installato su questo computer';

  @override
  String get limitsTotal => 'Totale';

  @override
  String get limitsSpent => 'Speso';

  @override
  String get limitsContext => 'Contesto';

  @override
  String get limitsWeekShort => '7g';

  @override
  String get deskSendMessage => 'Invia il messaggio (nei campi delle conversazioni)';

  @override
  String get deskFullWindow => 'A tutta finestra';

  @override
  String get deskFullWindowOff => 'Torna al pannello';

  @override
  String get deskBackToRoom => 'Torna alla Sala';

  @override
  String get deskRailLabel => 'Agenti';

  @override
  String deskRailWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count richieste per te',
      one: '1 richiesta per te',
    );
    return '$_temp0';
  }

  @override
  String get tpReading => 'Legge il contesto';

  @override
  String tpTokens(String done, String total) {
    return '$done di $total token';
  }

  @override
  String tpRate(String n) {
    return '$n token/s';
  }

  @override
  String tpCache(String pct) {
    return '$pct dalla cache';
  }

  @override
  String get tpWaitingFirst => 'Il fornitore non dice a che punto è: aspetto il primo token';

  @override
  String get tpThinking => 'Ragiona';

  @override
  String get tpWriting => 'Scrive';

  @override
  String tpWritten(String n) {
    return 'circa $n token';
  }

  @override
  String tpGenRate(String n) {
    return 'circa $n token/s';
  }

  @override
  String tpReadIn(String total, String time, String pct) {
    return 'contesto di $total letto in $time, $pct dalla cache';
  }

  @override
  String tpFirstAfter(String time) {
    return 'primo token dopo $time';
  }

  @override
  String get compactingNow => 'Sto riassumendo la conversazione…';

  @override
  String get asOpen => 'Impostazioni dell\'agente…';

  @override
  String asTitle(String name) {
    return 'Impostazioni di $name';
  }

  @override
  String get asClose => 'Chiudi';

  @override
  String get asGroupGeneral => 'Generale';

  @override
  String get asGroupWork => 'Modello e modo';

  @override
  String get asGroupMemory => 'Memoria';

  @override
  String get asGroupLimits => 'Spesa';

  @override
  String get asGroupTools => 'Strumenti';

  @override
  String get asGroupKnowledge => 'Conoscenza';

  @override
  String get asKind_god => 'God, guida tutto';

  @override
  String get asKind_demigod => 'Demi-God, il messaggero su Telegram';

  @override
  String get asKind_orchestrator => 'Capo del progetto';

  @override
  String get asKind_agent => 'Agente';

  @override
  String get asKind_subagent => 'Aiutante';

  @override
  String get asKind_inspector => 'Ispettore, solo lettura';

  @override
  String get asKind_assistant => 'Assistente personale';

  @override
  String get asKindChat => 'La Chat di ogni giorno';

  @override
  String get asStopped => 'Fermato';

  @override
  String get asMascot => 'Mascotte';

  @override
  String get asMascotHelp => 'Rinominarlo non cambia la faccia: la cambi solo tu, da qui.';

  @override
  String get asMascotGod =>
      'La mascotte di God è disegnata a mano: la stella gigante con la corona, con tre stelline che le girano attorno.';

  @override
  String get asName => 'Nome';

  @override
  String get asRole => 'Cosa fa';

  @override
  String get asRoleHelp =>
      'Una o due righe: God e gli orchestratori le leggono per decidere cosa passargli.';

  @override
  String get asProjects => 'Lavora anche per';

  @override
  String asProjectsHelp(String name) {
    return 'Scegli i progetti per cui lavora anche $name: lì sta sotto l\'orchestratore del progetto, che gli dà i compiti.';
  }

  @override
  String get asSaved => 'Salvato.';

  @override
  String get asSavedNew => 'Salvato: vale dalle conversazioni nuove.';

  @override
  String asRefused(String why) {
    return 'Il server non l\'ha accettato: $why';
  }

  @override
  String get asNoName => 'Serve un nome.';

  @override
  String get asModelHelp =>
      'Senza un modello suo usa quello dell\'agente sopra di lui. Vale dalle conversazioni nuove: il modello di una conversazione in corso lo cambi tu, dal suo campo di scrittura.';

  @override
  String get asModelGodHelp =>
      'Il modello che usa God; senza, quello predefinito scelto nella configurazione. Il modello di una conversazione in corso lo cambi tu, dal suo campo di scrittura.';

  @override
  String get asModelChatHelp =>
      'Il modello della Chat, come nella sua intestazione sulla pagina. Il modello di una conversazione in corso lo cambi tu, dal suo campo di scrittura.';

  @override
  String get asMode => 'Quanto fa da solo';

  @override
  String get asModeHelp => 'Quello che manda, pubblica, cancella o paga aspetta sempre te.';

  @override
  String get asMode_auto => 'In autonomia';

  @override
  String get asMode_manual => 'Chiede il permesso';

  @override
  String get asMode_plan => 'Prima propone un piano';

  @override
  String get asMode_readonly => 'Sola lettura';

  @override
  String get asModeExplain_auto => 'Lavora da solo e chiede solo per le cose pericolose.';

  @override
  String get asModeExplain_manual => 'Ti chiede prima di ogni modifica ai file o di ogni comando.';

  @override
  String get asModeExplain_plan => 'Prima scrive un piano e parte quando lo approvi.';

  @override
  String get asModeExplain_readonly => 'Legge e risponde, non cambia niente.';

  @override
  String get asInstructionsHelp =>
      'Il suo system prompt, il suo o quello di serie: le conversazioni già aperte tengono il loro.';

  @override
  String asMemOwn(String name) {
    return 'Memoria di $name: solo per questo agente';
  }

  @override
  String asMemOwnHelp(String name) {
    return 'La legge solo $name, all\'inizio di ogni conversazione. Anche $name ci può annotare quello che gli serve.';
  }

  @override
  String asMemProject(String name) {
    return 'Memoria del progetto «$name»';
  }

  @override
  String get asMemProjectHelp => 'La leggono tutti gli agenti che lavorano a questo progetto.';

  @override
  String get asMemNone => 'Questo agente non tiene una memoria sua.';

  @override
  String get asCompact => 'Riassunti delle conversazioni lunghe';

  @override
  String get asCompactHelp =>
      'Quando la conversazione diventa lunga, l\'agente fa un riassunto delle parti vecchie, come chi prende appunti. Qui scegli quando farlo e quanto dell\'ultima parte tenere com\'è.';

  @override
  String get asCompactAt => 'Quando fare il riassunto';

  @override
  String asCompactAtValue(String n) {
    return 'piena al $n%';
  }

  @override
  String get asCompactKeep => 'Quanto dell\'ultima parte tenere com\'è';

  @override
  String asCompactKeepValue(String n) {
    return 'l\'ultimo $n%';
  }

  @override
  String get asCompactKeepNone => 'niente';

  @override
  String asCompactDefaultIs(String at, String keep) {
    return 'Predefinito per il modello di questo agente: al $at%, tenendo il $keep%.';
  }

  @override
  String get asCompactDefaults => 'Torna ai valori predefiniti';

  @override
  String get asLimitsHelp =>
      'Quando arriva al limite si ferma e ti chiede. Il limite conta tutto quello speso da quando l\'hai messo.';

  @override
  String get asSpent => 'Speso finora';

  @override
  String get asLimit => 'Limite in dollari';

  @override
  String get asNoLimit => 'Nessun limite';

  @override
  String asLimitTokens(String n) {
    return 'Limite: $n token';
  }

  @override
  String get asRemoveLimit => 'Togli il limite';

  @override
  String get asLimitBad => 'Scrivi un importo maggiore di zero.';

  @override
  String get asToolsHelp =>
      'Per ogni strumento: come per tutti gli agenti (Impostazioni, Strumenti), sempre acceso per questo agente, oppure spento. Quelli essenziali non si spengono.';

  @override
  String get asToolsNewOnly =>
      'Le modifiche valgono dalle conversazioni nuove: quelle già aperte tengono i loro strumenti.';

  @override
  String asToolsTotal(String name, String n) {
    return '$name: circa $n token in ogni messaggio';
  }

  @override
  String get asToolDefaultOn => 'Come per tutti (acceso)';

  @override
  String get asToolDefaultOff => 'Come per tutti (spento)';

  @override
  String get asToolAlways => 'Sempre acceso';

  @override
  String get asToolOff => 'Spento';

  @override
  String get asToolLocked => 'Essenziale: sempre acceso';

  @override
  String get asEditRule => 'Modifiche nei file aperti';

  @override
  String get asEditRuleHelp =>
      'Quando modifica un file aperto nel Canvas: subito (evidenziato, annullabile) o come proposte che accetti tu. La scelta fatta sul file vince.';

  @override
  String get asEditNow => 'Subito';

  @override
  String get asEditPropose => 'Come proposte';

  @override
  String asKbHelp(String name) {
    return 'Quali raccolte può cercare $name. Ognuna dice chi può leggerla; qui puoi fare un\'eccezione per questo agente. Vale dalla prossima conversazione.';
  }

  @override
  String get asKbNone => 'Ancora nessuna raccolta.';

  @override
  String asKbByScope(String on) {
    return 'Per dove sta ($on)';
  }

  @override
  String get asKbOn => 'Sì';

  @override
  String get asKbOff => 'No';

  @override
  String get asKbScope_global => 'Tutti gli agenti';

  @override
  String get asKbScope_agent => 'Un agente';

  @override
  String get asKbScope_project => 'Gli agenti di un progetto';

  @override
  String get asDanger => 'Fermarlo';

  @override
  String get asStopHelp =>
      'Una pausa: i suoi turni si fermano subito, con chi sta sotto di lui, e i compiti aperti aspettano. «Riattiva» lo riporta e i compiti ripartono nella stessa conversazione. Per toglierlo dalla squadra usa «Rimuovi…».';

  @override
  String asStopAsk(String name) {
    return 'Fermare $name? È una pausa: i suoi turni si fermano subito e i compiti aperti aspettano; «Riattiva» lo riporta e ripartono da dove erano.';
  }

  @override
  String asStopYes(String name) {
    return 'Ferma $name';
  }

  @override
  String asStoppedNow(String name) {
    return '$name è fermo.';
  }

  @override
  String asLoadFailed(String why) {
    return 'Non sono riuscito a leggerlo dal server: $why';
  }

  @override
  String get asMenuNew => 'Nuova conversazione';

  @override
  String get asMenuModel => 'Modello e sforzo…';

  @override
  String get asMenuInstructions => 'Istruzioni…';

  @override
  String get asMenuStopTurn => 'Ferma quello che sta facendo';

  @override
  String cvPermAsks(String agent) {
    return '$agent chiede il tuo sì';
  }

  @override
  String get cvPermWhy => 'Perché te lo chiede';

  @override
  String get cvPermDetails => 'Dettagli';

  @override
  String get cvPermTool => 'Strumento';

  @override
  String get cvPermRawReasons => 'Motivi registrati';

  @override
  String get cvShowLess => 'Mostra meno';

  @override
  String get cvShowAllInput => 'Mostra tutta la richiesta';

  @override
  String get cvAllow => 'Consenti';

  @override
  String get cvThisChat => 'In questa conversazione';

  @override
  String cvThisChatHint(String tool) {
    return 'Consenti $tool senza chiederlo più, solo in questa conversazione';
  }

  @override
  String get cvAlways => 'Sempre';

  @override
  String cvAlwaysHint(String tool) {
    return 'Consenti $tool da ora in poi senza chiedere (una regola che puoi annullare in Impostazioni, Piattaforma)';
  }

  @override
  String get cvDeny => 'Nega';

  @override
  String get cvDenyWhy => 'Nega e spiega perché';

  @override
  String get cvDenyWhyPlaceholder => 'Cosa fare invece (l\'agente lo legge)';

  @override
  String get cvCriticalTitle => 'Pericolo: azione che non si può annullare';

  @override
  String get cvCriticalWhat => 'Cosa succede se consenti';

  @override
  String cvToolReqTitle(String name, String tool) {
    return '$name chiede di accendere «$tool»';
  }

  @override
  String cvToolReqWhy(String why) {
    return 'Perché: $why';
  }

  @override
  String cvToolReqHint(String name) {
    return 'Senza il tuo sì resta spento. «Sempre» cambia gli strumenti di $name (puoi annullarlo nello storico).';
  }

  @override
  String get cvToolReqSession => 'Accendi per questa conversazione';

  @override
  String cvToolReqAlways(String name) {
    return 'Sempre per $name';
  }

  @override
  String get cvToolReqNo => 'No';

  @override
  String get cvAgTitle => 'Un artefatto chiede un permesso';

  @override
  String get cvAgCap => 'Tetto di spesa per questo artefatto:';

  @override
  String get cvAgCapHint =>
      'Raggiunto il tetto le sue domande si fermano; puoi cambiarlo in Impostazioni › Artefatti.';

  @override
  String get cvAgHint =>
      'Resta finché non lo togli in Impostazioni › Artefatti. Una versione nuova dell\'artefatto lo tiene; una copia importata parte senza permessi.';

  @override
  String cvAgAllowCap(String cap) {
    return 'Consenti, fino a $cap';
  }

  @override
  String get cvAgAllow => 'Consenti';

  @override
  String get cvAgDeny => 'No';

  @override
  String get cvManyAnswers => 'una o più';

  @override
  String get cvOtherAnswer => 'Altro: scrivi la tua risposta';

  @override
  String get cvProposedPlan => 'Piano proposto';

  @override
  String get cvWaitingAnswer => 'in attesa di risposta';

  @override
  String get cvNotAnswered => 'nessuna risposta';

  @override
  String get cvPlanFeedback => 'Cosa cambieresti? (facoltativo)';

  @override
  String get cvPlanApprove => 'Approva e procedi';

  @override
  String get cvPlanRevise => 'Continua a pianificare';

  @override
  String get cvSendFeedback => 'Manda il commento';

  @override
  String get cvAnswer => 'Rispondi';

  @override
  String cvTodosTitle(String done, String all) {
    return 'Passi: $done su $all fatti';
  }

  @override
  String get cvEditMessage => 'Modifica';

  @override
  String get cvEditForks =>
      'Il messaggio modificato apre una copia di questa conversazione da qui; questa resta com\'è.';

  @override
  String get cvEditSend => 'Invia';

  @override
  String get cvCancel => 'Annulla';

  @override
  String get cvForkHere => 'Continua da qui';

  @override
  String get cvForkHereHint =>
      'Una conversazione nuova con tutto fino a questo messaggio; questa resta com\'è';

  @override
  String get cvForkStartsHere => 'Da qui continua la conversazione nuova.';

  @override
  String get cvForkEdited => 'Da qui continua il messaggio modificato.';

  @override
  String cvForkBack(String title) {
    return 'Torna a «$title»';
  }

  @override
  String get cvForkOrigin => 'la conversazione originale';

  @override
  String get cvCompactionAuto =>
      'La conversazione è stata riassunta qui (la parte più vecchia, preparata in anticipo)';

  @override
  String get cvCompactionManual => 'La conversazione è stata riassunta qui, come hai chiesto';

  @override
  String get cvCompactionEmergency =>
      'La conversazione è stata riassunta qui: la finestra era piena';

  @override
  String get cvCompactionEngine =>
      'Il motore dell\'abbonamento ha riassunto la conversazione qui (da solo)';

  @override
  String get cvCompactionUndone => 'Riassunto annullato: la conversazione intera è tornata';

  @override
  String get cvUndo => 'Annulla';

  @override
  String get cvStepLimitContinue => 'Continua';

  @override
  String get cvStepLimitContinueHint =>
      'L\'agente ha raggiunto il limite di passi: fallo andare avanti da dove si è fermato';

  @override
  String get cvStepLimitGoOn => 'Vai avanti';

  @override
  String cvCacheMissed(String cached, String expected) {
    return 'Questa risposta ha letto dalla cache solo $cached token invece di circa $expected: qualcosa ha cambiato l\'inizio della conversazione, quindi è stata ricalcolata (più lenta e, online, più cara).';
  }

  @override
  String get cvToolNoResult =>
      'Nessun risultato: la chiamata è finita senza (il turno è stato annullato o si è fermato).';

  @override
  String cvToolOnMachine(String name) {
    return 'su $name';
  }

  @override
  String cvToolOnNode(String name) {
    return 'sul nodo $name';
  }

  @override
  String get cvViaScript => 'da uno script';

  @override
  String get cvToolSeen => 'Cosa ha visto l\'agente';

  @override
  String cvOpenSubagentChat(String name) {
    return 'Apri la conversazione di $name';
  }

  @override
  String get cvKindSubagent => 'Aiutante';

  @override
  String cvElsewhereAsks(String name, String title) {
    return '$name ti chiede qualcosa in un\'altra conversazione: «$title»';
  }

  @override
  String cvElsewhereWorking(String name, String title) {
    return '$name sta lavorando in un\'altra conversazione: «$title»';
  }

  @override
  String get cvElsewhereUntitled => 'senza titolo';

  @override
  String get cvElsewhereAnswerHere => 'Rispondi qui';

  @override
  String get cvOpen => 'apri';

  @override
  String get cvUnqueue => 'Ritira (se l\'agente non l\'ha ancora letto)';

  @override
  String get cvSentWhileWorking => 'Mandato mentre l\'agente lavora: lo legge appena può';

  @override
  String cvWriteWhileWorking(String name) {
    return '$name sta lavorando: scrivi pure, lo legge subito dopo…';
  }

  @override
  String cvWriteTo(String name) {
    return 'Scrivi a $name…';
  }

  @override
  String get cvStopWhenBack => 'Il collegamento è perso: «Ferma» parte appena torna.';

  @override
  String get cvSendQueued => 'Manda: lo legge appena il lavoro in corso lo permette';

  @override
  String get cvInterrupt => 'Ferma';

  @override
  String get cvPaBadge => 'Archiviato · sola lettura';

  @override
  String cvPaChatReadOnly(String name) {
    return 'Il progetto «$name» è archiviato: questa conversazione è in sola lettura.';
  }

  @override
  String get cvPaRestore => 'Ripristina';

  @override
  String cvImpChatNotice(String source, String date) {
    return 'Conversazione portata da $source$date. Puoi continuarla qui.';
  }

  @override
  String get cvViaVoice => 'detto a voce';

  @override
  String get cvViaVoiceHint =>
      'Detto a mani libere; all\'agente è stata chiesta una risposta da leggere ad alta voce';

  @override
  String get cvViaArtifact => 'da un widget';

  @override
  String get cvViaArtifactHint =>
      'Mandato da un pulsante che hai cliccato in un artefatto o in un widget';

  @override
  String cvCanvasOpened(String name) {
    return 'Ha aperto $name nel Canvas';
  }

  @override
  String get cvCanvasShown => 'Nel canvas: premi per riaprirlo';

  @override
  String get cvBoardOpen => 'Apri la tavola';

  @override
  String cvBoardWaiting(String n) {
    return 'Una tavola con $n varianti: aprila per scegliere o commentare';
  }

  @override
  String cvBoardDone(String n) {
    return 'Tavola: hai scelto la variante $n';
  }

  @override
  String get cvFileSave => 'Salva';

  @override
  String get cvCanvasOpen => 'Aprilo nel canvas';

  @override
  String get cvChSecretTitle => 'Questo messaggio contiene un segreto';

  @override
  String get cvChSecretText =>
      'Sembra una chiave, una password o un numero di carta. I segreti non vanno mai in una chat: il modello e il registro lo terrebbero. Mettilo invece nel portachiavi: gli agenti lo useranno per nome senza vederlo.';

  @override
  String cvChSecretFound(String list) {
    return 'Trovato: $list';
  }

  @override
  String get cvChSecretKindKey => 'una chiave';

  @override
  String get cvChSecretKindPassword => 'una password';

  @override
  String get cvChSecretKindCode => 'un PIN o codice';

  @override
  String get cvChSecretKindCard => 'un numero di carta';

  @override
  String get cvChSecretKindIban => 'un IBAN';

  @override
  String get cvChSecretBack => 'Torna a scrivere';

  @override
  String get cvChSecretSend => 'Invia senza';

  @override
  String get cvChSecretVault => 'Mettilo nel portachiavi';

  @override
  String get cvAttachmentOpen => 'Apri nel Canvas';

  @override
  String get cvToBottom => 'Vai in fondo';

  @override
  String get cvThinking => 'Ragionamento';

  @override
  String get cvSeeAttachments => '(vedi gli allegati)';

  @override
  String get cvPastedOpen => 'Vedi tutto il testo incollato';

  @override
  String get cvPastedAsText => 'Incolla come testo';

  @override
  String get cvRemove => 'Rimuovi';

  @override
  String get cvClose => 'Chiudi';

  @override
  String get cvCopied => 'Copiato';

  @override
  String cvStartConversation(String name) {
    return 'Scrivi a $name per cominciare.';
  }

  @override
  String cvSubAsks(String name) {
    return 'Il sotto-agente «$name» chiede il tuo permesso.';
  }

  @override
  String cvPastedSize(String lines, String chars) {
    return '$lines righe · $chars caratteri';
  }

  @override
  String get cvCopy => 'Copia';

  @override
  String get mailCardNone => 'Nessun messaggio trovato';

  @override
  String mailCardMore(int n) {
    return 'altri $n';
  }

  @override
  String mailCardAttachments(int n) {
    return '$n allegati';
  }

  @override
  String get mailCardAttachment => '1 allegato';

  @override
  String get mailCardSaved => 'salvato';

  @override
  String get mailCardShowAll => 'Mostra tutto';

  @override
  String get mailCardShowLess => 'Mostra meno';

  @override
  String mailCardFolder(String mailbox, String folder) {
    return '$mailbox, $folder';
  }

  @override
  String get mailCardDraft => 'Bozza';

  @override
  String get mailCardTo => 'A';

  @override
  String get mailCardSubject => 'Oggetto';

  @override
  String get mailCardUnread => 'da leggere';

  @override
  String get mailCardPermTitle => 'L\'email, come partirebbe';

  @override
  String get mailCardDraftSaved => 'Bozza salvata';

  @override
  String get mailCardDraftChanged => 'Bozza modificata';

  @override
  String mailCardSentFrom(String mailbox) {
    return 'Inviata da $mailbox';
  }

  @override
  String get mailCardNobody => 'nessuno';

  @override
  String get cvAcpKindRead => 'lettura';

  @override
  String get cvAcpKindEdit => 'modifica';

  @override
  String get cvAcpKindDelete => 'cancellazione';

  @override
  String get cvAcpKindMove => 'spostamento';

  @override
  String get cvAcpKindSearch => 'ricerca';

  @override
  String get cvAcpKindExecute => 'comando';

  @override
  String get cvAcpKindThink => 'riflessione';

  @override
  String get cvAcpKindFetch => 'pagina web';

  @override
  String get cvAcpKindSwitchMode => 'modalità';

  @override
  String get cvAcpKindOther => 'azione';

  @override
  String get cvFindViaEverything => 'indice di Everything';

  @override
  String get cvFindViaSpotlight => 'indice di Spotlight';

  @override
  String get cvFindViaLocate => 'database di locate';

  @override
  String get cvFindViaWalk => 'ricerca nelle cartelle';

  @override
  String get cvFindViaPath => 'programmi nel PATH';

  @override
  String get cvFindViaContainer => 'ricerca nel container';

  @override
  String cvFindTook(String via, String seconds) {
    return '$via, $seconds s';
  }

  @override
  String cvFindTookCut(String via, String seconds, String limit) {
    return '$via, $seconds s (fermata a $limit s)';
  }

  @override
  String cvFindTookInterrupted(String via, String seconds) {
    return '$via, $seconds s (interrotta)';
  }

  @override
  String cvTooMany(String n) {
    return 'Al massimo $n allegati';
  }

  @override
  String get widgetTitle => 'Widget';

  @override
  String get widgetPreparing => 'Sto preparando un widget…';

  @override
  String get widgetOpenCanvas => 'Apri nel Canvas';

  @override
  String get widgetKeep => 'Tienilo';

  @override
  String get widgetKeepHint => 'Salvato come artefatto in artefatti/ e aperto nel Canvas';

  @override
  String get widgetKeptShort => 'Tenuto';

  @override
  String widgetKept(String path) {
    return 'Salvato come $path';
  }

  @override
  String get widgetAsks => 'Vuole mandare in chat:';

  @override
  String get widgetNoChat => 'Vuole mandare in chat (apri prima una conversazione):';

  @override
  String get widgetSend => 'Manda';

  @override
  String get widgetDismiss => 'Lascia stare';

  @override
  String get widgetLoading => 'Carico…';

  @override
  String get widgetOpenInPage => 'Apri nella pagina';

  @override
  String get widgetNoFrameHere =>
      'Su questo sistema l\'app non può far girare widget e artefatti al suo interno: aprilo nella pagina, nel browser.';

  @override
  String get artError1 => '1 errore';

  @override
  String artErrors(int n) {
    return '$n errori';
  }

  @override
  String get previewLinkTitle => 'La pagina vuole aprire un link';

  @override
  String get previewLinkOpen => 'Apri';

  @override
  String get embedCopied => 'Copiato';

  @override
  String get embedShareCopied => 'Copiato: incollalo dove vuoi condividerlo';

  @override
  String embedSaved(String name) {
    return 'Salvato: $name';
  }

  @override
  String get embedOpenInBrowser => 'Apri nel browser';

  @override
  String get embedProbeTitle => 'Prova della vista web';

  @override
  String get embedSaving => 'Salvataggio…';

  @override
  String get embedSavedState => 'Salvato';

  @override
  String get embedProbeOpen => 'Prova della vista web';

  @override
  String get requestAnswerAllowed => 'consentita';

  @override
  String get requestAnswerDenied => 'negata';

  @override
  String requestDoneHere(String answer) {
    return 'Hai già risposto dalla pagina o da un\'altra finestra: $answer.';
  }

  @override
  String requestDoneChat(String chat, String answer) {
    return 'Hai già risposto da $chat: $answer.';
  }

  @override
  String requestDoneTimeout(String answer) {
    return 'Nessuno ha risposto in tempo: $answer.';
  }

  @override
  String requestDoneElsewhere(String answer) {
    return 'Già decisa altrove: $answer.';
  }

  @override
  String get requestDoneClosing => 'Questa schermata si chiude da sola tra qualche secondo.';

  @override
  String get requestCloseHint => 'Chiudi (Esc)';

  @override
  String get requestTechDetails => 'Dettagli tecnici';

  @override
  String get cmOpen => 'Apri';

  @override
  String get cmPin => 'Fissa';

  @override
  String get cmUnpin => 'Togli dalle fissate';

  @override
  String get cmFolder => 'Sposta in una cartella';

  @override
  String get cmFolderNew => 'Nuova cartella…';

  @override
  String get cmFolderNewTitle => 'Nuova cartella';

  @override
  String get cmFolderNewYes => 'Sposta';

  @override
  String get cmFolderOut => 'Toglila dalla cartella';

  @override
  String get cmArchive => 'Archivia';

  @override
  String get cmUnarchive => 'Riporta';

  @override
  String get cmExport => 'Esporta in Markdown';

  @override
  String get cmArchived => 'Conversazione archiviata.';

  @override
  String get cmUnarchived => 'Conversazione riportata.';

  @override
  String get cmFailed => 'Non è riuscito: riprova.';

  @override
  String get cmExported => 'File salvato.';

  @override
  String cmForkOf(String title) {
    return 'ramo di «$title»';
  }

  @override
  String cmArchivedN(int n) {
    return 'Archiviate ($n)';
  }

  @override
  String get cmBack => 'Torna alle conversazioni';

  @override
  String get cmNew => 'Nuova conversazione';

  @override
  String get cmEmpty => 'Ancora nessuna conversazione: iniziane una.';

  @override
  String get cmEmptyArchived => 'Nessuna conversazione archiviata.';

  @override
  String get cmPinned => 'Fissate';

  @override
  String cmConversationsOf(String name) {
    return 'Conversazioni con $name';
  }

  @override
  String cmTask(String title) {
    return 'Compito: $title';
  }

  @override
  String get cmShared => 'Conversazione condivisa';

  @override
  String get pmOpen => 'Apri';

  @override
  String get pmTasks => 'Compiti e file';

  @override
  String get pmCode => 'Codice';

  @override
  String pmAgents(String project) {
    return 'Agenti di $project';
  }

  @override
  String get pmArchive => 'Archivia il progetto';

  @override
  String get pmRestore => 'Ripristina';

  @override
  String get pmInitGit => 'Inizializza git';

  @override
  String pmInitGitDone(String name) {
    return 'Repository git creato per «$name» (branch main).';
  }

  @override
  String pmAskTitle(String name) {
    return 'Archiviare «$name»?';
  }

  @override
  String get pmAskLead =>
      'Il progetto esce dagli elenchi e resta leggibile in «Archiviati». Niente viene cancellato: lo ripristini quando vuoi e torna com\'era.';

  @override
  String pmWorking(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n agenti stanno lavorando: verranno fermati',
      one: '1 agente sta lavorando: verrà fermato',
    );
    return '$_temp0';
  }

  @override
  String get pmNobody => 'Nessun agente ci sta lavorando adesso.';

  @override
  String pmAutos(int n, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n automazioni verranno messe in pausa ($names); ripartono quando ripristini il progetto.',
      one: '1 automazione verrà messa in pausa ($names); riparte quando ripristini il progetto.',
    );
    return '$_temp0';
  }

  @override
  String get pmFactTasks => 'I compiti aperti restano aperti.';

  @override
  String get pmFactSandbox => 'La sua sandbox si ferma e riparte al ripristino.';

  @override
  String get pmFactNobody =>
      'Fino ad allora nessun agente ci lavora né cambia i suoi file, e le chat collegate non lo usano.';

  @override
  String get pmFactRestore => 'Anche God può archiviarlo e ripristinarlo, sempre con il tuo sì.';

  @override
  String get pmStopAndArchive => 'Ferma e archivia';

  @override
  String get pmArchiveYes => 'Archivia';

  @override
  String pmArchived(String name) {
    return '«$name» archiviato.';
  }

  @override
  String pmRestored(String name) {
    return '«$name» ripristinato.';
  }

  @override
  String pmArchivedN(int n) {
    return 'Archiviati ($n)';
  }

  @override
  String pmArchivedOn(String day) {
    return 'archiviato il $day';
  }

  @override
  String get pmBadge => 'Archiviato · sola lettura';

  @override
  String get pmViewLead =>
      'Archiviato: puoi leggere le sue conversazioni, i compiti e i file. Ripristinalo per lavorarci di nuovo.';

  @override
  String get pmConversations => 'Conversazioni';

  @override
  String get pmTeam => 'Le conversazioni del gruppo';

  @override
  String get pmNoConversations => 'Nessuna conversazione.';

  @override
  String get pmTasksTitle => 'Compiti';

  @override
  String get pmNoTasks => 'Nessun compito.';

  @override
  String get pmNoLead => 'Questo progetto non ha un agente capo.';

  @override
  String get pmNoGit => 'Senza repository git';

  @override
  String get bellTitle => 'Da approvare';

  @override
  String get bellTooltip => 'Richieste e notifiche';

  @override
  String bellPermissions(int n) {
    return 'Permessi ($n)';
  }

  @override
  String bellQuestions(int n) {
    return 'Domande ($n)';
  }

  @override
  String bellWorking(int n) {
    return 'Al lavoro adesso ($n)';
  }

  @override
  String get bellNoApprovals => 'Niente che ti aspetta.';

  @override
  String get bellNoQuestions => 'Nessuna domanda.';

  @override
  String get bellNothingRunning => 'Niente in corso.';

  @override
  String get bellAllow => 'Consenti';

  @override
  String get bellDeny => 'Nega';

  @override
  String get bellLook => 'Guarda e decidi';

  @override
  String get bellAnswer => 'Rispondi';

  @override
  String get bellSeeAll => 'Vedi tutto';

  @override
  String pmConversationsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n conversazioni',
      one: '1 conversazione',
      zero: 'nessuna conversazione',
    );
    return '$_temp0';
  }

  @override
  String get raMenu => 'Rimuovi…';

  @override
  String raTitle(String name) {
    return 'Rimuovere $name?';
  }

  @override
  String raBody(String name) {
    return '$name esce dalla squadra: i suoi turni si fermano e nessuno gli dà più lavoro. Non si cancella niente: le sue conversazioni e la sua storia restano, leggibili in «Agenti rimossi», da dove puoi ripristinarlo.';
  }

  @override
  String raWith(String names) {
    return 'Insieme a lui: $names';
  }

  @override
  String raKept(int commits, int files) {
    return 'Lavoro non unito: $commits commit, $files file modificati';
  }

  @override
  String get raKeptError => 'Lavoro tenuto com\'è: non si è potuto controllare';

  @override
  String raKeptHow(String branch) {
    return 'Resta nel ramo $branch: ripristina l\'agente per riprenderlo.';
  }

  @override
  String raTasks(int count) {
    return 'Compiti aperti che si chiudono («agente rimosso»): $count';
  }

  @override
  String raRunning(int count) {
    return 'Conversazioni al lavoro che si fermano ora: $count';
  }

  @override
  String raYes(String name) {
    return 'Rimuovi $name';
  }

  @override
  String raDone(String name) {
    return '$name rimosso: «Agenti rimossi» lo riporta indietro.';
  }

  @override
  String raFailed(String why) {
    return 'Non rimosso: $why';
  }

  @override
  String raProtected(String name) {
    return '$name non si può rimuovere.';
  }

  @override
  String get raHelp =>
      'Esce dalla squadra con gli agenti sotto di lui; la sua storia resta e lo ripristini da «Agenti rimossi».';

  @override
  String get raListTitle => 'Agenti rimossi';

  @override
  String get raListRow => 'Leggi le loro conversazioni, riportali indietro';

  @override
  String get raListHelp =>
      'Agenti tolti dalla squadra, da te o da God. Non si è cancellato niente: le loro conversazioni restano leggibili e «Ripristina» riporta ciascuno indietro con chi è stato rimosso con lui.';

  @override
  String get raNone => 'Nessun agente rimosso.';

  @override
  String raWhen(String when, String by) {
    return 'Rimosso il $when da $by';
  }

  @override
  String get raByYou => 'te';

  @override
  String raReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get raRestore => 'Ripristina';

  @override
  String raRestored(String name) {
    return '$name è di nuovo nella squadra.';
  }

  @override
  String raRestoreFailed(String why) {
    return 'Non ripristinato: $why';
  }

  @override
  String raConversations(int count) {
    return 'Conversazioni ($count)';
  }

  @override
  String get raNoConversations => 'Nessuna conversazione.';

  @override
  String raReadOnly(String name) {
    return '$name è stato rimosso: questa conversazione è in sola lettura.';
  }

  @override
  String get raBadge => 'Rimosso';

  @override
  String get paMenu => 'Ferma…';

  @override
  String paTitle(String name) {
    return 'Fermare $name?';
  }

  @override
  String paYes(String name) {
    return 'Ferma $name';
  }

  @override
  String paDone(String name) {
    return '$name è in pausa: «Riattiva» lo riporta.';
  }

  @override
  String get paResume => 'Riattiva';

  @override
  String paResumeHelp(String name) {
    return '$name è fermo (in pausa). «Riattiva» lo riporta con chi è fermo sotto di lui, e i compiti aperti ripartono nella stessa conversazione.';
  }

  @override
  String paResumed(String name) {
    return '$name lavora di nuovo.';
  }

  @override
  String paResumedTasks(String name) {
    return '$name lavora di nuovo: i compiti aperti ripartono.';
  }

  @override
  String paResumeFailed(String why) {
    return 'Non riattivato: $why';
  }

  @override
  String paReadOnly(String name) {
    return '$name è fermo (in pausa): riattivalo per scrivergli.';
  }

  @override
  String get paBadge => 'In pausa';

  @override
  String get atWorkTitle => 'Agenti al lavoro insieme';

  @override
  String get atWorkAtMost => 'Agenti al lavoro insieme, al massimo';

  @override
  String get atWorkHelp =>
      'Quanti agenti possono lavorare nello stesso momento. Gli altri aspettano in coda e partono da soli, in ordine, appena si libera un posto. I tuoi messaggi diretti non aspettano mai; un sotto-agente prende il posto di chi lo aspetta. Abbassarlo non ferma nessuno: vale per i turni dopo.';

  @override
  String get atWorkNoLimit => 'Nessun limite';

  @override
  String atWorkSummary(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Al massimo $n agenti alla volta',
      one: 'Al massimo 1 agente alla volta',
    );
    return '$_temp0';
  }

  @override
  String get atWorkNoLimitHint => 'Ogni agente che ha lavoro parte subito.';

  @override
  String get atWorkSaved => 'Salvato: vale per i turni che partono da adesso.';

  @override
  String get atWorkNow => 'Adesso';

  @override
  String atWorkPlaces(int working, int limit) {
    return '$working posti occupati su $limit';
  }

  @override
  String atWorkPlacesNoLimit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n al lavoro, senza limite',
      one: '1 al lavoro, senza limite',
      zero: 'Nessuno al lavoro',
    );
    return '$_temp0';
  }

  @override
  String get queueTitle => 'Coda degli agenti';

  @override
  String get queueEmpty => 'Nessuno aspetta: ogni agente che ha lavoro sta lavorando.';

  @override
  String queuedNth(String nth, int of) {
    return 'in coda ($nth di $of)';
  }

  @override
  String queuedBanner(String nth, int of) {
    return 'In coda ($nth di $of): aspetta che si liberi un posto';
  }

  @override
  String get queueWaitingDoing => 'Aspetta che si liberi un posto';

  @override
  String get queueMoveFirst => 'Passa avanti';

  @override
  String get queueSee => 'Vedi la coda';

  @override
  String get queueNext => 'Prossimo';

  @override
  String get queueStop => 'Ferma';

  @override
  String queueWaited(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in coda da $n min',
      one: 'in coda da 1 min',
      zero: 'in coda da poco',
    );
    return '$_temp0';
  }

  @override
  String get queueChild => 'chiesto da un agente che lo aspetta';

  @override
  String get queueMoved => 'fatto passare avanti da te';

  @override
  String get queueMoveFailed => 'Non aspetta più: forse è appena partito.';

  @override
  String statusAtWork(int working, int limit) {
    return 'Al lavoro $working/$limit';
  }

  @override
  String statusAtWorkNoLimit(int n) {
    return 'Al lavoro $n';
  }

  @override
  String statusQueued(int n) {
    return 'in coda $n';
  }

  @override
  String get queueOpenSettings => 'Cambia il limite';

  @override
  String get fxOpenFiles => 'File del progetto';

  @override
  String get fxSubtitle => 'File e cartelle';

  @override
  String get fxPlatform => 'Piattaforma';

  @override
  String get fxAssistants => 'Agenti personali';

  @override
  String get fxNewFile => 'Nuovo file';

  @override
  String get fxNewFolder => 'Nuova cartella';

  @override
  String get fxMake => 'Crea';

  @override
  String get fxPathHint => 'Nome, con la cartella se ti serve (docs/nota.md)';

  @override
  String get fxUpload => 'Carica';

  @override
  String fxUploaded(int count) {
    return 'File caricati: $count.';
  }

  @override
  String get fxShowHidden => 'Mostra i file nascosti';

  @override
  String get fxHideHidden => 'Nascondi i file nascosti';

  @override
  String get fxRefresh => 'Aggiorna';

  @override
  String get fxTerminal => 'Terminale';

  @override
  String get fxFull => 'A tutta finestra';

  @override
  String get fxFullOff => 'Accanto alla conversazione';

  @override
  String get fxClose => 'Chiudi i file';

  @override
  String get fxSearchHint => 'Cerca nei file';

  @override
  String get fxClearSearch => 'Cancella la ricerca';

  @override
  String get fxFolder => 'Cartella';

  @override
  String get fxReadOnly => 'Sola lettura: il progetto è archiviato';

  @override
  String get fxEmpty => 'Cartella vuota.';

  @override
  String get fxDropHere => 'Rilascia i file per caricarli qui';

  @override
  String fxExists(String name) {
    return '$name esiste già qui.';
  }

  @override
  String get fxKeepBoth => 'Mantieni entrambi';

  @override
  String get fxReplace => 'Sostituisci';

  @override
  String get fxOpen => 'Apri nel Canvas';

  @override
  String get fxAsk => 'Chiedi all\'agente';

  @override
  String get fxRename => 'Rinomina';

  @override
  String get fxDownload => 'Scarica';

  @override
  String fxDownloaded(String name) {
    return '$name salvato.';
  }

  @override
  String get fxDelete => 'Elimina';

  @override
  String fxConfirmDelete(String path) {
    return 'Spostare $path nel cestino (.trash)?';
  }

  @override
  String fxConfirmDeleteForGood(String path) {
    return 'Eliminare $path per sempre?';
  }

  @override
  String get fxMore => 'Altre azioni';

  @override
  String get fxResize => 'Ridimensiona il pannello dei file';

  @override
  String fxAttachFailed(String name) {
    return 'Non sono riuscito ad allegare $name.';
  }

  @override
  String get cvBoardChoose => 'Scelgo questa';

  @override
  String get cvBoardChosen => 'Scelta';

  @override
  String get cvBoardChoiceWord => 'scelta';

  @override
  String get cvBoardCommentWord => 'commento';

  @override
  String get cvBoardWriteComment => 'Scrivi un commento';

  @override
  String get cvBoardSending => 'Invio…';

  @override
  String get cvBoardSent => 'Mandato all\'agente';

  @override
  String get cvBoardOneVariant => '1 variante';

  @override
  String cvBoardVariants(String n) {
    return '$n varianti';
  }

  @override
  String get cvBoardScreens => 'Larghezza delle anteprime';

  @override
  String get cvBoardScreenComputer => 'Computer';

  @override
  String get cvBoardScreenTablet => 'Tablet';

  @override
  String get cvBoardScreenPhone => 'Telefono';

  @override
  String get cvBoardFull => 'A tutto schermo';

  @override
  String get cvBoardCommentHere => 'Commento su questa variante (facoltativo con «Scelgo questa»)';

  @override
  String get cvBoardSendComment => 'Manda commento';

  @override
  String get cvBoardWhole => 'Commento sulla tavola intera';

  @override
  String get cvBoardWholeHint =>
      'Per esempio: mi piace il colore della 2 con la disposizione della 3';

  @override
  String get cvBoardSendToAgent => 'Manda all\'agente';

  @override
  String get cvBoardTab => 'Tavola';

  @override
  String get cvBoardNotFound => 'Questa tavola non c\'è più';

  @override
  String get cvCanvasReload => 'Ricarica';

  @override
  String cvEmbedPort(String port) {
    return 'Porta $port';
  }

  @override
  String cvDrawing(String percent) {
    return 'Disegno… $percent%';
  }

  @override
  String get cvArSection => 'Artefatti';

  @override
  String get cvArLead =>
      'Le piccole app in un file solo che gli agenti fanno per te. Si aprono nel Canvas, accanto alla chat.';

  @override
  String get cvArImport => 'Importa';

  @override
  String get cvArEmptyTitle => 'Ancora nessun artefatto';

  @override
  String get cvArEmpty1 =>
      'Un artefatto è un\'app HTML in un file solo che un agente fa in un turno: un calcolatore, il tabellone di un torneo, un gioco, un visualizzatore per un CSV. Gira nel Canvas, in un riquadro isolato, senza installare nulla e senza andare in rete.';

  @override
  String get cvArEmpty2 =>
      'Vive come file nella cartella artefatti/ di un progetto (o di God e degli assistenti), quindi lo trovi anche fra i file a destra. Per averne uno chiedi a un agente uno strumento da tenere e riusare; oppure importa un .rgartifact da un altro Rasgeth.';

  @override
  String get cvArPlacePlatform => 'Cartella di God';

  @override
  String get cvArPlaceAssistants => 'Scrivania degli assistenti';

  @override
  String get cvArOpen => 'Apri';

  @override
  String get cvArExport => 'Esporta';

  @override
  String get cvArDelete => 'Elimina';

  @override
  String cvArVersion(String n) {
    return 'versione $n';
  }

  @override
  String get cvArNoHeader => 'senza intestazione';

  @override
  String cvArLibs(String libs) {
    return 'librerie: $libs';
  }

  @override
  String cvArFrom(String who) {
    return 'da $who';
  }

  @override
  String get cvArPending => 'Importato · non ancora eseguito';

  @override
  String get cvArReadOnly => 'sola lettura: il progetto è archiviato';

  @override
  String cvArDeleteQ(String name) {
    return 'Eliminare «$name»?';
  }

  @override
  String get cvArDeleteText =>
      'Il file va nel cestino della sua cartella, come dall\'esplora file.';

  @override
  String cvArExportTitle(String name) {
    return 'Esporta «$name»';
  }

  @override
  String get cvArExportZip => 'Un file .rgartifact';

  @override
  String get cvArExportZipText =>
      'Per importarlo in un altro Rasgeth: l\'app, il suo manifesto e l\'impronta che controlla che arrivi intatta. Non porta con sé nessun permesso.';

  @override
  String get cvArExportHtml => 'Scarica come HTML';

  @override
  String get cvArExportHtmlText =>
      'Per aprirlo altrove. Attenzione: fuori da Rasgeth gira senza il riquadro isolato, con i permessi della pagina in cui lo apri.';

  @override
  String get cvArWhereQ => 'Dove lo metto?';

  @override
  String get cvArWhereLead =>
      'Va nella cartella artefatti/ del posto che scegli. Parte senza permessi e la prima volta si apre sul sorgente, con «Esegui».';

  @override
  String cvArImported(String name, String place) {
    return '«$name» importato in $place: la prima volta si apre sul sorgente, con «Esegui».';
  }

  @override
  String get cvArDataIgnored => 'I dati salvati che porta con sé non sono stati importati.';

  @override
  String get cvArDataImported => 'Sono arrivati anche i suoi dati salvati.';

  @override
  String get cvArHasData => 'ha dati salvati';

  @override
  String get cvArExportData => 'Includi i dati salvati';

  @override
  String get cvArExportDataHint =>
      'Ciò che l\'app ha tenuto su Rasgeth (la sua memoria). Lascialo spento per una copia pulita, senza i tuoi dati.';

  @override
  String get cvArPerms => 'Permessi';

  @override
  String cvArWants(String what) {
    return 'Chiede di $what';
  }

  @override
  String get cvArPermGranted => 'concesso';

  @override
  String get cvArPermNot => 'non concesso';

  @override
  String get cvArGrant => 'Concedi';

  @override
  String get cvArRevoke => 'Togli';

  @override
  String cvArSpent(String spent, String cap) {
    return 'spesi $spent di $cap';
  }

  @override
  String get sectionArtifacts => 'ARTEFATTI';

  @override
  String get artifactsRowHint =>
      'Le app fatte dagli agenti: apri, esporta, importa, elimina e i loro permessi';

  @override
  String get cvVwToChat => 'Chat';

  @override
  String get sideTabFiles => 'File';

  @override
  String get sideTabCanvas => 'Nebula';

  @override
  String get sideTabsLabel => 'Cosa mostra la colonna a destra';

  @override
  String get chatFileDownload => 'Scarica';

  @override
  String get chatAttachmentDownload => 'Scarica l\'allegato';

  @override
  String chatFileDownloading(String name) {
    return 'Scarico $name';
  }

  @override
  String chatFileDownloadOf(String done, String total, String speed, String left) {
    return '$done di $total · $speed/s · ancora $left';
  }

  @override
  String chatFileDownloadSoFar(String done, String speed) {
    return '$done · $speed/s';
  }

  @override
  String chatFileSaved(String name) {
    return 'Salvato: $name';
  }

  @override
  String chatFileDownloadFailed(String name) {
    return 'Non sono riuscito a scaricare $name';
  }

  @override
  String get cvSubMain => 'Agente principale';

  @override
  String get cvSubPath => 'Dove sei';

  @override
  String get cvSubRow => 'Sotto-agenti';

  @override
  String get cvSubOpenTab => 'Apri la scheda';

  @override
  String get cvSubStatusRunning => 'Lavora';

  @override
  String get cvSubStatusDone => 'Finito';

  @override
  String get cvSubStatusFailed => 'Fallito';

  @override
  String get cvSubStatusStopped => 'Fermato';

  @override
  String get cvSubFresh => 'Novità';

  @override
  String get cvSubWaits => 'Aspetta il tuo sì';

  @override
  String get cvSubClose => 'Chiudi la scheda';

  @override
  String get cvSubTask => 'Compito ricevuto';

  @override
  String cvSubTaskFrom(String name) {
    return 'Compito da «$name»';
  }

  @override
  String get cvSubEndedDone =>
      'Ha finito: il suo resoconto è tornato all\'agente che l\'ha lanciato.';

  @override
  String get cvSubEndedFailed => 'Non ha portato a termine il compito.';

  @override
  String get cvSubEndedStopped => 'È stato fermato.';

  @override
  String get cvSubInterrupted => 'Interrotto: il server si è fermato mentre lavorava.';

  @override
  String cvSubTime(String time) {
    return '$time';
  }

  @override
  String cvSubTools(String n) {
    return '$n strumenti';
  }

  @override
  String cvSubTokens(String n) {
    return '$n token';
  }

  @override
  String get cvSubNoWrite => 'Prende ordini solo dall\'agente che l\'ha lanciato';

  @override
  String get cvSubStop => 'Ferma';

  @override
  String get cvCmdStrip => 'Comandi in background';

  @override
  String cvCmdRunningN(String n) {
    return '$n in corso';
  }

  @override
  String cvCmdDoneN(String n) {
    return '$n finiti';
  }

  @override
  String get cvCmdOpenStrip => 'Mostra i comandi in background';

  @override
  String get cvCmdShrinkStrip => 'Riduci a una riga';

  @override
  String cvCmdStartedAt(String at) {
    return 'Partito alle $at';
  }

  @override
  String get cvCmdOutput => 'Output';

  @override
  String get cvCmdStop => 'Ferma';

  @override
  String cvCmdFinishedN(String n) {
    return '$n comandi finiti';
  }

  @override
  String get cvCmdRemoveFinished => 'Togli tutti i finiti';

  @override
  String get cvCmdRemove => 'Togli';

  @override
  String get cvCmdStatusRunning => 'in corso';

  @override
  String cvCmdStatusDone(String code) {
    return 'codice d\'uscita $code';
  }

  @override
  String cvCmdStatusFailed(String code) {
    return 'fallito, codice d\'uscita $code';
  }

  @override
  String get cvCmdStatusStopped => 'fermato';

  @override
  String get cvCmdStatusInterrupted => 'interrotto (Rasgeth si era fermato)';

  @override
  String get cvCmdOutputTitle => 'Comando in background';

  @override
  String get cvCmdStarted => 'Partito';

  @override
  String get cvCmdEnded => 'Finito';

  @override
  String get cvCmdFolder => 'Cartella';

  @override
  String get cvCmdBy => 'Lanciato da';

  @override
  String get cvCmdShowTimes => 'Orario di ogni riga';

  @override
  String cvCmdLines(String n) {
    return '$n righe';
  }

  @override
  String get cvCmdNoLog => 'Il suo registro non c\'è più.';

  @override
  String get cvRoomAdd => 'Aggiungi un agente';

  @override
  String cvRoomAnswering(String names) {
    return '$names sta rispondendo…';
  }

  @override
  String get cvRoomEmpty =>
      'Scrivi a tutti: risponde il primo, oppure chiama qualcuno con @nome. Aggiungere un agente non gli dà nessun accesso in più: quello che scrivono gli altri gli arriva come informazione.';

  @override
  String get cvRoomFirst => 'risponde per primo';

  @override
  String get cvRoomGone => 'Questa chat di gruppo non esiste più.';

  @override
  String get cvRoomGroupPersonal => 'Tuoi';

  @override
  String cvRoomInspector(String project) {
    return 'Inspector di $project';
  }

  @override
  String cvRoomLead(String project) {
    return 'Capo di $project';
  }

  @override
  String get cvRoomPick => 'Chi?';

  @override
  String cvRoomRemove(String name) {
    return 'Togli $name dalla chat';
  }

  @override
  String get cvRoomUsageHint =>
      'Quanto sono costate le sue risposte qui, e quanto è pieno il suo contesto';

  @override
  String get cvRoomWrite => 'Scrivi al gruppo (@ per chiamare qualcuno)';

  @override
  String cvRoomJoined(String name) {
    return '$name è entrato nella chat';
  }

  @override
  String cvRoomLeft(String name) {
    return '$name è uscito dalla chat';
  }

  @override
  String get cvGroups => 'Gruppi';

  @override
  String get cvGroupsEmpty =>
      'Più agenti in una chat: «Aggiungi un agente» in qualunque conversazione.';

  @override
  String get cvGroupNew => 'Nuovo gruppo';

  @override
  String cvChatsArchived(String n) {
    return 'Archiviate ($n)';
  }

  @override
  String get cvChatsBefore => 'Chat di prima';

  @override
  String get cvArchive => 'Archivia';

  @override
  String get cvUnarchive => 'Riporta';

  @override
  String get cvChatHint =>
      'Chiedi quello che vuoi: la Chat cerca sul web e cita le fonti, crea file, pagine e immagini e te li mostra, e ti propone varianti tra cui scegliere.';

  @override
  String get cvNewChat => 'Nuova chat';

  @override
  String get cvDailyChat => 'Chat';

  @override
  String get cvDelete => 'Elimina';

  @override
  String get cvDeleteChatConfirm => 'Eliminare questa chat per sempre?';

  @override
  String get cvChatToGroup =>
      'Continua in gruppo: aggiungi un agente, che riceve questa chat come contesto';

  @override
  String get cvAgentModelDefault => 'Il modello predefinito';

  @override
  String get cvInspector => 'Inspector';

  @override
  String get cvInspectorHint =>
      'Chiedi all\'inspector di questo progetto: legge file, git, il log delle attività, i task, la bacheca e il budget, e non cambia niente.';

  @override
  String get cvInspectorAlerts =>
      'Avvisami su Telegram quando qualcosa va storto (task abbandonato, budget superato, blocco, automazione fallita)';

  @override
  String get cvInspectorSummary => 'Riepilogo del giorno alle';

  @override
  String get cvFolderMove => 'Sposta in una cartella';

  @override
  String get cvFolderNew => 'Nuova cartella…';

  @override
  String get cvFolderName => 'Nome della cartella';

  @override
  String get cvFolderOut => 'Toglila dalla cartella';

  @override
  String get cvExportMd => 'Esporta in Markdown';

  @override
  String get cvBoard => 'Bacheca';

  @override
  String get cvNewThread => 'Nuovo thread';

  @override
  String get cvTitle => 'Titolo';

  @override
  String get cvReply => 'Rispondi';

  @override
  String get cvSearch => 'Cerca';

  @override
  String get cvSummary => 'Riassunto';

  @override
  String get cvResolve => 'Risolvi';

  @override
  String get cvBlock => 'Blocca';

  @override
  String get cvReopen => 'Riapri';

  @override
  String get cvPostKinds => 'task,result,question,decision,blocker,note';

  @override
  String get cvPostKindLabels => 'task,risultato,domanda,decisione,blocco,nota';

  @override
  String get cvStatusOpen => 'aperto';

  @override
  String get cvStatusResolved => 'risolto';

  @override
  String get cvStatusBlocked => 'bloccato';

  @override
  String get cvEmptyBoard => 'Ancora nessun thread.';

  @override
  String get cvNoResults => 'Nessun risultato.';

  @override
  String get cvAgentWholeProject => 'Tutto il progetto';

  @override
  String get cvBoardSub => 'Sottoprogetto';

  @override
  String get cvYou => 'Tu';

  @override
  String get cvScreenTitle => 'Browser degli agenti';

  @override
  String get cvScreenOpen => 'Schermo';

  @override
  String get cvScreenTake => 'Prendi il controllo';

  @override
  String get cvScreenGiveBack => 'Restituisci agli agenti';

  @override
  String get cvScreenAddress => 'Indirizzo web';

  @override
  String get cvScreenShared =>
      'Il browser che i tuoi agenti personali condividono: accedi una volta e tutti possono usare quel sito. Prendi il controllo per accedere: quello che scrivi va solo alla pagina, mai a un agente.';

  @override
  String get cvScreenYours =>
      'Ce l\'hai tu: gli agenti aspettano. Clicca e scrivi sullo schermo; restituiscilo quando hai finito.';

  @override
  String get cvScreenStarting => 'Avvio il browser…';

  @override
  String get cvScreenUnavailable =>
      'Il browser degli agenti richiede l\'installazione di Rasgeth con Docker.';

  @override
  String get cvTeachStart => 'Insegna un compito';

  @override
  String get cvTeachHint =>
      'Fai tu il compito una volta: ogni pagina, clic e testo viene annotato (mai le password), poi l\'agente ne fa una skill che approvi in Estensioni';

  @override
  String get cvTeachWho => 'Quale agente lo impara';

  @override
  String cvTeachRecording(String name) {
    return 'Registro per $name: fai il compito, poi premi Fine. Le password non vengono mai annotate.';
  }

  @override
  String get cvTeachDone => 'Fine';

  @override
  String get cvTeachTitle => 'Come si chiama questo compito? (facoltativo)';

  @override
  String get cvChatPlaceholder =>
      'Scrivi un messaggio (Invio per mandare, Maiusc+Invio per andare a capo)';

  @override
  String get cvConversations => 'Conversazioni';

  @override
  String get cvChatInstructions => 'Le istruzioni della Chat';

  @override
  String get termOpenAgain => 'Apri di nuovo';

  @override
  String get termKeyLeft => 'Freccia a sinistra';

  @override
  String get termKeyUp => 'Freccia in su';

  @override
  String get termKeyDown => 'Freccia in giù';

  @override
  String get termKeyRight => 'Freccia a destra';

  @override
  String get termPaste => 'Incolla';

  @override
  String get termShowKeyboard => 'Mostra la tastiera';

  @override
  String get termHideKeyboard => 'Nascondi la tastiera';

  @override
  String get spTitle => 'Sottoprogetti';

  @override
  String get spNew => 'Nuovo sottoprogetto';

  @override
  String spNewTitle(String name) {
    return 'Nuovo sottoprogetto in «$name»';
  }

  @override
  String get spNoTeam => 'nessun agente';

  @override
  String spTeam(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n agenti',
      one: '1 agente',
    );
    return '$_temp0';
  }

  @override
  String get spNoAgents => 'Ancora nessun agente: crealo dagli agenti del progetto.';

  @override
  String get spFiles => 'File del sottoprogetto';

  @override
  String get spFrom => 'Nuovo o esistente';

  @override
  String get spNewOne => 'Un sottoprogetto nuovo';

  @override
  String spBringInName(String name) {
    return 'Porta dentro il progetto $name';
  }

  @override
  String get spBringInTitle => 'Portare dentro il progetto?';

  @override
  String get spBringIn => 'Porta dentro';

  @override
  String get spAdoptConfirm =>
      'Il progetto entra in questo come sottoprogetto: il suo codice (con la sua storia) nella cartella, i suoi agenti sotto il capo di questo progetto, anche la bacheca e le conversazioni. La sua vecchia cartella resta come copia. Procedo?';

  @override
  String get spName => 'Nome del sottoprogetto';

  @override
  String get spDir => 'Cartella (facoltativa)';

  @override
  String get spDirHelp =>
      'Dentro il progetto, per esempio apps/shop. Vuota: una cartella nuova con il nome. Va bene anche una cartella che esiste già.';

  @override
  String get spImage => 'Immagine della sandbox tutta sua (facoltativa)';

  @override
  String get spImageHelp =>
      'Per strumenti che la sandbox del progetto non ha, come ghcr.io/cirruslabs/flutter:stable. L\'immagine deve avere bash.';

  @override
  String get spCreate => 'Crea';

  @override
  String get psTitle => 'Progetti';

  @override
  String get psRowHint => 'Archivia, ripristina, inizializza git';

  @override
  String get psNewProject => 'Nuovo';

  @override
  String get psLead =>
      'Archivia un progetto su cui non lavori: esce dagli elenchi, niente viene cancellato e torna com\'era.';

  @override
  String get psInUse => 'In uso';

  @override
  String get psNone => 'Ancora nessun progetto.';

  @override
  String get psArchived => 'Archiviati';

  @override
  String get psArchivedLead =>
      'In sola lettura. «Ripristina» rimette il progetto com\'era, con le sue automazioni.';

  @override
  String get psNoneArchived => 'Nessun progetto archiviato.';

  @override
  String get csEyebrow => 'Codice';

  @override
  String get csTitle => 'Dove sta il codice';

  @override
  String get csRowHint => 'GitHub, Gitea e le repository dei progetti';

  @override
  String get csQuestion => 'Dove sta il codice?';

  @override
  String get csPurpose =>
      'Ogni progetto ha una repository privata, pronta perché gli agenti ci mandino il lavoro. Scegli GitHub, un Gitea tutto tuo su questo computer, o tutti e due. Facoltativo.';

  @override
  String get csGithubTile =>
      'Le repository stanno sul tuo account GitHub. Serve un token con il permesso di crearle.';

  @override
  String get csGiteaTitle => 'Un Gitea tutto tuo';

  @override
  String get csGiteaTile =>
      'Un piccolo GitHub privato su questo computer, installato e avviato da Rasgeth, oppure il Gitea che hai già.';

  @override
  String get csLinked => 'collegato';

  @override
  String get csBoth =>
      'Con tutti e due: il codice sta su Gitea, e ogni modifica viene copiata su GitHub da sola.';

  @override
  String get csProjects => 'Progetti che hai già';

  @override
  String get csProjectsHint =>
      'I progetti nuovi hanno la loro repository da soli. Per quelli fatti prima:';

  @override
  String get csSync => 'Crea adesso le repository';

  @override
  String get csSynced => 'repository pronta';

  @override
  String get csDone => 'Fatto';

  @override
  String get csDisconnect => 'Scollega';

  @override
  String get csTryAndSave => 'Prova e salva';

  @override
  String get csGithubHint =>
      'Con un token che crei tu su GitHub: Rasgeth crea le repository e gli agenti ci mandano il codice. Il token resta a Rasgeth, mai nelle scatole degli agenti.';

  @override
  String csGithubLinked(String login) {
    return 'Collegato come @$login';
  }

  @override
  String get csGithubStep1 =>
      'Apri la pagina di GitHub per un nuovo token (accedi se te lo chiede):';

  @override
  String get csGithubOpen => 'Nuovo token su GitHub';

  @override
  String get csGithubStep2 => 'Compilala così:';

  @override
  String get csPermName => 'Token name: Rasgeth';

  @override
  String get csPermExpiry => 'Expiration: un anno (Rasgeth te lo ricorda prima che scada)';

  @override
  String get csPermRepos => 'Repository access: All repositories';

  @override
  String get csPermList =>
      'Permissions, Repositories: Administration, Contents, Issues e Pull requests su Read and write';

  @override
  String get csGithubStep3 => 'Premi Generate token in fondo, copialo e incollalo qui';

  @override
  String get csGithubTokenHelp => 'Comincia con github_pat_. GitHub lo mostra una volta sola.';

  @override
  String get csGiteaHint =>
      'Un server Git tutto tuo, su questo computer: le repository restano qui e le guardi nel browser come su GitHub. Rasgeth lo avvia e lo tiene aggiornato. Oppure collega un Gitea che hai già.';

  @override
  String get csGiteaKind => 'Quale Gitea';

  @override
  String get csGiteaKindOwn => 'Avvialo qui';

  @override
  String get csGiteaKindExisting => 'Un Gitea che hai già';

  @override
  String get csGiteaUrl => 'L\'indirizzo del tuo Gitea';

  @override
  String get csGiteaUrlHelp => 'Come lo apri nel browser, per esempio https://git.example.org.';

  @override
  String get csGiteaExtUser => 'Il tuo nome utente lì';

  @override
  String get csGiteaToken => 'Un token di accesso';

  @override
  String get csGiteaTokenHelp =>
      'Su Gitea: Impostazioni › Applicazioni › Genera token, con lettura e scrittura su repository e utente. Resta nel Portachiavi, mai in un file.';

  @override
  String get csGiteaConnect => 'Prova e collega';

  @override
  String csGiteaLinked(String url, String user) {
    return 'Collegato a $url, utente $user';
  }

  @override
  String get csGiteaUser => 'Il tuo nome utente su Gitea';

  @override
  String get csGiteaUserHelp => 'Lettere, numeri, punti, trattini; per esempio mario.';

  @override
  String get csGiteaPassword => 'Una password per Gitea';

  @override
  String get csGiteaPasswordHelp => 'Almeno 10 caratteri. Ti serve per aprire Gitea nel browser.';

  @override
  String get csGiteaAgain => 'La stessa password, di nuovo';

  @override
  String get csGiteaMismatch => 'Le due password sono diverse.';

  @override
  String get csGiteaCreate => 'Crea il mio Gitea';

  @override
  String csGiteaReady(String user) {
    return 'Gitea è pronto, utente $user';
  }

  @override
  String get csGiteaOpen => 'Apri Gitea';

  @override
  String get csGiteaStop => 'Spegni';

  @override
  String csGiteaNameNotFound(String host) {
    return 'Rasgeth non trova $host: il DNS che usa non conosce quel nome. La guida «I tuoi servizi di casa» in Impostazioni › Accesso da fuori casa dice cosa aggiungere e ti fa provare il nome.';
  }

  @override
  String csGiteaHostUnreachable(String host) {
    return 'Rasgeth trova $host, ma da qui il suo indirizzo non risponde (un indirizzo Tailscale, un\'altra rete?). La guida «I tuoi servizi di casa» in Impostazioni › Accesso da fuori casa dice come sistemare.';
  }

  @override
  String get csJobGitea => 'Avvio di Gitea';

  @override
  String get csJobGiteaImage => 'Scarico Gitea (una volta sola)';

  @override
  String get csJobGiteaStart => 'Avvio Gitea';

  @override
  String get csJobAccount => 'Creo il tuo account';

  @override
  String get csNotNeeded => 'non serve';

  @override
  String get csJobDone => 'Fatto.';

  @override
  String get csJobFailed =>
      'Qualcosa non è andato. Riprova; se succede ancora, i dettagli qui sotto aiutano chi ti dà una mano.';

  @override
  String get g4SfSkillsAsk => 'Fammele vedere prima';

  @override
  String get g4SfSkillsAskText =>
      'Una skill provata aspetta in Impostazioni › Estensioni finché non la approvi.';

  @override
  String get g4SfSkillsAuto => 'Installale quando passano le prove';

  @override
  String get g4SfSkillsAutoText =>
      'Una skill che passa le sue prove è subito pronta; puoi toglierla da Estensioni.';

  @override
  String get g4SfGuardianTitle => 'Il guardiano';

  @override
  String get g4SfGuardianAskText =>
      'Un file nella tua home, una cartella di sistema, un altro progetto: l\'agente si ferma e te lo chiede, sul web o su Telegram. Leggere è sempre libero.';

  @override
  String get g4SfGuardianAutoText =>
      'Gli agenti scrivono dove serve senza chiedere. Gli altri pericoli che scegli qui sotto chiedono comunque.';

  @override
  String get g4SfCareful => 'Prudente';

  @override
  String get g4SfCarefulText =>
      'Ogni azione rischiosa aspetta te. La scelta più sicura, anche la più lenta.';

  @override
  String get g4SfBalanced => 'Equilibrata';

  @override
  String get g4SfBalancedText =>
      'Approvi tu quello che non si può annullare (pubblicare, storia del codice, dischi, password, modifiche a Rasgeth); il resto lo approvano gli agenti che guidano.';

  @override
  String get g4SfFree => 'Libera';

  @override
  String get g4SfFreeText =>
      'Gli agenti che guidano approvano quasi tutto; a te chiedono solo per le password e per cambiare Rasgeth stesso.';

  @override
  String get g4SfPersonalize => 'Personalizza';

  @override
  String get g4SfNoLimit => 'nessun limite';

  @override
  String get g4SfNothingPaid =>
      'Usi solo abbonamenti o modelli locali: niente si paga a consumo, quindi non c\'è un limite di spesa da mettere. Con gli abbonamenti contano i limiti del piano (li vedi in alto).';

  @override
  String get g4SfKeepForever => 'sempre';

  @override
  String get g4SfKeep365 => 'un anno';

  @override
  String get g4SfKeep90 => 'tre mesi';

  @override
  String get g4SfKeep30 => 'un mese';

  @override
  String get g4SfDoneBtn => 'Fatto';

  @override
  String get g4SfLead =>
      'Quattro decisioni, ognuna in una scheda. Cambi tutto quando vuoi dalle Impostazioni.';

  @override
  String get g4SfGuardQ => 'Un agente vuole scrivere fuori dal suo progetto. Cosa succede?';

  @override
  String get g4SfGuardAsk => 'Mi chiede';

  @override
  String get g4SfGuardAuto => 'Lo lascio fare';

  @override
  String get g4SfApprTitle => 'Le approvazioni';

  @override
  String get g4SfApprQ =>
      'Chi dice sì prima di un\'azione rischiosa, come cancellare o pubblicare?';

  @override
  String g4SfApprCustom(int n, String of) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Una scelta tua: $n cose su $of le approvi solo tu.',
      one: 'Una scelta tua: 1 cosa su $of la approvi solo tu.',
    );
    return '$_temp0';
  }

  @override
  String get g4SfCustomTitle => 'Cosa approvi solo tu';

  @override
  String g4SfCustomLead(String god) {
    return 'Prima di queste azioni un agente chiede. Acceso: lo puoi approvare solo tu. Spento: può dire sì anche l\'agente che lo guida ($god o il capo del progetto).';
  }

  @override
  String g4SfBackTo(String preset) {
    return 'Torna a $preset';
  }

  @override
  String get g4SfBudgetTitle => 'Il limite di spesa';

  @override
  String get g4SfBudgetQ => 'Quanto può spendere Rasgeth al massimo con le tue chiavi API?';

  @override
  String get g4SfBudgetQFree =>
      'Con le chiavi API un limite ferma gli agenti prima che spendano troppo.';

  @override
  String get g4SfBudgetOther => 'altro';

  @override
  String g4SfBudgetSay(String usd) {
    return 'Arrivato a \$$usd, gli agenti si fermano e te lo dicono; lo alzi quando vuoi.';
  }

  @override
  String get g4SfBudgetNone => 'Nessun limite: occhio alle chiavi a consumo.';

  @override
  String get g4SfSkillsTitle => 'Le skill degli agenti';

  @override
  String get g4SfSkillsQ =>
      'Dopo un problema difficile un agente può salvare come l\'ha risolto, per tutti. Le installo da solo?';

  @override
  String get g4SfSkillsTools => 'Gli strumenti che eseguono codice aspettano sempre te.';

  @override
  String get g4SfWhereAgents =>
      'Gli agenti lavorano direttamente su questo computer, nella cartella del progetto: il guardiano controlla ogni comando che esce da lì.';

  @override
  String get g4SfKeepFor => 'Tieni le conversazioni per';

  @override
  String get g4TlSection => 'Strumenti';

  @override
  String get g4TlQ => 'Quali strumenti hanno gli agenti?';

  @override
  String get g4TlLead =>
      'Ogni strumento viene descritto al modello a ogni messaggio, e questo costa token. Spegni quelli che non ti servono: per tutti gli agenti qui, oppure per un agente solo dalla sua finestra, scheda Strumenti.';

  @override
  String get g4TlNewOnly =>
      'Le modifiche valgono dalle conversazioni nuove: quelle già aperte tengono i loro strumenti.';

  @override
  String g4TlTotal(String n) {
    return 'Circa $n token a ogni messaggio';
  }

  @override
  String g4TlSaved(String n) {
    return 'Spenti: $n token risparmiati a ogni messaggio';
  }

  @override
  String get g4TlNoneSaved => 'Niente spento';

  @override
  String g4TlWeight(String n) {
    return 'circa $n token a ogni messaggio';
  }

  @override
  String g4TlNeeded(String why) {
    return 'Serve sempre: $why';
  }

  @override
  String get g4TlLoading => 'Peso gli strumenti…';

  @override
  String get g4TlSearch => 'Cerca uno strumento: nome, comando o cosa fa';

  @override
  String g4TlNoMatch(String q) {
    return 'Nessuno strumento per «$q».';
  }

  @override
  String g4TlError(String error) {
    return 'Non riesco a leggere gli strumenti: $error';
  }

  @override
  String g4TlHowMany(String all, String on) {
    return '$on su $all accesi';
  }

  @override
  String g4TlExceptOn(String names) {
    return 'Acceso lo stesso per: $names (scelta loro)';
  }

  @override
  String g4TlExceptOff(String names) {
    return 'Spento per: $names (scelta loro)';
  }

  @override
  String get g4TlExceptReset => 'Come per tutti';

  @override
  String get g4CmSection => 'Comandi';

  @override
  String get g4CmOneDay => '1 giorno';

  @override
  String g4CmDays(String n) {
    return '$n giorni';
  }

  @override
  String g4CmHours(String n) {
    return '$n ore';
  }

  @override
  String get g4CmOneHour => '1 ora';

  @override
  String g4CmMinutes(String n) {
    return '$n min';
  }

  @override
  String get g4CmNoLimit => 'Senza limite';

  @override
  String get g4CmPageQ => 'Quanto possono durare i comandi degli agenti?';

  @override
  String get g4CmPageLead =>
      'Gli agenti lanciano comandi su questo computer: alcuni finiscono subito, altri (un server di sviluppo, un controllo dei file, una build lunga) restano accesi in sottofondo mentre l\'agente fa altro.';

  @override
  String get g4CmBgTitle => 'Comandi in sottofondo';

  @override
  String get g4CmBgLead =>
      'Server, controlli dei file e build lunghe. Li vedi nella striscia sopra la casella del messaggio e lì puoi fermarli.';

  @override
  String get g4CmAtOnce => 'Insieme in una conversazione';

  @override
  String get g4CmAtOnceHelp =>
      'Raggiunto il limite, l\'agente deve fermarne uno prima di avviarne un altro.';

  @override
  String get g4CmAtOnceWarn =>
      'Senza limite: un agente può avviarne quanti vuole. Ognuno usa processore e memoria; se il computer rallenta, fermane qualcuno dalla striscia.';

  @override
  String get g4CmLong => 'Quanto può durare uno';

  @override
  String get g4CmLongHelp => 'Passato questo tempo il comando si ferma da solo.';

  @override
  String get g4CmLongWarn =>
      'Senza limite: un comando resta acceso finché tu o l\'agente lo fermate, anche per giorni. Va bene per un server di sviluppo; ricordati di fermare quello che non ti serve più.';

  @override
  String get g4CmLog => 'Quanto può crescere il suo registro';

  @override
  String get g4CmLogHelp =>
      'Ogni riga è tenuta con la sua ora. Oltre questa misura se ne va la metà più vecchia.';

  @override
  String get g4CmLogWarn =>
      'Senza limite: un comando che scrive molto può riempire il disco col tempo. I registri sono nella cartella .redgiant/commands del progetto.';

  @override
  String get g4CmBashTitle => 'Comandi normali';

  @override
  String get g4CmBashLead =>
      'Quelli che l\'agente aspetta prima di andare avanti (test, un\'installazione, una conversione).';

  @override
  String get g4CmBash => 'Attesa più lunga';

  @override
  String get g4CmBashHelp =>
      'L\'agente può chiedere meno, mai di più. Per lavori più lunghi usa il sottofondo.';

  @override
  String get g4CmStepsTitle => 'Passi in un turno';

  @override
  String get g4CmStepsLead =>
      'In un turno un agente ragiona, usa uno strumento, legge il risultato e va avanti. Oltre il limite si ferma e ti dice a che punto è; il pulsante «Continua» sotto il suo messaggio lo fa andare avanti.';

  @override
  String get g4CmSteps => 'Passi al massimo';

  @override
  String g4CmStepsHelp(String n) {
    return 'Un passo è una chiamata al modello. Predefinito: nessun limite nelle conversazioni con te; $n per automazioni e compiti, che nessuno guarda. Un numero o «Nessun limite» vale per tutti i turni.';
  }

  @override
  String get g4CmStepsDefault => 'Predefinito';

  @override
  String get g4CmStepsWarn =>
      'Senza limite, anche per automazioni e compiti: un agente può lavorare per ore in un solo turno. Lo fermano solo i budget: tienine uno attivo (Impostazioni, Budget) se il modello costa.';

  @override
  String get g4CmDefaults => 'Torna ai predefiniti';

  @override
  String get g4CmSaved => 'Salvato: vale dal prossimo comando e dal prossimo messaggio.';

  @override
  String get g4CmUndo => 'Annulla';

  @override
  String get g4CmUndone => 'Annullato: sono tornati i valori di prima.';

  @override
  String get g4RqSection => 'Richieste a te';

  @override
  String get g4RqPageQ => 'Quando un agente ha bisogno di te';

  @override
  String get g4RqPageLead =>
      'Gli agenti chiedono prima delle azioni rischiose, ti fanno domande, propongono piani, chiedono uno strumento o una chiave. Scegli se devono chiederlo a te, e quanto ti aspettano.';

  @override
  String get g4RqModeTitle => 'Chiedermelo o no';

  @override
  String get g4RqModeQ => 'Vuoi rispondere tu alle richieste degli agenti?';

  @override
  String get g4RqModeAsk => 'Chiedimelo';

  @override
  String get g4RqModeClassifier => 'Non chiedermi niente';

  @override
  String get g4RqAlwaysYou =>
      'Anche con «Non chiedermi niente», le richieste davvero pericolose arrivano sempre a te, ovunque: cancellazioni definitive, file di sistema, segreti che escono, pagamenti veri e le protezioni di Rasgeth.';

  @override
  String get g4RqModeAskText =>
      'Le richieste ti arrivano ovunque: qui e sulle chat collegate. Rispondi dove ti è comodo: vale la prima risposta, e le altre copie si chiudono da sole.';

  @override
  String get g4RqModeClassifierText =>
      'Non ti arriva niente: decide il classificatore, un modello che scegli tu. Legge ogni richiesta con la conversazione e scrive perché ha deciso così. Solo le cose davvero pericolose (quelle qui sotto) ti arrivano comunque, ovunque.';

  @override
  String get g4RqModeClassifierWarn =>
      'Il classificatore può sbagliare, e ogni decisione costa una piccola richiesta al suo modello.';

  @override
  String get g4RqTimeTitle => 'Tempo per rispondere';

  @override
  String get g4RqTimeQ => 'Quanto deve aspettare un agente la tua risposta?';

  @override
  String get g4RqTimeQSpecial => 'Quanto aspettano la tua risposta le cose davvero pericolose?';

  @override
  String g4RqAfterSpecialText(String time) {
    return 'Se non rispondi entro $time, è un no.';
  }

  @override
  String get g4RqTimeNoneSpecial =>
      'Aspettano quanto serve: l\'agente resta fermo finché non rispondi.';

  @override
  String get g4RqSpecialTitle => 'Le cose davvero pericolose';

  @override
  String get g4RqSpecialQ => 'Cosa ti arriva sempre, ovunque tu sia?';

  @override
  String get g4RqSpecialText =>
      'Solo queste. Quando un agente sta per farne una si ferma e aspetta te: la richiesta ti arriva qui e sulle chat collegate, anche con «Non chiedermi niente», e il classificatore non la decide mai.';

  @override
  String get g4RqSpecialNot =>
      'Il lavoro di tutti i giorni non è in questo elenco: mandare il codice con git push, un messaggio o una email normale, mettere online un sito, cambiare i file del progetto, usare una chiave del portachiavi per il suo sito. Questi seguono la tua scelta qui sopra.';

  @override
  String get g4RqCriticalExamples => 'Per esempio:';

  @override
  String get g4RqTimeNone =>
      'L\'agente aspetta quanto serve. Le richieste di accendere uno strumento o di usare una chiave finiscono comunque dopo 15 e 10 minuti.';

  @override
  String g4RqAfterQ(String time) {
    return 'Se non rispondi entro $time:';
  }

  @override
  String get g4RqAfterNo => 'È un no';

  @override
  String get g4RqAfterClassifier => 'Decide il classificatore';

  @override
  String get g4RqAfterNoText =>
      'Un\'approvazione che nessuno dà è sempre un no. A una domanda l\'agente va avanti con la sua ipotesi migliore e ti dice quale.';

  @override
  String get g4RqAfterClassifierText =>
      'Allo scadere decide il classificatore al posto tuo, come con «Non chiedermi niente». Le cose davvero pericolose invece diventano un no.';

  @override
  String get g4RqClassifierTitle => 'Il classificatore';

  @override
  String get g4RqClassifierQ => 'Quale modello decide per te?';

  @override
  String get g4RqClassifierModel => 'Modello';

  @override
  String g4RqClassifierDefault(String model) {
    return 'Il modello leggero ($model)';
  }

  @override
  String get g4RqClassifierHow =>
      'Legge cosa chiede l\'agente, il suo compito e gli ultimi messaggi della conversazione; risponde sì o no con un motivo, o sceglie una risposta a una domanda. Nel dubbio dice no; se non riesce, è un no.';

  @override
  String get g4RqNoModel => 'nessuno collegato';

  @override
  String get g4RqSaved => 'Salvato: vale dalla prossima richiesta.';

  @override
  String get g4RqDoneTitle => 'Decise senza di te';

  @override
  String get g4RqDoneLead =>
      'Ogni richiesta decisa dal classificatore, o finita perché nessuno ha risposto in tempo, dalla più recente.';

  @override
  String get g4RqDoneEmpty => 'Ancora nessuna decisione presa senza di te.';

  @override
  String get g4RqOpenChat => 'Apri la conversazione';

  @override
  String g4RqByModel(String model) {
    return 'Classificatore ($model):';
  }

  @override
  String get g4RqByClassifier => 'Classificatore:';

  @override
  String get g4RqByTimeout => 'Tempo scaduto:';

  @override
  String get g4RqDecisionAllow => 'Sì';

  @override
  String get g4RqDecisionDeny => 'No';

  @override
  String get g4RqDecisionAnswered => 'Ha risposto';

  @override
  String get g4RqDecisionBlocked => 'Bloccata';

  @override
  String get g4RqKindApproval => 'azione';

  @override
  String get g4RqKindQuestion => 'domanda';

  @override
  String get g4RqKindPlan => 'piano';

  @override
  String get g4RqKindTool => 'strumento';

  @override
  String get g4RqKindCredential => 'chiave';

  @override
  String get g4RqKindAutomation => 'automazione';

  @override
  String get g4SfSaved => 'Salvato: vale dalla prossima azione degli agenti.';

  @override
  String get g4SfCustomOn => 'Lo approvi solo tu';

  @override
  String get g4CmAtWorkLead => 'Si salva subito, per i turni che partono da adesso.';

  @override
  String get g4RulesHub => 'Regole';

  @override
  String get g4TlExtLead =>
      'Installati da Estensioni (integrazioni magiche, proposte degli agenti, i tuoi): li ha ogni agente. Si cambiano o si tolgono lì.';

  @override
  String get g4TlExtTitle => 'Strumenti delle estensioni';

  @override
  String get g4SfTitle => 'Sicurezza e costi';

  @override
  String get g4GenAccount => 'Account';

  @override
  String get g4GenAgentInstructions => 'Le sue istruzioni';

  @override
  String get g4GenAgentLangAll => 'Tutte le lingue';

  @override
  String get g4GenAgentLangChange => 'cambia';

  @override
  String get g4GenAgentLangCommon => 'Le più usate';

  @override
  String get g4GenAgentLangHelp =>
      'La lingua in cui scrivono tutti gli agenti, la Chat e la memoria condivisa. Vale per le conversazioni nuove; quelle aperte tengono la loro.';

  @override
  String g4GenAgentLangNone(String q) {
    return 'Nessuna lingua corrisponde a «$q».';
  }

  @override
  String get g4GenAgentLangSearch => 'Cerca una lingua';

  @override
  String get g4GenAgentLangSub =>
      'Gli agenti rispondono in questa lingua dalla prossima conversazione.';

  @override
  String get g4GenAgentLangTitle => 'Lingua degli agenti';

  @override
  String get g4GenAgents => 'Per tutti gli agenti';

  @override
  String get g4GenAgentsLead =>
      'Quello che legge ogni agente, e chi riprova un task quando un agente si arrende.';

  @override
  String get g4GenAlreadySet => 'già impostata';

  @override
  String get g4GenBackupNone => 'Nessuno: un task abbandonato resta tale';

  @override
  String get g4GenBackupText =>
      'Un task su cui un agente si arrende viene riprovato una volta da questo modello, in una conversazione nuova.';

  @override
  String get g4GenBackupTitle => 'Modello di riserva per i task';

  @override
  String get g4GenCare => 'Aggiornamenti e diagnostica';

  @override
  String get g4GenCareLead =>
      'Se c\'è un Rasgeth più nuovo, e un registro da mandare quando qualcosa non va.';

  @override
  String g4GenCloudPrivacy(String name) {
    return 'Con $name, quello che dici dopo la parola di attivazione va a $name passando dal server di Rasgeth; la parola di attivazione resta riconosciuta solo in questa pagina.';
  }

  @override
  String get g4GenDebugClear => 'Cancella i registri';

  @override
  String get g4GenDebugClearConfirm => 'Cancellare tutti i registri tenuti?';

  @override
  String get g4GenDebugDownload => 'Scarica i registri';

  @override
  String get g4GenDebugForced => 'Accesa dalle impostazioni del server (REDGIANT_DEBUG=1).';

  @override
  String get g4GenDebugHelp =>
      'La modalità di debug tiene un registro dettagliato di tutto quello che fa Rasgeth: ogni passo dell\'avvio di un modello con i suoi tempi, i messaggi del motore locale, le richieste, quello che fa il programma di Windows. Accendila quando qualcosa è lento o va storto, ripeti l\'operazione, poi scarica i registri e mandali. Scrive tanto (al massimo 300 MB, i più vecchi se ne vanno) e non scrive mai password né chiavi.';

  @override
  String g4GenDebugSize(String size, String files) {
    return 'Registri tenuti: $size in $files file.';
  }

  @override
  String get g4GenDebugSwitch => 'Modalità di debug';

  @override
  String get g4GenDebugText =>
      'Tutto quello che fa Rasgeth, scritto in un registro da scaricare e mandare.';

  @override
  String get g4GenDebugTitle => 'Diagnostica';

  @override
  String get g4GenDraftDefaultUsed =>
      'Queste sono le istruzioni predefinite, con quello che hai scritto. Gli strumenti restano come per gli altri agenti.';

  @override
  String g4GenDraftFailed(String god, String why) {
    return '$god non è riuscito a scriverle ($why). Ecco quelle predefinite, con quello che hai scritto.';
  }

  @override
  String g4GenDraftLead(String god) {
    return '$god le scrive partendo da quelle predefinite, adattate a quello che hai scritto e alle sue impostazioni, e sceglie gli strumenti che gli servono. Leggi, cambia quello che vuoi, poi crealo.';
  }

  @override
  String get g4GenDraftRegenerate => 'Rigenera';

  @override
  String get g4GenDraftToolOnDefault => 'utile per il suo lavoro';

  @override
  String get g4GenDraftToolsAllOn => 'Tutti gli strumenti accesi, come per gli altri agenti.';

  @override
  String get g4GenDraftToolsLikeOthers => 'Tutti come per gli altri agenti';

  @override
  String g4GenDraftToolsSaved(String n, String tokens) {
    return '$n spenti: circa $tokens token risparmiati a ogni messaggio. Se più avanti gliene serve uno, te lo chiede.';
  }

  @override
  String get g4GenDraftToolsTitle => 'I suoi strumenti';

  @override
  String g4GenDraftToolTokens(String tokens) {
    return '$tokens token';
  }

  @override
  String get g4GenDraftUseDefault => 'Usa le predefinite';

  @override
  String g4GenDraftWorking(String god) {
    return '$god sta scrivendo le sue istruzioni...';
  }

  @override
  String get g4GenHasKey => 'Chiave pronta';

  @override
  String get g4GenImagesHelp =>
      'Una chiave OpenAI permette agli agenti di disegnare immagini; ogni immagine costa.';

  @override
  String get g4GenImagesKey => 'Chiave OpenAI per le immagini (generate_image)';

  @override
  String get g4GenImagesModel => 'Modello per le immagini';

  @override
  String get g4GenImagesTitle => 'Immagini';

  @override
  String get g4GenInstrText =>
      'Quello che ogni agente deve sapere o fare: come vuoi le risposte, le tue convenzioni, cosa evitare.';

  @override
  String get g4GenInstructionsHint =>
      'Quello che ogni agente deve sapere o fare, chiunque sia: come vuoi le risposte, le tue convenzioni, cosa evitare. Si aggiungono alle istruzioni proprie di ciascun agente (quelle sono nella sua scheda, in Agenti).';

  @override
  String get g4GenInstructionsPlaceholder =>
      'Per esempio: rispondi in italiano; codice e commenti in inglese; mai fare push senza chiedere.';

  @override
  String get g4GenInstructionsSaved =>
      'Salvate: le seguono le conversazioni che cominciano da adesso.';

  @override
  String get g4GenInstructionsTitle => 'Istruzioni per tutti gli agenti';

  @override
  String get g4GenInUse => 'in uso';

  @override
  String get g4GenKeyChange => 'Usa un\'altra chiave';

  @override
  String g4GenKeyGet(String name) {
    return 'Prendi una chiave di $name';
  }

  @override
  String get g4GenKeyHelp => 'Resta nel Portachiavi, cifrata; non torna mai in questa pagina.';

  @override
  String g4GenKeyLabel(String name) {
    return 'Chiave di $name';
  }

  @override
  String g4GenKeyLinked(String name) {
    return 'Usa la chiave di $name che hai già dato (chat, estensioni o voce).';
  }

  @override
  String get g4GenLead =>
      'Aspetto e lingua, poi quello che vale per tutti gli agenti e i servizi in più. Ogni riquadro apre la sua finestra; quelli accesi sono impostati.';

  @override
  String get g4GenLocked => 'impostato dall\'ambiente';

  @override
  String get g4GenLogout => 'Esci';

  @override
  String g4GenModelCloses(String date) {
    return 'Il fornitore chiude questo modello il $date: scegline un altro prima di allora.';
  }

  @override
  String get g4GenNews => 'Le novità';

  @override
  String get g4GenNewsText =>
      'Tutto quello che ha portato ogni versione, dalla più recente: anche quello che ti sei perso.';

  @override
  String g4GenNewsVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get g4GenOn => 'acceso';

  @override
  String get g4GenOwnSearchHint =>
      'Rasgeth può avviare un suo motore di ricerca (SearXNG): gratuito, senza chiavi, e con lui ogni modello può cercare sul web, anche quelli locali.';

  @override
  String get g4GenOwnSearchOn =>
      'Il motore di ricerca di Rasgeth è acceso: tutti gli agenti e la Chat cercano sul web con lui.';

  @override
  String get g4GenOwnSearchStart => 'Avvia il motore di ricerca di Rasgeth';

  @override
  String get g4GenOwnSearchStop => 'Spegnilo';

  @override
  String g4GenPriceKchars(String usd) {
    return '$usd ogni 1000 caratteri';
  }

  @override
  String g4GenPriceMinute(String usd) {
    return 'circa $usd al minuto';
  }

  @override
  String g4GenPriceMtokens(String usd) {
    return '$usd per milione di token audio';
  }

  @override
  String get g4GenQ => 'Come vuoi Rasgeth?';

  @override
  String get g4GenRefineAfter => 'Dopo';

  @override
  String get g4GenRefineBefore => 'Prima';

  @override
  String g4GenRefineCount(String del, String add) {
    return '$del parole tolte, $add aggiunte';
  }

  @override
  String g4GenRefineGodModel(String god) {
    return 'Il modello di $god';
  }

  @override
  String get g4GenRefineLegendAdd => 'quello che arriva';

  @override
  String get g4GenRefineLegendDel => 'quello che va via';

  @override
  String get g4GenRefineModel => 'Il modello che scrive';

  @override
  String get g4GenRewriteGo => 'Riscrivi';

  @override
  String g4GenRewriteLead(String god) {
    return '$god parte dalle istruzioni nel campo e le adatta a quello che l\'agente fa adesso. Prima vedi le modifiche.';
  }

  @override
  String get g4GenRewriteTitle => 'Riscrivi per il nuovo compito';

  @override
  String get g4GenRewriteYes => 'Sì, falle riscrivere';

  @override
  String get g4GenSaved => 'Salvato';

  @override
  String get g4GenSearchDocs => 'Come installare SearXNG da solo';

  @override
  String g4GenSearchHowTitle(String name) {
    return 'Come configurare $name';
  }

  @override
  String get g4GenSearchKey => 'Chiave';

  @override
  String get g4GenSearchKeyKept => 'Una chiave è salvata: lascia vuoto per tenerla.';

  @override
  String g4GenSearchKeyPage(String name) {
    return 'Apri la pagina delle chiavi di $name';
  }

  @override
  String g4GenSearchSaved(String name) {
    return 'Da ora i modelli che non sanno cercare da soli usano $name.';
  }

  @override
  String get g4GenSearchText => 'Permette a ogni agente e alla Chat di cercare sul web.';

  @override
  String get g4GenSearchTitle => 'Ricerca sul web';

  @override
  String g4GenSearchTried(String n, String first) {
    return 'Funziona: $n risultati, il primo «$first».';
  }

  @override
  String get g4GenSearchTriedEmpty => 'Ha risposto, ma senza risultati per la ricerca di prova.';

  @override
  String get g4GenSearchTry => 'Prova';

  @override
  String get g4GenSearchUrl => 'Indirizzo del server SearXNG';

  @override
  String get g4GenSearchUrlHelp => 'L\'indirizzo a cui risponde il tuo SearXNG.';

  @override
  String get g4GenSearchUse => 'Usa questo';

  @override
  String get g4GenSearchWho =>
      'Claude e gli abbonamenti cercano da soli. Gli altri (modelli locali, chiavi compatibili OpenAI) usano il servizio scelto qui.';

  @override
  String get g4GenServices => 'Servizi';

  @override
  String get g4GenServicesHint =>
      'Cose in più che gli agenti possono usare. Ognuna funziona solo se la imposti; lasciare un campo vuoto la spegne.';

  @override
  String g4GenSttCloudHelp(String models, String price) {
    return 'In cloud: $models. Da $price.';
  }

  @override
  String get g4GenSttCompatible => 'Un altro servizio compatibile';

  @override
  String get g4GenSttCompatibleHelp =>
      'Qualunque servizio con l\'API di trascrizione di OpenAI (speaches, il server di whisper.cpp…), al suo indirizzo.';

  @override
  String get g4GenSttLocal => 'Su questo computer';

  @override
  String get g4GenSttLocalHelp =>
      'whisper.cpp, avviato da Rasgeth: gratis, non esce niente di casa.';

  @override
  String get g4GenSttRemote => 'whisper su un altro computer';

  @override
  String get g4GenSttRemoteHelp =>
      'whisper-asr-webservice al suo indirizzo, per un computer con la scheda video.';

  @override
  String get g4GenTitle => 'Generale';

  @override
  String get g4GenTrying => 'Provo il modello…';

  @override
  String get g4GenUiLangHelp => 'Le pagine, i menu e la configurazione.';

  @override
  String get g4GenUiLangTitle => 'Lingua dell\'interfaccia';

  @override
  String get g4GenUpdHelp =>
      'Rasgeth cerca da solo una versione nuova al primo avvio di ogni giorno. Qui puoi cercarla adesso.';

  @override
  String get g4GenVoiceHelp =>
      'Trasforma in testo i messaggi vocali (da Telegram o dal microfono).';

  @override
  String get g4GenVoiceKey => 'Chiave del servizio di trascrizione';

  @override
  String get g4GenVoiceLocalHint =>
      'Nessun account e niente esce da questo computer. Rasgeth scarica una volta whisper.cpp e un modello multilingue (circa 560 MB, con la barra nell\'angolo) e li fa girare lui.';

  @override
  String get g4GenVoiceModel => 'Modello di trascrizione';

  @override
  String get g4GenVoiceModelHead => 'Modello';

  @override
  String g4GenVoiceNeedsKey(String name) {
    return 'Incolla prima la chiave di $name.';
  }

  @override
  String get g4GenVoiceNeedsUrl => 'Scrivi prima l\'indirizzo del servizio.';

  @override
  String get g4GenVoiceTitle => 'Messaggi vocali';

  @override
  String get g4GenVoiceUrl => 'Indirizzo del servizio di trascrizione';

  @override
  String get g4GenWritten => 'scritte';

  @override
  String get g4GenLook => 'Aspetto e lingua';

  @override
  String get g4GenBackupSaved => 'Salvato: vale per i task che si arrendono da adesso.';

  @override
  String g4GenDebugSaved(String name) {
    return 'Salvato: $name';
  }

  @override
  String g4GenNewsTitle(String version) {
    return 'Le novità di Rasgeth $version';
  }

  @override
  String get g4GenNewsOk => 'Ho capito';

  @override
  String get g4AgTreeTitle => 'La tua squadra';

  @override
  String g4AgTreeOf(String project) {
    return 'Gli agenti di $project';
  }

  @override
  String get g4AgTreeLead =>
      'Chi lavora per te. God guida tutto; ogni progetto ha il suo capo, che passa il lavoro agli agenti del progetto. Un agente vede solo il suo progetto; l\'ispettore legge soltanto.';

  @override
  String get g4AgTreeProjectLead =>
      'Il capo del progetto, gli agenti a cui passa il lavoro e quelli di altri posti assegnati qui.';

  @override
  String get g4AgAllProjects => 'Tutti i progetti';

  @override
  String get g4AgShowStopped => 'Anche quelli fermati';

  @override
  String get g4AgNoLead => 'Questo progetto non ha ancora un orchestratore.';

  @override
  String get g4AgNear => 'Demi-God e agenti personali';

  @override
  String get g4AgAssigned => 'assegnato';

  @override
  String get g4AgArchived => 'archiviato';

  @override
  String get g4AgOpen => 'Apri';

  @override
  String get g4AgClose => 'Chiudi';

  @override
  String get g4AgAddShort => 'Agente sotto';

  @override
  String g4AgAddUnder(String name) {
    return 'Aggiungi un agente sotto $name';
  }

  @override
  String get g4AgKind => 'Tipo';

  @override
  String get g4AgWhatItDoes => 'Cosa fa';

  @override
  String get g4AgModelDefault => 'Il modello predefinito';

  @override
  String get g4AgOpenChat => 'Apri la sua conversazione';

  @override
  String get g4AgReadOnly =>
      'Il suo progetto è archiviato: puoi leggere le impostazioni, non cambia niente finché il progetto non viene ripristinato.';

  @override
  String get g4AgGroupAssistant => 'Servizi e routine';

  @override
  String g4AgRewriteOffer(String name, String god) {
    return 'Hai cambiato cosa fa $name. Vuoi che $god riscriva le sue istruzioni per il nuovo compito? Le vedi prima che cambi qualcosa.';
  }

  @override
  String get g4AgRewriteNo => 'No, tienile';

  @override
  String get g4AgRewriteYes => 'Sì, falle riscrivere';

  @override
  String get g4AgServices => 'Servizi';

  @override
  String get g4AgServicesHelp =>
      'I servizi che può usare. Le modifiche valgono per le sue conversazioni nuove.';

  @override
  String get g4AgNoServices => 'Ancora nessun servizio aggiunto.';

  @override
  String get g4AgAddServiceHint =>
      'I servizi (Notion, Linear, GitHub…) si aggiungono in Impostazioni, Estensioni.';

  @override
  String get g4AgSvcChecking => 'Controllo…';

  @override
  String g4AgSvcWorks(int n) {
    return 'Funziona · $n strumenti';
  }

  @override
  String get g4AgSvcLogin => 'Devi accedere';

  @override
  String get g4AgSvcBroken => 'Non funziona';

  @override
  String get g4AgSavedNewChats => 'Salvato: vale per le sue conversazioni nuove.';

  @override
  String get g4AgRoutines => 'Routine';

  @override
  String get g4AgRoutinesHelp => 'Lavori che fa da solo a un\'ora fissa o quando succede qualcosa.';

  @override
  String get g4AgNoRoutines => 'Ancora nessuna routine.';

  @override
  String get g4AgNewRoutine => 'Nuova routine';

  @override
  String g4AgNewRoutineOf(String name) {
    return 'Una nuova routine per $name';
  }

  @override
  String get g4AgOn => 'Attiva';

  @override
  String get g4AgOff => 'Spenta';

  @override
  String get g4AgRoutineWhat => 'Cosa deve fare?';

  @override
  String get g4AgRoutineWhatHint =>
      'Per esempio: guarda gli appuntamenti di oggi e mandami un riassunto.';

  @override
  String get g4AgRoutineTitle => 'Il suo titolo (facoltativo)';

  @override
  String get g4AgRoutineWhen => 'Quando';

  @override
  String get g4AgEvery_daily => 'Ogni giorno';

  @override
  String get g4AgEvery_weekdays => 'Dal lunedì al venerdì';

  @override
  String get g4AgEvery_weekly => 'Ogni lunedì';

  @override
  String get g4AgEvery_hourly => 'Ogni ora';

  @override
  String get g4AgRoutineTime => 'A che ora (HH:MM)';

  @override
  String get g4AgRoutineTimeBad => 'Un\'ora come 09:00';

  @override
  String get g4AgRoutineSave => 'Salva la routine';

  @override
  String g4AgRoutineOnce(String at) {
    return 'Una volta, $at';
  }

  @override
  String g4AgWhenDaily(String time) {
    return 'Ogni giorno alle $time';
  }

  @override
  String g4AgWhenWeekdays(String time) {
    return 'Dal lunedì al venerdì alle $time';
  }

  @override
  String g4AgWhenWeekly(String time) {
    return 'Ogni lunedì alle $time';
  }

  @override
  String get g4AgSkills => 'Skill';

  @override
  String get g4AgSkillsHelp =>
      'Dopo un lavoro riuscito, digli «salva questo come skill»: scrive i passi e, quando li approvi in Estensioni, tutti gli agenti li possono usare.';

  @override
  String get g4AgShared => 'Cosa sanno di te tutti gli agenti';

  @override
  String get g4AgSharedHelp =>
      'Chi sei, il tuo lavoro, i tuoi strumenti: in comune fra tutti i tuoi agenti personali.';

  @override
  String get g4AgStep1 => 'Cosa deve fare?';

  @override
  String get g4AgStep2Help => 'Lavora lì, sotto il capo del progetto.';

  @override
  String get g4AgStep3 => 'Il suo nome';

  @override
  String get g4AgStep4Help =>
      'Di solito lo stesso del capo del progetto; scegline un altro per uno più economico o più bravo.';

  @override
  String get g4AgStep5 => 'Quanto può fare da solo';

  @override
  String get g4AgStep2Asst => 'Quali servizi può usare?';

  @override
  String get g4AgStep2AsstHelp =>
      'Vede solo i servizi che accendi qui. Tutto ciò che invia, pubblica, cancella o paga ti chiede sempre prima il permesso.';

  @override
  String get g4AgStep3Asst => 'Quanto può fare da solo?';

  @override
  String get g4AgWhere => 'Dove lavora';

  @override
  String get g4AgWhereHelp =>
      'In un sottoprogetto scrive solo nella sua cartella; il resto del progetto lo può leggere, e le modifiche lì passano dal capo.';

  @override
  String get g4AgWholeProject => 'Tutto il progetto';

  @override
  String get g4AgOwnWords => 'Descrivi il lavoro a parole tue';

  @override
  String get g4AgOwnWordsHelp =>
      'Per esempio: tiene i testi del sito in italiano e in inglese e controlla i link.';

  @override
  String get g4AgRecommended => 'consigliato';

  @override
  String get g4AgModeText_auto =>
      'Lavora da solo; chiede solo per le azioni rischiose (come deciso in Sicurezza).';

  @override
  String get g4AgModeText_manual => 'Chiede prima di ogni modifica ai file o di ogni comando.';

  @override
  String get g4AgModeText_plan => 'Prima propone un piano; lavora solo dopo che è stato approvato.';

  @override
  String get g4AgModeText_readonly => 'Legge e risponde, non cambia niente.';

  @override
  String get g4AgAsstMode_auto => 'Da solo';

  @override
  String get g4AgAsstMode_manual => 'Chiede prima';

  @override
  String get g4AgAsstModeText_auto =>
      'Lavora da solo; ti chiede solo prima di ciò che esce (inviare, pubblicare, pagare) o è rischioso.';

  @override
  String get g4AgAsstModeText_manual => 'Ti chiede prima di ogni modifica.';

  @override
  String get g4AgAsstPurpose =>
      'Un agente personale fa un lavoro per te, fuori dai progetti. God gli passa il lavoro che è suo; puoi anche parlarci direttamente.';

  @override
  String get g4AgAsstRole => 'Il suo lavoro';

  @override
  String get g4AgAsstRoleHelp =>
      'Una o due frasi: God le legge per decidere cosa passargli, quindi tienilo preciso.';

  @override
  String get g4AgOrAskGod => 'Non sai quali agenti ti servono?';

  @override
  String g4AgAskGod(String god) {
    return 'Chiedi a $god';
  }

  @override
  String get g4AgAskGodMessage =>
      'Quali agenti personali mi sarebbero utili? Guarda cosa faccio con te e proponimene due o tre, ognuno con un lavoro preciso e i servizi che gli servono. Creali solo dopo che ti ho detto di sì.';

  @override
  String g4AgDraftNext(String god) {
    return 'Avanti: $god scrive le sue istruzioni';
  }

  @override
  String g4AgDraftNextHint(String god) {
    return '$god scriverà le sue istruzioni e sceglierà i suoi strumenti; li vedi prima che venga creato.';
  }

  @override
  String get g4AgDraftTitle => 'Le sue istruzioni e i suoi strumenti';

  @override
  String get g4AgReviewWritten => 'scritte per lui';

  @override
  String get g4AgReviewBuiltIn => 'quelle predefinite';

  @override
  String get g4AgNoneChosen => 'nessuno';

  @override
  String get g4AgRole_coder => 'Programmatore';

  @override
  String get g4AgRoleText_coder => 'Scrive e cambia il codice, fa girare le prove.';

  @override
  String get g4AgRole_reviewer => 'Revisore';

  @override
  String get g4AgRoleText_reviewer =>
      'Controlla le modifiche cercando errori e codice poco chiaro, dice dove e perché.';

  @override
  String get g4AgRole_researcher => 'Ricercatore';

  @override
  String get g4AgRoleText_researcher => 'Cerca sul web e nei file, con le fonti.';

  @override
  String get g4AgRole_writer => 'Scrittore';

  @override
  String get g4AgRoleText_writer => 'Documentazione, README e testi, chiari e aggiornati.';

  @override
  String get g4AgRole_tester => 'Tester';

  @override
  String get g4AgRoleText_tester => 'Scrive e fa girare le prove, riproduce i difetti.';

  @override
  String get g4AgRole_custom => 'Altro';

  @override
  String get g4AgRoleText_custom => 'Descrivi tu il lavoro a parole tue.';

  @override
  String get g4AgJob_secretary => 'Segretaria';

  @override
  String get g4AgJobHint_secretary =>
      'Agenda, attività e messaggi; il punto della giornata ogni mattina.';

  @override
  String get g4AgJobText_secretary =>
      'Tieni in ordine le mie attività e i miei appuntamenti, ricordami le scadenze e fammi il punto della giornata quando te lo chiedo. Non mandare mai niente a mio nome senza chiedermelo.';

  @override
  String get g4AgJob_researcher => 'Ricercatore';

  @override
  String get g4AgJobHint_researcher => 'Cerca sul web e ti riporta quello che trova, con le fonti.';

  @override
  String get g4AgJobText_researcher =>
      'Cerca sul web quando te lo chiedo, confronta le fonti e riportami quello che hai trovato con i link, dicendo cosa non sei riuscito a confermare.';

  @override
  String get g4AgJob_social => 'Social';

  @override
  String get g4AgJobHint_social => 'Prepara i post e tiene d\'occhio le tue pagine.';

  @override
  String get g4AgJobText_social =>
      'Prepara i post per le mie pagine nel mio stile, proponimeli prima di pubblicarli e dimmi come sono andati gli ultimi.';

  @override
  String get g4AgJob_accounts => 'Conti';

  @override
  String get g4AgJobHint_accounts => 'Fatture, pagamenti e spese, in ordine.';

  @override
  String get g4AgJobText_accounts =>
      'Tieni in ordine fatture, pagamenti e spese, dimmi cosa scade e cosa manca. Non pagare né rimborsare mai senza la mia approvazione.';

  @override
  String get g4AgJob_tech => 'Aiuto tecnico';

  @override
  String get g4AgJobHint_tech => 'Risponde alle domande tecniche e sistema le piccole cose.';

  @override
  String get g4AgJobText_tech =>
      'Rispondi alle mie domande tecniche in modo semplice, con i passi da seguire, e sistema i piccoli problemi quando te lo chiedo.';

  @override
  String get g4AgJob_custom => 'Con parole mie';

  @override
  String get g4AgJobHint_custom => 'Descrivi tu il lavoro.';

  @override
  String get g4BuTitle => 'Budget';

  @override
  String g4BuThisMonth(String month) {
    return 'Speso a $month';
  }

  @override
  String get g4BuLead => 'Quanto spendono progetti e agenti, e fin dove possono arrivare.';

  @override
  String get g4BuChart => 'Spesa giorno per giorno di questo mese';

  @override
  String get g4BuHowLink => 'Come funzionano i limiti';

  @override
  String get g4BuHow =>
      'I limiti contano tutto quello che è stato speso da quando li hai messi, non mese per mese. Quando una riga arriva al limite, i suoi agenti si fermano prima della richiesta successiva, e Telegram ti avvisa quando ci si avvicina. Alza o togli il limite per farli ripartire. Gli abbonamenti (Claude, ChatGPT) e i modelli sul tuo computer qui non costano niente.';

  @override
  String get g4BuUnderstood => 'Ho capito';

  @override
  String get g4BuTotal => 'Totale';

  @override
  String get g4BuEverything => 'Tutto';

  @override
  String get g4BuNothingYet => 'Ancora nessuna spesa.';

  @override
  String get g4BuProjects => 'Progetti';

  @override
  String get g4BuAgents => 'Agenti';

  @override
  String g4BuLimitFor(String name) {
    return 'Limite per $name';
  }

  @override
  String g4BuLimitNow(String limit) {
    return 'Ora: $limit';
  }

  @override
  String g4BuLimitSay(String usd) {
    return 'A \$$usd i suoi agenti si fermano e te lo dicono; lo alzi quando vuoi.';
  }

  @override
  String get g4BuLimitPick => 'Scegli una cifra, o scrivine un\'altra.';

  @override
  String get g4BuRemoveLimit => 'Nessun limite';

  @override
  String g4BuMonth(String usd) {
    return '$usd questo mese';
  }

  @override
  String g4BuEver(String usd) {
    return '$usd dall\'inizio';
  }

  @override
  String get g4BuStopped => 'Limite raggiunto: fermo';

  @override
  String get g4BuChange => 'Cambia';

  @override
  String g4BuLimitIs(String limit) {
    return 'Limite $limit';
  }

  @override
  String get g4BuNoLimit => 'nessun limite';

  @override
  String get g4BuOther => 'altro';

  @override
  String get g4BuLimitLabel => 'Limite';

  @override
  String g4BuTokens(String n) {
    return '$n token';
  }

  @override
  String get g4BuRowHint => 'Questo mese, ogni progetto e agente, con i loro limiti';

  @override
  String g4DvRenameQ(String name) {
    return 'Un nome nuovo per «$name»';
  }

  @override
  String g4DvRenamed(String name) {
    return 'Rinominato: $name';
  }

  @override
  String get g4HubTitle => 'Impostazioni';

  @override
  String get g4HubGeneral => 'Lingua, istruzioni degli agenti, ricerca, immagini, novità';

  @override
  String get g4HubAgents => 'L\'albero degli agenti, nuovi agenti, assistenti';

  @override
  String get g4HubTools => 'Cosa può usare ogni agente';

  @override
  String get g4HubCommands => 'Comandi in background, agenti al lavoro insieme';

  @override
  String get g4HubRequests => 'Dove ti arrivano le richieste, quanto aspettano';

  @override
  String get g4HubSafety => 'Guardiano, chi approva, spesa, skill, conservazione';

  @override
  String get cvCanvasFullscreen => 'Schermo intero';

  @override
  String get cvCanvasFullscreenExit => 'Esci dallo schermo intero';

  @override
  String get cvSideMaximize => 'Ingrandisci';

  @override
  String get cvSideBackToChat => 'Torna alla chat';

  @override
  String get cvVwDownload => 'Scarica';

  @override
  String cvVwCanvasBack(String n) {
    return 'Canvas ($n)';
  }

  @override
  String get cvKbTitle => 'Scorciatoie';

  @override
  String get cvSideTabsLabel => 'File e terminali aperti';

  @override
  String get cvCanvasAgentOpened => 'Aperto dall\'agente';

  @override
  String get cvVwKindArchive => 'Archivio';

  @override
  String get cvVwKindAudio => 'Audio';

  @override
  String get cvVwKindCode => 'Codice';

  @override
  String get cvVwKindDocument => 'Documento';

  @override
  String get cvVwKindFont => 'Carattere';

  @override
  String get cvVwKindImage => 'Immagine';

  @override
  String get cvVwKindLayers => 'Livelli (OpenRaster)';

  @override
  String get cvVwKindMarkdown => 'Markdown';

  @override
  String get cvVwKindModel => 'Modello 3D';

  @override
  String get cvVwKindPdf => 'PDF';

  @override
  String get cvVwKindSheet => 'Foglio di calcolo';

  @override
  String get cvVwKindSite => 'Pagina';

  @override
  String get cvVwKindSlides => 'Presentazione';

  @override
  String get cvVwKindTable => 'Tabella';

  @override
  String get cvVwKindText => 'Testo';

  @override
  String get cvVwKindTree => 'Dati';

  @override
  String get cvVwKindUnknown => 'File';

  @override
  String get cvVwKindVideo => 'Video';

  @override
  String get embedFallbackNote => 'La pagina non risponde: qui c\'è la vista semplice dell\'app.';

  @override
  String get palTitle => 'Agenti al massimo in questo progetto';

  @override
  String get palZero => 'Solo orchestratore';

  @override
  String get palHelp =>
      'Oltre all\'orchestratore; contano anche i sotto-agenti al lavoro. Con 0 l\'orchestratore lavora da solo.';

  @override
  String palNow(String n) {
    return 'Ora: $n.';
  }

  @override
  String get palNone => 'nessuno';

  @override
  String get palOne => '1 agente';

  @override
  String palN(String n) {
    return '$n agenti';
  }

  @override
  String palOver(String n, String max) {
    return 'Ne ha $n, più di $max: nessuno viene rimosso, ma non se ne creano di nuovi finché la squadra non scende sotto il limite.';
  }

  @override
  String get palSaved => 'Salvato. Lo trovi nello storico delle modifiche, dove puoi annullarlo.';

  @override
  String pmAgentLimit(String n) {
    return 'Agenti al massimo: $n';
  }

  @override
  String errAgentLimit(String project, String max, String count) {
    return 'Il progetto «$project» può avere al massimo $max agenti oltre all\'orchestratore: ne ha $count. Alza il limite dal menu del progetto o rimuovine uno.';
  }

  @override
  String appUpdTitle(String app) {
    return 'Aggiornamento di $app';
  }

  @override
  String appUpdCheck(String app) {
    return 'Cerca aggiornamenti di $app…';
  }

  @override
  String get appUpdChecking => 'Cerco una versione nuova…';

  @override
  String appUpdUpToDate(String app, String current) {
    return '$app $current è la versione più recente.';
  }

  @override
  String appUpdAvailable(String version, String current) {
    return 'È uscita la versione $version: hai la $current.';
  }

  @override
  String get appUpdFromServer =>
      'GitHub non risponde: è la versione del Rasgeth a cui sei collegato.';

  @override
  String get appUpdDownload => 'Scarica';

  @override
  String appUpdDownloading(String version) {
    return 'Scarico la $version';
  }

  @override
  String get appUpdHide => 'Nascondi';

  @override
  String get appUpdLater => 'Più tardi';

  @override
  String get appUpdSkip => 'Salta questa versione';

  @override
  String appUpdReady(String version, String app) {
    return 'La $version è pronta. $app si chiude, si aggiorna e si riapre dove sei.';
  }

  @override
  String get appUpdVerified =>
      'Firma e somma di controllo verificate con la chiave degli aggiornamenti di Rasgeth.';

  @override
  String get appUpdRestart => 'Aggiorna e riavvia';

  @override
  String appUpdApplying(String app) {
    return 'Chiudo $app per aggiornarla…';
  }

  @override
  String get appUpdRetry => 'Riprova';

  @override
  String get appUpdClose => 'Chiudi';

  @override
  String get appUpdErrNetwork => 'Adesso GitHub non si raggiunge. Riprova più tardi.';

  @override
  String get appUpdErrSignature =>
      'La firma della lista dei file di questa versione manca o non è valida: non uso niente di questa versione.';

  @override
  String appUpdErrNotListed(String app) {
    return 'Questa versione non ha un pacchetto di $app per questo sistema.';
  }

  @override
  String get appUpdErrChecksum => 'Il file scaricato non è quello firmato: l\'ho cancellato.';

  @override
  String get appUpdErrDisk => 'Non riesco a tenere o aprire il file scaricato.';

  @override
  String get appUpdErrSwap => 'La sostituzione non è partita: non è cambiato niente.';

  @override
  String appUpdDone(String app, String version, String from) {
    return '$app adesso è la $version (prima era la $from).';
  }

  @override
  String appUpdWentBack(String version, String app, String current) {
    return 'La $version non è partita: $app è tornata alla $current. Non te la ripropongo finché non ne esce una più nuova.';
  }

  @override
  String appUpdCarried(String app) {
    return 'Questa copia di $app arriva con Rasgeth: si aggiorna insieme a Rasgeth.';
  }

  @override
  String get appUpdDev => 'Una build dalle sorgenti: non si aggiorna da sola.';

  @override
  String get knAsstSavedNewChats => 'Salvato: vale per le sue conversazioni nuove.';

  @override
  String get knCompactAtHint =>
      'Un agente può tenere a mente solo una certa quantità di testo alla volta, come un quaderno con un numero fisso di pagine. Più a destra: il riassunto arriva più tardi. Più a sinistra: arriva prima e la conversazione resta più leggera.';

  @override
  String get knCompactAtTitle => 'Quando fare il riassunto';

  @override
  String knCompactAtValue(String n) {
    return 'piena al $n%';
  }

  @override
  String knCompactDefaultIs(String at, String keep) {
    return 'Predefinito per il modello di questo agente: al $at%, tenendo il $keep%.';
  }

  @override
  String get knCompactDefaults => 'Torna ai valori predefiniti';

  @override
  String knCompactExample(String at, String keep) {
    return 'se l\'agente può tenere a mente 100 pagine, quando arriva a $at fa il riassunto: le ultime $keep restano esattamente com\'erano, quelle prima diventano poche pagine di appunti.';
  }

  @override
  String knCompactExampleNone(String at) {
    return 'se l\'agente può tenere a mente 100 pagine, quando arriva a $at le trasforma tutte in poche pagine di appunti.';
  }

  @override
  String get knCompactExampleTitle => 'Per esempio:';

  @override
  String get knCompactExplain =>
      'Quando la conversazione diventa lunga, l\'agente fa un riassunto delle parti vecchie, come chi prende appunti. Qui scegli quando farlo e quanto dell\'ultima parte tenere com\'è.';

  @override
  String get knCompactKeepHint =>
      'La parte più recente resta parola per parola, tutto quello che viene prima diventa appunti. Più ne tieni, meglio l\'agente ricorda gli ultimi dettagli; con un modello sul tuo computer ogni parola tenuta costa un po\' di tempo una volta sola (lì va bene il 12%).';

  @override
  String get knCompactKeepNone => 'niente';

  @override
  String get knCompactKeepTitle => 'Quanto dell\'ultima parte tenere com\'è';

  @override
  String knCompactKeepValue(String n) {
    return 'l\'ultimo $n%';
  }

  @override
  String get knErr_memory_empty => 'Scrivi qualcosa da ricordare.';

  @override
  String get knErr_memory_forgotten => 'Un ricordo dimenticato per sempre non può tornare.';

  @override
  String get knErr_memory_full =>
      'La memoria è piena: cancella o unisci prima qualche ricordo vecchio.';

  @override
  String get knErr_memory_gone => 'Quel ricordo non c\'è più.';

  @override
  String get knErr_memory_long =>
      'Un ricordo è lungo al massimo 400 caratteri: scrivilo più corto.';

  @override
  String get knErr_memory_moved =>
      'Il ricordo è cambiato ancora: annulla prima la modifica più recente.';

  @override
  String get knErr_memory_same => 'Un altro ricordo dice già la stessa cosa.';

  @override
  String get knErr_memory_secret =>
      'Sembra una password, un codice o il numero di una carta: i segreti non vanno mai in memoria.';

  @override
  String get knErr_memory_undone => 'Quella modifica è già stata annullata.';

  @override
  String knJob_download_knowledge_model(String model, String size) {
    return 'Scarico $model ($size) per la conoscenza, per cercare nei tuoi file su questo computer (una volta sola)';
  }

  @override
  String knJob_download_ocr(String languages, String size) {
    return 'Scarico la lettura del testo nelle immagini ($languages, $size), una volta sola';
  }

  @override
  String get knJob_download_pgvector =>
      'Scarico pgvector, la ricerca per significato nel database di Rasgeth (una volta sola)';

  @override
  String get knJob_error_checksum =>
      'Il download è arrivato rovinato (l\'impronta non coincide): riprova.';

  @override
  String get knJob_error_pgvector_unavailable =>
      'pgvector non è ancora pubblicato per questo computer: la conoscenza cerca solo per parole.';

  @override
  String get knJob_step_model_download => 'Il modello';

  @override
  String get knJob_step_ocr_languages => 'Le lingue';

  @override
  String get knJob_step_ocr_program => 'Il programma';

  @override
  String get knJob_step_tool_download => 'Scarico';

  @override
  String get knKbAdd => 'Aggiungi';

  @override
  String get knKbAddSource => 'Aggiungi una fonte';

  @override
  String knKbAddSourceTo(String name) {
    return 'Aggiungi una fonte a $name';
  }

  @override
  String get knKbAgentAlways => 'Sempre';

  @override
  String get knKbAgentByScopeNo => 'Come dice la raccolta (no)';

  @override
  String get knKbAgentByScopeYes => 'Come dice la raccolta (sì)';

  @override
  String knKbAgentLead(String name) {
    return 'Quali raccolte può cercare $name. Ognuna dice chi può leggerla; qui puoi fare un\'eccezione per questo agente.';
  }

  @override
  String get knKbAgentNever => 'Mai';

  @override
  String get knKbAgentNewOnly => 'Vale dalla prossima conversazione dell\'agente.';

  @override
  String knKbAgentNone(String name) {
    return '$name non legge nessuna raccolta';
  }

  @override
  String get knKbAgentOpenAll => 'Tutte le raccolte';

  @override
  String knKbAgentPieces(String n) {
    return '$n pezzi';
  }

  @override
  String knKbAgentReads(String n, String name) {
    return '$name legge $n raccolte';
  }

  @override
  String get knKbAgentTool =>
      'Le cerca con «Cerca nei documenti» e cita da dove viene ogni risposta.';

  @override
  String get knKbAllChats => 'Nessuno scelto: le conversazioni con tutti gli agenti.';

  @override
  String get knKbBackupVectors => 'Metti anche la conoscenza nel backup';

  @override
  String get knKbBackupVectorsHelp =>
      'Un backup più grande, ma su un altro computer la ricerca è pronta subito, senza rileggere tutto.';

  @override
  String get knKbChat => 'conversazione';

  @override
  String get knKbCiteFallback => 'documento';

  @override
  String get knKbCloudKey => 'Voce del Portachiavi con la chiave';

  @override
  String get knKbCloudKeyExample => 'chiave_voyage';

  @override
  String get knKbCloudKeyHelp =>
      'Vuoto: la chiave data nella configurazione, per OpenAI, Gemini e Mistral.';

  @override
  String get knKbCloudLead =>
      'I pezzi dei tuoi documenti vengono mandati al servizio per essere letti. La sua chiave resta nel Portachiavi.';

  @override
  String get knKbCloudModel => 'Modelli consigliati';

  @override
  String get knKbCloudModelName => 'Modello';

  @override
  String get knKbCloudText => 'OpenAI, Voyage, Cohere, Gemini, Mistral, Jina o il tuo';

  @override
  String get knKbCloudTitle => 'Un servizio online';

  @override
  String get knKbCloudTrying => 'Provo la chiave…';

  @override
  String get knKbCloudUrl => 'Indirizzo del servizio';

  @override
  String get knKbCloudUrlHelp => 'Uno che parla come OpenAI, che finisce con /v1.';

  @override
  String get knKbCloudUse => 'Usalo';

  @override
  String get knKbCloudWho => 'Quale servizio';

  @override
  String knKbColLine(String docs, String pieces) {
    return '$docs documenti · $pieces pezzi';
  }

  @override
  String get knKbColName => 'Nome';

  @override
  String get knKbColNameExample => 'Manuali, Contratti, Ricette…';

  @override
  String get knKbColNameHelp => 'Cosa contiene, in poche parole.';

  @override
  String get knKbColsLead =>
      'Una raccolta mette insieme le fonti di un argomento e dice quali agenti possono leggerla.';

  @override
  String get knKbColsTitle => 'Raccolte';

  @override
  String get knKbConsentChats =>
      'Gli agenti che possono leggere questa raccolta potranno trovare e citare quello che hai scritto nelle conversazioni e quello che gli agenti hanno risposto.';

  @override
  String get knKbConsentChatsYes => 'Sì, gli agenti possono leggere queste conversazioni';

  @override
  String get knKbConsentMail =>
      'Gli agenti che possono leggere questa raccolta potranno trovare e citare la tua posta. Rasgeth legge solo la posta in arrivo: non segna, non sposta e non cancella mai un messaggio.';

  @override
  String get knKbConsentMailYes => 'Sì, gli agenti possono leggere questa posta';

  @override
  String knKbDays(String n) {
    return '$n giorni';
  }

  @override
  String get knKbDiskLead => 'Quanto occupa la conoscenza, e se va nel backup.';

  @override
  String get knKbDiskModels => 'Modelli';

  @override
  String get knKbDiskOcr => 'Lettura delle immagini';

  @override
  String get knKbDiskTexts => 'Pezzi di testo';

  @override
  String get knKbDiskTitle => 'Spazio sul disco';

  @override
  String get knKbDiskTotal => 'In tutto';

  @override
  String get knKbDiskVectors => 'Indice per significato';

  @override
  String knKbDocsWaiting(String n) {
    return '$n documenti ancora da leggere.';
  }

  @override
  String get knKbDownloading => 'Lo sto scaricando…';

  @override
  String get knKbDropHere => 'Lascia qui per aggiungerli alla Conoscenza';

  @override
  String get knKbDropOnCard => 'Trascina dei file su una raccolta per aggiungerli.';

  @override
  String get knKbDropSay => 'Puoi anche trascinare i file su questa finestra.';

  @override
  String get knKbErr_bad_choice => 'Questa scelta non è possibile.';

  @override
  String get knKbErr_bad_source =>
      'Quella fonte non si può leggere: controlla il percorso o l\'indirizzo.';

  @override
  String get knKbErr_embedding_failed =>
      'Il modello non ha risposto: controlla la chiave e riprova.';

  @override
  String get knKbErr_no_vector =>
      'La ricerca per significato non è ancora pronta su questo computer.';

  @override
  String get knKbErr_not_found => 'Non c\'è più.';

  @override
  String get knKbEtaSoon => 'Il tempo che manca si vede dopo i primi minuti.';

  @override
  String get knKbFileExample => '/home/io/manuale.pdf';

  @override
  String get knKbFileHelp => 'Il suo percorso completo sul computer dove gira Rasgeth.';

  @override
  String get knKbFilePath => 'Il file';

  @override
  String get knKbFolderExample => '/home/io/Documenti oppure C:\\Users\\io\\Documenti';

  @override
  String get knKbFolderHelp => 'Il suo percorso completo sul computer dove gira Rasgeth.';

  @override
  String get knKbFolderPath => 'La cartella';

  @override
  String knKbForAgent(String name) {
    return 'Per $name';
  }

  @override
  String get knKbForAll => 'Per tutti gli agenti';

  @override
  String knKbForProject(String name) {
    return 'Per il progetto $name';
  }

  @override
  String get knKbForWhom => 'Chi può leggerla';

  @override
  String get knKbHere => 'Già scaricato';

  @override
  String get knKbHowFarBack => 'Quanto indietro';

  @override
  String get knKbKindText_chats => 'Quello che hai detto con gli agenti';

  @override
  String get knKbKindText_file => 'Un documento solo';

  @override
  String get knKbKindText_folder => 'Tutto quello che c\'è dentro, sempre aggiornato';

  @override
  String get knKbKindText_mail => 'Solo se lo vuoi tu';

  @override
  String get knKbKindText_url => 'Letta una volta, di nuovo quando lo chiedi';

  @override
  String get knKbKindText_workspace => 'I file di uno dei tuoi progetti';

  @override
  String get knKbKind_chats => 'Le conversazioni';

  @override
  String get knKbKind_file => 'Un file';

  @override
  String get knKbKind_folder => 'Una cartella';

  @override
  String get knKbKind_mail => 'Una casella di posta';

  @override
  String get knKbKind_url => 'Una pagina web';

  @override
  String get knKbKind_workspace => 'Un progetto';

  @override
  String get knKbLead =>
      'Scegli cartelle, file e pagine: Rasgeth li legge, li divide in pezzi e li ritrova per quello che vogliono dire. Gli agenti dicono da dove viene ogni risposta e con un clic si apre il file in quel punto.';

  @override
  String knKbLeftOut(String n) {
    return 'Lasciati fuori ($n)';
  }

  @override
  String knKbLine(String n) {
    return 'riga $n';
  }

  @override
  String knKbLines(String a, String b) {
    return 'righe $a–$b';
  }

  @override
  String get knKbLoading => 'Carico…';

  @override
  String knKbLocalText(String dims, String size) {
    return 'Su questo computer · $size MB · $dims numeri per pezzo';
  }

  @override
  String get knKbMail => 'email';

  @override
  String get knKbMake => 'Creala';

  @override
  String knKbMeaningBest(String name, String size) {
    return 'Quello consigliato è $name: $size MB, scaricato una volta sola, solo adesso che lo dici tu.';
  }

  @override
  String knKbMeaningDownload(String name, String size) {
    return 'Scarica $name ($size MB) e attivala';
  }

  @override
  String get knKbMeaningOffTitle => 'La ricerca per significato è spenta: solo per parole';

  @override
  String get knKbMeaningOff_downloading =>
      'Il modello che hai scelto non è ancora su questo computer: finché non arriva la ricerca va per parole.';

  @override
  String get knKbMeaningOff_failed =>
      'Il modello per il significato non risponde: la ricerca va per parole. Sceglilo di nuovo o scegline un altro.';

  @override
  String get knKbMeaningOff_no_model =>
      'Nessun modello legge ancora i tuoi documenti per significato: così gli agenti trovano un pezzo solo se contiene le stesse parole che cercano.';

  @override
  String get knKbMeaningOff_no_vector =>
      'Su questo computer manca la parte del database che cerca per significato: la ricerca va per parole.';

  @override
  String get knKbMeaningOther => 'Scegli un altro modello';

  @override
  String get knKbMeaningTurnOn => 'Attiva la ricerca per significato';

  @override
  String knKbMeaningUse(String name) {
    return 'Usa $name';
  }

  @override
  String get knKbMeaningWhy =>
      'Con un modello che legge per significato, «quando apre il magazzino» trova anche «apre alle 7:30». Gira su questo computer: i tuoi documenti non escono.';

  @override
  String get knKbModelLead =>
      'Su questo computer (scaricato una volta, niente esce di casa) oppure un servizio online con la tua chiave. Se lo cambi, l\'indice nuovo si prepara in sottofondo.';

  @override
  String get knKbModelTitle => 'Il modello che legge per significato';

  @override
  String get knKbNewCollection => 'Nuova raccolta';

  @override
  String knKbNewIndex(String model) {
    return 'Sto preparando un indice nuovo per $model; le ricerche usano quello di prima finché non è pronto.';
  }

  @override
  String get knKbNoCols => 'Ancora nessuna raccolta.';

  @override
  String get knKbNoMailboxes => 'Nessuna casella collegata: aggiungila in Automazioni.';

  @override
  String get knKbNoProjects => 'Non c\'è ancora nessun progetto.';

  @override
  String get knKbNoSources => 'Ancora nessuna fonte: aggiungi una cartella, un file o una pagina.';

  @override
  String get knKbOcrDownload => 'Scarica adesso';

  @override
  String get knKbOcrLanguages => 'Lingue dei tuoi documenti';

  @override
  String get knKbOcrLead =>
      'Legge foto di documenti e PDF scansionati su questo computer (Tesseract). Il programma e le lingue si scaricano la prima volta, pochi MB.';

  @override
  String get knKbOcrOn => 'Leggi il testo nelle immagini e nelle scansioni';

  @override
  String get knKbOcrOnHelp => 'Più lento del testo: circa un secondo a pagina.';

  @override
  String get knKbOcrReady => 'Pronto su questo computer.';

  @override
  String get knKbOcrTitle => 'Il testo nelle immagini e nelle scansioni';

  @override
  String knKbOcrToDownload(String size) {
    return 'Da scaricare: circa $size MB.';
  }

  @override
  String knKbOcrWaiting(String n) {
    return '$n immagini e scansioni lo aspettano.';
  }

  @override
  String knKbOpenCollection(String name) {
    return 'Apri la raccolta $name';
  }

  @override
  String knKbPage(String n) {
    return 'pagina $n';
  }

  @override
  String get knKbPause => 'Metti in pausa la lettura';

  @override
  String get knKbPauseHelp =>
      'Le ricerche continuano a funzionare; non legge niente di nuovo finché non lo spegni.';

  @override
  String knKbPickEmpty(String name) {
    return 'Qui in $name non c\'è niente.';
  }

  @override
  String get knKbPickFile => 'Scegli un file in Rasgeth';

  @override
  String get knKbPickFolder => 'Scegli una cartella in Rasgeth';

  @override
  String get knKbPickOther => 'Scegline un\'altra';

  @override
  String get knKbPickPlaces => 'Torna ai progetti';

  @override
  String get knKbPickThis => 'Scegli questa cartella';

  @override
  String get knKbPickUp => 'Su di una cartella';

  @override
  String get knKbPickWhere => 'I tuoi progetti e le cartelle di Rasgeth';

  @override
  String get knKbPlaceAssistants => 'La scrivania degli assistenti';

  @override
  String get knKbPlacePlatform => 'La cartella di God';

  @override
  String get knKbProv_cohere => 'Cohere';

  @override
  String get knKbProv_compatible => 'Un altro (come OpenAI)';

  @override
  String get knKbProv_gemini => 'Gemini';

  @override
  String get knKbProv_jina => 'Jina';

  @override
  String get knKbProv_mistral => 'Mistral';

  @override
  String get knKbProv_openai => 'OpenAI';

  @override
  String get knKbProv_voyage => 'Voyage';

  @override
  String get knKbQ => 'I tuoi documenti, da far consultare agli agenti';

  @override
  String knKbQueueError(String error) {
    return 'Fermo per un problema: $error';
  }

  @override
  String get knKbRebuild => 'Ricostruisci';

  @override
  String get knKbRebuildHelp => 'Rilegge tutto da capo con lo stesso modello.';

  @override
  String get knKbRebuildQ => 'Ricostruire l\'indice?';

  @override
  String get knKbRebuildText =>
      'Ogni pezzo viene riletto. Le ricerche continuano a usare l\'indice di adesso finché quello nuovo non è pronto.';

  @override
  String get knKbRecommended => 'consigliato';

  @override
  String get knKbRemove => 'Elimina la raccolta';

  @override
  String knKbRemoveQ(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get knKbRemoveSource => 'Togli questa fonte';

  @override
  String get knKbRemoveText =>
      'I suoi pezzi escono dalla conoscenza. I tuoi file restano dove sono: niente sul disco viene toccato.';

  @override
  String get knKbRerankLead =>
      'Rilegge la domanda con ogni pezzo trovato e li rimette in ordine: risposte migliori, un po\' più lento.';

  @override
  String get knKbRerankNone => 'Nessuno';

  @override
  String get knKbRerankNoneText => 'L\'ordine della ricerca così com\'è';

  @override
  String knKbRerankText(String size) {
    return 'Su questo computer · $size MB';
  }

  @override
  String get knKbRerankTitle => 'Quello che mette il migliore in cima';

  @override
  String get knKbRescan => 'Guarda di nuovo adesso';

  @override
  String get knKbSaveScope => 'Salva chi può leggerla';

  @override
  String get knKbScopeAgent => 'Un agente';

  @override
  String get knKbScopeAll => 'Tutti gli agenti';

  @override
  String get knKbScopeProject => 'Gli agenti di un progetto';

  @override
  String get knKbSection => 'Conoscenza';

  @override
  String get knKbSources => 'Fonti';

  @override
  String knKbSrcChatsAll(String days) {
    return 'Le tue conversazioni, ultimi $days giorni';
  }

  @override
  String knKbSrcChatsOf(String days, String names) {
    return 'Le conversazioni con $names, ultimi $days giorni';
  }

  @override
  String knKbSrcDocs(String n) {
    return '$n documenti';
  }

  @override
  String knKbSrcMailOf(String days) {
    return 'La posta degli ultimi $days giorni';
  }

  @override
  String knKbSrcProjectOf(String name) {
    return 'I file di $name';
  }

  @override
  String get knKbSrcState_failed => 'Non riesco a leggerla';

  @override
  String get knKbSrcState_ready => 'Aggiornata';

  @override
  String get knKbSrcState_scanning => 'Sto guardando';

  @override
  String get knKbSrcState_waiting => 'In attesa';

  @override
  String get knKbStateEmpty =>
      'Ancora niente da cercare: crea una raccolta e aggiungi una cartella.';

  @override
  String get knKbStateNoModel =>
      'Scegli un modello qui sotto per cercare per significato; fino ad allora cerca per parole.';

  @override
  String get knKbStateNoVector =>
      'La ricerca per significato non è ancora pronta su questo computer: per ora cerca per parole.';

  @override
  String get knKbStatePaused => 'In pausa: le ricerche funzionano, non legge niente di nuovo.';

  @override
  String knKbStateReady(String n) {
    return 'Pronta: $n pezzi si possono cercare';
  }

  @override
  String get knKbStateWorking => 'Sto leggendo i tuoi documenti…';

  @override
  String knKbStatusLine(String cols, String pieces) {
    return '$cols raccolte · $pieces pezzi';
  }

  @override
  String get knKbThreads => 'Thread del processore';

  @override
  String get knKbThreadsAuto => 'automatico';

  @override
  String get knKbThreadsHelp => 'In automatico lascia a te la maggior parte del processore.';

  @override
  String get knKbThreadsTitle => 'Quanto processore usare';

  @override
  String knKbToDownload(String size) {
    return 'Da scaricare: $size MB';
  }

  @override
  String get knKbTryExample => 'Quando scade la garanzia?';

  @override
  String knKbTryHow(String ms, String n) {
    return '$n pezzi in $ms ms, per significato e per parole.';
  }

  @override
  String get knKbTryLead =>
      'Quello che troverebbero gli agenti per una domanda, il migliore per primo. Cliccane uno per aprirlo.';

  @override
  String get knKbTryNothing => 'Non ho trovato niente. Prova con altre parole.';

  @override
  String get knKbTrySearch => 'Cerca';

  @override
  String get knKbTryTitle => 'Prova una ricerca';

  @override
  String get knKbTryWordsOnly =>
      'Cercato solo per parole (manca ancora il modello per il significato).';

  @override
  String get knKbUploadFiles => 'Carica file da questo computer';

  @override
  String get knKbUploadFolder => 'Carica una cartella da questo computer';

  @override
  String get knKbUploadSay =>
      'Oppure trascina qui i file. I file caricati restano nella cartella di God, sotto knowledge.';

  @override
  String get knKbUploading => 'Invio dei file…';

  @override
  String get knKbUrl => 'L\'indirizzo';

  @override
  String get knKbUrlHelp => 'Letta senza i tuoi accessi: solo pagine pubbliche.';

  @override
  String get knKbWhichChats => 'Le conversazioni con chi';

  @override
  String get knKbWhichMailbox => 'Quale casella';

  @override
  String get knKbWhichProject => 'Quale progetto';

  @override
  String knKbWhyFailed(String error) {
    return 'Non è andata: $error';
  }

  @override
  String get knKbWhy_binary => 'Non è un documento (un programma, un archivio…)';

  @override
  String get knKbWhy_empty => 'Non c\'è testo dentro';

  @override
  String get knKbWhy_encrypted => 'Protetto da una password';

  @override
  String get knKbWhy_needs_libreoffice => 'Un vecchio file di Office: serve LibreOffice.';

  @override
  String get knKbWhy_needs_ocr =>
      'Un\'immagine o una scansione: accendi la lettura del testo nelle immagini, più sotto.';

  @override
  String get knKbWhy_too_big => 'Troppo grande da leggere';

  @override
  String get knKbWhy_unsupported => 'Un tipo di file che non sa leggere';

  @override
  String get knMemAdd => 'Aggiungi';

  @override
  String get knMemAddPlaceholder => 'Una cosa da ricordare, per esempio: preferisco risposte brevi';

  @override
  String get knMemAlready => 'Lo ricorda già.';

  @override
  String get knMemAutoOff =>
      'Spenta: Rasgeth non impara niente da sola. Puoi sempre aggiungere ricordi qui, o chiedere a un agente di ricordarsi qualcosa.';

  @override
  String get knMemAutoOn =>
      'Dopo che hai scritto, Rasgeth annota le cose che restano vere su di te: gusti, lavoro, come preferisci le risposte. Legge solo i tuoi messaggi, mai email, pagine web o automazioni, e non annota mai le password.';

  @override
  String get knMemAutoTitle => 'Impara da sola dalle conversazioni';

  @override
  String knMemByAgent(String name) {
    return 'Salvato da $name';
  }

  @override
  String get knMemByAgentUnknown => 'Salvato da un agente';

  @override
  String get knMemByAuto => 'Imparato da sola';

  @override
  String get knMemByHuman => 'Scritto da te';

  @override
  String get knMemByImport => 'Dalle tue note di prima';

  @override
  String knMemCount(String n) {
    return '$n ricordi';
  }

  @override
  String get knMemCountOne => '1 ricordo';

  @override
  String get knMemDid_added => 'Aggiunto';

  @override
  String get knMemDid_edited => 'Modificato';

  @override
  String get knMemDid_forgotten => 'Dimenticato per sempre';

  @override
  String get knMemDid_removed => 'Cancellato';

  @override
  String get knMemEdit => 'Modifica';

  @override
  String get knMemEditTitle => 'Modifica il ricordo';

  @override
  String get knMemEmpty =>
      'Rasgeth non sa ancora niente di te. Parla con un agente, oppure scrivi qui una cosa da ricordare.';

  @override
  String get knMemEyebrow => 'Memoria condivisa';

  @override
  String get knMemForget => 'Dimentica per sempre';

  @override
  String get knMemForgetText =>
      'Rasgeth lo cancella e toglie le sue parole anche dall\'elenco delle modifiche. Non si potrà più recuperare.';

  @override
  String get knMemForgetTitle => 'Dimenticarlo per sempre?';

  @override
  String get knMemForgottenText => 'Le sue parole sono state cancellate per sempre.';

  @override
  String knMemFrom(String title) {
    return 'dalla conversazione «$title»';
  }

  @override
  String get knMemFromUntitled => 'da una conversazione';

  @override
  String get knMemGoShared => 'Memoria condivisa: cosa Rasgeth sa di te';

  @override
  String get knMemGoSharedOpen => 'Apri';

  @override
  String get knMemGoSharedText => 'La usano tutti gli agenti e si aggiorna da sola mentre parli.';

  @override
  String get knMemHistory => 'Ultime modifiche';

  @override
  String get knMemHistoryLead =>
      'Ogni modifica resta segnata e la puoi annullare, tranne quando dimentichi per sempre.';

  @override
  String get knMemHistoryLess => 'Mostra meno';

  @override
  String get knMemHistoryMore => 'Mostra tutte le modifiche';

  @override
  String get knMemLead =>
      'Questa memoria la usano tutti gli agenti e si aggiorna da sola mentre parli. Ogni agente ha anche una memoria sua, nella scheda Memoria dell\'agente.';

  @override
  String get knMemListLead =>
      'Le modifiche valgono dalla prossima conversazione: quelle già aperte continuano come prima.';

  @override
  String get knMemListTitle => 'Cosa ricorda';

  @override
  String get knMemNoOwn => 'Questo agente non tiene una memoria sua.';

  @override
  String get knMemOwnCard => 'Memoria personale di un agente';

  @override
  String get knMemOwnCardQ => 'Nella scheda Memoria di ogni agente';

  @override
  String get knMemOwnCardText =>
      'La legge solo quell\'agente. La scrivi tu, oppure l\'agente ci annota quello che gli serve per il suo lavoro.';

  @override
  String knMemOwnHelp(String name) {
    return 'La legge solo $name, all\'inizio di ogni conversazione. Anche $name ci può annotare quello che gli serve.';
  }

  @override
  String get knMemOwnPlaceholder => 'Per esempio: rispondi sempre con un elenco breve';

  @override
  String knMemOwnTitle(String name) {
    return 'Memoria di $name: solo per questo agente';
  }

  @override
  String get knMemProjectHelp => 'La leggono tutti gli agenti che lavorano a questo progetto.';

  @override
  String knMemProjectTitle(String name) {
    return 'Memoria del progetto «$name»';
  }

  @override
  String get knMemRemove => 'Cancella';

  @override
  String get knMemRemoved => 'Ricordo cancellato.';

  @override
  String get knMemSaved => 'Salvato';

  @override
  String get knMemSharedCard => 'Memoria condivisa';

  @override
  String get knMemSharedCardQ => 'Questa pagina';

  @override
  String get knMemSharedCardText =>
      'La leggono tutti gli agenti. Si riempie da sola con le tue conversazioni, e qui la puoi cambiare.';

  @override
  String get knMemSummaryTitle => 'Riassunto delle conversazioni lunghe';

  @override
  String get knMemTitle => 'Cosa Rasgeth sa di te';

  @override
  String get knMemUndid_added => 'Ripristinato';

  @override
  String get knMemUndid_edited => 'Tornato com\'era';

  @override
  String get knMemUndid_removed => 'Tolto di nuovo';

  @override
  String get knMemUndo => 'Annulla';

  @override
  String get knMemUndone => 'Annullata';

  @override
  String knMemUsed(String limit, String used) {
    return 'Spazio usato: $used caratteri su $limit';
  }

  @override
  String knMemWith(String name) {
    return 'con $name';
  }

  @override
  String get knSettings => 'Impostazioni';

  @override
  String knUiAboutHours(String h, String min) {
    return 'mancano circa $h h $min min';
  }

  @override
  String knUiAboutMinutes(String min) {
    return 'mancano circa $min min';
  }

  @override
  String get knUiLessThanMinute => 'manca meno di un minuto';

  @override
  String knUiOf(String done, String total) {
    return '$done di $total';
  }

  @override
  String get knUiDetails => 'Dettagli per chi ti aiuta';

  @override
  String get knWzDoneBtn => 'Fatto';

  @override
  String get knHubKnowledge =>
      'I tuoi documenti in cui gli agenti cercano: collezioni, fonti, modelli';

  @override
  String get knHubMemory => 'Cosa sanno di te tutti gli agenti, ogni modifica annullabile';

  @override
  String get cvSaveFailedShort => 'Non salvato';

  @override
  String get cvSaveRetry => 'Riprova a salvare';

  @override
  String get cvReadOnly => 'Sola lettura';

  @override
  String get cvPastePicture => 'Incolla immagine';

  @override
  String get cvPasteNone => 'Negli appunti non c\'è un\'immagine';

  @override
  String get cvAskedAgent => 'Messo nel messaggio della conversazione';

  @override
  String get renameNoticeTitle => 'RedGiant ora si chiama Rasgeth.';

  @override
  String get renameNoticeText =>
      'Cambia solo il nome: progetti, conversazioni, agenti e chiavi restano come sono. Si legge «ràs-ghet», con la g dura.';

  @override
  String get renameNoticeOk => 'Ho capito';

  @override
  String noInternetNotice(String parts) {
    return 'Senza internet. In attesa della rete: $parts (il collegamento riparte da solo appena torna). Tutto il resto funziona, modelli locali compresi.';
  }

  @override
  String get cvGeneratingImage => 'Sta generando un\'immagine…';

  @override
  String get cvGeneratingVideo => 'Sta generando un video…';

  @override
  String get cvGeneratingAudio => 'Sta generando un suono…';

  @override
  String get cvImageUnreadable => 'Non riesco ad aprire questa immagine';

  @override
  String cvImageUnreachable(String name) {
    return 'Immagine non disponibile qui: $name';
  }

  @override
  String get cvMediaNativeTitle => 'Usa lo strumento del modello quando c\'è';

  @override
  String get cvMediaNativeHelp =>
      'Alcuni modelli fanno le immagini da sé (ChatGPT con Codex): allora si usa il loro, e l\'immagine ti arriva in chat come con il nostro. Spento: sempre il fornitore scelto qui. Se in una conversazione chiedi «il vostro strumento», si usa sempre il nostro. Vale per le conversazioni nuove.';

  @override
  String get ptrSection => 'Ritratto';

  @override
  String get ptrHub => 'Come ti vedono gli agenti, costruito dalle tue conversazioni';

  @override
  String get ptrTitle => 'Come ti vedono gli agenti';

  @override
  String get ptrLead =>
      'Questo ritratto si costruisce da solo dalle tue conversazioni: i tuoi gusti, come ti piace che ti si parli, le tue abitudini, i progetti a cui lavori, cosa evitare. Lo leggono gli agenti che scegli, all\'inizio di ogni conversazione. Correggilo quando vuoi: vale sempre la tua parola.';

  @override
  String get ptrOnTitle => 'Costruisci il ritratto dalle conversazioni';

  @override
  String get ptrOnOn =>
      'Quando una conversazione si ferma, un modello leggero legge solo i tuoi messaggi e aggiorna il ritratto. Non annota mai password, chiavi, indirizzi email, numeri di telefono o cose di altre persone. Spende un poco dal tuo budget.';

  @override
  String get ptrOnOff =>
      'Spento: il ritratto non cambia e nessun agente lo legge. Quello che c\'è resta finché non lo cancelli.';

  @override
  String get ptrWhoTitle => 'Chi lo legge';

  @override
  String get ptrWhoLead =>
      'Le modifiche valgono dalla prossima conversazione: quelle già aperte continuano come erano.';

  @override
  String get ptrWho_god => 'God';

  @override
  String get ptrWho_orchestrators => 'Gli orchestratori dei progetti';

  @override
  String get ptrWho_chat => 'La Chat';

  @override
  String get ptrWho_others => 'Tutti gli altri agenti';

  @override
  String get ptrListTitle => 'Tratti';

  @override
  String get ptrListLead =>
      'Ogni tratto dice quanto è sicuro e da dove viene. Un tratto che nessuna conversazione ripete sbiadisce col tempo.';

  @override
  String ptrCount(String n) {
    return '$n tratti';
  }

  @override
  String get ptrCountOne => '1 tratto';

  @override
  String get ptrEmpty =>
      'Ancora nessun tratto: il ritratto si riempie mentre parli con gli agenti.';

  @override
  String get ptrEmptyOff => 'Il ritratto è spento e vuoto.';

  @override
  String get ptrAddPlaceholder =>
      'Aggiungi un tratto tu, per esempio Mi piacciono le risposte con esempi';

  @override
  String get ptrAdd => 'Aggiungi';

  @override
  String get ptrCat_preference => 'Preferenze';

  @override
  String get ptrCat_style => 'Come parlarti';

  @override
  String get ptrCat_habit => 'Abitudini';

  @override
  String get ptrCat_project => 'Progetti in corso';

  @override
  String get ptrCat_avoid => 'Da evitare';

  @override
  String get ptrCat_about => 'Su di te';

  @override
  String get ptrSure => 'Sicuro';

  @override
  String get ptrLikely => 'Probabile';

  @override
  String get ptrUnsure => 'Ancora incerto';

  @override
  String get ptrByYou => 'Scritto da te';

  @override
  String ptrSeen(String n) {
    return 'visto $n volte';
  }

  @override
  String get ptrSeenOnce => 'visto una volta';

  @override
  String get ptrWhere => 'Da dove viene';

  @override
  String get ptrUntitled => 'Una conversazione';

  @override
  String ptrWith(String name) {
    return 'con $name';
  }

  @override
  String get ptrEdit => 'Cambia';

  @override
  String get ptrRemove => 'Togli';

  @override
  String get ptrDeny => 'Non è vero';

  @override
  String get ptrEditTitle => 'Cambia il tratto';

  @override
  String get ptrEditNote =>
      'Una volta cambiato, il tratto è tuo: non sbiadisce e niente lo cambia da solo.';

  @override
  String ptrDenied(String n) {
    return '$n tratti che hai detto non veri: non verranno più proposti.';
  }

  @override
  String get ptrDeniedOne => '1 tratto che hai detto non vero: non verrà più proposto.';

  @override
  String get ptrTextTitle => 'Quello che leggono gli agenti';

  @override
  String get ptrTextLead =>
      'Il ritratto esattamente come entra in una conversazione nuova, breve e sempre uguale finché non cambia.';

  @override
  String get ptrTextShow => 'Mostra il testo';

  @override
  String get ptrTextHide => 'Nascondi il testo';

  @override
  String get ptrForgetTitle => 'Dimentica tutto';

  @override
  String get ptrForgetLead =>
      'Se ne vanno tutti i tratti, e le loro parole spariscono anche dalla cronologia. Non si torna indietro.';

  @override
  String get ptrForgetText =>
      'Ogni tratto del ritratto viene cancellato e le sue parole tolte dalla cronologia, anche quelli «non veri». Il ritratto riparte vuoto.';

  @override
  String get ptrForget => 'Dimentica tutto';

  @override
  String get ptrErr_empty => 'Scrivi il tratto.';

  @override
  String get ptrErr_long => 'Un tratto è al massimo di 200 caratteri: scrivilo più corto.';

  @override
  String get ptrErr_secret =>
      'Sembra una password, un codice o un numero di carta: i segreti non entrano mai nel ritratto.';

  @override
  String get ptrErr_private => 'Indirizzi email e numeri di telefono non entrano mai nel ritratto.';

  @override
  String get ptrErr_gone => 'Quel tratto non c\'è più.';

  @override
  String get tkTitle => 'Gruppi di strumenti';

  @override
  String get tkLead =>
      'Gli agenti partono con pochi strumenti, così ogni messaggio pesa poco. Gli altri gruppi sono spenti di serie: un agente ne accende uno da sé quando il lavoro lo chiede, per quella conversazione. Acceso sempre: l\'agente lo ha dall\'inizio. Spento da te: l\'agente deve chiedertelo.';

  @override
  String tkAgentLead(String name) {
    return 'I gruppi di $name: come per tutti gli agenti, oppure una scelta sua.';
  }

  @override
  String get tkAuto => 'Spento di serie';

  @override
  String get tkOn => 'Acceso sempre';

  @override
  String get tkOff => 'Spento da te';

  @override
  String tkAsAll(String state) {
    return 'Come per tutti: $state';
  }

  @override
  String get tkIsDefault => 'di serie';

  @override
  String get tkRole => 'acceso per il suo ruolo';

  @override
  String tkWeight(String n) {
    return 'circa $n token quando è acceso';
  }

  @override
  String tkEssential(String n) {
    return 'Strumenti essenziali, sempre accesi: circa $n token';
  }

  @override
  String tkStartTotal(String n) {
    return 'All\'inizio: circa $n token a ogni messaggio';
  }

  @override
  String tkRest(String n) {
    return 'Spenti all\'inizio: $n token che pesano solo se si accende un gruppo';
  }

  @override
  String tkTools(String list) {
    return 'Strumenti: $list';
  }

  @override
  String get tkStateAuto => 'spento di serie';

  @override
  String get asMascotSub =>
      'Un sotto-agente non ha una mascotte sua: vive per un compito, e mostra un anello nel colore del genitore.';

  @override
  String get auAsstNewRoutine => 'Nuova routine';

  @override
  String get auAutoOff => 'Spenta: non parte finché non la riaccendi.';

  @override
  String get auAutoOn => 'Accesa';

  @override
  String get auAutoStart => 'Parti da';

  @override
  String get auAutoTitle => 'Come si chiama';

  @override
  String get auAutoTitleHelp => 'Un nome breve, per te.';

  @override
  String get auAutoWhat => 'Cosa chiedere';

  @override
  String get auAutoWhatHelp =>
      'Come lo scriveresti in una chat. La risposta ti arriva su Telegram.';

  @override
  String get auAutoWho => 'Chi lo fa';

  @override
  String get auAutoWhoHelp =>
      'God vede tutti i progetti; il capo e gli agenti di un progetto solo il loro.';

  @override
  String get auAutoYaml => 'La ricetta (per esperti)';

  @override
  String get auAutoYamlHint => 'Quello che scrive il modulo. Se la cambi qui, viene salvata così.';

  @override
  String get auAutomationNotices => 'Messaggi delle automazioni';

  @override
  String get auAutomations => 'Automazioni';

  @override
  String get auAwChange => 'Cambia';

  @override
  String get auAwLastRun => 'Ultima volta';

  @override
  String get auAwLead =>
      'Un\'automazione chiede a un agente di fare qualcosa a un\'ora o quando succede qualcosa; un promemoria ti manda un messaggio in un giorno. I riquadri accesi sono attivi.';

  @override
  String get auAwListLead =>
      'Aprine una per accenderla o spegnerla, farla partire ora, cambiarla o vedere com\'è andata.';

  @override
  String get auAwListTitle => 'Le tue automazioni';

  @override
  String get auAwNewText =>
      'Un agente fa qualcosa per te: ogni mattina, ogni settimana, a una mail o a un push.';

  @override
  String get auAwQ => 'Cosa deve fare Rasgeth da solo?';

  @override
  String get auAwReminderText =>
      'Un messaggio per te nel giorno e all\'ora che scegli, così come l\'hai scritto.';

  @override
  String get auAwSourcesLead => 'Cosa possono ascoltare le automazioni, oltre all\'orologio.';

  @override
  String get auAwSourcesTitle => 'Collegamenti';

  @override
  String get auAwStarted => 'Partita: tra un momento la vedi qui sotto.';

  @override
  String get auAxAdvanced => 'Avanzate';

  @override
  String get auAxAfterWhich => 'Quale automazione';

  @override
  String get auAxAfter_failed => 'Se è andata male';

  @override
  String get auAxAfter_ok => 'Se è andata bene';

  @override
  String get auAxAfter_timeout => 'Se ci ha messo troppo';

  @override
  String get auAxAgentOwn => 'Quello dell\'agente';

  @override
  String get auAxAnyChat => 'qualunque chat';

  @override
  String get auAxAnyProject => 'Qualunque progetto';

  @override
  String get auAxApprove => 'Chiedimi prima di agire';

  @override
  String get auAxApproveHelp =>
      'Ti arriva una domanda qui e nelle chat; senza il tuo sì non parte.';

  @override
  String get auAxBudget => 'Un limite di spesa ogni volta';

  @override
  String get auAxBudgetHelp => 'Oltre il limite l\'agente si ferma.';

  @override
  String get auAxBudgetUsd => 'Dollari al massimo';

  @override
  String get auAxCat_other => 'Altro';

  @override
  String get auAxCat_personal => 'Personale';

  @override
  String get auAxCat_social => 'Social';

  @override
  String get auAxCat_work => 'Lavoro';

  @override
  String get auAxCondCooldown => 'Una pausa tra una volta e l\'altra';

  @override
  String get auAxCondDates => 'Solo in un periodo';

  @override
  String get auAxCondDays => 'Solo in certi giorni';

  @override
  String get auAxCondFrom => 'Solo da certi mittenti';

  @override
  String get auAxCondFromHelp => 'Per le email e i messaggi in chat.';

  @override
  String get auAxCondHours => 'Solo in certe ore';

  @override
  String get auAxCondMax => 'Non troppe volte al giorno';

  @override
  String get auAxCondWithout => 'Mai con certe parole';

  @override
  String get auAxCondWords => 'Solo con certe parole';

  @override
  String get auAxCooldown => 'Minuti di pausa';

  @override
  String get auAxCron => 'Espressione cron';

  @override
  String get auAxCronHelp =>
      'Minuto, ora, giorno del mese, mese, giorno della settimana: 0 9 * * 1-5 vuol dire alle 9 nei giorni lavorativi.';

  @override
  String get auAxDoes => 'Cosa fa';

  @override
  String get auAxDoesAgent => 'Lavora un agente';

  @override
  String get auAxDoesHelp =>
      'Un agente fa un lavoro, oppure ti arriva un messaggio così com\'è scritto.';

  @override
  String get auAxDoesReminder => 'Solo un messaggio';

  @override
  String get auAxEffort => 'Impegno';

  @override
  String get auAxEmailAll => 'Tutte';

  @override
  String get auAxEmailByBox => 'Alcune caselle';

  @override
  String get auAxEmailByCategory => 'Una categoria';

  @override
  String get auAxEmailText => 'Il testo contiene';

  @override
  String get auAxEmailTextPlaceholder => 'Una parola nell\'email (facoltativo)';

  @override
  String get auAxEmailWhich => 'Quali caselle';

  @override
  String get auAxEveryMinutes => 'Ogni quanti minuti';

  @override
  String get auAxFallback => 'Poi avvia';

  @override
  String get auAxFilesPath => 'Cartella';

  @override
  String get auAxFilesPathHelp => 'Dentro il progetto; un punto vuol dire tutto il progetto.';

  @override
  String get auAxFilesPattern => 'Solo questi file';

  @override
  String get auAxFilesPatternHelp => 'Per esempio *.pdf; vuoto: tutti i file.';

  @override
  String get auAxFilesProjectHelp => 'Prima crea un progetto: la cartella sta dentro un progetto.';

  @override
  String get auAxFiles_added => 'File nuovi';

  @override
  String get auAxFiles_changed => 'File cambiati';

  @override
  String get auAxFiles_removed => 'File cancellati';

  @override
  String get auAxFirstBox => 'La prima casella';

  @override
  String get auAxFrom => 'Dalle';

  @override
  String get auAxFromDay => 'Dal giorno';

  @override
  String get auAxIfFails => 'Se va male';

  @override
  String get auAxKind_custom => 'Scritto a mano (cron)';

  @override
  String get auAxKind_minutes => 'Ogni tot minuti';

  @override
  String get auAxKind_once => 'Una volta sola';

  @override
  String get auAxMagic => 'Automazione magica';

  @override
  String get auAxMagicAllSet => 'C\'è tutto quello che serve.';

  @override
  String get auAxMagicApprove => 'Approva e crea';

  @override
  String get auAxMagicAsk => 'Cosa deve succedere?';

  @override
  String get auAxMagicBuilding =>
      'God la sta costruendo con te: rispondi alle sue domande nella conversazione.';

  @override
  String get auAxMagicDismiss => 'Metti da parte';

  @override
  String get auAxMagicDone => 'Approvata: ora è tra le tue automazioni.';

  @override
  String get auAxMagicEdit => 'Cambiala prima';

  @override
  String get auAxMagicEx1 =>
      'Ogni giorno alle 3 controlla il mio conto Revolut e avvisami su WhatsApp se ho ricevuto o pagato soldi';

  @override
  String get auAxMagicEx2 =>
      'Quando arriva una fattura nella casella del lavoro, salvala nel progetto e dimmi l\'importo';

  @override
  String get auAxMagicEx3 =>
      'Quando scrivo «spesa:» su Telegram, aggiungilo alla lista e il sabato mandami la lista';

  @override
  String get auAxMagicExamples => 'Oppure parti da un esempio';

  @override
  String get auAxMagicGo => 'Chiedi a God';

  @override
  String get auAxMagicLead =>
      'Scrivi cosa deve succedere, come lo diresti a una persona. God ti risponde in una conversazione tutta sua e costruisce l\'automazione insieme a te.';

  @override
  String get auAxMagicListLead => 'Costruite con God: aprine una per continuare la conversazione.';

  @override
  String get auAxMagicListTitle => 'Automazioni magiche';

  @override
  String get auAxMagicMissing => 'Prima di approvare, sistema quello che manca:';

  @override
  String get auAxMagicNeeds => 'Serve ancora';

  @override
  String get auAxMagicPlaceholder =>
      'Ogni giorno alle 3 controlla il mio conto e scrivimi su WhatsApp cosa è entrato e cosa è uscito';

  @override
  String get auAxMagicPromise1 => 'Niente parte senza il tuo sì.';

  @override
  String get auAxMagicPromise2 =>
      'Gli strumenti e le skill nuove si provano a parte e aspettano te.';

  @override
  String get auAxMagicPromise3 =>
      'Chiavi e password non vanno mai nella chat: God ti dice dove metterle.';

  @override
  String get auAxMagicProposal => 'La proposta di God';

  @override
  String get auAxMagicReadyBadge => 'Da approvare';

  @override
  String get auAxMagicReject => 'Così no';

  @override
  String get auAxMagicSendNo => 'Manda a God';

  @override
  String get auAxMagicStarting => 'Chiamo God…';

  @override
  String get auAxMagicState_building => 'In costruzione';

  @override
  String get auAxMagicState_dismissed => 'Messa da parte';

  @override
  String get auAxMagicState_done => 'Approvata e creata';

  @override
  String get auAxMagicState_ready => 'Pronta: God aspetta il tuo sì';

  @override
  String get auAxMagicStep1 => 'Racconti cosa vuoi';

  @override
  String get auAxMagicStep2 => 'God te la propone';

  @override
  String get auAxMagicStep3 => 'La approvi';

  @override
  String get auAxMagicTile =>
      'Di\' a God cosa vuoi, con parole tue: ti chiede quello che serve, prepara quello che manca e te lo fa vedere prima che parta qualcosa.';

  @override
  String get auAxMagicWhy => 'Cosa non va? God lo legge e riprova';

  @override
  String auAxMailboxesWatching(String n, String names) {
    return '$n caselle collegate: $names.';
  }

  @override
  String get auAxMatchAll => 'Tutte';

  @override
  String get auAxMatchAny => 'Almeno una';

  @override
  String get auAxMaxPerDay => 'Al massimo, volte al giorno';

  @override
  String get auAxMessageChat => 'Solo in questa chat';

  @override
  String get auAxMessageChatHelp => 'Il numero della chat, per un gruppo; vuoto: qualunque chat.';

  @override
  String get auAxMessageFrom => 'Da chi';

  @override
  String get auAxMessageFromHelp =>
      'Una parte del nome o del numero; vuoto: chiunque sia collegato.';

  @override
  String get auAxMessageHandle => 'Il messaggio è solo per l\'automazione';

  @override
  String get auAxMessageHandleHelp => 'Demi-God non risponde: ci pensa l\'automazione.';

  @override
  String get auAxMessageWhere => 'Su quali chat (se non ne scegli nessuna: tutte)';

  @override
  String get auAxMessageWords => 'Con quali parole';

  @override
  String get auAxMessageWordsPlaceholder => 'spesa, /spese';

  @override
  String get auAxMissed => 'Se all\'ora giusta Rasgeth era spento';

  @override
  String get auAxMissedRun => 'Falla appena si accende';

  @override
  String get auAxMissedSkip => 'Lascia perdere';

  @override
  String get auAxModel => 'Modello';

  @override
  String get auAxModelHelp => 'Vuoto: quello dell\'agente.';

  @override
  String get auAxNeedMissing => 'Manca';

  @override
  String get auAxNeedOpen => 'Sistemalo';

  @override
  String get auAxNeedReady => 'Pronto';

  @override
  String get auAxNeedVault => 'Aggiungi al portachiavi';

  @override
  String auAxNeed_chat(String what) {
    return 'La chat $what';
  }

  @override
  String auAxNeed_credential(String what) {
    return 'La chiave per $what';
  }

  @override
  String get auAxNeed_email => 'Una casella email';

  @override
  String auAxNeed_extension(String what) {
    return 'L\'estensione $what';
  }

  @override
  String auAxNeed_other(String what) {
    return '$what';
  }

  @override
  String get auAxNextNone =>
      'Con queste condizioni a orario non parte mai: controlla le ore e i giorni.';

  @override
  String get auAxNextTimes => 'Le prossime volte';

  @override
  String get auAxNightHours => 'Di notte';

  @override
  String get auAxNone => 'Niente';

  @override
  String get auAxOnceAt => 'Giorno e ora';

  @override
  String get auAxOnly => 'Solo se';

  @override
  String get auAxOnlyHelp =>
      'Le condizioni per partire: tutte quelle che accendi, insieme. Se la avvii tu a mano non contano.';

  @override
  String get auAxOr => 'oppure';

  @override
  String get auAxOverlap => 'Se lavora ancora quando dovrebbe ripartire';

  @override
  String get auAxOverlapQueue => 'Aspetta e poi parte';

  @override
  String get auAxOverlapSkip => 'Salta quella volta';

  @override
  String get auAxPick => 'Scegli…';

  @override
  String get auAxRetries => 'Riprova, quante volte';

  @override
  String get auAxRetryMinutes => 'Minuti tra un tentativo e l\'altro';

  @override
  String get auAxRunQueued => 'in attesa';

  @override
  String get auAxRunTriggers =>
      'email,messaggio in chat,file,un\'altra automazione,lavoro,avvio,nuovo tentativo';

  @override
  String auAxSayAfter(String name) {
    return 'Dopo «$name»';
  }

  @override
  String get auAxSayApprove => 'Prima ti chiede il sì.';

  @override
  String auAxSayBudget(String usd) {
    return 'Spende al massimo \$$usd ogni volta.';
  }

  @override
  String auAxSayCooldown(String n) {
    return 'a distanza di almeno $n minuti';
  }

  @override
  String auAxSayDates(String from, String to) {
    return 'dal $from al $to';
  }

  @override
  String auAxSayDays(String days) {
    return 'di $days';
  }

  @override
  String auAxSayDoes(String who, String what) {
    return '$who fa: «$what».';
  }

  @override
  String auAxSayEmail(String filter) {
    return 'Quando arriva un\'email ($filter)';
  }

  @override
  String auAxSayFiles(String path) {
    return 'Quando cambiano i file in $path';
  }

  @override
  String get auAxSayFilesAll => 'Quando cambiano i file del progetto';

  @override
  String auAxSayFrom(String from) {
    return 'da $from';
  }

  @override
  String auAxSayHours(String from, String to) {
    return 'tra le $from e le $to';
  }

  @override
  String auAxSayMax(String n) {
    return 'al massimo $n volte al giorno';
  }

  @override
  String auAxSayMessage(String where) {
    return 'Quando ti scrivono su $where';
  }

  @override
  String get auAxSayNever => 'Scegli quando parte.';

  @override
  String get auAxSayOnly => 'Solo';

  @override
  String get auAxSayQuiet => 'Non ti avvisa.';

  @override
  String auAxSayReminder(String text) {
    return 'Ti arriva il messaggio: «$text».';
  }

  @override
  String get auAxSayStartup => 'All\'avvio di Rasgeth';

  @override
  String get auAxSayTask => 'Quando finisce un lavoro';

  @override
  String auAxSayTell(String where) {
    return 'Ti avvisa su $where.';
  }

  @override
  String auAxSayTellFailure(String where) {
    return 'Ti avvisa su $where, solo se va storto qualcosa.';
  }

  @override
  String auAxSayWith(String words) {
    return 'con «$words»';
  }

  @override
  String auAxSayWithout(String words) {
    return 'mai con «$words»';
  }

  @override
  String auAxSayWordsAll(String words) {
    return 'con tutte «$words»';
  }

  @override
  String auAxSayWordsAny(String words) {
    return 'con una di «$words»';
  }

  @override
  String get auAxSenders => 'Mittenti';

  @override
  String get auAxSendersPlaceholder => 'banca, anna@esempio.it, +39 333';

  @override
  String get auAxServerSays => 'Non va ancora:';

  @override
  String get auAxSession => 'Ogni volta';

  @override
  String get auAxSessionContinue => 'La stessa, che si ricorda';

  @override
  String get auAxSessionNew => 'Una conversazione nuova';

  @override
  String get auAxStart_after => 'Dopo un\'altra automazione';

  @override
  String get auAxStart_files => 'File che cambiano';

  @override
  String get auAxStart_message => 'Un messaggio in chat';

  @override
  String get auAxStart_startup => 'All\'avvio di Rasgeth';

  @override
  String get auAxStart_task => 'Quando finisce un lavoro';

  @override
  String get auAxStart_time => 'A un orario';

  @override
  String get auAxStartupHelp => 'Parte ogni volta che Rasgeth si accende.';

  @override
  String get auAxTask_abandoned => 'Abbandonato';

  @override
  String get auAxTask_not_testable => 'Finito, senza prova';

  @override
  String get auAxTask_verified => 'Finito e controllato';

  @override
  String get auAxTell => 'Dove ti avvisa';

  @override
  String get auAxTellAllHelp => 'Se non scegli niente: su tutte le chat che hai collegato.';

  @override
  String get auAxTellAlways => 'Ogni volta';

  @override
  String get auAxTellEmailFrom => 'Mandata da';

  @override
  String get auAxTellEmailTo => 'Email a';

  @override
  String get auAxTellEmailToHelp => 'Vuoto: alla casella stessa.';

  @override
  String get auAxTellFailure => 'Solo se va storto qualcosa';

  @override
  String get auAxTellHelp => 'Quando ha finito, dove arriva la risposta.';

  @override
  String get auAxTellNever => 'Mai';

  @override
  String get auAxTellReplyHelp =>
      'Quando parte da un messaggio in chat, risponde anche in quella chat.';

  @override
  String get auAxTellSomeHelp => 'Solo dove hai scelto.';

  @override
  String get auAxTellWhere => 'Dove';

  @override
  String get auAxTimeout => 'Tempo massimo, in minuti';

  @override
  String get auAxTo => 'Alle';

  @override
  String get auAxToAllChats => 'tutte le tue chat';

  @override
  String get auAxToDay => 'Al giorno';

  @override
  String get auAxToEmail => 'Email';

  @override
  String get auAxToWeb => 'Un avviso qui';

  @override
  String get auAxWhen => 'Quando';

  @override
  String get auAxWhenHelp => 'Che cosa la fa partire. Puoi sceglierne più d\'una: parte a ognuna.';

  @override
  String auAxWhenMinutes(String n) {
    return 'Ogni $n minuti';
  }

  @override
  String get auAxWithout => 'Parole che la fermano';

  @override
  String get auAxWithoutPlaceholder => 'newsletter, pubblicità';

  @override
  String get auAxWords => 'Parole';

  @override
  String get auAxWordsHelp => 'Separate da virgole.';

  @override
  String get auAxWordsPlaceholder => 'urgente, fattura';

  @override
  String get auAxWorkHours => 'Orario d\'ufficio';

  @override
  String get auAxYamlBack => 'Torna alle scelte qui sopra';

  @override
  String get auCancel => 'Annulla';

  @override
  String get auCreate => 'Crea';

  @override
  String get auDay_0 => 'domenica';

  @override
  String get auDay_1 => 'lunedì';

  @override
  String get auDay_2 => 'martedì';

  @override
  String get auDay_3 => 'mercoledì';

  @override
  String get auDay_4 => 'giovedì';

  @override
  String get auDay_5 => 'venerdì';

  @override
  String get auDay_6 => 'sabato';

  @override
  String get auDelete => 'Elimina';

  @override
  String get auDeleteAutomationConfirm => 'Eliminare questa automazione e il suo storico?';

  @override
  String get auDeliveryDelivered => 'consegnata';

  @override
  String auDeliveryDeliveredTo(String to) {
    return 'consegnata: $to';
  }

  @override
  String auDeliveryFailed(String reason) {
    return 'non consegnata: $reason';
  }

  @override
  String get auDeliveryNoChat => 'non consegnata: nessuna chat collegata';

  @override
  String get auDisabled => 'Spenta';

  @override
  String get auDismiss => 'Chiudi';

  @override
  String get auEmailAny => 'qualunque';

  @override
  String get auEmailFrom => 'da';

  @override
  String get auEmailFromPlaceholder => 'Mittente (parte dell\'indirizzo, facoltativo)';

  @override
  String get auEmailNeedFirst =>
      'Prima collega la casella email: finché non è collegata, questa automazione non parte.';

  @override
  String get auEmailSubject => 'L\'oggetto contiene';

  @override
  String get auEmailSubjectPlaceholder => 'L\'oggetto contiene (facoltativo)';

  @override
  String auEmailWatching(String user, String host) {
    return 'Guarda $user su $host.';
  }

  @override
  String get auEnabled => 'Attiva';

  @override
  String get auNewAutomation => 'Nuova automazione';

  @override
  String get auNewReminder => 'Nuovo promemoria';

  @override
  String get auNewSecret => 'Nuovo segreto';

  @override
  String get auNextRun => 'prossima';

  @override
  String get auNoAutomations =>
      'Ancora nessuna automazione. Scrivi una ricetta: quando parte, quale agente lavora, cosa gli si chiede.';

  @override
  String get auNoRuns => 'Nessuna esecuzione.';

  @override
  String get auOpen => 'apri';

  @override
  String get auOpenSession => 'Apri la sessione';

  @override
  String get auProjects => 'Progetti';

  @override
  String get auRecipeBroken => 'La ricetta non si legge più: aprila per correggerla';

  @override
  String get auReminderDay => 'Giorno';

  @override
  String get auReminderPurpose =>
      'Rasgeth ti manda questo testo su Telegram all\'ora che scegli, una volta sola. Nessun agente, nessun costo.';

  @override
  String get auReminderSave => 'Salva il promemoria';

  @override
  String get auReminderWhat => 'Cosa ricordarti';

  @override
  String get auRepoEvent_issue_comment => 'Commenti';

  @override
  String get auRepoEvent_issues => 'Issue';

  @override
  String get auRepoEvent_pull_request => 'Pull request';

  @override
  String get auRepoEvent_push => 'Nuovi commit';

  @override
  String get auRepoEvent_release => 'Rilasci';

  @override
  String get auRunNow => 'Esegui ora';

  @override
  String get auRunStatus => 'in corso,fatta,fallita,scaduta,saltata';

  @override
  String get auRunTriggers => 'orario,webhook,a mano,recuperata';

  @override
  String get auRuns => 'Esecuzioni';

  @override
  String get auSave => 'Salva';

  @override
  String get auSettings => 'Impostazioni';

  @override
  String get auTplDesc_blank => 'Scegli tu quando, chi e cosa.';

  @override
  String get auTplDesc_morning =>
      'Ogni giorno lavorativo alle 8: cosa è successo in ogni progetto.';

  @override
  String get auTplDesc_spending => 'Il primo del mese: quanto si è speso e dove.';

  @override
  String get auTplDesc_weekly => 'Il venerdì alle 17: la settimana in un messaggio.';

  @override
  String get auTplText_morning =>
      'Dimmi in poche righe cosa è successo ieri in ogni progetto: lavori finiti, problemi ancora aperti, decisioni da prendere.';

  @override
  String get auTplText_spending =>
      'Dimmi quanto si è speso il mese scorso, per progetto e per agente, e se qualcosa sembra fuori dal normale.';

  @override
  String get auTplText_weekly =>
      'Riassumi questa settimana in ogni progetto: cosa è stato finito, cosa è in ritardo, cosa è previsto per la prossima.';

  @override
  String get auTplTitle_blank => 'Da zero';

  @override
  String get auTplTitle_morning => 'Il punto del mattino';

  @override
  String get auTplTitle_spending => 'Le spese del mese';

  @override
  String get auTplTitle_weekly => 'Le novità della settimana';

  @override
  String get auWebhookSecretOnce =>
      'Segreto (si vede solo ora; va mandato nell\'header x-redgiant-secret):';

  @override
  String get auWebhookUrl => 'Webhook';

  @override
  String auWhenAt(String at) {
    return 'Una volta, il $at';
  }

  @override
  String get auWhenAtTime => 'alle';

  @override
  String auWhenCustom(String cron) {
    return 'Con un orario tutto suo ($cron)';
  }

  @override
  String auWhenDaily(String time) {
    return 'Ogni giorno alle $time';
  }

  @override
  String get auWhenDayOfMonth => 'il giorno';

  @override
  String auWhenEmail(String filter) {
    return 'Quando arriva una email ($filter)';
  }

  @override
  String get auWhenEmailHelp =>
      'La casella si imposta una volta, qui o in Impostazioni › Automazioni › Casella email. L\'email arriva all\'agente come informazione, mai come istruzioni.';

  @override
  String get auWhenEveryHours => 'ogni (ore)';

  @override
  String auWhenHours(String n) {
    return 'Ogni $n ore';
  }

  @override
  String get auWhenKind_daily => 'Ogni giorno';

  @override
  String get auWhenKind_email => 'A una email';

  @override
  String get auWhenKind_hours => 'Ogni tot ore';

  @override
  String get auWhenKind_monthly => 'Una volta al mese';

  @override
  String get auWhenKind_repo => 'Sul repository';

  @override
  String get auWhenKind_webhook => 'A una chiamata web';

  @override
  String get auWhenKind_weekdays => 'Giorni lavorativi';

  @override
  String get auWhenKind_weekly => 'Alcuni giorni della settimana';

  @override
  String auWhenMonthly(String day, String time) {
    return 'Ogni mese il giorno $day alle $time';
  }

  @override
  String auWhenRepo(String events) {
    return 'Quando succede qualcosa nel repository ($events)';
  }

  @override
  String get auWhenRepoHelp =>
      'Rasgeth aggiunge il webhook al repository del progetto da solo: su Gitea subito, su GitHub quando l\'accesso da fuori casa è attivo.';

  @override
  String get auWhenWebhook => 'Quando arriva una chiamata web (webhook)';

  @override
  String get auWhenWebhookHelp =>
      'Un altro programma (un sito, un modulo, GitHub…) chiama l\'indirizzo di Rasgeth; indirizzo e segreto compaiono dopo il salvataggio.';

  @override
  String auWhenWeekdays(String time) {
    return 'Dal lunedì al venerdì alle $time';
  }

  @override
  String auWhenWeekly(String days, String time) {
    return 'Ogni settimana il $days alle $time';
  }

  @override
  String auWhoLead(String project) {
    return 'Capo di $project';
  }

  @override
  String get auOwnHubHint =>
      'Quando le cose succedono da sole: orari, email, chat, file, promemoria';

  @override
  String get auOwnOpenChat => 'Apri la conversazione';

  @override
  String get auOwnTalkGod => 'Parla con God';

  @override
  String get auOwnMailboxesElsewhere =>
      'Le caselle si aggiungono e si cambiano in Impostazioni › Canali e caselle.';

  @override
  String get auOwnNoMailboxes => 'Ancora nessuna casella collegata.';

  @override
  String get auOwnCopied => 'Copiato';

  @override
  String get auOwnCopy => 'Copia';

  @override
  String get auOwnYamlLabel => 'La ricetta in YAML';

  @override
  String get auOwnRoutineOpen => 'Apri la routine';

  @override
  String get auOwnNoticeOpen => 'Apri';

  @override
  String auOwnNoticeFailed(String name) {
    return '$name: non riuscita';
  }

  @override
  String get auOwnPickTitle => 'Scegli';

  @override
  String auOwnNeedOpenWhere(String where) {
    return 'Si fa in Impostazioni › $where';
  }

  @override
  String get auOwnWhereChats => 'Canali e caselle';

  @override
  String get auOwnWhereExtensions => 'Estensioni';

  @override
  String get auOwnWhereKeychain => 'Portachiavi';

  @override
  String auOwnLoadFailed(String why) {
    return 'Non riesco a leggere: $why';
  }

  @override
  String get auOwnReadOnly =>
      'Le automazioni le cambia solo la persona (non da un dispositivo di progetto).';

  @override
  String get cvChSecretAnyway => 'Invia comunque';

  @override
  String get cvChSecretAnywayNote =>
      'Non è un segreto (un link, un codice d\'ordine)? «Invia comunque» lo manda come l\'hai scritto.';

  @override
  String get echoSearch => 'Cerca nelle conversazioni passate';

  @override
  String get echoClear => 'Cancella la ricerca';

  @override
  String get echoNone => 'Nessuna conversazione passata ha queste parole.';

  @override
  String get echoArchived => 'archiviato';

  @override
  String echoMatches(String n) {
    return '$n messaggi';
  }

  @override
  String get echoMatch => '1 messaggio';

  @override
  String get echoYou => 'Tu';

  @override
  String get echoHint =>
      'Scrivi almeno due lettere: ogni parola si cerca in quello che hai scritto tu e gli agenti.';

  @override
  String get skSection => 'Skill';

  @override
  String get skHub => 'Le skill degli agenti, le loro versioni e il ritorno indietro';

  @override
  String get skQuestion => 'Cosa hanno imparato gli agenti';

  @override
  String get skLead =>
      'Le skill sono istruzioni che gli agenti scrivono dopo un lavoro andato bene, o che dai tu. Ognuna tiene le sue versioni: chi l\'ha scritta, perché e quando, e puoi tornare a una qualsiasi.';

  @override
  String get skWaitingTitle => 'Ti aspettano';

  @override
  String get skWaitingLead =>
      'Skill nuove e versioni nuove di quelle installate, provate a parte. Non cambia niente finché non dici di sì.';

  @override
  String get skNoneWaiting => 'Non ti aspetta niente.';

  @override
  String get skNew => 'Skill nuova';

  @override
  String get skUpdate => 'Nuova versione di una skill installata';

  @override
  String skBy(String who) {
    return 'di $who';
  }

  @override
  String get skWhy => 'Perché';

  @override
  String get skTestsOk => 'Le sue prove sono passate.';

  @override
  String skScripts(String files) {
    return 'Ha degli script ($files): il codice non si installa mai da solo.';
  }

  @override
  String get skApprove => 'Approva';

  @override
  String get skReject => 'Rifiuta';

  @override
  String get skNextSession =>
      'Una volta installata, gli agenti la usano dalla loro conversazione successiva; quelli che stanno già parlando tengono la versione con cui hanno cominciato.';

  @override
  String get skInstalledTitle => 'Installate';

  @override
  String get skInstalledLead => 'Aprine una per vedere le sue versioni.';

  @override
  String get skNoneInstalled => 'Ancora nessuna skill.';

  @override
  String get skEverywhere => 'per tutti i progetti';

  @override
  String skProject(String name) {
    return 'progetto $name';
  }

  @override
  String get skVersionsTitle => 'Versioni';

  @override
  String get skVersionsLead => 'Gli agenti usano la più nuova dalla loro conversazione successiva.';

  @override
  String skVersion(String n) {
    return 'Versione $n';
  }

  @override
  String get skCurrent => 'in uso';

  @override
  String get skHow_baseline => 'Com\'era prima della cronologia';

  @override
  String get skHow_edited => 'Cambiata a mano';

  @override
  String get skHow_install => 'Prima versione';

  @override
  String get skHow_update => 'Nuova versione';

  @override
  String get skHow_import => 'Importata';

  @override
  String skHow_rollback(String n) {
    return 'Ritorno alla versione $n';
  }

  @override
  String get skUnknown => 'autore sconosciuto';

  @override
  String get skYou => 'te';

  @override
  String get skApprovedYou => 'approvata da te';

  @override
  String get skApprovedAuto => 'installata da sola (la tua scelta in Sicurezza)';

  @override
  String get skCompare => 'Confronta con quella in uso';

  @override
  String get skHideCompare => 'Nascondi il confronto';

  @override
  String skRollback(String n) {
    return 'Torna alla versione $n';
  }

  @override
  String skRollbackTitle(String n) {
    return 'Tornare alla versione $n?';
  }

  @override
  String skRollbackText(String name) {
    return 'I suoi file prendono il posto di quelli di «$name» in uso, come versione nuova: non si perde niente e puoi tornare qui. Gli agenti la usano dalla loro conversazione successiva.';
  }

  @override
  String skRolledBack(String n, String v) {
    return 'Tornata alla versione $n: adesso è la versione $v.';
  }

  @override
  String get skNotRestorable => 'Troppo grande per essere conservata: non può tornare.';

  @override
  String get skNoVersions => 'Ancora nessuna versione.';

  @override
  String get skLineTitle => 'Cosa è cambiato e perché';

  @override
  String get skCompareFull => 'Confronta: tutte le differenze';

  @override
  String get cvVwKindTimeline => 'Timeline video';

  @override
  String get jobNoticeStarting => 'Sta per partire…';

  @override
  String jobNoticePercent(int percent) {
    return '$percent% fatto';
  }

  @override
  String jobNoticePercentLeft(int percent, int min) {
    return '$percent% fatto, mancano circa $min min';
  }

  @override
  String get jobNoticeDone => 'Fatto: aprilo nel Canvas.';

  @override
  String get jobNoticeFailed => 'Non è riuscito.';

  @override
  String jobNoticeFailedWhy(String why) {
    return 'Non è riuscito: $why';
  }

  @override
  String get jobNoticeCancelled => 'Fermato.';

  @override
  String saveCancelled(String name) {
    return 'Salvataggio di $name fermato';
  }

  @override
  String saveTooBigPhone(String name, String size) {
    return '$name è troppo grande per salvarlo dal telefono ($size): salvalo dal computer';
  }

  @override
  String get cvAllowWork => 'Consenti sempre per questo lavoro';

  @override
  String get cvAllowWorkHint =>
      'Consenti lo stesso tipo di comando sulla stessa macchina senza chiederlo più, per il resto del lavoro di questa conversazione';

  @override
  String get cvChSecretKindExport => 'un\'esportazione di password';

  @override
  String get cvPwOne => '1 password';

  @override
  String cvPwMany(String n) {
    return '$n password';
  }

  @override
  String get cvPwExportTitle => 'Questa è un\'esportazione di password';

  @override
  String cvPwExportText(String what) {
    return 'Nel messaggio ci sono $what esportate da un gestore di password. In una conversazione non vanno: le terrebbero il modello, il registro, la ricerca e la trascrizione del motore.';
  }

  @override
  String get cvPwExportVault => 'Mettile nel Portachiavi';

  @override
  String get cvPwExportWithout => 'Invia senza';

  @override
  String get cvPwExportWithoutNote => '«Invia senza» manda le tue parole senza l\'esportazione.';

  @override
  String get cvPwExportAnyway => 'Invia comunque';

  @override
  String cvPwExportAnywayTitle(String what) {
    return 'Mandare $what all\'agente?';
  }

  @override
  String cvPwExportAnywayText(String what) {
    return '$what arriveranno al modello e resteranno nel registro della conversazione, nella ricerca e nella trascrizione del motore. Fallo solo se ne sei sicuro.';
  }

  @override
  String cvPwExportAnywayYes(String what) {
    return 'Invia $what';
  }

  @override
  String cvPwImported(String added, String skipped) {
    return 'Nel Portachiavi: $added nuove, $skipped c\'erano già.';
  }

  @override
  String get cvPwImportClosed =>
      'Il Portachiavi è chiuso: non ho importato niente. Aprilo in Impostazioni › Portachiavi e riprova.';

  @override
  String cvPwImportFailed(String error) {
    return 'Non ho importato niente: $error';
  }

  @override
  String cvPwProposal(String file) {
    return 'Propone di mettere nel tuo Portachiavi le password di $file.';
  }

  @override
  String get cvPwProposalButton => 'Mettile nel Portachiavi';

  @override
  String cvPwProposalAsk(String file) {
    return 'Mettere nel Portachiavi le password di $file?';
  }

  @override
  String get cvPwProposalText =>
      'Vanno nel tuo Portachiavi senza che l\'agente le veda; poi il file viene distrutto.';

  @override
  String get cvPwProposalYes => 'Importa e distruggi il file';

  @override
  String cvPwProposalDone(String added, String file) {
    return '$added password di $file sono nel Portachiavi; il file è distrutto.';
  }

  @override
  String get cvEraseForever => 'Cancella per sempre';

  @override
  String get cvEraseTitle => 'Cancellare per sempre questo messaggio?';

  @override
  String get cvEraseText =>
      'Sparisce dal registro della conversazione, dalla ricerca, dal ritratto e da quello che l\'agente ne ricorda. Non si può annullare.';

  @override
  String get cvEraseTextEngine =>
      'Sparisce dal registro della conversazione, dalla ricerca, dal ritratto, da quello che l\'agente ne ricorda e dalla trascrizione del motore. Non si può annullare.';

  @override
  String cvEraseQuotes(String n) {
    return 'Cancella anche $n risposte e risultati dell\'agente che lo riportano';
  }

  @override
  String get cvEraseYes => 'Cancella per sempre';

  @override
  String cvEraseDone(String n) {
    return 'Cancellato per sempre ($n).';
  }

  @override
  String get cvEraseBusy => 'L\'agente sta lavorando: fermalo o aspetta che finisca, poi riprova.';

  @override
  String get pairAgain => 'Abbina di nuovo';

  @override
  String get statusPairAgain => 'da abbinare di nuovo';

  @override
  String pairAgainTitle(String name) {
    return 'Abbina di nuovo $name';
  }

  @override
  String pairAgainBody(String name) {
    return 'Questo dispositivo non ha più la sua chiave per $name. Scrivi la password: il server resta nell\'elenco con le sue impostazioni e torna a funzionare.';
  }

  @override
  String get pairAgainNote =>
      'Questo dispositivo non ha più la sua chiave per questo server: abbinalo di nuovo con la password, senza toglierlo.';

  @override
  String get errKeystore =>
      'Questo computer non è riuscito a salvare la chiave di accesso nel suo portachiavi, quindi l\'abbinamento è stato annullato e sul server non resta un dispositivo in più. Riprova. Se succede ancora, riavvia il computer e accedi con la password, non con il PIN.';

  @override
  String get errKeystoreDetails => 'Dettagli';

  @override
  String get devForgetUnused => 'Togli quelli mai usati';

  @override
  String get devForgetUnusedTitle => 'Togliere i dispositivi mai usati?';

  @override
  String get devForgetUnusedBody =>
      'Vanno via tutti i dispositivi che non hanno mai fatto un accesso (per esempio un\'app che non è riuscita a tenere la sua chiave). Restano quelli abbinati negli ultimi dieci minuti: potrebbero collegarsi proprio adesso.';

  @override
  String devForgetUnusedDone(int count) {
    return 'Dispositivi tolti: $count.';
  }

  @override
  String get chAxCat_other => 'Altro';

  @override
  String get chAxCat_personal => 'Personale';

  @override
  String get chAxCat_social => 'Social';

  @override
  String get chAxCat_work => 'Lavoro';

  @override
  String get chAxMailboxAdd => 'Aggiungi casella';

  @override
  String get chAxMailboxAddText => 'Quante vuoi, ognuna nella sua categoria.';

  @override
  String get chAxMailboxAgents => 'Gli agenti possono usarla';

  @override
  String get chAxMailboxAgentsHelp =>
      'Cercano, leggono e scrivono bozze qui; ogni email che inviano te la chiede prima e te la mostra intera.';

  @override
  String get chAxMailboxCategory => 'Categoria';

  @override
  String get chAxMailboxName => 'Come la chiami';

  @override
  String get chAxMailboxNameHelp => 'Per esempio Lavoro o Gmail; vuoto: l\'indirizzo.';

  @override
  String get chAxMailboxNew => 'Nuova casella';

  @override
  String get chAxMailboxNewCategory => 'Oppure una categoria nuova';

  @override
  String get chAxMailboxNewCategoryPlaceholder => 'Famiglia, Circolo, Negozio…';

  @override
  String get chAxMailboxPasswordKept => 'Lasciala vuota per tenere quella che hai già dato.';

  @override
  String get chAxMailboxPurpose =>
      'Una casella per le automazioni: si legge solo la posta nuova, niente viene segnato o spostato.';

  @override
  String chAxMailboxesWatching(String n, String names) {
    return '$n caselle collegate: $names.';
  }

  @override
  String get chAxSmtpHost => 'Server per mandare (SMTP)';

  @override
  String get chAxSmtpHostHelp =>
      'Serve solo per ricevere i messaggi via email; vuoto: quello solito.';

  @override
  String get chAxSmtpPort => 'Porta per mandare';

  @override
  String get chChatChange => 'Cambia le impostazioni';

  @override
  String get chChatDiscordHow =>
      'Nel Discord Developer Portal crea un\'applicazione, aggiungi un bot, accendi Message Content Intent, copia il token e invita il bot in un tuo server (o scrivigli direttamente).';

  @override
  String get chChatDiscordToken => 'Token del bot';

  @override
  String get chChatImHow =>
      'Apple non offre iMessage ai programmi: serve un Mac sempre acceso, con l\'accesso a Messaggi e il server gratuito BlueBubbles. Il Mac risponde con il suo ID Apple: usane uno fatto apposta per Rasgeth, non il tuo.';

  @override
  String get chChatImLimits =>
      'Senza la Private API le risposte non si possono modificare e non compare «sta scrivendo»; approvazioni e domande si rispondono con i numeri. Mentre il Mac dorme o è spento i messaggi aspettano e arrivano al risveglio.';

  @override
  String get chChatImPassword => 'Password del server BlueBubbles';

  @override
  String get chChatImPrivate =>
      'La Private API di BlueBubbles è attiva (modifiche e «sta scrivendo...»)';

  @override
  String get chChatImStep1 =>
      'Sul Mac crea (o usa) un ID Apple solo per Rasgeth e accedi con quello in Messaggi.';

  @override
  String get chChatImStep2 =>
      'Scarica BlueBubbles Server da bluebubbles.app, aprilo e scegli una password del server.';

  @override
  String get chChatImStep3 =>
      'Quando lo chiede, consenti Accesso completo al disco e Accessibilità in Impostazioni di Sistema, Privacy e sicurezza: gli servono per leggere e mandare i messaggi.';

  @override
  String get chChatImStep4 =>
      'In BlueBubbles impedisci al Mac di andare in stop e annota il suo indirizzo: http://<indirizzo del Mac>:1234 in casa, oppure l\'indirizzo del suo tunnel da fuori.';

  @override
  String get chChatImStep5 =>
      'Scrivi qui indirizzo e password e premi Collega. Dal tuo iPhone scrivi all\'ID Apple del passo 1 e manda il codice.';

  @override
  String get chChatImUrl => 'Indirizzo del server BlueBubbles (http://...:1234)';

  @override
  String chChatLinked(String who) {
    return 'Collegato: $who';
  }

  @override
  String get chChatMatrixE2ee =>
      'Chat cifrate: in Element le chat dirette sono cifrate e il bot non riesce a leggerle. Per tenere la cifratura avvia Pantalaimon (l\'aiutante gratuito di Matrix per la cifratura) accanto a Rasgeth e scrivi il suo indirizzo al posto di quello del server.';

  @override
  String get chChatMatrixHomeserver => 'Indirizzo del server (per esempio https://matrix.org)';

  @override
  String get chChatMatrixHow =>
      'Rasgeth ha bisogno di un account Matrix tutto suo, non il tuo: è quello a cui scriverai.';

  @override
  String get chChatMatrixStep1 =>
      'Crea un account nuovo per il bot, per esempio su app.element.io (o sul tuo server).';

  @override
  String get chChatMatrixStep2 =>
      'Entrato come bot, apri Impostazioni, Aiuto e informazioni, Avanzate, Token di accesso, e copialo. Poi chiudi quella scheda senza uscire dall\'account: uscendo il token si annulla.';

  @override
  String get chChatMatrixStep3 =>
      'Scrivi qui l\'indirizzo del server e incolla il token, poi premi Collega.';

  @override
  String get chChatMatrixStep4 =>
      'Dal tuo account crea una stanza nuova senza cifratura (spegni «Attiva la crittografia end-to-end»), invita il bot (entra da solo) e manda il codice che compare.';

  @override
  String get chChatMatrixToken => 'Il token di accesso dell\'account del bot';

  @override
  String get chChatSendCode => 'Manda questo dalla chat per collegarla:';

  @override
  String get chChatSignalHow =>
      'Signal ha bisogno di signal-cli-rest-api acceso con un numero suo collegato (una seconda SIM o un dispositivo collegato); scrivi qui il suo indirizzo e il numero.';

  @override
  String get chChatSignalNumber => 'Il numero del bot (+39...)';

  @override
  String get chChatSignalUrl => 'Indirizzo di signal-cli-rest-api';

  @override
  String get chChatSlackApp => 'Token dell\'app (xapp-..., connections:write)';

  @override
  String get chChatSlackBot => 'Token del bot (xoxb-...)';

  @override
  String get chChatSlackHow =>
      'Su api.slack.com/apps crea un\'app, accendi Socket Mode (non serve un indirizzo pubblico), aggiungi i permessi chat:write, im:history, app_mentions:read, files:read, files:write, iscriviti a message.im e app_mention, installala e copia i due token.';

  @override
  String get chChatSteps => 'Passo per passo';

  @override
  String get chChatTeamsAppId => 'Microsoft App ID';

  @override
  String get chChatTeamsDownload => 'Scarica l\'app per Teams';

  @override
  String chChatTeamsEndpoint(String url) {
    return 'Endpoint di messaggistica per Azure: $url';
  }

  @override
  String get chChatTeamsFiles =>
      'I file di Rasgeth arrivano come una scheda da accettare: accettati, finiscono nel tuo OneDrive. A un bot di Teams non si possono mandare messaggi vocali.';

  @override
  String get chChatTeamsHow =>
      'Teams parla con i bot solo attraverso Microsoft Azure. Serve un account Microsoft 365 di lavoro o scuola che possa aggiungere app personalizzate (Teams gratuito per uso personale non accetta bot) e Rasgeth raggiungibile da fuori (Impostazioni, Accesso da fuori).';

  @override
  String get chChatTeamsSecret => 'Segreto client (il suo Valore)';

  @override
  String get chChatTeamsStep1 =>
      'Apri portal.azure.com (basta un account gratuito), scegli Crea una risorsa, cerca Azure Bot e premi Crea.';

  @override
  String get chChatTeamsStep2 =>
      'Dagli un nome, scegli il piano gratuito (F0), Tipo di app: Tenant singolo, Tipo di creazione: Crea un nuovo ID app Microsoft. Premi Crea, poi Vai alla risorsa.';

  @override
  String chChatTeamsStep3(String url) {
    return 'In Configurazione scrivi questo Endpoint di messaggistica e premi Applica: $url. Copia il Microsoft App ID e l\'App Tenant ID.';
  }

  @override
  String get chChatTeamsStep4 =>
      'Accanto a Microsoft App ID premi Gestisci password, poi Nuovo segreto client, Aggiungi, e copia il suo Valore (si vede una volta sola).';

  @override
  String get chChatTeamsStep5 =>
      'In Canali aggiungi Microsoft Teams, accetta le condizioni e premi Applica.';

  @override
  String get chChatTeamsStep6 =>
      'Incolla qui i tre valori e premi Collega. Poi scarica l\'app per Teams con il pulsante che compare.';

  @override
  String get chChatTeamsTenant => 'App Tenant ID';

  @override
  String get chChatTeamsUpload =>
      'In Teams apri App, Gestisci le tue app, Carica un\'app, Carica un\'app personalizzata, scegli il file scaricato e premi Aggiungi. Poi apri la chat con Rasgeth e manda il codice.';

  @override
  String get chChatTurnOff => 'Spegni';

  @override
  String get chChatWaHow =>
      'In Meta for Developers crea un\'app WhatsApp, copia il token di accesso, l\'ID del numero e il segreto dell\'app, e scegli un token di verifica. WhatsApp manda i messaggi a un indirizzo pubblico: Rasgeth deve essere raggiungibile da fuori (Impostazioni, Accesso da fuori).';

  @override
  String get chChatWaPhoneId => 'ID del numero di telefono';

  @override
  String get chChatWaSecret => 'Segreto dell\'app';

  @override
  String get chChatWaToken => 'Token di accesso';

  @override
  String get chChatWaVerify => 'Token di verifica (sceglilo tu)';

  @override
  String chChatWaWebhook(String url) {
    return 'Webhook per Meta: $url con il token di verifica che hai scelto; iscriviti a messages.';
  }

  @override
  String get chChats => 'Altre chat';

  @override
  String get chChatsHint =>
      'Parla con il Demi-God anche da Discord, Slack, Signal, WhatsApp, Matrix, Teams o iMessage. È una conversazione sola: cominciata su Telegram o qui, continua ovunque scrivi. Approvazioni e domande arrivano con i pulsanti (su Signal, Matrix e iMessage, con i numeri da rispondere).';

  @override
  String get chEmailChange => 'Cambia';

  @override
  String get chEmailConnect => 'Collega la casella email';

  @override
  String chEmailConnected(String host, String user) {
    return 'Leggo $user su $host.';
  }

  @override
  String get chEmailHost => 'Server di posta (IMAP)';

  @override
  String get chEmailHostHelp =>
      'Per esempio imap.gmail.com, outlook.office365.com, imap.mail.me.com.';

  @override
  String get chEmailNeedFirst =>
      'Prima collega la casella email: finché non è collegata, questa automazione non parte.';

  @override
  String get chEmailNotConnected => 'Non collegata';

  @override
  String get chEmailPassword => 'Password per le app';

  @override
  String get chEmailPasswordHelp =>
      'Meglio una password per le app (Gmail, Outlook e iCloud la creano nelle impostazioni di sicurezza dell\'account) che la tua: la puoi revocare quando vuoi. Resta in un file privato sul tuo server.';

  @override
  String get chEmailPort => 'Porta';

  @override
  String get chEmailPurpose =>
      'Una routine può partire quando arriva una email (una fattura, un avviso). Rasgeth guarda solo la posta nuova, ogni due minuti, e non cambia niente nella tua casella; l\'email arriva all\'agente come informazione, mai come istruzioni.';

  @override
  String get chEmailSave => 'Collega la casella';

  @override
  String get chEmailSecure => 'Cifrata da subito (porta 993)';

  @override
  String get chEmailTesting => 'Provo la casella…';

  @override
  String get chEmailTileText => 'Per le automazioni che partono quando arriva una email.';

  @override
  String get chEmailTitle => 'Casella email';

  @override
  String get chEmailUser => 'Indirizzo o nome utente';

  @override
  String chEmailWatching(String host, String user) {
    return 'Guarda $user su $host.';
  }

  @override
  String get chInput => 'letti';

  @override
  String get chRemove => 'Rimuovi';

  @override
  String get chSbChatAccounts => 'Account collegati';

  @override
  String get chSbChatDiscordText => 'Un bot nel tuo server Discord, in privato o in un canale.';

  @override
  String get chSbChatImText =>
      'Con un Mac sempre acceso e BlueBubbles: risponde l\'app Messaggi del Mac.';

  @override
  String get chSbChatMatrixText =>
      'Un account bot su qualsiasi server Matrix (matrix.org o il tuo), in chat o in una stanza.';

  @override
  String get chSbChatNoAccount =>
      'Ancora nessun account collegato: manda il codice qui sotto dalla chat.';

  @override
  String get chSbChatOnWaiting => 'Acceso: manda il codice dalla chat';

  @override
  String get chSbChatSignalText => 'Un numero Signal tutto suo, con signal-cli-rest-api.';

  @override
  String get chSbChatSlackText =>
      'Un\'app nel tuo spazio di lavoro Slack, in Socket Mode: niente indirizzo pubblico.';

  @override
  String get chSbChatTeamsText =>
      'Un bot in Microsoft Teams, per account di lavoro o scuola, con un Azure Bot gratuito.';

  @override
  String get chSbChatWaText => 'Il tuo numero WhatsApp Business, con la Cloud API di Meta.';

  @override
  String get chSbChatWaiting => 'Aspetto il codice… questa finestra se ne accorge da sola.';

  @override
  String get chSbChatsQ => 'Parla con Demi-God anche da altre app';

  @override
  String get chStTgAccounts => 'Account collegati';

  @override
  String get chTelegram => 'Telegram';

  @override
  String get chTgChangeBot => 'Usa un altro bot';

  @override
  String chTgLinked(String who) {
    return 'Collegato a $who';
  }

  @override
  String get chTgLinkedHint =>
      'Scrivi al tuo bot quando vuoi: Demi-God lo passa a God e ti riporta la risposta.';

  @override
  String chTgOpenBot(String bot) {
    return 'Apri @$bot';
  }

  @override
  String get chTgQr => 'Inquadra con la fotocamera del telefono';

  @override
  String get chTgWaiting => 'Aspetto che premi Avvia… questa pagina se ne accorge da sola.';

  @override
  String get chUnlink => 'Scollega';

  @override
  String get chWzConnect => 'Collega';

  @override
  String get chWzDoneBtn => 'Fatto';

  @override
  String get chWzLocked => 'impostato dall\'ambiente';

  @override
  String get chWzTgAsks => 'Qui ti avviso anche quando serve un tuo sì.';

  @override
  String get chWzTgBf1 => 'Va bene. Come lo chiamiamo?';

  @override
  String get chWzTgBf2 => 'Ora un nome utente, che finisca con «bot».';

  @override
  String get chWzTgBf3 => 'Fatto! Ecco il token: 123456789:AAH…';

  @override
  String get chWzTgBfName => 'Il mio Rasgeth';

  @override
  String get chWzTgCheck => 'Controlla';

  @override
  String get chWzTgChecking => 'Controllo…';

  @override
  String get chWzTgDone => 'fatto';

  @override
  String get chWzTgExampleBot => 'il_mio_rasgeth_bot';

  @override
  String get chWzTgHaveToken => 'Ho già un token';

  @override
  String chWzTgHello(String demigod, String god) {
    return 'Ciao, sono $demigod. Scrivimi quando vuoi: passo tutto a $god e ti riporto la risposta.';
  }

  @override
  String get chWzTgLater => 'dopo';

  @override
  String chWzTgLead(String demigod) {
    return 'Con Telegram scrivi a $demigod da dove vuoi e ricevi lì gli avvisi: approvazioni, domande, lavori lunghi, budget. Tre passi, un paio di minuti.';
  }

  @override
  String chWzTgLinked(String demigod, String who) {
    return 'Collegato a $who. Scrivi a $demigod quando vuoi.';
  }

  @override
  String get chWzTgLinkedShort => 'Collegato. Scrivi al tuo bot quando vuoi.';

  @override
  String get chWzTgMessage => 'Messaggio';

  @override
  String get chWzTgNow => 'adesso';

  @override
  String get chWzTgOfficial => 'bot ufficiale di Telegram';

  @override
  String get chWzTgOnline => 'bot · online';

  @override
  String get chWzTgOpenBf => 'Apri BotFather';

  @override
  String get chWzTgPressStart => 'Premi Avvia per iniziare a parlare con questo bot.';

  @override
  String get chWzTgQ => 'Rasgeth sul tuo telefono';

  @override
  String get chWzTgStart => 'AVVIA';

  @override
  String get chWzTgStep1 => 'Crea il bot con @BotFather';

  @override
  String get chWzTgStep1Text =>
      'BotFather è il bot ufficiale di Telegram che crea i bot. Scrivigli /newbot, dagli un nome e un nome utente che finisce con «bot».';

  @override
  String get chWzTgStep2 => 'Incolla il token';

  @override
  String get chWzTgStep2Text =>
      'BotFather risponde con una riga lunga, tipo 123456789:AAH… È la chiave del bot: tienila per te.';

  @override
  String get chWzTgStep3 => 'Abbina il telefono';

  @override
  String chWzTgStep3Text(String bot) {
    return 'Apri $bot e premi Avvia: Telegram gli manda da solo questo codice, niente da scrivere.';
  }

  @override
  String get chWzTgToken => 'Il token del bot';

  @override
  String get chWzTgYouWillSee => 'Cosa vedrai in Telegram';

  @override
  String get chWzTgYourBot => 'Il tuo bot';

  @override
  String get chWzTgYourBotName => 'il tuo bot';

  @override
  String get chWzTrying => 'Provo il modello…';

  @override
  String get moActive => 'attivo';

  @override
  String get moAgentModelDefault => 'Il modello predefinito';

  @override
  String get moAgents => 'Agenti';

  @override
  String get moAgentsModel => 'Modello dell\'agente';

  @override
  String get moBackup => 'Backup';

  @override
  String get moBackupModelNone => 'Nessuno: un task abbandonato resta tale';

  @override
  String get moBackupModelTitle => 'Modello di riserva per i task';

  @override
  String get moBrainChatgpt => 'Abbonamento ChatGPT';

  @override
  String get moBrainChatgptDevice =>
      'Se OpenAI dice che l\'accesso con codice dispositivo non è permesso: su chatgpt.com apri Impostazioni, Sicurezza, attiva l\'autorizzazione con codice dispositivo e riprova.';

  @override
  String get moBrainChatgptHint =>
      'Rasgeth usa ChatGPT tramite Codex, il programma ufficiale di OpenAI, collegato al tuo account. Quello che usi conta sui limiti del tuo piano.';

  @override
  String get moBrainChatgptStart => 'Collega ChatGPT';

  @override
  String get moBrainChatgptStep1 => 'Apri questa pagina e accedi:';

  @override
  String get moBrainChatgptStep2 => 'Lì scrivi questo codice:';

  @override
  String get moBrainClaude => 'Abbonamento Claude';

  @override
  String get moBrainClaudeCode => 'Incolla qui il codice';

  @override
  String get moBrainClaudeHint =>
      'Rasgeth usa Claude tramite il programma ufficiale di Anthropic, collegato al tuo account. Quello che usi conta sui limiti del tuo piano, non costa soldi in più.';

  @override
  String get moBrainClaudeOpen => 'Apri la pagina di accesso di Anthropic';

  @override
  String get moBrainClaudeStep2 =>
      'Accedi con il tuo account Claude. Alla fine Anthropic ti mostra un codice: copialo.';

  @override
  String get moBrainConnect => 'Collega';

  @override
  String get moBrainDefault => 'Il modello che usano gli agenti';

  @override
  String get moBrainDefaultHint =>
      'Gli agenti usano questo modello, a meno che tu non ne scelga un altro per loro. Prima di salvarlo viene provato con una domanda vera.';

  @override
  String get moBrainDefaultSaved => 'Salvato: gli agenti useranno questo.';

  @override
  String get moBrainDefaultTry => 'Prova e usa questo';

  @override
  String get moBrainDisconnect => 'Scollega';

  @override
  String get moBrainEffortHelp =>
      'Quanto ragiona prima di rispondere: basso è veloce ed economico, alto è più lento ma più accurato.';

  @override
  String moBrainKeyExample(String example) {
    return 'È fatta così: $example';
  }

  @override
  String moBrainKeyMake(String name) {
    return 'Crea una chiave sulla pagina di $name';
  }

  @override
  String get moBrainKeyTry => 'Prova e salva';

  @override
  String moBrainKeyWorks(String n) {
    return 'Funziona: $n modelli disponibili.';
  }

  @override
  String get moBrainLocal => 'Un modello su questo computer';

  @override
  String get moBrainNoModel =>
      'Non è ancora collegato nessun modello, quindi gli agenti non possono rispondere. Collegane uno qui sopra (un abbonamento, una chiave, o un modello locale al passo dopo), oppure più tardi da Impostazioni, Modelli e abbonamenti.';

  @override
  String get moBrainNotOpened => 'Non si è aperto niente?';

  @override
  String get moBrainOpenHere => 'Aprila da qui';

  @override
  String get moBrainServer => 'Un server tuo';

  @override
  String get moBrainServerHint =>
      'Se fai già girare dei modelli con Ollama, LM Studio o vLLM, dai a Rasgeth il suo indirizzo.';

  @override
  String get moBrainServerKey => 'La sua chiave';

  @override
  String get moBrainServerKeyHelp => 'Solo se il server la chiede; quasi sempre non serve.';

  @override
  String get moBrainServerUrl => 'Indirizzo del server';

  @override
  String get moBrainServerUrlHelp =>
      'Con /v1 alla fine. Ollama: http://localhost:11434/v1, LM Studio: http://localhost:1234/v1.';

  @override
  String get moBrainWhyText =>
      'Se paghi già Claude o ChatGPT, comincia da lì: non spendi altro. Con una chiave paghi quello che usi e puoi scegliere fra tanti fornitori. Un modello su questo computer non costa niente e tiene tutto privato, ma è più lento e meno bravo dei grandi modelli online. Puoi anche combinarli: per esempio un abbonamento per i lavori difficili e un modello locale per quelli piccoli.';

  @override
  String get moCatalogBuiltin => 'quello incluso in Rasgeth';

  @override
  String moCatalogChecked(String when) {
    return 'controllato $when';
  }

  @override
  String get moCatalogDownloaded => 'scaricato e firmato';

  @override
  String get moCatalogRefresh => 'Aggiorna ora';

  @override
  String get moCatalogRefreshing => 'Aggiorno…';

  @override
  String moCatalogRow(String date) {
    return 'Catalogo dei modelli: aggiornato il $date';
  }

  @override
  String get moCatalogUnreachable => 'GitHub non ha risposto: resta il catalogo in uso.';

  @override
  String get moCatalogUnsigned =>
      'Il catalogo scaricato non ha una firma valida: non è stato usato.';

  @override
  String moCatalogVersion(String n) {
    return 'versione $n';
  }

  @override
  String get moChat => 'Chat';

  @override
  String get moDownloaded => 'scaricato';

  @override
  String get moDownloads => 'download';

  @override
  String get moEffort => 'Effort';

  @override
  String get moEffortHint =>
      'Sforzo di ragionamento: più alto pensa di più, è più lento e costa di più. Dal prossimo messaggio.';

  @override
  String get moEffort_high => 'Alto';

  @override
  String get moEffort_low => 'Basso';

  @override
  String get moEffort_max => 'Massimo';

  @override
  String get moEffort_medium => 'Medio';

  @override
  String get moError => 'Errore';

  @override
  String get moFailed => 'fallito';

  @override
  String get moJob_step_model_download => 'Il modello';

  @override
  String get moLmBeyondMemory =>
      'più grande di RAM e scheda insieme: una parte si legge dall\'SSD a ogni token, più lento';

  @override
  String get moLmBigChunks => 'Blocchi grandi';

  @override
  String get moLmBigChunksHelp =>
      'Legge i messaggi lunghi a blocchi da 8.192 o 16.384 token invece che da 4.096, quando la scheda video ha posto, e carica il modello nella RAM quando ci sta con margine: gli esperti passano nella scheda una volta a blocco, quindi meno blocchi leggono più in fretta. Al primo avvio li misura su un messaggio lungo (qualche minuto in più) e tiene il più veloce. Solo per i modelli a esperti.';

  @override
  String moLmCardDownloading(String pct) {
    return 'in download, $pct%';
  }

  @override
  String moLmCardGet(String size) {
    return 'da scaricare, $size';
  }

  @override
  String get moLmCardOff => 'scelto, spento';

  @override
  String get moLmCardPaused => 'download in pausa';

  @override
  String get moLmCardReady => 'scaricato';

  @override
  String get moLmCardTooBig => 'troppo grande per questo computer';

  @override
  String get moLmContextTokens => 'token di contesto';

  @override
  String get moLmDelete => 'Elimina';

  @override
  String get moLmDeleteActiveConfirm =>
      'Questo modello è in uso: il motore si ferma e il file viene eliminato. Vado avanti?';

  @override
  String get moLmDiscard => 'Butta via il download';

  @override
  String moLmDownload(String size) {
    return 'Scarica · $size';
  }

  @override
  String get moLmDownloadedBusy => 'in download';

  @override
  String moLmDownloadedConfirm(String name, String size) {
    return 'Eliminare $name? Libera $size.';
  }

  @override
  String moLmDownloadedConfirmActive(String name, String size) {
    return '$name è il modello in uso: il motore si ferma e il file viene cancellato ($size). Procedo?';
  }

  @override
  String get moLmDownloadedEmpty => 'Nessun modello scaricato.';

  @override
  String moLmDownloadedHelp(String size) {
    return 'Tutti i file di modello nella cartella ($size in tutto), dal più grande. Eliminarne uno libera subito il suo spazio; quelli suggeriti si possono riscaricare.';
  }

  @override
  String moLmDownloadedNote(String n, String size) {
    return '$n sul disco · $size';
  }

  @override
  String get moLmDownloadedPartial => 'incompleto';

  @override
  String get moLmDownloadedTitle => 'Modelli scaricati';

  @override
  String get moLmEngine => 'Motore';

  @override
  String get moLmEngineHelp =>
      'Rasgeth sceglie quello adatto a questo computer. Cambialo solo se l\'avvio non riesce.';

  @override
  String get moLmEngine_cpu => 'Processore';

  @override
  String get moLmEngine_cuda => 'Scheda video NVIDIA (CUDA)';

  @override
  String get moLmEngine_mac => 'Il chip grafico del Mac (Metal), accanto a Rasgeth';

  @override
  String get moLmEngine_vulkan => 'Scheda AMD, Intel o integrata (Vulkan)';

  @override
  String get moLmEngine_windows => 'Scheda video, con il motore di Windows (Vulkan)';

  @override
  String get moLmExperimental => 'sperimentale';

  @override
  String get moLmFactCache => 'Cache degli esperti nella scheda';

  @override
  String get moLmFactRam => 'RAM libera contata';

  @override
  String get moLmFactSsd => 'Dall\'SSD a ogni token';

  @override
  String moLmFactSsdGb(String gb) {
    return 'circa $gb GB';
  }

  @override
  String get moLmFactSsdNone => 'niente: sta in RAM';

  @override
  String moLmGbPerSec(String n) {
    return '$n GB/s';
  }

  @override
  String moLmHwCpu(String max) {
    return 'Nessuna scheda video da usare: i modelli girano sul processore, più lenti; piccoli, fino a circa $max GB.';
  }

  @override
  String moLmHwGpu(String max, String name, String vram) {
    return '$name con $vram GB di memoria video: ci girano veloci modelli fino a circa $max GB.';
  }

  @override
  String get moLmHwGpuUnknown =>
      'C\'è una scheda video NVIDIA, ma non si sa quanta memoria ha: comincia da un modello piccolo.';

  @override
  String moLmHwIgpu(String max) {
    return 'Una scheda video integrata nel processore: un po\' più veloce del solo processore; modelli fino a circa $max GB.';
  }

  @override
  String moLmHwUnreachable(String max) {
    return 'Qui il motore non riesce a raggiungere la scheda video: i modelli girano sul processore, più lenti; fino a circa $max GB.';
  }

  @override
  String get moLmInUse => 'in uso';

  @override
  String get moLmLoading => 'Cerco i modelli…';

  @override
  String get moLmMoePrefetch => 'Strato dopo in anticipo';

  @override
  String get moLmOff => 'Spento';

  @override
  String get moLmOn => 'Acceso';

  @override
  String get moLmOther => 'Altri modelli nella cartella';

  @override
  String moLmOtherHelp(String size) {
    return 'Un file di modello nella cartella, fuori dai suggeriti ($size).';
  }

  @override
  String moLmPartRamSub(String free) {
    return '$free liberi adesso';
  }

  @override
  String get moLmPartSsd => 'SSD dei modelli';

  @override
  String moLmPartSsdSub(String free) {
    return '$free liberi';
  }

  @override
  String get moLmPause => 'Pausa';

  @override
  String moLmPaused(String done, String total) {
    return 'In pausa: $done di $total';
  }

  @override
  String moLmPausedAt(String done) {
    return 'In pausa a $done';
  }

  @override
  String get moLmPreloadSpeed => 'Modello letto dal disco';

  @override
  String get moLmRecommended => 'consigliato';

  @override
  String get moLmResume => 'Riprendi';

  @override
  String get moLmRoom => 'Spazio';

  @override
  String get moLmScoresHint =>
      'Le barre confrontano questi modelli tra loro (cinque è il migliore di loro). La velocità è una stima per questo computer.';

  @override
  String get moLmSearch => 'Altri modelli da Hugging Face';

  @override
  String get moLmSearchHint =>
      'Cerca per nome, scegli un repository e un file. I file che non sono modelli sono nascosti.';

  @override
  String get moLmSearchPlaceholder => 'per esempio gemma, qwen, mistral';

  @override
  String get moLmShowActivation => 'Mostra l\'attivazione';

  @override
  String get moLmSpecDraft => 'Con un modello piccolo della famiglia';

  @override
  String moLmSpecDraftGet(String size) {
    return 'Scarica il modello piccolo · $size';
  }

  @override
  String moLmSpecDraftHelp(String name, String size) {
    return '$name ($size) propone fino a 8 token; sta tutto nella scheda con il suo contesto, quindi al modello grande resta un po\' meno posto lì. Funziona solo con un modello della stessa famiglia (stesso vocabolario): lo sceglie Rasgeth.';
  }

  @override
  String get moLmSpecDraftReady => 'modello piccolo pronto';

  @override
  String get moLmSpecHelp =>
      'Scrive più in fretta senza cambiare le risposte: qualcosa di economico propone i token successivi e il modello li controlla tutti in un passaggio, leggendo i suoi pesi una volta per più token. Aiuta soprattutto dove il testo è prevedibile (codice da riscrivere, grandi modelli densi fuori dalla scheda); su testo nuovo guadagna poco. Misurato su una RTX 4080 Super: Llama 3.3 70B (quasi tutto in RAM) da 1,1 a 2,6 token/s su testo nuovo e a 7,4 sul codice riscritto; Qwen3 14B (nella scheda) da 59 a 155 sul codice, quasi pari sul testo. La velocità è sotto ogni risposta.';

  @override
  String get moLmSpecNgram => 'Dal testo già scritto';

  @override
  String get moLmSpecNgramHelp =>
      'Le proposte vengono da pezzi della conversazione che si ripetono (codice che si modifica, documenti citati): nessun secondo modello, nessuna memoria in più. Aiuta solo lì: su testo nuovo niente, e su un grande modello denso poco anche sul codice (misurato: Llama 3.3 70B da 1,1 a 1,3). Se la famiglia ha un modello piccolo, meglio quello.';

  @override
  String get moLmSpecNone => 'Spenta';

  @override
  String get moLmSpecTitle => 'Decodifica speculativa (per esperti)';

  @override
  String get moLmSpeedEstimate => 'token/s, stima';

  @override
  String get moLmSpeedMeasured => 'token/s, misurati';

  @override
  String get moLmSpeedTest => 'Misura il guadagno';

  @override
  String get moLmSpeedTestCode => 'Codice riscritto (token/s)';

  @override
  String get moLmSpeedTestCost =>
      'Richiede un bel po\' di tempo e di calcolo: il modello viene caricato più volte, minuti per uno grande. Nel frattempo il modello locale non risponde agli agenti.';

  @override
  String get moLmSpeedTestDone =>
      'Il motore è tornato com\'era. Scegli il modo qui sopra e riavvia il modello per usarlo.';

  @override
  String get moLmSpeedTestIntro =>
      'Rasgeth avvia questo modello una volta per ogni modo di scrivere (da solo, con il modello piccolo, con gli n-gram), gli fa scrivere un breve testo nuovo e riscrivere un pezzo di codice, e mostra i token al secondo di ciascuno. Alla fine il motore torna com\'era.';

  @override
  String get moLmSpeedTestMode => 'Modo';

  @override
  String get moLmSpeedTestProse => 'Testo nuovo (token/s)';

  @override
  String get moLmSpeedTestStart => 'Avvia il test';

  @override
  String get moLmSpeedTestTitle => 'Quanto va più veloce qui';

  @override
  String get moLmStart => 'Avvia';

  @override
  String get moLmStarting => 'Comincio…';

  @override
  String get moLmStream => 'SSD stream';

  @override
  String moLmStreamCache(String gb) {
    return ', $gb della scheda per gli esperti';
  }

  @override
  String get moLmStreamFromCard => 'il modello sta nella scheda';

  @override
  String get moLmStreamFromRam => 'il modello sta in RAM: l\'SSD si legge solo all\'avvio';

  @override
  String moLmStreamFromSsd(String gb) {
    return 'circa $gb GB letti dall\'SSD a ogni token';
  }

  @override
  String moLmStreamHdd(String disk) {
    return 'Non disponibile: $disk è un disco meccanico, troppo lento per leggerci un modello a ogni token.';
  }

  @override
  String moLmStreamMaybeSsd(String disk) {
    return 'Windows non dice se $disk è un SSD: usalo solo se lo è.';
  }

  @override
  String moLmStreamNoRoom(String disk, String free) {
    return 'Non disponibile: $disk ha solo $free liberi; ne servono almeno 20 GB.';
  }

  @override
  String moLmStreamPlan(String cache, String ctx, String ram, String source) {
    return 'In uso: contesto fino a $ctx token$cache, $source (contando $ram di RAM libera).';
  }

  @override
  String get moLmStreamThisDisk => 'il disco dei modelli';

  @override
  String get moLmStreamUnknownDisk =>
      'Rasgeth non sa ancora su che disco stanno i modelli (lo saprà al prossimo avvio di Rasgeth): usalo solo se è un SSD.';

  @override
  String get moLmSysmemClose => 'Ho capito';

  @override
  String get moLmSysmemStep1 => 'Apri il Pannello di controllo NVIDIA (clic destro sul desktop).';

  @override
  String get moLmSysmemStep2 =>
      'Gestisci impostazioni 3D, poi Impostazioni globali (oppure Impostazioni programma con llama-server.exe, solo per il motore).';

  @override
  String get moLmSysmemStep3 =>
      'CUDA - Sysmem Fallback Policy: scegli «Prefer No Sysmem Fallback» e Applica.';

  @override
  String get moLmSysmemStep4 =>
      'Riattiva il modello: il motore legge l\'impostazione quando parte.';

  @override
  String get moLmSysmemText =>
      'Quando la memoria della scheda finisce, il driver NVIDIA su Windows usa la RAM del computer invece di dare errore: la lettura dei messaggi diventa da 2 a 3,5 volte più lenta. Rasgeth non può leggere questa impostazione, quindi controllala una volta:';

  @override
  String get moLmSysmemTitle => 'Scheda NVIDIA: spegni «CUDA Sysmem Fallback»';

  @override
  String get moLmThisPc => 'Questo computer';

  @override
  String moLmTokensPerSec(String n) {
    return '$n token/s';
  }

  @override
  String get moLmTokensUnit => 'token/s';

  @override
  String moLmTooBig(String max, String need) {
    return 'Serve almeno $need: su questo computer ci sta fino a $max.';
  }

  @override
  String moLmTuneBatch(String n) {
    return 'blocchi da $n token';
  }

  @override
  String get moLmTuneCache => 'Scheda per gli esperti';

  @override
  String get moLmTuneChosen => 'scelta';

  @override
  String get moLmTuneCtx => 'Contesto';

  @override
  String get moLmTuneFailed => 'non è partito';

  @override
  String get moLmTuneHelp =>
      'Ogni riga è una prova vera: il modello legge un contesto di circa 2.000 token e ne scrive 64. Il turno tipico è un agente che legge 1.500 token di risultati e ne scrive 300: resta la riga più veloce, per questo modello, e puoi sceglierne un\'altra.';

  @override
  String moLmTuneLongRead(String n) {
    return 'un messaggio da $n token';
  }

  @override
  String get moLmTuneNoCopy => 'esperti calcolati sul processore nella lettura';

  @override
  String get moLmTuneRead => 'Lettura (tok/s)';

  @override
  String get moLmTuneRunning => 'misuro…';

  @override
  String get moLmTuneTitle => 'Regolazione su questo computer';

  @override
  String get moLmTuneTurn => 'Turno tipico (s)';

  @override
  String get moLmTuneUse => 'Usa';

  @override
  String get moLmTuneWrite => 'Scrittura (tok/s)';

  @override
  String get moLmUnavailable => 'Hugging Face non risponde: riprova più tardi.';

  @override
  String get moLmUseForAgents => 'Usalo per gli agenti';

  @override
  String get moLmUsedForAgents => 'Gli agenti useranno questo modello.';

  @override
  String get moLmVersionSuggested => 'consigliata';

  @override
  String get moLmVersions => 'Versione del file';

  @override
  String get moLmWarmHelp =>
      'Il modello legge il suo primo contesto e scrive qualche parola. La prima volta su una scheda video nuova ci vogliono minuti: la scheda prepara i suoi programmi una volta sola, poi è veloce.';

  @override
  String get moLmWarmSpeed => 'Contesto letto (come un primo messaggio)';

  @override
  String get moLmWhere => 'Dove va il modello';

  @override
  String get moLoading => 'Carico…';

  @override
  String get moModelHint =>
      'Il modello di questa conversazione (modelli degli agenti: Impostazioni, Agenti)';

  @override
  String get moModelNew => 'nuovo';

  @override
  String get moModelPick => 'Scegli un modello';

  @override
  String get moModelSearch => 'Cerca un modello';

  @override
  String get moModelUnconfirmed => 'dati da confermare';

  @override
  String get moModelWay => 'Da dove passa';

  @override
  String get moMpChange => 'Cambia';

  @override
  String get moMpLead =>
      'Scegline uno o più: li combini come vuoi. Ogni riquadro apre la sua finestra; quelli accesi sono collegati.';

  @override
  String get moMpLocalLead =>
      'Gratis, e niente esce da qui: il computer, dove stanno i modelli, quelli da scaricare e quelli già sul disco.';

  @override
  String get moMpNoDefault => 'Nessun modello scelto';

  @override
  String get moMpNoDefaultText => 'Collega un modo qui sopra, poi scegli quale usano gli agenti.';

  @override
  String get moMpSearchLead =>
      'Come gli agenti cercano su internet. Un fornitore alla volta: quello acceso è in uso.';

  @override
  String get moMpSearchTitle => 'Ricerca sul web';

  @override
  String get moSearch => 'Cerca';

  @override
  String get moSearchInUse => 'in uso';

  @override
  String get moSubsDeviceWait => 'Questa pagina se ne accorge da sola quando hai finito.';

  @override
  String moSubsLoggedAs(String plan, String who) {
    return 'Collegato: $who $plan';
  }

  @override
  String moSubsProgramDownload(String name) {
    return '$name viene scaricato quando lo attivi (una volta sola, qualche centinaio di MB, con la barra nell\'angolo).';
  }

  @override
  String moSubsProgramSystem(String name) {
    return '$name è già installato su questo computer: Rasgeth usa quello.';
  }

  @override
  String moSubsSharedLogin(String name) {
    return '$name è già collegato su questo computer: Rasgeth usa quell\'accesso così com\'è, senza rifarlo.';
  }

  @override
  String get moSubsUseShared => 'Usa l\'accesso già presente';

  @override
  String get moSubscriptions => 'Modelli e abbonamenti';

  @override
  String moTermsOf(String name) {
    return 'Termini di $name';
  }

  @override
  String moUiAboutHours(String h, String min) {
    return 'mancano circa $h h $min min';
  }

  @override
  String moUiAboutMinutes(String min) {
    return 'mancano circa $min min';
  }

  @override
  String get moUiDropNone => 'Nessun risultato.';

  @override
  String get moUiLessThanMinute => 'manca meno di un minuto';

  @override
  String get moUiNotNeeded => 'non serve';

  @override
  String moUiOf(String done, String total) {
    return '$done di $total';
  }

  @override
  String get moViaLocal => 'locale';

  @override
  String get moViaSubscription => 'abbonamento';

  @override
  String get moWzAgents => 'Agenti';

  @override
  String get moWzAgentsSub => 'fanno il lavoro';

  @override
  String get moWzAgentsText =>
      'Ricevono i compiti dagli orchestratori: scrivono codice, provano, cercano.';

  @override
  String get moWzAlreadySet => 'già impostata';

  @override
  String get moWzAssign => 'Chi usa quale modello';

  @override
  String get moWzAssignChat =>
      'La chat di tutti i giorni, con la ricerca sul web: domande, testi, idee.';

  @override
  String get moWzAssignConnect => 'Collega un modello';

  @override
  String get moWzAssignDemigod2 =>
      'Ti risponde su Telegram e nelle chat, e passa il lavoro: basta un modello veloce.';

  @override
  String get moWzAssignEmpty =>
      'Non hai ancora collegato nessun modello, quindi qui non c\'è niente da scegliere. Collegane uno al passo «Come deve pensare Rasgeth?» o avvia un modello locale.';

  @override
  String get moWzAssignGod =>
      'Quello che guida tutto: piani, progetti, altri agenti. Qui conviene il modello più forte.';

  @override
  String get moWzAssignLead =>
      'Ognuno lavora con il suo modello: il più forte per chi decide, uno veloce per chi risponde. Tocca un modello per cambiarlo.';

  @override
  String get moWzAssignLocal => 'Scegli un modello locale';

  @override
  String get moWzAssignOthers => 'Gli agenti che crei dopo';

  @override
  String get moWzAssignOthersHelp =>
      'E i riassunti della bacheca, se non ne scegli uno apposta per loro. Prima di salvarlo viene provato con una domanda vera.';

  @override
  String get moWzAssistants => 'Assistenti personali';

  @override
  String get moWzAssistantsSub => 'lavorano per te';

  @override
  String get moWzBackupText =>
      'Se un agente rinuncia a un task (un errore, il budget, nessuna verifica superata), questo modello lo riprova una volta, sapendo cosa ha fatto il primo. Meglio se è di un altro fornitore.';

  @override
  String get moWzBackupWindow =>
      'Riprova una volta i task abbandonati, in una conversazione nuova.';

  @override
  String get moWzBrain => 'Come deve pensare Rasgeth?';

  @override
  String get moWzBrainChatgpt =>
      'Il tuo piano ChatGPT Plus o Pro. Scrivi un codice breve sulla pagina di OpenAI.';

  @override
  String get moWzBrainClaude => 'Il tuo piano Claude Pro o Max. Accedi sulla pagina di Anthropic.';

  @override
  String get moWzBrainKeys =>
      'Anthropic, OpenAI, Gemini, Mistral, DeepSeek, Grok e altri. Paghi quello che usi.';

  @override
  String get moWzBrainKeysTitle => 'Una chiave API';

  @override
  String get moWzBrainLocal => 'Gratis e privato: niente esce da qui. Lo scegli al passo dopo.';

  @override
  String get moWzBrainQ => 'Come deve pensare Rasgeth?';

  @override
  String get moWzBrainServer =>
      'Ollama, LM Studio, vLLM o un altro server che parla la lingua di OpenAI.';

  @override
  String get moWzChosen => 'scelto';

  @override
  String get moWzDefaultModel => 'Modello predefinito';

  @override
  String get moWzDemiRole => 'Il portavoce';

  @override
  String moWzDense(String b) {
    return '$b miliardi · denso';
  }

  @override
  String get moWzDiskHdd => 'Disco meccanico: troppo lento per i modelli.';

  @override
  String get moWzDisksLead =>
      'Un modello occupa da 3 a 80 GB. Meglio un SSD veloce: Deep Field legge da lì.';

  @override
  String get moWzDisksNoMove =>
      'I modelli si spostano su un altro disco solo nell\'installazione di Rasgeth per Windows.';

  @override
  String get moWzDisksOne =>
      'Qui i modelli stanno nella cartella dei dati di Rasgeth. Nell\'installazione di Rasgeth per Windows puoi spostarli su un altro SSD.';

  @override
  String get moWzDisksTitle => 'Dove stanno i modelli';

  @override
  String get moWzDoneBtn => 'Fatto';

  @override
  String get moWzEffortHelp =>
      'Poco è veloce ed economico, a fondo è più lento ma più accurato. Resta fisso per ogni conversazione.';

  @override
  String get moWzEffortTitle => 'Quanto ragiona prima di rispondere';

  @override
  String get moWzEffort_high => 'A fondo';

  @override
  String get moWzEffort_low => 'Poco';

  @override
  String get moWzEffort_max => 'Al massimo';

  @override
  String get moWzEffort_medium => 'Il giusto';

  @override
  String get moWzFitNone => 'Nessuno gira abbastanza veloce qui: quelli sotto funzionano, piano.';

  @override
  String get moWzFitTab => 'Adatti';

  @override
  String get moWzFitTitle => 'Adatti a questo computer';

  @override
  String moWzFitsUpTo(String max) {
    return 'Ci girano veloci modelli fino a circa $max; quelli più grandi usano anche la RAM.';
  }

  @override
  String get moWzFolder => 'Cartella';

  @override
  String get moWzFolderHelp => 'Una cartella di questo disco; se non c\'è, viene creata.';

  @override
  String get moWzFolderLead =>
      'Dove Rasgeth salva i file dei modelli su questo disco. Quelli già scaricati vengono copiati lì.';

  @override
  String moWzFolderTitle(String disk) {
    return 'Cartella dei modelli su $disk';
  }

  @override
  String get moWzFree => 'liberi';

  @override
  String moWzFreeOf(String total) {
    return 'liberi di $total GB';
  }

  @override
  String get moWzGodRole => 'Il capo';

  @override
  String get moWzHereNow => 'qui ora';

  @override
  String get moWzHowItWorks => 'Come funziona';

  @override
  String moWzKeyOf(String name) {
    return 'La chiave di $name';
  }

  @override
  String get moWzKeysLead =>
      'Una chiave è come una password che lascia usare a Rasgeth i modelli del fornitore sul tuo account. Paghi il fornitore per quello che usi. Aggiungine quante vuoi: ognuna viene provata subito.';

  @override
  String moWzLegend(String n) {
    return 'Contorno verde: gira su questo computer tra scheda video e RAM, ad almeno $n token al secondo. Gli altri funzionano, ma piano.';
  }

  @override
  String moWzLikeAbove(String who) {
    return 'Lo stesso di $who';
  }

  @override
  String get moWzLocal => 'Modello locale';

  @override
  String get moWzLocalQ => 'Un modello su questo computer';

  @override
  String get moWzLocked => 'impostato dall\'ambiente';

  @override
  String moWzMoe(String b) {
    return '$b miliardi · a esperti';
  }

  @override
  String get moWzMoreModels => 'Altri file e ricerche';

  @override
  String get moWzMoveHere => 'Sposta qui';

  @override
  String moWzMoveLead(String folder, String free, String kind) {
    return '$kind, $free liberi. I modelli già scaricati vengono copiati in $folder; il modello in uso poi riparte.';
  }

  @override
  String moWzMoveTitle(String disk) {
    return 'Spostare i modelli su $disk?';
  }

  @override
  String moWzNModels(String n) {
    return '$n modelli';
  }

  @override
  String get moWzNone => 'Nessuno';

  @override
  String get moWzOfRamLong => 'di RAM';

  @override
  String get moWzOrchestrators => 'Orchestratori';

  @override
  String get moWzOrchestratorsSub => 'i capi dei progetti';

  @override
  String get moWzOrchestratorsText => 'Uno per progetto: divide il lavoro e lo passa agli agenti.';

  @override
  String get moWzPickFolder => 'Scegli cartella';

  @override
  String get moWzPickModel => 'Scegli il modello';

  @override
  String get moWzPickRepo => 'Scegli un repository';

  @override
  String get moWzProvider => 'Fornitore';

  @override
  String get moWzRemove => 'Togli';

  @override
  String get moWzSlowTab => 'Vanno piano';

  @override
  String get moWzSlowTitle => 'Funzionano, ma piano';

  @override
  String moWzStateKey(String name) {
    return '$name: collegata';
  }

  @override
  String moWzStateKeys(String n) {
    return '$n chiavi collegate';
  }

  @override
  String get moWzStateLinked => 'collegato';

  @override
  String moWzStateLocal(String model) {
    return '$model, in uso';
  }

  @override
  String get moWzStateLocalNext => 'lo scegli al passo dopo';

  @override
  String moWzStateServer(String url) {
    return 'collegato: $url';
  }

  @override
  String get moWzStreamInfo1 =>
      'Per modelli più grandi della scheda video, e per un contesto molto più lungo.';

  @override
  String get moWzStreamInfo2 =>
      'Le parti del modello usate di più stanno nella scheda e in RAM; il resto si legge dall\'SSD quando serve. Rende al meglio con i modelli a esperti; quelli densi funzionano, ma più lenti.';

  @override
  String get moWzStreamInfo3 =>
      'Al primo avvio Rasgeth misura questo computer e tiene la regolazione più veloce. Serve un SSD con almeno 20 GB liberi: un disco meccanico è troppo lento.';

  @override
  String get moWzStreamOff => 'Spento: girano solo i modelli che stanno nella scheda e nella RAM.';

  @override
  String moWzStreamOn(String disk) {
    return 'Acceso: i modelli più grandi della scheda e della RAM leggono il resto dall\'SSD ($disk) quando serve. Più lenti, ma girano.';
  }

  @override
  String get moWzSubscription =>
      'So che usare un abbonamento personale (al posto di una chiave API) in uno strumento di terzi può non essere permesso dalle condizioni del fornitore.';

  @override
  String get moWzTrying => 'Provo il modello…';

  @override
  String get moWzUnderstood => 'Ho capito';

  @override
  String get moWzUseFolder => 'Usa questa cartella';

  @override
  String moWzVram(String gb) {
    return '$gb di memoria video';
  }

  @override
  String get moWzWhich => 'Quale scelgo?';

  @override
  String get chUiAdvanced => 'Avanzate';

  @override
  String moJob_engine(String model) {
    return 'Avvio di $model';
  }

  @override
  String moJob_engine_load(String model) {
    return 'Carico $model';
  }

  @override
  String get moJob_error_bad_file => 'Questo non è un file di modello di Hugging Face.';

  @override
  String get moJob_error_checksum =>
      'Il download è arrivato rovinato (l\'impronta non coincide): riprova.';

  @override
  String get moJob_error_engine_stopped =>
      'Il motore si è fermato da solo. I dettagli qui sotto dicono perché.';

  @override
  String get moJob_error_incomplete =>
      'Il download si è fermato prima della fine: premi Riprendi per continuare da dove era.';

  @override
  String get moJob_error_load_timeout =>
      'Il modello non si è caricato in 15 minuti. Prova con uno più piccolo.';

  @override
  String get moJob_error_model_missing =>
      'Il file del modello non è più nella cartella. Scaricalo di nuovo.';

  @override
  String get moJob_error_no_gpu =>
      'Il motore non vede la scheda video. Aggiorna i driver della scheda e riavvia il computer, oppure scegli il processore in Avanzate.';

  @override
  String get moJob_error_out_of_memory =>
      'Non c\'è abbastanza memoria per questo modello. Scegline uno più piccolo, o lo stesso con una qualità più bassa.';

  @override
  String moJob_model_download(String model) {
    return 'Download di $model';
  }

  @override
  String moJob_speed_test(String model) {
    return 'Misuro $model';
  }

  @override
  String get moJob_step_draft => 'Con il modello piccolo';

  @override
  String get moJob_step_image => 'Scarico il motore (una volta sola)';

  @override
  String get moJob_step_load => 'Carico il modello in memoria';

  @override
  String get moJob_step_ngram => 'Con gli n-gram';

  @override
  String get moJob_step_none => 'Il modello da solo';

  @override
  String get moJob_step_preload =>
      'Leggo il modello una volta, così il primo messaggio non aspetta il disco';

  @override
  String get moJob_step_start => 'Avvio il motore';

  @override
  String get moJob_step_try => 'Provo una risposta';

  @override
  String get moJob_step_tune => 'Misuro questo computer per scegliere la regolazione più veloce';

  @override
  String get moLmQuality_good => 'qualità buona';

  @override
  String get moLmQuality_high => 'qualità alta';

  @override
  String get moLmQuality_reduced => 'qualità ridotta, per starci';

  @override
  String get moLmScore_code => 'Programmazione';

  @override
  String get moLmScore_languages => 'Altre lingue';

  @override
  String get moLmScore_smart => 'Intelligenza';

  @override
  String get moLmScore_speed => 'Velocità qui';

  @override
  String get moLmScore_tools => 'Strumenti';

  @override
  String get moLmSpeedMode_draft => 'Con il modello piccolo';

  @override
  String get moLmSpeedMode_ngram => 'N-gram';

  @override
  String get moLmSpeedMode_none => 'Modello da solo';

  @override
  String get chHubTelegram =>
      'Demi-God su Telegram: il bot, il suo token e gli account che gli scrivono';

  @override
  String get chHubChats => 'Demi-God su Discord, Slack, Signal, WhatsApp, Matrix, Teams e iMessage';

  @override
  String get moHubModels =>
      'Abbonamenti, chiavi API, il tuo server, il modello su questo computer e chi usa quale';

  @override
  String get xtAddServer => 'Aggiungi server';

  @override
  String get xtApprove => 'Approva';

  @override
  String get xtArgs => 'Argomenti';

  @override
  String get xtAxMagicDismiss => 'Metti da parte';

  @override
  String get xtAxMagicExamples => 'Oppure parti da un esempio';

  @override
  String get xtAxMagicGo => 'Chiedi a God';

  @override
  String get xtAxMagicReject => 'Così no';

  @override
  String get xtAxMagicSendNo => 'Manda a God';

  @override
  String get xtAxMagicStarting => 'Chiamo God…';

  @override
  String get xtAxMagicWhy => 'Cosa non va? God lo legge e riprova';

  @override
  String get xtAxNeedMissing => 'Manca';

  @override
  String get xtAxNeedReady => 'Pronto';

  @override
  String get xtAxNeedVault => 'Aggiungi al portachiavi';

  @override
  String get xtBy => 'da';

  @override
  String get xtCancel => 'Annulla';

  @override
  String get xtCommand => 'Comando';

  @override
  String get xtCopied => 'Copiato';

  @override
  String get xtCopy => 'Copia';

  @override
  String get xtCreate => 'Crea';

  @override
  String get xtDescription => 'Descrizione';

  @override
  String get xtExtAdd => 'Aggiungi';

  @override
  String get xtExtAddAndConnect => 'Aggiungi e collega';

  @override
  String get xtExtAdded => 'Aggiunto';

  @override
  String xtExtAppConsole(String name) {
    return 'Apri la pagina per sviluppatori di $name';
  }

  @override
  String xtExtAppGuide(String name) {
    return 'Crea la tua app su $name (una volta, una decina di minuti)';
  }

  @override
  String get xtExtAskHelp =>
      'Chiedilo a God con un\'integrazione o un\'estensione magica, con parole tue: cerca un servizio pronto nel catalogo, oppure scrive una capacità nuova, la prova e ti chiede il permesso prima di installare qualsiasi cosa.';

  @override
  String get xtExtAskTitle => 'Cosa vuoi che i tuoi agenti sappiano fare?';

  @override
  String get xtExtAuth_app => 'La tua app, con una guida';

  @override
  String get xtExtAuth_header => 'Serve una chiave';

  @override
  String get xtExtAuth_none => 'Nessun accesso da fare';

  @override
  String get xtExtAuth_oauth => 'Accedi sulla sua pagina';

  @override
  String get xtExtBroken => 'Non funziona';

  @override
  String get xtExtBrokenHelp =>
      'Un servizio non funziona: controlla la chiave, oppure toglilo e aggiungilo di nuovo. Passa sopra l\'etichetta per vedere l\'errore.';

  @override
  String get xtExtCatAll => 'Tutti';

  @override
  String get xtExtCat_cloud => 'Cloud';

  @override
  String get xtExtCat_code => 'Codice';

  @override
  String get xtExtCat_data => 'Dati';

  @override
  String get xtExtCat_design => 'Grafica';

  @override
  String get xtExtCat_docs => 'Documentazione';

  @override
  String get xtExtCat_home => 'Casa';

  @override
  String get xtExtCat_web => 'Web';

  @override
  String get xtExtCat_work => 'Lavoro';

  @override
  String get xtExtCatalog => 'Servizi che puoi aggiungere';

  @override
  String get xtExtCatalogHelp =>
      'Ognuno dà ai tuoi agenti strumenti nuovi. Prima quelli fatti dai servizi stessi; quelli della comunità sono fatti da altri.';

  @override
  String get xtExtChecking => 'Controllo…';

  @override
  String get xtExtClientId => 'Client ID della tua app';

  @override
  String get xtExtClientSecret => 'Client secret della tua app';

  @override
  String get xtExtClientSecretOptional => 'Client secret della tua app (se ce l\'ha)';

  @override
  String get xtExtCommunity => 'Della comunità';

  @override
  String get xtExtConnect => 'Collega';

  @override
  String get xtExtConnected => 'I tuoi servizi';

  @override
  String get xtExtEverywhere => 'Ovunque';

  @override
  String xtExtGuide(String name) {
    return 'Come preparare $name';
  }

  @override
  String xtExtKey(String name) {
    return 'Chiave di $name';
  }

  @override
  String get xtExtKeyHelp =>
      'Resta in un file privato sul tuo server e non viene più mostrata, nemmeno agli agenti.';

  @override
  String xtExtKeyWhere(String name) {
    return 'Dove trovo la chiave di $name?';
  }

  @override
  String get xtExtKindSkill => 'Skill';

  @override
  String get xtExtKindTool => 'Strumento';

  @override
  String get xtExtManualOauth => 'Si accede sulla sua pagina (OAuth)';

  @override
  String get xtExtManualToken => 'Chiave (facoltativa, inviata come Bearer)';

  @override
  String get xtExtMore => 'Scopri di più';

  @override
  String get xtExtNeedsLogin => 'Devi accedere';

  @override
  String get xtExtNothingFound =>
      'Non ho trovato niente. Chiedi a God con l\'estensione magica qui sopra: può scrivere quello che manca.';

  @override
  String xtExtOauthHelp(String name) {
    return 'Si apre una nuova scheda sulla pagina di $name: accedi lì e autorizza Rasgeth. Poi torna qui.';
  }

  @override
  String get xtExtOfficial => 'Ufficiale';

  @override
  String xtExtOnlyProject(String name) {
    return 'Solo in $name';
  }

  @override
  String get xtExtProposals => 'Aspettano te';

  @override
  String get xtExtProposalsHelp =>
      'Capacità scritte dagli agenti e già provate: niente viene installato finché non approvi.';

  @override
  String get xtExtSearch => 'Cerca un servizio';

  @override
  String xtExtServerUrl(String name) {
    return 'Indirizzo di $name';
  }

  @override
  String get xtExtServerUrlHelp =>
      'Come lo raggiunge il server di Rasgeth, per esempio sulla rete di casa.';

  @override
  String get xtExtSkills => 'Skill e strumenti';

  @override
  String get xtExtSkillsHelp =>
      'Capacità installate per i tuoi agenti. Clicca per leggerle o cambiarle.';

  @override
  String get xtExtTransport => 'Come gira';

  @override
  String get xtExtTransportHttp => 'Online (indirizzo)';

  @override
  String get xtExtTransportStdio => 'Su questo server (comando)';

  @override
  String get xtExtUnverified =>
      'Non confermato sulle pagine del servizio: se qualcosa non torna, ha ragione la sua documentazione.';

  @override
  String get xtExtUnverifiedShort => 'da verificare';

  @override
  String get xtExtWhere => 'Dove funziona';

  @override
  String get xtExtWhereHelp => 'Ovunque, o solo per gli agenti di un progetto.';

  @override
  String xtExtWorks(String n) {
    return 'Funziona · $n strumenti';
  }

  @override
  String get xtExtensions => 'Estensioni';

  @override
  String get xtFailedTests => 'Prove fallite';

  @override
  String get xtInstructions => 'Istruzioni';

  @override
  String get xtMediaGetKey => 'Crea la chiave';

  @override
  String get xtMediaHasKey => 'chiave già presente';

  @override
  String xtMediaKey(String name) {
    return 'Chiave di $name';
  }

  @override
  String xtMediaKeyLinked(String name) {
    return 'Chiave di $name collegata';
  }

  @override
  String xtMediaKeyStep1(String name) {
    return 'Apri la pagina di $name dove si creano le chiavi ed entra (o crea un account).';
  }

  @override
  String get xtMediaKeyStep2 => 'Crea una chiave nuova e copiala.';

  @override
  String get xtMediaKeyStep3 => 'Incollala qui e salva:';

  @override
  String get xtMediaNativeHelp =>
      'Alcuni modelli fanno le immagini da sé (ChatGPT con Codex): allora si usa il loro, e l\'immagine ti arriva in chat come con il nostro. Spento: sempre il fornitore scelto qui. Se in una conversazione chiedi «il vostro strumento», si usa sempre il nostro. Vale per le conversazioni nuove.';

  @override
  String get xtMediaNativeTitle => 'Usa lo strumento del modello quando c\'è';

  @override
  String get xtMediaNeedsKey => 'Manca la chiave';

  @override
  String get xtMediaOff => 'Spento';

  @override
  String get xtMediaOtherProvider => 'Scegli un altro fornitore';

  @override
  String get xtMediaPurpose =>
      'Chi fa immagini, video, voci, musica ed effetti sonori quando un agente ne deve fare uno (gli strumenti image_generation, video_generation e audio_generation). Per ognuno scegli un fornitore e un modello e incolla la sua chiave: una chiave che hai già dato per la chat (OpenAI, Gemini, xAI) vale anche qui. Si pagano al fornitore per quello che fai.';

  @override
  String get xtMediaStep1 => '1. Chi lo fa';

  @override
  String xtMediaStep2(String name) {
    return '2. La chiave di $name';
  }

  @override
  String get xtMediaTitle => 'Estensioni predefinite';

  @override
  String get xtMediaTurnOff => 'Spegni';

  @override
  String get xtMediaVoice => 'Voce';

  @override
  String get xtMediaVoiceFirst => 'La prima dell\'account';

  @override
  String get xtMedia_image => 'Immagini';

  @override
  String get xtMedia_image_help =>
      'Disegni, foto, illustrazioni, loghi da una descrizione (o da un\'immagine).';

  @override
  String get xtMedia_music => 'Musica';

  @override
  String get xtMedia_music_help => 'Canzoni e brani da una descrizione, con o senza voce.';

  @override
  String get xtMedia_sound => 'Effetti sonori';

  @override
  String get xtMedia_sound_help =>
      'Suoni brevi da una descrizione: una porta, la pioggia, una folla, un motore.';

  @override
  String get xtMedia_speech => 'Voce';

  @override
  String get xtMedia_speech_help => 'Un testo letto ad alta voce, con la voce che scegli.';

  @override
  String get xtMedia_video => 'Video';

  @override
  String get xtMedia_video_help =>
      'Brevi clip da una descrizione o da un primo fotogramma. Ci mettono minuti e costano di più. (OpenAI ha chiuso Sora a settembre 2026.)';

  @override
  String get xtModel => 'Modello';

  @override
  String get xtMxApprove => 'Approva e installa';

  @override
  String get xtMxArgs => 'Argomenti:';

  @override
  String get xtMxBadgeApprove => 'Da installare';

  @override
  String get xtMxBadgeInstalled => 'Installata';

  @override
  String get xtMxBadgeMissing => 'Manca qualcosa';

  @override
  String get xtMxBuilding =>
      'God la sta costruendo con te: rispondi alle sue domande nella conversazione.';

  @override
  String get xtMxChange => 'Cambiala';

  @override
  String get xtMxChangeGo => 'Chiedi a God';

  @override
  String get xtMxChangeLabel =>
      'Cosa deve cambiare? God la propone di nuovo e tu la installi come prima.';

  @override
  String get xtMxChanging =>
      'God la sta cambiando con te; quella installata continua a funzionare finché non approvi la nuova.';

  @override
  String xtMxCheckHost(String what) {
    return 'L\'indirizzo $what';
  }

  @override
  String xtMxCheckKey(String what) {
    return 'La chiave per $what';
  }

  @override
  String xtMxCheckKeyUndeclared(String what) {
    return 'La chiave $what, usata dal codice ma non dichiarata';
  }

  @override
  String xtMxCheckTest(String what) {
    return 'Il test di $what';
  }

  @override
  String get xtMxCode => 'Leggi il codice';

  @override
  String get xtMxDone =>
      'Installata: ogni agente ha questi strumenti dalla sua prossima conversazione.';

  @override
  String get xtMxExtension => 'Estensione magica';

  @override
  String get xtMxExtensionAsk => 'Cosa devono saper fare gli agenti?';

  @override
  String get xtMxExtensionEx1 => 'Trasforma un CSV in un grafico e dimmi i totali';

  @override
  String get xtMxExtensionEx2 => 'Controlla che partita IVA e codice fiscale siano validi';

  @override
  String get xtMxExtensionEx3 =>
      'Una skill per scrivere il mio resoconto settimanale come piace a me';

  @override
  String get xtMxExtensionLead =>
      'Di\' a God cosa devono saper fare gli agenti. God chiede, scrive strumenti e skill con i loro test e li prova in una sandbox chiusa: tu vedi com\'è andata e li installi con un tasto.';

  @override
  String get xtMxExtensionPlaceholder =>
      'Per esempio: trasforma un CSV in un grafico e dimmi i totali';

  @override
  String get xtMxExtensionTile =>
      'Capacità nuove per gli agenti, di ogni tipo: God scrive strumenti e skill, li prova a parte e tu li installi.';

  @override
  String get xtMxGiveKey => 'Dalla a questi strumenti';

  @override
  String xtMxGiveKeyText(String hosts, String tools) {
    return 'La riceveranno solo questi strumenti, attraverso il proxy, e solo verso $hosts: $tools.';
  }

  @override
  String xtMxGiveKeyTitle(String what) {
    return 'Dare $what a questo pacchetto?';
  }

  @override
  String get xtMxIntegration => 'Integrazione magica';

  @override
  String get xtMxIntegrationAsk => 'Quale servizio, e per farci cosa?';

  @override
  String get xtMxIntegrationEx1 => 'Collegami a Notion: cerca nelle mie pagine e creane di nuove';

  @override
  String get xtMxIntegrationEx2 => 'Collegami alle API del mio gestionale (fatture e clienti)';

  @override
  String get xtMxIntegrationEx3 => 'Leggi i miei compiti di Todoist e segnali come fatti';

  @override
  String get xtMxIntegrationLead =>
      'Di\' a God quale servizio e cosa devono farci gli agenti. God chiede quello che gli serve, scrive il connettore con i suoi test e lo prova in una sandbox chiusa: tu vedi com\'è andata e lo installi con un tasto.';

  @override
  String get xtMxIntegrationPlaceholder =>
      'Per esempio: collegami a Notion così gli agenti cercano nelle mie pagine e aggiungono note';

  @override
  String get xtMxIntegrationTile =>
      'Collega Rasgeth a un servizio tramite le sue API (Notion, il tuo gestionale, una banca…): God scrive il connettore, lo prova a parte e tu lo installi.';

  @override
  String get xtMxKeyHosts => 'Può andare solo a:';

  @override
  String get xtMxKeyLead =>
      'Incolla qui la chiave: va dritta nel tuo Portachiavi, cifrata. Nessuno la legge, nemmeno God; gli strumenti la ricevono solo attraverso il proxy.';

  @override
  String get xtMxKeyName => 'Nome nel Portachiavi:';

  @override
  String get xtMxKeyOnly =>
      'La usano solo gli strumenti di questo pacchetto; puoi cambiarla in Impostazioni > Portachiavi.';

  @override
  String get xtMxKeySave => 'Salva nel Portachiavi';

  @override
  String xtMxKeyTitle(String service) {
    return 'Chiave per $service';
  }

  @override
  String get xtMxKeyValue => 'La chiave';

  @override
  String get xtMxKeys => 'Chiavi';

  @override
  String get xtMxListLead =>
      'Fatte con God: aprine una per continuare la conversazione, installarla, cambiarla o toglierla.';

  @override
  String get xtMxListTitle => 'Integrazioni ed estensioni magiche';

  @override
  String get xtMxMissing => 'Prima di installarla manca questo:';

  @override
  String get xtMxParts => 'Cosa aggiunge';

  @override
  String get xtMxPromise1 => 'Niente si installa senza il tuo sì.';

  @override
  String get xtMxPromise2 =>
      'Ogni parte si prova in una sandbox chiusa che raggiunge solo i servizi che dichiara.';

  @override
  String get xtMxPromise3 => 'Le chiavi vanno nel tuo Portachiavi dalla finestra, mai nella chat.';

  @override
  String get xtMxProposal => 'Il pacchetto di God';

  @override
  String get xtMxReaches => 'Raggiunge solo';

  @override
  String get xtMxReachesNothing => 'Niente: lavora senza rete.';

  @override
  String get xtMxRetest => 'Riprova i test';

  @override
  String get xtMxState_building => 'In costruzione';

  @override
  String get xtMxState_dismissed => 'Messa da parte';

  @override
  String get xtMxState_done => 'Installata';

  @override
  String get xtMxState_ready => 'Pronta: aspetta te';

  @override
  String get xtMxState_testing => 'Test in corso';

  @override
  String get xtMxStep1 => 'Dici cosa vuoi';

  @override
  String get xtMxStep2 => 'God lo scrive e lo prova';

  @override
  String get xtMxStep3 => 'Tu lo installi';

  @override
  String get xtMxTesting => 'I test girano di nuovo nella sandbox…';

  @override
  String get xtMxUninstall => 'Disinstalla';

  @override
  String xtMxUninstallText(String what) {
    return 'Se ne vanno: $what. Escono dal Portachiavi anche le chiavi aggiunte per lei.';
  }

  @override
  String xtMxUninstallTitle(String what) {
    return 'Disinstallare $what?';
  }

  @override
  String get xtMxWhyGod => 'Deve correggerlo God: diglielo nella conversazione se non lo fa.';

  @override
  String get xtMxWhyHost =>
      'Il codice lo raggiunge ma non lo dichiara: God deve dichiararlo o toglierlo.';

  @override
  String get xtMxWhyMissing =>
      'Non è ancora nel tuo Portachiavi: aggiungila qui, va solo a questi strumenti.';

  @override
  String get xtMxWhyNotGiven =>
      'È nel tuo Portachiavi, ma non è data a questi strumenti (o non verso questi indirizzi).';

  @override
  String get xtMxWhyTest =>
      'Non è passato nella sandbox: God legge il perché e lo corregge; aggiunta una chiave, i test ripartono.';

  @override
  String get xtName => 'Nome';

  @override
  String get xtNewSkill => 'Nuova skill';

  @override
  String get xtNoProposals => 'Nessuna proposta.';

  @override
  String get xtOpen => 'apri';

  @override
  String get xtProposals => 'Proposte che aspettano te';

  @override
  String get xtReject => 'Rifiuta';

  @override
  String get xtRemotePasswordChange => 'Cambiala';

  @override
  String get xtRemove => 'Rimuovi';

  @override
  String get xtSave => 'Salva';

  @override
  String get xtScope => 'Ambito';

  @override
  String get xtScopePlatform => 'piattaforma';

  @override
  String get xtSkillDownload => 'Scarica';

  @override
  String get xtSkillDownloadHelp => 'Scarica questa skill come .zip, per condividerla';

  @override
  String get xtSkillImport => 'Importa una skill';

  @override
  String get xtSkillImportFile => 'Scegli un file .zip';

  @override
  String get xtSkillImportHelp =>
      'La cartella di una skill come .zip (il formato agentskills.io), da un altro Rasgeth o da un altro strumento.';

  @override
  String get xtSkillImportWhere => 'Installa in';

  @override
  String xtSkillImported(String name) {
    return 'Skill «$name» importata.';
  }

  @override
  String get xtSkillReplaceConfirm => 'Lì c\'è già una skill con questo nome. La sostituisco?';

  @override
  String get xtSvApprovedAuto => 'installata da sola (la tua scelta in Sicurezza)';

  @override
  String get xtSvApprovedYou => 'approvata da te';

  @override
  String xtSvBy(String who) {
    return 'di $who';
  }

  @override
  String get xtSvCompare => 'Confronta con quella in uso';

  @override
  String get xtSvCompareFull => 'Confronta: tutte le differenze';

  @override
  String get xtSvCurrent => 'in uso';

  @override
  String get xtSvHideCompare => 'Nascondi il confronto';

  @override
  String get xtSvHow_baseline => 'Com\'era prima della cronologia';

  @override
  String get xtSvHow_edited => 'Cambiata a mano';

  @override
  String get xtSvHow_import => 'Importata';

  @override
  String get xtSvHow_install => 'Prima versione';

  @override
  String xtSvHow_rollback(String n) {
    return 'Ritorno alla versione $n';
  }

  @override
  String get xtSvHow_update => 'Nuova versione';

  @override
  String get xtSvLead =>
      'Ogni cambiamento di questa skill resta: chi l\'ha scritto, perché e quando. Gli agenti usano la più nuova dalla loro conversazione successiva.';

  @override
  String get xtSvLineTitle => 'Cosa è cambiato e perché';

  @override
  String get xtSvNextSession =>
      'Una volta installata, gli agenti la usano dalla loro conversazione successiva; quelli che stanno già parlando tengono la versione con cui hanno cominciato.';

  @override
  String get xtSvNone => 'Ancora nessuna versione.';

  @override
  String get xtSvNotRestorable => 'Troppo grande per essere conservata: non può tornare.';

  @override
  String xtSvRollback(String n) {
    return 'Torna alla versione $n';
  }

  @override
  String xtSvRollbackConfirm(String name) {
    return 'I suoi file prendono il posto di quelli di «$name» in uso, come versione nuova: non si perde niente e puoi tornare qui. Gli agenti la usano dalla loro conversazione successiva.';
  }

  @override
  String xtSvRollbackTitle(String n) {
    return 'Tornare alla versione $n?';
  }

  @override
  String xtSvRolledBack(String n, String v) {
    return 'Tornata alla versione $n: adesso è la versione $v.';
  }

  @override
  String get xtSvTitle => 'Versioni';

  @override
  String get xtSvUnknown => 'autore sconosciuto';

  @override
  String xtSvVersion(String n) {
    return 'Versione $n';
  }

  @override
  String get xtSvWhy => 'Perché';

  @override
  String get xtSvYou => 'te';

  @override
  String get xtUrl => 'URL';

  @override
  String get xtWzDoneBtn => 'Fatto';

  @override
  String get xtXwAddress => 'Indirizzo';

  @override
  String get xtXwAuthor => 'Proposta da';

  @override
  String get xtXwConnectedLead =>
      'Quelli accesi funzionano. Aprine uno per rifare l\'accesso o toglierlo.';

  @override
  String get xtXwFailedLead =>
      'Proposte degli agenti che non hanno passato le prove: non sono mai state installate.';

  @override
  String get xtXwFile => 'File';

  @override
  String get xtXwImportText => 'Uno .zip che ti hanno passato, per tutto o per un progetto.';

  @override
  String xtXwKeptFiles(String files) {
    return 'File della skill che restano: $files';
  }

  @override
  String get xtXwKind => 'Tipo';

  @override
  String get xtXwNewSkillText => 'Istruzioni che scrivi tu per i tuoi agenti; si installa subito.';

  @override
  String get xtXwOpenFile => 'Apri il file';

  @override
  String get xtXwOwnLead =>
      'Per esperti: una skill che ti hanno passato, una che scrivi tu, un server che non è nel catalogo.';

  @override
  String get xtXwOwnTitle => 'Fatte a mano';

  @override
  String get xtXwPrevious => 'Installata ora';

  @override
  String xtXwScripts(String files) {
    return 'Ha degli script ($files): approva solo se ti fidi di quello che fanno.';
  }

  @override
  String get xtXwServerText =>
      'Un server MCP per indirizzo o per comando, con la sua chiave se serve.';

  @override
  String get xtXwSignIn => 'Accesso';

  @override
  String get xtXwSkillNameHelp => 'Lettere minuscole, cifre e trattini, come report-settimanale.';

  @override
  String get xtXwSource => 'Fatto da';

  @override
  String get xtXwState => 'Stato';

  @override
  String get xtXwSummary => 'Perché è nata';

  @override
  String get xtXwTests => 'Prove in una sandbox usa e getta';

  @override
  String get xtXwTestsFailed => 'prove non superate';

  @override
  String get xtXwUpdates => 'Aggiornamento di una skill installata';

  @override
  String get xtXwWaitsYou => 'aspetta il tuo sì';

  @override
  String get xtYou => 'Tu';

  @override
  String get vkCancel => 'Annulla';

  @override
  String get vkClose => 'Chiudi';

  @override
  String get vkDvSection => 'Dispositivi';

  @override
  String get vkKcAdd => 'Aggiungi';

  @override
  String get vkKcAddSub => 'Il valore viene cifrato appena salvi';

  @override
  String get vkKcAddTitle => 'Una nuova credenziale';

  @override
  String get vkKcAgentsHow =>
      'Gli agenti usano una credenziale con use_credential, o attraverso gli strumenti che le colleghi dentro ogni credenziale.';

  @override
  String get vkKcAgentsHowNoProxy => 'Gli agenti usano una credenziale con use_credential.';

  @override
  String get vkKcAll => 'Tutte';

  @override
  String get vkKcAllAgents => 'Tutti gli agenti';

  @override
  String get vkKcAllAgentsHelp => 'Spento: solo gli agenti che scegli tu.';

  @override
  String get vkKcAllCats => 'Tutte';

  @override
  String get vkKcAsk => 'Chiedimi prima che venga usata';

  @override
  String get vkKcAsk_always => 'Ogni volta';

  @override
  String get vkKcAsk_never => 'Mai: mi fido delle regole sopra';

  @override
  String get vkKcAsk_session => 'La prima volta in ogni conversazione';

  @override
  String get vkKcAutos => 'Automazioni che possono usarla';

  @override
  String get vkKcBrAddress => 'Indirizzo di Rasgeth';

  @override
  String get vkKcBrCode => 'Codice';

  @override
  String get vkKcBrCodeLead =>
      'Nell\'estensione (la chiave nella barra del browser) scrivi questo indirizzo e questo codice. Il codice vale dieci minuti e per un solo browser.';

  @override
  String get vkKcBrCopied => 'Copiato';

  @override
  String get vkKcBrCopy => 'Copia';

  @override
  String vkKcBrDone(String name) {
    return 'Collegato: «$name». Puoi chiudere questa finestra.';
  }

  @override
  String get vkKcBrDownload => 'Scarica l\'estensione';

  @override
  String get vkKcBrDownloadFirefox => 'Scarica la versione per Firefox';

  @override
  String get vkKcBrExpired => 'Quel codice è scaduto: creane uno nuovo.';

  @override
  String vkKcBrExpires(String time) {
    return 'Valido fino alle $time';
  }

  @override
  String vkKcBrHowChromium(String page) {
    return 'Decomprimila in una cartella che non sposterai. Apri $page, attiva «Modalità sviluppatore», premi «Carica estensione non pacchettizzata» e scegli la cartella. Puoi anche trascinare lo zip su quella pagina.';
  }

  @override
  String get vkKcBrHowFirefox =>
      'Apri about:debugging#/runtime/this-firefox, premi «Carica componente aggiuntivo temporaneo…» e scegli lo zip. Firefox la tiene finché non si chiude: per tenerla sempre deve essere firmata da Mozilla.';

  @override
  String get vkKcBrHowOpera =>
      'Decomprimila in una cartella che non sposterai. Apri opera://extensions, attiva «Modalità sviluppatore» in alto a destra, premi «Carica estensione non pacchettizzata» e scegli la cartella. Puoi anche trascinare lo zip su quella pagina.';

  @override
  String get vkKcBrHttpNote =>
      'Questo indirizzo inizia con http: l\'estensione lo accetta solo in casa (questo computer o la rete di casa). Da fuori usa l\'accesso remoto, con https.';

  @override
  String get vkKcBrLead =>
      'L\'estensione del portachiavi compila gli accessi in Opera, Chrome, Edge, Brave e Firefox, solo sul sito a cui appartiene ogni password, e salva qui quelle nuove. Ogni uso compare nell\'elenco qui sopra.';

  @override
  String get vkKcBrLink => 'Collega un browser';

  @override
  String vkKcBrLinked(String when) {
    return 'collegato $when';
  }

  @override
  String get vkKcBrMakeCode => 'Crea un codice';

  @override
  String get vkKcBrNever => 'non ancora usato';

  @override
  String get vkKcBrNone => 'Nessun browser collegato.';

  @override
  String vkKcBrSeen(String when) {
    return 'visto $when';
  }

  @override
  String get vkKcBrStep1 => '1. Installa l\'estensione';

  @override
  String get vkKcBrStep2 => '2. Collegala con un codice';

  @override
  String get vkKcBrStore =>
      'Più avanti anche nel Chrome Web Store: si installa con un clic e si aggiorna da sola.';

  @override
  String get vkKcBrTitle => 'Nel tuo browser';

  @override
  String get vkKcBrUnlink => 'Scollega';

  @override
  String vkKcBrUnlinkQ(String name) {
    return 'Scollegare $name?';
  }

  @override
  String get vkKcBrUnlinkText =>
      'Il browser smette subito di raggiungere il portachiavi. Le password restano qui; per usarlo di nuovo, ricollegalo con un codice nuovo.';

  @override
  String get vkKcBrWhich => 'Il tuo browser';

  @override
  String get vkKcBrWinLead =>
      'L\'estensione del portachiavi compila gli accessi in Opera, Chrome, Edge, Brave e Firefox, solo sul sito a cui appartiene ogni password, e salva qui quelle nuove.';

  @override
  String get vkKcBrWinTitle => 'Collega un browser';

  @override
  String get vkKcCat_api => 'Chiavi API';

  @override
  String get vkKcCat_bank => 'Banca';

  @override
  String get vkKcCat_email => 'Email';

  @override
  String get vkKcCat_login => 'Accessi';

  @override
  String get vkKcCat_other => 'Altro';

  @override
  String get vkKcCat_server => 'Server';

  @override
  String get vkKcCategory => 'Tipo';

  @override
  String get vkKcChange => 'Cambia';

  @override
  String get vkKcClosed => 'Il portachiavi è chiuso';

  @override
  String get vkKcClosedKeys =>
      'Finché non si apre, le chiavi che hai dato a Rasgeth restano dove erano (secrets.json e i file privati) e non si cancella niente.';

  @override
  String get vkKcCopied => 'Copiato';

  @override
  String get vkKcCopiedNote => 'Copiato: tra 30 secondi lo tolgo dagli appunti.';

  @override
  String get vkKcCopy => 'Copia';

  @override
  String get vkKcEmpty =>
      'Ancora niente. Aggiungi la chiave di un servizio che un agente deve usare, o importa le password da un altro gestore.';

  @override
  String get vkKcExpired => 'Scaduta';

  @override
  String get vkKcExpires => 'Scade il';

  @override
  String get vkKcExpiresHelp => 'Rasgeth te lo ricorda un mese prima.';

  @override
  String vkKcExpiresIn(String n) {
    return 'Scade tra $n giorni';
  }

  @override
  String get vkKcExpiresToday => 'Scade oggi';

  @override
  String get vkKcExpiringLead => 'Da rinnovare presto:';

  @override
  String get vkKcExport => 'Esporta cifrato';

  @override
  String get vkKcExportGo => 'Scarica';

  @override
  String get vkKcExportLead =>
      'Un file con tutte le credenziali, cifrato con una frase segreta tua: senza nessuno può aprirlo, nemmeno Rasgeth.';

  @override
  String get vkKcExportTitle => 'Esporta il portachiavi';

  @override
  String get vkKcExported => 'Scaricato. Tieni il file e la frase segreta in posti diversi.';

  @override
  String get vkKcEyebrow => 'Portachiavi';

  @override
  String get vkKcFormat => 'Valore dell\'intestazione';

  @override
  String get vkKcFormat_1password => '1Password';

  @override
  String get vkKcFormat_bitwarden => 'Bitwarden';

  @override
  String get vkKcFormat_chrome => 'Chrome o Edge';

  @override
  String get vkKcFormat_firefox => 'Firefox';

  @override
  String get vkKcFormat_generic => 'CSV';

  @override
  String get vkKcGenAgain => 'Un\'altra';

  @override
  String vkKcGenChars(String n) {
    return '$n caratteri';
  }

  @override
  String get vkKcGenDigits => 'Solo cifre (PIN)';

  @override
  String get vkKcGenKind => 'Di che cosa è fatta';

  @override
  String get vkKcGenLength => 'Lunghezza';

  @override
  String get vkKcGenLetters => 'Lettere e cifre';

  @override
  String get vkKcGenSymbols => 'Lettere, cifre, simboli';

  @override
  String get vkKcGenUse => 'Usa questa';

  @override
  String get vkKcGenerate => 'Creane una';

  @override
  String get vkKcHeader => 'Intestazione';

  @override
  String get vkKcHide => 'Nascondi';

  @override
  String get vkKcHosts => 'Indirizzi consentiti';

  @override
  String get vkKcHostsHelp =>
      'Nomi separati da virgole; *.esempio.it per tutti i suoi sottodomini.';

  @override
  String get vkKcHow => 'Come va sulla richiesta';

  @override
  String vkKcHowHelp(String ref, String value) {
    return 'Quando un agente non scrive da sé $ref, il valore va in questa intestazione. $value sta per il segreto.';
  }

  @override
  String get vkKcImport => 'Importa';

  @override
  String get vkKcImport1password => '1Password: File > Esporta > CSV';

  @override
  String get vkKcImportBitwarden => 'Bitwarden: Strumenti > Esporta cassaforte > .csv';

  @override
  String get vkKcImportChrome => 'Chrome ed Edge: Impostazioni > Password > Esporta password';

  @override
  String get vkKcImportFirefox => 'Firefox: Password > menu > Esporta password';

  @override
  String vkKcImportFound(String from, String n) {
    return '$n password trovate nel file di $from. Scegli quelle da tenere:';
  }

  @override
  String vkKcImportGo(String n) {
    return 'Importa $n';
  }

  @override
  String get vkKcImportLead =>
      'Esporta le password dall\'altro gestore in un file CSV, poi sceglilo qui. Va bene anche un file del portachiavi esportato da Rasgeth.';

  @override
  String get vkKcImportLogins =>
      'Gli accessi importati sono solo per te: nessun agente può usarli finché non lo permetti.';

  @override
  String get vkKcImportPick => 'Scegli il file';

  @override
  String get vkKcImportSafe => 'Dopo, cancella il file CSV: contiene le tue password in chiaro.';

  @override
  String get vkKcImportSealedGo => 'Apri e importa';

  @override
  String get vkKcImportSealedHelp => 'La frase segreta scelta quando il file è stato esportato.';

  @override
  String vkKcImportSkipped(String n) {
    return '$n senza password sono state lasciate fuori.';
  }

  @override
  String get vkKcImportTitle => 'Importa le password';

  @override
  String vkKcImported(String n) {
    return '$n credenziali aggiunte al portachiavi.';
  }

  @override
  String get vkKcLead =>
      'Cifrate su questo computer. Gli agenti le usano per nome e non le vedono mai; tu scegli dove può andare ognuna e chi può usarla.';

  @override
  String get vkKcLockedAdmin => 'Impostata dall\'amministratore';

  @override
  String get vkKcManage => 'Gestisci';

  @override
  String get vkKcMore => 'Altro';

  @override
  String get vkKcMoveLead =>
      'Da Bitwarden, 1Password, Chrome, Edge o Firefox; fuori in un file cifrato con una frase segreta tua.';

  @override
  String get vkKcMoveTitle => 'Portale qui, portale con te';

  @override
  String get vkKcName => 'Nome per gli agenti';

  @override
  String get vkKcNameBad => 'Solo lettere minuscole, cifre, - e _ (almeno due)';

  @override
  String get vkKcNameHelp =>
      'Minuscole, senza spazi: gli agenti lo scrivono per usare la credenziale.';

  @override
  String get vkKcNeverUsed => 'Mai usata';

  @override
  String get vkKcNoHosts => 'Senza un indirizzo nessun agente può usarla: resta solo per te.';

  @override
  String get vkKcNoMatch => 'Nessuna corrisponde alla ricerca.';

  @override
  String get vkKcNoUses => 'Nessun agente ha ancora usato una credenziale.';

  @override
  String get vkKcNone => 'Nessuna';

  @override
  String get vkKcNotes => 'Note';

  @override
  String get vkKcPassphrase => 'Frase segreta';

  @override
  String get vkKcPassphraseAgain => 'Di nuovo la frase segreta';

  @override
  String get vkKcPassphraseDiffer => 'Le due sono diverse';

  @override
  String get vkKcPassphraseHelp =>
      'Almeno 8 caratteri. Tienila in un posto sicuro: non si può recuperare.';

  @override
  String get vkKcProt_dpapi => 'Protetto da Windows';

  @override
  String get vkKcProt_env => 'Cifrato con la chiave del server';

  @override
  String get vkKcProt_file => 'Cifrato con una chiave tenuta su questo computer';

  @override
  String get vkKcProt_keychain => 'Protetto dal Portachiavi del Mac';

  @override
  String get vkKcQ => 'Le tue chiavi e password, al sicuro in un posto solo';

  @override
  String get vkKcRemove => 'Elimina';

  @override
  String vkKcRemoveQ(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get vkKcRemoveText =>
      'La credenziale esce dal portachiavi per sempre: agenti e strumenti non potranno più usarla.';

  @override
  String get vkKcSafeText =>
      'Cifratura AES-256, mai dentro un progetto o in git, mai scritte in una chat o in un registro.';

  @override
  String get vkKcSearch => 'Cerca per nome, servizio, utente o etichetta';

  @override
  String get vkKcSecret => 'Il segreto';

  @override
  String get vkKcSecretLead =>
      'La chiave, il token o la password. Una volta salvato non si vede più, a meno che lo chiedi tu.';

  @override
  String get vkKcSecretPlaceholder => 'Incollalo o scrivilo qui';

  @override
  String get vkKcService => 'Servizio';

  @override
  String get vkKcServiceExample => 'Revolut Business';

  @override
  String get vkKcServiceHelp =>
      'Il nome con cui la conosci: Revolut, Gmail, il server dell\'ufficio.';

  @override
  String get vkKcShow => 'Mostra';

  @override
  String get vkKcShowQ => 'Mostrare il segreto?';

  @override
  String get vkKcShowText =>
      'Resterà sullo schermo finché non lo nascondi o chiudi la finestra. Assicurati che nessuno stia guardando.';

  @override
  String get vkKcUnlockShow => 'Sblocca per vedere il segreto';

  @override
  String get vkKcUnlockCopy => 'Sblocca per copiare il segreto';

  @override
  String get vkKcUnlockRefused => 'Non sbloccato: il segreto resta nascosto.';

  @override
  String get vkKcNoLockQ => 'Questo dispositivo non ha un blocco';

  @override
  String get vkKcNoLockText =>
      'Su questo dispositivo niente controlla che sia tu: nelle impostazioni di sistema non c\'è un PIN, un\'impronta o il volto. Chiunque lo tenga in mano potrebbe vedere le tue chiavi, quindi imposta lì un blocco schermo. Vuoi andare avanti lo stesso?';

  @override
  String get vkKcSomeAgents => 'Gli agenti che possono usarla';

  @override
  String get vkKcSomeone => 'Qualcuno';

  @override
  String vkKcSys_chat(String what) {
    return 'Chat: $what';
  }

  @override
  String vkKcSys_email(String what) {
    return 'Casella email: $what';
  }

  @override
  String vkKcSys_git(String what) {
    return 'Codice: $what';
  }

  @override
  String vkKcSys_mcp(String what) {
    return 'Estensione: $what';
  }

  @override
  String vkKcSys_other(String what) {
    return '$what';
  }

  @override
  String vkKcSys_provider(String what) {
    return 'Fornitore di modelli: $what';
  }

  @override
  String vkKcSys_search(String what) {
    return 'Ricerca web: $what';
  }

  @override
  String vkKcSys_ssh(String what) {
    return 'Macchina (SSH): $what';
  }

  @override
  String get vkKcSystem => 'Tenute da Rasgeth';

  @override
  String get vkKcSystemLead =>
      'Chiavi messe da chi ha installato questo server (nel suo ambiente): Rasgeth le usa, qui non si possono cambiare.';

  @override
  String get vkKcSystemTitle => 'Impostate dall\'amministratore';

  @override
  String get vkKcTags => 'Etichette';

  @override
  String get vkKcTagsHelp => 'Separate da virgole: lavoro, casa…';

  @override
  String get vkKcTools => 'Strumenti delle estensioni che la ricevono';

  @override
  String get vkKcToolsHelp =>
      'Uno strumento scelto qui riceve l\'indirizzo per raggiungere il servizio con questa credenziale, mai il valore.';

  @override
  String get vkKcUrl => 'Indirizzo (se c\'è)';

  @override
  String vkKcUseAs(String name) {
    return 'Gli agenti la chiamano $name';
  }

  @override
  String vkKcUseBrowser(String name) {
    return '$name (browser)';
  }

  @override
  String vkKcUse_denied(String host, String name) {
    return 'ha chiesto $name verso $host: hai detto di no';
  }

  @override
  String vkKcUse_moved(String host, String name) {
    return 'ha spostato $name qui da $host';
  }

  @override
  String vkKcUse_refused(String host, String name) {
    return 'non ha potuto usare $name verso $host';
  }

  @override
  String vkKcUse_used(String host, String name) {
    return 'ha usato $name verso $host';
  }

  @override
  String get vkKcUsedBy => 'Usata da:';

  @override
  String get vkKcUsedByText =>
      'Rasgeth usa questa chiave da sola. Qui puoi cambiarla, scegliere se possono usarla anche gli agenti e vedere ogni uso; la togli dalla sua pagina.';

  @override
  String vkKcUsedTimes(String n, String when) {
    return 'Usata $n volte, l\'ultima $when';
  }

  @override
  String get vkKcUser => 'Utente o email (se c\'è)';

  @override
  String get vkKcUsesLead =>
      'Ogni volta che un agente ha chiesto una credenziale: quando, verso dove e com\'è andata.';

  @override
  String get vkKcUsesOne => 'Gli ultimi usi';

  @override
  String get vkKcUsesTitle => 'Chi le ha usate';

  @override
  String get vkKcWhere => 'Dove può andare';

  @override
  String get vkKcWhereLead =>
      'Il valore viene messo su una richiesta solo verso questi indirizzi: altrove viene rifiutato.';

  @override
  String get vkKcWho => 'Chi può usarla';

  @override
  String get vkKcWhoLead =>
      'Gli agenti non vedono mai il valore: lo chiedono per nome e Rasgeth lo mette sulla richiesta.';

  @override
  String get vkMcSection => 'Macchine';

  @override
  String get vkSave => 'Salva';

  @override
  String get vkSettings => 'Impostazioni';

  @override
  String get vkWzCode => 'Dove sta il codice';

  @override
  String get vkWzRemote => 'Accesso da fuori casa';

  @override
  String get vkAutomations => 'Automazioni';

  @override
  String get vkChats => 'Altre chat';

  @override
  String get vkExtensions => 'Estensioni';

  @override
  String get vkSubscriptions => 'Modelli e abbonamenti';

  @override
  String get vkTelegram => 'Telegram';

  @override
  String get g4211Hub => 'Servizi, skill, generazione e le proposte degli agenti';

  @override
  String get g4212Hub => 'Chiavi e password, al sicuro in un posto solo';

  @override
  String get g4211SignInOpened =>
      'La pagina del servizio si è aperta nel browser: accedi lì, poi torna qui.';

  @override
  String get g4211OpenExtensions => 'Apri Estensioni';

  @override
  String get g4212OpenKeychain => 'Apri il Portachiavi';

  @override
  String get syBackup => 'Backup';

  @override
  String get syBackupAddsHint =>
      'Un progetto con un nome già usato qui entra accanto all\'altro, con un numero dopo il nome.';

  @override
  String get syBackupAlreadyHere => 'c\'è già, resta com\'è';

  @override
  String get syBackupAnother => 'Importa un altro backup';

  @override
  String get syBackupChoose => 'Scegli il file del backup';

  @override
  String syBackupCounts(String agents, String conversations, String size) {
    return '$agents agenti · $conversations conversazioni · $size di file';
  }

  @override
  String syBackupDownload(String file) {
    return 'Scarica $file';
  }

  @override
  String get syBackupExport => 'Fai un backup';

  @override
  String get syBackupExportHint =>
      'Progetti con i loro file, agenti, conversazioni, chat e bacheca. Le chiavi e gli accessi ai servizi non ci sono: restano su questo computer. Le cartelle node_modules sono lasciate fuori (si ricreano).';

  @override
  String syBackupFrom(String when) {
    return 'Backup del $when';
  }

  @override
  String get syBackupImport => 'Importa un backup';

  @override
  String get syBackupImportHint =>
      'Da un altro Rasgeth o da questo. Qui non si cancella né si sostituisce niente: quello che c\'è nel backup viene aggiunto, e quello che c\'è già resta com\'è.';

  @override
  String get syBackupImportNow => 'Importa';

  @override
  String syBackupImported(String agents, String conversations, String projects) {
    return 'Fatto: aggiunti $projects progetti, $agents agenti e $conversations conversazioni.';
  }

  @override
  String syBackupKeepName(String name) {
    return 'Tieni $name';
  }

  @override
  String get syBackupKeys => 'Includi il portachiavi';

  @override
  String get syBackupKeysHelp =>
      'Cifrato con una frase segreta tua, con le chiavi dei modelli, delle chat e delle caselle: senza, le credenziali del backup non si possono aprire.';

  @override
  String get syBackupKeysIn => 'Il backup contiene un portachiavi: la sua frase segreta';

  @override
  String get syBackupKeysInHelp =>
      'Lasciala vuota per importare tutto il resto senza le credenziali.';

  @override
  String get syBackupKeysWrong =>
      'Il portachiavi non è stato importato: frase segreta sbagliata. Tutto il resto sì.';

  @override
  String get syBackupMake => 'Prepara il backup';

  @override
  String get syBackupMakeAgain => 'Preparalo di nuovo';

  @override
  String syBackupNameQuestion(String backup, String here, String who) {
    return '$who qui si chiama $here e nel backup $backup. Che nome tiene?';
  }

  @override
  String get syBackupNothingNew =>
      'Tutti i progetti di questo backup ci sono già: si aggiunge solo quello che manca.';

  @override
  String get syBackupPurpose =>
      'Tutti i progetti con i loro file, gli agenti e le conversazioni in un file solo: da tenere al sicuro, o da portare in un altro Rasgeth.';

  @override
  String get syBackupSaved => 'Salvato nella cartella Download.';

  @override
  String get syBackupSending => 'Mando il file a Rasgeth';

  @override
  String syBackupTakeName(String name) {
    return 'Usa $name';
  }

  @override
  String get syBrainDisconnect => 'Scollega';

  @override
  String get syCaddyDomain => 'L\'indirizzo';

  @override
  String get syCaddyDomainHelp => 'Rasgeth prende da solo il certificato HTTPS da Let\'s Encrypt.';

  @override
  String get syCaddyPihole =>
      'In casa alcuni router non riescono a raggiungere il proprio indirizzo pubblico: allora apri Rasgeth in casa con il solito link, oppure accendi Pi-hole in Impostazioni, Accesso da fuori casa (è facoltativo).';

  @override
  String get syCaddyStep1 =>
      'Dal fornitore del tuo dominio crea un record DNS di tipo A per l\'indirizzo che vuoi (per esempio rasgeth.tuodominio.it) che punti all\'indirizzo pubblico di casa. Se cambia, usa un servizio di DNS dinamico.';

  @override
  String get syCaddyStep2 => 'Sul router inoltra le porte 80 e 443 a questo computer.';

  @override
  String get syCaddyWarning =>
      'Con questa strada la pagina di accesso di Rasgeth è su internet: tieni la password forte e la seconda verifica attiva.';

  @override
  String get syCancel => 'Annulla';

  @override
  String get syCfAccess =>
      'Ancora più sicuro: in Cloudflare Zero Trust, Access, aggiungi un\'applicazione per questo indirizzo, così Cloudflare chiede chi sei prima ancora di mostrare la pagina.';

  @override
  String get syCfBuy => 'Compra un dominio su Cloudflare';

  @override
  String get syCfHost => 'L\'indirizzo che hai scelto';

  @override
  String get syCfHostHelp =>
      'Per esempio rasgeth.tuodominio.it: sottodominio e dominio del Public hostname.';

  @override
  String get syCfStep1 =>
      'Se non hai ancora un dominio, comprane uno (Cloudflare li vende a prezzo di costo, circa 10 euro l\'anno):';

  @override
  String get syCfStep2 =>
      'Apri Tunnels in Cloudflare Zero Trust, premi Create a tunnel, scegli Cloudflared e dagli un nome (per esempio rasgeth):';

  @override
  String get syCfStep3 =>
      'Nel passo Public hostname: sottodominio rasgeth, il tuo dominio, Service type HTTP, URL redgiant:7600. Salva.';

  @override
  String get syCfStep4 =>
      'Cloudflare mostra un comando con un token lungo dopo --token: copia solo il token e scrivi qui l\'indirizzo.';

  @override
  String get syCfToken => 'Il token del tunnel';

  @override
  String get syCfTokenHelp =>
      'La stringa lunga dopo --token nel comando che mostra Cloudflare (comincia con eyJ).';

  @override
  String get syCfTunnels => 'Tunnel di Cloudflare';

  @override
  String get syConnecting => 'collegamento…';

  @override
  String get syConversations => 'Conversazioni';

  @override
  String syErr_agent_limit(String count, String max, String project) {
    return 'Il progetto «$project» può avere al massimo $max agenti oltre all\'orchestratore: ne ha $count. Alza il limite in Impostazioni › Progetti o rimuovine uno.';
  }

  @override
  String get syErr_agent_removed =>
      'L\'agente è stato rimosso dalla squadra: ripristinalo per lavorarci.';

  @override
  String get syErr_agent_stopped => 'L\'agente è fermato (in pausa): riattivalo per riprendere.';

  @override
  String get syErr_bad_name => 'Questo non è un nome (per esempio git.home.example.com).';

  @override
  String get syErr_code_rejected =>
      'Anthropic non ha accettato questo codice: forse è incompleto o vecchio. Riapri la pagina di accesso per averne uno nuovo.';

  @override
  String get syErr_email_failed =>
      'La casella non ha fatto entrare Rasgeth: controlla server, indirizzo e password per le app.';

  @override
  String get syErr_failed => 'L\'accesso non è andato a buon fine. Riprova dall\'inizio.';

  @override
  String get syErr_host_unreachable =>
      'Il nome del server è noto, ma da Rasgeth il suo indirizzo non risponde. Vedi Impostazioni › Accesso da fuori casa › I tuoi servizi di casa.';

  @override
  String get syErr_key_rejected =>
      'Il fornitore ha rifiutato questa chiave. Controlla di averla copiata tutta e che sia ancora attiva.';

  @override
  String get syErr_memory_empty => 'Scrivi qualcosa da ricordare.';

  @override
  String get syErr_memory_forgotten => 'Un ricordo dimenticato per sempre non può tornare.';

  @override
  String get syErr_memory_full =>
      'La memoria è piena: cancella o unisci prima qualche ricordo vecchio.';

  @override
  String get syErr_memory_gone => 'Quel ricordo non c\'è più.';

  @override
  String get syErr_memory_long =>
      'Un ricordo è lungo al massimo 400 caratteri: scrivilo più corto.';

  @override
  String get syErr_memory_moved =>
      'Il ricordo è cambiato ancora: annulla prima la modifica più recente.';

  @override
  String get syErr_memory_same => 'Un altro ricordo dice già la stessa cosa.';

  @override
  String get syErr_memory_secret =>
      'Sembra una password, un codice o il numero di una carta: i segreti non vanno mai in memoria.';

  @override
  String get syErr_memory_undone => 'Quella modifica è già stata annullata.';

  @override
  String get syErr_missing_permission =>
      'GitHub non ha lasciato creare repository a questo token. Fanne uno nuovo con Administration su Read and write.';

  @override
  String get syErr_name_not_found =>
      'Rasgeth non trova il nome del server nel DNS che usa. Vedi Impostazioni › Accesso da fuori casa › I tuoi servizi di casa.';

  @override
  String get syErr_no_login => 'Prima apri la pagina di accesso di Anthropic.';

  @override
  String get syErr_no_model =>
      'Non hai ancora scelto un modello: apri Impostazioni, Modelli e abbonamenti, collegane uno (un abbonamento, una chiave o un modello locale) e sceglilo in \"Il modello che usano gli agenti\".';

  @override
  String get syErr_no_page =>
      'Non è stato possibile preparare la pagina di accesso di Anthropic. Riprova fra un momento.';

  @override
  String get syErr_no_password => 'Prima imposta una password.';

  @override
  String get syErr_portrait_empty => 'Scrivi il tratto.';

  @override
  String get syErr_portrait_gone => 'Quel tratto non c\'è più.';

  @override
  String get syErr_portrait_long => 'Un tratto è al massimo di 200 caratteri: scrivilo più corto.';

  @override
  String get syErr_portrait_private =>
      'Indirizzi email e numeri di telefono non entrano mai nel ritratto.';

  @override
  String get syErr_portrait_secret =>
      'Sembra una password, un codice o un numero di carta: i segreti non entrano mai nel ritratto.';

  @override
  String get syErr_project_archived => 'Il progetto è archiviato: ripristinalo per lavorarci.';

  @override
  String syErr_provider_stalled(String minutes, String retries) {
    return 'Il fornitore non risponde da $minutes minuti: ho riprovato $retries volte. Riprova fra un po\', o scegli un altro modello.';
  }

  @override
  String get syErr_terms => 'Prima spunta la casella sulle condizioni dei fornitori.';

  @override
  String get syErr_token_rejected =>
      'Telegram ha rifiutato questo token. Copialo di nuovo dal messaggio di BotFather, tutto intero.';

  @override
  String get syErr_too_many => 'Troppi tentativi sbagliati: aspetta 15 minuti e riprova.';

  @override
  String get syErr_unreachable =>
      'Il fornitore non ha risposto. Controlla l\'indirizzo e la connessione a internet, poi riprova.';

  @override
  String get syErr_vault_bad_file =>
      'Questo file non è un\'esportazione di password che Rasgeth sa leggere.';

  @override
  String get syErr_vault_bad_passphrase => 'Frase segreta sbagliata, o file rovinato.';

  @override
  String get syErr_vault_closed => 'Il portachiavi è chiuso su questo computer.';

  @override
  String get syErr_vault_in_git =>
      'La cartella del portachiavi sta dentro un repository git: non deve mai finire in un commit. Sposta la cartella dei dati di Rasgeth fuori da lì.';

  @override
  String get syErr_vault_name_taken =>
      'Un\'altra credenziale ha già quel nome per gli agenti: scegline un altro.';

  @override
  String get syErr_vault_no_value => 'Scrivi il segreto.';

  @override
  String get syErr_vault_not_found => 'Quella credenziale non è più nel portachiavi.';

  @override
  String get syErr_vault_system =>
      'Rasgeth usa questa chiave: la togli dalla sua pagina nelle Impostazioni.';

  @override
  String get syErr_voice_convert =>
      'Non sono riuscito a convertire la registrazione per whisper su questo computer.';

  @override
  String get syErr_voice_empty => 'La registrazione è vuota.';

  @override
  String syErr_voice_key_refused(String name) {
    return '$name ha rifiutato la chiave: controllala in Impostazioni, Voce.';
  }

  @override
  String syErr_voice_no_key(String name) {
    return '$name non ha ancora una chiave: aggiungila in Impostazioni, Voce.';
  }

  @override
  String get syErr_voice_no_service =>
      'Rasgeth non ha un servizio di trascrizione: scegline uno in Impostazioni, Voce, Trascrizione.';

  @override
  String get syErr_voice_provider => 'Questo fornitore non lo sa fare: scegline un altro.';

  @override
  String syErr_voice_rate_limited(String name) {
    return '$name dice troppe richieste o credito finito.';
  }

  @override
  String syErr_voice_service_error(String name, String status) {
    return '$name ha risposto con un errore ($status).';
  }

  @override
  String syErr_voice_timeout(String name) {
    return '$name ci ha messo troppo a rispondere.';
  }

  @override
  String get syErr_voice_too_long => 'La registrazione è troppo lunga.';

  @override
  String syErr_voice_unreachable(String name) {
    return '$name non si raggiunge: controlla che sia acceso e il suo indirizzo.';
  }

  @override
  String get syErr_weak => 'La password deve avere almeno 10 caratteri.';

  @override
  String get syErr_wrong => 'Password o codice sbagliati.';

  @override
  String get syError => 'Errore';

  @override
  String get syFailed => 'fallito';

  @override
  String get syFbArch => 'Architettura';

  @override
  String get syFbBackupBusy => 'Una copia è già in corso.';

  @override
  String get syFbBackupNow => 'Fai una copia adesso';

  @override
  String get syFbBackupQ => 'Meglio su un altro disco: se questo si rompe, la copia c\'è ancora.';

  @override
  String get syFbBackupStarted => 'Copia avviata: la vedi tra i lavori in corso.';

  @override
  String get syFbBackupTitle => 'Copie di sicurezza';

  @override
  String get syFbCannotMount => 'Qui non si può montare';

  @override
  String syFbContainerDisks(String name) {
    return 'Rasgeth OS gira in un container ($name): i dischi che vede sono quelli della macchina che lo ospita e da qui non si possono usare.';
  }

  @override
  String get syFbDaily => 'Ogni giorno';

  @override
  String get syFbDataDir => 'Cartella';

  @override
  String get syFbDataQ => 'Qui ci sono progetti, conversazioni e impostazioni.';

  @override
  String get syFbDataTitle => 'I dati';

  @override
  String get syFbDay => 'Giorno';

  @override
  String syFbDestDisk(String label, String path) {
    return 'Le copie vanno sul disco $label ($path).';
  }

  @override
  String syFbDestFolder(String path) {
    return 'Le copie vanno nella cartella $path.';
  }

  @override
  String syFbDestNode(String name) {
    return 'Le copie vanno sul nodo $name, nello spazio che presta.';
  }

  @override
  String syFbDestSftp(String machine, String path) {
    return 'Le copie vanno su $machine, in $path (SFTP).';
  }

  @override
  String syFbDestSmb(String path, String user) {
    return 'Le copie vanno nella cartella condivisa $path, come $user.';
  }

  @override
  String get syFbDisks => 'Dischi';

  @override
  String get syFbDisksTitle => 'Dischi rimovibili';

  @override
  String get syFbErr_already => 'Il container ha già una cartella con quel nome.';

  @override
  String get syFbErr_auth =>
      'La destinazione ha rifiutato l\'accesso: controlla utente e password (o la chiave della macchina).';

  @override
  String get syFbErr_bad_path =>
      'Scrivi un percorso completo (/volume1/Rasgeth) o dalla home (~/backup).';

  @override
  String get syFbErr_denied => 'La destinazione non lascia scrivere questo utente.';

  @override
  String get syFbErr_disk_missing =>
      'Il disco delle copie non è collegato: collegalo. Non è stato scritto niente altrove.';

  @override
  String get syFbErr_has_filesystem => 'Quel disco è già formattato: da qui non si riformatta mai.';

  @override
  String get syFbErr_keychain_closed => 'Apri prima il Portachiavi: la password si tiene lì.';

  @override
  String get syFbErr_mismatch =>
      'La copia è arrivata diversa dall\'originale: non è stata tenuta. Riprova.';

  @override
  String get syFbErr_needs_format => 'Quel disco non è formattato.';

  @override
  String get syFbErr_no_container => 'Sull\'host non c\'è un container con quel numero.';

  @override
  String get syFbErr_no_destination => 'Scegli prima dove vanno le copie.';

  @override
  String get syFbErr_no_disk => 'Quel disco non è (più) un disco rimovibile dell\'host.';

  @override
  String get syFbErr_not_found => 'La cartella o la destinazione non c\'è (più).';

  @override
  String get syFbErr_not_proxmox => 'Quella macchina non è un host Proxmox.';

  @override
  String get syFbErr_not_trusted =>
      'Prova prima questa macchina in Impostazioni › Macchine e fidati della sua chiave.';

  @override
  String get syFbErr_place_missing =>
      'La cartella della macchina ospite ora non è montata: non è stato scritto niente sul disco di sistema.';

  @override
  String get syFbErr_smb_address =>
      'Scrivi la cartella condivisa come \\\\host\\condivisione\\cartella (lettere, cifre, spazi, punti e trattini).';

  @override
  String get syFbErr_smb_bad_domain => 'Il dominio è fatto di lettere, cifre, punti e trattini.';

  @override
  String get syFbErr_smb_bad_password => 'Questa password non si può usare (niente a capo).';

  @override
  String get syFbErr_smb_bad_user => 'Questo nome utente non si può usare.';

  @override
  String get syFbErr_smb_missing =>
      'Le cartelle condivise hanno bisogno di smbclient, che questa installazione non ha.';

  @override
  String get syFbErr_unreachable =>
      'La destinazione non risponde: è accesa e in rete? Non è stato scritto niente altrove.';

  @override
  String get syFbFolderLead =>
      'Una cartella in cui questa macchina può scrivere: una condivisione di rete, un disco montato da te. Non dentro la cartella dei dati.';

  @override
  String get syFbFolderPath => 'Cartella';

  @override
  String get syFbFolderTitle => 'Oppure una cartella';

  @override
  String syFbFreeOf(String free) {
    return '$free liberi';
  }

  @override
  String syFbFreeOfTotal(String free, String total) {
    return '$free GB liberi su $total GB';
  }

  @override
  String get syFbFri => 'Ven';

  @override
  String get syFbHostBad_bad_device => 'Il dispositivo di questo disco non si può usare.';

  @override
  String get syFbHostBad_bad_id => 'Il numero del container è un numero, come 105.';

  @override
  String get syFbHostBad_bad_mp => 'Nessun punto di montaggio libero.';

  @override
  String get syFbHostBad_bad_name => 'Il nome di questo disco non si può usare per una cartella.';

  @override
  String get syFbHostId => 'Numero del container su Proxmox';

  @override
  String syFbHostIdHelp(String hostname) {
    return 'Il numero nell\'elenco di Proxmox (questo container si chiama $hostname).';
  }

  @override
  String get syFbHostKind => 'La macchina ospite';

  @override
  String get syFbHostLead =>
      'Da un container Rasgeth vede i dischi della macchina ospite ma non può montarli: li monta l\'ospite e passa dentro una cartella. Rasgeth se ne accorge da solo.';

  @override
  String syFbHostMany(String n) {
    return 'Su questa macchina ci sono $n dischi rimovibili: scegli quello per le copie.';
  }

  @override
  String get syFbHostNone =>
      'Non si vede nessun disco rimovibile dell\'ospite: collegalo all\'ospite, oppure usa una cartella in rete qui sotto.';

  @override
  String syFbHostOne(String how, String size, String title) {
    return 'Su questa macchina c\'è il disco $title, $how, $size.';
  }

  @override
  String get syFbHostOther => 'Altro';

  @override
  String get syFbHostSteps => 'Da eseguire sulla macchina ospite, come root';

  @override
  String get syFbHostTitle => 'Un disco della macchina ospite';

  @override
  String syFbHostWatching(String target) {
    return 'Controllo ogni pochi secondi: quando arriva $target compare qui sopra, pronta da usare.';
  }

  @override
  String get syFbHour => 'Ora';

  @override
  String get syFbKeep => 'Copie tenute';

  @override
  String syFbKeepN(String n) {
    return 'ne tiene $n';
  }

  @override
  String syFbLastFailed(String when, String why) {
    return 'La copia del $when non è riuscita: $why';
  }

  @override
  String syFbLastOk(String when) {
    return 'Ultima copia: $when, riletta e completa.';
  }

  @override
  String get syFbListAgain => 'Guarda di nuovo';

  @override
  String syFbListEmpty(String where) {
    return 'Ancora nessuna copia in $where.';
  }

  @override
  String get syFbListLead =>
      'Ognuna si può riportare qui: si aggiunge quello che manca, qui non si cancella niente.';

  @override
  String get syFbListShow => 'Mostra le copie';

  @override
  String get syFbListTitle => 'Le copie che ci sono';

  @override
  String get syFbMachineTitle => 'La macchina';

  @override
  String get syFbMethod_helper =>
      'Scegline uno: Rasgeth lo monta solo per le copie. I dischi di sistema non vengono mai proposti.';

  @override
  String get syFbMethod_none =>
      'Questa installazione non può montare dischi (per esempio Docker senza privilegi): usa un disco già montato, oppure una cartella qui sotto.';

  @override
  String get syFbMethod_udisks =>
      'Scegline uno: lo monta il sistema (udisks2). I dischi di sistema non vengono mai proposti.';

  @override
  String get syFbMissing_not_installed => 'non noto: manca il programma che lo dice';

  @override
  String get syFbMissing_unreadable => 'non leggibile';

  @override
  String get syFbMissing_unsupported => 'non disponibile su questo sistema';

  @override
  String get syFbMon => 'Lun';

  @override
  String get syFbNetAProxy => 'un reverse proxy';

  @override
  String syFbNetDns(String ip) {
    return 'Un server DNS nella tua rete ($ip): un nome come rasgeth.home può puntare qui.';
  }

  @override
  String get syFbNetFolder => 'Cartella lì';

  @override
  String get syFbNetFolderHelp =>
      'Un percorso completo (/volume1/Rasgeth, E:\\Backup) o dalla home (~/RedGiant-backups). Se manca la crea.';

  @override
  String get syFbNetLanOnly => 'Solo rete locale va benissimo: salta questo passo.';

  @override
  String get syFbNetLead =>
      'Niente da montare: funziona anche in un container o in Docker. Ogni copia arriva con un nome temporaneo e prende il suo nome vero solo quando è completa e controllata.';

  @override
  String syFbNetName(String name) {
    return 'Hai raggiunto Rasgeth con un nome: $name.';
  }

  @override
  String get syFbNetNoMachines =>
      'Nessuna macchina ancora: aggiungi il NAS o un altro computer in Impostazioni › Macchine (SSH), provalo una volta e torna qui.';

  @override
  String get syFbNetNoNodes =>
      'Nessun Rasgeth abbinato: abbinane uno in Impostazioni › Nodi (deve prestare il suo spazio).';

  @override
  String get syFbNetNode => 'Un altro Rasgeth';

  @override
  String get syFbNetNotTrusted => 'Prima provala in Impostazioni › Macchine';

  @override
  String get syFbNetNothing => 'Non c\'è niente che raggiunga già questa macchina da fuori.';

  @override
  String get syFbNetPick => 'Usa per le copie';

  @override
  String syFbNetProxies(String names) {
    return 'Gira già su questa macchina: $names.';
  }

  @override
  String syFbNetProxyFront(String name) {
    return 'Davanti a Rasgeth c\'è già $name.';
  }

  @override
  String get syFbNetSftp => 'Una delle tue macchine';

  @override
  String get syFbNetSmb => 'Cartella condivisa (SMB)';

  @override
  String syFbNetTailscale(String name) {
    return 'Tailscale è già attivo qui ($name): puoi usarlo.';
  }

  @override
  String get syFbNetTailscaleOff => 'Tailscale è installato qui ma non collegato.';

  @override
  String get syFbNetTitle => 'Oppure una cartella in rete';

  @override
  String get syFbNoDisks =>
      'Nessun disco rimovibile trovato. Collegane uno e riapri questa pagina, oppure usa una cartella.';

  @override
  String get syFbNodeOffline => 'Non in linea ora';

  @override
  String get syFbNodeOnline => 'In linea';

  @override
  String get syFbOff => 'Solo quando lo chiedo';

  @override
  String get syFbOfferCloud => 'Modelli nel cloud: sempre disponibili.';

  @override
  String syFbOfferLocalCpu(String max) {
    return 'Modelli locali: sì, piccoli, sul processore, fino a circa $max GB (più lenti che su una scheda video).';
  }

  @override
  String syFbOfferLocalGpu(String max) {
    return 'Modelli locali: sì, sulla scheda video, fino a circa $max GB.';
  }

  @override
  String get syFbOfferNoLocal =>
      'Modelli locali: non proposti, qui c\'è troppa poca memoria. Puoi comunque aggiungerne uno da Impostazioni › Modelli.';

  @override
  String get syFbPairLater =>
      'Scrivi l\'indirizzo del Rasgeth principale e il codice che mostra in Impostazioni › Nodi › «Aggiungi un nodo». Puoi farlo anche dopo, dalle Impostazioni.';

  @override
  String get syFbPassword => 'Password';

  @override
  String get syFbPasswordAgain => 'La stessa password di nuovo';

  @override
  String get syFbPasswordHelp => 'Almeno 10 caratteri.';

  @override
  String syFbPlaceFree(String free, String total) {
    return '$free GB liberi su $total';
  }

  @override
  String get syFbPlaceNotWritable => 'Rasgeth non può scriverci';

  @override
  String get syFbPlacesLead =>
      'Cartelle che la macchina che ospita Rasgeth ha montato in /var/lib/redgiant/backups (un punto di montaggio di Proxmox, una cartella di rete).';

  @override
  String get syFbPlacesTitle => 'Cartelle montate per le copie';

  @override
  String get syFbPveDo => 'Passalo a Rasgeth';

  @override
  String syFbPveDone(String target) {
    return 'Fatto: la cartella $target è arrivata.';
  }

  @override
  String get syFbPveFormat => 'Non formattato: formattalo e passalo';

  @override
  String syFbPveFormatLabel(String title) {
    return 'Tutto quello che c\'è sopra viene cancellato. Per andare avanti scrivi il suo nome: $title';
  }

  @override
  String syFbPveFormatQ(String title) {
    return 'Formattare il disco $title?';
  }

  @override
  String get syFbPveFormatYes => 'Formatta e passalo';

  @override
  String syFbPveGuess(String id) {
    return 'Questo container è il $id.';
  }

  @override
  String syFbPveHost(String name, String version) {
    return '$name: Proxmox $version.';
  }

  @override
  String get syFbPveLead =>
      'Se l\'host Proxmox è tra le tue macchine (Impostazioni › Macchine), Rasgeth può eseguire lì questi passi da solo. Prima te lo chiede, con tutti i comandi nella richiesta.';

  @override
  String get syFbPveLook => 'Cerca l\'host Proxmox';

  @override
  String get syFbPveNeedId => 'Scrivi prima il numero del container.';

  @override
  String get syFbPveNoDisks => 'Nessun disco rimovibile su quell\'host.';

  @override
  String syFbPveNone(String n) {
    return 'Nessuna delle tue $n macchine è un host Proxmox. Aggiungi l\'host in Impostazioni › Macchine (come root, con la chiave di Rasgeth), provalo, poi cerca di nuovo.';
  }

  @override
  String syFbPveQ(String host, String id, String title) {
    return 'Passare il disco $title di $host al container $id?';
  }

  @override
  String syFbPveRestart(String target) {
    return 'Fatto sull\'host. Se $target non compare entro un minuto, riavvia il container da Proxmox.';
  }

  @override
  String get syFbPveText =>
      'Rasgeth te lo chiede di nuovo tra le richieste, con i comandi esatti, prima di eseguire qualcosa sull\'host.';

  @override
  String get syFbPveTitle => 'Fallo tu';

  @override
  String get syFbPveYes => 'Chiedimelo con i comandi';

  @override
  String syFbRamFree(String gb) {
    return '$gb GB liberi adesso';
  }

  @override
  String syFbRamTotal(String gb) {
    return '$gb GB in tutto';
  }

  @override
  String get syFbRemovable => 'rimovibile';

  @override
  String get syFbRestore => 'Ripristina';

  @override
  String syFbRestoreQ(String when) {
    return 'Ripristinare la copia del $when?';
  }

  @override
  String get syFbRestoreText =>
      'Prima viene riletta, poi si aggiungono i progetti, gli agenti e le conversazioni che qui non ci sono. Qui non si cancella niente.';

  @override
  String get syFbRestoreYes => 'Ripristina';

  @override
  String get syFbRoleFull => 'Rasgeth completo';

  @override
  String get syFbRoleFullText => 'Agenti, progetti, chat e tutto il resto, su questa macchina.';

  @override
  String get syFbRoleNode => 'Nodo di un altro Rasgeth';

  @override
  String get syFbRoleNodeText => 'Questa macchina lavora per un Rasgeth che hai già.';

  @override
  String get syFbRoleSettingsLead => 'Puoi cambiarlo quando vuoi: prima chiede e dice cosa cambia.';

  @override
  String get syFbRoleTitle => 'Ruolo';

  @override
  String get syFbSat => 'Sab';

  @override
  String get syFbSmbAddress => 'Cartella condivisa';

  @override
  String get syFbSmbAddressHelp =>
      'Come la scrive Windows (\\\\nas\\backup\\Rasgeth) oppure smb://nas/backup/Rasgeth.';

  @override
  String get syFbSmbDomain => 'Dominio o gruppo di lavoro';

  @override
  String get syFbSmbDomainHelp => 'Solo se la tua rete lo chiede (spesso vuoto).';

  @override
  String get syFbSmbMissing =>
      'Le cartelle condivise hanno bisogno di smbclient, che questa installazione non ha (l\'immagine Docker e Rasgeth OS ce l\'hanno). Su Windows usa il campo cartella qui sopra con \\\\host\\condivisione.';

  @override
  String get syFbSmbPassword => 'Password';

  @override
  String get syFbSmbPasswordHelp => 'Va solo nel Portachiavi, mai in un file o in un log.';

  @override
  String get syFbSmbPasswordKept => 'È nel Portachiavi: lascia vuoto per tenerla.';

  @override
  String get syFbSmbUser => 'Utente';

  @override
  String get syFbSshAddKey => 'Aggiungi questa chiave';

  @override
  String syFbSshContainer(String name) {
    return 'In un container ($name) SSH entra nel container stesso, al suo indirizzo, con l\'utente redgiant.';
  }

  @override
  String get syFbSshKey => 'Chiave pubblica';

  @override
  String get syFbSshKeyHelp =>
      'Una riga che inizia con ssh-ed25519, ssh-rsa o ecdsa-sha2 (il file .pub).';

  @override
  String get syFbSshKeyPlaceholder => 'ssh-ed25519 AAAA… io@portatile';

  @override
  String syFbSshKeys(String n) {
    return '$n chiavi ammesse';
  }

  @override
  String get syFbSshNeedKey => 'Incolla prima una chiave pubblica, poi accendilo.';

  @override
  String get syFbSshOffHelp => 'Incolla qui sotto una chiave pubblica, poi accendilo.';

  @override
  String get syFbSshOn => 'SSH acceso';

  @override
  String get syFbSshQ =>
      'Per lavorare sulla macchina stessa da un terminale. Spento finché non lo accendi; solo chiavi, mai password.';

  @override
  String get syFbSshTitle => 'SSH';

  @override
  String get syFbSshWhy_no_helper =>
      'Questa installazione non ha l\'aiutante di sistema di Rasgeth OS: SSH lo gestisce il sistema che la ospita.';

  @override
  String get syFbSshWhy_not_installed => 'SSH (openssh-server) non è installato in questo sistema.';

  @override
  String syFbSshWhy_other(String why) {
    return 'Qui SSH non si può leggere: l\'aiutante di sistema ha risposto «$why».';
  }

  @override
  String get syFbSshWhy_timeout =>
      'L\'aiutante di sistema di Rasgeth OS ci ha messo troppo a rispondere: riprova tra poco.';

  @override
  String get syFbSshWhy_unreachable =>
      'L\'aiutante di sistema di Rasgeth OS non risponde (redgiant-helper.socket): ora SSH non si può leggere né cambiare. Di solito riavviare la macchina lo rimette a posto.';

  @override
  String get syFbSun => 'Dom';

  @override
  String get syFbSystemLead =>
      'La macchina su cui gira Rasgeth, il suo ruolo, dove stanno i dati e le copie, e SSH.';

  @override
  String get syFbSystemQ => 'Sistema';

  @override
  String get syFbSystemSection => 'Sistema';

  @override
  String get syFbThu => 'Gio';

  @override
  String get syFbToFullQ => 'Rendere di nuovo questo un Rasgeth completo?';

  @override
  String get syFbToFullText =>
      'Smette di lavorare per l\'altro Rasgeth; i suoi agenti, progetti e conversazioni tornano com\'erano.';

  @override
  String get syFbToFullYes => 'Rendilo completo';

  @override
  String get syFbToNodeQ => 'Trasformare questo Rasgeth in un nodo?';

  @override
  String get syFbToNodeText =>
      'Smetterà di essere un Rasgeth a sé quando sarà abbinato: agenti, progetti e conversazioni restano salvati, intatti, ma fermi finché non lo rendi di nuovo completo.';

  @override
  String get syFbToNodeYes => 'Rendilo un nodo';

  @override
  String get syFbTue => 'Mar';

  @override
  String get syFbUseDisk => 'Usa per le copie';

  @override
  String get syFbUseFolder => 'Usa questa cartella';

  @override
  String get syFbUsePlace => 'Usa per le copie';

  @override
  String get syFbUseShare => 'Usa questa cartella condivisa';

  @override
  String get syFbVirt => 'Gira su';

  @override
  String syFbVirtContainer(String name) {
    return 'un container ($name)';
  }

  @override
  String get syFbVirtNone => 'una macchina fisica';

  @override
  String syFbVirtVm(String name) {
    return 'una macchina virtuale ($name)';
  }

  @override
  String get syFbWed => 'Mer';

  @override
  String get syFbWeekly => 'Ogni settimana';

  @override
  String get syFbWhenTitle => 'Quando';

  @override
  String get syFbWhyFs => 'Formato non supportato';

  @override
  String get syFbWhyNoFs => 'Non formattato';

  @override
  String get syFbWhyNoUuid => 'Senza un identificativo';

  @override
  String get syFbWhyNotDisk => 'Non è un disco';

  @override
  String get syFbWhyNotRemovable => 'Non rimovibile';

  @override
  String get syFbWhySystem => 'Contiene il sistema';

  @override
  String get syFolder => 'Cartella';

  @override
  String get syGitGiteaAgain => 'La stessa password, di nuovo';

  @override
  String get syGitGiteaGuide => 'Apri «I tuoi servizi di casa»';

  @override
  String get syGitGiteaMismatch => 'Le due password sono diverse.';

  @override
  String get syInspector => 'Inspector';

  @override
  String get syJob_pihole => 'Avvio di Pi-hole';

  @override
  String get syJob_remote => 'Apro l\'accesso da fuori';

  @override
  String get syJob_step_account => 'Creo il tuo account';

  @override
  String get syJob_step_arrive => 'Aspetto la cartella';

  @override
  String get syJob_step_ask => 'Aspetto il tuo sì';

  @override
  String get syJob_step_conversations => 'Conversazioni';

  @override
  String get syJob_step_convert => 'Converto';

  @override
  String get syJob_step_copy => 'Copio i modelli';

  @override
  String get syJob_step_data => 'Progetti, agenti e impostazioni';

  @override
  String get syJob_step_download => 'Scarico il modello';

  @override
  String get syJob_step_draft => 'Con il modello piccolo';

  @override
  String get syJob_step_fetch => 'Porto qui la copia';

  @override
  String get syJob_step_files => 'I file dei progetti';

  @override
  String get syJob_step_gitea_image => 'Scarico Gitea (una volta sola)';

  @override
  String get syJob_step_gitea_start => 'Avvio Gitea';

  @override
  String get syJob_step_image => 'Scarico il motore (una volta sola)';

  @override
  String get syJob_step_image_download => 'Download';

  @override
  String get syJob_step_load => 'Carico il modello in memoria';

  @override
  String get syJob_step_look => 'Guardo l\'host';

  @override
  String get syJob_step_model_download => 'Il modello';

  @override
  String get syJob_step_model_prepare => 'Lo preparo per la pagina';

  @override
  String get syJob_step_move => 'Copio sul nuovo disco';

  @override
  String get syJob_step_ngram => 'Con gli n-gram';

  @override
  String get syJob_step_node_check => 'Controllo il video (SHA-256)';

  @override
  String syJob_step_node_copy(String node) {
    return 'Copio i file su $node';
  }

  @override
  String syJob_step_node_fetch(String node) {
    return 'Riporto il video da $node';
  }

  @override
  String syJob_step_node_ffmpeg(String node) {
    return 'Preparo ffmpeg su $node';
  }

  @override
  String get syJob_step_none => 'Il modello da solo';

  @override
  String get syJob_step_ocr_languages => 'Le lingue';

  @override
  String get syJob_step_ocr_program => 'Il programma';

  @override
  String get syJob_step_pihole_check => 'Controllo che risponda';

  @override
  String get syJob_step_pihole_image => 'Scarico Pi-hole (una volta sola)';

  @override
  String get syJob_step_pihole_start => 'Avvio Pi-hole';

  @override
  String get syJob_step_preload =>
      'Leggo il modello una volta, così il primo messaggio non aspetta il disco';

  @override
  String get syJob_step_remote_cert => 'Prendo il certificato da Let\'s Encrypt';

  @override
  String get syJob_step_remote_connect => 'Mi collego a Cloudflare';

  @override
  String get syJob_step_remote_https => 'Prendo l\'indirizzo sicuro (HTTPS)';

  @override
  String get syJob_step_remote_image => 'Scarico quello che serve (una volta sola)';

  @override
  String get syJob_step_remote_login => 'Aspetto che tu acceda a Tailscale';

  @override
  String get syJob_step_remote_start => 'Lo avvio';

  @override
  String get syJob_step_restore => 'Rimetto il motore com\'era';

  @override
  String get syJob_step_run => 'Eseguo i passi sull\'host';

  @override
  String get syJob_step_searxng_check => 'Controllo che risponda';

  @override
  String get syJob_step_searxng_image => 'Scarico SearXNG (una volta sola)';

  @override
  String get syJob_step_searxng_start => 'Lo avvio';

  @override
  String get syJob_step_start => 'Avvio il motore';

  @override
  String get syJob_step_switch => 'Avvio il modello su Windows';

  @override
  String get syJob_step_tool_download => 'Scarico';

  @override
  String get syJob_step_tool_unpack => 'Estraggo';

  @override
  String get syJob_step_try => 'Provo una risposta';

  @override
  String get syJob_step_tune => 'Misuro questo computer per scegliere la regolazione più veloce';

  @override
  String get syJob_step_verify => 'Rileggo il backup';

  @override
  String get syJob_step_video_derive => 'Preparo il file';

  @override
  String get syJob_step_video_probe => 'Leggo il file';

  @override
  String get syJob_step_video_render => 'Faccio il video con ffmpeg';

  @override
  String get syJob_step_video_save => 'Lo salvo nel progetto';

  @override
  String get syJob_step_video_silences => 'Cerco i silenzi';

  @override
  String get syJob_step_video_sound => 'Prendo il suono';

  @override
  String get syJob_step_video_transcribe => 'Scrivo le parole';

  @override
  String get syJob_step_video_wait => 'Aspetto il video prima di questo';

  @override
  String syKcImported(String n) {
    return '$n credenziali aggiunte al portachiavi.';
  }

  @override
  String get syKcPassphrase => 'Frase segreta';

  @override
  String get syKcPassphraseHelp =>
      'Almeno 8 caratteri. Tienila in un posto sicuro: non si può recuperare.';

  @override
  String get syLmRecommended => 'consigliato';

  @override
  String get syLoginCode => 'Codice dell\'app (6 cifre)';

  @override
  String get syMcAdd => 'Aggiungi';

  @override
  String get syMcAuthKey => 'Chiave';

  @override
  String get syMcAuthPassword => 'Password';

  @override
  String get syMcChangedNow => 'Adesso';

  @override
  String syMcChangedText(String name) {
    return 'Al posto di «$name» potrebbe esserci un altro computer. Non è partito niente e la connessione è stata rifiutata. Fidati della chiave nuova solo se sai perché è cambiata (sistema reinstallato, macchina sostituita).';
  }

  @override
  String get syMcChangedTitle => 'Pericolo: la macchina ha risposto con un\'altra chiave';

  @override
  String get syMcChangedWas => 'Fidata';

  @override
  String get syMcCopied => 'Copiata';

  @override
  String get syMcCopy => 'Copia';

  @override
  String get syMcCopyKey => 'Copia la chiave pubblica';

  @override
  String get syMcEdit => 'Modifica';

  @override
  String get syMcEditorLead =>
      'Dove si trova la macchina e chi entra. La chiave o la password vanno dritte nel portachiavi.';

  @override
  String get syMcEmpty =>
      'Ancora nessuna macchina. Aggiungine una: Rasgeth le prepara una chiave, tu ne copi la parte pubblica sulla macchina.';

  @override
  String get syMcFolder => 'Cartella di lavoro';

  @override
  String get syMcFolderHelp =>
      'Dove partono i comandi; cancellare fuori da qui ti chiede sempre. Un percorso completo (/srv/app, ~/app, o su Windows E:\\coding\\sito). Vuota per la cartella personale.';

  @override
  String get syMcFolderNone => 'la cartella personale (ogni cancellazione ti chiede)';

  @override
  String get syMcHost => 'Indirizzo';

  @override
  String get syMcHostHelp => 'Il suo nome o indirizzo IP in rete.';

  @override
  String get syMcHostKey => 'Chiave della macchina';

  @override
  String get syMcKeyGenerate => 'Crea una chiave nuova';

  @override
  String get syMcKeyGenerateHelp =>
      'Rasgeth crea una chiave ed25519: ne copierai la parte pubblica in ~/.ssh/authorized_keys sulla macchina.';

  @override
  String get syMcKeyKeep => 'Tieni la chiave';

  @override
  String get syMcKeyKeepHelp => 'La chiave nel portachiavi resta com\'è.';

  @override
  String get syMcKeyPaste => 'Incolla una chiave privata';

  @override
  String get syMcLead =>
      'Altri computer che i tuoi agenti raggiungono via SSH: un server, un Raspberry Pi, il computer dell\'ufficio. Chiavi e password restano nel portachiavi; gli agenti scelgono una macchina per nome e non le vedono mai.';

  @override
  String get syMcLogin => 'Accesso';

  @override
  String get syMcLoginGenerated => 'chiave fatta da Rasgeth, nel portachiavi';

  @override
  String get syMcLoginImported => 'la tua chiave, nel portachiavi';

  @override
  String get syMcLoginPassword => 'password nel portachiavi';

  @override
  String get syMcName => 'Nome';

  @override
  String get syMcNameHelp =>
      'Come la chiamano gli agenti: lettere, cifre, punto, trattino, senza spazi (web, pi, ufficio).';

  @override
  String get syMcNew => 'Aggiungi una macchina';

  @override
  String get syMcNewKey => 'Crea una chiave nuova';

  @override
  String get syMcNewKeyQ => 'Creare una chiave nuova per questa macchina?';

  @override
  String get syMcNewKeyText =>
      'La chiave vecchia smette di funzionare qui: copia la nuova chiave pubblica sulla macchina e togli quella vecchia.';

  @override
  String get syMcPassphrase => 'La sua frase segreta (se ne ha una)';

  @override
  String get syMcPassword => 'Password';

  @override
  String get syMcPasswordHelp =>
      'Resta nel portachiavi. Una chiave è più sicura: la password viaggia a ogni accesso.';

  @override
  String get syMcPasswordKept => 'La password nel portachiavi resta se non ne scrivi una nuova.';

  @override
  String get syMcPort => 'Porta';

  @override
  String get syMcPrivateKey => 'Chiave privata';

  @override
  String get syMcPrivateKeyHelp => 'OpenSSH o PEM. Va nel portachiavi e non si vede più.';

  @override
  String get syMcPrivateKeyPlaceholder => '-----BEGIN OPENSSH PRIVATE KEY-----';

  @override
  String get syMcProject => 'progetto';

  @override
  String get syMcPublicKey => 'Chiave pubblica';

  @override
  String get syMcPublicKeyHelp =>
      'Copiala in ~/.ssh/authorized_keys dell\'utente sulla macchina (una riga), poi prova la connessione.';

  @override
  String syMcRemoveQ(String name) {
    return 'Togliere «$name»?';
  }

  @override
  String get syMcRemoveText =>
      'La sua chiave o password esce dal portachiavi e gli agenti non possono più usarla. Togli anche la chiave pubblica dalla macchina.';

  @override
  String syMcReplaceQ(String name) {
    return 'Fidarsi della chiave nuova di «$name»?';
  }

  @override
  String get syMcReplaceText =>
      'Fallo solo se sai perché la chiave della macchina è cambiata: altrimenti qualcuno potrebbe leggere quello che Rasgeth manda.';

  @override
  String get syMcReplaceYes => 'Fidati della chiave nuova';

  @override
  String get syMcSafety =>
      'Quello che succede lì segue le stesse regole di qui: sudo, spegnere la macchina, installare programmi di sistema, cambiarne i file di sistema e cancellare fuori dalla sua cartella di lavoro ti chiedono sempre, anche con «Non chiedermi niente».';

  @override
  String get syMcSave => 'Salva';

  @override
  String get syMcSection => 'Macchine';

  @override
  String get syMcStateFailed => 'L\'ultima prova non è riuscita';

  @override
  String get syMcStateNew => 'Non ancora controllata';

  @override
  String get syMcStateTrusted => 'Chiave fidata';

  @override
  String get syMcTest => 'Prova la connessione';

  @override
  String get syMcTestAuth =>
      'La macchina ha rifiutato l\'accesso: la chiave pubblica è in ~/.ssh/authorized_keys (o la password è giusta)?';

  @override
  String syMcTestError(String message) {
    return 'Non è riuscito: $message';
  }

  @override
  String get syMcTestNoSecret =>
      'Nel portachiavi non c\'è né chiave né password per questa macchina: modificala e impostane una.';

  @override
  String syMcTestOk(String system) {
    return 'Collegata: $system';
  }

  @override
  String get syMcTestTimeout => 'La macchina non ha risposto in tempo.';

  @override
  String get syMcTestUnreachable =>
      'La macchina non si raggiunge: controlla l\'indirizzo e che sia accesa.';

  @override
  String get syMcTesting => 'Mi collego…';

  @override
  String get syMcTitle => 'Le tue macchine';

  @override
  String get syMcTofuHow =>
      'Per vederla sulla macchina: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub';

  @override
  String get syMcTofuText =>
      'Non è ancora partito niente. Se l\'impronta è quella della macchina, fidati: da ora Rasgeth si collega solo a una macchina con questa chiave.';

  @override
  String get syMcTofuTitle => 'Prima connessione: è la chiave della macchina?';

  @override
  String get syMcTrust => 'Fidati di questa chiave';

  @override
  String get syMcUser => 'Utente';

  @override
  String get syMcWho => 'Chi può usarla';

  @override
  String get syMcWhoAgents => 'Agenti';

  @override
  String get syMcWhoEveryone => 'Tutti gli agenti';

  @override
  String get syMcWhoEveryoneHelp => 'God, gli assistenti e gli agenti di ogni progetto.';

  @override
  String get syMcWhoLead => 'Gli agenti non scelti non la vedono nemmeno.';

  @override
  String get syMcWhoNoAgents => 'Non ci sono ancora agenti.';

  @override
  String get syMcWhoNobody => 'ancora nessuno';

  @override
  String get syMcWhoProjects => 'Tutti gli agenti di questi progetti';

  @override
  String get syNdAddButton => 'Mostra un codice di abbinamento';

  @override
  String get syNdAddLead =>
      'Sull\'altra macchina, al primo avvio (ruolo «Nodo di un altro Rasgeth») o nelle sue Impostazioni › Nodi, scrivi l\'indirizzo di questa macchina e il codice qui sotto.';

  @override
  String get syNdAddTitle => 'Aggiungi un nodo';

  @override
  String get syNdAddress => 'L\'indirizzo dell\'altro Rasgeth';

  @override
  String get syNdAddressPh => 'https://rasgeth.local oppure 192.168.1.10:3000';

  @override
  String get syNdAdmin => 'la usa e la gestisce';

  @override
  String syNdBackupDone(String name) {
    return 'Copiato sul nodo: $name';
  }

  @override
  String get syNdBackupNow => 'Copia ora';

  @override
  String get syNdBackupsOn => 'Copie';

  @override
  String get syNdCode => 'Codice di abbinamento';

  @override
  String syNdCodeAddress(String address) {
    return 'L\'indirizzo di questa macchina, come la raggiunge l\'altra (in rete locale, con Tailscale o un proxy): $address';
  }

  @override
  String syNdCodeExpires(String min) {
    return 'Vale una volta, ancora per $min minuti.';
  }

  @override
  String get syNdCodeField => 'Il suo codice';

  @override
  String get syNdCodePh => 'ABCD-EFGH';

  @override
  String get syNdCodeStop => 'Smetti di mostrarlo';

  @override
  String get syNdCommandsOn => 'Comandi';

  @override
  String get syNdConfirm => 'Coincidono: conferma';

  @override
  String get syNdConnecting => 'Si collega';

  @override
  String get syNdControl => 'Controllo';

  @override
  String get syNdControlLead =>
      'Mai implicito: una macchina ne comanda un\'altra solo con questo permesso, che la macchina comandata tiene e può togliere.';

  @override
  String syNdControlTitle(String name) {
    return 'Chi può comandare $name';
  }

  @override
  String get syNdController => 'Quale macchina';

  @override
  String syNdCpu(String n) {
    return '$n CPU';
  }

  @override
  String get syNdFingerprint => 'L\'impronta della sua chiave';

  @override
  String syNdFree(String n) {
    return '$n GB liberi';
  }

  @override
  String get syNdGive => 'Dai';

  @override
  String get syNdGrantsHere => 'Chi può comandare questa macchina';

  @override
  String get syNdGrantsLead =>
      'Solo queste macchine possono usare questa, ognuna con quello che le ha dato la persona. Toglierlo vale subito.';

  @override
  String get syNdHere => 'Qui';

  @override
  String get syNdJoinLead =>
      'Abbina questa macchina come nodo di un altro Rasgeth: su quello, Impostazioni › Nodi › «Aggiungi un nodo» mostra l\'indirizzo e un codice.';

  @override
  String get syNdJoinTitle => 'Lavora per un altro Rasgeth';

  @override
  String syNdLastSeen(String when) {
    return 'Vista l\'ultima volta $when';
  }

  @override
  String get syNdLead =>
      'Altre macchine Rasgeth che lavorano con questa: prestano comandi, modelli locali e spazio per progetti e copie di sicurezza. Chi può comandare chi si decide qui, macchina per macchina.';

  @override
  String syNdLoad(String n) {
    return 'carico $n%';
  }

  @override
  String syNdModels(String n) {
    return '$n modelli';
  }

  @override
  String get syNdName => 'Nome';

  @override
  String get syNdNameHelp => 'Come la chiamano le altre macchine e gli agenti.';

  @override
  String get syNdNoContainer => 'comandi solo per chi la gestisce';

  @override
  String get syNdNoContainerHelp =>
      'Lì non c\'è un contenitore (niente Docker): esegue comandi solo per una macchina che la gestisce, sulla macchina stessa. Con il solo «usare», solo file, spazio e modelli.';

  @override
  String get syNdNoNodes => 'Ancora nessun nodo.';

  @override
  String get syNdNoProjects => 'Ancora nessun progetto.';

  @override
  String get syNdNoRights => 'Senza permessi';

  @override
  String get syNdNoSandbox => 'niente comandi';

  @override
  String get syNdNodeName => 'Nome del nodo';

  @override
  String get syNdNodeNameHelp =>
      'Come la chiamate qui tu, gli agenti e le richieste. Vuoto: il nome che si dà da sola.';

  @override
  String get syNdNotReady =>
      'I nodi hanno bisogno del Portachiavi: la chiave di questa macchina sta solo lì. Aprilo in Impostazioni › Portachiavi.';

  @override
  String get syNdOffline => 'Non in linea';

  @override
  String get syNdOnline => 'In linea';

  @override
  String get syNdPair => 'Abbina';

  @override
  String get syNdPairing => 'Abbino…';

  @override
  String get syNdParent => 'Lavora per';

  @override
  String get syNdPending => 'In attesa del sì sull\'altra macchina';

  @override
  String syNdPendingFromNode(String name) {
    return '$name vuole diventare un nodo di questa macchina';
  }

  @override
  String syNdPendingFromPrincipal(String name) {
    return 'Questa macchina lavorerà per $name';
  }

  @override
  String get syNdPendingLead =>
      'Le due macchine mostrano le stesse sei cifre e l\'impronta l\'una dell\'altra. Se coincidono su tutti e due gli schermi, conferma su tutte e due: prima non si usa niente.';

  @override
  String get syNdPendingTitle => 'Confronta e conferma';

  @override
  String get syNdPlaces => 'Dove girano le cose';

  @override
  String get syNdPlacesLead =>
      'Per ogni progetto: di base resta tutto qui. Un nodo fissato per i comandi è dove va il node_run dei suoi agenti; uno per le copie tiene le copie dei suoi file.';

  @override
  String get syNdQ => 'Nodi';

  @override
  String syNdRam(String n) {
    return '$n GB di RAM';
  }

  @override
  String get syNdReason => 'Perché';

  @override
  String get syNdRefused => 'Rifiutata: la sua chiave è cambiata';

  @override
  String get syNdReject => 'Non coincidono';

  @override
  String get syNdRename => 'Rinomina';

  @override
  String syNdRenameQ(String name) {
    return 'Un nome per $name';
  }

  @override
  String get syNdRenderOn => 'Video';

  @override
  String get syNdRevoke => 'Togli';

  @override
  String syNdRevokeQ(String name) {
    return 'Togliere quello che $name può fare qui?';
  }

  @override
  String get syNdRightAdmin => 'Gestirla';

  @override
  String get syNdRightAdminHelp =>
      'Dare e togliere ad altre macchine il controllo di questa, e scrivere fuori dalla sandbox.';

  @override
  String get syNdRightUse => 'Usarla';

  @override
  String get syNdRightUseHelp =>
      'Far girare i comandi dei suoi agenti in una sandbox qui, usare i suoi modelli e tenere file qui.';

  @override
  String get syNdRights => 'Che cosa può fare';

  @override
  String syNdRightsTitle(String name) {
    return 'Che cosa può fare $name su questa macchina';
  }

  @override
  String get syNdSas => 'Le sei cifre';

  @override
  String get syNdSection => 'Nodi';

  @override
  String get syNdTheirFp => 'L\'impronta dell\'altra macchina';

  @override
  String get syNdThis => 'Questa macchina';

  @override
  String get syNdTree => 'L\'albero';

  @override
  String get syNdTreeLead =>
      'Questa macchina, i suoi nodi e i loro. Il controllo è a parte: è scritto sotto ogni macchina.';

  @override
  String get syNdUnpair => 'Scollega';

  @override
  String syNdUnpairQ(String name) {
    return 'Scollegare $name?';
  }

  @override
  String get syNdUnpairText =>
      'Le due macchine si dimenticano: se ne vanno collegamenti, permessi e collocazioni con lei. I suoi file restano dove sono. Per abbinarla di nuovo serve un codice nuovo.';

  @override
  String get syNdUse => 'la usa';

  @override
  String get syNdWho => 'Chi può comandarla';

  @override
  String get syNdWhoNobody => 'Nessuno oltre a lei';

  @override
  String get syOiAddress => 'L\'indirizzo di Rasgeth nella rete';

  @override
  String syOiAddressHelp(String port) {
    return 'Dove il proxy o la VPN trovano Rasgeth; la sua porta è $port.';
  }

  @override
  String get syOiAuthCaddy =>
      'Caddyfile con forward auth (Authelia), lasciando fuori i percorsi dell\'app';

  @override
  String get syOiAuthIf =>
      'Se lo vuoi comunque, lascia fuori /api/ e /ws: il forward auth protegge la pagina, la password di Rasgeth tutto il resto.';

  @override
  String get syOiAuthTitle => 'Authelia, Authentik o un altro forward auth davanti?';

  @override
  String get syOiAuthWhy =>
      'Meglio di no: Rasgeth ha già la sua password, con tentativi limitati e il codice facoltativo dell\'app di autenticazione, e un accesso davanti blocca l\'app, la riga di comando, gli agenti ACP, l\'estensione del browser e i webhook (Telegram, WhatsApp, automazioni), che entrano con i loro token.';

  @override
  String get syOiCaddy => 'Caddyfile: un sito tutto suo';

  @override
  String get syOiCaddyReload => 'Poi ricarica Caddy (caddy reload, o riavvia il suo container).';

  @override
  String syOiCaddyWildcard(String domain) {
    return 'Caddyfile: dentro un sito jolly che hai già (*.$domain)';
  }

  @override
  String get syOiCheck => 'Controlla che risponda';

  @override
  String get syOiCheckAnswers =>
      'Qualcosa risponde a questo indirizzo (il browser non lascia leggere chi): aprilo per vedere Rasgeth.';

  @override
  String syOiCheckGo(String url) {
    return 'Controlla $url da qui';
  }

  @override
  String syOiCheckLead(String lb, String rb) {
    return 'Da qualsiasi computer: Rasgeth risponde $lb\"ok\":true,…$rb.';
  }

  @override
  String get syOiCheckNo =>
      'Nessuna risposta da questo browser: controlla il nome nel DNS, il blocco del proxy e, da fuori, la VPN.';

  @override
  String get syOiCheckRedgiant => 'Rasgeth risponde a questo indirizzo.';

  @override
  String get syOiClose => 'Nascondi la guida';

  @override
  String get syOiCopied => 'Copiato';

  @override
  String get syOiCopy => 'Copia';

  @override
  String syOiDnsAdguard(String address, String domain) {
    return 'AdGuard Home: Filtri › Riscritture DNS: *.$domain o il nome singolo → $address.';
  }

  @override
  String get syOiDnsLead =>
      'Un nome al posto di un indirizzo: puntalo al proxy quando c\'è, altrimenti all\'indirizzo di Rasgeth.';

  @override
  String syOiDnsPihole(String address, String name) {
    return 'Pi-hole: Settings › Local DNS › DNS Records: $name → $address.';
  }

  @override
  String get syOiDnsRouter =>
      'Il router: la sua pagina «DNS statico», «nomi locali» o prenotazione DHCP (il nome cambia da router a router).';

  @override
  String get syOiDnsTs =>
      'Fuori casa con Tailscale: aggiungi il DNS di casa in DNS › Nameservers di Tailscale, limitato al tuo dominio, e gli stessi nomi funzionano anche fuori.';

  @override
  String syOiDnsWildcard(String domain) {
    return 'Pi-hole o dnsmasq, tutti i nomi di *.$domain insieme (un file in /etc/dnsmasq.d/)';
  }

  @override
  String syOiHomeAdguard(String address, String name) {
    return 'AdGuard Home: Filtri › Riscritture DNS: $name → $address.';
  }

  @override
  String get syOiHomeDnsmasq => 'dnsmasq (o un file in /etc/dnsmasq.d/ di Pi-hole)';

  @override
  String get syOiHomeHosts => 'I record di Pi-hole o /etc/hosts, a mano';

  @override
  String get syOiHomeLookup => 'Su Rasgeth OS, cosa risponde il suo DNS per il nome';

  @override
  String syOiHomePihole(String address, String name) {
    return 'Pi-hole: Settings › Local DNS › DNS Records: $name → $address.';
  }

  @override
  String syOiHomeRouter(String address, String name) {
    return 'Il router: la pagina «DNS statico» o «nomi locali»: $name → $address.';
  }

  @override
  String syOiHomeSeen(String dns) {
    return 'Rasgeth chiede i nomi a $dns.';
  }

  @override
  String get syOiHomeTitle => 'I tuoi servizi di casa (Gitea, NAS…) visti da Rasgeth';

  @override
  String get syOiHomeTs =>
      'Se il tuo Pi-hole risponde con indirizzi Tailscale (100.…), quelli funzionano solo per i dispositivi in Tailscale: aggiungi un record locale con l\'indirizzo della tua rete come sopra, oppure fai usare alla macchina di Rasgeth il router come DNS, con il nome lì.';

  @override
  String get syOiHomeV6 =>
      'Un router che risponde «non esiste» alla domanda IPv6 (AAAA) per i nomi aggiunti a mano: Rasgeth OS lo gestisce già; su altri sistemi con systemd-resolved serve Cache=no-negative in un file di /etc/systemd/resolved.conf.d/, altrimenti per un po\' il nome sembra non esistere.';

  @override
  String get syOiHomeWhat => 'Nel DNS che usa Rasgeth, dai al nome quell\'indirizzo locale:';

  @override
  String get syOiHomeWhich =>
      'Quale DNS usa Rasgeth: su Rasgeth OS lo mostra la console (o SSH) con il comando qui sotto, alla voce «Current DNS Server»; su un altro computer è il DNS di quel computer (impostazioni di rete, /etc/resolv.conf su Linux). «Prova un nome» chiede proprio al DNS che usa Rasgeth.';

  @override
  String get syOiHomeWhichCmd => 'Su Rasgeth OS, quale DNS usa';

  @override
  String get syOiHomeWhy =>
      'Rasgeth raggiunge il tuo Gitea, il NAS o gli altri servizi per nome, con il DNS della macchina su cui gira (spesso il router). Un nome che il telefono apre può lì essere sconosciuto, o portare a un indirizzo che Rasgeth non raggiunge: allora «Un Gitea che hai già» non riesce anche se il servizio funziona.';

  @override
  String get syOiLead =>
      'Un reverse proxy, una VPN, un DNS di casa: se raggiungi già le tue macchine così, Rasgeth ci va dietro come qualsiasi altro servizio. Qui ci sono i blocchi da copiare.';

  @override
  String get syOiName => 'Il nome di Rasgeth';

  @override
  String get syOiNameHelp => 'Il nome che aprirai, per esempio rasgeth.casa.example.com.';

  @override
  String syOiNpm1(String name) {
    return 'Hosts › Proxy Hosts › Add Proxy Host; Domain Names: $name.';
  }

  @override
  String syOiNpm2(String address, String port) {
    return 'Scheme http, Forward Hostname / IP $address, Forward Port $port.';
  }

  @override
  String get syOiNpm3 =>
      'Accendi «Websockets Support» (la pagina di Rasgeth vive su un WebSocket) e «Block Common Exploits».';

  @override
  String get syOiNpm4 =>
      'SSL: «Request a new SSL Certificate», «Force SSL», «HTTP/2 Support». Salva.';

  @override
  String get syOiOpen => 'Mostra la guida';

  @override
  String get syOiOtherVpn => 'WireGuard, ZeroTier e le altre';

  @override
  String syOiOtherVpnLead(String subnet) {
    return 'La stessa idea: con la rete di casa $subnet negli AllowedIPs del peer (WireGuard) o come rotta gestita (ZeroTier), Rasgeth si apre al suo indirizzo di casa.';
  }

  @override
  String get syOiPart => 'Cosa hai';

  @override
  String get syOiPartDns => 'DNS di casa';

  @override
  String get syOiPartHome => 'I tuoi servizi di casa';

  @override
  String get syOiPartProxy => 'Reverse proxy';

  @override
  String get syOiPartVpn => 'Tailscale o un\'altra VPN';

  @override
  String get syOiProbe => 'Prova un nome';

  @override
  String get syOiProbeBad => 'Questo non è un nome (per esempio git.home.example.com).';

  @override
  String syOiProbeDnsFailed(String name) {
    return 'Il DNS che usa Rasgeth non ha risposto per $name. Controlla che funzioni, poi riprova.';
  }

  @override
  String syOiProbeGo(String name) {
    return 'Prova $name';
  }

  @override
  String syOiProbeLead(String name) {
    return 'Rasgeth cerca il nome e apre https://$name da dove gira, come fa per il tuo Gitea. Della risposta non tiene e non mostra nulla, tranne il codice.';
  }

  @override
  String syOiProbeNotFound(String name) {
    return 'Il DNS che usa Rasgeth non conosce $name. Aggiungi lì il nome (router, Pi-hole o AdGuard) con l\'indirizzo locale del proxy, poi riprova.';
  }

  @override
  String syOiProbeOk(String address, String name, String status) {
    return 'Tutto a posto: qui $name è $address, e https://$name ha risposto (HTTP $status).';
  }

  @override
  String syOiProbeTailscale(String address, String name) {
    return 'Qui $name è $address: un indirizzo Tailscale, che Rasgeth non raggiunge. Nel DNS che usa Rasgeth, dai al nome l\'indirizzo locale del proxy.';
  }

  @override
  String syOiProbeTimeout(String address, String name) {
    return 'Qui $name è $address, ma non ha risposto in tempo: probabilmente un indirizzo che Rasgeth non raggiunge (un\'altra rete, una VPN).';
  }

  @override
  String syOiProbeTls(String address, String name) {
    return 'Qui $name è $address e risponde, ma con un certificato di cui Rasgeth non si fida (fatto a mano?). Dai al proxy un certificato di un\'autorità pubblica (Let\'s Encrypt).';
  }

  @override
  String syOiProbeUnreachable(String address, String name) {
    return 'Qui $name è $address, ma da Rasgeth nessuno risponde in https. Controlla che sia l\'indirizzo locale del proxy e che il proxy sia acceso.';
  }

  @override
  String get syOiProxyAddr => 'L\'indirizzo locale del proxy';

  @override
  String get syOiProxyAddrHelp =>
      'L\'indirizzo nella tua rete (192.168.…) del proxy davanti al servizio, o del servizio stesso. Non un indirizzo Tailscale (100.…): Rasgeth lo raggiunge solo se è anche lui in Tailscale.';

  @override
  String get syOiProxyLead =>
      'Il proxy può stare su un\'altra macchina: gli basta raggiungere l\'indirizzo di Rasgeth. Prende il certificato (HTTPS) e passa tutto, WebSocket compreso.';

  @override
  String syOiReachedAs(String host) {
    return 'Sei già raggiungibile come $host.';
  }

  @override
  String get syOiReachedName =>
      'Questa pagina è arrivata con un nome della tua rete: in casa funziona già; da fuori serve una delle strade qui sotto (per esempio Tailscale).';

  @override
  String get syOiReachedProxy =>
      'Questa pagina è arrivata attraverso un reverse proxy della tua rete: la guida qui sotto è già compilata con quello che Rasgeth ha visto.';

  @override
  String get syOiSaid =>
      'Hai detto che Rasgeth è già raggiungibile a modo tuo: non chiede più di configurare le sue strade.';

  @override
  String get syOiSaidUndo => 'Chiedimelo di nuovo';

  @override
  String syOiSaidUrl(String url) {
    return 'Hai detto che Rasgeth è già raggiungibile a $url: non chiede più di configurare le sue strade e i suoi link (Telegram…) usano quell\'indirizzo.';
  }

  @override
  String get syOiService => 'Il nome del servizio';

  @override
  String get syOiServiceHelp => 'Come lo apri, per esempio git.home.example.com.';

  @override
  String get syOiSkip => 'Salta: sono già raggiungibile';

  @override
  String get syOiSkipNote =>
      'Rasgeth smette di chiederti di configurare le sue strade (Tailscale, Cloudflare, il tuo dominio); restano qui se un giorno ne vuoi una.';

  @override
  String get syOiTitle => 'Hai già un\'infrastruttura';

  @override
  String get syOiTraefik => 'Traefik: file provider (configurazione dinamica)';

  @override
  String get syOiTraefikNote =>
      'Con le etichette di Docker invece: la stessa regola e l\'indirizzo come servizio con loadbalancer.server.url. Usa i nomi del tuo entry point e del tuo certificate resolver.';

  @override
  String get syOiTsHere => 'Tailscale sulla macchina di Rasgeth';

  @override
  String get syOiTsHereLead =>
      'Installa Tailscale sulla macchina ed entra (tailscale up): dai tuoi dispositivi della tailnet Rasgeth si apre a http://<macchina>:7600. Per l\'HTTPS con un certificato vero:';

  @override
  String syOiTsRunning(String name) {
    return 'Tailscale gira già qui come $name: dai tuoi dispositivi della tailnet Rasgeth si apre con quel nome. Per l\'HTTPS con un certificato vero:';
  }

  @override
  String get syOiTsServe => 'Sulla macchina';

  @override
  String get syOiTsSubnet => 'Tailscale come subnet router';

  @override
  String syOiTsSubnetLead(String subnet) {
    return 'Tailscale su un altro dispositivo di casa (il router, un Raspberry, la macchina del proxy) che condivide la rete $subnet:';
  }

  @override
  String syOiTsSubnetThen(String address, String port) {
    return 'Approva la rotta nella console di Tailscale (Machines › Edit route settings). Il telefono apre poi http://$address:$port da ovunque, e anche i nomi del tuo DNS di casa se lo aggiungi in DNS › Nameservers (limitato al tuo dominio).';
  }

  @override
  String get syOiWs =>
      'Rasgeth tiene viva la pagina con un WebSocket su /ws: Caddy e Traefik lo passano da soli; Nginx vuole gli header Upgrade (Websockets Support in Nginx Proxy Manager).';

  @override
  String get syOnline => 'collegato';

  @override
  String get syOpen => 'apri';

  @override
  String get syOsErr_bad_password => 'Una password Wi-Fi ha da 8 a 63 caratteri.';

  @override
  String get syOsErr_bad_ssid => 'Il nome di una rete ha da 1 a 32 caratteri.';

  @override
  String get syOsErr_busy => 'La macchina si sta già collegando a una rete: aspetta un momento.';

  @override
  String get syOsErr_cannot_https => 'L\'HTTPS non è gestito da questa installazione.';

  @override
  String get syOsErr_cannot_reboot => 'I riavvii non sono gestiti da questa installazione.';

  @override
  String get syOsErr_cannot_update => 'Gli aggiornamenti non sono gestiti da questa installazione.';

  @override
  String get syOsErr_cannot_wifi => 'Il Wi-Fi non è gestito da questa installazione.';

  @override
  String get syOsErr_clean_install => 'Questa versione chiede un\'installazione pulita.';

  @override
  String get syOsErr_connect_failed =>
      'La rete ha rifiutato il collegamento: controlla la password e riprova.';

  @override
  String get syOsErr_failed => 'Non ha funzionato. Riprova tra un momento.';

  @override
  String get syOsErr_https_failed => 'L\'HTTPS locale non è partito.';

  @override
  String get syOsErr_https_off => 'L\'HTTPS locale è spento: accendilo prima.';

  @override
  String get syOsErr_manual => 'Questa installazione non si aggiorna da sola.';

  @override
  String get syOsErr_no_wifi => 'Questa macchina non ha una scheda Wi-Fi.';

  @override
  String get syOsErr_not_found => 'Quella rete adesso non è a portata.';

  @override
  String get syOsErr_not_installed => 'Questo sistema non può farlo.';

  @override
  String get syOsErr_not_trusted => 'Questo dispositivo non si fida ancora del certificato.';

  @override
  String get syOsErr_reboot_failed => 'Non sono riuscito a programmare il riavvio.';

  @override
  String get syOsErr_start_failed => 'L\'aggiornamento non è partito.';

  @override
  String get syOsErr_timeout => 'La macchina ci ha messo troppo a rispondere.';

  @override
  String get syOsErr_tls_failed => 'Non sono riuscito a fare il certificato.';

  @override
  String get syOsErr_unreachable => 'L\'aiutante della macchina non ha risposto.';

  @override
  String get syOsErr_wifi_off => 'Il Wi-Fi non è attivo su questa macchina.';

  @override
  String get syOsHttpsAddress => 'Indirizzo';

  @override
  String get syOsHttpsCheck => 'Prova questo dispositivo';

  @override
  String get syOsHttpsDevice => 'Il tuo dispositivo';

  @override
  String get syOsHttpsDownload => 'Scarica il certificato';

  @override
  String get syOsHttpsFingerprint => 'Impronta del certificato (SHA-256)';

  @override
  String get syOsHttpsFirefox =>
      'Firefox su qualsiasi sistema: Impostazioni › Privacy e sicurezza › Certificati › Mostra certificati › Autorità › Importa, spunta «Considera attendibile questa CA per l\'identificazione di siti web».';

  @override
  String get syOsHttpsHow_android =>
      'Impostazioni › Sicurezza (o Sicurezza e privacy) › Altro › Crittografia e credenziali › Installa un certificato › Certificato CA: «Installa comunque», scegli Rasgeth-CA.crt.';

  @override
  String get syOsHttpsHow_iphone =>
      'Apri il file scaricato in Safari, «Consenti». Impostazioni › Generali › VPN e gestione dispositivi: installa il profilo. Poi Impostazioni › Generali › Info › Impostazioni certificati attendibili: attiva «Rasgeth on …».';

  @override
  String get syOsHttpsHow_linux =>
      'Debian/Ubuntu: sudo cp Rasgeth-CA.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates. Chrome e Firefox hanno un elenco loro: aggiungilo nelle impostazioni dei certificati del browser (Autorità, «Importa»).';

  @override
  String get syOsHttpsHow_mac =>
      'Apri Rasgeth-CA.crt: Accesso Portachiavi lo aggiunge. Fai doppio clic su «Rasgeth on …» nel portachiavi «login», apri «Attendibilità», metti «Quando si utilizza questo certificato» su «Fidati sempre», chiudi e scrivi la tua password.';

  @override
  String get syOsHttpsHow_windows =>
      'Apri Rasgeth-CA.crt, «Installa certificato…», «Utente corrente», «Colloca tutti i certificati nel seguente archivio», «Autorità di certificazione radice attendibili», Fine, Sì. Riavvia il browser.';

  @override
  String syOsHttpsInFront(String name) {
    return 'Arrivi già a Rasgeth in HTTPS attraverso $name: per quell\'indirizzo il certificato locale non serve.';
  }

  @override
  String get syOsHttpsLocal => 'HTTPS nella rete locale';

  @override
  String get syOsHttpsLocalOff =>
      'Spento: Rasgeth risponde solo in http (o attraverso l\'HTTPS che hai messo tu).';

  @override
  String syOsHttpsLocalOn(String name) {
    return 'https://$name e gli indirizzi della macchina rispondono con un certificato di questa macchina. http continua a funzionare finché non dici che è fidato.';
  }

  @override
  String get syOsHttpsNotYet =>
      'Questo dispositivo non si fida ancora del certificato (o https://… non risponde): non è cambiato niente, http continua a funzionare.';

  @override
  String get syOsHttpsNowOnly =>
      'Questo dispositivo si fida. Da ora http passa a https per il nome locale e gli indirizzi della macchina.';

  @override
  String get syOsHttpsOffQ => 'Spegnere l\'HTTPS locale?';

  @override
  String get syOsHttpsOffText =>
      'I browser che sono già passati da https://rasgeth.local continuano a chiedere https per al massimo 30 giorni: lì apri la macchina con il suo indirizzo (http://192.168…:7600) fino ad allora.';

  @override
  String get syOsHttpsOffYes => 'Spegni';

  @override
  String get syOsHttpsQ => 'Vuoi il lucchetto del browser anche nella rete di casa?';

  @override
  String get syOsHttpsQr => 'Codice QR per scaricare il certificato';

  @override
  String get syOsHttpsQrHelp =>
      'Da un telefono sulla stessa rete, inquadra il codice per scaricarlo.';

  @override
  String get syOsHttpsRedirect => 'Manda sempre a HTTPS';

  @override
  String get syOsHttpsRedirectOn =>
      'Le richieste http nella tua rete passano a https; i browser se lo ricordano (HSTS, 30 giorni). I dispositivi senza certificato mostrano un avviso: installalo anche lì.';

  @override
  String get syOsHttpsTitle => 'HTTPS nella tua rete';

  @override
  String get syOsHttpsTrustLead =>
      'Scaricalo sul dispositivo (dal telefono: inquadra il codice), installalo come scritto qui sotto, poi premi «Prova questo dispositivo». Il certificato vale solo per i nomi e gli indirizzi locali di questa macchina, mai per un sito qualsiasi.';

  @override
  String get syOsHttpsTrustTitle => 'Fidati del certificato su ogni dispositivo';

  @override
  String get syOsHttpsUntil => 'Il certificato della macchina si rinnova da solo prima del';

  @override
  String get syOsNetSub => 'Rete';

  @override
  String get syOsNetSubLead =>
      'Come la macchina si collega alla rete, e l\'HTTPS per le pagine della rete di casa.';

  @override
  String get syOsRebootNow => 'Riavvia ora';

  @override
  String get syOsRebootQ => 'Riavviare la macchina adesso?';

  @override
  String get syOsRebootText =>
      'Rasgeth si ferma per due o tre minuti mentre la macchina riparte; gli agenti al lavoro vengono interrotti e riprendono da quello che era salvato. La pagina torna da sola.';

  @override
  String get syOsRebootYes => 'Riavvia';

  @override
  String get syOsRebooting => 'La macchina si riavvia tra pochi secondi. La pagina torna da sola.';

  @override
  String get syOsSecLast => 'L\'ultima volta';

  @override
  String syOsSecLastAt(String when) {
    return '$when';
  }

  @override
  String syOsSecLastN(String n, String when) {
    return '$when, $n pacchetti';
  }

  @override
  String get syOsSecNever => 'Non ancora (gira una volta al giorno)';

  @override
  String get syOsSecNoReboot => 'Niente aspetta un riavvio.';

  @override
  String get syOsSecQ =>
      'Il sistema installa da solo gli aggiornamenti di sicurezza di Debian, ogni giorno.';

  @override
  String get syOsSecReboot => 'Un aggiornamento chiede un riavvio per finire';

  @override
  String get syOsSecTitle => 'Aggiornamenti di sicurezza del sistema';

  @override
  String syOsUpdApply(String version) {
    return 'Aggiorna alla $version';
  }

  @override
  String syOsUpdApplyQ(String version) {
    return 'Aggiornare Rasgeth alla $version?';
  }

  @override
  String get syOsUpdApplyText =>
      'La macchina scarica la versione nuova mentre questa continua a funzionare, poi riavvia Rasgeth: la pagina si ferma per qualche minuto e torna da sola. Non si perde niente, e se la versione nuova non parte torna quella di prima.';

  @override
  String get syOsUpdApplyYes => 'Aggiorna ora';

  @override
  String get syOsUpdBreaking =>
      'Questa versione non si installa sopra quella di adesso: Rasgeth ti guida (backup su un disco USB, reinstalli Rasgeth OS, ripristini).';

  @override
  String get syOsUpdChecked => 'Ultimo controllo';

  @override
  String get syOsUpdInstalled => 'Installato';

  @override
  String get syOsUpdQ => 'Rasgeth è aggiornato su questa macchina?';

  @override
  String get syOsUpdState => 'Stato';

  @override
  String get syOsUpdSub => 'Aggiornamenti';

  @override
  String get syOsUpdSubLead => 'Rasgeth e il sistema su cui gira, sempre aggiornati.';

  @override
  String get syOsUpdTitle => 'Rasgeth';

  @override
  String syOsUpd_applying(String version) {
    return 'Aggiorno alla $version';
  }

  @override
  String syOsUpd_available(String version) {
    return 'Rasgeth $version è pronto da installare';
  }

  @override
  String syOsUpd_breaking(String version) {
    return 'Rasgeth $version chiede un\'installazione pulita';
  }

  @override
  String get syOsUpd_error => 'L\'ultimo aggiornamento non è finito (gira la versione di prima)';

  @override
  String get syOsUpd_latest => 'Aggiornato';

  @override
  String get syOsUpd_unknown => 'Non ancora controllato';

  @override
  String get syOsUpd_unreachable => 'Non riesco a raggiungere GitHub per controllare';

  @override
  String syOsUpd_unsigned(String version) {
    return 'È uscito Rasgeth $version, ma ancora senza il pacchetto firmato per Rasgeth OS: arriva con un rilascio successivo';
  }

  @override
  String get syOsWifi8021x => 'rete aziendale (non da qui)';

  @override
  String syOsWifiConnectedTo(String ip, String name) {
    return 'Collegata a «$name» ($ip)';
  }

  @override
  String get syOsWifiForget => 'Dimentica';

  @override
  String syOsWifiForgetQ(String name) {
    return 'Dimenticare «$name»?';
  }

  @override
  String get syOsWifiForgetText =>
      'La macchina smette di collegarsi a questa rete e la sua password viene cancellata. Se è la rete in uso e non c\'è un cavo, la pagina smette di rispondere finché la macchina non ha un\'altra rete.';

  @override
  String get syOsWifiGood => 'segnale buono';

  @override
  String get syOsWifiHidden => 'Rete nascosta…';

  @override
  String get syOsWifiHiddenName => 'Il nome della rete';

  @override
  String get syOsWifiInReach => 'Reti a portata';

  @override
  String get syOsWifiInUse => 'in uso';

  @override
  String get syOsWifiJoin => 'Collegati';

  @override
  String syOsWifiJoined(String name) {
    return 'Collegata a «$name». Se stai usando questa pagina attraverso quella rete, continua a funzionare.';
  }

  @override
  String get syOsWifiJoining => 'Mi collego…';

  @override
  String get syOsWifiKnown => 'salvata';

  @override
  String syOsWifiKnownAway(String names) {
    return 'Salvate, ora non a portata: $names';
  }

  @override
  String get syOsWifiLooking => 'Cerco…';

  @override
  String get syOsWifiNone =>
      'Nessuna rete trovata. Cerca di nuovo, o collegati a una rete nascosta con il suo nome.';

  @override
  String get syOsWifiNotConnected => 'Non collegata a una rete Wi-Fi';

  @override
  String get syOsWifiNow => 'Adesso';

  @override
  String syOsWifiPassword(String name) {
    return 'Password di «$name»';
  }

  @override
  String get syOsWifiPasswordHelp =>
      'Da 8 a 63 caratteri. Resta solo sulla macchina, leggibile solo dal sistema; Rasgeth non la conserva e non la mostra mai.';

  @override
  String get syOsWifiQ => 'A quale rete senza fili si collega la macchina?';

  @override
  String syOsWifiSaved(String name) {
    return '«$name» è salvata: la macchina si collega appena la rete è a portata.';
  }

  @override
  String get syOsWifiScan => 'Cerca di nuovo';

  @override
  String get syOsWifiStrong => 'segnale forte';

  @override
  String get syOsWifiTitle => 'Wi-Fi';

  @override
  String get syOsWifiWeak => 'segnale debole';

  @override
  String get syOsWifiWhy_failed => 'Non riesco a leggere il Wi-Fi adesso. Riprova tra un momento.';

  @override
  String get syOsWifiWhy_no_helper => 'Il Wi-Fi lo gestisce il sistema di questa macchina.';

  @override
  String get syOsWifiWhy_no_wifi =>
      'Questa macchina non ha una scheda Wi-Fi (o il sistema non la riconosce).';

  @override
  String get syOsWifiWhy_not_installed => 'Questo sistema non ha gli strumenti per il Wi-Fi.';

  @override
  String get syOsWifiWhy_wifi_off =>
      'Il Wi-Fi non è attivo su questa macchina. Riavviala, o collega un cavo.';

  @override
  String get syOsWifiWired =>
      'C\'è un cavo collegato: la macchina usa il cavo, il Wi-Fi resta di riserva.';

  @override
  String get syPiholeAdmin => 'La pagina di Pi-hole, per vedere cosa blocca e sbloccare un sito:';

  @override
  String get syPiholeAds => 'Sul blocco della pubblicità';

  @override
  String get syPiholeAdsText =>
      'Pi-hole blocca i nomi dei servizi di pubblicità e tracciamento più noti, per ogni dispositivo che lo usa, telefoni e TV compresi. Ogni tanto un sito o un\'app ha bisogno di uno di quei nomi per funzionare (certi link dei negozi, certe app di streaming): allora sembra rotto.';

  @override
  String get syPiholeAllow =>
      'Se un sito smette di funzionare: apri la pagina di Pi-hole, Query Log, trova il nome bloccato e premi Allow. Per sospendere tutto il blocco per qualche minuto usa Disable blocking nella stessa pagina.';

  @override
  String syPiholeAnswers(String domain, String ip) {
    return 'In casa $domain ora porta a $ip.';
  }

  @override
  String get syPiholeChanges => 'Cosa cambia in casa, e come tornare indietro';

  @override
  String get syPiholeDevice =>
      'Se il router non permette di cambiare il DNS (alcuni router dei fornitori no), impostalo su ogni dispositivo: nei dettagli della rete Wi-Fi sui telefoni, nelle impostazioni della scheda di rete sui computer.';

  @override
  String get syPiholeDomain => 'Il tuo dominio (facoltativo)';

  @override
  String get syPiholeDomainHelp =>
      'L\'indirizzo che usi da fuori, tipo rasgeth.tuodominio.it: Pi-hole risponde per quello con l\'indirizzo qui sopra. Lascialo vuoto per usare Pi-hole solo contro la pubblicità.';

  @override
  String get syPiholeDomainWrong => 'Deve essere un nome tipo rasgeth.tuodominio.it.';

  @override
  String get syPiholeIp => 'L\'indirizzo di casa di questo computer';

  @override
  String get syPiholeIpHelp =>
      'Quattro numeri tipo 192.168.1.50. Lo trovi nella pagina del router tra i dispositivi collegati, oppure su questo computer: \"ip a\" su Linux, \"ipconfig\" su Windows, Impostazioni di Sistema, Rete su Mac. Meglio se il router dà sempre lo stesso indirizzo a questo computer (prenotazione dell\'indirizzo).';

  @override
  String get syPiholeIpWrong =>
      'Devono essere quattro numeri da 0 a 255 separati da punti, tipo 192.168.1.50.';

  @override
  String get syPiholeNeed =>
      'raggiungi Rasgeth da fuori con un tuo dominio, e in casa lo stesso link non si apre. Molti router non sanno rimandarti a casa tua passando da internet (la funzione si chiama NAT loopback o hairpin, e il loro non ce l\'ha).';

  @override
  String get syPiholeNeedTitle => 'Ti serve se';

  @override
  String get syPiholeNoNeed =>
      'usi Tailscale o Cloudflare Tunnel: quei link funzionano uguale in casa e fuori. Puoi comunque accenderlo solo per bloccare la pubblicità, se ti va.';

  @override
  String get syPiholeNoNeedTitle => 'Non ti serve se';

  @override
  String syPiholeNowRouter(String ip) {
    return 'Ultimo passo, tocca a te: sul router (o su ogni dispositivo) metti come server DNS $ip. Finché non lo fai, in casa nessuno usa Pi-hole.';
  }

  @override
  String get syPiholeOff =>
      'Per tornare indietro: rimetti il DNS del router com\'era (spesso \"automatico\") e spegni Pi-hole da qui. Sui tuoi computer non cambia nient\'altro.';

  @override
  String syPiholeOn(String ip) {
    return 'Pi-hole è acceso, su $ip.';
  }

  @override
  String get syPiholeOpenAdmin => 'Apri Pi-hole';

  @override
  String get syPiholePort => 'Dettagli tecnici: la porta 53';

  @override
  String get syPiholePortText =>
      'Pi-hole risponde sulla porta 53 (quella del DNS) solo all\'indirizzo di casa di questo computer, non su internet, e la sua pagina sta sulla porta 8053. Se su questo computer qualcos\'altro risponde già sulla porta 53 (un altro DNS, o quello del sistema su alcuni Linux), Pi-hole non può partire: Rasgeth te lo dice e non cambia niente.';

  @override
  String get syPiholeRouter =>
      'Per tutti i dispositivi insieme: apri la pagina del router (l\'indirizzo di solito è scritto sotto il router, tipo 192.168.1.1), cerca le impostazioni DHCP o LAN e metti come server DNS l\'indirizzo di casa di questo computer. I dispositivi lo prendono la prossima volta che si collegano (oppure riavviali).';

  @override
  String get syPiholeSecond =>
      'Un secondo DNS: se questo computer è spento, i dispositivi che conoscono solo Pi-hole non aprono nessun sito. Come secondo DNS puoi mettere l\'indirizzo del router o uno pubblico (1.1.1.1): tutto continua a funzionare a computer spento, ma a volte i dispositivi chiedono al secondo e allora vedono la pubblicità, o in casa non trovano il tuo dominio.';

  @override
  String get syPiholeShowPassword => 'Mostra la sua password';

  @override
  String get syPiholeStart => 'Accendi Pi-hole';

  @override
  String get syPiholeStop => 'Spegni Pi-hole';

  @override
  String get syPiholeTest =>
      'Come capirlo: collega il telefono al Wi-Fi di casa e apri il link di Rasgeth. Se si apre, Pi-hole per questo non ti serve (puoi volerlo lo stesso per bloccare la pubblicità). Se non si apre, ma con i dati del telefono sì, Pi-hole lo risolve.';

  @override
  String get syPiholeTitle => 'Il DNS di casa, con Pi-hole (facoltativo)';

  @override
  String get syPiholeWhat =>
      'Ogni dispositivo di casa chiede a un server DNS quale numero sta dietro a un nome (per esempio rasgeth.tuodominio.it). Di solito risponde il router o il tuo fornitore di internet. Pi-hole è un piccolo DNS che Rasgeth può far girare su questo computer: per il tuo dominio risponde con l\'indirizzo di casa di questo computer, così il link funziona anche in casa, e in più blocca pubblicità e tracciamento per ogni dispositivo che lo usa.';

  @override
  String get syPwSignOutOthersQ => 'Scollegare anche gli altri dispositivi?';

  @override
  String get syPwSignOutOthersText =>
      'Gli altri browser e le app collegate con la password vecchia restano dentro se li tieni. Scollegali se l\'hai cambiata perché qualcun altro potrebbe conoscerla.';

  @override
  String get syPwSignOutOthersYes => 'Scollegali';

  @override
  String get syRemoteCaddy =>
      'Per esperti: il tuo dominio che punta a casa, porte 80 e 443 aperte sul router. Chiunque su internet raggiunge la pagina di accesso.';

  @override
  String get syRemoteCloudflare =>
      'Un indirizzo sul tuo dominio (circa 10 euro l\'anno), niente da aprire sul router. Qualche passo in più sul sito di Cloudflare.';

  @override
  String get syRemoteCode => 'Seconda verifica (consigliata)';

  @override
  String get syRemoteCodeConfirm => 'Conferma';

  @override
  String get syRemoteCodeHint =>
      'Oltre alla password, un codice di 6 cifre da un\'app sul telefono (Google Authenticator, Microsoft Authenticator, 2FAS…): chi scopre la password non entra lo stesso.';

  @override
  String get syRemoteCodeOff => 'Seconda verifica spenta.';

  @override
  String get syRemoteCodeOn => 'Seconda verifica attiva';

  @override
  String get syRemoteCodeQr => 'Inquadra con l\'app di autenticazione';

  @override
  String get syRemoteCodeScan =>
      'Inquadra il codice con l\'app (oppure scrivici la chiave qui sotto), poi scrivi qui le 6 cifre che ti mostra.';

  @override
  String get syRemoteCodeStart => 'Attiva la seconda verifica';

  @override
  String get syRemoteConnect => 'Collega';

  @override
  String get syRemoteHow => 'Come raggiungerlo';

  @override
  String get syRemoteNeedsPassword => 'Prima imposta la password qui sopra.';

  @override
  String get syRemoteNewPassword => 'Nuova password';

  @override
  String get syRemoteOff => 'Spegni l\'accesso da fuori';

  @override
  String get syRemoteOn => 'Rasgeth si raggiunge da fuori a questo indirizzo:';

  @override
  String get syRemoteOwnDomain => 'Il tuo dominio, router aperto';

  @override
  String get syRemotePassword => 'La tua password';

  @override
  String get syRemotePasswordChange => 'Cambiala';

  @override
  String get syRemotePasswordHint =>
      'Da fuori Rasgeth chiede questa password (il link con il token resta per questo computer). Scegline una che non usi da nessun\'altra parte.';

  @override
  String get syRemotePasswordRule =>
      'Almeno 10 caratteri. Una frase breve è facile da ricordare e difficile da indovinare.';

  @override
  String get syRemotePasswordSaved => 'Password salvata.';

  @override
  String get syRemotePasswordSet => 'La password è impostata';

  @override
  String get syRemotePurpose =>
      'Usa Rasgeth dal telefono o da un altro computer quando sei fuori. Prima una password, poi una di tre strade; niente è raggiungibile da fuori finché non hai finito. Facoltativo.';

  @override
  String get syRemoteSessions => 'Browser collegati';

  @override
  String get syRemoteSessionsHint =>
      'Ogni accesso dura 30 giorni. Se hai perso un telefono, o pensi che qualcun altro sia entrato (si scollegano anche le app di Rasgeth):';

  @override
  String get syRemoteSignOutAll => 'Scollega tutti';

  @override
  String get syRemoteSignedOut => 'Scollegati tutti.';

  @override
  String get syRemoteTailscale =>
      'Una rete privata fra i tuoi dispositivi: niente da aprire sul router, gratis per uso personale. Installi Tailscale anche sul telefono.';

  @override
  String get syRemoteWaysFolded => 'Le strade di Rasgeth';

  @override
  String get syRemove => 'Rimuovi';

  @override
  String get sySave => 'Salva';

  @override
  String get sySaved => 'Salvato';

  @override
  String get sySbBackupQ => 'Tutto Rasgeth in un file';

  @override
  String get sySettings => 'Impostazioni';

  @override
  String get sySnCable => 'Uso il cavo';

  @override
  String sySnCableDone(String address) {
    return 'Il cavo funziona: Rasgeth è a $address. Collega questo dispositivo alla rete di casa e apri http://$address:7600 (oppure http://rasgeth.local:7600).';
  }

  @override
  String sySnFailed(String name, String why) {
    return 'Rasgeth non è riuscito a collegarsi a «$name»: $why';
  }

  @override
  String get sySnHidden => 'Una rete nascosta';

  @override
  String get sySnHiddenName => 'Nome della rete';

  @override
  String get sySnJoin => 'Usa questa rete';

  @override
  String sySnMaintQ(String ssid) {
    return 'Rasgeth non trovava più la rete di casa e ha riaperto $ssid: scegli la rete che deve usare.';
  }

  @override
  String get sySnNone =>
      'Intorno non si vede nessuna rete: usa il cavo, oppure scrivi il nome di una rete nascosta.';

  @override
  String sySnPassword(String name) {
    return 'Password di «$name»';
  }

  @override
  String sySnQ(String ssid) {
    return 'Sei collegato a $ssid, la rete temporanea di Rasgeth: quale rete deve usare Rasgeth a casa?';
  }

  @override
  String get sySnTitle => 'La rete di casa';

  @override
  String sySnTrying(String name, String ssid) {
    return 'Rasgeth si collega a «$name»: questa rete temporanea adesso si chiude. Collega questo dispositivo alla rete di casa e apri http://rasgeth.local:7600. Se non funziona, $ssid torna fra un minuto con il motivo.';
  }

  @override
  String get syStRemoteQ => 'Rasgeth anche fuori casa';

  @override
  String get syStopped => 'fermato';

  @override
  String get syTgQr => 'Inquadra con la fotocamera del telefono';

  @override
  String get syTsApps => 'App di Tailscale';

  @override
  String get syTsDns => 'Impostazioni DNS di Tailscale';

  @override
  String get syTsOpenSignIn => 'Apri la pagina di accesso di Tailscale';

  @override
  String get syTsSignIn => 'Tailscale vuole che tu acceda, per aggiungere Rasgeth alla tua rete:';

  @override
  String get syTsSignUp => 'Iscriviti a Tailscale';

  @override
  String get syTsStep1 =>
      'Crea un account gratuito su Tailscale (va bene con Google, Microsoft o GitHub):';

  @override
  String get syTsStep2 =>
      'Nella pagina DNS di Tailscale attiva MagicDNS e HTTPS Certificates (danno a Rasgeth un indirizzo sicuro):';

  @override
  String get syTsStep3 => 'Poi qui:';

  @override
  String get syTsStep4 =>
      'Installa Tailscale sul telefono e sugli altri computer, con lo stesso account:';

  @override
  String get syUiAdvanced => 'Avanzate';

  @override
  String get syUiDone => 'Fatto.';

  @override
  String get syUiNotNeeded => 'non serve';

  @override
  String syUpdBrkChecked(String conversations, String file, String projects, String size) {
    return '$file · $size · $projects progetti, $conversations conversazioni, memorie e impostazioni';
  }

  @override
  String get syUpdBrkDockerCopy =>
      'La cartella sta nel volume dei dati di Rasgeth, che l\'installazione pulita cancella: copia prima il file fuori, dalla cartella di Rasgeth:';

  @override
  String get syUpdBrkDone => 'Ho capito';

  @override
  String syUpdBrkKeys(String n) {
    return 'Il tuo portachiavi ($n chiavi, anche quelle dei modelli, delle chat e delle caselle) non è nel backup: ci entra solo protetto da una frase tua.';
  }

  @override
  String get syUpdBrkKeysAdd => 'Aggiungi anche il portachiavi';

  @override
  String get syUpdBrkKeysAgain => 'Rifai il backup con il portachiavi';

  @override
  String get syUpdBrkKeysIn => 'Nel backup c\'è anche il portachiavi, protetto dalla tua frase.';

  @override
  String syUpdBrkLead(String version) {
    return 'Rasgeth $version è cambiato troppo dentro per aggiornarsi come al solito: installato sopra quello vecchio potrebbe rompersi.';
  }

  @override
  String get syUpdBrkNext => 'Avanti';

  @override
  String get syUpdBrkRetry => 'Riprova il backup';

  @override
  String get syUpdBrkSaved => 'Backup fatto e riletto: è in questa cartella';

  @override
  String get syUpdBrkStep1 => 'Togli il Rasgeth vecchio';

  @override
  String get syUpdBrkStep1Docker => 'Nella cartella di Rasgeth togli i container e i loro volumi:';

  @override
  String get syUpdBrkStep1Mac =>
      'Dall\'icona nella barra dei menu scegli «Disinstalla…» (oppure trascina Rasgeth da Applicazioni nel Cestino).';

  @override
  String get syUpdBrkStep1Os =>
      'Copia il backup su un disco USB (Impostazioni › Sistema › Backup): reinstallare Rasgeth OS cancella il disco di questa macchina.';

  @override
  String get syUpdBrkStep1Source => 'Ferma Rasgeth e sposta altrove la sua cartella dei dati.';

  @override
  String get syUpdBrkStep1Win =>
      'Disinstalla Rasgeth. Quando chiede se tenere i dati puoi rispondere No: è tutto nel backup.';

  @override
  String syUpdBrkStep2(String version) {
    return 'Installa Rasgeth $version';
  }

  @override
  String get syUpdBrkStep3 => 'Ripristina';

  @override
  String get syUpdBrkStep3Docker =>
      'Apri Rasgeth, finisci la configurazione e importa il file copiato in Impostazioni › Backup › Importa un backup.';

  @override
  String get syUpdBrkStep3Os =>
      'Scrivi la nuova Rasgeth OS (chiavetta o immagine) e accendi la macchina: il primo avvio propone «Ripristina dal backup» e lo trova sul disco USB.';

  @override
  String get syUpdBrkStep3Text =>
      'Al primo avvio il nuovo Rasgeth propone «Ripristina dal backup»: lo trova da solo in quella cartella.';

  @override
  String syUpdBrkSub(String installed, String version) {
    return 'Rasgeth $version non si può installare sopra la $installed';
  }

  @override
  String syUpdBrkSure(String folder) {
    return 'Rasgeth si chiude e parte il suo disinstallatore. Il backup resta in $folder.';
  }

  @override
  String get syUpdBrkTitle => 'Questa versione richiede un\'installazione pulita';

  @override
  String get syUpdBrkUninstall => 'Disinstalla Rasgeth';

  @override
  String get syUpdBrkUninstallYes => 'Sì, disinstalla';

  @override
  String get syUpdBrkUninstalling => 'Il disinstallatore sta partendo sul desktop.';

  @override
  String get syUpdBrkWhy =>
      'Quindi si fa in tre passi brevi: prima un backup di tutto (lo sto facendo adesso, da solo), poi togli il Rasgeth vecchio e installi quello nuovo, che rimette tutto a posto dal backup.';

  @override
  String get syUpdCopied => 'Copiato';

  @override
  String get syUpdCopy => 'Copia';

  @override
  String get syUpdDownloadNew => 'Scarica la versione nuova';

  @override
  String get syUpdFoundDone =>
      'È tutto tornato. Vai avanti con i passi successivi per sistemare i modelli.';

  @override
  String get syUpdFoundKeys =>
      'La frase che hai scelto per il portachiavi. Senza, tutto il resto si ripristina lo stesso, e le chiavi dei modelli e delle chat si rimettono dalle loro pagine.';

  @override
  String syUpdFoundLead(String conversations, String date, String projects, String version) {
    return 'C\'è un backup del $date (Rasgeth $version): $projects progetti e $conversations conversazioni. Rimetto tutto a posto adesso?';
  }

  @override
  String get syUpdFoundRestore => 'Ripristina dal backup';

  @override
  String get syUpdFoundTitle => 'Ripristina dal backup';

  @override
  String get syUpdLater => 'Più tardi';

  @override
  String get syUpdLook => 'Cerca aggiornamenti';

  @override
  String get syUpdLooking => 'Cerco…';

  @override
  String get syUpdReqAgain => 'Controlla di nuovo';

  @override
  String get syUpdReqClose => 'Chiudi Rasgeth';

  @override
  String get syUpdReqClosing => 'Rasgeth si sta chiudendo. Puoi chiudere questa pagina.';

  @override
  String get syUpdReqDocker => 'Sul computer dove gira Rasgeth, nella sua cartella, esegui:';

  @override
  String get syUpdReqInstaller => 'Se l\'aggiornamento non parte, l\'installazione completa è qui:';

  @override
  String get syUpdReqInstallerLink => 'Rasgeth-Setup.exe';

  @override
  String syUpdReqLead(String installed, String version) {
    return 'Questo aggiornamento non può aspettare: Rasgeth $version sistema una cosa che la $installed non può continuare a fare in sicurezza.';
  }

  @override
  String get syUpdReqMac =>
      'Apri il file scaricato e trascina Rasgeth in Applicazioni, sostituendo quello vecchio; poi riaprilo.';

  @override
  String get syUpdReqNow => 'Aggiorna ora';

  @override
  String get syUpdReqSafe =>
      'Finché non aggiorni, agenti e automazioni restano fermi. Conversazioni, progetti e impostazioni sono al sicuro: non si perde niente.';

  @override
  String get syUpdReqSource =>
      'Porta il codice all\'ultima versione (git pull), ricompilalo e riavvia Rasgeth.';

  @override
  String syUpdReqSub(String installed, String version) {
    return 'Serve la versione $version (hai la $installed)';
  }

  @override
  String get syUpdReqTitle => 'È necessario aggiornare Rasgeth';

  @override
  String get syUpdReqUpdating =>
      'Rasgeth sta scaricando l\'aggiornamento: segui la finestra sul desktop. Si riavvia da solo.';

  @override
  String get syUpdReqUpdatingOs =>
      'Rasgeth OS sta aggiornando Rasgeth: la pagina si ferma per qualche minuto e torna da sola.';

  @override
  String get syWzBack => 'Indietro';

  @override
  String get syWzCpu => 'Processore';

  @override
  String get syWzFree => 'liberi';

  @override
  String get syWzGpu => 'Scheda video';

  @override
  String get syWzMemory => 'Memoria';

  @override
  String get syWzNoGpu => 'Nessuna';

  @override
  String get syWzRecommended => 'consigliata';

  @override
  String get syWzRemote => 'Accesso da fuori casa';

  @override
  String get syWzStorage => 'Dati e copie';

  @override
  String syWzThreads(String n) {
    return '$n thread';
  }

  @override
  String get syHubTitle => 'Sistema e accesso';

  @override
  String get syHubRemote =>
      'Password, secondo controllo, Tailscale, Cloudflare, il tuo dominio, Pi-hole';

  @override
  String get syHubSystem =>
      'La macchina, il ruolo, dati e backup, Wi-Fi, HTTPS, SSH, aggiornamenti';

  @override
  String get syHubMachines => 'I tuoi computer che gli agenti raggiungono via SSH';

  @override
  String get syHubNodes => 'Altre macchine che lavorano con questa';

  @override
  String get syHubBackup => 'Tutto in un file, e un file riportato qui';

  @override
  String get syGateOpen => 'Cosa fare';

  @override
  String get hfServiceTitle => 'Voce a mani libere accesa';

  @override
  String get hfServiceBody => 'Il microfono resta aperto per la conversazione a voce.';

  @override
  String get hfServiceChannel => 'Voce a mani libere';

  @override
  String get hfServiceChannelText =>
      'Si vede finché il microfono è aperto per la voce a mani libere.';

  @override
  String get hfPaused => 'In pausa: l\'app non è in primo piano';

  @override
  String get hfWakeNotHere =>
      'Su Mac, iPhone e iPad la parola di attivazione non si sente ancora: tocca l\'indicatore, poi «Parla ora».';

  @override
  String get hfWakeHelp =>
      'La tua parola di attivazione resta su questo dispositivo e si controlla con il modello vocale di Rasgeth.';

  @override
  String get hfLimitPrivacy =>
      'Quello che dici dopo «Parla ora» va a Rasgeth per essere trascritto; prima non si ascolta niente.';

  @override
  String get hfLimitAndroid =>
      'Su Android il microfono resta aperto anche a schermo spento o con un\'altra app davanti, con una notifica che lo dice.';

  @override
  String get hfLimitOthers =>
      'Su iPhone, iPad e sui computer ascolta finché l\'app è aperta; in secondo piano si mette in pausa e l\'indicatore lo dice.';

  @override
  String get hfReaderRow => 'Chi legge e a che volume';

  @override
  String get hfSttRow => 'Chi scrive quello che dici';

  @override
  String get hfSttNone => 'Ancora nessun servizio di trascrizione';

  @override
  String get hfPickConversation => 'Scegli la conversazione';

  @override
  String get hfNoRecent => 'Ancora nessuna conversazione';

  @override
  String get hfHandsFreeRow => 'Voce a mani libere';

  @override
  String hfHandsFreeOn(String state) {
    return 'Accesa: $state';
  }

  @override
  String get hfHandsFreeOff => 'Spenta su questo dispositivo';

  @override
  String get fsrTitle => 'Cerca nelle conversazioni';

  @override
  String get fsrGo => 'Cerca';

  @override
  String get fsrHint =>
      'Le parole in tutte le conversazioni: degli agenti, della Chat e degli inspector. Almeno due lettere.';

  @override
  String get fsrNone => 'Nessun risultato.';

  @override
  String get fsrUntitled => 'Nuova conversazione';

  @override
  String get fsrInspector => 'Inspector';

  @override
  String get g7WzRoleFull => 'Un Rasgeth completo';

  @override
  String get g7WzRoleFullText => 'Qui vivono i suoi agenti, progetti e chat.';

  @override
  String get g7WzRoleNode => 'Un nodo di un altro Rasgeth';

  @override
  String get g7WzRoleNodeText =>
      'Presta questa macchina a un altro Rasgeth: comandi, modelli locali, spazio per progetti e backup.';

  @override
  String get g7WzNoWay => 'Ancora nessun modo di pensare';

  @override
  String g7WzWays(String ways) {
    return 'Collegati: $ways';
  }

  @override
  String get g7WzWayKeys => 'Chiavi API';

  @override
  String get g7WzWayLocal => 'un modello su questo computer';

  @override
  String get g7WzWayServer => 'il tuo server';

  @override
  String get g7WzOpenModels => 'Modelli e abbonamenti';

  @override
  String get g7WzNoLocal => 'Ancora nessun modello su questo computer';

  @override
  String g7WzLocal(String model) {
    return 'In uso: $model';
  }

  @override
  String get g7WzOpenLocal => 'Modelli su questo computer';

  @override
  String get g7WzAssignLead =>
      'Chi decide ha il modello più forte, chi risponde uno veloce: God, Demi-God, gli assistenti e gli altri, ognuno il suo.';

  @override
  String get g7WzOpenAssign => 'Scegli chi usa quale modello';

  @override
  String get g7WzTelegramLead =>
      'Scrivi a Demi-God dal telefono, anche a voce: un bot tuo, fatto in un minuto con BotFather.';

  @override
  String get g7WzOpenTelegram => 'Configura Telegram';

  @override
  String get g7WzOpenBackups => 'Backup e destinazioni';

  @override
  String get g7WzOpenCode => 'GitHub e Gitea';

  @override
  String get g7WzOpenRemote => 'Accesso da fuori casa';

  @override
  String g7WzPresetText(String n) {
    return '$n tipi di azione che approvi solo tu';
  }

  @override
  String get g7WzSafetyMore => 'Tutto su sicurezza e costi';

  @override
  String get g7WzCustom => 'Una scelta tua';

  @override
  String get g7WzPassword => 'Password';

  @override
  String get g7WzPasswordAgain => 'Di nuovo la password';

  @override
  String g7WzDiskFree(String gb) {
    return 'Libero sul disco: $gb GB';
  }

  @override
  String get g7WzRedo => 'Rifai la configurazione';

  @override
  String get g7WzRedoText =>
      'La configurazione guidata della pagina, un passo alla volta: ogni passo si salva subito.';

  @override
  String get g7WzContinue => 'Continua la configurazione';

  @override
  String get g7WzContinueText =>
      'Modelli, chi usa quale, importazioni, Telegram, backup, accesso da fuori e sicurezza: un passo alla volta, ognuno si può saltare.';

  @override
  String get g7AcpRemove => 'Rimuovi';

  @override
  String get g7ImpOpen => 'Importa da altri agenti';

  @override
  String get g7ImpRow => 'Da Claude Code, Codex, Cursor e dalle esportazioni delle chat';

  @override
  String get g7AcpRow => 'Claude Code, Codex, Gemini CLI come agenti di un progetto';

  @override
  String get g7PlRow => 'Ogni modifica alle impostazioni e al codice, annullabile';

  @override
  String get g7NewsRow => 'Le novità di questa versione';

  @override
  String get g7HubTitle => 'Configurazione, importazioni e storia';

  @override
  String get g7SetupCode => 'Il codice di setup mostrato dalla macchina';

  @override
  String get g7SetupCodeYes => 'Ancora nessuna password? Usa il codice di setup';

  @override
  String get g7SetupCodeNo => 'Accedi con la password';

  @override
  String get trayOpen => 'Apri';

  @override
  String get trayQuit => 'Esci';

  @override
  String get trayStay => 'Resta nella barra di sistema quando chiudi la finestra';

  @override
  String get trayStayHelp =>
      'Richieste, domande e resoconti dei compiti continuano ad arrivare come notifiche; il menu dell\'icona riapre l\'app o la chiude.';

  @override
  String get trayNone =>
      'Questo desktop non ha una barra di sistema: chiudere la finestra chiude l\'app.';

  @override
  String get pushDesktopInTray =>
      'Con la finestra chiusa l\'app resta nella barra di sistema e le notifiche arrivano lo stesso. Dopo «Esci» questo computer non riceve niente: la pagina di Rasgeth e le chat collegate sì.';

  @override
  String get hfWakeNeedsModel =>
      'La parola di attivazione ha bisogno del suo modello vocale su questo dispositivo (Impostazioni, Voce); fino ad allora tocca l\'indicatore, poi «Parla ora».';

  @override
  String hfWakeModelAbout(String mb) {
    return 'La parola di attivazione si sente su questo dispositivo con un piccolo modello vocale (Vosk, Apache-2.0): $mb MB da scaricare una volta, poi resta qui. Niente di quello che dici esce dal dispositivo prima della parola.';
  }

  @override
  String get hfWakeModelAboutSoon =>
      'La parola di attivazione si sente su questo dispositivo con un piccolo modello vocale (Vosk, Apache-2.0), scaricato una volta e tenuto qui.';

  @override
  String get hfWakeStageServer => 'Rasgeth sta scaricando il modello vocale (solo la prima volta)';

  @override
  String get hfWakeStageEngine =>
      'Scarico il riconoscitore per questo computer (solo la prima volta)';

  @override
  String get hfWakeStageModel =>
      'Porto il modello vocale su questo dispositivo (solo la prima volta)';

  @override
  String get hfWakeLoading => 'Avvio la parola di attivazione…';

  @override
  String get hfWakeRetry => 'Riprova';

  @override
  String get hfWakeOnFirst => 'Prima accendi la voce a mani libere.';

  @override
  String get hfWakeErrFailed =>
      'lo scaricamento si è interrotto; controlla la connessione e riprova';

  @override
  String get hfWakeErrServer => 'Rasgeth non è riuscito a scaricare il modello vocale';

  @override
  String get hfWakeErrChecksum =>
      'il riconoscitore arrivato non è quello atteso, quindi non è stato tenuto';

  @override
  String get hfWakeErrBroken =>
      'il modello vocale non è partito su questo dispositivo; scaricalo di nuovo';

  @override
  String get moSysPersistarLine =>
      'Il contesto di ogni conversazione con un modello locale è salvato su disco: tornandoci, anche dopo un riavvio, non si rilegge tutto da capo.';

  @override
  String get smpMorning => 'Buongiorno';

  @override
  String get smpAfternoon => 'Buon pomeriggio';

  @override
  String get smpEvening => 'Buonasera';

  @override
  String smpMorningName(String name) {
    return 'Buongiorno, $name';
  }

  @override
  String smpAfternoonName(String name) {
    return 'Buon pomeriggio, $name';
  }

  @override
  String smpEveningName(String name) {
    return 'Buonasera, $name';
  }

  @override
  String get smpHeroLead => 'Di cosa hai bisogno oggi?';

  @override
  String get smpAskHint => 'Chiedimi qualcosa…';

  @override
  String get smpReplyHint => 'Rispondi…';

  @override
  String get smpSend => 'Invia';

  @override
  String get smpSettings => 'Impostazioni';

  @override
  String get smpInProgress => 'IN CORSO';

  @override
  String get smpNoTopics => 'Niente in corso. Scrivi qui sopra cosa ti serve: ci penso io.';

  @override
  String get smpLoading => 'Un momento…';

  @override
  String smpArchive(String n) {
    return 'Archivio ($n)';
  }

  @override
  String get smpJustStarted => 'Appena iniziato';

  @override
  String smpFrom(String name) {
    return 'da $name';
  }

  @override
  String get smpUnread => 'Novità';

  @override
  String get smpWaiting => 'ti aspetto';

  @override
  String get smpWorking => 'al lavoro';

  @override
  String get smpReady => 'pronto';

  @override
  String get smpOtherOne => 'Una cosa aspetta una tua risposta';

  @override
  String smpOtherMany(String n) {
    return '$n cose aspettano una tua risposta';
  }

  @override
  String get smpBack => 'Indietro';

  @override
  String get smpMore => 'Altro';

  @override
  String get smpRename => 'Rinomina';

  @override
  String get smpPin => 'Tieni in cima';

  @override
  String get smpUnpin => 'Non tenere in cima';

  @override
  String get smpArchiveThis => 'Metti in archivio';

  @override
  String get smpEmptyTopic => 'Ancora niente qui.';

  @override
  String get smpWorkingNow => 'Ci sto lavorando…';

  @override
  String get smpMove => 'Sposta';

  @override
  String get smpMovedHere => 'Portato qui da un altro argomento';

  @override
  String get smpRoutedIn => 'in:';

  @override
  String get smpRoutedUnsure => 'Non ero sicuro: l\'ho messo qui';

  @override
  String smpMovedTo(String title) {
    return 'Spostato in «$title»';
  }

  @override
  String get smpMovedElsewhere => 'Spostato in un altro argomento';

  @override
  String get smpDecide => 'Una decisione per te';

  @override
  String get smpAskAllow => 'Posso procedere?';

  @override
  String get smpAskCritical => 'Attenzione: questa cosa non si può annullare. Posso procedere?';

  @override
  String smpFor(String title) {
    return 'per: $title';
  }

  @override
  String get smpYes => 'Sì, procedi';

  @override
  String get smpNo => 'No';

  @override
  String get smpMoveTitle => 'Sposta in un altro argomento';

  @override
  String get smpMoveLead =>
      'Il tuo messaggio e la mia risposta vanno lì, e lì ti rispondo di nuovo.';

  @override
  String get smpNewTopic => 'Nuovo argomento';

  @override
  String get smpNewTopicName => 'Come lo chiamiamo? (puoi lasciarlo vuoto)';

  @override
  String get smpSearchHint => 'Cerca nei tuoi argomenti';

  @override
  String get smpInArchive => 'IN ARCHIVIO';

  @override
  String get smpArchiveTitle => 'Archivio';

  @override
  String get smpArchiveLead =>
      'Qui riposano gli argomenti fermi da qualche giorno. Toccane uno per riprenderlo.';

  @override
  String get smpNothingFound => 'Niente con queste parole.';

  @override
  String get smpArchiveEmpty => 'L\'archivio è vuoto.';

  @override
  String get smpRequestsTitle => 'Ti aspettano';

  @override
  String get smpNothingWaits => 'Niente ti aspetta.';

  @override
  String get smpNotify => 'Avvisi su questo dispositivo';

  @override
  String get smpNotifyBlocked => 'Bloccati dal browser: permettili nelle sue impostazioni.';

  @override
  String get smpVoice => 'Voce';

  @override
  String get smpVoiceHelp => 'Parlami e ascolta le risposte, su questo dispositivo.';

  @override
  String get smpSpend => 'Chiedimi prima di spendere';

  @override
  String get smpSpendHelp => 'Prima di pagare o comprare qualcosa te lo chiedo sempre.';

  @override
  String get smpAlways => 'Sempre';

  @override
  String get smpYourName => 'Il tuo nome';

  @override
  String get smpYourNameLabel => 'Come ti chiamo?';

  @override
  String get smpNoName => 'Aggiungi';

  @override
  String get smpLink => 'Collega';

  @override
  String get smpLinked => 'Collegato';

  @override
  String get smpTheme => 'Aspetto';

  @override
  String get smpColour => 'Colore';

  @override
  String get smpLanguage => 'Lingua';

  @override
  String get smpFullView => 'Vista completa';

  @override
  String get smpFullViewHelp => 'Tutte le impostazioni, per chi vuole vedere come funziona dentro.';

  @override
  String get smpSignOut => 'Esci';

  @override
  String get uiTitle => 'Interfaccia';

  @override
  String get uiHelp =>
      'Quella semplice mostra solo i tuoi argomenti e poche impostazioni; quella completa mostra tutto. Ogni dispositivo ricorda la sua.';

  @override
  String get uiSimple => 'Semplice';

  @override
  String get uiFull => 'Completa';

  @override
  String get wzLook => 'Interfaccia';

  @override
  String get wzLookQ => 'Come vuoi vedere Rasgeth?';

  @override
  String get wzLookLead => 'Puoi cambiarla quando vuoi, su ogni dispositivo.';

  @override
  String get wzLookSimple => 'Semplice';

  @override
  String get wzLookSimpleText =>
      'Una grande casella per chiedere quello che ti serve, i tuoi argomenti in corso e poche impostazioni. Per le cose di tutti i giorni.';

  @override
  String get wzLookFull => 'Completa';

  @override
  String get wzLookFullText =>
      'Agenti, progetti, strumenti, modelli e tutte le impostazioni. Per chi vuole vedere come funziona dentro.';

  @override
  String get wzLookName => 'Come ti chiamiamo?';

  @override
  String get wzLookNameHint => 'Il tuo nome (facoltativo)';

  @override
  String get smpOther => 'Altro…';

  @override
  String get smpOtherHint => 'Scrivi la tua risposta';

  @override
  String get prSection => 'Regole';

  @override
  String get prQ => 'Cosa deve tenere d\'occhio Rasgeth per te?';

  @override
  String get prLead =>
      'Scrivi una regola una volta e Rasgeth la fa rispettare da solo: quando succede qualcosa, se è come dici tu, ti avvisa, ti chiede, blocca o ferma gli agenti. Una regola non dà mai a nessuno più di quello che hai tu.';

  @override
  String get prMagic => 'Regola magica';

  @override
  String get prNew => 'Nuova regola';

  @override
  String get prListTitle => 'Le tue regole';

  @override
  String get prListLead =>
      'Una regola agisce solo se è accesa. Ognuna si prova sui suoi due esempi prima di accendersi.';

  @override
  String get prNone =>
      'Ancora nessuna regola. Descrivine una a God con «Regola magica», o scrivila tu.';

  @override
  String get prFiresTitle => 'Cosa hanno fatto le regole';

  @override
  String get prFiresLead => 'Le ultime volte che una regola ha agito, dalla più recente.';

  @override
  String get prTplMargin => 'Margine settimanale dell\'abbonamento';

  @override
  String get prTplMarginQ => 'Avvisarti a +5, fermare gli agenti a +2?';

  @override
  String get prTplMarginLead =>
      'Il margine è quanta settimana è passata meno quanta ne hai usata. Due regole, aggiunte spente: le accendi tu.';

  @override
  String get prTplAdd => 'Aggiungi le due regole';

  @override
  String prHoldTitle(String name) {
    return 'Fermati dalla regola «$name»';
  }

  @override
  String prHoldSince(String when) {
    return 'dalle $when';
  }

  @override
  String get prResumeNow => 'Riprendi';

  @override
  String get prByYou => 'tu';

  @override
  String get prByGod => 'fatta con God';

  @override
  String get prByTemplate => 'pronta';

  @override
  String prLastFired(String when) {
    return 'ultima volta $when';
  }

  @override
  String get prEdit => 'Cambia';

  @override
  String get prHistory => 'Storia';

  @override
  String prHistoryOf(String name) {
    return 'Storia di «$name»';
  }

  @override
  String prHistoryBy(String by, String version) {
    return '$by, versione $version';
  }

  @override
  String get prUndo => 'Annulla l\'ultima modifica';

  @override
  String get prRemove => 'Togli';

  @override
  String prRemoveQ(String name) {
    return 'Togliere la regola «$name»?';
  }

  @override
  String get prRemoveLead => 'Smette subito di agire. La sua storia resta: «Annulla» la riporta.';

  @override
  String get prChCreated => 'Creata';

  @override
  String get prChChanged => 'Cambiata';

  @override
  String get prChEnabled => 'Accesa';

  @override
  String get prChDisabled => 'Spenta';

  @override
  String get prChRemoved => 'Tolta';

  @override
  String get prChUndone => 'Annullata';

  @override
  String get prName => 'Nome';

  @override
  String get prNamePh => 'Niente push la domenica';

  @override
  String get prWords => 'Con parole tue (facoltativo)';

  @override
  String get prWhen => 'Quando';

  @override
  String get prWhenQ => 'cosa succede?';

  @override
  String get prIf => 'Se';

  @override
  String get prIfQ => 'cosa deve essere vero? (tutto)';

  @override
  String get prIfNone => 'Nessuna condizione: agisce ogni volta.';

  @override
  String get prThen => 'Allora';

  @override
  String get prThenQ => 'cosa fa Rasgeth?';

  @override
  String get prValue => 'Valore';

  @override
  String get prAddCond => 'Aggiungi una condizione';

  @override
  String get prRemoveCond => 'Togli la condizione';

  @override
  String get prAddAct => 'Aggiungi un\'azione';

  @override
  String get prRemoveAct => 'Togli l\'azione';

  @override
  String get prNotifyPh => 'Cosa dirti (vuoto: cosa è successo)';

  @override
  String get prReasonPh => 'Perché (l\'agente lo legge)';

  @override
  String get prScopeAll => 'Tutti';

  @override
  String get prScopeProject => 'Quelli del progetto';

  @override
  String get prScopeAgent => 'Quell\'agente';

  @override
  String get prResumePerson => 'Li riprendo io';

  @override
  String get prResumeAuto => 'Torna tutto a posto';

  @override
  String get prToolsOff => 'Strumenti da spegnere';

  @override
  String get prAutomation => 'Automazione';

  @override
  String get prCommand => 'Comando';

  @override
  String get prProjectPh => 'Progetto (vuoto: la cartella delle regole)';

  @override
  String get prCommandSafe =>
      'Gira nella sandbox, controllato come il comando di un agente: ciò che è davvero pericoloso chiede a te, e nel suo ambiente non c\'è nessuna chiave.';

  @override
  String get prCron => 'Orario';

  @override
  String get prCronHelp =>
      'Minuto, ora, giorno, mese, giorno della settimana: 0 9 * * 1-5 sono le 9:00 dei giorni feriali.';

  @override
  String get prExamples => 'Prova';

  @override
  String get prExamplesQ => 'un caso in cui deve agire, uno in cui no';

  @override
  String get prExFire => 'Deve agire';

  @override
  String get prExPass => 'Non deve agire';

  @override
  String get prExOk => 'Come previsto';

  @override
  String get prExBad => 'Non come previsto';

  @override
  String get prTrialOk => 'I due esempi vanno come devono: la regola si può accendere.';

  @override
  String get prTry => 'Prova';

  @override
  String get prSaveOff => 'Salva spenta';

  @override
  String get prSaveOn => 'Salva e accendi';

  @override
  String get prAnd => ' e ';

  @override
  String prSayWhen(String event) {
    return 'Quando $event';
  }

  @override
  String prSayWhenTime(String cron) {
    return 'Agli orari $cron';
  }

  @override
  String prSayIf(String conds) {
    return 'se $conds';
  }

  @override
  String prSayThen(String acts) {
    return 'allora $acts';
  }

  @override
  String get prSayNotify => 'ti avvisa';

  @override
  String prSayNotifyText(String text) {
    return 'ti dice «$text»';
  }

  @override
  String get prSayAsk => 'prima chiede a te';

  @override
  String get prSayBlock => 'lo blocca';

  @override
  String get prSayStop => 'ferma gli agenti dopo che hanno salvato, finché non li riprendi';

  @override
  String get prSayStopAuto => 'ferma gli agenti dopo che hanno salvato, finché non torna a posto';

  @override
  String prSayToolsOff(String what) {
    return 'spegne $what';
  }

  @override
  String prSayAutomation(String name) {
    return 'lancia l\'automazione «$name»';
  }

  @override
  String prSayCommand(String command) {
    return 'esegue «$command» nella sandbox';
  }

  @override
  String get prEvUsage => 'si legge il consumo dell\'abbonamento';

  @override
  String get prEvBudget => 'si usa un budget';

  @override
  String get prEvTool => 'sta per partire uno strumento o un comando';

  @override
  String get prEvFile => 'sta per essere scritto un file';

  @override
  String get prEvAgentDone => 'un agente finisce';

  @override
  String get prEvSchedule => 'a un orario';

  @override
  String get prFieldMargin => 'il margine (punti)';

  @override
  String get prFieldUsed => 'il consumo (%)';

  @override
  String get prFieldWindow => 'la finestra';

  @override
  String get prFieldProvider => 'l\'abbonamento';

  @override
  String get prFieldBudgetPct => 'il budget usato (%)';

  @override
  String get prFieldBudget => 'il budget';

  @override
  String get prFieldTool => 'lo strumento';

  @override
  String get prFieldCommand => 'il comando';

  @override
  String get prFieldPath => 'il percorso';

  @override
  String get prFieldProject => 'il progetto';

  @override
  String get prFieldAgent => 'l\'agente';

  @override
  String get prFieldStop => 'come è finito';

  @override
  String get prOpLt => 'è meno di';

  @override
  String get prOpLte => 'è al massimo';

  @override
  String get prOpGt => 'è più di';

  @override
  String get prOpGte => 'è almeno';

  @override
  String get prOpEq => 'è';

  @override
  String get prOpNeq => 'non è';

  @override
  String get prOpMatches => 'somiglia a';

  @override
  String get prOpContains => 'contiene';

  @override
  String get prActNotify => 'Avvisami';

  @override
  String get prActAsk => 'Chiedimi prima';

  @override
  String get prActBlock => 'Bloccalo';

  @override
  String get prActStop => 'Ferma gli agenti';

  @override
  String get prActToolsOff => 'Spegni strumenti';

  @override
  String get prActAutomation => 'Lancia un\'automazione';

  @override
  String get prActCommand => 'Esegui un comando';

  @override
  String get prMagicAsk => 'Cosa deve fare la regola?';

  @override
  String get prMagicPh =>
      'Per esempio: se il margine settimanale scende sotto 5 avvisami, sotto 2 ferma tutti';

  @override
  String get prMagicStep1 => 'Lo dici tu';

  @override
  String get prMagicStep2 => 'God la costruisce e la prova';

  @override
  String get prMagicStep3 => 'Decidi tu';

  @override
  String get prMagicProposal => 'La regola di God';

  @override
  String get prMagicMissing => 'Manca ancora:';

  @override
  String get prMagicNotTested => 'I suoi esempi non passano ancora; verrà creata spenta:';

  @override
  String get prMagicRefuse => 'Rifiuta';

  @override
  String get prMagicChange => 'Cambia';

  @override
  String get prMagicApprove => 'Approva';

  @override
  String get prMagicDone => 'Fatto: la regola è tra le tue regole.';

  @override
  String get prMagicBuilding => 'God sta costruendo la regola con te nella conversazione.';

  @override
  String get prMagicGo => 'Inizia con God';

  @override
  String get prMagicSendNo => 'Manda il no';

  @override
  String get prMagicWhy => 'Cosa non va (God lo legge)';

  @override
  String get prHub => 'Quando, se, allora: cosa Rasgeth tiene d’occhio per te';

  @override
  String get prEvWebhook => 'viene chiamato il suo indirizzo (webhook)';

  @override
  String get prFieldBody => 'ciò che manda';

  @override
  String get prHook => 'Indirizzo';

  @override
  String get prHookQ => 'Fare un segreto nuovo per l\'indirizzo di questa regola?';

  @override
  String get prHookQLead =>
      'Il segreto si vede una volta sola. Un segreto vecchio smette di funzionare.';

  @override
  String get prHookMake => 'Fai il segreto';

  @override
  String prHookTitle(String name) {
    return 'Indirizzo di «$name»';
  }

  @override
  String get prHookLead =>
      'Dai al servizio questo indirizzo e il segreto (nell\'intestazione x-redgiant-secret, o in fondo all\'indirizzo). Ciò che manda sono solo dati che la regola guarda: mai istruzioni.';

  @override
  String get prHookAddress => 'Indirizzo';

  @override
  String get prHookSecret => 'Segreto';

  @override
  String get prHookSecretHelp => 'Si vede solo ora: copialo.';

  @override
  String get syEmAccel => 'Accelerazione';

  @override
  String syEmAccelOk(String kind) {
    return '$kind funziona';
  }

  @override
  String get syEmAccel_container => 'nessuna in un container';

  @override
  String get syEmAccel_disabled => 'la virtualizzazione è spenta (BIOS) o manca l\'hypervisor';

  @override
  String get syEmAccel_kvm_denied =>
      'KVM c\'è ma questo utente non può usarlo (aggiungilo al gruppo kvm)';

  @override
  String get syEmAccel_no_kvm =>
      'Niente KVM: accendi la virtualizzazione nel BIOS e carica il modulo KVM';

  @override
  String get syEmAccel_unknown => 'non si sa finché l\'emulatore non è installato';

  @override
  String get syEmAdb => 'adb (platform-tools)';

  @override
  String get syEmAdbIdle =>
      'adb non è in funzione, quindi emulatori accesi e telefoni non si conoscono: Rasgeth non lo avvia solo per guardare.';

  @override
  String syEmApi(String api) {
    return 'API $api';
  }

  @override
  String get syEmAttached => 'Accesi adesso';

  @override
  String get syEmAvds => 'Dispositivi virtuali';

  @override
  String get syEmContainer =>
      'Qui Rasgeth gira in un container, quindi gli emulatori non possono girare su questa macchina: arrivano da un nodo con Android Studio o l\'SDK (un computer Windows, Mac o Linux collegato in Impostazioni › Nodi).';

  @override
  String get syEmEmulator => 'Emulatore';

  @override
  String get syEmFolder => 'Cartella dell\'SDK Android';

  @override
  String get syEmFolderForget => 'Dimenticala';

  @override
  String get syEmFolderHelp => 'La cartella che contiene platform-tools, emulator o system-images.';

  @override
  String get syEmFolderLabel => 'Percorso completo della cartella dell\'SDK';

  @override
  String get syEmFolderLead =>
      'Solo se l\'SDK sta in un posto dove Rasgeth non guarda da solo. Guarda ANDROID_HOME, ANDROID_SDK_ROOT, le impostazioni di Android Studio, il posto solito di Android Studio e adb nel PATH.';

  @override
  String get syEmFolderSave => 'Usa questa cartella';

  @override
  String get syEmHere => 'Questa macchina';

  @override
  String get syEmImageMissing => 'immagine mancante';

  @override
  String get syEmImages => 'Immagini di sistema';

  @override
  String get syEmLead =>
      'Emulatori Android, telefoni Android via USB o Wi-Fi e simulatori iOS: cosa hanno questa macchina e i tuoi nodi, e cosa manca. Qui Rasgeth guarda soltanto: non installa e non avvia niente.';

  @override
  String get syEmLookAgain => 'Guarda di nuovo';

  @override
  String get syEmLooked => 'Dove ha guardato Rasgeth';

  @override
  String get syEmLooking => 'Sto guardando…';

  @override
  String get syEmMax => 'Emulatori insieme';

  @override
  String get syEmMaxLead =>
      'Quanti emulatori possono girare insieme su questa macchina: ognuno usa da 2 a 4 GB di memoria.';

  @override
  String get syEmMiss_accel => 'L\'accelerazione hardware: senza, gli emulatori sono troppo lenti.';

  @override
  String get syEmMiss_avd => 'Un dispositivo virtuale che possa partire qui.';

  @override
  String get syEmMiss_cmdline_tools =>
      'cmdline-tools (sdkmanager, avdmanager), per scaricare immagini e creare dispositivi virtuali.';

  @override
  String get syEmMiss_emulator => 'Il pacchetto Android Emulator dell\'SDK.';

  @override
  String get syEmMiss_emulator_old =>
      'L\'emulatore è vecchio: Rasgeth può proporti l\'aggiornamento, che approvi tu.';

  @override
  String get syEmMiss_ios_bridge =>
      'Il ponte per immagine e tocchi dei simulatori iOS (serve-sim): un passo guidato lo scarica, con il tuo sì.';

  @override
  String get syEmMiss_platform_tools =>
      'platform-tools (adb), per parlare con emulatori e telefoni.';

  @override
  String get syEmMiss_sdk =>
      'Un SDK Android (lo installa Android Studio; oppure scegli qui sotto la sua cartella).';

  @override
  String get syEmMiss_system_image => 'Un\'immagine di sistema per questo processore.';

  @override
  String get syEmMiss_xcode => 'Xcode, per i simulatori iOS (dall\'App Store).';

  @override
  String get syEmMissing => 'Cosa manca';

  @override
  String get syEmNoNodes =>
      'Nessun nodo collegato. Collega in Impostazioni › Nodi un computer con Android Studio per usarne gli emulatori da qui.';

  @override
  String get syEmNoSdk =>
      'Nessun SDK Android trovato. Se ce l\'hai, scegli qui sotto la sua cartella, oppure installa Android Studio (o solo l\'SDK); arriverà un\'installazione guidata, che chiede sempre prima a te.';

  @override
  String get syEmNodeOffline => 'non in linea';

  @override
  String get syEmNodeOld =>
      'Questo nodo non ha detto cosa ha: è spento o è più vecchio della 3.11.';

  @override
  String get syEmNodes => 'I tuoi nodi';

  @override
  String get syEmNodesLead =>
      'Cosa hanno le macchine collegate a questa, come l\'ha detto ognuna l\'ultima volta.';

  @override
  String get syEmNone => 'nessuno';

  @override
  String get syEmNoneAttached => 'Nessun emulatore acceso e nessun telefono collegato.';

  @override
  String get syEmNotReady => 'Non ancora pronta: qui sotto c\'è cosa manca.';

  @override
  String get syEmOffline => 'non risponde';

  @override
  String get syEmPhoneUsb => 'Telefono via USB';

  @override
  String get syEmPhoneWifi => 'Telefono via Wi-Fi';

  @override
  String get syEmPlayStore => 'Play Store';

  @override
  String get syEmQ => 'Emulatori e telefoni';

  @override
  String syEmReady(String count) {
    return 'Pronta: qui possono girare gli emulatori ($count dispositivi virtuali).';
  }

  @override
  String get syEmRunningEmu => 'Emulatore';

  @override
  String get syEmSdk => 'SDK Android';

  @override
  String get syEmSection => 'Emulatori';

  @override
  String get syEmSimulators => 'Simulatori iOS';

  @override
  String get syEmSrc_ANDROID_HOME => 'da ANDROID_HOME';

  @override
  String get syEmSrc_ANDROID_SDK_ROOT => 'da ANDROID_SDK_ROOT';

  @override
  String get syEmSrc_custom => 'la cartella che hai scelto';

  @override
  String get syEmSrc_path => 'intorno ad adb o all\'emulatore nel PATH';

  @override
  String get syEmSrc_standard => 'il posto solito di Android Studio';

  @override
  String get syEmSrc_studio => 'dalle impostazioni di Android Studio';

  @override
  String get syEmSystem => 'Sistema';

  @override
  String get syEmUnauthorized => 'aspetta il tuo sì sul telefono';

  @override
  String get syEmXcode => 'Xcode';

  @override
  String get syOffline => 'non collegato';

  @override
  String get syHubEmulators => 'Emulatori Android, telefoni e simulatori iOS, qui e sui nodi';

  @override
  String get syAgents => 'Agenti';

  @override
  String get syDsBack => 'Indietro';

  @override
  String syDsError(String error) {
    return 'Non si può mostrare: $error';
  }

  @override
  String get syDsHome => 'Home';

  @override
  String get syDsRecents => 'App recenti';

  @override
  String get syDsRotate => 'Ruota';

  @override
  String syDsScreen(String name) {
    return 'Lo schermo di $name';
  }

  @override
  String get syDsShared =>
      'Il dispositivo degli agenti: vedi cosa fanno. Prendi il controllo per usarlo tu.';

  @override
  String get syDsStarting => 'Accendo l\'emulatore senza finestra: ci vuole circa un minuto.';

  @override
  String get syDsYours =>
      'Adesso è tuo: tocca, tieni premuto, scorri e scrivi. Quello che fai qui non arriva a nessun modello né nel registro. Restituiscilo quando hai finito.';

  @override
  String get syEmDevices => 'Dispositivi';

  @override
  String get syEmDevicesLead =>
      'Aprine uno per vederlo dal vivo a destra: un emulatore spento si accende senza finestra.';

  @override
  String get syEmNoDevices => 'Ancora nessun dispositivo qui.';

  @override
  String get syEmOpen => 'Apri';

  @override
  String get syEmStartedHere => 'acceso da Rasgeth';

  @override
  String get syEmStop => 'Spegni';

  @override
  String get syScreenGiveBack => 'Restituisci agli agenti';

  @override
  String get syScreenStarting => 'Avvio il browser…';

  @override
  String get syScreenTake => 'Prendi il controllo';

  @override
  String get syDsState_off => 'spento';

  @override
  String get syDsState_offline => 'non risponde';

  @override
  String get syDsState_on => 'acceso';

  @override
  String get syDsState_starting => 'si accende…';

  @override
  String get syDsState_unauthorized => 'aspetta il tuo sì sul telefono';

  @override
  String get syEiAvdName => 'Nome del telefono virtuale';

  @override
  String get syEiAvdNameHelp => 'Lettere, cifre, punto, trattino e trattino basso.';

  @override
  String get syEiBlock_container =>
      'Qui Rasgeth gira in un container, e lì dentro gli emulatori non possono girare. Collega un nodo (un computer con Rasgeth) e i suoi emulatori compaiono qui.';

  @override
  String get syEiBlock_emulators_running =>
      'C\'è un emulatore acceso: spegnilo prima, poi aggiorna.';

  @override
  String get syEiBlock_folder_not_empty =>
      'Quella cartella contiene già altre cose e non è un SDK Android: scegline una nuova o vuota.';

  @override
  String get syEiBlock_folder_relative => 'La cartella deve essere un percorso completo.';

  @override
  String syEiBlock_java_old(String major) {
    return 'Il Java trovato è la versione $major: gli strumenti di Android vogliono la 17 o più nuova. Installa un Java 17 o fai puntare JAVA_HOME a uno, poi guarda di nuovo.';
  }

  @override
  String get syEiBlock_no_accel =>
      'Questo computer non ha l\'accelerazione hardware per le macchine virtuali: un emulatore sarebbe troppo lento per usarlo. Non installo niente; meglio un nodo su un computer che ce l\'ha.';

  @override
  String get syEiBlock_no_java =>
      'Gli strumenti di Android vogliono Java 17 o più nuovo, e non l\'ho trovato (JAVA_HOME, il PATH, Android Studio). Installa un Java 17 (per esempio Eclipse Temurin o OpenLogic) o Android Studio, poi guarda di nuovo. Rasgeth non installa Java da solo.';

  @override
  String get syEiBlock_nothing => 'Qui non manca niente.';

  @override
  String get syEiBlock_offline =>
      'Non sono riuscito a leggere l\'elenco dei pacchetti di Google (con le licenze). Controlla la connessione e riprova.';

  @override
  String get syEiBlock_unsupported =>
      'Google non fa un emulatore Android per questo sistema e questo processore. Un nodo su un altro computer può portarne uno.';

  @override
  String get syEiCancelled => 'Fermata. Puoi ripartire quando vuoi.';

  @override
  String get syEiClose => 'Chiudi';

  @override
  String get syEiDone => 'Fatto. Il resoconto di questa macchina è stato letto di nuovo.';

  @override
  String get syEiFailed =>
      'L\'installazione non è finita. Quello che è già nella cartella resta; puoi riprovare.';

  @override
  String get syEiFolder => 'Cartella';

  @override
  String get syEiFolderApply => 'Ricalcola';

  @override
  String get syEiFolderHelp =>
      'Un percorso completo; una cartella nuova o vuota, oppure un SDK Android già presente.';

  @override
  String get syEiFolderOther => 'Un\'altra cartella o un altro nome';

  @override
  String get syEiFolderStandard => 'il posto standard di questo sistema';

  @override
  String get syEiInstall => 'Installa quello che manca';

  @override
  String syEiJava(String major) {
    return 'Con Java $major:';
  }

  @override
  String get syEiLead =>
      'Rasgeth li scarica da Google solo adesso, con il tuo sì, e mette tutto in questa cartella (il telefono virtuale va dove l\'emulatore li tiene). Nient\'altro cambia sul computer.';

  @override
  String get syEiLicenceAccept => 'Ho letto e accetto queste licenze';

  @override
  String get syEiLicenceHelp =>
      'Rasgeth dice sì al posto tuo solo a queste, solo per questa installazione.';

  @override
  String get syEiLicences => 'Licenze';

  @override
  String get syEiLicencesLead =>
      'Le condizioni di Google per questi pezzi, per intero. Leggile: l\'installazione parte solo quando le accetti.';

  @override
  String get syEiNote_bios =>
      'La virtualizzazione è spenta: accendila nel BIOS/UEFI (VT-x o AMD-V) e, su Windows, la funzione Windows Hypervisor Platform.';

  @override
  String get syEiNote_kvm_group =>
      'Linux: /dev/kvm c\'è ma questo utente non può usarlo. Un amministratore può aggiungere l\'utente al gruppo kvm, poi si rientra.';

  @override
  String get syEiNote_node =>
      'Impostazioni › Nodi: collega un computer che può far girare gli emulatori.';

  @override
  String get syEiNote_xcode =>
      'I simulatori iOS vogliono Xcode, dall\'App Store: Rasgeth non lo installa.';

  @override
  String get syEiReading => 'Leggo l\'elenco dei pacchetti di Google…';

  @override
  String get syEiRunning => 'Parto…';

  @override
  String get syEiStart => 'Installa';

  @override
  String get syEiStartUpdate => 'Aggiorna';

  @override
  String syEiStep_avd(String name) {
    return 'Il telefono virtuale $name';
  }

  @override
  String syEiStep_cmdline_tools(String version) {
    return 'Gli strumenti a riga di comando di Android $version (sdkmanager, avdmanager)';
  }

  @override
  String get syEiStep_emulator => 'L\'emulatore Android';

  @override
  String syEiStep_emulator_update(String version) {
    return 'L\'emulatore, all\'ultima versione $version';
  }

  @override
  String get syEiStep_licences => 'Le licenze che hai letto e accettato';

  @override
  String get syEiStep_platform_tools => 'Gli strumenti di piattaforma (adb)';

  @override
  String get syEiStep_system_image => 'Android 15 (API 35) per questo processore';

  @override
  String get syEiSteps => 'Cosa farà';

  @override
  String get syEiStopNow => 'Ferma';

  @override
  String get syEiTitle => 'Installa i pezzi di Android';

  @override
  String get syEiTitleUpdate => 'Aggiorna l\'emulatore';

  @override
  String syEiTotal(String size) {
    return 'Da scaricare: $size';
  }

  @override
  String get syEiUpdate => 'Aggiorna l\'emulatore';

  @override
  String get syUiDetails => 'Dettagli per chi ti aiuta';

  @override
  String get smpOldServer =>
      'Questa interfaccia semplice ha bisogno di Rasgeth 3.12 o più recente sul server, e questo è più vecchio. Chiedi a chi lo gestisce di aggiornare il server alla 3.12; intanto l\'interfaccia completa funziona.';

  @override
  String get smpTopicsFailed =>
      'I tuoi argomenti non sono arrivati. Riprova fra un momento, o usa l\'interfaccia completa.';

  @override
  String get smpTryAgain => 'Riprova';

  @override
  String smpMascotOf(String name, String state) {
    return '$name: $state';
  }

  @override
  String get smpMoodRest => 'qui per te';

  @override
  String get smpMoodListen => 'ti ascolta';

  @override
  String get smpMoodThink => 'ci pensa';

  @override
  String get smpMoodWork => 'al lavoro';

  @override
  String get smpMoodWait => 'ti aspetta';

  @override
  String get smpMoodHappy => 'contento, qualcosa è pronto';

  @override
  String get smpMoodWorried => 'preoccupato, qualcosa non va';

  @override
  String get smpSatellite => 'Satellite';

  @override
  String get smpSatelliteChat => 'Satellite · Chat';

  @override
  String get smpChatLead => 'Due chiacchiere? Sono qui.';

  @override
  String get smpChatHint => 'Scrivi a Satellite...';

  @override
  String get smpRecentChats => 'LE ULTIME CHIACCHIERE';

  @override
  String get smpNoChats => 'Ancora nessuna chiacchierata: scrivi qui e ne cominciamo una.';

  @override
  String get smpUntitledChat => 'Una nuova chiacchierata';

  @override
  String smpTodayAt(String time) {
    return 'Oggi, $time';
  }

  @override
  String get smpYesterday => 'Ieri';

  @override
  String get smpYourAgents => 'I TUOI AGENTI';

  @override
  String get smpOpenChat => 'Apri la chat';

  @override
  String smpAgentIs(String name, String state) {
    return '$name, $state';
  }

  @override
  String get nudgeTitle => 'Un saluto da God ogni tanto';

  @override
  String get nudgeHelp =>
      'Al massimo una volta al giorno, mai di notte: su qualcosa che ti aspetta, o un buongiorno. Non chiede niente.';

  @override
  String get nudgeEvery => 'Ogni quanto';

  @override
  String get nudgeDay => 'Una volta al giorno';

  @override
  String get nudgeTwoDays => 'Ogni due giorni';

  @override
  String get nudgeWeek => 'Una volta a settimana';

  @override
  String get smpDoingThink => 'sta pensando…';

  @override
  String get smpDoingSearch => 'sta cercando…';

  @override
  String get smpDoingWork => 'sta lavorando…';

  @override
  String get smpDoingWait => 'ti aspetta';

  @override
  String smpSpentHere(String usd) {
    return 'Speso qui: $usd';
  }

  @override
  String get smpRouting => 'Lo metto nell\'argomento giusto…';

  @override
  String get syEmIosBridge => 'Ponte per immagine e tocchi';

  @override
  String syEmIosBridgeAt(String folder, String version) {
    return 'serve-sim $version, in $folder';
  }

  @override
  String get syEmIosBridgeNone => 'Non installato';

  @override
  String get syEmIosNeedsMac =>
      'I simulatori iOS esistono solo su un Mac con Xcode: collega un Mac come nodo (Impostazioni › Nodi).';

  @override
  String get syEmIosReady =>
      'Pronto: i simulatori si aprono nel Canvas come gli emulatori Android.';

  @override
  String get syEmMiss_ios_arch =>
      'I simulatori iOS vogliono un Mac con Apple silicon; questo è un Mac Intel. Usa un altro Mac come nodo.';

  @override
  String get syEmRunningSim => 'Simulatore iOS';

  @override
  String get syIbBlock_intel =>
      'Il ponte vuole un Mac con Apple silicon: questo è un Mac Intel. Usa un altro Mac come nodo.';

  @override
  String get syIbBlock_no_npm =>
      'Non c\'è npm accanto al Node con cui gira Rasgeth, quindi il ponte qui non si può installare.';

  @override
  String get syIbBlock_no_xcode =>
      'Manca Xcode: Rasgeth non lo installa (App Store). Poi guarda di nuovo.';

  @override
  String get syIbBlock_not_mac =>
      'I simulatori iOS esistono solo su un Mac: collega un Mac come nodo.';

  @override
  String get syIbBlock_nothing => 'Il ponte è già installato.';

  @override
  String get syIbBlock_offline =>
      'Il registro npm non si è potuto leggere. Controlla la connessione a internet e riprova.';

  @override
  String get syIbDone => 'Il ponte iOS è installato.';

  @override
  String get syIbFolder => 'Cartella';

  @override
  String get syIbInstall => 'Installa il ponte iOS';

  @override
  String get syIbKeyboard =>
      'Con Xcode 27 la tastiera di un simulatore vuole Device Hub davanti e il permesso Accessibilità per l\'app che esegue Rasgeth. Rasgeth non ripara mai la tastiera da solo.';

  @override
  String get syIbLead =>
      'Rasgeth mostra lo schermo di un simulatore iOS e manda i tuoi tocchi tramite serve-sim (Apache-2.0, di Evan Bacon). Non fa parte di Rasgeth: con il tuo sì viene scaricato dal registro npm in una cartella di Rasgeth su questo Mac, controllato con la somma di controllo del registro, e nient\'altro sul Mac cambia. Togliendo quella cartella lo togli.';

  @override
  String get syIbLicence => 'Licenza';

  @override
  String get syIbSize => 'Dimensione una volta aperto';

  @override
  String get syIbStart => 'Scarica e installa';

  @override
  String get syIbStepDownload => 'Scarico serve-sim';

  @override
  String get syIbStepInstall => 'Lo installo nella cartella';

  @override
  String get syIbTitle => 'Ponte iOS';

  @override
  String get syIbVersion => 'Versione';
}
