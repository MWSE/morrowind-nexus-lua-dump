local odainHTN = require("sb_htn.interop")
local ConTetra = require("sb_htn_tetra.Contexts.ConTetra")

---@class DomTetra : DomainBuilder
local DomTetra = odainHTN.DomainBuilder:new("Tetra Domain", odainHTN.Factory.DefaultFactory:new(), ConTetra)

return DomTetra:Select("Find Player")
    :Condition("Is Player Nearby", function(ctx)
        mwse.log("Is Player Nearby...")
        return tes3.player.position:distance(ctx.Reference.position) <= 1024
    end)
    :Condition("Is Not Already Following Player", function(ctx)
        mwse.log("Is Not Already Following Player...")
        return ctx:HasState(ConTetra.States.IsApproachingPlayer) == false
    end)
    :Condition("Is Not In Combat", function(ctx)
        mwse.log("Is Not In Combat...")
        return ctx.Reference.mobile.inCombat == false
    end)
    :Action("Follow Player")
    :Do(function(ctx)
        mwse.log("Follow Player")
        tes3.setAIFollow { reference = ctx.Reference, target = tes3.player }
        return odainHTN.Tasks.ETaskStatus.Success
    end, nil)
    :Effect("Is Following Player", odainHTN.Effects.EEffectType.PlanAndExecute, function(ctx, type)
        mwse.log("Is Following Player")
        ctx:SetState(ConTetra.States.IsApproachingPlayer, true, type)
    end)
    :End()
    :End()
    -- :Select("Done")
    -- :Action("Done")
    -- :Do(function(ctx)
    --     mwse.log("Done");
    --     ctx.Done = true;
    --     return odainHTN.Tasks.ETaskStatus.Continue;
    -- end, nil)
    -- :End()
    -- :End()
    :Build()
