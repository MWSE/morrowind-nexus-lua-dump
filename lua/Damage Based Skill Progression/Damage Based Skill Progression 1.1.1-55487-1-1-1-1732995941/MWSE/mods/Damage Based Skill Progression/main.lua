--[[
	Damage Based Skill Progression:
	MWSE LUA Edition
	v1.1.1
	by Pimgd
]]--
local version = "v1.1.1"
local defaultConfig = {
	enableDBSP = true,
	enableSettingsPerSkill = false,
	skillExpPerHealth = 0.1,
	skillExpPerHealthBlunt = 0.1,
	skillExpPerHealthLongBlade = 0.1,
	skillExpPerHealthAxe = 0.1,
	skillExpPerHealthSpear = 0.1,
	skillExpPerHealthShortBlade = 0.1,
	skillExpPerHealthMarksman = 0.1,
	skillExpPerHit = 0.1,
	skillExpPerHitBlunt = 0.1,
	skillExpPerHitLongBlade = 0.1,
	skillExpPerHitAxe = 0.1,
	skillExpPerHitSpear = 0.1,
	skillExpPerHitShortBlade = 0.1,
	skillExpPerHitMarksman = 0.1,
	overkillExpPercentage = 0.0,
	logging = false
}
local config = mwse.loadConfig("Damage Based Skill Progression", defaultConfig)
local affectedSkills = {}
affectedSkills[tes3.skill.bluntWeapon] = true
affectedSkills[tes3.skill.longBlade] = true
affectedSkills[tes3.skill.axe] = true
affectedSkills[tes3.skill.spear] = true
affectedSkills[tes3.skill.shortBlade] = true
affectedSkills[tes3.skill.marksman] = true

local blockNextExpGain = false --used to prevent gaining default on-hit experience, likely to be a source of conflicts
local previousHealth = 0 --used to calculate overkill

local function logger(message)
	if (config.logging) then tes3ui.logToConsole("DBSP: " .. message) end
end

local function getExpAwardedFor(damage, overkillDamage, skill)
	if (affectedSkills[skill]) then
		local hitExp = config.skillExpPerHit
		local expPerPointOfDamage = config.skillExpPerHealth
		logger("Dealt " .. damage .. " and " .. overkillDamage .. " overkill damage.")
		local overkillExpRatio = config.overkillExpPercentage / 100
		logger("OverkillExpRatio: " .. overkillExpRatio)
		local damageToAwardExpOver = damage + (overkillDamage * overkillExpRatio)
		logger("Effective damage to award exp over: " .. damageToAwardExpOver)
		if (config.enableSettingsPerSkill) then
			if (skill == tes3.skill.bluntWeapon) then 
				hitExp = config.skillExpPerHitBlunt
				expPerPointOfDamage = config.skillExpPerHealthBlunt
			elseif (skill == tes3.skill.longBlade) then 
				hitExp = config.skillExpPerHitLongBlade
				expPerPointOfDamage = config.skillExpPerHealthLongBlade
			elseif (skill == tes3.skill.axe) then 
				hitExp = config.skillExpPerHitAxe
				expPerPointOfDamage = config.skillExpPerHealthAxe
			elseif (skill == tes3.skill.spear) then 
				hitExp = config.skillExpPerHitSpear
				expPerPointOfDamage = config.skillExpPerHealthSpear
			elseif (skill == tes3.skill.shortBlade) then 
				hitExp = config.skillExpPerHitShortBlade
				expPerPointOfDamage = config.skillExpPerHealthShortBlade
			elseif (skill == tes3.skill.marksman) then 
				hitExp = config.skillExpPerHitMarksman 
				expPerPointOfDamage = config.skillExpPerHealthMarksman
			end
		end
		logger("Exp per point of damage: " .. expPerPointOfDamage)
		logger("hitExp: " .. hitExp)
		local damageExp = expPerPointOfDamage * damageToAwardExpOver
		logger("damageExp: " .. damageExp)
		logger("total exp: " .. (hitExp + damageExp))
		return hitExp + damageExp
	end
	return 0
end

local function beforeDamage(e)
	if (e.source ~= tes3.damageSource.attack) then return end
	previousHealth = e.mobile.health.current
end

