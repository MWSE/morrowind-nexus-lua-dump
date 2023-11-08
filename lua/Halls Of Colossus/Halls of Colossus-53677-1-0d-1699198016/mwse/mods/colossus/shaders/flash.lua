local utils = require("colossus.utils")

local this = {}

---@class flashParams
---@field duration number

---@param params flashParams
function this.trigger(params)
    local shader = utils.getShader("ggw_flash")
    if shader == nil then
        return
    end

    ---@diagnostic disable

    local duration = params.duration
    local elapsed = 0.0

    shader.enabled = true
    shader.elapsed = elapsed
    shader.duration = duration

    local function update(e)
        ---@cast e simulateEventData
        elapsed = elapsed + e.delta
        if elapsed <= duration then
            shader.elapsed = elapsed
        else
            shader.enabled = false
            event.unregister("simulate", update)
        end
    end
    event.register("simulate", update)

    ---@diagnostic enable
end

return this
