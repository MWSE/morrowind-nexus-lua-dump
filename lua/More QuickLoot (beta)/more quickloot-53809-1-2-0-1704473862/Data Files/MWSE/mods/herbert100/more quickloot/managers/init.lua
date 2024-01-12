local Class = require("herbert100.Class")
local base =  require("herbert100.more quickloot.managers.abstract.base")
local config = require("herbert100.more quickloot.config")
local defns = require("herbert100.more quickloot.defns")
local log = require("herbert100.logger")("More QuickLoot/Regular") ---@type herbert.Logger

-- we will define the `Dead` and `Inanimate` managers here because they differ so little from the `base` manager

-- =============================================================================
-- DEAD MANAGER
-- =============================================================================

-- this container will be called on dead things. it will allow dead creates to be disposed, based on config settings.
---@class MQL.Manager.Dead : MQL.Manager
---@field trap tes3spell? records any trap that may be on the container
local Dead = Class{name="Dead Manager", parents={base}}

do -- define `Dead` methods and fields


function Dead:do_cant_loot_action()
    -- if the reason isn't that the container is empty, do the default behavior
    if self.cant_loot ~= defns.cant_loot.empty then base.do_cant_loot_action(self); return end

    if config.dead.dispose == defns.dispose.auto then 
        self:destroy_container()
    else
        -- change the button name if told to
        if config.dead.dispose == defns.dispose.take_all then
            self.gui:set_control_labels({take_all = "Dispose"})
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
        self:destroy_container()
        return true
    end

    -- then call the generic method
    return base.take_all_items(self, modifier_pressed)
end

end -- define `Dead` methods and fields





-- =============================================================================
-- INANIMATE MANAGER
-- =============================================================================

-- the container that will be used on inanimate objects, such as chests and barrels.
-- it will basically function the same way as the `base` manager, but it will now take into account whether containers are "locked" or "trapped"
-- this should take into account things being locked or trapped.
---@class MQL.Manager.Inanimate : MQL.Manager
---@field taking boolean? are we taking items or placing items?
---@field locked boolean? is the container currently locked?
---@field trap tes3spell? records any trap that may be on the container
local Inanimate = Class({name="Inanimate Manager", parents={base}}, {taking=true})

do -- define `Inanimate` methods and fields
-- local ac_interop = include('MWCA.interop2') ---@type AC.interop

function Inanimate:_get_container_label()
    local descriptor
    if self.locked then
        descriptor = "Locked"
    elseif self.trap then
        descriptor = "Trapped"
    elseif self.taking then
        return self.ref.object.name
        -- descriptor = "Looting"
    else
        descriptor = "Storing"
    end
    return string.format("%s (%s)", self.ref.object.name, descriptor)
end

function Inanimate:_initialize()
    -- used for AC compatibility
    if config.compat.ac then
        self.ref_handle = tes3.makeSafeObjectHandle(self.ref)
    end
    
end
function Inanimate:_get_status_text()
    local text = base._get_status_text(self)
    if self.taking then
        return text
    else
        if text then
            return string.format("%s | Capacity: %.1f/%i", text, self.ref.object.inventory:calculateWeight(), self.ref.object.capacity)
        end
        return string.format("Capacity: %.1f/%i", self.ref.object.inventory:calculateWeight(), self.ref.object.capacity)
    end
end

function Inanimate:update_cant_loot()
    base.update_cant_loot(self) -- do default tests, then check for locks/traps
    self.locked = nil
    self.trap = nil

    -- only proceed if `cant_loot` is `nil` or `empty` (because locked/trapped should take precedence over being empty)
    if not (self.cant_loot == nil or self.cant_loot == defns.cant_loot.empty) then return end
    
    local lock_node = self.ref.lockNode
    if not lock_node then return end

    -- if we pass the relevant checks
    local passed_trap_check, passed_lock_check = true, true


    local security = tes3.mobilePlayer.security.current

    self.locked = lock_node.locked
    if self.locked then
        passed_lock_check = config.inanimate.show_locked 
                            and security >= config.inanimate.show_locked_min_security 
                            and (security - security % 25) >= lock_node.level -- break it up into multiples of 25
    end
    
    self.trap = lock_node.trap
    if self.trap then
        passed_trap_check = config.inanimate.show_trapped and security >= config.inanimate.show_trapped_min_security
    end

    if passed_lock_check == false or passed_trap_check == false then
        self.cant_loot = defns.cant_loot.other
        return
    end

