local core    = require('openmw.core')
local self    = require('openmw.self')
local types   = require('openmw.types')
local storage = require('openmw.storage')
local time    = require('openmw_aux.time')

local cfg = require('scripts.DiscordRPC.disc_config')

-- ------------------------------ config ------------------------------

local INTERVAL = 4 * time.second
local SECTION  = "DiscordRPC"

local SHOW_CHARACTER_ART = cfg.SHOW_CHARACTER_ART
local DEFAULT_IMAGE      = cfg.DEFAULT_IMAGE or ""
local CHARACTER_IMAGES   = cfg.CHARACTER_IMAGES or {}

local presence = storage.playerSection(SECTION)
presence:setLifeTime(storage.LIFE_TIME.Temporary)

-- Not displayed:
local PLACEHOLDER_CLASSES = {
	["Adventurer"]          = true, -- english
	["Aventurier"]          = true, -- french
	["Abenteurer"]          = true, -- german
	["Poszukiwacz przygód"] = true, -- polish
	["Авантюрист"]          = true, -- russian
	["Aventurero"]          = true, -- spanish
	["Avventuriero"]        = true, -- italian
	["Kalandozó"]           = true, -- hungarian
	["Dobrodruh"]           = true, -- czech
	["冒険者"]               = true, -- japanese
}

-- ------------------------------ state ------------------------------

local attackers = {}
local lastSent  = nil

-- ------------------------------ game state ------------------------------

local function getCellName()
	local c = self.cell
	if not c then return "" end
	if c.name and c.name ~= "" then return c.name end
	if c.region and c.region ~= "" then
		local rec = core.regions.records[c.region]
		if rec and rec.name and rec.name ~= "" then return rec.name end
		return c.region
	end
	return c.id or ""
end

local function actorName(actor)
	local ok, rec = pcall(function() return actor.type.record(actor) end)
	if ok and rec and rec.name and rec.name ~= "" then return rec.name end
	return "an enemy"
end

local function pruneAttackers()
	for id, a in pairs(attackers) do
		local ok, dead = pcall(types.Actor.isDead, a)
		if not ok or dead then attackers[id] = nil end
	end
end

local function describeCombat()
	pruneAttackers()
	local list = {}
	for _, a in pairs(attackers) do list[#list + 1] = a end
	if #list == 0 then return nil end
	if #list == 1 then return "Fighting " .. actorName(list[1]) end
	return string.format("Fighting %d enemies", #list)
end

-- ------------------------------ publish ------------------------------

local function buildPresence()
	local combat  = describeCombat()
	local details = combat or "Exploring"
	local state   = getCellName()
	local image, tooltip = "", ""

	if SHOW_CHARACTER_ART then
		local rec     = types.NPC.record(self)
		local raceRec = types.NPC.races.records[rec.race]
		local clsRec  = types.NPC.classes and types.NPC.classes.records
			and types.NPC.classes.records[rec.class]
		local level   = types.NPC.stats.level(self).current
		local name    = (rec.name and rec.name ~= "") and rec.name or "Nerevarine"
		local race    = (raceRec and raceRec.name) or rec.race or ""
		local class   = (clsRec  and clsRec.name)  or rec.class or ""

		if PLACEHOLDER_CLASSES[class] then class = "" end

		local middle
		if race ~= "" and class ~= "" then middle = race .. " " .. class
		elseif race ~= ""              then middle = race
		elseif class ~= ""             then middle = class
		else                                middle = ""
		end

		local img = CHARACTER_IMAGES[name] or DEFAULT_IMAGE
		if img and img ~= "" then
			image = img
			if middle ~= "" then
				tooltip = string.format("%s, %s, Level %d", name, middle, level)
			else
				tooltip = string.format("%s, Level %d", name, level)
			end
		end
	end

	return { details = details, state = state, image = image, tooltip = tooltip }
end

local function publish()
	local p = buildPresence()
	if lastSent and p.details == lastSent.details and p.state == lastSent.state
		and p.image == lastSent.image and p.tooltip == lastSent.tooltip then
		return
	end
	lastSent = p
	presence:set("activity", p)
end

-- ------------------------------ events ------------------------------

local function onCombatTargetsChanged(data)
	if not data.actor then return end
	local id = data.actor.id
	local targetingPlayer = false
	if data.targets then
		for _, t in ipairs(data.targets) do
			if t == self.object then
				targetingPlayer = true
				break
			end
		end
	end
	if targetingPlayer then
		attackers[id] = data.actor
	else
		attackers[id] = nil
	end
	publish()
end

-- ------------------------------ register ------------------------------

time.runRepeatedly(publish, INTERVAL)

return {
	engineHandlers = {
		onActive = publish,
	},
	eventHandlers = {
		OMWMusicCombatTargetsChanged = onCombatTargetsChanged,
	},
}
