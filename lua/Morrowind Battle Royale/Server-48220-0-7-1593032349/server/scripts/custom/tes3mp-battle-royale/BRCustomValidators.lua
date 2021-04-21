-- custom validator for cell change
customEventHooks.registerValidator("OnPlayerCellChange", function(eventStatus, pid)
	tes3mp.LogMessage(2, "Player " .. pid .. " trying to enter cell " .. tostring(tes3mp.GetCell(pid)))

    if mapLogic.ValidateCell(pid) then
        return customEventHooks.makeEventStatus(true,true)
    else
        playerLogic.WarnPlayerAboutInterior(pid)
        return customEventHooks.makeEventStatus(false,true)
    end

end)
