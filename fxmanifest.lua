fx_version 'cerulean'
game 'gta5'

author 'MTJ2025'
description 'MTJ Los - Item-basiertes Lotterie Script fuer ESX Legacy'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@es_extended/imports.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/main.js',
    'html/images/*.png',
    'html/images/*.jpg',
    'html/images/*.gif',
    'html/images/*.webp'
}

lua54 'yes'
