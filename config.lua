--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║   ███╗   ███╗████████╗     ██╗██████╗  ██████╗ ██████╗ ██╗  ██╗           ║
║   ████╗ ████║╚══██╔══╝    ██╔╝╚════██╗██╔═████╗╚════██╗██║  ██║           ║
║   ██╔████╔██║   ██║        ██║  █████╔╝██║██╔██║ █████╔╝███████║           ║
║   ██║╚██╔╝██║   ██║        ██║ ██╔═══╝ ████╔╝██║██╔═══╝ ╚════██║           ║
║   ██║ ╚═╝ ██║   ██║        ██║ ███████╗╚██████╔╝███████╗     ██║           ║
║   ╚═╝     ╚═╝   ╚═╝        ╚═╝ ╚══════╝ ╚═════╝ ╚══════╝     ╚═╝           ║
╠══════════════════════════════════════════════════════════════════════════════╣
║               R U B B E L L O S E   K O N F I G U R A T I O N             ║
║                       © Copyright 2024 MTJ2024                              ║
║                Alle Rechte vorbehalten · All Rights Reserved                ║
╚══════════════════════════════════════════════════════════════════════════════╝

  HINWEIS: Alle Einstellungen sind auf Deutsch kommentiert.
  Aendere nur Werte hinter dem '=' Zeichen.
  Texte in '' sind Zeichenketten, Zahlen ohne '', true/false fuer Boolean.
]]

Config = {}

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                     ALLGEMEINE EINSTELLUNGEN                            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

Config.Debug                        = false                 -- [ Debug-Modus aktivieren (true/false) ]
Config.Sprache                      = 'de'                  -- [ Sprache der Texte: 'de' (nur Deutsch verfuegbar) ]
Config.Waehrung                     = '$'                   -- [ Waehrungszeichen vor dem Betrag ]
Config.WaehrungNachBetrag           = false                 -- [ Waehrungszeichen nach dem Betrag (true/false) ]
Config.BenachrichtigungTyp          = 'esx'                 -- [ Benachrichtigung: 'esx' = Standard ESX ]
Config.Copyright                    = '© MTJ2024'           -- [ Copyright-Anzeige in der UI ]

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                    UI / DARSTELLUNG EINSTELLUNGEN                       ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

Config.UI = {

    -- ── Allgemein ───────────────────────────────────────────────────────────
    Titel                           = 'MTJ Rubbellose',     -- [ Haupttitel oben in der UI ]
    Untertitel                      = 'Dein Glueck wartet!',-- [ Untertitel unter dem Haupttitel ]

    -- ── Hintergrundbild ─────────────────────────────────────────────────────
    --   Unterstuetzte Formate: jpg · jpeg · png · gif · webp · svg · bmp
    --   Pfad relativ zum html/img/ Ordner angeben.
    --   Platzhalter-Datei ist bereits vorhanden – einfach ersetzen.
    HintergrundAktiviert            = true,                 -- [ Hintergrundbild anzeigen (true/false) ]
    Hintergrundbild                 = 'img/bg.png',         -- [ Pfad: 'img/bg.png' | 'img/bg.jpg' | 'img/hintergrund.webp' ]
    HintergrundDimmen               = 0.55,                 -- [ Abdunkelung des Hintergrunds (0.0 = keins, 1.0 = schwarz) ]
    HintergrundBlur                 = 4,                    -- [ Unschaerfe des Hintergrunds in px (0 = keine) ]

    -- ── Logo ─────────────────────────────────────────────────────────────────
    --   Unterstuetzte Formate: png · jpg · jpeg · webp · svg · gif
    --   Platzhalter-Datei ist bereits vorhanden – einfach ersetzen.
    LogoAktiviert                   = true,                 -- [ Logo im Header anzeigen (true/false) ]
    Logo                            = 'img/logo.png',       -- [ Pfad: 'img/logo.png' | 'img/logo.jpg' | 'img/logo.webp' ]
    LogoBreite                      = 160,                  -- [ Logo Breite in Pixel ]
    LogoHoehe                       = 60,                   -- [ Logo Hoehe in Pixel ]

    -- ── Farben ──────────────────────────────────────────────────────────────
    PrimaerFarbe                    = '#FFD700',            -- [ Primaerfarbe (Gold-Ton) als HEX ]
    SekundaerFarbe                  = '#0d0d1a',            -- [ Hintergrundfarbe der UI als HEX ]
    AkzentFarbe                     = '#e94560',            -- [ Akzentfarbe fuer Buttons als HEX ]
    GewinnFarbe                     = '#00ff88',            -- [ Farbe der Gewinn-Anzeige als HEX ]
    NiederlagefarBe                 = '#ff4444',            -- [ Farbe der Niederlage-Anzeige als HEX ]
    JackpotFarbe                    = '#ff6b35',            -- [ Farbe des Jackpot-Counters als HEX ]

    -- ── Effekte ─────────────────────────────────────────────────────────────
    PartikelAktiviert               = true,                 -- [ Konfetti-Partikel bei Gewinn (true/false) ]
    GlitzerAktiviert                = true,                 -- [ Glitzer-Hintergrund-Effekt (true/false) ]
    GewinnAnimationDauer            = 4000,                 -- [ Dauer der Gewinn-Animation in Millisekunden ]
    UebergangGeschwindigkeit        = 300,                  -- [ Uebergangs-Animation in Millisekunden ]

    -- ── Features ────────────────────────────────────────────────────────────
    JackpotAnzeigen                 = true,                 -- [ Jackpot-Counter im Header anzeigen (true/false) ]
    GewinnerTickerAktiviert         = true,                 -- [ Laufband mit letzten Gewinnern (true/false) ]
    GewinnerTickerGeschwindigkeit   = 40,                   -- [ Geschwindigkeit des Laufbands (Pixel/Sek) ]
    MaxGewinnerImTicker             = 10,                   -- [ Anzahl der letzten Gewinner im Ticker ]
    KratzFortschrittAnzeigen        = true,                 -- [ Kratz-Fortschrittsbalken anzeigen (true/false) ]
    KratzSchwelle                   = 55,                   -- [ Prozent die gekratzt sein muessen fuer Auto-Reveal (%) ]
    KratzPinselGroesse              = 32,                   -- [ Groesse des Kratz-Pinsels in Pixel ]
}

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                     ANIMATIONS EINSTELLUNGEN                            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

