--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║              MTJ2024 RUBBELLOSE – CLIENT-SIDE LOGIK                        ║
║                    © Copyright 2024 MTJ2024                                ║
║             Alle Rechte vorbehalten · All Rights Reserved                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

local ESX        = exports['es_extended']:getSharedObject()
local uiOffen    = false
local npcHandle  = 0
local animLaeuft = false

-- ─────────────────────────────────────────────────────────────────────────────
--  HILFSFUNKTIONEN
-- ─────────────────────────────────────────────────────────────────────────────

local function Log(msg)
    if Config.Debug then
        print('^3[MTJ-Lose Client]^7 ' .. tostring(msg))
    end
end

local function LadeAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
end

local function SpieleAnimation(animCfg)
    if not Config.Animation.Aktiviert then return end
    local ped = PlayerPedId()
    LadeAnimDict(animCfg.Dict)
    TaskPlayAnim(ped, animCfg.Dict, animCfg.Name, 8.0, -8.0, animCfg.Dauer, animCfg.Flag, 0, false, false, false)
end

local function StoppeAnimation()
    ClearPedTasks(PlayerPedId())
end

-- ─────────────────────────────────────────────────────────────────────────────
--  ZENTRALES CUSTOM NOTIFY SYSTEM
--  Alle Benachrichtigungen laufen durch diese Funktion.
--  Typ:  'success' | 'error' | 'info' | 'warning' | 'jackpot' | 'item'
-- ─────────────────────────────────────────────────────────────────────────────

local function ZeigeNachricht(text, typ, dauer)
    typ   = typ   or 'info'
    dauer = dauer or (Config.Notify and Config.Notify.Dauer or 5000)

    if Config.BenachrichtigungTyp == 'custom' then
        -- Custom NUI Notify (läuft auch wenn UI geschlossen ist)
        SendNUIMessage({
            action = 'notify',
            text   = text,
            typ    = typ,
            dauer  = dauer,
        })
    else
        -- Fallback: ESX Standard
        local prefix = ''
        if typ == 'error'   then prefix = '~r~'
        elseif typ == 'success' or typ == 'jackpot' then prefix = '~g~'
        elseif typ == 'warning' then prefix = '~y~'
        end
        ESX.ShowNotification(prefix .. text)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  UI ÖFFNEN / SCHLIESSEN
-- ─────────────────────────────────────────────────────────────────────────────

local function OeffneUI()
    if uiOffen then return end
    uiOffen = true
    SetNuiFocus(true, true)

    -- Jackpot-Wert vom Server holen
    TriggerServerEvent('MTJ_Lose:JackpotAnfrage')

    -- Notify-System initialisieren (Config weitergeben)
    SendNUIMessage({
        action = 'notifyInit',
        config = Config.Notify,
    })

    -- Lose-Konfiguration und UI-Einstellungen an NUI senden
    SendNUIMessage({
        action  = 'oeffne',
        lose    = Config.Lose,
        ui      = Config.UI,
        jackpot = 0,
    })
    Log('UI geoeffnet')
end

local function SchliesseUI()
    if not uiOffen then return end
    uiOffen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'schliesse' })
    Log('UI geschlossen')
end

-- ─────────────────────────────────────────────────────────────────────────────
--  NUI-CALLBACKS (NUI → Client)
-- ─────────────────────────────────────────────────────────────────────────────

-- Spieler kauft ein Los über die UI
RegisterNUICallback('kaufe', function(data, cb)
    cb('ok')
    local losId = data.losId
    Log('Kaufe Los: ' .. tostring(losId))

    -- Kauf-Animation abspielen
    if Config.Animation.Aktiviert then
        SpieleAnimation(Config.Animation.Kauf)
        Wait(Config.Animation.Kauf.Dauer)
        StoppeAnimation()
    end

    TriggerServerEvent('MTJ_Lose:KaufeLos', losId)
end)

-- Spieler schließt die UI
RegisterNUICallback('schliesse', function(_, cb)
    cb('ok')
    SchliesseUI()
end)

