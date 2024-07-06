local base = require("InspectIt.controller.base")
local config = require("InspectIt.config")
local settings = require("InspectIt.settings")
local mesh = require("InspectIt.component.mesh")
local helpLayerMenu = tes3ui.registerID("InspectIt:MenuInspectionDescription")

---@class Guide : IController
---@field object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon?
---@field changedAnotherLookCallback fun(e:ChangedAnotherLookEventData)?
local this = {}
setmetatable(this, { __index = base })

---@type Guide
local defaults = {
}

---@return Guide
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Guide

    return instance
end

--- @param keyCode integer|nil
--- @return string|nil letter
local function GetLetter(keyCode)
    local letter = table.find(tes3.scanCode, keyCode)
    local returnString = tes3.scanCodeToNumber[keyCode] or letter
    if returnString then
        return string.upper(returnString)
    end
end

--- @param keyCombo mwseKeyCombo
--- @return string result
local function GetComboString(keyCombo)
    local keyCode = keyCombo.keyCode
    local comboText = GetLetter(keyCode)
    if not comboText then
        comboText = string.format("{%s}", mwse.mcm.i18n("unknown key"))
    end
    local hasAlt = (keyCombo.isAltDown and keyCode ~= tes3.scanCode.lAlt
        and keyCode ~= tes3.scanCode.rAlt)
    local hasShift = (keyCombo.isShiftDown and keyCode ~= tes3.scanCode.lShift
        and keyCode ~= tes3.scanCode.rShift)
    local hasCtrl = (keyCombo.isControlDown and keyCode ~= tes3.scanCode.lCtrl
        and keyCode ~= tes3.scanCode.rCtrl)
    local prefixes = {}
    if hasShift then table.insert(prefixes, "Shift") end
    if hasAlt then table.insert(prefixes, "Alt") end
    if hasCtrl then table.insert(prefixes, "Ctrl") end
    table.insert(prefixes, comboText)
    return table.concat(prefixes, " + ")
end

---@param e enterFrameEventData
local function OnEnterFrame(e)
    local help = tes3ui.findHelpLayerMenu(helpLayerMenu)
    if help then
        if settings.OnOtherMenu() then
            help.visible = false
            return
        end
        if config.display.tooltipsComplete then
            help.visible = true
        end
    end
end

---@param self Guide
function this.Destroy(self)
    self.object = nil
    local menu = tes3ui.findMenu(settings.guideMenuID)
    if menu then
        menu:destroy()
    end
    local help = tes3ui.findHelpLayerMenu(helpLayerMenu)
    if help then
        help:destroy()
    end
    if event.isRegistered(tes3.event.enterFrame, OnEnterFrame) then
        event.unregister(tes3.event.enterFrame, OnEnterFrame)
    end
    if self.changedAnotherLookCallback then
        event.unregister(settings.changedAnotherLookEventName, self.changedAnotherLookCallback)
        self.changedAnotherLookCallback = nil
    end
end

---@param parent tes3uiElement
---@param text string button text
---@param label string label text
---@param buttonId string|number|nil label text
---@returns tes3uiElement button
---@returns tes3uiElement block
---@returns tes3uiElement label
local function CreateButton(parent, text, label, buttonId)
    local row = parent:createBlock()
    row.flowDirection = tes3.flowDirection.leftToRight
    row.autoWidth = true
    row.autoHeight = true
    row.childAlignY = 0.5
    local button = row:createButton({ id = buttonId, text = text })
    local text = row:createLabel({ text = label })
    return button, row, text
end

