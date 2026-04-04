'use strict';

/* ============================================================
   ADMIN STATE
   ============================================================ */
let adminData = {
    tickets:  [],
    players:  [],
    esxItems: [],
    stats:    {},
};
let adminActiveTab     = 'tickets';
let adminSelectedTicketId = null;
let adminModalMode     = null;   // 'ticket' | 'prize' | 'esxitem'
let adminEditingId     = null;   // ID des bearbeiteten Datensatzes

/* ============================================================
   NUI-NACHRICHTEN (empfangen vom Client)
   ============================================================ */
window.addEventListener('message', (event) => {
    const d = event.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'admin:open':
            adminData.tickets = d.tickets || [];
            openAdmin(d);
            break;
        case 'admin:ticketsUpdated':
            adminData.tickets = d.tickets || [];
            if (adminActiveTab === 'tickets' || adminActiveTab === 'prizes') {
                renderAdminTab(adminActiveTab);
            }
            closeModal();
            showToast(d.msg || 'Gespeichert', 'success');
            break;
        case 'admin:playersUpdated':
            adminData.players = d.players || [];
            if (adminActiveTab === 'players') renderAdminTab('players');
            break;
        case 'admin:esxItemsUpdated':
            adminData.esxItems = d.items || [];
            if (adminActiveTab === 'database') renderAdminTab('database');
            closeModal();
            showToast(d.msg || 'Item gespeichert', 'success');
            break;
        case 'admin:statsUpdated':
            adminData.stats = d.stats || {};
            if (adminActiveTab === 'stats') renderAdminTab('stats');
            break;
        case 'admin:toast':
            showToast(d.message, d.type || 'info');
            break;
        case 'admin:error':
            showToast(d.message || 'Fehler', 'error');
            break;
    }
});

/* ============================================================
   ADMIN ÖFFNEN / SCHLIESSEN
   ============================================================ */
function openAdmin(data) {
    const screen = document.getElementById('screen-admin');
    if (screen) {
        screen.style.display = 'flex';
        document.body.style.display = 'block';
        document.body.style.pointerEvents = 'auto';
    }
    adminTab('tickets');

    // Spieler sofort laden
    adminNuiCall('admin:getPlayers', {});
    // Statistiken laden
    adminNuiCall('admin:getStats', {});
    // ESX-Items laden
    adminNuiCall('admin:getEsxItems', {});
}

function closeAdmin() {
    const screen = document.getElementById('screen-admin');
    if (screen) screen.style.display = 'none';
    adminNuiCall('admin:close', {});
}

/* ============================================================
   TAB NAVIGATION
   ============================================================ */
function adminTab(tab) {
    adminActiveTab = tab;
    document.querySelectorAll('.adm-tab').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === tab);
    });
    renderAdminTab(tab);
}

function renderAdminTab(tab) {
    const content = document.getElementById('admin-content');
    if (!content) return;

    switch (tab) {
        case 'tickets':  content.innerHTML = renderTicketsTab();  break;
        case 'prizes':   content.innerHTML = renderPrizesTab();   break;
        case 'players':  content.innerHTML = renderPlayersTab();  break;
        case 'database': content.innerHTML = renderDatabaseTab(); break;
        case 'stats':    content.innerHTML = renderStatsTab();    break;
    }
}

/* ============================================================
   TAB: LOS-TYPEN
   ============================================================ */
