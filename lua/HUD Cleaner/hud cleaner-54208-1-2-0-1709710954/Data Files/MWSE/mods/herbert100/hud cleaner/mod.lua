
local log = Herbert_Logger.new{include_timestamp=true}

local cfg = require("herbert100.hud cleaner.config")
local upd_reg = require("herbert100").update_registration
local common = dofile("herbert100.hud cleaner.common") ---@type herbert.HC.common
local hud = common.hud

---@type table?
local spammers_hot_quick_config = mwse.loadConfig("Quickkeys Hotbar")



if not spammers_hot_quick_config or next(spammers_hot_quick_config) == nil then
    spammers_hot_quick_config = nil
end

local virn_mode = tes3.isLuaModActive("Virnetch\\HotKeys")

local mm_cfg = cfg.menu_multi
local bars_cfg = mm_cfg.bars
local equipped_cfg = mm_cfg.equipped

---@type table<string, mwseTimer|boolean>
local timers = { menu_multi = false, companion_bars = false, spammer_hot_quick = false, ashfall=false, }

local hide_map
---@type table<string, fun(p: mwseTimerCallbackData?, ...)>
local timer_callbacks = {
    menu_multi = function()
        log:trace("running menu multi timer")
        local pm = tes3.mobilePlayer
        local wpn_ready = pm.weaponReady or pm.castReady
        local bar_override = mm_cfg.show_bars_if_wpn and wpn_ready
        if hud.bars then
            for k, bar in pairs(hud.bars) do
                bar.visible = bar_override or bars_cfg[k] >= 0.999 or pm[k].normalized <= bars_cfg[k]
            end
        end
        if hud.equipped then
            for k, block in pairs(hud.equipped) do
                if equipped_cfg[k] then
                    block.visible = wpn_ready
                end
            end
        end
        if hide_map > 0 and hud.map then
            if hide_map == 1 then
                    hud.map.visible = not wpn_ready
            elseif hide_map == 2 then
                hud.map.visible = wpn_ready
            elseif hide_map == 3 then
                hud.map.visible = tes3.player.cell.isOrBehavesAsExterior
            else
                hud.map.visible = tes3.player.cell.isOrBehavesAsExterior
            end
        end
    end,

    ---@param d mwseTimerCallbackData
    ---@param check_again boolean? should we check again? default: false
    companion_bars = function(d, check_again)
        log:trace("running companion bars timer")
        local MM = tes3ui.findMenu("MenuMulti")
        local CHBM = MM and MM:findChild("CompanionHealthBars:Menu") -- companion bar menu
        if not CHBM then return end
        -- local name = string.format("CompanionHealthBars:%s.label", mob.reference.id)
        local children = CHBM.children
        local threshold = cfg.companion_bars.health
        local bar_override = cfg.companion_bars.show_bars_if_wpn and tes3.mobilePlayer.weaponReady
        local num_visible = 0
        for i = 1, #children - 1, 2 do
            local name_block = children[i]
            if not name_block then goto next_ref end

            -- name has the form "CompanionHealthBars:%s.label", where `%s` == `ref.id`
            local ref_id = name_block.name:sub(21,-7)
            log("checking %q", ref_id)
            local ref_handle = common.active_companions[ref_id]

            if not ref_handle or not ref_handle:valid() then
                if check_again == false then goto next_ref end
                common.update_active_companions()
                ---@diagnostic disable-next-line: redundant-parameter
                return d.timer.callback(d, false)
            end
            
            local ref = ref_handle:getObject()
            
            local visibility = bar_override or ref.mobile.health.normalized < threshold
            log("setting visibility of %q to %s. health_ratio = %s", ref.object.name, visibility,ref.mobile.health.normalized )
            name_block.visible = visibility
            if children[i+1] then 
                children[i+1].visible = visibility
            end
            if visibility then
                num_visible = num_visible + 1
            end
            ::next_ref::
        end
        CHBM.visible = num_visible > 0
    end
}



local function update_timers()
    -- only do stuff when ingame
    if not tes3.player then return end
    for _, k  in ipairs(table.keys(timers)) do
        local enable = cfg[k].enable
        local pollrate = cfg[k].pollrate
        local t = timers[k]
        if t then t:cancel() end

        timers[k] = enable and timer.start{callback=timer_callbacks[k], duration=pollrate, iterations=-1}
    end
end

local damage_magicka = tes3.effect.damageMagicka

