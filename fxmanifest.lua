fx_version 'cerulean'
game 'gta5'

author 'MTJ2025'
description 'MTJ Los - Item-basiertes Lotterie Script fuer ESX Legacy'
version '1.1.0'

dependencies {
    'es_extended',
    'oxmysql',
}

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@es_extended/imports.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/css/admin.css',
    'html/js/main.js',
    'html/js/admin.js',
    'html/images/*.png',
    'html/images/*.jpg',
    'html/images/*.gif',
    'html/images/*.webp',
    'html/images/*.svg'
}

lua54 'yes'
