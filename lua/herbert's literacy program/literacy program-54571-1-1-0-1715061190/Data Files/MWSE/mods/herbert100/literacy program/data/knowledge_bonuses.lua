
local SK = tes3.skill ---@type table<string, tes3.skill>
local EV = tes3.event

local hlib = require("herbert100")

local knowledge_manager = hlib.import("Knowledge_Manager") ---@type herbert.HLP.Knowledge_Manager
local log = hlib.Logger()


---@param p herbert.HLP.Knowledge_Bonus.new_params
local function new_bonus(p) return knowledge_manager:register_knowledge_bonus(p) end

---@param skill_id tes3.skill
---@param mults table<tes3.skillType, number>
---@return number
local function get_skill_type_mult(skill_id, mults)
    return tes3.mobilePlayer and mults[tes3.mobilePlayer.skills[1+skill_id].type] or 1
end

do -- alchemy
    local ps_bonus = new_bonus{name="Brewing Chance", 
        skill_ids = {tes3.skill.alchemy}, 
        calculate_bonus = function(k)
            return 0.75 * (1 - 2^(-0.000035*(0.5*k^2-0.5*k)))
        end,
        event_id = tes3.event.potionBrewSkillCheck,
        ---@param e potionBrewSkillCheckEventData
        event_callback = function (self, e)
            local player = tes3.mobilePlayer

            local vanilla_brew_chance = player.alchemy.current + 0.1 * player.intelligence.current + 0.1 * player.luck.current

            local brew_chance = (1 + self:get_bonus()) * vanilla_brew_chance
    
            local roll = math.floor(100 * math.random())
            if roll <= brew_chance then
                local fPotionStrengthMult = tes3.findGMST(tes3.gmst.fPotionStrengthMult).value
                e.potionStrength = fPotionStrengthMult * e.mortar.quality * vanilla_brew_chance
                e.success = true
            else
                e.potionStrength = -1
                e.success = false
            end
        end,
        event_priority = -1,
    }
    new_bonus{name="Potion Strength", 
        skill_ids = ps_bonus.skill_ids, 
        calculate_bonus = function(k)
            return 1 * (1 - 2^(-0.3 * (0.000075 * (0.5 * k^2-k))))
        end,
        event_id = tes3.event.potionBrewSkillCheck,
        ---@param e potionBrewSkillCheckEventData
        event_callback = function(self, e)
            if e.success then
                e.potionStrength = e.potionStrength * (1 + self:get_bonus())
            end
        end,
        event_priority = ps_bonus.event_priority-1,
    }
end





