--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - Global								  				   │
│  The thin boi 								 					   │
╰──────────────────────────────────────────────────────────────────────╯
]]

MODNAME = "SunsDusk" -- Starwind: Solaris Duskia
I		= require('openmw.interfaces')
world	= require('openmw.world')
types	= require('openmw.types')
core	= require('openmw.core')
storage	= require('openmw.storage')
async	= require('openmw.async')
vfs		= require('openmw.vfs')
util	= require('openmw.util')
time	= require('openmw_aux.time')

v3 		= util.vector3

G_onUpdateJobs = {}
G_delayedUpdateJobs = {} -- {framesDelay, function} - don't use table.insert
G_eventHandlers = {}
G_onObjectActiveJobs = {}
G_onLoadJobs = {}
G_restocking = {}
G_settingsChangedJobs = {}
local successfulInitialized = false
-- cellHasPublican(cell)
-- resolveMaxQ(origId)
-- ensurePotionFor(origId, q, liquidKey)
-- consumeMilliliters(player, mlToConsume, liquidType)
-- isHeatSource(object, mode)


require('scripts.SunsDusk.sd_helpers')
require("scripts.SunsDusk.localization_g")
require('scripts.SunsDusk.sd_loadTexturePacks')
require('scripts.SunsDusk.constants')

for filename in vfs.pathsWithPrefix("scripts/SunsDusk/settings/") do
	if filename:match("%.lua$") and not filename:match("/%._") then
		local require_path = filename:gsub("%.lua$", "")
		require_path = require_path:gsub("/", ".")
		require(require_path)
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Databases															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

--require('scripts.SunsDusk.spreadsheetParser') -- dbConsumables
require('scripts.SunsDusk.staticsParser') -- dbStatics

for filename in vfs.pathsWithPrefix("scripts/SunsDusk/global_modules/") do
	if filename:match("%.lua$") and not filename:match("/%._") then
		-- Remove .lua extension
		local require_path = filename:gsub("%.lua$", "")
		-- Replace forward slashes with dots
		require_path = require_path:gsub("/", ".")
		require(require_path)
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ onUpdate															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function onUpdate(dt)
	for _, func in pairs(G_onUpdateJobs) do
		func(dt)
	end
	for index, t in pairs(G_delayedUpdateJobs) do
		t[1] = t[1] - 1
		if t[1] <= 0 then
			t[2]()
			G_delayedUpdateJobs[index] = nil
		end
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Objects active / inactive											  │
-- ╰──────────────────────────────────────────────────────────────────────╯

G_eventHandlers.SunsDusk_Unhook	= function (object)
	if object:hasScript("scripts/SunsDusk/sd_a.lua") then
		object:removeScript("scripts/SunsDusk/sd_a.lua")
	end
end

local function onObjectActive(object)
	-- Actor script
	--print(object.recordId, object.id)
	
	if types.Actor.objectIsInstance(object) then
		G_delayedUpdateJobs["addScript_"..object.id] = {
			2, 
			function()
				object:addScript("scripts/SunsDusk/sd_a.lua")
			end
		}
	end
	-- Jobs
	for _, job in pairs(G_onObjectActiveJobs) do
		job(object)
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Activating Beds and coal											  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function activateActivator(object, actor)
	local scrName = (types.Activator.record(object.recordId).mwscript or ''):lower()
	if scrName == "bed_standard" or scrName == "chargenbed" then
		actor:sendEvent("SunsDusk_ActivatedBed", object)
	end
	if object.recordId == "sd_coal_pile" then
		object:remove()
		if types.Ingredient.record("t_ingmine_coal_01") then
			world.createObject("t_ingmine_coal_01", 1):moveInto(types.NPC.inventory(actor))
		end
		actor:sendEvent("SunsDusk_playSound", "Item Misc Up")
	end
end

I.Activation.addHandlerForType(types.Activator, activateActivator)

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Util Events														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function checkIfVampireWerewolf(player)
	local gv	   = world.mwscript.getGlobalVariables(player)
	local vampire  = gv.PCVampire
	local werewolf = gv.PCWerewolf
	player:sendEvent("SunsDusk_checkedIfVampireWerewolf", { vampire, werewolf })
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Item Usage (Equipping / used misc)									  │
-- ╰──────────────────────────────────────────────────────────────────────╯

I.ItemUsage.addHandlerForType(types.Armor, function(armor, actor)
    actor:sendEvent("SunsDusk_equippedArmor", armor)
end)

I.ItemUsage.addHandlerForType(types.Light, function(armor, actor)
    actor:sendEvent("SunsDusk_equippedArmor", armor)
end)

I.ItemUsage.addHandlerForType(types.Clothing, function(armor, actor)
    actor:sendEvent("SunsDusk_equippedArmor", armor)
end)

I.ItemUsage.addHandlerForType(types.Weapon, function(armor, actor)
    actor:sendEvent("SunsDusk_equippedArmor", armor)
end)

I.ItemUsage.addHandlerForType(types.Lockpick, function(armor, actor)
    actor:sendEvent("SunsDusk_equippedArmor", armor)
end)

I.ItemUsage.addHandlerForType(types.Probe, function(armor, actor)
    actor:sendEvent("SunsDusk_equippedArmor", armor)
end)

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Inventory Stuff													  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function removeItem(data)
	local player = data[1]
	local item = data[2]
	local count = math.min(item.count, data[3] or 1)
	if count >= 1 then
		item:remove(count)
	end
end

