---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type IDPresenceMap
local almsiviEnemies = {
    ["almalexia"] = true,
    ["vivec"] = true,
}

---@type ValidPlaylistCallback
local function almsiviEnemyRule()
    return Playback.state.isInCombat
        and Playback.rules.combatTargetExact(almsiviEnemies)
end

---@type CombatTargetTypeMatches
local animalTypes = {
    ['creatures'] = true,
}

---@type ValidPlaylistCallback
local function animalEnemyRule()
    return Playback.state.isInCombat
        and Playback.rules.combatTargetType(animalTypes)
end

---@type IDPresenceMap
local bossFightTargets = {
    ["armion"] = true,
    ["baladas demnevanni"] = true,
    ["barenziah"] = true,
    ["barilzar"] = true,
    ["berserker denmother"] = true,
    ["bolvyn venim"] = true,
    ["captain falx carius"] = true,
    ["carnius magius"] = true,
    ["crescius nasica"] = true,
    ["dagoth araynys"] = true,
    ["dagoth endus"] = true,
    ["dagoth gares"] = true,
    ["dagoth gilvoth"] = true,
    ["dagoth odros"] = true,
    ["dagoth tureynul"] = true,
    ["dagoth uthol"] = true,
    ["dagoth vemyn"] = true,
    ["dandras vules"] = true,
    ["dhaunayne aundae"] = true,
    ["divayth fyr"] = true,
    ["dram bero"] = true,
    ["draugr lord aesliip"] = true,
    ["dreugh warlord"] = true,
    ["eno hlaalu"] = true,
    ["ettiene of glenmoril wyrd"] = true,
    ["gaenor"] = true,
    ["gedna relvel"] = true,
    ["gibbering lunatic"] = true,
    ["golena sadri"] = true,
    ["gothren"] = true,
    ["grurn"] = true,
    ["high draugr priest"] = true,
    ["hound of hircine"] = true,
    ["hrelvesuu"] = true,
    ["karrod"] = true,
    ["khash-ti dhrur"] = true,
    ["king hlaalu helseth"] = true,
    ["larrius varro"] = true,
    ["lightkeeper grahl"] = true,
    ["lord dregas volar"] = true,
    ["marara"] = true,
    ["mastrius"] = true,
    ["menta na"] = true,
    ["molag grunda"] = true,
    ["nomeg gwai"] = true,
    ["orvas dren"] = true,
    ["raxle berne"] = true,
    ["severa magia"] = true,
    ["sjoring hard-heart"] = true,
    ["spirit bear"] = true,
    ["staada"] = true,
    ["tharsten heart-fang"] = true,
    ["the big white wolf"] = true,
    ["the udyrfrykte"] = true,
    ["therana"] = true,
    ["trebonius artorius"] = true,
    ["ulfgar the unending"] = true,
    ["umbra"] = true,
    ["varus vatinius"] = true,
    ["varus vantinius"] = true,
    ["volrina quarra"] = true,
    ["warchief durgoc"] = true,
    ["warchief kurog"] = true,
    ["worm lord"] = true,
    ["wraith of sul-senipul"] = true,
    ["yarnar"] = true,
}

---@type ValidPlaylistCallback
local function bossFightRule()
    return Playback.state.isInCombat
        and Playback.rules.combatTargetExact(bossFightTargets)
end

