local util = {}

function util.metadataMissing()
	local errorMessage = "Error! Avni the Ash-hound-metadata.toml file is missing. Please install."
	tes3.messageBox{
		message = errorMessage
	}
	error(errorMessage)
end

return util