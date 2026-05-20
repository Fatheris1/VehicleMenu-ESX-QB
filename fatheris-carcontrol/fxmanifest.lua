fx_version 'cerulean'
games { 'gta5' }

author '.fatheris'
description 'Vehicle control menu'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png'
}

shared_scripts { 'config.lua' }
client_scripts  { 'client/main.lua' }
server_scripts  { 'server/main.lua' }

lua54 'yes'