local function addItem(data)
	local player = data[1]
	local recordId = data[2]
	local count = data[3]
	
	local tempItem = world.createObject(recordId, count)
	tempItem:moveInto(types.NPC.inventory(player))
	--player:sendEvent("SunsDusk_refreshInventory")
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Chargen Books														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function spawnBooksInChargenArea(data)
	local player = data[1]
	local cell = player.cell
	local bookCounts = {
        ["sd_book_1_needs"] = 0,
        ["sd_book_2_temp"] = 0,
        ["sd_backpack_satchelbrown"] = 0,
        ["sd_book_3_cook_1"] = 0,
        ["sd_book_4_clean"] = 0,
    }
    -- Check books directly in the cell
    for _, book in ipairs(cell:getAll(types.Book)) do
        if bookCounts[book.recordId] ~= nil then
            bookCounts[book.recordId] = bookCounts[book.recordId] + book.count
        end
    end
    
    -- Check books inside containers
    for _, container in ipairs(cell:getAll(types.Container)) do
        local inv = types.Container.content(container)
        for _, book in ipairs(inv:getAll(types.Book)) do
            if bookCounts[book.recordId] ~= nil then
                bookCounts[book.recordId] = bookCounts[book.recordId] + book.count
            end
        end
    end
	
	local toRemove = {
		{"misc_com_metal_goblet_01",v3(387, 980, 291)},
		{"misc_com_metal_goblet_01",v3(395, 987, 291)},
	}
	for _, item in ipairs(cell:getAll(types.Miscellaneous)) do
		local itemRecordId = item.recordId
		local itemPos = item.position
		for _, data in pairs(toRemove) do
			if data[1] == itemRecordId and (data[2] - itemPos):length()<4 and item.count > 0 then
				item:remove()
			end
		end
        --print(item.recordId, item.position)
    end
	
	local toMove = {
		{"bk_firmament",v3(371.407, 975.645, 298.838), v3(371.407166, 983.245605, 298.837982)},
	}
	for _, item in ipairs(cell:getAll(types.Book)) do
		local itemRecordId = item.recordId
		local itemPos = item.position
		for _, data in pairs(toMove) do
			if data[1] == itemRecordId and (data[2] - itemPos):length()<4 and item.count > 0 then
				item:teleport(item.cell, data[3])
			end
		end
    end

	local rotation = util.transform.rotate(1.95044, v3(0.519988, 0.519988, 0.677661))
	local books = {
		{"sd_book_1_needs",	v3(376.4,	980.2,	298.7), rotation},
		{"sd_book_2_temp",	v3(381.02,	980.3,	298.7), rotation},
		{"sd_book_3_cook_1",	v3(385.64,	980.1,	298.7), rotation},
		{"sd_book_4_clean",		v3(390.26,	980.0,	298.7), rotation},
		--	{"sd_backpack_satchelbrown", v3(376.2, 657.1, 232.1),  util.transform.rotate(2.55966, v3(0, 0, 1))},
		{"sd_backpack_satchelbrown", v3(375.92, 668.81, 232.09),  util.transform.rotate(2.55966, v3(0, 0, 1))},
	}
	local xOffset = 0
	for _, bookData in pairs(books) do
		if bookCounts[bookData[1]] == 0 then
			local newObj = world.createObject(bookData[1], 1)
			newObj:teleport(cell, bookData[2], { rotation = bookData[3] })
		end
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Lifecycle															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function onLoadInternal(data)
	saveData = data or {}
	saveData.consumableVfx			= saveData.consumableVfx		or saveData.steamingStews     or {}
	saveData.consumableVfxCounter	= saveData.consumableVfxCounter	or saveData.stewLootIdCounter or 0
	
	for _, job in pairs(G_onLoadJobs) do
		job(data)
	end
	--for _, player in pairs(world.players) do
	--	player:sendEvent("SunsDusk_syncDatabases", {saveData.reverse})--, saveData.stewRegistry})
	--end
end

local function onLoad(data)
	local success, err = pcall(onLoadInternal, data)
	if success then
		successfulInitialized = true
	else
		local errorMessage = [[Sun's Dusk failed to initialize.
Please report this Error on our OpenMW Discord channel
or at www.nexusmods.com/morrowind/mods/57526]] 

		for _, player in pairs(world.players) do
			player:sendEvent("SunsDusk_errorDetection", {
				globalInit = true,
				message = errorMessage,
				error = err
			})
		end
	end
end

local function onSave()
	if not successfulInitialized and not saveData then 
		return 
	end
	return saveData
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Handlers															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

G_eventHandlers.SunsDusk_checkIfVampireWerewolf				= checkIfVampireWerewolf
G_eventHandlers.SunsDusk_removeItem							= removeItem
G_eventHandlers.SunsDusk_addItem							= addItem
G_eventHandlers.SunsDusk_Books_spawnBooksInChargenArea		= spawnBooksInChargenArea

I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
    actor:sendEvent("SunsDusk_miscUsed", item)
end)

local pendingUnpause = false

G_eventHandlers.SunsDusk_unPauseUI = function()
    pendingUnpause = true
end

G_onUpdateJobs.unPauseUI = function(dt)
    if pendingUnpause then
        pendingUnpause = false
        if world.getPausedTags()["ui"] then
            world.unpause("ui")
        end
    end
end

return {
	engineHandlers = {
		onLoad			= onLoad,
		onInit			= onLoad,
		onSave			= onSave,
		onObjectActive	= onObjectActive,
		onUpdate		= onUpdate,
	},
	eventHandlers = G_eventHandlers,
	interfaceName = "SunsDusk",
	interface = {
		version = 1,
		isGenerated = function(obj)
			local recordId = type(obj) == "string" and obj or obj.recordId
			return saveData.stewRegistry[recordId] or saveData.reverse[recordId]
		end
	}
}