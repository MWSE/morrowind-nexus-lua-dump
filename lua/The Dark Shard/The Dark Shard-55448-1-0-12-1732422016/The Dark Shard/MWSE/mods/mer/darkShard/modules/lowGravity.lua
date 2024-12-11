
local common = require("mer.darkShard.common")
local logger = common.createLogger("shardCell")
local Gravity = require("mer.darkShard.components.Gravity")
local ShardCell = require("mer.darkShard.components.ShardCell")

local function togglePlayerGravity()
    if ShardCell.isOnShard() then
        logger:debug("Entering shard")
        Gravity.enableLowGravity()
    else
        logger:debug("Leaving shard")
        Gravity.disableLowGravity()
    end
end

event.register("cellChanged",  togglePlayerGravity)
event.register("loaded", togglePlayerGravity)

---@param e referenceActivatedEventData
event.register("referenceActivated", function(e)
    local validObjectTypes = {
        [tes3.objectType.creature] = true,
        [tes3.objectType.npc] = true,
    }
    if not validObjectTypes[e.reference.baseObject.objectType] then
        return
    end
    if ShardCell.isOnShard(e.reference) then
        Gravity.enableLowGravity(e.reference)
    end
end)

---@param e damageEventData
event.register("damage", function(e)
    if ShardCell.isOnShard(e.reference) then
        if e.source == tes3.damageSource.fall then
            logger:trace("Preventing fall damage")
            e.damage = 0
        end
    end
end)