/**
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║   MTJ2024 RUBBELLOSE – NUI Script                                      ║
 * ║   © Copyright 2024 MTJ2024 · Alle Rechte vorbehalten                   ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */

'use strict';

// ─────────────────────────────────────────────────────────────────────────────
//  ZUSTAND
// ─────────────────────────────────────────────────────────────────────────────
const State = {
    lose:           [],
    uiConfig:       {},
    jackpot:        0,
    aktivesLos:     null,       // aktuell ausgewählter Los-Typ
    karteEmpfangen: false,      // ob der Server schon das Ergebnis geschickt hat
    karteAufgedeckt:false,      // ob die Karte vollständig gekratzt wurde
    karteData:      null,       // Ergebnis-Daten vom Server
    tickerItems:    [],
    glitterAnim:    null,
};

// ─────────────────────────────────────────────────────────────────────────────
//  ELEMENTE
// ─────────────────────────────────────────────────────────────────────────────
const El = {
    app:            () => document.getElementById('app'),
    bgOverlay:      () => document.getElementById('bgOverlay'),
    glitter:        () => document.getElementById('glitterCanvas'),
    logoImg:        () => document.getElementById('logoImg'),
    mainTitle:      () => document.getElementById('mainTitle'),
    subTitle:       () => document.getElementById('subTitle'),
    jackpotValue:   () => document.getElementById('jackpotValue'),
    jackpotBox:     () => document.getElementById('jackpotBox'),
    tabNav:         () => document.getElementById('tabNav'),
    losCards:       () => document.getElementById('losCards'),
    shopView:       () => document.getElementById('shopView'),
    scratchView:    () => document.getElementById('scratchView'),
    scratchTitle:   () => document.getElementById('scratchTitle'),
    scratchDesc:    () => document.getElementById('scratchDesc'),
    prizeGrid:      () => document.getElementById('prizeGrid'),
    scratchCanvas:  () => document.getElementById('scratchCanvas'),
    progressBar:    () => document.getElementById('scratchProgressBar'),
    progressText:   () => document.getElementById('scratchProgressText'),
    buyBtn:         () => document.getElementById('buyBtn'),
    buyBtnText:     () => document.getElementById('buyBtnText'),
    buyInfo:        () => document.getElementById('buyInfo'),
    tickerInner:    () => document.getElementById('tickerInner'),
    resultOverlay:  () => document.getElementById('resultOverlay'),
    konfettiCanvas: () => document.getElementById('konfettiCanvas'),
    resultIcon:     () => document.getElementById('resultIcon'),
    resultTitle:    () => document.getElementById('resultTitle'),
    resultText:     () => document.getElementById('resultText'),
    copyright:      () => document.getElementById('copyrightText'),
    backBtn:        () => document.getElementById('backBtn'),
    progressWrap:   () => document.getElementById('scratchProgressWrap'),
};

// ─────────────────────────────────────────────────────────────────────────────
//  HILFSFUNKTIONEN
// ─────────────────────────────────────────────────────────────────────────────
function formatGeld(betrag) {
    return '$' + Math.floor(betrag).toLocaleString('de-DE');
}

function zeigeElement(el, show = true) {
    if (!el) return;
    el.classList.toggle('hidden', !show);
}

