local self    = require('openmw.self')
local core    = require('openmw.core')
local ui      = require('openmw.ui')
local I       = require('openmw.interfaces')
local util    = require('openmw.util')
local types   = require('openmw.types')
-- regions req SD for interior cell
local regions = G_hasSunsDusk and require('scripts.MakeAProfit.regions') or nil
local spec    = require('scripts.MakeAProfit.specialization')

local v2 = util.vector2

local Tooltips = {}

-- price tint color scales
-- down: light green -> green -> teal
local SCALE_DOWN = {
	util.color.rgb(0.55, 0.90, 0.55),
	util.color.rgb(0.2,  0.82, 0.45),
	util.color.rgb(0.1,  0.70, 0.70),
}
-- up: orange -> red -> pink
local SCALE_UP = {
	util.color.rgb(1.0,  0.65, 0.25),
	util.color.rgb(0.95, 0.30, 0.22),
	util.color.rgb(0.88, 0.30, 0.55),
}

local LABEL_REGION_DOWN = util.color.rgb(0.4, 0.85, 0.4)  -- export
local LABEL_REGION_UP   = util.color.rgb(0.9, 0.55, 0.2)  -- import
local LABEL_SPEC_DOWN   = util.color.rgb(0.4, 0.85, 0.4)  -- spec, price down
local LABEL_SPEC_UP     = util.color.rgb(0.9, 0.55, 0.2)  -- spec, price up

local function getPriceColor(mult)
	local dev   = math.abs(1 - mult)
	local t     = math.min(dev / (S_SD_MODIFIER / 100), 1.0)
	local scale = mult < 1 and SCALE_DOWN or SCALE_UP
	local a, b, s
	if t <= 0.5 then
		a, b, s = scale[1], scale[2], t * 2
	else
		a, b, s = scale[2], scale[3], (t - 0.5) * 2
	end
	local u = 1 - s
	return util.color.rgb(a.r * u + b.r * s, a.g * u + b.g * s, a.b * u + b.b * s)
end

local helpers

function Tooltips.init(ieHelpers)
	helpers = ieHelpers
end

local function rebuildCondensedRow(inner, BASE, record, adjustedValue, priceColor)
	local flexContent = ui.content {}
	
	if adjustedValue then
		flexContent:add({
			type  = ui.TYPE.Image,
			props = {
				size     = v2(16, 16),
				resource = BASE.createTexture('icons/gold.dds'),
			},
		})
		flexContent:add({
			template = BASE.textNormal,
			props    = { text = ' ' .. adjustedValue, textColor = priceColor },
		})
	end
	
	if record.weight > 0 then
		if #flexContent > 0 then
			flexContent:add(BASE.intervalH(4))
		end
		flexContent:add({
			type  = ui.TYPE.Image,
			props = {
				size     = v2(16, 16),
				resource = BASE.createTexture('icons/weight.dds'),
			},
		})
		flexContent:add({
			template = BASE.textNormal,
			props    = { text = ' ' .. helpers.roundToPlaces(record.weight, 2) },
		})
	end
	
	if #flexContent > 0 then
		inner.weightValue.content = flexContent
	else
		inner.weightValue = nil
	end
end

