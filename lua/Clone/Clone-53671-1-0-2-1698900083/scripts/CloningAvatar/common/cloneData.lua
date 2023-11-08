local pathPrefix    = "Clone.scripts.CloningAvatar"
local omw, core     = pcall(require, "openmw.core")
local _, world      = pcall(require, "openmw.world")
local _, nearby     = pcall(require, "openmw.nearby")
local _, types      = pcall(require, "openmw.types")
local _, util       = pcall(require, "openmw.util")
local _, interfaces = pcall(require, "openmw.interfaces")
local _, async      = pcall(require, "openmw.async")
local _, storage    = pcall(require, "openmw.storage")
local actorSwap
local globalSettings
if omw then
    pathPrefix = "scripts.CloningAvatar"
    actorSwap = require(pathPrefix .. '.ActorSwap')
    local settingsGroup = 'SettingsClone'
    globalSettings = storage.globalSection(settingsGroup)
end
local config      = require(pathPrefix .. ".config")
local dataManager = require(pathPrefix .. ".common.dataManager")
local cloneData   = {}
local commonUtil  = {
}
function commonUtil.showInfoBox(msg)
    if omw then
        world.players[1]:sendEvent("showMessageBoxInfo", { msg = { msg }, buttons = { "OK" } })
    else
        local buttons = {
            {
                text = "OK",
                callback = function(e)

                end,
            },
        }
        tes3ui.showMessageMenu({ message = msg, buttons = buttons })
    end
end

local function is_single_letter(s)
    -- Check if the string has exactly one character and if that character is a letter
    return #s == 1 and s:match("[a-zA-Z]") ~= nil
end
function commonUtil.getKeyBindingChar()
    if not omw then
        local config = mwse.loadConfig("clone")
        local code = config.keybindClone.keyCode
        for key, value in pairs(tes3.scanCode) do
            if value == code then
                return key
            end
        end
    else
        local keyChar = globalSettings:get("keyBind")
        if keyChar ~= nil and is_single_letter(keyChar) then
            return keyChar
        else
            return 'k'
        end
    end
end

function commonUtil.delayedAction(callback, duration)
    if not omw then
        timer.start({ duration = duration, callback = callback })
    else
        async:newUnsavableSimulationTimer(duration, callback)
    end
end

local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(math.rad(z))
        return rotate
    end
end
local function getPlayer()
    if omw and world then
        return world.players[1]
    elseif omw and nearby then
        return nearby.players[1]
    elseif not omw then
        return tes3.getReference("player")
    end
end
function commonUtil.getActorId(actor)
    if omw then
        return actor.id
    else
        return actor.id
    end
end

local actor1Saved
local actor2Saved
local actor1EquipSaved = {}
local actor2EquipSaved = {}
local actor2DestCell
local actor2DestPos
local actor2DestRot
function commonUtil.makeActorWait(actorRef)
    if omw then
        actorRef:sendEvent("StartAIPackage", { type = "Wander", distance = 0 })
    else
        tes3.setAIWander({ reference = actorRef, idles = {} })
    end
end

function cloneData.makeAllClonesWait(actorRef)
    for index, value in pairs(cloneData.getCloneData()) do
        local ref = cloneData.getCloneObject(value.id)
        if ref.mobile then
            commonUtil.makeActorWait(ref.mobile)
        end
    end
    if omw then
        actorRef:sendEvent("StartAIPackage", { type = "Wander", distance = 0 })
    else
        tes3.setAIWander({ reference = actorRef, idles = {} })
    end
end

function commonUtil.removeActiveEffects(actorRef)
    if omw then

    else
        local effects = actorRef.mobile:getActiveMagicEffects()
        for key, value in pairs(effects) do
            if value.duration ~= 1 then
                tes3.removeEffects({ reference = actorRef, effect = value.effectId, })
            end
        end
    end
end

function cloneData.playerIsInClone()
    local data = cloneData.getCloneDataForNPC(getPlayer())
    if not data then return false end
    if data.cloneType == "RealPlayer" then return false end
    return true
