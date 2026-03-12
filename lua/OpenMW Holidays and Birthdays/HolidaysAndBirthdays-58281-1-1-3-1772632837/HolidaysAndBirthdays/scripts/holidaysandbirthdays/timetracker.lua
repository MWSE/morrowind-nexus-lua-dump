local core = require('openmw.core')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local world = require('openmw.world')
local async = require('openmw.async')
local Helpers = require('scripts.holidaysandbirthdays.helpers')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local storage = require('openmw.storage')
local constants = require('scripts.holidaysandbirthdays.constants')


local trueDate = { year = 0, month = 0, day = 0 }
local globalSettings = storage.globalSection(constants.globalSettingsStorageKey)
local daedricQuestsLimited = globalSettings:get(constants.enableDaedricLimitersKey) or
    constants.enableDaedricLimitersDefault

local function processTrueDate(offset)
    local trueGameTime = calendar.gameTime() + offset * time.day
    local day = tonumber(calendar.formatGameTime("%d", trueGameTime))
    local month = tonumber(calendar.formatGameTime("%m", trueGameTime))
    local year = tonumber(calendar.formatGameTime("%Y", trueGameTime))
    return { year = year, month = month, day = day }
end
local function updateTimeOffsets()
    -- local t = calendar.formatGameTime("*t",constants.gameStartTime)
    -- print("start game time: " .. t.year .. "-" .. t.month .. "-" .. t.day)
    local gameTime = core.getGameTime()
    -- print("core gametime:",gameTime, calendar.formatGameTime("%d %m %Y", constants.gameStartTime))
    for _, player in pairs(world.players) do
        local vars = world.mwscript.getGlobalVariables(player)
        local day = vars.day
        local month = vars.month + 1
        local year = vars.year
        local playerDate = calendar.gameTime({
            day = day,
            month = month,
            year = year
        }) - Helpers.getAbsoluteGameStartTime()
        local diff = (playerDate - gameTime) / time.day
        local localOffset = math.floor(diff)
        trueDate = processTrueDate(localOffset)
        player:sendEvent("holidays_internal_receiveDayOffset", {trueDate = trueDate, offset = localOffset})
    end
end

local stopTimerFn = time.runRepeatedly(updateTimeOffsets, 31 * time.second, {
    type = time.SimulationTime, -- pauses with game
    --initialDelay = 5
})


--#region Daedric Summoning days tracking and handling

local function activationPreventHandler(object, actor)
    if daedricQuestsLimited then -- if enabled in settings
        if constants.daedraPrinceReference[string.lower(object.recordId)] ~= nil then
            local princeData = constants.daedraPrinceReference[string.lower(object.recordId)]
            local stage
            for _, player in pairs(world.players) do
                stage = types.Player.quests(player)[princeData.questId].stage
            end
            if stage >= princeData.questStage then
                -- Daedric quest active or finished -- no need to prevent anything
                return true
            end
            if trueDate.month == princeData.month and trueDate.day == princeData.day then
                local offerings = types.Actor.inventory(actor):findAll(princeData.offering.id)
                local offeringCount = 0
                for _, item in ipairs(offerings) do
                    offeringCount = offeringCount + item.count
                end
                if offeringCount >= princeData.offering.count then
                    actor:sendEvent("holidaysandbirthdays_daedraOfferingAccepted", princeData)
                    for _, item in ipairs(offerings) do
                        item:remove(princeData.offering.count)
                    end
                    return true
                else
                    actor:sendEvent("holidays_internal_daedraNeedOffering", princeData)
                    return false
                end
            else
                actor:sendEvent("holidays_internal_daedraNotInterested", princeData)
                return false
            end
        else
            -- activator not in list, letting it through
            return true
        end
    else
        return true
    end
end

-- local function onCellChange(t)
--     local prevCell = world.getCellById(t.oldCell.id)
--     local currCell = world.getCellById(t.newCell.id)
--     local player = world.players[1]
--     local localStatics = player.cell:getAll(types.Static)
-- end

local function onSettingsChanged()
    daedricQuestsLimited = globalSettings:get(constants.enableDaedricLimitersKey) or
        constants.enableDaedricLimitersDefault
end

I.Activation.addHandlerForType(types.Activator, activationPreventHandler)

storage.globalSection(constants.globalSettingsStorageKey):subscribe(async:callback(onSettingsChanged))


-- return {
--     eventHandlers = {
--         holidays_internal_onCellChanged = onCellChange,
--     }
-- }


--#endregion
