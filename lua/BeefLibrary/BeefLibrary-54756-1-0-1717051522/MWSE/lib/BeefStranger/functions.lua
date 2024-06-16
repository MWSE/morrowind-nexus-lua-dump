local functions = {}
local logger = require("logging.logger")
local log = logger.new { name = "bsFunctions", logLevel = "NONE", logToConsole = true, }

functions.effect = require("BeefStranger.effectMaker") 
functions.sound = require("BeefStranger.sounds")
functions.bsSound = require("BeefStranger.sounds").bsSound
-- functions.playSound = require("BeefStranger.playSound")
functions.spell = require("BeefStranger.spellMaker")
functions.config = require("BeefStranger.config")

--Auto Register Sounsd
-- functions.sound.register()


----------------------------------------------------------------------------------------------------
---`Require Folder`
----------------------------------------------------------------------------------------------------
function functions.importDir(modPath)
    local basePath = "Data Files/mwse/mods/"
    local filepath = basePath..modPath:gsub("%.", "/") .. "/"

    log:debug("filePath %s", filepath)

    local success, err = pcall(function()
        log:debug("filePath %s", filepath)
        for file in lfs.dir(filepath) do
            local fileName = file:match("(.+)%.lua$")
            if fileName then
                log:debug(modPath .. "." .. fileName)
                package.loaded[modPath .. "." .. fileName] = nil  -- Clear the cached module
                require(modPath .. "." .. fileName)
            end
        end
    end)

    if not success then
        mwse.log("[bsF | importDir]: Error - %s", err)
    end

end

----------------------------------------------------------------------------------------------------
---`Functions Logging`
----------------------------------------------------------------------------------------------------
---This just sets the log level for functions to debug, and logs to the console
---@param toggle boolean Toggles debug for functions
function functions.debug(toggle)
    if toggle then
        log:setLogLevel("DEBUG")
        log:debug("Debug Enabled")
    else
        log:setLogLevel("ERROR")
    end
end
----------------------------------------------------------------------------------------------------
---`createLog`
----------------------------------------------------------------------------------------------------
--- Logger functions type
--- @class Logger
--- @field trace fun(...: any)
--- @field debug fun(...: any)
--- @field info fun(...: any)
--- @field warn fun(...: any)
--- @field error fun(...: any)
--- @field log string|mwseLogger
--- @field setLogLevel fun(level: mwseLoggerLogLevel)
---------------------------------------------------------------------------
---@param name string Name of the logger
---@param level mwseLoggerLogLevel? logLevel : Defaults to "DEBUG"
---@param ...? mwseLoggerInputData
---@return mwseLogger logging
---Usage:
--
---     local log = functions.createLog("MyLogName", "TRACE")
---`    This creates a log with the name of "MyLogName" with a logLevel of "TRACE"`
--
---`Log Levels:`
function functions.createLog(name, level, ...)
    local cLogger = require("logging.logger")
    level = level or "NONE"
    -- if not level then level = "DEBUG" end
    local logging = cLogger.new{ name = name, logLevel = level, logToConsole = false, ...}
    mwse.log("[bsF | createLog]: %s", logging.name)
    return logging
end
----------------------------------------------------------------------------------------------------
---`getLog`
----------------------------------------------------------------------------------------------------
---@param name string Name of the logger to load
---@return Logger|any; A table with logging functions (`log`, `debug`, `info`, `warn`, `trace`).
---Usage:
--- ```lua
---     local log = getLog("MyLogName")
---     local trace, debug, info = log.trace, log.debug, log.info
---     
---     log.trace("This is a trace message")
---     trace("This is a trace message")
---     debug("This is a debug message")
---     info("This is an info message")
---     log.warn("This is a warning message")
---     log.error("This is an error message")
--- ```
function functions.getLog(name)
    local gLogger = require("logging.logger")

    package.loaded["logging.logger"] = nil -- Clear the cached module

    local logging = gLogger.getLogger(name) or functions.createLog(name)
    if not logging then
        mwse.log("[bsF | getLog]: Logging not found")
        return
    else
        mwse.log("[bsF | getLog]: %s Found", logging.name)
    end

    return{
        --- Logs a trace message
        --- @param ... any: The message to log
        trace = function (...) logging:trace(...) end,
        debug = function (...) logging:debug(...) end,
        info = function (...) logging:info(...) end,
        warn = function (...) logging:warn(...) end,
        error = function (...) logging:error(...) end,
        setLogLevel = function(level) logging:setLogLevel(level) end,
        log = logging,
    }
