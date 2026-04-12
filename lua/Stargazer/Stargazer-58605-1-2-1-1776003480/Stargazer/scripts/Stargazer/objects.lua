local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2

local objects = {}

local akatosh = {
  type = ui.TYPE.Image,
  props = {
    id = "akatosh",
    resource = ui.texture{path="textures/planet/Akatosh.dds"},
    size = v2(25,25),
  },
}

local data_akatosh = {
  name = "Akatosh",
  desc = "The Dragon God of Time. Chief among the gods, with mastery over the flow of time. Associated with dragons and the qualities of endurance and virtuous service.",
  eye = 8,
  buffs = {
    {name={'fortifyskill'},extra={'heavyarmor'},max=25},
    {name={'fortifyhealth'},max=25},
  },
}

objects["akatosh"] = {
  layout = akatosh,
  data = data_akatosh
}


local arkay = {
  type = ui.TYPE.Image,
  props = {
    id = "arkay",
    resource = ui.texture{path="textures/planet/Arkay.dds"},
    size = v2(25,25),
  },
}

local data_arkay = {
  name = "Arkay",
  desc = "The Mortal's God. God of cycles, particularly that of birth and death. Presides over funerals and burial rites, as well as ushering in the changes of the seasons.",
  eye = 12,
  buffs = {
    {name = {'fortifyskill'},extra={'restoration'},max=25},
    {name = {'fortifyskill'},extra={'marksman'},max=25},
  },
}

objects["arkay"] = {
  layout = arkay,
  data = data_arkay
}


local dibella = {
  type = ui.TYPE.Image,
  props = {
    id = "dibella",
    resource = ui.texture{path="textures/planet/Dibella.dds"},
    size = v2(25,25),
  },
}

local data_dibella = {
  name = "Dibella",
  desc = "Goddess of beauty and art, and one of the most popular of the Divines. Widespread cults are dedicated to both healing and sexual instruction.",
  buffs = {
    {name = {'fortifyskill'},extra={'speechcraft'},max=25},
    {name = {'fortifyattribute'},extra={'luck'},max=25},
  },
}

objects["dibella"] = {
  layout = dibella,
  data = data_dibella
}


local julianos = {
  type = ui.TYPE.Image,
  props = {
    id = "julianos",
    resource = ui.texture{path="textures/planet/Julianos.dds"},
    size = v2(25,25),
  },
}

local data_julianos = {
  name = "Julianos",
  desc = "God of logic, wisdom, and the arts of magic. His temples act as educational institutions in literature, history, and law.",
  eye = 4,
  buffs = {
    {name = {'fortifyattribute'},extra={'intelligence'},max=25},
    {name = {'fortifymagicka'},max=25},
  },
}

objects["julianos"] = {
  layout = julianos,
  data = data_julianos
}


local kynareth = {
  type = ui.TYPE.Image,
  props = {
    id = "kynareth",
    resource = ui.texture{path="textures/planet/Kynereth.dds"},
    size = v2(25,25),
  },
}

local data_kynareth = {
  name = "Kynareth",
  desc = "Goddess of the heavens, winds, and rain. Patron of sailors and travelers, and often propitiated for good fortune in life.",
  buffs = {
    {name = {'fortifyattribute'},extra={'agility'},max=25},
    {name = {'fortifyattribute'},extra={'speed'},max=25},
  },
}

objects["kynareth"] = {
  layout = kynareth,
  data = data_kynareth
}


local mara = {
  type = ui.TYPE.Image,
  props = {
    id = "mara",
    resource = ui.texture{path="textures/planet/Mara.dds"},
    size = v2(25,25),
  },
}

local data_mara = {
  name = "Mara",
  desc = "The Mother-Goddess. Goddess of love, compassion, and the bounty of nature. Presides over marriage ceremonies, befitting her ancient origins as a fertility goddess.",
  buffs = {
    {name = {'fortifyattribute'},extra={'personality'},max=25},
    {name = {'fortifyskill'},extra={'speechcraft'},max=25},
  },
}

objects["mara"] = {
  layout = mara,
  data = data_mara
}


local necromancer = {
  type = ui.TYPE.Image,
  props = {
    id = "necromancer",
    resource = ui.texture{path="textures/planet/necromancer.dds"},
    size = v2(25,25),
  },
}

local data_necromancer = {
  name = "necromancer",
  desc = "Moon and the body of the God of Worms Mannimarco.",
  buffs = {
    {name = {'fortifyskill'},extra={'conjuration'},max=25},
    {name = {'fortifyskill'},extra={'illusion'},max=25},
  },
}

objects["necromancer"] = {
  layout = necromancer,
  data = data_necromancer
}


local stendarr = {
  type = ui.TYPE.Image,
  props = {
    id = "stendarr",
    resource = ui.texture{path="textures/planet/Stendarr.dds"},
    size = v2(25,25),
  },
}

local data_stendarr = {
  name = "Stendarr",
  desc = "The Steadfast. God of mercy, justice, and righteousness. Patron of all those who wield righteous might to protect the weak, from emperors to holy warriors.",
  buffs = {
    {name = {'fortifyattribute'},extra={'strength'},max=25},
    {name = {'fortifyattribute'},extra={'endurance'},max=25},
  },
}

objects["stendarr"] = {
  layout = stendarr,
  data = data_stendarr
}


local zenithar = {
  type = ui.TYPE.Image,
  props = {
    id = "zenithar",
    resource = ui.texture{path="textures/planet/Zenithar.dds"},
    size = v2(25,25),
  },
}

local data_zenithar = {
  name = "Zenithar",
  desc = "The Trader God. God of work, commerce, and wealth, invoked for success in business ventures. Teaches prosperity through honest industry, rather than violence or deceit.",
  buffs = {
    {name = {'fortifyskill'},extra={'mercantile'},max=25},
    {name = {'fortifyskill'},extra={'armorer'},max=25},
  },
}

objects["zenithar"] = {
  layout = zenithar,
  data = data_zenithar
}

return objects