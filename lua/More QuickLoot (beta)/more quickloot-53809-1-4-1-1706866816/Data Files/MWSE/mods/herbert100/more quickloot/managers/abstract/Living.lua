---@diagnostic disable: undefined-field
local Class, base = require("herbert100.Class"), require("herbert100.more quickloot.managers.abstract.base")
local defns = require "herbert100.more quickloot.defns"
local log = require("herbert100.Logger")("More QuickLoot/Living")
-- local log = require("herbert100.logger") ("More QuickLoot/Living")
---@class MQL.Managers.Living : MQL.Manager
---@field allow_equipped table<tes3.objectType, boolean>? whether certain object types should be shown if equipped
---@field allow_equipped_slots table<tes3.clothingSlot, boolean>? whether things equipped in certain item slots should be allowed
local Living = Class.new{name="Living", parents={base}}

-- we should stop updating each frame if: 
-- 1) the person we're looking at doesn't exist,
-- 2) the person we're looking at is not alive, or 
-- 3) we are sneaking
function Living:on_simulate()
    return self.ref ~= nil                          -- container exists
        and self.ref.isDead == false                -- target is alive
        and tes3.mobilePlayer ~= nil                -- player mobile exists
        and tes3.mobilePlayer.isSneaking ~= true    -- player is not sneaking
end



---@param equipped_cfg MQL.config.equipped
---@return MQL.Item.obj_filter_fun
function Living:make_equipped_filter(equipped_cfg)
    do -- define the function
        local cfg = equipped_cfg
        if not cfg then
            log:error("self.config.equipped is nil. why is this happening.... using barter config as a fallback")
            cfg = require("herbert100.more quickloot.config").barter.equipped
        end
        local weapon, clothing, armor, l_glove, r_glove, belt, ring, amulet =
            tes3.objectType.weapon,
            tes3.objectType.clothing,
            tes3.objectType.armor,
            tes3.clothingSlot.leftGlove,
            tes3.clothingSlot.rightGlove,
            tes3.clothingSlot.belt,
            tes3.clothingSlot.ring,
            tes3.clothingSlot.amulet
        return function(obj)
            local obj_type = obj.objectType ---@type tes3.objectType

            -- we're splitting this up into a bunch of if statements for better branch control
            if obj_type == weapon then 
                if cfg.weapons then return true, defns.item_status.ok end
            elseif obj_type == armor then
                if cfg.armor then return true, defns.item_status.ok end
            
            elseif obj_type == clothing then ---@cast obj tes3clothing
                
                -- we're doing it this way so that jewelry and accessories can override the clothing setting
                if obj.slot == amulet or obj.slot == ring then
                    if cfg.jewelry then return true, defns.item_status.ok end

                elseif obj.slot == l_glove or obj.slot == r_glove or obj.slot == belt then
                    if cfg.accessories then return true, defns.item_status.ok end

                else
                    if cfg.clothing then return true, defns.item_status.ok end

                end
            end
            if cfg.show then
                return true, defns.item_status.unavailable, defns.unavailable_reason.equipped
            else
                return false
            end
        end
    end
end

return Living