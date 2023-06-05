-- A couple of helper functions. --


local helper = {}

local config = require("tew.Happenstance Hodokinesis.config")
local dataHandler = require("tew.Happenstance Hodokinesis.dataHandler")
local data = require("tew.Happenstance Hodokinesis.data")

-- We need to calculate a chance of good/bad effects to happen, based on the player's Luck --
function helper.calcActionChance()
	return math.clamp(
		(
			((tes3.mobilePlayer.luck.current + math.random(1, 10)) / 100) - (dataHandler.getUsedPerDay(tes3.worldController.daysPassed.value) / 50)
		),
		0.01,
		1.0
	)
end

function helper.calcBoon()
	return helper.calcActionChance() > (math.random(1, 100) / 100)
end

function helper.getVitalRestoreEffect(vital)

	local vitalEffects = {
		["health"] = tes3.effect.restoreHealth,
		["fatigue"] = tes3.effect.restoreFatigue,
		["magicka"] = tes3.effect.restoreMagicka
	}

	return vitalEffects[helper.getVitalName(vital)]
end

function helper.getVitalDamageEffect(vital)

	local vitalEffects = {
		["health"] = tes3.effect.damageHealth,
		["fatigue"] = tes3.effect.damageFatigue,
		["magicka"] = tes3.effect.damageMagicka
	}

	return vitalEffects[helper.getVitalName(vital)]
end

function helper.getConsumables(objectType, effect)
	local tab = {}
	for _, obj in ipairs(tes3.dataHandler.nonDynamicData.objects) do
		if obj.objectType == objectType then
			if obj.effects then
				if objectType == tes3.objectType.ingredient then
					if obj.effects[1] == effect then
						table.insert(tab, obj)
					end
				elseif objectType == tes3.objectType.alchemy then
					if obj.effects[1].id == effect then
						table.insert(tab, obj)
					end
				end
			end
		end
	end
	table.sort(tab, function(a, b) return a.value > b.value end)
	return tab
end

function helper.getScrolls(effect, effectRange)
	local tab = {}
	for _, obj in ipairs(tes3.dataHandler.nonDynamicData.objects) do
		if obj.objectType == tes3.objectType.book and obj.type == tes3.bookType.scroll then
			if obj.enchantment then
				for _, e in ipairs(obj.enchantment.effects) do
					if e.id == effect then
						if effectRange then
							if e.rangeType == effectRange then
								table.insert(tab, obj)
							end
						else
							table.insert(tab, obj)
						end
					end
				end
			end
		end
	end
	table.sort(tab, function(a, b) return a.value > b.value end)
	return tab
end

function helper.getGeneric(objectType)
	local tab = {}
	for _, obj in ipairs(tes3.dataHandler.nonDynamicData.objects) do
		if obj.objectType == objectType and obj.value and not obj.isKey then
			table.insert(tab, obj)
		end
	end
	table.sort(tab, function(a, b) return a.value > b.value end)
	return tab
end

function helper.getBestSkill(skillTable)
	local mp = tes3.mobilePlayer
	local playerWeaponSkills = {}

	if mp then
		for i, playerSkill in pairs(mp.skills) do
			debug.log(i)
			if skillTable[i - 1] then
				playerWeaponSkills[i - 1] = playerSkill.current
			end
		end
	end

	local sorted = {}
	for skillId, val in pairs(playerWeaponSkills) do
		sorted[val] = sorted[val] or {}
		table.insert(sorted[val], skillId)
	end

	return table.choice(sorted[math.max(table.unpack(table.keys(sorted)))])
end

function helper.getSkilledWeapon(fun)
	local skillId = fun()
	debug.log(skillId)

	local tab = {}
	for _, obj in ipairs(tes3.dataHandler.nonDynamicData.objects) do
		if obj.objectType == tes3.objectType.weapon and obj.skillId == skillId and obj.value then
			table.insert(tab, obj)
		end
	end
	table.sort(tab, function(a, b) return a.value > b.value end)
	return tab
end

