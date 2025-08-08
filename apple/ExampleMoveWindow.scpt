-- Adjust the estimated height of the title bar
property titleBarHeight : 20

tell application "System Events"
	-- Detect the active app and window
	set frontApp to name of first application process whose frontmost is true
	tell application process frontApp
		try
			set {xPos, yPos} to position of window 1
			set {winWidth, winHeight} to size of window 1
		on error
			display dialog "Could not get the active window." buttons {"OK"}
			return
		end try
	end tell
end tell

-- Calculate central position of the title bar
set clickX to xPos + (winWidth / 2)
set clickY to yPos + (titleBarHeight / 2)

-- Convert to integers (cliclick doesn't accept decimals)
set clickX to round clickX rounding as taught in school
set clickY to round clickY rounding as taught in school

-- Move the mouse and perform a held click
do shell script "/opt/local/bin/cliclick m:" & clickX & "," & clickY
delay 0.05
do shell script "/opt/local/bin/cliclick dd:" & clickX & "," & clickY

-- While pressed, send ctrl+right
tell application "System Events"
	key down control
	key code 124 -- right arrow -- 123 left arrow
	key up control
end tell

-- Release click
delay 0.2
do shell script "/opt/local/bin/cliclick du:" & clickX & "," & clickY