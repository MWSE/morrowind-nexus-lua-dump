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
    {
        id = "weapon",
        requirements = function(e)
            return e.reference.baseObject.objectType == tes3.objectType.weapon
        end
    },
    {
        id = "armor",
        requirements = function(e)
            return e.reference.baseObject.objectType == tes3.objectType.armor
        end
    },
    {
        id = "clothing",
        requirements = function(e)
            return e.reference.baseObject.objectType == tes3.objectType.clothing
        end
    },
    {
        id = "container",
        requirements = function(e)
            return e.reference.baseObject.objectType == tes3.objectType.container
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
    },
    {
        id = "azura",
        name = "Азура'",
        objectIds = {"azura"},
    }
}

for _, subject in ipairs(subjects) do
    Subject.registerSubject(subject)
end