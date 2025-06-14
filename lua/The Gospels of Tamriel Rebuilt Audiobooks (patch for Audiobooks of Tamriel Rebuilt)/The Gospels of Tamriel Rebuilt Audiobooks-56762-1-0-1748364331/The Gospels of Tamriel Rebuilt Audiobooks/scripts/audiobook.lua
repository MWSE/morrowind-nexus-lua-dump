local ui = require('openmw.ui')
local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local vfs = require('openmw.vfs')

-- formatted to all lowercase keys
-- regex: \b(\w+)\b\s*=
-- replace: \L$1
local sound_map = {
    bk_abcs = "Vo\\Audiobook\\ABCs_for_Barbarians.mp3",
    bk_aedraanddaedra = "Vo\\Audiobook\\AedraDaedra.mp3",
    bk_affairsofwizards = "Vo\\Audiobook\\The_Affairs_of_Wizards.mp3",
    bk_ancestorsandthedunmer = "Vo\\Audiobook\\Ancestors_and_the_Dunmer.mp3",
    bk_annotatedanuad = "Vo\\Audiobook\\The_Annotated_Anuad.mp3",
    bk_antecedantsdwemerlaw = "Vo\\Audiobook\\Antecedents_Dwemer.mp3",
    bk_anticipations = "Vo\\Audiobook\\The_Anticipations.mp3",
    bk_arcanarestored = "Vo\\Audiobook\\Arcana_Restored.mp3",
    bk_arcturianheresy = "Vo\\Audiobook\\The_Arcturian_Heresy.mp3",
    bk_arkaytheenemy = "Vo\\Audiobook\\Arkay_the_Enemy.mp3",
    bk_ashland_hymns = "Vo\\Audiobook\\AshHymns.mp3",
    bk_bartendersguide = "Vo\\Audiobook\\Hanins_Wake.mp3",
    bk_biographybarenziah1 = "Vo\\Audiobook\\BioBarenziah1.mp3",
    bk_biographybarenziah2 = "Vo\\Audiobook\\BioBarenziah2.mp3",
    bk_biographybarenziah3 = "Vo\\Audiobook\\BioBarenziah3.mp3",
    bk_blasphemousrevenants = "Vo\\Audiobook\\Blasphemous_Revenants.mp3",
    bk_bluebookofriddles = "Vo\\Audiobook\\The_Blue_Book_Riddles.mp3",
    bk_boethiahpillowbook = "Vo\\Audiobook\\Boethiah_Pillow_Book.mp3",
    bk_boethiahs_glory_unique = "Vo\\Audiobook\\Boethiahs_Glory.mp3",
    bk_bookdawnanddusk = "Vo\\Audiobook\\The_Book_of_Dawn_and_Dusk.mp3",
    bk_bookofdaedra = "Vo\\Audiobook\\The_Book_of_Daedra.mp3",
    bk_bookoflifeandservice = "Vo\\Audiobook\\Book_Of_Life_And_Service.mp3",
    bk_briefhistoryempire1 = "Vo\\Audiobook\\Biref_History_Empire_1.mp3",
    bk_briefhistoryempire2 = "Vo\\Audiobook\\Biref_History_Empire_2.mp3",
    bk_briefhistoryempire3 = "Vo\\Audiobook\\Biref_History_Empire_3.mp3",
    bookskill_heavy_armor1 = "Vo\\Audiobook\\Hallgerds_Tale.mp3",
    bookskill_heavy_armor4 = "Vo\\Audiobook\\How_Orsinium_Passed_Orcs.mp3",
    bookskill_light_armor2 = "Vo\\Audiobook\\Ice_and_Chitin.mp3",
    bk_im_my_own_grandpa = "Vo\\Audiobook\\Im_My_Own_Grandpa.mp3",
    bookskill_illusion3 = "Vo\\Audiobook\\Incident_in_Necrom.mp3",
    bookskill_armorer2 = "Vo\\Audiobook\\Last_Scabbard_of_Akrash.mp3",
    bookskill_light_armor3 = "Vo\\Audiobook\\Lord_Jornibrets_Last_Dance.mp3",
    bookskill_hand_to_hand5 = "Vo\\Audiobook\\Master_Zoarayms_Tale.mp3",
    bookskill_acrobatics5 = "Vo\\Audiobook\\Mystery_of_Talara_v1.mp3",
    bookskill_restoration5 = "Vo\\Audiobook\\Mystery_of_Talara_v2.mp3",
    bookskill_destruction5 = "Vo\\Audiobook\\Mystery_of_Talara_v3.mp3",
    bookskill_destruction5_open = "Vo\\Audiobook\\Mystery_of_Talara_v3.mp3",
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
    bookskill_alchemy3 = "Vo\\Audiobook\\Song_of_the_Alchemist.mp3",
    bookskill_security5 = "Vo\\Audiobook\\Surfeit_of_Thieves.mp3",
    bk_talmarogkersresearches = "Vo\\Audiobook\\Tal_Marog_Kers_Researches.mp3",
    bk_yagrums_book = "Vo\\Audiobook\\Tamrielic_Lore.mp3",
    bk_alchemistsformulary = "Vo\\Audiobook\\The_Alchemists_Formulary.mp3",
    bookskill_armorer1 = "Vo\\Audiobook\\The_Armorers_Challenge.mp3",
    bookskill_destruction4 = "Vo\\Audiobook\\The_Art_of_War_Magic.mp3",
    bookskill_axe2 = "Vo\\Audiobook\\The_Axe_Man.mp3",
    bk_balladeers_fakebook = "Vo\\Audiobook\\The_Balladeers_Fakebook.mp3",
    bk_blackglove = "Vo\\Audiobook\\The_Black_Glove.mp3",
    bookskill_security3 = "Vo\\Audiobook\\The_Dowry.mp3",
    bookskill_alteration2 = "Vo\\Audiobook\\The_Dragon_Break_Reexamined.mp3",
    bookskill_enchant5 = "Vo\\Audiobook\\The_Final_Lesson.mp3",
    bookskill_mysticism1 = "Vo\\Audiobook\\The_Firsthold_Revolt.mp3",
    bookskill_restoration3 = "Vo\\Audiobook\\The_Four_Suitors_Benitah.mp3",
    bookskill_marksman1 = "Vo\\Audiobook\\The_Gold_Ribbon_of_Merit.mp3",
    bookskill_blunt_weapon1 = "Vo\\Audiobook\\The_Hope_of_the_Redoran.mp3",
    bk_playscript = "Vo\\Audiobook\\The_Horror_Castle_Xyr.mp3",
    bookskill_destruction1 = "Vo\\Audiobook\\The_Horror_Castle_Xyr.mp3",
    bookskill_blunt_weapon2 = "Vo\\Audiobook\\The_Importance_of_Where.mp3",
    bk_legendaryscourge = "Vo\\Audiobook\\The_Legendary_Scourge.mp3",
    bookskill_security1 = "Vo\\Audiobook\\The_Locked_Room.mp3",
    bookskill_alteration5 = "Vo\\Audiobook\\The_Lunar_Lorkhan.mp3",
    bk_madnessofpelagius = "Vo\\Audiobook\\The_Madness_Pelagius.mp3",
    bookskill_marksman4 = "Vo\\Audiobook\\The_Marksmanship_Lesson.mp3",
    bk_manyfacesmissinggod = "Vo\\Audiobook\\The_Monomyth.mp3",
    bookskill_block2 = "Vo\\Audiobook\\The_Mirror.mp3",
    bk_oldways = "Vo\\Audiobook\\The_Old_Ways.mp3",
    bk_postingofthehunt = "Vo\\Audiobook\\The_Posting_of_the_Hunt.mp3",
    bookskill_hand_to_hand1 = "Vo\\Audiobook\\The_Prayers_of_Baranat.mp3",
    bookskill_athletics1 = "Vo\\Audiobook\\The_Ransom_of_Zarek.mp3",
    bookskill_light_armor1 = "Vo\\Audiobook\\The_Rear_Guard.mp3",
    bookskill_axe3 = "Vo\\Audiobook\\The_Seed.mp3",
    bookskill_axe1 = "Vo\\Audiobook\\The_Third_Door.mp3",
    bk_vagariesofmagica = "Vo\\Audiobook\\The_Vagaries_of_Magicka.mp3",
    bookskill_conjuration5 = "Vo\\Audiobook\\The_Warriors_Charge.mp3",
    bk_watersofoblivion = "Vo\\Audiobook\\The_Waters_of_Oblivion.mp3",
    bookskill_security2 = "Vo\\Audiobook\\The_Wolf_Queen_v1.mp3",
    bookskill_hand_to_hand2 = "Vo\\Audiobook\\The_Wolf_Queen_v2.mp3",
    bookskill_illusion1 = "Vo\\Audiobook\\The_Wolf_Queen_v3.mp3",
    bookskill_mercantile2 = "Vo\\Audiobook\\The_Wolf_Queen_v4.mp3",
    bookskill_speechcraft2 = "Vo\\Audiobook\\The_Wolf_Queen_v5.mp3",
    bookskill_sneak1 = "Vo\\Audiobook\\The_Wolf_Queen_v6.mp3",
    bookskill_speechcraft4 = "Vo\\Audiobook\\The_Wolf_Queen_v7.mp3",
    bookskill_enchant2 = "Vo\\Audiobook\\The_Wolf_Queen_v8.mp3",
    bookskill_unarmored1 = "Vo\\Audiobook\\The_Wraiths_Wedding_Dowry.mp3",
    bookskill_short_blade1 = "Vo\\Audiobook\\Unnamed_Book.mp3",
    bookskill_marksman3 = "Vo\\Audiobook\\Vernaccus_and_Bourlor.mp3",
    bk_warofthefirstcouncil = "Vo\\Audiobook\\War_of_the_First_Council.mp3",
    bookskill_long_blade1 = "Vo\\Audiobook\\Words_and_Philosophy.mp3",
    bk_wordsclanmother = "Vo\\Audiobook\\Words_Clan_Mom_Ahnissi.mp3",
    bk_words_of_the_wind = "Vo\\Audiobook\\Words_of_the_Wind.mp3",
    bk_yellowbookofriddles = "Vo\\Audiobook\\Yellow_Book_of_Riddles.mp3",
    bk_briefhistoryempire4 = "Vo\\Audiobook\\Biref_History_Empire_4.mp3",
    bk_briefhistoryofwood = "Vo\\Audiobook\\Picture_Book_of_Wood.mp3",
    bk_briefhistoryofwood_01 = "Vo\\Audiobook\\Picture_Book_of_Wood.mp3",
    bk_brothersofdarkness = "Vo\\Audiobook\\The_Brothers_Darkness.mp3",
    bk_cantatasofvivec = "Vo\\Audiobook\\The_Cantatas_of_Vivec.mp3",
    bk_changedones = "Vo\\Audiobook\\The_Changed_Ones.mp3",
    bk_charterfg = "Vo\\Audiobook\\Fighters_Guild_Charter.mp3",
    bk_chartermg = "Vo\\Audiobook\\Mages_Guild_Charter.mp3",
    bk_childrenofthesky = "Vo\\Audiobook\\Children_Of_Sky.mp3",
    bk_childrensanuad = "Vo\\Audiobook\\The_Annotated_Anuad.mp3",
    bk_chroniclesnchuleft = "Vo\\Audiobook\\Chronicles_of_Nchuleft.mp3",
    bk_confessions = "Vo\\Audiobook\\Confessions_Skooma_Eater.mp3",
    bk_consolationsofprayer = "Vo\\Audiobook\\The_Consolations_of_Prayer.mp3",
    bk_corpsepreperation1_c = "Vo\\Audiobook\\Corpse_Preparation_1.mp3",
    bk_corpsepreperation1_o = "Vo\\Audiobook\\Corpse_Preparation_1.mp3",
    bk_corpsepreperation2_c = "Vo\\Audiobook\\Corpse_Preparation_2.mp3",
    bk_corpsepreperation3_c = "Vo\\Audiobook\\Corpse_Preparation_3.mp3",
    bk_darkestdarkness = "Vo\\Audiobook\\Darkest_Darkness.mp3",
    bk_doorsofthespirit = "Vo\\Audiobook\\The_Doors_Of_Spirit.mp3",
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
    bk_homiliesofblessedalmalexia = "Vo\\Audiobook\\Homilies_Blessed_Amalexia.mp3",
    bk_honorthieves = "Vo\\Audiobook\\Honor_Among_Thieves.mp3",
    bk_houseoftroubles_c = "Vo\\Audiobook\\The_House_of_Troubles.mp3",
    bk_houseoftroubles_o = "Vo\\Audiobook\\The_House_of_Troubles.mp3",
    bk_invocationofazura = "Vo\\Audiobook\\Invocation_of_Azura.mp3",
    bk_istunondescosmology = "Vo\\Audiobook\\A_Less_Rude_Song.mp3",
    bk_legionsofthedead = "Vo\\Audiobook\\Legions_Of_The_Dead.mp3",
    bk_livesofthesaints = "Vo\\Audiobook\\Lives_of_the_saints.mp3",
    bk_lustyargonianmaid = "Vo\\Audiobook\\Lusty_Argonian_Maid.mp3",
    bk_mixedunittactics = "Vo\\Audiobook\\Mixed_Unit_Tactics.mp3",
    bk_mysteriousakavir = "Vo\\Audiobook\\Mysterious_Akavir.mp3",
    bk_mysticism = "Vo\\Audiobook\\Mysticism_Unfath_Voyage.mp3",
    bk_nerevarmoonandstar = "Vo\\Audiobook\\Nerevar_MoonStar.mp3",
    bk_ngastakvatakvakis_c = "Vo\\Audiobook\\NGasta_Kvata_Kvakis.mp3",
    bk_ngastakvatakvakis_o = "Vo\\Audiobook\\NGasta_Kvata_Kvakis.mp3",
    bk_onmorrowind = "Vo\\Audiobook\\On_Morrowind.mp3",
    bk_onoblivion = "Vo\\Audiobook\\On_Oblivion.mp3",
    bk_originofthemagesguild = "Vo\\Audiobook\\Origin_Mages_Guild.mp3",
    bk_overviewofgodsandworship = "Vo\\Audiobook\\Overview_Gods_Worship.mp3",
    bk_pigchildren = "Vo\\Audiobook\\The_Pig_Children.mp3",
    bk_pilgrimspath = "Vo\\Audiobook\\The_Pilgrims_Path.mp3",
    bk_poisonsong1 = "Vo\\Audiobook\\Poison_Song_Book_1.mp3",
    bk_poisonsong2 = "Vo\\Audiobook\\Poison_Song_Book_2.mp3",
    bk_poisonsong3 = "Vo\\Audiobook\\Poison_Song_Book_3.mp3",
    bk_poisonsong4 = "Vo\\Audiobook\\Poison_Song_Book_4.mp3",
    bk_poisonsong5 = "Vo\\Audiobook\\Poison_Song_5.mp3",
    bk_poisonsong6 = "Vo\\Audiobook\\Poison_Song_6.mp3",
    bk_poisonsong7 = "Vo\\Audiobook\\Poison_Song_7.mp3",
    bk_progressoftruth = "Vo\\Audiobook\\Progress_Of_Truth.mp3",
    bk_provinces_of_tamriel = "Vo\\Audiobook\\Provinces_of_Tamriel.mp3",
    bk_realbarenziah1 = "Vo\\Audiobook\\The_Real_Barenziah_Volume1.mp3",
    bk_realbarenziah2 = "Vo\\Audiobook\\The_Real_Barenziah_Volume2.mp3",
    bk_realbarenziah3 = "Vo\\Audiobook\\the_real_barenziah_v3.mp3",
    bk_realbarenziah4 = "Vo\\Audiobook\\the_real_barenziah_v4.mp3",
    bk_realbarenziah5 = "Vo\\Audiobook\\The_real_barenziah_v5.mp3",
    bk_realnerevar = "Vo\\Audiobook\\The_Real_Nerevar.mp3",
    bk_redbookofriddles = "Vo\\Audiobook\\The_Red_Book_Riddles.mp3",
    bk_reflectionsoncultworship = "Vo\\Audiobook\\Reflections_on_Cult_Worship.mp3",
    bk_samarstarloversjournal = "Vo\\Audiobook\\Starlovers_Log.mp3",
    bk_saryonissermons = "Vo\\Audiobook\\Saryonis_Sermons.mp3",
    bk_shorthistorymorrowind = "Vo\\Audiobook\\Short_History_Morrowind.mp3",
    bk_specialfloraoftamriel = "Vo\\Audiobook\\Special_Flora_Tamriel.mp3",
    bk_spiritofnirn = "Vo\\Audiobook\\Spirit_Of_Nirn.mp3",
    bk_spiritofthedaedra = "Vo\\Audiobook\\Spirit_Of_The_Daedra.mp3",
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
    bookskill_acrobatics2 = "Vo\\Audiobook\\A_Dance_in_Fire_book_1.mp3",
    bookskill_acrobatics3 = "Vo\\Audiobook\\A_Dance_in_Fire_Book_4.mp3",
    bookskill_acrobatics4 = "Vo\\Audiobook\\The_Black_Arrow_1.mp3",
    bookskill_alchemy1 = "Vo\\Audiobook\\A_Game_At_Dinner.mp3",
    bookskill_alchemy2 = "Vo\\Audiobook\\The_Cake_and_the_Diamond.mp3",
    bookskill_alchemy4 = "Vo\\Audiobook\\VivecSermon2.mp3",
    bookskill_alchemy5 = "Vo\\Audiobook\\VivecSermon18.mp3",
    bookskill_alteration1 = "Vo\\Audiobook\\Breathing_Water.mp3",
    bookskill_alteration3 = "Vo\\Audiobook\\Sithis.mp3",
    bookskill_alteration4 = "Vo\\Audiobook\\VivecSermon13.mp3",
    bookskill_armorer3 = "Vo\\Audiobook\\VivecSermon6.mp3",
    bookskill_armorer4 = "Vo\\Audiobook\\VivecSermon25.mp3",
    bookskill_armorer5 = "Vo\\Audiobook\\VivecSermon29.mp3",
    bookskill_athletics2 = "Vo\\Audiobook\\A_Dance_in_Fire_Book_3.mp3",
    bookskill_athletics3 = "Vo\\Audiobook\\VivecSermon1.mp3",
    bookskill_athletics4 = "Vo\\Audiobook\\VivecSermon8.mp3",
    bookskill_athletics5 = "Vo\\Audiobook\\VivecSermon31.mp3",
    bookskill_axe4 = "Vo\\Audiobook\\VivecSermon5.mp3",
    bookskill_axe5 = "Vo\\Audiobook\\VivecSermon16.mp3",
    bookskill_axe5_open = "Vo\\Audiobook\\VivecSermon16.mp3",
    bookskill_block1 = "Vo\\Audiobook\\Death_Blow_of_Abernanit.mp3",
    bookskill_block3 = "Vo\\Audiobook\\A_Dance_in_Fire_Book_2.mp3",
    bookskill_block4 = "Vo\\Audiobook\\VivecSermon7.mp3",
    bookskill_block5 = "Vo\\Audiobook\\VivecSermon32.mp3",
    bookskill_blunt_weapon4 = "Vo\\Audiobook\\VivecSermon3.mp3",
    bookskill_blunt_weapon5 = "Vo\\Audiobook\\VivecSermon9.mp3",
    bookskill_conjuration1 = "Vo\\Audiobook\\Feyfolken_v2.mp3",
    bookskill_conjuration2 = "Vo\\Audiobook\\Feyfolken_v3.mp3",
    bookskill_conjuration3 = "Vo\\Audiobook\\2920_9_Hearth_Fire.mp3",
    bookskill_conjuration4 = "Vo\\Audiobook\\2920_10_FrostFall.mp3",
    bookskill_enchant1 = "Vo\\Audiobook\\Feyfolken_v1.mp3",
    bookskill_enchant4 = "Vo\\Audiobook\\VivecSermon19.mp3",
    bookskill_hand_to_hand3 = "Vo\\Audiobook\\Charwich_Koiinge_Letters_v2.mp3",
    bookskill_hand_to_hand4 = "Vo\\Audiobook\\Charwich_Koiinge_Letters_v4.mp3",
    bookskill_heavy_armor2 = "Vo\\Audiobook\\2920_6_MidYear.mp3",
    bookskill_heavy_armor5 = "Vo\\Audiobook\\VivecSermon12.mp3",
    bookskill_heavy_armor3 = "Vo\\Audiobook\\Chimarvamidium.mp3",
    bookskill_light_armor4 = "Vo\\Audiobook\\VivecSermon21.mp3",
    bookskill_light_armor5 = "Vo\\Audiobook\\VivecSermon28.mp3",
    bookskill_long_blade2 = "Vo\\Audiobook\\2920_01_Morning_Star.mp3",
    bookskill_long_blade3 = "Vo\\Audiobook\\VivecSermon17.mp3",
    bookskill_long_blade4 = "Vo\\Audiobook\\VivecSermon20.mp3",
    bookskill_long_blade5 = "Vo\\Audiobook\\VivecSermon23.mp3",
    bookskill_marksman2 = "Vo\\Audiobook\\A_Dance_In_Fire_Book_5.mp3",
    bookskill_marksman5 = "Vo\\Audiobook\\The_Black_Arrow_2.mp3",
    bookskill_medium_armor4 = "Vo\\Audiobook\\VivecSermon22.mp3",
    bookskill_medium_armor5 = "Vo\\Audiobook\\VivecSermon33.mp3",
    bookskill_medium_armor1 = "Vo\\Audiobook\\Cherims_Heart_Of_Anequina.mp3",
    bookskill_medium_armor2 = "Vo\\Audiobook\\Bone_Book_I.mp3",
    bookskill_medium_armor3 = "Vo\\Audiobook\\Bone_Book_II.mp3",
    bookskill_mercantile1 = "Vo\\Audiobook\\The_Buying_Game.mp3",
    bookskill_mercantile3 = "Vo\\Audiobook\\2920_7_Suns_Height.mp3",
    bookskill_mercantile4 = "Vo\\Audiobook\\A_Dance_In_Fire_Book_6.mp3",
    bookskill_mercantile5 = "Vo\\Audiobook\\A_Dance_In_Fire_Book_7.mp3",
    bookskill_mysticism2 = "Vo\\Audiobook\\2920_02_Suns_Dawn.mp3",
    bookskill_mysticism3 = "Vo\\Audiobook\\VivecSermon4.mp3",
    bookskill_mysticism4 = "Vo\\Audiobook\\VivecSermon36.mp3",
    bookskill_mysticism5 = "Vo\\Audiobook\\Charwich_Koiinge_Letters_v3.mp3",
    bookskill_restoration1 = "Vo\\Audiobook\\Withershins.mp3",
    bookskill_restoration4 = "Vo\\Audiobook\\2920_04_Rains_Hand.mp3",
    bookskill_security4 = "Vo\\Audiobook\\Chances_Folly.mp3",
    bookskill_short_blade2 = "Vo\\Audiobook\\2920_11_Suns_Dusk.mp3",
    bookskill_short_blade3 = "Vo\\Audiobook\\2920_vol_12.mp3",
    bookskill_short_blade4 = "Vo\\Audiobook\\VivecSermon10.mp3",
    bookskill_short_blade5 = "Vo\\Audiobook\\VivecSermon30.mp3",
    bookskill_sneak2 = "Vo\\Audiobook\\2920_8_Last_Seed.mp3",
    bookskill_sneak3 = "Vo\\Audiobook\\Azura_and_the_Box.mp3",
    bookskill_sneak4 = "Vo\\Audiobook\\Trap.mp3",
    bookskill_sneak5 = "Vo\\Audiobook\\VivecSermon26.mp3",
    bookskill_spear2 = "Vo\\Audiobook\\2920_03_First_Seed.mp3",
    bookskill_spear3 = "Vo\\Audiobook\\VivecSermon14.mp3",
    bookskill_spear4 = "Vo\\Audiobook\\VivecSermon24.mp3",
    bookskill_spear5 = "Vo\\Audiobook\\VivecSermon35.mp3",
    bookskill_speechcraft1 = "Vo\\Audiobook\\Biography_Wolf_Queen.mp3",
    bookskill_speechcraft3 = "Vo\\Audiobook\\2920_05_Second_Seed.mp3",
    bookskill_speechcraft5 = "Vo\\Audiobook\\VivecSermon27.mp3",
    bookskill_unarmored2 = "Vo\\Audiobook\\Charwich_Koiinge_Letters_v1.mp3",
    bookskill_unarmored3 = "Vo\\Audiobook\\VivecSermon11.mp3",
    bookskill_unarmored4 = "Vo\\Audiobook\\VivecSermon15.mp3",
    bookskill_unarmored5 = "Vo\\Audiobook\\VivecSermon34.mp3",
    t_bk_arkhonlimtr = "Vo\\Audiobook\\A_Biography_of_Arkhonius_Lim.mp3",
    t_bk_commentarycovenantspc = "Vo\\Audiobook\\A_Commentary_on_the_Covenants.mp3",
    t_bk_dubioustaletr = "Vo\\Audiobook\\A_Dubious_Tale.mp3",
    t_bk_dunceinmorrowindtr_v1 = "Vo\\Audiobook\\A_Dunce_in_Morrowind_v1.mp3",
    t_bk_dunceinmorrowindtr_v2 = "Vo\\Audiobook\\A_Dunce_in_Morrowind_v2.mp3",
    t_bk_dunceinmorrowindtr_v3 = "Vo\\Audiobook\\A_Dunce_in_Morrowind_v3.mp3",
    t_bk_dunceinmorrowindtr_v4 = "Vo\\Audiobook\\A_Dunce_in_Morrowind_v4.mp3",
    t_bk_dunceinmorrowindtr_v5 = "Vo\\Audiobook\\A_Dunce_in_Morrowind_v5.mp3",
    t_bk_dunceinmorrowindtr_v6 = "Vo\\Audiobook\\A_Dunce_in_Morrowind_v6.mp3",
    t_bk_dunceinmorrowindtr_v7 = "Vo\\Audiobook\\A_Dunce_in_Morrowind_v7.mp3",
    t_bk_dunceinmorrowindtr_v8 = "Vo\\Audiobook\\A_Dunce_in_Morrowind_v8.mp3",
    t_bk_dunmersguidetoreachshotn = "Vo\\Audiobook\\A_Dunmers_Guide_to_The_Reach.mp3",
    t_bk_fablevalenwoodtr = "Vo\\Audiobook\\A_Fable_from_Valenwood.mp3",
    t_bk_handbookofthedevouttr = "Vo\\Audiobook\\A_Handbook_For_The_Devout.mp3",
    t_bk_almalexiahistorytr = "Vo\\Audiobook\\A_History_of_Almalexia.mp3",
    t_bk_historysaturailashotn = "Vo\\Audiobook\\A_History_of_Saturalia.mp3",
    t_bk_justpunishmenttr = "Vo\\Audiobook\\A_Just_Punishment.mp3",
    tr_m4_veranzaris_book_saom6 = "Vo\\Audiobook\\Sixteen_Accords_of_Madness_v6.mp3",
    tr_m4_veranzaris_book_saom12 = "Vo\\Audiobook\\Sixteen_Accords_of_Madness_v12.mp3",
    t_bk_gospelofsaintfelmstr = "Vo\\Audiobook\\The_Gospel_of_Saint_Felms.mp3",
    t_bk_gospelofsaintvelothtr_v1 = "Vo\\Audiobook\\The_Gospel_of_Saint_Veloth_Volume_I.mp3",
    t_bk_gospelofsaintvelothotr_v1 = "Vo\\Audiobook\\The_Gospel_of_Saint_Veloth_Volume_I.mp3",
    t_bk_gospelofsaintvelothtr_v2 = "Vo\\Audiobook\\The_Gospel_of_Saint_Veloth_Volume_II.mp3",
    t_bk_gospelofsaintvelothotr_v2 = "Vo\\Audiobook\\The_Gospel_of_Saint_Veloth_Volume_II.mp3",
    t_bk_fetchersguidetoancestraltr = "Vo\\Audiobook\\A_Fetchers_Guide_to_Ancestral_Tombs.mp3",
    t_bk_saintrilmslessontr = "Vo\\Audiobook\\St_Rilms_Lesson.mp3",
    t_bk_gospelofsaintmeristr = "Vo\\Audiobook\\The_Gospel_of_Saint_Meris.mp3",
    t_bk_gospelofsaintnerevartr = "Vo\\Audiobook\\The_Gospel_of_Saint_Nerevar.mp3",
    t_bk_gospelofsaintseryntr = "Vo\\Audiobook\\The_Gospel_of_Saint_Seryn.mp3",
    t_bk_gospelofsaintroristr = "Vo\\Audiobook\\The_Gospel_of_Saint_Roris.mp3",
    t_bk_gospelofsaintrilmstr = "Vo\\Audiobook\\The_Gospel_of_Saint_Rilms.mp3",
    t_bk_gospelofsaintolmstr = "Vo\\Audiobook\\The_Gospel_of_Saint_Olms.mp3",
    t_bk_gospelofsaintfelmstr = "Vo\\Audiobook\\The_Gospel_of_Saint_Felms.mp3",
    t_bk_gospelofsaintdelyntr = "Vo\\Audiobook\\The_Gospel_of_Saint_Delyn.mp3",
    t_bk_gospelofsaintllothistr = "Vo\\Audiobook\\The_Gospel_of_Saint_Llothis.mp3",
    t_bk_gospelofsaintaralortr = "Vo\\Audiobook\\The_Gospel_of_Saint_Aralor.mp3",
    t_bk_healerstaletr = "Vo\\Audiobook\\The_Healers_Tale.mp3",
    t_bk_regrettr = "Vo\\Audiobook\\Regret.mp3",
    t_bk_mineralsofmorrowindtr = "Vo\\Audiobook\\Minerals_Morrowind.mp3",
    t_bk_mannimarcoshotn = "Vo\\Audiobook\\Mannimarco.mp3",
    t_bk_liminalbridgespc = "Vo\\Audiobook\\Liminal_Bridges.mp3",
    t_bk_kinghelsethbiographytr = "Vo\\Audiobook\\King_Helseth_Bio.mp3",
    t_bk_historyofdaggerfalltr = "Vo\\Audiobook\\History_of_Daggerfall.mp3",
    t_bk_herooftheindoriltr = "Vo\\Audiobook\\Hero_of_the_Indoril.mp3",
    t_bk_herhandstr = "Vo\\Audiobook\\Her_Hands.mp3",
    t_bk_etiquettewithrulerstr = "Vo\\Audiobook\\Etiquette_Rulers.mp3",
    t_bk_beggarprinceshotn = "Vo\\Audiobook\\Beggar_Prince.mp3",
	t_bk_charityandleadershiptr= "Vo\\Audiobook\\CharityAndLeadership.mp3",
	t_bk_dunmerilawprimertr = "Vo\\Audiobook\\Dunmer_law_a_primer.mp3",
	t_bk_emeraldstr = "Vo\\Audiobook\\Emeralds.mp3",
	t_bk_jokestr = "Vo\\Audiobook\\Jokes.mp3"
}

