local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local v2 = util.vector2

local CITY_TEX = "textures/icons/skyrim_compass/cities/"
local MARKER_SIZE = 28
local cityMarkers = {}

local cities = {
    { name = "Balmora",      x = -20480, y =  -16384, icon = "balmora" },
    { name = "Vivec",        x =  32768, y =  -81920, icon = "vivec" },
    { name = "Ald'ruhn",     x = -12288, y =   57344, icon = "aldruhn" },
    { name = "Sadrith Mora", x = 143360, y =   40960, icon = "sadrith_mora" },
    { name = "Gnisis",       x = -81920, y =   90112, icon = "gnisis" },
    { name = "Suran",        x =  53248, y =  -49152, icon = "suran" },
    { name = "Ebonheart",    x =  16384, y = -102400, icon = "ebonheart" },
    { name = "Tel Vos",      x =  86016, y =  118784, icon = "tel_vos" },
    { name = "Dagon Fel",    x =  61440, y =  184320, icon = "dagon_fel" },
    { name = "Caldera",      x = -12288, y =   20480, icon = "caldera" },
    { name = "Molag Mar",    x = 106496, y =  -61440, icon = "molag_mar" },
    { name = "Maar Gan",     x = -20480, y =  102400, icon = "maar_gan" },
    { name = "Hla Oad",      x = -45056, y =  -36864, icon = "hla_oad" },
    { name = "Pelagiad",     x =   4096, y =  -57344, icon = "pelagiad" },
    { name = "Ghostgate",    x =  20480, y =   36864, icon = "ghostgate" },
    { name = "Dagoth Ur",    x =  20480, y =   69632, icon = "dagoth_ur" },
}

local textures = {}
for _, city in ipairs(cities) do
    textures[city.icon] = ui.texture { path = CITY_TEX .. city.icon .. ".dds" }
end

local initialized = false

local function addCityMarkers(mapWidget)
    if not mapWidget then return end

    for _, city in ipairs(cities) do
        local markerId = "skyrim_compass_city_" .. city.icon

        local tooltipContent = ui.content {
            {
                type = ui.TYPE.Text,
                props = {
                    text = city.name,
                    textSize = 14,
                    textColor = util.color.rgb(0.9, 0.9, 0.9),
                    textAlignH = ui.ALIGNMENT.Center,
                },
            },
        }

        mapWidget:createImageMarker({
            layerId = mapWidget.LAYER.marker,
            id = markerId,
            pos = util.vector3(city.x, city.y, 0),
            texture = textures[city.icon],
            size = v2(MARKER_SIZE, MARKER_SIZE),
            anchor = v2(0.5, 0.5),
            alpha = 0.9,
            visible = true,
            tooltipContent = tooltipContent,
        })
    end
end

local function setupEvents()
    if initialized then return end
    if not I.AdvancedWorldMap then return end

    local events = I.AdvancedWorldMap.events

    events.registerHandler("onMapShown", function(e)
        if not e.cellId then
            addCityMarkers(e.mapWidget)
        end
    end)

    initialized = true
end

return {
    engineHandlers = {
        onFrame = function()
            if not initialized then
                setupEvents()
            end
        end,
    },
}
