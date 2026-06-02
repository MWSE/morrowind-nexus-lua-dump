local config = require("Character Sound Overhaul.config")
local data = require("Character Sound Overhaul.data")
local soundData = require("Character Sound Overhaul.soundData")
local getFloorTexture = require("Character Sound Overhaul.libs.getFloorTexture")

local log = mwse.Logger.new{ modName = "Character Sound Overhaul", moduleName = "main", level = config.logLevel }

local damageContext = {}
local impactContext = {}
local impactMap = {}
local footMap = {}

-- Bounded interning cache for :lower(). Sound ids, mesh paths, and item names
-- are drawn from a fixed pool at runtime, so this saturates quickly and we
-- avoid allocating a fresh string on every hot-path lookup.
local lowerCache = {}
local function lowerCached(s)
	local cached = lowerCache[s]
	if not cached then
		cached = s:lower()
		lowerCache[s] = cached
	end
	return cached
end

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

local function addMagicEffectDefaults(id, magicEffect)
	table.getset(soundData.defaultEffects, id, {
		["area"] = magicEffect.areaSoundEffect,
		["bolt"] = magicEffect.boltSoundEffect,
		["cast"] = magicEffect.castSoundEffect,
		["hit"] = magicEffect.hitSoundEffect,
	})
end

local function init()
	local soundBuilder = require("Character Sound Overhaul.soundBuilder")
	for id, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
		addMagicEffectDefaults(id, magicEffect)
		addMagicEffectSounds(id, soundData.magicEffects)
	end
	soundBuilder.build()
	log:info("init: magic effects indexed, soundBuilder.build() complete")
end
event.register("initialized", init)

local function loaded()
	for id, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
		if not config.expandedMagicSounds then
			magicEffect.areaSoundEffect = soundData.defaultEffects[id]["area"]
			magicEffect.boltSoundEffect = soundData.defaultEffects[id]["bolt"]
			magicEffect.castSoundEffect = soundData.defaultEffects[id]["cast"]
			magicEffect.hitSoundEffect = soundData.defaultEffects[id]["hit"]
		else
			local key = tostring(id - 1)
			local effectSounds = soundData.magicEffects[key]
			if effectSounds then
				if effectSounds["area"] then
					magicEffect.areaSoundEffect = table.choice(effectSounds["area"])
				end
				if effectSounds["bolt"] then
					magicEffect.boltSoundEffect = table.choice(effectSounds["bolt"])
				end
				if effectSounds["cast"] then
					magicEffect.castSoundEffect = table.choice(effectSounds["cast"])
				end
				if effectSounds["hit"] then
					magicEffect.hitSoundEffect = table.choice(effectSounds["hit"])
				end
			end
		end
	end
end
event.register(tes3.event.loaded, loaded)


--[[ PLAY SOUND FILE ]]


local function getSoundPath(soundType, subType, action)
	if not (soundType and subType and action) then return end
	local typeTable = soundData[soundType]
	if not typeTable then return end
	local subTable = typeTable[subType]
	if not subTable then return end
	local dir = subTable[action]
	if not dir then return end
	return table.choice(dir)
end


local ACTOR_PITCH_TYPES = {
	[tes3.objectType.npc] = true,
	[tes3.objectType.creature] = true,
	[tes3.objectType.container] = true,
}

-- Camera Z changes every frame while swimming/flying; refresh once per frame.
local cachedFrameCameraZ
local function clearFrameCameraZ()
	cachedFrameCameraZ = nil
end
event.register(tes3.event.simulate, clearFrameCameraZ)

local function getPitch(ref)
	local cell
	if ref and ACTOR_PITCH_TYPES[ref.object.objectType] then
		cell = ref.cell
	else
		cell = tes3.player.cell
	end
	if not cell or not cell.hasWater then return 1.0 end

	if not cachedFrameCameraZ then
		cachedFrameCameraZ = tes3.worldController.worldCamera.cameraRoot.worldTransform.translation.z
	end
	local waterLevel = cell.waterLevel or 0
	if cachedFrameCameraZ < waterLevel then
		return 0.3
	end
	return 1.0
end


local function playRandomSound(ref, soundType, subType, action, volume)
	-- block the sound if empty action
	if action == "" then return false end

	local soundPath = getSoundPath(soundType, subType, action)

	if soundPath and impactMap[ref] then
		if action == "im" then
			impactMap[ref].soundTypeWeapon = soundType
			impactMap[ref].subTypeWeapon = subType
			impactMap[ref].actionWeapon = action
			impactMap[ref].volumeWeapon = volume
		elseif subType == "imp" then
			impactMap[ref].soundTypeArmor = soundType
			impactMap[ref].subTypeArmor = subType
			impactMap[ref].actionArmor = action
			impactMap[ref].volumeArmor = volume
		end
	end

	if not soundPath then return nil end

	local success = tes3.playSound{
		reference = ref,
		sound = soundPath,
		volume = volume / 100,
		pitch = getPitch(ref),
	}
	return success and soundPath or nil
