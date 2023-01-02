local odainHTN = require("sb_htn.interop")
local ConTetra = require("sb_htn_tetra.Contexts.ConTetra")

---@type ConTetra
local ct
---@type Domain
local dt = require("sb_htn_tetra.Domains.DomTetra")
---@type Planner
local p = odainHTN.Planners.Planner:new(ConTetra)
---@type mwseTimer
local t

--- @param e referenceActivatedEventData
local function referenceActivatedCallback(e)
    if (e.reference.baseObject.id == "AA1_Tetra") then
        if (t == nil) then
            ct = ConTetra:new(e.reference)
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
    if (e.reference.baseObject.id == "AA1_Tetra") then
        if (t) then
            t:pause()
        end
    end
end

event.register(tes3.event.referenceDeactivated, referenceDeactivatedCallback)
