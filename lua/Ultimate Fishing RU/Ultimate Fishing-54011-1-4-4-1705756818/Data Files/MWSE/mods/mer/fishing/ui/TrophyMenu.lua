local common = require("mer.fishing.common")
local logger = common.createLogger("TrophyMenu")

---Creates a ui that displays a caught fish along with a description and stats
---@class Fishing.TrophyMenu
local TrophyMenu = {
    PREVIEW_WIDTH = 700,
    PREVIEW_HEIGHT = 500,
}

local uiids = {
    menu = "Fishing:TrophyMenu",
    previewBorder = "Fishing:TrophyMenu:PreviewBorder",
    nifPreviewBlock = "Fishing:TrophyMenu:NifPreviewBlock",
    nif = "Fishing:TrophyMenu:Nif",
}

local function getMenu()
    return tes3ui.findMenu(uiids.menu)
end


local function removeCollision(sceneNode)
    for node in table.traverse{sceneNode} do
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then
            node.appCulled = true
        end
    end
end

local m1 = tes3matrix33.new()
local m2 = tes3matrix33.new()
local function createPreviewPane(parent, meshID)
    local menu = getMenu()

    logger:debug("Creating preview pane for %s", meshID)
    local previewBorder = menu:findChild(uiids.previewBorder)
    if previewBorder then
        previewBorder:destroy()
    end
    previewBorder = parent:createThinBorder{ id = uiids.previewBorder }
    --previewBorder.width = self.previewWidth
    previewBorder.flowDirection = "top_to_bottom"
    previewBorder.autoWidth = true
    previewBorder.autoHeight = true
    previewBorder.childAlignX = 0.5
    previewBorder.borderAllSides = 4
    --previewBorder.absolutePosAlignX = 0

    local nifPreviewBlock = previewBorder:createBlock{ id = uiids.nifPreviewBlock }
    --nifPreviewBlock.width = self.previewWidth
    nifPreviewBlock.width = TrophyMenu.PREVIEW_WIDTH
    nifPreviewBlock.height = TrophyMenu.PREVIEW_HEIGHT

    nifPreviewBlock.childOffsetX = TrophyMenu.PREVIEW_WIDTH/2
    nifPreviewBlock.childOffsetY = -TrophyMenu.PREVIEW_HEIGHT/2
    nifPreviewBlock.paddingAllSides = 2

    local rootNif = nifPreviewBlock:createNif{ id = uiids.nif, path = "craftingFramework\\empty.nif"}
    if not rootNif then
        logger:error("Empty nif not found")
        return
    end
    logger:trace("RootNif: %s", rootNif)

    --Avoid popups/CTDs if the mesh is missing.
    if not tes3.getFileExists(string.format("Meshes\\%s", meshID)) then
        logger:error("Mesh does not exist: %s", meshID)
        return
    end

    local mesh = tes3.loadMesh(meshID, false)
    if not mesh then
        logger:error("Mesh not found: %s", meshID)
        return
    end
    logger:trace("Mesh: %s", mesh)
    menu:updateLayout()

    local rootNode = rootNif.sceneNode --[[@as niNode]]
    rootNode:updateProperties()
    logger:trace("attaching mesh to rootNode")
    rootNode:attachChild(mesh)
    removeCollision(rootNode)
    do --add properties
        logger:trace("Adding properties")
        local vertexColorProperty = niVertexColorProperty.new()
        vertexColorProperty.name = "vcol yo"
        vertexColorProperty.source = 2
        rootNode:attachProperty(vertexColorProperty)

        local zBufferProperty = niZBufferProperty.new()
        zBufferProperty.name = "zbuf yo"
        zBufferProperty:setFlag(true, 0)
        zBufferProperty:setFlag(true, 1)
        rootNode:attachProperty(zBufferProperty)
    end

    local maxDimension
    local bb = rootNode:createBoundingBox(rootNode.scale) ---@diagnostic disable-line
    local height = (bb.max.z - bb.min.z)*2
    local width = bb.max.y - bb.min.y
    local depth = bb.max.x - bb.min.x
    maxDimension = math.max(width, depth, height)
    local targetHeight = TrophyMenu.PREVIEW_HEIGHT/2
    rootNode.scale = (targetHeight / maxDimension) * 1.5
    do --Apply rotation
        logger:trace("Applying rotation")
        local offset = -20
        m1:toRotationX(math.rad(-15))
        m2:toIdentity()
        local lowestPoint = bb.max.z * rootNode.scale
        offset = offset + lowestPoint
        --m2:toRotationY(math.rad(180))
        rootNode.translation.z = rootNode.translation.z + offset
        rootNode.rotation = rootNode.rotation * m1:copy() * m2:copy()
    end

    logger:trace("Updating rootNode")
    rootNode.appCulled = false
    rootNode:updateProperties()
    rootNode:update()
    rootNode:updateEffects()
    nifPreviewBlock:updateLayout()
    previewBorder:updateLayout()
    return previewBorder
