
local log = require("herbert100.proportional magicka regeneration.log")
-- this will set the log level. not ideal, but whatever
local mcm = require("herbert100.proportional magicka regeneration.mcm")


local log_level = mcm.config.log_level
local config, player_config, npc_config = mcm.config, mcm.config.player_regen, mcm.config.npc_regen
local current_formula_name

-- save the multiplier applied during combat, in case the mcm.config gets changed during combat

--timers are stored because they need to be remade if the poll rate changes
local player_timer          ---@type mwseTimer
local npc_timer             ---@type mwseTimer

-- store the actual computation variables for player regeneration, so we don't have to 
-- rederive them several times per second
local player_coeff     ---@type number
local npc_coeff        ---@type number

-- references for the player and NPCs
-- local player                ---@type tes3mobilePlayer

-- the time before the last travel, or nil if no travel has happened
local time_before_travel    ---@type number?






-- this will be the regen formula.
local regen_formula

-- create the function 
local function update_spline()
    -- this is the actual formula, but it's only used to make a spline because it's computationally expensive.
    local formulas = require("herbert100.proportional magicka regeneration.regeneration_formulas")
    local actual_regen_formula = formulas[config.formula_name]

    if not actual_regen_formula then 
        local default_formula_name = require("herbert100.proportional magicka regeneration.mcm.default_config").formula_name
        actual_regen_formula = formulas[default_formula_name]
        log:debug("had to load the default formula. that was weird.")
    end

    local splines = include("herbert100.math.Polynomial_Spline")

    if splines ~= nil then
        log:debug("herbert lib is installed :). making a spline!")
        local Evenly_Spaced_Spline = splines.Evenly_Spaced_Spline

        regen_formula = Evenly_Spaced_Spline.new{f=actual_regen_formula, lower_bound=5, upper_bound=400, dist=15}
        if log_level > 1 then
            log:debug(string.format("made spline for formula: %s. the spline is: %s", config.formula_name,tostring(regen_formula)))
            if log_level == 3 then
                log:trace("testing spline values.")
                for willpower = 30, 250,5 do
                    -- formula_values[willpower] = actual_regen_formula(willpower)
                    log:trace(string.format("%i:\n\tfunction=%f\n\tspline=%f", willpower, actual_regen_formula(willpower),regen_formula(willpower)))
                end
            end
        end
    else
        log:debug("herbert lib is not installed :(. not going to use a spline.")
        

        regen_formula = actual_regen_formula
    end

   
end

mcm.update_formula = update_spline

--[[on each call, the player receives a little of bit of magicka regeneration.
    this function is called `mcm.config.player_poll_rate` times per second, so it better be optimized!]]
local function player_regen_tick()
    local player = tes3.mobilePlayer
    -- store base magicka (ie maximum magicka) and current magicka
    local mb, mc = player.magicka.base, player.magicka.current

    
    -- only do stuff if there's magicka to be regenerated
    if mc >= mb then return end
        
    local w = player.willpower.current

    local reg = player_coeff * mb * regen_formula(w)
    if player.inCombat then
        reg = reg * config.combat_mult
     end
    -- only generate the debug strings if they're going to be shown
    if log_level > 1 then 
        local combat_mult
        if player.inCombat then 
            combat_mult = config.combat_mult
        else
            combat_mult = "N/A"
        end
        log:debug("doing a player regen tick \n\t\z
            willpower:          %i\n\t\z
            current magicka:    %i\n\t\z
            max magicka:        %i\n\t\z
            regenerated:        %f\n\t\z
            ----------------------------\n\t\z
            1%% of max magicka: %f\n\t\z
            player_coeff:       %f\n\t\z
            combat_mult:        %s\n\t\z
            poll_rate:          %f\n\t\z
            reg/sec:            %f",
            w, mc, mb, reg,
            mb/100, player_coeff, combat_mult, player_config.poll_rate, (reg / player_config.poll_rate)
        )
    end
    -- tes3.setStatistic { reference = player, name = "magicka", current = math.clamp(mc + reg, 0, mb) }
    tes3.modStatistic{reference = player, name = "magicka", current = reg, limitToBase=true}

end

