#include-once
#include <Date.au3>
#include <GDIPlus.au3>

Func _Countdown($airtime, $countdownMin)
	Local $countdown = "", $nocountdown = 0
	Local $Years = Round(Int($countdownMin / 525600), 0)
	Local $months = Round(Int($countdownMin / 43200), 0)
	Local $days = Int($countdownMin / 1440)
	Local $hours = Int($countdownMin / 60)
	$hours = Mod($hours, 24)
	Local $minutes = $countdownMin
	$minutes = Mod($minutes, 60)
	If $days = "" Then
		If $hours = "" Then
			If $minutes = "" Then
				$nocountdown = 1
			Else
			EndIf
		EndIf
	EndIf

	If $nocountdown = 0 Then
		$countdown = $countdown & $days & "d : "
		If $hours = "0" Then
			$countdown = $countdown & "0" & "h : "
			If $minutes = "0" Then
				$countdown = $countdown & "0" & "m"
			Else
				$countdown = $countdown & $minutes & "m"
			EndIf
		Else
			$countdown = $countdown & $hours & "h : "
			If $minutes = "0" Then
				$countdown = $countdown & "0" & "m"
			Else
				$countdown = $countdown & $minutes & "m"
			EndIf
		EndIf
	Else
		$countdown = $countdown & "-"
	EndIf

	If $days >= 2 Then
		$countdown = Round(((($days * 24) + $hours) / 24), 0)
		Return $countdown & " days"
	EndIf

	If Not ($days = "") Then
		If $days < 0 Then
			If $Years < 0 Then
				If ($Years < -1) Then
					Return StringReplace($Years, "-", "") & " years ago"
				Else
					Return StringReplace($Years, "-", "") & " year ago"
				EndIf
			Else
				If $months < -2 Then
					If $months < -11 Then
						Return "1 year ago"
					Else
						Return StringReplace($months, "-", "") & " months ago"
					EndIf
				Else
					$countdown = StringReplace($days, "-", "")
					If ($countdown > 1) Then
						Return $countdown & " days ago"
					Else
						Return $countdown & " day ago"
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
  If StringInStr($countdown, "0d : 0h : -") Then Return "recently"
  If StringInStr($countdown, "0d : 0h : 0m") Then Return "recently"
	If StringInStr($countdown, "0d : -") Then Return "recently"
  If ($Years = 0) And ($days = 0) And ($months = 0) And ($hours = 0) And ($minutes > 0) Then 
       Return $minutes&" minutes"
  EndIf
  If StringInStr($countdown, "0d :") And ($hours > 0) Then 
       Return $hours&"h"&" : "&$minutes&"m"
  EndIf
  
	Return $countdown
EndFunc   ;==>_Countdown


Func _TimeZoneConversion($DateTime, $ConversionCode, $UserUTC, $DSTOption)
	If StringInStr($ConversionCode, "-") Then
		$ConversionCode = StringReplace($ConversionCode, "-", "+")
	Else
		$ConversionCode = StringReplace($ConversionCode, "+", "-")
	EndIf
	$ConversionCode = $ConversionCode + $UserUTC + $DSTOption
	Return (_DateAdd('n', $ConversionCode, $DateTime))
EndFunc   ;==>_TimeZoneConversion


Func _GetWeekday($Date, $Short = 1)
	$Date = StringSplit($Date, "/", 2)
	If $Short = 1 Then
		Return _DateDayOfWeek(_DateToDayOfWeek($Date[0], $Date[1], StringLeft($Date[2], 2)), 1)
	Else
		Return _DateDayOfWeek(_DateToDayOfWeek($Date[0], $Date[1], StringLeft($Date[2], 2)), 0)
	EndIf
EndFunc   ;==>_GetWeekday

Func _HTML_StripTags($sHTMLData)
	If $sHTMLData = "" Then Return SetError(1, 0, $sHTMLData)
	Local $oHTML = ObjCreate("HTMLFILE")
	If @error Then Return SetError(1, 0, $sHTMLData)
	$oHTML.Open()
	$oHTML.Write($sHTMLData)
	Return SetError(0, 0, $oHTML.Body.innerText)
EndFunc   ;==>_HTML_StripTags

Func _URIEncode($urlText)
	$url = ""
	For $i = 1 To StringLen($urlText)
		$acode = Asc(StringMid($urlText, $i, 1))
		Select
			Case ($acode >= 48 And $acode <= 57) Or _
					($acode >= 65 And $acode <= 90) Or _
					($acode >= 97 And $acode <= 122)
				$url = $url & StringMid($urlText, $i, 1)
			Case $acode = 32
				$url = $url & "+"
			Case Else
				$url = $url & "%" & Hex($acode, 2)
		EndSelect
	Next
	Return $url
EndFunc   ;==>_URIEncode

Func _INetGet($sURL, $fString = True)
	Local $sString = InetRead($sURL, 1)
	Local $iError = @error, $iExtended = @extended
	If $fString = Default Or $fString Then $sString = BinaryToString($sString)
	Return SetError($iError, $iExtended, _ANSI2UNICODE($sString))
EndFunc   ;==>_INetGet

Func _Between($sString, $sStart, $sEnd)
	Local $sCase = "(?is)"
	$sStart = $sStart ? "\Q" & $sStart & "\E" : "\A"
	$sEnd = $sEnd ? "(?=\Q" & $sEnd & "\E)" : "\z"
	Local $aReturn = StringRegExp($sString, $sCase & $sStart & "(.*?)" & $sEnd, 3)
	If @error Then Return SetError(1, 0, 0)
	Return $aReturn
EndFunc   ;==>_Between

Func ArrayDelete(ByRef $avArray, $iElement)
	If Not IsArray($avArray) Then Return SetError(1, 0, 0)
	Local $iUBound = UBound($avArray, 1) - 1
	If $iElement < 0 Then $iElement = 0
	If $iElement > $iUBound Then $iElement = $iUBound
	Switch UBound($avArray, 0)
		Case 1
			For $i = $iElement To $iUBound - 1
				$avArray[$i] = $avArray[$i + 1]
			Next
			ReDim $avArray[$iUBound]
		Case 2
			Local $iSubMax = UBound($avArray, 2) - 1
			For $i = $iElement To $iUBound - 1
				For $j = 0 To $iSubMax
					$avArray[$i][$j] = $avArray[$i + 1][$j]
				Next
			Next
			ReDim $avArray[$iUBound][$iSubMax + 1]
		Case Else
			Return SetError(3, 0, 0)
	EndSwitch

	Return $iUBound
EndFunc   ;==>ArrayDelete


Func _ANSI2UNICODE($sString = "")
	Local Const $SF_ANSI = 1
	Local Const $SF_UTF8 = 4
	Return BinaryToString(StringToBinary($sString, $SF_ANSI), $SF_UTF8)
EndFunc   ;==>_ANSI2UNICODE
