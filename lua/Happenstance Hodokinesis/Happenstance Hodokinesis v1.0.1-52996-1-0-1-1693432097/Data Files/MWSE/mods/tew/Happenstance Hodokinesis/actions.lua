-- This module hold all the action we might want to take. --

local actions = {}

local helper = require("tew.Happenstance Hodokinesis.helper")
local data = require("tew.Happenstance Hodokinesis.data")
local messages = require("tew.Happenstance Hodokinesis.messages")


function actions.healVital(vital)
	local chance = helper.calcActionChance()
    local maxVital = helper.getMaxVital(vital)
    local randomValue = math.random()
    local range = maxVital - vital.current
    local increment = range * chance * randomValue

    vital.current = helper.roundFloat(vital.current + increment)
    vital.current = math.clamp(vital.current, vital.current, maxVital)

	helper.cast(
					"Somamend",
					{{ id = tes3.effect.restoreHealth, duration = 1, min = 0, max = 0 }},
					tes3.player,
					data.vfx.restoration
				)
	helper.updateVitalsUI()
	helper.showMessage(messages.healedVital)
end


function actions.damageVital(vital)
	local chance = helper.calcActionChance()
	local randomValue = math.random()
    local range = math.clamp(vital.current / chance, vital.current - vital.current*2, vital.current)
    local decrement = range * randomValue

	local health = tes3.mobilePlayer.health
	if (
		(helper.numbersClose(vital.base, health.base))
			and
		(helper.numbersClose(vital.baseRaw, health.baseRaw))
			and
		(helper.numbersClose(vital.current, health.current))
			and
		(helper.numbersClose(vital.currentRaw, health.currentRaw))
			and
		(helper.numbersClose(vital.normalized, health.normalized))
	) then
		vital.current = math.clamp(helper.roundFloat(vital.current - decrement), 1, helper.getMaxVital(vital))
	else
    	vital.current = math.clamp(vital.current - helper.roundFloat(decrement), vital.current - vital.current*2, vital.current)
	end
	helper.cast(
		"Somarend",
		{{ id = tes3.effect.damageHealth, duration = 1, min = 0, max = 0 }},
		tes3.player,
		data.vfx.destruction
	)

	helper.updateVitalsUI()
	helper.showMessage(messages.damagedVital)
end


