# PROGETTO: ON MY WAY (Safety & Connection)

**Concept:** Una Live Activity "Caring" che permette ai partner di condividere il rientro a casa in tempo reale tramite Dynamic Island, senza tracciamento 24/7.

---

## 1. STACK TECNOLOGICO COMPLETO

### Client iOS (Frontend)

- **Linguaggio:** Swift 5.9+
- **Target Minimo:** iOS 17.0 (Necessario per `@Observable`, `CLMonitor` e stabilità WidgetKit)
- **UI Framework:** SwiftUI (Lifecycle 100%)
- **Gestione Stato:** Swift Observation (`@Observable`)
- **Apple Frameworks:**
    - **ActivityKit:** Gestione Dynamic Island e Lock Screen Widget
    - **CoreLocation:** Tracciamento GPS in background + `CLMonitor` per geofencing persistente
    - **MapKit:** Calcolo ETA, distanza e snapshot mappa
    - **BackgroundTasks:** Gestione processi quando l'app è sospesa

### Backend (Firebase Serverless)

- **Authentication:** Firebase Auth (Sign in with Apple / Anonimo per MVP)
- **Database:** Cloud Firestore (NoSQL) con dati denormalizzati per performance
- **Backend Logic:** Firebase Cloud Functions (2nd Gen, Node.js/TypeScript)
- **Push Notifications:** Firebase Cloud Messaging (FCM) per notifiche standard

### Infrastruttura Esterna

- **Apple APNs:** Canale di trasporto per gli aggiornamenti Live Activity
- **Apple Maps Server:** API sottostante a MapKit per il calcolo rotte

---

## 2. STRUTTURA DEL PROGETTO (File Tree)

Il progetto segue l'architettura **"Pragmatic Modern SwiftUI"** (Feature-based + Centralized State).

```
OnMyWay/
├── App/
│   ├── OnMyWayApp.swift              // Entry Point: Inietta AppState e Container
│   ├── AppDelegate.swift             // Configurazione Firebase, APNs, State Restoration
│   └── AppDependencyContainer.swift  // Dependency Injection (Singletons)
│
├── Core/
│   ├── State/
│   │   └── AppState.swift            // Single Source of Truth (Observable)
│   │
│   ├── Data/
│   │   ├── FirestoreSchema.swift     // Costanti Type-Safe per Collezioni e Campi
│   │   ├── FirestoreService.swift    // CRUD generico su Firestore
│   │   └── FirestoreListeners.swift  // Listeners real-time per Trip e Token
│   │
│   ├── Models/
│   │   ├── User.swift                // Modello Utente (include partnerFcmToken denormalizzato)
│   │   ├── Pair.swift                // Modello Coppia (relazione permanente)
│   │   ├── PairingCode.swift         // Modello Codice temporaneo (solo primo pairing)
│   │   ├── Trip.swift                // Modello Viaggio
│   │   └── AppError.swift            // Gestione Errori Custom
│   │
│   ├── Managers/
│   │   ├── AuthManager.swift         // Gestione Login/Logout Firebase Auth
│   │   ├── PairingManager.swift      // Collegamento partner (one-time)
│   │   ├── NotificationManager.swift // Permessi notifiche e Token FCM
│   │   ├── LocationManager.swift     // CoreLocation Wrapper + Adaptive Accuracy
│   │   ├── GeofenceManager.swift     // CLMonitor per geofencing persistente (iOS 17+)
│   │   ├── TripManager.swift         // Logica viaggio (Start/Update/Complete)
│   │   ├── TripStateRestorer.swift   // Recovery dopo app kill/crash
│   │   ├── ActivityManager.swift     // ActivityKit Wrapper per Live Activity
│   │   └── FunctionsManager.swift    // Client per Cloud Functions
│   │
│   └── Utilities/
│       ├── Logger.swift              // Logging centralizzato
│       ├── Permissions.swift         // Helper verifica permessi sistema
│       └── OfflineQueue.swift        // Coda per richieste offline
│
├── UI/
│   ├── Navigation/
│   │   └── AppRouter.swift           // Router basato su NavigationStack e AppState
│   │
│   ├── Common/
│   │   ├── Styles/                   // Design System (Colors, Fonts, Gradients)
│   │   └── Components/               // Componenti riutilizzabili (Buttons, Cards, Maps)
│   │
│   └── Features/
│       ├── Onboarding/               // Welcome, Permissions
│       ├── Pairing/                  // Genera Codice / Inserisci Codice (one-time)
│       ├── Home/                     // Dashboard principale
│       ├── ActiveTrip/               // UI durante il viaggio (include stato "Connecting...")
│       └── Settings/                 // Impostazioni e Unpair
│
├── Shared/                           // Target Membership: App + WidgetExtension
│   ├── ActivityAttributes.swift      // Definizione dati Live Activity
│   ├── Constants.swift               // Configurazioni e chiavi
│   └── Extensions/                   // Date+Formatting, GeoPoint+CoreLocation
│
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings
    ├── Info.plist                    // Permessi e Background Modes
    └── GoogleService-Info.plist      // Configurazione Firebase


OnMyWayWidget/                        // Widget Extension Target
├── OnMyWayWidgetBundle.swift
├── TripLiveActivity.swift
└── Info.plist
```

