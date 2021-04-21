
customEventHooks.registerHandler("OnServerPostInit", function(eventStatus, pid)
	if eventStatus.validCustomHandlers then --check if some other script made this event obsolete
		testBR.OnServerPostInit()
	end
end)

customEventHooks.registerHandler("OnPlayerFinishLogin", function(eventStatus, pid)
	if eventStatus.validCustomHandlers then --check if some other script made this event obsolete
		--testBR.VerifyPlayerData(pid)
        -- check if player count is high enough to start automatic process
        if brConfig.automaticMatchmaking and not lobbyLogic.matchProposalInProgress and not matchLogic.matchInProgress then
            lobbyLogic.StartMatchProposal()
        end

        playerLogic.PlayerInit(pid, true)

	end
end)

customEventHooks.registerHandler("OnPlayerDisconnect", function(eventStatus, pid)
	if eventStatus.validCustomHandlers then --check if some other script made this event obsolete
        if matchLogic.IsPlayerInMatch(pid) then
            matchLogic.RemovePlayerFromPlayerList(pid)
            matchLogic.CheckVictoryConditions()
        end
	end
end)

customEventHooks.registerHandler("OnPlayerDeath", function(eventStatus, pid)
	if eventStatus.validCustomHandlers then --check if some other script made this event obsolete
		playerLogic.ProcessDeath(pid)
	end
end)

--[[ lol why is this here again? Was it for removing containers and NPCS/creatures?
customEventHooks.registerHandler("OnCellLoad", function(eventStatus, pid)
	if eventStatus.validCustomHandlers then --check if some other script made this event obsolete
		--testBR.OnCellLoad(pid)
	end
end)
]]

customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid)
	if eventStatus.validCustomHandlers then --check if some other script made this event obsolete
		playerLogic.ProcessCellChange(pid)
	end
end)

customEventHooks.registerHandler("OnPlayerEndCharGen", function(eventstatus, pid)
	if Players[pid] ~= nil then
		--tes3mp.LogMessage(2, "++++ Newly created: " .. tostring(pid))
		playerLogic.EndCharGen(pid)
        if brConfig.automaticMatchmaking and not lobbyLogic.matchProposalInProgress and not matchLogic.matchInProgress then
            lobbyLogic.StartMatchProposal()
        end
    end
end)

