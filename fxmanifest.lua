fx_version 'cerulean'
game 'gta5'

name 'qb_weather'
author 'ChatGPT'
description 'Custom QBCore Weather & Time Sync with Tsunami & Blackout'
version '1.0.0'

lua54 'yes'

shared_script 'config.lua'

server_scripts {
    '@qb-core/shared/locale.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

files {
    'water_flood.xml',
    'water_max.xml'
}
-- NOTE: To use water overrides for flooding, replace the above XML files
-- with real water height maps and enable Config.EnableWaterXML.
-- Some platforms may require specific data_file entries.
