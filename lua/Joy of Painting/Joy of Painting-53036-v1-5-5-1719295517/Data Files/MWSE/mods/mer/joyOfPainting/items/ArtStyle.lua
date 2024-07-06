local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("ArtStyle")
local Palette = require("mer.joyOfPainting.items.Palette")

---@class JOP.ArtStyle.shader
---@field id string The id of the shader
---@field shaderId string The id of the shader file
---@field defaultControls string[]? A list of control ids that are enabled by default when this shader is active

---@class JOP.ArtStyle.control
---@field id string The id of the control
---@field uniform string the name of the external variable in the shader being manipulated
---@field shader string The shader to use for this control
---@field name string The name of the control (shown in menu)
---@field sliderDefault number The default value for the slider
---@field sliderMin number? The minimum value for the slider
---@field sliderMax number? The maximum value for the slider
---@field shaderMin number? The minimum value for the shader variable
---@field shaderMax number? The maximum value for the shader variable
---@field defaultValue? number If set, this value will be reset when the photomenu is closed
---@field calculate? fun(skillLevel: number, artStyle: JOP.ArtStyle, canvas: JOP.Canvas): number A function that returns the value to be used for the shader variable

---@class JOP.ArtStyle.data
---@field name string The name of the art style
---@field shaders string[] A list of shaders to apply to the painting
---@field controls string[] A list of controls to use for this art style
---@field valueModifier number The value modifier for the painting
---@field animAlphaTexture string? The texture used to control the alpha during painting animation
---@field paintType string The type of palette to use for this art style
---@field requiresEasel boolean? Whether the art style requires an easel to be painted on
---@field maxDetailSkill number The skill level required to paint with maximum detail
---@field maxDistortSkill? number The skill level required to paint with minimum distortion
---@field minBrushSize? number The minimum detail level for this art style
---@field maxBrushSize? number The maximum detail level for this art style
---@field helpText? string The help text to display in the painting menu. This should explain how to get best results for this artstyle

---@class JOP.ArtStyle
---@field name string The name of the art style
---@field shaders JOP.ArtStyle.shader[] A list of shaders to apply to the painting
---@field controls string[] A list of controls to use for this art style
---@field valueModifier number The value modifier for the painting
---@field animAlphaTexture string The texture used to control the alpha during painting animation
---@field requiresEasel boolean? Whether the art style requires an easel to be painted on
---@field maxDetailSkill number The skill level required to paint with maximum detail
---@field maxDistortSkill? number The skill level required to paint with minimum distortion
---@field minBrushSize? number The minimum detail level for this art style
---@field maxBrushSize? number The maximum detail level for this art style
---@field paintType JOP.PaintType? The brush type to use for this art style
---@field brushType JOP.BrushType? The brush type to use for this art style
---@field helpText? string The help text to display in the painting menu. This should explain how to get best results for this artstyle
local ArtStyle = {
    classname = "ArtStyle"
}
ArtStyle.__index = ArtStyle

---@param e JOP.ArtStyle.data
function ArtStyle.registerArtStyle(e)
    logger:assert(type(e.name) == "string", "name must be a string")
    logger:assert(type(e.shaders) == "table", "shaders must be a table")
    logger:assert(type(e.valueModifier) == "number", "valueModifier must be a number")
    logger:debug("Registering art style %s", e.name)
    config.artStyles[e.name] = e
end

