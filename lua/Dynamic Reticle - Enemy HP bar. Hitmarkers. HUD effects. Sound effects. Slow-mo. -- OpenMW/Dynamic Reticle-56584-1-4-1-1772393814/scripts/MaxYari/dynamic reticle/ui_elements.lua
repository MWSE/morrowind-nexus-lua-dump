local mp = "scripts/MaxYari/dynamic reticle/"
local ui = require("openmw.ui")
local util = require("openmw.util")
local storage = require("openmw.storage")

local gutils = require(mp .. "gutils")
local settings = require(mp .. "settings")

local visualSettings = storage.playerSection('DynamicReticleVisualSettings')

-- Hitmarkers
local hitmarkerColor = visualSettings:get("HitMarkerColor")
local hitmarkerAlpha = visualSettings:get("HitMarkerOpacity")
local weakHitmarkerAlpha = visualSettings:get("WeakHitMarkerOpacity")
local hitmarkerScale = visualSettings:get("HitMarkerScale")

local hitmarkerTrianglePieceSize = util.vector2(14, 14) * hitmarkerScale

-- Reticles
local reticleColor = visualSettings:get("ReticleColor")
local reticleAlpha = visualSettings:get("ReticleOpacity")
local reticleSneakScale = visualSettings:get("ReticleSneakScale")
local reticleScale = visualSettings:get("ReticleScale")
local stealthArrowsScale = 0.75

local circleReticleSize = util.vector2(21, 21) * reticleScale
local stealthArrowSize = util.vector2(30.5, 7) * stealthArrowsScale

local animConf = {
    hmAlpha = hitmarkerAlpha,
    hmWeakAlpha = weakHitmarkerAlpha,
    hmPartSizeMult = 1,
    hmPartFromDist = 0,
    hmPartToDist = 0.0625 * hitmarkerScale,
    reticleAlpha = reticleAlpha,
    reticleSneakSizeMult = reticleSneakScale,
    sneakArrowPartFromDist = 0.25,
    sneakArrowPartToDist = 0.1,
}

-- Create a parent element
local parentElement = ui.create({
    layer = 'HUD',
    type = ui.TYPE.Widget,
    props = {
        size = util.vector2(200, 200),
        alpha = 1,
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(0.5, 0.5),
    },
    content = ui.content {        
        {
            name = "reticle",
            type = ui.TYPE.Image,
            props = {
                alpha = reticleAlpha,
                color = reticleColor,
                size = circleReticleSize,
                relativePosition = util.vector2(0.5, 0.5),
                anchor = util.vector2(0.5, 0.5),
                resource = ui.texture { path = settings.fileSelectors["Reticle"]:getFilePath() }
            },
            userData = { }
        },
        {
            name = "stealthArrowL",
            type = ui.TYPE.Image,
            props = {
                alpha = 0,
                color = reticleColor,
                size = stealthArrowSize,
                relativePosition = util.vector2(0.5, 0.5),
                anchor = util.vector2(1, 0.5),
                resource = ui.texture { path = settings.fileSelectors["StealthArrows"]:getFilePath("l") }
            },
            userData = {                
                direction = util.vector2(-1, 0),
                
            }
        },
        {
            name = "stealthArrowR",
            type = ui.TYPE.Image,
            props = {
                alpha = 0,
                color = reticleColor,
                size = stealthArrowSize,
                relativePosition = util.vector2(0.5, 0.5),
                anchor = util.vector2(0, 0.5),
                resource = ui.texture { path = settings.fileSelectors["StealthArrows"]:getFilePath("r")  }
            },
            userData = {                
                direction = util.vector2(1,0),                
            }
        },
        {
            name = "hitmarkerWrapper",
            type = ui.TYPE.Widget,
            props = {
                relativeSize = util.vector2(1, 1),
                alpha = 1,
            },
            content = ui.content {
                {
                    name = "hitmarkerWhiteTR",
                    type = ui.TYPE.Image,
                    props = {
                        alpha = 0,
                        size = hitmarkerTrianglePieceSize,
                        color = hitmarkerColor,
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0, 1),
                        resource = ui.texture { path = settings.fileSelectors["HitMarker"]:getFilePath("tr") }
                    },
                    userData = { direction = util.vector2(1,-1) }
                },
                {
                    name = "hitmarkerWhiteBR",
                    type = ui.TYPE.Image,
                    props = {
                        alpha = 0,
                        size = hitmarkerTrianglePieceSize,
                        color = hitmarkerColor,
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0, 0),
                        resource = ui.texture { path = settings.fileSelectors["HitMarker"]:getFilePath("br") }
                    },
                    userData = { direction = util.vector2(1,1)}
                },
                {
                    name = "hitmarkerWhiteBL",
                    type = ui.TYPE.Image,
                    props = {
                        alpha = 0,
                        size = hitmarkerTrianglePieceSize,
                        color = hitmarkerColor,
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(1, 0),
                        resource = ui.texture { path = settings.fileSelectors["HitMarker"]:getFilePath("bl") }
                    },
                    userData = { direction = util.vector2(-1,1)  }
                },
                {
                    name = "hitmarkerWhiteTL",
                    type = ui.TYPE.Image,
                    props = {
                        alpha = 0,
                        size = hitmarkerTrianglePieceSize,
                        color = hitmarkerColor,
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(1, 1),
                        resource = ui.texture { path = settings.fileSelectors["HitMarker"]:getFilePath("tl") }
                    },
                    userData = { direction = util.vector2(-1,-1)}
                }
            }
        }
    }
})

local function saveStartParams(el)
    if el.content then
        for name, child in pairs(el.content) do
            if not child.name then goto continue end
            saveStartParams(child)
            ::continue::
        end
    end
    if not el.userData then el.userData = {} end
    gutils.shallowMergeTables(el.userData, el.props)
end

saveStartParams(parentElement.layout)

-- Function to fetch elements by name
local function getElementByName(name)
    return parentElement.layout.content[name]
end


return {
    animConf = animConf,
    parentElement = parentElement,
    getElementByName = getElementByName
}
