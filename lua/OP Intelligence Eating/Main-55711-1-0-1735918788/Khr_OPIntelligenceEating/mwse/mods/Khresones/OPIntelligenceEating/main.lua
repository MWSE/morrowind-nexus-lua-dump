-- ??????????????? INTRO ????????????????????????????????????
-- ??????????????? Greetings! I'm Chresones and this is my mwse lua scripted workaround against a small problem when OP (alchemy overboosted etc.) intelligence ruins food (ingredient) bonuses/effects making them too strong / OP as well. This script will attempt to catch sort of IngredientConsumed event & temporarily lower intelligence when the player eats something thus neutralizing the OP buff. ????????????????????????????????????

-- ===========================================   B E G I N  -  V A R S   ============================================================================================================================================
local SID                        = "Swallow"
local IntSwapVal                 = 400
local IntSwapDuration            = 0.15

local function ResetInt()
    --tes3ui.log("Khr_HyperIntelligenceEating - Reset called! Restoring player's Current intelligence back value to ".. tostring(OPInt) .. "...")
    tes3.setStatistic({reference = tes3.mobilePlayer, attribute = 1, current = OPInt})
end

-- ===========================================   P R E P  !  ============================================================================================================================================
local function OnSoundPlay(e)
    ------------------- TRIGGER - 🔉Sound ----------------------------------------------------------------------------------------------------
    ----------- Try getting (Ingredient) Consumed sound & lower intelligance at the right moment! ----------------------------
    if (e.sound.id == SID) then
        -- Spot! ----------
        --tes3ui.log("Khr_HyperIntelligenceEating - '".. SID .. "' (about to be) playing sound trigger - Activated!! Should check conditions...")

        ----- Get initial (Current) player's Intelligence val first & define application necessity --------------
        -- ??????????? Effect (this mod) only useful for over-high / OP / cheating-level values such as 500 or 1000 or 3000/5000 + etc. Apply effect ONLY if those attribute values are reached ???????????????????????????????????
        CurrentInt = tes3.mobilePlayer.intelligence.current
        ---- Over 300 int points = OP! = APPLICABLE! --------------------
        if (CurrentInt > IntSwapVal) then
            -- Rec specifically OP value not to lose it ------------
            OPInt = CurrentInt
            HIA = true
            --tes3ui.log("Khr_HyperIntelligenceEating - ApplicationCondition - '".. CurrentInt .. "' of intelligence is considered OP! Effect APPLICABLE!")
        else
            HIA = false
            --tes3ui.log("Khr_HyperIntelligenceEating - ApplicationCondition - '".. CurrentInt .. "' of intelligence is NOT considered OP! Missing out on effect...")
        end

        ----- LOWER! ------------------
        if (HIA) then
            --tes3ui.log("Khr_HyperIntelligenceEating - Temporarily lowering player's ".. tostring(CurrentInt) .. " Current intelligence value to " .. tostring(IntSwapVal) .. " & restoring original val in " .. tostring(IntSwapDuration) .. " secs..")
            tes3.setStatistic({reference = tes3.mobilePlayer, attribute = 1, current = IntSwapVal})
            ----- Delayed RESET of the val! --------------
            timer.start({duration = IntSwapDuration, callback = ResetInt})
        end
    --else
    --    tes3ui.log("Khr_HyperIntelligenceEating - '".. SID .. "' (about to be) playing sound trigger - missing out on sound: " .. tostring(e.sound.id) .. "...")
    end
end


-- ===========================================   G O !  ============================================================================================================================================
local function OnLoad()
    ------ Vars ------------
    CurrentInt = 0
    OPInt      = 0
    HIA        = false
    ------ Reg! ---------------
    event.register(tes3.event.soundObjectPlay, OnSoundPlay)
end

--local function OnInit()
    --SSoundO = tes3.getObject(SID)
--end

--event.register("initialized", OnInit)
event.register("loaded", OnLoad)