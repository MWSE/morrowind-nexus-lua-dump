local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2

local constellations = {}

local lady_const = {
  type = ui.TYPE.Widget,
  name = "lady",
  props = {
    position = v2(2500,500),
    size = v2(93,193),
    anchor = v2(0.5,0.5),
    nLines = 3,
    id = 9,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/Lady.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lady_1.png"},
        position = v2(14,106),
        size = v2(66,61),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lady_2.png"},
        position = v2(14,65),
        size = v2(45,42),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lady_3.png"},
        position = v2(47,22),
        size = v2(12,44),
        visible = false,
      },
    },
  },
}

local lady_points = {
  [1] = {pos=v2(80,167), lineIdx={2}},
  [2] = {pos=v2(14,106), lineIdx={2,3}},
  [3] = {pos=v2(59,66), lineIdx={3,4}},
  [4] = {pos=v2(47,22), lineIdx={4}},
}

local lady_data = {
  name="The Lady",
  chargeOf = 8,
  desc="The Lady is one of the Warrior's Charges and her Season is Heartfire. Those born under the sign of the Lady are kind and tolerant.",
  month = {id=9,name="Hearthfire"},
  buffs = {
    {name = {'fortifyattribute'},extra={'personality'},max=25},
    {name = {'fortifyattribute'},extra={'speechcraft'},max=25},
  },
}

constellations[9] = {
  const = lady_const,
  points = lady_points,
  data = lady_data,
}

local apprentice_const = {
  type = ui.TYPE.Widget,
  name = "apprentice",
  props = {
    position = v2(2500,500),
    size = v2(89,193),
    anchor = v2(0.5,0.5),
    nLines = 9,
    id = 7,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice_1.png"},
        position = v2(34,79),
        size = v2(15,39),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice_2.png"},
        position = v2(12,79),
        size = v2(23,11),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice_3.png"},
        position = v2(6,71),
        size = v2(7,18),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice_4.png"},
        position = v2(6,70),
        size = v2(28,10),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice_5.png"},
        position = v2(35,70),
        size = v2(46,10),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice_6.png"},
        position = v2(67,44),
        size = v2(14,27),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice_7.png"},
        position = v2(67,32),
        size = v2(7,13),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice_8.png"},
        position = v2(34,44),
        size = v2(34,36),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/apprentice_9.png"},
        position = v2(25,16),
        size = v2(11,64),
        visible = false,
      },
    },
  },
}

local apprentice_points = {
  [1] = {pos=v2(49,119), lineIdx={2}},
  [2] = {pos=v2(35,80), lineIdx={2,3,5,6,9,10}},
  [3] = {pos=v2(12,89), lineIdx={3,4}},
  [4] = {pos=v2(7,71), lineIdx={4,5}},
  [5] = {pos=v2(80,71), lineIdx={6,7}},
  [6] = {pos=v2(67,45), lineIdx={7,8,9}},
  [7] = {pos=v2(74,32), lineIdx={8}},
  [8] = {pos=v2(25,15), lineIdx={10}},
}

local apprentice_data = {
  name="The Apprentice",
  chargeOf = 4,
  desc="The Apprentice's Season is Sun's Height. Those born under the sign of the apprentice have a special affinity for magick of all kinds, but are more vulnerable to magick as well.",
  month = {id=7,name="Sun's Height"},
  buffs = {
    {name = {'fortifyattribute'},extra={'willpower'},max=25},
    {name = {'fortifymagicka'},max=50,scale=2},
  },
}

constellations[7] = {
  const = apprentice_const,
  points = apprentice_points,
  data = apprentice_data,
}

local atronach_const = {
  type = ui.TYPE.Widget,
  name = "atronach",
  props = {
    position = v2(2500,500),
    size = v2(118,188),
    anchor = v2(0.5,0.5),
    nLines = 10,
    id = 11,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_1.png"},
        position = v2(88,48),
        size = v2(16,46),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_2.png"},
        position = v2(77,25),
        size = v2(27,24),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_3.png"},
        position = v2(46,21),
        size = v2(31,6),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_4.png"},
        position = v2(37,21),
        size = v2(10,21),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_5.png"},
        position = v2(36,42),
        size = v2(3,33),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_6.png"},
        position = v2(36,74),
        size = v2(13,16),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_7.png"},
        position = v2(48,90),
        size = v2(5,29),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_8.png"},
        position = v2(48,90),
        size = v2(31,29),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_9.png"},
        position = v2(70,60),
        size = v2(10,59),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/atronach_10.png"},
        position = v2(70,25),
        size = v2(8,35),
        visible = false,
      },
    },
  },
}

