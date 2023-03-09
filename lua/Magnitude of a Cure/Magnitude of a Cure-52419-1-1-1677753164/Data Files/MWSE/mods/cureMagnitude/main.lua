local common = require("cureMagnitude.common")
local edit = require("cureMagnitude.edit")

event.register("modConfigReady", function()
    require("cureMagnitude.mcm")
	common.config  = require("cureMagnitude.config")
end)


local function onSpellTooltipDrawn(e)
	local outerBlock = e.tooltip:findChild('effect')
	for _, eff in pairs(outerBlock.children) do
		local innerBlock = eff:findChild('effect')
		if innerBlock then
			local effectLabel = innerBlock.children[2].children[1]
			if effectLabel then
				edit.effectLabel(effectLabel)
			end
		end
	end
end

local function onTooltipDrawn(e)
	local main = e.tooltip:findChild('PartHelpMenu_main')
	for _, block in pairs(main.children) do
		local effectLabel = block:findChild('HelpMenu_effectLabel')
		if effectLabel then
			edit.effectLabel(effectLabel)
		else
			local effectLabel = block:findChild('HelpMenu_enchantEffectLabel')
			if effectLabel then
				edit.effectLabel(effectLabel)
			end
		end
	end
end

local function onSpellTick(e)
	if not common.cureEffects[e.effectId] then return end

	--local chance = math.random(1, 100)
	local instance = e.effectInstance
	local magnitude = common.getMagnitudeFromSource(e.source, e.effectId)

	if instance.state == 4 then
		if e.effectId == tes3.effect.cureCommonDisease then
			tes3.removeEffects{
				reference = e.target,
				castType = tes3.spellType.disease,
				chance = magnitude
			}
		elseif e.effectId == tes3.effect.cureBlightDisease then
			tes3.removeEffects{
				reference = e.target,
				castType = tes3.spellType.blight,
				chance = magnitude
			}
		elseif e.effectId == tes3.effect.curePoison then
			tes3.removeEffects{
				reference = e.target,
				effect = tes3.effect.poison,
				chance = magnitude
			}
		elseif e.effectId == tes3.effect.cureParalyzation then
			tes3.removeEffects{
				reference = e.target,
				effect = tes3.effect.paralyze,
				chance = magnitude
			}
		end
	end
	return false
end

-- local function onLoaded(e)
-- 	common.init()
-- 	edit.effects()
-- 	edit.objects()
-- end

local function onInitialized(e)
	if common.config.modEnabled then
		mwse.log(string.format("[%s]: enabled", common.dictionary.modName))
		event.register("spellTick", onSpellTick)
		event.register("uiObjectTooltip", onTooltipDrawn)
		event.register("uiSpellTooltip", onSpellTooltipDrawn)
		event.register("uiActivated", edit.onMenuAlchemy, {filter = "MenuAlchemy"})
		--event.register("loaded", onLoaded)
		common.init()
		edit.effects()
		edit.objects()
	else
		mwse.log(string.format("[%s]: disabled", common.dictionary.modName))
	end
end

event.register("initialized", onInitialized)