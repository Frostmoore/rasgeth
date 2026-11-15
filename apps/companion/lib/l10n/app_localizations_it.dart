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

  @override
  String get allSettings => 'Tutte le impostazioni';

  @override
  String get allSettingsHint =>
      'La pagina Impostazioni completa di RedGiant, dentro l\'app, con l\'accesso di questo dispositivo.';

  @override
  String get allSettingsBrowser => 'Apre la pagina di RedGiant nel browser: lì entri come sempre.';

  @override
  String get allSettingsNoHttps =>
      'Le impostazioni complete vogliono l\'HTTPS: da qui la pagina viaggerebbe in chiaro. Accendi l\'HTTPS nella rete di casa dal computer.';

  @override
  String get close => 'Chiudi';

  @override
  String get copy => 'Copia';

  @override
  String get connectExisting => 'Collega un RedGiant già acceso';

  @override
  String get firstStepsTitle => 'Ancora nessun RedGiant';

  @override
  String get firstStepsLead =>
      'Configurane uno nuovo da qui (al primo avvio RedGiant OS apre una sua rete Wi-Fi), oppure collega quello che usi già.';

  @override
  String get setupNew => 'Configura un RedGiant nuovo';

  @override
  String get setupNewHint =>
      'Una macchina con RedGiant OS accesa per la prima volta: l\'app entra nella sua rete temporanea e fa tutto il primo avvio.';

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
      'Quello che è fatto resta; puoi tornare qui, o finire dal browser, finché la rete temporanea è aperta (30 minuti da quando hai acceso RedGiant).';

  @override
  String get fsIntroTitle => 'Configura un RedGiant nuovo';

  @override
  String get fsIntroLead =>
      'Accendi il tuo RedGiant: per 30 minuti apre la rete Wi-Fi RedGiant-Setup-XXXX. L\'app ci entra, tu crei l\'accesso e scegli la rete di casa, poi RedGiant passa lì e l\'app lo ritrova.';

  @override
  String get fsIntroSafe =>
      'Tutto quello che scrivi viaggia cifrato, con la chiave di RedGiant controllata dall\'app: chi sta sulla rete temporanea non lo legge.';

  @override
  String get fsSeen => 'Reti temporanee qui intorno';

  @override
  String get fsNoScan =>
      'Il sistema non mostra le reti qui intorno: scrivi i quattro caratteri dopo RedGiant-Setup- (li vedi nella lista Wi-Fi del computer).';

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
  String get fsJoiningSheet => 'Scegli RedGiant-Setup nella finestra che mostra il sistema.';

  @override
  String get fsConnecting => 'Cerco RedGiant sulla rete…';

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
  String get fsWhereAndroid => 'Impostazioni › Rete › Wi-Fi: tocca RedGiant-Setup-…';

  @override
  String get fsWhereIos => 'Impostazioni › Wi-Fi: tocca RedGiant-Setup-…';

  @override
  String get fsWhereMac => 'Il menu Wi-Fi in alto a destra dello schermo: scegli RedGiant-Setup-…';

  @override
  String get fsWhereWindows => 'L\'icona Wi-Fi in basso a destra: scegli RedGiant-Setup-…';

  @override
  String get fsWhereOther => 'La lista Wi-Fi del sistema: scegli RedGiant-Setup-…';

  @override
  String get fsManualNoInternet =>
      'Il sistema può dire che la rete non ha internet: è giusto, resta collegato.';

  @override
  String get fsJoinedContinue => 'Fatto, continua';

  @override
  String get fsErrNotFound =>
      'RedGiant non risponde: sei sulla rete RedGiant-Setup? Resta aperta per 30 minuti da quando accendi RedGiant.';

  @override
  String get fsErrNotHere =>
      'Questo RedGiant non lascia creare un accesso nuovo da qui: finisci dalla sua pagina.';

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
      'La password che apre RedGiant da ogni dispositivo. Tienila: è anche quella che apre il suo portachiavi.';

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
      'Arriva cifrata a RedGiant e resta solo lì; questo dispositivo riceve un suo accesso, che puoi scollegare da Impostazioni › Dispositivi.';

  @override
  String get fsAccessGo => 'Crea l\'accesso';

  @override
  String get fsSignInTitle => 'Entra';

  @override
  String get fsSignInLead => 'Questo RedGiant ha già la sua password: scrivila per continuare.';

  @override
  String get fsMaintenanceTitle => 'RedGiant ha perso la sua rete';

  @override
  String get fsMaintenanceLead =>
      'Ha aperto la rete temporanea per riceverne una nuova. Serve la password del proprietario, e non cambia nient\'altro.';

  @override
  String get fsHomeTitle => 'La rete di casa';

  @override
  String get fsHomeLead =>
      'Quale rete deve usare RedGiant a casa? Sono quelle che ha visto intorno a sé.';

  @override
  String get fsHomeNone =>
      'Non ha visto reti intorno: usa il cavo, oppure scrivi il nome di una rete nascosta.';

  @override
  String get fsHomeUnusable => 'RedGiant non può collegarsi a questo tipo di rete';

  @override
  String get fsHomeHidden => 'Una rete nascosta';

  @override
  String get fsHomeHiddenName => 'Nome della rete';

  @override
  String fsHomePassword(String name) {
    return 'Password di «$name»';
  }

  @override
  String get fsHomeSafe => 'La password del Wi-Fi resta solo in RedGiant.';

  @override
  String fsHomeJoin(String name) {
    return 'Usa «$name»';
  }

  @override
  String get fsHomeCable => 'Uso il cavo';

  @override
  String fsHomeWaitWifi(String name) {
    return 'RedGiant si sta collegando a «$name»…';
  }

  @override
  String get fsHomeWaitCable => 'RedGiant passa alla rete di casa…';

  @override
  String get fsHomeWaitSub =>
      'Il dispositivo torna sulla sua rete e ritrova RedGiant lì (fino a due minuti). Se non funziona, RedGiant riapre la rete temporanea e dice perché.';

  @override
  String get fsLostTitle => 'Non trovo RedGiant';

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
  String get fsBrainTitle => 'Come deve pensare RedGiant?';

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
      'Ho letto le condizioni del provider: l\'abbonamento lo uso io, sul mio RedGiant.';

  @override
  String get fsBrainLater =>
      'I modelli su questa macchina, un tuo server e il resto sono nelle Impostazioni, dal computer o da «Tutte le impostazioni».';

  @override
  String get fsNamesTitle => 'I nomi';

  @override
  String get fsNamesLead =>
      'Chi guida il tuo RedGiant, e chi parla per lui nelle chat. Puoi cambiarli dopo.';

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
  String get fsDoneTitle => 'RedGiant è pronto';

  @override
  String get fsDoneLead =>
      'La rete temporanea è chiusa: RedGiant è sulla tua rete di casa, e questo dispositivo è collegato.';

  @override
  String get fsDoneMaintenance =>
      'RedGiant è di nuovo sulla sua nuova rete, e questo dispositivo è collegato.';

  @override
  String get fsDoneMore =>
      'Il resto del primo avvio (copie, chat, accesso da fuori…) è nella pagina, quando vuoi: «Impostazioni di RedGiant» › «Tutte le impostazioni».';

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
  String get homeErrBusy => 'RedGiant si sta già collegando a una rete: aspetta un momento.';

  @override
  String get homeErrWifiOff => 'Il Wi-Fi non è attivo su RedGiant.';

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
  String get pushOff => 'Non ancora attive per questo dispositivo.';

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
  String get updNowTitle => 'Aggiornare RedGiant?';

  @override
  String updNowBody(String version) {
    return 'RedGiant installa la $version e si riavvia: per qualche minuto non risponde, poi l\'app si ricollega da sola.';
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
  String get updStepWait => 'Attesa che RedGiant risponda';

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
    return 'Fermato: $name';
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
}
