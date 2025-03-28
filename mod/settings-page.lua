local layout = require("typist.mod.layout")
local tu = require("typist.lib.tblutils")

local layout_changed = false
G.FUNCS.__typist_write_layout = function(x) -- layout change UI callback
  local l = x.to_val
  love.filesystem.write("typist-layout", l)
  print('`typist-layout` set to: "' .. l .. '"')
  layout_changed = l ~= layout.current_layout
end

local original_create_UIBox_options = create_UIBox_options
-- TODO: insert a tab in the settings menu instead of an extra menu just for typist
function create_UIBox_options()
  local contents = original_create_UIBox_options()

  local button = UIBox_button {
    minw = 5,
    button = "__typist_settings_page_ui",
    label = { "Typist Settings" },
    colour = { 0.643, 0.404, 0.776, 1 }, -- #a467c6
  }

  table.insert(
    contents.nodes[1].nodes[1].nodes[1].nodes,
    #contents.nodes[1].nodes[1].nodes[1].nodes + 1,
    button
  )

  return contents
end

-- add layout change notification on menu exit
local original_exit_overlay_menu = G.FUNCS.exit_overlay_menu
G.FUNCS.exit_overlay_menu = function(...)
  original_exit_overlay_menu(...)

  if layout_changed then
    layout_changed = false

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
                  text = "layout changed - restart game",
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

    -- Auto-dismiss after 5 seconds
    G.E_MANAGER:add_event(Event {
      trigger = "after",
      delay = 5,
      func = function()
        G.FUNCS.exit_overlay_menu()
        return true
      end,
    })
  end
end

G.FUNCS.__typist_settings_page_ui = function()
  local tabs = create_tabs {
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
                opt_callback = "__typist_write_layout",
                current_option = tu.list_index_of(layout.builtin_layouts, layout.current_layout),
              },
            },
          }
        end,
      },
    },
  }

  G.FUNCS.overlay_menu {
    definition = create_UIBox_generic_options {
      back_func = "options",
      contents = { tabs },
    },
    config = { offset = { x = 0, y = 10 } },
  }
end
