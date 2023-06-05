local cf = mwse.loadConfig("HeartStrings", {lvl = 0, atk = 20, stop = false, intcom = false})

local function registerModConfig()		local tpl = mwse.mcm.createTemplate("HeartStrings")	tpl:saveOnClose("HeartStrings", cf)	tpl:register()	local p0 = tpl:createPage()	local var = mwse.mcm.createTableVariable
p0:createSlider{label = "Minimum level of humanoid type enemies to start combat music", min = 0, max = 100, step = 5, jump = 10, variable = var{id = "lvl", table = cf}}
p0:createSlider{label = "Minimum attack power of monster type enemies to start combat music", min = 0, max = 200, step = 5, jump = 10, variable = var{id = "atk", table = cf}}
p0:createYesNoButton{label = "Always start combat music in interiors regardless of enemies danger level", variable = var{id = "intcom", table = cf}}
p0:createYesNoButton{label = "Start a new track immediately when changing homogeneous locations", variable = var{id = "stop", table = cf}}
end		event.register("modConfigReady", registerModConfig)


local re = require("re")	local p, mp, D, COM		local Cach = {}		--local CT = timer
local function RandomFile(dir) local files = Cach[dir]	if not files then files = {}	for file in lfs.dir(dir) do if file:endswith("mp3") then table.insert(files, file) end end	Cach[dir] = files end	return table.choice(files) end


