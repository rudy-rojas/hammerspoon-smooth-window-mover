-- Configuration for moving window to next desktop with smooth transition
-- Key combination: shift + ctrl + opt + cmd + right arrow

-- Constants
local SLIDE_ANIMATION_DURATION = 0.2
local FAST_ANIMATION_DURATION = 0.08
local DESKTOP_TRANSITION_DELAY = 0.05
local WINDOW_FOCUS_DELAY = 0.15
local ALERT_DELAY = 0.5
local ALERT_DURATION = 0.8

-- Helper function to get window and space information
local function getWindowSpaceInfo(win)
    if not win then
        return nil, "No active window"
    end
    
    local currentSpaces = hs.spaces.windowSpaces(win)
    if not currentSpaces or #currentSpaces == 0 then
        return nil, "Could not get current space"
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
        return nil, "Only one desktop available"
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
        return nil, "Could not determine current desktop"
    end
    
    return {
        currentSpace = currentSpace,
        screenSpaces = screenSpaces,
        currentIndex = currentIndex
    }
end

-- Helper function to calculate target desktop index
local function getTargetIndex(currentIndex, totalSpaces, direction)
    if direction == "next" then
        local nextIndex = currentIndex + 1
        return nextIndex > totalSpaces and 1 or nextIndex
    else -- direction == "prev"
        local prevIndex = currentIndex - 1
        return prevIndex < 1 and totalSpaces or prevIndex
    end
end

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
    hs.window.animationDuration = SLIDE_ANIMATION_DURATION
    
    -- Animate the window by its width
    window:setFrame(targetFrame, hs.window.animationDuration)
    
    -- After the animation finishes, execute callback
    hs.timer.doAfter(hs.window.animationDuration + 0.05, function()
        if callback then
            callback(originalFrame)  -- Pass the original position to the callback
        end
    end)
end

-- Generic function to move window to desktop with optional visual effect
local function moveWindowToDesktop(direction, withVisualEffect)
    local win = hs.window.focusedWindow()
    
    local spaceInfo, errorMsg = getWindowSpaceInfo(win)
    if not spaceInfo then
        if errorMsg and withVisualEffect then
            hs.alert.show(errorMsg)
        end
        return
    end
    
    local targetIndex = getTargetIndex(spaceInfo.currentIndex, #spaceInfo.screenSpaces, direction)
    local targetSpace = spaceInfo.screenSpaces[targetIndex]
    local originalFrame = win:frame()
    
    -- Determine control key for desktop transition
    local controlKey = (direction == "next") and "right" or "left"
    
    -- Function to execute after slide (or immediately for fast version)
    local executeTransition = function(frameToRestore)
        -- Move the window to the target space
        hs.spaces.moveWindowToSpace(win, targetSpace)
        
        -- Execute desktop transition
        hs.eventtap.keyStroke({"ctrl"}, controlKey, 0)
        
        -- After transition, reposition the window and show message in destination desktop
        hs.timer.doAfter(DESKTOP_TRANSITION_DELAY, function()
            win:setFrame(frameToRestore, withVisualEffect and 0.1 or 0.05)
            
            hs.timer.doAfter(WINDOW_FOCUS_DELAY, function()
                win:focus()
                -- Show visual feedback in the destination desktop
                local alertDelay = withVisualEffect and ALERT_DELAY or 0.1
                hs.timer.doAfter(alertDelay, function()
                    hs.alert.show(string.format("     Desktop %d     ", targetIndex), ALERT_DURATION)
                end)
            end)
        end)
    end
    
    if withVisualEffect then
        -- Execute with visual displacement
        local slideDirection = (direction == "next") and "right" or "left"
        slideWindowByWidth(win, slideDirection, executeTransition)
    else
        -- Execute fast transition without visual effect
        hs.window.animationDuration = FAST_ANIMATION_DURATION
        executeTransition(originalFrame)
    end
end

-- Main functions using the generic function
function moveWindowToNextDesktop()
    moveWindowToDesktop("next", true)
end

function moveWindowToPrevDesktop()
    moveWindowToDesktop("prev", true)
end

function moveWindowToNextDesktopFast()
    moveWindowToDesktop("next", false)
end

function moveWindowToPrevDesktopFast()
    moveWindowToDesktop("prev", false)
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
hs.window.animationDuration = FAST_ANIMATION_DURATION  -- Faster animations globally

-- Confirmation message when loading the script
hs.alert.show("Script loaded", 1.5)