function sendeNUI(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

function GetParentResourceName() {
    // FiveM NUI utility
    return window.GetParentResourceName ? window.GetParentResourceName() : 'MTJ2024_Lose';
}

// ─────────────────────────────────────────────────────────────────────────────
//  GLITTER-HINTERGRUND-EFFEKT
// ─────────────────────────────────────────────────────────────────────────────
class GlitterEffect {
    constructor(canvas) {
        this.canvas  = canvas;
        this.ctx     = canvas.getContext('2d');
        this.stars   = [];
        this.running = false;
        this.resize();
        window.addEventListener('resize', () => this.resize());
        this.initStars();
    }

    resize() {
        this.canvas.width  = window.innerWidth;
        this.canvas.height = window.innerHeight;
    }

    initStars() {
        this.stars = [];
        const count = Math.floor((this.canvas.width * this.canvas.height) / 8000);
        for (let i = 0; i < count; i++) {
            this.stars.push(this.newStar());
        }
    }

    newStar(x, y) {
        return {
            x:       x ?? Math.random() * this.canvas.width,
            y:       y ?? Math.random() * this.canvas.height,
            r:       Math.random() * 1.5 + 0.3,
            alpha:   Math.random(),
            delta:   (Math.random() * 0.012 + 0.004) * (Math.random() < 0.5 ? 1 : -1),
            color:   `hsl(${40 + Math.random() * 30}, 100%, ${70 + Math.random() * 20}%)`,
        };
    }

    start() {
        this.running = true;
        this.animate();
    }

    stop() {
        this.running = false;
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }

    animate() {
        if (!this.running) return;
        const ctx = this.ctx;
        ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

        for (const s of this.stars) {
            s.alpha += s.delta;
            if (s.alpha <= 0 || s.alpha >= 1) s.delta = -s.delta;
            s.alpha = Math.max(0, Math.min(1, s.alpha));

            ctx.save();
            ctx.globalAlpha = s.alpha * 0.8;
            ctx.fillStyle   = s.color;
            ctx.shadowColor = s.color;
            ctx.shadowBlur  = 6;
            ctx.beginPath();
            ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        }
        requestAnimationFrame(() => this.animate());
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  KONFETTI-SYSTEM
// ─────────────────────────────────────────────────────────────────────────────
class Konfetti {
    constructor(canvas) {
        this.canvas     = canvas;
        this.ctx        = canvas.getContext('2d');
        this.particles  = [];
        this.running    = false;
        this.colors     = ['#FFD700','#FF6B35','#00FF88','#FF4466','#4FC3F7','#CE93D8','#FFCC02','#FF8A65'];
    }

    start(count = 200) {
        this.canvas.width  = window.innerWidth;
        this.canvas.height = window.innerHeight;
        this.running       = true;
        this.particles     = [];
        const cx = this.canvas.width  / 2;
        const cy = this.canvas.height / 2;
        for (let i = 0; i < count; i++) {
            const angle = Math.random() * Math.PI * 2;
            const speed = Math.random() * 14 + 4;
            this.particles.push({
                x:         cx, y: cy,
                vx:        Math.cos(angle) * speed,
                vy:        Math.sin(angle) * speed - Math.random() * 8,
                r:         Math.random() * 7 + 3,
                h:         Math.random() * 3 + 2,
                color:     this.colors[Math.floor(Math.random() * this.colors.length)],
                alpha:     1,
                rotation:  Math.random() * 360,
                rotSpeed:  (Math.random() - 0.5) * 8,
                gravity:   0.35,
            });
        }
        this.animate();
    }

    animate() {
        if (!this.running) return;
        const ctx = this.ctx;
        ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

        this.particles = this.particles.filter(p => p.alpha > 0.02);
        for (const p of this.particles) {
            p.x        += p.vx;
            p.y        += p.vy;
            p.vy       += p.gravity;
            p.vx       *= 0.99;
            p.alpha    -= 0.012;
            p.rotation += p.rotSpeed;

            ctx.save();
            ctx.globalAlpha = Math.max(0, p.alpha);
            ctx.translate(p.x, p.y);
            ctx.rotate(p.rotation * Math.PI / 180);
            ctx.fillStyle = p.color;
            ctx.fillRect(-p.r / 2, -p.h / 2, p.r, p.h);
            ctx.restore();
        }

        if (this.particles.length > 0) {
            requestAnimationFrame(() => this.animate());
        } else {
            this.running = false;
            ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }
    }

    stop() {
        this.running   = false;
        this.particles = [];
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCRATCH-CARD
// ─────────────────────────────────────────────────────────────────────────────
class ScratchCard {
    constructor(canvas, onComplete) {
        this.canvas      = canvas;
        this.ctx         = canvas.getContext('2d');
        this.onComplete  = onComplete;
        this.scratching  = false;
        this.revealed    = false;
        this.pinsel      = 34;
        this.schwelle    = 55; // % bis auto-reveal

        this._onMouseDown  = e => { this.scratching = true;  this._kratz(e); };
        this._onMouseMove  = e => { if (this.scratching) this._kratz(e); };
        this._onMouseUp    = () => { this.scratching = false; };
        this._onLeave      = () => { this.scratching = false; };
        this._onTouchStart = e => { e.preventDefault(); this.scratching = true;  this._kratz(e.touches[0]); };
        this._onTouchMove  = e => { e.preventDefault(); if (this.scratching) this._kratz(e.touches[0]); };
        this._onTouchEnd   = () => { this.scratching = false; };
    }

    init(pinsel, schwelle) {
        this.pinsel   = pinsel   || this.pinsel;
        this.schwelle = schwelle || this.schwelle;
        this.revealed = false;
        this.scratching = false;

        const { width, height } = this.canvas;
        const ctx = this.ctx;
        ctx.clearRect(0, 0, width, height);

        // Kratz-Oberfläche zeichnen
        const grad = ctx.createLinearGradient(0, 0, width, height);
        grad.addColorStop(0,   '#6a6a7a');
        grad.addColorStop(0.4, '#888899');
        grad.addColorStop(0.7, '#777788');
        grad.addColorStop(1,   '#5a5a6a');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, width, height);

        // Textur-Punkte
        for (let i = 0; i < 300; i++) {
            ctx.beginPath();
            ctx.arc(Math.random() * width, Math.random() * height, Math.random() * 1.2, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(255,255,255,${Math.random() * 0.08})`;
            ctx.fill();
        }

        // Text auf Scratch-Fläche
        ctx.fillStyle    = 'rgba(255,255,255,0.65)';
        ctx.font         = `bold ${Math.floor(height * 0.18)}px Segoe UI, Arial`;
        ctx.textAlign    = 'center';
        ctx.textBaseline = 'middle';
        ctx.shadowColor  = 'rgba(0,0,0,0.5)';
        ctx.shadowBlur   = 8;
        ctx.fillText('✨ HIER RUBBELN! ✨', width / 2, height / 2 - height * 0.1);
        ctx.font         = `${Math.floor(height * 0.12)}px Segoe UI, Arial`;
        ctx.fillStyle    = 'rgba(255,255,255,0.45)';
        ctx.fillText('Maus gedrückt halten & kratzen', width / 2, height / 2 + height * 0.1);
        ctx.shadowBlur   = 0;

        this._bindEvents();
    }

    _bindEvents() {
        this._unbindEvents();
        this.canvas.addEventListener('mousedown',  this._onMouseDown);
        this.canvas.addEventListener('mousemove',  this._onMouseMove);
        this.canvas.addEventListener('mouseup',    this._onMouseUp);
        this.canvas.addEventListener('mouseleave', this._onLeave);
        this.canvas.addEventListener('touchstart', this._onTouchStart, { passive: false });
        this.canvas.addEventListener('touchmove',  this._onTouchMove,  { passive: false });
        this.canvas.addEventListener('touchend',   this._onTouchEnd);
    }

    _unbindEvents() {
        this.canvas.removeEventListener('mousedown',  this._onMouseDown);
        this.canvas.removeEventListener('mousemove',  this._onMouseMove);
        this.canvas.removeEventListener('mouseup',    this._onMouseUp);
        this.canvas.removeEventListener('mouseleave', this._onLeave);
        this.canvas.removeEventListener('touchstart', this._onTouchStart);
        this.canvas.removeEventListener('touchmove',  this._onTouchMove);
        this.canvas.removeEventListener('touchend',   this._onTouchEnd);
    }

    _kratz(event) {
        if (this.revealed) return;
        const rect = this.canvas.getBoundingClientRect();
        const sx   = this.canvas.width  / rect.width;
        const sy   = this.canvas.height / rect.height;
        const x    = (event.clientX - rect.left) * sx;
        const y    = (event.clientY - rect.top)  * sy;

        const ctx = this.ctx;
        ctx.globalCompositeOperation = 'destination-out';
        ctx.beginPath();
        ctx.arc(x, y, this.pinsel, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalCompositeOperation = 'source-over';

        this._pruefeForschritt();
    }

    _pruefeForschritt() {
        const { width, height } = this.canvas;
        const data      = this.ctx.getImageData(0, 0, width, height).data;
        let transparent = 0;
        for (let i = 3; i < data.length; i += 4) {
            if (data[i] < 128) transparent++;
        }
        const pct = (transparent / (width * height)) * 100;
        _aktualisiereProgress(pct);

        if (pct >= this.schwelle && !this.revealed) {
            this._reveal();
        }
    }

    _reveal() {
        this.revealed = true;
        this._unbindEvents();
        // Alpha aller verbleibenden Pixel reduzieren (sanftes Verschwinden)
        const fade = () => {
            const { width, height } = this.canvas;
            const img  = this.ctx.getImageData(0, 0, width, height);
            let any    = false;
            for (let i = 3; i < img.data.length; i += 4) {
                if (img.data[i] > 0) {
                    img.data[i] = Math.max(0, img.data[i] - 18);
                    any = true;
                }
            }
            this.ctx.putImageData(img, 0, 0);
            if (any) {
                requestAnimationFrame(fade);
            } else {
                if (this.onComplete) this.onComplete();
            }
        };
        requestAnimationFrame(fade);
    }

    destroy() {
        this._unbindEvents();
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INSTANZEN
// ─────────────────────────────────────────────────────────────────────────────
let glitter     = null;
let konfetti    = null;
let scratchCard = null;

// ─────────────────────────────────────────────────────────────────────────────
//  JACKPOT-COUNTER (animierte Zahl)
// ─────────────────────────────────────────────────────────────────────────────
let jackpotAnimFrame = null;

function animiereJackpot(ziel) {
    if (jackpotAnimFrame) cancelAnimationFrame(jackpotAnimFrame);
    let aktuell = State.jackpot;
    const diff  = ziel - aktuell;
    const dauer = 800; // ms
    const start = performance.now();

    const step = (now) => {
        const t    = Math.min((now - start) / dauer, 1);
        const ease = 1 - Math.pow(1 - t, 3);
        const val  = Math.floor(aktuell + diff * ease);
        El.jackpotValue().textContent = formatGeld(val);
        if (t < 1) {
            jackpotAnimFrame = requestAnimationFrame(step);
        } else {
            State.jackpot = ziel;
            El.jackpotValue().textContent = formatGeld(ziel);
        }
    };
    jackpotAnimFrame = requestAnimationFrame(step);
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORTSCHRITT-BALKEN
// ─────────────────────────────────────────────────────────────────────────────
function _aktualisiereProgress(pct) {
    const clamped = Math.min(100, Math.max(0, pct));
    El.progressBar().style.width      = clamped.toFixed(1) + '%';
    El.progressText().textContent     = Math.floor(clamped) + '% aufgedeckt';
}

// ─────────────────────────────────────────────────────────────────────────────
//  UI AUFBAUEN
// ─────────────────────────────────────────────────────────────────────────────
function baueUI(lose, uiCfg) {
    State.lose     = lose;
    State.uiConfig = uiCfg;

    // Titel / Untertitel
    El.mainTitle().textContent  = uiCfg.Titel     || 'MTJ Rubbellose';
    El.subTitle().textContent   = uiCfg.Untertitel|| 'Dein Glück wartet!';
    El.copyright().textContent  = '© MTJ2024 · Rubbellose System';

    // Hintergrundbild
    const bgEl = El.bgOverlay();
    if (uiCfg.HintergrundAktiviert && uiCfg.Hintergrundbild) {
        bgEl.style.backgroundImage  = `url('${uiCfg.Hintergrundbild}')`;
        bgEl.style.backdropFilter   = `blur(${uiCfg.HintergrundBlur || 0}px)`;
        bgEl.style.backgroundColor  = `rgba(0,0,0,${uiCfg.HintergrundDimmen || 0.55})`;
    } else {
        bgEl.style.backgroundImage  = 'none';
        bgEl.style.backgroundColor  = 'rgba(8,8,20,0.96)';
    }

    // Logo
    const logoEl = El.logoImg();
    if (uiCfg.LogoAktiviert && uiCfg.Logo) {
        logoEl.src    = uiCfg.Logo;
        logoEl.width  = uiCfg.LogoBreite || 160;
        logoEl.height = uiCfg.LogoHoehe  || 60;
        logoEl.style.display = 'block';
    } else {
        logoEl.style.display = 'none';
    }

    // CSS-Variablen
    const root = document.documentElement.style;
    if (uiCfg.PrimaerFarbe)    root.setProperty('--primary',  uiCfg.PrimaerFarbe);
    if (uiCfg.AkzentFarbe)     root.setProperty('--accent',   uiCfg.AkzentFarbe);
    if (uiCfg.GewinnFarbe)     root.setProperty('--win',      uiCfg.GewinnFarbe);
    if (uiCfg.JackpotFarbe)    root.setProperty('--jackpot',  uiCfg.JackpotFarbe);
    if (uiCfg.NiederlagefarBe) root.setProperty('--lose',     uiCfg.NiederlagefarBe);

    // Jackpot-Box
    zeigeElement(El.jackpotBox(), uiCfg.JackpotAnzeigen !== false);

    // Tabs + Karten aufbauen
    bauteTabs(lose);
    baueKarten(lose);
}

function bauteTabs(lose) {
    const nav = El.tabNav();
    nav.innerHTML = '';
    lose.forEach((los, idx) => {
        const btn = document.createElement('button');
        btn.className      = 'tabBtn' + (idx === 0 ? ' aktiv' : '');
        btn.role           = 'tab';
        btn.textContent    = `${los.symbol} ${los.name}`;
        btn.dataset.losIdx = idx;
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tabBtn').forEach(b => b.classList.remove('aktiv'));
            btn.classList.add('aktiv');
            waehleLos(los);
        });
        nav.appendChild(btn);
    });
}

function baueKarten(lose) {
    const container = El.losCards();
    container.innerHTML = '';
    lose.forEach((los, idx) => {
        const card = document.createElement('div');
        card.className = 'losCard';
        card.style.setProperty('--card-color', los.farbe || '#FFD700');

        // Glow-Layer
        const glow = document.createElement('div');
        glow.className = 'losCardGlow';
        glow.style.background = `radial-gradient(circle at 50% 50%, ${(los.farbe || '#FFD700')}22, transparent 70%)`;
        card.appendChild(glow);

        card.innerHTML += `
            <div class="losCardSymbol">${los.symbol || '🎟️'}</div>
            <div class="losCardName">${los.name}</div>
            <div class="losCardDesc">${los.beschreibung || ''}</div>
            <div class="losCardPreis" style="color:${los.farbe || '#FFD700'}">${formatGeld(los.preis)}</div>
            <div class="losCardMaxGewinn">bis zu ${formatGeld(los.maxGewinn)} 🚀</div>
        `;
        card.addEventListener('click', () => waehleLos(los, true));
        container.appendChild(card);
    });
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOS AUSWÄHLEN
// ─────────────────────────────────────────────────────────────────────────────
function waehleLos(los, wechselAnsicht = false) {
    State.aktivesLos = los;

    // Tab aktiv setzen
    document.querySelectorAll('.tabBtn').forEach(b => {
        b.classList.toggle('aktiv', b.dataset.losIdx === String(State.lose.indexOf(los)));
    });

    // Scratch-Ansicht befüllen
    El.scratchTitle().textContent = los.symbol + ' ' + los.name;
    El.scratchDesc().textContent  = los.beschreibung || '';
    El.buyBtnText().textContent   = `Los kaufen – ${formatGeld(los.preis)}`;
    El.buyInfo().textContent      = `Möglicher Maximalgewinn: ${formatGeld(los.maxGewinn)} · Preis: ${formatGeld(los.preis)}`;

    // Canvas vorbereiten (leer = warte auf Kauf)
    resetScratch(false);

    // Panels zurücksetzen
    for (let i = 0; i < 3; i++) {
        const p = document.getElementById(`panel${i}`);
        if (p) {
            p.querySelector('.panelSymbol').textContent = '?';
            p.querySelector('.panelText').textContent   = '???';
            p.classList.remove('gewinn');
            p.style.opacity = '0.4';
        }
    }

    // Fortschritt zurücksetzen
    _aktualisiereProgress(0);
    zeigeElement(El.progressWrap(), false);

    // Kauf-Button aktivieren
    setzeBuyBtn(true, `🎟️ Los kaufen – ${formatGeld(los.preis)}`);
    State.karteEmpfangen  = false;
    State.karteAufgedeckt = false;

    if (wechselAnsicht) zeigeShop(false);
}

// ─────────────────────────────────────────────────────────────────────────────
//  ANSICHTEN WECHSELN
// ─────────────────────────────────────────────────────────────────────────────
function zeigeShop(zurZurück = true) {
    zeigeElement(El.shopView(), true);
    zeigeElement(El.scratchView(), false);
    if (zurZurück && State.lose.length > 0) {
        waehleLos(State.lose[0]);
    }
}

function zeigeScratch() {
    zeigeElement(El.shopView(), false);
    zeigeElement(El.scratchView(), true);
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCRATCH-KARTE RESET
// ─────────────────────────────────────────────────────────────────────────────
function resetScratch(mitCanvas = true) {
    if (scratchCard) {
        scratchCard.destroy();
        scratchCard = null;
    }
    if (mitCanvas) {
        const canvas = El.scratchCanvas();
        if (canvas) {
            const ctx = canvas.getContext('2d');
            ctx.clearRect(0, 0, canvas.width, canvas.height);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  KAUF-BUTTON
// ─────────────────────────────────────────────────────────────────────────────
function setzeBuyBtn(aktiv, text) {
    const btn = El.buyBtn();
    if (!btn) return;
    btn.disabled = !aktiv;
    El.buyBtnText().textContent = text || btn.querySelector('#buyBtnText').textContent;
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOS KAUFEN (aufgerufen per onclick)
// ─────────────────────────────────────────────────────────────────────────────
function kaufeLos() {
    if (!State.aktivesLos) return;
    setzeBuyBtn(false, '⏳ Wird gekauft...');

    // Canvas-Bereich vorbereiten (Ladespinner-Anzeige)
    const canvas = El.scratchCanvas();
    const rect   = El.prizeGrid().getBoundingClientRect();
    canvas.width  = rect.width;
    canvas.height = rect.height;
    const ctx    = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = 'rgba(13,13,26,0.75)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle    = 'rgba(255,215,0,0.8)';
    ctx.font         = 'bold 18px Segoe UI';
    ctx.textAlign    = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('⏳ Server bestätigt...', canvas.width / 2, canvas.height / 2);

    zeigeScratch();
    sendeNUI('kaufe', { losId: State.aktivesLos.id });
}

// ─────────────────────────────────────────────────────────────────────────────
//  KARTE ANZEIGEN (Ergebnis vom Server)
// ─────────────────────────────────────────────────────────────────────────────
function zeigeKarte(daten) {
    State.karteEmpfangen = true;
    State.karteData      = daten;

    // Panel-Symbole einsetzen
    for (let i = 0; i < 3; i++) {
        const p   = document.getElementById(`panel${i}`);
        const pd  = daten.panels && daten.panels[i];
        if (!p || !pd) continue;
        p.querySelector('.panelSymbol').textContent = pd.symbol || '?';
        p.querySelector('.panelText').textContent   = pd.text   || '?';
        p.style.opacity = '1';
        p.classList.toggle('gewinn', !!pd.gewinn);
    }

    // Canvas über den Panels aufspannen
    const canvas  = El.scratchCanvas();
    const grid    = El.prizeGrid();
    const rect    = grid.getBoundingClientRect();
    const panelRect = grid.getBoundingClientRect();
    canvas.width  = panelRect.width;
    canvas.height = panelRect.height;
    canvas.style.width  = '100%';
    canvas.style.height = '100%';

    // Fortschrittsbalken anzeigen
    zeigeElement(El.progressWrap(), State.uiConfig.KratzFortschrittAnzeigen !== false);
    _aktualisiereProgress(0);

    // Scratch-Card initialisieren
    scratchCard = new ScratchCard(canvas, () => {
        // Karte vollständig aufgedeckt
        State.karteAufgedeckt = true;
        zeigeErgebnis(daten);
        sendeNUI('aufgedeckt', { gewonnen: daten.gewonnen, jackpot: daten.jackpot });
    });
    scratchCard.init(
        State.uiConfig.KratzPinselGroesse || 34,
        State.uiConfig.KratzSchwelle      || 55
    );

    setzeBuyBtn(false, '🔍 Karte aufrubbeln...');
}

// ─────────────────────────────────────────────────────────────────────────────
//  ERGEBNIS ANZEIGEN
// ─────────────────────────────────────────────────────────────────────────────
function zeigeErgebnis(daten) {
    const overlay = El.resultOverlay();
    zeigeElement(overlay, true);

    if (daten.jackpot) {
        El.resultIcon().textContent  = '🏆';
        El.resultTitle().textContent = 'JACKPOT!!!';
        El.resultTitle().className   = 'jackpot';
        El.resultText().textContent  = 'Unglaublich! Du hast den Mega-Jackpot gewonnen!';
        if (konfetti) konfetti.start(400);
    } else if (daten.gewonnen) {
        El.resultIcon().textContent  = '🎉';
        El.resultTitle().textContent = 'Gewonnen!';
        El.resultTitle().className   = 'gewinn';
        El.resultText().textContent  = `Glückwunsch! ${daten.gewinnName}`;
        if (konfetti) konfetti.start(200);
    } else {
        El.resultIcon().textContent  = '😢';
        El.resultTitle().textContent = 'Leider nichts!';
        El.resultTitle().className   = 'niete';
        El.resultText().textContent  = 'Kein Glück diesmal – versuche es nochmal!';
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOCHMAL
// ─────────────────────────────────────────────────────────────────────────────
function nochmal() {
    zeigeElement(El.resultOverlay(), false);
    if (konfetti) konfetti.stop();

    // Zurück zur Shop-Ansicht desselben Los-Typs
    if (State.aktivesLos) {
        waehleLos(State.aktivesLos);
        zeigeScratch();
    } else {
        zeigeShop();
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  UI ÖFFNEN / SCHLIESSEN
// ─────────────────────────────────────────────────────────────────────────────
function oeffneUI(data) {
    baueUI(data.lose || [], data.ui || {});
    animiereJackpot(data.jackpot || 0);

    // Glitter starten
    if (data.ui && data.ui.GlitzerAktiviert !== false) {
        if (!glitter) glitter = new GlitterEffect(El.glitter());
        glitter.start();
    }

    // Konfetti-Instanz bereithalten
    konfetti = new Konfetti(El.konfettiCanvas());

    // Ersten Los-Tab auswählen
    if (data.lose && data.lose.length > 0) {
        waehleLos(data.lose[0]);
    }

    zeigeElement(El.app(), true);
}

function schliesseUI() {
    zeigeElement(El.app(), false);
    zeigeElement(El.resultOverlay(), false);
    if (glitter) glitter.stop();
    if (konfetti) konfetti.stop();
    resetScratch();
    sendeNUI('schliesse', {});
}

// ─────────────────────────────────────────────────────────────────────────────
//  GEWINNER-TICKER
// ─────────────────────────────────────────────────────────────────────────────
function gewinnerTicker(daten) {
    if (!State.uiConfig.GewinnerTickerAktiviert) return;
    State.tickerItems.push(daten);
    if (State.tickerItems.length > (State.uiConfig.MaxGewinnerImTicker || 10)) {
        State.tickerItems.shift();
    }
    aktualisiereTicker();
}

function aktualisiereTicker() {
    const inner = El.tickerInner();
    if (!inner) return;
    const items = State.tickerItems;
    if (items.length === 0) {
        inner.innerHTML = '';
        return;
    }
    // Doppeln für nahtlosen Loop
    const html = items.map(it =>
        `<span>🏅 <b>${it.name}</b> hat <b>${it.betrag}</b> bei <i>${it.los}</i> gewonnen!</span>`
    ).join('');
    inner.innerHTML = html + html;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOM NOTIFY SYSTEM
// ─────────────────────────────────────────────────────────────────────────────

const MTJNotify = (() => {
    let container = null;
    let cfg = {
        position:       'top-right',
        dauer:          5000,
        maxAnzahl:      5,
        fortschritt:    true,
        animation:      'slide',
        icons:  { success:'✅', error:'❌', info:'ℹ️', warning:'⚠️', jackpot:'🏆', item:'🎁' },
        titles: { success:'Erfolg', error:'Fehler', info:'Info', warning:'Hinweis', jackpot:'JACKPOT!', item:'Gewinn' },
    };

    // Config aus Lua-Nachricht setzen
    function init(notifyCfg) {
        container = document.getElementById('mtjNotifyContainer');
        if (!container) return;
        if (notifyCfg) {
            cfg.position    = notifyCfg.Position   || cfg.position;
            cfg.dauer       = notifyCfg.Dauer       || cfg.dauer;
            cfg.maxAnzahl   = notifyCfg.MaxAnzahl   || cfg.maxAnzahl;
            cfg.fortschritt = notifyCfg.FortschrittBalken !== false;
            cfg.animation   = (notifyCfg.EinblendAnimation || 'slide').toLowerCase();
            if (notifyCfg.Icons)  Object.assign(cfg.icons,  notifyCfg.Icons);
        }
        container.className = cfg.position;
    }

    // Benachrichtigung anzeigen
    function show(text, typ, dauer) {
        if (!container) { container = document.getElementById('mtjNotifyContainer'); }
        if (!container) return;
        typ   = typ   || 'info';
        dauer = dauer || cfg.dauer;

        // Überzählige entfernen
        const existing = container.querySelectorAll('.mtj-notify');
        if (existing.length >= cfg.maxAnzahl) {
            _dismiss(existing[0], true);
        }

        const icon  = cfg.icons[typ]  || 'ℹ️';
        const title = cfg.titles[typ] || 'Info';

        const el = document.createElement('div');
        el.className = `mtj-notify type-${typ}`;
        if (cfg.animation !== 'slide') el.classList.add(`anim-${cfg.animation}`);

        el.innerHTML = `
            <div class="mtj-notify-icon">${icon}</div>
            <div class="mtj-notify-body">
                <div class="mtj-notify-title">${title}</div>
                <div class="mtj-notify-text">${text}</div>
            </div>
            <button class="mtj-notify-close" title="Schließen">✕</button>
            ${cfg.fortschritt ? '<div class="mtj-notify-progress"></div>' : ''}
        `;

        // Schließen-Button
        el.querySelector('.mtj-notify-close').addEventListener('click', () => _dismiss(el));

        // Klick auf Benachrichtigung schließt sie auch
        el.addEventListener('click', e => {
            if (!e.target.classList.contains('mtj-notify-close')) _dismiss(el);
        });

        container.appendChild(el);

        // Fortschrittsbalken animieren
        if (cfg.fortschritt) {
            const bar = el.querySelector('.mtj-notify-progress');
            if (bar) {
                bar.style.width = '100%';
                bar.style.transition = `width ${dauer}ms linear`;
                requestAnimationFrame(() => requestAnimationFrame(() => { bar.style.width = '0%'; }));
            }
        }

        // Auto-Dismiss
        el._timeout = setTimeout(() => _dismiss(el), dauer);
    }

    function _dismiss(el, sofort = false) {
        if (!el || el._dismissed) return;
        el._dismissed = true;
        clearTimeout(el._timeout);
        if (sofort) { el.remove(); return; }
        el.classList.add('out');
        setTimeout(() => el.remove(), 320);
    }

    return { init, show };
})();

// ─────────────────────────────────────────────────────────────────────────────
//  NUI-MESSAGE-HANDLER (von Client-Lua)
// ─────────────────────────────────────────────────────────────────────────────
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {
        case 'oeffne':
            oeffneUI(data);
            break;

        case 'schliesse':
            schliesseUI();
            break;

        case 'zeigeKarte':
            zeigeKarte(data);
            break;

        case 'jackpotUpdate':
            animiereJackpot(data.betrag || 0);
            break;

        case 'gewinnerTicker':
            gewinnerTicker(data.daten || {});
            break;

        case 'notify':
            MTJNotify.show(data.text, data.typ, data.dauer);
            break;

        case 'notifyInit':
            MTJNotify.init(data.config);
            break;
    }
});

// ─────────────────────────────────────────────────────────────────────────────
//  INIT (Seite geladen)
// ─────────────────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    // App initial versteckt
    zeigeElement(El.app(), false);

    // ESC-Taste
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') schliesseUI();
    });
});
