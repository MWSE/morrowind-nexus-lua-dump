local types = require("openmw.types")
return {
    zhac_aa_bar1y = {
        type = types.Miscellaneous,
        model = "meshes\\mc\\mc_adamantium_ingot.nif",
        name = "Bar",
        icon = "icons\\mc\\mc_adamantium_ingot.tga"
    },
    zhac_aa_daedricebony = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_dae_ebony_ingot",
        data = {
            weight = 2.0,
            value = 4000,
            flags = 0
        },
        name = "Daedric Ebony Ingot",
        mesh = "mc\\mc_dae_ebony_ingot.nif",
        icon = "mc\\mc_dae_ebony_ingot.tga"
    },
    zhac_aa_ingot_iron = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_iron_ingot",
        data = {
            weight = 2.0,
            value = 2,
            flags = 0
        },
        name = "Iron Ingot",
        mesh = "mc\\mc_iron_ingot.nif",
        icon = "mc\\mc_iron_ingot.tga"
    },
    ["mc_log_ash"] = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_log_ash",
        data = {
            weight = 5.0,
            value = 3,
            flags = 0
        },
        name = "Ash Log",
        mesh = "mc\\mc_log_ash.nif",
        icon = "mc\\mc_log_ash.tga"
    },
    ["mc_log_cypress"] = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_log_cypress",
        data = {
            weight = 5.0,
            value = 4,
            flags = 0
        },
        name = "Cypress Log",
        mesh = "mc\\mc_log_cypress.nif",
        icon = "mc\\mc_log_cypress.tga"
    },
    ["mc_log_hickory"] = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_log_hickory",
        data = {
            weight = 5.0,
            value = 4,
            flags = 0
        },
        name = "Hickory Log",
        mesh = "mc\\mc_log_hickory.nif",
        icon = "mc\\mc_log_hickory.tga"
    },
    ["mc_log_oak"] = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_log_oak",
        data = {
            weight = 5.0,
            value = 5,
            flags = 0
        },
        name = "Oak Log",
        mesh = "mc\\mc_log_oak.nif",
        icon = "mc\\mc_log_oak.tga"
    },
    ["mc_log_parasol"] = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_log_parasol",
        data = {
            weight = 5.0,
            value = 3,
            flags = 0
        },
        name = "Parasol Mushroom Log",
        mesh = "mc\\mc_log_parasol.nif",
        icon = "mc\\mc_log_parasol.tga"
    },
    ["mc_log_pine"] = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_log_pine",
        data = {
            weight = 5.0,
            value = 3,
            flags = 0
        },
        name = "Log",
        mesh = "mc\\mc_log_pine.nif",
        icon = "mc\\mc_log_pine.tga"
    },
    ["mc_log_scrap"] = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_log_scrap",
        data = {
            weight = 5.0,
            value = 2,
            flags = 0
        },
        name = "Scrap Log",
        mesh = "mc\\mc_log_scrap.nif",
        icon = "mc\\mc_log_scrap.tga"
    },
    ["mc_log_swirlwood"] = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_log_swirlwood",
        data = {
            weight = 5.0,
            value = 6,
            flags = 0
        },
        name = "Swirlwood Log",
        mesh = "mc\\mc_log_mahogany.nif",
        icon = "mc\\mc_log_mahogany.tga"
    },
    mc_silver_ore = {
        type = "MiscItem",
        flags = { 0, 0 },
        id = "mc_silver_ore",
        data = {
          weight = 5.0,
          value = 10,
        },
        name = "Stone Fragment",
        mesh = "mc\\mc_ore_silver.nif",
        icon = "mc\\mc_silver_ore.tga"
      }
}
