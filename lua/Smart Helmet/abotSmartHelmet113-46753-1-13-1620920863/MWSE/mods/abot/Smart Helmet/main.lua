--[[
Swap helmet with Alt+Z key /abot
--]]

-- begin configurable parameters
local defaultConfig = {
autoSwapHostiles = true, -- autoSwap player helmet on/off on cell changed depending on hostiles nearby
minActorAiFightTrigger = 82, -- Min actor AI Fight setting to be judged hostile
maxHostileDistanceTrigger = 3500, -- Max distance of hostile actor from player to trigger helmet equipping
autoSwapWeather = true, -- autoSwap player helmet on/off depending on weather
autoSwapEnchanted = true, -- allow automatic unequip of enchanted helmets
autoSwapLight = true, -- autoSwap player enchanted helmet on/off depending on darkness
lightThreshold = 15, -- light level threshold for darkness
logLevel = 0, -- 0 = none, 1 = low, 2 = verbose
}
-- end configurable parameters

local author = 'abot'
local modName = 'Smart Helmet'
local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

-- 2nd parameter advantage: anything not defined in the loaded file inherits the value from defaultConfig
local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local mcm = require(author .. '.' .. modName .. '.mcm')
mcm.config = table.copy(config)

local function modConfigReady()
	mwse.registerModConfig(mcmName, mcm)
	mwse.log(modPrefix .. " modConfigReady")
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)

function mcm.onClose()
	config = table.copy(mcm.config)
	mwse.saveConfig(configName, config, {indent = false})
end

local ARMO = tes3.objectType.armor
local HELMETslot = tes3.armorSlot.helmet


-- set in loaded()
local worldController
local inputController
local player
local mobilePlayer

local lastHelmetId
local autoEquipped

local ENCH_TYPE_CONSTANT = tes3.enchantmentType.constant
local EFFECT_RANGE_SELF = tes3.effectRange.self
local EFFECT_LIGHT = tes3.effect.light
local EFFECT_NIGHTEYE = tes3.effect.nightEye

local function hasConstantVisionEnchantment(obj)
	local ench = obj.enchantment
	if not ench then
		return false
	end
	if not (ench.castType == ENCH_TYPE_CONSTANT) then
		return false
	end
	local efs = ench.effects
	if not efs then
		return false
	end
	local eff, id
	for i = 1, #efs do
		eff = efs[i]
		if eff then
			id = eff.id
			if id >= 0 then -- effects is a fixed size array, empty slots have id -1
				if (id == EFFECT_LIGHT)
				or (id == EFFECT_NIGHTEYE) then
					if eff.rangeType == EFFECT_RANGE_SELF then
						if eff.min > 0 then
							return true
						end
					end
				end
			end
		end
	end
end

local function hasConstantEnchantment(obj)
	local ench = obj.enchantment
	if not ench then
		return false
	end
	if not (ench.castType == ENCH_TYPE_CONSTANT) then
		return false
	end
	local efs = ench.effects
	if not efs then
		return false
	end
	return true
end

local function getLuma(cell)
	local ambientColor = cell.ambientColor
	---assert(ambientColor)
	local sunColor = cell.sunColor
	---assert(sunColor)
	local fogColor = cell.fogColor
	---assert(fogColor)
	local fogDensity = cell.fogDensity
	---assert(fogDensity)
	local r = ( (fogColor.r * fogDensity) + ambientColor.r + sunColor.r ) / 3
	local g = ( (fogColor.g * fogDensity) + ambientColor.g + sunColor.g ) / 3
	local b = ( (fogColor.b * fogDensity) + ambientColor.b + sunColor.b ) / 3
	local luma = (0.299 * r) + (0.587 * g) + (0.114 * b)
	---mwse.log("%s getLuma(%s) = %s", modPrefix, cell.name, luma)
	return luma
end

local function cellHasWeather(cell)
	local interior = cell.isInterior
	if interior then
		if cell.behavesAsExterior then
			interior = false
		end
	end
	return not interior
end

