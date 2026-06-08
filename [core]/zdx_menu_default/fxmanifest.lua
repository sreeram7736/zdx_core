fx_version 'cerulean'
game 'gta5'

name 'zdx_menu_default'
description 'ZDX Cinematic Framework - Default keyboard-navigated menu'
version '1.0.0'
lua54 'yes'

client_scripts {
    'client/main.lua',
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/app.js',
}

dependencies {
    'zdx_core',
}
