local this = {}
function this.onCreate(container)
	
	local descriptionLabel = {} -- global scope so we can update the description in click events

	local function getYesNoText(b)
		return b and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value
	end

	local function toggleCitations(e)
		config.citeYagrum = not config.citeYagrum
		local button = e.source
		button.text = getYesNoText(config.citeYagrum)
		descriptionLabel.text = config.citeYagrum and 
			"The tooltip flavor text cites Yagrum Bagarn's book Tamrielic Lore."
			or
			"The tooltip flavor text does not cite Yagrum Bagarn's book Tamrielic Lore."
	end

	do
		local optionBlock = container:createThinBorder({})
		optionBlock.layoutWidthFraction = 1.0
		optionBlock.flowDirection = "top_to_bottom"
		optionBlock.autoHeight = true
		optionBlock.paddingAllSides = 10

	
		local function makeButton(parentBlock, labelText, buttonText, callBack)
			local buttonBlock
			buttonBlock = parentBlock:createBlock({})
			buttonBlock.flowDirection = "left_to_right"
			buttonBlock.layoutWidthFraction = 1.0
			buttonBlock.autoHeight = true
			
			local label = buttonBlock:createLabel({ text = labelText })
			label.layoutOriginFractionX = 0.0

			
			local button = buttonBlock:createButton({ text = buttonText })
			button.layoutOriginFractionX = 1.0
			button.paddingTop = 3
			button:register("mouseClick", callBack)		
		end
		local buttonText = getYesNoText(config.citeYagrum)
		makeButton(optionBlock, 'Cite the source?', buttonText, toggleCitations)

				
		--Description pane
		local descriptionBlock = container:createThinBorder({})
		descriptionBlock.layoutWidthFraction = 1.0
		descriptionBlock.paddingAllSides = 10
		descriptionBlock.layoutHeightFraction = 1.0
		descriptionBlock.flowDirection = "top_to_bottom"
		
		--Do description first so it can be updated by buttons
		descriptionLabel = descriptionBlock:createLabel({ text = 
			"Yagrum Bagarn's book Tamrielic Lore gives brief descriptions of the stories behind several artifacts, all of which appear in-game. " .. 
			"Tamrielic Lore Tooltips adds excerpts from the book to the tooltips of each respective artifact."
		})
		descriptionLabel.layoutWidthFraction = 1.0
		descriptionLabel.wrapText = true
		
	end
end

function this.onClose(container)
	mwse.log("[phdinsorcery-loretooltips] Saving mod configuration:")
	mwse.log(json.encode(config, { indent = true }))
	json.savefile("config/phdinsorcery_loretooltips_config", config, { indent = true })
end

return this