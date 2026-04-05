'use strict';

/* ============================================================
   STATE
   ============================================================ */
let currentItem    = null;
let scratchDone    = false;
let ageConfirmed   = false;
let resultReceived = false;
let resultTimeout  = null;

/* ── pending ticket data (wartet auf Age-Gate) ── */
let pendingTicket     = null;

/* ── Debug ── */
let debugEnabled = false;

/* ============================================================
   DEBUG-SYSTEM
   ============================================================ */
function debugLog(msg, type) {
    const t = type || 'info';
    console.log('[MTJ Los Debug] ' + msg);
    const panel = document.getElementById('dbg-log');
    if (!panel) return;
    const line = document.createElement('div');
    line.className = 'dbg-line dbg-' + t;
    const ts = new Date().toLocaleTimeString('de-DE', { hour12: false });
    line.textContent = '[' + ts + '] ' + msg;
    panel.prepend(line);
    while (panel.children.length > 30) panel.removeChild(panel.lastChild);
}

function updateDebugPanel() {
    const p = document.getElementById('debug-panel');
    if (!p) return;
    p.style.display = debugEnabled ? 'block' : 'none';
    if (!debugEnabled) return;

    document.getElementById('dbg-item').textContent     = currentItem || '—';
    document.getElementById('dbg-done').textContent     = scratchDone    ? '✓ JA' : '✗ NEIN';
    document.getElementById('dbg-received').textContent = resultReceived ? '✓ JA' : '✗ NEIN';
}

/* ============================================================
   SICHTBARKEIT
   ============================================================ */
function showScreen(id) {
    ['screen-agegate','screen-ticket','screen-win','screen-lose'].forEach(s => {
        const el = document.getElementById(s);
        if (el) el.style.display = (s === id) ? 'flex' : 'none';
    });
}

function hideAll() {
    ['screen-agegate','screen-ticket','screen-win','screen-lose'].forEach(s => {
        const el = document.getElementById(s);
        if (el) el.style.display = 'none';
    });
}

/* ============================================================
   FiveM NUI-NACHRICHTEN
   ============================================================ */
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'openTicket')    handleOpenTicket(data);
    if (data.action === 'showResult')    showResult(data);
    if (data.action === 'admin:open')    openAdmin(data);
    if (data.action === 'admin:denied')  handleAdminDenied(data);
    if (data.action === 'forceClose')    forceClose();
    if (data.action === 'debug:toggle')  toggleDebug();
});

function forceClose() {
    hideAll();
    resetUI();
    debugLog('forceClose ausgeführt (Notfall-Exit)', 'warn');
}

function handleAdminDenied(data) {
    debugLog('Admin-Zugriff verweigert: ' + (data.message || 'Keine Berechtigung'), 'error');
    /* Fokus über closeUI-Callback freigeben */
    fetch(`https://${window.location.hostname}/admin:close`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({}),
    }).catch(() => {});
}

function toggleDebug() {
    debugEnabled = !debugEnabled;
    updateDebugPanel();
    debugLog('Debug-Panel ' + (debugEnabled ? 'aktiviert' : 'deaktiviert'), 'ok');
}

/* ============================================================
   TICKET ÖFFNEN – erst Age-Gate zeigen
   ============================================================ */
function handleOpenTicket(data) {
    document.body.style.display      = 'block';
    document.body.style.pointerEvents = 'auto';

    if (!ageConfirmed) {
        pendingTicket = data;
        showScreen('screen-agegate');
        return;
    }
    openTicket(data);
}

/* ── Age-Gate bestätigen ── */
function confirmAge() {
    ageConfirmed  = true;
    if (pendingTicket) {
        openTicket(pendingTicket);
        pendingTicket = null;
    }
}

/* ============================================================
   TICKET UI
   ============================================================ */
