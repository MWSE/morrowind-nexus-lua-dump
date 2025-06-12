local world = require('openmw.world')
local types = require('openmw.types')
local util  = require('openmw.util')
local time = require('openmw_aux.time')

local ITEM_LISTS = require('scripts.detd_randomItemLists')  -- same table as above

---------------------------------------------------------------------
-- Give an actor replacement gear (only the IDs we actually got)
---------------------------------------------------------------------
local function detd_wabbahat(data)
  local actor     = data.obj3
  local items     = data.items            -- table: { helmet = 'id', boots = 'id', ... }
  local inventory = types.Actor.inventory(actor)

  -- create + move only what we need
  for key, id in pairs(items) do
    world.createObject(id):moveInto(inventory)
  end

  -- tell the NPC script to equip everything
  actor:sendEvent('detd_WabbaInventoryComplete', items)
end

---------------------------------------------------------------------

-- Helper: Get items that can be dumped from an actor's inventory.
local function getDumpableInventoryItems(actor)
    local items = {}
    local inventory = types.Actor.inventory(actor)
    local invItems = inventory:getAll()
    
    for _, item in pairs(invItems) do
        if (types.Armor.objectIsInstance(item) or types.Clothing.objectIsInstance(item)) and
           types.Actor.hasEquipped(actor, item) then
            -- Skip equipped armor/clothing
        else
            table.insert(items, item)
        end
    end
    
    return items
end

-- Helper: Dump the actor's inventory items on the ground at the given position.
local function dumpInventory(actor, position)
    local items = getDumpableInventoryItems(actor)
    for _, item in pairs(items) do
        item:teleport(actor.cell, position, { onGround = true })
        item.owner.factionId = nil
        item.owner.recordId = nil
    end
end

