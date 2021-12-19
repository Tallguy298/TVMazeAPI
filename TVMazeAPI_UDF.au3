#include-once
#include "TVMazeAPI_UDF_Requirements.au3"

; =========================================
; UDF Name.......: TVMaze.com API UDF
; Author ........: BB_19
; =========================================


; #FUNCTION# ====================================================================================================================
; Name ..........: _GetTVSchedule
; Description ...: Get TV-Schedule for the next 48 hours
; Syntax ........: _GetTVSchedule($ConvertTimeZone = 0)
; Parameters ....: [$ConvertTimeZone]          - 0 or 1, 1= Airdate/time will be converted to the users timezone.
; Return values .: Array with schedule results in following table format: "ShowID|ShowName|Season|Episode|EpisodeName|NetworkName|AirTime|Countdown"
;				   @error 0 = Connection failed
;				   @error 1 = Nothing found for the date
; ===============================================================================================================================


Func _GetTVSchedule($ConvertTimeZone = 0)
	Local $UserUTC = _Date_Time_GetTimeZoneInformation() ;
	If $UserUTC[0] = 2 Then
		Local $DSTOption = 60
	Else
		Local $DSTOption = 0
	EndIf
	$UserUTC = $UserUTC[1]
	If StringInStr($UserUTC, "-") Then
		$UserUTC = StringReplace($UserUTC, "-", "+")
	Else
		$UserUTC = "-" & $UserUTC
	EndIf

	Local $tTime_T = _Date_Time_GetLocalTime()
	Local $Local_User_Time = _Date_Time_SystemTimeToDateTimeStr($tTime_T, 1)

	Local $stTime_T = _Date_Time_GetSystemTime()
	Local $System_Time = _Date_Time_SystemTimeToDateTimeStr($stTime_T, 1)
	Local $TV_Schedule_Results


	For $Date = 1 To 2 Step +1
		Local $US_Time = _DateAdd("n", "-300", $System_Time)
		$US_TimeS = StringSplit($US_Time, "/", 2)

		Local $Schedule_Date = $US_TimeS[0] & "-" & $US_TimeS[1] & "-" & StringLeft($US_TimeS[2], 2)
		Local $Schedule_Results = _INetGet("http://api.tvmaze.com/schedule?country=US&date=" & $Schedule_Date)
		If @error Then Return SetError(1)
		$Schedule_Results = StringReplace($Schedule_Results, '[{"id"', "")
		$Schedule_Results = StringSplit($Schedule_Results, '},{"id"', 1)
		If @error Then
			Return SetError(2)
		EndIf

		Local $TV_Schedule[($Schedule_Results[0])][8]

		For $i = 1 To $Schedule_Results[0] Step +1
			Local $AirTimeStamp = _Between($Schedule_Results[$i], '"airstamp":"', '",')
			If Not @error Then
				Local $TimezoneDiff = StringRight($AirTimeStamp[0], 6)
				$AirTimeStamp = StringReplace(StringReplace(StringLeft($AirTimeStamp[0], 16), "-", "/"), "T", " ")
				Local $UTCConverstionDT = (StringLeft($TimezoneDiff, 1) & StringMid($TimezoneDiff, 2, 2) * 60 + StringRight($TimezoneDiff, 2))
				Local $EpisodeAirDateTimeUser = _TimeZoneConversion($AirTimeStamp, $UTCConverstionDT, $UserUTC, $DSTOption)
				Local $DateDiff = _DateDiff('n', $Local_User_Time, $EpisodeAirDateTimeUser) + 1

				$Countdown = _Countdown($EpisodeAirDateTimeUser, $DateDiff)
				If $ConvertTimeZone = 1 Then
					$AirTimeStamp = $EpisodeAirDateTimeUser
				EndIf

				Local $Season = _Between($Schedule_Results[$i], '"season":', ',')
				If Not @error Then $Season = $Season[0]


				Local $RunTime = _Between($Schedule_Results[$i], '"runtime":', ',')
				If Not @error Then
					$RunTime = $RunTime[0]
				Else
					$RunTime = 20
				EndIf
				If ($DateDiff <= "-" & $RunTime) Then
					If $Countdown = "recently" Then $Countdown = "Recently aired"
				Else
					If $Countdown = "recently" Then $Countdown = "Airing now"
				EndIf

				Local $Episode = _Between($Schedule_Results[$i], '"number":', ',')
				If Not @error Then $Episode = $Episode[0]

				Local $Names = _Between($Schedule_Results[$i], '"name":"', '",')

				If Not @error Then
					Local $ids = _Between($Schedule_Results[$i], '"id":', ',')
					If Not @error Then
						If UBound($Names) > 2 Then
							$TV_Schedule[$i - 1][0] = $ids[0] ;Show ID
							$TV_Schedule[$i - 1][1] = $Names[1] ;Show Name

							If StringLen($Season) = "1" Then $Season = "0" & $Season
							If $Season = "Null" Then $Season = "00"
							If StringLen($Episode) = "1" Then $Episode = "0" & $Episode
							If $Episode = "Null" Then $Episode = "00"
							If $Names[0] = "Null" Then $Names[0] = "Episode " & $Episode

							$TV_Schedule[$i - 1][2] = $Season ;Season

							$TV_Schedule[$i - 1][3] = $Episode ;Episode
							$TV_Schedule[$i - 1][4] = $Names[0] ;Episode Name
							$TV_Schedule[$i - 1][5] = $Names[2] ;Network Name
							$AirTimeStampWeekDay = _GetWeekday($AirTimeStamp, 1)

							$TV_Schedule[$i - 1][6] = $AirTimeStampWeekDay & ", " & StringReplace($AirTimeStamp, " ", " - ") ;Aittimestamp

							$TV_Schedule[$i - 1][7] = $Countdown ;Countdown
						EndIf
					EndIf
				EndIf
			EndIf
		Next


		If $Date = 1 Then
			$TV_Schedule_Results = $TV_Schedule
			$System_Time = _DateAdd("d", "+1", $US_Time)
		Else

			Local $TV_Schedule_Results_Full[(UBound($TV_Schedule_Results) + UBound($TV_Schedule))][8]

			For $all = 0 To (UBound($TV_Schedule_Results) - 1) Step +1
				$TV_Schedule_Results_Full[$all][0] = $TV_Schedule_Results[$all][0]
				$TV_Schedule_Results_Full[$all][1] = $TV_Schedule_Results[$all][1]
				$TV_Schedule_Results_Full[$all][2] = $TV_Schedule_Results[$all][2]
				$TV_Schedule_Results_Full[$all][3] = $TV_Schedule_Results[$all][3]
				$TV_Schedule_Results_Full[$all][4] = $TV_Schedule_Results[$all][4]
				$TV_Schedule_Results_Full[$all][5] = $TV_Schedule_Results[$all][5]
				$TV_Schedule_Results_Full[$all][6] = $TV_Schedule_Results[$all][6]
				$TV_Schedule_Results_Full[$all][7] = $TV_Schedule_Results[$all][7]
			Next

			For $all = UBound($TV_Schedule_Results) To (UBound($TV_Schedule_Results_Full) - 1) Step +1
				$TV_Schedule_Results_Full[$all][0] = $TV_Schedule[$all - UBound($TV_Schedule_Results)][0]
				$TV_Schedule_Results_Full[$all][1] = $TV_Schedule[$all - UBound($TV_Schedule_Results)][1]
				$TV_Schedule_Results_Full[$all][2] = $TV_Schedule[$all - UBound($TV_Schedule_Results)][2]
				$TV_Schedule_Results_Full[$all][3] = $TV_Schedule[$all - UBound($TV_Schedule_Results)][3]
				$TV_Schedule_Results_Full[$all][4] = $TV_Schedule[$all - UBound($TV_Schedule_Results)][4]
				$TV_Schedule_Results_Full[$all][5] = $TV_Schedule[$all - UBound($TV_Schedule_Results)][5]
				$TV_Schedule_Results_Full[$all][6] = $TV_Schedule[$all - UBound($TV_Schedule_Results)][6]
				$TV_Schedule_Results_Full[$all][7] = $TV_Schedule[$all - UBound($TV_Schedule_Results)][7]
			Next

			Return $TV_Schedule_Results_Full
		EndIf
	Next

