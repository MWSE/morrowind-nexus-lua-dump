local common = {}

common.config = require("Virnetch.ShrineTooltips.config")
common.defaultConfig = require("Virnetch.ShrineTooltips.defaultConfig")
common.i18n = mwse.loadTranslations("Virnetch.ShrineTooltips")

common.mod = {}
common.mod.version = "2.0.1"
common.mod.name = common.i18n("mod.name")

local logger = require("logging.logger")
common.log = logger.new({
	name = "Shrine Tooltips",
	logLevel = common.config.logLevel
})

common.GUI_ID = {
	MenuMessage_button_layout = tes3ui.registerID("MenuMessage_button_layout"),

	shrineTooltipBlock = tes3ui.registerID("vir_shrineTooltips:shrineTooltipBlock"),
	shrineTooltipEffectBlock = tes3ui.registerID("vir_shrineTooltips:shrineTooltipEffectBlock"),
	shrineTooltipEffectIcon = tes3ui.registerID("vir_shrineTooltips:shrineTooltipEffectIcon"),
	shrineTooltipEffectText = tes3ui.registerID("vir_shrineTooltips:shrineTooltipEffectText")
}

--- True if the player activated a shrine this frame. Required for a message box to have the tooltips
--- @type boolean
common.activatingShrine = false

common.effects = {}

--- Adds a spell tooltip when hovering over the element
--- @param element tes3uiElement
--- @param spell tes3spell
function common.addSpellTooltipToElement(element, spell)
	if not element then
		common.log:error("common.addSpellTooltipToElement: Missing element param")
		return
	end

	if not spell then
		common.log:error("common.addSpellTooltipToElement: Missing spell param")
		return
	end

	if common.config.detailedTooltip then
		element:register(tes3.uiEvent.help, function()
			common.log:debug("Showing tooltipMenu for spell %s", spell.id)
			tes3ui.createTooltipMenu({
				spell = spell
			})
		end)
	else
		local texts = {}
		local icons = {}
		for i, effect in ipairs(spell.effects) do
			if effect.object then
				texts[i] = effect.object.name
				icons[i] = effect.object.icon
				if spell.effects[i].attribute ~= -1 then
					-- Get the attribute's name that this effect modifies, uppercase first letter if it's lowercase
					local targetAttribute = string.gsub(tes3.getAttributeName(effect.attribute), "^%l", string.upper)

					-- Replace "Attribute" with the attribute name.
					-- First try to figure out what "Attribute" is in the language by getting the last word from "Restore Attribute" gmst.
					local previousText = texts[i]
					local sAttribute = string.match(tes3.findGMST(tes3.gmst.sEffectRestoreAttribute).value, "%S+$")
					if sAttribute then
						texts[i] = string.gsub(texts[i], sAttribute, targetAttribute)
					end

					-- Otherwise default to replacing "Attribute"
					if previousText == texts[i] then
						texts[i] = string.gsub(texts[i], "Attribute", targetAttribute)
					end
				elseif spell.effects[i].skill ~= -1 then
					-- Get the skill's name that this effect modifies, uppercase first letter if it's lowercase
					local targetSkill = string.gsub(tes3.getSkillName(effect.skill), "^%l", string.upper)

					-- Replace "Skill" with the skill name.
					local sSkill = tes3.findGMST(tes3.gmst.sSkill).value
					texts[i] = string.gsub(texts[i], sSkill, targetSkill)
				end
			end
		end

		if texts[1] then
			element:register(tes3.uiEvent.help, function()
				common.log:debug("Showing simple tooltipMenu for spell %s", spell.id)
				local tooltip = tes3ui.createTooltipMenu()
				local tooltipBlock = tooltip:createBlock({ id = common.GUI_ID.shrineTooltipBlock })
				tooltipBlock.autoWidth = true
				tooltipBlock.autoHeight = true
				tooltipBlock.flowDirection = "top_to_bottom"

				for i=1, #texts do
					local effectBlock = tooltipBlock:createBlock({ id = common.GUI_ID.shrineTooltipEffectBlock })
					effectBlock.autoWidth = true
					effectBlock.autoHeight = true
					effectBlock.flowDirection = "left_to_right"
					effectBlock.borderAllSides = 1

					if icons[i] then
						local icon = effectBlock:createImage({
							id = common.GUI_ID.shrineTooltipEffectIcon,
							path = "icons\\"..icons[i]
						})
						icon.borderRight = 4
						icon.borderTop = 1
					end

					effectBlock:createLabel({
						id = common.GUI_ID.shrineTooltipEffectText,
						text = texts[i]
					})
				end
			end)
		end
	end
end

return common