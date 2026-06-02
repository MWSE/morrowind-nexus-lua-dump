if not registerWildcard then
	ui.showMessage("iSmith requires the latest version of Crafting Framework")
	return
end

-- registering the profession is optional
--registerProfession{
--	name = "iSmith",
--	skillId = "ismith_smithing",
--}

-- hammer weapons: any blunt 1h or 2h-close used as the crafting tool
registerWildcard{
	id = "iSmith:hammer_weapons",
	name = "Hammer Weapons",
	version = 1,
	icon = "icons/k/combat_blunt.dds",
	func = function()
		local ret = {}
		for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
			local record = types.Weapon.record(item)
			local weaponType = record.type
			if (weaponType == types.Weapon.TYPE.BluntOneHand or weaponType == types.Weapon.TYPE.BluntTwoClose)
			and (record.id:find("hammer") or record.name:lower():find("hammer"))
			then
				table.insert(ret, item)
			end
		end
		table.sort(ret, function(a, b) return a.count > b.count end)
		return ret
	end,
}

-- anvil station: validate a vanilla anvil is in front of the player on the
-- first tick; subsequent ticks always pass since the workpiece (a generated
-- activator) sits between the camera and the anvil and would otherwise mask it.
-- the movement check inside CF still aborts the craft if the player walks away.
registerStation{
	id = "iSmith:anvil",
	name = "Anvil",
	version = 2,
	icon = "icons/k/combat_armor.dds",
	func = function(craftingTick, recipe)
		if craftingTick and craftingTick > 0 then
			return true
		end
		local iMaxActivateDist = core.getGMST("iMaxActivateDist") or 192
		local function getCameraVector()
			local yaw = camera.getYaw()
			local pitch = camera.getPitch()
			local cosPitch = math.cos(pitch)
			return util.vector3(
				math.sin(yaw) * cosPitch,
				math.cos(yaw) * cosPitch,
				-math.sin(pitch)
			)
		end
		local cameraPos = camera.getPosition()
		local maxDist = iMaxActivateDist + camera.getThirdPersonDistance()
		local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
		if telekinesis then
			maxDist = maxDist + telekinesis.magnitude * 22
		end
		local endPos = cameraPos + getCameraVector() * maxDist
		local ray = nearby.castRenderingRay(cameraPos, endPos, { ignore = self })
		return ray.hitObject and ray.hitObject.recordId and ray.hitObject.recordId:lower():find("anvil")
	end,
}

