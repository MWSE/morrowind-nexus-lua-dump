local this = {}

-- if youre playing a different game (eg starwind), you can specify transporters and their lights here

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

this.help = [[
    info = Prints mod Info
    equipLight(actor, light) = Equips the light on the actor. Light can be gameObject or recordId
    listTransporters = List all transporters affected by `Transporter Lights`

    e.g.
    I.Pursuit_eqnx.info
    I.Pursuit_eqnx.equipLight(selected, "torch_256")
]]

return this
