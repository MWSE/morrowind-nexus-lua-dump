local util = {}

function util.metadataMissing()
	local errorMessage = "Ошибка! Отсутствует файл Watch the Skies-metadata.toml. Пожалуйста, переустановите мод."
	tes3.messageBox {
		message = errorMessage,
	}
	error(errorMessage)
end

return util
