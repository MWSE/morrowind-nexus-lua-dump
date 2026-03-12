local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local async = require('openmw.async')
local v2 = util.vector2
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local input = require('openmw.input')
local types = require('openmw.types')
local self = require("openmw.self")
-- local ambient = require("openmw.ambient"), 
-- local camera = require('openmw.camera')
-- local nearby = require('openmw.nearby')
-- local animation = require('openmw.animation')
local playerInventory = types.Actor.inventory(self)
local getEquipment = types.Actor.getEquipment
local checkLockpick = types.Lockpick.objectIsInstance
local checkProbe = types.Probe.objectIsInstance

local currentUiMode = nil
local sunsDusk

-- recharge soul gem tracking
local rechargeSoulCount = nil

-- lockpicking + trap disarming
local oldToolCondition

-- self repair attempt detection
local repairConditions = {}

-- ingredient tracking for potions
local ingredientCount = nil

-- self enchanting soul gem tracking
local selfEnchanting = false
local enchantSoulCount = nil

-- sun's dusk bath
local oldCleanValue = 0

require('scripts.timeFlies.tf_settings')

-- service UI modes that come from dialogue
-- when returning from any of these to Dialogue, DIALOGUE_TIME is not retriggered so that a conversation only counts once
-- local serviceModes = {
-- 	Barter = true,
-- 	SpellBuying = true,
-- 	SpellCreation = true,
-- 	Enchanting = true,
-- 	MerchantRepair = true,
-- 	Companion = true,
-- 	Travel = true,
-- }

local function getGold()
    local goldItem = playerInventory:find('gold_001')
    return goldItem and goldItem.count or 0
end

local serviceGold = nil
local currentServiceMode = nil
local i = 1
-- eating a lot of performance:
local function getToolCondition()
	--if not types.Actor.getStance(self) ~= types.Actor.STANCE.Weapon then return false end -- costs even more performance
    local equippedR = getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not equippedR then return false end
    local isLockpick = checkLockpick(equippedR)
    local isProbe =    checkProbe(equippedR)
    if not (isLockpick or isProbe) then return false end
	local condition = types.Item.itemData(equippedR).condition or 0
	return condition
end

function UiModeChanged(data)
	currentUiMode = data.newMode

	-- new convo
	if data.oldMode == "Dialogue" and currentUiMode == nil then
		local minutes = DIALOGUE_TIME
		if minutes > 0 then
			core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
		end
	end

    if data.oldMode == "Book" then -- or "Scroll"
        local minutes = READING_TIME
        if minutes > 0 then
            core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
        end
    end

    if data.oldMode == "Journal" then
        local minutes = JOURNAL_TIME
        if minutes > 0 then
            core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
        end
    end

    if data.oldMode == "Barter" then
        local minutes = BARTER_TIME
        if minutes > 0 then
            core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
        end
    end

	-- companion inventory
    if data.oldMode == "Companion" then
        local minutes = COMPANION_TIME
        if minutes > 0 then
            core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
        end
    end

	-- services using gold to pass time, the rest is in onFrame
	if currentUiMode == "SpellBuying" or currentUiMode == "MerchantRepair" then
		serviceGold = getGold()
		currentServiceMode = currentUiMode
	end

	-- NPC enchanting
	if currentUiMode == "Enchanting" and data.oldMode == "Dialogue" then
		serviceGold = getGold()
		currentServiceMode = "Enchanting"
	end

	-- clear gold tracking when service ends
	if currentServiceMode and data.oldMode == currentServiceMode then
		serviceGold = nil
		currentServiceMode = nil
	end	

	-- spell creating
    if currentUiMode == "SpellCreation" then
		serviceGold = getGold()
    end
	if data.oldMode == "SpellCreation" then
		local minutes = SPELLCREATE_TIME
        if minutes > 0 and getGold() < serviceGold  then
            core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
        end
		serviceGold = nil
    end

	-- enchanting
    if currentUiMode == "Enchanting" and data.oldMode == "Dialogue" then
		serviceGold = getGold()
    end
	if data.oldMode == "Enchanting" and currentUiMode == "Dialogue" then
		local minutes = ENCHANTING_TIME
        if minutes > 0 and getGold() < serviceGold  then
            core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
        end
		serviceGold = nil
    end

	if currentUiMode == "Enchanting" and data.oldMode ~= "Dialogue" then
		selfEnchanting = true
		enchantSoulCount = 0
		for _, item in pairs(playerInventory:getAll(types.Miscellaneous)) do
			if types.Item.itemData(item).soul and types.Item.itemData(item).soul ~= "" then
				enchantSoulCount = enchantSoulCount + item.count
			end
		end
	end

	if data.oldMode == "Enchanting" and selfEnchanting then
		selfEnchanting = false
		local currentCount = 0
		for _, item in pairs(playerInventory:getAll(types.Miscellaneous)) do
			if types.Item.itemData(item).soul and types.Item.itemData(item).soul ~= "" then
				currentCount = currentCount + item.count
			end
		end
		if enchantSoulCount and currentCount < enchantSoulCount then
			local minutes = SELF_ENCHANTING_TIME
			if minutes > 0 then
				core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
			end
		end
		enchantSoulCount = nil
	end

	-- recharging from inventory
	if currentUiMode == "Recharge" then
		rechargeSoulCount = 0
		for _, item in pairs(playerInventory:getAll(types.Miscellaneous)) do
			if types.Item.itemData(item).soul and types.Item.itemData(item).soul ~= "" then
				rechargeSoulCount = rechargeSoulCount + item.count
			end
		end
	end
	
	if data.oldMode == "Recharge" then
		rechargeSoulCount = nil
	end
	
	-- creating potions
	if currentUiMode == "Alchemy" then
		ingredientCount = 0
		for _, item in pairs(playerInventory:getAll(types.Ingredient)) do
			ingredientCount = ingredientCount + item.count
		end
	end
	
	if data.oldMode == "Alchemy" then
		ingredientCount = nil
	end

	-- looting a container that's not a plant or ore lmfao
    if data.oldMode == "Container" then
		local isPlant = data.arg and data.arg.type.record(data.arg).isOrganic
		if not isPlant then
			local minutes = LOOTING_TIME
			if minutes > 0 then
				core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
			end
		end
    end
