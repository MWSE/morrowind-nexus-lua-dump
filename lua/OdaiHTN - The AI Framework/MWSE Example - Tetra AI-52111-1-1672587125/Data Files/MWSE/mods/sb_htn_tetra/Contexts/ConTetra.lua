local odainHTN = require("sb_htn.interop")
local mc = require("sb_htn.Utils.middleclass")

---@class ConTetra : BaseContext
local ConTetra = mc.class("ConTetra", odainHTN.Contexts.BaseContext)

ConTetra.States =
{
    IsIdle = 1,
    IsReturningToOrigin = 2,
    IsApproachingPlayer = 3,
    IsInterestedInNPC = 4,
    IsInterestedInObject = 5
}

function ConTetra:initialize(ref)
    odainHTN.Contexts.BaseContext.initialize(self)

    self.WorldState       = {}
    self.MTRDebug         = nil;
    self.LastMTRDebug     = nil;
    self.DebugMTR         = false;
    self.LogDecomposition = false;

    self.Factory = odainHTN.Factory.DefaultFactory:new();

    for _, v in pairs(ConTetra.States) do
        self.WorldState[v] = 0
    end

    ---@type string
    self.IdleCellID = ref.cell.id
    ---@type tes3vector3
    self.IdlePosition = ref.position:copy()
    ---@type tes3reference
    self.Reference = ref
    ---@type tes3reference
    self.Target = nil
end

function ConTetra:init()
    odainHTN.Contexts.BaseContext.init(self)
end

function ConTetra:HasState(state, value)
    if (value ~= nil) then
        return odainHTN.Contexts.BaseContext.HasState(self, state, (value and 1 or 0));
    else
        return odainHTN.Contexts.BaseContext.HasState(self, state, 1);
    end
end

function ConTetra:SetState(state, value, type)
    odainHTN.Contexts.BaseContext.SetState(self, state, (value and 1 or 0), true, type);
end

return ConTetra
