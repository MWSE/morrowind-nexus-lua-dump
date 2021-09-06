
local config = mwse.loadConfig("enchanted_weapon_resistance", {
	changeFlag = true,
	disableEnchantment = true,
    blacklist = {
		-- ignoresNormalWeaponResistance won't be changed for these
		["ebony_staff_trebonius"] = true,
		["sunder"] = true,
		["warhammer_crusher_unique"] = true,
		["warhammer_crusher_unique_x"] = true,
		["fork_horripilation_unique"] = true,
		["fork_horripilation_unique_x"] = true,
		["widowmaker_unique"] = true
    }
})

local lastTargets = {}
local function enchantChargeUse(e)
	if not config.disableEnchantment then return end

	local lastTarget = lastTargets[e.caster.id]
	if not lastTarget then return end

	if e.isCast and e.source.castType == tes3.enchantmentType.onStrike then
		if lastTarget.resistNormalWeapons >= 100 then
			local currentWeapon = e.caster.mobile.readiedWeapon
			if currentWeapon and currentWeapon.object and currentWeapon.object.ignoresNormalWeaponResistance == false then
				-- Set a high charge so it fails
				e.charge = 50000

				-- Stop the sound and message
				local sMagicInsufficientCharge = tes3.findGMST("sMagicInsufficientCharge").value
				tes3.findGMST("sMagicInsufficientCharge").value = ""
				timer.delayOneFrame(function()
					tes3.removeSound{
						sound = e.source.effects[1].object.spellFailureSoundEffect,
						reference = e.caster
					}
					tes3.findGMST("sMagicInsufficientCharge").value = sMagicInsufficientCharge
				end)
			end
		end
	end
end

local function attack(e)
	if not config.disableEnchantment then return end

	if e.targetMobile
		and ( e.targetMobile.object.objectType == tes3.objectType.creature
		or e.targetMobile.object.objectType == tes3.objectType.npc )
	then
		lastTargets[e.reference.id] = e.targetMobile
	end
end

local function initialized()
    if not mwse.buildDate or mwse.buildDate < 20210830 then
		tes3.messageBox("Enchanted Weapon Resistance requires a newer version of MWSE. Please run MWSE-Update.exe.")
        return
    end

	if config.changeFlag then
		local weaponsByMesh = {}

		for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
			if not (weaponsByMesh[weapon.mesh:lower()] or weapon.enchantment) then
				weaponsByMesh[weapon.mesh:lower()] = weapon
			end
		end
	--	mwse.log("")
	--	mwse.log("")
	--	mwse.log("mesh:	weapon.id,	weapon.sourceMod")
	--	for mesh, weapon in pairs(weaponsByMesh) do
	--		mwse.log(mesh..":	"..weapon.id..",	"..weapon.sourceMod)
	--	end
	--	mwse.log("")
	--	mwse.log("")
		for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
			if not (config.blacklist[weapon.id:lower()] or config.blacklist[weapon.sourceMod:lower()]) then
				local newWeapon = weaponsByMesh[weapon.mesh:lower()]
				if weapon.enchantment and newWeapon and (weapon.ignoresNormalWeaponResistance ~= newWeapon.ignoresNormalWeaponResistance) then
	--				mwse.log("%s: %s -> %s", weapon.id, weapon.ignoresNormalWeaponResistance, newWeapon.ignoresNormalWeaponResistance)
					weapon.ignoresNormalWeaponResistance = newWeapon.ignoresNormalWeaponResistance
				end
			end
		end
	end

	event.register("attack", attack)
	event.register("enchantChargeUse", enchantChargeUse)
	mwse.log("[Enchanted Weapon Resistance] Initialized")
end
event.register("initialized", initialized)

local function registerModConfig()
	local template = mwse.mcm.createTemplate("Enchanted Weapon Resistance")
	template:saveOnClose("enchanted_weapon_resistance", config)

    local page = template:createSideBarPage{
        label = "Settings",
		description = "Enchanted Weapon Resistance by Virnetch"
			.. "\n\n"
			.. " - Automatically changes all enchanted weapons Ignore normal weapon resistance flag to be the same as an unenchanted weapon with the same mesh"
			.. "\n"
			.. " - Blocks cast-on-strike enchantments from triggering when attacking with a weapon that has no effect on the target"
			.. "\n\n"
			.. "Use this page to toggle the options. Use the blacklist to remove changes the 'Change Ignore normal weapon resistance' option makes to specific weapons or all weapons added/changed by a plugin."
    }

	page:createYesNoButton{
		label = "Change Ignore normal weapon resistance",
		description = "Automatically changes all enchanted weapons Ignore normal weapon resistance flag to be the same as an unenchanted weapon with the same mesh.\n\nUse the blacklist to remove changes this option makes to specific weapons or all weapons added/changed by a plugin. Note that for the changes to come to effect, Morrowind has to be restarted.",
		variable = mwse.mcm.createTableVariable{
			id = "changeFlag",
			table = config
		},
		restartRequired = true
	}
	page:createYesNoButton{
		label = "Block enchantment if weapon has no effect",
		description = "Blocks cast-on-strike enchantments from triggering when attacking with a weapon that has no effect on the target.",
		variable = mwse.mcm.createTableVariable{
			id = "disableEnchantment",
			table = config
		}
	}

    template:createExclusionsPage{
        label = "Enchanted Weapon Resistance Blacklist",
        variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config},
        filters = {
			{
				label = "Plugins",
				type = "Plugin",
			},
            {
                label = "Weapons",
                callback = function()
                    local weapons = {}
                    for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
                        if weapon.enchantment then
                            table.insert(weapons, weapon.id:lower())
                        end
                    end
                    table.sort(weapons)
                    return weapons
                end
            }
        }
    }

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)