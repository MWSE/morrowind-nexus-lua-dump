local rules = require("animationBlending.rules")

local tests = require("unitwind").new({
    enabled = true,
    exitAfter = true,
})

-- print("\x1b[2J\x1b[H")

tests:start("animationBlending")

tests:test("rules: case-insensitive", function()
    tests:expect(rules.matches("IDLE", "idle")).toBe(true)
    tests:expect(rules.matches("idle", "IDLE")).toBe(true)
end)

tests:test("rules: direct matches", function()
    tests:expect(rules.matches("Idle", "Idle")).toBe(true)
    tests:expect(rules.matches("Idle", "Jump")).toBe(false)

    tests:expect(rules.matches("WalkBack", "Walk")).toBe(false)
    tests:expect(rules.matches("WalkBack", "Back")).toBe(false)

    tests:expect(rules.matches("SwimWalkBack", "Swim")).toBe(false)
    tests:expect(rules.matches("SwimWalkBack", "Walk")).toBe(false)
    tests:expect(rules.matches("SwimWalkBack", "Back")).toBe(false)
end)

tests:test("rules: global wildcard", function()
    tests:expect(rules.matches("Idle", "*")).toBe(true)
    tests:expect(rules.matches("Idle", "*:")).toBe(true)
    tests:expect(rules.matches("Idle", "*:*")).toBe(true)
end)

tests:test("rules: prefix wildcard", function()
    tests:expect(rules.matches("WalkBack", "*Back")).toBe(true)
    tests:expect(rules.matches("WalkBack", "*Left")).toBe(false)
end)

tests:test("rules: suffix wildcard", function()
    tests:expect(rules.matches("WalkBack", "Walk*")).toBe(true)
    tests:expect(rules.matches("WalkBack", "Run*")).toBe(false)
end)

tests:test("rules: double wildcard", function()
    tests:expect(rules.matches("SwimWalkBack", "*Walk*")).toBe(true)
    tests:expect(rules.matches("SwimWalkBack", "*Run*")).toBe(false)
end)

tests:test("rules: empty group", function()
    tests:expect(rules.matches("idle", "")).toBe(false)
    tests:expect(rules.matches("idle", ":")).toBe(false)
    tests:expect(rules.matches("idle", ":*")).toBe(false)
end)

tests:finish()
