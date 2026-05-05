local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local v2 = util.vector2

local CITY_TEX = "textures/icons/skyrim_compass/cities/"
local LOC_TEX = "textures/icons/skyrim_compass/"
local CITY_MARKER_SIZE = 56
local LOC_MARKER_SIZE = 25
local QUEST_MARKER_SIZE = 30

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

local locations = {
    -- Settlements
    { name = "Gnaar Mok",         x =  -61440, y =   28672, icon = "loc_settlement" },
    { name = "Khuul",             x =  -69632, y =  139264, icon = "loc_settlement" },
    { name = "Seyda Neen",        x =  -12288, y =  -73728, icon = "loc_settlement" },
    { name = "Vos",               x =   98304, y =  114688, icon = "loc_settlement" },
    { name = "Ald Velothi",       x =  -86016, y =  126976, icon = "loc_settlement" },
    { name = "Dren Plantation",   x =   20480, y =  -53248, icon = "loc_settlement" },
    { name = "Arvel Plantation",  x =   20480, y =  -45056, icon = "loc_settlement" },
    -- Ashlander Camps
    { name = "Ahemmusa Camp",     x =   94208, y =  135168, icon = "loc_settlement" },
    { name = "Erabenimsun Camp",  x =  110592, y =   -4096, icon = "loc_settlement" },
    { name = "Urshilaku Camp",    x =  -28672, y =  151552, icon = "loc_settlement" },
    { name = "Zainab Camp",       x =   77824, y =   86016, icon = "loc_settlement" },
    -- Telvanni Towers
    { name = "Tel Mora",          x =  110592, y =  118784, icon = "loc_diamond" },
    { name = "Tel Aruhn",         x =  126976, y =   45056, icon = "loc_diamond" },
    { name = "Tel Branora",       x =  122880, y = -102400, icon = "loc_diamond" },
    { name = "Tel Fyr",           x =  126976, y =   12288, icon = "loc_diamond" },
    { name = "Wolverine Hall",    x =  151552, y =   28672, icon = "loc_diamond" },
    -- Forts
    { name = "Buckmoth Legion Fort",  x = -12288, y =  45056, icon = "loc_diamond" },
    { name = "Moonmoth Legion Fort",  x =  -4096, y = -20480, icon = "loc_diamond" },
    { name = "Hlormaren",         x =  -45056, y =   -4096, icon = "loc_diamond" },
    { name = "Marandus",          x =   36864, y =  -20480, icon = "loc_diamond" },
    -- Dunmer Strongholds
    { name = "Andasreth",         x =  -69632, y =   45056, icon = "loc_diamond_hollow" },
    { name = "Berandas",          x =  -77824, y =   77824, icon = "loc_diamond_hollow" },
    { name = "Falensarano",       x =   77824, y =   53248, icon = "loc_diamond_hollow" },
    { name = "Telasero",          x =   77824, y =  -53248, icon = "loc_diamond_hollow" },
    { name = "Falasmaryon",       x =  -12288, y =  126976, icon = "loc_diamond_hollow" },
    { name = "Rotheran",          x =   53248, y =  151552, icon = "loc_diamond_hollow" },
    { name = "Valenvaryon",       x =   -4096, y =  151552, icon = "loc_diamond_hollow" },
    { name = "Kogoruhn",          x =    4096, y =  118784, icon = "loc_diamond_hollow" },
    { name = "Bal Isra",          x =  -36864, y =   77824, icon = "loc_diamond_hollow" },
    -- Daedric Ruins
    { name = "Ald Daedroth",      x =   94208, y =  167936, icon = "loc_diamond_hollow" },
    { name = "Ashalmawia",        x =  -77824, y =  126976, icon = "loc_diamond_hollow" },
    { name = "Ashurnabitashpi",   x =  -36864, y =  151552, icon = "loc_diamond_hollow" },
    { name = "Ashurnibibi",       x =  -53248, y =  -28672, icon = "loc_diamond_hollow" },
    { name = "Bal Fell",          x =   73728, y =  -94208, icon = "loc_diamond_hollow" },
    { name = "Yansirramus",       x =  102400, y =   36864, icon = "loc_diamond_hollow" },
    { name = "Zergonipal",        x =   45056, y =  126976, icon = "loc_diamond_hollow" },
    { name = "Zaintiraris",       x =  102400, y =  -77824, icon = "loc_diamond_hollow" },
    { name = "Ald Sotha",         x =   53248, y =  -69632, icon = "loc_diamond_hollow" },
    { name = "Tureynulal",        x =   36864, y =   77824, icon = "loc_diamond_hollow" },
    -- Dwemer Ruins
    { name = "Nchuleftingth",     x =   86016, y =  -20480, icon = "loc_diamond_hollow" },
    { name = "Nchuleft",          x =   69632, y =  102400, icon = "loc_diamond_hollow" },
    { name = "Nchurdamz",         x =  143360, y =  -45056, icon = "loc_diamond_hollow" },
    { name = "Mzahnch",           x =   69632, y =  -77824, icon = "loc_diamond_hollow" },
    { name = "Mzuleft",           x =   53248, y =  176128, icon = "loc_diamond_hollow" },
    { name = "Odrosal",           x =   28672, y =   61440, icon = "loc_diamond_hollow" },
    -- Temples & Shrines
    { name = "Holamayan",         x =  159744, y =  -28672, icon = "loc_temple" },
    { name = "Fields of Kummu",   x =   12288, y =  -36864, icon = "loc_temple" },
    { name = "Sanctus Shrine",    x =   12288, y =  176128, icon = "loc_temple" },
    { name = "Bal Ur",            x =   53248, y =  -36864, icon = "loc_temple" },
    -- Other
    { name = "Ald Redaynia",      x =  -28672, y =  176128, icon = "loc_diamond_hollow" },
    { name = "Mount Assarnibibi", x =  118784, y =  -28672, icon = "loc_diamond_hollow" },
    { name = "Mount Kand",        x =   94208, y =  -36864, icon = "loc_diamond_hollow" },
    { name = "Khartag Point",     x =  -69632, y =   36864, icon = "loc_cave" },
    { name = "Koal Cave",         x =  -86016, y =   77824, icon = "loc_cave" },
    { name = "Uvirith's Grave",   x =   86016, y =   12288, icon = "loc_diamond_hollow" },
    { name = "Vas",               x =    4096, y =  184320, icon = "loc_cave" },
}

