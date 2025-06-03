-- Configuration for moving window to next desktop with smooth transition
-- Key combination: shift + ctrl + opt + cmd + right arrow

-- Function to create visual displacement by window width
function slideWindowByWidth(window, direction, callback)
    local originalFrame = window:frame()
    
    -- Calculate final position (displace by the window's width)
    local targetFrame = hs.geometry.copy(originalFrame)
    
    if direction == "right" then
        -- Move to the right by the full width of the window
        targetFrame.x = originalFrame.x + originalFrame.w
    else -- direction == "left"
        -- Move to the left by the full width of the window
        targetFrame.x = originalFrame.x - originalFrame.w
    end
    
    -- Configure smooth and fast animation
    hs.window.animationDuration = 0.2  -- Duration of displacement (faster)
    
    -- Animate the window by its width
    window:setFrame(targetFrame, hs.window.animationDuration)
    
    -- After the animation finishes, execute callback
    hs.timer.doAfter(hs.window.animationDuration + 0.05, function()
        if callback then
            callback(originalFrame)  -- Pass the original position to the callback
        end
    end)
end

-- Main function to move window to next desktop
function moveWindowToNextDesktop()
    local win = hs.window.focusedWindow()
    
    if not win then
        hs.alert.show("No active window")
        return
    end
    
    -- Get current window information
    local app = win:application()
    local windowTitle = win:title()
    local windowFrame = win:frame()
    
    -- Get current space
    local currentSpaces = hs.spaces.windowSpaces(win)
    if not currentSpaces or #currentSpaces == 0 then
        hs.alert.show("Could not get current space")
        return
    end
    
    local currentSpace = currentSpaces[1]
    local allSpaces = hs.spaces.allSpaces()
    
    -- Find all spaces for the current monitor
    local screenSpaces = nil
    for screenUUID, spaces in pairs(allSpaces) do
        for _, spaceID in ipairs(spaces) do
            if spaceID == currentSpace then
                screenSpaces = spaces
                break
            end
        end
        if screenSpaces then break end
    end
    
    if not screenSpaces or #screenSpaces < 2 then
        hs.alert.show("Only one desktop available")
        return
    end
    
    -- Find the index of the current space
    local currentIndex = nil
    for i, spaceID in ipairs(screenSpaces) do
        if spaceID == currentSpace then
            currentIndex = i
            break
        end
    end
    
    if not currentIndex then
        hs.alert.show("Could not determine current desktop")
        return
    end
    
    -- Calculate next space (circular)
    local nextIndex = currentIndex + 1
    if nextIndex > #screenSpaces then
        nextIndex = 1  -- Return to first desktop
    end
    
    local nextSpace = screenSpaces[nextIndex]
    
    -- Create callback for after visual displacement
    local afterSlideCallback = function(originalFrame)
        -- Move the window to the next space
        hs.spaces.moveWindowToSpace(win, nextSpace)
        
        -- Execute desktop transition with Ctrl + Right
        hs.eventtap.keyStroke({"ctrl"}, "right", 0)
        
        -- After transition, reposition the window and show message in destination desktop
        hs.timer.doAfter(0.05, function()  -- Increased delay to ensure desktop transition is complete
            win:setFrame(originalFrame, 0.1)  -- Restore original position
            
            hs.timer.doAfter(0.15, function()
                win:focus()
                -- Show visual feedback in the destination desktop (after window is focused)
                hs.timer.doAfter(0.5, function()
                    hs.alert.show(string.format("     Desktop %d     ", nextIndex), 0.8)
                end)
            end)
        end)
    end
    
    -- Execute visual displacement to the right followed by transition
    slideWindowByWidth(win, "right", afterSlideCallback)
end

-- Function to move window to previous desktop
function moveWindowToPrevDesktop()
    local win = hs.window.focusedWindow()
    
    if not win then 
        hs.alert.show("No active window")
        return 
    end
    
    local windowFrame = win:frame()
    local currentSpaces = hs.spaces.windowSpaces(win)
    if not currentSpaces or #currentSpaces == 0 then return end
    
    local currentSpace = currentSpaces[1]
    local allSpaces = hs.spaces.allSpaces()
    
    local screenSpaces = nil
    for screenUUID, spaces in pairs(allSpaces) do
        for _, spaceID in ipairs(spaces) do
            if spaceID == currentSpace then
                screenSpaces = spaces
                break
            end
        end
        if screenSpaces then break end
    end
    
    if not screenSpaces or #screenSpaces < 2 then return end
    
    local currentIndex = nil
    for i, spaceID in ipairs(screenSpaces) do
        if spaceID == currentSpace then
            currentIndex = i
            break
        end
    end
    
    local prevIndex = currentIndex - 1
    if prevIndex < 1 then
        prevIndex = #screenSpaces
    end
    
    local prevSpace = screenSpaces[prevIndex]
    
    -- Create callback for after visual displacement
    local afterSlideCallback = function(originalFrame)
        -- Capture prevIndex value for use in the callback
        local targetDesktop = prevIndex
        
        -- Move the window to the previous space
        hs.spaces.moveWindowToSpace(win, prevSpace)
        
        -- Execute desktop transition with Ctrl + Left
        hs.eventtap.keyStroke({"ctrl"}, "left", 0)
        
        -- After transition, reposition the window and show message in destination desktop
        hs.timer.doAfter(0.05, function()  -- Increased delay to ensure desktop transition is complete
            win:setFrame(originalFrame, 0.1)  -- Restore original position
            
            hs.timer.doAfter(0.15, function()
                win:focus()
                -- Show visual feedback in the destination desktop (after window is focused)
                hs.timer.doAfter(0.5, function()
                    hs.alert.show(string.format("     Desktop %d     ", targetDesktop), 0.8)
                end)
            end)
        end)
    end
    
    -- Execute visual displacement to the left followed by transition
    slideWindowByWidth(win, "left", afterSlideCallback)
end

-- Alternative function with more direct and fast transition (WITHOUT visual displacement)
function moveWindowToNextDesktopFast()
    local win = hs.window.focusedWindow()
    
    if not win then
        return
    end
    
    local currentSpaces = hs.spaces.windowSpaces(win)
    if not currentSpaces or #currentSpaces == 0 then
        return
    end
    
    local currentSpace = currentSpaces[1]
    local allSpaces = hs.spaces.allSpaces()
    
    -- Find spaces for current monitor
    local screenSpaces = nil
    for screenUUID, spaces in pairs(allSpaces) do
        for _, spaceID in ipairs(spaces) do
            if spaceID == currentSpace then
                screenSpaces = spaces
                break
            end
        end
        if screenSpaces then break end
    end
    
    if not screenSpaces or #screenSpaces < 2 then
        return
    end
    
    -- Find next space
    local currentIndex = nil
    for i, spaceID in ipairs(screenSpaces) do
        if spaceID == currentSpace then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = currentIndex + 1
    if nextIndex > #screenSpaces then
        nextIndex = 1
    end
    
    local nextSpace = screenSpaces[nextIndex]
    local originalFrame = win:frame()
    
    -- Ultra fast transition
    hs.window.animationDuration = 0.08
    
    -- Move window and change desktop almost simultaneously
    hs.spaces.moveWindowToSpace(win, nextSpace)
    hs.eventtap.keyStroke({"ctrl"}, "right", 0)
    
    -- Reposition window and show message in destination desktop
    hs.timer.doAfter(0.15, function()  -- Increased delay for desktop transition
        win:setFrame(originalFrame, 0.05)
        win:focus()
        -- Show message in destination desktop
        hs.timer.doAfter(0.1, function()
            hs.alert.show(string.format("     Desktop %d     ", nextIndex), 0.8)
        end)
    end)
end

-- Fast function for previous desktop (WITHOUT visual displacement)
function moveWindowToPrevDesktopFast()
    local win = hs.window.focusedWindow()
    
    if not win then return end
    
    local currentSpaces = hs.spaces.windowSpaces(win)
    if not currentSpaces or #currentSpaces == 0 then return end
    
    local currentSpace = currentSpaces[1]
    local allSpaces = hs.spaces.allSpaces()
    
    local screenSpaces = nil
    for screenUUID, spaces in pairs(allSpaces) do
        for _, spaceID in ipairs(spaces) do
            if spaceID == currentSpace then
                screenSpaces = spaces
                break
            end
        end
        if screenSpaces then break end
    end
    
    if not screenSpaces or #screenSpaces < 2 then return end
    
    local currentIndex = nil
    for i, spaceID in ipairs(screenSpaces) do
        if spaceID == currentSpace then
            currentIndex = i
            break
        end
    end
    
    local prevIndex = currentIndex - 1
    if prevIndex < 1 then
        prevIndex = #screenSpaces
    end
    
    local prevSpace = screenSpaces[prevIndex]
    local originalFrame = win:frame()
    
    -- Capture prevIndex for use in callback
    local targetDesktop = prevIndex
    
    hs.window.animationDuration = 0.08
    hs.spaces.moveWindowToSpace(win, prevSpace)
    hs.eventtap.keyStroke({"ctrl"}, "left", 0)
    
    -- Reposition window and show message in destination desktop
    hs.timer.doAfter(0.15, function()  -- Increased delay for desktop transition
        win:setFrame(originalFrame, 0.05)
        win:focus()
        -- Show message in destination desktop
        hs.timer.doAfter(0.1, function()
            hs.alert.show(string.format("     Desktop %d     ", targetDesktop), 0.8)
        end)
    end)
end

-- Configure main keyboard shortcuts (WITH visual displacement)
-- shift + ctrl + opt + cmd + right arrow
hs.hotkey.bind({"shift", "ctrl", "alt", "cmd"}, "right", function()
    moveWindowToNextDesktop()  -- WITH visual displacement to the right edge
end)

-- shift + ctrl + opt + cmd + left arrow
hs.hotkey.bind({"shift", "ctrl", "alt", "cmd"}, "left", function()
    moveWindowToPrevDesktop()  -- WITH visual displacement to the left edge
end)

-- Alternative shortcuts for fast versions (WITHOUT visual displacement)
-- shift + ctrl + opt + cmd + up arrow (fast to next)
hs.hotkey.bind({"shift", "ctrl", "alt", "cmd"}, "up", function()
    moveWindowToNextDesktopFast()  -- WITHOUT visual displacement
end)

-- shift + ctrl + opt + cmd + down arrow (fast to previous)
hs.hotkey.bind({"shift", "ctrl", "alt", "cmd"}, "down", function()
    moveWindowToPrevDesktopFast()  -- WITHOUT visual displacement
end)

-- Additional configuration to optimize transitions
hs.window.animationDuration = 0.08  -- Faster animations globally

-- Confirmation message when loading the script
hs.alert.show("Script loaded", 1.5)
