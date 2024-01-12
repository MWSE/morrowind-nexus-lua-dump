--[[
    More QuickLoot. An updated QuickLoot mod based on the original QuickLoot mod by mort.
    Version 1.2
    Author: herbert100
    
    Original QuickLoot author: mort
]] --

local defns = require("herbert100.more quickloot.defns")

---@diagnostic disable-next-line: assign-type-mismatch
local log = require("herbert100.Logger")("More QuickLoot/main") ---@type herbert.Logger

local update_registration = require("herbert100").update_registration
local mcm = require("herbert100.more quickloot.mcm")
local config = require("herbert100.more quickloot.config")

local GUI = require("herbert100.more quickloot.GUI")

local managers = require("herbert100.more quickloot.Managers") ---@type MQL.Manager_List


local this = {
    target = nil,                       ---@type tes3reference?
    manager = nil,                      ---@type MQL.Manager?
    manager_ref_handle = nil,           ---@type mwseSafeObjectHandle
    was_sneaking = false,               ---@type boolean were you sneaking in the last frame?
    monitoring_pickpocketing = false,   ---@type boolean are we checking to see if pickpocketing should happen?
    checking_service = false,           ---@type boolean `false` if we arent checking a service. otherwise, it's the type of service we're checking for
    service_override = false,           ---@type boolean only `true` if a service was denied and we're ignoring that decision
}


-- sourced from "Hide the Skooma" by Necrolesian. credit to them for compiling this list.
local skooma_dialogue_ids = { ["2350820932343717228"] = true, ["27431251821030328588"] = true, ["745815156108126115"] = true, ["1094918899840230767"] = true, ["170686103927626649"] = true, ["437731057154051750"] = true, ["2456544071464426424"] = true, ["781926249198433643"] = true, ["27861296403221528233"] = true, ["287378702993122269"] = true, ["29036265711176618107"] = true, ["2821782961190224094"] = true, ["3576191201815529709"] = true, ["3034922702178419782"] = true, ["277125218205084722"] = true, ["2797025664259225507"] = true, }

---@param e dialogueFilteredEventData
function this.skooma_filter(e)
    -- only do stuff when we are checking a service and we got a skooma rejection
    if this.checking_service and skooma_dialogue_ids[e.info.id] then 
        -- e.info.
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

-- keybindings. we're saving this here so that we can properly update the button press events when they change
-- (we need to unregister the old keybindings before registering the new ones)
---@type tes3.scanCode, tes3.scanCode, tes3.scanCode, mwseKeyCombo
local take_all_keycode, custom_keycode, modifier_keycode, undo_key

-- we're gonna do some weird scope stuff to protect the GH config
do -- initialize gh_blacklist, if it exists

    local gh_config
    if config.compat.gh_current == defns.misc.gh.installed then
        -- we need to make sure we don't write to this, since this is the actual config being used and updated by GH.
        -- thats why we're only allowing  `gh_config` to be visible in this scope, for the `is_organic` function
        gh_config = include("graphicHerbalism.config")

    elseif config.compat.gh_current == defns.misc.gh.previously then

        gh_config = mwse.loadConfig("graphicHerbalism", {blacklist = {}, whitelist={}})
        
    end


    --- this is a modified version of the `isHerb` function from `graphicHerbalism.main`, copied with permission
    -- we're assuming this is only called on references that aren't `nil`
    -- if the relevant settings are enabled, it will use Graphic Herbalism logic to detect whether something is a plant, in addition to our blacklist
    ---@param ref tes3reference
    ---@return boolean result
    function this.is_organic(ref)
        if not ref.object.organic then return false end

        -- if everything organic is a plant, return `true` before doing anything further
        if config.organic.not_plants_src == defns.not_plants_src.everything_plant then return true end

        -- at this point, we have `config.organic.not_plants_src > defns.not_plants_src.everything_plant`
        local id = ref.baseObject.id:lower()

        if config.blacklist.organic[id] then return false end

        -- past this point, the `blacklist.organic` didn't catch it

        -- if the relevant config setting is enabled, we should ask Graphic Herbalism for its opinion
        if config.organic.not_plants_src == defns.not_plants_src.gh then
            if gh_config.blacklist[id] then return false end
            if gh_config.whitelist[id] then return true end

            return (ref.object.script == nil)
        end

        -- past this point, Graphic Herbalism didn't catch it, so it's probably a plant

        return true
    end