end

local function onFrame(dt)
	i = i + 1
	
	if i%10 == 0 then
		local currentCondition = getToolCondition()
	
		-- time passes when tool (lockpick or probe) loses durability or durability increases after it was <3 before
		if currentCondition and oldToolCondition then
			local spentUses = oldToolCondition - currentCondition
			if spentUses < 0 and oldToolCondition <3 then
				spentUses = oldToolCondition
			end
			local minutes = spentUses * LOCKPICKING_TIME
			if minutes > 0 then
				core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
			end
		end
		oldToolCondition = currentCondition
	end

	-- remove someday when nobody is using version 2 anymore
	-- detect when dirt drops to ~0 (from bathing)
	if sunsDusk == nil then
		sunsDusk = I.SunsDusk and I.SunsDusk.version >= 2 and I.SunsDusk.version < 3 and I.SunsDusk.getSaveData() or false
	end
	if sunsDusk then
		local newCleanValue = sunsDusk.m_clean and sunsDusk.m_clean.dirt or 0
		if newCleanValue < 0.01 and oldCleanValue > 0.02 then
			local minutes = BATHING_TIME
			if minutes > 0 then
				core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
			end
		end
		oldCleanValue = newCleanValue
	end
	
	-- pass time each time for each transaction
	if currentServiceMode and serviceGold then
		local gold = getGold()
		if gold < serviceGold then
			local minutes = 0
			if currentServiceMode == "SpellBuying" then minutes = SPELLBUY_TIME
			elseif currentServiceMode == "MerchantRepair" then minutes = REPAIRING_TIME
			elseif currentServiceMode == "Enchanting" then minutes = ENCHANTING_TIME
			end
			if minutes > 0 then
				core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
			end
			serviceGold = gold
		end
	end	

	-- ui mode specific
	if currentUiMode == "Repair" then
		local seenIds = {}
		repairConditions = repairConditions or {}
		for _, item in pairs(playerInventory:getAll(types.Repair)) do
			local condition = types.Item.itemData(item).condition
			local prev = repairConditions[item.id]
			if prev ~= nil then
				if condition < prev.condition or item.count < prev.count then
					local minutes = SELF_REPAIRING_TIME
					if minutes > 0 then
						core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
					end
				end
			end
			repairConditions[item.id] = { condition = condition, count = item.count }
			seenIds[item.id] = true
		end
		
		-- entire stack consumed
		for id, _ in pairs(repairConditions) do
			if not seenIds[id] then
				local minutes = SELF_REPAIRING_TIME
				if minutes > 0 then
					core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
				end
				repairConditions[id] = nil
			end
		end
	else
		-- clear snapshots when not in repair UI so stale data doesn't cause false positives on re-entry
		repairConditions = nil
	end

	if rechargeSoulCount then
		local currentCount = 0
		for _, item in pairs(playerInventory:getAll(types.Miscellaneous)) do
			if types.Item.itemData(item).soul and types.Item.itemData(item).soul ~= "" then
				currentCount = currentCount + item.count
			end
		end
		if currentCount < rechargeSoulCount then
			local minutes = RECHARGE_TIME
			if minutes > 0 then
				core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
			end
		end
		rechargeSoulCount = currentCount
	end
	
	if ingredientCount then
		local currentCount = 0
		for _, item in pairs(playerInventory:getAll(types.Ingredient)) do
			currentCount = currentCount + item.count
		end
		if currentCount < ingredientCount then
			local minutes = POTION_TIME
			if minutes > 0 then
				core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
			end
		end
		ingredientCount = currentCount	
	end
