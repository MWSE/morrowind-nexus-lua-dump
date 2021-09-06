local animalController = require("mer.theGuarWhisperer.animalController")

local function eat(e)
    local animal = animalController.getAnimal(e.reference)
    if animal then
        animal:modHunger(e.amount)
    end
end

event.register("Ashfall:Eat", eat)