-- paste tsv in the [[ ]] block, then: lua convertTsvToLua.lua

local tsvBlock = [[
iron fork	Iron Fork	1	1		12.5	100		ShortBladeOneHand	22.38	[030] Iron	🗡️		0	5				1	iron ore											forging																		x													
iron throwing knife	Iron Throwing Knife	0.3	3		3	15		MarksmanThrown	10.00	[030] Iron	Ammo		0	6				2	iron ore											forging																		x													
iron club	Iron Club	12	10		7.5	40		BluntOneHand	13.60	[030] Iron	🔨		0	7				3	iron ore											forging																		x													
iron boots	Iron Boots	19	20	10		26	heavy	boots	13.90	[030] Iron	Armor		0	7				1	iron ore											forging																		x													
iron_greaves	Iron Greaves	18	44	10		25	heavy	greaves	13.95	[030] Iron	Armor		0	7				1	iron ore											forging																		x													
iron_pauldron_left	Iron Left Pauldron	10	24	10		20	heavy	pauldron	14.42	[030] Iron	Armor		0	7				1	iron ore											forging																		x													
iron_pauldron_right	Iron Right Pauldron	10	24	10		20	heavy	pauldron	14.42	[030] Iron	Armor		0	7				1	iron ore											forging																		x													
iron_gauntlet_right	Iron Right Gauntlet	7	14	10		10	heavy	gauntlet	14.49	[030] Iron	Armor		0	7				1	iron ore											forging																		x													
iron_gauntlet_left	Iron Left Gauntlet	7	14	10		25	heavy	gauntlet	14.69	[030] Iron	Armor		0	7				1	iron ore											forging																		x													
iron broadsword	Iron Broadsword	12	30		15	50		LongBladeOneHand	14.78	[030] Iron	⚔️		0	7				2	iron ore											forging																		x													
iron_helmet	Iron Helmet	5	30	10		25	heavy	helmet	14.82	[030] Iron	Armor		0	7				1	iron ore											forging																		x													
iron_cuirass	Iron Cuirass	30	70	10		200	heavy	cuirass	15.49	[030] Iron	Armor		0	8				2	iron ore											forging																		x													
iron arrow	Iron Arrow	0.1	1		3	0		Arrow	10.00	[030] Iron	Ammo		0	8				2	iron ore	1	racer plumes									forging																		x													
iron bolt	Iron Bolt	0.1	1		3	20		Bolt	10.00	[030] Iron	Ammo		0	8				2	iron ore											forging																		x													
iron dagger	Iron Dagger	3	10		12.5	20		ShortBladeOneHand	16.19	[030] Iron	🗡️		0	8				1	iron ore											forging																		x													
iron_bracer_left	Iron Left Bracer	5	10	10		200	heavy	gauntlet	17.14	[030] Iron	Armor		0	9				1	iron ore											forging																		x													
iron_bracer_right	Iron Right Bracer	5	10	10		200	heavy	gauntlet	17.14	[030] Iron	Armor		0	9				1	iron ore											forging																		x													
iron tanto	Iron Tanto	4	14		13.5	22		ShortBladeOneHand	17.50	[030] Iron	🗡️		0	9				1	iron ore	1	iron dagger									forging																		x													
iron_shield	Iron Shield	15	34	10		500	heavy	shield	20.39	[030] Iron	Armor		0	10				1	iron ore											forging																		x													
iron mace	Iron Mace	15	24		15.6	50		BluntOneHand	24.52	[030] Iron	🔨		0	12				2	iron ore											forging																		x													
iron_towershield	Iron Tower Shield	18	50	12		750	heavy	shield	25.91	[030] Iron	Armor		0	13				1	iron ore	1	iron_shield									forging																		x													
iron longsword	Iron Longsword	20	40		24.3	60		LongBladeOneHand	26.84	[030] Iron	⚔️		0	13				2	iron ore											forging																		x													
iron saber	Iron Saber	15	24		25.2	55		LongBladeOneHand	27.52	[030] Iron	⚔️		0	14				2	iron ore											forging																		x													
Iron Long Spear	Iron Spear	14	20		20	50		SpearTwoWide	28.50	[030] Iron	🔱		0	14				2	iron ore											forging																		x													
iron halberd	Iron Halberd	14	40		20	50		SpearTwoWide	28.50	[030] Iron	🔱		0	14				1	iron ore	1	Iron Long Spear									forging																		x													
iron shortsword	Iron Shortsword	8	20		22	40		ShortBladeOneHand	28.76	[030] Iron	🗡️		0	14				1	iron ore	1	iron tanto									forging																		x													
iron warhammer	Iron Warhammer	32	40		28	55		BluntTwoClose	29.30	[030] Iron	🔨2H		0	15				1	iron ore	1	iron mace									forging																		x													
iron war axe	Iron War Axe	24	30		22.5	50		AxeOneHand	29.90	[030] Iron	🪓		0	15				3	iron ore											forging																		x													
iron claymore	Iron Claymore	27	80		30	70		LongBladeTwoClose	31.38	[030] Iron	⚔️2H		0	16				1	iron ore	1	iron longsword									forging																		x													
iron battle axe	Iron Battle Axe	30	50		32	55		AxeTwoHand	33.88	[030] Iron	🪓2H		0	17				1	iron ore	1	iron war axe									forging																		x													
iron wakizashi	Iron Wakizashi	10	24		27	45		ShortBladeOneHand	34.94	[030] Iron	🗡️		0	17				1	iron ore	1	iron shortsword									forging																		x													
chitin greaves	Chitin Greaves	5.4	29	10		13	light	greaves	19.88	[040] Chitin	Armor		1.5	17				2	Any leather	2	iron ore									forging																		x	A												
chitin pauldron - left	Chitin Left Pauldron	2	16	10		10	light	pauldron	20.07	[040] Chitin	Armor		1.5	17				2	Any leather	2	iron ore									forging																		x	A												
chitin pauldron - right	Chitin Right Pauldron	2	16	10		10	light	pauldron	20.07	[040] Chitin	Armor		1.5	17				2	Any leather	2	iron ore									forging																		x	A												
chitin boots	Chitin Boots	6	13	10		44	light	boots	20.25	[040] Chitin	Armor		1.5	17				2	Any leather	2	iron ore									forging																		x	A												
chitin guantlet - left	Chitin Left Gauntlet	1	9	10		100	light	gauntlet	21.29	[040] Chitin	Armor		1.5	17				1	Any leather	1	iron ore									forging																		x	A												
chitin guantlet - right	Chitin Right Gauntlet	1	9	10		100	light	gauntlet	21.29	[040] Chitin	Armor		1.5	17				1	Any leather	1	iron ore									forging																		x	A												
chitin cuirass	Chitin Cuirass	6	45	10		100	light	cuirass	20.97	[040] Chitin	Armor		1.5	17				3	Any leather	4	iron ore									forging																		x	A												
chitin helm	Chitin Helm	1	19	10		125	light	helmet	21.61	[040] Chitin	Armor		1.5	18				2	Any leather	2	iron ore									forging																		x	A												
chitin_shield	Chitin Shield	4	22	10		250	light	shield	23.01	[040] Chitin	Armor		1.5	19				3	Any leather	3	iron ore									forging																		x	A												
chitin_towershield	Chitin Tower Shield	6	32	12		375	light	shield	27.97	[040] Chitin	Armor		1.5	21				3	Any leather	1	iron ore	1	chitin_shield							forging																		x	A												
steel broadsword	Steel Broadsword	12	60		17.5	50		LongBladeOneHand	17.81	[050] Steel	⚔️		1	13				3	iron ore	2	coal									forging																		x													
steel club	Steel Club	12	20		7.5	40		BluntOneHand	13.60	[050] Steel	🔨		1.5	13				3	iron ore	2	coal									forging																		x													
steel dagger	Steel Dagger	3	20		12.5	20		ShortBladeOneHand	16.19	[050] Steel	🗡️		1.5	14				1	iron ore	1	coal									forging																		x													
steel_greaves	Steel Greaves	18	88	15		25	heavy	greaves	20.52	[050] Steel	Armor		1.5	17				2	iron ore	1	coal									forging																		x													
steel_pauldron_left	Steel Left Pauldron	10	48	15		20	heavy	pauldron	20.97	[050] Steel	Armor		1.5	17				2	iron ore	1	coal									forging																		x													
steel_pauldron_right	Steel Right Pauldron	10	48	15		20	heavy	pauldron	20.97	[050] Steel	Armor		1.5	17				2	iron ore	1	coal									forging																		x									count = 	#REF!	},		
steel_boots	Steel Boots	20	40	15		88	heavy	boots	21.20	[050] Steel	Armor		1.5	17				2	iron ore	1	coal									forging																		x													
steel_cuirass	Steel Cuirass	30	150	15		200	heavy	cuirass	21.99	[050] Steel	Armor		1.5	17				3	iron ore	2	coal									forging																		x													
nordic_ringmail_cuirass	Nordic Ringmail Cuirass	21	80	10		140	medium	cuirass	19.61	[050] Steel	Armor		1.5	17				3	iron ore	2	coal	1	ingred_frost_salts_01							forging																		x	A												
steel_gauntlet_left	Steel Left Gauntlet	5	28	15		200	heavy	gauntlet	23.58	[050] Steel	Armor		1.5	18				1	iron ore	1	coal									forging																		x													
steel_gauntlet_right	Steel Right Gauntlet	5	28	15		200	heavy	gauntlet	23.58	[050] Steel	Armor		1.5	18				1	iron ore	1	coal									forging																		x													
steel_helm	Steel Helm	5	60	15		250	heavy	helmet	24.21	[050] Steel	Armor		1.5	18				2	iron ore	1	coal									forging																		x													
steel_shield	Steel Shield	15	68	15		500	heavy	shield	26.72	[050] Steel	Armor		1.5	20				3	iron ore	2	coal									forging																		x													
steel throwing knife	Steel Throwing Knife	0.3	4		4	15		MarksmanThrown	20.00	[050] Steel	Ammo		1.5	20				3	iron ore	2	coal									forging																		x													
steel axe	Steel Axe	24	60		18	45		AxeOneHand	23.79	[050] Steel	🪓		2	20				4	iron ore	2	coal									forging																		x													
steel spear	Steel Spear	14	40		17	50		SpearTwoWide	23.95	[050] Steel	🔱		2	20				3	iron ore	2	coal									forging																		x													
steel throwing star	Steel Throwing Star	0.1	3		5	15		MarksmanThrown	20.00	[050] Steel			2	21				3	iron ore	2	coal									forging																		x													
nordic broadsword	Nordic Broadsword	15	95		22.5	60		LongBladeOneHand	24.66	[050] Steel	⚔️		2	21				2	iron ore	2	silver ore	1	ingred_frost_salts_01							forging																		x													
steel arrow	Steel Arrow	0.1	2		4	15		Arrow	20.00	[050] Steel	Ammo		2	22				3	iron ore	1	coal	1	racer plumes							forging																		x													
steel bolt	Steel Bolt	0.1	2		4	20		Bolt	20.00	[050] Steel	Ammo		2	22				3	iron ore	2	coal									forging																		x													
steel dart	Steel Dart	0.2	6		5	15		MarksmanThrown	20.00	[050] Steel	Ammo		2	22				3	iron ore	1	coal	1	racer plumes							forging																		x													
steel mace	Steel Mace	15	48		18.2	50		BluntOneHand	27.76	[050] Steel	🔨		2	22				4	iron ore	2	coal									forging																		x													
nordic battle axe	Nordic Battle Axe	30	60		30	55		AxeTwoHand	31.56	[050] Steel	🪓2H		1.5	23				4	iron ore	2	coal	1	ingred_frost_salts_01							forging																		x													
steel_towershield	Steel Tower Shield	20	100	18		750	heavy	shield	33.20	[050] Steel	Armor		1.5	23				1	iron ore	1	coal	1	steel_shield							forging																		x													
nordic_iron_cuirass	Nordic Iron Cuirass	35	130	16		200	heavy	cuirass	22.95	[050] Steel	Armor		2.6	23				3	iron ore	2	coal									forging																		x	A												
steel longsword	Steel Longsword	20	80		27	60		LongBladeOneHand	30.10	[050] Steel	⚔️		2	24				5	iron ore	2	coal									forging																		x													
steel tanto	Steel Tanto	4	28		24.75	22		ShortBladeOneHand	30.55	[050] Steel	🗡️		2	24				3	iron ore	1	coal									forging																		x													
steel saber	Steel Saber	15	48		28	55		LongBladeOneHand	30.91	[050] Steel	⚔️		2	24				5	iron ore	2	coal									forging																		x													
steel crossbow	Steel Crossbow	10	160		20	50		MarksmanCrossbow	30.91	[050] Steel	🏹🎯		2	24				7	iron ore	4	coal									forging																		x													
steel shortsword	Steel Shortsword	8	40		24	40		ShortBladeOneHand	31.08	[050] Steel	🗡️		2	24				3	iron ore	1	coal									forging																		x													
nordic_iron_helm	Nordic Iron Helm	8	50	16		250	heavy	helmet	25.28	[050] Steel	Armor		2.6	24				2	iron ore	1	coal									forging																		x	A												
trollbone_cuirass	Nordic Trollbone Cuirass	32	165	18		160	heavy	cuirass	25.16	[050] Steel	Armor		2.6	25				3	iron ore	10	bonemeal									forging																		x	A												
steel halberd	Steel Halberd	14	80		23	50		SpearTwoWide	33.05	[050] Steel	🔱		2	25				3	iron ore	3	coal									forging																		x													
steel war axe	Steel War Axe	24	60		25	50		AxeOneHand	33.05	[050] Steel	🪓		2	25				5	iron ore	3	coal									forging																		x													
trollbone_helm	Nordic Trollbone Helm	8	65	18		200	heavy	helmet	27.16	[050] Steel	Armor		2.6	25				2	iron ore	7	bonemeal									forging																		x	A												
steel katana	Steel Katana	18	100		30	60		LongBladeOneHand	33.73	[050] Steel	⚔️		2	25				5	iron ore	4	coal									forging																		x													
steel warhammer	Steel Warhammer	32	80		32	55		BluntTwoClose	34.44	[050] Steel	🔨2H		2	26				6	iron ore	4	coal									forging																		x													
steel wakizashi	Steel Wakizashi	10	48		27	45		ShortBladeOneHand	34.94	[050] Steel	🗡️		2	26				4	iron ore	2	coal									forging																		x													
steel longbow	Steel Longbow	8	100		25	35		MarksmanBow	35.41	[050] Steel	🏹		2	26				6	iron ore	3	coal									forging																		x													
steel claymore	Steel Claymore	27	160		33.75	70		LongBladeTwoClose	35.74	[050] Steel	⚔️2H		2	26				5	iron ore	3	coal									forging																		x													
trollbone_shield	Nordic Trollbone Shield	16	78	18		400	heavy	shield	29.15	[050] Steel	Armor		2.6	27				3	iron ore	10	bonemeal									forging																		x	A												
steel battle axe	Steel Battle Axe	30	100		36	55		AxeTwoHand	38.52	[050] Steel	🪓2H		2	28				5	iron ore	3	coal									forging																		x													
steel dai-katana	Steel Dai-katana	20	240		36.45	70		LongBladeTwoClose	38.89	[050] Steel	⚔️2H		2	28				6	iron ore	5	coal									forging																		x													
nordic claymore	Nordic Claymore	30	180		37.5	100		LongBladeTwoClose	42.44	[050] Steel	⚔️2H		1.5	29				5	iron ore	2	coal	1	ingred_frost_salts_01							forging																		x	A												
steel staff	Steel Staff	8	28		12.25	70		BluntTwoWide	49.79	[050] Steel	🦯		1.5	31				3	iron ore	1	coal									forging																		x													
imperial_chain_coif_helm	Imperial Chain Coif	3.5	35	10		175	medium	helmet	21.19	[060] Imperial	Armor		2	20				2	iron ore	2	coal	3	Any leather							forging																		x													
imperial_chain_cuirass	Imperial Chain Cuirass	21	90	12		140	medium	cuirass	23.02	[060] Imperial	Armor		2	22				4	iron ore	3	coal	3	Any leather							forging																		x													
templar_greaves	Imperial Templar Greaves	18	110	18		25	heavy	greaves	24.34	[060] Imperial	Armor		2.6	25				3	iron ore	2	coal	4	racer plumes							forging																		x	A												
templar_pauldron_left	Imperial Templar Left Pauldron	10	60	18		20	heavy	pauldron	24.78	[060] Imperial	Armor		2.6	25				3	iron ore	2	coal	4	racer plumes							forging																		x	A												
templar_pauldron_right	Imperial Templar Right Pauldron	10	60	18		20	heavy	pauldron	24.78	[060] Imperial	Armor		2.6	25				3	iron ore	2	coal	4	racer plumes							forging																		x	A												
templar boots	Imperial Templar Boots	20	50	18		88	heavy	boots	25.01	[060] Imperial	Armor		2.6	25				3	iron ore	2	coal	4	racer plumes							forging																		x	A												
templar_cuirass	Imperial Templar Knight Cuirass	30	175	18		200	heavy	cuirass	25.79	[060] Imperial	Armor		2.6	26				5	iron ore	4	coal	5	racer plumes							forging																		x	A												
templar bracer left	Imperial Templar Left Bracer	5	25	18		200	heavy	gauntlet	27.35	[060] Imperial	Armor		2.6	26				2	iron ore	2	coal	2	racer plumes							forging																		x	A												
templar bracer right	Imperial Templar Right Bracer	5	25	18		200	heavy	gauntlet	27.35	[060] Imperial	Armor		2.6	26				2	iron ore	2	coal	2	racer plumes							forging																		x	A												
imperial_chain_pauldron_left	Imperial Chain Left Pauldron	10	28	20		70	heavy	pauldron	27.91	[060] Imperial	Armor		2.6	26				3	iron ore	2	coal	3	Any leather							forging																		x													
imperial_chain_pauldron_right	Imperial Chain Right Pauldron	10	28	20		70	heavy	pauldron	27.91	[060] Imperial	Armor		2.6	26				3	iron ore	2	coal	3	Any leather							forging																		x													
templar_helmet_armor	Imperial Templar Helmet	5	75	18		250	heavy	helmet	27.97	[060] Imperial	Armor		2.6	26				3	iron ore	2	coal	4	racer plumes							forging																		x													
imperial shield	Imperial Shield	14	78	16		500	heavy	shield	28.03	[060] Imperial	Armor		2.6	26				3	iron ore	2	coal	3	Any leather							forging																		x													
imperial_chain_greaves	Imperial Chain Greaves	10	50	20		70	medium	greaves	36.00	[060] Imperial	Armor		2.6	30				2	iron ore	2	coal	3	Any leather							forging																		x													
bonemold_greaves	Bonemold Greaves	13.4	220	15		20	medium	greaves	27.01	[070] Bonemold	Armor		2	24				7	bonemeal	3	iron ore									forging																		x	A												
bonemold_pauldron_l	Bonemold L Pauldron	8	120	15		16	medium	pauldron	27.30	[070] Bonemold	Armor		2	24				7	bonemeal	3	iron ore									forging																		x	A												
bonemold_pauldron_r	Bonemold R Pauldron	8	120	15		16	medium	pauldron	27.30	[070] Bonemold	Armor		2	24				7	bonemeal	3	iron ore									forging																		x	A												
bonemold_boots	Bonemold Boots	16	100	15		70	medium	boots	27.47	[070] Bonemold	Armor		2	24				7	bonemeal	3	iron ore									forging																		x	A												
bonemold arrow	Bonemold Arrow	0.15	2		4	12		Arrow	30.00	[070] Bonemold	Ammo		3.5	24				6	bonemeal	1	iron ore	1	racer plumes							forging																		x	A												
bonemold bolt	Bonemold Bolt	0.15	2		4	16		Bolt	30.00	[070] Bonemold	Ammo		3.5	24				6	bonemeal	2	iron ore									forging																		x	A												
bonemold_bracer_left	Bonemold Left Bracer	4	50	15		160	medium	gauntlet	29.33	[070] Bonemold	Armor		2	24				4	bonemeal	2	iron ore									forging																		x	A												
bonemold_bracer_right	Bonemold Right Bracer	4	50	15		160	medium	gauntlet	29.33	[070] Bonemold	Armor		2	24				4	bonemeal	2	iron ore									forging																		x	A												
bonemold_shield	Bonemold Shield	10	170	15		400	medium	shield	31.92	[070] Bonemold	Armor		2	26				7	bonemeal	4	iron ore									forging																		x	A												
bonemold_cuirass	Bonemold Cuirass	24	350	16		160	medium	cuirass	29.74	[070] Bonemold	Armor		2	26				12	bonemeal	4	iron ore									forging																		x	A												
bonemold_helm	Bonemold Helm	4	150	18		200	medium	helmet	34.71	[070] Bonemold	Armor		2	28				7	bonemeal	3	iron ore									forging																		x	A												
bonemold_towershield	Bonemold Tower Shield	13	250	17		600	medium	shield	37.39	[070] Bonemold	Armor		2	29				7	bonemeal	4	iron ore	1	bonemold_shield							forging																		x	A												
dragonscale_towershield	Dragonscale Tower Shield	12	230	22		600	medium	shield	45.37	[070] Bonemold	Armor		3	38				10	bonemeal	1	silver ore									forging																		x	A												
bonemold long bow	Bonemold Long Bow	7	250		30	400		MarksmanBow	76.17	[070] Bonemold	🏹		3.5	58				20	bonemeal	10	iron ore									forging																		x	A												
redoran_master_helm	Redoran Master Helm	4.5	3000	45		225	medium	helmet	76.43	[070] Bonemold	Armor		8.6	81				18	bonemeal	2	gold ore	4	ebony ore							forging																		x	A												
ingred_scrap_metal_01	Scrap Metal									[080] Dwemer	Ingredient		2	22				1	misc_dwrv_gear00											forging	4																	x													
dwarven spear	Dwarven Spear	14	300		21	50		SpearTwoWide	30.01	[080] Dwemer	🔱		3	30				8	dwemer scrap metal	4	iron ore									forging	6																	x	A												
dwemer_greaves	Dwemer Greaves	18	660	20		25	heavy	greaves	26.85	[080] Dwemer	Armor		4	32				4	dwemer scrap metal	2	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwemer_pauldron_left	Dwemer Left Pauldron	10	360	20		20	heavy	pauldron	27.29	[080] Dwemer	Armor		4	32				4	dwemer scrap metal	2	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwemer_pauldron_right	Dwemer Right Pauldron	10	360	20		20	heavy	pauldron	27.29	[080] Dwemer	Armor		4	32				4	dwemer scrap metal	2	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwemer_boots	Dwemer Boots	20	300	20		88	heavy	boots	27.51	[080] Dwemer	Armor		4	32				4	dwemer scrap metal	2	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwemer_bracer_left	Dwemer Left Bracer	5	150	20		200	heavy	gauntlet	29.83	[080] Dwemer	Armor		4	33				2	dwemer scrap metal	1	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwemer_bracer_right	Dwemer Right Bracer	5	150	20		200	heavy	gauntlet	29.83	[080] Dwemer	Armor		4	33				2	dwemer scrap metal	1	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwarven shortsword	Dwarven Shortsword	8	300		30	40		ShortBladeOneHand	38.04	[080] Dwemer	🗡️		3	33				4	dwemer scrap metal	2	iron ore									forging	6																	x	A												
dwemer_cuirass	Dwemer Cuirass	30	1050	20		200	heavy	cuirass	28.28	[080] Dwemer	Armor		4	33				7	dwemer scrap metal	4	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwarven mace	Dwarven Mace	15	360		25.5	50		BluntOneHand	36.86	[080] Dwemer	🔨		3	33				8	dwemer scrap metal	4	iron ore									forging	6																	x	A												
dwarven battle axe	Dwarven Battle Axe	30	750		35	55		AxeTwoHand	37.36	[080] Dwemer	🪓2H		3	34				8	dwemer scrap metal	4	iron ore									forging	6																	x	A												
dwemer_helm	Dwemer Helm	5	450	20		250	heavy	helmet	30.45	[080] Dwemer	Armor		4	34				4	dwemer scrap metal	2	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwarven war axe	Dwarven War Axe	24	450		30	50		AxeOneHand	39.36	[080] Dwemer	🪓		3	34				7	dwemer scrap metal	4	iron ore									forging	6																	x	A												
dwemer_shield	Dwemer Shield	15	510	20		500	heavy	shield	32.90	[080] Dwemer	Armor		4	35				6	dwemer scrap metal	3	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwemer_shield_battle_unique	Dwemer Battle Shield	15	510	20		500	heavy	shield	32.90	[080] Dwemer	Armor		4	35				6	dwemer scrap metal	3	coal							the hardcore mod heavily buffs this set		forging																		x	A												
dwarven warhammer	Dwarven Warhammer	32	600		39	55		BluntTwoClose	43.45	[080] Dwemer	🔨2H		3	37				9	dwemer scrap metal	5	iron ore									forging	6																	x	A												
dwarven halberd	Dwarven Halberd	24	600		28	70		SpearTwoWide	42.65	[080] Dwemer	🔱		3	37				9	dwemer scrap metal	5	iron ore	1	dwarven spear							forging	6																	x	A												
dwarven claymore	Dwarven Claymore	27	1200		41.25	70		LongBladeTwoClose	44.48	[080] Dwemer	⚔️2H		3	37				8	dwemer scrap metal	4	iron ore									forging	6																	x	A												
dwarven crossbow	Dwarven Crossbow	10	1200		30	50		MarksmanCrossbow	45.18	[080] Dwemer	🏹🎯		3	38				11	dwemer scrap metal	5	iron ore									forging	6																	x	A												
T_De_AlitHide_Greaves_01	Alit Hide Greaves	5	190	20		20	light	greaves	37.38	[085] Leather	Armor		3.5	35				4	Any leather	1	alit hide	4	bonemeal	3	silver ore																							x													
T_De_AlitHide_PauldronL_01	Alit Hide Left Pauldron	3	125	20		18	light	pauldron	37.48	[085] Leather	Armor		3.5	35				4	Any leather	1	alit hide	4	bonemeal	3	silver ore																							x													
T_De_AlitHide_PauldronR_01	Alit Hide Right Pauldron	3	125	20		18	light	pauldron	37.48	[085] Leather	Armor		3.5	35				4	Any leather	1	alit hide	4	bonemeal	3	silver ore																							x													
T_De_AlitHide_BracerL_01	Alit Hide Left Bracer	1.5	65	20		100	light	gauntlet	38.55	[085] Leather	Armor		3.5	36				2	Any leather	1	alit hide	2	bonemeal	2	silver ore																							x													
T_De_AlitHide_BracerR_01	Alit Hide Right Bracer	1.5	65	20		100	light	gauntlet	38.55	[085] Leather	Armor		3.5	36				2	Any leather	1	alit hide	2	bonemeal	2	silver ore																							x													
T_De_AlitHide_Boots_01	Alit Hide Boots	7	175	20		50	light	boots	37.62	[085] Leather	Armor		3.5	36				4	Any leather	1	alit hide	4	bonemeal	3	silver ore																							x													
T_De_AlitHide_Helm_01	Alit Hide Helm	2	155	20		140	light	helmet	39.00	[085] Leather	Armor		3.5	36				4	Any leather	1	alit hide	4	bonemeal	3	silver ore																							x													
T_De_AlitHide_HelmOpen_01	Alit Hide Open Helm	2	155	20		140	light	helmet	39.00	[085] Leather	Armor		3.5	36				4	Any leather	1	alit hide	4	bonemeal	3	silver ore																							x													
T_De_AlitHide_Cuirass_01	Alit Hide Cuirass	7	225	20		120	light	cuirass	38.46	[085] Leather	Armor		3.5	37				8	Any leather	1	alit hide	6	bonemeal	4	silver ore																							x													
T_De_AlitHide_TowerShield_01	Alit Hide Tower Shield	6	205	20		300	light	shield	40.68	[085] Leather	Armor		3.5	37				4	Any leather	1	alit hide	4	bonemeal	3	silver ore	1	T_De_AlitHide_Shield_01																					x													
T_De_AlitHide_Shield_01	Alit Hide Shield	5	180	20		270	light	shield	40.38	[085] Leather	Armor		3.5	37				6	Any leather	1	alit hide	4	bonemeal	3	silver ore																							x													
silver dagger	Silver Dagger	2.4	40		12.5	16		ShortBladeOneHand	15.88	[090] Silver	🗡️		2.6	20				3	silver ore	2	iron ore									forging																		x	A												
silver shortsword	Silver Shortsword	6	80		20	36		ShortBladeOneHand	26.13	[090] Silver	🗡️		2.6	25				4	silver ore	2	iron ore									forging																		x	A												
silver dart	Silver Dart	0.2	6		5	12		MarksmanThrown	30.00	[090] Silver	Ammo		5	26				4	silver ore	1	iron ore	1	racer plumes							forging																		x	A												
silver longsword	Silver Longsword	16	160		27	48		LongBladeOneHand	29.14	[090] Silver	⚔️		2.6	27				4	silver ore	3	iron ore									forging																		x	A												
silver arrow	Silver Arrow	0.1	3		3	12		Arrow	30.00	[090] Silver	Ammo		5	27				4	silver ore	1	iron ore	1	racer plumes							forging																		x	A												
silver bolt	Silver Bolt	0.1	8		3	16		Bolt	30.00	[090] Silver	Ammo		5	28				4	silver ore	2	iron ore									forging																		x	A												
silver spear	Silver Spear	11.2	80		23	40		SpearTwoWide	32.04	[090] Silver	🔱		2.6	29				6	silver ore	7	iron ore									forging																		x	A												
silver war axe	Silver War Axe	19.2	120		25	40		AxeOneHand	32.21	[090] Silver	🪓		2.6	29				7	silver ore	4	iron ore									forging																		x	A												
silver claymore	Silver Claymore	21.6	320		33.75	56		LongBladeTwoClose	34.66	[090] Silver	⚔️2H		2.6	30				5	silver ore	3	iron ore									forging																		x	A												
BM nordic silver mace	Nordic Silver Mace	30	1000		26	70		BluntOneHand	39.14	[090] Silver	🔨		6	48				4	silver ore	5	iron ore	1	ingred_frost_salts_01							forging	7																	x	A												
BM nordic silver shortsword	Nordic Silver Shortsword	15	1000		30	70		ShortBladeOneHand	40.36	[090] Silver	🗡️		6	48				3	silver ore	4	iron ore	1	ingred_frost_salts_01							forging	7																	x	A												
silver staff	Silver Staff	6.4	56		12.25	56		BluntTwoWide	49.04	[090] Silver	🦯		5	48				7	silver ore	4	iron ore									forging																		x	A												
BM nordic silver dagger	Nordic Silver Dagger	10	1000		37.5	70		ShortBladeOneHand	49.06	[090] Silver	🗡️		6.6	55				3	silver ore	4	iron ore	1	ingred_frost_salts_01							forging	7																	x	A												
BM nordic silver claymore	Nordic Silver Claymore	25	1000		43.75	150		LongBladeTwoClose	53.60	[090] Silver	⚔️2H		6.6	58				7	silver ore	8	iron ore	1	ingred_frost_salts_01							forging	7																	x	A												
BM nordic silver axe	Nordic Silver Axe	32	1000		43.75	65		AxeOneHand	57.99	[090] Silver	🪓		6.6	60				5	silver ore	6	iron ore	1	ingred_frost_salts_01							forging	7																	x	A												
BM nordic silver battleaxe	Nordic Silver Battleaxe	30	1000		50	100		AxeTwoHand	58.22	[090] Silver	🪓2H		6.6	61				8	silver ore	8	iron ore	1	ingred_frost_salts_01							forging	7																	x	A												
silver throwing star	Silver Throwing Star	0.2	16		5	12		MarksmanThrown	30.00	[090] Silver			5	74				5	silver ore	3	iron ore									forging																		x	A												
orcish bolt	Orcish Bolt	0.15	4		6	24		Bolt	40.00	[100] Orcish	Ammo		6.6	45				4	orichalcum ore	2	iron ore									forging																		x													
orcish battle axe	Orcish Battle Axe	15	2000		28	80		AxeTwoHand	31.18	[100] Orcish	🪓2H		6.6	47				8	orichalcum ore	4	iron ore									forging	7																	x													
orcish_greaves	Orcish Greaves	13.45	1760	30		30	medium	greaves	51.07	[100] Orcish	Armor		6	53				4	orichalcum ore	2	coal									forging	7																	x													
orcish_pauldron_left	Orcish Left Pauldron	8	960	30		24	medium	pauldron	51.31	[100] Orcish	Armor		6	53				4	orichalcum ore	2	coal									forging	7																	x													
orcish_pauldron_right	Orcish Right Pauldron	8	960	30		24	medium	pauldron	51.31	[100] Orcish	Armor		6	53				4	orichalcum ore	2	coal									forging	7																	x													
orcish_boots	Orcish Boots	17	800	30		105	medium	boots	51.73	[100] Orcish	Armor		6	53				4	orichalcum ore	2	coal									forging	7																	x													
orcish_bracer_left	Orcish Left Bracer	4.4	400	30		240	medium	gauntlet	54.03	[100] Orcish	Armor		6	54				2	orichalcum ore	1	coal									forging	7																	x													
orcish_bracer_right	Orcish Right Bracer	4.4	400	30		240	medium	gauntlet	54.03	[100] Orcish	Armor		6	54				2	orichalcum ore	1	coal									forging	7																	x													
orcish_cuirass	Orcish Cuirass	26.5	2800	30		240	medium	cuirass	52.75	[100] Orcish	Armor		6	55				7	orichalcum ore	4	coal									forging	7																	x													
orcish_helm	Orcish Helm	4.4	1200	30		300	medium	helmet	54.72	[100] Orcish	Armor		6	55				4	orichalcum ore	2	coal									forging	7																	x													
orcish warhammer	Orc Warhammer	38.4	1600		42	66		BluntTwoClose	48.25	[100] Orcish	🔨2H		6.6	56				9	orichalcum ore	4	iron ore									forging	7																	x													
orcish_towershield	Orcish Tower Shield	13.4	2000	32		900	medium	shield	64.11	[100] Orcish	Armor		6.6	64				10	orichalcum ore	7	coal									forging	7																	x													
T_Imp_Ebonweave_PauldronL_01	Ebonweave Left Pauldron	2	6000	30		13	light	pauldron	53.97	[105] Ebonweave	Armor		6	55				5	Any leather	2	ebony ore	4	gold ore	2	adamantium ore					forging	9																	x													
T_Imp_Ebonweave_PauldronR_01	Ebonweave Right Pauldron	2	6000	30		13	light	pauldron	53.97	[105] Ebonweave	Armor		6	55				5	Any leather	2	ebony ore	4	gold ore	2	adamantium ore					forging	9																	x													
T_Imp_Ebonweave_BracerL_01	Ebonweave Left Bracer	1.5	1500	30		100	light	gauntlet	55.00	[105] Ebonweave	Armor		6	55				3	Any leather	2	ebony ore	2	gold ore	1	adamantium ore					forging	9																	x													
T_Imp_Ebonweave_BracerR_01	Ebonweave Right Bracer	1.5	1500	30		100	light	gauntlet	55.00	[105] Ebonweave	Armor		6	55				3	Any leather	2	ebony ore	2	gold ore	1	adamantium ore					forging	9																	x													
T_Imp_Ebonweave_Greaves_01	Ebonweave Greaves	7	9500	30		80	light	greaves	54.45	[105] Ebonweave	Armor		6	55				5	Any leather	2	ebony ore	4	gold ore	2	adamantium ore					forging	9																	x													
T_Imp_Ebonweave_Boots_01	Ebonweave Boots	2.5	3500	30		80	light	boots	54.71	[105] Ebonweave	Armor		6	56				5	Any leather	2	ebony ore	4	gold ore	2	adamantium ore					forging	9																	x													
T_Imp_Ebonweave_Cuirass_01	Ebonweave Cuirass	12	11500	30		100	light	cuirass	54.39	[105] Ebonweave	Armor		6	56				6	Any leather	2	ebony ore	6	gold ore	4	adamantium ore					forging	9																	x													
T_Imp_Ebonweave_Helm_01	Ebonweave Helm	2	7000	30		115	light	helmet	55.14	[105] Ebonweave	Armor		6	56				5	Any leather	2	ebony ore	4	gold ore	2	adamantium ore					forging	9																	x													
T_Imp_Ebonweave_Helm_02	Ebonweave Open Helm	2	7000	30		115	light	helmet	55.14	[105] Ebonweave	Armor		6	56				5	Any leather	2	ebony ore	4	gold ore	2	adamantium ore					forging	9																	x													
adamantium_mace	Adamantium Mace	23	1000		20	100		BluntOneHand	34.16	[110] Adamantium	🔨		8	54				4	adamantium ore	2	iron ore									forging	8																	x	A												
adamantium_claymore	Adamantium Claymore	50	10000		40	150		LongBladeTwoClose	49.23	[110] Adamantium	⚔️2H		7.2	59				8	adamantium ore	4	iron ore									forging	8																	x	A												
adamantium_spear	Adamantium Spear	25	5000		30	80		SpearTwoWide	46.70	[110] Adamantium	🔱		8	61				8	adamantium ore	4	iron ore									forging	8																	x	A												
adamantium_shortsword	Adamantium Shortsword	20	1000		40	60		ShortBladeOneHand	51.19	[110] Adamantium	🗡️		8	62				4	adamantium ore	2	iron ore									forging	8																	x	A												
adamantium_greaves	Adamantium Greaves	13	10000	40		30	medium	greaves	66.32	[110] Adamantium	Armor		6.6	63				4	adamantium ore	4	iron ore									forging	8																	x	A												
adamantium_bracer_left	Adamantium Left Bracer	4	1000	40		100	medium	gauntlet	67.62	[110] Adamantium	Armor		6.6	64				2	adamantium ore	2	iron ore									forging	8																	x	A												
adamantium_bracer_right	Adamantium Right Bracer	4	1000	40		100	medium	gauntlet	67.62	[110] Adamantium	Armor		6.6	64				2	adamantium ore	2	iron ore									forging	8																	x	A												
adamantium_pauldron_left	Adamantium Left Pauldron	7	800	40		30	medium	pauldron	66.66	[110] Adamantium	Armor		6.6	64				4	adamantium ore	4	iron ore									forging	8																	x	A												
adamantium boots	Adamantium Boots	15	7000	40		100	medium	boots	67.00	[110] Adamantium	Armor		6.6	64				4	adamantium ore	4	iron ore									forging	8																	x	A												
adamantium_pauldron_right	Adamantium Right Pauldron	7	800	40		100	medium	pauldron	67.45	[110] Adamantium	Armor		6.6	64				4	adamantium ore	4	iron ore									forging	8																	x	A												
adamantium_cuirass	Adamantium Cuirass	25	10000	40		300	medium	cuirass	68.69	[110] Adamantium	Armor		6.6	65				7	adamantium ore	7	iron ore									forging	8																	x	A												
adamantium_axe	Admantium Axe	35	5000		60	100		AxeTwoHand	69.82	[110] Adamantium	🪓2H		8	72				8	adamantium ore	4	iron ore									forging	8																	x	A												
adamantium_helm	Adamantium Helm	4	5000	70		500	medium	helmet	115.51	[110] Adamantium	Armor		10.6	108				10	adamantium ore	10	raw glass	10	gold ore	10	silver ore					forging	8																	x	A												
ebony broadsword	Ebony Broadsword	24	15000		32.5	100		LongBladeOneHand	39.98	[120] Ebony	⚔️		8	57				5	ebony ore	3	gold ore									forging	9																	x	A												
ebony spear	Ebony Spear	28	10000		32	100		SpearTwoWide	51.76	[120] Ebony	🔱		9	68				10	ebony ore	4	gold ore									forging	9																	x	A												
ebony arrow	Ebony Arrow	0.2	10		10	30		Arrow	80.00	[120] Ebony	Ammo		9	70				4	ebony ore	1	gold ore	1	racer plumes							forging																		x	A												
ebony dart	Ebony Dart	0.4	2000		10	30		MarksmanThrown	80.00	[120] Ebony	Ammo		9	70				4	ebony ore	1	gold ore	1	racer plumes							forging																		x	A												
ebony mace	Ebony Mace	30	12000		39	100		BluntOneHand	57.83	[120] Ebony	🔨		9	71				10	ebony ore	4	gold ore									forging	9																	x	A												
ebony shortsword	Ebony Shortsword	16	10000		50	80		ShortBladeOneHand	64.34	[120] Ebony	🗡️		9	73				5	ebony ore	2	gold ore									forging	9																	x	A												
6th bell hammer	Sixth House Bell Hammer	75	5000		50	105		BluntTwoClose	61.89	[120] Ebony	🔨2H		9	73				10	ebony ore	4	gold ore									forging	9																	x	A												
ebony war axe	Ebony War Axe	48	15000		46.25	100		AxeOneHand	64.09	[120] Ebony	🪓		9	74				8	ebony ore	3	gold ore									forging	9																	x	A												
ebony longsword	Ebony Longsword	40	20000		49.95	120		LongBladeOneHand	62.71	[120] Ebony	⚔️		9	74				12	ebony ore	5	gold ore									forging	9																	x	A												
ebony_pauldron_left	Ebony Left Pauldron	20	12000	60		40	heavy	pauldron	73.68	[120] Ebony	Armor		9	78				5	ebony ore	2	gold ore									forging	9																	x	A												
ebony_pauldron_right	Ebony Right Pauldron	20	12000	60		40	heavy	pauldron	73.68	[120] Ebony	Armor		9	78				5	ebony ore	2	gold ore									forging	9																	x	A												
ebony_boots	Ebony Boots	40	10000	60		175	heavy	boots	74.07	[120] Ebony	Armor		9	78				5	ebony ore	2	gold ore									forging	9																	x	A												
ebony_greaves	Ebony Greaves	36	22000	60		50	heavy	greaves	72.90	[120] Ebony	Armor		9	79				10	ebony ore	2	gold ore									forging	9																	x	A												
ebony_bracer_left	Ebony Left Bracer	10	5000	60		400	heavy	gauntlet	78.24	[120] Ebony	Armor		9	80				3	ebony ore	1	gold ore									forging	9																	x	A												
ebony_bracer_right	Ebony Right Bracer	10	5000	60		400	heavy	gauntlet	78.24	[120] Ebony	Armor		9	80				3	ebony ore	1	gold ore									forging	9																	x	A												
ebony_cuirass	Ebony Cuirass	60	35000	60		400	heavy	cuirass	75.46	[120] Ebony	Armor		9	80				10	ebony ore	4	gold ore									forging	9																	x	A												
ebony_closed_helm	Ebony Closed Helm	10	15000	60		500	heavy	helmet	79.35	[120] Ebony	Armor		9	81				5	ebony ore	2	gold ore									forging	9																	x	A												
ebony_shield	Ebony Shield	30	17000	60		1000	heavy	shield	83.76	[120] Ebony	Armor		9	84				8	ebony ore	3	gold ore									forging	9																	x	A												
ebony_towershield	Ebony Tower Shield	30	25000	60		1500	heavy	shield	89.25	[120] Ebony	Armor		9.4	89				8	ebony ore	3	gold ore	1	ebony_shield							forging	9																	x	A												
ebony staff	Ebony Staff	16	7000		28	900		BluntTwoWide	106.32	[120] Ebony	🦯		9	95				7	ebony ore	3	gold ore									forging																		x	A												
ebony throwing star	Ebony Throwing Star	0.2	2000		10	30		MarksmanThrown	80.00	[120] Ebony			9	100				7	ebony ore	3	silver ore									forging																		x	A												
Ebony Scimitar	Ebony Scimitar	40	15000		58.05	800		LongBladeOneHand	127.35	[120] Ebony	⚔️		9	106				9	ebony ore	13	gold ore									forging	9																	x	A												
BM ice dagger	Stalhrim Dagger	5	15000		40	65		ShortBladeOneHand	51.57	[130] Stahlrim	🗡️		10	71				3	stahlrim	4	iron ore									forging																		x	A												
BM_Ice_PauldronL	Ice Armor Left Pauldron	8	12000	50		18	medium	pauldron	81.32	[130] Stahlrim	Armor		8	77				2	stahlrim	4	iron ore									forging	9																	x	A												
BM_Ice_PauldronR	Ice Armor Right Pauldron	8	12000	50		18	medium	pauldron	81.32	[130] Stahlrim	Armor		8	77				2	stahlrim	4	iron ore									forging	9																	x	A												
BM_Ice_Boots	Ice Armor Boots	17	5000	50		100	medium	boots	81.72	[130] Stahlrim	Armor		8	77				2	stahlrim	4	iron ore									forging	9																	x	A												
BM_Ice_greaves	Ice Armor Greaves	12	1000	50		100	medium	greaves	82.00	[130] Stahlrim	Armor		8	77				2	stahlrim	4	iron ore									forging	9																	x	A												
BM_Ice_cuirass	Ice Armor Cuirass	27	5000	50		180	medium	cuirass	82.05	[130] Stahlrim	Armor		8	77				2	stahlrim	6	iron ore									forging	9																	x	A												
BM_Ice_gauntletL	Ice Armor Left Gauntlet	4	1000	50		100	medium	gauntlet	82.44	[130] Stahlrim	Armor		8	77				2	stahlrim	3	iron ore									forging	9																	x	A												
BM_Ice_gauntletR	Ice Armor Right Gauntlet	4	1000	50		100	medium	gauntlet	82.44	[130] Stahlrim	Armor		8	77				2	stahlrim	3	iron ore									forging	9																	x	A												
BM_Ice_Helmet	Ice Armor Helmet	4	2000	50		175	medium	helmet	83.27	[130] Stahlrim	Armor		8	78				2	stahlrim	4	iron ore									forging	9																	x	A												
BM_NordicMail_Boots	Nordic Mail Boots	20	5000	66		85	heavy	boots	80.84	[130] Stahlrim	Armor		8.6	79						3	ebony ore	1	BM_Ice_Boots							forging	9																	x	A												
BM_Ice_Shield	Ice Shield	13	1000	50		400	medium	shield	85.25	[130] Stahlrim	Armor		8	79				4	stahlrim	7	iron ore									forging	9																	x	A												
BM_NordicMail_greaves	Nordic Mail Greaves	18	2000	66		80	heavy	greaves	80.90	[130] Stahlrim	Armor		8.6	79						3	ebony ore	1	BM_Ice_greaves							forging	9																	x	A												
BM_NordicMail_Shield	Nordic Mail Shield	20	1000	66		100	heavy	shield	81.01	[130] Stahlrim	Armor		8.6	79						4	ebony ore	1	BM_Ice_Shield							forging	9																	x	A												
BM_NordicMail_PauldronL	Nordic Mail Left Pauldron	10	1000	66		100	heavy	pauldron	81.56	[130] Stahlrim	Armor		8.6	79						3	ebony ore	1	BM_Ice_PauldronL							forging	9																	x	A												
BM_NordicMail_PauldronR	Nordic Mail Right Pauldron	10	1000	66		100	heavy	pauldron	81.56	[130] Stahlrim	Armor		8.6	79						3	ebony ore	1	BM_Ice_PauldronR							forging	9																	x	A												
BM_NordicMail_gauntletL	Nordic Mail Left Gauntlet	8	1000	66		100	heavy	gauntlet	81.67	[130] Stahlrim	Armor		8.6	80						2	ebony ore	1	BM_Ice_gauntletL							forging	9																	x	A												
BM_NordicMail_gauntletR	Nordic Mail Right Gauntlet	8	1000	66		100	heavy	gauntlet	81.67	[130] Stahlrim	Armor		8.6	80						2	ebony ore	1	BM_Ice_gauntletR							forging	9																	x	A												
BM_NordicMail_cuirass	Nordic Mail Cuirass	30	5000	66		300	heavy	cuirass	82.66	[130] Stahlrim	Armor		8.6	80						5	ebony ore	1	BM_Ice_cuirass							forging	9																	x	A												
BM_NordicMail_Helmet	Nordic Mail Helmet	8	1000	66		200	heavy	helmet	82.77	[130] Stahlrim	Armor		8.6	80						3	ebony ore	1	BM_Ice_helmet							forging	9																	x	A												
BM ice war axe	Stalhrim War Axe	35	50000		50	250		AxeOneHand	81.45	[130] Stahlrim	🪓		10	86				4	stahlrim	5	iron ore									forging																		x	A												
BM ice mace	Stalhrim Mace	65	40000		58.5	200		BluntOneHand	90.44	[130] Stahlrim	🔨		10	91				4	stahlrim	6	iron ore									forging																		x	A												
BM ice longsword	Stalhrim Longsword	70	65000		82.5	80		LongBladeOneHand	98.86	[130] Stahlrim	⚔️		10.6	98				5	stahlrim	7	iron ore									forging																		x	A												
glass staff	Glass Staff	4.8	5600		21	42		BluntTwoWide	55.26	[140] Glass	🦯		8	65				6	raw glass	2	silver ore									forging																		x	A												
glass dagger	Glass Dagger	1.8	4000		37.5	12		ShortBladeOneHand	44.57	[140] Glass	🗡️		10	68				4	raw glass	2	silver ore									forging	8																	x	A												
glass throwing knife	Glass Throwing Knife	0.2	25		6	9		MarksmanThrown	60.00	[140] Glass	Ammo		10	68				4	raw glass	2	silver ore									forging																		x	A												
glass arrow	Glass Arrow	0.15	8		6	9		Arrow	60.00	[140] Glass	Ammo		10	70				4	raw glass	1	coal	1	racer plumes							forging																		x	A												
glass war axe	Glass War Axe	14.4	12000		41.25	30		AxeOneHand	51.88	[140] Glass	🪓		10	71				3	raw glass	3	silver ore									forging	10																	x	A												
glass longsword	Glass Longsword	12	16000		44.55	36		LongBladeOneHand	49.40	[140] Glass	⚔️		10	71				9	raw glass	3	silver ore									forging	10																	x	A												
glass halberd	Glass Halberd	8.4	16000		38	30		SpearTwoWide	53.78	[140] Glass	🔱		10	73				4	raw glass	3	silver ore	1	glass staff							forging	10																	x	A												
glass claymore	Glass Claymore	16.2	32000		56.25	42		LongBladeTwoClose	59.77	[140] Glass	⚔️2H		10	77				9	raw glass	4	silver ore									forging	10																	x	A												
glass_bracer_left	Left Glass Bracer	3	4000	50		100	light	gauntlet	86.34	[140] Glass	Armor		10	88				3	raw glass	1	silver ore									forging	10																	x	A												
glass_bracer_right	Right Glass Bracer	3	4000	50		100	light	gauntlet	86.34	[140] Glass	Armor		10	88				3	raw glass	1	silver ore									forging	10																	x	A												
glass_pauldron_left	Glass Left Pauldron	3	9600	50		15	light	pauldron	85.41	[140] Glass	Armor		10	88				5	raw glass	2	silver ore									forging	10																	x	A												
glass_pauldron_right	Glass Right Pauldron	3	9600	50		15	light	pauldron	85.41	[140] Glass	Armor		10	88				5	raw glass	2	silver ore									forging	10																	x	A												
glass_greaves	Glass Greaves	9	17600	50		100	light	greaves	86.02	[140] Glass	Armor		10	89				5	raw glass	2	silver ore									forging	10																	x	A												
glass_boots	Glass Boots	3	8000	50		100	light	boots	86.34	[140] Glass	Armor		10	89				5	raw glass	2	silver ore									forging	10																	x	A												
glass_helm	Glass Helm	3	12000	50		150	light	helmet	86.89	[140] Glass	Armor		10	89				5	raw glass	2	silver ore									forging	10																	x	A												
glass_cuirass	Glass Cuirass	18	28000	50		120	light	cuirass	85.74	[140] Glass	Armor		10	90				9	raw glass	4	silver ore									forging	10																	x	A												
glass_shield	Glass Shield	9	13600	50		300	light	shield	88.21	[140] Glass	Armor		10	91				8	raw glass	3	silver ore									forging	10																	x	A												
glass_towershield	Glass Tower Shield	9	20000	55		450	light	shield	97.46	[140] Glass	Armor		10	96				8	raw glass	3	silver ore	1	glass_shield							forging	10																	x	A												
glass throwing star	Glass Throwing Star	0.1	20		9	9		MarksmanThrown	60.00	[140] Glass			10	100				4	raw glass	1	coal									forging																		x	A												
indoril boots	Indoril Boots	18	2000	45		26	medium	boots	73.47	[150] Indoril	Armor		8	74	8	Temple		4	gold ore	4	adamantium ore	1	ebony ore							forging	10																	x	A												
indoril left gauntlet	Indoril Left Gauntlet	4.5	1400	45		60	medium	gauntlet	74.60	[150] Indoril	Armor		8	74	8	Temple		2	gold ore	2	adamantium ore	1	ebony ore							forging	10																	x	A												
indoril right gauntlet	Indoril Right Gauntlet	4.5	1400	45		60	medium	gauntlet	74.60	[150] Indoril	Armor		8	74	8	Temple		2	gold ore	2	adamantium ore	1	ebony ore							forging	10																	x	A												
indoril pauldron left	Indoril Left Pauldron	9	2400	45		10	medium	pauldron	73.79	[150] Indoril	Armor		8	74	8	Temple		4	gold ore	4	adamantium ore	1	ebony ore							forging	10																	x	A												
indoril pauldron right	Indoril Right Pauldron	9	2400	45		10	medium	pauldron	73.79	[150] Indoril	Armor		8	74	8	Temple		4	gold ore	4	adamantium ore	1	ebony ore							forging	10																	x	A												
T_De_Ep_SkirtIndWarrior_01	Indoril Warrior Skirt	2	20			40		Skirt	80.00	[150] Indoril	Clothing		9.4	75	8	Temple		2	adamantium ore		ebony ore	2	silver ore								10																	x	A												
indoril cuirass	Indoril Cuirass	27	7000	45		180	medium	cuirass	74.68	[150] Indoril	Armor		8	75	8	Temple		7	gold ore	7	adamantium ore	1	ebony ore							forging	10																	x	A												
indoril helmet	Indoril Helmet	4.5	3000	45		225	medium	helmet	76.43	[150] Indoril	Armor		8	75	8	Temple		4	gold ore	4	adamantium ore	1	ebony ore							forging	10																	x	A												
indoril shield	Indoril Shield	13.5	2000	45		450	medium	shield	78.43	[150] Indoril	Armor		8	77	8	Temple		6	gold ore	6	adamantium ore	1	ebony ore							forging	10																	x	A												
T_De_Ordinator_Greaves_01	Indoril Greaves	12	3300	45		10	medium	greaves	73.62	[150] Indoril	Armor		9	78	8	Temple		4	gold ore	4	adamantium ore	1	ebony ore							forging	10																	x	A												
Indoril_MH_Guard_shield	Her Hand's Shield	17	2500	55		500	heavy	shield	73.40	[150] Indoril	Armor		9	81	8	Temple		6	gold ore	6	adamantium ore	1	ebony ore							forging	10																	x	A												
Indoril_MH_Guard_Greaves	Her Hand's Greaves	45	33000	70		60	heavy	greaves	83.60	[150] Indoril	Armor		9	83	8	Temple		4	gold ore	4	adamantium ore	2	ebony ore							forging	10																	x	A												
Indoril_MH_Guard_Pauldron_L	Her Hand's Left Pauldron	30	20000	70		50	heavy	pauldron	84.31	[150] Indoril	Armor		9	84	8	Temple		4	gold ore	4	adamantium ore	2	ebony ore							forging	10																	x	A												
Indoril_MH_Guard_Pauldron_R	Her Hand's Right Pauldron	30	20000	70		50	heavy	pauldron	84.31	[150] Indoril	Armor		9	84	8	Temple		4	gold ore	4	adamantium ore	2	ebony ore							forging	10																	x	A												
Indoril_MH_Guard_boots	Her Hand's Boots	60	15000	70		200	heavy	boots	84.31	[150] Indoril	Armor		9	84	8	Temple		4	gold ore	4	adamantium ore	2	ebony ore							forging	10																	x	A												
Indoril_MH_Guard_Cuirass	Her Hand's Cuirass	90	50000	70		550	heavy	cuirass	86.51	[150] Indoril	Armor		9	86	8	Temple		7	gold ore	7	adamantium ore	4	ebony ore							forging	10																	x	A												
Indoril_MH_Guard_gauntlet_L	Her Hand's Left Gauntlet	15	13000	70		500	heavy	gauntlet	90.06	[150] Indoril	Armor		9	86	8	Temple		2	gold ore	2	adamantium ore	1	ebony ore							forging	10																	x	A												
Indoril_MH_Guard_gauntlet_R	Her Hand's Right Gauntlet	15	13000	70		500	heavy	gauntlet	90.06	[150] Indoril	Armor		9	86	8	Temple		2	gold ore	2	adamantium ore	1	ebony ore							forging	10																	x	A												
Indoril_MH_Guard_helmet	Her Hand's Helmet	15	12000	75		650	heavy	helmet	97.13	[150] Indoril	Armor		8.6	88	8	Temple		4	gold ore	2	adamantium ore	4	ebony ore							forging	10																	x	A												
T_De_Necrom_Boots_01	Necrom Indoril Boots	18	2,000	50		26	medium	boots	80.85	[150] Indoril	Armor		10.6	89	9	Temple		4	adamantium ore	2	ebony ore	2	silver ore	1	indoril boots					forging	10																	x	A												
T_De_Necrom_GauntletL_01	Necrom Indoril Left Gauntlet	4.5	1,600	50		60	medium	gauntlet	81.97	[150] Indoril	Armor		10.6	89	9	Temple		2	adamantium ore	1	ebony ore	2	silver ore	1	indoril left gauntlet					forging	10																	x	A												
T_De_Necrom_GauntletR_01	Necrom Indoril Right Gauntlet	4.5	1,600	50		60	medium	gauntlet	81.97	[150] Indoril	Armor		10.6	89	9	Temple		2	adamantium ore	1	ebony ore	2	silver ore	1	indoril right gauntlet					forging	10																	x	A												
T_De_Necrom_Greaves_01	Necrom Indoril Greaves	12	3,300	50		10	medium	greaves	81.01	[150] Indoril	Armor		10.6	89	9	Temple		4	adamantium ore	2	ebony ore	2	silver ore	1	T_De_Ordinator_Greaves_01					forging	10																	x	A												
T_De_Necrom_PauldronL_01	Necrom Indoril Left Pauldron	7	2,800	50		10	medium	pauldron	81.28	[150] Indoril	Armor		10.6	89	9	Temple		4	adamantium ore	2	ebony ore	2	silver ore	1	indoril pauldron left					forging	10																	x	A												
T_De_Necrom_PauldronR_01	Necrom Indoril Right Pauldron	7	2,800	50		10	medium	pauldron	81.28	[150] Indoril	Armor		10.6	89	9	Temple		4	adamantium ore	2	ebony ore	2	silver ore	1	indoril pauldron right					forging	10																	x	A												
T_De_Necrom_Helm_01	Necrom Indoril Helmet	4.5	4,000	50		60	medium	helmet	81.97	[150] Indoril	Armor		10.6	90	9	Temple		4	adamantium ore	2	ebony ore	2	silver ore	1	indoril helmet					forging	10																	x	A												
T_De_Necrom_Cuirass_01	Necrom Indoril Cuirass	27	10,000	50		220	medium	cuirass	82.50	[150] Indoril	Armor		10.6	91	9	Temple		7	adamantium ore	4	ebony ore	2	silver ore	1	indoril cuirass					forging	10																	x	A												
T_De_Ex_SkirtNecrom_01	Necrom Indoril Skirt	4	100			50		Skirt	80.00	[150] Indoril	Clothing		10.6	91	9	Temple		2	adamantium ore		ebony ore	2	silver ore	1	T_De_Ep_SkirtIndWarrior_01						10																	x	A												
T_De_Necrom_Shield_01	Necrom Indoril Shield	13.5	2,000	50		450	medium	shield	85.77	[150] Indoril	Armor		10.6	92	9	Temple		7	adamantium ore	6	gold ore	2	silver ore	1	indoril shield					forging	10																	x	A												
daedric club	Daedric Club	36	10000		18	120		BluntOneHand	33.33	[160] Daedric	🔨		10.6	65				2	daedra heart	6	ebony ore	2	SC_greaterSoul							forging	11																	x	A												
daedric dagger	Daedric Dagger	9	10000		30	60		ShortBladeOneHand	39.59	[160] Daedric	🗡️		10.6	68				2	daedra heart	4	ebony ore	2	SC_greaterSoul							forging	11																	x	A												
daedric tanto	Daedric Tanto	12	14000		45	66		ShortBladeOneHand	57.45	[160] Daedric	🗡️		10.6	77				3	daedra heart	7	ebony ore	2	SC_greaterSoul							forging	11																	x	A												
daedric mace	Daedric Mace	45	24000		39	150		BluntOneHand	61.99	[160] Daedric	🔨		10.6	79				3	daedra heart	3	ebony ore	2	SC_greaterSoul	1	ebony mace					forging	11																	x	A												
daedric spear	Daedric Spear	42	20000		40	150		SpearTwoWide	68.95	[160] Daedric	🔱		10.6	83				4	daedra heart	7	ebony ore	2	SC_greaterSoul	1	ebony spear					forging	11																	x	A												
daedric staff	Daedric Staff	24	14000		28	210		BluntTwoWide	69.74	[160] Daedric	🦯		10.6	84				4	daedra heart	7	ebony ore	2	SC_grandSoul	1	ebony staff					forging	11																	x	A												
daedric shortsword	Daedric Shortsword	24	20000		52	120		ShortBladeOneHand	69.75	[160] Daedric	🗡️		10.6	84				4	daedra heart	7	ebony ore	2	SC_greaterSoul	1	ebony shortsword					forging	11																	x	A												
daedric arrow	Daedric Arrow	0.3	20		15	45		Arrow	100.00	[160] Daedric	Ammo		10.6	85				1	daedra heart	1	SC_pettySoul	20	ebony arrow							forging	6	5																x	A												
daedric long bow	Daedric Long Bow	24	50000		50	105		MarksmanBow	76.63	[160] Daedric	🏹		10.6	87				5	daedra heart	8	ebony ore	3	SC_grandSoul	1	ebony staff					forging	11																	x	A												
daedric dart	Daedric Dart	0.4	4000		12	45		MarksmanThrown	100.00	[160] Daedric	Ammo		10.6	88				1	daedra heart	1	SC_pettySoul	20	ebony dart							forging	6	5																x	A												
daedric longsword	Daedric Longsword	60	40000		59.4	180		LongBladeOneHand	78.98	[160] Daedric	⚔️		10.6	88				5	daedra heart	7	ebony ore	2	SC_greaterSoul	1	ebony longsword					forging	11																	x	A												
daedric war axe	Daedric War Axe	72	30000		55	150		AxeOneHand	79.34	[160] Daedric	🪓		10.6	89				5	daedra heart	7	ebony ore	2	SC_greaterSoul	1	ebony war axe					forging	11																	x	A												
daedric katana	Daedric Katana	54	50000		66	180		LongBladeOneHand	86.96	[160] Daedric	⚔️		10.6	92				4	daedra heart	4	ebony ore	2	SC_grandSoul	1	daedric longsword					forging	11																	x	A												
daedric wakizashi	Daedric Wakizashi	30	48000		67.5	135		ShortBladeOneHand	88.89	[160] Daedric	🗡️		10.6	93				4	daedra heart	4	ebony ore	2	SC_grandSoul	1	daedric tanto					forging	11																	x	A												
daedric_greaves	Daedric Greaves	54	44000	80		75	heavy	greaves	94.20	[160] Daedric	Armor		10.6	96				3	daedra heart	3	ebony ore	2	SC_greaterSoul	1	ebony_greaves					forging	11																	x	A												
daedric warhammer	Daedric Warhammer	96	30000		70	165		BluntTwoClose	92.76	[160] Daedric	🔨2H		10.6	96				7	daedra heart	7	ebony ore	3	SC_grandSoul	1	6th bell hammer					forging	11																	x	A												
daedric claymore	Daedric Claymore	81	80000		75	210		LongBladeTwoClose	94.64	[160] Daedric	⚔️2H		10.6	96				4	daedra heart	6	ebony ore	2	SC_grandSoul	1	daedric longsword					forging	11																	x	A												
daedric_pauldron_left	Daedric Left Pauldron	30	24000	80		60	heavy	pauldron	95.34	[160] Daedric	Armor		10.6	96				3	daedra heart	3	ebony ore	2	SC_greaterSoul	1	ebony_pauldron_left					forging	11																	x	A												
daedric_pauldron_right	Daedric Right Pauldron	30	24000	80		60	heavy	pauldron	95.34	[160] Daedric	Armor		10.6	96				3	daedra heart	3	ebony ore	2	SC_greaterSoul	1	ebony_pauldron_right					forging	11																	x	A												
daedric_boots	Daedric Boots	60	20000	80		263	heavy	boots	95.92	[160] Daedric	Armor		10.6	96				3	daedra heart	3	ebony ore	2	SC_greaterSoul	1	ebony_boots					forging	11																	x	A												
daedric battle axe	Daedric Battle Axe	90	50000		80	165		AxeTwoHand	98.03	[160] Daedric	🪓2H		10.6	98				4	daedra heart	6	ebony ore	2	SC_grandSoul	1	daedric war axe					forging	11																	x	A												
daedric_cuirass	Daedric Cuirass	90	70000	80		600	heavy	cuirass	97.94	[160] Daedric	Armor		10.6	98				5	daedra heart	6	ebony ore	2	SC_greaterSoul	1	ebony_cuirass					forging	11																	x	A												
daedric_gauntlet_left	Daedric Left Gauntlet	15	14000	80		600	heavy	gauntlet	101.99	[160] Daedric	Armor		10.6	99				2	daedra heart	2	ebony ore	2	SC_greaterSoul	1	ebony_bracer_left					forging	11																	x	A												
daedric_gauntlet_right	Daedric Right Gauntlet	15	14000	80		600	heavy	gauntlet	101.99	[160] Daedric	Armor		10.6	99				2	daedra heart	2	ebony ore	2	SC_greaterSoul	1	ebony_bracer_right					forging	11																	x	A												
daedric dai-katana	Daedric Dai-katana	60	120000		81	210		LongBladeTwoClose	101.63	[160] Daedric	⚔️2H		10.6	99				3	daedra heart	5	ebony ore	2	SC_grandSoul	1	daedric katana					forging	11																	x	A												
daedric_fountain_helm	Daedric Face of Inspiration	15	13000	65		750	heavy	helmet	87.33	[160] Daedric	Armor		10.6	100				3	daedra heart	3	ebony ore	2	SC_greaterSoul	1	ebony_closed_helm					forging	11																	x	A												
daedric_shield	Daedric Shield	45	34000	80		1500	heavy	shield	110.03	[160] Daedric	Armor		10.6	104				4	daedra heart	7	ebony ore	2	SC_greaterSoul	1	ebony_shield					forging	11																	x	A												
daedric_towershield	Daedric Tower Shield	45	50000	80		2250	heavy	shield	118.01	[160] Daedric	Armor		10.6	108				7	daedra heart	7	ebony ore	3	SC_grandSoul	1	ebony_towershield					forging	11																	x	A												
expensive_ring_03	Expensive Ring			(silver w rubies around)						Jewelry	clothing	Expensive Silver Ring	2	24				2	silver ore											forging																		x													
expensive_amulet_03	Expensive Amulet			(fully silver)						Jewelry	clothing	Expensive Silver Amulet	2	30				2	silver ore											forging																		x													
extravagant_ring_02	Extravagant Ring			(gold or dwemer toenail)						Jewelry	clothing	Extravagant Gold Ring	3	36				2	gold ore	1	silver ore									forging																		x													
T_Imp_Et_AmuletNib_01	Extravagant Amulet			(maybe gold with silver stone)						Jewelry	clothing	Extravagant Gold Amulet	3	42				2	gold ore	1	silver ore									forging																		x													
T_Ayl_Amulet_01	Ayleid Amulet			(pure gold)						Jewelry	clothing	Exquisite Gold Amulet	5	65				3	gold ore	1	adamantium ore									forging																		x													
T_Bre_Ex_Ring_01	Exquisite Ring			(gold with green stone)						Jewelry	clothing	Exquisite Gold Ring	5	77				3	gold ore	1	raw glass									forging																		x													
miner's pick	Miner's Pick	20	8		7	10		AxeTwoHand	1.42	Misc	🪓2H		1.5	8				5	iron ore											forging																		x	A												
BM Nordic Pick	Ancient Nordic Pick Axe	20	8000		20	100		AxeOneHand	30.95	Misc	🪓		6	44				6	adamantium ore	3	diamond	1	miner's pick							forging																		x	A												
T_De_Ebony_Pickaxe_01	Ebony Miner's Pick	26	1500		16	100		AxeTwoHand	18.81	Misc	🪓2H		10.6	60				11	ebony ore	3	diamond	1	miner's pick							forging																		x	A												
																																																							
]]

