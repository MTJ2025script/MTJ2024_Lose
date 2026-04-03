'use strict';

/* ============================================================
   STATE
   ============================================================ */
let currentItem        = null;
let scratchDone        = false;
let isScratching       = false;
let canvas, ctx;
let lastProgressCheck  = 0;
const SCRATCH_THRESHOLD      = 0.55;  // 55% freigerubbelt => automatisch auflösen
const PROGRESS_CHECK_INTERVAL = 150; // ms zwischen Canvas-Analysen

// Gespeicherte Canvas-Event-Handler (verhindert Listener-Stapelunge)
let scratchHandlers = null;

/* ============================================================
   FiveM NUI MESSAGE EMPFANGEN
   ============================================================ */
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {
        case 'openTicket':
            openTicket(data);
            break;
        case 'showResult':
            showResult(data);
            break;
    }
});

/* ============================================================
   TICKET ÖFFNEN
   ============================================================ */
function openTicket(data) {
    currentItem  = data.itemName;
    scratchDone  = false;

    // Body sichtbar machen (war per CSS versteckt)
    document.body.style.display = 'block';
    document.body.style.pointerEvents = 'auto';

    // Ticket-Hintergrund setzen
    const bg = document.getElementById('ticket-bg');
    if (data.ticketBg && data.ticketBg !== '') {
        bg.style.backgroundImage = `url('images/${data.ticketBg}')`;
    } else {
        bg.style.backgroundImage = 'linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)';
    }

    // Titel setzen
    document.getElementById('ticket-title').textContent = data.label || 'Los';

    // Views umschalten
    document.getElementById('result-view').classList.add('hidden');
    document.getElementById('ticket-view').classList.remove('hidden');
    document.getElementById('mtj-wrapper').classList.remove('hidden');

    // Canvas initialisieren
    initScratchCanvas();
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
    // Alte Listener entfernen, bevor neue hinzugefuegt werden
    removeScratchListeners();

    const scratchArea = document.getElementById('scratch-area');
    canvas = document.getElementById('scratch-canvas');
    ctx    = canvas.getContext('2d');

    const w = scratchArea.offsetWidth  || 300;
    const h = scratchArea.offsetHeight || 90;
    canvas.width  = w;
    canvas.height = h;

    // Silber-Rubbelschicht zeichnen
    const grad = ctx.createLinearGradient(0, 0, w, h);
    grad.addColorStop(0,   '#c0c0c0');
    grad.addColorStop(0.5, '#e8e8e8');
    grad.addColorStop(1,   '#a8a8a8');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);

    // "Rubbel mich"-Text
    ctx.fillStyle = '#888';
    ctx.font = 'bold 16px Segoe UI, Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('✨ Hier rubbeln! ✨', w / 2, h / 2);

    // Handler-Referenzen speichern (fuer sauberes Entfernen)
    scratchHandlers = {
        mousedown:  startScratch,
        mousemove:  doScratch,
        mouseup:    stopScratch,
        mouseleave: stopScratch,
        touchstart: (e) => { e.preventDefault(); startScratch(e.touches[0]); },
        touchmove:  (e) => { e.preventDefault(); doScratch(e.touches[0]);  },
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
    ctx.arc(pos.x, pos.y, 28, 0, Math.PI * 2);
    ctx.fill();
}

function checkScratchProgress() {
    const data    = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
    let cleared   = 0;
    const total   = canvas.width * canvas.height;
    for (let i = 3; i < data.length; i += 4) {
        if (data[i] === 0) cleared++;
    }
    if (cleared / total >= SCRATCH_THRESHOLD) {
        scratchDone = true;
        // Restliche Schicht ausblenden
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        // Server informieren
        sendScratchEvent();
    }
}

function sendScratchEvent() {
    fetch('https://mtj_los/scratchTicket', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemName: currentItem }),
    });
}

/* ============================================================
   ERGEBNIS ANZEIGEN
   ============================================================ */
function showResult(data) {
    document.getElementById('ticket-view').classList.add('hidden');
    document.getElementById('result-view').classList.remove('hidden');

    if (data.win) {
        showWin(data);
    } else {
        showLose(data);
    }
}

