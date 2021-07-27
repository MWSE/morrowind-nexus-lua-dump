-- show Water Life Fishing skill
-- bah, syncing this shit is harder than it seems, no easy to use get/set

local author = 'abot'
local modName = 'Water Life Fishing Skill View'
local modPrefix = author .. '/'.. modName

local skillModule = include("OtherSkills.skillModule")

if not skillModule then
	mwse.log("%s: Warning: OtherSkills.skillModule not found, Water Life Fishing Skill View disabled.", modPrefix)
end

local fishingSkillId = "ab01wlFishing"
local fishingSkillCap = 100
local fishingGlobalVarId = 'fishskill'

local fishingSkillRef -- set in onSkillReady()

local dbug = false

local function fishingSkillProcess()
	if not fishingSkillRef then
		assert(fishingSkillRef)
		return
	end
	local value = fishingSkillRef.value
	if not value then
		assert(value)
		return
	end
	local progress = fishingSkillRef.progress
	if not progress then
		assert(progress)
		return
	end
	local globValue = tes3.getGlobal(fishingGlobalVarId)
	if not globValue then
		assert(globValue)
		return
	end
	globValue = math.round(globValue, 2)
	local totValue = math.round(value + (progress / 100), 2)
	local m = math.max(globValue, totValue)
	if m > fishingSkillCap then
		tes3.setGlobal(fishingGlobalVarId, fishingSkillCap)
		return
	end
	local diff = globValue - totValue
	if diff <= 0 then
		return
	end
	diff = math.round(diff, 2)
	local int, frac = math.modf(diff)
	if int >= 1 then
		if dbug then
			mwse.log("%s fishingSkillRef:levelUpSkill(%s)", modPrefix, int)
		end
		fishingSkillRef:levelUpSkill(int)
	end
	if frac > 0 then
		frac = frac * 100
		if dbug then
			mwse.log("%s fishingSkillRef:progressSkill(%s)", modPrefix, frac)
		end
		fishingSkillRef:progressSkill(frac)
	end
	globValue = fishingSkillRef.value + (fishingSkillRef.progress / 100)
	globValue = math.round(globValue, 2)
	if dbug then
		mwse.log("%s tes3.setGlobal('%s', %s)", modPrefix, fishingGlobalVarId, globValue)
	end
	tes3.setGlobal(fishingGlobalVarId, globValue)
end

local function onSkillReady()
	--- mwse.log("%s onSkillReady()", modPrefix) -- runs on reload
	skillModule.registerSkill(
		fishingSkillId,
		{
		name = "Fishing",
		value =	tes3.getGlobal(fishingGlobalVarId), --default: 5
		---progress = 0, --default: 0
		lvlCap = fishingSkillCap, -- default: 100
		icon = "Icons/abot/wlFishing.dds", --default: a circle icon
		---attribute = tes3.attribute.luck, --optional
		description	= "Determines your effectiveness at Fishing.", --optional
		---specialization = tes3.specialization.stealth, --optional. Icon background is gray if none set
		active = 'active'
		}
	)
	fishingSkillRef = skillModule.getSkill(fishingSkillId)
	if fishingSkillRef then
		timer.start({duration = (math.random() * 0.1) + 0.95, callback = fishingSkillProcess, iterations = -1})
	else
		assert(fishingSkillRef)
	end
end

local function initialized()
	if not skillModule then
		return
	end
	local skillValue = tes3.getGlobal(fishingGlobalVarId)
	if skillValue then -- note: 0 is true in Lua
		local ab01wlgOnLoadScript = tes3.getScript('ab01wlgOnLoadScript')
		if ab01wlgOnLoadScript then
			event.register('OtherSkills:Ready', onSkillReady)
			---mwse.log("fishskill = %s, ab01wlgOnLoadScript = %s", skillValue, ab01wlgOnLoadScript)
			return
		end
	end
	mwse.log("%s: Warning: Water Life mod not detected, Water Life Fishing Skill View disabled.", modPrefix)
end
event.register('initialized', initialized)
