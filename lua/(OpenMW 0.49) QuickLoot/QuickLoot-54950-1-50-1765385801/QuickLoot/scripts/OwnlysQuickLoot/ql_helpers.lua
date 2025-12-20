local function rgbToHsv(r, g, b, a)
  --r, g, b, a = r / 255, g / 255, b / 255, a / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, v
  v = max

  local d = max - min
  if max == 0 then s = 0 else s = d / max end

  if max == min then
    h = 0 -- achromatic
  else
    if max == r then
    h = (g - b) / d
    if g < b then h = h + 6 end
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h, s, v, a
end

--[[
 * Converts an HSV color value to RGB. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
 * Assumes h, s, and v are contained in the set [0, 1] and
 * returns r, g, and b in the set [0, 255].
 *
 * @param   Number  h       The hue
 * @param   Number  s       The saturation
 * @param   Number  v       The value
 * @return  Array           The RGB representation
]]
local function hsvToRgb(h, s, v, a)
  local r, g, b

  local i = math.floor(h * 6);
  local f = h * 6 - i;
  local p = v * (1 - s);
  local q = v * (1 - f * s);
  local t = v * (1 - (1 - f) * s);

  i = i % 6

  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end

  return r,g,b,a --r * 255, g * 255, b * 255, a * 255
end

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

local function texText(t)--currentHealth,maxHealth,size,color, widgetWidth, widgetHeight, align)
	if t.currentHealth == "player" then
		return {}
	end
	local glyphs = glyphs
	local lineHeight = lineHeight
	if t.obscured then
		glyphs = daedric
		lineHeight = daedricHeight
	end
	local widgetWidth = t.widgetWidth or 50
	local widgetHeight = t.widgetHeight or 14
	local lineLevel = 0
	local size = (t.size or playerSettings:get("HP_SIZE"))
	local relScale = 1/lineHeight*size
	local aspectRatio = widgetHeight/widgetWidth
	local str = ""
	if type(t.currentHealth) == "number" then
		str= str..math.floor(t.currentHealth)
	else
		str = str..(t.currentHealth or "")
	end
	if HP_MAXHP and t.maxHealth then
		str = str.."/"..math.floor(t.maxHealth)
	end
	local ret = {}
	local totalWidth = 0
	
	local middleOffset = 0
	local stretchGlyph = 1
	local gapMult = 0.5
	for i=1, #str do
		local symbol = str:sub(i,i)
		if glyphs[symbol] and glyphs[symbol].width then
			local glyphHeight = lineHeight
			--local glyphHeight = glyphs[symbol].height
			local spaceLeft = glyphs[symbol].xoffset*gapMult
			local spaceRight = (glyphs[symbol].xadvance- glyphs[symbol].xoffset- glyphs[symbol].width)*gapMult
			local glyphWidth =  glyphs[symbol].width*stretchGlyph
			if symbol == " " then
				glyphWidth = glyphWidth+8
			end
			local total = spaceLeft+spaceRight+glyphWidth
			local relTotal = relScale* total   *aspectRatio
			if symbol =="/" then
				middleOffset = totalWidth+relTotal/2
			end
			totalWidth = totalWidth+relTotal
		end
	end
	if middleOffset > 0 then
		middleOffset = totalWidth/2-middleOffset
	end
	local currentPos = 0.5-totalWidth/2+middleOffset
	if t.align =="right" then
		currentPos = 0
	elseif t.align == "left" then
		currentPos = 1-totalWidth
	end
	local levelChars = {"a","b","c","d","e"}
	local lineLevel= 0
	for a,b in pairs(levelChars) do
		if glyphs[b] then
			lineLevel = math.max(lineLevel, glyphs[b].height+glyphs[b].yoffset)
		end
	end
	if lineLevel == 0 then
		lineLevel = glyphs["0"].height+glyphs["0"].yoffset
	end
	lineLevel = lineLevel+0.005
	for i=1, #str do
		local symbol = str:sub(i,i)
		if glyphs[symbol] and glyphs[symbol].width then
			local glyphHeight = lineHeight
			--local glyphHeight = glyphs[symbol].height
			local spaceLeft = glyphs[symbol].xoffset*gapMult
			local spaceRight = (glyphs[symbol].xadvance- glyphs[symbol].xoffset- glyphs[symbol].width)*gapMult
			local glyphWidth =  glyphs[symbol].width*stretchGlyph
			if symbol == " " then
				glyphWidth = glyphWidth+10
			end
			local total = spaceLeft+spaceRight+glyphWidth
			local relSpaceLeft = relScale*spaceLeft*aspectRatio
			local relSpaceRight = relScale*spaceRight*aspectRatio
			local relWidth = relScale*glyphWidth*aspectRatio
			--print(relScale,glyphWidth,aspectRatio)
			--print(glyphs[symbol].height*relScale,glyphs[symbol].height,relScale)
			local relTotal = relScale*total*aspectRatio
			local letterDepth = math.max(0,(glyphs[symbol].height+glyphs[symbol].yoffset-lineLevel)/lineHeight)
			--print(symbol, letterDepth)
			local anchor = letterDepth / (glyphs[symbol].height*relScale)/1.5
			table.insert(ret,{
				type = ui.TYPE.Image,
				props = {
					resource = glyphs[symbol].texture,
					relativePosition= v2(currentPos+relSpaceLeft, 0.41+size/3+letterDepth*relScale*160+TEXT_OFFSET),--glyphs[symbol].yoffset*relScale+(1-size)/2),
					relativeSize  = v2(relWidth, glyphs[symbol].height*relScale),
					color = t.color,
					anchor = v2(0,1)
				}
			} )
			currentPos = currentPos + relTotal
		end
	end
	--table.insert(ret,{
	--	type = ui.TYPE.Image,
	--	props = {
	--		resource = background,
	--		tileH = false,
	--		tileV = false,
	--		relativeSize  = v2(1,1),
	--		alpha = 0.6,
	--	},
	--})
	return ret
