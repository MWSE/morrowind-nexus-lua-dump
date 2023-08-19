--[[
Audiobook for Morrowind mod - mwse plugin
by rfuzzo
for: https://www.nexusmods.com/morrowind/mods/52458
version 1.0

Install:
- make sure to disable Audiobooks of Morrowind.esp
]] --
local read_menu = tes3ui.registerID("audiobooks:readmenu")
local read_menu_ok = tes3ui.registerID("audiobooks:readmenu_ok")
local read_menu_stop = tes3ui.registerID("audiobooks:readmenu_stop")
local read_menu_cancel = tes3ui.registerID("audiobooks:readmenu_cancel")

local last_played_sound_id = nil
local temp_book_id = nil

local ADD_BUTTONS = true

-- todo fill in
local sound_map = {
    bk_ABCs = "Vo\\Audiobook\\ABCs_for_Barbarians.mp3",
    bk_AedraAndDaedra = "Vo\\Audiobook\\AedraDaedra.mp3",
    bk_AffairsOfWizards = "Vo\\Audiobook\\The_Affairs_of_Wizards.mp3",
    bk_AncestorsAndTheDunmer = "Vo\\Audiobook\\Ancestors_and_the_Dunmer.mp3",
    bk_AnnotatedAnuad = "Vo\\Audiobook\\The_Annotated_Anuad.mp3",
    bk_AntecedantsDwemerLaw = "Vo\\Audiobook\\Antecedents_Dwemer.mp3",
    bk_Anticipations = "Vo\\Audiobook\\The_Anticipations.mp3",
    bk_ArcanaRestored = "Vo\\Audiobook\\Arcana_Restored.mp3",
    bk_ArcturianHeresy = "Vo\\Audiobook\\The_Arcturian_Heresy.mp3",
    bk_ArkayTheEnemy = "Vo\\Audiobook\\Arkay_the_Enemy.mp3",
    bk_Ashland_Hymns = "Vo\\Audiobook\\AshHymns.mp3",
    bk_bartendersguide = "Vo\\Audiobook\\Hanins_Wake.mp3",
    bk_BiographyBarenziah1 = "Vo\\Audiobook\\BioBarenziah1.mp3",
    bk_BiographyBarenziah2 = "Vo\\Audiobook\\BioBarenziah2.mp3",
    bk_BiographyBarenziah3 = "Vo\\Audiobook\\BioBarenziah3.mp3",
    bk_BlasphemousRevenants = "Vo\\Audiobook\\Blasphemous_Revenants.mp3",
    bk_BlueBookOfRiddles = "Vo\\Audiobook\\The_Blue_Book_Riddles.mp3",
    bk_BoethiahPillowBook = "Vo\\Audiobook\\Boethiah_Pillow_Book.mp3",
    bk_Boethiahs_Glory_unique = "Vo\\Audiobook\\Boethiahs_Glory.mp3",
    bk_BookDawnAndDusk = "Vo\\Audiobook\\The_Book_of_Dawn_and_Dusk.mp3",
    bk_BookOfDaedra = "Vo\\Audiobook\\The_Book_of_Daedra.mp3",
    bk_BookOfLifeAndService = "Vo\\Audiobook\\Book_Of_Life_And_Service.mp3",
    bk_BriefHistoryEmpire1 = "Vo\\Audiobook\\Biref_History_Empire_1.mp3",
    bk_BriefHistoryEmpire2 = "Vo\\Audiobook\\Biref_History_Empire_2.mp3",
    bk_BriefHistoryEmpire3 = "Vo\\Audiobook\\Biref_History_Empire_3.mp3",
	bookskill_heavy_armor1 = "Vo\\Audiobook\\Hallgerds_Tale.mp3",
    bookskill_heavy_armor4 = "Vo\\Audiobook\\How_Orsinium_Passed_Orcs.mp3",
    BookSkill_Light_Armor2 = "Vo\\Audiobook\\Ice_and_Chitin.mp3",
    bk_Im_My_Own_Grandpa = "Vo\\Audiobook\\Im_My_Own_Grandpa.mp3",
    bookskill_illusion3 = "Vo\\Audiobook\\Incident_in_Necrom.mp3",
    BookSkill_Armorer2 = "Vo\\Audiobook\\Last_Scabbard_of_Akrash.mp3",
    bookskill_light_armor3 = "Vo\\Audiobook\\Lord_Jornibrets_Last_Dance.mp3",
	bookskill_hand_to_hand5 = "Vo\\Audiobook\\Master_Zoarayms_Tale.mp3",
    BookSkill_Acrobatics5 = "Vo\\Audiobook\\Mystery_of_Talara_v1.mp3",
    BookSkill_Restoration5 = "Vo\\Audiobook\\Mystery_of_Talara_v2.mp3",
    BookSkill_Destruction5 = "Vo\\Audiobook\\Mystery_of_Talara_v3.mp3",
	BookSkill_Destruction5_open = "Vo\\Audiobook\\Mystery_of_Talara_v3.mp3",
    bookskill_illusion5 = "Vo\\Audiobook\\Mystery_of_Talara_v4.mp3",
    bookskill_mystery5 = "Vo\\Audiobook\\Mystery_of_Talara_v5.mp3",
    bk_nchunaksfireandfaith = "Vo\\Audiobook\\Nchuanks_Fire_and_Faith.mp3",
	bookskill_blunt_weapon3 = "Vo\\Audiobook\\Night_Falls_on_Sentinel.mp3",
    bookskill_restoration2 = "Vo\\Audiobook\\Notes_on_Racial_Phylogeny.mp3",
    bk_ordolegionis = "Vo\\Audiobook\\Ordo_Legionis.mp3",
    bookskill_illusion4 = "Vo\\Audiobook\\Palla_v1.mp3",
    bookskill_enchant3 = "Vo\\Audiobook\\Palla_v2.mp3",
    bookskill_acrobatics1 = "Vo\\Audiobook\\Realizations_of_Acrobacy.mp3",
	bk_redorancookingsecrets = "Vo\\Audiobook\\Redoran_Cooking_Secrets.mp3",
    bookskill_destruction2 = "Vo\\Audiobook\\Response_to_Beros_Speech.mp3",
    bookskill_illusion2 = "Vo\\Audiobook\\Silence_book.mp3",
    bookskill_spear1 = "Vo\\Audiobook\\Smugglers_Island.mp3",
	BookSkill_Alchemy3 = "Vo\\Audiobook\\Song_of_the_Alchemist.mp3",
    bookskill_security5 = "Vo\\Audiobook\\Surfeit_of_Thieves.mp3",
    bk_TalMarogKersResearches = "Vo\\Audiobook\\Tal_Marog_Kers_Researches.mp3",
    bk_Yagrums_Book = "Vo\\Audiobook\\Tamrielic_Lore.mp3",
    bk_AlchemistsFormulary = "Vo\\Audiobook\\The_Alchemists_Formulary.mp3",
    BookSkill_Armorer1 = "Vo\\Audiobook\\The_Armorers_Challenge.mp3",
	bookskill_destruction4 = "Vo\\Audiobook\\The_Art_of_War_Magic.mp3",
    bookskill_axe2 = "Vo\\Audiobook\\The_Axe_Man.mp3",
    bk_Balladeers_Fakebook = "Vo\\Audiobook\\The_Balladeers_Fakebook.mp3",
    bk_BlackGlove = "Vo\\Audiobook\\The_Black_Glove.mp3",
    BookSkill_Security3 = "Vo\\Audiobook\\The_Dowry.mp3",
    BookSkill_Alteration2 = "Vo\\Audiobook\\The_Dragon_Break_Reexamined.mp3",
	bookskill_enchant5 = "Vo\\Audiobook\\The_Final_Lesson.mp3",
    bookskill_mysticism1 = "Vo\\Audiobook\\The_Firsthold_Revolt.mp3",
    bookskill_restoration3 = "Vo\\Audiobook\\The_Four_Suitors_Benitah.mp3",
    bookskill_marksman1 = "Vo\\Audiobook\\The_Gold_Ribbon_of_Merit.mp3",
	bookskill_blunt_weapon1 = "Vo\\Audiobook\\The_Hope_of_the_Redoran.mp3",
    bk_playscript = "Vo\\Audiobook\\The_Horror_Castle_Xyr.mp3",
    bookskill_destruction1 = "Vo\\Audiobook\\The_Horror_Castle_Xyr.mp3",
    BookSkill_Blunt_Weapon2 = "Vo\\Audiobook\\The_Importance_of_Where.mp3",
    bk_LegendaryScourge = "Vo\\Audiobook\\The_Legendary_Scourge.mp3",
    bookskill_security1 = "Vo\\Audiobook\\The_Locked_Room.mp3",
	BookSkill_Alteration5 = "Vo\\Audiobook\\The_Lunar_Lorkhan.mp3",
    bk_madnessofpelagius = "Vo\\Audiobook\\The_Madness_Pelagius.mp3",
    bookskill_marksman4 = "Vo\\Audiobook\\The_Marksmanship_Lesson.mp3",
    bk_manyfacesmissinggod = "Vo\\Audiobook\\The_Monomyth.mp3",
	bookskill_block2 = "Vo\\Audiobook\\The_Mirror.mp3",
    bk_oldways = "Vo\\Audiobook\\The_Old_Ways.mp3",
    bk_PostingOfTheHunt = "Vo\\Audiobook\\The_Posting_of_the_Hunt.mp3",
    bookskill_hand_to_hand1 = "Vo\\Audiobook\\The_Prayers_of_Baranat.mp3",
    BookSkill_Athletics1 = "Vo\\Audiobook\\The_Ransom_of_Zarek.mp3",
    BookSkill_Light_Armor1 = "Vo\\Audiobook\\The_Rear_Guard.mp3",
	BookSkill_Axe3 = "Vo\\Audiobook\\The_Seed.mp3",
    BookSkill_Axe1 = "Vo\\Audiobook\\The_Third_Door.mp3",
    bk_VagariesOfMagica = "Vo\\Audiobook\\The_Vagaries_of_Magicka.mp3",
    bookskill_conjuration5 = "Vo\\Audiobook\\The_Warriors_Charge.mp3",
	bk_WatersOfOblivion = "Vo\\Audiobook\\The_Waters_of_Oblivion.mp3",
    bookskill_security2 = "Vo\\Audiobook\\The_Wolf_Queen_v1.mp3",
    bookskill_hand_to_hand2 = "Vo\\Audiobook\\The_Wolf_Queen_v2.mp3",
    bookskill_illusion1 = "Vo\\Audiobook\\The_Wolf_Queen_v3.mp3",
    bookskill_mercantile2 = "Vo\\Audiobook\\The_Wolf_Queen_v4.mp3",
	bookskill_speechcraft2 = "Vo\\Audiobook\\The_Wolf_Queen_v5.mp3",
    bookskill_sneak1 = "Vo\\Audiobook\\The_Wolf_Queen_v6.mp3",
    bookskill_speechcraft4 = "Vo\\Audiobook\\The_Wolf_Queen_v7.mp3",
    BookSkill_Enchant2 = "Vo\\Audiobook\\The_Wolf_Queen_v8.mp3",
    bookskill_unarmored1 = "Vo\\Audiobook\\The_Wraiths_Wedding_Dowry.mp3",
	bookskill_short_blade1 = "Vo\\Audiobook\\Unnamed_Book.mp3",
    bookskill_marksman3 = "Vo\\Audiobook\\Vernaccus_and_Bourlor.mp3",
    bk_WaroftheFirstCouncil = "Vo\\Audiobook\\War_of_the_First_Council.mp3",
    BookSkill_Long_Blade1 = "Vo\\Audiobook\\Words_and_Philosophy.mp3",
	bk_wordsclanmother = "Vo\\Audiobook\\Words_Clan_Mom_Ahnissi.mp3",
    bk_words_of_the_wind = "Vo\\Audiobook\\Words_of_the_Wind.mp3",
    bk_yellowbookofriddles = "Vo\\Audiobook\\Yellow_Book_of_Riddles.mp3",
    bk_BriefHistoryEmpire4 = "Vo\\Audiobook\\Biref_History_Empire_4.mp3",
    bk_BriefHistoryofWood = "Vo\\Audiobook\\Picture_Book_of_Wood.mp3",
    bk_BriefHistoryofWood_01 = "Vo\\Audiobook\\Picture_Book_of_Wood.mp3",
    bk_BrothersOfDarkness = "Vo\\Audiobook\\The_Brothers_Darkness.mp3",
    bk_CantatasOfVivec = "Vo\\Audiobook\\The_Cantatas_of_Vivec.mp3",
    bk_ChangedOnes = "Vo\\Audiobook\\The_Changed_Ones.mp3",
    bk_charterFG = "Vo\\Audiobook\\Fighters_Guild_Charter.mp3",
    bk_charterMG = "Vo\\Audiobook\\Mages_Guild_Charter.mp3",
    bk_ChildrenOfTheSky = "Vo\\Audiobook\\Children_Of_Sky.mp3",
    bk_ChildrensAnuad = "Vo\\Audiobook\\The_Annotated_Anuad.mp3",
    bk_ChroniclesNchuleft = "Vo\\Audiobook\\Chronicles_of_Nchuleft.mp3",
    bk_Confessions = "Vo\\Audiobook\\Confessions_Skooma_Eater.mp3",
    bk_ConsolationsOfPrayer = "Vo\\Audiobook\\The_Consolations_of_Prayer.mp3",
    bk_corpsepreperation1_c = "Vo\\Audiobook\\Corpse_Preparation_1.mp3",
    bk_corpsepreperation1_o = "Vo\\Audiobook\\Corpse_Preparation_1.mp3",
    bk_corpsepreperation2_c = "Vo\\Audiobook\\Corpse_Preparation_2.mp3",
    bk_corpsepreperation3_c = "Vo\\Audiobook\\Corpse_Preparation_3.mp3",
    bk_darkestdarkness = "Vo\\Audiobook\\Darkest_Darkness.mp3",
    bk_DoorsOfTheSpirit = "Vo\\Audiobook\\The_Doors_Of_Spirit.mp3",
    bk_easternprovincesimpartial = "Vo\\Audiobook\\The_Eastern_Provinces.mp3",
    bk_fellowshiptemple = "Vo\\Audiobook\\Fellowship_Of_The_Temple.mp3",
    bk_firmament = "Vo\\Audiobook\\The_Firmament.mp3",
    bk_fishystick = "Vo\\Audiobook\\Capns_Guide_to_the_Fishy_Stick.mp3",
    bk_five_far_stars = "Vo\\Audiobook\\The_Five_Far_Stars.mp3",
    bk_fivesongsofkingwulfharth = "Vo\\Audiobook\\Five_Songs_of_King_Wulfharth.mp3",
    bk_formygodsandemperor = "Vo\\Audiobook\\For_God_Emperor.mp3",
    bk_fragmentonartaeum = "Vo\\Audiobook\\Fragment_On_Artaeum.mp3",
    bk_frontierconquestaccommodat = "Vo\\Audiobook\\Frontier_Conquest.mp3",
    bk_galerionthemystic = "Vo\\Audiobook\\Galerion_the_Mystic.mp3",
    bk_galur_ritharis_papers = "Vo\\Audiobook\\Galur_Rithari_Papers.mp3",
    bk_graspingfortune = "Vo\\Audiobook\\Grasping_Fortune.mp3",
    bk_great_houses = "Vo\\Audiobook\\Great_Houses_Morrowind.mp3",
    bk_guide_to_ald_ruhn = "Vo\\Audiobook\\Guide_To_Aldruhn.mp3",
    bk_guide_to_balmora = "Vo\\Audiobook\\GuidetoBalmora.mp3",
    bk_guide_to_sadrithmora = "Vo\\Audiobook\\Guide_To_Sadrith_Mora.mp3",
    bk_guide_to_vivec = "Vo\\Audiobook\\Guide_To_Vivec.mp3",
    bk_guide_to_vvardenfell = "Vo\\Audiobook\\Guide_To_Vvardenfell.mp3",
    bk_guylainesarchitecture = "Vo\\Audiobook\\Guylaines_Architecture.mp3",
    bk_HomiliesOfBlessedAlmalexia = "Vo\\Audiobook\\Homilies_Blessed_Amalexia.mp3",
    bk_honorthieves = "Vo\\Audiobook\\Honor_Among_Thieves.mp3",
    bk_HouseOfTroubles_c = "Vo\\Audiobook\\The_House_of_Troubles.mp3",
    bk_HouseOfTroubles_o = "Vo\\Audiobook\\The_House_of_Troubles.mp3",
    bk_InvocationOfAzura = "Vo\\Audiobook\\Invocation_of_Azura.mp3",
    bk_istunondescosmology = "Vo\\Audiobook\\A_Less_Rude_Song.mp3",
    bk_legionsofthedead = "Vo\\Audiobook\\Legions_Of_The_Dead.mp3",
    bk_LivesOfTheSaints = "Vo\\Audiobook\\Lives_of_the_saints.mp3",
    bk_lustyargonianmaid = "Vo\\Audiobook\\Lusty_Argonian_Maid.mp3",
    bk_MixedUnitTactics = "Vo\\Audiobook\\Mixed_Unit_Tactics.mp3",
    bk_MysteriousAkavir = "Vo\\Audiobook\\Mysterious_Akavir.mp3",
    bk_Mysticism = "Vo\\Audiobook\\Mysticism_Unfath_Voyage.mp3",
    bk_NerevarMoonandStar = "Vo\\Audiobook\\Nerevar_MoonStar.mp3",
    bk_NGastaKvataKvakis_c = "Vo\\Audiobook\\NGasta_Kvata_Kvakis.mp3",
    bk_NGastaKvataKvakis_o = "Vo\\Audiobook\\NGasta_Kvata_Kvakis.mp3",
    bk_OnMorrowind = "Vo\\Audiobook\\On_Morrowind.mp3",
    bk_onoblivion = "Vo\\Audiobook\\On_Oblivion.mp3",
    bk_OriginOfTheMagesGuild = "Vo\\Audiobook\\Origin_Mages_Guild.mp3",
    bk_OverviewOfGodsAndWorship = "Vo\\Audiobook\\Overview_Gods_Worship.mp3",
    bk_PigChildren = "Vo\\Audiobook\\The_Pig_Children.mp3",
    bk_PilgrimsPath = "Vo\\Audiobook\\The_Pilgrims_Path.mp3",
    bk_poisonsong1 = "Vo\\Audiobook\\Poison_Song_Book_1.mp3",
    bk_poisonsong2 = "Vo\\Audiobook\\Poison_Song_Book_2.mp3",
    bk_poisonsong3 = "Vo\\Audiobook\\Poison_Song_Book_3.mp3",
    bk_poisonsong4 = "Vo\\Audiobook\\Poison_Song_Book_4.mp3",
    bk_poisonsong5 = "Vo\\Audiobook\\Poison_Song_5.mp3",
    bk_poisonsong6 = "Vo\\Audiobook\\Poison_Song_6.mp3",
    bk_poisonsong7 = "Vo\\Audiobook\\Poison_Song_7.mp3",
    bk_progressoftruth = "Vo\\Audiobook\\Progress_Of_Truth.mp3",
    bk_provinces_of_tamriel = "Vo\\Audiobook\\Provinces_of_Tamriel.mp3",
    bk_RealBarenziah1 = "Vo\\Audiobook\\The_Real_Barenziah_Volume1.mp3",
    bk_realbarenziah2 = "Vo\\Audiobook\\The_Real_Barenziah_Volume2.mp3",
    bk_realbarenziah3 = "Vo\\Audiobook\\the_real_barenziah_v3.mp3",
    bk_realbarenziah4 = "Vo\\Audiobook\\the_real_barenziah_v4.mp3",
    bk_RealBarenziah5 = "Vo\\Audiobook\\The_real_barenziah_v5.mp3",
    bk_RealNerevar = "Vo\\Audiobook\\The_Real_Nerevar.mp3",
    bk_redbookofriddles = "Vo\\Audiobook\\The_Red_Book_Riddles.mp3",
    bk_reflectionsoncultworship = "Vo\\Audiobook\\Reflections_on_Cult_Worship.mp3",
    bk_SamarStarloversJournal = "Vo\\Audiobook\\Starlovers_Log.mp3",
    bk_SaryonisSermons = "Vo\\Audiobook\\Saryonis_Sermons.mp3",
    bk_ShortHistoryMorrowind = "Vo\\Audiobook\\Short_History_Morrowind.mp3",
    bk_specialfloraoftamriel = "Vo\\Audiobook\\Special_Flora_Tamriel.mp3",
    bk_spiritofnirn = "Vo\\Audiobook\\Spirit_Of_Nirn.mp3",
    bk_SpiritOfTheDaedra = "Vo\\Audiobook\\Spirit_Of_The_Daedra.mp3",
    bk_tamrielicreligions = "Vo\\Audiobook\\Ruins_of_Kemel_Ze.mp3",
    bk_truenatureoforcs = "Vo\\Audiobook\\The_True_Nature_Orcs.mp3",
    bk_truenoblescode = "Vo\\Audiobook\\The_True_Nobles_Code.mp3",
    bk_vampiresofvvardenfell1 = "Vo\\Audiobook\\Vampires_Vvardenfell_I.mp3",
    bk_vampiresofvvardenfell2 = "Vo\\Audiobook\\Vampires_Vvardenfell_II.mp3",
    bk_varietiesoffaithintheempire = "Vo\\Audiobook\\Varieties_of_Faith.mp3",
    bk_vivec_murders = "Vo\\Audiobook\\Nerevar_At_Red_Mountain.mp3",
    bk_vivecandmephala = "Vo\\Audiobook\\Vivec_and_Mephala.mp3",
    bk_wherewereyoudragonbroke = "Vo\\Audiobook\\Where_you_when_Dragon_Broke.mp3",
    bk_wildelves = "Vo\\Audiobook\\The_Wild_Elves.mp3",
    BookSkill_Acrobatics2 = "Vo\\Audiobook\\A_Dance_in_Fire_book_1.mp3",
    BookSkill_Acrobatics3 = "Vo\\Audiobook\\A_Dance_in_Fire_Book_4.mp3",
    BookSkill_Acrobatics4 = "Vo\\Audiobook\\The_Black_Arrow_1.mp3",
    BookSkill_Alchemy1 = "Vo\\Audiobook\\A_Game_At_Dinner.mp3",
    BookSkill_Alchemy2 = "Vo\\Audiobook\\The_Cake_and_the_Diamond.mp3",
    BookSkill_Alchemy4 = "Vo\\Audiobook\\VivecSermon2.mp3",
    BookSkill_Alchemy5 = "Vo\\Audiobook\\VivecSermon18.mp3",
    BookSkill_Alteration1 = "Vo\\Audiobook\\Breathing_Water.mp3",
    BookSkill_Alteration3 = "Vo\\Audiobook\\Sithis.mp3",
    BookSkill_Alteration4 = "Vo\\Audiobook\\VivecSermon13.mp3",
    BookSkill_Armorer3 = "Vo\\Audiobook\\VivecSermon6.mp3",
    BookSkill_Armorer4 = "Vo\\Audiobook\\VivecSermon25.mp3",
    BookSkill_Armorer5 = "Vo\\Audiobook\\VivecSermon29.mp3",
    BookSkill_Athletics2 = "Vo\\Audiobook\\A_Dance_in_Fire_Book_3.mp3",
    BookSkill_Athletics3 = "Vo\\Audiobook\\VivecSermon1.mp3",
    BookSkill_Athletics4 = "Vo\\Audiobook\\VivecSermon8.mp3",
    BookSkill_Athletics5 = "Vo\\Audiobook\\VivecSermon31.mp3",
    BookSkill_Axe4 = "Vo\\Audiobook\\VivecSermon5.mp3",
    BookSkill_Axe5 = "Vo\\Audiobook\\VivecSermon16.mp3",
    BookSkill_Axe5_open = "Vo\\Audiobook\\VivecSermon16.mp3",
    BookSkill_Block1 = "Vo\\Audiobook\\Death_Blow_of_Abernanit.mp3",
    BookSkill_Block3 = "Vo\\Audiobook\\A_Dance_in_Fire_Book_2.mp3",
    BookSkill_Block4 = "Vo\\Audiobook\\VivecSermon7.mp3",
    BookSkill_Block5 = "Vo\\Audiobook\\VivecSermon32.mp3",
    BookSkill_Blunt_Weapon4 = "Vo\\Audiobook\\VivecSermon3.mp3",
    BookSkill_Blunt_Weapon5 = "Vo\\Audiobook\\VivecSermon9.mp3",
    BookSkill_Conjuration1 = "Vo\\Audiobook\\Feyfolken_v2.mp3",
    BookSkill_Conjuration2 = "Vo\\Audiobook\\Feyfolken_v3.mp3",
    BookSkill_Conjuration3 = "Vo\\Audiobook\\2920_9_Hearth_Fire.mp3",
    BookSkill_Conjuration4 = "Vo\\Audiobook\\2920_10_FrostFall.mp3",
    BookSkill_Enchant1 = "Vo\\Audiobook\\Feyfolken_v1.mp3",
    bookskill_enchant4 = "Vo\\Audiobook\\VivecSermon19.mp3",
    bookskill_hand_to_hand3 = "Vo\\Audiobook\\Charwich_Koiinge_Letters_v2.mp3",
    bookskill_hand_to_hand4 = "Vo\\Audiobook\\Charwich_Koiinge_Letters_v4.mp3",
    BookSkill_Heavy_Armor2 = "Vo\\Audiobook\\2920_6_MidYear.mp3",
    bookskill_heavy_armor5 = "Vo\\Audiobook\\VivecSermon12.mp3",
    BookSkill_Heavy_Armor3 = "Vo\\Audiobook\\Chimarvamidium.mp3",
    bookskill_light_armor4 = "Vo\\Audiobook\\VivecSermon21.mp3",
    bookskill_light_armor5 = "Vo\\Audiobook\\VivecSermon28.mp3",
    BookSkill_Long_Blade2 = "Vo\\Audiobook\\2920_01_Morning_Star.mp3",
    bookskill_long_blade3 = "Vo\\Audiobook\\VivecSermon17.mp3",
    bookskill_long_blade4 = "Vo\\Audiobook\\VivecSermon20.mp3",
    bookskill_long_blade5 = "Vo\\Audiobook\\VivecSermon23.mp3",
    BookSkill_Marksman2 = "Vo\\Audiobook\\A_Dance_In_Fire_Book_5.mp3",
    bookskill_marksman5 = "Vo\\Audiobook\\The_Black_Arrow_2.mp3",
    bookskill_medium_armor4 = "Vo\\Audiobook\\VivecSermon22.mp3",
    bookskill_medium_armor5 = "Vo\\Audiobook\\VivecSermon33.mp3",
    bookskill_medium_armor1 = "Vo\\Audiobook\\Cherims_Heart_Of_Anequina.mp3",
    BookSkill_Medium_Armor2 = "Vo\\Audiobook\\Bone_Book_I.mp3",
    BookSkill_Medium_Armor3 = "Vo\\Audiobook\\Bone_Book_II.mp3",
    bookskill_mercantile1 = "Vo\\Audiobook\\The_Buying_Game.mp3",
    BookSkill_Mercantile3 = "Vo\\Audiobook\\2920_7_Suns_Height.mp3",
    bookskill_mercantile4 = "Vo\\Audiobook\\A_Dance_In_Fire_Book_6.mp3",
    bookskill_mercantile5 = "Vo\\Audiobook\\A_Dance_In_Fire_Book_7.mp3",
    BookSkill_Mysticism2 = "Vo\\Audiobook\\2920_02_Suns_Dawn.mp3",
    BookSkill_Mysticism3 = "Vo\\Audiobook\\VivecSermon4.mp3",
    BookSkill_Mysticism4 = "Vo\\Audiobook\\VivecSermon36.mp3",
    BookSkill_Mysticism5 = "Vo\\Audiobook\\Charwich_Koiinge_Letters_v3.mp3",
    bookskill_restoration1 = "Vo\\Audiobook\\Withershins.mp3",
    BookSkill_Restoration4 = "Vo\\Audiobook\\2920_04_Rains_Hand.mp3",
    bookskill_security4 = "Vo\\Audiobook\\Chances_Folly.mp3",
    BookSkill_Short_Blade2 = "Vo\\Audiobook\\2920_11_Suns_Dusk.mp3",
    BookSkill_Short_Blade3 = "Vo\\Audiobook\\2920_vol_12.mp3",
    BookSkill_Short_Blade4 = "Vo\\Audiobook\\VivecSermon10.mp3",
    BookSkill_Short_Blade5 = "Vo\\Audiobook\\VivecSermon30.mp3",
    BookSkill_Sneak2 = "Vo\\Audiobook\\2920_8_Last_Seed.mp3",
    BookSkill_Sneak3 = "Vo\\Audiobook\\Azura_and_the_Box.mp3",
    bookskill_sneak4 = "Vo\\Audiobook\\Trap.mp3",
    bookskill_sneak5 = "Vo\\Audiobook\\VivecSermon26.mp3",
    BookSkill_Spear2 = "Vo\\Audiobook\\2920_03_First_Seed.mp3",
    bookskill_spear3 = "Vo\\Audiobook\\VivecSermon14.mp3",
    bookskill_spear4 = "Vo\\Audiobook\\VivecSermon24.mp3",
    bookskill_spear5 = "Vo\\Audiobook\\VivecSermon35.mp3",
    BookSkill_Speechcraft1 = "Vo\\Audiobook\\Biography_Wolf_Queen.mp3",
    BookSkill_Speechcraft3 = "Vo\\Audiobook\\2920_05_Second_Seed.mp3",
    bookskill_speechcraft5 = "Vo\\Audiobook\\VivecSermon27.mp3",
    bookskill_unarmored2 = "Vo\\Audiobook\\Charwich_Koiinge_Letters_v1.mp3",
    bookskill_unarmored3 = "Vo\\Audiobook\\VivecSermon11.mp3",
    bookskill_unarmored4 = "Vo\\Audiobook\\VivecSermon15.mp3",
    bookskill_unarmored5 = "Vo\\Audiobook\\VivecSermon34.mp3"

}

