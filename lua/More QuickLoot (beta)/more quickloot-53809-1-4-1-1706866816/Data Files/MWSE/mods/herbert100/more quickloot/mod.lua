--[[
    More QuickLoot. An updated QuickLoot mod based on the original QuickLoot mod by mort.
    Version 1.2
    Author: herbert100
    
    Original QuickLoot author: mort
]] --



-- this file kind of hurts to look at. things got out of hand here

local hlib = require("herbert100")

---@diagnostic disable-next-line: assign-type-mismatch
local log = hlib.Logger("More QuickLoot/main") ---@type herbert.Logger
local update_registration = hlib.update_registration



local defns = require("herbert100.more quickloot.defns")

local common = require("herbert100.more quickloot.common")

local config = require("herbert100.more quickloot.config")

local mcm = require("herbert100.more quickloot.mcm")


local GUI = require("herbert100.more quickloot.GUI")

local managers = require("herbert100.more quickloot.Managers") ---@type MQL.Manager_List




-- keybindings. we're saving this here so that we can properly update the button press events when they change
-- (we need to unregister the old keybindings before registering the new ones)
---@type tes3.scanCode, tes3.scanCode, tes3.scanCode, tes3.scanCode, mwseKeyCombo
local take_all_keycode, custom_keycode, modifier_keycode, activate_keycode, undo_key


local event_callbacks = {}



local this = {
    target = nil,                       ---@type tes3reference?
    manager = nil,                      ---@type MQL.Manager?
    was_sneaking = false,               ---@type boolean were you sneaking in the last frame?
    monitoring_pickpocketing = false,   ---@type boolean are we checking to see if pickpocketing should happen?
    checking_service = false,           ---@type boolean `false` if we arent checking a service. otherwise, it's the type of service we're checking for
    service_override = false,           ---@type boolean only `true` if a service was denied and we're ignoring that decision
    event_callbacks = event_callbacks,
}


---@param e dialogueFilteredEventData
function event_callbacks.skooma_filter(e)
    -- only do stuff when we are checking a service and we got a skooma rejection
    if this.checking_service and common.skooma_dialogue_ids[e.info.id] then 
        log ("we're checking a service and got a skooma rejection. checking_service = %s.", this.checking_service)

        -- if we're bartering and we don't want skooma to stop that, or if we're training and we don't want skooma to stop that
        if config.services.allow_skooma then
            -- set the service override to true so we can still make the manager
            this.service_override = true
        end
        -- mark that we're no longer checking a service
        this.checking_service = false
        -- block the event. we're doing this even if `allow_skooma == false` so that we stop mods from acting on this skooma event.
        return false
    end
    -- log "we failed the checkservice or dialogue id check"
end




--- makes sure the current target and manager are still valid
---@return boolean still_valid  
function this.is_manager_valid()
    if this.manager and this.manager.ref_handle:valid() then
        return true
    else
        this.kill_manager()
        return false
    end
end
---@deprecated
this.check_manager_is_valid = this.is_manager_valid



do -- define functions that run every frame (while certain conditions are met)

--[[this should only run while you are not sneaking and currently looking at an alive NPC.
its purpose is to create a Pickpocket manager once you start sneaking.

this function should be deregistered once any of the following three things happen: 
1) you stop looking at the NPC
2) the NPC dies
3) you start sneaking
]]
    function this.pickpocketing_check()
        -- if we're not looking at anything, or if the thing we're looking at isn't alive,
        -- or if the thing we're looking at isn't an NPC
        if this.target == nil
            or this.target.isDead ~= false
            or (this.target.object.objectType ~= tes3.objectType.npc and this.target.object.objectType ~= tes3.objectType.mobileNPC)
            -- or config.pickpocket.enable == false -- we dont really have to check since this event gets unregistered when menus open
        then
            goto unregister
        end

        -- if we're not sneaking (but we're looking at a valid target), then we should check again next frame
        if tes3.mobilePlayer.isSneaking == false then return end

        --[[ if we reach this point of the function call, we know three things:
                1) we're looking at an NPC
                2) that NPC is alive
                3) we're sneaking
            so, we should kill the active manager (if it exists), and create a new Pickpocket manager.
        ]]

        this.kill_manager() -- has a builtin `nil` check

        -- make a new `Pickpocket` manager and register its monitoring event
        this.manager = managers.Pickpocket(this.target)
        if this.manager.on_simulate ~= nil then
            if log.level == 5 then log:trace("in pickpocket check: registering Pickpocket simulate event") end
            event.register(tes3.event.simulate, this.monitor_manager, {priority=config.advanced.simulate_priority})
        end

        -- putting this here will ensure this function gets unregistered one the new pickpocketing manager is created.
        ::unregister::
        if log.level == 5 then log:trace("unregistering pickpocketing check") end

        update_registration{event=tes3.event.simulate, callback=this.pickpocketing_check, register=false, 
            priority=config.advanced.simulate_priority
        }
    end


