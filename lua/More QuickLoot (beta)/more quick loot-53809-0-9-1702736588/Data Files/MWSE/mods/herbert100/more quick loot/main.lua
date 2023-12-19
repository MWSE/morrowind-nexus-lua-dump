--[[
    More QuickLoot. An updated QuickLoot mod based on the original QuickLoot mod by mort.
    Version 0.65
    Author: herbert100
    
    Original QuickLoot author: mort
]] --

local defns = require("herbert100.more quick loot.defns")

---@diagnostic disable-next-line: assign-type-mismatch
local log = require("herbert100.Logger")(defns) ---@type Herbert_Logger


local mcm = require("herbert100.more quick loot.mcm")
local config = require("herbert100.more quick loot.config")
local interop = require("herbert100.more quick loot.interop")

local GUI = require("herbert100.more quick loot.GUI")

local managers = require("herbert100.more quick loot.Managers") ---@type table<string, MQL.Manager>



local this = {
    target = nil,                       ---@type tes3reference?
    manager = nil,                      ---@type MQL.Manager?
    manager_ref_handle = nil,           ---@type mwseSafeObjectHandle
    was_sneaking = false,               ---@type boolean were you sneaking in the last frame?
    monitoring_pickpocketing = false,   ---@type boolean are we checking to see if pickpocketing should happen?
}


-- keybindings. we're saving this here so that we can properly update the button press events when they change
-- (we need to unregister the old keybindings before registering the new ones)
local interact_keycode, take_all_keycode, custom_keycode, modifier_keycode

-- we're gonna do some weird scope stuff to protect the GH config
do -- initialize gh_blacklist, if it exists

    local gh_config
    if config.compat.gh_current == defns.gh_status.currently then
        -- we need to make sure we don't write to this, since this is the actual config being used and updated by GH.
        -- thats why we're only allowing  `gh_config` to be visible in this scope, for the `is_organic` function
        gh_config = require("graphicHerbalism.config")

    elseif config.compat.gh_current == defns.gh_status.previously then

        gh_config = mwse.loadConfig("graphicHerbalism", {blacklist = {}, whitelist={}})
        
    end

    if log.level > 1 and gh_config ~= nil then 
        log:debug("MAIN: loaded GH blacklist, printing:", json.encode(gh_config))
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

        if config.organic.plants_blacklist[id] then return false end

        -- past this point, the `plants_blacklist` didn't catch it

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

--- registers an event if it should be registered, deregisters it otherwise.
---@param event_name tes3.event
---@param callback fun() the function to register/unregister
---@param should_be_registered boolean should the event be registered?
---@param filters table? any filters to pass to the event
local function update_event_registration(event_name, callback, should_be_registered, filters)
	local registered = event.isRegistered(event_name, callback, filters)
	if should_be_registered then
		if not registered then
			event.register(event_name, callback, filters) 
		end
	else
		if registered then 
			event.unregister(event_name, callback, filters)
		end
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
            event.register(tes3.event.simulate, this.monitor_manager)
        end

        -- putting this here will ensure this function gets unregistered one the new pickpocketing manager is created.
        ::unregister::
        log "MAIN: unregistering pickpocket check"
        update_event_registration(tes3.event.simulate, this.pickpocketing_check, false)
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

    if log.level > 1 then log "killing old manager." end

    -- stop monitoring our manager if it was being monitored
    update_event_registration(tes3.event.simulate, this.monitor_manager, false)

    -- if this.manager.on_simulate ~= nil then
    --     event.unregister(tes3.event.simulate, this.monitor_manager)
    -- end

    this.manager:self_destruct();
    this.manager = nil
end
function this.stop_everything()
    log "MAIN: stopping everything"

    this.kill_manager()

    update_event_registration(tes3.event.simulate, this.pickpocketing_check, false)

    this.target = nil
end