end

-- function functions.getinfo()
--     local bsF = debug.getinfo(1, "nSl")
--     local bsC = debug.getinfo(2, "nSl")
--     -- return {
--     --     fName = bsF.name,
--     --     cName = bsC.name,
--     --     source = bsC.short_src,
--     --     line = bsC.currentline
--     -- }
--     return bsF, bsC
-- end


----------------------------------------------------------------------------------------------------
---`inspect` !Testing!
----------------------------------------------------------------------------------------------------
---@param table table The table you want to inspect
---Usage:
--- ```lua
---     bs.inspect(myTable)
---```
---`Returns a debug message of the table`
function functions.inspect(table)
    local inspect = require("inspect").inspect

    ----Just discovered debug.getinfo, testing

    -- local info = debug.getinfo(1, "n") --- 0 - getinfo, 1 - inspect, 2 - nil, 3 - xpcall
    -- mwse.log("[inspect info ---- %s]", info.)

    -- mwse.log("[0 - %s, 1 - %s, 2- %s, 3 - %s]", debug.getinfo(0, "n").name,debug.getinfo(1, "n").name,debug.getinfo(2, "n").name,debug.getinfo(3, "n").name)
    
    local bsF = debug.getinfo(1, "nSl")
    local bsC = debug.getinfo(2, "nSl")

    -- local name = bsF.name or "unknown"
    -- local source = bsC.short_src or "unknown"
    -- local line = bsC.currentline or "unknown"

    -- local bsF = debug.getinfo(1, "nSl")
    -- local bsC = debug.getinfo(2, "nSl")
    mwse.log("[ ---------------------------- |bsF | %s| ---------------------------- ]", bsF.name)
    mwse.log("[Source: %s, Line: %d]", bsC.short_src, bsC.currentline)
    mwse.log("%s", inspect(table))
    -- mwse.log("[bsF | inspect] - %s", inspect(table))
end
----------------------------------------------------------------------------------------------------
---`logC`
----------------------------------------------------------------------------------------------------
---Logs to console only, wont log the mwse.log
function functions.logC(...)
    tes3ui.log("[logC]: ".. ...)
end
----------------------------------------------------------------------------------------------------
---`timer`
----------------------------------------------------------------------------------------------------
---@class timer
---@field dur number How long each iteration lasts
---@field iter number? Number of times it'll repeat
---@field cb function|string The function ran when duration is expired
---@param params timer
---@return mwseTimer timerId
--- - `dur` - How long each iteration lasts
--- - `iter` - *Optional* - Number of times it'll repeat
--- - `cb` - The function ran when duration is expired\
---
--Usage:
--
---     functions.timer{dur = 1, iter = 3, cb = function()}
function functions.timer(params)
    assert(type(params.dur) == "number", "Parameter 'dur' must be a number")    --ChatGPT test says this is good practice so im testing it
    assert(type(params.cb) == "function") --[[ or type(params.cb) == "string", "Parameter 'cb' must be a function or a string representing a method call") ]]

    local callback
    --callback = type(params.cb) == "function" and params.cb or "Parameter 'cb' must be valid Lua code")
    if type(params.cb) == "function" then
        callback = params.cb
    else
        error("Parameter 'cb' must be a function")
    end

    local timerId = timer.start{
            duration = params.dur,
            iterations = params.iter or 1,
            callback = callback,
    }
    return timerId
end

----------------------------------------------------------------------------------------------------
---`YesNo`
----------------------------------------------------------------------------------------------------
---@param message string
---@param messageParam any|nil? Use nil if not adding formatting to message
---@param callback fun(e:tes3messageBoxCallbackData)
function functions.yesNo(message, messageParam, callback)
    if messageParam then
        message = string.format(message, messageParam)
    end
    tes3.messageBox{
        message = message,
        buttons = { "Yes", "No" },
        callback = callback
    }
