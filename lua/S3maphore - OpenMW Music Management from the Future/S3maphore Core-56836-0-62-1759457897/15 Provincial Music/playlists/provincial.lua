---@type S3maphorePlaylistEnv
_ENV = _ENV

local mainlandRegions = {
    ['shipal-shin region'] = true,
    ['alt orethan region'] = true,
    ['lan orethan region'] = true,
    ['mephalan vales region'] = true,
    ['sundered scar region'] = true,
    ['nedothril region'] = true,
    ['padomaic ocean region'] = true,
    ['sea of ghosts region'] = true,
    ['aranyon pass region'] = true,
    ['boethiah\'s spine region'] = true,
    ['dagon urul region'] = true,
    ['molagreahd region'] = true,
    ['sunad mora region'] = true,
    ['telvanni isles region'] = true,
    ['roth roryn region'] = true,
    ['thirr valley region'] = true,
    ['othreleth woods region'] = true,
    ['clambering moor region'] = true,
    ['velothi mountains region'] = true,
    ['uld vraech region'] = true,
}

local skyrimRegions = {
    ['druadach highlands region'] = true,
    ['lorchwuir heath region'] = true,
    ['midkarth region'] = true,
    ['vorndgad forest region'] = true,
    ['sundered hills region'] = true,
    ['solitude forest region'] = true,
    ['vaalstag highlands region'] = true,
    ['grey plains region'] = true,
    ['kilkreath mountains region'] = true,
}

local solstheimRegions = {
    ['brodir grove region'] = true,
    ['felsaad coast region'] = true,
    ['hirstaang forest region'] = true,
    ['isinfier plains region'] = true,
    ['moesring mountains region'] = true,
    ['thirsk region'] = true,
}

local cyrodiilRegions = {
    ['abecean sea region'] = true,
    ['dasek marsh region'] = true,
    ['gilded hills region'] = true,
    ['gold coast region'] = true,
    ['stirk isle region'] = true,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 's3/explore/cyrodiil',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat and cyrodiilRegions[Playback.state.self.cell.region]
        end,
    },
    {
        id = 's3/explore/skyrim',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat and skyrimRegions[Playback.state.self.cell.region]
        end,
    },
    {
        id = 's3/explore/mainland',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat and mainlandRegions[Playback.state.self.cell.region]
        end,
    },
    {
        id = 's3/explore/solstheim',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat and solstheimRegions[Playback.state.self.cell.region]
        end,
    },
    {
        id = 's3/battle/cyrodiil',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = function()
            return Playback.state.isInCombat and cyrodiilRegions[Playback.state.self.cell.region]
        end,
    },
    {
        id = 's3/battle/skyrim',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = function()
            return Playback.state.isInCombat and skyrimRegions[Playback.state.self.cell.region]
        end,
    },
    {
        id = 's3/battle/mainland',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = function()
            return Playback.state.isInCombat and mainlandRegions[Playback.state.self.cell.region]
        end,
    },
    {
        id = 's3/battle/solstheim',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = function()
            return Playback.state.isInCombat and solstheimRegions[Playback.state.self.cell.region]
        end,
    },
}