local function onDamageDealt(e)
	if (not config.enableDBSP) then return end
	if (e.attackerReference ~= tes3.player or e.damage <= 0 or e.source ~= tes3.damageSource.attack) then
		return
	end
	
	local overkillDamageDealt = math.max(0, (previousHealth - e.damage) * -1)
	local nonOverkillDamageDealt = e.damage - overkillDamageDealt

	if (e.projectile ~= nil) then
		logger("Handing out exp due to projectile damage")
		tes3.mobilePlayer:exerciseSkill(tes3.skill.marksman, getExpAwardedFor(nonOverkillDamageDealt, overkillDamageDealt, tes3.skill.marksman))
		blockNextExpGain = true
		return
	end
	
	if (not e.attacker or not e.attacker.readiedWeapon or not e.attacker.readiedWeapon.object or not e.attacker.readiedWeapon.object.skillId) then
		return
	end
	
	local usedSkillId = e.attacker.readiedWeapon.object.skillId
	if (affectedSkills[usedSkillId]) then
		logger("Handing out exp due to weapon damage")
		tes3.mobilePlayer:exerciseSkill(usedSkillId, getExpAwardedFor(nonOverkillDamageDealt, overkillDamageDealt, usedSkillId))
		blockNextExpGain = true
	end
end

local function onSkillExpGain(e)
	if (not config.enableDBSP) then return end
	if (affectedSkills[e.skill]) then
		if (blockNextExpGain) then
			logger("Blocked " .. tes3.skillName[e.skill] .. " from gaining " .. e.progress .. " xp.")
			blockNextExpGain = false
			return false
		end
		logger("Allowed " .. tes3.skillName[e.skill] .. " to gain " .. e.progress .. " xp.")
	end
end

event.register("damage", beforeDamage)
event.register("damaged", onDamageDealt)
event.register("exerciseSkill", onSkillExpGain)

