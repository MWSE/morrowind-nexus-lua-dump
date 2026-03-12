
--NOTES
-- add gold to player -> player->additem "gold_001" 50000
-- While an object is being teleported it cant be :removed(), it will show error as "cant remove 0 of 0 items"
-- ToggleCollision in console to noclip fly
-- Use this to run a function kinda like a coroutine -> time.runRepeatedly(updateTime, 1 * time.minute, { type = time.GameTime })
-- when using util.transform.rotateZ(radians) make sure to use radians and not an angle like the docs say
-- Error was saying it couldn't load/find a lua script, it was because it was missing a "require" at the top (core)

-- __TIPS__
--  __WAYS TO GET REFERENCES__
-- Cell:getAll(type) -> Get all objects of given type from the cell
-- Get an ANY record by recordId -> types.ANY.record(recordId) (eg. types.NPC.record('hannabi zabynatus'))
-- Get an object by formId -> local obj = world.getObjectByFormId(core.getFormId('Morrowind.esm', 480636)) (NOTE: this is not the ideal way to get a ref) (tip: click item with console open and type 'ori')
-- print an object.id then can check it (eg. object.id == '0x104c6eb') using onObjectActive() engine handler

--TODO
-- Planters that you can grow plants/alchemy ingredients in (static: Furn_Com_Planter and furn_planter_01 (01 - 04) and Furn_Planter_MH_03/Furn_Planter_MH_04
-- add hammock and bed (active_de_p_bed_28, active_de_pr_bed_22, active_de_r_bed_02) its an activator so spawn it using its recordId instead of building it from scratch
-- new statues = azura statue (azura under activators, just use model), static ex_v_stdeyln_01 and ex_v_vivecstatue_01
-- turrets that auto attack enemies (maybe) (crossbow model - static: ex_dwrv_walker00)

-- DRUG DEALER MOD -> grow plants (meshes/f/furn_pottedplant.nif) package them (misc: dwemer_satchel00), make skooma/moon sugar, Get orders deliver, don't get caught, hire hirelings, 

-- Potential models for ship upgrades
-- ACTIVATORS
-- a_light_dw_neon
-- act_dwe_fan00
-- act_dwe_gyro00
-- act_dwe_lever_a (is a lever with animations)
-- act_h20crank_-550_400 (might replace gear for steering)
-- act_sotha_gear00 (00 thru 03)
-- act_sotha_green00 and act_sotha_red00
-- Ex_aldruhn_roadmarker_01
-- misc_dwrv_prox_mine and prox_proj_mine
-- STATIC
-- ex_dae_claw_02
-- furn_spinningwheel_01
-- furn_spinwheel00
-- in_dwrv_scope00

-- Awesome video I took of using jump spell to get onto skyship

local util = require('openmw.util')
local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local modVersion = 1

--Player Inputs
local camForward = util.vector3(0,0,0)
local input_moveFwd = 0
local input_moveBack = 0
local input_moveL = 0
local input_moveR = 0
local input_jump = false
local input_run = 0
local input_activate = 0
local input_use = 0

local skyship = nil
local ropes = {}
local skyshipActivators = {}
local itemsPlacedOnDeck = {}

local state = "none"
local playerIsFlying = false
local skyshipRot = 0
local skyshipRotTarget = 0
local skyshipSpeed = 0
local raycastFoundSurfacePos = util.vector3(0,0,0)
local lerpPlayerActive = false
local skyshipMerchant = nil
local juliusActor = nil
local skyshipTableModel = nil

local placingObject = nil
local placingObjectRot = 0
local placingItemStackCount = 0
local placingObjectTestVOffset = 0
local delayUpdateTimer = 0
local climbRopeSoundTimer = 0
local climbRopeSoundPitch = 1
local objectToDestroy = {}

local activeCoroutines = {}
local loadedGameSetupTimer = 0
local lowFpsCheckerCounter = 0
local deltaTime = 0

local globals = world.mwscript.getGlobalVariables()

local setting_showFlyControlsPrompt = true
local setting_lowFpsMode = false

local upgrade_shipSpeed = 0
local upgrade_shipTurnSpeed = 0
local upgrade_shipVerticalSpeed = 0

local function startCoroutine(func)
    local co = coroutine.create(func)
    table.insert(activeCoroutines, co)
end

local function updateCoroutines(dt)
    for i = #activeCoroutines, 1, -1 do
        local co = activeCoroutines[i]

        if coroutine.status(co) == "dead" then
            table.remove(activeCoroutines, i)
        else
            local ok, waitTime = coroutine.resume(co, dt)
            if not ok then
                error(waitTime)
            end
        end
    end
end

local function getPlayer()
    if (player == nil) then
        for i, ref in ipairs(world.activeActors) do
            if (ref.type == types.Player) then
                return ref
            end
        end
    end
end

local function lerpPlayer(startPos, endPos, duration)
    if lerpPlayerActive then return end
    return function(dt)
        lerpPlayerActive = true
        local t = 0
        while t < duration do
            t = t + (coroutine.yield() or 0)
            local alpha = math.min(t / duration, 1)
            world.players[1]:teleport('',startPos * (1 - alpha) + endPos * alpha)
        end
        
        -- This code keeps the player from shooting across the ship due to "charged up" velocity from holding move keys
        world.players[1]:sendEvent('Ss_PlayerPlayAnimation', { animationName = "idle" })
        coroutine.yield() coroutine.yield() coroutine.yield()
        world.players[1]:sendEvent('Ss_PlayerPlayAnimation', {  })
        
        lerpPlayerActive = false
    end
end

local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(xzLen * math.sin(yaw), xzLen * math.cos(yaw), math.sin(pitch))
end

local function rotToFwd(rotation)
  return anglesToV(rotation:getPitch(), rotation:getYaw())
end

local function getCellNameByPos(position)
    local cellSize = 8192
    local cellX = math.floor(position.x / cellSize)
    local cellY = math.floor(position.y / cellSize)
    return world.getExteriorCell(cellX, cellY).name
end

local function rotateOffset(offset, rot)
    local cosR = math.cos(rot)
    local sinR = math.sin(rot)

    return util.vector3(
        offset.x * cosR - offset.y * sinR,
        offset.x * sinR + offset.y * cosR,
        offset.z
    )
end

local function calculateShipUpgradeStats()
  upgrade_shipSpeed = 0
  upgrade_shipTurnSpeed = 0
  upgrade_shipVerticalSpeed = 0
  for i, info in ipairs(itemsPlacedOnDeck) do
    if (info.obj.type == types.Activator) then   
      local objName = types.Activator.record(info.obj).name
      if string.find(objName,"Skyship Upgrade %- Max Speed ++") ~= nil then upgrade_shipSpeed = upgrade_shipSpeed + 1 end
      if string.find(objName,"Skyship Upgrade %- Turn Speed ++") ~= nil then upgrade_shipTurnSpeed = upgrade_shipTurnSpeed + 1 end
      if string.find(objName,"Skyship Upgrade %- Vertical Speed ++") ~= nil then upgrade_shipVerticalSpeed = upgrade_shipVerticalSpeed + 1 end
    end
  end
end

local function playClimbRopeSound(dt)
  climbRopeSoundTimer = climbRopeSoundTimer - dt
  if climbRopeSoundTimer <= 0 then
    climbRopeSoundTimer = .5
    world.players[1]:sendEvent("Ss_playSound", { sound = "animalSMALLright", volume = .8, pitch = climbRopeSoundPitch })
    if climbRopeSoundPitch == 1 then climbRopeSoundPitch = .7 else climbRopeSoundPitch = 1 end
  end
end

local function createActivatorOnSkyship(name, model, skyshipPos, posOffset, rotOffset, scale, list)
  local draftInfo = { name = name, model = model, }
  local draft = types.Activator.createRecordDraft(draftInfo)
  local record = world.createRecord(draft)
  local newActivator = world.createObject(record.id, 1)
  newActivator:setScale(scale)
  newActivator:teleport('', skyshipPos + posOffset, util.transform.rotateZ(rotOffset))
  if list then table.insert(list, { name = name, obj = newActivator, offset = rotateOffset(posOffset, -skyshipRot), rotOffset = rotOffset }) end
  return newActivator
end

local function createActivatorInWorld(name, model, pos, rotOffset, scale)
  local draftInfo = { name = name, model = model, }
  local draft = types.Activator.createRecordDraft(draftInfo)
  local record = world.createRecord(draft)
  local newActivator = world.createObject(record.id, 1)
  newActivator:setScale(scale)
  newActivator:teleport(world.players[1].cell, pos, util.transform.rotateZ(rotOffset))
  return newActivator
end

local function createMiscInventoryItem(inv, name, value, weight, icon, model, count)
  local itemInfo = { name = name, value = value, weight = weight, icon = icon, model = model }
  local itemDraft = types.Miscellaneous.createRecordDraft(itemInfo)
  local itemRecord = world.createRecord(itemDraft)
  local newItem = world.createObject(itemRecord.id, math.max(1,count))
  newItem:moveInto(inv)
end

local furnitureData = {
  { name = 'Skyship Furniture - Wooden Table', value = 800, weight = 5, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_table_04.nif', count = 8, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Wooden Round Table', value = 800, weight = 5, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_table_03.nif', count = 8, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Wooden Chair', value = 400, weight = 2, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_de_chair_02.nif', count = 8, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Wooden Bench', value = 600, weight = 3, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_bench_02.nif', count = 5, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Wooden Bookshelf', value = 800, weight = 8, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_de_bookshelf_01.nif', count = 8, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Fancy Bookshelf', value = 2400, weight = 10, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_bookshelf_01.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Fancy Winerack', value = 2400, weight = 10, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_winerack.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Fancy Chair', value = 1600, weight = 4, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_chair_01.nif', count = 6, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Fancy Table', value = 1600, weight = 5, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_table_01.nif', count = 6, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Fancy Table Long', value = 2400, weight = 12, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_de_table_07.nif', count = 6, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Item Pedestal', value = 800, weight = 6, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_museum_display_02.nif', count = 16, verticalOffset = -1, scale = 1},
  { name = 'Skyship Furniture - Item Display', value = 1600, weight = 6, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_museum_display_01.nif', count = 16, verticalOffset = -0.5, scale = 1},
  { name = 'Skyship Furniture - Tapestry - Forest', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_tapestry_01.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Tapestry - Floral', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_tapestry_02.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Tapestry - Seal of Akatosh', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_tapestry_04.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Tapestry - Wizard', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_c_t_wizard_01.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Tapestry - Warrior', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_c_t_warrior_01.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Tapestry - Steed', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_c_t_steed_01.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Tapestry - Lover', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_c_t_lover_01.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Skull on Stake', value = 800, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_bone_stake00.nif', count = 16, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Anvil', value = 2400, weight = 16, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_anvil00.nif', count = 2, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Cushion Round', value = 400, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_cushion_round_02.nif', count = 8, verticalOffset = 1, scale = 1},
  { name = 'Skyship Furniture - Cushion Square', value = 400, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_cushion_square_02.nif', count = 8, verticalOffset = 1, scale = 1},
  { name = 'Skyship Furniture - Keg', value = 800, weight = 10, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_de_kegstand.nif', count = 8, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Rug - Blue', value = 800, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_rug_01.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Rug - Red', value = 800, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_rug_02.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Rug - Round', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_rug_big_02.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Rug - Large Blue', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_rug_big_07.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Plant', value = 400, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_pottedplant.nif', count = 24, verticalOffset = 15, scale = 1},
  { name = 'Skyship Furniture - Practice Dummy', value = 800, weight = 3, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_practice_dummy.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Mounted Bearhead', value = 3000, weight = 5, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/m/bearbrownplaque.nif', count = 2, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Mounted Wolfhead', value = 2000, weight = 4, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/m/wolfredplaque.nif', count = 3, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Dwarven Mech Head', value = 5000, weight = 20, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/dwrv_mechhead00.nif', count = 1, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Statue of Azura', value = 8000, weight = 20, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/x/ex_dae_azura.nif', count = 1, verticalOffset = -1, scale = .32},
  { name = 'Skyship Furniture - Statue of Malacath', value = 3500, weight = 20, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/x/ex_dae_malacath_attack.nif', count = 1, verticalOffset = 99.5, scale = .32},
  { name = 'Skyship Furniture - Statue of Mehrunes Dagon', value = 3500, weight = 20, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/x/ex_dae_mehrunesdagon.nif', count = 1, verticalOffset = 134, scale = .32},
  { name = 'Skyship Furniture - Statue of Molagbal', value = 3500, weight = 20, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/x/ex_dae_molagbal.nif', count = 1, verticalOffset = 82.5, scale = .32},
  { name = 'Skyship Furniture - Statue of Boethiah', value = 3500, weight = 20, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/x/ex_dae_boethiah.nif', count = 1, verticalOffset = -1, scale = .24},
  { name = 'Skyship Furniture - Statue of Sheogorath', value = 3500, weight = 20, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/x/ex_dae_sheogorath.nif', count = 1, verticalOffset = -1, scale = .32},
  { name = 'Skyship Furniture - Statue of Dwarven Warrior', value = 3500, weight = 20, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/x/ex_dwrv_statue00.nif', count = 8, verticalOffset = -4.5, scale = .32},
  { name = 'Skyship Furniture - Wooden Carved Bear Figure', value = 800, weight = 3, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/x/ex_S_bear.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Wooden Carved Wolf Figure', value = 800, weight = 3, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/x/ex_S_wolf.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Sixth House Ash Pillar', value = 2400, weight = 12, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_6th_ashpillar.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Sixth House Ash Statue', value = 2400, weight = 12, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_6th_ashstatue.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Sixth House Banner', value = 1200, weight = 3, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_6th_banner.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Sixth House Banner Tall', value = 1200, weight = 3, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_6th_tallbanner.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Wolfskin Rug', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/Furn_colony_wolfrug01.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Bearskin Rug', value = 1200, weight = 1, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_bearskin_rug.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Cauldron', value = 800, weight = 15, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_cauldron_02.nif', count = 4, verticalOffset = 0, scale = 1},
  { name = 'Skyship Furniture - Decorative Shield - Eagle', value = 1000, weight = 3, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_com_coatofarms_01.nif', count = 4, verticalOffset = 0, scale = 2},
  { name = 'Skyship Furniture - Decorative Shield - Lion', value = 1000, weight = 3, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/Furn_Com_Coatofarms_02.nif', count = 4, verticalOffset = 0, scale = 2},
  { name = 'Skyship Furniture - Altar', value = 2000, weight = 20, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_imp_altar_01.nif', count = 4, verticalOffset = -0.5, scale = 1},
  { name = 'Skyship Furniture - Throne', value = 5000, weight = 8, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/f/furn_throne_01.nif', count = 1, verticalOffset = 0.5, scale = 1},
  { name = 'Skyship Furniture - Pile of Skulls', value = 1200, weight = 2, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/i/In_OM_skullpile.nif', count = 8, verticalOffset = 8.5, scale = 1.5},
  { name = 'Skyship Furniture - Giant Crystal', value = 2000, weight = 8, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/i/in_t_crystal_01.nif', count = 16, verticalOffset = -16, scale = .2},
  { name = 'Skyship Furniture - Giant Crystal Wide', value = 2000, weight = 8, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/i/in_t_crystal_02.nif', count = 16, verticalOffset = 73, scale = .4},
  { name = 'Skyship Furniture - Torch', value = 800, weight = 2, icon = 'icons/m/tx_clothbolt_02.tga', model = 'meshes/l/light_tikitorch00.nif', count = 16, verticalOffset = 0, scale = 2},
  --{ name = 'Skyship Furniture - Firepit', value = 800, weight = 2, icon = 'icons/m/tx_clothbolt_02.tga', recordId = "BM_firepit_uni", count = 16, verticalOffset = 0, scale = 2},

  { name = 'Skyship Upgrade - Max Speed ++', value = 15000, weight = 15, icon = 'icons/m/misc_dwrv_ark_cube00.tga', model = 'meshes/x/ex_gnisis_roadmarker_01.nif', count = 5, verticalOffset = 120, scale = .5},
  { name = 'Skyship Upgrade - Turn Speed ++', value = 8000, weight = 15, icon = 'icons/m/misc_dwrv_ark_cube00.tga', model = 'meshes/m/misc_dwrv_artifact00.nif', count = 5, verticalOffset = 21, scale = 3},
  { name = 'Skyship Upgrade - Vertical Speed ++', value = 8000, weight = 15, icon = 'icons/m/misc_dwrv_ark_cube00.tga', model = 'meshes/i/in_m_sewer_drain_01.nif', count = 5, verticalOffset = 0, scale = .2},
}

local function createSkyshipMerchant()
  local merchantTable = world.createObject('furn_com_rm_table_04', 1)
  merchantTable:teleport('', util.vector3(-10720.13, -71381.86, 189.66), util.transform.rotateZ(0))
  skyshipTableModel = createActivatorOnSkyship("Skyship Model","meshes/x/ex_de_ship.nif",util.vector3(0,0,0),util.vector3(-10717.11, -71375.5, 230.76),1.57,.032,nil)

  --local template = types.NPC.record('hannabi zabynatus')
  --local draftInfo = { template = template, name = "Skyship Merchant", servicesOffered = { ["Barter"] = true }, isRespawning = true  }
  --local draft = types.NPC.createRecordDraft(draftInfo)
  --local record = world.createRecord(draft)
  --local newNPC = world.createObject(record.id, 1)
  local newNPC = juliusActor
  newNPC:teleport('',util.vector3(-10718.45, -71465.17, 160.20), util.transform.rotateZ(0))
  skyshipMerchant = newNPC
  newNPC:sendEvent('RemoveAIPackages', 'Wander')
  newNPC:sendEvent('RemoveAIPackages', 'Travel')
  local inv = types.Actor.inventory(newNPC)
  
  -- Create Deed
  --local deedInfo = { id = "ss_skyship_deed", name = "Skyship Deed", value = 25000, weight = 0.1, icon = 'icons/m/tx_scroll_open_03.tga', model = "meshes/m/text_scroll_open_03.nif", text = [[<DIV ALIGN="CENTER"><FONT COLOR="000000" SIZE="5" FACE="Magic Cards"><BR>SKYSHIP DEED<BR><BR>Owner: %PCName<BR><BR>By the Lawful Accord of Vvardenfell, this document serves as a binding covenant of ownership of 1 Skyship. Said Vessel is granted unto the bearer in perpetuity, together with all ropes, rigging, chambers, fittings, and liberties of passage through the open skies above Morrowind and beyond, save where forbidden by law and temple.<BR>Purchased in full by %PCName<BR><BR>]], isScroll = true }
  --local deedDraft = types.Book.createRecordDraft(deedInfo)
  --local deedRecord = world.createRecord(deedDraft)
  --local newDeed = world.createObject(deedRecord.id,1)
  --newDeed:moveInto(inv)
  
  -- Create User Guide
  local guideInfo = { name = "Skyship User Manual", value = 10, weight = 0.1, icon = 'icons/m/tx_folio_01.tga', model = "meshes/m/text_folio_01.nif", text = [[<BR><BR><DIV ALIGN="CENTER"><FONT COLOR="000000" SIZE="5" FACE="Magic Cards"><BR>SKYSHIP USER MANUAL<BR><BR><DIV ALIGN="LEFT">    Welcome to the Skyship User Manual. This manual will guide you towards becoming a traveler of the sky. Many skyward adventures await! <BR><BR><DIV ALIGN="CENTER">MOUNTING<BR><BR><DIV ALIGN="LEFT">    Use the rope on the side of the ship to mount and dismount the skyship. The ropes are only useable when the skyship is stopped. There are other special methods for getting onto your skyship, these methods will be discussed later. <BR><BR><BR><BR><BR><BR><DIV ALIGN="CENTER">FLYING<BR><BR><DIV ALIGN="LEFT">    At the back of the ship, on the raised platform, you will find a dwarven cog. This is where you will control the skyship from. Simply interact with the cog to start and stop controlling the ship. You can walk around on the deck while the ship is still in flight. You can also jump out while the ship is in flight, it will stop automatically. <BR><BR><DIV ALIGN="CENTER">DECORATE<BR><BR><DIV ALIGN="LEFT">    There are many decoration items available, purchasable from the skyship merchant. You can use these to customize the deck and interior of your skyship. To place a furniture item, drag the item out of your inventory and drop it into the world, then you can place it where you please. Feel free to also place and show off any items or treasures found during your adventures, around the deck of the skyship.<BR><BR><DIV ALIGN="CENTER">TIPS AND TRICKS<BR><BR><DIV ALIGN="LEFT">- If you set your 'Mark' spell inside the cabin of the skyship, you can 'Recall' back to you skyship from anywhere. Make sure to set the mark inside the cabin, it does not work on the deck.<BR><BR>- When you are above deep enough water, you can simply jump overboard and take a dive. Its faster than using the rope.<BR><BR>- Make a 'Slowfall' spell to negate fall damage and allow yourself to jump overboard anywhere<BR><BR>- Make a strong 'Jump' spell to leap onto your skyship from the ground below<BR><BR>- A 'Levitate' spell can be helpful to reach the rope when it is in a slightly hard to reach place. (like on top of a tall building or on the side of a steep mountain.)<BR><BR>]], isScroll = false }
  local guideDraft = types.Book.createRecordDraft(guideInfo)
  local guideRecord = world.createRecord(guideDraft)
  local newGuide = world.createObject(guideRecord.id,1)
  newGuide:moveInto(inv)
  
  for k,v in pairs(furnitureData) do
    createMiscInventoryItem(inv,v.name,v.value,v.weight,v.icon,v.model, v.count)
  end
end

local function spawnSkyship(pos)
  local spawnPos = pos + util.vector3(0,0,1000)
  local draftInfo = { name = "", model = "meshes/x/ex_de_ship.nif", }
  local draft = types.Activator.createRecordDraft(draftInfo)
  local record = world.createRecord(draft)
  skyship = world.createObject(record.id, 1)
  --skyship = world.createObject('Ex_DE_ship', 1)
  skyship:teleport('',spawnPos)

  createActivatorOnSkyship("Skyship Furniture - Wooden Table", "meshes/f/furn_com_table_04.nif", spawnPos, util.vector3(174, 380, 240.96), 1.4708, 1, nil)
  createActivatorOnSkyship("Skyship Furniture - Wooden Table", "meshes/f/furn_com_table_04.nif", spawnPos, util.vector3(184, 210, 240.96), 1.5308, 1, nil)
  createActivatorOnSkyship("Skyship Upper Level", "meshes/d/ex_de_ship_trapdoor.nif", spawnPos, util.vector3(30.238,-441.718, 255.654), 0, 1, skyshipActivators)
  createActivatorOnSkyship("Skyship Cabin", "meshes/d/ex_de_ship_door.nif", spawnPos, util.vector3(-92.11,619.266, 262.616), 0, 1, skyshipActivators)
  createActivatorOnSkyship("Fly Skyship", "meshes/i/in_dwrv_scope20.nif", spawnPos, util.vector3(-40.11,700.266, 400.616), 0, .32, skyshipActivators)
  createActivatorOnSkyship("Use Rope", "meshes/f/furn_de_signpost_02.nif", spawnPos, util.vector3(260.78, -220.98, 210.01), 0, 1, skyshipActivators)
  for i = 1,64 do
    ropes[i] = createActivatorOnSkyship("Use Rope", "meshes/f/furn_de_rope_07.nif", spawnPos, util.vector3(310.78, -220.98, 245.01 - (i-1) * 190), 0, 1, nil)
  end
  delayUpdateTimer = 5
end

local function placeFurniture()
  local player = world.players[1]
  if input_run then placingObjectRot = placingObjectRot + .01 end
  world.players[1]:sendEvent("Ss_RaycastCameraForward",{ ignoreList = {world.players[1], placingObject} }) 
  local vertOffset = placingObject:getBoundingBox().halfSize.z
  --vertOffset = placingObjectTestVOffset
  for k,v in pairs(furnitureData) do
    if v.name == types.Miscellaneous.record(placingObject).name and v.verticalOffset ~= 0 then vertOffset = v.verticalOffset end
  end
  placingObject:teleport(player.cell, raycastFoundSurfacePos + util.vector3(0,0,vertOffset), util.transform.rotateZ(placingObjectRot))
  if input_use then
    local data = nil
    for k,v in pairs(furnitureData) do
      if v.name == types.Miscellaneous.record(placingObject).name then
        data = v
        if placingItemStackCount > 1 then
          createMiscInventoryItem(types.Actor.inventory(player),v.name,v.value,v.weight,v.icon,v.model, placingItemStackCount-1)
        end
        break
      end
    end
    local record = types.Miscellaneous.record(placingObject)
    if skyship and (player.position - skyship.position):length() < 1250 then
      createActivatorOnSkyship(record.name,record.model,skyship.position,raycastFoundSurfacePos + util.vector3(0,0,vertOffset) - skyship.position,placingObject.rotation:getYaw(),data.scale,nil)
    else
      createActivatorInWorld(record.name,record.model,raycastFoundSurfacePos + util.vector3(0,0,vertOffset),placingObject.rotation:getYaw(),data.scale)
    end
    table.insert(objectToDestroy,1,placingObject) 
    placingObject = nil
  end
end

local function updateRopes() 
  for i, obj in ipairs(ropes) do
      local enabled = skyshipSpeed == 0
      if playerIsFlying then enabled = false end
      if enabled then obj:teleport('', skyship.position + rotateOffset(util.vector3(310.78, -220.98, 245.01 - (i-1) * 190), skyshipRot)) 
      else obj.enabled = false end
  end
end

local function onUpdate(dt)

  updateCoroutines(dt)
  
  deltaTime = dt
  
  if (loadedGameSetupTimer > 0) then
    loadedGameSetupTimer = loadedGameSetupTimer - 1
    if loadedGameSetupTimer == 0 then
      updateRopes()
    end
  end
  
  if skyship then
    world.players[1]:sendEvent("Ss_SetSkyshipInfo",{ playerIsFlying = playerIsFlying, skyshipSpeed = skyshipSpeed, playerIsPlacingItem = placingObject ~= nil })
  end
  
  if (delayUpdateTimer > 0) then
    delayUpdateTimer = delayUpdateTimer - 1
    return
  end

  if (#objectToDestroy > 0) then
    for k, v in pairs(objectToDestroy) do
      v:remove()
    end
    objectToDestroy = {}
  end

  local player = world.players[1]
  
  if skyshipMerchant == nil then
    if player.cell.name == "Seyda Neen" and juliusActor ~= nil then
      createSkyshipMerchant()
    end
  else
    if types.Actor.canMove(skyshipMerchant) then 
      skyshipMerchant:teleport('', util.vector3(-10718.45, -71465.17, 160.20), util.transform.rotateZ(0)) 
    end
  end
  
  --if input_run then placingObjectTestVOffset = placingObjectTestVOffset + .5 print(placingObjectTestVOffset) end
  --if input_activate then placingObjectTestVOffset = placingObjectTestVOffset - .5 print(placingObjectTestVOffset) end
  
  -- Place Furniture
  if placingObject then
    placeFurniture()
  end
  
  local playerInsideSkyship = false
  if player.cell.name == 'Arrow, Upper Level' or player.cell.name == 'Arrow, Lower Level' or player.cell.name == 'Arrow, Cabin' then
    playerInsideSkyship = true
  end

  globals.lua_moveplayer = 1
  if playerInsideSkyship or not skyship then
    globals.lua_moveplayer = 0
    return
  end
  local dist = (player.position - skyship.position):length()
  if not playerIsFlying then
    if dist > 1250 or skyshipSpeed == 0 then 
      globals.lua_moveplayer = 0 
      if skyshipSpeed > 0 then 
        skyshipSpeed = 0 
        updateRopes()
      end
    end
  end

  local skyshipDir = rotToFwd(skyship.rotation)
  local moveVertical = 0
  local lowestHeight = core.land.getHeightAt(skyship.position, skyship.cell) + 2500
  
  local deltaMult = 1
  if dt > .015 then 
    lowFpsCheckerCounter = lowFpsCheckerCounter + 1
    if lowFpsCheckerCounter > 30 then deltaMult = dt * 80 end
  else
    lowFpsCheckerCounter = 0
  end
  if setting_lowFpsMode then deltaMult = dt * 80 end

  -- Skyship Flight Controls
  if playerIsFlying then
    if input_moveL == 1 then skyshipRotTarget = skyshipRotTarget + .0015 * deltaMult + .00075 * upgrade_shipTurnSpeed * deltaMult end
    if input_moveR == 1 then skyshipRotTarget = skyshipRotTarget - .0015 * deltaMult - .00075 * upgrade_shipTurnSpeed * deltaMult end

    if (input_moveFwd == 1) then skyshipSpeed = math.min(skyshipSpeed + .01 * deltaMult, 8 + upgrade_shipSpeed * 3)
    elseif (input_moveBack == 1) then skyshipSpeed = math.max(skyshipSpeed - .015 * deltaMult - (.005 * upgrade_shipSpeed), 0) end
    
    skyshipRot = skyshipRot + ((skyshipRotTarget - skyshipRot + math.pi) % (2*math.pi) - math.pi) * dt * (1 + .5 * upgrade_shipTurnSpeed) 

    if input_jump and skyship.position.z < 10000 then moveVertical = 2 * deltaMult + (1 * upgrade_shipVerticalSpeed) * deltaMult end
    if input_run and skyship.position.z > lowestHeight then moveVertical = -2 * deltaMult - (1 * upgrade_shipVerticalSpeed) * deltaMult end
  end
  
  if skyship.position.z < lowestHeight and skyshipSpeed > 0 then moveVertical = 5 * deltaMult end

  -- Update Player Position (if player is not flying, but on deck)
  if dt > 0  and not playerIsFlying and dist < 1250 then
    local playerOffsetPos = skyshipDir * -skyshipSpeed * deltaMult + util.vector3(0,0,moveVertical)
    globals.lua_x = player.position.x + playerOffsetPos.x
    globals.lua_y = player.position.y + playerOffsetPos.y
    globals.lua_z = player.position.z + playerOffsetPos.z
  end

  -- Update Skyship And Player Position (if player is flying)
  if dt > 0 and player.cell.isExterior then 
    skyship:teleport('', skyship.position + skyshipDir * -skyshipSpeed * deltaMult + util.vector3(0,0,moveVertical), util.transform.rotateZ(-skyshipRot)) 
    if playerIsFlying then 
      local playerPos = skyship.position + rotateOffset(util.vector3(36.579, 676.046, 360.6743) + util.vector3(0,0,moveVertical), skyshipRot)
      globals.lua_x = playerPos.x
      globals.lua_y = playerPos.y
      globals.lua_z = playerPos.z
    end
  end
  
  -- Update / Position placed objects on ship
  if skyshipSpeed > 0 or playerIsFlying then
    for i, info in ipairs(itemsPlacedOnDeck) do
      if info.obj ~= placingObject and info.obj.parentContainer == nil and info.obj.count > 0 then 
        info.obj:teleport('', skyship.position + rotateOffset(info.offset + util.vector3(0,0,moveVertical), skyshipRot), util.transform.rotateZ(-skyshipRot + info.rotOffset)) 
      end
    end
    for i, info in ipairs(skyshipActivators) do
      local spinDir = 1 if info.name == "Fly Skyship" then spinDir = -1 end
      info.obj:teleport('', skyship.position + rotateOffset(info.offset + util.vector3(0,0,moveVertical), skyshipRot), util.transform.rotateZ(-skyshipRot * spinDir + info.rotOffset)) 
    end
  end

  -- Climbing UP Rope
  if (state == "climbingRope" and dt > 0) then
    if player.position.z < skyship.position.z + 200 then
      playClimbRopeSound(dt)
      local ropeOffset = skyship.position + rotateOffset(util.vector3(358.16, -179.15, 0), skyshipRot)
      player:teleport('', util.vector3(ropeOffset.x, ropeOffset.y, player.position.z + 2 * deltaMult))
    else 
      state = "none"
      startCoroutine(lerpPlayer(player.position, skyship.position + rotateOffset(util.vector3(181.81, -156.5, 209.87), skyshipRot), 1.0))
    end
  end
  
  -- Climbing DOWN Rope
  if (state == "descendingRope" and not lerpPlayerActive and dt > 0) then
    if player.position.z > math.max(0, raycastFoundSurfacePos.z) then
      playClimbRopeSound(dt)
      local ropeOffset = skyship.position + rotateOffset(util.vector3(358.16, -179.15, 0), skyshipRot)
      player:teleport('', util.vector3(ropeOffset.x, ropeOffset.y, player.position.z - 4 * deltaMult))
    else 
      state = "none"
    end
  end

end

local function reducePlayersGold(data) 
   local gold = types.Actor.inventory(world.players[1]):find('gold_001')
   if gold then gold:remove(data.amount) end
end

local function setPlayerInputs(data) 
  camForward = data.camForward
  input_moveFwd = data.moveFwd
  input_moveBack = data.moveBack
  input_moveL = data.moveL
  input_moveR = data.moveR
  input_jump = data.jump
  input_run = data.run
  input_activate = data.activate
  input_use = data.use
end

local function setRaycastFoundSurface(data) 
  raycastFoundSurfacePos = data.hitPos
end

local function printPlayerBoatDifferenceVector(data)
  if not skyship then return end
  print(world.players[1].position - skyship.position)
end

local function buySkyship() 
  if (skyship == nil) then spawnSkyship(util.vector3(-13170.3974609375, -73131.453125, -7.65673828125)) end
end

local function pickUpFurniture(data) 
  if skyshipSpeed > 0 then
    world.players[1]:sendEvent("Ss_showMessage", {message="Stop the skyship before picking up furniture"})
    return
  end
  local objName = types.Activator.record(data.object).name
  local inv = types.Actor.inventory(world.players[1])
  for k,v in pairs(furnitureData) do
    if v.name == objName then
      createMiscInventoryItem(inv,v.name,v.value,v.weight,v.icon,v.model, 1)
      break
    end
  end
  data.object:remove()
end

local function ss_updateUserSettings(data)
  setting_showFlyControlsPrompt = data.showFlyControlsPrompt
  setting_lowFpsMode = data.lowFpsMode
end

local function loadData(saveData) 
  saveData = saveData or {}

  if saveData.skyship then skyship = saveData.skyship end
  if saveData.skyshipActivators then 
    skyshipActivators = saveData.skyshipActivators
    for k,v in pairs(skyshipActivators) do if (v.name == "Fly Skyship") then v.obj:setScale(.32) end end
  end
  if saveData.ropes then ropes = saveData.ropes end
  if saveData.skyshipRot then 
    skyshipRot = saveData.skyshipRot  
    skyshipRotTarget = skyshipRot
  end
  if saveData.skyshipMerchant then skyshipMerchant = saveData.skyshipMerchant end
  if saveData.skyshipTableModel then 
    skyshipTableModel = saveData.skyshipTableModel 
    skyshipTableModel:setScale(.032)
  end
  if saveData.playerIsFlying and saveData.playerIsFlying == true then
    globals.lua_ss_stopdriving = 1
  end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit = function(initData)
          
        end,
        onSave = function() 
          -- SAVE DATA
          return { modVersion = modVersion, skyship = skyship, skyshipActivators = skyshipActivators, ropes = ropes, skyshipRot = skyshipRot, skyshipMerchant = skyshipMerchant, skyshipTableModel = skyshipTableModel, playerIsFlying = playerIsFlying }
        end,
        onLoad = function(saveData)
          -- LOAD SAVED DATA
          local v, message = pcall(loadData, saveData) 
          if message ~= nil then print(message) end
          
          world.players[1]:sendEvent('Ss_PlayerPlayAnimation', {  })
          loadedGameSetupTimer = 32
          delayUpdateTimer = 28
        end,
        onActorActive = function (actor) 
          if actor.recordId == "julius teodor" then
            juliusActor = actor
          end
        end,
        onActivate = function(object, actor) 
        
          if placingObject == object then
            placingObject = nil
          end
          
          -- Check if you picked up an item you placed on deck, if so, remove it from list
          if object.type ~= types.Activator then
            for i=#itemsPlacedOnDeck,1,-1 do
               if itemsPlacedOnDeck[i].obj == object then
                   table.remove(itemsPlacedOnDeck, i)
                   break
               end
            end
          end
          
          if (object.type == types.Door) then
          
            -- Exit Skyship Upper Level
            if (world.players[1].cell.name == 'Arrow, Upper Level' and object.recordId == "ex_de_ship_trapdoor") then
              skyship:teleport('', skyship.position, util.transform.rotateZ(-skyshipRot)) 
              world.players[1]:teleport('',skyship.position - rotateOffset(util.vector3(-27.238,442.718, -255.654), skyshipRot), util.transform.rotateZ(-skyshipRot))
            end
            
            -- Exit Skyship Cabin
            if (world.players[1].cell.name == 'Arrow, Cabin' and object.recordId == "in_de_ship_cabindoor") then
              skyship:teleport('', skyship.position, util.transform.rotateZ(-skyshipRot)) 
              world.players[1]:teleport('',skyship.position + rotateOffset(util.vector3(-91.11,550.266, 242.616), skyshipRot), util.transform.rotateZ(-skyshipRot + 3.14159))
            end
            
          end
          
          if (object.type == types.Activator) then
          
            local objName = types.Activator.record(object).name
          
            -- Fly the Skyship
            if objName == 'Fly Skyship' then           
              playerIsFlying = not playerIsFlying
              if not playerIsFlying then
                world.players[1]:sendEvent('Ss_PlayerPlayAnimation', {  })
                skyshipRotTarget = skyshipRot
                if skyshipSpeed <= 1 then skyshipSpeed = 0 end
                globals.lua_ss_stopdriving = 1
              end
              if playerIsFlying then
                globals.lua_ss_startdriving = 1
                if (setting_showFlyControlsPrompt) then
                  world.players[1]:sendEvent('Ss_showTextPrompt', { timer = 30, text = " \n'Forward' to Accelerate\n'Backward' to Slow Down / Stop\n'Left' and 'Right' to Turn\nHold 'Jump' to Ascend (Default: E)\nHold 'Run' to Descend (Default: Shift)\n\nActivate the gear again to stop steering\nYou can walk around on deck while the ship is in flight\n  You must come to a complete stop to deploy the climbing rope  \n" })
                end
                world.players[1]:sendEvent('Ss_PlayerPlayAnimation', { animationName = "idle" })
                
                 -- Check for removed 'placed on deck' items
                 for i=#itemsPlacedOnDeck,1,-1 do
                     if itemsPlacedOnDeck[i].obj.parentContainer ~= nil or itemsPlacedOnDeck[i].obj.count == 0 then
                         table.remove(itemsPlacedOnDeck, i)
                     end
                 end
                 calculateShipUpgradeStats()
              end
              updateRopes()
            end
            
            -- Use the Rope
            if objName == 'Use Rope' and skyshipSpeed == 0 then
              if world.players[1].position.z - skyship.position.z < 205 then state = "climbingRope"
              else 
                state = "descendingRope" 
                local ropeOffset = skyship.position + rotateOffset(util.vector3(358.16, -179.15, 0), skyshipRot)
                world.players[1]:sendEvent('Ss_RaycastToFindSurface', { 
                  from = ropeOffset,
                  to = util.vector3(ropeOffset.x,ropeOffset.y,ropeOffset.z - 11000) 
                })
                startCoroutine(lerpPlayer(world.players[1].position, skyship.position + rotateOffset(util.vector3(358.16, -179.15, 209.87), skyshipRot), 1.0))
              end
            end
            
            -- Enter the Skyship Cabin
            if objName == 'Skyship Cabin' then
              world.players[1]:sendEvent("Ss_playSound", { sound = "Door Creaky Open", volume = 1 })
              globals.lua_moveplayer = 0
              delayUpdateTimer = 60
              world.players[1]:teleport('Arrow, Cabin',util.vector3(-125, -264, -137), util.transform.rotateZ(0))
            end
            
            -- Enter the Skyship Upper Level
            if objName == 'Skyship Upper Level' then
              world.players[1]:sendEvent("Ss_playSound", { sound = "Door Metal Open", volume = 1 })
              globals.lua_moveplayer = 0
              delayUpdateTimer = 60
              world.players[1]:teleport('Arrow, Upper Level',util.vector3(57, -141, -69), util.transform.rotateZ(0))
            end
            
            -- Pick Up Furniture
            if (string.find(objName,"Skyship Furniture - ") or string.find(objName,"Skyship Upgrade - ")) ~= nil then
              world.players[1]:sendEvent("Ss_showMessage", {message="Press 'p' to pick up Furniture/Upgrades"})
            end
            
          end
        end,
        onObjectActive = function(object)

          -- Hide 'Arrow' ship since its interiors are used for the mod
          if (object.id == '0x104c6eb' or object.id == '0x10491cb' or object.id == '0x104c6ed' or object.id == '0x104c6ee') then
            object.enabled = false
          end
          
          -- Start to Place a furniture item
          if object.type == types.Miscellaneous then 
            local itemName = types.Miscellaneous.record(object).name
            if (string.find(itemName,"Skyship Furniture - ") or string.find(itemName,"Skyship Upgrade - ")) ~= nil then
              world.players[1]:sendEvent("Ss_CloseInventory",{ })  
              placingObject = object
              placingObjectRot = 0
              placingItemStackCount = object.count
              delayUpdateTimer = 5
              world.players[1]:sendEvent('Ss_showTextPrompt', { timer = 60, text = "\nPress 'Use' to place object (Default: LMB)\nHold 'Run' to rotate object (Default: Shift)\n  Press 'Activate' on item to cancel (Default: Space)  \nAfter placement, press 'p' on object to pick it up\n" })
              for k,v in pairs(furnitureData) do
                if v.name == itemName and v.scale ~= 1 then placingObject:setScale(v.scale) return end
              end
              return
            end
          end
        
          -- Add Placed Item on ship to the 'itemsPlacedOnDeck' list so they move/rotate correctly
          if skyship and object.position.z > skyship.position.z and (object.position - skyship.position):length() < 1200 and object ~= placingObject then
            if object.type == types.Activator then
              local itemName = types.Activator.record(object).name
              if (string.find(itemName,"Skyship Furniture - ") or string.find(itemName,"Skyship Upgrade - ")) == nil then return end
              for k,v in pairs(furnitureData) do
                if v.name == itemName and v.scale ~= 1 then object:setScale(v.scale) end
              end
            end
            for i, info in ipairs(itemsPlacedOnDeck) do
                if info.obj == object then 
                  info.offset = rotateOffset(object.position - skyship.position, -skyshipRot)
                  info.rotOffset = object.rotation:getYaw() - skyship.rotation:getYaw()
                  return
                end
            end
            local itemInfo = { obj = object, offset = rotateOffset(object.position - skyship.position, -skyshipRot), rotOffset = object.rotation:getYaw() - skyship.rotation:getYaw() }
            table.insert(itemsPlacedOnDeck,itemInfo)
          end
          
        end,
    },
    eventHandlers = { 
      Ss_updateUserSettings = ss_updateUserSettings,
      Ss_BuySkyship = buySkyship,
      Ss_ReducePlayersGold = reducePlayersGold,
      Ss_SetPlayerInputs = setPlayerInputs,
      Ss_SetRaycastFoundSurface = setRaycastFoundSurface,
      Ss_PrintPlayerBoatDifferenceVector = printPlayerBoatDifferenceVector,
      Ss_PickUpFurniture = pickUpFurniture,
    }
}


-- EXAMPLE FOR SAVING / LOADING FROM S3c:tor
--[[
local ShipComponents = {}

return {
  engineHandlers = {
    onSave = function()
      local ObjectsAsKeys = {}

      -- Shenanigans to make these objects refer to the correct thing even if load order changes
      for _, object in pairs ShipComponents do ObjectsAsKeys[object] = true end

      return { ShipComponents = ShipComponents, }
    end,
    onLoad = function(saveData)
      saveData = saveData or {}
      if saveData.ShipComponents then
          for object in pairs(saveData.shipComponents) do ShipComponents[object.id] = object end
      end
    end,
  },
}]]