local function magic_icons_updated()
    ---@type tes3uiElement
    local icons_box = hud.effect_icons and hud.effect_icons:findChild("MenuMulti_magic_icons_box") 
    if not icons_box then return end

    local perm_effects = common.perm_bonuses
    local effect_by_icon = common.effect_by_icon
    local do_atronach_skip = tes3.isAffectedBy{reference=tes3.player, effect=tes3.effect.stuntedMagicka}
    log("------ BEGIN magic effect icon updates -----")
    for _, row in pairs(icons_box.children) do
        local hide_row = true
        local id, perm_mag, icon_vis

        for i, icon in pairs(row.children) do
            if not icon.contentPath then 
                log:trace("skipping icon %i because it had no icon", i)

                goto next_icon 
            end

            id = effect_by_icon[icon.contentPath:lower()]
            if not id then 
                log:trace("skipping icon with path %q because it had no id", string.lower, icon.contentPath)
                goto next_icon 
            end

            log:trace("checking %s", id)
            perm_mag = perm_effects[id]

            -- easy case first
            if not perm_mag then
                --[[ this is a special case that handles the atronach birthsign.
                    the atronach effect uses the "damage magicka" icon, so (by default), atronachs will have
                    a "damage magicka" icon on the hud, while having 0 "damage magicka" effect magnitude.
                    since `perm_mag == nil` (i.e. 0), we only need to check that the "damage magicka" effect magnitude is > 0.
                ]]
                if id == damage_magicka then
                    local _, mag = tes3.getEffectMagnitude{effect=id, reference=tes3.player}
                    if mag == 0 then
                        icon_vis = false
                    elseif do_atronach_skip then
                        icon_vis = false
                        do_atronach_skip = false
                    else
                        icon_vis = true
                    end
                    -- icon_vis = mag > 0
                else
                    icon_vis = true
                end
            else
                if common.targets_skill_ids[id] then
                    icon_vis = false
                    local e_mag, mag
                    -- it's not sufficient to only loop over `perm_mag`, because 
                    -- there could be skills with no permanent bonus that have an effect on them
                    for _, skill_id in pairs(tes3.skill) do
                        mag = tes3.getEffectMagnitude{effect=id, skill=skill_id, reference=tes3.player}
                        
                        -- note that `mag >= perm_mag[skill_id] >= 0`, and that `perm_mag[skill_id]` will be `nil` instead of `0`
                        -- so the `mag > 0` check handles the special case when `mag == 0` and `perm_mag[skill_id] == nil`
                        if mag > 0 and mag ~= perm_mag[skill_id] then
                            icon_vis = true
                            break
                        end
                    end
                elseif common.targets_attribute_ids[id] then
                    -- visible if they're not all the same
                    icon_vis = false
                    local e_mag, mag
                    for _, attr_id in pairs(tes3.attribute) do
                        mag = tes3.getEffectMagnitude{effect=id, attribute=attr_id, reference=tes3.player}
                        if mag > 0 and perm_mag[attr_id] ~= mag then
                            icon_vis = true
                            break
                        end
                    end
                else
                    -- need to check `mag > 0` because we want `nil` and `0` to behave the same
                    local e_mag, mag = tes3.getEffectMagnitude{effect=id, reference=tes3.player}
                    icon_vis = mag > 0 and mag ~= perm_mag
                end
            end
            -- print log messages (only if tracing)
            if log.level == 5 then
                local name = tes3.getMagicEffectName{effect=id}
                log:trace("%i: %q (id = %s)\n\t\z
                    icon_path = %q\n\t\z
                    magnitude: %s\n\t\z
                    perm_bonuses = %s\n\t\z
                    new visibility = %s",
                    i, name, id,
                    icon.contentPath:lower(), 
                    tes3.getEffectMagnitude{effect=id, reference=tes3.player},
                    perm_mag or "N/A",
                    icon_vis ~= false
                )
            end
            icon.visible = icon_vis

            if hide_row and icon_vis == true then 
                hide_row = false
            end
            ::next_icon::
        end
        row.visible = not hide_row
    end
    log("------ DONE updating icons -----")
end


local function update_icons_on_load()
    timer.delayOneFrame(magic_icons_updated)
end

local function update_menu_multi_on_menu_exit()
    if not tes3.player then return end
    if cfg.menu_multi.enable then
        timer_callbacks.menu_multi()
    end
end



local hot_quick_cfg = cfg.spammer_hot_quick

local spammer_timer_override

timer_callbacks.spammer_hot_quick = function()
    log:trace("running hotkey timer callback")
    if  not hud.spammer_hot_quick then return end

    local mp = tes3.mobilePlayer
    hud.spammer_hot_quick.visible = spammer_timer_override or hot_quick_cfg.show_if_wpn and (mp.weaponReady or mp.castReady)
end


local hotkey_pressed_timer ---@type mwseTimer?

local hotkeys = {}



local hotkey_key_codes = {}
local hotkey_mouse_codes = {}

