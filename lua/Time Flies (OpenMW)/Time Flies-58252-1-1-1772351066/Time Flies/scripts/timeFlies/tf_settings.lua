local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local async = require('openmw.async')

MODNAME = 'TimeFlies'

local settingsTemplate = {}

settingsTemplate.TIMEFLIES = {
	key = 'Settings'..MODNAME..'SELF',
	page = MODNAME..'MAIN',
	l10n = 'none',
	name = 'Player actions for passing time                           ',
	description = 'Measured in minutes',
	permanentStorage = true,
	order = 0,
	settings = {
        {
            key = 'READING_TIME',
            name = 'Reading books',
            description = '', -- How many minutes pass when you read a book.
            renderer = 'number',
            default = 15,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'JOURNAL_TIME',
            name = 'Viewing Journal',
            description = '', -- How many minutes pass when you open your journal.
            renderer = 'number',
            default = 2,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'SELF_REPAIRING_TIME',
            name = 'Self repairing',
            description = '', -- How many minutes pass when you repair an item yourself.
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },				
        {
            key = 'SELF_ENCHANTING_TIME',
            name = 'Self enchanting',
            description = '', -- How many minutes pass when you enchant an item yourself.
            renderer = 'number',
            default = 30,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'RECHARGE_TIME',
            name = 'Recharging with soul gems',
            description = '', -- How many minutes pass when you recharge a weapon.
            renderer = 'number',
            default = 3,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'LOOTING_TIME',
            name = 'Looting and containers',
            description = '', -- How many minutes pass when you loot a container or body.\nDoes not effect Quickloot, only when a container UI is displayed.
            renderer = 'number',
            default = 1,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'LOCKPICKING_TIME', -- and oblivion lockpicking too
            name = 'Lockpicking and Disarming Traps',
            description = '', -- How many minutes pass when attempt to lockpick or disarm a trap.
            renderer = 'number',
            default = 2,
            argument = { min = 0, max = 480 },
        },	
        {
            key = 'CONSUME_TIME', -- kinda want food to take longer than eating ingredients and chugging potions though
            name = 'Eating ingredients and drinking potions',
            description = '',
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'POTION_TIME',
            name = 'Making a potion', -- **** you SE
            description = '',
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },		
        {
            key = 'HARVEST_TIME',
            name = 'Picking herbs',
            description = '',
            renderer = 'number',
            default = 2,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'SHRINE_TIME',
            name = 'Receiving a shrine blessing',
            description = '',
            renderer = 'number',
            default = 15,
            argument = { min = 0, max = 480 },
        },
    }
}

settingsTemplate.NPCs = {
    key = 'Settings'..MODNAME..'NPCs',
	page = MODNAME..'MAIN',
    l10n = 'none',
    name = 'Interactions with NPCs passes time',
	description = 'Measured in minutes',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'DIALOGUE_TIME',
            name = 'Talking to an NPC',
            description = '', -- How many minutes pass when you have a conversation with an NPC.
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },		
        {
            key = 'BARTER_TIME',
            name = 'Bartering and trading', -- nil -> dialogue -> service -> dialogue
            description = '', -- How many minutes pass each time you barter with a merchant.
            renderer = 'number',
            default = 10,
            argument = { min = 0, max = 480 },
        },	
        {
            key = 'SPELLCREATE_TIME',
            name = 'Creating a spell at a Spellmaker', -- nil -> dialogue -> service -> dialogue
            description = '', -- How many minutes pass when you create a spell at a spellmaker.
            renderer = 'number',
            default = 30,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'SPELLBUY_TIME',
            name = 'Buying spells at a Spellmaker', -- nil -> dialogue -> service -> dialogue
            description = '', -- How many minutes pass when you buy a spell at a spellmaker.
            renderer = 'number', 
            default = 10,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'REPAIRING_TIME',
            name = 'Repairing at a Smith.', -- nil -> dialogue -> service -> dialogue
            description = '', -- How many minutes pass when you repair an item at a smith.
            renderer = 'number',
            default = 20,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'ENCHANTING_TIME',
            name = 'Enchanting at an Enchanter',
            description = '', -- How many minutes pass when you enchant an item at an enchanter.
            renderer = 'number',
            default = 60,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'COMPANION_TIME',
            name = 'Sharing with a companion',
            description = '', -- How many minutes pass when you share with a companion.
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },
		{
			key = 'EXTRA_TRAINING_TIME',
			name = 'Extra Training Time',
			description = 'Extra time added on top of the normal training time each session.\nVanilla Training time is 2 hours (hardcoded)',
			renderer = 'number',
			default = 0,
			argument = { min = 0, max = 480 },
		},
		{
			key = 'EXTRA_TRAINING_TIME_PER_LEVEL',
			name = 'Extra Training Time Per Level',
			description = 'Additional time added per current skill level, on top of normal training time.\nVanilla Training time is 2 hours (hardcoded)',
			renderer = 'number',
			default = 1,
			argument = { min = 0, max = 480 },
		},