local function isDark()
	local cell = tes3.getPlayerCell()
	if cellHasWeather(cell) then
		local hourObj = worldController.hour
		local gameHour = hourObj.value
		local nightTime = (gameHour < 6) or (gameHour > 20)
		return nightTime
	end
	if not config then
		assert(config)
		return false
	end
	local lt = config.lightThreshold
	if not lt then
		assert(lt)
		return false
	end
	if lt <= 0 then
		return false
	end
	return getLuma(cell) < lt
end

local visionEnhanceHelmetCache = {} -- cache for constant vision enhancement enchanted helmets
local enchantedHelmetCache = {} -- cache for constant enchantment helmets

--[[
reference: tes3reference. Read-only. A reference to the mobilePlayer actor that is equipping the item.
item: tes3baseObject. Read-only. The object being equipped.
itemData: tes3itemData. Read-only. The item data of item.
Filter: This event may be filtered by reference.
--]]
--[[
local function equip(e)
	if not (e.reference == mobilePlayer) then
		return
	end

	local obj = e.item
	if obj.objectType == ARMO then
		if obj.slot == HELMETslot then
			lastHelmetId = obj.id
		end
	end
end
--]]

local function getFirstHostile(cell, fightLevel, maxDistance)
	for actor in tes3.iterate(cell.actors) do
		local mobile = actor.mobile
		if mobile then
			if not (mobile.actorType == 2) then -- 0 = creature, 1 = NPC, 2 = player
				if mobile.fight >= fightLevel then
					local health = mobile.health
					if health then
						if health.current then
							if health.current > 0 then
								if player.position:distance(mobile.position) <= maxDistance then
									return mobile
								end
							end
						end
					end
				end
			end
		end
	end
	return false
end

local function getCurrentWeather()
 -- -1 something wrong, 0 Clear, 1 Cloudy, 2 Foggy, 3 Overcast, 4 Rain, 5 Thunder, 6 Ash, 7 Blight, 8 Snow, 9 Blizzard

	--[[
	local wc = tes3.getWorldController()
	if not wc then
		assert(wc)
		return -1
	end
	assert(wc == worldController)
	--]]
	local weatherController = worldController.weatherController
	if not weatherController then
		assert(weatherController)
		return -1
	end
	local currentWeather = weatherController.currentWeather
	if not currentWeather then
		return -1
	end
	return currentWeather.index
end

local function isBadWeather()
	local w = getCurrentWeather()
 -- 4 Rain, 5 Thunder, 6 Ash, 7 Blight, 8 Snow, 9 Blizzard
	local bad = ( w >= 4 ) and ( w <= 9 )
	---tes3.messageBox(string.format("weather = %s, bad = %s", w, bad))
	return bad

end

local function inGoodCondition(obj)
	local itemData = obj.itemData
	if itemData then
		local condition = itemData.condition
		if condition then
			return condition > 0
		else
			return true
		end
	else
		return true
	end
end


