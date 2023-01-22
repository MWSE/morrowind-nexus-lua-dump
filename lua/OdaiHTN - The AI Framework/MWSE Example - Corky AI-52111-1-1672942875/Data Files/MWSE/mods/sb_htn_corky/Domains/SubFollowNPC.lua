local odainHTN = require("sb_htn.interop")
local ConCorky = require("sb_htn_corky.Contexts.ConCorky")

---@class SubFollowNPC : DomainBuilder
local SubFollowNPC = odainHTN.DomainBuilder:new("Follow NPC", odainHTN.Factory.DefaultFactory:new(), ConCorky)

return SubFollowNPC:Select("Find Nearest NPC")
    :Condition("Is Not Returning To Origin", function(ctx)
        -- mwse.log("Is Not Returning To Origin?")
        return ctx:HasState(ConCorky.States.IsReturningToOrigin) == false
    end)
    :Condition("Is Not Following NPC", function(ctx)
        -- mwse.log("Is Not Following NPC?")
        return ctx:HasState(ConCorky.States.IsInterestedInNPC) == false
    end)
    :Condition("Is NPC Nearby", function(ctx)
        -- mwse.log("Is NPC Nearby?")
        local nearestDistance
        for npc in ctx.Reference.cell:iterateReferences(tes3.objectType.npc) do
            if (npc.position:distance(ctx.Reference.position) < (nearestDistance or 1024) and npc.isDead == false) then
                nearestDistance = npc.position:distance(ctx.Reference.position)
                ctx.Target = npc
            end
        end
        return nearestDistance ~= nil
    end)
    :Action("Follow NPC")
    :Do(function(ctx)
        -- mwse.log("Follow NPC...")
        tes3.setAIFollow { reference = ctx.Reference, target = ctx.Target }
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Is Following NPC", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Is Following NPC!")
        ctx:SetState(ConCorky.States.IsApproachingPlayer, false, type)
        ctx:SetState(ConCorky.States.IsInterestedInNPC, true, type)
        ctx:SetState(ConCorky.States.IsInterestedInObject, false, type)
    end)
    :End()
    :End()
    :Build()
