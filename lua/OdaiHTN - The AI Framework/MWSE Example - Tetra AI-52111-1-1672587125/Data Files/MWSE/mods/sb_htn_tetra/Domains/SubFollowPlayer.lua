local odainHTN = require("sb_htn.interop")
local ConTetra = require("sb_htn_tetra.Contexts.ConTetra")

---@class SubFollowPlayer : DomainBuilder
local SubFollowPlayer = odainHTN.DomainBuilder:new("Follow Player", odainHTN.Factory.DefaultFactory:new(), ConTetra)

return SubFollowPlayer:Select("Find Nearest Player")
    :Condition("Is Not Returning To Origin", function(ctx)
        -- mwse.log("Is Not Returning To Origin?")
        return ctx:HasState(ConTetra.States.IsReturningToOrigin) == false
    end)
    :Condition("Is Not Following Player", function(ctx)
        -- mwse.log("Is Not Following Player?")
        return ctx:HasState(ConTetra.States.IsApproachingPlayer) == false
    end)
    :Condition("Is Player Nearby", function(ctx)
        -- mwse.log("Is Player Nearby?")
        return tes3.player.position:distance(ctx.Reference.position) < 1024
    end)
    :Action("Follow Player")
    :Do(function(ctx)
        -- mwse.log("Follow Player...")
        tes3.setAIFollow { reference = ctx.Reference, target = tes3.mobilePlayer }
        ctx.Target = nil
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Is Following Player", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        -- mwse.log("Is Following Player!")
        ctx:SetState(ConTetra.States.IsApproachingPlayer, true, type)
        ctx:SetState(ConTetra.States.IsInterestedInNPC, false, type)
        ctx:SetState(ConTetra.States.IsInterestedInObject, false, type)
    end)
    :End()
    :End()
    :Build()
