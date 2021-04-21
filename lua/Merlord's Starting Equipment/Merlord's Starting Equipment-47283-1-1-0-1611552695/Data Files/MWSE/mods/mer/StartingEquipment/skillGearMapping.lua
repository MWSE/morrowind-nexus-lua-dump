return {
    [tes3.skill.block] = function()
        local gearList = {}
        if tes3.mobilePlayer.lightArmor.base > tes3.mobilePlayer.heavyArmor.base then
            table.insert(gearList, { item = "iron_shield" })
        else
            table.insert(gearList, { item = "netch_leather_shield" })
        end
        return gearList
    end,
    [tes3.skill.armorer] =function()
        local gearList = {
            { item = "repair_journeyman_01"} 
        }
        return gearList
    end,
    [tes3.skill.heavyArmor] =function()
        local gearList = {
            { item = "iron_helmet"},
        }
        return gearList
    end,
    [tes3.skill.bluntWeapon] =function()
        local gearList = {}
        
        if tes3.mobilePlayer.strength.base > tes3.mobilePlayer.intelligence.base then
            table.insert(gearList, { item = "iron warhammer"} )
        else
            table.insert(gearList, { item = "iron mace"} )
        end

        return gearList
    end,
    [tes3.skill.longBlade] =function()
        local gearList = {
            { item = "iron longsword"},
        }
        return gearList
    end,
    [tes3.skill.axe] =function()
        local gearList = {
            { item = "iron battle axe" }
        }
        return gearList
    end,
    [tes3.skill.spear] =function()
        local gearList = {
            { item = "iron spear" },
        }
        return gearList
    end,
    [tes3.skill.enchant] =function()
        local gearList = {
            { item = "Misc_SoulGem_Greater"},
        }
        return gearList
    end,
    [tes3.skill.destruction] = function()
        local gearList = {
            { item = "sc_elementalburstfire"},
            { item = "bk_ChildrenOfTheSky" },
        }
        
        return gearList
    end,
    [tes3.skill.alteration] = function()
        local gearList = {
            { item = "bk_InvocationOfAzura" },
            
        }
        return gearList
    end,
    [tes3.skill.illusion] = function()
        local gearList = {
            { item = "bk_MysteriousAkavir"},
            { item = "bk_darkestdarkness"},
        }
        
        return gearList
    end,
    [tes3.skill.conjuration] = function()
        local gearList = {
            { item = "bk_BookOfDaedra"},
            { item = "Misc_SoulGem_Petty", count = 2},
        }
        
        return gearList
    end,
    [tes3.skill.mysticism] = function()
        local gearList = {
            { item = "bk_Mysticism"},
            { item = "Misc_SoulGem_Common"},
            { item = "Misc_SoulGem_Lesser"},
        }
        
        return gearList
    end,
    [tes3.skill.restoration] = function()
        local gearList = {
            { item = "sc_healing"},
            { item = "bk_varietiesoffaithintheempire"},
        }
        return gearList
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

        return gearList
    end,
    [tes3.skill.security] = function()
        local gearList = {
            { item = "pick_apprentice_01", count= 2},
            { item = "probe_apprentice_01", count= 2},
        }
        
        return gearList
    end,
    [tes3.skill.sneak] = function()
        local gearList = {}
        if tes3.mobilePlayer.shortBlade.base > 20 then
            table.insert(gearList, { item = "iron spider dagger" })
        end
        return gearList
    end,
    [tes3.skill.lightArmor] = function()
        local gearList = {}
        local armors = {
            { item = "netch_leather_boots" },
            { item = "heavy_leather_boots" },
            { item = "netch_leather_cuirass" },
        }
        local choice =  table.choice(armors)
        table.insert(gearList, choice)
        return gearList
    end,
    [tes3.skill.shortBlade] = function()
        local gearList = {
            { item = "iron shortsword" }
        }
        return gearList
    end,
    [tes3.skill.marksman] = function()
        local gearList = {
            { item = "short bow" },
            { item = "iron arrow", count = 30 },
        }
        return gearList
    end,
    [tes3.skill.mercantile] = function()
        local gearList = {
            { item = "Gold_001", count = 50 }
        }
        return gearList
    end,
    [tes3.skill.handToHand] = function()
        local gearList = {
            { item = "common_glove_right_01"},
            { item = "common_glove_left_01"},
        }
        return gearList
    end,
}