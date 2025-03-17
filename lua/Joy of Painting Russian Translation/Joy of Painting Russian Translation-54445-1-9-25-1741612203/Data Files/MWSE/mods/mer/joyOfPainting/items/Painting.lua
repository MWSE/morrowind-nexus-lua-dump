local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local PaintService = require("mer.joyOfPainting.services.PaintService")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local Subject = require("mer.joyOfPainting.items.Subject")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Painting")
local meshService = require("mer.joyOfPainting.services.MeshService")
--[[
    Painting class for managing any item that has a painting
]]

---@alias JOP.tes3itemChildren tes3item|tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon

---@alias JOP.CanvasType
---| '"paper"'
---| '"canvas"'

---@class JOP.Painting.location
---@field cellId string?
---@field regionId string?
---@field cellName string?
---@field position tes3vector3?
---@field orientation tes3vector3?

---@class JOP.Painting.data
---@field canvasId string
---@field canvasType string
---@field paintingId string
---@field paintingTexture string
---@field paintingName string
---@field location JOP.Painting.location | string
---@field artStyle string The name of the artStyle
---@field subjects table<string, JOP.SubjectService.Result>


---@class JOP.Painting
---@field id string
---@field reference tes3reference
---@field data JOP.Painting.data
---@field item JOP.tes3itemChildren
---@field dataHolder tes3itemData|tes3reference
local Painting = {
    classname = "Painting",
}

Painting.__index = Painting

Painting.canvasFields = {
    "canvasId",
    "paintingId",
    "paintingTexture",
    "paintingName",
    "location",
    "artStyle",
    "subjects"
}
---@class JOP.Painting.params
---@field reference? tes3reference
---@field item? JOP.tes3itemChildren
---@field itemData? tes3itemData

---@class JOP.Canvas
---@field canvasId string The id of the canvas. Must be unique.
---@field rotatedId string? The id of the canvas to use when rotated. If not provided, the canvas will not be rotatable.
---@field textureWidth number The width of the texture to be used for the canvas.
---@field textureHeight number The height of the texture to be used for the canvas.
---@field frameSize string The size of the frame to use for the canvas. Must be one of "sqaure", "tall", or "wide"
---@field valueModifier number The value modifier for the painting
---@field canvasTexture string The texture to use for the canvas
---@field meshOverride string? An optional mesh override for the canvas
---@field requiresEasel boolean? Whether the canvas requires an easel to be painted on
---@field animSpeed number The speed of the painting animation
---@field animSound string The sound to play while painting
---@field clampOffset number? The amount to raise the easel clamp
---@field baseRotation number? *Default: 0* How much the canvas texture should be rotated when compositing

---@param e JOP.Canvas
function Painting.registerCanvas(e)
    logger:assert(type(e.canvasId) == "string", "id must be a string")
    logger:assert(type(e.textureHeight) == "number", "textureHeight must be a number")
    logger:assert(type(e.textureHeight) == "number", "textureHeight must be a number")
    logger:assert(type(e.frameSize) == "string", "frameSize must be a string")
    logger:assert(type(e.valueModifier) == "number", "valueModifier must be a number")
    logger:assert(type(e.canvasTexture) == "string", "canvasTexture must be a string")
    logger:assert(type(e.animSpeed) == "number", "animSpeed must be a number")
    logger:assert(type(e.animSound) == "string", "animSound must be a string")

    logger:debug("Registering canvas %s with frameSize %s", e.canvasId, e.frameSize)
    local id = e.canvasId:lower()
    config.canvases[id] = table.copy(e, {})
    if e.meshOverride then
        meshService.registerOverride(id, e.meshOverride)
    end
end

---@param id string
---@return boolean
function Painting.idIsCanvas(id)
    return config.canvases[id:lower()] ~= nil
end

---@param reference tes3reference
---@return boolean
function Painting.refIsPainting(reference)
    return reference.supportsLuaData
        and reference.data
        and reference.data.joyOfPainting
        and reference.data.joyOfPainting.paintingTexture ~= nil
end

---@param itemData tes3itemData
---@return boolean
function Painting.itemDataIsPainting(itemData)
    return itemData
        and itemData.data
        and itemData.data.joyOfPainting
        and itemData.data.joyOfPainting.paintingTexture ~= nil
end

function Painting.getCanvasObject(dataHolder)
    --get canvas object from id
    if dataHolder.data.joyOfPainting.canvasId then
        return tes3.getObject(dataHolder.data.joyOfPainting.canvasId)
    end
