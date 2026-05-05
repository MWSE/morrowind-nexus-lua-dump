--[[
ErnDebt for OpenMW.
Copyright (C) Erin Pentecost 2026

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local types        = require('openmw.types')
local aux_util     = require('openmw_aux.util')
local world        = require("openmw.world")
local MOD_NAME     = require("scripts.ErnDebt.ns")
local SLOT         = types.Actor.EQUIPMENT_SLOT

-- https://en.uesp.net/wiki/Tamriel_Data:Armor
--https://en.uesp.net/wiki/Tamriel_Data:Clothing

local commonPants  = { "common_pants_01", "common_pants_02", "common_pants_03", "common_pants_04", "common_pants_05",
    "T_Com_Cm_Pants_01",
    "T_Com_Cm_Pants_02",
    "T_Com_Cm_Pants_03",
    "T_Com_Cm_Pants_04" }
local commonShirts = { "common_shirt_01", "common_shirt_02", "common_shirt_03", "common_shirt_04", "common_shirt_05",
    "T_Com_Cm_Shirt_03", "T_Com_Cm_Shirt_04" }
local cheapExtras  = { "Potion_Local_Brew_01", "p_restore_health_b", "p_fortify_fatigue_s", "p_fortify_health_s",
    "potion_comberry_wine_01", "p_magicka_resistance_b", "p_lightning shield_s", "p_fire_shield_s", "p_frost_shield_s",
    "potion_skooma_01" }

-- a random package is chosen, provided it meets the requirements.
-- at least one element in each primitive list must be in the base game.
local gearPackages = {
    {
        name = "1h grunt",
        level = 1,
        equipment = {
            [SLOT.Helmet] = { "bonemold_helm" },
            [SLOT.Cuirass] = {
                "netch_leather_boiled_cuirass",
                "T_De_Netch_Cuirass_01",
                "T_De_Netch_Cuirass_02",
                "T_De_Netch_Cuirass_03" },
            [SLOT.CarriedRight] = { "chitin club", "chitin war axe", "chitin dagger", "iron saber", "T_Com_Farm_Hatchet_01" },
            [SLOT.CarriedLeft] = { "chitin_shield", "netch_leather_shield" },
            [SLOT.Shirt] = commonShirts,
            [SLOT.Pants] = commonPants,
            [SLOT.LeftGauntlet] = { "common_glove_left_01" },
            [SLOT.RightGauntlet] = { "common_glove_right_01" },
            [SLOT.Boots] = {
                "netch_leather_boots",
                "T_Imp_Cm_BootsCol_01",
                "T_Imp_Cm_BootsCol_02",
                "T_Imp_Cm_BootsCol_03",
                "T_Imp_Cm_BootsCol_04" },
        },
        extra = cheapExtras,
        spells = { { "noise", "hearth heal" }, { "restore strength", "stamina" }, {} },
    },
    {
        name = "2h grunt",
        level = 1,
        equipment = {
            [SLOT.LeftPauldron] = { "T_De_Chitin_PauldrL_01", "chitin pauldron - left" },
            [SLOT.RightPauldron] = { "T_De_Chitin_PauldrR_01", "chitin pauldron - right" },
            [SLOT.Helmet] = { "chitin_mask_helm", "T_Com_Iron_Helm_01" },
            [SLOT.Cuirass] = { "nordic_ringmail_cuirass" },
            [SLOT.Greaves] = { "netch_leather_greaves", "T_Imp_StuddedLeather_Greaves_01" },
            [SLOT.CarriedRight] = { "iron battle axe", "iron warhammer", "iron claymore", "iron halberd", "T_Com_Iron_Longhammer_01", "T_Com_Iron_Daikatana_01" },
            [SLOT.Shirt] = commonShirts,
            [SLOT.Pants] = commonPants,
            [SLOT.LeftGauntlet] = { "iron_gauntlet_left" },
            [SLOT.RightGauntlet] = { "iron_gauntlet_right" },
            [SLOT.Boots] = { "chitin boots", "T_De_Guarskin_Boots_01" },
        },
        extra = cheapExtras,
        spells = { { "wearying touch", "weakness" }, {} },
    },
    {
        name = "ranged grunt",
        level = 1,
        equipment = {
            [SLOT.Helmet] = { "netch_leather_boiled_helm" },
            [SLOT.Cuirass] = { "netch_leather_cuirass", "T_De_NetchRogue_Cuirass_01", },
            [SLOT.CarriedRight] = { "chitin short bow" },
            [SLOT.Ammunition] = { "chitin arrow" },
            [SLOT.Shirt] = commonShirts,
            [SLOT.Pants] = commonPants,
            [SLOT.LeftGauntlet] = { "common_glove_left_01" },
            [SLOT.RightGauntlet] = { "T_Nor_Leather1_BarcerR_01", "right leather bracer", "cloth bracer right" },
            [SLOT.Boots] = {
                "netch_leather_boots",
                "chitin boots" },
        },
        extra = cheapExtras,
        spells = { { "bound dagger", "summon scamp" }, { "shockball", "flamebolt", "frost bolt" } },
    },
    {
        name = "1h grunt - mid",
        level = 5,
        equipment = {
            [SLOT.Helmet] = { "nordic_iron_helm", "T_Com_Steel_Helm_01" },
            [SLOT.Cuirass] = {
                "nordic_iron_cuirass", "T_Imp_ColIron_Cuirass_01", "T_Imp_ColSteel_Cuirass_01" },
            [SLOT.LeftPauldron] = { "imperial left pauldron" },
            [SLOT.RightPauldron] = { "imperial right pauldron" },
            [SLOT.CarriedRight] = { "steel war axe", "dwarven mace", "dwarven shortsword", "steel katana", "fiend katana", "silver sparksword" },
            [SLOT.CarriedLeft] = { "steel_towershield", "steel_shield" },
            [SLOT.Shirt] = commonShirts,
            [SLOT.Pants] = commonPants,
            [SLOT.Greaves] = { "steel_greaves", "T_Imp_ColLamellar_Greaves_01", "T_Imp_ColSteel_Greaves_01", "T_Nor_Iron_Greaves_01" },
            [SLOT.LeftGauntlet] = { "steel_gauntlet_left" },
            [SLOT.RightGauntlet] = { "steel_gauntlet_right" },
            [SLOT.Boots] = { "steel_boots", "T_Imp_ColLamellar_Boots_01", "T_Imp_ColSteel1_Boots_01" },
        },
        extra = cheapExtras,
        spells = { { "second barrier", "stamina" }, { "water walking", "crushing burden" }, { "disintegrate weapon", "Feather" } },
    },
    {
        name = "1h grunt - seasoned",
        level = 7,
        equipment = {
            [SLOT.Helmet] = { "orcish_helm", "bonemold_helm", "T_De_Bonemold_Helm_02" },
            [SLOT.Cuirass] = { "bonemold_cuirass", "T_De_Bonemold_Cuirass_03" },
            [SLOT.LeftPauldron] = { "bonemold_pauldron_l" },
            [SLOT.RightPauldron] = { "bonemold_pauldron_r" },
            [SLOT.CarriedRight] = { "dwarven shortsword", "steel longsword", "T_De_Bonemold_Sword_01", "fiend tanto" },
            [SLOT.CarriedLeft] = { "bonemold_shield", "steel_shield", "veloths_tower_shield" },
            [SLOT.Greaves] = { "bonemold_greaves" },
            [SLOT.Boots] = { "bonemold_boots" },
            [SLOT.LeftGauntlet] = { "bonemold_bracer_left" },
            [SLOT.RightGauntlet] = { "bonemold_bracer_right" },
        },
        extra = cheapExtras,
        spells = {
            { "firebite",   "frostbite", "noise" },
            { "minor heal", "shield",    "summon scamp" },
        },
    },
    {
        name = "ranged grunt - seasoned",
        level = 8,
        equipment = {
            [SLOT.Helmet] = { "chitin helm", "mole_crab_helm" },
            [SLOT.Cuirass] = { "netch_leather_cuirass" },
            [SLOT.CarriedRight] = { "bonemold long bow" },
            [SLOT.Ammunition] = { "cruel flamearrow", "cruel frostarrow", "cruel sparkarrow", "cruel viperarrow" },
            [SLOT.Boots] = { "netch_leather_boots", "chitin boots" },
        },
        extra = cheapExtras,
        spells = {
            { "shockball", "fire bite", "absorb health", "fourth barrier" },
        },
    },
    {
        name = "1h grunt - veteran",
        level = 13,
        equipment = {
            [SLOT.Helmet] = { "orcish_helm" },
            [SLOT.Cuirass] = { "orcish_cuirass" },
            [SLOT.LeftPauldron] = { "orcish_pauldron_left" },
            [SLOT.RightPauldron] = { "orcish_pauldron_right" },
            [SLOT.CarriedRight] = { "glass dagger", "dwarven mace", "cruel sparksword", "cruel shardblade", "steel blade of heaven" },
            [SLOT.CarriedLeft] = { "orcish_shield", "steel_towershield" },
            [SLOT.Greaves] = { "orcish_greaves", "steel_greaves" },
            [SLOT.Boots] = { "orcish_boots" },
        },
        extra = cheapExtras,
        spells = {
            { "disintegrate armor", "paralysis",   "summon greater bonewalker" },
            { "lightning bolt",     "cure poison", "absorb endurance",         "frost barrier" },
            { "flamebolt",          "hearth heal", "absorb intelligence",      "shock barrier" },
        },
    },
    {
        name = "2h grunt - veteran",
        level = 14,
        equipment = {
            [SLOT.Helmet] = { "steel_helm", "fiend helm", "trollbone_helm" },
            [SLOT.Cuirass] = { "orcish_cuirass", "steel_cuirass" },
            [SLOT.CarriedRight] = {
                "orcish claymore",
                "dwarven warhammer",
                "shockbite warhammer",
                "steel claymore of hewing"
            },
            [SLOT.Greaves] = { "orcish_greaves" },
            [SLOT.Boots] = { "orcish_boots", "steel_boots" },
            [SLOT.LeftGauntlet] = { "orcish_bracer_left" },
            [SLOT.RightGauntlet] = { "orcish_bracer_right" },
        },
        extra = cheapExtras,
        spells = {
            { "disintegrate armor", "paralysis",   "summon greater bonewalker" },
            { "lightning bolt",     "cure poison", "absorb endurance",         "frost barrier" },
            { "flamebolt",          "hearth heal", "absorb intelligence",      "shock barrier" },
        },
    },
}

---@generic T: any
---@param collection T[]
---@return T[]
local function shuffle(collection)
    local randList = {}
    for _, item in pairs(collection) do
        -- get random index to insert into. 1 to size+1.
        -- # is a special op that gets size
        local insertAt = math.random(1, 1 + #randList)
        table.insert(randList, insertAt, item)
    end
    return randList
end

local function selectGearPackages(count, pcLevel)
    local out = {}
    local allowed = {}
    for _, package in pairs(gearPackages) do
        if package.level <= pcLevel then
            table.insert(allowed, package)
        end
    end
    allowed = shuffle(allowed)
    for i = 1, count do
        local safeIndex = ((i - 1) % #allowed) + 1
        table.insert(out, allowed[safeIndex])
    end
    return out
end

local function equipmentValidator(recordId)
    return (types.Armor.records[recordId] or types.Clothing.records[recordId] or types.Weapon.records[recordId]) ~= nil
end

local function extrasValidator(recordId)
    return (types.Potion.records[recordId]) ~= nil
end

---@param recordList string[]
---@param validator fun(a : string): boolean
---@return nil
local function selectRecordFromList(recordList, validator)
    if #recordList == 0 then
        return nil
    end
    local idx = math.random(1, #recordList)
    local recordId = recordList[idx]
    if not validator(recordId) then
        table.remove(recordList, idx)
        return selectRecordFromList(recordList, validator)
    end
    return recordId
end

local function gearupNPC(npc, gearTable)
    local inventory = npc.type.inventory(npc)

    local toEquip = {}
    -- now select entries from the table and send to the npc.
    for slot, itemList in pairs(gearTable.equipment) do
        local itemRecordId = selectRecordFromList(itemList, equipmentValidator)
        if itemRecordId then
            local count = slot == SLOT.Ammunition and math.random(20, 30) or 1
            local equipmentObject = world.createObject(itemRecordId, count)
            equipmentObject:moveInto(inventory)
            toEquip[slot] = equipmentObject
        else
            print("nothing for slot" .. tostring(slot))
        end
    end
    print("equip table: " .. aux_util.deepToString(toEquip, 4))
    npc:sendEvent(MOD_NAME .. "onEquip", toEquip)

    -- insert an extra thing
    local itemRecordId = selectRecordFromList(gearTable.extra, extrasValidator)
    if itemRecordId then
        local equipmentObject = world.createObject(itemRecordId)
        equipmentObject:moveInto(inventory)
    end

    -- add spells
    if #gearTable.spells > 0 then
        local spellGroupIdx = math.random(1, #gearTable.spells)
        for _, spellId in pairs(gearTable.spells[spellGroupIdx]) do
            npc.type.spells(npc):add(spellId)
        end
    end
end

local function gearupNPCs(npcs, pcLevel)
    --- Try to ensure NPCs have a variety of different packages.
    local gearTables = selectGearPackages(#npcs, pcLevel)
    for i, npc in ipairs(npcs) do
        gearupNPC(npc, gearTables[i])
    end
end

return {
    gearupNPCs = gearupNPCs,
}
