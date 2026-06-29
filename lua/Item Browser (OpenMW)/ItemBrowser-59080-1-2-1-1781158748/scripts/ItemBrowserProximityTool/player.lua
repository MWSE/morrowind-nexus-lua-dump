local core = require('openmw.core')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local SETTINGS_SECTION = 'Settings/ItemBrowserProximityTool/1_Tracking'
local FAVORITES_DATA_SECTION = 'ItemBrowser/Favorites'
local TRACKING_GROUP_NAME = '~ItemBrowserFavorites'
local TRACKING_MOD_NAME = 'ItemBrowser'
local HUDM_ICON = 'textures/icons/proximityTool/arrow_P.dds'
local SCAN_INTERVAL = 2

local function trackingSettings()
    return storage.playerSection(SETTINGS_SECTION)
end

local function favoritesData()
    return storage.playerSection(FAVORITES_DATA_SECTION)
end

local activeMarkersByItemId = {}

local function favoriteIds()
    local favorites = favoritesData():get('Favorites') or {}
    local ids = {}
    for id, value in pairs(favorites) do
        if value == true then
            ids[#ids + 1] = id
        end
    end
    return ids
end

local function objectsSignature(objects, name, icon)
    local ids = { tostring(name or ''), tostring(icon or '') }
    for _, object in ipairs(objects or {}) do
        ids[#ids + 1] = tostring(object.id or '')
    end
    table.sort(ids)
    return table.concat(ids, '\n')
end

local function removeTrackingEntry(proximityTool, entry)
    if entry.markerId then
        proximityTool.removeMarker(entry.markerId, entry.markerGroupId)
    end
    if entry.hudmMarkerId then
        proximityTool.removeHUDM(entry.hudmMarkerId)
    end
end

local function clearProximityToolMarkers(proximityTool)
    for itemId, entry in pairs(activeMarkersByItemId) do
        removeTrackingEntry(proximityTool, entry)
        activeMarkersByItemId[itemId] = nil
    end
    proximityTool.removeGroupNameMarkers(TRACKING_GROUP_NAME)
end

local function syncProximityTool()
    local proximityTool = I.proximityTool
    local settings = trackingSettings()

    if not proximityTool then
        activeMarkersByItemId = {}
        return
    end

    if settings:get('TrackFavorites') ~= true then
        clearProximityToolMarkers(proximityTool)
        proximityTool.update()
        proximityTool.updateHUDM()
        return
    end

    local ids = favoriteIds()
    if #ids == 0 then
        clearProximityToolMarkers(proximityTool)
        proximityTool.update()
        proximityTool.updateHUDM()
        return
    end

    local trackContainers = settings:get('TrackContainers') ~= false
    local trackActorInventories = settings:get('TrackActorInventories') == true

    core.sendGlobalEvent('ItemBrowserProximityTool_ScanRequest', {
        favoriteIds = ids,
        trackContainers = trackContainers,
        trackActorInventories = trackActorInventories,
        resolveUnresolvedContainers = settings:get('ResolveUnresolvedContainers') == true,
    })
end

local function applyScanResults(data)
    local proximityTool = I.proximityTool
    if not proximityTool then
        return
    end

    if trackingSettings():get('TrackFavorites') ~= true then
        if next(activeMarkersByItemId) then
            clearProximityToolMarkers(proximityTool)
            proximityTool.update()
            proximityTool.updateHUDM()
        end
        return
    end

    local seen = {}
    local changed = false

    for _, result in ipairs(data and data.results or {}) do
        local id = tostring(result.itemId or '')
        local name = tostring(result.name or id)
        local icon = tostring(result.icon or HUDM_ICON)
        local objects = result.objects or {}
        local signature = objectsSignature(objects, name, icon)
        if id ~= '' and #objects > 0 then
            seen[id] = true
            local entry = activeMarkersByItemId[id]
            if not entry or entry.signature ~= signature then
                if entry then
                    removeTrackingEntry(proximityTool, entry)
                end

                local markerId, markerGroupId = proximityTool.addMarker({
                    objects = objects,
                    groupName = TRACKING_GROUP_NAME,
                    temporary = true,
                    record = {
                        name = name,
                        icon = icon,
                        proximity = 3000,
                        temporary = true,
                    },
                })

                local hudmMarkerId = proximityTool.addHUDM({
                    modName = TRACKING_MOD_NAME,
                    objects = objects,
                    temporary = true,
                    params = {
                        icon = icon,
                        range = 3000,
                        scale = 0.6,
                        bonusSize = 4,
                        offsetMult = 0,
                    },
                })

                activeMarkersByItemId[id] = {
                    markerId = markerId,
                    markerGroupId = markerGroupId,
                    hudmMarkerId = hudmMarkerId,
                    signature = signature,
                }
                changed = true
            end
        end
    end

    for itemId, entry in pairs(activeMarkersByItemId) do
        if not seen[itemId] then
            removeTrackingEntry(proximityTool, entry)
            activeMarkersByItemId[itemId] = nil
            changed = true
        end
    end

    if changed then
        proximityTool.update()
        proximityTool.updateHUDM()
    end
end

local syncTimer = 0
local lastFavoritesRevision
local lastTrackFavorites
local lastTrackContainers
local lastTrackActorInventories
local lastResolveUnresolvedContainers
local lastProximityAvailable

local function updateTrackingSync(dt)
    syncTimer = syncTimer + dt
    if syncTimer < SCAN_INTERVAL then
        return
    end
    syncTimer = 0

    local settings = trackingSettings()
    local favoritesRevision = favoritesData():get('FavoritesRevision') or 0
    local trackFavorites = settings:get('TrackFavorites') == true
    local trackContainers = settings:get('TrackContainers') ~= false
    local trackActorInventories = settings:get('TrackActorInventories') == true
    local resolveUnresolvedContainers = settings:get('ResolveUnresolvedContainers') == true
    local proximityAvailable = I.proximityTool ~= nil

    if favoritesRevision ~= lastFavoritesRevision
        or trackFavorites ~= lastTrackFavorites
        or trackContainers ~= lastTrackContainers
        or trackActorInventories ~= lastTrackActorInventories
        or resolveUnresolvedContainers ~= lastResolveUnresolvedContainers
        or proximityAvailable ~= lastProximityAvailable
        or trackFavorites
    then
        lastFavoritesRevision = favoritesRevision
        lastTrackFavorites = trackFavorites
        lastTrackContainers = trackContainers
        lastTrackActorInventories = trackActorInventories
        lastResolveUnresolvedContainers = resolveUnresolvedContainers
        lastProximityAvailable = proximityAvailable
        syncProximityTool()
    end
end

return {
    engineHandlers = {
        onFrame = updateTrackingSync,
    },
    eventHandlers = {
        ItemBrowserProximityTool_ScanResults = applyScanResults,
    },
}
