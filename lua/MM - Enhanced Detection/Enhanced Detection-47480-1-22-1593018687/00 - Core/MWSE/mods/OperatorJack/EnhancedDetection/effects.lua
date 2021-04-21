local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("detectDaedra", 336)
tes3.claimSpellEffectId("detectAutomaton", 337)
tes3.claimSpellEffectId("detectHumanoid", 338)
tes3.claimSpellEffectId("detectDead", 339)
tes3.claimSpellEffectId("detectUndead", 340)
tes3.claimSpellEffectId("detectDoor", 341)
tes3.claimSpellEffectId("detectTrap", 342)

local effectVfx = {
	animal = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
	key = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
	enchantment = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
	daedra = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
	automaton = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
	humanoid = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
	dead = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
	undead = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
	door = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
	trap = {
		castVFX = "VFX_MysticismCast",
		hitVFX = "VFX_MysticismHit",
	},
}

local particleTexture = "vfx_myst_flare01.tga"

local staticIds = {
	animalCast = "VFX_OJ_ED_AnimalCast",
	animalHit = "VFX_OJ_ED_AnimalHit",
	keyCast = "VFX_OJ_ED_KeyCast",
	keyHit = "VFX_OJ_ED_KeyHit",
	enchantmentCast = "VFX_OJ_ED_EnchantmentCast",
	enchantmentHit = "VFX_OJ_ED_EnchantmentHit",
	daedricCast = "VFX_OJ_ED_DaedraCast",
	daedricHit = "VFX_OJ_ED_DaedraHit",
	automatonCast = "VFX_OJ_ED_AutomatonCast",
	automatonHit = "VFX_OJ_ED_AutomatonHit",
	humanoidCast = "VFX_OJ_ED_HumanoidCast",
	humanoidHit = "VFX_OJ_ED_HumanoidHit",
	deadCast = "VFX_OJ_ED_DeadCast",
	deadHit = "VFX_OJ_ED_DeadHit",
	undeadCast = "VFX_OJ_ED_UndeadCast",
	undeadHit = "VFX_OJ_ED_UndeadHit",
	doorCast = "VFX_OJ_ED_DoorCast",
	doorHit = "VFX_OJ_ED_DoorHit",
	trapCast = "VFX_OJ_ED_TrapCast",
	trapHit = "VFX_OJ_ED_TrapHit",
}
local statics = {
    [staticIds.animalCast] = "EditorMarker.nif",
    [staticIds.animalHit] = "OJ\\ED\\hit\\ED_H_Animal.nif",
    [staticIds.keyCast] = "EditorMarker.nif",
    [staticIds.keyHit] = "OJ\\ED\\hit\\ED_H_Key.nif",
    [staticIds.enchantmentCast] = "EditorMarker.nif",
    [staticIds.enchantmentHit] = "OJ\\ED\\hit\\ED_H_Enchant.nif",
    [staticIds.daedricCast] = "EditorMarker.nif",
    [staticIds.daedricHit] = "OJ\\ED\\hit\\ED_H_Daedra.nif",
    [staticIds.automatonCast] = "EditorMarker.nif",
    [staticIds.automatonHit] = "OJ\\ED\\hit\\ED_H_Automaton.nif",
    [staticIds.humanoidCast] = "EditorMarker.nif",
    [staticIds.humanoidHit] = "OJ\\ED\\hit\\ED_H_Humanoid.nif",
    [staticIds.deadCast] = "EditorMarker.nif",
    [staticIds.deadHit] = "OJ\\ED\\hit\\ED_H_Dead.nif",
    [staticIds.undeadCast] = "EditorMarker.nif",
    [staticIds.undeadHit] = "OJ\\ED\\hit\\ED_H_Undead.nif",
    [staticIds.doorCast] = "EditorMarker.nif",
    [staticIds.doorHit] = "OJ\\ED\\hit\\ED_H_Door.nif",
    [staticIds.trapCast] = "EditorMarker.nif",
    [staticIds.trapHit] = "OJ\\ED\\hit\\ED_H_Trap.nif",
}

