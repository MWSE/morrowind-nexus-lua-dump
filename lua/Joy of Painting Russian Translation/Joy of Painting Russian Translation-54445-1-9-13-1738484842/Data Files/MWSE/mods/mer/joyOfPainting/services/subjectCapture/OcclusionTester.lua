local config = require("mer.joyOfPainting.config")
local PixelMap = require("mer.joyOfPainting.services.subjectCapture.PixelMap")

---@class OcclusionTester
---@field targets niNode[]
---@field root niNode
---@field mask niNode
---@field camera niCamera
---@field texture niRenderedTexture
---@field pixelData niPixelData
---@field logger mwseLogger
---@field viewportAspectResolution number
---@field viewportScale number
local OcclusionTester = {}
OcclusionTester.__index = OcclusionTester

---@class OcclusionTester.params
---@field resolutionScale? number
---@field viewportAspectResolution? number
---@field viewportScale? number
---@field logger? mwseLogger

function OcclusionTester.getNearestPowerOfTwo(n)
    return 2 ^ math.floor(math.log(n, 2))
end

--- Create a new occlusion tester. Must be called *after* `initalized`.
---
---@param e OcclusionTester.params|nil
---@return OcclusionTester
function OcclusionTester.new(e)
    e = e or {}
    local this = setmetatable({}, OcclusionTester)
    this.viewportAspectResolution = e.viewportAspectResolution or 1.0
    this.viewportScale = e.viewportScale or 1.0

    this.logger = e.logger or require("logging.logger").new{name="OcclusionTester"}

    -- Rounds width and height to nearest power of two.
    local s = e.resolutionScale or 1.0
    local w, h = tes3ui.getViewportSize()
    w = OcclusionTester.getNearestPowerOfTwo(w * s)
    h = OcclusionTester.getNearestPowerOfTwo(h * s)
    assert(w >= 128 and h >= 128)

    -- Create the render target texture and pixel data.
    this.texture = assert(niRenderedTexture.create(w, h))
    this.pixelData = niPixelData.new(w, h)

    -- Create the utility meshes for managing stencils.
    ---@diagnostic disable
    this.root = assert(tes3.loadMesh("jop\\occlusionTester.nif")):clone()
    this.mask = assert(this.root:getObjectByName("Masked Objects"))
    ---@diagnostic enable

    -- Attach to camera, assign a convenience accessor.
    this.camera = tes3.worldController.worldCamera.cameraData.camera
    this.camera.parent:attachChild(this.root)

    -- Array of sceneNodes that we are testing against.
    this.targets = {}

    return this
end

--- Set the target scene objects that will be occlusion tested.
---
---@param sceneNodes niNode[]
function OcclusionTester:setTargets(sceneNodes)
    -- clear previous targets
    self.targets = {}
    self.mask:detachAllChildren()

    -- collect the new targets
    for _, node in pairs(sceneNodes) do
        table.insert(self.targets, node)
        for shape in table.traverse({ node }) do
            if shape:isInstanceOfType(tes3.niType.NiTriShape)
                and not shape:isAppCulled()
            then
                local t = shape.worldTransform
                shape = shape:clone()
                shape:copyTransforms(t)
                shape:detachAllProperties()
                self.mask:attachChild(shape, true)
            end
        end
    end
    self.mask:clearTransforms()
    self.mask:update()
end

--- Returns a normalized value representing the ratio of pixels that are not occluded.
---
---@return number
function OcclusionTester:getVisibility(maximum, visible)
    local ratio = 0.0
    if maximum ~= 0 then
        ratio = (visible / maximum)
    end
    return ratio
end

--- Returns a normalized value representing the ratio of active, visible
--- pixels compared to the total pixels in the scene.
function OcclusionTester:getPresence(active, total)
    local ratio = 0.0
    if total ~= 0 then
        ratio = (active / total)
    end
    return ratio
end

function OcclusionTester:getFraming(active, total)
    local ratio = 0.0
    if total ~= 0 then
        ratio = (active / total)
    end
    return ratio
end

---@class JOP.OcclusionTester.PixelDiagnostics
---@field presence number The ratio of active, visible pixels compared to the total pixels in the scene.
---@field visibility number The ratio of active pixels that are not occluded.
---@field framing number The ratio of active pixels that are on the edge of the scene.

---@param id string
---@return JOP.OcclusionTester.PixelDiagnostics
function OcclusionTester:getPixelDiagnostics(id)
    local totalActiveData = self:getPixelCounts({ visibleOnly = false })
    self:dumpDebug(id .. "_total")
    local visibleOnlyData = self:getPixelCounts({ visibleOnly = true })
    self:dumpDebug(id .. "_visible")
    local presence = self:getPresence(visibleOnlyData.active, totalActiveData.total)
    local visibility = self:getVisibility(totalActiveData.active, visibleOnlyData.active)
    local framing = self:getFraming(visibleOnlyData.activeEdges, visibleOnlyData.totalEdges)
    return {
        presence = presence,
        visibility = visibility,
        framing = framing,
    }
end

function OcclusionTester:enable()
    self.root.appCulled = false
    self.root:update()
    for _, node in ipairs(self.targets) do
        node.appCulled = true
    end
    if mge.camera.zoomEnable then
        self.logger:warn("MGE Zoom is enabled during Occlusion testing")
    end
end

function OcclusionTester:disable()
    self.root.appCulled = true
    self.root:update()
    for _, node in ipairs(self.targets) do
        node.appCulled = false
    end
end

function OcclusionTester:capturePixelData()
    self.logger:debug("Capturing pixel data...")

    ---@diagnostic disable
    self.camera.renderer:setRenderTarget(self.texture)
    self.camera:clear()
    self.camera:click()
    self.camera:swapBuffers()
    self.camera.renderer:setRenderTarget(nil)
    ---@diagnostic enable

    self.logger:debug("Finished capturing pixel data.")
    assert(self.texture:readback(self.pixelData))
end

function OcclusionTester:dumpDebug(subjectId)
    if config.mcm.debugMeshes then
        self.logger:warn("Dumping debug image for %s", subjectId)
        local plane = tes3.loadMesh("jop\\debug_plane.nif")
        plane.texturingProperty.maps[1].texture = self.pixelData:createSourceTexture()
        plane:saveBinary(string.format("data files\\meshes\\_debug\\%s.nif", subjectId))
    end
end

---@return JOP.PixelMap.countPixels.data
function OcclusionTester:getPixelCounts(e)
    e = e or { visibleOnly = false}
    ---@diagnostic disable
    if e.visibleOnly then
        self.mask.zBufferProperty.testFunction = ni.zBufferPropertyTestFunction.lessEqual
    else
        self.mask.zBufferProperty.testFunction = ni.zBufferPropertyTestFunction.always
    end
    ---@diagnostic enable
    self:capturePixelData()
    self.logger:debug("Counting pixels...")
    local pixelMap = PixelMap.new{
        pixelData = self.pixelData,
        viewportScale = self.viewportScale,
        aspectRatio = self.viewportAspectResolution,
    }
    return pixelMap:getPixelCountData()
end


return OcclusionTester