/* ---- GEWINN ---- */
function showWin(data) {
    document.getElementById('lose-screen').classList.add('hidden');
    const winScreen = document.getElementById('win-screen');
    winScreen.classList.remove('hidden');

    // Preis-Bild setzen
    const img   = document.getElementById('prize-image');
    const emoji = document.getElementById('prize-emoji');
    if (data.image && data.image !== '') {
        img.src = `images/${data.image}`;
        img.style.display  = 'block';
        emoji.style.display = 'none';
        img.onerror = () => {
            img.style.display  = 'none';
            emoji.style.display = 'block';
        };
    } else {
        img.style.display  = 'none';
        emoji.style.display = 'block';
    }

    // Gewinn-Bezeichnung
    document.getElementById('win-prize-label').textContent = data.label || '';

    // Animationssequenz starten
    setTimeout(() => openGiftBox(), 200);
    setTimeout(() => {
        document.getElementById('prize-reveal').classList.add('visible');
        spawnConfetti();
    }, 800);
    setTimeout(() => {
        document.getElementById('win-text').classList.add('visible');
    }, 1100);
    setTimeout(() => {
        document.getElementById('btn-collect').classList.add('visible');
    }, 1500);
}

function openGiftBox() {
    document.getElementById('gift-box').classList.add('open');
}

/* ---- KONFETTI ---- */
const CONFETTI_COLORS = [
    '#ffd60a','#ff6b6b','#4ecdc4','#45b7d1',
    '#96ceb4','#ff9ff3','#54a0ff','#5f27cd',
];

function spawnConfetti() {
    const container = document.getElementById('confetti-container');
    container.innerHTML = '';
    for (let i = 0; i < 80; i++) {
        const piece = document.createElement('div');
        piece.className = 'confetti-piece';
        piece.style.left            = `${Math.random() * 100}vw`;
        piece.style.width           = `${6 + Math.random() * 10}px`;
        piece.style.height          = `${10 + Math.random() * 14}px`;
        piece.style.background      = CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)];
        piece.style.borderRadius    = Math.random() > 0.5 ? '50%' : '2px';
        piece.style.animationDuration  = `${1.5 + Math.random() * 2.5}s`;
        piece.style.animationDelay     = `${Math.random() * 1.2}s`;
        container.appendChild(piece);
    }
}

/* ---- NIETE ---- */
function showLose(data) {
    document.getElementById('win-screen').classList.add('hidden');
    const loseScreen = document.getElementById('lose-screen');
    loseScreen.classList.remove('hidden');
    document.getElementById('lose-subtext').textContent = data.label || 'Vielleicht klappt es beim nächsten Mal!';
}

/* ============================================================
   BUTTONS
   ============================================================ */
function collectPrize() {
    closeUI();
}

function closeUI() {
    document.getElementById('mtj-wrapper').classList.add('hidden');
    // Reset für nächste Nutzung
    resetUI();
    fetch('https://mtj_los/closeUI', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    });
}

function resetUI() {
    scratchDone        = false;
    isScratching       = false;
    lastProgressCheck  = 0;
    currentItem        = null;

    // Canvas-Listener entfernen
    removeScratchListeners();

    document.getElementById('gift-box').classList.remove('open');
    document.getElementById('prize-reveal').classList.remove('visible');
    document.getElementById('win-text').classList.remove('visible');
    document.getElementById('btn-collect').classList.remove('visible');
    document.getElementById('confetti-container').innerHTML = '';
    document.getElementById('win-screen').classList.add('hidden');
    document.getElementById('lose-screen').classList.add('hidden');
    document.getElementById('result-view').classList.add('hidden');
    document.getElementById('ticket-view').classList.add('hidden');
    document.getElementById('prize-image').src = '';

    if (canvas && ctx) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
    }

    // Body wieder verstecken – verhindert jedes sichtbare Rendering im Spiel
    document.body.style.display = 'none';
    document.body.style.pointerEvents = 'none';
}
