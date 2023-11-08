local omw, core     = pcall(require, "openmw.core")
local _, world      = pcall(require, "openmw.world")
local _, nearby     = pcall(require, "openmw.nearby")
local _, types      = pcall(require, "openmw.types")
local _, interfaces = pcall(require, "openmw.interfaces")
local _, util       = pcall(require, "openmw.util")
local _, storage    = pcall(require, "openmw.storage")
local _, async      = pcall(require, "openmw.async")

local cloneMenu
local cloneManageMenu
local pathPrefix    = "Clone.scripts.CloningAvatar"
local messageBoxUtil
local globalSettings
if omw then
    local settingsGroup = 'SettingsClone'
    globalSettings = storage.globalSection(settingsGroup)
    pathPrefix = "scripts.CloningAvatar"
end
local cloneData   = require(pathPrefix .. ".common.cloneData")
local dataManager = require(pathPrefix .. ".common.dataManager")
--cutil = require("VerticalityGangProject.scripts.CloningAvatar.common.commonUtil")
local commonUtil  = {}
function commonUtil.getPlayer()
    print(omw, world == nil)
    if omw and world then
        return world.players[1]
    elseif omw and nearby then
        return nearby.players[1]
    elseif not omw then
        return tes3.getReference("player")
    end
end

function commonUtil.delayedAction(callback, duration)
    if not omw then
        timer.start({ duration = duration, callback = callback })
    else
        async:newUnsavableSimulationTimer(duration, callback)
    end
end

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

function commonUtil.getValueForRef(ref, valueId)
    if not omw then
        return ref.data[valueId]
    else
        return dataManager.getValue(ref.id .. valueId)
    end
end

function commonUtil.setValueForRef(ref, valueId, value)
    if not omw then
        ref.modified = true
        ref.data[valueId] = value
    else
        return dataManager.setValue(ref.id .. valueId, value)
    end
end

function commonUtil.setPosition(ref, position)
    if not omw then
        ref.position = position
    else
        ref:teleport(ref.cell, position)
    end
end

function commonUtil.getPosition(x, y, z)
    if not omw then
        return tes3vector3.new(x, y, z)
    else
        return util.vector3(x, y, z)
    end
end

function commonUtil.getObjectsInCell(cellOrCellname)
    if (not omw) then
        local cell = cellOrCellname
        if (cell.id == nil) then cell = ZackBridge.getCell(cell) end
        local refs = {}
        for ref in cell:iterateReferences() do
            table.insert(refs, ref)
        end
        return refs
    end
    local cell = cellOrCellname
    if (cell.name == nil) then
        cell = world.getCellByName(cell)
    else
        cell = cellOrCellname
    end
    return cell:getAll()
end

function commonUtil.getReferenceModId(ref)
    if omw then
        if not ref.contentFile then return nil end
        return ref.contentFile:lower()
    else
        if not ref.sourceMod then return nil end
        return ref.sourceMod:lower()
    end
end

function commonUtil.menuMode()
    if omw then
        return core.isWorldPaused()
    else
        return tes3.menuMode()
    end
end

function commonUtil.playerIsInClone()
    return cloneData.playerIsInClone()
end

if not omw then
    cloneMenu = include(pathPrefix .. ".mwse.cloneMenu")
    cloneManageMenu = include(pathPrefix .. ".mwse.cloneTubeMenu")
end
function commonUtil.addTopic(topic)
    if omw then
    else
        tes3.addTopic({ topic = topic })
    end
end

function commonUtil.addItem(itemId, count)
    if not omw then
        tes3.addItem({ reference = tes3.player, item = itemId, count = count })
    else
        local newObj = world.createObject(itemId, count)
        newObj:moveInto(world.players[1])
    end
end

function commonUtil.getGMST(gmst)
    if omw then
        return core.getGMST(gmst)
    else
        return tes3.findGMST(gmst).value
    end
end

function commonUtil.isPlayerVampire()
    if omw then
        local effCheck = types.Actor.activeEffects(commonUtil.getPlayer()):getEffect("vampirism")
        if effCheck ~= nil and effCheck.magnitude > 0 then
            return true
        else
            return false
        end
    else
        return tes3.isAffectedBy({ reference = tes3.player, effect = tes3.effect.vampirism })
    end
end

function commonUtil.isPlayerWerewolfForm()
    if omw then
        return types.NPC.isWerewolf(commonUtil.getPlayer())
    else
        local player = tes3.mobilePlayer
        return tes3.mobilePlayer.werewolf
    end
end

function commonUtil.canTeleport()
    if omw then
        return types.Player.isTeleportingEnabled(commonUtil.getPlayer())
    else
        return not tes3.getWorldController().flagTeleportingDisabled
    end
end

function commonUtil.openCloneMenu(force)
    local canOpen = cloneData.playerIsInClone()
    if not canOpen and not force then
        return
    end
    if commonUtil.isPlayerWerewolfForm() then
        commonUtil.showMessage("You cannot do this as a werewolf.")
        return
    end
    local vampcheck = commonUtil.isPlayerVampire()
    if force and vampcheck then
        commonUtil.showInfoBox("Vampires are incapable of using this device.")
        return
    end

    if not force and not commonUtil.canTeleport() then
        commonUtil.showMessage(commonUtil.getGMST("sTeleportDisabled"))
        return
    end
    if omw then
        core.sendGlobalEvent("openClonePlayerMenu")
    else
        cloneMenu.createWindow()
    end
end

