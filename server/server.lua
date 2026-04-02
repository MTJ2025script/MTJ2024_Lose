--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║              MTJ2024 RUBBELLOSE – SERVER-SIDE LOGIK                        ║
║                    © Copyright 2024 MTJ2024                                ║
║             Alle Rechte vorbehalten · All Rights Reserved                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

local ESX          = exports['es_extended']:getSharedObject()
local jackpotBetrag = Config.Jackpot.StartBetrag
local spielerDaten  = {}   -- [source] = { verlusteSerie, kaeufeHeute, letzterGrossGewinn, aktiveKarte }

-- ─────────────────────────────────────────────────────────────────────────────
--  HILFSFUNKTIONEN
-- ─────────────────────────────────────────────────────────────────────────────

local function FormatGeld(betrag)
    local formatted = tostring(math.floor(betrag))
    local result = ''
    local count  = 0
    for i = #formatted, 1, -1 do
        if count > 0 and count % 3 == 0 then result = '.' .. result end
        result = formatted:sub(i, i) .. result
        count  = count + 1
    end
    if Config.WaehrungNachBetrag then
        return result .. ' ' .. Config.Waehrung
    end
    return Config.Waehrung .. result
end

local function GetSpielerDaten(source)
    if not spielerDaten[source] then
        spielerDaten[source] = {
            verlusteSerie        = 0,
            kaeufeHeute          = 0,
            letzterGrossGewinn   = 0,
            aktiveKarte          = nil,
        }
    end
    return spielerDaten[source]
end

local function Log(msg)
    if Config.Debug then
        print('^3[MTJ-Lose]^7 ' .. tostring(msg))
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  JACKPOT – LADEN / SPEICHERN
-- ─────────────────────────────────────────────────────────────────────────────

local function LadeJackpot()
    if not Config.Datenbank.Aktiviert then return end
    MySQL.query('SELECT betrag FROM ?? LIMIT 1', { Config.Datenbank.TabelleJackpot }, function(result)
        if result and result[1] then
            jackpotBetrag = result[1].betrag
            Log('Jackpot geladen: ' .. FormatGeld(jackpotBetrag))
        end
    end)
end

local function SpeichereJackpot()
    if not Config.Datenbank.Aktiviert then return end
    MySQL.update('UPDATE ?? SET betrag = ? WHERE id = 1', { Config.Datenbank.TabelleJackpot, jackpotBetrag })
end

-- ─────────────────────────────────────────────────────────────────────────────
--  KI-GEWINNAUSLOSUNG
-- ─────────────────────────────────────────────────────────────────────────────