end

-- consuming food, potions and ingredients
local function onConsume(item)
    local minutes = CONSUME_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

-- global events
local function harvestPlant(object)
    local minutes = HARVEST_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function activateShrine(object)
	async:newUnsavableGameTimer(0.2, function()
		local minutes = SHRINE_TIME
		if minutes > 0 then
			core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
		end
    end)
end

local function disposeBody(object)
    local minutes = BODIES_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

-- sun's dusk global
local function cookFood()
    local minutes = COOKING_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function brewTea()
    local minutes = TEA_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function refillWell()
    local minutes = REFILL_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function purifyWater()
    local minutes = PURIFY_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function buildFire()
    local minutes = CAMPFIRE_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function pitchTent()
    local minutes = TENT_PITCH_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function destroyTent()
    local minutes = TENT_DESTROY_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function attackedTree()
    local minutes = WOODCUTTING_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function finishedBath()
    local minutes = BATHING_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

-- ownlyme's suite

local function mineOre()
    local minutes = MINING_TIME * 3
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function simplyMining()
    local minutes = MINING_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

local function disenchantFinished(data)
    local minutes = DISENCHANTING_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

-- ralts
local function bardcraftPerformance(data)
    local minutes = PERFORMANCE_TIME
    if minutes > 0 then
        core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
    end
end

I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
    if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer then
        local skillLevel = types.NPC.stats.skills[skillid](self).base
        local minutes = EXTRA_TRAINING_TIME + (EXTRA_TRAINING_TIME_PER_LEVEL * skillLevel)
        if minutes > 0 then
            core.sendGlobalEvent('TimeFlies_passMinutes', minutes)
        end
    end
end)

return {
    engineHandlers = {
		-- onInit = onLoad,
		-- onLoad = onLoad,
		-- onSave = onSave,
        onFrame = onFrame,
		onConsume = onConsume,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,

		-- my globals
		TimeFlies_harvestPlant = harvestPlant,
		TimeFlies_activateShrine = activateShrine,
		TimeFlies_disposeBody = disposeBody,

		-- sun's dusk globals
		TimeFlies_cookFood = cookFood,
		TimeFlies_brewTea = brewTea,
		TimeFlies_refillWell = refillWell,
		TimeFlies_purifyWater = purifyWater,
		TimeFlies_buildFire = buildFire,
		TimeFlies_pitchTent = pitchTent,
		TimeFlies_destroyTent = destroyTent,
		SunsDusk_finishedBath = finishedBath,
		SunsDusk_attackedTree = attackedTree,

		-- ownlyme's suite
		TimeFlies_mineOre = mineOre,
		TimeFlies_simplyMining = simplyMining,
		disenchanting_finishedDisenchanting = disenchantFinished,
		
		-- ralts
		BC_PerformanceLog = bardcraftPerformance,
    }
}

-- Ui Layers
-- 1    UiLayer(Scene)
-- 2    UiLayer(FadeToBlack)
-- 3    UiLayer(HitOverlay)
-- 4    UiLayer(HUD)
-- 5    UiLayer(JournalBooks)
-- 6    UiLayer(Windows)
-- 7    UiLayer(DragAndDrop)
-- 8    UiLayer(DrowningBar)
-- 9    UiLayer(MainMenuBackground)
-- 10    UiLayer(MainMenu)
-- 11    UiLayer(Settings)
-- 12    UiLayer(ControllerButtons)
-- 13    UiLayer(LoadingScreenBackground)
-- 14    UiLayer(LoadingScreen)
-- 15    UiLayer(Debug)
-- 16    UiLayer(Console)
-- 17    UiLayer(Modal)
-- 18    UiLayer(Popup)
-- 19    UiLayer(Notification)
-- 20    UiLayer(Video)
-- 21    UiLayer(InputBlocker)
-- 22    UiLayer(Pointer)

-- List of UI modes
-- Recharge
-- Training
-- Rest
-- LevelUp
-- Repair
-- ChargenRace
-- ChargenBirth
-- ChargenClass
-- ChargenClassGenerate
-- Scroll
-- ChargenClassCreate
-- Book
-- QuickKeysMenu
-- Interface
-- Journal
-- Jail
-- LoadingWallpaper
-- Loading
-- ChargenClassReview
-- Container
-- ChargenClassPick
-- ChargenName
-- MerchantRepair
-- Companion
-- MainMenu
-- Alchemy
-- Dialogue
-- Barter
-- SpellBuying
-- Travel
-- SpellCreation
-- Enchanting