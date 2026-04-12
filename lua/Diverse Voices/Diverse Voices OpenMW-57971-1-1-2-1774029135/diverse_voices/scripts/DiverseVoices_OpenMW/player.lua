local core = require('openmw.core')
local pathutil = require('scripts.DiverseVoices_OpenMW.path')
local voiceMap = require('scripts.DiverseVoices_OpenMW.voicemap')
local common = require('scripts.DiverseVoices_OpenMW.common')

local infoSoundCache = {}
local voiceTypeCache = {}

local function actorKey(actor)
    if not actor then
        return nil
    end
    return tostring(actor.recordId or ''):lower()
end

local function eventKey(e)
    return table.concat({ tostring(e.type), tostring(e.recordId), tostring(e.infoId) }, '|')
end

local function getSoundPathFromDialogue(e)
    local key = eventKey(e)
    local cached = infoSoundCache[key]
    if cached ~= nil then
        return cached or nil
    end

    local bucket = core.dialogue[e.type]
    if not bucket then
        infoSoundCache[key] = false
        return nil
    end

    local record = bucket.records[e.recordId]
    if not record or not record.infos then
        infoSoundCache[key] = false
        return nil
    end

    local wanted = tostring(e.infoId)
    for _, info in pairs(record.infos) do
        if tostring(info.id) == wanted then
            local sound = info.sound
            infoSoundCache[key] = (sound and sound ~= '') and sound or false
            return infoSoundCache[key] or nil
        end
    end

    infoSoundCache[key] = false
    return nil
end

local function getVoiceType(actor)
    local key = actorKey(actor)
    if not key or key == '' then
        return nil
    end

    local cached = voiceTypeCache[key]
    if cached ~= nil then
        return cached or nil
    end

    local value = voiceMap[key]
    voiceTypeCache[key] = value or false
    return value
end

return {
    eventHandlers = {
        DialogueResponse = function(e)
            if e.type ~= 'voice' then
                return
            end

            local actor = e.actor
            if not actor then
                return
            end

            local originalPath = getSoundPathFromDialogue(e)
            if not originalPath then
                return
            end

            local defaultPath = pathutil.resolveDefaultPath(originalPath)
            if not defaultPath then
                return
            end

            local voiceType = getVoiceType(actor)
            local replacementPath = nil

            if voiceType then
                replacementPath = pathutil.resolveVoiceTypePath(originalPath, voiceType)
                if not replacementPath then
                    common.log('Default exists but voicetype replacement missing | actor=%s | voiceType=%s | recordId=%s | infoId=%s | original=%s | attempted=%s',
                        tostring(actor.recordId or 'nil'),
                        tostring(voiceType),
                        tostring(e.recordId),
                        tostring(e.infoId),
                        tostring(originalPath),
                        tostring(pathutil.buildVoiceTypePath(originalPath, voiceType)))
                    return
                end
            else
                replacementPath = defaultPath
            end

            common.log('Replacing voice with fallback flow | actor=%s | voiceType=%s | recordId=%s | infoId=%s | original=%s | default=%s | replacement=%s',
                tostring(actor.recordId or 'nil'),
                tostring(voiceType or 'default'),
                tostring(e.recordId),
                tostring(e.infoId),
                tostring(originalPath),
                tostring(defaultPath),
                tostring(replacementPath))

            actor:sendEvent('DiverseVoices_OpenMW_Play', {
                path = replacementPath,
            })
        end,
    },
}
