-- the actual mod file. used because sometimes `main.lua` gets executed
local log = require("herbert100").Logger("Barter XP Overhaul") ---@type herbert.Logger
local config = require("herbert100.barter xp overhaul.config") ---@type BXP.config



local this = {
    waiting_to_give_xp = false, -- keeps track of if we're currently waiting to give the player xp
}

-- =============================================================================
-- DEFINE FUNCTIONS AND FORMULAS
-- =============================================================================
do -- define barter xp calculation functions

    -- this could all be done in way fewer lines of code, but i tried to break it up so that it's easier for mod makers to tweak things/add compatibility options to their mods
    -- the result is that it's probably a bit less readable, but a lot more modular. 
    -- i tried to thoroughly document the code, in order to offset this loss in readability.

    do -- define the mathematical formula for calculating barter xp

        --[[  `B` is going to be the formula that determines how much XP should be awarded to the player when bartering.
            it takes in one parameter, `x`, the total value of goods being bartered, and returns the amount of XP to award the player.
            NOTE: the value returned by `B` will be modified by config settings, and by the haggle bonus.

            you can visualize what's going on by looking at the graph on desmos: https://www.desmos.com/calculator/qdmbdzk5td 

            that also includes an explanation of why things are chosen the way they are. in this `do` block, all variables are exactly as they are on desmos.

            here's a brief description of `B` and why it was chosen this way:
            -- it uses the `arcsinh` function, which starts out convex and eventually becomes concave.
            -- this has the effect of discouraging the player from spamming multiple low value sales for the sake of gaining more xp,
            -- while also not making the XP gained from high value sales be insanely high.
            -- we're taking the absolute value to ensure the XP gain is always positive
        ]]


        -- `asinh` isn't included in `math` (at the time of writing)
        ---@param x number
        local function arcsinh(x) return math.log(x+math.sqrt(x^2+1)) end

        -- magic numbers for barter formula
        local C, C_x, O_x = 6, 0.00166, 3.65

        -- helper barter formula, used to ensure `B(0) == 0`
        local function B_h(x) return C * arcsinh(C_x * x - O_x) end

        --- barter xp formula (for calculating XP to reward using only the `sale_value`)
        ---@param n number the amount of gold the sale is worht
        ---@return number the amount of xp to award a sale with value `n`
        local function B(n) return B_h(math.abs(n)) - B_h(0) end

        -- calculates how much `xp` to award for a sale worth `n` gold.
        this.calc_sale_value_xp = B
    end


    -- calculate how much extra xp should be awarded for haggling.
    function this.calc_haggle_xp(sale_value, offer)
        -- dont bother if there's no offer, or if the sale_value and offer are the same
        if not offer or offer == sale_value then return 0 end

        local diff
        -- we're gaining money
        if sale_value > 0 then
            diff = offer - sale_value -- how much extra money we're gaining
        else -- we're losing money
            diff = (-sale_value) - (-offer) -- how much gold we're saving. the negative signs are there because both `sale_value` and `offer` are negative (and we want them to be positive for our purposes)
        end
        if log.level == 5 then
            log:trace([[calculating haggle bonus with
    sale_value: %s
    offer:      %s
    diff:       %s
    --------------
    config.haggle_coeff: %0.3f]],sale_value, offer, diff,
                config.haggle_coeff)
        end
        -- if we aren't making a profit then return 0
        if diff <= 0 then 
            log:trace("diff was %.3f. since this is <=0, we are returning 0", diff)
            return 0
        end

        local haggle_bonus = (config.haggle_coeff * 1.5 * diff^1.3) / 1000

        log:trace("awarding %0.3f haggle xp", haggle_bonus)
        return haggle_bonus
    end

    --- calculates the total amount of xp to award the player for bartering. (i.e., the sale XP and the haggling bonus), 
    -- and also multiplies this by any relevant config settings.
    -- the actual definitions are broken up to make it "easier" for other people to modify the behavior
    -- (i.e., you can separately redefine how sale and haggling bonuses are calculated)
    ---@param sale_value number the value of the transaction (e.g. what `calcBarterOffer` returns). 
    --- if `< 0`, were losing money, if `> 0`, we're gaining money.
    ---@param offer number? the amount of gold offered
    --- if `< 0`, were paying, if `> 0`, we're getting paid.
    function this.calc_barter_xp(sale_value, offer)
        local sale_xp = this.calc_sale_value_xp(sale_value)                          -- xp based on `sale_value`
        local haggle_xp = this.calc_haggle_xp(sale_value, offer)  -- xp based on haggling
        local total_xp = config.coeff * (sale_xp + haggle_xp)       -- total xp

        do -- make log statement
            log([[calculating barter xp (but not necessarily giving it to the player):
    sale_value: %s
    offer:      %s
    --------------
    sale         xp: %.3f
    haggle bonus xp: %.3f
    total        xp: %.3f
        ]], function ()
                local offer_str = offer or string.format("nil (so using %i)", sale_value)
                
                return sale_value, offer_str,
                sale_xp, haggle_xp, total_xp
            end)
        end

        return total_xp
    end


    --- awards the player XP after bartering. 
    -- basically just calls `calc_barter_xp`, makes sure that number is `> 0`, and then gives it to the player
    ---@param sale_value number the total value of gold exchanged during the transaction.
    ---@param offer number? the amount of gold offered. Defaults to `sale_value` if not provided
    function this.award_barter_xp(sale_value,offer)
        local xp = this.calc_barter_xp(sale_value,offer)
        if xp > 0 then
            this.waiting_to_give_xp = true
            log("xp was >0, we'll award %.3f xp once menus are closed.", xp)
            -- we're starting a `simulate` timer to ensure that 
            -- 1) xp is given after the player leaves the menu
            -- 2) the vanilla XP event is blocked (the vanilla event will trigger while `waiting_to_give_xp` is true)
            -- (this is because `simulate` timers only run when menus aren't open)
            timer.start{duration=0.01, callback=function (e)
                log("barter timer finished, going to give the player %.3f xp", xp)
                this.waiting_to_give_xp = false
                tes3.mobilePlayer:exerciseSkill(tes3.skill.mercantile, xp)
            end}
        end
    end
end


-- =============================================================================
-- DEFINE EVENTS
-- =============================================================================
-- these functions are only registered to the appropriate events if the relevant config settings are enabled,
-- which is why we arent checking that here


-- this will award xp after successfully bartering
---@param e barterOfferEventData
function this.barter_offer(e)
    log:trace([[barter event triggered with 
    success: %s
    offer:   %s
    value:   %s]], e.success, e.offer, e.value)
    if e.success then
        this.award_barter_xp(e.value, e.offer)
        e.claim = config.barter_offer_claim
     end
end
local mercentile_id = tes3.skill.mercantile

-- block the event if mercentile xp is being awarded and this mod is about to reward xp
---@param e exerciseSkillEventData
function this.block_vanilla_xp(e) 
    if e.skill ~= mercentile_id then return end 
    log("in exercseSkill event: something wants to give the player barter xp")
    if tes3ui.findMenu("MenuBarter") and this.waiting_to_give_xp then
        log("blocking barter xp because the barter menu is open and we're waiting to give xp")
        return false
    end
end




return this