end

function cloneData.savePlayerData()
    local actor1CD = cloneData.getCloneDataForNPC(getPlayer())
    if not actor1CD then
        print("Saved player data")
        return cloneData.markActorAsClone(getPlayer(), "RealPlayer")
    end
end

local function fixEncumbrance()
    local burden = tes3.getEffectMagnitude { reference = tes3.mobilePlayer, effect = tes3.effect.burden }
    local feather = tes3.getEffectMagnitude { reference = tes3.mobilePlayer, effect = tes3.effect.feather }
    local weight = tes3.player.object.inventory:calculateWeight() + burden - feather
    local oldWeight = tes3.mobilePlayer.encumbrance.currentRaw

    if (math.abs(oldWeight - weight) > 0.01) then
        -- logger:debug(string.format("Recalculating current encumbrance %.2f => %.2f", oldWeight, weight))
        tes3.setStatistic { reference = tes3.mobilePlayer, name = "encumbrance", current = weight }
    end
end
function cloneData.transferPlayerData(actor1, actor2, doTP, kill2)
    local check = dataManager.getValueOrInt("firstMessageGiven")
    if check == 2 then
        commonUtil.delayedAction(function()
            commonUtil.showInfoBox(
                "You are now using your first Clone as an Avatar. \nPress the " ..
                commonUtil.getKeyBindingChar() .. " key to open the menu again, to return to your original body.")
        end, 3
        )
        dataManager.setValue("firstMessageGiven", 3)
    end
    if check == 3 then
        commonUtil.delayedAction(function()
            commonUtil.showInfoBox(
                "You've returned to your own body. \nYou can exit the pod, or activate the switch to return to your created clone. \nYou can't switch between clones when you are in your own body, and outside of a clone pod.")
        end, 1
        )
        dataManager.setValue("firstMessageGiven", 4)
    end


    actor1Saved = actor1 --player
    actor2Saved = actor2
    actor1EquipSaved = {}
    actor2EquipSaved = {}
    local actor1id = commonUtil.getActorId(actor1)
    local actor2id = commonUtil.getActorId(actor2)

    local actor1CD = cloneData.getCloneDataForNPC(actor1)
    local actor2CD = cloneData.getCloneDataForNPC(actor2)
    if not actor1CD and actor1id == commonUtil.getActorId(getPlayer()) then
        print("Saved player data")
        cloneData.markActorAsClone(actor1, "RealPlayer")
        actor1CD = cloneData.getCloneDataForNPC(actor1)
    end
    local actor1IsInPod = actor1CD.occupiedPod == nil
    local actor2IsInPod = actor2CD.occupiedPod == nil
    if actor1CD and actor2CD then
        cloneData.setCloneDataForNPCID(actor1CD.id, actor2id)
        cloneData.setCloneDataForNPCID(actor2CD.id, actor1id)
    elseif not actor2 then
        error("No actor 2")
    elseif not actor1CD then
        error("Missing data for actor1")
    elseif not actor2CD then
        error("Missing data for actor2")
    end
    if omw then --Logic for OpenMW
        commonUtil.transferStats(actor1, actor2)
        local actor1Inv = {}
        local actor2Inv = {}
        local actor1Equip = types.Actor.getEquipment(actor1)
        local actor2Equip = types.Actor.getEquipment(actor2)

        for index, item in ipairs(types.Actor.inventory(actor1):getAll()) do
            table.insert(actor1Inv, item)
        end
        for index, item in ipairs(types.Actor.inventory(actor2):getAll()) do
            table.insert(actor2Inv, item)
        end
        for index, item in ipairs(actor1Inv) do
            if item.count > 0 then
                item:moveInto(actor2)
            end
        end
        for index, item in ipairs(actor2Inv) do
            if item.count > 0 then
                item:moveInto(actor1)
            end
        end
        actor1:sendEvent("CA_setEquipment", actor2Equip)
        actor2:sendEvent("CA_setEquipment", actor1Equip)
        if doTP ~= false then
            local actor1pos = actor1.position
            local actor1cell = actor1.cell
            local actor1rot = actor1.rotation
            local actor2pos = actor2.position
            local actor2cell = actor2.cell
            local actor2rot = actor2.rotation
            if actor2IsInPod then
                actor1rot = createRotation(0, 0, -90)
            end
            if actor1IsInPod then
                actor2rot = createRotation(0, 0, -90)
            end
            if actor2cell ~= nil then
                actor1:teleport(actor2cell, actor2pos, actor2rot)
            end
            actor2:teleport(actor1cell, actor1pos, actor1rot)
        end
        cloneData.makeAllClonesWait()