Config.Animation = {

    Aktiviert                       = true,                 -- [ Animationen generell aktivieren (true/false) ]

    -- ── Kauf-Animation (beim Loserwerb vom Haendler) ────────────────────────
    Kauf = {
        Dict                        = 'mp_common',          -- [ Animations-Dictionary ]
        Name                        = 'givetake1_a',        -- [ Animations-Name ]
        Flag                        = 49,                   -- [ Animations-Flag (49 = normal) ]
        Dauer                       = 3000,                 -- [ Dauer in Millisekunden ]
        PropAktiviert               = false,                -- [ Prop (Objekt) waehrend Animation (true/false) ]
    },

    -- ── Kratz-Animation (waehrend Rubbelvorgang) ─────────────────────────────
    Kratzen = {
        Dict                        = 'amb@world_human_stand_mobile@male@base', -- [ Dict ]
        Name                        = 'base',               -- [ Name ]
        Flag                        = 49,                   -- [ Flag ]
        Dauer                       = 8000,                 -- [ Dauer in Millisekunden ]
        PropModel                   = 'prop_paper_bag_01',  -- [ Prop-Modell (Loskarte) ]
        PropAktiviert               = false,                -- [ Prop anzeigen (true/false) ]
        PropKnochen                 = 57005,                -- [ Knochen-Index fuer Prop (rechte Hand) ]
    },

    -- ── Gewinn-Animation ─────────────────────────────────────────────────────
    Gewinn = {
        Dict                        = 'anim@mp_player_intcelebrationmale@helicopter', -- [ Dict ]
        Name                        = 'helicopter',         -- [ Name ]
        Flag                        = 11,                   -- [ Flag ]
        Dauer                       = 4000,                 -- [ Dauer in Millisekunden ]
    },

    -- ── Niederlage-Animation ─────────────────────────────────────────────────
    Niederlage = {
        Dict                        = 'anim@mp_player_intlosemale@',-- [ Dict ]
        Name                        = 'losemenu_idle_intro', -- [ Name ]
        Flag                        = 49,                   -- [ Flag ]
        Dauer                       = 3000,                 -- [ Dauer in Millisekunden ]
    },

    -- ── Jackpot-Animation ───────────────────────────────────────────────────
    Jackpot = {
        Dict                        = 'anim@mp_player_intcelebrationmale@waving_loop', -- [ Dict ]
        Name                        = 'waving_loop',        -- [ Name ]
        Flag                        = 11,                   -- [ Flag ]
        Dauer                       = 6000,                 -- [ Dauer in Millisekunden ]
    },
}

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                       JACKPOT EINSTELLUNGEN                             ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

