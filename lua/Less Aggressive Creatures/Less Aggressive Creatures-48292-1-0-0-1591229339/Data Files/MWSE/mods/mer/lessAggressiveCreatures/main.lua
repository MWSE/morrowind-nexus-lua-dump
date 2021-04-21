local configPath = "LessAggressiveCreatures"
local config = mwse.loadConfig(configPath, {
    enabled = true,
    peacefulChance = 50,
    creatureList = {
        ["cliff racer"] = true,
    }
})

local function onMobileActivated(e)
    if not config.enabled then return end
    local obj = e.reference.baseObject or e.reference.object
    if config.creatureList[string.lower(obj.id)] then
        if math.random(100) <= config.peacefulChance then
            e.reference.mobile.fight = 0
        end
    end
end

event.register("mobileActivated", onMobileActivated)

local function registerMCM()
    local template = mwse.mcm.createTemplate("Less Aggressive Creatures")
    template:saveOnClose(configPath, config)
    template:register()

    local page = template:createSideBarPage{
        label = "Settings",
        description = "Gives a chance for certain creatures to be spawned with a fight setting of 0. Configure the list of passive creatures on the Whitelist page."
    }
    page:createYesNoButton{
        label = "Enable Mod",
        description = "Turn this mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
    }
    page:createSlider{
        label = "Peaceful Chance",
        description = "The % chance that a spawned creature will be passive.",
        min = 0,
        max = 100,
        variable = mwse.mcm.createTableVariable{ id = "peacefulChance", table = config }
    }

    template:createExclusionsPage{
        label = "Peaceful Creatures Whitelist",
        variable = mwse.mcm.createTableVariable{ id = "creatureList", table = config},
        filters = {
            {
                label = "Creatures",
                callback = function()
                    local baseCreatures = {}
                    for obj in tes3.iterateObjects(tes3.objectType.creature) do
                        if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                            baseCreatures[#baseCreatures+1] = (obj.baseObject or obj).id:lower()
                        end
                    end
                    table.sort(baseCreatures)
                    return baseCreatures
                end
            }
        }
    }
end
event.register("modConfigReady", registerMCM)