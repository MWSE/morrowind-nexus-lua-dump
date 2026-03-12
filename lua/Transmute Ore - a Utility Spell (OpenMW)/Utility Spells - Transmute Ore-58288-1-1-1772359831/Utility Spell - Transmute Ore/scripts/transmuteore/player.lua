local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local ambient = require("openmw.ambient")
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local v2 = util.vector2

local currentUiMode = nil

-- transmute ore: greater spell
local transmuteMap = {
	["t_ingmine_oreiron_01"] = "t_ingmine_oresilver_01",
	["t_ingmine_oresilver_01"] = "t_ingmine_oregold_01",
	["t_ingmine_oregold_01"] = "t_ingmine_oreiron_01",
}

local transmuteTimer = nil
local skipSkillUse = false
local showLearnedMessageNextFrame = false

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
    if not skipSkillUse and skillId == "alteration" then
        local spell = types.Player.getSelectedSpell(self)
        if spell then 
			if spell.id == "transmute_ore_gr" then
				transmuteTimer = core.getRealTime() + 0.05
			end
			
			if spell.id == "transmute_ore_l" then
				core.sendGlobalEvent("TransmuteOre_transmute_l", {
					player = self,
				})
			end
        end
    end
end)

-- teaches transmute ore spell
function UiModeChanged(data)
	currentUiMode = data.newMode
    if currentUiMode == "Book" and data.arg and data.arg.recordId == "t_bk_reality&otherfalsehoodspc" then
		local hasSpellAlready = false
		for _, spell in pairs(types.Player.spells(self)) do
			if spell.id == "transmute_ore_gr" then
				hasSpellAlready = true
				break
			end
		end
		if not hasSpellAlready then
			types.Player.spells(self):add("transmute_ore_gr")
			showLearnedMessageNextFrame = true
			ambient.playSound("skillraise")
		end
    end
end

local function onFrame(dt)
	if showLearnedMessageNextFrame then
		ui.showMessage("You have learned the spell Transmute Ore.")
		showLearnedMessageNextFrame = false
	end
	if transmuteTimer and core.getRealTime() > transmuteTimer then
		transmuteTimer = nil

		local ray = I.SharedRay.get()
		if not ray.hit or not ray.hitObject then return end
		if not types.Item.objectIsInstance(ray.hitObject) then return end

		local recordId = ray.hitObject.recordId
		local newId = transmuteMap[recordId]
		if not newId then return end

		local successChance = 1
		if ray.hitObject.count > 1 then
			local neededSkill = 15 + ray.hitObject.count * 10
			local mySkill = types.Player.stats.skills.alteration(self).modified
			successChance = mySkill / neededSkill -- 31 pct at 5 ores and 20 skill
		end
		local success = successChance > math.random()
		if not success then 
			ui.showMessage("You failed to transmute "..ray.hitObject.count.." ores.")
			ambient.playSound("spell failure alteration")
			return 
		end
		skipSkillUse = true
		I.SkillProgression.skillUsed("alteration", {skillGain = ray.hitObject.count*2, useType = I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success , scale = nil})
		skipSkillUse = false
		core.sendGlobalEvent("TransmuteOre_transmute_gr", {
			player = self,
			target = ray.hitObject,
			newRecordId = newId,
		})
		ambient.playSoundFile("sound/transmute_ore.wav")
	end
end

local function showMessage(str)
	ui.showMessage(str)
end

