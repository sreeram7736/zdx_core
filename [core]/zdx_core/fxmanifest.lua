fx_version 'cerulean'
game 'gta5'

name 'zdx_core'
description 'ZDX Framework — Complete custom cinematic core with ESX/QB bridge compatibility.'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/player.lua',
    'server/api.lua',
    'server/callbacks.lua',
    'server/main.lua',
    'server/commands.lua',
    'bridge/esx/server.lua',
    'bridge/qb/server.lua',
}

client_scripts {
    'client/api.lua',
    'client/callbacks.lua',
    'client/main.lua',
    'client/npc.lua',
    'client/cinematic.lua',
    'bridge/esx/client.lua',
    'bridge/qb/client.lua',
}

dependencies {
    '/onesync',
    'oxmysql',
}
