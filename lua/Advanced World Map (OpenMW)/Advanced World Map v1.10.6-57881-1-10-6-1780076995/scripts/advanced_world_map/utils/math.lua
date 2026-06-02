local this = {}


function this.round(num, n)
  local mult = 10^(n or 0)
  return math.floor(num * mult + 0.5) / mult
end


return this