---@type IDPresenceMap
local corprusEnemies = {
    ["ash ghoul"] = true,
    ["ash poet"] = true,
    ["ash slave"] = true,
    ["ash zombie"] = true,
    ["ascended sleeper"] = true,
    ["blighted game rat"] = true,
    ["blighted kwama forager"] = true,
    ["blighted rat"] = true,
    ["blighted scrib"] = true,
    ["blighted alit"] = true,
    ["blighted cliff racer"] = true,
    ["blighted kagouti"] = true,
    ["blighted kwama warrior"] = true,
    ["blighted kwama worker"] = true,
    ["blighted nix-hound"] = true,
    ["blighted shalk"] = true,
    ["corprus stalker"] = true,
    ["dagoth aladus"] = true,
    ["dagoth baler"] = true,
    ["dagoth daynil"] = true,
    ["dagoth delnus"] = true,
    ["dagoth drals"] = true,
    ["dagoth draven"] = true,
    ["dagoth elam"] = true,
    ["dagoth fals"] = true,
    ["dagoth fandril"] = true,
    ["dagoth felmis"] = true,
    ["dagoth fervas"] = true,
    ["dagoth fovon"] = true,
    ["dagoth galmis"] = true,
    ["dagoth ganel"] = true,
    ["dagoth garel"] = true,
    ["dagoth girer"] = true,
    ["dagoth goral"] = true,
    ["dagoth hlevul"] = true,
    ["dagoth ienas"] = true,
    ["dagoth irvyn"] = true,
    ["dagoth malan"] = true,
    ["dagoth mendras"] = true,
    ["dagoth molos"] = true,
    ["dagoth mulis"] = true,
    ["dagoth mulyn"] = true,
    ["dagoth muthes"] = true,
    ["dagoth nilor"] = true,
    ["dagoth ralas"] = true,
    ["dagoth rather"] = true,
    ["dagoth reler"] = true,
    ["dagoth soler"] = true,
    ["dagoth tanis"] = true,
    ["dagoth ulen"] = true,
    ["dagoth uvil"] = true,
    ["dagoth vaner"] = true,
    ["dagoth velos"] = true,
    ["lame corprus"] = true,
    ["lame corprus "] = true,
}

---@type ValidPlaylistCallback
local function corprusEnemyRule(playback)
    return playback.state.isInCombat
        and playback.rules.combatTargetExact(corprusEnemies)
end

---@type IDPresenceMap
local daedraEnemyNames = {
    ['anhaedra'] = true,
    ['clannfear'] = true,
    ['creeper'] = true,
    ['daedroth'] = true,
    ['dark seducer'] = true,
    ['devourer'] = true,
    ['dremora caitiff'] = true,
    ['dremora kynreeve'] = true,
    ['dremora kynval'] = true,
    ['dremora'] = true,
    ['dremora lord'] = true,
    ['dremora sharpshooter'] = true,
    ['dremora spellcaster'] = true,
    ['famine'] = true,
    ['flame atronach'] = true,
    ['frost  atronach'] = true,
    ['frost atronach'] = true,
    ['herne'] = true,
    ['hunger'] = true,
    ['golden saint'] = true,
    ['iron atronach'] = true,
    ['issma'] = true,
    ['krazzt'] = true,
    ['lustidrike'] = true,
    ['mountain spirit'] = true,
    ['ogrim'] = true,
    ['ogrim titan'] = true,
    ['queen chirsaedo'] = true,
    ['rock chisel clannfear'] = true,
    ['scamp'] = true,
    ['seducer'] = true,
    ['storm atronach'] = true,
    ['storm monarch'] = true,
    ['vermai'] = true,
    ['winged twilight'] = true,
    ['xivilai'] = true,
}

---@type CombatTargetTypeMatches
local daedraTypes = {
    ['daedra'] = true,
}

---@type ValidPlaylistCallback
local function daedraEnemyRule()
    return Playback.state.isInCombat
        and (
            Playback.rules.combatTargetType(daedraTypes)
            or Playback.rules.combatTargetExact(daedraEnemyNames)
        )
end

---@type IDPresenceMap
local DagothurEnemiesEnemyNames = {
    ["dagoth ur"] = true,
    ["heart of lorkhan"] = true,
}

---@type ValidPlaylistCallback
local function endgameRule()
    return Playback.state.isInCombat
        and Playback.rules.combatTargetExact(DagothurEnemiesEnemyNames)
end

---@type ValidPlaylistCallback
local function defaultBattleRule()
    return Playback.state.isInCombat
end

---@type IDPresenceMap
local hircineNames = {
    ["hircine's aspect of guile"] = true,
    ["hircine's aspect of speed"] = true,
    ["hircine's aspect of strength"] = true,
    ["hircine"] = true,
}

---@type ValidPlaylistCallback
local function hircineenemiesEnemyRule()
    return Playback.state.isInCombat
        and Playback.rules.combatTargetExact(hircineNames)
end

