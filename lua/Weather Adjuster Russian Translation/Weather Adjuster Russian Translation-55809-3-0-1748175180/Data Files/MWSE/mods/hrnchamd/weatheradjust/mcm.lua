--[[
    Mod: Weather Adjuster
    Author: Hrnchamd
    Version: 3.0
]]--

local this = {}
local verString = "3.0"

function this.onCreate(parent)
    local pane = parent:createThinBorder{}
    pane.widthProportional = 1.0
    pane.heightProportional = 1.0
    pane.paddingAllSides = 12
    pane.flowDirection = tes3.flowDirection.topToBottom
    this.pane = pane

    local subhead1 = pane:createLabel{ text = "quis nostrum exercitationem ullam corporis suscipit laboriosam" }
    subhead1.font = 2

    local header = pane:createLabel{ text = "Преобразователь погоды - от Sun's Reach Laboratorum\nверсия " .. verString }
    header.color = tes3ui.getPalette(tes3.palette.header_color)
    header.borderAllSides = 12

    local subhead2 = pane:createLabel{ text = "sed quia consequuntur magni dolores eos" }
    subhead2.font = 2
    subhead2.borderBottom = 24

    local summary = pane:createLabel{ text = "Погодные цвета, небо и освещение для каждого региона. Плавные переходы между регионами. Ночью облака становятся по-настоящему темными.\n\nИспользуйте комбинацию клавиш для вызова окна настройки погоды во время игры, чтобы редактировать погоду, создавать пресеты и привязывать пресеты к регионам. Преобразователь погоды будет переключаться между пресетами при смене регионов.\n\nВы можете делиться своей пользовательской погодой с другими пользователями. Все настройки сохраняются в <Data Files/MWSE/config/Weather Adjuster.json>." }
    summary.widthProportional = 1.0
    summary.wrapText = true
    summary.borderBottom = 40

    local configBlock = pane:createBlock{}
    configBlock.maxWidth = 600
    configBlock.widthProportional = 1.0
    configBlock.autoHeight = true
    configBlock.flowDirection = tes3.flowDirection.topToBottom

    mwse.mcm.createKeyBinder(configBlock,
        {
            label = "Вызов окна настройки погоды",
            leftSide = false,
            allowCombinations = true,
            variable = {
                class = "TableVariable",
                table = this.config,
                id = "keybind",
                defaultSetting = mwse.mcm.createTableVariable{
                    keyCode = tes3.scanCode.F4, isShiftDown = true, isAltDown = false, isControlDown = false
                }
            }
        }
    )

    mwse.mcm.createOnOffButton(configBlock,
        {
            class = "OnOffButton",
            label = "Показывать сообщения о смене региона",
            leftSide = false,
            variable = mwse.mcm.createTableVariable{
                class = "TableVariable",
                table = this.config,
                id = "messageOnRegionChange",
                defaultSetting = false
            }
        }
    )

    mwse.mcm.createOnOffButton(configBlock,
        {
            class = "OnOffButton",
            label = "Отключить изменение текстур неба (для совместимости с другими модами)",
            leftSide = false,
            variable = mwse.mcm.createTableVariable{
                class = "TableVariable",
                table = this.config,
                id = "disableSkyTextureChanges",
                defaultSetting = false
            }
        }
    )

    parent:getTopLevelMenu():updateLayout()
end

function this.onClose(container)
    mwse.saveConfig(this.configId, this.config)
end

function this.registerModConfig()
    mwse.registerModConfig("Преобразователь погоды", this)
end

return this