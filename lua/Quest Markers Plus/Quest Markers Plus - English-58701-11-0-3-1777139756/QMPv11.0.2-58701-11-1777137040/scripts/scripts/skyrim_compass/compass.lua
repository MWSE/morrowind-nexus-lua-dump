local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local self = require('openmw.self')
local camera = require('openmw.camera')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local input = require('openmw.input')
local v2 = util.vector2

local settings = storage.playerSection("SkyrimCompass_Settings")
local questColorSettings = storage.playerSection("SkyrimCompass_QuestColor")
local iconColorSettings = storage.playerSection("SkyrimCompass_IconColor")

local BASE_WIDTH = 600
local BASE_HEIGHT = 40
local COMPASS_MARGIN = 10
local BASE_QUEST_SIZE = 33
local BASE_CITY_SIZE = 41
local BASE_CARDINAL_SIZE = 14
local FOV_RANGE = math.pi * 0.6
local FRAME_INTERVAL = 0.016
local CITY_SHOW_DIST = 40000
local CITY_HIDE_DIST = 5000
local LOC_SHOW_DIST = 25000
local LOC_HIDE_DIST = 1000
local BASE_LOC_SIZE = 24
local BORDER = 2

local compassElement = nil
local markerElements = {}
local cityLabelElement = nil
local lastUpdate = 0
local trackedMarkers = {}
local interiorDoors = {}
local crossCellActive = false
local lastRequestedCell = nil
local lastScale = nil

local toggleNotifElement = nil
local toggleNotifTimer = 0
local TOGGLE_NOTIF_DURATION = 2.0

local function isCompassEnabled()
    local v = settings:get("compassEnabled")
    if v == nil then return true end
    return v
end

local function hideAll()
    if compassElement then
        compassElement.layout.props.visible = false
        compassElement:update()
    end
    if cityLabelElement then
        cityLabelElement.layout.props.visible = false
        cityLabelElement:update()
    end
    for _, el in pairs(markerElements) do
        if el then
            el.layout.props.visible = false
            el:update()
        end
    end
end

local TEX = "textures/icons/skyrim_compass/"
local CITY_TEX = TEX .. "cities/"
local questMarkerTex = ui.texture { path = TEX .. "quest_marker.dds" }
local questDoorTex   = ui.texture { path = TEX .. "quest_door.dds" }
local compassBarTex  = ui.texture { path = TEX .. "compass_bar.dds" }
local notchTex       = ui.texture { path = TEX .. "notch.dds" }
local barWhiteTex    = ui.texture { path = TEX .. "bar_white.dds" }

local locSettlementTex    = ui.texture { path = TEX .. "loc_settlement.dds" }
local locDiamondTex       = ui.texture { path = TEX .. "loc_diamond.dds" }
local locDiamondHollowTex = ui.texture { path = TEX .. "loc_diamond_hollow.dds" }
local locTempleTex        = ui.texture { path = TEX .. "loc_temple.dds" }
local locCaveTex          = ui.texture { path = TEX .. "loc_cave.dds" }

local borderTopTex    = ui.texture { path = 'textures/menu_thin_border_top.dds' }
local borderBottomTex = ui.texture { path = 'textures/menu_thin_border_bottom.dds' }
local borderLeftTex   = ui.texture { path = 'textures/menu_thin_border_left.dds' }
local borderRightTex  = ui.texture { path = 'textures/menu_thin_border_right.dds' }
local borderTLTex     = ui.texture { path = 'textures/menu_thin_border_top_left_corner.dds' }
local borderTRTex     = ui.texture { path = 'textures/menu_thin_border_top_right_corner.dds' }
local borderBLTex     = ui.texture { path = 'textures/menu_thin_border_bottom_left_corner.dds' }
local borderBRTex     = ui.texture { path = 'textures/menu_thin_border_bottom_right_corner.dds' }

local function getScale()
    return (settings:get("compassScale") or 100) / 100
end

local function hsvToColor(h, s, v)
    h = (h % 360) / 360
    s = s / 100
    v = v / 100
    if s == 0 then return util.color.rgb(v, v, v) end
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return util.color.rgb(v, t, p)
    elseif i == 1 then return util.color.rgb(q, v, p)
    elseif i == 2 then return util.color.rgb(p, v, t)
    elseif i == 3 then return util.color.rgb(p, q, v)
    elseif i == 4 then return util.color.rgb(t, p, v)
    else return util.color.rgb(v, p, q) end
end

