event.register("damage", function(e)
  if (e.reference.object.isEssential == true) then
    e.damage = 0
  end
end)