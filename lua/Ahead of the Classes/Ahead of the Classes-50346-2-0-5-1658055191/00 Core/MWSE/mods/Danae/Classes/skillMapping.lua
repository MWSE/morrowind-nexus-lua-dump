return {
    [tes3.skill.block] = function()
        local gearList = {}
        if tes3.mobilePlayer.lightArmor.base > tes3.mobilePlayer.heavyArmor.base then
            table.insert(gearList, { item = "iron_shield" })
        else
            table.insert(gearList, { item = "netch_leather_shield" })
        end
        return {
            gearList = gearList,
            spellList = {},
        }
    end,
    [tes3.skill.armorer] = function()
        return {
            gearList = {
                { item = "hammer_repair", count = 2 },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.heavyArmor] = function()
        return {
            gearList = {
                { item = "iron_cuirass"},
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.bluntWeapon] = function()
        local gearList = {}
        if tes3.mobilePlayer.strength.base > tes3.mobilePlayer.intelligence.base then
            table.insert(gearList, { item = "steel club"} )
        else
            table.insert(gearList, { item = "iron club"} )
        end
        return {
            gearList = gearList,
            spellList = {},
        }
    end,
    [tes3.skill.longBlade] = function()
        return {
            gearList = {
                { item = "iron longsword"},
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.axe] = function()
        return {
            gearList = {
                { item = "iron war axe" }
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.spear] = function()
        return {
            gearList = {
                { item = "iron spear" },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.enchant] = function()
        return {
            gearList = {
                { item = "aa_cl_ench_ring" },
                { item = "Misc_SoulGem_Petty", count= 2},
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.destruction] = function()
        return {
            gearList = {
                },
            spellList = {
                "fire bite",
                "frost bolt",
            },
        }
    end,
    [tes3.skill.alteration] = function()
        return {
            gearList = {
            },
            spellList = {
                "feather",
                "open",
            },
        }
    end,
    [tes3.skill.illusion] = function()
        return {
            gearList = {
            },
            spellList = {
                "light",
                "chameleon",
            },
        }
    end,
    [tes3.skill.conjuration] = function()
        return {
            gearList = {
            },
            spellList = {
                "bound dagger",
                "summon scamp",
            },
        }
    end,
    [tes3.skill.mysticism] = function()
        return {
            gearList = {
            },
            spellList = {
                "telekinesis",
                "soul trap",
            },
        }
    end,
    [tes3.skill.restoration] = function()
        return {
            gearList = {
            },
            spellList = {
                "mother's kiss",
                "stamina",
            },
        }
    end,
    [tes3.skill.alchemy] = function()
        local gearList = {
            { item = "ingred_bittergreen_petals_01", count = 1},
            { item = "ingred_fire_salts_01", count = 1},
        }
        if math.random() < 0.5 then
            table.insert(gearList,  { item = "apparatus_a_mortar_01"})
        end
        if math.random() < 0.2 then
            table.insert(gearList,  { item = "apparatus_a_alembic_01"})
        end 
        return {
            gearList = gearList,
            spellList = {},
        }
    end,
    [tes3.skill.security] = function()
        return {
            gearList = {
                { item = "probe_journeyman_01", count = 2 },
                { item = "pick_journeyman_01",  count = 2 },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.sneak] = function()
        local gearList = {}
        if tes3.mobilePlayer.shortBlade.base > 20 then
            table.insert(gearList, { item = "p_chameleon_s" })
        end
        return {
            gearList = gearList,
            spellList = {},
        }
    end,
    [tes3.skill.lightArmor] = function()
        local gearList = {}
        local armors = {
                { item = "left leather bracer" },
                { item = "right leather bracer" },
        }
        local choice = table.choice(armors)
        table.insert(gearList, choice)
        return {
            gearList = gearList,
            spellList = {},
        }
    end,
    [tes3.skill.shortBlade] = function()
        return {
            gearList = {
                { item = "steel dagger" },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.marksman] = function()
        return {
            gearList = {
                { item = "short bow" },
                { item = "iron arrow", count = 30 },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.mercantile] = function()
        return {
            gearList = {
                { item = "Gold_001", count = 50 },
                { item = "AB_Misc_PurseCoin" },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.handToHand] = function()
        return {
            gearList = {
                { item = "aa_cl_h2h_glove_right" },
                { item = "aa_cl_h2h_glove_left" },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.unarmored] = function()
        return {
            gearList = {
                { item = "watcher's belt" },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.acrobatics] = function()
        return {
            gearList = {
                { item = "p_jump_q" },

            },
            spellList = {
            },
        }
    end,
    [tes3.skill.athletics] = function()
        return {
            gearList = {
                { item = "p_restore_fatigue_s" },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.mediumArmor] = function()
        return {
            gearList = {
                { item = "imperial_chain_pauldron_left" },
                { item = "imperial_chain_pauldron_right" },
            },
            spellList = {
            },
        }
    end,
    [tes3.skill.speechcraft] = function()
        return {
            gearList = {
                { item = "potion_t_bug_musk_01" },
            },
            spellList = {
            },
        }
    end,
}