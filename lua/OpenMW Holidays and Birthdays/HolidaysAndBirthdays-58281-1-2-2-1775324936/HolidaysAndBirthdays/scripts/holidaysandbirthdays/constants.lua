local I = require('openmw.interfaces')
local core = require('openmw.core')
local modInfo = require('scripts.holidaysandbirthdays.modinfo')
local l10n = core.l10n(modInfo.name)
local Helpers = require('scripts.holidaysandbirthdays.Helpers')
local constants = {}


--#region StatsWindow
if I.StatsWindow then
    local StatsConstants = I.StatsWindow.Constants
    constants.statsWindowPaneMap = -- behaviour map for StatsWindow Extended integration
    {
        ["left"] = {
            location = StatsConstants.Panes.LEFT,         --LEFT Pane
            addMethod = I.StatsWindow.addBoxToPane,       -- Add a box
            subAddMethod = I.StatsWindow.addSectionToBox, -- add section to box
            subLocation = "HB_tracking_parent",
            parentId = "HB_tracking_parent",              -- box and section
            subId = "HB_tracking_sub",                    -- are distinct entities
        },
        ["right"] = {
            location = StatsConstants.DefaultBoxes.RIGHT_SCROLL_BOX, --Right Pane
            addMethod = I.StatsWindow.addSectionToBox,               --Add section to an existing box
            subAddMethod = I.StatsWindow.modifySection,              -- Modify it with proper labels
            subLocation = nil,                                       -- no sub location, we modify what we created in the first step
            parentId = "HB_tracking_parent",                         --we don't touch original box
            subId = "HB_tracking_parent",
        }
    }


    constants.statsWindowPlacementMap = {
        ["top"] = StatsConstants.Placement.TOP,
        ["bottom"] = StatsConstants.Placement.BOTTOM
    }
end

constants.char_age_stat_label = l10n("character_age_label")
constants.char_bd_stat_label = l10n("character_bd_label")
constants.char_age_stat_tooltip = l10n("character_age_tooltip")
constants.char_bd_stat_tooltip = l10n("character_bd_tooltip")

--#endregion

--#region datetime and holidays
constants.birthSignMonthMap = {
    ["blessed touch sign"] = 1, -- the Ritual
    ["mooncalf"] = 2,           -- the Lover
    ["trollkin"] = 3,           -- the Lord
    ["fay"] = 4,                -- the Mage
    ["moonshadow sign"] = 5,    -- the Shadow
    ["charioteer"] = 6,         -- the Steed
    ["elfborn"] = 7,            -- the Apprentice
    ["warwyrd"] = 8,            -- the Warrior
    ["star-cursed"] = -1,       -- the Serpent can be any month
    ["lady's favor"] = 9,       -- the Lady
    ["beggar's nose"] = 10,     -- the Tower
    ["wombburned"] = 11,        -- the Atronach
    ["hara"] = 12               -- the Thief
}

constants.nonStandardMonthNameMap = {
    [1] = { ["argonian"] = "Vakka", ["gregorian"] = "January" },
    [2] = { ["argonian"] = "Xeech", ["gregorian"] = "February" },
    [3] = { ["argonian"] = "Sisei", ["gregorian"] = "March" },
    [4] = { ["argonian"] = "Hist-Deek", ["gregorian"] = "April" },
    [5] = { ["argonian"] = "Hist-Dooka", ["gregorian"] = "May" },
    [6] = { ["argonian"] = "Hist-Tsoko", ["gregorian"] = "June" },
    [7] = { ["argonian"] = "Thtithil", ["gregorian"] = "July" },
    [8] = { ["argonian"] = "Thtithil-Gah", ["gregorian"] = "August" },
    [9] = { ["argonian"] = "Nushmeeko", ["gregorian"] = "September" },
    [10] = { ["argonian"] = "Shaja-Nushmeeko", ["gregorian"] = "October" },
    [11] = { ["argonian"] = "Saxhleel", ["gregorian"] = "November" },
    [12] = { ["argonian"] = "Xulomaht", ["gregorian"] = "December" },
}

