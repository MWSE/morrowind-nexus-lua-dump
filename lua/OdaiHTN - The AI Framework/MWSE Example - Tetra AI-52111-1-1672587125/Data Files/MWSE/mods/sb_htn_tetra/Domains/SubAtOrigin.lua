local odainHTN = require("sb_htn.interop")
local ConTetra = require("sb_htn_tetra.Contexts.ConTetra")

---@class SubAtOrigin : DomainBuilder
local SubAtOrigin = odainHTN.DomainBuilder:new("At Origin", odainHTN.Factory.DefaultFactory:new(), ConTetra)

return SubAtOrigin:Select("At Origin")
    :Condition("Is Returning To Origin", function(ctx)
        -- mwse.log("Is Returning To Origin?")
        return ctx:HasState(ConTetra.States.IsReturningToOrigin)
    end)
    :Condition("Is Close To Origin", function(ctx)
        -- mwse.log("Is Close To Origin?")
        if (ctx.IdleCellID ~= ctx.Reference.cell.id) then
            -- mwse.log("Origin In Another Cell, Repositioning...")
            ctx.IdleCellID = ctx.Reference.cell.id
            ctx.IdlePosition = ctx.Reference.position:copy()
        end
        return ctx.Reference.position:distance(ctx.IdlePosition) < 1
    end)
    :Action("At Origin")
    :Do(function(ctx)
        -- mwse.log("At Origin...")
        tes3.setAIWander { reference = ctx.Reference, idles = { 0, 24, 20, 20, 20, 20, 20 }, range = 0 }
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Is At Origin", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Is At Origin!")
        ctx:SetState(ConTetra.States.IsReturningToOrigin, false, type)
        ctx:SetState(ConTetra.States.IsApproachingPlayer, false, type)
        ctx:SetState(ConTetra.States.IsInterestedInNPC, false, type)
        ctx:SetState(ConTetra.States.IsInterestedInObject, false, type)
    end)
    :End()
    :End()
    :Build()
