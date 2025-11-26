---@type S3maphorePlaylistEnv
_ENV = _ENV

local TimeSunrise = 6

local TimeSunset = 20

---@type IDPresenceMap
local VvardenfellWildernessRegions = {
	['ascadian isles region'] = true,
	['west gash region'] = true,
	['azura\'s coast region'] = true,
    ['bitter coast region'] = true,
	['grazelands region'] = true,
    ['sheogorad region'] = true,
}

---@type IDPresenceMap
local SixthHouseRegion = {
	['red mountain region'] = true,
}

---@type CellMatchPatterns
local ImpFortMatches = {
    allowed = {
        'buckmoth',
		'gnisis, fort darius',
		'moonmoth',
		'wolverine hall',
		'fort frostmoth',
		'governor\'s hall',
		'fort pelagiad',
		'pelagiad, south wall',
		'pelagiad, north wall',
    },
    disallowed = {
		'mage',
		'figher',
		'cult shrine',
		'imperial shrine',
	},
}

---@type CellMatchPatterns
local DagothUrMatches = {
    allowed = {
        'dagoth ur',
		'akulakhan\'s chamber'
    },
    disallowed = {},
}

---@type CellMatchPatterns
local SewerMatches = {
    allowed = {
        'underworks',
		'sewer',
		'old mournhold',
    },
    disallowed = {},
}

---@type CellMatchPatterns
local TownMatches = {
    allowed = {
        'balmora',
		'caldera',
		'pelagiad',
		'suran',
		'maar gan',
		'raven rock',
		'skaal village',
		'thirsk',
		'ald velothi',
		'dagon fel',
		'gnaar mok',
		'hla oad',
		'khuul',
		'seyda neen',
		'tel fyr',
		'ald-ruhn',
		'sadrith mora',
		'ald\'ruhn',
		'tel vos',
		'vos',
		'tel mora',
		'tel branora',
		'tel aruhn',
		'gnisis',
    },
    disallowed = {
		'mage',
		'figher',
		'shrine',
		'underworks',
		'sewer',
		'mine',
		'old mournhold',
		'fort pelagiad',
		'pelagiad, south wall',
		'governor',
		'pelagiad, north wall',
		'south wall cornerclub',
		'morag tong',
		'balmora, council club',
		'inner',
		'guild of fighters',
		'guild of mages',
		'imperial',
        'suran, desele\'s house of earthly delights',
        'inn',
		'council club',
		'balmora, south wall cornerclub',
		'ald-ruhn, the rat in the pot',
		'sadrith mora, dirty muriel\'s cornerclub',
		'gnaar mok, druegh-jigger\'s rest',
		'balmora, hecerinde\'s house',
		'cornerclub',
		'six fishes',
		'balmora, council club',
		'gnaar mok, nadene rotheran\'s shack',
		'raven rock, bar',
		'hla oad, fatleg\'s drop off',
		'sadrith mora, nevrila areloth\'s house',
		'eight plates',
		'lucky lockup',
		'shenk\'s shovel',
		'flowers of gold',
		'the pilgrim\'s rest',
		'the covenant',
		'plot and plaster',
		'the end of the world',
		'tradehouse',
		'the lizard\'s head',
		'tavern',
		'hole in the wall',
        'trader',
		'clothier',
		'temple',
		'armorer',
		'smith',
		'bookseller',
		'apothecary',
		'outfitter',
		'alchemist',
		'enchanter',
		'healer',
		'pawnbroker',
		'general goods',
		'flowers of gold',
		'club',
	},
}

---@type CellMatchPatterns
local DShrineMatches = {
    allowed = {
        'shrine',
    },
    disallowed = {
		'maar gan',
		'cult',
		'imperial',
		'temple',
		'mamaea',
		'sanit',
		'sanctus',
		'ainab',
		'assemanu',
		'hassour',
		'salmantu',
		'azura',
		'subdun',
		'yakin',
	},
}

