local odainHTN = require("sb_htn.interop")
local ConTetra = require("sb_htn_tetra.Contexts.ConTetra")

local SubTriggerCuriosity = require("sb_htn_tetra.Domains.SubTriggerCuriosity")
local SubReturnToOrigin = require("sb_htn_tetra.Domains.SubReturnToOrigin")
local SubAtOrigin = require("sb_htn_tetra.Domains.SubAtOrigin")
local SubFollowPlayer = require("sb_htn_tetra.Domains.SubFollowPlayer")
local SubFollowNPC = require("sb_htn_tetra.Domains.SubFollowNPC")
local SubApproachContainer = require("sb_htn_tetra.Domains.SubApproachContainer")
local SubAtContainer = require("sb_htn_tetra.Domains.SubAtContainer")

---@class DomTetra : DomainBuilder
local DomTetra = odainHTN.DomainBuilder:new("Tetra Domain", odainHTN.Factory.DefaultFactory:new(), ConTetra)

return DomTetra:Splice(SubTriggerCuriosity)
    :Select("AI Active")
    :Condition("Is Not In Combat", function(ctx)
        -- mwse.log("Is Not In Combat...")
        return ctx.Reference.mobile.inCombat == false
    end)
    :Condition("Is Idling", function(ctx)
        -- mwse.log("Is Idling...")
        return ctx:HasState(ConTetra.States.IsIdle)
    end)
    :Splice(SubAtOrigin)
    :Splice(SubAtContainer)
    :Splice(SubReturnToOrigin)
    :Splice(SubApproachContainer)
    :Splice(SubFollowPlayer)
    :Splice(SubFollowNPC)
    :End()
    :Build()
