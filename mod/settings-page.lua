local layout = require("typist.mod.layout")
local tu = require("typist.lib.tblutils")

local M = {}

-- TODO: insert a tab in the settings menu instead of an extra menu just for typist
-- TODO: add the settings page in the smods menu instead of options if present
M.insert_settings_page_button = function(options_menu_ui)
  table.insert(
    options_menu_ui.nodes[1].nodes[1].nodes[1].nodes,
    #options_menu_ui.nodes[1].nodes[1].nodes[1].nodes + 1,
    UIBox_button {
      minw = 5,
      button = "__typist_draw_settings_page",
      label = { "Typist Settings" },
      colour = { 0.643, 0.404, 0.776, 1 }, -- #a467c6
    }
  )
  return options_menu_ui
end

G.FUNCS.__typist_draw_settings_page = function()
  G.FUNCS.overlay_menu {
    definition = create_UIBox_generic_options {
      back_func = "options",
      contents = { M.settings_page_ui() },
    },
    config = { offset = { x = 0, y = 10 } },
  }
end

local dynamic_ui_text = {}
local function create_dynamic_textbox(name, initial_value)
  dynamic_ui_text[name] = type(initial_value) == "function" and initial_value()
    or initial_value
    or dynamic_ui_text[name]
    or ""
  return {
    n = G.UIT.R,
    config = { align = "cm", padding = 0 },
    nodes = {
      {
        n = G.UIT.O,
        config = {
          id = "__typist_" .. name,
          object = DynaText {
            string = { { ref_table = dynamic_ui_text, ref_value = name } },
            colours = { G.C.RED },
            silent = true,
            scale = 0.45,
          },
        },
      },
    },
  }
end
M.settings_page_ui = function()
  local layout_name_on_disk = love.filesystem.getInfo("typist-layout")
      and love.filesystem.read("typist-layout"):gsub("%s+", "")
    or layout.current_layout

  G.FUNCS.__typist_update_and_save_settings_state { to_val = layout_name_on_disk }

  return create_tabs {
    snap_to_nav = true,
    tabs = {
      {
        label = "Typist Settings",
        chosen = true,
        tab_definition_function = function()
          return {
            n = G.UIT.ROOT,
            config = {
              emboss = 0.05,
              minh = 6,
              r = 0.1,
              minw = 10,
              align = "cm",
              padding = 0.2,
              colour = G.C.BLACK,
            },
            nodes = {
              create_option_cycle {
                label = "Keyboard Layout",
                scale = 0.8,
                w = 4,
                options = layout.builtin_layouts,
                opt_callback = "__typist_update_and_save_settings_state",
                current_option = tu.list_index_of(layout.builtin_layouts, layout_name_on_disk),
              },
              create_dynamic_textbox("active_layout"),
              create_dynamic_textbox("restart_required"),
            },
          }
        end,
      },
    },
  }
end

local restart_required
local should_notify_of_layout_change
G.FUNCS.__typist_update_and_save_settings_state = function(x) -- layout change UI callback
  local l = x.to_val
  love.filesystem.write("typist-layout", l)

  restart_required = l ~= layout.current_layout
  should_notify_of_layout_change = restart_required

  dynamic_ui_text.active_layout = "active layout: " .. layout.current_layout
  dynamic_ui_text.restart_required = "restart required: " .. (restart_required and "yes" or "no")
end

-- TODO: maybe don't rely on `require` to generate a static layout table, and allow changing the layout on the fly instead?
M.draw_layout_change_notification = function()
  if not should_notify_of_layout_change then return end

  G.FUNCS.overlay_menu {
    definition = {
      n = G.UIT.ROOT,
      config = { align = "cm", colour = G.C.CLEAR },
      nodes = {
        {
          n = G.UIT.R,
          config = {
            align = "cm",
            colour = G.C.BLACK,
            padding = 0.2,
            r = 0.1,
          },
          nodes = {
            {
              n = G.UIT.T,
              config = {
                text = "typist layout changed, a restart is required for this change to take effect.",
                scale = 0.4,
                colour = G.C.RED,
              },
            },
          },
        },
      },
    },
    config = { offset = { x = 0, y = -0.5 } },
  }

  should_notify_of_layout_change = false
end

return M