local function equipSomeHelmet(visionOnly)
	local inventory = player.object.inventory
	local helmets = {}
	local ob, obId
	local helmetCount = 0
	for stack in tes3.iterate(inventory.iterator) do
		ob = stack.object
		if ob then
			if ob.objectType == ARMO then
				if ob.slot == HELMETslot then
					if inGoodCondition(ob) then
						helmetCount = helmetCount + 1
						helmets[helmetCount] = ob
						---mwse.log("%s: helmets[%s] = %s", modPrefix, ob.id, ob.name)
					end
				end
			end
		end
	end
	
	if helmetCount <= 0 then
		if not autoEquipped then
			tes3.messageBox('You have no helmets')
		end
		return
	end

	if not visionOnly then
		if lastHelmetId then
			---mwse.log("%s equipSomeHelmet()", modPrefix)
			for _, obj in pairs(helmets) do
				---mwse.log("%s objId = %s lastHelmetId = %s", modPrefix, obj.id, lastHelmetId)
				if obj.id == lastHelmetId then
					mwscript.equip({reference = player, item = obj.id})
					if config.logLevel > 0 then
						mwse.log("%s equipping helmet %s %s", modPrefix, obj.id, obj.name)
					end
					return
				end
			end
		end
	end

	if visionOnly then
		if config.autoSwapEnchanted then
			if config.autoSwapLight then
				local found
				for _, obj in pairs(helmets) do
					found = visionEnhanceHelmetCache[obj.id]
					if not found then
						if hasConstantVisionEnchantment(obj) then
							visionEnhanceHelmetCache[obj.id] = true
							found = true
						end
					end
					if found then
						mwscript.equip({reference = player, item = obj.id})
						if config.logLevel > 0 then
							mwse.log("%s equipping vision enhanced helmet %s %s", modPrefix, obj.id, obj.name)
						end
						return
					end
				end
			end
		end
		return
	end

	if config.autoSwapEnchanted then
		local found
		for _, obj in pairs(helmets) do
			found = enchantedHelmetCache[obj.id]
			if not found then
				if hasConstantEnchantment(obj) then
					enchantedHelmetCache[obj.id] = true
					found = true
				end
			end
			if found then
				mwscript.equip({reference = player, item = obj.id})
				if config.logLevel > 0 then
					mwse.log("%s equipping enchanted helmet %s %s", modPrefix, obj.id, obj.name)
				end
				return
			end
		end
		return
	end

	table.sort(helmets, function(a,b) return a.value > b.value end) -- more valuable first
	obId = helmets[1].id
	mwscript.equip({reference = player, item = obId})
	if config.logLevel > 0 then
		ob = tes3.getObject(obId)
		if ob then
			mwse.log("%s equipping helmet %s %s", modPrefix, obId, ob.name )
		end
	end
end

local function getEquippedPlayerHelmet()
	return tes3.getEquippedItem({ actor = player, objectType = ARMO, slot = HELMETslot })
end

--[[
local function unequipHelmet()
	local equippedHelmetStack = getEquippedPlayerHelmet()
	if equippedHelmetStack then
		local helmet = equippedHelmetStack.object
		if helmet then
			---lastHelmetId = helmet.id
			mobilePlayer:unequip({armorSlot = HELMETslot})
		end
	end
end
--]]

-- functions to e.g. avoid heavy/crashy loops on CellChange
-- when player is moving too fast e.g. superjumping

local scenicTravelAvailable  -- set in initialized()

local function initScenicTravelAvailable() -- call it in initialized()
	if tes3.getGlobal('ab01boDest') then
		scenicTravelAvailable = true
	elseif tes3.getGlobal('ab01ssDest') then
		scenicTravelAvailable = true
	elseif tes3.getGlobal('ab01goDest') then
		scenicTravelAvailable = true
	elseif tes3.getGlobal('ab01compMounted') then
		scenicTravelAvailable = true
	else
		scenicTravelAvailable = false
	end
end

local function isGlobalPositive(globalVarId)
	local v = tes3.getGlobal(globalVarId)
	if v then
		if v > 0 then
			if math.floor(v) > 0 then
				return true
			end
		end
	end
	return false
end

local function isPlayerScenicTraveling()
	if not scenicTravelAvailable then
		return false
	end
	if isGlobalPositive('ab01boDest') then
		return true -- if scenic boat traveling
	end
	if isGlobalPositive('ab01ssDest') then
		return true -- if scenic strider traveling
	end
	if isGlobalPositive('ab01goDest') then
		return true -- if scenic gondola traveling
	end
	if isGlobalPositive('ab01compMounted') then
		return true -- if guar riding
	end
end

local function isPlayerMovingFast()
	if mobilePlayer then
		local velocity = mobilePlayer.velocity
		if velocity then
			if #velocity >= 300 then
				return true
			end
		end
	end
	return false
end

