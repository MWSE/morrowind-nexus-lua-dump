--[[Choice "Ammunition Pack (45g)" 1
Choice "Armorer Toolbox (25g)" 2
Choice "Book Bundle (10g)" 3
Choice "Ingredient Satchel (65g)" 4
Choice "Keyring (15g)" 5
Choice "Locksmith Kit (30g)" 6
Choice "Potion Case (50g)" 7
Choice "Scroll Bag (35g)" 8
Choice "Soulgem Pouch (40g)" 9
Choice "Armor Crate (55g)" 10
Choice "Clothing Sack (20g)" 11
Choice "Junk Collection (5g)" 12
Choice "Weapon Barrel (60g)" 13
Choice "Nevermind" 14
--]]

local ids = {

    
    "g7_inventory_AMMO",
    "g7_inventory_REPA",
    "g7_inventory_BOOK",
    "g7_inventory_INGR",
    "g7_inventory_KEYS",
    "g7_inventory_LOCK",
    "g7_inventory_ALCH",
    "g7_inventory_SCRL",
    "g7_inventory_SOUL",
    "g7_inventory_ARMO",
    "g7_inventory_CLOT",
    "g7_inventory_MISC",
    "g7_inventory_WEAP",

}

local price = {
    [ids[1]] = 45,
    [ids[2]] = 25,
    [ids[3]] = 10,
    [ids[4]] = 65,
    [ids[5]] = 15,
    [ids[6]] = 30,
    [ids[7]] = 50,
    [ids[8]] = 35,
    [ids[9]] = 40,
    [ids[10]] = 55,
    [ids[11]] = 20,
    [ids[12]] = 5,
    [ids[13]] = 60,

}

local name = {
    [ids[1]] = "Ammunition Pack ",
    [ids[2]] = "Armorer Toolbox ",
    [ids[3]] = "Book Bundle ",
    [ids[4]] = "Ingredient Satchel ",
    [ids[5]] = "Keyring ",
    [ids[6]] = "Locksmith Kit ",
    [ids[7]] = "Potion Case ",
    [ids[8]] = "Scroll Bag ",
    [ids[9]] = "Soulgem Pouch ",
    [ids[10]] = "Armor Crate ",
    [ids[11]] = "Clothing Sack ",
    [ids[12]] = "Junk Collection ",
    [ids[13]] = "Weapon Barrel ",
}

local gold = tes3.getPlayerGold()

for i = 1, 12 do
    if (price[ids[i]] <= gold) and not tes3.mobilePlayer.object.inventory:contains(ids[i]) then
        tes3ui.choice(name[ids[i]], i)
    end
end

tes3ui.choice("Nevermind.", 14)

return price
