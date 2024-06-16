local icon = include("SSQN.interop")
local sb_achievements = include("sb_achievements.interop")

local function init()
    -- Custom Icons for Skyrim Style Quest Notifications
    if (icon) then
        icon.registerQIcon("CPRSSQ","\\Icons\\CPRS\\CPRSSQ_icon.dds")
        icon.registerQIcon("CPRSMQ","\\Icons\\CPRS\\CPRSSQ_icon.dds")
    end

   --Acheivements for SB_Achievements Framework
    if (sb_achievements) then
        local iconPath = "Icons\\CPRS\\"
        local openedSB
        local function openedSunBird(e)
            if (e.target.id == "CPRS_Secret_TrinGear") then
                openedSB = true
            end
        end

        event.register("activate", openedSunBird)

        local cats = {
            CPRS = sb_achievements.registerCategory("CPRS"),
        }

        sb_achievements.registerAchievement {
            id        = "CPRSMQ_07",
            category  = cats.CPRS,
            condition = function()
                return tes3.getJournalIndex { id = "CPRSMQ_07" } >= 100
            end,
            icon      = iconPath .. "CPRS_MQ_icon.dds",
            colour    = sb_achievements.colours.violet,
            title     = "Tri-Angled Master", desc = "You completed CPRS: The Tri-Angled Truth",
        }
        sb_achievements.registerAchievement {
            id        = "CPRSMQ_PSJJJ",
            category  = cats.CPRS,
            condition = function()
                return tes3.getJournalIndex { id = "CPRSMQ_06" } == 110 or tes3.getJournalIndex { id = "CPRSMQ_06" } == 120
            end,
            icon      = iconPath .. "CPRS_TT_icon.dds",
            colour    = sb_achievements.colours.violet,
            title     = "The PSJJJ Endeavor", desc = "You read Veloth's The PSJJJ Endeavor",
            configDesc = sb_achievements.configDesc.groupHidden
        }
        sb_achievements.registerAchievement {
            id        = "CPRSSQ_ALL",
            category  = cats.CPRS,
            condition = function()
                return tes3.getJournalIndex { id = "CPRSSQ_Daedrabook" } >= 40 and tes3.getJournalIndex { id = "CPRSSQ_Dralas" } == 100 and tes3.getJournalIndex { id = "CPRSSQ_Interview" } == 100 and tes3.getJournalIndex { id = "CPRSSQ_Skinescort" } == 40 and tes3.getJournalIndex { id = "CPRSSQ_Quinaepissu" } == 103 and tes3.getJournalIndex { id = "CPRSSQ_UndilusFlyers" } == 100 and tes3.getJournalIndex { id = "CPRSSQ_VivecSermons" } == 100
            end,
            icon      = iconPath .. "CPRS_SQ_icon.dds",
            colour    = sb_achievements.colours.violet,
            title     = "Friend of the CPRS", desc = "Finish all the CPRS: The Tri-Angled Truth side quests"
        }
        sb_achievements.registerAchievement {
            id        = "CPRSSQ_SB",
            category  = cats.CPRS,
            condition = function()
                local sbContainer = "CPRS_Secret_TrinGear"
                if (openedSB == true) then
                    return true
                end
            end,
            icon      = iconPath .. "CPRS_SB_icon.dds",
            colour    = sb_achievements.colours.violet,
            title     = "The SunBird", desc = "You were gifted Trinimac's Raiment",
            configDesc = sb_achievements.configDesc.groupHidden
        }
    end
end

event.register("initialized", init, { priority = sb_achievements.priority + 1 })