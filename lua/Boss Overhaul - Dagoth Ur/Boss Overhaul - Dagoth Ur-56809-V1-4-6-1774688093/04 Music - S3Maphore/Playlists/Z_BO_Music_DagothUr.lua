---@type IDPresenceMap
local BossCell = {
    ['dagoth ur, facility cavern'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'

-- thanks to S3 for actually implementing quest stage checks!

---@type ValidPlaylistCallback
local function PreBoss_CellRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.cellNameExact(BossCell) 
		and not playback.rules.journal { BO_DagothState = { min = 1, max = 10 }}
end

local function Boss_CellRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.cellNameExact(BossCell) 
		and playback.rules.journal { BO_DagothState = { min = 5, max = 5 }}
end

local function PostBoss_Stinger_CellRule(playback)
	return not playback.state.cellIsExterior
        and playback.rules.cellNameExact(BossCell) 
		and playback.rules.journal { BO_DagothState = { min = 10, max = 10 }}
	
end


local function PostBoss_CellRule(playback)
	return not playback.state.cellIsExterior
        and playback.rules.cellNameExact(BossCell) 
		and playback.rules.journal { BO_DagothState = { min = 10, max = 10 }}
end

local function Boss_FinaleRule(playback)
	return not playback.state.cellIsExterior
        and playback.rules.cellNameExact(BossCell) 
		and playback.rules.journal { BO_DagothState = { min = 8, max = 8 }}
end


---@type S3maphorePlaylist[]
return {
    {
        -- 'Music That Plays in the Room while the boss is alive but Friendly'
		id = 'BO/DagothUr/Pre_Boss',
		priority = (PlaylistPriority.Faction - 10),
		randomize = false,
		interruptMode = INTERRUPT.Other,
		
		isValidCallback = PreBoss_CellRule,
    },
	
	{
        -- 'Music That Plays in the Room while the boss is alive but Hostile'
		id = 'BO/DagothUr/Boss',
		priority = PlaylistPriority.BattleMod,
		randomize = false,
		interruptMode = INTERRUPT.Me,
		silenceBetweenTracks = {
			chance = 0,
			max = 0,
			min = 0,
		},
		fadeOut = 0,
		
		isValidCallback = Boss_CellRule,
    },
	
	{
        -- 'Music That Plays in the Room while the boss is alive but Hostile in Final Phase'
		id = 'BO/DagothUr/Boss_FinalPhase',
		priority = (PlaylistPriority.BattleMod - 10),
		randomize = false,
		playOneTrack = false,
		silenceBetweenTracks = {
			chance = 0,
			max = 0,
			min = 0,
		},
		fadeOut = 0,
		
		isValidCallback = Boss_FinaleRule,
    },
	
	{
        -- 'Music That Plays ONCE when boss is defeated'
		id = 'BO/DagothUr/Post_Boss_Stinger',
		priority = (PlaylistPriority.Special),
		randomize = false,
		playOneTrack = true,
		interruptMode = INTERRUPT.Me,
		
		isValidCallback = PostBoss_Stinger_CellRule,
    },
	
	{
        -- 'Music That Plays in room from now on when boss is defeated'
		id = 'BO/DagothUr/Post_Boss',
		priority = (PlaylistPriority.Faction - 20),
		randomize = false,
		playOneTrack = false,

		isValidCallback = PostBoss_CellRule,
    },
	
	
	
	
	
}