end


--- makes sure the current target and manager are still valid
---@return boolean still_valid  
function this.check_manager_is_valid()
    if this.manager ~= nil and this.manager_ref_handle:valid() then
        return true
    else
        this.kill_manager()
        return false
    end
end




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
        this.manager_ref_handle = tes3.makeSafeObjectHandle(this.target)
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
        if not this.check_manager_is_valid() then
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
    this.manager_ref_handle = nil -- clear the handle
    -- make sure we have a manager to begin with
    if this.manager == nil then return end

   log "killing old manager."

    -- stop monitoring our manager if it was being monitored
    

    this.manager:self_destruct();
    this.manager = nil

    update_registration{event=tes3.event.simulate, callback=this.monitor_manager, register=false, 
        priority=config.advanced.simulate_priority
    }

end
function this.stop_everything()

    this.kill_manager()
    if log.level == 5 then log:trace("unregistering pickpocketing check") end

    update_registration{event=tes3.event.simulate, callback=this.pickpocketing_check, register=false, 
        priority=config.advanced.simulate_priority
    }

    this.target = nil
end



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
        if not tes3.isCharGenFinished() then return end

        -- if we're sneaking, return the pickpocket manager if that's enabled, or return nothing if that's disabled.
        if tes3.mobilePlayer.isSneaking then
            if config.pickpocket.enable then return managers.Pickpocket end
            
            return
        end

        -- at this point, we know we arent sneaking, so the choice depends on the NPC.

        local ai = new_target.object.aiConfig

        this.service_override = false

        -- if ai.travelDestinations then return managers.Travel end
        local offers_service

        -- dont allow stuff during character generation
        if config.services.enable  then
            this.checking_service = true
            offers_service = tes3.checkMerchantOffersService{reference=new_target}
            if (offers_service or this.service_override) and managers.Services.allows_services(new_target) then
                this.service_override = false
                return managers.Services
            end
        end

        -- this.service_override = false
        -- at this point, no valid manager was found, but we may want to pickpocket this NPC in the future
        if config.pickpocket.enable then
            log:trace("registering pickpocket check")

            update_registration{event=tes3.event.simulate, callback=this.pickpocketing_check, register=true, 
                priority=config.advanced.simulate_priority
            }
        end
    end

    --- choose a manager for a container that's either dead or nonliving. (e.g. a chest or a dead rat)
    ---@param new_target tes3reference
    ---@return MQL.Manager? manager_cls the class of the manager to use
    function this.choose_nonliving_manager(new_target)
        -- check if its an organic container. this function will take into account whether the player wants to use GH to help detect
            -- whether something is a plant
        if this.is_organic(new_target) then
            -- we're checking whether organic looting is enabled inside this if block so that we can return `nil` 
            -- in the event that we detect a plant, and organic looting is disabled.
            if config.organic.enable then return managers.Organic end

            -- if the organic part isn't enabled 
            return
        end
        
        if new_target.isDead == true then 
            if config.dead.enable then return managers.Dead end
        else
            if config.inanimate.enable then return managers.Inanimate end
        end
    end

end

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
    if this.check_manager_is_valid() then
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
	if config.blacklist.containers[new_target.baseObject.id:lower()] then
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

    this.kill_manager()
    -- at this point, we have a valid new activation target and we're about to make a new manager
    log("making new %s. target = %s", function ()
        return manager_cls.__secrets.name, new_target.object.name
    end)
    this.kill_manager()

    if scripted and config.show_scripted == defns.show_scripted.prefix then
        this.manager = manager_cls(new_target, "(*) ")
    else
        this.manager = manager_cls(new_target)
    end
    this.manager_ref_handle = tes3.makeSafeObjectHandle(new_target)


    -- if the manager has something he wants done every frame, do it
    if this.manager.on_simulate ~= nil then
        if log.level == 5 then log:trace("registering monitor_manager") end
        event.register(tes3.event.simulate, this.monitor_manager, {priority=config.advanced.simulate_priority})
    end