--        commonUtil.makeActorWait(actor2)
        actor1:sendEvent("setplayerCurrentCloneType", actor2CD.cloneType)
        cloneData.updateClonedataLocation(actor1, actor2)
        cloneData.updateClonedataLocation(actor2, actor1)
        return { actor1 = actor1, actor2 = actor2 }
    else --Logic for MWSE
        local actor1pos  = tes3vector3.new(actor1.position.x, actor1.position.y, actor1.position.z)
        local actor1cell = actor1.cell.name
        local actor1rot  = actor1.orientation:copy()

        if actor1IsInPod then
            actor1rot = tes3vector3.new(0, 0, math.rad(-90))
        end
        local actor2DestPos = tes3vector3.new(actor2.position.x, actor2.position.y, actor2.position.z)
        local actor2cell    = actor2.cell.name
        local actor2rot     = actor2.orientation:copy()
        local tp1           = tes3.positionCell({
            reference = actor2,
            position = actor1pos,
            cell = actor1cell,
            orientation = actor1rot,
        })
        if doTP ~= false then
            tes3.fadeOut({ duration = 0.0001 })
            if not tp1 then
                error("Actor2 not TP")
            end
            local function onTimerComplete()
                --actor2.position = actor1pos
                --actor2.orientation = actor1rot
                print("T1: " .. tostring(tp1))
                print(actor2.id)
                local actor1Inv = {}
                local actor2Inv = {}
                for index, item in ipairs(actor1.mobile.inventory) do
                    table.insert(actor1Inv, {id = item.object.id,count = item.count,ref = item})
                end
                for index, item in ipairs(actor2.mobile.inventory) do
                    table.insert(actor2Inv,  {id = item.object.id,count = item.count,ref = item})
                end
                for index, item in ipairs(actor1Inv) do
                    local objectId = item.id
                    local equipped = actor1.object:hasItemEquipped(objectId)
                    if equipped then
                        actor2EquipSaved[objectId] = { itemData = item.ref.itemData }
                        actor1.mobile:unequip({ item = objectId, playSound = false })
                    end
                    tes3.transferItem({
                        from                = actor1.mobile,
                        item                = objectId,
                        to                  = actor2.mobile,
                        count               = item.count,
                        playSound           = false,
                        reevaluateEquipment = false,
                    })
                end
                for index, item in ipairs(actor2Inv) do
                    local objectId = item.id
                    local equipped = actor2.object:hasItemEquipped(objectId)
                    if equipped then
                        actor1EquipSaved[objectId] = { itemData = item.ref.itemData }
                        actor2.mobile:unequip({ item = objectId, playSound = false })
                    end
                    tes3.transferItem({
                        from                = actor2.mobile,
                        item                =objectId,
                        to                  = actor1.mobile,
                        count               = item.count,
                        playSound           = false,
                        reevaluateEquipment = false,
                    })
                end
                commonUtil.makeActorWait(actor2)
                commonUtil.transferSpells(actor1, actor2)
                for index, item in ipairs(actor1Saved.mobile.inventory) do
                    local objectId = item.object.id
                    if actor1EquipSaved[objectId] then
                        actor1Saved.mobile:equip({
                            item = objectId,
                            playSound = false,
                            itemData = actor1EquipSaved[objectId].itemData
                        })
                        print("Equipped " .. objectId)
                    end
                end
                for index, item in ipairs(actor2Saved.mobile.inventory) do
                    local objectId = item.object.id
                    if actor2EquipSaved[objectId] then
                        actor2Saved.mobile:equip({
                            item = objectId,
                            playSound = false,
                            itemData = actor2EquipSaved[objectId].itemData
                        })
                        print("Equipped " .. objectId)
                    end
                end
                commonUtil.transferStats(actor1, actor2)
                print(actor2DestPos)
                local tp2 = tes3.positionCell({
                    reference          = actor1,
                    position           = actor2DestPos,
                    cell               = actor2cell,
                    orientation        = actor2rot,
                    forceCellChange    = true,
                    teleportCompanions = false,
                })
                --actor1.position = actor2pos
                print("TP2: " .. tostring(tp2))
                if kill2 then
                    actor2.mobile.health.current = 0
                end
                fixEncumbrance()
                tes3.fadeIn({ duration = 0.1 })
            end

            timer.start({ duration = 0.1, callback = onTimerComplete })
        end
    end
