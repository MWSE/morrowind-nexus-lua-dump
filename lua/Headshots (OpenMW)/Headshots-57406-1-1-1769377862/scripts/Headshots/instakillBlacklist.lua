local imaGodHowCanYouKillAGod = {
    ["dagoth_ur_2"] = true,
    ["heart_akulakhan"] = true,
}

local fakeEssential = {
    -- morrowind
    ["crazy_batou"] = true,
    ["goris the maggot king"] = true,
    ["luven"] = true
}

function InInstakillBlacklist(actor)
    if      fakeEssential[string.lower(actor.recordId)] then            return false
    elseif  actor.type.records[actor.recordId].isEssential then         return true
    elseif  imaGodHowCanYouKillAGod[string.lower(actor.recordId)] then  return true
    else                                                                return false end
end
