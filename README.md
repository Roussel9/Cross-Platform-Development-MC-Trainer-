# MC Trainer Kami – Projektdokumentation

## 1. Einleitung

**MC Trainer Kami** ist ein universeller Multiple-Choice-Trainer für mobile Geräte. Die Anwendung ermöglicht es Nutzerinnen und Nutzern, Lernkarten („Karten“) in Modulen zu bearbeiten, Fortschritte zu verfolgen und Abzeichen (Achievements) zu sammeln.

### Was kann mit der Software gemacht werden?

- **Lernmodus**: Eine Lernkarte mit einem Text und 4–6 möglichen Antworten (mindestens eine richtig) wird angezeigt. Der Nutzer wählt eine oder mehrere Antworten und erhält sofort Rückmeldung. Bei falscher Antwort wird die korrekte Lösung angezeigt. Nach jeder Karte wird entweder die nächste angezeigt oder am Ende einer Runde eine Statistik.
- **Trainingsmodule**: Module können durchsucht und gelöscht werden.
- **Statistik**: Übersicht über alle Lernrunden und Fortschritte.
- **Achievements**: Abzeichen erhöhen die Motivation (z. B. Erstbesuch, Streak, Punktzahl).
- **6×-Meisterschaft**: Eine Karte wird nicht mehr angezeigt, wenn sie sechsmal hintereinander richtig beantwortet wurde. Bei einer falschen Antwort wird der Zähler zurückgesetzt.
- **Backend-Synchronisation**: Benutzerdaten (Profil, Fortschritt, Sessions, Achievements) werden in Supabase gespeichert und können geladen werden.
- **Server-Import**: Zusätzliche Module können von einem Server (Supabase) importiert werden.

Die App wurde in einem 4-köpfigen Team entwickelt, mit Git als Versionsverwaltung und Supabase als Backend und Datenbank.

---

## 2. Technische Umsetzung

### 2.1 Werkzeuge und Bibliotheken (Versionen)

| Werkzeug/Bibliothek | Version | Verwendung |
|--------------------|---------|------------|
| **Dart SDK** | ^3.9.2 | Programmiersprache |
| **Flutter** | SDK (>=3.35.0) | UI-Framework, plattformübergreifend |
| **supabase_flutter** | ^2.10.3 (2.10.3) | Backend: Auth, Datenbank, Storage |
| **provider** | ^6.1.5+1 | State-Management |
| **go_router** | ^17.0.0 | Routing/Navigation |
| **image_picker** | ^1.0.4 (1.2.1) | Profilbild / Avatar |
| **flutter_dotenv** | ^6.0.0 | Umgebungsvariablen (.env) |
| **json_annotation** / **json_serializable** | ^4.9.0 / ^6.11.3 | JSON-Serialisierung für Modelle |
| **share_plus** | ^12.0.1 | Teilen-Funktion |
| **intl** | ^0.19.0 | Internationalisierung / Formatierung |
| **flutter_lints** | ^5.0.0 | Linting / Code-Qualität |
| **build_runner** | ^2.10.4 | Code-Generierung (z. B. `*.g.dart`) |

### 2.2 Entwicklungsumgebung

- **IDE**:  Intellij und Android Studio mit Flutter- und Dart-Erweiterungen.
- **Flutter SDK** installieren und ins PATH aufnehmen: [flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install).
- **Git** für Klonen und Branches.

Vor dem ersten Start:

1. Repository klonen ( von GitLab).
2. Im Projektroot:  
   `flutter pub get`
3. Optional: `.env` im Projektroot anlegen (siehe Abschnitt „Konfiguration“).
4. Code-Generierung ausführen:  
   `dart run build_runner build --delete-conflicting-outputs`

### 2.3 Konfiguration

Für Supabase sind **URL** und **Anon Key** nötig. Diese können

- in einer `.env`-Datei im Projektroot stehen (mit `flutter_dotenv`), oder
- direkt in `lib/main.dart` bei `Supabase.initialize()` gesetzt werden (derzeit im Code).

Beispiel `.env`:

```env
SUPABASE_URL=https://<ihr-projekt>.supabase.co
SUPABASE_ANON_KEY=<ihr-anon-key>
```

Die `.env`-Datei sollte **nicht** versioniert werden (in `.gitignore` eintragen).

### 2.4 Projektstruktur

