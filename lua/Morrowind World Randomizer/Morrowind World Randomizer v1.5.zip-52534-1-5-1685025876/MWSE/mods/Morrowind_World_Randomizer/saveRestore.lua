local log = include("Morrowind_World_Randomizer.log")

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

local varNames = {["id"]=true, ["objectType"]=true, ["enchantCapacity"]=true, ["armorRating"]=true, ["maxCondition"]=true,
    ["quality"]=true, ["speed"]=true, ["weight"]=true, ["chopMin"]=true, ["chopMax"]=true,["slashMin"]=true, ["slashMax"]=true,
    ["thrustMin"]=true, ["thrustMax"]=true, ["mesh"]=true, ["castType"]=true, ["chargeCost"]=true, ["maxCharge"]=true, ["value"]=true,
    ["time"]=true,}
local ingrVarNames = {["effects"]=true, ["effectAttributeIds"]=true, ["effectSkillIds"]=true,}

---@param originalId string|nil
---@return table
function this.serializeItemBaseObject(object, originalId)
    if not object then return {} end

    local out = {}

    out.originalId = originalId
    out.created = (originalId and object.id ~= originalId) and true or false

    for varName, _ in pairs(varNames) do
        if object[varName] then
            out[varName] = object[varName]
        end
    end

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
        out.enchantment = {}
        -- out.enchantment.castType = object.enchantment.castType
        -- out.enchantment.chargeCost = object.enchantment.chargeCost
        out.enchantment.id = object.enchantment.id
        -- out.enchantment.maxCharge = object.enchantment.maxCharge
        -- out.enchantment.effects = serializeEffects(object.enchantment.effects)
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
                if female or male then table.insert(out.parts, {part.type, female, male}) end
            end
        end
    end

    if object.color then
        out.color = {object.color[1], object.color[2], object.color[3]}
    end

    return out
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

---@param data table
---@param createNewEnchantment boolean
function this.restoreItemBaseObject(object, data, createNewEnchantment)
    if not object or not data then return end
    log("Restoring object data %s", tostring(object))
    local enchantmentFound = false
    for varName, val in pairs(data) do
        if type(val) ~= "table" and varNames[varName] and not forbiddenForRestore[varName] then
            object[varName] = val

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
                object.effectAttributeIds[i] = id
            end

        elseif varName == "effectSkillIds" then
            for i, id in ipairs(val) do
                object.effectSkillIds[i] = id
            end

        elseif varName == "parts" then
            for pos = 1, #object.parts do
                local newPartData = val[pos]
                local part = object.parts[pos]
                if newPartData then
                    part.type = newPartData[1]
                    part.female = newPartData[2] and tes3.getObject(newPartData[2]) or nil
                    part.male = newPartData[3] and tes3.getObject(newPartData[3]) or nil
                else
                    part.type = 255
                    part.female = nil
                    part.male = nil
                end
            end

        elseif varName == "enchantment" then
            local enchantment = tes3.getObject(val.id)
            enchantmentFound = true
            object.enchantment = enchantment

        elseif varName == "color" then
            if object.color then
                object.color[1] = varName[1]
                object.color[2] = varName[2]
                object.color[3] = varName[3]
            end
        end
    end
    if object.enchantment and not enchantmentFound then object.enchantment = nil end
    tes3.setSourceless(object, true)
end

---@param enchantment tes3enchantment
---@param data table
function this.restoreEnchantment(enchantment, data)
    if not enchantment or not data then return end
    log("Restoring enchantment %s", tostring(enchantment))
    enchantment.castType = data.castType
    enchantment.chargeCost = data.chargeCost
    enchantment.maxCharge = data.maxCharge
    restoreEffects(enchantment, data.effects)
    tes3.setSourceless(enchantment, true)
end

---@param id string
---@param data table
---@return tes3enchantment|nil
function this.createEnchantment(id, data)
    if not id or not data then return end
    local castType = data.castType
    local chargeCost = data.chargeCost < 1 and 1 or data.chargeCost
    local maxCharge = data.maxCharge < 1 and 1 or data.maxCharge
    local enchantment = tes3.createObject{id = id, objectType = tes3.objectType.enchantment, castType = castType,
        chargeCost = chargeCost, maxCharge = maxCharge}

    restoreEffects(enchantment, data.effects)
    tes3.setSourceless(enchantment, true)
    log("%s enchantment created", tostring(enchantment))
    return enchantment
end


---@return table
function this.serializeActorBaseObject(object)
    local data = {spells = {}}

    for i, spell in pairs(object.spells) do
        table.insert(data.spells, spell.id)
    end
    data.barterGold = object.barterGold

    if object.aiConfig.travelDestinations ~= nil then
        data.travelDestinations = {}
        for i, destination in pairs(object.aiConfig.travelDestinations) do
            data.travelDestinations[i] = {cell = {id = destination.cell.id, gridX = destination.cell.gridX, gridY = destination.cell.gridY},
                marker = {x = destination.marker.position.x, y = destination.marker.position.y, z = destination.marker.position.z,
                rotX = destination.marker.orientation.x, rotY = destination.marker.orientation.y, rotZ = destination.marker.orientation.z,}}
        end
    end

    if object.attacks ~= nil then
        data.attacks = {}
        for i, val in ipairs(object.attacks) do
            table.insert(data.attacks, {val.min, val.max})
        end
    end

    if object.hair then
        data.hair = object.hair.id
    end
    if object.head then
        data.head = object.head.id
    end

    return data
end

---@param data table
function this.restoreActorBaseObject(object, data)
    if data == nil or object == nil then return end
    log("Restoring object data %s", tostring(object))
    if data.spells then
        for i, spell in pairs(object.spells) do
            object.spells:remove(spell)
        end
        for i, spellId in ipairs(data.spells) do
            object.spells:add(spellId)
        end
    end

    object.barterGold = data.barterGold ~= nil and data.barterGold or object.barterGold

    if object.aiConfig.travelDestinations ~= nil and data.travelDestinations ~= nil then
        for i, destination in pairs(object.aiConfig.travelDestinations) do
            if data.travelDestinations[i] ~= nil then
                destination.cell = tes3.getCell(data.travelDestinations[i].cell)
                destination.marker.position = tes3vector3.new(data.travelDestinations[i].marker.x, data.travelDestinations[i].marker.y,
                    data.travelDestinations[i].marker.z)
                destination.marker.orientation = tes3vector3.new(data.travelDestinations[i].marker.rotX, data.travelDestinations[i].marker.rotY,
                    data.travelDestinations[i].marker.rotZ)
            end
        end
    end

    if object.attacks ~= nil and data.attacks ~= nil then
        for i, val in ipairs(object.attacks) do
            if data.attacks[i] ~= nil then
                val.min = data.attacks[i][1]
                val.max = data.attacks[i][2]
            end
        end
    end

    if object.hair and data.hair then
        object.hair = tes3.getObject(data.hair)
    end
    if object.head and data.head then
        object.head = tes3.getObject(data.head)
    end
end

return this