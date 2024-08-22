local world = require("openmw.world")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local anim = require('openmw.animation')
local doorClosing = false

local doorOpening = false

local playerIsInVault = false
local checkForExit = false
local cutsceneState = 0
local openDelay = 2
local closeDelay = 5
local keyId = "gold_001"
local doorButton = "zhac_imp_button"
local doorStateVar = "zhac_hest_vdoorstate"
local vaultDoorId = "zhac_hest_vdoor_door"
local openSoundStage = 0

local HESTATUR_VAULT = "Hestatur"
local lightBlocker2 = "zhac_vault_lightblocker1"
local lightBlocker1 = "zhac_vault_lightblocker2"
local ENTRANCE = HESTATUR_VAULT .. ", Treasury Vault"
local doorObj
local function getObjByID(id, cell)
    if not cell then
        cell = world.players[1].cell
    end
    for index, value in ipairs(cell:getAll()) do
        if value.recordId == id then
            return value
        end
    end
end
local function setLightBlockersEnabled(state, cell)
    if not cell then
        cell = world.players[1].cell
    end
    for index, value in ipairs(cell:getAll()) do
        if value.recordId == lightBlocker2 or value.recordId == lightBlocker1 then
            value.enabled = state
        end
    end
end
local function openDoor()
    if doorOpening then
        return
    end
    doorOpening = true

    setLightBlockersEnabled(false)
    core.sound.playSound3d("SothaDoorOpen", doorObj, { volume = 3 })

    async:newUnsavableSimulationTimer(openDelay, function()
        world.mwscript.getGlobalVariables(world.players[1])[doorStateVar] = 1
        async:newUnsavableSimulationTimer(0.5, function()
            core.sound.playSound3d("Door Stone Open", doorObj, { volume = 5 })
        end
        )
    end
    )
    checkForExit = true
    openSoundStage = 0
end
local function closeDoor()
    if doorClosing then
        return
    end
    local completion = anim.getCurrentTime(doorObj, "death1")
    if completion and completion > 12 then --already closed
        return
    end
    world.mwscript.getGlobalVariables(world.players[1])[doorStateVar] = 0
    doorClosing = true
    openSoundStage = 0
end
local function finishDoorClose()
    if world.mwscript.getGlobalVariables(world.players[1])[doorStateVar] ~= 0 then
        world.mwscript.getGlobalVariables(world.players[1])[doorStateVar] = 0
    end
    core.sound.playSound3d("AB_Thunderclap0", doorObj, { volume = 3 })
    doorClosing = false
    -- I.TeleportBlocker.setDoorOpen(false)

    setLightBlockersEnabled(true)
end
local function autoClose()
    async:newUnsavableSimulationTimer(closeDelay, function()
        closeDoor()
    end)
end
local secsPassed = 0
local function onUpdate(dt)
    if not doorObj then
        for index, value in ipairs(world.players[1].cell:getAll(types.Activator)) do
            if value.recordId == vaultDoorId then
                doorObj = value
            end
        end
    end
    if doorClosing then
        local completion = anim.getCurrentTime(doorObj, "death1")
        if completion and completion > 12 then
            finishDoorClose()
        elseif completion then
            if openSoundStage == 0 and completion > 7.4 then
                core.sound.playSound3d("AB_SteamHammerStrike", doorObj, { volume = 5 })
                openSoundStage = 1
            elseif openSoundStage == 1 and completion > 8 then
                core.sound.playSound3d("AB_SteamHammerStrike", doorObj, { volume = 5 })
                openSoundStage = 2
            elseif openSoundStage == 2 and completion > 9 then
                core.sound.playSound3d("AB_SteamHammerStrike", doorObj, { volume = 5 })
                openSoundStage = 3
            end
        end
    end
    if doorOpening then
        local completion = anim.getCurrentTime(doorObj, "death2")
        if completion then
            if completion > 6.6 then
                doorOpening = false
            else
                if openSoundStage == 0 and completion > 2.1 then
                    core.sound.playSound3d("AB_SteamHammerStrike", doorObj, { volume = 5 })
                    openSoundStage = 1
                elseif openSoundStage == 1 and completion > 3.4 then
                    core.sound.playSound3d("AB_SteamHammerStrike", doorObj, { volume = 5 })
                    openSoundStage = 2
                elseif openSoundStage == 2 and completion > 3.9 then
                    core.sound.playSound3d("AB_SteamHammerStrike", doorObj, { volume = 5 })
                    openSoundStage = 3
                elseif openSoundStage == 3 and completion > 4.6 then
                    core.sound.playSound3d("AB_SteamHammerStrike", doorObj, { volume = 5 })
                    openSoundStage = 4
                end
            end
        end
    end
