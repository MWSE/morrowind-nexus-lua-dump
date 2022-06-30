local data = require("kindi.security.data")
local function saveData()
    local toSaveData = data
    tes3.player.data.kindi_securitySuccess = toSaveData
end
local function loadData(loaded)
    local fileName = loaded.filename

    local toLoadData = mwse.loadConfig("ss_kindi_data") or {}
    data =
        tes3.player.data.kindi_securitySuccess or toLoadData[fileName] or
        {
            pickedObjects = {},
            pickedTools = {},
            pickedNTime = 1,
            pickedNSucc = 0,
            pickedNFail = 0,
            pickedCumLVL = 0,
            probedObjects = {},
            probedTools = {},
            probedNTime = 1,
            probedNSucc = 0,
            probedNFail = 0,
            probedPTrap = 0,
            Doors = 1380929348,
            Containers = 1414418243,
            Lockpick = 1262702412,
            Probe = 1112494672,
            Other = 0
        }
end
local function statsCollector(e)
    if not e.picker == tes3.player then
        return
    end

    if not e.reference then
        return
    end

    local isObjLocked = e.lockPresent
    local chance = e.chance
    local toolName = (e.tool.name):gsub("%s+", "_")
    local toolType = e.tool.objectType
    local obj = e.reference
    local lockLvl = obj.lockNode.level
    local withKey = obj.lockNode.key
    local isTrapped = obj.lockNode.trap
    local trapPoint = 0

    if tes3.getTrap {reference = obj} then
        trapPoint = tes3.getTrap {reference = obj}.magickaCost
    end

    --[[Lockpick]]
    if toolType == tes3.objectType.lockpick then
        data.pickedNTime = data.pickedNTime + 1

        if not data.pickedTools[toolName] then
            data.pickedTools[toolName] = 0
        end
        data.pickedTools[toolName] = data.pickedTools[toolName] + 1

        if not data.pickedObjects[table.find(data, obj.object.objectType)] then
            data.pickedObjects[table.find(data, obj.object.objectType)] = 0
        end

        timer.delayOneFrame(
            function()
                if obj.lockNode.locked == false then
                    data.pickedNSucc = data.pickedNSucc + 1
                    data.pickedObjects[table.find(data, obj.object.objectType)] =
                        data.pickedObjects[table.find(data, obj.object.objectType)] + 1
                    data.pickedCumLVL = data.pickedCumLVL + lockLvl
                else
                    data.pickedNFail = data.pickedNFail + 1
                end
            end
        )
    end

    --[[Probing]]
    if toolType == tes3.objectType.probe then
        data.probedNTime = data.probedNTime + 1

        if not data.probedTools[toolName] then
            data.probedTools[toolName] = 0
        end
        data.probedTools[toolName] = data.probedTools[toolName] + 1

        if not data.probedObjects[table.find(data, obj.object.objectType)] then
            data.probedObjects[table.find(data, obj.object.objectType)] = 0
        end

        timer.delayOneFrame(
            function()
                if obj.lockNode.trap == nil then
                    data.probedNSucc = data.probedNSucc + 1
                    data.probedObjects[table.find(data, obj.object.objectType)] =
                        data.probedObjects[table.find(data, obj.object.objectType)] + 1
                    data.probedPTrap = data.probedPTrap + trapPoint
                else
                    data.probedNFail = data.probedNFail + 1
                end
            end
        )
    end
end
local function statRecord()
    local des = ""
    local tempN = 1
    local tempN2 = 1
    local temp = {}
    local temp2 = {}
    local s = ""
    local a = string.format("Lockpick attempts: %s\n", data.pickedNTime - 1)
    local b = string.format("Number of successful attempts: %s\n", data.pickedNSucc)
    local c = string.format("Number of failed attempts: %s\n", data.pickedNFail)
    local d = string.format("Cumulative lock level unlocked: %s\n", data.pickedCumLVL)
    local e = string.format("Success rate: %s %%\n", data.pickedNSucc / (data.pickedNTime - 1) * 100)

    if table.size(data.pickedTools) > 0 then
        for k, v in pairs(data.pickedTools) do
            table.insert(temp, string.format("%s: %s times\n", k:gsub("_", " "), v))
            tempN2 = tempN2 + v
        end
    else
        table.insert(temp, "No data yet\n")
    end

    if table.size(data.pickedObjects) > 0 then
        for k, v in pairs(data.pickedObjects) do
            table.insert(temp2, string.format("%s: %s times\n", k, v))
            tempN = tempN + v
        end
    else
        table.insert(temp2, "No data yet\n")
    end

    s = s .. "\nLockpick tools usage attempts: \n"

    for i = 1, #temp do
        s = s .. temp[i]
    end

    s = s .. "\nType of objects unlocked: \n"

    for i = 1, #temp2 do
        s = s .. temp2[i]
    end

    s = s .. string.format("Total: %s\n", tempN - 1)

    f = string.format("Average lock level unlocked: %s\n", data.pickedCumLVL / (tempN - 1))

    local header = string.format("          ~History and Statistics [%s]~\n\n", tes3.player.object.name)
    des = header .. a .. b .. c .. d .. f .. e .. s .. "\n----------------------------------------------\n\n"

    tempN = 1
    tempN2 = 1
    temp = {}
    temp2 = {}
    s = ""
    a = string.format("Disarm attempts: %s\n", data.probedNTime - 1)
    b = string.format("Number of successful attempts: %s\n", data.probedNSucc)
    c = string.format("Number of failed attempts: %s\n", data.probedNFail)
    d = string.format("Cumulative trap points disarmed: %s points\n", data.probedPTrap)
    e = string.format("Success rate: %s %%\n", data.probedNSucc / (data.probedNTime - 1) * 100)

    if table.size(data.probedTools) > 0 then
        for k, v in pairs(data.probedTools) do
            table.insert(temp, string.format("%s: %s times\n", k:gsub("_", " "), v))
        end
    else
        table.insert(temp, "No data yet\n")
    end

    if table.size(data.probedObjects) > 0 then
        for k, v in pairs(data.probedObjects) do
            table.insert(temp2, string.format("%s: %s times\n", k, v))
            tempN = tempN + v
        end
    else
        table.insert(temp2, "No data yet\n")
    end

    s = s .. "\nProbe tools usage attempts: \n"

    for i = 1, #temp do
        s = s .. temp[i]
    end

    s = s .. "\nType of objects disarmed: \n"

    for i = 1, #temp2 do
        s = s .. temp2[i]
    end

    s = s .. string.format("Total: %s\n", tempN - 1)

    f = string.format("Average trap points disarmed: %s\n", data.probedPTrap / (tempN - 1))

    des = des .. a .. b .. c .. d .. f .. e .. s

    SS_KINDI_UPDATE_STATS(des)
end

event.register("menuEnter", statRecord)
event.register("loaded", loadData)
event.register("save", saveData)
event.register("lockPick", statsCollector)
event.register("trapDisarm", statsCollector)