
-- lazy, need to make this not hidden
local CACHE_MAX = 64

local V0_COL = 0
local V1_COL = 1
local V2_COL = 2
local V3_COL = 3

---@class Face
---@field v0 integer
---@field v1 integer
---@field v2 integer
---@field v3 integer

---@class Faces
---@field data userdata
---@field length integer
---@field capacity integer
local Faces = {}
Faces.__index = Faces
local faces = {}

---@param capacity integer
---@return Faces
function faces.new(capacity)
  local self = setmetatable({}, Faces)

  self.data = userdata("i32", 4, capacity)
  self.length = 0
  self.capacity = capacity

  return self
end
 
---@param vs Face[]
---@return Faces
function faces.of(vs)
  local self = faces.new(#vs)
  for _, v in ipairs(vs) do
    self:add(v)
  end
  return self
end

---@param face Face
function Faces:add(face)
  assert(self.length < self.capacity)
  self.data:set(0, self.length, face.v0, face.v1, face.v2, face.v3)
  self.length = self.length + 1
end

local wireframe_cache = userdata("f64", 10, CACHE_MAX)

---@param draw_vertices Vertices
function Faces:draw_wireframes(draw_vertices)
  wireframe_cache:copy(-1)
  draw_vertices.data:take(self.data:mul(4), wireframe_cache, 0, 0, 2, 4, 10, self.length)
  draw_vertices.data:take(self.data:mul(4), wireframe_cache, 1, 2, 2, 4, 10, self.length)
  draw_vertices.data:take(self.data:mul(4), wireframe_cache, 2, 4, 2, 4, 10, self.length)
  draw_vertices.data:take(self.data:mul(4), wireframe_cache, 3, 6, 2, 4, 10, self.length)
  draw_vertices.data:take(self.data:mul(4), wireframe_cache, 0, 8, 2, 4, 10, self.length)

  for i = 0, self.length-2 do
    line(wireframe_cache, i * 10, 4, 4, 2)
  end
end

return faces
