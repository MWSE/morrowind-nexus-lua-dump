local config =
    mwse.loadConfig("Krimson Summoner",
    {
        sightSummon = true,
        disableDead = true,
        useMagicka = true,
        limitMax = true,
        compShare = true,
        healthTooltip = true,
        keybind = {keyCode = tes3.scanCode.c, isShiftDown = false, isAltDown = false, isControlDown = false},
    }
)

local creatureArray = {
    [1] = { "Animals", "",--20
        "mudcrab",--1
        "scrib",--1
        "nix-hound",--2
        "Rat",--2
        "alit",--3
        "guar",--3
        "cliff racer",--4
        "kagouti",--4
        "BM_horker",--5
        "Rat_pack_rerlas",--5
        "BM_wolf_red",--5
        "BM_wolf_grey",--5
        "shalk",--6
        "BM_bear_black",--10
        "BM_bear_brown",--10
        "BM_bear_snow_unique",--10
        "BM_wolf_snow_unique",--10
        "durzog_wild",--10
        "BM_frost_boar",--15
        "durzog_war",--15
    },
    [2] = { "Creatures", "",--23 TR-32
        "centurion_spider",--3
        "ash_slave",--5
        "centurion_sphere",--5
        "corprus_stalker",--5
        --"T_Glb_Cre_GolmM_01",--6 Mud Golem
        "goblin_grunt",--7
        "ash_zombie",--8
        "corprus_lame",--8
        --"T_Mw_Fau_TrllSw_01",--9 Swamp Troll
        "centurion_projectile",--10
        "BM_ice_troll_tough",--10
        "BM_riekling",--10
        "centurion_steam",--10
        "fabricant_verminous",--10
        "goblin_footsoldier",--13
        "ash_ghoul",--15
        --"T_Sky_Cre_HagRaven_01",--15 Hagraven
        "centurion_steam_advance",--20
        --"T_Glb_Cre_TrollCave_03",--20 Cave Troll
        "goblin_bruiser",--20
        "goblin_handler",--20
        "BM_riekling_boarmaster",--20
        "BM_riekling_mounted",--20
        "BM_spriggan",--20
        --"T_Glb_Cre_TrollFrost_04",--22 Frost Troll
        "ascended_sleeper",--25
        "goblin_officerUNI",--25
        --"T_Glb_Cre_TrollArmor_02",--26 Armored Troll Brute
        --"T_Glb_Cre_TrollArmor_03",--26 Armored Troll Stalker
        --"T_Glb_Cre_TrollArmor_04",--30 Armored Troll Champion
        "fabricant_hulking",--30
        --"T_Cyr_Cre_Mino_01",--30 Minotaur
    },
    [3] = { "Daedra", "",--13 TR-30
        --"TR_m3_StoryGoldenSaint",--4 Weakened Golden Saint
        --"T_Dae_Cre_LesserClfr_01",--5 Rock Chisel Clannfear
        "scamp",--5
        --"T_Dae_Cre_DridLs_01",--6 Dridrea Spawnling
        "clannfear",--7
        "atronach_flame",--7
        --"T_Dae_Cre_DremCait_01",--8 Dremora Caitiff
        --"TR_m3_Kha_11_DremSewers",--8 Dremora Oathkin
        --"TR_m3_Kha_Vermai_01",--8 Vermai Oathkin
        "dremora",--9
        --"T_Dae_Cre_DremKynv_01",--9 Dremora Kynval
        "atronach_frost",--9
        --"T_Dae_Cre_Drem_Arch_01",--10 Dremora Sharpshooter
        --"T_Dae_Cre_Drem_Cast_01",--10 Dremora Spellcaster
        "hunger",--11
        "ogrim",--11
        "daedroth",--12
        "dremora_lord",--12
        --"T_Dae_Cre_Drid_01",--12 Dridrea
        --"T_Dae_Cre_DremKynr_01",--15 Dremora Kynreeve
        --"TR_m3_Kha_DremoraSplCst",--15 Dremora Occultist
        "ogrim titan",--15
        "atronach_storm",--15
        "winged twilight",--15
        --"TR_m1_Vermai_PT",--16 Vermai
        --"T_Dae_Cre_DridGr_01",--18 Dridrea Matriarch
        "golden saint",--20
        --"T_Dae_Cre_Guardian_01",--20 Guardian
        --"T_Dae_Cre_DridBs_01",--30 Dridrea Monarch
        --"TR_m1_Beh",--30 Ogrim Behemoth
    },
    [4] = { "Diseased Animals", "",--15 TR-32
        "rat_blighted",--4
        "scrib blighted",--4
        "nix-hound blighted",--6
        "alit_blighted",--7
        "cliff racer_blighted",--8
        "kagouti_blighted",--8
        "shalk_blighted",--10
        --"T_Cyr_Fau_MooncDis_01",--1 Diseased Mooncrab
        "mudcrab-Diseased",--1
        "scrib diseased",--1
        --"T_Cyr_Fau_MuskratDs_01",--2 Diseased Muskrat
        --"T_Ham_Fau_SpkwormDs_01",--2 Diseased Spikeworm
        "alit_diseased",--3
        "rat_diseased",--3
        "cliff racer_diseased",--4
        --"T_Sky_Fau_SnowrayDs_01",--4 Diseased Snow Ray
        --"T_Sky_Fau_BoarDs_01",--4 Diseased Wild Boar
        "kagouti_diseased",--4
        --"T_Sky_Fau_WolfBlaDs_01",--5 Diseased Black Wolf
        --"T_Cyr_Fau_WolfColDs_01",--5 Diseased Colovian Wolf
        --"T_Sky_Fau_WolfGr_Dis_01",--5 Diseased Grey Wolf
        --"T_Cyr_Fau_WolfColDs_02",--5 Diseased Highlands Wolf
        --"T_Sky_Fau_HorkerDs_01",--5 Diseased Horker
        --"T_Sky_Fau_WolfRedDs_01",--5 Diseased Red Wolf
        "shalk_diseased",--6
        --"T_Sky_Fau_BearRedDs_01",--10 Diseased Brown Bear
        --"T_Cyr_Fau_BearColDs_01",--10 Diseased Colovian Bear
        "durzog_diseased",--10
        --"T_Sky_Fau_BearBrDs_01",--15 Diseased Grizzly Bear
        --"T_Glb_Cre_TrollCaveD_03",--20 Diseased Cave Troll
        --"T_Sky_Fau_SabCatDs_02",--20 Diseased Sabre Cat
        --"T_Sky_Cre_MinoDs_01",--25 Diseased Kreathi Minotaur
    },
    [5] = { "Undead", "",--19 TR-33
        "ancestor_ghost",--1
        "skeleton_weak",--3
        "bonewalker_weak",--3
        --"T_Mw_Und_Mum_02",--3 mummy
        --"T_Mw_Und_MumPl_01",--3 Plaguebearer Mummy
        "skeleton",--3
        "skeleton archer",--3
        "bonewalker",--4
        "dwarven ghost",--5
        --"T_Cyr_Und_RemLegionr02",--5 Oathbound Legionaire
        "Bonewalker_Greater",--7
        "skeleton warrior",--7
        "bonelord",--8
        --"T_Sky_Cre_IceWr_01",--8 Ice Wraith
        --"T_Cyr_Und_RemCaptain01",--8 Oathbound Captain
        "BM_wolf_skeleton",--10
        "ancestor_ghost_greater",--10
        --"T_Glb_Und_SkelOrc_03",--10 Skeleton Barbarian
        "skeleton nord ",--10
        "skeleton champion",--10
        --"T_Cyr_Und_WrthFad_01",--11 Faded Wraith
        --"T_Cyr_Und_SkelLegion_02",--12 Legionnaire Skeleton
        --"T_Cyr_Und_RemGeneral01",--12 Oathbound General
        --"T_Cyr_Und_Wrth_01",--15 Wraith
        "BM_draugr01",--20
        "lich",--20
        "skeleton_aldredaynia",--20
        --"T_Sky_Und_DrgrHousc_01",--25 Draugr Housecarl
        "bm_skeleton_pirate ",--25
        --"T_Sky_Und_DrgrLor_01",--30 Draugr Lord
        "bm_skeleton_pirate_capt",--35
        --"T_Glb_Und_SkelWLor_01",--35 Skeleton Warlord
        --"T_Glb_Und_LichGr_01",--40 Greater Lich
    },
    --[[[6] = { "Animals-TR", "",--TR-33
        "T_Glb_Fau_Bat_01",--1 Bat
        "TR_m1_molecrab_w",--1 Molecrab
        "T_Cyr_Fau_Moonc_01",--1 Mooncrab
        "T_Mw_Fau_Orn_01",--1 Ornada
        "T_Glb_Fau_Squirrel_02",--1 Squirrel
        "T_Cyr_Fau_Donk_01",--2 Donkey
        "T_Cyr_Fau_Muskrat_01",--2 Muskrat
        "T_Glb_Fau_LrgSpider_03",--2 Spider
        "T_Cyr_Fau_Goat_01",-- 2 Weald Goat
        "T_Mw_Fau_Hoom_01",--3 Hoom
        "T_Cyr_Fau_Hrs_01",--3 Horse
        "T_Mw_Fau_SkrendHtc_01",--4 Hatchling Sky Render
        "T_Sky_Fau_GoatMnFr_01",--4 Mountain Goat
        "T_Sky_Fau_Boar_01",--4 Wild Boar
        "T_Cyr_Fau_WolfCol_01",--5 Colovian Wolf
        "T_Glb_Fau_Deer_01",--5 Deer
        "T_Cyr_Fau_WolfCol_02",--5 Highlands Wolf
        "T_MW_Fau_Hirv_01",--5 Hirv
        "T_Mw_Fau_Velk_01",--5 Velk
        "T_Sky_Fau_CatlCowP_01",--6 Painted Cow
        "T_Glb_Fau_LrgSpider_01",--6 Large Spider
        "T_Cyr_Fau_Alphyn_01",--7 Alphyn
        "T_Sky_Fau_ElkWhite_01",--7 Elk
        "T_Mw_Fau_Para_01",--7 Parastylus
        "T_Mw_Fau_ParaVn_01",--8 Venomous Parastylus
        "T_Cyr_Fau_CatlBull_01",--10 Bull
        "T_Cyr_Fau_BearCol_01",--10 Colovian Bear
        "T_Mw_Fau_SkrendGrnd_01",--10 Sky Render
        "T_Glb_Fau_LrgSpider_02",--10 Spider Matron
        "T_Sky_Fau_Raki_01",--12 Raki
        "T_Mw_Fau_ArmunKag_01",--18 Armun Kagouti
        "T_Sky_Fau_BearGr_01",--18 Cave Bear
        "T_Sky_Fau_SabCat_01",--20 Sabre Cat
    },]]
}