-- updates the keybindings for spammers quick key hotbar (so that it appears for a few seconds)
local function update_hotkey_bindings()
    table.clear(hotkey_key_codes)
    table.clear(hotkey_mouse_codes)
    for i=0, 9 do
        local inp_cfg = tes3.getInputBinding(tes3.keybind.quick1 + i)
        if inp_cfg.device == 0 then
            hotkey_key_codes[inp_cfg.code] = true
        elseif inp_cfg.device == 1 then
            hotkey_mouse_codes[inp_cfg.code] = true
        end
    end
    if virn_mode and spammers_hot_quick_config then
        hotkey_key_codes[spammers_hot_quick_config.keyN.keyCode] = true
        hotkey_key_codes[spammers_hot_quick_config.keyP.keyCode] = true
    end
end

---@param e keyDownEventData
local function hotkey_pressed(e)
    if not hotkey_key_codes[e.keyCode] then return end
    if hotkey_pressed_timer then
        local successful = hotkey_pressed_timer:cancel()
        log("hot canceling hotkey timer. successful? %s", successful)
        
    end
    spammer_timer_override = true
    common.hud.spammer_hot_quick.visible = true
    log("hotkey override timer started")
    hotkey_pressed_timer = timer.start{duration=cfg.spammer_hot_quick.show_after_key_press,callback=function (e)
        log("hotkey override timer finished")
        spammer_timer_override = false
    end}
end


function timer_callbacks.ashfall(p, ...)
    if true then return end
    log:trace("running ashfall timer")
    local ash_hud = hud.ashfall
    log:trace("ashfall hud = %s", require("inspect").inspect, ash_hud)
    if not ash_hud then return end
    log("ashfall hud exists")
    if ash_hud.wetness_bar then
        log("wetness bar exists")
        log("wetness level = %s", ash_hud.wetness_bar.widget.current / ash_hud.wetness_bar.widget.max)
        if ash_hud.wetness_bar.widget.current / ash_hud.wetness_bar.widget.max < 0.2 then
            ash_hud.wetness_block.visible = false
        end
    end

end

local ash_common = include("mer.ashfall.common.common")


local function hide_ashfall_stuff()
    local ash_hud = common.hud.ashfall
    if not ash_hud then return end

    local ash_conditions = ash_common.staticConfigs.conditionConfig
    

    local override = cfg.ashfall.show_if_wpn and (tes3.mobilePlayer.weaponReady or tes3.mobilePlayer.castReady)

    if ash_hud.wetness_block then
        -- we dont need a wetness bar when we're dry
        ash_hud.wetness_block.visible = override or ash_conditions.wetness:getCurrentState() ~= ash_conditions.wetness.default
    end

    
    -- dont show the icons that say "nothing is wrong"
    if not override then
        ash_hud.rain_sheltered.visible = false
        ash_hud.sun_sheltered.visible = false
        
    end


    -- dont show the 4 temperature bars if the temperature is okay
    ash_hud.left_temp_limit.parent.parent.visible = override or ash_conditions.temp:getCurrentState() ~= ash_conditions.temp.default

end



local function update()
    if tes3.isLuaModActive("Spammer.Quick Key Hot Bar") then
        update_hotkey_bindings()
    end
    hide_map = cfg.hide_map
    upd_reg{event=tes3.event.loaded, callback=update_icons_on_load, register=cfg.hide_magic_effect_icons}
    upd_reg{tes3.event.menuExit, update_menu_multi_on_menu_exit}
    upd_reg{event=tes3.event.activeMagicEffectIconsUpdated, callback=magic_icons_updated, register=cfg.hide_magic_effect_icons}
    -- event.register(tes3.event.activeMagicEffectIconsUpdated, magic_icons_updated)

    update_timers()

    upd_reg{event="Ashfall:UpdateHud", callback=hide_ashfall_stuff, priority=-1, register=cfg.ashfall.enable}
    
end
common.initialize()
local function initialized()
    if tes3.isLuaModActive("Spammer.Quick Key Hot Bar") then
        event.register("loaded", update_hotkey_bindings)
    else
        hot_quick_cfg.enable = false
    end
    if not tes3.isLuaModActive("Companion Health Bars") then
         cfg.companion_bars.enable = false
     end
    update()
    event.register(tes3.event.loaded, update_timers)
    -- eventgister(tes3.event.loaded, update_timers)

    event.register(tes3.event.keyDown, hotkey_pressed)
    log:write_init_message()
end


if false and tes3.isInitialized() then
    common.update_effect_by_icon_tbl()
    initialized()
    -- common.initialize()
    common.update_perm_bonuses()    
    common.clear_MM_hud_data()
    common.update_MM_hud_data()
    update()
    hud = common.hud
end

event.register(tes3.event.initialized, initialized)

