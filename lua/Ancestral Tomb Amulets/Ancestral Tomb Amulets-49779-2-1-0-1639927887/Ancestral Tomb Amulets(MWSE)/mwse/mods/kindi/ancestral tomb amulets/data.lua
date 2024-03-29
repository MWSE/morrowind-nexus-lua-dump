local data = {}

data.alternate = false
data.menuModeCode = nil
data.menuWidth = nil
data.menuHeight = nil
data.menuPosx = nil
data.menuPosy = nil
data.storageCrate = nil
data.superCrate = nil
data.ownedAmulets = {}
data.allAmulets = {} --k = tombid, v = amuletid, copied from modifiedamulets(created amulets)
data.allTombs = {} --default + custom tombs
data.source = {} --k = sourcemod, v = cellid
data.plusChance = 0
data.rejectedTombs = {}
data.unusedDoors = {} --[[unknown doors]]

data.tooltipsComplete = nil
data.tooltipsCompleteIsInstalled =
    io.open(tes3.installDirectory .. "\\data files\\mwse\\mods\\Tooltips Complete\\interop.lua", "r")
if data.tooltipsCompleteIsInstalled then
    data.tooltipsComplete = require("Tooltips Complete.interop")
    io.close(data.tooltipsCompleteIsInstalled)
else
    data.tooltipsComplete = false
end

data.meta = {}
data.traitorCheck = {}

--[[you can add your own mesh and icon path to be used by the mod]]
--[[number of elements from both tables must be the same]]
data.amuletMesh = {
    "c\\Amulet_Common_1.nif",
    "c\\Amulet_Common_2.nif",
    "c\\Amulet_Common_3.nif",
    "c\\Amulet_Common_4.nif",
    "c\\Amulet_Common_5.nif",
    "c\\Amulet_Expensive_1.nif",
    "c\\Amulet_Expensive_2.nif",
    "c\\Amulet_Expensive_3.nif",
    "c\\Amulet_Exquisit_1.nif",
    "c\\Amulet_Extravagant_1.nif",
    "c\\Amulet_Extravagant_2.nif"
}

data.amuletIcon = {
    "c\\tx_amulet_com1.tga",
    "c\\tx_amulet_com2.tga",
    "c\\tx_amulet_com3.tga",
    "c\\tx_amulet_com4.tga",
    "c\\tx_amulet_com5.tga",
    "c\\tx_amulet_expens1.tga",
    "c\\tx_amulet_expens2.tga",
    "c\\tx_amulet_expens3.tga",
    "c\\tx_amulet_exquisite1.tga",
    "c\\tx_amulet_extrav1.tga",
    "c\\tx_amulet_extrav2.tga"
}

data.otherLabel =
    "                    Ancestral Tomb Amulets\n\nCollect all ancestral tomb amulets! Each amulet grants the wearer the power to teleport to the tomb associated with it.\n\nOne amulet has a chance to be randomly placed into a container each time an interior cell is entered.\nThe container is randomly picked, so make sure to check all containers if you can.\nOrganic, respawning, and scripted containers are not included in this list.\n\nIf a cell has rolled for an amulet, it will not roll for another until you have visited a variety of different cells.\nAmulets are one-of-a-kind items that you can only get once.\n\nThe amulets' enchantments are randomized, and they all have positive effects.\nYou could get a strong summoning or bound constant effect enchantment if you're lucky.\n\nFor every new character, the amulets will have a unique enchantment and design.\nFor that reason, a new game would offer a unique playthrough experience."

--[[you can add tombs to be exempted from the filter]]
--[[or you can specify where to teleport in a tomb. Values inside this table will have higher priority]]
--[[posx, posy, posz, rotationz in radians]]
--[[keys must be exact cell ID and position/rotation must be specified]]
--[[restart game to apply changes]]
data.tombExtra = {
    ["Adryn Ancestral Tomb"] = {position = {3623, 3703, 15053}, rotation = {0, 0, 1.570796}} --[[teleports to a more lore friendly position]],
    ["Heleran Ancestral Tomb"] = {position = {1937, 3650, 15234}, rotation = {0, 0, 1.570796}} --[[tombs located inside interiors are blacklisted, this one is exempted]]
}

--[[you can add custom tooltip to the amulet by editing this section]]
--[[this will override the mod default]]
--[[key must be a valid tomb cell ID, value will be the tooltip description]]
--[[require tooltips complete mod ]]
data.customAmuletTooltip = {
    ["Drethan Ancestral Tomb"] = "Extravagant jewellery of the Drethan family",
    ["Marvani Ancestral Tomb"] = "Unique ornament of the Marvani family",
    ["Andrano Ancestral Tomb"] = "Magnificent gemstone of the Andrano family",
    ["Velas Ancestral Tomb"] = "Auspicious stone of the Velas family"
}
data.effects = {
    WaterBreathing = 0,
    SwiftSwim = 1,
    WaterWalking = 2,
    Shield = 3,
    FireShield = 4,
    LightningShield = 5,
    FrostShield = 6,
    Feather = 8,
    SlowFall = 11,
    Invisibility = 39,
    Chameleon = 40,
    Light = 41,
    Sanctuary = 42,
    NightEye = 43,
    DetectAnimal = 64,
    DetectEnchantment = 65,
    DetectKey = 66,
    SpellAbsorption = 67,
    Reflect = 68,
    CureCommonDisease = 69,
    CureBlightDisease = 70,
    CurePoison = 72,
    CureParalyzation = 73,
    FortifyHealth = 80,
    FortifyMagicka = 81,
    FortifyFatigue = 82,
    ResistFire = 90,
    ResistFrost = 91,
    ResistShock = 92,
    ResistMagicka = 93,
    ResistCommonDisease = 94,
    ResistBlightDisease = 95,
    ResistPoison = 97,
    ResistNormalWeapons = 98,
    ResistParalysis = 99,
    SummonScamp = 102,
    SummonClannfear = 103,
    SummonDaedroth = 104,
    SummonDremora = 105,
    SummonGhost = 106,
    SummonSkeleton = 107,
    SummonLeastBonewalker = 108,
    SummonGreaterBonewalker = 109,
    SummonBonelord = 110,
    SummonTwilight = 111,
    SummonHunger = 112,
    SummonGoldenSaint = 113,
    SummonFlameAtronach = 114,
    SummonFrostAtronach = 115,
    SummonStormAtronach = 116,
    FortifyAttackBonus = 117,
    BoundDagger = 120,
    BoundLongsword = 121,
    BoundMace = 122,
    BoundBattleAxe = 123,
    BoundSpear = 124,
    BoundLongbow = 125,
    BoundCuirass = 127,
    BoundHelm = 128,
    BoundBoots = 129,
    BoundShield = 130,
    BoundGloves = 131
}

data.links = {
    modpage = "https://www.nexusmods.com/morrowind/mods/49779",
    video = "https://www.youtube.com/watch?v=wyQsfgY76Ug"
}

return data
