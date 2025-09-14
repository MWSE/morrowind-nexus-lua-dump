--[[
ErnShaderWrangler for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local core = require('openmw.core')
local onlineStats = require("scripts.ErnShaderWrangler.onlineStats")
local log = require("scripts.ErnShaderWrangler.log")
local settings = require("scripts.ErnShaderWrangler.settings")
local shader = require("scripts.ErnShaderWrangler.shader")
local pself = require("openmw.self")
local async = require("openmw.async")

local interiorShaders = {}
local exteriorShaders = {}

local function loadShaders(nameCSV)
    local out = {}
    for elem in string.gmatch(nameCSV, "[^,]+") do
        local parsed = ""
        local name = ""
        local parenIndex = string.find(elem, "%(")
        if parenIndex == nil then
            name = elem
            parsed = name
        else
            name = string.sub(elem, 1, parenIndex - 1)
            parsed = name
        end
        parsed = parsed .. " with args: "
        local shaderArgs = {}
        for k, v in string.gmatch(elem, "([^ (=]+)=([^ =)]+)") do
            shaderArgs[k] = tonumber(v)
            parsed = parsed .. k .. " = " .. shaderArgs[k] .. ", "
        end
        print("Loading shader " .. parsed)
        table.insert(out, shader.NewShader(name, shaderArgs))
    end
    return out
end

local function enableShaders(shaderCollection, enable)
    for _, s in ipairs(shaderCollection) do
        s:enable(enable)
    end
end

local frameDurationVarianceThreshold = 0.0
local disableShaderAtFrameDuration = 0.0
local enableShaderAtFrameDuration = 0.0
local interiorCondition = ""
local exteriorCondition = ""

local inExterior = nil

-- Ensure settings are re-applied.
local function applySettings()
    disableShaderAtFrameDuration = 1.0 / settings:get('disableAt')
    enableShaderAtFrameDuration = 1.0 / settings:get('enableAt')
    frameDurationVarianceThreshold = math.pow(settings:get('stddev'), 2)

    -- when set to 2, got 0.25
    print("frameDurationVarianceThreshold=" .. tostring(frameDurationVarianceThreshold))

    interiorCondition = settings:get('interior')
    exteriorCondition = settings:get('exterior')

    enableShaders(interiorShaders, false)
    enableShaders(exteriorShaders, false)
    print("Interior Shaders:" .. tostring(settings:get('interiorShaders')))
    interiorShaders = loadShaders(settings:get('interiorShaders'))
    print("Exterior Shaders:" .. tostring(settings:get('exteriorShaders')))
    exteriorShaders = loadShaders(settings:get('exteriorShaders'))

    -- even though this is not a setting, we reset it to nil
    -- so the shaders will re-apply later.
    inExterior = nil
end

applySettings()
settings:subscribe(async:callback(function(_, key)
    print("Settings changed.")
    applySettings()
end))

local frameDuration = onlineStats.NewSampleCollection(180)

local function onFrame(dt)
    -- don't do anything while paused.
    if dt == 0 then
        return
    end

    -- update running average
    local frameDur = core.getRealFrameDuration()
    frameDuration:add(frameDur)
end

local function onUpdate(dt)
    -- We moved between interior and exterior.
    local swapped = pself.cell.isExterior ~= inExterior or inExterior == nil
    if swapped then
        -- Ensure the old set of shaders is disabled.
        inExterior = pself.cell.isExterior
        if inExterior then
            enableShaders(interiorShaders, false)
        else
            enableShaders(exteriorShaders, false)
        end
    end

    -- Absolutist overrides.
    if inExterior then
        if exteriorCondition == "never" then
            enableShaders(exteriorShaders, false)
            return
        elseif exteriorCondition == "always" or swapped then
            enableShaders(exteriorShaders, true)
            return
        end
    else
        if interiorCondition == "never" then
            enableShaders(interiorShaders, false)
            return
        elseif interiorCondition == "always" or swapped then
            enableShaders(interiorShaders, true)
            return
        end
    end

    -- We're going to dynamically enable the shader now.
    local stats = frameDuration:calculate()
    if stats == nil then
        return
    end

    if stats.variance > frameDurationVarianceThreshold then
        -- stdev over 0.015 is variance > 0.000225
        -- this is basically +or- .02 seconds per frame
        log("stdev", function()
            return "FPS unstable. Frame Duration StdDev: " ..
                string.format("%.3f", math.sqrt(stats.variance)) .. " (" ..
                string.format("%.3f", math.sqrt(frameDurationVarianceThreshold)) .. ")"
        end)
        -- fps is too wild. do nothing.
        return
    end

    -- if FPS drops below 20, turn the shader off.
    if (stats.mean >= disableShaderAtFrameDuration) then
        log("disable", function()
            return "Disabling shaders. Frame Duration Mean: " ..
                string.format("%.3f", stats.mean) ..
                " (" ..
                string.format("%.3f", disableShaderAtFrameDuration) ..
                ") StdDev: " .. string.format("%.3f", math.sqrt(stats.variance)) .. " (" ..
                string.format("%.3f", math.sqrt(frameDurationVarianceThreshold)) .. ")"
        end)
        if inExterior then
            enableShaders(exteriorShaders, false)
        else
            enableShaders(interiorShaders, false)
        end
        return
    end
    if (stats.mean <= enableShaderAtFrameDuration) then
        -- we are fast and not using the shader, so enable it
        log("enable", function()
            return "Enabling shaders. Frame Duration Mean: " ..
                string.format("%.3f", stats.mean) ..
                " (" ..
                string.format("%.3f", enableShaderAtFrameDuration) ..
                ") StdDev: " .. string.format("%.3f", math.sqrt(stats.variance)) .. " (" ..
                string.format("%.3f", math.sqrt(frameDurationVarianceThreshold)) .. ")"
        end)
        if inExterior then
            enableShaders(exteriorShaders, true)
        else
            enableShaders(interiorShaders, true)
        end
        return
    end
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onUpdate = onUpdate
    }
}
