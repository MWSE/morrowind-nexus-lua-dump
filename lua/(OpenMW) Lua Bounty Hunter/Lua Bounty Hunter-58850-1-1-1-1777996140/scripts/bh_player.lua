local self    = require("openmw.self")
local types   = require("openmw.types")
local core    = require("openmw.core")
local nearby  = require("openmw.nearby")
local ui      = require("openmw.ui")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local I = require("openmw.interfaces")
local util    = require("openmw.util")
local input   = require("openmw.input")
local time    = require("openmw_aux.time")

local shared       = require("scripts.bh_shared")
local FORTS        = shared.FORTS
local DEFAULTS     = shared.DEFAULTS
local KHAJIIT_RACE = shared.KHAJIIT_RACE

local FORT_TARGET_LOWER = {}
local FORT_REWARD_LOWER = {}
for _, fort in ipairs(FORTS) do
    FORT_TARGET_LOWER[fort.id] = fort.targetCell:lower()
    FORT_REWARD_LOWER[fort.id] = fort.rewardNpc:lower()
end

local section = storage.playerSection("SettingsBH")

local function get(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local cachedSettings = {
    MOD_ENABLED      = get("MOD_ENABLED"),
    ESCAPE_CHANCE    = get("ESCAPE_CHANCE"),
    REWARD_PER_LEVEL = get("REWARD_PER_LEVEL"),
    ENABLE_LOGS      = get("ENABLE_LOGS"),
    MIN_PRISONER_LEVEL = get("MIN_PRISONER_LEVEL"),
    SHOW_DEATH_TAUNT = get("SHOW_DEATH_TAUNT"),
    SHOW_ALREADY_ESCORTING = get("SHOW_ALREADY_ESCORTING"),
}

local logEnabled = false
local function log(...)
    if logEnabled then print("[BH P]", ...) end
end

local function broadcastEscortState(pId)
    core.sendGlobalEvent("BH_UpdateEscortState", { prisonerId = pId })
end

local playerIsKhajiit = (function()
    local rec  = types.NPC.record(self.object)
    local race = rec and rec.race or ""
    return KHAJIIT_RACE[race:lower()] or false
end)()

local function pickMsg(pool)
    return pool[math.random(#pool)]
end

local function broadcastSettings()
    core.sendGlobalEvent("BH_SettingsUpdated", {
        MOD_ENABLED      = cachedSettings.MOD_ENABLED,
        ESCAPE_CHANCE    = cachedSettings.ESCAPE_CHANCE,
        REWARD_PER_LEVEL = cachedSettings.REWARD_PER_LEVEL,
        ENABLE_LOGS      = cachedSettings.ENABLE_LOGS,
        MIN_PRISONER_LEVEL = cachedSettings.MIN_PRISONER_LEVEL,
        SHOW_DEATH_TAUNT = cachedSettings.SHOW_DEATH_TAUNT,
        SHOW_ALREADY_ESCORTING = cachedSettings.SHOW_ALREADY_ESCORTING,


    })
    logEnabled = cachedSettings.ENABLE_LOGS
    log("Settings broadcast")
end

section:subscribe(async:callback(function()
    for k in pairs(cachedSettings) do cachedSettings[k] = get(k) end
    broadcastSettings()
end))

local fortWindow = nil
local windowOwnsMode = false

local function destroyFortWindow()
    if not fortWindow then return end
    fortWindow:destroy()
    fortWindow = nil
    if windowOwnsMode then
        windowOwnsMode = false
        I.UI.removeMode("Interface")
    end
end

local FONT_HEADER = 28
local FONT_COL    = 22
local FONT_BODY   = 22

local COL_LOC_W   = 440
local COL_NPC_W   = 280
local COL_SLOT_W  = 160

local COLOR_HEADER  = util.color.rgb(0.95, 0.80, 0.20)
local COLOR_SUB     = util.color.rgb(0.78, 0.66, 0.32)
local COLOR_TEXT    = util.color.rgb(0.92, 0.88, 0.78)
local COLOR_FREE_OK = util.color.rgb(0.65, 0.85, 0.45)
local COLOR_FREE_LO = util.color.rgb(0.95, 0.65, 0.25)
local COLOR_FREE_NO = util.color.rgb(0.90, 0.25, 0.20)
local COLOR_DIVIDER = util.color.rgb(0.55, 0.45, 0.20)
local COLOR_CLOSE   = util.color.rgb(0.95, 0.80, 0.20)

local function slotColor(free, total)
    if free <= 0 then return COLOR_FREE_NO end
    if total > 0 and free / total <= 0.34 then return COLOR_FREE_LO end
    return COLOR_FREE_OK
end

local function textCell(text, width, color, size, align)
    local fontSize = size or FONT_BODY
    return {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(width, fontSize + 6),
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text       = text,
                    textSize   = fontSize,
                    textColor  = color or COLOR_TEXT,
                    textAlignH = align or ui.ALIGNMENT.Start,
                },
            },
        },
    }