local function addMagicEffects()
    if tes3.getFileExists("meshes\\OJ\\ED\\hit\\ED_H_Animal.nif") == true then
		for id, mesh in pairs(statics) do
			if (tes3.getObject(id) == nil) then
				if (tes3.getFileExists("meshes\\" .. mesh) == true) then
					tes3.createObject({
						objectType = tes3.objectType.static,
						id = id,
						mesh = mesh
					})
				else
					print("[Enhanced Detection: ERROR] Static " .. id .. " missing mesh at path " .. mesh)
					return
				end
			end
		end

		particleTexture = "\\OJ\\ED\\md_rfd_kurp\\Blank.dds"

		effectVfx = {
			animal = {
				castVFX = staticIds.animalCast,
				hitVFX = staticIds.animalHit,
			},
			key = {
				castVFX = staticIds.keyCast,
				hitVFX = staticIds.keyHit,
			},
			enchantment = {
				castVFX = staticIds.enchantmentCast,
				hitVFX = staticIds.enchantmentHit,
			},
			daedra = {
				castVFX = staticIds.daedricCast,
				hitVFX = staticIds.daedricHit,
			},
			automaton = {
				castVFX = staticIds.automatonCast,
				hitVFX = staticIds.automatonHit,
			},
			humanoid = {
				castVFX = staticIds.humanoidCast,
				hitVFX = staticIds.humanoidHit,
			},
			dead = {
				castVFX = staticIds.deadCast,
				hitVFX = staticIds.deadHit,
			},
			undead = {
				castVFX = staticIds.undeadCast,
				hitVFX = staticIds.undeadHit,
			},
			door = {
				castVFX = staticIds.doorCast,
				hitVFX = staticIds.doorHit,
			},
			trap = {
				castVFX = staticIds.trapCast,
				hitVFX = staticIds.trapHit,
			},
		}	

		for effectType , pair in pairs(effectVfx) do
			for vfxType, staticId in pairs(pair) do
				if (tes3.getObject(staticId) == nil) then
					print("[Enhanced Detection: ERROR] Static " .. staticId .. " failed to be created for effect type " .. effectType)
					return
				end
			end
		end
			
		print("[Enhanced Detection: INFO] Optional VFX Initialized.")	
	end

	local animalEffect = tes3.getMagicEffect(tes3.effect.detectAnimal)
	animalEffect.castVisualEffect = tes3.getObject(effectVfx.animal.castVFX)
	animalEffect.hitVisualEffect = tes3.getObject(effectVfx.animal.hitVFX)
	animalEffect.particleTexture = particleTexture
	animalEffect.icon = "RFD\\ED_RFD_icon_animal.dds"

	local keyEffect = tes3.getMagicEffect(tes3.effect.detectKey)
	keyEffect.castVisualEffect = tes3.getObject(effectVfx.key.castVFX)
	keyEffect.hitVisualEffect = tes3.getObject(effectVfx.key.hitVFX)
	keyEffect.particleTexture = particleTexture
	keyEffect.icon = "RFD\\ED_RFD_icon_key.dds"

	local enchantmentEffect = tes3.getMagicEffect(tes3.effect.detectEnchantment)
	enchantmentEffect.castVisualEffect = tes3.getObject(effectVfx.enchantment.castVFX)
	enchantmentEffect.hitVisualEffect = tes3.getObject(effectVfx.enchantment.hitVFX)
	enchantmentEffect.particleTexture = particleTexture
	enchantmentEffect.icon = "RFD\\ED_RFD_icon_enchant.dds"
	
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.detectDaedra,
		name = "Detect Daedra",
		description = "Allows the caster of this effect to detect any daedra. The magnitude is the range in feet from the caster that daedra are detected.",

		-- Basic dials.
		baseCost = 1,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,

		-- Graphics/sounds.
		lighting = { 0.99, 0.95, 0.67 },
		castVFX = effectVfx.daedra.castVFX,
		hitVFX = effectVfx.daedra.hitVFX,
		icon = "RFD\\ED_RFD_icon_daedra.dds",
		particleTexture = particleTexture,

		-- Required callbacks.
		onTick = function(e) e:trigger() end,
  })
  
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.detectAutomaton,
		name = "Detect Automaton",
		description = "Allows the caster of this effect to detect any automaton. The magnitude is the range in feet from the caster that automaton are detected.",

		-- Basic dials.
		baseCost = 1,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,

		-- Graphics/sounds.
		lighting = { 0.99, 0.95, 0.67 },
		castVFX = effectVfx.automaton.castVFX,
		hitVFX = effectVfx.automaton.hitVFX,
		icon = "RFD\\ED_RFD_icon_automaton.dds",
		particleTexture = particleTexture,

		-- Required callbacks.
		onTick = function(e) e:trigger() end,
	})
  
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.detectHumanoid,
		name = "Detect Humanoid",
		description = "Allows the caster of this effect to detect any humanoid. The magnitude is the range in feet from the caster that humanoids are detected.",

		-- Basic dials.
		baseCost = 0.75,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,

		-- Graphics/sounds.
		lighting = { 0.99, 0.95, 0.67 },
		castVFX = effectVfx.humanoid.castVFX,
		hitVFX = effectVfx.humanoid.hitVFX,
		icon = "RFD\\ED_RFD_icon_humanoid.dds",
		particleTexture = particleTexture,

		-- Required callbacks.
		onTick = function(e) e:trigger() end,
	})
  
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.detectDead,
		name = "Detect Dead",
		description = "Allows the caster of this effect to detect any dead beings. The magnitude is the range in feet from the caster that they are detected.",

		-- Basic dials.
		baseCost = 0.75,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,

		-- Graphics/sounds.
		lighting = { 0.99, 0.95, 0.67 },
		castVFX = effectVfx.dead.castVFX,
		hitVFX = effectVfx.dead.hitVFX,
		icon = "RFD\\ED_RFD_icon_dead.dds",
		particleTexture = particleTexture,

		-- Required callbacks.
		onTick = function(e) e:trigger() end,
	})
  
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.detectUndead,
		name = "Detect Undead",
		description = "Allows the caster of this effect to detect any undead beings. The magnitude is the range in feet from the caster that they are detected.",

		-- Basic dials.
		baseCost = 0.75,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,

		-- Graphics/sounds.
		lighting = { 0.99, 0.95, 0.67 },
		castVFX = effectVfx.undead.castVFX,
		hitVFX = effectVfx.undead.hitVFX,
		icon = "RFD\\ED_RFD_icon_undead.dds",
		particleTexture = particleTexture,

		-- Required callbacks.
		onTick = function(e) e:trigger() end,
	})
  
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.detectDoor,
		name = "Detect Door",
		description = "Allows the caster of this effect to detect doors. The magnitude is the range in feet from the caster that they are detected.",

		-- Basic dials.
		baseCost = 1,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,

		-- Graphics/sounds.
		lighting = { 0.99, 0.95, 0.67 },
		castVFX = effectVfx.door.castVFX,
		hitVFX = effectVfx.door.hitVFX,
		icon = "RFD\\ED_RFD_icon_door.dds",
		particleTexture = particleTexture,

		-- Required callbacks.
		onTick = function(e) e:trigger() end,
	})
  
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.detectTrap,
		name = "Detect Trap",
		description = "Allows the caster of this effect to detect traps. The magnitude is the range in feet from the caster that they are detected.",

		-- Basic dials.
		baseCost = 1,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,

		-- Graphics/sounds.
		lighting = { 0.99, 0.95, 0.67 },
		castVFX = effectVfx.trap.castVFX,
		hitVFX = effectVfx.trap.hitVFX,
		icon = "RFD\\ED_RFD_icon_trap.dds",
		particleTexture = particleTexture,

		-- Required callbacks.
		onTick = function(e) e:trigger() end,
	})
end

event.register("magicEffectsResolved", addMagicEffects)