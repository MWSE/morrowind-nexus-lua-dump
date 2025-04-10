KRL_CONFIG = {
    buffRoomChance = 5, -- % chance the next room will be the Buff room.
    debuffRoomChance = 5, -- % chance the next room will be the Debuff room.
    minimumRoomsUntilShop = 4, -- lowest possible roll for how many rooms you must exit until the shop island.
    maximumRoomsUntilShop = 8, -- highest possible roll for how many rooms you must exit until the shop island.
    maxRoomLevel = 10, -- Max room level until final boss.
    roomsUntilBoss = 3, -- How many normal rooms you must go through before fighting a boss.
    baseDifficulty = 0, -- The base difficulty. This value is added to the difficulty from extra players.
    enableDifficultyPerPlayer = true, -- When true, the difficulty increases as the party size increases.
    maxPlayersUntilDifficultyIncrease = 1, -- When the part size is greater than this, increase the difficulty for each additional member.
    difficultyPerPlayer = 15, -- How much the difficulty increases for each additional party member.
    maxDifficulty = 100 -- Maximum difficulty.
}