fx_version 'bodacious'
games { 'gta5' }

dependencies {
    'oxmysql',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

export 'Migrate'

lua54 'yes'
