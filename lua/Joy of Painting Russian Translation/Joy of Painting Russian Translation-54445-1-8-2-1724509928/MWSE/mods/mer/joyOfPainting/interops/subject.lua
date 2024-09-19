local Subject = require("mer.joyOfPainting").Subject

---@type JOP.Subject.registerSubjectParams[]
local subjects = {
    --Subjects by objectType
    {
        id = "npc",
        requirements = function(e)
            return e.reference.baseObject.objectType == tes3.objectType.npc
        end
    },
    {
        id = "creature",
        requirements = function(e)
            return e.reference.baseObject.objectType == tes3.objectType.creature
        end
    },
    {
        id = "activator",
        requirements = function(e)
            return e.reference.baseObject.objectType == tes3.objectType.activator
                and e.reference.object.name ~= nil
                and e.reference.object.name ~= ""
        end
    },

    --Points of Interest
    {
        id = "lighthouse",
        name = "Маяк",
        objectIds = {"ex_common_lighthouse"},
    },
    {
        id = "skar",
        name = "Скар",
        objectIds = {"ex_ar_01"},
    },
    {
        id = "dwarventower",
        name = "Двемерская башня",
        objectIds = {
            "ex_dwrv_ruin_tower00",
            "AB_Ex_DwrvTower00Intact",
        },
    }
}

for _, subject in ipairs(subjects) do
    Subject.registerSubject(subject)
end