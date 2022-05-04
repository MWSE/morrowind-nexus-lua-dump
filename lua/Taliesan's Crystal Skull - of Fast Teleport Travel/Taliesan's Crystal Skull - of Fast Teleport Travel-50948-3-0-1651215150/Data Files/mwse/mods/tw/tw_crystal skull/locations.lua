-- set tw_likepc to 911

local this = {}

function this.mainmenu()
--Locations.mainmenu.buttons = {
local menu = {  
 { id =  0, butt = { "More Camps", "Landmarks", "Grottos", "Mines", "Velothi Towers", "Caves", "Ships", "Taverns", "Guilds", "Barrow's", "Cancel"}, mess = "Teleport to where?" }, 
 { id =  1, butt = { "Back...", "Aharasaplit", "Ahemmusa", "Aidanat", "Ashamanu", "Bensiberib", "Elanius", "Kaushtababi", "Mamshar-Disamus", "Massahanud", "Mila-Nipal", "Salit", "Shashmanu", "Shashurari", "Sobitbael", "Yakaridan", "Zainab", "Cancel" }},
 { id =  2, butt = { "Back...", "Arvel Plantation", "Bal Isra", "Dren Plantation", "Fields of Kummu", "Ghostgate", "Holamayan Monastery", "Khartag Point", "Manor District", "Mount Assarnibibi", "Mount Kand", "Oda Plateau", "Sanctus Shrine", "Shrine of Azura", "Uvirith's Grave", "Valley of the Wind", "Cancel" }},      
 { id =  3, butt = { "Back...", "Akimaes Grotto", "Eluba-Addon Grotto", "Ilanipu Grotto", "Koal Cave", "Madas Grotto", "Malmus Grotto", "Mudan Grotto", "Mul Grotto", "Nimawia Grotto", "Vassamsi Grotto", "Zalkin Grotto", "Cancel" }},  
 { id =  4, butt = { "Back...", "Ebony", "Glass", "Diamond", "Egg", "Cancel"}, mess = "Teleport to which Mine type?" }, 
 { id =  5, butt = { "Back...", "Ald Redaynia Tower", "Arvs-Drelen Tower", "Hanud Tower", "Mababi Tower", "Mawia Tower", "Odirniran Tower", "Sanni Tower", "Shara Tower", "Shishara Tower", "Shishi Tower", "Sulipund Tower", "Vas Tower", "Cancel"  }, mess = "Teleport to which Tower?"   },
 { id =  6, butt = { "Back...", "Bandit A-R", "Bandit S-Z", "6th House", "Slaver", "cancel" }, mess = "Teleport to which Cave?" },
 { id =  7, butt = { "Back...", "Full Ships", "Shipwrecks A-N", "Shipwrecks N-Z", "Cancel"}, mess = "Teleport to which Ship?" },   -- , "Open Boats"
 { id =  8, butt = { "Back...", "Taverns A-S", "Taverns S-Z", "Cancel" }, mess = "Teleport to which Tavern?" },
 { id =  9, butt = { "Back...", "Guilds F-M", "Guilds I-T", "Cancel"  }, mess = "Teleport to which Guild Hall?" },
 { id = 10, butt = { "Back...", "Bloodskal Barrow", "Connorflenge Barrow", "Eddard Barrow", "Frosselmane Barrow", "Gyldenhul Barrow", "Himmelhost Barrow", "Hrothmund's Barrow", "Jolgeirr Barrow", "Kelsedolk Barrow", "Kolbjorn Barrow", "Lukesturm Barrow", "Skogsdrake Barrow", "Stormpfund Barrow", "Valbrandr Barrow", "Cancel"}, mess = "Teleport to which Barrow?"   }, 
 { id = 20, butt = { "Back...", "Caldera Mine", "Elith-Pal Mine", "Mausur Caverns", "Sudanit Mine", "Vassir-Didanat Cave", "Yanemus Mine", "Cancel"}, mess = "Teleport to which Ebony Mine?"  },  -- Ebony
 { id = 21, butt = { "Back...", "Dissapla Mine", "Dunirai Caverns", "Halit Mine", "Massama Cave", "Yassu Mine", "Cancel"}, mess = "Teleport to which Glass Mine?"  }, -- Glass
 { id = 22, butt = { "Back...", "Abaelun Mine" }, mess = "Teleport to which Diamond Mine?" }, -- Diamond
 { id = 23, butt = { "Back...", "Abaesen-Pulu Egg Mine", "Abebaal Egg Mine", "Ahallaraddon Egg Mine", "Ahanibi-Malmus Egg Mine", "Akimaes-Ilanipu Egg Mine", "Asha-ahhe Egg Mine", "Ashimanu Egg Mine", "Band Egg Mine", "Eluba-Addon Egg Mine", "Eretammus-Sennammu Egg Mine", "Gnisis Egg mine", "Hairat-Vassamsi Egg Mine", "Hawia Egg Mine", "Inanius Egg Mine", "Madas-Zebba Egg Mine", "Maelu Egg Mine", "More", "Cancel" }, mess = "Teleport to which Egg Mine?" },   -- Egg 1
 { id = 24, butt = { "Back...", "Maesa-Shammus Egg Mine", "Matus-Akin Egg Mine", "Missir-Dadalit Egg Mine", "Mudan-Mul Egg Mine", "Panabanit-Nimawia Egg Mine", "Panud Egg Mine", "Pudai Egg Mine", "Sarimisun-Assa Egg Mine", "Setus Egg Mine", "Shulk Egg Mine", "Shurdan-Raplay Egg Mine", "Sinamusa Egg Mine", "Sinarralit Egg Mine", "Sur Egg Mine", "Vansunalit Egg Mine", "Zalkin-Sul Egg Mine", "Cancel"  }, mess = "Teleport to which Egg Mine?"   },  --  Egg 2
 { id = 25, butt = { "Back...", "Caldera Mine", "Elith-Pal Mine", "Mausur Caverns", "Sudanit Mine", "Vassir-Didanat Cave", "Yanemus Mine", "Cancel" }, mess = "Teleport to which Mine?"   },  --  ebony 
 { id = 26, butt = { "Back...", "Dissapla Mine", "Dunirai Caverns", "Halit Mine", "Massama Cave", "Yassu Mine", "Cancel" }, mess = "Teleport to which Mine?" },  --  glass
 { id = 27, butt = { "Back...", "Abaelun Mine", "Cancel"  }, mess = "Teleport to which Mine?"   },  --  diamond
 { id = 30, butt = { "Back...", "Ahinipalit", "Ainat", "Ansi", "Kumarahaz", "Kunirai", "Masseranit", "Minabi", "Odibaal", "Pulk", "Punsabanit", "Cancel"  }, mess = "Teleport to which Cave?"   },  -- A-R
 { id = 31, butt = { "Back...", "Sanabi", "Saturan", "Shallit", "Shushishi", "Surirulk", "Yasamsi", "Zainsipilu", "Zaintirari", "Zenarbael", "Cancel"  }, mess = "Teleport to which Cave?"   },  -- S-Z
 { id = 32, butt = { "Back...", "Assemanu","Bensamsi", "Mamaea", "Missamsi", "Piran", "Rissun", "Salmantu", "Sanit", "Sennananit", "Sharapli", "Subdun", "Yakin", "Cancel"  }, mess = "Teleport to which Cave?"   },  -- 6th House
 { id = 33, butt = { "Back...", "Addamasartus", "Aharunartus", "Hinnabi", "Kudanat", "Panat", "Sha-Adnius", "Shushan", "Sinsibadon", "Yakanalit", "Zebabi", "Cancel"  }, mess = "Teleport to which Cave?"   },  -- Slaver
 { id = 40, butt = { "Back...", "Arrow", "Chun-Ook", "Elf-Skerring", "Fair Helas", "Falvillo's Endeavor", "Grytewake", "Imperial Prison Ship", "Cancel" }, mess = "Teleport to which ship?"  },  -- full ships
 { id = 41, butt = { "Back...", "Abandoned Shipwreck", "Ancient Shipwreck", "Derelict Shipwreck", "Deserted Shipwreck", "Desolate Shipwreck", "Forgotten Shipwreck", "Lonely Shipwreck", "Lonesome Shipwreck", "Lost Shipwreck", "Neglected Shipwreck", "Cancel" }, mess = "Teleport to which ship?"   },  --"Shipwrecks A-N"
 { id = 42, butt = { "Back...", "Obscure Shipwreck", "Prelude Shipwreck", "Remote Shipwreck", "Shunned Shipwreck", "Strange Shipwreck", "Unchartered Shipwreck", "Unexplored Shipwreck", "Unknown Shipwreck", "Unmarked Shipwreck", "Cancel" }, mess = "Teleport to which ship?" },  --"Shipwrecks N-Z"
 { id = 50, butt = { "Back...", "Ald'ruhn - Ald Skar Inn", "Ald'ruhn - The Rat in the Pot", "Balmora - Council Club", "Balmora - Eight Plates", "Balmora - Lucky Lockup", "Balmora - South Wall Cornerclub", "Caldera - Shenk's Shovel", "Dagon Fel - End of the World", "Ebonheart - Six Fishes", "Maar Gan - Andus Tradehouse", "Molag Mar - The Pilgrim's Rest", "Pelagiad - Halfway Tavern", "Sadrith Mora - Fara's Hole in the Wall", "Sadrith Mora - Gateway Inn", "Sadrith Mora - Dirty Muriel's Cornerclub", "Cancel"}, mess = "Teleport to which Tavern? A-S" },
 { id = 51, butt = { "Back...", "Seyda Neen - Arrille's Tradehouse", "Suran - Desele's House of Earthly Delights", "Tel Aruhn - Plot and Plaster", "Tel Branora - Sethan's Tradehouse", "Tel Mora - The Covenant", "Vivec - Black Shalk Cornerclub", "Vivec - No Name Club", "Vivec - Elven Nations Cornerclub", "Vivec - The Flowers of Gold", "Vivec - The Lizard's Head", "Vos - Varo Tradehouse", "Mournhold - The Winged Guar", "Cancel"}, mess = "Teleport to which Tavern? S-Z" },
 { id = 60, butt = { "Back...", "Fighter's Guild - Ald'ruhn", " - Balmora", " - Wolverine Hall", " - Vivec", "Mage's Guild - Ald'ruhn", " - Balmora", " - Caldera", " - Wolverine Hall", " - Vivec", "Thieve's Guild - Ald'ruhn", " - Balmora", " - Sadrith Mora", " - Vivec", "Morag Tong - Headquarters, Vivec", " - Ald'ruhn", " - Balmora", " - Sadrith Mora", "Cancel" }, mess = "Teleport to which Guild Hall - F-M" },
 { id = 61, butt = { "Back...", "Imperial Cult - Fort Buckmoth", " - Fort Frostmouth",  " - Fort Moonmoth", " - Fort Pelagiad", " - Fort Darius", " - Wolverine Hall", " - Vivec, Foreign Quarter", " - Imperial Chapel in Ebonheart", " - Mournhold's Royal Palace", "The Temple - Ald'ruhn", " - Balmora", " - Ghostgate", " - Gnisis", " - Maar Gan", " - Molag Mar", " - Mournhold. TR", " - Sadrith Mora", "Cancel"}, mess = "Teleport to which Guild Hall - I-T" },
}
return menu
end


-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function this.MoreCamps() -- mainmenu 1  - 14 +10    
local menu = {
{ id = 1, cell = "Sheogarad Region (4, 19)",      pos = { 35423, 161009, 252 },   rot = {0, 0, 324 },  mess = "Aharasaplit Camp"     },
{ id = 2, cell = "Ahemmusa Camp (11, 16)",        pos = { 94264, 134918, 951 },   rot = { 0, 0, 137 }, mess = "Ahemmusa Camp"        },
{ id = 3, cell = "West Gash Region (-11, 14)",    pos = { -88101, 118887, 1695 }, rot = { 0, 0, 88 },  mess = "Aidanat Camp"         },
{ id = 4, cell = "Azura's Coast Region (13, 5)",  pos = { 111389, 47117, 258 },   rot = { 0, 0, 60 },  mess = "Ashamanu Camp"        },
{ id = 5, cell = "Azura's Coast Region (13, 3)",  pos = { 108467, 25856, 336 },   rot = { 0, 0, 169 }, mess = "Bensiberib Camp"      }, 
{ id = 6, cell = "Grazelands Region (10, 7)",     pos = { 86155, 63565, 1120 },   rot = { 0, 0,  77 }, mess = "Elanius Camp"         },
{ id = 7, cell = "Azura's Coast Region (13, -9)", pos = { 110395, -72925, 1079 }, rot = { 0, 0, 42 },  mess = "Kaushtababi Camp"     },
{ id = 8, cell = "Ashlands Region (1, 14)",       pos = { 13813, 120960, 785 },   rot = { 0, 0, 157 }, mess = "Mamshar-Disamus Camp" },
{ id = 9, cell = "Grazelands Region (13, 8)",     pos = { 109066, 70086, 1338 },  rot = { 0, 0, 26 },  mess = "Massahanud Camp"      },
{ id = 9, cell = "Grazelands Region (12, 11)",    pos = { 4108, 3963, 14756 },    rot = { 0, 0, 270 }, mess = "Mila-Nipal"           },
{ id = 10, cell = "Grazelands Region (12, 11)",    pos = { 104217, 92445, 771 },   rot = { 0, 0, 217 }, mess = "Salit Camp"           },
{ id = 11, cell = "West Gash Region (-9, 15)",     pos = { -68886, 125461, 1370 }, rot = { 0, 0, 57 },  mess = "Shashmanu Camp"       },
{ id = 12, cell = "Molag Amur Region (10, -1)",    pos = { 85040, -3510, 715 },    rot = { 0, 0, 34 },  mess = "Shashurari Camp"      },
{ id = 13, cell = "Azura's Coast Region (14, 1)",  pos = { 115958, 10009, 398 },   rot = { 0, 0, 57 },  mess = "Sobitbael Camp"       },
{ id = 14, cell = "Grazelands Region (10, 12)",    pos = { 87036, 101583, 649 },   rot = { 0, 0, 46 },  mess = "Yakaridan Camp"       },
{ id = 15, cell = "Zainab Camp (9, 10)",           pos = { 78351, 83963, 1010 },   rot = { 0, 0, 300 }, mess = "Zainab Camp"          },
}  
return menu
end
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
  
function this.Landmarks() -- mainmenu 2  - 15
local Landmarks = {
{ id = 1, cell = "Arvel Plantation (2, -6)",       pos = {20776,-42996,788},       rot = {0, 0, 90 }, mess = "Arvel Plantation"   },  
{ id = 2, cell = "Bal Isra (-5, 9)",               pos = {-35684, 79406, 1783},    rot = {0,0,50 },   mess = "Indarys Manor"      },  
{ id = 3, cell = "Dren Plantation, Dren's Villa",  pos = {589, 3519, 15767},       rot = {0,0,180 },  mess = "Dren Plantation"    }, 
{ id = 4, cell = "Fields of Kummu",                pos = {12144,-33592,800},       rot = {0,0,90 },   mess = "Fields of Kummu"    }, 
{ id = 5, cell = "Ghostgate",                      pos = {20079, 36716, 879},      rot = {0,0,0},     mess = "Ghostgate"          }, 
{ id = 6, cell = "Holamayan (19, -4)",             pos = {159099, -30529, 2073},   rot = {0,0,0},     mess = "Holamayan Monastery"   }, 
{ id = 7, cell = "Ald-ruhn, Manor District",       pos = {-78, -2188, -356},       rot = {0,0,0},     mess = "Manor District Ald'ruhn" },
{ id = 8, cell = "Kogoruhn (0, 14)",               pos = {5216, 120544, 1504},     rot = {0,0,180},   mess = "Kogoruhn Stronghold"   },
{ id = 9, cell = "Mount Assarnibibi",              pos = {-120709, -32221, 4589},  rot = {0,0,0},     mess = "Mount Assarnibibi"   }, 
{ id = 10, cell = "Mount Kand",                     pos = {97680, -39736, 5815},   rot = {0,0,287},   mess = "Mount Kand exterior" }, 
{ id = 11, cell = "Odai Plateau (-5, -5)",          pos = {-35904, -37056, 2016},  rot = {0,0,270},   mess = "Oda Plateau"         }, 
{ id = 12, cell = "Sanctus Shrine",                 pos = {3136, 173184, 1727},    rot = {0,0,315},   mess = "Sanctus Shrine"     }, 
{ id = 13, cell = "Shrine of Azura",                pos = {2999, 51200, 80},       rot = {0,0,270 },  mess = "Shrine of Azura"    }, 
{ id = 14, cell = "Uvirith's Grave (10, 1)",        pos = {87282, 10177, 2279},    rot = {0,0, 308},  mess = "Uvirith's Grave"    }, 
{ id = 15, cell = "Ashlands Region (7, 15)",        pos = {58984,124132,808},      rot = {0,0,160},   mess = "Valley of the Wind"  }, 
}
return Landmarks
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function this.Grottos()
local Grottos = {  
{ id =  1, cell = "Akimaes Grotto",      pos = {-5856, 1920, -296},  rot = {0,0,90},    mess = "Akimaes Grotto"  }, 
{ id =  2, cell = "Eluba-Addon Grotto",  pos = {-2016, 4096, -176},  rot = {0,0,90},    mess = "Eluba-Addon Grotto" }, 
{ id =  3, cell = "Ilanipu Grotto",      pos = {-7173, 2808, -681},  rot = {0,0,90},    mess = "Ilanipu Grotto" }, 
{ id =  4, cell = "Koal Cave",           pos = { 2738, 887, 294},    rot = {0,0,90},    mess = "Koal Cave" }, 
{ id =  5, cell = "Madas Grotto",        pos = {-1526, 4999, -37},   rot = {0,0,180},   mess = "Madas Grotto" }, 
{ id =  6, cell = "Malmus Grotto",       pos = {-3664, 240, -1075},  rot = {0,0,90},    mess = "Malmus Grotto" }, 
{ id =  7, cell = "Mudan Grotto",        pos = {-5506, 4126, -174},  rot = {0,0,180},   mess = "Mudan Grotto" }, 
{ id =  8, cell = "Mul Grotto",          pos = {-2144, 5752, -296},  rot = {0,0,203},   mess = "Mul Grotto" }, 
{ id = 10, cell = "Nimawia Grotto",      pos = {760, 1792, -298},    rot = {0,0,270},   mess = "Nimawia Grotto" }, 
{ id = 11, cell = "Vassamsi Grotto",     pos = {-1912, 3824, -44},   rot = {0,0,90},    mess = "Vassamsi Grotto" }, 
{ id = 12, cell = "Zalkin Grotto",       pos = {-632, 1560, -169},   rot = {0,0,0},     mess = "Zalkin Grotto" }, 
}
return Grottos
end
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--[[ Locations.MenuMines.buttons = {  
    1 Ebony Mines
    2 Glass Mines
    3 Diamond Mine
    4 Egg Mines
--]]    

function this.minesEbony()  --   menu - 4
-- {"Caldera Mine", "Elith-Pal Mine", "Mausur Caverns", "Sudanit Mine", "Vassir-Didanat Cave", "Yanemus Mine"},
local mineEbony = {
{ id =  1, cell = "West Gash Region (-3, 1)",  pos = {-22756, 12783, 1748},    rot = {0,0,202},  mess = "Caldera Mine" }, 
{ id =  2, cell = "Elith-Pal Mine",            pos = {2014, 2309, 35},         rot = {0,0,270},  mess = "Elith-Pal Mine" }, 
{ id =  3, cell = "Mausur Caverns",            pos = {1856, 2816, -96},        rot = {0,0,270},  mess = "Mausur Caverns" }, 
{ id =  4, cell = "Sudanit Mine",              pos = {2336, 2439, -290},       rot = {0,0,270},  mess = "Sudanit Mine" }, 
{ id =  5, cell = "Vassir-Didanat Cave",       pos = {3734, 3062, 225},        rot = {0,0,270},  mess = "Vassir-Didanat Cave" }, 
{ id =  6, cell = "Yanemus Mine",              pos = {-2649, -1151, 225},      rot = {0,0,270},  mess = "Yanemus Mine"     }, 
}
return mineEbony
end

-- -=-=-=-=-=-
function this.minesGlass()
-- {"Dissapla Mine", "Dunirai Caverns", "Halit Mine", "Massama Cave", "Yassu Mine" }, 
local mineGlass = {
{ id = 1, cell = "Dissapla Mine",   pos = {-2649, -1151, 225},  rot = {0,0,90},   mess = "Dissapla Mine"  }, 
{ id = 2, cell = "Dunirai Caverns", pos = {-2587, 4480, 734},   rot = {0,0,90},  mess = "Dunirai Caverns"  },  --- Ummm
{ id = 3, cell = "Halit Mine",      pos = {-1129, -504, 160},   rot = {0,0,90},   mess = "Halit Mine"  }, 
{ id = 4, cell = "Massama Cave",    pos = {1755, -252, 480},    rot = {0,0,270},  mess = "Massama Cave"  }, 
{ id = 5, cell = "Yassu Mine",      pos = {-1056, -392, 360},   rot = {0,0,90},   mess = "Yassu Mine"  }, 
}
return mineGlass
end

-- -=-=-=-=-=-
function this.minesDiamond()
-- { "Abaelun Mine" },
local mineDiamond = {
{ id = 1, cell = "Abaelun Mine",  pos = {-1523, 3035, -417},  rot = {0,0,0},  mess = "Abaelun Mine" }, 
}
return mineDiamond
end

-- -=-=-=-=-=-
--Egg Mines - 32
function this.minesEgg(button)
local mineEggs = {}
if ( button == 1 ) then
mineEggs= {
{ id =  1, cell = "Abaesen-Pulu Egg Mine",         pos = {224, -1398, -2093},  rot = {0,0,90},   mess = "Abaesen-Pulu Egg mine"   }, 
{ id =  2, cell = "Abebaal Egg Mine",              pos = {930, 5630, -674},    rot = {0,0,270},  mess = "Abebaal Egg Mine"   }, 
{ id =  3, cell = "Ahallaraddon Egg Mine",         pos = {1807, 2815, 530},    rot = {0,0,270},  mess = "Ahallaraddon Egg Mine"   }, 
{ id =  4, cell = "Ahanibi-Malmus Egg Mine",       pos = {-721, 7170, -546},   rot = {0,0,270},  mess = "Ahanibi-Malmus Egg Mine"   }, 
{ id =  5, cell = "Akimaes-Ilanipu Egg Mine",      pos = {-16, 7553, -1069},   rot = {0,0,90},   mess = "Akimaes-Ilanipu Egg Mine"   }, 
{ id =  6, cell = "Asha-ahhe Egg Mine",            pos = {330, 147, -129},     rot = {0,0,0},    mess = "Asha-ahhe Egg Mine"   }, 
{ id =  7, cell = "Ashimanu Egg Mine",             pos = {539, 2688, -175},    rot = {0,0,270},  mess = "Ashimanu Egg Mine"   }, 
{ id =  8, cell = "Band Egg Mine",                 pos = {4743, 6907, -557},   rot = {0,0,270},  mess = "Band Egg Mine"   }, 
{ id =  9, cell = "Eluba-Addon Egg Mine",          pos = {-930, 4092, 1515},   rot = {0,0,90},   mess = "Eluba-Addon Egmine"   }, 
{ id = 10, cell = "Eretammus-Sennammu Egg Mine",   pos = {-3873, 4100, -682},  rot = {0,0,90},   mess = "Eretammus-Sennammu Egg Mine"   }, 
{ id = 11, cell = "Gnisis, Eggmine",               pos = {3307,4476,256},      rot = {0,0,180},  mess = "Gnisis Eggmine"   }, 
{ id = 12, cell = "Hairat-Vassamsi Egg Mine",      pos = {-3453, 5438, -419},  rot = {0,0,180},  mess = "Hairat-Vassamsi Egg Mine"   }, 
{ id = 13, cell = "Hawia Egg Mine",                pos = {-1676, 1927, -1197}, rot = {0,0,90},   mess = "Hawia Egg Mine"   }, 
{ id = 14, cell = "Inanius Egg Mine",              pos = {-2816, -415, 721},   rot = {0,0,0},    mess = "Inanius Egg Mine"   }, 
{ id = 15, cell = "Madas-Zebba Egg Mine",          pos = {2179, 9023, -411},   rot = {0,0,270},  mess = "Madas-Zebba Egg Mine"   }, 
{ id = 16, cell = "Maelu Egg Mine",                pos = {-2046, 4223, -813},  rot = {0,0,90},   mess = "Maelu Egg Mine"   },             
}
--return mineEggs1
--end
elseif ( button == 2 ) then
-- -=-=-=-=-=-
--function this.minesEgg2()
mineEggs = {
{ id =  1, cell = "Maesa-Shammus Egg Mine",      pos = {-466, 2943, -1066},   rot = {0,0,270},  mess = "Maesa-Shammus Egg Mine"   }, 
{ id =  2, cell = "Matus-Akin Egg Mine",         pos = {802, -890, -1584},    rot = {0,0,270},  mess = "Matus-Akin Egg Mine"   }, 
{ id =  3, cell = "Missir-Dadalit Egg Mine",     pos = {2330, 3401, -814},    rot = {0,0,0},    mess = "Missir-Dadalit Egg Mine"   }, 
{ id =  4, cell = "Mudan-Mul Egg Mine",          pos = {352, 768, -928},      rot = {0,0,90},   mess = "Mudan-Mul Egg Mine"   }, 
{ id =  5, cell = "Panabanit-Nimawia Egg Mine",  pos = {2219, -2179, -1199},  rot = {0,0,270},  mess = "Panabanit-Nimawia Egg Mine"   }, 
{ id =  6, cell = "Panud Egg Mine",              pos = {2828, 3203, -558},    rot = {0,0,0},    mess = "Panud Egg Mine"   }, 
{ id =  7, cell = "Pudai Egg Mine",              pos = {-1423,1393,-431},     rot = {0,0,90},   mess = "Pudai Egg Mine"   }, 
{ id =  8, cell = "Sarimisun-Assa Egg Mine",     pos = {2191, 6007, -685},    rot = {0,0,270},  mess = "Sarimisun-Assa Egg Mine"   }, 
{ id =  9, cell = "Setus Egg Mine",              pos = {5152, 2048, 96},      rot = {0,0,270},  mess = "Setus Egg Mine"   }, 
{ id = 10, cell = "Shulk Egg Mine",              pos = {2972, -896, -1070},   rot = {0,0,270},  mess = "Shulk Egg Mine"   }, 
{ id = 11, cell = "Shurdan-Raplay Egg Mine",     pos = {-2604, 2049, -1068},  rot = {0,0,90},   mess = "Shurdan-Raplay Egg Mine"   }, 
{ id = 12, cell = "Sinamusa Egg Mine",           pos = {896, 5792, -1312},    rot = {0,0,180},  mess = "Sinamusa Egg Mine"   }, 
{ id = 13, cell = "Sinarralit Egg Mine",         pos = {-2043, 1145, -684},   rot = {0,0,90},   mess = "Sinarralit Egg Mine"   }, 
{ id = 14, cell = "Sur Egg Mine",                pos = {-2531, 3845, -552},   rot = {0,0,270},  mess = "Sur Egg Mine"   }, 
{ id = 15, cell = "Vansunalit Egg Mine",         pos = {-2425, 6517, -43},    rot = {0,0,90},   mess = "Vansunalit Egg Mine"   }, 
{ id = 16, cell = "Zalkin-Sul Egg Mine",         pos = {-3462, 5756, -1197},  rot = {0,0,90},   mess = "Zalkin-Sul Egg Mine"   },    
} 
end
return mineEggs
end

-- -=-=-=-=-=-
function this.Towers()
local Towers = {
{ id =  1, cell = "Ald Redaynia, Tower",      pos = {4453, 4102, 14576},   rot = {0,0,270},  mess = "Ald Redaynia, Tower"   }, 
{ id =  2, cell = "Gnisis, Arvs-Drelen",      pos = {3575, 6643, 224},     rot = {0,0,180},  mess = "Arvs-Drelen Tower"   }, 
{ id =  3, cell = "Hanud",                    pos = {4836, 7416, -300},    rot = {0,0,268},  mess = "Hanud Tower"   }, 
{ id =  4, cell = "Mababi",                   pos = {1043, 1528, -668},    rot = {0,0,90},   mess = "Mababi Tower"   }, 
{ id =  5, cell = "Mawia",                    pos = {2036, 1790, -1197},   rot = {0,0,270},  mess = "Mawia Tower"   }, 
{ id =  6, cell = "Odirniran",                pos = {348, 4863, -1066},    rot = {0,0,270},  mess = "Odirniran Tower"   }, 
{ id =  7, cell = "Sanni",                    pos = {120, 2951, -944},     rot = {0,0,270},  mess = "Sanni Tower"   }, 
{ id =  8, cell = "Shara",                    pos = {1033, 6011, 1630},    rot = {0,0,180},  mess = "Shara Tower"   }, 
{ id =  9, cell = "Shishara",                 pos = {1698, 2178, 96},      rot = {0,0,90},   mess = "Shishara Tower"   }, 
{ id = 10, cell = "Shishi",                   pos = {258, 4202, -1196},    rot = {0,0,90},   mess = "Shishi Tower"   }, 
{ id = 11, cell = "Sulipund",                 pos = {1056, 1664, -1072},   rot = {0,0,90},   mess = "Sulipund Tower"   }, 
{ id = 12, cell = "Vas, Entry Level",         pos = {773, 3581, 984},      rot = {0,0,180},  mess = "Vas Tower"   }, 
}
return Towers
end
 
 -- -=-=-=-=-=-
function this.travelCaves1()
local caveReturn
--if ( button == 1 ) then  -- Bandit 1 A-R *
caveReturn = {
{ id =  1, cell = "Ahinipalit",      pos = {-365, 515, -532},    rot = {0, 0, 270 },  mess = "Ahinipalit"     },  
{ id =  2, cell = "Ainat",           pos = {-736, -1776, 608},   rot = {0, 0, 270 },  mess = "Ainat"     },  
{ id =  3, cell = "Ansi",            pos = {-795, 1542, 221},    rot = {0, 0, 90 },   mess = "Ansi"     },  
{ id =  4, cell = "Kumarahaz",       pos = {796, 3209, 85},      rot = {0, 0, 270 },  mess = "Kumarahaz"     },  
{ id =  5, cell = "Kunirai",         pos = {1406, -812, 603},    rot = {0, 0, 0 },    mess = "Kunirai"     },  
{ id =  6, cell = "Masseranit",      pos = {1670, 1800, -676},   rot = {0, 0, 0 },    mess = "Masseranit"     },  
{ id =  7, cell = "Minabi",          pos = {-2707, 3079, 1120},  rot = {0, 0, 0 },    mess = "Minabi"     },  
{ id =  8, cell = "Odibaal",         pos = {-3852, -387, -222},  rot = {0, 0, 90 },   mess = "Odibaal"     },  
{ id =  9, cell = "Pulk",            pos = {160, 320, 352},      rot = {0, 0, 90 },   mess = "Pulk"     },  
{ id = 10, cell = "Punsabanit",      pos = {-539, -770, -34},    rot = {0, 0, 90 },   mess = "Punsabanit"     },  
}
return caveReturn
end
 -- -=-=-=-=-=-
function this.travelCaves2()
local caveReturn
--elseif ( button == 2 ) then    -- Bandit 2 S-Z *
caveReturn = {
{ id =  1, cell = "Sanabi",       pos = {522, 1813, 346},      rot = {0, 0, 180 },  mess = "Sanabi"     },  
{ id =  2, cell = "Saturan",      pos = {-3106, 1014, 738},    rot = {0, 0, 90 },   mess = "Saturan"     },  
{ id =  3, cell = "Shallit",      pos = {-1998, 1533, -296},   rot = {0, 0, 90 },   mess = "Shallit"     },  
{ id =  4, cell = "Shushishi",    pos = {-109, -130, 233},     rot = {0, 0, 270 },  mess = "Shushishi"     },  
{ id =  5, cell = "Surirulk",     pos = {419, 266, 96},        rot = {0, 0, 270 },  mess = "Surirulk"     },  
{ id =  6, cell = "Yasamsi",      pos = {-1417, 5374, -783},   rot = {0, 0, 90 },   mess = "Yasamsi"     },  
{ id =  7, cell = "Zainsipilu",   pos = {-3113, 2058, 739},    rot = {0, 0, 90 },   mess = "Zainsipilu"     },  
{ id =  8, cell = "Zaintirari",   pos = {-2571, 3641, 1368},   rot = {0, 0, 90 },   mess = "Zaintirari"     },  
{ id =  9, cell = "Zenarbael",    pos = {-3362, 4615, 215},    rot = {0, 0, 90 },   mess = "Zenarbael"     },  
}  
return caveReturn
end
 -- -=-=-=-=-=-
function this.travelCaves3()
local caveReturn
--elseif ( button == 3 ) then    -- 6th house # 12
caveReturn = {
{ id =  1, cell = "Assemanu",                     pos = {-5524, 249, 212},     rot = {0, 0, 0 },    mess = "Assemanu"     },  
{ id =  2, cell = "Bensamsi",                     pos = {-2696, 2347, -393},   rot = {0, 0, 180 },  mess = "Bensamsi"     },  
{ id =  3, cell = "Mamaea, Sanctum of Awakening", pos = {5222, 5274, 574},     rot = {0, 0, 180 },  mess = "Mamaea"     },  
{ id =  4, cell = "Missamsi",                     pos = {4908, -1137, -2718},  rot = {0, 0, 270 },  mess = "Missamsi"     },  
{ id =  5, cell = "Piran",                        pos = {1374, 3846, -1310},   rot = {0, 0, 90 },   mess = "Piran"     },  
{ id =  6, cell = "Rissun",                       pos = {3339, 7693, -1315},   rot = {0, 0, 270 },  mess = "Rissun"     },  
{ id =  7, cell = "Salmantu",                     pos = {3584, 3968, 150},     rot = {0, 0, 0 },    mess = "Salmantu"     },  
{ id =  8, cell = "Sanit",                        pos = {4465, 4227, -1297},   rot = {0, 0, 90 },   mess = "Sanit"     },  
{ id =  9, cell = "Sennananit",                   pos = {-2945, 3288, -1068},  rot = {0, 0, 0 },    mess = "Sennananit"     },  
{ id = 10, cell = "Sharapli",                     pos = {-2691, 727, -1186},   rot = {0, 0, 0 },    mess = "Sharapli"     },  
{ id = 11, cell = "Subdun",                       pos = {309, 13, 1230},       rot = {0, 0, 180 },  mess = "Subdun"     },  
{ id = 12, cell = "Yakin",                        pos = {1030, -4390, -542},   rot = {0, 0, 0 },    mess = "Yakin"     },  
}  
return caveReturn
end
 -- -=-=-=-=-=-
function this.travelCaves4()
local caveReturn
--elseif ( button == 4 ) then    -- slavers ## 10
caveReturn = {
{ id =  1, cell = "Addamasartus",      pos = {1280, 992, 480},    rot = {0, 0, 0 },    mess = "Addamasartus"     },  
{ id =  2, cell = "Aharunartus",       pos = {172, -248, -146},   rot = {0, 0, 0 },    mess = "Aharunartus"     },  
{ id =  3, cell = "Hinnabi",           pos = {609, -11, 483},     rot = {0, 0, 270 },  mess = "Hinnabi"     },  
{ id =  4, cell = "Kudanat",           pos = {-90, 2, 86},        rot = {0, 0, 270 },  mess = "Kudanat"     },  
{ id =  5, cell = "Panat",             pos = {-1149, 3596, 342},  rot = {0, 0, 180 },  mess = "Panat"     },  
{ id =  6, cell = "Sha-Adnius",        pos = {-1186, 2940, 91},   rot = {0, 0, 90 },   mess = "Sha-Adnius"     },  
{ id =  7, cell = "Shushan",           pos = {1, -33, 97},        rot = {0, 0, 0 },    mess = "Shushan"     },  
{ id =  8, cell = "Sinsibadon",        pos = {1322, -128, 731},   rot = {0, 0, 270 },  mess = "Sinsibadon"     },  
{ id =  9, cell = "Yakanalit",         pos = {1511, 2787, 116},   rot = {0, 0, 0 },    mess = "Yakanalit"     },  
{ id = 10, cell = "Zebabi",            pos = {42, -4093, 1113},   rot = {0, 0, 270 },  mess = "Zebabi"     },  
}
return caveReturn
end

-- -=-=-=-=-=-
function this.travelShips(button)
-- Shipwrecks - 19  hmm... need to split list
local Ships = {}
if ( button == 1 ) then   -- Full ships
 Ships = {
{ id = 1, cell = "Dagon Fel (7,22)",             pos = {62644,184228,188},   rot = {0,0,8},   mess = "Arrow"  },        
{ id = 2, cell = "Ebonheart (2,-13)",            pos = {20361,-102425,182},  rot = {0,0,180}, mess = "Chun-Ook"  },     
{ id = 3, cell = "Sadrith Mora (17,4~)",         pos = {141874,38606,327},   rot = {0,0,320}, mess = "Elf-Skerring"  }, 
{ id = 4, cell = "Ald Velothi",                  pos = {-88716,128140,136},  rot = {0,0,300}, mess = "Fair Helas"  },   
{ id = 5, cell = "Azura's Coast Region (12,14)", pos = {100600,114028,256},  rot = {0,0,30},  mess = "Falvillo's Endeavor"  }, 
{ id = 6, cell = "Bitter Coast Region (-7,-6)",  pos = {-52956,-44596,108},  rot = {0,0,220}, mess = "Grytewake"  }, 
{ id = 7, cell = "seyda Neen ()-2,-9",           pos = {-9656,-72024,200},   rot = {0,0,-3}, mess = "Imperial Prison Ship "  }, 
}
elseif ( button == 2 ) then  -- Shipwrecks A-N
Ships = {
{ id =  1, cell = "Sheogarad Region (1, 23)",      pos = {8937, 188669, 157},      rot = {0,0,166},  mess = "Abandoned Shipwreck"  },
{ id =  2, cell = "Sheogarad Region (8, 20)",      pos = {73584, 170610, 586},     rot = {0,0,260},  mess = "Ancient Shipwreck"  },
{ id =  3, cell = "Sheogarad Region (-7, 18)",     pos = {-51764, 152122, 349},    rot = {0,0,160},  mess = "Derelict Shipwreck"  },
{ id =  4, cell = "Azura's Coast Region (9, -11)", pos = {74577, -86878, -93},     rot = {0,0,6},    mess = "Deserted Shipwreck"  },
{ id =  5, cell = "Ascadian Isles Region (1, -6)", pos = {12163, -45662, -883},    rot = {0,0,0},    mess = "Desolate Shipwreck"  },
{ id =  6, cell = "West Gash Region (-13, 15)",    pos = {-100230, 124808, -1438}, rot = {0,0,290},  mess = "Forgotten Shipwreck"  },
{ id =  7, cell = "Azura's Coast Region (18, -1)", pos = {155415, -7392, -289},    rot = {0,0,300},  mess = "Lonely Shipwreck"  },
{ id =  8, cell = "Azura's Coast Region (13, 15)", pos = {111251, 128260, -664},   rot = {0,0,350},  mess = "Lonesome Shipwreck"  },
{ id =  9, cell = "Azura's Coast Region (15, 11)", pos = {127840, 94268, -313},    rot = {0,0,310},  mess = "Lost Shipwreck"  },
{ id = 10, cell = "Bitter Coast Region (-10, 4)",  pos = {-73767, 39570, 35},      rot = {0,0,230},  mess = "Neglected Shipwreck"  },
}
elseif ( button == 3 ) then  -- Shipwrecks N-Z
Ships = {
{ id = 1, cell = "Sheogorad Region (-1, 23)",      pos = {-6076, 191792, -1084},   rot = {0,0,0},   mess = "Obscure Shipwreck"  },
{ id = 2, cell = "Azura's Coast Region (11, -12)", pos = {94996, -96523, 249},     rot = {0,0,340}, mess = "Prelude Shipwreck"  },
{ id = 3, cell = "Bitter Coast Region (-1, -11)",  pos = {-8116, -84529, -34},     rot = {0,0,0},   mess = "Remote Shipwreck"  },
{ id = 4, cell = "Bitter Coast Region (-10, 1)",   pos = {-74755, 14566, 67},      rot = {0,0,260}, mess = "Shunned Shipwreck"  },
{ id = 5, cell = "Azura's Coast Region (19, 6)",   pos = {157597, 50471, 696},     rot = {0,0,340}, mess = "Strange Shipwreck"  },
{ id = 6, cell = "Ascadian Isles Region (4, -15)", pos = {35956, -119563, 387},    rot = {0,0,260}, mess = "Unchartered Shipwreck"  },
{ id = 7, cell = "Bitter Coast Region (-5, -7)",   pos = {-40144, -55737, 129},    rot = {0,0,350}, mess = "Unexplored Shipwreck"  },
{ id = 8, cell = "Azura's Coast Region (16, 4)",   pos = {132579, 37549, 403},     rot = {0,0,340}, mess = "Unknown Shipwreck"  },
{ id = 9, cell = "West Gash Region (-15, 14)",     pos = {-119654, 120393, -1429}, rot = {0,0,250}, mess = "Unmarked Shipwreck"  },
}
end
return Ships
end

-- -=-=-=-=-=-
function this.Guilds(button)
-- { id = 60, butt = { "Fighter's Guild - Ald'ruhn", " - Balmora", " - Wolverine Hall", " - Vivec", "Mage's Guild - Ald'ruhn", " - Balmora", " - Caldera", " - Wolverine Hall", " - Vivec", "Thieve's Guild - Ald'ruhn", " - Balmora", " - Sadrith Mora", " - Vivec", "Morag Tong - Headquarters, Vivec", " - Ald'ruhn", " - Balmora", " - Sadrith Mora", "Cancel" }, mess = "Teleport to which Guild Hall - F-M" },
local Guilds = {}
if ( button == 1 ) then 
Guilds = {
{ id =  1, cell = "Ald-ruhn, Guild of Fighters",                   pos = {122,203,-95},    rot = {0,0,180},   mess = "Fighter's Guild - Ald'ruhn"  },
{ id =  2, cell = "Balmora, Guild of Fighters",                    pos = {283,256,-33},    rot = {0,0,1800},  mess = "Fighter's Guild - Balmora"  },
{ id =  3, cell = "Sadrith Mora, Wolverine Hall: Fighter's Guild", pos = {288,-416,96},    rot = {0,0,0},     mess = "Fighter's Guild - Wolverine Hall"   },
{ id =  4, cell = "Vivec, Guild of Fighters",                      pos = {924,785,240},    rot = {0,0,270},   mess = "Fighter's Guild - Vivec"  },
{ id =  5, cell = "Ald-ruhn, Guild of Mages",                      pos = {-516,-32,0},     rot = {0,0,0},     mess = "Mage's Guild - Ald'ruhn"       },
{ id =  6, cell = "Balmora, Guild of Mages",                       pos = {-506,-239,-128}, rot = {0,0,0},     mess = "Mage's Guild - Balmora"        },
{ id =  7, cell = "Caldera, Guild of Mages",                       pos = {924,785,240},    rot = {0,0,270},   mess = "Mage's Guild - Caldera"        },
{ id =  8, cell = "Sadrith Mora, Wolverine Hall: Mage's Guild",    pos = {448,192,160},    rot = {0,0,0},     mess = "Mage's Guild - Wolverine Hall" },
{ id =  9, cell = "Vivec, Guild of Mages",                         pos = {1,157,-167},     rot = {0,0,180},   mess = "Mage's Guild - Vivec"          },
{ id = 10, cell = "Ald-ruhn, The Rat In The Pot",                  pos = {1,-567,-137},    rot = {0,0,0},     mess = "Thieve's Guild - Ald'ruhn"  },
{ id = 11, cell = "Balmora, South Wall Cornerclub",                pos = {11,-6,86},       rot = {0,0,90},    mess = "Thieve's Guild - Balmora"  },
{ id = 12, cell = "Sadrith Mora, Dirty Muriel's Cornerclub",       pos = {-256,-32,211},   rot = {0,0,180},   mess = "Thieve's Guild - Sadrith Mora"  },
{ id = 13, cell = "Vivec, Simine Fralinie: Bookseller",            pos = {6542,52,-160},   rot = {0,0,90},    mess = "Thieve's Guild - Vivec"         },
{ id = 14, cell = "Vivec, Arena Hidden Area",                      pos = {185,516,-410},   rot = {0,0,270},   mess = "Morag Tong - Headquarters, Vivec"  },
{ id = 15, cell = "Ald-ruhn, Morag Tong Guildhall",                pos = {-16,-96,0},      rot = {0,0,0},     mess = "Morag Tong - Ald'ruhn"  },
{ id = 16, cell = "Balmora, Morag Tong Guild",                     pos = {21,-224,98},     rot = {0,0,0},     mess = "Morag Tong - Balmora"  },
{ id = 17, cell = "Sadrith Mora, Morag Tong Guild",                pos = {-241,-0,250},    rot = {0,0,90},    mess = "Morag Tong - Sadrith Mora"  },        
}
elseif ( button == 2 ) then 
-- { id = 61, butt = { "Imperial Cult - Fort Pelagiad", " - Fort Darius", " - Wolverine Hall", " - Vivec, Foreign Quarter", " - Imperial Chapel in Ebonheart", " - Mournhold's Royal Palace", "The Temple - Ald'ruhn", " - Balmora", " - Ghostgate", " - Gnisis", " - Maar Gan", " - Molag Mar", " - Mournhold. TR", " - Sadrith Mora", "Cancel"}, mess = "Teleport to which Guild Hall - I-T" },
Guilds = {
{ id =  1, cell = "Buckmoth Legion Fort",           pos = {-12008,43889,2607},  rot = {0,0,270 }, mess = "Imperial Cult - Fort Buckmoth"  },
{ id =  2, cell = "Fort Frostmouth",                pos = {-174030,138759,345}, rot = {0,0,0},    mess = "Imperial Cult - Fort Frostmoth"  },
{ id =  3, cell = "Moonmoth Legion Fort, Interior", pos = {-116,18,-47 },       rot = {0,0,0},    mess = "Imperial Cult - Fort Moonmoth"  },
{ id =  4, cell = "Pelagiad, Fort Pelagiad",        pos = {1085,11,208},        rot = {0,0,90},   mess = "Imperial Cult - Fort Pelagiad"  },
{ id =  5, cell = "Gnisis, Fort Darius",            pos = {9,15,-38},           rot = {0,0,0},    mess = "Imperial Cult - Fort Darius"  },
{ id =  6, cell = "Gnisis, Fort Darius",            pos = {-64.416,32},         rot = {0,0,90},   mess = "Imperial Cult - Wolverine Hall"  },
{ id =  7, cell = "Vivec, Foreign Quarter Canalworks",  pos = {-895,-252,338},  rot = {0,0,270},  mess = "Imperial Cult - Vivec, Foreign Quarter"  },
{ id =  8, cell = "Imperial Chapel in Ebonheart",       pos = {11,-5,104},      rot = {0,0,0},    mess = "Imperial Cult - Imperial Chapel in Ebonheart"  },
{ id =  9, cell = "Mournhold, Royal Palace: Imperial Cult Services", pos = {877,494,-34}, rot = {0,0,180},  mess = "Imperial Cult - Mournhold's Royal Palace"  },
{ id = 10, cell = "Ald-ruhn, Temple",              pos = {3328,4096,14816},     rot = {0,0,90},   mess = "The Temple - Ald'ruhn"  },
{ id = 11, cell = "Balmora, Temple",               pos = {3664,4256,14816},     rot = {0,0,90},   mess = "The Temple - Balmora"  },
{ id = 12, cell = "Ghostgate, Temple",             pos = {-375,1,-413},         rot = {0,0,90},   mess = "The Temple - Ghostgate"  },
{ id = 13, cell = "Gnisis, Temple",                pos = {288,2816,-48},        rot = {0,0,90},   mess = "The Temple - Gnisis"  },
{ id = 14, cell = "Maar Gan, Shrine",              pos = {-2176,1792,992},      rot = {0,0,180},  mess = "The Temple - Maar Gan"  },
{ id = 15, cell = "Molag Mar, Temple",             pos = {-11,370,80},          rot = {0,0,180},  mess = "The Temple - Molag Mar"  },
{ id = 16, cell = "Mournhold Temple: Reception Area", pos = {1,-478,-665},      rot = {0,0,0},    mess = "The Temple - Mournhold. TR"  },
{ id = 17, cell = "Sadrith Mora, Telvanni Council House, Hermitage", pos = {3827,3061,2091}, rot = {0,0,0}, mess = "The Temple - Sadrith Mora"  },                      
}
end
return Guilds
end

-- -=-=-=-=-=-
function this.Taverns(button)

local Taverns = {}
if ( button == 1 ) then   -- A-S 15
Taverns = {
{ id =  1, cell = "Ald-ruhn, Ald Skar Inn",             pos = {372,-346,-131},   rot = {0,0,180},   mess = "Ald'ruhn - Ald Skar Inn"  },
{ id =  2, cell = "Ald-ruhn, The Rat In The Pot",       pos = {1,-567,-137},     rot = {0,0,0},     mess = "Ald'ruhn - The Rat in the Pot"  },
{ id =  3, cell = "Balmora, Council Club",              pos = {10,218,115},      rot = {0,0,180},   mess = "Balmora - Council Club"  },
{ id =  4, cell = "Balmora, Eight Plates",              pos = {-92,-290,-128},   rot = {0,0,90},    mess = "Balmora - Eight Plates"  },
{ id =  5, cell = "Balmora, Lucky Lockup",              pos = {-249,510,-398},   rot = {0,0,97},    mess = "Balmora - Lucky Lockup"  },
{ id =  6, cell = "Balmora, South Wall Cornerclub",     pos = {11,-6,86},        rot = {0,0,90},    mess = "Balmora - South Wall Cornerclub"  },
{ id =  7, cell = "Caldera, Shenk's Shovel",            pos = {-36,-14,210},     rot = {0,0,90},    mess = "Caldera - Shenk's Shovel"  },
{ id =  8, cell = "Dagon Fel, End of the World Renter Rooms", pos = {511,88,-45}, rot = {0,0,45},    mess = "Dagon Fel - End of the World"  },
{ id =  9, cell = "Ebonheart, Six Fishes",             pos = {256,24,88},        rot = {0,0,0},     mess = "Ebonheart - Six Fishes"  },
{ id = 10, cell = "Maar Gan, Andus Tradehouse",        pos = {8,-826,-176},      rot = {0,0,0},     mess = "Maar Gan - Andus Tradehouse"  },
{ id = 11, cell = "Molag Mar, The Pilgrim's Rest",     pos = {-257,266,84},      rot = {0,0,180},   mess = "Molag Mar - The Pilgrim's Rest"  },
{ id = 12, cell = "Pelagiad, Halfway Tavern",          pos = {234,-261,86},      rot = {0,0,270},   mess = "Pelagiad - Halfway Tavern"  },
{ id = 13, cell = "Sadrith Mora, Fara's Hole in the Wall", pos = {267,138,495},  rot = {0,0,270},   mess = "Sadrith Mora - Fara's Hole in the Wall"  },
{ id = 14, cell = "Sadrith Mora, Gateway Inn",         pos = {3997,4316,602},    rot = {0,0,0},     mess = "Sadrith Mora - Gateway Inn"  },
{ id = 15, cell = "Sadrith Mora, Dirty Muriel's Cornerclub", pos = {-256,-32,211}, rot = {0,0,180}, mess = "Sadrith Mora - Dirty Muriel's Cornerclub"  },
}
elseif ( button == 2) then   -- S-Z 12
Taverns = {
{ id =  1, cell = "Seyda Neen, Arrille's Tradehouse",          pos = {-242,-12,218},   rot = {0,0,180},   mess = "Seyda Neen - Arrille's Tradehouse"  },
{ id =  2, cell = "Suran, Desele's House of Earthly Delights", pos = {-274,-6,88},     rot = {0,0,180},   mess = "Suran - Desele's House of Earthly Delights"  },
{ id =  3, cell = "Tel Aruhn, Plot and Plaster",               pos = {303,121,474},    rot = {0,0,270},   mess = "Tel Aruhn - Plot and Plaster"  },
{ id =  4, cell = "Tel Branora, Sethan's Tradehouse",          pos = {959,-280,-47},   rot = {0,0,290},   mess = "Tel Branora - Sethan's Tradehouse"  },
{ id =  5, cell = "Tel Mora, The Covenant",                    pos = {-257,-8,197},    rot = {0,0,90},    mess = "Tel Mora - The Covenant"  },
{ id =  6, cell = "Vivec, Black Shalk Cornerclub",             pos = {-64,0,32},       rot = {0,0,0},     mess = "Vivec - Black Shalk Cornerclub"  },
{ id =  7, cell = "Vivec, No Name Club",                       pos = {-561,244,-171},  rot = {0,0,180},   mess = "Vivec - No Name Club"  },
{ id =  8, cell = "Vivec, Elven Nations Cornerclub",           pos = {-191,181,-168},  rot = {0,0,180},   mess = "Vivec - Elven Nations Cornerclub"  },
{ id =  9, cell = "Vivec, The Flowers of Gold",                pos = {-512,352,-32},   rot = {0,0,180},   mess = "Vivec - The Flowers of Gold"  },
{ id = 10, cell = "Vivec, The Lizard's Head",                  pos = {0,0,-32},        rot = {0,0,0},     mess = "Vivec - The Lizard's Head"  },
{ id = 11, cell = "Vos - Varo Tradehouse",                     pos = {-65,41,210},     rot = {0,0,80},    mess = "Vos - Varo Tradehouse"  },
{ id = 12, cell = "Mournhold, The Winged Guar",                pos = {2,-20,-41},      rot = {0,0,0},     mess = "Mournhold - The Winged Guar"  },            
}
end
return Taverns
end

-- -=-=-=-=-=-
function this.Barrows()
local Barrows= {
{ id =  1, cell = "Solstheim, Bloodskal Barrow",     pos = {1, -8,34},          rot = {0,0,180},  mess = "Bloodskal Barrow" },
{ id =  2, cell = "Solstheim, Connorflenge Barrow",  pos = {24,16,34},          rot = {0,0,180},  mess = "Connorflenge Barrow" },
{ id =  3, cell = "Solstheim, Eddard Barrow",        pos = {13,59,-47},         rot = {0,0,180},  mess = "Eddard Barrow" },
{ id =  4, cell = "Solstheim, Frosselmane Barrow",   pos = {17, 63,-17},        rot = {0,0,180},  mess = "Frosselmane Barrow" },
{ id =  5, cell = "Solstheim, Gyldenhul Barrow",     pos = {4339, -1086,34154}, rot = {0,0,0},    mess = "Gyldenhul Barrow" },
{ id =  6, cell = "Solstheim, Himmelhost Barrow",    pos = {12,51,-25},         rot = {0,0,180},  mess = "Himmelhost Barrow" },
{ id =  7, cell = "Solstheim, Hrothmund's Barrow",   pos = {4101,4021,16003},   rot = {0,0,0},    mess = "Hrothmund's Barrow" },
{ id =  8, cell = "Solstheim, Jolgeirr Barrow",      pos = {146,320,-29},       rot = {0,0,180},  mess = "Jolgeirr Barrow" },
{ id =  9, cell = "Solstheim, Kelsedolk Barrow",     pos = {18,43,-28},         rot = {0,0,180},  mess = "Kelsedolk Barrow" },
{ id = 10, cell = "Solstheim, Kolbjorn Barrow",      pos = {5,15,19},           rot = {0,0,180},  mess = "Kolbjorn Barrow" },
{ id = 11, cell = "Solstheim, Lukesturm Barrow",     pos = {9,27,-5},           rot = {0,0,180},  mess = "Lukesturm Barrow" },
{ id = 12, cell = "Solstheim, Skogsdrake Barrow",    pos = {21,51,-21},         rot = {0,0,180},  mess = "Skogsdrake Barrow" },
{ id = 13, cell = "Solstheim, Stormpfund Barrow",    pos = {5,-4,26},           rot = {0,0,180},  mess = "Stormpfund Barrow" },
{ id = 14, cell = "Solstheim, Valbrandr Barrow",     pos = {4226,4218,16054},   rot = {0,0,180},  mess = "Valbrandr Barrow" },     
}
return Barrows
end


-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- 240
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

return this   


--[[
Propylon Chambers
    
		Player->PositionCell, 540, 630, -368, 270,    "Andasreth, Propylon Chamber"
		Player->PositionCell, 540, 1024, -608, 270,   "Berandas, Propylon Chamber"
		Player->PositionCell, 302, 504, -368, 270,    "Falasmaryon, Propylon Chamber"
		Player->PositionCell, 410 898 -496 270,       "Falensarano, Propylon Chamber"
		Player->PositionCell, 4097, 3898, 12758, 180, "Hlormaren, Propylon Chamber"
		Player->PositionCell, 489 766 -368 270,       "Indoranyon, Propylon Chamber"
    Player->PositionCell, 244 888 -368 270,       "Marandus, Propylon Chamber"
    Player->PositionCell, 268, 636, -366, 270,    "Rotheran, Propylon Chamber"
    Player->PositionCell, 408 767 -484 270,       "Telasero, Propylon Chamber"
    Player->PositionCell, 290, 778, -496, 720,    "Valenvaryon, Propylon Chamber"
--]]

--[[	
Balmoa
;Central
		Player->PositionCell -20536.178, -13959.923, 313.89, 90, "Balmora (-3, -2)"
;North-East
		Player->PositionCell -15262.94, -12789.999, 540.722, 180, "Balmora (-2, -2)"
;North-West
		Player->PositionCell -25516.857, -10150.058, 1122.241, 180, "Balmora (-4, -2)"
;South-East
		Player->PositionCell -16623.131, -15619.301, 304.729, 0, "Balmora (-3, -2)"
;South-West
		Player->PositionCell -24576.701, -16072.117, 614.389, 63, "Balmora (-4, -2)"
--]]

--[[
;Old Mournhold 
;Old Mournhold: Abandoned Crypt
		Player->PositionCell 333.016, -194.762, -100.297, 0, "Old Mournhold: Abandoned Crypt"
;Old Mournhold: Abandoned Passageway
		Player->PositionCell 116.455, -2796.581, 1560.489, 270, "Old Mournhold: Abandoned Passageway"
;Old Mournhold: Armory Ruins
		Player->PositionCell -511.402, 2168.475, -551.235, 270, "Old Mournhold: Armory Ruins"
;Old Mournhold: Battlefield
		Player->PositionCell 2995.547, -3586.494, 890.342, 315, "Old Mournhold: Battlefield"
;Old Mournhold: Bazaar Sewers
		Player->PositionCell 2752.493, -2048.906, -678.235, 0, "Old Mournhold: Bazaar Sewers"
;Old Mournhold: City Gate
		Player->PositionCell 82.287, 979.983, 344.000, 225, "Old Mournhold: City Gate"
;Old Mournhold: Forgotten Sewer
		Player->PositionCell 9538.918, 3013.084, -440.482, 0, "Old Mournhold: Forgotten Sewer"
;Old Mournhold: Gedna Relvel's Tomb'
		Player->PositionCell 185.799, 1.196, -112.000, 270, "Old Mournhold: Gedna Relvel's Tomb"
;Old Mournhold: Manor District
		Player->PositionCell 214.530, 89.917, 1012.249, 90, "Old Mournhold: Manor District"
;Old Mournhold: Moril Manor, Courtyard
		Player->PositionCell 40.036, 20.003, 69.089, 0, "Old Mournhold: Moril Manor, Courtyard"
;Old Mournhold: Moril Manor, East Building
		Player->PositionCell 193.677, -6.644, 12.091, 90, "Old Mournhold: Moril Manor, East Building"
;Old Mournhold: Moril Manor, North Building
		Player->PositionCell 56.959, 165.104, 16.000, 0, "Old Mournhold: Moril Manor, North Building"
;Old Mournhold: Palace Sewers
		Player->PositionCell -1953.985, -1599.364, 484.157, 166.2, "Old Mournhold: Palace Sewers"
;Old Mournhold: Residential Ruins
		Player->PositionCell -3001.525, 2648.683, -806.748, 180, "Old Mournhold: Residential Ruins"
;Old Mournhold: Residential Sewers
		Player->PositionCell 567.269, 10905.725, 871.977, 90, "Old Mournhold: Residential Sewers"
;Old Mournhold: Tears of Amun-Shae
		Player->PositionCell -180.840, 11460.979, 1299.754, 180, "Old Mournhold: Tears of Amun-Shae"
;Old Mournhold: Temple Catacombs
		Player->PositionCell 7216.097, 6399.597, 2560.921, 270, "Old Mournhold: Temple Catacombs"
;Old Mournhold: Temple Crypt
		Player->PositionCell 10.388, 38.350, 85.308, 345, "Old Mournhold: Temple Crypt"
;Old Mournhold: Temple Gardens
		Player->PositionCell -1743.769, -1665.309, -362.565, 135, "Old Mournhold: Temple Gardens"
;Old Mournhold: Temple Sewers
		Player->PositionCell -255.231, -2782.626, -159.662, 180, "Old Mournhold: Temple Sewers"
;Old Mournhold: Temple Sewers East
		Player->PositionCell 1631.582, 8631.988, 12257.400, 0, "Old Mournhold: Temple Sewers East"
;Old Mournhold: Temple Sewers West
		Player->PositionCell -181.520, 356.991, -176.000, 270, "Old Mournhold: Temple Sewers West"
;Old Mournhold: Temple Shrine
		Player->PositionCell 5615.727, -5531.344, -1752.251, 270, "Old Mournhold: Temple Shrine"
;Old Mournhold: Teran Hall
		Player->PositionCell -1108.019, -5254.605, -432.925, 270, "Old Mournhold: Teran Hall"
;Old Mournhold: West Sewers
		Player->PositionCell 1249.813, 5552.527, -176.000, 0, "Old Mournhold: West Sewers"
--]]
    
--[[
Tamriel Rebuilt:
cell = "Old Ebonheart, Docks 7,-18", pos = {60934, -145787, 420},     rot = {0,0,180} },
cell = "Othmura 3,-39",              pos =  {29340, -318665, 144},    rot = {0,0,286} },
-- Mage Guilds
cell = "Idathren 5,-34",             pos = {44912, -277235, 320},    rot = {0,0,180}, mess = "TR_Idathren_02_Mages Guild"
cell = "Narsis 7,-51",               pos = {62096, -41761, 88},      rot = {0,0,270}, mess = "Narsis, Guild of Mages"
cell = "Kragen Mar -15,-30",         pos = {-118033, -238002, 2384}, rot = {0,0,315}, mess = "Kragen Mar, Guild of Mages
cell = "Othmura 3,-39",              pos = {28102, -317372, 692},    rot = {0,0,0},   mess = "Othmura, Guild of Mages"
cell = "Julan-Shar Region -18,12",   pos = {-14672,1042844,2496},    rot = {0,0,180}, mess = "Baan Malur, Guild of Mages"
cell = "Firewatch 17,15",            pos = {142988, 128739, 404},    rot = {0,0,270}, mess = "Firewatch Palace, Guild of Mages"
cell = "Bal Oyra 18,23",             pos = {152975, 196272, 383},    rot = {0,0,225}, mess = "Bal Oyra, Keep: Mages Guild Relay"
cell = "Helnim 25,1",                pos = {211807, 9162, 637},      rot = {0,0,360}, mess = "Helnim, Helnim Hall: Mages Guild Relay"
cell = "" {}, pos = {0,0,}  --  ""
cell = "" {}, pos = {0,0,}  --  ""
cell = "" {}, pos = {0,0,}  --  ""
cell = "" {}, pos = {0,0,}  --  ""
--]]
    
   
--[[
Ancestral Tombs - 92 AGGGG !!!!!  6 menus x 16
Ancestral tombs serve as the last resting places of any Dunmer family important enough to have one. They are usually guarded by the animated spirits of the dead - Ghosts, Skeletons, Bonelords and Bonewalkers - although some have been taken over by Daedra or vampires, making professional graverobbing a dangerous business.

    Alas Ancestral Tomb — Located northwest of Mount Assarnibibi, at the end of a short canyon. (map) (Quest Related)
    Player->PositionCell -1020.140, -1274.823, 208.000, 0, "Alas Ancestral Tomb"
    
    Alen Ancestral Tomb — A hideout for some vampires, located in the West Gash mountains southeast of Khuul. (map)
    Player->PositionCell -928.000, 2656.000, 64.000, 180, "Alen Ancestral Tomb"
    
    Andalen Ancestral Tomb — A small tomb on Azura's Coast located southeast of the Erabenimsun Camp near the peninsula. (map)'
    Player->PositionCell 866.810, -1014.381, 347.927, 0, "Andalen Ancestral Tomb"
    
    Andalor Ancestral Tomb — A small tomb west of Indoranyon in the Grazelands. (map)
    Player->PositionCell 3065.650, 2881.765, 503.395, 270, "Andalor Ancestral Tomb"
    
    Andas Ancestral Tomb — A medium-sized tomb, located north of the Erabenimsun Camp and along the coast. (map)
    Player->PositionCell 777.565, -541.874, -622.705, 0, "Andas Ancestral Tomb"
    
    Andavel Ancestral Tomb — A tomb located at the center of the large island north of Urshilaku Camp. (map)
    Player->PositionCell -5212.000, -656.122, 2144.000, 180, "Andavel Ancestral Tomb"
    
    Andrano Ancestral Tomb — A medium-sized tomb halfway on the road between Seyda Neen and Pelagiad. (map) (Quest Related)
    Player->PositionCell 1376.000, 7552.000, 14624.000, 90, "Andrano Ancestral Tomb"
    
    Andrethi Ancestral Tomb — A tomb just west over the mountains from Balmora. (map)
    Player->PositionCell 2622.785, 1198.403, -809.616, 270, "Andrethi Ancestral Tomb"
    
    Andules Ancestral Tomb — A small, daedra-occupied tomb in the northern Molag Amur region west of Tel Aruhn. (map)
    Player->PositionCell -873.483, 50.683, 336.000, 0, "Andules Ancestral Tomb"
    
    Aralen Ancestral Tomb — A hideout for some vampires in the Grazelands. (map)
    Player->PositionCell 3547.998, 5728.001, 11520.000, 90, "Aralen Ancestral Tomb"
    
    Aran Ancestral Tomb — A medium-sized tomb east of Lake Nabia in the Molag Amur region. (map)
    Player->PositionCell -2354.736, 5113.247, -106.918, 180, "Aran Ancestral Tomb"
    
    Arano Ancestral Tomb — A large, Daedra infested tomb on the southern tip of Tel Branora's island. (map)'
    Player->PositionCell 864.040, 2112.659, -624.346, 270, "Arano Ancestral Tomb"
    
    Arenim Ancestral Tomb — A large tomb on Azura's Coast south of Sadrith Mora, east of the Erabenimsun Camp, and close to the Holamayan monastery. (map) (Quest Related)'
    Player->PositionCell 1987.192, -115.135, -195.214, 0, "Arenim Ancestral Tomb"
    
    Arethan Ancestral Tomb — A small tomb in the mountains of Molag Amur. (map)
    Player->PositionCell -736.000, 1568.000, 64.000, 0, "Arethan Ancestral Tomb"
    
    Aryon Ancestral Tomb — A medium-sized tomb in the southern Ashlands region. (map)
    Player->PositionCell -516.048, -6817.083, 1913.612, 90, "Aryon Ancestral Tomb"
    
    Arys Ancestral Tomb — A small tomb on an island west of Tel Branora in the Azura's Coast region. (map)'
    Player->PositionCell 12800.000, -4064.000, -592.698, 0, "Arys Ancestral Tomb"
    
    Baram Ancestral Tomb — A large tomb on an island north of Tel Aruhn in the Azura's Coast region. (map)'
    Player->PositionCell -2532.069, 248.229, 1532.271, 180, "Baram Ancestral Tomb"
    
    Beran Ancestral Tomb — A Daedra infested tomb south of Tel Branora in the Azura's Coast region. (map)'
    Player->PositionCell -2554.274, 3920.084, -549.373, 0, "Beran Ancestral Tomb"
    
    Dareleth Ancestral Tomb — A small tomb in the northeast Ashlands, west of Tel Vos. (map)
    Player->PositionCell 3841.013, -3036.513, 1680.000, 270, "Dareleth Ancestral Tomb"
    
    Dralas Ancestral Tomb — A large tomb between Dagon Fel and Rotheran on the island of Sheogorad. (map)
    Player->PositionCell -2840.584, -3487.175, 1296.000, 0, "Dralas Ancestral Tomb"
    
    Drath Ancestral Tomb — A small tomb southwest of the Urshilaku Camp in the Ashlands region. (map)
    Player->PositionCell -2480.000, -3100.000, 920.000, 90, "Drath Ancestral Tomb"
    
    Dreloth Ancestral Tomb — A small tomb on Azura's Coast, east of the Erabenimsun Camp. (map)'
    Player->PositionCell -10.983, 1924.284, 223.000, 180, "Dreloth Ancestral Tomb"
    
    Drethan Ancestral Tomb — A small tomb on an island in the Sheogorad Region, east of Rotheran. (map) (Quest Related)
    Player->PositionCell 5077.188, -2239.904, 916.000, 270, "Drethan Ancestral Tomb"
    
    Drinith Ancestral Tomb — The large tomb in the northern Ashlands, east-northeast of Kogoruhn. (map)
    Player->PositionCell -320.000, -4568.000, 2800.000, 180, "Drinith Ancestral Tomb"
    
    Dulo Ancestral Tomb — A hideout for some vampires in the northwestern Molag Amur region. (map)
    Player->PositionCell 1727.059, 199.944, 2032.000, 270, "Dulo Ancestral Tomb"
    
    Fadathram Ancestral Tomb — A small tomb south of the Ghostfence in the southern Ashlands region. (map)
    Player->PositionCell -391.125, 511.601, 535.955, 90, "Fadathram Ancestral Tomb"
    
    Falas Ancestral Tomb — A small, Daedra-occupied tomb just south of Gnisis. (map)
    Player->PositionCell 134.574, 22.636, 96.000, 0, "Falas Ancestral Tomb"
    
    Favel Ancestral Tomb — A small tomb west of the Ahemmusa Camp in the northern Grazelands. (map) (Quest Related)
    Player->PositionCell -63.753, 2082.876, 838.322, 180, "Favel Ancestral Tomb"
    
    Foreign Quarter Tomb — A burial ground in the Canalworks of the Foreign Quarter of Vivec. (map)
    
    Gimothran Ancestral Tomb — A mid-sized tomb on the northern edge of the Molag Amur region, south of Falensarano. (map)
    Player->PositionCell -668.000, -336.000, 1048.000, 180, "Gimothran Ancestral Tomb"
    
    Ginith Ancestral Tomb — A hideout for a vampire named Irarak and his servants in the West Gash, northwest of Gnisis. (map) (Quest Related)
    Player->PositionCell 6.100, -9.526, 474.128, 0, "Ginith Ancestral Tomb"
    
    Helan Ancestral Tomb — A tomb located in the southern Molag Amur region, just northeast of Molag Mar. (map)
    Player->PositionCell -1790.895, 381.134, 342.533, 0, "Helan Ancestral Tomb"
    
    Helas Ancestral Tomb — A small tomb in the eastern Ashlands, located between the Ghostfence and Falensarano. (map)
    Player->PositionCell -2170.810, 998.104, 377.370, 90, "Helas Ancestral Tomb"
    
    Heleran Ancestral Tomb — A very small tomb hidden in the basement of Nedhelas' House in Caldera. (map) (Quest Related)'
    Player->PositionCell 1937.453, 3650.716, 15324.959, 90, "Heleran Ancestral Tomb"
    
    Heran Ancestral Tomb — A small tomb on the Bitter Coast, south of Hla Oad. (map)
    Player->PositionCell -16.359, 2755.654, 336.000, 180, "Heran Ancestral Tomb"
    
    Hlaalu Ancestral Tomb — A medium-sized tomb on Azura's Coast, south of Molag Mar. (map)'
    Player->PositionCell -245.877, 1225.168, 467.894, 180, "Hlaalu Ancestral Tomb"
    
    Hlaalu Ancestral Vaults — A tomb found underneath Vivec's Hlaalu Canton. (map) (Quest Related)'
    
    Hleran Ancestral Tomb — A hideout for some vampires to the west of Ald'ruhn. (map)'
    Player->PositionCell -792.141, -714.598, 115.722, 0, "Hleran Ancestral Tomb"
    
    Hlervi Ancestral Tomb — An island tomb north of Sadrith Mora in the Azura's Coast region. (map)'
    Player->PositionCell 3136.000, -864.000, 1149.967, 270, "Hlervi Ancestral Tomb"
    
    Hlervu Ancestral Tomb — A medium-sized tomb on Azura's Coast, south of the Holamayan Monastery. (map)'
    Player->PositionCell -2.985, 2550.127, -432.000, 180, "Hlervu Ancestral Tomb"
    
    Ienith Ancestral Tomb — A medium-sized tomb in the Grazelands northeast of Falensarano. (map)
    Player->PositionCell -1077.025, 347.799, 193.224, 0, "Ienith Ancestral Tomb"
    
    Indalen Ancestral Tomb — A medium-sized tomb northeast of Caldera. (map)
    Player->PositionCell -486.060, -96.965, 2565.255, 180, "Indalen Ancestral Tomb"
    
    Indaren Ancestral Tomb — A Daedra-occupied tomb in the northern Ashlands. (map)
    Player->PositionCell -2664.450, -1241.092, 813.575, 90, "Indaren Ancestral Tomb"
    
    Llando Ancestral Tomb — A small tomb in the northern Ashlands between the Urshilaku Camp and Valenvaryon. (map)
    Player->PositionCell -964.536, 5416.220, 681.203, 180, "Llando Ancestral Tomb"
    
    Lleran Ancestral Tomb — A small tomb between Hla Oad and Pelagiad, north of Seyda Neen in the Ascadian Isles region. (map)
    Player->PositionCell 994.029, -903.218, 192.917, 0, "Lleran Ancestral Tomb"
    
    Llervu Ancestral Tomb — A very small tomb located between Ald Velothi and Gnisis in the West Gash. (map)
    Player->PositionCell -2.274, -2.851, 104.226, 0, "Llervu Ancestral Tomb"
    
    Maren Ancestral Tomb — A large tomb in the Molag Amur region west of the Erabenimsun Camp. (map)
    Player->PositionCell -1442.830, 2032.039, -47.327, 180, "Maren Ancestral Tomb"
    
    Marvani Ancestral Tomb — A small tomb concealing a larger one, called Tukushapal, in the southern Azura's Coast region near Tel Branora. (map) (Quest Related)'
    Player->PositionCell -604.816, 4852.815, -942.650, 180, "Marvani Ancestral Tomb"
    
    Nelas Ancestral Tomb — A large island tomb in the northern Sheogorad Region. (map)
    Player->PositionCell -2748.000, 2180.000, 1396.000, 90, "Nelas Ancestral Tomb"
    
    Nerano Ancestral Tomb — A small tomb west of Tel Vos in the Grazelands. (map) (Quest Related)
    Player->PositionCell -2613.048, 2900.472, -494.443, 180, "Nerano Ancestral Tomb"
    
    Norvayn Ancestral Tomb — A large tomb northeast of Hlormaren in the Bitter Coast region. (map)
    Player->PositionCell -1155.346, -1792.629, 1817.022, 90, "Norvayn Ancestral Tomb"
    
    Omalen Ancestral Tomb — A large tomb in the northern Ashlands, north of Kogoruhn and southeast of Valenvaryon. (map)
    Player->PositionCell -1508.000, -1636.000, 1284.000, 180, "Omalen Ancestral Tomb"
    
    Omaren Ancestral Tomb — A medium-sized, Daedra-occupied tomb leading to a lost Daedric Ruin in the Azura's Coast region, due east of Sadrith Mora and northeast of Anudnabia. (map) (Quest Related)'
    Player->PositionCell 2031.945, -6074.258, 2123.721, 0, "Omaren Ancestral Tomb"
    
    Orethi Ancestral Tomb — A small tomb on the island of Sheogorad, west of Dagon Fel. (map)
    Player->PositionCell 978.460, -876.555, 80.000, 0, "Orethi Ancestral Tomb"
    
    Othrelas Ancestral Tomb — A small tomb on an island west of Vivec's Foreign Quarter, home to some vampires. (map)'
    Player->PositionCell 1853.587, 779.172, 730.527, 270, "Othrelas Ancestral Tomb"
    
    Randas Ancestral Tomb — A medium-sized, daedra-occupied tomb southwest of Bal Isra in the West Gash. (map)
    Player->PositionCell 1575.574, -3700.597, 1152.346, 270, "Randas Ancestral Tomb"
    
    Ravel Ancestral Tomb — A large, Daedra-occupied tomb north of the Shrine of Azura and southwest of the Holamayan Monastery. (map)
    Player->PositionCell -1175.111, 2571.872, 347.201, 180, "Ravel Ancestral Tomb"
    
    Raviro Ancestral Tomb — A small tomb occupied by some vampires west of Molag Mar. (map)
    Player->PositionCell -0.579, 2051.093, 235.391, 180, "Raviro Ancestral Tomb"
    
    Redas Ancestral Tomb — A large, Daedra-occupied tomb just south of Molag Mar on Azura's Coast. (map) (Quest Related)'
    Player->PositionCell 3056.000, -2080.000, -544.000, 90, "Redas Ancestral Tomb"
    
    Redoran Ancestral Vaults — A small tomb located in the middle of the Canalworks in the Redoran Canton. (map)
    
    Releth Ancestral Tomb — A small tomb on an island south of Telasero and northeast of Mzahnch in the Azura's Coast region. (map)'
    Player->PositionCell 2690.092, 901.860, 470.238, 270, "Releth Ancestral Tomb"
    
    Reloth Ancestral Tomb — A large tomb southeast of Khuul and west of Maar Gan in the West Gash. (map) (Quest Related)
    Player->PositionCell 1208.000, 1480.000, 416.000, 180, "Reloth Ancestral Tomb"
    
    Rethandus Ancestral Tomb — A large tomb between Gnisis and Khuul in the West Gash. (map)
    Player->PositionCell -3160.000, -100.000, 1516.000, 180, "Rethandus Ancestral Tomb"
    
    Rothan Ancestral Tomb — A small tomb west of Maar Gan on the edge of the Ashlands region. (map) (Quest Related)
    Player->PositionCell -2183.633, 3483.432, 168.000, 180, "Rothan Ancestral Tomb"
    
    Sadryon Ancestral Tomb — A small tomb just north of Sadrith Mora in the Azura's Coast region. (map)'
    Player->PositionCell 703.215, -638.163, 112, 0, "Sadryon Ancestral Tomb"
    
    Salothan Ancestral Tomb — A small, Daedra-occupied tomb east-southeast of Gnisis and east-northeast of Berandas in the West Gash region. (map)
    Player->PositionCell -2459.148, -6143.122, 1200.488, 0, "Salothan Ancestral Tomb"
    
    Salothran Ancestral Tomb — A medium-sized tomb located halfway between Andasreth and Bal Isra in the West Gash region. (map)
    Player->PositionCell -1024, -1120, 288, 90, "Salothran Ancestral Tomb"
    
    Salvel Ancestral Tomb — A medium-sized tomb just inside the northeastern corner of the Ghostfence, northeast of Tureynulal. (map) (Quest Related)
    Player->PositionCell 4600, -1928, 1280, 270, "Salvel Ancestral Tomb"
    
    Samarys Ancestral Tomb — A medium-sized tomb on the Bitter Coast northwest of Seyda Neen. (map)
    Player->PositionCell -2272, 992, 352, 90, "Samarys Ancestral Tomb"
    
    Sandas Ancestral Tomb — A small tomb in the Ascadian Isles. (map)
    Player->PositionCell 1660.078, 7.169, 352.050, 270, "Sandas Ancestral Tomb"
    
    Sandus Ancestral Tomb — A large tomb just outside the eastern Ghostfence, northwest of Falensarano. (map)
    Player->PositionCell -319.903, -1467.572, 1904.000, 270, "Sandus Ancestral Tomb"
    
    Sarano Ancestral Tomb — A large tomb, due north of the Fields of Kummu (via a north-northeast bit of road), in the Ascadian Isles region. (map) (Quest Related)
    Player->PositionCell 224.000, 200.000, 32.000, 90, "Sarano Ancestral Tomb"
    
    Saren Ancestral Tomb — A medium-sized, daedra-occupied tomb northeast of Moonmoth Legion Fort and northwest of Marandus. (map)
    Player->PositionCell -1312.003, 540.785, 1824.000, 90, "Saren Ancestral Tomb"
    
    Sarethi Ancestral Tomb — A vampire lair on the northern shore of the island of Sheogorad, on the peninsula northwest of Dagon Fel. (map)
    Player->PositionCell -2937.748, 370.802, 1008.000, 180, "Sarethi Ancestral Tomb"
    
    Sarys Ancestral Tomb — A medium-sized tomb on an island off the Bitter Coast, west of Seyda Neen and south of the Odai Plateau. (map)
    Player->PositionCell 7028.375, 4415.659, 15001.793, 270, "Sarys Ancestral Tomb"
    
    Savel Ancestral Tomb — A small but crowded tomb between Molag Mar and the Shrine of Azura on Azura's Coast. (map)'
    Player->PositionCell 384.000, 1272.000, 728.000, 180, "Savel Ancestral Tomb"
    
    Senim Ancestral Tomb — A large tomb southeast of Dagon Fel on the island of Sheogorad. (map)
    Player->PositionCell 1786.698, 830.678, 1264.000, 180, "Senim Ancestral Tomb"
    
    Seran Ancestral Tomb — A quite small, generic tomb within the borders of Khuul in the West Gash, southwest of the silt strider. (map)
    Player->PositionCell 1340.020, 2811.338, -11.189, 270, "Seran Ancestral Tomb"
    
    Serano Ancestral Tomb — A hideout for some vampires just north of Galom Daeus in the Molag Amur region. (map)
    Player->PositionCell -480.000, -1376.000, 2080.000, 0, "Serano Ancestral Tomb"
    
    Sethan Ancestral Tomb — A medium-sized tomb just south of the Zainab Camp in the Grazelands. (map)
    Player->PositionCell 3076.000, -3576.000, 3372.000, 0, "Sethan Ancestral Tomb"
    
    Telvayn Ancestral Tomb — A mid-sized tomb serving as a bandit hideout northeast of Gnaar Mok and east of Andasreth in the West Gash. (map) (Quest Related)
    Player->PositionCell -2181.687, 2456.948, 1008.000, 180, "Telvayn Ancestral Tomb"
    
    Thalas Ancestral Tomb — A small tomb northeast of Moonmoth Legion Fort in the southern Ashlands. (map)
    Player->PositionCell 1118.142, -1272.453, -208.000, 270, "Thalas Ancestral Tomb"
    
    Tharys Ancestral Tomb — A small tomb just southwest of Balmora in the West Gash. (map)
    Player->PositionCell 2092.789, 272.204, -80.395, 270, "Tharys Ancestral Tomb"
    
    Thelas Ancestral Tomb — A small tomb west of Seyda Neen on the Bitter Coast. (map)
    Player->PositionCell 120.507, -169.263, 91.203, 180, "Thelas Ancestral Tomb"
    
    Thiralas Ancestral Tomb — A daedra-occupied tomb mid-way between the Zainab Camp and Tel Aruhn in the Grazelands. (map)
    Player->PositionCell -1280.369, 386.138, 217.217, 90, "Thiralas Ancestral Tomb"
    
    Urshilaku Burial Caverns — A burial site some way to the south and a little to the east from the Urshilaku Camp. (map) (Quest Related)
    
    Uveran Ancestral Tomb — A mid-sized tomb just south of the Caldera Mine and north of Balmora in the West Gash. (map)
    Player->PositionCell 1934.000, -1558.922, 1774.555, 180, "Uveran Ancestral Tomb"
    
    Vandus Ancestral Tomb — A mid-sized tomb east of Marandus and north of Bal Ur in the Molag Amur region. (map)
    Player->PositionCell -2560.000, 1632.000, -192.000, 90, "Vandus Ancestral Tomb"
    
    Velas Ancestral Tomb — A small tomb just southwest of Telasero in the Molag Amur region. (map)
    Player->PositionCell -640.000, 3264.000, 144.000, 180, "Velas Ancestral Tomb"
    
    Veloth Ancestral Tomb — A mid-sized Daedra-occupied tomb just southeast of Berandas in the West Gash. (map)
    Player->PositionCell 1056.000, -4588.149, 2016.000, 180, "Veloth Ancestral Tomb"
    
    Venim Ancestral Tomb — A necromancer's hideout just north of the Zainab Camp in the Grazelands. (map)'
    Player->PositionCell -514.012, 4989.083, 635.230, 90, "Venim Ancestral Tomb"
    
    Verelnim Ancestral Tomb — A Daedra-occupied island tomb off of Azura's Coast, north of Holamayan and south-southeast of Wolverine Hall. (map)'
    Player->PositionCell 3360.000, -512.000, -352.000, 270, "Verelnim Ancestral Tomb"
--]]
    
    
--[[
Open Boats - 8
    Frost-Ghost — A small open boat just north of the Foreign Quarter in Vivec owned by Ano Andaram who is offering transport. (map)
    Harpy — A boat owned by Baleni Salavel, operating from the docks in Hla Oad. She provides you transport to Ebonheart, Gnaar Mok, Molag Mar and Vivec. (map)
    Omenwedur — A small open vessel at the docks of Khuul. (map)
    Pole Star — A small open boat at the docks of Tel Mora owned by Tonas Telvani who is offering transport. (map)
    Priggage — A small open boat in Gnaar Mok belonging to Valveli Arelas, who offers travel services. (map)
    Saucy — A small open vessel docked at Tel Aruhn. (map)
    Spring — A small open boat at the docks of Tel Branora, owned by Nireli Farys who is offering transport. (map)
    Whistler — A small open boat owned by Rindral Dralor who is offering transport outside Molag Mar. (map)
--]]
    
--[[
Imperial Legion
    "Imperial Legion - Buckmoth Legion Fort"  .
    "Imperial Legion - Fort Frostmoth. BM"    
    "Imperial Legion - Gnisis, Fort Darius"   .
    "Imperial Legion - Moonmoth Legion Fort"   .
    "Imperial Legion - Mournhold. TR"        
    "Imperial Legion - Fort Pelagiad"     .

--- umm to kill them maybe !!!
Vampire Aundae Clan
Vampire Berne Clan
Vampire Quarra Clan

--]]
    