end

function cloneData.getCloneRecordId()
    if not omw then
        return config.cloneRecordId
    else
        if types.NPC.createRecordDraft then
            return config.cloneRecordId
        else
            local playerRecord = types.NPC.record(getPlayer())
            local mOrF = "f"
            local playerRace = playerRecord.race
            if playerRecord.isMale then
                mOrF = "m"
            end
            local cloneRecord = "ZHAC_AvatarBase_" .. string.sub(playerRace, 0, 2) .. "_" .. mOrF
            print(cloneRecord)
            local recordCheck = types.NPC.record(cloneRecord)
            if recordCheck then
                return cloneRecord
            else
                return config.cloneRecordId
            end
        end
    end
end

function cloneData.getCloneRecord()
    if omw then
        local playerRecord = types.NPC.record(getPlayer())
        local rec = {
            name = playerRecord.name,
            template = types.NPC.record(cloneData.getCloneRecordId()),
            isMale = playerRecord.isMale,
            head = playerRecord.head,
            hair = playerRecord.hair,
            class = playerRecord.class,
            race = playerRecord.race
        }
        if types.NPC.createRecordDraft then
            local ret = types.NPC.createRecordDraft(rec)
            local record = world.overrideRecord(ret, ret.id)
            return record
        else
            return types.NPC.record(cloneData.getCloneRecordId())
        end
    else
        local cloneRecord = tes3.getObject(cloneData.getCloneRecordId())
        local playerRecord = tes3.getObject("player")
        cloneRecord.hair = playerRecord.hair
        cloneRecord.race = playerRecord.race
        cloneRecord.name = playerRecord.name
        cloneRecord.female = playerRecord.female
        cloneRecord.class = playerRecord.class
        cloneRecord.head = playerRecord.head
        cloneRecord.modified = true
        return cloneRecord
    end
end

function commonUtil.getLocationData(obj)
    if omw then
        return {
            exterior = obj.cell.isExterior,
            cell = obj.cell.name,
            px = obj.cell.gridX,
            py = obj.cell.gridY,
            position = obj.position,
            rotation = obj.rotation,
            worldSpaceId = obj.cell.worldSpaceId
        }
    end
end

local function isBlacklisted(inputString)
    local blacklist = { "vampire" } -- Add other blacklisted strings here
    for _, word in ipairs(blacklist) do
        if string.find(inputString:lower(), "^" .. word) then
            return true
        end
    end
    return false
end