EndFunc   ;==>_GetTVSchedule

; #FUNCTION# ====================================================================================================================
; Name ..........: _SearchShow
; Description ...: Search for shows on tvmaze.com
; Syntax ........: _SearchShow($SearchName, $searchbytvrageID = 0)
; Parameters ....: $SearchName          - Showname or TVRage ID
;                  [$searchbytvrageID]    - if 1 then TVRage ID required in the previous parameter
; Return values .: Array with Search results in following table format: "ShowName|ShowID"
;				   @error 0 = Connection failed
;				   @error 1 = Nothing found
; ===============================================================================================================================
Func _SearchShow($SearchName, $searchbytvrageID = 0)

	$SearchName = _URIEncode($SearchName)
	If $searchbytvrageID = 0 Then
		If $SearchName = "" Then Return SetError(2)
		Local $SearchResults = _INetGet("http://api.tvmaze.com/search/shows?q=" & $SearchName)

		If @error Then Return SetError(1)
		$SearchResults = StringSplit($SearchResults, '},{"score"', 1)
		If @error Then
			If Not StringInStr($SearchResults[1], "score") Then
				Return SetError(2)
			EndIf
		EndIf
	Else
		Local $SearchResult = _INetGet("http://api.tvmaze.com/lookup/shows?tvrage=" & $SearchName)
		If Not @error Then
			If StringInStr($SearchResult, '"id":') Then
				Local $SearchResults[2]
				$SearchResults[0] = 1
				$SearchResults[1] = $SearchResult
			Else
				Return SetError(2)
			EndIf
		Else
			Return SetError(1)
		EndIf
	EndIf

	Local $Search_Results[($SearchResults[0])][3]
	For $i = 1 To $SearchResults[0] Step +1
		Local $Names = _Between($SearchResults[$i], '"name":"', '",')
		If Not @error Then
			Local $ids = _Between($SearchResults[$i], '"id":', ',')
			If Not @error Then
				Local $score = _Between($SearchResults[$i], ':', ',"')
				If Not @error Then
					If Not StringInStr($SearchResults[$i], '"premiered":null') Then
						$Search_Results[$i - 1][0] = $Names[0] ;Show Name
						$Search_Results[$i - 1][1] = $ids[0] ;Show ID
						$Search_Results[$i - 1][2] = $score[0] ;Search Score
					EndIf
				EndIf
			EndIf
		EndIf
	Next

	;Filter out shows without any Airdate information
	Local $count_shows = 0, $Search_Results_Cleaned[$SearchResults[0]][3]
	For $i_x = 1 To $SearchResults[0] Step +1
		If Not ($Search_Results[$i_x - 1][0] = "") Then
			$count_shows = $count_shows + 1
			ReDim $Search_Results_Cleaned[$count_shows][3]
			$Search_Results_Cleaned[$count_shows - 1][0] = $Search_Results[$i_x - 1][0]
			$Search_Results_Cleaned[$count_shows - 1][1] = $Search_Results[$i_x - 1][1]
			$Search_Results_Cleaned[$count_shows - 1][2] = $Search_Results[$i_x - 1][2]
		EndIf
	Next
	If $count_shows = 0 Then Return SetError(2)
	Return $Search_Results_Cleaned
