local self = require('openmw.self')
local core = require('openmw.core')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ai = require('openmw.interfaces').AI

-- @globals
local MOD_NAME = "ModernCombat"
local MOD_SETTINGS = MOD_NAME .. "Settings__"

local settings = storage.globalSection(MOD_SETTINGS)
local global_values = storage.globalSection(MOD_NAME)

-- @permanent:magick
local os_conjuration = 0
local os_alteration = 0
local os_illusion = 0
local os_mysticism = 0
local os_restoration = 0
local os_destruction = 0
-- @permanent:melee
local os_longblade = 0
local os_shortblade = 0
local os_spear = 0
local os_axe = 0
local os_bluntweapon = 0
local os_marksman = 0
local os_handtohand = 0
-- @permanent:speed
local os_athletics = 0
-- @permanent:attributes
local oa_luck = 0
local oa_speed = 0
-- @permanent:flags
local is_actor_affected = false
local is_snapshot_created = false

-- @temporary:const
local is_creature = types.Creature.objectIsInstance(self)
local is_humanoid = not is_creature
-- @temporary:mechanics:fatigue 
local low_fatigue_timer = 0
-- @temporary:mechanics:magick 
local low_magicka_timer = 0
local prev_magicka = 0
-- @temporary:mechanics:pcdamage 
local prev_health = 0
-- @temporary:utils
local last_update_time = core.getRealTime()
local is_player_follower = false

function on_update(is_inactive)
    -- @shader:utils
    local combat_target = ai.getActiveTarget('Combat') or ai.getActiveTarget('Pursue')
    local is_mod_disabled = settings:get("Disabled")
    local is_mod_enabled = not is_mod_disabled
    local is_script_active = not is_inactive
    local is_script_disabled = not is_script_active
    local is_in_combat = combat_target ~= nil

    -- @optimization:skip peacefull actors
    local can_skip_update = not is_actor_affected and (not is_in_combat or is_mod_disabled)
    if can_skip_update then
        return;
    end

    -- @mechanics:pcdamage
    -- Reduce player damage on low fatigue
    local d_health = types.NPC.stats.dynamic.health(self)
    local current_health = d_health.current
    local health_diff = prev_health - current_health
    local is_hp_damaged = health_diff > 0
    if current_health > 0 and is_hp_damaged and not is_player_follower then
        local reduce_amount = health_diff * (1 - math.max(global_values:get("PlayerFatigue"), 0.25))
        current_health = current_health + reduce_amount
        d_health.current = current_health
    end
    prev_health = current_health

    -- @optimization:update attributes once per 2 seconds
    local real_time = core.getRealTime()
    local seconds_passed_since_update = real_time - last_update_time
    local is_new_actor_in_combat = is_in_combat and not is_actor_affected
    if (seconds_passed_since_update < 2) and not is_new_actor_in_combat then
        return;
    else
        is_actor_affected = true
        last_update_time = real_time
    end

    -- @shared
    local skills = types.NPC.stats.skills
    local attributes = types.NPC.stats.attributes
    -- @shared:magick
    local s_conjuration = skills.conjuration(self)
    local s_alteration = skills.alteration(self)
    local s_illusion = skills.illusion(self)
    local s_mysticism = skills.mysticism(self)
    local s_restoration = skills.restoration(self)
    local s_destruction = skills.destruction(self)
    -- @shared:melee
    local s_longblade = skills.longblade(self)
    local s_shortblade = skills.shortblade(self)
    local s_spear = skills.spear(self)
    local s_axe = skills.axe(self)
    local s_bluntweapon = skills.bluntweapon(self)
    local s_marksman = skills.marksman(self)
    local s_handtohand = skills.handtohand(self)
    -- @shared:speed
    local s_athletics = skills.athletics(self)
    -- @shared:attributes
    local a_speed = attributes.speed(self)
    local a_luck = attributes.luck(self)

    -- @mechanics:snapshot origin attributes
    if not is_snapshot_created then
        is_snapshot_created = true

        oa_speed = a_speed.base
        oa_luck = a_luck.base

        -- creatures doesn't have attributes
        if is_creature then
            return
        end

        os_conjuration = s_conjuration.base
        os_alteration = s_alteration.base
        os_illusion = s_illusion.base
        os_mysticism = s_mysticism.base
        os_restoration = s_restoration.base
        os_destruction = s_destruction.base

        os_longblade = s_longblade.base
        os_shortblade = s_shortblade.base
        os_spear = s_spear.base
        os_axe = s_axe.base
        os_bluntweapon = s_bluntweapon.base
        os_marksman = s_marksman.base
        os_handtohand = s_handtohand.base

        os_athletics = s_athletics.base

        return
    end

    -- @mechanics:restore origin attributes
    if is_snapshot_created and (is_mod_disabled or is_script_disabled or not is_in_combat) then
        is_snapshot_created = false
        is_actor_affected = false

        a_speed.base = oa_speed
        a_luck.base = oa_luck

        -- creature doesn't have attributes
        if is_creature then
            return
        end

        s_conjuration.base = os_conjuration
        s_alteration.base = os_alteration
        s_illusion.base = os_illusion
        s_mysticism.base = os_mysticism
        s_restoration.base = os_restoration
        s_destruction.base = os_destruction

        s_longblade.base = os_longblade
        s_shortblade.base = os_shortblade
        s_spear.base = os_spear
        s_axe.base = os_axe
        s_bluntweapon.base = os_bluntweapon
        s_marksman.base = os_marksman
        s_handtohand = os_handtohand

        s_athletics.base = os_athletics

        return
    end

    -- @shared:stats
    local d_magicka = types.NPC.stats.dynamic.magicka(self)
    local d_fatigue = types.NPC.stats.dynamic.fatigue(self)
    -- @shared:modifiers
    local mod_destruction = 1

    -- @mechanics:magick
    local is_magick_user = d_magicka.current / d_magicka.base < 0.25
    local is_low_magick_active = low_magicka_timer ~= 0
    local is_low_magick_disabled = low_magicka_timer == 0
    if is_magick_user and is_low_magick_disabled then
        low_magicka_timer = 4
    end

    if is_low_magick_active then
        low_magicka_timer = low_magicka_timer - 1
    end

    if is_low_magick_active then
        mod_destruction = 0
        d_magicka.current = d_magicka.current + d_magicka.base * 0.25
    elseif d_magicka.current ~= prev_magicka then
        d_magicka.current = d_magicka.current - d_magicka.current * 0.1
    end

    prev_magicka = d_magicka.current

    -- @mechanics:fatigue
    local is_low_fatigue = d_fatigue.current / d_fatigue.base < 0.1
    if is_low_fatigue then
        low_fatigue_timer = low_fatigue_timer + 1
    end
    if low_fatigue_timer >= 6 then
        low_fatigue_timer = 0
        d_fatigue.current = d_fatigue.base
    end

    is_player_follower = get_is_player_follower()

    -- @mechanics:always hit creature
    if is_creature then
        if a_luck.base < 1000 then
            a_luck.base = 1000
        end

        if a_speed.base < 10 then
            a_speed.base = 10
        end

        return;
    end

    -- @mechanics:always hit & cast for humanoids
    if s_athletics.base < 70 then
        s_athletics.base = 70
    end

    if a_speed.base < 50 then
        a_speed.base = 50
    end

    mod_skill(s_conjuration, os_conjuration, 1)
    mod_skill(s_alteration, os_alteration, 1)
    mod_skill(s_illusion, os_illusion, 1)
    mod_skill(s_mysticism, os_mysticism, 1)
    mod_skill(s_restoration, os_restoration, 1)
    mod_skill(s_destruction, os_destruction, mod_destruction)
    mod_skill(s_longblade, os_longblade, 1)
    mod_skill(s_shortblade, os_shortblade, 1)
    mod_skill(s_spear, os_spear, 1)
    mod_skill(s_axe, os_axe, 1)
    mod_skill(s_bluntweapon, os_bluntweapon, 1)
    mod_skill(s_marksman, os_marksman, 1)
    mod_skill(s_handtohand, os_handtohand, 1)
