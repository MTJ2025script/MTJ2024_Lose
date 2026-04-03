local ESX = exports['es_extended']:getSharedObject()
local isNuiOpen = false

-- ============================================================
--  Hilfsfunktion: Benachrichtigung
-- ============================================================
local function Notify(msg, ntype)
    if Config.NotifyType == 'esx' then
        ESX.ShowNotification(msg)
    elseif Config.NotifyType == 'ox_lib' then
        lib.notify({ title = 'MTJ Los', description = msg, type = ntype or 'inform' })
    else
        -- Fallback
        ESX.ShowNotification(msg)
    end
end

-- ============================================================
--  Alle Los-Items registrieren
-- ============================================================
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, ticket in ipairs(Config.Tickets) do
        local t = ticket
        ESX.RegisterUsableItem(t.itemName, function()
            if isNuiOpen then return end
            isNuiOpen = true

            -- NUI oeffnen und Ticket-Daten uebergeben
            SetNuiFocus(true, true)
            SendNUIMessage({
                action    = 'openTicket',
                itemName  = t.itemName,
                label     = t.label,
                ticketBg  = t.ticketBg,
            })
        end)
    end
end)

-- ============================================================
--  NUI Callback: Spieler kratzt das Los auf
-- ============================================================
RegisterNUICallback('scratchTicket', function(data, cb)
    TriggerServerEvent('mtj_los:server:scratch', data.itemName)
    cb('ok')
end)

-- ============================================================
--  NUI Callback: UI schliessen (nach Gewinn/Verlust)
-- ============================================================
RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    isNuiOpen = false
    cb('ok')
end)

-- ============================================================
--  Server -> Client: Ergebnis erhalten
-- ============================================================
RegisterNetEvent('mtj_los:client:result')
AddEventHandler('mtj_los:client:result', function(prize)
    if prize.type == 'nothing' then
        -- Niete – Verlier-Anzeige
        SendNUIMessage({
            action = 'showResult',
            win    = false,
            label  = prize.label,
            image  = '',
        })
    else
        -- Gewinn – Vollbild-Geschenk-Animation
        SendNUIMessage({
            action = 'showResult',
            win    = true,
            label  = prize.label,
            image  = prize.image or '',
        })
    end
end)

-- ============================================================
--  Server -> Client: Fahrzeug spawnen (Gewinn: Auto)
-- ============================================================
RegisterNetEvent('mtj_los:client:spawnCar')
AddEventHandler('mtj_los:client:spawnCar', function(model, label)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(100) end

    local playerPed  = PlayerPedId()
    local coords     = GetEntityCoords(playerPed)
    local heading    = GetEntityHeading(playerPed)

    local spawnX = coords.x + Config.CarSpawnOffset.x
    local spawnY = coords.y + Config.CarSpawnOffset.y
    local spawnZ = coords.z + Config.CarSpawnOffset.z

    local vehicle = CreateVehicle(modelHash, spawnX, spawnY, spawnZ, heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    Notify('🚗 Dein Gewinn-Fahrzeug wurde gespawnt: ' .. label, 'success')
end)
