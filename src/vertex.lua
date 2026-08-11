

local X_COL = 0
local Y_COL = 1
local Z_COL = 2
local W_COL = 3

---@class Vertex
---@field x number
---@field y number
---@field z number

---@class Vertices
---@field data userdata
---@field length integer
---@field capacity integer
local Vertices = {}
Vertices.__index = Vertices
local vertices = {}

---@param capacity integer
---@return Vertices
function vertices.new(capacity)
  local self = setmetatable({}, Vertices)

  self.data = userdata("f64", 4, capacity)
  self.length = 0
  self.capacity = capacity

  return self
end
 
---@param vs Vertex[]
---@return Vertices
function vertices.of(vs)
  local self = vertices.new(#vs)
  for _, v in ipairs(vs) do
    self:add(v)
  end
  return self
end


---@param vertex Vertex
function Vertices:add(vertex)
  assert(self.length < self.capacity)
  self.data:set(0, self.length, vertex.x, vertex.y, vertex.z, 1)
  self.length = self.length + 1
end

---@param target userdata
---@param matrix userdata
function Vertices:transform(target, matrix)
  self.data:matmul(matrix, target, 1)
end

return vertices
