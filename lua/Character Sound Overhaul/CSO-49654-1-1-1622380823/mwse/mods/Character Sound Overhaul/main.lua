local config = require("Character Sound Overhaul.config")
local soundData = require("Character Sound Overhaul.data")
local pickRandomFile = require("Character Sound Overhaul.libs.pickRandomFile")
local getFloorTexture = require("Character Sound Overhaul.libs.getFloorTexture")


local damageContext = {}
local impactContext = {}


--[[ PLAY SOUND FILE ]]


local function getSoundPath(soundType, subType, action)
	local dir = ("data files\\sound\\anu\\%s\\%s\\%s\\"):format(soundType, subType, action)
	local file = pickRandomFile(dir)
	if file then
		-- get relative to /sound/
		return dir:sub(18) .. file
	end

	-- if config.debugMode then
	-- 	mwse.log("[CSO] getSoundPath: Invalid directory -> %s", dir)
	-- end
end


local function getPitch(ref)
	if ref.cell.hasWater then
		local cameraNode = tes3.worldController.worldCamera.cameraRoot
		local cameraHeight = cameraNode.worldTransform.translation.z
		local waterLevel = ref.cell.waterLevel or 0
		if cameraHeight < waterLevel then
			return 0.3
		end
	end
	return 1.0
end


local function playRandomSound(ref, soundType, subType, action, volume)
	-- block the sound if empty action
	if action == "" then return "" end

	local soundPath = getSoundPath(soundType, subType, action)

	local success = false
	if soundPath then
		success = tes3.playSound{
			reference = ref,
			soundPath = soundPath,
			volume = volume / 100,
			pitch = getPitch(ref)
		}
	end

	-- if config.debugMode then
	-- 	mwse.log("[CSO] playRandomSound('%s', '%s', '%s', '%s', '%s')", ref, soundType, subType, action, volume)
	-- 	mwse.log("[CSO]     success = '%s'", success)
	-- 	mwse.log("[CSO]   soundPath = '%s'", soundPath)
	-- end

	return success and soundPath or nil
end


--[[ GET TEXTURES ]]--


local function isValidWeather()
	if not tes3.player.cell.isInterior then
		local wc = tes3.worldController.weatherController
		local currWeather = wc.currentWeather and wc.currentWeather.index
		local nextWeather = wc.nextWeather and wc.nextWeather.index

		if (currWeather == tes3.weather.rain
			and nextWeather ~= tes3.weather.thunder)
		then
			return true
		end

		if (currWeather == tes3.weather.thunder
			and nextWeather ~= tes3.weather.rain)
		then
			return true
		end
	end
	return false
end


--[[ GET REFERENCE INFO ]]--


local function getCreatureType(ref)
	if ref.object.biped then
		if ref.object.type == tes3.creatureType.undead then
			return "Creature - Skeletons"
		else
			return "Armor - Heavy"
		end
	end

	local creatureType = soundData.creatureTable[ref.object.mesh:lower()]
	if creatureType == "Metal" then
		return "Creature - Dwemer"
	elseif creatureType == "Ghost" then
		return "Creature - Ghosts"
	end
end


local function getBookType(book)
	if book.type == tes3.bookType.scroll then
		return "Scrolls"
	else
		return "Book"
	end
end


local function getClothingType(clothing)
	if clothing.slot == tes3.clothingSlot.ring
		or clothing.slot == tes3.clothingSlot.amulet
	then
		return "Jewelry"
	else
		return "Clothing"
	end
end


local function getArmorType(armor)
	if armor.weightClass == 0 then
		return "Armor - Light"
	elseif armor.weightClass == 1 then
		return "Armor - Medium"
	elseif armor.weightClass == 2 then
		return "Armor - Heavy"
	end
end


local function getReferenceArmorType(ref)
	if ref.object.objectType == tes3.objectType.creature then
		return getCreatureType(ref)
	end

	local armorSlot = tes3.armorSlot.cuirass
	if (config.altArmor == false) and (ref.object.race.isBeast == false) then
		armorSlot = tes3.armorSlot.boots
	end

	local equippedArmor = tes3.getEquippedItem{actor = ref, objectType = tes3.objectType.armor, slot = armorSlot}
	if equippedArmor then
		return getArmorType(equippedArmor.object)
	end
end


local function getWeaponType(ref)
	local mob = ref.mobile
	local readiedWeapon = mob and mob.readiedWeapon
	if readiedWeapon == nil then
		return "HandToHand"
	else
		return soundData.weaponTypes[readiedWeapon.object.type]
	end
end


--[[ PLAY SOUND EFFECTS ]]--


local function playArmorSound(ref)
	local action = getReferenceArmorType(ref)
	if action == nil then
		return
	end

	if not config.armorSounds then
		return true
	end

	local volume = config.NPCarmorVolume
	if ref == tes3.player then
		volume = config.PCarmorVolume
	end

	return playRandomSound(ref, "Movement", "Armor", action, volume)
