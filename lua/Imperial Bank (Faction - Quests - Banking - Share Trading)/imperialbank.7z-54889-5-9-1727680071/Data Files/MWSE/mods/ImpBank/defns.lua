--[[Stores all the relevant definitions and static data for the mod.
This includes:
1) The item ids being monitored.
2) How the prices should change whenever the JournalIndex for certain quests is changed.
3) How the prices should change each day.
]]
---@class vaelta.IB.defns
local defns = {
    -- Holds all the ids of items that we care about changing the price of
    ---@type table<string, boolean>
    SPECIAL_ITEM_IDS = {},
}
---@enum vaelta.IB.CC
local CC = {
    ebony = "vaib_com_ebony",
    kwama = "vaib_com_kwama",
    saltrice = "vaib_com_saltrice",
    gold = "vaib_com_gold",
    glass = "vaib_com_glass",
    mead = "vaib_com_mead",
    hides = "vaib_com_hides",
    comberries = "vaib_com_comberries",
}
defns.CC = CC

---@enum vaelta.IB.SC
local SC = {
    hlaalu = "vaib_stock_hlaalu",
    telvanni = "vaib_stock_telvanni",
    redoran = "vaib_stock_redoran",
    indoril = "vaib_stock_indoril",
    dres = "vaib_stock_dres",
    eec = "vaib_stock_eec",
    zafirbel = "vaib_stock_zafirbel",
    impbank = "vaib_stock_impbank",
    mages = "vaib_stock_mages",
    fighters = "vaib_stock_fighters",
    bearclan = "vaib_stock_bearclan",
}
defns.SC = SC

defns.SPECIAL_ITEM_IDS = {}

for _, id in pairs(defns.CC) do
    defns.SPECIAL_ITEM_IDS[id] = true
end
for _, id in pairs(defns.SC) do
    defns.SPECIAL_ITEM_IDS[id] = true
end
defns.SPECIAL_ITEM_IDS["gold_001"] = true

---@class vaelta.IB.player_data
---@field day integer The day the share prices were last updated.
defns.DEFAULT_PLAYER_DATA = {
    day = -math.huge
}


-- =============================================================================
-- DAILY CHANGE DATA
-- =============================================================================

---@class vaelta.IB.daily_change_data
---@field id vaelta.IB.CC|vaelta.IB.SC id of the stock being changed
---@field swan_chance integer the swan chance
---@field min integer the minimum chance
---@field max integer the maximum chance


---@type vaelta.IB.daily_change_data[]
defns.daily_changes = {
	---House Hlaalu
	{id=SC.hlaalu, min=-7, max=6, swan_chance=45},
	---House Telvanni
	{id=SC.telvanni, min=-10, max=9, swan_chance=35},
	---House Redoran
	{id=SC.redoran, min=-7, max=5, swan_chance=55},
	---House Indoril
	{id=SC.indoril, min=-6, max=4, swan_chance=60},
	---House Dres
	{id=SC.dres, min=-5, max=4, swan_chance=60},
	---EEC
	{id=SC.eec, min=-6, max=4, swan_chance=40},
	---Imperial Bank
	{id=SC.impbank, min=-7, max=7, swan_chance=40},
	---Mages Guild
	{id=SC.mages, min=-7, max=5, swan_chance=50},
	---Fighters Guild
	{id=SC.fighters, min=-8, max=6, swan_chance=40},
	---Zafirbel Bay Company
	{id=SC.zafirbel, min=-12, max=8, swan_chance=30},
	---Bear Clan
	{id=SC.bearclan, min=-25, max=15, swan_chance=15},
	---Ebony
	{id=CC.ebony, min=-12, max=12, swan_chance=20},
	---Kwama
	{id=CC.kwama, min=-4, max=2, swan_chance=55},
	---Saltrice
	{id=CC.saltrice, min=-4, max=3, swan_chance=55},
	---Gold
	{id=CC.gold, min=-9, max=8, swan_chance=30},
	---Glass
	{id=CC.glass, min=-11, max=10, swan_chance=35},
	---Mead
	{id=CC.mead, min=-4, max=3, swan_chance=65},
	---Hides
	{id=CC.hides, min=-5, max=3, swan_chance=55},
	---Comberries
	{id=CC.comberries, min=-4, max=3, swan_chance=65},
}

-- =============================================================================
-- QUEST PROGRESS UPDATE DATA
-- =============================================================================


-- Stores data that's used to calculate how much the price of a stock should decrease.
---@class vaelta.IB.penalty_data
---@field id vaelta.IB.CC|vaelta.IB.SC id of the stock being changed
---@field min integer the minimum amount
---@field max integer the maximum amount

-- Stores data that's used to calculate how much the price of a stock should increase.
---@class vaelta.IB.bonus_data
---@field id vaelta.IB.CC|vaelta.IB.SC id of the stock being changed
---@field min integer the minimum amount
---@field max integer the maximum amount

-- Stores information about how the prices should change for a `JournalIndex` of some quest.
---@class vaelta.IB.index_data
---@field min_index integer? minimium journal index for this to fire
---@field index integer? journal index for this to fire
---@field bonuses vaelta.IB.bonus_data[]? bonuses that get applied on this update
---@field penalties vaelta.IB.penalty_data[]? penalties that get applied on this update

