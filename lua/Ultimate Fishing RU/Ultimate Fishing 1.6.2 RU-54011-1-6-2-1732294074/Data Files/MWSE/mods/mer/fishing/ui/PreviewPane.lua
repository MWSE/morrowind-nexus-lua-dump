
local common = require("mer.fishing.common")
local logger = common.createLogger("PreviewPane")

---@class Fishing.PreviewPane.newParams
---@field meshID string
---@field parent tes3uiElement
---@field previewWidth number
---@field previewHeight number

---@class Fishing.PreviewPane : Fishing.PreviewPane.newParams
local PreviewPane = {}

local m1 = tes3matrix33.new()
local m2 = tes3matrix33.new()
local uiids = {
    previewBorder = "Fishing:PreviewBorder",
    nifPreviewBlock = "Fishing:NifPreviewBlock",
    nif = "Fishing:Nif",
}

---@param e Fishing.PreviewPane
---@return Fishing.PreviewPane
function PreviewPane.new(e)
    local self = setmetatable(table.copy(e), { __index = PreviewPane })
    return self
end

local function removeCollision(sceneNode)
    for node in table.traverse{sceneNode} do
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then
            node.appCulled = true
        end
    end
end


function PreviewPane:startRotate()
    local function rotate(e)
        local nif = self.parent:findChild(uiids.nif)
        if nif and nif.sceneNode then
            local node = nif.sceneNode
            m2:toRotationZ(math.rad(15) * e.delta)
            node.rotation = node.rotation * m2
            node:update()
        end
    end
    event.register("enterFrame", rotate)
    self.parent:register("destroy", function()
        event.unregister("enterFrame", rotate)
    end)
end

function PreviewPane:create()
    logger:debug("Creating preview pane for %s", self.meshID)
    local previewBorder = self.parent:findChild(uiids.previewBorder)
    if previewBorder then
        previewBorder:destroy()
    end
    previewBorder = self.parent:createThinBorder{ id = uiids.previewBorder }
    --previewBorder.width = self.previewWidth
    previewBorder.flowDirection = "top_to_bottom"
    previewBorder.autoWidth = true
    previewBorder.autoHeight = true
    previewBorder.childAlignX = 0.5
    previewBorder.borderAllSides = 4
    --previewBorder.absolutePosAlignX = 0

    local nifPreviewBlock = previewBorder:createBlock{ id = uiids.nifPreviewBlock }
    --nifPreviewBlock.width = self.previewWidth
    nifPreviewBlock.width = self.previewWidth
    nifPreviewBlock.height = self.previewHeight

    nifPreviewBlock.childOffsetX = self.previewWidth/2
    nifPreviewBlock.childOffsetY = -self.previewHeight/2
    nifPreviewBlock.paddingAllSides = 2

    local rootNif = nifPreviewBlock:createNif{ id = uiids.nif, path = "craftingFramework\\empty.nif"}
    if not rootNif then
        logger:error("Empty nif not found")
        return
    end
    logger:trace("RootNif: %s", rootNif)

    --Avoid popups/CTDs if the mesh is missing.
    if not tes3.getFileExists(string.format("Meshes\\%s", self.meshID)) then
        logger:error("Mesh does not exist: %s", self.meshID)
        return
    end

    local mesh = tes3.loadMesh(self.meshID, false)

    if not mesh then
        logger:error("Mesh not found: %s", self.meshID)
        return
    end
    logger:trace("Mesh: %s", mesh)

    self.parent:updateLayout()

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

    local bb = mesh:createBoundingBox(mesh.scale) ---@diagnostic disable-line
    --Log bounding box values
    local height = (bb.max.z - bb.min.z)*2
    local width = bb.max.y - bb.min.y
    local depth = bb.max.x - bb.min.x
    local maxDimension = math.max(width, depth, height)
    local lowestPoint = bb.max.z * mesh.scale

    -- mesh:update()
    -- local maxDimension = mesh.worldBoundRadius * 2
    -- logger:debug("maxDimension: %s", maxDimension)
    -- local lowestPoint = mesh.worldBoundOrigin.z - mesh.worldBoundRadius

    local targetHeight = self.previewHeight/2
    mesh.scale = (targetHeight / maxDimension) * 1.5
    do --Apply rotation
        local offset = -20
        m1:toRotationX(math.rad(-15))
        m2:toIdentity()

        offset = offset + lowestPoint
        --m2:toRotationY(math.rad(180))
        rootNode.translation.z = rootNode.translation.z + offset
        rootNode.rotation = rootNode.rotation * m1:copy() * m2:copy()
    end

    rootNode.appCulled = false
    rootNode:updateProperties()
    rootNode:update{ controllers = true, time = 0 }
    rootNode:updateEffects()

    nifPreviewBlock:updateLayout()
    previewBorder:updateLayout()
    self:startRotate()
    return previewBorder
end

return PreviewPane