end

function Painting.getPaintingOrCanvasName(dataHolder)
    local paintingData = dataHolder
        and dataHolder.data
        and dataHolder.data.joyOfPainting
    if not paintingData then return end
    if paintingData.paintingName then
        return paintingData.paintingName
    elseif paintingData.canvasId then
        return Painting.getCanvasObject(dataHolder).name
    end
end

---@param e JOP.Painting.params
---@return JOP.Painting
function Painting:new(e)
    local painting = setmetatable({}, self)
    logger:assert(e.reference ~= nil or e.item ~= nil,
        "Painting:new() requires either a reference or an item")

    painting.reference = e.reference
    painting.item = e.item or e.reference.object
    painting.dataHolder = e.itemData or e.reference
    painting.id = painting.item.id:lower()

    local safeRef
    if e.reference then
        safeRef = tes3.makeSafeObjectHandle(e.reference)
    end

    -- reference data
    painting.data = setmetatable({}, {
        __index = function(_, k)
            if safeRef and not safeRef:valid() then return end

            if painting.reference then
                if not painting.reference.supportsLuaData then
                    return nil
                end
            end
            if not (
                painting.dataHolder
                and painting.dataHolder.data
                and painting.dataHolder.data.joyOfPainting
            ) then
                return nil
            end
            return painting.dataHolder.data.joyOfPainting[k]
        end,
        __newindex = function(_, k, v)
            if safeRef and not safeRef:valid() then return end
            if painting.reference then
                logger:debug("Setting data field %s from reference %s", k, painting.reference.id)
                if not painting.reference.supportsLuaData then
                    logger:warn("Reference %s does not support lua data", painting.reference.id)
                    return
                end
            else
                logger:debug("Setting data field %s from item %s", k, painting.item.id)
            end

            --If we didn't previous have itemData added to the item, add it now
            if not painting.dataHolder then
                painting.dataHolder = tes3.addItemData{
                    to = tes3.player,
                    item = painting.item,
                }
            end
            if not painting.dataHolder.data.joyOfPainting then
                painting.dataHolder.data.joyOfPainting = {}
            end
            painting.dataHolder.data.joyOfPainting[k] = v
        end
    })
    return painting
end


---@return JOP.CanvasType
function Painting:getCanvasType()
    if self:isSketch() then
        return "paper"
    end
    return "canvas"
end

function Painting:isSketch()
    return self:hasPaintingData()
        and not self:getCanvasConfig().requiresEasel
end

function Painting:isPaintingObject()
    return self.reference
        and self.reference.object.id == self.data.paintingTexture
end

---Check if the painting has a subject depicted in it
---@param subjectId string The object ID of the subject
---@return JOP.SubjectService.Result?
function Painting:getSubjectResult(subjectId)
    return self.data.subjects and self.data.subjects[subjectId:lower()]
end

---@return table<string, JOP.SubjectService.Result>
function Painting:getSubjectResults()
    return self.data.subjects or {}
end



---Removes all data and replaces the painting with the original canvas
function Painting:clearCanvas()
    logger:debug("Clearing painting data")
    if self.data.canvasId then
        logger:debug("Has canvasId: %s", self.data.canvasId)
        if self.reference then
            if self:isPaintingObject() then
                logger:debug("%s is painting, replacing with original canvas", self.reference)
                tes3.createReference{
                    object = self.data.canvasId,
                    position = self.reference.position:copy(),
                    orientation =  self.reference.orientation:copy(),
                    cell = self.reference.cell,
                    scale =    self.reference.scale,
                }
                self.reference:delete()
            else --not the painting object, the easel
                logger:debug("%s is not the actual painting, so just reset the canvas", self.reference)
                self:resetCanvas()
            end
        elseif self.item then
            logger:debug("Replacing item %s in inventory with original canvas %s", self.item.id, self.data.canvasId)
            tes3.addItem{
                item = self.data.canvasId,
                count = 1,
                reference = tes3.player,
                playSound = false,
            }
            tes3.removeItem{
                item = self.item.id,
                itemData = self.dataHolder,
                count = 1,
                reference = tes3.player,
                playSound = false,
            }
        else
            logger:warn("No reference or item, can't clear canvas")
        end
    else
        logger:debug("No canvas ID, cleaning")
        self:cleanCanvas()
    end
end