-- =============================================================================
-- MCM
-- =============================================================================
event.register("modConfigReady", function (e)
    local MCM = require("herbert100.MCM").new{closed=update}

    local page = MCM:new_sidebar_page{label="Settings", desc="This mod lets you dynamically hide HUD elements when they aren't relevant."}
    page:new_button{label="Hide permanent magic effect icons", id="hide_magic_effect_icons",
        desc="If enabled, then effect icons tied to permanent bonuses won't be displayed in the in-game HUD. \z
            These icons will still be visible in the magic menu.\n\n\z
            An effect is considered \"permanent\" if it's caused by a constant enchantment or a permanent ability.\n\n\z
            Effects resulting from potions, spells, and non-constant enchantments will still be displayed."
    }


    page:new_dslider{label="Poll rate", id="pollrate", config=cfg.menu_multi,
        desc="How frequently should hud visibility be updated?",
        dp=1, min=0.2, max=2,
    }

    local bars_cat = page:new_category{label="Player Bars", config=cfg.menu_multi.bars}
    for id in pairs(cfg.menu_multi.bars) do
        bars_cat:new_pslider{id=id, label=string.format("Hide %s bar if %s is above", id, id)}
    end
    bars_cat:new_button{label="Show sliders when weapon is drawn", id="show_bars_if_wpn", config=cfg.menu_multi,
        desc="If enabled, then health/magicka/fatigue bars will always be shown when a weapon is readied."
    }


    local equipped_cat = page:new_category{label="Equipped items", config=cfg.menu_multi.equipped}
    for id in pairs(cfg.menu_multi.equipped) do
        equipped_cat:new_button{id=id, label="Hide " .. id .. " icon when weapons are holstered"}
    end


    page:new_dropdown{id="hide_map", label="Hide minimap",
        desc="This lets you change when the minimap gets hidden.\n\n\z
            The \"indoors\" and outdoors options use the `isOrBehavesAsExterior` flag, \z
            meaning that Mournhold is \"outdoors\", while things like houses and caves are \"indoors\".", 
        options={
            {"Never hide.", 0}, 
            {"Hide if weapon is drawn.", 1}, 
            {"Hide if weapon is holstered.", 2},
            {"Hide if you're indoors.", 3},
            {"Hide if you're outdoors.", 4},
        }}
    local companion_bars = page:new_category{label="Companion Bars Compatibility", config=cfg.companion_bars,
        desc="These settings control the compatibility options with companion bars."}

    companion_bars:new_button{label="Enable", id="enable",
        desc="Enables compatibility with Companion Bars. Original mod required.", 
        callback=function (self)
            if not tes3.isLuaModActive("Companion Health Bars") then
                self.variable.value = false
                cfg.companion_bars.enable = false
            end
        end
    }
    companion_bars:new_pslider{id="health", label="Hide health bar if health is above"}

    companion_bars:new_dslider{label="Poll rate", id="pollrate", 
        desc="How frequently should hud visibility be updated?",
        dp=1, min=0.2, max=2,
    }

    local spammer_hot_quick = page:new_category{label="QuickKey Hot Bar Compatibility", config=cfg.spammer_hot_quick,
        desc="These settings control the compatibility options with Spammer's mod."}

    spammer_hot_quick:new_button{label="Enable", id="enable",
        desc="Enables autohiding the quickey hotbar. Original mod required.", 
        callback=function (self)
            if not tes3.isLuaModActive("Spammer.Quick Key Hot Bar") then
                self.variable.value = false
                cfg.spammer_hot_quick.enable = false
            end
        end
    }
    spammer_hot_quick:new_button{id="show_if_wpn", label="Show if weapon is readied."}

    spammer_hot_quick:new_dslider{label="Seconds to keep visible after hotkey pressed", id="show_after_key_press", 
        desc="The hotkey bar will be visible for this many seconds after a hotkey is pressed.\n\n\z
            Set to 0 to disable.",
        dp=1, min=0, max=8,
    }

    spammer_hot_quick:new_dslider{label="Poll rate", id="pollrate", 
        desc="How frequently should the visibility of this element be updated?\n\n\z
        Note: This only affects the \"Show if weapon is readied\" option.",
        dp=1, min=0.2, max=2,
    }

    local ashfall = page:new_category{label="Ashfall compatibility settings", config=cfg.ashfall,
        desc="Allows Ashfall HUD elements to be hidden when they aren't relevant. \z
        For example, you won't have a wetness meter when you're \"dry\", and you won't have temperature meters when your temperature is fine. \z
        This will also prevent the sun/rain \"sheltered\" icons from showing up. The icons will still appear if you're unsheltered."
    }
    ashfall:new_button{label="Enable?", id="enable", desc="If true, ashfall hud elements will be hidden automatically when not relevant."}
    ashfall:new_button{id="show_if_wpn", label="Show if weapon is readied."}


    MCM.template.postCreate = function(self)
        if not tes3.isLuaModActive("Companion Health Bars") then
            cfg.companion_bars.enable = false
        end
    end
    page:add_log_settings()

    MCM:register()
end)
