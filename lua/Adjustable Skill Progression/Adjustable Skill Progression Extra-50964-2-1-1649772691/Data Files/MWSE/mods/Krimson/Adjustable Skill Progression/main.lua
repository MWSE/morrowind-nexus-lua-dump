local config

event.register("modConfigReady", function()

    require("Krimson.Adjustable Skill Progression.mcm")
	config  = require("Krimson.Adjustable Skill Progression.config")
end)

local function skillExercised(e)

	local usedSkill = tes3.mobilePlayer:getSkillStatistic(e.skill)
    local majorSkills = tes3.skillType.major
    local minorSkills = tes3.skillType.minor
    local miscSkills = tes3.skillType.misc

	if config.classMod then
		if usedSkill.type == majorSkills then
			e.progress = e.progress * config.majorMod * 0.1
		elseif usedSkill.type == minorSkills then
			e.progress = e.progress * config.minorMod * 0.1
		elseif usedSkill.type == miscSkills then
			e.progress = e.progress * config.miscMod * 0.1
		end
	end

	if config.indvMod then
		if e.skill == tes3.skill.acrobatics then
			e.progress = e.progress * config.acrobaticsMod * 0.1
		end

		if e.skill == tes3.skill.alchemy then
			e.progress = e.progress * config.alchemyMod * 0.1
		end

		if e.skill == tes3.skill.alteration then
			e.progress = e.progress * config.alterationMod * 0.1
		end

		if e.skill == tes3.skill.armorer then
			e.progress = e.progress * config.armorerMod * 0.1
		end

		if e.skill == tes3.skill.athletics then
			e.progress = e.progress * config.athleticsMod * 0.1
		end

		if e.skill == tes3.skill.axe then
			e.progress = e.progress * config.axeMod * 0.1
		end

		if e.skill == tes3.skill.block then
			e.progress = e.progress * config.blockMod * 0.1
		end

		if e.skill == tes3.skill.bluntWeapon then
			e.progress = e.progress * config.bluntMod * 0.1
		end

		if e.skill == tes3.skill.conjuration then
			e.progress = e.progress * config.conjurationMod * 0.1
		end

		if e.skill == tes3.skill.destruction then
			e.progress = e.progress * config.destructionMod * 0.1
		end

		if e.skill == tes3.skill.enchant then
			e.progress = e.progress * config.enchantMod * 0.1
		end

		if e.skill == tes3.skill.handToHand then
			e.progress = e.progress * config.handMod * 0.1
		end

		if e.skill == tes3.skill.heavyArmor then
			e.progress = e.progress * config.heavyMod * 0.1
		end

		if e.skill == tes3.skill.illusion then
			e.progress = e.progress * config.illusionMod * 0.1
		end

		if e.skill == tes3.skill.lightArmor then
			e.progress = e.progress * config.lightMod * 0.1
		end

		if e.skill == tes3.skill.longBlade then
			e.progress = e.progress * config.longMod * 0.1
		end

		if e.skill == tes3.skill.marksman then
			e.progress = e.progress * config.marksmanMod * 0.1
		end

		if e.skill == tes3.skill.mediumArmor then
			e.progress = e.progress * config.mediumMod * 0.1
		end

		if e.skill == tes3.skill.mercantile then
			e.progress = e.progress * config.mercantileMod * 0.1
		end

		if e.skill == tes3.skill.mysticism then
			e.progress = e.progress * config.mysticismMod * 0.1
		end

		if e.skill == tes3.skill.restoration then
			e.progress = e.progress * config.restorationMod * 0.1
		end

		if e.skill == tes3.skill.security then
			e.progress = e.progress * config.securityMod * 0.1
		end

		if e.skill == tes3.skill.shortBlade then
			e.progress = e.progress * config.shortMod * 0.1
		end

		if e.skill == tes3.skill.sneak then
			e.progress = e.progress * config.sneakMod * 0.1
		end

		if e.skill == tes3.skill.spear then
			e.progress = e.progress * config.spearMod * 0.1
		end

		if e.skill == tes3.skill.speechcraft then
			e.progress = e.progress * config.speechcraftMod * 0.1
		end

		if e.skill == tes3.skill.unarmored then
			e.progress = e.progress * config.unarmoredMod * 0.1
		end
	end

	if config.levelMod then
		if usedSkill.base <= 25 then
			e.progress = e.progress * config.levelMod25 * 0.1
		elseif usedSkill.base <= 50 then
			e.progress = e.progress * config.levelMod50 * 0.1
		elseif usedSkill.base <= 75 then
			e.progress = e.progress * config.levelMod75 * 0.1
		elseif usedSkill.base > 75 then
			e.progress = e.progress * config.levelMod100 * 0.1
		end
	end

	if config.indLevelMod then
		if e.skill == tes3.skill.acrobatics then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.acrobaticsLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.acrobaticsLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.acrobaticsLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.acrobaticsLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.alchemy then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.alchemyLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.alchemyLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.alchemyLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.alchemyLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.alteration then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.alterationLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.alterationLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.alterationLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.alterationLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.armorer then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.armorerLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.armorerLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.armorerLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.armorerLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.athletics then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.athleticsLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.athleticsLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.athleticsLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.athleticsLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.axe then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.axeLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.axeLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.axeLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.axeLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.block then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.blockLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.blockLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.blockLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.blockLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.bluntWeapon then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.bluntLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.bluntLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.bluntLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.bluntLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.conjuration then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.conjurationLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.conjurationLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.conjurationLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.conjurationLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.destruction then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.destructionLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.destructionLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.destructionLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.destructionLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.enchant then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.enchantLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.enchantLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.enchantLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.enchantLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.handToHand then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.handLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.handLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.handLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.handLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.heavyArmor then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.heavyLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.heavyLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.heavyLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.heavyLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.illusion then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.illusionLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.illusionLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.illusionLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.illusionLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.lightArmor then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.lightLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.lightLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.lightLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.lightLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.longBlade then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.longLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.longLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.longLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.longLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.marksman then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.marksmanLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.marksmanLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.marksmanLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.marksmanLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.mediumArmor then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.mediumLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.mediumLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.mediumLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.mediumLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.mercantile then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.mercantileLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.mercantileLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.mercantileLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.mercantileLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.mysticism then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.mysticismLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.mysticismLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.mysticismLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.mysticismLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.restoration then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.restorationLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.restorationLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.restorationLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.restorationLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.security then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.securityLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.securityLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.securityLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.securityLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.shortBlade then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.shortLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.shortLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.shortLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.shortLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.sneak then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.sneakLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.sneakLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.sneakLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.sneakLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.spear then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.spearLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.spearLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.spearLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.spearLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.speechcraft then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.speechcraftLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.speechcraftLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.speechcraftLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.speechcraftLevelMod100 * 0.1
			end
		end

		if e.skill == tes3.skill.unarmored then
			if usedSkill.base <= 25 then
				e.progress = e.progress * config.unarmoredLevelMod25 * 0.1
			elseif usedSkill.base <= 50 then
				e.progress = e.progress * config.unarmoredLevelMod50 * 0.1
			elseif usedSkill.base <= 75 then
				e.progress = e.progress * config.unarmoredLevelMod75 * 0.1
			elseif usedSkill.base > 75 then
				e.progress = e.progress * config.unarmoredLevelMod100 * 0.1
			end
		end
	end
end

local function onInitialized()

	event.register("exerciseSkill", skillExercised)
	mwse.log("Adjustable Skill Progression Initialized")
end

event.register("initialized", onInitialized)