function renderTicketsTab() {
    const tickets = adminData.tickets;
    const totalPrizes = tickets.reduce((s, t) => s + (t.prizes ? t.prizes.length : 0), 0);
    const totalScratched = adminData.stats.totalScratched || 0;
    const winRate = adminData.stats.winRate || 0;

    const rows = tickets.length === 0
        ? `<tr><td colspan="8">
            <div class="adm-empty">
                <div class="adm-empty-icon">🎟</div>
                <div>Noch keine Los-Typen angelegt</div>
            </div>
           </td></tr>`
        : tickets.map(t => {
            const prizes = t.prizes || [];
            const totalChance = prizes.reduce((s, p) => s + (p.chance || 0), 0);
            const winChance = prizes.filter(p => p.type !== 'nothing')
                .reduce((s, p) => s + (p.chance || 0), 0);
            const winPct = totalChance > 0 ? Math.round(winChance / totalChance * 100) : 0;
            const barColor = winPct > 50 ? '#22c55e' : winPct > 25 ? '#f59e0b' : '#ef4444';

            return `<tr>
                <td><span class="adm-code">${esc(t.itemName)}</span></td>
                <td><strong style="color:#f5d060;">${esc(t.label)}</strong></td>
                <td><span style="color:rgba(201,168,76,.5);font-size:12px;">${esc(t.ticketBg || '—')}</span></td>
                <td><span style="color:#22c55e;font-weight:700;">${fmtMoney(t.shopPrice)}</span></td>
                <td><span style="color:#f5d060;font-weight:700;">${prizes.length}</span></td>
                <td>
                    <div class="adm-chance-wrap">
                        <div class="adm-chance-bar">
                            <div class="adm-chance-fill" style="width:${winPct}%;background:${barColor};"></div>
                        </div>
                        <span style="font-size:12px;color:${barColor};font-weight:600;">${winPct}%</span>
                    </div>
                </td>
                <td><span class="adm-badge adm-badge-active">● Aktiv</span></td>
                <td>
                    <div style="display:flex;gap:6px;flex-wrap:wrap;">
                        <button class="adm-btn-sm adm-btn-edit"    onclick="openTicketModal(${t.id})">✏ Edit</button>
                        <button class="adm-btn-sm adm-btn-prize"   onclick="adminTab('prizes');adminSelectedTicketId=${t.id};renderAdminTab('prizes');">🏆 Preise</button>
                        <button class="adm-btn-sm adm-btn-del"     onclick="deleteTicket(${t.id},'${esc(t.label)}')">🗑</button>
                    </div>
                </td>
            </tr>`;
        }).join('');

    return `
        <div class="adm-stats-grid">
            <div class="adm-stat-card gold">
                <div class="adm-stat-val">${tickets.length}</div>
                <div class="adm-stat-lbl">Los-Typen</div>
                <div class="adm-stat-trend">↑ Alle aktiv</div>
            </div>
            <div class="adm-stat-card blue">
                <div class="adm-stat-val">${totalPrizes}</div>
                <div class="adm-stat-lbl">Preise gesamt</div>
                <div class="adm-stat-trend">Konfiguriert</div>
            </div>
            <div class="adm-stat-card green">
                <div class="adm-stat-val">${totalScratched.toLocaleString('de')}</div>
                <div class="adm-stat-lbl">Mal aufgerubbelt</div>
                <div class="adm-stat-trend">Gesamt</div>
            </div>
            <div class="adm-stat-card red">
                <div class="adm-stat-val">${winRate}%</div>
                <div class="adm-stat-lbl">Ø Gewinnquote</div>
                <div class="adm-stat-trend">Alle Lose</div>
            </div>
        </div>
        <div class="adm-table-wrap">
            <div class="adm-table-hdr">
                <div>
                    <h3>♠ Los-Typen verwalten</h3>
                    <div class="adm-table-hdr-sub">Alle Lose — Preise per Klick verwalten</div>
                </div>
                <button class="adm-btn-gold" onclick="openTicketModal(null)">＋ Neues Los</button>
            </div>
            <table class="adm-table">
                <thead><tr>
                    <th>ITEM-NAME</th><th>BEZEICHNUNG</th><th>HINTERGRUND</th>
                    <th>PREIS</th><th>PREISE</th><th>GEWINNCHANCE</th><th>STATUS</th><th>AKTIONEN</th>
                </tr></thead>
                <tbody>${rows}</tbody>
            </table>
        </div>`;
}

/* ============================================================
   TAB: PREISE
   ============================================================ */
