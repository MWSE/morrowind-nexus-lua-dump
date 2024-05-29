--- @param e modConfigReadyEventData
local function OnModConfigReady(e)
    local config = require("InspectIt.config")
    local settings = require("InspectIt.settings")
    local template = mwse.mcm.createTemplate(settings.modName)
    template:saveOnClose(settings.configPath, config)
    template:register()

    local page = template:createSideBarPage({
        label = settings.i18n("mcm.page.label")
    })
    local info = page.sidebar:createInfo({
        label = string.format("%s %s",settings.modName, settings.version),
        text = settings.i18n("mcm.sidebar.info")
    })
    page.sidebar:createHyperlink({
        text = settings.metadata.package.homepage,
        url = settings.metadata.package.homepage,
    })
    page.sidebar:createHyperlink({
        text = settings.metadata.package.repository,
        url = settings.metadata.package.repository,
    })

    do
        local input = page:createCategory({
            label = settings.i18n("mcm.input.category.label"),
            description = settings.i18n("mcm.input.category.description"),
        })
        input:createKeyBinder({
            label = settings.i18n("mcm.input.inspect.label"),
            description = settings.i18n("mcm.input.inspect.description"),
            variable = mwse.mcm.createTableVariable({
                id = "inspect",
                table = config.input,
            }),
            allowCombinations = true,
            allowMouse = false,
        })
        input:createKeyBinder({
            label = settings.i18n("mcm.input.another.label"),
            description = settings.i18n("mcm.input.another.description"),
            variable = mwse.mcm.createTableVariable({
                id = "another",
                table = config.input,
            }),
            allowCombinations = true,
            allowMouse = false,
        })
        input:createKeyBinder({
            label = settings.i18n("mcm.input.lighting.label"),
            description = settings.i18n("mcm.input.lighting.description"),
            variable = mwse.mcm.createTableVariable({
                id = "lighting",
                table = config.input,
            }),
            allowCombinations = true,
            allowMouse = false,
        })
        input:createKeyBinder({
            label = settings.i18n("mcm.input.reset.label"),
            description = settings.i18n("mcm.input.reset.description"),
            variable = mwse.mcm.createTableVariable({
                id = "reset",
                table = config.input,
            }),
            allowCombinations = true,
            allowMouse = false,
        })

        input:createSlider({
            label = settings.i18n("mcm.input.sensitivityX.label"),
            description = settings.i18n("mcm.input.sensitivityX.description"),
            variable = mwse.mcm.createTableVariable({
                id = "sensitivityX",
                table = config.input,
            }),
            min = 0,
            max = 2,
            step = 0.01,
            jump = 0.05,
            decimalPlaces = 2,
        })
        input:createSlider({
            label = settings.i18n("mcm.input.sensitivityY.label"),
            description = settings.i18n("mcm.input.sensitivityY.description"),
            variable = mwse.mcm.createTableVariable({
                id = "sensitivityY",
                table = config.input,
            }),
            min = 0,
            max = 2,
            step = 0.01,
            jump = 0.05,
            decimalPlaces = 2,
        })
        input:createSlider({
            label = settings.i18n("mcm.input.sensitivityZ.label"),
            description = settings.i18n("mcm.input.sensitivityZ.description"),
            variable = mwse.mcm.createTableVariable({
                id = "sensitivityZ",
                table = config.input,
            }),
            min = 0,
            max = 2,
            step = 0.01,
            jump = 0.05,
            decimalPlaces = 2,
        })
        input:createOnOffButton({
            label = settings.i18n("mcm.input.inversionX.label"),
            description = settings.i18n("mcm.input.inversionX.description"),
            variable = mwse.mcm.createTableVariable({
                id = "inversionX",
                table = config.input,
            }),
        })
        input:createOnOffButton({
            label = settings.i18n("mcm.input.inversionY.label"),
            description = settings.i18n("mcm.input.inversionY.description"),
            variable = mwse.mcm.createTableVariable({
                id = "inversionY",
                table = config.input,
            }),
        })
        input:createOnOffButton({
            label = settings.i18n("mcm.input.inversionZ.label"),
            description = settings.i18n("mcm.input.inversionZ.description"),
            variable = mwse.mcm.createTableVariable({
                id = "inversionZ",
                table = config.input,
            }),
        })
    end
    do
        local inspection = page:createCategory({
            label = settings.i18n("mcm.inspection.category.label"),
            description = settings.i18n("mcm.inspection.category.description"),
        })
        inspection:createOnOffButton({
            label = settings.i18n("mcm.inspection.inventory.label"),
            description = settings.i18n("mcm.inspection.inventory.description"),
            variable = mwse.mcm.createTableVariable({
                id = "inventory",
                table = config.inspection,
            }),
        })
        inspection:createOnOffButton({
            label = settings.i18n("mcm.inspection.barter.label"),
            description = settings.i18n("mcm.inspection.barter.description"),
            variable = mwse.mcm.createTableVariable({
                id = "barter",
                table = config.inspection,
            }),
        })
        inspection:createOnOffButton({
            label = settings.i18n("mcm.inspection.contents.label"),
            description = settings.i18n("mcm.inspection.contents.description"),
            variable = mwse.mcm.createTableVariable({
                id = "contents",
                table = config.inspection,
            }),
        })
        inspection:createOnOffButton({
            label = settings.i18n("mcm.inspection.cursorOver.label"),
            description = settings.i18n("mcm.inspection.cursorOver.description"),
            variable = mwse.mcm.createTableVariable({
                id = "cursorOver",
                table = config.inspection,
            }),
        })
        inspection:createOnOffButton({
            label = settings.i18n("mcm.inspection.activatable.label"),
            description = settings.i18n("mcm.inspection.activatable.description"),
            variable = mwse.mcm.createTableVariable({
                id = "activatable",
                table = config.inspection,
            }),
        })
        inspection:createOnOffButton({
            label = settings.i18n("mcm.inspection.playSound.label"),
            description = settings.i18n("mcm.inspection.playSound.description"),
            variable = mwse.mcm.createTableVariable({
                id = "playSound",
                table = config.inspection,
            }),
        })
    end
    do
        local display = page:createCategory({
            label = settings.i18n("mcm.display.category.label"),
            description = settings.i18n("mcm.display.category.description"),
        })
        display:createOnOffButton({
            label = settings.i18n("mcm.display.instruction.label"),
            description = settings.i18n("mcm.display.instruction.description"),
            variable = mwse.mcm.createTableVariable({
                id = "instruction",
                table = config.display,
            }),
        })
        display:createOnOffButton({
            label = settings.i18n("mcm.display.bokeh.label"),
            description = settings.i18n("mcm.display.bokeh.description"),
            variable = mwse.mcm.createTableVariable({
                id = "bokeh",
                table = config.display,
            }),
        })
        display:createOnOffButton({
            label = settings.i18n("mcm.display.leftPart.label"),
            description = settings.i18n("mcm.display.leftPart.description"),
            variable = mwse.mcm.createTableVariable({
                id = "leftPart",
                table = config.display,
            }),
        })
        display:createOnOffButton({
            label = settings.i18n("mcm.display.recalculateBounds.label"),
            description = settings.i18n("mcm.display.recalculateBounds.description"),
            variable = mwse.mcm.createTableVariable({
                id = "recalculateBounds",
                table = config.display,
            }),
        })
        display:createOnOffButton({
            label = settings.i18n("mcm.display.tooltipsComplete.label"),
            description = settings.i18n("mcm.display.tooltipsComplete.description"),
            variable = mwse.mcm.createTableVariable({
                id = "tooltipsComplete",
                table = config.display,
            }),
        })
    end
    do
        local dev = page:createCategory({
            label = settings.i18n("mcm.development.category.label"),
            description = settings.i18n("mcm.development.category.description"),
        })
        dev:createOnOffButton({
            label = settings.i18n("mcm.development.experimental.label"),
            description = settings.i18n("mcm.development.experimental.description"),
            variable = mwse.mcm.createTableVariable({
                id = "experimental",
                table = config.development,
            }),
        })
        dev:createDropdown({
            label = settings.i18n("mcm.development.logLevel.label"),
            description = settings.i18n("mcm.development.logLevel.description"),
            options = {
                { label = "TRACE", value = "TRACE" },
                { label = "DEBUG", value = "DEBUG" },
                { label = "INFO",  value = "INFO" },
                { label = "WARN",  value = "WARN" },
                { label = "ERROR", value = "ERROR" },
                { label = "NONE",  value = "NONE" },
            },
            variable = mwse.mcm.createTableVariable({
                id = "logLevel",
                table = config.development,
            }),
            callback = function(self)
                local logger = require("InspectIt.logger")
                logger:setLogLevel(self.variable.value)
            end
        })
        dev:createOnOffButton({
            label = settings.i18n("mcm.development.logToConsole.label"),
            description = settings.i18n("mcm.development.logToConsole.description"),
            variable = mwse.mcm.createTableVariable({
                id = "logToConsole",
                table = config.development,
            }),
            callback = function(self)
                local logger = require("InspectIt.logger")
                logger.logToConsole = config.development.logToConsole
            end
        })
    end

    template:createExclusionsPage({
        label = settings.i18n("mcm.leftPartFilter.page.label"),
        description = settings.i18n("mcm.leftPartFilter.page.description"),
        leftListLabel = settings.i18n("mcm.leftPartFilter.page.normal"),
        rightListLabel = settings.i18n("mcm.leftPartFilter.page.mirror"),
        showHeader = true,
        variable = mwse.mcm.createTableVariable({
            id = "leftPartFilter",
            table = config,
        }),
        filters = {
            {
                label = settings.i18n("mcm.leftPartFilter.armor.label"),
                type = "Object",
                objectType = tes3.objectType.armor,
                objectFilters = {
                    isLeftPart = true,
                },
            },
            {
                label = settings.i18n("mcm.leftPartFilter.clothing.label"),
                type = "Object",
                objectType = tes3.objectType.clothing,
                objectFilters = {
                    isLeftPart = true,
                },
            },
            {
                label = settings.i18n("mcm.leftPartFilter.sameArmor.label"),
                callback = function()
                    return require("InspectIt.component.mesh").GetArmorSameMeshAsRightPart()
                end
            },
            {
                label = settings.i18n("mcm.leftPartFilter.sameClothing.label"),
                callback = function()
                    return require("InspectIt.component.mesh").GetClothingSameMeshAsRightPart()
                end
            },
            {
                label = settings.i18n("mcm.leftPartFilter.plugin.label"),
                type = "Plugin",
            },
        }
    })
end
event.register(tes3.event.modConfigReady, OnModConfigReady)