end

-- Called when the player looks at a new object that would show a tooltip, or transfers off of such an object, or wiggles their mouse a little.
---@param e activationTargetChangedEventData
function this.activation_target_changed(e)
   this.update_active_manager(e.current)
end


-- this variable is used to `custom_activate` with things.
-- basically, the `custom_activate` function will set this to `true`, then trigger an activate event.
-- our `activate` event will see that this flag is true, and then it will do nothing
local skip_next = false

do -- key press functions

    -- a list of object types that are allowed to be taken when the `take_all_key` is pressed
    local take_nearby_allowed_types = { [tes3.objectType.ingredient] = true, [tes3.objectType.alchemy] = true, [tes3.objectType.miscItem] = true, [tes3.objectType.lockpick] = true, [tes3.objectType.probe] = true, [tes3.objectType.apparatus] = true, [tes3.objectType.ammunition] = true, [tes3.objectType.weapon] = true, [tes3.objectType.clothing] = true, [tes3.objectType.book] = true, [tes3.objectType.armor] = true, }
    
    
    function this.take_all_key_pressed()

        local mpressed = tes3.worldController.inputController:isKeyDown(modifier_keycode)

        -- if the manager is still valid, and if it was able to successfully take all items, do nothing else
        if this.check_manager_is_valid() and this.manager:take_all_items(mpressed) then
            return
        end

        -- otherwise, take all the items, if we're allowed
        -- only take all stuff if the distance is bigger than 0
        if this.target == nil or config.take_all_distance == 0 then return end

        local obj_type = this.target.object.objectType
        log("targeting %s. obj_type = %s. Seeing if it's possible to grab everything.", 
                function() return this.target.object.name, table.find(tes3.objectType, obj_type) end
            )

        if not take_nearby_allowed_types[obj_type] then return end

        log("about to take all nearby items")

        local take_nearby, allow_theft
        if mpressed then
            take_nearby = config.take_nearby_m
        else
            take_nearby = config.take_nearby
        end
        
        if take_nearby == defns.take_nearby.never_steal then
            allow_theft = false
        elseif take_nearby == defns.take_nearby.use_context then
            allow_theft = (tes3.getOwner{reference=this.target} ~= nil)
        elseif take_nearby == defns.take_nearby.always_steal then
            allow_theft = true
        end
        
        this.take_all_objects_of_type(obj_type, allow_theft)
    end



    -- this is so it plays nicely with custom activate, which is used to open the target container
    

    -- takes current item when the activation key is pressed, only happens if `use_activate_btn == true`
    ---@param e activateEventData 
    function this.activate_key_pressed(e)
        if not (this.check_manager_is_valid() and e.activator == tes3.player) then return end

        local mpressed = tes3.worldController.inputController:isKeyDown(modifier_keycode)
        -- logic for `use_activate_btn == true`
        if config.keys.use_activate_btn then 
        -- if we're told to skip a valid target, skip it and update the `skip_next` variable
            if skip_next == true then
                skip_next = false
                return
            end
            -- log " calling take item"
            -- this takes the item and returns true if we should block
            if this.manager:take_item(mpressed) then
                -- returning false blocks the activation event
                return false
            end
        else
            -- logic for `use_activate_btn == false`
            if mpressed then 
                -- log"calling modified open with use_activate_btn == false and activate key pressed"
                local successfully = this.manager:modified_open()
                return not successfully
            end

        end
    end

    ---@param e keyDownEventData
    function this.custom_key_pressed(e)

        if not this.check_manager_is_valid() or this.target == nil then return end

        local mpressed = tes3.worldController.inputController:isKeyDown(modifier_keycode)

        if config.keys.use_activate_btn then
            -- if `use_activate_btn == true`, the custom key should 
            -- 1) activate when the modifier key is not held
            -- 2) try to do a modified open if the modifier key is held, then fallback to activating
            if mpressed then
                if this.manager:modified_open() then
                    return false
                end
            end
            -- happens if modifier is not pressed, or if `modified_open` returned `false`
            skip_next = true
            tes3.player:activate(this.target)
            skip_next = false
        else
            -- if `use_activate_btn == false`, then this should take an item
            return not this.manager:take_item(mpressed) 
        end

    end

    ---@param e keyDownEventData
    function this.undo_key_pressed(e)
        if (undo_key.isControlDown and not e.isControlDown)
        or (undo_key.isAltDown and not e.isAltDown)
        or (undo_key.isShiftDown and not e.isShiftDown)
        or (undo_key.isSuperDown and not e.isSuperDown)
        or not this.check_manager_is_valid()
        then return end
        
        this.manager:undo()

    end
 
