local Class, base = require("herbert100.Class"), require("herbert100.more quick loot.managers.abstract.base")
-- local log = require("herbert100.Logger")(require("herbert100.more quick loot.defns"))
local config = require("herbert100.more quick loot.config")
local defns = require("herbert100.more quick loot.defns")
local log = require("herbert100.Logger")(defns)

-- the container that will be used on inanimate objects, such as chests and barrels.
-- it will basically function the same way as the `base` manager, but it will now take into account whether containers are "locked" or "trapped"
-- this should take into account things being locked or trapped.
---@class MQL.Manager.Inanimate : MQL.Manager
---@field cant_loot MQL.defns.cant_loot? if not `nil`, explains why this Manager can't loot
---@field cant_loot_actions table<MQL.defns.cant_loot, fun(self: MQL.Manager.Inanimate)> what to do for certain cant loot reasons.
---@field trap tes3spell? records any trap that may be on the container
local Inanimate = Class{name="Inanimate Manager", parents={base}}

--update the cant_loot_actions
Inanimate.cant_loot_actions = base.cant_loot_actions .. {
    --[[ shouldn't need this now that we forked the `dead` manager
    [defns.cant_loot.empty] = function(self)
        self.gui:block_and_show_msg("Empty")
        if self.ref.isDead == true then
            self.gui:update_control_labels({take_all = "Dispose"})
        end
    end,
    ]]
    [defns.cant_loot.locked] = function(self) self.gui:block_and_show_msg("Lock Level: " .. self.ref.lockNode.level) end,

    [defns.cant_loot.trapped] = function(self) self.gui:block_and_show_msg("Trapped") end,
}

--- do manager specific checks to see if you can't loot something
---@return boolean obstacle_found `true` if an obstacle was found, `false` otherwise.
function Inanimate:_do_additional_cant_loot_checks() 
    local lock_node = self.ref.lockNode
    if lock_node then
        self.trap = lock_node.trap -- could be `nil`
        if lock_node.locked then 
            self.cant_loot = defns.cant_loot.locked
            return true
        end

        if self.trap and config.inanimate.show_trapped == false then
            self.cant_loot = defns.cant_loot.trapped
            return true
        end
    end

    return false

end




--- takes the currently activated item. also checks if the item can be looted, and if we're currently in a menu.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean # `true` if the item was taken successfully (or a trap was activated), `false` otherwise.
function Inanimate:take_item(modifier_pressed)
    log("INANIMATE: calling take item with modifier_pressed = " .. tostring(modifier_pressed))
    -- check for traps first
    if self.trap ~= nil then 
        tes3.cast{reference = self.ref, target = tes3.player, spell = self.trap }
        self.ref.lockNode.trap = nil

        if self.cant_loot == defns.cant_loot.trapped then 
            self:update_container_status()
            return true
        end
    end
    -- then call the generic method
    return base.take_item(self,modifier_pressed)
end


-- Takes all items from the current target.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean looted_successfully `true` if the container was looted successfully, false otherwise
function Inanimate:take_all_items(modifier_pressed)
    -- log("INANIMATE: calling take all items with modifier_pressed = " .. tostring(modifier_pressed))

     -- check for traps first
     if self.trap ~= nil then 
        tes3.cast{reference = self.ref, target = tes3.player, spell = self.trap }
        self.ref.lockNode.trap = nil

        if self.cant_loot == defns.cant_loot.trapped then 
            self:update_container_status()
            return true
        end
    end

    -- then call the generic method
    return base.take_all_items(self,modifier_pressed)
end




return Inanimate