---

## 3. MODELLI DATI E SCHEMA FIRESTORE

### A. Struttura Database (con Denormalizzazione)

**Collection: `users/{userId}`**

Contiene i dati di ogni utente registrato. I dati del partner sono **denormalizzati** per evitare letture extra durante l'avvio del viaggio.

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| uid | string | ID utente Firebase Auth |
| displayName | string | Nome visualizzato |
| partnerId | string? | ID del partner collegato (null se non paired) |
| partnerDisplayName | string? | **DENORMALIZZATO** Nome del partner |
| partnerFcmToken | string? | **DENORMALIZZATO** Token FCM del partner (per notifiche dirette) |
| pairId | string? | ID del documento Pair (null se non paired) |
| homeLocation | GeoPoint | Coordinate di casa |
| fcmToken | string | Token Firebase Cloud Messaging proprio |
| activityPushToken | string? | Token APNs per Live Activity (temporaneo durante viaggio) |
| createdAt | Timestamp | Data creazione account |

**Nota sulla denormalizzazione:** Quando il partner aggiorna il suo `fcmToken`, una Cloud Function aggiorna automaticamente il campo `partnerFcmToken` nell'altro utente. Questo permette di avere tutti i dati necessari per iniziare un viaggio senza fare query aggiuntive.

**Collection: `pairs/{pairId}`**

Documento creato una sola volta quando due utenti si collegano. Rappresenta la relazione permanente tra i partner.

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| user1Id | string | ID del primo utente (chi ha generato il codice) |
| user2Id | string | ID del secondo utente (chi ha inserito il codice) |
| createdAt | Timestamp | Data del pairing |

**Collection: `pairingCodes/{code}`**

Documenti temporanei usati solo durante il processo di pairing iniziale. Vengono eliminati automaticamente dopo l'uso o alla scadenza.

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| creatorId | string | ID di chi ha generato il codice |
| createdAt | Timestamp | Data creazione |
| expiresAt | Timestamp | Scadenza (5 minuti dalla creazione) |

**Collection: `trips/{tripId}`**

Documento creato ogni volta che un utente inizia un viaggio. Viene aggiornato durante il tragitto e completato all'arrivo.

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| travelerId | string | ID di chi sta viaggiando |
| partnerId | string | ID del partner che riceve gli update |
| pairId | string | ID della coppia |
| status | string | Stato: "waiting_token", "active", "arrived", "cancelled" |
| startLocation | GeoPoint | Punto di partenza |
| destination | GeoPoint | Destinazione (casa) |
| currentLocation | GeoPoint | Posizione attuale (aggiornata in tempo reale) |
| currentProgress | number | Progresso 0.0 → 1.0 |
| currentEta | Timestamp | Orario stimato di arrivo |
| activityToken | string? | Token APNs della Live Activity del partner |
| startedAt | Timestamp | Inizio viaggio |
| completedAt | Timestamp? | Fine viaggio (null se in corso) |

**Nota sullo status:** Il nuovo stato `waiting_token` indica che il viaggio è stato creato ma il viaggiatore sta aspettando che il partner scriva il token della Live Activity. Solo quando lo status diventa `active` inizia il loop di aggiornamenti.

### B. Activity Attributes (Live Activity)

La Live Activity richiede una struttura dati divisa in due parti:

**Dati Statici** (non cambiano durante il viaggio):
- Nome del viaggiatore
- Nome della destinazione ("Casa")

**Dati Dinamici** (ContentState, aggiornati in tempo reale):
- Progress: percentuale di completamento (0.0 - 1.0)
- ETA String: tempo rimanente formattato ("12 min")
- Distance Remaining: distanza rimanente formattata ("1.5 km")

---

## 4. DESCRIZIONE COMPONENTI CHIAVE

### A. AppState (Single Source of Truth)

È l'oggetto Observable centrale che contiene tutto lo stato dell'applicazione. Tutti i componenti UI osservano questo stato e reagiscono ai cambiamenti.

**Proprietà principali:**
- `currentUser`: l'utente autenticato con dati denormalizzati del partner (null se non loggato)
- `partner`: riferimento al partner collegato (null se non paired)
- `pairId`: ID della relazione di coppia
- `activeTrip`: viaggio in corso dell'utente corrente (null se non sta viaggiando)
- `partnerTrip`: viaggio in corso del partner (null se il partner non sta viaggiando)
- `tripConnectionState`: stato della connessione con il partner durante il viaggio
- `error`: eventuale errore da mostrare all'utente

**Trip Connection State (nuovo):**
- `idle`: nessun viaggio in corso
- `waitingForPartnerToken`: viaggio creato, in attesa che il partner avvii la Live Activity
- `connected`: token ricevuto, loop aggiornamenti attivo
- `offline`: connessione persa, update in coda

**Proprietà computate:**
- `isAuthenticated`: true se currentUser non è null
- `isPaired`: true se partner non è null (stato permanente dopo primo pairing)
- `hasActiveTrip`: true se c'è un viaggio in corso (proprio o del partner)
- `canSendUpdates`: true solo se tripConnectionState è "connected"

### B. AppRouter (Navigazione)

