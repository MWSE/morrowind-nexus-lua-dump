local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local screenSize = ui.screenSize()
local storage = require('openmw.storage')
local playerSettings = storage.playerSection('Settings/OmwAchievements/Options')
local util = require('openmw.util')
local v2 = util.vector2
local interfaces = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local time = require('openmw_aux.time')

local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')
local achievements = require('scripts.omw_achievements.achievements.achievements')
local playerSettings = storage.playerSection('Settings/OmwAchievements/Options')

local createProgressBar = {}

function percentOf(t)
    local x = t[1]
    local y = t[2]

    if type(x) ~= "number" or type(y) ~= "number" or y == 0 then
        return 0
    end

    local percent = (x / y) * 100
    percent = math.floor(percent * 10 + 0.5) / 10

    return percent
end

function achievementProgressPercent(visitedCells, achievementCells)
    if type(visitedCells) ~= "table" or type(achievementCells) ~= "table" then
        return 0
    end

    local visitedMap = {}
    for _, cell in ipairs(visitedCells) do
        visitedMap[cell] = true
    end

    local visitedCount = 0
    local totalRequired = #achievementCells

    if totalRequired == 0 then
        return 0
    end

    for _, cell in ipairs(achievementCells) do
        if visitedMap[cell] then
            visitedCount = visitedCount + 1
        end
    end

    local percent = (visitedCount / totalRequired) * 100
    percent = math.floor(percent * 10 + 0.5) / 10
    return percent
end

function achievementProgressFraction(visitedCells, achievementCells)
    if type(visitedCells) ~= "table" or type(achievementCells) ~= "table" then
        return 0
    end

    local visitedMap = {}
    for _, cell in ipairs(visitedCells) do
        visitedMap[cell] = true
    end

    local visitedCount = 0
    local totalRequired = #achievementCells

    if totalRequired == 0 then
        return 0
    end

    for _, cell in ipairs(achievementCells) do
        if visitedMap[cell] then
            visitedCount = visitedCount + 1
        end
    end

    return visitedCount .. "/\n" .. totalRequired
end

