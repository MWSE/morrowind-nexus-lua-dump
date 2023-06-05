local common = require("alchemyArt.common")
local apparatus = require("alchemyArt.apparatus.apparatus")
local apparatusOverhaul = require("alchemyArt.apparatus.overhaul")
local alembic = require("alchemyArt.apparatus.alembic")
local retort = require("alchemyArt.apparatus.retort")
local calcinator = require("alchemyArt.apparatus.calcinator")
local mortar = require("alchemyArt.apparatus.mortar")
-- local ui = require("alchemyArt.ui")
local ingredients = require("alchemyArt.ingredients.ingredients")
local ingredType= require("alchemyArt.ingredients.ingredType")
local potion = require("alchemyArt.potion.potion")
local specialPotion = require("alchemyArt.potion.special")
local standardPotion = require("alchemyArt.potion.standard")

event.register("modConfigReady", function()
    require("alchemyArt.mcm")
	common.config  = require("alchemyArt.config")
end)

local function onUiObjectTooltip(e)
	if e.object.objectType == tes3.objectType.ingredient then
		ingredients.onTooltip(e)
	elseif e.object.objectType == tes3.objectType.apparatus then
		apparatus.onTooltip(e)
	end
end

local function onUiObjectTooltipLate(e)
	if e.object.objectType ~= tes3.objectType.alchemy then
		return
	end
	potion.onTooltip(e)
end


local function onLoaded(e)
	tes3.player.data.alchemyKnowledge = tes3.player.data.alchemyKnowledge or {}
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.apparatus) do
		if ref.data.alchemyArt and ref.data.alchemyArt.progress and ref.data.alchemyArt.progress < 100 then
			if ref.object.type == tes3.apparatusType.alembic then
				alembic:startTimer(ref)
			elseif ref.object.type == tes3.apparatusType.calcinator then
				calcinator:startTimer(ref)
			elseif ref.object.type == tes3.apparatusType.retort then
				retort:startTimer(ref)
			elseif ref.object.type == tes3.apparatusType.mortarAndPestle then
				mortar:startTimer(ref)
			end
		end
	end
end

local function onEquip(e)
	if e.item.objectType == tes3.objectType.apparatus then
		return false
	end
end

local function onConsumed(e)
	if e.item.objectType == tes3.objectType.alchemy then
		specialPotion.onEquip(e)
	elseif e.item.objectType == tes3.objectType.ingredient then
		if ingredType.insoluble[e.item.id] then
			return false
		end
		tes3.player.data.alchemyKnowledge[e.item.id] = tes3.player.data.alchemyKnowledge[e.item.id] or {}
		if common.getVisibleEffectsCount() == 0 and not tes3.player.data.alchemyKnowledge[e.item.id][1]  then
			tes3.messageBox(common.dictionary.effectLearned)
			common.practiceAlchemy(0.5)
		end
		tes3.player.data.alchemyKnowledge[e.item.id][1] = true
	end
end

local function onActivate(e)

	if (e.activator ~= tes3.player) then
        return
    end

	if e.target.object.objectType ~= tes3.objectType.apparatus then
		return
	end

	local pickUpApparatus

	if e.target.object.type == tes3.apparatusType.calcinator then
		pickUpApparatus =  calcinator:activate(e.target)
	elseif e.target.object.type == tes3.apparatusType.alembic then
		pickUpApparatus =  alembic:activate(e.target)
	elseif e.target.object.type == tes3.apparatusType.retort then
		pickUpApparatus = retort:activate(e.target)
	elseif e.target.object.type == tes3.apparatusType.mortarAndPestle then
		pickUpApparatus =  mortar:activate(e.target)
	end

	if not pickUpApparatus then
		return false
	end
end


local function onInitialized(e)
	if common.config.modEnabled then
		mwse.log(string.format("[%s]: enabled", common.dictionary.modName))
		event.register("activate", onActivate, {priority = 200})
		event.register("uiObjectTooltip", onUiObjectTooltip, {priority = 99999}) -- before ui expansion
		event.register("uiObjectTooltip", onUiObjectTooltipLate, {priority = -99999}) -- after ui expansion
		event.register("loaded", onLoaded)
		event.register("equip", onEquip)
		event.register("equip", onConsumed, {priority = -99999}) -- giving every opportunity to block consumption
		common.init()
		ingredients.init()
		specialPotion.init()
		standardPotion.init()
		if common.config.fixApparatusModels then
			apparatusOverhaul.changeMeshes()
		end
		if common.config.rebalanceApparatus then
			apparatusOverhaul.rebalance()
		end
	else
		mwse.log(string.format("[%s]: disabled", common.dictionary.modName))
	end
end

event.register("initialized", onInitialized)

-- ToDo
-- Check formulas for all the effects - done
-- More epic potions recipes - later
-- Potion rebalance - done
-- Ingredient overhaul - done?
-- similar ingred mechanics
-- iterop for potions and ingredients
-- effect combinations increase power - retort and calcinator left

-- potion names for effect combinations - later
-- magnitude duration for retort? - later

-- ashfall integration
-- poisoning
-- drinking animations

-- Meshes Icons left:

-- AB, TR - low priority

-- ingred_6th_corprusmeat_g - goddamn mesh - netch for now
-- ingred_snowbear_pelt_uniqueg - mesh and icon - clanclaw for now
-- ingred_snowwolf_pelt_uniqueg - mesh and icon - clanclaw for now
-- ingred_wolf_peltg - mesh and icon
-- ingred_bear_peltg - mesh and icon


