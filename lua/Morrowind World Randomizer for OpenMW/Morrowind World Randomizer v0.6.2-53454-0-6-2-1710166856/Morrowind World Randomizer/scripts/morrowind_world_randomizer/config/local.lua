local types = require('openmw.types')

local advTable = require("scripts.morrowind_world_randomizer.utils.table")
local stringLib = require("scripts.morrowind_world_randomizer.utils.string")

local objectIds = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

---@class mwr.config
local this = {}

local delimiter = "."

this.storageName = "Settings_MWR_By_Diject"

---@class mwr.configData
this.default = {
    version = 3,
    enabled = false,
    randomizeAfter = 720,
    randomizeOnce = false,
    cellLoadingTime = 0.5,
    doNot = {
        activatedContainers = true,
    },
    world = {
        item = {
            randomize = true,
            rregion = {
                min = 20,
                max = 20,
            },
        },
        static = {
            tree = {
                randomize = true,
                typesPerCell = 2,
            },
            rock = {
                randomize = true,
                typesPerCell = 2,
            },
            flora = {
                randomize = true,
                typesPerCell = 4,
            },
        },
        herb = {
            randomize = true,
            item = {
                randomize = false,
                rregion = {
                    min = 20,
                    max = 20,
                },
            },
            typesPerCell = 4,
        },
        light = {
            randomize = true,
        },
    },
    npc = {
        item = {
            randomize = true,
            rregion = {
                min = 20,
                max = 20,
            },
        },
        stat = {
            dynamic = {
                randomize = true,
                additive = false,
                health = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
                fatigue = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
                magicka = {
                    vregion = {
                        min = 1,
                        max = 2,
                    },
                },
            },
            attributes = {
                randomize = true,
                additive = false,
                vregion = {
                    min = 0.75,
                    max = 1.25,
                },
                limit = 255,
            },
            skills = {
                randomize = true,
                additive = true,
                vregion = {
                    min = -40,
                    max = 40,
                },
                limit = 100,
            },
        },
        spell = {
            randomize = true,
            bySchool = true,
            bySkill = false,
            levelReference = 20,
            bySkillMax = 2,
            rregion = {
                min = 20,
                max = 20,
            },
            add = {
                count = 2,
                bySkill = true,
                bySkillMax = 2,
                levelReference = 20,
                rregion = {
                    min = 20,
                    max = 20,
                },
            },
            remove = {
                count = 0,
            },
        },
    },
    creature = {
        randomize = true,
        onlyLeveled = true,
        byType = false,
        killParent = true,
        rregion = {
            min = 20,
            max = 20,
        },
        item = {
            randomize = true,
            rregion = {
                min = 20,
                max = 20,
            },
        },
        stat = {
            dynamic = {
                randomize = true,
                additive = false,
                health = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
                fatigue = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
                magicka = {
                    vregion = {
                        min = 1,
                        max = 2,
                    },
                },
            },
        },
        spell = {
            randomize = true,
            bySchool = true,
            rregion = {
                min = 20,
                max = 20,
            },
            add = {
                count = 2,
                levelReference = 20,
                rregion = {
                    min = 20,
                    max = 20,
                },
            },
            remove = {
                count = 0,
            },
        },
    },
    container = {
        item = {
            randomize = true,
            rregion = {
                min = 20,
                max = 20,
            },
        },
        lock = {
            chance = 100,
            maxValue = 100,
            rregion = {
                min = 30,
                max = 30,
            },
            add = {
                chance = 15,
                levelReference = 1,
            },
            remove = {
                chance = 25,
            },
        },
        trap = {
            chance = 100,
            levelReference = 1,
            add = {
                chance = 25,
                levelReference = 1,
            },
            remove = {
                chance = 25,
            },
        },
    },
    door = {
        lock = {
            chance = 100,
            maxValue = 100,
            rregion = {
                min = 30,
                max = 30,
            },
            add = {
                chance = 5,
                levelReference = 15,
            },
            remove = {
                chance = 20,
            },
        },
        trap = {
            chance = 100,
            levelReference = 1,
            add = {
                chance = 10,
                levelReference = 1,
            },
            remove = {
                chance = 25,
            },
        },
    },
    item = {
        safeMode = true,
        safeModeThreshold = 2,
        artifactsAsSeparate = true,
        new = {
            chance = 25,
            threshold = 5,
            change = {
                name = false,
                model = true,
                icon = true,
                prefix = true,
                enchantment = true,
            },
            linkIconToModel = false,
            model = {
                rregion = {
                    min = 100,
                    max = 100,
                },
            },
            stats = {
                rregion = {
                    min = 20,
                    max = 20,
                },
            },
            enchantment = {
                chance = 50,
                rregion = {
                    min = 20,
                    max = 20,
                },
            },
            effects = {
                add = {
                    chance = 50,
                    vregion = {
                        min = 1,
                        max = 2,
                    },
                },
                remove = {
                    chance = 25,
                    vregion = {
                        min = 1,
                        max = 1,
                    },
                },
            },
        },
    },
    other = {
        restockFix = {
            enabled = true,
            iregion = {
                min = 1,
                max = 5,
            },
        },
    },
}

---@type mwr.configData
this.data = advTable.deepcopy(this.default)

function this.loadData(data)
    if not data then return end
    advTable.applyChanges(this.data, data)
end

---@param objectType any
function this.getConfigTableByObjectType(objectType)
    if objectType == nil then
        return this.data.world
    elseif objectType == objectIds.npc or objectType == types.NPC then
        return this.data.npc
    elseif objectType == objectIds.creature or objectType == types.Creature then
        return this.data.creature
    elseif objectType == objectIds.container or objectType == types.Container then
        return this.data.container
    elseif objectType == objectIds.door or objectType == types.Door then
        return this.data.door
    elseif objectType == objectIds.static then
        return this.data.world.static
    elseif objectType == "HERB" then
        return this.data.world.herb
    end
    return nil
end

function this.setValueByString(val, str)
    local var = this.data
    local lastName
    local prevVar
    for _, varName in ipairs(stringLib.split(str, delimiter)) do
        if var[varName] ~= nil then
            lastName = varName
            prevVar = var
            var = var[lastName]
        else
            return false
        end
    end
    if lastName then
        if prevVar ~= nil then
            prevVar[lastName] = val
        else
            var[lastName] = val
        end
        return true
    end
    return false
end

function this.getValueByString(str)
    local var = this.data
    for _, varName in pairs(stringLib.split(str, delimiter)) do
        if var[varName] ~= nil then
            var = var[varName]
        else
            return nil
        end
    end
    return var
end

function this.loadPlayerSettings(storageTable)
    for name, val in pairs(storageTable) do
        this.setValueByString(val, name)
    end
end

function this.savePlayerSettings(storage)
    local function saveData(var, str)
        if type(var) == "userdata" or type(var) == "table" then
            for valName, val in pairs(var) do
                saveData(val, str and str..delimiter..valName or valName)
            end
        else
            storage:set(str, var)
        end
    end
    saveData(this.data, nil)
end

return this