local function getQuestColor()
    return hsvToColor(
        questColorSettings:get("questHue") or 0,
        questColorSettings:get("questSaturation") or 0,
        questColorSettings:get("questBrightness") or 100
    )
end

local function getIconColor()
    return hsvToColor(
        iconColorSettings:get("iconHue") or 0,
        iconColorSettings:get("iconSaturation") or 0,
        iconColorSettings:get("iconBrightness") or 100
    )
end

local function getIconColorDim()
    return hsvToColor(
        iconColorSettings:get("iconHue") or 0,
        iconColorSettings:get("iconSaturation") or 0,
        (iconColorSettings:get("iconBrightness") or 100) * 0.65
    )
end

local cities = {
    { name = "Balmora",      x = -20480, y =  -16384, icon = ui.texture { path = CITY_TEX .. "balmora.dds" } },
    { name = "Vivec",        x =  32768, y =  -81920, icon = ui.texture { path = CITY_TEX .. "vivec.dds" } },
    { name = "Ald'ruhn",     x = -12288, y =   57344, icon = ui.texture { path = CITY_TEX .. "aldruhn.dds" } },
    { name = "Sadrith Mora", x = 143360, y =   40960, icon = ui.texture { path = CITY_TEX .. "sadrith_mora.dds" } },
    { name = "Gnisis",       x = -81920, y =   90112, icon = ui.texture { path = CITY_TEX .. "gnisis.dds" } },
    { name = "Suran",        x =  53248, y =  -49152, icon = ui.texture { path = CITY_TEX .. "suran.dds" } },
    { name = "Ebonheart",    x =  16384, y = -102400, icon = ui.texture { path = CITY_TEX .. "ebonheart.dds" } },
    { name = "Tel Vos",      x =  86016, y =  118784, icon = ui.texture { path = CITY_TEX .. "tel_vos.dds" } },
    { name = "Dagon Fel",    x =  61440, y =  184320, icon = ui.texture { path = CITY_TEX .. "dagon_fel.dds" } },
    { name = "Caldera",      x = -12288, y =   20480, icon = ui.texture { path = CITY_TEX .. "caldera.dds" } },
    { name = "Molag Mar",    x = 106496, y =  -61440, icon = ui.texture { path = CITY_TEX .. "molag_mar.dds" } },
    { name = "Maar Gan",     x = -20480, y =  102400, icon = ui.texture { path = CITY_TEX .. "maar_gan.dds" } },
    { name = "Hla Oad",      x = -45056, y =  -36864, icon = ui.texture { path = CITY_TEX .. "hla_oad.dds" } },
    { name = "Pelagiad",     x =   4096, y =  -57344, icon = ui.texture { path = CITY_TEX .. "pelagiad.dds" } },
    { name = "Ghostgate",    x =  20480, y =   36864, icon = ui.texture { path = CITY_TEX .. "ghostgate.dds" } },
    { name = "Dagoth Ur",    x =  20480, y =   69632, icon = ui.texture { path = CITY_TEX .. "dagoth_ur.dds" } },
}