--[[this function will run every frame that certain managers are active. 
it allows a `Manager` to specify things they would like to do every frame through an `on_simulate` function. 
An `on_simulate` function should return a boolean value `keep_going`.
If the manager's `on_simulate` function returns `false`, this signifies that the manager should be destroyed. 

so basically, the purpose of this function is to perform the manager's `on_simulate` function, and ensure that it can be destroyed
if it's no longer in a valid state.

currently, it's used as follows:
- `Pickpocket` uses this to update the detection status of the player, and to make sure that:
    1) the person being pickpocketed still exists
    2) the person being pickpockted is still alive
    3) we are still sneaking
- `Living` managers (other than `Pickpocket`) use this to signal they want to die whenever one of three things happens:
    1) the NPC reference disappears
    2) the NPC dies
    3) we start sneaking
]]
    function this.monitor_manager()
        -- if the manager isn't valid, try to find a new one
        if not this.is_manager_valid() then
            this.update_active_manager(false)
            return
        end

        -- prod our manager and see if he wants to die yet
        local keep_going = this.manager:on_simulate()

        if keep_going == false then
            if log.level == 5 then log:trace("on_simulate returned false") end
            -- kill the current manager, and check to see if a new one should appear
            this.kill_manager() -- this also deregisters the `monitor_manager` function
            this.update_active_manager(false) -- false means we dont have a new target
        end
    end
end
-- kill the active manager and unregister its `on_simulate` event, if applicable
function this.kill_manager()
    -- make sure we have a manager to begin with
    if this.manager == nil then return end

    log "killing old manager."

    this.manager:self_destruct()
    this.manager = nil
    -- stop monitoring our manager if it was being monitored
    update_registration{
        event=tes3.event.simulate,
        callback=this.monitor_manager,
        register=false, 
        priority=config.advanced.simulate_priority
    }
end

-- kills the manager, unregisters any simulate events, and sets the target to `nil`
function this.reset()
    this.kill_manager()
    log:trace("unregistering pickpocketing check")

    update_registration{
        event=tes3.event.simulate, 
        callback=this.pickpocketing_check, 
        register=false, 
        priority=config.advanced.simulate_priority
    }
    this.target = nil
end


---@deprecated
this.stop_everything = this.reset



do -- logic for choosing managers

    --- choose a manager for an alive reference
    ---@param new_target tes3reference
    ---@return MQL.Manager? manager_cls the class of the manager to use
    function this.choose_alive_manager(new_target)
        if log.level == 5 then 
            log:trace("looking at %s. objectType = %s", new_target.object.name, new_target.object.objectType)
        end

        if new_target.object.objectType ~= tes3.objectType.npc and new_target.object.objectType ~= tes3.objectType.mobileNPC then
            return
        end
        -- dont allow stuff during character generation
        if not tes3.isCharGenFinished() then return end

        -- if we're sneaking, return the pickpocket manager if that's enabled, or return nothing if that's disabled.
        if tes3.mobilePlayer.isSneaking then
            if config.pickpocket.enable then return managers.Pickpocket end
            
            return
        end

        -- at this point, we know we arent sneaking, so the choice depends on the NPC.
        this.service_override = false

        if config.services.enable  then
            this.checking_service = true
            local offers_service = tes3.checkMerchantOffersService{reference=new_target}
            offers_service = offers_service or this.service_override
            this.service_override = false
            
            if offers_service and managers.Services.allows_services(new_target) then
                return managers.Services
            end
        end

        -- this.service_override = false
        -- at this point, no valid manager was found, but we may want to pickpocket this NPC in the future
        if config.pickpocket.enable then
            log:trace("registering pickpocket check")

            update_registration{
                event=tes3.event.simulate, 
                callback=this.pickpocketing_check, 
                register=true, 
                priority=config.advanced.simulate_priority
            }
        end
    end

    --- choose a manager for a container that's either dead or nonliving. (e.g. a chest or a dead rat)
    ---@param new_target tes3reference
    ---@return MQL.Manager? manager_cls the class of the manager to use
    function this.choose_nonliving_manager(new_target)
        -- check if its an organic container. this function will take into account whether 
        -- the player wants to use GH to help detect whether something is a plant
        if common.is_organic(new_target) then

            if config.organic.enable then return managers.Organic end
        elseif new_target.isDead == true then

            if config.dead.enable then return managers.Dead end
        else

            if config.inanimate.enable then return managers.Inanimate end
        end
    end

