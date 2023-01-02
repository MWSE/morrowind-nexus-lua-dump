local odainHTN = require("sb_htn.interop")
local ConTetra = require("sb_htn_tetra.Contexts.ConTetra")

---@class SubReturnToOrigin : DomainBuilder
local SubReturnToOrigin = odainHTN.DomainBuilder:new("Return To Origin", odainHTN.Factory.DefaultFactory:new(), ConTetra)

return SubReturnToOrigin:Select("Try To Return To Origin")
    :Condition("Is Not Returning To Origin", function(ctx)
        -- mwse.log("Is Not Returning To Origin?")
        return ctx:HasState(ConTetra.States.IsReturningToOrigin) == false
    end)
    :Condition("Is Too Far From Origin", function(ctx)
        -- mwse.log("Is Too Far From Origin?")
        return ctx.Reference.position:distance(ctx.IdlePosition) > 1024
    end)
    :Action("Return To Origin")
    :Do(function(ctx)
        -- mwse.log("Return To Origin...")
        tes3.setAITravel { reference = ctx.Reference, destination = ctx.IdlePosition }
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Is At Origin", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Is At Origin!")
        ctx:SetState(ConTetra.States.IsReturningToOrigin, true, type)
        ctx:SetState(ConTetra.States.IsApproachingPlayer, false, type)
        ctx:SetState(ConTetra.States.IsInterestedInNPC, false, type)
        ctx:SetState(ConTetra.States.IsInterestedInObject, false, type)
    end)
    :End()
    :End()
    :Build()