---comment
---@param location string|JOP.Painting.location
---@param results table<string, JOP.SubjectService.Result>
---@return string
function Painting.createTooltipText(location, results)
    --legacy paintings with string location
    if type(location) == "string" then
        location = {
            cellName = location
        }
    end

    local message = string.format("Расположение: %s", location.cellName)
    if results and table.size(results) > 0 then
        message = message .. "\nОбъекты:"
        local subjectNames = Subject.getSubjectNames(results)
        for subjectName in pairs(subjectNames) do
            message = message .. "\n - " .. subjectName
        end
    end
    return message
end

---@return string
function Painting:getTooltipText()
    return Painting.createTooltipText(self.data.location, self.data.subjects)
end


function Painting:paintingMenu()
    local isPainting = self:hasPaintingData()
    if isPainting then
        logger:debug("Canvas Activated")
        local paintingData = self.data
        local paintingTexture = paintingData.paintingTexture
        local tooltipText = self:getTooltipText()
        local paintingName = paintingData.paintingName and paintingData.paintingName or self.item.name

        local tooltipHeader = paintingName
        logger:debug("Painting Name: %s", paintingName)
        UIHelper.openPaintingMenu{
            canvasId = paintingData.canvasId,
            paintingTexture = paintingTexture,
            tooltipHeader = tooltipHeader,
            tooltipText = tooltipText,
            dataHolder = paintingData,
            callback = function()
                tes3.messageBox("Переименовано в '%s'", paintingData.paintingName)
            end,
            cancels = true
        }
    end
end

function Painting:hasPaintingData()
    return self.data.paintingTexture ~= nil
end

function Painting:hasCanvasData()
    return self.data.canvasId ~= nil
end

function Painting:isCanvas()
    return self:getCanvasConfig() ~= nil
end

---@return JOP.Canvas
function Painting:getCanvasConfig()
    ---@type JOP.Canvas
    local canvasConfig = config.canvases[self.data.canvasId]
    if not canvasConfig then
        local id = self.item.id:lower()
        logger:debug("No canvas config found for %s, checking item id", id)
        return config.canvases[id]
    end
    return canvasConfig
end


function Painting:doVisuals()
    self:doCanvasVisuals()
    self:doPaintingVisuals()
end

function Painting:doCanvasVisuals()
    if not self.reference then return end
    logger:debug("doCanvasVisuals for %s", self.id)
    --Attach the canvas mesh to the attach_canvas node
    local attachNode = NodeManager.getCanvasAttachNode(self.reference.sceneNode)
    if attachNode then
        if attachNode.children and #attachNode.children > 0 then
            for i = 1, #attachNode.children do
                attachNode:detachChildAt(i)
            end
        end
        if not self.data.canvasId then return end
        local canvasObject = tes3.getObject(self.data.canvasId)
        local mesh = tes3.loadMesh(canvasObject.mesh, false)
        local clonedMesh = mesh:clone()
        ---@cast clonedMesh niNode
        NodeManager.moveOriginToAttachPoint(clonedMesh)
        attachNode:attachChild(clonedMesh)
        attachNode:update()
        attachNode:updateEffects()
    end
end

function Painting:isRotatable()
    local canvasConfig = self:getCanvasConfig()
    return canvasConfig and canvasConfig.rotatedId ~= nil
        and not self:hasPaintingData()
end

function Painting:getRotatedId()
    local canvasConfig = self:getCanvasConfig()
    return canvasConfig and canvasConfig.rotatedId
end

---comment
---@param sound string?
---@return tes3reference?
function Painting:rotate(sound)
    local rotatedId = self:getRotatedId()
    if not rotatedId then
        logger:error("Tried to rotate a canvas that has no rotated Id")
    end
    logger:debug("Rotating canvas from %s to %s", self.item.id, rotatedId)

    sound = sound or "Item Misc Up"
    tes3.playSound{
        reference = tes3.player,
        sound = sound,
    }

    if self.reference then
        --delete current reference and replace with rotated version
        local newRef = tes3.createReference{
            object = rotatedId, --[[@as JOP.tes3itemChildren]]
            position = self.reference.position,
            orientation = self.reference.orientation,
            cell = self.reference.cell,
            scale = self.reference.scale,
        }
        local oldRef = self.reference
        oldRef:disable()
        timer.delayOneFrame(function()
            oldRef:delete()
        end)
        self.reference = newRef
        self.item = newRef.object
        self.dataHolder = newRef
        return newRef
    else
        --Remove old item from inventory and add rotated version
        tes3.removeItem{
            item = self.item.id,
            itemData = self.dataHolder,
            count = 1,
            reference = tes3.player,
            playSound = false,
        }
        local _, _, itemData = tes3.addItem{
            item = rotatedId, --[[@as JOP.tes3itemChildren]]
            itemData = self.dataHolder,
            count = 1,
            reference = tes3.player,
            playSound = false,
        }
        self.item = tes3.getObject(rotatedId)
        self.dataHolder = itemData --[[@as tes3itemData]]
    end
