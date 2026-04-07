local ESX = exports['es_extended']:getSharedObject()

-- ============================================================
--  FOKUS-STATE
-- ============================================================
local nuiFocusActive = false
local resultArrived  = false
local focusSession   = 0

local function releaseFocus()
    nuiFocusActive = false
    SetNuiFocus(false, false)
end

-- ============================================================
--  HELFER: RP-Notification
-- ============================================================
local function notify(msg, typ)
    -- typ: 'success' | 'error' | 'info'  (wird für Farbe genutzt)
    if typ == 'success' then
        ESX.ShowNotification('~g~' .. msg)
    elseif typ == 'error' then
        ESX.ShowNotification('~r~' .. msg)
    else
        ESX.ShowNotification('~y~' .. msg)
    end
end

-- ============================================================
--  TICKET ÖFFNEN – Prize-Daten kommen mit dem Event
--  Das NUI speichert die Prize-Daten selbst (pendingPrizeWin etc.)
--  und zeigt sie direkt nach dem scratchTicket-fetch() an.
-- ============================================================
RegisterNetEvent('mtj_los:client:openTicket')
AddEventHandler('mtj_los:client:openTicket', function(data)
    focusSession   = focusSession + 1
    local mySession = focusSession

    nuiFocusActive = true
    resultArrived  = false

    SetNuiFocus(true, true)

    notify('🎟 Du hast ein ' .. (data.label or 'Los') .. ' gezogen – reiß es auf!', 'info')

    -- Sicherheits-Timeout: 90 s (falls Spieler nie kratzt)
    Citizen.CreateThread(function()
        Citizen.Wait(90000)
        if focusSession == mySession and nuiFocusActive and not resultArrived then
            releaseFocus()
            SendNUIMessage({ action = 'forceClose' })
            notify('⏱ Los abgelaufen – Kein Aufreißen innerhalb der Zeit.', 'error')
        end
    end)

    SendNUIMessage({
        action     = 'openTicket',
        itemName   = data.itemName or data,
        label      = data.label      or '',
        ticketBg   = data.ticketBg   or '',
        prizeWin   = data.prizeWin,
        prizeLabel = data.prizeLabel or '',
        prizeImage = data.prizeImage or '',
    })
end)

-- ============================================================
--  NUI CALLBACKS – Spieler
-- ============================================================
RegisterNUICallback('scratchTicket', function(_, cb)
    resultArrived = true

    -- *** FOKUS SOFORT FREIGEBEN ***
    -- Kamera bewegt sich wieder; die Win/Lose-Anzeige bleibt sichtbar.
    -- Kein Warten auf Button-Klick – das war der Grund für den Freeze.
    releaseFocus()

    -- Server: Preis vergeben + DB-Log
    TriggerServerEvent('mtj_los:server:scratch')

    -- Auto-Close nach 30 s falls Spieler nicht klickt.
    -- SESSION-AWARE: mySession verhindert, dass dieser Timer
    -- in eine neue Los-Session hineinschießt.
    local mySession = focusSession
    Citizen.CreateThread(function()
        Citizen.Wait(30000)
        if focusSession == mySession then
            SendNUIMessage({ action = 'forceClose' })
        end
    end)

    cb({ ok = true })
end)

RegisterNUICallback('closeUI', function(_, cb)
    -- Fokus wurde bereits in scratchTicket freigegeben.
    -- Sicherheitshalber nochmal, falls closeUI direkt (z. B. Age-Gate "Nein") kommt.
    releaseFocus()
    TriggerServerEvent('mtj_los:server:cancelTicket')
    cb({ ok = true })
end)

-- ============================================================
--  SERVER → CLIENT: Gewinn-/Niete-Notification
-- ============================================================
RegisterNetEvent('mtj_los:client:prizeNotify')
AddEventHandler('mtj_los:client:prizeNotify', function(win, label)
    if win then
        notify('🎉 Glückwunsch! Du hast gewonnen: ' .. tostring(label), 'success')
    else
        notify('💸 Leider nichts. ' .. tostring(label) .. ' – Vielleicht beim nächsten Mal!', 'error')
    end
end)

