return {
	eventHandlers = {
		Uncapper_roundtrip = function(data)
			data[1]:sendEvent("Uncapper_roundtrip", data[2])
		end,
		Uncapper_IVLRoundtrip = function(data)
			data[1]:sendEvent("Uncapper_IVLRoundtrip", data[2])
		end,
	},
}
