local this =  {}

function this.getFailureString(container)
    return "Uszkodzono skіadnik."
end

function this.getSuccessString(container, ingredient, quantity)
    return string.format("Zebrano %s %s.", quantity, ingredient.name)
end

return this
