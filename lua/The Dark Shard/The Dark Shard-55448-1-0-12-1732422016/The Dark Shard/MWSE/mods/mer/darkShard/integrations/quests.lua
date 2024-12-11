local Quest = require("mer.darkShard.components.Quest")
local quests = {
    {
        id = "afq_main",
        stages = {
            notStarted = 0,
            falling = 1,
            findComet = 10,
            seesComet = 20,
            startTriangulation = 30,
            toShard = 40,
            finale = 99,
            finished = 100
        }
    },
    {
        id = "afq_up_triangle",
        stages = {
            notStarted = 0,
            triangulationComplete = 90,
            finished = 100
        }
    },
    {
        id = "afq_cult",
        stages = {
            notStarted = 0,
            addNote = 25,
            finished = 100
        }
    }
}

---@class Quest.quests.afq_main : DarkShard.Quest
---@field stages { notStarted:0, falling:1, findComet:10, seesComet:20, startTriangulation:30, toShard:40, finale:99, finished:100 }

---@class Quest.quests.afq_up_triangle : DarkShard.Quest
---@field stages { notStarted:0, triangulationComplete:90, finished:100 }

---@class Quest.quests.afq_cult : DarkShard.Quest
---@field stages { notStarted:0, addNote:25, finished:100 }

---@class Quest.quests
---@field afq_main Quest.quests.afq_main
---@field afq_up_triangle Quest.quests.afq_up_triangle
---@field afq_cult Quest.quests.afq_cult


for _, data in ipairs(quests) do
    Quest.register(data)
end