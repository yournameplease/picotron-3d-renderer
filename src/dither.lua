local ud_util = require("src.userdata")

local FILLP_ADDR = 0x5500

---@class DitherRamp
---@field dithers userdata[]
local DitherRamp = {}
DitherRamp.__index = DitherRamp


local dither = {}

function dither.new_hatched(horizontals, verticals)
  local cur = userdata("u8", 8)
  ud_util.debugh(cur)

  local dithers = {cur}
  cur = cur:copy()

  for i = 0, 2 do
    local n = 1<<(i-1)
    local line_start = 8 / (n<<1)
    local line_step = 8 / (n)

    if i == 0 then
      line_start = 0
      n = 1
    end

    for j = 0, n-1 do
      local line_0 = line_start + j*line_step
      for k = 0, 7 do
        local y = horizontals and line_0 or k
        local x = (line_0 + k)%8
        cur:bor(1 << (x), true, y, y, 1, 1, 1, 1)
      end
      add(dithers, cur)
      ud_util.debugh(cur)
      
      cur = cur:copy()
      for k = 0, 7 do
        local y = k
        local x = verticals and line_0 or (line_0 + k)%8
        cur:bor(1 << (x), true, 7-y, 7-y, 1, 1, 1, 1)
      end
      add(dithers, cur)
      cur = cur:copy()
      ud_util.debugh(cur)
    end 
  end

  local self = setmetatable({}, DitherRamp)

  self.dithers = dithers
  
  return self
end

function dither.new_bayer()
  local cur = userdata("u8", 8)
  ud_util.debugh(cur)

  local dithers = {cur}
  cur = cur:copy()


  function x_step(i)
    if i == 2 or i == 1 then return 1 else return 0 end
  end
  function y_step(i)
    if i == 2 or i == 3 then return 1 else return 0 end
  end
  
  for i = 0, 3 do
    for j = 0, 3 do
      for k = 0, 3 do
        local y = 4 * y_step(k) + 2*y_step(j) + y_step(i)
        local x = 4 * x_step(k) + 2*x_step(j) + x_step(i)
        cur:bor(1 << (x), true, y, y, 1, 1, 1, 1)
        add(dithers, cur)
        ud_util.debugh(cur)
        cur = cur:copy()
      end
    end 
  end

  local self = setmetatable({}, DitherRamp)

  self.dithers = dithers
  
  return self
end

---@param t number value in [0,1]
function DitherRamp:set_dither(t)
  t = mid(0, t, 1)
  
  local len = #self.dithers
  local idx = flr(t * (len - 1) + 0.5)

  self.dithers[idx+1]:poke(FILLP_ADDR)
end

function DitherRamp:debug_rect(x0, y0, x1, y1, c)
  c = c or 7
  
  for x = x0, x1 do
    self:set_dither((x-x0)/(x1-x0))
    rectfill(x, y0, x, y1, c)
  end
end

function DitherRamp:debug_circ(x, y, r, c)
  c = c or 7
  
  for r0 = r, 1, -1 do
    self:set_dither((r-r0)/r)
    circfill(x, y, r0, c)
  end
end

return dither
