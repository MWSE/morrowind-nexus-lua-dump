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

local comments = require("scripts.SSQN.comments")

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
local objective			comments.enabled = false

local playerJournal = {}

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
for i in vfs.pathsWithPrefix("scripts/SSQN/iconlists/") do
	if i:find(".lua$") then
		print("Loading iconlist "..i)
		i = string.gsub(i, ".lua", "")		i = string.gsub(i, "/", ".")
		M = require(i)
		parseList(M, true)
	end
end

--[[
async:newUnsavableSimulationTimer(1, function()
	for i in vfs.pathsWithPrefix("scripts/SSQN/interop/") do
		if i:find(".lua$") then
			print("Loading interop "..i)
			i = string.gsub(i, ".lua", "")		i = string.gsub(i, "/", ".")
			require(i)
		end
	end
end)
--]]


local function gmstToRgb(id, blend)
	local gmst = core.getGMST(id)
	if not gmst then return util.color.rgb(0.6, 0.6, 0.6) end
	local col = {}
	for v in string.gmatch(gmst, "(%d+)") do col[#col + 1] = tonumber(v) end
	if #col ~= 3 then print("Invalid RGB from "..gmst.." "..id) return util.color.rgb(0.6, 0.6, 0.6) end
	if blend then
		for i = 1, 3 do col[i] = col[i] * blend[i] end
	end
	return util.color.rgb(col[1] / 255, col[2] / 255, col[3] / 255)
end

local uiTheme = {
	normal = gmstToRgb("FontColor_color_normal"),
	header = gmstToRgb("FontColor_color_header"),
	baseSize = 16
	}

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
		notificationText = qname
		if obj then
			qname = obj
		else
			qname = "New Journal Entry"
		end
	end

	local template = I.MWUI.templates.boxSolidThick
	if settingsGroup:get("bannertransp") then template = I.MWUI.templates.boxTransparentThick end
--	local x, y = settingsGroup:get("bannerposx"), settingsGroup:get("bannerposy")
	local e = {
		x=settingsGroup:get("bannerposx"), y=settingsGroup:get("bannerposy"),
		showTitle = true, showIcon = settingsGroup:get("showicon"),
		width = 480, height = 72,	textX = 0.56, textY = 0.7,
	}
--	local textX = 0.56		local textY = 0.7
	local l = qname:len()		local pt = uiTheme.baseSize
	local bodySize = (l > 34 and pt) or (l > 24 and pt*1.25) or (pt*1.5)
	if index then
		e.textX = 0.5		e.showIcon = false
		bodySize = (l > 40 and pt) or (pt*1.25)
		if qname ~= "New Journal Entry" then
			e.textY = 0.5	e.showTitle = false	e.height = 48
		end
	elseif not e.showIcon then
		e.textX = 0.5	e.textY = 0.7
		bodySize = (l > 40 and pt) or (l > 30 and pt*1.25) or (pt*1.5)
	end
--	print(bodySize)

element = ui.create {
	layer = 'Notification',
	template = template,
	type = ui.TYPE.Container,
	props = {
	visible = true,
	relativePosition = util.vector2(e.x, e.y),
	anchor = util.vector2(0.5, 0.5),
	},
	content = ui.content {
	{ type = ui.TYPE.Widget, props = { size = util.vector2(e.width, e.height) },

	content = ui.content {

	{ type = ui.TYPE.Image,
            props = {
		visible = e.showIcon,
			--** Position of icon inside notification box.
			--** ( [0/0.5/1 = left/center/right], [0/0.5/1 = top/center/bottom] ) 
    		relativePosition = util.vector2(0.075, 0.5),
    		anchor = util.vector2(0.5, 0.5),
			--** Size of Icon 48 x 48. Change values in line below.
                size = util.vector2(48, 48),
		resource = ui.texture { path = notificationImage },
		},
	},

	{ template = I.MWUI.templates.textNormal,
	    type = ui.TYPE.Text,
            props = {
            visible = e.showTitle,
	    relativePosition = util.vector2(e.textX, 0.25),
	    anchor = util.vector2(0.5, 0.5),
	    text = l10n(notificationText),
	    textSize =  uiTheme.baseSize, textColor = uiTheme.normal,
		},
	},

	{ template = I.MWUI.templates.textHeader,
	type = ui.TYPE.Text,
            props = {
    relativePosition = util.vector2(e.textX, e.textY),
    anchor = util.vector2(0.5, 0.5),
	text = qname,
    textSize = bodySize, textColor = uiTheme.header,
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
--		print(objective.id, objective.index)
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

	local journal = playerJournal[id]
	if not journal then
		journal = {}		playerJournal[id] = journal
	end
	local infos = core.dialogue.journal.records[id].infos
	for _, v in ipairs(infos) do
		if v.questStage == stage and v.text and v.text ~= "" and not journal[stage] then
			journal[stage] = { id=v.id, time=core.getGameTime() }
		end
	end

	if comments.enabled then objective = { id=id, index=stage }		end
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
		onLoad = function(e)
			if e and e.journal then playerJournal = e.journal		end
			initQuestlist()
		end,
		onSave = function() return{ version=130, journal = playerJournal }		end
	},

	eventHandlers = {
		UiModeChanged = function(e)
			if element then self:sendEvent("ssqnRemove")		end
		end,
		ssqnRemove = function()
			if not element then		return		end
			local visible = element.layout.props.visible
			if visible and core.isWorldPaused() then
				element.layout.props.visible = false
				element:update()
			elseif not visible and not core.isWorldPaused() then
				element.layout.props.visible = true
				element:update()
			end
		end
	},

	interfaceName = "SSQN",
	interface = {
		version = 130,
		registerQIcon = function(id, path)
			if path:find("^\\") then path = string.sub(path, 2, -1)		end
			iconlist[id:lower()] = path
		end,
		getQIcon = function(id) return iconpicker(id)				end,
		blockQBanner = function(id) ignorelist[id:lower()] = true		end,
		addQComment = function(id, index, text)
			id = id:lower()		local q = comments[id]
			if not q then q = {}	comments[id] = q		end
			q[index] = text
		end,
		getJournal = function()
			local proxy = {}
			for k, v in pairs(playerJournal) do
				local q = {}
				for k, v in pairs(v) do
					q[k] = util.makeReadOnly(v)
				end
				proxy[k] = util.makeReadOnly(q)
			end
			return util.makeReadOnly(proxy)
		end
	}
}
