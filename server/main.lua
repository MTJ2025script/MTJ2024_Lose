local ESX = exports['es_extended']:getSharedObject()
math.randomseed(os.time())

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
    -- Gesamtgewicht berechnen
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
    -- Fallback: letzter Eintrag
    return prizes[#prizes]
end

-- ============================================================
--  Event: Spieler kratzt sein Los auf
-- ============================================================
RegisterNetEvent('mtj_los:server:scratch')
AddEventHandler('mtj_los:server:scratch', function(itemName)
    local src    = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    local ticketCfg = getTicketConfig(itemName)
    if not ticketCfg then
        TriggerClientEvent('mtj_los:client:result', src, { type = 'nothing', label = 'Ungültiges Los' })
        return
    end

    -- Pruefen ob Spieler das Item besitzt
    local item = xPlayer.getInventoryItem(itemName)
    if not item or item.count <= 0 then
        TriggerClientEvent('mtj_los:client:result', src, { type = 'nothing', label = 'Du hast kein Los' })
        return
    end

    -- Item entfernen (verbraucht)
    xPlayer.removeInventoryItem(itemName, 1)

    -- Gewinn ermitteln
    local prize = rollPrize(ticketCfg.prizes)

    -- Gewinn auszahlen
    if prize.type == 'money' then
        xPlayer.addMoney(prize.amount)
        print(('[MTJ_Los] Spieler %s (%s) hat %s$ gewonnen.'):format(xPlayer.getName(), src, prize.amount))

    elseif prize.type == 'item' then
        xPlayer.addInventoryItem(prize.item, prize.amount)
        print(('[MTJ_Los] Spieler %s (%s) hat %dx %s gewonnen.'):format(xPlayer.getName(), src, prize.amount, prize.item))

    elseif prize.type == 'weapon' then
        xPlayer.addWeapon(prize.weapon, prize.ammo or 0)
        print(('[MTJ_Los] Spieler %s (%s) hat Waffe %s gewonnen.'):format(xPlayer.getName(), src, prize.weapon))

    elseif prize.type == 'car' then
        -- Fahrzeug wird client-seitig gespawnt
        TriggerClientEvent('mtj_los:client:spawnCar', src, prize.model, prize.label)
        print(('[MTJ_Los] Spieler %s (%s) hat Fahrzeug %s gewonnen.'):format(xPlayer.getName(), src, prize.model))
    end

    -- Ergebnis an Client senden (fuer die UI)
    TriggerClientEvent('mtj_los:client:result', src, prize)
end)
