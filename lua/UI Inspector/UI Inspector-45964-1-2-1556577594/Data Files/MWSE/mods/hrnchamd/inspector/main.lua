--[[
	Mod: UI Inspector
	Author: Hrnchamd
    Version: 0.1
]]--

local INT_MIN = -0x80000000
local INT_MAX = 0x7FFFFFFF
local prop_inherit = -0x7F33
local this = {}

local function formatValue(value)
    if (type(value) == "number") then
        if (value == INT_MIN) then
            return "<INT_MIN>"
        elseif (value == INT_MAX) then
            return "<INT_MAX>"
        elseif (value == prop_inherit) then
            return "<inherit>"
        elseif (value ~= math.floor(value)) then
            -- Show up to 4 decimals, strip trailing zeros
            return string.format("%.4f", value):gsub("0+$", "")
        end
    elseif (type(value) == "string") then
        local firstLine = value:gsub("\n.*", "...")
        return firstLine
    elseif (value == nil) then
        return "<inactive>"
    end
    return tostring(value)
end

local function updateDetailValues(element)
    local menu = tes3ui.findMenu(this.id_menu)
    local values = menu:findChild(this.id_detail):findChild(this.id_detailValues)
    local valueList = values.children

    local function updateDetail(i, block, attribute)
        local v = block:findChild(this.id_valueText)
        v.text = formatValue(element[attribute])
        return next(valueList, i)
    end
    
    local i, child = next(valueList)
    i, child = updateDetail(i, child, "name")
    i, child = updateDetail(i, child, "id")
    i, child = updateDetail(i, child, "visible")
    i, child = updateDetail(i, child, "disabled")
    i, child = updateDetail(i, child, "contentType")
    i, child = updateDetail(i, child, "contentPath")
    i, child = updateDetail(i, child, "text")
    i, child = next(valueList, i) -- "color"
    i, child = next(valueList, i) -- "Layout"
    i, child = updateDetail(i, child, "positionX")
    i, child = updateDetail(i, child, "positionY")
    i, child = updateDetail(i, child, "absolutePosAlignX")
    i, child = updateDetail(i, child, "absolutePosAlignY")
    i, child = updateDetail(i, child, "width")
    i, child = updateDetail(i, child, "height")
    i, child = updateDetail(i, child, "minWidth")
    i, child = updateDetail(i, child, "minHeight")
    i, child = updateDetail(i, child, "maxWidth")
    i, child = updateDetail(i, child, "maxHeight")
    i, child = updateDetail(i, child, "autoWidth")
    i, child = updateDetail(i, child, "autoHeight")
    i, child = updateDetail(i, child, "widthProportional")
    i, child = updateDetail(i, child, "heightProportional")
    i, child = updateDetail(i, child, "borderAllSides")
    i, child = updateDetail(i, child, "borderLeft")
    i, child = updateDetail(i, child, "borderRight")
    i, child = updateDetail(i, child, "borderTop")
    i, child = updateDetail(i, child, "borderBottom")
    i, child = updateDetail(i, child, "paddingAllSides")
    i, child = updateDetail(i, child, "paddingLeft")
    i, child = updateDetail(i, child, "paddingRight")
    i, child = updateDetail(i, child, "paddingTop")
    i, child = updateDetail(i, child, "paddingBottom")
    i, child = updateDetail(i, child, "childAlignX")
    i, child = updateDetail(i, child, "childAlignY")
    i, child = updateDetail(i, child, "childOffsetX")
    i, child = updateDetail(i, child, "childOffsetY")
    i, child = updateDetail(i, child, "flowDirection")
    i, child = next(valueList, i) -- "Content Layout"
    i, child = updateDetail(i, child, "wrapText")
    i, child = updateDetail(i, child, "justifyText")
    i, child = updateDetail(i, child, "font")
    i, child = updateDetail(i, child, "scaleMode")
    i, child = updateDetail(i, child, "imageScaleX")
    i, child = updateDetail(i, child, "imageScaleY")
    i, child = next(valueList, i) -- "Events"
    i, child = updateDetail(i, child, "consumeMouseEvents")
    i, child = updateDetail(i, child, "repeatKeys")
    i, child = next(valueList, i) -- "Widget"

    menu:updateLayout()