-- delayed registration for Magic Window and Inventory Extender APIs
async:newUnsavableSimulationTimer(0.1, function()

-- magic window API
local configPlayer = require('scripts.MagicWindowExtender.config.player')
local API = require('openmw.interfaces').MagicWindow
local Spells = API.Spells
local C = API.Constants

-- magic window extender custom effects
-- greater transmute ore
Spells.registerEffect{
    id = "transmute_ore_effect",
    icon = "icons/s/tx_s_slowfall.dds",
    name = "Transmute Iron, Silver Ore, or Gold Ore",
    school = "alteration",
    hasDuration = false,
    hasMagnitude = false,
    isAppliedOnce = true,
    magnitudeType = C.Magic.MagnitudeDisplayType.Touch,
}

Spells.registerSpell{
    id = "transmute_ore_gr",
    effects = {
		{
			id = "transmute_ore_effect",
			effect = Spells.getCustomEffect("transmute_ore_effect"),
			magnitudeMin = 0,
			magnitudeMax = 0,
			area = 0,
			duration = 0,
			range = core.magic.RANGE.Touch,
		}
    }
}

-- lesser transmute ore
local ok, err = pcall(function()
	Spells.registerEffect{
		id = "transmute_ore_effect_l",
		icon = "icons/s/tx_s_slowfall.dds",
		name = "Transmute Iron or Silver Ore",
		school = "alteration",
		hasDuration = false,
		hasMagnitude = false,
		isAppliedOnce = true,
		magnitudeType = C.Magic.MagnitudeDisplayType.Touch,
	}

	Spells.registerSpell{
		id = "transmute_ore_l",
		effects = {
			{
				id = "transmute_ore_effect_l",
				effect = Spells.getCustomEffect("transmute_ore_effect_l"),
				magnitudeMin = 0,
				magnitudeMax = 0,
				area = 0,
				duration = 0,
				range = core.magic.RANGE.Self,
			}
		}
	}
end)
if not ok then
	print("[Transmute Ore] Failed to register lesser spell with Magic Window: " .. tostring(err))
end

-- inventory extender tooltip
if not I.InventoryExtender then
	print("[Transmute Ore] InventoryExtender not found - tooltip integration disabled")
	return
end

local BASE = I.InventoryExtender.Templates.BASE
local constants = I.InventoryExtender.Constants

local COLORS = {
	LABEL	= (constants and constants.Colors and constants.Colors.DISABLED) or util.color.rgb(0.6, 0.6, 0.6),
	MAGIC	= util.color.rgb(0.7, 0.5, 0.9),
}

local bookTooltips = {
	["t_bk_reality&otherfalsehoodspc"] = "Teaches the spell Greater Transmute Ore.",
}

local function getInnerContent(layout)
	local ok, result = pcall(function()
		return layout.content[1].content[1].content
	end)
	return ok and result or nil
end

local function addSeparator(content)
	content:add(BASE.intervalV(8))
	content:add({ template = I.MWUI.templates.horizontalLine, props = { size = v2(200, 2) } })
	content:add(BASE.intervalV(4))
end

local function addText(content, text, color)
	content:add({ template = BASE.textNormal, props = { text = text, textColor = color or COLORS.LABEL, multiline = true, textAlignH = ui.ALIGNMENT.Center } })
end

I.InventoryExtender.registerTooltipModifier("TransmuteOre_Books", function(item, layout)
	local tooltip = bookTooltips[item.recordId]
	if not tooltip then return layout end

	local content = getInnerContent(layout)
	if not content then return layout end

	addSeparator(content)
	addText(content, tooltip, COLORS.MAGIC)

	-- check if player already knows the spell
	local hasSpell = false
	for _, spell in pairs(types.Player.spells(self)) do
		if spell.id == "transmute_ore_gr" then
			hasSpell = true
			break
		end
	end
	if hasSpell then
		content:add(BASE.intervalV(2))
		addText(content, "Known", util.color.rgb(0.5, 0.9, 0.5))
	else
		content:add(BASE.intervalV(2))
		addText(content, "Unread", util.color.rgb(0.8, 0.3, 0.3))
	end

	return layout
end)

end)

return {
	engineHandlers = {
		onFrame = onFrame,
	},
    eventHandlers = {
        UiModeChanged = UiModeChanged,
		TransmuteOre_showMessage = showMessage,
    }
}