end

local function dividerRow(width, color)
    -- underscores separator
    return {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(width, FONT_BODY + 2),
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text       = string.rep("_", math.floor(width / 10)),
                    textSize   = FONT_BODY,
                    textColor  = color or COLOR_DIVIDER,
                    textAlignH = ui.ALIGNMENT.Start,
                },
            },
        },
    }
end

local function buildFortWindow(fortData)
    if fortWindow then fortWindow:destroy() end

    local rows = {}

    local totalWidth = COL_LOC_W + COL_NPC_W + COL_SLOT_W

    -- title bar
    rows[#rows + 1] = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textHeader,
                props = {
                    text      = "Fort Prison Status",
                    textSize  = FONT_HEADER,
                    textColor = COLOR_HEADER,
                },
            },
            {
                props = { size = util.vector2(totalWidth - 360, 0) },
            },
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text       = "[X]",
                    textSize   = FONT_HEADER,
                    textColor  = COLOR_CLOSE,
                    textAlignH = ui.ALIGNMENT.End,
                },
                events = {
                    mouseClick = async:callback(destroyFortWindow),
                },
            },
        },
    }

    rows[#rows + 1] = { props = { size = util.vector2(0, 14) } }

    -- column headers
    rows[#rows + 1] = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Start,
        },
        content = ui.content {
            textCell("Location",    COL_LOC_W,  COLOR_SUB, FONT_COL, ui.ALIGNMENT.Start),
            textCell("Reward NPC",  COL_NPC_W,  COLOR_SUB, FONT_COL, ui.ALIGNMENT.Start),
            textCell("Free Slots",  COL_SLOT_W, COLOR_SUB, FONT_COL, ui.ALIGNMENT.End),
        },
    }

    rows[#rows + 1] = { props = { size = util.vector2(0, 2) } }
    rows[#rows + 1] = dividerRow(totalWidth)
    rows[#rows + 1] = { props = { size = util.vector2(0, 6) } }

    -- data rows
    for i, f in ipairs(fortData) do
        local locName = f.name or f.id or "?"
        local npcName = f.rewardNpcName or "-"
        local slotText
        if f.total and f.total > 0 then
            slotText = string.format("%d / %d", f.free or 0, f.total)
        else
            slotText = tostring(f.free or 0)
        end
        local sColor = slotColor(f.free or 0, f.total or 0)

        rows[#rows + 1] = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Start,
            },
            content = ui.content {
                textCell(locName, COL_LOC_W,  COLOR_TEXT, FONT_BODY, ui.ALIGNMENT.Start),
                textCell(npcName, COL_NPC_W,  COLOR_TEXT, FONT_BODY, ui.ALIGNMENT.Start),
                textCell(slotText, COL_SLOT_W, sColor,    FONT_BODY, ui.ALIGNMENT.End),
            },
        }

        -- separate rows
        if i < #fortData then
            rows[#rows + 1] = { props = { size = util.vector2(0, 4) } }
        end
    end

    fortWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.box,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            {
                type = ui.TYPE.Container,
                template = I.MWUI.templates.boxSolid,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            arrange = ui.ALIGNMENT.Start,
                            padding = 24,
                        },
                        content = ui.content(rows),
                    },
                },
            },
        },
    }

    windowOwnsMode = true
    I.UI.setMode("Interface", { windows = {} })
end

local function toggleFortWindow()
    if fortWindow then
        destroyFortWindow()
    else
        core.sendGlobalEvent("BH_RequestFortStatus", { player = self.object })
    end
end

local triggerRegisteredBH = false
local function registerTriggerBH()
    if triggerRegisteredBH then return end
    triggerRegisteredBH = true
    input.registerTriggerHandler('ToggleFortStatus', async:callback(toggleFortWindow))
end

local function initScriptBH()
    registerTriggerBH()