local atronach_points = {
  [1] = {pos=v2(89,94), lineIdx={2}},
  [2] = {pos=v2(104,49), lineIdx={2,3}},
  [3] = {pos=v2(78,26), lineIdx={3,4,11}},
  [4] = {pos=v2(47,22), lineIdx={4,5}},
  [5] = {pos=v2(38,42), lineIdx={5,6}},
  [6] = {pos=v2(37,76), lineIdx={6,7}},
  [7] = {pos=v2(50,92), lineIdx={7,8,9}},
  [8] = {pos=v2(52,120), lineIdx={8}},
  [9] = {pos=v2(79,119), lineIdx={9,10}},
  [10] = {pos=v2(71,60), lineIdx={10,11}},
}

local atronach_data = {
  name="The Atronach",
  chargeOf = 4,
  desc="The Atronach (often called the Golem) is one of the Mage's Charges. Its season is Sun's Dusk. Those born under this sign are natural sorcerers with deep reserves of magicka, but they cannot generate magicka of their own.",
  month = {id=11,name="Sun's Dusk"},
  buffs = {
    {name={'fortifymagicka'},max=25},
    {name={'spellabsorption'},max=25},
  },
}

constellations[11] = {
  const = atronach_const,
  points = atronach_points,
  data = atronach_data,
}

local lord_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(80,201),
    anchor = v2(0.5,0.5),
    nLines = 14,
    id = 3,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_1.png"},
        position = v2(22,118),
        size = v2(3,11),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_2.png"},
        position = v2(24,122),
        size = v2(12,7),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_3.png"},
        position = v2(34,122),
        size = v2(14,7),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_4.png"},
        position = v2(48,111),
        size = v2(12,17),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_5.png"},
        position = v2(34,109),
        size = v2(7,13),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_6.png"},
        position = v2(39,91),
        size = v2(2,18),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_7.png"},
        position = v2(39,90),
        size = v2(13,10),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_8.png"},
        position = v2(24,90),
        size = v2(16,2),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_9.png"},
        position = v2(23,68),
        size = v2(22,23),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_10.png"},
        position = v2(43,50),
        size = v2(4,19),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_11.png"},
        position = v2(46,49),
        size = v2(21,14),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_12.png"},
        position = v2(21,49),
        size = v2(25,7),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_13.png"},
        position = v2(44,36),
        size = v2(3,14),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lord_14.png"},
        position = v2(36,35),
        size = v2(9,2),
        visible = false,
      },
    },
  }
}

local lord_points = {
  [1] = {pos=v2(23,118), lineIdx={2}},
  [2] = {pos=v2(24,128), lineIdx={2,3}},
  [3] = {pos=v2(35,122), lineIdx={3,4,6}},
  [4] = {pos=v2(49,128), lineIdx={4,5}},
  [5] = {pos=v2(59,112), lineIdx={5}},
  [6] = {pos=v2(40,108), lineIdx={6,7}},
  [7] = {pos=v2(40,91), lineIdx={7,8,9}},
  [8] = {pos=v2(52,100), lineIdx={7,8}},
  [9] = {pos=v2(24,91), lineIdx={9,10}},
  [10] = {pos=v2(44,69), lineIdx={10,11}},
  [11] = {pos=v2(45,50), lineIdx={11,12,13,14}},
  [12] = {pos=v2(66,63), lineIdx={12}},
  [13] = {pos=v2(21,56), lineIdx={13}},
  [14] = {pos=v2(45,36), lineIdx={14,15}},
  [15] = {pos=v2(36,35), lineIdx={15}},
}

local lord_data = {
  name="The Lord",
  chargeOf = 8,
  desc="The Lord's Season is First Seed and he oversees all of Tamriel during the planting. Those born under the sign of the Lord are stronger and healthier than those born under other signs.",
  month = {id=3,name="First Seed"},
  buffs = {
    {name={'fortifyskill','fortifyskill','fortifyskill'},extra={'lightarmor','mediumarmor','heavyarmor'},max=25},
    {name={'fortifyhealth'},max=25},
  },
}

