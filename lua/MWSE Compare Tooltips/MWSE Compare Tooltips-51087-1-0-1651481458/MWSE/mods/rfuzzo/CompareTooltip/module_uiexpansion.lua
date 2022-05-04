local config = require("rfuzzo.CompareTooltip.config")
local common = require("rfuzzo.CompareTooltip.common")

local isUIExpansionInstalled = tes3.isLuaModActive("UI Expansion")
isUIExpansionInstalled = true

local this = {}

--- caches uiexpansion label text for element id
--- @param id string
--- @param equTooltip tes3uiElement
--- @param equTable table
function this.uiexpansion_cache(equTooltip, id, equTable)
	if (not isUIExpansionInstalled) then
		return
	end

	local uiExpElement = equTooltip:findChild(id)
	if (uiExpElement ~= nil) then
		for _, element in ipairs(uiExpElement.children) do
			if (element.text ~= nil and element.text ~= '') then
				equTable[id] = element.text
				-- common.mod_log("  uiexpansion_cache (%s): %s", id, equTable[id])
			end
		end
	end
end

--- updates uiexpansion label with comparisons
--- @param id string
--- @param equTooltip tes3uiElement
--- @param equTable table
function this.uiexpansion_update(equTooltip, id, equTable)
	if (not isUIExpansionInstalled) then
		-- common.mod_log("uiexpansion_update not installed")
		return
	end

	local uiExpElement = equTooltip:findChild(id)
	if (uiExpElement ~= nil) then
		for _, element in ipairs(uiExpElement.children) do
			if (element.text ~= nil and element.text ~= '') then
				local eText = equTable[id]
				local cText = element.text

				-- common.mod_log("  uiexpansion_update (%s): %s vs %s", id, cText, eText)

				-- Compare
				local status = common.compare_text(cText, eText, element.name)
				-- ui expansion fix weight here
				if (id == 'UIEXP_Tooltip_IconWeightBlock') then
					if (status == 1) then
						status = 2
					elseif (status == 2) then
						status = 1
					end
				end
				common.set_color(element, status)

				if (config.useParens) then
					-- add compare text
					element.text = element.text .. " (" .. eText .. ")"
					element:updateLayout()
				end

			end
		end
	end
end

--- updates uiexpansion label with comparisons
--- @param id string
--- @param equTooltip tes3uiElement
--- @param status integer
function this.uiexpansion_color_block(equTooltip, id, status)
	if (not isUIExpansionInstalled) then
		return
	end

	local uiExpElement = equTooltip:findChild(id)
	if (uiExpElement ~= nil) then
		for _, element in ipairs(uiExpElement.children) do
			if (element.text ~= nil and element.text ~= '') then
				common.set_color(element, status)
				element:updateLayout()
			end
		end
	end
end

return this
