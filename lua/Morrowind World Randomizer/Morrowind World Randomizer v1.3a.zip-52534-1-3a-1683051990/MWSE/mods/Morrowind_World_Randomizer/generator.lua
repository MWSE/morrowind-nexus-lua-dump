local log = include("Morrowind_World_Randomizer.log")
local magicEffectLib = include("Morrowind_World_Randomizer.magicEffect")
local itemLib = include("Morrowind_World_Randomizer.item")
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
    local enchCost = itemLib.getEnchantPower(object.enchantment)
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

return this