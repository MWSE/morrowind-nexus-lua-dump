local logger = mwse.Logger.new()

--- A builder class for creating and configuring GUI elements using a fluent interface
---@class guiBuilder
---@field private element tes3uiElement
---@field private callbacks { [string]: function }
local this = {}
this.__index = this

--- Creates a new menu GUI element
---@public
---@param parameters createMenuParameters The parameters for creating the menu
---@return guiBuilder builder The current builder instance
function this.createMenu(parameters)
    local element = tes3ui.createMenu({
        id = parameters.id,
        dragFrame = parameters.dragFrame,
        fixedFrame = parameters.fixedFrame,
        modal = parameters.modal,
    })
    return this.create(element)
end

--- Creates a new label GUI element
---@public
---@param parameters createParameters The parameters for creating the label
---@return guiBuilder builder The current builder instance
function this.createLabel(parameters)
    local element = parameters.parent:createLabel({
        id = parameters.id,
    })
    return this.create(element)
end

--- Creates a new thin border GUI element
---@public
---@param parameters createParameters The parameters for creating the thin border
---@return guiBuilder builder The current builder instance
function this.createThinBorder(parameters)
    local element = parameters.parent:createThinBorder({
        id = parameters.id,
    })
    return this.create(element)
end

--- Creates a new block GUI element
---@public
---@param parameters createParameters The parameters for creating the block
---@return guiBuilder builder The current builder instance
function this.createBlock(parameters)
    local element = parameters.parent:createBlock({
        id = parameters.id,
    })
    return this.create(element)
end

--- Creates a new divider GUI element
---@public
---@param parameters createParameters The parameters for creating the divider
---@return guiBuilder builder The current builder instance
function this.createDivider(parameters)
    local element = parameters.parent:createDivider({
        id = parameters.id,
    })
    return this.create(element)
end

--- Creates a new button GUI element
---@public
---@param parameters createParameters The parameters for creating the button
---@return guiBuilder builder The current builder instance
function this.createButton(parameters)
    local element = parameters.parent:createButton({
        id = parameters.id,
    })
    return this.create(element)
end

--- Creates a new image button GUI element
--- @public
--- @param parameters createImageButtonParameters The parameters for creating the image button
--- @return guiBuilder builder The current builder instance
function this.createImageButton(parameters)
    local element = parameters.parent:createImageButton({
        id = parameters.id,
        idle = parameters.idle,
        over = parameters.over,
        pressed = parameters.pressed,
    })
    element.scaleMode = parameters.scaleMode or false
    return this.create(element)
end

--- Creates a new vertical scroll pane GUI element
---@public
---@param parameters createParameters The parameters for creating the vertical scroll pane
---@return guiBuilder builder The current builder instance
function this.createVerticalScrollPane(parameters)
    local element = parameters.parent:createVerticalScrollPane({
        id = parameters.id,
    })
    return this.create(element)
end

--- Creates a new text select GUI element
---@public
---@param parameters createParameters The parameters for creating the text select
---@return guiBuilder builder The current builder instance
function this.createTextSelect(parameters)
    local element = parameters.parent:createTextSelect({
        id = parameters.id,
    })
    return this.create(element)
end

--- Sets the text of the GUI element
---@public
---@param text string The value to set the text to
---@return guiBuilder builder The current builder instance
function this:withText(text)
    self.element.text = text
    return self
end

--- Sets the color of the GUI element
---@public
---@param color number[] The color to set (as an array of RGBA values)
---@return guiBuilder builder The current builder instance
function this:withColor(color)
    self.element.color = color
    return self
end

--- Sets the widget colors of the GUI element
---@public
---@param params widgetColorParameters The widget color parameters to set
---@return guiBuilder builder The current builder instance
function this:withWidgetColors(params)
    local widget = self.element.widget

    if not widget then
        logger:error("Element does not have a widget to set colors on")
        return self
    end

    if widget.idle and params.idle then
        widget.idle = params.idle
        widget.textElement.color = params.idle
    end

    if widget.idleActive and params.idleActive then
        widget.idleActive = params.idleActive
    end

    if widget.idleDisabled and params.idleDisabled then
        widget.idleDisabled = params.idleDisabled
    end

    if widget.over and params.over then
        widget.over = params.over
    end

    if widget.overActive and params.overActive then
        widget.overActive = params.overActive
    end

    if widget.overDisabled and params.overDisabled then
        widget.overDisabled = params.overDisabled
    end

    if widget.pressed and params.pressed then
        widget.pressed = params.pressed
    end

    if widget.pressedActive and params.pressedActive then
        widget.pressedActive = params.pressedActive
    end

    if widget.pressedDisabled and params.pressedDisabled then
        widget.pressedDisabled = params.pressedDisabled
    end

    return self
end

--- Sets the palette color of the GUI element
---@public
---@param palette tes3.palette The palette color to set
---@return guiBuilder builder The current builder instance
function this:withPalette(palette)
    return self:withColor(tes3ui.getPalette(palette))
end

--- Sets the GUI element to auto size (both width and height)
---@public
---@return guiBuilder builder The current builder instance
function this:withAutoSize()
    self.element.autoHeight = true
    self.element.autoWidth = true
    return self
end

--- Sets the GUI element to auto height
---@public
---@return guiBuilder builder The current builder instance
function this:withAutoHeight()
    self.element.autoHeight = true
    return self
end

--- Sets the GUI element to auto width
---@public
---@return guiBuilder builder The current builder instance
function this:withAutoWidth()
    self.element.autoWidth = true
    return self
end

