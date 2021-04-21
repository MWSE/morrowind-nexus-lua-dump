local modInfo = require('akh.SoullessCreatures.ModInfo')
local config = require("akh.SoullessCreatures.Config")

local function filter(predicate)

    local baseCreatures = {}
    for obj in tes3.iterateObjects(tes3.objectType.creature) do
        if not (obj.baseObject and obj.baseObject.id ~= obj.id ) and predicate(obj) then
            baseCreatures[#baseCreatures+1] = (obj.baseObject or obj).id:lower()
        end
    end
    table.sort(baseCreatures)
    return baseCreatures

end

local function registerModConfig()

    local template = mwse.mcm.createTemplate{
        name = modInfo.modName,
        headerImagePath="\\Textures\\akh\\SoullessCreatures\\logo.tga"
    }
    template:saveOnClose(modInfo.modName, config)
    template:register()

    template:createExclusionsPage{
        label = "Soulless Creatures",
        variable = mwse.mcm.createTableVariable{ id = "creatures", table = config},
        description = 'Creatures on the "Blocked" list will have their soul value set to zero effectively preventing their souls from being trapped. Defaults to vanilla summons.',
        filters = {
            {
                label = "All",
                callback = function()
                    return filter(function(obj) return true end)
                end
            },
            {
                label = "Summons",
                callback = function()
                    return filter(function(obj)
                        return string.find(obj.id:lower(), "summon")
                    end)
                end
            },
            {
                label = "Normal",
                callback = function()
                    return filter(function(obj)
                        return obj.type == tes3.creatureType.normal
                    end)
                end
            },
            {
                label = "Humanoid",
                callback = function()
                    return filter(function(obj)
                        return obj.type == tes3.creatureType.humanoid
                    end)
                end
            },
            {
                label = "Daedra",
                callback = function()
                    return filter(function(obj)
                        return obj.type == tes3.creatureType.daedra
                    end)
                end
            },
            {
                label = "Undead",
                callback = function()
                    return filter(function(obj)
                        return obj.type == tes3.creatureType.undead
                    end)
                end
            }
        }
    }

end

event.register("modConfigReady", registerModConfig)