function renderPrizesTab() {
    const tickets = adminData.tickets;
    if (tickets.length === 0) {
        return `<div class="adm-empty"><div class="adm-empty-icon">🏆</div><div>Erst Los-Typen anlegen</div></div>`;
    }

    if (!adminSelectedTicketId || !tickets.find(t => t.id === adminSelectedTicketId)) {
        adminSelectedTicketId = tickets[0].id;
    }

    const ticket = tickets.find(t => t.id === adminSelectedTicketId) || tickets[0];
    const prizes = ticket.prizes || [];
    const totalChance = prizes.reduce((s, p) => s + (p.chance || 0), 0);

    const ticketOpts = tickets.map(t =>
        `<option value="${t.id}" ${t.id === adminSelectedTicketId ? 'selected' : ''}>${esc(t.label)}</option>`
    ).join('');

    // Chance-Verteilung
    const distSegs = prizes.map(p => {
        const col = prizeColor(p.type);
        const pct = totalChance > 0 ? Math.round(p.chance / totalChance * 100) : 0;
        return `<div class="adm-dist-seg" style="flex:${p.chance};background:${col};">${pct > 6 ? pct + '%' : ''}</div>`;
    }).join('');

    const rows = prizes.length === 0
        ? `<tr><td colspan="6"><div class="adm-empty"><div class="adm-empty-icon">🏆</div><div>Noch keine Preise</div></div></td></tr>`
        : prizes.map(p => {
            const col   = prizeColor(p.type);
            const badge = prizeBadge(p.type);
            const pct   = totalChance > 0 ? Math.round(p.chance / totalChance * 100) : 0;
            const detail = prizeDetail(p);
            return `<tr>
                <td><span class="adm-badge ${badge}">${prizeIcon(p.type)} ${prizeTypeName(p.type)}</span></td>
                <td><strong style="color:#f0e0b0;">${esc(p.label)}</strong></td>
                <td style="color:rgba(201,168,76,.4);font-size:12px;">${esc(detail)}</td>
                <td style="color:rgba(201,168,76,.4);font-size:12px;">${esc(p.image || '—')}</td>
                <td>
                    <div class="adm-chance-wrap">
                        <div class="adm-chance-bar">
                            <div class="adm-chance-fill" style="width:${Math.min(pct,100)}%;background:${col};"></div>
                        </div>
                        <span style="font-size:12px;color:#f0e0b0;font-weight:600;">${p.chance}</span>
                    </div>
                </td>
                <td>
                    <div style="display:flex;gap:6px;">
                        <button class="adm-btn-sm adm-btn-edit" onclick="openPrizeModal(${ticket.id},${p.id})">✏ Edit</button>
                        <button class="adm-btn-sm adm-btn-del"  onclick="deletePrize(${p.id},'${esc(p.label)}')">🗑</button>
                    </div>
                </td>
            </tr>`;
        }).join('');

    return `
        <div style="display:flex;align-items:center;gap:12px;margin-bottom:18px;flex-wrap:wrap;">
            <select class="adm-form-select" style="width:auto;" onchange="adminSelectedTicketId=parseInt(this.value);renderAdminTab('prizes');">
                ${ticketOpts}
            </select>
            <span style="color:rgba(201,168,76,.4);font-size:12px;">
                ${prizes.length} Preis${prizes.length !== 1 ? 'e' : ''} · Summe: ${totalChance}
            </span>
            <button class="adm-btn-gold" style="margin-left:auto;" onclick="openPrizeModal(${ticket.id},null)">＋ Preis hinzufügen</button>
        </div>

        <div class="adm-dist-wrap">
            <div class="adm-dist-title">Gewinnverteilung</div>
            <div class="adm-dist-bar">${distSegs || '<div style="flex:1;background:rgba(201,168,76,.1);"></div>'}</div>
            <div class="adm-dist-legend">
                <span style="color:#22c55e;">● Geld</span>
                <span style="color:#60a5fa;">● Item</span>
                <span style="color:#f87171;">● Waffe</span>
                <span style="color:#f5d060;">● Fahrzeug</span>
                <span style="color:#6b7280;">● Niete</span>
            </div>
        </div>

        <div class="adm-table-wrap">
            <table class="adm-table">
                <thead><tr>
                    <th>TYP</th><th>BEZEICHNUNG</th><th>DETAILS</th><th>BILD</th><th>CHANCE</th><th>AKTIONEN</th>
                </tr></thead>
                <tbody>${rows}</tbody>
            </table>
        </div>`;
}

/* ============================================================
   TAB: SPIELER
   ============================================================ */
