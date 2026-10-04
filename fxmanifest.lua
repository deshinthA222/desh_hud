fx_version 'cerulean'

game 'gta5'
lua54 'yes'

author 'Smokey / Deshintha'
description 'Jet HUD + Vehicle Menu + Dashboard Gauges + Radar'
version '3.1.70'

files {
	'html/*.html',
	'html/*.css',
	'html/*.js',
	'html/*.svg',
	'html/icons/*.svg',
	'html/sounds/*',
	'html/flight-indicators/*',
	'html/flight-indicators/img/*'
}

ui_page 'html/index.html'

client_scripts {
	'config.lua',
	'client/main.lua',
	'client/aircraft_radar.lua',
	'client/status.lua',
	'client/weapon_hud.lua',
	'client/vehicle_crosshair.lua',
	'client/stance.lua',
	'client/fire_modes.lua',
	'client/vehicle_menu.lua',
	'client/dashboard.lua',
	'client/helicopter_hud.lua',
	'client/boat_hud.lua'
}
