local mod = "Hide the Skooma"
local version = "1.0"

-- Table of all INFO IDs for the contraband service refusal dialogues.
local dialogueId = {
    "2350820932343717228",
    "27431251821030328588",
    "745815156108126115",
    "1094918899840230767",
    "170686103927626649",
    "437731057154051750",
    "2456544071464426424",
    "781926249198433643",
    "27861296403221528233",
    "287378702993122269",
    "29036265711176618107",
    "2821782961190224094",
    "3576191201815529709",
    "3034922702178419782",
    "277125218205084722",
    "2797025664259225507",
}

-- Runs each time a dialogue info text is retrieved. So each time we click a dialogue topic or see a greeting.
local function onInfoGetText(e)
    local currentId = e.info.id
    local isRefusal = false

    -- Compare the INFO ID for this dialogue with the table above and look for a match.
    for _, tableId in ipairs(dialogueId) do
        if currentId == tableId then
            isRefusal = true
            break
        end
    end

    -- If there's no match, we don't care, do nothing.
    if isRefusal then

        -- Determine how many units of Moon Sugar and Skooma we have in inventory.
        local moonSugarCount = mwscript.getItemCount{
            reference = tes3.player,
            item = "ingred_moon_sugar_01",
        }

        local skoomaCount = mwscript.getItemCount{
            reference = tes3.player,
            item = "potion_skooma_01",
        }

        -- Remove the items from inventory so we can barter.
        if moonSugarCount > 0 then
            tes3.removeItem{
                reference = tes3.player,
                item = "ingred_moon_sugar_01",
                count = moonSugarCount,
                playSound = false,
            }
        end

        if skoomaCount > 0 then
            tes3.removeItem{
                reference = tes3.player,
                item = "potion_skooma_01",
                count = skoomaCount,
                playSound = false,
            }
        end

        -- Slightly delay this messagebox so it will appear below the service refusal text, not above.
        -- Using timer.real so it won't wait until we close the dialogue window.
        timer.start{
            type = timer.real,
            duration = 0.01,
            callback = function()
                tes3.messageBox("I don't know what you're talking about.\n(You quickly stash your drugs out of sight.)")
            end,
        }

        -- Re-add our items afterwards.
        -- Type defaults to timer.simulate, so it will wait until we close the dialogue window.
        timer.start{
            duration = 0.01,
            callback = function()
                if moonSugarCount > 0 then
                    tes3.addItem{
                        reference = tes3.player,
                        item = "ingred_moon_sugar_01",
                        count = moonSugarCount,
                        playSound = false,
                    }
                end

                if skoomaCount > 0 then
                    tes3.addItem{
                        reference = tes3.player,
                        item = "potion_skooma_01",
                        count = skoomaCount,
                        playSound = false,
                    }
                end
            end,
        }
    end
end

local function onInitialized()
    event.register("infoGetText", onInfoGetText)
    mwse.log("[" .. mod .. " " .. version .. "] Initialized.")
end

event.register("initialized", onInitialized)