function renderPlayersTab() {
    const players = adminData.players;
    const cards = players.length === 0
        ? `<div class="adm-empty"><div class="adm-empty-icon">👥</div><div>Keine Spieler online</div></div>`
        : `<div class="adm-player-grid">${players.map(p => {
            const ticketOpts = adminData.tickets.map(t =>
                `<option value="${esc(t.itemName)}">${esc(t.label)}</option>`
            ).join('');
            return `<div class="adm-player-card">
                <div class="adm-player-name">👤 ${esc(p.name)}</div>
                <div class="adm-player-info">
                    <span>ID: ${p.id}</span>
                    <span>Job: ${esc(p.job || '—')}</span>
                    <span style="font-size:10px;word-break:break-all;">${esc(p.identifier)}</span>
                </div>
                <div class="adm-player-actions">
                    <select class="adm-form-select" id="give-sel-${p.id}" style="flex:1;padding:5px 8px;font-size:12px;">
                        ${ticketOpts}
                    </select>
                    <button class="adm-btn-sm adm-btn-give" onclick="giveItem(${p.id})">🎟 Geben</button>
                </div>
            </div>`;
        }).join('')}</div>`;

    return `
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;flex-wrap:wrap;gap:10px;">
            <div>
                <div style="font-size:15px;font-weight:700;color:#f5d060;">👥 Online-Spieler</div>
                <div style="font-size:12px;color:rgba(201,168,76,.4);margin-top:3px;">${players.length} Spieler online</div>
            </div>
            <button class="adm-btn-gold" onclick="adminNuiCall('admin:getPlayers',{})">🔄 Aktualisieren</button>
        </div>
        ${cards}`;
}

/* ============================================================
   TAB: DATENBANK
   ============================================================ */
function renderDatabaseTab() {
    const items = adminData.esxItems;

    const rows = items.length === 0
        ? `<tr><td colspan="5"><div class="adm-empty"><div class="adm-empty-icon">🗄</div><div>Keine Items geladen</div></div></td></tr>`
        : items.map(i => `<tr>
            <td><span class="adm-code">${esc(i.name)}</span></td>
            <td style="color:#f0e0b0;">${esc(i.label)}</td>
            <td style="color:rgba(201,168,76,.4);">${i.weight}</td>
            <td>${i.rare ? '<span class="adm-badge adm-badge-car">★ Selten</span>' : '<span style="color:rgba(201,168,76,.3);font-size:12px;">Normal</span>'}</td>
            <td><span class="adm-badge adm-badge-active">● Aktiv</span></td>
           </tr>`).join('');

    // SQL generieren
    const sqlLines = adminData.tickets.map(t =>
        `INSERT IGNORE INTO \`items\` (\`name\`,\`label\`,\`weight\`,\`rare\`,\`can_remove\`) VALUES ('${t.itemName}','${t.label}',1,0,1);`
    ).join('\n');

    return `
        <div class="adm-db-section">
            <div class="adm-db-section-title">🗄 ESX Items Tabelle</div>
            <div class="adm-table-wrap">
                <div class="adm-table-hdr">
                    <div>
                        <h3>Registrierte Items</h3>
                        <div class="adm-table-hdr-sub">Zeigt Los-Items aus der ESX items-Tabelle</div>
                    </div>
                    <div style="display:flex;gap:8px;">
                        <button class="adm-btn-gold" onclick="openEsxItemModal()">＋ Item hinzufügen</button>
                        <button class="adm-btn-ghost" onclick="adminNuiCall('admin:getEsxItems',{})">🔄</button>
                    </div>
                </div>
                <table class="adm-table">
                    <thead><tr><th>NAME</th><th>LABEL</th><th>GEWICHT</th><th>SELTENHEIT</th><th>STATUS</th></tr></thead>
                    <tbody>${rows}</tbody>
                </table>
            </div>
        </div>

        <div class="adm-divider"></div>

        <div class="adm-db-section">
            <div class="adm-db-section-title">📋 SQL Generator</div>
            <div style="font-size:12px;color:rgba(201,168,76,.4);margin-bottom:10px;">
                Generiertes SQL für alle aktuellen Los-Items (z.B. für esx_shops oder neue Server):
            </div>
            <div class="adm-sql-box">${esc(sqlLines || '-- Keine Lose konfiguriert')}</div>
            <div style="margin-top:10px;display:flex;gap:8px;">
                <button class="adm-btn-ghost" onclick="copySql()">📋 SQL kopieren</button>
            </div>
        </div>`;
}

/* ============================================================
   TAB: STATISTIKEN
   ============================================================ */
