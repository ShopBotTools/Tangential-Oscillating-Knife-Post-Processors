+-----------------------------------------------------------
|												
| ShopBot configuration file 
|
|-----------------------------------------------------------
|
| Who     When       What
| ======  ========== ========================================
| Ryan P  ????		 Written
| Joe B   9/15/2022  Changed jogs to moves. Fleshed out header
| Brian O 9/20/2022  Eliminated need for "unwind" moves. Futher fleshed out header and footer
| Brian O 11/10/2022 Modified to automatically "round" corners for turns
| Brian O 11/24/2022 Added UI to set knife parameters
+-----------------------------------------------------------

POST_NAME = "ShopBot Tan/Osc Knife (mm)(*.sbp)"

FILE_EXTENSION = "sbp"

UNITS = "MM"

DIRECT_OUTPUT = "DIRECT to ShopBot|ShopBot_run.ini"

+------------------------------------------------
|    line terminating characteRS
+------------------------------------------------

LINE_ENDING = "[13][10]"

+------------------------------------------------
|    Block Numbering
+------------------------------------------------

LINE_NUMBER_START     = 0
LINE_NUMBER_INCREMENT = 10
LINE_NUMBER_MAXIMUM   = 999999

+================================================
+
+    default formating for variables
+
+================================================

+------------------------------------------------
+ Line numbering
+------------------------------------------------

var LINE_NUMBER   = [N|A|N|1.0]

+------------------------------------------------
+ Spindle Speed
+------------------------------------------------

var SPINDLE_SPEED = [S|A||1.0]

+------------------------------------------------
+ Feed Rate
+------------------------------------------------

var CUT_RATE    = [FC|A||1.1|0.0166]
var PLUNGE_RATE = [FP|A||1.1|0.0166]

+------------------------------------------------
+ Tool position in x,y and z
+------------------------------------------------

var X_POSITION = [X|A||1.6]
var Y_POSITION = [Y|A||1.6]
var Z_POSITION = [Z|A||1.6]

+------------------------------------------------
+ Home tool positions 
+------------------------------------------------

var X_HOME_POSITION = [XH|A||1.6]
var Y_HOME_POSITION = [YH|A||1.6]
var Z_HOME_POSITION = [ZH|A||1.6]


+------------------------------------------------
+ ArC centre positions - incremental from arC start
+------------------------------------------------

VAR ARC_CENTRE_I_INC_POSITION = [I|A||1.6]
VAR ARC_CENTRE_J_INC_POSITION = [J|A||1.6]


+================================================
+
+    Block definitions for toolpath output
+
+================================================
+ ------------------------------------------------
+   Scripted function used in postp                             
+ ------------------------------------------------

SCRIPT
	require "strict"
 	pp = require "ppVariables"
	Px = -999999
	Py = -999999
	Pz = -999999
	PPx = -999999
	PPy = -999999
	PPz = -999999
	RotationCount = 0 --Counts number of full rotations made by knife; used to correct position with VA command during lifts.
	Plunge = 0
	Radius = 0.1 --(Inches) Radius for auto-radius corner turning; recommend width of knife blade.
	turnInc = 0.2 --(Radians) Angular increment for corner radiusing turns.
	LiftAngle = 140 --(Degrees) Turn angle above which the knife will be lifted out of the material for turn.
	InAngle = 0 --(Radians) Angle parallel to motion going into a corner (PPx/PPy to Px/Py)
	OutAngle = 0 -- (Radians) Angle parlalel to motion going out of a corner (Px/Py to pp.X.Value/pp.Y.Value)
	TurnAngle = 0 
	rad2Deg = 180.0 / math.pi --Conversion factor from radians to degrees. 
	Options = {} -- Initialize options table
	Options.bladeWidth = 0.125 -- default value for blade width
	Options.pulloutAngle = 120 -- default value for pullout angle
	g_title = "Tangential_Oscillating_Knife" -- name for registry entry where settings are recorded.
	g_default_window_width  = 625 -- window width for UI in pixels
	g_default_window_height = 225 -- window height for UI in pixels
	InJog = 0
	

