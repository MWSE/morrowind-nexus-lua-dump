local Leeches = require("leeches.leeches")

--- Place leeches around the quest corpses.
---
local function placeLeeches()
    local positions = {
        { -26422.02, -43554.86, 648.77 },
        { -26300.14, -43680.22, 656.34 },
        { -26351.21, -43653.02, 649.75 },
        { -26435.97, -43575.61, 655.25 },
        { -26393.21, -43513.46, 634.76 },
        { -26262.09, -43689.08, 658.64 },
        { -26340.49, -43611.46, 645.19 },
    }
    local orientations = {
        { 0.26, 6.25,  1.13 },
        { 0.12, 0.06,  1.77 },
        { 6.16, 0.07,  4.69 },
        { 0.19, 6.10,  0.56 },
        { 0.30, 6.11,  5.97 },
        { 0.06, -0.00, 0.66 },
        { 0.12, 0.06,  3.93 },
    }
    for i = 1, #positions do
        tes3.createReference({
            object = "leech_ingred",
            position = positions[i],
            orientation = orientations[i],
        })
    end
end

local function attachCorpseLeeches()
    local timestamp = tes3.getSimulationTimestamp()
    for _, id in pairs({ "leech_npc_varel", "leech_npc_tilse" }) do
        local ref = tes3.getReference(id)
        if ref then
            local leeches = Leeches.getOrCreate(ref)
            for _ = 1, 60 do
                leeches:addLeech(ref, timestamp)
            end
        end
    end
end

---@param e journalEventData
event.register("journal", function(e)
    if e.topic.id == "leech_mq_02" and e.index == 70 then
        placeLeeches()
        attachCorpseLeeches()
    end
end)
