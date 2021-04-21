-- Initialises the current cell by creating/moving/disabling ore glow-lights

local DEBUG = 0

-------------------------------------------------
-- Useful debug and error routines
local function ERROR_text(...)
	local str=string.match(debug.traceback("",2),"GHLighting\\([%w\\%.]*:%d*)")
	mwse.log("[GHL] Error: %s  (%s)",string.format(...),str)
end

local function DEBUG_text(ilev,...)
	if (DEBUG < ilev) then return end
	mwse.log(...)
end

-------------------------------- MUST BE IN LOWER CASE --------------------------
local LightChanges={                                                       
	{"abanabi","ebony light"                         ,{-1739,  190, -340},{-1770,  330, -450}},
	{"abanabi","ebony light"                         ,{-2185,-1102,-2637},{-2257,-1111,-2597}},
	{"abanabi","ebony light"                         ,{-2233,-1320,-2573},{-2255,-1400,-2520}},
	{"abanabi","ebony light"                         ,{                 },{-2255,-1500,-1080}},
	{"caldera mine","ebony light"                    ,{                 },{ -220, 3600,  180}},
	{"caldera mine","ebony light"                    ,{                 },{ -566, 2659,  180}},
	{"caldera mine","ebony light"                    ,{                 },{ 4134, 6153,  160}},
	{"caldera mine","ebony light"                    ,{                 },{ 4360, 2320,  180}},
	{"caldera mine","ebony light"                    ,{                 },{ 4350, 4750,  100}},
	{"caldera mine","ebony light"                    ,{                 },{ 4785, 3344,  169}},
	{"caldera mine","ebony light"                    ,{                 },{ 5800, 5780,   60}},
	{"caldera mine","ebony light"                    ,{                 },{ 5979, 5273,  148}},
	{"caldera mine","ebony light"                    ,{                 },{  931, 3419,  183}},
	{"dissapla mine","green light_256"               ,{-1541, -624,   31},{-1580, -607,    8}},
	{"dissapla mine","green light_128"               ,{-1076, -128,   55},{-1050,  -81,   60}},
	{"dissapla mine","green light_256"               ,{ -717, 3632,  755},{ -780, 3632,  730}},
	{"dissapla mine","green light_256"               ,{ -417, 4104,  702},{ -530, 4150,  793}},
	{"dissapla mine","green light_256"               ,{  199, 1072,  -48},{  180, 1086,  -67}},
	{"dissapla mine","green light_256"               ,{ 1286, 2551,  480},{ 1200, 2570,  480}},
	{"dissapla mine","green light_256"               ,{ 1297, 1553,  -43},{ 1280, 1660, -110}},
	{"dissapla mine","green light_128"               ,{ 3120, 2033,  146},{ 3100, 2050,  146}},
	{"dissapla mine","bc mushroom 64"                ,{                 },{-2325,-1322,   72}},
	{"dissapla mine","bc mushroom 64"                ,{                 },{-2224,-1282,   42}},
	{"dissapla mine","green light_128"               ,{                 },{ -470, 3680,  650}},
	{"dunirai caverns","emerald light"               ,{-4695, 1156 ,  -6},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{-4695, 1156 ,  -6}},
	{"dunirai caverns","emerald light"               ,{-4510, 1599 ,  46},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{-4510, 1599,    0}},
	{"dunirai caverns","emerald light"               ,{-4451,  878 , -46},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{-4451,  878 , -46}},
	{"dunirai caverns","emerald light"               ,{-4402, 3454 ,  -5},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{-4402, 3454 ,  -5}},
	{"dunirai caverns","emerald light"               ,{-3737, 1565 , -11},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{-3700, 1566,   30}},
	{"dunirai caverns","emerald light"               ,{-2414,  893,  128},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{-2380,  900,  100}},
	{"dunirai caverns","emerald light"               ,{-2371, 1798 , 118},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{-2371, 1798 , 118}},
	{"dunirai caverns","emerald light"               ,{-2248, 1289,  233},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{-2130, 1250,  220}},
	{"dunirai caverns","emerald light"               ,{-2092, 1520,  105},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{-2050, 1550,  150}},
	{"dunirai caverns","emerald light"               ,{ -500, 6190 ,  73},{                 }},
	{"dunirai caverns","green light_128"             ,{                 },{ -500, 6190 ,  73}},
	{"ebonheart, underground caves","blue candle bulb_128",{-1539,1824, 323},{              }},
	{"ebonheart, underground caves","bc mushroom 128",{                 },{-1539, 1824,  323}},
	{"ebonheart, underground caves","blue candle bulb_128",{-721,1845,810},{                }},
	{"ebonheart, underground caves","bc mushroom 128",{                 },{ -721, 1845,  810}},
	{"elith-pal mine","ebony light"                  ,{ -300, -850, -100},{ -373, -811,  -24}},
	{"elith-pal mine","ebony light"                  ,{  492, 3911, -550},{  491, 3910, -493}},
	{"elith-pal mine","ebony light"                  ,{ 3280, -350, -193},{ 3241, -406, -192}},
	{"elith-pal mine","ebony light"                  ,{ 3426, -867, -150},{ 3426, -866, -131}},
	{"elith-pal mine","ebony light"                  ,{ 4540,-2523, -220},{ 4586,-2522, -177}},
	{"elith-pal mine","ebony light"                  ,{ 5655,-2607, -250},{ 5654,-2606, -181}},
    {"halit mine","green light_128"                  ,{ -407, -159,   45},{ -460, -159,   80}},
    {"halit mine","green light_128"                  ,{  695,-2176,   -8},{  660,-2200,  -30}},
	{"halit mine","green light_128"                  ,{ 1010,  595,   25},{ 1040,  660,   32}},
	{"halit mine","green light_128"                  ,{ 1678, 1561,   35},{ 1600, 1550,   50}},
	{"halit mine","green light_128"                  ,{ 2547,    8,   97},{ 2490, -100,   70}},
	{"halit mine","green light_128"                  ,{                 },{  170, -800,   68}},
	{"halit mine","green light_128"                  ,{                 },{ 1120, -260,   70}},
    {"halit mine","green light_128"                  ,{                 },{ 2320, 3000, -320}},
    {"halit mine","green light_128"                  ,{                 },{ 2700,   70,    0}},
    {"halit mine","green light_128"                  ,{                 },{ 2900, 1640,   50}},
    {"halit mine","green light_128"                  ,{                 },{ -260,  -70,   70}},
    {"halit mine","green light_128"                  ,{                 },{ 1590, 1350,   80}},
	{"maba-ilu","ebony light"                        ,{                 },{  350,  300,  260}},
	{"maba-ilu","green light_128"                    ,{                 },{  560,  450,  350}},
	{"massama cave","green light_128"                ,{-1600, 1744,    0},{-1600, 1670,    0}},
	{"massama cave","green light_128"                ,{ -528, 2848,    0},{ -510, 2900,   20}},
	{"massama cave","green light_128"                ,{ -176, 3856,  336},{ -300, 3800,  350}},
	{"massama cave","green light_128"                ,{  288, -448, -128},{  351, -451, -128}},
	{"massama cave","green light_256"                ,{  704, -496,  432},{  600, -590,  432}},
	{"massama cave","green light_128"                ,{ 2013, 3116,  198},{ 1919, 3122,  266}},
	{"massama cave","green light_128"                ,{ 2260, 2947,  278},{ 2320, 2900,  290}},
	{"massama cave","green light_128"                ,{ 3280, 3248,  240},{ 3370, 3350,  240}},
	{"massama cave","green light_128"                ,{                 },{-1193, -269, -692}},
	{"massama cave","green light_128"                ,{                 },{  -50, 3570,  100}},
	{"massama cave","green light_128"                ,{                 },{  670, -350,  570}},
	{"mausur caverns","ebony light"                  ,{ -989,  871, -723},{-1000,  850, -700}},
	{"mausur caverns","ebony light"                  ,{ -569, -589, -754},{ -541, -565, -739}},
	{"mausur caverns","ebony light"                  ,{ -489, 4005,  513},{ -485, 4043,  451}},
	{"mausur caverns","ebony light"                  ,{  148, 2074, -664},{  230, 2100, -660}},                                                                                               
	{"mausur caverns","ebony light"                  ,{  292, 1800, -602},{  280, 1840, -560}},
	{"mausur caverns","ebony light"                  ,{  302, 2021, -249},{  377, 2022, -290}},
	{"mausur caverns","ebony light"                  ,{ 1856, 3696,   96},{ 2030, 3670,   80}},
	{"mausur caverns","ebony light"                  ,{ 2183,  202, -957},{ 2200,  202, -980}},                                                                                               
	{"mausur caverns","ebony light"                  ,{ 2289,  512, -801},{ 2350,  570, -900}},                                                                                               
	{"mausur caverns","ebony light"                  ,{ 2326,  -95,-1096},{ 2280, -102,-1096}},
	{"mausur caverns","ebony light"                  ,{                 },{ 1580, 4330,  -50}},
	{"mausur caverns","ebony light"                  ,{                 },{ 2090, 4100, -170}},
	{"nchurdamz, interior","light_glowing_lichen_512_d",{-708,893,-212}  ,{                 }},
	{"nchurdamz, interior","green light_128"         ,{                 },{ -708,  893, -212}},
	{"norenen-dur, the teeth that gnash","adamantium",{ 5667, 6178,  555},{ 4100, 7000,  100}},
	{"norenen-dur, the teeth that gnash","adamantium",{ 5970, 6268,  910},{ 5950, 6300,  603}},
	{"old mournhold: armory ruins","adamantium"      ,{-1775,-2768, -200},{-1650,-2809, -250}},
	{"old mournhold: temple catacombs","adamantium"  ,{  467, 2159,  540},{  370, 2054,  570}},
	{"old mournhold: temple catacombs","adamantium"  ,{                 },{   50, 1620,  800}},
	{"old mournhold: temple crypt","adamantium"      ,{-6420,-3594, -895},{-6430,-3700, -895}},
	{"old mournhold: temple crypt","adamantium"      ,{-3511,  600, -515},{-3500,  650, -515}},
	{"old mournhold: temple crypt","adamantium"      ,{-3457,-1682, -928},{-3450,-1750, -928}},
	{"old mournhold: temple crypt","adamantium"      ,{-1174,-3382, -869},{-1050,-3400, -900}},
	{"old mournhold: temple crypt","adamantium"      ,{                 },{-6520,-3250, -837}},
	{"old mournhold: temple crypt","adamantium"      ,{                 },{-4796,-3372, -800}},
	{"old mournhold: temple crypt","adamantium"      ,{                 },{-3400,  420,  -49}},
    {"sudanit mine","ebony light"                    ,{-1812, 3795,-1550},{-1830, 3770,-1580}},
    {"sudanit mine","ebony light"                    ,{-1375, 2035,-1538},{-1400, 2090,-1538}},
    {"sudanit mine","ebony light"                    ,{ -414, 2469,-1532},{ -350, 2520,-1532}},
    {"sudanit mine","ebony light"                    ,{ 1638, 4558, -446},{ 1600, 4610, -420}},
	{"sudanit mine","ebony light"                    ,{                 },{  -73, 1541,-1531}},
	{"vassir-didanat cave","ebony light"             ,{  890, 3766,   14},{  930, 3800,   40}},
	{"vassir-didanat cave","ebony light"             ,{ 2352, 2560, -970},{ 2320, 2570,-1030}},
	{"vassir-didanat cave","ebony light"             ,{ 2803, 5876,  309},{ 2700, 5560,  250}},
	{"vassir-didanat cave","ebony light"             ,{ 3168, 1557, -842},{ 3160, 1520, -970}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ -950, 3800, -250}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 1020, 3710,   40}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 1391, 4128,   30}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 1577, 3152, -900}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 2290, 6400,  270}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 2400, 6519,  160}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 2500, 2400,-1030}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 2670, 5490,  -11}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 2850, 5900,  350}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 3230, 3000,-1000}},
	{"vassir-didanat cave","ebony light"             ,{                 },{ 3466, 2300, -800}},
    {"yanemus mine","ebony light"                    ,{-5068, 3643, -766},{-5000, 3700, -870}},
	{"yanemus mine","ebony light"                    ,{-4927, 3981, -770},{-4850, 4044, -820}},    
    {"yanemus mine","ebony light"                    ,{-3370, 5596,-1231},{-3300, 5550,-1330}},
    {"yanemus mine","ebony light"                    ,{-3287, 3242, -892},{-3287, 3260, -910}},
    {"yanemus mine","ebony light"                    ,{-2461, 2842, -928},{-2400, 2840, -900}},
	{"yanemus mine","ebony light"                    ,{-1864, 5757,-1299},{-1810, 5770,-1320}},    
    {"yanemus mine","ebony light"                    ,{ -233, 4055,-1758},{ -200, 4020,-1800}},
    {"yanemus mine","ebony light"                    ,{   33, 4631,-1723},{    0, 4660,-1723}},
	{"yanemus mine","ebony light"                    ,{  239, 2458,-2024},{  130, 2400,-2080}},    
    {"yanemus mine","ebony light"                    ,{ 1361, 3333,-2088},{ 1380, 3333,-2130}},
    {"yanemus mine","ebony light"                    ,{ 1793, 1241,-1756},{ 1820, 1200,-1780}},
	{"yanemus mine","ebony light"                    ,{                 },{-5388, 2893,-1430}},    
	{"yanemus mine","ebony light"                    ,{                 },{-3610, 2040,-1300}},    
	{"yanemus mine","ebony light"                    ,{                 },{ 1650, 1310,-2650}},    
	{"yanemus mine","ebony light"                    ,{                 },{ 1700, 2500,-2181}},    
	{"yassu mine","green light_128"                  ,{-1272, 2629,  -26},{-1217, 2513,   30}},
	{"yassu mine","green light_128"                  ,{-1183, 4960,  274},{-1160, 4850,  440}},
	{"yassu mine","green light_128"                  ,{  616, 4478,  474},{  610, 4310,  380}},
	{"yassu mine","green light_128"                  ,{ 2644, 3563, -176},{ 2730, 3550, -247}},
	{"yassu mine","green light_128"                  ,{ 2672, 4103, -176},{ 2592, 4082, -315}},  
	{"yassu mine","green light_128"                  ,{                 },{-1350, 4920,  120}},
	{"yassu mine","green light_128"                  ,{                 },{-1102, 5067,  236}},
	{"yassu mine","green light_128"                  ,{                 },{ -830, 2838,   18}},
	{"yassu mine","green light_128"                  ,{                 },{  -50, 2420,  -30}},
	{"yassu mine","green light_128"                  ,{                 },{  300, 5170,  820}},
	{"yassu mine","green light_128"                  ,{                 },{  500, 5030,  600}},
	{"yassu mine","green light_128"                  ,{                 },{  620,  900,   30}},
	{"yassu mine","green light_128"                  ,{                 },{  740, 4968,  320}},
	{"yassu mine","green light_128"                  ,{                 },{ 1630, 2913, -609}},
	{"yassu mine","green light_128"                  ,{                 },{ 2050, 2580, -255}},
	{"yassu mine","green light_128"                  ,{                 },{ 2260, 3712, -294}},
	{"yassu mine","green light_128"                  ,{                 },{ 2856, 3978, -133}},
	{"zenarbael","ebony light"                       ,{                 },{ 1592, 4331,  203}}  }

