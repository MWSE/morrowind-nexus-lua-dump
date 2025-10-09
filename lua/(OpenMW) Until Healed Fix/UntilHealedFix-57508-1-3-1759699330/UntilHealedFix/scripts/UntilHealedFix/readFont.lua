local core = require('openmw.core')
local vfs = require('openmw.vfs')
local v3 = require('openmw.util').vector3
local v2 = require('openmw.util').vector2
local ui = require('openmw.ui')


local fixInterpolation={
["OpenSans"] = {
	["h"] = 1,
	["l"] = 1,
	["n"] = 1,
}
}
local customLineHeight={
--["pelagiad"]= 100,
--["ayembedt"]= 100,
--["OpenSans"]= 103,
--["roboto"]  = 100,
--["blackops"]= 100,
}
local function readFont(file)
	local temp = file:reverse()
	local fileNameLength = temp:find("\\")-1
	local path = file:sub(1,-fileNameLength-1)
	local maxHeight = 0
	local minYOffset = 99999
	local lines = {}
	for line in vfs.lines(file) do
		table.insert(lines, line)
	end
	
	local glyphData = {}
	for i=2,#lines do
		if i<5 or lines[i]:sub(1,4) == "char" then
			glyphData[i] = {}
			for a in lines[i]:gmatch("%S+") do
				local delimiterPos = a:find("=")
				if delimiterPos then
					glyphData[i][a:sub(1,delimiterPos-1)] = a:sub(delimiterPos+1,#a)
					--print(i.." "..a:sub(1,delimiterPos-1).."="..a:sub(delimiterPos+1,#a))
				end
			end
		end
	end
	
	local glyphFile = path..glyphData[3].file:sub(2,-2)
	local lineHeight = glyphData[2].lineHeight
	local glyphs = {}
	for i=5,#glyphData do
		minYOffset = math.min(minYOffset, tonumber(glyphData[i].yoffset ))
	end
	for i=5,#glyphData do
		glyphData[i].yoffset = tonumber(glyphData[i].yoffset )--minYOffset
		maxHeight = math.max(maxHeight, tonumber(glyphData[i].height)+tonumber(glyphData[i].yoffset ))
	end
	--local shaveOff = lineHeight-maxHeight
	--print("minY",minYOffset)
	--print("maxHeight",maxHeight)
	--print("lineHeight",lineHeight)
	--local lineHeight = customLineHeight[playerSettings:get("FONT")] or maxHeight
	for i=5,#glyphData do
		local character = string.char(tonumber(glyphData[i].id))
		fixInt = 0--fixInterpolation[playerSettings:get("FONT")][character] or 0
		glyphs[character] = {
			xadvance  = tonumber(glyphData[i].xadvance ), 
			xoffset  = tonumber(glyphData[i].xoffset ), 
			yoffset  = tonumber(glyphData[i].yoffset )+fixInt, 
			height = tonumber(glyphData[i].height), 
			width = tonumber(glyphData[i].width), 
			texture =ui.texture{
				path = glyphFile,
				offset = v2(tonumber(glyphData[i].x), tonumber(glyphData[i].y)),
				size = v2(tonumber(glyphData[i].width), tonumber(glyphData[i].height))
			}
		}
	end
	return glyphs,lineHeight
end


return readFont