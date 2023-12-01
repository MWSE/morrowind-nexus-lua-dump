local this = {}

-- if youre playing a different game (eg starwind), you can specify transporters and their lights here
-- if you would like to include your patch into transporter_lights, please send me your patch so i can include it here

-- key : class id of transporters
-- val : item id of lights to equip
this.lights = {
    ["gondolier"] = "light_com_lantern_02",
    ["shipmaster"] = "light_com_lantern_02",
    ["caravaner"] = "torch_256"
}

this.alternateLights = {
    "torch_256",
    "light_com_lantern_02",
    "light_de_lantern_01",
    "light_de_lantern_05",
    "light_de_lantern_14",
    "light_de_lantern_10"
}




return this
