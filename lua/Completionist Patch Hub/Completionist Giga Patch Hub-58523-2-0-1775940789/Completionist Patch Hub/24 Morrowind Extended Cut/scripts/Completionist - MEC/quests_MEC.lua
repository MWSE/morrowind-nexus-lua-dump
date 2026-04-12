local self = require('openmw.self')
local quests = {
    {
        id = "CS_MethasHlaalu",
        name = "Kill Traven Morvos",
        category = "House Hlaalu Quests",
        subcategory = "Side Quest",
        master = "Morrowind Extended Cut",
        text = "Handle a House Hlaalu matter."
    },

    {
        id = "CS_FightersGuy",
        name = "Expelled Friend",
        category = "Fighters Guild Quests",
        subcategory = "Side Quest",
        master = "Morrowind Extended Cut",
        text = "Help a friend of the Fighters Guild."
    },

    {
        id = "MT_WritBemis",
        name = "Morag Tong: Writ for Mathyn Bemis",
        category = "Morag Tong Quests",
        subcategory = "Writs",
        master = "Morrowind Extended Cut",
        text = "Carry out a Morag Tong writ."
    },

    {
        id = "CS_Neloth",
        name = "Morag Tong: Writ for Master Neloth",
        category = "Morag Tong Quests",
        subcategory = "Writs",
        master = "Morrowind Extended Cut",
        text = "Carry out a Morag Tong writ."
    },

    {
        id = "CS_Maggots",
        name = "Maggots and Graverobbers",
        category = "Miscellaneous",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Look into a troubling matter."
    },

    {
        id = "CS_CTDecisionEmpire",
        name = "The Empire And Us",
        category = "Camonna Tong Quests",
        subcategory = "Decisions",
        master = "Morrowind Extended Cut",
        text = "Decide how to advance the Camonna Tong's plans."
    },

    {
        id = "CS_CTBonusKillDuke",
        name = "The Duke Must Die",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CTDecisionSlave",
        name = "A Question Of Freedom",
        category = "Camonna Tong Quests",
        subcategory = "Decisions",
        master = "Morrowind Extended Cut",
        text = "Decide how to advance the Camonna Tong's plans."
    },

    {
        id = "CS_CTDecisionStart",
        name = "The Puppet Master",
        category = "Camonna Tong Quests",
        subcategory = "Decisions",
        master = "Morrowind Extended Cut",
        text = "Decide how to advance the Camonna Tong's plans."
    },

    {
        id = "CS_CTBonusHortator",
        name = "Vonos and the Hortator",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CTDecisionGoal",
        name = "The Plan",
        category = "Camonna Tong Quests",
        subcategory = "Decisions",
        master = "Morrowind Extended Cut",
        text = "Decide how to advance the Camonna Tong's plans."
    },

    {
        id = "CS_CTPromotion",
        name = "Have You Heard Of Me?",
        category = "Camonna Tong Quests",
        subcategory = "Advancement",
        master = "Morrowind Extended Cut",
        text = "Advance your standing with the Camonna Tong."
    },

    {
        id = "CS_CTBonusHH1",
        name = "House Hlaalu: Velanda Omani",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle a House Hlaalu affair."
    },

    {
        id = "CS_CTBonusHH2",
        name = "House Hlaalu: Kill the Smuggler",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle a House Hlaalu affair."
    },

    {
        id = "CS_CTBonusHH3",
        name = "House Hlaalu: Raiding Indarys Manor",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle a House Hlaalu affair."
    },

    {
        id = "CS_CTBonusHH4",
        name = "House Hlaalu: Raiding Tel Uvirith",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle a House Hlaalu affair."
    },

    {
        id = "HH_BankFraud",
        name = "House Hlaalu: Sealed Orders",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle a House Hlaalu affair."
    },

    {
        id = "CS_CTBonusFG",
        name = "A Little Task From Orvas",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CTBonusHH",
        name = "House Hlaalu: Becoming The Grandmaster",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle a House Hlaalu affair."
    },

    {
        id = "CS_CTBonusMT",
        name = "A Conflict of Interest",
        category = "Camonna Tong Quests",
        subcategory = "Allied Operations",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CTWanted",
        name = "A Fool's Path",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CTArmor",
        name = "The Armor of the Camonna Tong",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT01",
        name = "Bad Business",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT02",
        name = "I've Made A Mistake",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT03",
        name = "Unique Set Of Skills",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT04",
        name = "Are You A Spy?",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT05",
        name = "Little Help Here?",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT06",
        name = "A Friend Of The Duke",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT07",
        name = "Hlaalu Informant",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT08",
        name = "A Friend Of A Friend",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT09",
        name = "Your Hands Are Tied",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT10",
        name = "Pushing The Line",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT11",
        name = "Retaliation",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT12",
        name = "Starve The Enemy",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT13",
        name = "Supply And Demand",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT14",
        name = "The Rival",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT15",
        name = "Who's Responsible?",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT16",
        name = "Vendetta",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT17",
        name = "Who is Larrius Varro?",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT18",
        name = "Bloodbath",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT19",
        name = "Two Sides Opposed",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT20",
        name = "The Imperial Knight",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT21",
        name = "Knight Slayer",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT22",
        name = "Salt In The Wound",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT23",
        name = "Criminal Trade",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT24",
        name = "Some Nerve",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT25",
        name = "You Again?",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT26",
        name = "An Old-Fashioned Prison Break",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT27",
        name = "Within?",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT28",
        name = "Associates of Traitors",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT29",
        name = "An Example",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT30",
        name = "From The Shadows",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT31",
        name = "A Deal With The Daedra",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT32",
        name = "The Truth",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT33",
        name = "The Raven and the Summoning",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT34",
        name = "Manipulating the Ienith",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_CT35",
        name = "Ascension",
        category = "Camonna Tong Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Handle Camonna Tong business."
    },

    {
        id = "CS_TG01",
        name = "The Camonna Tong Will Fall!",
        category = "Thieves Guild Quests",
        subcategory = "Camonna Tong Conflict",
        master = "Morrowind Extended Cut",
        text = "Work with the Thieves Guild against the Camonna Tong."
    },

    {
        id = "CS_TG02",
        name = "What about the Thieves Guild?",
        category = "Thieves Guild Quests",
        subcategory = "Camonna Tong Conflict",
        master = "Morrowind Extended Cut",
        text = "Work with the Thieves Guild against the Camonna Tong."
    },

    {
        id = "CS_TG03",
        name = "Victory for the Thieves Guild",
        category = "Thieves Guild Quests",
        subcategory = "Camonna Tong Conflict",
        master = "Morrowind Extended Cut",
        text = "Work with the Thieves Guild against the Camonna Tong."
    },

    {
        id = "CS_WC1",
        name = "Mages Guild: The Worm Lord",
        category = "Mages Guild Quests",
        subcategory = "Worm Cult",
        master = "Morrowind Extended Cut",
        text = "Assist the Mages Guild with a dangerous matter."
    },

    {
        id = "CS_WC2",
        name = "Mages Guild: The Warp in the West",
        category = "Mages Guild Quests",
        subcategory = "Worm Cult",
        master = "Morrowind Extended Cut",
        text = "Assist the Mages Guild with a dangerous matter."
    },

    {
        id = "CS_WC4",
        name = "Mages Guild: The Bloodworm Helm",
        category = "Mages Guild Quests",
        subcategory = "Worm Cult",
        master = "Morrowind Extended Cut",
        text = "Assist the Mages Guild with a dangerous matter."
    },

    {
        id = "CS_WC5",
        name = "Mages Guild: God of Worms",
        category = "Mages Guild Quests",
        subcategory = "Worm Cult",
        master = "Morrowind Extended Cut",
        text = "Assist the Mages Guild with a dangerous matter."
    },

    {
        id = "CS_WC3",
        name = "Mages Guild: King of Worms",
        category = "Mages Guild Quests",
        subcategory = "Worm Cult",
        master = "Morrowind Extended Cut",
        text = "Assist the Mages Guild with a dangerous matter."
    },

    {
        id = "CS_DBSithisTenants",
        name = "The Five Tenants",
        category = "Dark Brotherhood Quests",
        subcategory = "Sithis Path",
        master = "Morrowind Extended Cut",
        text = "Pursue the Dark Brotherhood."
    },

    {
        id = "CS_DBSithisBlades",
        name = "The Blades and the Black Hand of Sithis",
        category = "Dark Brotherhood Quests",
        subcategory = "Sithis Path",
        master = "Morrowind Extended Cut",
        text = "Pursue the Dark Brotherhood."
    },

    {
        id = "CS_DBSithisEnd",
        name = "Welcome to the Dark Brotherhood",
        category = "Dark Brotherhood Quests",
        subcategory = "Sithis Path",
        master = "Morrowind Extended Cut",
        text = "Pursue the Dark Brotherhood."
    },

    {
        id = "CS_DBMythicEnd",
        name = "The Eastern Mythic Dawn",
        category = "Brotherhood Quests",
        subcategory = "Endings and Choices",
        master = "Morrowind Extended Cut",
        text = "Choose the fate of the Brotherhood."
    },

    {
        id = "CS_DBSecretEnd",
        name = "The Return of the Morag Tong",
        category = "Brotherhood Quests",
        subcategory = "Endings and Choices",
        master = "Morrowind Extended Cut",
        text = "Choose the fate of the Brotherhood."
    },

    {
        id = "CS_DBChaosEnd",
        name = "The Collapse of the Vvardenfell Brotherhood",
        category = "Brotherhood Quests",
        subcategory = "Endings and Choices",
        master = "Morrowind Extended Cut",
        text = "Choose the fate of the Brotherhood."
    },

    {
        id = "CS_DBChoice",
        name = "Vvardenfell Brotherhood: To Sithis or Dagon",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DBBelt",
        name = "Hrordis: Magic Belt",
        category = "Brotherhood Quests",
        subcategory = "Endings and Choices",
        master = "Morrowind Extended Cut",
        text = "Choose the fate of the Brotherhood."
    },

    {
        id = "CS_DB10",
        name = "Vvardenfell Brotherhood: Only Good Dead",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB11",
        name = "Vvardenfell Brotherhood: Informants Inform",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB12",
        name = "Vvardenfell Brotherhood: Rude Interruption",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB13",
        name = "Vvardenfell Brotherhood: Clear His Name",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB14",
        name = "Vvardenfell Brotherhood: Our Ultimatum",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB15",
        name = "Vvardenfell Brotherhood: Not At All Sorry",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB16",
        name = "Vvardenfell Brotherhood: To Court A Murderer",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB17",
        name = "Vvardenfell Brotherhood: Avenge the Mythic Dawn",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB18",
        name = "Vvardenfell Brotherhood: Find Her",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB19",
        name = "Vvardenfell Brotherhood: The Apprentice",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB20",
        name = "Vvardenfell Brotherhood: Helping Hand",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB21",
        name = "Vvardenfell Brotherhood: A Great Gift",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB22",
        name = "Vvardenfell Brotherhood: Conversion",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB23",
        name = "Vvardenfell Brotherhood: The Traitor",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB24",
        name = "Vvardenfell Brotherhood: Attempt Again",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB25",
        name = "Vvardenfell Brotherhood: Stalemate",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB26",
        name = "Vvardenfell Brotherhood: Foul Weakness",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB27",
        name = "Vvardenfell Brotherhood: Peace At Last",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB28",
        name = "Vvardenfell Brotherhood: The Shadowscale",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB29",
        name = "Vvardenfell Brotherhood: The Shadowscale Chapter Two",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB30",
        name = "Vvardenfell Brotherhood: New Leader",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DBRR",
        name = "Dark Brotherhood: Promotion",
        category = "Dark Brotherhood Quests",
        subcategory = "Sithis Path",
        master = "Morrowind Extended Cut",
        text = "Pursue the Dark Brotherhood."
    },

    {
        id = "CS_DB01",
        name = "Vvardenfell Brotherhood: Old Justice",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB02",
        name = "Vvardenfell Brotherhood: Arch Nemesis",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB03",
        name = "Vvardenfell Brotherhood: Bad Blood",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB04",
        name = "Vvardenfell Brotherhood: Alliance",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB05",
        name = "Vvardenfell Brotherhood: Introducing Cyrse",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB06",
        name = "Vvardenfell Brotherhood: Shashmanu Camp",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB07",
        name = "Vvardenfell Brotherhood: Arranged Marriage",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB08",
        name = "Vvardenfell Brotherhood: Under Fire",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_DB09",
        name = "Vvardenfell Brotherhood: One Cure",
        category = "Vvardenfell Brotherhood Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Deal with the Vvardenfell Brotherhood."
    },

    {
        id = "CS_CrownAct1",
        name = "The Herald of the Sixth House",
        category = "Crown of Morrowind",
        subcategory = "Act 1",
        master = "Morrowind Extended Cut",
        text = "Pursue the Crown of Morrowind."
    },

    {
        id = "CS_CrownAct2",
        name = "Murder Aboard the Imperial Prison Ship",
        category = "Crown of Morrowind",
        subcategory = "Act 2",
        master = "Morrowind Extended Cut",
        text = "Pursue the Crown of Morrowind."
    },

    {
        id = "CS_CrownAct3",
        name = "The Heretic and the Assassin",
        category = "Crown of Morrowind",
        subcategory = "Act 3",
        master = "Morrowind Extended Cut",
        text = "Pursue the Crown of Morrowind."
    },

    {
        id = "CS_CrownAct4",
        name = "The Woman in Red",
        category = "Crown of Morrowind",
        subcategory = "Act 4",
        master = "Morrowind Extended Cut",
        text = "Pursue the Crown of Morrowind."
    },

    {
        id = "CS_CrownAct5",
        name = "The Herald of the Sixth House: Part Two",
        category = "Crown of Morrowind",
        subcategory = "Act 5",
        master = "Morrowind Extended Cut",
        text = "Pursue the Crown of Morrowind."
    },

    {
        id = "B3_ZainabBride",
        name = "Zainab Nerevarine",
        category = "Ashlander Quests",
        subcategory = "Zainab",
        master = "Morrowind Extended Cut",
        text = "Help the Zainab with an important matter."
    },

    {
        id = "CS_Thirty-six",
        name = "Thirty-six",
        category = "Temple Quests",
        subcategory = "Sermons",
        master = "Morrowind Extended Cut",
        text = "Seek out Vivec's sermons."
    },

    {
        id = "CS_SermonSet7",
        name = "The Seventh Set of Sermons",
        category = "Temple Quests",
        subcategory = "Sermons",
        master = "Morrowind Extended Cut",
        text = "Seek out Vivec's sermons."
    },

    {
        id = "CS_SermonSet6",
        name = "The Sixth Set of Sermons",
        category = "Temple Quests",
        subcategory = "Sermons",
        master = "Morrowind Extended Cut",
        text = "Seek out Vivec's sermons."
    },

    {
        id = "CS_SermonSet5",
        name = "The Fifth Set of Sermons",
        category = "Temple Quests",
        subcategory = "Sermons",
        master = "Morrowind Extended Cut",
        text = "Seek out Vivec's sermons."
    },

    {
        id = "CS_SermonSet4",
        name = "The Fourth Set of Sermons",
        category = "Temple Quests",
        subcategory = "Sermons",
        master = "Morrowind Extended Cut",
        text = "Seek out Vivec's sermons."
    },

    {
        id = "CS_SermonSet3",
        name = "The Third Set of Sermons",
        category = "Temple Quests",
        subcategory = "Sermons",
        master = "Morrowind Extended Cut",
        text = "Seek out Vivec's sermons."
    },

    {
        id = "CS_SermonSet2",
        name = "The Second Set of Sermons",
        category = "Temple Quests",
        subcategory = "Sermons",
        master = "Morrowind Extended Cut",
        text = "Seek out Vivec's sermons."
    },

    {
        id = "CS_SermonSet1",
        name = "The First Set of Sermons",
        category = "Temple Quests",
        subcategory = "Sermons",
        master = "Morrowind Extended Cut",
        text = "Seek out Vivec's sermons."
    },

    {
        id = "CS_BladesMember02",
        name = "More Members: Vuhon",
        category = "Blades Quests",
        subcategory = "Recruitment",
        master = "Morrowind Extended Cut",
        text = "Recruit support for the Blades."
    },

    {
        id = "CS_BladesMember01",
        name = "More Members: Kalorter",
        category = "Blades Quests",
        subcategory = "Recruitment",
        master = "Morrowind Extended Cut",
        text = "Recruit support for the Blades."
    },

    {
        id = "CS_BladesMembers",
        name = "Building the Base",
        category = "Blades Quests",
        subcategory = "Recruitment",
        master = "Morrowind Extended Cut",
        text = "Recruit support for the Blades."
    },

    {
        id = "CS_BladesMisc02",
        name = "The Mysterious Dunmer",
        category = "Blades Quests",
        subcategory = "Side Jobs",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_BladesMisc01",
        name = "From Vivec with Love",
        category = "Blades Quests",
        subcategory = "Side Jobs",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_BladesFTBook",
        name = "The Fourth Tool",
        category = "Blades Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_Blades08",
        name = "The Rise of the Tribe Unmourned",
        category = "Blades Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_Blades07",
        name = "A Discrete Meeting",
        category = "Blades Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_Blades06",
        name = "Smuggler, Liches, and Diplomacy",
        category = "Blades Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_Blades05",
        name = "From Mentors to Ruins",
        category = "Blades Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_Blades04",
        name = "The Dwemer Scholar",
        category = "Blades Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_Blades03",
        name = "Beneath the City",
        category = "Blades Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_Blades02",
        name = "Of Smugglers and Dagoths",
        category = "Blades Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_Blades01",
        name = "Arrival of the Imperial Spymaster",
        category = "Blades Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Assist the Blades with a dangerous investigation."
    },

    {
        id = "CS_DagothMisc01",
        name = "The Bells",
        category = "Mamshar-Disamus Quests",
        subcategory = "Side Matters",
        master = "Morrowind Extended Cut",
        text = "Look into a matter tied to Mamshar-Disamus."
    },

    {
        id = "CS_DagothMisc02",
        name = "A Love Letter",
        category = "Mamshar-Disamus Quests",
        subcategory = "Side Matters",
        master = "Morrowind Extended Cut",
        text = "Look into a matter tied to Mamshar-Disamus."
    },

    {
        id = "CS_DagothMisc03",
        name = "Feyfolken",
        category = "Mamshar-Disamus Quests",
        subcategory = "Side Matters",
        master = "Morrowind Extended Cut",
        text = "Look into a matter tied to Mamshar-Disamus."
    },

    {
        id = "CS_DagothTravel",
        name = "Travel Options to Mamshar-Disamus",
        category = "Mamshar-Disamus Quests",
        subcategory = "Travel",
        master = "Morrowind Extended Cut",
        text = "Arrange travel to Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth01",
        name = "The Mamshar-Disamus",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth02",
        name = "Traders and Transport",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth03",
        name = "Historical Documents: Part One",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth04",
        name = "Historical Documents: Part Two",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth05",
        name = "The Biography of Zemu Mamshar",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth06",
        name = "Distribution",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth07",
        name = "Who are the Ald-Kena?",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth08",
        name = "Into the Eyes of the Public",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth09",
        name = "Know Your Enemy",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth10",
        name = "The House",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth11",
        name = "Battle of Faith",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_Dagoth12",
        name = "Fall of the Quester-General",
        category = "Mamshar-Disamus Quests",
        subcategory = "Core Line",
        master = "Morrowind Extended Cut",
        text = "Investigate the Mamshar-Disamus."
    },

    {
        id = "CS_BladesScroll",
        name = "The Elder Scroll",
        category = "Blades Quests",
        subcategory = "Elder Scroll",
        master = "Morrowind Extended Cut",
        text = "Help the Blades secure a crucial document."
    },

    {
        id = "CS_Backpath",
        name = "Mephala's Saving Grace",
        category = "Main Quest",
        subcategory = "Back Path",
        master = "Morrowind Extended Cut",
        text = "Pursue the back path of the Nerevarine."
    },
    {
        id = "NF_MissingAgent",
        name = "Missing Agent",
        category = "Tamriel Rebuilt",
        subcategory = "Old Ebonheart / Morag Tong / Blades",
        master = "Morrowind Extended Cut",
        text = "Travel to Old Ebonheart and investigate Huleeya's disappearance."
    },
    {
        id = "FOM_Start",
        name = "Fate of Morrowind",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Speak with your allies about the fate of Morrowind."
    },

    {
        id = "FOM_CorprusCure",
        name = "The Corprus Cure",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Seek a cure for corprus."
    },

    {
        id = "FOM_DivinePlan",
        name = "A Divine Plan",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Learn more about a divine plan."
    },

    {
        id = "FOM_AshlanderCouncil",
        name = "The Ashlander Council",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Speak with the Ashlanders."
    },

    {
        id = "FOM_TempleDecision",
        name = "Temple Decision",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Discuss the matter with the Temple."
    },

    {
        id = "FOM_BladeOrders",
        name = "Orders from the Blades",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Receive orders from the Blades."
    },

    {
        id = "FOM_SecretMeeting",
        name = "A Secret Meeting",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Attend a secret meeting."
    },

    {
        id = "FOM_DaedricThreat",
        name = "Daedric Threat",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Investigate a Daedric threat."
    },

    {
        id = "FOM_AncientKnowledge",
        name = "Ancient Knowledge",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Search for ancient knowledge."
    },

    {
        id = "FOM_TowerSecrets",
        name = "Secrets of the Tower",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Investigate the Tower."
    },

    {
        id = "FOM_FinalChoice",
        name = "The Final Choice",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Make a final decision."
    },

    {
        id = "FOM_PathOfDuty",
        name = "The Path of Duty",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Follow the path of duty."
    },

    {
        id = "FOM_PathOfFaith",
        name = "The Path of Faith",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Follow the path of faith."
    },

    {
        id = "FOM_PathOfPower",
        name = "The Path of Power",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Follow the path of power."
    },
    {
        id = "FOM_AllySupport",
        name = "Support of Allies",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Seek support from allies."
    },

    {
        id = "FOM_FinalBattle",
        name = "The Final Battle",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Prepare for the final battle."
    },

    {
        id = "FOM_Aftermath",
        name = "Aftermath",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Deal with the aftermath."
    },

    {
        id = "FOM_End",
        name = "The Fate of Morrowind",
        category = "Fate of Morrowind",
        subcategory = "",
        master = "Morrowind Extended Cut",
        text = "Decide the fate of Morrowind."
    },
    {
        id = "CS_CTAMothersLove",
        name = "The Dren Brothers and a Mother's Love",
        category = "Tamriel Rebuilt",
        subcategory = "Camonna Tong / House Hlaalu",
        master = "Morrowind Extended Cut",
        text = "Travel to Narsis to help settle a matter between the Dren brothers."
    },

}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending Morrowind Extended Cut Data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}