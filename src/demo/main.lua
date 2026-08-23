
-- half screen vectors
FOCAL_LENGTH = 2
U_0 = SCREEN_WIDTH / 2
V_0 = SCREEN_HEIGHT / 2
-- ALPHA_U = F * U_0
-- ALPHA_V = -F * V_0
ALPHA_U = 128
ALPHA_V = 128

local vertices = require("src.vertex")
local dither = require("src.dither")
local lighting = require("src.lighting")
local faces = require("src.face")
local billboards = require("src.billboard")
local scene = require("src.scene")

local BUFFER_MAX = 1024

-- vertices

local buf = userdata("f64", BUFFER_MAX)

local dither_ramp
-- local lighting_ramp
-- todo)) global
---@type LightingRamp
lighting_ramp = nil
local s
-- todo: convert to userdata
local light = vec(1, -2, -3)
local t = 0

local camera

COLOR_TABLE_ADDRS = {
  [0] = 0x8000,
  0x9000,
  0xA000,
  0xB000,
}

function apply_color_table(color_table_sprite, idx)
  idx = idx or 0
	local sprite=get_spr(color_table_sprite)
	--copy the sprite into the address 0x8000 in memory
	memmap(sprite,COLOR_TABLE_ADDRS[idx])
	--poke the bit that makes it work for shapes(circ,rect etc.), the bit for sprites
	--is already set by default.
	poke(0x550b,0x3f)
	--the color table got copied and will be used. This is the same color table 
	--that pal() modifies.
end

---@param v Vertex
---@return Vertex
function vector_normalize(v)
  local mag = v:dot(v) ^ 0.5
  if mag < EPSILON then
    return vec(0, 0, 0)
  end
  return vec(v.x / mag, v.y / mag, v.z / mag)
end

function _init()
  camera = {
    pos = vec(-2, 4, 2),
    -- pitch = 0, roll = 0, yaw = 0.25
    pitch = 0.1, roll = 0.1, yaw = 0
  }

  
  local o = vec(0, 0, 5)
  local i_hat = vec(1, 0, 0)
  local j_hat = vec(0, 1, 0)
  local k_hat = vec(0, 0, 1)

  local GRID_S = 5
  -- local GRID_S = 1

  local scene_builder = scene.builder()
  
  -- test scene
  do
    for l = 0, GRID_S-1 do
      for m = 0, GRID_S-1 do
        local s = (l*GRID_S+m)%4+1
        scene_builder:add_cube(o + vec(3*l, 0, 3*m), i_hat * (1 + l/GRID_S), j_hat, k_hat * (1 + m/GRID_S), s)
      end
    end

    -- scene_builder:add_sphere(
    --   vec(15, 5, 25),
    --   10,
    --   20,
    --   10,
    --   2
    -- )
  
    -- scene_builder:add_sphere(
    --   vec(3, 5, 15),
    --   2,
    --   8,
    --   4,
    --   2
    -- )

    scene_builder:add_billboard(
      vec(-3, -4, 5),
      5
    )
  end

  -- diorama
  do
    -- for x = -2, 2 do
    --   for z = -2, 2 do
    --     scene_builder:add_plane(
    --       vec(0 + x, 0, 3 + z),
    --       vec(1, 0, 0),
    --       vec(0, 0, 1),
    --       16
    --     )
    --   end
    -- end
    -- scene_builder:add_cube(
    --   vec(0, -1, 3),
    --   vec(1, 0, 0),
    --   vec(0, 1, 0),
    --   vec(0, 0, 1),
    --   17
    -- )
    -- scene_builder:add_cube(
    --   vec(-2, -1, 4),
    --   vec(1, 0, 0),
    --   vec(0, 1, 0),
    --   vec(0, 0, 1),
    --   17
    -- )
    -- scene_builder:add_cube(
    --   vec(2, -1, 2),
    --   vec(1, 0, 0),
    --   vec(0, 1, 0),
    --   vec(0, 0, 1),
    --   17
    -- )
    -- scene_builder:add_cube(
    --   vec(3, -1, 4),
    --   vec(1, 0, 0),
    --   vec(0, 1, 0),
    --   vec(0, 0, 1),
    --   17
    -- )
    
    -- scene_builder:add_billboard(
    --   vec(-1, 0, 1),
    --   0x90000 | 18
    -- )
  end
   

  light = vector_normalize(light)

  apply_color_table(8, 0)
  -- apply_color_table(8, 1)
  apply_color_table(10, 2)
  -- apply_color_table(10, 3)

  lighting_ramp = lighting.new()

  s = scene_builder:build()
  s.camera = camera
  
  profile.enabled(true, true)
end



function _update()
  profile("update")
  t = t + 1/60
  
  if btn(0) then camera.pos.x = camera.pos.x - 0.1 end
  if btn(1) then camera.pos.x = camera.pos.x + 0.1 end
  if btn(2) then camera.pos.z = camera.pos.z - 0.1 end
  if btn(3) then camera.pos.z = camera.pos.z + 0.1 end
  if btn(4) then camera.pos.y = camera.pos.y + 0.1 end
  if btn(5) then camera.pos.y = camera.pos.y - 0.1 end
  
  -- currently pitch and yaw have their names flipped, i think
  if btn(8) then camera.pitch = camera.pitch - 0.01 end
  if btn(9) then camera.pitch = camera.pitch + 0.01 end
  if btn(10) then camera.yaw = camera.yaw + 0.01 end
  if btn(11) then camera.yaw = camera.yaw - 0.01 end
  if btn(14) then camera.roll = camera.roll - 0.01 end
  if btn(15) then camera.roll = camera.roll + 0.01 end
  profile("update")
end

function _draw()
  light = vector_normalize(vec(cos(t / 20), -2, sin(0.2 + t / 20)))

  cls(21)

  s:draw()

  profile.draw()

  -- lighting_ramp.dither:debug_rect(10, 10, 110, 110, 7)
  -- lighting_ramp.dither:debug_circ(210, 210, 100, 7)
end

