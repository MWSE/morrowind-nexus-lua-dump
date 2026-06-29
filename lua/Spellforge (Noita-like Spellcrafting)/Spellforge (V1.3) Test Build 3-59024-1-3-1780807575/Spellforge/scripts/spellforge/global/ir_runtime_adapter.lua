---@omw-context global
local continuation_planner = require("scripts.spellforge.global.continuation_planner")
local runtime_ir = require("scripts.spellforge.global.runtime_ir")
local runtime_job_planner = require("scripts.spellforge.global.runtime_job_planner")

local ir_runtime_adapter = {}

local function firstIrError(ir)
    return ir and ir.errors and ir.errors[1] and ir.errors[1].code or "runtime_ir_build_failed"
end

local function cachedIr(owner, plan)
    if type(plan) ~= "table" then
        return nil, "missing_plan"
    end

    local ir = owner and owner.runtime_ir or nil
    if type(ir) ~= "table" or ir.ok ~= true then
        ir = runtime_ir.build(plan)
        if owner ~= nil then
            owner.runtime_ir = ir
        end
    end
    if type(ir) ~= "table" or ir.ok ~= true then
        return nil, firstIrError(ir)
    end
    return ir, nil
end

function ir_runtime_adapter.planEvent(owner, plan, event, opts)
    local ir, ir_reason = cachedIr(owner, plan)
    if not ir then
        return {
            ok = false,
            stage = "ir",
            rejection_reason = ir_reason,
            event = event,
        }
    end

    local continuation_plan = continuation_planner.planFromEvent(plan, ir, event, opts)
    if not continuation_plan or continuation_plan.ok ~= true then
        return {
            ok = false,
            stage = "continuation",
            rejection_reason = continuation_plan and continuation_plan.rejection_reason or "continuation_plan_failed",
            ir = ir,
            continuation_plan = continuation_plan,
            event = event,
        }
    end

    local job_plan = runtime_job_planner.planJobs(plan, ir, continuation_plan, event, opts)
    return {
        ok = true,
        ir = ir,
        continuation_plan = continuation_plan,
        job_plan = job_plan,
        event = event,
    }
end

return ir_runtime_adapter