local locations = {
    { name = "Gnaar Mok",         x =  -61440, y =   28672, icon = locSettlementTex },
    { name = "Khuul",             x =  -69632, y =  139264, icon = locSettlementTex },
    { name = "Seyda Neen",        x =  -12288, y =  -73728, icon = locSettlementTex },
    { name = "Vos",               x =   98304, y =  114688, icon = locSettlementTex },
    { name = "Ald Velothi",       x =  -86016, y =  126976, icon = locSettlementTex },
    { name = "Dren Plantation",   x =   20480, y =  -53248, icon = locSettlementTex },
    { name = "Arvel Plantation",  x =   20480, y =  -45056, icon = locSettlementTex },
    { name = "Ahemmusa Camp",     x =   94208, y =  135168, icon = locSettlementTex },
    { name = "Erabenimsun Camp",  x =  110592, y =   -4096, icon = locSettlementTex },
    { name = "Urshilaku Camp",    x =  -28672, y =  151552, icon = locSettlementTex },
    { name = "Zainab Camp",       x =   77824, y =   86016, icon = locSettlementTex },
    { name = "Tel Mora",          x =  110592, y =  118784, icon = locDiamondTex },
    { name = "Tel Aruhn",         x =  126976, y =   45056, icon = locDiamondTex },
    { name = "Tel Branora",       x =  122880, y = -102400, icon = locDiamondTex },
    { name = "Tel Fyr",           x =  126976, y =   12288, icon = locDiamondTex },
    { name = "Wolverine Hall",    x =  151552, y =   28672, icon = locDiamondTex },
    { name = "Buckmoth Legion Fort",  x = -12288, y =  45056, icon = locDiamondTex },
    { name = "Moonmoth Legion Fort",  x =  -4096, y = -20480, icon = locDiamondTex },
    { name = "Hlormaren",         x =  -45056, y =   -4096, icon = locDiamondTex },
    { name = "Marandus",          x =   36864, y =  -20480, icon = locDiamondTex },
    { name = "Andasreth",         x =  -69632, y =   45056, icon = locDiamondHollowTex },
    { name = "Berandas",          x =  -77824, y =   77824, icon = locDiamondHollowTex },
    { name = "Falensarano",       x =   77824, y =   53248, icon = locDiamondHollowTex },
    { name = "Telasero",          x =   77824, y =  -53248, icon = locDiamondHollowTex },
    { name = "Falasmaryon",       x =  -12288, y =  126976, icon = locDiamondHollowTex },
    { name = "Rotheran",          x =   53248, y =  151552, icon = locDiamondHollowTex },
    { name = "Valenvaryon",       x =   -4096, y =  151552, icon = locDiamondHollowTex },
    { name = "Kogoruhn",          x =    4096, y =  118784, icon = locDiamondHollowTex },
    { name = "Bal Isra",          x =  -36864, y =   77824, icon = locDiamondHollowTex },
    { name = "Ald Daedroth",      x =   94208, y =  167936, icon = locDiamondHollowTex },
    { name = "Ashalmawia",        x =  -77824, y =  126976, icon = locDiamondHollowTex },
    { name = "Ashurnabitashpi",   x =  -36864, y =  151552, icon = locDiamondHollowTex },
    { name = "Ashurnibibi",       x =  -53248, y =  -28672, icon = locDiamondHollowTex },
    { name = "Bal Fell",          x =   73728, y =  -94208, icon = locDiamondHollowTex },
    { name = "Yansirramus",       x =  102400, y =   36864, icon = locDiamondHollowTex },
    { name = "Zergonipal",        x =   45056, y =  126976, icon = locDiamondHollowTex },
    { name = "Zaintiraris",       x =  102400, y =  -77824, icon = locDiamondHollowTex },
    { name = "Ald Sotha",         x =   53248, y =  -69632, icon = locDiamondHollowTex },
    { name = "Tureynulal",        x =   36864, y =   77824, icon = locDiamondHollowTex },
    { name = "Nchuleftingth",     x =   86016, y =  -20480, icon = locDiamondHollowTex },
    { name = "Nchuleft",          x =   69632, y =  102400, icon = locDiamondHollowTex },
    { name = "Nchurdamz",         x =  143360, y =  -45056, icon = locDiamondHollowTex },
    { name = "Mzahnch",           x =   69632, y =  -77824, icon = locDiamondHollowTex },
    { name = "Mzuleft",           x =   53248, y =  176128, icon = locDiamondHollowTex },
    { name = "Odrosal",           x =   28672, y =   61440, icon = locDiamondHollowTex },
    { name = "Holamayan",         x =  159744, y =  -28672, icon = locTempleTex },
    { name = "Fields of Kummu",   x =   12288, y =  -36864, icon = locTempleTex },
    { name = "Sanctus Shrine",    x =   12288, y =  176128, icon = locTempleTex },
    { name = "Bal Ur",            x =   53248, y =  -36864, icon = locTempleTex },
    { name = "Ald Redaynia",      x =  -28672, y =  176128, icon = locDiamondHollowTex },
    { name = "Mount Assarnibibi", x =  118784, y =  -28672, icon = locDiamondHollowTex },
    { name = "Mount Kand",        x =   94208, y =  -36864, icon = locDiamondHollowTex },
    { name = "Khartag Point",     x =  -69632, y =   36864, icon = locCaveTex },
    { name = "Koal Cave",         x =  -86016, y =   77824, icon = locCaveTex },
    { name = "Uvirith's Grave",   x =   86016, y =   12288, icon = locDiamondHollowTex },
    { name = "Vas",               x =    4096, y =  184320, icon = locCaveTex },
}

local cardinals = {
    { label = "N",  angle = 0,                  major = true },
    { label = "NE", angle = math.pi / 4,        major = false },
    { label = "E",  angle = math.pi / 2,        major = true },
    { label = "SE", angle = math.pi * 3 / 4,    major = false },
    { label = "S",  angle = math.pi,            major = true },
    { label = "SW", angle = -math.pi * 3 / 4,   major = false },
    { label = "W",  angle = -math.pi / 2,       major = true },
    { label = "NW", angle = -math.pi / 4,       major = false },
}

