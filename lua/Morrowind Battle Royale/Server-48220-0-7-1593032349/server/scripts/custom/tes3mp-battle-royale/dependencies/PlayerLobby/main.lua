local PlayerLobby = {}

PlayerLobby.scriptName = "PlayerLobby"

PlayerLobby.defaultConfig = {
    cell = "Mark's Vampire Test Cell",
    pos = {
        0,
        0,
        0
    },
    rot = {
        0,
        0
    },
    invulnerability = true,
    noDrops = true
}

PlayerLobby.config = DataManager.loadConfiguration(PlayerLobby.scriptName, PlayerLobby.defaultConfig)


function PlayerLobby.teleportToLobby(pid)
    tes3mp.SetCell(pid, PlayerLobby.config.cell)
    tes3mp.SendCell(pid)

    tes3mp.SetRot(
        pid,
        PlayerLobby.config.rot[1],
        PlayerLobby.config.rot[2]
    )
    tes3mp.SetPos(
        pid,
        PlayerLobby.config.pos[1],
        PlayerLobby.config.pos[2],
        PlayerLobby.config.pos[3]
    )
    tes3mp.SendPos(pid)
end


function PlayerLobby.OnPlayerEndCharGen(eventStatus, pid)
    if eventStatus.validDefaultHandler then
        PlayerLobby.teleportToLobby(pid)
    end
end

function PlayerLobby.OnPlayerDeath(eventStatus, pid)
    if eventStatus.validDefaultHandler and PlayerLobby.config.invulnerability then
        if tes3mp.GetCell(pid) == PlayerLobby.config.cell then
            tes3mp.Resurrect(pid, 5)
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end


function PlayerLobby.OnPlayerCellChangeV(eventStatus, pid, prev, next)
    if prev == PlayerLobby.config.cell and next ~= PlayerLobby.config.cell then
        return customEventHooks.triggerValidators("PlayerLobby_Leave", {pid})
    end
end

function PlayerLobby.OnPlayerCellChangeH(eventStatus, pid, prev, next)
    if prev == PlayerLobby.config.cell and next ~= PlayerLobby.config.cell then
        customEventHooks.triggerHandlers("PlayerLobby_Leave", eventStatus, {pid})
    end
end

function PlayerLobby.OnObjectPlaceV(eventStatus, pid)
    if PlayerLobby.config.noDrops and tes3mp.GetCell(pid) == PlayerLobby.config.cell then
        local inventory = Players[pid].data.inventory

        for objectIndex = 0, tes3mp.GetObjectListSize() - 1 do
            local refId = tes3mp.GetObjectRefId(objectIndex)
            local count = tes3mp.GetObjectCount(objectIndex)
            local charge = tes3mp.GetObjectCharge(objectIndex)
            local enchantmentCharge = tes3mp.GetObjectEnchantmentCharge(objectIndex)
            local soul = tes3mp.GetObjectSoul(objectIndex)
            
            inventoryHelper.addItem(inventory, refId, count, charge, enchantmentCharge, soul)

            tes3mp.ClearInventoryChanges(pid)
            tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
            tes3mp.AddItemChange(pid, refId, count, charge, enchantmentCharge, soul)
            tes3mp.SendInventoryChanges(pid, false, false)
        end

        return customEventHooks.makeEventStatus(false, false)
    end
end


customEventHooks.registerHandler("OnPlayerEndCharGen", PlayerLobby.OnPlayerEndCharGen)

customEventHooks.registerValidator("OnPlayerDeath", PlayerLobby.OnPlayerDeath)

customEventHooks.registerValidator("OnPlayerCellChange", PlayerLobby.OnPlayerCellChangeV)
customEventHooks.registerHandler("OnPlayerCellChange", PlayerLobby.OnPlayerCellChangeH)

customEventHooks.registerValidator("OnObjectPlace", PlayerLobby.OnObjectPlaceV)

return PlayerLobby