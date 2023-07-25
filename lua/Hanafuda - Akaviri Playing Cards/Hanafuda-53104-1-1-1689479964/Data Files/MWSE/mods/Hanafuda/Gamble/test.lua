do

    ---@param num integer
    ---@param value any
    ---@return table
    local function Repeat(num, value)
        local t = table.new(num, 0)
        for i = 1, num do
            -- table -> deepcopy?
            -- function call
            table.insert(t, value)
        end
        return t
    end

    local unitwind = require("unitwind").new({
        enabled = true,
        highlight = false,
    })
    unitwind:start("Koi-Koi Gamble Test")

    unitwind:test("CalculateAbility Zero", function()
        local settings = require("Hanafuda.Gamble.settings")
        ---@type Gamble.Ability
        local ability = {}
        do
            ---@type tes3mobileCreature
            local mobile = {
                attributes = Repeat(table.size(tes3.attribute), {current = 0}),
            }
            unitwind:expect(settings.CalculateAbility(mobile, ability)).toBe(0)
        end
        do
            ---@type tes3mobileNPC
            local mobile = {
                attributes = Repeat(table.size(tes3.attribute), {current = 0}),
                skills = Repeat(table.size(tes3.skill), {current = 0}),
            }
            unitwind:expect(settings.CalculateAbility(mobile, ability)).toBe(0)
        end
    end)

    unitwind:finish()
end
