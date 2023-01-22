local odainHTN = require("sb_htn.interop")
local ConCorky = require("sb_htn_corky.Contexts.ConCorky")

---@class SubAtContainer : DomainBuilder
local SubAtContainer = odainHTN.DomainBuilder:new("At Container", odainHTN.Factory.DefaultFactory:new(), ConCorky)

return SubAtContainer:Select("At Container")
    :Condition("Is Approaching Container", function(ctx)
        -- mwse.log("Is Approaching Container?")
        return ctx:HasState(ConCorky.States.IsInterestedInObject)
    end)
    :Condition("Is Close To Container", function(ctx)
        -- mwse.log("Is Close To Container?")
        return ctx.Reference.position:distance(ctx.IdlePosition) < 64
    end)
    :Action("At Container")
    :Do(function(ctx)
        -- mwse.log("At Container...")
        while (#ctx.Target.inventory.items > 0) do
            local stack = ctx.Target.inventory.items[1]
            tes3.transferItem{ from = ctx.Target, to = ctx.Reference, item = stack.object, count = stack.count }
        end
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Is At Container", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Is At Container!")
        ctx:SetState(ConCorky.States.IsApproachingPlayer, false, type)
        ctx:SetState(ConCorky.States.IsInterestedInNPC, false, type)
        ctx:SetState(ConCorky.States.IsInterestedInObject, false, type)
    end)
    :End()
    :End()
    :Build()
