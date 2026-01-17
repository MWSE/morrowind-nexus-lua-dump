local sb_achievements = require("sb_achievements.interop")
local aData = require("Pirate.Achievements_pack.AchData")
local pData
-- проверяем подключен ли мод Morrowind Achievement Collection.
local isActive = tes3.isLuaModActive("MAC")
if isActive == true then
    -- если да, то загружаем данные pData из этого мода.
    pData = include("MAC.playerData")
    else
    -- если нет то назначаем локальные значения цветов.
    pData = {
        colours = {
            bronze  = { 255 / 255, 140 / 255, 20 / 255 },
            silver  = { 200 / 255, 200 / 255, 255 / 255 },
            gold    = { 203 / 255, 190 / 255, 53 /255},
            plat    = { 200 / 255, 240 / 255, 200 / 255}
            }
        }
end
local i18n = mwse.loadTranslations("Pirate.Achievements_pack")

local function init()
    local iconPath = "Icons\\Ach_pack\\"

    local cats = {
        main = sb_achievements.registerCategory(i18n("Main Quest")),
        side = sb_achievements.registerCategory(i18n("Side Quest")),
        faction = sb_achievements.registerCategory(i18n("Faction")),
        misc = sb_achievements.registerCategory(i18n("Miscellaneous"))
    }

    sb_achievements.registerAchievement {
        id = "MW_Pillow",
        category = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            return tes3.getItemCount({ reference = "player", item = "misc_uni_pillow_unique" }) >0
        end,
        icon = iconPath .. "MW_Pillow.tga",
        colour = pData.colours.gold,
        title = i18n("MW_Pillow.Name"), desc = i18n("MW_Pillow.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }

    sb_achievements.registerAchievement {
        id = "MW_MeteorSlime",
        category = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            return tes3.getItemCount({ reference = "player", item = "ingred_scrib_jelly_02" }) >0
        end,
        icon = iconPath .. "MW_MeteorSlime.tga",
        colour = pData.colours.gold,
        title = i18n("MW_MeteorSlime.Name"), desc = i18n("MW_MeteorSlime.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }

        sb_achievements.registerAchievement {
        id = "MW_theLiar",
        category = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            ---@param creature tes3creatureInstance
            for npc in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                if (npc.baseObject.id == "m'aiq" and (npc.position:distance(tes3.player.position) < 512)) then
                    return true
                end
            end
            return false
        end,
        icon = iconPath .. "icn_theLiar.dds",
        colour = pData.colours.gold,
        title = i18n("MW_theLiar.Name"), desc = i18n("MW_theLiar.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id        = "MW_Webspinner",
        category  = cats.faction,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            return tes3.getGlobal("ThreadsWebspinner") >=26
        end,
        icon      = iconPath .. "icn_webOfMephala.dds",
        colour    = pData.colours.plat,
        title     = i18n("MW_Webspinner.Name"), desc = i18n("MW_Webspinner.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id        = "MW_vivecLessons",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount, 
        progress = function() 
            local myData = aData.getData() or {}
            local count = myData["VivecLessonsCount"] or 0
            if count >= 36 then
                event.unregister(tes3.event.bookGetText, aData.countLessons)
            end
            return count
        end, 
        progressMax = function() 
            return 36 
        end, 
        icon      = iconPath .. "icn_vivecLessons.dds",
        colour    = pData.colours.plat,
        title     = i18n("MW_vivecLessons.Name"), desc = i18n("MW_vivecLessons.Desc"),
    }
    sb_achievements.registerAchievement {
        id        = "MW_stillaStranger",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            return (tes3.getGlobal("DaysPassed") >=365)
        end,
        icon      = iconPath .. "icn_stillaStranger.dds",
        colour    = pData.colours.plat,
        title     = i18n("MW_stillaStranger.Name"), desc = i18n("MW_stillaStranger.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id        = "MW_orcIntelligence",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            return tes3.player.object.race.id == "Orc" and tes3.mobilePlayer.intelligence.base >= 100
        end,
        icon      = iconPath .. "icn_orcIntelligence.dds",
        colour    = sb_achievements.colours.indigo,
        title     = i18n("MW_orcIntelligence.Name"), desc = i18n("MW_orcIntelligence.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id        = "MW_nordSpeechcraft",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            return tes3.player.object.race.id == "Nord" and tes3.mobilePlayer.speechcraft.base >= 100
        end,
        icon      = iconPath .. "icn_nordSpeechcraft.dds",
        colour    = aData.colours.BlueWyrm,
        title     = i18n("MW_nordSpeechcraft.Name"), desc = i18n("MW_nordSpeechcraft.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id        = "MW_beastNerevarine",
        category  = cats.main,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            local raceId = tes3.player.object.race.id
            return (raceId == "Khajiit" or raceId == "Argonian") and tes3.getJournalIndex { id = "C3_DestroyDagoth" } >= 20
        end,
        icon      = iconPath .. "icn_beastNerevarine.dds",
        colour    = sb_achievements.colours.indigo,
        title     = i18n("MW_beastNerevarine.Name"), desc = i18n("MW_beastNerevarine.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id        = "MW_echoOfThePast",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress      = function()
            local myData = aData.getData() or {}
            local count = myData["AncestralTombCount"] or 0
            if count >= 88 then
                event.unregister(tes3.event.bookGetText, aData.countLessons)
            end
            return count
        end,
        progressMax   = function()
            return 88
        end,
        icon      = iconPath .. "icn_echoOfThePast.dds",
        colour    = pData.colours.plat,
        title     = i18n("MW_echoOfThePast.Name"), desc = i18n("MW_echoOfThePast.Desc"),
    }
    sb_achievements.registerAchievement {
        id        = "MW_miner",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.progressAmount,
        progress      = function()
            local myData = aData.getData() or {}
            local count = myData["mineCount"] or 0
            if count >= 43 then
                event.unregister(tes3.event.bookGetText, aData.countLessons)
            end
            return count
        end,
        progressMax   = function()
            return 43
        end,
        icon      = iconPath .. "icn_underTheEmpire.dds",
        colour    = pData.colours.gold,
        title     = i18n("MW_miner.Name"), desc = i18n("MW_miner.Desc"),
    }
    sb_achievements.registerAchievement {
        id        = "MW_dunmerStr",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            local myData = aData.getData()
            if (myData["dunmerStrCount"] >= 30) then
                event.unregister(tes3.event.cellChanged, aData.countDunmerStr)
                return true
            end
        end,
        icon      = iconPath .. "icn_dunmerStr.dds",
        colour    = pData.colours.bronze,
        title     = i18n("MW_dunmerStr.Name"), desc = i18n("MW_dunmerStr.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id        = "MW_daedricEq",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            local myData = aData.getData()
            if aData.daedricEq then
                return true
            end
        end,
        icon      = iconPath .. "icn_daedricEq.dds",
        colour    = pData.colours.plat,
        title     = i18n("MW_daedricEq.Name"), desc = i18n("MW_daedricEq.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id        = "MW_glassEq",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            local myData = aData.getData()
            if aData.glassEq then
                return true
            end
        end,
        icon      = iconPath .. "icn_glassEq.dds",
        colour    = pData.colours.gold,
        title     = i18n("MW_glassEq.Name"), desc = i18n("MW_glassEq.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id        = "MW_adamantiumEq",
        category  = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            local myData = aData.getData()
            if aData.adamantiumEq then
                return true
            end
        end,
        icon      = iconPath .. "icn_adamantiumEq.dds",
        colour    = pData.colours.plat,
        title     = i18n("MW_adamantiumEq.Name"), desc = i18n("MW_adamantiumEq.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }
    sb_achievements.registerAchievement {
        id = "MW_Miser",
        category = cats.misc,
        conditionType = sb_achievements.conditionType.instant,
        condition = function()
            return tes3.getItemCount({ reference = "player", item = "gold_001" }) >999999
        end,
        icon = iconPath .. "MW_Miser.tga",
        colour = pData.colours.gold,
        title = i18n("MW_Miser.Name"), desc = i18n("MW_Miser.Desc"),
        configDesc = sb_achievements.configDesc.groupHidden,
        lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
    }


end

local function initializedCallback(e)
    init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })
event.register(tes3.event.loaded, aData.initachievePack)
