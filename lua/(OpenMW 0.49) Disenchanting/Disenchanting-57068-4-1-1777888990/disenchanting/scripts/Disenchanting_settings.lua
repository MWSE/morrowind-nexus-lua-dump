local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local async = require('openmw.async')
local MODNAME = "Disenchanting"

local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local settingsTemplate = {}

local tempKey

-- ---------------------------------------------- skill progression ----------------------------------------------
tempKey = "Skill Progression"
settingsTemplate[tempKey] = {
	key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                        ",
	description = "",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "EXPERIENCE_EXP",
			name = "Experience Exponent",
			description = "EnchantmentPoints ^ Exponent",
			renderer = "number",
			default = 0.71,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "EXPERIENCE_MULT2",
			name = "Experience Mult",
			description = "* Mult",
			renderer = "number",
			default = 0.4,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "EXPERIENCE_ADD2",
			name = "Experience Add",
			description = "+ Add",
			renderer = "number",
			default = 3.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "CONSUME_MULT",
			name = "Consuming Experience Mult",
			description = "Soul value gets fed into the formula above and multiplied by this\n0 disables the dialogue when you use a soulgem with shift",
			renderer = "number",
			default = 2.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "DISENCHANTING_EXPERTISE_MULT",
			name = "Disenchanting Expertise Multiplier",
			description = "Increases your enchanting by 4 points for each unique effect you have disenchanted plus the count of all effects you have ever disenchanted (max. +5 per item)\nmultiplied by this value",
			renderer = "number",
			default = 0.05,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "UNCAPPER",
			name = "Uncapper",
			description = "Allow leveling enchanting higher than 100 though disenchanting or consuming soulgems",
			renderer = "checkbox",
			default = true,
		},
	},
}

-- ---------------------------------------------- soul recovery ----------------------------------------------
tempKey = "Soul Recovery"
settingsTemplate[tempKey] = {
	key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                        ",
	description = "",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "RECOUPED_SOUL",
			name = "Recouped Soul Mult",
			description = "enchantment size * this mult\nset to 0 to disable",
			renderer = "number",
			default = 0.7,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "MINIMUM_RECOUPED_SOUL",
			name = "Minimum Recouped Soul",
			description = "if the recouped soul is smaller than this value, don't create a soulgem",
			renderer = "number",
			default = 10,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "REQUIRE_EMPTY_SOULGEM",
			name = "Require empty soul gem",
			description = "does not use azura's star",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "PROJECTILES_PER_CHUNK",
			name = "Projectiles per Chunk",
			description = "maximum stack size of enchanted arrows/bolts/thrown weapons per soul gem",
			renderer = "number",
			default = 20,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "PROJECTILES_ENCHANT_MULTIPLIER",
			name = "Projectiles Enchant Multiplier",
			description = "set to match the engine's\n\"projectiles enchant multiplier\"\n(settings.cfg -> [Game])\n!!! DIVISOR, so smaller values = more soul recovery per arrow\n(the engine uses this as a multiplier, so we use it as a divisor to revert the change)",
			renderer = "number",
			default = 0.25,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "SOUL_PRICE_REBALANCE",
			name = "Tooltip Price Is Rebalanced?",
			description = "Do you have 'rebalance soul gem values' enabled in the settings?\nI recommend using my 'worthless soul gems' mod instead\nThis is only used for showing the correct price in the consume window.",
			renderer = "checkbox",
			default = true,
		},
	},
}