local function onDeath(e)

    if tes3.player.data.krimsonSummonList == nil then

        tes3.player.data.krimsonSummonList = {}
        return
    end

    local summonList = tes3.player.data.krimsonSummonList

    for _, refID in pairs(summonList) do

        if refID == e.reference.id then

            if config.disableDead then

                local ref = tes3.getReference(refID)

                tes3.createVisualEffect({ effect = "VFX_Summon_End", repeatCount = 1, position = ref.position })

                if not ref.disabled then

                    ref:disable()
                end

                timer.start({ duration = 2, callback = function ()

                    if ref.disabled then

                        ref:delete()
                    end
                end})
            end

            table.removevalue(summonList, refID)
        end
    end
end

local function dismissFollower(ref, button, refID, summonList)

    if button == 0 then

        table.removevalue(summonList, refID)
        tes3.createVisualEffect({ effect = "VFX_Summon_End", repeatCount = 1, position = ref.position })

        if not ref.disabled then

            ref:disable()
        end

        timer.start({ duration = 2, callback = function ()

            if ref.disabled then

                ref:delete()
            end
        end})

    elseif button == 1 then

        return
    end
end

local function followerMenu(ref, button, refID, summonList)

    if button == 0 then

        tes3.showContentsMenu({ reference = ref, pickpocket = false })

    elseif button == 1 then

        table.removevalue(summonList, refID)
        tes3.createVisualEffect({ effect = "VFX_Summon_End", repeatCount = 1, position = ref.position })

        if not ref.disabled then

            ref:disable()
        end

        timer.start({ duration = 2, callback = function ()

            if ref.disabled then

                ref:delete()
            end
        end})

    elseif button == 2 then

        return
    end
