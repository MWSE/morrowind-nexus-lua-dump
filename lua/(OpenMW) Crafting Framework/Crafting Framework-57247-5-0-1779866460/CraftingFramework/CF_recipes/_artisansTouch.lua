if not registerTouch then return end

-- ------------------------------ touch ------------------------------
registerTouch{
	id = "artisan",
	label = "Artisan's touch",
	priority = -1,
	gate = function(recipe)
		return (recipe.type == "Weapon" or recipe.type == "Armor"
			or recipe.type == "Clothing") and not recipe.preserveRecordId
	end,
}

-- ------------------------------ effects ------------------------------

registerIngredientsModifier{
	id = "touch:artisan",
	global = true,
	priority = -1,
	func = function(recipe, ctx)
		if not (ctx.touches and ctx.touches.artisan) then return end
		local ingr = ingredientsMutable(ctx)
		for _, i in ipairs(ingr) do
			if i.id == "ingred_diamond_01" then
				i.count = i.count + 1
				return
			end
		end
		table.insert(ingr, { type = "Ingredient", id = "ingred_diamond_01", count = 1 })
	end,
}

registerQualityModifier{
	id = "touch:artisan",
	global = true,
	priority = -1,
	func = function(recipe, ctx)
		if not (ctx.touches and ctx.touches.artisan) then return end
		if ctx.skillMult < 1 then
			local skillMult = (ctx.skillMult + 1) / 2
			local diffMult = skillMult / ctx.skillMult
			ctx.modified = ctx.modified * diffMult
			ctx.skillMult = skillMult
		end
		local levelBonus = math.max(0, checkSkill(recipe))
		ctx.artisanMult = 1 + (math.floor(levelBonus / 2) * 2) / 200 + 0.05
		ctx.modified = ctx.modified * ctx.artisanMult
	end,
}

registerExpModifier{
	id = "touch:artisan",
	global = true,
	priority = -1,
	func = function(recipe, ctx)
		if not (ctx.touches and ctx.touches.artisan) then return end
		for skillId, info in pairs(ctx.skills) do
			if info.diffMod < 1 then
				local ratio = info.diffMod ^ 0.5 / info.diffMod
				ctx.modified[skillId] = ctx.modified[skillId] * ratio
			end
			ctx.modified[skillId] = ctx.modified[skillId] * 1.1 + 0.5
		end
	end,
}

-- time: double the craft duration when the touch is active.
registerTimeModifier{
	id = "touch:artisan",
	global = true,
	priority = -1,
	func = function(recipe, ctx)
		if not (ctx.touches and ctx.touches.artisan) then return end
		ctx.modified = ctx.modified * 2
	end,
}

-- ------------------------------ button ------------------------------
local touchButton

local function applyButtonState()
	if not touchButton then return end
	if activeTouches.artisan then
		touchButton.content.background.props.color = morrowindGold
		touchButton.content.clickbox.userData.customColor = morrowindGold
	else
		touchButton.content.background.props.color = util.color.rgb(0, 0, 0)
		touchButton.content.clickbox.userData.customColor = nil
	end
end

registerWindowBuilder{
	id = "touch:artisan",
	priority = -1,
	func = function(ctx)
		touchButton = makeIconButton("textures/CraftingFramework/diamond.png", v2(S_FONT_SIZE * 1, S_FONT_SIZE * 1), function()
			toggleTouch("artisan")
		end, nil, "touch:artisan")
		applyButtonState()
		ctx.topBarButtonFlex.content:add(touchButton)
	end,
}

onTouchToggled(function(data)
	if data.id == "artisan" then applyButtonState() end
end)