g_DialogHtml = [[]] -- html source for UI. Each line must be concatenated to this variable. This allows for readable formatting.
..[[<!DOCTYPE html>]]
..[[<html>]]
	..[[<head>]]
		..[[<title>Tangential Oscillating Knife Dialog</title>]]
		..[[<style type="text/css">]]
			..[[body{background-color: #F0F0F0;}]]
			..[[body,td,th{font-family: Arial, Helvetica,sans-serif;font-size: 12px;}]]
			..[[.ParameterDescription{color:#555; width: 70%}]]
			..[[.FormButton {font-weight: bold; width: 100%; font-family: Arial, Helvetica, sans-serif; font-size: 12px;}]]
		..[[</style>]]
	..[[</head>]]
	..[[<body>]]
		..[[<table width=100%>]]
			..[[<tr height="40"><td colspan="4" valign="bottom"><b>Knife Settings</b><hr></td></tr>]]
			..[[<tr>]]
				..[[<td width=5%>Blade&nbsp;Width&nbsp;</td>]]
				..[[<td width=5%><input name="textfield" type="text" size="8" maxlength="5" ID="bladeWidth"></td>]]
				..[[<td width=20% text-align="left"><span id="bladeWidthUnits">Inches</span></td>]]
				..[[<td class="ParameterDescription">Width of blade (center of rotation to cutting edge).</td>]]
			..[[</tr>]]
			..[[<tr>]]
				..[[<td width=5%>Pullout&nbsp;Angle&nbsp;</td>]]
				..[[<td width=5%><input name="textfield" type="text" size="8" maxlength="5" ID="pulloutAngle"></td>]]
				..[[<td width=20% text-align="left"><span id="bladeWidthUnits">Degrees</span></td>]]
				..[[<td class="ParameterDescription">Minimum angle to trigger pullout for turn.</td>]]
			..[[</tr>]]
			..[[<tr>]]
				..[[<td style="width: 100%" colspan="4"><hr width="100%"></td>]]
			..[[</tr>]]
		..[[</table>]]
		..[[<table width=100%>]]
			..[[<tr width=100%>]]
				..[[<td style="width: 40%"></td>]]
				..[[<td style="width: 20%"><input  class="FormButton" type="button"  style="font-weight: bold; width: 100%; font-family: 'Lucida Sans Unicode', 'Lucida Grande', sans-serif; font-size: 12px;" id="ButtonOK" value="OK"></td>]]
				..[[<td style="width: 40%"></td>]]
			..[[</tr>]]
		..[[</table>]]
	..[[</body>]]
..[[</html>]]

function DisplayDialog(Options) -- Called in main. Pulls up UI
	local dialog = HTML_Dialog(true,g_DialogHtml, g_default_window_width, g_default_window_height, "Tangential Oscillating Knife Toolpath")
	dialog:AddLabelField("GadgetTitle", g_title)
	dialog:AddDoubleField("bladeWidth", Options.bladeWidth)
	dialog:AddDoubleField("pulloutAngle", Options.pulloutAngle)
	
	if not dialog:ShowDialog() then
       return 0
    end
	
	Options.bladeWidth = dialog:GetDoubleField("bladeWidth")
	Options.pulloutAngle = dialog:GetDoubleField("pulloutAngle")
	
	if Options.bladeWidth <= 0 then 
		DisplayMessageBox("Blade width must be a positive non-zero number!")
        return -1
	end	  
	if Options.pulloutAngle <= 0 then 
		DisplayMessageBox("Pullout Angle must be a positive non-zero number!")
        return -1
	end
	return 1
end

function LoadDefaults(Options) -- Loads variable defaults from registry.
	
	local registry = Registry(g_title)
	Options.bladeWidth = registry:GetDouble("bladeWidth", Options.bladeWidth)
	Options.pulloutAngle = registry:GetDouble("pulloutAngle", Options.pulloutAngle)
end

function SaveDefaults(Options) -- Records settings to registry for recall the next time post is run. 
	
	local registry = Registry(g_title)
	registry:SetDouble("bladeWidth", Options.bladeWidth)
	registry:SetDouble("pulloutAngle", Options.pulloutAngle)
end
  --[[ === main =================================================
  |
  | Initialise variables 
  |	
  ]]
  
	function main()
		
		if pp.Init() == false then
        		DisplayMessageBox('Failed to initialise ppVariables module!')
     	end
		LoadDefaults(Options)
		--MessageBox("dialog")
		local dialog_result = -1
		
		while dialog_result == -1 do
			dialog_result = DisplayDialog(Options)
		end
	
		-- The user cancelled
		if dialog_result == 0 then
			return false
		end
	
		SaveDefaults(Options)
		Radius = Options.bladeWidth
		LiftAngle = Options.pulloutAngle
		return true     
  	end 
	
	function Jog()
	
		if Px == -999999 then
			pp.PostP:OutputLine("J6 " .. Round2Six(pp.X.Value) .. "," .. Round2Six(pp.Y.Value) .. "," .. Round2Six(pp.Z.Value)  .. ",," .. "\r\n", false)
		end
		
		if PPz < pp.SAFEZ.Value and Px ~= -999999 then 
			InJog = 1
			AddRotation()
			pp.PostP:OutputLine("M6," .. Round2Six(Px) .. "," .. Round2Six(Py) .. "," .. Round2Six(PPz) .. ",," .. Round2Six(OutAngle*rad2Deg) .. "\r\n",false)
		end
		
		if PPz >= pp.SAFEZ.Value and Px ~= -999999 then 
			pp.PostP:OutputLine("J7 " .. Round2Six(Px) .. "," .. Round2Six(Py) .. "," .. Round2Six(Pz)  .. ",," .. "\r\n", false)
				if RotationCount ~= 0 then 
					pp.PostP:OutputLine("VA,,,,," .. Round2Six(OutAngle*rad2Deg - 360 * RotationCount) .. "\r\n",false)
					RotationCount = 0
				end
		end
		
		PPx = Px
		PPy = Py
		PPz = Pz		
		Px = pp.X.Value
		Py = pp.Y.Value
		Pz = pp.Z.Value
		
	
	end
	
	function AddRotation(cc)
		if (PPx ~= Px  or PPy ~= Py or PPz ~= Pz) and PPx ~= -999999 and Pz < pp.SAFEZ.Value then 
			local TurnX = Px
			local TurnY = Py
			local Lift = 1	
			local TurnDistance = 0
			
			AngleCalculation()
			
			if PPz >= pp.SAFEZ.Value then 
				pp.PostP:OutputLine("J8," .. Round2Six(PPx) .. "," .. Round2Six(PPy) .. "," .. Round2Six(PPz) .. ",," .. Round2Six(OutAngle*rad2Deg) .. "\r\n",false)
				if RotationCount ~= 0 then 
					pp.PostP:OutputLine("VA,,,,," .. Round2Six(OutAngle*rad2Deg - 360 * RotationCount) .. "\r\n",false)
					RotationCount = 0
				end
				Lift = 0
			else
				pp.PostP:OutputLine("M7," .. Round2Six(PPx) .. "," .. Round2Six(PPy) .. "," .. Round2Six(PPz) .. ",," .. Round2Six(InAngle*rad2Deg) .. "\r\n",false)
				Plunge = 1
			end
		
			if TurnAngle == 0 then 
				Lift = 0 
			end

			if math.abs(TurnAngle)*rad2Deg <= LiftAngle and (PPx ~= Px  or PPy ~= Py) and PPz < pp.SAFEZ.Value then
			local Length = math.sqrt(math.pow(PPx-Px,2) + math.pow(PPy-Py,2))
			
				if math.abs(TurnAngle) > turnInc * 1.5 and Length > Radius then 
					TurnDistance = Radius*math.tan(math.abs(TurnAngle/2))		
					if TurnDistance < Radius then
						TurnDistance = Radius
					end
					TurnX = Px - math.cos(InAngle) * TurnDistance
					TurnY = Py - math.sin(InAngle) * TurnDistance
				end
				Lift = 0
			end
			
			local Angle = InAngle
			
			if PPz < pp.SAFEZ.Value then
				if Plunge == 0 then 
				pp.PostP:OutputLine("M8," .. Round2Six(TurnX) .. "," .. Round2Six(TurnY) .. "," .. Round2Six(Pz) .. ",," .. Round2Six(Angle*rad2Deg) .. "\r\n", false)
				end
				if Lift == 0 then
					local segments = math.floor((math.abs(TurnAngle)*rad2Deg)/(turnInc*rad2Deg))
					local count = 0
					local increment = TurnAngle/segments
					while count < segments do
						Angle = Angle + increment
						TurnX = TurnX + math.cos(InAngle) * TurnDistance*(1/segments)
						TurnY = TurnY + math.sin(InAngle) * TurnDistance*(1/segments)
						pp.PostP:OutputLine("M9," .. Round2Six(TurnX) .. "," .. Round2Six(TurnY) .. "," .. Round2Six(PPz) .. ",," .. Round2Six(Angle*rad2Deg) .. "\r\n", false)
						count = count + 1
					end	
				end
			end
			

			    if OutAngle < 2*math.pi*RotationCount then 
					RotationCount = RotationCount -1
				end
				if OutAngle >= 2*math.pi*(RotationCount+1) then 
					RotationCount = RotationCount +1
				end
			if Lift == 1 and InJog == 0 then
				pp.PostP:OutputLine("M10," .. Round2Six(TurnX) .. "," .. Round2Six(TurnY) .. "," .. Round2Six(Pz) .. ",," .. Round2Six(Angle*rad2Deg) .. "\r\n", false)
				pp.PostP:OutputLine("J9," .. Round2Six(pp.SAFEZ.Value) .. "\r\n",false)
				pp.PostP:OutputLine("JB," .. Round2Six(OutAngle*rad2Deg) .. "\r\n",false)
				
				if RotationCount ~= 0 then 
					pp.PostP:OutputLine("VA,,,,," .. Round2Six(OutAngle*rad2Deg - 360 * RotationCount) .. "\r\n",false)
					RotationCount = 0
				end
				pp.PostP:OutputLine("J10," .. Round2Six(PPz) .. "\r\n",false)
			end
		end
		
		PPx = Px
		PPy = Py
		PPz = Pz
		Px = pp.X.Value
		Py = pp.Y.Value
		Pz = pp.Z.Value
		Plunge = 0
		InJog = 0
	end

	function Round2Six(num)
		return math.floor(num*1000000+0.5)/1000000
	end
	
	function AngleCalculation()
	
		InAngle = math.atan2(Py-PPy,Px-PPx)
		if InAngle < 0 then InAngle = InAngle + 2*math.pi end
		OutAngle = math.atan2(pp.Y.Value-Py,pp.X.Value-Px)
		if OutAngle < 0 then OutAngle = OutAngle + 2*math.pi end
		if pp.Y.Value == Py and pp.X.Value == Px then
			OutAngle = InAngle
		end
		TurnAngle = OutAngle - InAngle
		if TurnAngle > math.pi then 	
			TurnAngle = TurnAngle - 2*math.pi 
		end
		
		if TurnAngle < -1*math.pi then
			TurnAngle = TurnAngle + 2*math.pi 
		end
		
		InAngle = InAngle + 2*math.pi*RotationCount
		OutAngle = InAngle + TurnAngle
	end
ENDSCRIPT
+---------------------------------------------
+                Start of file
+---------------------------------------------

begin HEADER
"'Created using ShopBot Tan/Osc Knife Post V1.2"
"'----------------------------------------------------------------"
"IF %(25)=0 THEN GOTO UNIT_ERROR	'check to see software is set to standard"
"C#,92 'Load Knife Settings"
"IF &ATC = 1 Then GoSub EMPTY_SPINDLE"
"IF &ATC = 2 Then GoSub EMPTY_SPINDLE"
"IF &ATC = 4 Then GoSub EMPTY_SPINDLE"
"VO,1,&Knife_X_offset,&Knife_Y_offset 'Update these offsets in C:/sbParts/Custom/KnifeSettings.sbc"
"SF,0"
"&PWSafeZ = [SAFEZ]"
"JZ,[ZH]"
"SO,5,1"
"Pause 2"
"SO,6,1"
"MS,[FC],[FP]"


+--------------------------------------------
+               Program moves
+--------------------------------------------

begin RAPID_MOVE

"<!>Jog()"

+---------------------------------------------

begin FIRST_FEED_MOVE

"<!>AddRotation('F ')"

+---------------------------------------------

begin FEED_MOVE

"<!>AddRotation('S ')"

+---------------------------------------------------
+  Commands output at toolchange
+---------------------------------------------------

begin TOOLCHANGE
"'Tool Change"
	    


+---------------------------------------------------
+  Commands output for a new segment - toolpath
+  with same toolnumber but maybe different feedrates
+---------------------------------------------------

begin NEW_SEGMENT
"'New Path"

+---------------------------------------------
+                 end of file
+---------------------------------------------

begin FOOTER
"JZ,[ZH]"
"VO,0"
"J5,[XH],[YH],[ZH],,0"
"SO,6,0"
"SO,5,0"
"END"

"EMPTY_SPINDLE:"
"C#,89"
"IF &ToolIN = 0 Then GOTO ALREADY_EMPTY"
"&tool = 0"
"C9"
"ALREADY_EMPTY:"
"Return"

"UNIT_ERROR:"				
"CN, 91                            'Run file explaining unit error"
"END"