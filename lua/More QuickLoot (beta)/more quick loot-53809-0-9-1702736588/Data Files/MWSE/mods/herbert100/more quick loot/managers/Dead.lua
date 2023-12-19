local Class, base = require("herbert100.Class"), require("herbert100.more quick loot.managers.abstract.base")
-- local log = require("herbert100.Logger")(require("herbert100.more quick loot.defns"))
local config = require("herbert100.more quick loot.config")
local defns = require("herbert100.more quick loot.defns")
local log = require("herbert100.Logger")(defns)


-- this container will be called on dead things. it will allow dead creates to be disposed, based on config settings.
---@class MQL.Manager.Dead : MQL.Manager
---@field cant_loot MQL.defns.cant_loot? if not `nil`, explains why this Manager can't loot
---@field cant_loot_actions table<MQL.defns.cant_loot, fun(self: MQL.Manager.Dead)> what to do for certain cant loot reasons.
---@field trap tes3spell? records any trap that may be on the container
local Dead = Class{name="Dead Manager", parents={base}}

--update the cant_loot_actions
Dead.cant_loot_actions = base.cant_loot_actions .. {
    ---@param self MQL.Manager.Dead
    [defns.cant_loot.empty] = function(self)
        -- kill it if we're told to
        if config.dead.dispose == defns.dispose.auto then 
            self:destroy_container()
        else
            -- change the button name if told to
            if config.dead.dispose == defns.dispose.take_all then
                self.gui:update_control_labels({take_all = "Dispose"})
            end
            self.gui:block_and_show_msg("Empty")
        end
    end,
}

-- Takes all items from the current target.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean looted_successfully `true` if the container was looted successfully, false otherwise
function Dead:take_all_items(modifier_pressed)
    log("DEAD: calling take item with modifier_pressed = " .. tostring(modifier_pressed))
    -- dispose of dead things by pressing the "Take All" button, but the relevant config option is chosen.
    if self.cant_loot == defns.cant_loot.empty and config.dead.dispose == defns.dispose.take_all then
        self:destroy_container()
        return true
    end

    -- then call the generic method
    return base.take_all_items(self, modifier_pressed)
end




return Dead