end

local function changeAttrTo(element, attribute, value)
    element[attribute] = value
    element:getTopLevelMenu():updateLayout()
    updateDetailValues(element)
end

local function changeAttrNumeric(element, attribute, delta)
    local x = element[attribute]
    if (x ~= nil) then
        x = x + delta
    else
        x = 0
    end
    element[attribute] = x
    element:getTopLevelMenu():updateLayout()
    updateDetailValues(element)
end

local function updateDetail(e)
    local menu = tes3ui.findMenu(this.id_menu)
    local pane = menu:findChild(this.id_detail):findChild(this.id_pane)
    local uid = e.source.parent.parent:getPropertyInt("Hrn:Inspector.uid")
    local element = this.elementMap[uid]

    if (not element) then
        tes3.messageBox{ message = "UI Inspection: Failed on uid #" .. uid }
        return
    end

    pane:destroyChildren()
    pane.flowDirection = "left_to_right"
    local labels = pane:createBlock{}
    labels.flowDirection = "top_to_bottom"
    labels.borderRight = 20
    labels.width = 180
    labels.autoHeight = true
    local values = pane:createBlock{ id = this.id_detailValues }
    values.flowDirection = "top_to_bottom"
    values.widthProportional = 1.0
    values.autoHeight = true

    local function addDetail(attribute, editClass, defaultValue)
        local value = element[attribute]

        local t = labels:createLabel{ text = attribute }
        t.absolutePosAlignX = 1.0
        local valueBlock = values:createBlock{}
        valueBlock.autoWidth = true
        valueBlock.autoHeight = true
        local v = valueBlock:createLabel{ id = this.id_valueText, text = formatValue(value) }
        v.minWidth = 160
        
        local b = nil
        if (editClass == "int") then
            b = valueBlock:createLabel{ text = "<- " }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrNumeric(element, attribute, -10) end)
            b = valueBlock:createLabel{ text = " - " }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrNumeric(element, attribute, -1) end)
            b = valueBlock:createLabel{ text = " + " }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrNumeric(element, attribute, 1) end)
            b = valueBlock:createLabel{ text = " +>" }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrNumeric(element, attribute, 10) end)
            b = valueBlock:createLabel{ text = "Reset" }
            b.borderLeft = 15
            b:register("mouseClick", function () changeAttrTo(element, attribute, nil) end)
        elseif (editClass == "float") then
            b = valueBlock:createLabel{ text = "<- " }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrNumeric(element, attribute, -0.1) end)
            b = valueBlock:createLabel{ text = " - " }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrNumeric(element, attribute, -0.01) end)
            b = valueBlock:createLabel{ text = " + " }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrNumeric(element, attribute, 0.01) end)
            b = valueBlock:createLabel{ text = " +>" }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrNumeric(element, attribute, 0.1) end)
            b = valueBlock:createLabel{ text = "Reset" }
            b.borderLeft = 15
            b:register("mouseClick", function () changeAttrTo(element, attribute, nil) end)
        elseif (editClass == "bool") then
            b = valueBlock:createLabel{ text = "false" }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrTo(element, attribute, false) end)
            b = valueBlock:createLabel{ text = "true" }
            b.borderRight = 5
            b:register("mouseClick", function () changeAttrTo(element, attribute, true) end)
            b = valueBlock:createLabel{ text = "Reset" }
            b.borderLeft = 15
            b:register("mouseClick", function () changeAttrTo(element, attribute, nil) end)
        elseif (type(editClass) == "table") then
            for _, k in ipairs(editClass) do
                b = valueBlock:createLabel{ text = tostring(k) }
                b.borderRight = 5
                b:register("mouseClick", function () changeAttrTo(element, attribute, k) end)
            end
        end
    end

    local function addColourDetail(attribute)
        local c = element.color
        local text = string.format("%.3f, %.3f, %.3f, %.3f", c[1], c[2], c[3], element.alpha)

        local t = labels:createLabel{ text = attribute }
        t.absolutePosAlignX = 1.0
        local valueBlock = values:createBlock{}
        valueBlock.autoWidth = true
        valueBlock.autoHeight = true
        valueBlock.childAlignY = 1
        local swatch = valueBlock:createRect{ id = this.id_valueColour, color = c }
        swatch.width = 24
        swatch.height = 14
        local v = valueBlock:createLabel{ id = this.id_valueText, text = text }
        v.minWidth = 160
        v.borderLeft = 15
    end
    
    local function addHeading(title)
        local t = labels:createLabel{ text = title }
        t.absolutePosAlignX = 1.0
        t.borderTop = 10
        t.borderBottom = 10
        local v = values:createLabel{ text = " " }
        v.borderTop = 10
        v.borderBottom = 10
    end
    
    addDetail("name", nil)
    addDetail("id", nil)
    addDetail("visible", "bool")
    addDetail("disabled", "bool")
    addDetail("contentType", nil)
    addDetail("contentPath", nil)
    addDetail("text", nil)
    addColourDetail("color")
    addHeading("Layout")
    addDetail("positionX", "int")
    addDetail("positionY", "int")
    addDetail("absolutePosAlignX", "float")
    addDetail("absolutePosAlignY", "float")
    addDetail("width", "int")
    addDetail("height", "int")
    addDetail("minWidth", "int")
    addDetail("minHeight", "int")
    addDetail("maxWidth", "int")
    addDetail("maxHeight", "int")
    addDetail("autoWidth", "bool")
    addDetail("autoHeight", "bool")
    addDetail("widthProportional", "float")
    addDetail("heightProportional", "float")
    addDetail("borderAllSides", "int")
    addDetail("borderLeft", "int")
    addDetail("borderRight", "int")
    addDetail("borderTop", "int")
    addDetail("borderBottom", "int")
    addDetail("paddingAllSides", "int")
    addDetail("paddingLeft", "int")
    addDetail("paddingRight", "int")
    addDetail("paddingTop", "int")
    addDetail("paddingBottom", "int")
    addDetail("childAlignX", "float")
    addDetail("childAlignY", "float")
    addDetail("childOffsetX", "int")
    addDetail("childOffsetY", "int")
    addDetail("flowDirection", {"left_to_right", "top_to_bottom"})
    addHeading("Content Layout")
    addDetail("wrapText", "bool")
    addDetail("justifyText", {"left", "center", "right"})
    addDetail("font", {0, 1, 2})
    addDetail("scaleMode", "bool")
    addDetail("imageScaleX", "float")
    addDetail("imageScaleY", "float")
    addHeading("Events")
    addDetail("consumeMouseEvents", "bool")
    addDetail("repeatKeys", "bool")
    addHeading("Widget")

    menu:updateLayout()