end


local function playWeatherSound(ref)
	if not isValidWeather() then
		return
	end

	if not config.weatherSounds then
		return true
	end

	local volume = config.NPCweatherFootstepVolume
	if ref == tes3.player then
		volume = config.PCweatherFootstepVolume
	end

	return playRandomSound(ref, "Movement", "Water", "Puddle", volume)
end


local function playFootstepSound(ref, id)
	local action = soundData.footMapping[id]
	if action == nil then
		return
	end

	if not config.footstepSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return true
	end

	local texture = getFloorTexture(ref, soundData.ignoreList)
	local subType = soundData.landTable[texture]
	if subType == nil then
		return
	end

	local volume
	if ref == tes3.player then
		volume = config.PCfootstepVolume
	else
		volume = config.NPCfootstepVolume
	end

	if config.thumps then
		if ref.object.name == "Scrib" then
			return
		end
	end

	-- mute vanilla footstep sounds?
	-- tes3.game.volumeFootsteps = 0

	-- footsteps also trigger armor and weather sounds
	playArmorSound(ref)
	playWeatherSound(ref)

	return playRandomSound(ref, "Movement", subType, action, volume)
end


local function playWaterSound(ref, id)
	local action = soundData.waterMapping[id]
	if action == nil then
		return
	end

	if not config.footstepSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return true
	end

	local volume = config.NPCfootstepVolume
	if ref == tes3.player then
		volume = config.PCfootstepVolume
	end

	-- swimming also triggers armor sounds
	playArmorSound(ref)

	return playRandomSound(ref, "Movement", "Water", action, volume)
end


local function playItemSound(ref, id)
	local subType = soundData.itemUseMapping[id]
	if subType == nil then
		return
	end

	if not config.itemUseSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return true
	end

	local action = "Use"

	if subType == "Scrolls" then
		action = "Up"
	end

	if subType == "Ingredient" then
		action = (id == "item ingredient up") and "Up" or "Down"
	end

	if subType == "Book" then
		action = (id == "book open") and "Up" or "Down"
	end

	if id == "potion success" then
		action = "Create"
	end

	if id == "repair fail" then
		action = "Fail"
	end

	return playRandomSound(ref, "Items", subType, action, config.itemVolume)
end


local function playWeaponSound(ref, id)
	local action = soundData.weaponMapping[id]
	if action == nil then
		return
	end

	if not config.weaponSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return true
	end

	local mob = ref.mobile
	if mob == nil then return end

	local soundType = "Weapons"
	local subType = getWeaponType(ref)
	local soundVolume
	if ref == tes3.player then
		soundVolume = config.PCweaponVolume
	else
		soundVolume = config.NPCweaponVolume
	end

	return playRandomSound(ref, soundType, subType, action, soundVolume)
end


local function playImpactSound(ref, id)
	local action = soundData.impactMapping[id]
	if action == nil then
		return
	end

	local mob = ref.mobile
	if mob == nil then
		return
	end

	local soundType = "Weapons"
	local subType = "Impacts"
	local soundVolume

	-- Armor Hit Sounds
	if id:find("armor hit$") then
		if not config.armorSounds then
			-- it's a valid sound, but disabled by config
			-- return true, but dont actually play sounds
			return true
		end

		-- Shields play a different sound than normal armor hits
		-- This method *seems* to work for detecting blocking...
		if mob.actionData.currentAnimationGroup == -1
			and mob.readiedShield == nil
			and impactContext[ref] == nil
		then
			action = action:gsub("Armor", "Shield")
		end

		if ref == tes3.player then
			soundVolume = config.PCarmorVolume
		else
			soundVolume = config.NPCarmorVolume
		end

		return playRandomSound(ref, soundType, subType, action, soundVolume)
	end

	local impactCtx = impactContext[ref]
	impactContext[ref] = nil
	local damageCtx = damageContext[ref]
	damageContext[ref] = nil

	mwse.log("HEALTH DAMAGE")

	-- HandToHand Attack Sounds
	if id:find("^hand to hand hit") then
		if not config.weaponSounds then
			-- it's a valid sound, but disabled by config
			-- return true, but dont actually play sounds
			return true
		end

		subType = "HandToHand"
		action = "Impact"

		if ref == tes3.player then
			soundVolume = config.PCweaponVolume
		else
			soundVolume = config.NPCweaponVolume
		end

		return playRandomSound(ref, soundType, subType, action, soundVolume)
	end

	-- Weapon Attack Sounds
	if impactCtx and (id == "health damage") then
		if not config.weaponSounds then
			-- it's a valid sound, but disabled by config
			-- return true, but dont actually play sounds
			return true
		end

		subType = "Impacts"
		action = getCreatureType(ref)

		if not action then
			subType = impactCtx.subType
			action = "Impact"
		end

		if ref == tes3.player then
			soundVolume = config.PCweaponVolume
		else
			soundVolume = config.NPCweaponVolume
		end

		return playRandomSound(ref, soundType, subType, action, soundVolume)
	end

	-- Fall Damage Sounds
	if damageCtx and (id == "health damage") and (damageCtx.source == "fall") then
		if not config.footstepSounds then
			-- it's a valid sound, but disabled by config
			-- return true, but dont actually play sounds
			return true
		end

		subType = "Impacts"
		action = "Misc - Fall"

		if ref == tes3.player then
			soundVolume = config.PCfootstepVolume
		else
			soundVolume = config.NPCfootstepVolume
		end

		return playRandomSound(ref, soundType, subType, action, soundVolume)
	end
