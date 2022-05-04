local config = require("rfuzzo.CompareTooltip.config")

local common = {}

--- local logger
--- @param msg string
--- @vararg any *Optional*. No description yet available.
function common.mod_log(msg, ...)
	local str = "[ %s/%s ] " .. msg
	local arg = { ... }
	return mwse.log(str, config.author, config.id, unpack(arg))
end

--- Sets the color of an element by status
--- @param element tes3uiElement
--- @param status integer
function common.set_color(element, status)
	if (config.useColors) then
		local color = "normal_color"
		if (status == 1) then
			color = "fatigue_color" -- better
		elseif (status == 2) then
			color = "health_color" -- worse
		end

		-- update color
		if (color ~= "normal_color") then
			element.color = tes3ui.getPalette(color)
		end
	end
end

--- Creates arrow icons
--- @param element tes3uiElement
--- @param status integer
function common.set_arrows(element, status)
	if (config.useArrows) then
		-- add arrows
		local icon = ""
		if (status == 1) then
			icon = "textures/menu_scroll_up.dds" -- better
		elseif (status == 2) then
			icon = "textures/menu_scroll_down.dds" -- worse
		end
		if (icon ~= "") then
			local img = element:createImage{ path = icon }
			img.absolutePosAlignX = 0.98
			img.absolutePosAlignY = 2.5
			img.imageScaleX = 0.5
			img.imageScaleY = 0.5
		end
	end
end

--[[
    compares two strings popup child fields
		and returns a comparison result integer
		comparison options:
			a) scalars: 	28 vs 1 or 3.00 vs 3.00)
			b) ranges: 		1 - 11 vs 4 - 5)
			c) ratios:		300/300 vs 400/400
		status: 		0 (equal), 1 (better), 2 (worse)
]]
--- @param curText string
--- @param equText string
--- @param elementName string
function common.compare_text(curText, equText, elementName)
	local status = 0

	-- calculate compare factors
	local equ = tonumber(equText)
	local cur = nil
	if (equ ~= nil) then -- (a) check scalars
		-- if that worked, then the current one will work as well
		cur = tonumber(curText)
		-- mwse.log("[ CE ]   scalar comparison (" .. obj.id .. ") " .. cur .. " vs " .. equ)
	else
		if (string.find(equText, "-")) then -- (b) check ranges
			-- what IS a better range?
			-- average
			local split = string.split(equText)
			if (#split == 3) then
				local first = tonumber(split[1])
				local last = tonumber(split[3])

				if (first ~= nil and last ~= nil) then
					equ = (last + first)
					-- if that worked, then the current one will work as well
					split = string.split(curText)
					if (#split == 3) then
						first = tonumber(split[1])
						last = tonumber(split[3])

						if (first ~= nil and last ~= nil) then
							cur = (last + first)
							-- mwse.log("[ CE ]   range comparison (" .. obj.id .. ") " .. cur .. " vs " .. equ)
						end
					end
				end
			end
		elseif (string.find(equText, "/")) then -- (b) check ratio
			-- calculate ratio? (not necessarily a good indicator)
			-- for now, calculate the highest last value
			local split = string.split(equText, "/")
			if (#split == 2) then
				local first = tonumber(split[1])
				local last = tonumber(split[2])
				if (first ~= nil and last ~= nil) then
					equ = last
					-- if that worked, then the current one will work as well
					split = string.split(curText, "/")
					first = tonumber(split[1])
					last = tonumber(split[2])
					if (first ~= nil and last ~= nil) then
						cur = last
						-- mwse.log("[ CE ]   ratio comparison (" .. obj.id .. ") " .. cur .. " vs " .. equ)
					end
				end
			end
		end
	end

	-- compare
	if (cur ~= nil and equ ~= nil) then
		-- is bigger always better?
		local isReversed = false
		if (elementName == "HelpMenu_weight") then
			isReversed = true
		end
		-- if ui expansion used named fields that would work here

		if (cur > equ) then
			if isReversed then
				status = 2
			else
				status = 1
			end
		elseif (cur < equ) then
			if isReversed then
				status = 1
			else
				status = 2
			end
		end
	end

	return status
end

return common
