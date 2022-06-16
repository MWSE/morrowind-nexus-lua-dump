local common = {}

common.config = require("Virnetch.enchantmentServicesRedone.config")
common.defaultConfig = require("Virnetch.enchantmentServicesRedone.defaultConfig")
common.i18n = mwse.loadTranslations("Virnetch.enchantmentServicesRedone")

common.mod = {}
common.mod.version = "0.9.2"
common.mod.name = common.i18n("mod.name")

local logger = require("logging.logger")
common.log = logger.new({
	name = "enchantmentServicesRedone",
	logLevel = common.config.logLevel
})

common.GUI_ID = {
	MenuDialog = tes3ui.registerID("MenuDialog"),
	MenuDialog_TopicList = tes3ui.registerID("MenuDialog_topics_pane"),
	MenuDialog_Divider = tes3ui.registerID("MenuDialog_divider"),
	MenuDialog_Service_Enchanting = tes3ui.registerID("MenuDialog_service_enchanting"),
	MenuDialog_Service_Spellmaking = tes3ui.registerID("MenuDialog_service_spellmaking"),

	MenuInventorySelect = tes3ui.registerID("MenuInventorySelect"),
	MenuInventorySelect_button_cancel = tes3ui.registerID("MenuInventorySelect_button_cancel"),
	MenuInventorySelect_gold_label = tes3ui.registerID("vir_esr:MenuInventorySelect_gold_label"),
	MenuInventorySelect_transcriptionSourceEnchantCapacityLabel = tes3ui.registerID("vir_esr:MenuInventorySelect_transcriptionSourceEnchantCapacityLabel"),

	MenuInventorySelect_scrollpane = tes3ui.registerID("MenuInventorySelect_scrollpane"),
	MenuInventorySelect_item_brick = tes3ui.registerID("MenuInventorySelect_item_brick"),
	MenuInventorySelect_icon_brick = tes3ui.registerID("MenuInventorySelect_icon_brick"),

	MenuInventorySelect_itemBlock = tes3ui.registerID("vir_esr:MenuInventorySelect_itemBlock"),
	MenuInventorySelect_nameLabel = tes3ui.registerID("vir_esr:MenuInventorySelect_nameLabel"),
	MenuInventorySelect_belowBlock = tes3ui.registerID("vir_esr:MenuInventorySelect_belowBlock"),
	MenuInventorySelect_rightBlock = tes3ui.registerID("vir_esr:MenuInventorySelect_rightBlock"),

	itemSelect_label = tes3ui.registerID("vir_esr:itemSelect_label"),
	itemSelect_item = tes3ui.registerID("vir_esr:itemSelect_item"),
	itemSelect_itemHolder = tes3ui.registerID("vir_esr:itemSelect_itemHolder"),
	itemSelect_count = tes3ui.registerID("vir_esr:itemSelect_count"),

	Tooltip_decipherBlock = tes3ui.registerID("vir_esr:Tooltip_decipherBlock"),
	Tooltip_decipherLabel = tes3ui.registerID("vir_esr:Tooltip_decipherLabel"),
	Tooltip_decipherTextLabel = tes3ui.registerID("vir_esr:Tooltip_decipherTextLabel"),

	HelpMenu_main = tes3ui.registerID("PartHelpMenu_main"),
	effect = tes3ui.registerID("effect"),

	MenuMessage_message = tes3ui.registerID("MenuMessage_message"),
	MenuMessage_button_layout = tes3ui.registerID("MenuMessage_button_layout"),
	PartButton_text_ptr = tes3ui.registerID("PartButton_text_ptr"),

	MenuMessage_transcribeButton = tes3ui.registerID("vir_esr:MenuMessage_transcribeButton"),
	MenuMessage_cancelButton = tes3ui.registerID("vir_esr:MenuMessage_cancelButton"),

	TranscriptionMenu = tes3ui.registerID("vir_esr:TranscriptionMenu"),

	TranscriptionMenu_nameBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_nameBlock"),
	TranscriptionMenu_nameInput = tes3ui.registerID("vir_esr:TranscriptionMenu_nameInput"),

	TranscriptionMenu_itemsBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_itemsBlock"),
	TranscriptionMenu_sourceBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_sourceBlock"),
	TranscriptionMenu_scrollBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_scrollBlock"),
	TranscriptionMenu_soulBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_soulBlock"),

	TranscriptionMenu_midBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_midBlock"),
	TranscriptionMenu_countChangeBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_countChangeBlock"),
	TranscriptionMenu_countIncreaseButton = tes3ui.registerID("vir_esr:TranscriptionMenu_countIncreaseButton"),
	TranscriptionMenu_countDecreaseButton = tes3ui.registerID("vir_esr:TranscriptionMenu_countDecreaseButton"),
	TranscriptionMenu_countBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_countBlock"),
	TranscriptionMenu_costLabel = tes3ui.registerID("vir_esr:TranscriptionMenu_costLabel"),
	TranscriptionMenu_countLabel = tes3ui.registerID("vir_esr:TranscriptionMenu_countLabel"),

	TranscriptionMenu_infoBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_infoBlock"),
	TranscriptionMenu_soulAmountLabel = tes3ui.registerID("vir_esr:TranscriptionMenu_soulAmountLabel"),
	TranscriptionMenu_goldLabel = tes3ui.registerID("vir_esr:TranscriptionMenu_goldLabel"),
	TranscriptionMenu_chanceLabel = tes3ui.registerID("vir_esr:TranscriptionMenu_chanceLabel"),

	TranscriptionMenu_bottomBlock = tes3ui.registerID("vir_esr:TranscriptionMenu_bottomBlock"),
	TranscriptionMenu_buyButton = tes3ui.registerID("vir_esr:TranscriptionMenu_buyButton"),
	TranscriptionMenu_transcribeButton = tes3ui.registerID("vir_esr:TranscriptionMenu_transcribeButton"),
	TranscriptionMenu_cancelButton = tes3ui.registerID("vir_esr:TranscriptionMenu_cancelButton"),
}

