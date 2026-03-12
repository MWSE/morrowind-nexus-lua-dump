local core = require('openmw.core')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local SECTION_NAME = 'illegalLoitering'
local section = storage.globalSection(SECTION_NAME)

local DEFAULT_BOUNTY_PER_HOUR = 10
local DEFAULT_SCAN_RADIUS = 12000
local DEFAULT_GRACE_HOURS = 3

local REST_MODE = (I.UI and I.UI.MODE and I.UI.MODE.Rest) or 'Rest'
local LOADING_MODE = (I.UI and I.UI.MODE and I.UI.MODE.Loading) or 'Loading'
local LOADING_WALLPAPER_MODE = (I.UI and I.UI.MODE and I.UI.MODE.LoadingWallpaper) or 'LoadingWallpaper'

local restSession = nil
local lastRestCloseRealTime = nil

local BED_REST_CONTEXT_WINDOW_SECONDS = 600
local bedRestContext = nil

local function getConfig()
    local bountyPerHour = section:get('bountyPerHour') or DEFAULT_BOUNTY_PER_HOUR
    local scanRadius = section:get('scanRadius') or DEFAULT_SCAN_RADIUS
    local graceHours = section:get('graceHours')
    if type(graceHours) ~= 'number' then graceHours = DEFAULT_GRACE_HOURS end
    if graceHours < 0 then graceHours = 0 end
    return bountyPerHour, scanRadius, graceHours
end

local function isCellMarkedSafe(cellId)
    if not cellId then return false end
    local safeCells = section:get('safeCells')
    if not safeCells then return false end
    return safeCells[cellId] ~= nil and safeCells[cellId] ~= false
end

local function playerFactionRank(factionId)
    local ok, rank = pcall(function()
        return types.NPC.getFactionRank(self, factionId)
    end)
    if not ok then return 0 end
    return rank or 0
end

local function isPlayerExpelled(factionId)
    local ok, expelled = pcall(function()
        return types.NPC.isExpelled(self, factionId)
    end)
    if not ok then return false end
    return expelled == true
end

local function isUnauthorizedOwner(owner)
    if not owner then return false end

    if owner.recordId and owner.recordId ~= '' then
        return owner.recordId ~= self.recordId
    end

    if owner.factionId and owner.factionId ~= '' then
        if isPlayerExpelled(owner.factionId) then return true end

        local rank = playerFactionRank(owner.factionId)
        if rank <= 0 then return true end

        if owner.factionRank ~= nil and rank < owner.factionRank then
            return true
        end

        return false
    end

    return false
end

local function hasUnauthorizedOwnedObject(scanRadius)
    local function checkList(list)
        for _, obj in ipairs(list) do
            if obj and obj:isValid() and obj.owner then
                local dist = (obj.position - self.position):length()
                if dist <= scanRadius and isUnauthorizedOwner(obj.owner) then
                    return true
                end
            end
        end
        return false
    end

    local ok, res = pcall(function()
        if checkList(nearby.containers) then return true end
        if checkList(nearby.doors) then return true end
        if checkList(nearby.items) then return true end
        return false
    end)

    if not ok then
        -- If nearby access fails for any reason, prefer NOT to punish the player.
        return false
    end

    return res == true
end

local function hasNpcWitness(radius)
    local ok, res = pcall(function()
        for _, actor in ipairs(nearby.actors) do
            if actor and actor:isValid() and actor.id ~= self.id then
                if types.NPC.objectIsInstance(actor) and not types.Player.objectIsInstance(actor) then
                    local dist = (actor.position - self.position):length()
                    if dist <= radius then
                        return true
                    end
                end
            end
        end
        return false
    end)

    if not ok then
        return false
    end

    return res == true
end

local function isValidObject(obj)
    if obj == nil then
        return false
    end

    local ok, valid = pcall(function() return obj:isValid() end)
    return ok and valid == true
end

local function bedRestContextActive(cellId)
    if type(bedRestContext) ~= 'table' then
        return false
    end

    if type(bedRestContext.untilRealTime) ~= 'number' then
        return false
    end

    if type(bedRestContext.cellId) == 'string' and cellId and bedRestContext.cellId ~= cellId then
        return false
    end

    return core.getRealTime() <= bedRestContext.untilRealTime
end

local function setBedRestContext(cellId)
    bedRestContext = {
        cellId = cellId,
        untilRealTime = core.getRealTime() + BED_REST_CONTEXT_WINDOW_SECONDS,
    }
end

local function clearBedRestContext()
    bedRestContext = nil
