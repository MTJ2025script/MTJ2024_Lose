# MTJ Los – Lotterie Script für FiveM (ESX Legacy)

> Item-basiertes Lotterie-Script mit Rubbellos-UI, Vollbild-Gewinn-Animation und konfigurierbaren Preisen.

---

## Features

- 🎟️ **Benutzbares Los-Item** – wird als Bild im ESX-Inventar angezeigt
- 🖼️ **Ticket-Hintergrundbild** – jedes Los hat ein eigenes Backdrop-Design
- 🖱️ **Rubbel-Animation** – interaktives Canvas-Rubbelfeld (NUI)
- 🎁 **Vollbild-Gewinn-UI** – Geschenk-Box öffnet sich mit Animation, riesiges Preis-Bild erscheint
- 🎉 **Konfetti-Regen** bei Gewinn
- 😢 **Niete-Screen** bei Verlust
- ⚙️ **Config** – Gewinne pro Los-Typ frei konfigurierbar:
  - 💵 Geld (beliebiger Betrag)
  - 📦 Items (ESX-Items mit Menge)
  - 🚗 Fahrzeuge (beliebiges GTA-Modell)
  - 🔫 Waffen (mit Munition)
- 🏪 **Shop-kompatibel** – Items in ESX-Shops / Kiosken kaufbar

---

## Installation

### 1. Resource kopieren

Kopiere den Ordner `mtj_los` in deinen FiveM-Server-Ressourcen-Ordner (z. B. `resources/[scripts]/mtj_los`).

### 2. Datenbank einrichten

Führe `sql/install.sql` auf deiner ESX-Datenbank aus:

```sql
INSERT IGNORE INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    ('mtj_los_silber', 'Silber Los',  1, 0, 1),
    ('mtj_los_gold',   'Gold Los',    1, 0, 1),
    ('mtj_los_platin', 'Platin Los',  1, 1, 1);
```

### 3. Resource in server.cfg eintragen

```
ensure mtj_los
```

### 4. Bilder platzieren

Lege deine eigenen Bilder in `html/images/` ab:

| Dateiname            | Verwendung                          |
|----------------------|-------------------------------------|
| `ticket_silber.png`  | Hintergrundbild Silber Los          |
| `ticket_gold.png`    | Hintergrundbild Gold Los            |
| `ticket_platin.png`  | Hintergrundbild Platin Los          |
| `prize_money.png`    | Gewinn-Bild für Geldpreise          |
| `prize_pistol.png`   | Gewinn-Bild für Pistole             |
| `prize_smg.png`      | Gewinn-Bild für SMG                 |
| `prize_rifle.png`    | Gewinn-Bild für Gewehr              |
| `prize_sultan.png`   | Gewinn-Bild für Sultan RS           |
| `prize_zentorno.png` | Gewinn-Bild für Zentorno            |
| `prize_adder.png`    | Gewinn-Bild für Adder               |
| `prize_gold.png`     | Gewinn-Bild für Goldbarren          |

> Fehlt ein Bild, wird automatisch ein Trophy-Emoji (🏆) angezeigt.

---

## Konfiguration (`config.lua`)

### Neues Los hinzufügen

```lua
{
    itemName  = 'mtj_los_diamant',     -- ESX-Item-Name (muss in DB eingetragen sein)
    label     = 'Diamant Los',
    ticketBg  = 'ticket_diamant.png',  -- Hintergrundbild (html/images/)
    shopPrice = 25000,

    prizes = {
        { type = 'money',  amount = 500000,            label = '500.000 $',      image = 'prize_money.png', chance = 2  },
        { type = 'car',    model  = 'adder',            label = 'Adder',          image = 'prize_adder.png', chance = 1  },
        { type = 'weapon', weapon = 'WEAPON_RPG', ammo = 10, label = 'RPG',       image = 'prize_rpg.png',   chance = 1  },
        { type = 'item',   item   = 'goldbar', amount = 50,  label = '50x Gold',  image = 'prize_gold.png',  chance = 5  },
        { type = 'nothing',                              label = 'Leider nichts', image = '',                chance = 91 },
    },
},
```

### Gewinn-Typen

| `type`    | Pflicht-Felder        | Beschreibung              |
|-----------|-----------------------|---------------------------|
| `money`   | `amount`              | Geld direkt auf Konto     |
| `item`    | `item`, `amount`      | ESX-Item ins Inventar     |
| `weapon`  | `weapon`, `ammo`      | Waffe + Munition          |
| `car`     | `model`               | Fahrzeug spawnen          |
| `nothing` | —                     | Niete                     |

---

## Items in Shop eintragen (esx_shops)

Füge in die `config.lua` deines `esx_shops` folgendes ein:

```lua
{ name = 'mtj_los_silber', price = 500   },
{ name = 'mtj_los_gold',   price = 2500  },
{ name = 'mtj_los_platin', price = 10000 },
```

---

## Abhängigkeiten

- [es_extended](https://github.com/esx-framework/esx_core) (ESX Legacy)

---

## Credits

Entwickelt von **MTJ2025**
