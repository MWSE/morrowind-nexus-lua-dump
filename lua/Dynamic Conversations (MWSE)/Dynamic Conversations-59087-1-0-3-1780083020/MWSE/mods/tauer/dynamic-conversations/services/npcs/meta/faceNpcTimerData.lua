---@meta

--- Timer callback data for facing an NPC
---@class faceNpcTimerData : decoratedTimerData
---@field public npc mwseSafeObjectHandle The safe object handle of the NPC that is facing
---@field public target mwseSafeObjectHandle The safe object handle of the target NPC to face
---@field public angleChangePerIteration number The angle change per timer iteration (in radians)
