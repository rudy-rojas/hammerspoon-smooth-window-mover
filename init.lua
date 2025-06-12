-- Configuration for moving window to next desktop with smooth transition
-- Key combination: shift + ctrl + opt + cmd + right arrow

-- Constants
local SLIDE_ANIMATION_DURATION = 0.2
local FAST_ANIMATION_DURATION = 0.08
local BOUNCE_ANIMATION_DURATION = 0.15
local BOUNCE_RETURN_DURATION = 0.12
local DESKTOP_TRANSITION_DELAY = 0.05
local WINDOW_FOCUS_DELAY = 0.15
local ALERT_DELAY = 0.50
local ALERT_DURATION = 0.8
local BOUNCE_DISTANCE = 60  -- Distance for bounce animation in pixels
local MIN_SLIDE_DISTANCE = 50  -- Minimum slide displacement when near screen edges

-- Canvas management variables (reused from workspace switcher)
local activeCanvas = {}
local canvasCleanupTimer = nil

-- =============================================================================
-- CANVAS ALERT SYSTEM (reused from workspace switcher script)
-- =============================================================================

-- Function to get ordered monitors (reusable)
local function getOrderedMonitors()
    local screens = hs.screen.allScreens()
    local primaryScreen = hs.screen.primaryScreen()
    
    table.sort(screens, function(a, b)
        if a == primaryScreen then return true end
        if b == primaryScreen then return false end
        return a:name() < b:name()
    end)
    
    return screens
end

local function clearAllCanvas()
    for i = #activeCanvas, 1, -1 do
        local canvas = activeCanvas[i]
        if canvas then
            canvas:delete()
        end
        table.remove(activeCanvas, i)
    end
end

-- Enhanced function to show alert with canvas management
function showCanvasAlert(message, targetMonitor, duration)
    -- Clean previous canvas before creating a new one
    clearAllCanvas()
    
    local screens = getOrderedMonitors()
    local targetScreen = nil
    
    -- If targetMonitor is a number, get the screen by index
    if type(targetMonitor) == "number" then
        targetScreen = screens[targetMonitor]
    else
        -- If targetMonitor is a screen object, use it directly
        targetScreen = targetMonitor
    end
    
    -- If no target screen specified, use the current screen
    if not targetScreen then
        targetScreen = hs.screen.mainScreen()
    end
    
    if not targetScreen then return end

    local frame = targetScreen:frame()
    local width, height = 200, 50  -- Slightly wider for desktop messages
    local x = frame.x + (frame.w - width) / 2
    local y = frame.y + (frame.h - height) / 4

    local textSize = 18
    local textHeight = textSize + 6
    local textY = (height - textHeight) / 2

    local canvas = hs.canvas.new{
        x = x, y = y, w = width, h = height
    }:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = {red=0, green=0, blue=0, alpha=0.8},
        roundedRectRadii = {xRadius=12, yRadius=12}
    },{
        type = "text",
        text = message,
        textSize = textSize,
        textColor = {white=1, alpha=1},
        textAlignment = "center",
        frame = {x=0, y=textY, w=width, h=textHeight}
    })

    canvas:level(hs.canvas.windowLevels.overlay)
    canvas:show()
    
    -- Add canvas to tracking table
    table.insert(activeCanvas, canvas)

    -- Cancel previous timer if exists
    if canvasCleanupTimer then
        canvasCleanupTimer:stop()
        canvasCleanupTimer = nil
    end

    -- Create new timer to clean up
    canvasCleanupTimer = hs.timer.doAfter(duration or 1.0, function()
        clearAllCanvas()
        canvasCleanupTimer = nil
    end)
end

-- Forced cleanup function (useful for debugging)
function clearCanvas()
    clearAllCanvas()
    if canvasCleanupTimer then
        canvasCleanupTimer:stop()
        canvasCleanupTimer = nil
    end
    print("Canvas cleaned manually")
end

-- =============================================================================
-- WINDOW MOVEMENT FUNCTIONS (original functionality)
-- =============================================================================

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

-- Helper function to check if movement is possible and get target index
local function getTargetIndex(currentIndex, totalSpaces, direction)
    if direction == "next" then
        if currentIndex >= totalSpaces then
            return nil, "at_last"  -- At the last desktop, can't go further
        end
        return currentIndex + 1, "valid"
    else -- direction == "prev"
        if currentIndex <= 1 then
            return nil, "at_first"  -- At the first desktop, can't go back
        end
        return currentIndex - 1, "valid"
    end
end

