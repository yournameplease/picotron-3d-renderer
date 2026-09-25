SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
EPSILON = 0.0001


local cube_game = require("src.cube_game.main")
local demo_scenes = require("src.demo.main")

local demos = {
  {
    init = cube_game.init,
    update = cube_game.update,
    draw = cube_game.draw,
  },
  {
    init = demo_scenes.init_cubes,
    update = demo_scenes.update,
    draw = demo_scenes.draw,
  },
  {
    init = demo_scenes.init_sphere,
    update = demo_scenes.update,
    draw = demo_scenes.draw,
  },
}

local demo_index = 1

function _init()
  demos[demo_index].init()
end

function _update()
  if btnp(12) then
    demo_index = demo_index % #demos + 1
    _init()
  end
  
  demos[demo_index].update()
end

function _draw()
  demos[demo_index].draw()
end