local function npc_regen_tick()
    local reg, npc
    for npc_ref in tes3.getPlayerCell():iterateReferences{tes3.objectType.npc} do
        npc = npc_ref.mobile
        if npc  then
            -- if npc.birthsign and npc.birthsign.name == "Wombburned" then return end

            local mb, mc = npc.magicka.base, npc.magicka.current

            if mc < mb then
                local w = npc.willpower.current
             
                reg = npc_coeff * mb * regen_formula(w)

                if npc.inCombat then 
                    reg = reg * config.combat_mult
                 end

                -- atronach penalty is factored into `player_coeff`, but not `npc_coeff`
                if  npc_ref.object.spells:contains("wombburn") then 
                    if log_level > 1 then
                        log:debug("NPC regen tick: %s is an atronach. applying the multiplier: %f", npc.object.name, config.atronach_mult)
                    end
                    reg = reg * config.atronach_mult
                end

                if log_level == 3 then 
                    log:trace("doing an npc regen tick \n\t\z
                        willpower:          %i\n\t\z
                        current magicka:    %i\n\t\z
                        max magicka:        %i\n\t\z
                        regenerated:        %f\n\t\z
                        ----------------------------\n\t\z
                        1%% of max magicka:  %f\n\t\z
                        coeff:              %f\n\t\z
                        poll_rate:          %f\n\t\z
                        reg/sec:            %f",
                        w, mc, mb, reg,
                        mb/100, npc_coeff, npc_config.poll_rate/10, (reg / npc_config.poll_rate)
                    )
                end


                -- new magicka value is mc + reg, and make sure its between 0 and the players base magicka
                -- tes3.setStatistic { reference = npc, name = "magicka", current = math.clamp(mc + reg, 0, mb) }
                tes3.modStatistic{reference=npc, name="magicka", current=reg, limitToBase=true}
                
            end
        end
    end
end

-- this function assumes regeneration is supposed to happen
local function restore_a_bunch(mobile, seconds_passed)
    local mb, mc = mobile.magicka.base, mobile.magicka.current
    if mc >= mb then return end

    local rate_per_second
    -- get the rate for the corresponding type of actor 
    
    if mobile == tes3.mobilePlayer then
        -- we're dividing by the `poll_rate` because `player_coeff` was multiplied by the `poll_rate`, and we just want the 
        -- actual rate per second.
        rate_per_second = player_coeff / player_config.poll_rate
    else
        rate_per_second = npc_coeff / npc_config.poll_rate
        -- Wombburned is already factored into `player_coeff`
        if mobile.object.spells:contains("wombburn") then 
            if config.atronach_mult == 0 then return end

            rate_per_second = rate_per_second * config.atronach_mult
        end

    end

    local w =  mobile.willpower.current
    local reg = regen_formula(w)
                * mb
                * rate_per_second
                * seconds_passed


    -- tes3.setStatistic {reference = mobile, name = "magicka", current = math.clamp(reg, 0, mb)}
    tes3.modStatistic{reference = mobile, name = "magicka", current = reg, limitToBase=true}
end

-- Regenerate magicka for Player during traveling, no regen for NPCs and Creatures this time
-- because the Player has entered a new cell -> NPCs from last destination were unloaded.
-- Player's companions do get regeneration if the player has any.
local function travel_magicka_regen(e)
    if (not tes3.mobilePlayer.traveling) then -- Get time before traveling
        time_before_travel = tes3.getSimulationTimestamp()
    end
    if tes3.mobilePlayer.traveling then -- Travel finished
        local seconds_passed = (tes3.getSimulationTimestamp() - time_before_travel) * 3600
        time_before_travel = nil

        -- if atronachs can travel, or if the player is not an atronach, then they can restore travel magicka
        if player_config.enable and (mcm.config.atronachs_can_travel or  not tes3.player.object.spells:contains("wombburn")) then
            restore_a_bunch(tes3.mobilePlayer, seconds_passed)

        end
        if npc_config.enable and e.companions then 
            for companion in e.companions do
                if mcm.config.atronachs_can_travel or not companion.object.spells:contains("wombburn") then
                    restore_a_bunch(companion.mobile, seconds_passed)
                end
            end
        end
    end
end