constellations[3] = {
  const = lord_const,
  points = lord_points,
  data = lord_data,
}


local lover_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(92,196),
    anchor = v2(0.5,0.5),
    nLines = 11,
    id = 2,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_1.png"},
        position = v2(27,117),
        size = v2(23,17),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_2.png"},
        position = v2(49,91),
        size = v2(4,42),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_3.png"},
        position = v2(52,90),
        size = v2(11,3),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_4.png"},
        position = v2(58,73),
        size = v2(6,19),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_5.png"},
        position = v2(58,62),
        size = v2(10,12),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_6.png"},
        position = v2(58,45),
        size = v2(10,18),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_7.png"},
        position = v2(33,42),
        size = v2(25,4),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_8.png"},
        position = v2(22,42),
        size = v2(12,10),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_9.png"},
        position = v2(16,51),
        size = v2(7,21),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_10.png"},
        position = v2(17,72),
        size = v2(10,11),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/lover_11.png"},
        position = v2(26,71),
        size = v2(15,11),
        visible = false,
      },
    },
  }
}

local lover_points = {
  [1] = {pos=v2(27,117), lineIdx={2}},
  [2] = {pos=v2(50,133), lineIdx={2,3}},
  [3] = {pos=v2(53,91), lineIdx={3,4}},
  [4] = {pos=v2(64,92), lineIdx={4,5}},
  [5] = {pos=v2(59,73), lineIdx={5,6}},
  [6] = {pos=v2(68,63), lineIdx={6,7}},
  [7] = {pos=v2(59,45), lineIdx={7,8}},
  [8] = {pos=v2(34,43), lineIdx={8,9}},
  [9] = {pos=v2(22,52), lineIdx={9,10}},
  [10] = {pos=v2(17,72), lineIdx={10,11}},
  [11] = {pos=v2(27,82), lineIdx={11,12}},
  [12] = {pos=v2(41,72), lineIdx={12}},
}

local lover_data = {
  name="The Lover",
  chargeOf = 12,
  desc="The Lover is one of the Thief's Charges and her season is Sun's Dawn. Those born under the sign of the Lover are graceful and passionate.",
  month = {id=2,name="Sun's Dawn"},
  buffs = {
    {name = {'fortifyattribute'},extra={'agility'},max=25},
    {name={'resistparalysis'},max=50,scale=2},
  },
}

constellations[2] = {
  const = lover_const,
  points = lover_points,
  data = lover_data,
}

local mage_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(193,180),
    anchor = v2(0.5,0.5),
    nLines = 24,
    id = 4,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_1.png"},
        position = v2(12,39),
        size = v2(31,48),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_2.png"},
        position = v2(34,18),
        size = v2(10,21),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_3.png"},
        position = v2(42,39),
        size = v2(18,44),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_4.png"},
        position = v2(11,83),
        size = v2(49,58),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_5.png"},
        position = v2(11,140),
        size = v2(43,29),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_6.png"},
        position = v2(52,131),
        size = v2(26,38),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_7.png"},
        position = v2(58,83),
        size = v2(21,49),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_8.png"},
        position = v2(78,112),
        size = v2(14,20),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_9.png"},
        position = v2(90,101),
        size = v2(12,12),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_10.png"},
        position = v2(80,76),
        size = v2(12,36),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_11.png"},
        position = v2(101,76),
        size = v2(4,25),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_12.png"},
        position = v2(81,75),
        size = v2(23,2),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_13.png"},
        position = v2(103,45),
        size = v2(12,31),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_14.png"},
        position = v2(114,44),
        size = v2(33,31),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_15.png"},
        position = v2(146,61),
        size = v2(22,15),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_16.png"},
        position = v2(167,28),
        size = v2(13,33),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_17.png"},
        position = v2(114,27),
        size = v2(65,18),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_18.png"},
        position = v2(100,38),
        size = v2(15,7),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_19.png"},
        position = v2(99,27),
        size = v2(2,12),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_20.png"},
        position = v2(82,22),
        size = v2(18,6),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_21.png"},
        position = v2(80,12),
        size = v2(3,11),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_22.png"},
        position = v2(79,39),
        size = v2(21,15),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_23.png"},
        position = v2(79,53),
        size = v2(2,24),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/mage_24.png"},
        position = v2(43,38),
        size = v2(37,15),
        visible = false,
      },
    },
  }
}

