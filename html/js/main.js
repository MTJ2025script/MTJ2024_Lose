'use strict';

/* ============================================================
   STATE
   ============================================================ */
let currentItem       = null;
let scratchDone       = false;
let isScratching      = false;
let canvas, ctx;
let lastProgressCheck = 0;
const SCRATCH_THRESHOLD      = 0.48;
const PROGRESS_CHECK_INTERVAL = 100;
let scratchHandlers   = null;
let ageConfirmed      = false;
let resultReceived    = false;
let resultTimeout     = null;

/* ── pending ticket data (wartet auf Age-Gate) ── */
let pendingTicket     = null;

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

    if (data.action === 'openTicket')  handleOpenTicket(data);
    if (data.action === 'showResult')  showResult(data);
    if (data.action === 'admin:open')  openAdmin(data);
});

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

    /* Hintergrund */
    const bg = document.getElementById('ticket-bg-img');
    if (data.ticketBg && data.ticketBg !== '') {
        bg.style.backgroundImage = `url('images/${data.ticketBg}')`;
    } else {
        bg.style.backgroundImage = '';
    }

    /* Label */
    document.getElementById('ticket-name-label').textContent = data.label || 'LOS';

    /* Partikel */
    spawnBgSuits();

    showScreen('screen-ticket');

    requestAnimationFrame(() => initScratchCanvas());
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
   RUBBELFELD (Canvas)
   ============================================================ */
function removeScratchListeners() {
    if (!canvas || !scratchHandlers) return;
    canvas.removeEventListener('mousedown',  scratchHandlers.mousedown);
    canvas.removeEventListener('mousemove',  scratchHandlers.mousemove);
    canvas.removeEventListener('mouseup',    scratchHandlers.mouseup);
    canvas.removeEventListener('mouseleave', scratchHandlers.mouseleave);
    canvas.removeEventListener('touchstart', scratchHandlers.touchstart);
    canvas.removeEventListener('touchmove',  scratchHandlers.touchmove);
    canvas.removeEventListener('touchend',   scratchHandlers.touchend);
    scratchHandlers = null;
}

function initScratchCanvas() {
    removeScratchListeners();

    const zone = document.getElementById('scratch-zone');
    canvas = document.getElementById('scratch-canvas');
    ctx    = canvas.getContext('2d');

    const w = zone.offsetWidth  || 400;
    const h = zone.offsetHeight || 110;
    canvas.width  = w;
    canvas.height = h;

    /* Silber-Metallic Schicht */
    const grad = ctx.createLinearGradient(0, 0, w, h);
    grad.addColorStop(0,   '#9a9a9a');
    grad.addColorStop(0.2, '#d0d0d0');
    grad.addColorStop(0.35,'#f2f2f2');
    grad.addColorStop(0.5, '#e8e8e8');
    grad.addColorStop(0.65,'#d5d5d5');
    grad.addColorStop(0.8, '#c0c0c0');
    grad.addColorStop(1,   '#989898');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);

    /* Feine Textur-Linien */
    ctx.strokeStyle = 'rgba(255,255,255,0.15)';
    ctx.lineWidth   = 0.5;
    for (let x = 0; x < w; x += 3) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x + h * 0.3, h);
        ctx.stroke();
    }

    /* Kartenzeichen-Muster */
    ctx.fillStyle = 'rgba(80,80,80,0.06)';
    ctx.font      = '11px serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const suits = ['♠','♥','♦','♣'];
    let si = 0;
    for (let cx = 30; cx < w - 20; cx += 40) {
        for (let cy = 18; cy < h - 10; cy += 30) {
            ctx.fillText(suits[si % 4], cx, cy);
            si++;
        }
    }

    /* Rubbeltext */
    ctx.fillStyle = 'rgba(50,50,50,0.5)';
    ctx.font      = 'bold 13px Segoe UI, Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('✨ HIER RUBBELN – JETZT GLÜCK HERAUSRUBBELN! ✨', w / 2, h / 2);

    /* Event-Handler */
    scratchHandlers = {
        mousedown:  startScratch,
        mousemove:  doScratch,
        mouseup:    stopScratch,
        mouseleave: stopScratch,
        touchstart: (e) => { e.preventDefault(); startScratch(getTouchPos(e)); },
        touchmove:  (e) => { e.preventDefault(); doScratch(getTouchPos(e));    },
        touchend:   stopScratch,
    };

    canvas.addEventListener('mousedown',  scratchHandlers.mousedown);
    canvas.addEventListener('mousemove',  scratchHandlers.mousemove);
    canvas.addEventListener('mouseup',    scratchHandlers.mouseup);
    canvas.addEventListener('mouseleave', scratchHandlers.mouseleave);
    canvas.addEventListener('touchstart', scratchHandlers.touchstart, { passive: false });
    canvas.addEventListener('touchmove',  scratchHandlers.touchmove,  { passive: false });
    canvas.addEventListener('touchend',   scratchHandlers.touchend);
}