end

-- escort state
local prisoner       = nil
local prisonerLevel  = 1
local escorting      = false
local rewardPending  = false

-- if not in the same cell for 10s, treat as escaped
local lastCellName   = nil
local watchdogGen    = 0
local WATCHDOG_DELAY = 10 * time.second

local function isInFortTargetCell()
    local cell = self.cell
    if not cell then return nil end
    local lo = (cell.name or ""):lower()
    for _, fort in ipairs(FORTS) do
        if FORT_TARGET_LOWER[fort.id] == lo then return fort end
    end
    return nil
end

local function findRewardNpc(fort)
    local rewardLower = FORT_REWARD_LOWER[fort.id]
    for _, actor in ipairs(nearby.actors) do
        if types.NPC.objectIsInstance(actor)
           and actor.recordId:lower() == rewardLower
        then
            local d  = actor.position - self.position
            local hz = math.sqrt(d.x * d.x + d.y * d.y)
            local vt = math.abs(d.z)
            if hz <= fort.rewardRadius and vt <= fort.rewardZRange then
                return actor
            end
        end
    end
    return nil
end

local function clearEscort()
    prisoner      = nil
    prisonerLevel = 1
    escorting     = false
    rewardPending = false
    watchdogGen   = watchdogGen + 1   -- invalidate any pending watchdog
    broadcastEscortState(nil)
end

local function declarePrisonerEscaped()
    if not prisoner then return end
    local escapedNpc = prisoner
    local npcId = escapedNpc.id
    log("Prisoner escaped via cell change:", escapedNpc.recordId or "?")
    ui.showMessage(shared.MESSAGES.prisoner_escaped)
    core.sendGlobalEvent("BH_PrisonerEscapedViaCellChange", { npcId = npcId })
    -- drop them from the kill-player whitelist, escaped
    if escapedNpc:isValid() then
        self.object:sendEvent("BH_PrisonerClearKillPlayer", { npc = escapedNpc })
    end
    clearEscort()
end

local function tryClaimReward(fort)
    if rewardPending then return end
    if not prisoner or not prisoner:isValid() then return end

    local prisonerCell = prisoner.cell
    if not prisonerCell then return end
    local playerCell = self.cell
    if not playerCell then return end
    local sameCell = (prisonerCell == playerCell)
    if not sameCell then return end

    local rewardNpc = findRewardNpc(fort)
    if not rewardNpc then return end

    rewardPending = true
    local claimedPrisoner = prisoner
    local claimedLevel    = prisonerLevel
    -- drop the prisoner from the kill-player whitelist, deported
    if claimedPrisoner:isValid() then
        self.object:sendEvent("BH_PrisonerClearKillPlayer", { npc = claimedPrisoner })
    end
    clearEscort()
    log("Claiming reward at", fort.id)

    core.sendGlobalEvent("BH_ClaimReward", {
        npc            = claimedPrisoner,
        player         = self.object,
        fortId         = fort.id,
        npcLevel       = claimedLevel,
        rewardPerLevel = cachedSettings.REWARD_PER_LEVEL,
    })
end

local function scheduleWatchdog()
    watchdogGen = watchdogGen + 1
    local myGen = watchdogGen
    async:newUnsavableSimulationTimer(WATCHDOG_DELAY, function()
        if myGen ~= watchdogGen then return end
        if not escorting then return end
        if not prisoner or not prisoner:isValid() then
            clearEscort()
            return
        end
        local pcell = prisoner.cell
        local mycell = self.cell
        if pcell and mycell and pcell == mycell then
            -- prisoner caught up. All good.
            return
        end
        declarePrisonerEscaped()
    end)
end

local updateTimer = 0
local UPDATE_INTERVAL = 1.0 * time.second

local function onUpdate(dt)
    if not cachedSettings.MOD_ENABLED then return end

    if not escorting then return end

    local cellName = self.cell and self.cell.name or nil
    if cellName ~= lastCellName then
        lastCellName = cellName
        if escorting and prisoner and prisoner:isValid() then
            scheduleWatchdog()
        end
    end



    updateTimer = updateTimer + dt
    if updateTimer < UPDATE_INTERVAL then return end
    updateTimer = 0

    if not prisoner or not prisoner:isValid() then
        log("Prisoner lost (invalid)")
        clearEscort()
        return
    end

    if types.Actor.isDead(prisoner) then
        -- death is reported via BH_EscortEnded(reason='died')
        return
    end

    local fort = isInFortTargetCell()
    if fort then
        tryClaimReward(fort)
    else
        rewardPending = false
    end
