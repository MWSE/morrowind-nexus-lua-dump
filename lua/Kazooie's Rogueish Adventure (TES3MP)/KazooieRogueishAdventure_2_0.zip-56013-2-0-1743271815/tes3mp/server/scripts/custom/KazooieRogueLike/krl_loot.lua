local lootTable = {}

local function addLootResult(rarity, chance, lootItems, count)
    table.insert(lootTable, {
        lootItems = lootItems,
        chance = chance,
        count = count or 1,
        rarity = rarity
    })
end

local function addCommonLoot(chance, lootItems, count)
    addLootResult("Common", chance, lootItems, count)
end

local function addRareLoot(chance, lootItems, count)
    addLootResult("Rare", chance, lootItems, count)
end

local function addLegendaryLoot(chance, lootItems, count)
    addLootResult("Legendary", chance, lootItems, count)
end

local function addLootItem(refId, name)
    return {
        refId = refId,
        name = name
    }
end

addCommonLoot(25, {addLootItem("gold_001", "Gold")}, 25)
addCommonLoot(15, {addLootItem("common_shirt_02", "Common Shirt")})
addCommonLoot(15, {addLootItem("silver arrow", "Silver Arrows")}, 30)
addCommonLoot(15, {
    addLootItem("sc_invisibility", "Scroll of Invisibility"), 
    addLootItem("sc_hellfire", "Scroll of Hellfire"),
    addLootItem("sc_firstbarrier", "Scroll of First Barrier")
})
addCommonLoot(15, {
    addLootItem("bonemold long bow", "Bonemold Long Bow"),
    addLootItem("silver dagger", "Silver Dagger"), 
    addLootItem("silver longsword", "Silver Longsword"), 
    addLootItem("silver spear", "Silver Spear"), 
    addLootItem("silver staff", "Silver Staff"),
    addLootItem("silver claymore", "Silver Claymore"),
    addLootItem("silver war axe", "Silver War Axe")
})
addCommonLoot(15, {
    addLootItem("p_restore_health_q", "Health Potion"),
    addLootItem("p_restore_fatigue_q", "Fatigue Potion"),
    addLootItem("p_restore_magicka_q", "Magicka Potion")
})
addCommonLoot(15, {
    addLootItem("templar_cuirass", "Templar Cuirass"),
    addLootItem("steel_towershield", "Steel Shield"),
    addLootItem("silver_helm", "Silver Helmet"),
    addLootItem("netch_leather_pauldron_left", "Netch Leather Pauldron"),
    addLootItem("fur_pauldron_right", "Fur Pauldron"),
    addLootItem("bonemold_towershield", "Bonemold Shield"),
    addLootItem("bonemold_cuirass", "Bonemold Cuirass"),
    addLootItem("BM bear cuirass", "Bear Cuirass"),
    addLootItem("chitin_towershield", "Chitin Shield")
})

addRareLoot(10, {addLootItem("kazooie_fork", "Silver Fork")})
addRareLoot(10, {addLootItem("gold_001", "Gold")}, 50)
addRareLoot(10, {addLootItem("orcish_boots", "Orcish Boots")})
addRareLoot(10, {addLootItem("pick_journeyman_01", "Lockpick")}, 3)
addRareLoot(10, {
    addLootItem("amulet of shield", "Amulet of Shield"),
    addLootItem("amulet of rest", "Amulet of Rest"),
    addLootItem("belt of vigor", "Belt of Vigor"),
    addLootItem("Caius_pants", "Caius Pants"),
    addLootItem("dire sparkbolt ring", "Sparkbolt Ring"),
    addLootItem("dire flamebolt ring", "Flamebolt Ring"),
    addLootItem("exquisite_ring_02", "Exquisite Ring"),
    addLootItem("exquisite_skirt_01", "Exquisite Skirt")
})

addLegendaryLoot(10, {addLootItem("krl_fake_eltonbrand", "Eltonbrand")})
addLegendaryLoot(5, {addLootItem("blood ring", "Blood Ring")})
addLegendaryLoot(1, {addLootItem("gold_001", "Gold")}, 100)
addLegendaryLoot(1, {addLootItem("skeleton_key", "Skeleton Key")})
addLegendaryLoot(1, {addLootItem("kazooie_m1911", "M1911 Pistol")})
addLegendaryLoot(0.25, {addLootItem("BM_ring_hircine", "Ring of Hircine")})

function KRL_OpenMysteryBox()
    local lootTableCopy = krl_array(lootTable).shallow_copy()
    local shuffledLootTable = krl_array(lootTableCopy).shuffle()

    for _, lootResult in pairs(shuffledLootTable) do
        if KRL_RollLuck(lootResult.chance) then
            return {
                rarity = lootResult.rarity,
                count = lootResult.count,
                lootItem = lootResult.lootItems[math.random(#lootResult.lootItems)],
            }
        end
    end

    return {
        rarity = "Common",
        count = 10,
        lootItem = {
            refId = "gold_001",
            name = "Gold"
        }
    }
end

local possibleDiseases = {}
local niceDiseaseNames = {}

local function addDisease(diseaseId, diseaseName)
    table.insert(possibleDiseases, diseaseId)
    niceDiseaseNames[diseaseId] = diseaseName
end

addDisease("ash woe blight", "Ash Woe Blight")
addDisease("corprus", "Corprus")
addDisease("black-heart blight", "Black Heart Blight")
addDisease("ash-chancre", "Ash Chancre")
addDisease("chanthrax blight", "Chanthrax Blight")
addDisease("ataxia", "Ataxia")
addDisease("brown rot", "Brown Rot")
addDisease("chills", "Chills")
addDisease("collywobbles", "Collywobbles")
addDisease("crimson_plague", "Crimson Plague")
addDisease("dampworm", "Dampworm")
addDisease("droops", "Droops")
addDisease("greenspore", "Greenspore")
addDisease("helljoint", "Helljoint")
addDisease("rattles", "Rattles")
addDisease("rockjoint", "Rockjoint")
addDisease("rotbone", "Rotbone")
addDisease("rust chancre", "Rust Chancre")
addDisease("serpiginous dementia", "Serpiginous Dementia")
addDisease("swamp fever", "Swamp Fever")
addDisease("krl_vamprism", "Vamprism")
addDisease("vampire blood quarra", "Vampirism")
addDisease("werewolf blood", "Lycanthropy")
addDisease("witbane", "Witbane")
addDisease("wither", "Wither")
addDisease("yellow tick", "Yellow Tick")
addDisease("krl_cockrot", "Cock Rot")

function KRL_CatchRandomDisease(pid)
    local randomDisease = possibleDiseases[math.random(#possibleDiseases)]
    local diseaseName = niceDiseaseNames[randomDisease]
    logicHandler.RunConsoleCommandOnPlayer(pid, "AddSpell "..randomDisease, true)
    tes3mp.MessageBox(pid, -1, "You have contracted "..tostring(diseaseName)..".")
end
