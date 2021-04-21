local ttmPath="\\Textures\\tew\\Travel Tooltips\\"
local this={}

this.headers={
["Ald"]=ttmPath.."Aldruhn_citymap.tga",
["Balmora"]=ttmPath.."Balmora_citymap.tga",
["Caldera"]=ttmPath.."WestGash_regionmap.tga",
["Dagon Fel"]=ttmPath.."Sheogorad_regionmap.tga",
["Ebonheart"]=ttmPath.."Vivec_citymap.tga",
["Fort Frostmoth"]=ttmPath.."solstheim_map.tga",
["Gnaar Mok"]=ttmPath.."BitterCoast_regionmap.tga",
["Gnisis"]=ttmPath.."WestGash_regionmap.tga",
["Hla Oad"]=ttmPath.."BitterCoast_regionmap.tga",
["Azura"]=ttmPath.."holamayan.tga",
["Khuul"]=ttmPath.."WestGash_regionmap.tga",
["Maar Gan"]=ttmPath.."Ashlands_regionmap.tga",
["Molag Mar"]=ttmPath.."AzurasCoastS_regionmap.tga",
["Raven Rock"]=ttmPath.."solstheim_map.tga",
["Sadrith Mora"]=ttmPath.."SadrithMora_citymap.tga",
["Seyda Neen"]=ttmPath.."BitterCoast_regionmap.tga",
["Suran"]=ttmPath.."Ascadian_regionmap.tga",
["Tel Aruhn"]=ttmPath.."AzurasCoastN_regionmap.tga",
["Tel Branora"]=ttmPath.."AzurasCoastS_regionmap.tga",
["Tel Mora"]=ttmPath.."AzurasCoastN_regionmap.tga",
["Vivec"]=ttmPath.."Vivec_citymap.tga",
["Vos"]=ttmPath.."Grazelands_regionmap.tga",
}

this.descriptionTable={
["Ald"]="Ald'ruhn is the district seat of House Redoran, and one of the largest settlements on Vvardenfell.\nThe three principal districts are Ald'ruhn town, Ald'ruhn-under-Skar, and Buckmoth Fort.\nAld'ruhn town is a large settlement in the Redoran village style, built of local materials, with organic curves and undecorated exteriors inspired by the landscape and by the shells of giant native insects.",
["Balmora"]="Balmora is the district seat of House Hlaalu, and the largest settlement on Vvardenfell after Vivec City.\nBalmora's four districts are High Town, the Commercial District, Labor Town, and Fort Moonmoth.",
["Caldera"]="Caldera is a recently chartered Imperial town and mining corporation.\nThe Caldera Mining Company has been granted an Imperial monopoly to remove raw ebony from the rich deposits here. Caldera has the appearance and flavor of a Western Imperial town.",
["Dagon Fel"]="The region of Sheogorad is largely hostile and uninhabited, with two small villages at Ald Redaynia and Dagon Fel.\nOnly Dagon Fel is reached by ship services; all other island-to-island transport must be provided by the traveler.",
["Ebonheart"]="Ebonheart is the seat of the Imperial government for Vvardenfell district, and a busy center of maritime trade,\nwhere officers, docks, and warehouses of the East Empire Company are found.\nCastle Ebonheart is the home of Duke Vedam Dren, the district's ruler and Emperor's representative.\nAlso located at Castle Ebonheart are the Vvardenfell District Council chambers and the Hawk Moth Legion garrison.",
["Fort Frostmoth"]="The Empire has only just started their colonization of the isle in the dense Hirstaang Forest in the south,\nmoving slowly up into a region fells and hills, known as the Isinfier Plains.\nThe northeastern area is still occupied by the native Skaal people and the warlike folk of Thirsk, whose mead hall lies near the shore of Lake Fjalding.\nThe northwestern region boasts high mountains, with frost-laden summits and a barren climate, while the northernmost tip of the island is dominated by a massive glacier.",
["Gnaar Mok"]="Gnaar Mok is a tiny island fishing village in the Bitter Coast region of western Vvardenfell.",
["Gnisis"]="Gnisis is a small mining and trade village astride the silt strider caravan route between the northwest West Gash and Ald'ruhn.",
["Hla Oad"]="Hla Oad is a tiny isolated fishing village on western Vvardenfell in the Bitter Coast region.\nA rough track along the River Odai connects Hla Oad with the town of Balmora.",
["Azura"]="",
["Khuul"]="Khuul is a tiny fishing villages on the northern coast of the West Gash.",
["Maar Gan"]="Maar Gan is a small isolated village in a remote region north of Ald'ruhn.\nThe Maar Gan shrine is an important Temple pilgrimage site.",
["Molag Mar"]="The outpost at Molag Mar is a fortified stronghold on the southeastern edge of the desolate Molag Amur region.\nPilgrims bound for the nearby pilgrimage sites at Mount Assarnibibi and Mount Kand take refuge at the outpost's hostels, comforted by the garrison of Redoran and Buoyant Armiger crusaders stationed at the stronghold.",
["Raven Rock"]="Raven Rock is a place of great interest for the entrepreneurs of the Eastern Empire Company, given the sizable deposits of ebony ore that can be found there.\nWith considerable aid from the Empire itself, Raven Rock is now a fast-growing settlement and provides a place to rest, trade, and find some work.",
["Sadrith Mora"]="Sadrith Mora is the district seat of House Telvanni, and home of the Telvanni Council.\nSadrith Mora is an island settlement, and accessible only by sea and teleportation.",
["Seyda Neen"]="The piercing light of the Grand Pharos at the mouth of the harbor of the port village of Seyda Neen is a beacon to mariners throughout the Inner Sea.\nMost visitors from the Empire make landfall at the port of Seyda Neen, where they are processed by the Imperial Census and Excise Commission agents of the Coastguard station.",
["Suran"]="Suran is an agricultural village in the northeastern corner of the fertile Ascadian Isles region.\nTwo popular pilgrimage sites are nearby - the Fields of Kummu and the Shrine of Molag Bal.",
["Tel Aruhn"]="Tel Aruhn is the Telvanni tower of Archmagister Gothren, Telvanni Sorcerer-Lord and head of the Telvanni Council.\nThe associated settlement is a sizable village, and the site of the Festival Slave Market, the largest slave market on Vvardenfell.",
["Tel Branora"]="Tel Branora is the tower and seat of the eccentric Telvanni wizard named Mistress Therana.\nThe tower and its tiny village are located on a rocky promontory at the southeasternmost tip of Azura's Coast.",
["Tel Mora"]="Tel Mora is the Telvanni tower of Mistress Dratha, an ancient wizard of the Telvanni Council.\nThe small settlement includes a few craftsfolk and a tradehouse.",
["Vivec"]="Vivec City is the largest settlement on Vvardenfell, and one of the largest cities in the East.\nEach of the great cantons is the size of a complete town.\nOutlanders mostly confine themselves to the Foreign Canton, while natives live, work, and shop in the Great House compounds and residential cantons.\nThe High Fane and the palace of Vivec are visited by hundreds of tourists and pilgrims daily.",
["Vos"]="Permanent settlements in the fertile Grazelands region include the village of Vos and neighbouring Tel Vos tower.",
}

