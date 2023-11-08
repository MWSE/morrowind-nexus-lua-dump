local log = include("Morrowind_World_Randomizer.log")
local magicEffectLib = include("Morrowind_World_Randomizer.magicEffect")
local genData = include("Morrowind_World_Randomizer.generatorData")

local this = {}

local forbiddenEffectsIds = genData.forbiddenEffectsIds

local forbiddenIds = genData.forbiddenIds

local forbiddenModels = genData.forbiddenModels

local scriptWhiteList = genData.scriptWhiteList

local obtainableArtifacts = genData.obtainableArtifacts

local skillByEffectId = genData.skillByEffectId

local herbsOffsets = genData.herbsOffsets

local function addItemTable(out, objectTypeStr, objectSubTypeStr)
    if not out.ItemGroups[objectTypeStr] then out.ItemGroups[objectTypeStr] = {} end
    if not out.ItemGroups[objectTypeStr][objectSubTypeStr] then
        out.ItemGroups[objectTypeStr][objectSubTypeStr] = {Count = 0, MaxCost = 0, MaxEnchCost = 0, Items = {}}
    end
end

local function addItemToTable(out, object, objectTypeId, objectSubTypeId, isArtifact)
    local objectId = object.id
    local objectTypeStr = mwse.longToString(objectTypeId)
    local objectSubTypeStr = tostring(objectSubTypeId)
    addItemTable(out, objectTypeStr, objectSubTypeStr)
    local gr = out.ItemGroups[objectTypeStr][objectSubTypeStr]
    gr.Count = gr.Count + 1
    local enchCost = magicEffectLib.getEnchantPower(object.enchantment)
    gr.MaxEnchCost = math.max(gr.MaxEnchCost, enchCost)
    local cost = object.value or 0
    gr.MaxCost = math.max(gr.MaxCost, cost)
    out.Items[objectId:lower()] = {EnchCost = enchCost, Cost = cost, Type = objectTypeStr, SubType = objectSubTypeStr,
        Position = gr.Count, IsArtifact = isArtifact}
    table.insert(gr.Items, objectId)
    if isArtifact == true then
        addItemTable(out, "ARTF", "0")
        local agr = out.ItemGroups["ARTF"]["0"]
        agr.Count = agr.Count + 1
        agr.MaxEnchCost = math.max(gr.MaxEnchCost, enchCost)
        agr.MaxCost = math.max(gr.MaxCost, object.value or 0)
        table.insert(agr.Items, objectId)
    end
end

function this.fillItems()
    local items = {data = {}, artf = {}}
    local out = {Items = {}, ItemGroups = {}}
    items.data[tes3.objectType.alchemy] = {}
    items.data[tes3.objectType.ingredient] = {}
    items.data[tes3.objectType.apparatus] = {}
    items.data[tes3.objectType.armor] = {}
    items.data[tes3.objectType.book] = {}
    items.data[tes3.objectType.clothing] = {}
    items.data[tes3.objectType.lockpick] = {}
    items.data[tes3.objectType.probe] = {}
    items.data[tes3.objectType.repairItem] = {}
    items.data[tes3.objectType.weapon] = {}
    items.data[tes3.objectType.ammunition] = {}

    log("Item list generation...")
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if items.data[object.objectType] ~= nil and genData.checkRequirementsForItem(object) and
                (object.script == nil or scriptWhiteList[object.script.id]) and object.weight > 0 then
            table.insert(items.data[object.objectType], object)
        end
    end

    for objType, data in pairs(items.data) do
        table.sort(data, function(a, b) return a.value < b.value end)
    end


    for i, object in ipairs(items.data[tes3.objectType.book]) do
        local objSubType = 1
        if object.type then
            objSubType = object.type
        elseif object.slot then
            objSubType = object.slot
        end

        if object.enchantment ~= nil or object.skill ~= -1 then
            addItemToTable(out, object, tes3.objectType.book, objSubType)
        end
    end
    for typeId, data in pairs(items.data) do
        if typeId ~= tes3.objectType.book then
            for i, object in ipairs(data) do
                local objSubType = 1
                if object.type then
                    objSubType = object.type
                elseif object.slot then
                    objSubType = object.slot
                end

                if (typeId ~= tes3.objectType.armor or typeId ~= tes3.objectType.clothing) and object.enchantment ~= nil then
                    local forbidden = false
                    for i, effect in pairs(object.enchantment.effects) do
                        if forbiddenEffectsIds[effect.id] then
                            forbidden = true
                        end
                    end
                    if not forbidden then
                        addItemToTable(out, object, typeId, objSubType, obtainableArtifacts[object.id:lower()] == true)
                    end
                else
                    addItemToTable(out, object, typeId, objSubType, obtainableArtifacts[object.id:lower()] == true)
                end
            end
        end
    end

    for type, data in pairs(out.ItemGroups) do
        for subType, gr in pairs(data) do
            log("Item type %s, item subtype %s, count %s", type, subType, gr.Count)
        end
    end

    return out
