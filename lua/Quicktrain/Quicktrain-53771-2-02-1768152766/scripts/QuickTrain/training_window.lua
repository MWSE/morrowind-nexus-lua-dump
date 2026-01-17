local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")
local input = require("openmw.input")
local barterHelp = require("scripts.QuickTrain.barterhelp")
local winSize = util.vector2(500, 400)
local skills = {}
local storage = require('openmw.storage')
local bms = core.contentFiles.has("bms.omwscripts")
local skillData = {}
local lastActivatedActor
local trainingWindow
local controllerMode = false
local function textContent(text, template, color)
    local tsize = 15
    if not color then
        template = I.MWUI.templates.textNormal
        color = template.props.textColor
    elseif color == "red" then
        template = I.MWUI.templates.textNormal
        color = util.color.rgba(5, 0, 0, 1)
    else
        template = I.MWUI.templates.textHeader
        color = template.props.textColor
        --  tsize = 20
    end

    return {
        type = ui.TYPE.Text,
        template = template,
        props = {
            text = tostring(text),
            textSize = tsize,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            textColor = color
        }
    }
end
local function closeWindow(closeInterface)
    if trainingWindow then
        trainingWindow:destroy()
        trainingWindow = nil
        if closeInterface then
            I.UI.setMode()
        end
    end
end
local settings = storage.playerSection("SettingsQuicktrain")
local function buttonClick()

end
local function textButtonContent(text, template, color)
    local resource2Table = {}
    local resource3Table = {}


    local ret = {
        alignment = ui.ALIGNMENT.Center,

        props = {

            --size = size * 1.05,
            --num = num,
        },
        events = { mouseClick = async:callback(buttonClick)
        },
        content = ui.content {

            {
                type = ui.TYPE.Text,
                props = {
                    text = text,
                    --  relativeSize = util.vector2(0.2, 0.2)
                }
            }
        }
    }
    ret.template = I.MWUI.templates.bordersThick
    return ret
end


local function flexedItems(content, horizontal)
    if not horizontal then
        horizontal = false
    end
    return ui.content {
        {
            type = ui.TYPE.Flex,
            content = ui.content(content),
            events = {
                --   mouseMove = async:callback(mouseMove),
            },
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
                --     size = util.vector2(100, 100),
                autosize = true
            }
        }
    }
end
local peroid = 0.2
local function clickSkill(skillId)
    local data = skillData[skillId]
    if data.actorLevel <= data.playerLevel then
        ambient.playSound("menu click")
        ui.showMessage(core.getGMST("sServiceTrainingWords"))
        return
    end
    if data.playerGold < data.price then
        ambient.playSound("menu click")
        return
    end
    if data.attributeUnderSkill then
        ui.showMessage(core.getGMST("sNotifyMessage17"))
        return
    else
        I.QT_Fade.fade(peroid, peroid, peroid)
        local string = core.getGMST("sNotifyMessage39")
        local newLevel = data.playerLevel + 1
        local skillName = data.skillName
        local cost = data.price
        local actorFaction = data.actorFaction
        local paid = false
        if actorFaction and I.FactionBankData then
            local balance = I.FactionBankData.getBankBalance(actorFaction)
            if balance > cost then
                paid = true
                I.FactionBankData.reduceBalance(actorFaction, cost)
            end
        end
        if not paid then
            core.sendGlobalEvent("reducePlayerGold", cost)
        end
        -- ui.showMessage(string.format(string,skillName,newLevel))
        I.SkillProgression.skillLevelUp(data.id, I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer)
        core.sendGlobalEvent("QT_waitHours",2)
        closeWindow(true)
    end
    ambient.playSound("skillraise")
end
local imageClick = function(mouseEvent, data)
    -- --print("Clicked button", data.props.num, skills[data.props.num])
    clickSkill(skills[data.props.num])
end
local function imageContent(resource, size, resource2, boxed, num, resource3)
    local resource2Table = {}
    local resource3Table = {}

    if resource2 then
        resource2Table = {
            type = ui.TYPE.Image,
            props = {
                resource = resource2,
                size = size,
                --  relativeSize = util.vector2(0.2, 0.2)
            }
        }
    end
    if resource3 then
        resource3Table = {
            type = ui.TYPE.Image,
            props = {
                resource = resource3,
                size = util.vector2(25, 25),
                relativePosition = util.vector2(1, 1),
                anchor = util.vector2(1, 1)
            }
        }
    end
    local ret = {
        alignment = ui.ALIGNMENT.Center,

        props = {

            size = size * 1.05,
            num = num,
        },
        content = ui.content {
            resource2Table,

            {
                type = ui.TYPE.Image,
                props = {
                    resource = resource,
                    size = size,
                    --  relativeSize = util.vector2(0.2, 0.2)
                }
            },
            resource3Table
        }
    }
    if boxed then
        ret.events = {
            mouseClick = async:callback(imageClick)
        }
        ret.template = I.MWUI.templates.box
    end
    return ret
