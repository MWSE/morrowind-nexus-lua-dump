local log = include("diject.remains_of_the_fallen.utils.log")

local this = {}

local serializeEffects = function(effects)
    local effOut = {}
    if effects then
        for _, effect in pairs(effects) do
            local effectData = {}
            if effect.id == -1 then break end
            effectData.id = effect.id
            effectData.skill = effect.skill
            effectData.attribute = effect.attribute
            effectData.min = effect.min
            effectData.max = effect.max
            effectData.duration = effect.duration
            effectData.radius = effect.radius
            effectData.rangeType = effect.rangeType
            table.insert(effOut, effectData)
        end
    end
    return effOut
end

---@param enchantment tes3enchantment
---@return table|nil
function this.serializeItemEnchantment(enchantment)
    if not enchantment then return nil end
    local out = {}
    out.castType = enchantment.castType
    out.chargeCost = enchantment.chargeCost
    out.id = enchantment.id
    out.maxCharge = enchantment.maxCharge
    out.effects = serializeEffects(enchantment.effects)
    return out
end

local varNames = {["id"]=true, ["objectType"]=true, ["enchantCapacity"]=true, ["armorRating"]=true, ["maxCondition"]=true,
    ["quality"]=true, ["speed"]=true, ["weight"]=true, ["chopMin"]=true, ["chopMax"]=true,["slashMin"]=true, ["slashMax"]=true,
    ["thrustMin"]=true, ["thrustMax"]=true, ["mesh"]=true, ["castType"]=true, ["chargeCost"]=true, ["maxCharge"]=true,
    ["time"]=true, ["name"]=true, ["slot"]=true, ["skill"] = true, ["magickaCost"]=true, ["icon"]=true,}
local ingrVarNames = {["effects"]=true, ["effectAttributeIds"]=true, ["effectSkillIds"]=true,}

---@return table|nil
function this.serializeObject(object)
    if not object then return end

    local out = {}

    for varName, _ in pairs(varNames) do
        if object[varName] then
            out[varName] = object[varName]
        end
    end

    if object.value then out.value = object.value end

    if object.objectType ~= tes3.objectType.ingredient then
        if object.effects then out.effects = serializeEffects(object.effects) end
    else
        for varName, _ in pairs(ingrVarNames) do
            if object[varName] then
                out[varName] = {}
                for _, val in ipairs(object[varName]) do
                    table.insert(out[varName], val)
                end
            end
        end
    end

    if object.enchantment then
        out.enchantment = this.serializeItemEnchantment(object.enchantment)
    end

    if object.parts then
        out.parts = {}
        for _, part in pairs(object.parts) do
            if part.type ~= 255 then
                local female
                local male
                if part.female ~= nil then
                    female = part.female.id
                end
                if part.male ~= nil then
                    male = part.male.id
                end
                ---@class objectSerDes.partData
                local partData = {type = part.type, female = female, male = male}
                if female or male then table.insert(out.parts, partData) end
            end
        end
    end

    if object.color then
        out.color = {object.color[1], object.color[2], object.color[3]}
    end

    return out
end

local function restoreEffects(object, data)
    for i = 1, 8 do
        if data[i] then
            object.effects[i].id = data[i].id
            object.effects[i].skill = data[i].skill
            object.effects[i].attribute = data[i].attribute
            object.effects[i].min = data[i].min
            object.effects[i].max = data[i].max
            object.effects[i].duration = data[i].duration
            object.effects[i].radius = data[i].radius
            object.effects[i].rangeType = data[i].rangeType
        else
            object.effects[i].id = -1
            object.effects[i].skill = 0
            object.effects[i].attribute = 0
            object.effects[i].min = 0
            object.effects[i].max = 0
            object.effects[i].duration = 0
            object.effects[i].radius = 0
            object.effects[i].rangeType = 0
        end
    end
end

local forbiddenForRestore = {["id"]=true, ["objectType"]=true,}

