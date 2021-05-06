local this = {}

local RESPONSE_CACHE_MAX_SIZE = 20
local responsesPoolPerNpcCache = {}
local currentCacheIndex = 1
local cachedNpcIds = {}

local function storeResponsesPoolInCache(actorId, responseCandidates)
    if (currentCacheIndex >= RESPONSE_CACHE_MAX_SIZE) then
        currentCacheIndex = 1
        local staleNpcId = cachedNpcIds[currentCacheIndex]
        responsesPoolPerNpcCache[staleNpcId] = nil
    else
        currentCacheIndex = currentCacheIndex + 1
    end

    cachedNpcIds[currentCacheIndex] = actorId
    responsesPoolPerNpcCache[actorId] = table.deepcopy(responseCandidates)
end

local function getResponsesPoolFromCache(actorId)
    return responsesPoolPerNpcCache[actorId]
end

local function invalidate()
    responsesPoolPerNpcCache = {}
    currentCacheIndex = 1
    cachedNpcIds = {}
end

this.storeResponsesPoolInCache = storeResponsesPoolInCache
this.getResponsesPoolFromCache = getResponsesPoolFromCache
this.invalidate = invalidate

return this
