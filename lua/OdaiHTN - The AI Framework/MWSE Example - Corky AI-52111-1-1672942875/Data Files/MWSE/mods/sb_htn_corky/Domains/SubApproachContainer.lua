local odainHTN = require("sb_htn.interop")
local ConCorky = require("sb_htn_corky.Contexts.ConCorky")

---@class SubApproachContainer : DomainBuilder
local SubApproachContainer = odainHTN.DomainBuilder:new("Approach Container", odainHTN.Factory.DefaultFactory:new(), ConCorky)

return SubApproachContainer:Select("Find Nearest Container")
    :Condition("Is Not Returning To Origin", function(ctx)
        -- mwse.log("Is Not Returning To Origin?")
        return ctx:HasState(ConCorky.States.IsReturningToOrigin) == false
    end)
    :Condition("Is Not Approaching Container", function(ctx)
        -- mwse.log("Is Not Approaching Container?")
        return ctx:HasState(ConCorky.States.IsInterestedInObject) == false
    end)
    :Condition("Is Container Nearby", function(ctx)
        -- mwse.log("Is Container Nearby?")
        local nearestDistance
        for container in ctx.Reference.cell:iterateReferences(tes3.objectType.container) do
            if (container.position:distance(ctx.Reference.position) < (nearestDistance or 1024) and container.isOrganic and table.size(container.invetory.items)) then
                nearestDistance = container.position:distance(ctx.Reference.position)
                ctx.Target = container
            end
        end
        return nearestDistance ~= nil
    end)
    :Action("Approach Container")
    :Do(function(ctx)
        -- mwse.log("Approach Container...")
        tes3.setAITravel { reference = ctx.Reference, destination = ctx.Reference.position:lerp(ctx.Target.position, 0.9) }
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Is Approaching Container", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Is Approaching Container!")
        ctx:SetState(ConCorky.States.IsApproachingPlayer, false, type)
        ctx:SetState(ConCorky.States.IsInterestedInNPC, false, type)
        ctx:SetState(ConCorky.States.IsInterestedInObject, true, type)
    end)
    :End()
    :End()
    :Build()
