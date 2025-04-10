local config = require("Character Sound Overhaul.config")
local data = require("Character Sound Overhaul.data")
local soundData = require("Character Sound Overhaul.soundData")
local getFloorTexture = require("Character Sound Overhaul.libs.getFloorTexture")


local damageContext = {}
local impactContext = {}
local impactMap = {}

local function addMagicEffectSounds(id, soundsTable)
	local magicEffectSounds = table.getset(soundData.magicEffects, id, {
        ["area"] = {},
        ["bolt"] = {},
        ["cast"] = {},
        ["hit"] = {},
        ["fail"] = {},
        ["noise"] = {},
		})
	for name, sounds in pairs(magicEffectSounds) do
        local sound = soundsTable[name]
        if not table.contains(sounds, sound) then
            table.insert(sounds, sound)
        end
    end
end

local function addMagicEffectDefaults(id, magicEffect, soundsTable)
	local magicEffectDefaults = table.getset(soundData.defaultEffects, id, {
        ["area"] = magicEffect.areaSoundEffect,
        ["bolt"] = magicEffect.boltSoundEffect,
        ["cast"] = magicEffect.castSoundEffect,
        ["hit"] = magicEffect.hitSoundEffect,
		})
end

local function init()
	local soundBuilder = require("Character Sound Overhaul.soundBuilder")
	for id, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
		addMagicEffectDefaults(id, magicEffect, soundData.defaultEffects)
		addMagicEffectSounds(id, soundData.magicEffects)
	end
	soundBuilder.build()
end
event.register("initialized", init)

local function loaded(e)
	for id, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
		if not config.expandedMagicSounds then
			magicEffect.areaSoundEffect = soundData.defaultEffects[id]["area"]
			magicEffect.boltSoundEffect = soundData.defaultEffects[id]["bolt"]
			magicEffect.castSoundEffect = soundData.defaultEffects[id]["cast"]
			magicEffect.hitSoundEffect = soundData.defaultEffects[id]["hit"]
		else
			id = (tostring(id - 1))
			if soundData.magicEffects[id] then
				if soundData.magicEffects[id]["area"] then
					magicEffect.areaSoundEffect = table.choice(soundData.magicEffects[id]["area"])
				end
				
				if soundData.magicEffects[id]["bolt"] then
					magicEffect.boltSoundEffect = table.choice(soundData.magicEffects[id]["bolt"])
				end
				
				if soundData.magicEffects[id]["cast"] then
					magicEffect.castSoundEffect = table.choice(soundData.magicEffects[id]["cast"])
				end
				
				if soundData.magicEffects[id]["hit"] then
					magicEffect.hitSoundEffect = table.choice(soundData.magicEffects[id]["hit"])
				end
			end
		end
	end
end
event.register(tes3.event.loaded, loaded)


--[[ PLAY SOUND FILE ]]


local function getSoundPath(soundType, subType, action)
	local dir
	if soundType and subType and action then
		if soundType == "movement" then
			dir = soundData.movement[subType][action]
		elseif soundType == "items" then
			dir = soundData.items[subType][action]
		elseif soundType ==  "weapons" then
			dir = soundData.weapons[subType][action]
		elseif soundType == "magic" then
			dir = soundData.magic[subType][action]
		elseif soundType == "misc" then
			dir = soundData.misc[subType][action]
		elseif soundType == "magicEffects" then
			dir = soundData.magicEffects[subType][action]
		end
	end
	
	if not dir then
		return
	end
	
	local file = table.choice(dir)
	if file then
		-- get relative to /sound/
		return file
	end

	-- if config.debugMode then
	-- 	mwse.log("[CSO] getSoundPath: Invalid directory -> %s", dir)
	-- end
end


