local tu = require("typist.lib.tblutils")

local cardarea_handler = require("typist.mod.cardarea-handler")
local layout = require("typist.mod.layout")

---try each leader key in `layout.cardarea_map`; if one is held, dispatch to that CardArea
---return value matches `area and cardarea_handler(...)` so a `false` from the handler falls through
---@param held_keys table<string, boolean>
---@param key string
---@return boolean|nil
local function try_cardarea_with_leader(held_keys, key)
  for leader, area_fn in pairs(layout.cardarea_map) do
    if held_keys[leader] then
      local area = area_fn and area_fn()
      return area and cardarea_handler(area, key, held_keys)
    end
  end
end

---composite top row (jokers + consumables) when free-select keys or an active hover selection apply
---@param key string
---@param held_keys table<string, boolean>
---@return boolean|nil
local function try_top_area_composite(key, held_keys)
  if not (layout.top_area_free_select_map[key] or G.__typist_TOP_AREA.active_selection) then
    return
  end
  if not (G.jokers and G.consumeables) then return end

  G.__typist_TOP_AREA.cards = tu.list_concat(G.jokers.cards, G.consumeables.cards)
  G.__typist_TOP_AREA.highlighted = tu.list_concat(G.jokers.highlighted, G.consumeables.highlighted)

  return cardarea_handler(G.__typist_TOP_AREA, key, held_keys)
end

return function(Controller, key) -- order defines precedence
  if G.CONTROLLER and G.CONTROLLER.text_input_hook then return end

  if key == layout.escape then
    if G.OVERLAY_MENU then
      G.FUNCS:exit_overlay_menu()
    elseif G.STATE == G.STATES.SPLASH then
      G:delete_run()
      G:main_menu()
    else
      G.FUNCS:options()
    end
    return
  end

  if layout.global_map[key] then
    layout.global_map[key](Controller.held_keys)
    return
  end

  if G.SETTINGS.paused then
    require("typist.mod.state-handlers")[G.STATES.MENU](key, Controller.held_keys)
    return
  end

  if try_cardarea_with_leader(Controller.held_keys, key) then return end

  if try_top_area_composite(key, Controller.held_keys) then return end

  local state_handler = require("typist.mod.state-handlers")[G.STATE]
  if state_handler and G.GAME.STOP_USE == 0 then state_handler(key, Controller.held_keys) end
end
