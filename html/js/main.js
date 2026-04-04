'use strict';

/* ============================================================
   STATE
   ============================================================ */
let currentItem       = null;
let scratchDone       = false;
let isScratching      = false;
let canvas, ctx;
let lastProgressCheck = 0;
const SCRATCH_THRESHOLD      = 0.50;   // 50 % freigerubbelt → fertig
const PROGRESS_CHECK_INTERVAL = 120;   // ms zwischen Canvas-Analysen
let scratchHandlers = null;

/* ============================================================
   HILFSFUNKTIONEN: Sichtbarkeit
   ============================================================ */
function show(id, display) {
    document.getElementById(id).style.display = display || 'flex';
}
function hide(id) {
    document.getElementById(id).style.display = 'none';
}

/* ============================================================
   FiveM NUI-NACHRICHTEN
   ============================================================ */
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'openTicket') openTicket(data);
    if (data.action === 'showResult') showResult(data);
});

/* ============================================================
   TICKET ÖFFNEN
   ============================================================ */
function openTicket(data) {
    currentItem = data.itemName;
    scratchDone = false;

    // Body sichtbar machen
    document.body.style.display = 'block';
    document.body.style.pointerEvents = 'auto';

    // Ticket-Hintergrund
    const bg = document.getElementById('ticket-bg-img');
    if (data.ticketBg && data.ticketBg !== '') {
        bg.style.backgroundImage = `url('images/${data.ticketBg}')`;
    } else {
        bg.style.backgroundImage = 'linear-gradient(135deg, #0d0d1a 0%, #131328 50%, #0a0a1a 100%)';
    }

    // Titel
    document.getElementById('ticket-name-label').textContent = data.label || 'Los';

    // Screens umschalten
    hide('screen-win');
    hide('screen-lose');
    show('screen-ticket');
    show('app');

    // Canvas nach dem Anzeigen initialisieren
    requestAnimationFrame(() => initScratchCanvas());
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

    const w = zone.offsetWidth  || 360;
    const h = zone.offsetHeight || 100;
    canvas.width  = w;
    canvas.height = h;

    // Silber-Rubbelschicht zeichnen
    const grad = ctx.createLinearGradient(0, 0, w, h);
    grad.addColorStop(0,    '#b8b8b8');
    grad.addColorStop(0.3,  '#e0e0e0');
    grad.addColorStop(0.5,  '#f0f0f0');
    grad.addColorStop(0.7,  '#e0e0e0');
    grad.addColorStop(1,    '#a8a8a8');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);

    // Textur-Muster
    ctx.fillStyle = 'rgba(100,100,100,0.08)';
    for (let x = 0; x < w; x += 4) {
        for (let y = 0; y < h; y += 4) {
            if ((x + y) % 8 === 0) ctx.fillRect(x, y, 2, 2);
        }
    }

    // Rubbelhinweis-Text
    ctx.fillStyle = 'rgba(60,60,60,0.55)';
    ctx.font = 'bold 15px Segoe UI, Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('✨ Hier Rubbeln! ✨', w / 2, h / 2);

    // Event-Handler
    scratchHandlers = {
        mousedown:  startScratch,
        mousemove:  doScratch,
        mouseup:    stopScratch,
        mouseleave: stopScratch,
        touchstart: (e) => { e.preventDefault(); startScratch(getTouchPos(e)); },
        touchmove:  (e) => { e.preventDefault(); doScratch(getTouchPos(e));   },
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
        x: (e.clientX - rect.left) * (canvas.width  / rect.width),
        y: (e.clientY - rect.top)  * (canvas.height / rect.height),
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
}

function erase(pos) {
    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath();
    ctx.arc(pos.x, pos.y, 30, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
}

function checkScratchProgress() {
    const imgData = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
    let cleared = 0;
    const total = canvas.width * canvas.height;
    // Zähle komplett transparente Pixel (Alpha === 0)
    for (let i = 3; i < imgData.length; i += 4) {
        if (imgData[i] === 0) cleared++;
    }
    if (cleared / total >= SCRATCH_THRESHOLD) {
        scratchDone = true;
        removeScratchListeners();
        // Canvas weich ausblenden
        canvas.style.transition = 'opacity 0.4s ease';
        canvas.style.opacity = '0';
        // Server informieren
        setTimeout(sendScratchEvent, 200);
    }
}

function sendScratchEvent(retries) {
    const attempt = retries || 0;
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
    // Ticket-Screen ausblenden
    hide('screen-ticket');

    // Maus sicherstellen
    document.body.style.pointerEvents = 'auto';

    if (data.win) {
        showWin(data);
    } else {
        showLose(data);
    }
}

/* ── GEWINN ── */
function showWin(data) {
    show('screen-win');

    // Preis-Bild oder Fallback-Icon
    const img      = document.getElementById('prize-img');
    const fallback = document.getElementById('prize-icon-fallback');

    if (data.image && data.image !== '') {
        img.src = `images/${data.image}`;
        img.style.display = 'block';
        fallback.style.display = 'none';
        img.onerror = () => {
            img.style.display     = 'none';
            fallback.style.display = 'block';
        };
    } else {
        img.style.display     = 'none';
        fallback.style.display = 'block';
    }

    document.getElementById('win-prize-label').textContent = data.label || '';

    // Konfetti sofort starten
    spawnConfetti();

    // Sammeln-Button direkt sichtbar (kein animiertes Einblenden mehr)
    // → verhindert das Bug mit gestapelten CSS-Delays
    document.getElementById('btn-collect').style.opacity   = '1';
    document.getElementById('btn-collect').style.transform = 'none';
}

/* ── NIETE ── */
function showLose(data) {
    show('screen-lose');
    document.getElementById('lose-subtext').textContent =
        data.label || 'Vielleicht klappt es beim nächsten Mal!';
}

/* ── KONFETTI ── */
const CONFETTI_COLORS = [
    '#ffd60a','#ff6b6b','#4ecdc4','#45b7d1',
    '#96ceb4','#ff9ff3','#54a0ff','#5f27cd',
    '#ff9f43','#00d2d3',
];

function spawnConfetti() {
    const root = document.getElementById('confetti-root');
    root.innerHTML = '';
    for (let i = 0; i < 90; i++) {
        const p = document.createElement('div');
        p.className = 'confetti-piece';
        const size = 6 + Math.random() * 10;
        p.style.left              = `${Math.random() * 100}vw`;
        p.style.width             = `${size}px`;
        p.style.height            = `${size * (1.2 + Math.random())}px`;
        p.style.background        = CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)];
        p.style.borderRadius      = Math.random() > 0.45 ? '50%' : '2px';
        p.style.animationDuration = `${1.6 + Math.random() * 2.6}s`;
        p.style.animationDelay    = `${Math.random() * 1.4}s`;
        root.appendChild(p);
    }
}

/* ============================================================
   BUTTONS
   ============================================================ */
function collectPrize() { closeUI(); }

function closeUI() {
    hide('app');
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

    removeScratchListeners();

    hide('screen-ticket');
    hide('screen-win');
    hide('screen-lose');

    document.getElementById('confetti-root').innerHTML = '';
    document.getElementById('prize-img').src           = '';

    // Canvas zurücksetzen
    if (canvas && ctx) {
        canvas.style.transition = '';
        canvas.style.opacity    = '1';
        ctx.clearRect(0, 0, canvas.width, canvas.height);
    }

    // Body wieder verstecken
    document.body.style.display      = 'none';
    document.body.style.pointerEvents = 'none';
}