function renderStatsTab() {
    const s = adminData.stats;
    const total   = s.totalScratched || 0;
    const wins    = s.totalWins      || 0;
    const losses  = s.totalLosses    || 0;
    const winRate = total > 0 ? Math.round(wins / total * 100) : 0;
    const history = s.history || [];

    const histRows = history.length === 0
        ? `<tr><td colspan="5"><div class="adm-empty" style="padding:24px;"><div>Noch kein Verlauf</div></div></td></tr>`
        : history.map(h => `<tr>
            <td style="color:#f5d060;">${esc(h.playerName)}</td>
            <td><span class="adm-code">${esc(h.ticketItem)}</span></td>
            <td><span class="adm-badge ${prizeBadge(h.prizeType)}">${prizeTypeName(h.prizeType)}</span></td>
            <td style="color:#f0e0b0;">${esc(h.prizeLabel)}</td>
            <td style="color:rgba(201,168,76,.4);font-size:12px;">${formatDate(h.scratchedAt)}</td>
           </tr>`).join('');

    return `
        <div class="adm-stats-grid">
            <div class="adm-stat-card gold">
                <div class="adm-stat-val">${total.toLocaleString('de')}</div>
                <div class="adm-stat-lbl">Lose aufgerubbelt</div>
                <div class="adm-stat-trend">Gesamt</div>
            </div>
            <div class="adm-stat-card green">
                <div class="adm-stat-val">${wins.toLocaleString('de')}</div>
                <div class="adm-stat-lbl">Gewonnen</div>
                <div class="adm-stat-trend">↑ Gewinne</div>
            </div>
            <div class="adm-stat-card red">
                <div class="adm-stat-val">${losses.toLocaleString('de')}</div>
                <div class="adm-stat-lbl">Nieten</div>
                <div class="adm-stat-trend">Kein Gewinn</div>
            </div>
            <div class="adm-stat-card blue">
                <div class="adm-stat-val">${winRate}%</div>
                <div class="adm-stat-lbl">Gewinnquote</div>
                <div class="adm-stat-trend">Durchschnitt</div>
            </div>
        </div>

        <div class="adm-table-wrap adm-history-table">
            <div class="adm-table-hdr">
                <div>
                    <h3>📜 Letzte Gewinnverläufe</h3>
                    <div class="adm-table-hdr-sub">Die 20 letzten Kratz-Vorgänge</div>
                </div>
                <div style="display:flex;gap:8px;">
                    <button class="adm-btn-gold" onclick="adminNuiCall('admin:getStats',{})">🔄 Aktualisieren</button>
                    <button class="adm-btn-del adm-btn-sm" style="padding:7px 14px;font-size:12px;" onclick="clearHistory()">🗑 Verlauf löschen</button>
                </div>
            </div>
            <table class="adm-table">
                <thead><tr>
                    <th>SPIELER</th><th>LOS</th><th>TYP</th><th>GEWINN</th><th>DATUM</th>
                </tr></thead>
                <tbody>${histRows}</tbody>
            </table>
        </div>`;
}

/* ============================================================
   MODALS
   ============================================================ */
function openTicketModal(ticketId) {
    adminModalMode = 'ticket';
    adminEditingId = ticketId;

    const ticket = ticketId ? adminData.tickets.find(t => t.id === ticketId) : null;
    document.getElementById('admin-modal-title').textContent =
        ticket ? `✏ Los bearbeiten: ${ticket.label}` : '＋ Neues Los erstellen';

    document.getElementById('admin-modal-body').innerHTML = `
        <div class="adm-form-grid">
            <div class="adm-form-field">
                <label class="adm-form-label">Item-Name (ESX)</label>
                <input class="adm-form-input" id="mf-itemName"
                    value="${esc(ticket ? ticket.itemName : '')}"
                    placeholder="mtj_los_diamond"
                    ${ticket ? 'readonly style="opacity:.5;"' : ''} />
            </div>
            <div class="adm-form-field">
                <label class="adm-form-label">Bezeichnung</label>
                <input class="adm-form-input" id="mf-label"
                    value="${esc(ticket ? ticket.label : '')}"
                    placeholder="Diamond Los" />
            </div>
            <div class="adm-form-field">
                <label class="adm-form-label">Hintergrundbild</label>
                <input class="adm-form-input" id="mf-ticketBg"
                    value="${esc(ticket ? ticket.ticketBg : '')}"
                    placeholder="ticket_diamond.png" />
            </div>
            <div class="adm-form-field">
                <label class="adm-form-label">Shoppreis ($)</label>
                <input class="adm-form-input" id="mf-shopPrice" type="number"
                    value="${ticket ? ticket.shopPrice : '500'}"
                    min="0" />
            </div>
        </div>
        <div class="adm-info-box">
            ♦ Der Item-Name muss in der ESX <strong>items</strong>-Tabelle existieren.<br>
            Nutze den <strong>Datenbank</strong>-Tab um Items anzulegen.
        </div>`;

    showModal();
}