Config.Jackpot = {

    Aktiviert                       = true,                 -- [ Jackpot-System aktivieren (true/false) ]
    StartBetrag                     = 10000,                -- [ Start-/Mindestbetrag des Jackpots in $ ]
    MaxBetrag                       = 2000000,              -- [ Maximaler Jackpot-Betrag in $ ]
    AnteilProLos                    = 0.05,                 -- [ Anteil jedes Loskaufs geht in den Jackpot (5% = 0.05) ]
    GewinnChance                    = 0.001,                -- [ Basis Jackpot-Gewinnchance (0.1% = 0.001) ]
    ServerAnsageAktiviert           = true,                 -- [ Serverweite Jackpot-Gewinn-Ansage (true/false) ]
    NachGewinnZuruecksetzen         = true,                 -- [ Jackpot nach Gewinn auf StartBetrag zuruecksetzen (true/false) ]
    SpeichernInDB                   = true,                 -- [ Jackpot-Stand in Datenbank speichern (true/false) ]
    AutoSpeichernIntervall          = 300,                  -- [ Automatisches Speichern alle X Sekunden ]
}

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                    KI-ALGORITHMUS EINSTELLUNGEN                         ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

Config.KI = {

    Aktiviert                       = true,                 -- [ KI-Gewinnalgorithmus aktivieren (true/false) ]

    -- ── Zeitbonus: Bessere Chancen zu bestimmten Stunden ────────────────────
    ZeitBonusAktiviert              = true,                 -- [ Zeitbasierte Gewinnboni (true/false) ]
    ZeitBonusStunden                = { 20, 21, 22 },       -- [ Stunden (0-23) mit erhoehten Chancen ]
    ZeitBonusMultiplikator          = 1.50,                 -- [ Chancen-Multiplikator in Bonuszeit (1.5 = +50%) ]

    -- ── Verlustschutz: Automatischer Bonus nach vielen Niederlagen ──────────
    VerlustschutzAktiviert          = true,                 -- [ Verlustschutz aktivieren (true/false) ]
    MaxVerluste                     = 8,                    -- [ Niederlagen in Folge bis Bonus greift ]
    VerlustBonus                    = 1.30,                 -- [ Chancen-Multiplikator nach MaxVerluste (1.3 = +30%) ]

    -- ── Spieler-Cooldown nach Gewinn ─────────────────────────────────────────
    CooldownAktiviert               = true,                 -- [ Gewinn-Cooldown aktivieren (true/false) ]
    CooldownNachGrossemGewinn       = 600,                  -- [ Sekunden Cooldown nach Gewinn ueber GrossGewinnSchwelle ]
    GrossGewinnSchwelle             = 10000,                -- [ Ab dieser Gewinnsumme gilt Cooldown in $ ]

    -- ── Tageslimit ──────────────────────────────────────────────────────────
    TageslimitAktiviert             = true,                 -- [ Tageslimit aktivieren (true/false) ]
    MaxKaeufeProTag                 = 100,                  -- [ Max. Loskauefe pro Tag und Spieler ]

    -- ── Statistik-Tracking ──────────────────────────────────────────────────
    StatistikAktiviert              = true,                 -- [ Spielerstatistiken in DB speichern (true/false) ]
}

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                       SHOP / NPC EINSTELLUNGEN                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

Config.Shop = {

    -- ── Oeffnen per Befehl ───────────────────────────────────────────────────
    BefehlAktiviert                 = true,                 -- [ Shop per Chat-Befehl oeffnen (true/false) ]
    Befehl                          = 'rubbellose',         -- [ Chat-Befehl ohne / z.B. 'rubbellose' → /rubbellose ]

    -- ── NPC-Haendler ────────────────────────────────────────────────────────
    NPCAktiviert                    = true,                 -- [ NPC-Haendler auf der Karte spawnen (true/false) ]
    NPCModel                        = 'a_m_m_business_01', -- [ NPC-Ped-Modell (GTA V Modellname) ]

    -- ┌─────────────────────────────────────────────────────────────────────┐
    -- │  COORDS EINSTELLEN:  vec4(x, y, z, heading)                        │
    -- │  Tipp: Im Spiel /coords eingeben → Werte kopieren                  │
    -- │  Heading = Blickrichtung in Grad (0-360)                           │
    -- └─────────────────────────────────────────────────────────────────────┘
    NPCPosition                     = vec4(-1393.98, -581.20, 30.32, 305.0), -- [ vec4(x, y, z, heading) ]

    NPCInteraktionsRadius           = 2.5,                  -- [ Radius in dem der NPC ansprechbar ist (Meter) ]
    NPCInteraktionsTaste            = 38,                   -- [ GTA-Steuerungsindex (38 = E-Taste) ]

    -- ── Kartenblip ──────────────────────────────────────────────────────────
    BlipAktiviert                   = true,                 -- [ Blip auf der Karte anzeigen (true/false) ]
    BlipName                        = 'MTJ Rubbellose',     -- [ Name des Blips auf der Karte ]
    BlipSprite                      = 469,                  -- [ Blip-Icon-ID (469 = Gluecksspiel) ]
    BlipFarbe                       = 5,                    -- [ Blip-Farbe (5 = Gelb) ]
    BlipMassstab                    = 0.75,                 -- [ Blip-Groesse (0.5 = klein, 1.0 = normal) ]

    -- ── Item-System (Los per Inventar-Item benutzen) ─────────────────────────
    ItemSystemAktiviert             = true,                 -- [ Los-Items im Inventar nutzbar (true/false) ]
}

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                    RUBBELLOSE TYPEN EINSTELLUNGEN                       ║
-- ║                                                                          ║
-- ║  SYMBOL-LEGENDE:                                                         ║
-- ║    typ = 'nichts'  → Niete, kein Gewinn                                 ║
-- ║    typ = 'geld'    → Geldgewinn (betrag in $)                           ║
-- ║    typ = 'item'    → Item-Gewinn (item = ESX-Item-Name, menge = Anzahl) ║
-- ║    typ = 'jackpot' → Jackpot (betrag wird automatisch ermittelt)        ║
-- ║                                                                          ║
-- ║  chance = Gewichtung (keine echten Prozentwerte; relativ zueinander)    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

