local self = require("openmw.self")
local types = require("openmw.types")
local time = require("openmw_aux.time")
local ui = require("openmw.ui")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local util = require('openmw.util')
local async = require('openmw.async')
local ambient = require("openmw.ambient")
local vfs = require('openmw.vfs')
local storage = require('openmw.storage')
local l10n = core.l10n("SSQN")


local soundfiles = {
	["Skyrim Quest"] = "SSQN\\quest_update.wav",
	["6th House Chime"] = "Fx\\envrn\\bell2.wav",
	["Skill Raise"] = "Fx\\inter\\levelUP.wav",
	["Magic Effect"] = "Fx\\magic\\mystA.wav",
	["Oblivion Quest"] = "SSQN\\ob_quest.wav",
	["Cliff Racer"] = "Cr\\cliffr\\scrm.wav",
	["Journal Update"] = "SSQN\\journal_update.wav",
	["Book Page 1"] = "Fx\\BOOKPAG1.wav",
	["Book Page 2"] = "Fx\\BOOKPAG2.wav",
	["None"] = nil, ["Custom"] = "custom", ["Same as Start"] = "same"
	}


I.Settings.registerPage {
   key = "openmw_SSQN",
   l10n = "SSQN",
   name = "settings_modName",
   description = "settings_modDesc"
}

I.Settings.registerGroup({
   key = "Settings_openmw_SSQN",
   page = "openmw_SSQN",
   l10n = "SSQN",
   name = "settings_modCategory1_name",
   permanentStorage = true,
   settings = {
      {
         key = "enabled",
         default = true,
         renderer = "checkbox",
         name = "settings_modCategory1_setting01_name",
      },
      {
         key = "bannertransp",
         default = true,
         renderer = "checkbox",
         name = "settings_modCategory1_setting02_name",
      },
	{
         key = "bannerposx",
         default = 0.5,
         renderer = "number",
         name = "settings_modCategory1_setting03_name",
	description = "settings_modCategory1_setting03_desc",
         argument = {
            min = 0.0, max = 1.0,
         },
	},
	{
         key = "bannerposy",
         default = 0.15,
         renderer = "number",
	name = "",
         description = "settings_modCategory1_setting04_desc",
         argument = {
            min = 0.0, max = 1.0,
         },
	},
	{
         key = "bannertime",
         default = 5,
         renderer = "number",
         name = "settings_modCategory1_setting05_name",
         argument = {
            min = 2.0,
         },
	},
        {
            key = "soundfile",
            name = "settings_modCategory1_setting06_name",
            description = "settings_modCategory1_setting06_desc",
            default = "Skyrim Quest", 
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "LocalizationContext", 
                items = { "Skyrim Quest", "6th House Chime", "Skill Raise", "Magic Effect", "Oblivion Quest", "Cliff Racer", "None", "Custom" },
            },
	},
      {
         key = "soundcustom",
         default = "SSQN\\quest_update",
         renderer = "textLine",
         name = "settings_modCategory1_setting07_name",
         description = "settings_modCategory1_setting07_desc",
      },
        {
            key = "soundfilefin",
            name = "settings_modCategory1_setting08_name",
            description = "settings_modCategory1_setting08_desc",
            default = "Same as Start", 
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "LocalizationContext", 
                items = { "Skyrim Quest", "6th House Chime", "Skill Raise", "Magic Effect", "Oblivion Quest", "Cliff Racer", "None", "Custom", "Same as Start" },
            },
	},
      {
         key = "soundcustomfin",
         default = "SSQN\\quest_update",
         renderer = "textLine",
         name = "settings_modCategory1_setting09_name",
      },
        {
            key = "soundfileupdate",
            name = "settings_modCategory1_setting10_name",
            description = "settings_modCategory1_setting10_desc",
            default = "Journal Update",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "LocalizationContext", 
                items = { "Journal Update", "Book Page 1", "Book Page 2", "None", "Custom" },
            },
	},
      {
         key = "soundcustomupdate",
         default = "SSQN\\quest_update",
         renderer = "textLine",
         name = "settings_modCategory1_setting11_name",
      },
      {
         key = "bannerdemo",
         default = false,
         renderer = "checkbox",
         name = "settings_modCategory1_setting12_name",
      },
   },
})