-- Only moves implemented for these
local PlantChanges={ {"dissapla mine","flora_bc_mushroom_02",{-2332,-1342,56},{-2332,-1342,65}},
					 {"dissapla mine","flora_bc_mushroom_03",{-2315,-1303,41},{-2315,-1303,50}},
			{"ebonheart, underground caves","flora_bc_mushroom_02",{-1601,1840,299},{0,0,999}} }


local vec3=tes3vector3.new()
--
local function Tab2Vec3(vec_in)
-- Convert plain vector to tes3vector
	vec3.x=vec_in[1]
	vec3.y=vec_in[2]
	vec3.z=vec_in[3]
	return vec3:copy()
end

local function FindObject(cell,sObject,fXYZ,sFilter)
--
-- Returns nil if no object within 5 units
	if (#fXYZ == 0) then return end
	local Vec3=Tab2Vec3(fXYZ)
	for ref in cell:iterateReferences(sFilter) do
		if (sObject == ref.baseObject.id:lower()) then
			if (Vec3:distance(ref.position) < 5) then
				return ref
			end
		end
	end
--
end

local function InitLightRef(cell,obj,xyz1,xyz2)
--
	local ref
--
	if (#xyz1 == 0) then
		ref=tes3.createReference( {object=obj,position=Tab2Vec3(xyz2),cell=cell} )
		DEBUG_text(2,"InitLightRef:Light created")
	else
		ref=FindObject(cell,obj,xyz1,tes3.objectType.light)
		if ref then
			if (#xyz2 == 0) then
				tes3.setEnabled({reference=ref,enabled=false})
				DEBUG_text(2,"InitLightRef:Light disabled")
			else
				ref.position=Tab2Vec3(xyz2)
				DEBUG_text(2,"InitLightRefsLight moved")
			end
		else
			ERROR_text("%s not at %s in %s",obj,Tab2Vec3(xyz1),cell.id)
		end
	end
--
	if ref then
		ref.object.modified=false
	end
--
end

local function InitPlantRefs(sCell,cell)
-- Move a few plants
--
	for i,v in ipairs(PlantChanges) do
		if (sCell == v[1]) then
			if v.done then
				DEBUG_text(2,"InitPlantRefs:Object skipped")
			else
				ref=FindObject(cell,v[2],v[3],tes3.objectType.container)
				if ref then
					ref.position=Tab2Vec3(v[4])
					ref:updateSceneGraph()
					ref.modified=false
					DEBUG_text(2,"InitOtherRefs:Plant moved")
					v.done=true
				else
					ERROR_text("%s not at %s in %s",v[2],Tab2Vec3(v[3]),cell.id)
				end
			end
		end
	end
--
end

function InitCellRefs()
--
	cell=tes3.getPlayerCell()
	DEBUG_text(1,"\nInitCellRefs: Running in %s",cell.id)
--
	local sCell=(cell.id):lower()
	if cell.isInterior then
		for _,v in ipairs(LightChanges) do
			if (v[1] == sCell) then
				if v.done then
					DEBUG_text(2,"InitLightRefs:Object skipped")
				else
					InitLightRef(cell,v[2],v[3],v[4])
					v.done=true
				end
			end
		end
	end
--
	InitPlantRefs(sCell,cell)
--
end
