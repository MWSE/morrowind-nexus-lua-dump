require("scripts.abandoned-flat-containers.checks")
local core = require('openmw.core')
local Activation = require('openmw.interfaces').Activation
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')

local ids = require("scripts.abandoned-flat-containers.ids")
local STORAGE_KEY_ID = "momw_afc_es_key"
local STORAGE_CELL = "Enchanting Storage"

local function Container(containerId)
    for _, c in pairs(world.getCellByName(STORAGE_CELL):getAll(types.Container)) do
        if c.recordId == containerId then return c end
    end
end

local function makeHandler(activator, objtype, container, str, sound)
    return function(obj, actor)
        local moved

        if obj.recordId == activator then
            local c = Container(container)
            for _, thing in pairs(types.Player.inventory(actor):getAll(objtype)) do
                if c then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end

        if moved then
            actor:sendEvent(ids.e, {sound = sound, str = str})
        end
    end
end

-- Special handling for enchanted and non-enchanted clothing
local function clothing(obj, actor)
    local moved

    if obj.recordId == ids.clothing_activator then
        local c = Container(ids.clothing_container)
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

    if moved then
        actor:sendEvent(ids.e, {sound = ids.clothing_sound, str = ids.clothing_s})
    end
end

local function enchanted(obj, actor)
    local moved

    if obj.recordId == ids.ench_clo_activator then
        local c = Container(ids.ench_clo_container)
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

    if moved then
        actor:sendEvent(ids.e, {sound = ids.ench_clo_sound, str = ids.ench_clo_s})
    end
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

local function armor(kind, activator, container, str, sound)
    return function(obj, actor)
        local moved

        if obj.recordId == activator then
            local c = Container(container)
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

        if moved then
            actor:sendEvent(ids.e, {sound = sound, str = str})
        end
    end
end

local function makeWpn(inTypes, activator, container, str, sound)
    return function(obj, actor)
        local moved
        if obj.recordId == activator then
            local c = Container(container)
            for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
                if
                    c
                    and inTypes[types.Weapon.record(thing).type]
                    and not types.Player.hasEquipped(actor, thing)
                then
                    thing:moveInto(types.Container.content(c))
                    moved = true
                end
            end
        end
        if moved then
            actor:sendEvent(ids.e, {sound = sound, str = str})
        end
    end
end

-- Various other special handlers
local function book(obj, actor)
    local moved

    if obj.recordId == ids.book_activator then
        local c = Container(ids.book_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Book)) do
            local books = types.Book.record(thing)
            if c and not books.isScroll then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
    end

    if moved then
        actor:sendEvent(ids.e, {sound = ids.book_sound, str = ids.book_s})
    end
end

local function scroll(obj, actor)
    local moved

    if obj.recordId == ids.scroll_activator then
        local c = Container(ids.scroll_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Book)) do
            local scrolls = types.Book.record(thing)
            if c and scrolls.isScroll then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
    end

    if moved then
        actor:sendEvent(ids.e, {sound = ids.scroll_sound, str = ids.scroll_s})
    end
end

local function ttool(obj, actor)
    local moved
    if obj.recordId == ids.ttool_activator then
        local c = Container(ids.ttool_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Lockpick)) do
            if c and not types.Player.hasEquipped(actor, thing) then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Probe)) do
            if c and not types.Player.hasEquipped(actor, thing) then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
    end
    if moved then
        actor:sendEvent(ids.e, {sound = ids.ttool_sound, str = ids.ttool_s})
    end
end

-- Soul gems, keys, and other types.Miscellaneous need special handling
local function keyHandler(obj, actor)
    local moved

    if obj.recordId == ids.key_activator then
        local c = Container(ids.key_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Miscellaneous)) do
            if
                c
                and string.match(thing.recordId, "key")
                and thing.recordId ~= STORAGE_KEY_ID
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
    end

    if moved then
        actor:sendEvent(ids.e, {sound = ids.key_sound, str = ids.key_s})
    end
end