local cityTextures = {}
for _, city in ipairs(cities) do
    cityTextures[city.icon] = ui.texture { path = CITY_TEX .. city.icon .. ".dds" }
end

local locTextures = {}
for _, loc in ipairs(locations) do
    if not locTextures[loc.icon] then
        locTextures[loc.icon] = ui.texture { path = LOC_TEX .. loc.icon .. ".dds" }
    end
end

local questMarkerTex = ui.texture { path = LOC_TEX .. "quest_marker.dds" }
local questDoorTex = ui.texture { path = LOC_TEX .. "quest_marker1.dds" }
local currentQuestMarkers = {}
local activeMapWidget = nil

local initialized = false

local function addStaticMarkers(mapWidget)
    if not mapWidget then return end

    for _, city in ipairs(cities) do
        local markerId = "skyrim_compass_city_" .. city.icon

        mapWidget:createImageMarker({
            layerId = mapWidget.LAYER.nonInteractive,
            id = markerId,
            pos = util.vector3(city.x, city.y, 0),
            texture = cityTextures[city.icon],
            size = v2(CITY_MARKER_SIZE, CITY_MARKER_SIZE),
            anchor = v2(0.5, 0.5),
            alpha = 0.9,
            visible = true,
            tooltipContent = ui.content {
                { type = ui.TYPE.Text, props = {
                    text = city.name,
                    textSize = 14,
                    textColor = util.color.rgb(0.9, 0.9, 0.9),
                    textAlignH = ui.ALIGNMENT.Center,
                }},
            },
        })
    end

    for _, loc in ipairs(locations) do
        local markerId = "skyrim_compass_loc_" .. loc.name:gsub("[' ]", "_")

        mapWidget:createImageMarker({
            layerId = mapWidget.LAYER.nonInteractive,
            id = markerId,
            pos = util.vector3(loc.x, loc.y, 0),
            texture = locTextures[loc.icon],
            size = v2(LOC_MARKER_SIZE, LOC_MARKER_SIZE),
            anchor = v2(0.5, 0.5),
            alpha = 0.75,
            visible = true,
            tooltipContent = ui.content {
                { type = ui.TYPE.Text, props = {
                    text = loc.name,
                    textSize = 12,
                    textColor = util.color.rgb(0.8, 0.8, 0.8),
                    textAlignH = ui.ALIGNMENT.Center,
                }},
            },
        })
    end
end

local function addQuestMarkers(mapWidget)
    if not mapWidget then return end

    for i, m in ipairs(currentQuestMarkers) do
        if m.x and not m.crossCell then
            local markerId = "skyrim_compass_quest_" .. i
            local tex = m.door and questDoorTex or questMarkerTex
            pcall(function()
                mapWidget:createImageMarker({
                    layerId = mapWidget.LAYER.marker,
                    id = markerId,
                    pos = util.vector3(m.x, m.y, m.z or 0),
                    texture = tex,
                    size = v2(QUEST_MARKER_SIZE, QUEST_MARKER_SIZE),
                    anchor = v2(0.5, 0.5),
                    alpha = 1.0,
                    visible = true,
                    tooltipContent = ui.content {
                        { type = ui.TYPE.Text, props = {
                            text = m.name or "Quest Target",
                            textSize = 12,
                            textColor = util.color.rgb(0.9, 0.9, 0.9),
                            textAlignH = ui.ALIGNMENT.Center,
                        }},
                    },
                })
            end)
        end
    end
end

local function setupEvents()
    if initialized then return end
    if not I.AdvancedWorldMap then return end

    local events = I.AdvancedWorldMap.events

    events.registerHandler("onMapShown", function(e)
        if not e.cellId then
            activeMapWidget = e.mapWidget
            addStaticMarkers(e.mapWidget)
            addQuestMarkers(e.mapWidget)
        end
    end)

    events.registerHandler("onMapClosed", function(e)
        activeMapWidget = nil
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
    eventHandlers = {
        ["SkyrimCompass:setMarkers"] = function(data)
            currentQuestMarkers = data or {}
            if activeMapWidget then
                addQuestMarkers(activeMapWidget)
            end
        end,
    },
}