do -- weapons
    new_bonus{
        name="Hit Chance", 
        skill_ids={SK.axe, SK.bluntWeapon, SK.longBlade, SK.marksman, SK.spear, SK.shortBlade, SK.handToHand},
        calculate_bonus=function(k, skill_id)
            -- 0.629\left(1-2^{\left(\left(-0.00015\left(0.04x^{2}+10.5x\right)\right)\right)}\right)
            return 0.629 * (1 - 2^(
                -0.00015 * (0.04 * k^2 + 10.5 * k)
            )) * get_skill_type_mult(skill_id, {[0]=1.1, 1.05, 1})
        end, 
        event_id=EV.calcHitChance,
        event_callback=function (self, e) ---@param e calcHitChanceEventData
            if e.attacker ~= tes3.player then return end

            if e.projectile then
                if e.projectile.objectType ~= tes3.objectType.mobileProjectile then return end
                e.hitChance = e.hitChance * (1 + self:get_bonus(tes3.skill.marksman))
                return
            end

            local wpn = tes3.mobilePlayer.readiedWeapon
            if not wpn then
                -- hand to hand
                if tes3.mobilePlayer.weaponReady then
                    local bonus = (1 + self:get_bonus(tes3.skill.handToHand))
                    e.hitChance = e.hitChance * bonus
                    log("applying a %s hitchance bonus to hand to hand attack", bonus)
                end
                return 
            end
            
            local bonus = (1 + self:get_bonus(wpn.object.skillId))
            e.hitChance = e.hitChance * bonus
            log("applying a %s hitchance bonus to attack with %q (skill = %q)", bonus, wpn.object.name, wpn.object.skill.name)
        end
    }

    local function calc_dmg_bonus(k, skill_id)
        -- y=1+0.52\left(1-2^{-0.00004\left(0.001x^{2}+75x\right)}\right)
        return 0.52 * (1 - 2^(
            -0.00004 * (0.001 * k^2 + 75 * k)
        )) * get_skill_type_mult(skill_id, {[0]=1.1, 1.05, 1})
    end
    
    new_bonus{
        name="Damage", 
        skill_ids={SK.axe, SK.bluntWeapon, SK.longBlade, SK.marksman, SK.spear, SK.shortBlade},
        event_id=EV.damage,
        calculate_bonus=calc_dmg_bonus,

        event_callback=function (self, e) ---@param e damageEventData
            if e.attackerReference ~= tes3.player then return end

            if e.projectile then
                if e.projectile.objectType ~= tes3.objectType.mobileProjectile then return end
                e.damage = e.damage * (1 + self:get_bonus(tes3.skill.marksman))
                return
            end

            local wpn = tes3.mobilePlayer.readiedWeapon
            if not wpn then
                -- hand to hand
                if tes3.mobilePlayer.weaponReady then
                    local bonus = (1 + self:get_bonus(tes3.skill.handToHand))
                    e.damage = e.damage * bonus
                    log("applying a %s damage bonus to hand to hand attack", bonus)
                end
                return 
            end
            local bonus = (1 + self:get_bonus(wpn.object.skillId))
            e.damage = e.damage * bonus
            log("applying a %s damage bonus to attack with %q (skill = %q)", bonus, wpn.object.name, wpn.object.skill.name)
        end
    }

    new_bonus{
        name="Fatigue Damage", 
        skill_ids={tes3.skill.handToHand},
        event_id=EV.damageHandToHand,
        calculate_bonus=calc_dmg_bonus,
        event_callback=function (self, e) ---@param e damageHandToHandEventData
            if e.attackerReference ~= tes3.player then return end
            
            e.fatigueDamage = e.fatigueDamage * (1 + self:get_bonus(tes3.skill.handToHand))
        end
    }

end

do -- armor

    -- how many pieces of each armor weight class are we wearing
    local armor_type_counts = {
        [-1] = 0,                           -- unarmored (-1)
        [tes3.armorWeightClass.light] = 0,  -- light armor (0)
        [tes3.armorWeightClass.medium] = 0, -- medium armor (1)
        [tes3.armorWeightClass.heavy] = 0,  -- heavy armor (2)
    }
    -- convert armor type to skill id
    local at_to_skill_id = {
        [-1] = tes3.skill.unarmored,
        [0] = tes3.skill.lightArmor,
        [1] = tes3.skill.mediumArmor,
        [2] = tes3.skill.heavyArmor,
    }
    -- percentage of how much each armor type should get the hit chance bonus vs the damage reduction bonus
    ---@type table<tes3.skill, number>
    local skill_id_hc_mults = {
        [tes3.skill.unarmored] = 1,
        [tes3.skill.lightArmor] = 0.66,
        [tes3.skill.mediumArmor] = 0.33,
        [tes3.skill.heavyArmor] = 0,
    }

    -- could probably make this more efficient, but whatever
    local function calc_armor_type_amounts()
        local ot_armor = tes3.objectType.armor
        local ot_clothing = tes3.objectType.clothing
        for i=-1, 2 do armor_type_counts[i] = 0 end -- reset

        for _, stack in pairs(tes3.player.object.equipment) do
            local item = stack.object
            if item.objectType == ot_clothing then ---@cast item tes3clothing
                armor_type_counts[-1] = armor_type_counts[-1] + 1
            elseif item.objectType == ot_armor then ---@cast item tes3armor
                armor_type_counts[item.weightClass] = armor_type_counts[item.weightClass] + 1
            end
        end
    end
    event.register(tes3.event.loaded, calc_armor_type_amounts)
    event.register(tes3.event.equipped, calc_armor_type_amounts)
    event.register(tes3.event.unequipped, calc_armor_type_amounts)

    
    local function calc_hc_bonus(k, skill_id)
        local raw_bonus = - 0.4 * (1 - 2^(-0.000035*(0.5*k^2-0.5*k)))
        local denom = skill_id == tes3.skill.unarmored and 10 or 11
        -- i probably shouldnt' be adding 1 here, but i'm doing this for consistency with other knowledge bonuses
        return raw_bonus * skill_id_hc_mults[skill_id] / denom
    end

    local function calc_dr_bonus(k, skill_id)
        local raw_bonus = - 0.4 * (1 - 2^(-0.000035*(0.5*k^2-0.5*k)))
        local denom = skill_id == tes3.skill.unarmored and 10 or 11
        -- i probably shouldnt' be adding 1 here, but i'm doing this for consistency with other knowledge bonuses
        return raw_bonus * (1 - skill_id_hc_mults[skill_id]) / denom
    end

    local dr_kb = new_bonus{name = "Damage Reduction",
        skill_ids = {tes3.skill.unarmored, tes3.skill.lightArmor, tes3.skill.mediumArmor, tes3.skill.heavyArmor},
        event_id = tes3.event.damage,
        calculate_bonus = calc_dr_bonus, 
        event_callback = function(self, e) ---@param e damageEventData
            if e.reference ~= tes3.player then return end
            e.damage = e.damage * (1
                + self:get_bonus(at_to_skill_id[-1]) * armor_type_counts[-1]
                + self:get_bonus(at_to_skill_id[0])  * armor_type_counts[0]
                + self:get_bonus(at_to_skill_id[1])  * armor_type_counts[1]
                + self:get_bonus(at_to_skill_id[2])  * armor_type_counts[2]
            )
        end,
        get_display_string = function(self, skill_id)
            local bonus = self:get_bonus(skill_id)
            log("getting bonus display string for %s", self)
            if bonus == 0 or not bonus then return end
            if skill_id == tes3.skill.unarmored then
                return string.format("%s: -%s%% (per clothing piece)", self.name, math.round(-bonus * 100, 1))
            end
            return string.format("%s: -%s%% (per armor piece)", self.name, math.round(-bonus * 100, 1))

        end
    }
    new_bonus{name = "Hit Chance Reduction",
        skill_ids = dr_kb.skill_ids,
        event_id = tes3.event.calcHitChance,
        calculate_bonus = calc_hc_bonus, 
        event_callback = function(self, e) ---@param e calcHitChanceEventData
            if e.target ~= tes3.player then return end
            e.hitChance = e.hitChance * (
                1
                + self:get_bonus(at_to_skill_id[-1]) * armor_type_counts[-1]
                + self:get_bonus(at_to_skill_id[0])  * armor_type_counts[0]
                + self:get_bonus(at_to_skill_id[1])  * armor_type_counts[1]
                + self:get_bonus(at_to_skill_id[2])  * armor_type_counts[2]
            )
        end,
        get_display_string = dr_kb.get_display_string
    }