function openTicket(data) {
    currentItem    = data.itemName;
    scratchDone    = false;
    resultReceived = false;
    if (resultTimeout) { clearTimeout(resultTimeout); resultTimeout = null; }

    debugLog('Ticket geöffnet: ' + currentItem, 'info');

    /* Hintergrund */
    const bg = document.getElementById('ticket-bg-img');
    if (data.ticketBg && data.ticketBg !== '') {
        bg.style.backgroundImage = `url('images/${data.ticketBg}')`;
    } else {
        bg.style.backgroundImage = '';
    }

    /* Label */
    document.getElementById('tkt-name-label').textContent = data.label || 'LOS';

    /* Seriennummer */
    const serial = 'MTJ-' + Math.random().toString(36).substring(2, 6).toUpperCase()
                 + '-' + String(Math.floor(Math.random() * 1000000)).padStart(6, '0');
    const serialEl = document.getElementById('ticket-serial-display');
    if (serialEl) serialEl.textContent = 'SER: ' + serial;

    /* Tear-Button zurücksetzen */
    const btn = document.getElementById('btn-tear');
    if (btn) { btn.disabled = false; btn.style.opacity = ''; }

    /* Partikel */
    spawnBgSuits();

    showScreen('screen-ticket');
    updateDebugPanel();
}

/* ── Casino-Hintergrund-Kartenzeichen ── */
function spawnBgSuits() {
    const root = document.getElementById('casino-bg-particles');
    if (!root) return;
    root.innerHTML = '';
    const suits = ['♠','♥','♦','♣'];
    for (let i = 0; i < 20; i++) {
        const s = document.createElement('div');
        s.className = 'bg-suit';
        s.textContent = suits[Math.floor(Math.random() * suits.length)];
        s.style.left     = `${Math.random() * 100}vw`;
        s.style.fontSize = `${16 + Math.random() * 32}px`;
        s.style.animationDuration = `${8 + Math.random() * 14}s`;
        s.style.animationDelay    = `${Math.random() * 10}s`;
        root.appendChild(s);
    }
}

/* ============================================================
   LOS AUFREISSEN
   ============================================================ */

/* CSS-Keyframes einmalig injizieren (FiveM CEF-safe, kein element.animate()) */
(function injectTearStyles() {
    if (document.getElementById('tear-keyframes')) return;
    const s = document.createElement('style');
    s.id = 'tear-keyframes';
    s.textContent = [
        '@keyframes particleFly{',
        '0%{transform:translate(var(--tx0),var(--ty0)) scale(1);opacity:1}',
        '100%{transform:translate(var(--tx1),var(--ty1)) scale(0);opacity:0}',
        '}',
        '.tear-particle-anim{animation:particleFly var(--dur) cubic-bezier(.17,.67,.4,1) forwards}',
    ].join('');
    document.head.appendChild(s);
})();

