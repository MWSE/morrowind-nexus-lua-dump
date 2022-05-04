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
end

local function onInitialized()

	event.register("exerciseSkill", skillExercised)
	mwse.log("Adjustable Skill Progression Initialized")
end

event.register("initialized", onInitialized)