local settingsGroup = storage.playerSection("Settings_openmw_SSQN")



local playerqlist = { ["testbanner_id"] = true }
local element = nil
local questnames
if core.dialogue then
	questnames = {}
else
	questnames = require("scripts.SSQN.qnamelist")
	print("No dialogue API. Using qnamelist.lua ...")
end
local iconlist = { }

local function parseList(list, isMain)
	local name = ""
	for k, v in pairs(list) do
		if not iconlist[k:lower()] or isMain then
			name = string.sub(v, 2, -1)
			iconlist[k:lower()] = name
		end
	end
	return list
end

local M = require("scripts.SSQN.iconlist")
parseList(M, true)
for i in vfs.pathsWithPrefix("scripts\\SSQN\\iconlists") do
--	if not string.find(i, ".lua$") then print("Error non .lua file present in iconlists.") break end
	if i:find(".lua$") then
		i = string.gsub(i, ".lua", "")
		i = string.gsub(i, "/", ".")
		M = require(i)
		parseList(M, true)
	end
end


local function initQuestlist()
	print("Building existing player quest list")
	local quests = types.Player.quests(self)
	for _,v in pairs(quests) do
		local qid = v.id:lower()
       		if playerqlist[qid] == nil then
			playerqlist[qid] = v.finished
			if playerqlist[qid] then print(qid, "finished")
			else print(qid) end
		end
	end
end

local function iconpicker(qIDString)
    --checks for full name of index first as requested, then falls back on finding prefix
    if (iconlist[qIDString] ~= nil) then
        return iconlist[qIDString:lower()]
    else
		local j = 0 --Just to prevent a possible infinite loop
		repeat
			j = j + 1
			local loc = nil
			local i = 0
			repeat
				i = i - 1
				loc = string.find(qIDString, "_", i)
			until (loc ~= nil) or (i == -string.len(qIDString))
			if ( loc ~= nil ) then
				qIDString = string.sub(qIDString,1,loc)
				if (iconlist[qIDString:lower()] ~= nil) then
					break
				else
					qIDString = string.sub(qIDString,1,loc - 1)
				end
			else
				qIDString = ""
				break
			end
		until (iconlist[qIDString:lower()] ~= nil) or (qIDString == "") or (j == 10)
		
        if (iconlist[qIDString:lower()] ~= nil) then
	        return iconlist[qIDString:lower()]
        else
            return "Icons\\SSQN\\DEFAULT.dds" --Default in case no icon is found
        end
    end
end

local function removePopup()
	if element == nil then return end
	element:destroy()
	element = nil
end

local function getQuestName(i)
	if i == "testbanner_id" then
		return "Skyrim Style Quest Notifications"
	end
	local name
	if core.dialogue then
		name = core.dialogue.journal.records[i].questName
		if name == nil then name = "skip" end
	else
		name = questnames[i]
	end
	return name
end

local function displayPopup(questId)
	local qname = getQuestName(questId)
	if qname == nil then qname = questId end
	local notificationImage = iconpicker(questId)
	print(questId, notificationImage)
	if not vfs.fileExists(notificationImage) then notificationImage = "Icons\\SSQN\\DEFAULT.dds" end
	local notificationText = "text_queststart"
	if playerqlist[questId] then notificationText = "text_questfin" end

	local template = I.MWUI.templates.boxSolidThick
	if settingsGroup:get("bannertransp") then template = I.MWUI.templates.boxTransparentThick end
	local x, y = settingsGroup:get("bannerposx"), settingsGroup:get("bannerposy")