end

function Painting:resetPaintTime()
    logger:debug("Resetting paint anim time")
    local now = tes3.getSimulationTimestamp(false)
    local root = self.reference.sceneNode:getObjectByName("SWITCH_PAINT")
    for node in table.traverse{root} do
        if node.controller then
            logger:debug("Resetting controller for %s", node.name)
            node.controller.phase = -now + config.ANIM_OFFSET
        end
        for _, prop in pairs{node.materialProperty, node.texturingProperty} do
            if prop.controller then
                logger:debug("Resetting controller for %s", node.name)
                prop.controller.phase = -now + config.ANIM_OFFSET
            end
        end
    end
end

function Painting:doPaintAnim()
    logger:debug("doPaintAnim()")
    local texture = PaintService.createTexture(self.data.paintingTexture)
    if not texture then
        logger:error("Texture '%s' missing, unable to animate painting", self.data.paintingTexture)
        return
    end
    --get texture node
    local paintTexNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.PAINT_ANIM_TEX_NODE) --[[@as niNode]]
    logger:assert(paintTexNode ~= nil, "No paint node found")

    --set texture
    NodeManager.cloneTextureProperty(paintTexNode)
    paintTexNode.texturingProperty.baseMap.texture = texture
    paintTexNode:update()
    paintTexNode:updateProperties()

    --reset animation
    self:resetPaintTime()

    timer.delayOneFrame(function()
        --set index to animation node
        local switchNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.PAINT_SWITCH) --[[@as niSwitchNode]]
        local animIndex = NodeManager.getIndex(switchNode, NodeManager.nodes.PAINT_SWITCH_ANIMATING )
        if animIndex then
            logger:debug("Setting animation switch index")
            switchNode.switchIndex = animIndex
        else
            logger:error("No animating node found")
        end
    end)
end

function Painting:calculateValue()
    local value = config.BASE_PRICE
    logger:debug("Base value = %s", value)
    --skill
    local skillEffect = SkillService.getValueEffect()
    logger:debug("Skill effect = %s", skillEffect)
    value = value * skillEffect
    logger:debug("Value after skill effect = %s", value)
    --canvas
    local canvasConfig = self:getCanvasConfig()
    local canvasEffect = canvasConfig.valueModifier
    logger:debug("Canvas effect = %s", canvasEffect)
    value = value * canvasEffect
    logger:debug("Value after canvas effect = %s", value)
    --art style
    local artStyleEffect = config.artStyles[self.data.artStyle].valueModifier
    logger:debug("Art style effect = %s", artStyleEffect)
    value = value * artStyleEffect
    logger:debug("Value after art style effect = %s", value)
    --Random (config.MAX_RANDOM_PRICE_EFFECT)
    local randomEffect = math.random(100, config.MAX_RANDOM_PRICE_EFFECT*100)/100
    logger:debug("Random effect = %s", randomEffect)
    value = value * randomEffect
    logger:debug("Value after random effect = %s", value)
    value = math.floor(value)
    logger:debug("FINAL painting value = %s", value)
    return value
end

---@return tes3item|tes3weapon
function Painting:getPaintingObject()
    if self.data.canvasId then
        return tes3.getObject(self.data.canvasId)
    end
    if self.reference then
        return self.reference.object
    end
    return self.item
end

