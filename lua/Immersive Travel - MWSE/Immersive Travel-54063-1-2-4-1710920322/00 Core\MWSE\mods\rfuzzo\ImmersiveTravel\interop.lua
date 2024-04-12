local this = {}

-- Please generate a short text a guide NPC in Morrowind would say about this location.
-- Keys are in the format "(-x, -y)" where x and y are the coordinates of the location.
-- Note the whitespace!



---@type table<string, string>
this.quips = {}


-- insert to table
function this.insertQuip(key, text)
    this.quips[key] = text
end

return this

-- Reference
--[[
Ahemmusa Camp  (11, 16)
Ald Daedroth  (11, 20)
Ald Redaynia  (-5, 21)
Ald Sotha  (6, -9)
Ald Velothi  (-11, 15)
Ald'ruhn  (-2, 6)
Andasreth  (-9, 5)
Arvel Plantation  (2, -6)
Ashalmawia  (-10, 15)
Ashurnabitashpi  (-5, 18)
Ashurnibibi (-7, -4)
Bal Fell  (8, -12)
Bal Isra  (-5, 9)
Bal Ur  (6, -5)
Balmora  (-3, -2)
Berandas  (-10, 9)
Buckmoth Legion Fort  (-2, 5)
Caldera  (-2, 2)
Dagon Fel  (7, 22)
Dagoth Ur  (2, 8)
Dren Plantation  (2, -7)
Ebonheart  (1, -13)
Erabenimsun Camp  (13, -1)
Falasmaryon  (-2, 15)
Falensarano  (9, 6)
Fields of Kummu  (1, -5)
Ghostgate  (2, 4)
Gnaar Mok  (-8, 3)
Gnisis  (-11, -11)
Hla Oad  (-6, -5)
Hlormaren  (-6, -1)
Holamayan  (19, -4)
Khartag Point  (-9, 4)
Khuul  (-9, 17)
Koal Cave Entrance  (-11, 9)
Kogoruhn  (0, 14)
Maar Gian  (-3, 12)
Marandus  (4, -3)
Molag Mar  (12, -8)
Moonmoth Legion Fort  (-1, -3)
Mount Assarnibibi  (14, -4)
Mount Kand  (11, -5)
Mzahnch Ruin  (8, -10)
Mzuleft Ruin  (6, 21)
Nchuleft Ruin  (8, 12)
Nchuleftingth  (10, -3)
Nchurdamz  (17, -6)
Odai Plateau  (-5, -5)
Odrosal  (3, 7)
Pelagiad  (0, -7)
Rotheran  (6, 18)
Sadrith Mora  (17, 4)
Sanctus Shrine  (1, 21)
Seyda Neen  (-2, -9)
Suran  (6, -6)
Tel Aruhn  (15, 5)
Tel Branora  (14, -13)
Tel Fyr  (15, 1)
Tel Mora  (13, 14)
Tel Vos  (10, 14)
Telasero  (9, -7)
Tureynulal  (4, 9)
Urshilaku Camp (-4, 18)
Uvinth's Grave  (10, -1)
Valenvaryon  (-1, 18)
Vas  (0, 22)
Vemynal  (0, 10)
Vivec  (3, -11)
Vos  (11, 14)
Wolverine Hall  (18, 3)
Yansirramus  (12, 4)
Zainab Camp  (9, 10)
Zaintirais  (12, -10)
Zergonipal  (5, 15)
]]
