--[[
Configure settings for Unofficial TR spells here 
- adjusting magicka cost of spell effects,
- Blink VFX config
- Toggle Illegal Daedra
- Bound items Behavior
]]

--[[ Magicka cost of spell effects
OpenMW has an engine feature where spell effects cost more than in MWSE
The formulas for the spell effects in this mod are implemented as closely as possible,
but if you're coming from MWSE and are surprised as the difference in spell costs you can
change them here
]]

GLOBAL_EFFECT_COST_MULT = 1

EFFECT_COST_INSIGHT = 10
EFFECT_COST_ARMOR_RESARTUS = 60
EFFECT_COST_WEAPON_RESARTUS = 120
EFFECT_COST_BANISH_DAE = 128
EFFECT_COST_REFLECT = 20
EFFECT_COST_RADIANT_SHIELD = 5
EFFECT_COST_BLINK = 10
EFFECT_COST_PASSWALL = 750
EFFECT_COST_DISTRACT_CREATURE = 0.5
EFFECT_COST_DISTRACT_HUMANOID = 1
EFFECT_COST_FORTCAST = 12

--[[ Blink VFX
There are a few presets for Blink VFX to help you not teleport into walls
and need to use the tcl console command to get out
But if you want to change the vfx you can do that here.
To disable the blink preview VFX, set BLINK_PREVIEW_VFX_PRESET to 0.
]]
if isPlayer then
	
	BLINK_PREVIEW_VFX_PRESET = 2 -- 0 to disable, 1 for testing, 2 for the orb + smoke + circle (default), 3 for default but with a different ground circle
	
	if BLINK_PREVIEW_VFX_PRESET == 0 then
	
		BLINK_PREVIEW_VFX_MODEL = nil
		BLINK_PREVIEW_VFX_MODEL = nil
		BLINK_PREVIEW_VFX_OFFSET = nil
		BLINK_PREVIEW_VFX_SCALE = nil
		
	elseif BLINK_PREVIEW_VFX_PRESET == 1 then
	
		BLINK_PREVIEW_VFX_MODEL = "meshes/tr_spells/blink_pillar.NIF"
		BLINK_PREVIEW_VFX_MODEL = "meshes/tr_spells/blink_pillar2.NIF"
		BLINK_PREVIEW_VFX_OFFSET = v3(0,0,-0)
		BLINK_PREVIEW_VFX_SCALE = 0.55
	
	elseif BLINK_PREVIEW_VFX_PRESET == 2 then
	
		BLINK_PREVIEW_VFX_MODEL = "meshes/w/magic_target_myst.NIF"
		BLINK_PREVIEW_VFX_OFFSET = v3(0,0,130)
		BLINK_PREVIEW_VFX_OFFSET_GROUND = v3(0,0,114)
		BLINK_PREVIEW_VFX_SCALE = 1
		
		BLINK_PREVIEW_VFX_MODEL2 = "meshes/e/magic_cast_restore.NIF"
		BLINK_PREVIEW_VFX_OFFSET2 = v3(0,0,0)
		BLINK_PREVIEW_VFX_SCALE2 = 1
		
	elseif BLINK_PREVIEW_VFX_PRESET == 3 then -- same as 2 but with different ground circle
	
		BLINK_PREVIEW_VFX_MODEL = "meshes/w/magic_target_myst.NIF"
		BLINK_PREVIEW_VFX_OFFSET = v3(0,0,130)
		BLINK_PREVIEW_VFX_OFFSET_GROUND = v3(0,0,114)
		BLINK_PREVIEW_VFX_SCALE = 1
		
		BLINK_PREVIEW_VFX_MODEL2 = "meshes/e/magic_cast_alt.NIF"
		BLINK_PREVIEW_VFX_OFFSET2 = v3(0,0,0)
		BLINK_PREVIEW_VFX_SCALE2 = 1
	end
end

--[[ Illegal Daedra
In MWSE and in the summon spells' magic effect description, it is illegal to summon deadra in towns.
But for testing and for fun, illegal summoning wasn't shipped with this mod's initial release.
You can toggle it on here - false = off, true = on
]]

ILLEGAL_DAEDRA_TOGGLE = false

--[[ Bound Items
This mod has its own implementation of the Tamriel Data Bound armor and weapons
but can be extended to also apply to vanilla Bound items as well.
Disabled by default for compatibility with other mods altering vanilla Bound items.

BOUND_VANILLA_PATCH - Vanilla bound item spell effects will be handled by this mod - false = off, true = on
BOUND_SCALING_ENABLED - Scale Bound items with the below formulas. false = off, true = on
BOUND_DAMAGE/ARMOR/ENCHANT_BASE - From your Conjuration skill (starting from 0), increased % on the source record's stats
BOUND_DAMAGE/ARMOR/ENCHANT_PER_LEVEL - Increase damage, armor, and enchantment strength per point of conjuration,
  additive to the base %. Example: with settings at 40 and 0.7 you get 120% at lvl 100
BOUND_WEIGHT_BASE/REDUCTION_PER_LEVEL - Change the weight for Bound items here, based on conjuration/enchantment skill.
  Example: with BOUND_WEIGHT_BASE at 40 and BOUND_WEIGHT_REDUCTION_PER_LEVEL at 0.5, the items become weightless at lvl 80
  BOUND_SCALING_ENABLED must be set to true.
]]

BOUND_VANILLA_PATCH = false 
BOUND_SCALING_ENABLED = false
BOUND_DAMAGE_BASE = 50 -- %
BOUND_ARMOR_BASE = 50 -- %
BOUND_ENCHANT_BASE = 50 -- %
BOUND_DAMAGE_BONUS_PER_LEVEL  = 0.7  -- %
BOUND_ARMOR_BONUS_PER_LEVEL   = 0.7  -- %
BOUND_ENCHANT_BONUS_PER_LEVEL = 0.7  -- %
BOUND_WEIGHT_BASE = 40 -- %
BOUND_WEIGHT_REDUCTION_PER_LEVEL = 0.5 -- %