local ambient = require('openmw.ambient')
local self = require('openmw.self')
local types = require('openmw.types')
local vfs = require('openmw.vfs')

local hostileActors = {}
local soundBanks = {}

local playerStates = {
  combat = 'combat',
  explore = 'explore'
}

local gameState = {
  exterior = {
    current = nil,
    previous = nil
  },
  cellName = {
    current = nil,
    previous = nil
  },
  playtime = {
    current = os.time(),
    previous = -1
  },
  playerState = {
    current = nil,
    previous = nil
  },
  regionName = {
    current = nil,
    previous = nil
  },
  soundBank = {
    current = nil,
    previous = nil
  },
  track = {
    curent = nil,
    previous = nil
  }
}

local SoundBank = {

  trackForPath = function(soundBank, playerState, trackPath)
    local tracks = {}

    if playerState == playerStates.explore then
      tracks = soundBank.tracks
    end

    if playerState == playerStates.combat then
      tracks = soundBank.combatTracks
    end

    for _, track in pairs(tracks) do
      if (track.path == trackPath) then
        return track
      end
    end
  end

}

local cellNameDictionary = nil
local regionNameDictionary = nil

local initialized = false

local currentPlaybacktime = -1
local currentTrackLength = -1

local function countAvailableTracks(soundBank)
  if not soundBank.tracks or #soundBank.tracks == 0 then
    return 0
  end

  local availableTracks = 0

  if soundBank.tracks then
    for _, track in ipairs(soundBank.tracks) do
      if type(track) == "table" then
        track = track.path
      end

      if vfs.fileExists(track) then
        availableTracks = availableTracks + 1
      end
    end
  end

  if soundBank.combatTracks then
    for _, track in ipairs(soundBank.combatTracks) do
      if type(track) == "table" then
        track = track.path
      end

      if vfs.fileExists(track) then
        availableTracks = availableTracks + 1
      end
    end
  end

  return availableTracks
end

--- Collect sound banks.
-- Collects the user defined soundbanks that are stored inside the soundBanks folder
local function collectSoundBanks()
  local soundBanksPath = "scripts/DynamicMusic/soundBanks"
  print("collecting soundBanks from: " .. soundBanksPath)

  for file in vfs.pathsWithPrefix(soundBanksPath) do
    file = file.gsub(file, ".lua", "")
    print("requiring soundBank: " .. file)
    local soundBank = require(file)

    if type(soundBank) == 'table' then
      local availableTracks = countAvailableTracks(soundBank)

      if (availableTracks > 0) then
        if soundBank.tracks then
          for _, t in ipairs(soundBank.tracks) do
            t.path = string.lower(t.path)
          end
        end

        if soundBank.combatTracks then
          for _, t in ipairs(soundBank.combatTracks) do
            t.path = string.lower(t.path)
          end
        end

        table.insert(soundBanks, soundBank)
      else
        print('no tracks available: ' .. file)
      end
    else
      print("not a lua table: " .. file)
    end
  end
end

local function getPlayerState()
  for _, hostileActor in pairs(hostileActors) do
    if types.Actor.isInActorsProcessingRange(hostileActor) then
      return playerStates.combat
    end
  end

  return playerStates.explore
end

--- Returns if the given sondBank is allowed for the given cellname
-- Performs raw checks and does not use the dictionary
-- @param soundBank a soundBank
-- @paran cellName a cellName of type string
-- @returns true/false
local function isSoundBankAllowedForCellName(soundBank, cellName, useDictionary)
  if useDictionary and cellNameDictionary then
    return cellNameDictionary[cellName] and cellNameDictionary[cellName][soundBank]
  end

  if soundBank.cellNamePatternsExclude then
    for _, cellNameExcludePattern in ipairs(soundBank.cellNamePatternsExclude) do
      if string.find(cellName, cellNameExcludePattern) then
        return false
      end
    end
  end

  if soundBank.cellNames then
    for _, allowedCellName in ipairs(soundBank.cellNames) do
      if cellName == allowedCellName then
        return true
      end
    end
  end

  if soundBank.cellNamePatterns then
    for _, cellNamePattern in ipairs(soundBank.cellNamePatterns) do
      if string.find(cellName, cellNamePattern) then
        return true
      end
    end
  end