constants.holidayMatrix = {
    -- 01 Morning Star
    {
        ["01"] = { l10n("holiday_desc_new_life"), l10n("holiday_desc_clavicus") },
        ["02"] = { l10n("holiday_desc_scour_day"), },
        ["12"] = { l10n("holiday_desc_ovanka"), },
        ["13"] = { l10n("holiday_desc_meridia"), },
        ["14"] = { l10n("holiday_desc_south_winds"), },
        ["16"] = { l10n("holiday_desc_day_of_lights"), },
        ["18"] = { l10n("holiday_desc_waking_day") },
    }, -- 02 Sun's Dawn
    {
        ["02"] = { l10n("holiday_desc_mad_pelagius_day"), l10n("holiday_desc_sheogorath") },
        ["05"] = { l10n("holiday_desc_othroktide"), },
        ["08"] = { l10n("holiday_desc_day_of_release"), },
        ["13"] = { l10n("holiday_desc_feast_dead"), },
        ["16"] = { l10n("holiday_desc_hearts_day"), l10n("holiday_desc_sanguine") },
        ["27"] = { l10n("holiday_desc_perserverance_day"), },
        ["28"] = { l10n("holiday_desc_aduros_nau") },
    }, -- 03 First Seed
    {
        ["05"] = { l10n("holiday_desc_hermaeus_mora"), },
        ["07"] = { l10n("holiday_desc_first_planting"), },
        ["09"] = { l10n("holiday_desc_day_of_waiting"), },
        ["21"] = { l10n("holiday_desc_azura"), },
        ["25"] = { l10n("holiday_desc_flower_day"), },
        ["26"] = { l10n("holiday_desc_blades_festival") },
    }, -- 04 Rain's Hand
    {
        ["01"] = { l10n("holiday_desc_gardtide"), },
        ["09"] = { l10n("holiday_desc_peryite"), },
        ["13"] = { l10n("holiday_desc_day_of_dead"), },
        ["20"] = { l10n("holiday_desc_day_of_shame"), },
        ["28"] = { l10n("holiday_desc_jesters_festival") },
    }, -- 05 Second Seed
    {
        ["07"] = { l10n("holiday_desc_second_planting"), },
        ["09"] = { l10n("holiday_desc_marukh_day"), l10n("holiday_desc_namira") },
        ["17"] = { l10n("holiday_desc_koomu_alezeri"), },
        ["20"] = { l10n("holiday_desc_fire_festival"), },
        ["30"] = { l10n("holiday_desc_fishing_day") },
    }, -- 06 Mid Year
    {
        ["01"] = { l10n("holiday_desc_drigh_rzimb"), },
        ["05"] = { l10n("holiday_desc_hircine"), },
        ["16"] = { l10n("holiday_desc_mid_year"), },
        ["23"] = { l10n("holiday_desc_dancing_day"), },
        ["24"] = { l10n("holiday_desc_tibers_day") },
    }, -- 07 Sun's Height,
    {
        ["10"] = { l10n("holiday_desc_merchants_festival"), l10n("holiday_desc_vaermina") },
        ["12"] = { l10n("holiday_desc_divad_etept"), },
        ["20"] = { l10n("holiday_desc_suns_rest"), },
        ["29"] = { l10n("holiday_desc_fiery_night") },
    }, -- 08 Last Seed,
    {
        ["02"] = { l10n("holiday_desc_maiden_katrica"), },
        ["14"] = { l10n("holiday_desc_feast_tiger"), },
        ["21"] = { l10n("holiday_desc_appreciation_day"), },
        ["27"] = { l10n("holiday_desc_harvests_end") },
    }, -- 09 Hearth Fire,
    {
        ["03"] = { l10n("holiday_desc_tales_and_tallows"), l10n("holiday_desc_nocturnal") },
        ["06"] = { l10n("holiday_desc_khurat"), },
        ["12"] = { l10n("holiday_desc_riglametha"), },
        ["19"] = { l10n("holiday_desc_childrens_day") },
    }, -- 10 Frost Fall,
    {
        ["05"] = { l10n("holiday_desc_dirij_tereur"), },
        ["08"] = { l10n("holiday_desc_malacath"), },
        ["13"] = { l10n("holiday_desc_witches_festival"), l10n("holiday_desc_mephala") },
        ["23"] = { l10n("holiday_desc_borken_diamonds"), },
        ["30"] = { l10n("holiday_desc_emperors_day") },
    }, -- 11 Sun's Dusk,
    {
        ["02"] = { l10n("holiday_desc_boethiah"), },
        ["03"] = { l10n("holiday_desc_serpents_dance"), },
        ["08"] = { l10n("holiday_desc_moon_festival"), },
        ["18"] = { l10n("holiday_desc_hen_anseilak"), },
        ["20"] = { l10n("holiday_desc_warriors_festival"), l10n("holiday_desc_mehrunesdagon") },
    }, -- 12 Evening Star,
    {
        ["15"] = { l10n("holiday_desc_north_winds"), },
        ["18"] = { l10n("holiday_desc_baranth_do"), },
        ["24"] = { l10n("holiday_desc_chila"), l10n("holiday_desc_molagbal") },
        ["25"] = { l10n("holiday_desc_saturalia"), },
        ["31"] = { l10n("holiday_desc_old_life"), },
    }
}