end

function get_is_player_follower()
    for key, target in pairs(ai.getTargets('Follow')) do
        if target and target.type == types.Player and target:isValid() then
            return true
        end
    end

    return false
end

function mod_skill(skill, skill_origin, skill_mod)
    local damage_mod = (100 - (skill.damage or 0)) / 100
    if damage_mod < 0.2 then
        damage_mod = 0.2
    end
    skill.base = (skill_origin + 100) * skill_mod * damage_mod
end

return {
    engineHandlers = {
        onInactive = function()
            on_update(true)
            core.sendGlobalEvent('ActorInactive', {self.object})
        end,
        onActive = function()
            on_update(false)
        end,
        onUpdate = function()
            on_update(false)
        end,
        onSave = function()
            return {
                os_conjuration = os_conjuration,
                os_alteration = os_alteration,
                os_illusion = os_illusion,
                os_mysticism = os_mysticism,
                os_restoration = os_restoration,
                os_destruction = os_destruction,

                os_longblade = os_longblade,
                os_shortblade = os_shortblade,
                os_spear = os_spear,
                os_axe = os_axe,
                os_bluntweapon = os_bluntweapon,
                os_marksman = os_marksman,

                os_athletics = os_athletics,

                oa_luck = oa_luck,
                oa_speed = oa_speed,

                is_actor_affected = is_actor_affected,
                is_snapshot_created = is_snapshot_created
            }
        end,
        onLoad = function(data)
            os_conjuration = data.os_conjuration
            os_alteration = data.os_alteration
            os_illusion = data.os_illusion
            os_mysticism = data.os_mysticism
            os_restoration = data.os_restoration
            os_destruction = data.os_destruction

            os_longblade = data.os_longblade
            os_shortblade = data.os_shortblade
            os_spear = data.os_spear
            os_axe = data.os_axe
            os_bluntweapon = data.os_bluntweapon
            os_marksman = data.os_marksman

            os_athletics = data.os_athletics

            oa_luck = data.oa_luck
            oa_speed = data.oa_speed

            is_actor_affected = data.is_actor_affected
            is_snapshot_created = data.is_snapshot_created
        end
    }
}
