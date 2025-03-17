local staminaSpellCastCooldown ---@type boolean
local huntressNPCs ---@type tes3reference[]
local config = require("Huntress Companion.config")

local logging = require("logging.logger")
local log = logging.new({ name = "Huntress Comapnion", logLevel = config.logLevel })

---@param huntressNPC tes3reference
local function isFollowing(huntressNPC)
	if not huntressNPC then return false end
	if huntressNPC.mobile == nil then return false end
	if tes3.getCurrentAIPackageId({ reference = huntressNPC }) ~= tes3.aiPackage.follow then return false end
	return true
end

---@param huntressNPC tes3reference
local function harvest(huntressNPC)
	if not isFollowing(huntressNPC) then return end
	if huntressNPC.mobile.inCombat then return end
	log:trace("%s is following player", huntressNPC.id)
	for flora in tes3.getPlayerCell():iterateReferences(tes3.objectType.container) do
		if flora and flora.object.organic and (flora.isEmpty == false) then
			local distance = huntressNPC.position:distance(flora.position)
			log:trace("found flora %s, distance %s", flora.id, distance)
			if distance < 150 then
				if config.harvestDisable == true then tes3.setEnabled({ enabled = false, reference = flora }) end
				flora:clone()
				for _, stack in pairs(flora.object.inventory) do
					if stack.object.canCarry ~= false then tes3.transferItem { from = flora, to = huntressNPC, item = stack.object, count = stack.count, playSound = false } end
					flora.object.modified = false
					flora.object:onInventoryClose(flora)
					flora.isEmpty = true
					log:trace("%s harvested %s", huntressNPC.id, flora.id)
				end
			end
		end
	end
end

local function harvestTimer()
	if tes3.menuMode() then return end
	for _, huntressNPC in ipairs(huntressNPCs) do harvest(huntressNPC) end
	log:trace("harvestTimer running")
end

local function resetState() staminaSpellCastCooldown = false end

local function onCombatStart()
	if not staminaSpellCastCooldown then
		for _, huntressNPC in ipairs(huntressNPCs) do
			if isFollowing(huntressNPC) then
				log:trace("combatStart! %s cast stamina spell on player", huntressNPC.id)
				tes3.cast { reference = huntressNPC, target = tes3.mobilePlayer, spell = "0s_companion_stamina" }
				staminaSpellCastCooldown = true
				break
			end
		end
		if staminaSpellCastCooldown then timer.start({ iterations = 1, duration = 120, callback = resetState, type = timer.simulate }) end
	end
end

local function enablePlants()
	if config.harvestDisable == false then return end
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.container) do if ref and ref.object.organic and ref.disabled then tes3.setEnabled({ enabled = true, reference = ref }) end end
end

local function onLoaded()
	log:debug("loaded")
	tes3.player.data.huntressCompanions = true

	staminaSpellCastCooldown = false

	-- IDs of huntress NPCs - add the IDs of companions you want, be mindful to use the proper "" , and keep the IDs lowercase.
	local huntressIDs = {
		"aa_comp_0s_huntress",
		"aa_sa_gardener",
		"aa_sa_farmer",
		"aa_sa_ashl_scout",
		"aa_comp_pilgawiel",
		"aa_comp_thayla",
		"aa_comp_aria",
		"zennammu",
		"aa_comp_bodil",
		"aa_comp_draythen",
		"aa_comp_khyller",
		"aa_comp_oliver",
		"hides_his_eyes",
		"minabibi assardarainat",
		"aa_comp_varthaal",
		"jac_jasmine", 
		"tr_m4_Uurathor",
		"TR_m3_Fernard_Mannick"
	}
	huntressNPCs = {}
	for _, huntressID in ipairs(huntressIDs) do
		local npc = tes3.getReference(huntressID)
		if npc then
			log:trace("add %s to huntressNPCs table", npc)
			table.insert(huntressNPCs, npc)
		end
	end
	timer.start({ iterations = -1, duration = 1, callback = harvestTimer, type = timer.simulate })
end

local function onInitialized()
	if not tes3.isModActive("Friends and Frens.esp") then return end
	event.register("loaded", onLoaded)
	event.register("combatStart", onCombatStart)
	event.register("cellChanged", enablePlants)
	event.register("UIEXP:sandboxConsole", function(e) e.sandbox.huntressNPCs = huntressNPCs end)
	log:info("initialized!")
end
event.register("initialized", onInitialized)

local function registerModConfig() require("Huntress Companion.mcm") end
event.register("modConfigReady", registerModConfig)
