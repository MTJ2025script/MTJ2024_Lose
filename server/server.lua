local ESX           = exports['es_extended']:getSharedObject()
math.randomseed(os.time())

local useOxInventory = Config.InventoryType == 'ox_inventory'

-- ============================================================
--  LIVE CONFIG (aus DB geladen, überschreibt config.lua)
-- ============================================================
local LiveTickets    = {}   -- { id, itemName, label, ticketBg, shopPrice, prizes={...} }
local configReady    = false

-- ============================================================
--  HELFER: Admin-Berechtigung prüfen
-- ============================================================
local function isAdmin(src)
    -- Methode 1: spezifische ACE-Permission (mtj_los.admin)
    if IsPlayerAceAllowed(src, 'mtj_los.admin') then return true end
    -- Methode 2: allgemeine Admin-ACE (FiveM-Standard für ESX-Server)
    if IsPlayerAceAllowed(src, 'command') then return true end
    -- Methode 3: ESX-Gruppe als Fallback
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    for _, g in ipairs(Config.AdminGroups) do
        if group == g then return true end
    end
    return false
end

-- ============================================================
--  HELFER: Ticket per Item-Name finden
-- ============================================================
local function getTicketConfig(itemName)
    for _, ticket in ipairs(LiveTickets) do
        if ticket.itemName == itemName then return ticket end
    end
    return nil
end