do -- logic for choosing managers

    --- choose a manager for an alive reference
    ---@param new_target tes3reference
    ---@return MQL.Manager? manager_cls the class of the manager to use
    function this.choose_alive_manager(new_target)
        if log > 1 then 
            log(("MAIN: looking at %s. objectType = %s"):format(new_target.object.name, new_target.object.objectType))
        end
        if new_target.object.objectType ~= tes3.objectType.npc and new_target.object.objectType ~= tes3.objectType.mobileNPC then
            return
        end

        -- if we're sneaking, return the pickpocket manager if that's enabled, or return nothing if that's disabled.
        if tes3.mobilePlayer.isSneaking then
            if config.pickpocket.enable then return managers.Pickpocket end
            
            return
        end

        -- at this point, we know we arent sneaking, so the choice depends on the NPC.

        local ai = new_target.object.aiConfig

        -- if ai.travelDestinations then return managers.Travel end

        if config.training.enable and ai.offersTraining then return managers.Training end

        
        -- if new_target.object.barterGold and new_target.object.barterGold > 0 then return managers.Barter end

        -- at this point, no valid manager was found, but we may want to pickpocket this NPC in the future
        if config.pickpocket.enable then
            update_event_registration(tes3.event.simulate, this.pickpocketing_check, true)
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
    if new_target == false then
        new_target = this.target
    elseif log > 2 then
        if new_target ~= nil and new_target.object and new_target.object.name then 
            log:trace("MAIN: activation target changed! now looking at " .. new_target.object.name )
        else
            log:trace("MAIN: activation target changed! now looking at nothing!")
        end
    end

    -- update the current target. this will also be useful for the take all functionality and for 
    -- the `monitoring_pickpocketing` event
    this.target = new_target

    -- were going to disable the manger when the activation target changes instead of killing him
    -- this will have the effect of making the UI look a bit smoother (since taking an item can 
    --  temporarily set the target to `nil`  sometimes)
    if this.check_manager_is_valid() then
        if this.target == this.manager.ref then 
            -- we have finally been reunited with our manager. what a joyous day.
            if log.level > 2 then log:trace("MAIN: we found our manager. updating him and returning") end
            this.manager:update_container_status()
            return
        else
            -- we're not looking at our manager, so disable him
            if log.level > 2 then log:trace("MAIN: looking at something other than the manager, so we are disabling him for now.") end
            this.manager:disable()
        end
    end

    -- doing this after manager checks because we want to disable the manager if it exists and the target isnt nil
    if new_target == nil or new_target == false then return end 

    -- now we check to see if this new target is a candidate for a different type of manager

    -- check the script status of the container
    local scripted = (new_target:testActionFlag(tes3.actionFlag.useEnabled) == false) 
        -- or (new_target.object.script ~= nil)

    if log.level > 2 then
        if scripted then 
            log:trace("looking at a scripted container")
        end
        log:trace("useEnabled flag = " .. tostring(new_target:testActionFlag(tes3.actionFlag.useEnabled)))
        -- log:trace("onActivate flag = " .. tostring(new_target:testActionFlag(tes3.actionFlag.onActivate)))
        log:trace("new_target.obj.script = " .. tostring(new_target.object.script))
    end

    if scripted and config.show_scripted == defns.show_scripted.dont then
        return
    end

    -- `actorFlags` is `nil` whenever the object is not a `tes3actor`, i.e., not a lootable object.

    if interop.skipNextTarget or new_target.object.actorFlags == nil then
        interop.skipNextTarget = false
        return
    end

    -- if it's blacklisted, then dont do anything
	if config.blacklist[new_target.baseObject.id:lower()] then
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
    if log.level > 1 then 
        log("MAIN: making new manager with manager_cls = " .. tostring(manager_cls.__secrets.name))
    end
    this.kill_manager()

    if scripted and config.show_scripted == defns.show_scripted.prefix then
        this.manager = manager_cls(new_target, "(*) ")
    else
        this.manager = manager_cls(new_target)
    end
    this.manager_ref_handle = tes3.makeSafeObjectHandle(new_target)


    -- if the manager has something he wants done every frame, do it
    if this.manager.on_simulate ~= nil then
        event.register(tes3.event.simulate, this.monitor_manager)
    end

end

-- Called when the player looks at a new object that would show a tooltip, or transfers off of such an object, or wiggles their mouse a little.
---@param e activationTargetChangedEventData
function this.activation_target_changed(e)
   this.update_active_manager(e.current)
end


-- this variable is used to `custom_interact` with things.
-- basically, the `custom_interact` function will set this to `true`, then trigger an interact event.
-- our `interact` event will see that this flag is true, and then it will do nothing
local skip_next = false