Gestisce la navigazione dell'app basandosi sullo stato di AppState. Determina automaticamente quale schermata mostrare.

**Logica di navigazione:**
1. Se `isAuthenticated` è false → mostra Onboarding
2. Se `isPaired` è false → mostra Pairing (solo la prima volta)
3. Altrimenti → mostra Home (uso quotidiano normale)

La schermata di Pairing viene mostrata una sola volta nella vita dell'app, dopo l'autenticazione iniziale. Una volta che i partner sono collegati, l'app va sempre direttamente alla Home.

### C. AuthManager

Gestisce l'autenticazione tramite Firebase Auth. Supporta Sign in with Apple come metodo principale e autenticazione anonima per testing/MVP.

**Responsabilità:**
- Login e logout
- Persistenza della sessione
- Creazione documento utente su Firestore al primo accesso
- Osservazione dello stato di autenticazione
- Aggiornamento FCM token (sia proprio che denormalizzato nel partner)

### D. PairingManager

Gestisce il collegamento one-time tra due partner tramite codice numerico a 6 cifre.

**Flusso Genera Codice (User A):**
1. Genera un codice casuale di 6 cifre
2. Crea documento in `pairingCodes/{code}` con TTL di 5 minuti
3. Mostra il codice all'utente
4. Avvia timer per auto-eliminazione alla scadenza

**Flusso Inserisci Codice (User B):**
1. Legge il documento `pairingCodes/{code}`
2. Verifica che non sia scaduto e che il creatore non sia se stesso
3. Esegue una batch write atomica che include la denormalizzazione:
   - Crea documento `pairs/{pairId}`
   - Aggiorna `users/A` con partnerId, pairId, partnerDisplayName, partnerFcmToken
   - Aggiorna `users/B` con partnerId, pairId, partnerDisplayName, partnerFcmToken
   - Elimina il documento `pairingCodes/{code}`

**Flusso Unpair (opzionale, da Settings):**
1. Mostra dialog di conferma
2. Esegue batch write:
   - Rimuove tutti i campi partner da entrambi gli utenti
   - Elimina il documento Pair
3. Entrambi gli utenti tornano allo stato "non paired"

### E. LocationManager (con Adaptive Accuracy)

Wrapper attorno a CoreLocation che gestisce il tracciamento GPS con accuratezza adattiva per risparmiare batteria.

**Adaptive Accuracy Logic:**

| Distanza da destinazione | Accuracy Mode | Intervallo Update |
|--------------------------|---------------|-------------------|
| > 5 km | kCLLocationAccuracyKilometer | ~60 secondi |
| 2-5 km | kCLLocationAccuracyHundredMeters | ~30 secondi |
| < 2 km | kCLLocationAccuracyBest | ~15 secondi |

**Funzionamento:**
- All'avvio del viaggio, calcola la distanza totale
- Imposta l'accuracy iniziale in base alla distanza
- Ad ogni update di posizione, ricalcola la distanza rimanente
- Se la distanza scende sotto una soglia, aumenta l'accuracy
- Notifica il TripManager del cambio per adeguare la frequenza degli update

**Configurazione Background:**
- `allowsBackgroundLocationUpdates = true`
- `pausesLocationUpdatesAutomatically = false`
- `showsBackgroundLocationIndicator = true` (indicatore blu nella status bar)

### F. GeofenceManager (Persistente con CLMonitor)

Nuovo componente che gestisce il geofencing a livello di sistema usando `CLMonitor` (iOS 17+). Questo garantisce che l'arrivo venga rilevato anche se l'app viene terminata.

**Perché CLMonitor invece di startMonitoring(for:):**
- `CLMonitor` è la nuova API iOS 17 che sostituisce il vecchio geofencing
- Persiste automaticamente tra riavvii dell'app
- Consegna eventi anche se l'app è stata terminata dal sistema
- Supporta async/await nativamente

**Funzionamento:**
1. All'avvio del viaggio, registra una "condition" di tipo CircularGeographicCondition
2. Il raggio è 150 metri attorno alla destinazione
3. Se l'app viene terminata, iOS la risveglia in background quando l'utente entra nella zona
4. Nel risveglio, l'app ha pochi secondi per chiamare la Cloud Function di completamento
5. La condizione viene rimossa dopo il completamento o la cancellazione del viaggio

**State Persistence:**
- L'ID della condizione attiva viene salvato in UserDefaults
- Al lancio dell'app, GeofenceManager controlla se c'è una condizione attiva
- Se sì, verifica lo stato attuale e recupera il viaggio se necessario

### G. TripStateRestorer (Recovery dopo App Kill)

Nuovo componente che gestisce il recupero dello stato dopo che l'app è stata terminata o è crashata.

**Scenari gestiti:**

1. **App terminata durante viaggio attivo:**
   - Al rilancio, controlla se esiste un Trip con status "active" o "waiting_token" per l'utente corrente
   - Se sì, recupera il Trip da Firestore
   - Riattiva il LocationManager e il GeofenceManager
   - Riprende il loop di aggiornamenti

2. **App risvegliata da geofence:**
   - Riceve l'evento di ingresso nella zona
   - Recupera il tripId da UserDefaults
   - Chiama TripManager.completeTrip() con il tripId
   - La Cloud Function notifica il partner