-- ---------------------------------------------- disenchanted item ----------------------------------------------
tempKey = "Disenchanted Item"
settingsTemplate[tempKey] = {
	key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                        ",
	description = "",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "VALUE_MULT",
			name = "Disenchanted Item Value Mult",
			description = "0 = don't create a disenchanted version",
			renderer = "number",
			default = 0.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "CAPACITY_MULT",
			name = "Disenchanted Item Capacity Mult",
			description = "new capacity = old capacity * this mult",
			renderer = "number",
			default = 0.90,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "CAPACITY_FROM_ENCHANTMENT",
			name = "Capacity Increase From Old Enchantment",
			description = "new capacity = value above + (enchantment size * this mult)",
			renderer = "number",
			default = 0.43,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "BEST_IN_SLOT_CAP",
			name = "Cap at x times best in slot value",
			description = "If the new capacity is higher than x times the best unenchanted item for this slot, reduce it to x times that item's capacity",
			renderer = "number",
			default = 999999999,
			argument = {
				min = 0,
				max = 999999999,
			},
		},
		{
			key = "CAPACITY_CAP_FOR_TRASH",
			name = "Enchant Magnitude Mult for Trash",
			description = "The enchant magnitude that the formula uses is usually capped at 2x the item's base capacity.\nFor example boots of blinding light have a magnitude of several thousand but would get held back by their base capacity of 10.\nThis multiplier lifts it back up to at least x times the enchantment magnitude.",
			renderer = "number",
			default = 0.1428,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "ENCHANT_CAPACITY_FIX",
			name = "Enchanting Capacity Fix",
			description = "Fixes that the game changes an item's capacity when you enchant it (does not affect charges or anything)\nAlso gets rid of the 'Drained' and '[123]' in the name",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "APPEND_CAPACITY_TO_NAME",
			name = "Append Capacity To Name",
			description = "Append the new enchantment capacity in brackets to the drained item's name, e.g. 'Drained Iron Helm [42]'",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "PREPEND_DRAINED_TO_NAME",
			name = "Prepend 'Drained' To Name",
			description = "The disenchanted item will be called 'Drained <Name>'",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "SHOW_CAPACITY_IN_IE_TOOLTIP",
			name = "Show Capacity In IE Tooltip",
			description = "Show the enchantment capacity in Inventory Extender tooltips",
			renderer = "select",
			default = "On Drained",
			argument = {
				disabled = false,
				l10n = "none",
				items = {"Always", "On Drained", "Hold Shift", "Never" },
			},
		},
	},
}

-- ---------------------------------------------- effects & paper ----------------------------------------------
tempKey = "Effects & Paper"
settingsTemplate[tempKey] = {
	key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                        ",
	description = "",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "ALLOW_SPELLMAKING",
			name = "Use Effects in Spellmaking",
			description = "Allow using the effects learnt from disenchanting in spellmaking",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "ALLOW_REENCHANTING",
			name = "Use Effects in Enchanting",
			description = "Allow using the effects learnt from disenchanting in enchanting",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "OWN_SPELLS_IN_LIBRARY",
			name = "Own Spells In Library",
			description = "Enable if you want every spell you have ever known to be available for enchanting (and spellmaking?)",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "PAPER_MULT",
			name = "Enchanted Paper Multiplier",
			description = "For every enchanted paper you get x-1 extra",
			renderer = "number",
			default = 5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
	},
}

-- ---------------------------------------------- migration ----------------------------------------------
-- legacy single-section -> grouped sections; gated on `world` so only the global VM runs it
if world then
	local legacySection = storage.globalSection('Settings'..MODNAME)
	if legacySection:get("EXPERIENCE_EXP") ~= nil then
		for id, template in pairs(settingsTemplate) do
			local settingsSection = storage.globalSection(template.key)
			for i, entry in pairs(template.settings) do
				local v = legacySection:get(entry.key)
				if v == nil then v = entry.default end
				settingsSection:set(entry.key, v)
			end
		end
		legacySection:reset()
	end
end

-- ---------------------------------------------- registration ----------------------------------------------
-- groups in global, page elsewhere
if world then
	for _, template in pairs(settingsTemplate) do
		I.Settings.registerGroup(template)
	end
else
	I.Settings.registerPage {
		key = MODNAME,
		l10n = "none",
		name = "Disenchanting",
		description = ""
	}
end

-- ---------------------------------------------- cache + reactive ----------------------------------------------
-- mirror every setting to _G["S_"..key] and keep it fresh on changes
local sections = {}
for _, template in pairs(settingsTemplate) do
	local sec = storage.globalSection(template.key)
	table.insert(sections, sec)
	for _, entry in pairs(template.settings) do
		local v = sec:get(entry.key)
		if v == nil then v = entry.default end
		_G["S_"..entry.key] = v
	end
	sec:subscribe(async:callback(function(_, key)
		_G["S_"..key] = sec:get(key)
	end))
end

-- subscribers get called after settings were updated
return {
	subscribe = function(cb)
		for _, sec in pairs(sections) do
			sec:subscribe(async:callback(cb))
		end
	end,
}
