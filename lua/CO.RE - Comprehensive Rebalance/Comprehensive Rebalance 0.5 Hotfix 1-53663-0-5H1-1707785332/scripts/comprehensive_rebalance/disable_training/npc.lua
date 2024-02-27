local self = require("openmw.self")

local settings = require("scripts.comprehensive_rebalance.lib.settings")
local NPC = require("openmw.types").NPC

local offersTraining = false
local processed = false
local record = nil
local section = settings.GetSection("char")

--does not work
--servicesOffered is writable but doesn't do anything
--TODO: Update this when they finally add record modification support
local function processTraining()
    local train = offersTraining and not section:get("noTrainers") 
    print ("Setting training settings for " .. tostring(self) .. ' to ' .. tostring(train))
    record.servicesOffered['Training'] = train
end

local function onActive()
    local npc = NPC.objectIsInstance(self)
    if (npc and not processed) then
        record = NPC.record(self)
        if (record) then
            local training = record.servicesOffered['Training']
            offersTraining = training
            processTraining()
        end
    end
    if npc then
    end
    processed = true
end

local function onActivated(actor)
    processTraining()
end

return {
    engineHandlers = {
		onActivated = onActivated,
        onActive = onActive,
	}
}

