
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
		["lightofday_unique"] = true
    }
})


local lastAmmo = {}
local function calcHitChance(e)
	if not config.disableEnchantment then return end

	-- First, use the last ammo the actor used on last attack event.
	local weapon = lastAmmo[e.attacker.id]
	lastAmmo[e.attacker.id] = nil
	if not weapon then
		local attackerMobile = e.attacker.mobile

		-- If no ammo is saved, use the weapon the actor has currently readied.
		weapon = attackerMobile.readiedWeapon and attackerMobile.readiedWeapon.object
		if not weapon then return end
		if weapon.isRanged then
			-- If the weapon is ranged, use currently equipped ammo.
			-- Thrown weapons count as both readiedAmmo, and readiedWeapon,
			-- even if the actor has both thrown weapons and ammo equipped.
			weapon = attackerMobile.readiedAmmo and attackerMobile.readiedAmmo.object
		end
		if not weapon then return end
	end

	if weapon.enchantment and weapon.enchantment.castType == tes3.enchantmentType.onStrike then
		if e.targetMobile.resistNormalWeapons >= 100 then
			if weapon.ignoresNormalWeaponResistance == false then
				e.hitChance = 0
				if weapon.isProjectile and e.attacker == tes3.player then
					tes3.messageBox(tes3.findGMST(tes3.gmst.sMagicTargetResistsWeapons).value)
				end
				-- Block other mods from changing the hitChance.
				return false
			end
		end
	end
end

local function attack(e)
	if not config.disableEnchantment then return end

	if e.targetMobile
	  and e.mobile.readiedWeapon
	  and ( e.targetMobile.object.objectType == tes3.objectType.creature
	  or e.targetMobile.object.objectType == tes3.objectType.npc )
	  and e.mobile.readiedWeapon.object.isRanged then
		lastAmmo[e.reference.id] = e.mobile.readiedAmmo.object
	else
		lastAmmo[e.reference.id] = nil
	end
end

local function initialized()
    if not mwse.buildDate or mwse.buildDate < 20210830 then
		tes3.messageBox("Enchanted Weapon Resistance requires a newer version of MWSE. Please run MWSE-Update.exe.")
        return
    end

	if not config.version or config.version < 1.11 then
		config.version = 1.11
		if config.blacklist["widowmaker_unique"] then
			config.blacklist["widowmaker_unique"] = nil
			mwse.log("[Enchanted Weapon Resistance] Updated to 1.1.1, removed widowmaker_unique from blacklist")
			tes3.messageBox("[Enchanted Weapon Resistance] Updated to 1.1.1, removed widowmaker_unique from blacklist")
		end
		mwse.saveConfig("enchanted_weapon_resistance", config)
	end

	if config.changeFlag then
		local objectTypes = {
			tes3.objectType.weapon,
			tes3.objectType.ammunition
		}
		for _, objectType in pairs(objectTypes) do
			local objectsByMesh = {}

			for object in tes3.iterateObjects(objectType) do
				if object.sourceMod then
					if not (objectsByMesh[object.mesh:lower()] or object.enchantment) then
						objectsByMesh[object.mesh:lower()] = object
					end
				end
			end
	--		mwse.log("")
	--		mwse.log("")
	--		mwse.log("mesh:	object.id,	object.sourceMod")
	--		for mesh, object in pairs(objectsByMesh) do
	--			mwse.log(mesh..":	"..object.id..",	"..object.sourceMod)
	--		end
	--		mwse.log("")
	--		mwse.log("")
			for object in tes3.iterateObjects(objectType) do
				if object.sourceMod then
					if not (config.blacklist[object.id:lower()] or config.blacklist[object.sourceMod:lower()]) then
						local newObject = objectsByMesh[object.mesh:lower()]
						if object.enchantment and newObject and (object.ignoresNormalWeaponResistance ~= newObject.ignoresNormalWeaponResistance) then
	--						mwse.log("%s: %s -> %s", object.id, object.ignoresNormalWeaponResistance, newObject.ignoresNormalWeaponResistance)
							object.ignoresNormalWeaponResistance = newObject.ignoresNormalWeaponResistance
						end
					end
				end
			end
		end
	end

	event.register("attack", attack)
	event.register("calcHitChance", calcHitChance)

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
			.. " - Automatically changes the Ignore normal weapon resistance flag for all enchanted weapons and ammunition to be the same as an unenchanted item with the same mesh"
			.. "\n"
			.. " - Blocks cast-on-strike enchantments from triggering when the item has no effect on the target"
			.. "\n\n"
			.. "Use this page to toggle the options. Use the blacklist to remove changes the 'Change Ignore normal weapon resistance' option makes to specific items or all items added/changed by a plugin."
    }

	page:createYesNoButton{
		label = "Change Ignore normal weapon resistance",
		description = "Automatically changes the Ignore normal weapon resistance flag for all enchanted weapons and ammunition to be the same as an unenchanted item with the same mesh.\n\nUse the blacklist to remove changes this option makes to specific items or all items added/changed by a plugin. Note that for the changes to come to effect, Morrowind has to be restarted.",
		variable = mwse.mcm.createTableVariable{
			id = "changeFlag",
			table = config
		},
		restartRequired = true
	}
	page:createYesNoButton{
		label = "Block enchantment if weapon has no effect",
		description = "Blocks cast-on-strike enchantments from triggering when the item has no effect on the target.",
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
            },
            {
                label = "Ammunition",
                callback = function()
                    local ammunitions = {}
                    for ammunition in tes3.iterateObjects(tes3.objectType.ammunition) do
                        if ammunition.enchantment then
                            table.insert(ammunitions, ammunition.id:lower())
                        end
                    end
                    table.sort(ammunitions)
                    return ammunitions
                end
            }
        }
    }

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)