--[[
Auto equip last equipped shield/parrying weapon on 1 handed weapon readied.
Shift + drop the shield to auto equip it no more, or equip a different shield
]]

local author = 'abot'
local modName = 'Smart Shield'
local modPrefix = author .. '/' .. modName

local logLevel = 0

local tes3_weaponType = tes3.weaponType
local oneHandedWeapon = {
[tes3_weaponType.shortBladeOneHand] = true,
[tes3_weaponType.longBladeOneHand] = true,
[tes3_weaponType.bluntOneHand] = true,
[tes3_weaponType.axeOneHand] = true,
[tes3_weaponType.marksmanThrown] = true,
}

local weaponType = table.invert(tes3_weaponType)

-- set in loaded
local player
local mobilePlayer
local lastShieldId

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	lastShieldId = nil
	local data = player.data
	if not data then
		return
	end
	lastShieldId = data.ab01lastShieldId
end

local function save()
	local data = player.data
	if not data then
		player.data = {}
		data = player.data
	end
	data.lastShieldId = nil -- temporary to clean old id
	data.ab01lastShieldId = lastShieldId
end

local function weaponReadied(e)
	if not (e.reference == player) then
		return
	end
	if not e.weaponStack then
		return --- it happens
	end

	local readiedWeaponObj = e.weaponStack.object
	if not readiedWeaponObj then
		return
	end

	local readiedWeaponType = readiedWeaponObj.type
	if not oneHandedWeapon[readiedWeaponType] then
		return
	end

	if logLevel > 0 then
		mwse.log("%s: weaponReadied(e) readiedWeaponType = %s (%s) oneHandedWeapon[readiedWeaponType] = true",
			modPrefix, readiedWeaponType, weaponType[readiedWeaponType])
	end

	local readiedShieldStack = mobilePlayer.readiedShield
	if readiedShieldStack then
		if logLevel > 0 then
			mwse.log("%s: weaponReadied(e) readiedShieldStack.object = %s", modPrefix, readiedShieldStack.object.id)
		end
		return
	end

	if not lastShieldId then
		if logLevel > 0 then
			mwse.log("%s: weaponReadied(e) lastShieldId = %s", modPrefix, lastShieldId)
		end
		return
	end

	if not player.object.inventory:contains(lastShieldId) then
		if logLevel > 0 then
			mwse.log('%s: weaponReadied(e) not player.object.inventory:contains("%s")', modPrefix, lastShieldId)
		end
		lastShieldId = nil
		return
	end

	if logLevel > 0 then
		mwse.log('%s: weaponReadied(e) "%s" re-equipped', modPrefix, lastShieldId)
	end
---@diagnostic disable-next-line: deprecated
	mwscript.equip({reference = player, item = lastShieldId})
end

local tes3_objectType_armor = tes3.objectType.armor
local tes3_armorSlot_shield = tes3.armorSlot.shield

local function equipped(e)
	if not (e.reference == player) then
		return
	end
	local obj = e.item
	if not (obj.objectType == tes3_objectType_armor ) then
		return
	end
	if not (obj.slot == tes3_armorSlot_shield ) then
		return
	end
	lastShieldId = obj.id:lower()
	if logLevel > 0 then
		mwse.log("%s: equipped(e) lastShieldId = %s", modPrefix, lastShieldId)
	end
end

local tes3_scanCode_lShift = tes3.scanCode.lShift
local tes3_scanCode_rShift = tes3.scanCode.rShift

local inputController
local function isShiftDown()
	return inputController:isKeyDown(tes3_scanCode_lShift)
		or inputController:isKeyDown(tes3_scanCode_rShift)
end

local function itemDropped(e)
	local obj = e.reference.object
	if not (obj.objectType == tes3_objectType_armor ) then
		return
	end
	if not (obj.slot == tes3_armorSlot_shield) then
		return
	end
	if not isShiftDown() then
		return
	end
	local id = obj.id:lower()
	if logLevel > 0 then
		mwse.log("%s: itemDropped(e) obj.id:lower() == %s", modPrefix, id)
	end
	if id == lastShieldId then
		if logLevel > 0 then
			mwse.log("%s: itemDropped(e) obj.id:lower() == lastShieldId = %s", modPrefix, lastShieldId)
		end
		lastShieldId = nil
	end
end

event.register('initialized', function()
	inputController = tes3.worldController.inputController
	assert(inputController)
	event.register('itemDropped', itemDropped)
	event.register('loaded', loaded)
	event.register('save', save)
	event.register('equipped', equipped)
	event.register('weaponReadied', weaponReadied)
	mwse.log("%s initialized", modPrefix)
end)