end
local function replace_extension(filename, new_extension)
    -- Check if the filename contains a period
    if filename:find("%.") then
        -- Replace everything after the last period with the new extension
        return filename:gsub("%.[^%.]+$", "." .. new_extension)
    else
        -- If there's no period, just append the new extension
        return filename .. "." .. new_extension
    end
end
local function get_filename_from_path(path)
    -- Match everything after the last slash or backslash
    return path:match("([^/\\]+)$") or path
end
local function renderItemBoxed(item, bold)
    return
    {
        template = I.MWUI.templates.borders,
        alignment = ui.ALIGNMENT.Center,
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textHeader,
                props = {
                    text = item,
                    textSize = 10,
                    -- relativePosition = v2(0.5, 0.5),
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                }
            }
        }
    }
end
local function get_expertise_level(skill)
    -- Expertise levels mapped to keys
    local expertise_levels = {
        "Novice",     -- Level 1
        "Apprentice", -- Level 2
        "Journeyman", -- Level 3
        "Expert",     -- Level 4
        "Master"      -- Level 5
    }

    -- Loop through levels in descending order
    for i = 4, 0, -1 do
        if skill >= 25 * i then
            return expertise_levels[i + 1]
        end
    end

    -- If no match, default to novice
    return expertise_levels[1]
end
local function get_part_before_underscore(str)
    -- Match everything before the first underscore
    return str:match("^[^_]+") or str
end
local buttons = { "A", "X", "Y" }
local openTime
local function getAttributeMultipler(attributeId)
    local currentLevel = types.Actor.stats.attributes[attributeId](self).base
    local multipler = math.floor(types.Actor.stats.level(self).skillIncreasesForAttribute[attributeId] / 2)
    if multipler == 0 then
        multipler = 1
    elseif multipler > 5 then
        multipler = 5
    end
    
    if currentLevel + multipler > 100 then
        return 1
    end
    --print(multipler)
    return multipler
end
local function showWindow(actor)
    skillData = {}
    local data = I.TrainingLog.getTrainerData(actor)
    local columns = {}
    openTime = core.getRealTime()
    I.UI.setMode("Interface", { windows = {} })
    local actorFaction = types.NPC.getFactions(actor)[1]
    local playerGold = types.Actor.inventory(self):countOf("gold_001")
    local actorName = types.NPC.records[actor.recordId].name
    if actorFaction and I.FactionBankData then
        playerGold = playerGold + I.FactionBankData.getBankBalance(actorFaction)
    end
    table.insert(columns, {
        type = ui.TYPE.Flex,
        content = ui.content({

        }),
        props = {
            horizontal = false,
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
            size = util.vector2(50, 150),
        }
    })
    for i = 1, 3, 1 do
        local skillRecord = core.stats.Skill.records[data[i].id]
        local actorLevel = types.NPC.stats.skills[skillRecord.id](actor).base
        local playerLevel = types.NPC.stats.skills[skillRecord.id](self).base
        local attribute = core.stats.Attribute.records[skillRecord.attribute]
        local playerAttributeLevel = types.Actor.stats.attributes[attribute.id](self).base
        local attributeUnderSkill = playerAttributeLevel <= playerLevel
        skills[i] = skillRecord.id
        local iconPath = skillRecord.icon
        local multipler =getAttributeMultipler(attribute.id)
        iconPath = replace_extension(iconPath, "tga")
        iconPath = get_filename_from_path(iconPath)
        local fileName = iconPath
        iconPath = "icons\\quicktrain\\ui_exp\\rfd\\" .. iconPath
        --print(iconPath)
        local resource = ui.texture { -- texture in the top left corner of the atlas
            path = iconPath

        }
        local skillPart = get_part_before_underscore(fileName)
        --print(skillPart)
        local bresource = ui.texture { -- texture in the top left corner of the atlas
            path = "icons\\quicktrain\\ui_exp\\ui_exp\\skillbg_" .. skillPart .. ".dds"

        }
        local buttonresource 
        
        
        if controllerMode then
            buttonresource= ui.texture { -- texture in the top left corner of the atlas
            path = "icons\\quicktrain\\abxy\\button_xbox_digital_" .. buttons[i] .. "_3.png"

        }
        end
        local image = imageContent(resource, util.vector2(140, 140), bresource, true, i, buttonresource)
        --local image2 = imageContent(buttonresource, util.vector2(25, 25))
        local price = barterHelp.getTrainingPrice(actor, skillRecord.id)
        skillData[skillRecord.id] = {
            id = skillRecord.id,
            actorLevel = actorLevel,
            playerLevel = playerLevel,
            playerGold = playerGold,
            price = price,
            actorFaction = actorFaction,
            attribute = attribute.id,
            attributeUnderSkill = attributeUnderSkill,
            skillName = skillRecord.name
        }
        local trainSkill = get_expertise_level(actorLevel)
        local trainTo = "Train to Level " .. tostring(playerLevel + 1)
        if playerLevel >= actorLevel then
            trainTo ="You exceed " ..actorName .. "'s skill."
        end
        if attributeUnderSkill then
            
            trainTo = attribute.name .. " too low."
        end
        if playerLevel >= 100 then
            trainTo = "Skill Maxed"
        end
        local attributeCurrent = 
        table.insert(columns,
            {
                type = ui.TYPE.Flex,
                content = ui.content({
                    image,
                    --  image2,
                    textContent(skillRecord.name),
                    -- textContent("Can train to " .. tostring(actorLevel)),
                    textContent(attribute.name .. "(" .. tostring(multipler) .. "x)" ),
                    textContent(attribute.name .. ": " ..playerAttributeLevel ),
                    textContent(trainSkill .. " Trainer"),
                    textContent(""),
                    textContent(trainTo),
                    textContent(""),
                    textContent(tostring(price) .. " gp"),

                }),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = util.vector2(150, 150),
                }
            }

        )
        if (i < 3 ) or true then
            
        table.insert(columns, {
            type = ui.TYPE.Flex,
            content = ui.content({

            }),
            props = {
                horizontal = false,
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
                size = util.vector2(50, 150),
            }
        })
        end
    end
    local cancelButton = textButtonContent("Close")
    local content      = {}
    local headerText   = textContent("Select skill to train", true,"ASD")
    table.insert(content, headerText)
    local goldText = textContent("Gold: " .. tostring(playerGold) .. " gp")

    trainingWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick
        ,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            size = winSize,
            horizontal = true,
        },
        content =
            flexedItems({
                textContent(""),
                cancelButton,
                headerText,
                {
                    type = ui.TYPE.Flex,
                    content = flexedItems(columns, true),
                    props = {
                        horizontal = true,
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                        size = winSize,
                    }
                },

                -- flexedItems({ g }, true)
                goldText, cancelButton
            }, false)

    }
    return trainingWindow
