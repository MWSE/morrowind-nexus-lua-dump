---@type IDPresenceMap
local IncarnateCells = {
    ['cavern of the incarnate'] = true,
}

---@type ValidPlaylistCallback
local function incarnateCellRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.cellNameExact(IncarnateCells)
end

---@type S3maphorePlaylist[]
return {
    {
        -- 'MUSE - Cavern of the Incarnate',
        id = 'ms/cell/incarnate',
        priority = 50,
        noInterrupt = true,
        randomize = true,

        isValidCallback = incarnateCellRule,
    },
}