end

local function onActivate(e)

    if e.activator ~= tes3.player then

        return
    end

    if tes3.player.data.krimsonSummonList == nil then

        tes3.player.data.krimsonSummonList = {}
        return
    end

    local summonList = tes3.player.data.krimsonSummonList

    if config.compShare then

        for _, refID in pairs(summonList) do

            local ref = tes3.getReference(refID)

            if ref == e.target then

                tes3.messageBox({message = string.format("What do you want to do?\n"), buttons = {"Open Inventory", "Dismiss", "Cancel"},
                callback = function(e)
                    timer.delayOneFrame(function() followerMenu(ref, e.button, refID, summonList)
                    end)
                end})
                return false
            end
        end
    else

        for _, refID in pairs(summonList) do

            local ref = tes3.getReference(refID)

            if ref == e.target then

                tes3.messageBox({message = string.format("What do you want to do?\n"), buttons = {"Dismiss", "Cancel"},
                callback = function(e)
                    timer.delayOneFrame(function() dismissFollower(ref, e.button, refID, summonList)
                    end)
                end})
                return false
            end
        end
    end
end

local function targetChanged(e)

    if config.healthTooltip then

        if ( e.current == nil or tes3.getCurrentAIPackageId(e.current.mobile) ~= tes3.aiPackage.follow ) then

            return
        end

        if tes3.player.data.krimsonSummonList == nil then

            tes3.player.data.krimsonSummonList = {}
            return
        end

        local summonList = tes3.player.data.krimsonSummonList

        for _, refID in pairs(summonList) do

            local ref = tes3.getReference(refID)
            local mobile = ref.mobile

            if ref == e.current then

                local menu = tes3ui.findHelpLayerMenu("HelpMenu")
                local name = menu:findChild("HelpMenu_name")
                name.text = string.format("%s\nHealth: %s/%s", mobile.object.name, math.floor(tonumber(mobile.health.current)), mobile.health.base)
            end
        end
    end
