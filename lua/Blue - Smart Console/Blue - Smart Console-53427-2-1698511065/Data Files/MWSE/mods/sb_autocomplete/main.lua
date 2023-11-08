local mcm = require("sb_autocomplete.mcm")
local interop = require("sb_autocomplete.interop")

---@type tes3uiElement
local console
---@type tes3uiElement
local consoleSuggest
---@type number
local suggestionIndex
---@type string[]
local suggestions
---@type string
local lastSuggestion
---@type string
local prefix

---@param text string
---@param consoleMode string
local function tryFindCommand(text, consoleMode)
    local splitText = text:gsub("^%s*\"?[%S]+\"?->", ""):nonTrimSplit()
    prefix = console.text:match("^%s*\"?[%S]+\"?->") or ""
    table.clear(suggestions)

    if (#splitText == 0) then
        return
    end

    -- for key, value in pairs(mc_data.commands) do
    --     print(key)
    -- end

    if (#splitText > 1) then
        if (splitText[1]:len() >= mcm["settings"].minChar) then
            for command, params in pairs(interop.paramConfig[consoleMode]) do
                if (splitText[1]:lower() == command:lower()) then
                    if (#params == 1 and text:gsub(prefix .. splitText[1] .. " ", ""):gsub("\"", ""):lower():len() >= mcm["settings"].minChar) then
                        suggestions = params[1](text:gsub(prefix .. splitText[1] .. " ", ""):gsub("\"", ""):lower(),
                            selectOrGetReference(text))
                    else
                        for index, param in ipairs(params) do
                            if (param ~= "" and index + 1 == #splitText and splitText[index + 1] ~= nil and splitText[index + 1]:gsub("\"", ""):len() >= mcm["settings"].minChar) then
                                suggestions = param(splitText[index + 1]:gsub("\"", ""):lower(),
                                    selectOrGetReference(text))
                                break
                            end
                        end
                    end
                    break
                end
            end

            for key, value in ipairs(suggestions) do
                suggestions[key] = text:gsub(text:gsub(prefix .. splitText[1] .. " ", ""), value)
            end
        end
    else
        if (splitText[1]:len() >= mcm["settings"].minChar) then
            local midSuggestions = {}

            for index, command in ipairs(interop.commands[consoleMode]) do
                if (command:lower():startswith(splitText[1]:gsub("\"", ""):lower())) then
                    table.insert(suggestions, command)
                elseif (command:lower():contains(splitText[1]:gsub("\"", ""):lower())) then
                    table.insert(midSuggestions, command)
                end
            end

            for index, value in ipairs(midSuggestions) do
                table.insert(suggestions, value)
            end
        end
    end

    -- if (consoleMode == "mwscript" and data) then
    --     if (#splitText > 1) then
    --         if (#splitText == 2) then
    --             if (splitText[1] == "additem") then
    --                 suggestions = data.suggestItem(splitText[2])
    --             elseif (splitText[1] == "addsoulgem") then
    --                 suggestions = data.suggestSoulGem(splitText[2])
    --             elseif (splitText[1] == "addspell") then
    --                 suggestions = data.suggestSpell(splitText[2])
    --             elseif (splitText[1] == "cast") then
    --                 suggestions = data.suggestSpell(splitText[2])
    --             end
    --         elseif (#splitText > 2) then
    --             if (splitText[1] == "addspell") then
    --                 suggestions = data.suggestSpell(splitText[2])
    --             end
    --         end

    --         for key, value in ipairs(suggestions) do
    --             suggestions[key] = splitText[1] .. " " .. value
    --         end
    --     else
    --         local midSuggestions = {}

    --         for index, value in ipairs(data.commands) do
    --             if (value:match("^" .. splitText[1])) then
    --                 table.insert(suggestions, value)
    --             elseif (value:match(splitText[1])) then
    --                 table.insert(midSuggestions, value)
    --             end
    --         end

    --         for index, value in ipairs(midSuggestions) do
    --             table.insert(suggestions, value)
    --         end
    --     end
    -- elseif (consoleMode == "lua") then
    --     if (#splitText > 1) then
    --         if (#splitText == 2) then
    --             if (splitText[1] == "addall") then
    --                 suggestions = data_mcc.suggestObjectType(splitText[2])
    --             elseif (splitText[1] == "additem") then
    --                 suggestions = data_mcc.suggestItem(splitText[2])
    --             elseif (splitText[1] == "addone") then
    --                 suggestions = data_mcc.suggestObjectType(splitText[2])
    --             elseif (splitText[1] == "coc") then
    --                 suggestions = data_mcc.suggestCell(splitText[2])
    --             elseif (splitText[1] == "join") then
    --                 suggestions = data_mcc.suggestFaction(splitText[2])
    --             elseif (splitText[1] == "levelup") then
    --                 suggestions = data_mcc.suggestSkill(splitText[2])
    --             elseif (splitText[1] == "position") then
    --                 suggestions = data_mcc.suggestNPC(splitText[2])
    --             elseif (splitText[1] == "recall") then
    --                 suggestions = data_mcc.suggestMark(splitText[2])
    --             elseif (splitText[1] == "set") then
    --                 suggestions = data_mcc.suggestAttribute(splitText[2])
    --             elseif (splitText[1] == "spawn") then
    --                 suggestions = data_mcc.suggestObjects(splitText[2])
    --             elseif (splitText[1] == "weather") then
    --                 suggestions = data_mcc.suggestWeather(splitText[2])
    --             end
    --         elseif (#splitText > 2) then
    --             if (splitText[1] == "coc") then
    --                 suggestions = data_mcc.suggestCell(text:lower():gsub(splitText[1], ""))
    --             end
    --         end

    --         for key, value in ipairs(suggestions) do
    --             suggestions[key] = splitText[1] .. " " .. value
    --         end
    --     else
    --         local midSuggestions = {}

    --         for key, value in pairs(mcc_data.commands) do
    --             if (key:match("^" .. splitText[1])) then
    --                 table.insert(suggestions, key)
    --             elseif (key:match(splitText[1])) then
    --                 table.insert(midSuggestions, key)
    --             end
    --         end

    --         for index, value in ipairs(midSuggestions) do
    --             table.insert(suggestions, value)
    --         end
    --     end
    -- end
end

--- @param e uiActivatedEventData
local function onMenuConsoleActivated(e)
    if (e.newlyCreated) then
        console = e.element:findChild("UIEXP:ConsoleInputBox")
        consoleSuggest = e.element:findChild("PartDragMenu_main"):createLabel {
            id = "sb_auto"
        }
        consoleSuggest.text = ""
        consoleSuggest.autoWidth = true
        consoleSuggest.autoHeight = true
        e.element:findChild("PartDragMenu_main"):reorderChildren(1, 2, 1)
        e.element:findChild("PartDragMenu_main"):updateLayout()
    end

    if (console) then
        suggestionIndex = 0
        suggestions = {}
        console:registerAfter("keyPress", function(k)
            -- if (console.text:len() < mcm["settings"].minChar) then
            --     return
            -- end
            mwse.log("BLUE - %s", json.encode(k))
            local key = k.data0
            local keyStates = tes3.worldController.inputController.keyboardState
            local isShiftDown = tes3.worldController.inputController:isShiftDown()
            local isControlDown = tes3.worldController.inputController:isControlDown()
            local isAltDown = tes3.worldController.inputController:isAltDown()
            local fillKey = mcm["settings"]["fillKey"]
            local shouldFill = keyStates[fillKey["keyCode"] + 1] > 0 and isShiftDown == fillKey["isShiftDown"] and
                isControlDown == fillKey["isControlDown"] and isAltDown == fillKey["isAltDown"]
            local consoleMode = console.parent.parent:findChild("PartButton_text_ptr").text

            -- debug.log(console.text)
            if (shouldFill == false) then
                if (suggestionIndex > 0) then
                    lastSuggestion = suggestions[suggestionIndex]
                end
                tryFindCommand(suggestionIndex == 0 and console.text or lastSuggestion or suggestions[suggestionIndex],
                    consoleMode)
                -- debug.log("######## Before")
                -- debug.log(#suggestions)
                -- debug.log(json.encode(suggestions))
                -- debug.log(suggestionIndex)
            end
            if (#suggestions > 0) then
                if (shouldFill) then
                    suggestionIndex = suggestionIndex + 1
                    if (suggestionIndex > #suggestions) then
                        suggestionIndex = 1
                    end
                    console.text = prefix .. suggestions[suggestionIndex]
                    consoleSuggest.text = "Suggestions (" ..
                        (suggestionIndex == 0 and 1 or suggestionIndex) ..
                        "/" ..
                        #suggestions ..
                        "): " ..
                        (mcm["settings"]["sugType"] == 2 and suggestions[suggestionIndex]:gsub(" \"", "\xE000\""):split("\xE000")[2] or prefix .. suggestions[suggestionIndex])
                elseif (suggestionIndex > 0) then
                    console.text = prefix ..
                        (#suggestions > 0 and suggestions[suggestionIndex] or lastSuggestion) ..
                        (string.char(key) .. "|")
                    consoleSuggest.text = ""
                    suggestionIndex = 0
                else
                    consoleSuggest.text = "Suggestions (" ..
                        (suggestionIndex == 0 and 1 or suggestionIndex) ..
                        "/" ..
                        #suggestions ..
                        "): " ..
                        (mcm["settings"]["sugType"] == 2 and suggestions[1]:gsub(" \"", "\xE000\""):split("\xE000")[2] or prefix .. suggestions[1])
                end
            else
                consoleSuggest.text = ""
            end

            -- debug.log("######## After")
            -- debug.log(console.text)
        end)
    end
end

event.register("initialized",
    function()
        event.register("uiActivated", onMenuConsoleActivated, { filter = "MenuConsole", priority = -9999 })
        require("sb_autocomplete.utils")
        require("sb_autocomplete.commands")
        mcm.init()
    end,
    { priority = -999 })
event.register("UIEXP:consoleCommand", function(e)
    consoleSuggest.text = ""
    suggestionIndex = 0
end)