function Tooltips.registerTooltipModifier()
	local BASE = I.InventoryExtender.Templates.BASE
	
	I.InventoryExtender.registerTooltipModifier('MakeAProfit', function(item, layout)
		if helpers.isGold(item) then return layout end
		
		local mercantile = self.type.stats.skills.mercantile(self).modified
		local inner      = layout.content.padding.content.tooltip.content
		local inBarter   = I.UI.getMode() == 'Barter'
		local isCondensed = inner:indexOf('weightValue') and not inner:indexOf('value')
		
		-- value hiding
		local valueHidden = S_SKILL_THRESHOLD > 0
			and not inBarter
			and mercantile < S_SKILL_THRESHOLD
		
		if valueHidden then
			if not isCondensed and inner:indexOf('value') then
				inner.value.props.text = core.getGMST('sValue') .. ': ' .. S_HIDDEN_TEXT
			end
			if inner:indexOf('weightValue') then
				rebuildCondensedRow(inner, BASE, item.type.record(item), nil, nil)
			end
		end
		
		-- modifiers
		local regionMult  = 1
		local regionStatus = nil
		
		if regions and S_KNOWS_EXPORT > 0 and mercantile >= S_KNOWS_EXPORT then
			regionStatus = regions.getItemStatus(item.recordId)
			if regionStatus then
				local isExport = regionStatus == 'export'
				local f = S_SD_MODIFIER / 100
				regionMult = isExport and (1 - f) or (1 + f)
			end
		end
		
		local specMult    = 1
		local specLabel   = nil
		local specPct     = 0
		local specSelling = false
		
		if spec.playerKnows() and inBarter then
			local tradeWin = I.InventoryExtender.getWindow('Trade')
			local merchant = tradeWin and tradeWin.target
			if merchant then
				local bonus, label = spec.getModifier(merchant, item)
				if bonus > 0 then
					specLabel   = label
					specPct     = math.floor(bonus * 100 + 0.5)
					specSelling = item.parentContainer == self.object
					specMult    = specSelling and (1 + bonus) or (1 - bonus)
				end
			end
		end
		
		-- adjusted price
		local hasRegion = regionMult ~= 1
		local hasSpec   = specMult ~= 1
		
		if not valueHidden and (hasRegion or hasSpec) then
			local baseValue     = item.type.record(item).value
			local adjustedValue = math.max(1,
				math.floor(baseValue * regionMult * specMult))
			
			local tint = getPriceColor(regionMult * specMult)

			if not isCondensed and inner:indexOf('value') then
				inner.value.props.text = core.getGMST('sValue') .. ': #'
					.. tint:asHex() .. adjustedValue .. '#ffffff'
			end
			if isCondensed and inner:indexOf('weightValue') then
				rebuildCondensedRow(inner, BASE,
					item.type.record(item), adjustedValue, tint)
			end
		end
		
		local clauses = {}
		
		if regionStatus and S_EXPORT_LINE then
			local isExport = regionStatus == 'export'
			table.insert(clauses, {
				text  = (isExport and 'local export' or 'regional import')
					.. ' (' .. (isExport and '-' or '+') .. S_SD_MODIFIER .. '%)',
				color = (regionMult < 1) and LABEL_REGION_DOWN or LABEL_REGION_UP,
			})
		end
		
		if inBarter and S_SPEC_LINE then
			local tradeWin = I.InventoryExtender.getWindow('Trade')
			local merchant = tradeWin and tradeWin.target
			if merchant and types.NPC.objectIsInstance(merchant) then
				local npcFaction = types.NPC.record(merchant).faction
				if npcFaction and npcFaction ~= '' then
					local rank = types.NPC.getFactionRank(self, npcFaction)
					if rank and rank > 0 then
						local factionRec = types.Faction.record(npcFaction)
						local factionName = factionRec and factionRec.name or npcFaction
						local selling = item.parentContainer == self.object
						table.insert(clauses, {
							text  = factionName:lower() .. ' rank ' .. rank
								.. ' (' .. (selling and '+' or '-') .. rank .. '%)',
							color = selling and LABEL_SPEC_UP or LABEL_SPEC_DOWN,
						})
					end
				end
			end
		end
		
		if specPct > 0 and S_SPEC_LINE and specLabel then
			table.insert(clauses, {
				text  = specLabel:lower() .. ' specialty ('
					.. (specSelling and '+' or '-') .. specPct .. '%)',
				color = (specMult < 1) and LABEL_SPEC_DOWN or LABEL_SPEC_UP,
			})
		end
		
		if #clauses > 0 then
			for i, clause in ipairs(clauses) do
				local text = clause.text:sub(1, 1):upper()
					.. clause.text:sub(2) .. '.'
				inner:add({
					name     = 'mapModifier_' .. i,
					template = BASE.textNormal,
					props    = { text = text, textColor = clause.color },
				})
			end
		end
		
		return layout
	end)
end

function Tooltips.apply(windowName)
	local window = I.InventoryExtender.getWindow(windowName)
	if not window or not window.itemTable then return end
	
	window.itemTable.layout.userData.setFilter('MAP_valueHider', function(row)
		if row._map_wrapped then return true end
		row._map_wrapped = true
		
		local origValue = row.Value
		local origVW    = row['V/W']
		
		row.Value = function()
			local v = type(origValue) == 'function' and origValue() or origValue
			if S_SKILL_THRESHOLD <= 0 then return v end
			if I.UI.getMode() == 'Barter' then return v end
			local mercantile = self.type.stats.skills.mercantile(self).modified
			if mercantile >= S_SKILL_THRESHOLD then return v end
			if helpers.isGold(row.item) then return tostring(v) end
			return S_HIDDEN_TEXT
		end
		
		row['V/W'] = function()
			local v = type(origVW) == 'function' and origVW() or origVW
			if S_SKILL_THRESHOLD <= 0 then return v end
			if I.UI.getMode() == 'Barter' then return v end
			local mercantile = self.type.stats.skills.mercantile(self).modified
			if mercantile >= S_SKILL_THRESHOLD then return v end
			if helpers.isGold(row.item) then return tostring(v) end
			return ''
		end
		
		return true
	end)
	
	window.itemTable.layout.userData.refresh()
end

return Tooltips