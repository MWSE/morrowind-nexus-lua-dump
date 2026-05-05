--[[
    IC:
        FPerks_IC1_Passive          - +3 Willpower, +3 Personality, +5 Speechcraft, +5 Restoration
        FPerks_IC2_Passive          - +5 Willpower, +5 Personality, +10 Speechcraft, +10 Restoration
        FPerks_IC3_Passive          - +10 Willpower, +10 Personality, +18 Speechcraft, +18 Restoration
        FPerks_IC4_Passive          - +15 Willpower, +15 Personality, +25 Speechcraft, +25 Restoration

    Non-table spells (granted once, not removed on rank-up):
        "divine intervention"       Vanilla spell (P1)
        FPerks_IC4_AllAttributes    Power (P4)

    Divine Smite (P3+):
        When the player strikes an undead, daedra, or vampire
        with a weapon, divine damage is dealt directly to the
        target bypassing all resistances.
        Damage = Imperial Cult faction rank x 10.
        Per-target cooldown: 10s at P3, 5s at P4.
        Detected via npc.lua and creature.lua hit handlers.
]]

local ns         = require("scripts.FactionPerks.namespace")
local utils      = require("scripts.FactionPerks.utils")
local perkHidden  = utils.perkHidden
local safeAddSpell  = utils.safeAddSpell
local safeRemoveSpell = utils.safeRemoveSpell
local GUILD        = utils.FACTION_GROUPS.imperialCult
local interfaces = require("openmw.interfaces")
local types      = require('openmw.types')
local self       = require('openmw.self')
local core       = require('openmw.core')
local ui         = require('openmw.ui')
local ambient    = require('openmw.ambient')

local R = interfaces.ErnPerkFramework.requirements

local perkTable = {
    [1] = { passive = {"FPerks_IC1_Passive"} },
    [2] = { passive = {"FPerks_IC2_Passive"} },
    [3] = { passive = {"FPerks_IC3_Passive"} },
    [4] = { passive = {"FPerks_IC4_Passive"} },
}

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  SMITE FEEDBACK
--  One message per Divine, chosen at random when the smite
--  fires. Each reflects that Divine's domain and the context
--  of striking the unholy. Sound uses the vanilla critical
--  attack cue for a satisfying confirmation.
-- ============================================================

local IC_SMITE_MESSAGES = {
    "Akatosh guides your hand.",
    "By Arkay's grace, the dead shall not stand.",
    "Dibella blesses your strike.",
    "Julianos illuminates the weakness of your foe.",
    "Kynareth's breath carries your blow true.",
    "Mara shields the living through your hand.",
    "Stendarr's mercy is not for the wicked.",
    "Talos strengthens the arm of his faithful.",
    "Zenithar rewards your devotion.",
}

