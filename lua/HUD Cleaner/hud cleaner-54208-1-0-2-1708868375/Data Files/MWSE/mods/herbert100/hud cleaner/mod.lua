
local log = Herbert_Logger.new()

local cfg = require("herbert100.hud cleaner.config")
local upd_reg = require("herbert100").update_registration
local common = require("herbert100.hud cleaner.common")
local hud = common.hud

local mm_cfg = cfg.menu_multi
local bars_cfg = mm_cfg.bars
local equipped_cfg = mm_cfg.equipped

---@type table<string, mwseTimer|boolean>
local timers = { menu_multi = false, companion_bars = false }

local hide_map
---@type table<string, fun(p: mwseTimerCallbackData?, ...)>
local timer_callbacks = {
    menu_multi = function()
        log("running menu multi timer")
        local pm = tes3.mobilePlayer
        local wpn_ready = pm.weaponReady
        local bar_override = mm_cfg.show_bars_if_wpn and wpn_ready
        if hud.bars then
            for k, bar in pairs(hud.bars) do
                bar.visible = bar_override or pm[k].normalized <= bars_cfg[k]
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
        log("running timer")
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

local player_is_atronach
local damage_magicka = tes3.effect.damageMagicka

local function magic_icons_updated()
    ---@type tes3uiElement
    local icons_box = hud.effect_icons and hud.effect_icons:findChild("MenuMulti_magic_icons_box") 
    if not icons_box then return end

    local perm_effects = common.perm_bonuses
    local effect_by_icon = common.effect_by_icon

    log("------ BEGIN magic effect icon updates -----")
    for _, row in pairs(icons_box.children) do
        local hide_row = true
        local id, perm_mag, icon_vis

        for i, icon in pairs(row.children) do
            if not icon.contentPath then goto next_icon end

            id = effect_by_icon[icon.contentPath]
            if not id then goto next_icon end
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
                    icon_vis = tes3.getEffectMagnitude{effect=id, reference=tes3.player} > 0
                else
                    icon_vis = true
                end
            else
                if common.targets_skill_ids[id] then
                    icon_vis = false
                    local mag
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
                    local mag
                    for _, attr_id in pairs(tes3.attribute) do
                        mag = tes3.getEffectMagnitude{effect=id, attribute=attr_id, reference=tes3.player}
                        if mag > 0 and perm_mag[attr_id] ~= mag then
                            icon_vis = true
                            break
                        end
                    end
                else
                    local mag = tes3.getEffectMagnitude{effect=id, reference=tes3.player}
                    icon_vis = mag > 0 and mag ~= perm_mag
                    -- handling this special case separately because (at the time of writing), 
                    -- `tes3.getEffectMagnitude` does not work on `stuntedMagicka`
                    -- if id == damage_magicka and player_is_atronach then
                    --     -- hide the icon if the player is an atronach
                    --     icon_vis = false
                    -- else
                    --     icon_vis = perm_mag ~= tes3.getEffectMagnitude{effect=id, reference=tes3.player}
                    -- end
                end
            end
            if log.level == 5 then
                local name = tes3.getMagicEffectName{effect=id}
                log:trace("%i: %q (id = %s)\n\t\z
                    icon_path = %q\n\t\z
                    magnitude: %s\n\t\z
                    perm_bonuses = %s\n\t\z
                    new visibility = %s",
                    i, name, id,
                    icon.contentPath, 
                    tes3.getEffectMagnitude{effect=id, reference=tes3.player},
                    perm_mag,
                    icon_vis
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
    player_is_atronach = tes3.mobilePlayer and #tes3.mobilePlayer:getActiveMagicEffects{effect=tes3.effect.stuntedMagicka} ~= 0
    timer.delayOneFrame(magic_icons_updated)

end

local function update_menu_multi_on_menu_exit()
    if tes3.player and cfg.menu_multi.enable then
        timer_callbacks.menu_multi()
    end
end

local function update()
    hide_map = cfg.hide_map
    upd_reg{event=tes3.event.loaded, callback=update_icons_on_load, register=cfg.hide_magic_effect_icons}
    upd_reg{event=tes3.event.activeMagicEffectIconsUpdated, callback=magic_icons_updated, register=cfg.hide_magic_effect_icons}
    upd_reg{tes3.event.menuExit, update_menu_multi_on_menu_exit}

    update_timers()
    
end
common.initialize()
local function initialized()
    if not tes3.isLuaModActive("Companion Health Bars") then
         cfg.companion_bars.enable = false
     end
    update()
    event.register(tes3.event.loaded, update_timers)

    log:write_init_message()
end


-- if tes3.isInitialized() then
--     initialized()
--     common.initialize()
--     common.update_perm_bonuses()
--     common.update_effect_by_icon_tbl()
--     common.update_MM_hud_data()
--     common.clear_MM_hud_data()
-- end

event.register(tes3.event.initialized, initialized)

-- =============================================================================
-- MCM
-- =============================================================================
event.register("modConfigReady", function (e)
    local MCM = require("herbert100.MCM").new()

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
    MCM.template.postCreate = function(self)
        if not tes3.isLuaModActive("Companion Health Bars") then
            cfg.companion_bars.enable = false
        end
    end
    page:add_log_settings()

    MCM:register()
end)