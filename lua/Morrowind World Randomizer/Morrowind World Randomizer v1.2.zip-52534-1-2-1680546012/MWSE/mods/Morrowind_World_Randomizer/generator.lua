local log = include("Morrowind_World_Randomizer.log")

local this = {}

local forbiddenEffectsIds = { -- for abilities and diseases
    [14] = true,
    [15] = true,
    [16] = true,
    [22] = true,
    [23] = true,
    [24] = true,
    [25] = true,
    [26] = true,
    [27] = true,
    [132] = true,
    [133] = true,
    [135] = true,
}

local forbiddenIds = {
    ["war_axe_airan_ammu"] = true,
    ["shadow_shield"] = true,
    ["bonebiter_bow_unique"] = true,
    ["heart_of_fire"] = true,
    ["T_WereboarRobe"] = true,
    ["WerewolfRobe"] = true,


    ["vivec_god"] = true,
    ["wraith_sul_senipul"] = true,

    ["ToddTest"] = true,

    ["WerewolfHead"] = true,
}

local forbiddenModels = { -- lowercase
    ["pc\\f\\pc_help_deprec_01.nif"] = true,
}

local scriptWhiteList = {
    ["LegionUniform"] = true,
    ["OrdinatorUniform"] = true,
}

local obtainableArtifacts = {["boots_apostle_unique"]=true,["tenpaceboots"]=true,["cuirass_savior_unique"]=true,["dragonbone_cuirass_unique"]=true,["lords_cuirass_unique"]=true,["daedric_helm_clavicusvile"]=true,["ebony_shield_auriel"]=true,["towershield_eleidon_unique"]=true,["spell_breaker_unique"]=true,["ring_vampiric_unique"]=true,["ring_warlock_unique"]=true,["warhammer_crusher_unique"]=true,["staff_hasedoki_unique"]=true,["staff_magnus_unique"]=true,["ebony_bow_auriel"]=true,["longbow_shadows_unique"]=true,["claymore_chrysamere_unique"]=true,["claymore_iceblade_unique"]=true,["longsword_umbra_unique"]=true,["dagger_fang_unique"]=true,["mace of slurring"]=true,["robe_lich_unique"]=true,}

local skillByEffectId = {[0]=11,[1]=11,[2]=11,[3]=11,[4]=11,[5]=11,[6]=11,[7]=11,[8]=11,[9]=11,[10]=11,[11]=11,[12]=11,[13]=11,[14]=10,[15]=10,[16]=10,[17]=10,[18]=10,[19]=10,[20]=10,[21]=10,[22]=10,[23]=10,[24]=10,[25]=10,[26]=10,[27]=10,[28]=10,[29]=10,[30]=10,[31]=10,[32]=10,[33]=10,[34]=10,[35]=10,[36]=10,[37]=10,[38]=10,[39]=12,[40]=12,[41]=12,[42]=12,[43]=12,[44]=12,[45]=12,[46]=12,[47]=12,[48]=12,[49]=12,[50]=12,[51]=12,[52]=12,[53]=14,[54]=12,[55]=12,[56]=12,[57]=14,[58]=14,[59]=14,[60]=14,[61]=14,[62]=14,[63]=14,[64]=14,[65]=14,[66]=14,[67]=14,[68]=14,[69]=15,[70]=15,[71]=15,[72]=15,[73]=15,[74]=15,[75]=15,[76]=15,[77]=15,[78]=15,[79]=15,[80]=15,[81]=15,[82]=15,[83]=15,[84]=15,[85]=14,[86]=14,[87]=14,[88]=14,[89]=14,[90]=15,[91]=15,[92]=15,[93]=15,[94]=15,[95]=15,[96]=15,[97]=15,[98]=15,[99]=15,[100]=15,[101]=13,[102]=13,[103]=13,[104]=13,[105]=13,[106]=13,[107]=13,[108]=13,[109]=13,[110]=13,[111]=13,[112]=13,[113]=13,[114]=13,[115]=13,[116]=13,[117]=15,[118]=13,[119]=13,[120]=13,[121]=13,[122]=13,[123]=13,[124]=13,[125]=13,[126]=13,[127]=13,[128]=13,[129]=13,[130]=13,[131]=13,[132]=10,[133]=10,[134]=13,[135]=10,[136]=10,[137]=nil,[138]=13,[139]=13,[140]=13,}