--[[        {
            key = 'ADMIRE_TIME',
            name = 'Admiring a character',
            description = 'Requires the most recent update of 0.51', 
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },
		{
            key = 'INTIMIDATE_TIME',
            name = 'Intimidating a character',
            description = 'Requires the most recent update of 0.51', 
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },
		{
            key = 'TAUNT_TIME',
            name = 'Taunting a character',
            description = 'Requires the most recent update of 0.51', 
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },
		{
            key = 'BRIBE_TIME',
            name = 'Bribing a character',
            description = 'Requires the most recent update of 0.51', 
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },]]
		-- DialogueConditionType.Fight
		-- DialogueConditionType.Flee
		-- DialogueConditionType.Alarm		
    }
}

settingsTemplate.DELAY = {
    key = 'Settings'..MODNAME..'DELAY',
	page = MODNAME..'MAIN',
    l10n = 'none',
    name = 'Delay before time passes',
	description = 'Coming soon',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'DELAY_TOGGLE', -- not implemented
            name = 'Enable delay',
            description = 'Actions do not take time if done quickly', -- (opening a book quickly for example)
            renderer = 'checkbox',
            default = true,
            argument = { disabled = true },
        },
        {
            key = 'DELAY_TIME', -- not implemented
            name = 'How much time for the delay before time passing kicks in',
            description = 'in seconds',
			renderer = 'number',
			default = 10,
			argument = { disabled = true, min = 0, max = 1000 },
		},
--[[    {
            key = 'PSEUDOUNPAUSEDMENUS?????',
            name = 'Enable delay',
            description = 'Actions do not take time if done quickly (opening a book quickly for example)',
            renderer = 'checkbox',
            default = true,
        },		
       {
            key = 'FTB_TOGGLE',
            name = 'Fade to black?',
            description = 'Prolonged actions have a fade to black',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'FTB_THRESHOLD',
            name = 'After how many minutes of a time passing should a ftb kick in?',
            description = 'in seconds',
			renderer = 'number',
			default = 60,
			argument = { min = 0, max = 2400 },
		},
        {
            key = 'FTB_TIME',
            name = 'How long should ftb be?',
            description = 'in seconds',
			renderer = 'number',
			default = 1,
			argument = { min = 0, max = 60 },
		},]]
    }
}

settingsTemplate.CRAFTING = {
    key = 'Settings'..MODNAME..'CRAFTING',
	page = MODNAME..'MAIN',
    l10n = 'none',
    name = 'Crafting',
	description = 'Coming soon',	
    permanentStorage = true,
    order = 3,
    settings = {
        {
            key = 'CRAFTING_TIME_TOGGLE', -- not implemented
            name = 'Crafting takes time?',
            description = '',
            renderer = 'checkbox',
            default = true,
            argument = { disabled = true },
        },
        {
            key = 'CRAFTING_TIME_EXPERTISE',
            name = 'Expertise (skill) reduces crafting time?', -- not implemented
            description = '',
            renderer = 'checkbox',
            default = true,
            argument = { disabled = true },
        },
    }
}

