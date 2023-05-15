local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local async = require("openmw.async")
local I = require("openmw.interfaces")


local travelData = {	{
    travel1destcellname = "ToddTest",
    class = "guard",
    ID = "todd",
    travel1dest = {
        x = 1822.6411132813,
        y = -231.53230285645,
        z = -292.95007324219,
    },
    travel1destrot = {
        z = 0.5,
    },
}
,	{
    travel1destcellname = "Balmora",
    travel2dest = {
        x = -65872.71875,
        y = 135522.265625,
        z = 1101.9825439453,
    },
    travel2destrot = {
        z = 1.3999999761581,
    },
    travel2destcellname = "Khuul",
    ID = "navam veran",
    travel3destrot = {
        z = 0,
    },
    travel3destcellname = "Maar Gan",
    travel4dest = {
        x = -86782.3671875,
        y = 89454.3515625,
        z = 1124.3341064453,
    },
    travel4destrot = {
        z = 0,
    },
    travel4destcellname = "Gnisis",
    class = "caravaner",
    travel3dest = {
        x = -22371.015625,
        y = 100115.5859375,
        z = 2519.3955078125,
    },
    travel1dest = {
        x = -21320.673828125,
        y = -18233.11328125,
        z = 1179.0317382813,
    },
    travel1destrot = {
        z = 0,
    },
}
,	{
    travel1destcellname = "Balmora, Guild of Mages",
    travel2dest = {
        x = 3.5649647712708,
        y = 1393.2602539063,
        z = -390.19973754883,
    },
    travel2destrot = {
        z = 3.1415927410126,
    },
    travel2destcellname = "Vivec, Guild of Mages",
    ID = "erranil",
    travel3destrot = {
        z = 0.78539830446243,
    },
    travel3destcellname = "Sadrith Mora, Wolverine Hall: Mage's Guild",
    travel4dest = {
        x = 521.43688964844,
        y = 335.16000366211,
        z = 489.77105712891,
    },
    travel4destrot = {
        z = 1.5707963705063,
    },
    travel4destcellname = "Caldera, Guild of Mages",
    class = "guild guide",
    travel3dest = {
        x = -30.27954864502,
        y = 212.14183044434,
        z = 158.23793029785,
    },
    travel1dest = {
        x = -755.89660644531,
        y = -1002.7326660156,
        z = -644.62786865234,
    },
    travel1destrot = {
        z = 0.78539818525314,
    },
}
,	{
    travel1destcellname = "Ald-ruhn",
    travel2dest = {
        x = -22369.431640625,
        y = 100114.109375,
        z = 2523.5871582031,
    },
    travel2destrot = {
        z = 0,
    },
    travel2destcellname = "Maar Gan",
    ID = "punibi yahaz",
    travel3destrot = {
        z = 1.4000000953674,
    },
    travel3destcellname = "Khuul",
    travel4dest = {
        x = -8680.8720703125,
        y = -70138.65625,
        z = 923.29779052734,
    },
    travel4destrot = {
        z = 0.40000000596046,
    },
    travel4destcellname = "Seyda Neen",
    class = "caravaner",
    travel3dest = {
        x = -65875.59375,
        y = 135522.34375,
        z = 1106.4603271484,
    },
    travel1dest = {
        x = -17641.513671875,
        y = 54701.17578125,
        z = 2863.4526367188,
    },
    travel1destrot = {
        z = 1.5707963705063,
    },
}
,	{
    travel1destcellname = "Ald-ruhn, Guild of Mages",
    travel2dest = {
        x = 4.5620331764221,
        y = 1393.7875976563,
        z = -388.10922241211,
    },
    travel2destrot = {
        z = 3.1415927410126,
    },
    travel2destcellname = "Vivec, Guild of Mages",
    ID = "masalinie merian",
    travel3destrot = {
        z = 0.78539830446243,
    },
    travel3destcellname = "Sadrith Mora, Wolverine Hall: Mage's Guild",
    travel4dest = {
        x = 519.82690429688,
        y = 334.84185791016,
        z = 489.20904541016,
    },
    travel4destrot = {
        z = 1.5707963705063,
    },
    travel4destcellname = "Caldera, Guild of Mages",
    class = "guild guide",
    travel3dest = {
        x = -30.27954864502,
        y = 212.14183044434,
        z = 158.23793029785,
    },
    travel1dest = {
        x = 2597.4672851563,
        y = -511.15441894531,
        z = -265.328125,
    },
    travel1destrot = {
        z = 4.7123889923096,
    },
}
,	{
    travel1destcellname = "Ald-ruhn, Guild of Mages",
    travel2dest = {
        x = -755.89660644531,
        y = -1002.7326660156,
        z = -644.62786865234,
    },
    travel2destrot = {
        z = 0.78539818525314,
    },
    travel2destcellname = "Balmora, Guild of Mages",
    ID = "iniel",
    travel3destrot = {
        z = 3.1415927410126,
    },
    travel3destcellname = "Vivec, Guild of Mages",
    travel4dest = {
        x = 525.71350097656,
        y = 334.80548095703,
        z = 490.12701416016,
    },
    travel4destrot = {
        z = 1.5707963705063,
    },
    travel4destcellname = "Caldera, Guild of Mages",
    class = "guild guide",
    travel3dest = {
        x = 3.5204701423645,
        y = 1391.3254394531,
        z = -385.85330200195,
    },
    travel1dest = {
        x = 2592.888671875,
        y = -511.85394287109,
        z = -261.04968261719,
    },
    travel1destrot = {
        z = 4.7123889923096,
    },
}
,	{
    travel1destcellname = "Ebonheart",
    travel2dest = {
        x = -58674.81640625,
        y = 26485.35546875,
        z = 185.77236938477,
    },
    travel2destrot = {
        z = 4.7123889923096,
    },
    travel2destcellname = "Gnaar Mok",
    ID = "baleni salavel",
    travel3destrot = {
        z = 4.2831859588623,
    },
    travel3destcellname = "Vivec, Foreign Quarter",
    travel4dest = {
        x = 113960.15625,
        y = -61257.7109375,
        z = 761.30969238281,
    },
    travel4destrot = {
        z = 4.7123889923096,
    },
    travel4destcellname = "Molag Mar",
    class = "shipmaster",
    travel3dest = {
        x = 35748.99609375,
        y = -74467.4921875,
        z = 189.10723876953,
    },
    travel1dest = {
        x = 20380.296875,
        y = -102414.1484375,
        z = 183.51322937012,
    },
    travel1destrot = {
        z = 0,
    },
}
,	{
    travel1destcellname = "Vivec, Foreign Quarter",
    travel2dest = {
        x = -48493.7265625,
        y = -39754.04296875,
        z = 187.78486633301,
    },
    travel2destrot = {
        z = 1.4000000953674,
    },
    travel2destcellname = "Hla Oad",
    ID = "nevosi hlan",
    travel3destrot = {
        z = 2.8415930271149,
    },
    travel3destcellname = "Tel Branora",
    travel4dest = {
        x = 141877.859375,
        y = 38637.30859375,
        z = 337.96896362305,
    },
    travel4destrot = {
        z = 3.0831854343414,
    },
    travel4destcellname = "Sadrith Mora",
    class = "shipmaster",
    travel3dest = {
        x = 119148.2578125,
        y = -102117.8359375,
        z = 151.4847869873,
    },
    travel1dest = {
        x = 35751.109375,
        y = -74468.734375,
        z = 189.02146911621,
    },
    travel1destrot = {
        z = 4.283185005188,
    },
}
,	{
    travel1destcellname = "Vivec, Arena",
    travel2dest = {
        x = 28829.267578125,
        y = -76725.4921875,
        z = 157.25335693359,
    },
    travel2destrot = {
        z = 4.7123889923096,
    },
    travel2destcellname = "Vivec, Foreign Quarter",
    ID = "aren maren",
    travel3destrot = {
        z = 3.1415927410126,
    },
    travel3destcellname = "Vivec, Temple",
    class = "gondolier",
    travel3dest = {
        x = 30127.568359375,
        y = -98356.5546875,
        z = 172.53834533691,
    },
    travel1dest = {
        x = 33022.4609375,
        y = -88001.4453125,
        z = 132.4416809082,
    },
    travel1destrot = {
        z = 3.1415927410126,
    },
}
,	{
    travel1destcellname = "Vos",
    travel2dest = {
        x = 106924.6796875,
        y = 117168.7578125,
        z = 263.70416259766,
    },
    travel2destrot = {
        z = 0.60000002384186,
    },
    travel2destcellname = "Tel Mora",
    ID = "daynas darys",
    travel3destrot = {
        z = 3.1415927410126,
    },
    travel3destcellname = "Dagon Fel",
    class = "shipmaster",
    travel3dest = {
        x = 62677.796875,
        y = 184289.765625,
        z = 186.23698425293,
    },
    travel1dest = {
        x = 100663.21875,
        y = 114038.5078125,
        z = 254.08958435059,
    },
    travel1destrot = {
        z = 3.8831851482391,
    },
}
,	{
    travel1destcellname = "Sadrith Mora",
    travel2dest = {
        x = 62677.7421875,
        y = 184290.25,
        z = 186.34564208984,
    },
    travel2destrot = {
        z = 3.1415927410126,
    },
    travel2destcellname = "Dagon Fel",
    ID = "tonas telvani",
    travel3destrot = {
        z = 3.8831861019135,
    },
    travel3destcellname = "Vos",
    travel4dest = {
        x = 123304.71875,
        y = 41165.21875,
        z = 178.39712524414,
    },
    travel4destrot = {
        z = 0.90000009536743,
    },
    travel4destcellname = "Tel Aruhn",
    class = "shipmaster",
    travel3dest = {
        x = 100663.640625,
        y = 114037.3046875,
        z = 255.47074890137,
    },
    travel1dest = {
        x = 141874.3125,
        y = 38605.59765625,
        z = 326.82119750977,
    },
    travel1destrot = {
        z = 3.1415927410126,
    },
}
,	{
    travel1destcellname = "",
    class = "pauper",
    ID = "blatta hateria",
    travel1dest = {
        x = 160255.09375,
        y = -36135.1640625,
        z = 168.10514831543,
    },
    travel1destrot = {
        z = 0,
    },
}
,	{
    travel1destcellname = "Ebonheart",
    class = "monk",
    ID = "vevrana aryon",
    travel1dest = {
        x = 20426.11328125,
        y = -101409.0703125,
        z = 162.68621826172,
    },
    travel1destrot = {
        z = 3.1415927410126,
    },
}
,	{
    travel1destcellname = "Ald-ruhn, Guild of Mages",
    travel2dest = {
        x = -755.89660644531,
        y = -1002.7326660156,
        z = -644.62786865234,
    },
    travel2destrot = {
        z = 0.78539818525314,
    },
    travel2destcellname = "Balmora, Guild of Mages",
    ID = "flacassia fauseius",
    travel3destrot = {
        z = 0.78539830446243,
    },
    travel3destcellname = "Sadrith Mora, Wolverine Hall: Mage's Guild",
    travel4dest = {
        x = 523.16333007813,
        y = 335.72705078125,
        z = 487.87213134766,
    },
    travel4destrot = {
        z = 1.5707963705063,
    },
    travel4destcellname = "Caldera, Guild of Mages",
    class = "guild guide",
    travel3dest = {
        x = -30.27954864502,
        y = 212.14183044434,
        z = 158.23793029785,
    },
    travel1dest = {
        x = 2597.3198242188,
        y = -509.36541748047,
        z = -264.27572631836,
    },
    travel1destrot = {
        z = 4.7123889923096,
    },
}
,	{
    travel1destcellname = "Ald-ruhn",
    travel2dest = {
        x = -65882.90625,
        y = 135516.078125,
        z = 1111.1691894531,
    },
    travel2destrot = {
        z = 1.3707963228226,
    },
    travel2destcellname = "Khuul",
    ID = "daras aryon",
    travel3destrot = {
        z = 0,
    },
    travel3destcellname = "Gnisis",
    class = "caravaner",
    travel3dest = {
        x = -86779.1328125,
        y = 89453.34375,
        z = 1126.5556640625,
    },
    travel1dest = {
        x = -17642.2265625,
        y = 54701.21875,
        z = 2863.6860351563,
    },
    travel1destrot = {
        z = 1.5707963705063,
    },
}
,	{
    travel1destcellname = "Vivec, Arena",
    travel2dest = {
        x = 22611.46484375,
        y = -87935.921875,
        z = 107.37586212158,
    },
    travel2destrot = {
        z = 1.5707963705063,
    },
    travel2destcellname = "Vivec, Hlaalu",
    ID = "devas irano",
    travel3destrot = {
        z = 1.5707963705063,
    },
    travel3destcellname = "Vivec, Telvanni",
    class = "gondolier",
    travel3dest = {
        x = 42594.2265625,
        y = -87906.078125,
        z = 145.7484588623,
    },
    travel1dest = {
        x = 33020.7109375,
        y = -87971.4453125,
        z = 126.42379760742,
    },
    travel1destrot = {
        z = 3.1415927410126,
    },
}
,	{
    travel1destcellname = "Vivec, Arena",
    travel2dest = {
        x = 28829.505859375,
        y = -76725.1640625,
        z = 157.19631958008,
    },
    travel2destrot = {
        z = 4.7123889923096,
    },
    travel2destcellname = "Vivec, Foreign Quarter",
    ID = "fendryn drelvi",
    travel3destrot = {
        z = 3.1415927410126,
    },
    travel3destcellname = "Vivec, Temple",
    class = "gondolier",
    travel3dest = {
        x = 30125.87109375,
        y = -98353.5625,
        z = 174.67755126953,
    },
    travel1dest = {
        x = 33018.17578125,
        y = -87911.859375,
        z = 143.1452331543,
    },
    travel1destrot = {
        z = 3.1415927410126,
    },
}
,	{
    travel1destcellname = "Vivec, Arena",
    travel2dest = {
        x = 22611.78515625,
        y = -87934.03125,
        z = 98.41487121582,
    },
    travel2destrot = {
        z = 1.5707963705063,
    },
    travel2destcellname = "Vivec, Hlaalu",
    ID = "talsi uvayn",
    travel3destrot = {
        z = 1.5707963705063,
    },
    travel3destcellname = "Vivec, Telvanni",
    class = "gondolier",
    travel3dest = {
        x = 42593.98828125,
        y = -87906.4921875,
        z = 146.88505554199,
    },
    travel1dest = {
        x = 33040.21484375,
        y = -87932.1328125,
        z = 109.70626831055,
    },
    travel1destrot = {
        z = 3.1415927410126,
    },
}
,	{
    travel1destcellname = "Vivec, Temple",
    travel2dest = {
        x = 42593.8125,
        y = -87905.5234375,
        z = 144.33647155762,
    },
    travel2destrot = {
        z = 1.5707963705063,
    },
    travel2destcellname = "Vivec, Telvanni",
    ID = "dalse adren",
    travel3destrot = {
        z = 4.7123889923096,
    },
    travel3destcellname = "Vivec, Foreign Quarter",
    travel4dest = {
        x = 22613.068359375,
        y = -87935.859375,
        z = 105.25735473633,
    },
    travel4destrot = {
        z = 1.5707963705063,
    },
    travel4destcellname = "Vivec, Hlaalu",
    class = "gondolier",
    travel3dest = {
        x = 28828.943359375,
        y = -76727.0078125,
        z = 154.32467651367,
    },
    travel1dest = {
        x = 30125.951171875,
        y = -98355.6171875,
        z = 173.44982910156,
    },
    travel1destrot = {
        z = 3.1415927410126,
    },
}
,	{
    travel1destcellname = "Balmora",
    travel2dest = {
        x = -8680.6005859375,
        y = -70135.7890625,
        z = 919.59393310547,
    },
    travel2destrot = {
        z = 0.38539817929268,
    },
    travel2destcellname = "Seyda Neen",
    ID = "folsi thendas",
    travel3destrot = {
        z = 4.7123889923096,
    },
    travel3destcellname = "Vivec",
    travel4dest = {
        x = 103449.015625,
        y = -58402.7890625,
        z = 1545.5377197266,
    },
    travel4destrot = {
        z = 1.200000166893,
    },
    travel4destcellname = "Molag Mar",
    class = "caravaner",
    travel3dest = {
        x = 32206.376953125,
        y = -72225.1171875,
        z = 1006.6583251953,
    },
    travel1dest = {
        x = -21322.697265625,
        y = -18234.54296875,
        z = 1183.2424316406,
    },
    travel1destrot = {
        z = 0,
    },
}
,	{
    travel1destcellname = "Tel Mora",
    travel2dest = {
        x = 141870.90625,
        y = 38621.2421875,
        z = 331.33755493164,
    },
    travel2destrot = {
        z = 3.1415927410126,
    },
    travel2destcellname = "Sadrith Mora",
    ID = "haema farseer",
    travel3destrot = {
        z = 3.04159283638,
    },
    travel3destcellname = "Khuul",
    travel4dest = {
        x = 123303.90625,
        y = 41164.4609375,
        z = 182.47305297852,
    },
    travel4destrot = {
        z = 0.90000009536743,
    },
    travel4destcellname = "Tel Aruhn",
    class = "shipmaster",
    travel3dest = {
        x = -69427.671875,
        y = 142115.75,
        z = 192.24974060059,
    },
    travel1dest = {
        x = 106921.359375,
        y = 117169.125,
        z = 263.35888671875,
    },
    travel1destrot = {
        z = 0.60000002384186,
    },
}
,	{
    travel1destcellname = "Sadrith Mora",
    travel2dest = {
        x = 123303.8984375,
        y = 41163.8984375,
        z = 180.35557556152,
    },
    travel2destrot = {
        z = 0.90000009536743,
    },
    travel2destcellname = "Tel Aruhn",
    ID = "sedyni veran",
    travel3destrot = {
        z = 0.59999996423721,
    },
    travel3destcellname = "Tel Mora",
    class = "shipmaster",
    travel3dest = {
        x = 106924.5546875,
        y = 117169.296875,
        z = 263.70651245117,
    },
    travel1dest = {
        x = 141876.953125,
        y = 38613.12109375,
        z = 325.00564575195,
    },
    travel1destrot = {
        z = 3.1004178524017,
    },
}
,	{
    travel1destcellname = "Tel Branora",
    travel2dest = {
        x = 20362.787109375,
        y = -102424.5,
        z = 185.27079772949,
    },
    travel2destrot = {
        z = 0,
    },
    travel2destcellname = "Ebonheart",
    ID = "gals arethi",
    travel3destrot = {
        z = 0.60000002384186,
    },
    travel3destcellname = "Tel Mora",
    travel4dest = {
        x = 62681.5078125,
        y = 184288.640625,
        z = 188.39826965332,
    },
    travel4destrot = {
        z = 3.1415927410126,
    },
    travel4destcellname = "Dagon Fel",
    class = "shipmaster",
    travel3dest = {
        x = 106927.875,
        y = 117172.4140625,
        z = 262.775390625,
    },
    travel1dest = {
        x = 119153.3984375,
        y = -102116.171875,
        z = 159.79312133789,
    },
    travel1destrot = {
        z = 2.7831857204437,
    },
}
,	{
    travel1destcellname = "Khuul",
    travel2dest = {
        x = -48492.96875,
        y = -39756.79296875,
        z = 187.18106079102,
    },
    class = "shipmaster",
    travel2destcellname = "Hla Oad",
    ID = "valveli arelas",
    travel2destrot = {
        z = 1.3707963228226,
    },
    travel1dest = {
        x = -69428.7890625,
        y = 142115.71875,
        z = 195.14447021484,
    },
    travel1destrot = {
        z = 3.0415921211243,
    },
}
,	{
    travel1destcellname = "Balmora",
    travel2dest = {
        x = 32207.21484375,
        y = -72223.8046875,
        z = 1006.4372558594,
    },
    travel2destrot = {
        z = 4.7123889923096,
    },
    travel2destcellname = "Vivec",
    ID = "darvame hleran",
    travel3destrot = {
        z = 3.1415927410126,
    },
    travel3destcellname = "Suran",
    travel4dest = {
        x = -86786.09375,
        y = 89452.0703125,
        z = 1130.6611328125,
    },
    travel4destrot = {
        z = 0,
    },
    travel4destcellname = "Gnisis",
    class = "caravaner",
    travel3dest = {
        x = 53158.79296875,
        y = -48228.828125,
        z = 984.13787841797,
    },
    travel1dest = {
        x = -21318.732421875,
        y = -18232.40625,
        z = 1177.6635742188,
    },
    travel1destrot = {
        z = 0,
    },
}
,	{
    travel1destcellname = "Ald-ruhn",
    travel2dest = {
        x = -8681.427734375,
        y = -70136.1015625,
        z = 919.93927001953,
    },
    travel2destrot = {
        z = 0.40000000596046,
    },
    travel2destcellname = "Seyda Neen",
    ID = "selvil sareloth",
    travel3destrot = {
        z = 3.1415927410126,
    },
    travel3destcellname = "Suran",
    travel4dest = {
        x = 32206.884765625,
        y = -72222.421875,
        z = 1004.6455688477,
    },
    travel4destrot = {
        z = 4.7123889923096,
    },
    travel4destcellname = "Vivec",
    class = "caravaner",
    travel3dest = {
        x = 53159.55078125,
        y = -48228.60546875,
        z = 984.13787841797,
    },
    travel1dest = {
        x = -17642.642578125,
        y = 54699.1484375,
        z = 2865.9157714844,
    },
    travel1destrot = {
        z = 1.5707963705063,
    },
}
,	{
    travel1destcellname = "Suran",
    travel2dest = {
        x = 32207.0078125,
        y = -72224.5859375,
        z = 1007.1208496094,
    },
    class = "caravaner",
    travel2destcellname = "Vivec",
    ID = "dilami androm",
    travel2destrot = {
        z = 4.7123889923096,
    },
    travel1dest = {
        x = 53162,
        y = -48230.25,
        z = 984.13787841797,
    },
    travel1destrot = {
        z = 3.1415927410126,
    },
}
,	{
    travel1destcellname = "Vivec, Foreign Quarter",
    travel2dest = {
        x = -48492.66796875,
        y = -39754.5234375,
        z = 187.12548828125,
    },
    travel2destrot = {
        z = 1.4000000953674,
    },
    travel2destcellname = "Hla Oad",
    ID = "rindral dralor",
    travel3destrot = {
        z = 2.7831861972809,
    },
    travel3destcellname = "Tel Branora",
    class = "shipmaster",--normally rogue but for all intents this NPC is a shipmaster
    travel3dest = {
        x = 119153.2109375,
        y = -102118.265625,
        z = 155.02291870117,
    },
    travel1dest = {
        x = 35752.44140625,
        y = -74468.7109375,
        z = 190.27174377441,
    },
    travel1destrot = {
        z = 4.3123893737793,
    },
}
,	{
    travel1destcellname = "Seyda Neen",
    travel2dest = {
        x = 53161.16015625,
        y = -48229.4765625,
        z = 984.13787841797,
    },
    travel2destrot = {
        z = 3.1415927410126,
    },
    travel2destcellname = "Suran",
    ID = "adondasi sadalvel",
    travel3destrot = {
        z = 1.2000008821487,
    },
    travel3destcellname = "Molag Mar",
    travel4dest = {
        x = -21318.51171875,
        y = -18232.849609375,
        z = 1180.8386230469,
    },
    travel4destrot = {
        z = 0,
    },
    travel4destcellname = "Balmora",
    class = "caravaner",
    travel3dest = {
        x = 103448.5234375,
        y = -58400.91015625,
        z = 1547.8693847656,
    },
    travel1dest = {
        x = -8681.26953125,
        y = -70133.8046875,
        z = 918.23663330078,
    },
    travel1destrot = {
        z = 0.38539817929268,
    },
}
,	{
    travel1destcellname = "Maar Gan",
    travel2dest = {
        x = -17640.619140625,
        y = 54698.7578125,
        z = 2866.861328125,
    },
    travel2destrot = {
        z = 1.5707963705063,
    },
    travel2destcellname = "Ald-ruhn",
    ID = "seldus nerendus",
    travel3destrot = {
        z = 0,
    },
    travel3destcellname = "Gnisis",
    class = "caravaner",
    travel3dest = {
        x = -86780.328125,
        y = 89454.15625,
        z = 1125.2220458984,
    },
    travel1dest = {
        x = -22370.8515625,
        y = 100115.140625,
        z = 2520.1323242188,
    },
    travel1destrot = {
        z = 0,
    },
}
,	{
    travel1destcellname = "Balmora, Guild of Mages",
    travel2dest = {
        x = 2594.1879882813,
        y = -509.68878173828,
        z = -267.58639526367,
    },
    travel2destrot = {
        z = 4.7123889923096,
    },
    travel2destcellname = "Ald-ruhn, Guild of Mages",
    ID = "emelia duronia",
    travel3destrot = {
        z = 0.78539830446243,
    },
    travel3destcellname = "Sadrith Mora, Wolverine Hall: Mage's Guild",
    travel4dest = {
        x = 0.17864418029785,
        y = 1392.8215332031,
        z = -385.92874145508,
    },
    travel4destrot = {
        z = 3.1415927410126,
    },
    travel4destcellname = "Vivec, Guild of Mages",
    class = "guild guide",
    travel3dest = {
        x = -31.409912109375,
        y = 212.6812286377,
        z = 159.84870910645,
    },
    travel1dest = {
        x = -754.6630859375,
        y = -1006.1605224609,
        z = -640.23468017578,
    },
    travel1destrot = {
        z = 0.78539818525314,
    },
}
,	{
    travel1destcellname = "Gnaar Mok",
    travel2dest = {
        x = 62679.16015625,
        y = 184288.875,
        z = 185.83993530273,
    },
    class = "shipmaster",
    travel2destcellname = "Dagon Fel",
    ID = "talmeni drethan",
    travel2destrot = {
        z = 3.1415927410126,
    },
    travel1dest = {
        x = -58679.2109375,
        y = 26485.939453125,
        z = 190.11242675781,
    },
    travel1destrot = {
        z = 4.7123889923096,
    },
}
,	{
    travel1destcellname = "Vivec, Foreign Quarter",
    travel2dest = {
        x = 113948.6015625,
        y = -61251.453125,
        z = 755.29040527344,
    },
    travel2destrot = {
        z = 4.7123889923096,
    },
    travel2destcellname = "Molag Mar",
    ID = "nireli farys",
    travel3destrot = {
        z = 3.08318567276,
    },
    travel3destcellname = "Sadrith Mora",
    travel4dest = {
        x = 20361.34375,
        y = -102425.2578125,
        z = 182.35130310059,
    },
    travel4destrot = {
        z = 0,
    },
    travel4destcellname = "Ebonheart",
    class = "shipmaster",
    travel3dest = {
        x = 141880.21875,
        y = 38646.4453125,
        z = 315.29415893555,
    },
    travel1dest = {
        x = 35750.6484375,
        y = -74467.5625,
        z = 190.87222290039,
    },
    travel1destrot = {
        z = 4.2831864356995,
    },
}
,	{
    travel1destcellname = "Hla Oad",
    travel2dest = {
        x = 20377.666015625,
        y = -102406.234375,
        z = 187.52168273926,
    },
    travel2destrot = {
        z = 0,
    },
    travel2destcellname = "Ebonheart",
    ID = "ano andaram",
    travel3destrot = {
        z = 4.7123889923096,
    },
    travel3destcellname = "Molag Mar",
    travel4dest = {
        x = 119149.921875,
        y = -102117.046875,
        z = 158.76449584961,
    },
    travel4destrot = {
        z = 2.7853980064392,
    },
    travel4destcellname = "Tel Branora",
    class = "shipmaster",
    travel3dest = {
        x = 113965.0078125,
        y = -61251.92578125,
        z = 766.67694091797,
    },
    travel1dest = {
        x = -48489.703125,
        y = -39754.9296875,
        z = 181.71173095703,
    },
    travel1destrot = {
        z = 1.3707963228226,
    },
}
,	{
    travel1destcellname = "Fort Frostmoth",
    class = "shipmaster",
    ID = "s'virr",
    travel1dest = {
        x = -174024.390625,
        y = 136823.953125,
        z = 457.66833496094,
    },
    travel1destrot = {
        z = 4.6831865310669,
    },
}
,	{
    travel1destcellname = "Khuul",
    class = "shipmaster",
    ID = "wind_in_his_hair",
    travel1dest = {
        x = -69200.7265625,
        y = 142117.5625,
        z = 214.0786895752,
    },
    travel1destrot = {
        z = 3.0831880569458,
    },
}
,	{
    travel1destcellname = "Khuul",
    travel2dest = {
        x = -199408.5625,
        y = 157218.90625,
        z = 435.13116455078,
    },
    class = "shipmaster",
    travel2destcellname = "Raven Rock",
    ID = "basks_in_the_sun",
    travel2destrot = {
        z = 5.7663741111755,
    },
    travel1dest = {
        x = -69200.7265625,
        y = 142117.5625,
        z = 214.0786895752,
    },
    travel1destrot = {
        z = 3.0831880569458,
    },
}
,	{
    travel1destcellname = "Fort Frostmoth",
    class = "shipmaster",
    ID = "veresa alver",
    travel1dest = {
        x = -174016,
        y = 136704,
        z = 448,
    },
    travel1destrot = {
        z = 4.7000012397766,
    },
}
,	{
    travel1destcellname = "Firewatch",
    travel2dest = {
        x = 205096,
        y = 11360,
        z = 259.92486572266,
    },
    travel2destrot = {
        z = 0.69813168048859,
    },
    travel2destcellname = "Helnim",
    ID = "tr_m0_anedhil",
    travel3destrot = {
        z = 2.181661605835,
    },
    travel3destcellname = "Marog",
    class = "shipmaster",
    travel3dest = {
        x = 191512,
        y = -8640,
        z = 445.47116088867,
    },
    travel1dest = {
        x = 141976,
        y = 125432,
        z = 96.635330200195,
    },
    travel1destrot = {
        z = 3.141592502594,
    },
}
,	{
    travel1destcellname = "Old Ebonheart, Docks",
    travel2dest = {
        x = -24872,
        y = -107512,
        z = 129.7115020752,
    },
    class = "shipmaster",
    travel2destcellname = "Teyn",
    ID = "tr_m0_domiah",
    travel2destrot = {
        z = 4.7123889923096,
    },
    travel1dest = {
        x = 60856,
        y = -144544,
        z = 418.2887878418,
    },
    travel1destrot = {
        z = 1.570796251297,
    },
}
,	{
    travel1destcellname = "Andothren, Docks",
    travel2dest = {
        x = 181056,
        y = -140672,
        z = 203.51274108887,
    },
    travel2destrot = {
        z = 2.3561944961548,
    },
    travel2destcellname = "Darvonis",
    ID = "tr_m0_gindrala nethri",
    travel3destrot = {
        z = 1.570796251297,
    },
    travel3destcellname = "Old Ebonheart, Docks",
    class = "shipmaster",
    travel3dest = {
        x = 60856,
        y = -144544,
        z = 418.2887878418,
    },
    travel1dest = {
        x = 3848,
        y = -123960,
        z = 181.99993896484,
    },
    travel1destrot = {
        z = 4.0142569541931,
    },
}
,	{
    travel1destcellname = "Firewatch, Guild of Mages",
    travel2dest = {
        x = 4728,
        y = 3336,
        z = 15312.099609375,
    },
    class = "guild guide",
    travel2destcellname = "Firewatch, Guild of Mages",
    ID = "tr_m0_ohmonir",
    travel2destrot = {
        z = 5.4977869987488,
    },
    travel1dest = {
        x = 5432,
        y = 2720,
        z = 10672.624023438,
    },
    travel1destrot = {
        z = 3.9269907474518,
    },
}
,	{
    travel1destcellname = "Ebonheart",
    travel2dest = {
        x = -48502.00390625,
        y = -39732.98828125,
        z = 160.72436523438,
    },
    class = "shipmaster",
    travel2destcellname = "Hla Oad",
    ID = "tr_m0_sentius_veros",
    travel2destrot = {
        z = 1.3000000715256,
    },
    travel1dest = {
        x = 20375.66796875,
        y = -102426.265625,
        z = 152.78131103516,
    },
    travel1destrot = {
        z = 0,
    },
}
,	{
    travel1destcellname = "Firewatch",
    travel2dest = {
        x = 98840,
        y = 229048,
        z = 170.2887878418,
    },
    class = "shipmaster",
    travel2destcellname = "Nivalis",
    ID = "tr_m0_ysmund",
    travel2destrot = {
        z = 3.141592502594,
    },
    travel1dest = {
        x = 141976,
        y = 125432,
        z = 96.635330200195,
    },
    travel1destrot = {
        z = 3.141592502594,
    },
}
,	{
    travel1destcellname = "Llothanis",
    travel2dest = {
        x = 341602.5625,
        y = 129572.484375,
        z = 219.86480712891,
    },
    class = "t_mw_riverstriderservice",
    travel2destcellname = "Port Telvannis",
    ID = "tr_m1_aamunos_rolvar",
    travel2destrot = {
        z = 5.8331842422485,
    },
    travel1dest = {
        x = 274464.46875,
        y = 82058.6328125,
        z = 163.95233154297,
    },
    travel1destrot = {
        z = 4.273184299469,
    },
}
,	{
    travel1destcellname = "Firewatch, Guild of Mages",
    travel2dest = {
        x = 4776,
        y = 3520,
        z = 12500.841796875,
    },
    class = "guild guide",
    travel2destcellname = "Firewatch, Guild of Mages",
    ID = "tr_m1_dagmund",
    travel2destrot = {
        z = 6.1086521148682,
    },
    travel1dest = {
        x = 5432,
        y = 2720,
        z = 10672.624023438,
    },
    travel1destrot = {
        z = 3.9269907474518,
    },
}
,	{
    travel1destcellname = "Tel Ouada",
    travel2dest = {
        x = 341594.5,
        y = 129565.109375,
        z = 217.99029541016,
    },
    travel2destrot = {
        z = 5.8331842422485,
    },
    travel2destcellname = "Port Telvannis",
    ID = "tr_m1_dedave_atherayn",
    travel3destrot = {
        z = 3.0997047424316,
    },
    travel3destcellname = "Alt Bosara",
    class = "t_mw_riverstriderservice",
    travel3dest = {
        x = 301842.46875,
        y = -28938.35546875,
        z = 597.76000976563,
    },
    travel1dest = {
        x = 205348.578125,
        y = 153361.203125,
        z = 113.8833770752,
    },
    travel1destrot = {
        z = 1.6499998569489,
    },
}
,	{
    travel1destcellname = "Llothanis",
    travel2dest = {
        x = 205352.453125,
        y = 153357.78125,
        z = 123.89015960693,
    },
    class = "t_mw_riverstriderservice",
    travel2destcellname = "Tel Ouada",
    ID = "tr_m1_dolmse_andala",
    travel2destrot = {
        z = 1.6800000667572,
    },
    travel1dest = {
        x = 274478.75,
        y = 82055.3671875,
        z = 168.68196105957,
    },
    travel1destrot = {
        z = 4.2431855201721,
    },
}
,	{
    travel1destcellname = "Bal Oyra",
    class = "shipmaster",
    ID = "tr_m1_dunveri_rodran",
    travel1dest = {
        x = 151520,
        y = 203328,
        z = 144.8196105957,
    },
    travel1destrot = {
        z = 3.3161253929138,
    },
}
,	{
    travel1destcellname = "Gah Sadrith",
    travel2dest = {
        x = 296209.375,
        y = -30580.90234375,
        z = 186.32763671875,
    },
    class = "shipmaster",
    travel2destcellname = "Alt Bosara",
    ID = "tr_m1_erendas_senatam",
    travel2destrot = {
        z = 2.0000002384186,
    },
    travel1dest = {
        x = 343092.75,
        y = 110900.375,
        z = 201.52502441406,
    },
    travel1destrot = {
        z = 1.4000000953674,
    },
}
,	{
    travel1destcellname = "Gah Sadrith",
    travel2dest = {
        x = 281907.78125,
        y = 146963.515625,
        z = 396.62884521484,
    },
    class = "t_mw_riverstriderservice",
    travel2destcellname = "Sadas Plantation",
    ID = "tr_m1_gadam_tiren",
    travel2destrot = {
        z = 1.289999961853,
    },
    travel1dest = {
        x = 343215.84375,
        y = 110100.828125,
        z = 177.06634521484,
    },
    travel1destrot = {
        z = 0.7199998497963,
    },
}
,	{
    travel1destcellname = "Bahrammu",
    travel2dest = {
        x = 151520,
        y = 203328,
        z = 144,
    },
    travel2destrot = {
        z = 3.3161253929138,
    },
    travel2destcellname = "Bal Oyra",
    ID = "tr_m1_ilnori_pelelius",
    travel3destrot = {
        z = 3.141592502594,
    },
    travel3destcellname = "Dagon Fel",
    travel4dest = {
        x = 141976,
        y = 125432,
        z = 96.635345458984,
    },
    travel4destrot = {
        z = 3.141592502594,
    },
    travel4destcellname = "Firewatch",
    class = "shipmaster",
    travel3dest = {
        x = 62680,
        y = 184288,
        z = 161.71153259277,
    },
    travel1dest = {
        x = 124920,
        y = 205040,
        z = 136.96051025391,
    },
    travel1destrot = {
        z = 1.1344640254974,
    },
}
,	{
    travel1destcellname = "Bal Oyra",
    travel2dest = {
        x = 98840,
        y = 229048,
        z = 170.2887878418,
    },
    class = "shipmaster",
    travel2destcellname = "Nivalis",
    ID = "tr_m1_marthen redri",
    travel2destrot = {
        z = 3.141592502594,
    },
    travel1dest = {
        x = 151520,
        y = 203328,
        z = 144.8196105957,
    },
    travel1destrot = {
        z = 3.3161253929138,
    },
}
,	{
    travel1destcellname = "Tel Ouada",
    travel2dest = {
        x = 219163.0625,
        y = 13019.7421875,
        z = 1051.0202636719,
    },
    class = "caravaner",
    travel2destcellname = "Tel Gilan",
    ID = "tr_m1_milara_selenoth",
    travel2destrot = {
        z = 5.08318567276,
    },
    travel1dest = {
        x = 208250.578125,
        y = 152888.625,
        z = 961.73388671875,
    },
    travel1destrot = {
        z = 3.1999995708466,
    },
}
,	{
    travel1destcellname = "Port Telvannis",
    class = "t_mw_riverstriderservice",
    ID = "tr_m1_mordinara_valethi",
    travel1dest = {
        x = 346559.25,
        y = 133050.234375,
        z = 209.205078125,
    },
    travel1destrot = {
        z = 5.1431851387024,
    },
}
,	{
    travel1destcellname = "Llothanis",
    class = "shipmaster",
    ID = "tr_m1_nuleno_nethri",
    travel1dest = {
        x = 274044.25,
        y = 82122.4765625,
        z = 178.56449890137,
    },
    travel1destrot = {
        z = 5.2831859588623,
    },
}
,	{
    travel1destcellname = "Helnim, Guild of Mages",
    travel2dest = {
        x = 4144,
        y = 3424,
        z = 15328.127929688,
    },
    class = "guild guide",
    travel2destcellname = "Helnim, Guild of Mages",
    ID = "tr_m1_soril",
    travel2destrot = {
        z = 1.570796251297,
    },
    travel1dest = {
        x = 4776,
        y = 3520,
        z = 12500.841796875,
    },
    travel1destrot = {
        z = 6.1086521148682,
    },
}
,	{
    travel1destcellname = "Bahrammu",
    travel2dest = {
        x = 98840,
        y = 229048,
        z = 170.2887878418,
    },
    travel2destrot = {
        z = 3.141592502594,
    },
    travel2destcellname = "Nivalis",
    ID = "tr_m1_tandryen_reyas",
    travel3destrot = {
        z = 2.4434609413147,
    },
    travel3destcellname = "Tel Ouada",
    class = "shipmaster",
    travel3dest = {
        x = 202530.484375,
        y = 151870.5,
        z = 200.82730102539,
    },
    travel1dest = {
        x = 124920,
        y = 205040,
        z = 136.96051025391,
    },
    travel1destrot = {
        z = 1.1344640254974,
    },
}
,	{
    travel1destcellname = "Ranyon-ruhn",
    class = "caravaner",
    ID = "tr_m1_varusha caril",
    travel1dest = {
        x = 228074,
        y = 98628.8359375,
        z = 2034.2958984375,
    },
    travel1destrot = {
        z = 5.235987663269,
    },
}
,	{
    travel1destcellname = "Dagon Fel",
    travel2dest = {
        x = 205096,
        y = 11360,
        z = 259.92486572266,
    },
    travel2destrot = {
        z = 0.69813168048859,
    },
    travel2destcellname = "Helnim",
    ID = "tr_m1_virevar_tilvayn",
    travel3destrot = {
        z = 3.141592502594,
    },
    travel3destcellname = "Nivalis",
    travel4dest = {
        x = 143272,
        y = 38112,
        z = 179.38549804688,
    },
    travel4destrot = {
        z = 4.1887903213501,
    },
    travel4destcellname = "Sadrith Mora",
    class = "shipmaster",
    travel3dest = {
        x = 98840,
        y = 229048,
        z = 170.2887878418,
    },
    travel1dest = {
        x = 62680,
        y = 184288,
        z = 161.71151733398,
    },
    travel1destrot = {
        z = 3.141592502594,
    },
}
,	{
    travel1destcellname = "Port Telvannis",
    class = "t_mw_riverstriderservice",
    ID = "tr_m1_yugil_nethri",
    travel1dest = {
        x = 346555.90625,
        y = 133042.09375,
        z = 207.31455993652,
    },
    travel1destrot = {
        z = 5.2331857681274,
    },
}
,	{
    travel1destcellname = "Darvonis",
    travel2dest = {
        x = 141976,
        y = 125432,
        z = 96.635330200195,
    },
    travel2destrot = {
        z = 3.141592502594,
    },
    travel2destcellname = "Firewatch",
    ID = "tr_m2_derana llenam",
    travel3destrot = {
        z = 2.181661605835,
    },
    travel3destcellname = "Marog",
    travel4dest = {
        x = 141880.21875,
        y = 38646.4453125,
        z = 315.29415893555,
    },
    travel4destrot = {
        z = 3.08318567276,
    },
    travel4destcellname = "Sadrith Mora",
    class = "shipmaster",
    travel3dest = {
        x = 191512,
        y = -8640,
        z = 418.07727050781,
    },
    travel1dest = {
        x = 181056,
        y = -140672,
        z = 203.51274108887,
    },
    travel1destrot = {
        z = 2.3561944961548,
    },
}
,	{
    travel1destcellname = "Necrom",
    travel2dest = {
        x = 310002.4375,
        y = -129668.3984375,
        z = 1153.8256835938,
    },
    travel2destrot = {
        z = 5.4831862449646,
    },
    travel2destcellname = "Sailen",
    ID = "tr_m2_dravil bradyn",
    travel3destrot = {
        z = 2.2561945915222,
    },
    travel3destcellname = "Tel Muthada",
    class = "caravaner",
    travel3dest = {
        x = 221232,
        y = -37504,
        z = 3056,
    },
    travel1dest = {
        x = 344520.90625,
        y = -93361.6015625,
        z = 1304,
    },
    travel1destrot = {
        z = 2.0000002384186,
    },
}
,	{
    travel1destcellname = "Firewatch, Guild of Mages",
    travel2dest = {
        x = 4144,
        y = 3424,
        z = 15328.127929688,
    },
    class = "guild guide",
    travel2destcellname = "Firewatch, Guild of Mages",
    ID = "tr_m2_garath benaque",
    travel2destrot = {
        z = 1.570796251297,
    },
    travel1dest = {
        x = 5432,
        y = 2720,
        z = 10672.624023438,
    },
    travel1destrot = {
        z = 3.9269907474518,
    },
}
,	{
    travel1destcellname = "Necrom, Waterfront",
    travel2dest = {
        x = 274426.6875,
        y = 82046.5703125,
        z = 155.90798950195,
    },
    class = "shipmaster",
    travel2destcellname = "Llothanis",
    ID = "tr_m2_hlavora_gilnith",
    travel2destrot = {
        z = 4.5431861877441,
    },
    travel1dest = {
        x = 347178.875,
        y = -76228.703125,
        z = 336,
    },
    travel1destrot = {
        z = 2.3561944961548,
    },
}
,	{
    travel1destcellname = "Tel Mothrivra",
    travel2dest = {
        x = 274467.75,
        y = 82053.4296875,
        z = 169.78799438477,
    },
    class = "t_mw_riverstriderservice",
    travel2destcellname = "Llothanis",
    ID = "tr_m2_masalmalu_mendas",
    travel2destrot = {
        z = 4.2830381393433,
    },
    travel1dest = {
        x = 271424.84375,
        y = 17983.3359375,
        z = 294.52746582031,
    },
    travel1destrot = {
        z = 1.6000001430511,
    },
}
,	{
    travel1destcellname = "Andothren, Guild of Mages",
    travel2dest = {
        x = 4728,
        y = 3336,
        z = 15312.099609375,
    },
    class = "guild guide",
    travel2destcellname = "Andothren, Guild of Mages",
    ID = "tr_m2_mjara",
    travel2destrot = {
        z = 5.4977869987488,
    },
    travel1dest = {
        x = 7872,
        y = 4264,
        z = 15280.48046875,
    },
    travel1destrot = {
        z = 0,
    },
}
,	{
    travel1destcellname = "Alt Bosara",
    class = "t_mw_riverstriderservice",
    ID = "tr_m2_orvano tralen",
    travel1dest = {
        x = 301842.15625,
        y = -28937.044921875,
        z = 599.39422607422,
    },
    travel1destrot = {
        z = 3.0999991893768,
    },
}
,	{
    travel1destcellname = "Helnim",
    travel2dest = {
        x = 181056,
        y = -140672,
        z = 203.51274108887,
    },
    travel2destrot = {
        z = 2.3561944961548,
    },
    travel2destcellname = "Darvonis",
    ID = "tr_m2_selothril llana",
    travel3destrot = {
        z = 4.1887903213501,
    },
    travel3destcellname = "Sadrith Mora",
    class = "shipmaster",
    travel3dest = {
        x = 143272,
        y = 38112,
        z = 179.38549804688,
    },
    travel1dest = {
        x = 205096,
        y = 11360,
        z = 259.92486572266,
    },
    travel1destrot = {
        z = 0.69813168048859,
    },
}
,	{
    travel1destcellname = "Tel Muthada",
    travel2dest = {
        x = 228075.421875,
        y = 98628.203125,
        z = 2030.2989501953,
    },
    class = "caravaner",
    travel2destcellname = "Ranyon-ruhn",
    ID = "tr_m2_sera bavan",
    travel2destrot = {
        z = 5.235987663269,
    },
    travel1dest = {
        x = 221237.546875,
        y = -37494.73046875,
        z = 3051.1323242188,
    },
    travel1destrot = {
        z = 2.2000000476837,
    },
}
,	{
    travel1destcellname = "Alt Bosara",
    travel2dest = {
        x = 309862.75,
        y = -224734.328125,
        z = 423.47607421875,
    },
    class = "shipmaster",
    travel2destcellname = "Enamor Dayn",
    ID = "tr_m2_tedril nothro",
    travel2destrot = {
        z = 5.0831861495972,
    },
    travel1dest = {
        x = 296220.78125,
        y = -30589.072265625,
        z = 214.45599365234,
    },
    travel1destrot = {
        z = 2.0831868648529,
    },
}
,	{
    travel1destcellname = "Tel Gilan",
    travel2dest = {
        x = 246240,
        y = -91216,
        z = 2592,
    },
    class = "caravaner",
    travel2destcellname = "Akamora",
    ID = "tr_m2_valna sippusoti",
    travel2destrot = {
        z = 1.9999998807907,
    },
    travel1dest = {
        x = 219164.625,
        y = 13017.80859375,
        z = 1051.1070556641,
    },
    travel1destrot = {
        z = 5.0831866264343,
    },
}
,	{
    travel1destcellname = "Sailen",
    travel2dest = {
        x = 246240.109375,
        y = -91205.6953125,
        z = 2596.4406738281,
    },
    class = "caravaner",
    travel2destcellname = "Akamora",
    ID = "tr_m2_vernis drethan",
    travel2destrot = {
        z = 1.9707964658737,
    },
    travel1dest = {
        x = 309995.625,
        y = -129665.2734375,
        z = 1153.8255615234,
    },
    travel1destrot = {
        z = 5.5131855010986,
    },
}
,	{
    travel1destcellname = "Firewatch, Guild of Mages",
    travel2dest = {
        x = 0,
        y = 1392,
        z = -400.12005615234,
    },
    class = "guild guide",
    travel2destcellname = "Firewatch, Guild of Mages",
    ID = "tr_m3_barabus inclodios",
    travel2destrot = {
        z = 3.141592502594,
    },
    travel1dest = {
        x = 5432,
        y = 2720,
        z = 10672.624023438,
    },
    travel1destrot = {
        z = 3.9269907474518,
    },
}
,	{
    travel1destcellname = "Bosmora",
    class = "caravaner",
    ID = "tr_m3_bradli_arvil",
    travel1dest = {
        x = 275883.71875,
        y = -238679.875,
        z = 1457.24609375,
    },
    travel1destrot = {
        z = 3.6831865310669,
    },
}
,	{
    travel1destcellname = "Roa Dyr",
    class = "t_glb_fisherman",
    ID = "tr_m3_dovres salvi",
    travel1dest = {
        x = 70613.6875,
        y = -217352.53125,
        z = 94.079330444336,
    },
    travel1destrot = {
        z = 4.8599996566772,
    },
}
,	{
    travel1destcellname = "Akamora, Guild of Mages",
    travel2dest = {
        x = 7872,
        y = 4264,
        z = 15280.48046875,
    },
    class = "guild guide",
    travel2destcellname = "Akamora, Guild of Mages",
    ID = "tr_m3_elvilde",
    travel2destrot = {
        z = 0,
    },
    travel1dest = {
        x = -248,
        y = -504,
        z = -304,
    },
    travel1destrot = {
        z = 0.80000007152557,
    },
}
,	{
    travel1destcellname = "Necrom",
    travel2dest = {
        x = 246233.53125,
        y = -91210.5859375,
        z = 2588.8898925781,
    },
    travel2destrot = {
        z = 2.0000002384186,
    },
    travel2destcellname = "Akamora",
    ID = "tr_m3_fathusa_balvel",
    travel3destrot = {
        z = 4.0831866264343,
    },
    travel3destcellname = "Bosmora",
    class = "caravaner",
    travel3dest = {
        x = 277381.25,
        y = -239312.453125,
        z = 2295.3972167969,
    },
    travel1dest = {
        x = 344523.78125,
        y = -93358.78125,
        z = 1304,
    },
    travel1destrot = {
        z = 2.039999961853,
    },
}
,	{
    travel1destcellname = "Sailen",
    class = "caravaner",
    ID = "tr_m3_hlor_gonav",
    travel1dest = {
        x = 310000.4375,
        y = -129669.203125,
        z = 1154.9910888672,
    },
    travel1destrot = {
        z = 5.4831857681274,
    },
}
,	{
    travel1destcellname = "Marog",
    travel2dest = {
        x = 205096,
        y = 11360,
        z = 256,
    },
    travel2destrot = {
        z = 0.69813168048859,
    },
    travel2destcellname = "Helnim",
    ID = "tr_m3_ieva llori",
    travel3destrot = {
        z = 1.570796251297,
    },
    travel3destcellname = "Old Ebonheart, Docks",
    travel4dest = {
        x = 35752,
        y = -74456,
        z = 165.51438903809,
    },
    travel4destrot = {
        z = 4.27605676651,
    },
    travel4destcellname = "Vivec, Foreign Quarter",
    class = "shipmaster",
    travel3dest = {
        x = 60856,
        y = -144544,
        z = 418.2887878418,
    },
    travel1dest = {
        x = 191512,
        y = -8640,
        z = 417.82138061523,
    },
    travel1destrot = {
        z = 2.181661605835,
    },
}
,	{
    travel1destcellname = "",
    class = "t_glb_fisherman",
    ID = "tr_m3_illor mavos",
    travel1dest = {
        x = 67224.0234375,
        y = -222128.015625,
        z = 118.32518768311,
    },
    travel1destrot = {
        z = 3.9100000858307,
    },
}
,	{
    travel1destcellname = "Aimrah",
    travel2dest = {
        x = 89007.9140625,
        y = -194406.703125,
        z = 1565.2485351563,
    },
    travel2destrot = {
        z = 4.6831860542297,
    },
    travel2destcellname = "Vhul",
    ID = "tr_m3_ivrea llothro",
    travel3destrot = {
        z = 4.7123889923096,
    },
    travel3destcellname = "Andothren",
    class = "caravaner",
    travel3dest = {
        x = 10944,
        y = -133088,
        z = 1068.9833984375,
    },
    travel1dest = {
        x = 105758.7890625,
        y = -275213.5,
        z = 831.45849609375,
    },
    travel1destrot = {
        z = 4.7831864356995,
    },
}
,	{
    travel1destcellname = "Gorne",
    travel2dest = {
        x = 346809.90625,
        y = -75862.2578125,
        z = 332.58743286133,
    },
    class = "shipmaster",
    travel2destcellname = "Necrom, Waterfront",
    ID = "tr_m3_laga_gra-shogar",
    travel2destrot = {
        z = 2.3999998569489,
    },
    travel1dest = {
        x = 333540.21875,
        y = -239401.375,
        z = 501.82147216797,
    },
    travel1destrot = {
        z = 1.6000001430511,
    },
}
,	{
    travel1destcellname = "Enamor Dayn",
    class = "caravaner",
    ID = "tr_m3_lladas_varayne",
    travel1dest = {
        x = 305090.375,
        y = -225285.0625,
        z = 852.78759765625,
    },
    travel1destrot = {
        z = 5.6999983787537,
    },
}
,	{
    travel1destcellname = "Almas Thirr",
    travel2dest = {
        x = 89017.375,
        y = -194408.03125,
        z = 1565.2485351563,
    },
    class = "caravaner",
    travel2destcellname = "Vhul",
    ID = "tr_m3_lleres sarando",
    travel2destrot = {
        z = 4.5831861495972,
    },
    travel1dest = {
        x = 44032,
        y = -228184,
        z = 686.43426513672,
    },
    travel1destrot = {
        z = 4.7123889923096,
    },
}
,	{
    travel1destcellname = "Indal-ruhn",
    travel2dest = {
        x = 60856,
        y = -144544,
        z = 418.2887878418,
    },
    travel2destrot = {
        z = 1.570796251297,
    },
    travel2destcellname = "Old Ebonheart, Docks",
    ID = "tr_m3_ralis nalor",
    travel3destrot = {
        z = 4.0142569541931,
    },
    travel3destcellname = "Andothren, Docks",
    class = "shipmaster",
    travel3dest = {
        x = 3849.2595214844,
        y = -123961.25,
        z = 181.99993896484,
    },
    travel1dest = {
        x = 20448,
        y = -225032,
        z = 153.34600830078,
    },
    travel1destrot = {
        z = 5.5850534439087,
    },
}
,	{
    travel1destcellname = "Enamor Dayn",
    class = "shipmaster",
    ID = "tr_m3_rellus delano",
    travel1dest = {
        x = 309877.625,
        y = -224730.5625,
        z = 412.4323425293,
    },
    travel1destrot = {
        z = 4.9831871986389,
    },
}
,	{
    travel1destcellname = "Aimrah",
    travel2dest = {
        x = 44032,
        y = -228184,
        z = 686.43426513672,
    },
    class = "caravaner",
    travel2destcellname = "Almas Thirr",
    ID = "tr_m3_riltse helandil",
    travel2destrot = {
        z = 4.7123889923096,
    },
    travel1dest = {
        x = 105756.28125,
        y = -275213.0625,
        z = 831.45843505859,
    },
    travel1destrot = {
        z = 4.7831864356995,
    },
}
,	{
    travel1destcellname = "Omaynis",
    class = "caravaner",
    ID = "tr_m4_alvur_nirano",
    travel1dest = {
        x = -57184,
        y = -124608,
        z = 2568.0944824219,
    },
    travel1destrot = {
        z = 2.7052602767944,
    },
}
,	{
    travel1destcellname = "Almas Thirr",
    class = "shipmaster",
    ID = "tr_m4_balyn ilvenes",
    travel1dest = {
        x = 47336,
        y = -227680,
        z = 192.00003051758,
    },
    travel1destrot = {
        z = 1.570796251297,
    },
}
,	{
    travel1destcellname = "Menaan",
    class = "caravaner",
    ID = "tr_m4_didilu-edinu",
    travel1dest = {
        x = -17048,
        y = -163488,
        z = 1388.9833984375,
    },
    travel1destrot = {
        z = 3.141592502594,
    },
}
,	{
    travel1destcellname = "Almas Thirr",
    class = "shipmaster",
    ID = "tr_m4_drovamu llarno",
    travel1dest = {
        x = 47336,
        y = -227680,
        z = 192.00003051758,
    },
    travel1destrot = {
        z = 1.570796251297,
    },
}
,	{
    travel1destcellname = "Almas Thirr",
    travel2dest = {
        x = -17048,
        y = -163488,
        z = 1388.9833984375,
    },
    travel2destrot = {
        z = 3.141592502594,
    },
    travel2destcellname = "Menaan",
    ID = "tr_m4_ervyna_saran",
    travel3destrot = {
        z = 2.7052602767944,
    },
    travel3destcellname = "Omaynis",
    class = "caravaner",
    travel3dest = {
        x = -57184,
        y = -124608,
        z = 2568.0944824219,
    },
    travel1dest = {
        x = 44032,
        y = -228184,
        z = 686.43426513672,
    },
    travel1destrot = {
        z = 4.7123889923096,
    },
}
,	{
    travel1destcellname = "Andothren",
    travel2dest = {
        x = -90792,
        y = -143912,
        z = 1128,
    },
    class = "caravaner",
    travel2destcellname = "Bodrum",
    ID = "tr_m4_galotha sareloth",
    travel2destrot = {
        z = 4.6251225471497,
    },
    travel1dest = {
        x = 10952,
        y = -133088,
        z = 1068.9833984375,
    },
    travel1destrot = {
        z = 4.7123889923096,
    },
}
,	{
    travel1destcellname = "Andothren",
    travel2dest = {
        x = -27080,
        y = -208848,
        z = 1745.6215820313,
    },
    class = "caravaner",
    travel2destcellname = "Arvud",
    ID = "tr_m4_gols_ulven",
    travel2destrot = {
        z = 3.0543260574341,
    },
    travel1dest = {
        x = 10952,
        y = -133088,
        z = 1068.9833984375,
    },
    travel1destrot = {
        z = 4.7123889923096,
    },
}
,	{
    travel1destcellname = "Akamora, Guild of Mages",
    travel2dest = {
        x = 4728,
        y = 3336,
        z = 15312,
    },
    class = "guild guide",
    travel2destcellname = "Akamora, Guild of Mages",
    ID = "tr_m4_ja'hadra",
    travel2destrot = {
        z = 5.4977869987488,
    },
    travel1dest = {
        x = -248,
        y = -504,
        z = -304,
    },
    travel1destrot = {
        z = 0.7853981256485,
    },
}
,	{
    travel1destcellname = "Mundrethi Plantation, Slave Market",
    class = "gondolier",
    ID = "tr_m4_llehra sarani",
    travel1dest = {
        x = 37856,
        y = -166624,
        z = 213.17984008789,
    },
    travel1destrot = {
        z = 1.1504415273666,
    },
}
,	{
    travel1destcellname = "Almas Thirr",
    travel2dest = {
        x = 60856,
        y = -144544,
        z = 418.2887878418,
    },
    travel2destrot = {
        z = 1.570796251297,
    },
    travel2destcellname = "Old Ebonheart, Docks",
    ID = "tr_m4_maros_sadryon",
    travel3destrot = {
        z = 4.7123889923096,
    },
    travel3destcellname = "Teyn",
    travel4dest = {
        x = 35752,
        y = -74456,
        z = 165.51438903809,
    },
    travel4destrot = {
        z = 4.27605676651,
    },
    travel4destcellname = "Vivec, Foreign Quarter",
    class = "shipmaster",
    travel3dest = {
        x = -24872,
        y = -107512,
        z = 129.7115020752,
    },
    travel1dest = {
        x = 47336,
        y = -227680,
        z = 192.00003051758,
    },
    travel1destrot = {
        z = 1.570796251297,
    },
}
,	{
    travel1destcellname = "Ushu-Kur",
    class = "merchant",
    ID = "tr_m4_nassuran omoril",
    travel1dest = {
        x = -48095.6171875,
        y = -205610.640625,
        z = 662.388671875,
    },
    travel1destrot = {
        z = 1.3899999856949,
    },
}
,	{
    travel1destcellname = "Oran Plantation",
    class = "gondolier",
    ID = "tr_m4_nol",
    travel1dest = {
        x = 25848,
        y = -199008,
        z = 127.50811767578,
    },
    travel1destrot = {
        z = 1.6580626964569,
    },
}
,	{
    travel1destcellname = "Arvud",
    class = "caravaner",
    ID = "tr_m4_othrys rorivel",
    travel1dest = {
        x = -29243.8828125,
        y = -210354.328125,
        z = 528,
    },
    travel1destrot = {
        z = 1.5707963705063,
    },
}
,	{
    travel1destcellname = "Andothren, Docks",
    travel2dest = {
        x = 20376,
        y = -102424,
        z = 152.78132629395,
    },
    class = "shipmaster",
    travel2destcellname = "Ebonheart",
    ID = "tr_m4_pien vene",
    travel2destrot = {
        z = 0,
    },
    travel1dest = {
        x = 3848,
        y = -123960,
        z = 181.99993896484,
    },
    travel1destrot = {
        z = 4.0142569541931,
    },
}


}

--Need to recreate the above data. This time, provide the source cell and position. Calculate this by the other NPCs.
--Have to have this data in order to create the reverse connection to the settlement.

local function addCustDest(sourceNpc,targetCellName,targetPos,targetRot)
    --need  to add customdest for the NPC, and for the target NPC to return.
--Here, we will set the 
end
return {
    interfaceName = "TravelWindow_Data",
    interface = {
        travelData = travelData,
        addCustDest = addCustDest,
    }
}
