local util = {}

function util.metadataMissing()
	local errorMessage = "Error! AURA.toml file is missing. Please install."
	tes3.messageBox{
		message = errorMessage
	}
	error(errorMessage)
end

function util.getAuthors(authors)
	local length = #authors

	local output = ""

	for i, author in ipairs(authors) do
		if i < length - 1 then
			output = output .. string.format("%s, ", author)
		elseif i == length - 1 then
			output = output .. string.format("%s and ", author)
		else
			output = output .. string.format("%s", author)
		end
	end

	return output
end

return util