--- Sets the minimum size of the GUI element
---@public
---@param parameters sizeParameters The size parameters to set
---@return guiBuilder builder The current builder instance
function this:withMinSize(parameters)
    if parameters.width then
        self.element.minWidth = parameters.width
    end
    if parameters.height then
        self.element.minHeight = parameters.height
    end
    return self
end

--- Sets the maximum size of the GUI element
---@public
---@param parameters sizeParameters The size parameters to set
---@return guiBuilder builder The current builder instance
function this:withMaxSize(parameters)
    if parameters.width then
        self.element.maxWidth = parameters.width
    end
    if parameters.height then
        self.element.maxHeight = parameters.height
    end
    return self
end

--- Sets the maximum size of the GUI element
---@public
---@param parameters vector2Parameters The size parameters to set
---@return guiBuilder builder The current builder instance
function this:withPositionAlign(parameters)
    if parameters.x then
        self.element.absolutePosAlignX = parameters.x
    end
    if parameters.y then
        self.element.absolutePosAlignY = parameters.y
    end
    return self
end

--- Sets the flow direction of the GUI element
---@public
---@param flowDirection tes3.flowDirection The flow direction to set (e.g., "top_to_bottom", "left_to_right")
---@return guiBuilder builder The current builder instance
function this:withFlowDirection(flowDirection)
    self.element.flowDirection = flowDirection
    return self
end

--- Sets the border of the GUI element
---@public
---@param parameters borderPaddingParameters The border parameters to set
---@return guiBuilder builder The current builder instance
function this:withBorder(parameters)
    if parameters.all then
        self.element.borderAllSides = parameters.all
    end
    if parameters.left then
        self.element.borderLeft = parameters.left
    end
    if parameters.right then
        self.element.borderRight = parameters.right
    end
    if parameters.top then
        self.element.borderTop = parameters.top
    end
    if parameters.bottom then
        self.element.borderBottom = parameters.bottom
    end
    return self
end

--- Sets the padding of the GUI element
---@public
---@param parameters borderPaddingParameters The padding parameters to set
---@return guiBuilder builder The current builder instance
function this:withPadding(parameters)
    if parameters.all then
        self.element.paddingAllSides = parameters.all
    end
    if parameters.left then
        self.element.paddingLeft = parameters.left
    end
    if parameters.right then
        self.element.paddingRight = parameters.right
    end
    if parameters.top then
        self.element.paddingTop = parameters.top
    end
    if parameters.bottom then
        self.element.paddingBottom = parameters.bottom
    end
    return self
end

--- Sets the child alignment of the GUI element
---@public
---@param parameters vector2Parameters The alignment parameters to set
---@return guiBuilder builder The current builder instance
function this:withChildAlignment(parameters)
    if parameters.x then
        self.element.childAlignX = parameters.x
    end
    if parameters.y then
        self.element.childAlignY = parameters.y
    end
    return self
end

--- Sets the proportional size of the GUI element
---@public
---@param parameters sizeParameters The size parameters to set
---@return guiBuilder builder The current builder instance
function this:withProportional(parameters)
    if parameters.width then
        self.element.widthProportional = parameters.width
    end
    if parameters.height then
        self.element.heightProportional = parameters.height
    end
    return self
end

--- Sets the size of the GUI element
---@public
---@param parameters sizeParameters The size parameters to set
---@return guiBuilder builder The current builder instance
function this:withSize(parameters)
    if parameters.width then
        self.element.width = parameters.width
    end
    if parameters.height then
        self.element.height = parameters.height
    end
    return self
end

--- Registers a callback for a specific event on the GUI element
---@public
---@param evt string The event id to register the callback for
---@param callback fun(element: tes3uiElement, e: table|nil) The callback function to execute when the event occurs
---@return guiBuilder builder The current builder instance
function this:withCallback(evt, callback)
    self.callbacks = self.callbacks or {}
    if self.callbacks[evt] then
        logger:warn("Callback for event '%s' already registered", evt)
        return self
    end

    self.callbacks[evt] = function(e)
        callback(self.element, e or nil)
        self.element:updateLayout()
    end

    return self
end

--- Registers a UI callback for a specific event on the GUI element
---@public
---@param evt string The UI event id to register the callback for
---@param callback fun(e: tes3uiEventData) The callback function to execute when the event occurs
function this:withUICallback(evt, callback)
    self.element:register(evt, callback)

    return self
end

--- Attaches arbitrary data to the GUI element
--- @public
--- @param key string The key to associate with the data
--- @param data any The data to attach
--- @return guiBuilder builder The current builder instance
function this:withData(key, data)
    self.element:setLuaData(key, data)
    return self
end

--- Enables text wrapping for the GUI element
--- @public
--- @return guiBuilder builder The current builder instance
function this:withWrapText()
    self.element.wrapText = true
    return self
end

--- Updates the layout of the GUI element
---@public
---@return guiBuilder builder The current builder instance
function this:updateLayout()
    self.element:updateLayout()
    return self
end

--- Builds and returns the configured GUI element
---@public
---@return tes3uiElement element The built GUI element
function this:build()
    if self.callbacks then
        for evt, callback in pairs(self.callbacks) do
            self:registerCallback(evt, callback)
        end
    end
    return self.element
end

---@private
---@param evt string
---@param callback fun(element: tes3uiElement, e: table|nil)
function this:registerCallback(evt, callback)
    if not event.isRegistered(evt, callback) then
        event.register(evt, callback)
    end

    self.element:registerBefore(tes3.uiEvent.destroy, function()
        if event.isRegistered(evt, callback) then
            event.unregister(evt, callback)
        end
    end)
end

---@private
---@param element tes3uiElement
---@return guiBuilder
function this.create(element)
    local instance = setmetatable({ element = element }, this)
    return instance
end

return this