end
local container_blacklist = config.blacklist.containers
-- process should be: new container activates:

--- updates the currently active manager, possible making a new one or destroying the current one
-- also updates `this.target`, to ensure `this.target` is always referring to what the player is currently looking at
---@param new_target tes3reference|false|nil equal to `tes3reference|nil` if called by `activation_target_changed`, otherwise `false`
function this.update_active_manager(new_target)
    if new_target == false then new_target = this.target end

    log:trace("activation target changed. now looking at %s", function () return new_target and new_target.object and new_target.object.name end)

    -- update the current target. this will also be useful for the take all functionality and for 
    -- the `monitoring_pickpocketing` event
    this.target = new_target

    -- were going to disable the manger when the activation target changes instead of killing him
    -- this will have the effect of making the UI look a bit smoother (since taking an item can 
    --  temporarily set the target to `nil`  sometimes)
    if this.is_manager_valid() then
        if this.target == this.manager.ref then 
            -- we have finally been reunited with our manager. what a joyous day.
            log:trace("we found our manager. updating him and returning")
            this.manager:update()
            return
        else
            -- we're not looking at our manager, so disable him
           log:trace("looking at something other than the manager, so we are disabling him for now.")
            this.manager:disable()
        end
    end

    -- now we check to see if this new target is a candidate for a different type of manager

    -- doing this after manager checks because we want to disable the manager if it exists and the target isnt nil
    -- `actorFlags` is `nil` whenever the object is not a `tes3actor`, i.e., not a lootable object.
    if not new_target or new_target.object.actorFlags == nil then return end 


    -- check the script status of the container
    local scripted = (new_target:testActionFlag(tes3.actionFlag.useEnabled) == false) 
        -- or (new_target.object.script ~= nil)

    -- log:trace("container is scripted? %s", scripted)

    if scripted and config.show_scripted == defns.show_scripted.dont then
        return
    end

    

    -- if it's blacklisted, then dont do anything
	if next(container_blacklist) ~= nil and container_blacklist[new_target.baseObject.id:lower()] then
		return
	end

    local manager_cls -- the class of the new manager to create, or `nil` if no manager should be created

    -- `isDead == false` means the reference is a `mobileActor` and it's alive.
    if new_target.isDead == false then
        manager_cls = this.choose_alive_manager(new_target)
    else
        manager_cls = this.choose_nonliving_manager(new_target)
    end

    -- if we couldn't find a manager, return
    if manager_cls == nil then return end

    -- at this point, we have a valid new activation target and we're about to make a new manager
    this.kill_manager()

    this.manager = manager_cls.new(new_target)
    log("made a new manager: %s", this.manager)

    -- if the manager has something he wants done every frame, do it
    if this.manager.on_simulate ~= nil then
        log:trace("registering monitor_manager")
        event.register(tes3.event.simulate, this.monitor_manager, {priority=config.advanced.simulate_priority})
    end

end

-- Called when the player looks at a new object that would show a tooltip, or transfers off of such an object, or wiggles their mouse a little.
---@param e activationTargetChangedEventData
function event_callbacks.activation_target_changed(e)
   this.update_active_manager(e.current)
end


-- this variable is used to `custom_activate` with things.
-- basically, the `custom_activate` function will set this to `true`, then trigger an activate event.
-- our `activate` event will see that this flag is true, and then it will do nothing

