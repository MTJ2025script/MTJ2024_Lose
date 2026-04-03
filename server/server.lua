local ESX = exports['es_extended']:getSharedObject()
math.randomseed(os.time())

local useOxInventory = Config.InventoryType == 'ox_inventory'

-- ============================================================
--  Hilfsfunktion: Gewinn-Tabelle nach Item-Name abrufen
-- ============================================================
local function getTicketConfig(itemName)
    for _, ticket in ipairs(Config.Tickets) do
        if ticket.itemName == itemName then
            return ticket
        end
    end
    return nil
end

-- ============================================================
--  Gewinn ermitteln (gewichtete Zufalls-Auswahl)
-- ============================================================
local function rollPrize(prizes)
    local total = 0
    for _, prize in ipairs(prizes) do
        total = total + (prize.chance or 0)
    end

    local roll = math.random(1, total)
    local cumulative = 0
    for _, prize in ipairs(prizes) do
        cumulative = cumulative + (prize.chance or 0)
        if roll <= cumulative then
            return prize
        end
    end
    return prizes[#prizes]
end

-- ============================================================
--  Inventar-Helfer (ESX / ox_inventory)
-- ============================================================
local function playerHasItem(src, xPlayer, itemName)
    if useOxInventory then
        local item = exports.ox_inventory:GetItem(src, itemName, nil, false)
        return item ~= nil and item.count > 0
    end
    local item = xPlayer.getInventoryItem(itemName)
    return item ~= nil and item.count > 0
end

local function removePlayerItem(src, xPlayer, itemName)
    if useOxInventory then
        exports.ox_inventory:RemoveItem(src, itemName, 1)
    else
        xPlayer.removeInventoryItem(itemName, 1)
    end
end

local function addPlayerItem(src, xPlayer, itemName, count)
    if useOxInventory then
        exports.ox_inventory:AddItem(src, itemName, count)
    else
        xPlayer.addInventoryItem(itemName, count)
    end
end

local function addPlayerWeapon(src, xPlayer, weaponName, ammo)
    if useOxInventory then
        -- In ox_inventory werden Waffen als Items gespeichert (lowercase Name)
        exports.ox_inventory:AddItem(src, weaponName:lower(), 1, { ammo = ammo or 0 })
    else
        xPlayer.addWeapon(weaponName, ammo or 0)
    end
end

-- ============================================================
--  Ausstehende Kratz-Vorgaenge pro Spieler
--  (Schluessel = source, Wert = itemName)
-- ============================================================
local pendingScratches = {}

-- ============================================================
--  Usable Items server-seitig registrieren
-- ============================================================
AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, ticket in ipairs(Config.Tickets) do
        local t = ticket
        if useOxInventory then
            exports.ox_inventory:RegisterUsableItem(t.itemName, function(source)
                -- Verhindere doppeltes Oeffnen
                if pendingScratches[source] then return end

                local xPlayer = ESX.GetPlayerFromId(source)
                if not xPlayer then return end

                -- Item sofort entfernen, bevor die UI geöffnet wird
                if not playerHasItem(source, xPlayer, t.itemName) then return end
                removePlayerItem(source, xPlayer, t.itemName)

                pendingScratches[source] = t.itemName
                TriggerClientEvent('mtj_los:client:openTicket', source, t.itemName)
            end)
        else
            ESX.RegisterUsableItem(t.itemName, function(source)
                -- Verhindere doppeltes Oeffnen
                if pendingScratches[source] then return end

                local xPlayer = ESX.GetPlayerFromId(source)
                if not xPlayer then return end

                -- Item sofort entfernen, bevor die UI geöffnet wird
                if not playerHasItem(source, xPlayer, t.itemName) then return end
                removePlayerItem(source, xPlayer, t.itemName)

                pendingScratches[source] = t.itemName
                TriggerClientEvent('mtj_los:client:openTicket', source, t.itemName)
            end)
        end
    end
end)

-- ============================================================
--  Event: Spieler kratzt sein Los auf
-- ============================================================
RegisterNetEvent('mtj_los:server:scratch')
AddEventHandler('mtj_los:server:scratch', function(itemName)
    local src    = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    -- Sicherstellen, dass der Spieler wirklich ein Los geoeffnet hat
    if pendingScratches[src] ~= itemName then
        TriggerClientEvent('mtj_los:client:result', src, { type = 'nothing', label = 'Kein gültiges Los' })
        return
    end
    pendingScratches[src] = nil

    local ticketCfg = getTicketConfig(itemName)
    if not ticketCfg then
        TriggerClientEvent('mtj_los:client:result', src, { type = 'nothing', label = 'Ungültiges Los' })
        return
    end

    local prize = rollPrize(ticketCfg.prizes)

    if prize.type == 'money' then
        xPlayer.addMoney(prize.amount)
        print(('[MTJ_Los] Spieler %s (%s) hat %s$ gewonnen.'):format(xPlayer.getName(), src, prize.amount))

    elseif prize.type == 'item' then
        addPlayerItem(src, xPlayer, prize.item, prize.amount)
        print(('[MTJ_Los] Spieler %s (%s) hat %dx %s gewonnen.'):format(xPlayer.getName(), src, prize.amount, prize.item))

    elseif prize.type == 'weapon' then
        addPlayerWeapon(src, xPlayer, prize.weapon, prize.ammo or 0)
        print(('[MTJ_Los] Spieler %s (%s) hat Waffe %s gewonnen.'):format(xPlayer.getName(), src, prize.weapon))

    elseif prize.type == 'car' then
        TriggerClientEvent('mtj_los:client:spawnCar', src, prize.model, prize.label)
        print(('[MTJ_Los] Spieler %s (%s) hat Fahrzeug %s gewonnen.'):format(xPlayer.getName(), src, prize.model))
    end

    TriggerClientEvent('mtj_los:client:result', src, prize)
end)
