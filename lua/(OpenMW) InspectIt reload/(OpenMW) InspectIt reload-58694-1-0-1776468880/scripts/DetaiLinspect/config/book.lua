local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Book] = {
        title = 'Book/Scroll',
        color = util.color.rgb(0.6, 0.4, 0.2),
        showSkill = true,
        showValue = true,
        uniqueDescriptions = {
			['BookSkill_Enchant1'] = {
				'Feyfolken Volume I.',
				'Enchantment lore book.',
				'Type: Book'
			},
			['BookSkill_Enchant2'] = {
				'Queen-She-Wolf, Volume VIII.',
				'Enchantment-focused tome.',
				'Type: Book'
			},
			['bookskill_enchant3'] = {
				'Palla, Volume II.',
				'Book on enchantment skills.',
				'Type: Book'
			},
			['bookskill_enchant4'] = {
				'36 Lessons of Vivec, Sermon 19.',
				'Enchantment teachings.',
				'Type: Book'
			},
			['bookskill_enchant5'] = {
				'The Final Lesson.',
				'Advanced enchantment guide.',
				'Type: Book'
			},
			['bookskill_destruction1'] = {
				'Terror of Castle Xyr.',
				'Destruction magic tome.',
				'Type: Book'
			},
			['bookskill_destruction2'] = {
				"In Response to Bero's Speech.",
				'Destruction lore book.',
				'Type: Book'
			},
			['bookskill_destruction3'] = {
				' предполагаемое коварство',
				'Destruction strategy guide.',
				'Type: Book'
			},
			['bookskill_destruction4'] = {
				'The Art of Battle Magic.',
				'Destruction combat teachings.',
				'Type: Book'
			},
			['BookSkill_Destruction5'] = {
				'The Secret of Talara, Part 3.',
				'Advanced destruction lore.',
				'Type: Book'
			},
			['BookSkill_Alteration1'] = {
				'On Aquatic Breathing.',
				'Alteration skill guide.',
				'Type: Book'
			},
			['BookSkill_Alteration2'] = {
				'On the Draconian Breakthrough.',
				'Alteration lore tome.',
				'Type: Book'
			},
			['BookSkill_Alteration3'] = {
				'Sithis.',
				'Alteration-related text.',
				'Type: Book'
			},
			['BookSkill_Alteration4'] = {
				'36 Lessons of Vivec, Sermon 13.',
				'Alteration teachings.',
				'Type: Book'
			},
			['BookSkill_Alteration5'] = {
				'Lunar Lorkhan.',
				'Alteration mysticism book.',
				'Type: Book'
			},
			['bookskill_illusion1'] = {
				'Queen-She-Wolf, Volume III.',
				'Illusion lore tome.',
				'Type: Book'
			},
			['bookskill_illusion2'] = {
				'Silence.',
				'Illusion skill guide.',
				'Type: Book'
			},
			['bookskill_illusion3'] = {
				'Incident at Necrom.',
				'Illusion-related narrative.',
				'Type: Book'
			},
			['bookskill_illusion4'] = {
				'Palla, Volume I.',
				'Illusion teachings.',
				'Type: Book'
			},
			['bookskill_illusion5'] = {
				'The Secret of Talara, Part 4.',
				'Illusion advanced lore.',
				'Type: Book'
			},
			['BookSkill_Conjuration1'] = {
				'Feyfolken Volume II.',
				'Conjuration lore book.',
				'Type: Book'
			},
			['BookSkill_Conjuration2'] = {
				'Feyfolken Volume III.',
				'Conjuration teachings.',
				'Type: Book'
			},
			['BookSkill_Conjuration3'] = {
				'2920, Month of Fire.',
				'Conjuration-related text.',
				'Type: Book'
			},
			['BookSkill_Conjuration4'] = {
				'2920, Month of Frost.',
				'Conjuration lore tome.',
				'Type: Book'
			},
			['bookskill_conjuration5'] = {
				"A Warrior's Concerns.",
				'Conjuration guide for warriors.',
				'Type: Book'
			},
			['bookskill_mysticism1'] = {
				'Rebellion at Festhold.',
				'Mysticism lore book.',
				'Type: Book'
			},
			['BookSkill_Mysticism2'] = {
				'2920, Month of Sunrise.',
				'Mysticism-related text.',
				'Type: Book'
			},
			['BookSkill_Mysticism3'] = {
				'36 Lessons of Vivec, Sermon 4.',
				'Mysticism teachings.',
				'Type: Book'
			},
			['BookSkill_Mysticism4'] = {
				'36 Lessons of Vivec, Sermon 36.',
				'Advanced mysticism guide.',
				'Type: Book'
			},
			['BookSkill_Mysticism5'] = {
				'Charwich-Konning, Volume 3.',
				'Mysticism lore tome.',
				'Type: Book'
			},
			['bookskill_restoration1'] = {
				'Withershine.',
				'Restoration magic guide.',
				'Type: Book'
			},
			['bookskill_restoration2'] = {
				'Notes on Racial Phylogenesis.',
				'Restoration-related lore.',
				'Type: Book'
			},
			['bookskill_restoration3'] = {
				'Four Admirers of Benita.',
				'Restoration narrative.',
				'Type: Book'
			},
			['BookSkill_Restoration4'] = {
				'2920, Month of Rain.',
				'Restoration lore text.',
				'Type: Book'
			},
			['BookSkill_Restoration5'] = {
				'The Secret of Talara, Part 2.',
				'Restoration advanced teachings.',
				'Type: Book'
			},
			['BookSkill_Alchemy1'] = {
				'Game at Dinner.',
				'Alchemy guidebook.',
				'Type: Book'
			},
			['BookSkill_Alchemy2'] = {
				'Pie and Diamond.',
				'Alchemy lore tome.',
				'Type: Book'
			},
			['BookSkill_Alchemy3'] = {
				'Song of Alchemists.',
				'Alchemy poetry/guide.',
				'Type: Book'
			},
			['BookSkill_Alchemy4'] = {
				'36 Lessons of Vivec, Sermon 2.',
				'Alchemy teachings.',
				'Type: Book'
			},
			['BookSkill_Alchemy5'] = {
				'36 Lessons of Vivec, Sermon 18.',
				'Advanced alchemy guide.',
				'Type: Book'
			},
			['bookskill_unarmored1'] = {
				"Ghost's Dowry.",
				'Unarmored combat guide.',
				'Type: Book'
			},
			['bookskill_unarmored2'] = {
				'Charwich-Konning, Volume 1.',
				'Unarmored lore tome.',
				'Type: Book'
			},
			['bookskill_unarmored3'] = {
				'36 Lessons of Vivec, Sermon 11.',
				'Unarmored teachings.',
				'Type: Book'
			},
			['bookskill_unarmored4'] = {
				'36 Lessons of Vivec, Sermon 15.',
				'Unarmored advanced guide.',
				'Type: Book'
			},
			['bookskill_unarmored5'] = {
				'36 Lessons of Vivec, Sermon 34.',
				'Unarmored lore text.',
				'Type: Book'
			},
			['BookSkill_Block1'] = {
				"Abernanite's Fatal Strike.",
				'Blocking technique guide.',
				'Type: Book'
			},
			['bookskill_block2'] = {
				'Mirror.',
				'Blocking strategy book.',
				'Type: Book'
			},
			['BookSkill_Block3'] = {
				'Dance in Flame, Part 2.',
				'Blocking in combat guide.',
				'Type: Book'
			},
			['BookSkill_Block4'] = {
				'36 Lessons of Vivec, Sermon 7.',
				'Blocking teachings.',
				'Type: Book'
			},
			['BookSkill_Block5'] = {
				'36 Lessons of Vivec, Sermon 32.',
				'Advanced blocking guide.',
				'Type: Book'
			},
			['BookSkill_Armorer1'] = {
				"Armorer's Challenge.",
				'Armoring craft guide.',
				'Type: Book'
			},
			['BookSkill_Armorer2'] = {
				"Akrash's Last Sheaths.",
				'Armoring lore tome.',
				'Type: Book'
			},
			['BookSkill_Armorer3'] = {
				'36 Lessons of Vivec, Sermon 6.',
				'Armoring teachings.',
				'Type: Book'
			},
			['BookSkill_Armorer4'] = {
				'36 Lessons of Vivec, Sermon 25.',
				'Advanced armoring guide.',
				'Type: Book'
			},
			['BookSkill_Armorer5'] = {
				'36 Lessons of Vivec, Sermon 29.',
				'Armoring lore text.',
				'Type: Book'
			},
			['bookskill_medium armor1'] = {
				"Anekina Cherim's Heart.",
				'Medium armor lore book.',
				'Type: Book'
			},
			['BookSkill_Medium Armor2'] = {
				'Bone, Part One.',
				'Medium armor guide.',
				'Type: Book'
			},
			['BookSkill_Medium Armor3'] = {
				'Bone, Part Two.',
				'Continuation of medium armor guide.',
				'Type: Book'
			},
			['bookskill_medium armor4'] = {
				'36 Lessons of Vivec, Sermon 22.',
				'Medium armor teachings.',
				'Type: Book'
			},
			['bookskill_medium armor5'] = {
				'36 Lessons of Vivec, Sermon 33.',
				'Advanced medium armor guide.',
				'Type: Book'
			},
			['bookskill_heavy armor1'] = {
				"Hallgerd's Tale.",
				'Heavy armor lore tome.',
				'Type: Book'
			},
			['BookSkill_Heavy Armor2'] = {
				'2920, Month of Midyear.',
				'Heavy armor-related text.',
				'Type: Book'
			},
			['BookSkill_Heavy Armor3'] = {
				'Kimerwamidium.',
				'Heavy armor craft guide.',
				'Type: Book'
			},
			['bookskill_heavy armor4'] = {
				'How Orsinium Fell to the Orcs.',
				'Heavy armor lore narrative.',
				'Type: Book'
			},
			['bookskill_heavy armor5'] = {
				'36 Lessons of Vivec, Sermon 12.',
				'Heavy armor teachings.',
				'Type: Book'
			},
			['bookskill_blunt weapon1'] = {
				"Redoran's Hope.",
				'Blunt weapon guide.',
				'Type: Book'
			},
			['BookSkill_Blunt Weapon2'] = {
				'On the Importance of Place.',
				'Blunt weapon strategy book.',
				'Type: Book'
			},
			['bookskill_blunt weapon3'] = {
				'Night Falls on Sentinel.',
				'Blunt weapon lore narrative.',
				'Type: Book'
			},
			['BookSkill_Blunt Weapon4'] = {
				'36 Lessons of Vivec, Sermon 3.',
				'Blunt weapon teachings.',
				'Type: Book'
			},
			['BookSkill_Blunt Weapon5'] = {
				'36 Lessons of Vivec, Sermon 9.',
				'Advanced blunt weapon guide.',
				'Type: Book'
			},
			['BookSkill_Long Blade1'] = {
				'Words and Philosophy.',
				'Long blade combat guide.',
				'Type: Book'
			},
			['BookSkill_Long Blade2'] = {
				'2920, Month of Morning Star.',
				'Long blade lore text.',
				'Type: Book'
			},
			['bookskill_long blade3'] = {
				'36 Lessons of Vivec, Sermon 17.',
				'Long blade teachings.',
				'Type: Book'
			},
			['bookskill_long blade4'] = {
				'36 Lessons of Vivec, Sermon 20.',
				'Advanced long blade guide.',
				'Type: Book'
			},
			['bookskill_long blade5'] = {
				'36 Lessons of Vivec, Sermon 23.',
				'Long blade lore narrative.',
				'Type: Book'
			},
			['BookSkill_Axe1'] = {
				'The Third Door.',
				'Axe combat guide.',
				'Type: Book'
			},
			['bookskill_axe2'] = {
				'Man with an Axe.',
				'Axe strategy book.',
				'Type: Book'
			},
			['BookSkill_Axe3'] = {
				'The Seed.',
				'Axe lore narrative.',
				'Type: Book'
			},
			['BookSkill_Axe4'] = {
				'36 Lessons of Vivec, Sermon 5.',
				'Axe teachings.',
				'Type: Book'
			},
			['BookSkill_Axe5'] = {
				'36 Lessons of Vivec, Sermon 16.',
				'Advanced axe guide.',
				'Type: Book'
			},
			['bookskill_spear1'] = {
				"Smuggler's Island.",
				'Spear combat guide.',
				'Type: Book'
			},
			['BookSkill_Spear2'] = {
				'2920, Month of Meridian.',
				'Spear lore text.',
				'Type: Book'
			},
			['bookskill_spear3'] = {
				'36 Lessons of Vivec, Sermon 14.',
				'Spear teachings.',
				'Type: Book'
			},
			['bookskill_spear4'] = {
				'36 Lessons of Vivec, Sermon 24.',
				'Advanced spear guide.',
				'Type: Book'
			},
			['bookskill_spear5'] = {
				'36 Lessons of Vivec, Sermon 35.',
				'Spear lore narrative.',
				'Type: Book'
			},
			['BookSkill_Athletics1'] = {
				'Ransom for Zarek.',
				'Athletics guidebook.',
				'Type: Book'
			},
			['BookSkill_Athletics2'] = {
				'Dance in Flame, Part 3.',
				'Athletics combat guide.',
				'Type: Book'
			},
			['BookSkill_Athletics3'] = {
				'36 Lessons of Vivec, Sermon 1.',
				'Athletics teachings.',
				'Type: Book'
			},
			['BookSkill_Athletics4'] = {
				'36 Lessons of Vivec, Sermon 8.',
				'Advanced athletics guide.',
				'Type: Book'
			},
			['BookSkill_Athletics5'] = {
				'36 Lessons of Vivec, Sermon 31.',
				'Athletics lore narrative.',
				'Type: Book'
			},
			['bookskill_security1'] = {
				'Locked Room.',
				'Security guidebook.',
				'Type: Book'
			},
			['bookskill_security2'] = {
				'Queen-She-Wolf, Volume I.',
				'Security lore tome.',
				'Type: Book'
			},
			['BookSkill_Security3'] = {
				'Dowry.',
				'Security strategy book.',
				'Type: Book'
			},
			['bookskill_security4'] = {
				'Whim of Fortune.',
				'Security guide with tricks.',
				'Type: Book'
			},
			['bookskill_security5'] = {
				"Thieves' Satiety.",
				'Security lore narrative.',
				'Type: Book'
			},
			['bookskill_sneak1'] = {
				'Queen-She-Wolf, Volume VI.',
				'Sneak lore tome.',
				'Type: Book'
			},
			['BookSkill_Sneak2'] = {
				'2920, Month of Harvest.',
				'Sneak guidebook.',
				'Type: Book'
			},
			['BookSkill_Sneak3'] = {
				"Azura's Box.",
				'Sneak strategy narrative.',
				'Type: Book'
			},
			['bookskill_sneak4'] = {
				'Trap.',
				'Sneak guide with traps info.',
				'Type: Book'
			},
			['bookskill_sneak5'] = {
				"Vivec's 36 Lessons, Sermon 26.",
				'Improves sneak skill.',
				'Type: Book'
			},
			['bookskill_acrobatics1'] = {
				'Mastering Acrobatics.',
				'Enhances acrobatics abilities.',
				'Type: Book'
			},
			['BookSkill_Acrobatics2'] = {
				'Fire Dance, Part 1.',
				'Teaches acrobatics techniques.',
				'Type: Book'
			},
			['BookSkill_Acrobatics3'] = {
				'Fire Dance, Part 4.',
				'Advances acrobatics skills.',
				'Type: Book'
			},
			['BookSkill_Acrobatics4'] = {
				'Black Arrow, Volume 1.',
				'Acrobatics training manual.',
				'Type: Book'
			},
			['BookSkill_Acrobatics5'] = {
				'Talara’s Secret, Part 1.',
				'Acrobatics techniques revealed.',
				'Type: Book'
			},
			['BookSkill_Light Armor1'] = {
				'Rear Guard.',
				'Light armor training guide.',
				'Type: Book'
			},
			['BookSkill_Light Armor2'] = {
				'Ice and Chiton.',
				'Techniques for light armor use.',
				'Type: Book'
			},
			['bookskill_light armor3'] = {
				'Jornibret’s Final Dance.',
				'Advanced light armor tactics.',
				'Type: Book'
			},
			['bookskill_light armor4'] = {
				'Vivec’s 36 Lessons, Sermon 21.',
				'Improves light armor skill.',
				'Type: Book'
			},
			['bookskill_light armor5'] = {
				'Vivec’s 36 Lessons, Sermon 28.',
				'Enhances light armor proficiency.',
				'Type: Book'
			},
			['bookskill_short blade1'] = {
				'The Nameless Book.',
				'Short blade combat guide.',
				'Type: Book'
			},
			['BookSkill_Short Blade2'] = {
				'2920, Month of Dusk.',
				'Short blade techniques described.',
				'Type: Book'
			},
			['BookSkill_Short Blade3'] = {
				'2920, Month of Evening Star.',
				'Advanced short blade training.',
				'Type: Book'
			},
			['BookSkill_Short Blade4'] = {
				'Vivec’s 36 Lessons, Sermon 10.',
				'Improves short blade skill.',
				'Type: Book'
			},
			['BookSkill_Short Blade5'] = {
				'Vivec’s 36 Lessons, Sermon 30.',
				'Master short blade techniques.',
				'Type: Book'
			},
			['bookskill_marksman1'] = {
				'Golden Ribbon.',
				'Marksmanship training manual.',
				'Type: Book'
			},
			['BookSkill_Marksman2'] = {
				'Fire Dance, Part 5.',
				'Marksmanship techniques inside.',
				'Type: Book'
			},
			['bookskill_marksman3'] = {
				'Vernakcus and Burlor.',
				'Marksmanship guide with stories.',
				'Type: Book'
			},
			['bookskill_marksman4'] = {
				'Lesson in Archery Art.',
				'Fundamentals of marksmanship.',
				'Type: Book'
			},
			['bookskill_marksman5'] = {
				'Black Arrow, Volume II.',
				'Advanced marksmanship tactics.',
				'Type: Book'
			},
			['bookskill_mercantile1'] = {
				'The Game of Trade.',
				'Merchandising skills guide.',
				'Type: Book'
			},
			['bookskill_mercantile2'] = {
				'She-Wolf Queen, Book IV.',
				'Trade strategies revealed.',
				'Type: Book'
			},
			['BookSkill_Mercantile3'] = {
				'2920, Month of Sun’s Turning.',
				'Mercantile techniques described.',
				'Type: Book'
			},
			['bookskill_mercantile4'] = {
				'Fire Dance, Part 6.',
				'Mercantile training inside.',
				'Type: Book'
			},
			['bookskill_mercantile5'] = {
				'Fire Dance, Part 7.',
				'Advanced mercantile guide.',
				'Type: Book'
			},
			['BookSkill_Speechcraft1'] = {
				'Biography of the She-Wolf Queen.',
				'Speechcraft improvement guide.',
				'Type: Book'
			},
			['bookskill_speechcraft2'] = {
				'She-Wolf Queen, Book V.',
				'Enhances speechcraft skill.',
				'Type: Book'
			},
			['BookSkill_Speechcraft3'] = {
				'2920, Month of Seva.',
				'Speechcraft techniques inside.',
				'Type: Book'
			},
			['bookskill_speechcraft4'] = {
				'She-Wolf Queen, Book VII.',
				'Advanced speechcraft training.',
				'Type: Book'
			},
			['bookskill_speechcraft5'] = {
				'Vivec’s 36 Lessons, Sermon 27.',
				'Improves speechcraft ability.',
				'Type: Book'
			},
			['bookskill_hand to hand1'] = {
				'Baranath’s Prayers.',
				'Hand-to-hand combat guide.',
				'Type: Book'
			},
			['bookskill_hand to hand2'] = {
				'She-Wolf Queen, Book II.',
				'Hand-to-hand techniques described.',
				'Type: Book'
			},
			['bookskill_hand to hand3'] = {
				'Charwich-Konning, Volume 2.',
				'Advanced hand-to-hand training.',
				'Type: Book'
			},
			['bookskill_hand to hand4'] = {
				'Charwich-Konning, Volume 4.',
				'Master hand-to-hand tactics.',
				'Type: Book'
			},
			['bookskill_hand to hand5'] = {
				'Zoaraym the Master’s Story.',
				'Hand-to-hand combat wisdom.',
				'Type: Book'
			},
			['bk_LivesOfTheSaints'] = {
				'Lives of the Saints.',
				'Religious text about saints.',
				'Type: Book'
			},
			['bk_SaryonisSermons'] = {
				'Saryoni’s Sermons.',
				'Collection of religious sermons.',
				'Type: Book'
			},
			['bk_HomiliesOfBlessedAlmalexia'] = {
				'Homilies of Blessed Almalexia.',
				'Religious teachings collected.',
				'Type: Book'
			},
			['bk_PilgrimsPath'] = {
				'Pilgrim’s Path.',
				'Guide for religious pilgrimage.',
				'Type: Book'
			},
			['bk_HouseOfTroubles_o'] = {
				'House of Troubles.',
				'Book about trials and tribulations.',
				'Type: Book'
			},
			['bk_DoorsOfTheSpirit'] = {
				'Doors of the Spirit.',
				'Mystical text about spirits.',
				'Type: Book'
			},
			['bk_MysteriousAkavir'] = {
				'Mysterious Akavir.',
				'Tales of the distant land.',
				'Type: Book'
			},
			['bk_spiritofnirn'] = {
				'Spirit of Nirn, God of Mortals.',
				'Philosophical text about spirit.',
				'Type: Book'
			},
			['bk_vivecandmephala'] = {
				'Vivec and Mephala.',
				'Story about two divine beings.',
				'Type: Book'
			},
			['bk_istunondescosmology'] = {
				'A Rough Cosmology.',
				'Basic cosmic theory explained.',
				'Type: Book'
			},
			['bk_firmament'] = {
				'Firmament.',
				'Astrological guide inside.',
				'Type: Book'
			},
			['bk_manyfacesmissinggod'] = {
				'The Many Faces of the Missing God.',
				'Theological exploration.',
				'Type: Book'
			},
			['bk_frontierconquestaccommodat'] = {
				'Frontier, Conquest…',
				'Historical conquest narrative.',
				'Type: Book'
			},
			['bk_truenatureoforcs'] = {
				'True Nature of Orcs.',
				'Explores Orc culture and heritage.',
				'Type: Book'
			},
			['bk_varietiesoffaithintheempire'] = {
				'Varieties of Faith in the Empire.',
				'Overview of religious beliefs.',
				'Type: Book'
			},
			['bk_tamrielicreligions'] = {
				'Tamrielic Religions.',
				'Religious practices of Tamriel.',
				'Type: Book'
			},
			['bk_fivesongsofkingwulfharth'] = {
				'Five Songs of King Wulfharth.',
				'Epic poems about a king.',
				'Type: Book'
			},
			['bk_wherewereyoudragonbroke'] = {
				'Where Were You When the Dragon Came?',
				'Tales of dragon encounters.',
				'Type: Book'
			},
			['bk_nchunaksfireandfaith'] = {
				'Nchunak’s Fire and Faith.',
				'Spiritual journey described.',
				'Type: Book'
			},
			['bk_vampiresofwardenfell1'] = {
				'Vampires of Vvardenfell, Vol. I.',
				'Vampire lore and history.',
				'Type: Book'
			},
			['bk_reflectionsoncultworship...'] = {
				'Reflections on Cult Worship.',
				'Analysis of cult practices.',
				'Type: Book'
			},
			['bk_galerionthemystic'] = {
				'Galerion the Mystic.',
				'Biography of a famous mystic.',
				'Type: Book'
			},
			['bk_madnessofpelagius'] = {
				'Madness of Pelagius.',
				'Story of Pelagius’s downfall.',
				'Type: Book'
			},
			['bk_realbarenziah2'] = {
				'True Barenziah, Vol. II.',
				'Continued tale of Barenziah.',
				'Type: Book'
			},
			['bk_realbarenziah3'] = {
				'True Barenziah, Vol. III.',
				'Further Barenziah adventures.',
				'Type: Book'
			},
			['bk_realbarenziah4'] = {
				'True Barenziah, Vol. IV.',
				'Final chapters of Barenziah’s story.',
				'Type: Book'
			},
			['bk_OverviewOfGodsAndWorship'] = {
				'Overview of Gods and Worship.',
				'Guide to deities and rituals.',
				'Type: Book'
			},
			['bk_fragmentonartaeum'] = {
				'Fragment on Artaeum.',
				'Mystical text about Artaeum.',
				'Type: Book'
			},
			['bk_onoblivion'] = {
				'On Oblivion.',
				'Philosophical treatise on Oblivion.',
				'Type: Book'
			},
			['bk_InvocationOfAzura'] = {
				'Invocation of Azura.',
				'Rituals and prayers to Azura.',
				'Type: Book'
			},
			['bk_Mysticism'] = {
				'Mysticism.',
				'Study of mystical arts.',
				'Type: Book'
			},
			['bk_OriginOfTheMagesGuild'] = {
				'Origin of the Mages Guild.',
				'History of the Mages Guild.',
				'Type: Book'
			},
			['bk_specialfloraoftamriel'] = {
				'Special Flora of Tamriel.',
				'Guide to unique plants.',
				'Type: Book'
			},
			['bk_oldways'] = {
				'Old Ways.',
				'Traditional customs explained.',
				'Type: Book'
			},
			['bk_wildelves'] = {
				'Wild Elves.',
				'Culture of wild elf tribes.',
				'Type: Book'
			},
			['bk_PigChildren'] = {
				'Pig Children.',
				'Folk tales and legends.',
				'Type: Book'
			},
			['bk_redbookofriddles'] = {
				'Red Book of Riddles.',
				'Collection of challenging riddles.',
				'Type: Book'
			},
			['bk_yellowbookofriddles'] = {
				'Yellow Book of Riddles.',
				'More riddles to solve.',
				'Type: Book'
			},
			['bk_guylainesarchitecture'] = {
				'Guylaine’s Architecture.',
				'Architectural designs and history.',
				'Type: Book'
			},
			['bk_progressoftruth'] = {
				'Progression of Truth.',
				'Philosophical exploration of truth.',
				'Type: Book'
			},
			['bk_easternprovincesimpartial'] = {
				'Eastern Provinces Impartial.',
				'Neutral view of eastern provinces.',
				'Type: Book'
			},
			['bk_vampiresofvvardenfell2'] = {
				'Vampires of Vvardenfell, Vol. II.',
				'More vampire lore and tales.',
				'Type: Book'
			},
			['bk_gnisiseggmineledger'] = {
				'Gnisis Egg Mine Ledger.',
				'Records of egg mine operations.',
				'Type: Book'
			},
			['bk_fortpelagiadprisonerlog'] = {
				'Fort Pelagiad Prisoner Log.',
				'Log of fort prisoners.',
				'Type: Book'
			},
			['bk_MixedUnitTactics'] = {
				'Mixed Unit Tactics, Vol. 1.',
				'Military tactics guide.',
				'Type: Book'
			},
			['bk_gnisiseggminepass'] = {
				'Pass to Gnisis Egg Mine.',
				'Access permit for egg mine.',
				'Type: Book'
			},
			['bk_HouseOfTroubles_c'] = {
				'House of Troubles.',
				'Chronicles of trials and challenges.',
				'Type: Book'
			},
			['bk_truenoblescode'] = {
				'Noble Code of Honor.',
				'Code of conduct for nobles.',
				'Type: Book'
			},
			['bk_NGastaKvataKvakis_c'] = {
				'N’Gasta! Kvata! Kvakis!',
				'Mystical incantations collected.',
				'Type: Book'
			},
			['bk_legionsofthedead'] = {
				'Legions of the Dead.',
				'Tales of undead legions.',
				'Type: Book'
			},
			['bk_darkestdarkness'] = {
				'Darkest Darkness.',
				'Horror stories from the dark.',
				'Type: Book'
			},
			['bk_NGastaKvataKvakis_o'] = {
				'N’Gasta! Kvata! Kvakis!',
				'More mystical incantations.',
				'Type: Book'
			},
			['bk_hanginggardenswasten'] = {
				'Hanging Gardens Wasten.',
				'Description of hanging gardens.',
				'Type: Book'
			},
			['bk_itermerelsnotes'] = {
				'Itermerel’s Notes.',
				'Personal notes and observations.',
				'Type: Book'
			},
			['bk_tiramgadarscredentials'] = {
				'Tiram Gadar’s Credentials.',
				'Official credentials document.',
				'Type: Book'
			},
			['bk_corpsepreperation1_c'] = {
				'On Corpse Preparation, Vol. I.',
				'Guide to corpse preparation.',
				'Type: Book'
			},
			['bk_corpsepreperation1_o'] = {
				'On Corpse Preparation, Vol. I.',
				'Additional corpse prep details.',
				'Type: Book'
			},
			['bk_sharnslegionsofthedead'] = {
				'Sharn’s Legions of the Dead.',
				'Sharn’s account of undead legions.',
				'Type: Book'
			},
			['bk_SamarStarloversJournal'] = {
				'Samar Starlover’s Journal.',
				'Personal journal of Samar.',
				'Type: Book'
			},
			['bk_SpiritOfTheDaedra'] = {
				'Spirit of the Daedra.',
				'Study of Daedra spirits.',
				'Type: Book'
			},
			['bk_VagariesOfMagica'] = {
				'Vagaries of Magica.',
				'Unpredictable magic explained.',
				'Type: Book'
			},
			['bk_WatersOfOblivion'] = {
				'Waters of Oblivion.',
				'Explores mysteries of Oblivion waters.',
				'Type: Book'
			},
			['bk_LegendaryScourge'] = {
				'Legendary Scourge.',
				'Tales of legendary curses and plagues.',
				'Type: Book'
			},
			['bk_PostingOfTheHunt'] = {
				'Posting of the Hunt.',
				'Announcements and rules for hunts.',
				'Type: Book'
			},
			['bk_TalMarogKersResearches'] = {
				'Research notes by Tal Marog Kerah.',
				'Contains scholarly findings.',
				'Type: Research notes'
			},
			['bk_seniliasreport'] = {
				'Report authored by Senilius.',
				'Details on regional affairs.',
				'Type: Report'
			},
			['bk_graspingfortune'] = {
				'Essay on seizing fortune.',
				'Philosophical treatise.',
				'Type: Essay'
			},
			['bk_notefromsondaale'] = {
				'Note sent by Sondaale.',
				'Contains personal messages.',
				'Type: Note'
			},
			['bk_shishireport'] = {
				'Official report from Shishi.',
				'Military or exploratory data.',
				'Type: Report'
			},
			['bk_galtisguvronsnote'] = {
				'Letter from Galtis Guvron.',
				'Personal or official correspondence.',
				'Type: Letter'
			},
			['bk_sottildescodebook'] = {
				'Codebook used by Sottild.',
				'Encrypted communications guide.',
				'Type: Codebook'
			},
			["bk_NoteFromJ'Zhirr"] = {
				"Note from J'Zhirr.",
				'Contains urgent intelligence.',
				'Type: Note'
			},
			['bk_eastempirecompanyledger'] = {
				'Ledger of the East Empire Company.',
				'Financial and trade records.',
				'Type: Ledger'
			},
			['bk_nemindasorders'] = {
				'Orders issued by Neminda.',
				'Commands for subordinates.',
				'Type: Orders'
			},
			['bk_ordersforbivaleteneran'] = {
				'Letter addressed to Bival Teneran.',
				'Official instructions.',
				'Type: Letter'
			},
			['bk_treasuryreport'] = {
				'Treasury report document.',
				'Financial overview of funds.',
				'Type: Report'
			},
			['bk_treasuryorders'] = {
				'Treasury-issued orders.',
				'Directives for financial management.',
				'Type: Orders'
			},
			['bk_BlasphemousRevenants'] = {
				'Tome about blasphemous spirits.',
				'Dark magical lore.',
				'Type: Grimoire'
			},
			['bk_ConsolationsOfPrayer'] = {
				'Book of prayer consolations.',
				'Religious text for comfort.',
				'Type: Religious text'
			},
			['bk_BookDawnAndDusk'] = {
				'Philosophical book on cycles.',
				'Explores dawn and dusk symbolism.',
				'Type: Philosophy book'
			},
			['bk_CantatasOfVivec'] = {
				"Collection of Vivec's cantatas.",
				'Musical and poetic works.',
				'Type: Musical text'
			},
			['bk_Anticipations'] = {
				'Text on foreseeing events.',
				'Prophetic or philosophical content.',
				'Type: Prophecy text'
			},
			['bk_AncestorsAndTheDunmer'] = {
				'Study of Dunmer ancestry.',
				'Cultural and historical analysis.',
				'Type: Historical text'
			},
			['bk_AedraAndDaedra'] = {
				'Comparison of Aedra and Daedra.',
				'Divine beings lore.',
				'Type: Lore book'
			},
			['bk_AnnotatedAnuad'] = {
				'Annotated version of Anuad.',
				'Commentary on ancient text.',
				'Type: Annotated text'
			},
			['bk_ChildrensAnuad'] = {
				'Simplified Anuad for children.',
				'Educational version of lore.',
				"Type: Children's book"
			},
			['bk_ArcturianHeresy'] = {
				'Text on Arcturian heresy.',
				'Controversial religious doctrines.',
				'Type: Religious text'
			},
			['bk_ChangedOnes'] = {
				'Account of transformed beings.',
				'Lore on metamorphosis.',
				'Type: Lore book'
			},
			['bk_ChildrenOfTheSky'] = {
				'Story of the Sky Children.',
				'Mythological narrative.',
				'Type: Mythology book'
			},
			['bk_AntecedantsDwemerLaw'] = {
				'History of Dwemer legal system.',
				'Legal and cultural study.',
				'Type: Legal text'
			},
			['bk_ChroniclesNchuleft'] = {
				'Chronicles of Nchuleft region.',
				'Historical accounts.',
				'Type: Chronicles'
			},
			['bk_BiographyBarenziah1'] = {
				"Volume 1 of Barenziah's biography.",
				'Biographical details, early life.',
				'Type: Biography'
			},
			['bk_BiographyBarenziah2'] = {
				"Volume 2 of Barenziah's biography.",
				'Continued biographical narrative.',
				'Type: Biography'
			},
			['bk_BiographyBarenziah3'] = {
				"Volume 3 of Barenziah's biography.",
				'Later years and legacy.',
				'Type: Biography'
			},
			['bk_BriefHistoryEmpire1'] = {
				"Volume 1: Empire's early history.",
				'Historical overview.',
				'Type: History book'
			},
			['bk_BriefHistoryEmpire2'] = {
				"Volume 2: Empire's development.",
				'Continued historical narrative.',
				'Type: History book'
			},
			['bk_BriefHistoryEmpire3'] = {
				"Volume 3: Empire's conflicts.",
				'Wars and alliances history.',
				'Type: History book'
			},
			['bk_BriefHistoryEmpire4'] = {
				"Volume 4: Empire's decline.",
				'Late period historical analysis.',
				'Type: History book'
			},
			['bk_BrothersOfDarkness'] = {
				'Text on the Brothers of Darkness.',
				'Cult and their doctrines.',
				'Type: Cult lore'
			},
			['bk_BlackGlove'] = {
				'Story of the Black Glove.',
				'Dark artifact legend.',
				'Type: Legend'
			},
			['bk_BlueBookOfRiddles'] = {
				'Collection of riddles.',
				'Puzzles and enigmas.',
				'Type: Puzzle book'
			},
			['bk_BoethiahPillowBook'] = {
				'Intimate tales about Boethiah.',
				'Mythical and erotic stories.',
				'Type: Mythology book'
			},
			['bk_a1_1_directionscaiuscosades'] = {
				'Directions to Caius Cosades.',
				'Travel instructions.',
				'Type: Directions'
			},
			['bk_a1_2_antabolistocosades'] = {
				'Message from Haspat to Cosades.',
				'Personal communication.',
				'Type: Message'
			},
			['bk_a1_2_introtocadiusus'] = {
				'Letter to Senilius Cadiusus.',
				'Official or personal letter.',
				'Type: Letter'
			},
			['bk_a1_4_sharnsnotes'] = {
				'Notes on the Nerevarine cult.',
				'Research on religious group.',
				'Type: Research notes'
			},
			['bk_a1_v_vivecinformants'] = {
				'Tasks in Vivec from Kay.',
				'Quests and missions list.',
				'Type: Quest list'
			},
			['bk_A1_7_HuleeyaInformant'] = {
				'Info from Huleeya informant.',
				'Intelligence report.',
				'Type: Intelligence'
			},
			['bk_BookOfDaedra'] = {
				'Comprehensive Daedra guide.',
				'Lore on Daedric princes.',
				'Type: Lore book'
			},
			['bk_ArcanaRestored'] = {
				'Guide to restored arcana.',
				'Magic and mystical knowledge.',
				'Type: Magic guide'
			},
			['bk_BookOfLifeAndService'] = {
				'Philosophy of life and duty.',
				'Moral and ethical teachings.',
				'Type: Philosophy book'
			},
			['bk_BookOfRestAndEndings'] = {
				'Philosophy on rest and endings.',
				'Contemplation of finality.',
				'Type: Philosophy book'
			},
			['bk_AffairsOfWizards'] = {
				'Guide to wizard activities.',
				'Details on magical practices.',
				'Type: Magic guide'
			},
			['bk_CalderaRecordBook1'] = {
				"Caldera's official record book.",
				'Accounting and trade logs.',
				'Type: Ledger'
			},
			['bk_CalderaRecordBook2'] = {
				'Secret Caldera record book.',
				'Hidden financial data.',
				'Type: Ledger'
			},
			['bk_AuraneFrernis1'] = {
				"Aurane Frernis's recipe book.",
				'Collection of culinary recipes.',
				'Type: Cookbook'
			},
			['bk_auranefrernis2'] = {
				'Second volume of Frernis recipes.',
				'More culinary delights.',
				'Type: Cookbook'
			},
			['bk_auranefrernis3'] = {
				'Third volume of Frernis recipes.',
				'Advanced cooking techniques.',
				'Type: Cookbook'
			},
			['bk_6thhouseravings'] = {
				'Scribblings from the 6th House.',
				'Mystical and chaotic writings.',
				'Type: Scribblings'
			},
			['bk_CalderaMiningContract'] = {
				'Mining contract for Caldera.',
				'Legal mining agreements.',
				'Type: Contract'
			},
			['bk_ABCs'] = {
				'Basic primer for варваров.',
				'Alphabet and reading guide.',
				'Type: Primer'
			},
			['bk_a1_11_zainsubaninotes'] = {
				'Notes compiled by Zainsubani.',
				'Research or personal logs.',
				'Type: Notes'
			},
			['note to hrisskar'] = {
				'Short note addressed to Hrisskar.',
				'Contains brief instructions.',
				'Type: Note'
			},
			['chargen statssheet'] = {
				'Character stats documentation.',
				'Details on abilities and skills.',
				'Type: Stats sheet'
			},
			['bk_notetocalderaslaves'] = {
				'Notice for Caldera slaves.',
				'Official slave regulations.',
				'Type: Notice'
			},
			['bk_notetoinorra'] = {
				'Personal note to Inorra.',
				'Contains private messages.',
				'Type: Note'
			},
			['bk_notetocalderaguard'] = {
				'Address to Caldera guards.',
				'Orders or warnings for guards.',
				'Type: Address'
			},
			['bk_notetocalderamages'] = {
				'Message to Caldera mages.',
				'Instructions for magical personnel.',
				'Type: Message'
			},
			['bk_falanaamonote'] = {
				'Note directed to Falanaamo.',
				'Personal or official communication.',
				'Type: Note'
			},
			['bk_notetovalvius'] = {
				'Notification for Valvius.',
				'Official update or warning.',
				'Type: Notification'
			},
			['bk_notefromirgola'] = {
				'Letter from Irgola to recipient.',
				'Personal correspondence.',
				'Type: Letter'
			},
			['bk_notefrombildren'] = {
				'Note from Bildren to reader.',
				'Short message or warning.',
				'Type: Note'
			},
			['bk_notesoldout'] = {
				'Notice about sold-out potions.',
				'Inventory status update.',
				'Type: Notice'
			},
			['bk_notefromferele'] = {
				'Message from Ferele to recipient.',
				'Contains important intel.',
				'Type: Message'
			},
			['bk_Dren_Hlevala_note'] = {
				'Note from Dren to Hlevala.',
				'Personal or mission-related.',
				'Type: Note'
			},
			['bk_Dren_shipping_log'] = {
				"Log of Dren's shipping activities.",
				'Trade and cargo records.',
				'Type: Log'
			},
			['bk_saryonisermonsmanuscript'] = {
				"Manuscript of Saryoni's sermons.",
				'Religious teachings and speeches.',
				'Type: Manuscript'
			},
			['bk_messagefrommasteraryon'] = {
				'Message from Master Arion.',
				'Official or mystical communication.',
				'Type: Message'
			},
			['bk_responsefromdivaythfyr'] = {
				'Response letter from Divayth Fyr.',
				"Wise elder's reply.",
				'Type: Letter'
			},
			['bk_honorthieves'] = {
				"Treatise on thieves' honor code.",
				'Ethics of the criminal underworld.',
				'Type: Treatise'
			},
			['bk_redbook426'] = {
				'Red Book from 426 Era.',
				'Historical or magical tome.',
				'Type: Book'
			},
			['bk_yellowbook426'] = {
				'Yellow Book from 426 Era.',
				'Complementary to Red Book.',
				'Type: Book'
			},
			['bk_BrownBook426'] = {
				'Brown Book from 426 Era.',
				'Third part of Era trilogy.',
				'Type: Book'
			},
			['bk_orderfrommollismo'] = {
				'Order issued by Mollismo.',
				'Commands or directives.',
				'Type: Order'
			},
			['bk_BlightPotionNotice'] = {
				'Notice about blight potions.',
				'Information on healing potions.',
				'Type: Notice'
			},
			['bk_propertyofjolda'] = {
				"Item marked as Jolda's property.",
				'Ownership declaration.',
				'Type: Declaration'
			},
			['bk_joldanote'] = {
				'Hastily written note by Jolda.',
				'Urgent or personal message.',
				'Type: Note'
			},
			['bk_eggorders'] = {
				'Set of egg-related orders.',
				'Instructions or commands.',
				'Type: Orders'
			},
			['bk_notefromradras'] = {
				'Note sent by Radras.',
				'Personal or mission-critical.',
				'Type: Note'
			},
			['bk_thesevencurses'] = {
				'Text detailing seven curses.',
				'Dark magical lore.',
				'Type: Grimoire'
			},
			['bk_thelostprophecy'] = {
				'Lost prophecy manuscript.',
				'Foretelling ancient events.',
				'Type: Prophecy'
			},
			["bk_kagrenac'stools"] = {
				'Tools used by Kagrenac.',
				'Artifacts of divine power.',
				'Type: Artifacts'
			},
			['bk_NoteToAmaya'] = {
				'Personal note addressed to Amaya.',
				'Contains private intel.',
				'Type: Note'
			},
			['bk_vivecs_plan'] = {
				"Vivec's strategic plan.",
				'Tactics to defeat Dagoth Ur.',
				'Type: Strategy plan'
			},
			['bk_vivec_murders'] = {
				'Account of murders at Red Mountain.',
				'Dark historical events.',
				'Type: Chronicle'
			},
			['bk_saryoni_note'] = {
				'Note from Archcanonic Saryoni.',
				'Religious or mystical content.',
				'Type: Note'
			},
			['bk_vivec_no_murder'] = {
				'Account of battle at Red Mountain.',
				'Historical battle narrative.',
				'Type: Battle account'
			},
			['bk_Dagoth_Urs_Plans'] = {
				"Dagoth Ur's strategic plans.",
				'Evil schemes and tactics.',
				'Type: Strategy plan'
			},
			['bk_notefromberwen'] = {
				'Letter from Berwen to recipient.',
				'Personal or official letter.',
				'Type: Letter'
			},
			['bk_varoorders'] = {
				'Delivery orders by Varo.',
				'Logistics and supply instructions.',
				'Type: Orders'
			},
			['bk_storagenotice'] = {
				'Notice regarding storage.',
				'Rules or status update.',
				'Type: Notice'
			},
			['bk_notetomenus'] = {
				'Note directed to Menus.',
				'Personal or mission-related.',
				'Type: Note'
			},
			['bk_notefrombugrol'] = {
				'Note from Bugrol.',
				'Contains personal messages.',
				'Type: Note'
			},
			['bk_notefrombashuk'] = {
				'Note from Bashuk.',
				'Personal correspondence.',
				'Type: Note'
			},
			['bk_notebyaryon'] = {
				"Arion's notes.",
				'Collection of writings by Arion.',
				'Type: Notes'
			},
			['bk_BeramJournal1'] = {
				"Beram's journal, entry 1.",
				"First entry in Beram's diary.",
				'Type: Journal'
			},
			['bk_BeramJournal2'] = {
				"Beram's journal, entry 2.",
				"Second entry in Beram's diary.",
				'Type: Journal'
			},
			['bk_BeramJournal3'] = {
				"Beram's journal, entry 3.",
				"Third entry in Beram's diary.",
				'Type: Journal'
			},
			['bk_BeramJournal4'] = {
				"Beram's journal, entry 4.",
				"Fourth entry in Beram's diary.",
				'Type: Journal'
			},
			['bk_BeramJournal5'] = {
				"Beram's journal, entry 5.",
				"Fifth entry in Beram's diary.",
				'Type: Journal'
			},
			['bk_impmuseumwelcome'] = {
				'Invitation to the Imperial Museum.',
				'Official invitation document.',
				'Type: Invitation'
			},
			['bk_dwemermuseumwelcome'] = {
				'Invitation to the Dwemer Museum.',
				'Official invitation to Dwemer exhibit.',
				'Type: Invitation'
			},
			['bk_pillowinvoice'] = {
				'Invoice for a pillow.',
				'Financial document for a pillow purchase.',
				'Type: Invoice'
			},
			['bk_ravilamemorial'] = {
				'Memorial to Ravila.',
				'Commemorative text in memory of Ravila.',
				'Type: Memorial'
			},
			['bk_fishystick'] = {
				"Boatman's guide to fish snacks.",
				'Cooking guide by a boatman.',
				'Type: Guide'
			},
			["bk_kagrenac'splans_excl"] = {
				"Kagrenac's project plans.",
				'Detailed plans by Kagrenac.',
				'Type: Plans'
			},
			['bk_miungei'] = {
				'Letter from Trazami.',
				'Correspondence from Trazami.',
				'Type: Letter'
			},
			['bk_ynglingledger'] = {
				"Yngling's account book.",
				"Ledger for Yngling's transactions.",
				'Type: Ledger'
			},
			['bk_ynglingletter'] = {
				'Letter from Yngling.',
				'Correspondence from Yngling.',
				'Type: Letter'
			},
			['bk_indreledeed'] = {
				"Deed for Indrel's house.",
				'Legal document for house ownership.',
				'Type: Deed'
			},
			['bk_BriefHistoryEmpire1_oh'] = {
				'History of Odral Empire, part 1.',
				'First part of empire history.',
				'Type: History'
			},
			['bk_BriefHistoryEmpire2_oh'] = {
				'History of Odral Empire, part 2.',
				'Second part of empire history.',
				'Type: History'
			},
			['bk_BriefHistoryEmpire3_oh'] = {
				'History of Odral Empire, part 3.',
				'Third part of empire history.',
				'Type: History'
			},
			['bk_BriefHistoryEmpire4_oh'] = {
				'History of Odral Empire, part 4.',
				'Fourth part of empire history.',
				'Type: History'
			},
			['bk_dispelrecipe_tgca'] = {
				'Recipe for Dispel Potion.',
				'Instructions for making a dispel potion.',
				'Type: Recipe'
			},
			['bk_a1_1_caiuspackage'] = {
				'Package for Caius Cosades.',
				'Special delivery for Caius.',
				'Type: Package'
			},
			['bk_Ashland_Hymns'] = {
				'Hymns of Ashland.',
				'Collection of religious songs.',
				'Type: Hymns'
			},
			['bk_words_of_the_wind'] = {
				'Words of the Wind.',
				'Poetic text about the wind.',
				'Type: Poetry'
			},
			['bk_five_far_stars'] = {
				'Five Far Stars.',
				'Text about distant stars.',
				'Type: Text'
			},
			['bk_provinces_of_tamriel'] = {
				'Provinces of Tamriel.',
				'Information about Tamriel provinces.',
				'Type: Guide'
			},
			["bk_galur_rithari's_papers"] = {
				'Papers of Galur Rithari.',
				"Collection of Galur's documents.",
				'Type: Papers'
			},
			["bk_kagrenac'sjournal_excl"] = {
				"Kagrenac's personal journal.",
				'Private writings of Kagrenac.',
				'Type: Journal'
			},
			['bk_notes-kagouti mating habits'] = {
				'Notes on Kagouti mating habits.',
				'Study of Kagouti behavior.',
				'Type: Notes'
			},
			['bk_notefromnelos'] = {
				'Note from Nelos.',
				'Message written by Nelos.',
				'Type: Note'
			},
			['bk_notefromernil'] = {
				'Note from Ernil.',
				'Message written by Ernil.',
				'Type: Note'
			},
			['bk_enamor'] = {
				'Note to Salinu Sareti.',
				'Personal message for Salinu.',
				'Type: Note'
			},
			['bk_wordsclanmother'] = {
				'Words of Clan Mother Anissy.',
				'Speeches by Clan Mother.',
				'Type: Speeches'
			},
			['bk_corpsepreperation2_c'] = {
				'Guide to body preparation, vol. II.',
				'Second volume on body preparation.',
				'Type: Guide'
			},
			['bk_corpsepreperation3_c'] = {
				'Guide to body preparation, vol. III.',
				'Third volume on body preparation.',
				'Type: Guide'
			},
			['bk_ArkayTheEnemy'] = {
				'Arkay — Our Enemy.',
				'Text discussing Arkay as an enemy.',
				'Type: Text'
			},
			['bk_poisonsong1'] = {
				'Song of Poison, part I.',
				'First part of poison song.',
				'Type: Song'
			},
			['bk_poisonsong2'] = {
				'Song of Poison, part II.',
				'Second part of poison song.',
				'Type: Song'
			},
			['bk_poisonsong3'] = {
				'Song of Poison, part III.',
				'Third part of poison song.',
				'Type: Song'
			},
			['bk_poisonsong4'] = {
				'Song of Poison, part IV.',
				'Fourth part of poison song.',
				'Type: Song'
			},
			['bk_poisonsong5'] = {
				'Song of Poison, part V.',
				'Fifth part of poison song.',
				'Type: Song'
			},
			['bk_poisonsong6'] = {
				'Song of Poison, part VI.',
				'Sixth part of poison song.',
				'Type: Song'
			},
			['bk_poisonsong7'] = {
				'Song of Poison, part VII.',
				'Seventh part of poison song.',
				'Type: Song'
			},
			['bk_Confessions'] = {
				'Confessions of a Skooma Eater.',
				'Confessions about skooma addiction.',
				'Type: Confessions'
			},
			['bk_hospitality_papers'] = {
				'Guest hospitality papers.',
				'Documents for guest hospitality.',
				'Type: Papers'
			},
			["bk_uleni's_papers"] = {
				"Uleni's papers on wraithlessness.",
				'Documents about wraith status.',
				'Type: Papers'
			},
			['bk_redorancookingsecrets'] = {
				'Redoran cooking secrets.',
				'Collection of Redoran culinary recipes.',
				'Type: Cookbook'
			},
			['bk_widowdeed'] = {
				"Deed for Widow Vabdas's land.",
				'Legal document for land ownership.',
				'Type: Deed'
			},
			['bk_guide_to_vvardenfell'] = {
				'Guide to Vvardenfell.',
				'Travel guide for Vvardenfell region.',
				'Type: Guide'
			},
			['bk_guide_to_vivec'] = {
				'Guide to Vivec.',
				'Travel guide for Vivec city.',
				'Type: Guide'
			},
			['bk_guide_to_balmora'] = {
				'Guide to Balmora.',
				'Travel guide for Balmora town.',
				'Type: Guide'
			},
			['bk_guide_to_ald_ruhn'] = {
				'Guide to Ald Ruhn.',
				'Travel guide for Ald Ruhn settlement.',
				'Type: Guide'
			},
			['bk_guide_to_sadrithmora'] = {
				'Guide to Sadrith Mora.',
				'Travel guide for Sadrith Mora town.',
				'Type: Guide'
			},
			['text_paper_roll_01'] = {
				'Rolled up paper.',
				'Scrolled document, contents unknown.',
				'Type: Document'
			},
			['bk_seydaneentaxrecord'] = {
				'Seydanee tax record.',
				'Official tax documentation.',
				'Type: Tax Record'
			},
			['bk_a1_1_packagedecoded'] = {
				'Decoded package contents.',
				'Deciphered contents of a package.',
				'Type: Decoded Message'
			},
			['bk_a2_1_sevenvisions'] = {
				'Seven Visions text.',
				'Document detailing seven visions.',
				'Type: Text'
			},
			['bk_a2_1_thestranger'] = {
				'Text about The Stranger.',
				'Story or report about a mysterious stranger.',
				'Type: Story'
			},
			['sc_hellfire'] = {
				'Scroll of Hellfire.',
				'Magic scroll summoning hellfire.',
				'Type: Scroll'
			},
			['sc_ninthbarrier'] = {
				'Scroll of the Ninth Barrier.',
				'Magic scroll creating a barrier.',
				'Type: Scroll'
			},
			['sc_restoration'] = {
				'Scroll of Restoration.',
				'Magic scroll for healing and restoration.',
				'Type: Scroll'
			},
			['sc_blackstorm'] = {
				'Scroll of Black Storm.',
				'Magic scroll summoning a black storm.',
				'Type: Scroll'
			},
			['sc_balefulsuffering'] = {
				'Scroll of Baleful Suffering.',
				'Magic scroll causing suffering.',
				'Type: Scroll'
			},
			['sc_bloodthief'] = {
				'Scroll of Blood Thief.',
				'Magic scroll draining blood.',
				'Type: Scroll'
			},
			['sc_mindfeeder'] = {
				'Scroll of Mind Feeder.',
				'Magic scroll feeding on minds.',
				'Type: Scroll'
			},
			['sc_psychicprison'] = {
				'Scroll of Psychic Prison.',
				'Magic scroll trapping minds.',
				'Type: Scroll'
			},
			['sc_lesserdomination'] = {
				'Scroll of Lesser Domination.',
				'Magic scroll for minor mind control.',
				'Type: Scroll'
			},
			['sc_greaterdomination'] = {
				'Scroll of Greater Domination.',
				'Magic scroll for strong mind control.',
				'Type: Scroll'
			},
			['sc_supremedomination'] = {
				'Scroll of Supreme Domination.',
				'Magic scroll for ultimate mind control.',
				'Type: Scroll'
			},
			['sc_argentglow'] = {
				'Scroll of Argent Glow.',
				'Magic scroll creating silver glow.',
				'Type: Scroll'
			},
			['sc_redsloth'] = {
				'Scroll of Red Sloth.',
				'Magic scroll inducing red sloth effect.',
				'Type: Scroll'
			},
			['sc_reddeath'] = {
				'Scroll of Red Death.',
				'Magic scroll causing red death effect.',
				'Type: Scroll'
			},
			['sc_redmind'] = {
				'Scroll of Red Mind.',
				'Magic scroll affecting the mind with red energy.',
				'Type: Scroll'
			},
			['sc_redfate'] = {
				'Scroll of Red Fate.',
				'Magic scroll influencing fate with red power.',
				'Type: Scroll'
			},
			['sc_redscorn'] = {
				'Scroll of Red Scorn.',
				'Magic scroll inflicting red scorn effect.',
				'Type: Scroll'
			},
			['sc_redweakness'] = {
				'Scroll of Red Weakness.',
				'Magic scroll causing red weakness.',
				'Type: Scroll'
			},
			['sc_reddespair'] = {
				'Scroll of Red Despair.',
				'Magic scroll inducing red despair.',
				'Type: Scroll'
			},
			['sc_manarape'] = {
				'Scroll of Mana Rape.',
				'Magic scroll draining mana.',
				'Type: Scroll'
			},
			['sc_elevramssty'] = {
				"Scroll of Elevram's Sty.",
				"Magic scroll related to Elevram's sty.",
				'Type: Scroll'
			},
			['sc_fadersleadenflesh'] = {
				"Scroll of Fader's Leaden Flesh.",
				'Magic scroll weighing down flesh.',
				'Type: Scroll'
			},
			['sc_dedresmasterfuleye'] = {
				"Scroll of Dedres's Masterful Eye.",
				'Magic scroll enhancing vision.',
				'Type: Scroll'
			},
			['sc_golnaraseyemaze'] = {
				"Scroll of Golnara's Eye Maze.",
				'Magic scroll creating a vision maze.',
				'Type: Scroll'
			},
			['sc_didalasknack'] = {
				"Scroll of Didala's Knack.",
				'Magic scroll granting a special knack.',
				'Type: Scroll'
			},
			['sc_daerirsmiracle'] = {
				"Scroll of Daerir's Miracle.",
				'Magic scroll performing a miracle.',
				'Type: Scroll'
			},
			['sc_daydenespanacea'] = {
				"Scroll of Dayden's Panacea.",
				'Magic scroll providing a universal cure.',
				'Type: Scroll'
			},
			['sc_salensvivication'] = {
				"Scroll of Salen's Vivication.",
				'Magic scroll reviving life force.',
				'Type: Scroll'
			},
			['sc_vaerminaspromise'] = {
				"Scroll of Vaermina's Promise.",
				"Magic scroll bearing Vaermina's promise.",
				'Type: Scroll'
			},
			['sc_blackdeath'] = {
				'Scroll of Black Death.',
				'Magic scroll causing black death effect.',
				'Type: Scroll'
			},
			['sc_blackdespair'] = {
				'Scroll of Black Despair.',
				'Magic scroll inducing black despair.',
				'Type: Scroll'
			},
			['sc_blackfate'] = {
				'Scroll of Black Fate.',
				'Magic scroll influencing fate with black power.',
				'Type: Scroll'
			},
			['sc_blackmind'] = {
				'Scroll of Black Mind.',
				'Magic scroll affecting the mind with black energy.',
				'Type: Scroll'
			},
			['sc_blackscorn'] = {
				'Scroll of Black Scorn.',
				'Magic scroll inflicting black scorn effect.',
				'Type: Scroll'
			},
			['sc_blacksloth'] = {
				'Scroll of Black Sloth.',
				'Magic scroll causing black sloth effect.',
				'Type: Scroll'
			},
			['sc_blackweakness'] = {
				'Scroll of Black Weakness.',
				'Magic scroll causing black weakness.',
				'Type: Scroll'
			},
			['sc_tendilstrembling'] = {
				"Scroll of Tendil's Trembling.",
				'Magic scroll causing trembling effect.',
				'Type: Scroll'
			},
			['sc_feldramstrepidation'] = {
				"Scroll of Feldram's Trepidation.",
				'Magic scroll inducing fear.',
				'Type: Scroll'
			},
			['sc_reynosbeastfinder'] = {
				"Scroll of Reynos's Beast Finder.",
				'Magic scroll locating beasts.',
				'Type: Scroll'
			},
			['sc_mageseye'] = {
				"Scroll of Mage's Eye.",
				'Magic scroll enhancing magical vision.',
				'Type: Scroll'
			},
			['sc_tevralshawkshaw'] = {
				"Scroll of Tevral's Hawkshaw.",
				'Magic scroll granting hawk-like vision.',
				'Type: Scroll'
			},
			['sc_radrenesspellbreaker'] = {
				"Scroll of Radrene's Spellbreaker.",
				'Magic scroll dispelling enchantments.',
				'Type: Scroll'
			},
			['sc_alvusiaswarping'] = {
				"Scroll of Alvusia's Distortion.",
				'Alters reality around the caster.',
				'Type: Scroll'
			},
			['sc_corruptarcanix'] = {
				'Scroll of Arcanish Corruption.',
				'Inflicts arcane corruption.',
				'Type: Scroll'
			},
			['sc_greydeath'] = {
				'Scroll of Grey Death.',
				'Brings grey doom upon foes.',
				'Type: Scroll'
			},
			['sc_greydespair'] = {
				'Scroll of Grey Despair.',
				'Instills deep despair.',
				'Type: Scroll'
			},
			['sc_greyfate'] = {
				'Scroll of Grey Fate.',
				'Seals fate with grey doom.',
				'Type: Scroll'
			},
			['sc_greymind'] = {
				'Scroll of Grey Mind.',
				'Clouds the mind with grey haze.',
				'Type: Scroll'
			},
			['sc_greyscorn'] = {
				'Scroll of Grey Scorn.',
				'Inflicts scorn and despair.',
				'Type: Scroll'
			},
			['sc_greysloth'] = {
				'Scroll of Grey Sloth.',
				'Slows actions with grey lethargy.',
				'Type: Scroll'
			},
			['sc_greyweakness'] = {
				'Scroll of Grey Weakness.',
				'Weakens target with grey curse.',
				'Type: Scroll'
			},
			['sc_ulmjuicedasfeather'] = {
				"Scroll of Ulms's Feather.",
				"Summons power of Ulms' feather.",
				'Type: Scroll'
			},
			['sc_taldamsscorcher'] = {
				"Scroll of Taldam's Scorcher.",
				'Scorches enemies with fire.',
				'Type: Scroll'
			},
			['sc_elementalburstfire'] = {
				'Scroll of Elemental Burst: Fire.',
				'Releases burst of fire energy.',
				'Type: Scroll'
			},
			['sc_selisfieryward'] = {
				"Scroll of Selis's Fiery Ward.",
				'Creates fiery protective barrier.',
				'Type: Scroll'
			},
			['sc_dawnsprite'] = {
				'Scroll of Dawn Sprite.',
				'Summons sprite of dawn light.',
				'Type: Scroll'
			},
			['sc_bloodfire'] = {
				'Scroll of Burning Blood.',
				'Ignites blood with fiery power.',
				'Type: Scroll'
			},
			['sc_vigor'] = {
				'Scroll of Vigor.',
				'Boosts physical strength.',
				'Type: Scroll'
			},
			['sc_vitality'] = {
				'Scroll of Vitality.',
				'Restores life energy.',
				'Type: Scroll'
			},
			['sc_insight'] = {
				'Scroll of Insight.',
				'Enhances mental clarity.',
				'Type: Scroll'
			},
			['sc_gamblersprayer'] = {
				"Scroll of Gambler's Prayer.",
				'Brings luck in games of chance.',
				'Type: Scroll'
			},
			['sc_heartwise'] = {
				'Scroll of Heartwise Wisdom.',
				'Enhances emotional insight.',
				'Type: Scroll'
			},
			['sc_celerity'] = {
				'Scroll of Celerity.',
				'Increases movement speed.',
				'Type: Scroll'
			},
			['sc_mageweal'] = {
				'Scroll of Magical Weal.',
				'Enhances magical potency.',
				'Type: Scroll'
			},
			['sc_savagemight'] = {
				'Scroll of Savage Might.',
				'Grants primal strength.',
				'Type: Scroll'
			},
			['sc_oathfast'] = {
				'Scroll of Oathfast Vow.',
				'Strengthens клятвенные vows.',
				'Type: Scroll'
			},
			['sc_gonarsgoad'] = {
				"Scroll of Gonar's Goad.",
				'Prods target into action.',
				'Type: Scroll'
			},
			['sc_mondensinstigator'] = {
				"Scroll of Monden's Instigator.",
				'Stirs conflict and strife.',
				'Type: Scroll'
			},
			['sc_illneasbreath'] = {
				"Scroll of Illnei's Breath.",
				'Breathes chill of Illnei.',
				'Type: Scroll'
			},
			['sc_radiyasicymask'] = {
				"Scroll of Radiya's Ice Mask.",
				'Covers face with icy mask.',
				'Type: Scroll'
			},
			['sc_brevasavertedeyes'] = {
				"Scroll of Breva's Averted Eyes.",
				'Hides presence from view.',
				'Type: Scroll'
			},
			['sc_tinurshoptoad'] = {
				"Scroll of Tinur's Toad.",
				'Transforms into toad form.',
				'Type: Scroll'
			},
			['sc_uthshandofheaven'] = {
				"Scroll of Uth's Heavenly Hand.",
				'Channels divine power.',
				'Type: Scroll'
			},
			['sc_princeovsbrightball'] = {
				"Scroll of Prince Ova's Bright Ball.",
				'Summons glowing orbal light.',
				'Type: Scroll'
			},
			['sc_lordmhasvengeance'] = {
				"Scroll of Lord Mhas's Vengeance.",
				'Calls upon vengeful power.',
				'Type: Scroll'
			},
			['sc_elementalburstfrost'] = {
				'Scroll of Elemental Burst: Frost.',
				'Releases burst of frost energy.',
				'Type: Scroll'
			},
			['sc_windform'] = {
				'Scroll of Wind Form.',
				'Transforms into gaseous wind.',
				'Type: Scroll'
			},
			['sc_stormward'] = {
				'Scroll of Storm Ward.',
				'Protects against storm magic.',
				'Type: Scroll'
			},
			['sc_purityofbody'] = {
				'Scroll of Purity of Body.',
				'Cleanses body of impurities.',
				'Type: Scroll'
			},
			['sc_warriorsblessing'] = {
				"Scroll of Warrior's Blessing.",
				'Blesses warrior with strength.',
				'Type: Scroll'
			},
			['sc_galmsesseal'] = {
				"Scroll of Galmes's Seal.",
				'Seals target with ancient mark.',
				'Type: Scroll'
			},
			['sc_mark'] = {
				'Scroll of Marking Seal.',
				'Marks target for detection.',
				'Type: Scroll'
			},
			['sc_llirosglowingeye'] = {
				"Scroll of Lliros's Glowing Eye.",
				'Summons glowing eye of Lliros.',
				'Type: Scroll'
			},
			['sc_ondusisunhinging'] = {
				"Scroll of Ondusi's Unhinging.",
				'Unhinges locks and seals.',
				'Type: Scroll'
			},
			['sc_sertisesporphyry'] = {
				"Scroll of Sertise's Porphyry.",
				'Summons stone power of porphyry.',
				'Type: Scroll'
			},
			['sc_toususabidingbeast'] = {
				"Scroll of Tousi's Abiding Beast.",
				'Summons loyal beast spirit.',
				'Type: Scroll'
			},
			['sc_telvinscourage'] = {
				"Scroll of Telvin's Courage.",
				'Boosts bravery and valor.',
				'Type: Scroll'
			},
			['sc_leaguestep'] = {
				'Scroll of League Step.',
				'Enhances walking speed.',
				'Type: Scroll'
			},
			['sc_tranasasspelltrap'] = {
				"Scroll of Tranasa's Spell Trap.",
				'Traps incoming magical spells.',
				'Type: Scroll'
			},
			['sc_flameguard'] = {
				'Scroll of Flame Guard.',
				'Creates fiery protective shield.',
				'Type: Scroll'
			},
			['sc_shockguard'] = {
				'Scroll of the Electric Sentinel.',
				'Summons a guardian entity with electric powers.',
				'Type: Scroll'
			},
			['sc_healing'] = {
				'Healing scroll.',
				'Restores health to the target.',
				'Type: Scroll'
			},
			['sc_firstbarrier'] = {
				'Scroll of the First Barrier.',
				'Creates a protective barrier.',
				'Type: Scroll'
			},
			['sc_secondbarrier'] = {
				'Scroll of the Second Barrier.',
				'Enhances the protective barrier.',
				'Type: Scroll'
			},
			['sc_thirdbarrier'] = {
				'Scroll of the Third Barrier.',
				'Further strengthens the protective barrier.',
				'Type: Scroll'
			},
			['sc_fourthbarrier'] = {
				'Scroll of the Fourth Barrier.',
				'Adds an advanced layer to the barrier.',
				'Type: Scroll'
			},
			['sc_fifthbarrier'] = {
				'Scroll of the Fifth Barrier.',
				'Enhances barrier with superior magic.',
				'Type: Scroll'
			},
			['sc_sixthbarrier'] = {
				'Scroll of the Sixth Barrier.',
				'Provides ultimate barrier protection.',
				'Type: Scroll'
			},
			['sc_inaschastening'] = {
				'Scroll of Inas Chastening.',
				'Inflicts punishment on the target.',
				'Type: Scroll'
			},
			['sc_elementalburstshock'] = {
				'Scroll of Elemental Burst: Electric.',
				'Releases an electric elemental burst.',
				'Type: Scroll'
			},
			['sc_nerusislockjaw'] = {
				'Scroll of Neruzi Lockjaw.',
				"Paralyzes the target's jaws.",
				'Type: Scroll'
			},
			['sc_fphyggisgemfeeder'] = {
				'Scroll of Fphyggis Gem Feeder.',
				'Empowers gemstones with magic.',
				'Type: Scroll'
			},
			['sc_tranasasspellmire'] = {
				'Scroll of Tranasa Spellmire.',
				'Creates a magical swamp area.',
				'Type: Scroll'
			},
			['sc_reynosfins'] = {
				'Scroll of Reynos Fins.',
				'Grants aquatic movement abilities.',
				'Type: Scroll'
			},
			['sc_inasismysticfinger'] = {
				'Scroll of Inazi Mystic Finger.',
				'Enables mystical finger powers.',
				'Type: Scroll'
			},
			['sc_daynarsairybubble'] = {
				'Scroll of Daynar Airy Bubble.',
				'Creates an airy protective bubble.',
				'Type: Scroll'
			},
			['sc_selynsmistslippers'] = {
				'Scroll of Selyn Mist Slippers.',
				'Grants misty movement abilities.',
				'Type: Scroll'
			},
			['sc_flamebane'] = {
				'Scroll of Flame Bane.',
				'Inflicts deadly fire damage.',
				'Type: Scroll'
			},
			['sc_frostbane'] = {
				'Scroll of Frost Bane.',
				'Inflicts deadly cold damage.',
				'Type: Scroll'
			},
			['sc_shockbane'] = {
				'Scroll of Shock Bane.',
				'Inflicts deadly electric damage.',
				'Type: Scroll'
			},
			['bk_BriefHistoryofWood'] = {
				'Book: Forest Tales by No-ha.',
				'Illustrated guide to forest life.',
				'Type: Book'
			},
			['bk_RealBarenziah1'] = {
				'True Tale of Barenziah, Vol. I.',
				'Historical account of the queen.',
				'Type: Book'
			},
			['bk_RealBarenziah5'] = {
				'True Tale of Barenziah, Vol. V.',
				"Continues the queen's story.",
				'Type: Book'
			},
			['sc_divineintervention'] = {
				'Scroll of Divine Intervention.',
				'Calls upon divine power.',
				'Type: Scroll'
			},
			['sc_messengerscroll'] = {
				'Scroll of the Messenger.',
				'Enables message delivery magic.',
				'Type: Scroll'
			},
			['sc_cureblight_ranged'] = {
				'Scroll of Cure Blight (ranged).',
				'Heals blight from a distance.',
				'Type: Scroll'
			},
			['sc_summondaedroth_hto'] = {
				'Scroll of Milin Faram Summoning.',
				'Summons Milin Faram entity.',
				'Type: Scroll'
			},
			['sc_summongoldensaint'] = {
				'Scroll of Golden Saint Summoning.',
				'Summons a golden saint entity.',
				'Type: Scroll'
			},
			['bk_bartendersguide'] = {
				"Hanin's Awakening Guide.",
				'Guide for bartenders and mixologists.',
				'Type: Book'
			},
			['bk_NerevarineNotice'] = {
				'Official Nerevarine Notice.',
				'Formal announcement document.',
				'Type: Document'
			},
			['bk_Warehouse_log'] = {
				'Warehouse Inventory Log.',
				'Records warehouse stock and transactions.',
				'Type: Document'
			},
			['sc_invisibility'] = {
				'Scroll of Invisibility.',
				'Makes the caster invisible.',
				'Type: Scroll'
			},
			['sc_windwalker'] = {
				'Scroll of Wind Walker.',
				'Grants wind-based movement power.',
				'Type: Scroll'
			},
			['sc_tranasasspelltwist'] = {
				'Scroll of Tranasa Spell Twist.',
				'Alters magical spells in area.',
				'Type: Scroll'
			},
			['sc_tevilspeace'] = {
				"Scroll of Tevil's Peace.",
				'Brings peace to the surroundings.',
				'Type: Scroll'
			},
			['bk_red_mountain_map'] = {
				'Map of the Red Mountain.',
				'Detailed geographical map.',
				'Type: Map'
			},
			['bk_arrilles_tradehouse'] = {
				'Arilles Tradehouse Notice.',
				'Club announcement poster.',
				'Type: Notice'
			},
			['sc_FiercelyRoastThyEnemy_unique'] = {
				'Scroll of Fierce Flame.',
				'Inflicts intense fire damage on foes.',
				'Type: Scroll'
			},
			['bk_talostreason'] = {
				'Note from Oritius Maro.',
				'Secret note about treason.',
				'Type: Note'
			},
			['bk_a2_2_dagoth_message'] = {
				'Message from Dagoth Ur.',
				'Prophetic message from a Daedric lord.',
				'Type: Message'
			},
			['bk_EggOfTime'] = {
				'Egg of Time artifact.',
				'Mysterious object related to time magic.',
				'Type: Artifact'
			},
			['bk_DivineMetaphysics'] = {
				'Divine Metaphysics Treatise.',
				'Philosophical text on divine matters.',
				'Type: Book'
			},
			['bk_a1_1_elone_to_Balmora'] = {
				"Elone's Instructions to Balmora.",
				'Travel guide to Balmora.',
				'Type: Guide'
			},
			['bk_note'] = {
				'Worn and tattered note.',
				'Old, barely readable note.',
				'Type: Note'
			},
			['writ_yasalmibaal'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_oran'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_saren'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_sadus'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_vendu'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_guril'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_galasa'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_mavon'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_belvayn'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_bemis'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_brilnosu'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_navil'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_varro'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_baladas'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_bero'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['writ_therana'] = {
				'Execution Order: Noble Execution.',
				'Royal decree for noble execution.',
				'Type: Decree'
			},
			['bk_great_houses'] = {
				'Great Houses of Morrowind.',
				"Comprehensive guide to Morrowind's ruling houses.",
				'Type: Book'
			},
			['sc_summonskeletalservant'] = {
				'Scroll of Skeletal Servant Summoning.',
				'Summons a skeletal servant to aid the caster.',
				'Type: Scroll'
			},
			['sc_summonflameatronach'] = {
				'Scroll of Flame Atronach Summoning.',
				'Summons a fiery atronach creature.',
				'Type: Scroll'
			},
			['sc_summonfrostatronach'] = {
				'Scroll of Frost Atronach Summoning.',
				'Summons a frosty atronach creature.',
				'Type: Scroll'
			},
			['bk_charterMG'] = {
				'Charter of the Mages Guild.',
				'Official guild charter for mages.',
				'Type: Charter'
			},
			['bk_charterFG'] = {
				'Charter of the Fighters Guild.',
				'Official guild charter for fighters.',
				'Type: Charter'
			},
			['bk_Ibardad_Elante_notes'] = {
				"Elante's Personal Notes.",
				'Collection of notes and observations by Elante.',
				'Type: Notes'
			},
			['BookSkill_Destruction5_open'] = {
				"Talara's Secret, Part 3.",
				'Advanced destruction magic tutorial.',
				'Type: Tutorial'
			},
			['BookSkill_Axe5_open'] = {
				'36 Lessons of Vivec: Sermon 16.',
				"Vivec's teachings on axe combat.",
				'Type: Sermon'
			},
			["bk_Boethiah's Glory_unique"] = {
				"Boethiah's Glory.",
				'Text praising the Daedric Prince Boethiah.',
				'Type: Religious Text'
			},
			['bk_Aedra_Tarer_Unique'] = {
				'Aedra and Daedra of Tarer.',
				'Study of divine and demonic entities.',
				'Type: Study'
			},
			['bk_ocato_recommendation'] = {
				'Recommendation Letter from Ocato.',
				'Official letter of recommendation.',
				'Type: Letter'
			},
			['bk_Ajira1'] = {
				"Ajira's Report on Mushrooms.",
				'Scientific report on local fungi.',
				'Type: Report'
			},
			['bk_Ajira2'] = {
				"Ajira's Report on Flowers.",
				'Scientific report on local flora.',
				'Type: Report'
			},
			["Cumanya's Notes"] = {
				"Cumanya's Honest Warning.",
				'Warning notes from Cumanya about local dangers.',
				'Type: Warning'
			},
			['sc_Malaki'] = {
				'Blood-Written Scroll.',
				'Scroll inscribed with blood, holds dark power.',
				'Type: Scroll'
			},
			['sc_drathissoulrot'] = {
				"Scroll of Drathis' Soul Rot.",
				'Inflicts soul corruption upon the target.',
				'Type: Scroll'
			},
			['sc_drathiswinterguest'] = {
				"Scroll of Drathis' Winter Guest.",
				'Summons a winter spirit to harass enemies.',
				'Type: Scroll'
			},
			['sc_Vulpriss'] = {
				"Vulpriss' Scribblings.",
				'Mysterious doodles with hidden magical properties.',
				'Type: Scribblings'
			},
			['bk_BriefHistoryofWood_01'] = {
				'Forest Tales by No-ha (Part 1).',
				'Illustrated storybook about forest life.',
				'Type: Storybook'
			},
			['bk_landdeed_hhrd'] = {
				'Deed for Ascad Islands Land.',
				'Legal document for land ownership.',
				'Type: Deed'
			},
			['bk_landdeedfake_hhrd'] = {
				'Fake Deed for Odral Land.',
				'Counterfeit land ownership document.',
				'Type: Fake Deed'
			},
			['bk_stronghold_c_hlaalu'] = {
				'Hlaalu Stronghold Construction Permit.',
				'Permit for stronghold construction.',
				'Type: Permit'
			},
			['bk_stronghold_ld_hlaalu'] = {
				'Deed for Retan Estate.',
				'Legal document for estate ownership.',
				'Type: Deed'
			},
			['bk_V_hlaaluprison'] = {
				'List of Hlaalu Prison Inmates.',
				'Registry of prisoners in Hlaalu jail.',
				'Type: Registry'
			},
			['bk_Hlaalu_Vaults_Ledger'] = {
				'Hlaalu Vaults Inventory Ledger.',
				'Ledger tracking vault contents.',
				'Type: Ledger'
			},
			['sc_Indie'] = {
				'Dying Words of an Unknown.',
				'Final words of a dying individual.',
				'Type: Message'
			},
			['bk_Nerano'] = {
				'Note from Bakaraka.',
				'Personal note from Bakaraka.',
				'Type: Note'
			},
			['sc_Tyronius'] = {
				'Scroll of Tyronius.',
				'Ancient scroll with mystical powers.',
				'Type: Scroll'
			},
			['bk_shalitjournal_deal'] = {
				"Page from Shalit's Journal (Deal).",
				'Journal entry about a business deal.',
				'Type: Journal Entry'
			},
			['bk_shalit_note'] = {
				'Note to Hiden from Shalit.',
				'Personal message to Hiden.',
				'Type: Note'
			},
			['bk_drenblackmail'] = {
				"Dren's Blackmail Note.",
				'Blackmail note used for coercion.',
				'Type: Blackmail Note'
			},
			['bk_notetomalsa'] = {
				'Note addressed to Malza Ules.',
				'Contains personal messages.',
				'Type: Note'
			},
			['bk_Redoran_Vaults_Ledger'] = {
				'Ledger for Redoran clan vaults.',
				'Records inventory and transactions.',
				'Type: Ledger'
			},
			['bk_ILHermit_Page'] = {
				"Page from the Empire's history book.",
				'Details imperial chronicles.',
				'Type: Historical page'
			},
			['note_Peke_Utchoo'] = {
				'Final words of Peke Utchoo.',
				'Reveals last thoughts and wishes.',
				'Type: Note'
			},
			['bk_clientlist'] = {
				'List of clients and their details.',
				'Used for business tracking.',
				'Type: Client list'
			},
			['bk_contract_ralen'] = {
				'Contract for weapons and armor.',
				'Outlines terms of purchase.',
				'Type: Contract'
			},
			['bk_letterfromllaalam'] = {
				'Letter from Llaalam Dredil.',
				'Contains personal correspondence.',
				'Type: Letter'
			},
			['bk_letterfromjzhirr'] = {
				"Note from Jay'Zhirr.",
				'Short message with instructions.',
				'Type: Note'
			},
			['bk_letterfromllaalam2'] = {
				'Second letter from Llaalam Dredil.',
				'Further correspondence details.',
				'Type: Letter'
			},
			['bk_letterfromgadayn'] = {
				'Letter from Gadayn.',
				'Personal or business communication.',
				'Type: Letter'
			},
			['bk_leaflet_false'] = {
				'False leaflet with misleading info.',
				'Used for deception or propaganda.',
				'Type: Leaflet'
			},
			['bk_Telvanni_Vault_Ledger'] = {
				'Ledger for Telvanni clan vaults.',
				'Tracks magical and material goods.',
				'Type: Ledger'
			},
			['sc_almsiviintervention'] = {
				'Scroll of Almsivi Intervention.',
				'Enables magical teleportation.',
				'Type: Scroll'
			},
			["bk_Yagrum's_Book"] = {
				'Book of Tamriel legends.',
				'Collects myths and tales.',
				'Type: Book'
			},
			['bk_lustyargonianmaid'] = {
				'Story about an Argonian maiden.',
				'Contains risqué content.',
				'Type: Storybook'
			},
			['bk_AlchemistsFormulary'] = {
				'Collection of alchemy recipes.',
				'Guides potion creation.',
				'Type: Formulary'
			},
			['bk_SecretsDwemerAnimunculi'] = {
				'Secrets of Dwemer automata.',
				'Details ancient technology.',
				'Type: Manual'
			},
			['sc_icarianflight'] = {
				'Scroll of Icarian Flight.',
				'Grants temporary flight.',
				'Type: Scroll'
			},
			['bk_fellowshiptemple'] = {
				'Text about Temple Brotherhood.',
				'Details religious order.',
				'Type: Religious text'
			},
			['bk_formygodsandemperor'] = {
				'Ode to gods and emperor.',
				'Poetic tribute to deities and ruler.',
				'Type: Poem'
			},
			['bk_ordolegionis'] = {
				'Text about Order of Legion.',
				'Details military organization.',
				'Type: Manual'
			},
			['bk_bartendersguide_01'] = {
				"Guide to Hanin's awakening.",
				'Instructions for a ritual.',
				'Type: Guide'
			},
			['bookskill_mystery5'] = {
				"Fifth part of Talara's mystery.",
				'Continues a serialized tale.',
				'Type: Novel excerpt'
			},
			['bk_notetotelvon'] = {
				'Note sent to Telvon.',
				'Personal or task-related message.',
				'Type: Note'
			},
			['bk_WaroftheFirstCouncil'] = {
				'Chronicle of the First Council war.',
				'Details ancient conflict.',
				'Type: Historical text'
			},
			['bk_OnMorrowind'] = {
				'Book about Morrowind province.',
				'Provides regional overview.',
				'Type: Regional guide'
			},
			['bk_RealNerevar'] = {
				'True story of Nerevar.',
				'Historical account of the hero.',
				'Type: Biography'
			},
			['bk_NerevarMoonandStar'] = {
				'Legend of Nerevar: Moon and Star.',
				'Mythical tale about the hero.',
				'Type: Legend'
			},
			['bk_SaintNerevar'] = {
				"Saint Nerevar's hagiography.",
				'Religious text about the saint.',
				'Type: Religious text'
			},
			['bk_ShortHistoryMorrowind'] = {
				'Brief history of Morrowind.',
				'Condensed regional chronicle.',
				'Type: History book'
			},
			['bk_falljournal_unique'] = {
				"Tarhiel's personal diary.",
				'Records private thoughts and events.',
				'Type: Diary'
			},
			['sc_ekashslocksplitter'] = {
				'Scroll to break locks.',
				'Enables lockpicking magic.',
				'Type: Scroll'
			},
			['sc_frostguard'] = {
				'Scroll of Frost Guard.',
				'Provides frost protection.',
				'Type: Scroll'
			},
			['sc_paper plain'] = {
				'Plain sheet of paper.',
				'Blank for writing.',
				'Type: Paper'
			},
			['sc_paper_plain_01_canodia'] = {
				'Plain paper from Canodia.',
				'Blank writing material.',
				'Type: Paper'
			},
			['bk_commontongue'] = {
				'Guide to common language.',
				'Teaches regional dialect.',
				'Type: Language guide'
			},
			['bk_commontongue_irano'] = {
				'Common tongue guide (Irano edition).',
				'Dialect guide with regional notes.',
				'Type: Language guide'
			},
			['bk_Irano_note'] = {
				'Short note by Irano.',
				'Personal or task-related message.',
				'Type: Note'
			},
			['bk_Alen_note'] = {
				'Letter written by Alen.',
				'Contains personal correspondence.',
				'Type: Letter'
			},
			['writ_Berano'] = {
				'Royal execution order by Berano.',
				'Authorizes capital punishment.',
				'Type: Royal writ'
			},
			['writ_Hloggar'] = {
				'Royal execution order by Hloggar.',
				'Authorizes capital punishment.',
				'Type: Royal writ'
			},
			['writ_Alen'] = {
				'Royal execution order by Alen.',
				'Authorizes capital punishment.',
				'Type: Royal writ'
			},
			['bk_playscript'] = {
				'Script for "Horror of Castle Xyr".',
				'Theater play manuscript.',
				'Type: Play script'
			},
			['bk_ahnia'] = {
				'Note intended for Ahnia.',
				'Personal or task-related message.',
				'Type: Note'
			},
			['bk_nermarcnotes'] = {
				'Secret notes by Nermarc.',
				'Confidential information.',
				'Type: Secret notes'
			},
			['bk_custom_armor'] = {
				'Price list for custom armor.',
				'Lists costs for armor orders.',
				'Type: Price list'
			},
			['book_dwe_pipe00'] = {
				'Old Dwarven book about pipes.',
				'Details dwemer engineering.',
				'Type: Ancient book'
			},
			['book_dwe_cogs00'] = {
				'Old Dwarven book about cogs.',
				'Details dwemer machinery.',
				'Type: Ancient book'
			},
			['book_dwe_mach00'] = {
				'Old Dwarven book about machines.',
				'Details dwemer technology.',
				'Type: Ancient book'
			},
			['book_dwe_water00'] = {
				'Old Dwarven book about water systems.',
				'Details dwemer hydraulics.',
				'Type: Ancient book'
			},
			['book_dwe_power_con00'] = {
				'Old Dwarven book about power systems.',
				'Details dwemer energy technology.',
				'Type: Ancient book'
			},
			['book_dwe_metal_fab00'] = {
				'Old Dwarven book on metal fabrication.',
				'Outlines двемерская metallurgy.',
				'Type: Ancient book'
			},
			['bk_Teran_invoice'] = {
				"Invoice from Teran's business.",
				'Lists goods and payment details.',
				'Type: Invoice'
			},
			['book_dwe_boom00'] = {
				'Old Dwarven book about explosives.',
				'Details двемерская pyrotechnics.',
				'Type: Ancient book'
			},
			['bk_diary_sailor'] = {
				'Diary of a missing sailor.',
				'Records sea voyages and dangers.',
				'Type: Diary'
			},
			['bk_dbcontract'] = {
				'Contract with the Dark Brotherhood.',
				'Outlines assassination terms.',
				'Type: Contract'
			},
			['sc_chridittepanacea'] = {
				"Scroll of Chriditte's Panacea.",
				'Heals all wounds and diseases.',
				'Type: Scroll'
			},
			['bk_Adren'] = {
				'Warning note marked "ВНИМАНИЕ!!!".',
				'Alerts of danger or caution.',
				'Type: Warning note'
			},
			['bk_suicidenote'] = {
				'Suicide note left by Share.',
				'Reveals final thoughts.',
				'Type: Suicide note'
			},
			['bk_Artifacts_Tamriel'] = {
				'Catalog of famous Tamriel artifacts.',
				'Lists legendary items.',
				'Type: Catalog'
			},
			['sc_Erna'] = {
				'Note from Erna Brandru.',
				'Contains personal messages.',
				'Type: Note'
			},
			['bk_snowprince'] = {
				"Tale of the Snow Prince's fall.",
				'Tragic story of a frozen hero.',
				'Type: Legend'
			},
			['bk_BMtrial_unique'] = {
				'Letter from Rigmor Rizi.',
				'Personal or trial-related content.',
				'Type: Letter'
			},
			['bk_ThirskHistory'] = {
				'Historical account of Thirsk.',
				'Chronicles town history.',
				'Type: History text'
			},
			['bk_Airship_Captains_Journal'] = {
				"Captain's log for an airship.",
				'Records flight journeys.',
				'Type: Journal'
			},
			['sc_GrandfatherFrost'] = {
				'Song of Grandfather Frost.',
				'Festive winter melody.',
				'Type: Song'
			},
			['sc_Erna01'] = {
				'Another note from Erna Erne.',
				'Additional personal messages.',
				'Type: Note'
			},
			['sc_Chappy_sniper_test'] = {
				'Scroll of the sniper test.',
				'Enhances stealth and accuracy.',
				'Type: Scroll'
			},
			['bk_Sovngarde'] = {
				'Report on Sovngarde research.',
				'Details afterlife studies.',
				'Type: Research report'
			},
			['bk_BM_Aevar'] = {
				'Tale of Aevar, the stone singer.',
				'Epic story of a dwarven hero.',
				'Type: Epic tale'
			},
			['bk_BM_StoneMap'] = {
				'Map showing stone locations.',
				'Guides to ancient landmarks.',
				'Type: Map'
			},
			['sc_unclesweetshare'] = {
				'Song of Uncle Sweetshare.',
				'Whimsical folk melody.',
				'Type: Song'
			},
			['bk_fur_armor'] = {
				'Price list for fur armor sets.',
				'Lists costs for winter gear.',
				'Type: Price list'
			},
			['sc_jeleen'] = {
				'Farewell note from Jeleen.',
				'Emotional parting message.',
				'Type: Farewell note'
			},
			['bk_colonyreport'] = {
				'Report on colony status.',
				'Summarizes settlement progress.',
				'Type: Report'
			},
			['sc_savagetyranny'] = {
				'Scroll of savage tyranny.',
				'Empowers with brutal strength.',
				'Type: Scroll'
			},
			['bk_carniusnote'] = {
				'Note from Carnius with instructions.',
				'Contains task or warning.',
				'Type: Note'
			},
			['bk_BM_Stockcert'] = {
				'Certificate of stock ownership.',
				'Proves shareholder rights.',
				'Type: Certificate'
			},
			['sc_piratetreasure'] = {
				'Note detailing pirate treasure.',
				'Maps hidden loot locations.',
				'Type: Treasure map'
			},
			['bk_ThirskHistory_revised_m'] = {
				'Revised male edition of Thirsk history.',
				'Updated town chronicles.',
				'Type: History text'
			},
			['bk_ThirskHistory_revised_f'] = {
				'Revised female edition of Thirsk history.',
				'Updated town chronicles.',
				'Type: History text'
			},
			['sc_fjellnote'] = {
				'Bloodstained note from Fjell.',
				'Hints at violent events.',
				'Type: Bloodstained note'
			},
			['sc_sjobalnote'] = {
				'Orders from Toraver to Sjobal.',
				'Military or task commands.',
				'Type: Orders'
			},
			['sc_frosselnote'] = {
				'Bloodstained note from Frossel.',
				'Reveals dark secrets.',
				'Type: Bloodstained note'
			},
			['sc_fjaldingnote'] = {
				'Old, damp note from Fjalding.',
				'Weathered message with clues.',
				'Type: Old note'
			},
			['bk_fryssajournal'] = {
				'Personal journal of Fryssa.',
				'Records daily life and thoughts.',
				'Type: Personal journal'
			},
			['bk_necrojournal'] = {
				'Journal of a necromancer.',
				'Details dark magic practices.',
				"Type: Necromancer's journal"
			},
			['bk_leggejournal'] = {
				'Journal of a colony settler.',
				'Records survival and struggles.',
				"Type: Settler's journal"
			},
			['sc_bodily_restoration'] = {
				'Scroll for bodily restoration.',
				'Heals physical injuries.',
				'Type: Scroll'
			},
			['sc_bloodynote_s'] = {
				'Note stained with blood.',
				'Contains chilling message.',
				'Type: Bloody note'
			},
			['bk_colony_Toralf'] = {
				'Worn note from Toralf.',
				'Details colony issues.',
				'Type: Worn note'
			},
			['sc_hiddenkiller'] = {
				'Scroll of the hidden killer.',
				'Enhances stealth in battle.',
				'Type: Scroll'
			},
			['sc_lycanthropycure'] = {
				'Scroll to cure lycanthropy.',
				'Removes werewolf curse.',
				'Type: Scroll'
			},
			['sc_witchnote'] = {
				'Note from a Glenmoril witch.',
				'Contains dark incantations.',
				"Type: Witch's note"
			},
			['sc_rumornote_bm'] = {
				'Note with strange rumors.',
				'Spreads mysterious gossip.',
				'Type: Rumor note'
			}
        }
    }
}