local tu = require("typist.lib.tblutils")

local layout = require("typist.mod.layout")

local M = {}

M.is_new_run = function()
  return G.OVERLAY_MENU and G.SETTINGS.current_setup == "New Run"
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
M.enable_and_focus_seed_input = function()
  local toggle = get_seed_toggle()

  if not G.run_setup_seed or not get_seed_input() then
    G.run_setup_seed = true
    G.FUNCS.toggle_seeded_run(toggle)
  end

  ---@diagnostic disable-next-line: param-type-mismatch -- if it's nil after we've just created it then we're fucked anyway
  G.FUNCS.select_text_input(get_seed_input())
  return true
end

M.try_start = function()
  local start_button = get_clickable_start_button()
  if not start_button then return false end

  G.FUNCS.start_setup_run(start_button)
  return true
end

M.is_seed_input_hook_active = function()
  local hook = G.CONTROLLER.text_input_hook
  if not hook then return false end

  return M.is_new_run()
    and G.run_setup_seed
    and tu.dig(hook, { "config", "ref_table", "ref_value" }) == "setup_seed"
end

M.start_from_seed_input = function(key)
  local k = string.lower(key)
  if k == " " then k = "space" end

  if not (k == layout.proceed or k == layout.enter) or not M.is_seed_input_hook_active() then
    return false
  end
  if not G.setup_seed or G.setup_seed == "" then return false end

  local start_button = get_clickable_start_button()
  if not start_button then return false end

  G.FUNCS.start_setup_run(start_button)
  return true
end

M.disable_and_unfocus_seed_input = function()
  if not M.is_seed_input_hook_active() then return false end

  G.CONTROLLER.text_input_hook = nil
  G.run_setup_seed = false
  G.FUNCS.toggle_seeded_run(get_seed_toggle())
  return true
end

return M
