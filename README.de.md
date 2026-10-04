# Wortuhr – Bildschirmschoner für macOS

[English](README.md) · **Deutsch**

[![CI](https://github.com/Diavolezza/wortuhr/actions/workflows/ci.yml/badge.svg)](https://github.com/Diavolezza/wortuhr/actions/workflows/ci.yml)
· **[Im Browser ausprobieren](https://diavolezza.github.io/wortuhr/)**
· **[Download](https://github.com/Diavolezza/wortuhr/releases/latest)**
· **[Auf Ko-fi unterstützen](https://ko-fi.com/diavolezza)**

Wortuhr im 11×10-Raster. Die Minuten zwischen den Fünf-Minuten-Schritten lassen nacheinander die Kanten der
Platte glimmen – oben, rechts, unten, links – und erlöschen mit den nächsten Wörtern. Die jüngste Kante leuchtet am
hellsten; wie stark die früheren nachglühen, ist einstellbar – von nur der jüngsten Kante bis zu allen gleich hell.
Zeitansage in acht Varianten:

| Sprache | Beispiel (3:15 · 3:45) |
|---|---|
| Hochdeutsch | viertel nach drei · viertel vor vier |
| Schweizerdeutsch | viertel ab drü · viertel vor vieri (3:25 füf vor halbi vieri) |
| Süddeutsch | viertel vier · dreiviertel vier |
| Englisch (britisch) | a quarter past three · a quarter to four |
| Englisch (amerikanisch) | a quarter after three · a quarter to four |
| Französisch | trois heures et quart · quatre heures moins le quart (12 Uhr: midi, 0 Uhr: minuit) |
| Italienisch | le tre e un quarto · le quattro meno un quarto (1 Uhr: è l’una) |
| Spanisch | las tres y cuarto · las cuatro menos cuarto (1 Uhr: es la una) |

Farben, Schrift, Größe, das Licht der Minutenkanten, Einbrennschutz und „Nur auf dem Hauptbildschirm“ im
Optionen-Dialog einstellbar; der Dialog
spricht die gewählte Sprache. Beim ersten Start richtet sich die Uhr nach der Sprache des Macs.

![Wortuhr im Zeitraffer von 3:00 bis 3:15](docs/wortuhr.gif)

Getestet unter macOS 27 auf Apple Silicon; gebaut wird für Apple Silicon und Intel (ab macOS 13).

## Herunterladen und installieren

`Wortuhr-….zip` aus dem [neuesten Release](https://github.com/Diavolezza/wortuhr/releases/latest)
laden, entpacken und `Wortuhr.saver` nach `~/Library/Screen Savers` legen. Das Paket ist nur
ad hoc signiert, nicht notarisiert – deshalb einmal im Terminal die Download-Sperre entfernen:

    xattr -dr com.apple.quarantine ~/Library/Screen\ Savers/Wortuhr.saver

Dann in Systemeinstellungen → Bildschirmschoner „Wortuhr“ wählen.

## Aus dem Quelltext bauen und installieren

    ./build.sh --system

Braucht Xcode (oder die Command Line Tools). Das Skript baut für Apple Silicon und Intel,
erzeugt das Vorschaubild, signiert ad hoc und installiert nach `/Library/Screen Savers`
(fragt nach dem Administrator-Passwort). Danach in den Systemeinstellungen die Kachel
„Wortuhr“ einmal anklicken.

Nur aus `/Library/Screen Savers` zeigen die Systemeinstellungen das eigene Vorschaubild;
`./build.sh` ohne Option installiert nach `~/Library/Screen Savers` (dann mit Standard-Strudel).

Mit `--arm-only` wird nur für Apple Silicon gebaut – schneller, reicht für den eigenen Mac
(z. B. `./build.sh --system --arm-only`). Zum Weitergeben ohne die Option bauen.

`--docs` erzeugt zusätzlich die Bilder der README in `docs/` mit dem Bildschirmschoner selbst.

## Wenn etwas nicht geht

    ./diag.sh

schreibt Systemprotokoll (letzte 20 Minuten) und Absturzberichte nach `diag.log`.

## Eigenheiten von macOS 26+, die der Code abfängt

- Der Bildschirmschoner läuft hinter dem Anmeldefenster weiter → bei Eingabe ausblenden.
- Das Anmeldefenster verschwindet nach 30 s ohne Eingabe wieder → dann Uhr wieder einblenden.
- Die Vorschau in den Systemeinstellungen meldet `isPreview = false` → Eingabeerkennung nur beim echten
  Bildschirmschoner: nach `didstart` oder wenn der Bildschirm gesperrt ist (`CGSSessionScreenIsLocked`).
  Die Größe taugt nicht als Merkmal – die Vorschau ist intern ebenfalls bildschirmgroß.
- `didstart` ist unzuverlässig: kommt manchmal gar nicht, manchmal bevor macOS eine zweite Ansicht anlegt
  → Zustand gilt prozessweit, zusätzlich Prüfung auf gesperrten Bildschirm.
- Hinter dem Anmeldefenster bleiben `animateOneFrame` bzw. die Animation aus → eigener Takt (`DispatchSourceTimer`), `stopAnimation` hält die Uhr nicht an.
- `legacyScreenSaver` beendet sich nicht → `exit(0)` nach `willstop`.
- NSColorPanel ist im Bildschirmschoner-Prozess unzuverlässig → Farben als Auswahllisten.

## Bekanntes Problem: „Optionen …“ öffnet nur einmal

In den Systemeinstellungen öffnet „Optionen …“ den Dialog pro Sitzung nur einmal. Wird die
Kachel erneut angeklickt, fragt macOS den Dialog zwar bei der Wortuhr ab, blendet ihn aber
nicht ein. Abhilfe: Systemeinstellungen ganz beenden und neu öffnen.

Der Fehler liegt bei macOS 26 und betrifft auch andere Bildschirmschoner von Drittanbietern
(siehe [cowsaver#1](https://github.com/matthewsundling/cowsaver/issues/1)); Apples eigene
Bildschirmschoner laufen anders und sind nicht betroffen. Versuche, das Blatt von der Wortuhr
aus zu erzwingen, haben nicht funktioniert oder es verschlimmert.

## Prototyp

`prototype/index.html` im Browser öffnen – oder die [Live-Demo](https://diavolezza.github.io/wortuhr/):
dieselbe Uhr zum Ausprobieren von Zeitansage, Farben, Schrift und Größe, mit Zeitraffer.
Die Einstellungen lassen sich als JSON kopieren.

Raster und Zeitlogik stehen in `prototype/faces.js` und identisch in `Sources/ClockFace.swift`.
Nach jeder Änderung daran:

    node prototype/check.mjs

prüft alle Zeitansagen (jedes Wort im Raster, Lesereihenfolge, keine Überlappung,
gleichzeitig leuchtende Wörter nicht aneinandergeklebt) und
vergleicht Prototyp und Swift Zeile für Zeile.

## Aufbau

- `Sources/ClockFace.swift` – Buchstabenraster und Zeitlogik je Sprache
- `Sources/Settings.swift` – Einstellungen, Voreinstellungen, Speichern (ScreenSaverDefaults)
- `Sources/WortuhrView.swift` – Darstellung mit Core Animation (ein Glyphen-Layer pro Buchstabe)
- `Sources/ConfigController.swift` – Optionen-Dialog in allen Sprachen
- `Sources/Log.swift` – Diagnose-Ausgaben (`./diag.sh` sammelt sie)
- `Tools/main.swift` – erzeugt das Vorschaubild für die Systemeinstellungen (11:55)
- `Tools/Docs/main.swift` – erzeugt die Bilder der README (`./build.sh --docs`)
- `Tools/Phrases/main.swift` – gibt alle Zeitansagen aus Swift aus (für `prototype/check.mjs`)
- `.github/workflows/` – CI (Bauen + Prüfen), Live-Demo auf GitHub Pages, Release bei Versions-Tags (`v1.2` …)

## Unterstützen

Die Wortuhr ist kostenlos. Wenn sie dir gefällt, kannst du mir auf [Ko-fi](https://ko-fi.com/diavolezza) einen Kaffee spendieren ☕
oder sie über [GitHub Sponsors](https://github.com/sponsors/Diavolezza) unterstützen.

## Lizenz

MIT – siehe [LICENSE](LICENSE).
