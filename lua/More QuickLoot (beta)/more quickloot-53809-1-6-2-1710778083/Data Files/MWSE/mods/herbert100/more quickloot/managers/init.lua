local base =  require("herbert100.more quickloot.managers.abstract.base")
local config = require("herbert100.more quickloot.config")
local defns = require("herbert100.more quickloot.defns")

-- we will define the `Dead` and `Inanimate` managers here because they differ so little from the `base` manager

-- =============================================================================
-- DEAD MANAGER
-- =============================================================================

-- this container will be called on dead things. it will allow dead creates to be disposed, based on config settings.
---@class MQL.Manager.Dead : MQL.Manager
local Dead = Herbert_Class{name="Dead Manager", parents={base}}

do -- define `Dead` methods and fields


function Dead:do_cant_loot_action()
    -- if the reason isn't that the container is empty, do the default behavior
    if self.cant_loot ~= defns.cant_loot.empty then base.do_cant_loot_action(self); return end

    if config.dead.dispose == defns.dispose.auto then 
        self.ref:disable()
    else
        -- change the button name if told to
        if config.dead.dispose == defns.dispose.take_all then
            self.gui.key_label:update_labels{take_all = "Dispose"}
        end
        self.gui:block_and_show_msg("Empty")
    end
    if self.inventory_outdated and config.UI.update_inv_on_close then
        self.inventory_outdated = false
        tes3ui.forcePlayerInventoryUpdate()
    end
end



-- Takes all items from the current target.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean looted_successfully `true` if the container was looted successfully, false otherwise
function Dead:take_all_items(modifier_pressed)
    -- dispose of dead things by pressing the "Take All" button, but the relevant config option is chosen.
    if self.cant_loot == defns.cant_loot.empty and config.dead.dispose == defns.dispose.take_all then
        self.ref:disable()
        return true
    end

    -- then call the generic method
    return base.take_all_items(self, modifier_pressed)
end

function Dead:_make_items()
    self:add_items()

    if config.reg.sn_cf == defns.sn_cf.no_other_containers or (config.reg.sn_dist and config.reg.sn_dist <= 5) then 
        return
    end

    local dist, v_dist = config.reg.sn_dist^2, config.advanced.v_dist
    local name = self.ref.baseObject.name
    local pos = self.ref.position

    for ref in tes3.player.cell:iterateReferences(self.ref.object.objectType) do
        if not ref.isDead then goto next_ref end

        local ref_pos = ref.position

        if (pos.x - ref_pos.x)^2 + (pos.y - ref_pos.y)^2 > dist 
        or math.abs(pos.z - ref_pos.z) > v_dist
        or name ~= ref.baseObject.name
        or ref == self.ref
        then goto next_ref end
        ref:clone()
        self:add_items(ref)
        ::next_ref::
    end
end

end -- define `Dead` methods and fields







-- =============================================================================
-- RETURN MANAGER LIST
-- =============================================================================

---@class MQL.Manager_List
local Manager_List = {
    Dead = Dead,                                                            ---@type MQL.Manager.Dead
    Inanimate = require('herbert100.more quickloot.managers.Inanimate'),    ---@type MQL.Manager.Inanimate
    Pickpocket = require("herbert100.more quickloot.managers.Pickpocket"),  ---@type MQL.Manager.Pickpocket
    Organic = require("herbert100.more quickloot.managers.Organic"),        ---@type MQL.Manager.Organic
    Services = require("herbert100.more quickloot.managers.Services")       ---@type MQL.Manager.Services
}



return Manager_List ---@type MQL.Manager_List