function commonUtil.transferSpells(actor1, actor2)
    if omw then

    else
        local mob1 = actor1.mobile
        local mob2 = actor2.mobile
        local actor1Spells = {}
        local actor2Spells = {}
        for index, value in pairs(tes3.getSpells({ target = mob1, getActorSpells = false, getRaceSpells = false, getBirthsignSpells = false })) do
            if not isBlacklisted(value.id) then
                table.insert(actor1Spells, value.id)
                tes3.removeSpell({ reference = mob1, spell = value.id })
            end
        end
        for index, value in pairs(tes3.getSpells({ target = mob2, getActorSpells = false, getRaceSpells = false, getBirthsignSpells = false })) do
            if not isBlacklisted(value.id) then
                table.insert(actor2Spells, value.id)
                tes3.removeSpell({ reference = mob2, spell = value.id })
            end
        end

        for index, value in pairs(tes3.getSpells({ target = mob1, getActorSpells = true, getRaceSpells = false, getBirthsignSpells = false, spellType =
            tes3.spellType["ability"] })) do
            if not isBlacklisted(value.id) then
                table.insert(actor1Spells, value.id)
                tes3.removeSpell({ reference = mob1, spell = value.id })
            end
        end
        for index, value in pairs(tes3.getSpells({ target = mob2, getActorSpells = true, getRaceSpells = false, getBirthsignSpells = false, spellType =
            tes3.spellType["ability"] })) do
            if not isBlacklisted(value.id) then
                table.insert(actor2Spells, value.id)
                tes3.removeSpell({ reference = mob2, spell = value.id })
            end
        end

        for index, value in pairs(tes3.getSpells({ target = mob1, getActorSpells = true, getRaceSpells = false, getBirthsignSpells = false, spellType =
            tes3.spellType["curse"] })) do
            if not isBlacklisted(value.id) then
                table.insert(actor1Spells, value.id)
                tes3.removeSpell({ reference = mob1, spell = value.id })
            end
        end
        for index, value in pairs(tes3.getSpells({ target = mob2, getActorSpells = true, getRaceSpells = false, getBirthsignSpells = false, spellType =
            tes3.spellType["curse"] })) do
            if not isBlacklisted(value.id) then
                table.insert(actor2Spells, value.id)
                tes3.removeSpell({ reference = mob2, spell = value.id })
            end
        end
        for index, value in ipairs(actor1Spells) do
            tes3.addSpell({ reference = mob2, spell = value })
        end
        for index, value in ipairs(actor2Spells) do
            tes3.addSpell({ reference = mob1, spell = value })
        end
    end
end

function commonUtil.transferStats(actor1, actor2) --transfer current stat info between two actors, do not touch base(of actor 1 at least)
    if omw then

    else
        local mob1 = actor1.mobile
        local mob2 = actor2.mobile
        local properties = { "health", "fatigue", "magicka" }

        -- health/magicka/fatigue
        for _, name in pairs(properties) do
            --mob1[name].base, mob2[name].base = mob2[name].base, mob1[name].base
            mob1[name].current, mob2[name].current = mob2[name].current, mob1[name].current

            if mob1[name].current ~= mob1[name].base then
                tes3.setStatistic({ reference = mob1, name = name, current = mob1[name].current })
            end
            if mob2[name].current ~= mob2[name].base then
                tes3.setStatistic({ reference = mob2, name = name, current = mob2[name].current })
            end
        end

        -- attributes
        for name in pairs(tes3.attribute) do
            --mob1[name].base, mob2[name].base = mob2[name].base, mob1[name].base
            mob1[name].current, mob2[name].current = mob2[name].current, mob1[name].current

            if mob1[name].current ~= mob1[name].base then
                tes3.setStatistic({ reference = mob1, name = name, current = mob1[name].current })
            end
            if mob2[name].current ~= mob2[name].base then
                tes3.setStatistic({ reference = mob2, name = name, current = mob2[name].current })
            end
        end

        -- skills
        for name in pairs(tes3.skill) do
            --mob1[name].base, mob2[name].base = mob2[name].base, mob1[name].base
            --mob1[name].current, mob2[name].current = mob2[name].current, mob1[name].current

            -- tes3.setStatistic({ reference = mob1, name = name, current = mob1[name].current })
            -- tes3.setStatistic({ reference = mob2, name = name, current = mob2[name].current })
        end

        mob1:updateDerivedStatistics()
        mob2:updateDerivedStatistics()
    end
end