do -- key press functions

    -- a list of object types that are allowed to be taken when the `take_all_key` is pressed
    -- if you press "take all" while looking at an A list object type, you'll take all nearby objects of that type
    -- if you press "take all" while looking at a B list object type, you'll take all nearby objects with the same name as the one you're looking at
  
    
    function event_callbacks.take_all_key_pressed()

        -- if the manager is still valid, and if it was able to successfully take all items, do nothing else
        if this.is_manager_valid() then
            local mpressed = tes3.worldController.inputController:isKeyDown(modifier_keycode)
            if this.manager:take_all_items(mpressed) then return end
        end
        common.take_nearby_items(this.target)
    end

    
    -- this is so it plays nicely with custom activate, which is used to open the target container
    local skip_next_activate = false
    

    -- takes current item when the activation key is pressed, only happens if `use_activate_btn == true`
    ---@param e keyDownEventData 
    function event_callbacks.activate_key_pressed(e)
        if not this.is_manager_valid() then return end

        local mpressed = tes3.worldController.inputController:isKeyDown(modifier_keycode)
        
        if config.keys.use_activate_btn then -- if "take was pressed"
            skip_next_activate = true -- block activation event
            -- block the keypress event if we took the item
            return not this.manager:take_item(mpressed)
        else
            -- if "open" was pressed
            if mpressed and this.manager:modified_open() then 
                -- block the activation event if we successfully did a modified open
                skip_next_activate = true
                return false
            end
        end
    end
    -- block the activation event if we're instructed to do so
    ---@param e activateEventData 
    function event_callbacks.target_activated(e)
        if skip_next_activate and e.activator == tes3.player and this.is_manager_valid() and this.manager.ref == e.target then
            skip_next_activate = false
            return false
        end
    end

    ---@param e keyDownEventData
    function event_callbacks.custom_key_pressed(e)
        if this.target == nil or  not this.is_manager_valid() then return end

        local mpressed = tes3.worldController.inputController:isKeyDown(modifier_keycode)
        
        if config.keys.use_activate_btn then -- if "open" was pressed
            
            if mpressed then
                return not this.manager:modified_open()
            else
                tes3.player:activate(this.target)
                -- tes3.showContentsMenu{ reference=this.target,
                --     pickpocket=this.manager:is_instance_of(managers.Pickpocket)
                -- }
            end
        else -- "take" was pressed
            return not this.manager:take_item(mpressed) 
        end

    end

    ---@param e keyDownEventData
    function event_callbacks.undo_key_pressed(e)
        if undo_key.isAltDown == e.isAltDown
        and undo_key.isControlDown == e.isControlDown
        and undo_key.isShiftDown == e.isShiftDown
        and this.is_manager_valid()
        then
            this.manager:undo()
        else
            log("undo key was blocked for some reason.")
        end
    end
 
end





do -- make button press functions 

    ---@param e keyDownEventData
    function event_callbacks.arrow_key_scroll_down(e)
        if not this.is_manager_valid() then return end
        -- if we failed to increment the index, check if the current index is okay (this could happen if we try to scroll past the first or last item)
        local successful = this.manager:increment_index() or this.manager:is_current_index_valid()
        e.claim =  successful and config.advanced.ak_claim
    end
    
    ---@param e keyDownEventData
    function event_callbacks.arrow_key_scroll_up(e)
        if not this.is_manager_valid() then return end 
        local successful = this.manager:decrement_index() or this.manager:is_current_index_valid()
        e.claim =  successful and config.advanced.ak_claim
    end

    -- Called when the mouse wheel scroll is used. Changes the selection.
    ---@param e mouseWheelEventData
    function event_callbacks.mouse_wheel_scroll(e)
        if not this.is_manager_valid() then return end

        local successful
        if e.delta < 0 then
            successful = this.manager:increment_index() or this.manager:is_current_index_valid()
        else
            successful = this.manager:decrement_index() or this.manager:is_current_index_valid()
        end
        e.claim = successful and config.advanced.sw_claim
    end
end

---@param e uiObjectTooltipEventData
function event_callbacks.ui_object_tooltip(e)
    if this.target == nil or not this.is_manager_valid() or this.manager.cant_loot then return end

    e.tooltip.maxWidth = 0
    e.tooltip.maxHeight = 0
    e.tooltip.visible = false
    return false
end

-- override the TTIP item press button so that we can mark items in containers
function event_callbacks.ttip_collected_key_override()
    if this.is_manager_valid() and this.manager:ttip_mark_selected_as_collected() then
        return false
    end
end

function event_callbacks.update_manager_item_labels()
    if this.is_manager_valid() and this.manager.cant_loot == nil then
        this.manager.gui:update_all_item_labels()
    end
end

