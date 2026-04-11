local tu = require("typist.lib.tblutils")

local layout = require("typist.mod.layout")

local M = {}

local function cycle_index(current, count, step)
  return ((current + step - 1) % count) + 1
end
local direction = {
  [layout.menu_nav.left] = -1,
  [layout.menu_nav.right] = 1,
  [layout.menu_nav.down] = -1,
  [layout.menu_nav.up] = 1,
}
local ordered_names, viewed_deck = {}, 1

local function is_new_run()
  return G.OVERLAY_MENU and G.SETTINGS.current_setup == "New Run"
end

local function collect_tabs()
  local run_setup_tabs = {}
  if G.OVERLAY_MENU:get_UIE_by_ID("tab_contents") then
    for _, label in ipairs {
      localize("b_new_run"),
      localize("b_continue"),
      localize("b_challenges"),
    } do
      local tab = G.OVERLAY_MENU:get_UIE_by_ID("tab_but_" .. label)
      if tab and tu.dig(tab, { "config", "button" }) then
        run_setup_tabs[#run_setup_tabs + 1] = tab
      end
    end
  end
  return run_setup_tabs
end

local function cycle_tabs(run_setup_tabs)
  local current_tab = 1
  for i, tab in ipairs(run_setup_tabs) do
    if tu.dig(tab, { "config", "chosen" }) then
      current_tab = i
      break
    end
  end

  local next_tab = run_setup_tabs[cycle_index(current_tab, #run_setup_tabs, 1)]

  for _, tab in ipairs(run_setup_tabs) do
    tab.config.chosen = false
  end
  next_tab.config.chosen = true

  G.FUNCS.change_tab(next_tab)
end

local function navigate_deck_and_stake(key)
  if key == layout.menu_nav.left or key == layout.menu_nav.right then
    for i, v in ipairs(G.P_CENTER_POOLS.Back) do
      ordered_names[i] = v.name
      if v.name == G.GAME.viewed_back.name then viewed_deck = i end
    end

    local new_index = cycle_index(viewed_deck, #ordered_names, direction[key])

    G.FUNCS.change_viewed_back { to_key = new_index, to_val = ordered_names[new_index] }
  elseif key == layout.menu_nav.down or key == layout.menu_nav.up then
    local max_stake = get_deck_win_stake(G.GAME.viewed_back.effect.center.key) or 0
    if G.PROFILES[G.SETTINGS.profile].all_unlocked then max_stake = 8 end

    local stake_count = math.min(max_stake + 1, 8)
    local new_stake = cycle_index(G.viewed_stake or 1, stake_count, direction[key])

    G.FUNCS.change_stake { to_key = new_stake }
  end
end

local function get_seed_row()
  return G.OVERLAY_MENU:get_UIE_by_ID("run_setup_seed")
end
local function get_seed_toggle()
  return tu.dig(get_seed_row(), { "parent", "parent", "children", 3, "children", 1 })
end
local function get_seed_input()
  local object = tu.dig(get_seed_toggle(), { "config", "object" })
  if not object then return end

  return object:get_UIE_by_ID("text_input")
end
local function get_clickable_start_button()
  local start_button = tu.dig(get_seed_row(), { "parent", "children", 2 })
  if not start_button then return end

  G.FUNCS.can_start_run(start_button)
  return start_button.config.button == "start_setup_run" and start_button
end
local function try_start()
  local start_button = get_clickable_start_button()
  if not start_button then return false end

  G.FUNCS.start_setup_run(start_button)
  return true
end
M.handle = function(key)
  -- Handle tab cycling first, works on all tabs
  local run_setup_tabs = collect_tabs()
  if key == layout.dismiss and #run_setup_tabs > 1 then
    cycle_tabs(run_setup_tabs)
    return true
  end

  if not is_new_run() then return false end

  if key == layout.menu_nav.seed then
    local toggle = get_seed_toggle()

    if not G.run_setup_seed or not get_seed_input() then
      G.run_setup_seed = true
      G.FUNCS.toggle_seeded_run(toggle)
    end

    ---@diagnostic disable-next-line: param-type-mismatch -- if it's nil after we've just created it then we're fucked anyway
    G.FUNCS.select_text_input(get_seed_input())

    return true
  end

  if tu.dig(G, { "GAME", "viewed_back", "effect", "center" }) and direction[key] then
    navigate_deck_and_stake(key)
    return true
  end

  if (key == layout.proceed or key == layout.enter) and try_start() then return true end

  return false
end

local function is_seed_input_hook_active()
  local hook = G.CONTROLLER.text_input_hook
  if not hook then return false end

  return is_new_run()
    and G.run_setup_seed
    and tu.dig(hook, { "config", "ref_table", "ref_value" }) == "setup_seed"
end
M.start_from_seed_input = function(key)
  local k = string.lower(key)
  if k == " " then k = "space" end

  if not (k == layout.proceed or k == layout.enter) or not is_seed_input_hook_active() then
    return false
  end
  if not G.setup_seed or G.setup_seed == "" then return false end

  local start_button = get_clickable_start_button()
  if not start_button then return false end

  G.FUNCS.start_setup_run(start_button)
  return true
end
M.disable_and_unfocus_seed_input = function()
  if not is_seed_input_hook_active() then return false end

  G.CONTROLLER.text_input_hook = nil
  G.run_setup_seed = false
  G.FUNCS.toggle_seeded_run(get_seed_toggle())
  return true
end

return M
