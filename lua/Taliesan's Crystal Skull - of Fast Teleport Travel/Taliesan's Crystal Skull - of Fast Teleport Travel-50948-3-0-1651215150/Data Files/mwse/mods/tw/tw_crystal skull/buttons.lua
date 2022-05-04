local this = {}

function this.mainmenu()
local menu = {
    {id = 1,  butt = {"Towns", "Cancel"}                                                                                                , status = 11, mess = "Teleport to where?" },
    {id = 2,  butt = {"Towns", "Strongholds", "Cancel"}                                                                                 , status = 12, mess = "Teleport to where?" }, 
    {id = 3,  butt = {"Towns", "Strongholds", "Camps", "Cancel"}                                                                        , status = 13, mess = "Teleport to where?" },
    {id = 4,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Cancel"}                                      , status = 14, mess = "Teleport to where?" },     
    {id = 5,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Secret Masters", "Cancel"}                    , status = 15, mess = "Teleport to where?" },       
    {id = 6,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Secret Masters", "Shrines", "Cancel"}         , status = 16, mess = "Teleport to where?" },    
    {id = 7,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Secret Masters", "Shrines", "Ruins", "Cancel"}, status = 17, mess = "Teleport to where?" },     
    {id = 8,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Secret Masters", "Shrines", "Ruins", "Ultimate Menu", "Cancel"}, status = 18, mess = "Teleport to where?" },     
    --=-=-=-=-=-     
    --{id = 9,  butt = {      
    --{id = 10, butt = {    
    -- Towns likePC 1
    {id = 10  , butt = {"Back...", "Ald'Ruhn", "Balmora", "Caldera", "Hla Oad", "Gnisis", "Seyda Neen", "Suran", "Cancel"}         , status = 100, mess = "Teleport to Towns..." }, 
    {id = 110 , butt = {"Back...", "Ald'Ruhn", "Balmora", "Caldera", "Dagon Fel", "Ebonheart", "Gnaar Mok", "Gnisis", "Hla Oad", "Khuul", "Molag Mar", "Pelagiad", "Seyda Neen", "Sadrith Mora", "Suran", "Vivec", "Cancel"}, status = 110, mess = "Teleport to Towns..." },
    --{id = 110 , butt = {"Ald'Ruhn", "Balmora", "Caldera", "Hla Oad", "Gnisis", "Seyda Neen", "Suran", "Ebonheart", "Dagon Fel", "Gnaar Mok", "Khuul", "Molag Mar", "Pelagiad", "Sadrith Mora", "Vivec", "Cancel"}, status = 110, mess = "Teleport to Towns..." },
    --{id = 120 , butt = {"Ebonheart", "Dagon Fel", "Gnaar Mok", "Khuul"  , "Molag Mar", "Pelagiad", "Sadrith Mora", "Vivec", "Cancel"}, status = 120, mess = "Teleport to Towns..." },
    -- Balmora  likePC 2
    {id = 111 , butt = {"Back...", "Council Club", "South Wall Cornerclub", "Hlaalu Council Manor", "Hlaalo Manor", "Mage Guild", "Fighters Guild", "Lucky Lockup", "Caius Cosades' House", "Eight Plates", "The Temple", "Balmora", "Cancel"}, status = 121, mess = "Teleport to Balmora ..." },   -- "Main Menu",
    --{id = 111 , butt = {"Hlaalu Council Manor", "Hlaalo Manor", "Mage Guild", "Fighters Guild", "Lucky Lockup", "Caius Cosades' House", "Eight Plates", "Balmora", "Cancel"}, status = 121, mess = "Teleport to Balmora ..." },   -- "Main Menu",
    -- Vivec  likePC 2
    {id = 122 , butt = {"Back...", "Arena", "Arena Pit", "Foreign Quarter", "Foreign Quarter Plaza", "Hlaalu", "Hlaalu Plaza", "Redoran", "Redoran Plaza", "St. Delyn", "St. Delyn Plaza", "St. Olms", "St. Olms Plaza", "Telvanni", "Telvanni Plaza", "High Fane", "Vivec", "Cancel" }, status = 122, mess = "Teleport to Vivec..."},  -- "Main Menu", 
    -- Stronghold   likePC 2       
    {id = 20  , butt = {"Back...", "Berandas", "Hlormaren", "Falensarano", "Falasmaryon", "Telasero", "Cancel" }, status = 200, mess = "Teleport to Strongholds..." },
    {id = 21  , butt = {"Back...", "Andasreth", "Berandas",  "Hlormaren", "Falensarano", "Falasmaryon", "Indoranyon", "Marandus", "Rotheran", "Telasero", "Valenvaryon", "Cancel" }, status = 200, mess = "Teleport to Strongholds..." },
    --{id = 21  , butt = {"Berandas", "Hlormaren", "Telasero", "Falensarano", "Falasmaryon", "Andasreth", "Marandus" , "Indoranyon", "Rotheran", "Valenvaryon", "Cancel" }, status = 200, mess = "Teleport to Strongholds..." },
    --{id = 22  , butt = {"Andasreth", "Marandus" , "Indoranyon", "Rotheran", "Valenvaryon", "Cancel" }, status = 200, mess = "Teleport to Strongholds..." },
    -- Camps  likePC 3
    {id = 30  , butt = {"Back...", "Ahemmusa", "Erabenimsum", "Urshilaku", "Zainab", "Cancel"}, status = 300, mess = "Teleport to Camp..." },
    -- Great House  likePC 4    
    {id = 40 , butt = {"Back...", "Hlaalu", "Telvanni", "Redoran", "Cancel"}, status = 400, mess = "Teleport to which Great House..." },
    -- Misc   likePC 5
    {id = 50 , butt = {"Back...", "Caldera, Ghorak Manor", "Mudcrab merchant", "Tel Branora, Fadase Selvayn", "Ghostgate", "Mournhold", "Solstheim", "Cancel" } , status = 500 , mess = "Teleport to where?" }, 
    {id = 51 , butt = {"Back...", "Godsreach", "Great Bazaar", "Museum of Artifacts", "Plaza Brindisi Dorom", "Palace", "Temple", "Cancel"}, status = 501 , mess = "Teleport to Mournhold..." } ,
    {id = 52 , butt = {"Back...", "Fort Frostmouth", "Raven Rock", "Skaal Village", "Thirsk", "Castle Karstaag", "Cancel"}, status = 502 , mess = "Teleport to Solstheim..." },
    --{id = 53 , butt = {"Ald Redaynia" ,"Ald Velothi", "Maar Gan", "Tel Aruhn", "Tel Branora", "Tel Mora", "Tel Fyr", "Cancel"  }      , status = 500 , mess = "Teleport to where?" }, 
    -- Secret Masters   likePC 6   
    {id = 60 , butt = {"Back...", "Acrobatics", "Alchemy", "Alteration", "Armorer", "Athletics", "Axe", "Block","Blunt Weapons", "Conjuration", "Destruction", "Enchant", "Hand-to-Hand", "Heavy Armor", "Illusion", "More Masters", "Cancel"}                         , status = 600 , mess = "Teleport to Master of..." },
    --{id = 61 , butt = {"Blunt Weapons", "Conjuration", "Destruction", "Enchant", "Hand-to-Hand", "Heavy Armor", "Illusion", "More Masters", "Cancel"}   , status = 601 , mess = "Teleport to Master of..." },
    {id = 62 , butt = {"Back...", "Light Armor", "Long Blade", "Marksmanship", "Medium Armor", "Merchantile", "Mysticism", "Restoration", "Security", "Short Blade", "Sneak", "Spear", "Speechcraft", "Unarmored", "Cancel"}, status = 602 , mess = "Teleport to Master of..." }, 
    --{id = 63 , butt = {"Security", "Short Blade", "Sneak", "Spear", "Speechcraft", "Unarmored", "Back", "Cancel"}                                        , status = 603 , mess = "Teleport to Master of..." }, 
    -- Shrines   likePC 7         
    {id = 70 , butt = {"Back...", "Azura", "Boethiah", "Clavicus Vile", "Malacath", "Madrunes Dagon", "Mephaia", "Molag Bal", "Sheogorath", "Cancel"}, status = 600  , mess = "Teleport to Shrine of..." }, 
    -- Ruins   likePC 7
    {id = 80 , butt = {"Back...", "Aleft", "Arkngthand", "Arkngthunch-Sturdumz", "Bethamez", "Bthanchend", "Bthuand", "Bthungthumz", "Dagoth Ur", "Druscashti", "Endusal", "Galom Daeus", "Mudan", "More", "Cancel"} , status = 800 , mess = "Teleport to Ruin..." } ,
    --{id = 81 , butt = {"Druscashti", "Endusal", "Galom Daeus", "Mudan", "Mzahnch", "Mzanchend", "Mzuleft", "Nchardahrk", "More", "Cancel"} , status = 801 , mess = "Teleport to Ruin..." } ,
    {id = 82 , butt = {"Back...", "Mzahnch", "Mzanchend", "Mzuleft", "Nchardahrk", "Nchardumz", "Nchuleft", "Nchuleftingth", "Nchurdamz", "Odrosal", "Tureynulal", "Vemynal", "Cancel"}       , status = 802 , mess = "Teleport to Ruin..." } },
    {id = 90 , butt = {}       , status = 900 , mess = "Teleport to Ultimate..." }
return menu
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function this.Vivec()   
local Vivec = {
  { id =  1, cell = "Vivec, Arena (4, -11)",             pos = {36542,-88450,1882},   rot = {0,0,180},  mess = "Vivec, Arena"     },
  { id =  2, cell = "Vivec, Arena Pit",                  pos = {-1725, -2, -12},      rot = {0,0,90},   mess = "Vivec, Arena Pit"      },
  { id =  3, cell = "Vivec, Foreign Quarter (3, -10)",   pos = {29919,-80957,3104},   rot = {0,0,180},  mess = "Vivec, Foreign Quarter"     },
  { id =  4, cell = "Vivec, Foreign Quarter Plaza",      pos = {1340, 127, 318},      rot = {0,0,0},    mess = "Vivec, Foreign Quarter Plaza"     },
  { id =  5, cell = "Vivec, Hlaalu (2, -11)",            pos = {22211,-86265,2135},   rot = {0,0,180},  mess = "Vivec, Hlaalu"     },
  { id =  6, cell = "Vivec, Hlaalu Plaza",               pos = {-32, 1896, 124},      rot = {0,0,180},  mess = "Vivec, Hlaalu Plaza"     },
  { id =  7, cell = "Vivec, Redoran (3, -11)",           pos = {29120,-88455,1886},   rot = {0,0,180},  mess = "Vivec, Redoran"     },
  { id =  8, cell = "Vivec, Redoran Plaza",              pos = {-1677, 97, 1600},     rot = {0,0,90},   mess = "Vivec, Redoran Plaza"     },
  { id =  9, cell = "Vivec, St. Delyn (3, -12)",         pos = {29117,-94860,1880},   rot = {0,0,180},  mess = "Vivec, St. Delyn"     },
  { id = 10, cell = "Vivec, St. Delyn Plaza",            pos = {-1806, -93, -1742},   rot = {0,0,90},   mess = "Vivec, St. Delyn Plaza"     },
  { id = 11, cell = "Vivec, St. Olms (4, -12)",          pos = {36533,-94832,1879},   rot = {0,0,180},  mess = "Vivec, St. Olms"     },
  { id = 12, cell = "Vivec, St. Olms Plaza",             pos = {38, 1912, -942},      rot = {0,0,270},  mess = "Vivec, St. Olms Plaza"     },
  { id = 13, cell = "Vivec, Telvanni (5, -11)",          pos = {43450,-86263,2129},   rot = {0,0,180},  mess = "Vivec, Telvanni"     },
  { id = 14, cell = "Vivec, Telvanni Plaza",             pos = {38, 1912, -942},      rot = {0,0,180},  mess = "Vivec, Telvanni Plaza"     },
  { id = 15, cell = "Vivec, Temple (4, -13)",            pos = {32879,-99093,1168},   rot = {0,0,0},    mess = "Vivec, High Fane"     },
  { id = 16, cell = "Vivec",                             pos = {30646,-74586,567},    rot = {0,0,180},  mess = "Outside Vivec"  },                   
}
return Vivec
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--"Back..." add to all menus as button 0 !!!
--    {id = 111 , butt = {"Council Club", "South Wall Cornerclub", "Hlaalu Council Manor", "Hlaalo Manor", "Mage Guild", "Fighters Guild", "Lucky Lockup", "Caius Cosades' House", "Eight Plates", "The Temple", "Balmora", "Cancel"}, status = 121, mess = "Teleport to Balmora ..." },   -- "Main Menu",
function this.Balmora()   
local Balmora = {
  { id =  1, cell = "Balmora, Council Club",          pos = {10,218,115},        rot = {0,0,180},  mess = "Council Club"          },
  { id =  2, cell = "Balmora, South Wall Cornerclub", pos = {11,-6,86},          rot = {0,0,90},   mess = "South Wall Cornerclub" },
  { id =  3, cell = "Balmora, Hlaalu Council Manor",  pos = {-232,-10,97},       rot = {0,0,90},   mess = "Hlaalu Council Manor"  },
  { id =  4, cell = "Balmora, Hlaalo Manor",          pos = {-219,15,107},       rot = {0,0,90},   mess = "Hlaalo Manor"          },
  { id =  5, cell = "Balmora, Guild of Mages",        pos = {-506,-239,-128},    rot = {0,0,0},    mess = "Guild of Mages"        },
  { id =  6, cell = "Balmora, Guild of Fighters",     pos = {282,256,-32},       rot = {0,0,90},   mess = "Guild of Fighters"     },
  { id =  7, cell = "Balmora, Lucky Lockup",          pos = {-249,510,-399},     rot = {0,0,0},    mess = "Lucky Lockup"          },
  { id =  8, cell = "Balmora, Caius Cosades' House",  pos = {163,-228,192},      rot = {0,0,270},  mess = "Caius Cosades' House"  },
  { id =  9, cell = "Balmora, Eight Plates",          pos = {-109,-261,128},     rot = {0,0,0},    mess = "Eight Plates"          },
  { id = 10, cell = "Balmora, Temple",                pos = {3664,4256,14816},   rot = {0,0,90},   mess = "The Temple"            },
  { id = 11, cell = "Balmora",                        pos = {-22187,-18633,357}, rot = {0,0,0},    mess = "Balmora"               },
}
return Balmora
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function this.Towns()
local towns = {
  { id =  1, cell = "Ald'Ruhn",   pos = {-18006, 52005, 1756},   rot = {0,0,90},   mess = "Ald'Ruhn" },
  { id =  2, cell = "balmora",    pos = {0,0,0},                 rot = {0,0,0},    mess = "balmora" },   -- placeholder
  { id =  3, cell = "Caldera",    pos = {-14295, 22104, 1420},   rot = {0,0,180},  mess = "Caldera" },
  { id =  4, cell = "Dagon Fel",  pos = {64756, 183558, 597},    rot = {0,0,0},    mess = "Dagon Fel" },
  { id =  5, cell = "Ebonheart",  pos = {18553, -99084, 304},    rot = {0,0,180},  mess = "Ebonheart" },
  { id =  6, cell = "Gnaar Mok",  pos = {-59624, 28282, 114},    rot = {0,0,270},  mess = "Gnaar Mok" },
  { id =  7, cell = "Gnisis",     pos = {-78342, 90452, 980},    rot = {0,0,270},  mess = "Gnisis" },
  { id =  8, cell = "Hla Oad",    pos = {-46863, -38504, 125},   rot = {0,0,0},    mess = "Hla Oad" },
  { id =  9, cell = "Khuul",      pos = {-67365, 139095, 181},   rot = {0,0,0},    mess = "Khuul" },
  { id = 10, cell = "Molag Mar",  pos = {104481, -61113, 656},   rot = {0,0,90},   mess = "Molag Mar" },
  { id = 11, cell = "Pelagiad",   pos = {-2111, -57182, 1025},   rot = {0,0,90},   mess = "Pelagiad" },
  { id = 12, cell = "Seyda Neen", pos = {-11780, -67915, 170},   rot = {0,0,90},   mess = "Seyda Neen" },
  { id = 13, cell = "Sadrith Mora", pos = {142041, 37242, 207},  rot = {0,0,180},  mess = "Sadrith Mora" },
  { id = 14, cell = "Suran",      pos = {54394, -57951, 1007},   rot = {0,0,0},    mess = "Suran" },
  { id = 14, cell = "Vivec",      pos = {0,0,0},                 rot = {0,0,0},    mess = "Vivec" },    -- placeholder
}
return towns
end
    
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function this.Strongholds(button) -- mainmenu 2  - 15
local Strongholds
if (button == 20) then
Strongholds = {   
{ id =  1, cell = "Berandas",     pos = {-77788, 76069, 2351},    rot = {0,0,344},  mess = "Berandas" }, 
{ id =  2, cell = "Hlormaren",    pos = {-77788, 76069, 2351},    rot = {0,0,0},    mess = "Hlormaren" }, 
{ id =  3, cell = "Falensarano",  pos = {76153, 51408, 1683},     rot = {0,0,0},    mess = "Falensarano" }, 
{ id =  4, cell = "Falasmaryon",  pos = {-11955, 127599, 1455},   rot = {0,0,190},  mess = "Falasmaryon" }, 
{ id =  5, cell = "Telasero",     pos = {77330, -52928, 1444},    rot = {0,0,220},  mess = "Telasero" }, 
}
elseif (button == 21) then
Strongholds = {   
{ id =  1, cell = "Andasreth",   pos = {-68248, 47807, 1808},    rot = {0,0,160},  mess = "Andasreth"   }, 
{ id =  2, cell = "Berandas",    pos = {-77788, 76069, 2351},    rot = {0,0,344},  mess = "Berandas"    }, 
{ id =  3, cell = "Hlormaren",   pos = {-77788, 76069, 2351},    rot = {0,0,0},    mess = "Hlormaren"   }, 
{ id =  4, cell = "Falensarano", pos = {76153, 51408, 1683},     rot = {0,0,0},    mess = "Falensarano" }, 
{ id =  5, cell = "Falasmaryon", pos = {-11955, 127599, 1455},   rot = {0,0,190},  mess = "Falasmaryon" }, 
{ id =  6, cell = "Indoranyon",  pos = {-211, -2564, -582},      rot = {0,0,360},  mess = "Indoranyon"  }, 
{ id =  7, cell = "Marandus",    pos = {37083, -20283, 1454},    rot = {0,0,220},  mess = "Marandus"    }, 
{ id =  8, cell = "Rotheran",    pos = {53206, 154027, 1860},    rot = {0,0,130},  mess = "Rotheran"    }, 
{ id =  9, cell = "Telasero",    pos = {77330, -52928, 1444},    rot = {0,0,220},  mess = "Telasero"    }, 
{ id = 10, cell = "Valenvaryon", pos = {-3682, 154119, 2354},    rot = {0,0,180},  mess = "Valenvaryon" }, 
}
end
return Strongholds
end
-- stronghold
--    Kogoruhn
--    Player->PositionCell 5216, 120544, 1504, 180, "Kogoruhn (0, 14)"  
   
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function this.Camps() -- mainmenu 1  - 14 +10    
local menu = {
{ id = 1, cell = "Ahemmusa Camp (11, 16)",        pos = { 95373, 132907, 936 },   rot = { 0, 0, 137 }, mess = "Ahemmusa Camp"        },
{ id = 2, cell = "Erabenimsum Camp",              pos = { 107620, -2970, 717 },   rot = { 0, 0, 90 },  mess = "Erabenimsum Camp"        },
{ id = 3, cell = "Urshilaku Camp",                pos = { -29253, 150041, 727 },  rot = { 0, 0, 90 },  mess = "Urshilaku Camp"        },
{ id = 4, cell = "Zainab Camp (9, 10)",           pos = { 78351, 83963, 1010 },   rot = { 0, 0, 300 }, mess = "Zainab Camp"          },
}  
return menu
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function this.Mournhold()
-- {id = 51 {"Back...", "Godsreach", "Great Bazaar", "Museum of Artifacts", "Plaza Brindisi Dorom", "Palace", "Temple", "Cancel"}
local Mournhold = {
{ id = 1, cell = "Mournhold, Godsreach",                       pos = {2544,-224,176},    rot = {0,0,280},  mess = "Godsreach"      },  
{ id = 2, cell = "Mournhold, Great Bazaar",                    pos = {-504,2496,384},    rot = {0,0,160},  mess = "Great Bazaar"   },  
{ id = 3, cell = "Mournhold, Museum of Artifacts",             pos = {-2,131,-46},       rot = {0,0,0},    mess = "Museum of Artifacts"   },
{ id = 4, cell = "Mournhold, Plaza Brindisi Dorom",            pos = {0,3178,265},       rot = {0,0,180},  mess = "Plaza Brindisi Dorom"   },  
{ id = 5, cell = "Mournhold, Royal Palace: Reception Area",    pos = {22,997,-35},       rot = {0,0,170},  mess = "Palace Reception Area"   },  
{ id = 6, cell = "Mournhold, Temple Courtyard",                pos = { 0,-4704,220},     rot = {0,0,0},    mess = "Temple Courtyard"   },  
}
return Mournhold
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function this.Solstheim()
--{id = 52 {"Back...", "Fort Frostmouth", "Raven Rock", "Skaal Village", "Thirsk", "Castle Karstaag", "Cancel"} 
local Solstheim = {
{ id =  1, cell = "Fort Frostmoth (-22, 17)",            pos = {-174580,143857,1126},    rot = {0,0,180},  mess = "Fort Frostmoth"      },  
{ id =  2, cell = "Raven Rock (-25, 19)",                pos = {-197355,159749,824},     rot = {0,0,310},  mess = "Raven Rock"      },  
{ id =  3, cell = "Skaal Village (-20, 26)",             pos = {-159040,213038,3041},    rot = {0,0,180},  mess = "Skaal Village"      },  
{ id =  4, cell = "Solstheim, Lake Fjalding",            pos = {-156922,190036,986},     rot = {0,0,80},   mess = "Thirsk"      },  
{ id =  5, cell = "Solstheim, Castle Karstaag (-24,26)", pos = {-194212,216268,1024},    rot = {0,0,360},  mess = "Castle Karstaag"      },  
}
return Solstheim
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function this.Misc()
-- {id = 50 {"Back...", "Caldera, Ghorak Manor", "Mudcrab merchant", "Tel Branora, Fadase Selvayn", "Ghostgate", "Mournhold", "Solstheim", "Cancel" } 
local Misc = {
{ id =  1, cell = "Caldera, Ghorak Manor",                pos = {-772, -276, 475},    rot = {0,0,0},  mess = "Ghorak Manor"   },  
{ id =  2, cell = "Azura's Coast Region (9,-10)",         pos = {74600,-77476,131},   rot = {0,0,90}, mess = "Mudcrab merchant" },  
{ id =  3, cell = "Tel Branora, Fadase Selvayn: Trader",  pos = { -213, 7, 198 },     rot = {0,0,90}, mess = "Fadase Selvayn"   },  
{ id =  4, cell = "Ghostgate",                            pos = {20754, 38497, 1244}, rot = {0,0,0 }, mess = "Ghostgate"   },  
{ id =  5, cell = "Mournhold",     pos = {},    rot = {0,0,0 },  mess = "Mournhold"   },  
{ id =  6, cell = "Solstheim",     pos = {},    rot = {0,0,0 },  mess = "Solstheim"   },  
}
return Misc
end

-- -=-=-=-=-=-
function this.Master1() --(button)  
local Master = {
{ id =  1, cell = "Vivec, Arena Fighters Quarters",         pos = {12, -205, -32},       rot = {0, 0, 67},  mess = "Acrobatics Master Senyndie" },
{ id =  2, cell = "Valenvaryon, Propylon Chamber",          pos = {307, 747, -496},      rot = {0, 0, 270}, mess = "Alchemy Master Abelle Chriditte" },
{ id =  3, cell = "Tel Branora, Seryne Relas's House",      pos = {146, 22, 203},        rot = {0, 0, 280}, mess = "Alteration Master Seryne Relas" },
{ id =  4, cell = "Ebonheart, Hawkmoth Legion Garrison",    pos = {1040, 2544, -288},    rot = {0, 0, 180}, mess = "Armorer Master Sirollus Saccus" },
{ id =  5, cell = "Kaushtababi Camp, Adibael's Yurt",       pos = {-160, -187, -60},     rot = {0, 0, 40},  mess = "Athletics Master Adibael Hainnabibi" },
{ id =  6, cell = "Falensarano, Upper Level",               pos = {-1693, 3548, -1083},  rot = {0, 0, 268}, mess = "Axe Master Alfhedil Elf-Hewer" },
{ id =  7, cell = "Buckmoth Legion Fort",                   pos = {-12008, 43889, 2607}, rot = {0, 0, 270}, mess = "Block Master Shardie" },
{ id =  8, cell = "Vivec, The Abbey of St. Delyn the Wise", pos = {-510, 636, -422},     rot = {0, 0, 180}, mess = "Blunt Weapon Master Ernse Llervu" },
{ id =  9, cell = "Ald-ruhn, Temple",                       pos = {3328, 4096, 14816},   rot = {0, 0, 90},  mess = "Conjuration Master Methal Seran" },
{ id = 10, cell = "Ascadian Isles Region",                  pos = {37291, -61562, 894},  rot = {0, 0, 0},   mess = "Destruction Master Leles Birian" },
{ id = 11, cell = "Indoranyon",                             pos = {-211, -2564, -582},   rot = {0, 0, 360}, mess = "Enchant Master Qorwynn" },
{ id = 12, cell = "Holamayan Monastery",                    pos = {21, -605, -423},      rot = {0, 0, 0},   mess = "Hand-to-Hand Master Taren Omothan" },
{ id = 13, cell = "Vivec, Arena Fighters Training",         pos = {516, -1028, -46},     rot = {0, 0, 180}, mess = "Heavy Armor Master Seanwen" },
{ id = 14, cell = "Sadrith Mora, Dirty Muriel's Cornerclub", pos = {-256, -32, 211},     rot = {0, 0, 180}, mess = "Illusion Master Erer Darothril" },
}
return Master
end

-- -=-=-=-=-=-
function this.Master2() --(button)  
local Master = {
{ id =  1, cell = "Maar Gan, Andus Tradehouse",            pos = {8, -823, -176},        rot = {0, 0, 0},   mess = "Light Armor Master Aerin" },
{ id =  2, cell = "Molag Mar, Armigers Stronghold",        pos = {4092, 3781, 16218},    rot = {0, 0, 0},   mess = "Long Blade Master Ulms Drathen" },
{ id =  3, cell = "Falasmaryon, Missun Akin's Hut",        pos = {129, 382, -427},       rot = {0, 0, 0},   mess = "Marksman Master Missun Akin" },
{ id =  4, cell = "Tel Fyr",                               pos = {125557, 14100, 662},   rot = {0, 0, 0},   mess = "Medium Armor Master Cinia Urtius" },
{ id =  5, cell = "Zainab Camp, Ababael Timsar-Dadisun's Yurt", pos = {27, 378, -160},   rot = {0, 0, 0},   mess = "Merchantile Master Ababael Timsar-Dadisun" },
{ id =  6, cell = "Sadrith Mora, Gateway Inn: West Wing",  pos = {-797, 1460, -180},     rot = {0, 0, 180}, mess = "Mysticism Master Ardarume" },
{ id =  7, cell = "Vos, Vos Chapel",                       pos = {-4, 382, -40},         rot = {0, 0, 180}, mess = "Restoration MasterYakin Bael" },
{ id =  8, cell = "Balmora, Hecerinde's House",            pos = {93, 69, 98},           rot = {0, 0, 0},   mess = "Security Master Hecerinde" },
{ id =  9, cell = "Balmora, Lucky Lockup",                 pos = {-225, 503, -151},      rot = {0, 0, 90},  mess = "Short Blade Master Todwendy" },
{ id = 10, cell = "Gnaar Mok, Druegh-jigger's Rest",       pos = {3967, 4000, 14563},    rot = {0, 0, 0},   mess = "Sneak Master Wadarkhu" },
{ id = 11, cell = "Ghostgate, Tower of Dusk Lower Level",  pos = {4, -50, -27},          rot = {0, 0, 220}, mess = "Spear Master Mertis Falandas" },
{ id = 12, cell = "Sadrith Mora, Wolverine Hall: Mage's Guild", pos = {448, 192, 160},   rot = {0, 0, 0},   mess = "Speechcraft Master Skink-in-Tree's-Shade" },
{ id = 13, cell = "Dagon Fel, Vacant Tower",               pos = {-87, 265, 1232},       rot = {0, 0, 270}, mess = "Unarmored Master Khargol gro-Boguk" },
}
return Master
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--    {id = 70 , butt = {"Back...", "Azura", "Boethiah", "Clavicus Vile", "Malacath", "Madrunes Dagon", "Mephaia", "Molag Bal", "Sheogorath", "Cancel"}, status = 600  , mess = "Teleport to Shrine of..." }, 
function this.Shrines() --(button)  
local Shrines = {
{ id = 1, cell = "Azura's Coast Region",     pos = {162067, -61855, 1550},  rot = {0, 0, 280},   mess = "Azura" },
{ id = 2, cell = "Ashurnibibi",              pos = {162067, -61855, 1550},  rot = {0, 0, 280},   mess = "Boethiah" },
{ id = 3, cell = "Sheogorad Region",         pos = {67144, 182065, 953},    rot = {0, 0, 240},   mess = "Clavicus Vile" },
{ id = 4, cell = "Sheogorad Region",         pos = {679, 174764, 149},      rot = {0, 0, 180},   mess = "Malacath" },
{ id = 5, cell = "West Gash Region",         pos = {-118155, 115678, 445},  rot = {0, 0, 360},   mess = "Madrunes Dagon" },
{ id = 6, cell = "Vivec, Arena Hidden Area", pos = {185, 516, -410},        rot = {0, 0, 270},   mess = "Mephaia" },
{ id = 7, cell = "Yansirramus",              pos = {105514, 37781, 656},    rot = {0, 0, 280},   mess = "Molag Bal" },
{ id = 8, cell = "Vivec, St. Delyn Underworks",pos = {5840, 4448, 80},      rot = {0, 0, 180},   mess = "Sheogorath" },
}
return Shrines
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- {id = 80 , butt = {"Back...", "Aleft", "Arkngthand", "Arkngthunch-Sturdumz", "Bethamez", "Bthanchend", "Bthuand", "Bthungthumz", "Dagoth Ur", "Druscashti", "Endusal", "Galom Daeus", "Mudan", "More", "Cancel"} , status = 800 , mess = "Teleport to Ruin..." } ,
function this.Ruins(button) --(button)  
local Ruins = {}
if ( button == 1 ) then
Ruins = {  
{ id = 1, cell = "Bitter Coast Region",     pos = {-57340, 11938, 148},    rot = {0, 0, 80},   mess = "Aleft" },
{ id = 2, cell = "West Gash Region",        pos = {-2636, -13432, 2557},   rot = {0, 0, 90},   mess = "Arkngthand" },
{ id = 3, cell = "West Gash Region",        pos = {-95123, 116941, 2296},  rot = {0, 0, 270},  mess = "Arkngthunch-Sturdumz" },
{ id = 4, cell = "Gnisis(-10,11)",          pos = {-81299,94123,2224},     rot = {0, 0, 170},  mess = "Bethamez" },
{ id = 5, cell = "Red Mountain Region",     pos = {-14451, 83772, 3863},   rot = {0, 0, 350},  mess = "Bthanchend" },
{ id = 6, cell = "Ashlands Region",         pos = {36446, 131950, 760},    rot = {0, 0, 180},  mess = "Bthuand" },
{ id = 7, cell = "Ashlands Region",         pos = {-32150, 136807, 1241},  rot = {0, 0, 220},  mess = "Bthungthumz" },
{ id = 8, cell = "Dagoth Ur",               pos = {19000, 70642, 12027},   rot = {0, 0, 240},  mess = "Dagoth Ur" },
{ id = 9, cell = "Ashlands Region",         pos = {-44853, 141906, 1063},  rot = {0, 0, 220},  mess = "Druscashti" },
{ id = 10, cell = "Red Mountain Region",    pos = {10505 ,63124, 11513},   rot = {0, 0, 100},  mess = "Endusal" },
{ id = 11, cell = "Molag Amur Region",      pos = {70329, 5990, 965},      rot = {0, 0, 290},  mess = "Galom Daeus" },
{ id = 12, cell = "Ascadian Isles Region",  pos = {6515, -116815, 49},     rot = {0, 0, 190},  mess = "Mudan" },
{ id = 13, cell = "MORE", pos = {0,0,0},  rot = {0, 0, 0},  mess = "MORE" },  -- placeholder
}
-- {id = 82 , butt = {"Back...", "Mzahnch", "Mzanchend", "Mzuleft", "Nchardahrk", "Nchardumz", "Nchuleft", "Nchuleftingth", "Nchurdamz", "Odrosal", "Tureynulal", "Vemynal", "Cancel"}       , status = 802 , mess = "Teleport to Ruin..." } },
elseif ( button == 2 ) then
Ruins = { 
{ id = 1, cell = "Mzahnch Ruin",          pos = {71173, -73461, 168},  rot = {0, 0, 170},   mess = "Mzahnch" },
{ id = 2, cell = "Molag Amur Region",     pos = {75410, 17310, 1851},  rot = {0, 0, 360},   mess = "Mzanchend" },
{ id = 3, cell = "Mzuleft Ruin",          pos = {55607, 174326, 963},  rot = {0, 0, 340},   mess = "Mzuleft" },
{ id = 4, cell = "Sheogorad Region",      pos = {65564, 168667, 794},  rot = {0, 0, 200},   mess = "Nchardahrk" },
{ id = 5, cell = "Molag Amur Region",     pos = {125824, -39966, 1320},rot = {0, 0, 0},     mess = "Nchardumz" },
{ id = 6, cell = "Nchuleft Ruin",         pos = {69048, 102504, 2086}, rot = {0, 0, 300},   mess = "Nchuleft" },
{ id = 7, cell = "Nchuleftingth",         pos = {85219, -17123, 1001}, rot = {0, 0, 120},   mess = "Nchuleftingth" },
{ id = 8, cell = "Nchurdamz",             pos = {144213, -43914, 2520},rot = {0, 0, 240},   mess = "Nchurdamz" },
{ id = 9, cell = "Odrosal",               pos = {28926, 59355, 10778}, rot = {0, 0, 300},   mess = "Odrosal" },
{ id = 10, cell = "Tureynulal",           pos = {36846, 76349, 14021}, rot = {0, 0, 220},   mess = "Tureynulal" },
{ id = 11, cell = "Vemynal",              pos = {171, 87946, 7307},    rot = {0, 0, 90},    mess = "Vemynal" },
}
end
return Ruins
end

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--total = 139
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

return this   
