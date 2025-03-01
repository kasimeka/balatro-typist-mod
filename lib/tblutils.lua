local M = {}

M.contains = function(tbl, value)
  for _, v in pairs(tbl) do
    if v == value then return true end
  end
  return false
end

M.dig = function(tbl, path)
  local it = tbl
  for _, v in ipairs(path) do
    if not it then return nil end
    it = it[v]
  end
  return it
end

M.list_concat = function(...)
  local res = {}
  for _, t in ipairs { ... } do
    for _, v in ipairs(t) do
      table.insert(res, v)
    end
  end
  return res
end

M.reversed_ipairs = function(tbl)
  return function(t, i)
    i = i + 1
    if i <= #t then return i, t[#t - i + 1] end
  end, tbl, 0
end

M.list_take = function(list, n)
  return table.move(list, 1, n, 1, {})
end

M.list_diff = function(tbl1, tbl2)
  local is_unique = {}
  for _, v in pairs(tbl1) do
    is_unique[v] = true
  end
  for _, v in pairs(tbl2) do
    is_unique[v] = nil
  end

  local difference = {}
  for _, v in pairs(tbl1) do
    if is_unique[v] then table.insert(difference, v) end
  end
  return difference
end

M.list_move_item = function(list, from, to)
  table.insert(list, to, table.remove(list, from))
end

M.list_index_of = function(list, value)
  for i, v in ipairs(list) do
    if v == value then return i end
  end
  return nil
end

M.reverse_lookup = function(tbl)
  local res = {}
  for k, v in pairs(tbl) do
    res[v] = k
  end
  return res
end
M.enum = function(values, methods)
  local enum = M.reverse_lookup(values)
  return methods and setmetatable(enum, { __index = methods }) or enum
end

M.keyset = function(tbl)
  local res = {}
  for k, _ in pairs(tbl) do
    res[k] = true
  end
  return res
end

M.valueset = function(tbl)
  local res = {}
  for _, v in pairs(tbl) do
    res[v] = true
  end
  return res
end

M.with_default = function(default, tbl)
  -- stylua: ignore
  return setmetatable(tbl, { __index = function() return default end, })
end

M.override_merge = function(...)
  local res = {}
  for _, tbl in ipairs { ... } do
    if tbl then
      for k, v in pairs(tbl) do
        res[k] = v
      end
    end
  end
  return res
end

-- very limited in representation and not 100% correct
M.dump_to_stdout = function(object)
  local t = type(object)
  if t == "table" then
    io.write("{ ")
    for k, v in pairs(object) do
      if type(k) ~= "number" then k = '"' .. k .. '"' end
      io.write("[" .. k .. "] = ")
      io.write(M.dump_to_stdout(v))
      io.write(", ")
    end
    io.write("}")
  elseif t == "boolean" or t == "nil" or t == "number" then
    io.write(tostring(object))
  else
    io.write("[[" .. object .. "]]")
  end
end

-- very limited in representation and not 100% correct
M.dump_to_string = function(object)
  local t = type(object)
  local result

  if t == "table" then
    result = "{ "
    for k, v in pairs(object) do
      if type(k) ~= "number" then k = '"' .. k .. '"' end
      result = result .. "[" .. k .. "] = " .. M.dump_to_string(v) .. ", "
    end
    result = result .. "}"
  elseif t == "boolean" or t == "nil" or t == "number" then
    result = tostring(object)
  else
    result = "[[" .. tostring(object) .. "]]"
  end

  return result
end

M.enum_add_metavalues = function(enum, additions)
  local metavalues = (getmetatable(enum) or {}).__index or {}
  for k, v in pairs(additions) do
    metavalues[k] = v
  end
  return setmetatable(enum, { __index = metavalues })
end

M.enum_attach_valueset = function(enum)
  return M.enum_add_metavalues(enum, { valueset = M.valueset(enum) })
end

return M
