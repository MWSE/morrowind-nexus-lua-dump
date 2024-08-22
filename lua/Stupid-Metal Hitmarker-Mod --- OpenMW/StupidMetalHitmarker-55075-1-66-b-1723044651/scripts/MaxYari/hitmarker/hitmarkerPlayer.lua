local mp = "scripts/MaxYari/hitmarker/"
local fp = "scripts\\MaxYari\\hitmarker\\"

local ui = require("openmw.ui")
local util = require("openmw.util")
local gutils = require(mp .. "gutils")
local core = require("openmw.core")
local omwself = require("openmw.self")
local selfActor = gutils.Actor:new(omwself)

DebugLevel = 0

-- In a player script
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'SMHitmarkerPage',
    l10n = 'SMHitmarker',
    name = 'Stupid-Metal Hitmarkers',
    description = '~~ Hit em good. With visual feedback.',
}
I.Settings.registerGroup {
    key = 'SMHitmarkerSettings',
    page = 'SMHitmarkerPage',
    l10n = 'SMHitmarker',
    name = 'Settings',
    description = '',
    permanentStorage = true,
    settings = {
        {
            key = 'UseHitSound',
            renderer = 'checkbox',
            default = true,
            name = 'Use hitmarker sound',
            description = 'A bit of oomph'
        },
        {
            key = 'UseOnlyMarksmanHitSound',
            renderer = 'checkbox',
            default = true,
            name = 'Hitmarker sound with marksman weapon only',
            description = ''
        },
    },
}
local playerSettings = storage.playerSection('SMHitmarkerSettings')





local skullSize = util.vector2(379, 600) / 4.5
local skull = ui.create({
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        alpha = 0,
        size = skullSize,
        relativePosition = util.vector2(0.5, 0.5),
        anchor = (util.vector2(0.5, 0.5)),
        resource = ui.texture { path = mp .. "img/killskull.png" }
    }
})

local hitmarkerSize = util.vector2(200, 200) / 2
local hitmarker = ui.create({
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        alpha = 0,
        size = hitmarkerSize,
        relativePosition = util.vector2(0.5, 0.5),
        anchor = (util.vector2(0.5, 0.5)),
        resource = ui.texture { path = mp .. "img/hitmarker.png" }
    }
})

local dotSize = util.vector2(4, 4)
local dotAlpha = 0.25
local dot = ui.create({
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        alpha = dotAlpha,
        size = dotSize,
        relativePosition = util.vector2(0.5, 0.5),
        anchor = (util.vector2(0.5, 0.5)),
        resource = ui.texture { path = mp .. "img/reticle_dot.png" }
    }
})



local function onUpdate(dt)
    hitmarker.layout.props.alpha = gutils.lerp(hitmarker.layout.props.alpha, 0, dt * 8)
    hitmarker:update()

    skull.layout.props.alpha = gutils.lerp(skull.layout.props.alpha, 0, dt * 2)
    skull:update()

    dot.layout.props.alpha = gutils.lerp(dot.layout.props.alpha, dotAlpha, dt)
    dot:update()
end

local lastHostileDamagedTime = 0
local throttleInterval = 0.333
local function onHostileDamaged(data)
    gutils.print("HIT", 1)

    local currentTime = core.getRealTime()
    if data.currentHealth > 0 and currentTime - lastHostileDamagedTime < throttleInterval then
        return
    end
    lastHostileDamagedTime = currentTime


    if data.currentHealth <= 0 then
        skull.layout.props.alpha = 1
        dot.layout.props.alpha = 0
    else
        hitmarker.layout.props.alpha = 1
    end

    local stance = selfActor:getDetailedStance()

    if playerSettings:get('UseHitSound') then
        if not playerSettings:get('UseOnlyMarksmanHitSound') or stance == gutils.Actor.DET_STANCE.Marksman then
            local params
            if data.currentHealth <= 0 then
                params = { volume = 13, pitch = 0.2, loop = false }
            else
                params = { volume = 10, pitch = 0.2 + math.random() * 0.2, loop = false }
            end

            core.sound.playSoundFile3d(fp .. "sounds\\hit.wav", omwself, params)
        end
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = { HostileDamaged = onHostileDamaged },
}
