---@diagnostic disable: need-check-nil, undefined-field
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

local function getDialogActorRef()
	local MenuDialog = tes3ui.findMenu("MenuDialog")
	if MenuDialog then
		local mobile = MenuDialog:getPropertyObject("PartHyperText_actor")
		if mobile then
			---assert(mobile.reference)
			return mobile.reference
		end
	end
end

--[[local function getDialogActorOrPlayerRef()
	return getDialogActorRef() or tes3.player
end]]

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
	["<[bB][rR]>"] = "\n",
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


local substitutions = {}
local sk = {}

function speech.setSubstitution(pattern, replacement)
	if not substitutions[pattern] then
		substitutions[pattern] = replacement
		table.insert(sk, pattern)
	end
end

function speech.sortSubstitutions()
	table.sort(sk)
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

function speech.getFiltered(text, logLevel)
	if logLevel
	and (logLevel >= 5) then
		mwselog(text)
	end
	local line = text
	local oldLine = line
	
	-- these always first
	for pattern, replacement in pairs(substitutions0) do
		oldLine = line
		line = string.gsub(oldLine, pattern, replacement)
		if logLevel
		and (logLevel >= 4) then
			mwselog('line = string.gsub("%s", "%s", "%s")', oldLine, pattern, replacement)
			if (logLevel >= 5)
			or (not (line == oldLine)) then
				mwselog("line:\n%s\npattern = %s\nreplacement = %s", line, pattern, replacement)
			end
		end
	end

	-- ensure these are done after other %% replacements
	for i = 1, #sk do -- sk is sorted once in loaded()
		local pattern = sk[i]
		local replacement = substitutions[pattern]
		oldLine = line
		line = string.gsub(oldLine, pattern, replacement)
		if logLevel
		and (logLevel >= 4) then
			mwselog('line = string.gsub("%s", "%s", "%s")', oldLine, pattern, replacement)
			if (logLevel >= 5)
			or (not (line == oldLine)) then
				mwselog("line:\n%s\npattern = %s\nreplacement = %s", line, pattern, replacement)
			end
		end
	end

	local ptrn = "[%^%%]([%w_]+)"
	oldLine = line
	line = string.gsub(oldLine, ptrn, expandGlobalVar)
	if logLevel
	and (logLevel >= 4) then
		if (logLevel >= 5)
		or (not (line == oldLine)) then
			mwselog("oldLine:\n%s\npattern = %s\nline:\n%s", oldLine, ptrn, line)
		end
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
	--[[if logLevel
		and (logLevel >= 5) then
			mwselog(text)
		end
	end]]
	local line = speech.getFiltered(text, logLevel) -- Apply filtering
	if not line then
		return
	end
	if string.len(line) <= 0 then
		return
	end

	-- Append speech data.
	line = speech.getSAPIXML(params.tokensRequired or speech.tokensRequired, params.pitch or speech.pitch,
		params.volume or speech.volume, params.speed or speech.speed) .. line

	if logLevel
	and (logLevel >= 4) then
		mwselog(line)
	end
	if line then
		lastSpokenText = text
		comInterface:Speak(line, SAPI.SpeechVoiceSpeakFlags.SVSFlagsAsync)
	end
end

function speech.isSpeaking()
	if not comInterface then
		return
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

event.register('loaded',
function ()
	sk = {}
	local i = 0
	for pattern, _ in pairs(substitutions) do
		i = i + 1
		sk[i] = pattern
	end
	table.sort(sk)
	--[[
	for _, pattern in ipairs(sk) do
		local replacement = substitutions[pattern]
		mwse.log("SPEECH pattern = %s, replacement = %s" , pattern, replacement)
	end]]
end, {doOnce = true})

return speech
