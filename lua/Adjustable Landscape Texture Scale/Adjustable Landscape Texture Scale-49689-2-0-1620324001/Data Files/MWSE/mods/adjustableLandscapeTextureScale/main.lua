--[[
    Adjustable Landscape Texture Scale
    By Greatness7
--]]

local config = mwse.loadConfig("adjustableLandscapeTextureScale", {
    scale = 1.6
})

local function toGrid(i, s)
    return (i % s), math.floor(i / s)
end

local function applyScaling()
    local root = tes3.game.worldLandscapeRoot

    for i, cell in ipairs(root.children) do
        local ay, ax = toGrid(i-1, 3)

        for i, chunk in ipairs(cell.children) do
            local bx, by = toGrid(i-1, 4)

            for i, shape in ipairs(chunk.children) do
                local cx, cy = toGrid(i-1, 4)

                for i, texCoord in ipairs(shape.data.texCoords) do
                    local dx, dy = toGrid(i-1, 5)

                    local x = (ax * 16.0) + (bx * 4.0) + (cx * 1.0) + (dx * 0.25)
                    local y = (ay * 16.0) + (by * 4.0) + (cy * 1.0) + (dy * 0.25)

                    texCoord.x = x * config.scale
                    texCoord.y = y * config.scale
                end

                shape.data:markAsChanged()
                shape:update()
            end
        end
    end

    mwse.log("[Adjustable Landscape Texture Scale] Applied Scaling: %.2f", config.scale)
end

local function onCellChanged(e)
    if e.cell.isInterior then return end
    applyScaling()
    -- runs only once, on the first exterior load
    event.unregister("cellChanged", onCellChanged)
end
event.register("cellChanged", onCellChanged)

local function onModConfigReady()
    local template = mwse.mcm.createTemplate({name="Landscape Texel Density Adjuster"})
    template:saveOnClose("adjustableLandscapeTextureScale", config)
    template:register()

    local page = template:createSideBarPage({})
    page.sidebar:createInfo({text="Landscape Texel Density Adjuster v2.0\n\nBy Greatness7"})

    page:createSlider({
        label = "Scale: %s%%",
        description = "Texel Density Scale. Higher values increase texel density.",
        min = 100,
        max = 400,
        step = 1,
        jump = 10,
        variable = mwse.mcm:createVariable{
            get = function(self)
                return math.round(config.scale * 100)
            end,
            set = function(self, value)
                config.scale = math.round(value / 100, 2)
            end,
        },
    })

    page:createButton({
        buttonText = "Update",
        callback = applyScaling,
    })
end
event.register("modConfigReady", onModConfigReady)
