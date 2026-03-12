local I = require('openmw.interfaces')
local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local types = require('openmw.types')
local storage = require('openmw.storage')
local async = require('openmw.async')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local modInfo = require('scripts.holidaysandbirthdays.modinfo')
local Helpers = require('scripts.holidaysandbirthdays.helpers')
local hbui = require('scripts.holidaysandbirthdays.ui')
local constants = require('scripts.holidaysandbirthdays.constants')

local self = require("openmw.self")

local l10n = core.l10n(modInfo.l10n)
local generalSettings = storage.playerSection(constants.generalSettingsStorageKey)

local locals = {
    displayMessageStart = generalSettings:get(constants.displayMessageStartKey),
    displayMessageUntil = generalSettings:get(constants.displayMessageUntilKey),
    getBirthDayGifts = generalSettings:get(constants.getBirthDayGiftsKey),
    inExteriorCell = false,
    dateChanged = false,
}

if I.StatsWindow then
    local statsWindowSettings = storage.playerSection(constants.statsWindowIntegrationStorageKey)
    locals.statsWindowPane = statsWindowSettings:get(constants.statsWindowPaneKey)
    locals.statsWindowPlacement = string.lower(statsWindowSettings:get(constants.statsWindowPlacementSettingKey))
    locals.statsWindowIndent = statsWindowSettings:get(constants.indentValuesKey)
end

local ageStats = { birthYear = 0, birthMonth = 0, birthDay = 0, fullYears = 0 }
local ageStatsDefaults = { charBirthdayDay = -1, charStartingAge = -1, chargenAgeStatsSet = false }
local previousDate = { year = 0, month = 0, day = 0 }

local stastIntegrationFinished = false
local ageUIActive = false
local allowedUpdates = false

local function chargenFinished()
    if SaveData ~= nil then
        if SaveData.chargenFinished then
            return true
        end
    end

    if types.Player.getBirthSign(self) ~= "" then
        SaveData.chargenFinished = true
        return true
    end
    if types.Player.isCharGenFinished(self) then
        SaveData.chargenFinished = true
        return true
    end
    for _, item in ipairs(types.Container.inventory(self):findAll('chargen statssheet')) do
        SaveData.chargenFinished = true
        return true
    end
    return false
end


local function initStatsWindowIntegration()
    local API = I.StatsWindow

    if API then
        print("[" .. modInfo.name .. "] Starting Stats Window Extender Integration ")

        local targetPane = constants.statsWindowPaneMap[locals.statsWindowPane]
        local ageStatsPlacement = constants.statsWindowPlacementMap[locals.statsWindowPlacement]

        targetPane.addMethod(targetPane.parentId, targetPane.location, {
            placement = {
                indent = locals.statsWindowIndent,
                type = ageStatsPlacement,
            }
        })
        Helpers.addOrModifySection(targetPane.subAddMethod, targetPane.subId, targetPane.subLocation,
            {
                header = l10n("stats_window_section_title"),
                indent = locals.statsWindowIndent,
                placement = {
                    type = ageStatsPlacement,
                }
            })
        API.addLineToSection("HB_character_age", targetPane.subId, {
            label = constants.char_age_stat_label,
            indent = locals.statsWindowIndent,
            value = function()
                local repValue = ReturnAge() or
                    constants.defaultStartingCharacterAge
                return { string = tostring(repValue) }
            end,
            tooltip = function()
                return API.TooltipBuilders.TEXT({
                    text = string.format(constants.char_age_stat_tooltip)
                })
            end,

            visibleFn = function() return chargenFinished() end
        })
        API.addLineToSection("HB_character_birthday", targetPane.subId, {
            label = constants.char_bd_stat_label,
            indent = locals.statsWindowIndent,
            value = function()
                local repValue = ReturnBD() or "no data"
                return { string = tostring(repValue) }
            end,
            tooltip = function()
                return API.TooltipBuilders.TEXT({
                    text = string.format(constants.char_bd_stat_tooltip)
                })
            end,
            visibleFn = function() return chargenFinished() end
        })
        stastIntegrationFinished = true
    else
        print("[" .. modInfo.name .. "] Can't find Stats Window Extender Interface. Skipping integration ")
    end