EndFunc   ;==>_SearchShow


; #FUNCTION# ====================================================================================================================
; Name ..........: _GetShowInfo
; Description ...: Get Show Information
; Syntax ........: _GetShowInfo($ShowID, $ConvertTimeZone = 0, $SaveShowFiles = 0, $SaveShowFilesPath = @TempDir, $GetShowImage = 0,$SaveShowImagePath=@tempdir)
; Parameters ....: $ShowID		           - TVMaze Show ID
;                  [$ConvertTimeZone]      - 0 or 1, 1 = Airing date/times will be converted to the users timezone
;                  [$SaveShowFiles]        - 0 or 1, 1 = Download the ShowInfo File to the Computer, if file allready exists, then use the old one
;                  [$SaveShowFilesPath]    - 0 or 1, only required if previous or next parameter is set to 1
;                  [$GetShowImage]         - 0 or 1, 1 = Downloads the Show image to the $SaveShowFilesPath and the shows country image
; Return values .: Array with all ShowInfo in following format: [0] = "Show ID"
;																[1] = "Show Name"
;																[2] = "Network/Streaming Site - Name"
;																[3] = "Runtime in Minutes"
;																[4] = "Usual airing time" ;example: Mondays at 20:00
;																[5] = "Series Satus"
;																[6] = "Premiere Date"
;																[7] = "Timezone of the show"
;																[8] = "Image-Link of the show"
;																[9] = "Show Summary"
;																[10] = "Country Code"
;																[11] = "Country"
;																[12] = "Rating"
;																[13] = "Genres"
;				   @error 0 = Connection failed
;				   @error 1 = No show found under the id
; ===============================================================================================================================
Func _GetShowInfo($ShowID, $ConvertTimeZone = 0, $SaveShowFiles = 0, $SaveShowFilesPath = @TempDir, $GetShowImage = 0, $SaveShowImagePath = @TempDir)
	Local $Series_INFO[14]
	Local $UserUTC = _Date_Time_GetTimeZoneInformation() ;
	If $UserUTC[0] = 2 Then
		Local $DSTOption = 60
	Else
		Local $DSTOption = 0
	EndIf
	$UserUTC = $UserUTC[1]
	If StringInStr($UserUTC, "-") Then
		$UserUTC = StringReplace($UserUTC, "-", "+")
	Else
		$UserUTC = "-" & $UserUTC
	EndIf

	Local $tTime_T = _Date_Time_GetLocalTime()
	Local $Local_User_Time = _Date_Time_SystemTimeToDateTimeStr($tTime_T, 1)
	If $GetShowImage = 1 Then DirCreate($SaveShowImagePath)
	;DownloadShowInfo
	If $SaveShowFiles = 0 Then
		Local $SeriesInfo_EpisodeList = _INetGet("http://api.tvmaze.com/shows/" & $ShowID & "?embed=episodeswithspecials")
		If @error Then Return SetError(1)
	Else
		DirCreate($SaveShowFilesPath)
		If Not FileExists($SaveShowFilesPath & "\" & $ShowID & ".dat") Then
			InetGet("http://api.tvmaze.com/shows/" & $ShowID & "?embed=episodeswithspecials", $SaveShowFilesPath & "\" & $ShowID & ".dat", 1, 0)
			If @error Then Return SetError(1)
		EndIf
		Local $SeriesInfo_EpisodeList = FileRead($SaveShowFilesPath & "\" & $ShowID & ".dat")
	EndIf

	;Split Show Info & Episode List
	Local $Series_EpisodeList = _Between($SeriesInfo_EpisodeList, '"episodeswithspecials":', "")
	If Not @error Then $Series_EpisodeList = $Series_EpisodeList[0]
	Local $SeriesInfo = _Between($SeriesInfo_EpisodeList, "", '"episodeswithspecials":')
	If Not @error Then $SeriesInfo = $SeriesInfo[0]

	Local $Series_ID = _Between($SeriesInfo_EpisodeList, '{"id":', ",")
	If @error Then Return SetError(2)
	$Series_INFO[0] = $Series_ID[0]

	Local $EpisodeAirDateTimes = _Between($Series_EpisodeList, '"airstamp":"', '",')
	If @error Then Return SetError(2)

	Local $RunTimes = _Between($Series_EpisodeList, '"runtime":', ",")
	If Not @error Then
		Local $Series_Runtime = $RunTimes[UBound($RunTimes) - 1]
		$Series_INFO[3] = $Series_Runtime & " Minutes"
	Else
		Local $Series_Runtime = "-"
		$Series_INFO[3] = $Series_Runtime
	EndIf


	Local $ShowName = _Between($SeriesInfo, '"name":"', '",')
	If Not @error Then $ShowName = $ShowName[0]
	$Series_INFO[1] = $ShowName

	Local $NetworkName = _Between($SeriesInfo, '"name":"', '",')
	If Not @error Then
		If (UBound($NetworkName) > 1) Then $NetworkName = $NetworkName[1]
	EndIf
	$Series_INFO[2] = $NetworkName

	Local $Country = _Between($SeriesInfo, '"name":"', '",')
	If Not @error Then
		If (UBound($Country) > 2) Then $Country = $Country[2]
	EndIf
	$Series_INFO[11] = $Country

	Local $Rating = _Between($SeriesInfo, '"rating":{"average":', '},"')
	If Not @error Then
		$Rating = $Rating[0]
		If $Rating = "null" Then
			$Series_INFO[12] = "-"
		Else
			$Series_INFO[12] = $Rating & "/10"
		EndIf
	Else
		$Series_INFO[12] = "-"
	EndIf


	$Series_INFO[11] = $Country

	Local $SeriesStatus = _Between($SeriesInfo, '"status":"', '",')
	If Not @error Then $SeriesStatus = $SeriesStatus[0]
	$Series_INFO[5] = $SeriesStatus

	Local $PremireDate = _Between($SeriesInfo, '"premiered":"', '",')
	If Not @error Then $PremireDate = $PremireDate[0]
	$Series_INFO[6] = StringReplace($PremireDate, "-", "/")

	Local $Series_TimeZone = _Between($SeriesInfo, '"timezone":"', '"}')
	If Not @error Then $Series_TimeZone = $Series_TimeZone[0]
	If $Series_TimeZone = "0" Then $Series_TimeZone = "-"
	$Series_INFO[7] = $Series_TimeZone

	Local $Series_Image_Link = _Between($SeriesInfo, '"medium":"', '",')
	If Not @error Then
		$Series_Image_Link = $Series_Image_Link[0]
		If $GetShowImage = 1 Then
			If Not FileExists($SaveShowImagePath & "\" & $ShowID & ".jpg") Then InetGet($Series_Image_Link, $SaveShowImagePath & "\" & $ShowID & ".jpg", 1, 0)
		EndIf
	Else
		$Series_Image_Link = ""
	EndIf

	If $Series_Image_Link = "" Then
		If $GetShowImage = 1 Then
			If Not FileExists($SaveShowImagePath & "\" & $ShowID & ".jpg") Then
				If Not FileExists($SaveShowImagePath & "\NoPic.jpg") Then

					InetGet("http://tvmazecdn.com/images/no-img/no-img-portrait-text.png", $SaveShowImagePath & "\NoPic.png", 0, 0)
					_GDIPlus_Startup()
					Local $hImage = _GDIPlus_ImageLoadFromFile($SaveShowImagePath & "\NoPic.png")
					Local $sCLSID = _GDIPlus_EncodersGetCLSID("JPG")
					_GDIPlus_ImageSaveToFileEx($hImage, $SaveShowImagePath & "\NoPic.jpg", $sCLSID)
					_GDIPlus_ImageDispose($hImage)
					_GDIPlus_Shutdown()
					FileDelete($SaveShowImagePath & "\NoPic.png")

				EndIf
				FileCopy($SaveShowImagePath & "\NoPic.jpg", $SaveShowImagePath & "\" & $ShowID & ".jpg", 1)
			EndIf
		EndIf
	EndIf



	$Series_INFO[8] = $Series_Image_Link

	Local $Series_Summary = _Between($SeriesInfo, '"summary":"', '",')
	If Not @error Then $Series_Summary = StringReplace(StringReplace(_HTML_StripTags($Series_Summary[0]), '\"', '"'), "\n", "")
	$Series_INFO[9] = $Series_Summary



	Local $Series_Genre = _Between($SeriesInfo, '"genres":', ',"')
	If Not @error Then
		$Series_Genre = StringReplace(_HTML_StripTags($Series_Genre[0]), '\"', '"')
		$Series_Genre = StringReplace(StringReplace(StringReplace($Series_Genre, "[", ""), "]", ""), '"', '')
		If ($Series_Genre = "") Then
			$Series_INFO[13] = "-"
		Else
			$Series_INFO[13] = $Series_Genre
		EndIf
	Else
		$Series_INFO[13] = "-"
	EndIf

	#Region WeekDay and Time - "Usually Airs At"
	Local $TimezoneDiff = StringRight($EpisodeAirDateTimes[(UBound($EpisodeAirDateTimes) - 1)], 6)
	Local $UTCConverstionDT = (StringLeft($TimezoneDiff, 1) & StringMid($TimezoneDiff, 2, 2) * 60 + StringRight($TimezoneDiff, 2)) ; -240
	Local $LastEpisodeAirDateTime = StringReplace(StringReplace(StringLeft($EpisodeAirDateTimes[(UBound($EpisodeAirDateTimes) - 1)], 16), "-", "/"), "T", " ")
	If $ConvertTimeZone = 0 Then
		Local $Series_UsualAirTime = _GetWeekday($LastEpisodeAirDateTime, 0) & "s at " & StringRight($LastEpisodeAirDateTime, 5)
	Else
		$LastEpisodeAirDateTime = _TimeZoneConversion($LastEpisodeAirDateTime, $UTCConverstionDT, $UserUTC, $DSTOption)
		Local $Series_UsualAirTime = _GetWeekday($LastEpisodeAirDateTime, 0) & "s at " & StringRight($LastEpisodeAirDateTime, 5)
	EndIf
	$Series_INFO[4] = $Series_UsualAirTime

	Local $CountryCode = _Between($SeriesInfo, '"code":"', '",')
	If Not @error Then
		$CountryCode = $CountryCode[0]
		$Series_INFO[10] = $CountryCode
		If $GetShowImage = 1 Then
			If Not FileExists($SaveShowImagePath & "\" & $CountryCode & ".jpg") Then
				Local $DownX = InetGet("http://tvmazecdn.com/vendor/bower/famfamfam-flags/img/" & StringLower($CountryCode) & ".png", $SaveShowImagePath & "\" & $CountryCode & ".png", 0, 0)
				_GDIPlus_Startup()
				Local $hImage = _GDIPlus_ImageLoadFromFile($SaveShowImagePath & "\" & $CountryCode & ".png")
				Local $sCLSID = _GDIPlus_EncodersGetCLSID("JPG")
				_GDIPlus_ImageSaveToFileEx($hImage, $SaveShowImagePath & "\" & $CountryCode & ".jpg", $sCLSID)
				_GDIPlus_ImageDispose($hImage)
				_GDIPlus_Shutdown()
				FileDelete($SaveShowImagePath & "\" & $CountryCode & ".png")
			EndIf
		EndIf
	EndIf
	#EndRegion WeekDay and Time - "Usually Airs At"

	Return $Series_INFO
EndFunc   ;==>_GetShowInfo


; #FUNCTION# ====================================================================================================================
; Name ..........: _GetShowEpisodes
; Description ...: Get All Episodes of a TV-Show
; Syntax ........: _GetShowEpisodes($ShowID, $SaveShowFiles = 0, $SaveShowFilesPath = @TempDir, $ConvertTimeZone = 0, $GetLastAndNextEpisodeOnly = 0)
; Parameters ....: $ShowID		          - TVMaze ID
;                  [$SaveShowFiles]       - 0 or 1, 1 = Download the ShowInfo File to the Computer, if file allready exists, then use the old one
;                  [$SaveShowFilesPath]   - Folder/Path where the show files are downloaded to (only required if previous parameter is set to 1)
;                  [$ConvertTimeZone]     - 0 or 1, 1 = Airing date/times will be converted to the users timezone
;                  [$GetLastAndNextEpisodeOnly]   - 0 or 1, 0 = All episodes will be returned, 1 = Only the Last and the Next Episode will be returned
; Return values .: Array with all all episodes or only the last/next episode depending on what option was used in the parameters
;				   	Array Option 0(All Episodes): Table format: "Season|Episode|Episodename|Air Date/Time|Airing in/Aired"
;				   	Array Option 1(Last/Next EP): Table format: "Season|Episode|Episodename|Air Date/Time|Airing in/Aired|MinutesSinceAired/MinutesUntilAirs"
;				   @error 0 = Connection failed
;				   @error 1 = No Cast found
; ===============================================================================================================================
Func _GetShowEpisodes($ShowID, $SaveShowFiles = 0, $SaveShowFilesPath = @TempDir, $ConvertTimeZone = 0, $GetLastAndNextEpisodeOnly = 0)
	Local $UserUTC = _Date_Time_GetTimeZoneInformation() ;
	If $UserUTC[0] = 2 Then
		Local $DSTOption = 60
	Else
		Local $DSTOption = 0
	EndIf
	$UserUTC = $UserUTC[1]
	If StringInStr($UserUTC, "-") Then
		$UserUTC = StringReplace($UserUTC, "-", "+")
	Else
		$UserUTC = "-" & $UserUTC
	EndIf

	Local $tTime_T = _Date_Time_GetLocalTime()
	Local $Local_User_Time = _Date_Time_SystemTimeToDateTimeStr($tTime_T, 1)

	Local $NextEpisodeIndex = "", $LastEpisodeIndex = ""

	;DownloadShowInfo

	If $SaveShowFiles = 0 Then
		Local $SeriesInfo_EpisodeList = _INetGet("http://api.tvmaze.com/shows/" & $ShowID & "?embed=episodeswithspecials")
		If @error Then Return SetError(1)
	Else
		DirCreate($SaveShowFilesPath)
		If Not FileExists($SaveShowFilesPath & "\" & $ShowID & ".dat") Then
			InetGet("http://api.tvmaze.com/shows/" & $ShowID & "?embed=episodeswithspecials", $SaveShowFilesPath & "\" & $ShowID & ".dat", 1, 0)
			If @error Then
				FileDelete($SaveShowFilesPath & "\" & $ShowID & ".dat")
				Return SetError(1)
			EndIf
		EndIf
		Local $SeriesInfo_EpisodeList = FileRead($SaveShowFilesPath & "\" & $ShowID & ".dat")
	EndIf


	;Split Show Info & Episode List
	Local $Series_EpisodeList = _Between($SeriesInfo_EpisodeList, '"episodeswithspecials":', "")
	If Not @error Then
		$Series_EpisodeList = $Series_EpisodeList[0]
	Else
		FileDelete($SaveShowFilesPath & "\" & $ShowID & ".dat")
		Return SetError(1)
	EndIf

	Local $SeriesInfo = _Between($SeriesInfo_EpisodeList, "", '"episodeswithspecials":')
	If Not @error Then $SeriesInfo = $SeriesInfo[0]

	Local $SeriesStatus = _Between($SeriesInfo, '"status":"', '",')
	If Not @error Then $SeriesStatus = $SeriesStatus[0]


	Local $Seasons = _Between($Series_EpisodeList, '"season":', ",")
	Local $EpisodeNames = _Between($Series_EpisodeList, '"name":"', '",')
	Local $EpisodeAirDateTimes = _Between($Series_EpisodeList, '"airstamp":"', '",')
	If @error Then Return SetError(2)
	Local $RunTimes = _Between($Series_EpisodeList, '"runtime":', ",")
	If @error Then Local $RunTimes[100]
	Local $episodes = _Between($Series_EpisodeList, '"number":', ",")

	If Not @error Then
		Local $TV_Show[UBound($episodes)][5]
		Local $Countdowns[UBound($episodes)]
		Local $LastAndNextEpisode[3][6]
		For $i = (UBound($episodes) - 1) To 0 Step -1
			If (UBound($EpisodeAirDateTimes) - 1 < $i) Then
				ReDim $TV_Show[UBound($TV_Show) - 1][5]
				ContinueLoop
			EndIf
			Local $EpisodeAirDateTime = StringReplace(StringReplace(StringLeft($EpisodeAirDateTimes[$i], 16), "-", "/"), "T", " ")
			Local $TimezoneDiff = StringRight($EpisodeAirDateTimes[$i], 6)
			Local $UTCConverstionDT = (StringLeft($TimezoneDiff, 1) & StringMid($TimezoneDiff, 2, 2) * 60 + StringRight($TimezoneDiff, 2))

			Local $EpisodeAirDateTimeUser = _TimeZoneConversion($EpisodeAirDateTime, $UTCConverstionDT, $UserUTC, $DSTOption)

			If $ConvertTimeZone = 1 Then
				$EpisodeAirDateTimes[$i] = _GetWeekday($EpisodeAirDateTimeUser, 1) & ", " & $EpisodeAirDateTimeUser
			Else
				$EpisodeAirDateTimes[$i] = _GetWeekday($EpisodeAirDateTime, 1) & ", " & $EpisodeAirDateTime
			EndIf

			If StringLen($episodes[$i]) = 1 Then $episodes[$i] = "0" & $episodes[$i]
			If StringLen($Seasons[$i]) = 1 Then $Seasons[$i] = "0" & $Seasons[$i]
			If $Seasons[$i] = "Null" Then $Seasons[$i] = "00"
			If $episodes[$i] = "Null" Then $episodes[$i] = "00"
			If $EpisodeNames[$i] = "Null" Then $EpisodeNames[$i] = "Episode " & $episodes[$i]

			Local $DateDiff = _DateDiff('n', $Local_User_Time, $EpisodeAirDateTimeUser) + 1
			$TV_Show[$i][0] = $Seasons[$i]
			$TV_Show[$i][1] = $episodes[$i]
			$TV_Show[$i][2] = StringReplace($EpisodeNames[$i], '\"', '"')
			$TV_Show[$i][3] = StringReplace($EpisodeAirDateTimes[$i], " ", " - ", -1)

			If Not (StringInStr($DateDiff, "-")) Then
				$NextEpisodeIndex = $i
				$Countdowns[$i] = _Countdown($EpisodeAirDateTimeUser, $DateDiff)
				$TV_Show[$i][4] = $Countdowns[$i]
				If $GetLastAndNextEpisodeOnly = 1 Then
					$LastAndNextEpisode[1][0] = $Seasons[$NextEpisodeIndex]
					$LastAndNextEpisode[1][1] = $episodes[$NextEpisodeIndex]
					$LastAndNextEpisode[1][2] = StringReplace($EpisodeNames[$NextEpisodeIndex], '\"', '"')
					$LastAndNextEpisode[1][3] = StringReplace($EpisodeAirDateTimes[$NextEpisodeIndex], " ", " - ", -1)
					$LastAndNextEpisode[1][4] = $Countdowns[$NextEpisodeIndex]
					$LastAndNextEpisode[1][5] = $DateDiff
				EndIf
			Else
				If $LastEpisodeIndex = "" Then $LastEpisodeIndex = $i
				$Countdowns[$i] = $DateDiff

				If ($DateDiff < "-" & $RunTimes[$i]) Then
					$TV_Show[$i][4] = _Countdown($EpisodeAirDateTimeUser, $DateDiff)
				Else
					$TV_Show[$i][4] = "Airing now"
				EndIf

				If $GetLastAndNextEpisodeOnly = 1 Then
					$LastAndNextEpisode[0][0] = $Seasons[$LastEpisodeIndex]
					$LastAndNextEpisode[0][1] = $episodes[$LastEpisodeIndex]
					$LastAndNextEpisode[0][2] = StringReplace($EpisodeNames[$LastEpisodeIndex], '\"', '"')
					$LastAndNextEpisode[0][3] = StringReplace($EpisodeAirDateTimes[$LastEpisodeIndex], " ", " - ", -1)
					If ($DateDiff < "-" & $RunTimes[$i]) Then
						$LastAndNextEpisode[0][4] = "Aired"
					Else
						$LastAndNextEpisode[0][4] = "Airing now"
					EndIf
					$LastAndNextEpisode[0][5] = $DateDiff
					ExitLoop
				EndIf
			EndIf
		Next

		If $GetLastAndNextEpisodeOnly = 1 Then
			If $LastAndNextEpisode[0][2] = "" Then
				$LastAndNextEpisode[0][0] = "-"
				$LastAndNextEpisode[0][1] = "-"
				$LastAndNextEpisode[0][2] = "-"
				$LastAndNextEpisode[0][3] = "-"
				$LastAndNextEpisode[0][4] = "-"
				$LastAndNextEpisode[0][5] = "-"
			EndIf
			If $LastAndNextEpisode[1][2] = "" Then
				$LastAndNextEpisode[1][0] = "-"
				$LastAndNextEpisode[1][1] = "-"
				$LastAndNextEpisode[1][2] = "-"
				$LastAndNextEpisode[1][3] = "-"
				$LastAndNextEpisode[1][4] = "-"
				$LastAndNextEpisode[1][5] = "-"
			EndIf
			$LastAndNextEpisode[2][0] = $SeriesStatus
			Return $LastAndNextEpisode
		Else
			Return $TV_Show
		EndIf

	Else
		Return SetError(2)
	EndIf

EndFunc   ;==>_GetShowEpisodes


; #FUNCTION# ====================================================================================================================
; Name ..........: _GetCast
; Description ...: Get Castmembers of a TV Show
; Syntax ........: _GetCast($ShowID, $DownloadImages = 0, $DownloadFolder = @TempDir)
; Parameters ....: $ShowID		        - TVMaze ID
;                  [$DownloadImages]      - If "1" then Images of the Castmembers will be downloaded to the folder in the next parameter
;                  [$DownloadFolder]      - Folder to download the images of Castmembers
; Return values .: Array with all Cast-Members in following table format: "Actor Name|Actor Role|ActorImageLink"
;				   @error 0 = Connection failed
;				   @error 1 = No Cast found
; ===============================================================================================================================
Func _GetCast($ShowID, $DownloadFiles = 0, $DownloadFolderIMG = @TempDir, $DownloadFolder = @TempDir)
	If $DownloadFiles = 1 Then
		DirCreate($DownloadFolderIMG & "\" & $ShowID)
		DirCreate($DownloadFolder)
	EndIf

	If $DownloadFiles = 0 Then
		Local $SeriesInfo_Cast = _INetGet("http://api.tvmaze.com/shows/" & $ShowID & "/cast")
		If @error Then Return SetError(1)
	Else
		If Not FileExists($DownloadFolder & "\" & $ShowID & ".cast.dat") Then
			InetGet("http://api.tvmaze.com/shows/" & $ShowID & "/cast", $DownloadFolder & "\" & $ShowID & ".cast.dat")
			If @error Then Return SetError(1)
		EndIf

		Local $SeriesInfo_Cast = FileRead($DownloadFolder & "\" & $ShowID & ".cast.dat")
		If @error Then Return SetError(1)

	EndIf

	$SeriesInfo_Cast = StringSplit($SeriesInfo_Cast, '},{"person":', 1)
	If @error Then Return SetError(2)

	Local $Series_CastList[$SeriesInfo_Cast[0]][3]

	For $i = 1 To $SeriesInfo_Cast[0] Step +1

		Local $Actor = _Between($SeriesInfo_Cast[$i], '"name":"', '",')
		If Not @error Then $Series_CastList[$i - 1][0] = StringReplace($Actor[0], '\"', '"')

		Local $ActorChar = _Between($SeriesInfo_Cast[$i], '"name":"', '",')
		If Not @error Then $Series_CastList[$i - 1][1] = StringReplace($ActorChar[1], '\"', '"')


		Local $Actor_Image = _Between($SeriesInfo_Cast[$i], '"medium":"', '",')
		If Not @error Then
			If UBound($Actor_Image) > 1 Then
				$Series_CastList[$i - 1][2] = StringReplace($Actor_Image[1], "medium", "small")
			Else
				$Series_CastList[$i - 1][2] = StringReplace($Actor_Image[0], "medium", "small")
			EndIf
		EndIf
		If $DownloadFiles = 1 Then
			If Not ($Series_CastList[$i - 1][2] = "") Then
				If Not ($Series_CastList[$i - 1][0] = "") Then
					If Not FileExists($DownloadFolderIMG & "\" & $ShowID & "\" & $Series_CastList[$i - 1][0] & ".jpg") Then
						InetGet($Series_CastList[$i - 1][2], $DownloadFolderIMG & "\" & $ShowID & "\" & $Series_CastList[$i - 1][0] & ".jpg", 0, 0)
					EndIf
				EndIf
			Else
				If Not ($Series_CastList[$i - 1][0] = "") Then
					If Not FileExists($DownloadFolderIMG & "\" & $ShowID & "\" & $Series_CastList[$i - 1][0] & ".jpg") Then
						If Not FileExists($DownloadFolderIMG & "\" & $ShowID & "\NoPic.jpg") Then
							InetGet("http://tvmazecdn.com/images/no-img/no-img-portrait-clean.png", $DownloadFolderIMG & "\" & $ShowID & "\NoPic.png", 0, 0)
							_GDIPlus_Startup()
							Local $hImage = _GDIPlus_ImageLoadFromFile($DownloadFolderIMG & "\" & $ShowID & "\NoPic.png")
							Local $sCLSID = _GDIPlus_EncodersGetCLSID("JPG")
							_GDIPlus_ImageSaveToFileEx($hImage, $DownloadFolderIMG & "\" & $ShowID & "\NoPic.jpg", $sCLSID)
							_GDIPlus_ImageDispose($hImage)
							_GDIPlus_Shutdown()
							FileDelete($DownloadFolderIMG & "\" & $ShowID & "\NoPic.png")
						EndIf
						FileCopy($DownloadFolderIMG & "\" & $ShowID & "\NoPic.jpg", $DownloadFolderIMG & "\" & $ShowID & "\" & $Series_CastList[$i - 1][0] & ".jpg", 1)
					EndIf
				EndIf
			EndIf
		EndIf
	Next
	If $DownloadFiles = 1 Then
		If FileExists($DownloadFolderIMG & "\" & $ShowID & "\NoPic.jpg") Then FileDelete($DownloadFolderIMG & "\" & $ShowID & "\NoPic.jpg")
	EndIf
	Return $Series_CastList
EndFunc   ;==>_GetCast


; #FUNCTION# ====================================================================================================================
; Name ..........: _FilterBySeason
; Description ...: Filters an Episode-List by the selected Season
; Syntax ........: _FilterBySeason($Episode_List, $FilterSeason = "1")
; Parameters ....: $Episode_List        - Array of the Episodelist
;                  $FilterSeason        - Number of the season to filter
; Return values .: Filtered Array with the episodes of the selected season
; ===============================================================================================================================
Func _FilterBySeason($Episode_List, $FilterSeason = "1")
	If StringLen($FilterSeason) = "1" Then $FilterSeason = "0" & $FilterSeason
	For $i = (UBound($Episode_List) - 1) To 0 Step -1
		If Not StringInStr($Episode_List[$i][0], $FilterSeason) Then ArrayDelete($Episode_List, $i)
	Next
	Return $Episode_List
EndFunc   ;==>_FilterBySeason

Func _GetNumberOfSeasons($Episode_List)
	Local $NumberOfSeason[2]
	$NumberOfSeason[0] = 1
	$NumberOfSeason[1] = 0
	For $i = 0 To (UBound($Episode_List) - 1) Step +1
		If $Episode_List[$i][0] > $NumberOfSeason[1] Then $NumberOfSeason[1] = $Episode_List[$i][0]
		If $Episode_List[$i][0] < $NumberOfSeason[0] Then $NumberOfSeason[0] = $Episode_List[$i][0]
	Next
	Return $NumberOfSeason
EndFunc   ;==>_GetNumberOfSeasons