---@class rotf.serdes.restoreItemObject.params
---@field createNewEnchantment boolean|nil
---@field useIdFromData boolean|nil

---@param objectId string|nil
---@param data table
---@param params rotf.serdes.restoreItemObject.params|nil
---@return any
function this.restoreObject(objectId, data, params)
    if not data then return end
    if not params then params = {} end
    local choosedId = params.useIdFromData == true and data.id or objectId
    local object = choosedId and tes3.getObject(choosedId) or nil
    if object then
        return object
    else
        for obj in tes3.iterateObjects(data.objectType) do
            if not obj.script or obj.script == "" then ---@diagnostic disable-line: undefined-field
                object = obj:createCopy{id = choosedId} ---@diagnostic disable-line: undefined-field
                break
            end
        end
    end
    if not object or object.objectType ~= data.objectType then return end
    log("Restoring object data", object)
    local enchantmentFound = false
    for varName, val in pairs(data) do
        log(varName, "old", object[varName], "new", val)
        if type(val) ~= "table" and varNames[varName] and not forbiddenForRestore[varName] then
            object[varName] = val

        elseif varName == "value" and object.objectType ~= tes3.objectType.spell then
            object.value = val

        elseif varName == "effects" then
            if object.objectType ~= tes3.objectType.ingredient then
                restoreEffects(object, val)
            else
                for i, id in ipairs(val) do
                    object.effects[i] = id
                end
            end

        elseif varName == "effectAttributeIds" then
            for i, id in ipairs(val) do
                object.effectAttributeIds[i] = id ---@diagnostic disable-line: undefined-field
            end

        elseif varName == "effectSkillIds" then
            for i, id in ipairs(val) do
                object.effectSkillIds[i] = id ---@diagnostic disable-line: undefined-field
            end

        elseif varName == "parts" then
            for pos = 1, #object.parts do
                ---@type objectSerDes.partData
                local newPartData = val[pos]
                local part = object.parts[pos]
                if newPartData then
                    part.type = newPartData.type
                    part.female = newPartData.female and tes3.getObject(newPartData.female) or nil
                    part.male = newPartData.male and tes3.getObject(newPartData.male) or nil
                else
                    part.type = 255
                    part.female = nil
                    part.male = nil
                end
            end

        elseif varName == "enchantment" then
            local enchantment = tes3.getObject(val.id)
            if not enchantment or params.createNewEnchantment or enchantment.castType ~= val.castType then
                enchantment = this.createEnchantment((not enchantment) and val.id or nil, val)
            end
            enchantmentFound = true
            object.enchantment = enchantment

        elseif varName == "color" then
            if object.color then ---@diagnostic disable-line: undefined-field
                object.color[1] = val[1] ---@diagnostic disable-line: undefined-field
                object.color[2] = val[2] ---@diagnostic disable-line: undefined-field
                object.color[3] = val[3] ---@diagnostic disable-line: undefined-field
            end
        end
    end
    if object.enchantment and not enchantmentFound then object.enchantment = nil end
    return object
end

---@param enchantment tes3enchantment
---@param data table
function this.restoreEnchantment(enchantment, data)
    if not enchantment or not data then return end
    log("Restoring enchantment", enchantment, data)
    enchantment.castType = data.castType
    enchantment.chargeCost = data.chargeCost
    enchantment.maxCharge = data.maxCharge
    restoreEffects(enchantment, data.effects)
end

---@param id string|nil
---@param data table
---@return tes3enchantment|nil
function this.createEnchantment(id, data)
    if not data then return end
    local castType = data.castType
    local chargeCost = data.chargeCost < 1 and 1 or data.chargeCost
    local maxCharge = data.maxCharge < 1 and 1 or data.maxCharge
    local enchantment = tes3.createObject{id = id, objectType = tes3.objectType.enchantment, castType = castType,
        chargeCost = chargeCost, maxCharge = maxCharge}

    restoreEffects(enchantment, data.effects)
    log("Enchantment created", enchantment)
    return enchantment
end

return this