local function misc(obj, actor)
    local moved

    if obj.recordId == ids.misc_activator then
        local c = Container(ids.misc_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Miscellaneous)) do
            if c
                and not string.match(thing.recordId, "gold")
                and not string.match(thing.recordId, "key")
                and not string.match(thing.recordId, "soulgem")
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Apparatus)) do
            if c then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Light)) do
            if c then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
    end

    if moved then
        actor:sendEvent(ids.e, {sound = ids.misc_sound, str = ids.misc_s})
    end
end

local function soulgem(obj, actor)
    local moved

    if obj.recordId == ids.soulgem_activator then
        local c = Container(ids.soulgem_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Miscellaneous)) do
            if c and string.match(thing.recordId, "soulgem") then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
    end

    if moved then
        actor:sendEvent(ids.e, {sound = ids.soulgem_sound, str = ids.soulgem_s})
    end
end

-- Weapon type bundles
local axes = {
    [types.Weapon.TYPE.AxeOneHand] = true,
    [types.Weapon.TYPE.AxeTwoHand] = true
}

local ammos = {
    [types.Weapon.TYPE.Arrow] = true,
    [types.Weapon.TYPE.Bolt] = true,
    [types.Weapon.TYPE.MarksmanThrown] = true
}

local blunts = {
    [types.Weapon.TYPE.BluntOneHand] = true,
    [types.Weapon.TYPE.BluntTwoClose] = true,
    [types.Weapon.TYPE.BluntTwoWide] = true
}

local function takeAll(obj, actor)
    local c, moved

    -- Do All The Things
    if obj.recordId == ids.all_activator then
        -- Ingredients
        c = Container(ids.alchemy_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Ingredient)) do
            if c then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Ammo
        c = Container(ids.ammo_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            if
                c
                and ammos[types.Weapon.record(thing).type]
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Axes
        c = Container(ids.axe_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            if
                c
                and axes[types.Weapon.record(thing).type]
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Blunts
        c = Container(ids.bluntwpn_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            if
                c
                and blunts[types.Weapon.record(thing).type]
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Books
        c = Container(ids.book_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Book)) do
            local books = types.Book.record(thing)
            if c and not books.isScroll then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Bows
        c = Container(ids.bow_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            if
                c
                and types.Weapon.record(thing).type == types.Weapon.TYPE.MarksmanBow
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Clothes
        c = Container(ids.clothing_container)
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

        -- Crossbow
        c = Container(ids.crossbow_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            if
                c
                and types.Weapon.record(thing).type == types.Weapon.TYPE.MarksmanCrossbow
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Enchanted
        c = Container(ids.ench_clo_container)
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

        -- Heavy Armor
        c = Container(ids.heavy_armor_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Armor)) do
            if
                c
                and armorKind(thing) == "HeavyArmor"
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Keys
        c = Container(ids.key_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Miscellaneous)) do
            if
                c
                and string.match(thing.recordId, "key")
                and thing.recordId ~= STORAGE_KEY_ID
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Light Armor
        c = Container(ids.light_armor_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Armor)) do
            if
                c
                and armorKind(thing) == "LightArmor"
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Long Blade 1
        c = Container(ids.longblade1_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            if
                c
                and types.Weapon.record(thing).type == types.Weapon.TYPE.LongBladeOneHand
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Long Blade 2
        c = Container(ids.longblade2_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            if
                c
                and types.Weapon.record(thing).type == types.Weapon.TYPE.LongBladeTwoHand
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Medium Armor
        c = Container(ids.medium_armor_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Armor)) do
            if
                c
                and armorKind(thing) == "MediumArmor"
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Misc
        c = Container(ids.misc_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Miscellaneous)) do
            if c
                and not string.match(thing.recordId, "gold")
                and not string.match(thing.recordId, "key")
                and not string.match(thing.recordId, "soulgem")
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Apparatus)) do
            if c then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Light)) do
            if c then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Potions
        c = Container(ids.potion_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Potion)) do
            if c then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Scrolls
        c = Container(ids.scroll_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Book)) do
            local scrolls = types.Book.record(thing)
            if c and scrolls.isScroll then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Short Blade
        c = Container(ids.shortblade_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            if
                c
                and types.Weapon.record(thing).type == types.Weapon.TYPE.ShortBladeOneHand
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Soul Gems
        c = Container(ids.soulgem_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Miscellaneous)) do
            if c and string.match(thing.recordId, "soulgem") then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Spears
        c = Container(ids.spear_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Weapon)) do
            if
                c
                and types.Weapon.record(thing).type == types.Weapon.TYPE.SpearTwoWide
                and not types.Player.hasEquipped(actor, thing)
            then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        -- Thief Tools
        c = Container(ids.ttool_container)
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Lockpick)) do
            if c and not types.Player.hasEquipped(actor, thing) then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end
        for _, thing in pairs(types.Player.inventory(actor):getAll(types.Probe)) do
            if c and not types.Player.hasEquipped(actor, thing) then
                thing:moveInto(types.Container.content(c))
                moved = true
            end
        end

        if moved then actor:sendEvent(ids.e, {str = ids.all_s, sound = ids.all_sound}) end
    end