end

do -- magic

    local mc_bonus = new_bonus{name="Spell Magicka Cost", 
        calculate_bonus = function(k)
            return -0.5 * (1 - 2^(-0.000035*(0.5*k^2-0.5*k)))
        end, 
        skill_ids = table.values(tes3.magicSchoolSkill),
        event_id = EV.spellMagickaUse,
        event_callback = function (self, e)
            if e.caster == tes3.player then
                local skill_id = tes3.magicSchoolSkill[e.spell:getLeastProficientEffect(tes3.mobilePlayer)]
                e.cost = e.cost * (1 + self:get_bonus(skill_id))
            end
        end,
        event_priority=-100,
    }
    log("magic school skills = %s", function ()
        return json.encode(mc_bonus.skill_ids:map(tes3.getSkillName))
    end)
    local cc_bonus = new_bonus{name="Spell Cast Chance", 
        calculate_bonus = function(k)
            return  1.1 * 0.543 * ( 1 - 2^(-0.00005 * (0.5 * k^(1.5) + 70 * k)) )
        end, 
        skill_ids = mc_bonus.skill_ids,
        event_id = EV.spellCast,
        event_callback = function (self, e)
            if e.source.castType ~= tes3.spellType.spell or e.caster ~= tes3.player then return end
    
            local skill_id = tes3.magicSchoolSkill[e.source:getLeastProficientEffect(tes3.mobilePlayer)]
            e.castChance = e.castChance * (1 + self:get_bonus(skill_id))
        end,
        event_priority=-100,
    }

    -- enchanting

    local ec_bonus = new_bonus{name="Charge Use", 
        skill_ids = SK.enchant, 
        calculate_bonus = function(k) 
            return -0.5 * (1 - 2^(-0.000035*(0.5*k^2-0.5*k))) 
        end,
        event_id = EV.enchantChargeUse,
        event_callback = function (self, e)
            e.charge = e.charge * (1 + self:get_bonus())
        end,
        event_priority=-10,
    }
    -- record magicka of the third era compatibility information
    local motte_installed = hlib.is_mod_installed("Magicka of the Third Era")

    -- update the magic menu UI
    ---@param e tes3uiEventData
    local function magic_menu_preupdate(e)
        local spells_list = e.source:findChild("MagicMenu_spells_list")

        -- formats the number to a certain amount of decimal places, depending on the number
        local function fmt_number(num)
            return num <= 0 and num 
                or math.round(num, (num >= 100) and 0 or (num >= 10) and 1 or 2)
        end
        -- update spells menu, but only if magicka of the third era isn't installed
        if motte_installed then
            log("magicka of the third era is installed, skipping spells menu updates")
        else
            local layout = spells_list:findChild("MagicMenu_spell_layout")
            local name_blks = layout:findChild("MagicMenu_spell_names").children
            local cost_blks = layout:findChild("MagicMenu_spell_costs").children
            local chance_blks = layout:findChild("MagicMenu_spell_percents").children

            -- local x = tes3ui.findMenu("MenuMagic"):findChild("MagicMenu_spell_layout"):findChild("MagicMenu_spell_names").children[i]
            for i, name_blk in ipairs(name_blks) do

                local spell = name_blk:getPropertyObject("MagicMenu_Spell", "tes3object") ---@type tes3spell
                if not spell then
                    log:trace("%i) spell %q didnt exist!!", i, name_blk.text)
                    goto next_spell
                end

                log:trace("%i) spell = %q", i, spell.id)
                local skill_id = tes3.magicSchoolSkill[spell:getLeastProficientSchool(tes3.mobilePlayer)]
                if not skill_id or skill_id <= 0 then
                    log:trace("skill_id for %q couldn't be found", name_blk.text)
                    goto next_spell
                end

                log:trace("updating spell %q. skill = %q.", name_blk.text, tes3.skillName[skill_id])
                local cost_bonus = mc_bonus:get_bonus(skill_id)
                if cost_bonus and cost_bonus ~= 1 then
                    local new_cost = spell.magickaCost * cost_bonus
                    cost_blks[i].text = (new_cost <= 0) and "0" or tostring(fmt_number(new_cost))
                    log:trace("%i) updated cost to %s (from %s; bonus = %s)", i, new_cost, spell.magickaCost, cost_bonus)
                end
                local chance_bonus = cc_bonus:get_bonus(skill_id)

                if chance_bonus and chance_bonus ~= 1 then
                    local chance = spell:calculateCastChance{caster=tes3.mobilePlayer, checkMagicka=false}
                    local new_chance = chance * chance_bonus
                    chance_blks[i].text = "/" .. fmt_number(new_chance)
                    log:trace("%i) updated chance to %s (from %s; bonus = %s)", i, new_chance, chance, chance_bonus)
                end
                ::next_spell::
            end
        end
        do -- update enchant menu
            local layout = spells_list:findChild("MagicMenu_item_layout")

            local name_blks = layout:findChild("MagicMenu_item_names").children
            local cost_blks = layout:findChild("MagicMenu_item_costs").children
            -- local chance_blks = layout:findChild("MagicMenu_item_percents").children
            for i, name_blk in ipairs(name_blks) do
                local object = name_blk:getPropertyObject("MagicMenu_object", "tes3object") ---@type tes3object|tes3weapon|tes3clothing
                if not object then
                    log("%i) object %q didnt exist!!", i, name_blk.text)
                    goto next_spell
                end
                log:trace("%i) updating object %q has enchantment %q", i, object.name, object.enchantment)
                local chrg_bonus = ec_bonus:get_bonus()
                if chrg_bonus and chrg_bonus ~= 1 then
                    local new_cost = object.enchantment.chargeCost * chrg_bonus
                    cost_blks[i].text = tostring(fmt_number(new_cost))
                    log("%i) updated cost to %s (from %s; bonus = %s)", i, new_cost, object.enchantment.chargeCost, chrg_bonus)
                end
                ::next_spell::
            end
        end
    end

    ---@param e uiActivatedEventData
    event.register(tes3.event.uiActivated, function(e)
        if e.newlyCreated then
            e.element:registerAfter("preUpdate", magic_menu_preupdate)
        end
    end, {filter="MenuMagic"})
