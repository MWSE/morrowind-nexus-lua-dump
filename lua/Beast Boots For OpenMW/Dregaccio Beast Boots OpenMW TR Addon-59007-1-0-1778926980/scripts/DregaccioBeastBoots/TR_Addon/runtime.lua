-- Dregaccio Beast Boots OpenMW Lua runtime
-- This script swaps normal boot records to beast-compatible clones only at runtime.
local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')

local SCAN_INTERVAL = 0.70
local busy = false
local elapsed = SCAN_INTERVAL

local toBeast = {
    ["t_ayl_saliache_boots_01"] = "dregbb_04e77c66b736328e",
    ["t_com_iron_boots_01"] = "dregbb_fddb62af51242135",
    ["t_com_iron_boots_02"] = "dregbb_3f2646d4746407b1",
    ["t_com_steel_boots_consuming"] = "dregbb_f79ab41ab7948ed4",
    ["t_com_steel_boots_creeping"] = "dregbb_e4a624e4fc7f3bf1",
    ["t_com_steel_boots_glacial"] = "dregbb_043fed95906ba183",
    ["t_com_steel_boots_perfection"] = "dregbb_651fda757a2d8a37",
    ["t_dae_alternate_boots_01"] = "dregbb_9cb792ad0570cc8c",
    ["t_dae_gold_boots_01"] = "dregbb_304739f17954198f",
    ["t_dae_lord_boots_01"] = "dregbb_4d6033acc24050c2",
    ["t_dae_uni_bootsofatronach"] = "dregbb_6f10b5c0bf845784",
    ["t_dae_uni_bootsofpeace_01"] = "dregbb_94d61d204a4b787b",
    ["t_dae_uni_bootssaviorshide"] = "dregbb_81a53d56a391a864",
    ["t_de_alithide_boots_01"] = "dregbb_0034a994ad8ea4a5",
    ["t_de_bonemold_chuzei_boots"] = "dregbb_1d593ddf720547d1",
    ["t_de_bonemold_chuzei_boots_e"] = "dregbb_1f4f99eab7459995",
    ["t_de_bonemold_stone_boots"] = "dregbb_e7e811bdc5f69604",
    ["t_de_bonemold_ulvra_boots"] = "dregbb_ccd20624e8d09fc1",
    ["t_de_bonemold_water_boots"] = "dregbb_edea77b0a4726b90",
    ["t_de_bonemoldkrage_boots_01"] = "dregbb_7ed75f9b58cbbffa",
    ["t_de_bonemoldsacred_boots_01"] = "dregbb_17a3f6f0d1517009",
    ["t_de_canyonwatch_boots_01"] = "dregbb_7a00ef3b993bc87d",
    ["t_de_daedrichide_boots_01"] = "dregbb_99b61977294219f2",
    ["t_de_dresbonemold_boots_01"] = "dregbb_3abcb235a000294a",
    ["t_de_dreugh_boots_01"] = "dregbb_57702c59f04d5523",
    ["t_de_glassgilded_boots_01"] = "dregbb_652649ef97157eae",
    ["t_de_guarskin_boots_01"] = "dregbb_fb15bdd406897ce3",
    ["t_de_hvchit_boots"] = "dregbb_dba6d6b40278bf97",
    ["t_de_indbonemold_boots_01"] = "dregbb_70ad5308de8b6b55",
    ["t_de_indchevaram_boots_01"] = "dregbb_62b1818af7f85a2d",
    ["t_de_kagoutihide_boots_01"] = "dregbb_570642fd98188ac5",
    ["t_de_molecrab_boots_01"] = "dregbb_07dd17943ecf7f4e",
    ["t_de_narsiswatch_boots_01"] = "dregbb_86102ba0ad04e7ec",
    ["t_de_nativeebony_boots_01"] = "dregbb_2578eb6cbf58dd1b",
    ["t_de_necrom_boots_01"] = "dregbb_5a944bed9f467996",
    ["t_de_redoranwatchman_boots"] = "dregbb_71c9600be429a4e7",
    ["t_de_redwatchchitin_boots_01"] = "dregbb_10a01b7b77f05ab9",
    ["t_de_riverwatch_boots_01"] = "dregbb_db230bd6a8e38236",
    ["t_de_shinchitin_boots"] = "dregbb_03c2c3eea3aa5353",
    ["t_de_telvcephalopod_boots_01"] = "dregbb_43751aecd706e9a6",
    ["t_de_thirrbonemold_boots_01"] = "dregbb_615ae37bf069426a",
    ["t_de_uni_pasoroth_boots"] = "dregbb_85823f73af1a4577",
    ["t_dwe_rourken_boots_01"] = "dregbb_cd42b02a2a87d3f8",
    ["t_dwe_scrap_boots"] = "dregbb_2f70ad7218b13a9a",
    ["t_he_altmerglass_boots_01"] = "dregbb_2c29a57cef3bc1fc",
    ["t_he_direnni_boots_01"] = "dregbb_9ab6e25fb1f7660b",
    ["t_imp_alessianbrnz_boots_01"] = "dregbb_b682903997c8f18b",
    ["t_imp_chain_boots_01"] = "dregbb_07294216572fe0e1",
    ["t_imp_cm_bootscol_01"] = "dregbb_3bf5c1baf5b9daba",
    ["t_imp_cm_bootscol_02"] = "dregbb_78adc80d0c4bb3fe",
    ["t_imp_cm_bootscol_03"] = "dregbb_555415a3b03a491f",
    ["t_imp_cm_bootscol_04"] = "dregbb_1916d4974dafe7ca",
    ["t_imp_colgoathide_boots_01"] = "dregbb_004dc42a84849096",
    ["t_imp_coliron1_boots_01"] = "dregbb_b46640f071d72ce8",
    ["t_imp_coliron1_boots_02"] = "dregbb_d1b52c39147893af",
    ["t_imp_coliron1_boots_03"] = "dregbb_b7894b1ef906dc62",
    ["t_imp_coliron1_boots_04"] = "dregbb_c906a220654f91fa",
    ["t_imp_coliron2_boots_01"] = "dregbb_9227162b99d42b5f",
    ["t_imp_coliron_boots_01"] = "dregbb_2fb94bdd12d018b3",
    ["t_imp_collamellar_boots_01"] = "dregbb_ba2446537b7e5769",
    ["t_imp_colleather_boots_01"] = "dregbb_297fda17dee497c2",
    ["t_imp_colleather_boots_02"] = "dregbb_a9ac56408a77fc71",
    ["t_imp_colsteel1_boots_01"] = "dregbb_67eed79de92bfb73",
    ["t_imp_colsteel1_boots_02"] = "dregbb_84f06a66f135f2bc",
    ["t_imp_colsteel1_boots_03"] = "dregbb_5c7b17b80a506594",
    ["t_imp_colsteel1_boots_04"] = "dregbb_adb1e59519cb1ed5",
    ["t_imp_colsteel_boots_01"] = "dregbb_0171709d1e6f3d3c",
    ["t_imp_colsteel_boots_02"] = "dregbb_0ecd528e6c0897fe",
    ["t_imp_colsteel_boots_03"] = "dregbb_e05f53b4b597f608",
    ["t_imp_colsteel_boots_04"] = "dregbb_bc79a8f4cd71a2f7",
    ["t_imp_domina_boots_01"] = "dregbb_6ebd1506dc2317dc",
    ["t_imp_dragonscale_boots_01"] = "dregbb_898bd344d0401529",
    ["t_imp_ebonweave_boots_01"] = "dregbb_4cf667aaf1491e4b",
    ["t_imp_ebony_boots"] = "dregbb_d7e8cb6d48f1745e",
    ["t_imp_gold_boots_02"] = "dregbb_259d371243388c55",
    ["t_imp_guardtown1_boots_01"] = "dregbb_f5b567b92e83991e",
    ["t_imp_guardtown2_boots_01"] = "dregbb_19b4d939ad51b8ee",
    ["t_imp_guardtown3_boots_01"] = "dregbb_a0ab266040518ca7",
    ["t_imp_militia_boots_01"] = "dregbb_b2d237887afec1bd",
    ["t_imp_navyoff_boots_01"] = "dregbb_66bfbca60f7461d9",
    ["t_imp_navystud_boots_01"] = "dregbb_c429d3ac1aa612bc",
    ["t_imp_newtscale_boots_01"] = "dregbb_c0469382454206b1",
    ["t_imp_rddmtmp_boots_01"] = "dregbb_e10cfa7d91d8ce3d",
    ["t_imp_reman_boots_01"] = "dregbb_59303f36571f5f0c",
    ["t_imp_silver_boots_01"] = "dregbb_d8f940f0fdcd87cf",
    ["t_imp_studdedleather_boots_01"] = "dregbb_abae37d2ccc81be7",
    ["t_mao_scale_boots_01"] = "dregbb_4fc8c97f4ebcd78c",
    ["t_nor_bearskin_boots_01"] = "dregbb_420b359556db34aa",
    ["t_nor_guard_boots_01"] = "dregbb_3819c91e11b4acca",
    ["t_nor_guardfalkr_boots_01"] = "dregbb_8237416bc8354172",
    ["t_nor_iron_boots_01"] = "dregbb_3bb06f9c271cdf44",
    ["t_nor_iron_boots_leap"] = "dregbb_5c31caf61441d95c",
    ["t_nor_leather1_boots_01"] = "dregbb_90a3fda7f409043f",
    ["t_nor_rearoy_boots_01"] = "dregbb_069995703bb94d45",
    ["t_nor_ringmail_boots_01"] = "dregbb_49df8bcc6d4536d3",
    ["t_nor_ringmail_boots_02"] = "dregbb_42dfe8119b8d96b7",
    ["t_nor_toadscale_boots_01"] = "dregbb_fef08bcaa1d5585a",
    ["t_nor_toadscale_boots_02"] = "dregbb_11c391f6075abbee",
    ["t_nor_trollbone_boots_01"] = "dregbb_666ef12b986a7a43",
    ["t_nor_uni_predatorsgrace"] = "dregbb_ab435e0ebf869e4b",
    ["t_orc_leather_boots_01"] = "dregbb_9bd90e5b915932f8",
    ["t_qc_shellmold_boots_01"] = "dregbb_9c9811eee1d3ab18",
    ["t_qyc_shellmold_boots_01"] = "dregbb_1c133d4f57d5222a",
    ["t_qyk_manatee_boots_01"] = "dregbb_2a3331e5c6307b94",
    ["t_rea_wormmouth_boots_01"] = "dregbb_8e05f957709ddcea",
    ["t_rga_crownguard1_boots_01"] = "dregbb_1334c49741423db7",
    ["t_rga_iron_boots_01"] = "dregbb_9900ac0a8766fbee",
    ["t_rga_iron_boots_02"] = "dregbb_2853206b31c607ad",
    ["t_rga_ironlamellar_boots_01"] = "dregbb_09911a9172a96b9f",
    ["t_we_wenbone_boots_01"] = "dregbb_f36da940c0f24660",
    ["tr_m1_fwmg_bootsofcapacity"] = "dregbb_e45e7b8179b14f57",
    ["tr_m1_g_boots_jump"] = "dregbb_0ef2f027376eb80e",
    ["tr_m2_a_crabwalker_boots"] = "dregbb_63a3741d98fc41b3",
    ["tr_m2_a_explorer_boots"] = "dregbb_ee043d0aa30435b9",
    ["tr_m3_lightningboots"] = "dregbb_2cd8e330afee32a2",
    ["tr_m3_oe_tg_snowhareboots"] = "dregbb_f84d660d5c675711",
    ["tr_m3_q_at_mg04_boots"] = "dregbb_3827515f2cb2bb05",
    ["tr_m3_q_st_honns_1"] = "dregbb_c8ae0c3440c7e32c",
    ["tr_m3_q_st_honns_2"] = "dregbb_aac943a1f850ac28",
    ["tr_m3_q_st_honns_3"] = "dregbb_07ca041c16387383",
    ["tr_m3_q_st_honns_4"] = "dregbb_6a5790a876611faa",
    ["tr_m3_speaker_boots"] = "dregbb_850171e17b2a50e9",
    ["tr_m4_bal_vunalboots"] = "dregbb_3b55908f10214077",
    ["tr_m4_immetarca_boots"] = "dregbb_727e5c1331b0e86b",
    ["tr_m4_orcish_boots_uni"] = "dregbb_7943fdf0b98f7392",
    ["tr_m4_rr_vcave_4_footpads"] = "dregbb_dc18deb71411cdb4",
    ["tr_m7_dwemerbootsreflexes"] = "dregbb_05de355356bcb5e8",
    ["tr_m7_ns_ralvam_boots"] = "dregbb_9cad0dba58c273fa",
    ["tr_m7_sh01_mine3_jumperboots"] = "dregbb_d2b683011ae5845e",
    ["tr_m7_shinathitombboots"] = "dregbb_9656b817ddee07e6",
    ["tr_m7_springheel"] = "dregbb_84241a4eea6b8f06",
    ["tr_m7_voltandusboots"] = "dregbb_1370baccb5bb9856",
}
local toNormal = {}
for normal, beast in pairs(toBeast) do toNormal[beast] = normal end