3. **App crashata:**
   - Stesso flusso del caso 1
   - Il Trip rimane in stato "active" su Firestore
   - Al rilancio, l'utente vede la UI di viaggio in corso
   - Può continuare o cancellare manualmente

**Dati persistiti localmente:**
- `activeTripId`: ID del viaggio in corso (UserDefaults)
- `activeGeofenceConditionId`: ID della condizione CLMonitor (UserDefaults)
- `lastKnownLocation`: ultima posizione nota (UserDefaults, per recovery)

### H. TripManager (con Token Listener)

Contiene tutta la logica di business relativa ai viaggi, inclusa la gestione della race condition del token.

**Start Trip (con gestione race condition):**
1. Ottiene la posizione corrente da LocationManager
2. Calcola la rotta verso casa usando MapKit
3. Crea documento Trip su Firestore con status **"waiting_token"** (non "active")
4. Salva tripId in UserDefaults per recovery
5. Configura il geofence persistente sulla destinazione (via GeofenceManager)
6. **Attiva un Firestore Listener sul documento Trip**
7. Mostra UI "In attesa del partner..." / "Connecting..."
8. La Cloud Function notifica il partner (push FCM)
9. Il partner avvia la Live Activity e scrive il token su Firestore
10. **Il Listener rileva il campo activityToken popolato**
11. Salva il token in memoria locale
12. Aggiorna status a "active"
13. Avvia il loop di aggiornamenti GPS
14. Avvia la Live Activity locale

**Il Listener sul Token:**
- Osserva solo il campo `activityToken` del documento Trip
- Timeout di 60 secondi: se il partner non risponde, mostra errore "Partner non raggiungibile"
- L'utente può scegliere di continuare senza Live Activity del partner o cancellare

**Update Loop (ogni N secondi, basato su accuracy):**
1. Riceve aggiornamento posizione da LocationManager
2. Verifica che `canSendUpdates` sia true (token presente e online)
3. Ricalcola progresso e ETA
4. Se online: chiama Cloud Function per aggiornare Live Activity del partner
5. Se offline: salva update in OfflineQueue
6. Aggiorna UI locale

**Complete Trip (automatico via geofence):**
1. Riceve callback da GeofenceManager (entrato nella zona)
2. Aggiorna Firestore: status = "arrived", completedAt = now
3. Rimuove il geofence
4. Ferma il tracciamento GPS
5. Pulisce UserDefaults (tripId, geofenceId)
6. La Cloud Function invia push finale al partner per chiudere la Live Activity

### I. ActivityManager

Wrapper attorno ad ActivityKit per gestire le Live Activities.

**Responsabilità:**
- Verifica che il dispositivo supporti Live Activities
- Avvio Live Activity con attributi iniziali
- Aggiornamento ContentState (progresso, ETA, distanza)
- Terminazione Live Activity (normale o con errore)
- Gestione del pushToken per ricevere aggiornamenti remoti
- Scrittura del pushToken su Firestore quando si riceve un viaggio del partner

### J. NotificationManager

Gestisce i permessi per le notifiche e il token FCM.

**Responsabilità:**
- Richiesta permessi notifiche all'utente
- Registrazione per notifiche remote
- Ricezione e salvataggio del token FCM
- Aggiornamento token su Firestore quando cambia
- **Trigger dell'aggiornamento denormalizzato nel partner** (via Cloud Function)

### K. OfflineQueue

Gestisce la resilienza offline salvando gli aggiornamenti in coda quando non c'è connessione.