---@type CellMatchPatterns
local SixthHouseMatches = {
    allowed = {
		'red mountain region',
        'abinabi',
		'ainab',
		'assemanu',
		'bensamsi',
		'falasmaryon',
		'habunsanit',
		'hassour',
		'kogoruhn',
		'mamaea',
		'endusal',
		'ilunibi',
		'maran-adon',
		'missamsi',
		'odrosal',
		'tureynulal',
		'vemynal',
		'piran',
		'rissun',
		'salmantu',
		'yakin',
		'sanit',
		'sennananit',
		'sharapli',
		'subdun',
		'telasero',
    },
    disallowed = {},
}


---@type CellMatchPatterns
local TribunalMatches = {
    allowed = {
        'vivec',
		'mournhold',
		'temple',
		'maar gan, shrine',
		'vos chapel',
		'ghostgate',
		'molag mar',
		'ministry of truth',
    },
    disallowed = {
		'underworks',
		'sewer',
		'old mournhold',
		'guild of fighters',
		'guild of mages',
		'imperial',
        'trader',
		'clothier',
		'shop',
		'armorer',
		'armory',
		'the winged guar',
		'smith',
		'bookseller',
		'apothecary',
		'hostel',
		'outfitter',
		'the razor hole',
		'alchemist',
		'enchanter',
		'healer',
		'pawnbroker',
		'general goods',
		'flowers of gold',
		'club',
	},
}

---@type CellMatchPatterns
local CastleMatches = {
    allowed = {
        'ebonheart',
		'mournhold, royal palace',
    },
    disallowed = {
		'six fishes',
		'sewer',
		'cave',
		'chapels',
		'mournhold, royal palace: imperial cult services',
	},
}

---@type CellMatchPatterns
local CTongMatches = {
    allowed = {
        'dren plantation',
		'balmora, council club',
		'gnaar mok, nadene rotheran\'s shack',
		'gro-bagrat plantation',
		'arvel',
		'hla oad, fatleg\'s drop off',
		'sadrith mora, nevrila areloth\'s house',
		'vivec, no name club',
    },
    disallowed = {},
}

---@type CellMatchPatterns
local MerchantMatches = {
    allowed = {
        'trader',
		'clothier',
		'armorer',
		'smith',
		'weaponsmith',
		'bookseller',
		'armory',
		'apothecary',
		'outfitter',
		'alchemist',
		'shop',
		'enchanter',
		'healer',
		'pawnbroker',
		'general goods',
		'the razor hole',
    },
    disallowed = {
		'simine fralinie',
	},
}

---@type CellMatchPatterns
local TombBarrowMatches = {
    allowed = {
        'ancestral tomb',
		'barrow',
    },
    disallowed = {},
}

---@type CellMatchPatterns
local TavernMatches = {
    allowed = {
        'suran, desele\'s house of earthly delights',
        'inn',
		'council club',
		'cornerclub',
		'six fishes',
		'eight plates',
		'lucky lockup',
		'shenk\'s shovel',
		'flowers of gold',
		'the pilgrim\'s rest',
		'the covenant',
		'hostel',
		'raven rock, bar',
		'mournhold, the winged guar',
		'plot and plaster',
		'the end of the world',
		'tradehouse',
		'the lizard\'s head',
		'tavern',
		'hole in the wall',
    },
    disallowed = {
		'south wall cornerclub',
		'balmora, council club',
		'inner',
	},
}

---@type CellMatchPatterns
local AshlanderMatches = {
    allowed = {
        'ahemmusa camp',
        'erabenimsun camp',
		'urshilaku camp',
		'zainab camp',
		'holamayan monastery',
		'cavern of the incarnate',
		'shrine of azura',
    },
    disallowed = {},
}

---@type CellMatchPatterns
local FightersGuildMatches = {
    allowed = {
        'guild of fighters',
        'fighter\'s guild',
    },

    disallowed = {},
}

local MagesGuildMatches = {
    allowed = {
        'guild of mages',
        'mage\'s guild',
    },

    disallowed = {},
}

