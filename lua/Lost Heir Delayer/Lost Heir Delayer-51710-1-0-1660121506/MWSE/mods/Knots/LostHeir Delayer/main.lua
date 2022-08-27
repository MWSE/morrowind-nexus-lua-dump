local sourceMod = "t_lostheir.esp"
local topic = "A2_4_MiloGone"
local journalIndex = 1

local function journalRequirementsAreMet()
    return tes3.getJournalIndex({ id = topic }) >= journalIndex
end

local function onReferenceActivated(e)
    if e.reference.sourceMod and e.reference.sourceMod:lower() == sourceMod:lower() then
        if not journalRequirementsAreMet() then
            e.reference:disable()
        elseif e.reference.disabled and not e.reference.data.enabledAfterJournalUpdate then
            e.reference.data.enabledAfterJournalUpdate = true
            e.reference:enable()
        end
    end
end

event.register("referenceActivated", onReferenceActivated)