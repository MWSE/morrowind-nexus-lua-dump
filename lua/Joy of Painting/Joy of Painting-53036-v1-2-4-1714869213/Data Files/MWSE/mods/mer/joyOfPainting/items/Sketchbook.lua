local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Sketchbook")
local Painting = require("mer.joyOfPainting.items.Painting")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")
local CraftingFramework = require("CraftingFramework")

---@class JOP.Sketchbook
---@field reference tes3reference
---@field item JOP.tes3itemChildren
---@field dataHolder tes3itemData|tes3reference
---@field data table joyOfPainting data
---@field currentSketchIndex integer
local Sketchbook = {
    classname = "Sketchbook",
}
Sketchbook.__index = Sketchbook

---@class JOP.Sketchbook.sketch
---@field itemId string id of the item
---@field data table joyOfPainting data


---@class JOP.Sketchbook.data
---@field id string?
---@field reference tes3reference?
---@field item JOP.tes3itemChildren
---@field itemData tes3itemData?

---@param e JOP.Sketchbook.data
function Sketchbook.registerSketchbook(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    e.id = e.id:lower()
    config.sketchbooks[e.id] = table.copy(e, {})
    CraftingFramework.Indicator.register{
        objectId = e.id,
        additionalUI = function(indicator, parent)
            local sketchbook = Sketchbook:new{
                reference = indicator.reference,
                item = indicator.item --[[@as JOP.tes3itemChildren]],
                itemData = indicator.dataHolder --[[@as tes3itemData]]
            }
            if sketchbook then
                sketchbook:doTooltip(parent)
            end
        end
    }
end

---@param e JOP.Sketchbook.data
function Sketchbook:new(e)
    assert(e.reference or e.item, "Sketchbook requires either a reference or an item")
    local sketchbook = setmetatable({}, self)
    sketchbook.reference = e.reference
    sketchbook.item = e.item
    if e.reference and not e.item then
        sketchbook.item = e.reference.object --[[@as JOP.tes3itemChildren]]
    end
    sketchbook.dataHolder = (e.itemData ~= nil) and e.itemData or e.reference
    sketchbook.data = setmetatable({}, {
        __index = function(_, k)
            if not (
                sketchbook.dataHolder
                and sketchbook.dataHolder.data
                and sketchbook.dataHolder.data.joyOfPainting
            ) then
                return nil
            end
            return sketchbook.dataHolder.data.joyOfPainting[k]
        end,
        __newindex = function(_, k, v)
            if not (
                sketchbook.dataHolder
                and sketchbook.dataHolder.data
                and sketchbook.dataHolder.data.joyOfPainting
            ) then
                if not sketchbook.reference then
                    logger:debug("sketchbook.item: %s", sketchbook.item)
                    --create itemData
                    sketchbook.dataHolder = tes3.addItemData{
                        to = tes3.player,
                        item = sketchbook.item,
                    }
                    if not sketchbook.dataHolder then
                        logger:error("Failed to create itemData for sketchbook")
                        return
                    end
                end
                sketchbook.dataHolder.data.joyOfPainting = {
                    sketches = {}
                }
            end
            sketchbook.dataHolder.data.joyOfPainting[k] = v
        end
    })
    logger:debug("Sketches: %s", sketchbook.data.sketches)

    --convert back to array after being json serialised in save file
    if sketchbook.data.sketches then
        for k,v in pairs(sketchbook.data.sketches) do
            if type(k) == "string" and tonumber(k) then
                sketchbook.data.sketches[tonumber(k)] = v
                sketchbook.data.sketches[k] = nil
            end
        end
    end
    local hasSketches = (sketchbook.data.sketches ~= nil)
        and #sketchbook.data.sketches > 0
    sketchbook.currentSketchIndex = hasSketches and 1 or 0
    logger:debug("sketchindex = %s", sketchbook.currentSketchIndex)
    return sketchbook
end

function Sketchbook:addSketch(e)
    local item = e.item
    local itemData = e.itemData
    local painting = Painting:new{
        item = item,
        itemData = itemData,
    }
    if not painting:isSketch() then
        logger:error("Tried to add non-sketch to sketchbook")
        return
    end

    ---@type JOP.Sketchbook.sketch
    local newSketch = {
        itemId = painting.item.id,
        data = painting.dataHolder.data.joyOfPainting
    }

    --add to sketch list
    self.currentSketchIndex = self.currentSketchIndex + 1
    table.insert(self.data.sketches, self.currentSketchIndex, newSketch)

    --remove from inventory
    tes3.removeItem{
        item = e.item,
        itemData = itemData,
        reference = tes3.player,
        playSound = false
    }
    tes3.messageBox('"%s" added to sketchbook.', newSketch.data.paintingName)
    self:createSketchMenu()
    tes3.playSound{
        sound = "scroll",
        reference = tes3.player
    }
end

---@return JOP.Sketchbook.sketch
function Sketchbook:getCurrentSketch()
    return self.data.sketches[self.currentSketchIndex]
end

function Sketchbook:getSketchObject(sketch)
    if not sketch then sketch = self:getCurrentSketch() end
    if not sketch then
        logger:error("getSketchObject: Tried to get non-existent sketch")
        return nil
    end
    return tes3.getObject(sketch.itemId) --[[@as JOP.tes3itemChildren]]
end

function Sketchbook:removeSketch()
    --if no sketches, do nothing
    if #self.data.sketches == 0 then
        return
    end
    --check sketch exists at index
    if not self:getCurrentSketch() then
        logger:error("Tried to remove non-existent sketch")
    end
    local currentSketchObject = self:getSketchObject()
    if not currentSketchObject then
        logger:error("Tried to remove non-existent sketch")
        return
    end

    --remove current sketch
    ---@type JOP.Sketchbook.sketch
    local currentSketch = table.remove(self.data.sketches, self.currentSketchIndex)
    if self.currentSketchIndex > #self.data.sketches then
        self.currentSketchIndex = self.currentSketchIndex - 1
    end

    logger:debug("removing sketch %s", currentSketch.itemId)
    tes3.addItem{
        item = currentSketchObject,
        reference = tes3.player,
        playSound = false,
    }
    local itemData = tes3.addItemData{
        to = tes3.player,
        item = currentSketch.itemId,
    }
    itemData.data.joyOfPainting = currentSketch.data
    tes3.messageBox('"%s" removed from sketchbook.', currentSketch.data.paintingName)
    self:createSketchMenu()
    tes3.playSound{
        sound = "scroll",
        reference = tes3.player
    }
end

function Sketchbook:selectSketch()
    --selectInventoryMenu filtering on artwork that doesn't require an easel
    tes3ui.showInventorySelectMenu{
        title = "Select a sketch to add to your sketchbook.",
        noResultsText = "No sketches found.",
        filter = function(e)
            local painting = Painting:new{
                item = e.item,
                itemData = e.itemData,
            }
            return painting:isSketch()
        end,
        callback = function(e)
            if e.item then
                self:addSketch(e)
            end
        end
    }
end

function Sketchbook:createBaseMenu()
    local menu = tes3ui.findMenu("JOP_SketchbookMenu")
    if menu then
        menu:destroy()
    end
    menu = tes3ui.createMenu{
        id = "JOP_SketchbookMenu",
        fixedFrame = true,
    }
    return menu
end

function Sketchbook:createTitle(parent)
    local titleText = self.item.name
    if self.data.sketchbookName then
        titleText = string.format("%s: %s", titleText, self.data.sketchbookName)
    end

    local title = parent:createLabel{
        id = "JOP_SketchbookTitle",
        text = titleText,
    }
    title.absolutePosAlignX = 0.5
    title.color = tes3ui.getPalette("header_color")
    return title
end

function Sketchbook:createSubtitle(parent)
    --Show sketch index out of tota
    local subtitle = parent:createLabel{text ="(Empty)"}
    subtitle.absolutePosAlignX = 0.5

    ---@type JOP.Sketchbook.sketch
    local currentSketch = self:getCurrentSketch()
    if currentSketch then
        --Add sketch name
        subtitle.text = string.format( '"%s"', currentSketch.data.paintingName)
   end
end

function Sketchbook:createSketchBlock(parent)
    ---@type JOP.Sketchbook.sketch
    local currentSketch = self:getCurrentSketch()
    if currentSketch then
        UIHelper.createPaintingImage(parent,{
            paintingName = currentSketch.data.paintingName,
            paintingTexture = currentSketch.data.paintingTexture,
            canvasId = currentSketch.data.canvasId,
        })
    else
        --create a big rect instead
        local rect = parent:createRect{
            id = "JOP_Sketchbook_EmptyRect",
            color = {0,0,0},
        }
        rect.width = 400
        rect.height = 400
    end
end

function Sketchbook:createNameField(parent)
    ---@type JOP.Sketchbook.sketch
    local currentSketch = self:getCurrentSketch()
    if currentSketch then
        local nameField = UIHelper.createNamePaintingField(parent,{
            dataHolder = currentSketch.data,
            callback = function()
                tes3.messageBox("Renamed to '%s'", currentSketch.data.paintingName)
                self:createSketchMenu()
            end
        })
        nameField.elements.outerContainer.borderBottom = 5
    end
end

function Sketchbook:setButtonState(button, enabled)
    button.disabled = not enabled
    if enabled then
        button.widget.state = 1
    else
        button.widget.state = 2
    end
end


function Sketchbook:createSketchButton(e)
    local parent = e.parent
    local text = e.text
    local callback = e.callback
    local id = e.id or string.format("JOP_SketchbookButton_%s", string.gsub(text, " ", "_"))
    local button = parent:createButton{
        id = id,
        text = text
    }
    if e.enabled == nil then e.enabled = true end
    button:register("mouseClick", callback)
    self:setButtonState(button, e.enabled)
    button.widthProportional = 1.0
    return button
end

function Sketchbook:createNavbar(parent)
    --Previous and Next buttons
    local topRow = parent:createBlock{
        id = tes3ui.registerID("JOP_SketchbookButtons"),
        flowDirection = "left_to_right",
    }
    topRow.autoHeight = true
    topRow.widthProportional = 1.0
    topRow.flowDirection = "left_to_right"
    topRow.borderBottom = 5

    --First
    self:createSketchButton{
        parent = topRow,
        text = "|<",
        enabled = self.currentSketchIndex > 1,
        callback = function()
            self.currentSketchIndex = 1
            self:createSketchMenu()
            tes3.playSound{
                sound = "scroll",
                reference = tes3.player
            }
        end
    }
    --Previous
    self:createSketchButton{
        parent = topRow,
        text = "<<",
        enabled = self.currentSketchIndex > 1,
        callback = function()
            self.currentSketchIndex = self.currentSketchIndex - 1
            self:createSketchMenu()
            tes3.playSound{
                sound = "scroll",
                reference = tes3.player
            }
        end
    }

    --Display current out of total
    local thinBorder = topRow:createThinBorder()
    thinBorder.autoHeight = true
    thinBorder.autoWidth = true
    thinBorder.borderAllSides = 0
    thinBorder.borderTop = 3
    thinBorder.paddingLeft = 5
    thinBorder.paddingRight = 5
    thinBorder.paddingBottom = 4
    thinBorder:createLabel{
        text = string.format("(%d/%d)", self.currentSketchIndex, #self.data.sketches),
    }

    --Next
    self:createSketchButton{
        parent = topRow,
        text = ">>",
        enabled = self.currentSketchIndex < #self.data.sketches,
        callback = function()
            self.currentSketchIndex = self.currentSketchIndex + 1
            self:createSketchMenu()
            tes3.playSound{
                sound = "scroll",
                reference = tes3.player
            }
        end
    }
    --Last
    self:createSketchButton{
        parent = topRow,
        text = ">|",
        enabled = self.currentSketchIndex < #self.data.sketches,
        callback = function()
            self.currentSketchIndex = #self.data.sketches
            self:createSketchMenu()
            tes3.playSound{
                sound = "scroll",
                reference = tes3.player
            }
        end
    }

end

function Sketchbook:playerHasSketches()
    --check player inventory for sketches
    ---@param stack tes3itemStack
    for _, stack in pairs(tes3.player.object.inventory) do
        --iterate variables
        if stack.variables then
            for _, itemData in pairs(stack.variables) do
                local painting = Painting:new{
                    item = stack.object,
                    itemData = itemData,
                }
                if painting:isSketch() then
                    return true
                end
            end
        end
    end
    return false
end

function Sketchbook:createActionButtons(parent)
    --Add, remove and close buttons

    ---@type tes3uiElement
    local bottomRow = parent:createBlock{
        id = tes3ui.registerID("JOP_SketchbookButtons"),
        flowDirection = "left_to_right",
    }
    bottomRow.autoHeight = true
    bottomRow.widthProportional = 1.0
    bottomRow.flowDirection = "left_to_right"

    self:createSketchButton{
        parent = bottomRow,
        text = "Add Sketch",
        enabled = self:playerHasSketches(),
        callback = function()
            self:selectSketch()
        end
    }
    --remove
    self:createSketchButton{
        parent = bottomRow,
        text = "Remove Sketch",
        enabled = self:getCurrentSketch() ~= nil,
        callback = function()
            self:removeSketch()
        end
    }

    if self.reference then
        --take sketchbook
        self:createSketchButton{
            parent = bottomRow,
            text = "Pick Up",
            callback = function()
                self:close()
                common.pickUp(self.reference)
            end,
        }
    end

    --close
    self:createSketchButton{
        id = "JOP_SketchbookMenu_ExitButton",
        parent = bottomRow,
        text = "Close",
        callback = function()
            self:close()
        end
    }
end


function Sketchbook:createSketchMenu()
    self.data.sketches = self.data.sketches or {}
    self.menu = self:createBaseMenu()
    self:createTitle(self.menu)
    self:createSubtitle(self.menu)
    self:createSketchBlock(self.menu)
    self:createNavbar(self.menu)
    self:createNameField(self.menu)
    self:createActionButtons(self.menu)
    tes3ui.enterMenuMode(self.menu.id)
    self.menu:updateLayout()
    self.menu:updateLayout()
    self.menu:updateLayout()
end

function Sketchbook:open()
    self:createSketchMenu()
    tes3.playSound{
        sound = "scroll",
        reference = tes3.player
    }
end

function Sketchbook:rename()
    local menu = UIHelper.createBaseMenu("JOP.NamePaintingMenu")
    menu:createLabel{
        text = "Enter a new name for your sketchbook:",
    }
    local textField = mwse.mcm.createTextField(menu, {
        buttonText = "Submit",
        variable = mwse.mcm.createTableVariable{
            id = "sketchbookName",
            table = self.data,
        },
        callback = function()
            if self.data.sketchbookName == "" then
                self.data.sketchbookName = nil
            end
            if self.data.sketchbookName then
                tes3.messageBox("Sketchbook renamed to: %s", self.data.sketchbookName)
            end
            menu:destroy()
            tes3ui.leaveMenuMode()
        end,
    })
    tes3ui.acquireTextInput(textField.elements.inputField)
    tes3ui.enterMenuMode("JOP.NamePaintingMenu")
end

function Sketchbook:activate()
    tes3ui.showMessageMenu{
        message = self.item.name,
        buttons = {
            {
                text = "Open",
                callback = function()
                    timer.delayOneFrame(function()
                        self:open()
                    end)
                end
            },
            {
                text = "Rename",
                callback = function()
                    timer.delayOneFrame(function()
                        self:rename()
                    end)
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    common.pickUp(self.reference)
                end
            },
        },
        cancels = true
    }
end

function Sketchbook:doTooltip(parent)
    local numSketches = self.data.sketches and #self.data.sketches or 0
    local labelText = string.format("Sketches: %d", numSketches)
    parent:createLabel{ text = labelText }
    if self.data.sketchbookName then
        labelText = string.format('"%s"', self.data.sketchbookName)
        parent:createLabel{ text = labelText }
    end
end

function Sketchbook:close()
    tes3ui.leaveMenuMode()
    self.menu:destroy()
end



return Sketchbook