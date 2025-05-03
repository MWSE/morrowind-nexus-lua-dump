local function initialize()
	local ORC = 10; -- index of the Orc tes3race in the races array
	tes3.dataHandler.nonDynamicData.races[ORC].height.male = 1.10
	tes3.dataHandler.nonDynamicData.races[ORC].weight.male = 1.60
	tes3.dataHandler.nonDynamicData.races[ORC].height.female = 1.10
	tes3.dataHandler.nonDynamicData.races[ORC].weight.female = 1.40
    print("[Orcs Stand Taller: INFO] Initialized Orcs Stand Taller")
end

event.register("initialized", initialize)