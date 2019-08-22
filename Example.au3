#include "TVMazeAPI_UDF.au3"
#include <Array.au3>


;===========TV Schedule for next 2 days==========
;$TV_Schedule=_GetTVSchedule()
;_ArrayDisplay($TV_Schedule,"TV Schedule")


;===============Search for a show================
$sString = InputBox("TV Show Title" , "Name Of TV Show?" , "" , "" , 400 , 140)
$SearchResults=_SearchShow($sString)
$err = @error
_ArrayDisplay($SearchResults,"TV Show")

;===============Get show info/details============
$iIndex = _ArraySearch($SearchResults, $sString, 0, 0, 0, 0, 1)
If $iIndex < 0 Then $iIndex = 0
$ShowID=$SearchResults[$iIndex][1];
$ShowInfo = _GetShowInfo($ShowID)
_ArrayDisplay($ShowInfo,"Show Info")


;=============Get the cast of a show=============
$Cast=_GetCast($ShowID)
_ArrayDisplay($Cast,"Cast")


;============Get all Episodes of a Show==========
$AllEpisodes = _GetShowEpisodes($ShowID)
_ArrayDisplay($AllEpisodes,"All Episodes")


;========Filter Episodes by selected season======
$FilteredBySeason2 = _FilterBySeason($AllEpisodes, "1")
_ArrayDisplay($FilteredBySeason2,"Filtered by episodes of season 1")


;====Get only last and next episode of a show====
$LastAndNextEpisode = _GetShowEpisodes($ShowID, 0, @TempDir, 0, 1)
_ArrayDisplay($LastAndNextEpisode,"Last and Next Episodes only")