end


do -- athletics
    new_bonus{name="Movement Speed", 
        skill_ids = {tes3.skill.athletics},
        calculate_bonus=function(k)
            -- just the damage calculation function, but scaled down by 60%
            return 0.6 * 0.52 * (1 - 2^( -0.00004 * (0.001 * k^2 + 75 * k) ))
        end,
        event_id = EV.calcMoveSpeed,
        event_callback = function (self, e)
            if e.reference == tes3.player then
                e.speed = e.speed * (1 + self:get_bonus())
            end
        end
    }
end


do -- security

    local lockpick_bonus = new_bonus{name="Lockpicking Chance", 
        calculate_bonus = function(k) 
            return 0.75 * (1 - 2^(-0.000035*(0.5*k^2-0.5*k))) 
        end, 
        skill_ids = {tes3.skill.security},
        event_id = EV.lockPick,
        event_callback = function(self, e) e.chance = e.chance * (1 + self:get_bonus()) end
    }

    local probe_bonus = new_bonus{name="Probe Chance", 
        calculate_bonus = function(k) 
            return 1 * (1 - 2^(-0.3 * (0.000075 * (0.5 * k^2-k)))) 
        end, 
        skill_ids = lockpick_bonus.skill_ids,
        event_id = EV.trapDisarm,
        event_callback = function(self, e) 
            e.chance = e.chance * (1 + self:get_bonus())
        end
    }
