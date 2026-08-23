local ud_util = require("src.userdata")
local L_V0_COL = 0
local L_V1_COL = 1

local L_LEN = 2

local D_X0_COL = 0
local D_Y0_COL = 1
local D_X1_COL = 2
local D_Y1_COL = 3
local D_C_COL = 4

local D_ARGS = 5
local D_LEN = 5

---@class Line
---@field v0 integer
---@field v1 integer
---@field c integer

---@class Lines
---@field data userdata
---@field to_draw userdata
---@field length integer
---@field capacity integer
local Lines = {}
Lines.__index = Lines
local lines = {}

---@param capacity integer
---@return Lines
function lines.new(capacity)
  local self = setmetatable({}, Lines)

  self.data = userdata("i32", L_LEN, capacity+1)
  self.to_draw = userdata("f64", D_LEN, capacity+1)
  self.length = 0
  self.capacity = capacity

  return self
end
 
---@param vs Line[]
---@return Lines
function lines.of(vs)
  local self = lines.new(#vs)
  for _, v in ipairs(vs) do
    self:add(v)
  end
  -- ud_util.debugh(self.data)
  return self
end

---@param line Line
function Lines:add(line)
  assert(self.length < self.capacity)
  self.data:set(L_V0_COL, self.length, line.v0)
  self.data:set(L_V1_COL, self.length, line.v1)
  self.to_draw:set(D_C_COL, self.length, line.c)
  self.length = self.length + 1
end


function Lines:draw(draw_vertices)
  draw_vertices.data:take(self.data:mul(4), self.to_draw, L_V0_COL, D_X0_COL, 2, L_LEN, D_LEN, self.length)
  draw_vertices.data:take(self.data:mul(4), self.to_draw, L_V1_COL, D_X1_COL, 2, L_LEN, D_LEN, self.length)

  ud_util.debug(self.to_draw)
  line(self.to_draw, 0, self.length, D_ARGS, D_LEN)
end

return lines