function openPrizeModal(ticketId, prizeId) {
    adminModalMode = 'prize';
    adminEditingId = prizeId;
    adminSelectedTicketId = ticketId;

    const ticket = adminData.tickets.find(t => t.id === ticketId);
    const prize  = prizeId && ticket ? (ticket.prizes || []).find(p => p.id === prizeId) : null;

    document.getElementById('admin-modal-title').textContent =
        prize ? `✏ Preis bearbeiten` : `＋ Preis hinzufügen — ${ticket ? ticket.label : ''}`;

    const type = prize ? prize.type : 'money';

    document.getElementById('admin-modal-body').innerHTML = `
        <div class="adm-form-field">
            <label class="adm-form-label">Preis-Typ</label>
            <div class="adm-type-grid">
                ${[
                    {t:'money',   ico:'💵', lbl:'Geld',     col:'#22c55e', rgb:'34,197,94'},
                    {t:'item',    ico:'📦', lbl:'Item',     col:'#60a5fa', rgb:'96,165,250'},
                    {t:'weapon',  ico:'��', lbl:'Waffe',    col:'#f87171', rgb:'248,113,113'},
                    {t:'car',     ico:'🚗', lbl:'Fahrzeug', col:'#f5d060', rgb:'245,208,96'},
                    {t:'nothing', ico:'❌', lbl:'Niete',    col:'#6b7280', rgb:'107,114,128'},
                ].map(o => `
                    <button class="adm-type-btn ${type === o.t ? 'active' : ''}"
                        style="--type-col:${o.col};--type-rgb:${o.rgb};"
                        onclick="selectPrizeType('${o.t}',this)">
                        <span class="adm-type-btn-icon">${o.ico}</span>
                        <span class="adm-type-btn-lbl">${o.lbl}</span>
                    </button>`).join('')}
            </div>
        </div>
        <div class="adm-form-grid">
            <div class="adm-form-field">
                <label class="adm-form-label">Bezeichnung</label>
                <input class="adm-form-input" id="mf-plabel"
                    value="${esc(prize ? prize.label : '')}" placeholder="z.B. 10.000 $" />
            </div>
            <div class="adm-form-field">
                <label class="adm-form-label">Bild-Datei (html/images/)</label>
                <input class="adm-form-input" id="mf-pimage"
                    value="${esc(prize ? prize.image : '')}" placeholder="prize_money.png" />
            </div>
            <div class="adm-form-field">
                <label class="adm-form-label">Chance (Gewichtung)</label>
                <input class="adm-form-input" id="mf-pchance" type="number"
                    value="${prize ? prize.chance : '10'}" min="1" />
            </div>
            <div class="adm-form-field">
                <label class="adm-form-label">Betrag / Anzahl</label>
                <input class="adm-form-input" id="mf-pamount" type="number"
                    value="${prize ? prize.amount : '0'}" min="0" />
            </div>
            <div class="adm-form-field" id="mf-item-field" style="${type==='item'?'':'display:none'}">
                <label class="adm-form-label">Item-Name (ESX)</label>
                <input class="adm-form-input" id="mf-pitem"
                    value="${esc(prize ? prize.item : '')}" placeholder="bread" />
            </div>
            <div class="adm-form-field" id="mf-weapon-field" style="${type==='weapon'?'':'display:none'}">
                <label class="adm-form-label">Waffen-Hash</label>
                <input class="adm-form-input" id="mf-pweapon"
                    value="${esc(prize ? prize.weapon : '')}" placeholder="WEAPON_PISTOL" />
            </div>
            <div class="adm-form-field" id="mf-ammo-field" style="${type==='weapon'?'':'display:none'}">
                <label class="adm-form-label">Munition</label>
                <input class="adm-form-input" id="mf-pammo" type="number"
                    value="${prize ? prize.ammo : '0'}" min="0" />
            </div>
            <div class="adm-form-field" id="mf-car-field" style="${type==='car'?'':'display:none'}">
                <label class="adm-form-label">Fahrzeug-Modell</label>
                <input class="adm-form-input" id="mf-pcar"
                    value="${esc(prize ? prize.model : '')}" placeholder="sultan" />
            </div>
        </div>
        <div class="adm-info-box">
            ♠ <strong>Chance</strong> ist eine relative Gewichtung.<br>
            Gewinn-% = chance / Summe aller chances × 100
        </div>`;

    // Typ hidden field
    if (!document.getElementById('mf-ptype')) {
        const inp = document.createElement('input');
        inp.type = 'hidden'; inp.id = 'mf-ptype'; inp.value = type;
        document.getElementById('admin-modal-body').appendChild(inp);
    } else {
        document.getElementById('mf-ptype').value = type;
    }

    showModal();
}