end

local function toggleCollapser(e)
    local block = e.widget
    local toggle = block:findChild(this.id_subtoggle)
    local sublist = block:findChild(this.id_sublist)
    
    if (sublist.visible) then
        toggle.text = "+"
        sublist.visible = false
    else
        toggle.text = "-"
        sublist.visible = true
    end

    local menu = tes3ui.findMenu(this.id_menu)
    local scrollPaneWidget = menu:findChild(this.id_list).widget
    menu:updateLayout()
    scrollPaneWidget:contentsChanged()
end

local function showContents(e)
    local uid = e.widget:getPropertyInt("Hrn:Inspector.uid")
    local element = this.elementMap[uid]
    local id_content = nil

    local firstid = element.children[1].id
    if (firstid == this.id_dragFirstChild) then
        id_content = this.id_dragMain
    elseif (firstid == this.id_fixedFirstChild) then
        id_content = this.id_fixedMain
    elseif (firstid == this.id_scrollFirstChild) then
        id_content = this.id_pane
    else
        return
    end
    
    local function showItem(block)
        local toggle = block:findChild(this.id_subtoggle)
        local sublist = block:findChild(this.id_sublist)
        
        toggle.text = "-"
        sublist.visible = true
    end

    local function recursiveShow(x)
        local uid = x:getPropertyInt("Hrn:Inspector.uid")
        local element = this.elementMap[uid]

        if (not element) then
            return false
        elseif (element.id == id_content) then
            showItem(x)
            return true
        end
        
        local sublist = x:findChild(this.id_sublist)
        local status = false
        for _, child in ipairs(sublist.children) do
            local sel = child:findChild(this.id_elementSel)
            sel.widget.state = 2
            sel.widget.idleDisabled = { 0.44, 0.44, 0.44 }
            sel:triggerEvent("mouseLeave")
            if (recursiveShow(child)) then
                showItem(x)
                status = true
            end
        end
        return status
    end
    
    recursiveShow(e.widget)
    
    local menu = tes3ui.findMenu(this.id_menu)
    local scrollPaneWidget = menu:findChild(this.id_list).widget
    menu:updateLayout()
    scrollPaneWidget:contentsChanged()
