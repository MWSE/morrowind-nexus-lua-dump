local core = require("openmw.core")
local types = require("openmw.types")
local self = require('openmw.self')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local Player = types.Player
local WepType = types.Weapon.TYPE

-- @globals
local MOD_NAME = "ModernCombat"
local MOD_SETTINGS = MOD_NAME .. "Settings__"

local settings = storage.globalSection(MOD_SETTINGS)
local global_values = storage.globalSection(MOD_NAME)

-- @interface
I.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "Modern combat"
}

-- @permanent:speed
local attack_commited_speed_adjusted = 0
local dodge_speed_adjusted = 0
local speed_adjusted = 0
-- @permanent:skills
local athletics_adjusted = 0
local health_adjusted = 0
local strength_adjusted = 0
-- @temporary:time
local last_update_time = 0
local last_attack_time = 0
local last_dodge_time = 0
local last_attack_commited_time = 0
local stamina_reservation_time = 0
-- @temporary:gmst
local fFatigueReturnBase = core.getGMST("fFatigueReturnBase")
local fFatigueReturnMult = core.getGMST("fFatigueReturnMult")
local fEndFatigueMult = core.getGMST("fEndFatigueMult")
-- @temporary:mechanics
local dodge_turn_direction = 0
local reserverd_stamina = 0
local reserverd_stamina_recovery = 0
local health_from_previous_frame = 0
local melee_protection_effectivity = 100
-- @temporary:const
local max_time_in_combat = 3