local ThievesGuildCells = {
    allowed = {
		'balmora, south wall cornerclub',
		'ald-ruhn, the rat in the pot',
		'sadrith mora, dirty muriel\'s cornerclub',
		'gnaar mok, druegh-jigger\'s rest',
		'balmora, hecerinde\'s house',
		'vivec, simine fralinie: bookseller',
    },
	disallowed = {},
}

local MoragTongCells = {
    allowed = {
		'sadrith mora, morag tong guild',
		'ald-ruhn, morag tong guildhall',
		'balmora, morag tong guild',
		'vivec, arena hidden area',
		'morag tong guild',
    },
	disallowed = {},
}

local CultCells = {
    allowed = {
		'ebonheart, imperial chapels',
		'fort frostmoth, imperial cult shrine',
		'sadrith mora, wolverine hall: imperial shrine',
		'mournhold, royal palace: imperial cult services',
    },
	disallowed = {},
}

local ShipInteriorCells = {
    allowed = {
		'arrow',
		'grytewake',
		'falvillo\'s endeavor',
		'fair helas',
		'elf-skerring',
		'chun-ook',
		'imperial prison ship',
    },
	disallowed = {
		'barrow'
	},
}

local StrongholdCells = {
    allowed = {
		'andasreth', 
		'berandas',
		'falensarano',
		'hlormaren',
		'indoranyon',
		'marandus',
		'rotheran',
		'valenvaryon',
    },
	disallowed = {
		'sewers',
		'underground',
	},
}

local PlaylistPriority = require 'doc.playlistPriority'

local function VvardenfellWildernessDayClearRule(playback)
    return playback.state.cellIsExterior
		and (playback.state.weather == 'clear' or playback.state.weather == 'cloudy')
        and not playback.rules.region(SixthHouseRegion)
		and playback.rules.timeOfDay(TimeSunrise, TimeSunset)
end

---@type ValidPlaylistCallback
local function ShopRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(MerchantMatches)
end

---@type ValidPlaylistCallback
local function CTongRule(playback)
    return not playback.state.isInCombat
        --and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(CTongMatches)
end

---@type ValidPlaylistCallback
local function ImpFortRule(playback)
    return not playback.state.isInCombat
        --and playback.state.cellIsExterior
        and playback.rules.cellNameMatch(ImpFortMatches)
end

---@type ValidPlaylistCallback
local function FightersGuildRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(FightersGuildMatches)
end

---@type ValidPlaylistCallback
local function MoragTongRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(MoragTongCells)
end

---@type ValidPlaylistCallback
local function TownRule(playback)
    return not playback.state.isInCombat
        and playback.rules.cellNameMatch(TownMatches)
end

---@type ValidPlaylistCallback
local function AshlanderRule(playback)
    return not playback.state.isInCombat
        --and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(AshlanderMatches)
end

---@type ValidPlaylistCallback
local function StrongholdRule(playback)
    return not playback.state.isInCombat
        --and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(StrongholdCells)
end

---@type ValidPlaylistCallback
local function TribunalRule(playback)
    return not playback.state.isInCombat
        --and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(TribunalMatches)
end

---@type ValidPlaylistCallback
local function TavernRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(TavernMatches)
end

---@type ValidPlaylistCallback
local function SwimmingRule(playback)
    return playback.state.isUnderwater
        and playback.state.cellIsExterior
end

local function PCWerewolfVampireNightRule(playback)
	--return (playback.state.self.type.isWerewolf(playback.state.self) or playback.state.self.type.isVampire(playback.state.self))
	return playback.state.self.type.isWerewolf(playback.state.self)
		and playback.state.cellIsExterior
		and not playback.rules.timeOfDay(TimeSunrise, TimeSunset)
end

local function VvardenfellWildernessNightClearNotCursedRule(playback)
	return not playback.rules.timeOfDay(TimeSunrise, TimeSunset) 
		and (playback.state.weather == 'clear' or playback.state.weather == 'cloudy')
		and not playback.state.self.type.isWerewolf(playback.state.self)
		and playback.state.cellIsExterior
		and not playback.rules.region(SixthHouseRegion)