function this.update_keybindings()
    do -- unregister old keybinds
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.custom_key_pressed, 
            register=false,
            filter=custom_keycode, 
            priority=config.advanced.custom_priority
        }
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.take_all_key_pressed, 
            register=false,        
            filter=take_all_keycode, 
            priority=config.advanced.take_all_priority
        }
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.activate_key_pressed, 
            register=false,        
            filter=activate_keycode, 
            priority=config.advanced.activate_key_priority
        }
        if undo_key then
            update_registration{
                event=tes3.event.keyDown, 
                callback=event_callbacks.undo_key_pressed, 
                register=false,
                filter=undo_key.keyCode, 
                priority = 300
            }
        end
    end
    do -- update keybinds
        modifier_keycode = config.keys.modifier.keyCode
        custom_keycode = config.keys.custom.keyCode
        take_all_keycode = config.keys.take_all.keyCode
        activate_keycode = tes3.getInputBinding(tes3.keybind.activate).code
        undo_key = config.keys.undo
        -- sometimes these can be `nil`, but we want to ensure they're `true` or `false`
        undo_key.isAltDown = undo_key.isAltDown or false
        undo_key.isShiftDown = undo_key.isShiftDown or false
        undo_key.isControlDown = undo_key.isControlDown or false
        undo_key.isSuperDown = undo_key.isSuperDown or false
    end

    do -- register new keybinds
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.custom_key_pressed, 
            register= true,   
            filter=custom_keycode, 
            priority=config.advanced.custom_priority
        }
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.take_all_key_pressed, 
            register=true,        
            filter=take_all_keycode, 
            priority=config.advanced.take_all_priority
        }
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.activate_key_pressed, 
            register=true,        
            filter=activate_keycode, 
            priority=config.advanced.activate_key_priority
        }
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.undo_key_pressed, 
            register=true,
            filter= undo_key.keyCode,
            priority = 300
        }
    end

    -- update TTIP key bind events
    if config.compat.ttip then
        local ttip_config = include("rev_TTIP.config")
        
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.ttip_collected_key_override, 
            register=config.UI.ttip_mark_selected,
            filter=ttip_config.collect.keyCode, 
            priority=1
        }
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.update_manager_item_labels, 
            register=true, 
            filter=ttip_config.collect.keyCode, 
            priority=-1
        }
    end
end
-- tes3.getInputBinding(tes3.keybind.activate).code
function mcm.update()
    this.update_keybindings()

    -- update dialogue filter event registration
    update_registration{
        event=tes3.event.dialogueFiltered, 
        callback=event_callbacks.skooma_filter, 
        register=config.services.allow_skooma, 
        priority=config.advanced.dialogue_filtered_priority
    }

    
    -- update_registration{
    --     event=tes3.event.uiObjectTooltip, 
    --     callback=this.ui_object_tooltip, 
    --     register = not config.UI.show_tooltips, 
    --     priority=10
    -- }
    -- gui stuff
    GUI.update_control_key_names()
end




function event_callbacks.initialized()
    mcm.update()
    GUI.register_UIIDS_and_COLORS()

    update_registration{
        event=tes3.event.activate, 
        callback=event_callbacks.target_activated,
        register=true,
        priority=config.advanced.activate_event_priority
    }
    update_registration{
        event=tes3.event.activationTargetChanged, 
        callback=event_callbacks.activation_target_changed, 
        register=true
    }

    do -- register arrow key and scroll wheel events
        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.arrow_key_scroll_up, 
            register=true,   
            filter = tes3.scanCode.keyUp, 
            priority=config.advanced.ak_priority
        }

        update_registration{
            event=tes3.event.keyDown, 
            callback=event_callbacks.arrow_key_scroll_down, 
            register=true, 
            filter = tes3.scanCode.keyDown, 
            priority=config.advanced.ak_priority
        }
        update_registration{
            event=tes3.event.mouseWheel, 
            callback=event_callbacks.mouse_wheel_scroll, 
            register=true, 
            priority = config.advanced.sw_priority,
        }
    end
    do -- register `stop_everything` callback to various events that should destroy the menu
        update_registration{
            event=tes3.event.menuEnter, 
            callback=this.reset, 
            register=true, 
            priority=config.advanced.menu_entered_priority
        }
        update_registration{
            event=tes3.event.uiActivated, 
            callback=this.reset, 
            register=true, 
            filter="MenuInventory", 
            priority=config.advanced.menu_entered_priority
        }
        update_registration{
            event=tes3.event.load, 
            callback=this.reset, 
            register=true, 
            priority=config.advanced.load_priority
        }
        update_registration{
            event=tes3.event.cellChanged, 
            callback=this.reset, 
            register=true, 
            priority=config.advanced.cell_changed_priority
        }
    end

    log:info("Initialized version %s", config.version)
end

-- doing this so that the main file can be "included" by other mods
update_registration{event=tes3.event.initialized, callback=event_callbacks.initialized, register=true}
update_registration{event=tes3.event.modConfigReady, callback=mcm.register, register=true}

return this