constants.daedraPrinceReference = {
    ["tr_m7_statue_meridia"] =
    {
        name = "Meridia",
        month = 1,
        day = 13,
        offering = { name = "two opal gemstones", id = "T_IngMine_Opal_01", count = 2 },
        questId = "TR_m7_DA_Meridia",
        questStage = 10,
    },
    ["active_dae_mehrunes"] = {
        name = "Mehrunes Dagon",
        month = 1,
        day = 20,
        offering = { name = "five units of fire salts", id = "ingred_fire_salts_01", count = 5 },
        questId = "DA_Mehrunes",
        questStage = 10,
    },
    ["active_dae_sheogorath"] = {
        name = "Sheogorath",
        month = 2,
        day = 2,
        offering = { name = "two lesser soul gems", id = "misc_soulgem_lesser", count = 2 },
        questId = "DA_Sheogorath",
        questStage = 10,
    },
    ["active_dae_azura"] = {
        name = "Azura",
        month = 3,
        day = 21,
        offering = { name = "three pearls", id = "ingred_pearl_01", count = 3 },
        questId = "DA_Azura",
        questStage = 10,
    },
    ["tr_m7_statue_namira"] = {
        name = "Namira",
        month = 5,
        day = 09,
        offering = { name = "three black roses", id = "T_IngFlor_BlackrosePetal_01", count = 3 },
        questId = "TR_m7_DA_Namira",
        questStage = 10,
    },
    ["active_dae_malacath"] = {
        name = "Malacath",
        month = 10,
        day = 08,
        offering = { name = "five pieces of daedra skin", id = "ingred_daedra_skin_01", count = 5 },
        questId = "DA_Malacath",
        questStage = 10,
    },
    ["active_dae_molagbal"] = {
        name = "Molag Bal",
        month = 12,
        day = 24,
        offering = { name = "eight pieces of hound meat", id = "ingred_hound_meat_01", count = 8 },
        questId = "DA_MolagBal",
        questStage = 10,
    },
}

--#endregion


constants.bdNoteTemplate =
[[<DIV ALIGN="LEFT"><FONT COLOR="000000" SIZE="3" FACE="Magic Cards"><BR>{text}<BR><BR>{chirp}<BR>]]

constants.birthdayChirps = {
    l10n("birthday_wish_01"), l10n("birthday_wish_02"),
    l10n("birthday_wish_03"), l10n("birthday_wish_04"),
    l10n("birthday_wish_05"), l10n("birthday_wish_06"),
    l10n("birthday_wish_07"), l10n("birthday_wish_08"),
    l10n("birthday_wish_09"), l10n("birthday_wish_10"),
}

--#region Settings Constraints and Defaults
constants.defaultStartingCharacterAge = 27
constants.minStartingCharacterAge = 18
constants.maxStartingCharacterAge = 426
constants.defaultBirthdayDay = 15
constants.maxBirthdayDay = 31
constants.gameStartYear = 427
constants.gameStartMonth = 8
constants.gameStartFullDays = 15
constants.defaultDisplayMessageStart = 7
constants.defaultDisplayMessageUntil = 23
constants.getGiftsDefaultSetting = false
constants.monthNamesSettingDefault = "Tamrielic"
constants.statsWindowPaneDefault = "left"
constants.statsWindowPlacementSettingDefault = "bottom"
constants.indentValuesDefault = true
constants.enableDaedricLimitersDefault = false
constants.combineHolidayMessagesDefault = false


--#endregion
--#region Storage keys
constants.generalSettingsStorageKey = 'Settings/' .. modInfo.name .. '/General'
constants.statsWindowIntegrationStorageKey = 'Settings/' .. modInfo.name .. '/StatsWindow'
constants.globalSettingsStorageKey = 'Settings/' .. modInfo.name .. '/Global'
constants.combineHolidayMessagesKey = Helpers.key("combineHolidayMessagesKey")
constants.charAgeStorageKey = Helpers.key("defaultCharacterAge")
constants.charBirthDayStoregaKey = Helpers.key("defaultBirthdayDay")
constants.showHMessageKeybindStorageKey = Helpers.key("showHMessageKeybind")
constants.showMessageTriggerKey = Helpers.key("show_holiday_message")
constants.displayMessageStartKey = Helpers.key("displayMessageStart")
constants.displayMessageUntilKey = Helpers.key("displayMessageUntiKey")
constants.getBirthDayGiftsKey = Helpers.key("getBirthDayGiftsKey")
constants.monthNamesSettingKey = Helpers.key("monthNamesSettingKey")
constants.statsWindowPaneKey = Helpers.key("statsWindowPaneKey")
constants.statsWindowPlacementSettingKey = Helpers.key("statsWindowPlacementSettingKey")
constants.indentValuesKey = Helpers.key("indentValuesKey")
constants.enableDaedricLimitersKey = Helpers.key("enableDaedricLimitersKey")
--#endregion