function helper.getSkilledArmor(fun)
	local skill = fun()
	local tab = {}
	for _, obj in ipairs(tes3.dataHandler.nonDynamicData.objects) do
		if obj.objectType == tes3.objectType.armor and obj.skill == skill and obj.value then
			table.insert(tab, obj)
		end
	end
	table.sort(tab, function(a, b) return a.value > b.value end)
	return tab
end

function helper.getLootItem()
	local getters = {
		function() return helper.getSkilledWeapon(helper.getBestSkill(data.weaponSkills)) end,
		function() return helper.getSkilledArmor(helper.getBestSkill(data.armorSkills)) end,
		function() return helper.getGeneric(tes3.objectType.scroll) end,
		function() return helper.getGeneric(tes3.objectType.alchemy) end,
		function() return helper.getGeneric(tes3.objectType.clothing) end,
		function() return helper.getGeneric(tes3.objectType.ingredient) end,
		function() return helper.getGeneric(tes3.objectType.light) end,
		function() return helper.getGeneric(tes3.objectType.miscItem) end,
	}
	return table.choice(getters)()
end

function helper.roundFloat(n)
	return math.floor(math.abs(n + 0.5))
end

function helper.resolvePriority(tableSize)
	if tableSize == 1 then return tableSize end

	local luck = helper.calcActionChance() * 100
	local clampedLuck = math.clamp(luck, 0, 100)

	local minIndex = 1
	local maxIndex = tableSize

	-- Adjust the scaling factor as needed
	local scalingFactor = 1 - clampedLuck / 100

	-- Determine whether to completely randomize the luck
	local completelyRandom = math.random() <= 0.2

	local randomOffset = 0
	if completelyRandom then
	  randomOffset = math.random(minIndex, maxIndex)
	else
	  -- Calculate the random offset with adjusted scaling factor
	  randomOffset = math.random() * scalingFactor * (clampedLuck / 100) - scalingFactor * (clampedLuck / 200)
	end

	local index = math.floor(scalingFactor * (maxIndex - minIndex) + minIndex + randomOffset)

	index = math.clamp(index, minIndex, maxIndex)

	return index
end


-- Fillbars don't update immediately, so we need to force it. --
function helper.updateVitalsUI()
	local menuIds = {
		tes3ui.findMenu(tes3ui.registerID("MenuStat")),
		tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
	}

	local barIds = {
		[tes3.mobilePlayer.health] = tes3ui.registerID("MenuStat_health_fillbar"),
		[tes3.mobilePlayer.fatigue] = tes3ui.registerID("MenuStat_fatigue_fillbar"),
		[tes3.mobilePlayer.magicka] = tes3ui.registerID("MenuStat_magic_fillbar"),
	}

	for _, menu in ipairs(menuIds) do
		for vital, id in pairs(barIds) do
			local bar = menu:findChild(id)

			if bar then
				bar.widget.current = vital.current
				bar:updateLayout()
				menu:updateLayout()
			end
		end
	end
end

-- I suppose there might change in between calls, so make sure we factor that in. --
function helper.numbersClose(firstValue, secondValue)
	return math.isclose(firstValue, secondValue, 0.01)
end

-- Get a vital name to use in data indexing
function helper.getVitalName(vital)

	local vitalEffects = {
		[tes3.mobilePlayer.health] = "health",
		[tes3.mobilePlayer.fatigue] = "fatigue",
		[tes3.mobilePlayer.magicka] = "magicka"
	}

	for v, e in pairs(vitalEffects) do
		if (
			(helper.numbersClose(vital.base, v.base))
				and
			(helper.numbersClose(vital.baseRaw, v.baseRaw))
				and
			(helper.numbersClose(vital.current, v.current))
				and
			(helper.numbersClose(vital.currentRaw, v.currentRaw))
				and
			(helper.numbersClose(vital.normalized, v.normalized))
		) then
			return e
		end
	end
end


-- We need to know which fortify effect might be at play. --
function helper.getFortifyEffect(vital)
	local vitalEffects = {
		["health"] = tes3.effect.fortifyHealth,
		["fatigue"] = tes3.effect.fortifyFatigue,
		["magicka"] = tes3.effect.fortifyMagicka
	}
	return vitalEffects[helper.getVitalName(vital)]
