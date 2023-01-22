local odainHTN = require("sb_htn.interop")
local ConCorky = require("sb_htn_corky.Contexts.ConCorky")

---@class SubReturnToOrigin : DomainBuilder
local SubReturnToOrigin = odainHTN.DomainBuilder:new("Return To Origin", odainHTN.Factory.DefaultFactory:new(), ConCorky)

return SubReturnToOrigin:Select("Try To Return To Origin")
    :Condition("Is Not Returning To Origin", function(ctx)
        -- mwse.log("Is Not Returning To Origin?")
        return ctx:HasState(ConCorky.States.IsReturningToOrigin) == false
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
        ctx:SetState(ConCorky.States.IsReturningToOrigin, true, type)
        ctx:SetState(ConCorky.States.IsApproachingPlayer, false, type)
        ctx:SetState(ConCorky.States.IsInterestedInNPC, false, type)
        ctx:SetState(ConCorky.States.IsInterestedInObject, false, type)
    end)
    :End()
    :End()
    :Build()