end


--[[ GET TEXTURES ]]--


local weatherValidCache
local function recalcWeatherCache()
	local cell = tes3.player and tes3.player.cell
	if not cell or cell.isInterior then
		weatherValidCache = false
		return
	end
	local wc = tes3.worldController.weatherController
	local currWeather = wc.currentWeather and wc.currentWeather.index
	local nextWeather = wc.nextWeather and wc.nextWeather.index

	weatherValidCache = (currWeather == tes3.weather.rain and nextWeather ~= tes3.weather.thunder)
		or (currWeather == tes3.weather.thunder and nextWeather ~= tes3.weather.rain)
end

local function isValidWeather()
	if weatherValidCache == nil then recalcWeatherCache() end
	return weatherValidCache
end

event.register(tes3.event.weatherChangedImmediate, recalcWeatherCache)
event.register(tes3.event.weatherTransitionStarted, recalcWeatherCache)
event.register(tes3.event.weatherTransitionFinished, recalcWeatherCache)
event.register(tes3.event.cellChanged, recalcWeatherCache)


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


local function getBookType(book)
	if book.type == tes3.bookType.scroll then
		return "scrolls"
	else
		return "book"
	end
end


local function getClothingType(clothing)
	if clothing.slot == tes3.clothingSlot.ring
		or clothing.slot == tes3.clothingSlot.amulet
	then
		return "jewelry"
	else
		return "clothing"
	end
end


local function getArmorType(armor)
	if armor.weightClass == 0 then
		return "al"
	elseif armor.weightClass == 1 then
		return "am"
	elseif armor.weightClass == 2 then
		return "ah"
	end
end


local armorTypeCache = setmetatable({}, { __mode = "k" })

local function getReferenceArmorType(ref)
	local cached = armorTypeCache[ref]
	if cached ~= nil then
		if cached == false then return nil end
		return cached
	end

	local result
	if ref.object.objectType == tes3.objectType.creature then
		result = getCreatureType(ref)
	else
		local armorSlot = tes3.armorSlot.cuirass
		local race = ref.object.race
		if not config.altArmor and race and not race.isBeast then
			armorSlot = tes3.armorSlot.boots
		end
		local equipped = tes3.getEquippedItem{actor = ref, objectType = tes3.objectType.armor, slot = armorSlot}
		if equipped then
			result = getArmorType(equipped.object)
		end
	end

	armorTypeCache[ref] = result or false
	return result
end

local function invalidateArmorCache(e)
	if e.reference then armorTypeCache[e.reference] = nil end
end
event.register(tes3.event.equipped, invalidateArmorCache)
event.register(tes3.event.unequipped, invalidateArmorCache)


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


local function playArmorSound(ref)
	local action = getReferenceArmorType(ref)
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
	if not config.spellNoise then return end
	local ref = e.target
	if ref ~= tes3.player then return end
	if not e.effectId then return end

	local effectSounds = soundData.magicEffects[e.effectId]
	if not effectSounds then return end

	local noise = effectSounds["noise"]
	if not noise then
		log:debug("spellNoise: no noise sounds for effectId %s", e.effectId)
		return
	end

	local playing = tes3.getSoundPlaying({ sound = noise, reference = ref })
	if e.state and (e.state < 6) then
		if not playing then
			tes3.playSound{
				reference = ref,
				sound = table.choice(noise),
				volume = (config.PCmagicVolume / 100) * (e.effectInstance.effectiveMagnitude / 100),
				loop = true,
			}
		end
	elseif playing then
		tes3.removeSound({ sound = noise, reference = ref })
	end
end
event.register(tes3.event.spellTick, spellNoise)

local function onMagicCasted(e)
	if e.source == tes3.objectType.alchemy or e.source == tes3.objectType.enchantment then
		if config.expandedMagicSounds == true then
			local effect = e.sourceInstance:getLeastProficientEffect(e.caster.mobile)
			local id = tostring(effect.id)
			local spellEffect
			if soundData.magicEffects[id] then
				spellEffect = id
			end

			if spellEffect then
				local tempData = e.caster.tempData
				local slot = tempData.cso_lastMagic
				if slot then
					slot.effect = spellEffect
					slot.timestamp = tes3.getSimulationTimestamp()
				else
					tempData.cso_lastMagic = {
						effect = spellEffect,
						timestamp = tes3.getSimulationTimestamp(),
					}
				end
			end
		end
	end