end

---- UTF8 conversions
local char, byte, pairs, floor = string.char, string.byte, pairs, math.floor
local table_insert, table_concat = table.insert, table.concat
local unpack = table.unpack or unpack


local function unicode_to_utf8(code)
   -- converts numeric UTF code (U+code) to UTF-8 string
   local t, h = {}, 128
   while code >= h do
      t[#t+1] = 128 + code%64
      code = floor(code/64)
      h = h > 32 and 32 or h/2
   end
   t[#t+1] = 256 - 2*h + code
   return char(unpack(t)):reverse()
end

local function utf8_to_unicode(utf8str, pos)
   -- pos = starting byte position inside input string (default 1)
   pos = pos or 1
   local code, size = utf8str:byte(pos), 1
   if code >= 0xC0 and code < 0xFE then
      local mask = 64
      code = code - 128
      repeat
         local next_byte = utf8str:byte(pos + size) or 0
         if next_byte >= 0x80 and next_byte < 0xC0 then
            code, size = (code - mask - 2) * 64 + next_byte, size + 1
         else
            code, size = utf8str:byte(pos), 1
         end
         mask = mask * 32
      until code < mask
   end
   -- returns code, number of bytes in this utf8 char
   return code, size
end

local map_1252_to_unicode = {
   [0x80] = 0x20AC,
   [0x81] = 0x81,
   [0x82] = 0x201A,
   [0x83] = 0x0192,
   [0x84] = 0x201E,
   [0x85] = 0x2026,
   [0x86] = 0x2020,
   [0x87] = 0x2021,
   [0x88] = 0x02C6,
   [0x89] = 0x2030,
   [0x8A] = 0x0160,
   [0x8B] = 0x2039,
   [0x8C] = 0x0152,
   [0x8D] = 0x8D,
   [0x8E] = 0x017D,
   [0x8F] = 0x8F,
   [0x90] = 0x90,
   [0x91] = 0x2018,
   [0x92] = 0x2019,
   [0x93] = 0x201C,
   [0x94] = 0x201D,
   [0x95] = 0x2022,
   [0x96] = 0x2013,
   [0x97] = 0x2014,
   [0x98] = 0x02DC,
   [0x99] = 0x2122,
   [0x9A] = 0x0161,
   [0x9B] = 0x203A,
   [0x9C] = 0x0153,
   [0x9D] = 0x9D,
   [0x9E] = 0x017E,
   [0x9F] = 0x0178,
   [0xA0] = 0x00A0,
   [0xA1] = 0x00A1,
   [0xA2] = 0x00A2,
   [0xA3] = 0x00A3,
   [0xA4] = 0x00A4,
   [0xA5] = 0x00A5,
   [0xA6] = 0x00A6,
   [0xA7] = 0x00A7,
   [0xA8] = 0x00A8,
   [0xA9] = 0x00A9,
   [0xAA] = 0x00AA,
   [0xAB] = 0x00AB,
   [0xAC] = 0x00AC,
   [0xAD] = 0x00AD,
   [0xAE] = 0x00AE,
   [0xAF] = 0x00AF,
   [0xB0] = 0x00B0,
   [0xB1] = 0x00B1,
   [0xB2] = 0x00B2,
   [0xB3] = 0x00B3,
   [0xB4] = 0x00B4,
   [0xB5] = 0x00B5,
   [0xB6] = 0x00B6,
   [0xB7] = 0x00B7,
   [0xB8] = 0x00B8,
   [0xB9] = 0x00B9,
   [0xBA] = 0x00BA,
   [0xBB] = 0x00BB,
   [0xBC] = 0x00BC,
   [0xBD] = 0x00BD,
   [0xBE] = 0x00BE,
   [0xBF] = 0x00BF,
   [0xC0] = 0x00C0,
   [0xC1] = 0x00C1,
   [0xC2] = 0x00C2,
   [0xC3] = 0x00C3,
   [0xC4] = 0x00C4,
   [0xC5] = 0x00C5,
   [0xC6] = 0x00C6,
   [0xC7] = 0x00C7,
   [0xC8] = 0x00C8,
   [0xC9] = 0x00C9,
   [0xCA] = 0x00CA,
   [0xCB] = 0x00CB,
   [0xCC] = 0x00CC,
   [0xCD] = 0x00CD,
   [0xCE] = 0x00CE,
   [0xCF] = 0x00CF,
   [0xD0] = 0x00D0,
   [0xD1] = 0x00D1,
   [0xD2] = 0x00D2,
   [0xD3] = 0x00D3,
   [0xD4] = 0x00D4,
   [0xD5] = 0x00D5,
   [0xD6] = 0x00D6,
   [0xD7] = 0x00D7,
   [0xD8] = 0x00D8,
   [0xD9] = 0x00D9,
   [0xDA] = 0x00DA,
   [0xDB] = 0x00DB,
   [0xDC] = 0x00DC,
   [0xDD] = 0x00DD,
   [0xDE] = 0x00DE,
   [0xDF] = 0x00DF,
   [0xE0] = 0x00E0,
   [0xE1] = 0x00E1,
   [0xE2] = 0x00E2,
   [0xE3] = 0x00E3,
   [0xE4] = 0x00E4,
   [0xE5] = 0x00E5,
   [0xE6] = 0x00E6,
   [0xE7] = 0x00E7,
   [0xE8] = 0x00E8,
   [0xE9] = 0x00E9,
   [0xEA] = 0x00EA,
   [0xEB] = 0x00EB,
   [0xEC] = 0x00EC,
   [0xED] = 0x00ED,
   [0xEE] = 0x00EE,
   [0xEF] = 0x00EF,
   [0xF0] = 0x00F0,
   [0xF1] = 0x00F1,
   [0xF2] = 0x00F2,
   [0xF3] = 0x00F3,
   [0xF4] = 0x00F4,
   [0xF5] = 0x00F5,
   [0xF6] = 0x00F6,
   [0xF7] = 0x00F7,
   [0xF8] = 0x00F8,
   [0xF9] = 0x00F9,
   [0xFA] = 0x00FA,
   [0xFB] = 0x00FB,
   [0xFC] = 0x00FC,
   [0xFD] = 0x00FD,
   [0xFE] = 0x00FE,
   [0xFF] = 0x00FF,
}
local map_unicode_to_1252 = {}
for code1252, code in pairs(map_1252_to_unicode) do
   map_unicode_to_1252[code] = code1252
end

local function fromutf8(utf8str)
   local pos, result_1252 = 1, {}
   while pos <= #utf8str do
      local code, size = utf8_to_unicode(utf8str, pos)
      pos = pos + size
      code = code < 128 and code or map_unicode_to_1252[code] or ('?'):byte()
      table_insert(result_1252, char(code))
   end
   return table_concat(result_1252)
end

local function toutf8(str1252)
   local result_utf8 = {}
   for pos = 1, #str1252 do
      local code = str1252:byte(pos)
      table_insert(result_utf8, unicode_to_utf8(map_1252_to_unicode[code] or code))
   end
   return table_concat(result_utf8)
end

local bytemarkers = { {0x7FF,192}, {0xFFFF,224}, {0x1FFFFF,240} }
local function hextoutf8(decimal)

    if decimal<128 then return string.char(decimal) end
    local charbytes = {}
    for bytes,vals in ipairs(bytemarkers) do
      if decimal<=vals[1] then
        for b=bytes+1,2,-1 do
          local mod = decimal%64
          decimal = (decimal-mod)/64
          charbytes[b] = string.char(128+mod)
        end
        charbytes[1] = string.char(vals[2]+decimal)
        break
      end
    end
    return table.concat(charbytes)

end
local function formatNumber(num, mode)
	local text = math.floor(num*10)/10
	local textColor = nil
	if mode == "v/w" then
		text = (math.floor(num*10+0.5)/10)
	elseif mode == "weight" then
		text = math.floor(num*10+0.5)/10
	end
	if text >99 or text > 1.2 and (text%1 <=0.1 or text%1 >=0.9) then
		text = math.floor(text)
	end
	infSymbol = false
	if text == 1/0 then
		if not FONT_FIX then
			text = hextoutf8(0x221e)
		else
			text = "-" -- instead of "Inf"
			infSymbol = true
		end
	elseif text >= 10^6-100 then --1m
		text = text/1000--*1.005/1000
		local e = math.floor(math.log10(text))
		text = text + 10^e*1.005-10^e
		local suffixes = {"K","M","G","T","P","E","Z"}
		local i = 1
		while text >= 1000 do
			text = text/1000
			i=i+1
		end
		--text = string.format("%.2f",text)
		text = math.floor(text*100)/100 -- control rounding instead of string format
		text = string.format("%.2f",text)
		if #text == 6 then
			text=text:sub(1,3)
		else
			text = text:sub(1,4)
		end
		text = text.." "..suffixes[i]
	elseif text >= 1000 then
		text = math.floor(text/1000)..(not FONT_FIX and hextoutf8(0x200a)..hextoutf8(0x200a) or "")..string.format("%03d", math.floor((text%1000)/100)*100)
	end
	return ""..text
end

local function tableContains(t,entry)
	for a,b in pairs(t) do
		if b == entry then
			return entry
		end
	end
	return false
end

return {readFont,texText,rgbToHsv,hsvToRgb,fromutf8,toutf8,hextoutf8,formatNumber,tableContains}