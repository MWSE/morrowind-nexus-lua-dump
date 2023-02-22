local this =  {}

function this.getFailureString(container)
    return "Вы не нашли ничего ценного."
end

function this.getSuccessString(container, ingredient, quantity)
    return string.format("Вы собрали %s %s.", quantity, ingredient.name)
end

return this
