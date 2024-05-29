-- Zur Eingabe in tes3.getFaction
GetFactionNames = {"Clan Aundae", "Clan Berne", "Clan Quarra", "Fighters Guild", "Imperial Cult", "Imperial Legion", "Mages Guild", "Morag Tong", "Hlaalu", "Redoran", 
"Telvanni", "Temple", "Thieves Guild", "Twin Lamps", "East Empire Company"}
-- Zum Übergeben und dann Ausgeben in AdvNotifDisplay()
FactionTableNames = {"Vampire Clan Aundae.", "Vampire Clan Berne.", "Vampire Clan Quarra.", "Fighters Guild.", "Imperial Cult.", "Imperial Legion.", "Mages Guild.", "Morag Tong.", "Great House Hlaalu.",
"Great House Redoran.", "Great House Telvanni.", "Tribunal Temple.", "Thieves Guild.", "Twin Lamps.", "East Empire Company."}

IconScale = 0
IconBorderRight = 0
IconBorderLeft = 0

IconPaths = {}

if tes3.isLuaModActive("SSQN") then
    mwse.log("[Rank Up!] SSQN is active.")
    IconPaths = {
        "Icons\\SSQN\\vamp.dds", 
        "Icons\\SSQN\\vamp.dds", 
        "Icons\\SSQN\\vamp.dds", 
        "Icons\\SSQN\\FG.dds", 
        "Icons\\SSQN\\IC.dds", 
        "Icons\\SSQN\\IL.dds", 
        "Icons\\SSQN\\MG.dds", 
        "Icons\\SSQN\\MT.dds", 
        "Icons\\SSQN\\HH.dds",
        "Icons\\SSQN\\HR2.dds", 
        "Icons\\SSQN\\HT.dds", 
        "Icons\\SSQN\\TT.dds", 
        "Icons\\SSQN\\TG.dds", 
        "Icons\\SSQN\\divine.dds", -- Twin Lamps has no unique icon
        "Icons\\SSQN\\EEC.dds"
    }
    IconScale = 0.75
    IconBorderRight = 10
    IconBorderLeft = 8
    return
else
    mwse.log("[Rank Up!] SSQN is not active.")
    IconPaths = {
        "Icons\\Rank Up - Advancement Notifications\\Vampire_Clans_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Vampire_Clans_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Vampire_Clans_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Fighters_Guild_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Imperial_Cult_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Imperial_Legion_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Mages_Guild_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Morag_Tong_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Hlaalu_Icon.dds",
        "Icons\\Rank Up - Advancement Notifications\\Redoran_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Telvanni_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Temple_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Thieves_Guild_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\Twin_Lamps_Icon.dds", 
        "Icons\\Rank Up - Advancement Notifications\\East_Empire_Icon.dds"
    }
    IconScale = 0.13
    IconBorderRight = 0
    IconBorderLeft = 0
    return
end