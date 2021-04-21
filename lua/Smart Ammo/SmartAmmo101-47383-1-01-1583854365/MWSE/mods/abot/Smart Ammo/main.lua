--[[
Ammo autoequip while bow/crossbow/thrown weapon readied
It will remember and prefer last hand-picked ammo if pressing Alt while equipping it
/abot
--]]

-- begin configurable parameters
local defaultConfig = {
autoEquipArrows = true, -- autoequip arrows
autoEquipBolts = true, -- autoequip bolts
autoEquipThrown = true, -- autoequip thrown weapons
autoEquipSort = 1, --  sorted autoequip 0 = off, 1 = less valuable first, 2 = more available first, 3 = less available first, 4 = more valuable first
debugLevel = 0, -- debug level 0 = off, 1 = log, 2 = messages, 3 = log + messages, 4 = modal messages, 5 = log + modal messages
}
-- end configurable parameters

local tk = {} -- why it must be so hard to keep things in order...
tk[1] = 'autoEquipArrows'
tk[2] = 'autoEquipBolts'
tk[3] = 'autoEquipThrown'
tk[4] = 'autoEquipSort'
tk[5] = 'debugLevel'

local author = 'abot'
local modName = 'Smart Ammo'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores

local lib = require(author .. '.lib')

-- http://dkolf.de/src/dkjson-lua.fsl/wiki?name=Documentation
local config = mwse.loadConfig(configName)
if not config then
	config = table.copy(defaultConfig)
	mwse.log("%s config restored to default", modPrefix)
	lib.logConfig(config, {indent = true, keyorder = tk})
end

local mcm = require(author .. '.' .. modName .. '.mcm')
mcm.config = table.copy(config)

local function modConfigReady()
	mwse.registerModConfig(author .. "'s " .. modName, mcm)
	mwse.log(modPrefix .. " modConfigReady")
	lib.logConfig(config, {keyorder = tk})
end
event.register('modConfigReady', modConfigReady)

function mcm.onClose()
	config = table.copy(mcm.config)
	lib.saveConfig(configName, config, {keyorder = tk})
end



local BOW_TYPE = tes3.weaponType.marksmanBow -- 9
local CROSSBOW_TYPE = tes3.weaponType.marksmanCrossbow -- 10
local THROWN_TYPE = tes3.weaponType.marksmanThrown -- 11
local ARROW_TYPE = tes3.weaponType.arrow -- 12
local BOLT_TYPE = tes3.weaponType.bolt -- 13

local AMMUNITION_TYPE = tes3.objectType.ammunition -- 1330466113
local WEAPON_TYPE = tes3.objectType.weapon -- 1346454871

local inputController -- set on initialized()

-- set on loaded()
local player
local mobilePlayer

