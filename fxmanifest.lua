fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'BNDDO Legendary'
description 'Ambient style legendary spawning script'
author 'BNDOO Scripts'

shared_scripts {
    '@jo_libs/init.lua',
    "shared/config.lua",
    "shared/legendary_animals.lua"
}

jo_libs {
    'debugger',
    'callback',
    'table',
    'entity',
}

client_scripts {

    "client/client.lua",

}

server_scripts {
    "server/server.lua"
}

files {

}

escrow_ignore {
    "client/*",
    "server/*",
    "shared/*",
}