-- Random transformation event handler.
local function detd_WabbaEvent(data)
    local obj = data.obj

    local objcell = obj.cell

    if (objcell.isExterior == false or nil) then
        local transforms = {
            "scrib",
            "mudcrab",
            "BM_bear_black",
            "AB_Fau_SpiderParasolLrg",
            "alit",
            "AB_Fau_Bat",
            "BM_frost_boar",
            "BM_horker",
            "BM_spriggan",
            "BM_wolf_grey",
            "kagouti",
            "kwama forager",
            "kwama warrior",
            "nix-hound",
            "Rat",
            "shalk",
            "T_Cyr_Fau_Butterfly_02",
            "T_Cyr_Fau_CatlBull_01",
            "T_Cyr_Fau_CatlCow_01",
            "T_Cyr_Fau_Donk_01",
            "T_Cyr_Fau_Goat_01",
            "T_Cyr_Fau_Hrs_01",
            "T_Cyr_Fau_Muskrat_01",
            "T_Cyr_Fau_Pig_01",
            "T_Cyr_Fau_Pig_02",
            "T_Cyr_Fau_SnkDmAspis_01",
            "T_Glb_Cre_Gremlin_01",
            "T_Glb_Cre_Gremlin_02",
            "T_Glb_Cre_Gremlin_03",
            "T_Glb_Cre_Gremlin_04",
            "T_Glb_Cre_Gremlin_05",
            "T_Glb_Cre_LandDreu_01",
            "T_Glb_Cre_TrollCave_03",
            "T_Glb_Fau_BirdChi_01",
            "T_Glb_Fau_BirdChiRs_01",
            "T_Glb_Fau_Deer_01",
            "T_Glb_Fau_Squirrel_01",
            "T_Ham_Fau_Goat_01",
            "T_Ham_Fau_Wormmth_01",
            "T_Mw_Fau_AshFowl_01",
            "T_Mw_Fau_BeetleBl_01",
            "T_Mw_Fau_BeetleBr_01",
            "T_Mw_Fau_BeetleGr_01",
            "T_Mw_Fau_Molec_01",
            "T_Mw_Fau_Muskf_01",
            "T_Mw_Fau_Orn_01",
            "T_Mw_Fau_Para_01",
            "T_Mw_Fau_TrllSw_01",
            "T_Mw_Fau_Velk_01",
            "T_Mw_Fau_Tull_01",
            "AB_Fau_SpiderParasolBby",
            "AB_Fau_SpiderBlack",
            "T_Cyr_Fau_FrogBul_01",
            "T_Cyr_Fau_Tantha_01",
            "T_Cyr_Fau_SnkDmAspis_01",
            "T_Glb_Fau_HorkerGrey_01",
            "T_Cyr_Fau_RvNewt_01",
            "T_Glb_Cre_Kobold_01",
            "T_Glb_Cre_Sloa_01",
            "T_Cyr_Fau_BearCol_01",
            "T_Cyr_Fau_BirdStrid_01", 
            "T_Cyr_Fau_BirdStridN_01",
            "T_Cyr_Fau_Butterfly_01",
            "T_Cyr_Fau_Butterfly_02",
            "T_Cyr_Fau_Butterfly_03",
            "T_Cyr_Fau_Butterfly_04",
            "T_Cyr_Fau_Butterfly_05",
            "T_Cyr_Fau_Butterfly_06",
            "T_Cyr_Fau_CatlBull_01",
            "T_Cyr_Fau_Moonc_01",
            "T_Glb_Fau_RatGr_01", 
            "T_Glb_Fau_RatBk_01",
            "T_Ham_Fau_Spkworm_01",
            "T_Mw_Fau_Mucklch_01",
            "T_Mw_Fau_Para_01", 
            "T_Mw_Fau_RedoranHnd_01", 
            "T_Mw_Fau_SharaiHoppe_01",
            "T_Mw_Fau_SkrendHtc_01", 
            "T_Mw_Fau_Swfly_01",
            "T_Mw_Fau_Yethbug_01",
            "T_Sky_Fau_Danswyrm_01",
            "T_Sky_Fau_Elk_02",
        }
        
          
          -- Choose one transformation at random.
          local randomIndex = math.random(1, #transforms)
          local transformId = transforms[randomIndex]
          print("Transforming into: " .. transformId)
          print (obj.cell) 
          local New_object = world.createObject(transformId)
          New_object:teleport(obj.cell, obj.position, obj.rotation)
      end  

    print("Original object: ", obj)
    if (objcell.isExterior == true) then
        local transforms = {
            "scrib",
            "mudcrab",
            "BM_bear_black",
            "AB_Fau_SpiderParasolLrg",
            "alit",
            "AB_Fau_Bat",
            "BM_frost_boar",
            "BM_horker",
            "BM_spriggan",
            "BM_wolf_grey",
            "kagouti",
            "kwama forager",
            "kwama warrior",
            "nix-hound",
            "Rat",
            "shalk",
            "T_Cyr_Fau_Butterfly_02",
            "T_Cyr_Fau_CatlBull_01",
            "T_Cyr_Fau_CatlCow_01",
            "T_Cyr_Fau_Donk_01",
            "T_Cyr_Fau_Goat_01",
            "T_Cyr_Fau_Hrs_01",
            "T_Cyr_Fau_Muskrat_01",
            "T_Cyr_Fau_Pig_01",
            "T_Cyr_Fau_Pig_02",
            "T_Cyr_Fau_SnkDmAspis_01",
            "T_Glb_Cre_Gremlin_01",
            "T_Glb_Cre_Gremlin_02",
            "T_Glb_Cre_Gremlin_03",
            "T_Glb_Cre_Gremlin_04",
            "T_Glb_Cre_Gremlin_05",
            "T_Glb_Cre_LandDreu_01",
            "T_Glb_Cre_TrollCave_03",
            "T_Glb_Fau_BirdChi_01",
            "T_Glb_Fau_BirdChiRs_01",
            "T_Glb_Fau_Deer_01",
            "T_Glb_Fau_Squirrel_01",
            "T_Ham_Fau_Goat_01",
            "T_Ham_Fau_Wormmth_01",
            "T_Mw_Fau_AshFowl_01",
            "T_Mw_Fau_BeetleBl_01",
            "T_Mw_Fau_BeetleBr_01",
            "T_Mw_Fau_BeetleGr_01",
            "T_Mw_Fau_Molec_01",
            "T_Mw_Fau_Muskf_01",
            "T_Mw_Fau_Orn_01",
            "T_Mw_Fau_Para_01",
            "T_Mw_Fau_TrllSw_01",
            "T_Mw_Fau_Velk_01",
            "T_Mw_Fau_Tull_01",
            "AB_Fau_SpiderParasolBby",
            "AB_Fau_SpiderBlack",
            "T_Cyr_Fau_FrogBul_01",
            "T_Cyr_Fau_Tantha_01",
            "T_Cyr_Fau_SnkDmAspis_01",
            "T_Glb_Fau_HorkerGrey_01",
            "T_Cyr_Fau_RvNewt_01",
            "T_Glb_Cre_Kobold_01",
            "T_Glb_Cre_Sloa_01",
            "T_Cyr_Fau_BearCol_01",
            "T_Cyr_Fau_BirdStrid_01", 
            "T_Cyr_Fau_BirdStridN_01",
            "T_Cyr_Fau_Butterfly_01",
            "T_Cyr_Fau_Butterfly_02",
            "T_Cyr_Fau_Butterfly_03",
            "T_Cyr_Fau_Butterfly_04",
            "T_Cyr_Fau_Butterfly_05",
            "T_Cyr_Fau_Butterfly_06",
            "T_Cyr_Fau_CatlBull_01",
            "T_Cyr_Fau_Moonc_01",
            "T_Glb_Fau_RatGr_01", 
            "T_Glb_Fau_RatBk_01",
            "T_Ham_Fau_Spkworm_01",
            "T_Mw_Fau_Mucklch_01",
            "T_Mw_Fau_Para_01", 
            "T_Mw_Fau_RedoranHnd_01", 
            "T_Mw_Fau_SharaiHoppe_01",
            "T_Mw_Fau_SkrendHtc_01", 
            "T_Mw_Fau_Swfly_01",
            "T_Mw_Fau_Yethbug_01",
            "T_Sky_Fau_Danswyrm_01",
            "T_Sky_Fau_Elk_02",
            "netch_betty",
            "T_Sky_Cre_Giant_01",
            "T_Sky_Fau_Mamm_01",
            "T_Cyr_Cre_Mino_02",
            "T_Cyr_Cre_Mino_01",
            "T_Pi_Fau_Roc_01",
            "T_Glb_Cre_TrollFrost_01",
            "T_Sky_Fau_SabCat_01",
            "T_Cyr_Fau_Alphyn_01",
            "T_Sky_Fau_Raki_01",
            "AB_Fau_SpiderBlackLrg",
            "BM_ice_troll_tough",
            "T_Glb_Fau_LrgSpider_01",  
            "T_Sky_Fau_CatlCowP_01",
            "durzog_wild_weaker"
        }
 -- Choose one transformation at random.
 local randomIndex = math.random(1, #transforms)
 local transformId = transforms[randomIndex]
 print("Transforming into: " .. transformId)
 print (obj.cell) 
 local New_object = world.createObject(transformId)
 New_object:teleport(obj.cell, obj.position, obj.rotation)
    end
end

local function detd_DisableActor(data2)
    local objDisable = data2.obj2
    dumpInventory(objDisable, objDisable.position)
    objDisable.enabled = false
end

local function detd_SmallifyActorWabba(data3)
   local objSmall = data3.obj2
   objSmall:setScale(0.001)
end

local function detd_EnlargeActor(data4)
   local objlarger = data4.obj2
   objlarger:setScale(objlarger.scale*1.1)
end

local function detd_SmallifyActor(data5)
   local objsmallify = data5.obj2
   objsmallify:setScale(objsmallify.scale*0.9)
end

local function detd_SpawnClone(data)
    local actor  = data.obj
    local chance = data.chance or 0

    if math.random() <= chance then
        -- create a single copy of the same NPC record
        local clone = world.createObject(actor.recordId, 1)

        -- First, place the clone in the actor's current cell
        clone:teleport(actor.cell, actor.position, actor.rotation)
        
        -- Now it has a cell, so this is safe
         if actor.cell and actor.cell.isExterior then
            -- Move it 1000 units up
           local abovePos = util.vector3(actor.position.x, actor.position.y + 200, actor.position.z + 3000)
           actor:teleport(actor.cell, abovePos, actor.rotation)
           print("went up")
        end
        
    end
end

local _shrinking = {}

time.runRepeatedly(function()
    for id, ref in pairs(_shrinking) do
        if not ref:isValid() then
            _shrinking[id] = nil

        else
            local newScale = ref.scale * 0.995
            if newScale <= 0.20 then            -- hard minimum (10 %)
                newScale       = 0.20            -- clamp, don’t rebound
                _shrinking[id] = nil             -- stop shrinking
                ref:setScale(newScale)           -- write first…
                ref:sendEvent('detd_WabbaSmallWeak')  -- …then notify
            else
                ref:setScale(newScale)
            end
        end
    end
end, 0.01 * time.second)

local function detd_StartGradualShrink(dataShrink)
    local npc = dataShrink.obj
    if npc and npc:isValid() then
        _shrinking[npc.id] = npc
    end
end

local _growing = {}                  -- id → ref  (actors that are regrowing)
local GROW_FACTOR = 1 / 0.995        -- ≈ 1.005 025 (exact inverse of shrink)
local MAX_SCALE  = 1.0               -- stop when we reach normal size

time.runRepeatedly(function()
    for id, ref in pairs(_growing) do
        if not ref:isValid() then
            _growing[id] = nil

        else
            local newScale = ref.scale * GROW_FACTOR
            if newScale >= MAX_SCALE then        -- reached full size
                newScale    = MAX_SCALE
                _growing[id] = nil               -- stop growing
                ref:setScale(newScale)           -- write first …
                ref:sendEvent('detd_WabbaBackToNormal')  -- … then notify
            else
                ref:setScale(newScale)
            end
        end
    end
end, 0.01 * time.second)             -- same tick rate as the shrink loop

-- Call this to start regrowing an NPC / creature that is currently small
local function detd_StartGradualGrow(dataGrow)
    local npc = dataGrow.obj
    if npc and npc:isValid() then
        _growing[npc.id] = npc
    end
end

local _enlarging     = {}             -- id → ref  (actors growing to 2×)
local _normalizing   = {}             -- id → ref  (actors shrinking to 1×)

local ENLARGE_FACTOR = 1 / 0.995      -- ≈ 1.005  (0.5 % per tick)
local SHRINK_FACTOR  = 0.995
local MAX_GIANT      = 2.0
local NORMAL_SCALE   = 1.0

-- ── tick: enlarge to MAX_GIANT ──────────────────────────────────────
time.runRepeatedly(function()
    for id, ref in pairs(_enlarging) do
        if not ref:isValid() then
            _enlarging[id] = nil

        else
            local newScale = ref.scale * ENLARGE_FACTOR
            if newScale >= MAX_GIANT then
                newScale       = MAX_GIANT
                _enlarging[id] = nil
                ref:setScale(newScale)
                ref:sendEvent('detd_WabbaGiantDone')  -- optional notification
            else
                ref:setScale(newScale)
            end
        end
    end
end, 0.01 * time.second)

-- ── tick: shrink giants back to normal ─────────────────────────────
time.runRepeatedly(function()
    for id, ref in pairs(_normalizing) do
        if not ref:isValid() then
            _normalizing[id] = nil

        else
            local newScale = ref.scale * SHRINK_FACTOR
            if newScale <= NORMAL_SCALE then
                newScale        = NORMAL_SCALE
                _normalizing[id] = nil
                ref:setScale(newScale)
                ref:sendEvent('detd_WabbaGiantGone')   -- optional notification
            else
                ref:setScale(newScale)
            end
        end
    end
end, 0.01 * time.second)

-- ── public helpers ─────────────────────────────────────────────────
-- Call to start the 1.0 → 2.0 growth
local function detd_StartGradualEnlarge(data)
    local npc = data.obj
    if npc and npc:isValid() then
        _enlarging[npc.id]   = npc
        _normalizing[npc.id] = nil     -- cancel any opposite queue
    end
end

-- Call to start the 2.0 → 1.0 return
local function detd_StartGradualNormalize(data)
    local npc = data.obj
    if npc and npc:isValid() then
        _normalizing[npc.id] = npc
        _enlarging[npc.id]   = nil     -- cancel any opposite queue
    end
end


local function detd_ModifyDisposition(data)
    local npc    = data.npc
    local amount = data.amount or 0
    if not npc then return end

    for _, player in ipairs(world.players) do
        types.NPC.modifyBaseDisposition(npc, player, amount)
    end

    local player1 = world.players[1]
    types.Actor.spells(player1):add('detd_clear_crime')
end
---------------------------------------------------------------------
-- ... detd_WabbaEvent, detd_DisableActor, etc. ...

return {
  eventHandlers = {
    detd_wabbahat          = detd_wabbahat,
    detd_WabbaEvent        = detd_WabbaEvent,
    detd_DisableActor      = detd_DisableActor,
    detd_SmallifyActorWabba= detd_SmallifyActorWabba,
    detd_EnlargeActor      = detd_EnlargeActor,
    detd_SmallifyActor     = detd_SmallifyActor,
    detd_SpawnClone        = detd_SpawnClone,
    detd_ModifyDisposition = detd_ModifyDisposition,
    detd_StartGradualShrink = detd_StartGradualShrink,
    detd_StartGradualGrow = detd_StartGradualGrow,
    detd_StartGradualNormalize = detd_StartGradualNormalize,
    detd_StartGradualEnlarge = detd_StartGradualEnlarge,

  }
} 