local function cellChanged(e)

	if isPlayerMovingFast() then
		return
	end

	local doEquip = false
	local visionOnly = false

	if config.autoSwapHostiles then
		if not e.cell.restingIsIllegal then -- skip safe settlement
			if not isPlayerScenicTraveling() then
				local hostileActor = getFirstHostile(e.cell, config.minActorAiFightTrigger, config.maxHostileDistanceTrigger)
				if hostileActor then
					doEquip = true
					if config.logLevel > 0 then
						mwse.log("%s cellChanged hostile actor detected, looking for a helmet to equip", modPrefix)
					end
				end
			end
		end
	end

	if not doEquip then
		if config.autoSwapWeather then
			if cellHasWeather(e.cell) then
				doEquip = isBadWeather()
				if doEquip then
					if config.logLevel > 1 then
						mwse.log("%s cellChanged bad weather detected, looking for a helmet to equip", modPrefix)
					end
				end
			end
		end
	end

	if not doEquip then
		if config.autoSwapEnchanted then
			if config.autoSwapLight then
				visionOnly = isDark()
				if visionOnly then
					doEquip = true
					if config.logLevel > 1 then
						mwse.log("%s cellChanged darkness detected, looking for a helmet to equip", modPrefix)
					end
				end
			end
		end
	end

	if not doEquip then
		if lastHelmetId then
			if config.autoSwapEnchanted then -- auto swapping of enchanted helmet enabled
				local ob = tes3.getObject(lastHelmetId)
				if ob then
					if ob.enchantment then
						return -- return as enchanted helmet equipped
					end
				end
			end
		end
	end

	local equippedHelmetStack = getEquippedPlayerHelmet()
	if equippedHelmetStack then
		if not doEquip then
			---unequipHelmet()
			---tes3.messageBox("auto unequipping helmet...")
			if not (mobilePlayer == tes3.mobilePlayer) then
				mwse.log("%s cellChanged WARNING mobilePlayer != tes3.mobilePlayer", modPrefix)
			end
			--- mobilePlayer:unequip({armorSlot = HELMETslot}) -- this may trigger Better Clothes warnings spamming the log
			pcall( mobilePlayer:unequip({armorSlot = HELMETslot}) )
			if config.logLevel > 0 then
				mwse.log("%s cellChanged unequipping helmet", modPrefix)
			end
		end
		return
	end

	if not doEquip then
		return
	end

	---tes3.messageBox("auto equipping helmet...")
	autoEquipped = true
	equipSomeHelmet(visionOnly)
end

local function toggleHelmet()
	local equippedHelmetStack = getEquippedPlayerHelmet()
	if equippedHelmetStack then
		---unequipHelmet()

		-- to avoid Better CLothes warnings spamming the mwse.log
		pcall( mobilePlayer:unequip({armorSlot = HELMETslot}) )
	else
		equipSomeHelmet(false)
	end
end

local function loaded()
	worldController = tes3.worldController
	inputController = worldController.inputController
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer

	visionEnhanceHelmetCache = {}
	enchantedHelmetCache = {}

	local playerData = player.data
	if not playerData then
		return
	end
	local data = playerData.ab01smartHelmet
	if not data then
		return
	end
	lastHelmetId = data.lastHelmetId
	autoEquipped = data.autoEquipped
end

local function save()
	local playerData = player.data
	if not playerData then
		return
	end
	if playerData.ab01lastHelmetId then
		playerData.ab01lastHelmetId = nil
	end
	if not playerData.ab01smartHelmet then
		playerData.ab01smartHelmet = {}
	end
	playerData.ab01smartHelmet.lastHelmetId = lastHelmetId
	playerData.ab01smartHelmet.autoEquipped = autoEquipped
end

local LALT = tes3.scanCode.lAlt
local RALT = tes3.scanCode.rAlt

local function isAltDown()
	return inputController:isKeyDown(LALT)
		or inputController:isKeyDown(RALT)
end

local function keyDown(e)
	if not e.isAltDown then
		return
	end
	if tes3.menuMode() then
		return
	end
	autoEquipped = false
	timer.delayOneFrame(toggleHelmet)
	return false -- important! Returning non-nil from the callback claims/blocks the event.
end

--[[
when swapping helmet, event order is:
1. unequipped(old helmet)
2. equipped(new helmet)
--]]


local function unequipped(e)
	if not tes3.menuMode() then
		return
	end
	if not (e.mobile == mobilePlayer) then
		return
	end
	---mwse.log("\n%s unequipped()", modPrefix)
	local ob = e.item
	if not (ob.slot == HELMETslot) then
		return
	end
	if not (ob.objectType == ARMO) then
		return
	end
	---tes3.messageBox( string.format("%s unequipped %s %s", modPrefix, ob.id, ob.name) )
	if not isAltDown() then
		return
	end
	autoEquipped = false
	if lastHelmetId == ob.id then
		tes3.messageBox("%s preference cleared", ob.name)
	end
	lastHelmetId = nil
