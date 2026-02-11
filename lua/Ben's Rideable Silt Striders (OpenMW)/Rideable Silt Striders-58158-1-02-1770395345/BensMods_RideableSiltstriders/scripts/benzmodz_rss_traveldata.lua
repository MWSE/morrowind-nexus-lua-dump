
local util = require('openmw.util')
local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')

local travelData = {
  ['darvame hleran'] = { -- Seyda Neen
    ['Balmora'] = {
      sort = 0,
      cost = 15,
      startPoint = util.vector3(-8806, -70532, 1035),
      endPoint = util.vector3(-21361, -18282, 1085), 
      points = { util.vector3(-8798, -70536, 995), util.vector3(-5758, -71519, 963), util.vector3(-3788, -71691, 1311), util.vector3(-2035, -71300, 1722), util.vector3(-1414, -70925, 1867), util.vector3(-913, -70318, 1987), util.vector3(-620, -69533, 2052), util.vector3(-407, -69000, 2087), util.vector3(81, -68423, 2123), util.vector3(822, -67582, 2158), util.vector3(1281, -66729, 2255), util.vector3(1543, -65591, 2482), util.vector3(1679, -64330, 2696), util.vector3(1442, -62544, 2551), util.vector3(1004, -61065, 2341), util.vector3(524, -59380, 2247), util.vector3(-518, -56254, 2126), util.vector3(-955, -54795, 2050), util.vector3(-998, -53160, 1931), util.vector3(-1256, -51663, 1812), util.vector3(-2244, -50208, 1763), util.vector3(-4299, -47702, 1726), util.vector3(-6575, -45373, 1673), util.vector3(-7821, -44959, 1630), util.vector3(-10572, -44621, 1687), util.vector3(-12178, -44280, 1965), util.vector3(-14121, -43273, 2340), util.vector3(-15578, -41811, 2707), util.vector3(-18256, -38430, 3270), util.vector3(-19712, -35687, 3372), util.vector3(-20050, -32388, 3390), util.vector3(-18671, -28056, 3327), util.vector3(-18149, -26307, 3053), util.vector3(-18050, -24858, 2750), util.vector3(-18210, -23378, 2413), util.vector3(-18914, -21453, 1948), util.vector3(-19446, -20181, 1684), util.vector3(-20270, -18965, 1597), util.vector3(-20853, -18687, 1497), util.vector3(-21418, -18651, 1497) },
    },
    ['Vivec'] = {
      sort = 1,
      cost = 11,
      startPoint = util.vector3(-8806, -70532, 1035),
      endPoint = util.vector3(32277, -72255, 913), 
      points = { util.vector3(-6898, -71159, 1059), util.vector3(-5051, -71613, 1200), util.vector3(-2746, -72189, 1482), util.vector3(-1418, -73114, 1421), util.vector3(719, -75088, 1232), util.vector3(2623, -76774, 1171), util.vector3(3934, -77764, 1124), util.vector3(4688, -78029, 1171), util.vector3(6022, -78414, 1372), util.vector3(7303, -78872, 1423), util.vector3(9338, -79535, 1547), util.vector3(12357, -79875, 1691), util.vector3(15939, -79966, 1620), util.vector3(17363, -79191, 1550), util.vector3(18309, -77965, 1435), util.vector3(20031, -76526, 1133), util.vector3(21807, -75373, 900), util.vector3(23610, -74128, 972), util.vector3(25075, -72959, 1295), util.vector3(26682, -71757, 1955), util.vector3(27836, -70882, 2228), util.vector3(29678, -69599, 2169), util.vector3(31579, -69075, 1827), util.vector3(32633, -69647, 1457), util.vector3(33108, -70939, 1022), util.vector3(32891, -71449, 1001), util.vector3(32751, -72199, 1103) },
    },
    ['Suran'] = {
      sort = 2,
      cost = 18,
      startPoint = util.vector3(-8806, -70532, 1035),
      endPoint = util.vector3(53245, -47667, 1117), 
      points = { util.vector3(-7244, -71023, 983), util.vector3(-4649, -71725, 1453), util.vector3(-1805, -71319, 1835), util.vector3(-933, -70209, 1962), util.vector3(65, -68685, 2102), util.vector3(1927, -66392, 1845), util.vector3(4879, -63586, 1410), util.vector3(7969, -62613, 1235), util.vector3(14720, -61099, 1084), util.vector3(19303, -59555, 883), util.vector3(23202, -58787, 808), util.vector3(24727, -58125, 843), util.vector3(25991, -56151, 924), util.vector3(26914, -53782, 850), util.vector3(28976, -51243, 731), util.vector3(31662, -48187, 705), util.vector3(33514, -46548, 732), util.vector3(35267, -46239, 750), util.vector3(38037, -47813, 828), util.vector3(41320, -50587, 922), util.vector3(44336, -53230, 833), util.vector3(47334, -54155, 654), util.vector3(49105, -54081, 669), util.vector3(51453, -53180, 1195), util.vector3(53688, -52380, 1604), util.vector3(54952, -51740, 1704), util.vector3(55916, -50485, 1693), util.vector3(56068, -49054, 1521), util.vector3(55014, -47753, 1321), util.vector3(54128, -47382, 1222), util.vector3(53138, -47373, 1288) },
    },
    ['Gnisis'] = {
      sort = 3,
      cost = 51,
      startPoint = util.vector3(-8806, -70532, 1035),
      endPoint = util.vector3(-86824, 89359, 1030), 
      points = { util.vector3(-7785,-70920,955), util.vector3(-6204,-72022,1038), util.vector3(-6158,-74017,1190), util.vector3(-7199,-74645,1316), util.vector3(-9783,-74368,1447), util.vector3(-13385,-73064,1548), util.vector3(-15122,-72384,1426), util.vector3(-15868,-70479,1466), util.vector3(-19042,-66568,1518), util.vector3(-22775,-64896,1458), util.vector3(-28738,-62364,927), util.vector3(-35750,-59807,650), util.vector3(-39558,-58231,811), util.vector3(-41165,-57090,942), util.vector3(-41245,-55049,1161), util.vector3(-41494,-51077,1462), util.vector3(-42528,-49007,1897), util.vector3(-44086,-46460,2240), util.vector3(-45710,-42449,2261), util.vector3(-47087,-36946,2415), util.vector3(-47713,-34018,1734), util.vector3(-48522,-31265,1361), util.vector3(-49247,-28350,1228), util.vector3(-48783,-25838,1202), util.vector3(-47464,-23533,996), util.vector3(-46931,-21691,1209), util.vector3(-48664,-14028,1815), util.vector3(-49067,-10483,2425), util.vector3(-47311,-6681,3670), util.vector3(-45337,-3632,4290), util.vector3(-42422,1775,3448), util.vector3(-41336,5030,2573), util.vector3(-41337,6892,2307), util.vector3(-44416,9719,1906), util.vector3(-48646,11191,1225), util.vector3(-51417,13105,1747), util.vector3(-53204,14399,2213), util.vector3(-55504,17196,2317), util.vector3(-58184,23191,1782), util.vector3(-59162,25858,1229), util.vector3(-60700,29016,1106), util.vector3(-63381,33603,926), util.vector3(-66017,36010,866), util.vector3(-70386,38088,902), util.vector3(-72772,39684,847), util.vector3(-76144,43716,922), util.vector3(-77125,44994,1014), util.vector3(-78122,49625,1138), util.vector3(-82487,57096,855), util.vector3(-84278,60193,748), util.vector3(-84968,61768,710), util.vector3(-84800,64937,767), util.vector3(-84055,73009,389), util.vector3(-83970,75393,371), util.vector3(-84067,77134,1091), util.vector3(-84236,78806,2015), util.vector3(-83798,79930,2165), util.vector3(-83034,83447,2198), util.vector3(-82961,85961,1738), util.vector3(-83743,88111,1277), util.vector3(-85580,89059,1221), util.vector3(-86694,89044,1291) },
    },
  },
  ['selvil sareloth'] = { -- Balmora
    ['Seyda Neen'] = {
      sort = 1,
      cost = 15,
      startPoint = util.vector3(-21329, -18654, 1478),
      endPoint = util.vector3(-8766, -70197, 823), 
      points = { util.vector3(-22268, -18565, 1868), util.vector3(-24890, -19626, 3354), util.vector3(-26788, -21338, 2916), util.vector3(-28399, -23880, 1957), util.vector3(-29178, -25632, 1529), util.vector3(-30047, -27807, 1249), util.vector3(-30598, -30002, 1164), util.vector3(-30816, -32912, 992), util.vector3(-31091, -35576, 933), util.vector3(-31956, -38094, 877), util.vector3(-33311, -40287, 850), util.vector3(-35324, -41962, 860), util.vector3(-36261, -43528, 981), util.vector3(-36285, -45738, 1328), util.vector3(-35660, -47920, 1722), util.vector3(-33865, -50286, 2075), util.vector3(-31862, -51908, 2055), util.vector3(-29776, -52661, 1993), util.vector3(-27956, -53074, 2110), util.vector3(-26399, -53899, 2435), util.vector3(-25072, -55181, 2740), util.vector3(-24095, -55853, 2744), util.vector3(-22263, -56554, 2633), util.vector3(-19740, -57520, 2389), util.vector3(-17963, -58029, 2098), util.vector3(-15467, -62033, 2195), util.vector3(-14322, -63357, 1891), util.vector3(-14322, -64254, 1727), util.vector3(-14628, -65379, 1491), util.vector3(-14612, -67156, 1193), util.vector3(-14027, -68307, 950), util.vector3(-12739, -68993, 905), util.vector3(-11104, -68995, 817), util.vector3(-10511, -69468, 756), util.vector3(-10126, -69876, 758), util.vector3(-9221, -70384, 1048), util.vector3(-8781, -70545, 1008) },
    },
    ['Vivec'] = {
      sort = 3,
      cost = 22,
      startPoint = util.vector3(-21329, -18654, 1478),
      endPoint = util.vector3(32277, -72255, 913), 
      points = { util.vector3(-22156, -18610, 1788), util.vector3(-23950, -19040, 2517), util.vector3(-25576, -20416, 2799), util.vector3(-26805, -22019, 2429), util.vector3(-26257, -23478, 2018), util.vector3(-24775, -24082, 1798), util.vector3(-22014, -22728, 1641), util.vector3(-19472, -20444, 1203), util.vector3(-18047, -20085, 1627), util.vector3(-16077, -19749, 1404), util.vector3(-13970, -19245, 1025), util.vector3(-11740, -19145, 1200), util.vector3(-9490, -19277, 1565), util.vector3(-6662, -20331, 1855), util.vector3(-5318, -21308, 1839), util.vector3(-4434, -22424, 1750), util.vector3(-4434, -22424, 1750), util.vector3(-4102, -23360, 1621), util.vector3(-4419, -23848, 1578), util.vector3(-5102, -24396, 1498), util.vector3(-5305, -25020, 1455), util.vector3(-5356, -25706, 1412), util.vector3(-4833, -26475, 1468), util.vector3(-3907, -27172, 1619), util.vector3(-2645, -28099, 1667), util.vector3(-183, -29712, 1708), util.vector3(1853, -30860, 1712), util.vector3(3761, -31004, 1808), util.vector3(5228, -31417, 1791), util.vector3(6264, -33644, 1782), util.vector3(10626, -38112, 1721), util.vector3(16289, -43233, 1895), util.vector3(19586, -48809, 2072), util.vector3(21299, -56640, 1601), util.vector3(21763, -58027, 1473), util.vector3(21763, -58027, 1473), util.vector3(23867, -62677, 1646), util.vector3(24978, -64511, 1603), util.vector3(27854, -65645, 1675), util.vector3(29427, -65967, 1512), util.vector3(31220, -66379, 1260), util.vector3(32668, -68458, 954), util.vector3(32875, -71342, 1042), util.vector3(32750, -72197, 1061) },
    },
    ['Suran'] = {
      sort = 2,
      cost = 23,
      startPoint = util.vector3(-21329, -18654, 1478),
      endPoint = util.vector3(53211, -47669, 1117), 
      points = { util.vector3(-21982,-18557,1402), util.vector3(-22593,-18168,1367), util.vector3(-23281,-17187,1329), util.vector3(-23247,-16191,1317), util.vector3(-22737,-14811,1366), util.vector3(-22341,-13615,1354), util.vector3(-22222,-12547,1313), util.vector3(-21968,-11652,1285), util.vector3(-21185,-10788,1234), util.vector3(-19944,-9870,1205), util.vector3(-14526,-5524,1037), util.vector3(-11838,-3080,1312), util.vector3(-10931,-2564,1369), util.vector3(-9983,-2627,1432), util.vector3(-8609,-3559,1668), util.vector3(-7968,-4539,1840), util.vector3(-7784,-6452,2095), util.vector3(-7714,-9364,2458), util.vector3(-6720,-11431,2886), util.vector3(-5653,-12687,3193), util.vector3(-4199,-13595,3323), util.vector3(-2691,-13733,3399), util.vector3(73,-13422,3728), util.vector3(2483,-13127,4225), util.vector3(4237,-12685,4412), util.vector3(5540,-13051,4378), util.vector3(6574,-13663,4232), util.vector3(7573,-15025,3870), util.vector3(8652,-16557,3361), util.vector3(9907,-17690,3062), util.vector3(12396,-18489,2841), util.vector3(14957,-18715,2752), util.vector3(18969,-18960,2615), util.vector3(23200,-19686,2312), util.vector3(26641,-20634,2490), util.vector3(29602,-21114,2789), util.vector3(32962,-21382,3416), util.vector3(36043,-21016,3003), util.vector3(39208,-20716,2129), util.vector3(43517,-19976,1239), util.vector3(44788,-20158,1015), util.vector3(46373,-21025,862), util.vector3(47670,-22804,814), util.vector3(47857,-24508,783), util.vector3(47794,-25791,751), util.vector3(48132,-30852,725), util.vector3(47923,-32592,715), util.vector3(47941,-33963,637), util.vector3(49097,-38276,707), util.vector3(49130,-40844,700), util.vector3(49462,-43995,341), util.vector3(49742,-45165,178), util.vector3(50020,-46252,149), util.vector3(50354,-47691,386), util.vector3(50871,-49772,957), util.vector3(51624,-50822,1185), util.vector3(53015,-51479,1399), util.vector3(54541,-51357,1537), util.vector3(55637,-50261,1595), util.vector3(55805,-49124,1509), util.vector3(55192,-47828,1362), util.vector3(54134,-47338,1250), util.vector3(53132,-47373,1273) }
    },
    ['Ald-Ruhn'] = {
      sort = 0,
      cost = 21,
      startPoint = util.vector3(-21329, -18654, 1478),
      endPoint = util.vector3(-17706, 54638, 2775), 
      points = { util.vector3(-22002, -18567, 1397), util.vector3(-22739, -18235, 1301), util.vector3(-23225, -17326, 1268), util.vector3(-23343, -16312, 1265), util.vector3(-22586, -14565, 1252), util.vector3(-22324, -13543, 1237), util.vector3(-22154, -11672, 1205), util.vector3(-17427, -7860, 1037), util.vector3(-14608, -5552, 933), util.vector3(-11958, -3168, 1165), util.vector3(-10400, -1334, 1215), util.vector3(-9731, 612, 1328), util.vector3(-10577, 4290, 1683), util.vector3(-10383, 6047, 1773), util.vector3(-9568, 7066, 1885), util.vector3(-9543, 10495, 1888), util.vector3(-10388, 15508, 2490), util.vector3(-10301, 17515, 2404), util.vector3(-10170, 19212, 2277), util.vector3(-11431, 21285, 2414), util.vector3(-15727, 26685, 2819), util.vector3(-16921, 28675, 2785), util.vector3(-17136, 32056, 3211), util.vector3(-16218, 34715, 3667), util.vector3(-15238, 36903, 3905), util.vector3(-15461, 39170, 4005), util.vector3(-15490, 42593, 4015), util.vector3(-14248, 47309, 3978), util.vector3(-12542, 49875, 4121), util.vector3(-10807, 53054, 4193), util.vector3(-11058, 55461, 4222), util.vector3(-12344, 57122, 4235), util.vector3(-14618, 57689, 4095), util.vector3(-16569, 57029, 3458), util.vector3(-17785, 55828, 2970), util.vector3(-17945, 55446, 2867), util.vector3(-17939, 54692, 2848) },
    },
    ['Caldera'] = {
      sort = 4,
      cost = 10,
      startPoint = util.vector3(-21329, -18654, 1478),
      endPoint = util.vector3(-8837, 21937, 2158), 
      points = { util.vector3(-22147, -18554, 1331), util.vector3(-22701, -18230, 1252), util.vector3(-23273, -17239, 1200), util.vector3(-23206, -16008, 1166), util.vector3(-22538, -14855, 1195), util.vector3(-22276, -14059, 1205), util.vector3(-22204, -12800, 1202), util.vector3(-22077, -11763, 1189), util.vector3(-21392, -10881, 1179), util.vector3(-19940, -9740, 1121), util.vector3(-17907, -8187, 854), util.vector3(-16067, -6824, 758), util.vector3(-14590, -5601, 777), util.vector3(-13067, -4517, 849), util.vector3(-11704, -3017, 988), util.vector3(-10598, -1696, 1103), util.vector3(-9927, -4, 1169), util.vector3(-9661, 911, 1221), util.vector3(-10104, 2427, 1366), util.vector3(-10430, 4278, 1570), util.vector3(-10411, 5743, 1702), util.vector3(-9734, 6882, 1761), util.vector3(-9272, 8038, 1834), util.vector3(-9500, 9974, 1868), util.vector3(-9575, 11766, 1891), util.vector3(-8667, 14830, 1898), util.vector3(-7910, 17881, 1994), util.vector3(-8296, 20645, 2242), util.vector3(-8445, 21869, 2465) },
      flyAwayPoints = { util.vector3(-8364,22876,2753), util.vector3(-8212,24285,3079), util.vector3(-7851,26858,4065), util.vector3(-7103,28643,5372), util.vector3(-7105,30512,4333), util.vector3(-7394,32717,3298), util.vector3(-7847,35725,2572) }
    },
  },
  ['adondasi sadalvel'] = { -- Vivec
    ['Seyda Neen'] = {
      sort = 0,
      cost = 12,
      startPoint = util.vector3(32756,-72189,1127),
      endPoint = util.vector3(-8738, -70261, 823), 
      points = { util.vector3(32124,-74784,1266), util.vector3(31752,-75551,1361), util.vector3(30790,-76093,1462), util.vector3(29162,-75972,1551), util.vector3(27268,-75459,1581), util.vector3(25489,-75225,1491), util.vector3(24348,-75280,1414), util.vector3(22965,-75495,1308), util.vector3(20972,-76335,1278), util.vector3(19453,-77338,1385), util.vector3(17681,-78548,1484), util.vector3(15407,-80067,1375), util.vector3(13075,-81701,1184), util.vector3(8366,-84048,975), util.vector3(2908,-83996,562), util.vector3(1897,-83718,482), util.vector3(285,-82509,618), util.vector3(-1285,-81437,978), util.vector3(-5681,-79418,916), util.vector3(-11246,-78516,903), util.vector3(-13952,-78036,893), util.vector3(-15302,-77129,891), util.vector3(-16315,-75408,870), util.vector3(-16533,-72876,950), util.vector3(-15288,-70382,950), util.vector3(-13708,-69278,893), util.vector3(-11660,-68897,801), util.vector3(-10395,-69413,737), util.vector3(-9524,-70257,1074), util.vector3(-8810,-70522,1032) },
    },
    ['Suran'] = {
      sort = 1,
      cost = 8,
      startPoint = util.vector3(32756,-72189,1127),
      endPoint = util.vector3(53211, -47669, 1117),
      points = { util.vector3(32601,-73108,1047), util.vector3(32052,-74728,1305), util.vector3(32141,-75531,1298), util.vector3(33299,-76421,1440), util.vector3(34899,-76089,1587), util.vector3(36897,-73604,1732), util.vector3(38278,-71646,1396), util.vector3(39781,-69552,1107), util.vector3(41270,-67240,1287), util.vector3(42637,-66162,1520), util.vector3(44092,-65793,1754), util.vector3(45826,-64887,1966), util.vector3(49660,-61707,2036), util.vector3(53547,-58513,2637), util.vector3(55170,-57018,2778), util.vector3(56795,-54437,2578), util.vector3(56764,-51314,2154), util.vector3(55494,-48275,1381), util.vector3(54289,-47415,1235), util.vector3(53117,-47376,1274) },
    },
    ['Molag Mar'] = {
      sort = 2,
      cost = 21,
      startPoint = util.vector3(32756,-72189,1127),
      endPoint = util.vector3(103346, -58401, 1454), 
      points = { util.vector3(32512,-73369,1206), util.vector3(32670,-74755,1636), util.vector3(33458,-76255,1781), util.vector3(35549,-78029,1887), util.vector3(38154,-79095,1799), util.vector3(40817,-79675,1600), util.vector3(50364,-81291,2223), util.vector3(52324,-81575,2351), util.vector3(54326,-81836,2114), util.vector3(56736,-81590,1903), util.vector3(59693,-80569,1848), util.vector3(63913,-78567,2107), util.vector3(66744,-77402,2494), util.vector3(69142,-76098,2638), util.vector3(71578,-73993,2536), util.vector3(73391,-73044,2187), util.vector3(75473,-72932,1712), util.vector3(77954,-73589,1269), util.vector3(79954,-74694,1414), util.vector3(82731,-75367,1589), util.vector3(87164,-75248,1810), util.vector3(91866,-74200,2060), util.vector3(95062,-72042,2205), util.vector3(99470,-69623,2675), util.vector3(103315,-68207,3365), util.vector3(105528,-67022,3840), util.vector3(106820,-64506,3321), util.vector3(106355,-62580,2775), util.vector3(104952,-60942,2302), util.vector3(103634,-59785,2051), util.vector3(103588,-59810,2051), util.vector3(103062,-58729,1973) },
    },
    ['Balmora'] = {
      sort = 3,
      cost = 21,
      startPoint = util.vector3(32756,-72189,1127),
      endPoint = util.vector3(-21361, -18282, 1085), 
      points = { util.vector3(32553,-73031,1167), util.vector3(32228,-74503,1364), util.vector3(31773,-75543,1545), util.vector3(30425,-76085,1683), util.vector3(28808,-75788,1751), util.vector3(27190,-74549,1758), util.vector3(20561,-66403,1395), util.vector3(17999,-63909,1464), util.vector3(14335,-61648,1740), util.vector3(9597,-58938,2883), util.vector3(7016,-57483,2865), util.vector3(6175,-57025,2818), util.vector3(3921,-55243,2906), util.vector3(-1600,-50268,3111), util.vector3(-8329,-43179,3262), util.vector3(-10947,-39790,3308), util.vector3(-12937,-37120,3683), util.vector3(-15320,-32169,3570), util.vector3(-15946,-27974,3695), util.vector3(-16177,-23922,3194), util.vector3(-16776,-21726,2658), util.vector3(-18115,-19627,1992), util.vector3(-19809,-18872,1640), util.vector3(-21325,-18655,1523) },
    },
  },
  ['dilami androm'] = { -- Molag Mar
    ['Vivec'] = {
      sort = 1,
      cost = 21,
      startPoint = util.vector3(103051, -58713, 1937),
      endPoint = util.vector3(32277, -72255, 913), 
      points = { util.vector3(102849,-58222,1906), util.vector3(102389,-57819,1847), util.vector3(101307,-57456,1830), util.vector3(99734,-57241,1880), util.vector3(97314,-57418,2002), util.vector3(95197,-57237,1928), util.vector3(93214,-56004,1905), util.vector3(91814,-55336,1885), util.vector3(90541,-55603,1868), util.vector3(88589,-56196,1761), util.vector3(84443,-55605,2191), util.vector3(80921,-54604,2786), util.vector3(78458,-53323,2698), util.vector3(74140,-52615,2637), util.vector3(71616,-52010,2300), util.vector3(69618,-51795,2014), util.vector3(67705,-52253,2084), util.vector3(66886,-53482,2000), util.vector3(66555,-55080,1966), util.vector3(67049,-56877,1873), util.vector3(67065,-58382,1796), util.vector3(66665,-61669,1715), util.vector3(65827,-63593,1575), util.vector3(64502,-65614,1494), util.vector3(61986,-67506,1684), util.vector3(58642,-68279,2074), util.vector3(55957,-68721,2361), util.vector3(53679,-69065,2576), util.vector3(51099,-69352,2559), util.vector3(48910,-69940,2508), util.vector3(43645,-71124,2376), util.vector3(41636,-71256,2238), util.vector3(38539,-70200,1909), util.vector3(36749,-69464,1758), util.vector3(35356,-69333,1556), util.vector3(33818,-70004,1316), util.vector3(32939,-71035,1135), util.vector3(32763,-72175,1139) },
    },
    ['Suran'] = {
      sort = 0,
      cost = 14,
      startPoint = util.vector3(103051, -58713, 1937),
      endPoint = util.vector3(53211, -47669, 1117),
      points = { util.vector3(102896,-58336,1926), util.vector3(102680,-58017,1901), util.vector3(102154,-57763,1877), util.vector3(100670,-57348,1905), util.vector3(99276,-57228,1906), util.vector3(96857,-57487,1875), util.vector3(95310,-57238,1844), util.vector3(93948,-56350,2018), util.vector3(92746,-55685,1969), util.vector3(91341,-55429,1864), util.vector3(89984,-55837,1759), util.vector3(88226,-56119,1678), util.vector3(85671,-55623,1733), util.vector3(84971,-55101,1730), util.vector3(84493,-53832,1728), util.vector3(83749,-52272,1764), util.vector3(82484,-50453,1855), util.vector3(80876,-48948,1993), util.vector3(79281,-48587,2412), util.vector3(77500,-48408,2988), util.vector3(75974,-48599,2954), util.vector3(73252,-48826,2563), util.vector3(70905,-48834,2312), util.vector3(69284,-49436,2182), util.vector3(67367,-51857,2336), util.vector3(65335,-53261,2889), util.vector3(64336,-53319,3122), util.vector3(62841,-52489,3508), util.vector3(61566,-51923,4029), util.vector3(60287,-51864,4809), util.vector3(59080,-51044,4487), util.vector3(57734,-49538,3518), util.vector3(56548,-48441,2442), util.vector3(55350,-47701,1585), util.vector3(54285,-47362,1426), util.vector3(53164,-47364,1290) },
    },
  },
  ['folsi thendas'] = { -- Suran
    ['Balmora'] = {
      sort = 0,
      cost = 24,
      startPoint = util.vector3(53128, -47365, 1298),
      endPoint = util.vector3(-21361, -18282, 1085),
      points = { util.vector3(52069,-47390,1244), util.vector3(50670,-47437,1495), util.vector3(48844,-47518,1890), util.vector3(47514,-47446,1874), util.vector3(46585,-47005,1870), util.vector3(45252,-45949,1820), util.vector3(44171,-45175,1786), util.vector3(42685,-44773,1739), util.vector3(41442,-44075,1758), util.vector3(40566,-43151,1767), util.vector3(39926,-41346,1797), util.vector3(39087,-39571,1863), util.vector3(37769,-37419,1902), util.vector3(36502,-36121,1886), util.vector3(34592,-35316,2011), util.vector3(32679,-34934,2242), util.vector3(31205,-34576,2207), util.vector3(30219,-34041,2170), util.vector3(29090,-33700,2308), util.vector3(27470,-33986,2394), util.vector3(26743,-33880,2299), util.vector3(25308,-33367,1942), util.vector3(23294,-33114,1627), util.vector3(20491,-32581,1657), util.vector3(18354,-31616,1515), util.vector3(17235,-31180,1523), util.vector3(15853,-31633,1594), util.vector3(14417,-32673,1713), util.vector3(13221,-33231,1760), util.vector3(12360,-33051,1772), util.vector3(11046,-32850,2286), util.vector3(9487,-32538,2819), util.vector3(7709,-32182,2967), util.vector3(4360,-31523,2878), util.vector3(2348,-30974,2407), util.vector3(484,-30985,2239), util.vector3(-1639,-30976,2095), util.vector3(-3089,-31446,2009), util.vector3(-4151,-32463,2005), util.vector3(-4964,-33332,2000), util.vector3(-6781,-34345,2010), util.vector3(-9091,-36211,1998), util.vector3(-10261,-37948,2068), util.vector3(-10828,-39579,2081), util.vector3(-11273,-40717,2126), util.vector3(-15311,-41975,2515), util.vector3(-18846,-38904,3175), util.vector3(-19917,-35766,3329), util.vector3(-18039,-24784,2969), util.vector3(-18152,-21051,2366), util.vector3(-19490,-19078,1766), util.vector3(-20152,-18774,1604), util.vector3(-21340,-18651,1522) }, 
    },
    ['Seyda Neen'] = {
      sort = 1,
      cost = 19,
      startPoint = util.vector3(53128, -47365, 1298),
      endPoint = util.vector3(-8738, -70261, 823), 
      points = { util.vector3(52518,-47370,1210), util.vector3(51996,-47587,1134), util.vector3(51491,-48500,1090), util.vector3(51017,-50212,1088), util.vector3(50677,-52027,1128), util.vector3(49557,-53256,916), util.vector3(47782,-53756,816), util.vector3(44902,-53110,793), util.vector3(43079,-51870,777), util.vector3(37899,-47460,783), util.vector3(36017,-46573,779), util.vector3(33848,-46807,794), util.vector3(31180,-48581,797), util.vector3(28335,-51711,856), util.vector3(26816,-54660,936), util.vector3(25605,-56871,923), util.vector3(24046,-58184,835), util.vector3(21893,-58964,907), util.vector3(19252,-60433,1076), util.vector3(18010,-62613,1126), util.vector3(17255,-64653,1116), util.vector3(16570,-66390,1031), util.vector3(16188,-68551,1064), util.vector3(14822,-71071,1379), util.vector3(13157,-73123,1724), util.vector3(11615,-75055,1651), util.vector3(10073,-77527,1439), util.vector3(8824,-79982,1256), util.vector3(7841,-81618,1165), util.vector3(5509,-82572,1095), util.vector3(3735,-82062,804), util.vector3(2266,-81412,653), util.vector3(1030,-80287,802), util.vector3(-730,-78553,1196), util.vector3(-2922,-77396,1486), util.vector3(-6669,-75816,1430), util.vector3(-9889,-74402,1137), util.vector3(-12515,-73325,889), util.vector3(-14427,-72597,744), util.vector3(-15191,-71444,741), util.vector3(-14790,-69947,767), util.vector3(-13175,-69156,848), util.vector3(-11729,-68920,859), util.vector3(-10672,-69427,846), util.vector3(-9708,-70161,904), util.vector3(-8792,-70533,1041) },
    },
    ['Vivec'] = {
      sort = 2,
      cost = 9,
      startPoint = util.vector3(53128, -47365, 1298),
      endPoint = util.vector3(32277, -72255, 913), 
      points = { util.vector3(52185,-47387,1135), util.vector3(51465,-47679,1044), util.vector3(50944,-48581,1003), util.vector3(50475,-50728,947), util.vector3(49886,-52274,892), util.vector3(49001,-53159,857), util.vector3(47239,-53736,857), util.vector3(44776,-53101,916), util.vector3(42820,-51619,965), util.vector3(37311,-47125,920), util.vector3(36016,-46513,903), util.vector3(33795,-46740,863), util.vector3(31452,-48337,879), util.vector3(29455,-50372,815), util.vector3(27258,-53392,789), util.vector3(26126,-55908,794), util.vector3(25478,-57307,814), util.vector3(24156,-58470,806), util.vector3(22186,-59126,789), util.vector3(20715,-59511,783), util.vector3(19176,-60371,790), util.vector3(18114,-61749,913), util.vector3(17204,-63936,1151), util.vector3(16485,-66376,1285), util.vector3(16245,-69161,1269), util.vector3(16789,-72170,1235), util.vector3(17849,-74932,1050), util.vector3(19130,-76101,990), util.vector3(20578,-76425,934), util.vector3(22111,-75790,889), util.vector3(23153,-74672,1077), util.vector3(24777,-72986,1372), util.vector3(26787,-71828,1373), util.vector3(28929,-71100,1536), util.vector3(30627,-70389,1415), util.vector3(32046,-70508,1046), util.vector3(32749,-71104,944), util.vector3(32755,-72161,1092) },
    },
    ['Molag Mar'] = {
      sort = 3,
      cost = 14,
      startPoint = util.vector3(53128, -47365, 1298),
      endPoint = util.vector3(103346, -58401, 1454), 
      points = { util.vector3(52366,-47363,1170), util.vector3(51653,-47637,1063), util.vector3(51056,-48705,956), util.vector3(50501,-51852,930), util.vector3(50584,-54740,1062), util.vector3(51134,-57416,1023), util.vector3(52148,-59559,944), util.vector3(53542,-61001,887), util.vector3(57559,-64773,1025), util.vector3(60512,-68022,1713), util.vector3(64282,-72112,2428), util.vector3(67280,-75133,2459), util.vector3(70550,-76937,2213), util.vector3(72294,-77881,2060), util.vector3(74440,-78766,1864), util.vector3(76727,-78648,1701), util.vector3(79999,-77390,1500), util.vector3(83486,-75047,1313), util.vector3(85793,-73054,1574), util.vector3(89043,-71138,2482), util.vector3(92086,-70092,2703), util.vector3(96675,-68104,2900), util.vector3(98003,-66145,3701), util.vector3(99516,-64059,4245), util.vector3(100898,-62836,3982), util.vector3(102512,-61764,2783), util.vector3(103510,-60860,2002), util.vector3(103487,-59819,1764), util.vector3(103049,-58709,1943) },
    },
  },
  ['navam veran'] = { -- Ald-Ruhn
    ['Balmora'] = {
      sort = 0,
      cost = 20,
      startPoint = util.vector3(-17946, 54727, 2845),
      endPoint = util.vector3(-21361, -18282, 1085),
      points = { util.vector3(-17945,53998,2767), util.vector3(-18080,52301,2892), util.vector3(-18219,50793,3009), util.vector3(-18974,47056,3036), util.vector3(-19715,43658,3649), util.vector3(-20153,41271,3992), util.vector3(-20924,38558,3939), util.vector3(-21680,36645,3338), util.vector3(-22166,35020,2610), util.vector3(-22169,32461,2239), util.vector3(-21757,29217,2257), util.vector3(-20912,27402,2360), util.vector3(-19260,25972,2426), util.vector3(-17621,25509,2425), util.vector3(-16347,24905,2391), util.vector3(-14891,23339,2573), util.vector3(-13338,21951,2976), util.vector3(-11974,20844,2759), util.vector3(-10651,20036,2411), util.vector3(-10192,19248,2297), util.vector3(-10383,17406,2525), util.vector3(-10215,16138,2601), util.vector3(-9799,14326,2463), util.vector3(-9679,11261,2199), util.vector3(-9219,7148,2141), util.vector3(-9059,5150,2161), util.vector3(-9700,1243,1657), util.vector3(-10521,-1060,1311), util.vector3(-12455,-3548,1259), util.vector3(-14147,-5059,1204), util.vector3(-16270,-6893,1143), util.vector3(-17404,-8339,1158), util.vector3(-18046,-11004,1258), util.vector3(-18290,-13398,1338), util.vector3(-18380,-15617,1414), util.vector3(-18748,-17551,1510), util.vector3(-20329,-18611,1515), util.vector3(-21340,-18652,1493) },
    },
    ['Khuul'] = {
      sort = 1,
      cost = 26,
      startPoint = util.vector3(-17946, 54727, 2845),
      endPoint = util.vector3(-66475, 135470, 988), 
      points = { util.vector3(-17985,53771,2763), util.vector3(-18477,52751,2626), util.vector3(-19735,52217,2477), util.vector3(-21539,52482,2240), util.vector3(-23888,53846,1950), util.vector3(-24337,55397,1904), util.vector3(-24280,57571,1935), util.vector3(-25160,59482,1966), util.vector3(-27927,60970,2247), util.vector3(-29897,62121,2251), util.vector3(-31774,64800,2247), util.vector3(-33452,66315,2105), util.vector3(-35313,66291,2066), util.vector3(-37032,66920,2081), util.vector3(-38425,68719,2143), util.vector3(-38906,71042,2085), util.vector3(-38876,73748,1930), util.vector3(-38500,76764,1978), util.vector3(-38749,78759,2009), util.vector3(-39548,81294,2115), util.vector3(-40510,84039,2371), util.vector3(-41478,86496,2328), util.vector3(-41542,89731,2097), util.vector3(-41468,92004,1926), util.vector3(-40224,94005,1949), util.vector3(-38259,96383,2087), util.vector3(-35547,99013,2351), util.vector3(-32550,100125,2439), util.vector3(-29944,100736,2361), util.vector3(-28313,100426,2343), util.vector3(-27139,101007,2291), util.vector3(-26704,102537,2257), util.vector3(-26156,104495,2301), util.vector3(-26320,106243,2308), util.vector3(-27292,106587,2218), util.vector3(-29608,106853,2110), util.vector3(-31486,107936,2030), util.vector3(-32449,109344,1893), util.vector3(-32742,111730,1847), util.vector3(-32844,113614,1684), util.vector3(-33457,114833,1680), util.vector3(-33863,116582,1713), util.vector3(-34513,118523,1708), util.vector3(-35306,120444,1666), util.vector3(-36904,121619,1675), util.vector3(-38930,121617,1801), util.vector3(-40603,122366,1782), util.vector3(-42325,123685,1706), util.vector3(-44628,124988,1759), util.vector3(-45346,125972,2173), util.vector3(-46566,127532,3068), util.vector3(-48185,129828,4331), util.vector3(-50388,132006,5299), util.vector3(-51737,133227,6054), util.vector3(-53586,133770,4903), util.vector3(-56141,134424,3398), util.vector3(-58512,134259,2501), util.vector3(-60048,133068,1988), util.vector3(-62815,131892,1744), util.vector3(-64833,132296,1546), util.vector3(-66258,133734,1304), util.vector3(-66703,134498,1213), util.vector3(-66785,135347,1171) },
    },
    ['Maar Gan'] = {
      sort = 2,
      cost = 12,
      startPoint = util.vector3(-17946, 54727, 2845),
      endPoint = util.vector3(-22440, 100042, 2411), 
      points = { util.vector3(-17942,53965,2746), util.vector3(-18452,53095,2700), util.vector3(-19979,52379,2556), util.vector3(-22748,53377,2308), util.vector3(-23952,55117,2032), util.vector3(-24171,57632,2071), util.vector3(-24876,59346,2207), util.vector3(-27204,60436,2331), util.vector3(-29208,61637,2374), util.vector3(-30917,63412,2427), util.vector3(-33020,66189,2414), util.vector3(-33760,68041,2207), util.vector3(-33795,70003,2139), util.vector3(-35255,71936,2134), util.vector3(-35409,73747,2068), util.vector3(-36070,75460,2028), util.vector3(-38138,76751,1946), util.vector3(-38723,78836,1910), util.vector3(-39908,82280,2055), util.vector3(-41410,86257,2049), util.vector3(-41647,89237,2044), util.vector3(-41656,91664,1897), util.vector3(-39931,94279,1909), util.vector3(-37560,97062,2070), util.vector3(-34579,99610,2186), util.vector3(-31156,100634,2265), util.vector3(-28591,100953,2265), util.vector3(-25756,100690,2605), util.vector3(-23661,100003,2912), util.vector3(-22347,99807,2965) },
    },
    ['Gnisis'] = {
      sort = 3,
      cost = 22,
      startPoint = util.vector3(-17946, 54727, 2845),
      endPoint = util.vector3(-86824, 89359, 1030), 
      points = { util.vector3(-17960,53924,2731), util.vector3(-18536,52863,2617), util.vector3(-20756,52347,2357), util.vector3(-23198,53422,2005), util.vector3(-24755,54609,1895), util.vector3(-27075,56146,2440), util.vector3(-28572,56899,2673), util.vector3(-30133,58564,2860), util.vector3(-32270,59137,3026), util.vector3(-34226,59318,3075), util.vector3(-36985,58834,3185), util.vector3(-38653,58220,3266), util.vector3(-39515,57091,3297), util.vector3(-39801,56355,3241), util.vector3(-39654,55574,3133), util.vector3(-39537,54410,2979), util.vector3(-40192,53633,2909), util.vector3(-41349,53601,2861), util.vector3(-43213,54386,2669), util.vector3(-46365,55571,2288), util.vector3(-48695,57190,2115), util.vector3(-50460,58003,2045), util.vector3(-52748,58342,1965), util.vector3(-54712,59265,2007), util.vector3(-56659,59842,2108), util.vector3(-58393,60265,2281), util.vector3(-60157,60885,2280), util.vector3(-61586,61618,2680), util.vector3(-63122,62432,2799), util.vector3(-63607,63526,2591), util.vector3(-64040,65334,2370), util.vector3(-65561,67528,2219), util.vector3(-67768,68100,2229), util.vector3(-70412,68396,2172), util.vector3(-72413,69511,2180), util.vector3(-73144,71307,2375), util.vector3(-72739,73487,2387), util.vector3(-72124,75945,2112), util.vector3(-73088,77791,2373), util.vector3(-74403,80260,2580), util.vector3(-75426,81884,2300), util.vector3(-76439,82760,2046), util.vector3(-77789,83180,1928), util.vector3(-79280,83808,1898), util.vector3(-80404,85370,1727), util.vector3(-81998,86975,1401), util.vector3(-84648,88312,1303), util.vector3(-85769,88943,1282), util.vector3(-86663,89044,1305) },
    },
  },
  ['daras aryon'] = { -- Maar Gan
    ['Ald-ruhn'] = {
      sort = 0,
      cost = 12,
      startPoint = util.vector3(-22347, 99808, 2968),
      endPoint = util.vector3(-17706, 54638, 2775),
      points = { util.vector3(-22809,99864,2869), util.vector3(-23708,100280,2736), util.vector3(-25570,100957,2317), util.vector3(-26746,100680,2179), util.vector3(-28090,100657,2067), util.vector3(-30018,100851,2094), util.vector3(-31816,100346,2184), util.vector3(-33803,99913,2155), util.vector3(-35413,98917,2082), util.vector3(-37006,97654,1991), util.vector3(-38822,95743,1863), util.vector3(-40400,93770,1864), util.vector3(-41642,91831,1945), util.vector3(-41583,89733,2095), util.vector3(-41617,88288,2149), util.vector3(-41376,86440,2192), util.vector3(-40638,84180,2020), util.vector3(-39548,81576,1828), util.vector3(-38750,78318,1770), util.vector3(-38840,76734,1806), util.vector3(-39002,74099,1806), util.vector3(-39021,71158,1965), util.vector3(-38648,68910,2058), util.vector3(-37025,66846,2113), util.vector3(-35817,65358,2067), util.vector3(-34343,63640,2190), util.vector3(-33579,61647,2478), util.vector3(-33568,59762,2816), util.vector3(-32565,59338,2844), util.vector3(-30996,59112,2834), util.vector3(-29539,57743,2614), util.vector3(-28512,56992,2339), util.vector3(-27014,56373,2122), util.vector3(-25138,56690,2283), util.vector3(-23141,57073,2722), util.vector3(-20638,57644,3082), util.vector3(-19143,57426,3120), util.vector3(-18042,55794,2932), util.vector3(-17946, 54727, 2845) },
    },
    ['Khuul'] = {
      sort = 1,
      cost = 16,
      startPoint = util.vector3(-22347, 99808, 2968),
      endPoint = util.vector3(-66475, 135470, 988), 
      points = { util.vector3(-22969,99882,2866), util.vector3(-24093,100307,2744), util.vector3(-24722,101150,2610), util.vector3(-25119,102800,2425), util.vector3(-25833,104869,2282), util.vector3(-27038,106145,2074), util.vector3(-29339,106787,1824), util.vector3(-31373,108002,1495), util.vector3(-32457,109445,1377), util.vector3(-32649,111416,1512), util.vector3(-32805,113557,1443), util.vector3(-33556,115368,1365), util.vector3(-33836,117405,1368), util.vector3(-34949,119742,1320), util.vector3(-36181,121415,1370), util.vector3(-38031,121709,1691), util.vector3(-39735,121937,1728), util.vector3(-41870,123399,1731), util.vector3(-43963,124441,1741), util.vector3(-45033,126022,1740), util.vector3(-46579,127493,2492), util.vector3(-48685,130131,4108), util.vector3(-51344,132870,5449), util.vector3(-53482,133425,4774), util.vector3(-57576,132634,2555), util.vector3(-61297,132358,1434), util.vector3(-63320,132194,1447), util.vector3(-65814,132970,1316), util.vector3(-66769,135348,1189) },
    },
    ['Gnisis'] = {
      sort = 2,
      cost = 18,
      startPoint = util.vector3(-22347, 99808, 2968),
      endPoint = util.vector3(-86824, 89359, 1030), 
      points = { util.vector3(-23175,99940,2818), util.vector3(-24206,100420,2560), util.vector3(-25943,100915,2172), util.vector3(-27920,100774,2143), util.vector3(-30060,100916,2171), util.vector3(-32790,100187,2215), util.vector3(-35070,99228,2174), util.vector3(-37508,97165,1939), util.vector3(-39339,95204,1802), util.vector3(-41244,92807,1767), util.vector3(-41540,90701,1975), util.vector3(-41645,88402,2229), util.vector3(-40679,84560,2277), util.vector3(-40925,82465,2602), util.vector3(-42027,80220,3839), util.vector3(-42997,78625,4973), util.vector3(-44036,77571,5246), util.vector3(-46017,77313,5337), util.vector3(-48166,78311,4629), util.vector3(-50361,79263,3627), util.vector3(-53303,79950,2635), util.vector3(-55250,80762,2128), util.vector3(-57418,82442,2358), util.vector3(-60365,84696,2129), util.vector3(-62276,85953,2067), util.vector3(-65623,87887,2531), util.vector3(-69200,88687,1937), util.vector3(-71601,88569,1565), util.vector3(-75463,87921,790), util.vector3(-78472,87570,703), util.vector3(-83797,88242,1049), util.vector3(-85607,88855,1166), util.vector3(-86631,89048,1306) },
    },
  },
  ['punibi yahaz'] = { -- Gnisis
    ['Ald-ruhn'] = {
      sort = 0,
      cost = 22,
      startPoint = util.vector3(-86674, 89042, 1304),
      endPoint = util.vector3(-17706, 54638, 2775),
      points = { util.vector3(-87508,89056,1197), util.vector3(-88466,88618,1049), util.vector3(-88705,87486,1187), util.vector3(-87713,86203,1672), util.vector3(-86073,85276,1392), util.vector3(-84995,84702,1198), util.vector3(-84000,84378,1364), util.vector3(-82839,84579,1550), util.vector3(-81317,84793,1559), util.vector3(-79822,84799,1504), util.vector3(-78349,84744,1466), util.vector3(-77137,84532,1437), util.vector3(-75433,85824,1421), util.vector3(-72948,85693,1669), util.vector3(-70705,84711,2180), util.vector3(-69486,83704,2085), util.vector3(-68350,81995,1803), util.vector3(-67935,79816,1852), util.vector3(-67031,79062,1950), util.vector3(-65987,78294,2083), util.vector3(-65702,76981,2386), util.vector3(-65343,75674,2634), util.vector3(-64622,74662,2954), util.vector3(-64243,72974,3006), util.vector3(-63074,70373,2842), util.vector3(-61596,68981,2638), util.vector3(-61323,67906,2575), util.vector3(-61680,65737,2280), util.vector3(-61412,62679,1905), util.vector3(-61022,61687,1874), util.vector3(-59770,60574,2100), util.vector3(-58434,60155,2188), util.vector3(-56771,59879,1946), util.vector3(-55019,59100,1841), util.vector3(-53546,58482,1924), util.vector3(-51508,58208,1897), util.vector3(-50045,57844,1854), util.vector3(-48525,56606,1961), util.vector3(-45617,55567,2277), util.vector3(-43156,54155,2537), util.vector3(-40502,53410,2825), util.vector3(-39755,54103,2926), util.vector3(-39714,55181,3016), util.vector3(-39921,55864,3107), util.vector3(-39469,57283,3168), util.vector3(-38293,58514,3064), util.vector3(-37341,58712,2936), util.vector3(-35825,59105,2885), util.vector3(-34278,59313,2794), util.vector3(-31662,59195,2719), util.vector3(-29943,58216,2511), util.vector3(-28980,56994,2254), util.vector3(-27623,56741,2119), util.vector3(-25755,55790,1740), util.vector3(-24735,56291,1840), util.vector3(-23133,56948,2402), util.vector3(-20655,57220,2939), util.vector3(-18624,56547,3021), util.vector3(-17958,55592,2856), util.vector3(-17951,54743,2878) },
    },
    ['Maar Gan'] = {
      sort = 1,
      cost = 18,
      startPoint = util.vector3(-86674, 89042, 1304),
      endPoint = util.vector3(-22440, 100042, 2411), 
      points = { util.vector3(-87027,89048,1229), util.vector3(-87792,88838,1150), util.vector3(-87928,87714,1143), util.vector3(-86799,86863,1337), util.vector3(-85829,86818,1669), util.vector3(-82822,87388,1427), util.vector3(-80252,87663,1034), util.vector3(-77090,87955,909), util.vector3(-74597,89228,852), util.vector3(-73385,91302,885), util.vector3(-71654,92000,1052), util.vector3(-69395,91415,1498), util.vector3(-67954,90783,1791), util.vector3(-65285,91328,1858), util.vector3(-62806,90704,1861), util.vector3(-61439,91502,1961), util.vector3(-61195,92945,2034), util.vector3(-61379,94286,1955), util.vector3(-58811,96051,1789), util.vector3(-56337,96358,1898), util.vector3(-54428,94206,1724), util.vector3(-53028,93373,2247), util.vector3(-49646,92778,3717), util.vector3(-45706,93028,4834), util.vector3(-44364,93186,4892), util.vector3(-40313,94684,3375), util.vector3(-38305,96352,2292), util.vector3(-36960,97598,2168), util.vector3(-34843,99425,2371), util.vector3(-31207,100724,2727), util.vector3(-27553,100997,2577), util.vector3(-25042,100995,2630), util.vector3(-24015,100460,2688), util.vector3(-23177,99931,2796), util.vector3(-22374,99808,3030) },
    },
    ['Khuul'] = {
      sort = 2,
      cost = 14,
      startPoint = util.vector3(-86674, 89042, 1304),
      endPoint = util.vector3(-66475, 135470, 988), 
      points = { util.vector3(-87133,89048,1213), util.vector3(-87830,88878,1127), util.vector3(-89133,88181,892), util.vector3(-91092,87498,571), util.vector3(-92824,87552,541), util.vector3(-94350,87725,577), util.vector3(-96043,87370,549), util.vector3(-98668,87377,620), util.vector3(-102874,88529,602), util.vector3(-106382,90022,585), util.vector3(-111271,95923,531), util.vector3(-112545,99724,582), util.vector3(-112722,103288,853), util.vector3(-112804,104568,937), util.vector3(-112979,106611,776), util.vector3(-112990,109218,522), util.vector3(-112973,110618,439), util.vector3(-113005,111533,621), util.vector3(-114190,113332,1104), util.vector3(-114790,115268,1120), util.vector3(-114862,116809,1133), util.vector3(-114282,119196,1033), util.vector3(-112023,121566,1007), util.vector3(-106863,123637,865), util.vector3(-102345,123011,884), util.vector3(-100680,120185,737), util.vector3(-100323,117425,718), util.vector3(-100323,117425,718), util.vector3(-100353,115755,846), util.vector3(-98879,114385,1134), util.vector3(-97392,113916,1227), util.vector3(-95963,112790,1201), util.vector3(-94495,113114,1373), util.vector3(-92892,113788,1502), util.vector3(-90407,114354,1425), util.vector3(-88590,115379,1419), util.vector3(-87128,116719,1562), util.vector3(-86598,117833,1615), util.vector3(-85745,119729,1695), util.vector3(-84586,122333,1657), util.vector3(-83834,123234,1745), util.vector3(-82138,122024,2034), util.vector3(-81086,121515,2097), util.vector3(-79240,120718,2044), util.vector3(-77123,119678,2051), util.vector3(-75323,119728,1821), util.vector3(-73729,120979,1796), util.vector3(-72242,122921,1558), util.vector3(-71608,124804,1594), util.vector3(-70916,126811,1680), util.vector3(-69751,129900,2175), util.vector3(-69095,131279,2103), util.vector3(-67281,132375,1580), util.vector3(-66569,133768,1223), util.vector3(-66642,134487,1170), util.vector3(-66777,135320,1161) },
    },
    ['Seyda Neen'] = {
      sort = 3,
      cost = 52,
      startPoint = util.vector3(-86674, 89042, 1304),
      endPoint = util.vector3(-8738, -70261, 823), 
      points = { util.vector3(-87390,89030,1211), util.vector3(-88377,88680,1140), util.vector3(-90509,87756,961), util.vector3(-92614,87607,788), util.vector3(-97754,87391,770), util.vector3(-100429,87653,678), util.vector3(-102201,87467,695), util.vector3(-103098,85820,668), util.vector3(-103152,81265,608), util.vector3(-101594,79474,670), util.vector3(-99023,78363,695), util.vector3(-96542,78652,709), util.vector3(-94933,78920,674), util.vector3(-92421,78652,595), util.vector3(-90364,79352,597), util.vector3(-88698,79247,553), util.vector3(-87579,78263,968), util.vector3(-86767,76181,1148), util.vector3(-85138,72263,545), util.vector3(-85185,68060,700), util.vector3(-85270,62901,543), util.vector3(-84901,61063,394), util.vector3(-82089,56747,761), util.vector3(-78772,52515,707), util.vector3(-78135,50692,705), util.vector3(-77571,46550,775), util.vector3(-77108,45030,836), util.vector3(-75727,41517,634), util.vector3(-73575,38753,641), util.vector3(-70955,35238,680), util.vector3(-66108,27953,1641), util.vector3(-63970,25432,2121), util.vector3(-59717,20488,1867), util.vector3(-56604,15717,2409), util.vector3(-55034,13421,2441), util.vector3(-54079,10827,2138), util.vector3(-53943,1239,645), util.vector3(-53672,-3216,611), util.vector3(-53007,-9778,600), util.vector3(-51673,-13485,756), util.vector3(-51540,-15200,561), util.vector3(-52029,-18242,547), util.vector3(-52815,-22229,648), util.vector3(-52756,-25627,587), util.vector3(-51315,-29004,625), util.vector3(-49255,-30838,714), util.vector3(-48061,-33001,896), util.vector3(-48494,-35949,1073), util.vector3(-49204,-39039,1128), util.vector3(-51028,-42239,829), util.vector3(-52205,-44519,702), util.vector3(-52459,-47637,772), util.vector3(-51443,-51298,767), util.vector3(-49049,-54636,788), util.vector3(-45919,-56731,809), util.vector3(-37501,-59415,591), util.vector3(-30475,-61481,587), util.vector3(-26616,-65467,662), util.vector3(-24778,-67580,821), util.vector3(-22832,-68618,800), util.vector3(-18024,-70234,672), util.vector3(-15640,-70238,655), util.vector3(-13065,-69254,739), util.vector3(-11608,-68864,834), util.vector3(-10841,-68995,775), util.vector3(-9788,-70087,868), util.vector3(-8790,-70535,1038) },
    },
  },
  ['seldus nerendus'] = { -- Khuul
    ['Maar Gan'] = {
      sort = 0,
      cost = 16,
      startPoint = util.vector3(-66773, 135331, 1175),
      endPoint = util.vector3(-22440, 100042, 2411), 
      points = { util.vector3(-66909,136002,1057), util.vector3(-67516,136660,1011), util.vector3(-69212,136604,1160), util.vector3(-69827,135478,1425), util.vector3(-69511,134092,1489), util.vector3(-68378,132950,1552), util.vector3(-64747,131726,1622), util.vector3(-62845,132097,1692), util.vector3(-59461,131869,2551), util.vector3(-55861,131297,4298), util.vector3(-53884,130906,5970), util.vector3(-52542,130631,6272), util.vector3(-50821,130123,5545), util.vector3(-47935,128633,3490), util.vector3(-46293,127244,2280), util.vector3(-44996,125441,1836), util.vector3(-43745,124491,1796), util.vector3(-42037,123444,1694), util.vector3(-38926,119932,1943), util.vector3(-36520,116658,2421), util.vector3(-34552,114088,2432), util.vector3(-33262,111474,1841), util.vector3(-32128,108847,1795), util.vector3(-29094,107077,2132), util.vector3(-25933,106344,2272), util.vector3(-24025,105707,3143), util.vector3(-22333,104992,3660), util.vector3(-20963,103949,3636), util.vector3(-20174,102830,3511), util.vector3(-20158,101293,3286), util.vector3(-21136,99859,3047), util.vector3(-21558,99724,3016), util.vector3(-22334,99813,2991) },
    },
    ['Ald-ruhn'] = {
      sort = 1,
      cost = 27,
      startPoint = util.vector3(-66773, 135331, 1175),
      endPoint = util.vector3(-17706, 54638, 2775),
      points = { util.vector3(-66851,135632,1096), util.vector3(-67569,136231,912), util.vector3(-68580,137267,652), util.vector3(-69692,138482,468), util.vector3(-71529,139341,327), util.vector3(-72435,140311,410), util.vector3(-72275,141772,517), util.vector3(-70727,143260,599), util.vector3(-67643,144021,497), util.vector3(-61693,146750,510), util.vector3(-57532,149800,609), util.vector3(-53698,153378,550), util.vector3(-51544,153448,545), util.vector3(-51122,151935,789), util.vector3(-50852,150309,1384), util.vector3(-50347,148403,2046), util.vector3(-50391,146714,2383), util.vector3(-50331,144445,2584), util.vector3(-49760,141104,2512), util.vector3(-49023,138598,2347), util.vector3(-48107,137780,2396), util.vector3(-45636,136568,2004), util.vector3(-43628,134890,2012), util.vector3(-40841,132402,2046), util.vector3(-37511,129930,1936), util.vector3(-34153,127877,1587), util.vector3(-30289,125643,1718), util.vector3(-28656,124686,1660), util.vector3(-27269,123200,1623), util.vector3(-24548,120404,1462), util.vector3(-20613,116704,1366), util.vector3(-17985,115150,1531), util.vector3(-15219,113463,1816), util.vector3(-13406,111065,1945), util.vector3(-11945,108055,1664), util.vector3(-10521,105035,2023), util.vector3(-8791,103047,3186), util.vector3(-6806,101359,4499), util.vector3(-7173,100235,4835), util.vector3(-8550,98507,5768), util.vector3(-9466,96913,5776), util.vector3(-10429,96113,5543), util.vector3(-13419,95696,4331), util.vector3(-15594,94884,4158), util.vector3(-16952,93028,4377), util.vector3(-18299,90492,4410), util.vector3(-19163,88010,3691), util.vector3(-20274,86586,3162), util.vector3(-21904,84576,3267), util.vector3(-21572,81752,3697), util.vector3(-21507,79863,5362), util.vector3(-21484,78543,5839), util.vector3(-22150,74456,5323), util.vector3(-23156,71815,5374), util.vector3(-24471,69072,5201), util.vector3(-24537,66811,4367), util.vector3(-23860,64067,3560), util.vector3(-21819,60953,3263), util.vector3(-19398,57748,3165), util.vector3(-17958,55612,2816), util.vector3(-17941,54701,2876) },
    },
    ['Gnisis'] = {
      sort = 2,
      cost = 14,
      startPoint = util.vector3(-66773, 135331, 1175),
      endPoint = util.vector3(-86824, 89359, 1030), 
      points = { util.vector3(-66877,135873,1093), util.vector3(-67369,136360,1003), util.vector3(-68365,137030,841), util.vector3(-68970,137823,713), util.vector3(-70102,138825,457), util.vector3(-71378,139255,361), util.vector3(-72600,139406,440), util.vector3(-75215,138852,624), util.vector3(-78287,137426,663), util.vector3(-84156,133759,579), util.vector3(-88803,130716,578), util.vector3(-92149,127827,578), util.vector3(-99683,123019,543), util.vector3(-100676,122024,510), util.vector3(-100671,119872,536), util.vector3(-100286,117452,639), util.vector3(-100296,115695,892), util.vector3(-100306,114191,964), util.vector3(-100925,113029,1131), util.vector3(-100832,112201,1338), util.vector3(-99951,111180,1614), util.vector3(-100163,109782,1967), util.vector3(-100473,107950,1830), util.vector3(-100780,105809,1619), util.vector3(-101248,103897,2114), util.vector3(-101451,102902,2277), util.vector3(-101835,100422,2072), util.vector3(-101034,98845,1723), util.vector3(-100373,96621,773), util.vector3(-100368,95104,422), util.vector3(-101132,93052,573), util.vector3(-101976,90610,694), util.vector3(-101769,89058,586), util.vector3(-99948,87500,601), util.vector3(-97304,87068,660), util.vector3(-93220,87299,818), util.vector3(-87959,87426,873), util.vector3(-84751,87398,962), util.vector3(-81763,87586,1371), util.vector3(-79768,88840,2163), util.vector3(-79788,90768,2821), util.vector3(-81480,91989,3131), util.vector3(-82999,91502,2906), util.vector3(-84626,90018,2028), util.vector3(-85840,89094,1267), util.vector3(-86024,89052,1232), util.vector3(-86648,89048,1267) },
    },
  },
}

return {
    engineHandlers = {
        onActivate = function(object, actor)
          if actor.recordId == 'player' and object.type == types.NPC then
            core.sendGlobalEvent('SetActiveTravelData', { tData = travelData[object.recordId] } )
            world.players[1]:sendEvent('SetActiveTravelData', { tData = travelData[object.recordId] } )
          end
        end,
        onPlayerAdded = function (player) 
          local travelActorsList = {}
          for k, v in pairs(travelData) do
            travelActorsList[k] = k
            --table.insert(travelActorsList, k)
          end
          world.players[1]:sendEvent('GetListOfTravelActors', { list = travelActorsList } )
        end
    },
    eventHandlers = { 
      
    }
}

