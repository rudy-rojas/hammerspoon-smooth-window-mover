-- =============================================================================
-- UNIFIED WORKSPACE & WINDOW MOVER SCRIPT - Version 1.5 Tested in macOS Ventura (13.7.6)
-- In theory, it should also work on earlier versions.
-- =============================================================================
-- Combines workspace switcher (Ctrl+number) and window mover (Shift+Ctrl+Alt+Cmd+arrows)

-- =============================================================================
--               SETTINGS
-- =============================================================================

-- local WINDOW_MOVER_MODIFIERS = {"shift", "ctrl", "alt", "cmd"} --DEFAULT
-- local WINDOW_MOVER_MODIFIERS = {"shift", "ctrl"} -- example
local WINDOW_MOVER_MODIFIERS = {"shift", "ctrl", "alt", "cmd"}
showAlert = true

-- =============================================================================
-- SHARED VARIABLES AND CONSTANTS
-- =============================================================================

-- Workspace switcher variables
spacesPerMonitor = {}
desktopIds = {}
currentMonitor = 1
currentDesktop = 1
tableInitialized = false

-- Window mover constants
local SLIDE_ANIMATION_DURATION = 0.2
local FAST_ANIMATION_DURATION = 0.08
local BOUNCE_ANIMATION_DURATION = 0.15
local BOUNCE_RETURN_DURATION = 0.12
local DESKTOP_TRANSITION_DELAY = 0.05
local WINDOW_FOCUS_DELAY = 0.15
local ALERT_DELAY = 0.50
local ALERT_DURATION = 0.8
local BOUNCE_DISTANCE = 60
local MIN_SLIDE_DISTANCE = 50

-- Shortcut detection constants
local SHORTCUT_VERIFICATION_TIMEOUT = 0.3
local SHORTCUT_VERIFICATION_ATTEMPTS = 3

-- Shared canvas management
local activeCanvas = {}
local canvasCleanupTimer = nil

-- =============================================================================
-- SHARED UTILITY FUNCTIONS
-- =============================================================================

-- Function to get ordered monitors (shared by both systems)
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

-- Unified canvas cleanup
local function clearAllCanvas()
    for i = #activeCanvas, 1, -1 do
        local canvas = activeCanvas[i]
        if canvas then
            canvas:delete()
        end
        table.remove(activeCanvas, i)
    end
end

