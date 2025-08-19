local tu = require("typist.lib.tblutils")

local M = {}

tu.add_metavalues(M, {
  builtin_layouts = tu.add_metavalues(
    { "qwerty", "dvorak", "qwerty_1hand_right", "workman" },
    { default = "qwerty" }
  ),
  tostring = function()
    --TODO:!
    -- return "keymap = " .. tu.dump_to_string(M) .. '\nlayout_name = "' .. M.current_layout .. '"'
    return ""
  end,
  -- stylua: ignore
  print = function()
    --TODO:!
    -- io.write("keymap = ") tu.dump_to_stdout(M) io.write('\nlayout_name = "' .. M.current_layout ..'"')
  end,
})

local layout
local layout_name_on_disk = love.filesystem.getInfo("typist-layout")
  and love.filesystem.read("typist-layout"):gsub("%s+", "")
if tu.list_index_of(M.builtin_layouts, layout_name_on_disk) then
  layout = layout_name_on_disk
else
  require("typist.lib.log")(
    "found invalid layout name `"
      .. layout_name_on_disk
      .. "` on disk, will default to `"
      .. M.builtin_layouts.default
      .. "`"
  )
  layout = M.builtin_layouts.default
end

tu.add_metavalues(M, { current_layout = layout })

local overrides = love.filesystem.getInfo("typist-overrides.lua")
  and love.filesystem.load("typist-overrides.lua")

local is_mac = love.system.getOS() == "OS X"
M.debug_leader_left = is_mac and "lgui" or "lctrl"
M.debug_leader_right = is_mac and "rgui" or "rctrl"

M.unacorn_card = "\\"
M.preview_deck = ({
  dvorak = ";",
  qwerty = "z",
  workman = "z",
  --TODO: qwerty_1hand_right = "s",
})[layout]

M.proceed = "space"
M.dismiss = "tab"
M.reroll = "r"
M.skip = "s"
M.buy = ({
  dvorak = "j",
  qwerty = "c",
  workman = "m",
  qwerty_1hand_right = "l",
})[layout]
M.buy_and_use = ({
  dvorak = "k",
  qwerty = "v",
  workman = "c",
  qwerty_1hand_right = "o",
})[layout]

M.enter = "return"
M.escape = "escape"