function commonUtil.copyStats(actorSource, actorTarget) --one way copy of stats from one actor to another
    if omw then
        for key, val in pairs(actorSource.type.stats.attributes) do
            print(key)
            actorTarget:sendEvent("CA_SetStat",
                {
                    stat = "attributes",
                    key = key,
                    base = val(actorSource).base,
                    damage = val(actorSource).damage,
                    modifier = val(actorSource).modifier
                })
        end
        for key, val in pairs(actorSource.type.stats.dynamic) do
            actorTarget:sendEvent("CA_SetStat",
                {
                    stat = "dynamic",
                    key = key,
                    base = val(actorSource).base,
                    modifier = val(actorSource).modifier,
                    current = val(actorSource).current,
                })
        end
        for key, val in pairs(actorSource.type.stats.skills) do
            actorTarget:sendEvent("CA_SetStat",
                {
                    stat = "skills",
                    key = key,
                    base = val(actorSource).base,
                    damage = val(actorSource).damage,
                    modifier = val(actorSource).modifier
                })
        end
    else
        local asm = actorSource.mobile
        local atm = actorTarget.mobile
        local actor1stats = {}
        for index, value in pairs(asm.attributes) do
            local aval
            for index1, avalue in pairs(tes3.attribute) do
                if index == avalue + 1 then
                    aval = index1
                end
            end
            if aval then
                print(aval)
                tes3.setStatistic({ reference = atm, name = aval, current = value.base, base = value.base })
            end
        end
        for index, value in pairs(asm.skills) do
            local aval
            for index1, avalue in pairs(tes3.skill) do
                if index == avalue + 1 then
                    aval = index1
                end
            end
            if aval then
                print(aval)
                tes3.setStatistic({ reference = atm, name = aval, current = value.base, base = value.base })
            end
        end
        tes3.setStatistic({ reference = atm, name = "health", current = asm.health.base, base = asm.health.base })
        tes3.setStatistic({ reference = atm, name = "fatigue", current = asm.fatigue.base, base = asm.fatigue.base })
        tes3.setStatistic({ reference = atm, name = "magicka", current = asm.magicka.base, base = asm.magicka.base })
    end
end

function commonUtil.createPlayerClone(cell, position, rotation)
    local newActor
    local check = dataManager.getValueOrInt("firstMessageGiven", 0)
    if check == 0 then
        dataManager.setValue("firstMessageGiven", 1)
        commonUtil.delayedAction(function()
            commonUtil.showInfoBox(
                "Now that you've created your first clone, enter the opposite clone pod. \nOpen the door on it.")
        end, 3
        )
    end
    if omw then
        if position.x then
            position = util.vector3(position.x, position.y, position.z)
        end
        rotation = createRotation(0, 0, -90)
        newActor = world.createObject(cloneData.getCloneRecord().id)
        newActor:teleport(cell, position, rotation)
        newActor:addScript("scripts/CloningAvatar/omw/cloneScript.lua")
    else
        if not rotation then
            rotation = tes3vector3.new(0, 0, math.rad(-90))
        end
        position = tes3vector3.new(position.x, position.y, position.z)
        newActor = tes3.createReference({
            object = cloneData.getCloneRecord(),
            position = position,
            cell = cell,
            orientation = rotation
        })
    end
    commonUtil.copyStats(getPlayer(), newActor)
    return newActor
end

function commonUtil.getReferenceById(id, locationData)
    if omw and world then
        if id == getPlayer().id then
            return getPlayer()
        end
        for index, value in ipairs(world.activeActors) do
            if value.id == id then
                return value
            end
        end
        if not locationData then
        else
            local cell
            if locationData.exterior == true then
                print("Found Exterior")
                cell = world.getExteriorCell(locationData.px, locationData.py)
            else
                cell = world.getCellByName(locationData.cell)
            end
            for index, value in ipairs(cell:getAll(types.NPC)) do
                if value.id == id then
                    return value
                end
            end
            for index, value in ipairs(cell:getAll()) do
                if value.id == id then
                    return value
                end
            end
        end
    elseif omw and nearby then
        if id == getPlayer().id then
            return getPlayer()
        end
        for index, value in ipairs(nearby.actors) do
            if value.id == id then
                return value
            end
        end
    elseif not omw then
        return tes3.getReference(id)
    end