do -- key press functions

    function this.take_all_key_pressed()
        -- tes3.worldController.inputController:isKeyDown(config.keys.modifier.keyCode)
        -- if the manager is still valid, and if it was able to successfully take all items, do nothing else
        if this.check_manager_is_valid() 
            and this.manager:take_all_items(tes3.worldController.inputController:isKeyDown(modifier_keycode)) == true 
        then
            return
        end
        -- otherwise, take all the items, if we're allowed
        -- only take all stuff if the distance is bigger than 0
        if this.target ~= nil and config.take_all_distance > 0 then
            local obj_type = this.target.object.objectType
            if log.level > 1 then 
                log(string.format("MAIN: targeting %s. obj_type = %s. Seeing if it's possible to grab everything.", 
                    this.target.object.name, table.find(tes3.objectType, obj_type))
                )
            end
            if obj_type == tes3.objectType.ingredient
                or obj_type == tes3.objectType.alchemy
                or obj_type == tes3.objectType.miscItem
                or obj_type ==tes3.objectType.lockpick
                or obj_type ==tes3.objectType.probe
                or obj_type == tes3.objectType.apparatus
                or obj_type == tes3.objectType.ammunition
                or obj_type == tes3.objectType.weapon
                or obj_type == tes3.objectType.clothing
                or obj_type == tes3.objectType.book
                or obj_type == tes3.objectType.armor
                -- or obj_type == tes3.objectType.leveledItem 
            then
                log("MAIN: its possible! doing it")
                this.take_all_objects_of_type(obj_type, (tes3.getOwner{reference=this.target} ~= nil))
            end
        end
    end

    -- this is only registered when `use_interact_btn == true`. it's used to take items while the modifier key is held
    function this.modified_interact_key_pressed()
        -- only do stuff if modifier key is pressed
        if tes3.worldController.inputController:isKeyDown(modifier_keycode) and this.check_manager_is_valid() then
            log "modified interact event firing"
            return this.manager:take_item(true)
        end

    end

    -- this is called when `use_interact_btn == false` and the custom key is pressed
    function this.take_item_key_pressed()
        if this.check_manager_is_valid() then 
            local mpressed = tes3.worldController.inputController:isKeyDown(modifier_keycode)
            log("MAIN: about to take item with mpressed = " .. tostring(mpressed))
            this.manager:take_item(mpressed) 
        end
    end

    -- this is so it plays nicely with custom interact, which is used to open the target container
    

    -- takes current item when the activation key is pressed, only happens if `use_interact_btn == true`
    ---@param e activateEventData 
    function this.activate_key_pressed(e)
        log "MAIN: activate key pressed."
        if this.check_manager_is_valid() and e.activator == tes3.player then
            -- if we're told to skip a valid target, skip it and update the `skip_next` variable
            if skip_next == true then
                skip_next = false
                return
            end

            -- this takes the item and returns true if we should block
            if this.manager:take_item(tes3.worldController.inputController:isKeyDown(modifier_keycode)) then
                -- returning false blocks the activation event
                return false
            end
        end
    end
    -- this is triggered when `use_interact_btn == true`, and you press the `custom_key` to activate a container
    function this.custom_interact(e)
        -- if we either can loot, or can't loot because it's empty
        if this.check_manager_is_valid() and this.target ~= nil then
            skip_next = true
            tes3.player:activate(this.target)
            skip_next = false
        end
    end
end

--- takes all objects of a certain type
---@param obj_type tes3.objectType
---@param allow_theft boolean? should theft be allowed?
function this.take_all_objects_of_type(obj_type, allow_theft)
    tes3.playItemPickupSound{item=this.target.object}

    local target_pos = this.target.position
    for obj_ref in tes3.player.cell:iterateReferences(obj_type) do

        local obj = obj_ref.object

        -- if there's not an activate flag, and if it's close enough
        if obj_ref:testActionFlag(tes3.actionFlag.useEnabled) ~= false
            -- and obj_ref:testActionFlag(tes3.actionFlag.onActivate) ~= false
            and math.abs(target_pos.x - obj_ref.position.x) <= config.take_all_distance
            and math.abs(target_pos.y - obj_ref.position.y) <= config.take_all_distance
            and math.abs(target_pos.z - obj_ref.position.z) <= config.take_all_distance
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

    -- keycode == 208
    function this.arrow_key_scroll_down()
        if this.check_manager_is_valid() then this.manager.gui:increment_index() end
    end

    -- keycode == 200
    function this.arrow_key_scroll_up()
        if this.check_manager_is_valid() then this.manager.gui:decrement_index() end

    end

    -- Called when the mouse wheel scroll is used. Changes the selection.
    function this.mouse_wheel_scroll(e)
        if this.check_manager_is_valid() then
            if (e.delta < 0) then
                this.manager.gui:increment_index()
            else
                this.manager.gui:decrement_index()
            end
        end
    end
end

function this.ui_object_tooltip(e)
    if (tes3.menuMode()) then return end

    if interop.skipNextTarget then
        interop.skipNextTarget = false
        return
    end
    if (config.UI.show_tooltips == false) then
        if e.reference ~= nil and e.reference.mobile ~= nil and
            e.reference.mobile.health.current ~= nil and
            e.reference.mobile.health.current <= 0 then
            e.tooltip.maxWidth = 0
            e.tooltip.maxHeight = 0
        elseif e.object.objectType == tes3.objectType.container then
            e.tooltip.maxWidth = 0
            e.tooltip.maxHeight = 0
        end
    end
