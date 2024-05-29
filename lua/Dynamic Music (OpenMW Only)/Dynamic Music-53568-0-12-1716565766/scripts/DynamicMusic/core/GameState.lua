local GameState = {}

GameState.exterior = {
    current = nil,
    previous = nil
}

GameState.cellName = {
    current = nil,
    previous = nil
}

GameState.playtime = {
    current = os.time(),
    previous = -1
}

GameState.playerState = {
    current = nil,
    previous = nil
}

GameState.regionName = {
    current = nil,
    previous = nil
}

GameState.soundBank = {
    current = nil,
    previous = nil
}

GameState.track = {
    curent = nil,
    previous = nil
}

GameState.playlist = {
    current = nil,
    previous = nil
}

return GameState