end

function ReturnAge() return tostring(ageStats.fullYears) end

function ReturnBD()
    return "3E " .. ageStats.birthYear .. "-" ..
        Helpers.zeroPadNumericString(ageStats.birthMonth) .. "-" ..
        Helpers.zeroPadNumericString(ageStats.birthDay)
end

local function initializeSettingsFromStorage()
    locals.displayMessageStart = generalSettings:get(constants.displayMessageStartKey)
    locals.displayMessageUntil = generalSettings:get(constants.displayMessageUntilKey)
    locals.getBirthDayGifts = generalSettings:get(constants.getBirthDayGiftsKey)
    if I.StatsWindow then
        local statsWindowSettings = storage.playerSection(constants.statsWindowIntegrationStorageKey)
        locals.statsWindowPane = statsWindowSettings:get(constants.statsWindowPaneKey)
        locals.statsWindowPlacement = string.lower(statsWindowSettings:get(constants.statsWindowPlacementSettingKey))
        locals.statsWindowIndent = statsWindowSettings:get(constants.indentValuesKey)
    end
end

local function onSettingsChanged()
    initializeSettingsFromStorage()
end

local function getTrueGameDate(t)
    SaveData.dayOffset = t.offset
    if chargenFinished() then
        if not locals.trueDate then
            locals.trueDate = { year = 0, month = 0, day = 0 }
        end
        previousDate = Helpers.table_shallow_copy(locals.trueDate)
        locals.trueDate = Helpers.table_shallow_copy(t.trueDate)
        locals.dateChanged = locals.trueDate.year .. "|" .. locals.trueDate.month .. "|" .. locals.trueDate.day ~=
            previousDate.year .. "|" .. previousDate.month .. "|" .. previousDate.day
    end
end

local function calcAge()
    if not SaveData.dayOffset then
        return
    end
    local trueGameTime = calendar.gameTime() + SaveData.dayOffset * time.day
    local conf = require('openmw_aux.calendarconfig')


    local absoluteBirthday = calendar.gameTime({
        day = ageStats.birthDay,
        month = ageStats.birthMonth,
        year = -ageStatsDefaults.charStartingAge
    }) - ((conf.startingYearDay) * time.day)

    local decimalAbsBirthday = Helpers.dateToDecimalDate(absoluteBirthday)
    local decimalTrueGameTime = Helpers.dateToDecimalDate(trueGameTime)
    local decimalAge = decimalTrueGameTime - decimalAbsBirthday

    ageStats.fullYears = math.floor(decimalAge)
    ageStats.birthYear = math.floor(decimalAbsBirthday)
    SaveData.ageStats = Helpers.table_shallow_copy(ageStats)
end

local function isBirthday()
    if locals.trueDate.month == ageStats.birthMonth and locals.trueDate.day == ageStats.birthDay then
        return true
    else
        return false
    end
end

local function getDisplayMonthName(monthIndex)
    local key = string.lower(locals.monthNamesSetting)
    local ret = constants.nonStandardMonthNameMap[monthIndex][key]
    if ret == nil then
        ret = calendar.monthName(monthIndex)
    end
    return ret
end

