local config = require("sanekEnchant.config")
local interop = require("sanekEnchant.interop")

local function createTableVar(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config,
    }
end

local function createPage(template)
    local page = template:createSideBarPage{
        label = "Settings",
        description =
            "Adjust enchanting GMST settings.\n" ..
            "\n" ..
			"By default, a character with max stats has 11% chance to make full 225-point Constant Effect enchantment on Daedric Tower Shield.\n" ..
            "Use submit to push current slider values immediately.\n" ..
			"Hover over to see whats going on",
    }

    page:createSlider{
        label = "Enchant Chance Mult",		
		description =
		    "Enchant chance, higher - less chances\n" ..
			"\n" ..
			"Default = 0.5\n" ..
			"Vanilla = 3", 
        variable = createTableVar("enchantChanceMult"),
        min = 0.1, max = 5,
        step = 0.1, jump = 0.5, decimalPlaces = 1,
        defaultSetting = 0.5,
    }

    page:createSlider{
        label = "Constant Effect Chance Mult",
		description =
		    "How hard to enchant CE relative to the base enchant chance\n" ..
			"\n" ..
			"Higher makes Constant Effect enchants easier.\n" ..
            "Lower makes them harder.\n" ..
			"\n" ..
			"At 0.5, Constant Effect enchanting is twice as normal enchanting relative to the base chance setting.\n" ..
            "\n" ..
            "Default&Vanilla: 0.5",
        variable = createTableVar("constantChanceMult"),
        min = 0.1, max = 1,
        step = 0.1, jump = 0.1, decimalPlaces = 1,
        defaultSetting = 0.5,
    }

    page:createSlider{
        label = "Constant Effect Duration Mult",
		description =
		    "Controls how much enchant capacity Constant Effect enchantments consume.\n" ..
            "\n" ..
            "Higher make Constant Effect enchants take more space.\n" ..
            "Lower let more Constant Effect enchantment fit into the same item.\n" ..
            "\n" ..
            "Default&Vanilla: 100", 
        variable = createTableVar("constantDurationMult"),
        min = 1, max = 300,
        step = 1, jump = 10, 
        defaultSetting = 100.0,
    }

    page:createSlider{
        label = "Enchant Capacity Mult",
		description =
		    "Overall enchant capacity\n" ..
			"Higher = more capacity , lower = less\n" ..
			"\n" ..
			"Default&Vanilla: 0.1",
        variable = createTableVar("enchantMult"),
        min = 0.01, max = 1.00,
        step = 0.01, jump = 0.1, decimalPlaces = 2,
        defaultSetting = 0.1,
    }

    page:createSlider{
        label = "Enchant Value Mult",
		description =
		    "How much costs enchant by NPCs\n" ..
			"\n" ..
			"Default&Vanilla: 1000",
        variable = createTableVar("enchantValueMult"),
        min = 100, max = 2000,
        step = 50, jump = 100,
        defaultSetting = 1000,
    }

page:createInfo{
    text = "",
    postCreate = function(self)
        local parent = self.elements.outerContainer
        if not parent then
            return
        end

        -- Прячем пустой label этой строки
        if self.elements.label then
            self.elements.label.visible = false
            self.elements.label.width = 0
            self.elements.label.height = 0
        end

        -- Убираем лишние отступы у самой строки
        parent.paddingTop = 0
        parent.paddingBottom = 0
        parent.borderTop = 0
        parent.borderBottom = 0
        parent.autoHeight = true

        local row = parent:createBlock({})
        row.flowDirection = "left_to_right"
        row.widthProportional = 1.0
        row.autoHeight = true
        row.paddingTop = 0
        row.paddingBottom = 0
        row.childAlignX = 0.0

        local applyBtn = row:createButton({ text = "Submit" })
        applyBtn.paddingLeft = 8
        applyBtn.paddingRight = 8
        applyBtn:register("mouseClick", function()
            mwse.saveConfig("sanekEnchant", config)
            interop.applyGMST()
            template:clickTab(page)
        end)

        

        local defaultsBtn = row:createButton({ text = "Default" })
        defaultsBtn.paddingLeft = 8
        defaultsBtn.paddingRight = 8
        defaultsBtn.borderLeft = 8
        defaultsBtn:register("mouseClick", function()
            interop.restoreDefaults()
            template:clickTab(page)
        end)
		
		
		
		local vanillaBtn = row:createButton({ text = "Vanilla" })
        vanillaBtn.paddingLeft = 8
        vanillaBtn.paddingRight = 8
        vanillaBtn.borderLeft = 8
        vanillaBtn:register("mouseClick", function()
            interop.restoreVanilla()
            template:clickTab(page)
        end)
    end,
}

    return page
end

local template = mwse.mcm.createTemplate("sanekEnchant")
template:saveOnClose("sanekEnchant", config)

createPage(template)

mwse.mcm.register(template)