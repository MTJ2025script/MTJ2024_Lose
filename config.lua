Config = {}

-- ============================================================
--  ALLGEMEINE EINSTELLUNGEN
-- ============================================================

-- Benachrichtigungstyp: 'esx' | 'ox_lib' | 'custom'
Config.NotifyType = 'esx'

-- Inventar-System: 'esx' | 'ox_inventory'
Config.InventoryType = 'esx'

-- Spawn-Offset fuer gewonnene Fahrzeuge (relativ zum Spieler)
Config.CarSpawnOffset = { x = 5.0, y = 0.0, z = 0.0 }

-- ============================================================
--  ADMIN-TABLET EINSTELLUNGEN
-- ============================================================

-- Befehl zum Oeffnen des Admin-Tablets im Spiel
Config.AdminCommand = 'losadmin'

-- ESX-Gruppen die das Admin-Tablet nutzen duerfen
Config.AdminGroups = { 'admin', 'superadmin' }

-- ============================================================
--  LOS-TYPEN  (Startkonfiguration – wird beim ersten Start
--  automatisch in die Datenbank importiert)
--  Danach alles ueber das Admin-Tablet verwalten!
--  Bilder kommen in: html/images/<dateiname>
-- ============================================================

-- ============================================================
--  WAHRSCHEINLICHKEITS-UEBERSICHT (Generisches Los, 1.000 $)
--
--  Tier-Verteilung:  Silber 65 %  |  Gold 28 %  |  Platin 7 %
--
--  Silber-Gewinnchance : ~39 %  →  Ø Geld-Rueckfluss   ~82 $
--  Gold-Gewinnchance   : ~31 %  →  Ø Geld-Rueckfluss  ~357 $
--  Platin-Gewinnchance : ~30 %  →  Ø Geld-Rueckfluss 2.050 $
--
--  Gesamt Ø Rueckfluss : ~297 $  bei 1.000 $ Einsatz
--  House Edge          : ~70 %   (Haus verdient langfristig)
--
--  Gewinnquote gesamt  : ~36 %   (1 von 3 Losen gewinnt ETWAS)
--  → Spieler bleibt motiviert, ohne dass das Haus verliert.
--
--  Jackpot (80.000 $)  : 0,07 %  (~1 von 1.430 Losen)
--  Auto-Gewinn         : 0,07 %  (~1 von 1.430 Losen)
--  → Selten genug fuer RP-Server-Legenden.
-- ============================================================

