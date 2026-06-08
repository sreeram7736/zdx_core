fx_version 'cerulean'
game 'gta5'

name 'zdx_core'
description 'A lightweight cinematic core with RPG database and universal ESX/QB/QBox compatibility.'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/player.lua',
    'server/main.lua',
    'server/commands.lua',
    'bridge/esx/server.lua',
    'bridge/qb/server.lua',
}

client_scripts {
    'client/main.lua',
    'bridge/esx/client.lua',
    'bridge/qb/client.lua',
}

dependencies {
    '/onesync',
    'oxmysql',
}

provide 'es_extended'
provide 'qb-core'
provide 'qbx_core'
