local dataHandler = require("scripts.quest_guider_lite.storage.dataHandler")
local questLib = require("scripts.quest_guider_lite.quest")
local log = require("scripts.quest_guider_lite.utils.log")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local requirementChecker = require("scripts.quest_guider_lite.requirementChecker")
local myTypes = require("scripts.quest_guider_lite.types")

local this = {}

---@param data questDataGenerator.requirementData
local function getRequirementDataHash(data)
    local ret = ""
    for name, _ in pairs(data) do
        ret = ret..name
    end
    return ret
end

function this.descriptionLines()
    local descriptionLines = require("scripts.quest_guider_lite.descriptionLines")
    ---@type table<string, table<string, questDataGenerator.requirementData>>
    local types = {}

    ---@type table<string, integer>
    local reqCount = {}

    local reqNum = 0
    local knownNum = 0

    ---@param reqBlock questDataGenerator.requirementData[]
    local function processReqBlock(reqBlock)
        for _, req in pairs(reqBlock) do
            reqNum = reqNum + 1
            if descriptionLines[req.type] then
                knownNum = knownNum + 1
            end

            local reqTypeList = types[req.type]
            if not reqTypeList then
                types[req.type] = {}
                reqTypeList = types[req.type]
            end
            reqTypeList[getRequirementDataHash(req)] = req

            reqCount[req.type] = (reqCount[req.type] or 0) + 1
        end
    end

    for qId, qStages in pairs(dataHandler.quests) do

        for name, qData in pairs(qStages) do
            if name == "name" or name == "hasFinished" or name == "links" then
                goto continue
            end

            for _, reqBlock in pairs(qData.requirements or {}) do
                processReqBlock(reqBlock)
            end

            ::continue::
        end
    end

    for scriptId, scrData in pairs(dataHandler.localVariablesByScriptId) do
        for varName, varData in pairs(scrData) do
            for _, resData in pairs(varData.results) do
                for _, resBlock in pairs(resData) do
                    processReqBlock(resBlock)
                end
            end
        end
    end

    for tp, _ in pairs(types) do
        if not descriptionLines[tp] then
            log("Not found:", tp)
        end
    end
    log("Found requirements:", reqNum)
    log("Known requirements:", knownNum)
    log("Coverage:", knownNum / reqNum)

    local countList = {}
    for reqType, count in pairs(reqCount) do
        table.insert(countList, {count, reqType})
    end

    table.sort(countList, function (a, b)
        return a[1] > b[1]
    end)

    print("")
    print("")
    log("Count:")
    print("")
    for _, dt in ipairs(countList) do
        log(dt[2], ":", dt[1])
    end

    for type, data in pairs(types) do
        print("")
        print("")
        log("Type:", type)
        print("")
        for _, req in pairs(data) do
            local resData = questLib.getDescriptionDataFromDataBlock({req})
            if resData and resData[1] then
                log(resData[1].str) ---@diagnostic disable-line: need-check-nil
                print("")
                log(req)
            end
        end
    end
end


function this.printRandomQuestList(showGiverData)
    ---@type { name: string, links: string[]?, hasFinished: boolean?, [string]: questDataGenerator.stageData }[]
    local dias = tableLib.keys(dataHandler.quests)
    tableLib.shuffle(dias)

    local allowedTypes = {
        [myTypes.requirementType.Journal] = true,
        [myTypes.requirementType.CustomPCFaction] = true,
        [myTypes.requirementType.CustomPCRank] = true,
        [myTypes.requirementType.CustomGlobal] = true,
        [myTypes.requirementType.Dead] = true,
        [myTypes.requirementType.CustomOnDeath] = true,
        [myTypes.requirementType.Item] = true,
    }

    local i = 0

    for _, diaId in ipairs(dias) do
        if i > 100 then break end
        local qDt = dataHandler.quests[diaId]
        local firstInd = questLib.getFirstIndex(qDt)
        local firstDt = qDt[tostring(firstInd)]

        if firstDt then
            for _, reqBlock in pairs(firstDt.requirements or {}) do
                local ret = requirementChecker.checkBlock(reqBlock, {
                    allowedTypes = allowedTypes,
                    threatErrorsAs = true,
                })

                if ret then
                    print(string.format("Journal \"%s\" %s", diaId, tostring(firstInd)))
                    if showGiverData then
                        for _, req in pairs(reqBlock) do
                            if req.type == "ACT" and req.object then
                                local objData = dataHandler.questObjects[req.object]
                                log((objData or {}).positions)
                            end

                            if req.type == "DIA" then
                                print(req.variable)
                            end
                        end
                    end
                    i = i + 1
                    break
                end
            end
        end
    end
end


return this