---@diagnostic disable: undefined-field
local Class, base = require("herbert100.Class"), require("herbert100.more quickloot.managers.abstract.base")
local defns = require "herbert100.more quickloot.defns"
-- local log = require("herbert100.logger") ("More QuickLoot/Living")
---@class MQL.Managers.Living : MQL.Manager
---@field allow_equipped table<tes3.objectType, boolean>? whether certain object types should be shown if equipped
---@field allow_equipped_slots table<tes3.clothingSlot, boolean>? whether things equipped in certain item slots should be allowed
local Living = Class.new({name="Living", parents={base}})

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


local weapon, clothing, armor, l_glove, r_glove, belt, ring, amulet =
    tes3.objectType.weapon,
    tes3.objectType.clothing,
    tes3.objectType.armor,
    tes3.clothingSlot.leftGlove,
    tes3.clothingSlot.rightGlove,
    tes3.clothingSlot.belt,
    tes3.clothingSlot.ring,
    tes3.clothingSlot.amulet

function Living:do_equipped_check(item, unavailable_msg)
    if not item.equipped or item.status < defns.item_status.unavailable then return end

    if item.status == defns.item_status.unavailable then
        item.status = defns.item_status.ok
        item.unavailable_reason = nil
    end

    local obj_type = item.object.objectType ---@type tes3.objectType

    -- we're splitting this up into a bunch of if statements for better branch control
    if obj_type == weapon then 
        if self.config.equipped.weapons then return end
    elseif obj_type == armor then
        if self.config.equipped.armor then return end
    
    elseif obj_type == clothing then
        local obj = item.object ---@type tes3clothing

        -- we're doing it this way so that jewelry and accessories can override the clothing setting
        if obj.slot == amulet or obj.slot == ring then
            if self.config.equipped.jewelry then return end
        elseif obj.slot == l_glove or obj.slot == r_glove or obj.slot == belt then
            if self.config.equipped.accessories then return end
        else
            if self.config.equipped.clothing then return end
        end
    end
    if self.config.equipped.show then
        item.status = defns.item_status.unavailable
        item.unavailable_reason = unavailable_msg or "This item is equipped!"
    else
        item.status = defns.item_status.deleted
    end
end


return Living