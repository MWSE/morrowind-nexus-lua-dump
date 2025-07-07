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


local soundfiles = require("scripts.SSQN.configSound")
local comments = {}
-- local comments = require("scripts.SSQN.comments")

local settings = storage.playerSection("Settings_openmw_SSQN")

common = { omw = { ui=ui, core=core, interfaces=I, util=util, l10n=l10n },
	settings = settings
}


local playerqlist = { ["testbanner_id"] = true }
local element = nil
local questnames = {}
--[[
if core.dialogue then
	questnames = {}
else
	questnames = require("scripts.SSQN.qnamelist")
	print("No dialogue API. Using qnamelist.lua ...")
end
--]]
local iconlist = {}		local ignorelist = {}
local updateList = {}

local questLog = {}			local questIndex = {}
local locations = {}
local proxy = { log = {}, index = {}, names = {} }

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
	if i:find("%.lua$") then
		print("Loading iconlist "..i)
		i = string.sub(i, 1, -5)		i = string.gsub(i, "/", ".")
		M = require(i)
		parseList(M, true)
	end
end

local dialogModes = {
    Barter = true,
    Companion = true,
    Dialogue = true,
    Enchanting = true,
    MerchantRepair = true,
    SpellBuying = true,
    SpellCreation = true,
    Training = true,
    Travel = true,
}

-- Legacy sound names
local legacy = {
	keys = { "soundfile", "soundfilefin", "soundfileupdate" },
	update = {
		["Book Page 1"] = "snd_book1",
		["Book Page 2"] = "snd_book2",
		["SkyUI New Quest"] = "snd_ui_quest_new",
		["SkyUI Objective 1"] = "snd_ui_obj_new_01",
		["SkyUI Skill Increase"] = "snd_ui_skill_increase",
		["None"] = "snd_none", ["Custom"] = "snd_custom", ["Same as Start"] = "snd_same"
		}
}

local function updateKeys()
	for _, v in ipairs(legacy.keys) do
		local key = settings:get(v)
	--	print(v, key)
		if key and legacy.update[key] then
	--		print(v, legacy.update[key])
			settings:set(v, legacy.update[key])
		end
	end
end

updateKeys()

local function updateSettings(_, key)
	local s = soundfiles.settingKeys[key]
	if s then
		soundfiles[s] = settings:get(key)
	--	print(s, soundfiles[s])
	end
end

settings:subscribe(async:callback(updateSettings))
for k, _ in pairs(soundfiles.settingKeys) do	updateSettings(_, k)		end


local function initQuestlist()
	print("Building existing player quest list")
	local quests = types.Player.quests(self)
	for _,v in pairs(quests) do
		local qid = v.id:lower()
       		if playerqlist[qid] == nil then
			playerqlist[qid] = v.finished
	--		if playerqlist[qid] then print(qid, "finished")
	--		else print(qid) end
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
			until (loc ~= nil) or (i <= -string.len(qIDString))
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

local function getQuestName(i)
	if type(i) ~= "string" then		return		end
	if i == "testbanner_id" then
		return "Skyrim Style Quest Notifications"
	end
	local name
	if core.dialogue then
		name = core.dialogue.journal.records[i]
		if name then		name = name.questName		end
	else
		name = questnames[i]
	end
	return name
end

local uicode = require("scripts.SSQN.uicode")

local function removePopup()
	if not element then	return		end
	uicode.removePopup()
	element = nil
end

local function displayPopup(msg)
	local questId, index, tmpl = msg.questId, msg.questStage, msg.template
	if not questId and not msg.text then		return		end

	local e = {
		x=settings:get("bannerposx"), y=settings:get("bannerposy"),
--		showTitle = true, showIcon = settings:get("showicon"),
		width = 360, height = 72,	textX = 0.56, textY = 0.7,
	}

	local txt = msg.text		local header = msg.header
	local notificationImage = type(msg.icon) == "string" and msg.icon
	if tmpl == "questStart" or tmpl == "questFinish" then
		txt = txt or getQuestName(questId) or questId
		header = header or (tmpl == "questFinish" and "text_questfinish")
			or "text_queststart"
	elseif tmpl == "objective" then
		local obj = comments[questId]		obj = obj and obj[index]
		if obj then	txt = obj		end
	end
	if not txt then	return		end

	if msg.showIcon == false then
		notificationImage = nil
	elseif type(questId) == "string" then
		notificationImage = notificationImage or iconpicker(questId)
	end
	if msg.showIcon then
		notificationImage = notificationImage or ""
	elseif not settings:get("showicon") then
		notificationImage = nil
	end
	if tmpl == "questStart" or tmpl == "questFinish" or notificationImage then
		print(questId, notificationImage)
	end

	if notificationImage and not vfs.fileExists(notificationImage) then
		notificationImage = "Icons\\SSQN\\DEFAULT.dds"
	end
	if msg.showHeader == false then
		header = nil
	end

	e.transparent = settings:get("bannertransp")
	if not header and not notificationImage then		e.height = 48		end
	e.bodySize = tonumber(settings:get("textSizeTitle"))

