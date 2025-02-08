local function registerModConfig()

local config = require("DFPSO.config")

local template = mwse.mcm.createTemplate("DFPSO")
  template:saveOnClose("DFPSO", config)

  local page = template:createSideBarPage({ label = "Settings" })
  local settingsPage = page:createCategory("Settings")
  local generalCategory = settingsPage:createCategory("General")
  
  	generalCategory:createYesNoButton({
	label = "Smooth Mode",
	description = "Toogles smooth, per-frame adjustment of View Distance. Requires reload to enable or disable.",
	variable = mwse.mcm.createTableVariable{
		id = "smooth",
		table = config
		}
	})

	generalCategory:createSlider({ 
        label = "Smooth Aggression",
		description = "Determines how aggressively the Smooth Mode adjustment changes View Distance. Does nothing without Smooth Mode.",
		min = 1,
		max = 10,
		step = 1,
		jump = 1,
        variable = mwse.mcm.createTableVariable {
              id = "smoothagro",
              table = config
          }
    })


  
      generalCategory:createSlider({ 
        label = "Target Framerate",
		description = "This determines the framerate the script will try to reach. Default is 60, recommended to set slightly lower than your average framerate in non-stressed areas.",
		min = 15,
		max = 360,
		step = 1,
		jump = 15,
        variable = mwse.mcm.createTableVariable {
              id = "target",
              table = config
          }
    })
	
		generalCategory:createSlider({ 
        label = "Tolerance", 
		description = "Determines upper and lower bounds for the frametime in which no changes to View Distance will be made. Given as percentage value above and below the Target Framerate, computed from frametime.",
		min = 0,
		max = 50,
		step = 1,
		jump = 5,
        variable = mwse.mcm.createTableVariable {
              id = "threshold",
              table = config
          }
    })
	
		generalCategory:createSlider({ 
        label = "Aggression", 
		description = "Determines how many increments of downward or upward change are made to the View Distance per change instance. Increasing this risks overshoot but may help in very heavily stressed setups.",
		min = 1,
		max = 6,
		step = 1,
		jump = 1,
        variable = mwse.mcm.createTableVariable {
              id = "agro",
              table = config
          }
    })
	
		generalCategory:createSlider({ 
        label = "Checkrate", 
		description = "This setting controls how often the current frametime is measured and how often View Distance can be changed, given as checks per second. Only updates when reloading a save.",
		min = 1,
		max = 10,
		step = 1,
		jump = 1,
        variable = mwse.mcm.createTableVariable {
              id = "changerate",
              table = config
          }
    })
	
		generalCategory:createYesNoButton({
		label = "Prediction",
		description = "This feature will compare the frametimes measured during the last two checks to detect lowered performance before it exceeds the tolerance bounds and adjust View Distance down to compensate. Enabling this may prevent framerate drops but lead to overly aggressive View Distance lowering.",
		variable = mwse.mcm.createTableVariable{
			id = "prediction",
			table = config
			}
		})
		
	generalCategory:createSlider({ 
        label = "Prediction Tolerance",
		description = "Determines how large the drop in performance can be before triggering the Prediction View Distance change, given in percentage of Tolerance. Has no effect without Prediction.",
		min = 5,
		max = 100,
		step = 1,
		jump = 5,
        variable = mwse.mcm.createTableVariable {
              id = "predrange",
              table = config
          }
    })
	
	generalCategory:createYesNoButton({
		label = "Delta Awareness",
		description = "Automatically increases the magnitude of View Distance change based on the difference between the current and last checked frametime. Essentially increases Aggression when performance is significantly higher or lower than expected. Only use with low Aggression values.",
		variable = mwse.mcm.createTableVariable{
			id = "delta",
			table = config
			}
		})
	
	generalCategory:createYesNoButton({
		label = "Whitelist",
		description = "This option enables or disables the Whitelist. If enabled, the mod will only apply to cells listed in the Whitelist.JSON file in MWSE's config folder. Use together with Static Adjustment to emulate FOE behaviour.",
		variable = mwse.mcm.createTableVariable{
			id = "usewl",
			table = config
			}
		})

	generalCategory:createYesNoButton({
			label = "Gridlist",
			description = "This option enables or disables the Gridlist. If enabled, the mod will only apply to cells listed in the Gridlist.JSON file in MWSE's config folder. Will override Whitelist if enabled together.",
			variable = mwse.mcm.createTableVariable{
				id = "usegridlist",
				table = config
				}
		})

	generalCategory:createYesNoButton({
				label = "Automatic List Addition",
				description = "Enables automatic addition of low performing cells to the Whitelist/Gridlist. Will add any current cells if performance is below the List Threshold for 3 seconds. Requires reload to enable.",
				variable = mwse.mcm.createTableVariable{
					id = "autoadd",
					table = config
					}
		})

	generalCategory:createSlider({ 
			label = "List Threshold",
			description = "Determines the FPS threshold for automatic list addition. If performance is below this FPS value for more than 3 seconds, the current cell is added to White/Gridlist if Automatic List Addition is enabled.",
			min = 5,
			max = 100,
			step = 1,
			jump = 5,
			variable = mwse.mcm.createTableVariable {
				  id = "wlthres",
				  table = config
			  }
	})

  
	generalCategory:createSlider({ 
        label = "Default View Distance",
		description = "This value determines the default View Distance for non-whitelisted cells. If you have Whitelist enabled and enter a non-whitelisted cell, the mod will set your View Distance to this value. Has no effect without Whitelist.",
		min = 0,
		max = 9,
		step = 1,
		jump = 1,
        variable = mwse.mcm.createTableVariable {
              id = "nwlvalue",
              table = config
          }
    })
	
	generalCategory:createYesNoButton({
		label = "Static Adjustment",
		description = "Switches the function from dynamic, framerate-based View Distance adjustment to static View Distance adjustment. Requires Whitelist. If enabled, will set the View Distance to the value specified in Static View Distance upon entering a whitelisted cell.",
		variable = mwse.mcm.createTableVariable{
			id = "static",
			table = config
			}
		})
		
	generalCategory:createSlider({ 
        label = "Static View Distance",
		description = "This value is used to set the View Distance in whitelisted cells when Static Adjustment is enabled. Requires both Whitelist and Static Adjustment.",
		min = 0,
		max = 9,
		step = 1,
		jump = 1,
        variable = mwse.mcm.createTableVariable {
              id = "staticvd",
              table = config
          }
    })
  

		

	
	template:register()
end

event.register("modConfigReady", registerModConfig)