local C = {--Cell"] = "Folder",--CommentsComments 2Comments 3
["Balmora"] = "Town",--Hlaalu
["Suran"] = "Town",--Hlaalu
["Adonathran"] = "Town",--Hlaalu
["Menaan"] = "Town",--Hlaalu
["Arvud"] = "Town",--Hlaalu
["Indal-Ruhn"] = "Town",--Hlaalu
["Kragen Mar"] = "Town",--Hlaalu
["Hlan Oek"] = "Town",--Hlaalu
["Idathen"] = "Town",--Hlaalu
["Othmura"] = "Town",--Hlaalu
["Uneyn"] = "Town",--Hlaalu
["Ilaanam"] = "Town",--Hlaalu
["Hlarud"] = "Town",--Hlaalu
["Narun"] = "Town",--Hlaalu
["Ud Hleryn"] = "Town",--Hlaalu
["Sadrathim"] = "Town",--Hlaalu
["Shipal Sharai"] = "Town",--Hlaalu
["Narsis"] = "Town",--Hlaalu
["Andothren"] = "Town",--Hlaalu
["Armun Pass Outpost"] = "Town",--Hlaalu
["Nav Andaram"] = "Town",--Hlaalu
["Omaynis"] = "Town",--Hlaalu
["Ald-ruhn"] = "Town",--Redoran
["Gnisis"] = "Town",--Redoran
["Maar Gan"] = "Town",--Redoran
["Kogomar"] = "Town",--Redoran
["Kogotel"] = "Town",--Redoran
["Rhanim"] = "Town",--Redoran
["Verachen"] = "Town",--Redoran
["Kartur"] = "Town",--Redoran
["Bodrem"] = "Town",--Redoran
["Baan Malur"] = "Town",--Redoran
["Soluthis"] = "Town",--Redoran
["Rhun Huk"] = "Town",--Redoran
["Bodrum"] = "Town",--Redoran
["Uman"] = "Town",--Redoran
["Sadrith Mora"] = "Town",--Telvanni
["Tel Aruhn"] = "Town",--Telvanni
["Tel Branora"] = "Town",--Telvanni
["Tel Mora"] = "Town",--Telvanni
["Uvirith's Grave"] = "Town",--Telvanni
["Vos"] = "Town",--Telvanni
["Alt Bosara"] = "Town",--Telvanni
["Gah Sadrith"] = "Town",--Telvanni
["Llothanis"] = "Town",--Telvanni
["Marog"] = "Town",--Telvanni
["Port Telvannis"] = "Town",--Telvanni
["Ranyon-ruhn"] = "Town",--Telvanni
["Tel Aranyon"] = "Town",--Telvanni
["Tel Drevis"] = "Town",--Telvanni
["Tel Gilan"] = "Town",--Telvanni
["Tel Mothrivra"] = "Town",--Telvanni
["Tel Muthada"] = "Town",--Telvanni
["Tel Oren"] = "Town",--Telvanni
["Tel Ouada"] = "Town",--Telvanni
["Tel Rivus"] = "Town",--Telvanni
["Verulas Pass"] = "Town",--Telvanni
["Mournhold"] = "Town",--Indoril
["Almalexia"] = "Town",--Indoril
["Aimrah"] = "Town",--Indoril
["Akamora"] = "Town",--Indoril
["Ammar"] = "Town",--Indoril
["Bosmora"] = "Town",--Indoril
["Dreynim Spa"] = "Town",--Indoril
["Enamor Dayn"] = "Town",--Indoril
["Gorne"] = "Town",--Indoril
["Meralag"] = "Town",--Indoril
["Roa Dyr"] = "Town",--Indoril
["Sailen"] = "Town",--Indoril
["Vhul"] = "Town",--Indoril
["Othrenis"] = "Town",--Indoril
["Vivec"] = "Town",--Vivec
["Almas Thirr"] = "Temple",--Indoril Temple
["Necrom"] = "Temple",--Indoril Temple
["Caldera"] = "Town",--Imperial
["Ebonheart"] = "Town",--Imperial
["Pelagiad"] = "Town",--Imperial
["Raven Rock"] = "Town",--Imperial
["Old Ebonheart"] = "Town",--Imperial
["Firewatch"] = "Town",--Imperial
["Helnim"] = "Town",--Imperial
["Cormar"] = "Town",--Imperial
["Bal Oyra"] = "Town",--Imperial
["Nivalis"] = "Town",--Imperial
["Teyn"] = "Town",--Imperial
["Seyda Neen"] = "Town",--Village
["Hla Oad"] = "Town",--Village
["Gnaar Mok"] = "Town",--Village
["Ald Velothi"] = "Town",--Village
["Fair Helas"] = "Town",--Village
["Khuul"] = "Town",--Village
["Bahrammu"] = "Town",--Village
["Baldrahn"] = "Town",--Village
["Dondril"] = "Town",--Village
["Eravan"] = "Town",--Village
["Felms Ithul"] = "Town",--Village
["Hla Bulor"] = "Town",--Village
["Saveri"] = "Town",--Village
["Selyn"] = "Town",--Village
["Tahvel"] = "Town",--Village
["Velonith"] = "Town",--Village
["Arvel Plantation"] = "Town",--Plantation
["Dren Plantation"] = "Town",--Plantation
["Erethan Plantation"] = "Town",--Plantation
["Mundrethi Plantation"] = "Town",--Plantation
["Nethril Plantation"] = "Town",--Plantation
["Oran Plantation"] = "Town",--Plantation
["Orelu Plantation"] = "Town",--Plantation
["Sadas Plantation"] = "Town",--Plantation
["Sadavel Plantation"] = "Town",--Plantation
["Savrethi Distillery"] = "Town",--Plantation
["Tel Ouada Guar Farm"] = "Town",--Plantation
["Vathras Plantation"] = "Town",--Plantation
["Veralan Farm"] = "Town",--Plantation
["Buckmoth Legion Fort"] = "Fort",--Fort
["Gnisis, Fort Darius"] = "Fort",--Fort
["Fort Frostmoth"] = "Fort",--Fort
["Moonmoth Legion Fort"] = "Fort",--Fort
["Sadrith Mora, Wolverine Hall"] = "Fort",--Fort
["Pelagiad, Fort Pelagiad"] = "Fort",--Fort
["Pelagiad, Guard Tower"] = "Fort",--Fort
["Pelagiad, North Wall"] = "Fort",--Fort
["Pelagiad, South Wall"] = "Fort",--Fort
["Cephorad Keep"] = "Fort",--Fort
["Dustmoth Legion Garrison"] = "Fort",--Fort
["Ebon Tower"] = "Fort",--Fort
["Fort Ancylis"] = "Fort",--Fort
["Fort Servas"] = "Fort",--Fort
["Fort Umbermoth"] = "Fort",--Fort
["Icebreaker Keep"] = "Fort",--Fort
["Imperial Guard"] = "Fort",--Fort
["Imperial Navy Command Post"] = "Fort",--Fort
["Ebonheart, Hawkmoth Legion Garrison"] = "Fort",--Fort
["Ebonheart, Hawkmoth Towers"] = "Fort",--Fort
["Ebonheart, Imperial Guard Garrison"] = "Fort",--Fort
["Molag Mar"] = "Town",--Indoril
["Raven Rock, Factor's Estate"] = "Town",--Estate
["Mournhold, Velas Manor"] = "Town",--Estate
["Indarys Manor"] = "Town",--Estate
["Rethan Manor"] = "Town",--Estate
["Tel Uvirith"] = "Town",--Estate
["Skaal Village"] = "Skyrim",--Nord
["Solstheim, Thirsk"] = "Skyrim",--Nord
["Aleft"] = "Dwemer",--Dwemer
["Arkngthand"] = "Dwemer",--Dwemer
["Bethamez"] = "Dwemer",--Dwemer
["Bthanchend"] = "Dwemer",--Dwemer
["Bthuand"] = "Dwemer",--Dwemer
["Bthungthumz"] = "Dwemer",--Dwemer
["Mudan"] = "Dwemer",--Dwemer
["Mzahnch"] = "Dwemer",--Dwemer
["Mzanchend"] = "Dwemer",--Dwemer
["Mzuleft"] = "Dwemer",--Dwemer
["Nchardahrk"] = "Dwemer",--Dwemer
["Nchardumz"] = "Dwemer",--Dwemer
["Nchuleft"] = "Dwemer",--Dwemer
["Nchuleftingth"] = "Dwemer",--Dwemer
["Nchurdamz"] = "Dwemer",--Dwemer
["Sorkvild's Tower"] = "Dwemer",--Dwemer
["Arkngthunch-Sturdumz"] = "Dwemer",--Dwemer
["Bamz-Amschend"] = "Dwemer",--Dwemer
["Akuband"] = "Dwemer",--Dwemer TR
["Alencheth"] = "Dwemer",--Dwemer TR
["Amthuandz"] = "Dwemer",--Dwemer TR
["Archtumz"] = "Dwemer",--Dwemer TR
["Arkgnthleft"] = "Dwemer",--Dwemer TR
["Barzamthuand"] = "Dwemer",--Dwemer TR
["Bazak"] = "Dwemer",--Dwemer TR
["Bazhthum"] = "Dwemer",--Dwemer TR
["Bthalag-Zturamz"] = "Dwemer",--Dwemer TR
["Bthangthamuzand"] = "Dwemer",--Dwemer TR
["Bthuangthuv"] = "Dwemer",--Dwemer TR
["Bthung"] = "Dwemer",--Dwemer TR
["Bthungtch"] = "Dwemer",--Dwemer TR
["Bthzundcheft"] = "Dwemer",--Dwemer TR
["Chunzefk"] = "Dwemer",--Dwemer TR
["Durthungz"] = "Dwemer",--Dwemer TR
["Hendor-Stardumz"] = "Dwemer",--Dwemer TR
["Kemel-Ze"] = "Dwemer",--Dwemer TR
["Khadumzunch"] = "Dwemer",--Dwemer TR
["Leftunch"] = "Dwemer",--Dwemer TR
["Manrizache"] = "Dwemer",--Dwemer TR
["Mvelthngth-Schel"] = "Dwemer",--Dwemer TR
["Mzankh"] = "Dwemer",--Dwemer TR
["Mzungleft"] = "Dwemer",--Dwemer TR
["Nchazdrumn"] = "Dwemer",--Dwemer TR
["Nchulark"] = "Dwemer",--Dwemer TR
["Nchulegfth"] = "Dwemer",--Dwemer TR
["Ngelfltingth"] = "Dwemer",--Dwemer TR
["Ratharzak"] = "Dwemer",--Dwemer TR
["Rthungzark"] = "Dwemer",--Dwemer TR
["Yaztaramz"] = "Dwemer",--Dwemer TR
["Addadshashanammu"] = "Daedric",--Daedric
["Ald Daedroth"] = "Daedric",--Daedric
["Ald Sotha"] = "Daedric",--Daedric
["Almurbalarammi"] = "Daedric",--Daedric
["Anudnabia"] = "Daedric",--Daedric
["Ashalmawia"] = "Daedric",--Daedric
["Ashalmimilkala"] = "Daedric",--Daedric
["Ashunartes"] = "Daedric",--Daedric
["Ashurnibibi"] = "Daedric",--Daedric
["Assalkushalit"] = "Daedric",--Daedric
["Assarnatamat"] = "Daedric",--Daedric
["Assernerairan"] = "Daedric",--Daedric
["Assurdirapal"] = "Daedric",--Daedric
["Assurnabitashpi"] = "Daedric",--Daedric
["Bal Fell"] = "Daedric",--Daedric
["Bal Ur"] = "Daedric",--Daedric
["Dushariran"] = "Daedric",--Daedric
["Ebernanit"] = "Daedric",--Daedric
["Esutanamus"] = "Daedric",--Daedric
["Ibishammus"] = "Daedric",--Daedric
["Ihinipalit"] = "Daedric",--Daedric
["Kaushtarari"] = "Daedric",--Daedric
["Kushtashpi"] = "Daedric",--Daedric
["Maelkashishi"] = "Daedric",--Daedric
["Magas Volar"] = "Daedric",--Daedric
["Onnissiralis"] = "Daedric",--Daedric
["Ramimilk"] = "Daedric",--Daedric
["Shashpilamat"] = "Daedric",--Daedric
["Tusenend"] = "Daedric",--Daedric
["Ularradallaku"] = "Daedric",--Daedric
["Yansirramus"] = "Daedric",--Daedric
["Yasammidan"] = "Daedric",--Daedric
["Zaintiraris"] = "Daedric",--Daedric
["Zergonipal"] = "Daedric",--Daedric
["Norenen-dur"] = "Daedric",--Daedric
["Ald Balaal"] = "Daedric",--Daedric TR
["Ald Mirathi"] = "Daedric",--Daedric TR
["Ald Niripal"] = "Daedric",--Daedric TR
["Ald Uman"] = "Daedric",--Daedric TR
["Ald Uran"] = "Daedric",--Daedric TR
["Alumawia"] = "Daedric",--Daedric TR
["Anashbibi"] = "Daedric",--Daedric TR
["Ashpibishal"] = "Daedric",--Daedric TR
["Ashushushi"] = "Daedric",--Daedric TR
["Baelkashpitu"] = "Daedric",--Daedric TR
["Bal Dushal"] = "Daedric",--Daedric TR
["Balititashpi"] = "Daedric",--Daedric TR
["Bapatipi"] = "Daedric",--Daedric TR
["Bushipananit"] = "Daedric",--Daedric TR
["Ebamusharisus"] = "Daedric",--Daedric TR
["Ebunammidan"] = "Daedric",--Daedric TR
["Essarnartes"] = "Daedric",--Daedric TR
["Esuranamit"] = "Daedric",--Daedric TR
["Hadrumnibibi"] = "Daedric",--Daedric TR
["Hummurushtapi"] = "Daedric",--Daedric TR
["Ibiammusashan"] = "Daedric",--Daedric TR
["Ikinammassu"] = "Daedric",--Daedric TR
["Kannidamarus"] = "Daedric",--Daedric TR
["Malkamalit"] = "Daedric",--Daedric TR
["Mashadananit"] = "Daedric",--Daedric TR
["Onimushili"] = "Daedric",--Daedric TR
["Ossurnashalit"] = "Daedric",--Daedric TR
["Shambalu"] = "Daedric",--Daedric TR
["Teknilashashulpi"] = "Daedric",--Daedric TR
["Ulanababia"] = "Daedric",--Daedric TR
["Veranzaris"] = "Daedric",--Daedric TR
["Yabananit"] = "Daedric",--Daedric TR
["Yamandalkal"] = "Daedric",--Daedric TR
["Yamuninisharn"] = "Daedric",--Daedric TR
["Yanishanabi"] = "Daedric",--Daedric TR
["Yashazmus"] = "Daedric",--Daedric TR
["Andasreth"] = "Dunge",--Stronghold
["Berandas"] = "Dunge",--Stronghold
["Falensarano"] = "Dunge",--Stronghold
["Hlormaren"] = "Dunge",--Stronghold
["Indoranyon"] = "Dunge",--Stronghold
["Marandus"] = "Dunge",--Stronghold
["Rotheran"] = "Dunge",--Stronghold
["Valenvaryon"] = "Dunge",--Stronghold
["Ald Erfoud Ruins"] = "Dunge",--Stronghold TR
["Ald Verya Ruins"] = "Dunge",--Stronghold TR
["Andvaryon"] = "Dunge",--Stronghold TR
["Baan Urlai"] = "Dunge",--Stronghold TR
["Bahrund"] = "Dunge",--Stronghold TR
["Bisandryon"] = "Dunge",--Stronghold TR
["Dun Akafell"] = "Dunge",--Stronghold TRVampire
["Idaverrano"] = "Dunge",--Stronghold TR
["Khirakai"] = "Dunge",--Stronghold TRVampire
["Koranyon"] = "Dunge",--Stronghold TR
["Mandaran"] = "Dunge",--Stronghold TR
["Merihayan"] = "Dunge",--Stronghold TR
["Romayon"] = "Dunge",--Stronghold TRVampire
["Salandus"] = "Dunge",--Stronghold TR
["Tirilathran"] = "Dunge",--Stronghold TR
["Tulesmath"] = "Dunge",--Stronghold TR
["Tur Julan"] = "Dunge",--Stronghold TR
["Turendas"] = "Dunge",--Stronghold TR
["Valandus"] = "Dunge",--Stronghold TR
["Veremmu"] = "Dunge",--Stronghold TR
["Volenfaryon"] = "Dunge",--Stronghold TR
["Zanammu"] = "Dunge",--Stronghold TR
["Zuldassur Manor"] = "Dunge",--Stronghold TR
["Dagoth Ur"] = "Red Mountain",--Dagoth Red
["Dagoth Ur, Facility Cavern"] = "Boss",--Dagoth Red
["Endusal"] = "Red Mountain",--Dagoth Red
["Kogoruhn"] = "Dagoth",--Dagoth
["Mamaea"] = "Dagoth",--Dagoth
["Odrosal"] = "Red Mountain",--Dagoth Red
["Tureynulal"] = "Red Mountain",--Dagoth Red
["Vemynal"] = "Red Mountain",--Dagoth Red
["Abinabi"] = "Dagoth",--Dagoth
["Ainab"] = "Dagoth",--Dagoth
["Assemanu"] = "Dagoth",--Dagoth
["Bensamsi"] = "Dagoth",--Dagoth
["Falasmaryon"] = "Dagoth",--Dagoth
["Hassour"] = "Dagoth",--Dagoth
["Ilunibi"] = "Dagoth",--Dagoth
["Maran-Adon"] = "Dagoth",--Dagoth
["Missamsi"] = "Dagoth",--Dagoth
["Morvayn Manor"] = "Dagoth",--Dagoth
["Piran"] = "Dagoth",--Dagoth
["Rissun"] = "Dagoth",--Dagoth
["Salmantu"] = "Dagoth",--Dagoth
["Sanit"] = "Dagoth",--Dagoth
["Sennananit"] = "Dagoth",--Dagoth
["Sharapli"] = "Dagoth",--Dagoth
["Subdun"] = "Dagoth",--Dagoth
["Telasero"] = "Dagoth",--Dagoth
["Yakin"] = "Dagoth",--Dagoth
["Vissamu"] = "Dagoth",--Dagoth
["Ashmelech"] = "Dunge",--TombVampire
["Druscashti"] = "Dunge",--DwemerVampire
["Galom Daeus"] = "Dunge",--DwemerVampire
["Ald Virak"] = "Dunge",--VampireVampire
["Anbarsud"] = "Dunge",--VampireVampire
["Abaelun Mine"] = "Mine",--Mine
["Caldera Mine"] = "Mine",--Mine
["Dissapla Mine"] = "Mine",--Mine
["Dunirai Caverns"] = "Mine",--Mine
["Elith-Pal Mine"] = "Mine",--Mine
["Halit Mine"] = "Mine",--Mine
["Massama Cave"] = "Mine",--Mine
["Mausur Caverns"] = "Mine",--Mine
["Sudanit Mine"] = "Mine",--Mine
["Vassir-Didanat Cave"] = "Mine",--Mine
["Yanemus Mine"] = "Mine",--Mine
["Yassu Mine"] = "Mine",--Mine
["Raven Rock, Mine"] = "Mine",--Mine
["Raven Rock, Mine Entrance"] = "Mine",--Mine
["Raven Rock, Abandoned Mine Shaft"] = "Mine",--Mine
["Addai Mine"] = "Mine",--Mine TR
["Balsin Mine"] = "Mine",--Mine TR
["Belan Mine"] = "Mine",--Mine TR
["Dilitan Mine"] = "Mine",--Mine TR
["Gilvan-Tidrith Mine"] = "Mine",--Mine TR
["Harrumat Mine"] = "Mine",--Mine TR
["Hlersis Mine"] = "Mine",--Mine TR
["Ilvi Mine"] = "Mine",--Mine TR
["Issurnawia Mine"] = "Mine",--Mine TR
["Litu-Dur Mine"] = "Mine",--Mine TR
["Mannusudipat Mine"] = "Mine",--Mine TR
["Murahn-Cithal Mine"] = "Mine",--Mine TR
["Nerebys Mine"] = "Mine",--Mine TR
["Pamonibu Mine"] = "Mine",--Mine TR
["Pulummu Mine"] = "Mine",--Mine TR
["Ranyon-ruhn Mine"] = "Mine",--Mine TR
["Sadrapit Mine"] = "Mine",--Mine TR
["Sassur-Dari Mine"] = "Mine",--Mine TR
["Shubattu Mine"] = "Mine",--Mine TR
["Tahvel Iron Mine"] = "Mine",--Mine TR
["Terendas Mine"] = "Mine",--Mine TR
["Thalotheran Quarry"] = "Mine",--Mine TR
["Ushu-Kur"] = "Mine",--Mine TR
["Vantus Mine"] = "Mine",--Mine TR
["Varethan Mine"] = "Mine",--Mine TR
["Veramus Mine"] = "Mine",--Mine TR
["Yanimmu Mine"] = "Mine",--Mine TR
["Sotha Sil"] = "Dwemer",--
["Sotha Sil, Dome of Sotha Sil"] = "Boss",--
["Old Mournhold"] = "Dunge",--
["Cavern of the Incarnate"] = "Incarnate",--
["Ghostgate"] = "Temple",--
["Akulakhan's Chamber"] = "Dagoth Ur",--
["Solstheim, Mortrag Glacier: Entry"] = "Dunge",--
["Solstheim, Mortrag Glacier: Inner Ring"] = "Dunge",--
["Solstheim, Mortrag Glacier: Outer Ring"] = "Dunge",--
["Solstheim, Mortrag Glacier: Huntsman's Hall"] = "Boss",--
["Falasmaryon, Sewers"] = "Dunge",--Sewers
["Hlormaren, Sewers"] = "Dunge",--Sewers
["Molag Mar, Underworks"] = "Dunge",--Sewers
["Vivec, Arena Underworks"] = "Dunge",--Sewers
["Vivec, Foreign Quarter Underworks"] = "Dunge",--Sewers
["Vivec, Hall Underworks"] = "Dunge",--Sewers
["Vivec, Hlaalu Underworks"] = "Dunge",--Sewers
["Vivec, Redoran Underworks"] = "Dunge",--Sewers
["Vivec, St. Delyn Underworks"] = "Dunge",--Sewers
["Vivec, St. Olms Underworks"] = "Dunge",--Sewers
["Vivec, Telvanni Underworks"] = "Dunge",--Sewers
["Vivec, Puzzle Canal, Center"] = "Dunge",--Sewers
["Vivec, Puzzle Canal, Level 1"] = "Dunge",--Sewers
["Vivec, Puzzle Canal, Level 2"] = "Dunge",--Sewers
["Vivec, Puzzle Canal, Level 3"] = "Dunge",--Sewers
["Vivec, Puzzle Canal, Level 4"] = "Dunge",--Sewers
["Vivec, Puzzle Canal, Level 5"] = "Dunge",--Sewers
["Gnisis, Arvs-Drelen"] = "Dunge",--Velothi Tower
["Hanud"] = "Dunge",--Velothi Tower
["Mababi"] = "Dunge",--Velothi Tower
["Mawia"] = "Dunge",--Velothi Tower
["Odirniran"] = "Dunge",--Velothi Tower
["Sanni"] = "Dunge",--Velothi Tower
["Shara"] = "Dunge",--Velothi Tower
["Shishi"] = "Dunge",--Velothi Tower
["Sulipund"] = "Dunge",--Velothi Tower
["Ald Redaynia"] = "Dunge",--Velothi Tower
["Vas"] = "Dunge",--Velothi Tower
["Shrine of Azura"] = "Temple",--Azura ShrineAzura Shrine
["Emmurbalpitu"] = "Temple",--Azura ShrineAzura Shrine
["Mournhold Temple"] = "Temple",--Indoril Temple
["Mournhold, Temple Courtyard"] = "Temple",--Indoril Temple
["Vivec, Temple"] = "Temple",--Vivec
["Vivec, Canon Offices"] = "Temple",--Vivec
["Vivec, Canon Quarters"] = "Temple",--Vivec
["Vivec, High Fane"] = "Temple",--Vivec
["Vivec, Hall of Wisdom"] = "Temple",--Vivec
["Vivec, Hall of Justice"] = "Temple",--Vivec
["Vivec, Justice Offices"] = "Temple",--Vivec
["Vivec, Milo's Quarters"] = "Temple",--Vivec
["Vivec, Office of the Watch"] = "Temple",--Vivec
["Vivec, Ordinator Barracks"] = "Temple",--Vivec
["Vivec, Palace of Vivec"] = "Temple",--Vivec
["Holamayan Monastery"] = "Temple",--
["Baluridan"] = "Mine",--Kwama TR
["Menuas-Ahhe"] = "Mine",--Kwama TR
["Abaesen-Pulu Egg Mine"] = "Mine",--Kwama
["Abebaal Egg Mine"] = "Mine",--Kwama
["Ahallaraddon Egg Mine"] = "Mine",--Kwama
["Ahanibi-Malmus Egg Mine"] = "Mine",--Kwama
["Akimaes-Ilanipu Egg Mine"] = "Mine",--Kwama
["Asha-Ahhe Egg Mine"] = "Mine",--Kwama
["Ashimanu Egg Mine"] = "Mine",--Kwama
["Band Egg Mine"] = "Mine",--Kwama
["Eluba-Addon Egg Mine"] = "Mine",--Kwama
["Eretammus-Sennammu Egg Mine"] = "Mine",--Kwama
["Gnisis, Eggmine"] = "Mine",--Kwama
["Gnisis, Lower Eggmine"] = "Mine",--Kwama
["Hairat-Vassamsi Egg Mine"] = "Mine",--Kwama
["Hawia Egg Mine"] = "Mine",--Kwama
["Inanius Egg Mine"] = "Mine",--Kwama
["Madas-Zebba Egg Mine"] = "Mine",--Kwama
["Maelu Egg Mine"] = "Mine",--Kwama
["Maesa-Shammus Egg Mine"] = "Mine",--Kwama
["Matus-Akin Egg Mine"] = "Mine",--Kwama
["Missir-Dadalit Egg Mine"] = "Mine",--Kwama
["Mudan-Mul Egg Mine"] = "Mine",--Kwama
["Panabanit-Nimawia Egg Mine"] = "Mine",--Kwama
["Panud Egg Mine"] = "Mine",--Kwama
["Pudai Egg Mine"] = "Mine",--Kwama
["Sarimisun-Assa Egg Mine"] = "Mine",--Kwama
["Setus Egg Mine"] = "Mine",--Kwama
["Shulk Egg Mine"] = "Mine",--Kwama
["Shurdan-Raplay Egg Mine"] = "Mine",--Kwama
["Sinamusa Egg Mine"] = "Mine",--Kwama
["Sinarralit Egg Mine"] = "Mine",--Kwama
["Sur Egg Mine"] = "Mine",--Kwama
["Vansunalit Egg Mine"] = "Mine",--Kwama
["Zalkin-Sul Egg Mine"] = "Mine",--Kwama
["Ministry of Truth, Hall of Processing"] = "Dunge",--Vivec
["Ministry of Truth, Holding Cells"] = "Dunge",--Vivec
["Ministry of Truth, Prison Keep"] = "Dunge",--Vivec
["Andar Mok"] = "Town",--Village Port
["Darvonis"] = "Town",--Village Port
["Dreynim"] = "Town",--Village Port
["Gol Mok"] = "Town",--Village Port
["Rilsoan"] = "Town",--Village Port
["Seitur"] = "Town",--Village Port
["Windbreaker Keep"] = "Town",--Village Port
["Tel Fyr"] = "Explore",--Telvanni
["Drakehold Ruin"] = "Tomb",--Tomb TR
["Drolar Manor Ruin"] = "Tomb",--Tomb TR
["Dunada-Nammu"] = "Tomb",--Tomb TR
["Dusara"] = "Tomb",--Tomb TR
["Ermunsour, Forgotten Shrine"] = "Tomb",--Tomb TR
["Thelaro Chapel"] = "Tomb",--Tomb TR
["Wavebreaker Keep"] = "Tomb",--Tomb TR
["Yalamalku"] = "Tomb",--Tomb TR
}



