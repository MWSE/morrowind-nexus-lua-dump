
local common = require("mer.darkShard.common")
local logger = common.createLogger("ShardCell")

---@class DarkShard.ShardCell
local ShardCell = {
    cellId = "dark shard"
}

---Check if the player is in the shard
---@param ref? tes3reference
---@return boolean
function ShardCell.isOnShard(ref)
    ref = ref or tes3.player
    local cell = ref.cell
    if not cell then return false end
    return cell.id:lower() == ShardCell.cellId
end



return ShardCell