--- @param book_id string
local function getSoundId(book_id) return book_id .. "_" end

local re = require("re")
--- @param dirty_id string
--- replace spaces with _, replace . and ' with none
local function sanitize_id(dirty_id)
    local result = string.gsub(dirty_id, "%s+", "_")
    result = re.gsub(result, "[.,]", "")
    return result
end

------------------------------------------------------------------------------------

local function removeSoundInternal()
    if last_played_sound_id ~= nil then
        -- tes3.removeSound({ sound = last_played_sound_id, reference = tes3.player })
        tes3.removeSound({reference = tes3.player})
    end
end

local function playSoundInternal()
    if temp_book_id ~= nil then
        local sound_path = sound_map[temp_book_id]
        if sound_path ~= nil then
            local sound_id = getSoundId(temp_book_id)

            removeSoundInternal()

            -- play new sound
            -- local sound_obj = tes3.createObject { id = sound_id, objectType = tes3.objectType.sound, filename = sound_path }
            -- local success = tes3.playSound({ sound = sound_obj, reference = tes3.player })

            tes3.say({reference = tes3.player, soundPath = sound_path})

            -- if success then
            last_played_sound_id = sound_id
            -- end
        end
    end
end

------------------------------------------------------------------------------------

--- @param e equipEventData
local function equipCallback(e)
    if (e.item.objectType ~= tes3.objectType.book) then return end

    local sanitized_id = sanitize_id(e.item.id)
    local sound_path = sound_map[sanitized_id]

    -- debug.log(e.item.id)
    -- debug.log(sanitized_id)
    -- debug.log(sound_path)

    if sound_path ~= nil then
        temp_book_id = sanitized_id
    else
        temp_book_id = nil
    end