end

function this.fillCreatures()
    local creatures = {}
    local out = {Creatures = {}, CreatureGroups = {}}

    log("Creature list generation...")
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        local idLow = object.id:lower()
        if object ~= nil and object.objectType == tes3.objectType.creature and not object.deleted and not object.isEssential and
                (object.script == nil or scriptWhiteList[object.script.id] or string.find(object.script.id, "^disease[A-Z].+")) and
                not string.find(idLow, "kwama queen_") and not string.find(idLow, ".+_summon") and
                not forbiddenIds[object.id] and object.name ~= "<Deprecated>" and object.health > 0 and
                object.mesh and tes3.getFileSource("Meshes\\"..object.mesh) and not forbiddenModels[object.mesh:lower()] then

            local objSubType = object.type
            if object.swims then
                objSubType = 4
            end
            if creatures[objSubType] == nil then creatures[objSubType] = {} end
            table.insert(creatures[objSubType], object)
        end
    end
    for objType, data in pairs(creatures) do
        table.sort(data, function(a, b) return a.level < b.level end)
    end

    for subType, data in pairs(creatures) do
        for i, object in ipairs(data) do
            if not out.CreatureGroups[tostring(subType)] then
                out.CreatureGroups[tostring(subType)] = {Count = 0, Items = {}}
            end
            local gr = out.CreatureGroups[tostring(subType)]
            gr.Count = gr.Count + 1
            table.insert(gr.Items, object.id)
            out.Creatures[object.id:lower()] = {SubType = tostring(subType), Position = gr.Count}
        end
    end

    for subType, data in pairs(out.CreatureGroups) do
        log("Creture type %s, count %s", subType, data.Count)
    end

    return out
end

function this.fillHeadsHairs()
    local data = {}
    local out = {Parts = {}, List = {}}

    log("Bodypart list generation...")
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object ~= nil and object.objectType == tes3.objectType.bodyPart and not object.deleted and object.raceName and
                object.partType == tes3.activeBodyPartLayer.base and object.part <= 1 and
                object.mesh and tes3.getFileSource("Meshes\\"..object.mesh) and not forbiddenModels[object.mesh:lower()] and
                not forbiddenIds[object.id] then

            local raceLow = object.raceName:lower()
            if data[raceLow] == nil then data[raceLow] = {} end
            if data[raceLow][object.part] == nil then data[raceLow][object.part] = {} end
            table.insert(data[raceLow][object.part], object)
        end
    end

    for raceName, dt in pairs(data) do
        for partId, objectArr in pairs(dt) do
            local partIdStr = tostring(partId)
            if out.List[partIdStr] == nil then out.List[partIdStr] = {} end
            if not out.Parts[raceName] then out.Parts[raceName] = {} end
            if not out.Parts[raceName][partIdStr] then out.Parts[raceName][partIdStr] = {} end
            for _, object in pairs(objectArr) do
                local femaleId = 0
                if object.female then femaleId = 1 end
                local femaleIdStr = tostring(femaleId)
                if not out.Parts[raceName][partIdStr][femaleIdStr] then out.Parts[raceName][partIdStr][femaleIdStr] = {} end

                table.insert(out.Parts[raceName][partIdStr][femaleIdStr], object.id)
                out.List[partIdStr][object.id:lower()] = true
            end
        end
    end

    log("Bodypart list generation comleted.")
    return out
