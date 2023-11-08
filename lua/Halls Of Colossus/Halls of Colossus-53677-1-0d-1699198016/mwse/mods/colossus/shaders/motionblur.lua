local utils = require("colossus.utils")

local this = {}

---@type mgeShaderHandle?
local shader

---@type tes3transform?
local previous

---@param e simulateEventData
local function update(e)
    if shader == nil then
        return
    end

    local camera = tes3.getCamera()
    local current = camera.worldTransform
    previous = previous or current:copy()

    local t = math.clamp(1.0 - e.delta, 0.0, 1.0)

    previous.translation = (
        previous.translation:lerp(current.translation, t)
    )
    previous.rotation = (
        previous.rotation:toQuaternion():slerp(current.rotation:toQuaternion(), t):toRotation()
    )

    local inv = previous:invert()
    local pos = inv.translation
    local r = inv.rotation

    ---@diagnostic disable
    shader.mviewLast = {
        r.z.x, r.y.x, r.x.x, 0,
        r.z.y, r.y.y, r.x.y, 0,
        r.z.z, r.y.z, r.x.z, 0,
        pos.z, pos.y, pos.x, 1,
    }
    ---@diagnostic enable
end
event.register("simulate", update)

function this.start()
    shader = utils.getShader("ggw_motionblur")
    if shader == nil then
        return
    end

    previous = nil
    shader.enabled = true

    if not event.isRegistered("simulate", update) then
        event.register("simulate", update)
    end
end

function this.stop()
    if shader == nil then
        return
    end

    previous = nil
    shader.enabled = false

    event.unregister("simulate", update)
end

return this
