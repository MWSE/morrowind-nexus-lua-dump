local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Activator] = {
        title = 'Activator',
        color = util.color.rgb(0.8, 0.2, 0.8),
        showWeight = true,
		uniqueDescriptions = {
			['activator_lever_01'] = {
				'Lever',
				'Mechanical activator.',
				'Type: Activator',
				'Location: Dungeons, ruins, temples',
				'Description: Wall‑mounted lever used to open doors, lower bridges, or activate traps.',
				'Notes: Cannot be picked up. Used to trigger mechanisms.'
			},
			['activator_button_01'] = {
				'Button',
				'Pressure‑sensitive activator.',
				'Type: Activator',
				'Location: Daedric ruins, magical chambers',
				'Description: Recessed button that activates when pressed.',
				'Notes: Often requires specific weight or spell to activate.'
			},
			['activator_pressure_plate_01'] = {
				'Pressure Plate',
				'Floor‑mounted activator.',
				'Type: Activator',
				'Location: Trap‑filled dungeons, ancient ruins',
				'Description: Hidden plate that activates when stepped on.',
				'Notes: Triggers traps, opens secret doors.'
			},
			['door_01'] = {
				'Door',
				'Standard wooden door.',
				'Type: Activator (Door)',
				'Location: Everywhere — homes, shops, dungeons',
				'Description: Barrier that can be opened, locked, or trapped.',
				'Notes: May require key, lockpick, or spell to open.'
			},
			['container_chest_01'] = {
				'Chest',
				'Storage container.',
				'Type: Container/Activator',
				'Location: Dungeons, homes, guarded areas',
				'Description: Wooden box used to store items. Often locked.',
				'Notes: Can contain loot, may be trapped.'
			}
        }
    }
}