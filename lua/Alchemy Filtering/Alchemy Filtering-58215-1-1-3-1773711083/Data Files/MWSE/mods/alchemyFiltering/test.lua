local log = mwse.Logger.new()
log.level = "DEBUG"
local common = require("alchemyFiltering.common")

IconText = {}
IconText.__index = IconText
-- common.IconText = IconText

--- Create a new block holing Icon and Text elements
---
--- The argument is a table holding various settings
--- * parent -  (required) the block in which the IconText will created
--- * textId - (optional) the registerd ID of the text element
--- * isLabel - (optional) if true, the text element is a Label, otherwise a TextSelect
--- * path - (optional) the path to the Icon
--- * text - (optional) the text of the text element
function IconText:create(args)
    local element = {}
    setmetatable(element, self)
    if args.isLabel then
        element.block = args.parent:createBlock()
        element.block.autoHeight = true
        element.block.autoWidth = true
        element.block.childAlignX = 0.5
        element.block.childAlignY = 0.5
        element.block.flowDirection = tes3.flowDirection.leftToRight
    else
        element.block = args.parent:createButton{id = args.textId}
    end
    if not args.isButton then
        element.block.contentPath = nil
        element.block.paddingTop = nil
        element.block.paddingBottom = nil
        element.block.paddingLeft = nil
        element.block.paddingRight = nil
        element.block.paddingAllSides = 0
        element.block.borderAllSides = 0
    end
    -- element.block.contentPath = nil
    -- element.block.childAlignY = 0.5
    element.icon = element.block:createImage()
    if args.isLabel then
        element.text = element.block:createLabel{id = args.textId}
    else
        element.text = element.block
        element.icon:reorder{before = element.block.children[1]}
    end

    if args.isButton then
        element.block.children[2].borderTop = 2
        element.icon.borderTop = 4
        element.icon.borderBottom = 2
        element.icon.borderLeft = 4
    end
    -- element.icon.absolutePosAlignY = 0.5
    -- element.text.absolutePosAlignY = 0.5

    element:setPath(args.path)
    element:setText(args.text)
    return element
end

--- Sets the path to the Icon
---
--- If path is nil, then the Icon is hidden. The border will be updated
--- appropriately to maintain text alignment
function IconText:setPath(path)
    if path then
        self.icon.contentPath = "Icons\\" .. path
        self.icon.visible = true
        self.icon.borderRight = 5
        self.block.paddingLeft = 0
    else
        self.icon.visible = false
        self.block.paddingLeft = 5 + 16
    end
end

--- Sets the text to be displayed
---
--- Also sets the text of the block, which is not visible, but allows
--- for the block itself to be sorted based on the text value.
function IconText:setText(text)
    self.block.text = text
    self.text.text = text
end

local function test()
    log:debug("hello test")

    local menu = tes3ui.createMenu{id = "AF:test_menu", fixedFrame = true}    local cancel = menu:createButton{text = "Retry"}
    cancel:register("mouseClick", function ()
        menu:destroy()
        local test = dofile("Data Files/MWSE/mods/alchemyFiltering/test.lua")
        test()
    end)
    local cancel = menu:createButton{text = "Cancel"}
    cancel:register("mouseClick", function ()
        menu:destroy()
    end)
    menu:updateLayout()
    IconText:create{parent= menu, text = "Cure Poison", path ="s\\Tx_S_Cure_Poision.tga", isButton = true}
    IconText:create{parent= menu, text = "Cure Poison", path ="s\\Tx_S_Cure_Poision.tga"}

    IconText:create{parent= menu, text = "Cure Poison", path ="s\\Tx_S_Cure_Poision.tga", isLabel = true}
    IconText:create{parent= menu, text = "Cure Poison", isLabel = true}

    menu:updateLayout()
    common:logTree(menu)
    -- Icons\s\Tx_S_Cure_Poision.tga
end

return test