local function getPitch(ref)
	if (ref == nil) or (ref ~= (tes3.objectType.npc or tes3.objectType.creature or tes3.objectType.container)) then
		if tes3.player.cell.hasWater then
			local cameraNode = tes3.worldController.worldCamera.cameraRoot
			local cameraHeight = cameraNode.worldTransform.translation.z
			local waterLevel = tes3.player.cell.waterLevel or 0
			if cameraHeight < waterLevel then
				return 0.3
			end
		end
		return 1.0
	elseif ref.cell.hasWater then
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

	if impactMap[ref] then
		if soundPath and action == "im" then
			impactMap[ref].soundTypeWeapon = soundType
			impactMap[ref].subTypeWeapon = subType
			impactMap[ref].actionWeapon = action
			impactMap[ref].volumeWeapon = volume
		elseif soundPath and subType == "imp" then
			impactMap[ref].soundTypeArmor = soundType
			impactMap[ref].subTypeArmor = subType
			impactMap[ref].actionArmor = action
			impactMap[ref].volumeArmor = volume
		end
	end

	local success = false
	if soundPath then
		success = tes3.playSound{
			reference = ref,
			sound = soundPath,
			volume = volume / 100,
			pitch = getPitch(ref),
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
			return "cs"
		else
			return "ah"
		end
	end

	local creatureType = data.creatureTable[ref.object.mesh:lower()]
	if creatureType == "metal" then
		return "cd"
	elseif creatureType == "ghost" then
		return "cg"
	end
end


local function getbookType(book)
	if book.type == tes3.bookType.scroll then
		return "scrolls"
	else
		return "book"
	end
end


local function getclothingType(clothing)
	if clothing.slot == tes3.clothingSlot.ring
		or clothing.slot == tes3.clothingSlot.amulet
	then
		return "jewelry"
	else
		return "clothing"
	end
end


local function getarmorType(armor)
	if armor.weightClass == 0 then
		return "al"
	elseif armor.weightClass == 1 then
		return "am"
	elseif armor.weightClass == 2 then
		return "ah"
	end
end


local function getReferencearmorType(ref)
	if ref.object.objectType == tes3.objectType.creature then
		return getCreatureType(ref)
	end

	local armorSlot = tes3.armorSlot.cuirass
	if (config.altArmor == false) and (ref.object.race.isBeast == false) then
		armorSlot = tes3.armorSlot.boots
	end

	local equippedarmor = tes3.getEquippedItem{actor = ref, objectType = tes3.objectType.armor, slot = armorSlot}
	if equippedarmor then
		return getarmorType(equippedarmor.object)
	end
end


local function getWeaponType(ref)
	local mob = ref.mobile
	local readiedWeapon = mob and mob.readiedWeapon
	if readiedWeapon == nil then
		return "h2h"
	else
		return data.weaponTypes[readiedWeapon.object.type]
	end
end


--[[ PLAY SOUND EFFECTS ]]--


local function playarmorSound(ref)
	local action = getReferencearmorType(ref)
	if action == nil then
		return
	end

	if not config.armorSounds then
		return false
	end

	local volume = config.NPCarmorVolume
	if ref == tes3.player then
		volume = config.PCarmorVolume
	end

	return playRandomSound(ref, "movement", "armor", action, volume)
end


local function playWeatherSound(ref)
	if not isValidWeather() then
		return
	end

	if not config.weatherSounds then
		return false
	end

	local volume = config.NPCweatherFootstepVolume
	if ref == tes3.player then
		volume = config.PCweatherFootstepVolume
	end

	return playRandomSound(ref, "movement", "water", "fp", volume)
end

local function spellNoise(e)
	if not config.spellNoise then
		return false
	else
		local ref = e.target
		if ref == tes3.player then
			if e.effectId and soundData.magicEffects[e.effectId] then
				if e.state and (e.state < 6) then
					local noise = soundData.magicEffects[e.effectId]["noise"]
					if not tes3.getSoundPlaying({ sound = noise, reference = ref }) then
						tes3.playSound{
						reference = ref,
						sound = table.choice(noise),
						volume = ({config.PCmagicVolume / 100} * {e.effectInstance.effectiveMagnitude / 100}),
						loop = true,
						}
					end
				elseif tes3.getSoundPlaying({ sound = noise, reference = ref }) then
					tes3.removeSound({ sound = noise, reference = ref })
				end
			end
		end
	end
end
event.register(tes3.event.spellTick, spellNoise)

local function onMagicCasted(e)
	if e.source == tes3.objectType.alchemy or e.source == tes3.objectType.enchantment then
		if not config.expandedMagicSounds then
			return false
		else
			local effect = e.sourceInstance:getLeastProficientEffect(e.caster.mobile)
			local id = tostring(effect.id)
			local magicEffect
			if soundData.magicEffects[id] then
				spellEffect = id
			end
			
			if spellEffect then
				e.caster.tempData.cso_lastMagic = {
				effect = spellEffect,
				timestamp = tes3.getSimulationTimestamp(),
				}
			end
		end
	end
end
event.register(tes3.event.magicCasted, onMagicCasted)

local function spellEffects(e)
	local effect = e.spell:getLeastProficientEffect(e.caster.mobile)
	local id = tostring(effect.id)
	if not config.expandedMagicSounds then
		return false
	else
		local spellEffect
		if soundData.magicEffects[id] then
			if soundData.magicEffects[id]["fail"] then
				spellEffect = id
			end
		end
		
		if spellEffect then
			e.caster.tempData.cso_lastCast = {
				effect = spellEffect,
				timestamp = tes3.getSimulationTimestamp(),
				}
		end
	end
end
event.register(tes3.event.spellMagickaUse, spellEffects)

local function shortenString(input, delimiter)
	local pos = string.find(input, delimiter)
	if pos then
		return string.sub(input, 1, pos - 1)
	else
		return nil
	end
end

local function shortenBetween(input, startChar, endChar)
	local pos = input:match(startChar .. "(.-)" .. endChar)
	if pos then
		return pos
	else
		return nil
	end
end

local function playMagicEffectSound(ref, id)
	local subType = shortenString(id, "_")
	if not soundData.magicEffects[subType] then
		return
	end
	
	local action = shortenBetween(id, "_", "_")
	if not soundData.magicEffects[subType][action] == id then
		return
	end
	
	if action == "fail" then
		return false
	end
	
	local volume
	if ref == tes3.player then
		volume = config.PCmagicVolume
	elseif ref.object.objectType == tes3.objectType.ammunition  then
		volume = config.spellProjectileVolume
	else
		volume = config.NPCmagicVolume
	end
	
	if ref and ref.supportsLuaData then
		local tempData = ref.tempData.cso_lastSound
		local timestamp = tes3.getSimulationTimestamp()
		if tempData then
			if id == tempData.effect then
				if math.isclose(timestamp, tempData.timestamp, 0.01) then
					return false
				else
					ref.tempData.cso_lastSound = nil
				end
			end
		end
	
		ref.tempData.cso_lastSound = {
			effect = id,
			timestamp = tes3.getSimulationTimestamp(),
			}
		return playRandomSound(ref, "magicEffects", subType, action, volume)
	elseif ref.object.objectType == tes3.objectType.ammunition  then
		local tempData = tes3.player.tempData.cso_lastBoltSound
		local timestamp = tes3.getSimulationTimestamp()
		if tempData then
			if id == tempData.effect then
				if math.isclose(timestamp, tempData.timestamp, 0.01) then
					return false
				else
					tes3.player.tempData.cso_lastBoltSound = nil
				end
			end
		end
		
		tes3.player.tempData.cso_lastBoltSound = {
			effect = id,
			timestamp = tes3.getSimulationTimestamp(),
			}
		return playRandomSound(ref, "magicEffects", subType, action, volume)
	
	end
end

local function playMagicSound(ref, id)
	if not config.magicSounds then
		return false
	end
	
	if data.magicMapping[id] == nil then
		return
	end
	
	local subType = data.magicMapping[id]["subType"]
	local action = data.magicMapping[id]["action"]
	if action == nil then
		return
	end
	
	local volume
	if ref == tes3.player then
		volume = config.PCmagicVolume
	elseif ref.object.objectType == tes3.objectType.ammunition  then
		volume = config.spellProjectileVolume
	else
		volume = config.NPCmagicVolume
	end
	
	if (config.expandedMagicSounds == true) then
		if ref and ref.supportsLuaData then
			if action == "fail" then
				local failData = ref.tempData.cso_lastCast
				local timestamp = tes3.getSimulationTimestamp()
				if failData then
					if math.isclose(timestamp, failData.timestamp, 0.01) then
						subType = failData.effect
						return playRandomSound(ref, "magicEffects", subType, action, volume)
					else
						ref.tempData.cso_lastCast = nil
					end
				else
					return playRandomSound(ref, "magic", subType, action, volume)
				end
			else
				local magicData = ref.tempData.cso_lastMagic
				local timestamp = tes3.getSimulationTimestamp()
				if magicData then
					if math.isclose(timestamp, magicData.timestamp, 0.01) then
						subType = magicData.effect
						return playRandomSound(ref, "magicEffects", subType, action, volume)
					else
						ref.tempData.cso_lastMagic = nil
					end
				else
					return playRandomSound(ref, "magic", subType, action, volume)
				end
			end
		end
	else
		return playRandomSound(ref, "magic", subType, action, volume)
	end
end 


local function playFootstepSound(ref, id)
	local action = data.footMapping[id]
	if action == nil then
		return
	end

	if not config.footstepSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return false
	end

	local texture = getFloorTexture(ref, data.ignoreList)
	local subType = data.landTable[texture]
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
		if ref.object.name == "scrib" then
			return
		end
	end

	-- mute vanilla footstep sounds?
	-- tes3.game.volumeFootsteps = 0

	-- footsteps also trigger armor and weather sounds
	playarmorSound(ref)
	playWeatherSound(ref)

	return playRandomSound(ref, "movement", subType, action, volume)
end


local function playWaterSound(ref, id)
	local action = data.waterMapping[id]
	if action == nil then
		return
	end

	if not config.footstepSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return false
	end

	local volume = config.NPCfootstepVolume
	if ref == tes3.player then
		volume = config.PCfootstepVolume
	end

	-- swimming also triggers armor sounds
	playarmorSound(ref)

	return playRandomSound(ref, "movement", "water", action, volume)
end


local function playitemsound(ref, id)
	local subType = data.itemUseMapping[id]
	if subType == nil then
		return
	end

	if not config.itemUseSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return false
	end

	local action = "us"

	if subType == "scrolls" then
		action = "up"
	end

	if subType == "ingredient" then
		action = (id == "item ingredient up") and "up" or "dw"
	end

	if subType == "book" then
		action = (id == "book open") and "up" or "dw"
	end

	if id == "potion success" then
		action = "cr"
	end

	if id == "repair fail" then
		action = "fa"
	end

	return playRandomSound(ref, "items", subType, action, config.itemVolume)
end


local function playweaponsound(ref, id)
	local action = data.weaponMapping[id]
	if action == nil then
		return
	end

	if not config.weaponSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return false
	end
	
	local mob = ref.mobile
	if mob == nil then return end
	
	local subType = getWeaponType(ref)
	
	if action == "dr" or action == "sh" then
		if not ref.isReadyingWeapon then
			return false
		end
	end
	
	local soundVolume
	if ref == tes3.player then
		soundVolume = config.PCweaponVolume
	else
		soundVolume = config.NPCweaponVolume
	end

	return playRandomSound(ref, "weapons", subType, action, soundVolume)
end


local function playImpactSound(ref, id)
	local action = data.impactMapping[id]
	if action == nil then
		return
	end

	local mob = ref.mobile
	if mob == nil then
		return
	end
	
	impactMap[ref] = impactMap[ref] or {}
	if impactMap[ref] then
		impactMap[ref].sound = id
	end

	local soundType = "weapons"
	local subType = "imp"
	local soundVolume

	-- armor Hit Sounds
	if id:find("armor hit$") then
		if not config.armorSounds then
			-- it's a valid sound, but disabled by config
			-- return true, but dont actually play sounds
			return false
		end

		-- Shields play a different sound than normal armor hits
		-- This method *seems* to work for detecting blocking...
		if mob.actionData.currentAnimationGroup == -1
			and mob.readiedShield == nil
			and impactContext[ref] == nil
		then
			action = action:gsub("armor", "shield")
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

	-- HandToHand Attack Sounds
	if id:find("^hand to hand hit") then
		if not config.weaponSounds then
			-- it's a valid sound, but disabled by config
			-- return true, but dont actually play sounds
			return false
		end

		subType = "h2h"
		action = "im"

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
			return false
		end

		subType = "imp"
		action = getCreatureType(ref)

		if not action then
			subType = impactCtx.subType
			action = "im"
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
			return false
		end

		subType = "imp"
		action = "mf"

		if ref == tes3.player then
			soundVolume = config.PCfootstepVolume
		else
			soundVolume = config.NPCfootstepVolume
		end

		return playRandomSound(ref, soundType, subType, action, soundVolume)
	end
end


--[[ PLAY MAIN SOUNDS ]]--

local function onDamaged(e)
	if config.deathRattle then
		local ref = e.reference
		
		if (not e.killingBlow) then
			return
		end

		if not ref.mobile or not (ref.mobile.actorType == tes3.actorType.npc) then
			return
		end
		
		tes3.removeSound({ sound = nil, reference = ref })
		
		if impactMap[ref] then
			local soundType
			local subType
			local action
			local volume
			
			if config.armorSounds then
				soundType = impactMap[ref].soundTypeArmor
				subType = impactMap[ref].subTypeArmor
				action = impactMap[ref].actionArmor
				volume = impactMap[ref].volumeArmor
				playRandomSound(ref, soundType, subType, action, volume)
			end
			
			if config.weaponSounds then
				soundType = impactMap[ref].soundTypeWeapon
				subType = impactMap[ref].subTypeWeapon
				action = impactMap[ref].actionWeapon
				volume = impactMap[ref].volumeWeapon
				playRandomSound(ref, soundType, subType, action, volume)
			else
				tes3.playSound({ reference = ref, sound = impactMap[ref].sound })
			end
			impactMap[ref] = nil
		end
		
		tes3.playVoiceover{
			actor = ref,
			voiceover  = 4,
			pitch = getPitch(ref),
		}
	end
end
event.register(tes3.event.damaged, onDamaged)

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


local function onPlayitemsound(e)
	if not config.itemSounds then
		return
	end

	local soundType = "items"
	local subType = (
		data.itemNameMapping[e.item.name:lower()]
		or data.itemMapping[e.item.mesh:lower()]
		or data.itemTypes[e.item.objectType]
	)
	local action = (e.state == 0) and "up" or "dw"
	if subType == nil then
		return
	elseif subType == "armor" then
		soundType = "movement"
		action = getarmorType(e.item)
	elseif subType == "clothing" then
		soundType = "items"
		subType = getclothingType(e.item)
	elseif subType == "book" then
		soundType = "items"
		subType = getbookType(e.item)
	elseif subType == "misc" then
		soundType = "items"
		subType = "generic"
	elseif subType == "weapons" then
		soundType = "weapons"
		subType = data.weaponTypes[e.item.type]
		action = (e.state == 0) and "dr" or "sh"
	elseif subType == "ammunition" then
		soundType = "weapons"
		subType = "mrkt"
		action = (e.state == 0) and "dr" or "sh"
	end

	local ref = tes3.player
	local soundVolume = config.itemVolume

	if playRandomSound(ref, soundType, subType, action, soundVolume) then
		e.block = true
	end
end
event.register("playItemSound", onPlayitemsound)


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
		and objectType ~= tes3.objectType.ammunition
	then
		return
	end

	-- always ensure sound id is lowered
	local id = e.sound.id:lower()
	-- play associated sound for this id
	local soundPath = (
		playFootstepSound(ref, id)
		or playWaterSound(ref, id)
		or playweaponsound(ref, id)
		or playImpactSound(ref, id)
		or playitemsound(ref, id)
		or playMagicSound(ref, id)
		or playMagicEffectSound(ref, id)
	)

	-- block replaced sound from playing
	if soundPath then
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
		subType = data.corpseMapping[object.mesh:lower()]
	end

	if actor and actor.isDead then
        if object.objectType == tes3.objectType.creature then
            subType = getCreatureType(actor.reference)
            if subType ~= "cd" then
                subType = "body"
            end
        else
            subType = "body"
        end
    end

	if subType then
		playRandomSound(tes3.player, "misc", subType, "o", config.miscVolume)
		timer.delayOneFrame(function()
			playRandomSound(tes3.player, "misc", subType, "c", config.miscVolume)
		end)
	end
end
event.register("menuEnter", onMenuContents, {filter = "MenuContents"})


--[[ Journal Sounds ]]--


local function onJournal(e)
	if not config.journalSounds then
		return
	end

	local action = e.new and "nu" or "up"

	playRandomSound(tes3.player, "misc", "journal", action, config.miscVolume)
end
event.register("journal", onJournal)


--[[ Mod Config Menu ]]--


local function registerModConfig()
	require("Character Sound Overhaul.mcm")
end
event.register("modConfigReady", registerModConfig)