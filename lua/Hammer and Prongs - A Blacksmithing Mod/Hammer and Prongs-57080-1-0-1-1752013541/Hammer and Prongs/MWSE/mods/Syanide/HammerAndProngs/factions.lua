local function isInFaction(factionId)
    local faction = tes3.getFaction(factionId)
    return faction and faction.playerRank and faction.playerRank >= 0
end

local factionNames = {
    -- Original factions
    "Redoran", "Thieves Guild", "Temple", "Imperial Cult", "Imperial Knights",	
    "Hlaalu", "Telvanni", "Fighters Guild", "Morag Tong", "Ashlanders", "Blades",
    "Clan Quarra", "Clan Aundae", "Clan Berne", "Camonna Tong", "Imperial Legion",
    "Mages Guild", "Sixth House", "Census and Excise", "Twin Lamps", "Nerevarine",
    "Talos Cult", "Royal Guard", "Dark Brotherhood", "Hands of Almalexia",
    "East Empire Company", "Skaal",

    -- TR Factions
    "T_Cyr_AbeceanTradingCompany", "T_Cyr_Blades", "T_Cyr_CensusAndExcise",
    "T_Cyr_DarkBrotherhood", "T_Cyr_FightersGuild", "T_Cyr_ImperialCult",
    "T_Cyr_ImperialCuria", "T_Cyr_ImperialLegion", "T_Cyr_ImperialNavy",
    "T_Cyr_ItinerantPriests", "T_Cyr_KingdomAnvil", "T_Cyr_KingdomKvatch",
    "T_Cyr_KingdomSutch", "T_Cyr_MagesGuild", "T_Cyr_NibenHierophants",
    "T_Cyr_ThievesGuild", "T_Cyr_VampirumOrder", "T_Glb_ArchaeologicalSociety",
    "T_Glb_AstrologicalSociety", "T_Glb_BarristersGuild", "T_Glb_CourtesansGuild",
    "T_Glb_GeographicalSociety", "T_Glb_RatcatchersGuild", "T_Glb_ScenaristsGuild",
    "T_Ham_Crowns", "T_Ham_MagesGuild", "T_Ham_RaHabiCompany",
    "T_Ham_So-MitanaCompany", "T_Ham_SogatDurGada", "T_Mw_Clan_Baluath",
    "T_Mw_Clan_Orlukh", "T_Mw_HouseDres", "T_Mw_HouseIndoril",
    "T_Mw_ImperialNavy", "T_Mw_JaNattaSyndicate", "T_Mw_Shinathi",
    "T_Sky_Alovach", "T_Sky_Bearclan", "T_Sky_Bordraigh", "T_Sky_Braign",
    "T_Sky_ClanKhulari", "T_Sky_Companions", "T_Sky_DarkBrotherhood",
    "T_Sky_FightersGuild", "T_Sky_FireHandClan", "T_Sky_Hunnath",
    "T_Sky_ImperialCult", "T_Sky_ImperialLegion", "T_Sky_ImperialNavy",
    "T_Sky_MagesGuild", "T_Sky_Nourthu", "T_Sky_Pachkan",
    "T_Sky_RoyalHaafingarCompany", "T_Sky_Taliesinn", "T_Sky_ThievesGuild"
}

factions = {}

for _, name in ipairs(factionNames) do
    -- remove spaces and capitalize first letter of each word for function name
    local key = "is" .. name:gsub("(%w)(%w*)", function(a,b) return a:upper()..b end):gsub(" ", "")
    factions[key] = function()
        return isInFaction(name)
    end
end

-- Example usage:
-- if factions.isRedoran() then ...
-- if factions.isT_Sky_Bearclan() then ...