end

local function rotateNif(e)
    local menu = tes3ui.findMenu(uiids.menu)
    if not menu then
        event.unregister("enterFrame", rotateNif)
        return
    end
    local nif = menu:findChild(uiids.nif)
    if nif and nif.sceneNode then
        local node = nif.sceneNode
        m2:toRotationZ(math.rad(15) * e.delta)
        node.rotation = node.rotation * m2
        node:update()
    end
end


---@param parent tes3uiElement
---@param headerText string
---@param description string
local function createDescription(parent, headerText, description)
    --create text block
    local textBlock = parent:createThinBorder{ id = uiids.textBlock }
    textBlock.widthProportional = 1.0
    textBlock.autoHeight = true
    textBlock.flowDirection = "top_to_bottom"
    textBlock.borderAllSides = 4
    textBlock.paddingAllSides = 10

    ---create header
    local header = textBlock:createLabel{ id = uiids.header, text = headerText }
    header.color = tes3ui.getPalette("header_color")
    header.wrapText = true
    header.justifyText = "center"
    header.widthProportional = 1.0

    ---create description
    if description then
        local descriptionText = description
        local descriptionLabel = textBlock:createLabel{ id = uiids.description, text = descriptionText }
        descriptionLabel.wrapText = true
        descriptionLabel.justifyText = "center"
        descriptionLabel.widthProportional = 1.0
    end

    textBlock:updateLayout()
    return textBlock
end

local function createButtonsBlock(parent)
    local block = parent:createBlock()
    block.flowDirection = "left_to_right"
    block.widthProportional = 1.0
    block.autoHeight = true
    block.childAlignX = 1.0
    return block
end

local function createButton(parent, button)
    local closeButton = parent:createButton{ text = button.text }
    closeButton:register("mouseClick", function()
        local menu = getMenu()
        if menu then
            menu:destroy()
            tes3ui.leaveMenuMode()
        end
        if button.callback then
            button.callback()
        end
    end)
    return closeButton
end

---@class TrophyMenu.createMenu.params
---@field header string The header text
---@field description string The description text
---@field previewMesh string The mesh to be displayed in the trophy menu
---@field buttons TrophyMenu.createMenu.buttonConfig[] A list of buttons to be displayed

---@class TrophyMenu.createMenu.buttonConfig
---@field text string The text to be displayed on the button
---@field callback function The function to be called when the button is clicked

---@param e TrophyMenu.createMenu.params
function TrophyMenu.createMenu(e)
    local menu = tes3ui.createMenu{
        id = uiids.menu,
        fixedFrame = true
    }
    menu.minWidth = TrophyMenu.PREVIEW_WIDTH
    menu.minHeight = TrophyMenu.PREVIEW_HEIGHT
    menu.absolutePosAlignX = 0.5
    menu.flowDirection = "top_to_bottom"
    createPreviewPane(menu, e.previewMesh)
    createDescription(menu, e.header, e.description)
    local buttonsBlock = createButtonsBlock(menu)
    for _, button in ipairs(e.buttons) do
        createButton(buttonsBlock, button)
    end
    event.register("enterFrame", rotateNif)
    menu:updateLayout()
    tes3ui.enterMenuMode(uiids.menu)
end


return TrophyMenu