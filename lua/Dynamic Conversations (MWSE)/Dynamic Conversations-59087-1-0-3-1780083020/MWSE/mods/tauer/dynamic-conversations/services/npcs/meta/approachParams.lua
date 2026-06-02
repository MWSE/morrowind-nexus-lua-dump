---@meta

--- Table parameter definitions for `npcMover.approach`.
---@class approachParams
---@field public npc tes3npcInstance The NPC that will approach the target
---@field public target tes3npcInstance The target NPC to approach
---@field public onApproached fun(tes3npcInstance, tes3npcInstance) A callback function to be called when the approach is complete
