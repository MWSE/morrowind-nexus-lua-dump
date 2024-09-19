local this =  {}

function this.getFailureString(container)
    return "You failed to harvest anything of value."
end

function this.getSuccessString(container, ingredient, quantity)
    return string.format("You harvested %s %s.", quantity, ingredient.name)
end

return this