end

local function equipped(e)
	if not tes3.menuMode() then
		return
	end
	if not (e.mobile == mobilePlayer) then
		return
	end
	---mwse.log("\n%s equip()", modPrefix)
	local ob = e.item
	if not (ob.slot == HELMETslot) then
		return
	end
	if not (ob.objectType == ARMO) then
		return
	end
	---tes3.messageBox( string.format("%s equip %s %s", modPrefix, ob.id, ob.name) )
	if not isAltDown() then
		return
	end
	autoEquipped = false
	if lastHelmetId == ob.id then
		return
	end
	lastHelmetId = ob.id
	tes3.messageBox("%s preference stored", ob.name)
end

local function initialized()
	initScenicTravelAvailable()
	event.register('loaded', loaded)
	event.register('save', save)
	event.register('keyDown', keyDown, { filter = tes3.scanCode.z }) -- z key scancode, will check for Alt in keyDown()
	event.register('cellChanged', cellChanged,{ priority = -1 }) -- lower priority as I want to execute getLuma() after other events change cell light level
	event.register('unequipped', unequipped)
	event.register('equipped', equipped)

	local s = string.format("%s initialized Alt+Z hotkey", modPrefix)
	---mwse.log(s)
	tes3.messageBox(s)
end
event.register('initialized', initialized)


--[[
tes3.getEquippedItem
Fetches a currently equipped Equipment Stack from an Actor.
local equippedLightStack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.light })
Return Value
	Equipment Stack. The stack of equipment.
Parameters
	All parameters are delivered via a table.
actor (Actor, Mobile Actor, or Reference) Who to get the equipment of.
objectType (Object Type) Filter the object type to retrieve. Relates to the tes3.objectType.* constants.
slot or type (number) Filter the slot or type of the item to retrieve. This will filter the weapon type, clothing or armor slot.
enchanted (boolean) If provided, the result will be filtered by the enchantment state. A true value limits the result to enchanted items, while a false value will only return unenchanted items.

Examples
Get Player’s Equipped Light
In this example, we print the object ID of the player’s equipped light source.

local equippedLightStack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.light })
if (equippedLightStack) then
	mwse.log("Equipped light: %s", equippedLightStack.object.id)
else
	mwse.log("No light equipped.")
end

Get Player’s Shield
This example shows the player’s shield.
local equippedLightStack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.shield })
if (equippedLightStack) then
	mwse.log("Equipped light: %s", equippedLightStack.object.id)
else
	mwse.log("No light equipped.")
end

boolean unequip {tes3object item, armorSlot armorSlot, clothingSlot clothingSlot, objectType type} Uses table arguments.
Returns:
	true if the un-equip was successful.
Un-equips item(s) that match the argument given. Only one argument can be used in a call.
item:
	One equipped item matching the item given.
	e.g. mobileActor:unequip{ item = tes3.getObject("common_pants_01") }
armorSlot:
	One piece of armor occupying that slot. Slot numbers can be accessed through tes3.weaponSlot.
	e.g. mobileActor:unequip{ armorSlot = tes3.weaponSlot.helmet }
clothingSlot:
	One piece of clothing occupying that slot. Slot numbers can be accessed through tes3.clothingSlot.
	Rings are the only slot that can have multiple items equipped. Call the function multiple times to un-equip them all.
	e.g. mobileActor:unequip{ clothingSlot = tes3.clothingSlot.belt }
type:
	All items of that object type are un-equipped.
	e.g. mobileActor:unequip{ type = tes3.objectType.armor }
	Weapons and ammunition can be un-equipped with this argument.


boolean equip (tes3object item)
Returns:
	true if the equip was successful.
Equips an item from the actor’s inventory. If the item does not exist, or the the actor is currently attacking with another item that occupies the item’s slot, it will fail.
--]]