local function onUpdate()
    local is_mod_disabled = settings:get("Disabled")
    local is_mod_enabled = not is_mod_disabled

    local fatigue = Player.stats.dynamic.fatigue(self)
    local health = Player.stats.dynamic.health(self)
    local magicka = Player.stats.dynamic.magicka(self)

    local level = Player.stats.level(self)

    local strength = Player.stats.attributes.strength(self)
    local endurance = Player.stats.attributes.endurance(self)
    local speed = Player.stats.attributes.speed(self)
    local athletics = Player.stats.skills.athletics(self)

    -- un-modified value
    local base_endurance = endurance.modified
    local total_endurance = endurance.modified

    local base_strength = strength.base - strength_adjusted
    local mod_strength = strength.modified - strength.base
    local total_strength = base_strength + mod_strength;

    local base_speed = speed.base - speed_adjusted - dodge_speed_adjusted + attack_commited_speed_adjusted
    local mod_speed = speed.modified - speed.base
    local total_speed = mod_speed + base_speed

    local base_athletics = athletics.base - athletics_adjusted
    local mod_athletics = athletics.modified - athletics.base
    local total_athletics = mod_athletics + base_athletics

    local base_health = health.base - health_adjusted
    local mod_health = health.modified or health.base - health.base
    local total_health = mod_health + base_health

    -- Player state 
    local is_move = self.controls.movement ~= 0
    local is_run = self.controls.run
    local is_move_backward = self.controls.movement < 0
    local is_move_forward = self.controls.movement > 0
    local is_move_side = self.controls.sideMovement ~= 0
    local is_jump = self.controls.jump
    local is_attack = self.controls.use ~= 0
    local in_air = not Player.isOnGround(self)
    local in_combat = last_attack_time ~= 0
    local can_move = Player.canMove(self)

    -- time helpers
    local real_time = core.getRealTime()
    local seconds_passed_since_update = 0
    if last_update_time ~= 0 then
        seconds_passed_since_update = real_time - last_update_time
    end

    -- combat mode
    if is_attack then
        last_attack_time = real_time
    elseif real_time - last_attack_time > max_time_in_combat then
        last_attack_time = 0
    end

    -- STAMINA & FATIGUE
    -- =================
    -- * Stops fatigue regeneration while running or jumping 
    -- * Increase fatigue drain durin backward movement 
    if is_mod_enabled and (is_attack or is_move or is_jump or in_air) and (in_combat and can_move) then
        local backward_fatigue_drain = 0
        if is_move_backward and settings:get("Backward") then
            backward_fatigue_drain = fatigue.base * 0.15 * seconds_passed_since_update
        end

        local base_loss = fFatigueReturnBase + fFatigueReturnMult
        local endur_loss = total_endurance * fEndFatigueMult
        local fatigue_loss = base_loss * seconds_passed_since_update

        fatigue.current = fatigue.current - fatigue_loss - backward_fatigue_drain
    elseif is_mod_enabled then
        local fatigue_regen = (1.1 + (0.7 * total_endurance))
        local fatigue_regen_per_second = fatigue_regen * seconds_passed_since_update
        local next_fatigue = fatigue.current + fatigue_regen_per_second
        if next_fatigue < (fatigue.base - reserverd_stamina) then
            fatigue.current = next_fatigue
        end
    end

    -- DODGE
    -- =====
    local can_dodge = dodge_speed_adjusted == 0
    if (is_move_backward or (is_move_side and settings:get("Dodge"))) and
        (is_mod_enabled and is_jump and can_move and can_dodge) then
        dodge_speed_adjusted = 0

        if is_move_side then
            dodge_turn_direction = self.controls.sideMovement
        end

        if is_move_backward then
            dodge_turn_direction = 0
        end

        if speed.modified < 300 then
            dodge_speed_adjusted = 300 - speed.modified
        end

        speed.base = speed.base + dodge_speed_adjusted
        fatigue.current = fatigue.current - 20

        last_attack_time = real_time
        last_dodge_time = real_time

        if dodge_turn_direction ~= 0 then
            self.controls.yawChange = dodge_turn_direction * 2
        end
    end

    -- camera rotation
    if last_dodge_time ~= 0 then
        if dodge_turn_direction ~= 0 then
            self.controls.yawChange = -dodge_turn_direction * 0.1
        end
    end

    if dodge_speed_adjusted ~= 0 and real_time - last_dodge_time > 0.1 then
        speed.base = speed.base - dodge_speed_adjusted
        dodge_speed_adjusted = 0
        dodge_turn_direction = 0
        last_dodge_time = 0
    end

    -- WALK & RUN
    -- ==========
    -- * Increase run speed for early levels
    -- * Increase walk speed for early levels
    if (is_move or is_move_side) and is_mod_enabled then
        if speed_adjusted == 0 and base_speed < 50 then
            speed_adjusted = 50 - base_speed
            speed.base = speed.base + speed_adjusted
        end
    elseif speed_adjusted ~= 0 then
        speed.base = speed.base - speed_adjusted
        speed_adjusted = 0
    end

    if is_run and is_mod_enabled then
        if athletics_adjusted == 0 and base_athletics < 70 then
            athletics_adjusted = 70 - base_athletics
            athletics.base = athletics.base + athletics_adjusted
        end
    elseif athletics_adjusted ~= 0 then
        athletics.base = athletics.base - athletics_adjusted
        athletics_adjusted = 0
    end

    -- ATTACK COMMITED
    -- ===============
    -- * Lock player in backward direction on attack
    -- * Increse player forward attack direction
    if is_attack and is_mod_enabled then
        last_attack_commited_time = real_time
    end

    if last_attack_commited_time ~= 0 and real_time - last_attack_commited_time >= 0.7 then
        speed.base = speed.base + attack_commited_speed_adjusted
        attack_commited_speed_adjusted = 0
        last_attack_commited_time = 0
    elseif last_attack_commited_time ~= 0 then
        local prev_adjust = attack_commited_speed_adjusted
        local total_speed = speed.modified + prev_adjust
        if is_move_forward then
            attack_commited_speed_adjusted = total_speed * -0.1
        else
            attack_commited_speed_adjusted = total_speed * 0.8
        end
        speed.base = speed.base + prev_adjust - attack_commited_speed_adjusted
    end

    -- RETROACTIVE HEALTH
    -- ==================
    -- * Adjust health dynamically based on endurance
    local health_mod = 45 + math.floor(level.current * (base_endurance / 7.5))
    if is_mod_enabled and health.base < health_mod then
        local next_health_adjusted = health_mod - (health.base - health_adjusted)
        if next_health_adjusted ~= health_adjusted then
            health.base = health.base - health_adjusted + next_health_adjusted
            health_adjusted = next_health_adjusted
        end
    elseif is_mod_disabled and health_adjusted ~= 0 then
        health.base = health.base - health_adjusted
        health_adjusted = 0
    end

    -- REDUCE STRENGHT ON LOW SKILL
    -- ==========================
    -- * Reduce strength when using unskilled weapon
    local weapon = Player.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    local melee_weapon = false
    local is_weapon = weapon and weapon.type == types.Weapon
    if is_mod_enabled and is_weapon and Player.stance(self) == types.Actor.STANCE.Weapon then
        local wep_type = types.Weapon.record(weapon).type;
        local skill = nil;

        if wep_type == WepType.LongBladeTwoHand or wep_type == WepType.LongBladeOneHand then
            skill = Player.stats.skills.longblade(self)
            melee_weapon = true
        elseif wep_type == WepType.ShortBladeOneHand then
            skill = Player.stats.skills.shortblade(self)
            melee_weapon = true
        elseif wep_type == WepType.SpearTwoWide then
            skill = Player.stats.skills.spear(self)
            melee_weapon = true
        elseif wep_type == WepType.AxeTwoHand or type == WepType.AxeOneHand then
            skill = Player.stats.skills.axe(self)
            melee_weapon = true
        elseif wep_type == WepType.BluntOneHand or wep_type == WepType.BluntTwoClose or wep_type == WepType.BluntTwoWide then
            skill = Player.stats.skills.bluntweapon(self)
            melee_weapon = true
        elseif wep_type == WepType.MarksmanBow or wep_type == WepType.MarksmanCrossbow or wep_type ==
            WepType.MarksmanThrown then
            skill = Player.stats.skills.marksman(self)
        end

        if skill ~= nil then
            strength_mod = math.floor((skill.modified / 100 - 1) * total_strength)
            strength.base = strength.base - strength_adjusted + strength_mod
            strength_adjusted = strength_mod
        elseif strength_adjusted ~= 0 then
            strength.base = strength.base - strength_adjusted
            strength_adjusted = 0
        end
    elseif strength_adjusted ~= 0 then
        strength.base = strength.base - strength_adjusted
        strength_adjusted = 0
    end

    local remain_health = (health.current / health.base);
    if remain_health >= 0.5 then
        melee_protection_effectivity = math.min(100, melee_protection_effectivity + seconds_passed_since_update * 2)
    else
        melee_protection_effectivity = math.max(0, melee_protection_effectivity - seconds_passed_since_update * 2)
    end

    if is_mod_enabled and remain_health <= 0.45 and not in_combat then
        health.current = health.current + health.base * 0.05 * seconds_passed_since_update
    end

    local can_recovery =
        health_from_previous_frame ~= 0 and melee_weapon and (remain_health <= 0.5) and health.current > 0
    local health_diff = health_from_previous_frame - health.current
    if is_mod_enabled and can_recovery and health_diff > 0 then
        local recovery_amount = math.min(math.max(1 - (remain_health / 0.5), 0.2), 0.8) *
                                    math.max((melee_protection_effectivity / 100), 0.5)

        health.current = (health.current + health_diff) - (health_diff * (1 - recovery_amount))
    end

    health_from_previous_frame = health.current

    if health_diff > 0 then
        last_attack_time = real_time
    end

    local spell_stance = Player.stance(self) == types.Actor.STANCE.Spell
    local current_magicka = magicka.current;
    local base_magicka = magicka.base;
    local convesion_step = math.min(5 * seconds_passed_since_update, 5)
    if spell_stance and current_magicka / base_magicka < 0.35 and reserverd_stamina / fatigue.base < 0.8 then
        stamina_reservation_time = real_time
        reserverd_stamina = reserverd_stamina + convesion_step
        magicka.current = magicka.current + convesion_step
        local reduced_stamina = fatigue.base - reserverd_stamina
        if fatigue.current > reduced_stamina then
            fatigue.current = reduced_stamina
        end
    end

    if real_time - stamina_reservation_time > 5 and reserverd_stamina ~= 0 then
        reserverd_stamina_recovery = reserverd_stamina
        reserverd_stamina = reserverd_stamina - convesion_step
        if reserverd_stamina <= 0 then
            reserverd_stamina = 0
            reserverd_stamina_recovery = 0
        end
    elseif reserverd_stamina_recovery ~= 0 and not in_combat then
        reserverd_stamina_recovery = reserverd_stamina_recovery - convesion_step
        if reserverd_stamina_recovery > 0 then
            reserverd_stamina = reserverd_stamina - convesion_step
        else
            reserverd_stamina_recovery = 0
        end
    end

    core.sendGlobalEvent('PlayerStats', {{
        fatigue = fatigue.current / fatigue.base
    }})

    last_update_time = real_time
end

local function onSave()
    return {
        attack_commited_speed_adjusted = attack_commited_speed_adjusted,
        dodge_speed_adjusted = dodge_speed_adjusted,
        athletics_adjusted = athletics_adjusted,
        health_adjusted = health_adjusted,
        speed_adjusted = speed_adjusted,
        strength_adjusted = strength_adjusted
    }
end

local function onLoad(data)
    attack_commited_speed_adjusted = data.attack_commited_speed_adjusted or 0
    dodge_speed_adjusted = data.dodge_speed_adjusted or 0
    athletics_adjusted = data.athletics_adjusted or 0
    health_adjusted = data.health_adjusted or 0
    speed_adjusted = data.speed_adjusted or 0
    strength_adjusted = data.strength_adjusted or 0
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad
    }
}