end

function this.fillSpells()
    local spells = {}
    local out = {Spells = {}, SpellGroups = {}, TouchRange = {}}

    log("Spell list generation...")
    for _, object in pairs(tes3.dataHandler.nonDynamicData.spells) do
        if object ~= nil and not object.deleted and object.effects then
            if spells[object.castType] == nil then spells[object.castType] = {} end

            local baseCost = 0
            local effectCount = 0
            for _, effect in pairs(object.effects) do
                if effect.id >= 0 then
                    baseCost = baseCost + magicEffectLib.calculateEffectCost(effect)
                    effectCount = effectCount + 1
                end
            end
            if effectCount > 0 then
                table.insert(spells[object.castType], {object = object, cost = baseCost})
            end
        end
    end
    for objType, data in pairs(spells) do
        table.sort(data, function(a, b) return a.cost < b.cost end)
    end

    for ctype, dt in pairs(spells) do
        for _, data in ipairs(dt) do
            local idLow = data.object.id:lower()
            local object = data.object
            local effectsExistion = {}
            local isTouch = false
            local containsForbiddenEffect = false
            for _, effect in pairs(object.effects) do
                local id = skillByEffectId[effect.id]
                if id then
                    effectsExistion[id] = true
                    if effect.rangeType == tes3.effectRange.touch then isTouch = true end
                    if forbiddenEffectsIds[effect.id] then containsForbiddenEffect = true end
                end
            end
            if not (containsForbiddenEffect and (ctype == tes3.spellType.disease or ctype == tes3.spellType.blight or tes3.spellType.ability)) then
                out.Spells[idLow] = {}
                if isTouch then out.TouchRange[idLow] = {} end
                for schoolId, _ in pairs(effectsExistion) do
                    local id = schoolId

                    if ctype == tes3.spellType.ability then id = 200
                    elseif ctype == tes3.spellType.disease or ctype == tes3.spellType.blight then id = 201 end

                    if out.SpellGroups[tostring(id)] == nil then out.SpellGroups[tostring(id)] = {Count = 0, Items = {}} end
                    local gr = out.SpellGroups[tostring(id)]
                    gr.Count = gr.Count + 1
                    table.insert(gr.Items, data.object.id)
                    table.insert(out.Spells[idLow], {SubType = id, Position = gr.Count})

                    if isTouch then
                        id = id + 100
                        if out.SpellGroups[tostring(id)] == nil then out.SpellGroups[tostring(id)] = {Count = 0, Items = {}} end
                        gr = out.SpellGroups[tostring(id)]
                        gr.Count = gr.Count + 1
                        table.insert(gr.Items, data.object.id)
                        table.insert(out.TouchRange[idLow], {SubType = id, Position = gr.Count})
                    end
                end
            end
        end
    end

    for subType, data in pairs(out.SpellGroups) do
        log("Spell type %s, count %s", subType, data.Count)
    end

    return out
end

function this.fillHerbs()
    local data = {}
    local out = {Herbs = {}, HerbsObjectList = {}}

    log("Herb list generation...")
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object ~= nil and object.objectType == tes3.objectType.container and (object.script == nil or scriptWhiteList[object.script.id]) and
                not object.deleted and object.organic and object.respawns and object.capacity < 5 and
                not string.find(object.id, "^T_Mw_Mine+") and object.mesh and tes3.getFileSource("Meshes\\"..object.mesh) and
                not forbiddenModels[object.mesh:lower()] then

            table.insert(data, object)
        end
    end

    local pos = 0
    for _, object in pairs(data) do
        pos = pos + 1
        local idLow = object.id:lower()
        out.Herbs[idLow] = {Offset = herbsOffsets[idLow] or 0, Position = pos}

        table.insert(out.HerbsObjectList, object.id)
    end
    out.HerbsListCount = pos

    log("Herb list generation comleted.")
    return out
