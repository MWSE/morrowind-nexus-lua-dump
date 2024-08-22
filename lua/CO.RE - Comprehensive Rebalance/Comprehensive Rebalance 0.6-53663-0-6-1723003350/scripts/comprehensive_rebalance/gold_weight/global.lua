local Misc = require('openmw.types').Miscellaneous

local function setGoldWeight(initData)
    local gold = Misc.record('Gold_001')
    if gold then
        print ("Gold weight is " .. tostring(gold.weight))
        gold.weight = 300
    else
        print("Something on this I don't like")
    end
end

local function onLoad(savedData, initData)
    setGoldWeight(savedData)
end

return
{
	engineHandlers =
	{
		onInit = setGoldWeight,
		onLoad = onLoad,
	}
}

