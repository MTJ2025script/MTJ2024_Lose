--[[
  MTJ2024 Rubbellose – Deutsche Sprachdatei
  © Copyright 2024 MTJ2024
]]

Locale = {}

Locale['de'] = {
    -- Allgemein
    kein_geld               = 'Du hast nicht genug Geld! Benoetigt: %s',
    tageslimit              = 'Du hast dein Tageslimit von %d Losen erreicht!',
    cooldown                = 'Du musst noch %d Sekunden warten, bevor du wieder ein Los kaufen kannst.',
    fehler_server           = 'Es ist ein Fehler aufgetreten. Bitte versuche es erneut.',
    ui_oeffnen              = '[E] MTJ Rubbellose oeffnen',

    -- Kauf
    kauf_erfolg             = 'Du hast ein %s fuer %s gekauft!',
    kauf_animation          = 'Du kaufst ein Rubbellos...',
    kratzen_animation       = 'Du rubbelst das Los auf...',

    -- Gewinn
    gewinn_geld             = '🎉 Glueckwunsch! Du hast %s gewonnen!',
    gewinn_item             = '🎉 Glueckwunsch! Du hast %dx %s gewonnen!',
    gewinn_jackpot          = '🏆 JACKPOT! Du hast den Jackpot von %s gewonnen!!!',
    niete                   = '😢 Leider nichts gewonnen. Versuche es nochmal!',

    -- Serverweite Ansagen
    server_gewinn           = '🎰 %s hat bei den MTJ Rubbellose %s gewonnen!',
    server_jackpot          = '🏆🏆🏆 JACKPOT! %s hat den Mega-Jackpot von %s GEWONNEN! 🏆🏆🏆',

    -- Fehler
    item_nicht_gefunden     = 'Du hast kein %s in deinem Inventar!',
    spieler_nicht_gefunden  = 'Spieler nicht gefunden!',

    -- Admin
    jackpot_gesetzt         = 'Jackpot wurde auf %s gesetzt.',
    debug_an                = 'Debug-Modus aktiviert.',
    debug_aus               = 'Debug-Modus deaktiviert.',
    keine_berechtigung      = 'Du hast keine Berechtigung fuer diesen Befehl!',
}

-- Hilfsfunktion: Uebersetzung abrufen
function T(key, ...)
    local lang = Config.Sprache or 'de'
    local str  = (Locale[lang] and Locale[lang][key]) or (Locale['de'] and Locale['de'][key]) or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
