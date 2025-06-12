---@type IDPresenceMap
local SixthHouseEnemies = {
    ['ascended sleeper'] = true,
    ['ash ghoul'] = true,
    ['ash slave'] = true,
    ['ash zombie'] = true,
    ['corprus stalker'] = true,
    ['lame corprus'] = true,
    ['dagoth fandril'] = true,
    ['dagoth molos'] = true,
    ['dagoth felmis'] = true,
    ['dagoth rather'] = true,
    ['dagoth garel'] = true,
    ['dagoth reler'] = true,
    ['dagoth goral'] = true,
    ['dagoth tanis'] = true,
    ['dagoth hlevul'] = true,
    ['dagoth uvil'] = true,
    ['dagoth malan'] = true,
    ['dagoth vaner'] = true,
    ['dagoth ulen'] = true,
    ['dagoth irvyn'] = true,
    ['dagoth aladus'] = true,
    ['dagoth fovon'] = true,
    ['dagoth baler'] = true,
    ['dagoth girer'] = true,
    ['dagoth daynil'] = true,
    ['dagoth delnus'] = true,
    ['dagoth mendras'] = true,
    ['dagoth drals'] = true,
    ['dagoth mulis'] = true,
    ['dagoth draven'] = true,
    ['dagoth muthes'] = true,
    ['dagoth elam'] = true,
    ['dagoth nilor'] = true,
    ['dagoth fervas'] = true,
    ['dagoth ralas'] = true,
    ['dagoth soler'] = true,
    ['dagoth fals'] = true,
    ['dagoth galmis'] = true,
    ['dagoth ganel'] = true,
    ['dagoth mulyn'] = true,
    ['dagoth gares'] = true,
    ['dagoth velos'] = true,
    ['dagoth araynys'] = true,
    ['dagoth endus'] = true,
    ['dagoth gilvoth'] = true,
    ['dagoth odroth'] = true,
    ['dagoth tureynul'] = true,
    ['dagoth uthol'] = true,
}

---@type IDPresenceMap
local GenericDagoth = {
    'dagoth',
}

---@type IDPresenceMap
local DagothUr = {
    ['dagoth ur'] = true,
}

---@type ValidPlaylistCallback
local function sixthHouseEnemyRule(playback)
    return playback.state.isInCombat
        and (
            playback.rules.combatTargetExact(SixthHouseEnemies) or playback.rules.cellNameMatch(GenericDagoth)
        )
end

---@type ValidPlaylistCallback
local function theManHimselfRule(playback)
    return playback.state.isInCombat
        and playback.rules.combatTargetExact(DagothUr)
end

---@type IDPresenceMap
local SixthHouseCells = {
    ['abinabi'] = true,
    ['ainab'] = true,
    ['ainab, shrine'] = true,
    ['assemanu'] = true,
    ['assemanu, shrine'] = true,
    ['bensamsi'] = true,
    ['dagoth ur, facility cavern'] = true,
    ['dagoth ur, inner facility'] = true,
    ['dagoth ur, inner tower'] = true,
    ['dagoth ur, lower facility'] = true,
    ['dagoth ur, outer facility'] = true,
    ['endusal, kagrenac\'s study'] = true,
    -- ['erabenimsun camp, ainab\'s yurt'] = true,
    ['falasmaryon, lower level'] = true,
    ['falasmaryon, missun akin\'s hut'] = true,
    ['falasmaryon, propylon chamber'] = true,
    ['falasmaryon, sewers'] = true,
    ['falasmaryon, upper level'] = true,
    ['habunsanit'] = true,
    ['hassour'] = true,
    ['hassour, shrine'] = true,
    -- ['hlerynhul, mausur yakinusha\'s apartment'] = true,
    ['kogoruhn, bleeding heart'] = true,
    ['kogoruhn, charma\'s breath'] = true,
    ['kogoruhn, dome of pollock\'s eve'] = true,
    ['kogoruhn, dome of urso'] = true,
    ['kogoruhn, hall of maki'] = true,
    ['kogoruhn, hall of phisto'] = true,
    ['kogoruhn, hall of the watchful touch'] = true,
    ['kogoruhn, nabith waterway'] = true,
    ['kogoruhn, temple of fey'] = true,
    ['kogoruhn, vault of aerode'] = true,
    ['mamaea, sanctum of awakening'] = true,
    ['mamaea, sanctum of black hope'] = true,
    ['mamaea, shrine of pitted dreams'] = true,
    ['maran-adon'] = true,
    ['missamsi'] = true,
    ['odrosal, dwemer training academy'] = true,
    ['odrosal, tower'] = true,
    ['piran'] = true,
    ['piransulit'] = true,
    ['piransunabi grotto'] = true,
    ['rissun'] = true,
    ['salmantu'] = true,
    ['salmantu, shrine'] = true,
    ['sanit'] = true,
    ['sanit, shrine'] = true,
    ['sennananit'] = true,
    ['sharapli'] = true,
    ['subdun'] = true,
    ['subdun, shrine'] = true,
    ['telasero, dome'] = true,
    ['telasero, lower level'] = true,
    ['telasero, propylon chamber'] = true,
    ['telasero, upper level'] = true,
    ['tureynulal, bladder of clovis'] = true,
    ['tureynulal, eye of duggan'] = true,
    ['tureynulal, eye of thom wye'] = true,
    ['tureynulal, kagrenac\'s library'] = true,
    ['vemynal, hall of torque'] = true,
    ['vemynal, outer fortress'] = true,
    ['yakin'] = true,
    ['yakin, shrine'] = true,
}

---@type ValidPlaylistCallback
local function sixthHouseCellRule(playback)
    return not playback.state.isInCombat
        and playback.rules.cellNameExact(SixthHouseCells)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        -- 'MUSE - Sixth House Dungeons',
        id = 'ms/cell/6thhouse',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = sixthHouseCellRule,
    },
    {
        -- 'MUSE - Sixth House Enemies',
        id = 'ms/combat/dagoth',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = sixthHouseEnemyRule,
    },
    -- NOTE: Due to having higher registration order, Dagoth Ur playlist will beat out regular-dagoth playlist
    {
        -- 'MUSE - Sixth House Enemies',
        id = 'ms/combat/dagoth ur',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = sixthHouseEnemyRule,
    },
}
