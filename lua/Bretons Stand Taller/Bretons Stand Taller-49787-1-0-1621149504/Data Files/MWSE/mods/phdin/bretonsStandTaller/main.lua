local function initialize()
	local BRETON = 4; -- index of the Breton tes3race in the races array
	tes3.dataHandler.nonDynamicData.races[BRETON].height.male = 1.05
	tes3.dataHandler.nonDynamicData.races[BRETON].weight.male = 1.03
	tes3.dataHandler.nonDynamicData.races[BRETON].height.female = 1.03
	tes3.dataHandler.nonDynamicData.races[BRETON].weight.female = 0.95
    print("[Bretons Stand Taller: INFO] Initialized Bretons Stand Taller")
end

event.register("initialized", initialize)