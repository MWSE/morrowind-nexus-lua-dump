-- Alcohol — game-hour based decay using timer.start (MWSE timer module)
-- Place as: Data Files\MWSE\mods\alcohol_detection\main.lua

local MOD_TAG = "[alcohol_simple_global] "

local config = {
    debug = true,                -- false wenn stabil
    decayPerHour = 1,            -- normaler Abbau pro Spielstunde
    decayPerHourSleeping = 2,    -- Abbau pro Spielstunde beim Schlafen (doppelt)
    maxLevel = 24,               -- Clamp
    manual = {
        -- overrides: ["potion_local_brew_01"] = 2,
    },
    thresholds = {
        { limit = 10, spell = "AL_Drunk_5", name = "extremely wasted", message = "You are extremely wasted." },
        { limit = 7,  spell = "AL_Drunk_4", name = "wasted",            message = "You are wasted." },
        { limit = 5,  spell = "AL_Drunk_3", name = "very drunk",        message = "You are very drunk." },
        { limit = 3,  spell = "AL_Drunk_2", name = "drunk",             message = "You are drunk." },
        { limit = 1,  spell = "AL_Drunk_1", name = "tipsy",             message = "You feel tipsy." },
    },
    drunkSpellList = { "AL_Drunk_1", "AL_Drunk_2", "AL_Drunk_3", "AL_Drunk_4", "AL_Drunk_5" },
    watchIntervalGameHours = 1,  -- wie viele Spielstunden zwischen Ticks (1 = jede Spielstunde)
}

