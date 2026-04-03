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
--  LOS-TYPEN  (beliebig viele hinzufuegen)
--  Jedes item-name muss in der ESX items-Tabelle existieren.
--  Bilder kommen in: html/images/<dateiname>
-- ============================================================

Config.Tickets = {

    -- --------------------------------------------------------
    --  SILBER LOS
    -- --------------------------------------------------------
    {
        itemName  = 'mtj_los_silber',           -- ESX Item-Name
        label     = 'Silber Los',
        ticketBg  = 'ticket_silber.png',        -- Hintergrundbild des Tickets (html/images/)
        shopPrice = 500,                        -- Kaufpreis in Shops (Dollar)

        -- "chance" sind relative Gewichtungen (kein striktes Prozent).
        -- Die tatsaechliche Wahrscheinlichkeit = chance / Summe aller chances.
        prizes = {
            {
                type    = 'money',
                amount  = 1000,
                label   = '1.000 $',
                image   = 'prize_money.png',
                chance  = 20,
            },
            {
                type    = 'money',
                amount  = 5000,
                label   = '5.000 $',
                image   = 'prize_money.png',
                chance  = 8,
            },
            {
                type    = 'item',
                item    = 'bread',
                amount  = 5,
                label   = '5x Brot',
                image   = 'prize_bread.png',
                chance  = 15,
            },
            {
                type    = 'item',
                item    = 'water',
                amount  = 5,
                label   = '5x Wasser',
                image   = 'prize_water.png',
                chance  = 10,
            },
            {
                type    = 'nothing',
                label   = 'Leider nichts gewonnen',
                image   = '',
                chance  = 47,
            },
        },
    },

    -- --------------------------------------------------------
    --  GOLD LOS
    -- --------------------------------------------------------
    {
        itemName  = 'mtj_los_gold',
        label     = 'Gold Los',
        ticketBg  = 'ticket_gold.png',
        shopPrice = 2500,

        prizes = {
            {
                type    = 'money',
                amount  = 10000,
                label   = '10.000 $',
                image   = 'prize_money.png',
                chance  = 15,
            },
            {
                type    = 'money',
                amount  = 50000,
                label   = '50.000 $',
                image   = 'prize_money.png',
                chance  = 5,
            },
            {
                type    = 'weapon',
                weapon  = 'WEAPON_PISTOL',
                ammo    = 250,
                label   = 'Pistole + 250 Schuss',
                image   = 'prize_pistol.png',
                chance  = 10,
            },
            {
                type    = 'weapon',
                weapon  = 'WEAPON_MICROSMG',
                ammo    = 500,
                label   = 'Micro SMG + 500 Schuss',
                image   = 'prize_smg.png',
                chance  = 3,
            },
            {
                type    = 'car',
                model   = 'sultan',
                label   = 'Sultan RS',
                image   = 'prize_sultan.png',
                chance  = 2,
            },
            {
                type    = 'nothing',
                label   = 'Leider nichts gewonnen',
                image   = '',
                chance  = 65,
            },
        },
    },

    -- --------------------------------------------------------
    --  PLATIN LOS
    -- --------------------------------------------------------
    {
        itemName  = 'mtj_los_platin',
        label     = 'Platin Los',
        ticketBg  = 'ticket_platin.png',
        shopPrice = 10000,

        prizes = {
            {
                type    = 'money',
                amount  = 100000,
                label   = '100.000 $',
                image   = 'prize_money.png',
                chance  = 5,
            },
            {
                type    = 'weapon',
                weapon  = 'WEAPON_CARBINERIFLE',
                ammo    = 1000,
                label   = 'Carbine Rifle + 1000 Schuss',
                image   = 'prize_rifle.png',
                chance  = 8,
            },
            {
                type    = 'car',
                model   = 'zentorno',
                label   = 'Zentorno',
                image   = 'prize_zentorno.png',
                chance  = 2,
            },
            {
                type    = 'car',
                model   = 'adder',
                label   = 'Adder (Bugatti)',
                image   = 'prize_adder.png',
                chance  = 1,
            },
            {
                type    = 'item',
                item    = 'goldbar',
                amount  = 10,
                label   = '10x Goldbarren',
                image   = 'prize_gold.png',
                chance  = 10,
            },
            {
                type    = 'nothing',
                label   = 'Leider nichts gewonnen',
                image   = '',
                chance  = 74,
            },
        },
    },
}

-- ============================================================
--  SHOP-KIOSK EINTRAEGE  (fuer esx_shops / ox_target etc.)
--  Format: { itemName, label, price }
--  Muss manuell in deinem Shop-Script eingetragen werden,
--  ODER du nutzt die unten stehende automatische ox_target-Config.
-- ============================================================

Config.ShopItems = {}
for _, ticket in ipairs(Config.Tickets) do
    table.insert(Config.ShopItems, {
        name  = ticket.itemName,
        label = ticket.label,
        price = ticket.shopPrice,
    })
end
