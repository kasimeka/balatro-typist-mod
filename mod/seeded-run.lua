local tu = require("typist.lib.tblutils")

local M = {}

M.is_new_run_overlay = function()
  return G.STATE == G.STATES.MENU
    and G.OVERLAY_MENU
    and G.SETTINGS.current_setup == "New Run"
    and G.OVERLAY_MENU:get_UIE_by_ID("tab_but_" .. localize("b_new_run"))
end

local function run_setup_seed_row()
  return G.OVERLAY_MENU:get_UIE_by_ID("run_setup_seed")
end

local function seed_toggle_uie()
  return tu.dig(run_setup_seed_row(), { "parent", "parent", "children", 3, "children", 1 })
end

local function seed_input()
  local object = tu.dig(seed_toggle_uie(), { "config", "object" })
  return object:get_UIE_by_ID("text_input")
end

local function start_button_ready()
  local start_button = tu.dig(run_setup_seed_row(), { "parent", "children", 2 })
  G.FUNCS.can_start_run(start_button)
  return start_button.config.button == "start_setup_run" and start_button
end

M.enable_and_focus = function()
  local toggle = seed_toggle_uie()

  if not G.run_setup_seed or not seed_input() then
    G.run_setup_seed = true
    G.FUNCS.toggle_seeded_run(toggle)
  end

  G.FUNCS.select_text_input(seed_input())
  return true
end

M.start_run = function()
  local start_button = start_button_ready()
  if not start_button then return false end
  G.FUNCS.start_setup_run(start_button)
  return true
end

M.seed_input_hook_active = function()
  local hook = G.CONTROLLER.text_input_hook
  if not hook then return false end
  local cfg = hook.config.ref_table
  return M.is_new_run_overlay()
    and G.run_setup_seed
    and cfg
    and cfg.ref_table == G
    and cfg.ref_value == "setup_seed"
end

local releasing_text_input_hook = false
M.submit_from_text_input = function(key)
  if releasing_text_input_hook then return false end
  if (key ~= "RETURN" and key ~= " ") or not M.seed_input_hook_active() then return false end
  if not G.setup_seed or G.setup_seed == "" then return false end

  local start_button = start_button_ready()
  if not start_button then return false end

  releasing_text_input_hook = true
  G.FUNCS.text_input_key { key = "return" }
  releasing_text_input_hook = false

  G.FUNCS.start_setup_run(start_button)
  return true
end

M.disable_from_focused_input = function()
  if not M.seed_input_hook_active() then return false end

  G.CONTROLLER.text_input_hook = nil
  G.run_setup_seed = false
  G.FUNCS.toggle_seeded_run(seed_toggle_uie())
  return true
end

return M
