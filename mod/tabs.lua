local tu = require("typist.lib.tblutils")
local layout = require("typist.mod.layout")

local M = {}

function M.cycle_index(current, count, step)
  return ((current + step - 1) % count) + 1
end

function M.collect(labels)
  local tabs = {}
  if not G.OVERLAY_MENU then return tabs end
  for _, label in ipairs(labels) do
    local tab = G.OVERLAY_MENU:get_UIE_by_ID("tab_but_" .. label)
    if tab and tu.dig(tab, { "config", "button" }) then
      tabs[#tabs + 1] = tab
    end
  end
  return tabs
end

function M.cycle(tabs, state, step)
  step = step or 1
  state = state or {}
  local current = state.current
  if not current or not tabs[current] or not tu.dig(tabs[current], { "config", "chosen" }) then
    current = 1
    for i, tab in ipairs(tabs) do
      if tu.dig(tab, { "config", "chosen" }) then current = i; break end
    end
  end

  local next = M.cycle_index(current, #tabs, step)
  tabs[current].config.chosen = false
  tabs[next].config.chosen = true
  G.FUNCS.change_tab(tabs[next])
  state.current = next
end

function M.make_handler(labels_fn)
  local state = {}
  return function(key, held_keys)
    if key ~= layout.dismiss then return false end
    local t = M.collect(labels_fn())
    if #t < 2 then return false end
    local step = (held_keys[layout.modifier_left] or held_keys[layout.modifier_right]) and -1 or 1
    M.cycle(t, state, step)
    return true
  end
end

return M