**Funzionamento:**
- Monitora lo stato della connessione tramite Network framework
- Quando offline: salva gli update in UserDefaults (mantiene solo l'ultimo per trip)
- Quando torna online: invia l'update più recente e svuota la coda
- Gli update sono idempotenti: inviare lo stesso update più volte non causa problemi

### L. FirestoreListeners

Nuovo componente che centralizza i listener real-time di Firestore.

**Listeners attivi:**
- `tripTokenListener`: osserva il campo activityToken del Trip corrente
- `partnerTripListener`: osserva i Trip del partner per mostrare quando sta viaggiando
- `userDataListener`: osserva il proprio documento user per sync dei dati denormalizzati

---

## 5. FLUSSI LOGICI (End-to-End Workflows)

### A. Primo Utilizzo e Pairing (One-Time)

Il pairing avviene una sola volta quando due utenti decidono di collegarsi. Dopo il pairing, la relazione è permanente fino a eventuale unpair manuale.

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRIMO UTILIZZO (Una Tantum)                  │
└─────────────────────────────────────────────────────────────────┘

    User A (nuovo)                          User B (nuovo)
         │                                       │
         ▼                                       │
    1. Installa app                              │
         │                                       │
         ▼                                       │
    2. Onboarding (permessi)                     │
         │                                       │
         ▼                                       │
    3. Sign in with Apple                        │
         │                                       │
         ▼                                       │
    4. Schermata Pairing                         │
       "Collega il tuo partner"                  │
         │                                       │
         ▼                                       │
    5. Tap "Genera Codice"                       │
         │                                       │
         ▼                                       │
    6. Mostra codice "482910"                    │
       (valido 5 minuti)                         │
         │                                       ▼
         │                               1. Installa app
         │                                       │
         │                                       ▼
         │                               2. Onboarding
         │                                       │
         │                                       ▼
         │                               3. Sign in with Apple
         │                                       │
         │                                       ▼
         │                               4. Schermata Pairing
         │                                  "Ho già un codice"
         │                                       │
         │                                       ▼
         │◄─────────────────────────────  5. Inserisce "482910"
         │                                       │
         ▼                                       ▼
    ┌─────────────────────────────────────────────────┐
    │              PAIRING COMPLETATO                 │
    │                                                 │
    │  • Creato documento pairs/{pairId}              │
    │  • User A.partnerId = B, partnerFcmToken = ... │
    │  • User B.partnerId = A, partnerFcmToken = ... │
    │  • Dati partner DENORMALIZZATI in entrambi     │
    │  • Codice "482910" eliminato                    │
    │                                                 │
    │  QUESTA OPERAZIONE AVVIENE UNA SOLA VOLTA      │
    └─────────────────────────────────────────────────┘
         │                                       │
         ▼                                       ▼
    Home Screen                             Home Screen
    (vede partner B)                        (vede partner A)
```

### B. Utilizzo Quotidiano (Post-Pairing)

Dopo il pairing iniziale, ogni volta che l'utente apre l'app va direttamente alla Home. Non deve più passare dalla schermata di pairing.

```
┌─────────────────────────────────────────────────────────────────┐
│                    UTILIZZO QUOTIDIANO                          │
│              (Ogni giorno dopo il primo pairing)                │
└─────────────────────────────────────────────────────────────────┘

    User A                                  User B
         │                                       │
         ▼                                       │
    1. Apre app                                  │
         │                                       │
         ▼                                       │
    2. TripStateRestorer verifica:               │
       - C'è un viaggio attivo da recuperare?    │
       - No → procedi normale                    │
         │                                       │
         ▼                                       │
    3. AppRouter verifica:                       │
       - isAuthenticated? ✓                      │
       - isPaired? ✓                             │
         │                                       │
         ▼                                       │
    4. Va direttamente a HOME                    │
       (nessun pairing richiesto)                │
         │                                       │
         ▼                                       │
    5. Vede il bottone                           │
       "Torno a Casa"                            │
```

### C. Start Trip (con Token Handshake)

Quando l'utente preme "Torno a Casa", inizia il flusso di viaggio con gestione della race condition.

```
┌─────────────────────────────────────────────────────────────────┐
│                    START TRIP (con Token Handshake)             │
└─────────────────────────────────────────────────────────────────┘

    User A (Viaggiatore)                    User B (Partner)
         │                                       │
         ▼                                       │
    1. Tap "Torno a Casa"                        │
         │                                       │
         ▼                                       │
    2. TripManager.startTrip()                   │
         │                                       │
         ├── Ottiene posizione corrente          │
         ├── Calcola rotta (MapKit)              │
         ├── Crea Trip su Firestore              │
         │   └── status: "waiting_token" ◄───────┼── NUOVO STATUS
         ├── Salva tripId in UserDefaults        │
         ├── Configura geofence (CLMonitor)      │
         │                                       │
         ▼                                       │
    3. UI mostra:                                │
       "In attesa del partner..."                │
       [Indicatore di caricamento]               │
         │                                       │
         ▼                                       │
    4. Attiva Firestore Listener                 │
       sul campo "activityToken"                 │
         │                                       │
         ▼                                       │
    5. Cloud Function (onCreate)                 │
         │                                       │
         ├── Legge Trip                          │
         ├── Usa partnerFcmToken (denormalizzato)│
         │   (NESSUNA QUERY EXTRA!)              │
         │                                       │
         └── Invia push FCM ────────────────────►│
                                                 │
                                                 ▼
                                        6. Riceve push
                                                 │
                                                 ▼
                                        7. Avvia Live Activity
                                                 │
                                                 ▼
                                        8. Ottiene pushToken
                                                 │
                                                 ▼
                                        9. Scrive token su Firestore
                                           trips/{id}.activityToken = "..."
         │                                       │
         │◄──────────────────────────────────────┘
         │   Listener rileva cambio!
         ▼
    10. Token ricevuto!
         │
         ├── Salva token in memoria
         ├── Aggiorna status: "active"
         ├── Avvia tracciamento GPS
         ├── Avvia Live Activity locale
         │
         ▼
    11. UI mostra:
        "In viaggio verso casa"
        [Progress bar, ETA]
         │
         ▼
    12. Inizia Update Loop
```

**Gestione Timeout Token:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    TIMEOUT (Partner non risponde)               │
└─────────────────────────────────────────────────────────────────┘

    User A (Viaggiatore)
         │
         ▼
    1. Listener attivo da 60 secondi
       Token ancora null
         │
         ▼
    2. Mostra dialog:
       "Il tuo partner non ha risposto"
       
       [Continua senza notifiche]  [Riprova]  [Annulla]
         │
         ├── Continua: status → "active", loop senza push al partner
         ├── Riprova: resetta timer, rinvia notifica FCM
         └── Annulla: elimina Trip, torna a Home
```

### D. Update Loop (con Adaptive Accuracy)

Durante il viaggio, la posizione viene aggiornata con frequenza adattiva.

```
┌─────────────────────────────────────────────────────────────────┐
│               UPDATE LOOP (Adaptive Accuracy)                   │
└─────────────────────────────────────────────────────────────────┘

    User A (in viaggio)
         │
         ▼
    1. LocationManager riceve nuova posizione
         │
         ▼
    2. Calcola distanza rimanente
         │
         ├─── > 5 km ───────────────────────────┐
         │    Accuracy: Kilometer               │
         │    Prossimo update: ~60 sec          │
         │                                      │
         ├─── 2-5 km ───────────────────────────┤
         │    Accuracy: HundredMeters           │
         │    Prossimo update: ~30 sec          │
         │                                      │
         └─── < 2 km ───────────────────────────┤
              Accuracy: Best                    │
              Prossimo update: ~15 sec          │
         │                                      │
         ▼◄─────────────────────────────────────┘
    3. TripManager.updateProgress()
         │
         ├── Verifica canSendUpdates == true
         │   (token presente E online)
         │
         ▼
    4. Se può inviare:
         │
         ├── FunctionsManager.updateLiveActivity()
         │        │
         │        ▼
         │   Cloud Function firma e invia ad APNs
         │        │
         │        ▼
         │   Live Activity di B si aggiorna
         │
         ▼
    5. Se offline:
         │
         ├── OfflineQueue.enqueue(update)
         ├── UI mostra indicatore "Offline"
         │
         ▼
    6. Aggiorna UI locale (progress, ETA)
         │
         ▼
    7. Attendi prossimo update (basato su accuracy)
         │
         └── Torna al punto 1
```

### E. End Trip (Geofence Persistente)

L'arrivo viene rilevato automaticamente tramite geofence, anche se l'app è stata terminata.

```
┌─────────────────────────────────────────────────────────────────┐
│              END TRIP (Geofence Persistente)                    │
└─────────────────────────────────────────────────────────────────┘

CASO 1: App in foreground/background
────────────────────────────────────

    User A (sta arrivando)
         │
         ▼
    1. Entra nel raggio di 150m da casa
         │
         ▼
    2. GeofenceManager (CLMonitor) rileva evento
         │
         └── Callback: onConditionMet()
         │
         ▼
    3. TripManager.completeTrip()
         │
         ├── Aggiorna Firestore:
         │   └── status: "arrived"
         │   └── completedAt: timestamp
         │
         ├── Rimuove condizione CLMonitor
         ├── Ferma tracciamento GPS
         ├── Pulisce UserDefaults
         └── Termina Live Activity locale
         │
         ▼
    4. Cloud Function (onUpdate)
         │
         ├── Rileva status: active → arrived
         └── Invia push APNs event: "end"
         │
         ▼
    5. Live Activity di B si chiude
       mostrando "Arrivato! 🏠"


CASO 2: App terminata dal sistema
─────────────────────────────────

    User A (app killed, sta arrivando)
         │
         ▼
    1. Entra nel raggio di 150m da casa
         │
         ▼
    2. iOS rileva evento geofence (CLMonitor)
         │
         ▼
    3. iOS risveglia l'app in background
       (tempo limitato: ~10 secondi)
         │
         ▼
    4. AppDelegate.didFinishLaunching
         │
         ├── TripStateRestorer.checkPendingGeofence()
         ├── Legge tripId da UserDefaults
         │
         ▼
    5. TripManager.completeTrip(tripId)
         │
         ├── Chiamata rapida a Firestore
         └── Chiamata a Cloud Function
         │
         ▼
    6. App torna in sospensione
         │
         ▼
    7. Cloud Function completa il flusso
       (notifica il partner)
```

### F. App Recovery (dopo Kill o Crash)

```
┌─────────────────────────────────────────────────────────────────┐
│                    APP RECOVERY                                 │
└─────────────────────────────────────────────────────────────────┘

    User A (riapre app dopo crash/kill)
         │
         ▼
    1. App Launch
         │
         ▼
    2. TripStateRestorer.restore()
         │
         ├── Legge activeTripId da UserDefaults
         │
         ├─── tripId == nil ─────────────────────┐
         │    Nessun viaggio da recuperare       │
         │    → Procedi normale                  │
         │                                       │
         └─── tripId != nil ─────────────────────┤
              │                                  │
              ▼                                  │
         3. Query Firestore: trips/{tripId}      │
              │                                  │
              ├─── status == "arrived" ──────────┤
              │    Viaggio già completato        │
              │    → Pulisci UserDefaults        │
              │    → Procedi normale             │
              │                                  │
              ├─── status == "cancelled" ────────┤
              │    Viaggio cancellato            │
              │    → Pulisci UserDefaults        │
              │    → Procedi normale             │
              │                                  │
              └─── status == "active" ───────────┤
                   │                             │
                   ▼                             │
              4. Recupera viaggio                │
                   │                             │
                   ├── Riattiva LocationManager  │
                   ├── Riattiva GeofenceManager  │
                   ├── Riavvia Update Loop       │
                   ├── Mostra UI ActiveTrip      │
                   │                             │
                   ▼                             │
              5. Continua viaggio normale        │
                                                 │
              ◄──────────────────────────────────┘
```

### G. Gestione Offline

L'app gestisce gracefully la perdita di connessione durante il viaggio.

```
┌─────────────────────────────────────────────────────────────────┐
│                    SCENARI OFFLINE                              │
└─────────────────────────────────────────────────────────────────┘

SCENARIO 1: Viaggiatore perde connessione temporaneamente
─────────────────────────────────────────────────────────────────
• tripConnectionState passa a "offline"
• Gli update vengono salvati in OfflineQueue
• Viene mantenuto solo l'ultimo update (non serve lo storico)
• La Live Activity del partner mostra l'ultimo stato noto
• UI viaggiatore mostra indicatore "Offline - aggiornamenti in pausa"
• Quando torna online, viene inviato l'update più recente
• Il partner vede la posizione "saltare" all'ultima nota

SCENARIO 2: Viaggiatore arriva a casa mentre è offline
─────────────────────────────────────────────────────────────────
• Il geofence CLMonitor funziona localmente (non richiede internet)
• TripManager segna il viaggio come completato localmente
• Il completamento viene messo in coda
• Quando torna online, Firestore viene aggiornato
• Cloud Function invia il push finale al partner
• La Live Activity del partner si chiude (con ritardo)

SCENARIO 3: Partner perde connessione
─────────────────────────────────────────────────────────────────
• I push APNs vengono accodati da Apple
• Apple conserva l'ultimo push per ogni Live Activity
• Il partner vedrà lo stato più recente appena riconnesso

SCENARIO 4: Connessione instabile (on/off frequente)
─────────────────────────────────────────────────────────────────
• OfflineQueue previene accumulo di update duplicati
• Mantiene solo l'ultimo update per ogni trip
• Gli update sono idempotenti (sicuri da reinviare)
• Nessun rischio di spam al partner
```

### H. Unpair (Opzionale)

Se un utente vuole scollegarsi dal partner, può farlo dalle impostazioni.

```
┌─────────────────────────────────────────────────────────────────┐
│                         UNPAIR                                  │
│                  (Da Settings, opzionale)                       │
└─────────────────────────────────────────────────────────────────┘

    User A (vuole scollegarsi)
         │
         ▼
    1. Settings > "Scollega Partner"
         │
         ▼
    2. Dialog di conferma
       "Sei sicuro? Dovrai generare un nuovo
        codice per ricollegarti"
         │
         ▼
    3. Conferma
         │
         ▼
    4. PairingManager.unpair()
         │
         ├── Batch write atomica:
         │   ├── Rimuove tutti i campi partner da users/A
         │   ├── Rimuove tutti i campi partner da users/B
         │   └── Elimina documento pairs/{pairId}
         │
         ▼
    5. Entrambi gli utenti:
         │
         ├── AppState.partner = nil
         ├── AppState.isPaired = false
         │
         ▼
    6. AppRouter naviga a schermata Pairing
       (possono ri-collegarsi con nuovo codice)
```

---

## 6. BACKEND: CLOUD FUNCTIONS

### Struttura Cartella

```
functions/
├── src/
│   ├── index.ts                    // Entry point
│   ├── onTripCreated.ts            // Trigger: notifica partner all'inizio viaggio
│   ├── onTripUpdated.ts            // Trigger: gestisce arrivo (status changed)
│   ├── onUserFcmTokenChanged.ts    // Trigger: sincronizza token denormalizzato
│   ├── updateLiveActivity.ts       // HTTPS Callable: aggiorna Live Activity
│   └── cleanupExpiredCodes.ts      // Scheduled: pulisce codici pairing scaduti
│
├── lib/
│   └── apnsClient.ts               // Wrapper per invio push APNs
│
├── keys/
│   └── AuthKey_XXXX.p8             // Chiave Apple (NON committare)
│
├── package.json
├── tsconfig.json
└── .env                            // Variabili ambiente (NON committare)
```

### Descrizione Functions

**onTripCreated (Firestore Trigger)**

Si attiva quando viene creato un nuovo documento in `trips/`. Responsabilità:
- Legge i dati del viaggio appena creato
- **Usa il partnerFcmToken già presente nel documento Trip** (passato dal client, denormalizzato)
- NON fa query aggiuntive per trovare il partner
- Invia una push notification FCM per avvisare che il partner sta tornando

**onTripUpdated (Firestore Trigger)**

Si attiva quando un documento in `trips/` viene modificato. Responsabilità:
- Controlla se lo status è cambiato da "active" ad "arrived"
- Se sì, legge l'activityToken dal documento
- Invia push APNs con event "end" per chiudere la Live Activity del partner

**onUserFcmTokenChanged (Firestore Trigger)**

Si attiva quando il campo `fcmToken` di un utente cambia. Responsabilità:
- Trova il partner dell'utente (se esiste)
- Aggiorna il campo `partnerFcmToken` nel documento del partner
- Mantiene i dati denormalizzati sincronizzati

**updateLiveActivity (HTTPS Callable)**

Funzione chiamata direttamente dall'app del viaggiatore per aggiornare la Live Activity del partner. Responsabilità:
- Verifica che l'utente sia autenticato
- Riceve: pushToken, progress, eta, distanceRemaining
- Costruisce il payload APNs nel formato richiesto da ActivityKit
- Firma il payload con la chiave .p8 di Apple
- Invia ad Apple APNs
- Restituisce successo o errore

**cleanupExpiredCodes (Scheduled)**

Funzione pianificata che gira ogni ora. Responsabilità:
- Query su `pairingCodes/` dove expiresAt < now
- Elimina tutti i documenti scaduti
- Previene accumulo di codici non utilizzati

### Payload APNs per Live Activity

Il payload deve seguire il formato specifico di Apple per gli aggiornamenti Live Activity:

**Update (durante viaggio):**
- aps.timestamp: Unix timestamp corrente
- aps.event: "update"
- aps.content-state: oggetto con progress, etaString, distanceRemaining

**End (arrivo):**
- aps.timestamp: Unix timestamp corrente
- aps.event: "end"
- aps.content-state: oggetto finale (progress: 1.0, etaString: "Arrivato")

---

## 7. SICUREZZA: FIRESTORE SECURITY RULES

Le Security Rules sono fondamentali per proteggere i dati degli utenti. Senza regole appropriate, chiunque potrebbe leggere la posizione e l'indirizzo di casa di altri utenti.

### Principi di Sicurezza

1. **Autenticazione obbligatoria:** Tutte le operazioni richiedono un utente autenticato
2. **Ownership:** Gli utenti possono modificare solo i propri dati
3. **Partnership:** I partner possono leggere i dati relativi ai viaggi condivisi
4. **Minimo privilegio:** Ogni regola concede solo i permessi strettamente necessari

### Regole per Collection

**users/{userId}**
- READ: Solo l'utente stesso può leggere il proprio documento completo
- WRITE: Solo l'utente stesso può scrivere
- Eccezione: Il partnerId può leggere campi limitati (displayName) per la UI

**pairs/{pairId}**
- READ: Solo i due utenti che fanno parte della coppia
- CREATE: Chiunque autenticato (durante il pairing)
- DELETE: Solo i membri della coppia (durante unpair)
- UPDATE: Nessuno (il documento è immutabile dopo la creazione)

**pairingCodes/{code}**
- READ: Chiunque autenticato (necessario per verificare il codice)
- CREATE: Chiunque autenticato
- DELETE: Solo il creatore o tramite Cloud Function
- Nota: I codici scaduti vengono puliti da una scheduled function

**trips/{tripId}**
- READ: Solo il viaggiatore (travelerId) O il partner (partnerId)
- CREATE: Solo l'utente autenticato che si imposta come travelerId
- UPDATE travelerId: Solo il viaggiatore può aggiornare posizione e status
- UPDATE activityToken: Solo il partner può scrivere il token della Live Activity
- DELETE: Solo il viaggiatore può cancellare il proprio viaggio

### Validazioni Aggiuntive

- Il campo `travelerId` in un nuovo Trip deve corrispondere all'utente autenticato
- Il campo `partnerId` deve corrispondere al partnerId dell'utente autenticato
- Lo status può transitare solo in direzioni valide: waiting_token → active → arrived/cancelled
- Le coordinate (GeoPoint) devono essere valide (lat: -90/+90, lng: -180/+180)

---

## 8. CONFIGURAZIONE E CHECKLIST

### Xcode Project Settings

**Signing & Capabilities:**
- Background Modes: Location updates, Remote notifications, Background fetch
- Push Notifications: ON
- Maps: ON

**Info.plist Keys:**
- NSSupportsLiveActivities: YES
- NSLocationWhenInUseUsageDescription: messaggio per permesso location
- NSLocationAlwaysAndWhenInUseUsageDescription: messaggio per permesso background
- UIBackgroundModes: location, remote-notification, fetch

**Target Membership:**
- ActivityAttributes.swift deve appartenere sia al target App che al target Widget Extension

### Firebase Console

- Caricare chiave APNs (.p8) in Project Settings > Cloud Messaging
- Abilitare Authentication: Anonymous + Sign in with Apple
- Abilitare Cloud Firestore
- **Deployare le Security Rules** (fondamentale!)
- Creare gli indici Firestore necessari (verranno suggeriti al primo errore)
- Deployare Cloud Functions con: `firebase deploy --only functions`

### Apple Developer Portal

- Creare App ID con Push Notifications capability
- Generare chiave APNs (.p8) per Live Activities
- Configurare Sign in with Apple
- Annotare Team ID e Key ID per le Cloud Functions

---

## 9. ROADMAP SVILUPPO

| Fase | Funzionalità | Priorità |
|------|--------------|----------|
| **MVP** | Auth + Pairing + Start Trip + Live Activity base | 🔴 Alta |
| **v1.0** | Token handshake + Geofence CLMonitor + UI polish | 🔴 Alta |
| **v1.1** | Adaptive accuracy + Offline queue + State recovery | 🔴 Alta |
| **v1.2** | Security Rules + Denormalizzazione FCM token | 🔴 Alta |
| **v1.3** | Notifica "Sta tardando" + Timeout automatico | 🟡 Media |
| **v2.0** | Widget Home Screen + Complications watchOS | 🟢 Futura |
| **v2.1** | Multi-destinazione (lavoro, palestra, etc.) | 🟢 Futura |