end
event.register(tes3.event.magicCasted, onMagicCasted)

local function spellEffects(e)
	local effect = e.spell:getLeastProficientEffect(e.caster.mobile)
	local id = tostring(effect.id)
	if config.expandedMagicSounds == true then
		local spellEffect
		if soundData.magicEffects[id] and soundData.magicEffects[id]["fail"] then
			spellEffect = id
		end

		if spellEffect then
			local tempData = e.caster.tempData
			local slot = tempData.cso_lastCast
			if slot then
				slot.effect = spellEffect
				slot.timestamp = tes3.getSimulationTimestamp()
			else
				tempData.cso_lastCast = {
					effect = spellEffect,
					timestamp = tes3.getSimulationTimestamp(),
				}
			end
		end
	end
end
event.register(tes3.event.spellMagickaUse, spellEffects)

local function playMagicEffectSound(ref, id)
	local underscore = id:find("_", 1, true)
	if not underscore then return end
	local subType = id:sub(1, underscore - 1)
	local subTypeSounds = soundData.magicEffects[subType]
	if not subTypeSounds then return end

	local action = id:match("_(.-)_", underscore)
	if not action or not subTypeSounds[action] then
		return
	end

	if action == "fail" then
		return false
	end

	local isAmmo = ref.object.objectType == tes3.objectType.ammunition
	local volume
	if ref == tes3.player then
		volume = config.PCmagicVolume
	elseif isAmmo then
		volume = config.spellProjectileVolume
	else
		volume = config.NPCmagicVolume
	end

	-- Player-scoped bookkeeping for projectile refs (ammunition); per-ref otherwise.
	local dedupeHolder
	local dedupeKey
	if isAmmo then
		dedupeHolder = tes3.player.tempData
		dedupeKey = "cso_lastBoltSound"
	elseif ref.supportsLuaData then
		dedupeHolder = ref.tempData
		dedupeKey = "cso_lastSound"
	else
		return
	end

	local slot = dedupeHolder[dedupeKey]
	local timestamp = tes3.getSimulationTimestamp()
	if slot then
		if id == slot.effect and math.isclose(timestamp, slot.timestamp, 0.01) then
			return false
		end
		slot.effect = id
		slot.timestamp = timestamp
	else
		dedupeHolder[dedupeKey] = { effect = id, timestamp = timestamp }
	end
	return playRandomSound(ref, "magicEffects", subType, action, volume)
end

local function playMagicSound(ref, _, mapping)
	if not config.magicSounds then
		return false
	end

	local subType = mapping.subType
	local action = mapping.action
	if not action then return end

	local volume
	if ref == tes3.player then
		volume = config.PCmagicVolume
	elseif ref.object.objectType == tes3.objectType.ammunition then
		volume = config.spellProjectileVolume
	else
		volume = config.NPCmagicVolume
	end

	if config.expandedMagicSounds and ref.supportsLuaData then
		local cacheKey = (action == "fail") and "cso_lastCast" or "cso_lastMagic"
		local cached = ref.tempData[cacheKey]
		if cached then
			if math.isclose(tes3.getSimulationTimestamp(), cached.timestamp, 0.01) then
				return playRandomSound(ref, "magicEffects", cached.effect, action, volume)
			else
				ref.tempData[cacheKey] = nil
			end
		end
	end

	return playRandomSound(ref, "magic", subType, action, volume)
end


local function playFootstepSound(ref, _, action)
	if not config.footstepSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return false
	end

	local texture = getFloorTexture(ref, data.ignoreList)
	local rawSubType = data.landTable[texture]
	local subType

	if rawSubType then
		subType = lowerCached(rawSubType)
		local entry = footMap[ref]
		if entry then
			entry.subType = subType
		else
			footMap[ref] = { subType = subType }
		end
	else
		local entry = footMap[ref]
		if not entry then return end
		subType = entry.subType
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
	playArmorSound(ref)
	playWeatherSound(ref)

	return playRandomSound(ref, "movement", subType, action, volume)
end


local function playWaterSound(ref, _, action)
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
	playArmorSound(ref)

	return playRandomSound(ref, "movement", "water", action, volume)
end


local function playItemSound(ref, id, subType)
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


local function playWeaponSound(ref, _, action)
	if not config.weaponSounds then
		-- it's a valid sound, but disabled by config
		-- return true, but dont actually play sounds
		return false
	end
	
	local subType = getWeaponType(ref)
	
	local soundVolume
	if ref == tes3.player then
		soundVolume = config.PCweaponVolume
	else
		soundVolume = config.NPCweaponVolume
	end

	return playRandomSound(ref, "weapons", subType, action, soundVolume)
