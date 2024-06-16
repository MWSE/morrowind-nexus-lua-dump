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
    return "Этот эффект телепортирует в ".. location .."."
end
local function addTeleportationEffects()
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToMournhold,
		name = "Телепорт в Морнхолд",
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
		name = "Телепорт в Тель Мору",
		description = getDescription("Тель Мору"),
		baseCost = 150,
		positionCell = {
			position = { 106925, 117169, 264},
			orientation = { x=0, y=0, z=34},
			cell = "Tel Mora"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToSuran,
		name = "Телепорт в Суран",
		description = getDescription("Суран"),
		baseCost = 150,
		positionCell = {
			position = { 56217, -50650, 52},
			orientation = { x=0, y=0, z=178},
			cell = "Suran"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToPelagiad,
		name = "Телепорт в Пелагиад",
		description = getDescription("Пелагиад"),
		baseCost = 150,
		positionCell = {
			position = { 1008, -56746, 1360},
			orientation = { x=0, y=0, z=86},
			cell = "Pelagiad"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToMolagMar,
		name = "Телепорт в Молаг Мар",
		description = getDescription("Молаг Мар"),
		baseCost = 150,
		positionCell = {
			position = { 106763, -61839, 780},
			orientation = { x=0, y=0, z=92},
			cell = "Molag Mar"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToMaarGan,
		name = "Телепорт в Маар Ган",
		description = getDescription("Маар Ган"),
		baseCost = 150,
		positionCell = {
			position = { -22118, 102242, 1979},
			orientation = { x=0, y=0, z=34},
			cell = "Maar Gan"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToGnisis,
		name = "Телепорт в Гнисис",
		description = getDescription("Гнисис"),
		baseCost = 150,
		positionCell = {
			position = { -86430, 91415, 1035},
			orientation = { x=0, y=0, z=34},
			cell = "Gnisis"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToCaldera,
		name = "Телепорт в Кальдеру",
		description = getDescription("Кальдеру"),
		baseCost = 150,
		positionCell = {
			position = { -10373, 17241, 1284},
			orientation = { x=0, y=0, z=4},
			cell = "Caldera"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToVivec,
		name = "Телепорт в Вивек",
		description = getDescription("Вивек"),
		baseCost = 150,
		positionCell = {
			position = { 29906, -76553, 790},
			orientation = { x=0, y=0, z=178},
			cell = "Vivec"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToEbonheart,
		name = "Телепорт в Эбенгард",
		description = getDescription("Эбенгард"),
		baseCost = 150,
		positionCell = {
			position = { 18122, -101919, 337},
			orientation = { x=0, y=0, z=268},
			cell = "Ebonheart"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToBalmora,
		name = "Телепорт в Балмору",
		description = getDescription("Балмору"),
		baseCost = 150,
		positionCell = {
			position = { -22707, -17639, 403},
			orientation = { x=0, y=0, z=0},
			cell = "Balmora"
		}
	})
	framework.effects.mysticism.createBasicTeleportationEffect({
		id = tes3.effect.teleportToAldRuhn,
		name = "Телепорт в Альд'рун",
		description = getDescription("Альд'рун"),
		baseCost = 150,
		positionCell = {
			position = { -16328, 52678, 1841},
			orientation = { x=0, y=0, z=92},
			cell = "Ald-Ruhn"
		}
	})
end

event.register("magicEffectsResolved", addTeleportationEffects)