--[[
	local l = txt:len()		local pt = tonumber(settings:get("textSize"))
	e.bodySize = (l > 34 and pt) or (l > 24 and pt*1.25) or (pt*1.5)
	if index then
		e.textX = 0.5		e.showIcon = false
		e.bodySize = (l > 40 and pt) or (pt*1.25)
		if txt ~= "New Journal Entry" then
			e.textY = 0.5	e.showTitle = false	e.height = 48
		end
	elseif not e.showIcon then
		e.textX = 0.5	e.textY = 0.7
		e.bodySize = (l > 40 and pt) or (l > 30 and pt*1.25) or (pt*1.5)
	end
	print(e.bodySize)
--]]

	e.text = txt		e.icon = notificationImage		e.header = header
	e.onlyFade = common.settings:get("anim_style") ~= "opt_anim_scroll"
	e.duration = common.settings:get("bannertime")
	if type(msg.time) == "number" then
		e.duration = math.max(msg.time, 2)
	end

	element = uicode.renderBanner(e)

	local soundfile, sound

	if tmpl == "objective" then
		soundfile = soundfiles[settings:get("sound_objective")]
	elseif tmpl == "questStart" then
		soundfile = soundfiles[settings:get("soundfile")]
--		if soundfile == "custom" then soundfile = settings:get("soundcustom")	end
	elseif tmpl == "questFinish" then
		soundfile = soundfiles[settings:get("soundfilefin")]
		if soundfile == "same" then
			soundfile = soundfiles[settings:get("soundfile")]
--		elseif soundfile == "custom" then
--			soundfile = settings:get("soundcustomfin")
		end
	end
	if type(msg.sound) == "string" then
		soundfile = soundfiles[msg.sound] or msg.sound
		sound = core.sound.records[msg.sound]
	end
	--	Normalize volume of sound file
--	local sndOpt = {volume = soundfile == soundfiles["snd_sky_quest"] and 2 or 1}
	local sndOpt = {volume = soundfile and soundfiles.volume[soundfile:lower()] or 1}

	if sound then
		ambient.playSound(msg.sound, sndOpt)
	elseif soundfile then
		ambient.playSoundFile("Sound\\"..soundfile, sndOpt)
	end
end

local function onUpdate(dt)
	if element then
		if uicode.update(dt) then	removePopup()		end
	end
end

local function getQuestchange(quests)
	for _,v in pairs(quests) do
		local qid = v.id:lower()
       		if playerqlist[qid] ~= nil then
			if v.finished and not playerqlist[qid] then
				playerqlist[qid] = true
				if getQuestName(qid) then	return qid	end
			end
		elseif playerqlist[qid] == nil then
			playerqlist[qid] = v.finished
			if getQuestName(qid) then	return qid	end
		end
	end
	return nil
end

local function journalHandler()
	if element or #updateList == 0 then		return		end
	local msg = updateList[1]		table.remove(updateList, 1)
--	print(msg.id, msg.index, msg.type)
	if not msg.template then	return		end
	displayPopup(msg)
end

local player = { name="" }

time.runRepeatedly(function()
	if settings:get("bannerdemo") and element == nil then
		local finish = playerqlist.testbanner_id
		displayPopup({ questId = "testbanner_id",
			template = finish and "questFinish" or "questStart"})
		playerqlist.testbanner_id = not finish
	else
		journalHandler()
	end
	if self.cell ~= player.cell then
		local c = self.cell
		if player.cell and c.isExterior and c.name and c.name ~= "" then
			local name = c.name
			local s = name:find(",")	if s then name = name:sub(1, s - 1)		end
		--	print("EXT CELL NAME "..name)
			local cells, found = locations[name:lower()]
			if not cells then
				cells = {}
				locations[name:lower()] = cells
				if settings:get("showDiscover") then
					I.SSQN.showBanner{
						text=settings:get("discoverUpper") and name:upper() or name,
						header=l10n("text_discover")
					}
				end
			end
			for _, v in ipairs(cells) do
				if c.gridX == v.gridX and c.gridY == v.gridY then
					found = true
				end
			end
			if not found then
				local p = self.position
			--	print("NEW ENTRY IN LOCATION "..name)
				table.insert(cells, {
					gridX = c.gridX, gridY = c.gridY, name = c.name,
					time = math.floor(core.getGameTime()),
					position = util.vector3(
						math.floor(p.x), math.floor(p.y), math.ceil(p.z) 
					)
				})
				local l = {}
				for k, v in ipairs(cells) do
					l[k] = util.makeReadOnly(v)
				end
				proxy.names[name:lower()] = util.makeReadOnly(l)
			end
--			player.name = c.name
		end
		player.cell = c
	end	
end, 1 * time.second)

