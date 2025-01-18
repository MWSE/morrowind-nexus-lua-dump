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
	["Book Page 1"] = "Fx\\BOOKPAG1.wav",
	["Book Page 2"] = "Fx\\BOOKPAG2.wav",
	["Journal Update"] = "SSQN\\journal_update.wav",
	["SkyUI New Quest"] = "Fx\\ui\\ui_quest_new.wav",
	["SkyUI Objective 1"] = "Fx\\ui\\ui_objective_new_01.wav",
	["SkyUI Skill Increase"] = "Fx\\ui\\ui_skill_increase.wav",
	["None"] = nil, ["Custom"] = "custom", ["Same as Start"] = "same"
	}


local settingsGroup = storage.playerSection("Settings_openmw_SSQN")

local comments = {}
comments.tr_dbattack = {
	[10] = "Speak to a Guard about the attack",
	[30] = "Speak with Apelles Matius in Ebonheart",
	[50] = "Speak to Asciene Rane in the Grand Council Chambers",
	[60] = "Speak to a Royal Guard about the Dark Brotherhood",
	[100] = "Find the Dark Brotherhood base in Old Mournhold"
}
comments.pc_m1_ip_als4 = {
	[10] = "Travel to Archad to confront Uricalimo",
	}

local playerqlist = { ["testbanner_id"] = true }
local element = nil
local questnames
if core.dialogue then
	questnames = {}
else
	questnames = require("scripts.SSQN.qnamelist")
	print("No dialogue API. Using qnamelist.lua ...")
end
local iconlist = {}		local ignorelist = {}
local showObjective, objective = false

local function parseList(list, isMain)
	if type(list) ~= "table" then return		end
	for k, v in pairs(list) do
		if not iconlist[k:lower()] or isMain then
			if v:find("^\\") then v = string.sub(v, 2, -1)		end
			iconlist[k:lower()] = v
		end
	end
end

local M = require("scripts.SSQN.iconlist")
parseList(M, true)
for i in vfs.pathsWithPrefix("scripts/SSQN/iconlists") do
	if i:find(".lua$") then
		print("Loading iconlist "..i)
		i = string.gsub(i, ".lua", "")		i = string.gsub(i, "/", ".")
		M = require(i)
		parseList(M, true)
	end
end

async:newUnsavableSimulationTimer(1, function()
	for i in vfs.pathsWithPrefix("scripts/SSQN/interop") do
		if i:find(".lua$") then
			print("Loading interop "..i)
			i = string.gsub(i, ".lua", "")		i = string.gsub(i, "/", ".")
			require(i)
		end
	end
end)

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
    qIDString = qIDString:lower()
    --checks for full name of index first as requested, then falls back on finding prefix
    if (iconlist[qIDString] ~= nil) then
        return iconlist[qIDString]
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
				if (iconlist[qIDString] ~= nil) then
					break
				else
					qIDString = string.sub(qIDString,1,loc - 1)
				end
			else
				qIDString = ""
				break
			end
		until (iconlist[qIDString] ~= nil) or (qIDString == "") or (j == 10)
		
        if (iconlist[qIDString] ~= nil) then
	        return iconlist[qIDString]
        else
            return "Icons\\SSQN\\DEFAULT.dds" --Default in case no icon is found
        end
    end
end

local function removePopup()
	if not element or type(element) == "number" then element = nil	return		end
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

local function displayPopup(questId, index)
	local qname = getQuestName(questId) or questId
	local notificationImage = iconpicker(questId)
	print(questId, notificationImage)
	if not vfs.fileExists(notificationImage) then notificationImage = "Icons\\SSQN\\DEFAULT.dds" end

	local notificationText
	if not index then
		notificationText = playerqlist[questId] and "text_questfin" or "text_queststart"
	else
		local obj = comments[questId]		if obj then obj = obj[index]	end
		if obj then
			notificationText = qname
			qname = obj
		else
			notificationText = "New Journal Entry:"
		end
	end

	local template = I.MWUI.templates.boxSolidThick
	if settingsGroup:get("bannertransp") then template = I.MWUI.templates.boxTransparentThick end
	local x, y = settingsGroup:get("bannerposx"), settingsGroup:get("bannerposy")
	local textPos, showIcon = 0.5, false
	if settingsGroup:get("showicon") and not index then textPos, showIcon = 0.55, true	end

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
		visible = showIcon,
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
	    relativePosition = util.vector2(textPos, 0.2),
	    anchor = util.vector2(0.5, 0.2),
	    text = l10n(notificationText),
	    textSize = 16,
		},
	},

	{ template = I.MWUI.templates.textHeader,
	type = ui.TYPE.Text,
            props = {
    relativePosition = util.vector2(textPos, 0.8),
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

	local soundfile
	if index then
		soundfile = "Fx\\ui\\ui_objective_new_01.wav"
	elseif notificationText == "text_queststart" then
		soundfile = soundfiles[settingsGroup:get("soundfile")]
		if soundfile == "custom" then soundfile = settingsGroup:get("soundcustom")	end
	else
		soundfile = soundfiles[settingsGroup:get("soundfilefin")]
		if soundfile == "same" then
			soundfile = soundfiles[settingsGroup:get("soundfile")]
		elseif soundfile == "custom" then
			soundfile = settingsGroup:get("soundcustomfin")
		end
	end

	if soundfile ~= nil then ambient.playSoundFile("Sound\\"..soundfile)		end
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
	if questId ~= nil and not ignorelist[questId] and settingsGroup:get("enabled") then
		displayPopup(questId)
	elseif objective then
		print(objective.id, objective.index)
		displayPopup(objective.id, objective.index)
		objective = nil
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
	if showObjective then objective = { id=id, index=stage }		end
	local soundfile = soundfiles[settingsGroup:get("soundfileupdate")]
	if soundfile == "custom" then soundfile = settingsGroup:get("soundcustomupdate")	end
	if soundfile == nil then return end
	if element == nil and not core.isWorldPaused() then
		element = 1
		async:newUnsavableSimulationTimer(1, function() removePopup() end)
	end
	ambient.playSoundFile("Sound\\"..soundfile)
end


return {
	engineHandlers = {
		onQuestUpdate = onQuestUpdate,
		onInit = initQuestlist,
		onLoad = initQuestlist
	},
--[[
	eventHandlers = {
		UiModeChanged = function(e)
			if element and e.newMode then self:sendEvent("ssqnRemove")	end
		end,
		ssqnRemove = function() if core.isWorldPaused() then removePopup()	end	end
	},
--]]
	interfaceName = "SSQN",
	interface = {
		version = 0,
		registerQIcon = function(id, path)
			if path:find("^\\") then path = string.sub(path, 2, -1)		end
			iconlist[id:lower()] = path
		end,
		getQIcon = function(id) return iconpicker(id)				end,
		blockQBanner = function(id) ignorelist[id:lower()] = true		end
	}
}
