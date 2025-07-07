local enableLogging = false
-- enableLogging = true -- comment this out in production builds!

return {
	log = function(...)
		if not enableLogging then
			return
		end
		print(...)
	end,
}
