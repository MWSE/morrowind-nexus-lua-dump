local log = Herbert_Logger.new()

---@class herbert.HC.common
local common = {
    effect_by_icon = {}, ---@type table<string, tes3.effect>
    targets_skill_ids = {}, ---@type table<tes3.effect, boolean>
    targets_attribute_ids = {}, ---@type table<tes3.effect, boolean>
    has_no_magnitude = {}, ---@type table<tes3.effect, boolean>

    hud = {
        equipped_block = nil,   ---@type tes3uiElement?
        equipped = nil,         ---@type table<string, tes3uiElement>?
        bars = nil,             ---@type table<string, tes3uiElement>?
        effect_icons = nil,     ---@type tes3uiElement?
        map = nil,              ---@type tes3uiElement?
        spammer_hot_quick = nil, ---@type tes3uiElement?
        ashfall = nil, ---@type table<string, tes3uiElement?>
    },
    active_companions = {}, ---@type table<string, mwseSafeObjectHandle>
    -- table containing information about permanent effect bonuses.
    -- if an effect targets skills/attributes, then `perm_bonuses[id]` will be a table containing information
    -- about permanent bonuses for each skill/attribute
    -- otherwise, `perm_bonuses[id]` will be a number containing the mangnitude of the effect
    perm_bonuses = {}, ---@type table<tes3.effect, number|table<tes3.skill|tes3.attribute, number>>
    bad_anim_states = {
        [tes3.animationState.dead] = true,
        [tes3.animationState.dying] = true,
    },
    
}


-- update the list of all companions
function common.update_active_companions()
    if not tes3.player  or not tes3.player.cell then return end

    table.clear(common.active_companions)
    local active_companions, bad_anim_states = common.active_companions, common.bad_anim_states
    -- local player_pos = tes3.player.position
    -- local max_dist = 100 * 22.1

    for _, mob in ipairs(tes3.mobilePlayer.friendlyActors) do
        if  mob.isDead == false
        -- and mob.position:distance(player_pos) <= max_dist
        and mob.health.current > 0
        and tes3.getCurrentAIPackageId{reference=mob} == tes3.aiPackage.follow
        and not bad_anim_states[mob.actionData.animationAttackState]
        then
            local ref = mob.reference
            active_companions[ref.id] = tes3.makeSafeObjectHandle(ref)
        end
    end
end

function common.clear_MM_hud_data()
    table.clear(common.hud)
end


function common.update_effect_by_icon_tbl()
    table.clear(common.targets_skill_ids)
    table.clear(common.targets_attribute_ids)
    table.clear(common.has_no_magnitude)
    for _, id in pairs(tes3.effect) do 
        local effect = tes3.getMagicEffect(id)
        if not effect then goto next_effect end

        -- local path = "Icons\\" .. effect.icon
        local path = string.lower("Icons\\" .. effect.icon)
        log:trace("effect %q has icon = %q", effect.name, path)
        common.effect_by_icon[path] = id
        if effect.targetsSkills then
            common.targets_skill_ids[id] = true
        end
        if effect.targetsAttributes then
            common.targets_attribute_ids[id] = true
        end
        if effect.hasNoMagnitude then
            common.has_no_magnitude[id] = true
        end

        ::next_effect::
    end
    log:trace("effect_by_icon = %s", require("inspect").inspect, common.effect_by_icon)
end

function common.update_MM_hud_data()
    common.clear_MM_hud_data()

    local hud = common.hud

	local mm = tes3ui.findMenu("MenuMulti")
    if not mm then return end
    -- Bottom row
    local bottom_row = mm:findChild("MenuMulti_bottom_row")
    if not bottom_row then return end
    -- Bars, equipped weapon/magic, sneak indicator, equipped notification
    local bottom_row_left = bottom_row.children[1]
    if bottom_row_left then

        local player_bars = bottom_row_left:findChild("MenuMulti_fillbars_layout")
        if player_bars then
           hud.bars = {
                health = player_bars:findChild("MenuStat_health_fillbar"),
                magicka = player_bars:findChild("MenuStat_magic_fillbar"),
                fatigue = player_bars:findChild("MenuStat_fatigue_fillbar"),
            }
        end

       hud.equipped = {
            magic = bottom_row_left:findChild("MenuMulti_magic_layout"),
            weapon = bottom_row_left:findChild("MenuMulti_weapon_layout")
        }
       hud.equipped_block=hud.equipped.weapon.parent.parent
    end

    -- Active magic effects, map, map notification
    local bottom_row_right = bottom_row.children[2]
    if bottom_row_right then
        hud.map = bottom_row_right:findChild("MenuMulti_map")
        hud.effect_icons = bottom_row_right:findChild("MenuMulti_magic_icons_layout")
    end

    hud.spammer_hot_quick = mm:findChild("Spa_HotQuick")

    local ashfall_main = mm:findChild("Ashfall:HUD_mainHUDBlock")
    if ashfall_main then
        log("found ashfall main")
        hud.ashfall = {
            main = ashfall_main,
            wetness_block = ashfall_main:findChild("Ashfall:HUD_wetnessBlock"),
            wetness_bar = ashfall_main:findChild("Ashfall:HUD_wetnessBar"),
            sheltered_block = ashfall_main:findChild("Ashfall:HUD_shelteredBlock"),

            rain_sheltered = ashfall_main:findChild("Ashfall:HUD_rain_sheltered"),
            rain_unsheltered = ashfall_main:findChild("Ashfall:HUD_rain_unsheltered"),
            sun_sheltered = ashfall_main:findChild("Ashfall:HUD_sun_sheltered"),
            sun_unsheltered = ashfall_main:findChild("Ashfall:HUD_sun_unsheltered"),

            left_temp_current = ashfall_main:findChild("Ashfall:HUD_leftTempPlayerBar"),
            right_temp_current = ashfall_main:findChild("Ashfall:HUD_rightTempPlayerBar"),

            left_temp_limit = ashfall_main:findChild("Ashfall:HUD_leftTempLimitBar"),
            right_temp_limit = ashfall_main:findChild("Ashfall:HUD_rightTempLimitBar"),
        }
        log("set hud.ashfall = %s", require("inspect").inspect, hud.ashfall)

    end
    