local mage_points = {
  [1] = {pos=v2(13,87), lineIdx={2}},
  [2] = {pos=v2(44,40), lineIdx={2,3,4,25}},
  [3] = {pos=v2(35,19), lineIdx={3}},
  [4] = {pos=v2(58,83), lineIdx={4,5,8}},
  [5] = {pos=v2(11,140), lineIdx={5,6}},
  [6] = {pos=v2(54,169), lineIdx={6,7}},
  [7] = {pos=v2(78,131), lineIdx={7,8,9}},
  [8] = {pos=v2(91,112), lineIdx={9,10,11}},
  [9] = {pos=v2(102,101), lineIdx={10,12}},
  [10] = {pos=v2(81,76), lineIdx={11,13,24}},
  [11] = {pos=v2(104,76), lineIdx={12,13,14}},
  [12] = {pos=v2(114,45), lineIdx={14,19,15,18}},
  [13] = {pos=v2(146,75), lineIdx={15,16}},
  [14] = {pos=v2(167,61), lineIdx={16,17}},
  [15] = {pos=v2(179,28), lineIdx={17,18}},
  [16] = {pos=v2(100,39), lineIdx={19,20,23}},
  [17] = {pos=v2(100,27), lineIdx={20,21}, eye = true},
  [18] = {pos=v2(81,12), lineIdx={22}},
  [19] = {pos=v2(80,53), lineIdx={23,24,25}},
  [20] = {pos=v2(82,23), lineIdx={22,21}},
}

local mage_data = {
  name="The Mage",
  guardian=true,
  charges = {1,7,11},
  desc="The Mage is a Guardian Constellation whose Season is Rain's Hand when magicka was first used by men. His Charges are the Apprentice, the Golem, and the Ritual. Those born under the Mage have more magicka and talent for all kinds of spellcasting, but are often arrogant and absent-minded.",
  month = {id=4,name="Rain's Hand"},
  buffs = {
    {name = {'fortifyattribute'},extra={'intelligence'},max=25},
    {name={'fortifymaximummagicka'},max=25},
  },
}

constellations[4] = {
  const = mage_const,
  points = mage_points,
  data = mage_data,
}

local ritual_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(173,161),
    anchor = v2(0.5,0.5),
    nLines = 6,
    id = 1,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/ritual.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/ritual_1.png"},
        position = v2(52,10),
        size = v2(31,18),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/ritual_2.png"},
        position = v2(81,10),
        size = v2(54,12),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/ritual_3.png"},
        position = v2(100,21),
        size = v2(35,51),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/ritual_4.png"},
        position = v2(100,70),
        size = v2(54,25),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/ritual_5.png"},
        position = v2(151,93),
        size = v2(3,28),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/ritual_6.png"},
        position = v2(91,119),
        size = v2(62,18),
        visible = false,
      },
    },
  }
}

local ritual_points = {
  [1] = {pos=v2(53,27), lineIdx={2}},
  [2] = {pos=v2(82,11), lineIdx={2,3}},
  [3] = {pos=v2(134,22), lineIdx={3,4}},
  [4] = {pos=v2(101,71), lineIdx={4,5}},
  [5] = {pos=v2(153,94), lineIdx={5,6}},
  [6] = {pos=v2(152,120), lineIdx={6,7}},
  [7] = {pos=v2(92,136), lineIdx={7}},
}

local ritual_data = {
  name="The Ritual",
  chargeOf = 4,
  desc="The Ritual is one of the Mage's Charges and its Season is Morning Star. Those born under this sign have a variety of abilities depending on the aspects of the moons and the Divines.",
  month = {id=1,name="Morning Star"},
  buffs = {
    {name = {'fortifyskill'},extra={'mysticism'},max=25},
    {name = {'fortifyskill'},extra={'conjuration'},max=25},
  },
}

constellations[1] = {
  const = ritual_const,
  points = ritual_points,
  data = ritual_data,
}