-- Indexed by quest id. 
-- Values are arrays of `index_data`s. each holds the relevant journal index, and the bonuses/penalties associated to that index.
---@type table<string, vaelta.IB.index_data[]>
defns.quest_progress_bonuses = {

    -- We'll annotate the first piece of data in more detail to explain how the overall structure works.
 
    -- For each quest id, we get an array of data. This array has only one entry.
    ["hh_disguisedarmor"]={
       
       { -- START OF FIRST DATA ENTRY
 
          -- the JournalIndex that triggers this update.
          -- NOTE: semicolons work exactly the same as commas when defining tables.
          -- so `index=100;` is the same as `index=100,`.
          -- the only difference is that semicolons are a bit easier to read in more compact table definitions.
          index=100; 
 
          -- Data about which stocks should INCREASE in value, and how much they should increase.
          -- `id` is the stock id.
          -- `min` is the minimium amount of increase (first argument to `get_bonus_multiplier`)
          -- `max` is the maximum amount of increase (second argument to `get_bonus_multiplier`)
          bonuses={
             {id=SC.hlaalu; min=105; max=120};
          }; 
          -- Data about which stocks should DECREASE in value, and how much they should decrease.
          -- `id` is the stock id.
          -- `min` is the minimium amount of decrease (first argument to `get_penalty_multiplier`)
          -- `max` is the maximum amount of decrease (second argument to `get_penalty_multiplier`)
          penalties={
             {id=SC.redoran; min=85; max=95}
          }
 
       } -- END OF FIRST DATA ENTRY
    };
 
    -- the rest of the entries have been compacted down into a few lines so the file is easier to navigate.
 
    ["hh_indesp1"]={{index=100; bonuses={{id=SC.hlaalu; min=105; max=110}}; penalties={{id=SC.indoril; min=80; max=95}}}};
 
    ["hh_eggmine"]={{min_index=100; penalties={{id=SC.hlaalu; min=90; max=95}; {id=CC.kwama; min=80; max=95}}}};
 
    ["hh_indesp2"]={{index=100; bonuses={{id=SC.hlaalu; min=110; max=120}}; penalties={{id=SC.indoril; min=80; max=95}}}};
 
    ["hh_indesp3"]={{index=100; bonuses={{id=SC.hlaalu; min=105; max=120}}; penalties={{id=SC.redoran; min=85; max=95}}}};
 
    ["hh_retaliation"]={{min_index=100; bonuses={{id=SC.hlaalu; min=105; max=110}}}};
 
    ["hh_indesp4"]={
       {min_index=100; bonuses={{id=SC.hlaalu; min=110; max=140}; {id=SC.eec; min=110; max=160}}; penalties={{id=SC.redoran; min=50; max=80}}};
    };
 
    ["hh_odirniran"]={{index=100; bonuses={{id=SC.hlaalu; min=115; max=130}}; penalties={{id=SC.telvanni; min=75; max=95}}}};
 
    ["hh_ashlanderebony"]={
       {
          index=100;
          bonuses={{id=SC.hlaalu; min=115; max=140}; {id=CC.ebony; min=145; max=180}};
          penalties={{id=SC.telvanni; min=75; max=95}; {id=SC.redoran; min=85; max=95}};
       };
    };
 
    ["hh_guardmerchant"]={{min_index=100; bonuses={{id=SC.hlaalu; min=105; max=110}}}};
 
    ["hh_nordsmugglers"]={{min_index=100; bonuses={{id=SC.hlaalu; min=105; max=110}}}};
 
    ["hh_destroyindarysmanor"]={
       {index=100; bonuses={{id=SC.hlaalu; min=115; max=150}}; penalties={{id=SC.redoran; min=60; max=80}}};
    };
 
    ["hh_destroyteluvirith"]={{index=100; bonuses={{id=SC.hlaalu; min=115; max=150}}; penalties={{id=SC.telvanni; min=60; max=80}}}};
 
    ["hh_bankfraud"]={{index=100; penalties={{id=SC.hlaalu; min=85; max=95}}}};
 
    ["hh_capturespy"]={{min_index=100; bonuses={{id=SC.hlaalu; min=105; max=110}}}};
 
    ["hh_replacedocs"]={{index=100; penalties={{id=SC.hlaalu; min=85; max=95}}}};
 
    ["hh_winsaryoni"]={{index=100; bonuses={{id=SC.hlaalu; min=110; max=120}}}};
 
    ["hh_wincamonna"]={{min_index=100; bonuses={{id=SC.hlaalu; min=115; max=130}}}};
 
    ["hh_stronghold"]={
       {index=300; bonuses={{id=SC.hlaalu; min=110; max=140}}; penalties={{id=SC.telvanni; min=90; max=95}; {id=SC.redoran; min=90; max=95}}};
    };
 
 
 
    ---house hlaalu tr
    ["tr_m3_at_catcatchers"]={{index=130; bonuses={{id=SC.hlaalu; min=105; max=110}}}};
 
    ["tr_m4_hh_and_caravanransom"]={{index=100; bonuses={{id=SC.hlaalu; min=115; max=125}}}};
 
    ["tr_m4_hh_and_docksquests"]={{index=100; bonuses={{id=SC.hlaalu; min=105; max=110}}}};
 
    ["tr_m4_hh_and_employment"]={{index=100; bonuses={{id=SC.hlaalu; min=105; max=110}}}};
 
    ["tr_m4_hh_and_greef"]={{index=100; bonuses={{id=SC.hlaalu; min=115; max=125}}}};
 
    ["tr_m4_hh_and_hearing"]={{min_index=100; bonuses={{id=SC.hlaalu; min=115; max=125}}}};
 
    ["tr_m4_hh_and_omaynisinn"]={{index=100; bonuses={{id=SC.hlaalu; min=105; max=115}}}};
 
    ["tr_m4_hh_and_reverserescue"]={{index=100; bonuses={{id=SC.hlaalu; min=110; max=115}}}};
 
    ["tr_m4_hh_and_ship"]={{index=100; bonuses={{id=SC.hlaalu; min=110; max=115}}}};
 
    ["tr_m4_hh_salvaniwine"]={{index=100; bonuses={{id=SC.hlaalu; min=110; max=115}}}};
 
    ["tr_m4_hh_ulvo1"]={{index=100; bonuses={{id=SC.hlaalu; min=110; max=115}}}};
 
    ["tr_m4_ob_poisoning_the_well"]={{index=100; bonuses={{id=SC.hlaalu; min=105; max=115}}}};
 
    ["tr_m7_hh_sathis2"]={{index=100; bonuses={{id=SC.hlaalu; min=105; max=115}}; penalties={{id=SC.indoril; min=90; max=95}}}};
 
    ["tr_m7_hh_sathis4"]={{min_index=200; bonuses={{id=SC.hlaalu; min=105; max=115}}}};
 
    ["tr_m7_hh_sathis5"]={{index=100; bonuses={{id=SC.hlaalu; min=105; max=115}}; penalties={{id=SC.indoril; min=85; max=95}}}};
 
    ["tr_m7_hh_sathis6"]={{index=175; bonuses={{id=SC.hlaalu; min=105; max=115}}; penalties={{id=SC.indoril; min=85; max=95}}}};
 
 
 
    ---misc tr
    ["tr_m7_ho_cluelesseggminer"]={{index=120; bonuses={{id=CC.kwama; min=130; max=155}}}};
 
 
 
    ---house redoran 
    ["hr_stronghold"]={
       {index=300; bonuses={{id=SC.redoran; min=110; max=140}}; penalties={{id=SC.telvanni; min=90; max=95}; {id=SC.hlaalu; min=90; max=95}}};
    };
 
    ["hr_mudcrabnest"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}}};
 
    ["hr_courier"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}}};
 
    ["hr_finddalobar"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}}};
 
    ["hr_foundershelm"]={{index=100; bonuses={{id=SC.redoran; min=115; max=120}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
 
    ["hr_guardguarherds"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}}};
 
    ["hr_guardsarethi"]={{index=100; bonuses={{id=SC.redoran; min=110; max=125}}}};
 
    ["hr_oldbluefin"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}}};
 
    ["hr_ashimanumine"]={{index=100; bonuses={{id=SC.redoran; min=115; max=120}; {id=CC.kwama; min=120; max=140}}}};
 
    ["hr_kagouti"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}; {id=CC.kwama; min=105; max=115}}}};
 
    ["hr_shishireport"]={{index=110; bonuses={{id=SC.redoran; min=115; max=135}}; penalties={{id=SC.telvanni; min=80; max=95}}}};
 
    ["hr_cultelimination"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}}};
 
    ["hr_honorchallenge"]={{index=100; bonuses={{id=SC.redoran; min=115; max=120}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
 
    ["hr_shurinbaal"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}}};
 
    ["hr_archmaster"]={{index=100; bonuses={{id=SC.redoran; min=110; max=130}}}};
 
    ["hr_lostbanner"]={{index=100; bonuses={{id=SC.redoran; min=105; max=115}}}};
 
    ["hr_taxcollector"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}}};
 
    ["hr_calderacorrupt"]={
       {
          index=100;
          bonuses={{id=SC.redoran; min=110; max=120}};
          penalties={{id=SC.hlaalu; min=85; max=95}; {id=SC.eec; min=90; max=95}; {id=CC.ebony; min=90; max=95}};
       };
    };
 
    ["hr_calderadisrupt"]={
       {
          index=100;
          bonuses={{id=SC.redoran; min=130; max=160}};
          penalties={{id=SC.hlaalu; min=60; max=85}; {id=SC.eec; min=60; max=85}; {id=CC.ebony; min=60; max=85}};
       };
    };
 
    ["hr_arobarkidnap"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}; penalties={{id=SC.telvanni; min=85; max=95}}}};
 
    ["hr_hlaanoslanders"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
 
    ["hr_cowarddisgrace"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}; penalties={{id=SC.hlaalu; min=90; max=95}}}};
 
    ["hr_dagothtanis"]={{index=100; bonuses={{id=SC.redoran; min=105; max=110}}}};
 
    ["hr_attackuvirith"]={{index=100; bonuses={{id=SC.redoran; min=115; max=125}}; penalties={{id=SC.telvanni; min=75; max=95}}}};
 
    ["hr_attackrethan"]={{index=100; bonuses={{id=SC.redoran; min=115; max=125}}; penalties={{id=SC.hlaalu; min=75; max=95}}}};
 
 
 
    ---house redoran lgnpc
    ["jo_amarobar"]={{index=120; bonuses={{id=SC.redoran; min=105; max=125}}}};
    
    ["jo_amllethri"]={{index=110; bonuses={{id=SC.redoran; min=115; max=125}}; penalties={{id=SC.hlaalu; min=75; max=95}}}};
       
    ["jo_lmtraitor"]={{index=120; bonuses={{id=SC.redoran; min=105; max=115}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
    
    ["jo_ndisguisedarmor"]={{index=100; bonuses={{id=SC.redoran; min=105; max=115}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
        
    ["jo_lmmonopoly"]={
       {index=30;
        bonuses={{id=SC.redoran; min=105; max=110}; {id=SC.mages; min=105; max=120}};
        penalties={{id=SC.telvanni; min=75; max=95}}
        };
       {index=40;
        bonuses={{id=SC.redoran; min=105; max=110}; {id=SC.telvanni; min=115; max=125}};
        penalties={{id=SC.mages; min=40; max=75}}
        };
    };
    
    ["jo_amllethri"]={
       {index=110; bonuses={{id=SC.redoran; min=115; max=125}}; penalties={{id=SC.hlaalu; min=75; max=95}} };
       {index=120; bonuses={{id=SC.redoran; min=115; max=125}}; penalties={{id=SC.hlaalu; min=75; max=95}} };
    };
    
    ["jo_amsarethi"]={
       {index=100; bonuses={{id=SC.redoran; min=105; max=110}} };
       {index=110; bonuses={{id=SC.redoran; min=110; max=115}} };
       {index=120; bonuses={{id=SC.redoran; min=110; max=125}} };
    };
    
    ["jo_fr_guril"]={{index=100; bonuses={{id=SC.redoran; min=105; max=120}}};
                     {index=110; penalties={{id=SC.redoran; min=75; max=95}}};
                    };
    
    ["jo_ilentius"]={{index=100; bonuses={{id=SC.redoran; min=105; max=120}}};
                     {index=120; penalties={{id=SC.redoran; min=80; max=95}}};
                     {index=130; penalties={{id=SC.redoran; min=90; max=95}}};
                     {index=140; bonuses={{id=SC.redoran; min=105; max=115}}};
                    };
                    
                    
    
    ---mages guild magical missions recharged
    ["vd_mg2_antlassalobar"]={
       {index=40; bonuses={{id=SC.mages; min=105; max=115}}; penalties={{id=SC.telvanni; min=80; max=95}} };
       {index=50; bonuses={{id=SC.mages; min=105; max=115}}; penalties={{id=SC.telvanni; min=80; max=95}} };
    };
    
    ["vd_mg3_hlaaluvault"]={
       {index=101; bonuses={{id=SC.mages; min=110; max=120}}; bonuses={{id=SC.hlaalu; min=105; max=110}} };
    };
    
    ["vd_mg4_gameofwits"]={
       {index=40; penalties={{id=SC.mages; min=85; max=95}}; bonuses={{id=SC.telvanni; min=105; max=115}} };
       {index=50; bonuses={{id=SC.mages; min=110; max=120}}; penalties={{id=SC.telvanni; min=80; max=95}} };
       {index=60; bonuses={{id=SC.mages; min=105; max=115}}; penalties={{id=SC.telvanni; min=70; max=80}} };
       {index=70; bonuses={{id=SC.mages; min=105; max=110}} };
    };
    
 
    ---house telvanni 
    ["town_tel_vos"]={{index=35; bonuses={{id=SC.telvanni; min=105; max=110}}}};
    
    ["lor_tpb_ht_chair"]={{index=60; bonuses={{id=SC.telvanni; min=105; max=110}}; penalties={{id=SC.mages; min=85; max=95}}}};
    
    ["lor_tpb_ht_nchurdamz"]={{index=50; bonuses={{id=SC.telvanni; min=105; max=110}}}};
    
    ["lor_tpb_ht_recruitmouths"]={{index=50; bonuses={{id=SC.telvanni; min=105; max=110}}}};
    
    ["lor_tpb_ht_swaycouncil"]={{index=80; bonuses={{id=SC.telvanni; min=110; max=120}}}};
    
    ["lor_tpb_ht_tiramsfindings"]={{index=50; bonuses={{id=SC.telvanni; min=105; max=110}}; penalties={{id=SC.mages; min=85; max=95}}}};
    
    ["lor_tpb_ht_tiramsfindings"]={{index=55; bonuses={{id=SC.telvanni; min=105; max=110}}; penalties={{id=SC.mages; min=85; max=95}}}};
    
    ["lor_tpb_ht_aryonsrequest"]={{index=50; bonuses={{id=SC.telvanni; min=105; max=110}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
    
    ["lor_tpb_ht_archmagister"]={{index=100; bonuses={{id=SC.telvanni; min=130; max=150}}}};
    
    ["ht_stronghold"]={
       {index=300; bonuses={{id=SC.telvanni; min=110; max=140}}; penalties={{id=SC.redoran; min=90; max=95}; {id=SC.hlaalu; min=90; max=95}}};
    };
 
    ["ht_slaverebellion"]={{index=100; bonuses={{id=SC.telvanni; min=115; max=125}; {id=CC.kwama; min=120; max=140}}}};
 
    ["ht_baladasally"]={{index=100; bonuses={{id=SC.telvanni; min=105; max=110}}}};
 
    ["ht_minecure"]={{index=100; bonuses={{id=SC.telvanni; min=115; max=120}}}};
 
    ["ht_odirniran"]={{index=100; bonuses={{id=SC.telvanni; min=110; max=130}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
 
    ["ht_monopoly"]={{index=100; bonuses={{id=SC.telvanni; min=130; max=160}}; penalties={{id=SC.mages; min=50; max=80}}}};
 
    ["ht_shishi"]={{index=100; bonuses={{id=SC.telvanni; min=110; max=130}}; penalties={{id=SC.redoran; min=85; max=95}}}};
 
    ["ht_attackrethan"]={{index=100; bonuses={{id=SC.telvanni; min=110; max=130}}; penalties={{id=SC.hlaalu; min=75; max=95}}}};
 
    ["ht_attackindarys"]={{index=100; bonuses={{id=SC.telvanni; min=110; max=130}}; penalties={{id=SC.redoran; min=75; max=95}}}};
 
    ["ht_archmagister"]={{index=100; bonuses={{id=SC.telvanni; min=125; max=150}}}};
 
 
 
    ---house telvanni tr
    ["tr_m1_ht_fa2"]={{index=200; bonuses={{id=SC.telvanni; min=110; max=125}}}};
 
    ["tr_m1_ht_mi1"]={{index=60; bonuses={{id=SC.telvanni; min=110; max=115}}}};
 
    ["tr_m1_ht_mi2"]={{index=50; bonuses={{id=SC.telvanni; min=110; max=115}}}};
 
    ["tr_m1_ht_va1"]={{index=101; bonuses={{id=SC.telvanni; min=110; max=115}}; penalties={{id=SC.indoril; min=85; max=95}}}};
 
    ["tr_m1_ht_va2"]={{index=100; bonuses={{id=SC.telvanni; min=110; max=115}}; penalties={{id=SC.indoril; min=85; max=95}}}};
 
    ["tr_m1_ito_soulswipe"]={{index=40; bonuses={{id=SC.telvanni; min=115; max=125}}; penalties={{id=SC.mages; min=80; max=95}}}};
 
 
     ---house telvanni lgnpc tel uvirith
    ["jo_tuashlanders"]={{index=100; bonuses={{id=SC.telvanni; min=105; max=115}}};
                         {index=110; bonuses={{id=SC.telvanni; min=105; max=115}}};
                         {index=120; bonuses={{id=SC.telvanni; min=105; max=115}}};
                         {index=130; bonuses={{id=SC.telvanni; min=105; max=115}}};
                        };
                        
    ["jo_tuchallenge"]={{index=100; bonuses={{id=SC.telvanni; min=105; max=115}}};
                         {index=110; bonuses={{id=SC.telvanni; min=105; max=115}}};
                        };
                        
    ["jo_tucultists"]={{index=110; bonuses={{id=SC.telvanni; min=105; max=115}}}};
    
    ["jo_vdnobleht"]={{index=100; bonuses={{id=SC.telvanni; min=105; max=120}}}};
 
 
 
 
    ---morag tong
    ["mt_writoran"]={{min_index=100; bonuses={{id=SC.redoran; min=115; max=125}}; penalties={{id=SC.hlaalu; min=80; max=95}}}};
 
    ["mt_writsaren"]={{min_index=100; penalties={{id=SC.redoran; min=70; max=95}}; bonuses={{id=SC.hlaalu; min=115; max=135}}}};
 
    ["mt_writvendu"]={{min_index=100; bonuses={{id=SC.redoran; min=105; max=115}}; penalties={{id=SC.telvanni; min=70; max=95}}}};
 
    ["mt_writguril"]={{min_index=100; penalties={{id=SC.redoran; min=70; max=95}}; bonuses={{id=SC.hlaalu; min=115; max=135}}}};
 
    ["mt_writgalasa"]={{min_index=100; bonuses={{id=SC.redoran; min=105; max=115}}; penalties={{id=SC.hlaalu; min=90; max=95}}}};
 
    ["mt_writmavon"]={{min_index=100; bonuses={{id=SC.redoran; min=105; max=115}}; penalties={{id=SC.telvanni; min=70; max=95}}}};
 
    ["mt_writbelvayn"]={{min_index=100; bonuses={{id=SC.redoran; min=105; max=115}}; penalties={{id=SC.telvanni; min=70; max=95}}}};
 
    ["mt_writbemis"]={{min_index=100; bonuses={{id=SC.redoran; min=105; max=115}}; penalties={{id=SC.hlaalu; min=90; max=95}}}};
 
    ["mt_writbrilnosu"]={{min_index=100; bonuses={{id=SC.redoran; min=105; max=115}}; penalties={{id=SC.telvanni; min=90; max=95}}}};
 
    ["mt_writnavil"]={{min_index=100; bonuses={{id=SC.redoran; min=115; max=125}}; penalties={{id=SC.hlaalu; min=70; max=95}}}};
 
    ["mt_writbaladas"]={{min_index=100; bonuses={{id=SC.hlaalu; min=115; max=125}}; penalties={{id=SC.telvanni; min=60; max=85}}}};
 
    ["mt_writbero"]={{min_index=100; bonuses={{id=SC.redoran; min=115; max=125}}; penalties={{id=SC.hlaalu; min=65; max=95}}}};
 
    ["mt_writtherana"]={{min_index=100; bonuses={{id=SC.hlaalu; min=115; max=125}}; penalties={{id=SC.telvanni; min=60; max=85}}}};
 
 
 
    ---morag tong tr
    ["tr_m3_mt_felrar"]={{min_index=100; bonuses={{id=SC.indoril; min=115; max=125}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
 
    ["tr_m3_mt_indriri"]={{min_index=100; penalties={{id=SC.redoran; min=85; max=95}}; bonuses={{id=SC.hlaalu; min=105; max=115}}}};
 
    ["tr_m4_mt_almse"]={{min_index=100; penalties={{id=SC.redoran; min=85; max=95}}; bonuses={{id=SC.hlaalu; min=105; max=115}}}};
 
    ["tr_m4_mt_llirala"]={{min_index=100; bonuses={{id=SC.indoril; min=115; max=135}}; penalties={{id=SC.hlaalu; min=65; max=95}}}};
 
    ["tr_m4_mt_nadrasarvel"]={
       {min_index=100; bonuses={{id=SC.indoril; min=105; max=125}}; penalties={{id=SC.hlaalu; min=85; max=95}}};
    };
 
    ["tr_m4_mt_omayn"]={{min_index=100; bonuses={{id=SC.indoril; min=105; max=125}}; penalties={{id=SC.hlaalu; min=65; max=95}}}};
 
    ["tr_m4_mt_serali"]={{min_index=100; bonuses={{id=SC.indoril; min=105; max=125}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
 
 
 
    ---mages guild
    ["mg_guildmaster"]={{index=100; bonuses={{id=SC.mages; min=110; max=140}}}};
 
    ["mg_joinus"]={{index=100; bonuses={{id=SC.mages; min=105; max=115}}; penalties={{id=SC.telvanni; min=75; max=95}}}};
 
    ["mg_stopcompetition"]={{min_index=100; bonuses={{id=SC.mages; min=105; max=115}}}};
 
    ["mg_spycatch"]={{index=100; bonuses={{id=SC.mages; min=110; max=125}}; penalties={{id=SC.telvanni; min=70; max=90}}}};
 
    ["mg_apprentice"]={{index=100; bonuses={{id=SC.mages; min=105; max=115}}}};
 
    ["mg_science"]={{index=100; bonuses={{id=SC.mages; min=105; max=115}}}};
 
    ["mg_excavation"]={{min_index=100; bonuses={{id=SC.mages; min=110; max=125}}}};
 
    ["mg_mzuleft"]={{index=100; bonuses={{id=SC.mages; min=105; max=115}}}};
 
    ["mg_bethamez"]={{index=100; bonuses={{id=SC.mages; min=105; max=115}}}};
 
    ["mg_killtelvanni"]={{index=100; penalties={{id=SC.mages; min=60; max=80}; {id=SC.telvanni; min=10; max=50}}}};
 
    ["mg_dwarves"]={{index=100; bonuses={{id=SC.mages; min=120; max=135}}}};
 
 
 
    ---mages guild tr
    ["tr_m1_fw_mg05"]={{index=100; bonuses={{id=SC.mages; min=110; max=115}}}};
 
    ["tr_m1_fw_mg08"]={{index=100; bonuses={{id=SC.mages; min=110; max=120}}; penalties={{id=SC.telvanni; min=80; max=95}}}};
 
    ["tr_m1_fw_mg09"]={{index=100; bonuses={{id=SC.mages; min=110; max=120}}; penalties={{id=SC.telvanni; min=80; max=95}}}};
 
    ["tr_m2_mg_polodie1"]={{index=140; bonuses={{id=SC.mages; min=110; max=115}}}};
 
    ["tr_m2_mg_polodie2"]={{index=100; bonuses={{id=SC.mages; min=110; max=115}}}};
 
    ["tr_m3_mg_oe_guards1"]={{index=80; bonuses={{id=SC.mages; min=105; max=110}}}};
 
    ["tr_m4_mg_ando_4"]={{index=100; bonuses={{id=SC.mages; min=110; max=115}}}};
 
 
 
    ---temple tr
    ["tr_m3_tt_lloris1"]={{index=250; penalties={{id=SC.hlaalu; min=75; max=95}; {id=SC.indoril; min=75; max=95}}}};
 
    ["tr_m3_tt_illene1"]={{index=50; bonuses={{id=SC.indoril; min=105; max=115}}}};
 
    ["tr_m3_tt_illene2"]={{index=100; bonuses={{id=SC.indoril; min=110; max=120}}}};
 
    ["tr_m3_tt_illene3"]={
       {index=130; penalties={{id=SC.indoril; min=75; max=95}; {id=SC.hlaalu; min=75; max=95}}};
       {index=150; bonuses={{id=SC.indoril; min=105; max=115}; {id=SC.hlaalu; min=105; max=115}}};
    };
 
    ["tr_m3_tt_lloris3"]={{index=300; bonuses={{id=SC.indoril; min=115; max=135}}}};
 
    ["tr_m3_tt_lloris4"]={
       {index=150; penalties={{id=SC.indoril; min=85; max=95}}; bonuses={{id=SC.hlaalu; min=105; max=115}}};
       {index=200; bonuses={{id=SC.indoril; min=105; max=115}}; penalties={{id=SC.hlaalu; min=85; max=95}}};
    };
 
    ["tr_m3_tt_lloris5"]={
       {index=200; penalties={{id=SC.indoril; min=75; max=95}; {id=SC.hlaalu; min=75; max=95}}};
       {index=210; penalties={{id=SC.indoril; min=75; max=95}; {id=SC.hlaalu; min=75; max=95}}};
       {index=220; penalties={{id=SC.indoril; min=75; max=95}; {id=SC.hlaalu; min=75; max=95}}};
       {index=230; penalties={{id=SC.indoril; min=85; max=95}}; bonuses={{id=SC.hlaalu; min=105; max=115}}};
 
       {index=250; bonuses={{id=SC.indoril; min=105; max=115}; {id=SC.hlaalu; min=105; max=115}}};
 
       {index=255; bonuses={{id=SC.indoril; min=105; max=115}; {id=SC.hlaalu; min=105; max=115}}};
 
       {index=260; bonuses={{id=SC.indoril; min=105; max=115}; {id=SC.hlaalu; min=105; max=115}}};
    };
 
    ["tr_m3_tt_rip"]={{index=300; bonuses={{id=SC.indoril; min=105; max=115}}}};
 
 
 
 
    --- thieves guild
    ["tg_lootaldruhnmg"]={
       {index=100; bonuses={{id=SC.telvanni; min=105; max=115}}; penalties={{id=SC.mages; min=80; max=95}}};
    };
    
    ["tg_masterhelm"]={
       {index=100; penalties={{id=SC.redoran; min=80; max=95}}};
    };
    
    ["tg_dartsjudgement"]={
       {index=100; penalties={{id=SC.redoran; min=80; max=95}}};
       {index=105; penalties={{id=SC.redoran; min=80; max=95}}};
    };
    
    ["tg_withershins"]={
       {index=100; bonuses={{id=SC.telvanni; min=105; max=115}}; penalties={{id=SC.mages; min=80; max=95}}};
    };
    
    ["tg_redorancookbook"]={
       {index=100; penalties={{id=SC.redoran; min=80; max=95}}};
    };
    
    ["tg_ebonystaff"]={
       {index=100; penalties={{id=SC.telvanni; min=80; max=95}}};
       {index=105; penalties={{id=SC.telvanni; min=80; max=95}}};
    };
    
    ["tg_cookbookalchemy"]={
       {index=100; bonuses={{id=SC.mages; min=105; max=115}}; penalties={{id=SC.telvanni; min=80; max=95}}};
    };
    
    ["tg_enemyparley"]={
       {index=100; penalties={{id=SC.hlaalu; min=80; max=95}}};
    };
    
    ["tg_bitterbribe"]={
       {index=100; penalties={{id=SC.hlaalu; min=80; max=95}}};
    };
    
    ["tg_hostage"]={
       {index=100; penalties={{id=SC.hlaalu; min=80; max=95}}};
    };
    
    ["tg_killienith"]={
       {index=100; penalties={{id=SC.hlaalu; min=80; max=95}}};
    };
    
    ["tg_killhardheart"]={
       {index=100; penalties={{id=SC.fighters; min=50; max=60}}};
    };
    
  
 
 
    ---fighters guild
    ["fg_rathunt"]={{index=100; bonuses={{id=SC.fighters; min=102; max=110}}}};
 
    ["fg_egg_poachers"]={
       {index=100; bonuses={{id=SC.fighters; min=110; max=115}; {id=CC.kwama; min=110; max=120}; {id=SC.hlaalu; min=110; max=115}}};
    };
 
    ["fg_telvanni_agents"]={
       {
          index=100;
          bonuses={{id=SC.fighters; min=110; max=115}; {id=CC.ebony; min=110; max=120}; {id=SC.hlaalu; min=110; max=115}};
          penalties={{id=SC.telvanni; min=85; max=95}};
       };
    };
 
    ["fg_deseledebt"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}}}};
 
    ["fg_orcbounty"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}}}};
 
    ["fg_verethigang"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}; {id=CC.ebony; min=110; max=115}}}};
 
    ["fg_nchurdamz"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}}}};
 
    ["fg_dissaplamine"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}}}};
 
    ["fg_corprusstalker"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}; {id=SC.telvanni; min=105; max=110}}}};
 
    ["fg_tenimbounty"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}}}};
 
    ["fg_duniraisupply"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}}}};
 
    ["fg_telasero"]={{index=100; bonuses={{id=SC.fighters; min=115; max=125}}}};
 
    ["fg_engaerbounty"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}}}};
 
    ["fg_findpudai"]={{index=100; bonuses={{id=SC.fighters; min=135; max=165}}}};
 
    ["fg_vas"]={{index=100; bonuses={{id=SC.fighters; min=110; max=125}}}};
 
    ["fg_beneranbounty"]={{index=100; bonuses={{id=SC.fighters; min=110; max=125}}}};
 
    ["fg_suranbandits"]={{index=100; bonuses={{id=SC.fighters; min=110; max=125}}}};
 
    ["fg_elithpalsupply"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}}}};
 
    ["fg_killhardheart"]={{index=100; bonuses={{id=SC.fighters; min=130; max=155}}}};
 
 
 
    ---fighters guild tr
    ["tr_m2_fg_amiro1"]={{index=100; bonuses={{id=SC.fighters; min=102; max=110}}}};
 
    ["tr_m2_fg_amiro2"]={{min_index=100; bonuses={{id=SC.fighters; min=102; max=110}}}};
 
    ["tr_m2_fg_amiro3"]={{index=221; bonuses={{id=SC.fighters; min=102; max=110}}}};
 
    ["tr_m2_fg_hartise_eggmine"]={
       {index=100; bonuses={{id=SC.fighters; min=102; max=110}; {id=CC.kwama; min=110; max=115}}};
    };
 
    ["tr_m2_fg_hartise_rethyn"]={
       {index=100; bonuses={{id=SC.fighters; min=102; max=110}}; penalties={{id=SC.telvanni; min=80; max=95}}};
    };
 
    ["tr_m2_fg_hartise_twilight"]={
       {index=100; bonuses={{id=SC.fighters; min=102; max=110}; {id=SC.telvanni; min=102; max=110}}};
    };
 
    ["tr_m2_fg_irano1"]={{index=100; bonuses={{id=SC.fighters; min=102; max=110}; {id=SC.indoril; min=102; max=110}}}};
 
    ["tr_m2_fg_leonos1"]={{index=60; bonuses={{id=SC.fighters; min=102; max=110}}}};
 
    ["tr_m3_fg_at_3"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}; {id=SC.hlaalu; min=105; max=110}}}};
 
    ["tr_m3_fg_at_5"]={
       {
          index=100;
          bonuses={{id=SC.fighters; min=105; max=110}; {id=SC.hlaalu; min=105; max=110}};
          penalties={{id=SC.indoril; min=85; max=95}};
       };
    };
 
    ["tr_m3_fg_at_6"]={
       {index=100; bonuses={{id=SC.fighters; min=105; max=110}; {id=SC.hlaalu; min=105; max=110}; {id=SC.indoril; min=105; max=110}}};
    };
 
    ["tr_m4_fg_alits"]={{index=100; bonuses={{id=SC.fighters; min=105; max=110}; {id=SC.hlaalu; min=105; max=110}}}};
 
    ["tr_m4_fg_cliffracer"]={{index=200; bonuses={{id=SC.fighters; min=105; max=110}; {id=SC.hlaalu; min=105; max=110}}}};
 
    ["tr_m4_fg_ushukur3"]={{index=200; bonuses={{id=SC.fighters; min=105; max=110}; {id=SC.hlaalu; min=105; max=110}}}};
 
    ["tr_m4_fg_ushukur4"]={{index=300; bonuses={{id=SC.fighters; min=105; max=110}; {id=SC.hlaalu; min=105; max=110}}}};
 
    ["tr_m4_fg_ushukur5"]={
       {index=500; bonuses={{id=SC.fighters; min=115; max=125}}; penalties={{id=SC.hlaalu; min=85; max=95}}};
    };
 
 
 
    ---eec bloodmoon
    ["co_1"]={{index=50; bonuses={{id=SC.eec; min=102; max=110}; {id=CC.ebony; min=110; max=115}}}};
 
    ["co_2"]={{min_index=90; bonuses={{id=SC.eec; min=105; max=115}; {id=CC.ebony; min=110; max=115}}}};
 
    ["co_3"]={{index=70; penalties={{id=SC.eec; min=85; max=95}}}};
 
    ["co_5"]={
       {index=80; bonuses={{id=SC.eec; min=110; max=125}; {id=CC.ebony; min=110; max=115}}};
       {index=70; bonuses={{id=SC.eec; min=110; max=125}; {id=CC.ebony; min=110; max=115}}};
    };
 
    ["co_8"]={{index=60; bonuses={{id=SC.eec; min=110; max=115}; {id=CC.ebony; min=110; max=115}}}};
 
    ["co_10"]={
       {index=100; bonuses={{id=SC.eec; min=110; max=115}; {id=CC.ebony; min=110; max=115}}};
       {index=110; bonuses={{id=SC.eec; min=110; max=115}; {id=CC.ebony; min=110; max=115}}};
    };
 
    ["co_12"]={{index=110; bonuses={{id=SC.eec; min=110; max=115}; {id=CC.ebony; min=110; max=115}}}};
 
    ["co_estate"]={{index=50; bonuses={{id=SC.eec; min=120; max=135}; {id=CC.ebony; min=130; max=145}}}};
 
    ["co_12a"]={{index=50; penalties={{id=SC.eec; min=50; max=95}; {id=CC.ebony; min=80; max=95}}}};
 
    ["co_13a"]={{index=60; penalties={{id=SC.eec; min=50; max=95}; {id=CC.ebony; min=50; max=75}}}};
 
 
 
    ---eec tr
    ["tr_m2_ao_flingalore"]={{index=100; bonuses={{id=SC.eec; min=102; max=110}}}};
 
    ["tr_m3_eec_counterfeit"]={{index=40; bonuses={{id=SC.eec; min=110; max=115}}}};
 
    ["tr_m3_eec_ebony"]={{index=82; bonuses={{id=SC.eec; min=110; max=115}}}};
 
    ["tr_m3_eec_excise"]={{index=70; bonuses={{id=SC.eec; min=110; max=115}}}};
 
 
    ---eec ebonheart mod
    ["eec_caldera"]={
       {index=100;
        bonuses={{id=CC.ebony; min=105; max=110}; {id=SC.hlaalu; min=105; max=110} };
        penalties={{id=SC.eec; min=80; max=85}}
        };
       {index=110; bonuses={{id=SC.eec; min=105; max=110}; {id=CC.ebony; min=105; max=110}; {id=SC.hlaalu; min=105; max=110} }};
       {index=120; bonuses={{id=SC.eec; min=110; max=115}; {id=CC.ebony; min=105; max=115}; {id=SC.hlaalu; min=101; max=107} }};
       {index=130; bonuses={{id=SC.eec; min=115; max=125}; {id=CC.ebony; min=105; max=115}; {id=SC.hlaalu; min=101; max=105} }};
    };
    
    ["eec_competition"]={
       {index=100; bonuses={{id=SC.eec; min=105; max=110}; {id=CC.ebony; min=105; max=110}; {id=SC.telvanni; min=115; max=140} }};
       {index=110; bonuses={{id=SC.eec; min=105; max=110}; {id=CC.ebony; min=105; max=110}; {id=SC.redoran; min=115; max=140} }};
       {index=120; bonuses={{id=SC.eec; min=105; max=110}; {id=CC.ebony; min=105; max=115}; {id=SC.indoril; min=115; max=140} }};
       {index=130; bonuses={{id=SC.eec; min=105; max=115}; {id=CC.ebony; min=105; max=115}; {id=SC.hlaalu; min=115; max=140} }};
    };
    
    ["eec_glassmineghost"]={
       {index=100; penalties={{id=SC.eec; min=75; max=90}; {id=CC.glass; min=75; max=90}} };
       {index=110; bonuses={{id=SC.eec; min=110; max=120}; {id=CC.glass; min=105; max=125}} };
    };
    
    ["eec_reviewer"]={
       {index=100; penalties={id=SC.eec; min=75; max=90} };
       {index=110; bonuses={id=SC.eec; min=110; max=120} };
    };
    
    ["eec_smugglers"]={
       {index=100; bonuses={id=SC.eec; min=101; max=105} };
       {index=110; bonuses={id=SC.eec; min=105; max=108} };
       {index=120; bonuses={id=SC.eec; min=115; max=125} };
    };
    
    ["eec_troubleatminered"]={
       {index=100;
        bonuses={{id=CC.ebony; min=101; max=105}; {id=SC.redoran; min=105; max=110}};
        penalties={{id=SC.eec; min=80; max=95}}
        };
       {index=110;
        bonuses={{id=SC.eec; min=105; max=115}; {id=CC.ebony; min=101; max=105}; {id=SC.redoran; min=101; max=106}}
        };
       {index=120;
        bonuses={{id=CC.ebony; min=110; max=120}; {id=SC.eec; min=115; max=125}};
        penalties={{id=SC.redoran; min=90; max=95}}
        };
    };
    
    ["eec_troubleatminetelv"]={
       {index=100;
        bonuses={{id=CC.ebony; min=101; max=105}; {id=SC.telvanni; min=105; max=110}};
        penalties={{id=SC.eec; min=80; max=95}}
        };
       {index=110;
        bonuses={{id=SC.eec; min=105; max=115}; {id=CC.ebony; min=101; max=105}; {id=SC.telvanni; min=101; max=106}}
        };
       {index=120;
        bonuses={{id=CC.ebony; min=110; max=120}; {id=SC.eec; min=115; max=125}};
        penalties={{id=SC.telvanni; min=90; max=95}}
        };
    };
    
    ["eec_troubleatminetemp"]={
       {index=100;
        bonuses={{id=CC.ebony; min=101; max=105}; {id=SC.indoril; min=105; max=110}};
        penalties={{id=SC.eec; min=80; max=95}}
        };
       {index=110;
        bonuses={{id=SC.eec; min=105; max=115}; {id=CC.ebony; min=101; max=105}; {id=SC.indoril; min=101; max=106}}
        };
       {index=120;
        bonuses={{id=CC.ebony; min=110; max=120}; {id=SC.eec; min=115; max=125}};
        penalties={{id=SC.indoril; min=90; max=95}}
        };
    };
 
 
    ---imperial bank
    ["vaib_01_docs"]={{index=100; bonuses={{id=SC.impbank; min=102; max=110}}}};
 
    ["vaib_02_loan1"]={{index=130; bonuses={{id=SC.impbank; min=102; max=108}}}};
 
    ["vaib_02_loan2"]={{index=125; bonuses={{id=SC.impbank; min=102; max=108}}}};
 
    ["vaib_02_loan3"]={{index=120; bonuses={{id=SC.impbank; min=102; max=108}}}};
 
    ["vaib_03_silk"]={{index=100; bonuses={{id=SC.impbank; min=105; max=115}}}};
 
    ["vaib_04_donation"]={{index=100; bonuses={{id=SC.impbank; min=105; max=120}}}};
 
    ["vaib_05_fallengold"]={{index=100; bonuses={{id=SC.impbank; min=102; max=108}; {id=CC.gold; min=102; max=108}}}};
 
    ["vaib_06_docs2"]={{index=100; bonuses={{id=SC.impbank; min=102; max=108}}}};
 
    ["vaib_07_goldcourier"]={{index=100; bonuses={{id=SC.impbank; min=102; max=108}; {id=CC.gold; min=102; max=108}}}};
 
    ["vaib_08_goldmine"]={
       {index=100; bonuses={{id=SC.impbank; min=120; max=145}; {id=SC.eec; min=120; max=135}; {id=CC.gold; min=140; max=155}}};
    };
 
    ["vaib_09_debt"]={{index=100; bonuses={{id=SC.impbank; min=102; max=108}}; penalties={{id=SC.hlaalu; min=85; max=95}}}};
 
    ["vaib_10_goldmine2"]={
       {index=150; bonuses={{id=SC.impbank; min=140; max=160}; {id=SC.eec; min=140; max=170}; {id=CC.gold; min=160; max=195}}};
       {index=190; penalties={{id=SC.impbank; min=10; max=40}; {id=SC.eec; min=65; max=75}; {id=CC.gold; min=65; max=95}}};
    };
    ["vaib_11_closure"]={{index=100; bonuses={{id=SC.impbank; min=180; max=220}}}};
 
    ["vaib_13_ce"]={
       {
          index=110;
          bonuses={{id=SC.impbank; min=105; max=115}; {id=SC.eec; min=105; max=115}};
          penalties={{id=SC.zafirbel; min=15; max=20}};
       };
    };
 
    ["vaib_15_nords"]={
       {index=100; bonuses={{id=SC.impbank; min=140; max=180}; {id=SC.eec; min=190; max=260}; {id=SC.zafirbel; min=1200; max=2200}}};
    };
 
 
 
    ---mages guild shotn
    ["sky_qre_dsmg1_journal"]={{min_index=100; bonuses={{id=SC.mages; min=105; max=115}}}};
 
    ["sky_qre_dsmg2_journal"]={{index=110; bonuses={{id=SC.mages; min=105; max=110}}}};
 
    ["sky_qre_dsmg3_journal"]={{index=100; bonuses={{id=SC.mages; min=105; max=110}}}};
 
    ["sky_qre_dsmg4_journal"]={{index=100; bonuses={{id=SC.mages; min=115; max=125}}}};
 
    ["sky_qre_dsmg5_journal"]={{index=100; bonuses={{id=SC.mages; min=125; max=145}}}};
 
    ["sky_qre_kwmg1_journal"]={{index=50; bonuses={{id=SC.mages; min=105; max=110}}}};
 
    ["sky_qre_kwmg2_journal"]={{index=100; bonuses={{id=SC.mages; min=115; max=120}}}};
 
    ["sky_qre_kwmg3_journal"]={{min_index=105; bonuses={{id=SC.mages; min=115; max=120}}}};
 
    ["sky_qre_kwmg4_journal"]={{min_index=130; bonuses={{id=SC.mages; min=105; max=115}}}};
 
    ["sky_qre_kwmg5_journal"]={{index=140; penalties={{id=SC.mages; min=80; max=95}}}};
 
    ["sky_qre_kwmg6_journal"]={{min_index=220; bonuses={{id=SC.mages; min=125; max=145}}}};
 
 
 
    ---fighters guild shotn
    ["sky_qre_kwfg1_journal"]={{index=100; bonuses={{id=SC.fighters; min=105; max=115}}}};
 
    ["sky_qre_kwfg2_journal"]={{index=100; bonuses={{id=SC.fighters; min=105; max=115}}}};
 
    ["sky_qre_kwfg3_journal"]={{index=100; bonuses={{id=SC.fighters; min=105; max=115}}}};
 
    ["sky_qre_kwfg4_journal"]={{index=110; bonuses={{id=SC.fighters; min=105; max=115}}}};
}

return defns