event.register(tes3.event.initialized, function()
	common.palette = {
		headerColor = tes3ui.getPalette(tes3.palette.headerColor),
		disabledColor = tes3ui.getPalette(tes3.palette.disabledColor)
	}
end)

--- @class esrSavedData
--- @field temporaryObjects table<string, string[]> For each objectType, stores the ids of temporaryObjects that will be deleted when no longer needed. See objects\objectCreator.lua
--- @field transcriptions table<string, string> For transcriptions, stores the sourceScroll's id under the created scroll's id. Used to access the original scroll's `text` to display it when activating the scroll.
--- @field decipheredScrolls table<string, string> For scrolls that have been deciphered, stores the spell's idNum under the scroll's id.

--- Shortcut to tes3.player.data.esr, assigned in main.lua
--- @type esrSavedData
common.savedData = nil

--- Shows a tooltip
--- @param text string The text to show in the tooltip
--- @param wrapText boolean? Optional.
function common.tooltip(text, wrapText)
	local tooltip = tes3ui.createTooltipMenu()
	local tooltipText = tooltip:createLabel({ text = text })
	tooltipText.wrapText = wrapText
end

--- Calls tes3ui.leaveMenuMode if the current top menu is MenuMulti.
function common.leaveMenuModeIfNotInMenu()
	local topMenu = tes3ui.getMenuOnTop()
	local multiMenu = tes3ui.findMenu("MenuMulti")

	if (
		topMenu and multiMenu
		and topMenu.id == multiMenu.id
	) then
		tes3ui.leaveMenuMode()
	end
end

--[[
function common.showScrollMenu(text)
	tes3ui.showScrollMenu(text)

	local menu = tes3ui.findMenu("MenuScroll")
	menu:registerAfter(tes3.uiEvent.destroy, function()
		timer.delayOneFrame(common.leaveMenuModeIfNotInMenu, timer.real)
	end)

	return menu
end
 ]]

--- @param spellId string Id of the spell
--- @return string|nil
function common.getIdNumOfDecipheredSpell(spellId)
	spellId = spellId:lower()

	local idNum = string.gsub(spellId, "^vir_esr_dspl_0*", "")
	if idNum == spellId then return end

	return idNum
end

--- @param idNum string
--- @return tes3spell|nil
function common.getDecipheredSpellByIdNum(idNum)
	local decipheredSpellId = string.format("vir_esr_dSpl_%05d", tonumber(idNum))
	return tes3.getObject(decipheredSpellId)
end

--- Finds a new unused id in the form "`baseId`_`idNum`"
--- @param baseId string
--- @return string randomId `baseId`_`idNum`
--- @return string idNum A number in the range [0, 99999], converted to a string.
function common.getRandomId(baseId)
	local randomId, idNum
	repeat
		idNum = tostring(math.random(0, 99999))
		randomId = string.format("%s_%05d", baseId, idNum)
	until not tes3.getObject(randomId)
	return randomId, idNum