local subNotches = {}
for i = 0, 15 do
    local a = -math.pi + i * math.pi / 8
    local skip = false
    for _, c in ipairs(cardinals) do
        if math.abs(util.normalizeAngle(a - c.angle)) < 0.01 then skip = true; break end
    end
    if not skip then table.insert(subNotches, a) end
end

local function getScreenSize()
    local layerId = ui.layers.indexOf("HUD")
    local w = ui.layers[layerId].size.x
    local ss = ui.screenSize()
    local scale = ss.x / w
    return ss:ediv(v2(scale, scale))
end

local function getCompassY(ss)
    local ch = BASE_HEIGHT * getScale()
    if settings:get("compassBottom") then
        return ss.y - ch - COMPASS_MARGIN
    else
        return COMPASS_MARGIN
    end
end

local function angleToX(angle, screenW)
    local cw = BASE_WIDTH * getScale()
    local n = util.normalizeAngle(angle)
    local f = n / FOV_RANGE
    if math.abs(f) > 1 then return nil end
    return (screenW - cw) / 2 + cw / 2 + f * (cw / 2)
end

local function getYaw()
    local fwd = camera.viewportToWorldVector(v2(0.5, 0.5))
    return math.atan2(fwd.x, fwd.y)
end

local function destroyAll()
    if compassElement then compassElement:destroy(); compassElement = nil end
    if cityLabelElement then cityLabelElement:destroy(); cityLabelElement = nil end
    for _, el in pairs(markerElements) do
        if el then el:destroy() end
    end
    markerElements = {}
end

local function buildCompass()
    if compassElement then compassElement:destroy() end
    local scale = getScale()
    local cw = BASE_WIDTH * scale
    local ch = BASE_HEIGHT * scale
    local ss = getScreenSize()
    local compassX = (ss.x - cw) / 2
    local compassY = getCompassY(ss)
    compassElement = ui.create({
        layer = "HUD",
        type = ui.TYPE.Widget,
        props = {
            position = v2(compassX, compassY),
            size = v2(cw, ch),
            visible = true,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    position = v2(0, 0),
                    size = v2(cw, ch),
                    resource = barWhiteTex,
                    color = util.color.rgb(0, 0, 0),
                    alpha = (settings:get("compassAlpha") or 30) * 0.01,
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    position = v2(0, 0),
                    size = v2(cw, ch),
                    resource = compassBarTex,
                    tileH = false, tileV = false,
                },
            },
            { type = ui.TYPE.Image, props = {
                resource = borderTopTex, tileH = true, tileV = false,
                relativePosition = v2(0, 0), position = v2(BORDER * 2, 0),
                relativeSize    = v2(1, 0), size     = v2(-BORDER * 4, BORDER),
            }},
            { type = ui.TYPE.Image, props = {
                resource = borderBottomTex, tileH = true, tileV = false,
                relativePosition = v2(0, 1), position = v2(BORDER * 2, -BORDER),
                relativeSize    = v2(1, 0), size     = v2(-BORDER * 4, BORDER),
            }},
            { type = ui.TYPE.Image, props = {
                resource = borderLeftTex, tileH = false, tileV = true,
                relativePosition = v2(0, 0), position = v2(0, BORDER * 2),
                relativeSize    = v2(0, 1), size     = v2(BORDER, -BORDER * 4),
            }},
            { type = ui.TYPE.Image, props = {
                resource = borderRightTex, tileH = false, tileV = true,
                relativePosition = v2(1, 0), position = v2(-BORDER, BORDER * 2),
                relativeSize    = v2(0, 1), size     = v2(BORDER, -BORDER * 4),
            }},
            { type = ui.TYPE.Image, props = {
                resource = borderTLTex,
                relativePosition = v2(0, 0), position = v2(0, 0),
                size = v2(BORDER * 2, BORDER * 2),
            }},
            { type = ui.TYPE.Image, props = {
                resource = borderTRTex,
                relativePosition = v2(1, 0), position = v2(-BORDER * 2, 0),
                size = v2(BORDER * 2, BORDER * 2),
            }},
            { type = ui.TYPE.Image, props = {
                resource = borderBLTex,
                relativePosition = v2(0, 1), position = v2(0, -BORDER * 2),
                size = v2(BORDER * 2, BORDER * 2),
            }},
            { type = ui.TYPE.Image, props = {
                resource = borderBRTex,
                relativePosition = v2(1, 1), position = v2(-BORDER * 2, -BORDER * 2),
                size = v2(BORDER * 2, BORDER * 2),
            }},
        },
    })
