local core = require('openmw.core')

if core.API_REVISION < 39 then
    error('This mod requires OpenMW 0.49.0 or newer, please update.')
end

local Activation = require('openmw.interfaces').Activation
local types = require('openmw.types')
local world = require('openmw.world')

local ids = require("scripts.abandoned-flat-containers.ids")

local function Container(cell, containerId)
    for _, c in pairs(world.getCellByName(cell):getAll(types.Container)) do
        if c.recordId == containerId then return c end
    end
end

local function makeHandler(activator, objtype, cell, container, str)
    return function(obj, actor)
        local moved

        if obj.recordId == activator then
            local c = Container(cell, container)
            for _, thing in pairs(types.Player.inventory(actor):getAll(objtype)) do
                if c then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end

        if moved then actor:sendEvent(ids.e, str) end
    end
end

-- Weapons require special examination
local function bow(obj, actor)
    local moved

    if obj.recordId == ids.bow_activator then
        local c = Container(ids.bow_cell, ids.bow_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            local wpn = types.Weapon.record(thing)
            if
                (wpn.type == types.Weapon.TYPE.MarksmanBow
                 or wpn.type == types.Weapon.TYPE.MarksmanCrossbow)
                and not types.Player.hasEquipped(actor, thing)
            then
                if c then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end
    end

    if moved then actor:sendEvent(ids.e, ids.bow_s) end
end

local function arrow(obj, actor)
    local moved

    if obj.recordId == ids.arrow_activator then
        local c = Container(ids.arrow_cell, ids.arrow_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            local wpn = types.Weapon.record(thing)
            if
                (wpn.type == types.Weapon.TYPE.Arrow
                 or wpn.type == types.Weapon.TYPE.Bolt)
                and not types.Player.hasEquipped(actor, thing)
            then
                if c then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end
    end

    if moved then actor:sendEvent(ids.e, ids.arrow_s) end
end

local function melee(obj, actor)
    local moved

    if obj.recordId == ids.melee_activator then
        local c = Container(ids.melee_cell, ids.melee_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            local wpn = types.Weapon.record(thing)
            if
                (wpn.type == types.Weapon.TYPE.AxeOneHand
                 or wpn.type == types.Weapon.TYPE.AxeTwoHand
                 or wpn.type == types.Weapon.TYPE.BluntOneHand
                 or wpn.type == types.Weapon.TYPE.BluntTwoClose
                 or wpn.type == types.Weapon.TYPE.BluntTwoWide
                 or wpn.type == types.Weapon.TYPE.LongBladeOneHand
                 or wpn.type == types.Weapon.TYPE.LongBladeTwoHand
                 or wpn.type == types.Weapon.TYPE.ShortBladeOneHand
                 or wpn.type == types.Weapon.TYPE.SpearTwoWide)
                and not types.Player.hasEquipped(actor, thing)
            then
                if c then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end
    end

    if moved then actor:sendEvent(ids.e, ids.melee_s) end
end

local function ranged(obj, actor)
    local moved

    if obj.recordId == ids.ranged_activator then
        local c = Container(ids.ranged_cell, ids.ranged_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            local wpn = types.Weapon.record(thing)
            if
                wpn.type == types.Weapon.TYPE.MarksmanThrown
                and not types.Player.hasEquipped(actor, thing)
            then
                if c then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end
    end

    if moved then actor:sendEvent(ids.e, ids.ranged_s) end
end

-- Special handling for enchanted and non-enchanted clothing
local function clothing(obj, actor)
    local moved

    if obj.recordId == ids.clothing_activator then
        local c = Container(ids.clothing_cell, ids.clothing_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Clothing)) do
            local clothes = types.Clothing.record(thing)
            if
                clothes.enchant == ""
                and not types.Player.hasEquipped(actor, thing)
            then
                if c then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end
    end

    if moved then actor:sendEvent(ids.e, ids.clothing_s) end
end

local function enchanted(obj, actor)
    local moved

    if obj.recordId == ids.enchanted_activator then
        local c = Container(ids.enchanted_cell, ids.enchanted_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Clothing)) do
            local clothes = types.Clothing.record(thing)
            if
                clothes.enchant ~= ""
                and not types.Player.hasEquipped(actor, thing)
            then
                if c then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end
    end

    if moved then actor:sendEvent(ids.e, ids.enchanted_s) end
end

-- THANK YOU zackhasacat!
-- https://discord.com/channels/260439894298460160/854806553310920714/1122323464087416895
local typeGmstMap = {
    [types.Armor.TYPE.Boots] = "iBootsWeight",
    [types.Armor.TYPE.Cuirass] = "iCuirassWeight",
    [types.Armor.TYPE.Greaves] = "iGreavesWeight",
    [types.Armor.TYPE.Helmet] = "iHelmWeight",
    [types.Armor.TYPE.LBracer] = "iGauntletWeight",
    [types.Armor.TYPE.LGauntlet] = "iGauntletWeight",
    [types.Armor.TYPE.LPauldron] = "iPauldronWeight",
    [types.Armor.TYPE.RBracer] = "iGauntletWeight",
    [types.Armor.TYPE.RGauntlet] = "iGauntletWeight",
    [types.Armor.TYPE.RPauldron] = "iPauldronWeight",
    [types.Armor.TYPE.Shield] = "iShieldWeight"
}

local function armorKind(obj)
    local iWeight = core.getGMST(typeGmstMap[obj.type.record(obj).type])
    local epsilon = 0.0005
    local weight = obj.type.record(obj).weight

    if weight <= iWeight * core.getGMST("fLightMaxMod") + epsilon then
        return "LightArmor"
    elseif weight <= iWeight * core.getGMST("fMedMaxMod") + epsilon then
        return "MediumArmor"
    else
        return "HeavyArmor"
    end
end

local function armor(kind, activator, cell, container, str)
    return function(obj, actor)
        local moved

        if obj.recordId == activator then
            local c = Container(cell, container)
            for _, thing in pairs(types.Player.inventory(actor):getAll(types.Armor)) do
                if
                    c
                    and armorKind(thing) == kind
                    and not types.Player.hasEquipped(actor, thing)
                then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end

        if moved then actor:sendEvent(ids.e, str) end
    end
end

-- https://stackoverflow.com/a/22831842
local function startsWith(str, start)
   return string.sub(str, 1, string.len(start)) == start
end

-- Soul gems need special handling since they are considered "misc" along with gold and etc
local function soulgem(obj, actor)
    local moved

    if obj.recordId == ids.soulgem_activator then
        local c = Container(ids.soulgem_cell, ids.soulgem_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Miscellaneous)) do
            if c and not startsWith(thing.recordId, "gold_") then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
    end

    if moved then actor:sendEvent(ids.e, ids.soulgem_s) end
end

-- Generated handlers
local alchemy = makeHandler(ids.alchemy_activator, types.Ingredient, ids.alchemy_cell, ids.alchemy_container, ids.alchemy_s)
local book = makeHandler(ids.book_activator, types.Book, ids.book_cell, ids.book_container, ids.book_s)
local potion = makeHandler(ids.misc_activator, types.Potion, ids.misc_cell, ids.misc_container, ids.misc_s)
local lockpick = makeHandler(ids.lockpick_activator, types.Lockpick, ids.lockpick_cell, ids.lockpick_container, ids.lockpick_s)
local probe = makeHandler(ids.probe_activator, types.Probe, ids.probe_cell, ids.probe_container, ids.probe_s)

local lightArmor = armor("LightArmor", ids.light_armor_activator, ids.light_armor_cell, ids.light_armor_container, ids.light_armor_s)
local mediumArmor = armor("MediumArmor", ids.medium_armor_activator, ids.medium_armor_cell, ids.medium_armor_container, ids.medium_armor_s)
local heavyArmor = armor("HeavyArmor", ids.heavy_armor_activator, ids.heavy_armor_cell, ids.heavy_armor_container, ids.heavy_armor_s)

-- No engineHandler needed; just do this stuff when the script loads. The game world may not
-- yet be fully initialized but that's fine since all we're doing is registering handlers.
for _, handler in pairs(
    {alchemy, bow, arrow, melee, ranged, clothing, enchanted, book,
     potion, soulgem, lockpick, probe, lightArmor, mediumArmor, heavyArmor}
) do
    Activation.addHandlerForType(types.Activator, handler)
end
