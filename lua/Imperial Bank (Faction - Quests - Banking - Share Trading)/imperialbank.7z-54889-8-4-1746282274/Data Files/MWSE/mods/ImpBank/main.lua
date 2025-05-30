
---Imperial Bank SSQN Icon

local ssqn = include("SSQN.interop")

local function init() 
    if (ssqn) then
        -- Imperial Bank
		ssqn.registerQIcon("vaib_01_docs","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_02_loan1","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_02_loan2","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_02_loan3","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_03_silk","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_04_donation","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_05_fallengold","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_06_docs2","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_07_goldcourier","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_08_goldmine","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_09_debt","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_10_goldmine2","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_11_closure","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_12_docs3","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_13_ce","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_13_cefirewatch","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_13_cehelnim","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_14_zafirbel","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_15_nords","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_15_nords1","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_15_nords2","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_15_nords3","\\Icons\\va\\vaib_ssqn_icon.dds")
		
		ssqn.registerQIcon("vaib_ns_letter","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_ns01_docs","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_ns02_advert","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_ns03_gallery","\\Icons\\va\\vaib_ssqn_icon.dds")
		
		ssqn.registerQIcon("vaib_an01_doc","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_an02_loan","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_an03_loan","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_an04_loan","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_an05_debt","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_an06_machine","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_an06_machine_com","\\Icons\\va\\vaib_ssqn_icon.dds")
		ssqn.registerQIcon("vaib_an06_machine_mat","\\Icons\\va\\vaib_ssqn_icon.dds")
		
		ssqn.registerQIcon("vaib_ch01_salesman","\\Icons\\va\\vaib_ssqn_icon.dds")
    end
end

event.register(tes3.event.initialized, init)

---Imperial Bank Share Trading

local defns = require("impbank.defns")
local SPECIAL_ITEM_IDS = defns.SPECIAL_ITEM_IDS

-- Stores the current player data. Used to ensure we update prices exaclty one time each day.
---@type vaelta.IB.player_data
local player_data 

-- =============================================================================
-- FUNCTIONS THAT COMPUTE AND UPDATE STOCK PRICES
-- =============================================================================


---Overall Change Amount Formulae
---@param lower_bound number
---@param upper_bound number
---@return number
local function get_bonus_multiplier(lower_bound, upper_bound)
    local mp = tes3.mobilePlayer
    return 0.01 * (
        math.random(lower_bound, upper_bound) 
        + 0.18 * mp.luck.current
        + 0.23 * mp.mercantile.base
    )
end


---@param data vaelta.IB.bonus_data
local function apply_stock_value_bonus(data)
    local bonus_multiplier = get_bonus_multiplier(data.min, data.max)

    local item = tes3.getObject(data.id)
    item.value = item.value * bonus_multiplier
    item.modified = true
end



--- Calculates a penalty multiplier that's used to reduce the price of a share.
---@param lower_bound number between 1 and 100
---@param upper_bound number between 1 and 100
---@return number penalty_mult between 0 and 1.
local function get_penalty_multiplier(lower_bound, upper_bound)
    return math.random(upper_bound, lower_bound) / 100
end

-- -----------------------------------------------------------------------------
-- DAILY CHANGES
-- -----------------------------------------------------------------------------


---@param data vaelta.IB.penalty_data
local function apply_stock_value_penalty(data)
    local bonus_multiplier = get_penalty_multiplier(data.min, data.max)

    local item = tes3.getObject(data.id)
    item.value = item.value * bonus_multiplier
    item.modified = true
end

