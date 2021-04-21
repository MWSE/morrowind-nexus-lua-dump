local reportLocations = {
    { position = { -313, -1486, -763 }, orientation = { 0, 0, 149 } },
    { position = { 119, -1720, -594 }, orientation = { 0, 0, 172 } },
    { position = { 577, -1586, -679 }, orientation = { 337, 11, 172 } },
    { position = { 602, -1351, -758 }, orientation = { 0, 57, 183 } },
    { position = { 274, -1625, -731 }, orientation = { 0, 0, 183 } },
    { position = { 568, -1743, -759 }, orientation = { 315, 0, 270 } },
    { position = { 3, -1316, -763 }, orientation = { 0, 0, 225 } },
    { position = { -862, -1095, -727 }, orientation = { 343, 319, 198 } },
    { position = { 574, -737, -763 }, orientation = { 0, 0, 115 } },
    { position = { 603, -274, -659 }, orientation = { 0, 286, 276 } },
    { position = { -791, -851, -729 }, orientation = { 0, 0, 160 } },
    { position = { -292, -1335, -606 }, orientation = { 0, 0, 53 } },
    { position = { 293, -182, -251 }, orientation = { 0, 0, 16 } },
    { position = { 205, -366, -202 }, orientation = { 15, 355, 93 } },
    { position = { -554, 70, 5 }, orientation = { 0, 0, 80 } },
    { position = { -571, 61, -251 }, orientation = { 0, 0, 52 } },
    { position = { 614, -1405, -666 }, orientation = { 0, 0, 0 } },
    { position = { 577, -1630, -622 }, orientation = { 9, 16, 93 } },
    { position = { -621, -314, -200 }, orientation = { 11, 344, 1 } },
    { position = { -287, -132, -244 }, orientation = { 57, 2, 92 } } ,
    { position = { -454, -680, -758 }, orientation = { 308, 354, 270 } },
    { position = { -791, -740, -761 }, orientation = { 0, 0, 40 } },
}

local function onJournal(e)
    if e.topic.id == "MG_StolenReport" then
        if e.index == 10 then 
            
            --randomise first report location
            local report1 = tes3.getReference("bk_Ajira1")
            local location1 = table.choice(reportLocations) 
            if report1 then
                timer.delayOneFrame(function()
                    tes3.positionCell{
                        cell = "Balmora, Guild of Mages", 
                        position = location1.position, 
                        orientation = location1.orientation, 
                        reference = report1
                    };
                end)
                
            end

            --randomise second report locoation
            local report2 = tes3.getReference("bk_Ajira2")
            local location2 = table.choice(reportLocations)
            --Keep picking until they are different locations
            while location1 == location2 do
                location2 = table.choice(reportLocations)
            end
            if report2 then
                timer.delayOneFrame(function()
                    tes3.positionCell{
                        cell = "Balmora, Guild of Mages", 
                        position = location2.position, 
                        orientation = location2.orientation, 
                        reference = report2
                    };
                end)
            end
        end
    end
end


event.register("journal", onJournal)