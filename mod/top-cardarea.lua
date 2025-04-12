local tu = require("typist.lib.tblutils")

local layout = require("typist.mod.layout")

-- local function mergaroonie(...)
--   local res = {}
--   for _, tbl in ipairs { ... } do
--     if tbl then
--       for _, v in pairs(tbl) do
--         res[v] = true
--       end
--     end
--   end
--   return res
-- end

-- pseudo-CardArea object to manipulate jokers and consumable as if they're one hand
local top_area = setmetatable({}, { __index = { __typist_top_area = true } })
return function(key, held_keys)
  if layout.free_select_two_electric_boogaloo[key] or __typist_ACTIVE_TOP_AREA_SELECTION then
    top_area.cards = tu.list_concat(G.jokers.cards, G.consumeables.cards)
    -- local cardset = mergaroonie(G.jokers.cards, G.consumeables.cards)

    top_area.highlighted = tu.list_concat(G.jokers.highlighted, G.consumeables.highlighted)

    return require("typist.mod.cardarea-handler")(top_area, key, held_keys)
  end
end
