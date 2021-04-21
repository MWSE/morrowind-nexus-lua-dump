local state
local HuntressNPC
local config = require("Huntress Companion.config")

local function harvest()
	for flora in tes3.getPlayerCell():iterateReferences(tes3.objectType.container) do
		if flora and flora.object.organic and (flora.isEmpty == false) then
			if mwscript.getDistance({reference = flora, target = HuntressNPC}) < 100 then
				if config.harvestDisable == true then tes3.setEnabled({enabled = false, reference = flora}) end
				flora:clone()
				for _, stack in pairs(flora.object.inventory) do
					if stack.object.canCarry ~= false then
						tes3.transferItem{from=flora, to=HuntressNPC, item=stack.object, count=stack.count, playSound=false}
					end
					flora.object.modified = false
					flora.object:onInventoryClose(flora)
					flora.isEmpty = true
				end
			end
		end
	end
end

local function followCheck()
    if tes3.menuMode() then
        return
    end
	if HuntressNPC.mobile == nil then return end
	if HuntressNPC.mobile.inCombat then return end
	if tes3.getCurrentAIPackageId(HuntressNPC.mobile) ~= tes3.aiPackage.follow then return end
    harvest()
end

local function resetState()
	state = 1
end

local function onCombatStart()
	if HuntressNPC.mobile == nil then return end
	if tes3.getCurrentAIPackageId(HuntressNPC.mobile) == tes3.aiPackage.follow then
		if state == 1 then
			tes3.cast{ reference = HuntressNPC, target = tes3.mobilePlayer, spell = "0s_companion_stamina"}
			timer.start({iterations = 1, duration = 120, callback = resetState, type = timer.simulate })
			state = 2
		end
	end
end

local function onCellChanged()
	if config.harvestDisable == false then return end
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.container) do
		if ref and ref.object.organic and ref.disabled then
			tes3.setEnabled({enabled = true, reference = ref})
		end
	end
end

local function onLoaded()
    state = 1
    HuntressNPC = tes3.getReference("0s_huntress_companion")
	event.register("combatStart", onCombatStart)
	event.register("cellChanged", onCellChanged)
	timer.start({iterations = -1, duration = 1, callback = followCheck, type = timer.simulate })
end

local function initialized()
	if tes3.isModActive("Huntress_Companion.esp") then
		event.register("loaded", onLoaded)
	end
end
event.register("initialized", initialized)

local function registerModConfig()
	require("Huntress Companion.mcm")
end
event.register("modConfigReady", registerModConfig)