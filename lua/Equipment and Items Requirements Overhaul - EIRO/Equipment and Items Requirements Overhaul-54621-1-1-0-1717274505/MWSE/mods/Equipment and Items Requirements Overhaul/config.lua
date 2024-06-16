local config = {
    -- Default values
    Skills = {
        ["Long Blade One Hand"] = { broadsword = 0.0, saber = 0.0, longsword = 0.0, katana = 0.0, ["other/artifact"] = 0.0 },
        ["Long Blade Two Close"] = { claymore = 0.0, ["dai-katana"] = 0.0, ["other/artifact"] = 0.0 },
        ["Marksman Thrown"] = { dart = 0.0, knife = 0.0, star = 0.0, ["other/artifact"] = 0.0 },
        ["Marksman Bow"] = { ["short bow"] = 0.0, ["long bow"] = 0.0, ["other/artifact"] = 0.0 },
        ["Marksman Crossbow"] = { crossbow = 0.0, ["other/artifact"] = 0.0 },
        ["Blunt One Hand"] = { club = 0.0, mace = 0.0, ["other/artifact"] = 0.0 },
        ["Blunt Two Wide"] = { staff = 0.0, ["other/artifact"] = 0.0 },
        ["Blunt Two Close"] = { ["hammers - two hands - all"] = 0.0, ["other/artifact"] = 0.0 },
        Arrow = { arrow = 0.0, ["other/artifact"] = 0.0 },
        Bolt = { bolt = 0.0, ["other/artifact"] = 0.0 },
        ["Short Blade One Hand"] = { dagger = 0.0, tanto = 0.0, ["short sword"] = 0.0, wakizashi = 0.0, ["other/artifact"] = 0.0 },
        ["Spear Two Wide"] = { spear = 0.0, halberd = 0.0, ["other/artifact"] = 0.0 },
        ["Axe One Hand"] = { ["axes - one hands - all"] = 0.0, ["other/artifact"] = 0.0 },
        ["Axe Two Close"] = { ["axes - two hands - all"] = 0.0, ["other/artifact"] = 0.0 },
    },
    ArmorSkills = {
        ["Light Armor"] = { ["light armor"] = 0.0 },
        ["Medium Armor"] = { ["medium armor"] = 0.0 },
        ["Heavy Armor"] = { ["heavy armor"] = 0.0 },
    },
    Attributes = {
        strength = 0,
        intelligence = 0,
        willpower = 0,
        agility = 0,
        speed = 0,
        endurance = 0,
        personality = 0,
        luck = 0
    },
    Other = {
        clothing = 0,
        alchemy = 0,
        book = 0,
        lockpick = 0,
        probe = 0,
        apparatus = 0,
        spell = 0,
        repairItem = 0,
    }
}

return config