end

--- takes all objects of a certain type
---@param obj_type tes3.objectType
---@param allow_theft boolean? should theft be allowed?
function this.take_all_objects_of_type(obj_type, allow_theft)
    tes3.playItemPickupSound{item=this.target.object}

    local target_pos = this.target.position
    local v_dist = config.advanced.v_dist
    local dist2 = config.take_all_distance^2

    for obj_ref in tes3.player.cell:iterateReferences(obj_type) do

        local obj = obj_ref.object
        local obj_pos = obj_ref.position


        -- we're using a cylinder metric to treat 
        if obj_ref:testActionFlag(tes3.actionFlag.useEnabled) ~= false
            and (target_pos.x - obj_pos.x)^2 + (target_pos.y - obj_pos.y)^2 <= dist2
            and math.abs(target_pos.z - obj_pos.z) <= v_dist
        then
            local crime_victim = tes3.getOwner{reference = obj_ref}
            -- if it's not a crime then take it normally
            if crime_victim == nil then
                tes3.addItem{item=obj,reference=tes3.player,playSound=false,updateGUI=false,}
                -- obj_ref:disable()
                obj_ref:delete()
            -- otherwise, only take it if we're already stealing.
            elseif allow_theft then
                tes3.addItem{item=obj,reference=tes3.player,playSound=false,updateGUI=false,}
                tes3.triggerCrime{victim=crime_victim,value=obj.value,type=tes3.crimeType.theft}
                -- obj_ref:disable()
                obj_ref:delete()

            end
        end
    end
    tes3ui.forcePlayerInventoryUpdate()
end



do -- make button press functions 

    ---@param e keyDownEventData
    function this.arrow_key_scroll_down(e)
        if not this.check_manager_is_valid() then return end
        -- if we failed to increment the index, check if the current index is okay (this could happen if we try to scroll past the first or last item)
        local successful = this.manager:increment_index() or this.manager:is_current_index_valid()
        e.claim =  successful and config.advanced.ak_claim
    end
    
    ---@param e keyDownEventData
    function this.arrow_key_scroll_up(e)
        if not this.check_manager_is_valid() then return end 
        local successful = this.manager:decrement_index() or this.manager:is_current_index_valid()
        e.claim =  successful and config.advanced.ak_claim
    end

    -- Called when the mouse wheel scroll is used. Changes the selection.
    ---@param e mouseWheelEventData
    function this.mouse_wheel_scroll(e)
        if not this.check_manager_is_valid() then return end

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
function this.ui_object_tooltip(e)
    if this.target == nil or not this.check_manager_is_valid() or this.manager.cant_loot then return end

    e.tooltip.maxWidth = 0
    e.tooltip.maxHeight = 0
    e.tooltip.visible = false
    return false
end

-- override the TTIP item press button so that we can mark items in containers
function this.ttip_collected_key_override()
    if this.check_manager_is_valid() then
        if this.manager:ttip_mark_selected_as_collected() then
            return false
        end
    end
end

function this.update_manager_item_labels()
    if this.check_manager_is_valid() then
        this.manager.gui:update_all_item_labels()
    end
end