local recipes = {
	{
		id = "iron fork",
		craftingCategory = "[030] Iron",
		types = "🗡️",
		level = 5,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		craftingSound = "forging",
		manualProgress = true,
	},
	{
		id = "iron club",
		craftingCategory = "[030] Iron",
		types = "🔨",
		level = 7,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		craftingSound = "forging",
		manualProgress = true,
	},
	{
		id = "iron broadsword",
		craftingCategory = "[030] Iron",
		types = "⚔️",
		level = 7,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron dagger",
		craftingCategory = "[030] Iron",
		types = "🗡️",
		level = 8,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron tanto",
		craftingCategory = "[030] Iron",
		types = "🗡️",
		level = 9,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "iron dagger", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron mace",
		craftingCategory = "[030] Iron",
		types = "🔨",
		level = 12,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron longsword",
		craftingCategory = "[030] Iron",
		types = "⚔️",
		level = 13,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron saber",
		craftingCategory = "[030] Iron",
		types = "⚔️",
		level = 14,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Iron Long Spear",
		craftingCategory = "[030] Iron",
		types = "🔱",
		level = 14,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron halberd",
		craftingCategory = "[030] Iron",
		types = "🔱",
		level = 14,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "Iron Long Spear", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron shortsword",
		craftingCategory = "[030] Iron",
		types = "🗡️",
		level = 14,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "iron tanto", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "nordic claymore",
		craftingCategory = "[050] Steel",
		types = "⚔️2H",
		level = 29,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron war axe",
		craftingCategory = "[030] Iron",
		types = "🪓",
		level = 15,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwarven battle axe",
		craftingCategory = "[080] Dwemer",
		types = "🪓2H",
		level = 34,
		craftingTime = 6,
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 8 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwarven warhammer",
		craftingCategory = "[080] Dwemer",
		types = "🔨2H",
		level = 37,
		craftingTime = 6,
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 9 },
			{ id = "T_IngMine_OreIron_01", count = 5 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron wakizashi",
		craftingCategory = "[030] Iron",
		types = "🗡️",
		level = 17,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "iron shortsword", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel broadsword",
		craftingCategory = "[050] Steel",
		types = "⚔️",
		level = 13,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel club",
		craftingCategory = "[050] Steel",
		types = "🔨",
		level = 13,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel dagger",
		craftingCategory = "[050] Steel",
		types = "🗡️",
		level = 14,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel axe",
		craftingCategory = "[050] Steel",
		types = "🪓",
		level = 20,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel spear",
		craftingCategory = "[050] Steel",
		types = "🔱",
		level = 20,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "nordic broadsword",
		craftingCategory = "[050] Steel",
		types = "⚔️",
		level = 21,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel mace",
		craftingCategory = "[050] Steel",
		types = "🔨",
		level = 22,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwarven claymore",
		craftingCategory = "[080] Dwemer",
		types = "⚔️2H",
		level = 37,
		craftingTime = 6,
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 8 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel longsword",
		craftingCategory = "[050] Steel",
		types = "⚔️",
		level = 24,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel tanto",
		craftingCategory = "[050] Steel",
		types = "🗡️",
		level = 24,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel saber",
		craftingCategory = "[050] Steel",
		types = "⚔️",
		level = 24,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwarven crossbow",
		craftingCategory = "[080] Dwemer",
		types = "🏹🎯",
		level = 38,
		craftingTime = 6,
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 11 },
			{ id = "T_IngMine_OreIron_01", count = 5 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel shortsword",
		craftingCategory = "[050] Steel",
		types = "🗡️",
		level = 24,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel halberd",
		craftingCategory = "[050] Steel",
		types = "🔱",
		level = 25,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel war axe",
		craftingCategory = "[050] Steel",
		types = "🪓",
		level = 25,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "T_IngMine_Coal_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel katana",
		craftingCategory = "[050] Steel",
		types = "⚔️",
		level = 25,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "T_IngMine_Coal_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "silver claymore",
		craftingCategory = "[090] Silver",
		types = "⚔️2H",
		level = 30,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 5 },
			{ id = "T_IngMine_OreIron_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel wakizashi",
		craftingCategory = "[050] Steel",
		types = "🗡️",
		level = 26,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel longbow",
		craftingCategory = "[050] Steel",
		types = "🏹",
		level = 26,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 6 },
			{ id = "T_IngMine_Coal_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM nordic silver claymore",
		craftingCategory = "[090] Silver",
		types = "⚔️2H",
		level = 58,
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 7 },
			{ id = "T_IngMine_OreIron_01", count = 8 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM nordic silver battleaxe",
		craftingCategory = "[090] Silver",
		types = "🪓2H",
		level = 61,
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 8 },
			{ id = "T_IngMine_OreIron_01", count = 8 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_claymore",
		craftingCategory = "[110] Adamantium",
		types = "⚔️2H",
		level = 59,
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 8 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_axe",
		craftingCategory = "[110] Adamantium",
		types = "🪓2H",
		level = 72,
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 8 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel staff",
		craftingCategory = "[050] Steel",
		types = "🦯",
		level = 31,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwarven spear",
		craftingCategory = "[080] Dwemer",
		types = "🔱",
		level = 30,
		craftingTime = 6,
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 8 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwarven shortsword",
		craftingCategory = "[080] Dwemer",
		types = "🗡️",
		level = 33,
		craftingTime = 6,
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwarven mace",
		craftingCategory = "[080] Dwemer",
		types = "🔨",
		level = 33,
		craftingTime = 6,
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 8 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "6th bell hammer",
		craftingCategory = "[120] Ebony",
		types = "🔨2H",
		level = 73,
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 10 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwarven war axe",
		craftingCategory = "[080] Dwemer",
		types = "🪓",
		level = 34,
		craftingTime = 6,
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 7 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass claymore",
		craftingCategory = "[140] Glass",
		types = "⚔️2H",
		level = 77,
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 9 },
			{ id = "T_IngMine_OreSilver_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwarven halberd",
		craftingCategory = "[080] Dwemer",
		types = "🔱",
		level = 37,
		craftingTime = 6,
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 9 },
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "dwarven spear", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric warhammer",
		craftingCategory = "[160] Daedric",
		types = "🔨2H",
		level = 96,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 7 },
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "Misc_SoulGem_Grand", count = 3 },
			{ id = "6th bell hammer", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric claymore",
		craftingCategory = "[160] Daedric",
		types = "⚔️2H",
		level = 96,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 6 },
			{ id = "Misc_SoulGem_Grand", count = 2 },
			{ id = "daedric longsword", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "silver dagger",
		craftingCategory = "[090] Silver",
		types = "🗡️",
		level = 20,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 3 },
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "silver shortsword",
		craftingCategory = "[090] Silver",
		types = "🗡️",
		level = 25,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "silver longsword",
		craftingCategory = "[090] Silver",
		types = "⚔️",
		level = 27,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "silver spear",
		craftingCategory = "[090] Silver",
		types = "🔱",
		level = 29,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 6 },
			{ id = "T_IngMine_OreIron_01", count = 7 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "silver war axe",
		craftingCategory = "[090] Silver",
		types = "🪓",
		level = 29,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 7 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric battle axe",
		craftingCategory = "[160] Daedric",
		types = "🪓2H",
		level = 98,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 6 },
			{ id = "Misc_SoulGem_Grand", count = 2 },
			{ id = "daedric war axe", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM nordic silver mace",
		craftingCategory = "[090] Silver",
		types = "🔨",
		level = 48,
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM nordic silver shortsword",
		craftingCategory = "[090] Silver",
		types = "🗡️",
		level = 48,
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 3 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "silver staff",
		craftingCategory = "[090] Silver",
		types = "🦯",
		level = 48,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 7 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM nordic silver dagger",
		craftingCategory = "[090] Silver",
		types = "🗡️",
		level = 55,
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 3 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric dai-katana",
		craftingCategory = "[160] Daedric",
		types = "⚔️2H",
		level = 99,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 5 },
			{ id = "Misc_SoulGem_Grand", count = 2 },
			{ id = "daedric katana", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM nordic silver axe",
		craftingCategory = "[090] Silver",
		types = "🪓",
		level = 60,
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 5 },
			{ id = "T_IngMine_OreIron_01", count = 6 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "miner's pick",
		craftingCategory = "Misc",
		types = "🪓2H",
		level = 8,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 5 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Ebony_Pickaxe_01",
		craftingCategory = "Misc",
		types = "🪓2H",
		level = 60,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 11 },
			{ id = "ingred_diamond_01", count = 3 },
			{ id = "miner's pick", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_mace",
		craftingCategory = "[110] Adamantium",
		types = "🔨",
		level = 54,
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_spear",
		craftingCategory = "[110] Adamantium",
		types = "🔱",
		level = 61,
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 8 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_shortsword",
		craftingCategory = "[110] Adamantium",
		types = "🗡️",
		level = 62,
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony broadsword",
		craftingCategory = "[120] Ebony",
		types = "⚔️",
		level = 57,
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 5 },
			{ id = "T_IngMine_OreGold_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony spear",
		craftingCategory = "[120] Ebony",
		types = "🔱",
		level = 68,
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 10 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony mace",
		craftingCategory = "[120] Ebony",
		types = "🔨",
		level = 71,
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 10 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony shortsword",
		craftingCategory = "[120] Ebony",
		types = "🗡️",
		level = 73,
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 5 },
			{ id = "T_IngMine_OreGold_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony war axe",
		craftingCategory = "[120] Ebony",
		types = "🪓",
		level = 74,
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 8 },
			{ id = "T_IngMine_OreGold_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony longsword",
		craftingCategory = "[120] Ebony",
		types = "⚔️",
		level = 74,
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 12 },
			{ id = "T_IngMine_OreGold_01", count = 5 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony staff",
		craftingCategory = "[120] Ebony",
		types = "🦯",
		level = 95,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "T_IngMine_OreGold_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Ebony Scimitar",
		craftingCategory = "[120] Ebony",
		types = "⚔️",
		level = 106,
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 9 },
			{ id = "T_IngMine_OreGold_01", count = 13 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM ice dagger",
		craftingCategory = "[130] Stahlrim",
		types = "🗡️",
		level = 71,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 3 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM ice war axe",
		craftingCategory = "[130] Stahlrim",
		types = "🪓",
		level = 86,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 5 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM ice mace",
		craftingCategory = "[130] Stahlrim",
		types = "🔨",
		level = 91,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 6 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM ice longsword",
		craftingCategory = "[130] Stahlrim",
		types = "⚔️",
		level = 98,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 5 },
			{ id = "T_IngMine_OreIron_01", count = 7 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass staff",
		craftingCategory = "[140] Glass",
		types = "🦯",
		level = 65,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 6 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass dagger",
		craftingCategory = "[140] Glass",
		types = "🗡️",
		level = 68,
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 4 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass war axe",
		craftingCategory = "[140] Glass",
		types = "🪓",
		level = 71,
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 3 },
			{ id = "T_IngMine_OreSilver_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass longsword",
		craftingCategory = "[140] Glass",
		types = "⚔️",
		level = 71,
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 9 },
			{ id = "T_IngMine_OreSilver_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass halberd",
		craftingCategory = "[140] Glass",
		types = "🔱",
		level = 73,
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 4 },
			{ id = "T_IngMine_OreSilver_01", count = 3 },
			{ id = "glass staff", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron warhammer",
		craftingCategory = "[030] Iron",
		types = "🔨2H",
		level = 15,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "iron mace", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric club",
		craftingCategory = "[160] Daedric",
		types = "🔨",
		level = 65,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 6 },
			{ id = "Misc_SoulGem_Greater", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric dagger",
		craftingCategory = "[160] Daedric",
		types = "🗡️",
		level = 68,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 4 },
			{ id = "Misc_SoulGem_Greater", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric tanto",
		craftingCategory = "[160] Daedric",
		types = "🗡️",
		level = 77,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "Misc_SoulGem_Greater", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric mace",
		craftingCategory = "[160] Daedric",
		types = "🔨",
		level = 79,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "Misc_SoulGem_Greater", count = 2 },
			{ id = "ebony mace", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric spear",
		craftingCategory = "[160] Daedric",
		types = "🔱",
		level = 83,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "Misc_SoulGem_Greater", count = 2 },
			{ id = "ebony spear", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric staff",
		craftingCategory = "[160] Daedric",
		types = "🦯",
		level = 84,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "Misc_SoulGem_Grand", count = 2 },
			{ id = "ebony staff", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric shortsword",
		craftingCategory = "[160] Daedric",
		types = "🗡️",
		level = 84,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "Misc_SoulGem_Greater", count = 2 },
			{ id = "ebony shortsword", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric long bow",
		craftingCategory = "[160] Daedric",
		types = "🏹",
		level = 87,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 8 },
			{ id = "Misc_SoulGem_Grand", count = 3 },
			{ id = "ebony staff", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric longsword",
		craftingCategory = "[160] Daedric",
		types = "⚔️",
		level = 88,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "Misc_SoulGem_Greater", count = 2 },
			{ id = "ebony longsword", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric war axe",
		craftingCategory = "[160] Daedric",
		types = "🪓",
		level = 89,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "Misc_SoulGem_Greater", count = 2 },
			{ id = "ebony war axe", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric katana",
		craftingCategory = "[160] Daedric",
		types = "⚔️",
		level = 92,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 4 },
			{ id = "Misc_SoulGem_Grand", count = 2 },
			{ id = "daedric longsword", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric wakizashi",
		craftingCategory = "[160] Daedric",
		types = "🗡️",
		level = 93,
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 4 },
			{ id = "Misc_SoulGem_Grand", count = 2 },
			{ id = "daedric tanto", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron claymore",
		craftingCategory = "[030] Iron",
		types = "⚔️2H",
		level = 16,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "iron longsword", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron battle axe",
		craftingCategory = "[030] Iron",
		types = "🪓2H",
		level = 17,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "iron war axe", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "nordic battle axe",
		craftingCategory = "[050] Steel",
		types = "🪓2H",
		level = 23,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel crossbow",
		craftingCategory = "[050] Steel",
		types = "🏹🎯",
		level = 24,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 7 },
			{ id = "T_IngMine_Coal_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel warhammer",
		craftingCategory = "[050] Steel",
		types = "🔨2H",
		level = 26,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 6 },
			{ id = "T_IngMine_Coal_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM Nordic Pick",
		craftingCategory = "Misc",
		types = "🪓",
		level = 44,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 6 },
			{ id = "ingred_diamond_01", count = 3 },
			{ id = "miner's pick", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel claymore",
		craftingCategory = "[050] Steel",
		types = "⚔️2H",
		level = 26,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "T_IngMine_Coal_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "imperial broadsword",
		craftingCategory = "[060] Imperial",
		types = "⚔️",
		level = 18,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 1 },
			{ id = "Any leather", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel battle axe",
		craftingCategory = "[050] Steel",
		types = "🪓2H",
		level = 28,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "T_IngMine_Coal_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dreugh club",
		craftingCategory = "{5} Other",
		types = "🔨",
		level = 19,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 4 },
			{ id = "ingred_dreugh_wax_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dreugh staff",
		craftingCategory = "{5} Other",
		types = "🦯",
		level = 53,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 7 },
			{ id = "T_IngMine_Coal_01", count = 4 },
			{ id = "ingred_dreugh_wax_01", count = 10 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel dai-katana",
		craftingCategory = "[050] Steel",
		types = "⚔️2H",
		level = 28,
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 6 },
			{ id = "T_IngMine_Coal_01", count = 5 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish battle axe",
		craftingCategory = "[100] Orcish",
		types = "🪓2H",
		level = 47,
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 8 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish warhammer",
		craftingCategory = "[100] Orcish",
		types = "🔨2H",
		level = 56,
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 9 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
		{
		id = "iron boots",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 7,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_greaves",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 7,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_pauldron_left",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 7,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_pauldron_right",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 7,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_gauntlet_right",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 7,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_gauntlet_left",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 7,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_helmet",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 7,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_cuirass",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 8,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_bracer_left",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 9,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_bracer_right",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 9,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_shield",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 10,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "iron_towershield",
		craftingCategory = "[030] Iron",
		types = "Armor",
		level = 13,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "iron_shield", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_greaves",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 17,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_pauldron_left",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 17,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_pauldron_right",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 17,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_boots",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 17,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_cuirass",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 17,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "nordic_ringmail_cuirass",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 17,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_frost_salts_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_gauntlet_left",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 18,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_gauntlet_right",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 18,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_helm",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 18,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_shield",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 20,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "steel_towershield",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 23,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 1 },
			{ id = "T_IngMine_Coal_01", count = 1 },
			{ id = "steel_shield", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "nordic_iron_cuirass",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 23,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "nordic_iron_helm",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 24,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "trollbone_cuirass",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 25,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "ingred_bonemeal_01", count = 10 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "trollbone_helm",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 25,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "ingred_bonemeal_01", count = 7 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "trollbone_shield",
		craftingCategory = "[050] Steel",
		types = "Armor",
		level = 27,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "ingred_bonemeal_01", count = 10 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "imperial_chain_coif_helm",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 20,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "Any leather", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "imperial_chain_cuirass",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 22,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 3 },
			{ id = "Any leather", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "templar_greaves",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 25,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_racer_plumes_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "templar_pauldron_left",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 25,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_racer_plumes_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "templar_pauldron_right",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 25,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_racer_plumes_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "templar boots",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 25,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_racer_plumes_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "templar_cuirass",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 26,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 5 },
			{ id = "T_IngMine_Coal_01", count = 4 },
			{ id = "ingred_racer_plumes_01", count = 5 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "templar bracer left",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 26,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_racer_plumes_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "templar bracer right",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 26,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_racer_plumes_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "imperial_chain_pauldron_left",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 26,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "Any leather", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "imperial_chain_pauldron_right",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 26,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "Any leather", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "templar_helmet_armor",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 26,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "ingred_racer_plumes_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "imperial shield",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 26,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 3 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "Any leather", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "imperial_chain_greaves",
		craftingCategory = "[060] Imperial",
		types = "Armor",
		level = 30,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreIron_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 2 },
			{ id = "Any leather", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_greaves",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 32,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_pauldron_left",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 32,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_pauldron_right",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 32,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_boots",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 32,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_bracer_left",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 33,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_bracer_right",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 33,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_cuirass",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 33,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 7 },
			{ id = "T_IngMine_Coal_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_helm",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 34,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_shield",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 35,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 6 },
			{ id = "T_IngMine_Coal_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "dwemer_shield_battle_unique",
		craftingCategory = "[080] Dwemer",
		types = "Armor",
		level = 35,
		craftingSound = "forging",
		ingredients = {
			{ id = "ingred_scrap_metal_01", count = 6 },
			{ id = "T_IngMine_Coal_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish_greaves",
		craftingCategory = "[100] Orcish",
		types = "Armor",
		level = 53,
		craftingSound = "forging",
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish_pauldron_left",
		craftingCategory = "[100] Orcish",
		types = "Armor",
		level = 53,
		craftingSound = "forging",
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish_pauldron_right",
		craftingCategory = "[100] Orcish",
		types = "Armor",
		level = 53,
		craftingSound = "forging",
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish_boots",
		craftingCategory = "[100] Orcish",
		types = "Armor",
		level = 53,
		craftingSound = "forging",
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish_bracer_left",
		craftingCategory = "[100] Orcish",
		types = "Armor",
		level = 54,
		craftingSound = "forging",
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish_bracer_right",
		craftingCategory = "[100] Orcish",
		types = "Armor",
		level = 54,
		craftingSound = "forging",
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 2 },
			{ id = "T_IngMine_Coal_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish_cuirass",
		craftingCategory = "[100] Orcish",
		types = "Armor",
		level = 55,
		craftingSound = "forging",
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 7 },
			{ id = "T_IngMine_Coal_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish_helm",
		craftingCategory = "[100] Orcish",
		types = "Armor",
		level = 55,
		craftingSound = "forging",
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 4 },
			{ id = "T_IngMine_Coal_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "orcish_towershield",
		craftingCategory = "[100] Orcish",
		types = "Armor",
		level = 64,
		craftingSound = "forging",
		craftingTime = 7,
		ingredients = {
			{ id = "T_IngMine_OreOrichalcum_01", count = 10 },
			{ id = "T_IngMine_Coal_01", count = 7 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Ebonweave_PauldronL_01",
		craftingCategory = "[105] Ebonweave",
		types = "Armor",
		level = 55,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "Any leather", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Ebonweave_PauldronR_01",
		craftingCategory = "[105] Ebonweave",
		types = "Armor",
		level = 55,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "Any leather", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Ebonweave_BracerL_01",
		craftingCategory = "[105] Ebonweave",
		types = "Armor",
		level = 55,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "Any leather", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreGold_01", count = 2 },
			{ id = "ingred_adamantium_ore_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Ebonweave_BracerR_01",
		craftingCategory = "[105] Ebonweave",
		types = "Armor",
		level = 55,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "Any leather", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreGold_01", count = 2 },
			{ id = "ingred_adamantium_ore_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Ebonweave_Greaves_01",
		craftingCategory = "[105] Ebonweave",
		types = "Armor",
		level = 55,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "Any leather", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Ebonweave_Boots_01",
		craftingCategory = "[105] Ebonweave",
		types = "Armor",
		level = 56,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "Any leather", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Ebonweave_Cuirass_01",
		craftingCategory = "[105] Ebonweave",
		types = "Armor",
		level = 56,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "Any leather", count = 6 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreGold_01", count = 6 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Ebonweave_Helm_01",
		craftingCategory = "[105] Ebonweave",
		types = "Armor",
		level = 56,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "Any leather", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Ebonweave_Helm_02",
		craftingCategory = "[105] Ebonweave",
		types = "Armor",
		level = 56,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "Any leather", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_greaves",
		craftingCategory = "[110] Adamantium",
		types = "Armor",
		level = 63,
		craftingSound = "forging",
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_bracer_left",
		craftingCategory = "[110] Adamantium",
		types = "Armor",
		level = 64,
		craftingSound = "forging",
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_bracer_right",
		craftingCategory = "[110] Adamantium",
		types = "Armor",
		level = 64,
		craftingSound = "forging",
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_pauldron_left",
		craftingCategory = "[110] Adamantium",
		types = "Armor",
		level = 64,
		craftingSound = "forging",
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium boots",
		craftingCategory = "[110] Adamantium",
		types = "Armor",
		level = 64,
		craftingSound = "forging",
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_pauldron_right",
		craftingCategory = "[110] Adamantium",
		types = "Armor",
		level = 64,
		craftingSound = "forging",
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_cuirass",
		craftingCategory = "[110] Adamantium",
		types = "Armor",
		level = 65,
		craftingSound = "forging",
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 7 },
			{ id = "T_IngMine_OreIron_01", count = 7 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "adamantium_helm",
		craftingCategory = "[110] Adamantium",
		types = "Armor",
		level = 108,
		craftingSound = "forging",
		craftingTime = 8,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 10 },
			{ id = "ingred_raw_glass_01", count = 10 },
			{ id = "T_IngMine_OreGold_01", count = 10 },
			{ id = "T_IngMine_OreSilver_01", count = 10 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_pauldron_left",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 78,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 5 },
			{ id = "T_IngMine_OreGold_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_pauldron_right",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 78,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 5 },
			{ id = "T_IngMine_OreGold_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_boots",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 78,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 5 },
			{ id = "T_IngMine_OreGold_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_greaves",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 79,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 10 },
			{ id = "T_IngMine_OreGold_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_bracer_left",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 80,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "T_IngMine_OreGold_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_bracer_right",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 80,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "T_IngMine_OreGold_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_cuirass",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 80,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 10 },
			{ id = "T_IngMine_OreGold_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_closed_helm",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 81,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 5 },
			{ id = "T_IngMine_OreGold_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_shield",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 84,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 8 },
			{ id = "T_IngMine_OreGold_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "ebony_towershield",
		craftingCategory = "[120] Ebony",
		types = "Armor",
		level = 89,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 8 },
			{ id = "T_IngMine_OreGold_01", count = 3 },
			{ id = "ebony_shield", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_Ice_PauldronL",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 77,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_Ice_PauldronR",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 77,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_Ice_Boots",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 77,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_Ice_greaves",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 77,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_Ice_cuirass",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 77,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 6 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_Ice_gauntletL",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 77,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_Ice_gauntletR",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 77,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_Ice_Helmet",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 78,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 2 },
			{ id = "T_IngMine_OreIron_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_NordicMail_Boots",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 79,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "BM_Ice_Boots", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_Ice_Shield",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 79,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_Stalhrim_01", count = 4 },
			{ id = "T_IngMine_OreIron_01", count = 7 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_NordicMail_greaves",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 79,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "BM_Ice_greaves", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_NordicMail_Shield",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 79,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 4 },
			{ id = "BM_Ice_Shield", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_NordicMail_PauldronL",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 79,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "BM_Ice_PauldronL", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_NordicMail_PauldronR",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 79,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "BM_Ice_PauldronR", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_NordicMail_gauntletL",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 80,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "BM_Ice_gauntletL", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_NordicMail_gauntletR",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 80,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "BM_Ice_gauntletR", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_NordicMail_cuirass",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 80,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 5 },
			{ id = "BM_Ice_cuirass", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "BM_NordicMail_Helmet",
		craftingCategory = "[130] Stahlrim",
		types = "Armor",
		level = 80,
		craftingSound = "forging",
		craftingTime = 9,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "BM_Ice_helmet", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_bracer_left",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 88,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 3 },
			{ id = "T_IngMine_OreSilver_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_bracer_right",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 88,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 3 },
			{ id = "T_IngMine_OreSilver_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_pauldron_left",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 88,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 5 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_pauldron_right",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 88,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 5 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_greaves",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 89,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 5 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_boots",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 89,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 5 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_helm",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 89,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 5 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_cuirass",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 90,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 9 },
			{ id = "T_IngMine_OreSilver_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_shield",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 91,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 8 },
			{ id = "T_IngMine_OreSilver_01", count = 3 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "glass_towershield",
		craftingCategory = "[140] Glass",
		types = "Armor",
		level = 96,
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_raw_glass_01", count = 8 },
			{ id = "T_IngMine_OreSilver_01", count = 3 },
			{ id = "glass_shield", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "indoril boots",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 74,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "indoril left gauntlet",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 74,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 2 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "indoril right gauntlet",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 74,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 2 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "indoril pauldron left",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 74,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "indoril pauldron right",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 74,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Ep_SkirtIndWarrior_01",
		craftingCategory = "[150] Indoril",
		types = "Clothing",
		level = 75,
		factionRank = 8,
		faction = "Temple",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "indoril cuirass",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 75,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 7 },
			{ id = "ingred_adamantium_ore_01", count = 7 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "indoril helmet",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 75,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "indoril shield",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 77,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 6 },
			{ id = "ingred_adamantium_ore_01", count = 6 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Ordinator_Greaves_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 78,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Indoril_MH_Guard_shield",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 81,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 6 },
			{ id = "ingred_adamantium_ore_01", count = 6 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Indoril_MH_Guard_Greaves",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 83,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Indoril_MH_Guard_Pauldron_L",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 84,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Indoril_MH_Guard_Pauldron_R",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 84,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Indoril_MH_Guard_boots",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 84,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Indoril_MH_Guard_Cuirass",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 86,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 7 },
			{ id = "ingred_adamantium_ore_01", count = 7 },
			{ id = "ingred_raw_ebony_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Indoril_MH_Guard_gauntlet_L",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 86,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 2 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Indoril_MH_Guard_gauntlet_R",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 86,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 2 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "Indoril_MH_Guard_helmet",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 88,
		factionRank = 8,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 4 },
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 4 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Necrom_Boots_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 89,
		factionRank = 9,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "indoril boots", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Necrom_GauntletL_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 89,
		factionRank = 9,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "indoril left gauntlet", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Necrom_GauntletR_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 89,
		factionRank = 9,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "indoril right gauntlet", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Necrom_Greaves_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 89,
		factionRank = 9,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "T_De_Ordinator_Greaves_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Necrom_PauldronL_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 89,
		factionRank = 9,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "indoril pauldron left", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Necrom_PauldronR_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 89,
		factionRank = 9,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "indoril pauldron right", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Necrom_Helm_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 90,
		factionRank = 9,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "indoril helmet", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Necrom_Cuirass_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 91,
		factionRank = 9,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 7 },
			{ id = "ingred_raw_ebony_01", count = 4 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "indoril cuirass", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Ex_SkirtNecrom_01",
		craftingCategory = "[150] Indoril",
		types = "Clothing",
		level = 91,
		factionRank = 9,
		faction = "Temple",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "T_De_Ep_SkirtIndWarrior_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_De_Necrom_Shield_01",
		craftingCategory = "[150] Indoril",
		types = "Armor",
		level = 92,
		factionRank = 9,
		faction = "Temple",
		craftingSound = "forging",
		craftingTime = 10,
		ingredients = {
			{ id = "ingred_adamantium_ore_01", count = 7 },
			{ id = "T_IngMine_OreGold_01", count = 6 },
			{ id = "T_IngMine_OreSilver_01", count = 2 },
			{ id = "indoril shield", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_greaves",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 96,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "SC_greaterSoul", count = 2 },
			{ id = "ebony_greaves", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_pauldron_left",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 96,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "SC_greaterSoul", count = 2 },
			{ id = "ebony_pauldron_left", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_pauldron_right",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 96,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "SC_greaterSoul", count = 2 },
			{ id = "ebony_pauldron_right", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_boots",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 96,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "SC_greaterSoul", count = 2 },
			{ id = "ebony_boots", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_cuirass",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 98,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 5 },
			{ id = "ingred_raw_ebony_01", count = 6 },
			{ id = "SC_greaterSoul", count = 2 },
			{ id = "ebony_cuirass", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_gauntlet_left",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 99,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "SC_greaterSoul", count = 2 },
			{ id = "ebony_bracer_left", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_gauntlet_right",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 99,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "SC_greaterSoul", count = 2 },
			{ id = "ebony_bracer_right", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_fountain_helm",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 100,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 3 },
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "SC_greaterSoul", count = 2 },
			{ id = "ebony_closed_helm", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_shield",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 104,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 4 },
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "SC_greaterSoul", count = 2 },
			{ id = "ebony_shield", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "daedric_towershield",
		craftingCategory = "[160] Daedric",
		types = "Armor",
		level = 108,
		craftingSound = "forging",
		craftingTime = 11,
		ingredients = {
			{ id = "ingred_daedras_heart_01", count = 7 },
			{ id = "ingred_raw_ebony_01", count = 7 },
			{ id = "SC_grandSoul", count = 3 },
			{ id = "ebony_towershield", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "expensive_ring_03",
		craftingCategory = "Jewelry",
		types = "clothing",
		nameOpt = "Expensive Silver Ring",
		level = 24,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "expensive_amulet_03",
		craftingCategory = "Jewelry",
		types = "clothing",
		nameOpt = "Expensive Silver Amulet",
		level = 30,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreSilver_01", count = 2 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "extravagant_ring_02",
		craftingCategory = "Jewelry",
		types = "clothing",
		nameOpt = "Extravagant Gold Ring",
		level = 36,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Imp_Et_AmuletNib_01",
		craftingCategory = "Jewelry",
		types = "clothing",
		nameOpt = "Extravagant Gold Amulet",
		level = 42,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 2 },
			{ id = "T_IngMine_OreSilver_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Ayl_Amulet_01",
		craftingCategory = "Jewelry",
		types = "clothing",
		nameOpt = "Exquisite Gold Amulet",
		level = 65,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 3 },
			{ id = "ingred_adamantium_ore_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
	{
		id = "T_Bre_Ex_Ring_01",
		craftingCategory = "Jewelry",
		types = "clothing",
		nameOpt = "Exquisite Gold Ring",
		level = 77,
		craftingSound = "forging",
		ingredients = {
			{ id = "T_IngMine_OreGold_01", count = 3 },
			{ id = "ingred_raw_glass_01", count = 1 },
		},
		profession = "iSmith",
		tools = {
			{ id = "iSmith:hammer_weapons" },
		},
		stations = {
			{ id = "iSmith:anvil" },
		},
		manualProgress = true,
	},
}

-- redirect every recipe's completion to our standalone global handler
-- so the minigame quality can replace CF's default qualityMult
for _, recipe in ipairs(recipes) do
	recipe.craftingEvent = "iSmith_complete"
end

return recipes