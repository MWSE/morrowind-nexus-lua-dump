---@type CellMatchPatterns
local TempleCellNames = {
    allowed = {
        'vivec',
        'almas thirr',
        'necrom',
        'molag mar',
        'ghostgate',
		'holamayan monastery'
    }
}

local TempleCombatTargets = {
	['ordinator'] = true,
	['high ordinator'] = true,
	['salas valor'] = true,
	['fedris hler'] = true,
	['hand arnas therethi'] = true,
	['hand drals indobar'] = true,
	['hand sadas mavandes'] = true,
	['hand savor hlan'] = true,
	['hand vonos veri'] = true,
	['gavas drin'] = true,
	['tholer saryoni'] = true,
	['tuls valen'] = true,
	['feldrelo sadri'] = true,
	['uvoo llaren'] = true,
	['tharer rotheloth'] = true,
	['endryn llethan'] = true,
	['ordinator in mourning'] = true,
	['alvu sareleth'] = true,
	['muran samarys'] = true,
	['lloris dalan'] = true,
	['illene teloth'] = true,
	['vaden baro'] = true,
	['nalvs andolin'] = true,
	['nivis serethran'] = true,
	['dram marvos'] = true,
	['aeyne redothril'] = true,
	['ano forondas'] = true,
	['chavana emalur'] = true,
	['milara orvayn'] = true,
	['ratagos'] = true,

}

---@type ValidPlaylistCallback
local function templeCellRule()
    return not Playback.state.isInCombat
        and Playback.rules.cellNameMatch(TempleCellNames)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/temple',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = templeCellRule,

    },
	{
        id = 'ms/combat/temple',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = function(playback)
            return playback.state.isInCombat
                and playback.rules.combatTargetExact(TempleCombatTargets)
        end,
    }
}