end
if settings:get("enableTrainingUIReplace") == true and not bms then
    I.UI.registerWindow("Training",
        function(x, y)
            -- --print(x,y)
            --if lastActivatedActor then
            showWindow(lastActivatedActor)
            -- end
        end,

        function()
            --   closeWindow()
        end
    )
end
return {
    eventHandlers = {
        UiModeChanged = function(data)
            if data and data.arg and data.arg then
                lastActivatedActor = data.arg
            end
            if not data.newMode then
                closeWindow()
            end
        end
    },
    engineHandlers = {
        onControllerButtonPress = function(ctrl)
            controllerMode = true
            if trainingWindow then
                if ctrl == input.CONTROLLER_BUTTON.B then
                    I.Quicktrain_Main.skipNext()
                end
                if core.getRealTime() - openTime < 0.5 then
                    return
                end
                if ctrl == input.CONTROLLER_BUTTON.A then
                    local skillId = skills[1]
                    if skillId then
                        clickSkill(skillId)
                    end
                elseif ctrl == input.CONTROLLER_BUTTON.X then
                    local skillId = skills[2]
                    if skillId then
                        clickSkill(skillId)
                    end
                elseif ctrl == input.CONTROLLER_BUTTON.Y then
                    local skillId = skills[3]
                    if skillId then
                        clickSkill(skillId)
                    end
                end
            end
        end,
        onKeyPress = function(key)
            if not lastActivatedActor then
                return
            end
            controllerMode = false
            local isExpelled = false
            if lastActivatedActor.type == types.NPC and lastActivatedActor and types.NPC.getFactions(lastActivatedActor)[1] then
                local amInFaction = false
                local fact = types.NPC.getFactions(lastActivatedActor)[1] 
                for i,x in ipairs(types.NPC.getFactions(self)) do
                    if x == fact then
                        amInFaction = true
                        isExpelled = types.NPC.isExpelled(self,fact)
                    end
                end
            end 
            if trainingWindow then
                if key.code == input.KEY._1 then
                    local skillId = skills[1]
                    if skillId then
                        clickSkill(skillId)
                    end
                elseif key.code == input.KEY._2 then
                    local skillId = skills[2]
                    if skillId then
                        clickSkill(skillId)
                    end
                elseif key.code == input.KEY._3 then
                    local skillId = skills[3]
                    if skillId then
                        clickSkill(skillId)
                    end
                elseif key.code == input.KEY.Escape then
                    I.Quicktrain_Main.skipNext()

                end
            elseif key.code == input.KEY.T and I.UI.getMode() == "Dialogue"  and lastActivatedActor and types.NPC.records[lastActivatedActor.recordId].servicesOffered["Training"] and I.TrainingLog.isTrainingData(lastActivatedActor) and not isExpelled then
                I.UI.setMode("Training",{target =lastActivatedActor })
            end
        end
    },
    --I.TrainingLog_TWin.showWindow()
    interfaceName = "TrainingLog_TWin",
    interface = {
        showWindow = showWindow,
    },
}