end

local function isSoundBankAllowedForRegionName(soundBank, regionName, useDictionary)
  if not soundBank.regionNames then
    return false
  end

  if useDictionary and regionNameDictionary then
    return regionNameDictionary[regionName] and regionNameDictionary[regionName][soundBank]
  end

  for _, allowedRegionName in ipairs(soundBank.regionNames) do
    if regionName == allowedRegionName then
      return true
    end
  end

  return false
end

---Check if sound bank is allowed
-- Returns if the specified soundbank is allowed to play in the current ingame situation.
-- @param soundBank the soundbank that should be checked
-- @return true/false
local function isSoundBankAllowed(soundBank)
  if not soundBank then
    return false
  end

  if soundBank.interiorOnly and gameState.exterior.current then
    return false
  end

  if soundBank.exteriorOnly and not gameState.exterior.current then
    return false
  end

  if gameState.playerState.current == playerStates.explore then
    if not soundBank.tracks or #soundBank.tracks == 0 then
      return false
    end
  end

  if gameState.playerState.current == playerStates.combat then
    if not soundBank.combatTracks or #soundBank.combatTracks == 0 then
      return false
    end
  end

  if (soundBank.cellNames or soundBank.cellNamePatterns) and not isSoundBankAllowedForCellName(soundBank, gameState.cellName.current, true) then
    return false
  end

  if soundBank.regionNames and not isSoundBankAllowedForRegionName(soundBank, gameState.regionName.current, true) then
    return false
  end


  return true
end

local function contains(elements, element)
  for _, e in pairs(elements) do
    if (e == element) then
      return true
    end
  end
  return false
end