element = ui.create {
	layer = 'Notification',
	template = template,
	type = ui.TYPE.Container,
	props = {
	relativePosition = util.vector2(x, y),
	anchor = util.vector2(0.5, 0.5),
	},
	content = ui.content {
		--** Size of notification box 480 x 72. Change numbers in the line below.
	{ type = ui.TYPE.Widget, props = { size = util.vector2(480, 72) },

	content = ui.content {

	{ type = ui.TYPE.Image,
            props = {
			--** Position of icon inside notification box.
			--** ( [0/0.5/1 = left/center/right], [0/0.5/1 = top/center/bottom] ) 
    		relativePosition = util.vector2(0.02, 0.5),
    		anchor = util.vector2(0.02, 0.5),
			--** Size of Icon 48 x 48. Change values in line below.
                size = util.vector2(48, 48),
		resource = ui.texture { path = notificationImage },
		},
	},

	{ template = I.MWUI.templates.textNormal,
	    type = ui.TYPE.Text,
            props = {
	    relativePosition = util.vector2(0.55, 0.2),
	    anchor = util.vector2(0.5, 0.2),
	    text = l10n(notificationText),
	    textSize = 16,
		},
	},

	{ template = I.MWUI.templates.textHeader,
	type = ui.TYPE.Text,
            props = {
    relativePosition = util.vector2(0.55, 0.8),
    anchor = util.vector2(0.5, 0.8),
	text = qname,
    textSize = 16,
		},
	},

	},

	},
	},
}

	async:newUnsavableSimulationTimer(settingsGroup:get("bannertime"), function() removePopup() end)
	local soundfile = soundfiles[settingsGroup:get("soundfile")]
	if soundfile == "custom" then soundfile = settingsGroup:get("soundcustom")..".wav" end
	if notificationText == "text_queststart" then
		if soundfile ~= nil then ambient.playSoundFile("Sound\\"..soundfile) end
		return
	end
	local soundFinish = soundfiles[settingsGroup:get("soundfilefin")]
	if soundFinish ~= "same" then
		soundfile = soundFinish
		if soundFinish == "custom" then soundfile = settingsGroup:get("soundcustomfin")..".wav" end
	end
	if soundfile ~= nil then ambient.playSoundFile("Sound\\"..soundfile) end
end

local function getQuestchange(quests)
	for _,v in pairs(quests) do
		local qid = v.id:lower()
       		if playerqlist[qid] ~= nil then
			if v.finished and not playerqlist[qid] then
				playerqlist[qid] = true
				return qid
			end
		end
		if playerqlist[qid] == nil then
			playerqlist[qid] = v.finished
			if getQuestName(qid) ~= "skip" then return qid end
		end
	end
	return nil
end

local function journalHandler()
	if element ~= nil then return end
	local questId = getQuestchange(types.Player.quests(self))
	if questId ~= nil and settingsGroup:get("enabled") then
		displayPopup(questId)
	end
end
		
time.runRepeatedly(function()
	if not settingsGroup:get("bannerdemo") then journalHandler()
	elseif element == nil then
		displayPopup("testbanner_id")
		playerqlist.testbanner_id = not playerqlist.testbanner_id
	end
end, 1 * time.second)

local function onQuestUpdate(id, stage)
--	if playerqlist[id] == nil then return end
--	if not playerqlist[qid] and types.Player.quests(self)[id].finished then return end
	local soundfile = soundfiles[settingsGroup:get("soundfileupdate")]
	if soundfile == "custom" then soundfile = settingsGroup:get("soundcustomupdate")..".wav" end
	if soundfile == nil then return end
	if element == nil and not core.isWorldPaused() then
		element = 1
		async:newUnsavableSimulationTimer(1, function() element = nil end)
	end
	ambient.playSoundFile("Sound\\"..soundfile)
end


return {
	engineHandlers = {
		onQuestUpdate = onQuestUpdate,
		onInit = initQuestlist,
		onLoad = initQuestlist
}
}