-- stylua: ignore
M.free_select_map = ({
  dvorak = tu.enum {
    "a", "o", "e", "u", "i";
    "d", "h", "t", "n", "s";
    "f", "g", "c", "r", "l";
    "'", ",", ".", "p", "y";
  },
  qwerty = tu.enum {
    "a", "s", "d", "f", "g";
    "h", "j", "k", "l", ";";
    "y", "u", "i", "o", "p";
    "q", "w", "e", "r", "t";
  },
  workman = tu.enum {
    "a", "s", "h", "t", "g";
    "y", "n", "e", "o", "i";
    "j", "f", "u", "p", ";";
    "b", "w", "r", "d", "q";
  },
  qwerty_1hand_right = tu.enum {
    --[[ "d", ]] "f", "g", "h", "j", "k";
    --[[ "e", ]] "r", "t", "y", "u", "i";
    --[[ "c", ]] "v", "b", "n", "m", ",";
  },
})[layout]
-- stylua: ignore
M.top_area_free_select_map = {
  ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5;
  ["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9, ["0"] = 10;
  -- ["kp7"] = 1, ["kp8"] = 2, ["kp9"] = 3;
  -- ["kp4"] = 4, ["kp5"] = 5, ["kp6"] = 6;
  -- ["kp1"] = 7, ["kp2"] = 8, ["kp3"] = 9;
}
local function stitch(keymap, impls, l)
  local res = {}
  for k, v in pairs(impls) do
    res[keymap[k][l]] = v
  end
  return res
end

local global = tu.enum { "RUN_INFO", "OPTIONS" }
M.global_map = stitch({
  [global.RUN_INFO] = {
    dvorak = "q",
    qwerty = "x",
    workman = "x",
    --TODO:
    qwerty_1hand_right = false,
  },
  [global.OPTIONS] = {
    dvorak = M.escape,
    qwerty = M.escape,
    workman = M.escape,
    --TODO:
    qwerty_1hand_right = false,
  },
}, {
  [global.RUN_INFO] = function()
    if G.HUD and G.HUD:get_UIE_by_ID("run_info_button").config.button then G.FUNCS.run_info() end
  end,
  [global.OPTIONS] = function()
    if not G.OVERLAY_MENU then G.FUNCS:options() end
  end,
}, layout)

local cardarea = tu.enum { "HAND", "JOKERS", "CONSUMEABLES" }
-- stylua: ignore
M.cardarea_map = stitch({
  [cardarea.HAND] = {
    dvorak = "z",
    qwerty = "/",
    workman = "/",
    qwerty_1hand_right = "l",
  },
  [cardarea.JOKERS] = {
    dvorak = "/",
    qwerty = "[",
    workman = "[",
    qwerty_1hand_right = "a",
  },
  [cardarea.CONSUMEABLES] = {
    dvorak = "-",
    qwerty = "'",
    workman = "'",
    qwerty_1hand_right = "s",
  },
}, {
  [cardarea.HAND] = function() return G.hand end,
  [cardarea.JOKERS] = function() return G.jokers end,
  [cardarea.CONSUMEABLES] = function() return G.consumeables end,
}, layout)
--TODO: qwerty_1hand_right?
M.select_multiple_right = "rshift"
M.select_multiple_left = "lshift"

local function subscript_fields(keymap, l)
  local res = {}
  for k, v in pairs(keymap) do
    res[k] = v[l]
  end
  return res
end

M.hand = subscript_fields({
  deselect_all = {
    dvorak = "b",
    qwerty = "n",
    workman = "k",
    qwerty_1hand_right = "e",
  },
  invert_selection = {
    dvorak = "m",
    qwerty = "m",
    workman = "l",
    qwerty_1hand_right = "w",
  },
  left5 = {
    dvorak = "w",
    qwerty = ",",
    workman = "d",
  },
  right5 = {
    dvorak = "v",
    qwerty = ".",
    workman = ".",
  },
  reorder_by_enhancements = {
    dvorak = "x",
    qwerty = "b",
    workman = "v",
  },
  sort_by_rank = {
    dvorak = "k",
    qwerty = "v",
    workman = "c",
    --TODO: qwerty_1hand_right = "z",
  },
  sort_by_suit = {
    dvorak = "j",
    qwerty = "c",
    workman = "m",
    --TODO: qwerty_1hand_right = "x",
  },
  cycle_sort_orders = {
    qwerty_1hand_right = "c",
    -- TODO: delete me
    dvorak = "kp0",
  },
}, layout)

--stylua: ignore
M.cheat = tu.override_merge(subscript_fields({
  leader_right = {
    dvorak = "l",
    qwerty = "p",
    workman = ";",
  },
  leader_left = {
    dvorak = "'",
    qwerty = "q",
    workman = "q",
  },
}, layout), {
  best_hand = "b",
  best_flush = "f",
  suits_map = { s = "Spades", d = "Diamonds", c = "Clubs", h = "Hearts" },
  ranks_map =  {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8,
    ["9"] = 9, ["0"] = 10, ["1"] = 10, ["j"] = 11, ["q"] = 12, ["k"] = 13, ["a"] = 14,
  },
  reverse_left = "lshift",
  reverse_right = "rshift",
})

if overrides then
  local chunk = overrides()
  if type(chunk) == "function" then
    M = tu.deep_merge(M, chunk(M))
  elseif type(chunk) == "table" then
    M = tu.deep_merge(M, chunk)
  else
    error(
      "`typist-overrides.lua` is invalid: expected a function or table, got "
        .. type(chunk)
        .. " instead"
    )
  end
end

return M
