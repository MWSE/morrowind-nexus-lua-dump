local magickaExpanded = include("OperatorJack.MagickaExpanded.magickaExpanded")

-- ID of the Eye amulet enchantement that the MExp one will replace. Needs to exist in the esp, have two effects, the first one will be replaced and be permament on self.
local wideEyeAmuletEnchantment = "_TT_WideEye_en"

tes3.claimSpellEffectId("forbidSleep", 1201)

local forbidSleepEffect
local isAffectedByForbidSleep

local function addForbidSleepMagicEffect()
	forbidSleepEffect = magickaExpanded.effects.mysticism.createBasicEffect({
		id = tes3.effect.forbidSleep,
		name = "Forbid Sleep",
		description = "Prevents the target from resting for the duration.",

		baseCost = 20.0,
		speed = 2.0,

		allowEnchanting = true,
		appliesOnce = true,
		canCastTarget = true,
		hasNoDuration = false,
		hasNoMagnitude = true,

		onTick = function(e) e:trigger() end,

	})
end

local function onUiShowRestMenu(e)
	isAffectedByForbidSleep = tes3.isAffectedBy({
        reference = tes3.player,
        effect = tes3.effect.forbidSleep
    })
	if isAffectedByForbidSleep then
		
		e.allowRest = false
		e.scripted = true
	end
end

local function onMenuRestWaitOpen(e)
	if isAffectedByForbidSleep then
		local GUI_MenuRestWait = tes3ui.findMenu(tes3ui.registerID("MenuRestWait"))
		local GUI_MenuRestWait_label_text = GUI_MenuRestWait:findChild(tes3ui.registerID("MenuRestWait_label_text"))
		GUI_MenuRestWait_label_text.text = "No matter how tired you are, you are unable to fall asleep."
	end
end

local function registerEnchantments()
	magickaExpanded.enchantments.createBasicEnchantment({
	  id = wideEyeAmuletEnchantment,
	  effect = tes3.effect.forbidSleep,
	  range = tes3.effectRange.self,
	  castType = tes3.enchantmentType.constant
	})
  end

event.register("uiShowRestMenu", onUiShowRestMenu)
event.register("uiActivated", onMenuRestWaitOpen, { filter = "MenuRestWait"})
event.register("magicEffectsResolved", addForbidSleepMagicEffect)
event.register("MagickaExpanded:Register", registerEnchantments)