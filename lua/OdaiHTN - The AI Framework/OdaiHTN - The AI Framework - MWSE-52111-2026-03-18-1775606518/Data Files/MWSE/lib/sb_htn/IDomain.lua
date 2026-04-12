local mc = require("sb_htn.Utils.middleclass")

---@class IDomain
---@field Root TaskRoot
---@field AddSubtask fun(self: IDomain, parent: ICompoundTask, subtask: ITask): ICompoundTask
---@field AddSlot fun(self: IDomain, parent: ICompoundTask, slot: Slot): ICompoundTask
local IDomain = mc.class("IDomain")

return IDomain