```
mc_trainer_kami/
├── lib/
│   ├── main.dart                 # Einstieg, Supabase-Init, Provider, Routen
│   ├── core/
│   │   ├── constants/            # app_colors.dart, app_strings.dart
│   │   ├── theme/               # app_theme.dart
│   │   └── widgets/             # AppBar, gemeinsame UI-Bausteine
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/          # Login, Register, AuthWrapper, ForgotPassword
│   │   │   └── services/        # auth_service.dart (Supabase Auth)
│   │   ├── home/
│   │   │   ├── screens/         # HomeScreen, NotificationScreen, ProfileScreen
│   │   │   └── widgets/         # CategoryCard, QuizCard
│   │   └── modules/
│   │       └── screens/         # ModuleList, LessonList, QuizScreen, QuizResult
│   ├── models/                  # achievement_data, app_notifications, lernen_module, module_data
│   ├── provider/                # backend_provider.dart, home_provider.dart
│   └── widgets/                 # custom_button etc.
├── assets/images/               # Hintergrundbilder etc.
├── android/, ios/, web/, …      # Plattform-spezifisch
├── pubspec.yaml
├── analysis_options.yaml        # Linter-/Analyzer-Regeln
└── README.md
```

### 2.5 Projektstandards

- **Sprache**: Dart/Flutter, UI-Texte teils Deutsch, teils Englisch.
- **State-Management**: Provider (`ChangeNotifier`), zentraler Datenzugriff über `BackendProvider` und `HomeProvider`.
- **Linting**: `analysis_options.yaml` nutzt `package:flutter_lints/flutter.yaml`. Analyse per `flutter analyze`.

### 2.6 App zum Laufen bringen

1. **Abhängigkeiten installieren**  
   `flutter pub get`

2. **Code-Generierung (z. B. für `lernen_module.g.dart`)**  
   `dart run build_runner build --delete-conflicting-outputs`

3. **Supabase**
    - Projekt in Supabase anlegen, Tabellen/Schema bereitstellen (vgl. Abschnitt Systemarchitektur).
    - `SUPABASE_URL` und `SUPABASE_ANON_KEY` in `.env` oder in `main.dart` setzen.

4. **App starten**
    - Android/iOS: Gerät/Emulator verbinden, dann  
      `flutter run`
    - Web:  
      `flutter run -d chrome`

5. **Tests**  
   `flutter test`

---

## 3. Systemarchitektur

### 3.1 Beteiligte Systeme

- **Flutter-App (Client)**
    - Nutzt Supabase über das SDK (`supabase_flutter`).
    - Auth, Datenbankabfragen und Datei-Upload (z. B. Avatare) laufen im Client.

- **Supabase (Backend)**
    - **Auth**: Registrierung, Login (E-Mail/Passwort), ggf. Passwort-Reset.
    - **PostgreSQL**: Alle fachlichen Daten (Module, Karten, Fortschritte, Statistiken, Achievements, Benachrichtigungen).
    - **Storage**: z. B. Bucket `avatar_profile` für Profilbilder.

- **Versionsverwaltung**
    - Git (z. B. GitLab), kollaborative Entwicklung im Team (4 Personen), Feature-Branches und Merges.

### 3.2 Kommunikation zwischen den Systemen

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter-App (Client)                        │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │  Screens/   │  │  Provider    │  │  AuthService,           │ │
│  │  Widgets    │  │ (Backend,    │  │  Modelle                │ │
│  │             │  │  Home)       │  │                         │ │
│  └──────┬──────┘  └──────┬───────┘  └───────────┬─────────────┘ │
│         │                │                      │               │
│         └────────────────┼──────────────────────┘               │
│                          │ supabase_flutter                     │
└──────────────────────────┼──────────────────────────────────────┘
                           │ HTTPS / REST / Realtime
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Supabase                                   │
│  ┌─────────────┐  ┌───────────────────────┐  ┌─────────────────┐│
│  │ Auth        │  │ PostgreSQL (Tabellen) │  │ Storage         ││
│  │ (Login/     │  │ modules, submodules,  │  │ avatar_profile  ││
│  │  SignUp)    │  │ questions, options,   │  │                 ││
│  │             │  │ user_profiles,        │  │                 ││
│  │             │  │ user_achievements,    │  │                 ││
│  │             │  │ learning_sessions,    │  │                 ││
│  │             │  │ user_card_progress,   │  │                 ││
│  │             │  │ user_statistics, …    │  │                 ││
│  └─────────────┘  └───────────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

- Die App spricht ausschließlich mit Supabase (URL + Anon Key). Es gibt keine zusätzliche eigene Backend-API.
- Alle datenrelevanten Aktionen (Lernfortschritt, 6×-Meisterschaft, Statistiken, Achievements, Benachrichtigungen) werden in Supabase abgebildet und von dort gelesen/geschrieben.

### 3.3 Wichtige Supabase-Tabellen (Überblick)

