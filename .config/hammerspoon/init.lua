hs.hotkey.bind({"ctrl", "alt"}, "t", function()
  hs.application.launchOrFocus("Ghostty")
end)

-- Window snapping (like Linux)
local function snap(unitRect)
  local win = hs.window.focusedWindow()
  if not win then return end
  hs.window.animationDuration = 0
  win:move(unitRect, nil, true, 0)
end

hs.hotkey.bind({"ctrl", "alt"}, "left",  function() snap({x=0,   y=0, w=0.5, h=1}) end)
hs.hotkey.bind({"ctrl", "alt"}, "right", function() snap({x=0.5, y=0, w=0.5, h=1}) end)
hs.hotkey.bind({"ctrl", "alt"}, "up",    function() snap({x=0,   y=0, w=1,   h=1}) end)
hs.hotkey.bind({"ctrl", "alt"}, "down",  function() snap({x=0.25,y=0.25,w=0.5,h=0.5}) end)

hs.hotkey.bind({"ctrl", "shift"}, "s", function()
  hs.task.new("/usr/sbin/screencapture", nil, {"-i", "-c"}):start()
end)
