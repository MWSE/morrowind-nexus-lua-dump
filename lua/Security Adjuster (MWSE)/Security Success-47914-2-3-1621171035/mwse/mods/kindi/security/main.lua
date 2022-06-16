--[[v2.3]]
local data = require("kindi.security.data")
local config
local objtip

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

local function NewTooltipBlock(tooltip, ts, ts1, effects)
    local block = tooltip:createBlock {}
    block.minWidth = 1
    block.maxWidth = 200
    block.autoWidth = true
    block.autoHeight = true
	block.paddingRight = 5
    block.paddingTop = 1
    block.paddingBottom = 3
	block.flowDirection = "top_to_bottom"
	local divider = block:createDivider{}
    local label = block:createLabel {text = string.format("%s%s", ts, ts1)}
    label.justifyText = "center"
    label.wrapText = true

	if effects then
		local divider2 = block:createDivider{}
	local label2 = block:createLabel {text = effects}
	label2.wrapText = true
	label2.justifyText = "center"
	end
end

local function ShowTheChance(tooltip, pickChance, disarmChance, isLocked, needKey, Tar, trappoints)
    local ts
    local ts1
    if isequippingLockpick and isLocked then
        if not needKey then
            ts1 = string.format("\nKey: %s", "No key")
        else
            ts1 = string.format("\nKey: %s", Tar.reference.lockNode.key.name)
        end
        ts = string.format("Unlock Chance: %.2f", pickChance)

        if config.showExtra == false then
            ts1 = ""
        end
        NewTooltipBlock(tooltip, ts, ts1)
    elseif isequippingProbe and Tar.reference.lockNode.trap then
		local effects = ""
		local trap = Tar.reference.lockNode.trap
		for i = 1, #trap.effects do
		if trap.effects[i].id >= 0 then
		effects = effects..string.format("%s %s to %s pts for %s secs in %s ft on %s", tes3.findGMST(1283 + trap.effects[i].id).value, trap.effects[i].min, trap.effects[i].max, trap.effects[i].duration, trap.effects[i].radius, tes3.findGMST(1442 + trap.effects[i].rangeType).value)
		if i > 1 then
		effects = effects.."\n"
		end
		end
		end


        local ts = string.format("Disarm Chance: %.2f", disarmChance)
        local ts1 = string.format("\nTrap: %s - %s points", Tar.reference.lockNode.trap.name, trappoints)
        if config.showExtra == false then
            ts1 = ""
			effects = nil
        end
        NewTooltipBlock(tooltip, ts, ts1, effects)
    end
end

local function DoyouKnowHowToPickALock(Tar)
    if config.showInfo == false then
        return
    end
    local lockortrap = Tar.reference
    local pickChance = 0
    local needKey = false
    local isLocked = false
    local isTrapped = false
    local tooltip = Tar.tooltip
    objtip = Tar.tooltip
    --[[only interested in locked objects or trapped objects]]
    if lockortrap == nil or lockortrap.lockNode == nil then
        return
    end

    if
        --[[assuming only containers and doors can be locked or trapped]]
        tes3.player.mobile.readiedWeapon ~= nil and
            (lockortrap.object.objectType == tes3.objectType.container or
                lockortrap.object.objectType == tes3.objectType.door)
     then
        isequippingLockpick = (tes3.player.mobile.readiedWeapon.object.objectType == tes3.objectType.lockpick)
        isequippingProbe = (tes3.player.mobile.readiedWeapon.object.objectType == tes3.objectType.probe)
    else
        return
    end

    --[[is the object locked?]]
    if lockortrap.lockNode.locked == false then
        isLocked = false
    else
        isLocked = true
    end
    --[[is the object trapped?]]
    if tes3.getTrap {reference = lockortrap} == nil then
        isTrapped = false
    else
        isTrapped = true
    end
    --[[does it need a key?]]
    if lockortrap.lockNode.key then
        needKey = true
    else
        needKey = false
    end

    --[[calculation for lockpicking and disarming]]
    if isequippingLockpick and isLocked then
        if tes3.getLockLevel {reference = lockortrap} ~= nil and tes3.getLockLevel {reference = lockortrap} > 0 then
            pickChance =
                math.max(
                0,
                ((0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
                    tes3.mobilePlayer.security.current) *
                    tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.lockpick}).object.quality *
                    (tes3.findGMST(tes3.gmst.fFatigueBase).value -
                        tes3.findGMST(tes3.gmst.fFatigueMult).value *
                            (1 - tes3.mobilePlayer.fatigue.current / tes3.mobilePlayer.fatigue.base)) +
                    tes3.findGMST(tes3.gmst.fPickLockMult).value * tes3.getLockLevel {reference = lockortrap}
            )
        else
            --[[if there is no lock or the lock level is 0]]
            pickChance = 0
        end
    elseif isequippingProbe and isTrapped then
        trappoints = tes3.getTrap {reference = lockortrap}.magickaCost
        disarmChance =
            math.max(
            0,
            (((0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
                tes3.mobilePlayer.security.current) +
                (tes3.findGMST(tes3.gmst.fTrapCostMult).value * tes3.getTrap {reference = lockortrap}.magickaCost)) *
                tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.probe}).object.quality *
                (tes3.findGMST(tes3.gmst.fFatigueBase).value -
                    tes3.findGMST(tes3.gmst.fFatigueMult).value *
                        (1 - tes3.mobilePlayer.fatigue.current / tes3.mobilePlayer.fatigue.base))
        )
    end
    ShowTheChance(tooltip, pickChance, disarmChance, isLocked, needKey, Tar, trappoints)
end

--[[gmst resets to default every game session, we restore it here]]
local function updategmst()
    tes3.findGMST(1081).value = tonumber(config.fpicklockmult)
    tes3.findGMST(1082).value = tonumber(config.ftrapcostmult)
end

local function loadData(loaded)
    local fileName = loaded.filename

    local toLoadData = mwse.loadConfig("ss_kindi_data") or {}
    data =
        toLoadData[fileName] or
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

local function saveData(saved)
    local fileName = string.sub(saved.filename, 0, -5)

    local toSaveData = data

    local currentData = mwse.loadConfig("ss_kindi_data") or {}
    currentData[fileName] = toSaveData
    mwse.saveConfig("ss_kindi_data", currentData)
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
    des =
        header ..
        a .. b .. c .. d .. f .. e .. s .. "\n----------------------------------------------\n\n"

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

local function fresh()
    if objtip then
        tes3ui.refreshTooltip(objtip)
    end
end

event.register("simulate", fresh)
event.register("menuEnter", statRecord)
event.register("saved", saveData)
event.register("loaded", loadData)
event.register("initialized", updategmst)
event.register("lockPick", statsCollector)
event.register("trapDisarm", statsCollector)
event.register("uiObjectTooltip", DoyouKnowHowToPickALock)
event.register(
    "modConfigReady",
    function()
        require("kindi.security.mcm")
        config = require("kindi.security.config")
    end
)
