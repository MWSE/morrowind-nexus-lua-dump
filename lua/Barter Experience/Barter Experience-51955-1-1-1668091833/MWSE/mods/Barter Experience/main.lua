--Mod by Muggins because nothing like this exists yet afaik--

local function onBarterOffer(e)
    -- Give some flat experience for each attempted trade.
    tes3.mobilePlayer:exerciseSkill(24, 1)
	-- Store the value of the traded goods and prevent exploitable haggling, thanks Buying Game!
	if e.offer > e.value then
		local trueValue = common.getArrayValue(e.selling, "sell") - common.getArrayValue(e.buying, "buy")
		if e.offer > trueValue then
			e.success = false
		end
	end
end

local function onBarterSuccess(e)
    -- First make sure it's not a negative value, then gain a fraction of it as experience.
    if trueValue < 0 then tes3.mobilePlayer:exerciseSkill(24, trueValue * -1 * 0.002) else
    tes3.mobilePlayer:exerciseSkill(24, trueValue * 0.002)
    end
end

local function onInitialized(e)
    mwse.log("[Barter Experience]: enabled")
    event.register("barterOffer", onBarterOffer)
    event.register("barterOffer", onBarterSuccess, {priority = -99999})
end

event.register("initialized", onInitialized )