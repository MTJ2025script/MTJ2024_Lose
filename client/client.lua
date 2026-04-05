local ESX = exports['es_extended']:getSharedObject()

-- ============================================================
--  FOKUS-STATE
--  nuiFocusActive  – true solange NUI den Fokus hält
--  resultArrived   – true sobald der Server ein Result schickt
--  focusSession    – Zähler: verhindert dass alte Phase-Timer
--                    neue Ticket- oder Admin-Sessions stören
-- ============================================================
local nuiFocusActive = false
local resultArrived  = false
local focusSession   = 0

local function releaseFocus()
    nuiFocusActive = false
    SetNuiFocus(false, false)
end

-- ============================================================
--  TICKET ÖFFNEN
--  Server sendet table { itemName, label, ticketBg }
-- ============================================================
RegisterNetEvent('mtj_los:client:openTicket')
AddEventHandler('mtj_los:client:openTicket', function(data)
    focusSession   = focusSession + 1
    local mySession = focusSession

    nuiFocusActive = true
    resultArrived  = false
    SetNuiFocus(true, true)

    -- Phase 1: Falls der Server innerhalb von 12 s kein Result schickt
    --          → Fokus zwangsweise freigeben (Kamera-Freeze-Schutz)
    Citizen.CreateThread(function()
        Citizen.Wait(12000)
        if focusSession == mySession and nuiFocusActive and not resultArrived then
            releaseFocus()
            SendNUIMessage({ action = 'forceClose' })
        end
    end)

    SendNUIMessage({
        action   = 'openTicket',
        itemName = data.itemName or data,
        label    = data.label    or '',
        ticketBg = data.ticketBg or '',
    })
end)

-- ============================================================
--  ERGEBNIS ANZEIGEN
-- ============================================================
RegisterNetEvent('mtj_los:client:result')
AddEventHandler('mtj_los:client:result', function(prize)
    resultArrived = true   -- Phase-1-Timer wird damit inaktiv

    SendNUIMessage({
        action = 'showResult',
        win    = prize.type ~= 'nothing',
        label  = prize.label or '',
        image  = prize.image or '',
    })

    -- Phase 2: Spieler hat 30 s Zeit das Ergebnis zu lesen.
    --          Danach Fokus zwangsweise freigeben (Kamera-Freeze-Schutz).
    local mySession = focusSession
    Citizen.CreateThread(function()
        Citizen.Wait(30000)
        if focusSession == mySession and nuiFocusActive then
            releaseFocus()
            SendNUIMessage({ action = 'forceClose' })
        end
    end)
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
--  NUI CALLBACKS – Spieler
-- ============================================================
RegisterNUICallback('scratchTicket', function(data, cb)
    TriggerServerEvent('mtj_los:server:scratch', data.itemName)
    cb({ ok = true })
end)

RegisterNUICallback('closeUI', function(_, cb)
    releaseFocus()
    TriggerServerEvent('mtj_los:server:cancelTicket')
    cb({ ok = true })
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
