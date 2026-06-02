local M = {}

function M.create(deps)
    local temperatureDebug = assert(deps.temperatureDebug)
    local temperature = assert(deps.temperature)
    local state = assert(deps.state)
    local normalizeKey = assert(deps.normalizeKey)
    local trim = assert(deps.trim)
    local isSeasonalTemperatureVariationsEnabled = assert(deps.isSeasonalTemperatureVariationsEnabled)

    function temperatureDebug.formatSignedNumber(value, decimals)
        local numericValue = tonumber(value) or 0
        local digitCount = math.max(0, math.floor(tonumber(decimals) or 0))
        local formatPattern = '%.' .. tostring(digitCount) .. 'f'
        local absoluteValueText = string.format(formatPattern, math.abs(numericValue))
        if numericValue >= 0 then
            return '+' .. absoluteValueText
        end

        return '-' .. absoluteValueText
    end

    function temperatureDebug.buildDebugOverlayLines(currentState)
        local debugState = currentState or state
        local lines = {
            'Temperature Debug Overlay',
        }
        local seasonLabel = nil
        local seasonalOffset = 0
        local timeOfDayLabel = nil
        local timeOfDaySeasonalOffset = 0
        local cellTypeLabel = nil
        local cellScannedStaticCount = nil
        local cellTopScoreType = nil
        local cellTopScoreValue = 0
        local campfireWarmModifier = 0
        local campfireSourceCount = 0
        local campfireActiveSourceCount = 0
        local campfireNearestDistance = nil
        local campfireNearestRecordId = ''
        local campfireBaseWarmModifier = 0
        local campfireInteriorMultiplier = 1.0
        local campfireScanActivatorScanned = 0
        local campfireScanActivatorMatched = 0
        local campfireScanLightScanned = 0
        local campfireScanLightMatched = 0
        local campfireScanStaticScanned = 0
        local campfireScanStaticMatched = 0
        local campfireScanFailures = {}

        for _, entry in ipairs(debugState.temperatureModifierEntries) do
            if entry.id == 'region' or entry.id == 'interior_base' then
                seasonLabel = normalizeKey(entry.season)
                seasonalOffset = tonumber(entry.seasonalOffset) or 0
                timeOfDayLabel = normalizeKey(entry.timeOfDay)
                timeOfDaySeasonalOffset = tonumber(entry.timeOfDaySeasonalOffset) or 0
            elseif entry.id == 'cell' then
                cellTypeLabel = trim(tostring(entry.cellTypeLabel or entry.cellType or ''))
                cellScannedStaticCount = math.max(0, tonumber(entry.scannedStaticCount) or 0)
                cellTopScoreType = normalizeKey(entry.topScoreType)
                cellTopScoreValue = tonumber(entry.topScoreValue) or 0
            elseif entry.id == 'campfire' then
                campfireWarmModifier = math.max(0, tonumber(entry.warmModifier) or 0)
                campfireSourceCount = math.max(0, tonumber(entry.sourceCount) or 0)
                campfireActiveSourceCount = math.max(0, tonumber(entry.activeSourceCount) or 0)
                campfireNearestDistance = tonumber(entry.nearestDistance)
                campfireNearestRecordId = normalizeKey(entry.nearestRecordId)
                campfireBaseWarmModifier = math.max(0, tonumber(entry.baseWarmModifier) or 0)
                campfireInteriorMultiplier = math.max(0, tonumber(entry.interiorMultiplier) or 1.0)
                campfireScanActivatorScanned = math.max(0, tonumber(entry.scanActivatorScanned) or 0)
                campfireScanActivatorMatched = math.max(0, tonumber(entry.scanActivatorMatched) or 0)
                campfireScanLightScanned = math.max(0, tonumber(entry.scanLightScanned) or 0)
                campfireScanLightMatched = math.max(0, tonumber(entry.scanLightMatched) or 0)
                campfireScanStaticScanned = math.max(0, tonumber(entry.scanStaticScanned) or 0)
                campfireScanStaticMatched = math.max(0, tonumber(entry.scanStaticMatched) or 0)
                if type(entry.scanFailures) == 'table' then
                    campfireScanFailures = entry.scanFailures
                end
            end
            local entryValue = (tonumber(entry.warmModifier) or 0) + (tonumber(entry.coldModifier) or 0)
            lines[#lines + 1] = string.format(
                '%s: %s',
                tostring(entry.label or entry.id or 'Modifier'),
                temperatureDebug.formatSignedNumber(entryValue, 0)
            )
        end

        if cellTypeLabel == nil or cellTypeLabel == '' then
            cellTypeLabel = 'Unknown'
        end
        lines[#lines + 1] = string.format('Cell Type: %s', cellTypeLabel)
        if cellScannedStaticCount ~= nil then
            lines[#lines + 1] = string.format('Cell Objects Scanned: %d', cellScannedStaticCount)
        end
        if cellTopScoreType ~= nil and cellTopScoreType ~= '' and cellTopScoreValue > 0 then
            lines[#lines + 1] = string.format('Cell Score Leader: %s (%d)', cellTopScoreType, math.floor(cellTopScoreValue + 0.5))
        end

        local isNearHeatSource = campfireWarmModifier > 0
            or campfireActiveSourceCount > 0
            or (campfireNearestDistance ~= nil and campfireNearestDistance >= 0)
        lines[#lines + 1] = string.format('Near Heat Source: %s', isNearHeatSource and 'Yes' or 'No')
        lines[#lines + 1] = string.format('Heat Sources: %d active / %d scanned', campfireActiveSourceCount, campfireSourceCount)
        lines[#lines + 1] = string.format('Heat Source Warmth: %s', temperatureDebug.formatSignedNumber(campfireWarmModifier, 1))
        lines[#lines + 1] = string.format('Heat Source Base Warmth: %s', temperatureDebug.formatSignedNumber(campfireBaseWarmModifier, 1))
        lines[#lines + 1] = string.format('Heat Source Interior Multiplier: x%.2f', campfireInteriorMultiplier)
        lines[#lines + 1] = string.format(
            'Heat Scan Activators: %d/%d',
            campfireScanActivatorMatched,
            campfireScanActivatorScanned
        )
        lines[#lines + 1] = string.format(
            'Heat Scan Lights: %d/%d',
            campfireScanLightMatched,
            campfireScanLightScanned
        )
        lines[#lines + 1] = string.format(
            'Heat Scan Statics: %d/%d',
            campfireScanStaticMatched,
            campfireScanStaticScanned
        )
        if type(campfireScanFailures) == 'table' and #campfireScanFailures > 0 then
            lines[#lines + 1] = string.format('Heat Scan Failures: %d', #campfireScanFailures)
            lines[#lines + 1] = string.format('Heat Scan Failure[1]: %s', tostring(campfireScanFailures[1]))
        else
            lines[#lines + 1] = 'Heat Scan Failures: 0'
        end
        if campfireNearestDistance ~= nil and campfireNearestDistance >= 0 then
            lines[#lines + 1] = string.format('Nearest Heat Source Distance: %.1f', campfireNearestDistance)
        else
            lines[#lines + 1] = 'Nearest Heat Source Distance: n/a'
        end
        if campfireNearestRecordId ~= '' then
            lines[#lines + 1] = string.format('Nearest Heat Source ID: %s', campfireNearestRecordId)
        else
            lines[#lines + 1] = 'Nearest Heat Source ID: n/a'
        end

        local seasonText = 'Disabled'
        if isSeasonalTemperatureVariationsEnabled() then
            if seasonLabel ~= nil and seasonLabel ~= '' then
                seasonText = seasonLabel:gsub('(%a)([%w_]*)', function(first, rest)
                    return string.upper(first) .. string.lower(rest)
                end)
            else
                seasonText = 'Unavailable'
            end
        end
        lines[#lines + 1] = string.format('Season: %s', seasonText)
        lines[#lines + 1] = string.format(
            'Seasonal Offset: %s',
            temperatureDebug.formatSignedNumber(seasonalOffset, 0)
        )
        local timeOfDayText = 'Disabled'
        if isSeasonalTemperatureVariationsEnabled() then
            if timeOfDayLabel ~= nil and timeOfDayLabel ~= '' then
                timeOfDayText = timeOfDayLabel:gsub('(%a)([%w_]*)', function(first, rest)
                    return string.upper(first) .. string.lower(rest)
                end)
            else
                timeOfDayText = 'Base Daytime'
            end
        end
        lines[#lines + 1] = string.format('Time Of Day: %s', timeOfDayText)
        lines[#lines + 1] = string.format(
            'Time Of Day Offset: %s',
            temperatureDebug.formatSignedNumber(timeOfDaySeasonalOffset, 0)
        )

        local tickSeconds = tonumber(temperature.system.TEMPERATURE_TICK_SECONDS) or 0
        lines[#lines + 1] = string.format(
            'Tick Rate: %s per tick (every %.2fs, x%.2f multiplier)',
            temperatureDebug.formatSignedNumber(debugState.temperatureCurrentTickAmount, 2),
            tickSeconds,
            tonumber(debugState.temperatureCurrentTickMultiplier) or 1.0
        )
        lines[#lines + 1] = string.format('Total Warm: %s', temperatureDebug.formatSignedNumber(debugState.temperatureTotalWarm, 0))
        lines[#lines + 1] = string.format('Total Cold: %s', temperatureDebug.formatSignedNumber(debugState.temperatureTotalCold, 0))
        lines[#lines + 1] = string.format(
            'Total Target: %s (capped %s)',
            temperatureDebug.formatSignedNumber(debugState.temperatureTotalModifier, 0),
            temperatureDebug.formatSignedNumber(debugState.temperatureCappedModifier, 0)
        )
        lines[#lines + 1] = string.format(
            'Temperature Cap: %s to %s',
            temperatureDebug.formatSignedNumber(temperature.system.TEMPERATURE_MIN, 0),
            temperatureDebug.formatSignedNumber(temperature.system.TEMPERATURE_MAX, 0)
        )

        return lines
    end

    return temperatureDebug
end

return M