--Creates a new misc item with the paintingTexture as the ID and the path to the icon
function Painting:createPaintingObject()
    assert(self.data.paintingTexture ~= nil, "No painting texture set")
    logger:debug("artStyle name: ", self.data.artStyle)
    local canvasObj = self:getPaintingObject()

    ---@type tes3.createObject.params
    local objParams = {
        id = self.data.paintingTexture,
        name = config.artStyles[self.data.artStyle].name,
        mesh = canvasObj.mesh,
        enchantment = canvasObj.enchantment,
        weight = canvasObj.weight,
        type = canvasObj.type,
        maxCondition = canvasObj.maxCondition,
        speed = canvasObj.speed,
        reach = canvasObj.reach,
        enchantCapacity = canvasObj.enchantCapacity,
        chopMin = canvasObj.chopMin,
        chopMax = canvasObj.chopMax,
        slashMin = canvasObj.slashMin,
        slashMax = canvasObj.slashMax,
        thrustMin = canvasObj.thrustMin,
        thrustMax = canvasObj.thrustMax,
        materialFlags = canvasObj.flags,
        getIfExists = false,
        objectType = tes3.objectType.miscItem,--canvasObj.objectType,
        icon = PaintService.getPaintingIconPath(self.data.paintingTexture),
        value = self:calculateValue(),
    }

    local paintingObject = tes3.createObject(objParams) --[[@as JOP.tes3itemChildren]]

    logger:debug("Created painting object %s", paintingObject.id)
    return paintingObject
end



function Painting:doPaintingVisuals()
    if not self.reference then return end
    if not self.data.paintingTexture then return end
    logger:debug("doPaintingVisuals for %s", self.id)
    local paintingTexture = PaintService.createTexture(self.data.paintingTexture)
    local switchPaintNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.PAINT_SWITCH) --[[@as niSwitchNode]]
    local paintTextureNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.PAINT_TEX_NODE) --[[@as niNode]]
    -- check if the ref has a painting (reference.data.joyOfPainting.paintingTexture)
    if paintingTexture and switchPaintNode and paintTextureNode then
        logger:debug("Painting texture found for %s", self.id)
        -- set switch to paintNode
        local paintedNodeIndex = NodeManager.getIndex(switchPaintNode, NodeManager.nodes.PAINT_SWITCH_PAINTED)
        if paintedNodeIndex then
            switchPaintNode.switchIndex = paintedNodeIndex
            --set texture
            NodeManager.cloneTextureProperty(paintTextureNode)
            paintTextureNode.texturingProperty.baseMap.texture = paintingTexture
            paintTextureNode:update()
            paintTextureNode:updateProperties()
        else
            logger:warn("Painted node not found for %s", self.id)
        end
    else
        --remove paintingTexture data
        logger:warn("Painting texture not found for %s, clearing canvas", self.id)
        self:clearCanvas()
    end
end

function Painting:clearData()
    logger:debug("Clearing painting data")
    for _, field in ipairs(Painting.canvasFields) do
        self.data[field] = nil
    end
end

---Reset all data and remove painting nodes from the object
function Painting:resetCanvas()
    self:clearData()
    --Remove children from the attach_canvas node
    local attachNode = NodeManager.getCanvasAttachNode(self.reference.sceneNode)
    if attachNode then
        attachNode:detachChildAt(1)
        attachNode:update()
    end
end

function Painting:attachCanvas(item, itemData)
    if item then
        logger:trace("Attaching canvas %s", item.id)
        local isPainting = itemData and itemData.data.joyOfPainting
            and itemData.data.joyOfPainting.paintingTexture
        if isPainting then
            for _, field in ipairs(Painting.canvasFields) do
                self.data[field] = itemData.data.joyOfPainting[field]
            end
            if not self.data.paintingName then
                self.data.paintingName = item.name
            end
        else
            logger:trace("Canvas is blank")
            self.data.canvasId = item.id:lower()
        end
        if self:hasCanvasData() then
            self:doVisuals()
        end
    else
        logger:trace("No canvas selected")
    end
end

---Resets data and attaches a clean canvas
function Painting:cleanCanvas()
    logger:debug("Cleaning canvas")
    local canvasId = self.data.canvasId or self.reference.object.id
    self:resetCanvas()
    self.data.canvasId = canvasId
    local canvas = tes3.getObject(canvasId)
    self:attachCanvas(canvas)
end


function Painting:takeCanvas(e)
    e = e or { blockSound = false }
    local attachedId = self.data.paintingId or self.data.canvasId
    if not attachedId then
        logger:debug("No canvas to take")
        return
    end
    logger:debug("Taking canvas %s", attachedId)
    tes3.addItem{
        reference = tes3.player,
        item = attachedId,
        count = 1,
        playSound = not e.blockSound,
    }
    local itemData = tes3.addItemData{
        item = attachedId,
        to = tes3.player,
        updateGUI = true,
    }
    if self.data.paintingId then
        itemData.data.joyOfPainting = {}
        for _, field in ipairs(Painting.canvasFields) do
            itemData.data.joyOfPainting[field] = self.data[field]
        end
    end
    self:resetCanvas()
end

return Painting