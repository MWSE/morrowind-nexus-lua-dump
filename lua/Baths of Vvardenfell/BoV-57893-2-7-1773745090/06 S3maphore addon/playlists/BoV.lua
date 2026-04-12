---@type IDPresenceMap
local BoVCells = {
    ['Ald-ruhn, Public Bath'] = true,
    ['Balmora, Public Bath'] = true,
    ['Caldera, Public Bath'] = true,
    ['Dagon Fel, Public Bath: Sauna'] = true,
    ['Gnisis, Public Bath'] = true,
    ['Maar Gan, Public Bath: Cenote'] = true,
    ['Molag Mar, Public Bath'] = true,
    ['Mounhold, Public Bath'] = true,
    ['Mournhold, Healing Bath: Chaning Rooms'] = true,
    ['Odai Mudbaths'] = true,
    ['Suran, Public Bath'] = true,
    ['Tel Aruhn, Public Bath'] = true,
    ['Tel Branora, Public Bath'] = true,
    ['Tel Mora, Public Bath'] = true,
    ['Vivec, Foraign Quarter Public Bath'] = true,
    ['Vivec, Hlaalu Bath'] = true,
    ['Vivec, Redoran Bath'] = true,
    ['Vivec, Telvanni Public Bath'] = true,
    ['Vos, Public Bath'] = true,
}

local function BoVRule(playback)
    return playback.rules.cellNameExact(BoVCells)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/baths',
        priority = PlaylistPriority.CellExact,

        isValidCallback = BoVRule,
    }
}