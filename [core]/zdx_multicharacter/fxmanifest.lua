fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'zdx-multicharacter'
author 'ZiDFPS'
version '1.0.0'
description 'Premium Cinematic Multicharacter & Spawn Selector'

shared_scripts {
    'config/config.lua',
    'config/rooms.lua',
    'config/spawns.lua',
    'config/cameras.lua'
}

client_scripts {
    'client/utils.lua',
    'client/camera.lua',
    'client/appearance.lua',
    'client/spawns.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/callbacks.lua',
    'server/database.lua',
    'server/slots.lua',
    'server/screenshots.lua',
    'server/characters.lua'
}

ui_page 'ui/dist/index.html'

files {
    'ui/dist/**/*'
}

dependencies {
    'oxmysql',
    'illenium-appearance'
}

optional_dependencies {
    'screenshot-basic'
}

escrow_ignore {
    'config/*.lua',
    'bridge/*.lua'
}