end



do -- armorer

    local rc_bonus = new_bonus{name="Repair Chance", 
        calculate_bonus = function(k)
            return 0.75 * (1 - 2^(-0.000035*(0.5*k^2-0.5*k)))
        end, 
        skill_ids = {tes3.skill.armorer},
        event_id = EV.repair,
        event_callback = function (self, e)
            if e.repairer == tes3.mobilePlayer then
                e.chance = e.chance * (1 + self:get_bonus())
            end
        end
    }

    new_bonus{name="Repir Amount", 
        calculate_bonus = function(k)
            return 1 * (1 - 2^(-0.3 * (0.000075 * (0.5 * k^2-k))))
        end, 
        skill_ids = rc_bonus.skill_ids, 
        event_id = EV.repair,
        event_callback = function(self, e)
            if e.repairer == tes3.mobilePlayer then
                e.repairAmount = e.repairAmount * (1 + self:get_bonus())
            end
        end
    }
end


do -- block
    local chance_bonus = new_bonus{name="Repair Chance", 
        calculate_bonus = function(k)
            return 0.75 * (1 - 2^(-0.000035*(0.5*k^2-0.5*k)))
        end, 
        skill_ids = {tes3.skill.block},
        event_id = EV.calcBlockChance,
        ---@param e calcBlockChanceEventData
        event_callback = function (self, e)
            if e.target == tes3.player then
                e.blockChance = e.blockChance * (1 + self:get_bonus())
            end
        end,
    }

    new_bonus{name="Shield Damage Taken", 
        calculate_bonus = function(k)
            return -0.5 * (1 - 2^(-0.3 * (0.000075 * (0.5 * k^2-k))))
        end, 
        skill_ids = chance_bonus.skill_ids,
        event_id = EV.shieldBlocked, ---@param e shieldBlockedEventData
        event_callback = function (self, e)
            if e.reference == tes3.player then
                e.conditionDamage = e.conditionDamage * (1 + self:get_bonus())
            end
        end,
    }
end

do -- acrobatics
    new_bonus{name="Fall Damage Taken", 
        calculate_bonus = function(x)
            return -0.75 * (1 - 2 ^(-0.00002 * (200 * x + 0.5 * x^2)))
        end, 
        skill_ids = {tes3.skill.acrobatics},
        event_id = EV.damage, 
        event_callback = function (self, e) ---@param e damageEventData
            if e.reference == tes3.player and e.source == "fall" then
                e.damage = e.damage * (1 + self:get_bonus(20))
            end
        end,
    }

end


do -- xp 
    new_bonus{name="XP Modifier", 
        calculate_bonus = function(x)
            return 0.33 * (1 - 2 ^(-0.00002 * (200 * x + 0.5 * x^2)))
        end, 
        skill_ids = table.values(tes3.skill),
        event_id = EV.exerciseSkill, ---@param e exerciseSkillEventData
        event_callback = function (self, e)
            e.progress = e.progress * (1 + self:get_bonus(e.skill))
        end,
        event_priority=-10,
        sort_priority=100,
    }
end