local function registerMCM()
	local template = mwse.mcm.createTemplate("Damage Based Skill Progression")
	template:saveOnClose("Damage Based Skill Progression", config)
	--template.headerImagePath = "MWSE/mods/Magicka Based Skill Progression/Magicka Based Skill Progression Logo.tga"

	local page = template:createSideBarPage()
	page.label = "General Settings"
	page.description = "Damage Based Skill Progression: MWSE-Lua Edition, "..version..", by Pimgd"

	local category = page:createCategory("General Settings")

	category:createYesNoButton({
		label = "Enable/Disable",
		description = "Toggle the functionality of the mod on and off.",
		variable = mwse.mcm:createTableVariable{id = "enableDBSP", table = config}
	})
	local skillExpPerHitField = category:createTextField()
	skillExpPerHitField.numbersOnly = true
	skillExpPerHitField.label = "Skill Experience per hit"
	skillExpPerHitField.description = "The amount of skill experience to give per hit. Successfully landing a blow in vanilla gives 1 skill XP. You can use this together with experience per point of damage. Starting weapons tend to deal between 1 to 5 damage on a quick strike. The default of 0.1 is intended to make early game progression not as punishing.\nHand to Hand is not affected."
	skillExpPerHitField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHit", table = config}
	
	local skillExpPerHealthField = category:createTextField()
	skillExpPerHealthField.numbersOnly = true
	skillExpPerHealthField.label = "Skill Experience per point of Health damage dealt"
	skillExpPerHealthField.description = "The amount of skill experience to give per point of health damage dealt. Successfully landing a blow in vanilla gives 1 skill XP. Starting weapons tend to deal between 1 to 5 damage on a quick strike. Default of 0.1 gives 1 skill XP per 10 damage dealt.\nHand to Hand is not affected."
	skillExpPerHealthField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHealth", table = config}
	
	category:createSlider{
		label = "Percentage of experience given for overkill damage dealt",
		description = "When you hit an enemy for more than their remaining health, the damage in excess of their health is 'Overkill Damage'.\nTo prevent awarding a lot of experience for flattening scribs with a Daedric Warhammer, you can adjust the experience gain that is awarded for overkill damage.\n\nFor example, if you get 0.1 experience per damage and overkill experience is set to 20%, and you hit a scrib (8 health) for 40 damage, you'd get\n0.1*(8 + (32*0.2)) = \n0.1*(8 + 6.4) = 1.44 experience instead of 4.",
		variable = mwse.mcm.createTableVariable{
			id = "overkillExpPercentage",
			table = config,
		},
		min = 0,
		max = 100,
		defaultSetting = 0,
	}

	category:createYesNoButton({
		label = "Logging",
		description = "Logs mod actions to the console, for debugging.",
		variable = mwse.mcm:createTableVariable{id = "logging", table = config}
	})
	
	local pageSkills = template:createSideBarPage()
	pageSkills.label = "Settings Per Skill"
	local settingsPerSkillCategory = pageSkills:createCategory("Settings per skill")
	settingsPerSkillCategory:createYesNoButton({
		label = "Enable/Disable settings per skill",
		description = "If you want to specify custom values per skill, you can do so here by enabling this option.",
		variable = mwse.mcm:createTableVariable{id = "enableSettingsPerSkill", table = config}
	})
		local bluntHitField = settingsPerSkillCategory:createTextField()
	bluntHitField.numbersOnly = true
	bluntHitField.label = "Blunt Weapon: Skill Experience per hit"
	bluntHitField.description = "The amount of skill experience to give per hit for Blunt Weapons."
	bluntHitField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHitBlunt", table = config}
	
	local bluntHealthField = settingsPerSkillCategory:createTextField()
	bluntHealthField.numbersOnly = true
	bluntHealthField.label = "Blunt Weapon: Skill Experience per point of Health damage dealt"
	bluntHealthField.description = "The amount of skill experience to give per point of health damage dealt for Blunt Weapons."
	bluntHealthField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHealthBlunt", table = config}
	
		local longBladeHitField = settingsPerSkillCategory:createTextField()
	longBladeHitField.numbersOnly = true
	longBladeHitField.label = "Long Blade: Skill Experience per hit"
	longBladeHitField.description = "The amount of skill experience to give per hit for Long Blades."
	longBladeHitField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHitLongBlade", table = config}
	
	local longBladeHealthField = settingsPerSkillCategory:createTextField()
	longBladeHealthField.numbersOnly = true
	longBladeHealthField.label = "Long Blade: Skill Experience per point of Health damage dealt"
	longBladeHealthField.description = "The amount of skill experience to give per point of health damage dealt for Long Blades."
	longBladeHealthField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHealthLongBlade", table = config}
	
		local axeHitField = settingsPerSkillCategory:createTextField()
	axeHitField.numbersOnly = true
	axeHitField.label = "Axe: Skill Experience per hit"
	axeHitField.description = "The amount of skill experience to give per hit for Axes."
	axeHitField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHitAxe", table = config}
	
	local axeHealthField = settingsPerSkillCategory:createTextField()
	axeHealthField.numbersOnly = true
	axeHealthField.label = "Axe: Skill Experience per point of Health damage dealt"
	axeHealthField.description = "The amount of skill experience to give per point of health damage dealt for Axes."
	axeHealthField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHealthAxe", table = config}
	
		local spearHitField = settingsPerSkillCategory:createTextField()
	spearHitField.numbersOnly = true
	spearHitField.label = "Spear: Skill Experience per hit"
	spearHitField.description = "The amount of skill experience to give per hit for Spears."
	spearHitField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHitSpear", table = config}
	
	local spearHealthField = settingsPerSkillCategory:createTextField()
	spearHealthField.numbersOnly = true
	spearHealthField.label = "Spear: Skill Experience per point of Health damage dealt"
	spearHealthField.description = "The amount of skill experience to give per point of health damage dealt for Spears."
	spearHealthField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHealthSpear", table = config}
	
		local shortBladeHitField = settingsPerSkillCategory:createTextField()
	shortBladeHitField.numbersOnly = true
	shortBladeHitField.label = "Short Blade: Skill Experience per hit"
	shortBladeHitField.description = "The amount of skill experience to give per hit for Short Blades."
	shortBladeHitField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHitShortBlade", table = config}
	
	local shortBladeHealthField = settingsPerSkillCategory:createTextField()
	shortBladeHealthField.numbersOnly = true
	shortBladeHealthField.label = "Short Blade: Skill Experience per point of Health damage dealt"
	shortBladeHealthField.description = "The amount of skill experience to give per point of health damage dealt for Short Blades."
	shortBladeHealthField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHealthShortBlade", table = config}
	
		local marksmanHitField = settingsPerSkillCategory:createTextField()
	marksmanHitField.numbersOnly = true
	marksmanHitField.label = "Marksman: Skill Experience per hit"
	marksmanHitField.description = "The amount of skill experience to give per hit for Ranged Weapons."
	marksmanHitField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHitMarksman", table = config}
	
	local marksmanHealthField = settingsPerSkillCategory:createTextField()
	marksmanHealthField.numbersOnly = true
	marksmanHealthField.label = "Marksman: Skill Experience per point of Health damage dealt"
	marksmanHealthField.description = "The amount of skill experience to give per point of health damage dealt for Ranged Weapons."
	marksmanHealthField.variable = mwse.mcm:createTableVariable{id = "skillExpPerHealthMarksman", table = config}
	

	mwse.mcm.register(template)
end

event.register("modConfigReady", registerMCM)