if SMODS then
  SMODS.Atlas { key = "modicon", path = "avatar.png", px = 34, py = 34 }
else
  require("typist.lib.log")("This file is meaningless without the `SMODS` runtime")
end
