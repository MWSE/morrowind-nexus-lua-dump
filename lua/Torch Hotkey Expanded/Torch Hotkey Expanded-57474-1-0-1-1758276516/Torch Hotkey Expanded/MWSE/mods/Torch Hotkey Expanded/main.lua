local midnightOilCommon = include("mer.midnightOil.common")

local config = require("Torch Hotkey Expanded.config")

local log = mwse.Logger.new({
	name = "Torch Hotkey Expanded",
	level = config.logLevel
})
dofile("Torch Hotkey Expanded.mcm")

---@param item tes3light
---@param data tes3itemData
---@return boolean
local function midnightOilIsCandleRunOut(item, data)
	return false
end
if midnightOilCommon then
	---@param item tes3light
	---@param data tes3itemData
	midnightOilIsCandleRunOut = function(item, data)
		local isLanternOrCandle = midnightOilCommon.isOilLantern(item) or midnightOilCommon.isCandleLantern(item)
		if not isLanternOrCandle then
			return false
		end
		local isRunOut = item.time > 0 and data and data.timeLeft < 1
		return isRunOut
	end
end

--- @param ref tes3reference
--- @return tes3light?, tes3itemData?
local function getBestLight(ref)
	---@type { item: tes3light, data: tes3itemData|nil }[]
	local lights = {}
	--- @param stack tes3itemStack
	for _, stack in pairs(ref.object.inventory) do
		local obj = stack.object
		if obj.objectType ~= tes3.objectType.light
		or not obj.canCarry
		or obj.time <= 0 then
			goto continue
		end
		local variablesCount = 0
		for _, data in ipairs(stack.variables or {}) do
			variablesCount = variablesCount + 1
			if not midnightOilIsCandleRunOut(obj, data) then
				table.insert(lights, { item = obj, data = data })
			end
		end
		local leftCount = stack.count - variablesCount
		if leftCount <= 0 then
			goto continue
		end

		table.insert(lights, { item = obj })
		:: continue ::
	end
	if table.empty(lights) then return end
	-- Now we want the light with biggest radius.
	table.sort(lights, function(a, b)
		if a.item.radius > b.item.radius then
			return true
		elseif a.item.radius == b.item.radius then
			-- Sort by usedTime.
			local timeA = a.data and a.data.timeLeft or a.item.time
			local timeB = b.data and b.data.timeLeft or b.item.time
			return timeA < timeB
		end
		return false
	end)
	-- Now if there are multiple, e.g. torches, but some are used, pick the most used one.
	local picked = lights[1]
	return picked.item, picked.data
end

---@type tes3armor|nil, tes3weapon|nil, boolean, boolean
local lastShield, lastWeapon, weaponReady, skipNextUnequip

local function resetVariables()
	lastShield = nil
	lastWeapon = nil
	weaponReady = false
	skipNextUnequip = false
end
event.register(tes3.event.load, resetVariables)

-- Unequips a light if a player had any equipped. In that case it will also reequip the player's previous equipment.
---@return boolean unequipped
local function unequipLight()
	-- Look to see if we have a light equipped. If we have one, unequip it.
	local lightStack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.light })
	if not lightStack then
		return false
	end
	tes3.mobilePlayer:unequip({ type = tes3.objectType.light })

	-- If we had a shield equipped before, re-equip it.
	if lastShield then
		tes3.mobilePlayer:equip({ item = lastShield })
	end

	-- If we had a 2H weapon equipped before, re-equip it.
	if lastWeapon then
		-- Drawing a weapon also plays the equip sound. Don't play it twice.
		tes3.mobilePlayer:equip({ item = lastWeapon, playSound = not weaponReady })
	end

	-- If our weapon was out before then take it out again.
	if weaponReady then
		tes3.mobilePlayer.weaponReady = true
	end
	return true
end

event.register(tes3.event.weaponUnreadied, function(e)
	if e.reference ~= tes3.player then return end
	if skipNextUnequip then
		skipNextUnequip = false
		return
	end
	-- We don't need to take out the player's weapon anymore.
	weaponReady = false
end)

event.register(tes3.event.equipped, function(e)
	if e.reference ~= tes3.player then return end
	local item = e.item --[[@as tes3armor]]
	if item.objectType == tes3.objectType.armor and item.slot == tes3.armorSlot.shield then
		lastShield = nil
		return
	end
	if item.objectType == tes3.objectType.weapon then
		lastWeapon = nil
		weaponReady = false
		return
	end
end)

--- @param e keyDownEventData
local function swapForLight(e)
	if not tes3.isKeyEqual({ expected = config.hotkey, actual = e }) then return end
	if tes3.menuMode() then return end
	if unequipLight() then return end

	-- If we don't have a light equipped, try to find one.
	local light, data = getBestLight(tes3.player)
	if not light then
		tes3.messageBox("You have no lights")
		return
	end

	lastShield = nil
	lastWeapon = nil
	weaponReady = tes3.mobilePlayer.weaponReady

	local shieldStack = tes3.getEquippedItem({
		actor = tes3.player,
		objectType = tes3.objectType.armor,
		slot = tes3.armorSlot.shield
	})
	if shieldStack then
		lastShield = shieldStack.object
	end

	local weaponStack = tes3.getEquippedItem({
		actor = tes3.player,
		objectType = tes3.objectType.weapon
	})
	local probe = tes3.getEquippedItem({
		actor = tes3.player,
		objectType = tes3.objectType.probe
	})
	local lockpick = tes3.getEquippedItem({
		actor = tes3.player,
		objectType = tes3.objectType.lockpick
	})
	local hasFistsOut = not lockpick and not probe and weaponReady
	-- If a player had a weapon equipped that requires two hands, or fists out
	-- we need to put it down to show the light.
	local needsUnequip = false
	if weaponStack then
		if weaponStack.object.isTwoHanded or weaponStack.object.isRanged then
			needsUnequip = true
			lastWeapon = weaponStack.object
		end
	elseif hasFistsOut then
		needsUnequip = true
	end

	if needsUnequip then
		skipNextUnequip = true
		tes3.mobilePlayer.weaponReady = false
	end

	-- Equip the light we found.
	tes3.mobilePlayer:equip({
		item = light,
		itemData = data,
	})
end
event.register(tes3.event.keyDown, swapForLight)
