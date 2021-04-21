-- code mostly from a old version of NullCascade's speech API
-- I'm unable to use the new dll version at the moment /abot

local speech = {}

-- We need LuaCOM, which is a naughty old module that doesn't return anything.
require("luacom")
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

local function getDialogActor()
	local MenuDialog = tes3ui.findMenu("MenuDialog")
	if (MenuDialog) then
		return MenuDialog:getPropertyObject("PartHyperText_actor")
	end
end

local function getDialogActorOrPlayer()
	return getDialogActor() or tes3.mobilePlayer
end

local substitutions = {
	["<[bB][rR]>"] = "\n",
	["%%[cC][lL][aA][sS][sS]"] = function()
		local class = getDialogActorOrPlayer().object.class
		if class then
			return class.name
		end
	end,
	["%%[nN][aA][mM][eE]"] = function() return getDialogActorOrPlayer().object.name end,
	["%%[pP][cC][cC][lL][aA][sS][sS]"] = function()	return tes3.player.object.class.name end,
	["%%[pP][cC][nN][aA][mM][eE]"] = function() return tes3.player.object.name end,
	["%%[pP][cC][rR][aA][cC][eE]"] = function() return tes3.player.object.race.name end,
	["%%[rR][aA][cC][eE]"] = function()
		local race = getDialogActorOrPlayer().object.race
		if race then
			return race.name
		end
	end,
	["%%[cC][eE][lL][lL]"] = function() return tes3.player.cell.name end,
	["%%[fF][aA][cC][tT][iI][oO][nN]"] = function()
		local actor = getDialogActor()
		if actor then
			local faction = actor.object.faction
			if faction then
				return faction.name
			end
		end
	end,
	["%%[nN][eE][xX][tT][pP][cC][rR][aA][nN][kK]"] = function()
		local actor = getDialogActor()
		if actor then
			local faction = actor.object.faction
			if faction then
				return faction:getRankName(faction.playerRank + 1)
			end
		end
	end,
	["%%[pP][cC][rR][aA][nN][kK]"] = function()
		local actor = getDialogActor()
		if actor then
			local faction = actor.object.faction
			if faction then
				return faction:getRankName(faction.playerRank)
			end
		end
	end,
	["%%[rR][aA][nN][kK]"] = function()
		local actor = getDialogActor()
		if actor then
			local faction = actor.object.faction
			if faction then
				return faction:getRankName(actor.object.factionRank)
			end
		end
	end,
	["[@#]"] = "", -- Remove any other special symbols.

}
function speech.setSubstitution(pattern, replacement)
	substitutions[pattern] = replacement
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

function speech.getFiltered(text)
	local line = text
	if logLevel then
		if logLevel >= 1 then
			mwselog(text)
		end
	end
	local oldLine
	for pattern, replacement in pairs(substitutions) do
		oldLine = line
		line = string.gsub(line, pattern, replacement)
		if logLevel then
			if logLevel >= 2 then
				if not (line == oldLine) then
					mwselog("line:\n%s\npattern = %s\nreplacement = %s", line, pattern, replacement)
				end
			end
		end
	end
	if logLevel then
		if logLevel >= 1 then
			mwselog(line)
		end
	end
	return line
end

function speech.speak(text, params, logLevel)
	if (not comInterface or speech.muted) then
		return
	end

	local line = speech.getFiltered(text) -- Apply filtering

	-- Append speech data.
	line = speech.getSAPIXML(params.tokensRequired or speech.tokensRequired, params.pitch or speech.pitch, params.volume or speech.volume, params.speed or speech.speed) .. line

	if logLevel then
		if logLevel >= 1 then
			mwselog(line)
		end
	end

	comInterface:Speak(line, SAPI.SpeechVoiceSpeakFlags.SVSFlagsAsync)
end

function speech.isSpeaking()
	if not comInterface then
		return nil
	end
	return comInterface.Status.RunningState == SAPI.SpeechRunState.SRSEIsSpeaking
end

function speech.stop()
	if (not comInterface) then
		return
	end

	if (comInterface.Status.RunningState == SAPI.SpeechRunState.SRSEIsSpeaking) then
		comInterface:Speak(' ', SAPI.SpeechVoiceSpeakFlags.SVSFPurgeBeforeSpeak)
	end
end

function speech.skip(type, count)
	if (not comInterface) then
		return
	end

	comInterface:Skip(type or "Sentence", count or 1)
end

return speech