function createProgressBar.getFraction(achievementType, id)
    local macData = interfaces.storageUtils.getStorage("counters")
    local omwaData = interfaces.storageUtils.getStorage("achievements")
    local achievement = sk00maUtils.getAchievementById(achievements, id)

    --- Completed fraction for unlocked achievements
    if omwaData:get(id) == true then

        -- Completed fraction for common types of achievements
        if achievementType == "single_quest" or achievementType == "talkto" or achievementType == "join_faction" then
            return "1/\n1"
        elseif achievementType == "multi_quest" and achievement.progressOperator == nil then
            return "1/\n1"
        elseif achievementType == "multi_quest" and achievement.progressOperator ~= nil then
            local questAmount = #achievement.journalID
            local multiQuestJournalIds = achievement.journalID
            local multiQuestStages = achievement.stage
            local currentQuestStageTable = {}
            for q, str in ipairs(multiQuestJournalIds) do
                multiQuestJournalIds[q] = string.lower(str)
            end
            for k = 1, questAmount do
                for j = 1, questAmount do
                    local currentQuestStage = types.Player.quests(self.object)[multiQuestJournalIds[j]].stage
                    table.insert(currentQuestStageTable, currentQuestStage)
                end
            end
            local progressTable = achievement.progressOperator(achievement, currentQuestStageTable)
            return progressTable[2] .. "/\n" .. progressTable[2]
        elseif achievementType == "visit_all" then
            return #achievement.cells .. "/\n" .. #achievement.cells
        elseif achievementType == "read_all" then
            return #achievement.books .. "/\n" .. #achievement.books
        elseif achievementType == "equipment" then
            local equipmentTable = achievement.equipment
            local maxProgression = 0
            for _ in pairs(equipmentTable) do
                maxProgression = maxProgression + 1
            end
            return maxProgression .. "/\n" .. maxProgression
        elseif achievementType == "rank_faction" then
            local requiredRank = achievement.rank
            return requiredRank .. "/\n" .. requiredRank
        elseif achievementType == "global_variable" then
            local value = achievement.value
            return value .. "/\n" .. value
        end

        -- Completed fraction for unique achievements
        if achievementType == "unique" then
            if id == "book_01" then
                local bookRead = macData:getCopy('bookRead')
                return "100" .. "/\n" .. "100"
            elseif id == "museum_01" then
                local museumArtifacts = macData:getCopy("museumArtifacts")
                return "32" .. "/\n" .. "32"
            elseif id == "free_slaves_01" then
                local slavesCounter = macData:get("slavesCounter")
                return "50" .. "/\n" .. "50"
            elseif id == "orc_intelligence_01" then
                return "100" .. "/\n" .. "100"
            elseif id == "nord_speechcraft_01" then
                return "100" .. "/\n" .. "100"
            elseif id == "dayspassed_01" then
                return "60" .. "/\n" .. "60"
            elseif id == "dayspassed_02" then
                return "365" .. "/\n" .. "365"
            elseif id == "skooma_01" then
                return "100" .. "/\n" .. "100"
            elseif id == "killtribunal_01" or
            id == "ordinator_01" or
            "beast_nerevarine_01" or
            "azurastar_01" or
            "werewolf_01" then
                return "1/\n1"
            end
        end

    end

    local progressFraction = "0/\n1"

    --- Calculate progress fraction for "multi_quest"
    if achievementType == "multi_quest" then
        if achievement.progressOperator ~= nil then
            local questAmount = #achievement.journalID
            local multiQuestJournalIds = achievement.journalID
            local multiQuestStages = achievement.stage
            local currentQuestStageTable = {}

            for q, str in ipairs(multiQuestJournalIds) do
                multiQuestJournalIds[q] = string.lower(str)
            end

            for k = 1, questAmount do
                for j = 1, questAmount do
                    local currentQuestStage = types.Player.quests(self.object)[multiQuestJournalIds[j]].stage
                    table.insert(currentQuestStageTable, currentQuestStage)
                end
            end

            local progressTable = achievement.progressOperator(achievement, currentQuestStageTable)
            progressFraction = progressTable[1] .. "/\n" .. progressTable[2]
        else
            progressFraction = "0/\n1"
        end
    end

    --- Calculate progress fraction for "visit_all"
    if achievementType == "visit_all" then
        local achievementCells = achievement.cells
        local visitedCells = macData:getCopy("visitedCells")
        progressFraction = achievementProgressFraction(visitedCells, achievementCells)
    end

    --- Calculate progress fraction for "read_all"
    if achievementType == "read_all" then
        local achievementBooks = achievement.books
        local bookRead = macData:getCopy("bookRead")
        progressFraction = achievementProgressFraction(bookRead, achievementBooks)
    end

    --- Calculate progress fraction for "equipment"
    if achievementType == "equipment" then
        local equipmentTable = achievement.equipment
        local maxProgression = 0
        for _ in pairs(equipmentTable) do
            maxProgression = maxProgression + 1
        end
        local currentProgression = 0

        for slotKey, expected in pairs(equipmentTable) do
            local equippedItem = types.Actor.getEquipment(self.object, slotKey)
            if equippedItem ~= nil then
                local equippedItem = types.Actor.getEquipment(self.object, slotKey)
                local recordId = equippedItem.recordId

                if type(expected) == "string" then
                    if recordId == expected then
                        currentProgression = currentProgression + 1
                    end
                elseif type(expected) == "table" then
                    if sk00maUtils.contains(expected, recordId) then
                        currentProgression = currentProgression + 1
                    end
                end
            end
        end

        progressFraction = currentProgression .. "/\n" .. maxProgression
    end

    --- Calculate progress fraction for "rank_faction"
    if achievementType == "rank_faction" then
        local requiredRank = achievement.rank
        local factionId = achievement.factionId
        local currentRank = types.NPC.getFactionRank(self.object, factionId)
        progressFraction = currentRank .. "/\n" .. requiredRank
    end

    --- Calculate progress fraction for "single_quest"
    if achievementType == "single_quest" then
        progressFraction = "0/\n1"
    end

    --- Calculate progress fraction for "global_variable"
    if achievementType == "global_variable" then
        local globalVariables = macData:getCopy("globalVariables")
        local currentProgression = globalVariables[achievement.variable]
        local maxProgression = achievement.value
        progressFraction = currentProgression .. "/\n" .. maxProgression
    end

    --- Calculate progress fraction for unique achievements
    if achievementType == "unique" and id == "book_01" then
        local bookRead = macData:getCopy('bookRead')
        progressFraction = #bookRead .. "/\n" .. "100"
    end

    if achievementType == "unique" and id == "museum_01" then
        local museumArtifacts = macData:getCopy("museumArtifacts")
        progressFraction = #museumArtifacts .. "/\n" .. "32"
    end

    if achievementType == "unique" and id == "free_slaves_01" then
        local slavesCounter = macData:get("slavesCounter")
        progressFraction = slavesCounter .. "/\n" .. "50"
    end

    if achievementType == "unique" and id == "orc_intelligence_01" then
        if types.NPC.record(self.object).race == "orc" then
            local currentIntelligence = types.Actor.stats.attributes.intelligence(self.object).modified
            progressFraction = currentIntelligence .. "/\n" .. "100"
        end
    end

    if achievementType == "unique" and id == "nord_speechcraft_01" then
        if types.NPC.record(self.object).race == "nord" then
            local currentSpeechcraft = types.NPC.stats.skills.speechcraft(self.object).modified
            progressFraction = currentSpeechcraft .. "/\n" .. "100"
        end
    end

    if achievementType == "unique" and id == "dayspassed_01" then
        local daysPassed = math.floor(core.getGameTime() / time.day)
        if types.Player.quests(self.object)["a1_1_findspymaster"].stage < 14 then
            progressFraction = daysPassed .. "/\n" .. "60"
        end
    end

    if achievementType == "unique" and id == "dayspassed_02" then
        local daysPassed = math.floor(core.getGameTime() / time.day)
        progressFraction = daysPassed .. "/\n" .. "365"
    end

    if achievementType == "unique" and id == "skooma_01" then
        local skoomaBottlesCounter = macData:get("skoomaBottles")
        progressFraction = skoomaBottlesCounter .. "/\n" .. "100"
    end

    return progressFraction