-- ============================================================
--  SERVER → CLIENT: Debug-Nachrichten ans NUI weiterleiten
-- ============================================================
RegisterNetEvent('mtj_los:client:serverDebug')
AddEventHandler('mtj_los:client:serverDebug', function(msg)
    SendNUIMessage({ action = 'debug:serverMsg', msg = tostring(msg) })
end)

-- ============================================================
--  FAHRZEUG SPAWNEN
-- ============================================================
RegisterNetEvent('mtj_los:client:spawnCar')
AddEventHandler('mtj_los:client:spawnCar', function(model, label)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end
    if not HasModelLoaded(modelHash) then
        ESX.ShowNotification('[MTJ Los] Fahrzeug-Modell nicht geladen.')
        return
    end
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local offset = Config.CarSpawnOffset or { x = 5.0, y = 0.0, z = 0.0 }
    local veh    = CreateVehicle(modelHash,
        coords.x + offset.x, coords.y + offset.y, coords.z + (offset.z or 0.5),
        GetEntityHeading(ped), true, false)
    SetModelAsNoLongerNeeded(modelHash)
    if veh and veh ~= 0 then
        SetVehicleNumberPlateText(veh, 'MTJ LOS')
        SetEntityAsMissionEntity(veh, true, true)
        ESX.ShowNotification(('🚗 %s gespawnt!'):format(label or model))
    end
end)

-- ============================================================
--  SERVER → CLIENT: Admin-Daten → NUI
-- ============================================================
RegisterNetEvent('mtj_los:admin:sendData')
AddEventHandler('mtj_los:admin:sendData', function(payload)
    SendNUIMessage(payload)
end)

-- ============================================================
--  NUI CALLBACKS – Admin
-- ============================================================
local adminCbs = {
    'admin:open', 'admin:saveTicket', 'admin:deleteTicket',
    'admin:savePrize', 'admin:deletePrize', 'admin:getPlayers',
    'admin:giveItem', 'admin:getEsxItems', 'admin:addEsxItem',
    'admin:getStats', 'admin:clearHistory',
}

for _, cbName in ipairs(adminCbs) do
    local evtName = 'mtj_los:' .. cbName
    RegisterNUICallback(cbName, function(data, cb)
        TriggerServerEvent(evtName, data)
        cb({ ok = true })
    end)
end

RegisterNUICallback('admin:close', function(_, cb)
    releaseFocus()
    cb({ ok = true })
end)

-- ============================================================
--  ADMIN BEFEHL (/losadmin)
-- ============================================================
RegisterCommand(Config.AdminCommand or 'losadmin', function()
    -- Fokus-State setzen damit F10 und Safety-Mechanismen greifen
    focusSession   = focusSession + 1
    nuiFocusActive = true
    resultArrived  = true   -- verhindert dass ein laufender Ticket-Phase-1-Timer feuert
    SetNuiFocus(true, true)
    TriggerServerEvent('mtj_los:admin:open')
end, false)

-- ============================================================
--  NOTFALL-EXIT: Kamera-Freeze beheben (/losclose oder F10)
-- ============================================================
RegisterCommand('losclose', function()
    releaseFocus()
    TriggerServerEvent('mtj_los:server:cancelTicket')
    SendNUIMessage({ action = 'forceClose' })
end, false)

RegisterKeyMapping('losclose', 'MTJ Los – UI schliessen (Notfall-Exit)', 'keyboard', 'F10')

-- ============================================================
--  DEBUG TOGGLE (/losdebug)
-- ============================================================
RegisterCommand('losdebug', function()
    SendNUIMessage({ action = 'debug:toggle' })
end, false)