settingsTemplate.SD = {
    key = 'Settings'..MODNAME..'SURVIVAL',
	page = MODNAME..'MAIN',
    l10n = 'none',
    name = 'Survival actions take time',
	description = "Requires Sun's Dusk. Measured in minutes.",
    permanentStorage = true,
    order = 4,
    settings = {
        {
            key = 'COOKING_TIME',
            name = 'Cooking from yourself and publicans',
            description = '', -- How many minutes pass when you cook a meal.
            renderer = 'number',
            default = 15,
            argument = { min = 0, max = 480 },
        },
		{
            key = 'TEA_TIME',
            name = 'Brewing tea',
            description = '', -- How many minutes pass when you brew tea.
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'BATHING_TIME',
            name = 'Bathing',
            description = '',
            renderer = 'number',
            default = 15,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'REFILL_TIME',
            name = 'Refilling from wells and kegs',
            description = '',
            renderer = 'number',
            default = 5,
            argument = { min = 0, max = 480 },
        },		
        {
            key = 'PURIFY_TIME',
            name = 'Purifying water takes time',
            description = '', -- How many minutes pass when you cook a meal.
            renderer = 'number',
            default = 10,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'WOODCUTTING_TIME',
            name = 'Cutting wood takes time',
            description = 'How many minutes pass when you cook a meal.',
            renderer = 'number',
            default = 4,
            argument = { min = 0, max = 480 },
        },			
        {
            key = 'CAMPFIRE_TIME',
            name = 'Making a campfire',
            description = '',
            renderer = 'number',
            default = 2,
            argument = { min = 0, max = 480 },
        },		
        {
            key = 'TENT_PITCH_TIME',
            name = 'Pitching a tent',
            description = '',
            renderer = 'number',
            default = 3,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'TENT_DESTROY_TIME',
            name = 'Breaking camp',
            description = '',
            renderer = 'number',
            default = 3,
            argument = { min = 0, max = 480 },
        },
    }
}

settingsTemplate.OWNLYME = {
    key = 'Settings'.. MODNAME..'OWNLYME',
	page = MODNAME..'MAIN',
    l10n = 'none',
    name = "Ownlyme's Suite",
	description = 'Requires Simply Mining, Disenchanting, and Quickloot for individual settings.\nMeasured in minutes.',	
    permanentStorage = true,
    order = 5,
    settings = {
        {
            key = 'MINING_TIME',
            name = 'Mining',
            description = '',
            renderer = 'number',
            default = 4,
            argument = { min = 0, max = 480 },
        },
        {
            key = 'DISENCHANTING_TIME',
            name = 'Disenchanting',
            description = '',
            renderer = 'number',
            default = 60,
            argument = { min = 0, max = 480 },
        },
		{
			key = 'BODIES_TIME',
			name = 'Disposing bodies',
			description = 'When using Quickloot',
			renderer = 'number',
			default = 15,
			argument = { min = 0, max = 480 },
		},
    }
}

settingsTemplate.RALTS = {
    key = 'Settings'.. MODNAME..'RALTS',
	page = MODNAME..'MAIN',
    l10n = 'none',
    name = "Bardcraft",
	description = 'Coming Soon',
    permanentStorage = true,
    order = 6,
    settings = {
        {
            key = 'PERFORMANCE_TIME',
            name = 'Performing a song takes time',
            description = '',
            renderer = 'number',
            default = 15,
            argument = { disabled = true, min = 0, max = 480 },
        },
    }
}

--[[settingsTemplate.RELIGION = {
    key = 'Settings'..MODNAME..'RELIGION',
	page = MODNAME..'MAIN',
    l10n = 'none',
    name = 'Evening Star (coming soon)',
	description = 'Religious actions take time',
    permanentStorage = true,
    order = 8,
    settings = {
        {
            key = 'PRAYER_TIME',
            name = '(Coming soon) Prayer takes time',
            description = '',
            renderer = 'number',
            default = 60,
            argument = { min = 0, max = 480 },
        },
    }
}]]

for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

I.Settings.registerPage {
	key = MODNAME..'MAIN',
	l10n = 'none',
	name = 'Time Flies',
	description = 'Actions in game take time.',
}

-- called on init and when settings change
local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for i, entry in pairs(template.settings) do
			_G[entry.key] = settingsSection:get(entry.key) or entry.default
		end
	end
end

readAllSettings()

for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
	end))
end

-- disable time passing when in combat ?