end 

local function VvardenfellWildernessNightOvercastNotCursedRule(playback)
	return not playback.rules.timeOfDay(TimeSunrise, TimeSunset) 
		and (playback.state.weather == 'foggy' or playback.state.weather == 'overcast')
		and not playback.state.self.type.isWerewolf(playback.state.self)
		and playback.state.cellIsExterior
		and not playback.rules.region(SixthHouseRegion)
end 

local function VvardenfellWildernessDayOvercastRule(playback)
	return playback.rules.timeOfDay(TimeSunrise, TimeSunset) 
		and (playback.state.weather == 'foggy' or playback.state.weather == 'overcast')
		and playback.state.cellIsExterior
		and not playback.rules.region(SixthHouseRegion)
end 

local function VvardenfellWildernessDaySnowRule(playback)
	return playback.rules.timeOfDay(TimeSunrise, TimeSunset) 
		and (playback.state.weather == 'snow' or playback.state.weather == 'blizzard')
		and playback.state.cellIsExterior
		and not playback.rules.region(SixthHouseRegion)
end 

local function VvardenfellWildernessNightSnowNotCursedRule(playback)
	return not playback.rules.timeOfDay(TimeSunrise, TimeSunset) 
		and (playback.state.weather == 'snow' or playback.state.weather == 'blizzard')
		and playback.state.cellIsExterior
		and not playback.state.self.type.isWerewolf(playback.state.self)
		and not playback.rules.region(SixthHouseRegion)
end 

local function VvardenfellWildernessNightRainNotCursedRule(playback)
	return not playback.rules.timeOfDay(TimeSunrise, TimeSunset) 
		and (playback.state.weather == 'rain' or playback.state.weather == 'thunder')
		and not playback.state.self.type.isWerewolf(playback.state.self)
		and playback.state.cellIsExterior
		and not playback.rules.region(SixthHouseRegion)
end

local function VvardenfellWildernessDayRainRule(playback)
	return playback.rules.timeOfDay(TimeSunrise, TimeSunset) 
		and (playback.state.weather == 'rain' or playback.state.weather == 'thunder')
		and playback.state.cellIsExterior
		and not playback.rules.region(SixthHouseRegion)
end

---@type ValidPlaylistCallback
local function MagesGuildRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and (
            (
                playback.rules.cellNameMatch(MagesGuildMatches)
            )
        )
end

---@type ValidPlaylistCallback
local function ThievesGuildRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(ThievesGuildCells)
end

---@type ValidPlaylistCallback
local function TombBarrowRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(TombBarrowMatches)
end

---@type ValidPlaylistCallback
local function DagothUrRule(playback)
    return not playback.state.isInCombat
        --and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(DagothUrMatches)
end

---@type ValidPlaylistCallback
local function ShipInteriorRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(ShipInteriorCells)
end

---@type ValidPlaylistCallback
local function daedricTilesetRule(playback)
    return not playback.state.cellIsExterior
		and not Playback.state.isInCombat
		and not playback.rules.cellNameMatch(DShrineMatches)
        and playback.rules.staticExact(Tilesets.Daedric)
end

---@type ValidPlaylistCallback
local function daedricShrineRule(playback)
    return not playback.state.cellIsExterior
		and not Playback.state.isInCombat
        and playback.rules.cellNameMatch(DShrineMatches)
end

---@type ValidPlaylistCallback
local function dwemerStaticRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
		and not playback.rules.cellNameMatch(SixthHouseMatches)
        and playback.rules.staticExact(Tilesets.Dwemer)
end

---@type ValidPlaylistCallback
local function SixthHouseRule(playback)
    return not playback.state.isInCombat
        and playback.rules.cellNameMatch(SixthHouseMatches)
end