end


--[[ PLAY MAIN SOUNDS ]]--
local function onDamage(e)
	local ref = e.reference
	damageContext[ref] = damageContext[ref] or {}
	damageContext[ref].source = e.source
end
event.register("damage", onDamage)

local function onAttack(e)
	local target = e.targetReference
	local damage = e.mobile.actionData.physicalDamage

	if not target then return end
	if damage < 1 then return end

	impactContext[target] = impactContext[target] or {}
	impactContext[target].subType = getWeaponType(e.reference)
end
event.register("attack", onAttack)


local function onPlayItemSound(e)
	if not config.itemSounds then
		return
	end

	local soundType = "Items"
	local subType = (
		soundData.itemNameMapping[e.item.name:lower()]
		or soundData.itemMapping[e.item.mesh:lower()]
		or soundData.itemTypes[e.item.objectType]
	)
	local action = (e.state == 0) and "Up" or "Down"

	if subType == nil then
		return
	elseif subType == "Armor" then
		soundType = "Movement"
		action = getArmorType(e.item)
	elseif subType == "Clothing" then
		soundType = "Items"
		subType = getClothingType(e.item)
	elseif subType == "Book" then
		soundType = "Items"
		subType = getBookType(e.item)
	elseif subType == "Misc" then
		soundType = "Items"
		subType = "Generic"
	elseif subType == "Weapons" then
		soundType = "Weapons"
		subType = soundData.weaponTypes[e.item.type]
		action = (e.state == 0) and "Draw" or "Sheathe"
	elseif subType == "Ammunition" then
		soundType = "Weapons"
		subType = "MarksmanThrown"
		action = (e.state == 0) and "Draw" or "Sheathe"
	end

	local ref = tes3.player
	local soundVolume = config.itemVolume

	if playRandomSound(ref, soundType, subType, action, soundVolume) then
		e.block = true
	end
end
event.register("playItemSound", onPlayItemSound)


local function onAddSound(e)
	if e.isVoiceover then return end

	-- assume sound came from player if ref not provided
	-- TODO: document for which sounds this is necessary
	local ref = e.reference or tes3.player

	-- only interested in sounds coming from actors
	-- or containers for graphic herbalism handling
	local objectType = ref.object.objectType
	if objectType ~= tes3.objectType.npc
		and objectType ~= tes3.objectType.creature
		and objectType ~= tes3.objectType.container
	then
		return
	end

	-- always ensure sound id is lowered
	local id = e.sound.id:lower()

	-- play associated sound for this id
	local soundPath = (
		playFootstepSound(ref, id)
		or playWaterSound(ref, id)
		or playWeaponSound(ref, id)
		or playImpactSound(ref, id)
		or playItemSound(ref, id)
	)

	-- block replaced sound from playing
	if type(soundPath) == "string" then
		e.block = true
	end
end
event.register("addSound", onAddSound)


--[[ Open / Close Sounds ]]--


local function onMenuContents(e)
	if not config.lootSounds then
		return
	end

	local actor = e.menu:getPropertyObject("MenuContents_Actor")
	local object = (
		actor and actor.reference.object
		or e.menu:getPropertyObject("MenuContents_ObjectContainer")
	)
	if object == nil then
		return
	end

	local subType
	if object.objectType == tes3.objectType.container then
		subType = soundData.corpseMapping[object.mesh:lower()]
	end

	if actor and actor.isDead then
        if object.objectType == tes3.objectType.creature then
            subType = getCreatureType(actor.reference)
            if subType ~= "Creature - Dwemer" then
                subType = "Body"
            end
        else
            subType = "Body"
        end
    end

	if subType then
		playRandomSound(tes3.player, "Misc", subType, "Open", config.miscVolume)
		timer.delayOneFrame(function()
			playRandomSound(tes3.player, "Misc", subType, "Close", config.miscVolume)
		end)
	end
end
event.register("menuEnter", onMenuContents, {filter = "MenuContents"})


--[[ Journal Sounds ]]--


local function onJournal(e)
	if not config.journalSounds then
		return
	end

	local action = e.new and "New" or "Update"

	playRandomSound(tes3.player, "Misc", "Journal", action, config.miscVolume)
end
event.register("journal", onJournal)


--[[ Mod Config Menu ]]--


local function registerModConfig()
	require("Character Sound Overhaul.mcm")
end
event.register("modConfigReady", registerModConfig)