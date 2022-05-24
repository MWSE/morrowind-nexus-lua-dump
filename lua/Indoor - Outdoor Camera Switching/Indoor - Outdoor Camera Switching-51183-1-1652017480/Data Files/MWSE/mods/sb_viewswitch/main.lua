--- @param e cellChangedEventData
local function cellChangedCallback(e)
    if (e.cell.isInterior) then
        tes3.force1stPerson()
    else
        tes3.force3rdPerson()
    end
end
event.register(tes3.event.cellChanged, cellChangedCallback)