local R = {
["Bitter Coast Region"] = "Explore",
["Azura's Coast Region"] = "Explore",
["Molag Mar Region"] = "Ashland",
["Ashlands Region"] = "Ashland",
["West Gash Region"] = "Explore",
["Red Mountain Region"] = "Red Mountain",
["Ascadian Isles Region"] = "Explore",
["Grazelands Region"] = "Explore",
["Sheogorad"] = "Explore",
["Mournhold Region"] = "Town",
["Felsaad Coast Region"] = "Skyrim",
["Moesring Mountains Region"] = "Skyrim",
["Isinfier Plains Region"] = "Skyrim",
["Hirstaang Forest Region"] = "Skyrim",
["Brodir Grove Region"] = "Skyrim",
["Thirsk Region"] = "Skyrim",

--["Aanthirin Region"] = "",
--["Abecean Sea Region"] = "",
--["Alt Orethan Region"] = "",
--["Aranyon Pass Region"] = "",
["Armun Ashlands Region"] = "Ashland",
--["Arnesian Jungle Region"] = "",
--["Ascadian Bluffs Region"] = "",
--["Boethiah's Spine Region"] = "",
--["Broken Cape Region"] = "",
--["Clambering Moor Region"] = "",
--["Colovian Barrowlands Region"] = "",
--["Colovian Highlands Region"] = "",
--["Dagon Urul Region"] = "",
--["Dasek Marsh Region"] = "",
--["Deshaan Plains Region"] = "",
--["Drajkmyr Marsh Region"] = "",
["Druadach Highlands Region"] = "Skyrim",
["Falkheim Region"] = "Skyrim",
--["Gilded Hills Region"] = "",
--["Gold Coast Region"] = "",
--["Gorvigh Mountains Region"] = "",
["Grey Meadows Region"] = "Ashland",
--["Helnim Fields Region"] = "",
--["Hirsing Forest Region"] = "",
--["Hrimbald Plateau Region"] = "",
--["Jerall Mountains Region"] = "",
["Julan-Shar Region"] = "Skyrim",
["Kilkreath Mountains Region"] = "Skyrim",
--["Kreathi Vale Region"] = "",
--["Kvetchi Pass Region"] = "",
--["Lan Orethan Region"] = "",
["Lorchwuir Heath Region"] = "Skyrim",
--["Mephalan Vales Region"] = "",
--["Mhorkren Hills Region"] = "",
["Midkarth Region"] = "Skyrim",
--["Molag Ruhn Region"] = "",
--["Molagreahd Region"] = "",
--["Mudflats Region"] = "",
--["Nedothril Region"] = "",
["Northshore Region"] = "Skyrim",
--["Old Ebonheart Region"] = "",
--["Othreleth Woods Region"] = "",
--["Padomaic Ocean Region"] = "",
--["Reaver's Shore Region"] = "",
--["Rift Valley Region"] = "",
--["Roth Roryn Region"] = "",
--["Sacred Lands Region"] = "",
--["Salt Marsh Region"] = "",
--["Sea of Ghosts Region"] = "",
--["Seitur Region"] = "",
--["Shambalun Veil Region"] = "",
--["Shipal-Shin Region"] = "",
--["Skaldring Mountains Region"] = "",
["Solitude Forest Region"] = "Skyrim",
["Solitude Forest Region S"] = "Skyrim",
--["Southern Gold Coast Region"] = "",
--["Stirk Isle Region"] = "",
["Sundered Hills Region"] = "Skyrim",
--["Sundered Scar Region"] = "",
--["Telvanni Isles Region"] = "",
--["Thirr Valley Region"] = "",
["Throat of the World Region"] = "Skyrim",
["Troll's Teeth Mountains Region"] = "Skyrim",
["Uld Vraech Region"] = "Skyrim",
["Valstaag Highlands Region"] = "Skyrim",
["Velothi Mountains Region"] = "Skyrim",
["Vorndgad Forest Region"] = "Skyrim",
--["West Weald Region"] = "",
["White Plains Region"] = "Skyrim",
--["Wuurthal Dale Region"] = "",
--["Ysheim Region"] = "",
}


