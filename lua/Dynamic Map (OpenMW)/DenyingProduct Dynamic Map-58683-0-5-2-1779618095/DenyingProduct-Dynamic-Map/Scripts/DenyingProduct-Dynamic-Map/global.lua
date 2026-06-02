local world = require("openmw.world")
local types = require("openmw.types")
local util = require("openmw.util")

local Door = types.Door

local shopColor   = util.color.rgb(1, 0.824, 0.294) -- Yellowish (shops/outfitter)
local magicColor  = util.color.rgb(0.294, 0.725, 1) -- Blue (mages, alchemy)
local fightColor  = util.color.rgb(1, 0.675, 0.294) -- Orange (fighters, weapons)
local templeColor = util.color.rgb(0.294, 1, 0.584) -- Green (temples, chapels)
local redColor    = util.color.rgb(1, 0.294, 0.294) -- Red
local innColor    = util.color.rgb(0.561, 0.294, 1) -- Purple (inns, taverns)
local doorPatterns = { -- color to use if a door contains the keyword
    {keyword = "mage", 						color = magicColor,     cellType = "magic"},
    {keyword = "alchemist", 				color = magicColor,     cellType = "magic"},
    {keyword = "apothecary", 				color = magicColor,     cellType = "magic"},
    {keyword = "healer", 					color = magicColor,     cellType = "magic"},
    {keyword = "sorcerer", 					color = magicColor,     cellType = "magic"},
    {keyword = "enchanter", 				color = magicColor,     cellType = "magic"},
    {keyword = "herbalist", 				color = magicColor,     cellType = "magic"},
    {keyword = "elixirs", 					color = magicColor,     cellType = "magic"},
    {keyword = "fighter", 					color = fightColor,     cellType = "fight"},
    {keyword = "smith", 					color = fightColor,     cellType = "fight"},
    {keyword = "armor", 					color = fightColor,     cellType = "fight"},
    {keyword = "weapon", 					color = fightColor,     cellType = "fight"},
    {keyword = "the razor hole", 			color = fightColor,     cellType = "fight"},
    {keyword = "tong", 						color = redColor,       cellType = "red"},
    {keyword = "dres", 						color = redColor,       cellType = "red"},
    {keyword = "hlaalu", 					color = shopColor,      cellType = "hlaalu"},
    {keyword = "redoran", 					color = fightColor,     cellType = "redoran"},
    {keyword = "telvanni", 					color = magicColor,     cellType = "telvanni"},
    {keyword = "indoril", 					color = templeColor,    cellType = "temple"},
    {keyword = "temple", 					color = templeColor,    cellType = "temple"},
    {keyword = "chapel", 					color = templeColor,    cellType = "temple"},
    {keyword = "shrine", 					color = templeColor,    cellType = "temple"},
    {keyword = "wise woman", 				color = templeColor,    cellType = "temple"},
    {keyword = "outfitter", 				color = shopColor,      cellType = "shop"},
    {keyword = "pawn", 						color = shopColor,      cellType = "shop"},
    {keyword = "trade", 					color = shopColor,      cellType = "shop"},
    {keyword = "clothier", 					color = shopColor,      cellType = "shop"},
    {keyword = "weaver", 					color = shopColor,      cellType = "shop"},
    {keyword = "tailor", 					color = shopColor,      cellType = "shop"},
    {keyword = "book", 						color = shopColor,      cellType = "shop"},
    {keyword = "merchandise", 				color = shopColor,      cellType = "shop"},
    {keyword = "goods", 					color = shopColor,      cellType = "shop"},
    {keyword = "wares", 					color = shopColor,      cellType = "shop"},
    {keyword = "pantry", 					color = shopColor,      cellType = "shop"},
    {keyword = "fort", 						color = fightColor,     cellType = "fort"},
    {keyword = "tradehouse", 				color = innColor,       cellType = "inn"},
    {keyword = "inn", 						color = innColor,       cellType = "inn"},
    {keyword = "club", 						color = innColor,       cellType = "inn"},
    {keyword = "cornerclub", 				color = innColor,       cellType = "inn"},
    {keyword = "tavern", 					color = innColor,       cellType = "inn"},
    {keyword = "hostel", 					color = innColor,       cellType = "inn"},
    {keyword = "alehouse", 					color = innColor,       cellType = "inn"},
    {keyword = "bar", 						color = innColor,       cellType = "inn"},
    {keyword = "pub", 						color = innColor,       cellType = "inn"},
    {keyword = "eight plates", 				color = innColor,       cellType = "inn"},
    {keyword = "lucky lockup", 				color = innColor,       cellType = "inn"},
    {keyword = "shenk's shovel", 			color = innColor,       cellType = "inn"},
    {keyword = "the end of the world", 		color = innColor,       cellType = "inn"},
    {keyword = "six fishes", 				color = innColor,       cellType = "inn"},
    {keyword = "tower of dusk", 			color = innColor,       cellType = "inn"},
    {keyword = "the pilgrim's rest", 		color = innColor,       cellType = "inn"},
    {keyword = "fara's hole in the wall",	color = innColor,       cellType = "inn"},
    {keyword = "earthly delights", 			color = innColor,       cellType = "inn"},
    {keyword = "plot and plaster", 			color = innColor,       cellType = "inn"},
    {keyword = "the covenant", 				color = innColor,       cellType = "inn"},
    {keyword = "the flowers of gold", 		color = innColor,       cellType = "inn"},
    {keyword = "the lizard's head", 		color = innColor,       cellType = "inn"},
    {keyword = "lokken main hall", 			color = innColor,       cellType = "inn"},
    {keyword = "rat in the pot", 			color = innColor,       cellType = "inn"},
    {keyword = "the grey lodge", 			color = innColor,       cellType = "inn"},
    {keyword = "the laughing goblin", 		color = innColor,       cellType = "inn"},
    {keyword = "underground bazaar", 		color = innColor,       cellType = "inn"},
    {keyword = "hostel of the crossing", 	color = innColor,       cellType = "inn"},
    {keyword = "limping scrib", 			color = innColor,       cellType = "inn"},
    {keyword = "the pious pirate", 			color = innColor,       cellType = "inn"},
    {keyword = "the dancing cup", 			color = innColor,       cellType = "inn"},
    {keyword = "the guar with no name", 	color = innColor,       cellType = "inn"},
    {keyword = "shalaasa's caravanserai",	color = innColor,       cellType = "inn"},
    {keyword = "the nest", 					color = innColor,       cellType = "inn"},
    {keyword = "the gentle velk", 			color = innColor,       cellType = "inn"},
    {keyword = "the howling noose", 		color = innColor,       cellType = "inn"},
    {keyword = "the queen's cutlass", 		color = innColor,       cellType = "inn"},
    {keyword = "silver serpent", 			color = innColor,       cellType = "inn"},
    {keyword = "unnamed legion bar", 		color = innColor,       cellType = "inn"},
    {keyword = "mjornir's meadhouse", 		color = innColor,       cellType = "inn"},
    {keyword = "the red drake", 			color = innColor,       cellType = "inn"},
    {keyword = "the leaking spore", 		color = innColor,       cellType = "inn"},
    {keyword = "the swallow's nest", 		color = innColor,       cellType = "inn"},
    {keyword = "the golden glade", 			color = innColor,       cellType = "inn"},
    {keyword = "pilgrim's respite", 		color = innColor,       cellType = "inn"},
    {keyword = "the empress katariah", 		color = innColor,       cellType = "inn"},
    {keyword = "legion boarding house", 	color = innColor,       cellType = "inn"},
    {keyword = "the moth and tiger", 		color = innColor,       cellType = "inn"},
    {keyword = "the salty futtocks", 		color = innColor,       cellType = "inn"},
    {keyword = "the avenue", 				color = innColor,       cellType = "inn"},
    {keyword = "the dancing jug", 			color = innColor,       cellType = "inn"},
    {keyword = "the strider's wake", 		color = innColor,       cellType = "inn"},
    {keyword = "the toiling guar", 			color = innColor,       cellType = "inn"},
    {keyword = "the cliff racer's rest", 	color = innColor,       cellType = "inn"},
    {keyword = "the glass goblet", 			color = innColor,       cellType = "inn"},
    {keyword = "the note in your eye", 		color = innColor,       cellType = "inn"},
    {keyword = "the magic mudcrab", 		color = innColor,       cellType = "inn"},
    {keyword = "twisted root", 				color = innColor,       cellType = "inn"},
    {keyword = "the howling hound", 		color = innColor,       cellType = "inn"},
    {keyword = "the sload's tale", 			color = innColor,       cellType = "inn"},
    {keyword = "the abecette", 				color = innColor,       cellType = "inn"},
    {keyword = "caravan stop", 				color = innColor,       cellType = "inn"},
    {keyword = "sailor's fulke", 			color = innColor,       cellType = "inn"},
    {keyword = "anchor's rest", 			color = innColor,       cellType = "inn"},
    {keyword = "the blind watchtower", 		color = innColor,       cellType = "inn"},
    {keyword = "plaza taverna", 			color = innColor,       cellType = "inn"},
    {keyword = "sunset hotel", 				color = innColor,       cellType = "inn"},
    {keyword = "dancing saber", 			color = innColor,       cellType = "inn"},
    {keyword = "stendarr's retreat", 		color = innColor,       cellType = "inn"}
}

