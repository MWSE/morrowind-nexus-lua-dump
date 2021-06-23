local common = require("mer.bardicInspiration.common")
local messages = require("mer.bardicInspiration.messages.messages")

local function registerModConfig()
    local config = mwse.loadConfig(common.staticData.configPath, common.defaultConfig)
    local template = mwse.mcm.createTemplate{ name = messages.modName }
    template.onClose = function()
        common.config.save(config)
    end
    template:register()

    local settings = template:createSideBarPage{
        label = messages.mcm_page_settings,
        description = messages.mcm_page_description,
    }

    settings:createOnOffButton{
        label = string.format("Enable %s", common.modName),
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = config }
    }

    settings:createDropdown{
        label = messages.mcm_debug_label,
        description = messages.mcm_debug_description,
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
        callback = function(self)
            common.log:setLogLevel(self.variable.value)
        end
    }

    local function createSongListPostCreate(difficulty)
        return function(self)
            if common.data.knownSongs then
                local list = ""
                local knownSongs = table.copy(common.data.knownSongs)
                if #knownSongs == 0 then
                    self.elements.info.text = "None"
                else
                    table.sort(knownSongs, common.songSorter)

                    for _, song in ipairs(knownSongs) do
                        if song.difficulty == difficulty then
                            list = list .. song.name .. "\n"
                        end
                    end
                    list = string.sub(list, 1, -2)
                    self.elements.info.text = list
                end
            end
        end
    end

    local category = settings:createCategory("Songs Learned")
    local beginner = category:createCategory("Beginner:")
    beginner:createInfo{
        text = "",
        inGameOnly = true,
        postCreate = createSongListPostCreate("beginner")
    }
    local intermediate = category:createCategory("Intermediate:")
    intermediate:createInfo{
        text = "",
        inGameOnly = true,
        postCreate = createSongListPostCreate("intermediate")
    }
    local advanced = category:createCategory("Advanced:")
    advanced:createInfo{
        text = "",
        inGameOnly = true,
        postCreate = createSongListPostCreate("advanced")
    }
    

    template:createExclusionsPage{
        label = messages.mcm_tavernspage_name,
        description = messages.mcm_tavernspage_description,
        variable = mwse.mcm:createTableVariable{ id = "innkeepers", table = config },
        leftListLabel = messages.mcm_tavernspage_leftListLabel,
        rightListLabel = messages.mcm_tavernspage_rightListLabel,
        filters = {
            {
                label = "",
                callback = function()
                    local npcs = {}
                    for obj in tes3.iterateObjects(tes3.objectType.npc) do
                        local id = (obj.baseObject or obj).id:lower()
                        npcs[id] = true
                    end
                    local npcsList = {}
                    for npc, _ in pairs(npcs) do
                        table.insert(npcsList, npc)
                    end
                    table.sort(npcsList)
                    return npcsList
                end
            }
        }
    }
end
event.register("modConfigReady", registerModConfig)
