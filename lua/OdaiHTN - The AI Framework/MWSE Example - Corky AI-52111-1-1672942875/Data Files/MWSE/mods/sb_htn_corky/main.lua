local odainHTN = require("sb_htn.interop")
local ConCorky = require("sb_htn_corky.Contexts.ConCorky")

---@type ConCorky
local ct
---@type Domain
local dt = require("sb_htn_corky.Domains.DomCorky")
---@type Planner
local p = odainHTN.Planners.Planner:new(ConCorky)
---@type mwseTimer
local t

--- @param e referenceActivatedEventData
local function referenceActivatedCallback(e)
    if (e.reference.baseObject.id == "guar_llovyn_unique") then
        if (t == nil) then
            ct = ConCorky:new(e.reference)
            ct:init()
            ct.LogDecomposition = true

            t = timer.start {
                duration = 1 / 4,
                iterations = -1,
                callback = function() p:Tick(dt, ct) end
            }
        else
            t:resume()
        end
    end
end

event.register(tes3.event.referenceActivated, referenceActivatedCallback)

--- @param e referenceDeactivatedEventData
local function referenceDeactivatedCallback(e)
    if (e.reference.baseObject.id == "guar_llovyn_unique") then
        if (t) then
            t:pause()
        end
    end
end

event.register(tes3.event.referenceDeactivated, referenceDeactivatedCallback)