this.gondoliersTable={
["Foreign"]="The Foreign Quarter is the large three-tiered canton to the north.\nThe Imperial Guilds each have guildhalls and complete services here, and an Imperial cult shrine serves the spiritual needs of the Imperial faithful.\nVarious independent tradesmen, craftsmen, and trainers also rent space here.",
["Temple"]="The High Fane is the largest Tribunal temple on Vvardenfell.\nPilgrims travel from all over Morrowind to view the High Fane and the Ministry of Truth, and to offer prayer and thanks before the Palace of Vivec.",
["Hlaalu"]="Hlaalu Compound is the westmost canton.\nThe Hlaalu Councilors flaunt their splendid tier-top mansions here.\nA variety of craftsmen and tradesmen also have shops at Hlaalu Compound.",
["Telvanni"]="Telvanni Compound is the eastmost canton.\nThe administrative center includes a treasury and a hall of records.\nThere are many tradesmen, craftsmen, and trainers, and the cornerclub provides lodgings for Telvanni kin and mercenaries.",
["Redoran"]="Redoran Compound is the canton south of the Foreign Quarter, west of and next to the Arena.\nThe Redoran administrative center there includes the Redoran Treasury, Hall of Records, and Holding Cells.\nOn the lowest tier is a Redoran shrine and ancestral vaults.\nThere are many tradesmen, craftsmen, and trainers, and the cornerclub provides lodgings for Redoran kin and retainers.",
["Arena"]="The Arena Compound lies between the Redoran compound on the west and the Telvanni compound on the east.\nThe Arena is the site of public entertainments and combat sports, providing seating for hundreds of spectators.\nBeneath the Arena are dressing and storage rooms for entertainers and training rooms and animal pens for the combat competitors.",
["Delyn"]="St. Delyn Canton and St. Olms Canton are residence cantons for commoners and paupers.\nThe Temple charges very reasonable rents for comfortable workshops, shops, and apartments,\nand most of Vvardenfell's crafts and light industry are housed in these cantons.\nThe Abbey of St. Delyn the Wise is on the top tier of St. Delyn.",
["Olms"]="St. Delyn Canton and St. Olms Canton are residence cantons for commoners and paupers.\nThe Temple charges very reasonable rents for comfortable workshops, shops, and apartments,\nand most of Vvardenfell's crafts and light industry are housed in these cantons.\nThere is a top-tier Hlaalu manor on St. Olms.",
}

return this
