return {
  getIndex = function(x, y)
    local xx = x >= 0 and x * 2 or x * -2 - 1
    local yy = y >= 0 and y * 2 or y * -2 - 1
    return (xx >= yy) and (xx * xx + xx + yy) or (yy * yy + xx)
  end,
  unpair = function(z)
    local sqrtz = math.floor(math.sqrt(z))
    local sqz = sqrtz * sqrtz
    local result1 = ((z - sqz) >= sqrtz) and {sqrtz, z - sqz - sqrtz} or {z - sqz, sqrtz}
    local xx = result1[1] % 2 == 0 and result1[1] / 2 or (result1[1] + 1) / -2
    local yy = result1[2] % 2 == 0 and result1[2] / 2 or (result1[2] + 1) / -2
    return xx, yy
  end
}