end

-- Max stats are essentialy the base value + any fortify effects at a given time, so let's make sure we calculate from the actual max value available. --
function helper.getMaxVital(vital)

	local fortifyEffect = helper.getFortifyEffect(vital)

	-- If we don't match any effect for some reason, let's just not do anything
	local fortifyBonus = 0

	if fortifyEffect then
		fortifyBonus = tes3.getEffectMagnitude({
			reference = tes3.player,
			effect = fortifyEffect
		})
	end

	return (vital.base + fortifyBonus)
end

function helper.cast(name, effects, ref, vfx)
	local magicSourceInstance = tes3.applyMagicSource({
		name = name,
		reference = ref,
		castChance = 100,
		bypassResistances = true,
		effects = effects
	})
	magicSourceInstance:playVisualEffect{
		effectIndex = 0,
		position = ref.position,
		visual = vfx
	}
end

function helper.showMessage(message)
	if config.showInfoMessages then
		tes3.messageBox{
			message = message
		}
	end
end

function helper.getRandomNPCPositionFromTable(tab)
	local mp = tes3.mobilePlayer
	if mp then
		local npc = tes3.getReference(table.choice(tab))
		return npc.position:copy(), npc.cell
	end
end

function helper.getExteriorDoor(cell)
	for door in cell:iterateReferences(tes3.objectType.door) do
		if door.destination then
			if (door.destination.cell.isOrBehavesAsExterior) then
				return door
			end
		end
	end
end

function helper.getRandomCellRefPositions()
	local teleportCell = table.choice(tes3.dataHandler.nonDynamicData.cells)
	local positions = {}
	for ref in teleportCell:iterateReferences() do
		if ref.position then
			local pos = ref.position
			table.insert(positions, pos)
		end
	end
	return teleportCell, positions
end

function helper.getUsageLimit()
	return helper.roundFloat((math.remap(tes3.mobilePlayer.luck.current, 1, 100, 1, 10)))
end

function helper.isApparatus(ref)
	if not ref then return false end
	return ref.object.objectType == tes3.objectType.apparatus
end

function helper.isTalkableNPC(ref)
	if not ref then return false end
	if (ref.object.objectType == tes3.objectType.npc) then
		return not ref.isDead and not ref.inCombat
	end
	return false
end

function helper.isMerchant(ref)
	if not ref then return false end
	if (ref.object.objectType == tes3.objectType.npc) then
		local ai = ref.object.aiConfig
		local barters = false
		if
			ai.bartersAlchemy or
			ai.bartersApparatus or
			ai.bartersArmor or
			ai.bartersBooks or
			ai.bartersClothing or
			ai.bartersEnchantedItems or
			ai.bartersIngredients or
			ai.bartersLights or
			ai.bartersLockpicks or
			ai.bartersMiscItems or
			ai.bartersProbes or
			ai.bartersRepairTools or
			ai.bartersWeapons
		then
			barters = true
		end
		return barters and not ref.isDead and not ref.inCombat
	end
	return false
end

function helper.getBoonPower()
	return helper.roundFloat(math.remap(helper.resolvePriority(100), 1, 100, 100, 1))
end

function helper.getBoonDuration()
	return helper.roundFloat(math.remap(helper.resolvePriority(100), 1, 100, 120, 5))
end

function helper.getMalusPower()
	local maxPower = helper.resolvePriority(100)
	return math.clamp(math.random(helper.roundFloat(maxPower/3), helper.roundFloat(maxPower + helper.roundFloat(maxPower/3))), 1, 100)
end

function helper.getMalusDuration()
	return helper.roundFloat(math.remap(helper.resolvePriority(100), 1, 100, 5, 120))
end

-- function helper.joinTables(tables)
-- 	local output = {}
-- 	local n = 0
-- 	for _, tab in ipairs(tables) do
-- 		for _,v in ipairs(tab) do
-- 			n=n+1
-- 			output[n]=v
-- 		end
-- 	end
-- 	return output
-- end

--
return helper