local vertices = require("src.vertex")
local faces = require("src.face")

SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270

-- half screen vectors
F = 2
U_0 = SCREEN_WIDTH / 2
V_0 = SCREEN_HEIGHT / 2
ALPHA_U = F * U_0
ALPHA_V = -F * V_0
-- focal length

-- vertices

local v
local f
local proj
local image
local world_to_cam
local cam_to_screen
local v_proj
local v_cam


local camera

function _init()
  camera = {
    x = 0, y = 0, z = 0,
    pitch = 0, roll = 0, yaw = 0
  }

  
  local cube_vertices = {}

  local o = {x = 0.2, y = 0.5, z = 5}
  local i_hat = {x = 1, y = 0, z = 0}
  local j_hat = {x = 0, y = 1, z = 0}
  local k_hat = {x = 0, y = 0, z = 1}

  for i = 0, 1 do
    for j = 0, 1 do
      for k = 0, 1 do
        add(cube_vertices, {
          x = o.x + i * i_hat.x + j * j_hat.x + k * k_hat.x,
          y = o.y + i * i_hat.y + j * j_hat.y + k * k_hat.y,
          z = o.z + i * i_hat.z + j * j_hat.z + k * k_hat.z,
        })
      end
    end
  end

  world_to_cam = userdata("f64", 4, 4)
  world_to_cam:set(0, 0,
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    camera.x, camera.y, camera.z, 1
  )

  cam_to_screen = userdata("f64", 4, 4)
  cam_to_screen:set(0, 0,
    ALPHA_U, 0, U_0, 0,
    0, ALPHA_V, V_0, 0,
    0, 0, 1, 0,
    0, 0, 0, 0
  )
  cam_to_screen:transpose(true)

  
  v = vertices.of(cube_vertices)
  v_proj = vertices.of(cube_vertices)
  v_cam = vertices.of(cube_vertices)


  f = faces.of({
    {v1 = 0, v2 = 1, v0 = 2, v3 = 3},
    {v1 = 4, v2 = 5, v0 = 6, v3 = 7},
    {v1 = 0, v2 = 1, v0 = 4, v3 = 5},
    {v1 = 2, v2 = 3, v0 = 6, v3 = 7},
    {v1 = 0, v2 = 2, v0 = 4, v3 = 6},
    {v1 = 1, v2 = 3, v0 = 5, v3 = 7},
  })
end



function _update()
  if btn(0) then camera.x = camera.x - 0.1 end
  if btn(1) then camera.x = camera.x + 0.1 end
  if btn(2) then camera.y = camera.y - 0.1 end
  if btn(3) then camera.y = camera.y + 0.1 end
  if btn(4) then camera.z = camera.z + 0.1 end
  if btn(5) then camera.z = camera.z - 0.1 end
  
  if btn(8) then camera.yaw = camera.yaw - 0.001 end
  if btn(9) then camera.yaw = camera.yaw + 0.001 end
  if btn(10) then camera.pitch = camera.pitch - 0.001 end
  if btn(11) then camera.pitch = camera.pitch + 0.001 end
  if btn(14) then camera.roll = camera.roll + 0.001 end
  if btn(15) then camera.roll = camera.roll - 0.001 end
end

function _draw()
  local a = camera.yaw
  local b = camera.pitch
  local g = camera.roll
  world_to_cam:set(0, 0,
    cos(b)*cos(g), -cos(b)*sin(g), sin(b), camera.x,
    cos(a)*sin(g)+sin(a)*sin(b)*cos(g), cos(a)*cos(g)-sin(a)*sin(b)*sin(g), -sin(a)*cos(b), camera.y,
    sin(a)*sin(g)-cos(a)*sin(b)*cos(g), sin(a)*cos(g)+cos(a)*sin(b)*sin(g), cos(a)*cos(b), camera.y,
    0, 0, 0, 1
  )
  world_to_cam:transpose(true)

  cls(21)

  -- DEBUG = true
  DEBUG = false
  
  color(6)
  print("CPU: " .. stat(1))
  print("CAM: " .. camera.x .. "," .. camera.y .. "," .. camera.z)

  color(5)
  v:transform(v_proj.data, world_to_cam)
  if DEBUG then
  print("v_proj")
  print(v_proj.data[0] .. ", " .. v_proj.data[1] .. ", " .. v_proj.data[2] .. ", " .. v_proj.data[3] .. ", ")
  print(v_proj.data[4+0] .. ", " .. v_proj.data[4+1] .. ", " .. v_proj.data[4+2] .. ", " .. v_proj.data[4+3] .. ", ")
  print(v_proj.data[8+0] .. ", " .. v_proj.data[8+1] .. ", " .. v_proj.data[8+2] .. ", " .. v_proj.data[8+3] .. ", ")
  print(v_proj.data[12+0] .. ", " .. v_proj.data[12+1] .. ", " .. v_proj.data[12+2] .. ", " .. v_proj.data[12+3] .. ", ")
  print(v_proj.data[16+0] .. ", " .. v_proj.data[16+1] .. ", " .. v_proj.data[16+2] .. ", " .. v_proj.data[16+3] .. ", ")
  print(v_proj.data[20+0] .. ", " .. v_proj.data[20+1] .. ", " .. v_proj.data[20+2] .. ", " .. v_proj.data[20+3] .. ", ")
  print(v_proj.data[24+0] .. ", " .. v_proj.data[24+1] .. ", " .. v_proj.data[24+2] .. ", " .. v_proj.data[24+3] .. ", ")
  print(v_proj.data[28+0] .. ", " .. v_proj.data[28+1] .. ", " .. v_proj.data[28+2] .. ", " .. v_proj.data[28+3] .. ", ")
  end

  v_proj:transform(v_cam.data, cam_to_screen)
  v_cam.data:div(v_cam.data, true, 2, 0, 1, 4, 4, v_proj.length)
  v_cam.data:div(v_cam.data, true, 2, 1, 1, 4, 4, v_proj.length)
  if DEBUG then
  print(v_cam.length .. ", " .. v_cam.capacity)
  print(v_cam.data[0] .. ", " .. v_cam.data[1] .. ", " .. v_cam.data[2] .. ", " .. v_cam.data[3] .. ", ")
  print(v_cam.data[4+0] .. ", " .. v_cam.data[4+1] .. ", " .. v_cam.data[4+2] .. ", " .. v_cam.data[4+3] .. ", ")
  print(v_cam.data[8+0] .. ", " .. v_cam.data[8+1] .. ", " .. v_cam.data[8+2] .. ", " .. v_cam.data[8+3] .. ", ")
  print(v_cam.data[12+0] .. ", " .. v_cam.data[12+1] .. ", " .. v_cam.data[12+2] .. ", " .. v_cam.data[12+3] .. ", ")
  print(v_cam.data[16+0] .. ", " .. v_cam.data[16+1] .. ", " .. v_cam.data[16+2] .. ", " .. v_cam.data[16+3] .. ", ")
  print(v_cam.data[20+0] .. ", " .. v_cam.data[20+1] .. ", " .. v_cam.data[20+2] .. ", " .. v_cam.data[20+3] .. ", ")
  print(v_cam.data[24+0] .. ", " .. v_cam.data[24+1] .. ", " .. v_cam.data[24+2] .. ", " .. v_cam.data[24+3] .. ", ")
  print(v_cam.data[28+0] .. ", " .. v_cam.data[28+1] .. ", " .. v_cam.data[28+2] .. ", " .. v_cam.data[28+3] .. ", ")
  end

  color(7)
  f:draw_wireframes(v_cam)
  
  color(8)
  pset(v_cam.data, 0, v_cam.length, 2, 4)

end