end

local function summon(id, position)

    if tes3.player.data.krimsonSummonList == nil then

        tes3.player.data.krimsonSummonList = {}
    end

    local summonList = tes3.player.data.krimsonSummonList

    if config.limitMax then

        local summonMax = math.floor(tonumber(tes3.mobilePlayer.conjuration.current / 20 + 1))

        if table.size(summonList) >= summonMax then

            tes3.messageBox("You have reached the max number of summons.")
            return
        end
    end

    if config.useMagicka then

        local obj = tes3.getObject(id)
        local cost = math.floor(tonumber(obj.health / 1.5 + 20))
        local expGain = math.floor(tonumber(obj.health * 2 / 7))

        if cost > 250 then

            cost = 250
        end

        if cost > tes3.mobilePlayer.magicka.current then

            tes3.messageBox("You don't have enough magicka to summon this.")
            return
        else
            tes3.mobilePlayer:exerciseSkill(tes3.skill.conjuration, expGain)
            tes3.modStatistic({ reference = tes3.mobilePlayer, name = "magicka", current = -cost })
        end
    end

    local ref = position and tes3.createReference({ object = id, position = position, cell = tes3.player.cell })
    local mobileRef = ref.mobile

    table.insert(summonList, ref.id)
    tes3.playSound({ sound = "conjuration hit", reference = tes3.mobilePlayer })
    tes3.createVisualEffect({ effect = "VFX_Summon_Start", repeatCount = 1, position = ref.position })

    mobileRef.fight = 0
    mobileRef.flee = 0
    mobileRef.alarm = 0
    mobileRef.hello = 0
    tes3.setAIFollow({ reference = ref, target = tes3.player, reset = true })
