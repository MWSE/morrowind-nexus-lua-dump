local Core = require('openmw.core')
local Types = require('openmw.types')
local Nearby = require('openmw.nearby')
local Until = require('openmw.util')
local Storage = require('openmw.storage')
local Async = require('openmw.async')
local SoundData = require('Scripts.MaxarFootsteps.SoundsData')

local settingsGroup = Storage.globalSection('Settings_foot')
local settings = {
    volume = 1.0,
    lightArmorVolume = 0.5,
    mediumArmorVolume = 0.7,
    heavyArmorVolume = 0.9
}
local function updateSettingsFromStorage()
    settings.volume = settingsGroup:get('volume') / 100
    settings.lightArmorVolume = settingsGroup:get('lightArmorVolume') / 100
    settings.mediumArmorVolume = settingsGroup:get('mediumArmorVolume') / 100
    settings.heavyArmorVolume = settingsGroup:get('heavyArmorVolume') / 100
end
settingsGroup:subscribe(Async:callback(updateSettingsFromStorage))
local function getWaterDeepness(actor)
    local position = actor.position
    local startingPoint = position:__add(Until.vector3(0,0,120))
    local endingPoint = Until.vector3(0,0,-100):__add(position)

    local feetPoint = position:__add(Until.vector3(0,0,0))

    local waterRaycast = Nearby.castRay(startingPoint, endingPoint,{ignore=actor,collisionType=Nearby.COLLISION_TYPE.Water})
    local groundRaycast = Nearby.castRay(startingPoint, endingPoint,{ignore=actor,collisionType=Nearby.COLLISION_TYPE.HeightMap})

    if waterRaycast.hit then
      local height = 100
      if groundRaycast.hit then
        height = waterRaycast.hitPos.z - groundRaycast.hitPos.z
      end
      local distanceToWater = feetPoint:__sub(waterRaycast.hitPos).z
      --print("Distance to water: " .. distanceToWater)
      local isInWater = distanceToWater < 0
      return height, isInWater, distanceToWater
    end
end
local function rayCastWater(actor)
    local position = actor.position
    local startingPoint = position:__add(Until.vector3(0,0,120))
    local endingPoint = Until.vector3(0,0,-40):__add(position)
    local options = {
      ignore = actor,
      collisionType = Nearby.COLLISION_TYPE.Water
    }

    local option_vivec_water = {
        ignore = actor,
        collisionType = Nearby.COLLISION_TYPE.Default
    }
    local raycast = Nearby.castRay(startingPoint, endingPoint,options)
    if raycast.hit then
      local height = raycast.hitPos.z - position.z
      return height
    end
end
local function playWaterSound(actor)
    Core.sound.playSoundFile3d(SoundData.getDeepWaterSound(),actor,{timeOffset=0.0,volume=settings.volume,loop=false,pitch=1.0})
end
local function playWaterFootstep(actor)
    local deepwaterparams = {
        timeOffset=0.0,
        volume=settings.volume + 1.0,
        loop=false,
        pitch=1.0
    }
    local height, isInWater, distanceToWater = getWaterDeepness(actor)
    if height and height > 0 and distanceToWater < 5 then
        --print("Water deepness: " .. height)
        if isInWater then
            deepwaterparams.pitch = math.max(1.0 - height / 100, 0.5)
            Core.sound.playSoundFile3d(SoundData.getDeepWaterSound(), actor, deepwaterparams)
        else
            Core.sound.playSoundFile3d(SoundData.getWaterSound(), actor, deepwaterparams)
        end
        return true
    end
    return false
end
local function isSneaking(actor)
    return actor.controls.sneak
end

local lastFootSound = ""
local function playFootstepSound(actor, pitch)
    local params = {
    timeOffset=0.0,
    volume=settings.volume,
    loop=false,
    pitch= pitch or 1.0
    }

    local speed = Types.Actor.getCurrentSpeed(actor)

    local boots = Types.Actor.getEquipment(actor,Types.Actor.EQUIPMENT_SLOT.Boots)
    if boots and Types.Armor.objectIsInstance(boots) then
        local weight = Types.Armor.record(boots).weight
        if weight > 18.0 then
            params.volume = settings.volume
        elseif weight > 12.0 then
            params.volume = settings.volume * 0.95
        else
            params.volume = settings.volume * 0.90
        end
    else
        params.volume = settings.volume * 0.85
    end

    if isSneaking(actor) then
        lastFootSound = SoundData.getDifferentSound(lastFootSound, "default", speed, 'wander', settings.baseWalkingSpeed, settings.baseRunningSpeed)
    else
        lastFootSound = SoundData.getDifferentSound(lastFootSound, "default", speed, nil, settings.baseWalkingSpeed, settings.baseRunningSpeed)
    end
    
    if not playWaterFootstep(actor) then
        Core.sound.playSoundFile3d(lastFootSound, actor, params)
    end
