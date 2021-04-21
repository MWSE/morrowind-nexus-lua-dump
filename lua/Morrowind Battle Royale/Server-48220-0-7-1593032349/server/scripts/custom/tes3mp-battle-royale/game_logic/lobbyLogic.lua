lobbyLogic = {}

-- indicates if match proposal is currently in progress
matchProposalInProgress = false

-- list of players (PIDs) who are ready to start a match
-- used just for the pre-match logic. If criteria for starting the match is met, playerList becomes a copy of this list
readyList = {}

function EndMatchProposal()
    tes3mp.LogMessage(2, "Ending current match proposal")
    matchProposalInProgress = false
    brDebug.Log(3, "readyList has " .. tostring(#readyList) .. " PIDs in it")
	if lobbyLogic.CanStartMatch() then
        brDebug.Log(1, "Match can be started")
        matchLogic.Start()
	else
		tes3mp.SendMessage(0, "Match was not started.\n", true)
        if brConfig.automaticMatchmaking then
            lobbyLogic.StartMatchProposal()
        end
	end
    readyList = {}
end

-- Used by players to enlist themselves as participants in the next match
lobbyLogic.PlayerConfirmParticipation = function(pid)
    -- TODO: figure out proper criteria for this
    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() and not tableHelper.containsValue(readyList, pid) and not matchLogic.IsMatchInProgress() then
        table.insert(readyList, pid)
        tes3mp.SendMessage(pid, color.Yellow .. Players[pid].data.login.name .. " is ready.\n", true)
        brDebug.Log(1, "readyList has " .. tostring(#readyList) .. " PIDs in it")
	end
end

-- starts a new match proposal
lobbyLogic.StartMatchProposal = function()
    brDebug.Log(3, "Running StartMatchProposal function")
    -- check if there are at least 2 players on server and that there is no other match proposal already in progress
    -- At this stage the #Players shows 0 after 1 player is online and 1 once second players is online
    -- So instead of trying to figure out why this is so, we will just shift things for 1, replacing 1 with 0
    -- This is not a problem with TES3MP code, this is because LUA is using some awful voodoo backwards logic for tables
    if lobbyLogic.CanStartMatchProposal() then
        --if not testBR.matchInProgress and not matchProposalInProgress then
        tes3mp.LogMessage(2, "Proposing a start of a new match")
        tes3mp.SendMessage(0, "New match is being proposed. Type " .. color.Yellow .. "/ready" .. color.White .. " in the next " .. tostring(brConfig.matchProposalTime) .. " seconds in order to join.\n", true)
        matchProposalInProgress = true
        readyList = {}
        matchProposalTimer = tes3mp.CreateTimerEx("EndMatchProposal", time.seconds(brConfig.matchProposalTime), "i", 1)
        tes3mp.StartTimer(matchProposalTimer)
    else
        brDebug.Log(3, "#Players: " .. tostring(#Players) .. ", matchInProgress: " .. tostring(matchLogic.matchInProgress) .. ", matchProposalInProgress" .. tostring(matchProposalInProgress))
        reasonMessage = "Something went horribly wrong on the server. This should NEVER happen. Go yell at testman\n"
        if #Players <= 0 then
            tes3mp.LogMessage(2, "Not enough players to start match proposal")
            reasonMessage = "New match proposal was not started because there are not enough players on the server.\n"
        elseif matchLogic.IsMatchInProgress() then
            tes3mp.LogMessage(2, "Match in progress, won't start proposal for new one")
            reasonMessage = "New match proposal was not started because the match is currently in progress.\n"
        elseif matchProposalInProgress then
            tes3mp.LogMessage(2, "Match proposal already in process")
            reasonMessage = "New match proposal was not started because one is already in progress.\n"
        end
        if #Players > 0 then
            -- send message only to players in lobby, since it's not relevant to players who are already in match
            for pid, player in pairs(Players) do
                if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
                    tes3mp.SendMessage(pid, reasonMessage, false)
                end
            end
        end
    end
end

lobbyLogic.GetReadyList = function()
  return readyList
end

-- returns true if criteria for starting the match is met
lobbyLogic.CanStartMatch = function()
    if #readyList >= 2 then
        return true
    end
    return false
end

lobbyLogic.CanStartMatchProposal = function()
    if #Players > 0 and not matchLogic.IsMatchInProgress() and not matchProposalInProgress then
        return true
    end
    return false
end

return lobbyLogic