function actions.addPotionRestore(vital)
	local potionTable = helper.getConsumables(tes3.objectType.alchemy, helper.getVitalRestoreEffect(vital))
	tes3.addItem({
		reference = tes3.player,
		item = potionTable[helper.resolvePriority(#potionTable)]
	})
	helper.showMessage(messages.potion)
end

function actions.addPotionFeather()
	local potionTable = helper.getConsumables(tes3.objectType.alchemy, tes3.effect.feather)
	tes3.addItem({
		reference = tes3.player,
		item = potionTable[helper.resolvePriority(#potionTable)]
	})
	helper.showMessage(messages.potion)
end

function actions.addPotionBurden()
	local potionTable = helper.getConsumables(tes3.objectType.alchemy, tes3.effect.burden)
	tes3.addItem({
		reference = tes3.player,
		item = potionTable[helper.resolvePriority(#potionTable)]
	})
	helper.showMessage(messages.potion)
end

function actions.addPotionDisease()
	local potionTable = helper.getConsumables(tes3.objectType.alchemy, tes3.effect.cureCommonDisease)
	tes3.addItem({
		reference = tes3.player,
		item = potionTable[helper.resolvePriority(#potionTable)]
	})
	helper.showMessage(messages.potion)
end

function actions.addPotionBlight()
	local potionTable = helper.getConsumables(tes3.objectType.alchemy, tes3.effect.cureBlightDisease)
	tes3.addItem({
		reference = tes3.player,
		item = potionTable[helper.resolvePriority(#potionTable)]
	})
	helper.showMessage(messages.potion)
end

function actions.addPotionCurePoison()
	local potionTable = helper.getConsumables(tes3.objectType.alchemy, tes3.effect.curePoison)
	tes3.addItem({
		reference = tes3.player,
		item = potionTable[helper.resolvePriority(#potionTable)]
	})
	helper.showMessage(messages.potion)
end

function actions.addPotionPoison()
	local potionTable = helper.getConsumables(tes3.objectType.alchemy, tes3.effect.poison)
	tes3.addItem({
		reference = tes3.player,
		item = potionTable[helper.resolvePriority(#potionTable)]
	})
	helper.showMessage(messages.potion)
end

function actions.addPotionUnderwater()
	local potionTable_swim = helper.getConsumables(tes3.objectType.alchemy, tes3.effect.swiftSwim)
	local potionTable_breathe = helper.getConsumables(tes3.objectType.alchemy, tes3.effect.waterBreathing)
	table.copy(potionTable_swim, potionTable_breathe)
	tes3.addItem({
		reference = tes3.player,
		item = potionTable_breathe[helper.resolvePriority(#potionTable_breathe)]
	})
	helper.showMessage(messages.potion)
end

function actions.addIngredientRestore(vital)
	local ingredientTable = helper.getConsumables(tes3.objectType.ingredient, helper.getVitalRestoreEffect(vital))
	tes3.addItem({
		reference = tes3.player,
		item = ingredientTable[helper.resolvePriority(#ingredientTable)]
	})
	helper.showMessage(messages.ingredient)
end

function actions.addIngredientDamage(vital)
	local ingredientTable = helper.getConsumables(tes3.objectType.ingredient, helper.getVitalDamageEffect(vital))
	tes3.addItem({
		reference = tes3.player,
		item = ingredientTable[helper.resolvePriority(#ingredientTable)]
	})
	helper.showMessage(messages.ingredient)
end

function actions.addIngredientFeather()
	local ingredientTable = helper.getConsumables(tes3.objectType.ingredient, tes3.effect.feather)
	tes3.addItem({
		reference = tes3.player,
		item = ingredientTable[helper.resolvePriority(#ingredientTable)]
	})
	helper.showMessage(messages.ingredient)
end

function actions.addIngredientBurden()
	local ingredientTable = helper.getConsumables(tes3.objectType.ingredient, tes3.effect.burden)
	tes3.addItem({
		reference = tes3.player,
		item = ingredientTable[helper.resolvePriority(#ingredientTable)]
	})
	helper.showMessage(messages.ingredient)
end

function actions.addIngredientDisease()
	local ingredientTable = helper.getConsumables(tes3.objectType.ingredient, tes3.effect.cureCommonDisease)
	tes3.addItem({
		reference = tes3.player,
		item = ingredientTable[helper.resolvePriority(#ingredientTable)]
	})
	helper.showMessage(messages.ingredient)
end

function actions.addIngredientBlight()
	local ingredientTable = helper.getConsumables(tes3.objectType.ingredient, tes3.effect.cureBlightDisease)
	tes3.addItem({
		reference = tes3.player,
		item = ingredientTable[helper.resolvePriority(#ingredientTable)]
	})
	helper.showMessage(messages.ingredient)
end

function actions.addIngredientCurePoison()
	local ingredientTable = helper.getConsumables(tes3.objectType.ingredient, tes3.effect.curePoison)
	tes3.addItem({
		reference = tes3.player,
		item = ingredientTable[helper.resolvePriority(#ingredientTable)]
	})
	helper.showMessage(messages.ingredient)
end


function actions.addIngredientPoison()
	local ingredientTable = helper.getConsumables(tes3.objectType.ingredient, tes3.effect.poison)
	tes3.addItem({
		reference = tes3.player,
		item = ingredientTable[helper.resolvePriority(#ingredientTable)]
	})
	helper.showMessage(messages.ingredient)
end

function actions.addIngredientUnderwater()
	local ingredientTable_swim = helper.getConsumables(tes3.objectType.ingredient, tes3.effect.swiftSwim)
	local ingredientTable_breathe = helper.getConsumables(tes3.objectType.ingredient, tes3.effect.waterBreathing)
	table.copy(ingredientTable_swim, ingredientTable_breathe)
	tes3.addItem({
		reference = tes3.player,
		item = ingredientTable_breathe[helper.resolvePriority(#ingredientTable_breathe)]
	})
	helper.showMessage(messages.ingredient)
end


function actions.addScrollRestore(vital)
	local scrollTable = helper.getScrolls(helper.getVitalRestoreEffect(vital), tes3.effectRange.self)
	tes3.addItem({
		reference = tes3.player,
		item = scrollTable[helper.resolvePriority(#scrollTable)]
	})
	helper.showMessage(messages.scroll)
end

function actions.addScrollOpen()
	local scrollTable = helper.getScrolls(tes3.effect.open, nil)
	tes3.addItem({
		reference = tes3.player,
		item = scrollTable[helper.resolvePriority(#scrollTable)]
	})
	helper.showMessage(messages.scroll)
end

function actions.addScrollLock()
	local scrollTable = helper.getScrolls(tes3.effect.lock, nil)
	tes3.addItem({
		reference = tes3.player,
		item = scrollTable[helper.resolvePriority(#scrollTable)]
	})
	helper.showMessage(messages.scroll)
end

function actions.addScrollFeather()
	local scrollTable = helper.getScrolls(tes3.effect.feather, tes3.effectRange.self)
	tes3.addItem({
		reference = tes3.player,
		item = scrollTable[helper.resolvePriority(#scrollTable)]
	})
	helper.showMessage(messages.scroll)
end

function actions.addScrollBurden()
	local scrollTable = helper.getScrolls(tes3.effect.burden, tes3.effectRange.self)
	tes3.addItem({
		reference = tes3.player,
		item = scrollTable[helper.resolvePriority(#scrollTable)]
	})
	helper.showMessage(messages.scroll)
end

function actions.addScrollDisease()
	local scrollTable = helper.getScrolls(tes3.effect.cureCommonDisease, tes3.effectRange.self)
	tes3.addItem({
		reference = tes3.player,
		item = scrollTable[helper.resolvePriority(#scrollTable)]
	})
	helper.showMessage(messages.scroll)
end

function actions.addScrollBlight()
	local scrollTable = helper.getScrolls(tes3.effect.cureBlightDisease, tes3.effectRange.self)
	tes3.addItem({
		reference = tes3.player,
		item = scrollTable[helper.resolvePriority(#scrollTable)]
	})
	helper.showMessage(messages.scroll)
end

function actions.addScrollCurePoison()
	local scrollTable = helper.getScrolls(tes3.effect.curePoison, tes3.effectRange.self)
	tes3.addItem({
		reference = tes3.player,
		item = scrollTable[helper.resolvePriority(#scrollTable)]
	})
	helper.showMessage(messages.scroll)
end

function actions.addScrollUnderwater()
	local scrollTable_swim = helper.getScrolls(tes3.effect.swiftSwim, tes3.effectRange.self)
	local scrollTable_breathe = helper.getScrolls(tes3.effect.waterBreathing, tes3.effectRange.self)
	table.copy(scrollTable_swim, scrollTable_breathe)
	tes3.addItem({
		reference = tes3.player,
		item = scrollTable_breathe[helper.resolvePriority(#scrollTable_breathe)]
	})
	helper.showMessage(messages.scroll)
end

function actions.unlock(ref)
	helper.cast(
		"Apokopto",
		{{ id = tes3.effect.open, duration = 1, min = 0, max = 0 }},
		ref,
		data.vfx.alteration
	)
	tes3.unlock{reference = ref}
	helper.showMessage(messages.unlocked)
end

function actions.lockLess(ref)
	helper.cast(
		"Trizo",
		{{ id = tes3.effect.open, duration = 1, min = 0, max = 0 }},
		ref,
		data.vfx.alteration
	)
	local lockNode = ref.lockNode
	if lockNode then
		local levelOld = lockNode.level
		local levelNew = math.clamp(helper.roundFloat(helper.resolvePriority(100)), 1, levelOld)
		lockNode.level = levelNew
	end
	helper.showMessage(messages.lockedLess)
end

function actions.lockMore(ref)
	helper.cast(
		"Perikleio",
		{{ id = tes3.effect.open, duration = 1, min = 0, max = 0 }},
		ref,
		data.vfx.alteration
	)
	local lockNode = ref.lockNode
	if lockNode then
		local levelOld = lockNode.level
		local levelNew = math.clamp(helper.roundFloat(helper.resolvePriority(100)), levelOld, 100)
		lockNode.level = levelNew
	end
	helper.showMessage(messages.lockedMore)
end

function actions.feather()
	local duration = helper.getBoonDuration()
	local power = helper.getBoonPower()

	helper.cast(
		"Pteroma",
		{{ id = tes3.effect.feather, duration = duration, min = power, max = power }},
		tes3.player,
		data.vfx.alteration
	)
	helper.showMessage(messages.spellFeather)
end

function actions.burden()
	local duration = helper.getMalusDuration()
	local power = helper.getMalusPower()

	helper.cast(
		"Barophoria",
		{{ id = tes3.effect.burden, duration = duration, min = power, max = power }},
		tes3.player,
		data.vfx.alteration
	)
	helper.showMessage(messages.spellBurden)
end

function actions.bountyLess()
	local mp = tes3.mobilePlayer
	local bounty = mp.bounty
	local percentage = math.clamp(math.remap(helper.resolvePriority(100), 1, 100, 100, 1) / 100, 0.0, 1.0)
	local newBounty = helper.roundFloat((bounty) - (bounty * percentage))
	mp.bounty = newBounty
	helper.showMessage(messages.bountyLess)
end

function actions.bountyMore()
	local mp = tes3.mobilePlayer
	local bounty = mp.bounty
	local percentage = math.clamp(helper.resolvePriority(100) / 100, 0.0, 1.0)
	local newBounty = helper.roundFloat((bounty) + (bounty * percentage))
	mp.bounty = newBounty
	helper.showMessage(messages.bountyMore)
end

function actions.bountyTeleport()
	local locations = data.bountyNPCs
	local mp = tes3.mobilePlayer
	local teleportPosition, teleportCell
	if mp then
		teleportPosition, teleportCell = helper.getRandomNPCPositionFromTable(locations)
	end
	if teleportPosition and teleportCell then
		tes3.positionCell{
			position = teleportPosition,
			cell = teleportCell
		}
		helper.showMessage(messages.bountyTeleport)
	end
end

function actions.templeTeleport()
	helper.cast(
		"Trioktasis",
		{{ id = tes3.effect.almsiviIntervention, duration = 1, min = 100, max = 100 }},
		tes3.player,
		data.vfx.mysticism
	)
	helper.showMessage(messages.templeTeleport)
end

function actions.cultTeleport()
	helper.cast(
		"Theioktasis",
		{{ id = tes3.effect.divineIntervention, duration = 1, min = 100, max = 100 }},
		tes3.player,
		data.vfx.mysticism
	)
	helper.showMessage(messages.cultTeleport)
end

function actions.cureDisease()
	helper.cast(
		"Nososeuthesis",
		{{ id = tes3.effect.cureCommonDisease, duration = 1, min = 100, max = 100 }},
		tes3.player,
		data.vfx.restoration
	)
	helper.showMessage(messages.diseaseCured)
end

function actions.cureBlight()
	helper.cast(
		"Lytosepsis",
		{{ id = tes3.effect.cureBlightDisease, duration = 1, min = 100, max = 100 }},
		tes3.player,
		data.vfx.restoration
	)
	helper.showMessage(messages.blightCured)
end

function actions.curePoison()
	helper.cast(
		"Toxicure",
		{{ id = tes3.effect.curePoison, duration = 1, min = 100, max = 100 }},
		tes3.player,
		data.vfx.restoration
	)
	helper.showMessage(messages.poisonCured)
end

function actions.contractDisease()
	tes3.cast{
		reference = tes3.player,
		spell = table.choice(data.diseases),
		alwaysSucceeds = true,
		bypassResistances = true,
		instant = true,
		target = tes3.player
	}
	helper.showMessage(messages.diseaseContracted)
end

function actions.contractBlight()
	tes3.cast{
		reference = tes3.player,
		spell = table.choice(data.blights),
		alwaysSucceeds = true,
		bypassResistances = true,
		instant = true,
		target = tes3.player
	}
	helper.showMessage(messages.blightContracted)
end

function actions.poison()
	local duration = helper.roundFloat(math.remap(helper.resolvePriority(100), 1, 100, 5, 20))
	local power =  helper.resolvePriority(15)

	helper.cast(
		"Toxicon",
		{{ id = tes3.effect.poison, duration = duration, min = power, max = power }},
		tes3.player,
		data.vfx.poison
	)
	helper.showMessage(messages.spellPoison)
end

function actions.underwaterBoon()
	local duration = helper.getBoonDuration()
	local power = helper.getBoonPower()

	helper.cast(
		"Ichtioid",
		{
			{ id = tes3.effect.swiftSwim, duration = duration, min = power, max = power },
			{ id = tes3.effect.waterBreathing, duration = duration, min = power, max = power }
		},
		tes3.player,
		data.vfx.alteration
	)
	helper.showMessage(messages.underwaterBoon)
end

function actions.teleportOutside()
	local door = helper.getExteriorDoor(tes3.mobilePlayer.cell)
	if door then
		tes3.player:activate(door)
		helper.showMessage(messages.teleportOutside)
	end
end

function actions.calmHostiles()
	local duration = helper.getBoonDuration()
	local power = helper.getBoonPower()
	local mp = tes3.mobilePlayer
	for _, v in ipairs(mp.hostileActors) do
		helper.cast(
			"Eirenikos",
			{{ id = tes3.effect.calmHumanoid, duration = duration, min = power, max = power }},
			v.reference,
			data.vfx.illusion
		)
		helper.cast(
			"Eirenikos",
			{{ id = tes3.effect.calmCreature, duration = duration, min = power, max = power }},
			v.reference,
			data.vfx.illusion
		)
	end
	helper.showMessage(messages.calmHostiles)
end

function actions.sanctuary()
	local duration = helper.getBoonDuration()
	local power = helper.getBoonPower()

	helper.cast(
		"Asylion",
		{{ id = tes3.effect.sanctuary, duration = duration, min = power, max = power }},
		tes3.player,
		data.vfx.illusion
	)
	helper.showMessage(messages.sanctuary)
end

function actions.chameleon()
	local duration = helper.getBoonDuration()
	local power = helper.getBoonPower()

	helper.cast(
		"Chromaleontis",
		{{ id = tes3.effect.chameleon, duration = duration, min = power, max = power }},
		tes3.player,
		data.vfx.illusion
	)
	helper.showMessage(messages.chameleon)
end

function actions.invisibility()
	local duration = helper.getBoonDuration()
	local power = helper.getBoonPower()

	helper.cast(
		"Adelotesis",
		{{ id = tes3.effect.invisibility, duration = duration, min = power, max = power }},
		tes3.player,
		data.vfx.illusion
	)
	helper.showMessage(messages.invisibility)
end

function actions.disintegrateWeapon()
	local duration = helper.getMalusDuration()
	local power = helper.getMalusPower()

	helper.cast(
		"Melilochysis",
		{{ id = tes3.effect.disintegrateWeapon, duration = duration, min = power, max = power }},
		tes3.player,
		data.vfx.destruction
	)
	helper.showMessage(messages.disintegrateWeapon)
end

function actions.disintegrateArmor()
	local duration = helper.getMalusDuration()
	local power = helper.getMalusPower()

	helper.cast(
		"Orektomacheia",
		{{ id = tes3.effect.disintegrateArmor, duration = duration, min = power, max = power }},
		tes3.player,
		data.vfx.destruction
	)
	helper.showMessage(messages.disintegrateArmor)
end

function actions.killHostiles()
	local mp = tes3.mobilePlayer
	for _, v in ipairs(mp.hostileActors) do
		v.health.current = 0
	end
	helper.showMessage(messages.killHostiles)
end

function actions.damageHostiles()
	local mp = tes3.mobilePlayer
	for _, v in ipairs(mp.hostileActors) do
		local chance = helper.calcActionChance()
		local randomValue = math.random()
		local vital = v.health
		local range = math.clamp(vital.current / chance, vital.current - vital.current*2, vital.current)
		local decrement = range * randomValue

		vital.current = math.clamp(vital.current - helper.roundFloat(decrement), vital.current - vital.current*2, vital.current)

		helper.cast(
			"Somarend",
			{{ id = tes3.effect.damageHealth, duration = 1, min = 0, max = 0 }},
			v.reference,
			data.vfx.destruction
		)
	end
	helper.showMessage(messages.damageHostiles)
end

function actions.summonScrib()
	tes3.createReference{
		object = "scrib",
		position = tes3.mobilePlayer.reference.position,
		orientation = tes3.mobilePlayer.reference.orientation,
		cell = tes3.player.cell,
	}
	helper.showMessage(messages.scribSummoned)
end

function actions.summonScribHostile()
	local scrib = tes3.createReference{
		object = "tew_hodo_scrib",
		position = tes3.mobilePlayer.reference.position,
		orientation = tes3.mobilePlayer.reference.orientation,
		cell = tes3.player.cell,
	}
	helper.showMessage(messages.scribSummonedHostile)
end

function actions.teleportRandom()
	local teleportCell, positions = helper.getRandomCellRefPositions()
	while (table.empty(positions)) or (data.blacklistedCells[teleportCell.editorName]) do
		teleportCell, positions = helper.getRandomCellRefPositions()
	end

	tes3.positionCell{
		position = table.choice(positions),
		cell = teleportCell
	}
	event.register(tes3.event.cellChanged, function() tes3.runLegacyScript{command = "fixme"} end, { doOnce = true })
	helper.showMessage(messages.teleportRandom)
end

function actions.luckyContainer()
	local function addLuckyLoot(e)
		local ref = e.target
		if not (ref.object.objectType == tes3.objectType.container) or (ref.object.objectType == tes3.objectType.container and ref.organic) then return end
		local items = helper.getLootItem()
		tes3.addItem{
			reference = ref,
			item = items[helper.resolvePriority(#items)],
			count = 1
		}
		helper.showMessage(messages.luckyContainerOpened)
		event.unregister(tes3.event.activate, addLuckyLoot)
	end
	event.register(tes3.event.activate, addLuckyLoot)
	helper.showMessage(messages.luckyContainer)
end

function actions.alchemyBoon()
	local duration = helper.getBoonDuration()
	local power = helper.getBoonPower()

	helper.cast(
		"Pharmakonexousia",
		{
			{ id = tes3.effect.fortifySkill, skill=tes3.skill.alchemy, duration = duration, min = power, max = power },
		},
		tes3.player,
		data.vfx.restoration
	)
	helper.showMessage(messages.alchemyBoon)
end

function actions.alchemyFail()
	local duration = helper.getMalusDuration()
	local power = helper.getMalusPower()

	helper.cast(
		"Pharmakonaporia",
		{
			{ id = tes3.effect.damageSkill, skill=tes3.skill.alchemy, duration = duration, min = power, max = power },
		},
		tes3.player,
		data.vfx.destruction
	)
	helper.showMessage(messages.alchemyFail)
end


function actions.personalityBoon()
	local duration = helper.getBoonDuration()
	local power = helper.getBoonPower()

	helper.cast(
		"Kharis",
		{
			{ id = tes3.effect.fortifyAttribute, attribute=tes3.attribute.personality, duration = duration, min = power, max = power },
		},
		tes3.player,
		data.vfx.restoration
	)
	helper.showMessage(messages.personalityBoon)
end

function actions.personalityFail()
	local duration = helper.getMalusDuration()
	local power = math.floor(helper.getMalusPower() / 2)

	helper.cast(
		"Aphanasia",
		{
			{ id = tes3.effect.damageAttribute, attribute=tes3.attribute.personality, duration = 0, min = power, max = power },
		},
		tes3.player,
		data.vfx.destruction
	)
	timer.start{
		type = timer.game,
		duration = duration / 60,
		iterations = 1,
		callback = function()
			debug.log("Aphanasia Cure cast!")
			helper.cast(
				"Aphanasia Cure",
				{
					{ id = tes3.effect.restoreAttribute, attribute=tes3.attribute.personality, duration = 1, min = 100, max = 100 },
				},
				tes3.player,
				data.vfx.restoration
			)
		end
	}
	helper.showMessage(messages.personalityFail)
end

function actions.barterBoon()
	local duration = helper.getBoonDuration()
	local power = helper.getBoonPower()

	helper.cast(
		"Euthymeia",
		{
			{ id = tes3.effect.fortifySkill, skill=tes3.skill.mercantile, duration = duration, min = power, max = power },
		},
		tes3.player,
		data.vfx.restoration
	)
	helper.showMessage(messages.barterBoon)
end

function actions.barterFail()
	local duration = helper.getMalusDuration()
	local power = helper.getMalusPower()

	helper.cast(
		"Chremasmos",
		{
			{ id = tes3.effect.damageSkill, skill=tes3.skill.mercantile, duration = duration, min = power, max = power },
		},
		tes3.player,
		data.vfx.destruction
	)
	helper.showMessage(messages.barterFail)
end

function actions.flunge()
	local mp = tes3.mobilePlayer
	if mp then
		local teleportCell = tes3.player.cell
		if teleportCell.isOrBehavesAsExterior then
			local pos = mp.position:copy()
			pos.z = pos.z + 4000
			if teleportCell then
				helper.cast(
					"Bradyseismos",
					{
						{ id = tes3.effect.slowFall, skill=tes3.skill.mercantile, duration = 60, min = 1, max = 100 },
					},
					tes3.player,
					data.vfx.alteration
				)
				tes3.positionCell{
					position = pos,
					cell = teleportCell
				}
				helper.showMessage(messages.flungedAir)
			end
		else
			if teleportCell then
				tes3.positionCell{
					position = tes3.getLastExteriorPosition(),
				}
				helper.showMessage(messages.flungedOutside)
			end
		end
	end
end

function actions.preventEquip()
	local function butterfingers(e)
		event.unregister(tes3.event.equip, butterfingers)
		helper.showMessage(messages.preventEquip(e.item.name))
		e.block = true
	end
	event.register(tes3.event.equip, butterfingers)
	helper.showMessage(messages.clumsy)
end

function actions.flies()
	local function playFlies(e)
		if not e.sound or (e.sound and e.sound.id == "Flies") or not tes3.player then return end

		tes3.playSound{
			sound = "Flies",
			pitch = e.pitch * math.random(50, 120) / 100,
			volume = math.random(50, 100) / 100,
		}
		return false
	end

	event.register(tes3.event.addSound, playFlies)

	timer.start{
		type = timer.game,
		duration = 0.5,
		iterations = 1,
		callback = function()
			event.unregister(tes3.event.addSound, playFlies)
		end
	}

	helper.showMessage(messages.flies)
end

--
return actions