end
----------------------------------------------------------------------------------------------------
---`onTick`
----------------------------------------------------------------------------------------------------
---@param e tes3magicEffectTickEventData The tick event data
---@param action function The function to be inserted into the beginning spell state.
---Sets up all the triggers for an effect. Usually used at the end of the onTick function ex:
---
---     local function onEffectTick(e)
---         local function doThis()
---            this thing
---         end
---        functions.onTick(e, doThis)
---     end
function functions.onTick(e, action)
    assert(type(action) == "function", "Parameter 'action' must be a function")

    if e.effectInstance.state == tes3.spellState.working then
        e:trigger(); return
    elseif e.effectInstance.state == tes3.spellState.beginning then
        e:trigger(); e:trigger()
        action(e)
    elseif e.effectInstance.state == tes3.spellState.ending then
        e.effectInstance.state = tes3.spellState.retired
    end
end
----------------------------------------------------------------------------------------------------
---`effectTimer`
----------------------------------------------------------------------------------------------------
--- Attempt to emulate vanilla effect timer.
---@param e tes3magicEffectTickEventData Used to pass eventData to timer for calculations
---@param callback function The function the timer will run
---Usage:
---
---     bs.effectTimer(e, function ()
---         target.mobile:applyDamage { damage = 1, playerAttack = true }
---     end)
function functions.effectTimer(e, callback)
    assert(type(callback) == "function", "Parameter 'callback' must be a function")
    local effect = #e.sourceInstance.sourceEffects > 0 and e.sourceInstance.sourceEffects[1] ---@type tes3effect
    local duration = effect and math.max(1, effect.duration) or 1
    local mag = e.effectInstance.effectiveMagnitude
    local iter = 0
    log:debug("effectTimer: mag = %s", mag)
    local timerId = timer.start({
        duration = 1 / mag,
        callback = function()
            iter = iter + 1
            log:debug("effectTimer: %s", iter)
            callback()
        end,
        iterations = duration * mag,
    })
    return timerId
end

----------------------------------------------------------------------------------------------------
---`dmgTick`
----------------------------------------------------------------------------------------------------
----Effect Timer to add damage per tick
---@class dmgTick
---@field damage number? Default: to 1 perTick. The amount of damage dealt perTick
---@field applyArmor boolean? Default: false. If armor should mitigate the incoming damage. If the player is the target, armor experience will be gained.
---@field resist tes3.effectAttribute? Optional. The resistance attribute that is applied to the damage. It can reduce damage or exploit weakness
---@field applyDifficulty boolean? Default: false. If the game difficulty modifier should be applied. Must be used with the playerAttack argument to apply the correct modifier.
---@field playerAttack boolean? Optional. If the attack came from the player. Used for difficulty calculation.
---@field doNotChangeHealth boolean? Default: false. If all armor effects except the health change should be applied. These include hit sounds, armor condition damage, and player experience gain from being hit.
---@param e tes3magicEffectTickEventData
---@param params dmgTick
---Usage:
--- 
---     functions.dmgTick(e, {damage = 1})
---
---`Function to quickly add Damage = effectiveMagnitude * duration on timer lasting duration, only really for spells that only damage on tick,`
---`Otherwise use effectTimer`
--
---*`---Parameters---`*
--
--- - `damage` - The Damage applied each tick
--- - `applyArmor` - If armor mitigates
--- - `resist` - The attribute that resists this
--- - `applyDifficulty` - If the difficulty modifier is used
--- - `playerAttack` - If the attack came from the player
--- - `doNotChangeHealth` - If it shouldnt actually damage but still do armor effects
function functions.dmgTick(e, params) 
    assert(type(params) == "table", "Parameter 'params' must be a table")
    if e.effectInstance.state == tes3.spellState.working then e:trigger() return end
    local ref = e.effectInstance.target
    local refHandle = tes3.makeSafeObjectHandle(ref) --Make safe handle
    local timerId
    local iter = 1
    local function timerCallback()
        if refHandle and refHandle:valid() then
            log:debug("timerCallback - %s", iter); iter = iter + 1 --for debugging
            local mobile = refHandle:getObject() and refHandle:getObject().mobile --put safeObject into ref
            if not mobile then log:debug("not mobile") return end
            mobile:applyDamage({
                damage = params.damage or 1,
                applyArmor = params.applyArmor or false,
                resistAttribute = params.resist,
                applyDifficulty = params.applyDifficulty,
                playerAttack = params.playerAttack or true,
                doNotChangeHealth = params.doNotChangeHealth
            })

            if mobile.health.current <= 0 then
                timerId:cancel()
                log:debug("target dead cancel timer setState to ending")
                e.effectInstance.state = tes3.spellState.ending --ending
            end
        end
    end

    if e.effectInstance.state == tes3.spellState.beginning then
        e:trigger() e:trigger()
        local mag = e.effectInstance.effectiveMagnitude
        timerId = functions.effectTimer(e, timerCallback)
        log:debug("mag = %s", mag)
        e.effectInstance.state = tes3.spellState.working
    end

    if e.effectInstance.state == tes3.spellState.ending then
        e.effectInstance.state = tes3.spellState.retired
        log:debug("ending")
    end
