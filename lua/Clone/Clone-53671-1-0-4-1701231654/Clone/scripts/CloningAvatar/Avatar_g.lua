local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local async = require('openmw.async')
local storage = require("openmw.storage")
local actorSwap = require('scripts.CloningAvatar.ActorSwap')
local cloneData = require("scripts.CloningAvatar.common.cloneData")
local settingsGroup = 'SettingsClone'
local globalSettings = storage.globalSection(settingsGroup)
local function doActorSwap(data)
    actorSwap.doActorSwap(data.actor1, data.actor2)
end
if not types.Player.isTeleportingEnabled then
    I.Settings.registerPage {
        key = "Clone",
        l10n = "Clone",
        name = "Clone",
        description = "Clone is enabled, but your engine version is too old. Please download a new version of OpenMW Develppment or 0.49+.(Newer than October 30, 2023)"
    }
    error("Newer version of OpenMW is required")
end
local function createPlayerAvatar(player)
    local playerRecord = types.NPC.record(player.recordId)
    local rec = {
        name = playerRecord.name,
        template = types.NPC.record("ZHAC_AvatarBase"),
        isMale = playerRecord.isMale,
        head = playerRecord.head,
        hair = playerRecord.hair,
        class = playerRecord.class,
        race = playerRecord.race
    }
    local ret = types.NPC.createRecordDraft(rec)
    local record = world.overrideRecord(ret,ret.id)
    local newActor = world.createObject(record.id)
    newActor:teleport(player.cell, player.position)
    return newActor
end
local respawnCell = "Caldera, Guild of Mages"
local respawnPos = util.vector3(521.4033203125, 882.4403076171875, 401)
local function movePlayerToNewBody()
    local player = world.players[1]
    player:setScale(1)
    player:teleport(respawnCell, respawnPos)
    player:sendEvent("RegainControl")
end
local function playerRespawn()
    cloneData.handleCloneDeath()
end
local function removePlayerItemCount(itemId, fcount)
    local count = 0
    if not fcount then
        fcount = 1
    end

    local player = world.players[1]
    local inventory = types.Actor.inventory(player):getAll()

    for _, stack in pairs(inventory) do
        if string.find(stack.recordId, itemId) and stack.count > fcount then
            stack:remove(fcount)
            --stack.count = stack.count - fcount
            return fcount
        end
    end


    return count
end
local activatedActor
local function activateNPC(object, actor)
    --print(object.recordId)
    if object.recordId:lower() == cloneData.getCloneRecordId():lower() then
        --actorSwap.doActorSwap(actor, object)
        --return false
        activatedActor = object
    end
end
local function onItemActive(item)
    if item.recordId == "zhac_swapmarker" then
        item:remove()
        if activatedActor then
            actorSwap.doActorSwap(world.players[1], activatedActor)
            world.players[1]:sendEvent("closeMenuWindow_Clone")
        end
    end
end
local function updateClonedataLocation(actor)
    cloneData.updateClonedataLocation(actor)
end
local cloneScript = "scripts//cloningAvatar//omw//cloneScript.lua"
local function onActorActive(actor)
    if actor.recordId == "zhack_avatarbase" then
        if not actor:hasScript(cloneScript) then
            actor:addScript(cloneScript)
        end
    end
end
local function SwitchToClone(id)
local cdata = cloneData.getCloneData()

local destCLone = cloneData.getCloneObject(id)
if not destCLone then
    error("No clone found!")
end
cloneData.transferPlayerData(world.players[1],destCLone)

end
local function openCloneManageMenu(id)

    world.players[1]:sendEvent("openCloneManageMenu",{data = cloneData.getCloneData(), id = id})

end
local function CC_CreateClone(buttonId)
    
    local check1, check2, check3 = removePlayerItemCount("ingred_6th_corp"),
    removePlayerItemCount("ingred_daedras_heart_01"), removePlayerItemCount("ingred_frost_salts_01")
    if buttonId == "tdm_controlpanel_left" then
        local newClone = cloneData.addCloneToWorld("gnisis, arvs-drelen", { x = 4637, y = 6015, z = 146 })

        cloneData.setClonePodName(newClone.createdCloneId, buttonId)
    elseif buttonId == "tdm_controlpanel_right" then
        local newClone = cloneData.addCloneToWorld("gnisis, arvs-drelen", { x = 4637, y = 5766, z = 146 })
        print(newClone.createdCloneId)
        cloneData.setClonePodName(newClone.createdCloneId, buttonId)
    end
end
local function openClonePlayerMenu()
world.players[1]:sendEvent("openClonePlayerMenu",cloneData.getMenuData())
end
local function Clone_SettingUpdate(data)

    globalSettings:set(data.key, data.value)

end
acti.addHandlerForType(types.NPC, activateNPC)
return {
    interfaceName  = "CloningAvatars",
    interface      = {
        version = 1,

    },
    engineHandlers = {
        onItemActive = onItemActive,
        onActorActive = onActorActive,
    },
    eventHandlers  = {
        Clone_SettingUpdate = Clone_SettingUpdate,
        doActorSwap = doActorSwap,
        createPlayerAvatar = createPlayerAvatar,
        rezPlayer = rezPlayer,
        playerRespawn = playerRespawn,
        updateClonedataLocation = updateClonedataLocation,
        SwitchToClone= SwitchToClone,
        openClonePlayerMenu = openClonePlayerMenu,
        openCloneManageMenu = openCloneManageMenu,
        CC_CreateClone = CC_CreateClone,
    }
}
