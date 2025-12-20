local MODNAME = "QLPP"

local tempKey
local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local settingsTemplate = {}


tempKey = "Difficulty Formula"
settingsTemplate[tempKey] = {
    key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ", -- lol
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "QLPP_BASE_DIFFICULTY",
			name = "Base Difficulty",
			description = "Base difficulty (in skill levels)\nBTW: The settings are in order of operation",
			renderer = "number",
			default = -15,
			argument = {
				min = -100,
				max = 100,
			},
		},
		{
			key = "QLPP_POISON_DIFFICULTY",
			name = "Poison Difficulty",
			description = "+ poison magnitude * mult\n(Final chance * 0.5 to not get caught)\nPoisons are made by not using an alembic",
			renderer = "number",
			default = 1.0,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_WEIGHT_MULT",
			name = "Weight Multiplier",
			description = "+ weight*mult",
			renderer = "number",
			default = 0.25,
			argument = {
				min = 1,
				max = 100,
			},
		},
		{
			key = "QLPP_VALUE_ADD",
			name = "Price Add",
			description = "+ (price+add)^exp*mult",
			renderer = "number",
			default = -10,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_VALUE_EXP",
			name = "Price Exponent",
			description = "+ (price+add)^exp*mult",
			renderer = "number",
			default = 0.51,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_VALUE_MULT",
			name = "Price Mult",
			description = "+ (price+add)^exp*mult",
			renderer = "number",
			default = 1.5,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_EQUIPPED_MULT",
			name = "Equipped Mult",
			description = "* mult\nMultiply Base difficulty, weight and price by [x] if the item is equipped",
			renderer = "number",
			default = 1.1,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_EQUIPPED_ARMOR_BONUS",
			name = "Equipped Armor Bonus",
			description = "+ bonus\nAdd difficulty points if the armor is equipped",
			renderer = "number",
			default = 30,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_EQUIPPED_WEAPON_BONUS",
			name = "Equipped Weapon Bonus",
			description = "+ bonus\nAdd difficulty points if the weapon is equipped",
			renderer = "number",
			default = 50,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_EQUIPPED_JEWELRY_BONUS",
			name = "Equipped Jewelry Bonus",
			description = "+ bonus\nAdd difficulty points if the ring/amulet is equipped",
			renderer = "number",
			default = 15,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_TARGET_SKILL_MULT",
			name = "Target Skill Mult",
			description = "+ (Sneak+Agility*0.2+Luck*0.1)*mult\nAdds Sneak Skill + Attributes of the target to difficulty",
			renderer = "number",
			default = 0.6,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_MERCHANT_MULT",
			name = "Merchant Mult",
			description = "* mult\nMultiply difficulty if merchant",
			renderer = "number",
			default = 1.5,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_MERCHANT_ADD",
			name = "Merchant Bonus",
			description = "+ bonus\nFlat bonus to difficulty for merchants",
			renderer = "number",
			default = 20,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_IN_COMBAT_MODIFIER",
			name = "In Combat Modifier",
			description = "+ bonus\nAdded difficulty for pickpocketing in combat",
			renderer = "number",
			default = 40,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_OWN_SKILL_MULT",
			name = "Own Skill Mult",
			description = "% Chance = skill*mult-difficulty\n(skill includes attributes)",
			renderer = "number",
			default = 2,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_SECURITY_SKILL",
			name = "Use Security Skill",
			description = "Use the security skill instead of sneak, but still agility as governing attribute",
			renderer = "checkbox",
			default = false
		},
	}
}



tempKey = "Chance Modifiers"
settingsTemplate[tempKey] = {
    key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ", -- lol
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "QLPP_FATIGUE_MIN_MODIFIER",
			name = "Fatigue Min Modifier",
			description = "* mult\nMultiplier on % Chance when exhausted",
			renderer = "number",
			default = 0.9,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_FATIGUE_MAX_MODIFIER",
			name = "Fatigue Max Modifier",
			description = "* mult\nMultiplier on % Chance when rested",
			renderer = "number",
			default = 1.1,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_FRONT_MODIFIER",
			name = "From Front Modifier",
			description = "* mult\nMultiplier on % Chance from the front (front quarter)",
			renderer = "number",
			default = 0.9,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_BACK_MODIFIER",
			name = "From Back Modifier",
			description = "* mult\nMultiplier on % Chance from the back (back quarter)",
			renderer = "number",
			default = 1.15,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_USED_ATTEMPT_MODIFIER",
			name = "Used Attempts Mult",
			description = "- [used attempts]*mult\nSubtract used attempts times [x] from % chance to make repeated pickpocketing harder",
			renderer = "number",
			default = 1,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_MAX_PICKPOCKET_CHANCE",
			name = "Max Pickpocket Chance",
			description = "math.min([x],chance)\nCap max chance to pickpocket an item at [x]%",
			renderer = "number",
			default = 100,
			argument = {
				min = 0,
				max = 100,
			},
		},
	}
}


