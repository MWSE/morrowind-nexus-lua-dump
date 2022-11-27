local config = {}
-- crates not used yet:
-- ds22_crate_comberry
-- ds22_crate_ebonyequipment
-- ds22_crate_silk

-- crates used only once
-- ds22_crate_ashyams
-- ds22_crate_books
-- ds22_crate_sujamma

config.regions = {
    ["Bitter Coast Region"] = {
        neighboringRegions = {"West Gash Region","Roth Roryn","Ascadian Isles Region"},
        randomPriceMax = 1.15,
        randomPriceMin = 0.95,
        prices = {
            ["ds22_crate_fish"] = -0.25,
            ["ds22_crate_moonsugar"] = -0.05,
            ["ds22_crate_skooma"] = -0.1,
            ["ds22_crate_kwama"] = 0,
            ["ds22_crate_dwemerartefacts"] = 0,
            ["ds22_crate_ebony"] = 0,
            ["ds22_crate_matze"] = -0.1,
            ["ds22_crate_leather"] = -0.05,
            ["ds22_crate_leatherarmor"] = 0,
            ["ds22_crate_commonclothes"] = 0.1,
            
        }

    },
    ["Azura's Coast Region"] = {
        neighboringRegions = {"Sheogorad Region","Sundered Scar Region","Mephalan Vales Region","Helnim Fields Region","Molagreahd Region","Ascadian Isles Region","Grazelands Region","Molag Amur Region"},
        randomPriceMax = 1.1,
        randomPriceMin = 0.85,
        prices = {
            ["ds22_crate_fish"] = -0.15,
            ["ds22_crate_potions"] = -0.1,
            ["ds22_crate_muck"] = -0.2,
            ["ds22_crate_kwama"] = 0,
            ["ds22_crate_kresh"] = -0.15,
            ["ds22_crate_kreshfibercloth"] = -0.2,
            ["ds22_crate_marshemerrow"] = -0.1,
            ["ds22_crate_saltrice"] = -0.25,
            ["ds22_crate_bonemoldequipment"] = 0,
            ["ds22_crate_leather"] = -0.1,
            ["ds22_crate_leatherarmor"] = -0.15,
            ["ds22_crate_commonclothes"] = 0,
            ["ds22_crate_expensiveclothes"] = 0.1
        }
    },
    ["Molag Amur Region"] = {
        neighboringRegions = {"Ashlands Region","Azura's Coast Region","Ascadian Isles Region","West Gash Region","Grazelands Region"},
        randomPriceMax = 1.5,
        randomPriceMin = 1.25,
        prices = {
            ["ds22_crate_meat"] = -0.15,
            ["ds22_crate_bone"] = -0.2,
            ["ds22_crate_kwama"] = -0.25,
            ["ds22_crate_chitin"] = -0.15,
            ["ds22_crate_chitinequipment"] = 0,
            ["ds22_crate_commonclothes"] = 0.1
        }
    },
    ["Ashlands Region"] = {
        neighboringRegions = {"Red Mountain Region","West Gash Region","Molag Amur Region","Sheogorad Region","Grazelands Region"},
        randomPriceMax = 1.5,
        randomPriceMin = 1.1,
        prices = {
            ["ds22_crate_meat"] = -0.25,
            ["ds22_crate_bone"] = -0.25,
            ["ds22_crate_bonemoldequipment"] = -0.15,
            ["ds22_crate_kwama"] = -0.2,
            ["ds22_crate_ashyams"] = -0.25,
            ["ds22_crate_chitin"] = -0.2,
            ["ds22_crate_chitinequipment"] = -0.15,
            ["ds22_crate_ebony"] = -0.25,
            ["ds22_crate_glass"] = -0.15,
            ["ds22_crate_scuttle"] = -0.1,
            ["ds22_crate_dwemerartefacts"] = -0.15,
            ["ds22_crate_commonclothes"] = -0.1,
            ["ds22_crate_expensiveclothes"] = 0.1
        }
    },
    ["West Gash Region"] = {
        neighboringRegions = {"Ashlands Region","Julan-Shar Region","Solstheim, Hirstaang Forest","Ascadian Isles Region","Bitter Coast Region","Molag Amur Region"},
        randomPriceMax = 1.25,
        randomPriceMin = 0.9,
        prices = {
            ["ds22_crate_fish"] = -0.05,
            ["ds22_crate_potions"] = -0.1,
            ["ds22_crate_muck"] = -0.1,
            ["ds22_crate_kwama"] = -0.05,
            ["ds22_crate_kresh"] = -0.15,
            ["ds22_crate_kreshfibercloth"] = -0.25,
            ["ds22_crate_marshemerrow"] = -0.05,
            ["ds22_crate_saltrice"] = -0.05,
            ["ds22_crate_bonemoldequipment"] = -0.1,
            ["ds22_crate_ironequipment"] = 0.1,
            ["ds22_crate_leather"] = -0.25,
            ["ds22_crate_leatherarmor"] = -0.2,
            ["ds22_crate_dwemerartefacts"] = -0.1,
            ["ds22_crate_scuttle"] = -0.2,
            ["ds22_crate_commonclothes"] = -0.15,
            ["ds22_crate_expensiveclothes"] = 0.1
        }
    },
    ["Red Mountain Region"] = {
        neighboringRegions = {"Ashlands Region"},
        randomPriceMax = 3,
        randomPriceMin = 2,
        prices = {
            ["ds22_crate_ebony"] = -0.5,
            ["ds22_crate_glass"] = -0.5,
            ["ds22_crate_dwemerartefacts"] = -0.5,
        }
    },
    ["Ascadian Isles Region"] = {
        neighboringRegions = {"Molag Amur Region","Roth Roryn","Azura's Coast Region","Bitter Coast Region","West Gash Region"},
        randomPriceMax = 1.1,
        randomPriceMin = 0.75,
        prices = {
            ["ds22_crate_potions"] = -0.25,
            ["ds22_crate_muck"] = 0.2,
            ["ds22_crate_kwama"] = -0.1,
            ["ds22_crate_kreshfibercloth"] = 0.1,
            ["ds22_crate_marshemerrow"] = 0.1,
            ["ds22_crate_saltrice"] = 0.1,
            ["ds22_crate_ironequipment"] = 0,
            ["ds22_crate_steelequipment"] = 0,
            ["ds22_crate_silverequipment"] = 0,
            ["ds22_crate_leather"] = 0,
            ["ds22_crate_leatherarmor"] = 0,
            ["ds22_crate_scuttle"] = -0.1,
            ["ds22_crate_moonsugar"] = 0,
            ["ds22_crate_skooma"] = 0,
            ["ds22_crate_shein"] = -0.15,
            ["ds22_crate_greef"] = -0.15,
            ["ds22_crate_flin"] = -0.1,
            ["ds22_crate_cyrodilicbrandy"] = -0.1,
            ["ds22_crate_corkbulbs"] = -0.25,
            ["ds22_crate_fish"] = 0.1,
            ["ds22_crate_commonclothes"] = -0.2,
            ["ds22_crate_expensiveclothes"] = 0
        }
    },
    ["Grazelands Region"] = {
        neighboringRegions = {"Ashlands Region","Azura's Coast Region","Molag Amur Region","Sheogorad Region"},
        randomPriceMax = 1.25,
        randomPriceMin = 1.1,
        prices = {
            ["ds22_crate_potions"] = -0.2,
            ["ds22_crate_muck"] = 0.2,
            ["ds22_crate_kwama"] = -0.1,
            ["ds22_crate_kresh"] = -0.05,
            ["ds22_crate_kreshfibercloth"] = 0,
            ["ds22_crate_marshemerrow"] = -0.25,
            ["ds22_crate_saltrice"] = -0.25,
            ["ds22_crate_ironequipment"] = 0,
            ["ds22_crate_steelequipment"] = 0,
            ["ds22_crate_silverequipment"] = 0,
            ["ds22_crate_leatherarmor"] = 0,
            ["ds22_crate_chitinequipment"] = 0,
            ["ds22_crate_scuttle"] = -0.1,
            ["ds22_crate_moonsugar"] = 0,
            ["ds22_crate_skooma"] = 0,
            ["ds22_crate_dwemerartefacts"] = 0,
            ["ds22_crate_hacklelo"] = -0.25,
            ["ds22_crate_commonclothes"] = 0
        }
    },
    ["Sheogorad Region"] = {
        neighboringRegions = {"Ashlands Region","Azura's Coast Region","Grazelands Region"},
        randomPriceMax = 1.25,
        randomPriceMin = 0.95,
        prices = {
            ["ds22_crate_fish"] = -0.15,
            ["ds22_crate_leather"] = 0,
            ["ds22_crate_leatherarmor"] = 0.15,
            ["ds22_crate_commonclothes"] = -0.1,
            ["ds22_crate_dwemerartefacts"] = -0.25,
        }
    },
    ["Mournhold Region"] = {
        neighboringRegions = {"Alt Orethan Region"},
        randomPriceMax = 1.05,
        randomPriceMin = 0.75,
        prices = {
            ["ds22_crate_adamantium"] = -0.1,
            ["ds22_crate_adamantiumequipment"] = 0,
            ["ds22_crate_ironequipment"] = -0.2,
            ["ds22_crate_steelequipment"] = -0.2,
            ["ds22_crate_silverequipment"] = -0.2,
            ["ds22_crate_leatherarmor"] = 0,
            ["ds22_crate_bonemoldequipment"] = 0,
            ["ds22_crate_chitinequipment"] = 0,
            ["ds22_crate_kwama"] = -0.1,
            ["ds22_crate_kreshfibercloth"] = 0,
            ["ds22_crate_silkcloth"] = 0,
            ["ds22_crate_books"] = -0.25,
            ["ds22_crate_potions"] = -0.2,
            ["ds22_crate_shein"] = -0.05,
            ["ds22_crate_greef"] = -0.05,
            ["ds22_crate_sujamma"] = -0.15,
            ["ds22_crate_scuttle"] = -0.1,
            ["ds22_crate_matze"] = -0.15,
            ["ds22_crate_ebony"] = 0.1,
            ["ds22_crate_glass"] = 0.1,
            ["ds22_crate_dwemerartefacts"] = -0.1,
            ["ds22_crate_commonclothes"] = -0.1,
            ["ds22_crate_expensiveclothes"] = -0.2
        }
    },
    ["Solstheim, Felsaad Coast Region"] = {
        neighboringRegions = {"Solstheim, Isinfier Plains","Solstheim, Moesring Mountains"},
        randomPriceMax = 1.5,
        randomPriceMin = 1.15,
        prices = {
            ["ds22_crate_fish"] = -0.15,
            ["ds22_crate_fur"] = -0.25,
            ["ds22_crate_meat"] = -0.25,
            ["ds22_crate_ironequipment"] = 0.1,
            ["ds22_crate_steelequipment"] = 0.1,
            ["ds22_crate_silverequipment"] = 0,
            ["ds22_crate_nordicequipment"] = -0.25,
            ["ds22_crate_nordmead"] = -0.1,
            ["ds22_crate_commonclothes"] = -0.1

        }
    },
    ["Solstheim, Moesring Mountains"] = {
        neighboringRegions = {"Solstheim, Isinfier Plains","Solstheim, Felsaad Coast Region"},
        randomPriceMax = 1.75,
        randomPriceMin = 1.25,
        prices = {
            -- No trader?
            ["ds22_crate_fish"] = -0.1,
            ["ds22_crate_fur"] = -0.25,
            ["ds22_crate_meat"] = -0.25,
        }
    },
    ["Solstheim, Isinfier Plains"] = {
        neighboringRegions = {"Solstheim, Hirstaang Forest","Uld Vraech Region","Thirsk Region","Solstheim, Moesring Mountains","Solstheim, Felsaad Coast Region"},
        randomPriceMax = 1.4,
        randomPriceMin = 1.25,
        prices = {
            ["ds22_crate_fish"] = -0.2,
            ["ds22_crate_fur"] = -0.25,
            ["ds22_crate_meat"] = -0.25,
            ["ds22_crate_ironequipment"] = 0,
            ["ds22_crate_steelequipment"] = 0,
            ["ds22_crate_silverequipment"] = 0,
            ["ds22_crate_nordicequipment"] = 0,
            ["ds22_crate_nordmead"] = -0.1
        }
    },
    ["Solstheim, Hirstaang Forest"] = {
        neighboringRegions = {"West Gash Region","Uld Vraech Region","Julan-Shar Region","Solstheim, Isinfier Plains"},
        randomPriceMax = 1.3,
        randomPriceMin = 1.1,
        prices = {
            ["ds22_crate_fish"] = -0.1,
            ["ds22_crate_fur"] = -0.15,
            ["ds22_crate_meat"] = -0.2,
            ["ds22_crate_ironequipment"] = 0,
            ["ds22_crate_steelequipment"] = 0,
            ["ds22_crate_silverequipment"] = -0.1,
            ["ds22_crate_nordicequipment"] = -0.1,
            ["ds22_crate_nordmead"] = -0.2,
            ["ds22_crate_ebony"] = -0.25,
            ["ds22_crate_commonclothes"] = -0.1
        }
    },
    ["Solstheim, Brodir Grove Region"] = {
        neighboringRegions = {"Solstheim, Isinfier Plains", "Solstheim, Hirstaang Forest"},
        randomPriceMax = 1.3,
        randomPriceMin = 1.1,
        prices = {
            -- I don't think there's even a trader here
        }
    }, 
    ["Thirsk Region"] = {
        neighboringRegions = {"Solstheim, Isinfier Plains","Solstheim, Felsaad Coast Region"},
        randomPriceMax = 1.3,
        randomPriceMin = 1.1,
        prices = {
            ["ds22_crate_fish"] = 0,
            ["ds22_crate_fur"] = -0.2,
            ["ds22_crate_meat"] = -0.25,
            ["ds22_crate_ironequipment"] = -0.1,
            ["ds22_crate_steelequipment"] = -0.1,
            ["ds22_crate_silverequipment"] = -0.15,
            ["ds22_crate_nordicequipment"] = -0.15,
            ["ds22_crate_nordmead"] = -0.25
        }
    },

    -- TR Regions start here
    ["Shipal-Shin Region"] = {
        neighboringRegions = {"Thirr Valley Region","Deshaan Plains Region","Othreleth Woods Region"}
    },
    ["Boethiah's Spine Region"] = {
        neighboringRegions = {"Telvanni Isles","Helnim Fields Region","Molagreahd Region"}
    },
    ["Molagreahd Region"] = {
        neighboringRegions = {"Azura's Coast Region","Boethiah's Spine Region","Telvanni Isles"}
    },
    ["Telvanni Isles"] = {
        neighboringRegions = {"Molagreahd Region","Boethiah's Spine Region"}
    },
    ["Helnim Fields Region"] = {
        neighboringRegions = {"Azura's Coast Region","Mephalan Vales Region","Boethiah's Spine Region"}
    },
    ["Mephalan Vales Region"] = {
        neighboringRegions = {"Azura's Coast Region","Sundered Scar Region","Lan Orethan Region","Sacred Lands Region","Helnim Fields Region","Boethiah's Spine Region"}
    },
    ["Sacred Lands Region"] = {
        neighboringRegions = {"Mephalan Vales Region","Nedothril Region"}
    },
    ["Sundered Scar Region"] = {
        neighboringRegions = {"Azura's Coast Region","Aanthirin Region","Alt Orethan Region","Mephalan Vales Region"}
    }, 
    ["Nedothril Region"] = {
        neighboringRegions = {"Sacred Lands Region","Lan Orethan Region"}
    }, 
    ["Alt Orethan Region"] = {
        neighboringRegions = {"Lan Orethan Region","Aanthirin Region","Deshaan Plains Region","Sundered Scar Region"}
    }, 
    ["Lan Orethan Region"] = {
        neighboringRegions = {"Mephalan Vales Region","Mudflats Region","Alt Orethan Region","Nedothril Region"}
    }, 
    ["Aanthirin Region"] = {
        neighboringRegions = {"Ascadian Isles Region","Deshaan Plains Region","Thirr Valley Region","Roth Roryn","Sundered Scar Region","Alt Orethan Region"}
    }, 
    ["Roth Roryn"] = {
        neighboringRegions = {"Bitter Coast Region","Velothi Mountains Region","Clambering Moor Region","Ascadian Isles Region","Armun Ashlands Region","Aanthirin Region"}
    },
    -- ["Velothi Mountains Region"] = {
    --     neighboringRegions = {"Roth Roryn","Grey Meadows Region","Othreleth Woods Region"}
    -- },
    ["Armun Ashlands Region"] = {
        neighboringRegions = {"Roth Roryn","Othreleth Woods Region"}
    },
    -- ["Grey Meadows Region"] = {
    --     neighboringRegions = {"Clambering Moor Region","Uld Vraech Region","Julan-Shar Region","Velothi Mountains Region"}
    -- },
    ["Othreleth Woods Region"] = {
        neighboringRegions = {"Armun Ashlands Region","Velothi Mountains Region","Shipal-Shin Region","Thirr Valley Region"}
    },
    --["Uld Vraech Region"] = {
    --    neighboringRegions = {"Solstheim, Hirstaang Forest","Julan-Shar Region","Grey Meadows Region","Solstheim, Isinfier Plains"}
    --},
    --["Clambering Moor Region"] = {
    --    neighboringRegions = {"Roth Roryn","Grey Meadows Region"}
    --},
    ["Thirr Valley Region"] = {
        neighboringRegions = {"Aanthirin Region","Othreleth Woods Region","Shipal-Shin Region"}
    },
    -- ["Deshaan Plains Region"] = {
    --     neighboringRegions = {"Alt Orethan Region","Salt Marsh Region","Mudflats Region","Shipal-Shin Region","Aanthirin Region"}
    -- },
    -- ["Salt Marsh Region"] = {
    --     neighboringRegions = {"Deshaan Plains Region","Mudflats Region","Arnesian Jungle Region"}
    -- },
    -- ["Mudflats Region"] = {
    --     neighboringRegions = {"Lan Orethan Region","Deshaan Plains Region","Salt Marsh Region"}
    -- },
    -- ["Arnesian Jungle Region"] = {
    --     neighboringRegions = {"Salt Marsh Region"}
    -- },
    -- ["Julan-Shar Region"] = {
    --     neighboringRegions = {"West Gash Region","Uld Vraech Region","Solstheim, Hirstaang Forest","Grey Meadows Region"}
    -- },
    ["Old Ebonheart Region"] = {
        neighboringRegions = {"Aanthirin Region"},
        randomPriceMax = 1,
        randomPriceMin = 0.75,
    }
}

return config