end
local function isMusuemItem(item)
    local record = item.type.records[item.recordId]
    local musuemRecord = item.type.records[item.recordId .. "_x"]
    local isMuseumId = string.sub(item.recordId, -2) == "_x"
    local nonMusuemRecord = item.type.records[string.sub(item.recordId, 1, -3)]

    if record and musuemRecord then
        return true
    elseif isMuseumId and nonMusuemRecord then
        return true
    else
        return false
    end
end

local function runCheckForGold(player)
    local count = types.Actor.inventory(player):countOf("gold_001")
    return count > 100000
end
local function runCheckForMusuem(player)
    local objs = player.cell:getAll()
    local validMusuemItems = 0
    for index, npc in ipairs(objs) do
        if isMusuemItem(npc) then
            validMusuemItems = validMusuemItems + 1
        end
    end
    for index, npc in ipairs(objs) do
        if isMusuemItem(npc) then
            validMusuemItems = validMusuemItems + 1
        end
    end
    return validMusuemItems > 4
end
local function runCheckForKeys(player)
    local keyCount = 0
    for index, value in ipairs(types.Actor.inventory(player):getAll(types.Miscellaneous)) do
        local record = types.Miscellaneous.records[value.recordId]
        if record and record.isKey then
            keyCount = keyCount + 1
        end
    end
    return keyCount > 24
end
local function isEquipped(actor, item)
    for index, value in pairs(types.Actor.getEquipment(actor)) do
        if value == item then
            return true
        end
    end
    return false
end
local function runCheckForArmor(player)
    local npcs = player.cell:getAll(types.NPC)
    local validArmorSets = 0
    for index, npc in ipairs(npcs) do
        if npc ~= player then
            local inventory = types.Actor.inventory(npc)
            local totalValue = 0
            for index, item in ipairs(inventory:getAll(types.Armor)) do
                if isEquipped(npc, item) then
                    local value = types.Armor.records[item.recordId].value
                    validArmorSets = validArmorSets + 1
                    totalValue = totalValue + value
                end
            end
            if totalValue > 20000 then
                validArmorSets = validArmorSets + 1
            elseif totalValue > 0 then
                --print("value", totalValue)
            end
        end
    end
    return validArmorSets > 3
end

--zhac_carryingitems
I.Activation.addHandlerForType(types.Activator, function(obj, actor)
    if obj.recordId == doorButton then --or obj.recordId == "ab_furn_shrinemephala_a" then
        local itemCount = types.Actor.inventory(actor):countOf(keyId)
        local isVaultUnLocked = I.Vault_Lock.isVaultLocked()
        if itemCount < 1 then
            if actor.type == types.Player then
                actor:sendEvent("showMessageHestatur", "Only the lord of Hestatur may control the vault.")
            end
            return false
        elseif not isVaultUnLocked then
            if actor.type == types.Player then
                actor:sendEvent("showMessageHestatur", "There are still some locks engaged, the door will not move.")
            end
            return false
        end
        --print(isVaultUnLocked)
        if world.mwscript.getGlobalVariables(actor)[doorStateVar] == 0 then
            openDoor()
        else
            closeDoor()
        end
        --print("opening")
        return false
    elseif obj.recordId == "zhac_hestatur_vlock_01" then
        local canOpen = runCheckForGold(actor)
        if canOpen then
            world.mwscript.getGlobalVariables(actor).zhac_hest_vdoor1_state = 1
        end
    elseif obj.recordId == "zhac_hestatur_vlock_02" then
        local canOpen = runCheckForArmor(actor)
        if canOpen then
            world.mwscript.getGlobalVariables(actor).zhac_hest_vdoor2_state = 1
        end
    elseif obj.recordId == "zhac_hestatur_vlock_03" then
        local canOpen = runCheckForMusuem(actor)
        if canOpen then
            world.mwscript.getGlobalVariables(actor).zhac_hest_vdoor3_state = 1
        end
    elseif obj.recordId == "zhac_hestatur_vlock_04" then
        local canOpen = runCheckForKeys(actor)
        if canOpen then
            world.mwscript.getGlobalVariables(actor).zhac_hest_vdoor4_state = 1
        end
    end
end)
local function onItemActive(item)
    if item.recordId == "zhac_vault_exitmarker" then
        item:remove()
        async:newUnsavableSimulationTimer(openDelay, function()
            openDoor()
        end)
    end
end
local function onCellChanged(data)
    if doorClosing or doorOpening then
        finishDoorClose()
    end
end

return
{
    interfaceName = "Hestatur_Vault",
    interface = {
        openDoor = openDoor,
        closeDoor = closeDoor,
        autoClose = autoClose,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onPlayerAdded = onPlayerAdded,
        onItemActive = onItemActive,
    },
    eventHandlers = {
        goToVault = goToVault,
        StartCutscene1 = StartCutscene1,
        firstApproach = firstApproach,
        checkInWhenDone = checkInWhenDone,
        MV_onCellChange = onCellChanged,
        skipIntroQuest = skipIntroQuest,
    }
}