end
--[[ animated containers stuff. coming soon! (hopefully)
function Inanimate:ac_close()
    if not self.ac_opened then return end
    ac_interop.play_close_animation(self.ref, true) 
    self.ac_opened = false
end

function Inanimate:ac_open()
    if self.ac_opened or self.locked or self.trap then return end
    ac_interop.play_open_animation(self.ref, true) 
    self.ac_opened = true
end

function Inanimate:self_destruct()
    if config.compat.ac and self.ref_handle:valid() then
        self:ac_close()
    end
    base.self_destruct(self)
end
]]
function Inanimate:do_cant_loot_action()
    if self.cant_loot == defns.cant_loot.other then
        if self.locked then
            self.gui:block_and_show_msg("Lock Level: " .. self.ref.lockNode.level)
        elseif self.trap then
            self.gui:block_and_show_msg("Trapped")
        else
            log:error("didnt fail lock or trap check, but cant_loot is set to other")
        end
    elseif self.cant_loot == defns.cant_loot.disabled then
        self.gui:hide()
        -- if config.compat.ac then self:ac_close() end
    else
        base.do_cant_loot_action(self)
    end
end



--- makes the manager update the status of the container it's managing. this is useful to checking if the container is empty, locked, etc
-- this will end up getting called after an item is taken, because the target will temporarily be set to `nil`
function Inanimate:update(force_remake_items)
    log:debug("updating container status")

    self:update_cant_loot()

    if self.cant_loot then
        self:do_cant_loot_action()
        return
    end

    -- now we know we can loot

    self.gui:show()
    local item_changed = false

    if self.locked then
        for _, item in ipairs(self.items) do
            if item.status == defns.item_status.ok then
                item_changed = true
                item.status = defns.item_status.unavailable_temp
                item.unavailable_reason = "Container is locked!"
            end
        end
    else
        for _, item in ipairs(self.items) do
            if item.status == defns.item_status.unavailable_temp then
                item_changed = true
                item.status = defns.item_status.ok
                item.unavailable_reason = nil
            end
        end
    end
    self.gui:set_name_label(self:_get_container_label())
    self.gui:set_status_label(self:_get_status_text())

    -- if config.compat.ac then self:ac_open() end 

    if self.gui.blocked or force_remake_items then
        self.gui:make_item_blocks(self.items)
        self.index = 0
        self:increment_index(true)
        return
    elseif item_changed then
        self.gui:update_visible_items(self.index)
    end
end



--- takes the currently activated item. also checks if the item can be looted, and if we're currently in a menu.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean # `true` if the item was taken successfully (or a trap was activated), `false` otherwise.
function Inanimate:take_item(modifier_pressed)

    -- if we're blocking because of a lock/trap, or if we can see inside the container
    if self.cant_loot == nil or self.cant_loot == defns.cant_loot.other then
        if self.locked then
            if self.cant_loot == nil then 
                tes3.messageBox("This container is locked!")
            end
            return false
        end

        -- container isnt locked
        if self.trap then
            tes3.cast{reference = self.ref, target = tes3.player, spell = self.trap }
            self.ref.lockNode.trap = nil
            -- dont do anything else if we cant actually see inside the container
            if self.cant_loot == defns.cant_loot.other then
                self:update()
                return true
            end
            self:update()
        end
    end

    -- now we do the normal behavior
    return base.take_item(self,modifier_pressed)
    
end