end

local function setPosition(id)

    local position

    if config.sightSummon then

        local ray = tes3.rayTest ({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = { tes3.player } })

        if ray then

            position = ray.intersection + tes3vector3.new(0, 0, 10)
        else
            position = tes3.mobilePlayer.position
        end
    else
        position = tes3.mobilePlayer.position
    end

    summon(id, position)
end

local function summonMenu()

    if not tes3ui.menuMode() then

        local menu = {}
        local menuText

        menu.main = tes3ui.createMenu {id = "KrimsonSummonMenu", fixedFrame = true}
        menu.main.autoHeight = true
        menu.main.autoWidth = true

        menu.border = menu.main:createThinBorder()
        menu.border.autoHeight = true
        menu.border.autoWidth = true

        menu.window = menu.border:createBlock {}
        menu.window.autoHeight = true
        menu.window.autoWidth = true

        menu.bottom = menu.main:createBlock {}
        menu.bottom.autoHeight = true
        menu.bottom.autoWidth = true

        menu.close = menu.bottom:createButton {text = tes3.findGMST(tes3.gmst.sClose).value}
        menu.close.borderTop = 15
        menu.close.borderRight = 50
        menu.close:register(
            "mouseClick",
            function()
                menu.main:destroy()
                tes3ui.leaveMenuMode()
            end
        )

        local magicka = math.floor(tonumber(tes3.mobilePlayer.magicka.current))

        if config.useMagicka then

            menu.magicka = menu.bottom:createLabel {text = string.format("Your Current Magicka: %d", magicka)}
            menu.magicka.borderTop = 15
            menu.magicka.borderRight = 50
        end

        if config.limitMax then

            if tes3.player.data.krimsonSummonList == nil then

                tes3.player.data.krimsonSummonList = {}
            end

            local summonList = tes3.player.data.krimsonSummonList
            local summonNumber = table.size(summonList)
            local summonMax = math.floor(tonumber(tes3.mobilePlayer.conjuration.current / 20 + 1))

            if summonNumber >= summonMax then

                menu.summon = menu.bottom:createLabel {text = string.format("Current summons/Max summons: %d/%d     You have the Maximum number of summons", summonNumber, summonMax)}
            else
                menu.summon = menu.bottom:createLabel {text = string.format("Current summons/Max summons: %d/%d     Available summons remaining: %d", summonNumber, summonMax, summonMax - summonNumber)}
            end

            menu.summon.borderTop = 15
        end

        for i = 1, 5 do

            menu[i] = menu.window:createBlock {}
            menu[i].autoHeight = true
            menu[i].autoWidth = true
            menu[i].paddingAllSides = 20
            menu[i].flowDirection = "top_to_bottom"
        end

        for i, creatureTable in ipairs(creatureArray) do

            for j, id in ipairs(creatureTable) do

                if j < 3 then

                    menuText = menu[i]:createLabel {text = id}
                    menuText.wrapText = true
                    menuText.justifyText = "center"
                    menuText.borderBottom = 2
                else
                    local obj = tes3.getObject(id)
					local cost = math.floor(tonumber(obj.health / 1.5 + 20))

                    if config.useMagicka then

                        if cost > 250 then

                            cost = 250
                        end

                        menuText = menu[i]:createLabel {text = string.format("%s ( Magicka: %d )", obj.name, cost)}

                        if cost > magicka then

                            menuText.color = {0.5,0.5,0.5}
                        end

                        menuText.wrapText = true
                        menuText.justifyText = "right"
                    else
                        menuText = menu[i]:createLabel {text = string.format("%s", obj.name)}
                    end

                    menuText.borderBottom = 2

                    if ( obj.level * 3 + 10 <= tes3.mobilePlayer.conjuration.current and obj.level > tes3.player.object.level ) then

                        menuText.color = {0.2,0.2,0.2}
                        menuText:register(
                            "help",
                            function()
                                local tooltip = tes3ui.createTooltipMenu{item = id}
                                tooltip:createLabel{text = string.format("Level Required: %s", obj.level)}
                            end
                        )
                    elseif ( obj.level * 3 + 10 > tes3.mobilePlayer.conjuration.current and obj.level <= tes3.player.object.level ) then

                        menuText.color = {0.2,0.2,0.2}
                        menuText:register(
                            "help",
                            function()
                                local tooltip = tes3ui.createTooltipMenu{item = id}
                                tooltip:createLabel{text = string.format("Conjuration Required: %s", obj.level * 3 + 10)}
                            end
                        )
                    elseif ( obj.level * 3 + 10 > tes3.mobilePlayer.conjuration.current and obj.level > tes3.player.object.level ) then
                        menuText.color = {0.2,0.2,0.2}
                        menuText:register(
                            "help",
                            function()
                                local tooltip = tes3ui.createTooltipMenu{item = id}
                                tooltip:createLabel{text = string.format("Conjuration Required: %s\nLevel Required: %s", obj.level * 3 + 10, obj.level)}
                            end
                        )
                    else
                        menuText:register(
                            "help",
                            function()
                                local tooltip = tes3ui.createTooltipMenu{item = id}
                                tooltip:createLabel{text = string.format("Level: %d\nHealth: %d\nMagicka: %d\nStamina: %d\nSoul: %d", obj.level, obj.health, obj.magicka, obj.fatigue, obj.soul)}
                            end
                        )

                        menuText:register(
                            "mouseClick",
                            function()
                                setPosition(id)
                                menu.main:destroy()
                                tes3ui.leaveMenuMode()
                            end
                        )
                    end
                end
            end
        end

        tes3ui.enterMenuMode("KrimsonSummonMenu")
    end