-- Spieler hat das Los aufgedeckt (Kratzen fertig)
RegisterNUICallback('aufgedeckt', function(data, cb)
    cb('ok')
    TriggerServerEvent('MTJ_Lose:Aufgedeckt')

    -- Gewinn- oder Niederlage-Animation
    Wait(500)
    if data.gewonnen then
        if data.jackpot then
            SpieleAnimation(Config.Animation.Jackpot)
        else
            SpieleAnimation(Config.Animation.Gewinn)
        end
    else
        SpieleAnimation(Config.Animation.Niederlage)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  SERVER-EVENTS (Server → Client)
-- ─────────────────────────────────────────────────────────────────────────────

-- Server schickt die Karte (Panels + Ergebnis)
RegisterNetEvent('MTJ_Lose:ZeigeKarte', function(daten)
    -- Kratzen-Animation starten
    if Config.Animation.Aktiviert then
        CreateThread(function()
            SpieleAnimation(Config.Animation.Kratzen)
        end)
    end

    -- Karte an NUI senden (verzögert, damit Animation sichtbar ist)
    Wait(1200)
    SendNUIMessage({
        action  = 'zeigeKarte',
        panels  = daten.panels,
        losName = daten.losName,
        losSymbol = daten.losSymbol,
        gewonnen  = daten.gewonnen,
        gewinnName= daten.gewinnName,
        jackpot   = daten.jackpot,
    })
end)

-- Jackpot-Wert wurde aktualisiert
RegisterNetEvent('MTJ_Lose:JackpotUpdate', function(betrag)
    SendNUIMessage({ action = 'jackpotUpdate', betrag = betrag })
end)

-- Benachrichtigung vom Server anzeigen (funktioniert auch ohne offene UI)
RegisterNetEvent('MTJ_Lose:Benachrichtigung', function(text, typ)
    ZeigeNachricht(text, typ)
end)

-- Gewinner-Ticker-Eintrag empfangen
RegisterNetEvent('MTJ_Lose:GewinnerTicker', function(daten)
    SendNUIMessage({ action = 'gewinnerTicker', daten = daten })
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  CHAT-BEFEHL
-- ─────────────────────────────────────────────────────────────────────────────

if Config.Shop.BefehlAktiviert then
    RegisterCommand(Config.Shop.Befehl, function()
        if uiOffen then
            SchliesseUI()
        else
            OeffneUI()
        end
    end, false)

    TriggerEvent('chat:addSuggestion', '/' .. Config.Shop.Befehl, 'MTJ Rubbellose Shop oeffnen')
end

-- ESC-Taste schließt die UI
CreateThread(function()
    while true do
        Wait(0)
        if uiOffen and IsControlJustReleased(0, 200) then -- 200 = ESC
            SchliesseUI()
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  NPC-HÄNDLER
-- ─────────────────────────────────────────────────────────────────────────────

if Config.Shop.NPCAktiviert then
    CreateThread(function()
        -- Modell laden
        local model = GetHashKey(Config.Shop.NPCModel)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(100) end

        -- Coords aus vec4 auslesen  (vec4 / vector4 identisch in FiveM)
        local coords  = Config.Shop.NPCPosition
        local px, py, pz, heading = coords.x, coords.y, coords.z, coords.w

        -- NPC spawnen (z leicht abgesenkt für sauberes Stehen auf dem Boden)
        npcHandle = CreatePed(4, model, px, py, pz - 1.0, heading, false, true)
        SetEntityInvincible(npcHandle, true)
        SetBlockingOfNonTemporaryEvents(npcHandle, true)
        SetPedCanRagdoll(npcHandle, false)
        FreezeEntityPosition(npcHandle, true)
        TaskStartScenarioInPlace(npcHandle, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)

        SetModelAsNoLongerNeeded(model)

        -- Blip
        if Config.Shop.BlipAktiviert then
            local blip = AddBlipForCoord(px, py, pz)
            SetBlipSprite(blip, Config.Shop.BlipSprite)
            SetBlipColour(blip, Config.Shop.BlipFarbe)
            SetBlipScale(blip, Config.Shop.BlipMassstab)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(Config.Shop.BlipName)
            EndTextCommandSetBlipName(blip)
        end

        -- Interaktions-Loop
        while true do
            Wait(0)
            local ped    = PlayerPedId()
            local pedPos = GetEntityCoords(ped)
            local npcPos = GetEntityCoords(npcHandle)
            local dist   = #(pedPos - npcPos)

            if dist < Config.Shop.NPCInteraktionsRadius then
                -- Hinweis-Text anzeigen
                SetTextFont(4)
                SetTextProportional(1)
                SetTextScale(0.0, 0.45)
                SetTextColour(255, 255, 255, 215)
                SetTextDropShadow()
                SetTextEntry('STRING')
                AddTextComponentString(T('ui_oeffnen'))
                DrawText(0.5, 0.85)

                if IsControlJustReleased(0, Config.Shop.NPCInteraktionsTaste) then
                    if uiOffen then SchliesseUI() else OeffneUI() end
                end
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  ITEM-SYSTEM: Usable Items registrieren
-- ─────────────────────────────────────────────────────────────────────────────

if Config.Shop.ItemSystemAktiviert then
    for _, los in ipairs(Config.Lose) do
        local losId   = los.id
        local losItem = los.item
        ESX.RegisterUsableItem(losItem, function(source)
            TriggerServerEvent('MTJ_Lose:BenutzeItem', losId)
            OeffneUI()
        end)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  RESSOURCEN-START: Notify-System sofort initialisieren
--  (funktioniert auch OHNE geöffnete UI)
-- ─────────────────────────────────────────────────────────────────────────────

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- Kurz warten bis NUI bereit ist
    Wait(500)
    SendNUIMessage({
        action = 'notifyInit',
        config = Config.Notify,
    })
    Log('Notify-System initialisiert (Position: ' .. (Config.Notify and Config.Notify.Position or 'top-right') .. ')')
end)