end
local armorSlotsVolumes = {
    [Types.Actor.EQUIPMENT_SLOT.Boots] = 0.5,         -- Feet armor
    [Types.Actor.EQUIPMENT_SLOT.Cuirass] = 1.0,       -- Chest armor (loudest)
    [Types.Actor.EQUIPMENT_SLOT.Greaves] = 0.7,       -- Leg armor
    [Types.Actor.EQUIPMENT_SLOT.Helmet] = 0.1,        -- Head armor
    [Types.Actor.EQUIPMENT_SLOT.LeftGauntlet] = 0.1,  -- Left hand armor
    [Types.Actor.EQUIPMENT_SLOT.LeftPauldron] = 0.6,  -- Left shoulder armor
    [Types.Actor.EQUIPMENT_SLOT.RightGauntlet] = 0.1, -- Right hand armor
    [Types.Actor.EQUIPMENT_SLOT.RightPauldron] = 0.6  -- Right shoulder armor
}

local armorWeightLimits = {
    [Types.Actor.EQUIPMENT_SLOT.Boots] = {light = 12.0, medium = 18.0},
    [Types.Actor.EQUIPMENT_SLOT.Cuirass] = {light = 18.0, medium = 27.0},
    [Types.Actor.EQUIPMENT_SLOT.Greaves] = {light = 9.0, medium = 13.5},
    [Types.Actor.EQUIPMENT_SLOT.Helmet] = {light = 3.0, medium = 4.5},
    [Types.Actor.EQUIPMENT_SLOT.LeftGauntlet] = {light = 3.0, medium = 4.5},
    [Types.Actor.EQUIPMENT_SLOT.RightGauntlet] = {light = 3.0, medium = 4.5},
    [Types.Actor.EQUIPMENT_SLOT.LeftPauldron] = {light = 6.0, medium = 9.0},
    [Types.Actor.EQUIPMENT_SLOT.RightPauldron] = {light = 6.0, medium = 9.0}
 }
 
local function getArmorClass(slot, weight)
    local limits = armorWeightLimits[slot]
    if not limits then return nil end -- invalid slot
    
    if weight <= limits.light then
        return 0 -- light
    elseif weight <= limits.medium then
        return 1 -- medium
    else
        return 2 -- heavy
    end
 end

local function getArmorVolumme(type)
    if type == 0 then
        return settings.lightArmorVolume
    elseif type == 1 then
        return settings.mediumArmorVolume
    elseif type == 2 then
        return settings.heavyArmorVolume
    end
end
local function playArmorSound(actor, pitch)
    local armorVolumes = {
    [0] = 0.0,
    [1] = 0.0,
    [2] = 0.0,
    }
    
    for slot, volume in pairs(armorSlotsVolumes) do
        local item = Types.Actor.getEquipment(actor,slot)
        if item and Types.Armor.objectIsInstance(item) then
            local weight = Types.Armor.record(item).weight
            local armorClass = getArmorClass(slot, weight)
            if armorClass then
                armorVolumes[armorClass] = armorVolumes[armorClass] + volume * getArmorVolumme(armorClass)
            end
        end
    end

    local waterHeight, isInWater = getWaterDeepness(actor)
    local pitch = 1.0
    local timeOffset = 0.0
    if isInWater then
        pitch = math.max(1.0 - waterHeight / 400, 0.75)
        timeOffset = timeOffset + pitch
    end
    for slot, volume in pairs(armorVolumes) do
        if volume > 0 then
            local sound = SoundData.getArmorSound(slot)
            Core.sound.playSoundFile3d(sound, actor, {timeOffset=timeOffset,volume=settings.volume * volume,loop=false,pitch=pitch})
        end
    end
end
local function playLandingSound(actor)
    Core.sound.playSoundFile3d(SoundData.getLandingSound(),actor,{timeOffset=0.0,volume=settings.volume,loop=false,pitch=1.0})
end

local function playWaterSplash(actor,pitchh, volume)
    local pitch = pitchh or 1.0
    local volume = volume or settings.volume
    local file = SoundData.getWaterSplashSound()
    Core.sound.playSoundFile3d(file,actor,{timeOffset=0.0,volume=volume,loop=false,pitch=pitch})
end

return {
    rayCastWater = rayCastWater,
    getWaterDeepness = getWaterDeepness,
    playFootstepSound = playFootstepSound,
    playArmorSound = playArmorSound,
    playLandingSound = playLandingSound,
    playWaterSound = playWaterSound,
    playWaterSplash = playWaterSplash
}