local dialogTarget

local function updateJournal(id, stage, info)

	local quest = questLog[id]
	if not quest then
		quest = {}		questLog[id] = quest
	end
	quest[stage] = { id=info.id, time=core.getGameTime(), cell=self.cell.id }
	if dialogTarget then
		quest[stage].actor = dialogTarget.recordId
	end

	local q = {}
	for k, v in pairs(quest) do
		q[k] = util.makeReadOnly(v)
	end
	proxy.log[id] = util.makeReadOnly(q)

	local i = { questId=id, questStage=stage }
	table.insert(questIndex, i)
	table.insert(proxy.index, util.makeReadOnly(i))

end

local function onQuestUpdate(id, stage)

	local infos = core.dialogue.journal.records[id].infos
	local journal = questLog[id] or {}
	for _, v in ipairs(infos) do
		if v.questStage == stage and v.text and v.text ~= "" and not journal[stage] then
			updateJournal(id, stage, v)
		end
	end

	local soundfile = soundfiles[settings:get("soundfileupdate")]
--	if soundfile == "custom" then soundfile = settings:get("soundcustomupdate")	end
	if soundfile then
		if element == nil and not core.isWorldPaused() then
			updateList[#updateList + 1] = {}
		end
		ambient.playSoundFile("Sound\\"..soundfile)
	end

	if not ignorelist[id] and settings:get("enabled") then
		local msg
		if getQuestchange(types.Player.quests(self)) then
			msg = { questId=id, questStage=stage }
			msg.template = playerqlist[id] and "questFinish" or "questStart"
			updateList[#updateList + 1] = msg
		end
		local obj = comments[id]		obj = obj and obj[stage]
		if obj then
			msg = { questId=id, questStage=stage, template="objective", showIcon=false }
			updateList[#updateList + 1] = msg
		end
	end
end


return {
	engineHandlers = {
		onUpdate = onUpdate,
		onQuestUpdate = onQuestUpdate,
		onInit = initQuestlist,
		onLoad = function(e)
			if e and e.journal then
				questLog = e.journal
				for k, v in pairs(questLog) do
					local q = {}
					for k, v in pairs(v) do
						q[k] = util.makeReadOnly(v)
					end
					proxy.log[k] = util.makeReadOnly(q)
				end
			end
			if e and e.index then
				questIndex = e.index
				for k, v in ipairs(questIndex) do
					proxy.index[k] = util.makeReadOnly(v)
				end
			end
			if e and e.locations then
				locations = e.locations
				for k, v in pairs(locations) do
					local l = {}
					for k, v in ipairs(v) do
						l[k] = util.makeReadOnly(v)
					end
					proxy.names[k] = util.makeReadOnly(l)
				end
			end
			initQuestlist()
		end,
		onSave = function()
			return{ version=136, journal = questLog, index = questIndex, locations=locations }
		end
	},

	eventHandlers = {
		UiModeChanged = function(e)
			if element then self:sendEvent("ssqnRemove")		end
			if e.newMode == nil then
				dialogTarget = nil
			elseif dialogModes[e.newMode] and e.arg then
				dialogTarget = e.arg
			end
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
		version = 136,
		registerQIcon = function(id, path)
			if path:find("^\\") then path = string.sub(path, 2, -1)		end
			iconlist[id:lower()] = path
		end,
		registerQBlock = function(id) ignorelist[id:lower()] = true		end,
		getQIcon = function(id)		return iconpicker(id)			end,
		isQBannerBlocked = function(id) return ignorelist[id:lower()] == true		end,
		addQComment = function(id, index, text)
			id = id:lower()		local q = comments[id]
			if not q then q = {}	comments[id] = q		end
			q[index] = text
		end,
		getJournalIndex = function()	return util.makeReadOnly(proxy.index)		end,
		getJournalQuests = function()	return util.makeReadOnly(proxy.log)		end,
		getLocations = function()	return util.makeReadOnly(proxy.names)		end,
		showBanner = function(m)
			assert(type(m) == "table" and m.text, "showBanner: text key must be a string")
			m.template = m.template or "objective"
			updateList[#updateList + 1] = m
		end,

		-- Legacy functions
		blockQBanner = function(id) ignorelist[id:lower()] = true		end,
		getJournal = function()		return util.makeReadOnly(proxy.log)		end,

	}
}
