local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("teleportToAkamora", 293)
tes3.claimSpellEffectId("teleportToFirewatch", 294)
tes3.claimSpellEffectId("teleportToHelnim", 295)
tes3.claimSpellEffectId("teleportToNecrom", 296)
tes3.claimSpellEffectId("teleportToOldEbonheart", 297)
tes3.claimSpellEffectId("teleportToPortTelvannis", 298)

tes3.claimSpellEffectId("teleportToAltBosara", 299)
tes3.claimSpellEffectId("teleportToBalOrya", 300)
tes3.claimSpellEffectId("teleportToGahSadrith", 301)
tes3.claimSpellEffectId("teleportToGorne", 302)
tes3.claimSpellEffectId("teleportToLlothanis", 303)
tes3.claimSpellEffectId("teleportToMarog", 304)
tes3.claimSpellEffectId("teleportToMeralag", 305)
tes3.claimSpellEffectId("teleportToTelAranyon", 306)
tes3.claimSpellEffectId("teleportToTelMothrivra", 307)
tes3.claimSpellEffectId("teleportToTelMuthada", 308)
tes3.claimSpellEffectId("teleportToTelOuada", 309)


local function getDescription(location)
    return "This effect teleports subject to ".. location .."."
end
local function addTeleportationEffects()
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToAkamora,
		name = "Teleport To Akamora",
		description = getDescription("Akamora"),
		baseCost = 150,
		positionCell = {
			position = { 249793, -90523, 3039},
			orientation = { x=0, y=0, z=349},
			cell = "Akamora"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToFirewatch,
		name = "Teleport To Firewatch",
		description = getDescription("Firewatch"),
		baseCost = 150,
		positionCell = {
			position = { 150453, 126079, 510},
			orientation = { x=0, y=0, z=0},
			cell = "Firewatch"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToHelnim,
		name = "Teleport To Helnim",
		description = getDescription("Helnim"),
		baseCost = 150,
		positionCell = {
			position = { 215604, 9145, 647},
			orientation = { x=0, y=0, z=291},
			cell = "Helnim"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToNecrom,
		name = "Teleport To Necrom",
		description = getDescription("Necrom"),
		baseCost = 150,
		positionCell = {
			position = { 342132, -85025, 1310},
			orientation = { x=0, y=0, z=92},
			cell = "Necrom"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToOldEbonheart,
		name = "Teleport To Old Ebonheart",
		description = getDescription("Old Ebonheart"),
		baseCost = 150,
		positionCell = {
			position = { 57948, -155684, 710},
			orientation = { x=0, y=0, z=0},
			cell = "Old Ebonheart"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToPortTelvannis,
		name = "Teleport To Port Telvannis",
		description = getDescription("Port Telvannis"),
		baseCost = 150,
		positionCell = {
			position = { 343425, 132953, 257},
			orientation = { x=0, y=0, z=297},
			cell = "Port Telvannis"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToAltBosara,
		name = "Teleport To Alt Bosara",
		description = getDescription("Alt Bosara"),
		baseCost = 150,
		positionCell = {
			position = { 299317, -33706, 1111},
			orientation = { x=0, y=0, z=69},
			cell = "Alt Bosara"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToBalOrya,
		name = "Teleport To Bal Orya",
		description = getDescription("Bal Orya"),
		baseCost = 150,
		positionCell = {
			position = { 154938, 196334, 302},
			orientation = { x=0, y=0, z=320},
			cell = "Bal Orya"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToGahSadrith,
		name = "Teleport To Gah Sadrith",
		description = getDescription("Gah Sadrith"),
		baseCost = 150,
		positionCell = {
			position = { 344677, 112667, 941},
			orientation = { x=0, y=0, z=92},
			cell = "Gah Sadrith"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToGorne,
		name = "Teleport To Gorne",
		description = getDescription("Gorne"),
		baseCost = 150,
		positionCell = {
			position = { 334020, -239395, 444},
			orientation = { x=0, y=0, z=92},
			cell = "Gorne"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToLlothanis,
		name = "Teleport To Llothanis",
		description = getDescription("Llothanis"),
		baseCost = 150,
		positionCell = {
			position = { 263895, 86714, 258},
			orientation = { x=0, y=0, z=97},
			cell = "Llothanis"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToMarog,
		name = "Teleport To Marog",
		description = getDescription("Morag"),
		baseCost = 150,
		positionCell = {
			position = { 192921, -15703, 1627},
			orientation = { x=0, y=0, z=303},
			cell = "Marog"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToMeralag,
		name = "Teleport To Meralag",
		description = getDescription("Meralag"),
		baseCost = 150,
		positionCell = {
			position = { 211327, -179157, 305},
			orientation = { x=0, y=0, z=0},
			cell = "Meralag"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToTelAranyon,
		name = "Teleport To Tel Aranyon",
		description = getDescription("Tel Aranyon"),
		baseCost = 150,
		positionCell = {
			position = { 232546, 102444, 3366},
			orientation = { x=0, y=0, z=90},
			cell = "Tel Aranyon"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToTelMothrivra,
		name = "Teleport To Tel Mothrivra",
		description = getDescription("Tel Mothrivra"),
		baseCost = 150,
		positionCell = {
			position = { 277984, 22615, 1160},
			orientation = { x=0, y=0, z=270},
			cell = "Tel Mothrivra"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToTelMuthada,
		name = "Teleport To Tel Muthada",
		description = getDescription("Tel Muthada"),
		baseCost = 150,
		positionCell = {
			position = { 221231, -37731, 2995},
			orientation = { x=0, y=0, z=46},
			cell = "Tel Muthada"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToTelOuada,
		name = "Teleport To Tel Ouada",
		description = getDescription("Tel Ouada"),
		baseCost = 150,
		positionCell = {
			position = { 210154, 147991, 246},
			orientation = { x=0, y=0, z=303},
			cell = "Tel Ouada"
		}
	})
end

event.register("magicEffectsResolved", addTeleportationEffects)