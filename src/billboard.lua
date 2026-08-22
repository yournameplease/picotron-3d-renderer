---@class Billboard
---@field s integer
---@field v integer

local ud_util = require("src.userdata")

B_V_COL = 0
B_S_COL = 1
B_SPRITE_H_COL = 2
B_SPRITE_W_COL = 3
B_WORLD_H_COL = 4
B_WORLD_W_COL = 5

B_LEN = 6

D_S_COL = 0
D_SX_COL = 1
D_SY_COL = 2
D_SW_COL = 3
D_SH_COL = 4
D_DX_COL = 5
D_DY_COL = 6
D_DW_COL = 7
D_DH_COL = 8
D_WORLD_W_COL = 9
D_WORLD_H_COL = 10

D_LEN = 11

---@class Billboards
---@field data userdata
---@field to_draw userdata
---@field length integer
---@field capacity integer
local Billboards = {}
Billboards.__index = Billboards
local billboards = {}

---@param capacity integer
---@return Billboards
function billboards.new(capacity)
  local self = setmetatable({}, Billboards)

  self.data = userdata("i32", B_LEN, capacity)
  self.to_draw = userdata("f64", D_LEN, capacity)
  self.length = 0
  self.capacity = capacity

  return self
end
 
---@param bbs Billboard[]
---@return Billboards
function billboards.of(bbs)
  local self = billboards.new(#bbs)

  for _,bb in ipairs(bbs) do
    self:add(bb)
  end

  return self
end

---@param billboard Billboard
function Billboards:add(billboard)
  assert(self.length < self.capacity)

  self.to_draw:set(D_S_COL, self.length, billboard.s)
  self.data:set(B_V_COL, self.length, billboard.v)
  self.to_draw:set(D_SH_COL, self.length, 16)
  self.to_draw:set(D_SW_COL, self.length, 16)
  self.to_draw:set(D_WORLD_H_COL, self.length, 256)--16)
  self.to_draw:set(D_WORLD_W_COL, self.length, 256)--16)

  self.length = self.length + 1
end

function Billboards:draw(vertices)
  -- self.to_draw:copy(self.data, true, B_S_COL, D_S_COL, 1, B_LEN, D_LEN, self.length)
  vertices.data:take(self.data:mul(4), self.to_draw, B_V_COL, D_DX_COL, 3, 4, D_LEN, self.length)
  self.to_draw:copy(0, true, B_S_COL, D_SX_COL, 1, D_LEN, D_LEN, self.length)
  self.to_draw:copy(0, true, B_S_COL, D_SY_COL, 1, D_LEN, D_LEN, self.length)
  -- self.to_draw:copy(self.data, true, B_SPRITE_W_COL, D_SH_COL, 1, B_LEN, D_LEN, self.length)
  -- self.to_draw:copy(self.data, true, B_SPRITE_H_COL, D_SW_COL, 1, B_LEN, D_LEN, self.length)
  -- also gets 1/z -> D_DW_COL
  self.to_draw:copy(self.to_draw, true, D_DW_COL, D_DH_COL, 1, D_LEN, D_LEN, self.length)
  self.to_draw:mul(self.to_draw, true, D_WORLD_W_COL, D_DW_COL, 1, D_LEN, D_LEN, self.length)
  self.to_draw:mul(self.to_draw, true, D_WORLD_H_COL, D_DH_COL, 1, D_LEN, D_LEN, self.length)

  sspr(self.to_draw, 0, self.length, 9, D_LEN)

  -- print("")
  -- print("")
  -- print("")
  -- print("")
  -- print("")
  -- print("")
  -- print("")
  -- print("")
  -- print("")
  -- print("")
  -- print(self.length)
  -- ud_util.debug(self.data)
  -- ud_util.debug(self.to_draw)
end

return billboards
