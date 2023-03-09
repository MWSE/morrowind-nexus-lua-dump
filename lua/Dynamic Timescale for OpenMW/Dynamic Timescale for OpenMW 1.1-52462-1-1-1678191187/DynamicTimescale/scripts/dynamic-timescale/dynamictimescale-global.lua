local core = require('openmw.core')
local world = require('openmw.world')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local types = require('openmw.types')

I.Settings.registerGroup {
    key = 'SettingsDynamicTimescale',
    page = 'DynamicTimescale',
    l10n = 'DynamicTimescale',
    name = 'Timescale Settings',
    description = 'Adjust the timescales for different situations. Numbers correspond to morrowind minutes per real life minute. Morrowind vanilla default is 30.',
    permanentStorage = false,
    settings = {
        {
            key = 'wildernessTimescale',
            renderer = 'number',
            name = 'Wilderness Timescale',
            description = 'Timescale for when in the wilderness',
            default = 30
        },
		{
            key = 'townTimescale',
            renderer = 'number',
            name = 'Town Timescale',
            description = 'Timescale for when in villages, towns and cities and other no sleep zones.',
            default = 15
        },
		{
            key = 'interiorTimescale',
            renderer = 'number',
            name = 'Interior Timescale',
            description = 'Timescale for when indoors',
            default = 8
        },
		{
            key = 'enableFightSneakTime',
            renderer = 'checkbox',
            name = 'Enable combat and sneaking timescales',
            description = 'Enables separate timescales for sneaking and fighting which overrides the location ones. Enabled by default.',
            default = true
        },
		{
            key = 'sneakingTimescale',
            renderer = 'number',
            name = 'Sneaking Timescale',
            description = 'Timescale for when sneaking',
            default = 5
        },
		{
            key = 'combatTimescale',
            renderer = 'number',
            name = 'Combat Timescale',
            description = 'Timescale for when weapon or magic readied',
            default = 5
        },
		
    }
}

local globalSettings = storage.globalSection('SettingsDynamicTimescale')

return{
	eventHandlers = {
		['daisysettimescaleCELL'] = function(e)
			player = e.player
			if player.cell.isExterior == true or player.cell:hasTag('QuasiExterior') == true then
				if player.cell:hasTag('NoSleep') == true then
					world.setGameTimeScale(globalSettings:get('townTimescale'))
				else
					world.setGameTimeScale(globalSettings:get('wildernessTimescale'))
				end
			else
				world.setGameTimeScale(globalSettings:get('interiorTimescale'))
			end
		end,
		['daisysettimescaleCOMBAT'] = function()
			world.setGameTimeScale(globalSettings:get('combatTimescale'))
		end,
		['daisysettimescaleSNEAKING'] = function()
			world.setGameTimeScale(globalSettings:get('sneakingTimescale'))
		end
	}
}