| Tabelle / Objekt | Zweck |
|------------------|--------|
| `modules` | Lernmodule (inkl. `default` für Standard-/Import-Module) |
| `submodules` | Untereinheiten eines Moduls |
| `questions` | Lernkarten (Frage + Verknüpfung zu Optionen) |
| `options` | Antwortoptionen je Frage, inkl. `is_correct` |
| `user_profiles` | Benutzerprofil (Name, Avatar-URL, etc.), verknüpft mit Auth |
| `user_achievements` | Erworbene Achievements pro Nutzer |
| `achievements` | Definition der Abzeichen |
| `learning_sessions` | Lernrunden/Sessions |
| `submodules_per_session` | Zuordnung Submodul ↔ Session |
| `user_card_progress` | Fortschritt pro Karte (u. a. für 6×-Meisterschaft) |
| `user_submodule_level_progress` | Fortschritt pro Submodul |
| `user_statistics` | Aggregierte Nutzerstatistiken |
| `user_notifications` | Benachrichtigungen in der App |
| `imported_modules` / `deleted_modules` | Import-/Löschverwaltung von Modulen |
| **Storage**: `avatar_profile` | Hochgeladene Profilbilder |

RLS (Row Level Security) und Storage-Richtlinien sollten in Supabase so gesetzt sein, dass Nutzer nur eigene Daten sehen bzw. ändern können.

---

## 4. Anforderungen – Umsetzung

Die folgenden Anforderungen entsprechen der Projektvorgabe. Der Stand bezieht sich auf den aktuellen Code- und Funktionsumfang.

| Anforderung | Status | Kurzbeschreibung |
|-------------|--------|------------------|
| **Lernmodus**: Karte mit Text und 4–6 Antworten, mind. eine richtig | ✅ umgesetzt | Umsetzung in Quiz-Flow, Nutzung von `questions` und `options`. |
| **Lernmodus**: Nutzer wählt eine/mehrere Antworten, sieht Korrektheit, bei Falsch: richtige Antwort anzeigen | ✅ umgesetzt | In QuizScreen und Auswertungslogik umgesetzt. |
| **Lernmodus**: Nächste Karte oder Ende mit Statistik | ✅ umgesetzt | Navigation und QuizResultScreen mit Rundenstatistik. |
| **Trainingsmodule durchsuchen und löschen** | ✅ umgesetzt | ModuleListScreen, BackendProvider: Suche und Delete auf `modules`/`submodules`. |
| **Statistik über alle Lernrunden** | ✅ umgesetzt | Nutzung von `learning_sessions`, `user_statistics`; Anzeige u. a. auf Profil/Home. |
| **Achievements** | ✅ umgesetzt | `achievements`, `user_achievements`, Logik im BackendProvider, Anzeige auf Home/Profil. |
| **6× hintereinander richtig → Karte wird nicht mehr angezeigt; bei Falsch Zähler zurückgesetzt** | ✅ umgesetzt | `user_card_progress` und zugehörige Logik (z. B. in Quiz- und Backend-Logik). |
| **Benutzerdaten auf Backend sichern und wieder laden** | ✅ umgesetzt | Supabase für Profil, Fortschritt, Sessions, Achievements, Statistiken. |
| **Weitere Module von einem Server importieren** | ✅ umgesetzt | Nutzung von `modules` mit `default`/Import und ggf. `imported_modules`. |


Weitere optionale oder nicht explizit vorgegebene Punkte, die im Projekt vorkommen:

- Benachrichtigungen (`user_notifications`, NotificationScreen)
- Profilbild-Upload (Storage `avatar_profile`)
- Teilen-Funktion (`share_plus`)

---

## 5. Potenzialerweiterung

- Passwort vergessen / Reset (vorbereitet in `auth_service.dart`, ggf. UI auskommentiert): Frontend wurde schon gearbeitet

## 6. Weitere Hinweise für Softwareentwickler

- **Einstieg in den Code**:
    - `lib/main.dart` für Start, Supabase und Provider.
    - `lib/provider/backend_provider.dart` für nahezu alle Backend-Operationen.
    - `lib/features/auth/services/auth_service.dart` für Auth.
    - Feature-basiert: `lib/features/{auth,home,modules}/`.

- **Git-Workflow**:  
  Feature-Branches (z. B. `31-benachrichtigungen-implementieren`, `25-game-logic-von-a-bis-z`), Merges in `main`, konventionelle Commit-Texte (z. B. `feat(...):`, `fix(...):`).

- **Source-Code- bzw. API-Dokumentation**:  
  Öffentliche APIs und komplexe Funktionen sind per Dartdoc kommentiert. Eine HTML-API-Dokumentation erzeugt man mit:  
  `dart doc .`  
  Die Ausgabe liegt dann unter `doc/api/`. Bei Bedarf kann eine CI-Pipeline (z. B. GitLab CI) diese Doku bauen und bereitstellen.

- **Umgebungsvariablen**:  
  Supabase-Zugangsdaten aus `.env` laden und in `main.dart` bei `Supabase.initialize()` verwenden, sobald `flutter_dotenv` dort angebunden ist – dann sind keine Zugangsdaten im Quellcode nötig.

Mit diesem Stand der Dokumentation können sich neue Entwickler schnell im Projekt orientieren und die Entwicklungsumgebung so einrichten, dass sie mit dem Lesen der README direkt mit der Entwicklung starten können.