end

local function registerModConfig()

    local template = mwse.mcm.createTemplate("Krimson Summoner")

    template:saveOnClose("Krimson Summoner", config)
    template:register()

    local page = template:createPage()

    page:createKeyBinder ({
        label = "Summon Hotkey (restart the game to apply changes to this)",
        variable = mwse.mcm.createTableVariable {id = "keybind", table = config}
    })

    page:createYesNoButton({
        label = "Limit the number of summons with your skill in Conjuration?",
        variable = mwse.mcm.createTableVariable {id = "limitMax", table = config}
    })

    page:createYesNoButton({
        label = "Require magicka to summon followers?",
        variable = mwse.mcm.createTableVariable {id = "useMagicka", table = config}
    })

    page:createYesNoButton({
        label = "Summon followers where you are looking at?",
        variable = mwse.mcm.createTableVariable {id = "sightSummon", table = config}
    })

    page:createYesNoButton({
        label = "Show followers current/max health on tooltip?",
        variable = mwse.mcm.createTableVariable {id = "healthTooltip", table = config}
    })

    page:createYesNoButton({
        label = "Use companion share for the followers? If option below is Yes, you will lose items they carry when they die.",
        variable = mwse.mcm.createTableVariable {id = "compShare", table = config}
    })

    page:createYesNoButton({
        label = "Disable and remove your summons automatically when they die?",
        variable = mwse.mcm.createTableVariable {id = "disableDead", table = config}
    })
end

event.register("modConfigReady", registerModConfig)

local function onInitialized()

    event.register("activationTargetChanged", targetChanged)
    event.register("activate", onActivate)
    event.register("death", onDeath)
    event.register("keyDown", summonMenu, {filter = config.keybind.keyCode})
end

event.register("initialized", onInitialized)