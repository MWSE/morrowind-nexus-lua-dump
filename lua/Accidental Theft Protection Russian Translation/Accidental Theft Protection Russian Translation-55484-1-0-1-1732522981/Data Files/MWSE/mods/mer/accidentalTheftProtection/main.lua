local modName = "Защита от случайной кражи"
local configPath = "noAccidentalTheft"
local config = mwse.loadConfig(configPath, {
    enabled = true,
    blacklist = {}
})

local function isBlacklisted(ref)
    return config.blacklist[string.lower(ref.object.id)]
end

local function onActivate(e)
    if config.enabled then
        if not tes3.hasOwnershipAccess{target = e.target} then
            if not tes3.player.mobile.isSneaking then
                if not isBlacklisted(e.target) then
                    return false
                end
            end
        end
    end
end

event.register("activate", onActivate)

local function registerMCM()
    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(configPath, config)
    template:register()

    local settingsDescription = (
        "Этот мод предотвращает случайную кражу предметов, вы сможете брать предметы только в режиме скрытности."
    )
    local settingsPage = template:createPage{
        label = "Настройки",
        --description = settingsDescription
        noScroll = true,
        indent = 0,
        postCreate = function(self)
            self.elements.innerContainer.paddingAllSides = 10
        end
    }

    do 
        local category = settingsPage:createCategory(modName)
        category:createInfo{ text = settingsDescription }

        settingsPage:createYesNoButton{
            label = "Включить мод",
            variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
        }

        settingsPage:createExclusionsPage{
            createOuterContainer = function(self, parent)
                local outerContainer = parent:createBlock()
                outerContainer.flowDirection = "top_to_bottom"
                outerContainer.widthProportional = 1.0
                outerContainer.heightProportional = 1.0
                self.elements.outerContainer = outerContainer
            end,
            label = "Черный список",
            variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config },
            filters = {
                {
                    label = "Зелья",
                    type = "Object",
                    objectType = tes3.objectType.alchemy,
                },
                {
                    label = "Болты\\Стрелы",
                    type = "Object",
                    objectType = tes3.objectType.ammunition,
                },
                {
                    label = "Устройства",
                    type = "Object",
                    objectType = tes3.objectType.apparatus,
                },
                {
                    label = "Доспехи",
                    type = "Object",
                    objectType = tes3.objectType.armor,
                },
                {
                    label = "Книги",
                    type = "Object",
                    objectType = tes3.objectType.book,
                },
                {
                    label = "Контейнеры",
                    type = "Object",
                    objectType = tes3.objectType.container,
                },
                {
                    label = "Одежда",
                    type = "Object",
                    objectType = tes3.objectType.clothing,
                },
                {
                    label = "Двери",
                    type = "Object",
                    objectType = tes3.objectType.door
                },
                {
                    label = "Ингредиенты",
                    type = "Object",
                    objectType = tes3.objectType.ingredient,
                },
                {
                    label = "Светильники",
                    callback = function()
                        local list = {}
                        for obj in tes3.iterateObjects(tes3.objectType.light) do
                            if obj.canCarry then
                                list[#list+1] = (obj.baseObject or obj).id:lower()
                            end
                            table.sort(list)
                        end
                        return list
                    end
                },
                {
                    label = "Отмычки",
                    type = "Object",
                    objectType = tes3.objectType.lockpick,
                },
                {
                    label = "Разное",
                    type = "Object",
                    objectType = tes3.objectType.miscItem,
                },
                {
                    label = "Щупы",
                    type = "Object",
                    objectType = tes3.objectType.probe,
                },
                {
                    label = "Инструменты",
                    type = "Object",
                    objectType = tes3.objectType.repairItem,
                },
                {
                    label = "Оружие",
                    type = "Object",
                    objectType = tes3.objectType.weapon,
                },
            }
        }
    end

   

end
event.register("modConfigReady", registerMCM)