-- safe logger
local function safeLog(...)
    if not config.debug then return end
    if not mwse or not mwse.log then return end
    local parts = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        parts[#parts+1] = (v == nil) and "nil" or tostring(v)
    end
    pcall(function() mwse.log(MOD_TAG .. table.concat(parts, " ")) end)
end

-- persistent player data
local function getPlayerData()
    if not tes3.player then return { level = 0, transient = true } end
    local root = tes3.player.data
    if not root then
        safeLog("getPlayerData: tes3.player.data missing, using transient")
        return { level = 0, transient = true }
    end
    root.alc_mod = root.alc_mod or {}
    local t = root.alc_mod
    t.level = t.level or 0
    t.previousSpell = t.previousSpell or nil
    t._watcherActive = t._watcherActive or false
    return t
end

-- add/remove spells safely (accepts id or spell object)
local function addSpellSafe(id)
    if not id then return end
    pcall(function()
        local obj = (tes3.getObject and tes3.getObject(id)) or nil
        if obj and obj.objectType == tes3.objectType.spell then
            tes3.addSpell{ reference = tes3.player, spell = obj }
        else
            tes3.addSpell{ reference = tes3.player, spell = id }
        end
    end)
end

local function removeSpellSafe(id)
    if not id then return end
    pcall(function()
        local obj = (tes3.getObject and tes3.getObject(id)) or nil
        if obj and obj.objectType == tes3.objectType.spell then
            tes3.removeSpell{ reference = tes3.player, spell = obj }
        else
            tes3.removeSpell{ reference = tes3.player, spell = id }
        end
    end)
end

-- detection includes 'brew', wine, ale ...
local function looksLikeDrink(id)
    if not id then return false end
    local s = tostring(id):lower()

    -- NEW: explicit blacklist
    if s:find("tea") 
    or s:find("milk") then
        return false
    end

    if s:find("drink")
    or s:find("wine")
    or s:find("ale")
    or s:find("mead")
    or s:find("brandy")
    or s:find("whiskey")
    or s:find("liquor")
    or s:find("beer")
    or s:find("liqueur")
    or s:find("brew") then
        return true
    end

    return false
end

-- multiplier per unit (manual override or value buckets)
local function getMultiplierForId(obj)
    if not obj then return nil end
    local id = tostring(obj.id or obj):lower()
    if config.manual[id] then
        safeLog("getMultiplierForId: manual override for", id, "->", config.manual[id])
        return config.manual[id]
    end
    if not looksLikeDrink(id) then
        safeLog("getMultiplierForId: not a drink:", id)
        return nil
    end
    local val = tonumber(obj.value) or 0
    if val < 100 then return 1 end
    if val < 200 then return 2 end
    if val < 300 then return 3 end
    if val < 400 then return 4 end
    return 5
end

-- thresholds helpers
local function findThresholdEntryForLevel(level)
    if not level or level <= 0 then return nil end
    for _, entry in ipairs(config.thresholds) do
        if level >= entry.limit then return entry end
    end
    return nil
end

local function computeSpellForLevel(level)
    local e = findThresholdEntryForLevel(level)
    return e and e.spell or nil
end

local function computeMessageForLevel(level)
    local e = findThresholdEntryForLevel(level)
    if e and e.message then return e.message end
    if not level or level <= 0 then return "You are sober." end
    return nil
end

-- update spells & message only on actual state change
local function updateSpellsForLevel(pdata)
    if not pdata then return end
    if pdata.level and pdata.level > config.maxLevel then pdata.level = config.maxLevel end

    local newSpell = computeSpellForLevel(pdata.level or 0)
    local prevSpell = pdata.previousSpell

    if newSpell == prevSpell then
        safeLog("updateSpellsForLevel: no change (prev==new):", tostring(prevSpell))
        return
    end

    -- remove all drunk spells first
    for _, s in ipairs(config.drunkSpellList) do
        pcall(function() removeSpellSafe(s) end)
    end

    -- add appropriate spell
    if newSpell then
        safeLog("updateSpellsForLevel: adding", newSpell)
        addSpellSafe(newSpell)
    else
        safeLog("updateSpellsForLevel: now sober")
    end

    -- show english message
    local msg = nil
    if pdata.level and pdata.level > 0 then
        msg = computeMessageForLevel(pdata.level)
    else
        msg = "You are sober."
    end
    if msg then pcall(function() tes3.messageBox(msg) end) end

    pdata.previousSpell = newSpell
end

-- GAME-HOUR WATCHER: tick in Spielstunden (verwende timer.start with type = timer.game)
local function startGameHourWatcher(pdata)
    if not pdata then return end
    if pdata._watcherActive then
        safeLog("startGameHourWatcher: watcher already active")
        return
    end

    safeLog("startGameHourWatcher: starting (game-hour ticks)")

    local function tick()
        -- Safety: player exists
        if not tes3.player then
            pdata._watcherActive = false
            safeLog("gameWatcher: no player, stopping")
            return
        end

        -- determine sleeping state now
        local sleepingNow = false
        pcall(function() sleepingNow = (tes3.mobilePlayer and tes3.mobilePlayer.sleeping) and true or false end)
        local perHour = sleepingNow and config.decayPerHourSleeping or config.decayPerHour

        -- subtract perHour (ein Tick repräsentiert eine Spielstunde)
        pdata.level = (pdata.level or 0) - perHour
        if pdata.level < 0 then pdata.level = 0 end

        safeLog(("gameWatcher.tick: sleeping=%s ; perHour=%s ; level now=%.4f")
            :format(tostring(sleepingNow), tostring(perHour), tonumber(pdata.level or 0)))

        -- update status/spells
        updateSpellsForLevel(pdata)

        -- if still >0 schedule next tick in watchIntervalGameHours Spielstunde(n)
        if (pdata.level or 0) > 0 then
            if timer and timer.start then
                timer.start{ duration = config.watchIntervalGameHours, callback = tick, type = timer.game }
            else
                pdata._watcherActive = false
                safeLog("gameWatcher: no timer API, stopping")
            end
        else
            pdata._watcherActive = false
            safeLog("gameWatcher: level is zero, stopping")
        end
    end

    -- Try to start via timer API; only set the persisted flag if we actually scheduled a timer.
    if timer and timer.start then
        pdata._watcherActive = true
        timer.start{ duration = config.watchIntervalGameHours, callback = tick, type = timer.game }
    else
        -- Fallback: sofortiges einmaliges Aufrufen ohne persistentes Flag
        safeLog("startGameHourWatcher: no timer API, running single tick fallback")
        tick()
    end
end

-- apply consumption: add mult * count
local function handleConsumeMany(itemObj, count)
    if not itemObj then
        safeLog("handleConsumeMany: invalid itemObj")
        return false
    end
    count = tonumber(count) or 0
    if count <= 0 then
        safeLog("handleConsumeMany: count <=0")
        return false
    end

    local per = getMultiplierForId(itemObj)
    if not per then
        safeLog("handleConsumeMany: no multiplier for", tostring(itemObj.id))
        return false
    end

    local add = per * count
    local pdata = getPlayerData()

    -- add sofort
    pdata.level = (pdata.level or 0) + add
    if pdata.level > config.maxLevel then pdata.level = config.maxLevel end

    safeLog(("handleConsumeMany: consumed %d x %s -> +%s level -> now=%.4f")
        :format(count, tostring(itemObj.id), tostring(add), tonumber(pdata.level or 0)))

    updateSpellsForLevel(pdata)

    -- start watcher wenn nötig
    if (pdata.level or 0) > 0 then
        startGameHourWatcher(pdata)
    end

    return true
end

-- get item count safely (0 on error)
local function getItemCountSafe(reference, obj)
    local ok, count = pcall(function()
        if not reference or not obj then return 0 end
        return tes3.getItemCount{ reference = reference, item = obj }
    end)
    if ok and count then return count end
    return 0
end

-- TOOLTIP: ursprüngliche einfache Implementation (wie im ersten Script)
local function uiObjectTooltip(e)
    pcall(function()
        if not e or not e.object or not e.tooltip then return end
        local obj = e.object
        if obj.objectType ~= tes3.objectType.alchemy then return end
        local mult = getMultiplierForId(obj)
        if not mult then return end

        safeLog("uiObjectTooltip: for", tostring(obj.id), "-> multiplier", tostring(mult))

        local block = e.tooltip:createBlock()
        block.minWidth = 1
        block.maxWidth = 230
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = 6
        local label = block:createLabel{ text = (mult <= 1 and "Cheap Alcohol" or mult == 2 and "Alcohol" or mult == 3 and "Alcohol" or mult == 4 and "Strong Alcohol" or "Strong Alcohol") }
        label.wrapText = true
    end)
end

-- IMMEDIATE CONSUME on equip (equip event fires before item is equipped)
local function onEquip(e)
    local ok, err = pcall(function()
        if not e or not e.reference or not e.item then
            safeLog("onEquip: invalid event payload")
            return
        end
        if e.reference ~= tes3.player then return end

        local obj = e.item
        if not obj or obj.objectType ~= tes3.objectType.alchemy then
            safeLog("onEquip: not alchemy, skip:", tostring(obj and obj.id))
            return
        end

        -- apply consume wenn Alkohol
        if getMultiplierForId(obj) then
            safeLog("onEquip: immediate consume of 1 unit for", tostring(obj.id))
            handleConsumeMany(obj, 1)
        else
            safeLog("onEquip: item not alcohol (no multiplier):", tostring(obj.id))
        end
    end)
    if not ok then safeLog("Error in onEquip:", tostring(err)) end
end

-- allow manual console commands und debug
local function registerConsoleCommands()
    if not (mwse and mwse.registerCommand) then return end

    mwse.registerCommand("alcohol_level", function()
        local p = getPlayerData()
        local lvl = tonumber(p.level or 0) or 0
        local msg = ("Alcohol level: %.2f"):format(lvl)
        safeLog("console: " .. msg)
        tes3.messageBox(msg)
    end)

    mwse.registerCommand("alcohol_add", function(val)
        local n = tonumber(val) or 1
        local p = getPlayerData()
        p.level = (p.level or 0) + n
        if p.level > config.maxLevel then p.level = config.maxLevel end
        updateSpellsForLevel(p)
        startGameHourWatcher(p)
        tes3.messageBox(("Added %.2f alcohol"):format(n))
    end)

    mwse.registerCommand("alcohol_set", function(val)
        local n = tonumber(val) or 0
        local p = getPlayerData()
        p.level = n
        if p.level > config.maxLevel then p.level = config.maxLevel end
        updateSpellsForLevel(p)
        if (p.level or 0) > 0 then startGameHourWatcher(p) end
        tes3.messageBox(("Set alcohol to %.2f"):format(n))
    end)
end

-- on loaded: wenn Alkohol gespeichert >0 -> Watcher starten
local function onLoaded(e)
    safeLog("onLoaded: checking alcohol level")
    local pdata = getPlayerData()

    -- Wichtig: reset the persisted flag so startGameHourWatcher can actually start a fresh watcher.
    pdata._watcherActive = false

    if (pdata.level or 0) > 0 then
        safeLog("onLoaded: alcohol level > 0, starting watcher")
        startGameHourWatcher(pdata)
    end
end

-- helper: handle "drink multiple" via console or external calls (obj or id)
local function drinkMultipleById(id, count)
    if not id then return false end
    local obj = nil
    pcall(function() obj = tes3.getObject(id) end)
    if not obj then
        safeLog("drinkMultipleById: unknown id", tostring(id))
        return false
    end
    return handleConsumeMany(obj, count or 1)
end

-- Init / events registration
local function onInitialized()
    safeLog("alcohol_simple_global: initialized")
    -- register events using tes3.event constants
    event.register(tes3.event.loaded, onLoaded)
    event.register(tes3.event.equip, onEquip)
    event.register(tes3.event.uiObjectTooltip, uiObjectTooltip)
    registerConsoleCommands()
end

event.register(tes3.event.initialized, onInitialized)

-- exported utilities (optional)
return {
    handleConsumeMany = handleConsumeMany,
    getPlayerData = getPlayerData,
    drinkMultipleById = drinkMultipleById,
}