end

local function isSleepingDialog(arg)
    local cell = self.cell
    if not cell then return false end
    if bedRestContextActive(cell.id) then
        return true
    end
    if isValidObject(arg) then
        return true
    end

    if cell.hasTag and cell:hasTag('NoSleep') then
        return false
    end

    local ok, werewolf = pcall(function() return types.NPC.isWerewolf(self) end)
    if ok and werewolf then
        return false
    end

    return true
end

local function beginRest(arg)
    local cell = self.cell
    if not cell or not cell.id then return end

    local bedRest = false
    if arg ~= nil then
        setBedRestContext(cell.id)
        bedRest = true
    elseif bedRestContextActive(cell.id) then
        bedRest = true
    end

    if restSession then
        if bedRest then
            restSession.skip = true
        end
        return
    end

    restSession = { startTime = core.getGameTime(), cellId = cell.id }

    if bedRest then
        restSession.skip = true
        return
    end

    if isSleepingDialog(arg) then
        restSession.skip = true
        return
    end

    if isCellMarkedSafe(cell.id) then
        restSession.skip = true
        return
    end

    local bountyPerHour, scanRadius, graceHours = getConfig()
    restSession.bountyPerHour = bountyPerHour
    restSession.graceHours = graceHours
    restSession.illegal = hasUnauthorizedOwnedObject(scanRadius)
    if cell.isExterior then
        restSession.illegal = restSession.illegal or hasNpcWitness(scanRadius)
    end

    if restSession.illegal then
        local now = core.getRealTime()
        if (not lastRestCloseRealTime) or (now - lastRestCloseRealTime > 1) then
            ui.showMessage('Loitering here for more than three hours is illegal.')
        end
    end
end

local function endRest()
    if not restSession then return end

    clearBedRestContext()

    local deltaSeconds = core.getGameTime() - (restSession.startTime or core.getGameTime())
    restSession.startTime = nil

    local deltaHours = deltaSeconds / 3600
    local hours = math.ceil(deltaHours - 1e-6)
    if hours <= 0 or restSession.skip or not restSession.illegal then
        restSession = nil
        lastRestCloseRealTime = core.getRealTime()
        return
    end

    local bountyPerHour = restSession.bountyPerHour or (section:get('bountyPerHour') or DEFAULT_BOUNTY_PER_HOUR)

    local graceHours = restSession.graceHours
    if type(graceHours) ~= 'number' then graceHours = section:get('graceHours') end
    if type(graceHours) ~= 'number' then graceHours = DEFAULT_GRACE_HOURS end
    if graceHours < 0 then graceHours = 0 end

    local fineHours = math.max(0, hours - graceHours)
    if fineHours <= 0 then
        restSession = nil
        lastRestCloseRealTime = core.getRealTime()
        return
    end

    core.sendGlobalEvent('illegalLoitering_AddBounty', {
        hours = fineHours,
        cellId = restSession.cellId,
    })
    restSession = nil
    lastRestCloseRealTime = core.getRealTime()
end

local function isRestModeActive()
    if I and I.UI and I.UI.modes then
        for _, mode in ipairs(I.UI.modes) do
            if mode == REST_MODE then
                return true
            end
        end
        return false
    end

    if I and I.UI and I.UI.getMode then
        local ok, mode = pcall(function() return I.UI.getMode() end)
        return ok and mode == REST_MODE
    end

    return false
end

return {
    eventHandlers = {
        UiModeChanged = function(data)
            if type(data) ~= 'table' then return end

            local stackOk, stack = pcall(function() return ui._getUiModeStack() end)
            local restInStack = false
            local loadingInStack = false

            if stackOk and type(stack) == 'table' then
                for _, mode in ipairs(stack) do
                    if mode == REST_MODE then
                        restInStack = true
                    elseif mode == LOADING_MODE or mode == LOADING_WALLPAPER_MODE then
                        loadingInStack = true
                    end
                end
            else
                restInStack = isRestModeActive()
                loadingInStack = data.newMode == LOADING_MODE or data.newMode == LOADING_WALLPAPER_MODE
                    or data.oldMode == LOADING_MODE or data.oldMode == LOADING_WALLPAPER_MODE
            end

            if data.newMode == REST_MODE then
                beginRest(data.arg)
                return
            end

            if not restInStack and not loadingInStack then
                endRest()
            end
        end,
    },
    engineHandlers = {
        onLoad = function()
            restSession = nil
            bedRestContext = nil
        end,
        onSave = function()
            return nil
        end,
    },
}
