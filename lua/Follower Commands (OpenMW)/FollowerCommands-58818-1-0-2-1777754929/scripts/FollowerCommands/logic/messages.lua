local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")

local settingsDebug = storage.globalSection("SettingsFollowerCommands_debug")
local l10n = core.l10n("FollowerCommands_messages")

local messages = {}

local function pickRandomMessage(follower, messageType)
    local name = follower.type.records[follower.recordId].name
    local messageOptions = {}
    local i = 1
    while true do
        local msgKey = ("%s_%d"):format(messageType, i)
        local msg = l10n(msgKey, { name = name })
        if msgKey ~= msg then
            messageOptions[#messageOptions+1] = msg
        else
            break
        end
        i = i + 1
    end
    return messageOptions[math.random(#messageOptions)]
end

messages.show = function(player, follower, messageType)
    if not settingsDebug:get("enableMessages") then return end
    
    if type(follower) == "table" then
        local speaker
        for _, actor in ipairs(follower) do
            -- creatures don't speak
            if types.NPC.objectIsInstance(actor) then
                speaker = actor
                break
            end
        end
        if not speaker then
            return
        end
        follower = speaker
        -- creatures don't speak
    elseif types.Creature.objectIsInstance(follower) then
        return
    end

    local msg = pickRandomMessage(follower, messageType)
    player:sendEvent("ShowMessage", { message = msg })
end

return messages
