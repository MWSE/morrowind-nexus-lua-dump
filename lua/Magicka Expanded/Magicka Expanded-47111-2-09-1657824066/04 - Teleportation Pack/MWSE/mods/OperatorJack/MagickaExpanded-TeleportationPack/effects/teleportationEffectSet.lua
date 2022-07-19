local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

-- Capitals
tes3.claimSpellEffectId("teleportToAldRuhn", 241)
tes3.claimSpellEffectId("teleportToBalmora", 242)
tes3.claimSpellEffectId("teleportToEbonheart", 243)
tes3.claimSpellEffectId("teleportToVivec", 244)

-- Towns
tes3.claimSpellEffectId("teleportToCaldera", 245)
tes3.claimSpellEffectId("teleportToGnisis", 246)
tes3.claimSpellEffectId("teleportToMaarGan", 247)
tes3.claimSpellEffectId("teleportToMolagMar", 248)
tes3.claimSpellEffectId("teleportToPelagiad", 249)
tes3.claimSpellEffectId("teleportToSuran", 250)
tes3.claimSpellEffectId("teleportToTelMora", 251)

-- Other
tes3.claimSpellEffectId("teleportToMournhold", 310)


local function getDescription(location)
    return "This effect teleports subject to ".. location .."."
end
local function addTeleportationEffects()
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToMournhold,
		name = "Teleport To Mournhold",
		description = getDescription("Mournhold"),
		baseCost = 150,
		positionCell = {
			position = { -4, 3170, 199},
			orientation = { x=0, y=0, z=0},
			cell = "Mournhold, Plaza Brindisi Dorom"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToTelMora,
		name = "Teleport To Tel Mora",
		description = getDescription("Tel Mora"),
		baseCost = 150,
		positionCell = {
			position = { 106925, 117169, 264},
			orientation = { x=0, y=0, z=34},
			cell = "Tel Mora"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToSuran,
		name = "Teleport To Suran",
		description = getDescription("Suran"),
		baseCost = 150,
		positionCell = {
			position = { 56217, -50650, 52},
			orientation = { x=0, y=0, z=178},
			cell = "Suran"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToPelagiad,
		name = "Teleport To Pelagiad",
		description = getDescription("Pelagiad"),
		baseCost = 150,
		positionCell = {
			position = { 1008, -56746, 1360},
			orientation = { x=0, y=0, z=86},
			cell = "Pelagiad"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToMolagMar,
		name = "Teleport To Molag Mar",
		description = getDescription("Molag Mar"),
		baseCost = 150,
		positionCell = {
			position = { 106763, -61839, 780},
			orientation = { x=0, y=0, z=92},
			cell = "Molag Mar"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToMaarGan,
		name = "Teleport To Maar Gan",
		description = getDescription("Maar Gan"),
		baseCost = 150,
		positionCell = {
			position = { -22118, 102242, 1979},
			orientation = { x=0, y=0, z=34},
			cell = "Maar Gan"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToGnisis,
		name = "Teleport To Gnisis",
		description = getDescription("Gnisis"),
		baseCost = 150,
		positionCell = {
			position = { -86430, 91415, 1035},
			orientation = { x=0, y=0, z=34},
			cell = "Gnisis"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToCaldera,
		name = "Teleport To Caldera",
		description = getDescription("Caldera"),
		baseCost = 150,
		positionCell = {
			position = { -10373, 17241, 1284},
			orientation = { x=0, y=0, z=4},
			cell = "Caldera"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToVivec,
		name = "Teleport To Vivec",
		description = getDescription("Vivec"),
		baseCost = 150,
		positionCell = {
			position = { 29906, -76553, 790},
			orientation = { x=0, y=0, z=178},
			cell = "Vivec"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToEbonheart,
		name = "Teleport To Ebonheart",
		description = getDescription("Ebonheart"),
		baseCost = 150,
		positionCell = {
			position = { 18122, -101919, 337},
			orientation = { x=0, y=0, z=268},
			cell = "Ebonheart"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToBalmora,
		name = "Teleport To Balmora",
		description = getDescription("Balmora"),
		baseCost = 150,
		positionCell = {
			position = { -22707, -17639, 403},
			orientation = { x=0, y=0, z=0},
			cell = "Balmora"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToAldRuhn,
		name = "Teleport To Ald-Ruhn",
		description = getDescription("Ald-Ruhn"),
		baseCost = 150,
		positionCell = {
			position = { -16328, 52678, 1841},
			orientation = { x=0, y=0, z=92},
			cell = "Ald-Ruhn"
		}
	})
end

event.register("magicEffectsResolved", addTeleportationEffects)