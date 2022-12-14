local function initialize()
	local BRETON = 4; -- index of the Breton tes3race in the races array
	tes3.dataHandler.nonDynamicData.races[BRETON].height.male = 1.05
	tes3.dataHandler.nonDynamicData.races[BRETON].weight.male = 1.03
	tes3.dataHandler.nonDynamicData.races[BRETON].height.female = 1.03
	tes3.dataHandler.nonDynamicData.races[BRETON].weight.female = 0.95
	local ORC = 10; -- index of the Orc tes3race in the races array
	tes3.dataHandler.nonDynamicData.races[ORC].height.male = 1.12
	tes3.dataHandler.nonDynamicData.races[ORC].weight.male = 1.80
	tes3.dataHandler.nonDynamicData.races[ORC].height.female = 1.12
	tes3.dataHandler.nonDynamicData.races[ORC].weight.female = 1.70
    print("[Races Stand Taller: INFO] Initialized Races Stand Taller")
end

event.register("initialized", initialize)