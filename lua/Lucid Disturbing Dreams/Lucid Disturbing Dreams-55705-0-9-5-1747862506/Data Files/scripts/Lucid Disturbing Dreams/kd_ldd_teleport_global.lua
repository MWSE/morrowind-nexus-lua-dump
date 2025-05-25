--global

return {
    eventHandlers = {
      KD_Teleport = function(teleData)
        teleData.target:teleport(teleData.cell, teleData.position)
        print("global ok")
      end
    }
  }

