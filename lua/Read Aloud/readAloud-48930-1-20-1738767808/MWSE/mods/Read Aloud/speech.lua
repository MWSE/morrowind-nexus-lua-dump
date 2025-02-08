---@diagnostic disable: need-check-nil, undefined-field, undefined-global
-- code mostly from a old version of NullCascade's speech API
-- I'm unable to use the new dll version at the moment /abot

local speech = {}

-- We need LuaCOM, which is a naughty old module that doesn't return anything.
require("luacom")
---@diagnostic disable-next-line: undefined-field
local luacom = _G.luacom
local luaComObjId = "SAPI.SpVoice"

-- Instantiate a SAPI voice object
local comInterface = luacom.GetObject(luaComObjId)
if comInterface then
	comInterface:Quit()
end
comInterface = luacom.CreateObject(luaComObjId)

if (comInterface and comInterface:GetVoices().Count == 0) then
	comInterface = nil
end

local SAPI = nil
if (comInterface) then
	SAPI = luacom.GetTypeInfo(comInterface):GetTypeLib():ExportEnumerations()
end

function speech.getVoices()
	local t = {}
	local i = 0
	local enumerate_voices = luacom.GetEnumerator(comInterface:GetVoices())
	local voice = enumerate_voices:Next()
	while voice do
		i = i + 1
		t[i] = voice:GetDescription()
		voice = enumerate_voices:Next()
	end
	return t
end

function speech.setVoiceByIndex(i)
	comInterface:setVoice(comInterface:GetVoices():Item(i - 1))
end

-- Allow a mute flag.
speech.muted = false

-- Configure the voice.
speech.pitch = 2
speech.speed = -1
speech.tokensRequired = "Gender=Female;Age!=Child;Language=409"
speech.volume = 50

--[[
-- replaced with more recent tes3.applyTextDefines()

local function getDialogActorRef()
	local MenuDialog = tes3ui.findMenu("MenuDialog")
	if MenuDialog then
		local mobile = MenuDialog:getPropertyObject("PartHyperText_actor")
		if mobile then
			---assert(mobile.reference)
			return mobile.reference
		end
	end
end]]

--[[local function getDialogActorOrPlayerRef()
	return getDialogActorRef() or tes3.player
end]]