---local skipEquipped -- used in equipped(
---local skipUnequipped -- used in unequipped(

local bit = require('bit')

local function debugMsg(s)
	---local dbug = tes3.getGlobal('ab01debug')
	local dbug = config.debugLevel
	if dbug then
		if bit.band(dbug, 4) == 4 then
			tes3.messageBox({ message = s, buttons = {'OK'} })
		elseif bit.band(dbug, 2) == 2 then
			tes3.messageBox(s)
		end
		if bit.band(dbug, 1) == 1 then
			mwse.log(s)
		end
	end
end

---local skipStoringAmmo
local function storeAmmo(ammoType, ammoId)
	--[[
	if skipStoringAmmo then
		skipStoringAmmo = false
		mwse.log("skipStoringAmmo player.data.ab01HandpickedAmmoId[%s] = %s", ammoType, ammoId)
		return
	end
	--]]
	assert(player.data)
	assert(player.data.ab01HandpickedAmmoId)
	player.data.ab01HandpickedAmmoId[ammoType] = ammoId
	debugMsg(string.format("%s setting player.data.ab01HandpickedAmmoId[%s] = %s", modPrefix, ammoType, ammoId))
end

local GUI_ID_MenuInventory = tes3ui.registerID('MenuInventory')
---local GUI_ID_MenuInventory_scrollpane = tes3ui.registerID('MenuInventory_scrollpane')
---local GUI_ID_PartScrollPane_pane = tes3ui.registerID('PartScrollPane_pane')

local function updateInventory()
	local mainMenu = tes3ui.findMenu(GUI_ID_MenuInventory)
	if mainMenu then
		mainMenu:updateLayout()
	end
	tes3ui.forcePlayerInventoryUpdate()
end

local aeAmmoType
local aeItemId

local function unequipAmmoType()
	if aeAmmoType == THROWN_TYPE then
		--[[
		if mobilePlayer.weaponReady then
			mobilePlayer.weaponReady = false -- hands down, try to avoid crime making
		end
		--]]
		if mobilePlayer.readiedWeapon then
			---skipUnequipped = true
			mobilePlayer:unequip({ type = WEAPON_TYPE })
			if tes3.menuMode() then
				timer.frame.delayOneFrame(updateInventory)
			end
		end
		return
	end

	local readiedAmmoCount = mobilePlayer.readiedAmmoCount
	if not readiedAmmoCount then
		return
	end
	if readiedAmmoCount <= 0 then
		return
	end
	local readiedAmmo = mobilePlayer.readiedAmmo
	if not readiedAmmo then
		return
	end

	---skipUnequipped = true
	mobilePlayer:unequip({ type = AMMUNITION_TYPE })
	if tes3.menuMode() then
		timer.frame.delayOneFrame(updateInventory)
	end
end

local function alreadyEquipped()
	local readiedAmmo = mobilePlayer.readiedAmmo
	if not readiedAmmo then
		return false
	end
	local readiedAmmoCount = mobilePlayer.readiedAmmoCount
	if not readiedAmmoCount then
		return false
	end
	if readiedAmmoCount <= 0 then
		return false
	end
	local readiedAmmoObj = readiedAmmo.object
	if not readiedAmmoObj then
		return false
	end
	if not (readiedAmmoObj.type == aeAmmoType) then
		return false
	end
	debugMsg(string.format("%s alreadyEquipped() %s proper ammo already equipped", modPrefix, readiedAmmoCount))
	return true -- proper readiedAmmoObj type already equipped
end

local function AequipItem()
	if alreadyEquipped() then
		return
	end
	local menuMode = tes3.menuMode()
	if not menuMode then -- important! else it may loop?
		local actionData = mobilePlayer.actionData
		if actionData then
			local animState = actionData.animationAttackState
--[[
return {["idle"] = 0,["ready"] = 1,["swingUp"] = 2,["swingDown"] = 3,["swingHit"] = 4,["swingFollowLight"] = 5,
	["swingFollowMed"] = 6,["swingFollowHeavy"] = 7,["readyingWeap"] = 8,["unreadyWeap"] = 9,["casting"] = 10,
	["casting2"] = 11,["readyingMagic"] = 12,["unreadyMagic"] = 13,["knockdown"] = 14,["knockedOut"] = 15,
	["pickingProbing"] = 16,-- ["unknown_0x11"] = 17,["dying"] = 18,["dead"] = 19,
--]]
			if animState > 1 then -- player animation
				timer.frame.delayOneFrame(AequipItem)
				return
			end
		end
	end
	---skipStoringAmmo = true
	---skipEquipped = true

	if mwscript.getItemCount({ reference = player, item = aeItemId }) > 0 then -- safety

		---assert(player == tes3.player) -- never say never
		---assert(mobilePlayer == tes3.mobilePlayer)

		mwscript.equip({ reference = player, item = aeItemId })
		if menuMode then
			timer.frame.delayOneFrame(updateInventory)
		end
	end
end

local function AequipAmmo()
	unequipAmmoType() --- needed else inventory does not refresh well
	timer.frame.delayOneFrame(AequipItem)
end

local function autoEquipAmmo()
	if alreadyEquipped() then
		return
	end

	local obj = player.object
	local inventory = obj.inventory

	if player.data then
		if player.data.ab01HandpickedAmmoId then
			local ammoId = player.data.ab01HandpickedAmmoId[aeAmmoType]
			---debugMsg(string.format("%s autoEquipAmmo() stored ammo %s %s", modPrefix, aeAmmoType, ammoId))
			if ammoId then
				if mwscript.getItemCount({ reference = player, item = ammoId }) > 0 then -- important safety!!!
					aeItemId = ammoId
					debugMsg(string.format("%s autoEquipAmmo() autoequipping %s", modPrefix, aeItemId))
					---timer.frame.delayOneFrame(AequipAmmo)
					AequipAmmo()
					return -- important!
				end
			end
		end
	end

	local i, c, v
	local ammos = {}
	local mode = config.autoEquipSort
	local item
	for stack in tes3.iterate(inventory.iterator) do
		item = stack.object
		if item.type == aeAmmoType then
			i = item.id
			if i then
				if not i:lower():find('_uni') then
					c = stack.count
					v = item.value
					table.insert(ammos, { id = i, value = v, count = c } )
				end
			end
		end
	end
	if #ammos <= 0 then
		return
	end
	if mode == 1 then
		table.sort(ammos, function(a,b) return a.value < b.value end) -- less valuable first
	elseif mode == 2 then
		table.sort(ammos, function(a,b) return a.count > b.count end) -- more available first
	elseif mode == 3 then
		table.sort(ammos, function(a,b) return a.count < b.count end) -- less available first
	elseif mode == 4 then
		table.sort(ammos, function(a,b) return a.value > b.value end) -- more valuable first
	end
	aeItemId = ammos[1].id
	debugMsg(string.format("%s autoEquipAmmo() autoequipping %s", modPrefix, aeItemId))
	AequipAmmo()
end


local function autoEquipAmmoType(aType)
	---assert(aType)
	aeAmmoType = aType
	autoEquipAmmo()
end

local function projectileExpire(e)
	if not (e.firingReference == player) then
		return
	end
	---debugMsg(string.format("%s projectileExpire() firingWeapon %s", modPrefix, e.firingWeapon))
	local firingWeaponObj = e.firingWeapon
	local firingWeaponType = firingWeaponObj.type

	local readiedWeapon = mobilePlayer.readiedWeapon
	local readiedWeaponObj
	local readiedWeaponType
	if readiedWeapon then
		readiedWeaponObj = readiedWeapon.object
		readiedWeaponType = readiedWeaponObj.type
	end

	if firingWeaponType == THROWN_TYPE then
		if not (readiedWeaponType == firingWeaponType) then
			if config.autoEquipThrown then
				debugMsg(string.format("%s projectileExpire() firingWeaponType == THROWN_TYPE, autoEquip", modPrefix))
				autoEquipAmmoType(THROWN_TYPE)
			end
		end
		return
	end

	if not readiedWeapon then -- readiedWeapon really means like standard scripting HasItemEquipped
		return
	end

	--[[
	if not mobilePlayer.weaponReady then -- this is equivalent to standard scripting GetWeaponDrawn
		mobilePlayer.weaponReady = false -- hands down, try to avoid crime making
	end
	--]]

	local readiedAmmo = mobilePlayer.readiedAmmo
	local readiedAmmoObj
	local readiedAmmoType
	if readiedAmmo then
		readiedAmmoObj = readiedAmmo.object
		readiedAmmoType = readiedAmmoObj.type
	end

	local readiedAmmoCount = mobilePlayer.readiedAmmoCount
	if firingWeaponType == BOW_TYPE then
		if readiedWeaponType == BOW_TYPE then
			if config.autoEquipArrows then
				if not (readiedAmmoType == ARROW_TYPE) then
					debugMsg(string.format("%s projectileExpire() readiedWeaponType == BOW_TYPE, autoEquip ARROW_TYPE", modPrefix))
					autoEquipAmmoType(ARROW_TYPE)
					return
				end
				if readiedAmmoCount then
					if readiedAmmoCount <= 0 then
						debugMsg(string.format("%s projectileExpire() readiedWeaponType == BOW_TYPE, count 0 autoEquip ARROW_TYPE", modPrefix))
						autoEquipAmmoType(ARROW_TYPE)
					end
				end
			end
		end
		return
	end

	if firingWeaponType == CROSSBOW_TYPE then
		if readiedWeaponType == CROSSBOW_TYPE then
			if config.autoEquipBolts then
				if not (readiedAmmoType == BOLT_TYPE) then
					debugMsg(string.format("%s projectileExpire() readiedWeaponType == CROSSBOW_TYPE, autoEquip BOLT_TYPE", modPrefix))
					autoEquipAmmoType(BOLT_TYPE)
					return
				end
				if readiedAmmoCount then
					if readiedAmmoCount <= 0 then
						debugMsg(string.format("%s projectileExpire() readiedWeaponType == CROSSBOW_TYPE, count 0 autoEquip BOLT_TYPE", modPrefix))
						autoEquipAmmoType(BOLT_TYPE)
					end
				end
			end
		end
	end

end

local function weaponReadied(e)
	if not (e.reference == player) then
		return
	end
	debugMsg(string.format("%s weaponReadied()", modPrefix))
	---assert(e.weaponStack)
	if not e.weaponStack then
		return --- it happens
	end
	local readiedWeaponObj = e.weaponStack.object
	if not readiedWeaponObj then
		return
	end
	local readiedWeaponType = readiedWeaponObj.type
	if readiedWeaponType == THROWN_TYPE then
		debugMsg(string.format("%s weaponReadied() readiedWeaponType == THROWN_TYPE, return", modPrefix))
		return
	end

	local readiedAmmo = mobilePlayer.readiedAmmo
	local readiedAmmoObj
	local readiedAmmoType
	if readiedAmmo then
		readiedAmmoObj = readiedAmmo.object
		readiedAmmoType = readiedAmmoObj.type
	end

	local readiedAmmoCount = mobilePlayer.readiedAmmoCount
	if readiedWeaponType == BOW_TYPE then
		if config.autoEquipArrows then
			if not (readiedAmmoType == ARROW_TYPE) then
				debugMsg(string.format("%s weaponReadied() readiedWeaponType == BOW_TYPE, autoEquip ARROW_TYPE", modPrefix))
				autoEquipAmmoType(ARROW_TYPE)
				return
			end
			-- must check this, readiedAmmo may still be not nil with ammo count 0
			if (not readiedAmmoCount) or (readiedAmmoCount <= 0) then
				debugMsg(string.format("%s weaponReadied() readiedWeaponType == BOW_TYPE, count 0 autoEquip ARROW_TYPE", modPrefix))
				autoEquipAmmoType(ARROW_TYPE)
			end
		end
		return
	end

	if readiedWeaponType == CROSSBOW_TYPE then
		if config.autoEquipBolts then
			if not (readiedAmmoType == BOLT_TYPE) then
				debugMsg(string.format("%s weaponReadied() readiedWeaponType == CROSSBOW_TYPE, autoEquip BOLT_TYPE", modPrefix))
				autoEquipAmmoType(BOLT_TYPE)
				return
			end
			-- must check this, readiedAmmo may still be not nil with ammo count 0
			if (not readiedAmmoCount) or (readiedAmmoCount <= 0) then
				debugMsg(string.format("%s weaponReadied() readiedWeaponType == CROSSBOW_TYPE, count 0 autoEquip BOLT_TYPE", modPrefix))
				autoEquipAmmoType(ARROW_TYPE)
			end
		end
	end

end

local LALT = tes3.scanCode.lAlt
local RALT = tes3.scanCode.rAlt

local function isAltDown()
	return inputController:isKeyDown(LALT)
		or inputController:isKeyDown(RALT)
end

--[[
when swapping ammo, event order is:
1. equip(new ammo)
2. unequipped(old ammo)
3. equipped(new ammo)
--]]

local function unequipped(e)
	if not tes3.menuMode() then
		return
	end
	if not (e.mobile == mobilePlayer) then
		return
	end
	---debugMsg(string.format("%s unequipped()", modPrefix))
	--[[
	if skipUnequipped then
		skipUnequipped = false
		return
	end
	--]]
	if not isAltDown() then
		return
	end
	if not player.data then
		assert(player.data)
		return
	end
	if not player.data.ab01HandpickedAmmoId then
		assert(player.data.ab01HandpickedAmmoId)
		return
	end
	local item = e.item
	---assert(item)
	local itemId = item.id
	---assert(itemId)
	for ammoType, ammoId in pairs(player.data.ab01HandpickedAmmoId) do
		---debugMsg(string.format("%s unequipped() stored ammo %s %s", modPrefix, ammoType, ammoId))
		if ammoId == itemId then
			tes3.messageBox("%s preference cleared", item.name)
			player.data.ab01HandpickedAmmoId[ammoType] = false
			---debugMsg(string.format("%s unequipped() setting player.data.ab01HandpickedAmmoId[%s] to false", modPrefix, ammoType))
		end
	end
end

local function equipped(e)
	if not (e.mobile == mobilePlayer) then
		return
	end
	--[[
	if skipEquipped then
		debugMsg(string.format("%s equipped() skipEquipped", modPrefix))
		skipEquipped = false
		return
	end
	--]]
	---debugMsg(string.format("%s equipped()", modPrefix))

	local equippedItem = e.item
	local equippedItemId = equippedItem.id
	local equippedItemType = equippedItem.type

	if tes3.menuMode() then
		if isAltDown() then
			if (equippedItemType == THROWN_TYPE)
			or (equippedItemType == ARROW_TYPE)
			or (equippedItemType == BOLT_TYPE) then
				---debugMsg(string.format("%s equipped() type %s %s stored", modPrefix, equippedItemType, equippedItemId))
				tes3.messageBox("%s preference stored", equippedItem.name)
				storeAmmo(equippedItemType, equippedItemId)
				return
			end
		end
	end

	if equippedItemType == THROWN_TYPE then
		debugMsg(string.format("%s equipped() THROWN_TYPE", modPrefix))
		return
	end

	local readiedAmmo = mobilePlayer.readiedAmmo
	local readiedAmmoCount = mobilePlayer.readiedAmmoCount

	local readiedAmmoObj
	local readiedAmmoType
	if readiedAmmo then
		readiedAmmoObj = readiedAmmo.object
		readiedAmmoType = readiedAmmoObj.type
	end

	if readiedAmmo and readiedAmmoCount and (readiedAmmoCount > 0) then
		if (
				(equippedItemType == BOW_TYPE)
			and (readiedAmmoType == ARROW_TYPE)
			)
		or (
				(equippedItemType == CROSSBOW_TYPE)
			and (readiedAmmoType == BOLT_TYPE)
			) then
			debugMsg(string.format("%s equipped() %s, ammo already loaded, skip", modPrefix, equippedItemId))
			return
		end
	end

	if equippedItemType == BOW_TYPE then
		if config.autoEquipArrows then
			if not (readiedAmmoType == ARROW_TYPE) then
				debugMsg(string.format("%s equipped() BOW_TYPE, autoEquip ARROW_TYPE", modPrefix))
				autoEquipAmmoType(ARROW_TYPE)
				return
			end
		end
	elseif equippedItemType == CROSSBOW_TYPE then
		if config.autoEquipBolts then
			if not (readiedAmmoType == BOLT_TYPE) then
				debugMsg(string.format("%s equipped() CROSSBOW_TYPE, autoEquip BOLT_TYPE", modPrefix))
				autoEquipAmmoType(BOLT_TYPE)
				return
			end
		end
	end

	local readiedWeapon = mobilePlayer.readiedWeapon
	if not readiedWeapon then
		return
	end

	local weaponObj = readiedWeapon.object
	local readiedWeaponType = weaponObj.type
	if readiedWeaponType == THROWN_TYPE then
		debugMsg(string.format("%s equipped() %s, readied %s", modPrefix, equippedItemId, weaponObj.id))
		return
	end

	if readiedWeaponType == BOW_TYPE then
		if not (readiedAmmoType == ARROW_TYPE) then
			if config.autoEquipArrows then
				debugMsg(string.format("%s equipped() readiedWeaponType == BOW_TYPE, autoequip ARROW_TYPE", modPrefix))
				autoEquipAmmoType(ARROW_TYPE)
			end
		end
		return
	end

	if readiedWeaponType == CROSSBOW_TYPE then
		if not (readiedAmmoType == BOLT_TYPE) then
			if config.autoEquipBolts then
				debugMsg(string.format("%s equipped() readiedWeaponType == CROSSBOW_TYPE, autoequip BOLT_TYPE", modPrefix))
				autoEquipAmmoType(BOLT_TYPE)
			end
		end
	end

end

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	if not player.data then
		player.data = {}
	end
	if not player.data.ab01HandpickedAmmoId then
		player.data.ab01HandpickedAmmoId = {}
	end
end

local function save()
	if not player.data then
		player.data = {}
	end
	if not player.data.ab01HandpickedAmmoId then
		player.data.ab01HandpickedAmmoId = {}
	end
end

local function initialized()
	inputController = tes3.worldController.inputController
	event.register('loaded', loaded)
	event.register('save', save)
	event.register('weaponReadied', weaponReadied)
	event.register('unequipped', unequipped)
	event.register('equipped', equipped)
	event.register('projectileExpire', projectileExpire)
end

event.register('initialized', initialized)