local DUN = {
["Dunge"] = 1,
["Dwemer"] = 1,
["Daedric"] = 1,
["Dagoth"] = 1,
["Tomb"] = 1,
["Sewers"] = 1,
["Cave"] = 1,
["Mine"] = 1,
["Stronghold"] = 1,
}

local NOC = {
["Dagoth"] = 1,
["Red Mountain"] = 1,
["Dagoth Ur"] = 1,
["Boss"] = 1,
}

local NOSTOP = {
["Town"] = 1,
["Explore"] = 1,
["Skyrim"] = 1,
["Temple"] = 1,
["Fort"] = 1,
}

local ST = {
["in_pycave"] = "Dunge",
["in_moldcave"] = "Dunge",
["in_mudcave"] = "Dunge",
["in_lavacave"] = "Dunge",
["in_bonecave"] = "Dunge",
["in_BM_cave"] = "Dunge",
["BM_IC"] = "Dunge",
["T_Sky_Cave"] = "Dunge",
["T_Cnq_Cave"] = "Dunge",
["T_Cyr_Cave"] = "Dunge",
["T_Mw_Cave"] = "Dunge",
["AB_In_Cave"] = "Dunge",
["AB_In_MVCave"] = "Dunge",
}


local Ptomb = re.compile[[ "tomb" / "barrow" / "crypt" / "catacomb" / "burial" ]]