-- escape for lua output
local function luaStr(s)
	if not s then return nil end
	if type(s) == "number" then
		return s
	end
	s = s:gsub("\\", "\\\\"):gsub('"', '\\"')
	return '"' .. s .. '"'
end

local function splitTabs(line)
	local fields = {}
	local temp = line .. "\t"
	temp:gsub("([^\t]*)\t", function(field)
		fields[#fields + 1] = field
		return ""
	end)
	return fields
end

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local lines = {}
for line in tsvBlock:gmatch("[^\r\n]+") do
	lines[#lines + 1] = line
end

local keyOrder = {
	"id", "craftingCategory", "types", "nameOpt", "level",
	"factionRank", "faction", "count", "disabled", "hidden",
	"craftingSound", "craftingTime", "craftingInterval",
	"experience", "skill", "secondLevel", "secondSkill",
	"craftingEvent", "profession",
}

local fieldMap = {
	{ key = "craftingCategory", idx = 11, number = false },
	{ key = "types",            idx = 12, number = false },
	{ key = "nameOpt",          idx = 13, number = false },
	{ key = "level",     		idx = 15, number = true },
	{ key = "factionRank",      idx = 16, number = true },
	{ key = "faction",          idx = 17, number = false },
	{ key = "count",            idx = 18, number = true },
	{ key = "disabled",         idx = 30, number = false },
	{ key = "craftingSound",    idx = 31, number = false },
	{ key = "craftingTime",     idx = 32, number = true },
	{ key = "experience",       idx = 33, number = true },
	{ key = "skill",       idx = 34, number = false },
	{ key = "secondLevel",      idx = 35, number = true },
	{ key = "secondSkill",      idx = 36, number = false },
	{ key = "craftingEvent",    idx = 42, number = false },
	{ key = "profession",       idx = 43, number = false },
	{ key = "craftingInterval", idx = 44, number = true },
	{ key = "hidden",           idx = 45, number = false },
}

-- material aliases (mirror of parseRecipes); legacy tsv only
local materialMapping = {
	["adamantium ore"] = "ingred_adamantium_ore_01",
	["iron ore"] = "T_IngMine_OreIron_01",
	["racer plumes"] = "ingred_racer_plumes_01",
	["coal"] = "T_IngMine_Coal_01",
	["orichalcum ore"] = "T_IngMine_OreOrichalcum_01",
	["dwemer scrap metal"] = "ingred_scrap_metal_01",
	["raw glass"] = "ingred_raw_glass_01",
	["raw ebony"] = "ingred_raw_ebony_01",
	["ebony ore"] = "ingred_raw_ebony_01",
	["daedra heart"] = "ingred_daedras_heart_01",
	["daedric heart"] = "ingred_daedras_heart_01",
	["gold ore"] = "T_IngMine_OreGold_01",
	["silver ore"] = "T_IngMine_OreSilver_01",
	["diamond"] = "ingred_diamond_01",
	["netch leather"] = "ingred_netch_leather_01",
	["bonemeal"] = "ingred_bonemeal_01",
	["stahlrim"] = "ingred_raw_Stalhrim_01",
	["amethyst"] = "T_IngMine_Amethyst_01",
	["ruby"] = "ingred_ruby_01",
	["sapphire"] = "T_IngMine_Sapphire_01",
	["emerald"] = "ingred_emerald_01",
	["midnight agate"] = "T_IngMine_Agate_03",
	["pearl"] = "ingred_pearl_01",
	["trama root"] = "ingred_trama_root_01",
	["small mole crab shell"] = "",
	["garnet"] = "T_IngMine_Garnet_01",
	["resin"] = "ingred_resin_01",
	["fire petal"] = "ingred_fire_petal_01",
	["dreugh wax"] = "ingred_dreugh_wax_01",
	["petty soul gem"] = "Misc_SoulGem_Petty",
	["lesser soul gem"] = "Misc_SoulGem_Lesser",
	["common soul gem"] = "Misc_SoulGem_Common",
	["greater soul gem"] = "Misc_SoulGem_Greater",
	["grand soul gem"] = "Misc_SoulGem_Grand",
	["alit hide"] = "ingred_alit_hide_01",
}

local matCols = { {19, 20}, {21, 22}, {23, 24}, {25, 26}, {27, 28} }

print("return {")

for i = 3, #lines do
	local line = lines[i]
	if line and line:match("%S") then
		local f = splitTabs(line)
		while #f < 45 do f[#f + 1] = "" end

		local function g(idx) return trim(f[idx] or "") end

		local id = g(1)
		if id ~= "" then
			local rec = { id = id }

			for _, m in ipairs(fieldMap) do
				local v = g(m.idx)
				if v ~= "" then 
					if m.number then
						rec[m.key] = tonumber(v)
					else
						rec[m.key] = v
					end
				end
			end

			-- ingredients
			local ingredients = {}
			for _, pair in ipairs(matCols) do
				local count = tonumber(g(pair[1])) or 0
				local matId = g(pair[2])
				if matId ~= "" and count > 0 then
					matId = materialMapping[matId:lower()] or matId
					if matId ~= "" then ingredients[#ingredients + 1] = { id = matId, count = count } end
				end
			end

			-- tools
			local tools = {}
			for _, idx in ipairs({39, 40}) do
				local v = g(idx)
				if v ~= "" then tools[#tools + 1] = { id = v } end
			end

			-- stations
			local stations = {}
			local station = g(41)
			if station ~= "" then stations[#stations + 1] = { id = station } end

			print("\t{")
			for _, key in ipairs(keyOrder) do
				if rec[key] then
					print("\t\t" .. key .. " = " .. luaStr(rec[key]) .. ",")
				end
			end
			if #ingredients > 0 then
				print("\t\tingredients = {")
				for _, ing in ipairs(ingredients) do
					local c = ing.count == math.floor(ing.count) and tostring(math.floor(ing.count)) or tostring(ing.count)
					print("\t\t\t{ id = " .. luaStr(ing.id) .. ", count = " .. c .. " },")
				end
				print("\t\t},")
			end
			if #tools > 0 then
				print("\t\ttools = {")
				for _, t in ipairs(tools) do print("\t\t\t{ id = " .. luaStr(t.id) .. " },") end
				print("\t\t},")
			end
			if #stations > 0 then
				print("\t\tstations = {")
				for _, s in ipairs(stations) do print("\t\t\t{ id = " .. luaStr(s.id) .. " },") end
				print("\t\t},")
			end
			print("\t},")
		end
	end
end

print("}")