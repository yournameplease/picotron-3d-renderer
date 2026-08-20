
local ud_util = {}

function ud_util.debug(ud, start, max_rows)
  start = start or 0
  max_rows = (max_rows or ud:height()) + start
  for y = start, min(ud:height(), max_rows)-1 do
    str = y .. ": " .. ud:get(0, y)
    for x = 1, ud:width()-1 do
      str = str .. ", " .. ud:get(x, y)
    end
    print(str)
  end
end

function ud_util.debugh(ud, start, max_rows)
  start = start or 0
  max_rows = max_rows or ud:height()
  if max_rows == nil then
    --1d
    local str = ud:get(0)
    for x = 1, ud:width()-1 do
      str = str .. ", " .. ud:get(x)
    end
    printh(str)
    return
  else
    max_rows = (max_rows or ud:height()) + start
    for y = start, min(ud:height(), max_rows)-1 do
      local str = y .. ": " .. ud:get(0, y)
      for x = 1, ud:width()-1 do
        str = str .. ", " .. ud:get(x, y)
      end
      printh(str)
    end
    return
  end
end

return ud_util
