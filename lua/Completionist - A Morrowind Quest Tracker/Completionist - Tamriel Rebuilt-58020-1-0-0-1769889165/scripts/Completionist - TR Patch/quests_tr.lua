local self = require('openmw.self')

local quests = {
    -- #########################################################################
    -- GAME: TAMRIEL REBUILT
    -- #########################################################################

    {
        id = "TR_NecMQ_1",
        name = "Mourning Their Passing",
        category = "Main Quest",
        subcategory = "Foul Murder",
        master = "Tamriel Rebuilt", text = "As gods fall, strange dreams drift in their wake."
    },
    {
        id = "TR_NecMQ_Outcast",
        name = "The Outcast's Ringlet",
        category = "Main Quest",
        subcategory = "Foul Murder",
        master = "Tamriel Rebuilt", text = "Wraithmail deliveries."
    },
    {
        id = "TR_NecMQ_2, TR_NecMQ_2Path",
        name = "Seeking Their Council",
        category = "Main Quest",
        subcategory = "Foul Murder",
        master = "Tamriel Rebuilt", text = "Seek scattered fragments of an ancient ally."
    },
    {
        id = "TR_NecMQ_Destroyer",
        name = "The Destroyer's Ringlet",
        category = "Main Quest",
        subcategory = "Foul Murder",
        master = "Tamriel Rebuilt", text = "Grant a ghost's wish at Boethiah's behest."
    },
    {
        id = "TR_NecMQ_Madman",
        name = "The Madman's Ringlet",
        category = "Main Quest",
        subcategory = "Foul Murder",
        master = "Tamriel Rebuilt", text = "A ringlet lies upon the sacred path."
    },
    {
        id = "TR_NecMQ_Schemer",
        name = "The Schemer's Ringlet",
        category = "Main Quest",
        subcategory = "Foul Murder",
        master = "Tamriel Rebuilt", text = "Confess, corrupt, or convict?"
    },
    {
        id = "TR_NecMQ_3, TR_NecMQ_3Death, TR_NecMQ_3Moment, TR_NecMQ_3Tribunal, TR_NecMQ_3Visions",
        name = "Finding Their Way",
        category = "Main Quest",
        subcategory = "Foul Murder",
        master = "Tamriel Rebuilt", text = "Antediluvian secrets."
    },
    {
        id = "TR_m4_HH_AND_Crates",
        name = "Counting Crates",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Nalvyna Balen's Quests, Bal Foyen, Docks: Port Authority",
        master = "Tamriel Rebuilt", text = "Clean up at the Port Authority warehouse."
    },
    {
        id = "TR_m4_HH_AND_Greef, TR_m4_HH_AND_Greef2",
        name = "Greef Astray",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Nalvyna Balen's Quests, Bal Foyen, Docks: Port Authority",
        master = "Tamriel Rebuilt", text = "Trouble's brewing at the Savrethi Distillery."
    },
    {
        id = "TR_m4_HH_AND_Employment, TR_m4_HH_AND_Employment2",
        name = "A New Employment",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Nalvyna Balen's Quests, Bal Foyen, Docks: Port Authority",
        master = "Tamriel Rebuilt", text = "Search for vacancies for a jobless scribe."
    },
    {
        id = "TR_m4_HH_AND_Ship, TR_m4_HH_AND_Ship2",
        name = "The Waylaid Ship",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Nalvyna Balen's Quests, Bal Foyen, Docks: Port Authority",
        master = "Tamriel Rebuilt", text = "Discover the cause of a ship's impoundment."
    },
    {
        id = "TR_m4_HH_AND_DocksQuests",
        name = "Jobs at the Docks",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Dreynos Helvi's Quests, Bal Foyen, Hlaalu Council Manor",
        master = "Tamriel Rebuilt", text = "Prove your capabilities to House Hlaalu."
    },
    {
        id = "TR_m4_HH_AND_CaravanRansom",
        name = "Caravan Ransom",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Dreynos Helvi's Quests, Bal Foyen, Hlaalu Council Manor",
        master = "Tamriel Rebuilt", text = "Solve a caravan holdup in ashworn Arvud."
    },
    {
        id = "TR_m4_And_MissingMerchant, TR_m4_And_MissingMerchant2",
        name = "The Missing Merchant",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Dreynos Helvi's Quests, Bal Foyen, Hlaalu Council Manor",
        master = "Tamriel Rebuilt", text = "Investigate the reason for a trader's disappearance."
    },
    {
        id = "TR_m4_HH_AND_OmaynisInn, TR_m4_HH_AND_OmaynisInn2, TR_m4_HH_AND_OmaynisInn3",
        name = "Omaynis Inn",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ulvys Ules' Quests, Bal Foyen, Andas Estate",
        master = "Tamriel Rebuilt", text = "Construct a drinking den for the residents of Omaynis."
    },
    {
        id = "TR_m4_HH_AND_ReverseRescue, TR_m4_HH_AND_ReverseRescue2",
        name = "The Reverse Rescue",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ulvys Ules' Quests, Bal Foyen, Andas Estate",
        master = "Tamriel Rebuilt", text = "Sabotage a salvation."
    },
    {
        id = "TR_m4_HH_AND_Hearing, TR_m4_HH_AND_HearManse, TR_m4_HH_AND_HearMels, TR_m4_HH_AND_HearMilns, TR_m4_HH_AND_HearTholas, TR_m4_HH_AND_HearTola",
        name = "The Hearing",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ulvys Ules' Quests, Bal Foyen, Andas Estate",
        master = "Tamriel Rebuilt", text = "Sway a vote for Tholer Andas."
    },
    {
        id = "TR_m4_HH_SalvaniWine",
        name = "Wine Contract for Bol Salvani",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Bol Salvani's Quests, Gol Mok",
        master = "Tamriel Rebuilt", text = "Obtain funds for a deal, legitimately or otherwise."
    },
    {
        id = "TR_m7_HH_Sathis1",
        name = "Letter to S'Vosh",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Feldril Sathis' Quests, Hlan Oek",
        master = "Tamriel Rebuilt", text = "Courier a missive to a Hlaalu agent."
    },
    {
        id = "TR_m7_HH_Sathis2",
        name = "The Spirit of Neen",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Feldril Sathis' Quests, Hlan Oek",
        master = "Tamriel Rebuilt", text = "Transmit a bribe to the hetman of Aimrah."
    },
    {
        id = "TR_m7_HH_Sathis3",
        name = "Smugglers in Yadamsi",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Feldril Sathis' Quests, Hlan Oek",
        master = "Tamriel Rebuilt", text = "Exact tribute from a new gang smuggling on the Thirr."
    },
    {
        id = "TR_m7_HH_Sathis4",
        name = "Stolen Battle Axe",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Feldril Sathis' Quests, Hlan Oek",
        master = "Tamriel Rebuilt", text = "Retrieve the prized weapon of a Hlaalu Councilor...before he notices."
    },
    {
        id = "TR_m7_HH_Sathis5",
        name = "S'Vosh's Code Book",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Feldril Sathis' Quests, Hlan Oek",
        master = "Tamriel Rebuilt", text = "Recover secret intelligence lost to the Indoril."
    },
    {
        id = "TR_m7_HH_Sathis6",
        name = "Frame the Ilvi Mine Foreman",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Feldril Sathis' Quests, Hlan Oek",
        master = "Tamriel Rebuilt", text = "Cause a miner incident for the Indoril."
    },
    {
        id = "TR_m7_HH_Alvynu_1",
        name = "Old Money",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Alvynu Llervas' Quests, Narsis, Measurehall",
        master = "Tamriel Rebuilt", text = "Collect on a one-hundred-and-twenty-year-old loan."
    },
    {
        id = "TR_m7_HH_Alvynu_2",
        name = "Striking Iron",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Alvynu Llervas' Quests, Narsis, Measurehall",
        master = "Tamriel Rebuilt", text = "Strangle a nascent workers' union."
    },
    {
        id = "TR_m7_HH_Alvynu_3",
        name = "Shakedown",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Alvynu Llervas' Quests, Narsis, Measurehall",
        master = "Tamriel Rebuilt", text = "Bring back a merchant's stolen goods."
    },
    {
        id = "TR_m7_HH_Alvynu_4, TR_m7_HH_Alvynu_4B",
        name = "Moral Luck",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Alvynu Llervas' Quests, Narsis, Measurehall",
        master = "Tamriel Rebuilt", text = "Investigate a curse of good luck laid on the Fortuna."
    },
    {
        id = "TR_m7_HH_Alvynu_5",
        name = "Early Release",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Alvynu Llervas' Quests, Narsis, Measurehall",
        master = "Tamriel Rebuilt", text = "Extract testimony against the Ja-Natta Syndicate."
    },
    {
        id = "TR_m7_HH_Alvynu_6",
        name = "Sin and Punishment",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Alvynu Llervas' Quests, Narsis, Measurehall",
        master = "Tamriel Rebuilt", text = "Vengeful spirits threaten the city."
    },
    {
        id = "TR_m7_HH_Alvynu_7, TR_m7_HH_Alvynu_7BC, TR_m7_HH_Alvynu_7RS",
        name = "The Lowest of Bidders",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Alvynu Llervas' Quests, Narsis, Measurehall",
        master = "Tamriel Rebuilt", text = "Eliminate the competition before an upcoming share selloff."
    },
    {
        id = "TR_m7_HH_SeventhFamily_1",
        name = "Intercept Message",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Belron Hlaalu's Quests, Narsis, Seventh Family Manor",
        master = "Tamriel Rebuilt", text = "Steal a letter from the Seventh Family's adversaries."
    },
    {
        id = "TR_m7_HH_SeventhFamily_2",
        name = "Seek Forever the Seyda Neen",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Belron Hlaalu's Quests, Narsis, Seventh Family Manor",
        master = "Tamriel Rebuilt", text = "Salvage a part of a storied wreck."
    },
    {
        id = "TR_m7_HH_Raran1",
        name = "Llananu's Report",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Diradeni Raran's Quests, Narsis, Raran Manor",
        master = "Tamriel Rebuilt", text = "Courier a sealed missive for the Raran family."
    },
    {
        id = "TR_m7_HH_Raran2",
        name = "The Night Shift",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Diradeni Raran's Quests, Narsis, Raran Manor",
        master = "Tamriel Rebuilt", text = "Investigate thefts at the Raran Warehouse."
    },
    {
        id = "TR_m7_HH_GM_1",
        name = "Money Never Sleeps",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Help orchestrate House Hlaalu's hostile takeover of the East Empire Company."
    },
    {
        id = "TR_m7_HH_GM_2z, HH_WinCamonna",
        name = "Dealing with Orvas Dren",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Deal with Orvas Dren, and decide your stance towards the Camonna Tong in the process."
    },
    {
        id = "TR_m7_HH_GM_3za",
        name = "Crackdown",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Eliminate threats to House Hlaalu by stamping out the Camonna Tong and Ja-Natta Syndicate."
    },
    {
        id = "TR_m7_HH_GM_3zb",
        name = "Expel the Outlanders",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Eliminate the major threats to House Hlaalu and the Camonna Tong."
    },
    {
        id = "TR_m7_HH_GM_4",
        name = "Hlaalu Grandmaster",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Get support from every Hlaalu councilor."
    },
    {
        id = "TR_m7_HH_GM_4a",
        name = "Right of Passage",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Curtail the freedoms of Redoran-controlled Ald Iuval."
    },
    {
        id = "TR_m7_HH_GM_4b",
        name = "Ancestral Approval",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Intercede with a Hlaalu Councilor's Indoril ancestor."
    },
    {
        id = "TR_m7_HH_GM_4c",
        name = "Snuffing Out the Lamp",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Confront a Twin Lamps operative."
    },
    {
        id = "TR_m7_HH_GM_5",
        name = "Finding the Saint",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Determine the whereabouts of a dream-drawn Mer."
    },
    {
        id = "TR_m7_HH_GM_6",
        name = "The Ritual of St. Veloth",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Perform a strange ritual outlined by a dream."
    },
    {
        id = "TR_m7_HH_GM_7",
        name = "The Face of Veloth",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ereven Peronys' and the Hlaalu Grandmaster Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Bring a message back to the Dunmer people."
    },
    {
        id = "TR_m7_Ns_HH_RentFarmingTR_m7_Ns_HH_RentFarmingATR_m7_Ns_HH_RentFarmingBTR_m7_Ns_HH_RentFarmingC",
        name = "Rent Farming",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Saritha Hlaalu's Quests, Narsis, Second Family Manor",
        master = "Tamriel Rebuilt", text = "Recover rent arrears for the Second Family."
    },
    {
        id = "TR_m7_Ns_HH_AngryLetter, TR_m7_Ns_HH_AngryLetterA",
        name = "An Angry Letter",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Saritha Hlaalu's Quests, Narsis, Second Family Manor",
        master = "Tamriel Rebuilt", text = "Exchange letters between a duke and the grandmaster's heiress."
    },
    {
        id = "TR_m7_HH_SixthFamily_1",
        name = "Chanis' Bonus",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Sodreru Hlaalu's Quests, Narsis, Sixth Family Manor",
        master = "Tamriel Rebuilt", text = "Deliver a bonus to a Hlaalu Council Company factor."
    },
    {
        id = "TR_m7_HH_SixthFamily_2",
        name = "Letter from the Family",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Sodreru Hlaalu's Quests, Narsis, Sixth Family Manor",
        master = "Tamriel Rebuilt", text = "Help along a mail delivery."
    },
    {
        id = "TR_m7_HH_FirstFamily_1",
        name = "Trouble in the Catacombs",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Tereldyn Hlaalu's Quests, Narsis, First Family Manor",
        master = "Tamriel Rebuilt", text = "Check on strange noises in Endeavor's Lament."
    },
    {
        id = "TR_m7_HH_FirstFamily_2",
        name = "Repairing the Breach",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Tereldyn Hlaalu's Quests, Narsis, First Family Manor",
        master = "Tamriel Rebuilt", text = "Bargain with bureaucrats to secure a sewer's repair."
    },
    {
        id = "TR_m7_HH_Dren, TR_m7_HH_Dren_O, TR_m7_HH_Dren_V",
        name = "A Troubled Delivery",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Releniah Dren's Quests, Old Dren Plantation",
        master = "Tamriel Rebuilt", text = "Bring a mother's message to the Drens on Vvardenfell."
    },
    {
        id = "TR_m4_HH_Ulvo1",
        name = "Charter Enforcement",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ulvo Hlaari's Quests, Oran Plantation",
        master = "Tamriel Rebuilt", text = "Negotiate with a shipmaster on strike."
    },
    {
        id = "TR_m4_HH_Ulvo2",
        name = "A Velkcome Diversion",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ulvo Hlaari's Quests, Oran Plantation",
        master = "Tamriel Rebuilt", text = "Rustle a village Velk."
    },
    {
        id = "TR_m4_HH_Ulvo3",
        name = "The Cost Of Iron",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ulvo Hlaari's Quests, Oran Plantation",
        master = "Tamriel Rebuilt", text = "Tools are vanishing from around the plantation - but to what end?"
    },
    {
        id = "TR_m4_HH_Ulvo4",
        name = "Home To Roost",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Ulvo Hlaari's Quests, Oran Plantation",
        master = "Tamriel Rebuilt", text = "Scouts come knocking for a familiar beast."
    },
    {
        id = "TR_m7_Oth_HH_1",
        name = "Buy Food for Othmura",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Idros Rothrano's Quests, Othmura",
        master = "Tamriel Rebuilt", text = "Buy supplies from neighboring farms."
    },
    {
        id = "TR_m7_Oth_HH_2",
        name = "Mail Pattern Badness",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Idros Rothrano's Quests, Othmura",
        master = "Tamriel Rebuilt", text = "Demand a delayed report from Idathren's governor."
    },
    {
        id = "TR_m7_Oth_HH_3",
        name = "In Search of a Master",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Idros Rothrano's Quests, Othmura",
        master = "Tamriel Rebuilt", text = "Seek out the owner of a slave."
    },
    {
        id = "TR_m7_Oth_HH_4",
        name = "Song of the People",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Idros Rothrano's Quests, Othmura",
        master = "Tamriel Rebuilt", text = "Quiet rowdy revelers through a bard's dismissal."
    },
    {
        id = "TR_m7_Oth_HH_5",
        name = "Aid to the Needy",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Artisa Rethan's Quests, Othmura",
        master = "Tamriel Rebuilt", text = "Get House Hlaalu's aid to the poor of a House Redoran settlement."
    },
    {
        id = "TR_m7_Oth_HH_6",
        name = "Plant Coronati's Hindsight",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Artisa Rethan's Quests, Othmura",
        master = "Tamriel Rebuilt", text = "Sow distrust with the movement of a warhammer."
    },
    {
        id = "TR_m7_Oth_HH_7",
        name = "A Reputation to Uphold",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Artisa Rethan's Quests, Othmura",
        master = "Tamriel Rebuilt", text = "Halt an inquest into the garrison's commander."
    },
    {
        id = "TR_m7_ShiSha_HH_1",
        name = "I Haven't The Time",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Llaros Samalsi's Quests, Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "Petitioners bother the governor - make them stop."
    },
    {
        id = "TR_m7_ShiSha_HH_2",
        name = "Our Prying Friends",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Llaros Samalsi's Quests, Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "Help the Camonna Tong escape Legion scrutiny."
    },
    {
        id = "TR_m7_ShiSha_HH_3",
        name = "A Foreman's Debt",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Llaros Samalsi's Quests, Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "Collect on the debt of the town mine's former foremer."
    },
    {
        id = "TR_m7_ShiSha_HH_4",
        name = "Shinathi Stand-off",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Llaros Samalsi's Quests, Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "A Shinathi raid invites a Legion response - and Hlaalu mediation."
    },
    {
        id = "TR_m7_HH_Vedas1",
        name = "Share of the Pie",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Edrano Vedas' Quests, Vedas Plantation",
        master = "Tamriel Rebuilt", text = "Convince a merchant to buy only from the Vedas Plantation."
    },
    {
        id = "TR_m7_HH_Vedas2",
        name = "The Hound and the Rat",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Edrano Vedas' Quests, Vedas Plantation",
        master = "Tamriel Rebuilt", text = "Get the plantation's debtors to resume payments."
    },
    {
        id = "TR_m0_HH_TholerAndas",
        name = "An Invitation From Tholer Andas",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = "Tholer Andas is offering you an invitation to Bal Foyen."
    },
    {
        id = "TR_m0_HH_AtranOran",
        name = "An Uncle's Concern",
        category = "Great Houses | Great House Hlaalu",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = "Visit Councilman Atran Oran at the Oran Plantation."
    },
    {
        id = "TR_m7_HR_AldIuval_q1, TR_m7_HR_AldIuval_q1_a, TR_m7_HR_AldIuval_q1_b",
        name = "Due Vendetta",
        category = "Great Houses | Great House Redoran",
        subcategory = "Felmaru Llendu's Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Challenge a traitor to an honorable duel."
    },
    {
        id = "TR_m7_HR_AldIuval_q2",
        name = "Unrest in the House",
        category = "Great Houses | Great House Redoran",
        subcategory = "Felmaru Llendu's Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Inspect a merchant vessel held at the Ald Marak dock."
    },
    {
        id = "TR_m7_HR_AldIuval_q3",
        name = "The Will of One",
        category = "Great Houses | Great House Redoran",
        subcategory = "Felmaru Llendu's Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Seek out the last scion of a warrior dynasty."
    },
    {
        id = "TR_m7_HR_AldIuval_q4, TR_m7_HR_AldIuval_q4_a, TR_m7_HR_AldIuval_q4_b",
        name = "Funeral for a Son",
        category = "Great Houses | Great House Redoran",
        subcategory = "Felmaru Llendu's Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "The traitor has surfaced - get on his trail."
    },
    {
        id = "TR_m7_HR_AldIuval_q5",
        name = "Hope Rides Alone",
        category = "Great Houses | Great House Redoran",
        subcategory = "Felmaru Llendu's Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Retrieve a legendary blade for a duel in the Narsis Arena."
    },
    {
        id = "TR_m7_HR_AM_01",
        name = "The Pale Biter",
        category = "Great Houses | Great House Redoran",
        subcategory = "Delis Llethri's Quests, Ald Marak",
        master = "Tamriel Rebuilt", text = "Slay a nix-hound with an icy sting."
    },
    {
        id = "TR_m7_HR_AM_02",
        name = "Dreugh of Danrilk",
        category = "Great Houses | Great House Redoran",
        subcategory = "Delis Llethri's Quests, Ald Marak",
        master = "Tamriel Rebuilt", text = "Aid an investigation into the Dreugh of Danrilk Grotto."
    },
    {
        id = "TR_m7_HR_AM_03",
        name = "Swamp Witch of Iden",
        category = "Great Houses | Great House Redoran",
        subcategory = "Delis Llethri's Quests, Ald Marak",
        master = "Tamriel Rebuilt", text = "Defeat a swamp witch and commander of swamp trolls."
    },
    {
        id = "TR_m7_HR_AM_04",
        name = "Reclaiming Ibbi-Suen Mine",
        category = "Great Houses | Great House Redoran",
        subcategory = "Delis Llethri's Quests, Ald Marak",
        master = "Tamriel Rebuilt", text = "Reclaim lost treasure and territory for House Redoran."
    },
    {
        id = "TR_m7_HR_AM_05",
        name = "The Dreugh Prince of Lake Coronati",
        category = "Great Houses | Great House Redoran",
        subcategory = "Delis Llethri's Quests, Ald Marak",
        master = "Tamriel Rebuilt", text = "Hunt down and kill a cunning hive-prince."
    },
    {
        id = "TR_m7_HR_WM_Ep, TR_m7_HR_WM_Ep_a",
        name = "The Stand",
        category = "Great Houses | Great House Redoran",
        subcategory = "Delis Llethri and Felmaru Llendu's Quests, Waters March",
        master = "Tamriel Rebuilt", text = "Discover the fate of an underwater assault."
    },
    {
        id = "TR_m2_HT_Vaerin_q1, TR_m2_HT_Vaerin_q1_a, TR_m2_HT_Vaerin_q1_b",
        name = "It's Good to be a Telvanni Lord",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Vaerin's Quests, Alt Bosara",
        master = "Tamriel Rebuilt", text = "Demand dues from lesser Telvanni wizards."
    },
    {
        id = "TR_m2_HT_Vaerin_q2",
        name = "Knowledge From Beyond",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Vaerin's Quests, Alt Bosara",
        master = "Tamriel Rebuilt", text = "Capture the soul of an Indoril wraith."
    },
    {
        id = "TR_m2_HT_Vaerin_q3",
        name = "Don't Mind Me",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Vaerin's Quests, Alt Bosara",
        master = "Tamriel Rebuilt", text = "Swipe a scroll while battle rages."
    },
    {
        id = "TR_m2_HT_Vaerin_q4",
        name = "It's Not Theft If They're Dead",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Vaerin's Quests, Alt Bosara",
        master = "Tamriel Rebuilt", text = "Daedra and treasure abound in a grandiose ruin."
    },
    {
        id = "TR_m2_HT_Vaerin_q5",
        name = "Plan B",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Vaerin's Quests, Alt Bosara",
        master = "Tamriel Rebuilt", text = "Secure an emergency exit in case of plots gone awry."
    },
    {
        id = "TR_m2_HT_Vaerin_q6, TR_m2_HT_Vaerin_q6_a, TR_m2_HT_Vaerin_q6_ep",
        name = "We're Done When I Say So",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Vaerin's Quests, Alt Bosara",
        master = "Tamriel Rebuilt", text = "Devastate a Tel as a reminder of Vaerin's power."
    },
    {
        id = "TR_m1_ITO_SoulSwipe",
        name = "Soul Swipe",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Jula Minthri's Quests, Firewatch",
        master = "Tamriel Rebuilt", text = "Retrieve a gem containing the soul of a summoned herne."
    },
    {
        id = "TR_m1_HT_Ra1",
        name = "A Message from Vvardenfell",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Areth Morvayn's Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Meet a messenger from Vvardenfell in Bahrammu."
    },
    {
        id = "TR_m1_HT_Ra2",
        name = "Plague",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Areth Morvayn's Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Areth Morvayn wants you to supply an agent of Mistress Eldale, or does he?"
    },
    {
        id = "TR_m1_HT_El1",
        name = "Dispatch to Eldale",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Fervas Shulisa's Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Bring a message to Mistress Eldale in Gah Sadrith."
    },
    {
        id = "TR_m1_HT_El2",
        name = "Message to Bal Gernak",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Fervas Shulisa's Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Bal Gernak receives a warning to stop his actions, and you should bring it."
    },
    {
        id = "TR_m1_HT_Dr1",
        name = "Ingredients for Lord Dral",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Malvas Relvani's Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Collect some ingredients for the study of the Archmagister."
    },
    {
        id = "TR_m1_HT_Dr2",
        name = "Uncharted Waters",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Malvas Relvani's Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Explore a new magical world, and adapt to its conditions."
    },
    {
        id = "TR_m1_HT_Fa1",
        name = "Seeds for Faruna",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Nethan Marys' Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Bring some precious plant seeds to Mistress Faruna in Tel Oren."
    },
    {
        id = "TR_m1_HT_Fa2",
        name = "Fresh Delivery",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Nethan Marys' Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Gather some research subjects from the slavemarket in Port Telvannis."
    },
    {
        id = "TR_m1_HT_Mi1",
        name = "Census in Ranyon-ruhn",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Nevrile Omayn's Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Find out why the census in Ranyon-ruhn has stopped."
    },
    {
        id = "TR_m1_HT_Mi2",
        name = "Peacemaker",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Nevrile Omayn's Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Solve a dispute between the local priest and another citizen of Ranyon-ruhn."
    },
    {
        id = "TR_m1_HT_Va1",
        name = "Fools that Meddle",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Norahin Darys' Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Remove a priest from Port Telvannis to please Master Vaerin."
    },
    {
        id = "TR_m1_HT_Va2",
        name = "Books of Faith",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Norahin Darys' Quests, Port Telvannis",
        master = "Tamriel Rebuilt", text = "Those boring books of the Temple should end up at the bottom of the ocean..."
    },
    {
        id = "TR_m1_RR_MQ_1",
        name = "Trouble in Ranyon-ruhn",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "The Telvanni master of Ranyon-ruhn has some troubles with his mine and you may be able to help..."
    },
    {
        id = "TR_m1_RR_MQ_2",
        name = "A Most Displeased Noble",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "The mine workers are unhappy, but why?"
    },
    {
        id = "TR_m1_RR_MQ_3",
        name = "Concerns of a Lord",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "Sometimes, slaves are in short supply, even in Port Telvannis."
    },
    {
        id = "TR_m1_RR_MQ_4",
        name = "Unconventional Methods",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "Finding some workers for the mine is proving to be a lot of work."
    },
    {
        id = "TR_m1_RR_MQ_5",
        name = "Daggers and Chains",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "Be careful around Argonian slaves, they may be armed to their teeth."
    },
    {
        id = "TR_m1_RR_MQ_6",
        name = "Beast of Burden",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "Mithras has burdened you with the task of finding a pack guar..."
    },
    {
        id = "TR_m1_RR_MQ_7",
        name = "Balancing Act",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "The ebony mine in Ranyon-ruhn is still losing money, so you need to take a dive in its paperwork."
    },
    {
        id = "TR_m1_RR_MQ_8",
        name = "Treachery Revealed",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "Finally, we get to know exactly who stole the ebony from the mine."
    },
    {
        id = "TR_m1_RR_MQ_9",
        name = "The Final Search",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "The traitor's house has been watched from several angles, so how could he have disappeared?"
    },
    {
        id = "TR_m1_RR_MQ_10",
        name = "Time to Pay, the Telvanni Way",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Mithras' Quests, Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "In the final showdown, the plot will be unveiled and the town of Ranyon-ruhn will be saved..."
    },
    {
        id = "TR_m1_HT_Oathrung",
        name = "Reclaiming Oathrung",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Faruna's Quests, Tel Oren",
        master = "Tamriel Rebuilt", text = "Steal a legendary staff for Mistress Faruna."
    },
    {
        id = "TR_m1_HT_Rathra_q1",
        name = "On Elemental Daedra",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Rathra's Quests, Tel Ouada",
        master = "Tamriel Rebuilt", text = "Obtain a tome for a Telvanni mage."
    },
    {
        id = "TR_m1_HT_Rathra_q2, TR_m1_HT_Rathra_q2_a, TR_m1_HT_Rathra_q2_b",
        name = "Supply Chain",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Rathra's Quests, Tel Ouada",
        master = "Tamriel Rebuilt", text = "Meddle in Master Mithras' mining venture."
    },
    {
        id = "TR_m1_HT_Rathra_q3",
        name = "The Daedric Septis",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Rathra's Quests, Tel Ouada",
        master = "Tamriel Rebuilt", text = "Wrest a grimoire from the possession of Dagon's warlocks."
    },
    {
        id = "TR_m1_HT_Rathra_q4",
        name = "Accounting Error",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Rathra's Quests, Tel Ouada",
        master = "Tamriel Rebuilt", text = "Obscure Rathra's sabotage of Mithras' mine."
    },
    {
        id = "TR_m1_HT_Rathra_q5",
        name = "The Only Way Out",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Rathra's Quests, Tel Ouada",
        master = "Tamriel Rebuilt", text = "Assassinate the Duchess of Firewatch's court mage."
    },
    {
        id = "TR_m1_HT_Rathra_q6",
        name = "The Blood of Gods and Men",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Rathra's Quests, Tel Ouada",
        master = "Tamriel Rebuilt", text = "Force a mine's closure with a display of Telvanni brutality."
    },
    {
        id = "TR_m1_HT_Nu1",
        name = "The Book of Worms",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Nira Uldram's Quests, Tel Rivus",
        master = "Tamriel Rebuilt", text = "Obtain a rare book for the ruler of Tel Rivus."
    },
    {
        id = "TR_m0_HT_CephalopodShells",
        name = "Cephalopod Shell Fragments",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = "Bring cephalopod shell fragments to Master Neloth."
    },
    {
        id = "TR_m0_HT_UnseatingDral, TR_m1_HT_UnseatingDral, TR_m1_HT_UnseatingDral_Eldale, TR_m1_HT_UnseatingDral_Faruna, TR_m1_HT_UnseatingDral_Mithras, TR_m1_HT_UnseatingDral_Rathra, TR_m1_HT_UnseatingDral_Vaerin",
        name = "Unseating Rilvin Dral",
        category = "Great Houses | Great House Telvanni",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = "Become the legitimate Archmagister of House Telvanni and the head of the Parliament of Bugs."
    },
    {
        id = "TR_m1_EEC_Lora",
        name = "The Messenger",
        category = "Factions | East Empire Company",
        subcategory = "Lora Avis' Quests, East Empire Company, Firewatch",
        master = "Tamriel Rebuilt", text = "Deliver a cost estimate to a valued client."
    },
    {
        id = "TR_m1_EEC_Lora2",
        name = "Academic Contraband",
        category = "Factions | East Empire Company",
        subcategory = "Lora Avis' Quests, East Empire Company, Firewatch",
        master = "Tamriel Rebuilt", text = "Enforce the Company's monopoly on Dwemer goods."
    },
    {
        id = "TR_m1_EEC_Zaren",
        name = "Business as Usual",
        category = "Factions | East Empire Company",
        subcategory = "Zaren Hammebenat's Quests, East Empire Company, Firewatch",
        master = "Tamriel Rebuilt", text = "Obtain a mysterious package for the Company's Factor."
    },
    {
        id = "TR_M7_EEC_Narsis1",
        name = "Strike a Deal",
        category = "Factions | East Empire Company",
        subcategory = "Rogatus Cipius' Quests, East Empire Company, Narsis",
        master = "Tamriel Rebuilt", text = "Change caravan contractors for the Company."
    },
    {
        id = "TR_M7_EEC_Narsis2",
        name = "Individual Endeavor",
        category = "Factions | East Empire Company",
        subcategory = "Rogatus Cipius' Quests, East Empire Company, Narsis",
        master = "Tamriel Rebuilt", text = "Search for exportable wares in the Grand Bazaar."
    },
    {
        id = "TR_m7_EEC_Narsis3",
        name = "Measure of a Mer",
        category = "Factions | East Empire Company",
        subcategory = "Rogatus Cipius' Quests, East Empire Company, Narsis",
        master = "Tamriel Rebuilt", text = "Muddle the master weights of the Hlaalu Council Company."
    },
    {
        id = "TR_m7_EEC_Narsis4, TR_m7_EEC_Narsis4a",
        name = "The Dawdling Caravans",
        category = "Factions | East Empire Company",
        subcategory = "Rogatus Cipius' Quests, East Empire Company, Narsis",
        master = "Tamriel Rebuilt", text = "Unsnarl a logistics problem in Shipal-Sharai."
    },
    {
        id = "TR_m7_EEC_Narsis5",
        name = "Induced Demand",
        category = "Factions | East Empire Company",
        subcategory = "Rogatus Cipius' Quests, East Empire Company, Narsis",
        master = "Tamriel Rebuilt", text = "Expand the EEC's share in the Cyrodiilic Brandy sector."
    },
    {
        id = "TR_m7_EEC_Narsis6",
        name = "Under Our Protection",
        category = "Factions | East Empire Company",
        subcategory = "Rogatus Cipius' Quests, East Empire Company, Narsis",
        master = "Tamriel Rebuilt", text = "Seek and destroy raiders troubling company caravans."
    },
    {
        id = "TR_m7_EEC_Narsis7",
        name = "Securing The Route",
        category = "Factions | East Empire Company",
        subcategory = "Rogatus Cipius' Quests, East Empire Company, Narsis",
        master = "Tamriel Rebuilt", text = "Find business for the Fighters Guild in exchange for cheaper rates."
    },
    {
        id = "TR_m7_EEC_Narsis8",
        name = "A Desert Armory",
        category = "Factions | East Empire Company",
        subcategory = "Rogatus Cipius' Quests, East Empire Company, Narsis",
        master = "Tamriel Rebuilt", text = "Clear some stubborn locals from the site of a new caravanserai."
    },
    {
        id = "TR_m3_EEC_Cano1",
        name = "Paper Trail",
        category = "Factions | East Empire Company",
        subcategory = "Cano's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Collect reports for submission to the Briricca Bank."
    },
    {
        id = "TR_m3_EEC_Cano2",
        name = "Tough Customer",
        category = "Factions | East Empire Company",
        subcategory = "Cano's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Handle a dissatisfied client."
    },
    {
        id = "TR_m3_EEC_Cano3, TR_m3_EEC_Cano3_a, TR_m3_EEC_Cano3_b, TR_m3_EEC_Cano3_c",
        name = "Buying Time",
        category = "Factions | East Empire Company",
        subcategory = "Cano's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Recent shipping delays require some savvy negotiation."
    },
    {
        id = "TR_m3_EEC_Cano4",
        name = "Talking Shop",
        category = "Factions | East Empire Company",
        subcategory = "Cano's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Close a deal with a Velothi merchant."
    },
    {
        id = "TR_m3_EEC_Cano5, TR_m3_EEC_Cano5_a, TR_m3_EEC_Cano5_b, TR_m3_EEC_Cano5_c",
        name = "Follow the Money",
        category = "Factions | East Empire Company",
        subcategory = "Cano's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Track down an elusive agent of the Company."
    },
    {
        id = "TR_m3_EEC_Cano5z",
        name = "Bank Run",
        category = "Factions | East Empire Company",
        subcategory = "Cano's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Get an update from the Briricca Bank."
    },
    {
        id = "TR_m3_EEC_Cano6, TR_m3_EEC_Cano6_a, TR_m3_EEC_Cano6_b, TR_m3_EEC_Cano6_c, TR_m3_EEC_Cano6_cz, TR_m3_EEC_Cano6_x",
        name = "Art of the Deal",
        category = "Factions | East Empire Company",
        subcategory = "Cano's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Cover your tracks, or broker the unthinkable?"
    },
    {
        id = "TR_m3_EEC_excise",
        name = "Letter of the Law",
        category = "Factions | East Empire Company",
        subcategory = "Aetia Nemesia's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Work out the import fees for a merchant without proper documentation."
    },
    {
        id = "TR_m3_EEC_counterfeit",
        name = "Writ for Counterfeit",
        category = "Factions | East Empire Company",
        subcategory = "Aetia Nemesia's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Kill some counterfeiters that are hiding in the sewers."
    },
    {
        id = "TR_m3_EEC_curse",
        name = "Basement Declaration",
        category = "Factions | East Empire Company",
        subcategory = "Aetia Nemesia's Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Secretly return a \"borrowed\" scroll to its rightful owner."
    },
    {
        id = "TR_m3_EEC_ebony",
        name = "Empty Mines, Empty Coffers",
        category = "Factions | East Empire Company",
        subcategory = "Cassynderia Lys' Quests, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "House Redoran demands a refund for an already depleted ebony mine they bought."
    },
    {
        id = "TR_m2_FG_Amiro1",
        name = "Belated Service",
        category = "Factions | Fighters Guild",
        subcategory = "Amiro's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Take out a bandit gang and discover the fate of a missing guild member."
    },
    {
        id = "TR_m2_FG_Amiro2",
        name = "Beleaguered Sanctuary",
        category = "Factions | Fighters Guild",
        subcategory = "Amiro's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Bring down a bandit... if you can find him."
    },
    {
        id = "TR_m2_FG_Amiro3",
        name = "Conflict of Interest",
        category = "Factions | Fighters Guild",
        subcategory = "Amiro's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Find a pair of runaway slaves and make a choice between helping them escape slavery or return them to their master."
    },
    {
        id = "TR_m2_FG_Leonos1",
        name = "A Lifted Ledger",
        category = "Factions | Fighters Guild",
        subcategory = "Circus Leonos' Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Find Clibergus' ledger and bring it to him."
    },
    {
        id = "TR_m2_FG_Leonos2",
        name = "Instructions from an Altmer",
        category = "Factions | Fighters Guild",
        subcategory = "Circus Leonos' Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Courier a care package between manor and mine."
    },
    {
        id = "TR_m2_FG_Irano1",
        name = "No Sin Goes Unpunished",
        category = "Factions | Fighters Guild",
        subcategory = "Laalalvo Irano's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Track down a repentant assassin."
    },
    {
        id = "TR_m2_FG_Irano2",
        name = "Noble Protection",
        category = "Factions | Fighters Guild",
        subcategory = "Laalalvo Irano's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "What should be a simple bodyguard job goes bloody awry."
    },
    {
        id = "TR_m2_FG_Irano3",
        name = "Akavorioc",
        category = "Factions | Fighters Guild",
        subcategory = "Laalalvo Irano's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Kill the legendary vampire Akavorioc, a devotee of Molag Bal."
    },
    {
        id = "TR_m2_FG_Irano4",
        name = "Caught in a Web",
        category = "Factions | Fighters Guild",
        subcategory = "Laalalvo Irano's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Find a girl gone missing. Find out what forces are working against the Guild in Akamora."
    },
    {
        id = "TR_m3_FG_AT_1",
        name = "Vinipter's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Ja'Basska's Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Hunt down a mercenary the Morag Tong can't touch."
    },
    {
        id = "TR_m3_FG_AT_2",
        name = "Debt Collection in Vhul",
        category = "Factions | Fighters Guild",
        subcategory = "Ja'Basska's Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Collect a smith's debts, one way or another."
    },
    {
        id = "TR_m3_FG_AT_3",
        name = "Dalveni Land Grab",
        category = "Factions | Fighters Guild",
        subcategory = "Ja'Basska's Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Convince a homeowner to relocate, plantations need more land!"
    },
    {
        id = "TR_m3_FG_AT_4",
        name = "The Ring of Lifebloom",
        category = "Factions | Fighters Guild",
        subcategory = "Ja'Basska's Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Raid a tomb for a vital ring."
    },
    {
        id = "TR_m3_FG_AT_5, TR_m3_FG_AT_5_b, TR_m3_FG_AT_5_c",
        name = "Slaves at Llaran Farm",
        category = "Factions | Fighters Guild",
        subcategory = "Ja'Basska's Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "The Indoril need you to free some slaves. Hlaalu slaves, that is."
    },
    {
        id = "TR_m3_FG_AT_6",
        name = "Kill Argo Hlon",
        category = "Factions | Fighters Guild",
        subcategory = "Ja'Basska's Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Kill a bandit leader who has angered folks on both sides of the bridge."
    },
    {
        id = "TR_m4_FG_Hjaskar",
        name = "Hjaskar's Debt",
        category = "Factions | Fighters Guild",
        subcategory = "Neras Hardil's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Extract repayment from a smooth-talking Nord."
    },
    {
        id = "TR_m4_FG_Cliffracer",
        name = "Theft from Above",
        category = "Factions | Fighters Guild",
        subcategory = "Neras Hardil's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "The curious case of a cliff racer criminal."
    },
    {
        id = "TR_m4_FG_Darvas",
        name = "Dreth's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Neras Hardil's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Go bounty hunting at Vathras Plantation."
    },
    {
        id = "TR_m4_FG_Alits, TR_m4_FG_AlitsB",
        name = "Alit Trouble in Menaan",
        category = "Factions | Fighters Guild",
        subcategory = "Neras Hardil's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Remove the neighbors of a Hlaalu notable."
    },
    {
        id = "TR_m4_FG_Molsa, TR_m4_FG_MolsaB",
        name = "Ervethi's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Neras Hardil's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Hunt down a traitor to House Hlaalu."
    },
    {
        id = "TR_m4_FG_Map, TR_m4_FG_MapB",
        name = "Recover the Map of Ushu-Dimmu",
        category = "Factions | Fighters Guild",
        subcategory = "Neras Hardil's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Resolve a hostage situation for Tholer Andas."
    },
    {
        id = "TR_m4_FG_UshuKur1, TR_m4_FG_UshuKur1B, TR_m4_FG_UshuKur1C, TR_m4_FG_UshuKur1D",
        name = "Security for Ushu-Kur Iron Mine",
        category = "Factions | Fighters Guild",
        subcategory = "Tholer Andas and Gelvu Andas' Quests, Andas Estate, in Bal Foyen, and Ushu-Kur Mine",
        master = "Tamriel Rebuilt", text = "Journey to an old Imperial penal mine."
    },
    {
        id = "TR_m4_FG_UshuKur2",
        name = "Manit-Pal the Hunter",
        category = "Factions | Fighters Guild",
        subcategory = "Tholer Andas and Gelvu Andas' Quests, Andas Estate, in Bal Foyen, and Ushu-Kur Mine",
        master = "Tamriel Rebuilt", text = "Dislodge a raving Ashlander from Ushu-Kur Mine."
    },
    {
        id = "TR_m4_FG_UshuKur3, TR_m4_FG_UshuKur3B",
        name = "For a Few Pieces of Iron",
        category = "Factions | Fighters Guild",
        subcategory = "Tholer Andas and Gelvu Andas' Quests, Andas Estate, in Bal Foyen, and Ushu-Kur Mine",
        master = "Tamriel Rebuilt", text = "Make an example of a caravaneer who crossed the Hlaalu."
    },
    {
        id = "TR_m4_FG_UshuKur4, TR_m4_FG_UshuKur4B, TR_m4_FG_UshuKur4C",
        name = "Digging Deeper",
        category = "Factions | Fighters Guild",
        subcategory = "Tholer Andas and Gelvu Andas' Quests, Andas Estate, in Bal Foyen, and Ushu-Kur Mine",
        master = "Tamriel Rebuilt", text = "The miners are on strike, and it's time to pick a side."
    },
    {
        id = "TR_m4_FG_UshuKur5, TR_m4_FG_UshuKur5B, TR_m4_FG_UshuKur5C, TR_m4_FG_UshuKur5D, TR_m4_FG_UshuKur5E, TR_m4_FG_UshuKur5F",
        name = "The Cursed Crown",
        category = "Factions | Fighters Guild",
        subcategory = "Tholer Andas and Gelvu Andas' Quests, Andas Estate, in Bal Foyen, and Ushu-Kur Mine",
        master = "Tamriel Rebuilt", text = "Fight for the power to undo death."
    },
    {
        id = "TR_m1_FG_Egg, TR_m1_FG_Egg2",
        name = "Breaking Some Eggs",
        category = "Factions | Fighters Guild",
        subcategory = "Permil Danconis' Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Resolve a breach of contract for a swindled merchant."
    },
    {
        id = "TR_m1_FG_Past, TR_m1_FG_Past2",
        name = "The Potion Seller's Past",
        category = "Factions | Fighters Guild",
        subcategory = "Permil Danconis' Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Handle a harasser of the city's apothecary."
    },
    {
        id = "TR_m1_FG_FindOrc",
        name = "Find Mashug gro-Dugal",
        category = "Factions | Fighters Guild",
        subcategory = "Permil Danconis' Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Find out what happened to a guild member on his last mission."
    },
    {
        id = "TR_m1_FG_Burglary, TR_m1_FG_BurglaryExtra",
        name = "Burglary in Nivalis",
        category = "Factions | Fighters Guild",
        subcategory = "Permil Danconis' Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Investigate a series of burglaries for a Nivalis shopkeeper."
    },
    {
        id = "TR_m1_FG_Codaliastalker, TR_m1_FG_Codaliastalkeralt",
        name = "Coladia Nelus' Stalker",
        category = "Factions | Fighters Guild",
        subcategory = "Permil Danconis' Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Get rid of a stalker who has been bothering a resident of Firewatch."
    },
    {
        id = "TR_m1_FG_Mandaran",
        name = "Silni's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Galan Brandt's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Go bounty hunting for the Order of Firewatch."
    },
    {
        id = "TR_m1_FG_Manrizache",
        name = "Manrizache",
        category = "Factions | Fighters Guild",
        subcategory = "Galan Brandt's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Help some archaeologists on an excavation."
    },
    {
        id = "TR_m1_FG_Protection, TR_m1_FG_Protection2, TR_m1_FG_Protection3, TR_m1_FG_Protection4",
        name = "Proactive Protection",
        category = "Factions | Fighters Guild",
        subcategory = "Galan Brandt's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Secure new contracts for the Fighters Guild."
    },
    {
        id = "TR_m2_FG_Hartise_Joran",
        name = "Joran the Defector",
        category = "Factions | Fighters Guild",
        subcategory = "Hartise's Quests, Helnim Guild",
        master = "Tamriel Rebuilt", text = "Convince a former member to rejoin the guild."
    },
    {
        id = "TR_m2_FG_Hartise_Tainted",
        name = "Tainted Goods",
        category = "Factions | Fighters Guild",
        subcategory = "Hartise's Quests, Helnim Guild",
        master = "Tamriel Rebuilt", text = "Ensure a fellow fighter is not imperiled."
    },
    {
        id = "TR_m2_FG_Hartise_Eggmine",
        name = "A Blight on Business",
        category = "Factions | Fighters Guild",
        subcategory = "Hartise's Quests, Helnim Guild",
        master = "Tamriel Rebuilt", text = "Bring a cure to a kwama queen."
    },
    {
        id = "TR_m2_FG_Hartise_Rethyn",
        name = "Capture Rethyn Verelnim",
        category = "Factions | Fighters Guild",
        subcategory = "Hartise's Quests, Helnim Guild",
        master = "Tamriel Rebuilt", text = "Arrest a renegade for a Telvanni wizard."
    },
    {
        id = "TR_m2_FG_Hartise_Twilight",
        name = "Hunting Twilight",
        category = "Factions | Fighters Guild",
        subcategory = "Hartise's Quests, Helnim Guild",
        master = "Tamriel Rebuilt", text = "Destroy a rebellious Daedra."
    },
    {
        id = "TR_m2_FG_Hartise_Selyn, TR_m2_FG_Hartise_Selyn2, TR_m2_FG_Hartise_Selyn3, TR_m2_FG_Hartise_Selyn4",
        name = "Darythi's Change of Heart",
        category = "Factions | Fighters Guild",
        subcategory = "Hartise's Quests, Helnim Guild",
        master = "Tamriel Rebuilt", text = "Sort out a mixup for Master Darythi."
    },
    {
        id = "TR_m7_FG_HL_Q1",
        name = "Taxing the Crooks",
        category = "Factions | Fighters Guild",
        subcategory = "Corter's Quests, Hlerynhul Guild",
        master = "Tamriel Rebuilt", text = "Even criminals owe the taxman."
    },
    {
        id = "TR_m7_FG_HL_Q2",
        name = "Falengar's Gang",
        category = "Factions | Fighters Guild",
        subcategory = "Corter's Quests, Hlerynhul Guild",
        master = "Tamriel Rebuilt", text = "Disperse a gang atop a Shipal-Shin mesa."
    },
    {
        id = "TR_m7_FG_HL_Q3",
        name = "Silence Rolyn Vedas",
        category = "Factions | Fighters Guild",
        subcategory = "Corter's Quests, Hlerynhul Guild",
        master = "Tamriel Rebuilt", text = "Stop the tongue of a slanderous Hlaalu."
    },
    {
        id = "TR_m7_FG_HL_Q4",
        name = "Reinforcement from the Temple",
        category = "Factions | Fighters Guild",
        subcategory = "Corter's Quests, Hlerynhul Guild",
        master = "Tamriel Rebuilt", text = "Prevent the arrival of an Ordinator."
    },
    {
        id = "TR_m7_FG_HL_Q5",
        name = "Assault on Lake Coronati",
        category = "Factions | Fighters Guild",
        subcategory = "Corter's Quests, Hlerynhul Guild",
        master = "Tamriel Rebuilt", text = "Board a trade ship crossing Lake Coronati."
    },
    {
        id = "TR_m7_FG_HL_Q6",
        name = "Marching against the Waters March",
        category = "Factions | Fighters Guild",
        subcategory = "Corter's Quests, Hlerynhul Guild",
        master = "Tamriel Rebuilt", text = "Remind the Redoran to stay within their borders."
    },
    {
        id = "TR_m7_Ns_FG_1",
        name = "Sharai Exterminator",
        category = "Factions | Fighters Guild",
        subcategory = "Lasskr's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Remove pests from a Narsis residence."
    },
    {
        id = "TR_m7_Ns_FG_2",
        name = "Silver Delivery",
        category = "Factions | Fighters Guild",
        subcategory = "Lasskr's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Bring precious metals to the guild's smith."
    },
    {
        id = "TR_m7_Ns_FG_3",
        name = "Caravan in the Canyon",
        category = "Factions | Fighters Guild",
        subcategory = "Lasskr's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Become a caravan guard for the East Empire Company."
    },
    {
        id = "TR_m7_Ns_FG_4, TR_m7_Ns_FG_4_FindJournal",
        name = "Nayalimmu's Bounty",
        category = "Factions | Fighters Guild",
        subcategory = "Lasskr's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Bring down a bandit leader for the Imperial Legion."
    },
    {
        id = "TR_m7_Ns_FG_5",
        name = "Skyrending",
        category = "Factions | Fighters Guild",
        subcategory = "Teris Vandenius' Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Cull a Skyrender swarm and defeat its queen."
    },
    {
        id = "TR_m7_Ns_FG_6",
        name = "Tensions in Num-Ittu Mine",
        category = "Factions | Fighters Guild",
        subcategory = "Teris Vandenius' Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Calm unrest at Num-Ittu Mine."
    },
    {
        id = "TR_m7_Ns_FG_7",
        name = "On Falsity",
        category = "Factions | Fighters Guild",
        subcategory = "Teris Vandenius' Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Retrieve an ancient tome from the depths of the city's catacombs."
    },
    {
        id = "TR_m7_Ns_FG_8",
        name = "Capture a Canyon Thresher",
        category = "Factions | Fighters Guild",
        subcategory = "Teris Vandenius' Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Bring in a beast for the Narsis Arena."
    },
    {
        id = "TR_m7_FG_NarsisMaster_Casimor",
        name = "Legacy of the Syffim",
        category = "Factions | Fighters Guild",
        subcategory = "Micarya's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Put down a Second Era general and his undead army."
    },
    {
        id = "TR_m7_FG_NarsisMaster_Consulate",
        name = "Spy at the Consulate",
        category = "Factions | Fighters Guild",
        subcategory = "Micarya's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Work on the sly for the Imperial Consulate."
    },
    {
        id = "TR_m7_FG_Krag_Rescue, TR_m7_FG_NarsisMaster_Rescue, TR_m7_FG_RescueAuctinius",
        name = "Rescue Auctinius Voteporix",
        category = "Factions | Fighters Guild",
        subcategory = "Micarya's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Save a chapter member from a necromancer's prison."
    },
    {
        id = "TR_m7_FG_NarsisMaster_Hlaalu, TR_m7_FG_NarsisMaster_Hlaalu_Andr, TR_m7_FG_NarsisMaster_Hlaalu_HL",
        name = "Remove Hlaalu Influence",
        category = "Factions | Fighters Guild",
        subcategory = "Micarya's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Enforce the guild's independence."
    },
    {
        id = "TR_m3_FG_OE_Cursing, TR_m3_FG_OE_Cursing2",
        name = "Cursing Like A Witch",
        category = "Factions | Fighters Guild",
        subcategory = "Sharnoga gra-Mal's Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "Help the local Warder of the Fighters Guild and deal with the witch who cursed him..."
    },
    {
        id = "TR_m3_FG_OE_ChampLost",
        name = "A Champion Lost",
        category = "Factions | Fighters Guild",
        subcategory = "Sharnoga gra-Mal's Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "Find a note in Manumnabi."
    },
    {
        id = "TR_m3_FG_OE_Legacy",
        name = "A Legacy's Trail",
        category = "Factions | Fighters Guild",
        subcategory = "Sharnoga gra-Mal's Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "Consult a librarian as to a warrior's next steps."
    },
    {
        id = "TR_m3_FG_OE_Fate",
        name = "A Final Fate",
        category = "Factions | Fighters Guild",
        subcategory = "Sharnoga gra-Mal's Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "Find clues to the end of a famous hero."
    },
    {
        id = "TR_m3_FG_OE_MoreRats",
        name = "More Rats?",
        category = "Factions | Fighters Guild",
        subcategory = "Foedus Locutius' Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "Handle some black market 'vermin'."
    },
    {
        id = "TR_m3_FG_OE_Ghosts",
        name = "And Ghosts, Too!",
        category = "Factions | Fighters Guild",
        subcategory = "Foedus Locutius' Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "When the dead come calling, who will answer?"
    },
    {
        id = "TR_m1_FW_IC1_Guar",
        name = "Blessing for a Beast",
        category = "Factions | Imperial Cult",
        subcategory = "Tarom's Quests, Grand Chapel of Akatosh, Firewatch",
        master = "Tamriel Rebuilt", text = "Provide respite to a poorly guar."
    },
    {
        id = "TR_m1_FW_IC2_Taxes",
        name = "Render Unto Tiber",
        category = "Factions | Imperial Cult",
        subcategory = "Tarom's Quests, Grand Chapel of Akatosh, Firewatch",
        master = "Tamriel Rebuilt", text = "Gilara Renus has some tasks for you to do before she'll give the cult a donation..."
    },
    {
        id = "TR_m1_FW_IC3_Ring",
        name = "The Ring of Respite",
        category = "Factions | Imperial Cult",
        subcategory = "Tarom's Quests, Grand Chapel of Akatosh, Firewatch",
        master = "Tamriel Rebuilt", text = "Retrieve a sacred artifact from Windbreaker Keep."
    },
    {
        id = "TR_m1_FW_IC5_Sword",
        name = "The Sword of Taldeus",
        category = "Factions | Imperial Cult",
        subcategory = "Tarom's Quests, Grand Chapel of Akatosh, Firewatch",
        master = "Tamriel Rebuilt", text = "Discover the resting place of a saint's holy blade."
    },
    {
        id = "TR_m1_FW_IC6_Lore, TR_m1_FW_IC6_Lore2, TR_m1_FW_IC6_Lore3, TR_m1_FW_IC6_Lorefail",
        name = "The Star Wound",
        category = "Factions | Imperial Cult",
        subcategory = "Tarom's Quests, Grand Chapel of Akatosh, Firewatch",
        master = "Tamriel Rebuilt", text = "Explain the birth of Tamriel's largest volcano."
    },
    {
        id = "TR_m1_FW_IC7_Blood",
        name = "The Blood Mage",
        category = "Factions | Imperial Cult",
        subcategory = "Tarom's Quests, Grand Chapel of Akatosh, Firewatch",
        master = "Tamriel Rebuilt", text = "Put an end to an army of the dead."
    },
    {
        id = "TR_m2_IC_Widower",
        name = "The Wealthy Widower",
        category = "Factions | Imperial Cult",
        subcategory = "Kamlen's Quests, Chapel of Kynareth, Helnim",
        master = "Tamriel Rebuilt", text = "Console a grieving widower."
    },
    {
        id = "TR_m2_IC_Convert",
        name = "An Unlikely Convert",
        category = "Factions | Imperial Cult",
        subcategory = "Kamlen's Quests, Chapel of Kynareth, Helnim",
        master = "Tamriel Rebuilt", text = "Collect the dues of an unlikely convert."
    },
    {
        id = "TR_m2_IC_Pilgrim, TR_m2_IC_Pilgrim2",
        name = "The Thieving Pilgrim",
        category = "Factions | Imperial Cult",
        subcategory = "Godred the Weary's Quests, Chapel of Kynareth, Helnim",
        master = "Tamriel Rebuilt", text = "Help retrieve a stolen limeware platter."
    },
    {
        id = "TR_m2_IC_Haunting",
        name = "Harbor Haunting",
        category = "Factions | Imperial Cult",
        subcategory = "Cantorius Tramel's Quests, Chapel of Kynareth, Helnim",
        master = "Tamriel Rebuilt", text = "Exorcise an ill-fortuned vessel."
    },
    {
        id = "TR_m7_IC_Maria1",
        name = "Alms of Affection",
        category = "Factions | Imperial Cult",
        subcategory = "Maria Afrana's Quests, Chapel of Dibella, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Find financial support from the people of Hlerynhul."
    },
    {
        id = "TR_m7_IC_Maria2",
        name = "Sabotaged Painting",
        category = "Factions | Imperial Cult",
        subcategory = "Maria Afrana's Quests, Chapel of Dibella, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Track down an art vandal."
    },
    {
        id = "TR_m7_IC_Maria3",
        name = "Bug Musk for Hlerynhul",
        category = "Factions | Imperial Cult",
        subcategory = "Maria Afrana's Quests, Chapel of Dibella, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Unwrinkle some noses."
    },
    {
        id = "TR_m7_IC_Maria4",
        name = "Feed the Poor in Ald Iuval",
        category = "Factions | Imperial Cult",
        subcategory = "Maria Afrana's Quests, Chapel of Dibella, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Deliver succor to the starving."
    },
    {
        id = "TR_m7_IC_Maria5",
        name = "Converted Deserter",
        category = "Factions | Imperial Cult",
        subcategory = "Maria Afrana's Quests, Chapel of Dibella, Hlerynhul",
        master = "Tamriel Rebuilt", text = "A change of faith might save this mer from execution."
    },
    {
        id = "TR_m7_IC_Maria5_a",
        name = "Letter to Daroso Sethri",
        category = "Factions | Imperial Cult",
        subcategory = "Maria Afrana's Quests, Chapel of Dibella, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Convey a convert's explanation to his old family and faith."
    },
    {
        id = "TR_m7_IC_Maria6",
        name = "Recovering Heartseeker",
        category = "Factions | Imperial Cult",
        subcategory = "Maria Afrana's Quests, Chapel of Dibella, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Bring back the blade of the last Knight of Dibella."
    },
    {
        id = "TR_m7_IC_Maria7",
        name = "Finding Marana Saruthi",
        category = "Factions | Imperial Cult",
        subcategory = "Maria Afrana's Quests, Chapel of Dibella, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Save a priestess from the servants of Mehrunes Dagon."
    },
    {
        id = "TR_m7_IC_Maria8",
        name = "Duel with an Armiger",
        category = "Factions | Imperial Cult",
        subcategory = "Maria Afrana's Quests, Chapel of Dibella, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Defend the chapel's honor."
    },
    {
        id = "TR_m7_Ns_IC1, TR_m7_Ns_IC1_a",
        name = "Blessing the Faithful",
        category = "Factions | Imperial Cult",
        subcategory = "Plutus Ceno's Quests, Chapel of Zenithar, Narsis",
        master = "Tamriel Rebuilt", text = "Perform the blessing of Zenithar for Asius Tarlo and Dovis Radreno."
    },
    {
        id = "TR_m7_Ns_IC2",
        name = "Ghosts in the Closet",
        category = "Factions | Imperial Cult",
        subcategory = "Plutus Ceno's Quests, Chapel of Zenithar, Narsis",
        master = "Tamriel Rebuilt", text = "Right an old wrong."
    },
    {
        id = "TR_m7_Ns_IC3",
        name = "Spoiled Luck",
        category = "Factions | Imperial Cult",
        subcategory = "Plutus Ceno's Quests, Chapel of Zenithar, Narsis",
        master = "Tamriel Rebuilt", text = "Help a gambler beat a spell of bad luck."
    },
    {
        id = "TR_m7_Ns_IC4",
        name = "Serve Two Masters",
        category = "Factions | Imperial Cult",
        subcategory = "Plutus Ceno's Quests, Chapel of Zenithar, Narsis",
        master = "Tamriel Rebuilt", text = "Convince a Temple priest to permit Dunmer to visit the chapel."
    },
    {
        id = "TR_m7_Ns_IC5, TR_m7_Ns_IC5_a, TR_m7_Ns_IC5_b, TR_m7_Ns_IC5_c",
        name = "God of Work and Commerce",
        category = "Factions | Imperial Cult",
        subcategory = "Plutus Ceno's Quests, Chapel of Zenithar, Narsis",
        master = "Tamriel Rebuilt", text = "Mediate in a dispute between a company and its employees."
    },
    {
        id = "TR_m7_Ns_IC6",
        name = "Seeking Saint Ino",
        category = "Factions | Imperial Cult",
        subcategory = "Plutus Ceno's Quests, Chapel of Zenithar, Narsis",
        master = "Tamriel Rebuilt", text = "Search for a priest in a sacred figure's lost tomb."
    },
    {
        id = "TR_m7_Ns_IC7",
        name = "Salvage Mission",
        category = "Factions | Imperial Cult",
        subcategory = "Plutus Ceno's Quests, Chapel of Zenithar, Narsis",
        master = "Tamriel Rebuilt", text = "A blessed ship has sunk, and the insurer wants compensation."
    },
    {
        id = "TR_m7_Ns_IC8",
        name = "Diamond in the Rough",
        category = "Factions | Imperial Cult",
        subcategory = "Plutus Ceno's Quests, Chapel of Zenithar, Narsis",
        master = "Tamriel Rebuilt", text = "Locate an aedric treasure hinted at only through visions."
    },
    {
        id = "TR_m3_IC_OE_FundingDwemer",
        name = "Scrap for Cyrodiil",
        category = "Factions | Imperial Cult",
        subcategory = "Valacca Prontia's Quests, Grand Chapel of Talos, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Find 5 pieces of Dwemer scrap metal."
    },
    {
        id = "TR_m3_IC_OE_FundingRacers",
        name = "Plumes for Cyrodiil",
        category = "Factions | Imperial Cult",
        subcategory = "Valacca Prontia's Quests, Grand Chapel of Talos, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Find 20 racer plumes."
    },
    {
        id = "TR_m3_IC_OE_MystSpread, TR_m3_IC_OE_MystSpread_C, TR_m3_IC_OE_MystSpread_F, TR_m3_IC_OE_MystSpread_P",
        name = "Spreading the Mystery",
        category = "Factions | Imperial Cult",
        subcategory = "Felmo Ilveroth's Quests, Grand Chapel of Talos, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "These plays about a three-headed demon just aren't selling. Fix that will you?"
    },
    {
        id = "TR_m3_IC_OE_TheftBrass",
        name = "Theft of Brass",
        category = "Factions | Imperial Cult",
        subcategory = "Felmo Ilveroth's Quests, Grand Chapel of Talos, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "A thief in the Great Chapel! Who could it be?"
    },
    {
        id = "TR_m3_IC_OE_DukeMessage",
        name = "Message to Myth",
        category = "Factions | Imperial Cult",
        subcategory = "Felmo Ilveroth's Quests, Grand Chapel of Talos, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Petition the Duke to put on a provocative play."
    },
    {
        id = "TR_m0_IC_DustBeetleShell, TR_m0_IC_DustBeetleShell_Not",
        name = "Gathering Dust Beetle Shells",
        category = "Factions | Imperial Cult",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = ""
    },
    {
        id = "TR_m1_IL_Nivalis, TR_m1_IL_Nivalis2",
        name = "Shipment to Nivalis",
        category = "Factions | Imperial Legion",
        subcategory = "Vycius Pitio's Quests, Dustmoth Legion Garrison, Firewatch",
        master = "Tamriel Rebuilt", text = "Courier a message from commander to commodore."
    },
    {
        id = "TR_m1_IL_Fauna2",
        name = "Exotic Fauna",
        category = "Factions | Imperial Legion",
        subcategory = "Vycius Pitio's Quests, Dustmoth Legion Garrison, Firewatch",
        master = "Tamriel Rebuilt", text = "Help confiscated skooma make it to a Legion lockup."
    },
    {
        id = "TR_m1_IL_Skoomaship",
        name = "Naval Negotiations",
        category = "Factions | Imperial Legion",
        subcategory = "Vycius Pitio's Quests, Dustmoth Legion Garrison, Firewatch",
        master = "Tamriel Rebuilt", text = "Commandeer more contraband for the Dustmoth Legion."
    },
    {
        id = "TR_m1_IL_Finepoor, TR_m1_IL_Finepoor2, TR_m1_IL_Finepoor3, TR_m1_IL_Finepoor4",
        name = "Taxing the Poor",
        category = "Factions | Imperial Legion",
        subcategory = "Vycius Pitio's Quests, Dustmoth Legion Garrison, Firewatch",
        master = "Tamriel Rebuilt", text = "It's a fine day, citizen - pay up."
    },
    {
        id = "TR_m1_IL_Sweetdeal, TR_m1_IL_Sweetdeal2",
        name = "A Sweet Deal",
        category = "Factions | Imperial Legion",
        subcategory = "Vycius Pitio's Quests, Dustmoth Legion Garrison, Firewatch",
        master = "Tamriel Rebuilt", text = "In a Helnim basement, something sweet may be about to turn sour."
    },
    {
        id = "TR_m1_IL_Templar",
        name = "The Templar's Trifles",
        category = "Factions | Imperial Legion",
        subcategory = "Thromil Rufus' Quests, Dustmoth Legion Garrison, Firewatch",
        master = "Tamriel Rebuilt", text = "Recruit a Templar to the Dustmoth Legion."
    },
    {
        id = "TR_m1_IL_Knightduel",
        name = "Death or Dishonor",
        category = "Factions | Imperial Legion",
        subcategory = "Thromil Rufus' Quests, Dustmoth Legion Garrison, Firewatch",
        master = "Tamriel Rebuilt", text = "Fight as the commander's champion in a duel of honor."
    },
    {
        id = "TR_m1_IL_Onimushili",
        name = "Traitor in Onimushili",
        category = "Factions | Imperial Legion",
        subcategory = "Thromil Rufus' Quests, Dustmoth Legion Garrison, Firewatch",
        master = "Tamriel Rebuilt", text = "Hunt down a legionnaire turned cultist."
    },
    {
        id = "TR_m1_IL_Pahunsabi",
        name = "Confrontation at Pahunsabi",
        category = "Factions | Imperial Legion",
        subcategory = "Thromil Rufus' Quests, Dustmoth Legion Garrison, Firewatch",
        master = "Tamriel Rebuilt", text = "Champion or Commander? It's time to choose."
    },
    {
        id = "TR_m7_IL_HL_Q1",
        name = "Report for Ereven Baryl",
        category = "Factions | Imperial Legion",
        subcategory = "Antonius Rato's Quests, Tiger Hall, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Deliver a report from Antonius Rato to Ereven Baryl in Narsis."
    },
    {
        id = "TR_m7_IL_HL_Q2",
        name = "Dock Dispute",
        category = "Factions | Imperial Legion",
        subcategory = "Antonius Rato's Quests, Tiger Hall, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Assist an angry Redoran retainer with getting his goods through a Hlaalu tollhouse."
    },
    {
        id = "TR_m7_IL_HL_Q3",
        name = "Slaves in Zarathil",
        category = "Factions | Imperial Legion",
        subcategory = "Antonius Rato's Quests, Tiger Hall, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Return some escaped Hlaalu slaves."
    },
    {
        id = "TR_m7_IL_HL_Q4",
        name = "Indignant Waters",
        category = "Factions | Imperial Legion",
        subcategory = "Antonius Rato's Quests, Tiger Hall, Hlerynhul",
        master = "Tamriel Rebuilt", text = "Acquire an ancient Redoran helmet from the ruler of Hlerynhul."
    },
    {
        id = "TR_m4_IL_Smuggler",
        name = "Laying Down the Law",
        category = "Factions | Imperial Legion",
        subcategory = "Rojanna Jades' Quests, Fort Ancylis, in Roth Roryn",
        master = "Tamriel Rebuilt", text = "Deliver Imperial justice to a notorious smuggler."
    },
    {
        id = "TR_m4_IL_Grudge, TR_m4_IL_Grudgeb",
        name = "An Old Grudge",
        category = "Factions | Imperial Legion",
        subcategory = "Rojanna Jades' Quests, Fort Ancylis, in Roth Roryn",
        master = "Tamriel Rebuilt", text = "Ensure an ex-thug's past comes back to haunt him."
    },
    {
        id = "TR_m4_IL_Dreugh",
        name = "More Dreugh, More Problems",
        category = "Factions | Imperial Legion",
        subcategory = "Rojanna Jades' Quests, Fort Ancylis, in Roth Roryn",
        master = "Tamriel Rebuilt", text = "Reclaim Teyn's harbor for the Empire."
    },
    {
        id = "TR_m4_IL_Freedom, TR_m4_IL_Savrethkey",
        name = "Freedom At Any Price",
        category = "Factions | Imperial Legion",
        subcategory = "Rojanna Jades' Quests, Fort Ancylis, in Roth Roryn",
        master = "Tamriel Rebuilt", text = "A citizen has been enslaved at Savrethi Distillery."
    },
    {
        id = "TR_m4_IL_Agent, TR_m4_IL_Agentb, TR_m4_IL_Agentc, TR_m4_IL_Marcius",
        name = "Death of an Agent",
        category = "Factions | Imperial Legion",
        subcategory = "Rojanna Jades' Quests, Fort Ancylis, in Roth Roryn",
        master = "Tamriel Rebuilt", text = "A Menaan murder brings the Legion's internal conflict to a head."
    },
    {
        id = "TR_m4_IL_Kathletter",
        name = "Proper Channels",
        category = "Factions | Imperial Legion",
        subcategory = "Rojanna Jades' Quests, Fort Ancylis, in Roth Roryn",
        master = "Tamriel Rebuilt", text = "Testify on the conduct of your commander."
    },
    {
        id = "TR_m2_IL_RacerSwarm",
        name = "Racer Swarm",
        category = "Factions | Imperial Legion",
        subcategory = "Servas Capris' Quests, Fort Servas, Helnim",
        master = "Tamriel Rebuilt", text = "Cull cliff racers at Helnim's lighthouse."
    },
    {
        id = "TR_m2_IL_WantedWizard",
        name = "Wanted Wizard",
        category = "Factions | Imperial Legion",
        subcategory = "Servas Capris' Quests, Fort Servas, Helnim",
        master = "Tamriel Rebuilt", text = "Arrest a murdering mage."
    },
    {
        id = "TR_m2_IL_RaidersOtori",
        name = "Raiders in Otori",
        category = "Factions | Imperial Legion",
        subcategory = "Servas Capris' Quests, Fort Servas, Helnim",
        master = "Tamriel Rebuilt", text = "Break a bandit group harassing Telvanni traders."
    },
    {
        id = "TR_m7_Ns_IL_1, TR_m7_Ns_IL_1a",
        name = "Hit or Miss",
        category = "Factions | Imperial Legion",
        subcategory = "Ereven Baryl's Quests, Heron Hall, Narsis",
        master = "Tamriel Rebuilt", text = "Assist a Dunmer woman with finding who killed her husband."
    },
    {
        id = "TR_m7_Ns_IL_2",
        name = "Tough on Crime",
        category = "Factions | Imperial Legion",
        subcategory = "Ereven Baryl's Quests, Heron Hall, Narsis",
        master = "Tamriel Rebuilt", text = "Pump up the arrest quota numbers with a drunken partner."
    },
    {
        id = "TR_m7_Ns_IL_3",
        name = "For a Good Cause",
        category = "Factions | Imperial Legion",
        subcategory = "Ereven Baryl's Quests, Heron Hall, Narsis",
        master = "Tamriel Rebuilt", text = "Investigate someone skimming gold from the coffers of the Briricca Bank."
    },
    {
        id = "TR_m7_Ns_IL_4",
        name = "Cold Case",
        category = "Factions | Imperial Legion",
        subcategory = "Ereven Baryl's Quests, Heron Hall, Narsis",
        master = "Tamriel Rebuilt", text = "Heron Hall receives some new evidence, cracking open a cold case involving the Drens."
    },
    {
        id = "TR_m7_Ns_IL_5",
        name = "Rabble-Rousing",
        category = "Factions | Imperial Legion",
        subcategory = "Ereven Baryl's Quests, Heron Hall, Narsis",
        master = "Tamriel Rebuilt", text = "A political agitator must be silenced."
    },
    {
        id = "TR_m7_Ns_IL_6",
        name = "Cleaning Up",
        category = "Factions | Imperial Legion",
        subcategory = "Ereven Baryl's Quests, Heron Hall, Narsis",
        master = "Tamriel Rebuilt", text = "Remove a blackmailer for the Duke of Narsis District."
    },
    {
        id = "TR_m7_Ns_IL_7",
        name = "The Pen and the Sword",
        category = "Factions | Imperial Legion",
        subcategory = "Ereven Baryl's Quests, Heron Hall, Narsis",
        master = "Tamriel Rebuilt", text = "The Proconsul of Morrowind needs an abolitionist removed from Narsis."
    },
    {
        id = "TR_m7_Ns_IL_8",
        name = "Bloody Brevur",
        category = "Factions | Imperial Legion",
        subcategory = "Ereven Baryl's Quests, Heron Hall, Narsis",
        master = "Tamriel Rebuilt", text = "Investigate an apartment tower with connections to the Camonna Tong."
    },
    {
        id = "TR_m7_Ns_IL_9",
        name = "Pushed and Pulled",
        category = "Factions | Imperial Legion",
        subcategory = "Ereven Baryl's Quests, Heron Hall, Narsis",
        master = "Tamriel Rebuilt", text = "It's time to clean up after the Camonna Tong's mistakes."
    },
    {
        id = "TR_m3_IL_Judge",
        name = "Judge and Jury",
        category = "Factions | Imperial Legion",
        subcategory = "Maurrisha's Quests, Imperial Guard Command Post, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Settle a mucky merchants dispute."
    },
    {
        id = "TR_m3_IL_Jury",
        name = "Jury and Executioner",
        category = "Factions | Imperial Legion",
        subcategory = "Maurrisha's Quests, Imperial Guard Command Post, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "A hostage situation means it's time to break both doors and skulls."
    },
    {
        id = "TR_m3_IL_Purloined",
        name = "Properly Purloined",
        category = "Factions | Imperial Legion",
        subcategory = "Maurrisha's Quests, Imperial Guard Command Post, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Sewer duty. What every legionnaire signs up for!"
    },
    {
        id = "TR_m3_IL_Justice, TR_m3_OE_BelatedJustice, TR_m3_OE_BelatedJusticeA, TR_m3_OE_BelatedJusticeB, TR_m3_OE_BelatedJusticeC, TR_m3_OE_BelatedJusticeD, TR_m3_OE_BelatedJusticeE, TR_m3_OE_BelatedJusticeF, TR_m3_OE_BelatedJusticeH",
        name = "Belated Justice",
        category = "Factions | Imperial Legion",
        subcategory = "Olfvur Steel-Skin's Quests, Legion Headquarters, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "General Casik has been languishing in a dungeon for three decades. He still insists that he is innocent."
    },
    {
        id = "TR_m3_IL_Work",
        name = "All Work and No Play",
        category = "Factions | Imperial Legion",
        subcategory = "Olfvur Steel-Skin's Quests, Legion Headquarters, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Give orders at the Legion headquarters."
    },
    {
        id = "TR_m3_IL_Sabotage",
        name = "Sabotage",
        category = "Factions | Imperial Legion",
        subcategory = "Olfvur Steel-Skin's Quests, Legion Headquarters, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Handle the saboteur obstructing Firewatch's naval supplies."
    },
    {
        id = "TR_m0_SiegeAtFiremoth, TR_m3_IL_SiegeAtFiremoth",
        name = "Siege at Firemoth",
        category = "Factions | Imperial Legion",
        subcategory = "Caecalia Victrix's Quests, Legion Headquarters, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Remove an undead army from an Imperial fortress."
    },
    {
        id = "TR_m3_IL_FiremothRebuilt, TR_m3_IL_FiremothRebuilt_Hla, TR_m3_IL_FiremothRebuilt_Navy, TR_m3_IL_FiremothRebuilt_Red, TR_m3_IL_FiremothRebuilt_Report, TR_m3_IL_FiremothRebuilt_Skirt, TR_m3_IL_FiremothRebuilt_Tel, TR_m3_IL_FiremothRebuilt_Trap",
        name = "Firemoth Rekindled",
        category = "Factions | Imperial Legion",
        subcategory = "Caecalia Victrix's Quests, Legion Headquarters, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Restore an Imperial bastion of the Inner Sea."
    },
    {
        id = "TR_m7_ShiSha_IL_1",
        name = "Talking a Big Game",
        category = "Factions | Imperial Legion",
        subcategory = "Madala Ceno's Quests, Legion Post, Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "Assist the local Legion Post in dealing with a petty thief who \"has connections\"."
    },
    {
        id = "TR_m7_ShiSha_IL_2",
        name = "A Deal Gone Wrong",
        category = "Factions | Imperial Legion",
        subcategory = "Madala Ceno's Quests, Legion Post, Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "Assist a wife in recovering her kidnapped husband from outlaws."
    },
    {
        id = "TR_m7_ShiSha_IL_3",
        name = "Water Troubles",
        category = "Factions | Imperial Legion",
        subcategory = "Madala Ceno's Quests, Legion Post, Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "The Legion Post at Shipal-Sharai is missing its weekly shipment of water, you're sent to investigate why."
    },
    {
        id = "TR_m7_ShiSha_IL_4",
        name = "Desert Justice",
        category = "Factions | Imperial Legion",
        subcategory = "Madala Ceno's Quests, Legion Post, Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "End the criminal activities of sapphire smugglers."
    },
    {
        id = "TR_m0_IL_Honthjolf",
        name = "The Traitor's Cousin",
        category = "Factions | Imperial Legion",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = "Inform a blacksmith that his cousin is dead."
    },
    {
        id = "TR_m7_AI_JNS_1",
        name = "Moving Merchandise",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Tervur Ryalas' Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Peddle skooma on the streets of Ald Iuval."
    },
    {
        id = "TR_m7_AI_JNS_2",
        name = "Special Delivery",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Tervur Ryalas' Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Smuggle a stolen ancestor spirit to the Narsis Underboss."
    },
    {
        id = "TR_m7_AI_JNS_3",
        name = "Teachable Moment",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Tervur Ryalas' Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Beat down on a plantation owner who sold to House Hlaalu."
    },
    {
        id = "TR_m7_AI_JNS_4",
        name = "Foeman",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Tervur Ryalas' Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Ensure a Thieves Guild scout goes silent."
    },
    {
        id = "TR_m7_AI_JNS_5",
        name = "Stiff Competition",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Tervur Ryalas' Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Eliminate a small smuggling gang for the syndicate."
    },
    {
        id = "TR_m7_AI_JNS_6",
        name = "A Heavy Toll",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Tervur Ryalas' Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Stand and deliver!"
    },
    {
        id = "TR_m7_AI_JNS_7",
        name = "Lost Correspondence",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Tervur Ryalas' Quests, Ald Iuval",
        master = "Tamriel Rebuilt", text = "Find a syndicate spy sent to get kompromat on Ivul Hleryn."
    },
    {
        id = "TR_m7_Ns_JNS_1",
        name = "The Maze",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Saldeni Andralor's Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Off a Camonna Tong thug who's been intruding on syndicate turf."
    },
    {
        id = "TR_m7_Ns_JNS_2",
        name = "Greydust",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Saldeni Andralor's Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Push the gang's signature new narcotic."
    },
    {
        id = "TR_m7_Ns_JNS_3, TR_m7_Ns_JNS_3_Kill",
        name = "Grave Offense",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Saldeni Andralor's Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Clear the unwanted undead of a family tomb."
    },
    {
        id = "TR_m7_Ns_JNS_4",
        name = "Too Many Cooks",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Saldeni Andralor's Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Bring a kidnapping outfit into the fold."
    },
    {
        id = "TR_m7_Ns_JNS_5",
        name = "Death of a Witness",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Saldeni Andralor's Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Find a scapegoat for murder."
    },
    {
        id = "TR_m7_Ns_JNS_6, TR_m7_Ns_JNS_6_Fake",
        name = "Mule",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Saldeni Andralor's Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Freelance for the Camonna Tong."
    },
    {
        id = "TR_m7_Ns_JNS_7",
        name = "Forceful Negotiations",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "Saldeni Andralor's Quests, Narsis",
        master = "Tamriel Rebuilt", text = "Initiate a bloodbath beneath the Grand Bazaar."
    },
    {
        id = "TR_m7_JNS_TheBoss_BreathingIn",
        name = "Breathing In",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "K'Vatra's Quests, Uddanu",
        master = "Tamriel Rebuilt", text = "Secure the cooperation of the Thieves Guild."
    },
    {
        id = "TR_m7_JNS_TheBoss_SnakeEyes",
        name = "Snake Eyes",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "K'Vatra's Quests, Uddanu",
        master = "Tamriel Rebuilt", text = "A change of management is due at a major city casino."
    },
    {
        id = "TR_m7_JNS_TheBoss_BreathingOut, TR_m7_JNS_TheBoss_BreathingOutp",
        name = "Breathing Out",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "K'Vatra's Quests, Uddanu",
        master = "Tamriel Rebuilt", text = "Send a message with murder."
    },
    {
        id = "TR_m7_JNS_TheBoss_EndOfTheLine",
        name = "End of the Line",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "K'Vatra's Quests, Uddanu",
        master = "Tamriel Rebuilt", text = "Decapitate the Camonna Tong."
    },
    {
        id = "TR_m7_JNS_TheBoss_Consolidation",
        name = "Consolidation",
        category = "Factions | Ja-Natta Syndicate",
        subcategory = "K'Vatra's Quests, Uddanu",
        master = "Tamriel Rebuilt", text = "Clean house."
    },
    {
        id = "TR_m2_MG_Francine1",
        name = "Letter of Resignation",
        category = "Factions | Mages Guild",
        subcategory = "Francine Aldard's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Deliver Francine's letter of resignation to her old Telvanni master."
    },
    {
        id = "TR_m2_MG_Francine2",
        name = "Field Research",
        category = "Factions | Mages Guild",
        subcategory = "Francine Aldard's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Try to ask for permission to conduct research in Necrom's bonewalker smithies."
    },
    {
        id = "TR_m2_MG_Francine3",
        name = "Investigation at Fort Windmoth",
        category = "Factions | Mages Guild",
        subcategory = "Francine Aldard's Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Find out the reason behind an arrest warrant."
    },
    {
        id = "TR_m2_MG_Polodie1",
        name = "Striking Roots",
        category = "Factions | Mages Guild",
        subcategory = "Ranosa Orrels' Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Scour Nedothril for horn lily bulbs and timsa-come-by flowers."
    },
    {
        id = "TR_m2_MG_Polodie2",
        name = "Harvest Time in Akamora",
        category = "Factions | Mages Guild",
        subcategory = "Ranosa Orrels' Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Deliver paralysis resistance potions to the guard tower."
    },
    {
        id = "TR_m2_MG_Ranosa1",
        name = "A Rare Enchantment",
        category = "Factions | Mages Guild",
        subcategory = "Ranosa Orrels' Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Obtain an amulet from the local temple."
    },
    {
        id = "TR_m2_MG_Ranosa2",
        name = "Interview with a Vampire",
        category = "Factions | Mages Guild",
        subcategory = "Ranosa Orrels' Quests, Akamora Guild",
        master = "Tamriel Rebuilt", text = "Ask questions on vampirism to an isolated pack."
    },
    {
        id = "TR_m3_AT_MG01",
        name = "A Soulful Demonstration",
        category = "Factions | Mages Guild",
        subcategory = "Tynachos' Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Prove your ability to trap a soul."
    },
    {
        id = "TR_m3_AT_MG02",
        name = "Rowdy Anne's Soul",
        category = "Factions | Mages Guild",
        subcategory = "Tynachos' Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Hook the soul of a fabled fish."
    },
    {
        id = "TR_m3_AT_MG03",
        name = "Velk's Soul",
        category = "Factions | Mages Guild",
        subcategory = "Tynachos' Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Commit sacrilege for the collection."
    },
    {
        id = "TR_m3_AT_MG04",
        name = "Armun Kagouti's Soul",
        category = "Factions | Mages Guild",
        subcategory = "Tynachos' Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Take down an apex predator of the Armun Ashlands."
    },
    {
        id = "TR_m3_AT_MG05",
        name = "Kor-An-Taketh's Soul",
        category = "Factions | Mages Guild",
        subcategory = "Tynachos' Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Strike deals for rare souls with Firewatch's collectors."
    },
    {
        id = "TR_m3_AT_MG06",
        name = "Yathosil's Soul",
        category = "Factions | Mages Guild",
        subcategory = "Tynachos' Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Ensnare a powerful Spider Daedra."
    },
    {
        id = "TR_m3_AT_MG07",
        name = "The Creature in the Lake's Soul",
        category = "Factions | Mages Guild",
        subcategory = "Tynachos' Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Spirit away royalty in the stygian deeps."
    },
    {
        id = "TR_m3_AT_MGBonus",
        name = "Azura's Star",
        category = "Factions | Mages Guild",
        subcategory = "Tynachos' Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Make a godly gift to Tynachos' collection."
    },
    {
        id = "TR_m4_MG_Ando_1",
        name = "On Daedric Design",
        category = "Factions | Mages Guild",
        subcategory = "Ethalvora's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Retrieve a rare tome for Ethalvora."
    },
    {
        id = "TR_m4_MG_Ando_2",
        name = "A Shock to the Senses",
        category = "Factions | Mages Guild",
        subcategory = "Ethalvora's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Handle an apprentice's shocking behavior."
    },
    {
        id = "TR_m4_MG_Ando_3",
        name = "Hyperbolic Tesselation",
        category = "Factions | Mages Guild",
        subcategory = "Ethalvora's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Assist an expert on Daedric architecture."
    },
    {
        id = "TR_m4_MG_Ando_4",
        name = "Cell Bound",
        category = "Factions | Mages Guild",
        subcategory = "Ethalvora's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Negotiate the release of a criminal mage."
    },
    {
        id = "TR_m4_MG_Ando_5",
        name = "Kurhu",
        category = "Factions | Mages Guild",
        subcategory = "Ethalvora's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Barter with bandits for rare magical goods."
    },
    {
        id = "TR_m4_MG_Ando_6",
        name = "Anashbibi",
        category = "Factions | Mages Guild",
        subcategory = "Ethalvora's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Pluck a strange crystal from a glacier-bound ruin."
    },
    {
        id = "TR_m4_MG_Ando_7",
        name = "Arrange an Accident for Adric Jerenise",
        category = "Factions | Mages Guild",
        subcategory = "Ethalvora's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Make a journey through the Armun Ashlands a little more treacherous..."
    },
    {
        id = "TR_m4_MG_Ando_8, TR_m4_MG_Ando_8a",
        name = "Axiomatic Inversion",
        category = "Factions | Mages Guild",
        subcategory = "Ethalvora's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "Tempt catastrophe with a daring magical heist."
    },
    {
        id = "TR_m1_FW_MG01",
        name = "Lady's Mantle",
        category = "Factions | Mages Guild",
        subcategory = "Halan Macrinus' Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Collect a rare Colovian plant."
    },
    {
        id = "TR_m1_FW_MG02",
        name = "Delivery for Dagmund",
        category = "Factions | Mages Guild",
        subcategory = "Halan Macrinus' Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "An uplifting tale in farflung Nivalis."
    },
    {
        id = "TR_m1_FW_MG03",
        name = "The Ring of Ineptitude",
        category = "Factions | Mages Guild",
        subcategory = "Banvira Auctoria's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Locate a powerful ring located in an ancestral tomb."
    },
    {
        id = "TR_m1_FW_MG04",
        name = "Counterintelligence",
        category = "Factions | Mages Guild",
        subcategory = "Banvira Auctoria's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Even a mage can know too much."
    },
    {
        id = "TR_m1_FW_MG05",
        name = "Kill Shalath Abkala",
        category = "Factions | Mages Guild",
        subcategory = "Banvira Auctoria's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Enter a necromancer's volcanic hideaway."
    },
    {
        id = "TR_m1_FW_MG06",
        name = "The Tower of the Enchantress",
        category = "Factions | Mages Guild",
        subcategory = "Banvira Auctoria's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Seek a rare scroll in the halls of a mysterious sorceress."
    },
    {
        id = "TR_m1_FW_MG07",
        name = "Yamandalkal",
        category = "Factions | Mages Guild",
        subcategory = "Gindaman's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Parley with a lord of Oblivion."
    },
    {
        id = "TR_m1_FW_MG07a",
        name = "Deal with a Devil",
        category = "Factions | Mages Guild",
        subcategory = "Gindaman's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "A clash of a Xivilai and an Odylic Mage."
    },
    {
        id = "TR_m1_FW_MG08",
        name = "Double Agent",
        category = "Factions | Mages Guild",
        subcategory = "Gindaman's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Subvert a Telvanni spy."
    },
    {
        id = "TR_m1_FW_MG09",
        name = "The Pawns of the Outer Planes",
        category = "Factions | Mages Guild",
        subcategory = "Gindaman's Quests, Firewatch Guild",
        master = "Tamriel Rebuilt", text = "Banish a meddling Dremora Lord."
    },
    {
        id = "TR_m2_MG_Areanne1",
        name = "Starry-Eyed",
        category = "Factions | Mages Guild",
        subcategory = "Areanne Vara's Quests, Helnim Guild",
        master = "Tamriel Rebuilt", text = "Areanne Vara needs eyestar eyes."
    },
    {
        id = "TR_M2_MG_Areanne2",
        name = "Lamplit",
        category = "Factions | Mages Guild",
        subcategory = "Areanne Vara's Quests, Helnim Guild",
        master = "Tamriel Rebuilt", text = "Discover the mission of a tight-lipped Lamp Knight."
    },
    {
        id = "TR_m7_Ns_MG_Alch",
        name = "Alchemical Erratum",
        category = "Factions | Mages Guild",
        subcategory = "Errata Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Get a potion for Ophelia."
    },
    {
        id = "TR_m7_Ns_MG_Alt",
        name = "Altered Erratum",
        category = "Factions | Mages Guild",
        subcategory = "Errata Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Deliver a scroll for Malvyn Tinur."
    },
    {
        id = "TR_m7_Ns_MG_Conj",
        name = "Conjured Erratum",
        category = "Factions | Mages Guild",
        subcategory = "Errata Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Trap souls for Waterfall-Beneath-Cloudy-Sky."
    },
    {
        id = "TR_m7_Ns_MG_Des, TR_m7_Ns_MG_DesA",
        name = "Destructive Erratum",
        category = "Factions | Mages Guild",
        subcategory = "Errata Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Seek out a master of destruction magic."
    },
    {
        id = "TR_m7_Ns_MG_Ench",
        name = "Enchanted Erratum",
        category = "Factions | Mages Guild",
        subcategory = "Errata Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Help Anatolius repair the BALROG."
    },
    {
        id = "TR_m7_Ns_MG_Ill",
        name = "Illusory Erratum",
        category = "Factions | Mages Guild",
        subcategory = "Errata Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Help Nolidrando recover a sensitive tome."
    },
    {
        id = "TR_m7_Ns_MG_Mys, TR_m7_Ns_MG_MysA, TR_m7_Ns_MG_MysB, TR_m7_Ns_MG_MysC",
        name = "Mystic Erratum",
        category = "Factions | Mages Guild",
        subcategory = "Errata Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Oh the places you'll go, involuntarily."
    },
    {
        id = "TR_m7_Ns_MG_Rest",
        name = "Restored Erratum",
        category = "Factions | Mages Guild",
        subcategory = "Errata Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Acquire Hemlock seeds for Konn Light-Kissed"
    },
    {
        id = "TR_m7_Ns_MG_Arch01",
        name = "Dead Magic",
        category = "Factions | Mages Guild",
        subcategory = "Ralsa Ondusi's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Secure a Dremora Lord's assistance."
    },
    {
        id = "TR_m7_Ns_MG_Arch02",
        name = "Passwall",
        category = "Factions | Mages Guild",
        subcategory = "Ralsa Ondusi's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Recover an ancient amulet."
    },
    {
        id = "TR_m7_Ns_MG_Arch03",
        name = "Anti-Magic",
        category = "Factions | Mages Guild",
        subcategory = "Ralsa Ondusi's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Carry out an inter-dimensional rescue."
    },
    {
        id = "TR_m3_MG_OE_Restocking",
        name = "Restocking",
        category = "Factions | Mages Guild",
        subcategory = "Amelphia Tarramon's Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "Gather ingredients for Amelphia Tarramon."
    },
    {
        id = "TR_m3_MG_OE_FourLiquors",
        name = "Four Types of Liquor",
        category = "Factions | Mages Guild",
        subcategory = "Amelphia Tarramon's Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "An alchemical apprentice fancies a drink, or four."
    },
    {
        id = "TR_m3_MG_OE_Guards1, TR_m3_MG_OE_Guards2",
        name = "Guars and Guards",
        category = "Factions | Mages Guild",
        subcategory = "Arquebald Vene's Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "Help a guard who has been put out to pasture."
    },
    {
        id = "TR_m3_MG_OE_WateryFate, TR_m3_MG_OE_WateryFate2",
        name = "A Watery Fate",
        category = "Factions | Mages Guild",
        subcategory = "Arquebald Vene's Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "Track down a drunken mage."
    },
    {
        id = "TR_m3_MG_OE_GhostGem",
        name = "Ghost in a Gem",
        category = "Factions | Mages Guild",
        subcategory = "Valkreia Krex's Quests, Old Ebonheart Guild",
        master = "Tamriel Rebuilt", text = "Resolve a necromantic dilemma."
    },
    {
        id = "TR_m7_Oth_MG_1",
        name = "Eviction Notice",
        category = "Factions | Mages Guild",
        subcategory = "Kharal gra-Ratash's Quests, Othmura Guild",
        master = "Tamriel Rebuilt", text = "Clear squatters from the site of a planned investigation."
    },
    {
        id = "TR_m7_Oth_MG_2",
        name = "Letter for Ondusi",
        category = "Factions | Mages Guild",
        subcategory = "Kharal gra-Ratash's Quests, Othmura Guild",
        master = "Tamriel Rebuilt", text = "Inform the Narsis guildhall of the investigation's beginning."
    },
    {
        id = "TR_m7_Oth_MG_3",
        name = "The Ghost Ring",
        category = "Factions | Mages Guild",
        subcategory = "Kharal gra-Ratash's Quests, Othmura Guild",
        master = "Tamriel Rebuilt", text = "A dungeon delve tests your spell repertoire."
    },
    {
        id = "TR_m0_MG_Ajira",
        name = "A Letter to a Friend",
        category = "Factions | Mages Guild",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = "Bring good news to a friend on the mainland."
    },
    {
        id = "TR_m0_MG_Tenyeminwe",
        name = "A Message to Firewatch",
        category = "Factions | Mages Guild",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = "Deliver unfinished research to a colleague."
    },
    {
        id = "TR_m4_MT_Llirala",
        name = "Writ for Llirala Arys",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Lawman of House Hlaalu."
    },
    {
        id = "TR_m4_MT_Serali",
        name = "Writ for Serali Beralam",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Hlaalu retainer."
    },
    {
        id = "TR_m3_MT_Varru",
        name = "Writ for Varru Envano",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a hetman's husband."
    },
    {
        id = "TR_m4_MT_Ilmeni",
        name = "Writ for Ilmeni",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Dunmer smuggler."
    },
    {
        id = "TR_m4_MT_NadrasArvel",
        name = "Writ for Nadras Arvel",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a paranoid aristocrat."
    },
    {
        id = "TR_m4_MT_Omayn",
        name = "Writ for Nalvos Omayn",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a dissolute noble."
    },
    {
        id = "TR_m4_MT_Dransa",
        name = "Writ for Dransa",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Dunmer tomb raider."
    },
    {
        id = "TR_m3_MT_Dileru",
        name = "Writ for Dileru Dras",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execut-wait, what's \"illegal\"?"
    },
    {
        id = "TR_m4_MT_Almse",
        name = "Writ for Almse Ramaran",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Redoran lord's daughter."
    },
    {
        id = "TR_m3_MT_Indriri",
        name = "Writ for Indriri Veram",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Redoran of remote Uman."
    },
    {
        id = "TR_m7_MT_Peleri",
        name = "Writ for Peleri Hlaalu",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Hlerynhul noble."
    },
    {
        id = "TR_m7_MT_Turesa",
        name = "Writ for Turesa Veldyn",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Kwama expert."
    },
    {
        id = "TR_m7_MT_Nelyos",
        name = "Writ for Nelyos Givaron",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute an outlaw gang leader."
    },
    {
        id = "TR_m7_MT_Ulvys",
        name = "Writ for Ulvys Nerano",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Hlaalu egg mine foreman."
    },
    {
        id = "TR_m7_MT_Hagar",
        name = "Writ for Hagar Stone-Hand",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execut-wait, an assassin!"
    },
    {
        id = "TR_m3_MT_Felrar",
        name = "Writ for Felrar Berathi",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Hlan Oek garrison guard."
    },
    {
        id = "TR_m3_MT_Mirasa",
        name = "Writ for Mirasa Rurvyn",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a noble pilgrim."
    },
    {
        id = "TR_m3_MT_Ulyn",
        name = "Writ for Ulyn Menathren",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a killer of pilgrims."
    },
    {
        id = "TR_m4_MT_Jebyn",
        name = "Writ for Jelyn Indo",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute Jelyn Indo."
    },
    {
        id = "TR_m7_MT_Milena",
        name = "Writ for Milena Farano",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Narsis noble."
    },
    {
        id = "TR_m7_MT_Ibarmas",
        name = "Writ for Ibarmas-Zel",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Shinathi hunter."
    },
    {
        id = "TR_m7_MT_Selvura",
        name = "Writ for Selvura Indosi",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a notorious smuggler."
    },
    {
        id = "TR_m4_MT_Tolmse",
        name = "Writ for Tolmse Indarys",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a cultist of Sheogorath."
    },
    {
        id = "TR_m3_MT_Arin",
        name = "Writ for Arin Andathril",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably re-execute a restless Indoril of Tur Julan."
    },
    {
        id = "TR_m3_MT_Ughash",
        name = "Writ for Ughash gro-Mazkun",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a fearsome Malahk Orc."
    },
    {
        id = "TR_m7_MT_Llevas",
        name = "Writ for Llevas Uvalor",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a Narsis captain and formidable warrior."
    },
    {
        id = "TR_m7_MT_Hlevis",
        name = "Writ for Hlevis Relnim",
        category = "Factions | Morag Tong",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Honorably execute a daedric cultist of Malacath."
    },
    {
        id = "TR_m3_MT_Sp_Dils",
        name = "The Elusive Vodryn Talnaris",
        category = "Factions | Morag Tong",
        subcategory = "Hlenil Saravyne's Quests, Almas Thirr Guild",
        master = "Tamriel Rebuilt", text = "Hunt down a traitor to the Morag Tong."
    },
    {
        id = "TR_m4_MT_Sp_Gulmon, TR_m4_MT_SP_Gulmon_Writ",
        name = "A Reluctant Execution",
        category = "Factions | Morag Tong",
        subcategory = "Dareni Dulo's Quests, Bal Foyen Guild",
        master = "Tamriel Rebuilt", text = "An assassin dithers - determine why."
    },
    {
        id = "TR_m7_MT_Special1, TR_m7_MT_Special1a",
        name = "A Stolen Writ",
        category = "Factions | Morag Tong",
        subcategory = "Myaru Sareleth's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Track down murderers working outside of the Morag Tong."
    },
    {
        id = "TR_m7_MT_Special2",
        name = "Investigating a Lead",
        category = "Factions | Morag Tong",
        subcategory = "Myaru Sareleth's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Identify a Dark Brotherhood agent."
    },
    {
        id = "TR_m7_MT_Special3",
        name = "The Blessing of Mephala",
        category = "Factions | Morag Tong",
        subcategory = "Myaru Sareleth's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Seek the approval and artifacts of the Daedric Prince Mephala."
    },
    {
        id = "TR_m7_MT_Special3a",
        name = "Cancelled Delivery",
        category = "Factions | Morag Tong",
        subcategory = "Myaru Sareleth's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Execute a Dark Brotherhood agent."
    },
    {
        id = "TR_m7_MT_Special4",
        name = "Dusk for the Night Mother",
        category = "Factions | Morag Tong",
        subcategory = "Myaru Sareleth's Quests, Narsis Guild",
        master = "Tamriel Rebuilt", text = "Eliminate a vile encroachment of Sithis."
    },
    {
        id = "TR_m1_MT_HlaaluAmulet",
        name = "Amulet of Methas Hlaalu",
        category = "Factions | Morag Tong",
        subcategory = "Eno Hlaalu's Quests, Vounoura",
        master = "Tamriel Rebuilt", text = "Honor the wish of a retired Grandmaster."
    },
    {
        id = "TR_m7_DB_Special1",
        name = "Betray the Tong",
        category = "Factions | Morag Tong",
        subcategory = "Jeanne Duchamp's Quests, Haniridun",
        master = "Tamriel Rebuilt", text = "Switch up your assassination supplier."
    },
    {
        id = "TR_m3_TG_AT_Q0, TR_m3_TG_AT_Q0a",
        name = "Find Gordol the Scrivener",
        category = "Factions | Thieves Guild",
        subcategory = "Gordol the Scrivener's Quests, Almas Thirr",
        master = "Tamriel Rebuilt", text = "Uncover the Thieves Guild den in Almas Thirr."
    },
    {
        id = "TR_m3_TG_AT_Q1",
        name = "Swindle the Pilgrims",
        category = "Factions | Thieves Guild",
        subcategory = "Gordol the Scrivener's Quests, Almas Thirr",
        master = "Tamriel Rebuilt", text = "Prove your worth by robbing pilgrims under the Ordinators' noses."
    },
    {
        id = "TR_m3_TG_AT_Q2",
        name = "Dreugh Spear",
        category = "Factions | Thieves Guild",
        subcategory = "Gordol the Scrivener's Quests, Almas Thirr",
        master = "Tamriel Rebuilt", text = "Lift a rare weapon from a drillmaster's apartment."
    },
    {
        id = "TR_m3_TG_AT_Q3, TR_m3_TG_AT_Q3a",
        name = "Find Flavius Celto",
        category = "Factions | Thieves Guild",
        subcategory = "Gordol the Scrivener's Quests, Almas Thirr",
        master = "Tamriel Rebuilt", text = "Discover the fate of a brother thief sailing in dangerous waters."
    },
    {
        id = "TR_m3_TG_AT_Q4",
        name = "Stolen Punavit",
        category = "Factions | Thieves Guild",
        subcategory = "Gordol the Scrivener's Quests, Almas Thirr",
        master = "Tamriel Rebuilt", text = "Acquire the smuggled substance of a criminal rival."
    },
    {
        id = "TR_m3_TG_AT_Q5",
        name = "Skooma at the Mundrethi Plantation",
        category = "Factions | Thieves Guild",
        subcategory = "Gordol the Scrivener's Quests, Almas Thirr",
        master = "Tamriel Rebuilt", text = "Seek the source of an illicit trade."
    },
    {
        id = "TR_m3_TG_AT_Q6, TR_m3_TG_AT_Q6a",
        name = "Smuggling along the Sacred Path",
        category = "Factions | Thieves Guild",
        subcategory = "Gordol the Scrivener's Quests, Almas Thirr",
        master = "Tamriel Rebuilt", text = "The Tong overreach and some careful thieving can get the Temple involved..."
    },
    {
        id = "TR_m4_TG_Shei1",
        name = "A Guild in Ruins",
        category = "Factions | Thieves Guild",
        subcategory = "Shei's Quests, Shei's House and Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Find a fresh start in stale halls."
    },
    {
        id = "TR_m4_TG_Shei2, TR_m4_TG_Shei3B, TR_m4_TG_Shei3C, TR_m4_TG_Shei3D",
        name = "Thieves Like Us",
        category = "Factions | Thieves Guild",
        subcategory = "Shei's Quests, Shei's House and Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Run a recruitment drive for organized crime."
    },
    {
        id = "TR_m4_TG_Shei4, TR_m4_TG_Shei4B",
        name = "Good Fences, Good Neighbors",
        category = "Factions | Thieves Guild",
        subcategory = "Shei's Quests, Shei's House and Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Make first contact with a famous fence."
    },
    {
        id = "TR_m4_TG_ThreeEyes1, TR_m4_TG_ThreeEyes1B",
        name = "Thoricles' Bane",
        category = "Factions | Thieves Guild",
        subcategory = "Shei's Quests, Shei's House and Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Deliver a high value artifact to an Imperial arms collector."
    },
    {
        id = "TR_m4_TG_Shei5, TR_m4_TG_Shei5B, TR_m4_TG_Shei5C, TR_m4_TG_Shei5D, TR_m4_TG_Shei5E, TR_m4_TG_Shei5F",
        name = "Sugary Business",
        category = "Factions | Thieves Guild",
        subcategory = "Shei's Quests, Shei's House and Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Collapse or commandeer the skooma trade in Bal Foyen."
    },
    {
        id = "TR_m4_TG_ThreeEyes2, TR_m4_TG_ThreeEyes2B, TR_m4_TG_ThreeEyes2C, TR_m4_TG_ThreeEyes2D, TR_m4_TG_ThreeEyes2E",
        name = "Scandalous Letters",
        category = "Factions | Thieves Guild",
        subcategory = "Shei's Quests, Shei's House and Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "An agitated noble requests a return to sender."
    },
    {
        id = "TR_m4_TG_Shei6, TR_m4_TG_Shei6B, TR_m4_TG_Shei6C",
        name = "Bal Foyen Regained",
        category = "Factions | Thieves Guild",
        subcategory = "Shei's Quests, Shei's House and Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "The fate of the new guild hangs in the balance..."
    },
    {
        id = "TR_m4_TG_Marug1",
        name = "The Oldest Trick in the Book",
        category = "Factions | Thieves Guild",
        subcategory = "Marug gro-Meridius' Quests, Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Conduct a theft in volume."
    },
    {
        id = "TR_m4_TG_Rilmas1",
        name = "Ain't Stabbed a Man Since",
        category = "Factions | Thieves Guild",
        subcategory = "Rowdy Rilmas' Quests, Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Convey a thief's apology to his victim."
    },
    {
        id = "TR_m4_TG_Rilmas2",
        name = "Galdres Beran's Vigorish",
        category = "Factions | Thieves Guild",
        subcategory = "Rowdy Rilmas' Quests, Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Show a reluctant potter the need for 'protection'."
    },
    {
        id = "TR_m4_TG_Tattara1, TR_m4_TG_Tattara1B, TR_m4_TG_Tattara1C",
        name = "Disarming the Tong",
        category = "Factions | Thieves Guild",
        subcategory = "Tattara's Quests, Bthuangthuv, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Take the Tong's blades before they can be used against you."
    },
    {
        id = "TR_m1_FW_TG1_Brandy",
        name = "Cyrodiilic Brandy",
        category = "Factions | Thieves Guild",
        subcategory = "Fitz-Fitz's Quests, The Howling Noose, Firewatch",
        master = "Tamriel Rebuilt", text = "Get some Cyrodiilic Brandy as a personal request."
    },
    {
        id = "TR_m1_FW_TG2_Candle",
        name = "Friela Antoni's Candlesticks",
        category = "Factions | Thieves Guild",
        subcategory = "Fitz-Fitz's Quests, The Howling Noose, Firewatch",
        master = "Tamriel Rebuilt", text = "Repossess Friela Antoni's candlesticks."
    },
    {
        id = "TR_m1_FW_TG3_Dagger",
        name = "Hrongal's Dagger",
        category = "Factions | Thieves Guild",
        subcategory = "Fitz-Fitz's Quests, The Howling Noose, Firewatch",
        master = "Tamriel Rebuilt", text = "Snatch a blade from a drunken Nord."
    },
    {
        id = "TR_m1_FW_TG4_Letter",
        name = "Letter to Selura",
        category = "Factions | Thieves Guild",
        subcategory = "Fitz-Fitz's Quests, The Howling Noose, Firewatch",
        master = "Tamriel Rebuilt", text = "Filch kompromat on a court mage."
    },
    {
        id = "TR_m1_FW_TG5_Helm",
        name = "Devil Cephalopod Helm",
        category = "Factions | Thieves Guild",
        subcategory = "Fitz-Fitz's Quests, The Howling Noose, Firewatch",
        master = "Tamriel Rebuilt", text = "Fitz-Fitz wants this expensive helmet and you should steal it."
    },
    {
        id = "TR_m1_FW_TG6_Stone",
        name = "The Stone of Septimia",
        category = "Factions | Thieves Guild",
        subcategory = "Fitz-Fitz's Quests, The Howling Noose, Firewatch",
        master = "Tamriel Rebuilt", text = "It belonged to a museum!"
    },
    {
        id = "TR_m2_He_TG1",
        name = "Find the Helnim Gang",
        category = "Factions | Thieves Guild",
        subcategory = "Silniel the Maven's Quests, The Howling Noose, Firewatch",
        master = "Tamriel Rebuilt", text = "Track down an independent gang of thieves in Helnim."
    },
    {
        id = "TR_m2_He_TG2",
        name = "Deal with Servas Capris",
        category = "Factions | Thieves Guild",
        subcategory = "Greedy Hofmund's Quests, Falkoth: Clothier, Helnim",
        master = "Tamriel Rebuilt", text = "Divert Servas Capris' attention from the Helnim gang."
    },
    {
        id = "TR_m2_He_TG3",
        name = "Deal with Disela",
        category = "Factions | Thieves Guild",
        subcategory = "Greedy Hofmund's Quests, Falkoth: Clothier, Helnim",
        master = "Tamriel Rebuilt", text = "Uncover Caedan Jorval's corruption for Disela."
    },
    {
        id = "TR_m2_He_TG4",
        name = "The Tel Gilan Job",
        category = "Factions | Thieves Guild",
        subcategory = "Greedy Hofmund's Quests, Falkoth: Clothier, Helnim",
        master = "Tamriel Rebuilt", text = "Convince the Helnim thieves to join the guild by breaking into a Telvanni vault."
    },
    {
        id = "TR_m7_Ns_TG_1",
        name = "Show Me Your Moves",
        category = "Factions | Thieves Guild",
        subcategory = "Thorleif Stage-Hand's Quests, Redwater Theater, Narsis",
        master = "Tamriel Rebuilt", text = "Steal a potion for a Fighters Guild member."
    },
    {
        id = "TR_m7_Ns_TG_2",
        name = "Offer They Can't Refuse",
        category = "Factions | Thieves Guild",
        subcategory = "Thorleif Stage-Hand's Quests, Redwater Theater, Narsis",
        master = "Tamriel Rebuilt", text = "Help maintain the theater's faltering front."
    },
    {
        id = "TR_m7_Ns_TG_3",
        name = "Friends in Low Places",
        category = "Factions | Thieves Guild",
        subcategory = "Thorleif Stage-Hand's Quests, Redwater Theater, Narsis",
        master = "Tamriel Rebuilt", text = "A publican calls on the Thieves Guild's promised protection."
    },
    {
        id = "TR_m7_Ns_TG_4",
        name = "The Devil You Know",
        category = "Factions | Thieves Guild",
        subcategory = "Thorleif Stage-Hand's Quests, Redwater Theater, Narsis",
        master = "Tamriel Rebuilt", text = "Hamper the drug trade of the Ja-Natta Syndicate."
    },
    {
        id = "TR_m7_Ns_TG_5",
        name = "Born to be Wild",
        category = "Factions | Thieves Guild",
        subcategory = "Thorleif Stage-Hand's Quests, Redwater Theater, Narsis",
        master = "Tamriel Rebuilt", text = "Raid a plantation vault for an enchanted Ayleid longbow."
    },
    {
        id = "TR_m7_Ns_TG_6, TR_m7_Ns_TG_6a, TR_m7_Ns_TG_6b",
        name = "Flying Too Close",
        category = "Factions | Thieves Guild",
        subcategory = "Thorleif Stage-Hand's Quests, Redwater Theater, Narsis",
        master = "Tamriel Rebuilt", text = "Rival gangs sniffing around means it's time to take precautions."
    },
    {
        id = "TR_m7_Ns_TG_7",
        name = "Take the House",
        category = "Factions | Thieves Guild",
        subcategory = "Thorleif Stage-Hand's Quests, Redwater Theater, Narsis",
        master = "Tamriel Rebuilt", text = "Rip the Camonna Tong's treasure hoard out from under them."
    },
    {
        id = "TR_m7_Ns_TG_8",
        name = "Before the Dust Settles",
        category = "Factions | Thieves Guild",
        subcategory = "Thorleif Stage-Hand's Quests, Redwater Theater, Narsis",
        master = "Tamriel Rebuilt", text = "Steal stars from the Duke of Narsis District."
    },
    {
        id = "TR_m7_Ns_TG_9",
        name = "To the Limit",
        category = "Factions | Thieves Guild",
        subcategory = "Thorleif Stage-Hand's Quests, Redwater Theater, Narsis",
        master = "Tamriel Rebuilt", text = "Steal a most treasured possession of House Hlaalu."
    },
    {
        id = "TR_m3_TG_Fentus1",
        name = "The Eye of Argonia",
        category = "Factions | Thieves Guild",
        subcategory = "Cap'n Fentus' Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Steal the legendary Eye of Argonia from a warship docked at the Old Ebonheart harbor."
    },
    {
        id = "TR_m3_TG_Fentus2",
        name = "High-Flying Plans",
        category = "Factions | Thieves Guild",
        subcategory = "Cap'n Fentus' Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Bring Cap'n Fentus some Dwemer airship plans."
    },
    {
        id = "TR_m3_TG_Fentus3",
        name = "Thieving Rivalry",
        category = "Factions | Thieves Guild",
        subcategory = "Cap'n Fentus' Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Retrieve a valuable book from a tomb before a fellow guild member does."
    },
    {
        id = "TR_m3_TG_Fentus3b, TR_m3_TG_Fentus3c",
        name = "Happy Birthday, Ruma Soanix",
        category = "Factions | Thieves Guild",
        subcategory = "Cap'n Fentus' Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Infiltrate a dinner party and steal a valuable document."
    },
    {
        id = "TR_m3_TG_Fentus3d",
        name = "When the Nord's Away...",
        category = "Factions | Thieves Guild",
        subcategory = "Cap'n Fentus' Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Steal a pair of enchanted boots while their owner is on a hunting trip."
    },
    {
        id = "TR_m3_TG_Fentus4",
        name = "A Message from Mister Delagia",
        category = "Factions | Thieves Guild",
        subcategory = "Cap'n Fentus' Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Rob a Nibenese silk merchant who is doing business with Delagia's gang."
    },
    {
        id = "TR_m3_TG_Fentus5b, TR_m3_TG_Fentus5b",
        name = "Lost in Chunzefk",
        category = "Factions | Thieves Guild",
        subcategory = "Cap'n Fentus' Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Rescue a fellow thief who has not returned from a Dwemer ruin."
    },
    {
        id = "TR_m3_TG_Moranie1",
        name = "Facing Eviction",
        category = "Factions | Thieves Guild",
        subcategory = "Wry-Eye Moranie's Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Help a poor woman who is indebted to Delagia's gang."
    },
    {
        id = "TR_m3_TG_Moranie2, TR_m3_TG_Moranie2b, TR_m3_TG_Moranie2c",
        name = "Infiltrating the Gang",
        category = "Factions | Thieves Guild",
        subcategory = "Wry-Eye Moranie's Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Join Delagia's gang and find leverage against Otrebus Delagia."
    },
    {
        id = "TR_m3_TG_Moranie3, TR_m3_TG_Moranie3b, TR_m3_TG_Moranie3c, TR_m3_TG_Moranie3d, TR_m3_TG_Moranie3e",
        name = "An Empress' Ransom",
        category = "Factions | Thieves Guild",
        subcategory = "Wry-Eye Moranie's Quests, The Empress Katariah, Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Exchange a royal artifact for the freedom of the Thieves Guild leaders."
    },
    {
        id = "TR_m0_TG_SecretMasterPick",
        name = "The Secret Master's Lockpick",
        category = "Factions | Thieves Guild",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = "Deliver a Secret Master's Lockpick to the mainland."
    },
    {
        id = "TR_m0_TongueToad",
        name = "Tongue-Toad's Retirement",
        category = "Factions | Thieves Guild",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = ""
    },
    {
        id = "TR_TT_Q1",
        name = "Initiation",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Join the illustrious Tribunal Temple."
    },
    {
        id = "TR_m3_TT_Bloodstone",
        name = "Pilgrimage to the Bloodstone Shrine",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Make the pilgrimage to the Bloodstone Shrine."
    },
    {
        id = "TR_m1_TT_1b",
        name = "Pilgrimage to the Isle of Arches",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Bring some slaughterfish scales with you and visit this wild island."
    },
    {
        id = "TR_m7_TT_PedestalMuatra",
        name = "Pilgrimage to Muatra's Pedestal",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Make an offering to the shrine that holds Vivec's own spear."
    },
    {
        id = "TR_m4_TT_ShrineAlmaFury",
        name = "Pilgrimage to the Shrine of Almalexia's Fury",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Visit the monument to an Akaviri army's destruction."
    },
    {
        id = "TR_m4_TT_ShrineBodrum",
        name = "Pilgrimage to the Shrine to the Battle of Bodrum",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Journey to the site of Vivec's victory over the Reman Empire."
    },
    {
        id = "TR_m2_TT_1a",
        name = "Pilgrimage to the Shrine of the Boethian Falls",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Offer a Black Rose in honor of Almalexia."
    },
    {
        id = "TR_m7_TT_ShrineConviction",
        name = "Pilgrimage to the Shrine of Conviction",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Visit the site of the conversion of the Shinathi tribespeople."
    },
    {
        id = "TR_m1_TT_1c",
        name = "Pilgrimage to the Shrine of Foresight",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "This shrine is situated at Aegondo Point, a beautiful and dangerous cape."
    },
    {
        id = "TR_m2_TT_1c",
        name = "Pilgrimage to the Shrine of Hindsight",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Travel to the cave where St. Delyn the Wise made his contributions to Temple canon."
    },
    {
        id = "TR_m1_TT_1a",
        name = "Pilgrimage to the Shrine of Purging",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Offer a daedric heart near the famous cave of Dadrunibi."
    },
    {
        id = "TR_m7_HO_TT_ShrineHO",
        name = "Pilgrimage to the Shrine of Seryn's Devotion",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Re-enact the fate of a dying soldier."
    },
    {
        id = "TR_m2_TT_1b",
        name = "Pilgrimage to the Shrine of Solitude",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Journey to the spot where Sotha Sil received wisdom from Azura's heralds."
    },
    {
        id = "TR_m4_TT_ShrineOlmsRest",
        name = "Pilgrimage to the Tomb of St Olms",
        category = "Factions | Tribunal Temple",
        subcategory = "General Quests, Any Temple",
        master = "Tamriel Rebuilt", text = "Re-enact the final meditation of a dying saint."
    },
    {
        id = "TR_m7_AI_TT_Q1",
        name = "Sword or Sermon",
        category = "Factions | Tribunal Temple",
        subcategory = "Muran Samarys' Quests, Ald Iuval, Temple",
        master = "Tamriel Rebuilt", text = "Admonish or punish three robbers of Temple faithful."
    },
    {
        id = "TR_m7_AI_TT_Q2",
        name = "Gold and Graces",
        category = "Factions | Tribunal Temple",
        subcategory = "Muran Samarys' Quests, Ald Iuval, Temple",
        master = "Tamriel Rebuilt", text = "Choose the fate of funding from a sizable donation."
    },
    {
        id = "TR_m7_AI_TT_Q3",
        name = "Endless Appetite",
        category = "Factions | Tribunal Temple",
        subcategory = "Muran Samarys' Quests, Ald Iuval, Temple",
        master = "Tamriel Rebuilt", text = "A voracious Daedra troubles Ald Iuval."
    },
    {
        id = "TR_m7_AI_TT_Q4",
        name = "Overseeing a House War",
        category = "Factions | Tribunal Temple",
        subcategory = "Muran Samarys' Quests, Ald Iuval, Temple",
        master = "Tamriel Rebuilt", text = "Judge a Redoran killer of a Hlaalu warrior."
    },
    {
        id = "TR_m7_AI_TT_Q5",
        name = "Echoes of the Past",
        category = "Factions | Tribunal Temple",
        subcategory = "Muran Samarys' Quests, Ald Iuval, Temple",
        master = "Tamriel Rebuilt", text = "Recover a dagger treasured by both Temple and House Redoran."
    },
    {
        id = "TR_m7_AI_TT_Q6",
        name = "The Balance of Faith",
        category = "Factions | Tribunal Temple",
        subcategory = "Muran Samarys' Quests, Ald Iuval, Temple",
        master = "Tamriel Rebuilt", text = "The temple's master experiences the rage of loss."
    },
    {
        id = "TR_m3_TT_Lloris1, TR_m3_TT_Lloris1b, TR_m3_TT_Lloris1c",
        name = "Healing Jalor Indo",
        category = "Factions | Tribunal Temple",
        subcategory = "Lloris Dalan's Quests, Almas Thirr, Temple",
        master = "Tamriel Rebuilt", text = "Cure an ailing smith."
    },
    {
        id = "TR_m3_TT_Lloris2, TR_m3_TT_Lloris2b, TR_m3_TT_Lloris2c, TR_m3_TT_Lloris2d, TR_m3_TT_Lloris2e",
        name = "Duress of a Slave",
        category = "Factions | Tribunal Temple",
        subcategory = "Lloris Dalan's Quests, Almas Thirr, Temple",
        master = "Tamriel Rebuilt", text = "Deliver a letter to a young noble facing a moral dilemma."
    },
    {
        id = "TR_m3_TT_Lloris3, TR_m3_TT_Lloris3b, TR_m3_TT_Lloris3c, TR_m3_TT_Lloris3d",
        name = "Outlandish Heresy",
        category = "Factions | Tribunal Temple",
        subcategory = "Lloris Dalan's Quests, Almas Thirr, Temple",
        master = "Tamriel Rebuilt", text = "Deal with outlanders in Old Ebonheart."
    },
    {
        id = "TR_m3_TT_Lloris4, TR_m3_TT_Lloris4b",
        name = "Learned Proverbs",
        category = "Factions | Tribunal Temple",
        subcategory = "Lloris Dalan's Quests, Almas Thirr, Temple",
        master = "Tamriel Rebuilt", text = "Share some religious proverbs to the commoners in Almas Thirr."
    },
    {
        id = "TR_m3_TT_Lloris5, TR_m3_TT_Lloris5b, TR_m3_TT_Lloris5c, TR_m3_TT_Lloris5d, TR_m3_TT_Lloris5e, TR_m3_TT_Lloris5f, TR_m3_TT_Lloris5g, TR_m3_TT_Lloris6",
        name = "Calitia's Sanctuary",
        category = "Factions | Tribunal Temple",
        subcategory = "Lloris Dalan's Quests, Almas Thirr, Temple",
        master = "Tamriel Rebuilt", text = "Control the fate of a Hlaalu spy."
    },
    {
        id = "TR_m3_TT_Illene1, TR_m3_TT_Illene1b",
        name = "Disease of the Mind",
        category = "Factions | Tribunal Temple",
        subcategory = "Illene Teloth's Quests, Almas Thirr, Office of Intercession",
        master = "Tamriel Rebuilt", text = "Lure a mad Ordinator of War back to Serynthul."
    },
    {
        id = "TR_m3_TT_Illene2, TR_m3_TT_Illene2b, TR_m3_TT_Illene2c, TR_m3_TT_Illene2d",
        name = "Inquisition of Vys-Assanud",
        category = "Factions | Tribunal Temple",
        subcategory = "Illene Teloth's Quests, Almas Thirr, Office of Intercession",
        master = "Tamriel Rebuilt", text = "Nobody expects the Temple Inquisition!"
    },
    {
        id = "TR_m3_TT_Illene3, TR_m3_TT_Illene3b, TR_m3_TT_Illene3c, TR_m3_TT_Illene3d, TR_m3_TT_Illene3e",
        name = "A Warmonger's Counsel",
        category = "Factions | Tribunal Temple",
        subcategory = "Illene Teloth's Quests, Almas Thirr, Office of Intercession",
        master = "Tamriel Rebuilt", text = "Avert a House War."
    },
    {
        id = "TR_m3_TT_RIP, TR_m3_TT_RIP_2",
        name = "May She Rest in Peace",
        category = "Factions | Tribunal Temple",
        subcategory = "Vaden Baro's Quests, Almas Thirr, Monastery of St. Veloth",
        master = "Tamriel Rebuilt", text = "Arrange a proper cremation."
    },
    {
        id = "TR_m3_TT_floodedtomb",
        name = "A Flooded Tomb",
        category = "Factions | Tribunal Temple",
        subcategory = "Vaden Baro's Quests, Almas Thirr, Monastery of St. Veloth",
        master = "Tamriel Rebuilt", text = "Retrieve family remains from Dreugh squatters."
    },
    {
        id = "TR_m3_TT_Speaker",
        name = "Speaker for the Dead",
        category = "Factions | Tribunal Temple",
        subcategory = "Vaden Baro's Quests, Almas Thirr, Monastery of St. Veloth",
        master = "Tamriel Rebuilt", text = "Become an advocate for those beyond."
    },
    {
        id = "TR_m3_TT_Disembodied, TR_m3_TT_Disembodied2",
        name = "Disembodied",
        category = "Factions | Tribunal Temple",
        subcategory = "Vaden Baro's Quests, Almas Thirr, Monastery of St. Veloth",
        master = "Tamriel Rebuilt", text = "Investigate a haunting in Roa Dyr."
    },
    {
        id = "TR_m3_TT_FaceStealer",
        name = "The Face Stealer",
        category = "Factions | Tribunal Temple",
        subcategory = "Vaden Baro's Quests, Almas Thirr, Monastery of St. Veloth",
        master = "Tamriel Rebuilt", text = "Hunt a creature of many guises."
    },
    {
        id = "TR_m3_TT_SeeYou, TR_m3_TT_SeeYou_Arara, TR_m3_TT_SeeYou_Balver, TR_m3_TT_SeeYou_Dilale, TR_m3_TT_SeeYou_Kha, TR_m3_TT_SeeYou_Maladel, TR_m3_TT_SeeYou_Setisa",
        name = "Warm to the Touch",
        category = "Factions | Tribunal Temple",
        subcategory = "Vaden Baro's Quests, Almas Thirr, Monastery of St. Veloth",
        master = "Tamriel Rebuilt", text = "Help a restless spirit move on."
    },
    {
        id = "TR_m4_TT_WellnessCheck",
        name = "Wellness Check",
        category = "Factions | Tribunal Temple",
        subcategory = "Nalvs Andolin's Quests, Bal Foyen Temple",
        master = "Tamriel Rebuilt", text = "Console a dying Dunmer."
    },
    {
        id = "TR_m4_TT_KitchenSupplies, TR_m4_TT_KitchenSupplies_a, TR_m4_TT_KitchenSupplies_b",
        name = "Kitchen Supplies",
        category = "Factions | Tribunal Temple",
        subcategory = "Nalvs Andolin's Quests, Bal Foyen Temple",
        master = "Tamriel Rebuilt", text = "Find food for the poor, both fine and foul."
    },
    {
        id = "TR_m4_TT_TroublesomeOrc, TR_m4_TT_TroublesomeOrc_b, TR_m4_TT_TroublesomeOrc_c, TR_m4_TT_ArmunAdventure_e, TR_m4_TT_BooksBarbarians",
        name = "A Troublesome Orc",
        category = "Factions | Tribunal Temple",
        subcategory = "Nalvs Andolin's Quests, Bal Foyen Temple",
        master = "Tamriel Rebuilt", text = "A shrine has acquired an unwelcome guardian."
    },
    {
        id = "TR_m4_TT_Forgiveness",
        name = "Pilgrimage to the Shrine of Forgiveness",
        category = "Factions | Tribunal Temple",
        subcategory = "Nalvs Andolin's Quests, Bal Foyen Temple",
        master = "Tamriel Rebuilt", text = "Pay penance for your sins, real or imagined."
    },
    {
        id = "TR_m4_TT_AndothrenCharity",
        name = "Bal Foyen Charity",
        category = "Factions | Tribunal Temple",
        subcategory = "Nalvs Andolin's Quests, Bal Foyen Temple",
        master = "Tamriel Rebuilt", text = "Hawk a cure for greed to Bal Foyen nobility."
    },
    {
        id = "TR_m4_TT_ArmunAdventure, TR_m4_TT_ArmunAdventure_b, TR_m4_TT_ArmunAdventure_c, TR_m4_TT_ArmunAdventure_d, TR_m4_TT_ArmunAdventure_f",
        name = "Armun Ashlands Avenger",
        category = "Factions | Tribunal Temple",
        subcategory = "Nalvs Andolin's Quests, Bal Foyen Temple",
        master = "Tamriel Rebuilt", text = "Track down a killer of pilgrims."
    },
    {
        id = "TR_m4_TT_LastWillAndTestament",
        name = "The Last Will and Testament of Ulmon Vathri",
        category = "Factions | Tribunal Temple",
        subcategory = "Nalvs Andolin's Quests, Bal Foyen Temple",
        master = "Tamriel Rebuilt", text = "Of frauds and funerals."
    },
    {
        id = "TR_m7_HO_TT_01",
        name = "Tithe or Toll",
        category = "Factions | Tribunal Temple",
        subcategory = "Nivis Serethran's Quests, Hlan Oek Temple",
        master = "Tamriel Rebuilt", text = "Take a cut from the pilgrims traveling Veloth's Path."
    },
    {
        id = "TR_m7_HO_TT_02",
        name = "Insult to Injury",
        category = "Factions | Tribunal Temple",
        subcategory = "Nivis Serethran's Quests, Hlan Oek Temple",
        master = "Tamriel Rebuilt", text = "Uls needs healing...but from a n'wah?"
    },
    {
        id = "TR_m7_HO_TT_03",
        name = "The Pilgrim's Path",
        category = "Factions | Tribunal Temple",
        subcategory = "Nivis Serethran's Quests, Hlan Oek Temple",
        master = "Tamriel Rebuilt", text = "Protect pilgrims from perils on the path."
    },
    {
        id = "TR_m7_HO_TT_04",
        name = "A Change of Heart",
        category = "Factions | Tribunal Temple",
        subcategory = "Nivis Serethran's Quests, Hlan Oek Temple",
        master = "Tamriel Rebuilt", text = "Two seek sanctuary from the Camonna Tong."
    },
    {
        id = "TR_m7_HO_TT_05",
        name = "The Crook of the Crossing",
        category = "Factions | Tribunal Temple",
        subcategory = "Nivis Serethran's Quests, Hlan Oek Temple",
        master = "Tamriel Rebuilt", text = "Retrieve a sacred artifact of the Hlan Oek temple."
    },
    {
        id = "TR_m7_HO_TT_06",
        name = "Far From Grace",
        category = "Factions | Tribunal Temple",
        subcategory = "Nivis Serethran's Quests, Hlan Oek Temple",
        master = "Tamriel Rebuilt", text = "Rescue two pilgrims kidnapped on the road."
    },
    {
        id = "TR_m7_HO_TT_07",
        name = "In the Family",
        category = "Factions | Tribunal Temple",
        subcategory = "Nivis Serethran's Quests, Hlan Oek Temple",
        master = "Tamriel Rebuilt", text = "Stop the desecration of a local luminary's family tomb."
    },
    {
        id = "TR_m4_TT_StAralor_Q1",
        name = "Blood Money",
        category = "Factions | Tribunal Temple",
        subcategory = "Dram Marvos' Quests, Monastery of St. Aralor",
        master = "Tamriel Rebuilt", text = "Collect the ill-gotten gains of a penitent Mer."
    },
    {
        id = "TR_m4_TT_StAralor_Q2",
        name = "Endril Gilveni's Arrest",
        category = "Factions | Tribunal Temple",
        subcategory = "Dram Marvos' Quests, Monastery of St. Aralor",
        master = "Tamriel Rebuilt", text = "Enforce Temple law against ignorant legionnaires."
    },
    {
        id = "TR_m4_TT_StAralor_Q3",
        name = "The Past We Left Behind",
        category = "Factions | Tribunal Temple",
        subcategory = "Dram Marvos' Quests, Monastery of St. Aralor",
        master = "Tamriel Rebuilt", text = "A criminal past is not so easily abandoned..."
    },
    {
        id = "TR_m7_StDelyn_TT_01",
        name = "Nature of Fire",
        category = "Factions | Tribunal Temple",
        subcategory = "Aeyne Redothril's Quests, Monastery of St. Delyn",
        master = "Tamriel Rebuilt", text = "Retrieve and ruminate."
    },
    {
        id = "TR_m7_StDelyn_TT_02",
        name = "Spreading the Word",
        category = "Factions | Tribunal Temple",
        subcategory = "Aeyne Redothril's Quests, Monastery of St. Delyn",
        master = "Tamriel Rebuilt", text = "Ensure a book's distribution in the lands of House Hlaalu."
    },
    {
        id = "TR_m7_StDelyn_TT_03",
        name = "Origins of Vampires",
        category = "Factions | Tribunal Temple",
        subcategory = "Aeyne Redothril's Quests, Monastery of St. Delyn",
        master = "Tamriel Rebuilt", text = "Suppress a forbidden master text."
    },
    {
        id = "TR_m4_TT_STF_mf_pilgrimage",
        name = "War-Pilgrimage to the Foothills",
        category = "Factions | Tribunal Temple",
        subcategory = "Ano Forondas' Quests, Monastery of St. Felms",
        master = "Tamriel Rebuilt", text = "Bring death to the trolls of the Velothi mountains."
    },
    {
        id = "TR_m4_TT_STF_aum_pilgrimage",
        name = "War-Pilgrimage to Ald Uman",
        category = "Factions | Tribunal Temple",
        subcategory = "Ano Forondas' Quests, Monastery of St. Felms",
        master = "Tamriel Rebuilt", text = "Purge a shrine of the House of Troubles."
    },
    {
        id = "TR_m4_TT_STF_destroy_ancient",
        name = "Trial of the Saint",
        category = "Factions | Tribunal Temple",
        subcategory = "Ano Forondas' Quests, Monastery of St. Felms",
        master = "Tamriel Rebuilt", text = "Prove your mettle against a vampire ancient."
    },
    {
        id = "TR_m7_Ns_TT_Chavana1",
        name = "A Beggar Ill",
        category = "Factions | Tribunal Temple",
        subcategory = "Chavana Emalur's Quests, Narsis, Shrine of the Hidden Saints",
        master = "Tamriel Rebuilt", text = "Intervene in the case of a sickly sewer-dweller."
    },
    {
        id = "TR_m7_Ns_TT_Chavana2, TR_m7_Ns_TT_Chavana2a",
        name = "Dangerous Offer",
        category = "Factions | Tribunal Temple",
        subcategory = "Chavana Emalur's Quests, Narsis, Shrine of the Hidden Saints",
        master = "Tamriel Rebuilt", text = "Dissuade a netch rancher from a narcotics sideline."
    },
    {
        id = "TR_m7_Ns_TT_Chavana3",
        name = "My Mouth is Skilled at Lying",
        category = "Factions | Tribunal Temple",
        subcategory = "Chavana Emalur's Quests, Narsis, Shrine of the Hidden Saints",
        master = "Tamriel Rebuilt", text = "Re-enact the wedding of Vivec and Molag Bal."
    },
    {
        id = "TR_m7_Ns_TT_Chavana3a",
        name = "Its Alibi a Tooth",
        category = "Factions | Tribunal Temple",
        subcategory = "Chavana Emalur's Quests, Narsis, Shrine of the Hidden Saints",
        master = "Tamriel Rebuilt", text = "A ritual drowner faces ritual drowning."
    },
    {
        id = "TR_m7_Ns_TT_Chavana4",
        name = "Hidden Saint",
        category = "Factions | Tribunal Temple",
        subcategory = "Chavana Emalur's Quests, Narsis, Shrine of the Hidden Saints",
        master = "Tamriel Rebuilt", text = "A beloved priest's murder has Narsis abuzz."
    },
    {
        id = "TR_m7_Ns_TT_Orvayn1",
        name = "Gutter Conjurer",
        category = "Factions | Tribunal Temple",
        subcategory = "Milara Orvayn's Quests, Narsis, Eight-Bones Temple",
        master = "Tamriel Rebuilt", text = "A necromancer preys on the remains in the Catacombs."
    },
    {
        id = "TR_m7_Ns_TT_Orvayn2",
        name = "Shinathi Apostasy",
        category = "Factions | Tribunal Temple",
        subcategory = "Milara Orvayn's Quests, Narsis, Eight-Bones Temple",
        master = "Tamriel Rebuilt", text = "Slay the leader of a deviant Shinathi cult."
    },
    {
        id = "TR_m7_Ns_TT_Orvayn3",
        name = "Dueling Blasphemy",
        category = "Factions | Tribunal Temple",
        subcategory = "Milara Orvayn's Quests, Narsis, Eight-Bones Temple",
        master = "Tamriel Rebuilt", text = "Defeat a loud-mouthed Temple critic in a duel to the death."
    },
    {
        id = "TR_m7_Ns_TT_Orvayn4",
        name = "Sewer Rats",
        category = "Factions | Tribunal Temple",
        subcategory = "Milara Orvayn's Quests, Narsis, Eight-Bones Temple",
        master = "Tamriel Rebuilt", text = "Purge a cult of Namira that festers beneath Narsis."
    },
    {
        id = "TR_m7_Ns_TT_Orvayn5",
        name = "The Belt of St. Olms",
        category = "Factions | Tribunal Temple",
        subcategory = "Milara Orvayn's Quests, Narsis, Eight-Bones Temple",
        master = "Tamriel Rebuilt", text = "Hunt down a traitor Ordinator and their stolen relic."
    },
    {
        id = "TR_m1_TT_2, TR_m1_TT_2_Message, TR_m1_TT_2_Status",
        name = "Chores in Port Telvannis",
        category = "Factions | Tribunal Temple",
        subcategory = "Ratagos' Quests, Ranyon-ruhn Temple",
        master = "Tamriel Rebuilt", text = "Enlighten the city of Port Telvannis and try to gain the support of as many people as you can."
    },
    {
        id = "TR_m1_TT_3, TR_m1_TT_3_Status",
        name = "Support in Llothanis",
        category = "Factions | Tribunal Temple",
        subcategory = "Ratagos' Quests, Ranyon-ruhn Temple",
        master = "Tamriel Rebuilt", text = "The local people of Llothanis need some guidance from the Temple."
    },
    {
        id = "TR_m1_TT_4, TR_m1_TT_4_Deaths",
        name = "Escort to Dadrunibi",
        category = "Factions | Tribunal Temple",
        subcategory = "Ratagos' Quests, Ranyon-ruhn Temple",
        master = "Tamriel Rebuilt", text = "Escort two pilgrims on the way to Dadrunibi."
    },
    {
        id = "TR_m1_TT_4point5",
        name = "Darkness in Sagea",
        category = "Factions | Tribunal Temple",
        subcategory = "Ratagos' Quests, Ranyon-ruhn Temple",
        master = "Tamriel Rebuilt", text = "Bring an end to a rogue Telvanni necromancer."
    },
    {
        id = "TR_m1_TT_5, TR_m1_TT_5_CureA, TR_m1_TT_5_CureD, TR_m1_TT_5_CureV",
        name = "Epidemic in Ranyon-ruhn",
        category = "Factions | Tribunal Temple",
        subcategory = "Ratagos' Quests, Ranyon-ruhn Temple",
        master = "Tamriel Rebuilt", text = "Cure three Ranyon-ruhn townspeople before they become vampires!"
    },
    {
        id = "TR_m1_TT_6, TR_m1_TT_6_Stolen",
        name = "Seht's Ward",
        category = "Factions | Tribunal Temple",
        subcategory = "Ratagos' Quests, Ranyon-ruhn Temple",
        master = "Tamriel Rebuilt", text = "The amulet of Seht's Warding should be retrieved, by any means possible."
    },
    {
        id = "TR_m1_TT_7",
        name = "End the Vampire Epidemic",
        category = "Factions | Tribunal Temple",
        subcategory = "Ratagos' Quests, Ranyon-ruhn Temple",
        master = "Tamriel Rebuilt", text = "Trace the corruption to its source."
    },
    {
        id = "ID_NOT_FOUND",
        name = "Letter of War",
        category = "Factions | Tribunal Temple",
        subcategory = "Vvardenfell Integrations",
        master = "Tamriel Rebuilt", text = ""
    },
    {
        id = "TR_m4_Bal0_Troubles, TR_m4_Bal0_Troubles_A",
        name = "Troubles on the Road",
        category = "Vampire Quests",
        subcategory = "Armas Tyravel's Quests, Arvud",
        master = "Tamriel Rebuilt", text = "Vampiric assaults plague the Armun Ashlands..."
    },
    {
        id = "TR_m4_Bal1_Hunter",
        name = "Hunting the Hunter",
        category = "Vampire Quests",
        subcategory = "Kashshaptu's Quests, Malawius Camp",
        master = "Tamriel Rebuilt", text = "Turn the tables on a prolific vampire killer."
    },
    {
        id = "TR_m4_Bal2_Lair",
        name = "A New Lair",
        category = "Vampire Quests",
        subcategory = "Ofelia's Quests, Khirakai and Ald Balaal",
        master = "Tamriel Rebuilt", text = "Return the Baluath to a den reminiscent of their ancient glory."
    },
    {
        id = "TR_m4_Bal_Hannat",
        name = "The Ageless Apprentice",
        category = "Vampire Quests",
        subcategory = "Ofelia's Quests, Khirakai and Ald Balaal",
        master = "Tamriel Rebuilt", text = "Investigate a strange apparition."
    },
    {
        id = "TR_m4_Bal3_ArvsShadan",
        name = "The Sorceress of Arvs-Shadan",
        category = "Vampire Quests",
        subcategory = "Ofelia's Quests, Khirakai and Ald Balaal",
        master = "Tamriel Rebuilt", text = "Teach a lesson to a student of the vampiric condition."
    },
    {
        id = "TR_m4_Bal4_Sathram",
        name = "The Solitary Savant",
        category = "Vampire Quests",
        subcategory = "Ofelia's Quests, Khirakai and Ald Balaal",
        master = "Tamriel Rebuilt", text = "Prepare a suitable study for a solitary scholar."
    },
    {
        id = "TR_m4_Bal5_AmuletsPacts",
        name = "Amulets and Pacts",
        category = "Vampire Quests",
        subcategory = "Ofelia's Quests, Khirakai and Ald Balaal",
        master = "Tamriel Rebuilt", text = "Gather ash from the ectoplasm to seal an ancient pact."
    },
    {
        id = "TR_m4_Bal_KillOrlukh",
        name = "Slay Orlukh Ancient",
        category = "Vampire Quests",
        subcategory = "Ofelia's Quests, Khirakai and Ald Balaal",
        master = "Tamriel Rebuilt", text = "Destroy the founding father of a rival bloodline."
    },
    {
        id = "TR_m4_VA_IronAndBlood",
        name = "Iron and Blood",
        category = "Vampire Quests",
        subcategory = "Mette Black-Briar's Quests, East Empire Company Headquarters in Old Ebonheart",
        master = "Tamriel Rebuilt", text = "What's yours is mine."
    },
    {
        id = "TR_m4_VA_MoreBlood",
        name = "More Blood Than Iron",
        category = "Vampire Quests",
        subcategory = "Mette Black-Briar's Quests, East Empire Company Headquarters in Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Eliminate the unwelcome tenants of Anbarsud."
    },
    {
        id = "TR_m4_VA_OVampHunt",
        name = "Vampire Hunter",
        category = "Vampire Quests",
        subcategory = "Thoga gra-Shugurz's Quests, Anbarsud",
        master = "Tamriel Rebuilt", text = "Battle a clan-killer who's come too close."
    },
    {
        id = "TR_m4_VA_Invasion",
        name = "Invasion from Above",
        category = "Vampire Quests",
        subcategory = "Varos' Quests, Anbarsud",
        master = "Tamriel Rebuilt", text = "Wipe out the Hlaalu investigating Ald Virak."
    },
    {
        id = "TR_m4_VA_DestroyBaluath",
        name = "Destroy Clan Baluath",
        category = "Vampire Quests",
        subcategory = "Alukh gra-Murz's Quests, Anbarsud",
        master = "Tamriel Rebuilt", text = "Stymy the resurgence of a rival clan."
    },
    {
        id = "TR_m4_VA_Roadside",
        name = "Roadside Picnic",
        category = "Vampire Quests",
        subcategory = "Orlukh gro-Othmog's Quests, Anbarsud",
        master = "Tamriel Rebuilt", text = "Lure in a snack for the clan."
    },
    {
        id = "TR_m4_VA_Warmblooded",
        name = "Warmblooded Introduction",
        category = "Vampire Quests",
        subcategory = "Orlukh gro-Othmog's Quests, Anbarsud",
        master = "Tamriel Rebuilt", text = "Recover a cattle's stolen intelligence."
    },
    {
        id = "TR_m4_VA_Propylon",
        name = "The Propylon Index",
        category = "Vampire Quests",
        subcategory = "Orlukh gro-Othmog's Quests, Anbarsud",
        master = "Tamriel Rebuilt", text = "Hunt down a propylon index for the clan."
    },
    {
        id = "TR_m4_VA_Proper",
        name = "Proper Documentation",
        category = "Vampire Quests",
        subcategory = "Orlukh gro-Othmog's Quests, Anbarsud",
        master = "Tamriel Rebuilt", text = "Uncover the anonymous seller who damned the Orlukh."
    },
    {
        id = "TR_m4_VA_Termination",
        name = "Termination Notice",
        category = "Vampire Quests",
        subcategory = "Orlukh gro-Othmog's Quests, Anbarsud",
        master = "Tamriel Rebuilt", text = "Kill Bal Foyen's leading light."
    },
    {
        id = "TR_m4_VA_Namira",
        name = "Namira's Shroud",
        category = "Vampire Quests",
        subcategory = "Orlukh gro-Othmog's Quests, Anbarsud",
        master = "Tamriel Rebuilt", text = "Make a loan to a vampire ancient."
    },
    {
        id = "TR_m4_VA_BarendrethProtection",
        name = "Barendreth Protection",
        category = "Vampire Quests",
        subcategory = "Aanthirin",
        master = "Tamriel Rebuilt", text = "Repel an Ordinator assault on a new Baluath Clan stronghold."
    },
    {
        id = "TR_m3_VA_ScrollDomination",
        name = "A Stunning Proposition",
        category = "Vampire Quests",
        subcategory = "Aanthirin",
        master = "Tamriel Rebuilt", text = "Rob a Roa Dyr vault for an acquisitive mage."
    },
    {
        id = "TR_m4_VA_Ibinai",
        name = "Power through Destruction",
        category = "Vampire Quests",
        subcategory = "Armun Ashlands",
        master = "Tamriel Rebuilt", text = "Seek the reason for a mercenary's survival."
    },
    {
        id = "TR_m4_VA_VrashMind",
        name = "Vrashammu's Mind Control",
        category = "Vampire Quests",
        subcategory = "Armun Ashlands",
        master = "Tamriel Rebuilt", text = "Collect a mesmerising secret for the vampire, Vrashammu."
    },
    {
        id = "TR_m1_FW_VA_BloodSample",
        name = "A Sample of Blood",
        category = "Vampire Quests",
        subcategory = "Dagon Urul",
        master = "Tamriel Rebuilt", text = "An alchemist seeks samples from vampiric veins."
    },
    {
        id = "TR_m3_wil_Merihayan",
        name = "The Ballad of Berelas",
        category = "Vampire Quests",
        subcategory = "Lan Orethan",
        master = "Tamriel Rebuilt", text = "When the Indoril draw too close, vampires must stick together..."
    },
    {
        id = "TR_m7_VA_AniVamp",
        name = "A Study on Animal Vampirism",
        category = "Vampire Quests",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Can beasts become vampires?"
    },
    {
        id = "TR_m7_VA_DaedricOrigin",
        name = "Daedric Origin",
        category = "Vampire Quests",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Punish three apostates of Namira."
    },
    {
        id = "TR_m7_Ns_Arena_01",
        name = "The Netchiman's Boy",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Face down a spear-wielding farmhand."
    },
    {
        id = "TR_m7_Ns_Arena_02",
        name = "The Good Trooper",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Best an ex-Legion marksman."
    },
    {
        id = "TR_m7_Ns_Arena_03",
        name = "The Foreign Quarter Killer",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Fight to the death against an infamous murderer."
    },
    {
        id = "TR_m7_Ns_Arena_04",
        name = "The Silver Scale",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Rank up with the defeat of a Nord warrior."
    },
    {
        id = "TR_m7_Ns_Arena_05",
        name = "Sandweaver",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Triumph over a fan-favorite swordsman."
    },
    {
        id = "TR_m7_Ns_Arena_06",
        name = "Rival",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "A grudge match demands death."
    },
    {
        id = "TR_m7_Ns_Arena_07",
        name = "The Knight of the Woods",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Duel a Wood Elf posing as a Breton knight."
    },
    {
        id = "TR_m7_Ns_Arena_08",
        name = "The Pack",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Defeat a beastmaster and his pack of loyal Kagouti."
    },
    {
        id = "TR_m7_Ns_Arena_09, TR_m7_Ns_Arena_09a",
        name = "The Golden Scale",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Join the ranks of the Gold Scale gladiators."
    },
    {
        id = "TR_m7_Ns_Arena_10",
        name = "Skewer of Kvatch",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Beat a halberd-wielding veteran of the Cyrodiil City arena."
    },
    {
        id = "TR_m7_Ns_Arena_11, TR_m7_Ns_Arena_11a",
        name = "A Dive",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Of bribes and blood."
    },
    {
        id = "TR_m7_Ns_Arena_12",
        name = "Telvanni Takedown",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Execute a captured Telvanni spy."
    },
    {
        id = "TR_m7_Ns_Arena_13",
        name = "The Ebony Scale",
        category = "Miscellaneous",
        subcategory = "Arena, Narsis",
        master = "Tamriel Rebuilt", text = "Reach the apex of the Narsis arena."
    },
    {
        id = "TR_m4_And_Bounty_Boneeater",
        name = "Bounty: Bone-Eater",
        category = "Miscellaneous",
        subcategory = "Agronak gro-Dumag's Bounties, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Terminate a tribe of bestial cannibals."
    },
    {
        id = "TR_m4_And_Bounty_RogueArgonians",
        name = "Bounty: Heem-Wan and Illisheeus",
        category = "Miscellaneous",
        subcategory = "Agronak gro-Dumag's Bounties, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Stop a murderous duo of slave escapees."
    },
    {
        id = "TR_m4_And_Bounty_Holst",
        name = "Bounty: Holst the Hound",
        category = "Miscellaneous",
        subcategory = "Agronak gro-Dumag's Bounties, Bal Foyen",
        master = "Tamriel Rebuilt", text = "End the predations of a houndmaster highwayman."
    },
    {
        id = "TR_m4_And_Bounty_Runat",
        name = "Bounty: The Kagouti Tusks",
        category = "Miscellaneous",
        subcategory = "Agronak gro-Dumag's Bounties, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Eliminate a bandit gang that have been troubling the traders of Arvud."
    },
    {
        id = "TR_m4_And_Bounty_Vyper",
        name = "Bounty: The Vyper Blades",
        category = "Miscellaneous",
        subcategory = "Agronak gro-Dumag's Bounties, Bal Foyen",
        master = "Tamriel Rebuilt", text = "Kill a clan of cutthroats that have been ambushing Roth Roryn travelers."
    },
    {
        id = "TR_m3_B_Nirmeni Ieneth, TR_m3_B_Nirmeni Ieneth_D",
        name = "Bounty: Nirmeni Ieneth",
        category = "Miscellaneous",
        subcategory = "Roa Dyr (and the lands of Indoril Ilvi)",
        master = "Tamriel Rebuilt", text = "Track down the bandit who's been robbing pilgrims on Veloth's Path."
    },
    {
        id = "TR_m3_B_Ja",
        name = "Bounty: Ja'Jabba",
        category = "Miscellaneous",
        subcategory = "Roa Dyr (and the lands of Indoril Ilvi)",
        master = "Tamriel Rebuilt", text = "Kill an escaped slave near Rilsoan."
    },
    {
        id = "TR_m3_B_Llanehra Androthi, TR_m3_B_Llanehra Androthi_D",
        name = "Bounty: Llanehra Androthi",
        category = "Miscellaneous",
        subcategory = "Roa Dyr (and the lands of Indoril Ilvi)",
        master = "Tamriel Rebuilt", text = "Stop a notorious velk-poacher in Felms Ithul."
    },
    {
        id = "TR_m3_B_Where",
        name = "Bounty: Where-Stars-Are-Drowning",
        category = "Miscellaneous",
        subcategory = "Roa Dyr (and the lands of Indoril Ilvi)",
        master = "Tamriel Rebuilt", text = "Bring justice to a runaway slave who killed his overseer."
    },
    {
        id = "TR_m3_B_Aesithal Tyavylch",
        name = "Bounty: Aesithal Tyavylch",
        category = "Miscellaneous",
        subcategory = "Roa Dyr (and the lands of Indoril Ilvi)",
        master = "Tamriel Rebuilt", text = "Catch an elusive thief and grave robber."
    },
    {
        id = "TR_m3_B_Hengor",
        name = "Bounty: Hengor the Outlaw",
        category = "Miscellaneous",
        subcategory = "Roa Dyr (and the lands of Indoril Ilvi)",
        master = "Tamriel Rebuilt", text = "Outwit a clever bandit on the road to Nav Andaram."
    },
    {
        id = "TR_m3_B_Turedus_Esdrecus",
        name = "Bounty: Turedus Esdrecus",
        category = "Miscellaneous",
        subcategory = "Roa Dyr (and the lands of Indoril Ilvi)",
        master = "Tamriel Rebuilt", text = "Execute a thief who dared to steal from Indoril Ilvi."
    },
    {
        id = "TR_m4_Uman_B1",
        name = "Bounty: Hamdirn",
        category = "Miscellaneous",
        subcategory = "Indriri Veram's Bounties, Uman",
        master = "Tamriel Rebuilt", text = "Ice a Nord smuggler for House Redoran."
    },
    {
        id = "TR_m4_Uman_B2",
        name = "Bounty: Dira Folvani",
        category = "Miscellaneous",
        subcategory = "Indriri Veram's Bounties, Uman",
        master = "Tamriel Rebuilt", text = "Bring a dissident hermit to justice."
    },
    {
        id = "TR_m4_Uman_B3",
        name = "Bounty: Drunna Fire-Eater and Geirfinna the Destroyer",
        category = "Miscellaneous",
        subcategory = "Indriri Veram's Bounties, Uman",
        master = "Tamriel Rebuilt", text = "Smoke out bandits in an ash-swallowed shrine."
    },
    {
        id = "TR_m7_DA_Meridia",
        name = "Meridia's Quest",
        category = "Miscellaneous",
        subcategory = "Daedric Prince Quests",
        master = "Tamriel Rebuilt", text = "Kill a Sload crime lord for Meridia"
    },
    {
        id = "TR_m7_DA_Namira, TR_m7_DA_Nam_Alembic, TR_m7_DA_Nam_Blood, TR_m7_DA_Nam_Bone, TR_m7_DA_Nam_Elvesa, TR_m7_DA_Nam_Goblet, TR_m7_DA_Nam_Rolvon",
        name = "Namira's Quest",
        category = "Miscellaneous",
        subcategory = "Daedric Prince Quests",
        master = "Tamriel Rebuilt", text = "Aid a priestess in completing an ancient ritual."
    },
    {
        id = "TR_m1_DA_Sanguine",
        name = "Sanguine's Quest",
        category = "Miscellaneous",
        subcategory = "Daedric Prince Quests",
        master = "Tamriel Rebuilt", text = "M'Aiq's birthday approaches, and you're in charge of drinks."
    },
    {
        id = "TR_m3_Aim_Dreugh1, TR_m3_Aim_Dreugh1b, TR_m3_Aim_Dreugh1c",
        name = "Finding Jebyn the Sailor",
        category = "Miscellaneous",
        subcategory = "Aimrah",
        master = "Tamriel Rebuilt", text = "There has been a strange disappearance in foggy Aimrah."
    },
    {
        id = "TR_m3_Aim_Horrav",
        name = "Getting the Hell Out of Aimrah",
        category = "Miscellaneous",
        subcategory = "Aimrah",
        master = "Tamriel Rebuilt", text = "Collect a debt for the Sailors' Inn."
    },
    {
        id = "TR_m3_Aim_Intermediation",
        name = "Intermediation",
        category = "Miscellaneous",
        subcategory = "Aimrah",
        master = "Tamriel Rebuilt", text = "Selling to House Dres."
    },
    {
        id = "TR_m3_Aim_Rats",
        name = "Rats in the Walls",
        category = "Miscellaneous",
        subcategory = "Aimrah",
        master = "Tamriel Rebuilt", text = "Deal with vermin behind the plaster."
    },
    {
        id = "TR_m3_Aim_Dreugh2, TR_m3_Aim_Dreugh2b, TR_m3_Aim_Dreugh2c, TR_m3_Aim_Dreugh2d, TR_m3_Aim_Dreugh2e, TR_m3_Aim_Dreugh2f, TR_m3_Aim_Dreugh2g, TR_m3_Aim_Dreugh2h, TR_m3_Aim_Dreugh2i",
        name = "Shadows under Aimrah",
        category = "Miscellaneous",
        subcategory = "Aimrah",
        master = "Tamriel Rebuilt", text = "Uncover the foul secret of Aimrah."
    },
    {
        id = "TR_m2_Ak_CantKill",
        name = "Can't Buy a Kill",
        category = "Miscellaneous",
        subcategory = "Akamora",
        master = "Tamriel Rebuilt", text = "Play the assassin to a clueless outlander."
    },
    {
        id = "TR_m2_ak_flaw",
        name = "Character Flaw",
        category = "Miscellaneous",
        subcategory = "Akamora",
        master = "Tamriel Rebuilt", text = "Find out what is making a local man act crazy."
    },
    {
        id = "TR_m2_Ak_Daedra, TR_m2_Ak_DaedraB",
        name = "Hunting Daedra",
        category = "Miscellaneous",
        subcategory = "Akamora",
        master = "Tamriel Rebuilt", text = "Deal with some marauding daedra that have been plaguing Akamora."
    },
    {
        id = "TR_m2_Ak_Nameless",
        name = "The Nameless Dunmer",
        category = "Miscellaneous",
        subcategory = "Akamora",
        master = "Tamriel Rebuilt", text = "Help a Dunmer find out who his ancestors are."
    },
    {
        id = "TR_m2_Ak_Gem",
        name = "The Nobura Tayo",
        category = "Miscellaneous",
        subcategory = "Akamora",
        master = "Tamriel Rebuilt", text = "Help track down a valuable gem."
    },
    {
        id = "TR_m7_AI_Infestation",
        name = "Infestation and Eviction",
        category = "Miscellaneous",
        subcategory = "Ald Iuval",
        master = "Tamriel Rebuilt", text = "Eradicate carnivorous beetles in Ald Iuval's old tavern."
    },
    {
        id = "TR_m7_AI_OrnadaBtD",
        name = "Ornada One Bites the Dust",
        category = "Miscellaneous",
        subcategory = "Ald Iuval",
        master = "Tamriel Rebuilt", text = "Treat a sickly insect queen."
    },
    {
        id = "TR_m7_AI_SweetwaterDreugh",
        name = "Sweetwater Dreugh",
        category = "Miscellaneous",
        subcategory = "Ald Iuval",
        master = "Tamriel Rebuilt", text = "A dreugh at the docks makes bathing unwise."
    },
    {
        id = "TR_m7_AM_AlwaysSomething",
        name = "Always Something to Learn",
        category = "Miscellaneous",
        subcategory = "Ald Marak",
        master = "Tamriel Rebuilt", text = "Collect cuirass curiosities for a burned-out bonesmith."
    },
    {
        id = "TR_m7_AM_FreeingGulveeus",
        name = "Free to Work",
        category = "Miscellaneous",
        subcategory = "Ald Marak",
        master = "Tamriel Rebuilt", text = "Emancipate a tradehouse slave."
    },
    {
        id = "TR_m3_AT_Brother, TR_m3_AT_Brother2",
        name = "Brother Against Brother",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "A family is split between two Great Houses."
    },
    {
        id = "TR_m3_AT_Catcatchers",
        name = "Catcatching in Almas Thirr",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "Aid an escape... or a capture."
    },
    {
        id = "TR_m3_AT_HisDeath",
        name = "Cutthroat Bureaucracy",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "Assist an aspiring tollmer in his dark ambitions."
    },
    {
        id = "TR_m3_AT_RatFriend",
        name = "Friends with Rats",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "Help an unusual pairing squeak by the guards."
    },
    {
        id = "TR_m3_AT_Matter_Record, TR_m3_AT_Matter_Record_a",
        name = "A Matter of Record",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "A pilgrim's quest for paperwork requires some dedication."
    },
    {
        id = "TR_m3_AT_Deed",
        name = "No Good Deed",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "Interrogate a group of slaves in search of a spy."
    },
    {
        id = "TR_m3_AT_Literacy",
        name = "Perils of Literacy",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "Handle a bookseller's suspected heresy."
    },
    {
        id = "TR_m3_AT_Armiger, TR_m3_AT_Armiger_aTR_m3_AT_Armiger_b, TR_m3_AT_Armiger_c",
        name = "Proud to be Buoyant",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "A Buoyant Armiger falls prey to a thief."
    },
    {
        id = "TR_m3_AT_SilentNight",
        name = "Silent Night",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "Silence a snoring neighbor for Llandora Falavel."
    },
    {
        id = "TR_m3_AT_Waters",
        name = "Tainted Waters",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "Identify and avenge a corpse pulled from the Thirr."
    },
    {
        id = "TR_m3_AT_Top Secret Recipes",
        name = "Top Secret Recipe",
        category = "Miscellaneous",
        subcategory = "Almas Thirr",
        master = "Tamriel Rebuilt", text = "Deliver a strange message for a pushy priest."
    },
    {
        id = "TR_m2_AB_ChooseFamily",
        name = "You Can't Choose Your Family",
        category = "Miscellaneous",
        subcategory = "Alt Bosara",
        master = "Tamriel Rebuilt", text = "Help someone with a brother bother."
    },
    {
        id = "TR_m2_AB_HTreports",
        name = "Telvanni Reports",
        category = "Miscellaneous",
        subcategory = "Alt Bosara",
        master = "Tamriel Rebuilt", text = "Retrieve an overdue report."
    },
    {
        id = "TR_m2_Ay_FallGuy",
        name = "An Inconvenient Scapegoat",
        category = "Miscellaneous",
        subcategory = "Ammar",
        master = "Tamriel Rebuilt", text = "A local Nord needs help proving his innocence."
    },
    {
        id = "TR_m2_AO_ShackledLove",
        name = "A Lover's Plea",
        category = "Miscellaneous",
        subcategory = "Andar Mok",
        master = "Tamriel Rebuilt", text = "One loveless, one penniless. Can you bring them together?"
    },
    {
        id = "TR_m2_AO_FlinGalore",
        name = "Flin Galore!",
        category = "Miscellaneous",
        subcategory = "Andar Mok",
        master = "Tamriel Rebuilt", text = "Find a missing cargo of Flin."
    },
    {
        id = "TR_m4_wil_BanditDuo",
        name = "An Outlander Bandit Duo",
        category = "Miscellaneous",
        subcategory = "Armun Pass Outpost",
        master = "Tamriel Rebuilt", text = "These bandits are wanted dead or alive."
    },
    {
        id = "TR_m4_wil_StrayGuars",
        name = "Stray Caravan Guars",
        category = "Miscellaneous",
        subcategory = "Armun Pass Outpost",
        master = "Tamriel Rebuilt", text = "Provide a guar retrieval service."
    },
    {
        id = "TR_m4_Arv_Metamorphosis, TR_m4_Arv_Metamorphosis_a",
        name = "Atriban's Metamorphosis",
        category = "Miscellaneous",
        subcategory = "Arvud",
        master = "Tamriel Rebuilt", text = "Reshape the future of a hapless alchemist."
    },
    {
        id = "TR_m4_Arv_BuriedSilver",
        name = "Buried Hlaalu Silver",
        category = "Miscellaneous",
        subcategory = "Arvud",
        master = "Tamriel Rebuilt", text = "Sift out treasure from the ash."
    },
    {
        id = "TR_m4_Arv_SlaveMistake",
        name = "Of Cats and Wood Elves",
        category = "Miscellaneous",
        subcategory = "Arvud",
        master = "Tamriel Rebuilt", text = "An Ohmes or a Bosmer? This slaver can't tell."
    },
    {
        id = "TR_m4_Arv_VampireFather",
        name = "Serjo Olmas Uvayn's Fate",
        category = "Miscellaneous",
        subcategory = "Arvud",
        master = "Tamriel Rebuilt", text = "Uncover the truth of a noble's disappearance."
    },
    {
        id = "TR_m4_Arv_StolenCargo",
        name = "Stolen Cargo in Issarbaddon",
        category = "Miscellaneous",
        subcategory = "Arvud",
        master = "Tamriel Rebuilt", text = "Handle a ransom for a slave."
    },
    {
        id = "TR_m4_Arv_VendelVisit, TR_m4_Arv_VendelVisitB, TR_m4_Arv_VendelVisitC, TR_m4_Arv_VendelVisitD",
        name = "The Visitor Known as Vendel Othreleth",
        category = "Miscellaneous",
        subcategory = "Arvud",
        master = "Tamriel Rebuilt", text = "Broker a betrothal for a visiting noble."
    },
    {
        id = "TR_m4_Arv_Dravil",
        name = "Young Dravil",
        category = "Miscellaneous",
        subcategory = "Arvud",
        master = "Tamriel Rebuilt", text = "Argue with a fiery young mer."
    },
    {
        id = "TR_m1_As_Guard, TR_m1_As_Guard_Details, TR_m1_As_Guard_Erdlan",
        name = "Removing the Guard",
        category = "Miscellaneous",
        subcategory = "Ashamul",
        master = "Tamriel Rebuilt", text = "Remove the guard from the entrance of Ashamul to help a smuggler."
    },
    {
        id = "TR_m1_As_Dwemer",
        name = "The Dwemer Staff",
        category = "Miscellaneous",
        subcategory = "Ashamul",
        master = "Tamriel Rebuilt", text = "Recently a dwemer ruin was discovered close to Ashamul and the cave-dwellers want a piece of its treasures."
    },
    {
        id = "TR_m1_Bah_GuarMeat",
        name = "The Price of Guar Meat",
        category = "Miscellaneous",
        subcategory = "Bahrammu",
        master = "Tamriel Rebuilt", text = "Secure a good price on a herd of guar."
    },
    {
        id = "TR_m1_Bah_widow, TR_m1_Bah_widow2",
        name = "The Widow and the Sea",
        category = "Miscellaneous",
        subcategory = "Bahrammu",
        master = "Tamriel Rebuilt", text = "A humble fisherman is lost, but was he taken by the sea?"
    },
    {
        id = "TR_m4_And_AAB",
        name = "Awoke and Broke",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Experience one expensive night in."
    },
    {
        id = "TR_m4_And_Credibility",
        name = "Certificate of Credibility",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Papers, please."
    },
    {
        id = "TR_m4_And_Drowned",
        name = "Drowned Out",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Dreams of a deluge trouble a pious Dunmer."
    },
    {
        id = "TR_m4_And_TMM, TR_m4_And_TMM_ash",
        name = "The Malignant Merchant",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Tend to the troubles of a truculent trader."
    },
    {
        id = "TR_m4_And_MaterialMatters",
        name = "Material Matters",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Initiate a product recall for a faulty piece of armor."
    },
    {
        id = "TR_m4_And_Packrat",
        name = "Packrat",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Track down missing goods at the Port Authority warehouse."
    },
    {
        id = "TR_m4_And_Routinedelivery",
        name = "A Routine Delivery",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Smuggle an ebony blade to a secretive buyer."
    },
    {
        id = "TR_m4_And_Soul",
        name = "Soul Inheritor",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "A Telvanni mage covets his cousin's spirit."
    },
    {
        id = "TR_m4_And_SheKindlySpoke",
        name = "The Thief, She Kindly Spoke",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "A pauper community is stricken by the arrest of one of their own."
    },
    {
        id = "TR_m4_And_Alchemists_1, TR_m4_And_Alchemists_2, TR_m4_And_Alchemists_3, TR_m4_And_Alchemists_4, TR_m4_And_Alchemists_5, TR_m4_And_Alchemists_6",
        name = "Trouble Brewing in Bal Foyen",
        category = "Miscellaneous",
        subcategory = "Bal Foyen",
        master = "Tamriel Rebuilt", text = "Two alchemists formulate both potions and plots..."
    },
    {
        id = "TR_m1_BOmuskfly_ITO",
        name = "Muskfly Infestation",
        category = "Miscellaneous",
        subcategory = "Bal Oyra",
        master = "Tamriel Rebuilt", text = "Find a novel solution to a pest complaint."
    },
    {
        id = "TR_m3_Bala_WLCR",
        name = "When Love Crosses Rivers",
        category = "Miscellaneous",
        subcategory = "Balathren",
        master = "Tamriel Rebuilt", text = "An Indoril commoner falls for a Hlaalu lord's daughter."
    },
    {
        id = "TR_m2_Ba_Smiler",
        name = "The Smiler",
        category = "Miscellaneous",
        subcategory = "Baldrahn",
        master = "Tamriel Rebuilt", text = "Help a muck farmer get even with a co-worker."
    },
    {
        id = "TR_m4_Bd_Wesencolm",
        name = "An Unwell Traveler",
        category = "Miscellaneous",
        subcategory = "Bodrum",
        master = "Tamriel Rebuilt", text = "Provide respite to an East Empire Company agent."
    },
    {
        id = "TR_m4_Bd_Lost_in_Transit, TR_m4_Bd_Lost_in_Transit_A, TR_m4_Bd_Lost_in_Transit_C, TR_m4_Bd_Lost_in_Transit_D, TR_m4_Bd_Lost_in_Transit_N, TR_m4_Bd_Lost_in_Transit_S",
        name = "Lost in Transit",
        category = "Miscellaneous",
        subcategory = "Bodrum",
        master = "Tamriel Rebuilt", text = "A couple's son has gone missing in the Armun Ashlands."
    },
    {
        id = "TR_m4_Bd_RedoranDebt",
        name = "The Proud Redoran",
        category = "Miscellaneous",
        subcategory = "Bodrum",
        master = "Tamriel Rebuilt", text = "Settle a debt problem for an elf too stubborn to speak of it."
    },
    {
        id = "TR_m4_Bd_ArmyYouHave",
        name = "With The Army You Have",
        category = "Miscellaneous",
        subcategory = "Bodrum",
        master = "Tamriel Rebuilt", text = "Eliminate the cause of some Kobold assaults."
    },
    {
        id = "TR_m3_Bo_Burglar1",
        name = "The Company We Keep",
        category = "Miscellaneous",
        subcategory = "Bosmora",
        master = "Tamriel Rebuilt", text = "Investigate a recent string of burglaries in Bosmora."
    },
    {
        id = "TR_m3_Bo_Burglar2",
        name = "Caught Off-Guard",
        category = "Miscellaneous",
        subcategory = "Bosmora",
        master = "Tamriel Rebuilt", text = "Spring a trap to catch a burglar."
    },
    {
        id = "TR_m3_Bo_DragonHunter",
        name = "The Perils of Dragon Hunting",
        category = "Miscellaneous",
        subcategory = "Bosmora",
        master = "Tamriel Rebuilt", text = "Track down a missing knightly order."
    },
    {
        id = "TR_m3_Bo_Kiseen",
        name = "Unrequited Business",
        category = "Miscellaneous",
        subcategory = "Bosmora",
        master = "Tamriel Rebuilt", text = "Assist a Khajiiti Trader with his blackmailer problem."
    },
    {
        id = "TR_m3_Dar_Mistake",
        name = "Mahhjat's Mistake",
        category = "Miscellaneous",
        subcategory = "Darvonis",
        master = "Tamriel Rebuilt", text = "Help a Khajiit fix his mistake."
    },
    {
        id = "TR_m3_Dar_Reprus",
        name = "Marcus Reprus' Ring",
        category = "Miscellaneous",
        subcategory = "Darvonis",
        master = "Tamriel Rebuilt", text = "Ashlander thieves!"
    },
    {
        id = "TR_m3_Do_Cultists",
        name = "At Play in the Meadows of Malacath",
        category = "Miscellaneous",
        subcategory = "Dondril",
        master = "Tamriel Rebuilt", text = "Deal with the Malacath worshippers at Hadrumnibibi."
    },
    {
        id = "TR_m3_Do_Velk",
        name = "The Velk and the Dagger",
        category = "Miscellaneous",
        subcategory = "Dondril",
        master = "Tamriel Rebuilt", text = "Find the errant velk."
    },
    {
        id = "TR_m3_Dr_Bandits",
        name = "Rich Pickings",
        category = "Miscellaneous",
        subcategory = "Dreynim Spa",
        master = "Tamriel Rebuilt", text = "Kill Rithre Arsur, the bandit leader."
    },
    {
        id = "TR_m3_Dr_Daughter",
        name = "My Daughter's Keeper",
        category = "Miscellaneous",
        subcategory = "Dreynim Spa",
        master = "Tamriel Rebuilt", text = "Fedura's daughter is missing and the staff aren't talking."
    },
    {
        id = "TR_m2_A8_5_FreeAtLast, TR_m2_A8_5_FreeAtLast2",
        name = "Free at Last?",
        category = "Miscellaneous",
        subcategory = "Erethan Plantation",
        master = "Tamriel Rebuilt", text = "Help Midave Llarys, head of the guards with capturing an escaped slave."
    },
    {
        id = "TR_m1_FW_ABitterTaste",
        name = "A Bitter Taste",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Steal a rare ore for an acquisitive naturalist."
    },
    {
        id = "TR_m1_FW_Clannfear",
        name = "A Clannfear in Firewatch",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Help an exasperated Wood Elf shake off a suitor's unwanted expressions of affection."
    },
    {
        id = "TR_m1_FW_CollegeEnrollAlchemy, TR_m1_FW_CollegeEnrollArchaeology, TR_m1_FW_CollegeEnrollGeography, TR_m1_FW_CollegeEnrollHistory, TR_m1_FW_CollegeEnrollMagecraft, TR_m1_FW_CollegeEnrollPhilosophy, TR_m1_FW_CollegeEnrollRhetoric",
        name = "College of Firewatch: Enrollment",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Enroll at a prestigious institution."
    },
    {
        id = "TR_m1_FW_DoubleMean",
        name = "Double Meaning",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Deliver a message to a Telvanni envoy."
    },
    {
        id = "TR_m1_FW_Gummidge, TR_m1_FW_Gummidge_a, TR_m1_FW_Gummidge_b, TR_m1_FW_Gummidge_c, TR_m1_FW_Gummidge_d, TR_m1_FW_Gummidge_e, TR_m1_FW_Gummidge_f, TR_m1_FW_Gummidge_g",
        name = "Gummidge",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "An old commoner has lost something... but what exactly?"
    },
    {
        id = "TR_m1_FW_CollegeGreatRiver",
        name = "The Great River",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Barter or thieve for a rare bezoar."
    },
    {
        id = "TR_m1_FW_CollegeRealThing",
        name = "Just Like the Real Thing",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Sell fictitious artifacts to unsuspecting buyers."
    },
    {
        id = "TR_m1_FW_MinerProblems",
        name = "Miner Problems",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Investigate a problem with some diamond miners."
    },
    {
        id = "TR_m1_FW_OutOfOrder",
        name = "Out of Order",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Address a legal case against a knightly order."
    },
    {
        id = "TR_m1_FW_SugarAndSpice",
        name = "Sugar and Spice",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Intervene in an old veteran's struggle."
    },
    {
        id = "TR_m1_FW_ATighterFIt",
        name = "A Tighter Fit",
        category = "Miscellaneous",
        subcategory = "Firewatch",
        master = "Tamriel Rebuilt", text = "Assist a dyeing business."
    },
    {
        id = "TR_m7_Shin_RenderingAssistance",
        name = "Rendering Assistance",
        category = "Miscellaneous",
        subcategory = "Gan-Ettu Camp",
        master = "Tamriel Rebuilt", text = "Prove your worth to the Gan-Ettu."
    },
    {
        id = "TR_M1_GS_MQ_4",
        name = "Duel of Riddles",
        category = "Miscellaneous",
        subcategory = "Gah Sadrith",
        master = "Tamriel Rebuilt", text = "Beat Mistress Eldale in a contest of words."
    },
    {
        id = "TR_M1_GS_MQ_2",
        name = "Fiancee Lost",
        category = "Miscellaneous",
        subcategory = "Gah Sadrith",
        master = "Tamriel Rebuilt", text = "Investigate the disappearance of a Nord adventurer's lover."
    },
    {
        id = "TR_M1_GS_MQ_5",
        name = "Gah Sadrith Inquisition",
        category = "Miscellaneous",
        subcategory = "Gah Sadrith",
        master = "Tamriel Rebuilt", text = "Gah Sadrith is shaken by an evil daedra worshipper. Find out who it is."
    },
    {
        id = "TR_M1_GS_MQ_3",
        name = "Search for a Perfect Sword",
        category = "Miscellaneous",
        subcategory = "Gah Sadrith",
        master = "Tamriel Rebuilt", text = "A High Elf wants the perfect sword. But does it even exist?"
    },
    {
        id = "TR_M1_GS_MQ_1",
        name = "Telvanni Manners",
        category = "Miscellaneous",
        subcategory = "Gah Sadrith",
        master = "Tamriel Rebuilt", text = "A lesson in Telvanni manners can be a bit... expensive."
    },
    {
        id = "TR_m4_wil_fishingpole",
        name = "Grum's Fishing Pole",
        category = "Miscellaneous",
        subcategory = "Gol Mok",
        master = "Tamriel Rebuilt", text = "This fisherman can't swim."
    },
    {
        id = "TR_m3_Go_Guard1",
        name = "The Gorne Guard's Getaway",
        category = "Miscellaneous",
        subcategory = "Gorne",
        master = "Tamriel Rebuilt", text = "The lookout is moonlighting. Where could he be?"
    },
    {
        id = "TR_m3_Go_Fish",
        name = "Gorne Fishing",
        category = "Miscellaneous",
        subcategory = "Gorne",
        master = "Tamriel Rebuilt", text = "Resolve a fishy dispute."
    },
    {
        id = "TR_m3_Go_Guard2",
        name = "An Alchemical Ailment",
        category = "Miscellaneous",
        subcategory = "Gorne",
        master = "Tamriel Rebuilt", text = "A travelling alchemist has some...interesting recipes."
    },
    {
        id = "TR_m7_Ns_BearingBadNews",
        name = "Bearing Bad News",
        category = "Miscellaneous",
        subcategory = "Helnim",
        master = "Tamriel Rebuilt", text = "Courier terse correspondence between husband and wife."
    },
    {
        id = "TR_m2_IAS_BelongMuseum",
        name = "It Belongs in a Museum",
        category = "Miscellaneous",
        subcategory = "Helnim",
        master = "Tamriel Rebuilt", text = "Identify a source of Dwemer contraband."
    },
    {
        id = "TR_m2_ito_literary_critic",
        name = "Literary Critic",
        category = "Miscellaneous",
        subcategory = "Helnim",
        master = "Tamriel Rebuilt", text = "Conduct a critical delivery."
    },
    {
        id = "TR_m2_HB_Fraud",
        name = "The Famous Fraud",
        category = "Miscellaneous",
        subcategory = "Hla Bulor",
        master = "Tamriel Rebuilt", text = "Calm down a problematic local."
    },
    {
        id = "TR_m7_HL_PartnersInWine",
        name = "Partners in Wine",
        category = "Miscellaneous",
        subcategory = "Hladri Winery",
        master = "Tamriel Rebuilt", text = "Broker a deal for an enterprising wine merchant."
    },
    {
        id = "TR_m7_HO_CluelessEggminer, TR_m7_HO_CluelessEggminer_H, TR_m7_HO_CluelessEggminer_P, TR_m7_HO_CluelessEggminer_W",
        name = "The Clueless Eggminer",
        category = "Miscellaneous",
        subcategory = "Hlan Oek",
        master = "Tamriel Rebuilt", text = "Get into eggmining with an Imperial entrepreneur."
    },
    {
        id = "TR_m7_HO_DivingForArns",
        name = "Diving for Arns",
        category = "Miscellaneous",
        subcategory = "Hlan Oek",
        master = "Tamriel Rebuilt", text = "Salvage a shipment of sunken scrap."
    },
    {
        id = "TR_m7_HO_Guide",
        name = "Guide to Hlan Oek",
        category = "Miscellaneous",
        subcategory = "Hlan Oek",
        master = "Tamriel Rebuilt", text = "Grant a guided tour to a couple seeking both information and fun."
    },
    {
        id = "TR_m7_HO_HighAndDry, TR_m7_HO_HighAndDry_a",
        name = "High and Dry",
        category = "Miscellaneous",
        subcategory = "Hlan Oek",
        master = "Tamriel Rebuilt", text = "A captain grows suspicious of Hlan Oek's shipwrights."
    },
    {
        id = "TR_m7_HO_HouseForSale, TR_m7_HO_HouseForSale_a",
        name = "House for Sale",
        category = "Miscellaneous",
        subcategory = "Hlan Oek",
        master = "Tamriel Rebuilt", text = "Find yourself a homeowner for a knockdown price."
    },
    {
        id = "TR_m7_HO_Lost",
        name = "Lost But Not Forgotten",
        category = "Miscellaneous",
        subcategory = "Hlan Oek",
        master = "Tamriel Rebuilt", text = "Recover some jewelry for a passing pilgrim."
    },
    {
        id = "TR_m7_HO_PassageMenevia",
        name = "Passage to Menevia",
        category = "Miscellaneous",
        subcategory = "Hlan Oek",
        master = "Tamriel Rebuilt", text = "Strike a deal for safe passage, no questions asked."
    },
    {
        id = "TR_m7_HO_StraboBook",
        name = "Strabo's Book Problem",
        category = "Miscellaneous",
        subcategory = "Hlan Oek",
        master = "Tamriel Rebuilt", text = "Cooked books make for a rewarding theft."
    },
    {
        id = "TR_m7_HL_AffairsHeart",
        name = "Affairs of the Heart",
        category = "Miscellaneous",
        subcategory = "Hlerynhul",
        master = "Tamriel Rebuilt", text = "Aid an excursion beyond the bounds of marriage."
    },
    {
        id = "TR_m7_HL_HelpingOthers",
        name = "Helping Others",
        category = "Miscellaneous",
        subcategory = "Hlerynhul",
        master = "Tamriel Rebuilt", text = "Retrieve a magic bow from a bandit cavern."
    },
    {
        id = "TR_m7_HL_MakingPeace, TR_m7_HL_MakingPeace_a, TR_m7_HL_MakingPeace_b",
        name = "Making Peace",
        category = "Miscellaneous",
        subcategory = "Hlerynhul",
        master = "Tamriel Rebuilt", text = "What will you do with two drunken sailors?"
    },
    {
        id = "TR_m7_HL_PauperAndPrince",
        name = "The Pauper and the Prince",
        category = "Miscellaneous",
        subcategory = "Hlerynhul",
        master = "Tamriel Rebuilt", text = "Locate a pauper gone missing."
    },
    {
        id = "TR_m7_HL_PearlsForConrel",
        name = "Pearls for Conrel",
        category = "Miscellaneous",
        subcategory = "Hlerynhul",
        master = "Tamriel Rebuilt", text = "Pearl dive for a Hlerynhul jeweler."
    },
    {
        id = "TR_m7_HL_ProvingFaith",
        name = "Proving Faith",
        category = "Miscellaneous",
        subcategory = "Hlerynhul",
        master = "Tamriel Rebuilt", text = "A pestered mage seeks Temple membership."
    },
    {
        id = "TR_m7_Ida_Net",
        name = "Caught in a Net",
        category = "Miscellaneous",
        subcategory = "Idathren",
        master = "Tamriel Rebuilt", text = "A robbery raises suspicions at the Sadrano Manor."
    },
    {
        id = "TR_m4_Indal_MudcrabSlayer",
        name = "The Mudcrab Slayer",
        category = "Miscellaneous",
        subcategory = "Indal-ruhn",
        master = "Tamriel Rebuilt", text = "Seek out the bane of all things mudcrab."
    },
    {
        id = "TR_m4_IR_WillToGoOn",
        name = "A Will to Go On",
        category = "Miscellaneous",
        subcategory = "Indal-ruhn",
        master = "Tamriel Rebuilt", text = "Aid two traders traveling Veloth's Path."
    },
    {
        id = "TR_m4_Ish_Nerevarine",
        name = "Ishanuran Nerevarine",
        category = "Miscellaneous",
        subcategory = "Ishanuran Camp",
        master = "Tamriel Rebuilt", text = "Seek the acclamation of the Ishanuran."
    },
    {
        id = "TR_m3_Kha_AnguishCrux",
        name = "The Anguished Crux",
        category = "Miscellaneous",
        subcategory = "Khalaan",
        master = "Tamriel Rebuilt", text = "Fight your way to the heart of a mighty fortress."
    },
    {
        id = "TR_m3_Kha_FlowersDark",
        name = "Flowers in the Dark",
        category = "Miscellaneous",
        subcategory = "Khalaan",
        master = "Tamriel Rebuilt", text = "Assist a Daedroth with its diet."
    },
    {
        id = "TR_m3_Kha_Forsaken_Betrayer",
        name = "The Forsaken Betrayer",
        category = "Miscellaneous",
        subcategory = "Khalaan",
        master = "Tamriel Rebuilt", text = "Enter the depths of Oblivion to track down a Dremora for Malacath."
    },
    {
        id = "TR_m3_Kha_ClannfearTransport",
        name = "Through A Clannfear, Darkly",
        category = "Miscellaneous",
        subcategory = "Khalaan",
        master = "Tamriel Rebuilt", text = "A Clannfear hungers. Help it find someone to nibble on."
    },
    {
        id = "TR_m3_Kha_DaedricChests",
        name = "Treasure Hunt in Oblivion",
        category = "Miscellaneous",
        subcategory = "Khalaan",
        master = "Tamriel Rebuilt", text = "Pursue rumors of strange keys and hidden chests."
    },
    {
        id = "TR_m3_Kha_UndyingRivalry",
        name = "An Undying Rivalry",
        category = "Miscellaneous",
        subcategory = "Khalaan",
        master = "Tamriel Rebuilt", text = "Help an embattled Indoril end a ceaseless onslaught of Daedra attacking his position."
    },
    {
        id = "TR_m1_GO_6",
        name = "A Beleaguered Pilgrim",
        category = "Miscellaneous",
        subcategory = "Llothanis",
        master = "Tamriel Rebuilt", text = "Help protect a pilgrim on his journey."
    },
    {
        id = "TR_m1_GO_4",
        name = "A Smuggler Found",
        category = "Miscellaneous",
        subcategory = "Llothanis",
        master = "Tamriel Rebuilt", text = "A shady tavern in Llothanis is the perfect place for an espionage mission."
    },
    {
        id = "TR_m1_GO_2_ITO",
        name = "Stranded Shipment",
        category = "Miscellaneous",
        subcategory = "Llothanis",
        master = "Tamriel Rebuilt", text = "Help a tailor track down his missing supplies."
    },
    {
        id = "TR_m1_GO_1",
        name = "Temple Propaganda",
        category = "Miscellaneous",
        subcategory = "Llothanis",
        master = "Tamriel Rebuilt", text = "It is dangerous to be a Tribunal Temple worshipper in the Telvanni lands. Find out why."
    },
    {
        id = "TR_m1_GO_5",
        name = "The Prince of Plots",
        category = "Miscellaneous",
        subcategory = "Llothanis",
        master = "Tamriel Rebuilt", text = "A Llothanis noble has been captured by a cult. Save him!"
    },
    {
        id = "TR_m7_MaarBani_SuppliesSD",
        name = "Supplies for Sanvyr Deroth",
        category = "Miscellaneous",
        subcategory = "Maar-Bani Crossing",
        master = "Tamriel Rebuilt", text = "A publican's party is missing a shipment of booze."
    },
    {
        id = "TR_m2_Mar_SaveSlave",
        name = "Folk Medicine",
        category = "Miscellaneous",
        subcategory = "Marog",
        master = "Tamriel Rebuilt", text = "Sevra Andules is upset about her ill slave..."
    },
    {
        id = "TR_m2_Mar_LoveWar, TR_m2_Mar_LoveWar2",
        name = "To Win a Heart",
        category = "Miscellaneous",
        subcategory = "Marog",
        master = "Tamriel Rebuilt", text = "Assist an awkward warrior with his stuttering advances."
    },
    {
        id = "TR_m4_MN_Assassin",
        name = "Cut Short in Menaan",
        category = "Miscellaneous",
        subcategory = "Menaan",
        master = "Tamriel Rebuilt", text = "Death row beckons for this helpless Bosmer."
    },
    {
        id = "TR_m4_MN_Shorted",
        name = "Delivery of Wine",
        category = "Miscellaneous",
        subcategory = "Menaan",
        master = "Tamriel Rebuilt", text = "Conduct a delivery for an innumerate trader."
    },
    {
        id = "TR_m3_Me_Lost",
        name = "Lost and Found",
        category = "Miscellaneous",
        subcategory = "Meralag",
        master = "Tamriel Rebuilt", text = "Return an amulet on behalf of a Bosmer."
    },
    {
        id = "TR_m3_Me_Truth, TR_m3_Me_Truth_b, TR_m3_Me_Truth_c",
        name = "Tunneling to the Truth",
        category = "Miscellaneous",
        subcategory = "Meralag",
        master = "Tamriel Rebuilt", text = "Investigate a smuggling ring near the sleepy town of Meralag."
    },
    {
        id = "TR_m4_MP_SlaveWhisperer, TR_m4_MP_SlaveWhisperer1",
        name = "The Slave Whisperer",
        category = "Miscellaneous",
        subcategory = "Mundrethi Plantation",
        master = "Tamriel Rebuilt", text = "Silence a troublesome slave."
    },
    {
        id = "TR_m7_Ns_BeneathStVelothsGaze",
        name = "Beneath St. Veloth's Gaze",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "A caravaner's friend is in financial trouble."
    },
    {
        id = "TR_m7_NS_Irwaen",
        name = "Bring Irwaen Home",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Escort a woozy Wood Elf to safety."
    },
    {
        id = "TR_m7_Ns_DisTaste",
        name = "Distinct Distaste",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Deliver a bitter complaint."
    },
    {
        id = "TR_m7_Ns_JoinCamonnaTong",
        name = "Join the Camonna Tong",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Not you, n'wah."
    },
    {
        id = "TR_m7_Ns_MatterOfPedigree",
        name = "A Matter of Pedigree",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Prove the truth of a vision of family."
    },
    {
        id = "TR_m7_Ns_Moonshiner",
        name = "Moonshine Sonata",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "A Shinathi craves the things of his home."
    },
    {
        id = "TR_m7_Ns_MovingHouse",
        name = "Moving House",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Interview a ghost for The Canyon Echo."
    },
    {
        id = "TR_m7_Ns_Caravan",
        name = "M'Raskhar's Game",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Pitch a new game to the Fortuna casino."
    },
    {
        id = "TR_m7_Ns_NiceRing",
        name = "A Nice Ring to It",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Hunt for missing jewelry in the Narsis bazaar."
    },
    {
        id = "TR_m7_Ns_PayingDues",
        name = "Paying Dues",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "A Wood Elf merchant has been targeted by the Camonna Tong."
    },
    {
        id = "TR_m7_Ns_PiousAndPersecuted",
        name = "Pious and Persecuted",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Enable a jailbreak from Heron Hall."
    },
    {
        id = "TR_m7_Ns_RescuePotLady",
        name = "Rescue the Pot Lady",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Locate a local eccentric, lost in her senility."
    },
    {
        id = "TR_m7_Ns_RobbingAncestors",
        name = "Robbing the Ancestors",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Aid a gambler and a grave robber."
    },
    {
        id = "TR_m7_Ns_RobeHeavySwinging",
        name = "Robe of Heavy Swinging",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Shoplifting proves burdensome for an Argonian thief."
    },
    {
        id = "TR_m7_NS_ShockTherapy",
        name = "Shock Therapy",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Recover Barusi Fareleth's stolen research."
    },
    {
        id = "TR_m7_Ns_SinkOrSwim",
        name = "Sink or Swim",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Find the supplier for Meer-Ei's Swim Shop."
    },
    {
        id = "TR_m7_Ns_StageFright, TR_m7_Ns_StageFright_G, TR_m7_Ns_StageFright_M",
        name = "Stage Fright",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Something spectral stalks the stage."
    },
    {
        id = "TR_m7_Ns_TaleBreathBrine",
        name = "A Tale of Breath, Brine and Brotherhood",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Support a pair of diving Breton warriors."
    },
    {
        id = "TR_m7_InSearchofSnacks",
        name = "Thirst in Verse",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "I'll take a shein to you."
    },
    {
        id = "TR_m7_Ns_ToTheLastDrop",
        name = "To The Last Drop",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "A sailor's absence worries his captain."
    },
    {
        id = "TR_m7_Ns_Traipsing",
        name = "Traipsing with Danger",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Rescue a healer's adventuring son."
    },
    {
        id = "TR_m7_Ns_Air",
        name = "Up In The Air",
        category = "Miscellaneous",
        subcategory = "Narsis",
        master = "Tamriel Rebuilt", text = "Pass on a message for a clerk with a bad knee."
    },
    {
        id = "TR_m2_Nm_Drunk",
        name = "Bad Spirits",
        category = "Miscellaneous",
        subcategory = "Necrom",
        master = "Tamriel Rebuilt", text = "Help a drunk get back on his feet."
    },
    {
        id = "TR_m2_Nm_House",
        name = "A Forgotten House",
        category = "Miscellaneous",
        subcategory = "Necrom",
        master = "Tamriel Rebuilt", text = "Cleanse the family tomb for an ancestral spirit."
    },
    {
        id = "TR_m2_Nm_Walker",
        name = "Honor the Ancestors",
        category = "Miscellaneous",
        subcategory = "Necrom",
        master = "Tamriel Rebuilt", text = "Retrieve the remains of an ancestor."
    },
    {
        id = "TR_m2_Nm_Scout",
        name = "A Missing Scout",
        category = "Miscellaneous",
        subcategory = "Necrom",
        master = "Tamriel Rebuilt", text = "An Ordinator is visiting Necrom on important business."
    },
    {
        id = "TR_m2_Nm_Vorith",
        name = "Old Soldiers",
        category = "Miscellaneous",
        subcategory = "Necrom",
        master = "Tamriel Rebuilt", text = "Return a dead soldier's possessions to his widow."
    },
    {
        id = "TR_m2_Nm_Wake",
        name = "Wake for the Waves",
        category = "Miscellaneous",
        subcategory = "Necrom",
        master = "Tamriel Rebuilt", text = "Why does this old mer stare so sadly?"
    },
    {
        id = "TR_m1_Niv_Crack",
        name = "Cracking Icebreaker",
        category = "Miscellaneous",
        subcategory = "Nivalis",
        master = "Tamriel Rebuilt", text = "Jailbreak a supposed Orc pirate."
    },
    {
        id = "TR_m1_Niv_JustASip",
        name = "Just a Sip",
        category = "Miscellaneous",
        subcategory = "Nivalis",
        master = "Tamriel Rebuilt", text = "Find a tipple for a templar."
    },
    {
        id = "TR_m4_Ob_Ancestral_Guidance",
        name = "Obainat Nerevarine",
        category = "Miscellaneous",
        subcategory = "Obainat Camp",
        master = "Tamriel Rebuilt", text = "Forge together the Obainat and be proclaimed Nerevarine."
    },
    {
        id = "TR_m4_Ob_Poisoning_The_Well",
        name = "Poisoning the Well",
        category = "Miscellaneous",
        subcategory = "Obainat Camp",
        master = "Tamriel Rebuilt", text = "Distil this, Serjo Savrethi."
    },
    {
        id = "TR_m3_OE_AldmeriDiplomacy",
        name = "Aldmeri Diplomacy",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Calm down an embassy member who is unwilling to let old grudges go."
    },
    {
        id = "TR_m3_OE_AmbassadorTrouble",
        name = "Ambassador Trouble",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Decipher the speech of an unusual Telvanni ambassador."
    },
    {
        id = "TR_m3_OE_archer",
        name = "An Archer's Potential",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Impress a master archer."
    },
    {
        id = "TR_m3_OE_BreadcrumbTrail, TR_m3_OE_BreadcrumbTrailBlade, TR_m3_OE_BreadcrumbTrailGloves, TR_m3_OE_BreadcrumbTrailJournal, TR_m3_OE_BreadcrumbTrailRing",
        name = "A Breadcrumb Trail",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Find some missing items after a pub crawl."
    },
    {
        id = "TR_m3_OE_CriminalLawyer",
        name = "A Criminal Lawyer",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Help a criminal lawyer take care of their old client."
    },
    {
        id = "TR_m3_OE_DeadlyTreasure",
        name = "A Deadly Treasure",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Clean up in the aftermath of an ill-fated robbery."
    },
    {
        id = "TR_m3_MG_CursedGems",
        name = "Don't Touch My Gems!",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Assist a mage in his study of curses."
    },
    {
        id = "TR_m3_OE_DukeAffair, TR_m3_OE_DA_common, TR_m3_OE_DA_keys, TR_m3_OE_DA_poor, TR_m3_OE_DA_rich, TR_m3_OE_DA_tower",
        name = "The Exiled Duke's Affair",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "The Duke wants a lover and the thief wants out."
    },
    {
        id = "TR_m3_OE_GhoulBusiness, TR_m3_OE_GhoulArgonian, TR_m3_OE_GhoulImperial, TR_m3_OE_GhoulJannav",
        name = "Ghoulish Business",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Investigate a case of corpses leaving their coffins."
    },
    {
        id = "TR_m3_OE_HlarsisvAlju",
        name = "Hlarsis v Alju-Deekus",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Intervene in a legal dispute between a slavemaster and his former slave."
    },
    {
        id = "TR_m3_OE_Inspiration",
        name = "Illicit Inspiration",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Help the Imperial officer obtain her portrait from the \"extraordinary\" painter..."
    },
    {
        id = "TR_m3_OE_OhWhatCustoms",
        name = "Oh What Customs!",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Imperial regulations make Great House politics almost seem tame in comparison."
    },
    {
        id = "TR_m3_OE_AbductedAmbassador",
        name = "The Prince of Rats",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Return an ambassador to his embassy."
    },
    {
        id = "TR_m3_OE_Resigned",
        name = "Resigned to Fate",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Help to retrieve an important scroll, one of the clerks took with him to the sewers, to the Census officer."
    },
    {
        id = "TR_m3_OE_SmallComplaint",
        name = "A Small Complaint",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Another day in The Salty Futtocks, another dead body."
    },
    {
        id = "TR_m3_OE_CourtWizard",
        name = "The Sorceror's Apprentices",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Help choose a new master sorceror for Ebon Tower."
    },
    {
        id = "TR_m3_OE_StendarrTowerHaunting",
        name = "Stendarr Tower Haunting",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Exorcise a ghost that is haunting one of the castle towers."
    },
    {
        id = "TR_m3_OE_StickySituation",
        name = "Sticky Situation",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Help Eulix Festius build a new mortar."
    },
    {
        id = "TR_m3_OE_TamrielRebuilt",
        name = "Tamriel Rebuilt",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Help Docelle Bien finish her Tamriel map and learn the plight of a TR modder."
    },
    {
        id = "TR_m3_OE_Kassad",
        name = "A Taste of Home",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "A delivery from Hammerfell has gone awry."
    },
    {
        id = "TR_m7_HO_MissingFriend",
        name = "Waiting on a Friend",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Track down a missing miner."
    },
    {
        id = "TR_m3_MG_OE_IntsExts",
        name = "When Interiors Don't Match Their Exteriors",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Trace a hapless apprentice's unfortunate journey through a pocket realm."
    },
    {
        id = "TR_m3_OE_WhereHorseGone",
        name = "Where has the Horse Gone?",
        category = "Miscellaneous",
        subcategory = "Old Ebonheart",
        master = "Tamriel Rebuilt", text = "Find the lost horse of a Breton knight."
    },
    {
        id = "TR_m4_wil_KoboldFisher",
        name = "A Fishy Kobold",
        category = "Miscellaneous",
        subcategory = "Omaynis",
        master = "Tamriel Rebuilt", text = "Naru Ouradas has a fishy new neighbor."
    },
    {
        id = "TR_m4_Om_RemnantsResdayn, TR_m4_Om_RemnantsPath1, TR_m4_Om_RemnantsPath2, TR_m4_Om_RemnantsPath3, TR_m4_Om_RemnantsIbelard",
        name = "Remnants of Resdayn",
        category = "Miscellaneous",
        subcategory = "Omaynis",
        master = "Tamriel Rebuilt", text = "Test the truth of a curse in a Hlaalu egg mine."
    },
    {
        id = "TR_m4_Om_Statue, TR_m4_Om_StatueA, TR_m4_Om_StatueB",
        name = "The Statue",
        category = "Miscellaneous",
        subcategory = "Omaynis",
        master = "Tamriel Rebuilt", text = "Decorate a delta with the statue of a saint."
    },
    {
        id = "TR_m4_wil_HouseholdSlave",
        name = "A Household Slave is Wanted",
        category = "Miscellaneous",
        subcategory = "Oran Plantation",
        master = "Tamriel Rebuilt", text = "Dels Ravyn's slaves keep having 'accidents'. He wants a new one."
    },
    {
        id = "TR_m4_wil_OranEscaped, TR_m4_wil_OranEscaped2",
        name = "Awfully-Swift-Skink Breaks Free",
        category = "Miscellaneous",
        subcategory = "Oran Plantation",
        master = "Tamriel Rebuilt", text = "Assist with slave retainment. Or not."
    },
    {
        id = "TR_m4_wil_OranMissingBrother",
        name = "The Missing Brother",
        category = "Miscellaneous",
        subcategory = "Oran Plantation",
        master = "Tamriel Rebuilt", text = "Catch up with a man and his boat."
    },
    {
        id = "TR_m1_TO_RunningIntoTrouble, TR_m1_TO_RunningIntoTrouble_a",
        name = "Running Into Trouble",
        category = "Miscellaneous",
        subcategory = "Orelu Plantation",
        master = "Tamriel Rebuilt", text = "Two slaves are in peril after they escaped from the Orelu Plantation, get them to safety."
    },
    {
        id = "TR_m7_Oth_BanditsinKuriki",
        name = "Bandits in Kuriki",
        category = "Miscellaneous",
        subcategory = "Othmura",
        master = "Tamriel Rebuilt", text = "Clear Kuriki of outlaws for Othmura's commander."
    },
    {
        id = "TR_m7_Oth_BrothersLove",
        name = "A Brother's Love",
        category = "Miscellaneous",
        subcategory = "Othmura",
        master = "Tamriel Rebuilt", text = "A Temple Master has been intercepting mail."
    },
    {
        id = "TR_m7_Oth_ChangingHouses",
        name = "Changing Houses",
        category = "Miscellaneous",
        subcategory = "Othmura",
        master = "Tamriel Rebuilt", text = "A drumless Dunmer bemoans a moving mishap."
    },
    {
        id = "TR_m7_Oth_EdalvelLetter",
        name = "Letter for Edalvel Plantation",
        category = "Miscellaneous",
        subcategory = "Othmura",
        master = "Tamriel Rebuilt", text = "Bring an urgent missive to a plantation overseer."
    },
    {
        id = "TR_m7_Oth_FamilyBusiness",
        name = "The Family Business",
        category = "Miscellaneous",
        subcategory = "Othmura",
        master = "Tamriel Rebuilt", text = "Rebuff a recruiter for the Camonna Tong."
    },
    {
        id = "TR_m1_PT_ADH",
        name = "A Disobedient Husband",
        category = "Miscellaneous",
        subcategory = "Port Telvannis",
        master = "Tamriel Rebuilt", text = "Resolving a domestic dispute with attempted murder? It's got to be Port Telvannis."
    },
    {
        id = "TR_m1_PT_DreughGreaves",
        name = "Dreugh Greaves",
        category = "Miscellaneous",
        subcategory = "Port Telvannis",
        master = "Tamriel Rebuilt", text = "A wood elf has run off with a vital piece of armor. Get it back!"
    },
    {
        id = "TR_m1_PT_Ogrim",
        name = "Hunting an Ogrim",
        category = "Miscellaneous",
        subcategory = "Port Telvannis",
        master = "Tamriel Rebuilt", text = "Is this young Telvanni courageous or just plain stupid to attempt to battle an Ogrim?"
    },
    {
        id = "TR_m1_PT_MaI_1, TR_m1_PT_MaI_2, TR_m1_PT_MaI_3, TR_m1_PT_MaI_4",
        name = "Intrigue in Port Telvannis",
        category = "Miscellaneous",
        subcategory = "Port Telvannis",
        master = "Tamriel Rebuilt", text = "When a dead body is discovered in Port Telvannis, it is the start of a vendetta."
    },
    {
        id = "TR_m1_PT_Translation",
        name = "Lost in Translation",
        category = "Miscellaneous",
        subcategory = "Port Telvannis",
        master = "Tamriel Rebuilt", text = "If you can understand this Dark Elf gentleman you truly are a knower of the Velothi tongue."
    },
    {
        id = "TR_m1_PT_Muse",
        name = "Ninety-Nine Percent Inspiration",
        category = "Miscellaneous",
        subcategory = "Port Telvannis",
        master = "Tamriel Rebuilt", text = "A poet's muse is the final one percent of his inspiration, and she is not happy about that..."
    },
    {
        id = "TR_m1_PT_NoisesOff",
        name = "Noises Off",
        category = "Miscellaneous",
        subcategory = "Port Telvannis",
        master = "Tamriel Rebuilt", text = "It must be hard to be a successful enchanter when all you hear is noise..."
    },
    {
        id = "TR_m1_PT_PackRats",
        name = "Pack RATS!!!",
        category = "Miscellaneous",
        subcategory = "Port Telvannis",
        master = "Tamriel Rebuilt", text = "A fight between neighbors has gotten out of hand, and it is caused by a strange pet."
    },
    {
        id = "TR_m1_PT_SlaveTrade",
        name = "The Slave Trade",
        category = "Miscellaneous",
        subcategory = "Port Telvannis",
        master = "Tamriel Rebuilt", text = "One of the wares of the Port Telvannis slave market should be returned to the salesman..."
    },
    {
        id = "TR_m1_RR_Slander",
        name = "Alchemical Slander",
        category = "Miscellaneous",
        subcategory = "Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "A newcomer is trying to bring the reputation of two local alchemists into disrepute."
    },
    {
        id = "TR_m1_RR_Drunkard",
        name = "The Drunken Knight",
        category = "Miscellaneous",
        subcategory = "Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "A drunkard once was a noble knight. Help him to become one again."
    },
    {
        id = "TR_m1_RR_Romance",
        name = "Romance in Ranyon-ruhn",
        category = "Miscellaneous",
        subcategory = "Ranyon-ruhn",
        master = "Tamriel Rebuilt", text = "The Ranyon-ruhn guard captain, Simeth, is in love with Nataya Radasar and you should help him to get her attention."
    },
    {
        id = "TR_m3_Rils_Grotto",
        name = "Dangerous Waters",
        category = "Miscellaneous",
        subcategory = "Rilsoan",
        master = "Tamriel Rebuilt", text = "Lloris' brother hasn't returned from his dive. Find out what happened."
    },
    {
        id = "TR_m3_Rd_Burden, TR_m3_Rd_Burden_Agent, TR_m3_Rd_Burden_Betrayal, TR_m3_Rd_Burden_Punavit",
        name = "Burden of Proof",
        category = "Miscellaneous",
        subcategory = "Roa Dyr",
        master = "Tamriel Rebuilt", text = "Investigate Indoril Ilvi's suspicions of Vhul's Syvvit Tong."
    },
    {
        id = "TR_m3_RD_CastingRiches",
        name = "Casting the Riches Away",
        category = "Miscellaneous",
        subcategory = "Roa Dyr",
        master = "Tamriel Rebuilt", text = "As a rich mer's wealth grows, so too grows his fear of sin."
    },
    {
        id = "TR_m3_Rd_Drinkstealrant",
        name = "Drinking, Stealing, Ranting",
        category = "Miscellaneous",
        subcategory = "Roa Dyr",
        master = "Tamriel Rebuilt", text = "Investigate the case of the ranting Redguard."
    },
    {
        id = "TR_m3_RD_ExtPunish",
        name = "Extrajudicial Punishment",
        category = "Miscellaneous",
        subcategory = "Roa Dyr",
        master = "Tamriel Rebuilt", text = "Help a tollmer find a thief."
    },
    {
        id = "TR_m1_SP_QforAAdri",
        name = "Questions for Athenim Adri",
        category = "Miscellaneous",
        subcategory = "Sadas Plantation",
        master = "Tamriel Rebuilt", text = "In a small place like Sadas Plantation, curiosity can be troublesome..."
    },
    {
        id = "TR_m1_SP_SickStrider",
        name = "The Sick Strider",
        category = "Miscellaneous",
        subcategory = "Sadas Plantation",
        master = "Tamriel Rebuilt", text = "Discover the cure quickly, or the huge animal will collapse on top of you..."
    },
    {
        id = "TR_m7_Sdr_DefilingwithHoliness",
        name = "Defiling with Holiness",
        category = "Miscellaneous",
        subcategory = "Sadrathim",
        master = "Tamriel Rebuilt", text = "Ancestor ghosts are unnerved by an shrine to Arkay."
    },
    {
        id = "TR_m3_Sa_Inquiry, TR_m3_Sa_Idroso, TR_m3_Sa_Golveso, TR_m3_Sa_Ethasi, TR_m3_Sa_Dalam",
        name = "Religious Inquiry",
        category = "Miscellaneous",
        subcategory = "Sailen",
        master = "Tamriel Rebuilt", text = "Assist the Order of War in locating a cultist hiding in Sailen."
    },
    {
        id = "TR_m3_Er_Prayer",
        name = "Save a Prayer",
        category = "Miscellaneous",
        subcategory = "Sailen",
        master = "Tamriel Rebuilt", text = "The Ancestor Ghosts have strong opinions on this Dunmer's lovelife."
    },
    {
        id = "TR_m3_Sa_TheVoice",
        name = "The Voice to Calm Me Down",
        category = "Miscellaneous",
        subcategory = "Sailen",
        master = "Tamriel Rebuilt", text = "Break a hermit's silence."
    },
    {
        id = "TR_m1_SA_SC",
        name = "Sarvanni Courier: Mole Crab Eggs",
        category = "Miscellaneous",
        subcategory = "Sarvanni",
        master = "Tamriel Rebuilt", text = "For some extra drakes, deliver the molecrab eggs too!"
    },
    {
        id = "TR_m4_WickedWater",
        name = "Wicked Water Woes",
        category = "Miscellaneous",
        subcategory = "Savrethi Distillery",
        master = "Tamriel Rebuilt", text = "A dispute over water threatens the peace between Ashlanders and the Hlaalu."
    },
    {
        id = "TR_m3_Se_Invest",
        name = "Worthy Investment",
        category = "Miscellaneous",
        subcategory = "Seitur",
        master = "Tamriel Rebuilt", text = "Help a Redguard trader get some trade."
    },
    {
        id = "TR_m7_SepGaP_Shinathi",
        name = "This Too Shall Pass",
        category = "Miscellaneous",
        subcategory = "Septim's Gate Pass",
        master = "Tamriel Rebuilt", text = "A case of constipation requires urgent intervention."
    },
    {
        id = "TR_m7_ShiSha_FamilyAffair, TR_m7_ShiSha_FamilyAffair_d",
        name = "A Family Affair",
        category = "Miscellaneous",
        subcategory = "Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "Determine the fate of a traveling merchant."
    },
    {
        id = "TR_m7_ShiSha_Haunt, TR_m7_ShiSha_Haunt_S",
        name = "Haunted Instrument",
        category = "Miscellaneous",
        subcategory = "Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "When the dead don't sleep, neither can their neighbors."
    },
    {
        id = "TR_m7_ShiSha_LiftSpirits",
        name = "Lifting Spirits",
        category = "Miscellaneous",
        subcategory = "Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "Restock a bar with a bandit gang's booze supply."
    },
    {
        id = "TR_m7_ShiSha_Painting",
        name = "Painting Reclamation",
        category = "Miscellaneous",
        subcategory = "Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "A true test of your thieving arts."
    },
    {
        id = "TR_m7_ShiSha_Sense",
        name = "Sense of Apprehension",
        category = "Miscellaneous",
        subcategory = "Shipal-Sharai",
        master = "Tamriel Rebuilt", text = "Locate a narcotics smuggler in the canyons of Shipal-Shin."
    },
    {
        id = "TR_m7_SlaveTrouble",
        name = "Gweiwen's Slave Trouble",
        category = "Miscellaneous",
        subcategory = "Stormgate Pass",
        master = "Tamriel Rebuilt", text = "An Argonian runs for the border, with a cat-catcher on his heels."
    },
    {
        id = "TR_m3_Ta_Strike",
        name = "Unrest at Tahvel",
        category = "Miscellaneous",
        subcategory = "Tahvel",
        master = "Tamriel Rebuilt", text = "Help resolve a strike at Tahvel."
    },
    {
        id = "TR_m2_TGi_ComplicatComp",
        name = "Complicated Competition",
        category = "Miscellaneous",
        subcategory = "Tel Gilan",
        master = "Tamriel Rebuilt", text = "Assist a healer with a business problem."
    },
    {
        id = "TR_m2_He_M_SeekingFriend",
        name = "Seeking a Friend",
        category = "Miscellaneous",
        subcategory = "Tel Gilan",
        master = "Tamriel Rebuilt", text = "Help track down an old friend."
    },
    {
        id = "TR_m2_TMo_GoneToGround",
        name = "Gone to Ground",
        category = "Miscellaneous",
        subcategory = "Tel Mothrivra",
        master = "Tamriel Rebuilt", text = "Help a couple of Ordinators to bring a criminal to justice."
    },
    {
        id = "TR_m2_TMo_QualityTime",
        name = "Quality Time",
        category = "Miscellaneous",
        subcategory = "Tel Mothrivra",
        master = "Tamriel Rebuilt", text = "Help Feduro's brother Mohryl."
    },
    {
        id = "TR_m2_TMo_TrialsOfAge",
        name = "The Trials of Age",
        category = "Miscellaneous",
        subcategory = "Tel Mothrivra",
        master = "Tamriel Rebuilt", text = "Help an Old Lady."
    },
    {
        id = "TR_m2_TM_Brothers",
        name = "The Brave and the Foolish",
        category = "Miscellaneous",
        subcategory = "Tel Muthada",
        master = "Tamriel Rebuilt", text = "Get proof of bravery, if not brains."
    },
    {
        id = "TR_m2_TM_SadSong_a, TR_m2_TM_SadSong_b",
        name = "A Nord's Sad Song",
        category = "Miscellaneous",
        subcategory = "Tel Muthada",
        master = "Tamriel Rebuilt", text = "This bar's bard is really bringing down the atmosphere."
    },
    {
        id = "TR_m2_TM_Vendetta",
        name = "Sweet Vendetta",
        category = "Miscellaneous",
        subcategory = "Tel Muthada",
        master = "Tamriel Rebuilt", text = "A grieving mother will not be denied her vengeance. But how far is too much?"
    },
    {
        id = "TR_m1_TO_KillOrBeKilled",
        name = "Kill or Be Killed",
        category = "Miscellaneous",
        subcategory = "Tel Ouada",
        master = "Tamriel Rebuilt", text = "If a Morag Tong murder attempt is thwarted, the victim and his savior should be cautious."
    },
    {
        id = "TR_m1_TO_NinarisSecret",
        name = "Ninari Dorvayn's Secret",
        category = "Miscellaneous",
        subcategory = "Tel Ouada",
        master = "Tamriel Rebuilt", text = "What is the dark secret behind Ninari Dorvayn?"
    },
    {
        id = "TR_m1_TO_AColdharbourKeelhaul",
        name = "A Coldharbour Keelhaul",
        category = "Miscellaneous",
        subcategory = "Tel Ouada",
        master = "Tamriel Rebuilt", text = "Help a shady scholar with his \"research\" by retrieving an artifact from a shrine to Molag Bal."
    },
    {
        id = "TR_m4_T_IlvaalmuUnbound",
        name = "Ilvaalmu Unbound",
        category = "Miscellaneous",
        subcategory = "Teyn",
        master = "Tamriel Rebuilt", text = "A vampire lies trapped, but do you proffer a hand, or draw your blade?"
    },
    {
        id = "TR_m4_T_Lighthouse",
        name = "Lighthouse Keeper's Hospitality",
        category = "Miscellaneous",
        subcategory = "Teyn",
        master = "Tamriel Rebuilt", text = "A lighthouse keeper seeks company."
    },
    {
        id = "TR_m4_T_MotherInLaw",
        name = "Meet the Mother-In-Law",
        category = "Miscellaneous",
        subcategory = "Teyn",
        master = "Tamriel Rebuilt", text = "A Breton needs a fiancé, and you happen to be passing."
    },
    {
        id = "TR_m4_T_Euphoria, TR_m4_T_Euphoria_b",
        name = "The Ring of Euphoria",
        category = "Miscellaneous",
        subcategory = "Teyn",
        master = "Tamriel Rebuilt", text = "A robbed Ohmes-raht seeks a moving gift."
    },
    {
        id = "TR_m4_T_NucciusTR_m3_AT_Nuccius_LanetteTR_m4_T_Nuccius_DishesTR_m4_T_Nuccius_WWonTR_m4_T_Nuccius_WagerTR_m7_AI_Nuccius_Guar",
        name = "Vodunius Nuccius",
        category = "Miscellaneous",
        subcategory = "Teyn",
        master = "Tamriel Rebuilt", text = "A familiar face is down on his luck. Again."
    },
    {
        id = "TR_m7_Shin_BornNecro",
        name = "Born a Necromancer",
        category = "Miscellaneous",
        subcategory = "Ussiran Camp",
        master = "Tamriel Rebuilt", text = "Cover a novice necromancer's trail."
    },
    {
        id = "TR_m7_wil_ThrashThresher",
        name = "Thrash the Thresher",
        category = "Miscellaneous",
        subcategory = "Vadaryn Plantation",
        master = "Tamriel Rebuilt", text = "Kill the beast obstructing a plantation's trade."
    },
    {
        id = "TR_m4_wil_Ahnaissa",
        name = "A Khajiit's Calling",
        category = "Miscellaneous",
        subcategory = "Vathras Plantation",
        master = "Tamriel Rebuilt", text = "Host an interview with a slave."
    },
    {
        id = "TR_m3_VF_Shrine",
        name = "A Miner's Duty",
        category = "Miscellaneous",
        subcategory = "Velonith",
        master = "Tamriel Rebuilt", text = "A neighbor has a noise complaint."
    },
    {
        id = "TR_m2_VP_JealousShopkeeper",
        name = "The Jealous Shopkeeper",
        category = "Miscellaneous",
        subcategory = "Verulas Pass",
        master = "Tamriel Rebuilt", text = "Fix a footfall problem."
    },
    {
        id = "TR_m3_Vh_BardsTale",
        name = "A Bard's Tale",
        category = "Miscellaneous",
        subcategory = "Vhul",
        master = "Tamriel Rebuilt", text = "Help a bard tell his tale."
    },
    {
        id = "TR_m3_Vh_Temple",
        name = "Cleansing of the Temple",
        category = "Miscellaneous",
        subcategory = "Vhul",
        master = "Tamriel Rebuilt", text = "Convince a bothersome trader to leave the Temple grounds."
    },
    {
        id = "TR_m3_Vh_Honns, TR_m3_Vh_Honns1, TR_m3_Vh_Honns2, TR_m3_Vh_Honns3, TR_m3_Vh_Honns4",
        name = "Honns in Luck",
        category = "Miscellaneous",
        subcategory = "Vhul",
        master = "Tamriel Rebuilt", text = "Help a Nord who feels he got tricked by some slimy Dunmer."
    },
    {
        id = "TR_m3_Vh_Boots",
        name = "The Speed of Lightning",
        category = "Miscellaneous",
        subcategory = "Vhul",
        master = "Tamriel Rebuilt", text = "Race an Imperial with enchanted boots."
    },
    {
        id = "TR_m4_Vf_ManCrystal",
        name = "A Man in the Crystal",
        category = "Miscellaneous",
        subcategory = "Volenfaryon",
        master = "Tamriel Rebuilt", text = "Destroy a mabrigash's most magical enemy."
    },
    {
        id = "TR_m4_wil_BelBetu1",
        name = "Getting Rid of Vildaryn Terano",
        category = "Miscellaneous",
        subcategory = "Volenfaryon",
        master = "Tamriel Rebuilt", text = "Deter an unwanted apprentice."
    },
    {
        id = "TR_m4_wil_BelBetu2",
        name = "Expedition to Barzamthuand",
        category = "Miscellaneous",
        subcategory = "Volenfaryon",
        master = "Tamriel Rebuilt", text = "Gather precious metals from a Dwemer ruin."
    },
    {
        id = "TR_m4_wil_BelBetu3",
        name = "Blood Ritual of Volenfaryon",
        category = "Miscellaneous",
        subcategory = "Volenfaryon",
        master = "Tamriel Rebuilt", text = "Seize a stronghold for a potent magician."
    },
    {
        id = "TR_m7_Yand_AirDominance",
        name = "Roahaz' Air Dominance",
        category = "Miscellaneous",
        subcategory = "Yandaran",
        master = "Tamriel Rebuilt", text = "A Shinathi scout has lost his means of handling the Skyrender menace."
    },
    {
        id = "TR_m4_wil_CureDredaseDevani",
        name = "Cure Dredase Devani",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "Prevent the vampiric transformation of an imprisoned Ordinator."
    },
    {
        id = "TR_m4_TJ_DaedricDinner",
        name = "Daedric Dinner",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "Assist a Hunger in cooking a meal fit for a Daedric Prince!"
    },
    {
        id = "TR_m4_wil_HautharmoKill",
        name = "The Death of Oirdo Malamartle",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "A reclusive Lich and a follower of Stendarr. It can only end badly - but for whom?"
    },
    {
        id = "TR_m3_Rd_HisEyes",
        name = "His Eyes Are On You",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "A Legion agent hunts stolen intelligence."
    },
    {
        id = "TR_m3_wil_Hvaldur",
        name = "Hvaldur is Alive!",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "A Nord slave dreams of home."
    },
    {
        id = "TR_m3_St_Elimiran",
        name = "The Ill-Advised Heist",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "Help or hinder the thief, Elimiran."
    },
    {
        id = "TR_m7_wil_Nymph",
        name = "The Nymph and the Ogre",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "An exchange in a pool lands you in hot water."
    },
    {
        id = "TR_m7_wil_OneClan",
        name = "One Clan, Two Houses",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "A duo of descendants seek an ancestral cuirass."
    },
    {
        id = "TR_m4_wil_TaxmanIndalruhn",
        name = "A Paranoid Taxman",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "Escort an Imperial taxman to Indal-ruhn."
    },
    {
        id = "TR_m3_wil_Haliwaran",
        name = "Reclaiming Haliwaran",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "Uncover a scheme of the Imperial Legion."
    },
    {
        id = "TR_m3_LA_TheRift",
        name = "The Rift",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "Assist a wizard in reaching a pocket realm."
    },
    {
        id = "TR_m4_wil_Emmurbalpitu",
        name = "What Happened in Emmurbalpitu",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "Aid a Winged Twilight in an investigation."
    },
    {
        id = "TR_m4_wil_Immetarca",
        name = "When Elves Fly",
        category = "Miscellaneous",
        subcategory = "Wilderness (Aanthirin)",
        master = "Tamriel Rebuilt", text = "This Elven Enchanter is ready for take-off."
    },
    {
        id = "TR_m3_wil_Harrumat",
        name = "Harrumat Mine",
        category = "Miscellaneous",
        subcategory = "Wilderness (Alt Orethan)",
        master = "Tamriel Rebuilt", text = "Investigate the secret of a tunnel that was discovered in Harrumat Mine."
    },
    {
        id = "TR_m3_wil_Zanammu",
        name = "Rite of Passage",
        category = "Miscellaneous",
        subcategory = "Wilderness (Alt Orethan)",
        master = "Tamriel Rebuilt", text = "Retrieve an Ashlander from a rite of passage gone wrong..."
    },
    {
        id = "TR_m4_wil_ArmunRoadblock",
        name = "An Armun Roadblock",
        category = "Miscellaneous",
        subcategory = "Wilderness (Armun Ashlands)",
        master = "Tamriel Rebuilt", text = "Test your luck in an Armun traffic jam."
    },
    {
        id = "TR_m4_wil_Joscus",
        name = "Find Joscus' Body",
        category = "Miscellaneous",
        subcategory = "Wilderness (Armun Ashlands)",
        master = "Tamriel Rebuilt", text = "Locate a corpse in a flooded mine."
    },
    {
        id = "TR_m4_wil_GaNahiru",
        name = "Ga'Nahiru, or the Great Beast",
        category = "Miscellaneous",
        subcategory = "Wilderness (Armun Ashlands)",
        master = "Tamriel Rebuilt", text = "Take down a beast of Ashlander fable."
    },
    {
        id = "TR_m4_wil_UrnuridunGuar",
        name = "Poisoned Urnuridun Guar",
        category = "Miscellaneous",
        subcategory = "Wilderness (Armun Ashlands)",
        master = "Tamriel Rebuilt", text = "Choose life or death for a guar."
    },
    {
        id = "TR_m2_Wil_RuinOfStrife",
        name = "Factory of Strife",
        category = "Miscellaneous",
        subcategory = "Wilderness (Boethiah's Spine)",
        master = "Tamriel Rebuilt", text = "A looters' turf war brews in Bthangthamuzand."
    },
    {
        id = "TR_m2_wil_Pestilent",
        name = "Pestilent Magic",
        category = "Miscellaneous",
        subcategory = "Wilderness (Boethiah's Spine)",
        master = "Tamriel Rebuilt", text = "Help Orenin Hlano heal his illness and kill the necromancer who caused it."
    },
    {
        id = "TR_m2_wil_Pestilent_b",
        name = "Pestilent Magic: The Necromancer's Cattle",
        category = "Miscellaneous",
        subcategory = "Wilderness (Boethiah's Spine)",
        master = "Tamriel Rebuilt", text = "Save a Nord woman from a necromancer's experiments."
    },
    {
        id = "TR_m2_wil_Tongue",
        name = "Regrowing a Tongue",
        category = "Miscellaneous",
        subcategory = "Wilderness (Boethiah's Spine)",
        master = "Tamriel Rebuilt", text = "Help a pilgrim find his words again."
    },
    {
        id = "TR_m7_Oth_Bugtracker",
        name = "Bugtesting with Bera Famori",
        category = "Miscellaneous",
        subcategory = "Wilderness (Coronati Basin)",
        master = "Tamriel Rebuilt", text = "Assist a mad mer with her Yeth-Grub experiments."
    },
    {
        id = "TR_m7_Sdr_TheStinkCurse",
        name = "The Curse of Foul Stench",
        category = "Miscellaneous",
        subcategory = "Wilderness (Coronati Basin)",
        master = "Tamriel Rebuilt", text = "Intercede in a curse laid upon an odorous mer."
    },
    {
        id = "TR_m7_TheDeadPilgrim",
        name = "The Dead Pilgrim",
        category = "Miscellaneous",
        subcategory = "Wilderness (Coronati Basin)",
        master = "Tamriel Rebuilt", text = "Bring peace to a pilgrim from one already passed."
    },
    {
        id = "TR_m7_wil_LurkerInTheMangrove",
        name = "Lurker in the Mangrove",
        category = "Miscellaneous",
        subcategory = "Wilderness (Coronati Basin)",
        master = "Tamriel Rebuilt", text = "Relieve a bridge of its troll."
    },
    {
        id = "TR_m7_wil_SecretMaster",
        name = "Secret Master's Alchemical Tools",
        category = "Miscellaneous",
        subcategory = "Wilderness (Coronati Basin)",
        master = "Tamriel Rebuilt", text = "A furious alchemist demands the return of her apparatus."
    },
    {
        id = "TR_m3_wil_Esuranamit",
        name = "Lights Out",
        category = "Miscellaneous",
        subcategory = "Wilderness (Lan Orethan)",
        master = "Tamriel Rebuilt", text = "A humorous task for the Madgod's amusement."
    },
    {
        id = "TR_m2_wil_Hlersis",
        name = "A Lost Traveler",
        category = "Miscellaneous",
        subcategory = "Wilderness (Mephalan Vales)",
        master = "Tamriel Rebuilt", text = "Guide a lost Dunmer through the Mephalan Vales."
    },
    {
        id = "TR_m2_wil_Between",
        name = "Walk the Talk",
        category = "Miscellaneous",
        subcategory = "Wilderness (Mephalan Vales)",
        master = "Tamriel Rebuilt", text = "At an Orc's behest, play a prank on two mighty heroes."
    },
    {
        id = "TR_m2_wil_Legacy",
        name = "A Ruined Legacy",
        category = "Miscellaneous",
        subcategory = "Wilderness (Molag Ruhn)",
        master = "Tamriel Rebuilt", text = "Assist a Dunmer in retrieving the weapon of her ancestors."
    },
    {
        id = "TR_m2_Wil_AvengeKnights",
        name = "Avenge the Knights",
        category = "Miscellaneous",
        subcategory = "Wilderness (Molag Ruhn)",
        master = "Tamriel Rebuilt", text = "Help two knights avenge their fallen comrades."
    },
    {
        id = "TR_m2_Wil_WhichWitch",
        name = "Which Witch?",
        category = "Miscellaneous",
        subcategory = "Wilderness (Molag Ruhn)",
        master = "Tamriel Rebuilt", text = "A witch and a naked barbarian... it's déjà vu all over again."
    },
    {
        id = "TR_m7_wil_DralnasVirian",
        name = "The Fate of Dralnas Virian",
        category = "Miscellaneous",
        subcategory = "Wilderness (Othreleth Woods)",
        master = "Tamriel Rebuilt", text = "A mer's son has sequestered himself with a hermit, and the family want word."
    },
    {
        id = "TR_m3_TT_RuinousKeep",
        name = "Dead Shores",
        category = "Miscellaneous",
        subcategory = "Wilderness (Padomaic Ocean)",
        master = "Tamriel Rebuilt", text = "Help an Ordinator escape imprisonment from his necromancer captors."
    },
    {
        id = "TR_m3_stranded",
        name = "Stranded",
        category = "Miscellaneous",
        subcategory = "Wilderness (Padomaic Ocean)",
        master = "Tamriel Rebuilt", text = "Salvation for a sandbound sailor?"
    },
    {
        id = "TR_m3_OE_Freedom, TR_m3_OE_Freedom2",
        name = "Freedom for a Fiend",
        category = "Miscellaneous",
        subcategory = "Wilderness (Random)",
        master = "Tamriel Rebuilt", text = "Unravel the twisted mystery of a trapped soul seeking revenge against its captor."
    },
    {
        id = "TR_m4_wil_Troupe_Trouble",
        name = "A Troupe in Trouble",
        category = "Miscellaneous",
        subcategory = "Wilderness (Roth Roryn)",
        master = "Tamriel Rebuilt", text = "Get a group of actors back on the road."
    },
    {
        id = "TR_m4_wil_Shenjirra",
        name = "Cat-Catchers on the Road",
        category = "Miscellaneous",
        subcategory = "Wilderness (Roth Roryn)",
        master = "Tamriel Rebuilt", text = "Aid a recaptured escapee."
    },
    {
        id = "TR_m4_wil_ArgonianBandits",
        name = "Killing of Ulves Heladren",
        category = "Miscellaneous",
        subcategory = "Wilderness (Roth Roryn)",
        master = "Tamriel Rebuilt", text = "Come across the scene of a crime."
    },
    {
        id = "TR_m4_wil_MannuScamps",
        name = "The Many Scamps of Mannu",
        category = "Miscellaneous",
        subcategory = "Wilderness (Roth Roryn)",
        master = "Tamriel Rebuilt", text = "Find the source of a Scamp swarm."
    },
    {
        id = "TR_m4_wil_MyDearFriendArvena",
        name = "My Dear Friend Arvena",
        category = "Miscellaneous",
        subcategory = "Wilderness (Roth Roryn)",
        master = "Tamriel Rebuilt", text = "Launch a rescue for a Redguard's old friend."
    },
    {
        id = "TR_m4_wil_NirnBoundSaint, TR_m4_wil_NirnBoundSaintB, TR_m4_wil_NirnBoundSaintC, TR_m4_wil_NirnBoundSaintD",
        name = "A Nirn-Bound Saint",
        category = "Miscellaneous",
        subcategory = "Wilderness (Roth Roryn)",
        master = "Tamriel Rebuilt", text = "A Golden Saint seeks to exit a binding arrangement."
    },
    {
        id = "TR_m4_wil_BuyingRope",
        name = "A Rope Salesman",
        category = "Miscellaneous",
        subcategory = "Wilderness (Roth Roryn)",
        master = "Tamriel Rebuilt", text = "A chance encounter could leave you hanging."
    },
    {
        id = "TR_m4_wil_SkeletonWizard, TR_m4_wil_SkeletonWizardB, TR_m4_wil_SkeletonWizardC",
        name = "Skeleton Wizard",
        category = "Miscellaneous",
        subcategory = "Wilderness (Roth Roryn)",
        master = "Tamriel Rebuilt", text = "You see two corpses, but one's still standing..."
    },
    {
        id = "TR_m4_wil_TribunalTS",
        name = "Tribunal Thrill-Seeking",
        category = "Miscellaneous",
        subcategory = "Wilderness (Roth Roryn)",
        master = "Tamriel Rebuilt", text = "Give an exciting tomb tour for two bored Breton nobles."
    },
    {
        id = "TR_m2_Nm_BrokenFamily",
        name = "A Broken Family",
        category = "Miscellaneous",
        subcategory = "Wilderness (Sacred Lands)",
        master = "Tamriel Rebuilt", text = "Brotherly love competes with a holy duty."
    },
    {
        id = "TR_m3_wil_KriepsTheWeak",
        name = "Krieps the Weak",
        category = "Miscellaneous",
        subcategory = "Wilderness (Sacred Lands)",
        master = "Tamriel Rebuilt", text = "Calm a fearful artisan."
    },
    {
        id = "TR_m2_wil_Farm",
        name = "Preaching by Proxy",
        category = "Miscellaneous",
        subcategory = "Wilderness (Sacred Lands)",
        master = "Tamriel Rebuilt", text = "Convert a stray sheep... or, at least, try to."
    },
    {
        id = "TR_m7_wil_LongWayDown",
        name = "A Long Way Down",
        category = "Miscellaneous",
        subcategory = "Wilderness (Shipal-Shin)",
        master = "Tamriel Rebuilt", text = "Recover a ring lost in a nasty fall."
    },
    {
        id = "TR_m7_wil_OnRocks",
        name = "On the Rocks",
        category = "Miscellaneous",
        subcategory = "Wilderness (Shipal-Shin)",
        master = "Tamriel Rebuilt", text = "A hungover clerk needs a courier to turn in her work."
    },
    {
        id = "TR_m7_Ns_Poison",
        name = "Poison for Indring",
        category = "Miscellaneous",
        subcategory = "Wilderness (Shipal-Shin)",
        master = "Tamriel Rebuilt", text = "Become a ratcatcher's resupply."
    },
    {
        id = "TR_m2_wil_Faith",
        name = "Blind Faith",
        category = "Miscellaneous",
        subcategory = "Wilderness (Sunad Mora)",
        master = "Tamriel Rebuilt", text = "Escort a lost Dunmer and her traveling rat."
    },
    {
        id = "TR_m1_wil_SmuggleSeeker",
        name = "Chasing the Smugglers",
        category = "Miscellaneous",
        subcategory = "Wilderness (Sunad Mora)",
        master = "Tamriel Rebuilt", text = "Can you discover the hideout of these smugglers?"
    },
    {
        id = "TR_m1_wil_Coward",
        name = "The Coward and the Tomb",
        category = "Miscellaneous",
        subcategory = "Wilderness (Sunad Mora)",
        master = "Tamriel Rebuilt", text = "We all know that ancestral tombs can be scary, but the tomb of your own family?"
    },
    {
        id = "TR_m1_wil_EscortToTO",
        name = "Escort to Tel Ouada",
        category = "Miscellaneous",
        subcategory = "Wilderness (Sunad Mora)",
        master = "Tamriel Rebuilt", text = "Help a merchant worried about bandits reach her destination."
    },
    {
        id = "TR_m3_Wil_Foeburner",
        name = "Foeburner",
        category = "Miscellaneous",
        subcategory = "Wilderness (Sundered Scar)",
        master = "Tamriel Rebuilt", text = "Prepare a Golden Saint for battle."
    },
    {
        id = "TR_m1_wil_Drink, TR_m1_wil_Drink_b",
        name = "Don't Give Drink to Miners",
        category = "Miscellaneous",
        subcategory = "Wilderness (Telvanni Isles)",
        master = "Tamriel Rebuilt", text = "The miners in the Nethre-Pulu Egg Mine want to throw a party, and you should sort out the drinks..."
    },
    {
        id = "TR_m1_wil_MudlapMosslog",
        name = "Mudlap and the Mosslog",
        category = "Miscellaneous",
        subcategory = "Wilderness (Telvanni Isles)",
        master = "Tamriel Rebuilt", text = "Help a Wood Elf execute a daring plan."
    },
    {
        id = "TR_m1_wil_woebringer",
        name = "Woebringer",
        category = "Miscellaneous",
        subcategory = "Wilderness (Telvanni Isles)",
        master = "Tamriel Rebuilt", text = "Why is a proud Nord warrior walking around naked and why is a slave girl carrying around a giant warhammer?"
    },
    {
        id = "TR_m4_VM_Headless",
        name = "Headless",
        category = "Miscellaneous",
        subcategory = "Wilderness (Velothi Mountains)",
        master = "Tamriel Rebuilt", text = "Assemble a skeletal armiger."
    },
    {
        id = "TR_m4_wil_NakedWitch",
        name = "The Naked Witch",
        category = "Miscellaneous",
        subcategory = "Wilderness (Velothi Mountains)",
        master = "Tamriel Rebuilt", text = "A Nord has left this witch feeling severely underdressed."
    },
    {
        id = "TR_m2_FW_SkoomaFree",
        name = "Free From Addiction, But Not From Debt",
        category = "Miscellaneous",
        subcategory = "Windmoth Legion Fort",
        master = "Tamriel Rebuilt", text = "Help a legionnaire leave his skooma-fuelled past behind."
    },
    {
        id = "TR_m0_blades_Aquilinius, TR_m0_blades_Aquilinius2, TR_m0_blades_Doure, TR_m0_blades_Doure2, TR_m0_blades_Idra, TR_m0_blades_Idra2",
        name = "Blades Trainers",
        category = "Miscellaneous",
        subcategory = "Vvardenfell",
        master = "Tamriel Rebuilt", text = "Seek out the Blades Trainers on the Mainland for gifts and advice."
    },
}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Completionist] Sending TR quest data...")
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}
