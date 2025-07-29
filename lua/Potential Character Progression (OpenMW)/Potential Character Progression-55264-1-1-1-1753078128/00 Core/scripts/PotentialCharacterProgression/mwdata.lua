-- Data from vanilla Morrowind used in this mod
-- It is either impossible or unwise to gather this information from content files/openmw.cfg

-- Maybe not the most logical way to organize this, but it makes things simpler at runtime
--[[
    class = {
        armorer     = ,
        athletics   = ,
        axe         = ,
        block       = ,
        bluntweapon = ,
        heavyarmor  = ,
        longblade   = ,
        mediumarmor = ,
        spear       = ,
        alchemy     = ,
        alteration  = ,
        conjuration = ,
        destruction = ,
        enchant     = ,
        illusion    = ,
        mysticism   = ,
        restoration = ,
        unarmored   = ,
        acrobatics  = ,
        handtohand  = ,
        lightarmor  = ,
        marksman    = ,
        mercantile  = ,
        security    = ,
        shortblade  = ,
        sneak       = ,
        speechcraft = 
    },
--]]

-- Major skill, minor skill, and specialization data for the 21 vanilla classes
-- This information is used to select the art shown when leveling up
local classData = {
    acrobat = {
        athletics   = 'M',
        spear       = 'm',
        alteration  = 'm',
        unarmored   = 'M',
        acrobatics  = 'MS',
        handtohand  = 'mS',
        lightarmor  = 'mS',
        marksman    = 'MS',
        mercantile  = 'S',
        security    = 'S',
        shortblade  = 'S',
        sneak       = 'MS',
        speechcraft = 'mS'
    },

    agent = {
        block       = 'm',
        conjuration = 'm',
        illusion    = 'm',
        unarmored   = 'm',
        acrobatics  = 'MS',
        handtohand  = 'S',
        lightarmor  = 'MS',
        marksman    = 'S',
        mercantile  = 'mS',
        security    = 'S',
        shortblade  = 'MS',
        sneak       = 'MS',
        speechcraft = 'MS'
    },

    archer = {
        armorer     = 'S',
        athletics   = 'MS',
        axe         = 'S',
        block       = 'MS',
        bluntweapon = 'S',
        heavyarmor  = 'S',
        longblade   = 'MS',
        mediumarmor = 'mS',
        spear       = 'mS',
        restoration = 'm',
        unarmored   = 'm',
        lightarmor  = 'M',
        marksman    = 'M',
        sneak       = 'm'
    },

    assassin = {
        athletics   = 'm',
        block       = 'm',
        longblade   = 'm',
        alchemy     = 'm',
        acrobatics  = 'MS',
        handtohand  = 'S',
        lightarmor  = 'MS',
        marksman    = 'MS',
        mercantile  = 'S',
        security    = 'mS',
        shortblade  = 'MS',
        sneak       = 'MS',
        speechcraft = 'S'
    },

    barbarian = {
        armorer     = 'mS',
        athletics   = 'MS',
        axe         = 'MS',
        block       = 'MS',
        bluntweapon = 'MS',
        heavyarmor  = 'S',
        longblade   = 'S',
        mediumarmor = 'MS',
        spear       = 'S',
        unarmored   = 'm',
        acrobatics  = 'm',
        lightarmor  = 'm',
        marksman    = 'm'
    },

    bard = {
        block       = 'M',
        longblade   = 'M',
        mediumarmor = 'm',
        alchemy     = 'M',
        enchant     = 'm',
        illusion    = 'm',
        acrobatics  = 'MS',
        handtohand  = 'S',
        lightarmor  = 'S',
        marksman    = 'S',
        mercantile  = 'mS',
        security    = 'mS',
        shortblade  = 'S',
        sneak       = 'S',
        speechcraft = 'MS'
    },

    battlemage = {
        axe         = 'M',
        heavyarmor  = 'M',
        longblade   = 'm',
        alchemy     = 'mS',
        alteration  = 'MS',
        conjuration = 'MS',
        destruction = 'MS',
        enchant     = 'mS',
        illusion    = 'S',
        mysticism   = 'mS',
        restoration = 'S',
        unarmored   = 'S',
        marksman    = 'm'
    },

    crusader = {
        armorer     = 'mS',
        athletics   = 'S',
        axe         = 'S',
        block       = 'MS',
        bluntweapon = 'MS',
        heavyarmor  = 'MS',
        longblade   = 'MS',
        mediumarmor = 'mS',
        spear       = 'S',
        alchemy     = 'm',
        destruction = 'M',
        restoration = 'm',
        handtohand  = 'm'
    },

    healer = {
        bluntweapon = 'm',
        alchemy     = 'mS',
        alteration  = 'MS',
        conjuration = 'S',
        destruction = 'S',
        enchant     = 'S',
        illusion    = 'mS',
        mysticism   = 'MS',
        restoration = 'MS',
        unarmored   = 'mS',
        handtohand  = 'M',
        lightarmor  = 'm',
        speechcraft = 'M'
    },

    knight = {
        armorer     = 'mS',
        athletics   = 'S',
        axe         = 'MS',
        block       = 'MS',
        bluntweapon = 'S',
        heavyarmor  = 'MS',
        longblade   = 'MS',
        mediumarmor = 'mS',
        spear       = 'S',
        enchant     = 'm',
        restoration = 'm',
        mercantile  = 'm',
        speechcraft = 'M'
    },

    mage = {
        alchemy     = 'mS',
        alteration  = 'MS',
        conjuration = 'mS',
        destruction = 'MS',
        enchant     = 'mS',
        illusion    = 'MS',
        mysticism   = 'MS',
        restoration = 'MS',
        unarmored   = 'mS',
        shortblade  = 'm'
    },

    monk = {
        athletics   = 'M',
        block       = 'm',
        bluntweapon = 'm',
        restoration = 'm',
        unarmored   = 'M',
        acrobatics  = 'MS',
        handtohand  = 'MS',
        lightarmor  = 'mS',
        marksman    = 'mS',
        mercantile  = 'S',
        security    = 'S',
        shortblade  = 'S',
        sneak       = 'MS',
        speechcraft = 'S'
    },

    nightblade = {
        alchemy     = 'S',
        alteration  = 'MS',
        conjuration = 'S',
        destruction = 'mS',
        enchant     = 'S',
        illusion    = 'MS',
        mysticism   = 'MS',
        restoration = 'S',
        unarmored   = 'mS',
        lightarmor  = 'm',
        marksman    = 'm',
        security    = 'm',
        shortblade  = 'M',
        sneak       = 'M'
    },

    pilgrim = {
        block       = 'm',
        mediumarmor = 'M',
        alchemy     = 'm',
        illusion    = 'm',
        restoration = 'M',
        acrobatics  = 'S',
        handtohand  = 'mS',
        lightarmor  = 'S',
        marksman    = 'MS',
        mercantile  = 'MS',
        security    = 'S',
        shortblade  = 'mS',
        sneak       = 'S',
        speechcraft = 'MS'
    },

    rogue = {
        armorer     = 'S',
        athletics   = 'mS',
        axe         = 'MS',
        block       = 'mS',
        bluntweapon = 'S',
        heavyarmor  = 'S',
        longblade   = 'mS',
        mediumarmor = 'mS',
        spear       = 'S',
        handtohand  = 'M',
        lightarmor  = 'M',
        mercantile  = 'M',
        shortblade  = 'M',
        speechcraft = 'm'
    },

    scout = {
        armorer     = 'S',
        athletics   = 'MS',
        axe         = 'S',
        block       = 'MS',
        bluntweapon = 'S',
        heavyarmor  = 'S',
        longblade   = 'MS',
        mediumarmor = 'MS',
        spear       = 'S',
        alchemy     = 'm',
        alteration  = 'm',
        unarmored   = 'm',
        lightarmor  = 'm',
        marksman    = 'm',
        sneak       = 'M'
    },

    sorcerer = {
        heavyarmor  = 'm',
        mediumarmor = 'm',
        alchemy     = 'S',
        alteration  = 'MS',
        conjuration = 'MS',
        destruction = 'MS',
        enchant     = 'MS',
        illusion    = 'mS',
        mysticism   = 'MS',
        restoration = 'S',
        unarmored   = 'S',
        marksman    = 'm',
        shortblade  = 'm'
    },

    spellsword = {
        axe         = 'm',
        block       = 'M',
        bluntweapon = 'm',
        longblade   = 'M',
        mediumarmor = 'm',
        alchemy     = 'mS',
        alteration  = 'MS',
        conjuration = 'S',
        destruction = 'MS',
        enchant     = 'mS',
        illusion    = 'S',
        mysticism   = 'S',
        restoration = 'MS',
        unarmored   = 'S'
    },

    thief = {
        athletics   = 'm',
        acrobatics  = 'MS',
        handtohand  = 'mS',
        lightarmor  = 'MS',
        marksman    = 'mS',
        mercantile  = 'mS',
        security    = 'MS',
        shortblade  = 'MS',
        sneak       = 'MS',
        speechcraft = 'mS'
    },

    warrior = {
        armorer     = 'mS',
        athletics   = 'MS',
        axe         = 'mS',
        block       = 'MS',
        bluntweapon = 'mS',
        heavyarmor  = 'MS',
        longblade   = 'MS',
        mediumarmor = 'MS',
        spear       = 'mS',
        marksman    = 'm'
    },

    witchhunter = {
        block       = 'm',
        bluntweapon = 'm',
        alchemy     = 'MS',
        alteration  = 'S',
        conjuration = 'MS',
        destruction = 'S',
        enchant     = 'MS',
        illusion    = 'S',
        mysticism   = 'mS',
        restoration = 'S',
        unarmored   = 'mS',
        lightarmor  = 'M',
        marksman    = 'M',
        sneak       = 'm'
    }
}

return {
    classData = classData
}