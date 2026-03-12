async:newUnsavableSimulationTimer(0.1, function()

if not I.InventoryExtender then
	return
end

local BASE = I.InventoryExtender.Templates.BASE
local MAGIC = I.InventoryExtender.Templates.MAGIC


local function getInnerContent(layout)
	local ok, result = pcall(function()
		return layout.content[1].content[1].content
	end)
	return ok and result or nil
end

local REPAIR_TO_INGREDIENT = {
	["sm_t_ingmine_oreiron_01"]      = "t_ingmine_oreiron_01",
	["sm_t_ingmine_coal_01"]         = "t_ingmine_coal_01",
	["sm_t_ingmine_oresilver_01"]    = "t_ingmine_oresilver_01",
	["sm_t_ingmine_orecopper_01"]    = "t_ingmine_orecopper_01",
	["sm_t_ingmine_oregold_01"]      = "t_ingmine_oregold_01",
	["sm_t_ingmine_oreorichalcum_01"]= "t_ingmine_oreorichalcum_01",
	["sm_ingred_diamond_01"]         = "ingred_diamond_01",
	["sm_ingred_adamantium_ore_01"]  = "ingred_adamantium_ore_01",
	["sm_ingred_raw_ebony_01"]       = "ingred_raw_ebony_01",
	["sm_ingred_raw_glass_01"]       = "ingred_raw_glass_01",
}

I.InventoryExtender.registerTooltipModifier("SunsDusk_RepairAsIngredient", function(item, layout)
	local targetId = REPAIR_TO_INGREDIENT[item.recordId]
	if not targetId then return layout end

	local rec = types.Ingredient.records[targetId]
	if not rec then return layout end

	local content = getInnerContent(layout)
	if not content then return layout end

	content.condition = nil
	content.quality = nil

	local alchemy = self.type.stats.skills.alchemy(self).base
	local visibleCount = math.floor(alchemy / core.getGMST('fWortChanceValue'))

	local effectLayouts = {}
	for i, effect in ipairs(rec.effects) do
		local row = {
			type = ui.TYPE.Flex,
			props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
			content = ui.content {}
		}
		if i <= visibleCount then
			row.content:add(MAGIC.effectIcon(effect.id))
			row.content:add(BASE.intervalH(4))
			row.content:add({
				template = BASE.textNormal,
				props = { text = core.magic.effects.records[effect.id].name }
			})
		else
			row.content:add({ template = BASE.textNormal, props = { text = '?' } })
		end
		if i ~= 1 then table.insert(effectLayouts, BASE.intervalV(8)) end
		table.insert(effectLayouts, row)
	end

	if #effectLayouts > 0 then
		for i, row in ipairs(effectLayouts) do
			content:insert(2 + i, row)
		end
	end

	return layout
end)

end)