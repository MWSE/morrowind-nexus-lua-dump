function log(...)
	local arg = {...}
	local d = 4 * (tonumber(arg[2]) - 1)
	local s = ""
	for i = 1, d do
		s = s .. " "
	end
	print(s .. string.format(...))
end