---@param blackswan_chance number
---@param lower_bound number
---@param upper_bound number
---@return number
local function get_daily_multiplier(blackswan_chance, lower_bound, upper_bound)
    local mp = tes3.mobilePlayer
    if math.random(1, blackswan_chance) == 1 then 
        local blackswan_amount = math.random(30, 95)
        upper_bound = (upper_bound + blackswan_amount)
        lower_bound = (lower_bound - blackswan_amount)
    end
    
    if mp.luck.current < 15 then
        upper_bound = (upper_bound * .8)
        lower_bound = (lower_bound * 1.20)
    
    elseif mp.luck.current < 25 then
        upper_bound = (upper_bound * .85)
        lower_bound = (lower_bound * 1.15)
    
    elseif mp.luck.current < 35 then
        upper_bound = (upper_bound * .9)
        lower_bound = (lower_bound * 1.1)
    
    elseif mp.luck.current < 45 then
        upper_bound = (upper_bound * 1.05)
        lower_bound = (lower_bound * .95)
    
    elseif mp.luck.current < 55 then
        upper_bound = (upper_bound * 1.1)
        lower_bound = (lower_bound * .9)
    
    elseif mp.luck.current < 70 then
        upper_bound = (upper_bound * 1.15)
        lower_bound = (lower_bound * .85)
    
    else
        upper_bound = (upper_bound * 1.2)
        lower_bound = (lower_bound * .8)
    end
    
    if lower_bound < -85 then lower_bound = -85
    end
    
    upper_bound = upper_bound + (mp.mercantile.base * 0.225)
    
    return 0.01 * (
        math.random(lower_bound, upper_bound)
    )
end

---@param data vaelta.IB.daily_change_data
local function apply_daily_change(data)
    local item = tes3.getObject(data.id)
    local old_value = item.value

    local bonus = old_value * get_daily_multiplier(data.swan_chance, data.min, data.max)

    item.value = math.floor(old_value + bonus)
    item.modified = true
end

---Try to apply the random fluctuations to the certificate prices.
-- This function will be called every couple seconds, but will only actually update the prices once per day.
local function try_to_update_daily_prices()
    if not player_data or not tes3.player then return end


    local day = tes3.worldController.daysPassed.value     -- current day

    -- already updated? bail
    if player_data.day >= day then return end

    -- Record that we already tried to update things today.
    player_data.day = day

    -- dont have the quest? bail
    if tes3.getJournalIndex{id = "vaib_member"} < 20 then return end

    -- update the prices
    for _, data in ipairs(defns.daily_changes) do
        apply_daily_change(data)
    end
end


-- =============================================================================
-- EVENT CALLBACKS
-- =============================================================================

---@param e calcBarterPriceEventData
local function calc_barter_price(e)
    -- not a certificate? bail
    if not SPECIAL_ITEM_IDS[e.item.id:lower()] then return end

    e.price = e.item.value * e.count
    return false
end


local function loaded()
    local data = tes3.player.data
    if not data.vaelta_imp_bank then    
        data.vaelta_imp_bank = table.copy(defns.DEFAULT_PLAYER_DATA)
    end
    player_data = data.vaelta_imp_bank
    -- start daily change timer
    timer.start{duration = 5, iterations = -1, callback = try_to_update_daily_prices}
end

-- Update prices whenever certain quests are progressed.
---@param e journalEventData
local function journal(e)
    -- no data? bail
    local journal_data = defns.quest_progress_bonuses[e.topic.id:lower()]
    if not journal_data then return end

    local index = e.index

    -- iterate through the price changes for each index
    -- then check to see if we're at the appropriate journal index
    -- if so, apply the updates.
    for _, index_data in ipairs(journal_data) do 
        if index_data.index and index_data.index == index 
        or index_data.min_index and index_data.min_index <= index 
        then
            -- apply bonuses
            for _, bonus_data in ipairs(index_data.bonuses or {}) do
                apply_stock_value_bonus(bonus_data)
            end
            -- apply penalties
            for _, penalty_data in ipairs(index_data.penalties or {}) do
                apply_stock_value_penalty(penalty_data)
            end
        end
    end
end

-- register all events when the game is initialized
local function initialized()
    event.register("journal", journal)
    event.register(tes3.event.loaded, loaded)
    -- huge priority so that we can have total control over our special items
    event.register("calcBarterPrice", calc_barter_price, {priority = math.huge})
end

event.register("initialized", initialized, {doOnce = true})