Config.Lose = {

    -- ╔══ LOS 1: STANDARD ═════════════════════════════════════════════════╗
    {
        id                          = 'standard',           -- [ Eindeutige ID (keine Leerzeichen) ]
        name                        = '⭐ Standard Los',    -- [ Anzeigename in der UI ]
        beschreibung                = 'Dein Einstieg ins Glueck – guenstig und mit fairen Chancen!', -- [ Beschreibung ]
        item                        = 'mtj_los_standard',   -- [ ESX-Item-Name (muss in Items-DB vorhanden sein) ]
        preis                       = 100,                  -- [ Kaufpreis in $ ]
        symbol                      = '⭐',                  -- [ Emoji-Symbol fuer die Karte ]
        farbe                       = '#4CAF50',            -- [ Kartenakzentfarbe (HEX) ]
        maxGewinn                   = 2000,                 -- [ Max. moeglicher Gewinn fuer die Anzeige in $ ]
        gewinne = {
            -- name            betrag  chance    typ        [item]               [menge]
            { name='Niete',              betrag=0,       chance=55,  typ='nichts'                              },
            { name='50$ Gewinn',         betrag=50,      chance=22,  typ='geld'                                },
            { name='200$ Gewinn',        betrag=200,     chance=13,  typ='geld'                                },
            { name='500$ Gewinn',        betrag=500,     chance=6,   typ='geld'                                },
            { name='2.000$ Gewinn',      betrag=2000,    chance=2,   typ='geld'                                },
            { name='2x Standard Los',    betrag=0,       chance=2,   typ='item',  item='mtj_los_standard', menge=2 },
            { name='JACKPOT!',           betrag=0,       chance=0,   typ='jackpot'                             },
        },
    },

    -- ╔══ LOS 2: SILBER ════════════════════════════════════════════════════╗
    {
        id                          = 'silber',             -- [ Eindeutige ID ]
        name                        = '🥈 Silber Los',      -- [ Anzeigename ]
        beschreibung                = 'Mehr Risiko, mehr Belohnung – Silber glaenzt fuer Glueckspilze!', -- [ Beschreibung ]
        item                        = 'mtj_los_silber',     -- [ ESX-Item-Name ]
        preis                       = 500,                  -- [ Kaufpreis in $ ]
        symbol                      = '🥈',                 -- [ Emoji-Symbol ]
        farbe                       = '#9E9E9E',            -- [ Kartenakzentfarbe (HEX) ]
        maxGewinn                   = 10000,                -- [ Max. moeglicher Gewinn fuer die Anzeige in $ ]
        gewinne = {
            { name='Niete',              betrag=0,       chance=45,  typ='nichts'                              },
            { name='250$ Gewinn',        betrag=250,     chance=25,  typ='geld'                                },
            { name='1.000$ Gewinn',      betrag=1000,    chance=16,  typ='geld'                                },
            { name='3.500$ Gewinn',      betrag=3500,    chance=8,   typ='geld'                                },
            { name='10.000$ Gewinn',     betrag=10000,   chance=3,   typ='geld'                                },
            { name='2x Silber Los',      betrag=0,       chance=2,   typ='item',  item='mtj_los_silber',   menge=2 },
            { name='JACKPOT!',           betrag=0,       chance=0.5, typ='jackpot'                             },
        },
    },

    -- ╔══ LOS 3: GOLD ══════════════════════════════════════════════════════╗
    {
        id                          = 'gold',               -- [ Eindeutige ID ]
        name                        = '🥇 Gold Los',        -- [ Anzeigename ]
        beschreibung                = 'Exklusive Chancen fuer wahre Gluecksritter – Gold fuer die Mutigen!', -- [ Beschreibung ]
        item                        = 'mtj_los_gold',       -- [ ESX-Item-Name ]
        preis                       = 2000,                 -- [ Kaufpreis in $ ]
        symbol                      = '🥇',                 -- [ Emoji-Symbol ]
        farbe                       = '#FFD700',            -- [ Kartenakzentfarbe (HEX) ]
        maxGewinn                   = 75000,                -- [ Max. moeglicher Gewinn fuer die Anzeige in $ ]
        gewinne = {
            { name='Niete',              betrag=0,       chance=35,  typ='nichts'                              },
            { name='1.000$ Gewinn',      betrag=1000,    chance=28,  typ='geld'                                },
            { name='5.000$ Gewinn',      betrag=5000,    chance=20,  typ='geld'                                },
            { name='15.000$ Gewinn',     betrag=15000,   chance=10,  typ='geld'                                },
            { name='75.000$ Gewinn',     betrag=75000,   chance=4,   typ='geld'                                },
            { name='Gold-Paket (3x)',    betrag=0,       chance=2,   typ='item',  item='mtj_los_gold',     menge=3 },
            { name='JACKPOT!',           betrag=0,       chance=1,   typ='jackpot'                             },
        },
    },

    -- ╔══ LOS 4: DIAMANT ══════════════════════════════════════════════════╗
    {
        id                          = 'diamant',            -- [ Eindeutige ID ]
        name                        = '💎 Diamant Los',     -- [ Anzeigename ]
        beschreibung                = 'Das Ultimative – nur fuer Legenden. Traumgewinne warten auf dich!', -- [ Beschreibung ]
        item                        = 'mtj_los_diamant',    -- [ ESX-Item-Name ]
        preis                       = 10000,                -- [ Kaufpreis in $ ]
        symbol                      = '💎',                 -- [ Emoji-Symbol ]
        farbe                       = '#00E5FF',            -- [ Kartenakzentfarbe (HEX) ]
        maxGewinn                   = 500000,               -- [ Max. moeglicher Gewinn fuer die Anzeige in $ ]
        gewinne = {
            { name='Niete',              betrag=0,       chance=22,  typ='nichts'                              },
            { name='5.000$ Gewinn',      betrag=5000,    chance=28,  typ='geld'                                },
            { name='25.000$ Gewinn',     betrag=25000,   chance=22,  typ='geld'                                },
            { name='75.000$ Gewinn',     betrag=75000,   chance=14,  typ='geld'                                },
            { name='200.000$ Gewinn',    betrag=200000,  chance=7,   typ='geld'                                },
            { name='500.000$ Gewinn',    betrag=500000,  chance=3,   typ='geld'                                },
            { name='Diamant-Set (3x)',   betrag=0,       chance=2,   typ='item',  item='mtj_los_diamant',  menge=3 },
            { name='MEGA JACKPOT!',      betrag=0,       chance=2,   typ='jackpot'                             },
        },
    },
}

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║              ADMIN / BERECHTIGUNGS EINSTELLUNGEN                        ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

Config.Admin = {
    AceGruppe                       = 'admin',              -- [ ACE-Gruppe fuer Admin-Befehle ]
    JackpotSetzenBefehl             = 'setjackpot',         -- [ Befehl: /setjackpot <betrag> ]
    GewinnStatistikBefehl           = 'losestat',           -- [ Befehl: /losestat ]
    DebugBefehl                     = 'losedebug',          -- [ Befehl: /losedebug ]
}

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                  DATENBANK EINSTELLUNGEN                                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

Config.Datenbank = {
    Aktiviert                       = true,                 -- [ MySQL-Datenbank verwenden (true/false) ]
    TabelleJackpot                  = 'mtj_lose_jackpot',   -- [ Tabellen-Name fuer Jackpot-Daten ]
    TabelleVerlauf                  = 'mtj_lose_verlauf',   -- [ Tabellen-Name fuer Kauf-/Gewinn-Verlauf ]
    TabelleStats                    = 'mtj_lose_stats',     -- [ Tabellen-Name fuer Spieler-Statistiken ]
    MaxVerlaufEintraege             = 500,                  -- [ Maximale Eintraege im Verlauf (aeltere werden geloescht) ]
}
