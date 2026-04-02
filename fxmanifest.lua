--[[
╔══════════════════════════════════════════════════════════════════════╗
║   ███╗   ███╗████████╗     ██╗██████╗  ██████╗ ██████╗ ██╗  ██╗   ║
║   ████╗ ████║╚══██╔══╝    ██╔╝╚════██╗██╔═████╗╚════██╗██║  ██║   ║
║   ██╔████╔██║   ██║        ██║  █████╔╝██║██╔██║ █████╔╝███████║   ║
║   ██║╚██╔╝██║   ██║        ██║ ██╔═══╝ ████╔╝██║██╔═══╝ ╚════██║   ║
║   ██║ ╚═╝ ██║   ██║        ██║ ███████╗╚██████╔╝███████╗     ██║   ║
║   ╚═╝     ╚═╝   ╚═╝        ╚═╝ ╚══════╝ ╚═════╝ ╚══════╝     ╚═╝   ║
╠══════════════════════════════════════════════════════════════════════╣
║          R U B B E L L O S E   S Y S T E M   F O R   E S X         ║
║                  © Copyright 2024 MTJ2024                           ║
║           Alle Rechte vorbehalten · All Rights Reserved             ║
╚══════════════════════════════════════════════════════════════════════╝
]]

fx_version   'cerulean'
game         'gta5'

author       'MTJ2024'
description  'MTJ2024 Rubbellose System – Professionelles Scratch-Card Lotterie System fuer FiveM ESX Legacy'
version      '1.0.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'locales/de.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

client_scripts {
    'client/client.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',

    -- ┌─────────────────────────────────────────────────┐
    -- │  Alle Bild-Formate  (in Config frei waehlbar)   │
    -- └─────────────────────────────────────────────────┘
    'html/img/*.jpg',
    'html/img/*.jpeg',
    'html/img/*.png',
    'html/img/*.gif',
    'html/img/*.webp',
    'html/img/*.svg',
    'html/img/*.ico',
    'html/img/*.bmp',
    'html/img/*.tiff',
}
