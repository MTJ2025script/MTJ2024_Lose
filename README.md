# MTJ2024 Rubbellose System
### Professionelles Scratch-Card Lotterie System für FiveM ESX Legacy
**© Copyright 2024 MTJ2024 – Alle Rechte vorbehalten**

---

## 📦 Features

- 🎴 **Canvas-basierte Rubbellos-Mechanik** – echter Kratz-Effekt mit Maus/Touch
- 🤖 **KI-Gewinnauslosung** – Zeitbonus, Verlustschutz, gewichtete Wahrscheinlichkeit
- 🏆 **Jackpot-System** – wächst mit jedem Kauf, serverweite Ansage bei Gewinn
- 🎨 **Premium Dark-UI** – Gold-Glitter, animierter Jackpot-Counter, Gewinner-Ticker
- 🖼️ **Bild-Unterstützung** – Hintergrundbild + Logo frei konfigurierbar (jpg/png/webp/gif/svg)
- 📋 **Vollständige deutsche Config** – rechts-ausgerichtete Spalten, Blockformat
- 🎭 **Animationen** – Kauf-, Kratz-, Gewinn- und Niederlage-Animationen
- 💾 **MySQL-Datenbankanbindung** – Jackpot, Verlauf, Statistiken
- 🎟️ **4 Los-Typen** – Standard, Silber, Gold, Diamant

---

## 🗂️ Dateistruktur

```
MTJ2024_Lose/
├── fxmanifest.lua          → Resource-Manifest (alle Bildformate deklariert)
├── config.lua              → Finale deutsche Blockconfig
├── locales/
│   └── de.lua              → Deutsche Sprachstrings
├── server/
│   └── server.lua          → ESX-Serverlogik + KI-Algorithmus + Jackpot
├── client/
│   └── client.lua          → Client-Animationen + NUI + NPC-Händler
├── html/
│   ├── index.html          → Rubbellos-UI
│   ├── style.css           → Dark-Casino-Theme
│   ├── script.js           → Canvas-Scratch + Konfetti + Jackpot-Counter
│   └── img/
│       ├── bg.png          ← PLATZHALTER – eigenes Bild ersetzen
│       └── logo.png        ← PLATZHALTER – eigenes Logo ersetzen
└── sql/
    └── mtj_lose.sql        → Datenbankschema importieren
```

---

## 🚀 Installation

1. **Ordner** `MTJ2024_Lose` in deinen FiveM `resources/` Ordner kopieren
2. **SQL** `sql/mtj_lose.sql` in deine Datenbank importieren
3. **Items** in `items`-Tabelle eintragen (Kommentar im SQL beachten)
4. **`server.cfg`** eintragen: `ensure MTJ2024_Lose`
5. **Bilder** ersetzen:
   - `html/img/bg.png` → dein Hintergrundbild (jpg/png/webp/gif/svg)
   - `html/img/logo.png` → dein Server-Logo (png/jpg/webp/svg)
   - Pfade in `config.lua` → `Config.UI.Hintergrundbild` und `Config.UI.Logo` anpassen

---

## ⚙️ Konfiguration

Alle Einstellungen befinden sich in `config.lua` – vollständig auf Deutsch mit rechts-ausgerichteten Kommentarspalten.

| Befehl          | Beschreibung                |
|-----------------|-----------------------------|
| `/rubbellose`   | Shop öffnen/schließen       |
| `/setjackpot`   | Jackpot setzen (Admin)      |
| `/losedebug`    | Debug-Modus umschalten      |

---

## 🖼️ Bilder konfigurieren

```lua
-- In config.lua:
Config.UI.Hintergrundbild = 'img/bg.jpg'    -- oder .png / .webp / .gif / .svg
Config.UI.Logo            = 'img/logo.png'  -- oder .jpg / .webp / .svg
```

Alle Formate (`jpg`, `jpeg`, `png`, `gif`, `webp`, `svg`, `bmp`) sind im Manifest deklariert.

---

*© Copyright 2024 MTJ2024 · Alle Rechte vorbehalten · Weiterverkauf verboten*