local serpent_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(133,184),
    anchor = v2(0.5,0.5),
    nLines = 3,
    id = 13,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/serpent.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/serpent_1.png"},
        position = v2(78,90),
        size = v2(15,80),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/serpent_2.png"},
        position = v2(30,90),
        size = v2(51,17),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/serpent_3.png"},
        position = v2(78,20),
        size = v2(25,72),
        visible = false,
      },
    },
  }
}

local serpent_points = {
  [1] = {pos=v2(92,169), lineIdx={2}},
  [2] = {pos=v2(79,91), lineIdx={2,3,4}},
  [3] = {pos=v2(31,106), lineIdx={3}},
  [4] = {pos=v2(102,21), lineIdx={4}},
}

-- What do i do with you feller :O
local serpent_data = {
  name="The Serpent",
  desc="The Ritual is one of the Mage's Charges and its Season is Morning Star. Those born under this sign have a variety of abilities depending on the aspects of the moons and the Divines.",
  buffs = {
    {name={'resistpoison'},max=25},
    {name={'resistpoison'},max=25},
  },
}

constellations[13] = {
  const = serpent_const,
  points = serpent_points,
  data = serpent_data,
}

local shadow_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(110,180),
    anchor = v2(0.5,0.5),
    nLines = 4,
    id = 5,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/shadow.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/shadow_1.png"},
        position = v2(8,85),
        size = v2(41,41),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/shadow_2.png"},
        position = v2(47,87),
        size = v2(39,40),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/shadow_3.png"},
        position = v2(66,54),
        size = v2(20,34),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/shadow_4.png"},
        position = v2(60,22),
        size = v2(8,34),
        visible = false,
      },
    },
  }
}

local shadow_points = {
  [1] = {pos=v2(9,86), lineIdx={2}},
  [2] = {pos=v2(48,125), lineIdx={2,3}},
  [3] = {pos=v2(86,88), lineIdx={3,4}},
  [4] = {pos=v2(67,55), lineIdx={4,5}},
  [5] = {pos=v2(61,23), lineIdx={5}},
}

local shadow_data = {
  name="The Shadow",
  chargeOf = 12,
  desc="The Shadow's Season is Second Seed. The Shadow grants those born under her sign the ability to hide in shadows.",
  month = {id=5,name="Second Seed"},
  buffs = {
    {name={'chameleon'},max=25},
    {name={'nighteye'},max=25},
  },
}

constellations[5] = {
  const = shadow_const,
  points = shadow_points,
  data = shadow_data,
}

local steed_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(150,182),
    anchor = v2(0.5,0.5),
    nLines = 8,
    id = 6,
  },
  content = ui.content{
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/steed.png"},
        position = v2(0,0),
        relativeSize = v2(1,1),
        alpha = 0,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/steed_1.png"},
        position = v2(82,113),
        size = v2(6,33),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/steed_2.png"},
        position = v2(29,97),
        size = v2(33,28),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/steed_3.png"},
        position = v2(60,97),
        size = v2(24,18),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/steed_4.png"},
        position = v2(82,73),
        size = v2(12,41),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/steed_5.png"},
        position = v2(60,73),
        size = v2(34,25),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/steed_6.png"},
        position = v2(92,51),
        size = v2(48,24),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/steed_7.png"},
        position = v2(47,54),
        size = v2(47,21),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/steed_8.png"},
        position = v2(47,23),
        size = v2(57,33),
        visible = false,
      },
    },
  },
}

local steed_points = {
  [1] = {pos=v2(87,145), lineIdx={2}},
  [2] = {pos=v2(83,114), lineIdx={2,4,5}},
  [3] = {pos=v2(30,123), lineIdx={3}},
  [4] = {pos=v2(61,98), lineIdx={3,4,6}},
  [5] = {pos=v2(93,74), lineIdx={5,6,7,8}},
  [6] = {pos=v2(139,52), lineIdx={7}},
  [7] = {pos=v2(48,55), lineIdx={8,9}},
  [8] = {pos=v2(103,24), lineIdx={9}},
}

