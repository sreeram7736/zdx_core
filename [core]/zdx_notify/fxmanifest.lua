fx_version 'cerulean'
game 'gta5'

name 'zdx_notify'
description 'ZDX Cinematic Framework - Notification system'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'config.lua',
}

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
