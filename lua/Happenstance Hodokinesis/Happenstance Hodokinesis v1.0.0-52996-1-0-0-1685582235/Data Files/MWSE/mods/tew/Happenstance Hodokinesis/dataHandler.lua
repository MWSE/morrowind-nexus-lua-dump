local dataHandler = {}

local statistic = require("tew.Happenstance Hodokinesis.statistic")

local defaults = {
    aleaUsed = {},
	luckProgress = 0
}

local function initTableValues(data, t)
    for k, v in pairs(t) do
        -- If a field already exists - we initialized the data
        -- table for this character before. Don't do anything.
        if data[k] == nil then
            if type(v) ~= "table" then
                data[k] = v
            elseif v == {} then
                data[k] = {}
            else
                -- Fill out the sub-tables
                data[k] = {}
                initTableValues(data[k], v)
            end
        end
    end
end

local function getData()
    return tes3.player.data.hodokinesis
end

local function flushData(day)
	local aleaUsed = getData().aleaUsed
	for k, _ in pairs(aleaUsed) do
		if k ~= day then
			aleaUsed[k] = nil
		end
	end
end

function dataHandler.initialiseData()
    local data = tes3.player.data
    data.hodokinesis = data.hodokinesis or {}
    local hodokinesisData = data.hodokinesis
    initTableValues(hodokinesisData, defaults)
end

function dataHandler.getUsedPerDay(day)
	flushData(day)
	return getData().aleaUsed[day] or 0
end

function dataHandler.setUsedPerDay(day)
	flushData(day)
	local used = dataHandler.getUsedPerDay(day)
	getData().aleaUsed[day] = used + 1
end

function dataHandler.setLuckProgress(increase)
	local progress = getData().luckProgress
	local current = progress + increase
	if current >= 1.0 then
		statistic.increaseLuck()
		getData().luckProgress = 0
	else
		getData().luckProgress = current
	end
end

return dataHandler