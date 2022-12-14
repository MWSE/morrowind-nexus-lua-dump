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

-- Allow a mute flag.
speech.muted = false

-- Configure the voice.
speech.pitch = 2
speech.speed = -1
speech.tokensRequired = "Gender=Female;Age!=Child;Language=409"
speech.volume = 50

-- hopefully fixed these things to return a more useful/valid reference, not a mobile without a documented mobile.object /abot
local function getDialogActorRef()
	local MenuDialog = tes3ui.findMenu("MenuDialog")
	if MenuDialog then
		local mobile = MenuDialog:getPropertyObject("PartHyperText_actor")
		if mobile then
			---assert(mobile.reference)
			return mobile.reference
		end
	end
	return nil
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
		return nil
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
	return nil
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
		return faction:getRankName(faction.playerRank + 1)
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

local sk = {}
local substitutions = {
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

-- modified to sort things /abot
function speech.setSubstitution(pattern, replacement)
	substitutions[pattern] = replacement
	sk[#substitutions] = pattern
end

function speech.getSAPIXML(tokensRequired, pitch, volume, speed)
	return string.format("<voice required=\"%s\" /><pitch absmiddle=\"%d\" /><volume level=\"%d\" /><rate speed=\"%d\" />", tokensRequired, pitch, volume, speed)
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
	local line = text
	if logLevel then
		if logLevel >= 5 then
			mwselog(text)
		end
	end
	local oldLine
	---for pattern, replacement in pairs(substitutions) do
	local replacement
	for _, pattern in ipairs(sk) do -- sk is sorted once in loaded()
		replacement = substitutions[pattern]
		oldLine = line
		line = string.gsub(line, pattern, replacement)
		if logLevel then
			if logLevel >= 4 then
				mwselog('line = string.gsub("%s", "%s", "%s")', line, pattern, replacement)
				if (logLevel >= 5)
				or (not (line == oldLine)) then
					mwselog("line:\n%s\npattern = %s\nreplacement = %s", line, pattern, replacement)
				end
			end
		end
	end

	-- ensure these are done after other %% replacements
	local ptrn = "[%^%%]([%w_]+)"
	oldLine = line
	line = string.gsub(line, ptrn, expandGlobalVar)
	if logLevel then
		if logLevel >= 4 then
			if (logLevel >= 5)
			or (not (line == oldLine)) then
				mwselog("oldLine:\n%s\npattern = %s\nline:\n%s", oldLine, ptrn, line)
			end
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

	--[[if logLevel then
		if logLevel >= 5 then
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
	line = speech.getSAPIXML(params.tokensRequired or speech.tokensRequired, params.pitch or speech.pitch, params.volume or speech.volume, params.speed or speech.speed) .. line

	if logLevel then
		if logLevel >= 4 then
			mwselog(line)
		end
	end
	if line then
		lastSpokenText = text
		comInterface:Speak(line, SAPI.SpeechVoiceSpeakFlags.SVSFlagsAsync)
	end
end

function speech.isSpeaking()
	if not comInterface then
		return nil
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

function speech.skip(type, count)
	if not comInterface then
		return
	end
	comInterface:Skip(type or "Sentence", count or 1)
end

local function loaded()
	local i = #sk + 1
	for pattern, _ in pairs(substitutions) do
		if not sk[i] then
			sk[i] = pattern
			i = i + 1
		end
	end
	-- so things like "[%%%^][nN][aA][mM][eE]" hopefully take precedence over fixing gro- pronunciation /abot
	table.sort(sk)
	--[[local replacement
	for _, pattern in ipairs(sk) do
		replacement = substitutions[pattern]
		mwse.log("SPEECH pattern = %s, replacement = %s" , pattern, replacement)
	end]]
end
event.register('loaded', loaded, {doOnce = true})

return speech