-- Function to create visual displacement by window width
function slideWindowByWidth(window, direction, callback)
    local originalFrame = window:frame()
    local screen = window:screen()
    local screenFrame = screen:frame()
    
    -- Calculate final position (displace by the window's width or available space)
    local targetFrame = hs.geometry.copy(originalFrame)
    
    if direction == "right" then
        -- Calculate available space to the right
        local availableSpace = (screenFrame.x + screenFrame.w) - (originalFrame.x + originalFrame.w)
        -- Move by window width, available space, or minimum slide distance - whichever ensures visibility
        local displacement = math.max(MIN_SLIDE_DISTANCE, math.min(originalFrame.w, availableSpace))
        targetFrame.x = originalFrame.x + displacement
    else -- direction == "left"
        -- Calculate available space to the left  
        local availableSpace = originalFrame.x - screenFrame.x
        -- Move by window width, available space, or minimum slide distance - whichever ensures visibility
        local displacement = math.max(MIN_SLIDE_DISTANCE, math.min(originalFrame.w, availableSpace))
        targetFrame.x = originalFrame.x - displacement
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

-- Function to create bounce animation when no more desktops are available
function bounceWindow(window, direction, callback)
    local originalFrame = window:frame()
    local screen = window:screen()
    local screenFrame = screen:frame()
    
    -- Calculate bounce position
    local bounceFrame = hs.geometry.copy(originalFrame)
    
    if direction == "right" then
        -- Bounce to the right, but respect screen boundaries
        local availableSpace = (screenFrame.x + screenFrame.w) - (originalFrame.x + originalFrame.w)
        local bounceDistance = math.min(BOUNCE_DISTANCE, availableSpace)
        bounceFrame.x = originalFrame.x + bounceDistance
    else -- direction == "left"
        -- Bounce to the left, but respect screen boundaries
        local availableSpace = originalFrame.x - screenFrame.x
        local bounceDistance = math.min(BOUNCE_DISTANCE, availableSpace)
        bounceFrame.x = originalFrame.x - bounceDistance
    end
    
    -- Configure bounce animation
    hs.window.animationDuration = BOUNCE_ANIMATION_DURATION
    
    -- First animation: bounce out
    window:setFrame(bounceFrame, hs.window.animationDuration)
    
    -- Second animation: return to original position
    hs.timer.doAfter(BOUNCE_ANIMATION_DURATION + 0.02, function()
        hs.window.animationDuration = BOUNCE_RETURN_DURATION
        window:setFrame(originalFrame, hs.window.animationDuration)
        
        -- Execute callback after bounce is complete
        hs.timer.doAfter(BOUNCE_RETURN_DURATION + 0.02, function()
            if callback then
                callback()
            end
        end)
    end)
end

-- Generic function to move window to desktop with optional visual effect
local function moveWindowToDesktop(direction, withVisualEffect)
    local win = hs.window.focusedWindow()
    
    local spaceInfo, errorMsg = getWindowSpaceInfo(win)
    if not spaceInfo then
        if errorMsg and withVisualEffect then
            -- Use canvas alert instead of hs.alert.show
            showCanvasAlert(errorMsg, win and win:screen(), ALERT_DURATION)
        end
        return
    end
    
    local targetIndex, status = getTargetIndex(spaceInfo.currentIndex, #spaceInfo.screenSpaces, direction)
    
    -- If movement is not possible, show bounce animation
    if status ~= "valid" then
        if withVisualEffect then
            local slideDirection = (direction == "next") and "right" or "left"
            
            bounceWindow(win, slideDirection, function()
                -- Only bounce effect, no message
            end)
        else
            -- For fast version, do nothing (no bounce, no message)
        end
        return
    end
    
    -- Continue with normal movement if valid
    local targetSpace = spaceInfo.screenSpaces[targetIndex]
    local originalFrame = win:frame()
    local windowScreen = win:screen()
    
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
                -- Show visual feedback in the destination desktop using canvas
                local alertDelay = withVisualEffect and ALERT_DELAY or 0.1
                hs.timer.doAfter(alertDelay, function()
                    -- Use canvas alert instead of hs.alert.show
                    showCanvasAlert(string.format("Desktop %d", targetIndex), windowScreen, ALERT_DURATION)
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

-- =============================================================================
-- KEYBOARD SHORTCUTS
-- =============================================================================

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

-- =============================================================================
-- CONTROL FUNCTIONS
-- =============================================================================

-- Window mover control functions
hs.windowMover = {
    clearCanvas = clearCanvas,
    moveNext = moveWindowToNextDesktop,
    movePrev = moveWindowToPrevDesktop,
    moveNextFast = moveWindowToNextDesktopFast,
    movePrevFast = moveWindowToPrevDesktopFast,
    test = function()
        local win = hs.window.focusedWindow()
        if win then
            showCanvasAlert("Window Mover Test", win:screen(), 2.0)
        else
            showCanvasAlert("No focused window", nil, 2.0)
        end
    end,
    status = function()
        print("Window Mover Status:")
        print("- Active canvas:", #activeCanvas)
        local win = hs.window.focusedWindow()
        if win then
            print("- Focused window:", win:title())
            print("- Window screen:", win:screen():name())
        else
            print("- No focused window")
        end
    end
}

-- Additional configuration to optimize transitions
hs.window.animationDuration = FAST_ANIMATION_DURATION  -- Faster animations globally

-- Clean canvas when reloading script
clearAllCanvas()

-- Confirmation message when loading the script
-- print("=== WINDOW MOVER WITH CANVAS ALERTS LOADED ===")
-- print("• shift + ctrl + alt + cmd + arrows: Move with animation")
-- print("• shift + ctrl + alt + cmd + up/down: Fast move")
-- print("• Use hs.windowMover.test() to test canvas")
-- print("• Use hs.windowMover.clearCanvas() to clear stuck canvas")
-- print("====================================================")