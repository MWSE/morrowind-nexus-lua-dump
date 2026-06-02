---@meta

--- Timer callback data for NPC travel
---@class approachTimerData : decoratedTimerData
---@field public npc mwseSafeObjectHandle The safe object handle of the NPC that is traveling
---@field public target mwseSafeObjectHandle The safe object handle of the target NPC being approached
---@field public onApproached function A callback function to be called when the travel is complete
