return {
    -- NPCs with IDs INCLUDING these words are considered guards
    GUARD_PATTERNS = { "guard", "ordinator", "watchman" },
    GUARD_TR_PATTERNS = {},
    GUARD_EXCLUDE_PATTERNS = {},

    -- exempted guards IDs, must be matched
    EXEMPT_IDS = {
        -- ["example_guard_id"] = true,
    },

    -- what is considered a safe place, these words are INCLUDED in IDs
    SAFE_KEYWORDS = {
        "temple",
        "high fane",
        "chapel",
        "tradehouse",
        "cornerclub",
        "council club",
        "garrison",
        "fort",
        "inn",
        "tavern",
        "hostel",
        "hotel",
        "meadhouse",
        "caravanserai",
        "waistwork",
        "the rat in the pot",
        "eight plates",
        "lucky lockup",
        "shenk's shovel",
        "the end of the world",
        "six fishes",
        "tower of dusk",
        "the pilgrim's rest",
        "fara's hole in the wall",
        "desele's house of",
        "plot and plaster",
        "the covenant",
        "no name club",
        "the flowers of gold",
        "the lizard's head",
        "the winged guar",
        "raven rock, bar",
        "the grey lodge",
        "the laughing goblin",
        "limping scrib",
        "the pious pirate",
        "the guar with no name",
        "the dancing cup",
        "moons club",
        "the gentle velk",
        "the howling noose",
        "the queen's cutlass",
        "the red drake",
        "the leaking spore",
        "the musty mudcrub",
        "the swallow's nest",
        "the golden glade",
        "fighting chance",
        "heron hall",
        "the last drop",
        "the hackle-lounge",
        "the merchants's purse",
        "the purple lantern",
        "the fortuna",
        "the rigged challenge",
        "respite",
        "old ebonheart, the empress katariah",
        "old ebonheart, the moth and tiger",
        "old ebonheart, the salty futtocks",
        "port telvannis, the avenue",
        "rayon-ruhn, the dancing jug",
        "sailen, the toiling guar",
        "septim's gate pass, scent of niben",
        "stormgate pass, the saxhleel balladeer",
        "tel gilan, the cliff racer's rest",
        "tel mothrivra, the glass goblet",
        "tel muthada, the note in your eye",
        "tel ouada, the magic mudcrab",
        "verulas pass, twisted root",
        "anvil, the abecette",
        "anvil, the anchor's rest",
        "thresvy, the blind watchtower",
        "anvil, goldenrod house",
        "karthwasten, the dancing saber",
    },
    -- no traveling here despite SAFE_KEYWORDS
    EXCLUDED_CELLS = {
        -- ["some cell name"] = true,
    },

    -- door position overrides: cell name (lowercase) -> array of {x, y, z}
    -- guard walks to the nearest override pos instead of the door position
    -- used when Beautiful cities of Morrowind.ESP is NOT installed
    DOOR_OVERRIDES = {
        ["moonmoth legion fort, interior"] = { { x = -5063, y = -18123, z = 1178 } },
    },

    -- same format, used when Beautiful cities of Morrowind.ESP IS installed
    DOOR_OVERRIDES_BCOM = {
        ["balmora, eight plates"] = { { x = -21661, y = -12069, z = 672 }, { x = -21661, y = -12069, z = 938 } },
        ["moonmoth legion fort, interior"] = { { x = -5063, y = -18123, z = 1178 } },
    },

    -- don't change that
    DEFAULTS = {
        MOD_ENABLED         = true,
        DETECTION_RANGE     = 600,
        DOOR_SCAN_RANGE     = 2000,
        NIGHT_START         = 23,
        NIGHT_END           = 6,
        STRAY_DISTANCE      = 600,
        DOOR_ARRIVAL_DIST   = 250,
        DOOR_STRAY_DIST     = 600,
        CHAMELEON_THRESHOLD = 85,
        SNEAK_THRESHOLD     = 75,
        SIGN_COMPAT         = false,
        DISPOSITION_THRESHOLD = 70,
    },


    MESSAGES = {
        -- 1. Player meets guard at night
        escort_start = {
            guard = {
                "It's late, citizen. Follow me to shelter, I know a place nearby.",
                "Loitering after dark is a crime. Come with me before this gets worse.",
                "The streets aren't safe at this hour. Come, I'll take you somewhere warm.",
                "Halt. Nightfall is no time for wandering. Follow me.",
                "You there! Curfew for the suspicious is in effect. Walk with me, I'll see you to an inn.",
            },
            ordinator = {
                "Outlander. The Holy City does not tolerate vagrants after dark. Follow me.",
                "You tread sacred ground at a forbidden hour. Walk with me. Now.",
                "Foreigners do not wander these streets at night. The Tribunal forbids it. Come.",
                "An outlander, loitering in the sacred city after dark. You test our patience. Follow me.",
                "By the grace of the Tribunal, I will lead you to shelter. Keep up.",
                "Night belongs to the faithful, not to wanderers. Follow me to safety.",
            },
        },

        -- 2. Guard arrived at door with player
        escort_at_door = {
            guard = {
                "Here we are. Get inside.",
                "Here. Get off the street before I change my mind.",
                "This is the place. In you go.",
                "We've arrived. Head indoors, citizen.",
            },
            ordinator = {
                "We have arrived. Enter. Now.",
                "The shelter stands before you. Do not waste my time.",
                "Enter, outlander. Be grateful I did not arrest you.",
                "Inside, outlander. The night is not yours.",
            },
        },

        -- 3. Player entered the door
        escort_arrived = {
            guard = {
                "Good. Stay indoors until morning.",
                "Good. Stay off the streets, outlander. I won't be this kind next time.",
                "Safe at last. Don't let me catch you out again tonight.",
            },
            ordinator = {
                "Inside. Do not leave until the sun rises.",
                "Remain here. The Tribunal does not grant second chances to loiterers.",
                "The Tribunal's mercy has limits. Remain here.",
                "Consider this mercy, outlander. Do not expect it again.",
            },
        },

        -- 4. Player escaped via stealth / chameleon / invisibility
        escort_escaped = {
            guard = {
                "Where did... hmph. Gone.",
                "Huh? The vagran's gone. Whatever, I'll pretend this never happened. Let's go back to patrol.",
                "The vagrant's slipped away. Nothing I can do now.",
            },
            ordinator = {
                "Trickery. The Tribunal sees all, even what I cannot.",
                "Vanished like a fetcher in the night. This is not over.",
                "Cowardly magic. The Temple will remember this.",
                "The outlander flees like a rat. The Temple forgets nothing.",
            },
        },

        -- 5. Player ran away on foot
        escort_fled = {
            guard = {
                "Runner! You'll answer for this.",
                "That's it! You had your chance.",
                "I warned you to stay close.",
                "Running only makes it worse!",
            },
            ordinator = {
                "Your defiance ends here.",
                "An outlander who defies curfew defies the Tribunal itself.",
                "You were warned, outlander.",
                "Flee all you wish. The law follows.",
            },
        },

        -- 6. Morning arrived
        escort_morning = {
            guard = {
                "Dawn's here. You're free to go.",
                "Morning at last. Stay out of trouble.",
                "The night watch is over. Move along, citizen.",
                "Dawn. The curfew is lifted. Try not to cause trouble.",
            },
            ordinator = {
                "The sun rises. You may go for now.",
                "Dawn grants you reprieve, outlander. Do not return at night.",
                "Morning. Do not presume on our mercy again.",
                "The sun spares you, foreigner. Do not loiter here again.",
            },
        },

        -- 7. Arrest resolved (fine paid / jail): guard resumes escort, warns player
        escort_resume = {
            guard = {
                "Try to run again and I won't be so gentle.",
                "Stay with me this time. Next stunt like that, you'll see the inside of a cell.",
                "Keep close. I'm done chasing you tonight.",
                "Follow, and don't try that again. My patience has a limit.",
            },
            ordinator = {
                "Try to flee again, outlander, and the Tribunal's mercy ends.",
                "Your next escape will be your last. Walk. Now.",
                "Defy me once more and you will pray for the mere inconvenience of a fine.",
                "The Temple watches. Run again and you will learn what true punishment is.",
            },
        },
    },
}