-- Unified canvas alert function with style support
function showCanvasAlert(message, targetMonitor, duration, style)
    if showAlert then
        -- Clean previous canvas before creating a new one
        clearAllCanvas()
        
        style = style or "workspace"  -- "workspace" or "window"
        
        local screens = getOrderedMonitors()
        local targetScreen = nil
        
        -- Handle different target monitor types
        if type(targetMonitor) == "number" then
            targetScreen = screens[targetMonitor]
        else
            targetScreen = targetMonitor  -- Screen object
        end
        
        -- Fallback to main screen if no target specified
        if not targetScreen then
            targetScreen = hs.screen.mainScreen()
        end
        
        if not targetScreen then return end
        -- Style-specific settings
        local width = (style == "workspace") and 220 or 200
        local textSize = (style == "workspace") and 18 or 18
        local alpha = (style == "workspace") and 0.8 or 0.8
        
        -- Color based on message type
        local bgColor = {red=0, green=0, blue=0, alpha=alpha}
        local textColor = {white=1, alpha=1}
        
        -- Check if it's an error/warning message
        if string.find(message:lower(), "disabled") or string.find(message:lower(), "shortcut") then
            bgColor = {red=0.8, green=0.3, blue=0.1, alpha=alpha}  -- Orange-red for warnings
            width = 280
        end
        local frame = targetScreen:frame()
        local height = 50
        local x = frame.x + (frame.w - width) / 2
        local y = frame.y + (frame.h - height) / 4
        local textHeight = textSize + 6
        local textY = (height - textHeight) / 2
        local canvas = hs.canvas.new{
            x = x, y = y, w = width, h = height
        }:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = bgColor,
            roundedRectRadii = {xRadius=12, yRadius=12}
        },{
            type = "text",
            text = message,
            textSize = textSize,
            textColor = textColor,
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
        canvasCleanupTimer = hs.timer.doAfter(duration or 1.5, function()
            clearAllCanvas()
            canvasCleanupTimer = nil
        end)
    end
end



-- Shared cleanup function
function clearCanvas()
    clearAllCanvas()
    if canvasCleanupTimer then
        canvasCleanupTimer:stop()
        canvasCleanupTimer = nil
    end
    print("Canvas cleaned manually")
end

-- Function to open Mission Control shortcuts in System Preferences
function openMissionControlShortcuts()
    local script = [[
        tell application "System Preferences"
            reveal pane id "com.apple.preference.keyboard"
            activate
        end tell
        tell application "System Events"
            tell process "System Preferences"
                repeat with i from 1 to 20
                    try
                        click radio button "Shortcuts" of tab group 1 of window 1
                        exit repeat
                    on error
                        delay 0.1
                    end try
                end repeat
                repeat with i from 1 to 20
                    try
                        select (first row of table 1 of scroll area 1 of splitter group 1 of tab group 1 of window 1 whose value of static text 1 contains "Mission Control")
                        exit repeat
                    on error
                        delay 0.1
                    end try
                end repeat
                -- Scroll hacia abajo
                repeat with i from 1 to 10
                    try
                        tell scroll area 2 of splitter group 1 of tab group 1 of window 1
                            set value of scroll bar 1 to 1.0
                        end tell
                        exit repeat
                    on error
                        delay 0.1
                    end try
                end repeat
                
                -- Animación shake
                set originalPosition to position of window 1
                set originalX to item 1 of originalPosition
                set originalY to item 2 of originalPosition
                
                -- Realizar el shake
                repeat with i from 1 to 6
                    if i mod 2 = 1 then
                        set position of window 1 to {originalX + 10, originalY}
                    else
                        set position of window 1 to {originalX - 10, originalY}
                    end if
                    delay 0.05
                end repeat
                
                -- Restaurar posición original
                set position of window 1 to originalPosition
            end tell
        end tell
    ]]
    
    hs.osascript.applescript(script)
    print("Opening Mission Control shortcuts in System Preferences with shake animation...")
end

-- =============================================================================
-- WORKSPACE SWITCHER SYSTEM (Ctrl + number)
-- =============================================================================

-- Main function to get spaces for each monitor
function getSpacesPerMonitor()
    spacesPerMonitor = {}
    desktopIds = {}
    
    local screens = getOrderedMonitors()
    
    for i, screen in ipairs(screens) do
        local spaces = hs.spaces.spacesForScreen(screen)
        local spaceCount = #spaces
        spacesPerMonitor[i] = spaceCount
        
        for _, spaceId in ipairs(spaces) do
            desktopIds[#desktopIds + 1] = spaceId
        end
    end
    
    tableInitialized = true
    showTable()
end

function showTable()
    print("=== SPACES PER MONITOR ===")
    for i, spaces in ipairs(spacesPerMonitor) do
        local monitorType = (i == 1) and " (Primary)" or ""
        print(string.format("Monitor %d%s: %d spaces", i, monitorType, spaces))
    end
    print("Total stored IDs:", #desktopIds)
end

function update()
    if not tableInitialized then
        getSpacesPerMonitor()
    else
        print("Table already initialized. Use 'forceUpdate()' if you need to update.")
    end
end

function forceUpdate()
    print("Forcing spaces update...")
    getSpacesPerMonitor()
end

function onSpaceChange()
    local screens = getOrderedMonitors()
    
    if #spacesPerMonitor ~= #screens then
        getSpacesPerMonitor()
        return
    end
    
    for i, screen in ipairs(screens) do
        local spaces = hs.spaces.spacesForScreen(screen)
        if #spaces ~= spacesPerMonitor[i] then
            getSpacesPerMonitor()
            return
        end
    end
end

-- Fast and silent monitor activation
function activateMonitorSilently(targetMonitor)
    local screens = getOrderedMonitors()
    local targetScreen = screens[targetMonitor]
    
    if not targetScreen then return false end
    
    local originalPosition = hs.mouse.absolutePosition()
    local currentScreen = hs.mouse.getCurrentScreen()
    
    if currentScreen and currentScreen:id() == targetScreen:id() then
        return true
    end
    
    local frame = targetScreen:frame()
    local monitorCenter = {
        x = frame.x + frame.w / 2,
        y = frame.y + frame.h / 2
    }
    
    hs.mouse.absolutePosition(monitorCenter)
    
    local targetWindow = nil
    local allWindows = hs.window.allWindows()
    
    for _, window in ipairs(allWindows) do
        if window and window:isVisible() and not window:isMinimized() then
            local windowScreen = window:screen()
            if windowScreen and windowScreen:id() == targetScreen:id() then
                targetWindow = window
                break
            end
        end
    end
    
    if targetWindow then
        targetWindow:focus()
    else
        hs.eventtap.leftClick(monitorCenter)
    end
    
    return true
end

function determineMonitorBySpace(spaceNumber)
    local totalSpaces = 0
    for _, spaces in ipairs(spacesPerMonitor) do
        totalSpaces = totalSpaces + spaces
    end
    
    if spaceNumber > totalSpaces then
        return nil
    end
    
    local accumulatedSpaces = 0
    for i, spaces in ipairs(spacesPerMonitor) do
        accumulatedSpaces = accumulatedSpaces + spaces
        if spaceNumber <= accumulatedSpaces then
            return i
        end
    end
    
    return nil
end

-- Enhanced function to verify shortcut execution and detect disabled shortcuts
function verifyShortcutExecution(spaceNumber, targetMonitor, initialSpace, callback)
    local attempts = 0
    local maxAttempts = SHORTCUT_VERIFICATION_ATTEMPTS
    
    local function checkSpaceChange()
        attempts = attempts + 1
        local currentSpace = hs.spaces.focusedSpace()
        local expectedSpace = desktopIds[spaceNumber]
        
        if currentSpace == expectedSpace then
            -- Shortcut worked
            if callback then callback(true) end
            return
        end
        
        if attempts >= maxAttempts then
            -- Shortcut appears to be disabled
            if callback then callback(false) end
            return
        end
        
        -- Try again
        hs.timer.doAfter(SHORTCUT_VERIFICATION_TIMEOUT / maxAttempts, checkSpaceChange)
    end
    
    -- Start verification
    checkSpaceChange()
end

function verifyAndShowAlert(spaceNumber, targetMonitor, attempts)
    attempts = attempts or 1
    local maxAttempts = 4
    
    local initialSpace = hs.spaces.focusedSpace()
    
    -- First, try the shortcut
    hs.eventtap.keyStroke({"ctrl"}, tostring(spaceNumber))
    
    -- Wait a moment then verify if it worked
    hs.timer.doAfter(0.1, function()
        verifyShortcutExecution(spaceNumber, targetMonitor, initialSpace, function(success)
            if success then
                -- Shortcut worked, show success alert
                local currentDesktop = hs.spaces.focusedSpace()
                local expectedDesktop = desktopIds[spaceNumber]
                local screens = getOrderedMonitors()
                local targetScreen = screens[targetMonitor]
                local currentScreen = hs.mouse.getCurrentScreen()
                
                local correctDesktop = (currentDesktop == expectedDesktop)
                local correctMonitor = (currentScreen and targetScreen and currentScreen:id() == targetScreen:id())
                
                if correctDesktop and correctMonitor then
                    showCanvasAlert(string.format("Desktop %d", spaceNumber), targetMonitor, 1.0, "workspace")
                    print(string.format("✓ Alert shown correctly on Desktop %d, Monitor %d", spaceNumber, targetMonitor))
                else
                    -- Force position and show alert
                    if targetScreen then
                        local frame = targetScreen:frame()
                        local center = {
                            x = frame.x + frame.w / 2,
                            y = frame.y + frame.h / 2
                        }
                        hs.mouse.absolutePosition(center)
                    end
                    
                    hs.timer.doAfter(0.05, function()
                        showCanvasAlert(string.format("Desktop %d", spaceNumber), targetMonitor, 1.0, "workspace")
                        print(string.format("✓ Desktop %d activated on Monitor %d", spaceNumber, targetMonitor))
                    end)
                end
            else
                -- Shortcut didn't work - likely disabled
                showCanvasAlert(string.format("Desktop %d shortcut is disabled", spaceNumber), targetMonitor, 2.0, "workspace")
                print(string.format("⚠ Desktop %d shortcut appears to be disabled in System Preferences", spaceNumber))
                
                -- Automatically open Mission Control shortcuts after a brief delay
                hs.timer.doAfter(2.5, function()
                    openMissionControlShortcuts()
                end)
            end
        end)
    end)
end

-- Key code mapping and control variables
local numberKeyCodes = {
    [18] = 1, [19] = 2, [20] = 3, [21] = 4, [23] = 5,
    [22] = 6, [26] = 7, [28] = 8, [25] = 9
}

local processingKey = false
local lastTime = 0

-- Main eventtap for workspace switching
local ctrlNumberTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local flags = event:getFlags()
    local keyCode = event:getKeyCode()
    local currentTime = hs.timer.secondsSinceEpoch()
    
    if flags.ctrl and not flags.cmd and not flags.alt and not flags.shift then
        local number = numberKeyCodes[keyCode]
        
        if number and not processingKey and (currentTime - lastTime) > 0.2 then
            local monitor = determineMonitorBySpace(number)
            
            if monitor then
                processingKey = true
                lastTime = currentTime
                
                local activated = activateMonitorSilently(monitor)
                
                if activated then
                    hs.timer.doAfter(0.01, function()
                        verifyAndShowAlert(number, monitor)
                        currentMonitor = monitor
                        currentDesktop = number
                        
                        hs.timer.doAfter(0.5, function()
                            processingKey = false
                        end)
                    end)
                    
                    return true
                else
                    processingKey = false
                end
            end
        end
    end
    
    return false
end)

-- =============================================================================
-- WINDOW MOVER SYSTEM (Shift + Ctrl + Alt + Cmd + arrows)
-- =============================================================================

-- Helper function to get window and space information
local function getWindowSpaceInfo(win)
    if not win then
        return nil, "No active window"
    end
    
    local currentSpaces = hs.spaces.windowSpaces(win)
    if not currentSpaces or #currentSpaces == 0 then
        -- return nil, "Could not get current space"
        return nil
    end
    
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
    
    if not screenSpaces or #screenSpaces < 2 then
        return nil, "Only one desktop available"
    end
    
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

local function getTargetIndex(currentIndex, totalSpaces, direction)
    if direction == "next" then
        if currentIndex >= totalSpaces then
            return nil, "at_last"
        end
        return currentIndex + 1, "valid"
    else
        if currentIndex <= 1 then
            return nil, "at_first"
        end
        return currentIndex - 1, "valid"
    end
end

function slideWindowByWidth(window, direction, callback)
    local originalFrame = window:frame()
    local screen = window:screen()
    local screenFrame = screen:frame()
    
    local targetFrame = hs.geometry.copy(originalFrame)
    
    -- if direction == "right" then
    --     local availableSpace = (screenFrame.x + screenFrame.w) - (originalFrame.x + originalFrame.w)
    --     local displacement = math.max(MIN_SLIDE_DISTANCE, math.min(originalFrame.w, availableSpace))
    --     targetFrame.x = originalFrame.x + displacement
    -- else
    --     local availableSpace = originalFrame.x - screenFrame.x
    --     local displacement = math.max(MIN_SLIDE_DISTANCE, math.min(originalFrame.w, availableSpace))
    --     targetFrame.x = originalFrame.x - displacement
    -- end
    
    -- hs.window.animationDuration = SLIDE_ANIMATION_DURATION
    -- window:setFrame(targetFrame, hs.window.animationDuration)
    
    hs.timer.doAfter(hs.window.animationDuration + 0.05, function()
        if callback then
            callback(originalFrame)
        end
    end)
end

function bounceWindow(window, direction, callback)
    local originalFrame = window:frame()
    local screen = window:screen()
    local screenFrame = screen:frame()
    
    local bounceFrame = hs.geometry.copy(originalFrame)
    
    if direction == "right" then
        -- Always bounce right by the full BOUNCE_DISTANCE, even if it goes beyond screen
        bounceFrame.x = originalFrame.x + BOUNCE_DISTANCE
    else
        -- Always bounce left by the full BOUNCE_DISTANCE, even if it goes beyond screen
        bounceFrame.x = originalFrame.x - BOUNCE_DISTANCE
    end
    
    hs.window.animationDuration = BOUNCE_ANIMATION_DURATION
    window:setFrame(bounceFrame, hs.window.animationDuration)
    
    hs.timer.doAfter(BOUNCE_ANIMATION_DURATION + 0.02, function()
        hs.window.animationDuration = BOUNCE_RETURN_DURATION
        window:setFrame(originalFrame, hs.window.animationDuration)
        
        hs.timer.doAfter(BOUNCE_RETURN_DURATION + 0.02, function()
            if callback then
                callback()
            end
        end)
    end)
end

local function moveWindowToDesktop(direction, withVisualEffect)
    local win = hs.window.focusedWindow()
    
    local spaceInfo, errorMsg = getWindowSpaceInfo(win)
    if not spaceInfo then
        if errorMsg and withVisualEffect then
            showCanvasAlert(errorMsg, win and win:screen(), ALERT_DURATION, "window")
        end
        return
    end
    
    local targetIndex, status = getTargetIndex(spaceInfo.currentIndex, #spaceInfo.screenSpaces, direction)
    
    if status ~= "valid" then
        if withVisualEffect then
            local slideDirection = (direction == "next") and "right" or "left"
            bounceWindow(win, slideDirection, function()
                -- Only bounce effect, no message
            end)
        end
        return
    end
    
    local targetSpace = spaceInfo.screenSpaces[targetIndex]
    local originalFrame = win:frame()
    local windowScreen = win:screen()
    
    local executeTransition = function(frameToRestore)
        -- Use AppleScript with cliclick for macOS Ventura compatibility
        local keyCode = (direction == "next") and "124" or "123"  -- 124 = right arrow, 123 = left arrow
        local script = string.format([[
            -- Ajusta la altura estimada de la barra de título
            property titleBarHeight : 20
            tell application "System Events"
                -- Detectar la app y ventana activa
                set frontApp to name of first application process whose frontmost is true
                tell application process frontApp
                    try
                        set {xPos, yPos} to position of window 1
                        set {winWidth, winHeight} to size of window 1
                    on error
                        return
                    end try
                end tell
            end tell
            -- Calcular posición central de la barra de título
            set clickX to xPos + (winWidth / 2)
            set clickY to yPos + 5
            -- Convertir a enteros (cliclick no acepta decimales)
            set clickX to round clickX rounding as taught in school
            set clickY to round clickY rounding as taught in school
            -- Mover el ratón y hacer clic sostenido
            do shell script "/opt/local/bin/cliclick m:" & clickX & "," & clickY
            delay 0.05
            do shell script "/opt/local/bin/cliclick dd:" & clickX & "," & clickY
            -- Mientras está presionado, enviar ctrl+arrow
            tell application "System Events"
                key down control
                key code %s
                key up control
            end tell
            -- Soltar clic
            delay 0.2
            do shell script "/opt/local/bin/cliclick du:" & clickX & "," & clickY
        ]], keyCode)
        
        hs.osascript.applescript(script)
        
        -- Wait for the transition to complete, then show alert
        hs.timer.doAfter(0.8, function()
            -- Show the alert on the new desktop (targetIndex)
            showCanvasAlert(string.format("Desktop %d", targetIndex), windowScreen, ALERT_DURATION, "window")
        end)
    end
    
    if withVisualEffect then
        local slideDirection = (direction == "next") and "right" or "left"
        slideWindowByWidth(win, slideDirection, executeTransition)
    else
        hs.window.animationDuration = FAST_ANIMATION_DURATION
        executeTransition(originalFrame)
    end
end

-- Window movement functions
function moveWindowToNextDesktop()
    moveWindowToDesktop("next", true)
end

function moveWindowToPrevDesktop()
    moveWindowToDesktop("prev", true)
end

-- =============================================================================
-- INITIALIZATION AND CONTROL
-- =============================================================================

-- Configure space watcher with canvas cleanup
spaceWatcher = hs.spaces.watcher.new(function()
    onSpaceChange()
    if #activeCanvas > 0 then
        hs.timer.doAfter(0.1, clearAllCanvas)
    end
end)

-- Start systems
ctrlNumberTap:start()
spaceWatcher:start()
getSpacesPerMonitor()

-- Configure keyboard shortcuts for window mover
hs.hotkey.bind(WINDOW_MOVER_MODIFIERS, "right", moveWindowToNextDesktop)
hs.hotkey.bind(WINDOW_MOVER_MODIFIERS, "left", moveWindowToPrevDesktop)

-- Control interfaces
hs.ctrlListener = {
    stop = function()
        ctrlNumberTap:stop()
        print("Workspace switcher stopped")
    end,
    restart = function()
        ctrlNumberTap:stop()
        ctrlNumberTap:start()
        processingKey = false
        lastTime = 0
        print("Workspace switcher restarted")
    end,
    status = function()
        print("Workspace Switcher Status:")
        print("- Monitor:", currentMonitor)
        print("- Desktop:", currentDesktop)
        print("- Processing:", processingKey)
        print("- Active canvas:", #activeCanvas)
        print("- Spaces per monitor:", table.concat(spacesPerMonitor, ", "))
    end,
    test = function(number)
        local monitor = determineMonitorBySpace(number)
        if monitor then
            print("Testing Desktop", number, "on Monitor", monitor)
            activateMonitorSilently(monitor)
            hs.timer.doAfter(0.02, function()
                verifyAndShowAlert(number, monitor)
            end)
        else
            print("Desktop", number, "does not exist")
        end
    end,
    clearCanvas = clearCanvas,
    checkShortcuts = function()
        print("Checking all desktop shortcuts...")
        for i = 1, 9 do
            if determineMonitorBySpace(i) then
                hs.timer.doAfter(i * 0.5, function()
                    hs.ctrlListener.test(i)
                end)
            end
        end
    end,
    openShortcutSettings = openMissionControlShortcuts
}

hs.windowMover = {
    moveNext = moveWindowToNextDesktop,
    movePrev = moveWindowToPrevDesktop,
    test = function()
        local win = hs.window.focusedWindow()
        if win then
            showCanvasAlert("Window Mover Test", win:screen(), 2.0, "window")
        else
            showCanvasAlert("No focused window", nil, 2.0, "window")
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
    end,
    clearCanvas = clearCanvas
}

-- Optimize animations globally
hs.window.animationDuration = FAST_ANIMATION_DURATION

-- Clean canvas on reload
clearAllCanvas()

-- Confirmation messages
print("=== UNIFIED WORKSPACE & WINDOW MOVER LOADED (ENHANCED) ===")
print("WORKSPACE SWITCHER:")
print("• Ctrl + 1-9: Switch to desktop on appropriate monitor")
print("• Automatically detects disabled shortcuts")
print("• Opens System Preferences when shortcuts are disabled")
print("• Use hs.ctrlListener.test(number) to test")
print("• Use hs.ctrlListener.checkShortcuts() to test all")
print("• Use hs.ctrlListener.openShortcutSettings() to open settings")
print("")
print("WINDOW MOVER:")
print("• Shift + Ctrl + Alt + Cmd + right/left: Move window with animation")
print("• Use hs.windowMover.test() to test")
print("")
print("SHARED:")
print("• Use clearCanvas() to clear stuck canvas")
print("=======================================================")