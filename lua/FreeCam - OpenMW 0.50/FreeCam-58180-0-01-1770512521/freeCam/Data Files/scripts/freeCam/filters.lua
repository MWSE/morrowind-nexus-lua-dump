




local function LPF(oldValue, newValue, k)
   return ((oldValue) * k + (newValue) * (1 - k))
end

local function LPFdt(oldValue, newValue, k, dt)
   local kDt = math.min(1, math.pow(k, dt))
   return LPF(oldValue, newValue, kDt)
end

return {
   LPF = LPF,
   LPFdt = LPFdt,
}