end

----------------------------------------------------------------------------------------------------
---`getEffect`
----------------------------------------------------------------------------------------------------
--Took from OperatorJack--
---@param e tes3magicEffectCollisionEventData|tes3magicEffectTickEventData
---@param effectId tes3.effect
---Usage: 
--
---     local effect = functions.getEffect(e, tes3.effect.light)
---     local effect = functions.getEffect(e, 41) --Same as above but with number
--
--- - `Mainly used for spells you create`
--
-- - `Vanilla ID's | ↓`
function functions.getEffect(e, effectId)
    assert(type(effectId) == "number", "Parameter 'effectId' must be a number")
    for i = 1, 8 do
        local effect = e.sourceInstance.sourceEffects[i]
        if effect ~= nil and effect.id == effectId then
            return effect
        end
    end
    return nil
end

----------------------------------------------------------------------------------------------------
---`duration`
----------------------------------------------------------------------------------------------------
---@param e tes3magicEffectCollisionEventData|tes3magicEffectTickEventData The tick/collision data
---@param effectID tes3.effect The ID of the spell. Either the name or ID`(tes3.effect.light or 41)`
---@return integer duration The duration of the effect, will return 1 if no `duration`
---Usage:
--
---     local duration = functions.duration(e, tes3.effect.light)
--
---`returns duration of spell or 1 if the duration was 0`
--
---Vanilla ID's `↓`
function functions.duration(e, effectID)
    local duration = functions.getEffect(e, effectID) and math.max(1, functions.getEffect(e, effectID).duration) or 1
    return duration
end

----------------------------------------------------------------------------------------------------
---`shuffleInv`
----------------------------------------------------------------------------------------------------
---I didnt make this, its a shuffler made from other examples using the Fisher-Yates algoritm | Which I dont understand
---@param t table<number, tes3itemStack> -- The inventory table to shuffle.
---@return table<number, tes3itemStack> -- The shuffled inventory table.
---Usage:
--
---     for _, stack in pairs(functions.shuffleInv(target.object.inventory)) do
---        log:debug("%s", stack.object.name)
---      end
--- - `This returns a shuffled list of items in the targets inventory`
function functions.shuffleInv(t)
    local rand = math.random
    local invCopy = {}
    -- Copy the original table to tCopy
    for i, v in pairs(t) do
        invCopy[i] = v
    end

    local iterations = #invCopy
    local j
    for i = iterations, 2, -1 do
        j = rand(i)
        invCopy[i], invCopy[j] = invCopy[j], invCopy[i]
    end
    return invCopy
end

----------------------------------------------------------------------------------------------------
---`mergeTables`
----------------------------------------------------------------------------------------------------
function functions.mergeTables(t1, t2)
    local t = {}
    for k, v in pairs(t1) do
        t[k] = v
    end
    for k, v in pairs(t2) do
        t[k] = v
    end
    return t
end

----------------------------------------------------------------------------------------------------
---`onLoad`
----------------------------------------------------------------------------------------------------
---@param func fun()
---@param priority number
---Shorthand for:
---
---     event.register("loaded", function()
---     end)
---
---     bs.onLoad(function()
---     end)
function functions.onLoad(func, priority)
    event.register("loaded", func, {priority = priority})
