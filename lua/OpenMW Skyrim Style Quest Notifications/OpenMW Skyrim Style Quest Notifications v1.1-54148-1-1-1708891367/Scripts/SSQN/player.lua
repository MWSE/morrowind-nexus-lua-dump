local self = require("openmw.self")
local types = require("openmw.types")
local time = require("openmw_aux.time")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local util = require('openmw.util')
local async = require('openmw.async')
local ambient = require("openmw.ambient")
local vfs = require('openmw.vfs')
local storage = require('openmw.storage')


local soundfiles = {
	["Skyrim Quest"] = "SSQN\\quest_update.wav",
	["6th House Chime"] = "Fx\\envrn\\bell2.wav",
	["Skill Raise"] = "Fx\\inter\\levelUP.wav",
	["Magic Effect"] = "Fx\\magic\\mystA.wav",
	["Oblivion Quest"] = "SSQN\\ob_quest.wav",
	["Cliff Racer"] = "Cr\\cliffr\\scrm.wav",
	["None"] = nil, ["Custom"] = "custom"
	}


I.Settings.registerPage {
   key = 'openmw_SSQN',
   l10n = 'openmw_SSQN',
   name = 'Skyrim Style Quest Notifications',
   description = 'OpenMW Skyrim Style Quest Notifications\nby Taitechnic\t\tv1.1\noriginal MWSE mod by Nazz.\n\nThis mod notifies you when you start or finish a quest. The idea is to mimic the quest notifications from Skyrim, hence the name.'
}

I.Settings.registerGroup({
   key = 'Settings_openmw_SSQN',
   page = 'openmw_SSQN',
   l10n = 'openmw_SSQN',
   name = 'Preferences',
   permanentStorage = true,
   settings = {
      {
         key = 'enabled',
         default = true,
         renderer = 'checkbox',
         name = 'Enable Start/Finish Quest Notifications',
      },
      {
         key = 'bannertransp',
         default = true,
         renderer = 'checkbox',
         name = 'Transparent Notification Banner',
      },
	{
         key = 'bannerposx',
         default = 0.5,
         renderer = 'number',
         name = 'Position of Notification Banner on screen',
	description = 'Horizontal position 0.0 = left edge, 1.0 = right edge',
         argument = {
            min = 0.0, max = 1.0,
         },
	},
	{
         key = 'bannerposy',
         default = 0.15,
         renderer = 'number',
	name = "",
         description = 'Vertical position 0.0 = top edge, 1.0 = bottom edge',
         argument = {
            min = 0.0, max = 1.0,
         },
	},
	{
         key = 'bannertime',
         default = 5,
         renderer = 'number',
         name = 'How long to display notification (seconds)',
         argument = {
            min = 2.0,
         },
	},
        {
            key = 'soundfile',
            name = 'Notification Sound',
            description = 'Select the sound to be played when the notification appears. Selecting None silences the notification\n\nDefault: Skyrim Quest',
            default = 'Skyrim Quest', 
            renderer = 'select',
            argument = {
                disabled = false,
                l10n = 'LocalizationContext', 
                items = { "Skyrim Quest", "6th House Chime", "Skill Raise", "Magic Effect", "Oblivion Quest", "Cliff Racer", "None", "Custom" },
            },
	},
      {
         key = 'soundcustom',
         default = "SSQN\\quest_update",
         renderer = 'textLine',
         name = 'Custom Sound File',
         description = 'File path in Sounds\\ folder, without .wav extension',
      },
      {
         key = 'bannerdemo',
         default = false,
         renderer = 'checkbox',
         name = 'Run notification banner test mode',
      },
   },
})

local settingsGroup = storage.playerSection('Settings_openmw_SSQN')



local playerqlist = { ["testbanner_id"] = true }
local element = nil
local questnames = require("scripts.SSQN.qnamelist")
local shadow = require("scripts.SSQN.iconlist")
local iconlist = { }
local vfsname = ""
for k, v in pairs(shadow) do
	vfsname = string.sub(v, 2, -1)
	iconlist[k:lower()] = vfsname
end


local function initQuestlist()
	print("Building existing player quest list")
	local quests = types.Player.quests(self)
	for _,v in pairs(quests) do
		print(v)
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

local function displayPopup(questId)
	local qname = questnames[questId]
	if qname == nil then qname = questId end
	local notificationImage = iconpicker(questId)
	print(questId, notificationImage)
	if not vfs.fileExists(notificationImage) then notificationImage = "Icons\\SSQN\\DEFAULT.dds" end
	local notificationText = "Quest Started:"
	if playerqlist[questId] then notificationText = "Quest Finished:" end

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
	    text = notificationText,
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
			if questnames[qid] ~= "skip" then return qid end
		end
	end
	return nil
end

local function journalHandler()
	if element ~= nil then return end
	local questId = getQuestchange(types.Player.quests(self))
	if questId ~= nil and settingsGroup:get("enabled") then
		displayPopup(questId)
--		print(questId, types.Player.quests(self).stage)
	end
end
		
time.runRepeatedly(function()
	if not settingsGroup:get("bannerdemo") then journalHandler()
	elseif element == nil then displayPopup("testbanner_id")
	end
end, 1 * time.second)


return {
	engineHandlers = {
		onInit = initQuestlist,
		onLoad = initQuestlist
}
}