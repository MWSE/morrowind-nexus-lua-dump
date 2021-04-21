local teleport = function(pid, cell, x, y, z, rx, rz)
    tes3mp.SetCell(pid, cell)
    tes3mp.SendCell(pid)

    tes3mp.SetRot( pid, rx, rz )
    tes3mp.SetPos( pid, x, y, z )
    tes3mp.SendPos(pid)
end

SupportTickets.registerAdminAction("Ticket location", function(pid, ticket)
    teleport(
        pid,
        ticket.location.cell,
        ticket.location.x,
        ticket.location.y,
        ticket.location.z,
        0,
        0
    )
end)

SupportTickets.registerAdminAction("Player location", function(pid, ticket)
    local player = logicHandler.GetPlayerByName(ticket.playerName)
    if player ~= nil then
        local loc = player.data.location
        teleport(
            pid,
            loc.cell,
            loc.posX,
            loc.posY,
            loc.posZ,
            loc.rotX,
            loc.rotZ
        )
    end
end)