local function lower(value)
    if value == nil then return nil end
    return string.lower(tostring(value))
end

local function safe(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function isValidObject(obj)
    return obj ~= nil and safe(function() return obj:isValid() end) == true
end

local function isActor(obj)
    return isValidObject(obj) and types.Actor.objectIsInstance(obj)
end

local function npcRecord(actor)
    if not isActor(actor) or not types.NPC.objectIsInstance(actor) then return nil end
    return safe(types.NPC.record, actor)
end

local function raceRecord(raceId)
    if raceId == nil then return nil end
    local rec = safe(types.NPC.races.record, raceId)
    if rec ~= nil then return rec end
    return safe(types.NPC.races.record, lower(raceId))
end

local function isBeastActor(actor)
    local rec = npcRecord(actor)
    if rec == nil or rec.race == nil then return false end
    local race = raceRecord(rec.race)
    return race ~= nil and race.isBeast == true
end

local function isBootOrShoe(item)
    if not isValidObject(item) then return false end
    if types.Armor.objectIsInstance(item) then
        local rec = safe(types.Armor.record, item)
        return rec ~= nil and rec.type == types.Armor.TYPE.Boots
    end
    if types.Clothing.objectIsInstance(item) then
        local rec = safe(types.Clothing.record, item)
        return rec ~= nil and rec.type == types.Clothing.TYPE.Shoes
    end
    return false
end

local function copyItemState(source, target)
    local sourceData = safe(types.Item.itemData, source)
    local targetData = safe(types.Item.itemData, target)
    if sourceData ~= nil and targetData ~= nil then
        pcall(function() targetData.condition = sourceData.condition end)
        pcall(function() targetData.enchantmentCharge = sourceData.enchantmentCharge end)
        pcall(function() targetData.soul = sourceData.soul end)
    end
    if source.owner ~= nil and target.owner ~= nil then
        pcall(function() target.owner.recordId = source.owner.recordId end)
        pcall(function() target.owner.factionId = source.owner.factionId end)
        pcall(function() target.owner.factionRank = source.owner.factionRank end)
    end
end

local function equippedInBootSlot(actor, item)
    if not isActor(actor) or not isValidObject(item) then return false end
    local okHasEquipped = safe(types.Actor.hasEquipped, actor, item)
    if okHasEquipped == true then return true end
    local equipped = safe(types.Actor.getEquipment, actor, types.Actor.EQUIPMENT_SLOT.Boots)
    return equipped == item
end

local function useItem(actor, item)
    if not isActor(actor) or not isValidObject(item) then return end
    core.sendGlobalEvent('UseItem', { object = item, actor = actor, force = true })
end

local function targetRecordFor(actor, item)
    if not isBootOrShoe(item) then return nil end
    local id = lower(item.recordId)
    if id == nil then return nil end
    if isBeastActor(actor) then
        return toBeast[id]
    else
        return toNormal[id]
    end
end

local function replaceInventoryItem(actor, item, targetRecordId, equipAfter)
    if not isActor(actor) or not isValidObject(item) or targetRecordId == nil then return nil end
    local count = item.count or 1
    if count < 1 then count = 1 end
    local inventory = types.Actor.inventory(actor)
    local replacement = world.createObject(targetRecordId, count)
    copyItemState(item, replacement)
    replacement:moveInto(inventory)
    item:remove(count)
    if equipAfter == true then
        useItem(actor, replacement)
    end
    return replacement
end

local function processItem(actor, item, forceEquip)
    if busy or not isActor(actor) or not isValidObject(item) then return false end
    local target = targetRecordFor(actor, item)
    if target == nil or lower(item.recordId) == lower(target) then return false end
    busy = true
    local shouldEquip = forceEquip == true or equippedInBootSlot(actor, item)
    local ok = pcall(replaceInventoryItem, actor, item, target, shouldEquip)
    busy = false
    return ok
end

local function scanInventory(actor)
    if busy or not isActor(actor) then return end
    local inventory = types.Actor.inventory(actor)
    if inventory == nil then return end
    local armors = safe(function() return inventory:getAll(types.Armor) end) or {}
    for _, item in ipairs(armors) do
        processItem(actor, item, false)
    end
    local clothing = safe(function() return inventory:getAll(types.Clothing) end) or {}
    for _, item in ipairs(clothing) do
        processItem(actor, item, false)
    end
end

local function scanActors()
    if busy then return end
    local seen = {}
    for _, player in ipairs(world.players) do
        if isActor(player) and player.id ~= nil and not seen[player.id] then
            seen[player.id] = true
            scanInventory(player)
        end
    end
    for _, actor in ipairs(world.activeActors) do
        if isActor(actor) and actor.id ~= nil and not seen[actor.id] then
            seen[actor.id] = true
            scanInventory(actor)
        end
    end
end

local function itemUsageHandler(item, actor)
    if busy or not isActor(actor) or not isValidObject(item) then return nil end
    local target = targetRecordFor(actor, item)
    if target == nil or lower(item.recordId) == lower(target) then return nil end
    processItem(actor, item, true)
    return false
end

I.ItemUsage.addHandlerForType(types.Armor, itemUsageHandler)
I.ItemUsage.addHandlerForType(types.Clothing, itemUsageHandler)

return {
    engineHandlers = {
        onUpdate = function(dt)
            elapsed = elapsed + dt
            if elapsed >= SCAN_INTERVAL then
                elapsed = 0
                scanActors()
            end
        end,
    },
    eventHandlers = {
        DregaccioBeastBootsScan = function()
            scanActors()
        end,
    },
}