end

-- No engineHandler needed; just do this stuff when the script loads. The game world may not
-- yet be fully initialized but that's fine since all we're doing is registering handlers.
for _, handler in pairs(
    {
        makeHandler(ids.alchemy_activator, types.Ingredient, ids.alchemy_container, ids.alchemy_s, ids.alchemy_sound),
        makeWpn(ammos, ids.ammo_activator, ids.ammo_container, ids.ammo_s, ids.ammo_sound),
        makeWpn(axes, ids.axe_activator, ids.axe_container, ids.axe_s, ids.axe_sound),
        makeWpn(blunts, ids.bluntwpn_activator, ids.bluntwpn_container, ids.bluntwpn_s, ids.bluntwpn_sound),
        book,
        makeWpn({[types.Weapon.TYPE.MarksmanBow] = true}, ids.bow_activator, ids.bow_container, ids.bow_s, ids.bow_sound),
        clothing,

        makeWpn({[types.Weapon.TYPE.MarksmanCrossbow] = true}, ids.crossbow_activator, ids.crossbow_container, ids.crossbow_s, ids.crossbow_sound),
        enchanted,
        armor("HeavyArmor", ids.heavy_armor_activator, ids.heavy_armor_container, ids.heavy_armor_s, ids.heavy_armor_sound),
        keyHandler,
        armor("LightArmor", ids.light_armor_activator, ids.light_armor_container, ids.light_armor_s, ids.light_armor_sound),
        makeWpn({[types.Weapon.TYPE.LongBladeOneHand] = true}, ids.longblade1_activator, ids.longblade1_container, ids.longblade1_s, ids.longblade1_sound),
        makeWpn({[types.Weapon.TYPE.LongBladeTwoHand] = true}, ids.longblade2_activator, ids.longblade2_container, ids.longblade2_s, ids.longblade2_sound),
        armor("MediumArmor", ids.medium_armor_activator, ids.medium_armor_container, ids.medium_armor_s, ids.medium_armor_sound),
        misc,
        makeHandler(ids.potion_activator, types.Potion, ids.potion_container, ids.potion_s, ids.potion_sound),
        scroll,
        makeWpn({[types.Weapon.TYPE.ShortBladeOneHand] = true}, ids.shortblade_activator, ids.shortblade_container, ids.shortblade_s, ids.shortblade_sound),
        soulgem,
        makeWpn({[types.Weapon.TYPE.SpearTwoWide] = true}, ids.spear_activator, ids.spear_container, ids.spear_s, ids.spear_sound),
        ttool,

        takeAll
    }
) do
    Activation.addHandlerForType(types.Activator, handler)
end

local function bossBattleBegin(player)
    player:teleport(
        "Enchanting Storage",
        util.vector3(-3926.082031, 1340.704590, 145.000061),
        util.transform.rotateZ(185)
    )
end

local function bossBattleOver(player)
    player:teleport(
        "Enchanting Storage",
        util.vector3(-178.434174, -344.366058, 3),
        util.transform.rotateZ(90)
    )
end

local function disableActor(actor)
	actor.enabled = false
end

return {
    eventHandlers = {
        momw_afc_bossBattleBegin = bossBattleBegin,
        momw_afc_bossBattleOver = bossBattleOver,
        momw_afc_disableActor = disableActor
    }
}