--- @param dirty_id string
--- replace spaces with _, replace . and ' with none
local function sanitize_id(dirty_id)
    local result = string.gsub(dirty_id, "%s+", "_") -- Replace spaces with underscores
    result = string.gsub(result, "[%.']", "")        -- Remove periods and apostrophes
    return result
end

local currentBook = nil
local isReading = false
local playingBook

return {
    eventHandlers = {
        UiModeChanged = function(data)
            if data.newMode == "Book" or data.newMode == "Scroll" then
                currentBook = data.arg
                isReading = true
            else
                isReading = false
            end
        end
    },

    engineHandlers = {
        onKeyPress = function(key)
            if currentBook == nil then
                return
            end

            if key.symbol == 'x' then
                if isReading == true then
                    local record = types.Book.record(currentBook)
                    local name = record.id or "unknown"
                    local book_id = sanitize_id(name)
                    local file = "Sound\\" .. (sound_map[book_id] or "unknown")
                    if vfs.fileExists(file) then
                        core.sound.say(file, self)
                        ui.showMessage("Reading\n" .. record.name)
                        playingBook = record.name
                    else
                        ui.showMessage("This book does not have an audiobook")
                    end
                end
            elseif key.symbol == "c" then
                if core.sound.isSayActive(self) then
                    core.sound.stopSay(self)
                    local record = types.Book.record(currentBook)
                    ui.showMessage("Stopped reading\n" .. playingBook)
                end
            end
        end
    }
}
