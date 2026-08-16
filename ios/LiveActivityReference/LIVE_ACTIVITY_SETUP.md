# iOS Live Activity einrichten (manuell in Xcode, auf dem Mac)

Das hier kann ich (Claude) nicht selbst erledigen -- Windows kann keine iOS-Builds
bauen, und das Anlegen eines neuen Xcode-Targets per Hand-Editieren der
`.pbxproj`-Datei ist zu riskant (kann das ganze Projekt kaputt machen), ohne es
hinterher in Xcode selbst prüfen zu können. Die Dart-Seite (Aufrufe, Datenfluss)
ist bereits fertig -- es fehlt nur dieser native Teil.

## Voraussetzungen

- Mac mit Xcode (aktuelle Version)
- Apple Developer Account (auch der kostenlose reicht für lokales Testen auf
  einem eigenen Gerät/Simulator)
- iOS 16.1+ auf dem Testgerät (Live Activities funktionieren nicht im
  Simulator vor iOS 16.2 zuverlässig -- am besten auf einem echten iPhone
  testen)

## Schritte

1. **Projekt öffnen**: `ios/Runner.xcworkspace` in Xcode öffnen (nicht die
   `.xcodeproj`-Datei).

2. **Widget Extension anlegen**: `File` → `New` → `Target...` → `Widget
   Extension` auswählen.
   - Produktname: z.B. `TimerWidget`
   - **"Include Live Activity" ankreuzen**
   - "Embed in Application": `Runner`
   - Bei der Nachfrage danach auf **Activate** klicken.

3. **Generierte Datei ersetzen**: Xcode legt automatisch eine Datei wie
   `TimerWidgetLiveActivity.swift` an. Deren kompletten Inhalt durch den
   Inhalt von [`TimerLiveActivity.swift`](TimerLiveActivity.swift) (im
   selben Ordner wie diese Anleitung) ersetzen.

4. **App Group Capability** -- für **beide** Targets (`Runner` UND die neue
   Widget Extension):
   - Target auswählen → `Signing & Capabilities` → `+ Capability` → `App
     Groups`
   - Neue Gruppe anlegen, z.B. `group.com.example.boxingApp.timer`
   - **Exakt dieselbe ID** bei beiden Targets ankreuzen.
   - Diese ID muss mit der Konstante `_liveActivityAppGroupId` in
     `lib/services/background_timer_controller.dart` übereinstimmen (dort
     schon so vorbereitet -- falls du eine andere ID vergibst, dort
     anpassen).

5. **Push Notifications Capability** -- **nur** für `Runner` (nicht für die
   Extension): `Signing & Capabilities` → `+ Capability` → `Push
   Notifications`. (Wird von `live_activities` als Zusatz vorausgesetzt,
   auch wenn wir aktuell keinen Push-Server nutzen --
   `iOSEnableRemoteUpdates: false` ist im Dart-Code schon gesetzt.)

6. **Info.plist der Extension**: `NSSupportsLiveActivities` = `true`
   ergänzen (in `Runner/Info.plist` ist das bereits vorhanden, siehe
   [Info.plist](../Runner/Info.plist) -- muss zusätzlich in der
   `Info.plist` der neuen Extension stehen).

7. **Deployment Target prüfen**: Bei der Extension sicherstellen, dass
   `iOS Deployment Target` nicht niedriger als beim Haupt-Target ist (in
   `Runner` bereits auf 16.1 gesetzt).

8. **Bauen & testen**: `flutter pub get`, dann in Xcode auf einem echten
   iPhone (nicht Simulator, für zuverlässiges Verhalten) ausführen. Timer im
   Fight-Trainer-Screen starten, App verlassen/Handy sperren -- die Live
   Activity sollte auf dem Sperrbildschirm bzw. in der Dynamic Island
   (iPhone 14 Pro oder neuer) erscheinen.

## Bekannte Einschränkung

Beim **Intervall-Timer** (mehrere Runden/Pausen) zählt die Zeit in der Live
Activity zwar durchgehend korrekt weiter (das übernimmt SwiftUI selbst,
`Text(timerInterval:)`), aber die **Beschriftung** ("Runde 1/2" → "Pause")
wechselt während die App im Hintergrund ist **nicht automatisch** mit -- das
würde einen eigenen Push-Server voraussetzen, um die Live Activity von außen
zu aktualisieren. Beim Zurückkehren in die App ist wieder alles korrekt. Für
den einfachen Timer (nur eine Phase) betrifft diese Einschränkung nichts.
