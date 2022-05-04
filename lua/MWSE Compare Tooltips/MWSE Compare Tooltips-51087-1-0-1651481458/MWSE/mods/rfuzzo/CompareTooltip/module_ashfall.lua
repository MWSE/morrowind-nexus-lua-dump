local config = require("rfuzzo.CompareTooltip.config")
local common = require("rfuzzo.CompareTooltip.common")

local isAshfallInstalled = tes3.isLuaModActive("mer.ashfall")

local this = {}

--- caches ashfall label text for element id
--- @param id string
--- @param equTooltip tes3uiElement
--- @param equTable table
function this.ashfall_cache(equTooltip, id, equTable)
	if (not isAshfallInstalled) then
		return
	end

	local element = equTooltip:findChild(id)
	if (element ~= nil and element.text ~= nil) then
		equTable[id] = string.trim(element.text)
		-- common.mod_log("  ashfall_cache (%s): %s", id, equTable[id])
	end
end

--- updates ashfall label with comparisons
--- @param id string
--- @param equTooltip tes3uiElement
--- @param equTable table
function this.ashfall_update(equTooltip, id, equTable)
	if (not isAshfallInstalled) then
		-- common.mod_log("ashfall_update not installed")
		return
	end

	local element = equTooltip:findChild(id)
	if (element ~= nil and element.text ~= nil) then
		local eText = equTable[id]
		local cText = element.text

		-- common.mod_log("  ashfall_update (%s): %s vs %s", id, cText, eText)

		-- Compare
		local status = common.compare_text(cText, eText, element.name)
		common.set_color(element, status)
		-- set header color
		local headerID = string.sub(id, 0, string.len(id) - 5) .. "Header"
		local header = equTooltip:findChild(headerID)
		if (header ~= nil) then
			common.set_color(header, status)
			-- icon hack for arrows
			if (config.useArrows) then
				header.text = "  " .. header.text
				header:updateLayout()
			end
		end

		common.set_arrows(element, status)

		if (config.useParens) then
			-- add compare text
			element.text = element.text .. " (" .. eText .. ")"
		end

		-- icon hack for arrows
		if (config.useArrows) then
			element.text = element.text .. "     "
		end

		element:updateLayout()
	end
end

--- colors a whole block
--- @param id string
--- @param equTooltip tes3uiElement
--- @param status integer
function this.ashfall_color_block(equTooltip, id, status)
	if (not isAshfallInstalled) then
		return
	end

	local element = equTooltip:findChild(id)
	if (element ~= nil and element.text ~= nil) then
		common.set_color(element, status)
		-- set header color
		local headerID = string.sub(id, 0, string.len(id) - 5) .. "Header"
		local header = equTooltip:findChild(headerID)
		if (header ~= nil) then
			common.set_color(header, status)
			-- icon hack for arrows
			if (config.useArrows) then
				header.text = "  " .. header.text
				header:updateLayout()
			end
		end

		common.set_arrows(element, status)

		-- icon hack for arrows
		if (config.useArrows) then
			element.text = element.text .. "     "
		end

		element:updateLayout()
	end
end

return this