local function wait_magicka(e)
    local penalty = 0
    if e.count > 0 and e.hour > 1 then
        -- The sleep was interrupted
        penalty = (e.hour - 1)
    end
    local seconds_passed = (tes3.mobilePlayer.restHoursRemaining - penalty) * 3600

    -- restore player magicka
    if player_config.enable and (mcm.config.atronachs_can_sleep or  not  tes3.player.object.spells:contains("wombburn")) then
        restore_a_bunch(tes3.mobilePlayer, seconds_passed)
    end

    -- restore npc_magicka 	
    if npc_config.enable  then
        for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.actor) do
            if (mcm.config.atronachs_can_sleep or not  ref.object.spells:contains("wombburn")) then
                restore_a_bunch(ref.mobile, seconds_passed)
            end
        end
    end
end

--- update the magicka regeneration and player regeneration timers
local function update_timers()
    log:debug("updating timers.")
    -- cancel the timers if they were active
    if player_timer and player_timer.state == timer.active then 
        log:debug("player timer was active, disabling it.")
        player_timer:cancel()
    end
    if npc_timer and npc_timer.state == timer.active then
        log:debug("npc timer was active, disabling it.")
        npc_timer:cancel()
    end

    -- start the timers if the corresponding settings are enabled
    if player_config.enable then

        -- don't start the timer if the player is an atronach and `atronach_mult == 0`
        if config.atronach_mult == 0 and tes3.mobilePlayer and tes3.player.object.spells:contains("wombburn") then 
            log:debug("not starting player timer because the player is an Atronach and magicka regeneration is disabled for Atronachs.")
            goto npc_check
        end
        log:debug("starting player timer.")
        player_timer = timer.start {
            iterations = -1,
            duration = player_config.poll_rate,
            callback = player_regen_tick
        }
    end
    ::npc_check::
    if npc_config.enable then
        log:debug("starting NPC timer.")
        timer.start {
            iterations = -1,
            duration = npc_config.poll_rate,
            callback = npc_regen_tick
        }
    end
end

-- update the variables used in computations
local function update_variables()
    if current_formula_name ~= mcm.config.formula_name then 
        update_spline()
        current_formula_name = mcm.config.formula_name
    end

    local player = tes3.mobilePlayer

    
    --[[at 100% magicka regen, 100 willpower should result in 1% of magicka being regenerated per second]]
    -- actual formula is described in player_magicka_regen,

    -- stores how much we regenerate each tick
    -- we're dividing by 100 at the end because we're going to be multiplying by base magicka
    -- and we're really interested in getting 1% of base magicka
    player_coeff = (player_config.coeff  * player_config.poll_rate ) / 100

    npc_coeff =  (npc_config.coeff * npc_config.poll_rate) / 100

    if player then 
        if tes3.player.object.spells:contains("wombburn") then
            log:debug("player is an atronach, adjusting regen rate.")
            player_coeff = player_coeff * config.atronach_mult
        end
    end
    if log_level > 1 then 
        log:debug("updated variables:\n\t\z
            player_coeff: %f\n\t\z
            npc_coeff: %f",
            player_coeff, npc_coeff
        )
    end


end

-- called whenever the MCM is closed 
function mcm.update()
    log_level = mcm.config.log_level
    update_variables()

    -- if we're ingame, update the timers
    if tes3.mobilePlayer ~= nil then update_timers() end
 end


-- whenever a save is loaded, 
local function save_loaded()
    -- make sure the combat_mult is nil. i'm not putting this in the update_variables function because this should only happen when a save is loaded

    -- we're doing this when the save is loaded so that we can factor in the atronach mult
    update_variables()

    -- wait a second to make sure everything (actors, player, etc) are loaded, then start the timers
    timer.start{duration=1,callback=update_timers}
end

--[[ happens when the game loads (ie titlescreen shows up)
    what will happen: 
        1) register a function that does stuff whenever a save is loaded 
            *) the stuff that will happen: 
                a) update the constants that will be used in calculations (so we don't have to calculate them several times a second, since they pretty much never change anyway)
                b) start regeneration timers for the player and NPCs (if the corresponding features are enabled in the MCM)
        2) register an event that restores magicka whenver the player waits (if player regen is enabled)
        3) register an event that restores magicka whenever the player travels (if player regen is enabled)
]]
local function initialized()

    update_spline()
    event.register(tes3.event.loaded, save_loaded)
    event.register(tes3.event.calcRestInterrupt, wait_magicka)
    event.register(tes3.event.calcTravelPrice, travel_magicka_regen)

    log:info("Initialized.")

end

event.register(tes3.event.initialized, initialized)

event.register(tes3.event.modConfigReady, mcm.register)