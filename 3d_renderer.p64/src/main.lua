local vertices = require("src.vertex")

-- vertices

local v
local proj
local v_proj

function _init()
  local cube_vertices = {}

  local o = {x = 2, y = 1, z = 0}
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

  local d = 1
  proj = userdata("f64", 4, 4)
  proj:set(0, 0,
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, -1/d, 1
  )

  
  v = vertices.of(cube_vertices)
  v_proj = vertices.of(cube_vertices)
end



function _update()
  
end

function _draw()
  v:transform(v_proj.data, proj)
  cls(21)
  color(7)
  pset(v_proj.data, 0, v_proj.length, 2, 4)

  print(v_proj.data[0] .. ", " .. v_proj.data[1] .. ", " .. v_proj.data[2] .. ", " .. v_proj.data[3] .. ", ")
  print(v_proj.data[4+0] .. ", " .. v_proj.data[4+1] .. ", " .. v_proj.data[4+2] .. ", " .. v_proj.data[4+3] .. ", ")
  print(v_proj.data[8+0] .. ", " .. v_proj.data[8+1] .. ", " .. v_proj.data[8+2] .. ", " .. v_proj.data[8+3] .. ", ")
  print(v_proj.data[12+0] .. ", " .. v_proj.data[12+1] .. ", " .. v_proj.data[12+2] .. ", " .. v_proj.data[12+3] .. ", ")
  print(v_proj.data[16+0] .. ", " .. v_proj.data[16+1] .. ", " .. v_proj.data[16+2] .. ", " .. v_proj.data[16+3] .. ", ")
  print(v_proj.data[20+0] .. ", " .. v_proj.data[20+1] .. ", " .. v_proj.data[20+2] .. ", " .. v_proj.data[20+3] .. ", ")
  print(v_proj.data[24+0] .. ", " .. v_proj.data[24+1] .. ", " .. v_proj.data[24+2] .. ", " .. v_proj.data[24+3] .. ", ")
  print(v_proj.data[28+0] .. ", " .. v_proj.data[28+1] .. ", " .. v_proj.data[28+2] .. ", " .. v_proj.data[28+3] .. ", ")
end

