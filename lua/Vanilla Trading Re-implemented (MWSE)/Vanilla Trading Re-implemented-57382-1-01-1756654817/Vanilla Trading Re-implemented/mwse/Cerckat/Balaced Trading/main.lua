--Mod by cerckat because there is no simple mod that do this--

local function cerckat_BalancedVendors(e)
local Merc, Per, Luck, Disp, Vmerc, Vper, Vluck = tes3.mobilePlayer.mercantile.current, tes3.mobilePlayer.personality.current, tes3.mobilePlayer.luck.current, e.mobile.object.disposition, e.mobile.mercantile.current, e.mobile.personality.current, e.mobile.luck.current
local NewSkillMod = Merc * 0.01 + Per * 0.005 + Luck * 0.0005 + ( math.clamp(Disp, 0, 100) * 0.0005 ) - Vmerc * 0.01 - Vper * 0.005 - Vluck * 0.0005
-- the new skill modificator is mercantile skill, half the personality, 5% of luck of you against the rival merchant plus 5% of his dispotition to your favor--
	if e.buying == false then
	-- this mean when you are selling thing, singular makes the calculation for each thing
	--In practice it applies to everything together
		local NewSellPrice =  e.basePrice * ( 0.35 + NewSkillMod ) 
		-- the base value of the thing your are selling is mult for the new skill mod 
		local LowSell = e.basePrice * 0.25
		-- inicial offer is hard shoe to 25% of the base value so low mercantile character dont suffer
		local HighSell = e.basePrice * 0.75
		-- inicial offer is hard cap to 75% of the base value to help merchants not to buy at a loss
		-- This may sound like little but remember that haggling is a thing
		e.price = math.clamp(NewSellPrice, LowSell, HighSell) 
		-- final inicial offer
	end
	if e.buying == true then
	-- and this is when you buying thing 
		local NewBuyPrice =  e.basePrice * ( 2.25 - ( NewSkillMod ) )
		-- inicial offer from the merchant is base price mult 2.25 minus the new skill mod
		local LowBuy = e.basePrice * 1.85
		-- shoeed to 185% of the base value as inicial offer 
		local HighBuy = e.basePrice * 3
		-- capped to 3 times the base value so low mercantile characters can buy things
		e.price = math.clamp(NewBuyPrice, LowBuy, HighBuy) + e.count
		-- final inicial offer plus one for each thing on the stack so everything is valued in at laest 3 gold
	end
end
event.register("calcBarterPrice", cerckat_BalancedVendors)

local function initialize()
end
event.register("initialized", initialize)