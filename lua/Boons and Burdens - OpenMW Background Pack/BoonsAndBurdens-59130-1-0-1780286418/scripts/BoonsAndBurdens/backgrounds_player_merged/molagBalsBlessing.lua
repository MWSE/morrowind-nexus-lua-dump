---@omw-context player
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local I = require("openmw.interfaces")
local self = require("openmw.self")

I.CharacterTraits.addTrait {
    id = "BaB_molagBalsBlessing",
    type = "background",
    name = "Blessed by Molag Bal",
    description = (
        "In a moment of desperation - or ambition, or weakness - " ..
        "you made an offering at a shrine of Molag Bal. He accepted. " ..
        "Your magicka swelled and your grip on bound servants sharpened, " ..
        "but your body grew hollow, the tithe he demanded paid in flesh and endurance. " ..
        "Those who have walked beside you since bear a burden they never agreed to: " ..
        "the Prince of Domination has made them your shield, " ..
        "just as he makes all things serve the strong.\n" ..
        "\n" ..
        "+10 Conjuration\n" ..
        "+50 Max Magicka\n" ..
        "-20 Endurance\n" ..
        "-30 Max HP\n" ..
        "> All incoming melee attacks are redirected towards one of your random followers if you have any"
    ),
    doOnce = function()
        local conjuration = self.type.stats.skills.conjuration(self)
        conjuration.base = conjuration.base + 10
        local magicka = self.type.stats.dynamic.magicka(self)
        magicka.base = magicka.base + 50

        local endurance = self.type.stats.attributes.endurance(self)
        endurance.base = endurance.base - 20
        local health = self.type.stats.dynamic.health(self)
        health.base = health.base - 30
    end,
    onLoad = function()
        local followers = {}
        local indexedFollowers = {}
        I.Combat.addOnHitHandler(function(attack)
            if not attack or not attack.successful then return end

            followers = I.FollowerDetectionUtil.getFollowerList()
            for _, state in pairs(followers) do
                local followsMe = (state.leader and state.leader.id == self.id) or
                    (state.superLeader and state.superLeader.id == self.id)
                if followsMe then
                    indexedFollowers[#indexedFollowers + 1] = state.actor
                end
            end
            if #indexedFollowers == 0 then return end

            local newAttackTarget = indexedFollowers[math.random(#indexedFollowers)]
            newAttackTarget:sendEvent("Hit", attack)
            indexedFollowers = {}
            return false
        end)
    end
}