local steed_data = {
  name="The Steed",
  chargeOf = 8,
  desc="The Steed is one of the Warrior's Charges, and her Season is Mid Year. Those born under the sign of the Steed are impatient and always hurrying from one place to another.",
  month = {id=6,name="Mid Year"},
  buffs = {
    {name = {'fortifyskill'},extra={'athletics'},max=25},
    {name = {'fortifyskill'},extra={'acrobatics'},max=25},
  },
}

constellations[6] = {
  const = steed_const,
  points = steed_points,
  data = steed_data,
}

local thief_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(245,164),
    anchor = v2(0.5,0.5),
    nLines = 20,
    id = 12,
  },
content = ui.content{
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief.png"},
      position = v2(0,0),
      relativeSize = v2(1,1),
      alpha = 0,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_1.png"},
      position = v2(89,119),
      size = v2(31,26),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_2.png"},
      position = v2(89,85),
      size = v2(62,35),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_3.png"},
      position = v2(186,98),
      size = v2(32,19),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_4.png"},
      position = v2(181,66),
      size = v2(7,34),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_5.png"},
      position = v2(149,74),
      size = v2(18,13),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_6.png"},
      position = v2(165,66),
      size = v2(17,10),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_7.png"},
      position = v2(149,85),
      size = v2(16,14),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_8.png"},
      position = v2(104,60),
      size = v2(47,27),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_9.png"},
      position = v2(149,51),
      size = v2(34,17),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_10.png"},
      position = v2(149,51),
      size = v2(19,25),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_11.png"},
      position = v2(104,51),
      size = v2(47,11),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_12.png"},
      position = v2(44,53),
      size = v2(61,9),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_13.png"},
      position = v2(80,60),
      size = v2(25,16),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_14.png"},
      position = v2(71,74),
      size = v2(11,20),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_15.png"},
      position = v2(91,41),
      size = v2(15,21),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_16.png"},
      position = v2(104,41),
      size = v2(3,21),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_17.png"},
      position = v2(91,10),
      size = v2(35,33),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_18.png"},
      position = v2(105,10),
      size = v2(21,33),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_19.png"},
      position = v2(104,10),
      size = v2(95,52),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/thief_20.png"},
      position = v2(197,10),
      size = v2(19,68),
      visible = false,
    },
  },
}
}

local thief_points = {
  [1] = {pos=v2(119,144), lineIdx={2}},
  [2] = {pos=v2(90,120), lineIdx={2,3}},
  [3] = {pos=v2(150,86), lineIdx={3,6,8,9}},
  [4] = {pos=v2(217,117), lineIdx={4}},
  [5] = {pos=v2(187,99), lineIdx={4,5}},
  [6] = {pos=v2(182,67), lineIdx={5,7,10}},
  [7] = {pos=v2(166,75), lineIdx={6,7,11}},
  [8] = {pos=v2(164,99), lineIdx={8}},
  [9] = {pos=v2(105,61), lineIdx={9,12,13,14,16,17,20}},
  [10] = {pos=v2(149,52), lineIdx={10,11,12}},
  [11] = {pos=v2(45,54), lineIdx={13}},
  [12] = {pos=v2(81,75), lineIdx={14,15}},
  [13] = {pos=v2(72,93), lineIdx={15}},
  [14] = {pos=v2(92,42), lineIdx={16,18}, eye = true},
  [15] = {pos=v2(106,42), lineIdx={17,19}},
  [16] = {pos=v2(125,11), lineIdx={18,19}},
  [17] = {pos=v2(198,10), lineIdx={20,21}},
  [18] = {pos=v2(215,77), lineIdx={21}},
}

local thief_data = {
  name="The Thief",
  guardian = true,
  charges = {2,5,10},
  desc="The Thief is the last Guardian Constellation, and her Season is the darkest month of Evening Star. Her Charges are the Lover, the Shadow, and the Tower. Those born under the sign of the Thief are not typically thieves, though they take risks more often and only rarely come to harm. They will run out of luck eventually, however, and rarely live as long as those born under other signs.",
  month = {id=12,name="Evening Star"},
  buffs = {
    {name={'fortifyskill'},extra={'sneak'},max=25},
    {name={'sanctuary'},max=25},
  },
}

constellations[12] = {
  const = thief_const,
  points = thief_points,
  data = thief_data,
}

local tower_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(104,196),
    anchor = v2(0.5,0.5),
    nLines = 9,
    id = 10,
  },
