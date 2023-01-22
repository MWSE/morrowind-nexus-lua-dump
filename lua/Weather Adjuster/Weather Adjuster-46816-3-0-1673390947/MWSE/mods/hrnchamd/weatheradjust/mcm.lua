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

    local header = pane:createLabel{ text = "Weather Adjuster - from Sun's Reach Laboratorum\nversion " .. verString }
    header.color = tes3ui.getPalette(tes3.palette.header_color)
    header.borderAllSides = 12

    local subhead2 = pane:createLabel{ text = "sed quia consequuntur magni dolores eos" }
    subhead2.font = 2
    subhead2.borderBottom = 24

    local summary = pane:createLabel{ text = "Regional weather colours, skies and lighting. Seamless transitions between regions. Clouds can become truly dark at night.\n\nUse the toggle weather editor keybind during gameplay to edit weather, create presets, and assign presets to regions. Weather Adjuster will transition between presets as you change regions.\n\nYou can share your custom weather with others. All settings are saved in <Data Files/MWSE/config/Weather Adjuster.json>." }
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
            label = "Toggle weather editor window",
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
            label = "Show messages on region change",
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
            label = "Disable sky texture changes (for mod compatibility)",
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
    mwse.registerModConfig("Weather Adjuster", this)
end

return this