-- tes3.getInputBinding(tes3.keybind.activate).code
function mcm.update()
    do -- update keybinds

        -- unregister old keybinds
        update_registration{event=tes3.event.keyDown, callback=this.custom_key_pressed, register=false,
            filter=custom_keycode, priority=config.advanced.custom_priority
        }
        update_registration{event=tes3.event.keyDown, callback=this.take_all_key_pressed, register=false,        
            filter=take_all_keycode, priority=config.advanced.take_all_priority
        }
        if undo_key then
            update_registration{event=tes3.event.keyDown, callback=this.undo_key_pressed, register=false,
                filter=undo_key.keyCode, priority = 300
            }
        end
        -- update keybinds
        modifier_keycode = config.keys.modifier.keyCode
        custom_keycode = config.keys.custom.keyCode
        take_all_keycode = config.keys.take_all.keyCode
        undo_key = config.keys.undo

        -- register new keybinds
        update_registration{event=tes3.event.keyDown, callback=this.custom_key_pressed, register= true,   
            filter=custom_keycode, priority=config.advanced.custom_priority
        }
        update_registration{event=tes3.event.keyDown, callback=this.take_all_key_pressed, register=true,        
            filter=take_all_keycode, priority=config.advanced.take_all_priority
        }
        update_registration{event=tes3.event.keyDown, callback=this.undo_key_pressed, register=true,
            filter= undo_key.keyCode, priority = 300
        }

    end



    -- update dialogue filter event registration
    local enable_skooma_event = config.services.allow_skooma
    update_registration{event=tes3.event.dialogueFiltered, callback=this.skooma_filter, register=enable_skooma_event, 
        priority=config.advanced.dialogue_filtered_priority
    }


    -- do TTIP compatibility settings
    if config.compat.ttip then
        local ttip_config = include("rev_TTIP.config")
        
        update_registration{event=tes3.event.keyDown, callback=this.ttip_collected_key_override, register=config.UI.ttip_mark_selected,
            filter=ttip_config.collect.keyCode, priority=1
        }
        update_registration{event=tes3.event.keyDown, callback=this.update_manager_item_labels, register=true, 
            filter=ttip_config.collect.keyCode, priority=-1
        }

    end
    
    update_registration{event=tes3.event.uiObjectTooltip, callback=this.ui_object_tooltip, register=not config.UI.show_tooltips,
        priority=10
    }
    -- gui stuff
    GUI.update_control_key_names()
end




function this.initialized()
    mcm.update()
    GUI.register_UIIDS_and_COLORS()

    event.register(tes3.event.activate, this.activate_key_pressed, {priority=config.advanced.activate_priority})
    -- now activate them
    update_registration{event=tes3.event.activationTargetChanged, callback=this.activation_target_changed, register=true}

    -- register the arrow keys and scroll wheel. these will only do stuff while the manager is active
    update_registration{event=tes3.event.keyDown, callback=this.arrow_key_scroll_up, register=true,   
        filter = tes3.scanCode.keyUp, priority=config.advanced.ak_priority
    }
    update_registration{event=tes3.event.keyDown, callback=this.arrow_key_scroll_down, register=true, 
        filter = tes3.scanCode.keyDown, priority=config.advanced.ak_priority
    }
    update_registration{event=tes3.event.mouseWheel, callback=this.mouse_wheel_scroll, register=true, 
        priority = config.advanced.sw_priority,
    }
    
    update_registration{event=tes3.event.menuEnter, callback=this.stop_everything, register=true, 
        priority=config.advanced.menu_entered_priority
    }
    update_registration{event=tes3.event.uiActivated, callback=this.stop_everything, register=true, 
        filter="MenuInventory", priority=config.advanced.menu_entered_priority
    }
    
    update_registration{event=tes3.event.load, callback=this.stop_everything, register=true, 
        priority=config.advanced.load_priority
    }
    update_registration{event=tes3.event.cellChanged, callback=this.stop_everything, register=true, 
        priority=config.advanced.cell_changed_priority
    }



    log:info("Initialized version %s", defns.misc.version)
end

-- doing this so that the main file can be "included" by other mods
update_registration{event=tes3.event.initialized, callback=this.initialized, register=true}
update_registration{event=tes3.event.modConfigReady, callback=mcm.register, register=true}

return this