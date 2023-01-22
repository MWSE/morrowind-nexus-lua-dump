local odainHTN = require("sb_htn.interop")
local ConCorky = require("sb_htn_corky.Contexts.ConCorky")

---@class SubAtOrigin : DomainBuilder
local SubAtOrigin = odainHTN.DomainBuilder:new("At Origin", odainHTN.Factory.DefaultFactory:new(), ConCorky)

return SubAtOrigin:Select("At Origin")
    :Condition("Is Returning To Origin", function(ctx)
        -- mwse.log("Is Returning To Origin?")
        return ctx:HasState(ConCorky.States.IsReturningToOrigin)
    end)
    :Condition("Is Close To Origin", function(ctx)
        -- mwse.log("Is Close To Origin?")
        if (ctx.IdleCellID ~= ctx.Reference.cell.id) then
            -- mwse.log("Origin In Another Cell, Repositioning...")
            ctx.IdleCellID = ctx.Reference.cell.id
            ctx.IdlePosition = ctx.Reference.position:copy()
        end
        return ctx.Reference.mobile.aiPlanner:getActivePackage() and
            ctx.Reference.mobile.aiPlanner:getActivePackage().type ~= tes3.aiPackage.travel and
            ctx.Reference.position:distance(ctx.IdlePosition) < 256
    end)
    :Action("At Origin")
    :Do(function(ctx)
        -- mwse.log("At Origin...")
        tes3.positionCell { reference = ctx.Reference, position = ctx.IdlePosition }
        tes3.setAIWander { reference = ctx.Reference, idles = { 0, 24, 20, 20, 20, 20, 20 }, range = 0 }
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Is At Origin", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Is At Origin!")
        ctx:SetState(ConCorky.States.IsReturningToOrigin, false, type)
        ctx:SetState(ConCorky.States.IsApproachingPlayer, false, type)
        ctx:SetState(ConCorky.States.IsInterestedInNPC, false, type)
        ctx:SetState(ConCorky.States.IsInterestedInObject, false, type)
    end)
    :End()
    :End()
    :Build()