end

function createProgressBar.getPercentage(achievementType, id)
    local macData = interfaces.storageUtils.getStorage("counters")
    local omwaData = interfaces.storageUtils.getStorage("achievements")
    local achievement = sk00maUtils.getAchievementById(achievements, id)

    if omwaData:get(id) == true then
        return 100
    end

    local progressPercentage = 0

    --- Calculate progress percentage for "multi_quest"
    if achievementType == "multi_quest" then
        if achievement.progressOperator ~= nil then
            local questAmount = #achievement.journalID
            local multiQuestJournalIds = achievement.journalID
            local multiQuestStages = achievement.stage
            local currentQuestStageTable = {}

            for q, str in ipairs(multiQuestJournalIds) do
                multiQuestJournalIds[q] = string.lower(str)
            end

            for k = 1, questAmount do
                for j = 1, questAmount do
                    local currentQuestStage = types.Player.quests(self.object)[multiQuestJournalIds[j]].stage
                    table.insert(currentQuestStageTable, currentQuestStage)
                end
            end

            local progressTable = achievement.progressOperator(achievement, currentQuestStageTable)
            progressPercentage = percentOf(progressTable)
        else
            progressPercentage = 0
        end
    end

    --- Calculate progress percentage for "visit_all"
    if achievementType == "visit_all" then
        local achievementCells = achievement.cells
        local visitedCells = macData:getCopy("visitedCells")
        progressPercentage = achievementProgressPercent(visitedCells, achievementCells)
    end

    --- Calculate progress percentage for "read_all"
    if achievementType == "read_all" then
        local achievementBooks = achievement.books
        local bookRead = macData:getCopy("bookRead")
        progressPercentage = achievementProgressPercent(bookRead, achievementBooks)
    end

    --- Calculate progress percentage for "equipment"
    if achievementType == "equipment" then
        local equipmentTable = achievement.equipment
        local maxProgression = 0
        for _ in pairs(equipmentTable) do
            maxProgression = maxProgression + 1
        end
        local currentProgression = 0

        for slotKey, expected in pairs(equipmentTable) do
            local equippedItem = types.Actor.getEquipment(self.object, slotKey)
            if equippedItem ~= nil then
                local equippedItem = types.Actor.getEquipment(self.object, slotKey)
                local recordId = equippedItem.recordId

                if type(expected) == "string" then
                    if recordId == expected then
                        currentProgression = currentProgression + 1
                    end
                elseif type(expected) == "table" then
                    if sk00maUtils.contains(expected, recordId) then
                        currentProgression = currentProgression + 1
                    end
                end
            end
        end

        local progressTable = {currentProgression, maxProgression}
        progressPercentage = percentOf(progressTable)
    end

    --- Calculate progress percentage for "rank_faction"
    if achievementType == "rank_faction" then
        local requiredRank = achievement.rank
        local factionId = achievement.factionId
        local currentRank = types.NPC.getFactionRank(self.object, factionId)
        local progressTable = {currentRank, requiredRank}
        progressPercentage = percentOf(progressTable)
    end

    --- Calculate progress percentage for "single_quest"
    if achievementType == "single_quest" then
        progressPercentage = 0
    end

    --- Calculate progress percentage for "global_variable"
    if achievementType == "global_variable" then
        if achievement.enableProgress == true then
            local globalVariables = macData:getCopy("globalVariables")
            local currentValue = globalVariables[achievement.variable]
            progressPercentage = percentOf({currentValue, achievement.value})
        end
    end

    --- Calculate progress for unique achievements
    if achievementType == "unique" and id == "book_01" then
        local bookRead = macData:getCopy('bookRead')
        progressPercentage = percentOf({#bookRead, 100})
    end

    if achievementType == "unique" and id == "museum_01" then
        local museumArtifacts = macData:getCopy("museumArtifacts")
        progressPercentage = percentOf({#museumArtifacts, 32})
    end

    if achievementType == "unique" and id == "free_slaves_01" then
        local slavesCounter = macData:get("slavesCounter")
        progressPercentage = percentOf({slavesCounter, 50})
    end

    if achievementType == "unique" and id == "orc_intelligence_01" then
        if types.NPC.record(self.object).race == "orc" then
            local currentIntelligence = types.Actor.stats.attributes.intelligence(self.object).modified
            progressPercentage = percentOf({currentIntelligence, 100})
        end
    end

    if achievementType == "unique" and id == "nord_speechcraft_01" then
        if types.NPC.record(self.object).race == "nord" then
            local currentSpeechcraft = types.NPC.stats.skills.speechcraft(self.object).modified
            progressPercentage = percentOf({currentSpeechcraft, 100})
        end
    end

    if achievementType == "unique" and id == "dayspassed_01" then
        local daysPassed = math.floor(core.getGameTime() / time.day)
        if types.Player.quests(self.object)["a1_1_findspymaster"].stage < 14 then
            progressPercentage = percentOf({daysPassed, 60})
        end
    end

    if achievementType == "unique" and id == "dayspassed_02" then
        local daysPassed = math.floor(core.getGameTime() / time.day)
        progressPercentage = percentOf({daysPassed, 365})
    end

    if achievementType == "unique" and id == "skooma_01" then
        local skoomaBottlesCounter = macData:get("skoomaBottles")
        progressPercentage = percentOf({skoomaBottlesCounter, 100})
    end

    return progressPercentage
end

function createProgressBar.createLocked(achievementType, id)

    local width_ratio = 0.25
    local scale_factor = playerSettings:get('ui_scaling_factor')
    local widget_width = screenSize.x * width_ratio * scale_factor
    local icon_size = screenSize.y * 0.06 * scale_factor

    local progressPercentage = createProgressBar.getPercentage(achievementType, id)

    local achievementLogoBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(icon_size, icon_size)
        }
    }

    local progressBarTexture = {
        type = ui.TYPE.Image,
        props = {
            relativePosition = v2(0, 0),
            anchor = v2(0, 0),
            alpha = 0.3,
            size = v2(((widget_width * 0.85)-7-icon_size)*(progressPercentage*0.01), icon_size),
            resource = ui.texture { path = "Textures\\omwa\\progress_bar.dds" }
        }
    }

    local progressBar = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(0, 0), 
            relativePosition = v2(0, 0),
            size = v2(((widget_width * 0.85)-7-icon_size)*(progressPercentage*0.01), icon_size)
        },
        content = ui.content({progressBarTexture})
    }

    local emptyVBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(7, 80)
        }
    }

    local progressBarFlex = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            relativePosition = v2(0, 0),
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center
        },
        external = {
            stretch = 1,
            grow = 1
        },
        content = ui.content(
            {achievementLogoBox,
            emptyVBox,
            progressBar}
        )
    }

    return(progressBarFlex)