local function fetchRandomTrack(tracks, options)
  local allowedTracks = tracks

  if options and options.blacklist and #options.blacklist > 0 then
    allowedTracks = {}
    for _, t in pairs(tracks) do
      if not contains(options.blacklist, t) then
        table.insert(allowedTracks, t)
      end
    end
  end

  local rnd = math.random(1, #allowedTracks)
  local track = allowedTracks[rnd]

  return track
end

---Plays another track from an allowed soundbank
-- Chooses a fitting soundbank and plays a track from it
-- If no soundbank could be found a vanilla track is played
local function newMusic()
  print("new music requested")

  local soundBank = nil

  for index = #soundBanks, 1, -1 do
    if isSoundBankAllowed(soundBanks[index]) then
      soundBank = soundBanks[index]
      break
    end
  end

  -- force new music when streammusic was used in the ingame console
  if not ambient.isMusicPlaying() then
    gameState.soundBank.current = nil
  end

  --continue playback if no playerState change happened and the same soundbank should be played again
  if gameState.playerState.current == gameState.playerState.previous then
    if gameState.soundBank.current == soundBank and currentPlaybacktime < currentTrackLength then
      print("skipping new track and continue with current")
      return
    end
  end

  -- no matching soundbank available - switching to default music
  if not soundBank then
    print("no matching soundbank found")

    if gameState.soundBank.current then
      ambient.streamMusic('')
    end

    gameState.track.curent = nil
    currentPlaybacktime = -1
    gameState.soundBank.current = nil
    gameState.track.current = nil
    return
  end

  gameState.soundBank.current = soundBank

  print("fetch track from: " .. soundBank.id)


  -- reusing previous track if trackpath is available
  if gameState.track.previous and gameState.soundBank.current ~= gameState.soundBank.previous then
    local tempTrack = SoundBank.trackForPath(
      gameState.soundBank.current,
      gameState.playerState.current,
      gameState.track.previous.path
    )

    if tempTrack then
      print("resuming existing track from previous " .. gameState.track.previous.path)
      gameState.track.current = tempTrack
      return
    end
  end

  local track = nil
  local tracks = soundBank.tracks

  -- in case of combat situation use combat tracks
  if gameState.playerState.current == playerStates.combat and soundBank.combatTracks then
    tracks = soundBank.combatTracks
  end
  track = fetchRandomTrack(tracks)

  -- if new trackpath == previous trackpath try to fetch a different track
  if #tracks > 1 and (gameState.track.previous and track.path == gameState.track.previous.path or false) then
    print("searching for another track to avoid repeated playback of: " .. gameState.track.previous.path)
    track = fetchRandomTrack(tracks, { blacklist = { track } })
  end

  currentPlaybacktime = 0

  gameState.track.current = track
  if track.length then
    currentTrackLength = track.length
  end

  print("playing track: " .. track.path)
  ambient.stopMusic()
  ambient.streamMusic(track.path)
end

local function hasGameStateChanged()
  if gameState.playerState.previous ~= gameState.playerState.current then
    -- print("change playerState: " ..gameState.playerState.current)
    return true
  end

  if not ambient.isMusicPlaying() then
    -- print("change music not playing")
    return true
  end

  if currentTrackLength > -1 and currentPlaybacktime > currentTrackLength then
    -- print("change trackLength")
    return true
  end

  if gameState.regionName.current ~= gameState.regionName.previous then
    -- print("change regionName")
    return true
  end

  if gameState.cellName.current ~= gameState.cellName.previous then
    -- print("change celName")
    return true
  end

  return false
end

--- Prefetches dictionary.cells
-- Every sondBank is checked agains each cellName and the dictionary is populated if the soundBank is allowed for that cell
-- @param cellNames all cellNames of the game
local function createCellNameDictionary(cellNames, soundBanks)
  local dictionary = {}

  print("prefetching cells")
  for _, cellName in ipairs(cellNames) do
    for _, soundBank in ipairs(soundBanks) do
      if isSoundBankAllowedForCellName(soundBank, cellName, false) then
        local dict = dictionary[cellName]
        if not dict then
          dict = {}
          dictionary[cellName] = dict
        end
        --       print("adding: " ..tostring(soundBank.id) .." to " ..cellName)
        dictionary[cellName][soundBank] = true
      end
    end
  end

  return dictionary
end

local function createRegionNameDictionary(regionNames, soundBanks)
  local dictionary = {}

  print("prefetching regions")
  for _, regionName in ipairs(regionNames) do
    for _, soundBank in ipairs(soundBanks) do
      if isSoundBankAllowedForRegionName(soundBank, regionName, false) then
        local dict = dictionary[regionName]
        if not dict then
          dict = {}
          dictionary[regionName] = dict
        end
        dictionary[regionName][soundBank] = true
      end
    end
  end

  return dictionary
end

local function onFrame(dt)
  gameState.exterior.current = self.cell and self.cell.isExterior
  gameState.cellName.current = self.cell and self.cell.name or ""
  gameState.playtime.current = os.time()
  gameState.regionName.current = self.cell and self.cell.region or ""
  gameState.playerState.current = getPlayerState()

  if currentPlaybacktime > -1 then
    currentPlaybacktime = currentPlaybacktime + (gameState.playtime.current - gameState.playtime.previous)
  end

  if hasGameStateChanged() then
    newMusic()
  end

  gameState.exterior.previous = gameState.cellName.current
  gameState.cellName.previous = gameState.cellName.current
  gameState.playtime.previous = gameState.playtime.current
  gameState.playerState.previous = gameState.playerState.current
  gameState.regionName.previous = gameState.regionName.current
  gameState.soundBank.previous = gameState.soundBank.current
  gameState.track.previous = gameState.track.current
end

local function engaging(eventData)
  if (not eventData.actor) then return end;
  hostileActors[eventData.actor.id] = eventData.actor;
end

local function disengaging(eventData)
  if (not eventData.actor) then return end;
  hostileActors[eventData.actor.id] = nil;
end

local function globalDataCollected(eventData)
  print("collecting global data")
  local data = eventData.data

  if data.cellNames then
    cellNameDictionary = createCellNameDictionary(data.cellNames, soundBanks)
  end

  if data.regionNames then
    regionNameDictionary = createRegionNameDictionary(data.regionNames, soundBanks)
  end

  data = nil
end

local function initialize()
  if not initialized then
    print('initializing playerscript')
    collectSoundBanks()
    initialized = true
  end
end

local function onInit(initData)
  initialize()
end

local function onLoad(initData)
  initialize()
end

return {
  engineHandlers = {
    onFrame = onFrame,
    onInit = onInit,
    onLoad = onLoad
  },
  eventHandlers = {
    engaging = engaging,
    disengaging = disengaging,
    globalDataCollected = globalDataCollected
  },
}
