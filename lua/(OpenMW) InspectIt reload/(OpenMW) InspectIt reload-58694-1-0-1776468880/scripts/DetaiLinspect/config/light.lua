local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Light] = {
        title = 'Light',
        color = util.color.rgb(1.0, 0.9, 0.3),
        showWeight = true,
        showValue = true,
		uniqueDescriptions = {
			['light_torch_01'] = {
				'Torch',
				'Portable light source.',
				'Type: Light Source',
				'Location: Homes, taverns, dungeons, sold by traders',
				'Description: Wooden stick with flammable material. Provides light for a limited time.',
				'Notes: Weight: 1.0, Value: 1 gold, Duration: 60 seconds. Can be used as a melee weapon.'
			},
			['light_lantern_01'] = {
				'Lantern',
				'Oil‑powered light source.',
				'Type: Light Source',
				'Location: Wealthy homes, temples, guard posts',
				'Description: Metal container with oil and a wick. Burns longer than a torch.',
				'Notes: Weight: 2.0, Value: 15 gold, Duration: 120 seconds.'
			},
			['light_candle_01'] = {
				'Candle',
				'Small light source.',
				'Type: Light Source',
				'Location: Homes, temples, shops',
				'Description: Wax or tallow candle. Provides dim light.',
				'Notes: Weight: 0.1, Value: 2 gold, Duration: 30 seconds.'
			},
			['light_glowdust_01'] = {
				'Glow Dust',
				'Magical glowing powder.',
				'Type: Alchemical Light Source',
				'Location: Alchemists, rare chests, Daedric ruins',
				'Description: Fine powder that emits a soft magical light.',
				'Notes: Weight: 0.0, Value: 5 gold, Duration: 45 seconds. Also used in alchemy.'
			}
        }
    }
}