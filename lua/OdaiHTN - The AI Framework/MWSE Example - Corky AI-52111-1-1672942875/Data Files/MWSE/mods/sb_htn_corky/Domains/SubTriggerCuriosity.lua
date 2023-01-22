local odainHTN = require("sb_htn.interop")
local ConCorky = require("sb_htn_corky.Contexts.ConCorky")

---@class SubTriggerCuriosity : DomainBuilder
local SubTriggerCuriosity = odainHTN.DomainBuilder:new("Trigger Curiosity", odainHTN.Factory.DefaultFactory:new(), ConCorky)

return SubTriggerCuriosity:Select("Try To Enable Curiosity")
    :Condition("Is Not Purchased", function(ctx)
        -- mwse.log("Is Not Purchased?")
        if (tes3.getCurrentAIPackageId(ctx.Reference.mobile) ~= tes3.aiPackage.follow) then
            return false
        end
        local animState = ctx.Reference.mobile.actionData.animationAttackState
        if (
            ctx.Reference.mobile.health.current <= 0 or animState == tes3.animationState.dying or
                animState == tes3.animationState.dead) then
            return false
        end

        return true
    end)
    :Condition("Is Not Idling", function(ctx)
        -- mwse.log("Is Not Idling?")
        return ctx:HasState(ConCorky.States.IsIdle) == false
    end)
    :Action("Enable Curiosity")
    :Do(function(ctx)
        -- mwse.log("Enable Curiosity...")
        ctx.IdleCellID = ctx.Reference.cell.id
        ctx.IdlePosition = ctx.Reference.position:copy()
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Corky Is Curious", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Corky Is Curious!")
        ctx:SetState(ConCorky.States.IsIdle, true, type)
    end)
    :End()
    :End()
    :Select("Try To Disable Curiosity")
    :Condition("Is Purchased", function(ctx)
        -- mwse.log("Is Purchased?")
        return tes3.getGlobal("Purchased") == 1
    end)
    :Condition("Is Idling", function(ctx)
        -- mwse.log("Is Idling?")
        return ctx:HasState(ConCorky.States.IsIdle)
    end)
    :Action("Disable Curiosity")
    :Do(function(ctx)
        -- mwse.log("Disable Curiosity...")
        ctx.IdlePosition = nil
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Corky Is Not Curious", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Corky Is Not Curious!")
        ctx:SetState(ConCorky.States.IsIdle, false, type)
    end)
    :End()
    :End()
    :Build()
