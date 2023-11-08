local utils = require("colossus.utils")

local this = {}

---@type mgeShaderHandle?
local shader

---@return mwseTimer?
local blackoutTimer

---@class BlackoutParams
---@field leadup number
---@field duration number
---@field delayMin number
---@field delayMax number

---@param params BlackoutParams
function this.start(params)
    if blackoutTimer then
        blackoutTimer:cancel()
        blackoutTimer = nil
    end

    shader = utils.getShader("ggw_blackout")
    if shader == nil then
        return
    end

    ---@diagnostic disable
    shader.startTime = 0.0
    shader.stopTime = 0.0
    shader.enabled = true
    ---@diagnostic enable

    blackoutTimer = timer.start({
        duration = params.leadup or 0.01,
        callback = "colossus:blackout",
        data = params,
    })
end

function this.stop()
    if blackoutTimer then
        blackoutTimer:cancel()
        blackoutTimer = nil
    end

    if shader then
        shader.enabled = false
    end
end

event.register("loaded", this.stop)

---@param e { timer: mwseTimer }
local function blackout(e)
    shader = utils.getShader("ggw_blackout")
    if shader == nil then
        return
    end

    ---@type BlackoutParams
    local params = e.timer.data

    -- The time it takes to fade in/out.
    local fadeTime = utils.uniform(1.0, 2.0)

    -- The space between this and the next blackout.
    local space = utils.uniform(params.delayMin, params.delayMax)

    -- The combined duration of the fade and following space.
    local duration = fadeTime + space

    -- If there's still duration remaining, schedule another blackout.
    params.duration = params.duration - duration
    if params.duration > 0 then
        blackoutTimer = timer.start({
            duration = duration,
            callback = "colossus:blackout",
            data = params,
        })
    end

    ---@diagnostic disable
    shader.enabled = true
    shader.startTime = shader.time
    shader.stopTime = shader.time + fadeTime
    ---@diagnostic enable
end
timer.register("colossus:blackout", blackout)

return this
