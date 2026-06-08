fx_version 'cerulean'
game 'gta5'

name 'zdx_inventory'
description 'ZDX Cinematic Framework - RPG Inventory bridge for ox_inventory'
version '1.0.0'
lua54 'yes'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_inventory'
}