end

--- @param enchantment tes3enchantment
--- @return tes3magicEffect|nil
function common.getFirstMagicEffectOnEnchantment(enchantment)
	local effect = enchantment.effects[1]
	return effect and effect.object
end

--- Checks if any of the effects prevent Spellmaking
--- @param enchantmentOrSpell tes3enchantment|tes3spell
--- @return boolean
function common.canUseSpellmaking(enchantmentOrSpell)
	for _, effect in ipairs(enchantmentOrSpell.effects) do
		if effect.object then
			if effect.object.allowSpellmaking == false then
				return false
			end
		end
	end
	return true
end

--- Calculates the magicka cost for a spell, with the same results as in the
--- spellmaking menu. Takes into account the spellmakerAreaEffectCost and
--- spellmakingMatchesEditor MCP features, and the fEffectCostMult GMST.
--- @param enchantmentOrSpell tes3spell|tes3enchantment
--- @return number
function common.calculateMagickaCost(enchantmentOrSpell)
	-- Sources:
		-- https://gitlab.com/OpenMW/openmw/-/wikis/development/research#spell-merchant
		-- https://en.uesp.net/wiki/Morrowind:Spellmakers#Spell_Cost
	local magickaCost = 0
	for _, effect in pairs(enchantmentOrSpell.effects) do
		if effect.object then
			--[[
				local effectCost = 0.5 * (math.max(1, effect.min) + math.max(1, effect.max))
				effectCost = effectCost * 0.1 * effect.object.baseMagickaCost
				effectCost = effectCost * ( 1 + effect.duration )
				effectCost = effectCost + 0.05 * math.max(1, effect.radius) * effect.object.baseMagickaCost

				magickaCost = magickaCost + effectCost * tes3.findGMST(tes3.gmst.fEffectCostMult).value
				magickaCost = math.max(1, magickaCost)
				if effect.rangeType == tes3.effectRange.target then
					magickaCost = magickaCost * 1.5
				end
			]]

			local baseMagickaCost = effect.object.baseMagickaCost
			local min = math.max(1, effect.min)
			local max = math.max(1, effect.max)

			local duration = math.max(1, effect.duration)
			if not tes3.hasCodePatchFeature(tes3.codePatchFeature.spellmakingMatchesEditor) then
				duration = duration + 1
			end

			local radius = effect.radius or 0
			if tes3.hasCodePatchFeature(tes3.codePatchFeature.spellmakerAreaEffectCost) then
				radius = 1 + radius^2 / 400
			end
			if (radius == 0) then
				radius = 1
			end

			local effectCost
			if tes3.hasCodePatchFeature(tes3.codePatchFeature.spellmakerAreaEffectCost) then
				effectCost = math.round(((min + max) * duration * radius) * (baseMagickaCost / 20))
			else
				effectCost = math.round(((min + max) * duration + radius) * (baseMagickaCost / 20))
			end

			common.log:trace("Calculated cost for effect %s, min: %i, max: %i, dur: %i, area: %.2f: %i", effect.object.name, min, max, duration, radius, effectCost)
			magickaCost = magickaCost + effectCost * tes3.findGMST(tes3.gmst.fEffectCostMult).value
			if effect.rangeType == tes3.effectRange.target then
				magickaCost = magickaCost * 1.5
			end
		end
	end
	magickaCost = math.floor(magickaCost)
	-- magickaCost = math.round(magickaCost)

	return math.max(1, magickaCost)
end

--- Sets the effects of the vir_esr_dummySpell to be `effects`, recalculates its
--- magickaCost and returns it. Used for calculating the basePurchaseCost or
--- cast chance of spells we don't want to create yet.
--- @param effects tes3effect[]
--- @return tes3spell
function common.getDummySpell(effects)
	--- @type tes3spell
	local dummySpell = tes3.createObject({
		objectType = tes3.objectType.spell,
		id = "vir_esr_dummySpell",
		sourceless = true
	})

	-- Set the effects
	if effects then
		for i=1, 8 do
			dummySpell.effects[i] = effects[i]
		end

		-- Recalculate magicka cost
		dummySpell.magickaCost = common.calculateMagickaCost(dummySpell)
	end

	return dummySpell
end