content = ui.content{
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower.png"},
      position = v2(0,0),
      relativeSize = v2(1,1),
      alpha = 0,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower_1.png"},
      position = v2(13,168),
      size = v2(37,3),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower_2.png"},
      position = v2(48,169),
      size = v2(36,2),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower_3.png"},
      position = v2(39,151),
      size = v2(12,20),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower_4.png"},
      position = v2(39,117),
      size = v2(10,36),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower_5.png"},
      position = v2(47,74),
      size = v2(10,45),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower_6.png"},
      position = v2(55,25),
      size = v2(6,51),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower_7.png"},
      position = v2(68,93),
      size = v2(15,2),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower_8.png"},
      position = v2(81,78),
      size = v2(11,16),
      visible = false,
    },
  },
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/tower_9.png"},
      position = v2(88,65),
      size = v2(4,15),
      visible = false,
    },
  },
}
}

local tower_points = {
  [1] = {pos=v2(14,169), lineIdx={2}},
  [2] = {pos=v2(49,170), lineIdx={2,3,4}},
  [3] = {pos=v2(83,170), lineIdx={3}},
  [4] = {pos=v2(40,152), lineIdx={4,5}},
  [5] = {pos=v2(48,117), lineIdx={5,6}},
  [6] = {pos=v2(56,75), lineIdx={6,7}},
  [7] = {pos=v2(60,26), lineIdx={7}},
  [8] = {pos=v2(69,94), lineIdx={8}},
  [9] = {pos=v2(82,94), lineIdx={8,9}},
  [10] = {pos=v2(91,79), lineIdx={9,10}},
  [11] = {pos=v2(89,66), lineIdx={10}},
  [12] = {pos=v2(14,125), lineIdx={}},
}

local tower_data = {
  name="The Tower",
  chargeOf = 12,
  desc="The Tower is one of the Thief's Charges and its Season is Frostfall. Those born under the sign of the Tower have a knack for finding gold and can open locks of all kinds.",
  month = {id=10,name="Frostfall"},
  buffs = {
    {name={'detectanimal','detectenchantment','detectkey'},max=25},
    {name={'shield'},max=25},
  },
}

constellations[10] = {
  const = tower_const,
  points = tower_points,
  data = tower_data,
}

local warrior_const = {
  type = ui.TYPE.Widget,
  props = {
    position = v2(2500,500),
    size = v2(200,180),
    anchor = v2(0.5,0.5),
    nLines = 32,
    id = 8,
  },
content = ui.content{
  {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture{path="textures/const/warrior.png"},
      position = v2(0,0),
      relativeSize = v2(1,1),
      alpha = 0,
    },
  },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_1.png"},
        position = v2(55,160),
        size = v2(17,9),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_2.png"},
        position = v2(60,137),
        size = v2(11,25),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_3.png"},
        position = v2(60,126),
        size = v2(29,13),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_4.png"},
        position = v2(87,126),
        size = v2(16,15),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_5.png"},
        position = v2(101,120),
        size = v2(16,21),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_6.png"},
        position = v2(115,120),
        size = v2(14,39),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_7.png"},
        position = v2(128,156),
        size = v2(22,3),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_8.png"},
        position = v2(133,128),
        size = v2(36,10),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_9.png"},
        position = v2(167,131),
        size = v2(19,7),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_10.png"},
        position = v2(184,107),
        size = v2(3,26),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_11.png"},
        position = v2(133,104),
        size = v2(18,26),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_12.png"},
        position = v2(150,104),
        size = v2(36,5),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_13.png"},
        position = v2(150,81),
        size = v2(9,25),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_14.png"},
        position = v2(156,81),
        size = v2(29,28),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_15.png"},
        position = v2(99,104),
        size = v2(53,2),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_16.png"},
        position = v2(22,101),
        size = v2(78,5),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_17.png"},
        position = v2(87,104),
        size = v2(13,24),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_18.png"},
        position = v2(99,104),
        size = v2(19,18),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_19.png"},
        position = v2(64,78),
        size = v2(37,28),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_20.png"},
        position = v2(52,50),
        size = v2(14,30),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_21.png"},
        position = v2(52,31),
        size = v2(13,20),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_22.png"},
        position = v2(99,65),
        size = v2(2,41),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_23.png"},
        position = v2(89,25),
        size = v2(12,42),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_24.png"},
        position = v2(99,47),
        size = v2(20,19),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_25.png"},
        position = v2(98,25),
        size = v2(21,25),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_26.png"},
        position = v2(117,47),
        size = v2(12,31),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_27.png"},
        position = v2(127,76),
        size = v2(21,19),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_28.png"},
        position = v2(146,52),
        size = v2(5,43),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_29.png"},
        position = v2(117,44),
        size = v2(18,5),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_30.png"},
        position = v2(133,44),
        size = v2(18,10),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_31.png"},
        position = v2(60,8),
        size = v2(31,19),
        visible = false,
      },
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{path="textures/const/warrior_32.png"},
        position = v2(98,10),
        size = v2(29,17),
        visible = false,
      },
    },
}
}

