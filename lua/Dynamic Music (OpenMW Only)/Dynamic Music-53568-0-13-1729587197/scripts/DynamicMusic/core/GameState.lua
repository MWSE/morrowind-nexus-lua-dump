local GameState = {}

GameState.hourOfDay = {
    current = nil,
    previous = nil
}
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

GameState.soundbank = {
    current = nil,
    previous = nil
}

return GameState