end

local function rezPlayer()
    if omw then
        local scr = world.mwscript.getGlobalScript("ZHAC_PlayerRez", world.players[1])
        scr.variables.doRez = 1
    end
end

function cloneData.getCloneData()
    return dataManager.getValueOrTable("CloneData")
end

local nextDest


function cloneData.movePlayerToNewBody()
    local player = getPlayer()
    local currentID = cloneData.getCloneDataForNPC(player).id
    --  cloneData.removeCloneFromData(currentID)
    local destCLone = cloneData.getCloneObject(cloneData.getRealPlayerCloneID())
    local data = cloneData.transferPlayerData(world.players[1], destCLone)
    --destCLone.enabled = false
    if omw then
        player:setScale(1)
        player:sendEvent("RegainControl")
    else

    end
end

local function playerRespawn()

end
function cloneData.handleCloneDeath()
    local player = getPlayer()
    rezPlayer()
    -- player:setScale(0.001)
    --local deadAvatar = commonUtil.createPlayerClone(player.cell, player.position, player.rotation)
    local currentID = cloneData.getCloneDataForNPC(player).id
    --  cloneData.removeCloneFromData(currentID)
    local destCLone = cloneData.getCloneObject(cloneData.getRealPlayerCloneID())
    local data = cloneData.transferPlayerData(player, destCLone, true, true)
    --destCLone.enabled = false
    -- player:setScale(1)
    if omw then
        player:sendEvent("RegainControl")

        actorSwap.doActorSwap(player, destCLone, false)
        --async:newUnsavableSimulationTimer(5, cloneData.movePlayerToNewBody)
    end
    --commonUtil.setActorHealth(destCLone, 0)

    --player:teleport(player.cell, util.vector3(player.position.x, player.position.y, player.position.z + 1000))
end

function cloneData.setCloneData(data)
    dataManager.setValue("CloneData", data)
end

function cloneData.getCloneDataForNPC(actor)
    local currentId = commonUtil.getActorId(actor)
    for index, value in pairs(cloneData.getCloneData()) do
        if value.currentId == currentId then
            return value
        end
    end
    print("Found no clone data for " .. actor.id)
    return nil
end

function cloneData.getCloneDataForID(id)
    for index, value in pairs(cloneData.getCloneData()) do
        if value.id == id then
            return value
        end
    end
    print("Found no clone data for " .. id)
    return nil
end

function cloneData.getRealPlayerCloneID()
    local cdata = cloneData.getCloneData()
    for index, value in pairs(cdata) do
        if value.cloneType == "RealPlayer" then
            return value.id
        end
    end
end

function cloneData.setCloneDataForNPCID(cloneID, newID, type)
    local cdata = cloneData.getCloneData()
    for index, value in pairs(cdata) do
        if value.id == cloneID then
            cdata[index].currentId = newID
        end
    end
    cloneData.setCloneData(cdata)
end

function cloneData.updateClonedataLocation(actor, tempActor)
    local currentId = commonUtil.getActorId(actor)
    local cdata = cloneData.getCloneData()
    if not tempActor then
        tempActor = actor
    end
    for index, value in pairs(cdata) do
        if value.currentId == currentId then
            cdata[index].locationData = commonUtil.getLocationData(tempActor)
            return value
        end
    end
    cloneData.setCloneData(cdata)
    return nil
end

function cloneData.getCloneObject(cloneId)
    local cdata = cloneData.getCloneData()
    for index, value in pairs(cdata) do
        if value.id == cloneId then
            local ref = commonUtil.getReferenceById(value.currentId, value.locationData)
            if not ref then
                error("Could not find actor " .. value.currentId .. value.locationData.cell)
            end
            return ref
        end
    end
end