end
event.register(tes3.event.equip, equipCallback, {priority = 100})

--- @param e activateEventData
local function activateCallback(e)
    if (e.target.baseObject.objectType ~= tes3.objectType.book) then return end

    local sanitized_id = sanitize_id(e.target.id)
    local sound_path = sound_map[sanitized_id]

    -- debug.log(e.item.id)
    -- debug.log(sanitized_id)
    -- debug.log(sound_path)

    if sound_path ~= nil then
        temp_book_id = sanitized_id
    else
        temp_book_id = nil
    end
end
event.register(tes3.event.activate, activateCallback)

------------------------------------------------------------------------------------

-- OK button callback.
local function onMenuBookRead(e) playSoundInternal() end

-- Stop button callback.
local function onMenuBookStop(e) removeSoundInternal() end

------------------------------------------------------------------------------------

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)

    if (e.element.name ~= "MenuBook") then return end

    if temp_book_id == nil then return end

    -- add buttons
    if ADD_BUTTONS then
        local bookMenu = e.element

        -- Option 1
        local menu = bookMenu:createRect({id = "rf_bookmenu_read"})
        menu.alpha = 0.0
        menu.autoHeight = true
        menu.autoWidth = true
        menu.absolutePosAlignX = 0.5
        menu.absolutePosAlignY = 0.9
        menu.childAlignX = 0.5

        -- Interactions
        local button_block = menu:createBlock{}
        button_block.widthProportional = 1.0
        button_block.autoHeight = true
        button_block.autoWidth = true
        button_block.childAlignX = 0.5

        local button_color = {55 / 255, 23 / 255, 0 / 255}

        local button_read = button_block:createTextSelect({
            id = "rf_bookmenu_btn_read",
            text = "Read"
        })
        button_read.widget.idle = button_color
        button_read:register(tes3.uiEvent.mouseClick, onMenuBookRead)

        -- separator
        local fill = button_block:createRect();
        fill.width = 260
        fill.height = 20
        fill.alpha = 0.0

        local button_stop = button_block:createTextSelect({
            id = "rf_bookmenu_btn_stop",
            text = "Stop"
        })
        button_stop.widget.idle = button_color
        button_stop:register(tes3.uiEvent.mouseClick, onMenuBookStop)

        menu:updateLayout()
        bookMenu:updateLayout()
    end

end
event.register(tes3.event.uiActivated, uiActivatedCallback)