end

local function clearList()
    local menu = tes3ui.findMenu(this.id_menu)
    local pane = menu:findChild(this.id_list):findChild(this.id_pane)
    this.elementMap = {}
    pane:destroyChildren()
end

local function refreshList()
    local menu = tes3ui.findMenu(this.id_menu)
    local pane = menu:findChild(this.id_list):findChild(this.id_pane)
    local uid = 1
    
    local function recursiveRefresh(element, container)
        for i, child in ipairs(element.children) do
            local block = container:createBlock{}
            block:setPropertyBool("is_part", true)
            block.widthProportional = 1.0
            block.autoHeight = true
            block.flowDirection = "top_to_bottom"

            local topline = block:createBlock{}
            local collapser
            topline.widthProportional = 1.0
            topline.autoHeight = true
            if (#child.children > 0) then
                collapser = topline:createLabel{ id = this.id_subtoggle, text = "+" }
                collapser.minWidth = 15
            else
                topline.paddingLeft = 15
            end
            local elementSelect = topline:createTextSelect{ id = this.id_elementSel, text = child.name or "(nil)" }
            elementSelect.autoHeight = true
            
            if (#child.children >= 1) then
                local firstid = child.children[1].id
                if (firstid == this.id_dragFirstChild or firstid == this.id_fixedFirstChild or firstid == this.id_scrollFirstChild) then
                    local contents = topline:createLabel{ text = "Contents >" }
                    contents.borderLeft = 30
                    contents:register("mouseClick", showContents)
                end
            end

            local sublist = block:createBlock{ id = this.id_sublist }
            sublist.visible = false
            sublist.flowDirection = "top_to_bottom"
            sublist.borderLeft = 15
            sublist.widthProportional = 1.0
            sublist.autoHeight = true

            block:setPropertyInt("Hrn:Inspector.uid", uid)
            this.elementMap[uid] = child
            uid = uid + 1
            if (child.id ~= this.id_menu) then
                recursiveRefresh(child, sublist)
            else
                block.visible = false
            end

            elementSelect:register("mouseClick", updateDetail)
            if (collapser) then
                collapser:register("mouseClick", toggleCollapser)
            end
        end
    end

    this.elementMap = {}
    pane:destroyChildren()
    recursiveRefresh(this.uiRoot, pane)
    
    local scrollPaneWidget = menu:findChild(this.id_list).widget
    scrollPaneWidget:contentsChanged()
    scrollPaneWidget.positionY = 0
end

local function createInspector(id)
    local menu = tes3ui.createMenu{ id = id, dragFrame = true }
    this.uiRoot = menu.parent
    menu.text = "UI Inspector"
    menu.minWidth = 100
    menu.minHeight = 100
    menu.width = 600
    menu.height = 800
    menu.positionX = 150
    menu.positionY = 360
    
    if (tes3ui.stealHelpMenu) then
        -- Copy help tooltip if present
        local help = tes3ui.findHelpLayerMenu(this.id_help)
        if (help and help.visible) then
            -- Turn off mouse following on update
            help:register("preUpdate", function(e) end)
            help:register("update", function(e) end)
            -- Transfer from help layer to main layer
            tes3ui.stealHelpMenu()
        end
    end
    
    local warn = menu:createLabel{ text = "Warning: This menu tree is a static snapshot. Do not try to check the details of closed menus, it will be crashy."}
    warn.wrapText = true
    warn.widthProportional = 1.0
    warn.heightProportional = -1.0
    warn.minHeight = 36
    local list = menu:createVerticalScrollPane{ id = this.id_list }
    list.borderAllSides = 8
    list.widthProportional = 1.0
    list.heightProportional = 0.8
    local detail = menu:createVerticalScrollPane{ id = this.id_detail }
    detail.borderAllSides = 8
    detail.widthProportional = 1.0
    detail.heightProportional = 1.2
    local refresh = menu:createButton{ text = "Refresh" }
    refresh.borderRight = 60
    refresh.absolutePosAlignX = 1.0
    refresh.absolutePosAlignY = 0.08
    refresh:register("mouseClick", refreshList)
end

local function cleanupInspector()
    -- Remove copy of help tooltip
    local help = tes3ui.findMenu(this.id_help)
    if (help) then
        help:destroy()
    end
end

local function toggleInspector()
    local menu = tes3ui.findMenu(this.id_console)
    this.id_menu = this.id_console
    
    if (menu) then
        if (not menu:findChild(this.id_detail)) then
            this.id_menu = this.id_inspector
            menu = tes3ui.findMenu(this.id_inspector)
        end
    end
    
    if (not menu) then
        createInspector(this.id_menu)
        refreshList()
    else
        cleanupInspector()
        menu:destroy()
    end
end

local function init()
    this.id_inspector = tes3ui.registerID("Hrn:MenuInspector")
    this.id_menu = this.id_inspector
    this.id_list = tes3ui.registerID("Hrn:MenuInspector.List")
    this.id_detail = tes3ui.registerID("Hrn:MenuInspector.Detail")
    this.id_detailValues = tes3ui.registerID("Hrn:MenuInspector.Detail.Values")
    this.id_valueText = tes3ui.registerID("Hrn:MenuInspector.Detail.Text")
    this.id_elementSel = tes3ui.registerID("Hrn:MenuInspector.ElementSelect")
    this.id_subtoggle = tes3ui.registerID("Hrn:MenuInspector.SubToggle")
    this.id_sublist = tes3ui.registerID("Hrn:MenuInspector.SubList")

    this.id_console = tes3ui.registerID("MenuConsole")
    this.id_help = tes3ui.registerID("HelpMenu")
    this.id_partScrollPane = tes3ui.registerID("PartScrollPane")
    this.id_partDragMenu = tes3ui.registerID("PartDragMenu")
    this.id_pane = tes3ui.registerID("PartScrollPane_pane")
    this.id_dragMain = tes3ui.registerID("PartDragMenu_main")
    this.id_fixedMain = tes3ui.registerID("PartNonDragMenu_main")
    this.id_dragFirstChild = tes3ui.registerID("PartDragMenu_thick_border")
    this.id_fixedFirstChild = tes3ui.registerID("focusable")
    this.id_scrollFirstChild = tes3ui.registerID("PartScrollPane_outer_frame")

    -- On F3
    event.register("keyDown", toggleInspector, { filter = 61 })
end

event.register("initialized", init)



local modConfig = {}

function modConfig.onCreate(container)
	local pane = container:createThinBorder{}
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"

    local subhead1 = pane:createLabel{ text = "quis nostrum exercitationem ullam corporis suscipit laboriosam" }
    subhead1.font = 2

    local header = pane:createLabel{ text = "UI Inspector - from Sun's Reach Laboratorum\nversion 1.0" }
    header.color = tes3ui.getPalette("header_color")
    header.borderAllSides = 12

    local subhead2 = pane:createLabel{ text = "sed quia consequuntur magni dolores eos" }
    subhead2.font = 2

    local txt = pane:createLabel{}
    txt.wrapText = true
    txt.height = 1
    txt.widthProportional = 1.0
    txt.heightProportional = -1.0
    txt.borderTop = 35
    txt.text = "Press F3 to Inspect UIs. Press F3 again to hide it."
    
    pane:updateLayout()
end

function modConfig.onClose(container)
end

local function registerModConfig()
	mwse.registerModConfig("UI Inspector", modConfig)
end

event.register("modConfigReady", registerModConfig)
