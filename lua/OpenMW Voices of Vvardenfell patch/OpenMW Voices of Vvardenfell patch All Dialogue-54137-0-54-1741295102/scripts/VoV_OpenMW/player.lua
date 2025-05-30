local core = require("openmw.core")
local self = require("openmw.self")
local ambient = require("openmw.ambient")
local types = require("openmw.types")
local I = require("openmw.interfaces")
local vfs = require("openmw.vfs")
local storage = require("openmw.storage")

I.Settings.registerPage {
   key = "openmw_VoV",
   l10n = "openmw_VoV",
   name = "settings_modName",
   description = "settings_modDesc"
}

I.Settings.registerGroup({
   key = "Settings_openmw_VoV",
   page = "openmw_VoV",
   l10n = "openmw_VoV",
   name = "settings_modCategory1_name",
   permanentStorage = true,
   settings = {
      {
         key = "greetings",
         default = false,
         renderer = "checkbox",
         name = "settings_modCategory1_setting01_name"
      },
      {
         key = "blockAdmire",
         default = false,
         renderer = "checkbox",
         name = "settings_modCategory1_setting02_name"
      },
      {
         key = "silence",
         default = false,
         renderer = "checkbox",
         name = "settings_modCategory1_setting03_name"
      },
   },
})

local settingsGroup = storage.playerSection("Settings_openmw_VoV")


local infos = { greeting = {}, admire = {} }

if core.dialogue then
  for _, record in pairs(core.dialogue.greeting.records) do
      for _, v in ipairs(record.infos) do
          infos.greeting[v.id] = true
      end
  end
  for _, v in ipairs(core.dialogue.persuasion.records["Admire Fail"].infos) do
       infos.admire[v.id] = true
  end
  for _, v in ipairs(core.dialogue.persuasion.records["Admire Success"].infos) do
       infos.admire[v.id] = true
  end
end

local function isInfoBlocked(m)
	if not core.dialogue then	return		end
	if settingsGroup:get("greetings") and not infos.greeting[m] then
		return true
	end
	if settingsGroup:get("blockAdmire") and infos.admire[m] then
		return true
	end
end


local basePath = "Vo\\AIV"
local vovActor = nil


--- @param path string
--- openmw if npc is not nearby, sound played ambient instead of focused on npc
local function playText(path, npc)
	local near = true
	if not self.cell.isExterior and self.cell ~= npc.cell then
		near = false
	else
		near = (self.position - npc.position):length() < 1000
	end
	if near then
		core.sendGlobalEvent("soundSay", {file=path, obj=npc})
	else
		ambient.say(path)
	end
end

--- @param isMale boolean
--- @return string
local function getActorSex(isMale)
	if isMale then return "m" else return "f" end
end

--- @param path string
--- @return boolean
local function isPathValid(path)
	return vfs.fileExists("Sound\\" .. path)
end

local function constructVoicePath(race, sex, infoId, actorId, factionId, factionRank)
	local path = basePath
	if (race) then
		path = path .. "\\" .. race
	else
		path = path .. "\\creature"
	end
	if (sex) then
		path = path .. "\\" .. sex
	end
	if (actorId) then
		path = path .. "\\" .. actorId
	end
	if (factionId) then
		path = path .. "\\" .. factionId
	end
	if (factionRank and factionRank >= 0) then
		path = path .. "\\" .. factionRank
	end
	if (infoId) then
		path = path .. "\\" .. infoId .. ".mp3"
	end
	return path
end

local function getVoicePath(race, sex, infoId, actorId, factionId, factionRank)
	-- Check the most specific path first.
	local primaryPath = constructVoicePath(race, sex, infoId, actorId, factionId, factionRank)
	if (isPathValid(primaryPath)) then return primaryPath end
	-- Find every possible fallback path.
	local secondaryPaths = {
		constructVoicePath(race, sex, infoId, actorId, factionId, nil),
		constructVoicePath(race, sex, infoId, actorId, nil, nil),
		constructVoicePath(race, sex, infoId, nil, factionId, factionRank),
		constructVoicePath(race, sex, infoId, nil, factionId, nil),
		constructVoicePath(race, sex, infoId, nil, nil, nil),
		constructVoicePath(nil, nil,  infoId, actorId, factionId, factionRank),
		constructVoicePath(nil, nil,  infoId, actorId, factionId, nil),
		constructVoicePath(nil, nil, infoId, actorId, nil, nil),
		constructVoicePath(nil, nil,  infoId, nil, factionId, factionRank),
		constructVoicePath(nil, nil,  infoId, nil, factionId, nil),
		constructVoicePath(nil, nil, infoId, nil, nil, nil)
	}
	-- Return the first path in the list that is valid.
	for k, path in pairs(secondaryPaths) do
		if(isPathValid(path)) then
			return path
		end
	end
	-- If there's no line, return the most specific path for logging purposes.
	return primaryPath
end

---@param e infoGetTextEventData
local function onInfoGetText(e)
	local info = e.info
	if isInfoBlocked(info.id) then		return		end
	if vovActor then
		local infoId = info.id
		local actorId = vovActor.recordId
		local race = nil
		local sex = nil
		local factionId = nil
		local factionRank = nil
		if vovActor.type == types.NPC then
			local npcRecord = types.NPC.record(vovActor)
			race = npcRecord.race
			sex = getActorSex(npcRecord.isMale)
			local factions = types.NPC.getFactions(vovActor)
			factionId = factions[1]
			if factionId ~= nil then
				factionRank = types.NPC.getFactionRank(self, factionId)
			end
		end
		local voicePath = getVoicePath(race, sex, infoId, actorId, factionId, factionRank)
		if isPathValid(voicePath) then
			print(string.format("VoV: Playing Line at %s", voicePath))
			playText("Sound\\" .. voicePath, vovActor)
		else
			print(string.format("VoV: Missing Line at %s", voicePath))
		end
	end
end


local function silenceVoice(npc)
	vovActor = nil
	if not settingsGroup:get("silence") then return end
	if core.sound.isSayActive(npc) then
		core.sendGlobalEvent("soundStopSay", npc)
	end
	ambient.stopSay()
end

return {
	eventHandlers = {
	tes3InfoGetText = onInfoGetText,
	UiModeChanged = function(m)
		if m.newMode == nil then
			if vovActor then silenceVoice(vovActor) end
		end
		if m.newMode == "Dialogue" and m.arg and m.arg ~= vovActor then
			vovActor = m.arg
		end
	end
	},
}