---@type ValidPlaylistCallback
local function RedMountainRule(playback)
    return not playback.state.isInCombat
        and playback.rules.region(SixthHouseRegion)
end

---@type ValidPlaylistCallback
local function ImperialCultRule(playback)
    return not playback.state.isInCombat
        and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(CultCells)
end

---@type ValidPlaylistCallback
local function ImperialCastleRule(playback)
    return not playback.state.isInCombat
        --and not playback.state.cellIsExterior
        and playback.rules.cellNameMatch(CastleMatches)
end

---@type ValidPlaylistCallback
local function CaveRule(playback)
    return not playback.state.cellIsExterior
	and not playback.state.isInCombat
        and playback.rules.staticExact(Tilesets.Cave)
end

---@type ValidPlaylistCallback
local function SewerRule(playback)
    return not playback.state.cellIsExterior
		and not playback.state.isInCombat
        and playback.rules.cellNameMatch(SewerMatches)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'Daggerfall Swimming Theme',

        tracks = {
            'Music/DaggerfallRemastered_S3maphore/Swimming/song_fm_swim2.mp3',
        },

        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 3,
        randomize = true,

        isValidCallback = SwimmingRule,
    },
    {
        id = 'Daggerfall Fighters Guild Themes',

        tracks = {
            'Music/DaggerfallRemastered_S3maphore/FightersGuild/song_23.mp3',
        },

        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = FightersGuildRule,
    },
	{
        id = 'Daggerfall Mages Guild Themes',

        tracks = {
            'Music/DaggerfallRemastered_S3maphore/MagesGuild/song_gmage_3.mp3',
			'Music/DaggerfallRemastered_S3maphore/MagesGuild/song_magic_2.mp3',
        },

        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = MagesGuildRule,
    },
	{
        id = 'Daggerfall Sneaking Music',

        tracks = {
            'Music/DaggerfallRemastered_S3maphore/ThievesGuild/song_fsneak2.mp3',
			'Music/DaggerfallRemastered_S3maphore/ThievesGuild/song_sneaking.mp3',
        },

        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = ThievesGuildRule,
    },
	{
        id = 'Daggerfall Sneaking Music 2',

        tracks = {
            'Music/DaggerfallRemastered_S3maphore/MoragTong/song_sneaking2.mp3',
        },

        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = MoragTongRule,
    },
	{
        id = 'Daggerfall Neutral Temple',

        tracks = {
            'Music/DaggerfallRemastered_S3maphore/Ashlander/song_fneut.mp3',
        },

        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = AshlanderRule,
    },
	{
        id = 'Daggerfall Ship Music',

        tracks = {
            'Music/DaggerfallRemastered_S3maphore/InsideShip/song_swimming.mp3',
        },

        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 2,
        randomize = true,

        isValidCallback = ShipInteriorRule,
    },
	{
        id = 'Daggerfall Daedric',
		
        tracks = {
            'Music/DaggerfallRemastered_S3maphore/daedric/song_dungeon8.mp3',
			'Music/DaggerfallRemastered_S3maphore/daedric/song_d5.mp3',
			'Music/DaggerfallRemastered_S3maphore/daedric/song_d3.mp3',
			'Music/DaggerfallRemastered_S3maphore/daedric/song_30.mp3',
        },
		
        priority = PlaylistPriority.Tileset,
        randomize = true,
		
        isValidCallback = daedricTilesetRule,
    },
	{
        id = 'Daggerfall Temple Bad',
		
        tracks = {
            'Music/DaggerfallRemastered_S3maphore/Dungeon/DPrince/song_fbad.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,
		
        isValidCallback = daedricShrineRule,
    },
	{
        id = 'Daggerfall Temple Good',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/ImpCult/song_ggood.mp3',
        },
		
        priority = PlaylistPriority.Faction - 2,
        randomize = true,
		
        isValidCallback = ImperialCultRule,
    },
	{
        id = 'Werewolf or Vampire Night',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Night/VampWere/song_fcurse.mp3',
			'Music/DaggerfallRemastered_S3maphore/Night/VampWere/song_feerie.mp3',
			'Music/DaggerfallRemastered_S3maphore/Night/VampWere/song_fm_nite3.mp3',
        },
		
        priority = PlaylistPriority.Faction - 2,
        randomize = true,
		
        isValidCallback = PCWerewolfVampireNightRule,
    },
	{
        id = 'Daggerfall Clear Day',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Sunny/song_sunnyday.mp3',
			'Music/DaggerfallRemastered_S3maphore/Sunny/song_gsunny2.mp3',
			'Music/DaggerfallRemastered_S3maphore/Sunny/song_fday___d.mp3',
        },		
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		
        isValidCallback = VvardenfellWildernessDayClearRule,
		fallback = {
            playlistChance = 0.50,
            playlists = {
                'Explore'
            },
			tracks = {
				'explore',
			},
        },
    },
	{
        id = 'Daggerfall Clear Night',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Night/song_16.mp3',
			'Music/DaggerfallRemastered_S3maphore/Night/song_18.mp3',
			'Music/DaggerfallRemastered_S3maphore/Night/song_25.mp3',
			'Music/DaggerfallRemastered_S3maphore/Night/song_fruins.mp3',
        },
		
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		
        isValidCallback = VvardenfellWildernessNightClearNotCursedRule,
    },
	{
        id = 'Daggerfall Overcast Night',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Overcast/N/song_12.mp3',
			'Music/DaggerfallRemastered_S3maphore/Overcast/N/song_13.mp3',
        },
		
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		
        isValidCallback = VvardenfellWildernessNightOvercastNotCursedRule,
    },
	{
        id = 'Daggerfall Overcast Day',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Overcast/D/song_29.mp3',
			'Music/DaggerfallRemastered_S3maphore/Overcast/D/song_overcast.mp3',
			'Music/DaggerfallRemastered_S3maphore/Overcast/D/song_overlong.mp3',
        },
		
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		
        isValidCallback = VvardenfellWildernessDayOvercastRule,
    },
	{
        id = 'Daggerfall Rain Night',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Rain/n/song_08fm.mp3',
        },
		
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		
        isValidCallback = VvardenfellWildernessNightRainNotCursedRule,
    },
	{
        id = 'Daggerfall Rain Day',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Rain/d/song_08.mp3',
			'Music/DaggerfallRemastered_S3maphore/Rain/d/song_raining.mp3',
        },
		
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		
        isValidCallback = VvardenfellWildernessDayRainRule,
    },
	{
        id = 'Daggerfall Snow Day',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Snow/D/song_20.mp3',
			'Music/DaggerfallRemastered_S3maphore/Snow/D/song_fsnow__b.mp3',
        },
		
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		
        isValidCallback = VvardenfellWildernessDaySnowRule,
    },
	{
        id = 'Daggerfall Snow Night',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Snow/N/song_oversnow.mp3',
			'Music/DaggerfallRemastered_S3maphore/Snow/N/song_snowing.mp3',
        },
		
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		
        isValidCallback = VvardenfellWildernessNightSnowNotCursedRule,
    },
	{
        id = 'Daggerfall Shop',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Shop/song_gshop.mp3',
        },
		
        priority = PlaylistPriority.Faction - 2,
        randomize = true,
		
        isValidCallback = ShopRule,
    },
	{
        id = 'Daggerfall Tavern',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/tavern/song_folk1.mp3',
			'Music/DaggerfallRemastered_S3maphore/tavern/song_folk2.mp3',
			'Music/DaggerfallRemastered_S3maphore/tavern/song_folk3.mp3',
        },
		
        priority = PlaylistPriority.Faction - 2,
        randomize = true,
		
        isValidCallback = TavernRule,
    },
	{
        id = 'Daggerfall Remastered - Camonna Tong',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/CTong/song_22.mp3',
        },
		
        priority = PlaylistPriority.Faction - 2,
        randomize = true,
		
        isValidCallback = CTongRule,
    },
	{
        id = 'Daggerfall Remastered - Forts',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/fort/song_03.mp3',
			'Music/DaggerfallRemastered_S3maphore/fort/song_15.mp3',
			'Music/DaggerfallRemastered_S3maphore/fort/song_dag_1.mp3',
			'Music/DaggerfallRemastered_S3maphore/fort/song_dag_3.mp3',
        },
		
        priority = PlaylistPriority.Faction - 2,
        randomize = true,
		
        isValidCallback = ImpFortRule,
    },
    {
        id = 'Daggerfall Remastered - Dwemer',
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_04.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_05.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_10.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_21.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_d9.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_d10.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_dag_11.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_dungeon.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_dungeon6.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_fdngn10.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/dwemer/song_fdngn11.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = dwemerStaticRule,
    },
    {
        id = 'Daggerfall Remastered - Tomb',
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/dungeon/tomb/song_d2.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/tomb/song_d6.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/tomb/song_d8.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/tomb/song_dungeon7.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = TombBarrowRule,
    },
    {
        id = 'Daggerfall Remastered - Stronghold',
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/dungeon/stronghold/song_02.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/stronghold/song_09.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/stronghold/song_dag_4.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/stronghold/song_dag_10.mp3',
			'Music/DaggerfallRemastered_S3maphore/dungeon/stronghold/song_dag_12.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = StrongholdRule,
    },
    {
        id = 'Daggerfall Remastered - Towns',
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/town/song_square_2.mp3',
			'Music/DaggerfallRemastered_S3maphore/town/song_tavern.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,

        isValidCallback = TownRule,
		fallback = {
            playlistChance = 0.50,
            playlists = {
                'Explore'
            },
			tracks = {
				'explore',
			},
        },
    },
	{
        id = 'Daggerfall Remastered - Tribunal',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Tribunal/song_d7.mp3',
        },
        priority = PlaylistPriority.Faction - 2,
        randomize = true,
        isValidCallback = TribunalRule,
    },
	{
        id = 'Daggerfall Remastered - Castle',
		
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Palace/song_06.mp3',
			'Music/DaggerfallRemastered_S3maphore/Palace/song_dag_6.mp3',
			'Music/DaggerfallRemastered_S3maphore/Palace/song_dag_9.mp3',
			'Music/DaggerfallRemastered_S3maphore/Palace/song_fpalac.mp3',
        },
        priority = PlaylistPriority.Faction - 2,
        randomize = true,
        isValidCallback = ImperialCastleRule,
    },
    {
        id = 'Daggerfall Remastered - Cave',
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_07.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_28.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_d1.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_d4.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_dungeon5.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_dungeon9.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,
        isValidCallback = CaveRule,
    },
    {
        id = 'Daggerfall Remastered - Sewer',
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_07.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_28.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_d1.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_d4.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_dungeon5.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/MineCave/song_dungeon9.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,
        isValidCallback = SewerRule,
    },
    {
        id = 'Daggerfall Remastered - Sixth House',
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Dungeon/6House/song_fdungn4.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/6House/song_fdungn9.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/6House/song_fm_dngn1.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/6House/song_fm_dngn4.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,
        isValidCallback = SixthHouseRule,
    },
    {
        id = 'Daggerfall Remastered - Red Mountain',
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Dungeon/6House/song_fdungn4.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/6House/song_fdungn9.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/6House/song_fm_dngn1.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/6House/song_fm_dngn4.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,
        isValidCallback = RedMountainRule,
    },
    {
        id = 'Daggerfall Remastered - Dagoth Ur',
        tracks = {
			'Music/DaggerfallRemastered_S3maphore/Dungeon/Ur/song_dag_7.mp3',
			'Music/DaggerfallRemastered_S3maphore/Dungeon/Ur/song_gdungn4.mp3',
        },
        priority = PlaylistPriority.Tileset,
        randomize = true,
        isValidCallback = DagothUrRule,
    },
}
