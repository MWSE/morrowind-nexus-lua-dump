local Activation = require("openmw.interfaces").Activation
local Interfaces = require("openmw.interfaces")
local storage = require("openmw.storage")
local types = require("openmw.types")
local world = require("openmw.world")

local SECONDS_PER_DAY = 24 * 60 * 60
local MIN_DELAY_DAYS = 0
local DEFAULT_DELAY_DAYS = 2
local STATE_VERSION = 1
local SETTINGS_SECTION_KEY = "RestockReimplSettings"
local SETTINGS_PAGE_KEY = "Restock"
local SETTING_DELAY_DAYS = "RESTOCK_DELAY_DAYS"
local SETTING_EMERGENCY_RESET = "EMERGENCY_RESET_ARMED"

local state = nil
local updateAccumulator = 0
local lastActivationErrorGameTime = -1
local lastMerchantSeen = nil
local settingsSection = storage.globalSection(SETTINGS_SECTION_KEY)

Interfaces.Settings.registerGroup({
    key = SETTINGS_SECTION_KEY,
    page = SETTINGS_PAGE_KEY,
    l10n = "Restock",
    name = "Restock",
    description = "Reset all settings to default",
    permanentStorage = true,
    settings = {
        {
            key = SETTING_DELAY_DAYS,
            name = "Restock Delay (Days)",
            description = "Delay before restocking items return.",
            default = DEFAULT_DELAY_DAYS,
            renderer = "number",
            min = MIN_DELAY_DAYS,
        },
        {
            key = SETTING_EMERGENCY_RESET,
            name = "OH SHIT BUTTON",
            description = "Emergency reset for merchants. This button restores all merchants inventories to their original state.",
            default = false,
            renderer = "checkbox",
        },
    },
})

local function makeDefaultState()
    return {
        version = STATE_VERSION,
        installed = false,
        installedAtDay = 0,
        delayDays = DEFAULT_DELAY_DAYS,
        merchants = {},
        lastEmergencyResetDay = nil,
    }
end

local function clampDelayDays(value)
    local n = tonumber(value) or DEFAULT_DELAY_DAYS
    return math.max(MIN_DELAY_DAYS, n)
end

local function syncDelayFromSettings()
    local configured = settingsSection:get(SETTING_DELAY_DAYS)
    local clamped = clampDelayDays(configured)
    state.delayDays = clamped
end

local function ensureState()
    if state == nil then
        state = makeDefaultState()
    end
    if state.version ~= STATE_VERSION then
        state.version = STATE_VERSION
    end
    if type(state.merchants) ~= "table" then
        state.merchants = {}
    end
    syncDelayFromSettings()
end

local function tableSize(t)
    local count = 0
    for _ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

local function hasEntries(t)
    return type(t) == "table" and next(t) ~= nil
end

local function gameDayNow()
    return world.getGameTime() / SECONDS_PER_DAY
end

local function notifyPlayers(message)
    for _, player in ipairs(world.players) do
        player:sendEvent("RestockReimpl_ShowMessage", message)
    end
end

local function isMerchantActor(actor)
    if not actor or not actor:isValid() then
        return false
    end
    if actor.type ~= types.NPC and actor.type ~= types.Creature then
        return false
    end
    if types.Actor.isDead(actor) then
        return false
    end

    local ok, record = pcall(function()
        if actor.type == types.NPC then
            return types.NPC.record(actor)
        end
        return types.Creature.record(actor)
    end)

    if not ok or not record then
        return false
    end
    return record.servicesOffered ~= nil and record.servicesOffered.Barter == true
end

local function getInventory(actor)
    local inventory = types.Actor.inventory(actor)
    pcall(function()
        if not inventory:isResolved() then
            inventory:resolve()
        end
    end)
    return inventory
end