end

local function updateCompass()
    if not compassElement then return end

    local scale = getScale()
    local cw = BASE_WIDTH * scale
    local ch = BASE_HEIGHT * scale
    local qs = math.floor(BASE_QUEST_SIZE * scale)
    local cs = math.floor(BASE_CITY_SIZE * scale)
    local cardSize = math.floor(BASE_CARDINAL_SIZE * scale)
    local iconClr = getIconColor()
    local iconClrDim = getIconColorDim()
    local questClr = getQuestColor()

    local ss = getScreenSize()
    local compassY = getCompassY(ss)
    local compassX = (ss.x - cw) / 2
    local compassR = compassX + cw
    local yaw = getYaw()
    local pPos = self.position
    local cY = compassY + ch / 2
    local active = {}

    local function clampX(centerX, markerW)
        return math.max(compassX, math.min(compassR - markerW, centerX - markerW / 2))
    end

    compassElement.layout.props.position = v2(compassX, compassY)

    -- Cardinal directions
    for _, c in ipairs(cardinals) do
        local diff = util.normalizeAngle(c.angle - yaw)
        local x = angleToX(diff, ss.x)
        local k = "c_" .. c.label
        local tw = math.floor(40 * scale)
        local th = math.floor(30 * scale)
        if x then
            local clr = c.major and iconClr or iconClrDim
            if not markerElements[k] then
                markerElements[k] = ui.create({
                    layer = "HUD",
                    type = ui.TYPE.Widget,
                    props = { position = v2(0,0), size = v2(tw, th), visible = true },
                    content = ui.content {
                        { type = ui.TYPE.Text, props = {
                            text = c.label,
                            textSize = c.major and cardSize or cardSize - 2,
                            textColor = clr,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                            textShadow = true, textShadowColor = util.color.rgb(0,0,0),
                            position = v2(0,0), size = v2(tw, th),
                        }},
                    },
                })
            end
            markerElements[k].layout.props.position = v2(clampX(x, tw), cY - th / 2)
            markerElements[k].layout.content[1].props.textColor = clr
            markerElements[k].layout.props.visible = true
            markerElements[k]:update()
            active[k] = true
        elseif markerElements[k] then
            markerElements[k].layout.props.visible = false
            markerElements[k]:update()
        end
    end

    -- Sub-notches
    for _, sa in ipairs(subNotches) do
        local diff = util.normalizeAngle(sa - yaw)
        local x = angleToX(diff, ss.x)
        local k = "n_" .. string.format("%.3f", sa)
        local nw = math.max(2, math.floor(2 * scale))
        local nh = math.floor(10 * scale)
        if x then
            if not markerElements[k] then
                markerElements[k] = ui.create({
                    layer = "HUD",
                    type = ui.TYPE.Widget,
                    props = { position = v2(0,0), size = v2(nw, nh), visible = true },
                    content = ui.content {
                        { type = ui.TYPE.Image, props = {
                            resource = notchTex, size = v2(nw, nh), alpha = 0.4,
                            color = iconClr,
                        }},
                    },
                })
            end
            markerElements[k].layout.props.position = v2(clampX(x, nw), cY - nh / 2)
            markerElements[k].layout.content[1].props.color = iconClr
            markerElements[k].layout.props.visible = true
            markerElements[k]:update()
            active[k] = true
        elseif markerElements[k] then
            markerElements[k].layout.props.visible = false
            markerElements[k]:update()
        end
    end

    -- City / location markers
    local centeredCity = nil
    local centeredCityAlpha = 0
    local CENTER_THRESHOLD = 0.06
    local isInterior = not self.cell.isExterior

    for _, city in ipairs(cities) do
        local k = "city_" .. city.name

        if isInterior then
            if markerElements[k] then
                markerElements[k].layout.props.visible = false
                markerElements[k]:update()
            end
            goto nextCity
        end

        local dx = city.x - pPos.x
        local dy = city.y - pPos.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > CITY_SHOW_DIST or dist < CITY_HIDE_DIST then
            if markerElements[k] then
                markerElements[k].layout.props.visible = false
                markerElements[k]:update()
            end
            goto nextCity
        end

        local mAngle = math.atan2(dx, dy)
        local diff = util.normalizeAngle(mAngle - yaw)
        local x = angleToX(diff, ss.x)

        if x then
            local alpha = 1.0
            if dist > CITY_SHOW_DIST * 0.7 then
                alpha = math.max(0.25, 1.0 - (dist - CITY_SHOW_DIST * 0.7) / (CITY_SHOW_DIST * 0.3))
            end

            if not markerElements[k] then
                markerElements[k] = ui.create({
                    layer = "HUD",
                    type = ui.TYPE.Widget,
                    props = { position = v2(0,0), size = v2(cs, cs), visible = true },
                    content = ui.content {
                        { type = ui.TYPE.Image, props = {
                            resource = city.icon,
                            size = v2(cs, cs),
                            alpha = alpha,
                            color = iconClr,
                        }},
                    },
                })
            end
            markerElements[k].layout.props.position = v2(clampX(x, cs), cY - cs / 2)
            markerElements[k].layout.props.visible = true
            markerElements[k].layout.content[1].props.alpha = alpha
            markerElements[k].layout.content[1].props.color = iconClr
            markerElements[k]:update()
            active[k] = true

            local absDiff = math.abs(diff)
            if absDiff < CENTER_THRESHOLD then
                local labelAlpha = alpha * (1 - absDiff / CENTER_THRESHOLD)
                if not centeredCity or labelAlpha > centeredCityAlpha then
                    centeredCity = city.name
                    centeredCityAlpha = labelAlpha
                end
            end
        elseif markerElements[k] then
            markerElements[k].layout.props.visible = false
            markerElements[k]:update()
        end

        ::nextCity::
    end

    -- City name label (above or below the compass depending on position setting)
    local labelY
    local labelH = math.floor(20 * scale)
    if settings:get("compassBottom") then
        labelY = compassY - labelH - 2
    else
        labelY = compassY + ch + 2
    end

    if centeredCity and settings:get("showCityNames") ~= false then
        local labelSize = math.floor(13 * scale)
        if not cityLabelElement then
            cityLabelElement = ui.create({
                layer = "HUD",
                type = ui.TYPE.Flex,
                props = {
                    position = v2(compassX, labelY),
                    size = v2(cw, labelH),
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                    visible = true,
                },
                content = ui.content {
                    { type = ui.TYPE.Text, props = {
                        text = centeredCity,
                        textSize = labelSize,
                        textColor = util.color.rgb(0.88, 0.88, 0.88),
                        textShadow = true,
                        textShadowColor = util.color.rgb(0, 0, 0),
                    }},
                },
            })
        end
        cityLabelElement.layout.props.position = v2(compassX, labelY)
        cityLabelElement.layout.props.size = v2(cw, labelH)
        cityLabelElement.layout.content[1].props.text = centeredCity
        cityLabelElement.layout.props.alpha = centeredCityAlpha
        cityLabelElement.layout.props.visible = true
        cityLabelElement:update()
    elseif cityLabelElement then
        cityLabelElement.layout.props.visible = false
        cityLabelElement:update()
    end

    -- Location markers
    local ls = math.floor(BASE_LOC_SIZE * scale)
    for _, loc in ipairs(locations) do
        local k = "loc_" .. loc.name

        if isInterior then
            if markerElements[k] then
                markerElements[k].layout.props.visible = false
                markerElements[k]:update()
            end
            goto nextLoc
        end

        do
            local dx = loc.x - pPos.x
            local dy = loc.y - pPos.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > LOC_SHOW_DIST or dist < LOC_HIDE_DIST then
                if markerElements[k] then
                    markerElements[k].layout.props.visible = false
                    markerElements[k]:update()
                end
                goto nextLoc
            end

            local mAngle = math.atan2(dx, dy)
            local diff = util.normalizeAngle(mAngle - yaw)
            local x = angleToX(diff, ss.x)

            if x then
                local alpha = 1.0
                if dist > LOC_SHOW_DIST * 0.7 then
                    alpha = math.max(0.25, 1.0 - (dist - LOC_SHOW_DIST * 0.7) / (LOC_SHOW_DIST * 0.3))
                end

                if not markerElements[k] then
                    markerElements[k] = ui.create({
                        layer = "HUD",
                        type = ui.TYPE.Widget,
                        props = { position = v2(0,0), size = v2(ls, ls), visible = true },
                        content = ui.content {
                            { type = ui.TYPE.Image, props = {
                                resource = loc.icon,
                                size = v2(ls, ls),
                                alpha = alpha,
                                color = iconClr,
                            }},
                        },
                    })
                end
                markerElements[k].layout.props.position = v2(clampX(x, ls), cY - ls / 2)
                markerElements[k].layout.props.visible = true
                markerElements[k].layout.content[1].props.alpha = alpha
                markerElements[k].layout.content[1].props.color = iconClr
                markerElements[k]:update()
                active[k] = true
            elseif markerElements[k] then
                markerElements[k].layout.props.visible = false
                markerElements[k]:update()
            end
        end

        ::nextLoc::
    end

    -- Request exit door positions when tracking cross-cell indoors
    if isInterior and crossCellActive then
        local cellId = self.cell.id
        if cellId ~= lastRequestedCell then
            lastRequestedCell = cellId
            interiorDoors = {}
            core.sendGlobalEvent("SkyrimCompass:findExitDoors", {
                cellId = cellId,
                player = self.object,
            })
        end
    else
        if crossCellActive then crossCellActive = false end
        if #interiorDoors > 0 then interiorDoors = {} end
        lastRequestedCell = nil
    end

    local useInteriorDoors = isInterior and crossCellActive and #interiorDoors > 0

    -- Quest markers (outdoor: from ProximityTool, indoor: from QGL door tracking)
    if useInteriorDoors then
        for i, doorData in ipairs(interiorDoors) do
            local k = "q_" .. i
            local mAlpha = (settings:get("markerAlpha") or 100) * 0.01
            local markerY = cY - qs / 2

            if not markerElements[k] then
                markerElements[k] = ui.create({
                    layer = "HUD",
                    type = ui.TYPE.Widget,
                    props = { position = v2(0,0), size = v2(qs, qs), visible = true },
                    content = ui.content {
                        { type = ui.TYPE.Image, props = {
                            resource = questDoorTex,
                            size = v2(qs, qs),
                            alpha = mAlpha,
                            color = questClr,
                        }},
                    },
                })
            else
                markerElements[k].layout.content[1].props.resource = questDoorTex
            end

            local ddx = doorData.x - pPos.x
            local ddy = doorData.y - pPos.y
            local mAngle = math.atan2(ddx, ddy)
            local ddiff = util.normalizeAngle(mAngle - yaw)
            local mx = angleToX(ddiff, ss.x)

            markerElements[k].layout.content[1].props.color = questClr
            if mx then
                markerElements[k].layout.props.position = v2(clampX(mx, qs), markerY)
                markerElements[k].layout.content[1].props.alpha = mAlpha
            else
                local edgeX
                if ddiff > 0 then
                    edgeX = (ss.x + cw) / 2 - qs / 2
                else
                    edgeX = (ss.x - cw) / 2 - qs / 2
                end
                markerElements[k].layout.props.position = v2(edgeX, markerY)
                markerElements[k].layout.content[1].props.alpha = 0.3
            end
            markerElements[k].layout.props.visible = true
            markerElements[k]:update()
            active[k] = true
        end
    else
        for i, m in ipairs(trackedMarkers) do
            local k = "q_" .. i
            if not m.x then goto skip end

            local icon = m.door and questDoorTex or questMarkerTex
            local mAlpha = (settings:get("markerAlpha") or 100) * 0.01
            local markerY = cY - qs / 2

            if not markerElements[k] then
                markerElements[k] = ui.create({
                    layer = "HUD",
                    type = ui.TYPE.Widget,
                    props = { position = v2(0,0), size = v2(qs, qs), visible = true },
                    content = ui.content {
                        { type = ui.TYPE.Image, props = {
                            resource = icon,
                            size = v2(qs, qs),
                            alpha = mAlpha,
                            color = questClr,
                        }},
                    },
                })
            else
                markerElements[k].layout.content[1].props.resource = icon
            end

            local mdx = m.x - pPos.x
            local mdy = m.y - pPos.y
            local mAngle = math.atan2(mdx, mdy)
            local mdiff = util.normalizeAngle(mAngle - yaw)
            local mx = angleToX(mdiff, ss.x)

            markerElements[k].layout.content[1].props.color = questClr
            if mx then
                local hDiff = (m.z or 0) - pPos.z
                if math.abs(hDiff) > 300 then markerY = markerY + (hDiff > 0 and -3 or 3) end

                markerElements[k].layout.props.position = v2(clampX(mx, qs), markerY)
                markerElements[k].layout.content[1].props.alpha = mAlpha
            else
                local edgeX
                if mdiff > 0 then
                    edgeX = (ss.x + cw) / 2 - qs / 2
                else
                    edgeX = (ss.x - cw) / 2 - qs / 2
                end
                markerElements[k].layout.props.position = v2(edgeX, markerY)
                markerElements[k].layout.content[1].props.alpha = 0.3
            end
            markerElements[k].layout.props.visible = true
            markerElements[k]:update()
            active[k] = true
            ::skip::
        end
    end

    local maxQ = math.max(#trackedMarkers, #interiorDoors)
    for k2 = maxQ + 1, maxQ + 20 do
        local k = "q_" .. k2
        if markerElements[k] then
            markerElements[k].layout.props.visible = false
            markerElements[k]:update()
        end
    end

    -- Hide any element not active this frame
    for k, elem in pairs(markerElements) do
        if not active[k] and elem then
            elem.layout.props.visible = false
            elem:update()
        end
    end
end

local function showToggleNotif(enabled)
    if toggleNotifElement then
        toggleNotifElement:destroy()
        toggleNotifElement = nil
    end

    local ss = getScreenSize()
    local text = enabled and "Quest Markers Plus: Enabled" or "Quest Markers Plus: Disabled"
    local notifW = 400
    local notifH = enabled and 48 or 28

    local children = {
        { type = ui.TYPE.Flex, props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true,
        }, content = ui.content {
            { type = ui.TYPE.Text, props = {
                text = text,
                textSize = 16,
                textColor = util.color.rgb(0.88, 0.78, 0.55),
                textShadow = true,
                textShadowColor = util.color.rgb(0, 0, 0),
            }},
        }},
    }

    if enabled then
        children[#children+1] = { type = ui.TYPE.Flex, props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true,
        }, content = ui.content {
            { type = ui.TYPE.Text, props = {
                text = "Press J to open quest menu to re-enable tracking",
                textSize = 13,
                textColor = util.color.rgb(0.65, 0.58, 0.40),
                textShadow = true,
                textShadowColor = util.color.rgb(0, 0, 0),
            }},
        }}
    end

    toggleNotifElement = ui.create({
        layer = "HUD",
        type = ui.TYPE.Flex,
        props = {
            position = v2((ss.x - notifW) / 2, ss.y * 0.15),
            size = v2(notifW, notifH),
            horizontal = false,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            visible = true,
            alpha = 1,
        },
        content = ui.content(children),
    })
    toggleNotifTimer = TOGGLE_NOTIF_DURATION