-- do the normal `take_all_items` behavior, but check for locks/traps first.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean looted_successfully `true` if the container was looted successfully, false otherwise
function Inanimate:take_all_items(modifier_pressed)
    -- if we're blocking because of a lock/trap, or if we can see inside the container
    if self.cant_loot == nil or self.cant_loot == defns.cant_loot.other then
        if self.locked then
            if self.cant_loot == nil then 
                tes3.messageBox("This container is locked!")
            end
            return false
        end

        -- container isnt locked
        if self.trap then
            tes3.cast{reference = self.ref, target = tes3.player, spell = self.trap }
            self.ref.lockNode.trap = nil

            -- dont do anything else if we cant actually see inside the container
            if self.cant_loot == defns.cant_loot.other then
                self:update()
                return true
            end
            self:update()
        end
    end
    return base.take_all_items(self,modifier_pressed)
end



-- this will look for similar containers when `taking`, and it will iterate through the player's inventory when `not taking` (skipping over equipped items)
---@return MQL.Item.iter_container.params
function Inanimate:_get_iter_params()
    local ref, check_equipped, obj_filter, search_nearby

    local pcfg = config.inanimate.placing
    if self.taking then
        ref = self.ref
        search_nearby = {
            container_filter = config.reg.sn_cf,
            owned_by = {self.stealing_from},
            dist = config.reg.sn_dist,
        }
    else
        ref = tes3.player
        check_equipped = true
        local book, ingredient = tes3.objectType.book, tes3.objectType.ingredient
        obj_filter = function (obj)
            return (pcfg.allow_books or obj.objectType ~= book) 
                and (pcfg.allow_ingredients or obj.objectType ~= ingredient) 
                and obj.weight >= pcfg.min_weight
        end
    end

    ---@type MQL.Item.iter_container.params
    return { ref = ref, search_nearby = search_nearby, check_equipped=check_equipped, obj_filter=obj_filter}
end

-- this switches between taking and placing items, provided the container isn't trapped/locked
function Inanimate:modified_open()
    if self.locked then
        tes3.messageBox("You can't store items in locked containers.")
    elseif self.trap then
        tes3.messageBox("You can't store items in trapped containers.")
    else
        self.taking = not self.taking

        if self.taking then
            self.transfer_to = tes3.player
        else
            self.transfer_to = self.ref
        end
        self:remake_items()
    end
    return true
end

-- this is getting changed so that we sort items in reverse when storing items
function Inanimate:_sort_items()
    local Physical_Item = require("herbert100.more quickloot.Item").Physical
    local sort_items = config.UI.sort_items
    local comp

    if sort_items == defns.sort_items.value_weight_ratio then
        if not config.compat.bg or tes3.mobilePlayer.mercantile.current >= include("buyingGame.common").config.knowsPrice then
            comp = Physical_Item.value_weight_comp
        end
    elseif sort_items == defns.sort_items.value then
        if not config.compat.bg or tes3.mobilePlayer.mercantile.current >= include("buyingGame.common").config.knowsPrice then
            comp = Physical_Item.value_comp
        end
    elseif sort_items == defns.sort_items.weight then
        comp = Physical_Item.weight_comp
    end
    if not comp then return end

    if not self.taking or not config.inanimate.placing.reverse_sort then
        local old_comp = comp
        comp = function(a,b) return old_comp(b,a) end
    end

    table.sort(self.items, comp)
end



end -- define `Inanimate` methods and fields


-- =============================================================================
-- RETURN MANAGER LIST
-- =============================================================================

---@class MQL.Manager_List
local Manager_List = {
    Dead = Dead,                                                            ---@type MQL.Manager.Dead
    Inanimate = Inanimate,                                                  ---@type MQL.Manager.Inanimate
    Pickpocket = require("herbert100.more quickloot.managers.Pickpocket"),  ---@type MQL.Manager.Pickpocket
    Organic = require("herbert100.more quickloot.managers.Organic"),        ---@type MQL.Manager.Organic
    Services = require("herbert100.more quickloot.managers.Services")       ---@type MQL.Manager.Services
}



return Manager_List ---@type MQL.Manager_List