constants.theStage = "C3_DestroyDagoth"

constants.bdGifts = { -- Eh. No clue what to put here.
    ["armor_gifts"] = {
        { ID = "newtscale_cuirass", count = 1 },
        { ID = "bonemold_cuirass",  count = 1 },
        { ID = "steel_cuirass",     count = 1 },
        { ID = "fur_colovian_helm", count = 1 },
        { ID = "bonemold_helm",     count = 1 },
        { ID = "steel_helm",        count = 1 },
        { ID = "chitin greaves",    count = 1 },
        { ID = "bonemold_greaves",  count = 1 },
        { ID = "steel_greaves",     count = 1 },
        { ID = "chitin boots",      count = 1 },
        { ID = "bonemold_boots",    count = 1 },
        { ID = "steel_boots",       count = 1 }, },
    ["weapon_gifts"] = {
        { ID = "silver war axe",     count = 1 },
        { ID = "steel battle axe",   count = 1 },
        { ID = "steel mace",         count = 1 },
        { ID = "steel warhammer",    count = 1 },
        { ID = "dreugh staff",       count = 1 },
        { ID = "dwarven shortsword", count = 1 },
        { ID = "silver longsword",   count = 1 },
        { ID = "steel dai-katana",   count = 1 },
        { ID = "dwarven spear",      count = 1 },
        { ID = "bonemold long bow",  count = 1 }, },
    ["clothing_gifts"] = {
        { ID = "extravagant_amulet_02", count = 1 },
        { ID = "exquisite_belt_01",     count = 1 },
        { ID = "exquisite_pants_01",    count = 1 },
        { ID = "exquisite_ring_01",     count = 1 },
        { ID = "extravagant_robe_01_r", count = 1 },
        { ID = "exquisite_robe_01",     count = 1 },
        { ID = "exquisite_shirt_01",    count = 1 },
        { ID = "exquisite_shoes_01",    count = 1 },
        { ID = "exquisite_skirt_01",    count = 1 }, },
    ["book_gifts"] = {
        { ID = "bookskill_heavy armor1",  count = 1 },
        { ID = "bookskill_medium armor1", count = 1 },
        { ID = "bookskill_light armor3",  count = 1 },
        { ID = "BookSkill_Axe1",          count = 1 },
        { ID = "bookskill_spear1",        count = 1 },
        { ID = "bookskill_sneak4",        count = 1 },
        { ID = "BookSkill_Alteration1",   count = 1 },
        { ID = "bookskill_enchant5",      count = 1 },
        { ID = "bookskill_security5",     count = 1 },
        { ID = "BookSkill_Armorer1",      count = 1 },
        { ID = "bookskill_restoration1",  count = 1 },
        { ID = "BookSkill_Block1",        count = 1 },
        { ID = "bookskill_hand to hand5", count = 1 },
        { ID = "bookskill_unarmored1",    count = 1 },
        { ID = "BookSkill_Armorer1",      count = 1 },
        { ID = "bookskill_blunt weapon3", count = 1 },
        { ID = "BookSkill_Speechcraft1",  count = 1 },
        { ID = "bookskill_marksman1",     count = 1 },
        { ID = "bookskill_destruction1",  count = 1 },
        { ID = "bookskill_illusion2",     count = 1 },
        { ID = "bookskill_short blade1",  count = 1 },
        { ID = "BookSkill_Long Blade1",   count = 1 },
        { ID = "bookskill_mercantile1",   count = 1 },
        { ID = "BookSkill_Alchemy2",      count = 1 },
        { ID = "bookskill_mysticism1",    count = 1 },
        { ID = "BookSkill_Athletics1",    count = 1 },
        { ID = "bookskill_acrobatics1",   count = 1 }, },
}

constants.bdGiftsMap = {
    [1] = "armor_gifts",
    [2] = "weapon_gifts",
    [3] = "clothing_gifts",
    [4] = "book_gifts"
}

return constants