local function combatStarted(e) if e.target == mp and not COM and not NOC[D.MusL] then		local m = e.actor	local ob = m.object		local Start --local r = m.reference
	if cf.intcom and p.cell.isInterior then Start = true				--ob.blood == 2 	 ob.type ~= 0
	elseif m.actorType == 1 or ob.biped or ob.usesEquipment then		if ob.level >= cf.lvl then Start = true end
	elseif ob.attacks[1].max >= cf.atk then Start = true end
	
	if Start then 
		COM = true
		local file = RandomFile("data files\\music\\Battle")
		tes3.streamMusic{path = ("Battle\\%s"):format(file), situation = 1, crossfade = 1}
	--	tes3.messageBox("Combat  %s", file)
	end
end end		event.register("combatStarted", combatStarted)


--[[
local function attack(e) if not COM and e.targetMobile == mp and e.mobile.actionData.physicalDamage > cf.atk then	COM = true
	local file = RandomFile("data files\\music\\Battle")
	tes3.streamMusic{path = ("Battle\\%s"):format(file), situation = 1, crossfade = 1}
--	tes3.messageBox("Combat  %s", file)
end end		--event.register("attack", attack, {priority = -100000})
--]]

local function musicSelectTrack(e)		if e.situation == 1 and not NOC[D.MusL] then
	local file = RandomFile("data files\\music\\Battle")
	e.music = ("Battle\\%s"):format(file)
