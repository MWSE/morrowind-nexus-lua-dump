local postprocessing = require('openmw.postprocessing')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local core = require('openmw.core')
local util = require('openmw.util')
local storage = require('openmw.storage')
local async = require('openmw.async')
local input = require('openmw.input')
local I = require('openmw.interfaces')

-----------------------------------------------------------------------------------------------------------------------

local focal = 0
local scaling = 0
local distdof = 2000
local shader = nil

-----------------------------------------------------------------------------------------------------------------------

local function enable()
    if not shader then shader = postprocessing.load('Cinematic Bokeh DoF') end
    shader:enable()
end

local function disable()
    if shader then shader:disable() end
end

-----------------------------------------------------------------------------------------------------------------------

local function boolSetting(key, name, description, default)
    return {
        key = key,
        renderer = 'checkbox',
        name = name,
        default = default,
    }
end

local function floatSetting(key, name, description, default)
    return {
        key = key,
        renderer = 'number',
        name = name,
        default = default,
    }
end

I.Settings.registerPage({
    key = 'WazaCinematicBokehDoF',
    l10n = 'CinematicBokehDoF',
    name = 'Cinematic DoF',
    description = 'Cinematic DoF from Dexter.',
})

local group = 'SettingsWazaCinematicBokehDoF'
local storage = storage.playerSection(group)

I.Settings.registerGroup({
    key = group,
    page = 'WazaCinematicBokehDoF',
    l10n = 'CinematicBokehDoF',
    name = 'General',
    permanentStorage = true,
    order = 0,
    settings = {
        boolSetting('enabled', 'Enabled', '', true),
        floatSetting('scaling', 'Time Scale', 'Transition Speed', 5),
        floatSetting('focal', 'Focal Length', 'Focal Length', 2000),
    },
})

local function updateSettings()
    local disabled = not storage:get('enabled')
    I.Settings.updateRendererArgument(group, 'scaling', {disabled = disabled, min = 0.1, max = 20})
    I.Settings.updateRendererArgument(group, 'focal', {disabled = disabled, min = 0})

    scaling = storage:get('scaling')
    focal = storage:get('focal')

    if disabled then
        disable()
    else
        enable()
    end
end

updateSettings()

storage:subscribe(async:callback(updateSettings))

-----------------------------------------------------------------------------------------------------------------------

return {
    engineHandlers = {
        onFrame = function(dt)
            if not shader or core.isWorldPaused() then return end

            local from = camera.getPosition()
            local orient = util.transform.rotateZ(camera.getYaw()) * util.transform.rotateX(camera.getPitch())

            local fpos = from + orient * util.vector3(0, focal, 0)

            local ray = nearby.castRenderingRay(from, from + orient * util.vector3(0, focal, 0))

            local trans = ray.hitPos and ray.hitPos or fpos

            local dist = (trans - from):length()

            local scaled_dt = scaling * dt

            distdof = distdof * (1.0 - scaled_dt) + dist * scaled_dt

            shader:setFloat('distdof', distdof)
        end,
        onKeyPress = function(key)
            if key.code ~= input.KEY.X then return end
            if storage:get('enabled') then
                storage:set('enabled', false)
                disable()
            else
                storage:set('enabled', true)
                enable()
            end
        end
    }
}