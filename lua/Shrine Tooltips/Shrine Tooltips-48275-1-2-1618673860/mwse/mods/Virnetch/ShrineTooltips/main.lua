
local effects = {}
local shrineScripts = {
	shrineAralor = true,
	shrineDelyn = true,
	shrineFelms = true,
	shrineLlothis = true,
	shrineMeris = true,
	shrineNerevar = true,
	shrineOlms = true,
	shrineRilm = true,
	shrineRoris = true,
	shrineSeryn = true,
	shrineVeloth = true,
	shrineVivecFury = true,
	shrineTemple = true,

	shrineImperial = true,

		--Tamriel_Data
	T_ScObj_ShrineAlessia = true,
	T_ScObj_ShrineAlmalexiaMercy = true,
	T_ScObj_ShrineCuhlecain = true,
	T_ScObj_ShrineMorihaus = true,
	T_ScObj_ShrineReman = true,
	T_ScObj_ShrineSothaSilMastery = true,

	T_ScObj_ShrineSaintColoPC = true,
	T_ScObj_ShrineSaintEmpPC = true,
	T_ScObj_ShrineSaintHealerPC = true,
	T_ScObj_ShrineSaintHearthPC = true,
	T_ScObj_ShrineSaintLawPC = true,
	T_ScObj_ShrineSaintProphPC = true,
	T_ScObj_ShrineSaintTradePC = true,
	T_ScObj_ShrineSaintWarPC = true,
	T_ScObj_ShrineSaintWorkPC = true,

	T_ScObj_ShrinePelinal = true,
	T_ScObj_ShrineOrdinator = true
}

local function menuEnter(e)
	if not tes3.player then return end

    local eyePos = tes3.getPlayerEyePosition()
    local eyeDirection = tes3.getPlayerEyeVector()

    local result = tes3.rayTest{
        position = eyePos,
        direction = eyeDirection,
        ignore = { tes3.player }
    }

	if result and result.reference and result.reference.object and result.reference.object.script then
		if not shrineScripts[result.reference.object.script.id] then
			return
		end

		local buttonLayout = e.element:findChild(tes3ui.registerID("MenuMessage_button_layout"))
		for _, button in pairs(buttonLayout.children) do
			local texts = {}
			local icons = {}
			local id = effects[button.text]
			if id then
				local spell = tes3.getObject(id)
				if spell and spell.objectType == tes3.objectType.spell then
					for i=1, #spell.effects do
						local effect = tes3.getMagicEffect(spell.effects[i].id)
						if effect then
							texts[i] = effect.name
							icons[i] = effect.icon
							if spell.effects[i].attribute ~= -1 then
								local targetAttribute = string.gsub(tes3.getAttributeName(spell.effects[i].attribute), "%l", string.upper, 1)
								texts[i] = string.gsub(texts[i], "Attribute", targetAttribute)
							elseif spell.effects[i].skill ~= -1 then
								local targetSkill = tes3.getSkillName(spell.effects[i].skill)
								texts[i] = string.gsub(texts[i], "Skill", targetSkill)
							end
						end
					end
				end
				if texts[1] then
					button:register("help", function()
						local tooltip = tes3ui.createTooltipMenu()
						local tooltipBlock = tooltip:createBlock()
						tooltipBlock.autoWidth = true
						tooltipBlock.autoHeight = true
						tooltipBlock.flowDirection = "top_to_bottom"
						for i=1, #texts do
							local effectBlock = tooltipBlock:createBlock()
							effectBlock.autoWidth = true
							effectBlock.autoHeight = true
							effectBlock.flowDirection = "left_to_right"
							if icons[i] then
								local icon = effectBlock:createImage{ path = "icons\\"..icons[i] }
								icon.borderRight = 4
								icon.borderTop = 1
							end
							effectBlock:createLabel{ text = texts[i] }
						end
					end)
				end
			end
		end
	end
end
event.register("uiActivated", menuEnter, {filter = "MenuMessage"})

local function getSpellNameById(id)
	local name
	local spell = tes3.getObject(id)
	if spell then
		name = spell.name
	end

	return name
end

local function initialized()
	local blessingIds = {
		"aralor's intervention",
		"shield of st. delyn",
		"felms' glory",
		"the rock of llothis",
		"meris' warding",
		"veloth's indwelling",
		"spirit of nerevar",
		"olms' benediction",
		"rilm's grace",
		"roris' bloom",
		"seryn's shield",
		"vivec's fury",
		"lady's grace shrine",
		"soul of sotha sil",
		"vivec's mystery",

			--Tamriel_Data
		"T_Imp_Res_BlessingAlessia",
		"T_De_Res_AlmalexiasMercy",
		"T_Imp_Res_BlessingCuhlecain",
		"T_Imp_Res_BlessingMorihaus",
		"T_Imp_Res_BlessingReman",
		"T_De_Res_SothaSilsMastery",

		"T_Imp_Res_BlessingStColo",
		"T_Imp_Res_BlessingStEmp",
		"T_Imp_Res_BlessingStHealer",
		"T_Imp_Res_BlessingStHearth",
		"T_Imp_Res_BlessingStLaw",
		"T_Imp_Res_BlessingStProph",
		"T_Imp_Res_BlessingStTrade",
		"T_Imp_Res_BlessingStWar",
		"T_Imp_Res_BlessingStWork",

		"T_Imp_Res_BlessingPelinal",
		"T_De_Res_OrdinatorBlessing"

	}

	for i=1, #blessingIds do
		local id = blessingIds[i]
		local name = getSpellNameById(id)
		if name then
			effects[name] = id
		end
	end

	mwse.log("[Shrine Tooltips] Initialized")
end
event.register("initialized", initialized)