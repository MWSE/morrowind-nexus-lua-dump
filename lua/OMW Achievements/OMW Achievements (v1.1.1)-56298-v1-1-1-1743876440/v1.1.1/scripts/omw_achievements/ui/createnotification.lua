local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local v2 = util.vector2
local core = require('openmw.core')
local l10n = core.l10n('OmwAchievements')

local storage = require('openmw.storage')
local playerSettings = storage.playerSection('SettingsPlayerOmwAchievements')

local notification = {}

function notification.createnotification(icon_path, achName, achDescription, bg)

    if playerSettings:get('notification_position') == "right_top" then
        notificationPosition = v2(.97, .03)
    elseif playerSettings:get('notification_position') == "left_top" then
        notificationPosition = v2(.27, .03)
    elseif playerSettings:get('notification_position') == "right_bottom" then
        notificationPosition = v2(.97, .65)
    elseif playerSettings:get('notification_position') == "left_bottom" then
        notificationPosition = v2(.27, .65)
    elseif playerSettings:get('notification_position') == "center_bottom" then
        notificationPosition = v2(.63, .70)
    elseif playerSettings:get('notification_position') == "center_top" then
        notificationPosition = v2(.63, .04)
    end

    local screenSize = ui.screenSize()
    local icon_size = screenSize.y * 0.05
    local width_ratio = 0.19
    local widget_width = screenSize.x * width_ratio
    local widget_height = icon_size * 1.8

    if bg ~= nil then
        if bg == "red" then
            icon_bg = "Icons\\MAC\\icnBackgroundGet_Red.tga"
        elseif bg == "yellow" then
            icon_bg = "Icons\\MAC\\icnBackgroundGet_Yellow.tga"
        elseif bg == "green" then
            icon_bg = "Icons\\MAC\\icnBackgroundGet_Green.tga"
        elseif bg == "aqua" then
            icon_bg = "Icons\\MAC\\icnBackgroundGet_Aqua.tga"
        elseif bg == "blue" then
            icon_bg = "Icons\\MAC\\icnBackgroundGet_Blue.tga"
        elseif bg == "purple" then
            icon_bg = "Icons\\MAC\\icnBackgroundGet_Purple.tga"
        end
    else
        icon_bg = "Icons\\MAC\\icnBackgroundGet.tga"
    end

    local getTextSize = (screenSize.x * 0.01)
    local nameTextSize = (screenSize.x * 0.008)
    local descriptionTextSize = (screenSize.x * 0.008)

    local achievementLogo = {
        type = ui.TYPE.Image,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            size = v2(icon_size, icon_size),
            resource = ui.texture { path = icon_path },
            color = util.color.hex("000000")
        }
    }

    local achievementLogoBackground = {
        type = ui.TYPE.Image,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5),
            size = v2(icon_size, icon_size),
            resource = ui.texture { path = icon_bg }
        }
    }

    local achievementLogoBox = {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            size = v2(icon_size, icon_size)
        },
        content = ui.content {
            achievementLogoBackground,
            achievementLogo
        }
    }

    local achievementGetText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = l10n('notification_text'),
            textSize = getTextSize
        }
    }

    local achievementNameText = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = achName,
            textSize = nameTextSize
        }
    }

    local achievementDescriptionText = {
        type = ui.TYPE.Text,
        props = {
            text = achDescription,
            autoSize = false,
            textSize = descriptionTextSize,
            size = v2((widget_width - icon_size - 7), descriptionTextSize*2),
            multiline = true,
            wordWrap = true,
            textColor = util.color.hex("cccccc")
        }
    }

    local achievementDescriptionTextBox = {
        type = ui.TYPE.Widget,
        props = {
            template = I.MWUI.templates.borders,
            anchor = v2(0, 0),
            position = v2(0, 0),
            size = v2((widget_width - icon_size - 7), descriptionTextSize*2)
        },
        content = ui.content({achievementDescriptionText})
    }

    local emptyHBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(300, 6)
        }
    }

    local emptyVBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(7, 80)
        }
    }

    local achievementText = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            relativePosition = v2(0, 0),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Start
        },
        content = ui.content {
            achievementGetText,
            emptyHBox,
            achievementNameText,
            emptyHBox,
            achievementDescriptionTextBox
        }
    }

    local achievement = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            size = v2(widget_width, widget_height),
            anchor = v2(0, 0),
            relativePosition = v2(.01, .01),
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content(
            {achievementLogoBox,
            emptyVBox,
            achievementText}
        )
    }

    local achievementNotificationBox = {
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(0, 0),
            relativePosition = v2(0, 0),
            size = v2(widget_width, widget_height)
        },
        content = ui.content({achievement})
    }

    local achievementNotificationContainer = {
        type = ui.TYPE.Container,
        layer = "Notification",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            anchor = v2(1, 0),
            relativePosition = notificationPosition
        },
        content = ui.content({achievementNotificationBox})
    }

    achievementNotification = ui.create(achievementNotificationContainer)

end

return notification