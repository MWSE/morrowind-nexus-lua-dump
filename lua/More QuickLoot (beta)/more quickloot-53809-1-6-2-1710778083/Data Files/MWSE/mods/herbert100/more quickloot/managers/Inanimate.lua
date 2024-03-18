local base =  require("herbert100.more quickloot.managers.abstract.base")
local config = require("herbert100.more quickloot.config")
local defns = require("herbert100.more quickloot.defns")

local log = Herbert_Logger() ---@type herbert.Logger


local ac_interop = include("herbert100.animated containers.interop") ---@type herbert.AC.interop
local ac_defns = defns.misc.ac
local ac_cfg = config.inanimate.ac
local bg_cfg --- buying game config
event.register("initialized", function(e)
    local bg_common = include("buyingGame.common")
    bg_cfg = bg_common and bg_common.config
end, {priority=-2000, doOnce=true})

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
---@field ac_ever_opened boolean whether we ever opened this animated container. this is so that we dont open it more than once
local Inanimate = Herbert_Class.new{name="Inanimate Manager", parents={base},
    fields={
        {"taking", default=true},
        {"locked", default=false},
        {"trap", },
        {"ac_ever_opened", default=false}
    },
    init = function (self, ref)
        base.__secrets.init(self,ref)
        if ac_interop then
            -- mark the container as having been opened if it's open when the manager is created
            self.ac_ever_opened = ac_interop.get_container_state(ref) >= 3
        end
    end
}


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
    return string.format("%s (%s)", base._get_container_label(self), descriptor)
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
function Inanimate:undo()
    base.undo(self)
    if not self.taking then
        self:update_status_label()
    end
end

function Inanimate:ac_try_to_close()
    if ac_interop 
    and self.ref_handle:valid() 
    and ac_cfg.close ~= ac_defns.close.never 
    and (ac_cfg.auto_close_if_empty or #self.ref.object.inventory.items > 0)
    then
        local use_cfg = (ac_cfg.close == ac_defns.close.use_ac_cfg)
        log("trying to close container with use_cfg = %s. container = %s", use_cfg, self.ref)
        if ac_interop.try_to_close(self.ref, use_cfg) then
            self.ac_ever_opened = false
        end
    end
end

-- function Inanimate:get_m_keylabels()
--     return self.taking and {}
-- end

function Inanimate:self_destruct()
    self:ac_try_to_close()
    base.self_destruct(self)
end

function Inanimate:disable()
    base.disable(self)
    self:ac_try_to_close()
    -- self.cant_loot = defns.cant_loot.disabled
    -- if self.inventory_outdated and config.UI.update_inv_on_close then
    --     tes3ui.forcePlayerInventoryUpdate()
    --     self.inventory_outdated = false
    -- end
    -- self.gui:hide()
end

function Inanimate:do_cant_loot_action()
    if self.cant_loot == defns.cant_loot.other then
        if self.locked then
            self.gui:block_and_show_msg("Lock Level: " .. self.ref.lockNode.level)
        elseif self.trap then
            self.gui:block_and_show_msg("Trapped")
        else
            log:error("didnt fail lock or trap check, but cant_loot is set to other")
        end
    -- elseif self.cant_loot == defns.cant_loot.disabled then
    --     self.gui:hide()
    --     self:ac_try_to_close()
    --     -- if config.compat.ac then self:ac_close() end
    else
        if ac_interop and ac_cfg.open_empty_on_sight and self.cant_loot == defns.cant_loot.empty then
            self:ac_try_to_open(ac_defns.open.on_sight)
        end
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
    
    -- if animated containers is installed, open the container
    -- we're doing this here to handle the special case where the container was locked and then got unlocked
    -- this will only open the container if it's closed, and if it can be opened
    if ac_interop then self:ac_try_to_open(ac_defns.open.on_sight) end

    self.gui:show()
    local item_changed = false

    if self.locked then
        for _, item in ipairs(self.items) do
            if item.status == defns.item_status.ok then
                item_changed = true
                item.status = defns.item_status.unavailable_temp
                item.unavailable_reason = defns.unavailable_reason.locked
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
    self:update_status_label()
    self:update_GUI_label()


    if self.gui.blocked or force_remake_items then
        self:remake_GUI_items()
    elseif item_changed then
        self.gui:update_visible_items(self.index)
    end
end

--- try to open an animated container
---@param lvl MQL.defns.misc.ac.open    
function Inanimate:ac_try_to_open(lvl)
    if ac_interop
    and not self.ac_ever_opened -- make sure we don't open a container twice (unless the menu gets remade)
    and ac_cfg.open >= lvl      -- make sure the config settings allow the container to be opened in this way
    and not self.trap           -- make sure the container isn't trapped
    and not self.locked         -- make sure the contaienr isn't locked
    then
        log("trying to AC open container with level: %s", lvl)
        -- politely ask animated containers to open the container
        self.ac_ever_opened = ac_interop.try_to_open(self.ref)
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
    if base.take_item(self, modifier_pressed) then
        self:ac_try_to_open(ac_defns.open.item_taken)
        if not self.taking then
            self:update_status_label()
        end
        return true
    end
    return false
    
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
    if base.take_all_items(self, modifier_pressed) then
        self:ac_try_to_open(ac_defns.open.item_taken)
        return true
    end
    return false
end




function Inanimate:_make_items()
    if self.taking then
        base._make_items(self)
        return
    end

    local banned_types = {
        [tes3.objectType.book] = not config.inanimate.placing.allow_books,
        [tes3.objectType.ingredient] = not config.inanimate.placing.allow_ingredients,
    }
    local min_weight = config.inanimate.placing.min_weight

    self:add_items(tes3.player, self.ref, function(obj)
        return not banned_types[obj.objectType] and obj.weight >= min_weight
    end)
end

-- this switches between taking and placing items, provided the container isn't trapped/locked
function Inanimate:modified_open()
    if self.locked then
        tes3.messageBox("You can't store items in locked containers.")
    elseif self.trap then
        tes3.messageBox("You can't store items in trapped containers.")
    else
        self:play_switch_sound()
        self.taking = not self.taking
        self:make_items()
        self:update_GUI_label()
        self:update_status_label()
        self:update(true)
    end
    return true
end

-- this is getting changed so that we sort items in reverse when storing items
function Inanimate:_sort_items()
    local Physical_Item = require("herbert100.more quickloot.Item").Physical

    local sort_items = config.UI.sort_items
    local comp

    if sort_items == defns.sort_items.dont then return end

    if sort_items == defns.sort_items.weight then
        comp = Physical_Item.weight_comp
        goto taking_check
    end

    if bg_cfg and tes3.mobilePlayer.mercantile.current < bg_cfg.knowsPrice then 
        return
    end

    if sort_items == defns.sort_items.value_weight_ratio then
        comp = Physical_Item.value_weight_comp
    else
        comp = Physical_Item.value_comp
    end

    ::taking_check::
    if not self.taking or not config.inanimate.placing.reverse_sort then
        local old_comp = comp
        comp = function(a,b) return old_comp(b,a) end
    end

    table.sort(self.items, comp)
end


return Inanimate