local odainHTN = require("sb_htn.interop")
local ConTetra = require("sb_htn_tetra.Contexts.ConTetra")

---@class SubTriggerCuriosity : DomainBuilder
local SubTriggerCuriosity = odainHTN.DomainBuilder:new("Trigger Curiosity", odainHTN.Factory.DefaultFactory:new(), ConTetra)

return SubTriggerCuriosity:Select("Try To Enable Curiosity")
    :Condition("Is Not AA1_TetraFlw", function(ctx)
        -- mwse.log("Is Not AA1_TetraFlw?")
        return tes3.getGlobal("AA1_TetraFlw") == 0
    end)
    :Condition("Is Not Idling", function(ctx)
        -- mwse.log("Is Not Idling?")
        return ctx:HasState(ConTetra.States.IsIdle) == false
    end)
    :Action("Enable Curiosity")
    :Do(function(ctx)
        -- mwse.log("Enable Curiosity...")
        ctx.IdleCellID = ctx.Reference.cell.id
        ctx.IdlePosition = ctx.Reference.position:copy()
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Tetra Is Curious", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Tetra Is Curious!")
        ctx:SetState(ConTetra.States.IsIdle, true, type)
    end)
    :End()
    :End()
    :Select("Try To Disable Curiosity")
    :Condition("Is AA1_TetraFlw", function(ctx)
        -- mwse.log("Is AA1_TetraFlw?")
        return tes3.getGlobal("AA1_TetraFlw") == 1
    end)
    :Condition("Is Idling", function(ctx)
        -- mwse.log("Is Idling?")
        return ctx:HasState(ConTetra.States.IsIdle)
    end)
    :Action("Disable Curiosity")
    :Do(function(ctx)
        -- mwse.log("Disable Curiosity...")
        ctx.IdlePosition = nil
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Tetra Is Not Curious", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Tetra Is Not Curious!")
        ctx:SetState(ConTetra.States.IsIdle, false, type)
    end)
    :End()
    :End()
    :Build()