function tearTicket() {
    if (scratchDone) return;
    scratchDone = true;

    const btn = document.getElementById('btn-tear');
    if (btn) { btn.disabled = true; }

    debugLog('Los wird aufgerissen: ' + currentItem, 'info');

    /* Server-Event SOFORT senden – maximale Zeit für den Server */
    sendScratchEvent(0);

    const card = document.getElementById('ticket-card');
    const wrap = document.getElementById('ticket-wrap');

    /* Phase 1 – Schütteln */
    card.classList.add('ticket-shaking');

    setTimeout(() => {
        card.classList.remove('ticket-shaking');

        /* Phase 2 – Bildschirm-Flash */
        const flash = document.createElement('div');
        flash.id = 'tear-flash';
        document.getElementById('app').appendChild(flash);
        setTimeout(() => { if (flash.parentNode) flash.remove(); }, 450);

        /* Phase 3 – Ticket in zwei Hälften spalten */
        const rect     = card.getBoundingClientRect();
        const wrapRect = wrap.getBoundingClientRect();
        const offsetTop = rect.top - wrapRect.top;
        const halfH    = Math.round(rect.height / 2);
        const w        = rect.width;

        function makePiece(clipTop) {
            const div = document.createElement('div');
            div.className = 'tear-piece';
            const top = clipTop ? offsetTop : offsetTop + halfH;
            div.style.cssText = [
                'position:absolute',
                'left:0',
                'top:' + top + 'px',
                'width:' + w + 'px',
                'height:' + halfH + 'px',
                'overflow:hidden',
                'z-index:50',
                'pointer-events:none',
                'border-radius:' + (clipTop ? '22px 22px 0 0' : '0 0 22px 22px'),
            ].join(';');
            const clone = card.cloneNode(true);
            clone.removeAttribute('id');
            clone.style.cssText = [
                'position:absolute',
                'top:' + (clipTop ? '0' : '-' + halfH + 'px'),
                'left:0',
                'width:' + w + 'px',
                'margin:0',
                'animation:none',
            ].join(';');
            div.appendChild(clone);
            return div;
        }

        const topDiv = makePiece(true);
        const botDiv = makePiece(false);

        card.style.visibility = 'hidden';
        wrap.style.position   = 'relative';
        wrap.appendChild(topDiv);
        wrap.appendChild(botDiv);

        /* Partikel */
        spawnTearParticles(wrap, offsetTop + halfH, w);

        /* Hälften animieren – CSS transition, kein element.animate() */
        requestAnimationFrame(() => {
            topDiv.style.transition = 'transform .85s cubic-bezier(.55,.06,.68,.19), opacity .85s ease';
            topDiv.style.transform  = 'translateY(-230px) translateX(-28px) rotate(-15deg) scale(.88)';
            topDiv.style.opacity    = '0';

            botDiv.style.transition = 'transform .85s cubic-bezier(.55,.06,.68,.19), opacity .85s ease';
            botDiv.style.transform  = 'translateY(230px) translateX(28px) rotate(12deg) scale(.88)';
            botDiv.style.opacity    = '0';
        });

    }, 440);
}

function spawnTearParticles(parent, tearY, ticketW) {
    const colors = ['#f5d060','#ffe566','#c9a84c','#ffffff','#ff6b35','#ff4040','#aa00ff','#00c8ff'];
    for (let i = 0; i < 25; i++) {
        const p     = document.createElement('div');
        const angle  = Math.random() * Math.PI * 2;
        const speed  = 80 + Math.random() * 180;
        const size   = 4 + Math.random() * 7;
        const color  = colors[Math.floor(Math.random() * colors.length)];
        const startX = ticketW * 0.2 + Math.random() * ticketW * 0.6;
        const dur    = Math.round(500 + Math.random() * 600);
        const tx1    = Math.round(Math.cos(angle) * speed);
        const ty1    = Math.round(Math.sin(angle) * speed - 30);

        p.style.cssText = [
            'position:absolute',
            'left:'   + startX + 'px',
            'top:'    + tearY  + 'px',
            'width:'  + size   + 'px',
            'height:' + size   + 'px',
            'border-radius:' + (Math.random() > 0.45 ? '50%' : '3px'),
            'background:'    + color,
            'box-shadow:0 0 ' + (size * 2) + 'px ' + color,
            'pointer-events:none',
            'z-index:60',
            '--tx0:0px', '--ty0:0px',
            '--tx1:' + tx1 + 'px',
            '--ty1:' + ty1 + 'px',
            '--dur:' + dur + 'ms',
        ].join(';');
        p.className = 'tear-particle-anim';

        parent.appendChild(p);

        /* cleanup via transitionend-equivalent: just timeout */
        setTimeout(() => { if (p.parentNode) p.remove(); }, dur + 50);
    }
}

function sendScratchEvent(retries) {
    const attempt = retries || 0;

    /* Fallback: Kamera-Freeze verhindern wenn Server kein Result schickt.
       Lua Phase-1-Timer feuert bei 12 s – NUI timeout bei 11 s sorgt dafür
       dass closeUI (fetch) zuerst ausgelöst wird und Lua sauber abbrechen kann. */
    if (attempt === 0) {
        debugLog('scratchTicket gesendet (Item: ' + currentItem + ')', 'info');
        resultTimeout = setTimeout(() => {
            if (!resultReceived) {
                debugLog('TIMEOUT: Kein Result vom Server – closeUI wird aufgerufen', 'error');
                closeUI();
            }
        }, 11000);
    }

    fetch(`https://${window.location.hostname}/scratchTicket`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ itemName: currentItem }),
    }).then(() => {
        debugLog('scratchTicket Fetch OK', 'ok');
    }).catch(() => {
        debugLog('scratchTicket Fetch FEHLER (Versuch ' + (attempt + 1) + ')', 'error');
        if (attempt < 3) {
            setTimeout(() => sendScratchEvent(attempt + 1), 500);
        }
    });
}

