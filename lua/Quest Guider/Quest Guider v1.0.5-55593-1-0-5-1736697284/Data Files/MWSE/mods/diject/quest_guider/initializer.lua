local log = include("diject.quest_guider.utils.log")
local config = include("diject.quest_guider.config")

local this = {}

this.logLevel = 0
-- TODO add file existence check
---@param async boolean|nil
---@return boolean res true if successful. If async always true
function this.runDataGeneration(async)
    local maxPos = config.data.data.maxPos
    local dir = tes3.installDirectory.."\\Data Files\\MWSE\\lib\\quest_guider"
    local outputDir = tes3.installDirectory.."\\Data Files\\MWSE\\mods\\diject\\quest_guider\\Data"
    local encoding
    if tes3.getLanguageCode() == tes3.languageCode.pol then
        encoding = "1250"
    elseif tes3.getLanguageCode() == tes3.languageCode.rus then
        encoding = "1251"
    else
        encoding = "1252"
    end

    -- by morrowind.ini
    -- local command = string.format("start /B \"\" /D \"%s\" \"Quest Data Builder.exe\" -p %d -d \"%s\" -o \"%s\" -e %s -l %d",
    --     dir, maxPos, tes3.installDirectory, outputDir, encoding, this.logLevel)

    -- by mod names
    -- local command = string.format("start /B \"\" /D \"%s\" \"Quest Data Builder.exe\" -p %d -e %s -d \"%s\" -o \"%s\" -l %d -f",
    --     dir, maxPos, encoding, tes3.installDirectory, outputDir, this.logLevel)
    -- for _, gameFile in ipairs(tes3.dataHandler.nonDynamicData.activeMods) do
    --     if gameFile.playerName == "" then
    --         command = string.format("%s \"%s\"", command, gameFile.filename)
    --     end
    -- end

    -- by data file
    local inputData = {
        logLevel = this.logLevel,
        directory = tes3.installDirectory,
        output = outputDir,
        encoding = encoding,
        maxPos = maxPos,
        gameFiles = {},
    }
    for _, gameFile in ipairs(tes3.dataHandler.nonDynamicData.activeMods) do
        if gameFile.playerName == "" then
            table.insert(inputData.gameFiles, gameFile.filename)
        end
    end
    json.savefile("\\mods\\diject\\quest_guider\\Data\\input", inputData)
    local inputDataPath = tes3.installDirectory.."\\Data Files\\MWSE\\mods\\diject\\quest_guider\\Data\\input.json"
    local command = string.format("start /B \"\" /D \"%s\" \"Quest Data Builder.exe\" -p %d -d \"%s\" -i \"%s\" -o \"%s\" -e %s -l %d",
        dir, maxPos, tes3.installDirectory, inputDataPath, outputDir, encoding, this.logLevel)

    log(command)
    if async then
        if os.execute(command) ~= 0 then
            return false
        end
    else
        local handle = io.popen(command)
        if not handle then
            log("Error in data generation")
            return false
        end
        local result = handle:read("*a")
        log("Data Generator Output:")
        log(result)
        handle:close()
    end
    return true
end

return this