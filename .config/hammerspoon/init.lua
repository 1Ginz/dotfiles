hs.hotkey.bind({"ctrl", "alt"}, "t", function()
  hs.application.launchOrFocus("Ghostty")
end)

hs.hotkey.bind({"ctrl", "shift"}, "s", function()
  hs.task.new("/usr/sbin/screencapture", nil, {"-i", "-c"}):start()
end)
