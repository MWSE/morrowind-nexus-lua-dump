local CraftingFramework = require("CraftingFramework")
if not CraftingFramework then 
    return
end

local config = require("Syanide.HammerAndProngs.config")
local includeFolder = require("Syanide.HammerAndProngs.includeFolder")

require("Syanide.HammerAndProngs.factions")
require("Syanide.HammerAndProngs.tools")
require("Syanide.HammerAndProngs.materials")

if not tes3.isModActive("Tamriel_Data.esm") and not tes3.isModActive("OAAB.esm") then
    mwse.log("[HammerAndProngs] Tamriel_Data and OAAB not found! Mod will not work.")
    return
elseif not tes3.isModActive("Tamriel_Data.esm") then
    mwse.log("[HammerAndProngs] Tamriel_Data not found! Mod will not work.")
    return
elseif not tes3.isModActive("OAAB_Data.esm") then
    mwse.log("[HammerAndProngs] OAAB not found! Mod will not work.")
    return
end

includeFolder("Syanide.HammerAndProngs.Materials")
includeFolder("Syanide.HammerAndProngs.Armor")
includeFolder("Syanide.HammerAndProngs.Armor.Mods")
includeFolder("Syanide.HammerAndProngs.Weapons")
includeFolder("Syanide.HammerAndProngs.Weapons.Mods")

if config.jewelry then
    includeFolder("Syanide.HammerAndProngs.Jewelry")
    includeFolder("Syanide.HammerAndProngs.Jewelry.Mods")
end

if config.OAAB then
    includeFolder("Syanide.HammerAndProngs.OAAB.Armor")
    includeFolder("Syanide.HammerAndProngs.OAAB.Weapons")
end

if config.OAAB and config.jewelry then
    includeFolder("Syanide.HammerAndProngs.OAAB.Jewelry")
end

if config.TRData then
    includeFolder("Syanide.HammerAndProngs.Tamriel_Data.Armor")
    includeFolder("Syanide.HammerAndProngs.Tamriel_Data.Weapons")
end

if config.TRData and config.jewelry then
    includeFolder("Syanide.HammerAndProngs.Tamriel_Data.Jewelry")
end

if config.daedric then 
    includeFolder("Syanide.HammerAndProngs.Daedric")
    includeFolder("Syanide.HammerAndProngs.Daedric.Mods")
end

if config.daedric and config.OAAB then
    includeFolder("Syanide.HammerAndProngs.OAAB.Daedric")
end

if config.daedric and config.TRData then
    includeFolder("Syanide.HammerAndProngs.Tamriel_Data.Daedric")
end

if tes3.isLuaModActive("mer.RealisticRepair") then
    require("Syanide.HammerAndProngs.RRactivator")
else
    require("Syanide.HammerAndProngs.activator")
end

local function skillRaised(e)
    if config.skillMessage then
        if e.skill == tes3.skill.armorer then
            if e.level == 15 or e.level == 30 or e.level == 45 or e.level == 60 or e.level == 75 or e.level == 90 or e.level == 100 then
                tes3.messageBox("You feel as though you can craft new weapons and armor.")
            end
        end
    else
        return
    end
end
event.register(tes3.event.skillRaised, skillRaised)