end


local function playImpactSound(ref, id, action)
	local mob = ref.mobile
	if mob == nil then
		return
	end
	
	local mapEntry = impactMap[ref]
	if mapEntry then
		mapEntry.sound = id
	else
		impactMap[ref] = { sound = id }
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
	if not config.deathRattle then return end

	local ref = e.reference
	if not e.killingBlow then return end
	if not ref.mobile or ref.mobile.actorType ~= tes3.actorType.npc then return end

	tes3.removeSound({ sound = nil, reference = ref })

	local impactData = impactMap[ref]
	if impactData then
		local played = false
		if config.armorSounds and impactData.actionArmor then
			playRandomSound(ref, impactData.soundTypeArmor, impactData.subTypeArmor, impactData.actionArmor, impactData.volumeArmor)
			played = true
		end
		if config.weaponSounds and impactData.actionWeapon then
			playRandomSound(ref, impactData.soundTypeWeapon, impactData.subTypeWeapon, impactData.actionWeapon, impactData.volumeWeapon)
			played = true
		end
		if not played and impactData.sound then
			tes3.playSound({ reference = ref, sound = impactData.sound })
		end
		impactMap[ref] = nil
	end

	tes3.playVoiceover{
		actor = ref,
		voiceover = 4,
		pitch = getPitch(ref),
	}
end
event.register(tes3.event.damaged, onDamaged)

local function onDamage(e)
	local ref = e.reference
	local ctx = damageContext[ref]
	if ctx then
		ctx.source = e.source
	else
		damageContext[ref] = { source = e.source }
	end
end
event.register("damage", onDamage)

local function onAttack(e)
	local target = e.targetReference
	local damage = e.mobile.actionData.physicalDamage

	if not target then return end
	if damage < 1 then return end

	local subType = getWeaponType(e.reference)
	local ctx = impactContext[target]
	if ctx then
		ctx.subType = subType
	else
		impactContext[target] = { subType = subType }
	end
end
event.register("attack", onAttack)


local function onPlayItemSound(e)
	if not config.itemSounds then
		return
	end
	
	if e.reference and e.reference ~= tes3.player then
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
		action = getArmorType(e.item)
	elseif subType == "clothing" then
		soundType = "items"
		subType = getClothingType(e.item)
	elseif subType == "book" then
		soundType = "items"
		subType = getBookType(e.item)
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
event.register("playItemSound", onPlayItemSound)


-- Dispatch: each sound id maps to {handler, preLookedUpMappingValue}. Handlers
-- themselves early-return if the config flag is off. Order of seeding below
-- matches the original priority (foot > water > weapon > impact > item > magic)
-- in case an id appears in more than one mapping — first write wins.
local handlerById = {}
local function seedDispatch(mapping, handler)
	for id, value in pairs(mapping) do
		if handlerById[id] == nil then handlerById[id] = {handler, value} end
	end
end

seedDispatch(data.footMapping, playFootstepSound)
seedDispatch(data.waterMapping, playWaterSound)
seedDispatch(data.weaponMapping, playWeaponSound)
seedDispatch(data.impactMapping, playImpactSound)
seedDispatch(data.itemUseMapping, playItemSound)
seedDispatch(data.magicMapping, playMagicSound)

local INTERESTING_OBJECT_TYPES = {
	[tes3.objectType.npc] = true,
	[tes3.objectType.creature] = true,
	[tes3.objectType.container] = true,  -- graphic herbalism
	[tes3.objectType.ammunition] = true,
}

local function onAddSound(e)
	if e.isVoiceover then return end

	local ref = e.reference or tes3.player
	if not INTERESTING_OBJECT_TYPES[ref.object.objectType] then return end

	local id = lowerCached(e.sound.id)
	local entry = handlerById[id]
	local soundPath
	if entry then
		soundPath = entry[1](ref, id, entry[2])
	else
		soundPath = playMagicEffectSound(ref, id)
	end

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


--[[ Ref-Keyed State Cleanup ]]--


local function onReferenceDeactivated(e)
	local ref = e.reference
	damageContext[ref] = nil
	impactContext[ref] = nil
	impactMap[ref] = nil
	footMap[ref] = nil
end
event.register(tes3.event.referenceDeactivated, onReferenceDeactivated)


--[[ Mod Config Menu ]]--


local function registerModConfig()
	require("Character Sound Overhaul.mcm")
end
event.register("modConfigReady", registerModConfig)