local function onSmiteProc(data)
    ambient.playSound("critical attack")
    ui.showMessage(IC_SMITE_MESSAGES[math.random(#IC_SMITE_MESSAGES)])
end

-- ============================================================
--  IMPERIAL CULT PERKS
--  Primary attributes: Willpower, Personality
--  Scaling: Speechcraft, Restoration
--  Special: Divine Intervention (P1), Divine Smite (P3+),
--           Fortify All Attributes power (P4)
-- ============================================================

local function guildRank(rank)
    local reqs = {
        R().minimumFactionRank('imperial cult', rank),
    }
    if core.contentFiles.has("tamriel_data.esm") then
        table.insert(reqs, R().minimumFactionRank('t_cyr_itinerantpriests', rank))
        table.insert(reqs, R().minimumFactionRank('t_sky_imperialcult', rank))
    end
    -- No need for orGroup if only one requirement
    if #reqs == 1 then return reqs[1] end
    return R().orGroup(table.unpack(reqs))
end


local ic1_id = ns .. "_ic_lay_worshipper"
interfaces.ErnPerkFramework.registerPerk({
    id = ic1_id,
    localizedName = "Lay Worshipper",
    localizedDescription = "You have joined the Cult and attend its rites faithfully. "
        .. "The Nine Divines offer you modest but real protection.\
 "
        .. "(+3 Willpower, +3 Personality, +5 Speechcraft, +5 Restoration, "
        .. "grants Divine Intervention)",
    hidden = perkHidden(GUILD, 0, 1),
    art = "textures\\levelup\\healer", cost = 1,
    requirements = {
        guildRank(0),
        R().minimumLevel(1)
    },
    onAdd = function()
        setRank(1)
        safeAddSpell("divine intervention")
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("divine intervention")
    end,
})

local ic2_id = ns .. "_ic_charitable_hand"
interfaces.ErnPerkFramework.registerPerk({
    id = ic2_id,
    localizedName = "Charitable Hand",
    localizedDescription = "You have distributed alms and tended to the sick in the name of the Divines. "
        .. "Your faith has strengthened your body as well as your spirit.\
 "
        .. "Requires Lay Worshipper. "
        .. "(+5 Willpower, +5 Personality, +10 Speechcraft, +10 Restoration)",
    hidden = perkHidden(GUILD, 3, 5),
    art = "textures\\levelup\\healer", cost = 2,
    requirements = {
        R().hasPerk(ic1_id),
        guildRank(3),
        R().minimumAttributeLevel('willpower', 40),
        R().minimumLevel(5),
    },
    onAdd    = function() setRank(2) end,
    onRemove = function() setRank(nil) end,
})

local ic3_id = ns .. "_ic_divine_favour"
interfaces.ErnPerkFramework.registerPerk({
    id = ic3_id,
    localizedName = "Divine Favour",
    localizedDescription = "The Divines have marked you as a servant of true worth. "
        .. "When you strike the unholy, divine power smites them through your hand.\
 "
        .. "Requires Charitable Hand. "
        .. "(+10 Willpower, +10 Personality, +18 Speechcraft, +18 Restoration)\
\
"
        .. "Divine Smite: Striking undead, daedra, or vampires deals bonus divine damage "
        .. "equal to your Imperial Cult rank x 10. 10s cooldown per target.",
    hidden = perkHidden(GUILD, 6, 10),
    art = "textures\\levelup\\healer", cost = 3,
    requirements = {
        R().hasPerk(ic2_id),
        guildRank(6),
        R().minimumAttributeLevel('willpower', 50),
        R().minimumLevel(10),
    },
    onAdd    = function() setRank(3) end,
    onRemove = function() setRank(nil) end,
})

local ic4_id = ns .. "_ic_blessed_of_the_nine"
interfaces.ErnPerkFramework.registerPerk({
    id = ic4_id,
    localizedName = "Blessed of the Nine",
    localizedDescription = "The Nine Divines have extended their grace to you directly. "
        .. "Once each day you may call upon their full blessing. "
        .. "The cooldown on Divine Smite is halved.\
 "
        .. "Requires Divine Favour. "
        .. "(+15 Willpower, +15 Personality, +25 Speechcraft, +25 Restoration, "
        .. "1/day Fortify All Attributes +50 for 30s)\
\
"
        .. "Divine Smite cooldown reduced to 5s per target.",
    hidden = perkHidden(GUILD, 9, 15),
    art = "textures\\levelup\\healer", cost = 4,
    requirements = {
        R().hasPerk(ic3_id),
        guildRank(9),
        R().minimumAttributeLevel('willpower', 75),
        R().minimumLevel(15),
    },
    onAdd = function()
        setRank(4)
        safeAddSpell("FPerks_IC4_AllAttributes")
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("FPerks_IC4_AllAttributes")
    end,
})

-- ============================================================
--  ENGINE CALLBACKS
-- ============================================================
return {
    eventHandlers = {
        FPerks_IC_SmiteProc = onSmiteProc,
    },
}