-- ====================================================== CLIMATE TEMPERATURE ======================================================

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Climate Zones - Vector-Based Heat/Cold Sources						  │
-- ╰──────────────────────────────────────────────────────────────────────╯

CLIMATE_SOURCES = {

-- ========================================================== VVARDENFELL ==========================================================
	-- RED MOUNTAIN REGION (Volcanic hot zones)
	{
		name = "Red Mountain Core",
		position = util.vector3(20752.800781, 69140.593750, 10833.319336),
		intensity = 37,
		radius = 55000,
		climate = "volcanic",
		exponent = 2.5, -- squareInfluence
	},
	{
		name = "Red Mountain Reborn", -- Red Mountain Reborn ; Red Tower ; Rocky Red Mountain
		position = util.vector3(21000, 71358.187500, 21258.263672),
		intensity = 40,
		radius = 28000,
		exponent = 2, -- squareInfluence
		climate = "volcanic",
	},
	{
		name = "Red Mountain West", -- between Mar Gaan and ald'ruhn
		position = util.vector3(-4846.307129, 89136.726562, 6508.192871),
		intensity = 10,
		radius = 15000,
		climate = "volcanic",
		exponent = 1, -- squareInfluence
	},	
	{
		name = "Ghostgate", -- Ghostgate coordinates (vanilla): (20765.322266, 38586.734375, 1246.631348)
		position = util.vector3(25000, 30000, 1246.631348),
		intensity = 13, -- 38c
		radius = 36000,
		climate = "volcanic",
		exponent = 1.1, -- squareInfluence
	},
	-- MOLAG AMUR REGION (Volcanic badlands)
	{
		name = "Molag Amur Lava Fields",
		position = util.vector3(58000, -10000, 1000),
		intensity = 15,
		radius = 48000,
		exponent = 2, -- squareInfluence
		climate = "volcanic",
	},
	{
		name = "Molag Amur Wastes", 
		position = util.vector3(70000, 30000, 1200), -- touches grazelands, ends just north of falenserano
		intensity = 12,
		radius = 30000,
		exponent = 2, -- squareInfluence
		climate = "volcanic",
	},
	{
		name = "Uvirith's Grave",
		position = util.vector3(86275.718750, 9998.221680, 4003.486328),
		intensity = 5,
		radius = 8000,
		climate = "coastal",
		exponent = 0.7, -- squareInfluence				
	},
	{
		name = "Western Foyada", 
		position = util.vector3(25000, -7000, 1200),
		intensity = 10,
		radius = 33000,
		exponent = 2, -- squareInfluence
		climate = "volcanic",
	},	
	{
		name = "Molag Mar", 
		position = util.vector3(110000, -36000, 1500),
		intensity = 10,
		radius = 55000,
		climate = "volcanic" -- not an ashland but probably gets cold at night
	},	
	
	-- ASHLANDS REGION (Hot, dry volcanic wasteland)
	{
		name = "Ald'ruhn",
		position = util.vector3(-10000.386719, 54000, 3200),
		intensity = 2,
		radius = 22000,
		climate = "volcanic",
		exponent = 0.7, -- squareInfluence		
	},	
	{
		name = "Ashlands West",
		position = util.vector3(-37000, 70000, 2600),
		intensity = 8,
		radius = 35000,
		climate = "volcanic",
		exponent = 0.7, -- squareInfluence		
	},
	{
		name = "Ashlands East",
		position = util.vector3(38000, 115000, 800),
		intensity = 11,
		radius = 44000,
		climate = "ashland",
		exponent = 1.6, -- squareInfluence		
	},	
	{
		name = "Maar Gan",
		position = util.vector3(-18000, 100000, 3200),
		intensity = 3,
		radius = 24000,
		climate = "volcanic",
		exponent = 0.5, -- squareInfluence		
	},	
	{
		name = "Ashlands North", -- between kog and urshilaku
		position = util.vector3(-10000, 130000, 2300),
		intensity = 12,
		radius = 54000,
		climate = "ashland",
		exponent = 2.5, -- squareInfluence		
	},		
	{
		name = "Koguruhn", 
		position = util.vector3(12000, 115000, 2000),
		intensity = 3,
		radius = 25000,
		exponent = 2, -- squareInfluence
		climate = "volcanic",
	},		
	
	-- WEST GASH REGION
	{
		name = "Gnisis", -- Khuul: -70364.867188, 141287.000000, 150 -10000
		position = util.vector3(-50000, 115000, 1500),
		intensity = -7,
		radius = 52500,
		climate = "coastal"
	},	
	{
		name = "Gnisis Left",
		position = util.vector3(-78860, 100256, 0),
		intensity = 4,
		radius = 22794.00,
		climate = "temperate",
		exponent = 0.3,
	},
	-- SHEOGORAD REGION (Cold northern islands)
	{
		name = "Sheogorad Islands",
		position = util.vector3(36168.410156, 203473.703125, 57.169540), -- northernmost island of sheogorad
		intensity = -45,
		radius = 48117,
		climate = "cold",
		exponent = 0.7, -- squareInfluence
	},
	{
		name = "Dagon Fel",
		position = util.vector3(60500, 182663, 160), -- northernmost island of sheogorad
		intensity = 3,
		radius = 5000,
		climate = "urban",
		exponent = 1, -- squareInfluence
	},	
	
	-- SOLSTHEIM (Arctic region)
	{
		name = "Solstheim TOTSP",
		position = util.vector3(-120000, 269746.312500, 250),
		intensity = -55,
		radius = 115000 / (TEMP_TOTSP and 1 or 10000),
		exponent = 2, -- squareInfluence
		climate = "arctic",
	},
	{
		name = "Skaal Village TOTSP",
		position = util.vector3(-101374.570312, 260866.734375, 3477.895752), -- TOTSP skaal village
		intensity = 14,
		radius = 7000 / (TEMP_TOTSP and 1 or 10000),
		climate = "urban",
		exponent = 0.7, -- squareInfluence
	},	
	{
		name = "Hirstaang Forest Mountain TOTSP",
		position = util.vector3(-135000.390625, 205000, 1500),
		intensity = -25,
		radius = 17000 / (TEMP_TOTSP and 1 or 10000),
		climate = "arctic",
		exponent = 2.5
	},
	{
		name = "Northwest glaciers TOTSP",
		position = util.vector3(-150000, 279746.312500, 5000),
		intensity = -55,
		radius = 20000 / (TEMP_TOTSP and 1 or 10000),
		climate = "arctic",
		exponent = 0.7, -- squareInfluence
	},
	{
		name = "Solstheim",
		position = util.vector3(-180000, 215000, 2000),
		intensity = -55,
		radius = 115000,
		exponent = 2, -- squareInfluence
		climate = "arctic",
	},
	{
		name = "Skaal Village",
		position = util.vector3(-161374.570312, 211000, 3077.895752),
		intensity = 14,
		radius = 7000,
		climate = "urban",
		exponent = 0.7, -- squareInfluence
	},
	{
		name = "Northwest glaciers",
		position = util.vector3(-211000, 226000, 5000),
		intensity = -55,
		radius = 20000,
		climate = "arctic",
		exponent = 0.7, -- squareInfluence
	},	
	
	-- BITTER COAST REGION (Warm, humid swamps)
	{
		name = "Seyda Neen", -- middle of Seyda Neen
		position = util.vector3(-10934.880859, -70883.960938, 228.582367), 
		intensity = 15, -- 35c is max
		radius = 23000,
		exponent = 2, -- squareInfluence
		climate = "tropical",
	},
	{
		name = "Bitter Coast Swamps",
		position = util.vector3(-68012, 96, 228),
		intensity = 15,
		radius = 50934.00,
		centerRadius = 19650.00,
		climate = "tropical",
		exponent = 0.65,
		blendMode = 3,
	},
	{
		name = "Odai River",
		position = util.vector3(-27513, -40213, 228),
		intensity = -3,
		radius = 21428.00,
		centerRadius = 9432.00,
		climate = "coastal",
		blendMode = 3,
	},	
	{
		name = "Balmora",
		position = util.vector3(-12500, -6000, 1500), 
		intensity = -3,
		radius = 23500,
		climate = "coastal",
		exponent = 0.7, -- squareInfluence
	},	
	
	-- ASCADIAN ISLES REGION (Temperate, fertile)
	{
		name = "Ascadian Isles",
		position = util.vector3(14499, -35510, 300),
		intensity = 5, -- 25c
		radius = 37214.00,
		position = util.vector3(10000, -40000, 300),
		radius = 38000,
		exponent = 2, -- squareInfluence
		climate = "temperate",
	},
	{
		name = "Ascadian Isles Plantations",
		position = util.vector3(22500, -47000, 600),
		intensity = 8,
		radius = 12000,
		exponent = 2, -- squareInfluence
		climate = "tropical",
	},
	{
		name = "Vivec City",
		position = util.vector3(32467.130859, -90863.234375, 100), 
		intensity = 2,
		radius = 15000, 
		exponent = 2, -- squareInfluence
		climate = "urban",
	},
	{
		name = "Nabia River",
		position = util.vector3(47500, -52000, 1000),
		intensity = -1,
		radius = 36000,
		exponent = 2, -- squareInfluence
		climate = "coastal",
	},		
	{
		name = "Suran",
		position = util.vector3(52000, -55000, 1000),
		intensity = 4,
		radius = 10000,
		climate = "urban",
		exponent = 0.7, -- squareInfluence
	},	
	
	-- GRAZELANDS REGION (Warm grasslands)
	{
		name = "Grazelands",
		position = util.vector3(80000, 105000, 1200),
		intensity = 10,
		radius = 40000,
		climate = "grassland",
		exponent = 2.5, -- squareInfluence		
	},
	{
		name = "North Azura's Coast",
		position = util.vector3(120000, 105000, 500),
		intensity = -5,
		radius = 35000,
		climate = "coastal",
		exponent = 0.7, -- squareInfluence		
	},	
	
	-- AZURA'S COAST REGION (Cool eastern coast)
	{
		name = "Sadrith Mora", -- sadrith mora
		position = util.vector3(145000, 35000, 100),
		intensity = -1,
		radius = 50000,
		climate = "coastal",
		exponent = 0.7, -- squareInfluence
	},
	{
		name = "Azura's Coast South", -- near tel branora
		position = util.vector3(130000, -110000, 100),
		intensity = -8,
		radius = 30000,
		exponent = 2, -- squareInfluence
		climate = "coastal",
	},
	{
	  name = "Azura's Coast East", 
	  position = util.vector3(165000, -31000, 200),
	  intensity = -6,
	  radius = 55000,
	  climate = "coastal" -- not an ashland but probably gets cold at night
	},		
	
-- ======================================================== TAMRIEL REBUILT ========================================================

	-- The Northern Islands (Telvanni Territory)
	{
		name = "Sea of Ghosts", -- cold air for most of Sea of Ghosts
		position = util.vector3(165591, 252563, 0),
		intensity = -48,
		radius = 82530.00,
		centerRadius = 33798.00,
		climate = "arctic",
	},
	{
		name = "Eastern Northern Islands",
		position = util.vector3(243564, 241738, 0),
		intensity = -40,
		radius = 67596.00,
		centerRadius = 11000.00,
		climate = "arctic",
		exponent = 0.7,
	},		
	{
		name = "Tel Rivus",
		position = util.vector3(135246.109375, 201921.609375, 3401.285400), -- mushroom tower air around Tel Rivus
		intensity = 15,
		radius = 4500,
		climate = "urban",
		exponent = 0.3,
	},
	{
		name = "Nivalis",
		position = util.vector3(102290, 227942.750000, 91),
		intensity = -3,
		radius = 2200,
		climate = "urban",
		exponent = 0.3,
	},
	-- Telvanni Isles
	{
		name = "Port Telvannis",
		position = util.vector3(339283, 141714, 3600),
		intensity = 20,
		radius = 17070.00,
		centerRadius = 11790.00,
		climate = "urban",
		exponent = 0.4,
		blendMode = 1,
	},
	{
		name = "Sadas Plantation",
		position = util.vector3(291000, 144701, 1300),
		intensity = 2,
		radius = 15000.00,
		climate = "tropical",
		exponent = 0.3,
	},
	{
		name = "Eastern Telvanni Island",
		position = util.vector3(375363, 151775, 0),
		intensity = -20,
		radius = 83316.00,
		centerRadius = 11004.00,
		climate = "coastal",
		blendMode = 1,
	},
	{
		name = "Port Telvannis Coast",
		position = util.vector3(348383, 123071, 2661),
		intensity = -10,
		radius = 40000.00,
		centerRadius = 14148.00,
		climate = "coastal",
		exponent = 1.35,
		blendMode = 1,
	},
	{
		name = "Gah Sadrith",
		position = util.vector3(346603.593750, 106578, 1800),
		intensity = 10,
		radius = 9000,
		climate = "urban",
		exponent = 0.3,
	},	
	
	-- Dagon Urul (Telvanni Territory)
	{
		name = "Firewatch",
		position = util.vector3(146743, 126426, 1300),
		intensity = -10,
		radius = 5500,
		climate = "urban",
		exponent = 0.3,
	},
	-- Sunad Mora / Molagreahd (Telvanni Territory)
	{
		name = "Near Tel Ouada",
		position = util.vector3(210705, 136178, 4258),
		intensity = -8,
		radius = 64452.00,
		climate = "coastal",
		exponent = 1,
	},
	{
		name = "Ranyon-Ruhn",
		position = util.vector3(230399.484375, 102629.187500, 5290.160156),
		intensity = -3,
		radius = 15000,
		climate = "urban",
		exponent = 0.7,
	},
	{
		name = "Llothanis",
		position = util.vector3(270622.000000, 83425.203125, 1866.901855),
		intensity = -4,
		radius = 8000,
		climate = "urban",
		exponent = 0.7,
	},
	-- Padomaic Ocean (Telvanni Territory)
	{
		name = "Windbreaker Keep",
		position = util.vector3(313185, 41120, 0),
		intensity = -2,
		radius = 14148.00,
		climate = "coastal",
		blendMode = 1,
	},
	{
		name = "Eroth Island",
		position = util.vector3(354431, -38409, 0),
		intensity = 10,
		radius = 10218.00,
		climate = "tropical",
		exponent = 0.5,
		blendMode = 1,
	},	
	
	-- Boethia's Spine (Telvanni Territory)
	{
		name = "Boethia's Spine: Eastern Coast",
		position = util.vector3(285906, 44997, 4264),
		intensity = -4,
		radius = 55020.00,
		centerRadius = 11004.00,
		climate = "coastal",
		blendMode = 1,
	},
	-- Molag Ruhn (Telvanni Territory)
	{
		name = "Central Telvannis",
		position = util.vector3(240455, -58774, 1500),
		intensity = 12,
		radius = 73884.00,
		climate = "tropical",
		exponent = 0.8,
		blendMode = 1,
	},
	{
		name = "Isle of Arches",
		position = util.vector3(269406, 166656, 1200),
		intensity = -12,
		radius = 18078.00,
		climate = "coastal",
		exponent = 0.3,		
		blendMode = 1,
	},
	{
		name = "Helnim",
		position = util.vector3(207000, 11700, 1070),
		intensity = 5,
		radius = 5000,
		climate = "urban",
		exponent = 0.3,
	},
	{
		name = "Western Coast",
		position = util.vector3(187390, 35773, 3000),
		intensity = -10,
		radius = 57378.00,
		centerRadius = 16506.00,
		climate = "coastal",
		exponent = 0.6,
		blendMode = 1,
	},
	-- Mephalan Vales
	{
		name = "Northwest Indoril",
		position = util.vector3(177600, -99711, 3000),
		intensity = -12,
		radius = 44016.00,
		centerRadius = 16506.00,
		climate = "coastal",
		exponent = 0.6,
		blendMode = 3,
	},
	{
		name = "Akamora",
		position = util.vector3(249475, -88202, 3000),
		intensity = -6,
		radius = 14148.00,
		centerRadius = 4716.00,
		climate = "urban",
		exponent = 0.95,
		blendMode = 1,
	},
	{
		name = "Central Valley",
		position = util.vector3(207769, -151723, 1500),
		intensity = 12,
		radius = 44802.00,
		centerRadius = 20436,
		climate = "tropical",
		blendMode = 3,
	},
{
		name = "Arkgnthleft",
		position = util.vector3(238372, -130657, 4500),
		intensity = 32,
		radius = 6000.00,
		climate = "volcanic",
		exponent = 0.65,
		blendMode = 3,
	},
	{
		name = "Mansurabi",
		position = util.vector3(188142.773438, -173953.335938, 2352.524231),
		intensity = 32,
		radius = 7000,
		climate = "volcanic",
		exponent = 0.65,
		blendMode = 3,
	},
	-- Sacred Lands
	{
		name = "Necrom",
		position = util.vector3(349000, -90408, 1600),
		intensity = 12,
		radius = 33000.00,
		centerRadius = 8000.00,
		climate = "urban",
		exponent = 0.95,
		blendMode = 1,
	},
	{
		name = "Necrom Outskirts",
		position = util.vector3(360567, -102103, 6000),
		intensity = -14,
		radius = 77814.00,
		centerRadius = 27510.00,
		climate = "ashland",
		exponent = 0.65,
		blendMode = 1,
	},
	{
		name = "Southeast Necrom Valley",
		position = util.vector3(273957, -198218, 6000),
		intensity = -8,
		radius = 77814.00,
		centerRadius = 27510.00,
		climate = "ashland",
		exponent = 0.65,
		blendMode = 1,
	},	
	
	-- Alt Orethan
	{
		name = "Southwest Indoril",
		position = util.vector3(176287, -175774, 2500),
		intensity = 10,
		radius = 44802.00,
		centerRadius = 20436.00,
		climate = "tropical",
		blendMode = 3,
	},
	{
		name = "Bthung",
		position = util.vector3(84005, -133402, 500),
		intensity = 38,
		radius = 10218.00,
		climate = "volcanic",
		blendMode = 1,
	},
	{
		name = "Southeast OE",
		position = util.vector3(129472, -169479, 500),
		intensity = 8,
		radius = 42444.00,
		centerRadius = 3930.00,
		climate = "tropical",
		blendMode = 3,
	},
	{
		name = "Old Ebonheart Docks",
		position = util.vector3(64102, -139432, 2104),
		intensity = -15,
		radius = 11004.00,
		centerRadius = 5502.00,
		climate = "coastal",
		exponent = 0.6,
		blendMode = 3,
	},
	{
		name = "Old Ebonheart", -- 57506.589844, -152330.890625, 2393.983154 is epicenter point ; 51553 left side ; 64800 right side
		position = util.vector3(60527, -152100, 1000), --47434
		intensity = -6,
		radius = 9972.00,
		centerRadius = 5100.00,
		climate = "urban",
		exponent = 0.25,
		blendMode = 3,
	},
	{
		name = "Ebon Tower", -- -1455
		position = util.vector3(53677, -144614, 6103), --3400 radius center ; -140490.765625 550
		intensity = -13,
		radius = 6500,
		centerRadius = 1200,		
		exponent = 0.35,		
		climate = "cold",
		blendMode = 3,
	},
	{
		name = "Northern Ebon Shores",
		position = util.vector3(55157.449219, -137589.265625, 1044.918823), -- 55157.449219, -141430.078125, 2089.837646 ; 55074.683594, -133748.453125, 0
		intensity = -13,
		radius = 7500,
		centerRadius = 5500,	
		exponent = 0.35,		
		climate = "cold",
		blendMode = 3,
	},
	{
		name = "OE Outskirts",
		position = util.vector3(78525, -163315, 925),
		intensity = -5,
		radius = 27510.00,
		centerRadius = 13362.00,
		climate = "grassland",
		exponent = 0.51,
		blendMode = 3,
	},	
	
	{
		name = "Dondril",
		position = util.vector3(77558, -177655, 1900),
		intensity = 14,
		radius = 18078.00,
		centerRadius = 10218.00,
		climate = "urban",
		blendMode = 1,
	},
	{
		name = "Island South of Almas Thirr",
		position = util.vector3(54450, -256506, 500),
		intensity = 5,
		radius = 24366.00,
		centerRadius = 7074.00,
		climate = "grassland",
		blendMode = 3,
	},
	{
		name = "Northern Thirr River",
		position = util.vector3(46229, -173967, 705),
		intensity = -8,
		radius = 23580.00,
		centerRadius = 11790.00,
		climate = "coastal",
		exponent = 0.8,
		blendMode = 3,
	},
	{
		name = "Lake South of Aimrah",
		position = util.vector3(94638, -283548, 705),
		intensity = -2,
		radius = 33012.00,
		centerRadius = 18864.00,
		climate = "coastal",
		blendMode = 3,
	},
	{
		name = "Vhul",
		position = util.vector3(96150, -204696, 297),
		intensity = 10,
		radius = 25938.00,
		centerRadius = 10218.00,
		climate = "grassland",
		blendMode = 3,
	},
	{
		name = "Nav Andoram",
		position = util.vector3(70367, -267907, 164),
		intensity = 1,
		radius = 11004.00,
		centerRadius = 6288.00,
		climate = "urban",
		blendMode = 3,
	},
	{
		name = "Hlorandus",
		position = util.vector3(99981, -250153, 1379),
		intensity = 12,
		radius = 22794.00,
		centerRadius = 7860.00,
		climate = "grassland",
		exponent = 1.3,
		blendMode = 3,
	},
	{
		name = "Roa Dyr",
		position = util.vector3(67779, -217107, 746),
		intensity = 4,
		radius = 8646.00,
		centerRadius = 4716.00,
		climate = "urban",
		exponent = 0.9,
		blendMode = 3,
	},
	{
		name = "Selyn Plantation",
		position = util.vector3(71753, -232742, 652),
		intensity = 12,
		radius = 14934.00,
		centerRadius = 4000,
		climate = "tropical",
		exponent = 0.8,
		blendMode = 3,
	},
	{
		name = "Almas Thirr",
		position = util.vector3(46204, -223509, 3847),
		intensity = 2,
		radius = 20436.00,
		centerRadius = 7074.00,
		climate = "urban",
		exponent = 0.6,
		blendMode = 3,
	},
	{
		name = "Area West of Hla Oad",
		position = util.vector3(-1733, -204718, -72),
		intensity = 2,
		radius = 29082.00,
		centerRadius = 10218.00,
		climate = "tropical",
		exponent = 1.65,
		blendMode = 3,
	},
	{
		name = "Tur Julan",
		position = util.vector3(12503, -193201, 6366),
		intensity = 12,
		radius = 8646.00,
		centerRadius = 4716.00,
		climate = "ashland",
		exponent = 0.7999999999999998,
		blendMode = 3,
	},
	{
		name = "Indal Ruhn",
		position = util.vector3(18514, -222557, 59),
		intensity = 6,
		radius = 10218.00,
		centerRadius = 4716.00,
		climate = "urban",
		blendMode = 3,
	},
	{
		name = "Hlan Oek",
		position = util.vector3(6788, -255072, 865),
		intensity = 16,
		radius = 36942.00,
		centerRadius = 13362.00,
		climate = "tropical",
		exponent = 1.05,
		blendMode = 3,
	},
	{
		name = "Gol Mok",
		position = util.vector3(18337, -134601, 800),
		intensity = 8,
		radius = 14934.00,
		centerRadius = 7074.00,
		climate = "coastal",
		blendMode = 1,
	},
	{
		name = "Mushroom Forest",
		position = util.vector3(-11722, -312841, 1200),
		intensity = 12,
		radius = 33798.00,
		centerRadius = 20436.00,
		climate = "coastal",
		blendMode = 3,
	},
	{
		name = "Teyn",
		position = util.vector3(-27537, -102002, 1200),
		intensity = 1,
		radius = 16506.00,
		centerRadius = 7860.00,
		climate = "coastal",
		blendMode = 3,
	},
	{
		name = "Firewatch",
		position = util.vector3(-60865, -80631, 1200),
		intensity = 3,
		radius = 11790.00,
		centerRadius = 5502.00,
		climate = "coastal",
		blendMode = 1,
	},
	{
		name = "Omaynis",
		position = util.vector3(-45853, -140393, 500),
		intensity = 9,
		radius = 36942.00,
		centerRadius = 20436.00,
		climate = "grassland",
		blendMode = 3,
	},
	{
		name = "Bodrum",
		position = util.vector3(-95346, -140764, 3000),
		intensity = 8,
		radius = 8646.00,
		centerRadius = 4716.00,
		climate = "coastal",
		blendMode = 1,
	},
	{
		name = "Uman",
		position = util.vector3(-141976, -167044, 3000),
		intensity = 14,
		radius = 7860.00,
		centerRadius = 3930.00,
		climate = "urban",
		exponent = 0.35,
		blendMode = 3,
	},
	{
		name = "Northern Velothi Mountains",
		position = util.vector3(-161568, -185969, 5000),
		intensity = -32,
		radius = 42444.00,
		centerRadius = 14148.00,
		climate = "arctic",
		exponent = 0.85,
		blendMode = 3,
	},
	{
		name = "St. Felms Monestary",
		position = util.vector3(-95345, -148902, 3000),
		intensity = -4,
		radius = 50304.00,
		centerRadius = 10218.00,
		climate = "coastal",
		blendMode = 3,
	},
	{
		name = "Arvud",
		position = util.vector3(-29262, -208223, 500),
		intensity = -6,
		radius = 7074.00,
		centerRadius = 3930.00,
		climate = "urban",
		exponent = 0.6,
		blendMode = 3,
	},
	{
		name = "Western Arvud Ashlands",
		position = util.vector3(-98082, -196709, 500),
		intensity = 18,
		radius = 31440.00,
		centerRadius = 11790.00,
		climate = "ashland",
		exponent = 0.66,
		blendMode = 3,
	},
	{
		name = "Central Arvud Ashlands",
		position = util.vector3(-49305, -210018, 500),
		intensity = 18,
		radius = 45588.00,
		centerRadius = 29868.00,
		climate = "ashland",
		exponent = 1.5,
		blendMode = 3,
	},
	{
		name = "Othmura",
		position = util.vector3(35643, -300284, 1000),
		intensity = 8,
		radius = 33012.00,
		centerRadius = 10218.00,
		climate = "coastal",
		blendMode = 3,
	},
	{
		name = "Southern Ald Marak",
		position = util.vector3(38654, -351392, 500),
		intensity = 8,
		radius = 25152.00,
		centerRadius = 14148.00,
		climate = "coastal",
		blendMode = 1,
	},
	{
		name = "Western Mushroom Forest",
		position = util.vector3(-4694, -348877, 500),
		intensity = 17,
		radius = 34584.00,
		centerRadius = 8646.00,
		climate = "coastal",
		exponent = 0.96,
		blendMode = 3,
	},
	{
		name = "Eastern Mushroom Forest",
		position = util.vector3(16412, -381591, 500),
		intensity = 12,
		radius = 33012.00,
		centerRadius = 15720.00,
		climate = "coastal",
		blendMode = 3,
	},
	{
		name = "Almas Thirr 2",
		position = util.vector3(49062, -197990, 705),
		intensity = -10,
		radius = 22794.00,
		centerRadius = 11790.00,
		climate = "urban",
		exponent = 0.8,
		blendMode = 3,
	},
	{
		name = "Mundrethi Plantation",
		position = util.vector3(23176, -169478, 147),
		intensity = 14,
		radius = 20436.00,
		centerRadius = 10218.00,
		climate = "tropical",
		exponent = 0.8,
		blendMode = 3,
	},
	{
		name = "Indal-ruhn",
		position = util.vector3(25159, -202828, 147),
		intensity = 14,
		radius = 14148.00,
		centerRadius = 6288.00,
		climate = "tropical",
		exponent = 0.75,
		blendMode = 3,
	},
	{
		name = "Andothren",
		position = util.vector3(-7830, -145305, 1200),
		intensity = 12,
		radius = 35370.00,
		centerRadius = 15720.00,
		climate = "urban",
		blendMode = 3,
	},
	{
		name = "Velothi Mountains",
		position = util.vector3(-157008, -143215, 5000),
		intensity = -32,
		radius = 36156.00,
		centerRadius = 12576.00,
		climate = "arctic",
		exponent = 0.85,
		blendMode = 3,
	},
	-- Narsis (very hot but next to water)
	{
		name = "Eastern Narsis Shore",
		position = util.vector3(74748, -384761, 500),
		intensity = 10,
		radius = 30654.00,
		centerRadius = 7860.00,
		climate = "coastal",
		exponent = 0.45,
		blendMode = 3,
	},
	{
		name = "Desert 1",
		position = util.vector3(-5090, -429202, 1200),
		intensity = 23,
		radius = 44802.00,
		centerRadius = 23580.00,
		climate = "ashland",
		exponent = 0.5,
		blendMode = 3,
	},
	{
		name = "Shinal Pal",
		position = util.vector3(10847, -400789, 500),
		intensity = -9,
		radius = 10218.00,
		centerRadius = 6288.00,
		climate = "urban",
		blendMode = 3,
	},
	{
		name = "Narsis Air",
		position = util.vector3(51112, -408534, 13000),
		intensity = 14,
		radius = 17144.00,
		centerRadius = 7860.00,
		climate = "ashland",
		exponent = 0.75,
		blendMode = 3,
	},
	{
		name = "Narsis Underground",
		position = util.vector3(61028, -408000, -6000),
		intensity = 3,
		radius = 9072.00,
		centerRadius = 4716.00,
		climate = "coastal",
		exponent = 0.5,
		blendMode = 3,
	},
	{
		name = "Desert 2",
		position = util.vector3(-63123, -398840, 1500),
		intensity = 21,
		radius = 99280.00,
		centerRadius = 44016.00,
		climate = "ashland",
		exponent = 0.75,
		blendMode = 3,
	},
	{
		name = "Desert 3",
		position = util.vector3(33528, -449598, 1200),
		intensity = 21,
		radius = 38514.00,
		centerRadius = 19650.00,
		climate = "ashland",
		exponent = 0.3,
		blendMode = 3,
	},
	{
		name = "Desert 4",
		position = util.vector3(92591, -449922, 1200),
		intensity = 21,
		radius = 56592.00,
		centerRadius = 33012.00,
		climate = "ashland",
		exponent = 0.85,
		blendMode = 3,
	},
-- =================================================== SKYRIM: HOME OF THE NORDS ===================================================
	
	{
		name = "Southern Reach",
		position = util.vector3(-840746.000000, 28431.939453, 2578.603271), -- south of Karthwasten
		intensity = -35,
		radius = 55000,
		climate = "cold",
		exponent = 2, -- squareInfluence
	},
	{
		name = "Karthwasten",
		position = util.vector3(-848765.375000, 43273.554688, 4377.544434),
		intensity = 10,
		radius = 10000,
		climate = "urban",
		exponent = 1, -- squareInfluence
	},
	{
		name = "Vorngdad River Crossing",
		position = util.vector3(-838463.375000, 85069.281250, 967.980225),
		intensity = -10,
		radius = 60000,
		climate = "coastal",
		exponent = 2, -- squareInfluence
	},
    {
        name = "Karthgad",
        position = util.vector3(-831367.125000, 93571.921875, 3089.000000),
        intensity = 5,                               
        radius = 3000,
        climate = "urban",
        exponent = 0.7, -- squareInfluence
    },
    {
        name = "Vronberg Peak",
        position = util.vector3(-880024.812500, 99906.046875, 9696.071289),
        intensity = -10,                               
        radius = 90000,
        climate = "cold",
        exponent = 2, -- squareInfluence
    },
    {
        name = "North East Druadach Highlands",
        position = util.vector3(-947490.437500, 122790.734375, 8100.055176),
        intensity = -10,                               
        radius = 60000,
        climate = "cold",
        exponent = 2, -- squareInfluence
    },	-- -901321.937500, 123198.210938, 3535.152100
    {
        name = "North West Druadach Highlands",
        position = util.vector3(-901321.937500, 123198.210938, 3535.152100),
        intensity = -15,                               
        radius = 60000,
        climate = "cold",
        exponent = 1, -- squareInfluence
    },	
    {
        name = "Southern Druadach Highlands",
        position = util.vector3(-911909.562500, 81143.875000, 8231.844727),
        intensity = -6,                               
        radius = 60000,
        climate = "cold",
        exponent = 2, -- squareInfluence
    },
    {
        name = "Haimtir",
        position = util.vector3(-903830.875000, 69251.390625, 8093.222168),
        intensity = -5,                               
        radius = 3000,
        climate = "urban",
        exponent = 0.7, -- squareInfluence
    },	
    {
        name = "Saern",
        position = util.vector3(-888337.375000, 37173.097656, 8382.009766),
        intensity = -10,                               
        radius = 3000,
        climate = "cold",
        exponent = 0.7, -- squareInfluence
    },		
    {
        name = "Mirilstern",
        position = util.vector3(-887733.187500, 65897.859375, 7253.706055),
        intensity = -1,                               
        radius = 5000,
        climate = "urban",
        exponent = 1, -- squareInfluence
    },
    {
        name = "Merduibh",
        position = util.vector3(-951166.250000 , 100501.648438, 9075.352539),
        intensity = -15,                               
        radius = 6000,
        climate = "urban",
        exponent = 0.7, -- squareInfluence
    },
    {
        name = "Bailenoss",
        position = util.vector3(-963645.750000, 110893.140625, 9726.282227),
        intensity = -5,                               
        radius = 5000,
        climate = "urban",
        exponent = 0.7, -- squareInfluence
    },
    {
        name = "Dragonstar",
        position = util.vector3(-925010.687500, 106665.085938, 5543.631836),
        intensity = -14,                               
        radius = 10000,
        climate = "urban",
        exponent = 0.7, -- squareInfluence
    },
    {
        name = "Fort Vostangar",
        position = util.vector3(-889646.187500, 131624.765625, 4693.269043),
        intensity = -15,                               
        radius = 20000,
        climate = "cold",
        exponent = 1.5, -- squareInfluence
    },
    {
        name = "Eastern Reach Valley Peak",
        position = util.vector3(-903459.562500, 149219.250000, 3454.195801),
        intensity = -11,                               
        radius = 40000,
        climate = "cold",
        exponent = 1.5, -- squareInfluence
    },
    {
        name = "Northern Reach Valley",
        position = util.vector3(-917134.375000, 150782.437500, 284.984833),
        intensity = -4,                               
        radius = 15000,
        climate = "coastal",
        exponent = 2, -- squareInfluence
    },
    {
        name = "Northern Dwemer Ruins",
        position = util.vector3(-931091.125000, 175000.109375, 9989.604492),
		intensity = -17,
		radius = 80000,
		climate = "cold",
		exponent = 2, -- squareInfluence
	},
	-- -901321.937500, 123198.210938, 3535.152100
	-- -887733.187500, 65897.859375, 7253.706055	
	-- -911909.562500, 81143.875000, 8231.844727
	
-- ======================================================== PROJECT CYRODIIL =======================================================

	--Strident Coast
	{
		name = "Anvil Metropolis",
		position = util.vector3(-982268.500000, -449687.250000, 54.990334), -- right inside the main gates / near port
		intensity = 8,
		radius = 15000, 
		exponent = 2, -- squareInfluence
		climate = "urban",
	},
	{
		name = "Goldstone", -- fort/castle just westish of Anvil
		position = util.vector3(-991346.687500, -462415.718750, 3940.242188),
		intensity = 2,
		radius = 12000, 
		exponent = 2, -- squareInfluence
		climate = "urban",
	},
	{
		name = "Central Basin", 
		position = util.vector3(-981553.375000, -411549.375000, 2253.913818),
		intensity = 12,
		radius = 35000, 
		exponent = 2, -- squareInfluence
		climate = "tropical",
	},
	{
		name = "Central Coast", 
		position = util.vector3(-1010000.375000, -395000.375000, 2253.913818),
		intensity = 12,
		radius = 55000, 
		exponent = 2, -- squareInfluence
		climate = "tropical",
	},
	{
		name = "Eastern Hills",
		position = util.vector3(-915288.687500, -398940.968750, 2857.000000),
		intensity = 7,
		radius = 45000, 
		exponent = 2, -- squareInfluence
		climate = "grassland",
	},
	{
		name = "Central Grasslands",
		position = util.vector3(-933579.250000, -407790.375000, 2029.296875),
		intensity = 9,
		radius = 57250, 
		exponent = 2, -- squareInfluence
		climate = "grassland",
	},		
	{
		name = "River", 
		position = util.vector3(-941723.875000, -445309.656250, -143.532761),
		intensity = 8,
		radius = 40000, 
		exponent = 2, -- squareInfluence
		climate = "coastal",
	},
	{
		name = "Southeast Grasslands",
		position = util.vector3(-915703.750000, -447545.437500, 4417.484375),
		intensity = 12,
		radius = 60000, 
		climate = "grasslands",
		exponent = 1.5, -- squareInfluence
	},
	{
		name = "Dasek Marsh",
		position = util.vector3(-911427.937500, -466203.906250, -8.087215),
		intensity = 15,
		radius = 60000, 
		climate = "tropical",
		exponent = 1, -- squareInfluence
	},	
	
	-- Brennan Bluffs
	{
		name = "North Bluffs",
		position = util.vector3(-1007086.812500, -361634.250000, 3745.705566),
		intensity = 7,
		radius = 15000, 
		exponent = 2, -- squareInfluence
		climate = "ashland",
	},
	{
		name = "West Bluffs",
		position = util.vector3(-968501.500000, -374764.625000, 2779.492920),
		intensity = 7,
		radius = 42500, 
		exponent = 2, -- squareInfluence
		climate = "ashland",
	},
	{
		name = "East Bluffs",
		position = util.vector3(-941686.625000, -375296.218750, 4138.486328),
		intensity = 10,
		radius = 50000, 
		exponent = 2, -- squareInfluence
		climate = "ashland",
	},
	-- Abacean Sea
	{
		name = "South Abacean Sea",
		position = util.vector3(-1013792.125000, -467934.093750, 940.788635),
		intensity = 8,
		radius = 80000, 
		exponent = 2, -- squareInfluence
		climate = "coastal",
	},
	{
		name = "Southern Archipeligo", 
		position = util.vector3(-1045531.312500, -433413.718750, 1544.698242),
		intensity = 8,
		radius = 35000, 
		exponent = 2, -- squareInfluence
		climate = "tropical",
	},	
	{
		name = "North Abacean Sea",
		position = util.vector3(-1071855.000000, -405237.437500, 932.030701),
		intensity = 6,
		radius = 80000, 
		exponent = 2, -- squareInfluence
		climate = "coastal",
	},
	{
		name = "Stirk Island", 
		position = util.vector3(-1115045.125000, -405190.625000, 7236.096191), -- top of mountain
		intensity = 5,
		radius = 40000, 
		exponent = 2, -- squareInfluence
		climate = "tropical",
	},
	{
		name = "Northern Archipeligo", 
		position = util.vector3(-1087663.375000, -355880.000000, 2319.454346),
		intensity = 3,
		radius = 55000, 
		exponent = 2, -- squareInfluence
		climate = "tropical",
	},
-- ===================================================== WORTHY LANDMASS MODS ======================================================

	-- LYITHDONEA (tropical archipeligo) -- cool during the evenings, warm during the day and town center is hottest
	{
		name = "Central Island",
		position = util.vector3(715000.75, -615000, 1500),
		intensity = 10,
		radius = 10000,
		climate = "tropical",
		exponent = 0.7, -- squareInfluence
	},
		{
		name = "Lyithdonea Archipeligo",
		position = util.vector3(712605.75, -617658, 4000),
		intensity = 5,
		radius = 165000,
		exponent = 2, -- squareInfluence
		climate = "coastal",
	},
	-- few mountainous areas, 
	-- (707868.187500, -577316.875000, 7135.610352) ; 
	-- 
	-- (763507.562500, -653643.437500, 9642.374023)
	
	-- WINDHELM : THE CITY OF KINGS , by superliuk
    {
        name = "Windhelm City",
        position = util.vector3(-362000, 154000, 1300),     -- Western City Gate: (-358464.125000, 153153.296875, 624.864136) 8k x diff 5k y diff
        intensity = 7,                                     -- Eastern City Gate: (-366862.812500, 148029.125000, 911.160217)
        radius = 8500,
        climate = "urban",
--      exponent = 1.5, -- squareInfluence
    },
    {
        name = "Western Eastmarch",
        position = util.vector3(-368262.500000, 194052.953125, 3246.108887),
        intensity = -65,
        radius = 85000,
        climate = "arctic",
        exponent = 2.1, -- squareInfluence        
    },    
    {
        name = "Skyrim - Morrowind Border 1",
        position = util.vector3(-319463.125000, 159340.437500, 14606.377930),
        intensity = -75,
        radius = 60000,
        climate = "arctic",
        exponent = 3, -- squareInfluence
    },
    {
        name = "Skyrim - Morrowind Border 2",
        position = util.vector3(-311199.968750, 126159.945312, 20678.658203),
        intensity = -75,
        radius = 60000,
        climate = "arctic",
        exponent = 3, -- squareInfluence
    },
    {
        name = "Ruined Fort",
        position = util.vector3(-346872.906250, 133448.859375, 1280.310425),
        intensity = 10,                               
        radius = 1000,
        climate = "urban",
        exponent = 0.7, -- squareInfluence
    },
}