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
      'I modelli su questa macchina, un tuo server e il resto sono nelle Impostazioni, dal computer o da «Tutte le impostazioni».';

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
      'Solo dalla rete di casa. Tailscale, Cloudflare o un tuo nome: in «Tutte le impostazioni».';

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
  String get metricsRestoredFromDisk => 'KV cache ripristinata dall\'SSD prima di questa richiesta';

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
  String get sideTabCanvas => 'Canvas';

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
}
