--[[
	Mod: Fabricant Guar Companion
	Author: Melchior Dahrk
--]]

local mdFG_global_MuskAtomizer
local mdFG_global_following
local mdFG_global_Sample_Guar
local mdFG_global_imperfect
local mdFG_global_dead


-- Guar Detection

local guarReferences = {}

local function isGuar(object)
	local id = object.id:lower()
	return id:find("guar") and not id:find("guar%a")
end

local function onRefCreated(e)
	if isGuar(e.reference.object) then
		guarReferences[e.reference] = true
	end
end

local function onRefDeleted(e)
	guarReferences[e.reference] = nil
end

local function getNearbyGuars()
	local pos = tes3.player.position
	for ref in pairs(guarReferences) do
		if ref.position:distance(pos) < 1024 then
			coroutine.yield(ref)
		end
	end
end


-- Musk Atomizer

local atomizerTimer

local function followPlayer(ref)
	local aiData = ref.mobile.aiData
	if not aiData then return end

	local aiPackage = aiData:getActivePackage()
	if not aiPackage then return end

	if aiPackage.type ~= 3 then
		tes3.setAIFollow{reference=ref, target=tes3.player}
	end
end

local function collectMuskSample(e)
	local object = e.target.object
	if (mwscript.hasItemEquipped{reference=tes3.player, item="mdFG_w_collector"}
		and object.objectType == tes3.objectType.creature
		and mdFG_global_Sample_Guar.value == 0
		and e.activator == tes3.player
		and isGuar(object)
		)
	then
		mdFG_global_Sample_Guar.value = 1
		tes3.messageBox("[Guar musk sample collected.]")
	end
end

local function muskAtomizerTick()
	if (mdFG_global_following.value == 1) and (mdFG_global_MuskAtomizer.value == 1) then
		for ref in coroutine.wrap(getNearbyGuars) do
			followPlayer(ref)
		end
	end
end

local function muskAtomizerStart()
	if atomizerTimer then
		atomizerTimer:cancel()
	end
	if (mdFG_global_following.value == 1) and (mdFG_global_MuskAtomizer.value == 1) then
		atomizerTimer = timer.start{duration=1, iterations=-1, type=timer.simulate, callback=muskAtomizerTick}
	end
end


-- Imperfect Aggro

local function getClosestCombatTarget(ref, distance)
	local closestRef
	for i, cell in pairs(tes3.getActiveCells()) do
		for otherRef in cell:iterateReferences() do
			if (otherRef.object.objectType == tes3.objectType.creature
				or otherRef.object.objectType == tes3.objectType.npc)
			then
				local dist = ref.position:distance(otherRef.position)
				if (dist < distance
				    and ref.object ~= otherRef.object
				    and otherRef.disabled == false
				    and otherRef.deleted == false
				    and otherRef.mobile ~= nil
				    and otherRef.mobile.health.current > 0)
				then
					closestRef = otherRef
					distance = dist
				end
			end
		end
	end
	return closestRef, distance
end

local function mdFG_script_imperfectFight()
	mwscript.stopScript{script="mdFG_script_imperfectFight"}

	local imperfect = tes3.getReference("mdFG_Imperfect")
	-- mwse.log("imperfect.mobile.inCombat == %s", imperfect.mobile.inCombat)
	if imperfect.mobile.inCombat == true then
		return
	end

	local closestRef, distance = getClosestCombatTarget(imperfect, 1000)
	-- mwse.log("closestRef == %s, distance == %s", closestRef, distance)
	if closestRef then
		mwscript.startCombat{reference=imperfect, target=closestRef}
	end
end


-- Gizmo Guards

local function mdFG_script_AIGuard()

	local gizmo = tes3.getReference("mdFG_gizmo")
	local player = tes3.getReference("player")
	local dist = gizmo.position:distance(player.position)
	-- mwse.log("gizmo.mobile.inCombat == %s", gizmo.mobile.inCombat)
	if (player.mobile.inCombat == true
		and dist < 3000)
	then
		followPlayer(gizmo)
		mdFG_global_following.value = 1
		mwscript.stopScript{script="mdFG_script_AIGuard"}
	end
end


-- Override Scripts

local function mdFG_script_RepairModule()
	tes3.showRepairServiceMenu()
	mwscript.stopScript{script="mdFG_script_RepairModule"}
end

local function mdFG_script_AIFollow()
	muskAtomizerStart()
	mwscript.stopScript{script="mdFG_script_AIFollow"}
end

local function mdFG_script_SummonGizmo(e)
    local pos = e.reference.position:copy()
    local ori = e.reference.orientation:copy()
    local cell = e.reference.cell
    timer.delayOneFrame(function()
        local ref = tes3.getReference("mdFG_gizmo")
        tes3.positionCell{reference=ref, position=pos, orientation=ori, cell=cell}
        mwscript.disable{reference=ref}
        mwscript.enable{reference=ref}
    end)
    mwscript.stopScript{script="mdFG_script_SummonGizmo"}
end

-- Mod Initialization

event.register("initialized", function()
	if tes3.isModActive("Fabricant Guar.ESP") then
		-- register events
		event.register("loaded", muskAtomizerStart)
		event.register("activate", collectMuskSample)
		event.register("mobileActivated", onRefCreated)
		event.register("mobileDeactivated", onRefDeleted)
		-- override scripts
		mwse.overrideScript("mdFG_script_RepairModule", mdFG_script_RepairModule)
		mwse.overrideScript("mdFG_script_AIFollow", mdFG_script_AIFollow)
		mwse.overrideScript("mdFG_script_imperfectFight", mdFG_script_imperfectFight)
		mwse.overrideScript("mdFG_script_AIGuard", mdFG_script_AIGuard)
		mwse.overrideScript("mdFG_script_SummonGizmo", mdFG_script_SummonGizmo)
		-- cache globals
		mdFG_global_MuskAtomizer = tes3.findGlobal("mdFG_global_MuskAtomizer")
		mdFG_global_Sample_Guar = tes3.findGlobal("mdFG_global_Sample_Guar")
		mdFG_global_following = tes3.findGlobal("mdFG_global_following")
		mdFG_global_imperfect = tes3.findGlobal("mdFG_global_imperfect")
		mdFG_global_dead = tes3.findGlobal("mdFG_global_dead")
	end
end)
