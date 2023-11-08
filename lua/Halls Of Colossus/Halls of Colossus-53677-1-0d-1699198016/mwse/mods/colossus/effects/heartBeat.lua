local log = require("colossus.log")
local utils = require("colossus.utils")

local sounds = {
    { id = nil,          length = 1.000, maxDistance = 4800 },
    { id = "ggw_60bpm",  length = 1.920, maxDistance = 2400 },
    { id = "ggw_96bpm",  length = 1.202, maxDistance = 1800 },
    { id = "ggw_138bpm", length = 0.739, maxDistance = 1200 },
    { id = "ggw_174bpm", length = 0.652, maxDistance = 600 },
    { id = "ggw_210bpm", length = 0.546, maxDistance = 0 },
}

---@param handle mwseSafeObjectHandle
local function heartBeat(handle)
    if not ENABLED then return end

    if not handle:valid() then
        log:warn("heartBeat: invalid handle")
        return
    end

    ---@diagnostic disable-next-line: undefined-field
    local distance = tes3.player.position:distance(handle.position)

    --- Select the appropriate sound for the distance.
    for _, sound in ipairs(sounds) do
        if distance >= sound.maxDistance then
            log:trace("Playing sound %s", sound.id)
            if sound.id then
                tes3.playSound({
                    sound = sound.id,
                    pitch = utils.uniform(0.9, 1.0),
                    volume = utils.uniform(0.9, 1.0),
                    reference = tes3.player,
                    mixChannel = tes3.soundMix.master,
                })
            end
            timer.start({
                duration = sound.length + 0.01,
                callback = function()
                    heartBeat(handle)
                end,
            })
            break
        end
    end
end

local this = {}

---@param ref tes3reference
function this.start(ref)
    log:debug("Start heartbeat: %s", ref)
    local handle = tes3.makeSafeObjectHandle(ref)
    if handle then
        ENABLED = true
        heartBeat(handle)
    end
end

function this.stop()
    log:debug("Stop heartbeat")
    ENABLED = false
end

return this
