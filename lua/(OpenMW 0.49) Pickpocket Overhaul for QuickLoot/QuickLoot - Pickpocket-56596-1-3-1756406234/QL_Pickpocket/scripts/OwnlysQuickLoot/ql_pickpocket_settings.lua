local MODNAME = "QLPP"



settings = {
    key = 'SettingsPlayer'..MODNAME,
    page = MODNAME,
    l10n = MODNAME,
    name = "QuickLoot PP",
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "BASE_DIFFICULTY",
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
			key = "POISON_DIFFICULTY",
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
			key = "WEIGHT_MULT",
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
			key = "VALUE_ADD",
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
			key = "VALUE_EXP",
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
			key = "VALUE_MULT",
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
			key = "EQUIPPED_MULT",
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
			key = "EQUIPPED_ARMOR_BONUS",
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
			key = "EQUIPPED_WEAPON_BONUS",
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
			key = "EQUIPPED_JEWELRY_BONUS",
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
			key = "TARGET_SKILL_MULT",
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
			key = "MERCHANT_MULT",
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
			key = "MERCHANT_ADD",
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
			key = "IN_COMBAT_MODIFIER",
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
			key = "OWN_SKILL_MULT",
			name = "Own Skill Mult",
			description = "% Chance = skill*mult-difficulty\n(skill includes attributes)\n--------------------------------------------",
			renderer = "number",
			default = 2,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "FATIGUE_MIN_MODIFIER",
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
			key = "FATIGUE_MAX_MODIFIER",
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
			key = "FRONT_MODIFIER",
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
			key = "BACK_MODIFIER",
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
			key = "USED_ATTEMPT_MODIFIER",
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
			key = "MAX_PICKPOCKET_CHANCE",
			name = "Max Pickpocket Chance",
			description = "math.min([x],chance)\nCap max chance to pickpocket an item at [x]%",
			renderer = "number",
			default = 100,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "SECURITY_SKILL",
			name = "Use Security Skill",
			description = "Use the security skill instead of sneak, but still agility as governing attribute",
			renderer = "checkbox",
			default = false
		},
		{
			key = "FAILED_ATTEMPT_COST",
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
			key = "MAX_THEFTS_PER_NPC",
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
			key = "SKILL_FOR_BONUS_ATTEMPTS",
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
			key = "MIN_SKILL_FOR_NO_PUNISHMENT",
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
			key = "SKILL_FOR_IN_COMBAT",
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
			key = "SKILL_TO_BYPASS_SKILL_CHECK",
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
			key = "ITEM_VISIBILITY_MULT",
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
			key = "ONLY_SHOW_ABOVE_CHANCE",
			name = "Min Chance to show item",
			description = "Required stealing chance (%) for items to appear at all (assumes you're coming from the back, ignores fatigue bonuses)",
			renderer = "number",
			default = 33,
			argument = {
				min = 0,
				max = 200,
			},
		},
		{
			key = "EXPERIENCE_ADD",
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
			key = "EXPERIENCE_MULT",
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
			key = "FAILED_ATTEMPT_EXPERIENCE_MULT",
			name = "Failed Attempt Experience Multiplier",
			description = "When failing, experience is multiplied by success chance and also this multiplier\nFailed pocket peeking always rewards 1 exp",
			renderer = "number",
			default = 0.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "DEBUG_MODE",
			name = "Debug Mode",
			description = "Print calculations in console",
			renderer = "checkbox",
			default = false
		},
	}
}

I.Settings.registerGroup(settings)

I.Settings.registerPage {
    key = MODNAME,
    l10n = MODNAME,
    name = "QuickLoot PP",
    description = ""
}


return true