local function BerechneGewinn(source, losConfig)
    local daten         = GetSpielerDaten(source)
    local ki            = Config.KI
    local multiplikator = 1.0

    -- Zeitbonus
    if ki.Aktiviert and ki.ZeitBonusAktiviert then
        local stunde = tonumber(os.date('%H'))
        for _, h in ipairs(ki.ZeitBonusStunden) do
            if stunde == h then
                multiplikator = multiplikator * ki.ZeitBonusMultiplikator
                Log('Zeitbonus aktiv (Stunde ' .. stunde .. '): x' .. ki.ZeitBonusMultiplikator)
                break
            end
        end
    end

    -- Verlustschutz
    if ki.Aktiviert and ki.VerlustschutzAktiviert then
        if daten.verlusteSerie >= ki.MaxVerluste then
            multiplikator = multiplikator * ki.VerlustBonus
            Log('Verlustschutz aktiv nach ' .. daten.verlusteSerie .. ' Niederlagen: x' .. ki.VerlustBonus)
        end
    end

    -- Jackpot-Prüfung
    if Config.Jackpot.Aktiviert then
        local jackpotChance = Config.Jackpot.GewinnChance * multiplikator
        if math.random() < jackpotChance then
            return {
                typ    = 'jackpot',
                name   = 'JACKPOT!',
                betrag = jackpotBetrag,
                item   = nil,
                menge  = 0,
            }
        end
    end

    -- Gewinntabelle mit angepassten Gewichtungen aufbauen
    local tabelle       = {}
    local gesamtGewicht = 0

    for _, gewinn in ipairs(losConfig.gewinne) do
        if gewinn.typ ~= 'jackpot' then
            local w = gewinn.chance
            if gewinn.typ ~= 'nichts' then
                w = w * multiplikator
            end
            gesamtGewicht = gesamtGewicht + w
            tabelle[#tabelle + 1] = { gewinn = gewinn, kumuliert = gesamtGewicht }
        end
    end

    local zufall = math.random() * gesamtGewicht
    local kumuliert = 0
    for _, eintrag in ipairs(tabelle) do
        kumuliert = kumuliert + eintrag.gewinn.chance * (eintrag.gewinn.typ ~= 'nichts' and multiplikator or 1.0)
        if zufall <= kumuliert then
            return eintrag.gewinn
        end
    end

    -- Fallback: Niete
    return losConfig.gewinne[1]
end

-- ─────────────────────────────────────────────────────────────────────────────
--  PANEL-GENERATOR (Symbole für die Rubbel-Karte)
-- ─────────────────────────────────────────────────────────────────────────────

local SYMBOLE = { '💰', '⭐', '💎', '🍀', '7️⃣', '🎰', '🏆', '🎁', '🔥', '🌟' }

local function GeneriereSymbol()
    return SYMBOLE[math.random(#SYMBOLE)]
end

local function GenerierePanel(gewinn, losConfig)
    -- Bei Gewinn: 3 gleiche Symbole + Betrag
    if gewinn.typ == 'geld' or gewinn.typ == 'jackpot' then
        local sym  = GeneriereSymbol()
        local text = gewinn.typ == 'jackpot'
            and ('JP ' .. Config.Waehrung .. math.floor(jackpotBetrag))
            or  (Config.Waehrung .. gewinn.betrag)
        return {
            { symbol = sym, text = text, gewinn = true },
            { symbol = sym, text = text, gewinn = true },
            { symbol = sym, text = text, gewinn = true },
        }
    elseif gewinn.typ == 'item' then
        local sym  = '🎁'
        local text = gewinn.menge .. 'x Los'
        return {
            { symbol = sym, text = text, gewinn = true },
            { symbol = sym, text = text, gewinn = true },
            { symbol = sym, text = text, gewinn = true },
        }
    else
        -- Niete: 3 verschiedene Symbole, kein Match
        local used = {}
        local panels = {}
        for i = 1, 3 do
            local sym
            repeat
                sym = GeneriereSymbol()
            until not used[sym]
            used[sym] = true
            panels[i] = { symbol = sym, text = losConfig.preis > 999 and '$???' or '$??', gewinn = false }
        end
        return panels
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  GEWINN AUSZAHLEN
-- ─────────────────────────────────────────────────────────────────────────────

local function ZahleGewinnAus(source, gewinn, xPlayer, losConfig)
    local daten = GetSpielerDaten(source)

    if gewinn.typ == 'geld' then
        xPlayer.addAccountMoney('money', gewinn.betrag)
        TriggerClientEvent('MTJ_Lose:Benachrichtigung', source, T('gewinn_geld', FormatGeld(gewinn.betrag)), 'success')

        -- Serverweite Ansage bei großem Gewinn
        if gewinn.betrag >= Config.KI.GrossGewinnSchwelle then
            TriggerClientEvent('chatMessage', -1, 'MTJ Rubbellose', {255, 215, 0},
                '🎰 ' .. GetPlayerName(source) .. ' hat ' .. FormatGeld(gewinn.betrag) .. ' gewonnen!')
            daten.letzterGrossGewinn = os.time()
        end

        -- DB-Verlauf
        if Config.Datenbank.Aktiviert then
            MySQL.insert('INSERT INTO ?? (identifier, spielername, los_typ, einsatz, gewinn_name, gewinn_betrag, gewinn_typ) VALUES (?,?,?,?,?,?,?)',
                { Config.Datenbank.TabelleVerlauf, xPlayer.identifier, GetPlayerName(source),
                  losConfig.id, losConfig.preis, gewinn.name, gewinn.betrag, 'geld' })
        end

        daten.verlusteSerie = 0
        TriggerClientEvent('MTJ_Lose:GewinnerTicker', -1, {
            name   = GetPlayerName(source),
            los    = losConfig.name,
            betrag = FormatGeld(gewinn.betrag),
        })

    elseif gewinn.typ == 'jackpot' then
        xPlayer.addAccountMoney('money', jackpotBetrag)
        local betragText = FormatGeld(jackpotBetrag)

        TriggerClientEvent('MTJ_Lose:Benachrichtigung', source, T('gewinn_jackpot', betragText), 'jackpot')
        TriggerClientEvent('chatMessage', -1, 'MTJ Rubbellose', {255, 100, 0},
            '🏆🏆🏆 JACKPOT! ' .. GetPlayerName(source) .. ' hat den Jackpot von ' .. betragText .. ' gewonnen! 🏆🏆🏆')

        if Config.Datenbank.Aktiviert then
            MySQL.insert('INSERT INTO ?? (identifier, spielername, los_typ, einsatz, gewinn_name, gewinn_betrag, gewinn_typ, ist_jackpot) VALUES (?,?,?,?,?,?,?,1)',
                { Config.Datenbank.TabelleVerlauf, xPlayer.identifier, GetPlayerName(source),
                  losConfig.id, losConfig.preis, 'JACKPOT', jackpotBetrag, 'jackpot' })
            MySQL.update('UPDATE ?? SET letzter_gewinner=?, letzter_gewinn_datum=NOW() WHERE id=1',
                { Config.Datenbank.TabelleJackpot, GetPlayerName(source) })
        end

        if Config.Jackpot.NachGewinnZuruecksetzen then
            jackpotBetrag = Config.Jackpot.StartBetrag
            SpeichereJackpot()
            TriggerClientEvent('MTJ_Lose:JackpotUpdate', -1, jackpotBetrag)
        end

        daten.verlusteSerie = 0

    elseif gewinn.typ == 'item' then
        xPlayer.addInventoryItem(gewinn.item, gewinn.menge)
        TriggerClientEvent('MTJ_Lose:Benachrichtigung', source,
            T('gewinn_item', gewinn.menge, gewinn.name), 'success')

        if Config.Datenbank.Aktiviert then
            MySQL.insert('INSERT INTO ?? (identifier, spielername, los_typ, einsatz, gewinn_name, gewinn_betrag, gewinn_typ) VALUES (?,?,?,?,?,?,?)',
                { Config.Datenbank.TabelleVerlauf, xPlayer.identifier, GetPlayerName(source),
                  losConfig.id, losConfig.preis, gewinn.name, 0, 'item' })
        end

        daten.verlusteSerie = 0

    else -- Niete
        TriggerClientEvent('MTJ_Lose:Benachrichtigung', source, T('niete'), 'error')

        if Config.Datenbank.Aktiviert then
            MySQL.insert('INSERT INTO ?? (identifier, spielername, los_typ, einsatz, gewinn_name, gewinn_betrag, gewinn_typ) VALUES (?,?,?,?,?,?,?)',
                { Config.Datenbank.TabelleVerlauf, xPlayer.identifier, GetPlayerName(source),
                  losConfig.id, losConfig.preis, 'Niete', 0, 'nichts' })
        end

        daten.verlusteSerie = (daten.verlusteSerie or 0) + 1
    end

    -- Statistik aktualisieren
    if Config.Datenbank.Aktiviert and Config.KI.StatistikAktiviert then
        local gewinnBetrag = (gewinn.typ == 'geld' and gewinn.betrag)
            or (gewinn.typ == 'jackpot' and jackpotBetrag) or 0
        MySQL.query([[
            INSERT INTO ?? (identifier, spielername, gesamt_kaeufe, gesamt_ausgaben, gesamt_gewinne, kaeufe_heute, letzter_kauf)
            VALUES (?,?,1,?,?,1,NOW())
            ON DUPLICATE KEY UPDATE
                spielername=VALUES(spielername),
                gesamt_kaeufe=gesamt_kaeufe+1,
                gesamt_ausgaben=gesamt_ausgaben+VALUES(gesamt_ausgaben),
                gesamt_gewinne=gesamt_gewinne+VALUES(gesamt_gewinne),
                kaeufe_heute=kaeufe_heute+1,
                letzter_kauf=NOW()
        ]], { Config.Datenbank.TabelleStats, xPlayer.identifier, GetPlayerName(source),
              losConfig.preis, gewinnBetrag })
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  SERVER-EVENTS
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNetEvent('MTJ_Lose:KaufeLos', function(losId)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    -- Los-Config finden
    local losConfig = nil
    for _, los in ipairs(Config.Lose) do
        if los.id == losId then losConfig = los break end
    end
    if not losConfig then return end

    local daten = GetSpielerDaten(source)

    -- Tageslimit prüfen
    if Config.KI.TageslimitAktiviert and daten.kaeufeHeute >= Config.KI.MaxKaeufeProTag then
        TriggerClientEvent('MTJ_Lose:Benachrichtigung', source, T('tageslimit', Config.KI.MaxKaeufeProTag), 'error')
        return
    end

    -- Cooldown nach großem Gewinn prüfen
    if Config.KI.CooldownAktiviert and daten.letzterGrossGewinn > 0 then
        local vergangen = os.time() - daten.letzterGrossGewinn
        if vergangen < Config.KI.CooldownNachGrossemGewinn then
            local rest = Config.KI.CooldownNachGrossemGewinn - vergangen
            TriggerClientEvent('MTJ_Lose:Benachrichtigung', source, T('cooldown', rest), 'error')
            return
        end
    end

    -- Geld prüfen
    if xPlayer.getAccount('money').money < losConfig.preis then
        TriggerClientEvent('MTJ_Lose:Benachrichtigung', source, T('kein_geld', FormatGeld(losConfig.preis)), 'error')
        return
    end

    -- Geld abziehen
    xPlayer.removeAccountMoney('money', losConfig.preis)
    daten.kaeufeHeute = (daten.kaeufeHeute or 0) + 1

    -- Jackpot-Anteil hinzufügen
    if Config.Jackpot.Aktiviert then
        local anteil = math.floor(losConfig.preis * Config.Jackpot.AnteilProLos)
        jackpotBetrag = math.min(jackpotBetrag + anteil, Config.Jackpot.MaxBetrag)
        TriggerClientEvent('MTJ_Lose:JackpotUpdate', -1, jackpotBetrag)
        Log('Jackpot erhoeht um ' .. anteil .. ' → ' .. jackpotBetrag)
    end

    -- KI-Gewinnauslosung
    local gewinn = BerechneGewinn(source, losConfig)
    Log('Spieler ' .. GetPlayerName(source) .. ' | Los: ' .. losConfig.id .. ' | Gewinn: ' .. gewinn.name)

    -- Panels für Scratch-Card generieren
    local panels = GenerierePanel(gewinn, losConfig)

    -- Ergebnis an Client senden (Client zeigt Animation, Server hat bereits entschieden)
    daten.aktiveKarte = {
        gewinn    = gewinn,
        losConfig = losConfig,
        xPlayer   = xPlayer,
        quelle    = source,
    }

    TriggerClientEvent('MTJ_Lose:ZeigeKarte', source, {
        panels    = panels,
        losName   = losConfig.name,
        losSymbol = losConfig.symbol,
        gewonnen  = gewinn.typ ~= 'nichts',
        gewinnName= gewinn.name,
        jackpot   = gewinn.typ == 'jackpot',
    })
end)

-- Client bestätigt: Karte aufgedeckt → Gewinn auszahlen
RegisterNetEvent('MTJ_Lose:Aufgedeckt', function()
    local source = source
    local daten  = GetSpielerDaten(source)
    if not daten.aktiveKarte then return end

    local karte = daten.aktiveKarte
    daten.aktiveKarte = nil

    ZahleGewinnAus(source, karte.gewinn, karte.xPlayer, karte.losConfig)
end)

-- Item-Verwendung aus dem Inventar
RegisterNetEvent('MTJ_Lose:BenutzeItem', function(losId)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local losConfig = nil
    for _, los in ipairs(Config.Lose) do
        if los.id == losId then losConfig = los break end
    end
    if not losConfig then return end

    -- Item entfernen
    xPlayer.removeInventoryItem(losConfig.item, 1)

    local daten  = GetSpielerDaten(source)
    local gewinn = BerechneGewinn(source, losConfig)
    local panels = GenerierePanel(gewinn, losConfig)

    daten.aktiveKarte = {
        gewinn    = gewinn,
        losConfig = losConfig,
        xPlayer   = xPlayer,
        quelle    = source,
    }

    TriggerClientEvent('MTJ_Lose:ZeigeKarte', source, {
        panels    = panels,
        losName   = losConfig.name,
        losSymbol = losConfig.symbol,
        gewonnen  = gewinn.typ ~= 'nichts',
        gewinnName= gewinn.name,
        jackpot   = gewinn.typ == 'jackpot',
    })
end)

-- Jackpot-Wert anfragen
RegisterNetEvent('MTJ_Lose:JackpotAnfrage', function()
    TriggerClientEvent('MTJ_Lose:JackpotUpdate', source, jackpotBetrag)
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  ADMIN BEFEHLE
-- ─────────────────────────────────────────────────────────────────────────────

RegisterCommand(Config.Admin.JackpotSetzenBefehl, function(source, args)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or not IsPlayerAceAllowed(tostring(source), 'command.' .. Config.Admin.JackpotSetzenBefehl) then
            TriggerClientEvent('MTJ_Lose:Benachrichtigung', source, T('keine_berechtigung'), 'error')
            return
        end
    end
    local betrag = tonumber(args[1])
    if not betrag then return end
    jackpotBetrag = math.max(Config.Jackpot.StartBetrag, math.min(betrag, Config.Jackpot.MaxBetrag))
    SpeichereJackpot()
    TriggerClientEvent('MTJ_Lose:JackpotUpdate', -1, jackpotBetrag)
    if source > 0 then
        TriggerClientEvent('MTJ_Lose:Benachrichtigung', source, T('jackpot_gesetzt', FormatGeld(jackpotBetrag)), 'success')
    else
        print('[MTJ-Lose] Jackpot gesetzt: ' .. FormatGeld(jackpotBetrag))
    end
end, true)

RegisterCommand(Config.Admin.DebugBefehl, function(source, args)
    if source > 0 and not IsPlayerAceAllowed(tostring(source), 'command.' .. Config.Admin.DebugBefehl) then return end
    Config.Debug = not Config.Debug
    local msg = Config.Debug and T('debug_an') or T('debug_aus')
    if source > 0 then
        TriggerClientEvent('MTJ_Lose:Benachrichtigung', source, msg, 'info')
    else
        print('[MTJ-Lose] ' .. msg)
    end
end, true)

-- ─────────────────────────────────────────────────────────────────────────────
--  RESSOURCE START / STOP
-- ─────────────────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    math.randomseed(os.time())
    LadeJackpot()

    -- Jackpot automatisch speichern
    if Config.Jackpot.SpeichernInDB then
        SetInterval(function()
            SpeichereJackpot()
        end, Config.Jackpot.AutoSpeichernIntervall * 1000)
    end

    print('^2[MTJ-Lose]^7 Rubbellose System gestartet. © 2024 MTJ2024')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SpeichereJackpot()
    print('^1[MTJ-Lose]^7 Rubbellose System gestoppt.')
end)

-- Spielerdaten beim Disconnect leeren
AddEventHandler('playerDropped', function()
    spielerDaten[source] = nil
end)

-- Tageslimit täglich zurücksetzen (0:00 Uhr)
CreateThread(function()
    while true do
        Wait(60000) -- Jede Minute prüfen
        local stunde  = tonumber(os.date('%H'))
        local minute  = tonumber(os.date('%M'))
        if stunde == 0 and minute == 0 then
            for _, daten in pairs(spielerDaten) do
                daten.kaeufeHeute = 0
            end
            Log('Tageslimits zurueckgesetzt.')
        end
    end
end)