function cloneData.markActorAsClone(actor, type)
    local playerName
    if omw then
        playerName = types.NPC.record("player").name
    else
        playerName = tes3.player.object.name
    end
    local cdata = cloneData.getCloneData()
    local nextCloneId = dataManager.getValueOrInt("NextCloneId") + 1
    local newCloneData = {}
    newCloneData.currentId = commonUtil.getActorId(actor)
    newCloneData.cloneType = "PlayerClone"
    if type ~= nil then
        newCloneData.cloneType = type
        newCloneData.name = playerName
    else
        newCloneData.name = "Clone " .. nextCloneId
    end
    newCloneData.id = nextCloneId
    dataManager.setValue("NextCloneId", nextCloneId)
    cdata[nextCloneId] = newCloneData
    cloneData.setCloneData(cdata)
    return { cloneData = cdata, createdCloneId = nextCloneId, newClone = actor }
end

function cloneData.addCloneToWorld(cell, position, rotation, cloneType)
    local newClone = commonUtil.createPlayerClone(cell, position, rotation)
    local data = cloneData.markActorAsClone(newClone, cloneType)
    return { cloneData = data.cloneData, createdCloneId = data.createdCloneId, newClone = newClone }
end

function cloneData.clearCloneIDForPod(pod)
    local cdata = cloneData.getCloneData()
    for index, value in pairs(cdata) do
        if cdata[index].occupiedPod == pod then
            cdata[index].occupiedPod = nil
        end
    end
    cloneData.setCloneData(cdata)
end

function cloneData.setClonePodName(cloneId, pod)
    cloneData.clearCloneIDForPod(pod)
    local cdata = cloneData.getCloneData()
    for index, value in pairs(cdata) do
        if value.id == cloneId then
            cdata[index].occupiedPod = pod
        end
    end
    cloneData.setCloneData(cdata)
end

function cloneData.getCloneIDForPod(pod)
    local cdata = cloneData.getCloneData()
    for index, value in pairs(cdata) do
        if cdata[index].occupiedPod == pod then
            return index
        end
    end
end

function cloneData.removeCloneFromData(id)
    local cdata = cloneData.getCloneData()
    for index, value in pairs(cdata) do
        if value.id == id then
            table.remove(cdata, index)
            cloneData.setCloneData(cdata)
            return
        end
    end
end

function commonUtil.getCellName(actor)
    if not omw then
        return actor.cell.name
    else
        if actor.cell.name == "" and actor.cell.isExterior then
            return actor.cell.region
        end
        return actor.cell.name
    end
end

function commonUtil.getActorHealth(actor)
    if omw then
        return types.Actor.stats.dynamic.health(actor).current
    else
        if not actor.mobile then
            return 10
        end
        return actor.mobile.health.current
    end
end

function commonUtil.setActorHealth(actor, val)
    if omw then
        actor:sendEvent("CA_setHealth", val)
    else
        actor.mobile.health.current = val
    end
end

function cloneData.getMenuData()
    local cdata = cloneData.getCloneData()
    local menuData = {}

    for index, value in pairs(cdata) do
        local newData = { id = value.id, name = value.name, info = {} }
        local actor = cloneData.getCloneObject(value.id)
        if not actor then
            error("Couldn't find actor " .. value.id)
        end
        newData.info["loc"] = "Current Location: " .. commonUtil.getCellName(actor)
        newData.info["health"] = "Health: " .. tostring(commonUtil.getActorHealth(actor))
        newData.info["isAlive"] = commonUtil.getActorHealth(actor) > 0
        newData.realId = commonUtil.getActorId(actor)
        table.insert(menuData, newData)
    end
    return menuData
end

function cloneData.storePlayer()
    local cdata = cloneData.getCloneData()
    local player = getPlayer()

    for index, value in pairs(cdata) do
        if value.cloneType == "RealPlayer" then
            error("Player already exists")
        end
    end
    local newClone = cloneData.addCloneToWorld(player.cell, player.position, nil, "RealPlayer")
    commonUtil.transferPlayerData(player, newClone)
end

return cloneData