end

----------------------------------------------------------------------------------------------------
---`rayCast`
----------------------------------------------------------------------------------------------------
---@param maxDistance number RayCast from players eye, returns a reference
---@param toLog boolean?
---@return tes3reference result
---Usage:
--
---     local target = functions.rayCast(900)
--
---`Returns a reference`
--
---`Ignores player`
--
---`maxDistance` is in game units, if you want it in ft like spell radius is divide by 22.1
function functions.rayCast(maxDistance, toLog)
    local result = tes3.rayTest({
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        ignore = {tes3.player},
        maxDistance = maxDistance,
    })

    if toLog and result then
        local ref = result.reference
        log:debug("RayCast: %s - %s : %d", ref.object.name, functions.objectTypeNames[ref.object.objectType], result.distance)
    end

    -- if result and result.reference then --if result is reference return it
    --     return result.reference
    -- else
    --     return nil
    -- end
    return result and result.reference
end

----------------------------------------------------------------------------------------------------
---`typeCheck`
----------------------------------------------------------------------------------------------------
---@param ref tes3reference|tes3itemStack|tes3item  The reference to check the type of. ***`NOTE: This should be the base reference, as object.objectType is tacked on the end`***
---@param objType string|tes3.objectType|number The type to compare to, can be "npc" or tes3.objectType.npc, or even 1598246990
---@param info? boolean Add true as last param to log objectType to console, used with functions.debug(true)
---Usage:
--
---     local target = functions.rayCast(900)
---     
---     if functions.typeCheck(target, "npc") then
---         tes3.messageBox("Target is NPC")
---     end
function functions.typeCheck(ref, objType, info)
    local objectType = objType
    if type(objType) == "string" then objectType = tes3.objectType[objType] end --Conert string to ObjectType Value

    local refType
    if type(ref) == "number" then
        refType = ref
    elseif type(ref.object) == "userdata" then
        refType = ref.object.objectType
    elseif type(ref.objectType) == "number" then
        refType = ref.objectType
    else
        error("Invalid ref passed to typeCheck", 1)
    end

    if info == true then 
        log:debug("%s | objectType = %s", ref.object and ref.object.name or "BaseRef not passed", functions.objectTypeNames[refType]) 
    end

    return refType == objectType

    -- if (ref.object.objectType == objectType) then
    --     return true
    -- else
    --     return false
    -- end
end

----------------------------------------------------------------------------------------------------
---`linearInter` 
----------------------------------------------------------------------------------------------------
-- local m = -9/150 -- slope m represents how much the base cost changes for each increase in the number of undead kills/Where undead kills maxes out
-- local c = 10 -- the max when above is negative? --baseCost 
-- local base = math.max(m * arkayData.kills + c, 1)
-- local base2 = math.max( -9/150 * arkayData.kills + 10, 1)
-- linear interpolation formula
-- posLinear -- local damage =                        math.min((2/150)   * tes3.player.data.arkay.kills + 1,  3)
--                                                          (1, 3, 150, tes3.player.data.arkay.kills)
-- negLinear -- tes3.getObject("test2").magickaCost = math.max((-24/150) * arkayData.kills + 25, 1)


--- 
--- functions.linearInter(10, 1, 150, tes3.player.data.arkay.kills, false)
---
--- start at 10, end at 1 when arkay.kills = 150, is negative (false)
---
--- functions.linearInter(1, 3, 150, tes3.player.data.arkay.kills, true)
---
--- start at 1, end at 3 when arkay.kills = 150, is a positive increase (true)
---
---@deprecated Use functions.lerp
---@param base any The starting value
---@param max any The value it ends at
---@param progressCap any When the value of data hits this max will be the value
---@param data any Where progressCap gets its data
---@param positive boolean If true then returns a positive slope, negative if false
---@return number
function functions.linearInter(base, max, progressCap, data, positive)
    local slope = (max - base)/progressCap
    local result = (slope * data + base)
    if positive then
        return math.min(result, max)
    else
        return math.max(result, max)
    end
