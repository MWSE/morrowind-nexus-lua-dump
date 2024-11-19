local types = require('openmw.types')
local world = require('openmw.world')

local function createArmorDraft(sourceTemplate, styleTemplate)
    local itemTable = {
        template = styleTemplate,
        baseArmor = sourceTemplate.baseArmor,
        enchant = sourceTemplate.enchant,
        enchantCapacity = sourceTemplate.enchantCapacity,
        health = sourceTemplate.health,
        mwscript = sourceTemplate.mwscript,
        value = sourceTemplate.value,
        weight = sourceTemplate.weight,
        name = sourceTemplate.name,
    }
    return types.Armor.createRecordDraft(itemTable)
end

local function createWeaponDraft(sourceTemplate, styleTemplate)
    local itemTable = {
        template = styleTemplate,
        chopMaxDamage = sourceTemplate.chopMaxDamage,
        chopMinDamage = sourceTemplate.chopMinDamage,
        enchant = sourceTemplate.enchant,
        enchantCapacity = sourceTemplate.enchantCapacity,
        health = sourceTemplate.health,
        isMagical = sourceTemplate.isMagical,
        isSilver = sourceTemplate.isSilver,
        mwscript = sourceTemplate.mwscript,
        reach = sourceTemplate.reach,
        slashMaxDamage = sourceTemplate.slashMaxDamage,
        slashMinDamage = sourceTemplate.slashMinDamage,
        speed = sourceTemplate.speed,
        thrustMaxDamage = sourceTemplate.thrustMaxDamage,
        thrustMinDamage = sourceTemplate.thrustMinDamage,
        value = sourceTemplate.value,
        weight = sourceTemplate.weight,
        name = sourceTemplate.name,
    }
    return types.Weapon.createRecordDraft(itemTable)
end

local function createClothingDraft(sourceTemplate, styleTemplate)
    local itemTable = {
        template = styleTemplate,
        type = sourceTemplate.type,
        enchant = sourceTemplate.enchant,
        enchantCapacity = sourceTemplate.enchantCapacity,
        mwscript = sourceTemplate.mwscript,
        value = sourceTemplate.value,
        weight = sourceTemplate.weight,
        name = sourceTemplate.name,
    }
    return types.Clothing.createRecordDraft(itemTable)
end

local function getTemplates(source, style)
    local sourceTemplate = source.type.record(source)
    local styleTemplate = source.type.record(style)
    return { sourceTemplate = sourceTemplate, styleTemplate = styleTemplate }
end

local function createRecordDraft(type, sourceTemplate, styleTemplate)
    if type == types.Armor then
        return createArmorDraft(sourceTemplate, styleTemplate)
    elseif type == types.Weapon then
        return createWeaponDraft(sourceTemplate, styleTemplate)
    elseif type == types.Clothing then
        return createClothingDraft(sourceTemplate, styleTemplate)
    else
        print('TRANSMOG: This should not happen lol')
    end
end

local function transmog(data)
    print(data)
    local player = world.players[1]
    local templates = getTemplates(data.source, data.style)
    -- If the source has no enchantment and/or script while the style
    -- does, they will also be present on the transmog. As far as I can tell,
    -- this cannot be circumvented on the current OpenMW build. Look into
    -- contributing to the project.
    if templates.sourceTemplate.enchant == nil and templates.styleTemplate.enchant ~= nil then
        player:sendEvent('transmogFailed', 'an enchantment')
        return
    end
    if templates.sourceTemplate.mwscript == nil and templates.styleTemplate.mwscript ~= nil then
        player:sendEvent('transmogFailed', 'an attached script')
        return
    end
    local recordDraft = createRecordDraft(data.source.type, templates.sourceTemplate, templates.styleTemplate)
    local newRecord = world.createRecord(recordDraft)
    world.createObject(newRecord.id):moveInto(player)
    data.source:remove(1)
    player:sendEvent('transmogCompleted', nil)
end

return {
    eventHandlers = {
        transmog = transmog,
    }
}