---@param e JOP.ArtStyle.control
function ArtStyle.registerControl(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:assert(type(e.shader) == "string", "shader must be a string")
    logger:assert(type(e.name) == "string", "name must be a string")
    logger:assert(type(e.sliderDefault) == "number", "sliderDefault must be a number")
    logger:debug("Registering control %s", e.id)
    config.controls[e.id] = table.copy(e, {})
end

---@param e JOP.ArtStyle.shader
function ArtStyle.registerShader(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:assert(type(e.shaderId) == "string", "shaderId must be a string")
    logger:debug("Registering shader %s", e.id)
    config.shaders[e.id] = e
end

---@param data JOP.ArtStyle.data
function ArtStyle:new(data)
    local artStyle = setmetatable(table.deepcopy(data), self)
    local shaders = data.shaders
    artStyle.shaders = {}
    for _, shader in ipairs(shaders) do
        logger:assert(config.shaders[shader] ~= nil, string.format("Shader %s not found", shader))
        table.insert(artStyle.shaders, config.shaders[shader])
    end
    artStyle.paintType = config.paintTypes[data.paintType]
    if artStyle.paintType.brushType then
        artStyle.brushType = config.brushTypes[artStyle.paintType.brushType]
    end
    return artStyle
end

function ArtStyle:isValidBrush(id)
    local brushData = config.brushes[id:lower()]
    if brushData then
       return brushData.brushType == self.brushType.id:lower()
    end
end

---@return table<string, JOP.Brush>
function ArtStyle:getBrushes()
    --iterate config.brushes and return those where this brush type is in its brushTypes list
    local brushes = {}
    for brushId, brushData in pairs(config.brushes) do
        if self:isValidBrush(brushId) then
            brushes[brushId] = brushData
        end
    end
    return brushes
end

function ArtStyle:playerHasBrush()
    logger:debug("Checking for %s brush", self.name)

    if not self.brushType then
        logger:debug("No brush required for this art style")
        return true
    end

    for _, brush in pairs(self:getBrushes()) do
        if tes3.player.object.inventory:contains(brush.id) then
            logger:debug("Found brush: %s", brush)
            return true
        end
    end
    --search area
    for _, cell in pairs(tes3.getActiveCells()) do
        for reference in cell:iterateReferences() do
            if self:getBrushes()[reference.object.id:lower()] and not common.isStack(reference) then
                if reference.position:distance(tes3.player.position) < tes3.getPlayerActivationDistance() then
                    logger:debug("Found nearby brush reference: %s", reference.object.id)
                    return true
                end
            end
        end
    end

    return false
end

function ArtStyle:isValidPaint(id)
    local paletteItem = config.paletteItems[id:lower()]
    if paletteItem then
        return paletteItem.paintType == self.paintType.id
    end
end

---@return table<string, JOP.PaletteItem>
function ArtStyle:getPalettes()
    local palettes = {}
    for paletteId, paletteItem in pairs(config.paletteItems) do
        if self:isValidPaint(paletteId) then
            palettes[paletteId] = paletteItem
        end
    end
    return palettes
end

function ArtStyle:playerHasPaint()
    logger:debug("Checking playerHasPaint for %s", self.name)
    if not self.paintType then
        logger:debug("No palette required for this art style")
        return true
    end
    --Search inventory
    for paletteId, paletteItem in pairs(self:getPalettes()) do
        logger:debug("Checking palette: %s", paletteId)
        local itemStack = tes3.player.object.inventory:findItemStack(paletteId)
        if itemStack then
            logger:debug("Found palette: %s", paletteId)
            --if no variables, then treat it as full if fullByDefault
            if paletteItem.fullByDefault then
                local numVariables = itemStack.variables and #itemStack.variables or 0
                if itemStack.count > numVariables then
                    logger:debug("stack count greater than variabels, has at least one full")
                    return true
                end
            end

            if itemStack.variables then
                for _, itemData in ipairs(itemStack.variables) do
                    local palette = Palette:new{
                        item = itemStack.object,
                        itemData = itemData
                    }
                    if palette then
                        local remaining = palette:getRemainingUses()
                        if remaining > 0 then
                            logger:debug("%d uses remaining", remaining)
                            return true
                        end
                    end
                end
            end
        end
    end
    --Search nearby area
    for _, cell in pairs(tes3.getActiveCells()) do
        for reference in cell:iterateReferences() do
            if self:isValidPaint(reference.object.id) and not common.isStack(reference) then
                if common.closeEnough(reference) then
                    local palette = Palette:new({
                        reference = reference
                    })
                    if palette and palette:getRemainingUses() > 0 then
                        logger:debug("Found nearby palette reference: %s", reference.object.id)
                        return true
                    end
                end
            end
        end
    end
    return false
end


function ArtStyle:usePaint()
    logger:debug("Using up palette for %s", self.name)
    ---@type JOP.Palette.params[]
    local usedStacks = {}
    ---@type JOP.Palette.params[]
    local newStacks = {}

    for paletteId, paletteItem in pairs(self:getPalettes()) do
        local itemStack = tes3.player.object.inventory:findItemStack(paletteId)
        if itemStack then
            if itemStack.variables then
                for _, itemData in ipairs(itemStack.variables) do
                    if itemData.data.joyOfPainting then
                        table.insert(usedStacks, {
                            paletteItem = paletteItem,
                            item = itemStack.object,
                            itemData = itemData
                        })
                    else
                        table.insert(newStacks, {
                            paletteItem = paletteItem,
                            item = itemStack.object,
                            itemData = itemData
                        })
                    end
                end
            else
                table.insert(newStacks, {
                    paletteItem = paletteItem,
                    item = itemStack.object
                })
            end
        end
    end
    --prioritise used stacks
    for _, stackData in ipairs(usedStacks) do
        local palette = Palette:new(stackData)
        if palette and palette:use() then
            return
        end
    end
    --then new stacks
    for _, stackData in ipairs(newStacks) do
        local palette = Palette:new(stackData)
        if palette and palette:use() then
            return
        end
    end
    --then nearby reference
    for _, cell in pairs(tes3.getActiveCells()) do
        for reference in cell:iterateReferences() do
            if self:isValidPaint(reference.object.id) and not common.isStack(reference) then
                if common.closeEnough(reference) then
                    logger:debug("Found nearby palette reference: %s", reference.object.id)
                    local palette = Palette:new({
                        item = reference.object,
                        reference = reference
                    })

                    if palette and palette:use() then
                        return
                    end
                end
            end
        end
    end

    logger:warn("No palette found to use")
end

function ArtStyle:getButton(callback)
    return {
        text = self.name,
        callback = callback,
        enableRequirements = function()
            return self:playerHasBrush() and self:playerHasPaint()
        end,
        tooltipDisabled = function()
            local text
            local hasBrush = self:playerHasBrush()
            local hasPaint = self:playerHasPaint()
            if not hasBrush and not hasPaint then
                text = string.format("Requires %s and %s", self.brushType.name, self.paintType.name)
            elseif not hasBrush then
                text = string.format("Requires %s", self.brushType.name)
            elseif not hasPaint then
                text = string.format("Requires %s", self.paintType.name)
            end
            return { text = text }
        end
    }
end

return ArtStyle