local function showHolidayMessages()
    calcAge()
    local msgs = constants.holidayMatrix[locals.trueDate.month]
        [tostring(Helpers.zeroPadNumericString(locals.trueDate.day))]
    if msgs ~= nil then
        for _, msg in ipairs(msgs) do
            ui.showMessage(msg)
        end
    end
    if isBirthday() then
        local bmsg = string.gsub(l10n("holiday_desc_birthday"), "{age}", ageStats.fullYears)
        bmsg = string.gsub(bmsg, "{month}", getDisplayMonthName(ageStats.birthMonth))
        bmsg = string.gsub(bmsg, "{sign}", types.Player.birthSigns.records[types.Player.getBirthSign(self)].name)
        bmsg = string.gsub(bmsg, "{chirp}", constants.birthdayChirps[math.random(1, #constants.birthdayChirps)])
        bmsg = string.gsub(bmsg, "{year}", ageStats.birthYear)
        bmsg = string.gsub(bmsg, "{day}", Helpers.ordinalNumber(tonumber(ageStats.birthDay)))
        ui.showMessage(bmsg)
    end
end

local function getBirthMonthFromSign(signId)
    for key, value in pairs(constants.birthSignMonthMap) do
        if Helpers.matchString(string.lower(signId), string.lower(key), 1, true) then return value end
    end
    return nil
end

local function processBirthDay()
    if chargenFinished then
        local birthSign = types.Player.getBirthSign(self)
        local birthMonth = nil
        local birthday = -1
        if birthSign ~= "" then
            birthMonth = getBirthMonthFromSign(birthSign)
            if birthMonth == -1 or birthMonth == nil then -- Serpent moves randomly across the sky, can be any month, and a fallback for unkown signs
                birthMonth = math.random(1, 12)
            end

            if ageStatsDefaults.charBirthdayDay == 0 then -- picking date at random
                birthday = math.random(1, calendar.daysInMonth(birthMonth))
            else
                -- clamping birthday day value, so it's not outside of month length if provided from settings
                birthday = math.min(ageStatsDefaults.charBirthdayDay,
                    calendar.daysInMonth(birthMonth))
            end
        end
        if birthMonth ~= nil then
            ageStats.birthMonth = birthMonth
            ageStats.birthDay = birthday
            SaveData.ageStats = ageStats
        end
        if SaveData.dayOffset then
            calcAge()
        end
    end
end

local function holidayMessageHandler(dt) -- OnUpdate
    if dt > 0 and allowedUpdates then    --not doing the check on pause
        if chargenFinished() then
            -- print("chargen finished")
            if not ageStatsDefaults.chargenAgeStatsSet and not ageUIActive and locals.inExteriorCell then
                -- print("can ask for age")
                ageUIActive = true
                hbui.displayAgeInputWindow()
                -- else
                --     -- print("can't ask for age")
                --     -- print(locals.inExteriorCell)
            end
            if not SaveData.dayOffset then SaveData.dayOffset = 0 end
            if ageStatsDefaults.chargenAgeStatsSet == true and stastIntegrationFinished == false then
                initStatsWindowIntegration()
            end
            local gameHour = tonumber(calendar.formatGameTime("%H"))
            if (gameHour >= locals.displayMessageStart and gameHour <=
                    locals.displayMessageUntil) then
                if locals.dateChanged then
                    showHolidayMessages()
                    if isBirthday() and locals.getBirthDayGifts and not locals.itIsDone then
                        ui.showMessage(l10n("bd_gift_message"))
                        core.sendGlobalEvent("holidays_internal_onBirthday",
                            { actor = self, year = locals.trueDate.year })
                    end
                    locals.dateChanged = false
                end
            end
        end
    end
end


-- local function onKeyPress(key)
--     if key.code == input.KEY.K then
--         print(tostring(locals.statsWindowIndent))
--     end
-- end



local function onTeleported() -- On Teleported
    local oldCell = self.cell
    local newCell = nil
    async:newUnsavableSimulationTimer(0.1,
        function() -- Waiting for simulation to start ticking again so we know we are in the new cell
            locals.inExteriorCell = (self.cell:hasTag("QuasiExterior") or self.cell.isExterior)
            -- newCell = self.cell
            -- print(oldCell.displayName)
            -- print(newCell.displayName)
            -- core.sendGlobalEvent("holidays_internal_onCellChanged",
            --     {
            --         oldCell = { id = oldCell.id, name = oldCell.name },
            --         newCell = { id = newCell.id, name = newCell.name }
            --     })
        end)
end

local function uiAgeStatsSet(t)
    ageStatsDefaults.charStartingAge = t.age
    ageStatsDefaults.charBirthdayDay = t.bd
    ageStatsDefaults.chargenAgeStatsSet = true
    SaveData.ageStatsDefaults = Helpers.table_shallow_copy(ageStatsDefaults)
    ageStats.birthDay = t.bd
    processBirthDay()
end

function OnLoad(data)
    SaveData = data or {}
    initializeSettingsFromStorage()
    if chargenFinished() == true then
        if not SaveData.dayOffset then SaveData.dayOffset = 0 end
        if not SaveData.ageStats then
            processBirthDay()
        end
        ageStats = Helpers.table_shallow_copy(SaveData.ageStats)
        if SaveData.ageStatsDefaults ~= nil then
            ageStatsDefaults = Helpers.table_shallow_copy(SaveData.ageStatsDefaults)
        end
        if SaveData.locals ~= nil then
            locals = Helpers.table_shallow_copy(SaveData.locals)
        end
        locals.inExteriorCell = (self.cell:hasTag("QuasiExterior") or self.cell.isExterior)
    end
    allowedUpdates = true
end

-- onInit - this stuff is called once
function OnInit()
    SaveData = {}
    initializeSettingsFromStorage()
    if chargenFinished() == true then
        processBirthDay()
    end
    allowedUpdates = true
    locals.inExteriorCell = (self.cell:hasTag("QuasiExterior") or self.cell.isExterior)
end

function OnSave()
    SaveData.locals = Helpers.table_shallow_copy(locals)
    SaveData.ageStats = Helpers.table_shallow_copy(ageStats)
    SaveData.ageStatsDefaults = Helpers.table_shallow_copy(ageStatsDefaults)
    return SaveData
end

local function onItIsDone()
    locals.itIsDone = true
end


local function onDaedraNotInterested(princeData)
    ui.showMessage("Prince's statue regards you impassively. You feel you're not likely to get a response. Return on " ..
        Helpers.ordinalNumber(princeData.day) .. " of " .. calendar.monthName(princeData.month) ..
        ". The summoning day of " .. princeData.name .. ". And bring an offering of " .. princeData.offering.name)
end

local function onDaedraNeedOffering(princeData)
    ui.showMessage("You do not have the required offering of " ..
        princeData.offering.name ..
        ". Return on " .. Helpers.ordinalNumber(princeData.day) .. " of " .. calendar.monthName(princeData.month) ..
        ". The summoning day of " .. princeData.name .. ". And bring the offering")
end

local function onOfferingAccepted(princeData)
    ui.showMessage(princeData.name .. " accepts your offering, mortal.")
end

-- local holidayProcessor = nil

-- local function startUpdating()
-- 	holidayProcessor = time.runRepeatedly(dailyUpdater, 1 * time.day, { type = time.GameTime })
-- end

input.registerTriggerHandler(constants.showMessageTriggerKey, async:callback(
    function() showHolidayMessages() end))

storage.playerSection(constants.generalSettingsStorageKey):subscribe(
    async:callback(onSettingsChanged))

storage.playerSection(constants.statsWindowIntegrationStorageKey):subscribe(
    async:callback(onSettingsChanged))

-- startUpdating()

return {
    engineHandlers = {
        onTeleported = onTeleported,
        onUpdate = holidayMessageHandler,
        onLoad = OnLoad,
        onSave = OnSave,
        onInit = OnInit,
        -- onKeyPress = onKeyPress,
    },
    eventHandlers = {
        holidays_internal_receiveDayOffset = getTrueGameDate,
        holidays_internal_uiChargenAgeStatsChanged = uiAgeStatsSet,
        holidays_internal_onItIsDone = onItIsDone,
        holidays_internal_daedraNotInterested = onDaedraNotInterested,
        holidays_internal_daedraNeedOffering = onDaedraNeedOffering,
        holidaysandbirthdays_daedraOfferingAccepted = onOfferingAccepted,
    }
}