--- Returns ( 0.1 * actor.luck + 0.2 * actor.intelligence + npcEnchant ) * npcFatigueTerm
--- @param actor tes3mobileActor
--- @return number
function common.calculateBaseEnchantChanceForActor(actor)
	--[[
		Source: https://gitlab.com/OpenMW/openmw/-/wikis/development/research#enchanted-item-recharge

		luckTerm = 0.1 * luck
		if luckTerm < 1 or luckTerm > 10: luckTerm = 1

		intelligenceTerm = 0.2 * intelligence
		if intelligenceTerm > 20: intelligenceTerm = 20
		if intelligenceTerm < 1: intelligenceTerm = 1

		x = (pcEnchant + intelligenceTerm + luckTerm) * fatigueTerm
		roll 100, success if roll < x
		on success restore charge: soulgem charge * (roll / x)
	]]

	local npcLuck = math.clamp(0.1 * actor.luck.current, 1, 10)
	local npcIntelligence = math.clamp(0.2 * actor.intelligence.current, 1, 20)
	local npcEnchant = actor:getSkillValue(tes3.skill.enchant)
	local npcFatigueTerm = actor:getFatigueTerm()
	return ( npcLuck + npcIntelligence + npcEnchant ) * npcFatigueTerm
end

--- Checks if the npc offers the recharge and transcription services
--- @param object tes3npc|tes3npcInstance
--- @return boolean
local function offersRechargeAndTranscription(object)
	local aiConfig = object.aiConfig
	return (
		aiConfig.offersEnchanting
		and not aiConfig.offersRepairs
		and aiConfig.bartersEnchantedItems
	)
end

--- Checks if the npc offers the recharge service
--- @param object tes3npc|tes3npcInstance
--- @param checkConfig boolean? Default: `true`. If `false`, config black/whitelist wont be checked
--- @return boolean
function common.offersRecharge(object, checkConfig)
	local baseObject = object.baseObject or object
	local id = baseObject.id:lower()
	if checkConfig ~= false and common.config.recharge.offerers[id] ~= nil then
		common.log:debug("Recharge: Found value %s in config for %s, returning", common.config.recharge.offerers[id], id)
		return common.config.recharge.offerers[id]
	else
		return offersRechargeAndTranscription(object)
	end
end

--- Checks if the npc offers the transcription service
--- @param object tes3npc|tes3npcInstance
--- @param checkConfig boolean? Default: `true`. If `false`, config black/whitelist wont be checked
--- @return boolean
function common.offersTranscription(object, checkConfig)
	local baseObject = object.baseObject or object
	local id = baseObject.id:lower()
	if checkConfig ~= false and common.config.transcription.offerers[id] ~= nil then
		common.log:debug("Transcription: Found value %s in config for %s, returning", common.config.transcription.offerers[id], id)
		return common.config.transcription.offerers[id]
	else
		return offersRechargeAndTranscription(object)
	end
end

--- Checks if the npc offers the deciphering service
--- @param object tes3npc|tes3npcInstance
--- @param checkConfig boolean? Default: `true`. If `false`, config black/whitelist wont be checked
--- @return boolean
function common.offersDeciphering(object, checkConfig)
	local baseObject = object.baseObject or object
	local id = baseObject.id:lower()
	if checkConfig ~= false and common.config.deciphering.offerers[id] ~= nil then
		common.log:debug("Deciphering: Found value %s in config for %s, returning", common.config.deciphering.offerers[id], id)
		return common.config.deciphering.offerers[id]
	else
		local aiConfig = object.aiConfig
		return (
			aiConfig.offersSpellmaking
			and not aiConfig.offersRepairs
			and not offersRechargeAndTranscription(object)
		)
	end
end

--- Checks if the npc should have blank scrolls added to
--- @param object tes3npc|tes3npcInstance
--- @param checkConfig boolean? Default: `true`. If `false`, config black/whitelist wont be checked
--- @return boolean
function common.bartersBlankScrolls(object, checkConfig)
	local baseObject = object.baseObject or object
	local id = baseObject.id:lower()
	if checkConfig ~= false and common.config.itemAdditions.blankScrolls.barterers[id] ~= nil then
		common.log:debug("bartersBlankScrolls: Found value %s in config for %s, returning", common.config.itemAdditions.blankScrolls.barterers[id], id)
		return common.config.itemAdditions.blankScrolls.barterers[id]
	else
		local aiConfig = object.aiConfig
		if aiConfig and aiConfig.bartersBooks then
			if object.class and string.multifind(object.class.id:lower(), common.config.itemAdditions.blankScrolls.classPattern) then
				return true
			end
		end
	end
	return false
end

return common