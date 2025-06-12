local core = require("openmw.core")
local T = require("openmw.types")

local mCfg = require("scripts.fresh-loot.config.configuration")
local mTypes = require("scripts.fresh-loot.config.types")

local module = {}

local armorWeightFactors = {
    [T.Armor.TYPE.Helmet] = core.getGMST("iHelmWeight"),
    [T.Armor.TYPE.Cuirass] = core.getGMST("iCuirassWeight"),
    [T.Armor.TYPE.LPauldron] = core.getGMST("iPauldronWeight"),
    [T.Armor.TYPE.RPauldron] = core.getGMST("iPauldronWeight"),
    [T.Armor.TYPE.Greaves] = core.getGMST("iGreavesWeight"),
    [T.Armor.TYPE.Boots] = core.getGMST("iBootsWeight"),
    [T.Armor.TYPE.LGauntlet] = core.getGMST("iGauntletWeight"),
    [T.Armor.TYPE.RGauntlet] = core.getGMST("iGauntletWeight"),
    [T.Armor.TYPE.Shield] = core.getGMST("iShieldWeight"),
    [T.Armor.TYPE.LBracer] = core.getGMST("iGauntletWeight"),
    [T.Armor.TYPE.RBracer] = core.getGMST("iGauntletWeight"),
}

local fLightMaxMod = core.getGMST("fLightMaxMod")
local fMedMaxMod = core.getGMST("fMedMaxMod")

local function getRecord(object)
    if object.type and object.type.record then
        return object.type.record(object)
    end
    return nil
end
module.getRecord = getRecord

local function objectId(object)
    return string.format("<%s (%s)>", object.recordId, object.id)
end
module.objectId = objectId

local function isObjectInvalid(obj)
    return not obj:isValid() or obj.count == 0
end
module.isObjectInvalid = isObjectInvalid

local function getActorLevel(actor)
    return math.max(T.Actor.stats.level(actor).current, 1)
end
module.getActorLevel = getActorLevel

local function isActorHostile(actor)
    return T.Actor.stats.ai.fight(actor).base >= mCfg.lootLevel.minHostileFightValue
end
module.isActorHostile = isActorHostile

local function isActorProtector(actor)
    return T.Actor.stats.ai.alarm(actor).base >= mCfg.lootLevel.minProtectorAlarmValue
end
module.isActorProtector = isActorProtector

local function getEquippedItemSlot(actor, item)
    for slot, object in pairs(T.Actor.getEquipment(actor)) do
        if object.id == item.id then
            return slot
        end
    end
    return nil
end
module.getEquippedItemSlot = getEquippedItemSlot

local function getArmorClass(record)
    local epsilon = 0.0005
    local weightFactor = math.floor(armorWeightFactors[record.type])

    if record.weight <= weightFactor * fLightMaxMod + epsilon then
        return mTypes.armorClasses.Light
    end
    if record.weight <= weightFactor * fMedMaxMod + epsilon then
        return mTypes.armorClasses.Medium
    end
    return mTypes.armorClasses.Heavy
end

local function itemRecordToTable(type, record)
    local newRecord = {}
    for _, field in ipairs(mTypes.itemTypes[type].recordFields) do
        newRecord[field] = record[field]
    end
    return newRecord
end
module.itemRecordToTable = itemRecordToTable

local function getItemClass(type, record)
    if type == T.Armor then
        return getArmorClass(record)
    end
end
module.getItemClass = getItemClass

local function getItemsValueSum(loot)
    local inventory = loot.type.inventory(loot)
    local sum = 0
    for _, item in ipairs(inventory:getAll()) do
        local record = getRecord(item)
        sum = sum + (record.isKey and 0 or record.value or 0)
    end
    return sum
end
module.getItemsValueSum = getItemsValueSum

local function areValidItemProps(item, record)
    return not T.Item.itemData(item).enchantmentCharge
            and not T.Item.isRestocking(item)
            and not record.mwscript
            and string.sub(record.id, 1, 10) ~= "Generated:"
end
module.areValidItemProps = areValidItemProps

local function hasValidInventory(container)
    local inventory = T.Container.inventory(container)
    if not inventory:isResolved() then
        return true
    end
    for type in pairs(mTypes.itemTypes) do
        for _, item in ipairs(inventory:getAll(type)) do
            if mTypes.itemTypes[item.type] then
                return true
            end
        end
    end
    return false
end
module.hasValidInventory = hasValidInventory

local function isValidContainer(state, record)
    return not state.cache.excluded.containerIds[record.id]
            and not record.mwscript
            and not record.isOrganic
            and not record.isRespawning
end
module.isValidContainer = isValidContainer

local function isValidActor(state, record)
    return not state.cache.excluded.actorIds[record.id]
            and record.mwscript ~= "slavescript"
            and record.class ~= "guard"
end
module.isValidActor = isValidActor

module.getLootData = function(state, object)
    if object.type == T.Container then
        return state.containers[object.id]
    end
    return state.actors[object.id]
end

return module