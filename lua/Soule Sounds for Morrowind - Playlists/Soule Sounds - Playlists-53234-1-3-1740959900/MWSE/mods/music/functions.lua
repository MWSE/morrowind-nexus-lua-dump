-- These are all global functions. Global functions are bad for many reasons,
-- which we can expand on in Discord if you want.
-- Consider making this a module like so:

-- BEGIN OF EXAMPLE LIB
--[[
local functions = {}

function this.myFunction(params)
	-- ...
end

-- return functions
-- END OF EXAMPLE LIB

-- BEGIN OF EXAMPLE LIB USAGE
local functions = require("music.functions")
functions.myFunction(params)
-- END OF EXAMPLE LIB USAGE
--]]

--
-- Start of original code.
--
local functions = {}
local lfs = require("lfs")

function functions.randomizeNumber(max, latest)
	if (max <= 1) then
		n = 1
	else
		n = math.random(1, max)
		while (n == latest) do
			n = math.random(1, max)
		end
    end

    return n
end

function functions.checkFolder(path, ext)
	fSize = 0
	for file in lfs.dir(path) do
		if string.endswith(file, ext) then
			fSize = fSize + 1
        end
	end
	return fSize
end

-- For these functions, you can do some fanciness with json, assuming
-- that your tables only contain basic information:
-- mwse.log("%s table contains: %s", "example table", json.encode(t))
-- 
-- If you want it prettier with indentation, do:
-- mwse.log("%s table contains: %s", "example table", json.encode(t, {indent = true}))
function functions.findMaxValPos(t, c)
	local p = {}
	for i = 1, table.getn(t) do
		p[i]= i
	end

	--table.sort(p, function(a, b) return t[a][c] > t[b][c] end)
	table.sort(p, function( a, b ) return c[a] > c[b] end)

	return c[1]
end

return functions