end

----------------------------------------------------------------------------------------------------
---`lerp`
----------------------------------------------------------------------------------------------------
---`I dont understand this at all, its cobbled together from random tidbits I found online, it works through magic.`
---@param base any The starting value
---@param max any The value it ends at
---@param progressCap any When the value of data hits this max will be the value
---@param data any Where progressCap gets its data
---@param isPositive boolean If true then returns a positive slope, negative if false
---@return number
---Usage:
--
---     local damage = functions.lerp(1, 3, 150, playerData.kills, true)
--
---     `1 - is the starting value`
---     `3 - is the end value`
--
---     `150 - the cap, when kills in this example reaches 150, damage = 3, when its 0, damage = 1`
--
---     `playerData.kills - can be anything, in this instance its player.data.kills, which keeps track of kills and increments starting value`
--
---     `true - means the value is increasing, when false decreasing` ``lerp(3, 1, 150, playerData.kills, false)`
--
function functions.lerp(base, max, progressCap, data, isPositive)
    local slope = (max - base)/progressCap
    local result = (slope * data + base)
    if isPositive then
        return math.min(result, max)
    else
        return math.max(result, max)
    end
end


--|==============================================================================================|
--|===================================|Small Helper Functions|===================================|
--|==============================================================================================|

----------------------------------------------------------------------------------------------------
---`string.format`
----------------------------------------------------------------------------------------------------
---@param string string
---@param ... (any)
function functions.sf(string, ...)
    return string.format(string, ...)
end
----------------------------------------------------------------------------------------------------
---`state`
----------------------------------------------------------------------------------------------------
---Get onTick spells state
---@param e tes3magicEffectTickEventData
---@return tes3.spellState
function functions.state(e)
    return e.effectInstance.state
end
----------------------------------------------------------------------------------------------------
---`refreshSpell`
----------------------------------------------------------------------------------------------------
---Removes and Adds back the spell. Made for updating a spells cost after the player has it.
---@param ref tes3reference
---@param spell string
function functions.refreshSpell(ref, spell)
    tes3.removeSpell{reference = ref, spell = spell}
    tes3.addSpell{reference = ref, spell = spell}
end
----------------------------------------------------------------------------------------------------
---`modCurrent`
----------------------------------------------------------------------------------------------------
---@param ref tes3reference|tes3mobilePlayer
---@param stat string
---@param amount number
---@param baseLimit boolean?
function functions.modCurrent(ref, stat, amount, baseLimit)
    tes3.modStatistic{
        reference = ref,
        name = stat,
        current = amount,
        limitToBase = baseLimit
    }
end
----------------------------------------------------------------------------------------------------
---`setBase`
----------------------------------------------------------------------------------------------------
---@param ref tes3reference|tes3mobilePlayer
---@param stat string
---@param amount number
---@param baseAndCurrent boolean?
function functions.setBase(ref, stat, amount, baseAndCurrent)
    tes3.setStatistic{
        reference = ref,
        name = stat,
        base = amount,
        value = baseAndCurrent == true and amount
    }
end
----------------------------------------------------------------------------------------------------
---`addSpell`
----------------------------------------------------------------------------------------------------
---More convienent addSpell when you're just adding spell to a ref
---@param ref any Who to add the spell to
---@param spell string|tes3spell Spell Id
function functions.addSpell(ref, spell)
    tes3.addSpell{reference = ref, spell = spell}
end
----------------------------------------------------------------------------------------------------
---`bulkAddSpells`
----------------------------------------------------------------------------------------------------
---@param spellTable table
function functions.bulkAddSpells(ref, spellTable)
    for _, spell in pairs(spellTable) do
        if not tes3.hasSpell{reference = ref, spell = spell.spell.id} then
            tes3.addSpell{reference = ref, spell = spell.spell.id}
        else
            log:debug("bullkAddSpells - Player already has %s, skipping", spell.spellId)
        end
    end
end
----------------------------------------------------------------------------------------------------
---`distributeSpells`
----------------------------------------------------------------------------------------------------
function functions.distributeSpells(spellTable) 
    for key, spell in pairs(spellTable) do
        if tes3.hasSpell{reference = spell.seller, spell = spell.spellId} then
            log:debug("%s has %s", spell.seller, spell.spellId)
            -- break
        else
            log:debug("Adding %s to %s", spell.spellId, spell.seller)
            functions.sellSpell(spell.seller, spell.spellId)
        end
    end
end
----------------------------------------------------------------------------------------------------
---`sellSpell`
----------------------------------------------------------------------------------------------------
---Adds the spell to the `ref` and sets them to sell spells
---@param ref string The id of the reference ex: "fargoth"
---@param spellId any The id of the spell ex: "fire bite"
---Usage:
--
---     functions.sellSpell("fargoth", "rallying touch")
function functions.sellSpell(ref, spellId)
    local seller = tes3.getReference(ref)
    if seller == tes3.player or seller == tes3.mobilePlayer then return end
    if seller.object.aiConfig.offersSpells == false then
        seller.object.aiConfig.offersSpells = true
        log:debug("%s now offersSpells", seller)
    end
    functions.addSpell(seller, spellId)
    log:debug("%s added to %s", spellId, seller)
end
----------------------------------------------------------------------------------------------------
---`keyUp`
----------------------------------------------------------------------------------------------------
---Small helper function to handle keyUp event, includes a check for menuMode, not really faster but i wanted it.
---@param key string|number The Key to trigger it ex: "p" 
---@param func fun() The function you want to run on key press
---Usage: *Note is registered in the loaded event*
---
---     bs.keyUp("p", function()
---         bs.msg("P has been pressed")
---     end)
function functions.keyUp(key, func)
    local function keyAction() --needed for menuMode check
        if not tes3.menuMode() then
            func()             --This is where the passed along function runs
        end
    end

    if type(key) == "string" then
        key = tes3.scanCode[key]
    elseif type(key) == "number" then
        key = key
    end
    -- tes3.scanCode[key]

    local function onLoad()     --only register event when game is loaded
        event.unregister("keyUp", keyAction, { filter = key }) -- Unregister the event first
        if not event.isRegistered("keyUp", keyAction, { filter = key }) then
            event.register("keyUp", keyAction, { filter = key })
        end
    end

    event.unregister("loaded", onLoad)
    event.register("loaded", onLoad)
end
----------------------------------------------------------------------------------------------------
---`glowFX`
----------------------------------------------------------------------------------------------------
---Applys an enchant style vfx to a reference
---@param ref tes3reference|string The reference to apply the Fx to
---@param effectId tes3.effect
---@param lifespan number?
---Usage:
---
---     functions.glowFX(ref, tes3.effect.charm)
--- >
function functions.glowFX(ref, effectId, lifespan)
    tes3.createVisualEffect({ lifespan = lifespan or 1, reference = ref, magicEffectId = effectId, })
end
----------------------------------------------------------------------------------------------------
---`equipMagic`
----------------------------------------------------------------------------------------------------
function functions.equipMagic(spellId)
    tes3.mobilePlayer:equipMagic{source = spellId}
end
----------------------------------------------------------------------------------------------------
---`msg`
----------------------------------------------------------------------------------------------------
---Just a shorthand for messageBox, `local bs = require("BeefStranger.functions")`
---@param ... any|tes3.messageBox.messageOrParams
--- - Usage: Same as tes3.messageBox
---
---         functions.msg("Yo dayo")
--- - This obviously works better when requiring like this:
--
---         local bs = require("BeefStranger.functions")
---         bs.msg("Yo dayo")
function functions.msg(...)
    tes3.messageBox(...)
end
----------------------------------------------------------------------------------------------------
---`playSound`
----------------------------------------------------------------------------------------------------
---@param sound string|tes3sound|bsSounds The sound object, or id of the sound to look for.
---@param volume number? Default: 1.0. A value between 0.0 and 1.0 to scale the volume off of.
---@param pitch number? Default: 1.0. The pitch-shift multiplier. For 22kHz audio (most typical) it can have the range [0.005, 4.5]; for 44kHz audio it can have the range [0.0025, 2.25].
---@param reference tes3reference|tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer|string|nil? The reference to attach the sound to. If no reference is provided, the sound will be played directly.
---Usage:
---
---     functions.playSound(bs.sound.bell6)
---or
---
---     functions.playSound("bell6")
function functions.playSound(sound, volume, pitch, reference)
    tes3.playSound{ sound = sound, volume = volume, pitch = pitch, reference = reference}
end
----------------------------------------------------------------------------------------------------
---`createConfig` --Not sure i can make it worth using
----------------------------------------------------------------------------------------------------
-- function functions.createConfig(configPath, default)
--     local config = mwse.loadConfig(configPath, default)
    
--     event.register(tes3.event.modConfigReady, function ()
--         local template = mwse.mcm.createTemplate({ name = configPath })
--         template:saveOnClose(configPath, config)
--     end)


--     return config
-- end
----------------------------------------------------------------------------------------------------



---------------------------------objectTypes in Table---------------------------------<br>
---@type (number | string)[] Table to convert objectTypes inserted into its string
functions.objectTypeNames = {
    [1230259009] = "activator",
    [1212369985] = "alchemy",
    [1330466113] = "ammunition",
    [1095782465] = "apparatus",
    [1330467393] = "armor",
    [1313297218] = "birthsign",
    [1497648962] = "bodyPart",
    [1263488834] = "book",
    [1280066883] = "cell",
    [1396788291] = "class",
    [1414483011] = "clothing",
    [1414418243] = "container",
    [1095062083] = "creature",
    [1279347012] = "dialogue",
    [1330007625] = "dialogueInfo",
    [1380929348] = "door",
    [1212370501] = "enchantment",
    [1413693766] = "faction",
    [1414745415] = "gmst",
    [1380404809] = "ingredient",
    [1145979212] = "land",
    [1480938572] = "landTexture",
    [1129727308] = "leveledCreature",
    [1230390604] = "leveledItem",
    [1212631372] = "light",
    [1262702412] = "lockpick",
    [1178945357] = "magicEffect",
    [1129531725] = "miscItem",
    [1413693773] = "mobileActor",
    [1380139341] = "mobileCreature",
    [1212367181] = "mobileNPC",
    [1346584909] = "mobilePlayer",
    [1246908493] = "mobileProjectile",
    [1347637325] = "mobileSpellProjectile",
    [1598246990] = "npc",
    [1146242896] = "pathGrid",
    [1112494672] = "probe",
    [1397052753] = "quest",
    [1162035538] = "race",
    [1380336978] = "reference",
    [1313293650] = "region",
    [1095779666] = "repairItem",
    [1414546259] = "script",
    [1279871827] = "skill",
    [1314213715] = "sound",
    [1195658835] = "soundGenerator",
    [1279610963] = "spell",
    [1380143955] = "startScript",
    [1413567571] = "static",
    [1346454871] = "weapon",
}

functions.skills = {
    [0] = "block",
    [1] = "armorer",
    [2] = "mediumArmor",
    [3] = "heavyArmor",
    [4] = "bluntWeapon",
    [5] = "longBlade",
    [6] = "axe",
    [7] = "spear",
    [8] = "athletics",
    [9] = "enchant",
    [10] = "destruction",
    [11] = "alteration",
    [12] = "illusion",
    [13] = "conjuration",
    [14] = "mysticism",
    [15] = "restoration",
    [16] = "alchemy",
    [17] = "unarmored",
    [18] = "security",
    [19] = "sneak",
    [20] = "acrobatics",
    [21] = "lightArmor",
    [22] = "shortBlade",
    [23] = "marksman",
    [24] = "mercantile",
    [25] = "speechcraft",
    [26] = "handToHand",
}

---------------------------------spellStates in Table---------------------------------
---@type table
functions.stateId = {
    [0] = "preCast",
    [1] = "cast",
    [4] = "beginning",
    [5] = "working",
    [6] = "ending",
    [7] = "retired",
    [8] = "workingFortify",
    [9] = "endingFortify",
}

functions.stateName = {
    ["preCast"] = 0,
    ["cast"] = 1,
    ["beginning"] = 4,
    ["working"] = 5,
    ["ending"] = 6,
    ["retired"] = 7,
    ["workingFortify"] = 8,
    ["endingFortify"] = 9,
}



return functions
