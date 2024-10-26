local footsteps = {
  ArmorHeavy = {
    unknown = {
      "fst_armor_heavy_01.mp3",
      "fst_armor_heavy_02.mp3",
      "fst_armor_heavy_03.mp3",
      "fst_armor_heavy_04.mp3",
      "fst_armor_heavy_05.mp3",
      "fst_armor_heavy_06.mp3",
      "fst_armor_heavy_07.mp3",
      "fst_armor_heavy_08.mp3",
    },
  },
  ArmorLight = {
    unknown = {
      "fst_armor_light_01.mp3",
      "fst_armor_light_02.mp3",
      "fst_armor_light_03.mp3",
      "fst_armor_light_04.mp3",
      "fst_armor_light_05.mp3",
      "fst_armor_light_06.mp3",
      "fst_armor_light_07.mp3",
      "fst_armor_light_08.mp3",
    },
  },
  ArmorMedium = {
    unknown = {
      "fst_armor_medium_01.mp3",
      "fst_armor_medium_02.mp3",
      "fst_armor_medium_03.mp3",
      "fst_armor_medium_04.mp3",
      "fst_armor_medium_05.mp3",
      "fst_armor_medium_06.mp3",
      "fst_armor_medium_07.mp3",
      "fst_armor_medium_08.mp3",
    },
  },
  default = {
    wander = {
      "wander01.mp3",
      "wander02.mp3",
      "wander03.mp3",
      "wander04.mp3",
      "wander05.mp3",
      "wander06.mp3",
    },
    walk = {
      "walk01.mp3",
      "walk02.mp3",
      "walk03.mp3",
      "walk04.mp3",
      "walk05.mp3",
      "walk06.mp3",
      "walk07.mp3",
      "walk08.mp3",
      "walk09.mp3",
      "walk10.mp3",
    },
    run = {
      "run02.mp3",
      "run03.mp3",
      "run04.mp3",
    },
  },
  water = {
    wander = {
      "wander01.mp3",
      "wander02.mp3",
      "wander03.mp3",
      "wander04.mp3",
      "wander05.mp3",
    },
    unknown = {
      "water_through1.mp3",
      "water_through10.mp3",
      "water_through11.mp3",
      "water_through2.mp3",
      "water_through3.mp3",
      "water_through4.mp3",
      "water_through5.mp3",
      "water_through6.mp3",
      "water_through7.mp3",
      "water_through8.mp3",
      "water_through9.mp3",
    },
  },
  land = {
    unknown = {
      "fst_wood_jump_01.mp3",
      "fst_wood_jump_02.mp3",
      "fst_wood_jump_03.mp3",
    },
  },
  water_land = {
    unknown = {
      "fst_water_jump_01.mp3",
      "fst_water_jump_02.mp3",
    },
  },
}


local function getFootstepSound(material, speed)
    local sound_type = 'walk'
    if speed < 100 then sound_type = 'wander'
    elseif speed > 200 then sound_type = 'run' end

    local sounds = footsteps[material] and footsteps[material][sound_type]
    if not sounds or #sounds == 0 then return nil end
    local filename = sounds[math.random(#sounds)]
    return string.format('sound/%s/%s', material, filename)
end


local function getLandSound(material)
    local sounds = footsteps[material] and footsteps[material]['land']
    if not sounds or #sounds == 0 then return nil end
    local filename = sounds[math.random(#sounds)]
    return string.format('sound/%s/%s', material, filename)
end

local function getWaterSound()
    local sounds = footsteps['water'] and footsteps['water']['wander']
    if not sounds or #sounds == 0 then return nil end
    local filename = sounds[math.random(#sounds)]
    return string.format('sound/%s/%s', 'water', filename)
end

local function getDeepWaterSound()
    local sounds = footsteps['water'] and footsteps['water']['unknown']
    if not sounds or #sounds == 0 then return nil end
    local filename = sounds[math.random(#sounds)]
    return string.format('sound/%s/%s', 'water', filename)
end

local function getWaterSplashSound()
    local sounds = footsteps['water_land'] and footsteps['water_land']['unknown']
    if not sounds or #sounds == 0 then return nil end
    local filename = sounds[math.random(#sounds)]
    return string.format('sound/%s/%s', 'water_land', filename)
end

local function getChainSound()
    local sounds = footsteps['chain'] and footsteps['chain']['unknown']
    if not sounds or #sounds == 0 then return nil end
    local filename = sounds[math.random(#sounds)]
    return string.format('sound/%s/%s', 'chain', filename)
end

local function getArmorSound(armorIndex) --0 light, 1 medium, 2 heavy
    local armorType = 'Light'
    if armorIndex == 1 then armorType = 'Medium'
    elseif armorIndex == 2 then armorType = 'Heavy' end

    local sounds = footsteps['Armor'..armorType] and footsteps['Armor'..armorType]['unknown']
    if not sounds or #sounds == 0 then return nil end
    local filename = sounds[math.random(#sounds)]
    return string.format('sound/%s/%s', 'Armor'..armorType, filename)
end

local function getDifferentSound(lastSound, material, speed, s_type, walk_speed, run_speed)
    local run_speed = run_speed or 200
    local walk_speed = walk_speed or 100
    local sound_type = 'walk' or s_type
    if speed < walk_speed then sound_type = 'wander'
    elseif speed > run_speed - 10 then sound_type = 'run' end

    if not lastSound then
        -- If no last sound, just return a random sound
        return getFootstepSound(material, speed)
    end

    local sounds = footsteps[material] and footsteps[material][sound_type]
    if not sounds or #sounds <= 1 then
        -- If there's only one or no sound, we can't get a different one
        return lastSound
    end

    local lastFilename = lastSound:match("([^/]+)$") -- Extract filename from path
    local availableSounds = {}

    for _, sound in ipairs(sounds) do
        if sound ~= lastFilename then
            table.insert(availableSounds, sound)
        end
    end

    if #availableSounds == 0 then
        -- This shouldn't happen if we have more than one sound, but just in case
        return lastSound
    end

    local newFilename = availableSounds[math.random(#availableSounds)]
    return string.format('sound/%s/%s', material, newFilename)
end

local function getLandingSound()
  local sounds = footsteps['land'] and footsteps['land']['unknown']
  if not sounds or #sounds == 0 then return nil end
  local filename = sounds[math.random(#sounds)]
  return string.format('sound/%s/%s', 'land', filename)
end

return {
    getFootstepSound = getFootstepSound,
    getLandSound = getLandSound,
    getWaterSound = getWaterSound,
    getChainSound = getChainSound,
    getDifferentSound = getDifferentSound,
    getDeepWaterSound = getDeepWaterSound,
    getArmorSound = getArmorSound,
    getLandingSound = getLandingSound,
    getWaterSplashSound = getWaterSplashSound,
}