function getCanvasPos(e) {
    const rect = canvas.getBoundingClientRect();
    return {
        x: (e.clientX - rect.left)  * (canvas.width  / rect.width),
        y: (e.clientY - rect.top)   * (canvas.height / rect.height),
    };
}

function getTouchPos(e) {
    return e.touches ? e.touches[0] : e;
}

function startScratch(e) {
    if (scratchDone) return;
    isScratching = true;
    erase(getCanvasPos(e));
}

function doScratch(e) {
    if (!isScratching || scratchDone) return;
    erase(getCanvasPos(e));
    const now = Date.now();
    if (now - lastProgressCheck >= PROGRESS_CHECK_INTERVAL) {
        lastProgressCheck = now;
        checkScratchProgress();
    }
}

function stopScratch() {
    isScratching = false;
    if (!scratchDone) checkScratchProgress();
}

function erase(pos) {
    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath();
    ctx.arc(pos.x, pos.y, 32, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
}

function checkScratchProgress() {
    const imgData = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
    let cleared = 0;
    const total  = canvas.width * canvas.height;
    for (let i = 3; i < imgData.length; i += 4) {
        if (imgData[i] === 0) cleared++;
    }
    if (cleared / total >= SCRATCH_THRESHOLD) {
        scratchDone = true;
        removeScratchListeners();
        canvas.style.transition = 'opacity 0.5s ease';
        canvas.style.opacity    = '0';
        setTimeout(sendScratchEvent, 250);
    }
}

function sendScratchEvent(retries) {
    const attempt = retries || 0;

    /* Fallback: Kamera-Freeze verhindern wenn Server kein Result schickt */
    if (attempt === 0) {
        resultTimeout = setTimeout(() => {
            if (!resultReceived) closeUI();
        }, 10000);
    }

    fetch(`https://${window.location.hostname}/scratchTicket`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ itemName: currentItem }),
    }).catch(() => {
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
    fetch(`https://${window.location.hostname}/closeUI`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({}),
    });
}

function resetUI() {
    scratchDone       = false;
    isScratching      = false;
    lastProgressCheck = 0;
    currentItem       = null;
    resultReceived    = false;
    if (resultTimeout) { clearTimeout(resultTimeout); resultTimeout = null; }

    removeScratchListeners();

    const coinRain = document.getElementById('coin-rain');
    if (coinRain) coinRain.innerHTML = '';

    const prizeImg = document.getElementById('prize-img');
    if (prizeImg)  prizeImg.src = '';

    if (canvas && ctx) {
        canvas.style.transition = '';
        canvas.style.opacity    = '1';
        ctx.clearRect(0, 0, canvas.width, canvas.height);
    }

    const particles = document.getElementById('casino-bg-particles');
    if (particles) particles.innerHTML = '';

    document.body.style.display       = 'none';
    document.body.style.pointerEvents = 'none';
}

