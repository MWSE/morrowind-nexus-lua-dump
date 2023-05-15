local tatau = require("sb_tatau.interop")
local tattooList = require("sb_remi_tattoos.tattoos")
local crafting = require("CraftingFramework.interop")

---@type CraftingFramework.Recipe.data[]
local recipes = {}
local slotsRegistered = {}

for tatName, tat in pairs(tattooList) do
    table.insert(recipes, {
        id = "sb_tatrecipe_" .. tat.id,
        craftableId = tat.id,
        name = tatName,
        persist = false,
        noResult = true,
        craftCallback = function(self, e)
            local r = math.random(1, 3)
            tes3.messageBox(r == 1 and "Enjoy your new ink, muthsera." or
                r == 2 and "I like your new look." or
                "Thank you for your patronage.")

            timer.start {
                duration = 0.25,
                callback = function(e)
                    for _, oldTat in pairs(tattooList) do
                        if (oldTat.slot == tat.slot) then
                            if (tat.id == oldTat.id) then
                                tatau:applyTattoo(tes3.player, tat.id)
                            else
                                tatau:removeTattoo(tes3.player, oldTat.id)
                            end
                        end
                    end
                    tes3.player.data["sb_remi_tattoos"][tostring(tat.slot)] = tat.id
                end,
                persist = false
            }
        end,
        materials = {
            {
                material = "Gold_001",
                count = 100
            }
        },
        category = tatau.data.tattooSlots[tat.slot][1],
        previewImage = tat.icon or ("Textures\\" .. tat.mPaths[""])
    })
    slotsRegistered[tat.slot] = true
end

for slot, _ in pairs(slotsRegistered) do
    table.insert(recipes, {
        id = "sb_tatrecipe_remove",
        craftableId = "remove",
        name = "Remove Tattoo",
        persist = false,
        noResult = true,
        craftCallback = function(self, e)
            local r = math.random(1, 3)
            tes3.messageBox(r == 1 and "Maybe next time." or
                r == 2 and "Perhaps another?" or
                "I'm sorry it wasn't to your liking, muthsera.")

            timer.start {
                duration = 0.25,
                callback = function(e)
                    for _, oldTat in pairs(tattooList) do
                        if (oldTat.slot == slot) then
                            tatau:removeTattoo(tes3.player, oldTat.id)
                            tes3.player.data["sb_remi_tattoos"][tostring(oldTat.slot)] = nil
                        end
                    end
                end,
                persist = false
            }
        end,
        materials = {
            {
                material = "Gold_001",
                count = 50
            }
        },
        category = tatau.data.tattooSlots[slot][1]
    })
end

return recipes
