
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
description 'Custom Multicharacter for ZDX'
author 'ZiDFPS'
version '1.1'

shared_scripts {
    "config.lua",
    "shared/creation.lua",
    "shared/delete_tables.lua",
    "shared/bridge/spawn_selector.lua",
}

client_scripts {
    "locales/*.lua",
    "shared/bridge/cl_clothing.lua",
    "client/core.lua",
    "client/camera.lua",
    "client/settings.lua",
    "client/main.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "locales/*.lua",
    "shared/bridge/sv_clothing.lua",
    "shared/slot.lua",
    "shared/webhooks.lua",
    "server/core.lua",
    "server/frameworks/*.lua",
    "server/main.lua",
    "server/update.lua",
}

ui_page "html/index.html"

files {
    "html/index.html",
    "html/assets/*.css",
    
    "html/assets/*.png",
    "html/js/*.js",
    "html/fonts/*.otf",
    "html/fonts/*.ttf",
    "html/fonts/*.TTF",
}

escrow_ignore {
    "config.lua",
    "locales/*.lua",
    "shared/creation.lua",
    "shared/animations.lua",
    "shared/delete_tables.lua",
    "shared/locations.lua",
    "shared/slot.lua",
    "shared/webhooks.lua",
    "shared/bridge/*.lua",
}
dependency 'oxmysql'
