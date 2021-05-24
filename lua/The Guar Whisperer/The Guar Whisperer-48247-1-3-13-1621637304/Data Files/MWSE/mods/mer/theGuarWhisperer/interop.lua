local animalController = require("mer.theGuarWhisperer.animalController")

local function eat(e)
    local animal = animalController.getAnimal(e.reference)
    animal:modHunger(e.amount)
end

event.register("Ashfall:Eat", eat)