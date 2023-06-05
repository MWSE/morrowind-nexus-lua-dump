local log = require("leeches.log")
local utils = require("leeches.utils")

local this = {}

---@alias PathingCallback fun(timer: mwseTimer, reference: tes3reference): any
---@type table<string, PathingCallback>
local pathingCallbacks = {}

--- Register a pathing callback.
---
---@param name string
---@param callback PathingCallback
function this.registerCallback(name, callback)
    pathingCallbacks[name] = callback
end

---@class PathingData
---@field reference string
---@field onTick string
---@field onFinish string
---@field destinations number[][]

---@param data PathingData
function this.startPathing(data)
    timer.start({
        iterations = -1,
        duration = 0.1,
        callback = "leeches:pathing:update", ---@diagnostic disable-line
        persist = true,
        data = data,
    })
end

local function update(e)
    ---@type PathingData
    local data = e.timer.data

    -- Get the reference.
    local ref = utils.getReference(data.reference)
    if ref == nil then
        log:error("pathing: invalid reference (%s)", data.reference)
        e.timer:cancel()
        return
    end

    -- Trigger the onTick callback.
    if data.onTick then
        local callback = assert(pathingCallbacks[data.onTick])
        if callback(e.timer, ref) ~= nil then
            log:trace("pathing: paused (%s)", data.reference)
            return
        end
    end

    -- Ensure the reference is alive.
    if ref.isDead then
        log:debug("pathing: dead reference (%s)", data.reference)
        e.timer:cancel()
        return
    end

    -- Ensure the reference is in an active cell.
    local mobile = ref.mobile
    if not (mobile and mobile.activeAI) then
        log:debug("pathing: inactive reference (%s)", data.reference)
        return
    end

    -- Get the destination.
    local destination = data.destinations[1]

    -- Start pathing.
    local package = ref.mobile.aiPlanner:getActivePackage() or {}
    if package.type ~= tes3.aiPackage.travel then
        tes3.setAITravel({ reference = ref, destination = destination })
        return
    end

    -- Wait for pathing to finish.
    if not package.isDone then
        return
    end

    -- If we finished but we're not at the destination, teleport.
    local position = tes3vector3.new(unpack(destination))
    if ref.position:distance(position) > 1024 then
        tes3.positionCell({ reference = ref, position = destination })
    end

    -- Reset the AI.
    tes3.setAIWander({ reference = ref, idles = { 0, 0, 0, 0, 0, 0, 0, 0 } })

    -- Pop the destination.
    table.remove(data.destinations, 1)
    if #data.destinations ~= 0 then
        return
    end

    -- Trigger the onFinish callback.
    if data.onFinish then
        local callback = assert(pathingCallbacks[data.onFinish])
        callback(e.timer, ref)
    end

    -- All finished, end the timer.
    log:debug("pathing: finished (%s)", data.reference)
    e.timer:cancel()
end
timer.register("leeches:pathing:update", update)

return this
