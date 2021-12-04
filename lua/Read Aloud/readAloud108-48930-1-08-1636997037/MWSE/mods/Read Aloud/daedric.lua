local modPrefix = 'Read Aloud'
local cmn = require(modPrefix .. '.common')
local SAPIwind = require(modPrefix .. '.speech')

local config = cmn.config

local skillModule = include('OtherSkills.skillModule')

if not skillModule then
	config.daedricSkill = false
	mwse.log("%s: Warning: OtherSkills.skillModule not found, Daedric Skill disabled.", modPrefix)
end

local daedricSkillId = 'ab01daedric'
local daedricSkillCap = 100

local function getDaedricSkillActive()
	if config.daedricSkill then
		return 'active'
	else
		return 'inactive'
	end
end

local knownDaedricLetters = {}

-- daedric skill/translation

local daedricSkillRef -- set in onSkillReady()

local function initDaedricSkillRef()
-- each call to getSkill(daedricSkillId) returns a new object/address
	if skillModule then
		daedricSkillRef = skillModule.getSkill(daedricSkillId)
	else
		daedricSkillRef = nil
	end
end

local function getDaedricSkillValue()
	if daedricSkillRef then
		return daedricSkillRef.value
	else
		return 1
	end
end

local function progressDaedricSkill(valueToAdd)
	if daedricSkillRef then
		---mwse.log("daedricSkillRef:progressSkill(%s)", valueToAdd)
		daedricSkillRef:progressSkill(valueToAdd)
	end
end

local function levelUpDaedricSkill()
	if daedricSkillRef then
		---mwse.log("daedricSkillRef:levelUpSkill()")
		daedricSkillRef:levelUpSkill()
	end
end

local function onSkillReady()
	skillModule.registerSkill(
		daedricSkillId,
		{
		name = 'Daedric',
		value =	5, --default: 5
		progress = 0, --default: 0
		lvlCap = daedricSkillCap, -- default: 100
		icon = "Icons/abot/daedric.dds", --default: a circle icon
		attribute = tes3.attribute.intelligence, --optional
		description	= "Determines your effectiveness at reading Daedric text in enchanted scrolls.", --optional
		specialization = tes3.specialization.magic, --optional. Icon background is gray if none set
		active = getDaedricSkillActive(),
		}
	)
	initDaedricSkillRef()
end

if skillModule then
	event.register('OtherSkills:Ready', onSkillReady)
end

-- weird language making sorting difficult
local function pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a, f) -- note: not conservative sort
	local i = 0 -- iterator variable
	local iter = function() -- iterator function
		i = i + 1
		local ai = a[i]
		if ai == nil then
			return nil
		else
			return ai, t[ai]
		end
	end
	return iter
end

local function letters2string()
	local s = ''
	if knownDaedricLetters then
		if #knownDaedricLetters > 0 then
			for _, v in pairsByKeys(knownDaedricLetters) do
				s = s .. v
			end
		end
	end
	return s
end

local function daedricSkillProcess(inStr)
	---mwse.log("daedricSkillProcess(%s)", inStr)
	local knownCount = 26
	local strlen = string.len(inStr)
	local count = 0
	local skill = getDaedricSkillValue()
	local outStr = inStr
	if skill < daedricSkillCap then
		local maxRand = 2 * (daedricSkillCap - 1)
		knownCount = #knownDaedricLetters
		local c
		local lc
		outStr = ''
		for i = 1, strlen do
			c = string.sub(inStr, i, i)
			lc = string.lower(c)
			if knownDaedricLetters[lc] then
				outStr = outStr .. c
				count = count + 1
			elseif string.find(c, "[%s%p]") then
				outStr = outStr .. c
			elseif skill > math.random(0, maxRand) then
				outStr = outStr .. c
				count = count + 1
				if knownCount < 26 then
					knownCount = knownCount + 1
				end
				knownDaedricLetters[lc] = 1
			else
				outStr = outStr .. ' '
			end
		end
	end

	local newSkill = math.floor((daedricSkillCap * knownCount / 26 ) + 0.5)
	local skillInc = newSkill - skill
	if config.logLevel > 2 then
		local l2s = letters2string()
		mwse.log("%s: read Daedric:\noutStr = %s, knownDaedricLetters = %s, knownCount = %s, skill = %s, newSkill = %s, skillInc = %s"
		, modPrefix, outStr, l2s, knownCount, skill, newSkill, skillInc)
	end
	if skillInc > 0 then
		levelUpDaedricSkill()
		--[[
		skillInc = skillInc - 1
		if skillInc > 0 then
			mwse.log("timer.start({type = timer.real, duration = 5, callback = levelUpDaedricSkill, iterations = %s})", skillInc)
			timer.start({type = timer.real, duration = 5, callback = levelUpDaedricSkill, iterations = skillInc})
		end
		--]]
	else
		progressDaedricSkill(2*count)
	end
	return outStr
end

local function getDaedricTranslation(inStr)
	---mwse.log("getDaedricTranslation(inStr) config.daedricSkill = %s, daedricSkillRef = %s", config.daedricSkill, daedricSkillRef)
	local outStr = SAPIwind.getFiltered(inStr)
	if config.daedricSkill and daedricSkillRef then
		outStr = daedricSkillProcess(outStr)
	end
	local l = string.len(outStr)
	if l > 0 then
		if config.daedricTranslation then
			local maxChars = 200
			local s
			 -- usually 100 characters = 10 sec message, can be annoying
			if l > maxChars then
				s = string.sub(outStr, 1, maxChars) .. '...'
			else
				s = outStr
			end
			tes3.messageBox(s)
		end
		---mwse.log("read daedric: outStr =\n%s", outStr)
	end
	if config.readDaedricTranslation then
		return outStr
	else
		return ''
	end
end

local this = {}
this.knownDaedricLetters = knownDaedricLetters

function this.getDaedricReplace(inStr)
	local s = inStr
	if s then
		s = getDaedricTranslation(inStr)
-- important to get translation lowercase else 2 letters words will be spelled
		s = string.lower(s)
		if config.logLevel >= 2 then
			mwse.log("%s: getDaedricReplace(%s) --> %s", modPrefix, inStr, s)
		end
	end
	return s
end

return this