---@type IDPresenceMap
local solstheimEnemyNames = {
    ["confused lunatic"] = true,
    ["fearsome grahl"] = true,
    ["horker"] = true,
    ["deadly grahl"] = true,
    ["dire frost atronach"] = true,
    ["draugr"] = true,
    ["draugr berserker"] = true,
    ["draugr champion"] = true,
    ["draugr deathlord"] = true,
    ["draugr huntsman"] = true,
    ["draugr hero"] = true,
    ["draugr plague"] = true,
    ["dragon priest"] = true,
    ["dragon servant"] = true,
    ["draugr shaman"] = true,
    ["draugr sorcerer"] = true,
    ["draugr warlord"] = true,
    ["dulk"] = true,
    ["giant draugr"] = true,
    ["grahl"] = true,
    ["horker pup"] = true,
    ["hulking draugr"] = true,
    ["insane wanderer"] = true,
    ["krish"] = true,
    ["lesser draugr"] = true,
    ["riekling boarmaster"] = true,
    ["riekling raider"] = true,
    ["spectral dragon servant"] = true,
    ["spriggan"] = true,
    ["the good beast"] = true,
    ["the swimmer"] = true,
    ["tusked bristle-piglet"] = true,
    ["tusked bristleback"] = true,
    ["twiggan"] = true,
    ["valbrandr draugr"] = true,
    ["wandering idiot"] = true,
    ["wandering lunatic"] = true,
    ["werewolf"] = true,
    ["werewolf innocent"] = true,
}

---@type string[]
local solstheimMatches = {
    'draugr',
}

---@type ValidPlaylistCallback
local function solstheimEnemyRule()
    return Playback.state.isInCombat
        and (
            Playback.rules.combatTargetExact(solstheimEnemyNames)
            or
            Playback.rules.combatTargetMatch(solstheimMatches)
        )
end

