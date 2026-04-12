local mc = require("sb_htn.Utils.middleclass")
local IOperator = require("sb_htn.Operators.IOperator")
local ETaskStatus = require("sb_htn.Tasks.ETaskStatus")

---@class FuncOperator<IContext> : IOperator
---@field private _func fun(ctx: IContext): ETaskStatus
---@field private _start fun(ctx: IContext): ETaskStatus
---@field private _funcStop fun(ctx: IContext): boolean
---@field private _funcAborted fun(ctx: IContext): boolean
local FuncOperator = mc.class("FuncOperator", IOperator)

---@param func function<IContext, ETaskStatus>
---@param start function<IContext>?
---@param funcStop function<IContext>?
---@param funcAborted function<IContext>?
---@param T IContext
function FuncOperator:initialize(T, func, start, funcStop, funcAborted)
    self._func = func
    self._start = start
    self._funcStop = funcStop
    self._funcAborted = funcAborted
    self.T = T
end

---@param ctx IContext
function FuncOperator:Start(ctx)
    assert(ctx:isInstanceOf(self.T), "Unexpected context type!")
    if (self._start) then return self._start(ctx) else return ETaskStatus.Continue end -- Start is not required, so report back Continue if we have no Start func.
end

---@param ctx IContext
function FuncOperator:Update(ctx)
    assert(ctx:isInstanceOf(self.T), "Unexpected context type!")
    if (self._func) then return self._func(ctx) else return ETaskStatus.Failure end
end

---@param ctx IContext
function FuncOperator:Stop(ctx)
    assert(ctx:isInstanceOf(self.T), "Unexpected context type!")
    if (self._funcStop) then self._funcStop(ctx) end
end

---@param ctx IContext
function FuncOperator:Abort(ctx)
    assert(ctx:isInstanceOf(self.T), "Unexpected context type!")
    if (self._funcAborted) then self._funcAborted(ctx) end
end

return FuncOperator