end

function createProgressBar.createUnlocked()

    local width_ratio = 0.25
    local scale_factor = playerSettings:get('ui_scaling_factor')
    local widget_width = screenSize.x * width_ratio * scale_factor
    local icon_size = screenSize.y * 0.06 * scale_factor

    local achievementLogoBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(icon_size, icon_size)
        }
    }

    local progressBarTexture = {
        type = ui.TYPE.Image,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            alpha = 0.3,
            size = v2((widget_width * 0.85)-7-icon_size, icon_size),
            resource = ui.texture { path = "Textures\\omwa\\progress_bar.dds" }
        }
    }

    local progressBar = {
        type = ui.TYPE.Widget,
        props = {
            size = v2((widget_width * 0.85)-7-icon_size, icon_size)
        },
        content = ui.content({progressBarTexture})
    }

    local emptyVBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(7, 80)
        }
    }

    local progressBarFlex = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            relativePosition = v2(0, 0),
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center
        },
        external = {
            stretch = 1,
            grow = 1
        },
        content = ui.content(
            {achievementLogoBox,
            emptyVBox,
            progressBar}
        )
    }

    return(progressBarFlex)
end

function createProgressBar.createEmpty()
    local width_ratio = 0.25
    local scale_factor = playerSettings:get('ui_scaling_factor')
    local widget_width = screenSize.x * width_ratio * scale_factor
    local icon_size = screenSize.y * 0.06 * scale_factor

    local achievementLogoBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(icon_size, icon_size)
        }
    }

    local progressBar = {
        type = ui.TYPE.Widget,
        props = {
            size = v2((widget_width * 0.85)-7-icon_size, icon_size)
        }
    }

    local emptyVBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(7, 80)
        }
    }

    local progressBarFlex = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            relativePosition = v2(0, 0),
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center
        },
        external = {
            stretch = 1,
            grow = 1
        },
        content = ui.content(
            {achievementLogoBox,
            emptyVBox,
            progressBar}
        )
    }

    return(progressBarFlex)
end

return createProgressBar