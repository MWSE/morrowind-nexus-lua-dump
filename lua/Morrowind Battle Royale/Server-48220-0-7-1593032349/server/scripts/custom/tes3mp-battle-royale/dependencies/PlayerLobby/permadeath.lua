local PermaDeath = {}

function PermaDeath.OnPlayerDeath(eventStatus, pid)
    if eventStatus.validDefaultHandler then
        local player = Players[pid]
        player.data.customVariables.dead = true
        PlayerLobby.teleportToLobby(pid)
        tes3mp.Resurrect(pid, 5)
        return customEventHooks.makeEventStatus(false, false)
    end
end

function PermaDeath.LeaveAttempt(eventStatus, pid)
    tes3mp.LogMessage(enumerations.log.INFO, "PlayerLobby_Leave")
    if eventStatus.validDefaultHandler then
        if Players[pid].data.customVariables.dead then
            PlayerLobby.teleportToLobby(pid)
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

function PermaDeath.resurrect(eventStatus, pid)
    Players[pid].data.customVariables.dead = nil
end

customEventHooks.registerValidator("OnPlayerDeath", PermaDeath.OnPlayerDeath)

customEventHooks.registerValidator("PlayerLobby_Leave", PermaDeath.LeaveAttempt)

return PermaDeath