end



-- tes3.getInputBinding(tes3.keybind.activate).code
function mcm.update()
    do -- unbind old keys, update saved keycodes
        if custom_keycode ~= nil then 
            update_event_registration(tes3.event.keyDown, this.take_item_key_pressed, false,    {filter=custom_keycode})
            update_event_registration(tes3.event.keyDown, this.custom_interact, false,          {filter=custom_keycode})
        end
        if take_all_keycode ~= nil then 
            update_event_registration(tes3.event.keyDown, this.take_all_key_pressed, false,     {filter=take_all_keycode})
        end
        -- unregister the modified interact btn function (which triggeres when you press the interact key while holding the modifier)
        if interact_keycode ~= nil then
            update_event_registration(tes3.event.keyDown, this.modified_interact_key_pressed, false,    {filter=interact_keycode})
        end
        modifier_keycode = config.keys.modifier.keyCode
        custom_keycode = config.keys.custom.keyCode
        take_all_keycode = config.keys.take_all.keyCode
        interact_keycode = tes3.getInputBinding(tes3.keybind.activate).code
        log("MAIN: updated modifier keycode to " .. tostring(modifier_keycode))
    end

    do -- register/deregister activate event and bind new keys
        -- if we should take items with the interact button
        if config.keys.use_interact_btn then 
            -- high priority to make sure we beat graphic herbalism (whenever this mod is enabled and GH is enabled too)
            update_event_registration(tes3.event.activate, this.activate_key_pressed, true, {priority=400})
            event.register(tes3.event.keyDown, this.custom_interact,        {filter=custom_keycode})
            update_event_registration(tes3.event.keyDown, this.modified_interact_key_pressed,  true, {filter=interact_keycode})
            -- update_event_registration(tes3.event.keyDown, this.take_item_key_pressed)

        else
            -- we shouldn't take items with the activate key
            update_event_registration(tes3.event.activate, this.activate_key_pressed, false, {priority=400})
            event.register(tes3.event.keyDown, this.take_item_key_pressed,  {filter=custom_keycode})

        end
        event.register(tes3.event.keyDown, this.take_all_key_pressed,       {filter=take_all_keycode})
    end

    GUI.update_control_key_names()
end

do -- normal version when not livecoding
    local function initialized()
        mcm.update()
        GUI.register_UIIDS()

        event.register(tes3.event.activationTargetChanged, this.activation_target_changed)
        -- event.register(tes3.event.uiObjectTooltip, this.ui_object_tooltip)
        event.register(tes3.event.keyDown, this.arrow_key_scroll_up,    {filter = tes3.scanCode.keyUp})
        event.register(tes3.event.keyDown, this.arrow_key_scroll_down,  {filter = tes3.scanCode.keyDown})
        event.register(tes3.event.mouseWheel, this.mouse_wheel_scroll)
        
        -- kill the manager and reset the active target 
        event.register(tes3.event.menuEnter, this.stop_everything)
        
        -- whenever we try to change cells or load, kill the manager
        -- we're registering with super high priority because we're not actually doing anything related to changing cells and loading
        -- and we don't want our these things to get blocked by other mods (if they block or claim the event)
        event.register(tes3.event.load, this.stop_everything, {priority=1000})
        event.register(tes3.event.cellChanged, this.stop_everything, {priority=1000})

        log:info("MAIN: Mod initialized")

    end
    event.register(tes3.event.initialized, initialized)

    event.register(tes3.event.modConfigReady, mcm.register)
end
--[[
do -- livecoding version
    local function initialized()
        mcm.update()
        GUI.register_UIIDS()

        -- now activate them
        livecoding.registerEvent(tes3.event.activationTargetChanged, this.activation_target_changed)
        livecoding.registerEvent(tes3.event.keyDown, this.arrow_key_scroll_up,   {filter = tes3.scanCode.keyUp})
        livecoding.registerEvent(tes3.event.keyDown, this.arrow_key_scroll_down, {filter = tes3.scanCode.keyDown})
        livecoding.registerEvent(tes3.event.mouseWheel, this.mouse_wheel_scroll)
        
        livecoding.registerEvent(tes3.event.menuEnter, this.stop_everything)
        
        livecoding.registerEvent(tes3.event.load, this.stop_everything, {priority=1000})
        livecoding.registerEvent(tes3.event.cellChanged, this.stop_everything, {priority=1000})


        log:info("MAIN: Mod initialized")

    end
    livecoding.registerEvent(tes3.event.initialized, initialized)
    update_event_registration(tes3.event.modConfigReady, mcm.register)
end
]]
return this