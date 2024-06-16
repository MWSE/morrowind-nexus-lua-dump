-- Adds Gardening Skill to Character Menu

local author = 'Triballu'
local modName = 'Gardening Skill Addon'
local modPrefix = author .. '/'.. modName

local skillModule = include("OtherSkills.skillModule")

if not skillModule then
	mwse.log("%s: Warning: OtherSkills.skillModule not found, Gardner Skill View disabled.", modPrefix)
end

local gardnerSkillId = "tribgardner"
local gardnerSkillCap = 100.1
local gardnerGlobalVarId = 'tribGardner'

local gardnerSkillRef -- set in onSkillReady()

local dbug = false

local function gardnerSkillProcess()
	if not gardnerSkillRef then
		assert(gardnerSkillRef)
		return
	end
	local value = gardnerSkillRef.value
	if not value then
		assert(value)
		return
	end
	local progress = gardnerSkillRef.progress
	if not progress then
		assert(progress)
		return
	end
	local globValue = tes3.getGlobal(gardnerGlobalVarId)
	if not globValue then
		assert(globValue)
		return
	end
	globValue = math.round(globValue, 2)
	local totValue = math.round(value + (progress / 100), 2)
	local m = math.max(globValue, totValue)
	if m > gardnerSkillCap then
		tes3.setGlobal(gardnerGlobalVarId, gardnerSkillCap)
		return
	end
	local diff = globValue - totValue
	if diff == 0 then
		return
	end
	diff = math.round(diff, 2)
	local int, frac = math.modf(diff)
	if not (int == 0) then
		if dbug then
			mwse.log("%s gardnerSkillRef:levelUpSkill(%s)", modPrefix, int)
		end
		gardnerSkillRef:levelUpSkill(int)
	end
	if not (frac == 0) then
		frac = frac * 100
		if dbug then
			mwse.log("%s gardnerSkillRef:progressSkill(%s)", modPrefix, frac)
		end
		gardnerSkillRef:progressSkill(frac)
	end
	globValue = gardnerSkillRef.value + (gardnerSkillRef.progress / 100)
	globValue = math.round(globValue, 2)
	if dbug then
		mwse.log("%s tes3.setGlobal('%s', %s)", modPrefix, gardnerGlobalVarId, globValue)
	end
	tes3.setGlobal(gardnerGlobalVarId, globValue)
end

local function onSkillReady()
	skillModule.registerSkill(
		gardnerSkillId,
		{
		name = "Gardening",
		value =	tes3.getGlobal(gardnerGlobalVarId),
		lvlCap = gardnerSkillCap,
		icon = "Icons/gardner/gardnerskill.dds",
		attribute = tes3.attribute.intelligence,
		description = "Gardening is a very useful skill to have. It allows you to use seeds to plant your own crops to harvest and gather materials from. The higher your skill will yield better results.",
		specialization = tes3.specialization.magic,
		active = 'active'
		}
	)
	gardnerSkillRef = skillModule.getSkill(gardnerSkillId)
	if gardnerSkillRef then
		timer.start({duration = (math.random() * 0.1) + 0.95, callback = gardnerSkillProcess, iterations = -1})
	else
		assert(gardnerSkillRef)
	end
end

local function initialized()
	if not skillModule then
		return
	end
	local skillValue = tes3.getGlobal(gardnerGlobalVarId)
	if skillValue then -- note: 0 is true in Lua
			event.register('OtherSkills:Ready', onSkillReady)
			return
	end
	mwse.log("%s: Warning: Gardner mod not detected, Gardner Skill View disabled.", modPrefix)
end
event.register('initialized', initialized)