function commonUtil.openManageCloneMenu(id)
    if omw then
        core.sendGlobalEvent("openCloneManageMenu", id)
    else
        cloneManageMenu.createWindow(id)
    end
end

function commonUtil.resurrectPlayer()
    commonUtil.setActorHealth(tes3.player.mobile, 100)
    if not omw then
        tes3.player.mobile:resurrect({ resetState = false, })
    end
    commonUtil.showMessage("Rezurrect time")
end

function commonUtil.getReferenceById(id, locationData)
    if omw and world then
        if id == commonUtil.getPlayer().id then
            return commonUtil.getPlayer()
        end
        if not locationData then
            for index, value in ipairs(world.activeActors) do
                if value.id == id or value.recordId == id:lower() and value ~= commonUtil.getPlayer() then
                    return value
                end
            end
            for index, value in ipairs(commonUtil.getPlayer().cell:getAll(types.Activator)) do
                if value.id == id or value.recordId == id:lower() and value ~= commonUtil.getPlayer() then
                    return value
                end
            end
        else
            local cell
            if locationData.cell.name ~= nil then
                cell = locationData.cell
            elseif locationData.exterior then
                cell = world.getExteriorCell(locationData.px, locationData.py, locationData.worldSpaceId)
            else
                cell = world.getCellByName(locationData.cell)
            end
            for index, value in ipairs(cell:getAll()) do
                if value.id == id or value.recordId == id:lower() and value ~= commonUtil.getPlayer() then
                    return value
                end
            end
        end
    elseif omw and nearby then
        if id == commonUtil.getPlayer().id then
            return commonUtil.getPlayer()
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

function commonUtil.getActorId(actor)
    if omw then
        return actor.id
    else
        return actor.id
    end
end

function commonUtil.getRefRecordId(obj)
    if omw then
        return obj.recordId:lower()
    else
        return obj.baseObject.id:lower()
    end
end

local function handlePlayerDeath()

end
local function is_single_letter(s)
    -- Check if the string has exactly one character and if that character is a letter
    return #s == 1 and s:match("[a-zA-Z]") ~= nil
end
function commonUtil.getKeyBindingChar()
    if not omw then
        local config = mwse.loadConfig("clone")
        local code = tes3.scanCode.k
        if config and config.keybindClone then
            code = config.keybindClone.keyCode
        end
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

function commonUtil.getLocationData(obj)
    if omw then
        return {
            exterior = obj.cell.isExterior,
            cell = obj.cell.name,
            px = obj.cell.gridX,
            py = obj.cell.gridY,
            position = obj.position,
            rotation = obj.rotation,
            worldSpaceId = obj.cell.worldSpaceId,
            region = obj.cell.region
        }
    end
end

function commonUtil.setObjectState(id, state)
    local obj = commonUtil.getReferenceById(id, { cell = commonUtil.getPlayer().cell })
    if omw then
        obj.enabled = state
    else
        tes3.setEnabled({ reference = obj, enabled = state })
    end
end

function commonUtil.getQuestStage(questId)
    if not omw then
        return tes3.getJournalIndex({ id = questId })
    else
        return types.Player.quests(commonUtil.getPlayer())[questId].stage
    end
end

function commonUtil.getPlayerItemCount(itemId)
    local player = commonUtil.getPlayer()
    local count = 0

    if omw then
        local playerInv = types.Actor.inventory(player):getAll()
        for index, value in ipairs(playerInv) do
            if string.find(value.recordId, itemId) then
                count = count + value.count
            end
        end
    else -- MWSE logic
        local player = tes3.player
        local inventory = player.object.inventory

        for _, stack in pairs(inventory) do
            if string.find(stack.object.id, itemId) then
                count = count + stack.count
            end
        end
    end

    return count
end

function commonUtil.setReferenceState(obj, state)
    if omw and obj.count > 0 then
        obj.enabled = state
    elseif not omw then
        tes3.setEnabled({ reference = obj, enabled = state })
    end
end

function commonUtil.setActorHealth(actor, health)
    if omw then
        actor:sendEvent("CA_setHealth", health)
    else
        actor.health.current = health
    end
end

function commonUtil.getScale(obj)
    if omw then
        return obj.scale
    else
        return obj.scale
    end
end

function commonUtil.setScale(obj, scale)
    if omw then
        obj:setScale(scale)
    else
        obj.scale = scale
    end
end

function commonUtil.getScriptVariables(objectId, scriptName, val)
    local object = commonUtil.getReferenceById(objectId)
    if omw then
        return world.mwscript.getLocalScript(object).variables[val]
    else
        return object.context[val]
    end
end

function commonUtil.teleportActor(actor, cellName, pos)
    if omw then
        actor:teleport(cellName, util.vector3(pos.x, pos.y, pos.z))
    else
        tes3.positionCell({ reference = actor, cell = cellName, position = tes3vector3.new(pos.x, pos.y, pos.z) })
    end
end

function commonUtil.showMessage(msg)
    if omw then
        world.players[1]:sendEvent("showMessage", msg)
    else
        tes3ui.showNotifyMenu(msg)
    end
end

function commonUtil.writeToConsole(msg)
    if omw then
        world.players[1]:sendEvent("writeToConsole", msg)
    else
        tes3ui.log(msg)
    end
end

function commonUtil.closeMenu()
    if omw then
        world.players[1]:sendEvent("closeMenuWindow_Clone")
    else
        tes3ui.leaveMenuMode()
    end
end

return commonUtil