---@type IDPresenceMap
local UndeadEnemyNames = {
    ["advanced centurion spider"] = true,
    ["advanced steam centurion"] = true,
    ["ancestor ghost"] = true,
    ["ancestor guardian"] = true,
    ["areas"] = true,
    ["arenara"] = true,
    ["armor centurion champion"] = true,
    ["armor centurion"] = true,
    ["banshee"] = true,
    ["barrowguard"] = true,
    ["beldoh the undying"] = true,
    ["blade centurion"] = true,
    ["bonelord"] = true,
    ["bonewalker"] = true,
    ["broken dwemer spider"] = true,
    ["calvario"] = true,
    ["centurion archer"] = true,
    ["centurion bomber"] = true,
    ["centurion flyer"] = true,
    ["centurion sphere"] = true,
    ["centurion spiderling"] = true,
    ["centurion spider"] = true,
    ["centurion superspider"] = true,
    ["clasomo"] = true,
    ["crippled skeleton"] = true,
    ["dahrk mezalf"] = true,
    ["damaged centurion spider"] = true,
    ["decayed skeleton"] = true,
    ["draugr housecarl"] = true,
    ["draugr lord"] = true,
    ["draugr tongue"] = true,
    ["dwarven shade"] = true,
    ["dwarven spectre"] = true,
    ["dwemer attack spider"] = true,
    ["dwemer builder"] = true,
    ["dwemer colossus"] = true,
    ["dwemer maintenance spider"] = true,
    ["dwemer surveyor"] = true,
    ["dystonal centurion"] = true,
    ["eloe"] = true,
    ["faded wraith"] = true,
    ["fammana"] = true,
    ["flaming skull"] = true,
    ["frost lich"] = true,
    ["gateway haunt"] = true,
    ["gergio"] = true,
    ["germia"] = true,
    ["ghost guardian"] = true,
    ["ghost of galos heleran"] = true,
    ["ghoul"] = true,
    ["gladroon"] = true,
    ["greater ancestor ghost"] = true,
    ["greater bonelord"] = true,
    ["greater bonewalker"] = true,
    ["greater dwarven spectre"] = true,
    ["greater lich"] = true,
    ["greater plaguebearer bonewalker"] = true,
    ["greater plaguebearer ghost"] = true,
    ["greater skeleton champion"] = true,
    ["hulking fabricant"] = true,
    ["ice wraith"] = true,
    ["igna"] = true,
    ["ildogesto"] = true,
    ["incendia spider"] = true,
    ["irarak"] = true,
    ["iroroon"] = true,
    ["kanit ashurnisammis"] = true,
    ["khajiiti skeleton"] = true,
    ["kjeld"] = true,
    ["knurguri"] = true,
    ["legionnaire skeleton"] = true,
    ["leone"] = true,
    ["lesser bonewalker"] = true,
    ["lich"] = true,
    ["lorurmend"] = true,
    ["lost spirit"] = true,
    ["luminarium spider"] = true,
    ["mace centurion sphere"] = true,
    ["mansilamat vabdas"] = true,
    ["merta"] = true,
    ["mirkrand"] = true,
    ["moranarg"] = true,
    ["mororurg"] = true,
    ["mummy"] = true,
    ["oathbound captain"] = true,
    ["oathbound general"] = true,
    ["oathbound legionnaire"] = true,
    ["pelf"] = true,
    ["plaguebearer bonelord"] = true,
    ["plaguebearer bonewalker"] = true,
    ["plaguebearer ghost"] = true,
    ["plaguebearer lich"] = true,
    ["plaguebearer mummy"] = true,
    ["plaguebearer skeleton champion"] = true,
    ["plaguebearer skeleton"] = true,
    ["plaguebearer skeleton warlord"] = true,
    ["profane acolyte"] = true,
    ["radac stungnthumz"] = true,
    ["reberio"] = true,
    ["repair centurion"] = true,
    ["repair spider"] = true,
    ["rotting draugr"] = true,
    ["scout centurion"] = true,
    ["sentinel centurion"] = true,
    ["shade of woronac"] = true,
    ["shock centurion"] = true,
    ["siri"] = true,
    ["skeletal corpse"] = true,
    ["skeleton archer"] = true,
    ["skeleton assasin"] = true,
    ["skeleton barbarian"] = true,
    ["skeleton berserker"] = true,
    ["skeleton champion"] = true,
    ["skeleton pirate captain"] = true,
    ["skeleton pirate"] = true,
    ["skeleton"] = true,
    ["skeleton warlord"] = true,
    ["skeleton warrior"] = true,
    ["skeleton war-wizard"] = true,
    ["skelton pirate"] = true,
    ["sphere centurion"] = true,
    ["spider centurion"] = true,
    ["steam centurion"] = true,
    ["steam guardian"] = true,
    ["tarerane"] = true,
    ["tickler"] = true,
    ["tragrim"] = true,
    ["vampire stalker"] = true,
    ["vampire"] = true,
    ["verminous fabricant"] = true,
    ["welkynd spirit"] = true,
    ["wormmouth"] = true,
    ["woronac"] = true,
    ["wraith"] = true,
    ["yagrum bagarn"] = true,
    ["zombie"] = true,
}

---@type CombatTargetTypeMatches
local undeadTypes = {
    ['undead'] = true,
}

---@type ValidPlaylistCallback
local function undeadEnemyRule()
    return Playback.state.isInCombat
        and
        (
            Playback.rules.combatTargetType(undeadTypes)
            or Playback.rules.combatTargetExact(UndeadEnemyNames)
        )
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/combat/almsivi',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = almsiviEnemyRule,
    },
    {
        id = 'ms/combat/1animal',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = animalEnemyRule,
    },
    {
        id = 'ms/combat/2bandit',
        priority = PlaylistPriority.BattleVanilla,
        randomize = true,

        isValidCallback = defaultBattleRule,
    },
    {
        id = 'ms/combat/3undead',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = undeadEnemyRule,
    },
    {
        id = 'ms/combat/4daedra',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = daedraEnemyRule,
    },
    {
        id = 'ms/combat/5corprus',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = corprusEnemyRule,
    },
    {
        id = 'ms/combat/6boss fight',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = bossFightRule,
    },
    {
        id = 'ms/combat/dagoth ur',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = endgameRule,
    },
    {
        id = 'ms/combat/hircine',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = hircineenemiesEnemyRule,
    },
    {
        id = 'ms/combat/solstheim',
        priority = PlaylistPriority.BattleMod,
        randomize = true,

        isValidCallback = solstheimEnemyRule,
    },
}