local function getMerchantInventories(actor)
    local inventories = {}
    local primaryInventory = getInventory(actor)
    inventories[#inventories + 1] = primaryInventory

    if actor.cell then
        local ok, containers = pcall(function()
            return actor.cell:getAll(types.Container)
        end)
        if ok and containers then
            for _, container in ipairs(containers) do
                local owner = container.owner and container.owner.recordId or nil
                if owner and owner == actor.recordId then
                    local containerInventory = types.Container.inventory(container)
                    pcall(function()
                        if not containerInventory:isResolved() then
                            containerInventory:resolve()
                        end
                    end)
                    inventories[#inventories + 1] = containerInventory
                end
            end
        end
    end

    return inventories, primaryInventory
end

local function collectCounts(inventories)
    local counts = {}
    for _, inventory in ipairs(inventories) do
        for _, item in ipairs(inventory:getAll()) do
            local count = item.count or 0
            if count > 0 then
                counts[item.recordId] = (counts[item.recordId] or 0) + count
            end
        end
    end
    return counts
end

local function convertRestockingStacksToStatic(inventories)
    local restockBaseline = {}
    local toConvert = {}

    for _, inventory in ipairs(inventories) do
        for _, item in ipairs(inventory:getAll()) do
            local count = item.count or 0
            if count > 0 and types.Item.isRestocking(item) then
                restockBaseline[item.recordId] = (restockBaseline[item.recordId] or 0) + count
                table.insert(toConvert, {
                    object = item,
                    inventory = inventory,
                    recordId = item.recordId,
                    count = count,
                })
            end
        end
    end

    for _, entry in ipairs(toConvert) do
        if entry.object:isValid() then
            entry.object:remove()
        end
        if entry.count > 0 then
            world.createObject(entry.recordId, entry.count):moveInto(entry.inventory)
        end
    end

    return restockBaseline
end

local function snapshotMerchant(actor)
    local inventories = getMerchantInventories(actor)
    local baselineAll = collectCounts(inventories)
    local restockBaseline = convertRestockingStacksToStatic(inventories)

    local entry = {
        recordId = actor.recordId,
        baselineAll = baselineAll,
        restockBaseline = restockBaseline,
        lastRestockDay = gameDayNow(),
    }

    state.merchants[actor.id] = entry
    return entry
end

local function ensureMerchantEntry(actor)
    local entry = state.merchants[actor.id]
    if entry then
        local inventories = getMerchantInventories(actor)
        local liveRestocking = convertRestockingStacksToStatic(inventories)

        entry.baselineAll = entry.baselineAll or collectCounts(inventories)
        entry.restockBaseline = entry.restockBaseline or {}

        for recordId, count in pairs(liveRestocking) do
            if count > (entry.restockBaseline[recordId] or 0) then
                entry.restockBaseline[recordId] = count
            end
        end

        if not entry.lastRestockDay then
            entry.lastRestockDay = gameDayNow()
        end
        return entry
    end

    return snapshotMerchant(actor)
end

local function removeItemCount(inventories, recordId, countToRemove)
    if countToRemove <= 0 then
        return 0
    end

    local removed = 0
    for _, inventory in ipairs(inventories) do
        local stacks = {}
        for _, stack in ipairs(inventory:findAll(recordId)) do
            table.insert(stacks, stack)
        end

        for _, stack in ipairs(stacks) do
            if countToRemove <= 0 then
                break
            end
            if stack:isValid() then
                local canRemove = math.min(stack.count or 0, countToRemove)
                if canRemove > 0 then
                    stack:remove(canRemove)
                    countToRemove = countToRemove - canRemove
                    removed = removed + canRemove
                end
            end
        end

        if countToRemove <= 0 then
            break
        end
    end

    return removed
end

local function countOf(inventories, recordId)
    local total = 0
    for _, inventory in ipairs(inventories) do
        total = total + (inventory:countOf(recordId) or 0)
    end
    return total
end

local function resetMerchantToBaseline(actor, entry)
    if not entry or not hasEntries(entry.baselineAll) then
        return false, 0
    end

    local inventories, primaryInventory = getMerchantInventories(actor)
    local changedItems = 0
    local current = collectCounts(inventories)

    for recordId, currentCount in pairs(current) do
        local targetCount = entry.baselineAll[recordId] or 0
        if currentCount > targetCount then
            changedItems = changedItems + removeItemCount(inventories, recordId, currentCount - targetCount)
        end
    end

    for recordId, targetCount in pairs(entry.baselineAll) do
        local currentCount = countOf(inventories, recordId)
        if currentCount < targetCount then
            local missing = targetCount - currentCount
            world.createObject(recordId, missing):moveInto(primaryInventory)
            changedItems = changedItems + missing
        end
    end

    convertRestockingStacksToStatic(inventories)
    entry.lastRestockDay = gameDayNow()
    return changedItems > 0, changedItems
end

local function runDelayedRestock(actor, entry)
    if not entry or not hasEntries(entry.restockBaseline) then
        return false, 0
    end

    local now = gameDayNow()
    local last = entry.lastRestockDay or now

    if now < last then
        entry.lastRestockDay = now
        return false, 0
    end
    if now - last < state.delayDays then
        return false, 0
    end

    local inventories, primaryInventory = getMerchantInventories(actor)
    local added = 0

    for recordId, targetCount in pairs(entry.restockBaseline) do
        local currentCount = countOf(inventories, recordId)
        if currentCount < targetCount then
            local missing = targetCount - currentCount
            world.createObject(recordId, missing):moveInto(primaryInventory)
            added = added + missing
        end
    end

    entry.lastRestockDay = now
    return added > 0, added
end

local function iterateMerchants(callback)
    local seen = {}
    for _, cell in ipairs(world.cells) do
        local okNpc, npcs = pcall(function()
            return cell:getAll(types.NPC)
        end)
        if okNpc and npcs then
            for _, npc in ipairs(npcs) do
                if isMerchantActor(npc) and not seen[npc.id] then
                    seen[npc.id] = true
                    callback(npc)
                end
            end
        end

        local okCreature, creatures = pcall(function()
            return cell:getAll(types.Creature)
        end)
        if okCreature and creatures then
            for _, creature in ipairs(creatures) do
                if isMerchantActor(creature) and not seen[creature.id] then
                    seen[creature.id] = true
                    callback(creature)
                end
            end
        end
    end
end

local function buildInstallBaseline()
    state.installed = true
    state.installedAtDay = gameDayNow()

    notifyPlayers(
        string.format(
            "Restock: initialized. Merchants are captured lazily when first interacted with. Currently tracked: %d.",
            tableSize(state.merchants)
        )
    )
end

local function emergencyResetAllMerchants()
    ensureState()
    notifyPlayers("Restock: emergency reset started. This can take a while.")

    local tracked = tableSize(state.merchants)
    local visited = 0
    local rebuilt = 0
    local adjustedItems = 0

    iterateMerchants(function(actor)
        local entry = state.merchants[actor.id]
        if not entry then
            return
        end

        visited = visited + 1

        local changed, delta = resetMerchantToBaseline(actor, entry)
        if changed then
            rebuilt = rebuilt + 1
            adjustedItems = adjustedItems + delta
        end
    end)

    state.lastEmergencyResetDay = gameDayNow()

    notifyPlayers(
        string.format(
            "Restock: emergency reset done. Tracked merchants: %d, loaded+visited: %d, rebuilt: %d, item adjustments: %d.",
            tracked,
            visited,
            rebuilt,
            adjustedItems
        )
    )
end

local function setDelayDays(value)
    ensureState()

    local n = tonumber(value)
    if n == nil then
        notifyPlayers("Restock: invalid delay value. Use any number >= 0.")
        return
    end

    n = clampDelayDays(n)
    settingsSection:set(SETTING_DELAY_DAYS, n)
    state.delayDays = n
    notifyPlayers(string.format("Restock: restock delay is now %.2f in-game day(s).", n))
end

local function showStatus()
    ensureState()
    notifyPlayers(
        string.format(
            "Restock: delay=%.2f day(s), trackedMerchants=%d, installedAtDay=%.2f.",
            state.delayDays,
            tableSize(state.merchants),
            state.installedAtDay or 0
        )
    )
end

local function consumeEmergencyResetSetting()
    if settingsSection:get(SETTING_EMERGENCY_RESET) then
        settingsSection:set(SETTING_EMERGENCY_RESET, false)
        emergencyResetAllMerchants()
    end
end

local function processMerchantRestock(merchant, errorLabel)
    if not merchant or not merchant:isValid() then
        return
    end
    if not isMerchantActor(merchant) then
        return
    end

    lastMerchantSeen = merchant

    local ok, err = pcall(function()
        ensureState()
        consumeEmergencyResetSetting()
        local entry = ensureMerchantEntry(merchant)
        runDelayedRestock(merchant, entry)
    end)

    if not ok then
        local now = world.getGameTime()
        if lastActivationErrorGameTime < 0 or math.abs(now - lastActivationErrorGameTime) > 10 then
            lastActivationErrorGameTime = now
            notifyPlayers("Restock: runtime error in merchant hook; skipping restock for this interaction.")
            print(string.format("Restock %s error: %s", errorLabel or "runtime", tostring(err)))
        end
    end
end

local function onMerchantActivated(merchant, actor)
    if actor.type ~= types.Player then
        return
    end
    processMerchantRestock(merchant, "activation")
end

local function onUiModeChanged(data)
    if type(data) ~= "table" then
        return
    end

    if data.oldMode ~= "Barter" and data.newMode ~= "Barter" then
        return
    end

    local merchant = data.merchant
    if (not merchant or not merchant:isValid()) and lastMerchantSeen and lastMerchantSeen:isValid() then
        merchant = lastMerchantSeen
    end

    processMerchantRestock(merchant, "ui-mode")
end

local function onInit()
    ensureState()
    consumeEmergencyResetSetting()
end

local function onLoad(data)
    if type(data) == "table" and data.version == STATE_VERSION then
        state = data
    end

    ensureState()
    consumeEmergencyResetSetting()

    if not state.installed then
        buildInstallBaseline()
    end
end

local function onUpdate(dt)
    ensureState()
    updateAccumulator = updateAccumulator + (dt or 0)
    if updateAccumulator >= 1.0 then
        updateAccumulator = 0
        consumeEmergencyResetSetting()
    end
end

local function onSave()
    ensureState()
    return state
end

Activation.addHandlerForType(types.NPC, onMerchantActivated)
Activation.addHandlerForType(types.Creature, onMerchantActivated)

return {
    interfaceName = "Restock",
    interface = {
        emergencyReset = emergencyResetAllMerchants,
        setDelayDays = setDelayDays,
        showStatus = showStatus,
    },
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onUpdate = onUpdate,
        onSave = onSave,
    },
    eventHandlers = {
        RestockReimpl_EmergencyReset = emergencyResetAllMerchants,
        RestockReimpl_SetDelayDays = setDelayDays,
        RestockReimpl_ShowStatus = showStatus,
        RestockReimpl_OnUiModeChanged = onUiModeChanged,
    },
}
