-- devilish_wabbajack_global.lua
-- Path: scripts/devilish_wabbajack_global.lua

local world = require('openmw.world')
local types = require('openmw.types')
local util  = require('openmw.util')
local time  = require('openmw_aux.time')
local core  = require('openmw.core')

local ITEM_LISTS = require('scripts.detd_randomItemLists')

local SCALE_TICK = 0.05 * time.second

-- Gentler scale speeds
local SCALE_FACTOR_DOWN = 0.9925
local SCALE_FACTOR_UP = 1 / SCALE_FACTOR_DOWN

local MIN_SCALE = 0.75
local MAX_SCALE = 1.50
local NORMAL_SCALE = 1.0

--------------------------------------------------------
-- DEBUG HELPER
--------------------------------------------------------

local function dbg(msg)
    print("[WABBAJACK GLOBAL] " .. tostring(msg))
end

--------------------------------------------------------
-- WEATHER EFFECT
--------------------------------------------------------

local WABBA_WEATHERS = {
    core.weather.records.Clear,
    core.weather.records.Cloudy,
    core.weather.records.Foggy,
    core.weather.records.Overcast,
    core.weather.records.Rain,
    core.weather.records.Thunderstorm,
    core.weather.records.Ashstorm,
    core.weather.records.Blight,
    core.weather.records.Snow,
    core.weather.records.Blizzard,
}