tempKey = "Attempts and Perks"
settingsTemplate[tempKey] = {
    key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ", -- lol
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "QLPP_FAILED_ATTEMPT_COST",
			name = "Failed attempt cost",
			description = "The amount of attempts you loose when failing the theft",
			renderer = "number",
			default = 2,
			argument = {
				min = 1,
				max = 1000000,
			},
		},
		{
			key = "QLPP_MAX_THEFTS_PER_NPC",
			name = "Max Attempts Per NPC",
			description = "You can only attempt pickpocketing this many times per npc",
			renderer = "number",
			default = 2,
			argument = {
				min = 1,
				max = 100000,
			},
		},
		{
			key = "QLPP_SKILL_FOR_BONUS_ATTEMPTS",
			name = "Skill requirement for bonus attempts",
			description = "Every x levels you get a bonus attempt",
			renderer = "number",
			default = 30,
			argument = {
				min = 1,
				max = 100000,
			},
		},
		{
			key = "QLPP_MIN_SKILL_FOR_NO_PUNISHMENT",
			name = "Min Skill For No Punishment",
			description = "Above this skill level, no crimes will get triggered when caught",
			renderer = "number",
			default = 20,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_SKILL_FOR_IN_COMBAT",
			name = "Skill Required For Combat Pickpocketing",
			description = "Above this skill level you can pickpocket in combat",
			renderer = "number",
			default = 50,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_SKILL_TO_BYPASS_SKILL_CHECK",
			name = "Skill to bypass Pocket Peeking Skill Check",
			description = "Otherwise you gotta pass a skill check for a 0 value item to peek into pockets",
			renderer = "number",
			default = 30,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "QLPP_ITEM_VISIBILITY_MULT",
			name = "Item Peeking Chance",
			description = "Percent Chance to see each item at 100 Skill (proportional below that)",
			renderer = "number",
			default = 1000000,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "QLPP_ONLY_SHOW_ABOVE_CHANCE",
			name = "Min Chance to show item",
			description = "Required stealing chance (%) for items to appear at all (assumes you're coming from the back, ignores fatigue bonuses)",
			renderer = "number",
			default = 33,
			argument = {
				min = 0,
				max = 200,
			},
		},
	}
}


tempKey = "Experience"
settingsTemplate[tempKey] = {
    key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ", -- lol
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "QLPP_EXPERIENCE_ADD",
			name = "Base Experience",
			description = "Flat value for rewarded experience",
			renderer = "number",
			default = 3.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "QLPP_EXPERIENCE_MULT",
			name = "Experience Multiplier",
			description = "Multiplies the difficulty rating by this value for extra experience",
			renderer = "number",
			default = 0.06,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "QLPP_FAILED_ATTEMPT_EXPERIENCE_MULT",
			name = "Failed Attempt Experience Multiplier",
			description = "When failing, experience is multiplied by success chance and also this multiplier\nFailed pocket peeking always rewards 1 exp",
			renderer = "number",
			default = 0.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
	}
}


tempKey = "Misc"
settingsTemplate[tempKey] = {
    key = 'Settings'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                             ", -- lol
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "QLPP_DEBUG_MODE",
			name = "Debug Mode",
			description = "Print calculations in console",
			renderer = "checkbox",
			default = false
		},
	}
}


-- Settings Migration
local legacySection = storage.playerSection('SettingsPlayer'..MODNAME)
if legacySection:get("BASE_DIFFICULTY") then
	for id, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for i, entry in pairs(template.settings) do
			local originalKey = entry.key:sub(6,-1)
			settingsSection:set(entry.key, legacySection:get(originalKey) or entry.default)
		end
	end
	legacySection:reset()
end

for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end


I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = MODNAME
}

-- called on init and when settings change
local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for i, entry in pairs(template.settings) do
			_G[entry.key] = settingsSection:get(entry.key)
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
