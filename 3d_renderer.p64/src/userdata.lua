
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
  max_rows = (max_rows or ud:height()) + start
  for y = start, min(ud:height(), max_rows)-1 do
    str = y .. ": " .. ud:get(0, y)
    for x = 1, ud:width()-1 do
      str = str .. ", " .. ud:get(x, y)
    end
    printh(str)
  end
end

return ud_util