end

local function onSave()
    return {
        prisoner      = prisoner,
        prisonerLevel = prisonerLevel,
        escorting     = escorting,
    }
end

local function onLoad(data)
    registerTriggerBH()
    broadcastSettings()
    if not data then return end
    prisoner      = data.prisoner
    prisonerLevel = data.prisonerLevel or 1
    escorting     = data.escorting or false
    broadcastEscortState(prisoner and prisoner.id or nil)
    rewardPending = false

    if prisoner and not prisoner:isValid() then
        clearEscort()
    end
    lastCellName = nil
    watchdogGen  = watchdogGen + 1
    log("Loaded: escorting=", tostring(escorting),
        " prisoner=", prisoner and prisoner.recordId or "nil")
end

local function onShowMessage(data)
    if data and data.message then ui.showMessage(data.message) end
end

local function onNotifyAlreadyEscorting()
    if not cachedSettings.SHOW_ALREADY_ESCORTING then return end
    ui.showMessage(shared.MESSAGES.already_escorting)
end

local function onCheckAlreadyEscorting(data)
    if not cachedSettings.MOD_ENABLED then return end

    core.sendGlobalEvent("BH_StartEscort", {
        npc             = data.npc,
        player          = data.player,
        playerIsKhajiit = playerIsKhajiit,
        originalFight   = data.originalFight,
    })
end

local function onEscortStarted(data)
    if escorting then return end
    prisoner      = data.npc
    prisonerLevel = data.prisonerLevel or 1
    escorting     = true
    rewardPending = false
    lastCellName  = self.cell and self.cell.name or nil
    log("Escort started:", prisoner and prisoner.recordId or "?",
        "level:", prisonerLevel)

    -- tell gko_player that this NPC may now kill the player
    self.object:sendEvent("BH_PrisonerSetKillPlayer", { npc = prisoner })
    broadcastEscortState(prisoner.id)
end

local function onPrisonerEscaped(data)
    log("Prisoner went hostile:", data and data.npc and data.npc.recordId or "?")
end

local function onEscortEnded(data)
    local reason = data and data.reason or "?"
    log("Escort ended:", reason)

    -- only when the prisoner was killed
    if reason == "died" and data and data.npc and data.npc:isValid()
       and cachedSettings.SHOW_DEATH_TAUNT
    then
        local stillOurs = prisoner and prisoner:isValid() and data.npc.id == prisoner.id
        if stillOurs then
            local pool = playerIsKhajiit and shared.MESSAGES.khajiit_death_prisoner
                                          or shared.MESSAGES.death_prisoner
            local playerRec  = types.NPC.record(self.object)
            local playerName = playerRec and playerRec.name or "Hero"
            ui.showMessage(playerName .. ": \"" .. pickMsg(pool) .. "\"")
        end
    end

    -- clear the kill-player whitelist for the prisoner
    if data and data.npc and data.npc:isValid() then
        self.object:sendEvent("BH_PrisonerClearKillPlayer", { npc = data.npc })
    elseif prisoner and prisoner:isValid() then
        self.object:sendEvent("BH_PrisonerClearKillPlayer", { npc = prisoner })
    end

    clearEscort()
end

local function onReceiveFortStatus(data)
    if data and data.forts then
        buildFortWindow(data.forts)
    end
end

local function onUiModeChanged(data)
    if data.oldMode == "Interface" and data.newMode == nil
       and fortWindow and windowOwnsMode
    then
        destroyFortWindow()
    end
end

return {
    engineHandlers = {
        onInit   = initScriptBH,
        onSave   = onSave,
        onLoad   = onLoad,
        onUpdate = onUpdate,
    },

    eventHandlers = {
        BH_ShowMessage            = onShowMessage,
        BH_NotifyAlreadyEscorting = onNotifyAlreadyEscorting,
        BH_CheckAlreadyEscorting  = onCheckAlreadyEscorting,
        BH_EscortStarted          = onEscortStarted,
        BH_PrisonerEscaped        = onPrisonerEscaped,
        BH_EscortEnded            = onEscortEnded,
        BH_ReceiveFortStatus      = onReceiveFortStatus,
        UiModeChanged             = onUiModeChanged,
    },
}