--[[
local function getClass()
	local ref = getDialogActorRef()
	if not ref then
		return ''
	end
	local class = ref.object.class
	if class then
		if class.name then
			return class.name
		end
	end
	return ''
end

local function getName()
	local ref = getDialogActorRef()
	if not ref then
		return ''
	end
	local name = ref.object.name
	if name then
		return name
	end
	return ''
end

local function getRace()
	local ref = getDialogActorRef()
	if not ref then
		return ''
	end
	local race = ref.object.race
	if race then
		return race.name
	end
	return ''
end

local function getTes3Faction(ref)
	if not ref then
		return
	end
	local obj = ref.object
	if obj then
		if obj.faction then
			return obj.faction
		end
	end
	local baseObj = ref.baseObject
	if baseObj then
		if baseObj.faction then
			return baseObj.faction
		end
	end
	return
end

local function getFaction()
	local ref = getDialogActorRef()
	if not ref then
		return ''
	end
	local faction = getTes3Faction(ref)
	if faction then
		if faction.name then
			return faction.name
		end
	end
	return ''
end

local function getNextPCRank()
	local ref = getDialogActorRef()
	if not ref then
		return ''
	end
	local faction = getTes3Faction(ref)
	if faction then
		local nextRank = faction.playerRank
		if nextRank < 9 then
			nextRank = nextRank + 1
		end
		return faction:getRankName(nextRank)
	end
	return ''
end

local function getPCRank()
	local ref = getDialogActorRef()
	if not ref then
		return ''
	end
	local faction = getTes3Faction(ref)
	if faction then
		return faction:getRankName(faction.playerRank)
	end
	return ''
end

local function getRank()
	local ref = getDialogActorRef()
	if not ref then
		return ''
	end
	local faction = getTes3Faction(ref)
	if not faction then
		return ''
	end
	local factionRank
	local obj = ref.object
	if obj then
		factionRank = obj.factionRank
		if not factionRank then
			local baseObj = ref.baseObject
			if baseObj then
				factionRank = baseObj.factionRank -- fix for Gothren and maybe others? /abot
			end
		end
	end
	if factionRank then
		return faction:getRankName(factionRank)
	end
	return ''
end

local substitutions0 = {
	["[%%%^][cC][lL][aA][sS][sS]"] = getClass,

	["([%%%^][nN][aA][mM][eE])"] = getName, -- starting ( mostly to sort and explode %Name as soon as possible

	["[%%%^][pP][cC][cC][lL][aA][sS][sS]"] = function()	return tes3.player.object.class.name end,
	["[%%%^][pP][cC][nN][aA][mM][eE]"] = function() return tes3.player.object.name end,
	["[%%%^][pP][cC][rR][aA][cC][eE]"] = function() return tes3.player.object.race.name end,
	["[%%%^][rR][aA][cC][eE]"] = getRace,
	["[%%%^][cC][eE][lL][lL]"] = function() return tes3.player.cell.name end,
	["[%%%^][fF][aA][cC][tT][iI][oO][nN]"] = getFaction,
	["[%%%^][nN][eE][xX][tT][pP][cC][rR][aA][nN][kK]"] = getNextPCRank,
	["[%%%^][pP][cC][rR][aA][nN][kK]"] = getPCRank,
	["[%%%^][rR][aA][nN][kK]"] = getRank,

	["[@#]"] = "", -- Remove any other special symbols.

}
]]

local substitutions = {}
local sk = {}

function speech.setSubstitution(pattern, replacement)
	if not substitutions[pattern] then
		substitutions[pattern] = replacement
		table.insert(sk, pattern)
	end
end

function speech.getSAPIXML(tokensRequired, pitch, volume, speed)
	return string.format("<voice required=\"%s\" /><pitch absmiddle=\"%d\" /><volume level=\"%d\" /><rate speed=\"%d\" />",
		tokensRequired, pitch, volume, speed)
end

-- workaround
local function mwselog(str, ...)
	if select('#', ...) > 0 then
		print(tostring(str):format(...))
	else
		print(tostring(str))
	end
end

local function expandGlobalVar(globalVarId)
	if globalVarId then
		local g = tes3.findGlobal(globalVarId)
		if g then
			return tostring(g.value)
		end
	end
	return globalVarId
end

local function stripTags(s)
	return s:gsub('[@#]', '')
end

---local function replacePercent(s)
	---return s:gsub('%%', '%^'):gsub('%^%^', '%^')
---end

local function stripTagsAndApplyTextDefines(s, actorObj)
	local s2 = stripTags(s)
	if actorObj then
		s2 = tes3.applyTextDefines({text = s2, actor = actorObj})
	end
	return s2
end

local function textDefines(s)
	local actorObj
	local mob = tes3ui.getServiceActor()
	if mob then
		actorObj = mob.reference.object
	end
	return stripTagsAndApplyTextDefines(s, actorObj)
end

function speech.getFiltered(text, logLevel)
	local logLevel4 = logLevel and (logLevel >= 4)
	local logLevel5 = logLevel and (logLevel >= 5)
	if logLevel5 then
		mwselog(text)
	end
	local line = textDefines(text)
	
	-- these always first
	
	--[[
	for pattern, replacement in pairs(substitutions0) do
		local oldLine = line
		line = string.gsub(line, pattern, replacement)
		if logLevel
		and (logLevel >= 4) then
			mwselog('line = string.gsub("%s", "%s", "%s")', oldLine, pattern, replacement)
			if (logLevel >= 5)
			or (not (line == oldLine)) then
				mwselog("newline:\n%s\npattern = %s\nreplacement = %s", line, pattern, replacement)
			end
		end
	end
	
	]]
	
	for i = 1, #sk do
		local pattern = sk[i] -- respect patterns definition order
		local replacement = substitutions[pattern]
		local oldLine = line
		line = string.gsub(line, pattern, replacement)
		if logLevel4
		and (not (line == oldLine)) then
			mwselog('line = string.gsub("%s", "%s", "%s")', oldLine, pattern, replacement)
			if logLevel5 then
				mwselog("newline:\n%s\npattern = %s\nreplacement = %s", line, pattern, replacement)
			end
		end
	end

	local ptrn = "[%^%%]([%w_]+)"
	local oldLine = line
	line = string.gsub(line, ptrn, expandGlobalVar)
	if logLevel5
	and ( not (line == oldLine) ) then
		mwselog("oldLine:\n%s\npattern = %s\newline:\n%s", oldLine, ptrn, line)
	end
	return line
end

local lastSpokenText
-- useful e.g. to calculate talking delay /abot
function speech.getLastSpokenText()
	return lastSpokenText
end

function speech.speak(text, params, logLevel)
	if not comInterface then
		return
	end
	if speech.muted then
		return
	end
	local logLevel1 = logLevel and (logLevel >= 1)
	--[[local logLevel5 = logLevel and (logLevel >= 5)
	if logLeve5 then
		mwselog(text)
	end]]
	local oldText = text
	local line = speech.getFiltered(text, logLevel) -- Apply filtering
	if logLevel1 then
		if not ( string.len(text) == string.len(oldText) ) then
			mwselog('oldText =\n%s\ntext =\n%s', oldText, text)
		end
	end
	if not line then
		return
	end
	if string.len(line) <= 0 then
		return
	end

	-- Append speech data.
	line = speech.getSAPIXML(params.tokensRequired or speech.tokensRequired, params.pitch or speech.pitch,
		params.volume or speech.volume, params.speed or speech.speed) .. line

	local logLevel4 = logLevel and (logLevel >= 4)
	if logLevel4 then
		mwselog(line)
	end
	if line then
		lastSpokenText = text
	end
	local success = pcall(
		function ()
			comInterface:Speak(line, SAPI.SpeechVoiceSpeakFlags.SVSFlagsAsync)
		end
	)
	if logLevel1
	and (not success)
	and ( not tes3.menuMode() ) then
		tes3.messageBox('Read Aloud: WARNING! speech unavailable probably due to Low Memory condition')
	end
end

function speech.isSpeaking()
	if not comInterface then
		return false
	end
	return comInterface.Status.RunningState == SAPI.SpeechRunState.SRSEIsSpeaking
end

function speech.stop()
	if not comInterface then
		return
	end
	if (comInterface.Status.RunningState == SAPI.SpeechRunState.SRSEIsSpeaking) then
		comInterface:Speak(' ', SAPI.SpeechVoiceSpeakFlags.SVSFPurgeBeforeSpeak)
	end
end

function speech.skip(sType, count)
	if not comInterface then
		return
	end
	comInterface:Skip(sType or "Sentence", count or 1)
end

return speech