local function getDoorInfo(name)

    local lower =
        string.lower(name)

    for _, pattern in ipairs(doorPatterns) do

        if string.find(
            lower,
            pattern.keyword,
            1,
            true
        ) then
            return {
                color = pattern.color,
                cellType = pattern.cellType
            }
        end
    end

    return { color = nil, cellType = nil }
end

local function DP_DM_sendPlayerCells(e)

    local player = e.actor

    if not player then
        return
    end

    local exteriorCells = {}
    local interiorCells = {}

    local addedInterior = {}

    -------------------------------------------------
    -- Exterior Cells
    -------------------------------------------------

    for _, cell in pairs(world.cells) do

        if cell.isExterior
        and cell.name
        and cell.name ~= "" then

            table.insert(
                exteriorCells,
                {
                    name = cell.name,
                    x = cell.gridX,
                    y = cell.gridY
                }
            )
        end
    end

    -------------------------------------------------
    -- Interior Entrances
    -------------------------------------------------

    for _, cell in pairs(world.cells) do

        if cell.isExterior then

            local refs = cell:getAll(Door)

            for _, door in ipairs(refs) do

                if Door.isTeleport(door) then

                    local destCell = Door.destCell(door)
                    local destPos = Door.destPosition(door)

                    if destCell
                    and not destCell.isExterior
                    and destCell.name
                    and destCell.name ~= ""
                    and not addedInterior[destCell.name] then

                        addedInterior[destCell.name] = true
                        local info = getDoorInfo(destCell.name)
                        table.insert(
                            interiorCells,
                            {
                                name = destCell.name,
                                color = info.color,
                                cellType = info.cellType,

                                x = cell.gridX,
                                y = cell.gridY,

                                exteriorName = cell.name,

                                doorX = door.position.x,
                                doorY = door.position.y,
                                doorZ = door.position.z,

                                destX = destPos and destPos.x,
                                destY = destPos and destPos.y,
                                destZ = destPos and destPos.z
                            }
                        )
                    end
                end
            end
        end
    end

    -------------------------------------------------
    -- Send
    -------------------------------------------------

    player:sendEvent(
        "DP_DM_fromGlobal",
        {
            exteriorCells = exteriorCells,
            interiorCells = interiorCells
        }
    )
end

return {
    eventHandlers = {
        DP_DM_sendPlayerCells =
            DP_DM_sendPlayerCells
    }
}