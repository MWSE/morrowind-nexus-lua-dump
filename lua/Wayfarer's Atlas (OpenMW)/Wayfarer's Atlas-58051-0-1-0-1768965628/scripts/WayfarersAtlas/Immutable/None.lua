return setmetatable({}, {
	__tostring = function()
		return "Symbol_None"
	end,
	__index = function()
		error("Cannot index None")
	end,
})
