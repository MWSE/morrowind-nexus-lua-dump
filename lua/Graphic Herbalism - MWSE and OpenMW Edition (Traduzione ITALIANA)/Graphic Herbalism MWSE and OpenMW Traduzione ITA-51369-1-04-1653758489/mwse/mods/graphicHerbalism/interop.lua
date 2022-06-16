local this =  {}

function this.getFailureString(container)
    return "Non sei riuscito a raccogliere nulla di utile"
end

function this.getSuccessString(container, ingredient, quantity)
    return string.format("Hai raccolto %s %s", quantity, ingredient.name)
end

return this