local herbsOffsets = {["flora_bittergreen_07"]=70,["flora_bittergreen_06"]=40,["flora_bittergreen_08"]=50,["flora_bittergreen_09"]=60,["flora_bittergreen_10"]=50,["flora_sedge_01"]=25,["flora_sedge_02"]=25,["flora_kreshweed_02"]=120,["flora_green_lichen_02"]=0,["flora_green_lichen_01"]=5,["flora_ash_yam_02"]=10,["flora_muckspunge_01"]=80,["flora_kreshweed_01"]=80,["flora_muckspunge_05"]=110,["flora_muckspunge_06"]=100,["flora_muckspunge_02"]=90,["flora_ash_yam_01"]=20,["flora_kreshweed_03"]=90,["flora_muckspunge_04"]=80,["flora_muckspunge_03"]=80,["flora_stoneflower_02"]=45,["flora_marshmerrow_02"]=60,["flora_bc_mushroom_07"]=0,["flora_marshmerrow_03"]=70,["flora_saltrice_01"]=50,["flora_bc_mushroom_06"]=10,["flora_saltrice_02"]=50,["flora_bc_mushroom_05"]=15,["flora_wickwheat_01"]=40,["flora_bc_mushroom_03"]=15,["flora_wickwheat_03"]=20,["flora_wickwheat_04"]=25,["flora_bc_shelffungus_03"]=0,["flora_bc_shelffungus_04"]=0,["flora_bc_shelffungus_02"]=0,["flora_chokeweed_02"]=100,["flora_roobrush_02"]=30,["flora_marshmerrow_01"]=70,["flora_wickwheat_02"]=20,["flora_bc_mushroom_01"]=15,["flora_bc_shelffungus_01"]=0,["flora_stoneflower_01"]=40,["flora_plant_05"]=30,["flora_black_lichen_02"]=5,["flora_plant_02"]=30,["flora_black_lichen_01"]=5,["flora_plant_03"]=20,["flora_plant_06"]=30,["flora_plant_08"]=-10,["flora_plant_07"]=5,["flora_fire_fern_01"]=30,["flora_fire_fern_03"]=20,["flora_black_anther_02"]=20,["flora_bc_podplant_01"]=10,["flora_fire_fern_02"]=20,["flora_bc_podplant_02"]=10,["flora_heather_01"]=5,["flora_rm_scathecraw_02"]=70,["flora_comberry_01"]=50,["flora_rm_scathecraw_01"]=100,["flora_bc_mushroom_02"]=15,["flora_bc_mushroom_04"]=15,["flora_bc_mushroom_08"]=10,["flora_plant_04"]=20,["flora_bc_fern_01"]=70,["flora_black_anther_01"]=50,["flora_gold_kanet_01"]=30,["flora_bm_belladonna_01"]=30,["flora_corkbulb"]=0,["flora_bm_belladonna_02"]=30,["flora_gold_kanet_02"]=30,["flora_bittergreen_01"]=60,["flora_bm_holly_02"]=160,["flora_bm_holly_04"]=160,["flora_bm_holly_01"]=160,["flora_bm_holly_05"]=160,["flora_gold_kanet_02_uni"]=30,["flora_bm_belladonna_03"]=30,["flora_bm_wolfsbane_01"]=25,["tramaroot_04"]=40,["flora_bittergreen_04"]=20,["tramaroot_05"]=30,["flora_bittergreen_05"]=50,["tramaroot_03"]=45,["flora_bittergreen_02"]=50,["tramaroot_02"]=85,["flora_willow_flower_01"]=40,["flora_willow_flower_02"]=30,["flora_bittergreen_03"]=80,["contain_trama_shrub_05"]=140,["contain_trama_shrub_01"]=120,["flora_bc_podplant_03"]=10,["flora_bc_podplant_04"]=10,["flora_red_lichen_01"]=5,["flora_red_lichen_02"]=5,["flora_hackle-lo_02"]=20,["flora_hackle-lo_01"]=20,["contain_trama_shrub_02"]=140,["tramaroot_01"]=50,["contain_trama_shrub_03"]=70,["contain_trama_shrub_04"]=120,["contain_trama_shrub_06"]=120,["kollop_01_pearl"]=5,["kollop_02_pearl"]=5,["kollop_03_pearl"]=5,}

local function addItemTable(out, objectTypeStr, objectSubTypeStr)
    if not out.ItemGroups[objectTypeStr] then out.ItemGroups[objectTypeStr] = {} end
    if not out.ItemGroups[objectTypeStr][objectSubTypeStr] then
        out.ItemGroups[objectTypeStr][objectSubTypeStr] = {Count = 0, Items = {}}
    end
end

local function addItemToTable(out, objectId, objectTypeId, objectSubTypeId, isArtifact)
    local objectTypeStr = mwse.longToString(objectTypeId)
    local objectSubTypeStr = tostring(objectSubTypeId)
    addItemTable(out, objectTypeStr, objectSubTypeStr)
    local gr = out.ItemGroups[objectTypeStr][objectSubTypeStr]
    gr.Count = gr.Count + 1
    out.Items[objectId:lower()] = {Type = objectTypeStr, SubType = objectSubTypeStr, Position = gr.Count, IsArtifact = isArtifact}
    table.insert(gr.Items, objectId)
    if isArtifact == true then
        addItemTable(out, "ARTF", "0")
        local agr = out.ItemGroups["ARTF"]["0"]
        agr.Count = agr.Count + 1
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
        if object ~= nil and not object.deleted and items.data[object.objectType] ~= nil and object.name ~= nil and object.name ~= "" and
                not forbiddenIds[object.id] and object.name ~= "<Deprecated>" and (object.icon == nil or object.icon ~= "default icon.dds") and
                object.weight > 0 and not forbiddenModels[(object.mesh or "err"):lower()] then

            if (object.script == nil or scriptWhiteList[object.script.id]) then
                table.insert(items.data[object.objectType], object)
            end

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
            addItemToTable(out, object.id, tes3.objectType.book, objSubType)
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
                        addItemToTable(out, object.id, typeId, objSubType, obtainableArtifacts[object.id:lower()] == true)
                    end
                else
                    addItemToTable(out, object.id, typeId, objSubType, obtainableArtifacts[object.id:lower()] == true)
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
                not forbiddenModels[(object.mesh or "err"):lower()] then

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
                object.partType == tes3.activeBodyPartLayer.base and object.part <= 1 and not forbiddenModels[(object.mesh or "err"):lower()] and
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
                if effect.id > 0 then
                    baseCost = baseCost + effect.cost
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
                not string.find(object.id, "^T_Mw_Mine+") and not forbiddenModels[(object.mesh or "err"):lower()] then

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