Config.Tickets = {

    -- --------------------------------------------------------
    --  SILBER LOS
    --  Haufige kleine Trostpreise  →  Spieler "gewinnt" oft
    --  etwas und macht weiter, obwohl der Einsatz hoeher ist.
    --  Gewinnchance ~39 %  |  Ø Geld-Rueckfluss ~82 $
    -- --------------------------------------------------------
    {
        itemName  = 'mtj_los_silber',
        label     = 'Silber Los',
        ticketBg  = 'ticket_silber.png',
        shopPrice = 500,

        -- chance = relative Gewichtung. Summe = 100.
        prizes = {
            {   -- Trostgewinn – haefig, fuehlt sich gut an
                type   = 'money', amount = 200,
                label  = '200 $',  image  = 'prize_money.png',
                chance = 20,
            },
            {   -- Kleiner Gewinn – "fast rentiert"
                type   = 'money', amount = 600,
                label  = '600 $',  image  = 'prize_money.png',
                chance = 7,
            },
            {   -- Sachpreis – fuehlt sich wie Gewinn an
                type   = 'item',  item   = 'bread', amount = 5,
                label  = '5x Brot', image = 'prize_bread.png',
                chance = 7,
            },
            {   -- Sachpreis
                type   = 'item',  item   = 'water', amount = 3,
                label  = '3x Wasser', image = 'prize_water.png',
                chance = 5,
            },
            {   -- Niete – Mehrheit
                type   = 'nothing', label = 'Leider nichts gewonnen',
                image  = '', chance = 61,
            },
        },
    },

    -- --------------------------------------------------------
    --  GOLD LOS
    --  Mittlere Gewinne moeglich, aber selten.
    --  Gewinnchance ~31 %  |  Ø Geld-Rueckfluss ~357 $
    -- --------------------------------------------------------
    {
        itemName  = 'mtj_los_gold',
        label     = 'Gold Los',
        ticketBg  = 'ticket_gold.png',
        shopPrice = 2500,

        prizes = {
            {   -- Trostgewinn
                type   = 'money', amount = 800,
                label  = '800 $',  image  = 'prize_money.png',
                chance = 14,
            },
            {   -- Mittlerer Gewinn
                type   = 'money', amount = 2500,
                label  = '2.500 $', image = 'prize_money.png',
                chance = 5,
            },
            {   -- Schoener Gewinn – selten
                type   = 'money', amount = 6000,
                label  = '6.000 $', image = 'prize_money.png',
                chance = 2,
            },
            {   -- Waffe als Sachpreis
                type   = 'weapon', weapon = 'WEAPON_PISTOL', ammo = 250,
                label  = 'Pistole + 250 Schuss', image = 'prize_pistol.png',
                chance = 4,
            },
            {   -- Sachpreis
                type   = 'item',  item   = 'bread', amount = 10,
                label  = '10x Brot', image = 'prize_bread.png',
                chance = 6,
            },
            {   -- Niete – Mehrheit
                type   = 'nothing', label = 'Leider nichts gewonnen',
                image  = '', chance = 69,
            },
        },
    },

    -- --------------------------------------------------------
    --  PLATIN LOS
    --  Grosse Gewinne moeglich – aber extrem selten.
    --  Jackpot + Auto je ~1 % dieses Tiers = ~0,07 % gesamt.
    --  Gewinnchance ~30 %  |  Ø Geld-Rueckfluss ~2.050 $
    -- --------------------------------------------------------
    {
        itemName  = 'mtj_los_platin',
        label     = 'Platin Los',
        ticketBg  = 'ticket_platin.png',
        shopPrice = 10000,

        prizes = {
            {   -- Trostgewinn
                type   = 'money', amount = 2500,
                label  = '2.500 $',  image  = 'prize_money.png',
                chance = 10,
            },
            {   -- Mittlerer Gewinn
                type   = 'money', amount = 10000,
                label  = '10.000 $', image  = 'prize_money.png',
                chance = 4,
            },
            {   -- Grosser Gewinn
                type   = 'money', amount = 30000,
                label  = '30.000 $', image  = 'prize_money.png',
                chance = 2,
            },
            {   -- JACKPOT – Legende auf dem Server (~0,07 % gesamt)
                type   = 'money', amount = 80000,
                label  = '80.000 $ JACKPOT!', image = 'prize_money.png',
                chance = 1,
            },
            {   -- Auto-Hauptgewinn – sichtbar auf dem Server (~0,07 % gesamt)
                type  = 'car', model = 'sultan',
                label = 'Sultan RS', image = 'prize_sultan.png',
                chance = 1,
            },
            {   -- Waffe als Sachpreis
                type   = 'weapon', weapon = 'WEAPON_CARBINERIFLE', ammo = 500,
                label  = 'Carbine Rifle + 500 Schuss', image = 'prize_rifle.png',
                chance = 5,
            },
            {   -- Sachpreis
                type   = 'item',  item = 'goldbar', amount = 5,
                label  = '5x Goldbarren', image = 'prize_gold.png',
                chance = 7,
            },
            {   -- Niete – Mehrheit
                type   = 'nothing', label = 'Leider nichts gewonnen',
                image  = '', chance = 70,
            },
        },
    },
}

-- ============================================================
--  GENERISCHES LOS  (ein Item, ein Preis im Shop)
--  Wenn aktiviert: Spieler kauft "mtj_los" fuer einen Preis.
--  Beim Benutzen wird per Zufall ein Tier (Silber/Gold/Platin)
--  ausgewuerfelt – der Spieler weiss vorher nicht was er bekommt.
--
--  TierChances = relative Gewichtungen (nicht Prozent).
--  Beispiel: silber=60 gold=30 platin=10 → Gesamt 100
--    → Silber  60 % Wahrscheinlichkeit
--    → Gold    30 % Wahrscheinlichkeit
--    → Platin  10 % Wahrscheinlichkeit
-- ============================================================

Config.GenericLos = {
    enabled   = true,                -- false = nur einzelne Los-Typen im Shop
    itemName  = 'mtj_los',
    label     = 'Los',
    shopPrice = 1000,                -- ein einziger Kaufpreis

    -- Welche Tiers können ausgewürfelt werden?
    -- itemName muss mit einem Config.Tickets[].itemName übereinstimmen.
    tierChances = {
        { itemName = 'mtj_los_silber', chance = 60 },
        { itemName = 'mtj_los_gold',   chance = 30 },
        { itemName = 'mtj_los_platin', chance = 10 },
    },
}

-- ============================================================
--  SHOP-KIOSK EINTRAEGE  (fuer esx_shops / ox_target etc.)
--  Muss manuell in deinem Shop-Script eingetragen werden.
-- ============================================================

Config.ShopItems = {}

-- Generisches Los hat Vorrang wenn aktiviert
if Config.GenericLos.enabled then
    table.insert(Config.ShopItems, {
        name  = Config.GenericLos.itemName,
        label = Config.GenericLos.label,
        price = Config.GenericLos.shopPrice,
    })
else
    -- Einzelne Tiers im Shop
    for _, ticket in ipairs(Config.Tickets) do
        table.insert(Config.ShopItems, {
            name  = ticket.itemName,
            label = ticket.label,
            price = ticket.shopPrice,
        })
    end
end
