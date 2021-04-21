--[[
	Plugin: mwse_PoisonCrafting.esp
--]]

local g7a = require("g7.a.common")

local this = {
	ignore = {},
	enable = true,
}

local player
local flagsInverted
local statsModified


-- UTILS

local function skipEvent(ob)
	return (
		ob.objectType ~= tes3.objectType.apparatus
		or this.ignore[ob.id] ~= nil
		or this.enable ~= true
	)
end


-- SETUP

local function toggleEffectFlags()
	-- Toggles the 'isHarmful' flag on all magic effects.

	local MGEF = tes3.getDataHandler().nonDynamicData.magicEffects

	for i=1, #MGEF do
		MGEF[i].isHarmful = not MGEF[i].isHarmful
	end

	flagsInverted = not flagsInverted
end


local function toggleBaseStats()
	-- Toggles the player's current stats between base/modified values.

	local actor = tes3.getMobilePlayer()

	if statsModified then
		-- restore them
		for stat, values in pairs(statsModified) do
			for i=1, #values do
				local diff = actor[stat][i].base - values[i].base
				actor[stat][i].current = values[i].current + diff
			end
		end
		-- clear values
		statsModified = nil
	else
		statsModified = { attributes={}, skills={} }
		-- store values
		for stat, values in pairs(statsModified) do
			for i=1, #actor[stat] do
				-- save backups
				values[i] = {
					base = actor[stat][i].base,
					current = actor[stat][i].current,
				}
				-- enforce base
				actor[stat][i].current = values[i].base
			end
		end
	end
end


local function potionConfig()

	local gmsts = {
		effects = "Potion Effects",
		failure = "Your potion failed.",
		success = "You created a potion.",
	}

	return gmsts
end


local function poisonConfig()
	toggleEffectFlags()

	local gmsts = {
		effects = "Poison Effects",
		failure = "Your poison failed.",
		success = "You created a poison.",
	}

	return gmsts
end


local function getApparatus()
	--
	local mortar = nil
	local apparatus = {}

	-- scan current cell apparatus
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.apparatus) do
		local args = {reference=ref, target=player}
		local item = ref.object

		if not (
			apparatus[item]
			or tes3.getOwner(ref)
			or mwscript.getDelete(args)
			or mwscript.getDisabled(args)
			or mwscript.getDistance(args) > 768
			)
		then -- is unowned and accessible
			mortar = mortar or (item.type == 0) and item.id
			apparatus[item] = true
		end
	end

	-- check for mortar and pestle
	if not mortar then
		for stack in tes3.iterate(player.object.inventory.iterator) do
			local item = stack.object

			if (item.type == tes3.apparatusType.mortarAndPestle
				and item.objectType == tes3.objectType.apparatus)
			then
				mortar = item.id
				break
			end
		end
	end

	-- copy apparatus to inventory
	if mortar then

		local function map(func, items)
			for item, _ in pairs(items) do
				func{reference=player, item=item.id}
			end
		end

		-- copy over all apparatus
		map(mwscript.addItem, apparatus)

		-- remove when menu closed
		timer.delayOneFrame(
			function ()
				map(mwscript.removeItem, apparatus)
			end
		)
	end

	return mortar
end


-- USAGE

local function pickUp()
	local target = this.target

	-- delay to prevent activation while menu mode
	timer.delayOneFrame(
		function ()
			-- bypass the event
			this.enable = false
			player:activate(target)
			this.enable = true
		end
	)
end


local function closeAlchemy()
	if statsModified then
		toggleBaseStats()
	end
	if flagsInverted then
		toggleEffectFlags()
	end
end


local function startAlchemy(config)
	--
	if tes3.getMobilePlayer().inCombat then
		tes3.messageBox{message="You cannot make potions during battle."}
		return
	end

	local mortar = getApparatus()
	if not mortar then
		tes3.messageBox{message="Requires a Mortar and Pestle."}
		return
	end

	-- apply GMST strings
	local cfg = config()
	tes3.getGMST("sCreatedEffects").value = cfg.effects
	tes3.getGMST("sNotifyMessage8").value = cfg.failure
	tes3.getGMST("sPotionSuccess").value = cfg.success

	-- enforce base stats
	if g7a.config.useBaseStats then
		toggleBaseStats()
	end

	-- bypass equip event
	this.enable = false
	mwscript.equip{reference=player, item=mortar}
	this.enable = true

	-- clean up on closed
	timer.delayOneFrame(closeAlchemy)
end


local function updateProgress(potion)
	local alchemy = 17
	local progress = tes3.getMobilePlayer().skillProgress
	local skills = tes3.getDataHandler().nonDynamicData.skills

	for i=1, 8 do
		local effect = potion.effects[i+1]
		if (not effect) or (effect.id == -1) then
			progress[alchemy] = progress[alchemy] + (
				skills[alchemy].actions[1] * (i-1) * 0.1
			)
			break
		end
	end
end


-- MENUS

local function onButton(e)
	-- What do you want to do?
	-- 0. Cancel
	-- 1. Pick Up / Settings
	-- 2. Brew Potion
	-- 3. Brew Poison

	if e.button == 1 then
		this.action()
	elseif e.button == 2 then
		startAlchemy(potionConfig)
	elseif e.button == 3 then
		startAlchemy(poisonConfig)
	end
end


local function showMenu()
	tes3.messageBox{
		message = "What do you want to do?",
		buttons = {"Cancel", this.button, "Brew Potion", "Brew Poison"},
		callback = onButton,
	}
end


-- EVENT

function this.onEquip(e)
	local ob = e.item

	if skipEvent(ob) then
		return
	end

	this.target = nil
	this.button = "Settings"
	this.action = g7a.configMain
	showMenu()

	return false
end


function this.onActivate(e)
	local ob = e.target.object

	if tes3.menuMode() or skipEvent(ob) then
		return
	elseif tes3.getMobilePlayer().isSneaking then
		return
	elseif e.activator ~= player then
		return
	end

	this.target = e.target
	this.button = "Pick Up"
	this.action = pickUp
	showMenu()

	return false
end


function this.onPotionBrewed(e)
	if g7a.config.useLabels then
		g7a.applyLabel(e.object)
	end
	if g7a.config.useBonusProgress then
		updateProgress(e.object)
	end
end


function this.onLoaded(e)
	-- update outer scoped vars
	player = tes3.getPlayerRef()

	-- fix alchemy effect flags
	statsModified = nil
	closeAlchemy()
end


function this.register()
	event.register("loaded", this.onLoaded)
	event.register("equip", this.onEquip)
	event.register("activate", this.onActivate)
	event.register("potionBrewed", this.onPotionBrewed)
end


return this