/* ============================================================
   ERGEBNIS ANZEIGEN
   ============================================================ */
function showResult(data) {
    resultReceived = true;
    if (resultTimeout) { clearTimeout(resultTimeout); resultTimeout = null; }
    hideAll();
    document.body.style.pointerEvents = 'auto';

    debugLog('Result empfangen: win=' + data.win + ' label=' + data.label, 'ok');

    if (data.win) {
        showWin(data);
    } else {
        showLose(data);
    }
}

/* ── GEWINN ── */
function showWin(data) {
    showScreen('screen-win');

    const img      = document.getElementById('prize-img');
    const fallback = document.getElementById('prize-icon-fallback');

    if (data.image && data.image !== '') {
        img.src              = `images/${data.image}`;
        img.style.display    = 'block';
        fallback.style.display = 'none';
        img.onerror = () => {
            img.style.display      = 'none';
            fallback.style.display = 'block';
        };
    } else {
        img.style.display      = 'none';
        fallback.style.display = 'block';
    }

    document.getElementById('win-prize-label').textContent = data.label || '';

    spawnCoinRain();
}

/* ── NIETE ── */
function showLose(data) {
    showScreen('screen-lose');
    document.getElementById('lose-subtext').textContent =
        data.label || 'Vielleicht klappt es beim nächsten Mal!';
}

/* ── Münzen-Regen ── */
const COIN_EMOJIS = ['🪙','💰','💎','⭐','🌟','✨'];

function spawnCoinRain() {
    const root = document.getElementById('coin-rain');
    if (!root) return;
    root.innerHTML = '';
    for (let i = 0; i < 60; i++) {
        const c = document.createElement('div');
        c.className   = 'coin';
        c.textContent = COIN_EMOJIS[Math.floor(Math.random() * COIN_EMOJIS.length)];
        c.style.left              = `${Math.random() * 100}vw`;
        c.style.fontSize          = `${16 + Math.random() * 18}px`;
        c.style.animationDuration = `${1.4 + Math.random() * 2.2}s`;
        c.style.animationDelay    = `${Math.random() * 1.6}s`;
        root.appendChild(c);
    }
}

/* ============================================================
   BUTTONS
   ============================================================ */
function collectPrize() { closeUI(); }

function closeUI() {
    hideAll();
    resetUI();
    sendCloseCallback(0);
}

function sendCloseCallback(attempt) {
    fetch(`https://${window.location.hostname}/closeUI`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({}),
    }).catch(() => {
        if (attempt < 5) {
            setTimeout(() => sendCloseCallback(attempt + 1), 300);
        }
    });
}

function resetUI() {
    scratchDone       = false;
    currentItem       = null;
    resultReceived    = false;
    if (resultTimeout) { clearTimeout(resultTimeout); resultTimeout = null; }

    /* Aufgerissene Teile + Flash entfernen */
    document.querySelectorAll('.tear-piece').forEach(el => el.remove());
    const tearFlash = document.getElementById('tear-flash');
    if (tearFlash) tearFlash.remove();
    const card = document.getElementById('ticket-card');
    if (card) { card.style.visibility = ''; card.classList.remove('ticket-shaking'); }

    const coinRain = document.getElementById('coin-rain');
    if (coinRain) coinRain.innerHTML = '';

    const prizeImg = document.getElementById('prize-img');
    if (prizeImg)  prizeImg.src = '';

    const particles = document.getElementById('casino-bg-particles');
    if (particles) particles.innerHTML = '';

    document.body.style.display       = 'none';
    document.body.style.pointerEvents = 'none';

    updateDebugPanel();
    debugLog('UI zurückgesetzt', 'info');
}

