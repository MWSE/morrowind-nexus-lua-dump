local dummies = {}

dummies.dummyList = {
    -- vanilla
    ["furn_practice_dummy"] = true,
    -- TD
    ["t_com_furn_practicedummy"] = true,
}

dummies.isDummy = function(obj)
    return obj and dummies.dummyList[obj.recordId]
end

return dummies