end

local function isValidDestination(destination)
    if destination == nil or destination.marker == nil then return false end
    local pos = destination.marker.position
    local rot = destination.marker.orientation
    return not (pos == nil or rot == nil or (pos.x == 0 and pos.y == 0 and pos.z == 0 and rot.x == 0 and rot.y == 0 and rot.z == 0))
end

function this.findTravelDestinations()
    log("Travel destinations list generation...")
    local out = {}

    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object ~= nil and (object.objectType == tes3.objectType.npc or object.objectType == tes3.objectType.creature) and not object.deleted and
                object.aiConfig and object.aiConfig.travelDestinations then
            for _, dest in pairs(object.aiConfig.travelDestinations) do
                if isValidDestination(dest) and not forbiddenIds[dest.cell.id] then
                    local newDest = {marker = {position = dest.marker.position, orientation = dest.marker.orientation}, cell = dest.cell}
                    table.insert(out, newDest)
                end
            end
        end
    end

    log("Travel destinations Count = %i", #out)
    return out
end

function this.fingLandTextures()
    log("Land testures list generation...")
    local out = {Textures = {}, Groups = {}}
    local count = 0
    for _, texture in pairs(tes3.dataHandler.nonDynamicData.landTextures) do
        if texture.filename and tes3.getFileSource("Textures\\"..texture.filename) then
            local textureType = 0
            if (texture.id:find("road") or texture.id:find("ash_04") or texture.id:find("mudflats_01") or
                    texture.id:find("ma_crackedearth")) then
                textureType = 9
            elseif (texture.id:find("ice")) then textureType = 10
            elseif (texture.id:find("grass") or texture.id:find("clover") or texture.id:find("scrub")) then textureType = 1
            elseif (texture.id:find("sand")) then textureType = 2
            elseif (texture.id:find("rock") or texture.id:find("stone")) then textureType = 6
            elseif (texture.id:find("dirt") or texture.id:find("mud") or texture.id:find("muck")) then textureType = 3
            -- elseif (texture.id:find("snow")) then textureType = 4
            elseif (texture.id:find("ash")) then textureType = 5
            elseif (texture.id:find("gravel")) then textureType = 7
            elseif (texture.id:find("lava")) then textureType = 8
            end

            out.Textures[texture.index] = {Type = textureType}
            if out.Groups[textureType] == nil then out.Groups[textureType] = {} end
            table.insert(out.Groups[textureType], texture.index)
            count = count + 1
        end
    end
    log("Land testures list generation Count = %i", count)
    return out
end

function this.generateRandomizedLandscapeTextureIndices()
    local textures = {}
    local textures1 = this.fingLandTextures()
    for i, val in pairs(textures1.Textures) do
        local id = math.random(1, #textures1.Groups[val.Type])
        textures[tostring(i)] = textures1.Groups[val.Type][id]
        table.remove(textures1.Groups[val.Type], id)
    end
    return textures
end

this.itemTypeWhiteList = {
    [tes3.objectType.alchemy] = true,
    [tes3.objectType.ingredient] = true,
    [tes3.objectType.apparatus] = true,
    [tes3.objectType.armor] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.lockpick] = true,
    [tes3.objectType.probe] = true,
    [tes3.objectType.repairItem] = true,
    [tes3.objectType.weapon] = true,
    [tes3.objectType.miscItem] = true,
    [tes3.objectType.ammunition] = true,
    [tes3.objectType.light] = true,
}

---@class mwr.generator.partsDataStruct
---@field [1] integer
---@field [2] string
---@field [3] string

---@class mwr.generator.partsStruct
---@field mesh string
---@field parts mwr.generator.partsDataStruct[]

---@class mwr.generator.enchantment.group
---@field Items string[] enchantment ids
---@field Max95 number 95% median value of an enchantment cost in this group
---@field Max number the max value of an enchantment cost in this group

---@class mwr.generator.itemGroup
---@field items table
---@field meshes table
---@field arrowMeshes table|nil
---@field boltMeshes table|nil
---@field enchantValues table<string, number> index - item id
---@field maxValue number
---@field medianValue number
---@field medianEnchant number
---@field enchant90 number
---@field enchant95 number
---@field values number[10]
---@field maxEnchant number
---@field bowMeshes table
---@field crossbowMeshes table

---@class mwr.generator.enchantmentGroup
---@field Items table<string, integer> index - lower enchantment id, value - position in Groups[enchantmentType].Items
---@field Groups table<tes3.enchantmentType, mwr.generator.enchantment.group>

---@class mwr.itemStatsData
---@field parts table<tes3.objectType, table<integer, table< integer, mwr.generator.partsStruct>>>
---@field itemGroup table<tes3.objectType, mwr.generator.itemGroup>
---@field enchantments mwr.generator.enchantmentGroup

---@return mwr.itemStatsData
function this.generateItemData()
    local items = {}
    local enchantments = {[tes3.enchantmentType.castOnce] = {}, [tes3.enchantmentType.onStrike] = {}, [tes3.enchantmentType.onUse] = {},
        [tes3.enchantmentType.constant] = {},}
    local out = {parts = {}, itemGroup = {}, enchantments = {Items = {}, Groups = {}}}
    for itType, val in pairs(this.itemTypeWhiteList) do
        if val then
            items[itType] = {}
        end
    end

    log("Item data generation...")
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object.objectType == tes3.objectType.enchantment then
            table.insert(enchantments[object.castType], {id = object.id, value = magicEffectLib.getEffectsPower(object.effects)})
        end
        if genData.checkRequirementsForItem(object) and items[object.objectType] ~= nil then

            table.insert(items[object.objectType], object)

            if object.parts then
                local data = {}
                for _, part in pairs(object.parts) do
                    if part.type ~= 255 then
                        local female
                        local male
                        if part.female ~= nil and not part.female.deleted and not part.female.disabled and
                                tes3.getFileSource("meshes\\"..part.female.mesh) then
                            female = part.female.id
                        end
                        if part.male ~= nil and not part.male.deleted and not part.male.disabled and
                                tes3.getFileSource("meshes\\"..part.male.mesh) then
                            male = part.male.id
                        end
                        if female or male then table.insert(data, {part.type, female, male}) end
                    end
                end
                local objSubType = 0
                if object.type then
                    objSubType = object.type
                elseif object.slot then
                    objSubType = object.slot
                end
                if not out.parts[object.objectType] then out.parts[object.objectType] = {} end
                if not out.parts[object.objectType][objSubType] then out.parts[object.objectType][objSubType] = {} end
                if #data > 0 then table.insert(out.parts[object.objectType][objSubType], {mesh = object.mesh, parts = data}) end
            end
        end
    end

    for enchType, data in pairs(enchantments) do
        table.sort(data, function(a, b) return a.value < b.value end)
        out.enchantments.Groups[enchType] = {Items = {}, Max95 = data[math.floor(#data * 0.95)].value, Max = data[#data].value}
        local enchTable = out.enchantments.Groups[enchType].Items
        local pos = 1
        for i, ench in ipairs(data) do
            table.insert(enchTable, ench.id)
            out.enchantments.Items[ench.id:lower()] = pos
            pos = pos + 1
        end
    end

    for objType, data in pairs(items) do
        table.sort(data, function(a, b) return a.value < b.value end)
        local meshes = {}
        local bowMeshes = {}
        local crossbowMeshes = {}
        local enchantVals = {0,}
        local enchValData = {}
        for i, item in pairs(data) do
            local enchVal = 0
            if item.enchantment then
                enchVal = magicEffectLib.getEffectsPower(item.enchantment.effects)
            elseif objType == tes3.objectType.alchemy then
                enchVal = magicEffectLib.getEffectsPower(item.effects)
            end
            if enchVal > 0 then
                table.insert(enchantVals, enchVal)
                enchValData[item.id] = enchVal
            end

            if item.mesh then
                if objType == tes3.objectType.weapon and item.type == tes3.weaponType.marksmanBow then
                    bowMeshes[item.mesh] = true
                elseif objType == tes3.objectType.weapon and item.type == tes3.weaponType.marksmanCrossbow then
                    crossbowMeshes[item.mesh] = true
                else
                    meshes[item.mesh] = true
                end
            end
        end
        local meshList = {}
        for mesh, _ in pairs(meshes) do
            table.insert(meshList, mesh)
        end
        local bowMeshList = {}
        for mesh, _ in pairs(bowMeshes) do
            table.insert(bowMeshList, mesh)
        end
        local crossbowMeshList = {}
        for mesh, _ in pairs(crossbowMeshes) do
            table.insert(crossbowMeshList, mesh)
        end
        local arrowMeshes = nil
        local boltMeshes = nil
        if objType == tes3.objectType.ammunition then
            arrowMeshes = {}
            boltMeshes = {}
            local addMesh = function(mesh)
                if mesh and tes3.getFileSource("meshes\\"..mesh) then
                    local ms = tes3.loadMesh(mesh)
                    local boundingBox = ms:createBoundingBox()
                    if boundingBox.min.y <= -55 then
                        table.insert(arrowMeshes, mesh)
                    elseif boundingBox.min.y >= -35 and boundingBox.min.y <= -17 then
                        table.insert(boltMeshes, mesh)
                    end
                end
            end
            for i, item in pairs(items[tes3.objectType.weapon]) do
                addMesh(item.mesh)
            end
            for i, mesh in pairs(meshList) do
                addMesh(mesh)
            end
        end
        table.sort(enchantVals)
        local values = {}
        for i = 1, 10 do
            table.insert(values, data[math.max(math.min(math.floor(#data * i * 0.1), #data), 1)].value or 0)
        end
        out.itemGroup[objType] = {
            items = data, meshes = meshList, enchantValues = enchValData, maxValue = data[#data].value,
            medianValue = data[math.floor(#data / 2)].value,
            maxEnchant = enchantVals[#enchantVals], medianEnchant = enchantVals[math.floor(#enchantVals / 2)],
            enchant90 = enchantVals[math.floor(#enchantVals * 0.9)] or 0,
            enchant95 = enchantVals[math.floor(#enchantVals * 0.95)] or 0,
            values = values,
            bowMeshes = #bowMeshList > 0 and bowMeshList or nil, crossbowMeshes = #crossbowMeshList > 0 and crossbowMeshList or nil,
            arrowMeshes = arrowMeshes, boltMeshes = boltMeshes,
        }
    end

    log("Item data generation comleted")
    return out
end

function this.fillFlora()
    local data = {}
    local out = {Data = {}, Groups = {}}
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object then
            local id = object.id:lower()
            if object.objectType == tes3.objectType.static and object.mesh and tes3.getFileSource("Meshes\\"..object.mesh) and
                    not forbiddenModels[object.mesh:lower()] and (id:find("grass") or id:find("bush") or id:find("flora")) and
                    not (id:find("tree") or id:find("log") or id:find("menhir") or id:find("root") or id:find("parasol") or id:find("rock") or
                    id:find("plane")) then
                local str = ((id:gsub("[_ ]", "") or ""):match(".+%d+") or ""):match("%a+")
                if str then
                    if not data[str] then data[str] = {} end
                    table.insert(data[str], object)
                end
            end
        end
    end
    for _, gr in pairs(data) do
        local ids = {}
        for _, object in pairs(gr) do
            local id = object.id:lower()
            if object.mesh and tes3.getFileSource("meshes\\"..object.mesh) then
                local ms = tes3.loadMesh(object.mesh)
                if ms then
                    local boundingBox = ms:createBoundingBox()
                    local l = math.max(math.abs(boundingBox.max.x - boundingBox.min.x), math.abs(boundingBox.max.y - boundingBox.min.y))
                    if l < 250 then
                        out.Data[id] = {Offset = -boundingBox.min.z - math.abs((boundingBox.max.z - boundingBox.min.z) * 0.05), Radius = l / 2}
                        table.insert(ids, id)
                    end
                end
            end
        end
        if #ids > 0 then
            table.insert(out.Groups, ids)
        end
    end
    return out
end

function this.fillRocks()
    local data = {}
    local out = {Data = {}, Groups = {}}
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object then
            local id = object.id:lower()
            if object.objectType == tes3.objectType.static and object.mesh and tes3.getFileSource("meshes\\"..object.mesh) and (genData.staticWhiteList[id] or
                    not forbiddenModels[object.mesh:lower()] and (id:find("rock") or id:find("menhir")) and not (id:find("grass") or id:find("bush") or id:find("flora") or
                    id:find("log") or id:find("root") or id:find("tree") or id:find("parasol") or id:find("entr") or
                    id:find("plane"))) then
                local str = ((id:gsub("[_ ]", "") or ""):match(".+%d+") or ""):match("%a+")
                if str then
                    if not data[str] then data[str] = {} end
                    table.insert(data[str], object)
                end
            end
        end
    end
    for _, gr in pairs(data) do
        local ids = {}
        for _, object in pairs(gr) do
            local id = object.id:lower()
            local ms = tes3.loadMesh(object.mesh)
            if ms then
                local boundingBox = ms:createBoundingBox()
                local l = math.max(math.abs(boundingBox.max.x - boundingBox.min.x), math.abs(boundingBox.max.y - boundingBox.min.y))
                if l < 1200 then
                    local r = 0
                    local rest = tes3.rayTest {
                        position = tes3vector3.new(0, 0, 0),
                        direction = tes3vector3.new(0, 0, 1),
                        useModelCoordinates = true,
                        root = ms,
                        useBackTriangles = true,
                        maxDistance = 0,
                    }
                    local res = tes3.rayTest {
                        position = tes3vector3.new(0, 0, 0),
                        direction = tes3vector3.new(0, 0, -1),
                        useModelCoordinates = true,
                        root = ms,
                        useBackTriangles = true,
                        maxDistance = 0,
                    }
                    if not res or rest then
                        r = r + 3
                        res = tes3.rayTest {
                            position = tes3vector3.new(0, 0, 0),
                            direction = tes3vector3.new(0, 1, 0),
                            useModelCoordinates = true,
                            root = ms,
                            useBackTriangles = true,
                            maxDistance = 0,
                        }
                        if res then r = r + 1 end
                        res = tes3.rayTest {
                            position = tes3vector3.new(0, 0, 0),
                            direction = tes3vector3.new(0, -1, 0),
                            useModelCoordinates = true,
                            root = ms,
                            useBackTriangles = true,
                            maxDistance = 0,
                        }
                        if res then r = r + 1 end
                        res = tes3.rayTest {
                            position = tes3vector3.new(0, 0, 0),
                            direction = tes3vector3.new(-1, 0, 0),
                            useModelCoordinates = true,
                            root = ms,
                            useBackTriangles = true,
                            maxDistance = 0,
                        }
                        if res then r = r + 1 end
                        res = tes3.rayTest {
                            position = tes3vector3.new(0, 0, 0),
                            direction = tes3vector3.new(1, 0, 0),
                            useModelCoordinates = true,
                            root = ms,
                            useBackTriangles = true,
                            maxDistance = 0,
                        }
                        if res then r = r + 1 end
                    end
                    if r > 6 or genData.staticWhiteList[id] then
                        out.Data[id] = {Offset = -boundingBox.min.z - math.abs((boundingBox.max.z - boundingBox.min.z) * 0.1), Radius = l / 2}
                        table.insert(ids, id)
                    end
                end
            end
        end
        if #ids > 0 then
            table.insert(out.Groups, ids)
        end
    end
    return out
end

function this.fillTrees()
    local data = {}
    local out = {Data = {}, Groups = {}}
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object then
            local id = object.id:lower()
            if object.objectType == tes3.objectType.static and object.mesh and tes3.getFileSource("meshes\\"..object.mesh) and (genData.staticWhiteList[id] or
                    not forbiddenModels[object.mesh:lower()] and (id:find("tree") or id:find("parasol")) and not (id:find("rock") or id:find("plane") or
                    id:find("log"))) then
                local str = ((id:gsub("[_ ]", "") or ""):match(".+%d+") or ""):match("%a+")
                if str then
                    if not data[str] then data[str] = {} end
                    table.insert(data[str], object)
                end
            end
        end
    end
    for _, gr in pairs(data) do
        local ids = {}
        for _, object in pairs(gr) do
            local id = object.id:lower()
            local ms = tes3.loadMesh(object.mesh)
            if ms then
                local boundingBox = ms:createBoundingBox()
                if boundingBox then
                    local l = math.max(math.abs(boundingBox.max.x - boundingBox.min.x), math.abs(boundingBox.max.y - boundingBox.min.y))
                    out.Data[id] = {Offset = -boundingBox.min.z - math.abs((boundingBox.max.z - boundingBox.min.z) * 0.1), Radius = l / 2}
                    table.insert(ids, id)
                end
            end
        end
        if #ids > 0 then
            table.insert(out.Groups, ids)
        end
    end
    return out
end

function this.rebuildRocksTreesData(data)
    if not data then return end
    local out = {Data = {}, Groups = {}}
    local arr
    if data.RocksOffset then
        arr = data.RocksOffset
    elseif data.TreesOffset then
        arr = data.TreesOffset
    else
        arr = {}
    end
    for id, dt in pairs(arr) do
        local object = tes3.getObject(id)
        if object and object.mesh and tes3.getFileSource("meshes\\"..object.mesh) then
            local ms = tes3.loadMesh(object.mesh)
            if ms then
                local boundingBox = ms:createBoundingBox()
                local r = math.max(math.abs(boundingBox.max.x - boundingBox.min.x), math.abs(boundingBox.max.y - boundingBox.min.y)) / 2
                local offset = dt.Offset
                if offset == 0 or not offset then
                    offset = -boundingBox.min.z - (boundingBox.max.z - boundingBox.min.z) * 0.05
                end
                out.Data[id] = {Offset = offset, Radius = r}
            end
        end
    end
    local grpArr
    if data.RocksGroups then
        grpArr = data.RocksGroups
    elseif data.TreesGroups then
        grpArr = data.TreesGroups
    else
        grpArr = {}
    end
    for i, dt in pairs(grpArr) do
        if dt.Items and #dt.Items > 0 then
            table.insert(out.Groups, dt.Items)
        end
    end
    return out
end

function this.correctStaticsData(data)
    for id, _ in pairs(data.Data) do
        local object = tes3.getObject(id)
        if not object then
            data.Data[id] = nil
        end
    end
    local newGroups = {}
    for _, grp in pairs(data.Groups) do
        local newGrp = {}
        for _, id in pairs(grp) do
            if data.Data[id:lower()] then
                table.insert(newGrp, id)
            end
        end
        if #newGrp > 0 then
            table.insert(newGroups, newGrp)
        end
    end
    data.Groups = newGroups
end

return this