local warrior_points = {
  [1] = {pos=v2(56,168), lineIdx={2}},
  [2] = {pos=v2(71,161), lineIdx={2,3}},
  [3] = {pos=v2(61,138), lineIdx={3,4}},
  [4] = {pos=v2(88,127), lineIdx={4,5,18}},
  [5] = {pos=v2(102,140), lineIdx={5,6}},
  [6] = {pos=v2(116,121), lineIdx={6,7,19}},
  [7] = {pos=v2(129,158), lineIdx={7,8}},
  [8] = {pos=v2(149,157), lineIdx={8}},
  [9] = {pos=v2(134,129), lineIdx={9,12}},
  [10] = {pos=v2(168,138), lineIdx={9,10}},
  [11] = {pos=v2(185,132), lineIdx={10,11}},
  [12] = {pos=v2(185,108), lineIdx={11,13,15}},
  [13] = {pos=v2(151,105), lineIdx={12,13,14,16}},
  [14] = {pos=v2(157,82), lineIdx={14,15}},
  [15] = {pos=v2(100,105), lineIdx={16,17,18,19,20,23}},
  [16] = {pos=v2(23,102), lineIdx={17}},
  [17] = {pos=v2(65,79), lineIdx={20,21}},
  [18] = {pos=v2(53,51), lineIdx={21,22}},
  [19] = {pos=v2(64,32), lineIdx={22}},
  [20] = {pos=v2(100,66), lineIdx={23,24,25}},
  [21] = {pos=v2(90,26), lineIdx={24,32}},
  [22] = {pos=v2(118,48), lineIdx={25,26,27,30}},
  [23] = {pos=v2(99,26), lineIdx={26,33}, eye = true},
  [24] = {pos=v2(128,77), lineIdx={27,28}},
  [25] = {pos=v2(147,94), lineIdx={28,29}},
  [26] = {pos=v2(150,53), lineIdx={29,31}},
  [27] = {pos=v2(134,45), lineIdx={30,31}},
  [28] = {pos=v2(61,9), lineIdx={32}},
  [29] = {pos=v2(126,11), lineIdx={33}},
}

local warrior_data = {
  name="The Warrior",
  guardian = true,
  charges = {3,6,9},
  desc="The Warrior is the first Guardian Constellation and he protects his charges during their Seasons. The Warrior's own season is Last Seed when his Strength is needed for the harvest. His Charges are the Lady, the Steed, and the Lord. Those born under the sign of the Warrior are skilled with weapons of all kinds, but prone to short tempers.",
  month = {id=8,name="Last Seed"},
  buffs = {
    {name = {'fortifyattribute'},extra={'strength'},max=25},
    {name = {'fortifyattack'},max=25},
  },
}

constellations[8] = {
  const = warrior_const,
  points = warrior_points,
  data = warrior_data,
}


-- add plantes (8 divines) (DONE)
-- add more plantes (daedra realms)
-- AKATOSH IS EYE OF WARRIOR
-- JULIANOS IS EYE OF MAGE
-- ARKAY IS EYE OF THIEF
-- MOONS MAN (PHASES) (withered corpses of lorkhan) nah
-- Theres a moon orbitin arkay (necromancer moon) (should be fine morrowind is after the warp in the west?)
-- shooting stars
-- azura star

-- gotta watch out for overlapping

return constellations