end

return {
    engineHandlers = {
        onFrame = function(dt)
            local now = core.getRealTime()
            if now - lastUpdate < FRAME_INTERVAL then return end
            lastUpdate = now

            if toggleNotifTimer > 0 then
                toggleNotifTimer = toggleNotifTimer - dt
                if toggleNotifElement then
                    local a = math.min(1, toggleNotifTimer / 0.5)
                    toggleNotifElement.layout.props.alpha = a
                    toggleNotifElement.layout.props.visible = a > 0.01
                    toggleNotifElement:update()
                    if a <= 0.01 then
                        toggleNotifElement:destroy()
                        toggleNotifElement = nil
                    end
                end
            end

            if not isCompassEnabled() then
                hideAll()
                return
            end

            if I.UI.getMode() ~= nil and I.UI.getMode() ~= "Interface" then
                if compassElement then
                    compassElement.layout.props.visible = false
                    compassElement:update()
                end
                if cityLabelElement then
                    cityLabelElement.layout.props.visible = false
                    cityLabelElement:update()
                end
                return
            end

            local currentScale = getScale()
            if currentScale ~= lastScale then
                destroyAll()
                lastScale = currentScale
            end

            if not compassElement then buildCompass() end
            if compassElement then
                local barAlpha = (settings:get("compassAlpha") or 30) * 0.01
                compassElement.layout.props.visible = true
                compassElement.layout.content[1].props.alpha = barAlpha
                compassElement.layout.content[2].props.alpha = barAlpha
                compassElement:update()
            end

            updateCompass()
        end,

        onKeyPress = function(key)
            if key.code == input.KEY.O and I.UI.getMode() == nil then
                local enabled = isCompassEnabled()
                local newState = not enabled
                settings:set("compassEnabled", newState)
                showToggleNotif(newState)
                if not newState then
                    pcall(function()
                        storage.playerSection("Settings:QGL:ToRemove"):set("removeAll", true)
                    end)
                end
            end
        end,

        onActive = function()
            destroyAll()
            lastScale = getScale()
            buildCompass()
        end,
    },
    eventHandlers = {
        ["SkyrimCompass:setMarkers"] = function(data)
            local markers = {}
            for _, m in ipairs(data or {}) do
                if m.crossCell then
                    crossCellActive = true
                elseif m.x then
                    table.insert(markers, m)
                end
            end
            trackedMarkers = markers
        end,
        ["SkyrimCompass:exitDoorsFound"] = function(data)
            if data.doors then
                interiorDoors = data.doors
            end
        end,
    },
}