-- ============================================================
--  HELFER: Gewichtete Zufalls-Auswahl
-- ============================================================
local function rollPrize(prizes)
    if not prizes or #prizes == 0 then
        return { type = 'nothing', label = 'Keine Preise konfiguriert', image = '' }
    end
    local total = 0
    for _, prize in ipairs(prizes) do total = total + (prize.chance or 0) end
    if total <= 0 then
        return prizes[#prizes] or { type = 'nothing', label = 'Keine Preise konfiguriert', image = '' }
    end
    local roll, cumulative = math.random(1, total), 0
    for _, prize in ipairs(prizes) do
        cumulative = cumulative + (prize.chance or 0)
        if roll <= cumulative then return prize end
    end
    return prizes[#prizes]
end

-- ============================================================
--  INVENTAR-HELFER
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
    if useOxInventory then exports.ox_inventory:RemoveItem(src, itemName, 1)
    else xPlayer.removeInventoryItem(itemName, 1) end
end

local function addPlayerItem(src, xPlayer, itemName, count)
    if useOxInventory then exports.ox_inventory:AddItem(src, itemName, count)
    else xPlayer.addInventoryItem(itemName, count) end
end

local function addPlayerWeapon(src, xPlayer, weaponName, ammo)
    if useOxInventory then
        exports.ox_inventory:AddItem(src, weaponName:lower(), 1, { ammo = ammo or 0 })
    else
        xPlayer.addWeapon(weaponName, ammo or 0)
    end
end

-- ============================================================
--  USABLE ITEMS REGISTRIEREN
-- ============================================================
local pendingScratches = {}

local function registerUsableItem(ticket)
    local t = ticket
    local handler = function(source)
        if pendingScratches[source] then return end
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end
        if not playerHasItem(source, xPlayer, t.itemName) then return end
        removePlayerItem(source, xPlayer, t.itemName)
        pendingScratches[source] = t.itemName
        TriggerClientEvent('mtj_los:client:openTicket', source, {
            itemName = t.itemName,
            label    = t.label,
            ticketBg = t.ticketBg,
        })
    end

    if useOxInventory then
        exports.ox_inventory:RegisterUsableItem(t.itemName, handler)
    else
        ESX.RegisterUsableItem(t.itemName, handler)
    end
end

local function registerAllUsableItems()
    for _, ticket in ipairs(LiveTickets) do
        registerUsableItem(ticket)
    end
end

-- ============================================================
--  DB: LIVE CONFIG LADEN
-- ============================================================
local function loadLiveConfig(callback)
    exports['oxmysql']:query([[
        SELECT
            t.id AS ticket_id, t.item_name AS ticket_item, t.label AS ticket_label,
            t.ticket_bg, t.shop_price,
            p.id AS prize_id, p.type AS prize_type, p.label AS prize_label,
            p.image, p.chance, p.amount, p.item_name AS prize_item,
            p.weapon, p.ammo, p.car_model
        FROM mtj_los_tickets t
        LEFT JOIN mtj_los_prizes p ON p.ticket_id = t.id
        WHERE t.active = 1
        ORDER BY t.id, p.id
    ]], {}, function(rows)
        local ticketMap   = {}
        local ticketOrder = {}

        if rows then
            for _, row in ipairs(rows) do
                if not ticketMap[row.ticket_id] then
                    ticketMap[row.ticket_id] = {
                        id        = row.ticket_id,
                        itemName  = row.ticket_item,
                        label     = row.ticket_label,
                        ticketBg  = row.ticket_bg  or '',
                        shopPrice = row.shop_price  or 500,
                        prizes    = {},
                    }
                    table.insert(ticketOrder, row.ticket_id)
                end
                if row.prize_id then
                    table.insert(ticketMap[row.ticket_id].prizes, {
                        id      = row.prize_id,
                        type    = row.prize_type  or 'nothing',
                        label   = row.prize_label or '',
                        image   = row.image       or '',
                        chance  = row.chance      or 10,
                        amount  = row.amount      or 0,
                        item    = row.prize_item  or '',
                        weapon  = row.weapon      or '',
                        ammo    = row.ammo        or 0,
                        model   = row.car_model   or '',
                    })
                end
            end
        end

        LiveTickets = {}
        for _, id in ipairs(ticketOrder) do
            table.insert(LiveTickets, ticketMap[id])
        end

        if callback then callback() end
    end)
end

-- ============================================================
--  DB: SEED AUS CONFIG.LUA (erster Start)
-- ============================================================
local function seedFromConfig(callback)
    local count = #Config.Tickets
    if count == 0 then if callback then callback() end return end

    local done = 0
    for _, ticket in ipairs(Config.Tickets) do
        exports['oxmysql']:insert(
            'INSERT IGNORE INTO mtj_los_tickets (item_name, label, ticket_bg, shop_price) VALUES (?, ?, ?, ?)',
            { ticket.itemName, ticket.label, ticket.ticketBg or '', ticket.shopPrice or 500 },
            function(ticketId)
                if ticketId and ticketId > 0 then
                    for _, prize in ipairs(ticket.prizes or {}) do
                        exports['oxmysql']:insert(
                            'INSERT INTO mtj_los_prizes (ticket_id, type, label, image, chance, amount, item_name, weapon, ammo, car_model) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                            { ticketId, prize.type, prize.label, prize.image or '',
                              prize.chance or 10, prize.amount or 0,
                              prize.item or '', prize.weapon or '', prize.ammo or 0, prize.model or '' },
                            function() end
                        )
                    end
                end
                done = done + 1
                if done == count and callback then callback() end
            end
        )
    end
end

-- ============================================================
--  STARTUP
-- ============================================================
AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    exports['oxmysql']:query('SELECT COUNT(*) as cnt FROM mtj_los_tickets', {}, function(res)
        local cnt = (res and res[1] and res[1].cnt) or 0
        if cnt == 0 then
            seedFromConfig(function()
                Wait(500)
                loadLiveConfig(function()
                    registerAllUsableItems()
                    configReady = true
                    print(('[MTJ Los] %d Los-Typen aus Config geladen und in DB gespeichert.'):format(#LiveTickets))
                end)
            end)
        else
            loadLiveConfig(function()
                registerAllUsableItems()
                configReady = true
                print(('[MTJ Los] %d Los-Typen aus Datenbank geladen.'):format(#LiveTickets))
            end)
        end
    end)
end)

-- ============================================================
--  EVENT: Los aufrubbeln
-- ============================================================
RegisterNetEvent('mtj_los:server:scratch')
AddEventHandler('mtj_los:server:scratch', function(itemName)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not configReady then
        TriggerClientEvent('mtj_los:client:result', src, { type = 'nothing', label = 'Server lädt noch' })
        return
    end

    if pendingScratches[src] ~= itemName then
        print(('[MTJ Los] WARNUNG: Kein pending scratch für %s (erwartet: %s, bekommen: %s)'):format(
            src, tostring(pendingScratches[src]), tostring(itemName)))
        TriggerClientEvent('mtj_los:client:result', src, { type = 'nothing', label = 'Kein gültiges Los' })
        return
    end
    pendingScratches[src] = nil

    local ticketCfg = getTicketConfig(itemName)
    if not ticketCfg then
        print(('[MTJ Los] WARNUNG: Kein TicketConfig für Item "%s"'):format(tostring(itemName)))
        TriggerClientEvent('mtj_los:client:result', src, { type = 'nothing', label = 'Ungültiges Los' })
        return
    end

    local prize = rollPrize(ticketCfg.prizes)
    if not prize then
        TriggerClientEvent('mtj_los:client:result', src, { type = 'nothing', label = 'Kein Preis verfügbar' })
        return
    end

    print(('[MTJ Los] %s kratzt %s → %s (%s)'):format(src, itemName, tostring(prize.type), tostring(prize.label)))

    -- Ergebnis SOFORT an Client schicken
    TriggerClientEvent('mtj_los:client:result', src, prize)

    -- Preis vergeben + DB in eigenem Thread
    Citizen.CreateThread(function()
        local ok, err = pcall(function()
            if prize.type == 'money' then
                xPlayer.addMoney(prize.amount or 0)
            elseif prize.type == 'item' then
                if prize.item and prize.item ~= '' then
                    addPlayerItem(src, xPlayer, prize.item, prize.amount or 1)
                end
            elseif prize.type == 'weapon' then
                if prize.weapon and prize.weapon ~= '' then
                    addPlayerWeapon(src, xPlayer, prize.weapon, prize.ammo or 0)
                end
            elseif prize.type == 'car' then
                if prize.model and prize.model ~= '' then
                    TriggerClientEvent('mtj_los:client:spawnCar', src, prize.model, prize.label)
                end
            end
        end)
        if not ok then
            print(('[MTJ Los] FEHLER beim Preis vergeben: %s'):format(tostring(err)))
        end

        local identifier = tostring(src)
        local playerName = tostring(src)
        pcall(function()
            identifier = xPlayer.getIdentifier()
            playerName = xPlayer.getName()
        end)
        print(('[MTJ Los] %s (%s) → %s → %s'):format(playerName, src, ticketCfg.label, tostring(prize.label)))

        pcall(function()
            exports['oxmysql']:insert(
                'INSERT INTO mtj_los_history (player_identifier, player_name, ticket_item, prize_type, prize_label) VALUES (?, ?, ?, ?, ?)',
                { identifier, playerName, itemName, prize.type, prize.label },
                function() end
            )
        end)
    end)
end)

-- ============================================================
--  EVENT: UI geschlossen ohne zu rubbeln (pending aufräumen)
-- ============================================================
RegisterNetEvent('mtj_los:server:cancelTicket')
AddEventHandler('mtj_los:server:cancelTicket', function()
    pendingScratches[source] = nil
end)

-- ============================================================
--  CLEANUP: pendingScratches bei Disconnect bereinigen
-- ============================================================
AddEventHandler('playerDropped', function()
    pendingScratches[source] = nil
end)

-- ============================================================
--  HILFE: Alle Ticket-Daten für Admin serialisieren
-- ============================================================
local function serializeTickets()
    local out = {}
    for _, t in ipairs(LiveTickets) do
        local prizes = {}
        for _, p in ipairs(t.prizes) do
            table.insert(prizes, {
                id     = p.id,   type   = p.type,   label  = p.label,
                image  = p.image, chance = p.chance, amount = p.amount,
                item   = p.item,  weapon = p.weapon,  ammo   = p.ammo,
                model  = p.model,
            })
        end
        table.insert(out, {
            id        = t.id,       itemName  = t.itemName,
            label     = t.label,    ticketBg  = t.ticketBg,
            shopPrice = t.shopPrice, prizes   = prizes,
        })
    end
    return out
end

-- ============================================================
--  ADMIN: Los-Daten laden (Client öffnet Admin-Tablet)
-- ============================================================
RegisterNetEvent('mtj_los:admin:open')
AddEventHandler('mtj_los:admin:open', function()
    local src = source
    if not isAdmin(src) then
        -- NUI zurückschicken damit der Client den Fokus freigibt
        TriggerClientEvent('mtj_los:admin:sendData', src, {
            action  = 'admin:denied',
            message = 'Keine Admin-Berechtigung.',
        })
        print(('[MTJ Los] Admin-Zugriff verweigert für Spieler %s'):format(src))
        return
    end
    TriggerClientEvent('mtj_los:admin:sendData', src, {
        action  = 'admin:open',
        tickets = serializeTickets(),
    })
end)

-- ============================================================
--  ADMIN: Ticket speichern (Neu / Update)
-- ============================================================
RegisterNetEvent('mtj_los:admin:saveTicket')
AddEventHandler('mtj_los:admin:saveTicket', function(data)
    local src = source
    if not isAdmin(src) then return end

    if data.id then
        exports['oxmysql']:execute(
            'UPDATE mtj_los_tickets SET label=?, ticket_bg=?, shop_price=? WHERE id=?',
            { data.label, data.ticketBg or '', data.shopPrice or 500, data.id },
            function()
                loadLiveConfig(function()
                    registerAllUsableItems()
                    TriggerClientEvent('mtj_los:admin:sendData', src, {
                        action  = 'admin:ticketsUpdated',
                        tickets = serializeTickets(),
                        msg     = 'Los aktualisiert',
                    })
                end)
            end
        )
    else
        exports['oxmysql']:insert(
            'INSERT INTO mtj_los_tickets (item_name, label, ticket_bg, shop_price) VALUES (?, ?, ?, ?)',
            { data.itemName, data.label, data.ticketBg or '', data.shopPrice or 500 },
            function(newId)
                -- Item auch in ESX items eintragen
                exports['oxmysql']:insert(
                    'INSERT IGNORE INTO items (name, label, weight, rare, can_remove) VALUES (?, ?, 1, 0, 1)',
                    { data.itemName, data.label },
                    function() end
                )
                loadLiveConfig(function()
                    registerAllUsableItems()
                    TriggerClientEvent('mtj_los:admin:sendData', src, {
                        action  = 'admin:ticketsUpdated',
                        tickets = serializeTickets(),
                        msg     = 'Neues Los erstellt',
                    })
                end)
            end
        )
    end
end)

-- ============================================================
--  ADMIN: Ticket löschen
-- ============================================================
RegisterNetEvent('mtj_los:admin:deleteTicket')
AddEventHandler('mtj_los:admin:deleteTicket', function(data)
    local src = source
    if not isAdmin(src) then return end
    exports['oxmysql']:execute('DELETE FROM mtj_los_tickets WHERE id=?', { data.id }, function()
        loadLiveConfig(function()
            TriggerClientEvent('mtj_los:admin:sendData', src, {
                action  = 'admin:ticketsUpdated',
                tickets = serializeTickets(),
                msg     = 'Los gelöscht',
            })
        end)
    end)
end)

-- ============================================================
--  ADMIN: Preis speichern
-- ============================================================
RegisterNetEvent('mtj_los:admin:savePrize')
AddEventHandler('mtj_los:admin:savePrize', function(data)
    local src = source
    if not isAdmin(src) then return end

    if data.id then
        exports['oxmysql']:execute([[
            UPDATE mtj_los_prizes
            SET type=?, label=?, image=?, chance=?, amount=?, item_name=?, weapon=?, ammo=?, car_model=?
            WHERE id=?]],
            { data.type, data.label, data.image or '', data.chance or 10,
              data.amount or 0, data.item or '', data.weapon or '', data.ammo or 0,
              data.model or '', data.id },
            function()
                loadLiveConfig(function()
                    TriggerClientEvent('mtj_los:admin:sendData', src, {
                        action  = 'admin:ticketsUpdated',
                        tickets = serializeTickets(),
                        msg     = 'Preis aktualisiert',
                    })
                end)
            end
        )
    else
        exports['oxmysql']:insert([[
            INSERT INTO mtj_los_prizes (ticket_id, type, label, image, chance, amount, item_name, weapon, ammo, car_model)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
            { data.ticketId, data.type, data.label, data.image or '', data.chance or 10,
              data.amount or 0, data.item or '', data.weapon or '', data.ammo or 0, data.model or '' },
            function()
                loadLiveConfig(function()
                    TriggerClientEvent('mtj_los:admin:sendData', src, {
                        action  = 'admin:ticketsUpdated',
                        tickets = serializeTickets(),
                        msg     = 'Preis hinzugefügt',
                    })
                end)
            end
        )
    end
end)

-- ============================================================
--  ADMIN: Preis löschen
-- ============================================================
RegisterNetEvent('mtj_los:admin:deletePrize')
AddEventHandler('mtj_los:admin:deletePrize', function(data)
    local src = source
    if not isAdmin(src) then return end
    exports['oxmysql']:execute('DELETE FROM mtj_los_prizes WHERE id=?', { data.id }, function()
        loadLiveConfig(function()
            TriggerClientEvent('mtj_los:admin:sendData', src, {
                action  = 'admin:ticketsUpdated',
                tickets = serializeTickets(),
                msg     = 'Preis gelöscht',
            })
        end)
    end)
end)

-- ============================================================
--  ADMIN: Online-Spieler abrufen
-- ============================================================
RegisterNetEvent('mtj_los:admin:getPlayers')
AddEventHandler('mtj_los:admin:getPlayers', function()
    local src = source
    if not isAdmin(src) then return end

    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local pid      = tonumber(playerId)
        local xPlayer  = ESX.GetPlayerFromId(pid)
        if xPlayer then
            table.insert(players, {
                id         = pid,
                name       = xPlayer.getName(),
                identifier = xPlayer.getIdentifier(),
                job        = xPlayer.getJob() and xPlayer.getJob().label or '—',
            })
        end
    end

    TriggerClientEvent('mtj_los:admin:sendData', src, {
        action  = 'admin:playersUpdated',
        players = players,
    })
end)

-- ============================================================
--  ADMIN: Item an Spieler geben
-- ============================================================
RegisterNetEvent('mtj_los:admin:giveItem')
AddEventHandler('mtj_los:admin:giveItem', function(data)
    local src     = source
    if not isAdmin(src) then return end

    local target  = ESX.GetPlayerFromId(data.playerId)
    if not target then
        TriggerClientEvent('mtj_los:admin:sendData', src, { action='admin:toast', message='Spieler nicht gefunden', type='error' })
        return
    end

    addPlayerItem(data.playerId, target, data.itemName, 1)
    TriggerClientEvent('mtj_los:admin:sendData', src, {
        action  = 'admin:toast',
        message = ('Los "%s" an %s gegeben'):format(data.itemName, target.getName()),
        type    = 'success',
    })
end)

-- ============================================================
--  ADMIN: ESX Items abrufen
-- ============================================================
RegisterNetEvent('mtj_los:admin:getEsxItems')
AddEventHandler('mtj_los:admin:getEsxItems', function()
    local src = source
    if not isAdmin(src) then return end
    exports['oxmysql']:query("SELECT name, label, weight, rare FROM items WHERE name LIKE 'mtj_%' ORDER BY name", {}, function(rows)
        TriggerClientEvent('mtj_los:admin:sendData', src, {
            action = 'admin:esxItemsUpdated',
            items  = rows or {},
        })
    end)
end)

-- ============================================================
--  ADMIN: ESX Item hinzufügen
-- ============================================================
RegisterNetEvent('mtj_los:admin:addEsxItem')
AddEventHandler('mtj_los:admin:addEsxItem', function(data)
    local src = source
    if not isAdmin(src) then return end
    exports['oxmysql']:insert(
        'INSERT IGNORE INTO items (name, label, weight, rare, can_remove) VALUES (?, ?, ?, ?, 1)',
        { data.name, data.label, data.weight or 1, data.rare or 0 },
        function()
            exports['oxmysql']:query("SELECT name, label, weight, rare FROM items WHERE name LIKE 'mtj_%' ORDER BY name", {}, function(rows)
                TriggerClientEvent('mtj_los:admin:sendData', src, {
                    action = 'admin:esxItemsUpdated',
                    items  = rows or {},
                    msg    = 'Item gespeichert',
                })
            end)
        end
    )
end)

-- ============================================================
--  ADMIN: Statistiken abrufen
-- ============================================================
RegisterNetEvent('mtj_los:admin:getStats')
AddEventHandler('mtj_los:admin:getStats', function()
    local src = source
    if not isAdmin(src) then return end

    exports['oxmysql']:query('SELECT COUNT(*) as total FROM mtj_los_history', {}, function(resTotal)
        local total = (resTotal and resTotal[1] and resTotal[1].total) or 0
        exports['oxmysql']:query("SELECT COUNT(*) as wins FROM mtj_los_history WHERE prize_type != 'nothing'", {}, function(resWins)
            local wins   = (resWins and resWins[1] and resWins[1].wins) or 0
            local losses = total - wins
            local winRate = total > 0 and math.floor(wins / total * 100) or 0
            exports['oxmysql']:query([[
                SELECT player_name AS playerName, ticket_item AS ticketItem,
                       prize_type AS prizeType, prize_label AS prizeLabel,
                       scratched_at AS scratchedAt
                FROM mtj_los_history ORDER BY scratched_at DESC LIMIT 20
            ]], {}, function(history)
                TriggerClientEvent('mtj_los:admin:sendData', src, {
                    action = 'admin:statsUpdated',
                    stats  = {
                        totalScratched = total,
                        totalWins      = wins,
                        totalLosses    = losses,
                        winRate        = winRate,
                        history        = history or {},
                    },
                })
            end)
        end)
    end)
end)

-- ============================================================
--  ADMIN: Verlauf löschen
-- ============================================================
RegisterNetEvent('mtj_los:admin:clearHistory')
AddEventHandler('mtj_los:admin:clearHistory', function()
    local src = source
    if not isAdmin(src) then return end
    exports['oxmysql']:execute('DELETE FROM mtj_los_history', {}, function()
        TriggerClientEvent('mtj_los:admin:sendData', src, {
            action = 'admin:statsUpdated',
            stats  = { totalScratched=0, totalWins=0, totalLosses=0, winRate=0, history={} },
        })
        TriggerClientEvent('mtj_los:admin:sendData', src, {
            action='admin:toast', message='Verlauf gelöscht', type='success'
        })
    end)
end)