--	tes3.messageBox("Combat new  %s", file)
else
	if COM then	COM = nil end
	
	timer.delayOneFrame(function()
		local dir = ("data files\\music\\%s\\"):format(D.MusL)
		local file = RandomFile(dir)
		tes3.streamMusic{path = ("%s\\%s"):format(D.MusL, file), situation = 2, crossfade = 1}
	--	tes3.messageBox("Select  %s  %s", D.MusL, file)
	end)
end end		event.register("musicSelectTrack", musicSelectTrack)


local function cellChanged(e)
	local c = e.cell		local ext = c.isOrBehavesAsExterior		local cid = c.id	local low = cid:lower()		local split = string.split(cid, ",")	split = string.split(split[1], ":")[1]
	local reg = tes3.getRegion().id		local Prev = D.MusL			local Mus = C[cid] or C[split]
	
	if ext then
		if not Mus or DUN[Mus] then Mus = R[reg] end
	else
		if not Mus then
			if re.find(low, Ptomb) then Mus = "Tomb"		--if string.find(low, "sewers") then Mus = "Sewers" end
			else
				local stid
				for sta in c:iterateReferences(tes3.objectType.static) do stid = sta.id
					for pat, _ in pairs(ST) do if string.startswith(stid, pat) then Mus = "Dunge" break end end
					if Mus then break end
				end
			end
		end
	end
	if not Mus then Mus = "Explore" end

	
	if D.MusL ~= Mus then D.MusL = Mus
		if cf.stop or not (NOSTOP[Prev] and NOSTOP[Mus]) then
			local dir = ("data files\\music\\%s\\"):format(Mus)
			local file = RandomFile(dir)
			tes3.streamMusic{path = ("%s\\%s"):format(Mus, file), situation = 2, crossfade = 1}
		end
	end
--	tes3.messageBox("%s    %s  reg = %s   Mus = %s", cid, split, reg, Mus)
end		event.register("cellChanged", cellChanged)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		D = p.data		D.MusL = D.MusL or "Explore"		COM = nil
end		event.register("loaded", loaded)