end

local targets_attrs = common.targets_attribute_ids
local targets_skills = common.targets_skill_ids
local no_mag = common.has_no_magnitude
-- add a permanent effect bonus.
---@param active_magic_effect tes3activeMagicEffect
---@param effect_id tes3.effect
local function add_perm_bonus(active_magic_effect, effect_id)

    -- table will be the subtable
    local tbl, id ---@type table, tes3.skill|tes3.attribute|tes3.effect


    if targets_skills[effect_id] then
        tbl = table.getset(common.perm_bonuses, effect_id, {})
        id = active_magic_effect.skillId
    elseif targets_attrs[effect_id] then
        tbl = table.getset(common.perm_bonuses, effect_id, {})
        id = active_magic_effect.attributeId
    else
        tbl = common.perm_bonuses
        id = effect_id
    end
    -- special case for things with no magnitude
    if no_mag[effect_id] then
        tbl[id] = 1
    else
        -- local magic_effect = tes3.getMagicEffect(active_magic_effect.effectId).
        tbl[id] = (tbl[id] or 0) + active_magic_effect.magnitude
        -- tbl[id] = (tbl[id] or 0) + active_magic_effect.effectInstance.magnitude
    end
end


function common.update_perm_bonuses()
    common.perm_bonuses = {}
    local bonuses = common.perm_bonuses
    log("---- updating perm bonuses ----")

    for i, s in ipairs(tes3.mobilePlayer.activeMagicEffectList) do
        local instance = s.instance
        local id = s.effectId
        local src_type = instance.sourceType
        if log.level == 5 then
            local name = tes3.getMagicEffectName{effect=s.effectId}
            local cast_type
            if src_type == tes3.magicSourceType.spell then
                cast_type = table.find(tes3.spellType, instance.source.castType)
            elseif src_type == tes3.magicSourceType.enchantment then
                cast_type = table.find(tes3.enchantmentType, instance.source.castType)
            else
                cast_type = "alchemy"
            end
            log:trace("%i: %q (id = %s). (skill = %q; attr = %q)\n\t\z
                magnitude: %s (effect = %s)\n\t\z
                src_type: %q\n\t\z
                cast_type: %q", 
                i, name, id,
                s.skillId and s.skillId >= 0 and table.find(tes3.skill, s.skillId),
                s.attributeId and s.attributeId >= 0 and table.find(tes3.attribute, s.attributeId),
                s.magnitude, s.effectInstance.effectiveMagnitude,
                table.find(tes3.magicSourceType, src_type), 
                cast_type
            )
        end
        
        if src_type == tes3.magicSourceType.spell then

            local src = instance.source ---@type tes3spell
            if src.castType == tes3.spellType.ability then
                add_perm_bonus(s, id)
                log:trace("%i: this is a constant spell. adding bonus", i)
            end

        elseif src_type == tes3.magicSourceType.enchantment then 

            local src = instance.source ---@type tes3enchantment
            if src.castType == tes3.enchantmentType.constant then
                add_perm_bonus(s, id)
                log:trace("%i: this is a constant enchantment. adding bonus", i)
            end

        end
    end
    log("---- DONE updating perm bonuses ----")

end

function common.initialize()
    event.register(tes3.event.activeMagicEffectIconsUpdated, common.update_perm_bonuses, {priority = 100000})
    event.register(tes3.event.initialized, common.update_effect_by_icon_tbl, {priority = 10000})
    event.register(tes3.event.loaded, common.update_MM_hud_data)
    event.register(tes3.event.load, common.clear_MM_hud_data)
end

return common