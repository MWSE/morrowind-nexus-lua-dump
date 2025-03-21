--[[
    Event handler for equipping bait
]]

local common = require("mer.fishing.common")
local logger = common.createLogger("BaitEventHandler")
local Bait = require("mer.fishing.Bait.Bait")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local CraftingFramework = require("CraftingFramework")
local TileDropper = CraftingFramework.TileDropper
TileDropper.register{
    name = "BaitEquip",
    logger = logger,
    isValidTarget = function(e)
        return FishingRod.isFishingRod(e.item)
    end,
    canDrop = function(e)
        if not FishingStateManager.isState("IDLE") then return false end
        local bait = Bait.get(e.held.item.id)
        if not bait then return false end
        local data = e.held.itemData and e.held.itemData.data or nil
        if Bait.isCooked(data) then return false end
        return true
    end,
    onDrop = function(e)
        logger:debug("Dropped bait %s onto %s", e.held.item.id, e.target.item.id)
        local bait = Bait.get(e.held.item.id)
        if not bait then
            logger:warn("Failed to get bait from %s", e.held.item.id)
            return
        end
        local fishingRod = FishingRod.new{
            item = e.target.item,
            itemData = e.target.itemData
        }
        if fishingRod == nil then
            logger:warn("Failed to create fishing rod from %s", e.target.item.id)
            return
        end
        fishingRod:equipBait(bait, e.reference)
    end
}