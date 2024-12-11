local SigilStone = require("mer.sigilStones.components.SigilStone")

local modifiers_lowLevel = {
    {  id = "readiness" },
    {  id = "jagged" },
    {  id = "ferocious" },
    {  id = "condensed" },
    {  id = "fortified" },
    { id = "superior" },
    { id = "shaming", description = "Drain Intelligence on Strike" },
    { id = "misfortune", description = "Drain Luck on Strike" },
    { id = "maiming", description = "Drain Speed on Strike" },
    { id = "weakening", description = "Drain Strength on Strike" },
    { id = "wounding", description = "Drain Heath on Strike" },
    { id = "draining", description = "Drain Magicka on Strike" },
    { id = "exhaustion", description = "Drain Fatigue on Strike" },
    { id = "bleeding", description = "Damage Health on Strike" },
    { id = "Spirit knife", description = "Damage Health on Touch" },
    { id = "mudcrab", description = "Waterbreathing on Self (Ring/Amulet)" },
    { id = "fish", description = "Swift Swim on Self (Ring/Amulet)" },
    { id = "buoyancy", description = "Water Walking on Self (Ring/Amulet)" },
    { id = "protector", description = "Constant Shield (Clothing/Armor)" },
    { id = "flameguard", description = "Constant Fire Shield (Clothing/Armor)" },
    { id = "stormguard", description = "Constant Shock Shield (Clothing/Armor)" },
    { id = "frostguard", description = "Constant Frost Shield (Clothing/Armor)" },
    { id = "heavystep", description = "Burden on Touch (Ring/Amulet)" },
    { id = "pocketed", description = "Constant Feather (Clothing/Armor)" },
    { id = "frog", description = "Jump on Self (Ring/Amulet)" },
    { id = "floating", description = "Levitate on Self (Ring/Amulet)" },
    { id = "slowfall", description = "Slowfall on Self (Ring/Amulet)" },
    { id = "burgler", description = "Open on Touch (Ring/Amulet)" },
    { id = "firey", description = "Fire Damage on Strike" },
    { id = "arching", description = "Shock Damage on Strike" },
    { id = "chilling", description = "Frost Damage on Strike" },
    { id = "viper", description = "Poison on Strike" },
    { id = "corrosive", description = "Disintegrate on Strike" },
    { id = "hiding", description = "Invisibility on Use (Ring/Amulet)" },
    { id = "camoflauge", description = "Chameleon on Use (Ring/Amulet)" },
    { id = "elusive", description = "Constant Sanctuary" },
    { id = "cat", description = "Constant Night-Eye"},
    { id = "jink", description = "Paralyze on Strike" },
    { id = "tongueTying", description = "Silence on Strike" },
    { id = "blinding", description = "Blind on Strike" },
    { id = "echoes", description = "Sound on Strike" },
    { id = "soulStealing", description = "Soul Trap on Strike" },
    { id = "farReaching", description = "Constant Telekinesis (Clothing/Armor)" },
    { id = "absorbing", description = "Constant Spell Absorption (Clothing/Armor)" },
    { id = "mirrors", description = "Constant Reflect (Clothing/Armor)" },
    { id = "bear", description = "Constant Fortify Strength (Clothing/Armor)"},
    { id = "owl", description = "Constant Fortify Intelligence (Clothing/Armor)" },
    { id = "faith", description = "Constant Fortify Willpower (Clothing/Armor)" },
    { id = "nixHound", description = "Constant Fortify Agility (Clothing/Armor)" },
    { id = "hare", description = "Constant Fortify Speed (Clothing/Armor)" },
    { id = "ogrim", description = "Constant Fortify Endurance" },
    { id = "scamp", description = "Constant Fortify Personality" },
    { id = "celestial", description = "Constant Fortify Luck" },
    { id = "enchanter", description = "Constant Fortify Enchant" },
    { id = "blacksmith", description = "Constant Fortify Armorer" },
    { id = "wizard", description = "Constant Fortify Destruction" },
    { id = "warlock", description = "Constant Fortify Alteration" },
    { id = "mesmer", description = "Constant Fortify Illusion" },
    { id = "summoner", description = "Constant Fortify Conjuration" },
    { id = "mystic", description = "Constant Fortify Mysticism" },
    { id = "angel", description = "Constant Fortify Restoration" },
    { id = "alchemist", description = "Constant Fortify Alchemy" },
    { id = "devious", description = "Constant Fortify Sneak" },
    { id = "gymnast", description = "Constant Fortify Acrobatics" },
    { id = "merchant", description = "Constant Fortify Mercantile" },
    { id = "wordsmith", description = "Constant Fortify Speechcraft" },
}

---@type SigilStones.SigilStone.ObjectConfig[]
local sigilStones = {
    {
        objectId = "AATL_M_Dae_SigilStone_S",
        drainedObjectId = "AATL_M_Dae_SigilStone",
        modifiers = modifiers_lowLevel
    },
    {
        objectId = "mer_sigilStone_01",
        drainedObjectId = "mer_sigilStone_01_d",
        modifiers = modifiers_lowLevel
    }
}

for _, data in ipairs(sigilStones) do
    SigilStone.registerSigilStoneObject(data)
end