---@param self Guide
---@param params Activate.Params
function this.Activate(self, params)
    self:Destroy()
    self.object = params.object

    local name = params.name or params.object.name
    if not name or name == "" then -- fallback
        name = params.object.id
    end

    local width, height = tes3ui.getViewportSize()
    local aspectRatio = width/height
    local offset = 0.02

    -- This modal menu is a must. If there is not a single modal menu visible on the screen, right-clicking will cause all menus to close and return.
    -- This causes unexpected screen transitions and glitches. Especially in Barter.
    local menu = tes3ui.createMenu({ id = settings.guideMenuID, dragFrame = false, fixedFrame = true, modal = true })
    menu:destroyChildren()
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.absolutePosAlignX = 1.0 - offset
    menu.absolutePosAlignY = offset * aspectRatio
    menu.autoWidth = true
    menu.autoHeight = true
    menu.minWidth = 0 -- or tooltip size?
    menu.minHeight = 0
    --menu.alpha = 0
    local border = menu:createThinBorder()
    border.flowDirection = tes3.flowDirection.topToBottom
    border.autoWidth = true
    border.autoHeight = true
    border.paddingAllSides = 8
    border.childAlignX = 0.5
    local nameLabel = border:createLabel({ text = name })
    nameLabel.borderAllSides = 4
    nameLabel.color = tes3ui.getPalette(tes3.palette.headerColor)

    -- if guided
    do
        local block = border:createBlock()
        if not config.display.instruction then
            block.visible = false
        end
        block.flowDirection = tes3.flowDirection.topToBottom
        block.widthProportional = 1.0
        block.autoWidth = true
        block.autoHeight = true
        block.childAlignX = 0.5
        block.paddingLeft = 2
        block.paddingRight = 2

        block:createDivider().widthProportional = 1.0
        block:createLabel({ text = settings.i18n("guide.rotate.text") })
        block:createLabel({ text = settings.i18n("guide.translate.text") })
        block:createLabel({ text = settings.i18n("guide.zoom.text") })

        -- mirror the left part
        if config.display.leftPart and self.object.isLeftPart then
            local button, leftPartBlock, label = CreateButton(block, settings.i18n("guide.leftPart.text"), "placeholder")
            local function FilterChanged()
                if mesh.CanMirrorBySourceMod(self.object.sourceMod) == false then
                    button.disabled = true
                    button.widget.state = tes3.uiState.disabled
                    label.text = settings.i18n("guide.leftPart.plugin")
                    label.color = tes3ui.getPalette(tes3.palette.disabledColor)
                else
                    button.disabled = false
                    button.widget.state = tes3.uiState.normal
                    label.text = mesh.CanMirrorById(self.object.id) and settings.i18n("guide.leftPart.mirror") or settings.i18n("guide.leftPart.normal")
                    label.color = tes3ui.getPalette(tes3.palette.normalColor)
                end
            end
            FilterChanged()
            button:register(tes3.uiEvent.mouseClick, function(e)
                local after = mesh.ToggleMirror(self.object.id)
                self.logger:info("%s left part filter id: %s, plugin: %s", (after and "Add" or "Remove"), self.object.id:lower(), self.object.sourceMod)
                FilterChanged()
                event.trigger(settings.toggleMirroringEventName)
            end)
            -- another look always no need mirroring
            self.changedAnotherLookCallback = function (e)
                -- Avoid manipulating the same state as FilterChanged(). To make it easier to maintain consistency.
                if e.another then
                    leftPartBlock.visible = false
                else
                    leftPartBlock.visible = true
                end
            end
            event.register(settings.changedAnotherLookEventName, self.changedAnotherLookCallback)
        end
        -- another/activate
        if params.another.type ~= nil then
            local button = CreateButton(block, settings.i18n("guide.another.text"), ": " .. GetComboString(config.input.another))
            button:register(tes3.uiEvent.mouseClick, function(e)
                event.trigger(settings.switchAnotherLookEventName)
            end)
        end
        -- lighting
        do
            local button = CreateButton(block, settings.i18n("guide.lighting.text"), ": " .. GetComboString(config.input.lighting))
            button:register(tes3.uiEvent.mouseClick, function(e)
                event.trigger(settings.switchLightingEventName)
            end)
        end
        -- reset
        do
            local button = CreateButton(block, settings.i18n("guide.reset.text"), ": " .. GetComboString(config.input.reset))
            button:register(tes3.uiEvent.mouseClick, function(e)
                event.trigger(settings.resetPoseEventName)
            end)
        end
        -- return
        do
            local button = CreateButton(block, settings.i18n("guide.return.text"), ": " .. GetComboString(config.input.inspect), settings.returnButtonName)
            button:register(tes3.uiEvent.mouseClick, function(e)
                event.trigger(settings.returnEventName)
            end)
        end
    end

    menu:updateLayout()

    -- on mouse fade? help layer does not trigger over, leave event
    if config.display.tooltipsComplete and params.description then
        self.logger:debug("Create description")
        local help = tes3ui.createHelpLayerMenu({ id = helpLayerMenu })
        help:destroyChildren()
        help.flowDirection = tes3.flowDirection.topToBottom
        help.absolutePosAlignX = offset
        help.absolutePosAlignY = 0.5
        help.autoWidth = true
        help.autoHeight = true
        help.minWidth = 0
        help.minHeight = 0
        help.alpha = 0.4
        local block = help:createBlock()
        block.flowDirection = tes3.flowDirection.topToBottom
        block.widthProportional = 1.0
        block.minWidth = 0
        block.maxWidth = 320
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = 8
        --block.childAlignX = 0.5
        local label = block:createLabel({ text = params.description })
        -- label.color = tes3ui.getPalette(tes3.palette.headerColor)
        label.alpha = 0.95 -- .borderAllSides = 2
        help:updateLayout()

        event.register(tes3.event.enterFrame, OnEnterFrame)
    end
end

---@param self Guide
---@param params Deactivate.Params
function this.Deactivate(self, params)
    self:Destroy()
end

---@param self Guide
function this.Reset(self)
    self:Destroy()
end

return this