local function detd_WabbaRandomWeather(data)
    dbg("Weather event triggered")

    local obj = data and data.obj

    if not obj then
        dbg("No object passed")
        return
    end

    if not obj.cell then
        dbg("Object has no cell")
        return
    end

    if not obj.cell.isExterior then
        dbg("Target is indoors - weather change skipped")
        return
    end

    local regionId = obj.cell.region
    if not regionId then
        dbg("No region detected")
        return
    end

    local weather = WABBA_WEATHERS[math.random(#WABBA_WEATHERS)]
    dbg("Region detected: " .. tostring(regionId))
    dbg("Weather change executed")

    core.weather.changeWeather(regionId, weather)
end

--------------------------------------------------------
-- TRANSFORM LISTS
--------------------------------------------------------

local INTERIOR_TRANSFORMS = {
    'scrib', 'mudcrab', 'AB_Fau_SpiderParasolLrg', 'alit', 'AB_Fau_Bat',
    'BM_frost_boar', 'BM_horker', 'BM_spriggan', 'BM_wolf_grey', 'kagouti', 'kwama forager',
    'kwama warrior', 'nix-hound', 'Rat', 'shalk', 'T_Cyr_Fau_Butterfly_02', 'T_Cyr_Fau_CatlBull_01',
    'T_Cyr_Fau_CatlCow_01', 'T_Cyr_Fau_Donk_01', 'T_Cyr_Fau_Goat_01', 'T_Cyr_Fau_Hrs_01',
    'T_Cyr_Fau_Muskrat_01', 'T_Cyr_Fau_Pig_01', 'T_Cyr_Fau_Pig_02', 'T_Cyr_Fau_SnkDmAspis_01',
    'T_Glb_Cre_Gremlin_01', 'T_Glb_Cre_Gremlin_02', 'T_Glb_Cre_Gremlin_03', 'T_Glb_Cre_Gremlin_04',
    'T_Glb_Cre_Gremlin_05', 'T_Glb_Fau_BirdChi_01',
    'T_Glb_Fau_BirdChiRs_01', 'T_Glb_Fau_Deer_01', 'T_Glb_Fau_Squirrel_01', 'T_Ham_Fau_Goat_01',
    'T_Ham_Fau_Wormmth_01', 'T_Mw_Fau_AshFowl_01', 'T_Mw_Fau_BeetleBl_01', 'T_Mw_Fau_BeetleBr_01',
    'T_Mw_Fau_BeetleGr_01', 'T_Mw_Fau_Molec_01', 'T_Mw_Fau_Muskf_01', 'T_Mw_Fau_Orn_01',
    'T_Mw_Fau_Para_01', 'T_Mw_Fau_TrllSw_01', 'T_Mw_Fau_Velk_01', 'T_Mw_Fau_Tull_01',
    'AB_Fau_SpiderBlack', 'T_Cyr_Fau_FrogBul_01', 'T_Cyr_Fau_Tantha_01',
    'T_Glb_Fau_HorkerGrey_01', 'T_Cyr_Fau_RvNewt_01', 'T_Glb_Cre_Kobold_01',
    'T_Cyr_Fau_BirdStrid_01', 'T_Cyr_Fau_BirdStridN_01', 'T_Cyr_Fau_Butterfly_01',
    'T_Cyr_Fau_Butterfly_03', 'T_Cyr_Fau_Butterfly_04', 'T_Cyr_Fau_Butterfly_05', 'T_Cyr_Fau_Butterfly_06',
    'T_Cyr_Fau_Moonc_01', 'T_Glb_Fau_RatGr_01', 'T_Glb_Fau_RatBk_01', 'T_Ham_Fau_Spkworm_01',
    'T_Mw_Fau_Mucklch_01', 'T_Mw_Fau_RedoranHnd_01', 'T_Mw_Fau_SharaiHoppe_01', 'T_Mw_Fau_SkrendHtc_01',
    'T_Mw_Fau_Swfly_01', 'T_Mw_Fau_Yethbug_01', 'T_Sky_Fau_Danswyrm_01', 'T_Sky_Fau_Elk_02',
}

local EXTERIOR_ONLY_TRANSFORMS = {
    'netch_betty', 'T_Sky_Cre_Giant_01', 'T_Sky_Fau_Mamm_01', 'T_Cyr_Cre_Mino_02', 'T_Cyr_Cre_Mino_01',
    'T_Pi_Fau_Roc_01', 'T_Glb_Cre_TrollFrost_01', 'T_Sky_Fau_SabCat_01', 'T_Cyr_Fau_Alphyn_01',
    'T_Sky_Fau_Raki_01', 'AB_Fau_SpiderBlackLrg', 'BM_ice_troll_tough', 'T_Glb_Fau_LrgSpider_01',
    'T_Sky_Fau_CatlCowP_01', 'durzog_wild_weaker',
}

--------------------------------------------------------
-- SCALE SYSTEM
--------------------------------------------------------

local SCALE_MODES = {
    shrink = {
        factor = SCALE_FACTOR_DOWN,
        stopAt = MIN_SCALE,
        stopIf = function(scale) return scale <= MIN_SCALE end,
        event = 'detd_WabbaSmallWeak',
    },
    grow = {
        factor = SCALE_FACTOR_UP,
        stopAt = NORMAL_SCALE,
        stopIf = function(scale) return scale >= NORMAL_SCALE end,
        event = 'detd_WabbaBackToNormal',
    },
    enlarge = {
        factor = SCALE_FACTOR_UP,
        stopAt = MAX_SCALE,
        stopIf = function(scale) return scale >= MAX_SCALE end,
        event = 'detd_WabbaGiantDone',
    },
    normalize = {
        factor = SCALE_FACTOR_DOWN,
        stopAt = NORMAL_SCALE,
        stopIf = function(scale) return scale <= NORMAL_SCALE end,
        event = 'detd_WabbaGiantGone',
    },
}

local scalingActors = {}

local function chooseRandom(list)
    return list[math.random(#list)]
end

local function chooseTransformForActor(actor)
    if not actor or not actor.cell then
        return nil
    end

    if actor.cell.isExterior then
        if math.random(100) == 1 then
            local picked = chooseRandom(EXTERIOR_ONLY_TRANSFORMS)
            dbg("Exterior rare roll succeeded, using exterior-only transform: " .. tostring(picked))
            return picked
        else
            local picked = chooseRandom(INTERIOR_TRANSFORMS)
            dbg("Exterior rare roll failed, using interior transform: " .. tostring(picked))
            return picked
        end
    end

    local picked = chooseRandom(INTERIOR_TRANSFORMS)
    dbg("Interior cell, using interior transform: " .. tostring(picked))
    return picked
end

local function getIndoorOffsetPosition(actor)
    local offsets = {
        util.vector3(80, 0, 0),
        util.vector3(-80, 0, 0),
        util.vector3(0, 80, 0),
        util.vector3(0, -80, 0),
    }

    local offset = offsets[math.random(#offsets)]
    return util.vector3(
        actor.position.x + offset.x,
        actor.position.y + offset.y,
        actor.position.z + offset.z
    )
end

local function queueScaleMode(actor, mode)
    if actor and actor.isValid and actor:isValid() then
        scalingActors[actor.id] = {
            ref = actor,
            mode = mode,
        }
        dbg("Queued scale mode: " .. tostring(mode))
    else
        dbg("queueScaleMode failed: invalid actor")
    end
end

time.runRepeatedly(function()
    for id, entry in pairs(scalingActors) do
        local ref = entry.ref
        local mode = SCALE_MODES[entry.mode]

        if not ref or not ref:isValid() or not mode then
            scalingActors[id] = nil
        else
            local newScale = ref.scale * mode.factor

            if mode.stopIf(newScale) then
                ref:setScale(mode.stopAt)
                scalingActors[id] = nil
                dbg("Scale finished: " .. tostring(entry.mode))

                if mode.event then
                    ref:sendEvent(mode.event)
                end
            else
                ref:setScale(newScale)
            end
        end
    end
end, SCALE_TICK)

local function detd_StartGradualShrink(data)
    queueScaleMode(data.obj, 'shrink')
end

local function detd_StartGradualGrow(data)
    queueScaleMode(data.obj, 'grow')
end

local function detd_StartGradualEnlarge(data)
    queueScaleMode(data.obj, 'enlarge')
end

local function detd_StartGradualNormalize(data)
    queueScaleMode(data.obj, 'normalize')
end

--------------------------------------------------------
-- WABBA HAT / ITEM REPLACEMENT
--------------------------------------------------------

local function detd_wabbahat(data)
    local actor = data.obj3
    local items = data.items

    if not actor or not items then
        dbg("detd_wabbahat failed: missing actor or items")
        return
    end

    dbg("Adding replacement items")

    local inventory = types.Actor.inventory(actor)

    for _, id in pairs(items) do
        if id then
            world.createObject(id):moveInto(inventory)
        end
    end

    actor:sendEvent('detd_WabbaInventoryComplete', items)
end

--------------------------------------------------------
-- INVENTORY DUMP FOR TRANSFORMED ACTORS
--------------------------------------------------------

local function getDumpableInventoryItems(actor)
    local items = {}
    local inventory = types.Actor.inventory(actor)
    local invItems = inventory:getAll()

    for _, item in pairs(invItems) do
        local isEquippedArmorOrClothing =
            (types.Armor.objectIsInstance(item) or types.Clothing.objectIsInstance(item)) and
            types.Actor.hasEquipped(actor, item)

        if not isEquippedArmorOrClothing then
            items[#items + 1] = item
        end
    end

    return items
end

local function dumpInventory(actor, position)
    local items = getDumpableInventoryItems(actor)

    for i = 1, #items do
        local item = items[i]
        item:teleport(actor.cell, position, { onGround = true })
        item.owner.factionId = nil
        item.owner.recordId = nil
    end
end

--------------------------------------------------------
-- WABBA TRANSFORM
--------------------------------------------------------

local function detd_WabbaEvent(data)
    dbg("Transformation event triggered")

    local obj = data.obj
    if not obj or not obj.cell then
        dbg("Invalid object for transform")
        return
    end

    local transformId = chooseTransformForActor(obj)
    if not transformId then
        dbg("No transform could be selected")
        return
    end

    dbg("Transforming into: " .. tostring(transformId))

    local newObject = world.createObject(transformId)

    if obj.cell.isExterior then
        newObject:teleport(obj.cell, obj.position, obj.rotation)
    else
        newObject:teleport(obj.cell, getIndoorOffsetPosition(obj), obj.rotation)
    end
end

--------------------------------------------------------
-- DISABLE ACTOR
--------------------------------------------------------

local function detd_DisableActor(data)
    dbg("Disable actor event")

    local objDisable = data.obj2
    if not objDisable then
        dbg("Disable failed - no actor")
        return
    end

    dumpInventory(objDisable, objDisable.position)
    objDisable.enabled = false
end

--------------------------------------------------------
-- SCALE EFFECTS
--------------------------------------------------------

local function detd_SmallifyActorWabba(data)
    local objSmall = data.obj2

    if objSmall then
        dbg("Smallify actor to tiny size")
        objSmall:setScale(0.001)
    end
end

local function detd_EnlargeActor(data)
    local objLarger = data.obj2

    if objLarger then
        dbg("Enlarge actor")
        objLarger:setScale(math.min(objLarger.scale * 1.1, MAX_SCALE))
    end
end

local function detd_SmallifyActor(data)
    local objSmallify = data.obj2

    if objSmallify then
        dbg("Shrink actor")
        objSmallify:setScale(math.max(objSmallify.scale * 0.9, MIN_SCALE))
    end
end

--------------------------------------------------------
-- SPAWN CLONE
--------------------------------------------------------

local function detd_SpawnClone(data)
    local actor = data.obj
    local chance = data.chance or 0

    if not actor then
        dbg("Spawn clone failed: no actor")
        return
    end

    if math.random() > chance then
        dbg("Spawn clone roll failed")
        return
    end

    dbg("Spawning clone")

    local clone = world.createObject(actor.recordId, 1)

    if actor.cell and actor.cell.isExterior then
        local abovePos = util.vector3(
            actor.position.x,
            actor.position.y + 200,
            actor.position.z + 3000
        )
        clone:teleport(actor.cell, abovePos, actor.rotation)
    else
        clone:teleport(actor.cell, getIndoorOffsetPosition(actor), actor.rotation)
    end
end

--------------------------------------------------------
-- KNOCKBACK
--------------------------------------------------------

local function detd_EnemyKnockback(data)
    if not data or not data.actor or not data.nextPos then
        dbg("Knockback failed - invalid data")
        return
    end

    dbg("Applying knockback")

    local actor = data.actor
    local onGround = data.ground

    actor:teleport(
        actor.cell,
        data.nextPos,
        {
            onGround = onGround,
            rotation = data.rotation,
        }
    )

    actor:sendEvent('detd_TELE_DONE')
end

--------------------------------------------------------
-- DISPOSITION
--------------------------------------------------------

local function detd_ModifyDisposition(data)
    local npc = data.npc
    local amount = data.amount or 0

    if not npc then
        dbg("ModifyDisposition failed: no npc")
        return
    end

    dbg("Modifying disposition by " .. tostring(amount))

    for _, player in ipairs(world.players) do
        types.NPC.modifyBaseDisposition(npc, player, amount)
    end

    local player1 = world.players[1]
    if player1 then
        types.Actor.spells(player1):add('detd_clear_crime')
    end
end

--------------------------------------------------------
-- EVENT REGISTRATION
--------------------------------------------------------

return {
    eventHandlers = {
        detd_wabbahat = detd_wabbahat,
        detd_WabbaEvent = detd_WabbaEvent,
        detd_DisableActor = detd_DisableActor,
        detd_SmallifyActorWabba = detd_SmallifyActorWabba,
        detd_EnlargeActor = detd_EnlargeActor,
        detd_SmallifyActor = detd_SmallifyActor,
        detd_SpawnClone = detd_SpawnClone,
        detd_ModifyDisposition = detd_ModifyDisposition,
        detd_StartGradualShrink = detd_StartGradualShrink,
        detd_StartGradualGrow = detd_StartGradualGrow,
        detd_StartGradualNormalize = detd_StartGradualNormalize,
        detd_StartGradualEnlarge = detd_StartGradualEnlarge,
        detd_EnemyKnockback = detd_EnemyKnockback,
        detd_WabbaRandomWeather = detd_WabbaRandomWeather,
    }
}
