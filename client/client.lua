local ESX = exports['es_extended']:getSharedObject()
local isNuiOpen      = false
local useOxInventory = Config.InventoryType == 'ox_inventory'

-- ============================================================
--  Hilfsfunktion: Benachrichtigung
-- ============================================================
local function Notify(msg, ntype)
    if Config.NotifyType == 'esx' then
        ESX.ShowNotification(msg)
    elseif Config.NotifyType == 'ox_lib' then
        lib.notify({ title = 'MTJ Los', description = msg, type = ntype or 'inform' })
    else
        ESX.ShowNotification(msg)
    end
end

-- ============================================================
--  Hilfsfunktion: Ticket-UI oeffnen
-- ============================================================
local function openTicketUI(itemName)
    if isNuiOpen then return end

    local ticketCfg
    for _, t in ipairs(Config.Tickets) do
        if t.itemName == itemName then
            ticketCfg = t
            break
        end
    end
    if not ticketCfg then return end

    isNuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'openTicket',
        itemName = ticketCfg.itemName,
        label    = ticketCfg.label,
        ticketBg = ticketCfg.ticketBg,
    })
end

-- ============================================================
--  ESX: Alle Los-Items client-seitig registrieren
-- ============================================================
if not useOxInventory then
    AddEventHandler('onClientResourceStart', function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end

        for _, ticket in ipairs(Config.Tickets) do
            local t = ticket
            ESX.RegisterUsableItem(t.itemName, function()
                openTicketUI(t.itemName)
            end)
        end
    end)
end

-- ============================================================
--  ox_inventory: Ticket-UI oeffnen (server-seitig ausgeloest)
-- ============================================================
if useOxInventory then
    RegisterNetEvent('mtj_los:client:openTicket')
    AddEventHandler('mtj_los:client:openTicket', function(itemName)
        openTicketUI(itemName)
    end)
end

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
        SendNUIMessage({
            action = 'showResult',
            win    = false,
            label  = prize.label,
            image  = '',
        })
    else
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

    local playerPed = PlayerPedId()
    local coords    = GetEntityCoords(playerPed)
    local heading   = GetEntityHeading(playerPed)

    local vehicle = CreateVehicle(modelHash,
        coords.x + Config.CarSpawnOffset.x,
        coords.y + Config.CarSpawnOffset.y,
        coords.z + Config.CarSpawnOffset.z,
        heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    Notify('🚗 Dein Gewinn-Fahrzeug wurde gespawnt: ' .. label, 'success')
end)