function openEsxItemModal() {
    adminModalMode = 'esxitem';
    adminEditingId = null;
    document.getElementById('admin-modal-title').textContent = '＋ ESX Item hinzufügen';
    document.getElementById('admin-modal-body').innerHTML = `
        <div class="adm-form-grid">
            <div class="adm-form-field">
                <label class="adm-form-label">Item-Name</label>
                <input class="adm-form-input" id="mf-ename" placeholder="mtj_los_diamond" />
            </div>
            <div class="adm-form-field">
                <label class="adm-form-label">Bezeichnung</label>
                <input class="adm-form-input" id="mf-elabel" placeholder="Diamond Los" />
            </div>
            <div class="adm-form-field">
                <label class="adm-form-label">Gewicht</label>
                <input class="adm-form-input" id="mf-eweight" type="number" value="1" min="0" />
            </div>
            <div class="adm-form-field">
                <label class="adm-form-label">Selten</label>
                <select class="adm-form-select" id="mf-erare">
                    <option value="0">Nein</option>
                    <option value="1">Ja</option>
                </select>
            </div>
        </div>
        <div class="adm-info-box">
            ♣ Das Item wird direkt in die ESX <strong>items</strong>-Tabelle eingetragen.
        </div>`;
    showModal();
}

function selectPrizeType(type, btn) {
    document.querySelectorAll('.adm-type-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    const inp = document.getElementById('mf-ptype');
    if (inp) inp.value = type;
    // Bedingte Felder
    const show = (id, vis) => {
        const el = document.getElementById(id);
        if (el) el.style.display = vis ? '' : 'none';
    };
    show('mf-item-field',   type === 'item');
    show('mf-weapon-field', type === 'weapon');
    show('mf-ammo-field',   type === 'weapon');
    show('mf-car-field',    type === 'car');
}

/* ── Modal anzeigen ── */
function showModal() {
    const m = document.getElementById('admin-modal');
    if (m) m.classList.remove('adm-hidden');
}

function closeModal() {
    const m = document.getElementById('admin-modal');
    if (m) m.classList.add('adm-hidden');
}

/* ── Speichern ── */
function saveModal() {
    if (adminModalMode === 'ticket')  saveTicket();
    if (adminModalMode === 'prize')   savePrize();
    if (adminModalMode === 'esxitem') saveEsxItem();
}

function saveTicket() {
    const data = {
        id:        adminEditingId,
        itemName:  val('mf-itemName'),
        label:     val('mf-label'),
        ticketBg:  val('mf-ticketBg'),
        shopPrice: parseInt(val('mf-shopPrice')) || 500,
    };
    if (!data.label) { showToast('Bezeichnung fehlt', 'error'); return; }
    if (!adminEditingId && !data.itemName) { showToast('Item-Name fehlt', 'error'); return; }
    adminNuiCall('admin:saveTicket', data);
}

function savePrize() {
    const type = val('mf-ptype') || 'money';
    const data = {
        id:       adminEditingId,
        ticketId: adminSelectedTicketId,
        type:     type,
        label:    val('mf-plabel'),
        image:    val('mf-pimage'),
        chance:   parseInt(val('mf-pchance')) || 10,
        amount:   parseInt(val('mf-pamount')) || 0,
        item:     val('mf-pitem'),
        weapon:   val('mf-pweapon'),
        ammo:     parseInt(val('mf-pammo')) || 0,
        model:    val('mf-pcar'),
    };
    if (!data.label) { showToast('Bezeichnung fehlt', 'error'); return; }
    adminNuiCall('admin:savePrize', data);
}

function saveEsxItem() {
    const data = {
        name:   val('mf-ename'),
        label:  val('mf-elabel'),
        weight: parseInt(val('mf-eweight')) || 1,
        rare:   parseInt(val('mf-erare'))   || 0,
    };
    if (!data.name || !data.label) { showToast('Name und Label erforderlich', 'error'); return; }
    adminNuiCall('admin:addEsxItem', data);
}

/* ============================================================
   AKTIONEN
   ============================================================ */
function deleteTicket(id, label) {
    if (!confirm(`Los "${label}" wirklich löschen?\nAlle zugehörigen Preise werden ebenfalls gelöscht.`)) return;
    adminNuiCall('admin:deleteTicket', { id });
}

function deletePrize(id, label) {
    if (!confirm(`Preis "${label}" wirklich löschen?`)) return;
    adminNuiCall('admin:deletePrize', { id });
}

function giveItem(playerId) {
    const sel = document.getElementById(`give-sel-${playerId}`);
    if (!sel) return;
    const itemName = sel.value;
    if (!itemName) { showToast('Kein Los ausgewählt', 'error'); return; }
    adminNuiCall('admin:giveItem', { playerId, itemName });
}

function clearHistory() {
    if (!confirm('Gesamten Verlauf unwiderruflich löschen?')) return;
    adminNuiCall('admin:clearHistory', {});
}

function copySql() {
    const box = document.querySelector('.adm-sql-box');
    if (!box) return;
    try {
        navigator.clipboard.writeText(box.textContent);
        showToast('SQL kopiert!', 'success');
    } catch {
        showToast('Manuell markieren und kopieren', 'info');
    }
}

/* ============================================================
   NUI FETCH → CLIENT
   ============================================================ */
function adminNuiCall(action, data) {
    fetch(`https://${window.location.hostname}/${action}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data || {}),
    }).catch(() => {});
}

/* ============================================================
   TOAST
   ============================================================ */
function showToast(msg, type) {
    type = type || 'info';
    const container = document.getElementById('admin-toast-container');
    if (!container) return;

    const icons = { success: '✓', error: '✕', info: '♦' };
    const t = document.createElement('div');
    t.className = `adm-toast ${type}`;
    t.innerHTML = `<span>${icons[type] || '♦'}</span><span>${esc(msg)}</span>`;
    container.appendChild(t);

    setTimeout(() => {
        t.style.transition = 'opacity .3s, transform .3s';
        t.style.opacity = '0';
        t.style.transform = 'translateX(40px)';
        setTimeout(() => t.remove(), 320);
    }, 3200);
}

/* ============================================================
   HELFER
   ============================================================ */
function val(id) {
    const el = document.getElementById(id);
    return el ? el.value.trim() : '';
}

function esc(str) {
    if (str == null) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function fmtMoney(n) {
    return (n || 0).toLocaleString('de') + ' $';
}

function formatDate(ts) {
    if (!ts) return '—';
    try {
        const d = new Date(ts);
        return d.toLocaleString('de-DE', { day:'2-digit', month:'2-digit', hour:'2-digit', minute:'2-digit' });
    } catch { return ts; }
}

function prizeColor(type) {
    const map = { money:'#22c55e', item:'#60a5fa', weapon:'#f87171', car:'#f5d060', nothing:'#6b7280' };
    return map[type] || '#6b7280';
}

function prizeBadge(type) {
    const map = { money:'adm-badge-money', item:'adm-badge-item', weapon:'adm-badge-weapon', car:'adm-badge-car', nothing:'adm-badge-nothing' };
    return map[type] || 'adm-badge-nothing';
}

function prizeIcon(type) {
    const map = { money:'💵', item:'📦', weapon:'🔫', car:'🚗', nothing:'❌' };
    return map[type] || '❓';
}

function prizeTypeName(type) {
    const map = { money:'Geld', item:'Item', weapon:'Waffe', car:'Fahrzeug', nothing:'Niete' };
    return map[type] || type;
}

function prizeDetail(p) {
    if (!p) return '';
    if (p.type === 'money')  return `${(p.amount||0).toLocaleString('de')} $`;
    if (p.type === 'item')   return `${p.item || '?'} × ${p.amount || 0}`;
    if (p.type === 'weapon') return `${p.weapon || '?'} · ${p.ammo || 0} Schuss`;
    if (p.type === 'car')    return `Modell: ${p.model || '?'}`;
    return '—';
}
