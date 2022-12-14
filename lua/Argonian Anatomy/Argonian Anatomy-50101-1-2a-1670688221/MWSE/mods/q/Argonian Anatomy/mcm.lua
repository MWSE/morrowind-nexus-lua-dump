local config = require("q.Argonian Anatomy.config")

local function newline(component)
	component:createInfo({ text = "\n" })
end

local function postFormat(self)
	self.elements.info.layoutOriginFractionX = 0.5
end

local function addSideBar(component)
	component.sidebar:createInfo({
		text = "\nWelcome to Argonian Anatomy!",
		postCreate = postFormat
	})
	component.sidebar:createHyperLink({
		text = "\nMade by Qwerty",
		exec = "start https://www.nexusmods.com/users/57788911?tab=user+files",
		postCreate = postFormat,
	})
	component.sidebar:createHyperLink({
		text = "\nCoding by C3pa",
		exec = "start https://www.nexusmods.com/users/37172285?tab=user+files",
		postCreate = postFormat
	})
    component.sidebar:createHyperLink({
		text = "\nHelp with animations by EJ-12",
		exec = "start https://www.nexusmods.com/morrowind/users/468930?tab=user+files",
		postCreate = postFormat
	})
end


local template = mwse.mcm.createTemplate({
	name = "Argonian Anatomy",
	headerImagePath = "MWSE/mods/q/Argonian Anatomy/Title.tga"
})
template:register()
template:saveOnClose("Argonian Anatomy", config)

do
    local settingsPage = template:createSideBarPage({ label = "Preferences" })
    addSideBar(settingsPage)
    settingsPage.noScroll = true

    newline(settingsPage)
    settingsPage:createCategory({ label = "Which races should have new skeleton?" })

    newline(settingsPage)
    settingsPage:createOnOffButton({
        label = "The Argonians",
        description = "This will enable new skeleton for all members of the Argonian race.",
        variable = mwse.mcm.createTableVariable({
            id = "argonian",
            table = config,
            restartRequired = true,
        })
    })

    newline(settingsPage)
    settingsPage:createOnOffButton({
        label = "The Naga Breed",
        description = "This will enable new skeleton for all members of the Naga Breed mod.",
        variable = mwse.mcm.createTableVariable({
            id = "godzilla",
            table = config,
            restartRequired = true,
        })
    })

    newline(settingsPage)
    settingsPage:createOnOffButton({
        label = "The Shadowscales",
        description = "This will enable new skeleton for the Shadowscales mod.",
        variable = mwse.mcm.createTableVariable({
            id = "shadowscale",
            table = config,
            restartRequired = true,
        })
    })
end
