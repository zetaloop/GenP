#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Skull.ico
#AutoIt3Wrapper_Outfile_x64=AdobeGenP.exe
#AutoIt3Wrapper_Res_Comment=AdobeGenP
#AutoIt3Wrapper_Res_CompanyName=AdobeGenp
#AutoIt3Wrapper_Res_Description=Adobe Generic Patcher
#AutoIt3Wrapper_Res_Fileversion=3.6.4.0
#AutoIt3Wrapper_Res_LegalCopyright=AdobeGenP 2025
#AutoIt3Wrapper_Res_LegalTradeMarks=AdobeGenP 2025
#AutoIt3Wrapper_Res_ProductName=AdobeGenP
#AutoIt3Wrapper_Res_ProductVersion=3.6.4
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Array.au3>
#include <ButtonConstants.au3>
#include <Crypt.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <GuiListView.au3>
#include <GUITab.au3>
#include <GuiTreeView.au3>
#include <Inet.au3>
#include <Memory.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <ProgressConstants.au3>
#include <Security.au3>
#include <StaticConstants.au3>
#include <String.au3>
#include <WindowsConstants.au3>
#include <WinAPIProc.au3>
#include <WinAPI.au3>

AutoItSetOption("GUICloseOnESC", 0)
Global $g_version = "3.6.4"
Global $g_appwndtitle = "AdobeGenP v" & $g_version
Global $g_appversion = "CGP Community Edition" & @CRLF & "Originally created by uncia"
If _Singleton($g_appwndtitle, 1) = 0 Then
	Exit
EndIf
Global $mylvgroupisexpanded = True
Global $g_agroupids[0]
Global $finterrupt = 0
Global $filestopatch[0][1], $filestopatchnull[0][1]
Global $filestorestore[0][1], $ffileslisted = 0
Global $myhgui, $htab, $hmaintab, $hlogtab, $idmsg, $idlistview, $g_idlistview, $idbuttonsearch, $idbuttonstop
Global $idbuttoncustomfolder, $idbtncure, $idbtndeselectall, $listviewselectflag = 1
Global $idbtnupdatehosts, $idmemo, $timestamp, $idlog, $idbtnrestore, $idbtncopylog, $idfindacc
Global $idenablemd5, $idonlyadobefolders, $idbtnsaveoptions, $idcustomdomainlistlabel, $idcustomdomainlistinput
Global $hpopuptab, $idbtnremoveags, $idbtncleanhosts, $idbtnedithosts, $idlabeledithosts, $sedithoststext, $idbtnrestorehosts
Global $sremoveagstext, $idlabelremoveags, $scleanfirewalltext, $idlabelcleanfirewall, $idbtnopenwf, $idbtncreatefw, $idbtnremovefw, $idbtntogglefw
Global $sruntimeinstallertext, $idlabelruntimeinstaller, $idbtntoggleruntimeinstaller, $swintrusttext, $idlabelwintrust, $idbtntogglewintrust, $idbtndevoverride
Global $idbtnagsinfo, $idbtnfirewallinfo, $idbtnhostsinfo, $idbtnruntimeinfo, $idbtnwintrustinfo
Global $sinipath = @ScriptDir & "\config.ini"
If Not FileExists($sinipath) Then
	FileInstall("config.ini", @ScriptDir & "\config.ini")
EndIf
Global $configvervar = IniRead($sinipath, "Info", "ConfigVer", "????")
Global $mydefpath = IniRead($sinipath, "Default", "Path", @ProgramFilesDir)
If Not FileExists($mydefpath) Or Not StringInStr(FileGetAttrib($mydefpath), "D") Then
	IniWrite($sinipath, "Default", "Path", @ProgramFilesDir)
	$mydefpath = @ProgramFilesDir
EndIf
Global $myregexpglobalpatternsearchcount = 0, $count = 0, $idprogressbar
Global $aouthexglobalarray[0], $anullarray[0], $ainhexarray[0]
Global $sz_type, $bfoundacro32 = False, $bfoundgenericarm = False, $aspecialfiles, $sspecialfiles = "|"
Global $progressfilecountscale, $filesearchedcount
Global $bfindacc = IniRead($sinipath, "Options", "FindACC", "1")
Global $benablemd5 = IniRead($sinipath, "Options", "EnableMD5", "1")
Global $bonlyadobefolders = IniRead($sinipath, "Options", "OnlyAdobeFolder", "1")
Global $g_sthirdpartyfirewall = ''
Global $sdefaultdomainlisturl = "https://a.dove.isdumb.one/list.txt"
Global $scurrentdomainlisturl = IniRead($sinipath, "Options", "CustomDomainListURL", $sdefaultdomainlisturl)
Local $ttargetfilelist_adobe = IniReadSection($sinipath, "TargetFiles")
Global $targetfilelist_adobe[0]
If Not @error Then
	ReDim $targetfilelist_adobe[$ttargetfilelist_adobe[0][0]]
	For $i = 1 To $ttargetfilelist_adobe[0][0]
		$targetfilelist_adobe[$i - 1] = StringReplace($ttargetfilelist_adobe[$i][1], '"', '')
	Next
EndIf
$aspecialfiles = IniReadSection($sinipath, "CustomPatterns")
For $i = 1 To UBound($aspecialfiles) - 1
	$sspecialfiles = $sspecialfiles & $aspecialfiles[$i][0] & "|"
Next
If $cmdline[0] = 1 And $cmdline[1] = "-updatehosts" Then
	updatehostsfile()
	Exit
EndIf
GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")
maingui()
Local $bhostsbakexists = False
If FileExists(@WindowsDir & "\System32\drivers\etc\hosts.bak") Then
	GUICtrlSetState($idbtnrestorehosts, $GUI_ENABLE)
	$bhostsbakexists = True
EndIf
While 1
	Local $bhostsbakexistsnow
	If FileExists(@WindowsDir & "\System32\drivers\etc\hosts.bak") Then
		$bhostsbakexistsnow = True
	Else
		$bhostsbakexistsnow = False
	EndIf
	If $bhostsbakexistsnow <> $bhostsbakexists Then
		If $bhostsbakexistsnow Then
			GUICtrlSetState($idbtnrestorehosts, $GUI_ENABLE)
		Else
			GUICtrlSetState($idbtnrestorehosts, $GUI_DISABLE)
		EndIf
		$bhostsbakexists = $bhostsbakexistsnow
	EndIf
	$idmsg = GUIGetMsg()
	Select
		Case $idmsg = $GUI_EVENT_CLOSE
			GUIDelete($myhgui)
			_exit()
		Case $idmsg = $GUI_EVENT_RESIZED
			ContinueCase
		Case $idmsg = $GUI_EVENT_RESTORE
			ContinueCase
		Case $idmsg = $GUI_EVENT_MAXIMIZE
			Local $iwidth
			Local $agui = WinGetPos($myhgui)
			Local $arect = _GUICtrlListView_GetViewRect($g_idlistview)
			If ($arect[2] > $agui[2]) Then
				$iwidth = $agui[2] - 75
			Else
				$iwidth = $arect[2] - 25
			EndIf
			GUICtrlSendMsg($idlistview, $LVM_SETCOLUMNWIDTH, 1, $iwidth)
		Case $idmsg = $idbuttonstop
			$listviewselectflag = 0
			filllistviewwithinfo()
			memowrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $mydefpath & @CRLF & "---" & @CRLF & "Waiting for user action.")
			GUICtrlSetState($idbuttonstop, $GUI_HIDE)
			GUICtrlSetState($idbuttonsearch, $GUI_SHOW)
			GUICtrlSetState($idbuttonsearch, 64)
			GUICtrlSetState($idbtnrestore, 128)
			GUICtrlSetState($idbtndeselectall, 128)
			GUICtrlSetState($idbtncure, 128)
			GUICtrlSetState($idbtnupdatehosts, 64)
			GUICtrlSetState($idbtncleanhosts, 64)
			GUICtrlSetState($idbtnedithosts, 64)
			GUICtrlSetState($idbtncreatefw, 64)
			GUICtrlSetState($idbtntogglefw, 64)
			GUICtrlSetState($idbtnremovefw, 64)
			GUICtrlSetState($idbtnopenwf, 64)
			GUICtrlSetState($idbtntoggleruntimeinstaller, 64)
			GUICtrlSetState($idbtntogglewintrust, 64)
			GUICtrlSetState($idbtndevoverride, 64)
			GUICtrlSetState($idbtnremoveags, 64)
			GUICtrlSetState($idbtnrestorehosts, 64)
			GUICtrlSetState($idbtnagsinfo, 64)
			GUICtrlSetState($idbtnfirewallinfo, 64)
			GUICtrlSetState($idbtnhostsinfo, 64)
			GUICtrlSetState($idbtnruntimeinfo, 64)
			GUICtrlSetState($idbtnwintrustinfo, 64)
		Case $idmsg = $idbuttonsearch
			$finterrupt = 0
			GUICtrlSetState($idbuttonsearch, $GUI_HIDE)
			GUICtrlSetState($idbuttonstop, $GUI_SHOW)
			togglelog(0)
			GUICtrlSetState($idbtndeselectall, 128)
			GUICtrlSetState($idlistview, 128)
			GUICtrlSetState($idbtncure, 128)
			GUICtrlSetState($idbuttoncustomfolder, 128)
			GUICtrlSetState($idbtnupdatehosts, 128)
			GUICtrlSetState($idbtncleanhosts, 128)
			GUICtrlSetState($idbtnedithosts, 128)
			GUICtrlSetState($idbtncreatefw, 128)
			GUICtrlSetState($idbtntogglefw, 128)
			GUICtrlSetState($idbtnremovefw, 128)
			GUICtrlSetState($idbtnopenwf, 128)
			GUICtrlSetState($idbtntoggleruntimeinstaller, 128)
			GUICtrlSetState($idbtntogglewintrust, 128)
			GUICtrlSetState($idbtndevoverride, 128)
			GUICtrlSetState($idbtnremoveags, 128)
			GUICtrlSetState($idbtnrestorehosts, 128)
			GUICtrlSetState($idbtnagsinfo, 128)
			GUICtrlSetState($idbtnfirewallinfo, 128)
			GUICtrlSetState($idbtnhostsinfo, 128)
			GUICtrlSetState($idbtnruntimeinfo, 128)
			GUICtrlSetState($idbtnwintrustinfo, 128)
			_GUICtrlListView_DeleteAllItems($g_idlistview)
			_GUICtrlListView_SetExtendedListViewStyle($idlistview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
			_GUICtrlListView_AddItem($idlistview, '', 0)
			_GUICtrlListView_AddItem($idlistview, '', 1)
			_GUICtrlListView_AddItem($idlistview, '', 2)
			_GUICtrlListView_AddItem($idlistview, '', 2)
			_GUICtrlListView_RemoveAllGroups($idlistview)
			_GUICtrlListView_InsertGroup($idlistview, -1, 1, '', 1)
			_GUICtrlListView_SetGroupInfo($idlistview, 1, "Info", 1, $LVGS_COLLAPSIBLE)
			_GUICtrlListView_AddSubItem($idlistview, 0, '', 1)
			_GUICtrlListView_AddSubItem($idlistview, 1, "Preparing...", 1)
			_GUICtrlListView_AddSubItem($idlistview, 2, '', 1)
			_GUICtrlListView_AddSubItem($idlistview, 3, "Be patient, please.", 1)
			_GUICtrlListView_SetItemGroupID($idlistview, 0, 1)
			_GUICtrlListView_SetItemGroupID($idlistview, 1, 1)
			_GUICtrlListView_SetItemGroupID($idlistview, 2, 1)
			_GUICtrlListView_SetItemGroupID($idlistview, 3, 1)
			_expand_all_click()
			_GUICtrlListView_SetGroupInfo($idlistview, 1, "Info", 1, $LVGS_COLLAPSIBLE)
			$filestopatch = $filestopatchnull
			$filestorestore = $filestopatchnull
			$timestamp = TimerInit()
			Local $filecount
			If $bfindacc = 1 Then
				Local $sappspaneldir = EnvGet("ProgramFiles(x86)") & "\Common Files\Adobe"
				Local $asize = DirGetSize($sappspaneldir, $DIR_EXTENDED)
				If UBound($asize) >= 2 Then
					$filecount = $asize[1]
					recursivefilesearch($sappspaneldir, 0, $filecount)
					progresswrite(0)
				EndIf
			EndIf
			$asize = DirGetSize($mydefpath, $DIR_EXTENDED)
			If UBound($asize) >= 2 Then
				$filecount = $asize[1]
				$progressfilecountscale = 100 / $filecount
				$filesearchedcount = 0
				progresswrite(0)
				recursivefilesearch($mydefpath, 0, $filecount)
				Sleep(100)
				progresswrite(0)
			EndIf
			filllistviewwithfiles()
			If _GUICtrlListView_GetItemCount($idlistview) > 0 Then
				_assign_groups_to_found_files()
				$listviewselectflag = 1
				GUICtrlSetState($idbuttonsearch, 128)
				GUICtrlSetState($idbtndeselectall, 128)
				GUICtrlSetState($idbtncure, 64)
				GUICtrlSetState($idbtncure, 256)
				If UBound($filestorestore) > 0 Then
					GUICtrlSetState($idbtnupdatehosts, 128)
					GUICtrlSetState($idbtncleanhosts, 128)
					GUICtrlSetState($idbtnedithosts, 128)
					GUICtrlSetState($idbtncreatefw, 128)
					GUICtrlSetState($idbtntogglefw, 128)
					GUICtrlSetState($idbtnremovefw, 128)
					GUICtrlSetState($idbtnopenwf, 128)
					GUICtrlSetState($idbtntoggleruntimeinstaller, 128)
					GUICtrlSetState($idbtntogglewintrust, 128)
					GUICtrlSetState($idbtndevoverride, 128)
					GUICtrlSetState($idbtnremoveags, 128)
					GUICtrlSetState($idbtnrestorehosts, 128)
					GUICtrlSetState($idbtnrestore, 64)
					GUICtrlSetState($idbtnagsinfo, 128)
					GUICtrlSetState($idbtnfirewallinfo, 128)
					GUICtrlSetState($idbtnhostsinfo, 128)
					GUICtrlSetState($idbtnruntimeinfo, 128)
					GUICtrlSetState($idbtnwintrustinfo, 128)
				EndIf
			Else
				$listviewselectflag = 0
				filllistviewwithinfo()
				GUICtrlSetState($idbtncure, 128)
				GUICtrlSetState($idbtndeselectall, 128)
				GUICtrlSetState($idbuttonsearch, 64)
				GUICtrlSetState($idbuttonsearch, 256)
			EndIf
			_expand_all_click()
			GUICtrlSetState($idbtndeselectall, 64)
			GUICtrlSetState($idlistview, 64)
			GUICtrlSetState($idbuttoncustomfolder, 64)
			GUICtrlSetState($idbuttonsearch, $GUI_SHOW)
			GUICtrlSetState($idbuttonstop, $GUI_HIDE)
			GUICtrlSetState($idbtnupdatehosts, 64)
			GUICtrlSetState($idbtncleanhosts, 64)
			GUICtrlSetState($idbtnedithosts, 64)
			GUICtrlSetState($idbtncreatefw, 64)
			GUICtrlSetState($idbtntogglefw, 64)
			GUICtrlSetState($idbtnremovefw, 64)
			GUICtrlSetState($idbtnopenwf, 64)
			GUICtrlSetState($idbtntoggleruntimeinstaller, 64)
			GUICtrlSetState($idbtntogglewintrust, 64)
			GUICtrlSetState($idbtndevoverride, 64)
			GUICtrlSetState($idbtnremoveags, 64)
			GUICtrlSetState($idbtnrestorehosts, 64)
			GUICtrlSetState($idbtnagsinfo, 64)
			GUICtrlSetState($idbtnfirewallinfo, 64)
			GUICtrlSetState($idbtnhostsinfo, 64)
			GUICtrlSetState($idbtnruntimeinfo, 64)
			GUICtrlSetState($idbtnwintrustinfo, 64)
		Case $idmsg = $idbuttoncustomfolder
			togglelog(0)
			myfileopendialog()
			_expand_all_click()
			If $ffileslisted = 0 Then
				GUICtrlSetState($idbtncure, 128)
				GUICtrlSetState($idbtndeselectall, 128)
				GUICtrlSetState($idbuttonsearch, 64)
				GUICtrlSetState($idbuttonsearch, 256)
			Else
				GUICtrlSetState($idbuttonsearch, 128)
				GUICtrlSetState($idbtndeselectall, 64)
				GUICtrlSetState($idbtncure, 64)
				GUICtrlSetState($idbtncure, 256)
			EndIf
		Case $idmsg = $idbtndeselectall
			togglelog(0)
			If $listviewselectflag = 1 Then
				For $i = 0 To _GUICtrlListView_GetItemCount($idlistview) - 1
					_GUICtrlListView_SetItemChecked($idlistview, $i, 0)
				Next
				$listviewselectflag = 0
			Else
				For $i = 0 To _GUICtrlListView_GetItemCount($idlistview) - 1
					_GUICtrlListView_SetItemChecked($idlistview, $i, 1)
				Next
				$listviewselectflag = 1
			EndIf
		Case $idmsg = $idbtncure
			togglelog(0)
			GUICtrlSetState($idlistview, 128)
			GUICtrlSetState($idbtndeselectall, 128)
			GUICtrlSetState($idbuttonsearch, 128)
			GUICtrlSetState($idbtncure, 128)
			GUICtrlSetState($idbtnrestore, 128)
			GUICtrlSetState($idbuttoncustomfolder, 128)
			GUICtrlSetState($idbtnupdatehosts, 128)
			GUICtrlSetState($idbtncleanhosts, 128)
			GUICtrlSetState($idbtnedithosts, 128)
			GUICtrlSetState($idbtncreatefw, 128)
			GUICtrlSetState($idbtntogglefw, 128)
			GUICtrlSetState($idbtnremovefw, 128)
			GUICtrlSetState($idbtnopenwf, 128)
			GUICtrlSetState($idbtntoggleruntimeinstaller, 128)
			GUICtrlSetState($idbtntogglewintrust, 128)
			GUICtrlSetState($idbtndevoverride, 128)
			GUICtrlSetState($idbtnremoveags, 128)
			GUICtrlSetState($idbtnrestorehosts, 128)
			GUICtrlSetState($idbtnagsinfo, 128)
			GUICtrlSetState($idbtnfirewallinfo, 128)
			GUICtrlSetState($idbtnhostsinfo, 128)
			GUICtrlSetState($idbtnruntimeinfo, 128)
			GUICtrlSetState($idbtnwintrustinfo, 128)
			_expand_all_click()
			_GUICtrlListView_EnsureVisible($idlistview, 0, 0)
			Local $itemfromlist
			For $i = 0 To _GUICtrlListView_GetItemCount($idlistview) - 1
				If _GUICtrlListView_GetItemChecked($idlistview, $i) = True Then
					_GUICtrlListView_SetItemSelected($idlistview, $i)
					$itemfromlist = _GUICtrlListView_GetItemText($idlistview, $i, 1)
					myglobalpatternsearch($itemfromlist)
					progresswrite(0)
					Sleep(100)
					memowrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $itemfromlist & @CRLF & "---" & @CRLF & "medication :)")
					logwrite(1, $itemfromlist)
					Sleep(100)
					myglobalpatternpatch($itemfromlist, $aouthexglobalarray)
					_GUICtrlListView_Scroll($idlistview, 0, 10)
					_GUICtrlListView_EnsureVisible($idlistview, $i, 0)
					Sleep(100)
				EndIf
				_GUICtrlListView_SetItemChecked($idlistview, $i, False)
			Next
			_GUICtrlListView_DeleteAllItems($g_idlistview)
			_GUICtrlListView_SetExtendedListViewStyle($idlistview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
			_GUICtrlListView_RemoveAllGroups($idlistview)
			_GUICtrlListView_InsertGroup($idlistview, -1, 1, '', 1)
			_GUICtrlListView_SetGroupInfo($idlistview, 1, "Info", 1, $LVGS_COLLAPSIBLE)
			memowrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $mydefpath & @CRLF & "---" & @CRLF & "waiting for user action")
			GUICtrlSetState($idlistview, 64)
			GUICtrlSetState($idbuttonsearch, 64)
			GUICtrlSetState($idbuttoncustomfolder, 64)
			GUICtrlSetState($idbtnrestore, 128)
			GUICtrlSetState($idbtncure, 128)
			GUICtrlSetState($idbuttonsearch, 256)
			GUICtrlSetState($idbtnupdatehosts, 64)
			GUICtrlSetState($idbtncleanhosts, 64)
			GUICtrlSetState($idbtnedithosts, 64)
			GUICtrlSetState($idbtncreatefw, 64)
			GUICtrlSetState($idbtntogglefw, 64)
			GUICtrlSetState($idbtnremovefw, 64)
			GUICtrlSetState($idbtnopenwf, 64)
			GUICtrlSetState($idbtntoggleruntimeinstaller, 64)
			GUICtrlSetState($idbtntogglewintrust, 64)
			GUICtrlSetState($idbtndevoverride, 64)
			GUICtrlSetState($idbtnremoveags, 64)
			GUICtrlSetState($idbtnrestorehosts, 64)
			GUICtrlSetState($idbtnagsinfo, 64)
			GUICtrlSetState($idbtnfirewallinfo, 64)
			GUICtrlSetState($idbtnhostsinfo, 64)
			GUICtrlSetState($idbtnruntimeinfo, 64)
			GUICtrlSetState($idbtnwintrustinfo, 64)
			filllistviewwithinfo()
			If $bfoundacro32 = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "AdobeGenP does not patch the x32 bit version of Acrobat. Please use the x64 bit version of Acrobat.")
				logwrite(1, "AdobeGenP does not patch the x32 bit version of Acrobat. Please use the x64 bit version of Acrobat.")
			EndIf
			If $bfoundgenericarm = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "This AdobeGenP build does not support ARM binaries, only x64.")
				logwrite(1, "This AdobeGenP build does not support ARM binaries, only x64.")
			EndIf
			togglelog(1)
			GUICtrlSetState($hlogtab, $GUI_SHOW)
		Case $idmsg = $idbtnrestore
			GUICtrlSetData($idlog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "AdobeGenP Version: " & $g_version & '' & @CRLF & "Config Version: " & $configvervar & '' & @CRLF)
			togglelog(0)
			GUICtrlSetState($idlistview, 128)
			GUICtrlSetState($idbtndeselectall, 128)
			GUICtrlSetState($idbuttonsearch, 128)
			GUICtrlSetState($idbtncure, 128)
			GUICtrlSetState($idbtnrestore, 128)
			GUICtrlSetState($idbuttoncustomfolder, 128)
			GUICtrlSetState($idbtnupdatehosts, 128)
			GUICtrlSetState($idbtncleanhosts, 128)
			GUICtrlSetState($idbtnedithosts, 128)
			GUICtrlSetState($idbtncreatefw, 128)
			GUICtrlSetState($idbtntogglefw, 128)
			GUICtrlSetState($idbtnremovefw, 128)
			GUICtrlSetState($idbtnopenwf, 128)
			GUICtrlSetState($idbtntoggleruntimeinstaller, 128)
			GUICtrlSetState($idbtntogglewintrust, 128)
			GUICtrlSetState($idbtndevoverride, 128)
			GUICtrlSetState($idbtnremoveags, 128)
			GUICtrlSetState($idbtnrestorehosts, 128)
			GUICtrlSetState($idbtnagsinfo, 128)
			GUICtrlSetState($idbtnfirewallinfo, 128)
			GUICtrlSetState($idbtnhostsinfo, 128)
			GUICtrlSetState($idbtnruntimeinfo, 128)
			GUICtrlSetState($idbtnwintrustinfo, 128)
			_expand_all_click()
			_GUICtrlListView_EnsureVisible($idlistview, 0, 0)
			Local $itemfromlist, $icheckeditems, $iprogress
			For $i = 0 To _GUICtrlListView_GetItemCount($idlistview) - 1
				If _GUICtrlListView_GetItemChecked($idlistview, $i) = True Then
					_GUICtrlListView_SetItemSelected($idlistview, $i)
					$itemfromlist = _GUICtrlListView_GetItemText($idlistview, $i, 1)
					$icheckeditems = _GUICtrlListView_GetSelectedCount($idlistview)
					$iprogress = 100 / $icheckeditems
					progresswrite(0)
					restorefile($itemfromlist)
					progresswrite($iprogress)
					Sleep(100)
					memowrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $itemfromlist & @CRLF & "---" & @CRLF & "restoring :)")
					Sleep(100)
					_GUICtrlListView_Scroll($idlistview, 0, 10)
					_GUICtrlListView_EnsureVisible($idlistview, $i, 0)
					Sleep(100)
				EndIf
				_GUICtrlListView_SetItemChecked($idlistview, $i, False)
			Next
			_GUICtrlListView_DeleteAllItems($g_idlistview)
			_GUICtrlListView_SetExtendedListViewStyle($idlistview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
			_GUICtrlListView_RemoveAllGroups($idlistview)
			_GUICtrlListView_InsertGroup($idlistview, -1, 1, '', 1)
			_GUICtrlListView_SetGroupInfo($idlistview, 1, "Info", 1, $LVGS_COLLAPSIBLE)
			memowrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $mydefpath & @CRLF & "---" & @CRLF & "waiting for user action")
			GUICtrlSetState($idlistview, 64)
			GUICtrlSetState($idbuttoncustomfolder, 64)
			GUICtrlSetState($idbtnrestore, 128)
			GUICtrlSetState($idbtncure, 128)
			GUICtrlSetState($idbuttonsearch, 64)
			GUICtrlSetState($idbuttonsearch, 256)
			GUICtrlSetState($idbtnupdatehosts, 64)
			GUICtrlSetState($idbtncleanhosts, 64)
			GUICtrlSetState($idbtnedithosts, 64)
			GUICtrlSetState($idbtncreatefw, 64)
			GUICtrlSetState($idbtntogglefw, 64)
			GUICtrlSetState($idbtnremovefw, 64)
			GUICtrlSetState($idbtnopenwf, 64)
			GUICtrlSetState($idbtntoggleruntimeinstaller, 64)
			GUICtrlSetState($idbtntogglewintrust, 64)
			GUICtrlSetState($idbtndevoverride, 64)
			GUICtrlSetState($idbtnremoveags, 64)
			GUICtrlSetState($idbtnrestorehosts, 64)
			GUICtrlSetState($idbtnagsinfo, 64)
			GUICtrlSetState($idbtnfirewallinfo, 64)
			GUICtrlSetState($idbtnhostsinfo, 64)
			GUICtrlSetState($idbtnruntimeinfo, 64)
			GUICtrlSetState($idbtnwintrustinfo, 64)
			filllistviewwithinfo()
			togglelog(1)
		Case $idmsg = $idbtncopylog
			sendtoclipboard()
		Case $idmsg = $idfindacc
			If _ischecked($idfindacc) Then
				$bfindacc = 1
			Else
				$bfindacc = 0
			EndIf
		Case $idmsg = $idenablemd5
			If _ischecked($idenablemd5) Then
				$benablemd5 = 1
			Else
				$benablemd5 = 0
			EndIf
		Case $idmsg = $idonlyadobefolders
			If _ischecked($idonlyadobefolders) Then
				$bonlyadobefolders = 1
			Else
				$bonlyadobefolders = 0
			EndIf
		Case $idmsg = $idbtnsaveoptions
			saveoptionstoconfig()
		Case $idmsg = $idbtnremoveags
			removeags()
		Case $idmsg = $idbtnupdatehosts
			togglelog(0)
			updatehostsfile()
		Case $idmsg = $idbtncleanhosts
			removehostsentries()
		Case $idmsg = $idbtnedithosts
			edithosts()
		Case $idmsg = $idbtnrestorehosts
			restorehosts()
		Case $idmsg = $idbtncreatefw
			togglelog(0)
			createfirewallrules()
		Case $idmsg = $idbtntogglefw
			togglelog(0)
			showtogglerulesgui()
		Case $idmsg = $idbtnremovefw
			togglelog(0)
			removefirewallrules()
		Case $idmsg = $idbtnopenwf
			openwf()
		Case $idmsg = $idbtntoggleruntimeinstaller
			togglelog(0)
			unpackruntimeinstallers()
		Case $idmsg = $idbtntogglewintrust
			togglelog(0)
			managewintrust()
		Case $idmsg = $idbtndevoverride
			togglelog(0)
			managedevoverride()
		Case $idmsg = $idbtnagsinfo
			showinfopopup("Removes Adobe Genuine Services (AGS) and related files to remove the 'Adobe Genuine Service Alert' popup." & @CRLF & @CRLF & "Removal of AGS will ONLY stop popups which say 'Adobe Genuine Service Alert' in the popup title bar.")
		Case $idmsg = $idbtnfirewallinfo
			showinfopopup("Manages Windows Firewall rules to block Adobe apps from accessing the internet -- stopping non-AGS popups. Easily add outbound rules for any installed app, toggle all rules off/on, or delete all rules." & @CRLF & @CRLF & "Some app features may not work when cut from internet.")
		Case $idmsg = $idbtnhostsinfo
			showinfopopup("Manages hosts file -- specifically targeting domains used for non-AGS popups. Auto update hosts using the provided list URL (Options), manually edit in Notepad, remove all entries, or restore a backup." & @CRLF & @CRLF & "Hosts must be updated regularly to remain effective.")
		Case $idmsg = $idbtnruntimeinfo
			showinfopopup("Select apps may pack the RuntimeInstaller.dll with UPX causing patching to fail. AdobeGenP can unpack these files so they can then be patched." & @CRLF & @CRLF & "This method is currently only needed with After Effects and Premiere Pro.")
		Case $idmsg = $idbtnwintrustinfo
			showinfopopup("Avoid all non-AGS popups by ' trusting' each app. Uses a modified DLL + registry edit for allowing DLL redirection. Trust/Untrust each app or add/remove the reg key as needed. Reg key is auto-added when trusting apps." & @CRLF & @CRLF & "Thanks to Team V.R for wintrust.dll!")
	EndSelect
WEnd

Func maingui()
	$myhgui = GUICreate($g_appwndtitle, 595, 510, -1, -1, BitOR($WS_MAXIMIZEBOX, $WS_MINIMIZEBOX, $WS_SIZEBOX, $GUI_SS_DEFAULT_GUI))
	$htab = GUICtrlCreateTab(0, 1, 597, 510)
	$hmaintab = GUICtrlCreateTabItem("Main")
	$idlistview = GUICtrlCreateListView('', 10, 35, 575, 355)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$g_idlistview = GUICtrlGetHandle($idlistview)
	_GUICtrlListView_SetExtendedListViewStyle($idlistview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))
	$istyles = _WinAPI_GetWindowLong($myhgui, $gwl_style)
	_WinAPI_SetWindowLong($myhgui, $gwl_style, BitXOR($istyles, $WS_SIZEBOX, $WS_MINIMIZEBOX, $WS_MAXIMIZEBOX))
	_GUICtrlListView_SetItemCount($idlistview, UBound($filestopatch))
	_GUICtrlListView_AddColumn($idlistview, '', 20)
	_GUICtrlListView_AddColumn($idlistview, "[Click to expand/collapse all]", 532, 2)
	_GUICtrlListView_EnableGroupView($idlistview)
	_GUICtrlListView_InsertGroup($idlistview, -1, 1, '', 1)
	_GUICtrlListView_SetGroupInfo($idlistview, 1, "Info", 1, $LVGS_COLLAPSIBLE)
	filllistviewwithinfo()
	$idbuttoncustomfolder = GUICtrlCreateButton("Path", 10, 430, 80, 30)
	GUICtrlSetTip(-1, "Set custom search path")
	GUICtrlSetImage(-1, "imageres.dll", -4, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbuttonsearch = GUICtrlCreateButton("Search", 134, 430, 80, 30)
	GUICtrlSetTip(-1, "Search path for installed apps")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbuttonstop = GUICtrlCreateButton("Stop", 134, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetTip(-1, "Stop search")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtncure = GUICtrlCreateButton("Patch", 258, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Patch selected file(s)")
	GUICtrlSetImage(-1, "imageres.dll", -102, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtndeselectall = GUICtrlCreateButton("De/Select", 381, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "De/Select all files")
	GUICtrlSetImage(-1, "imageres.dll", -76, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnrestore = GUICtrlCreateButton("Restore", 505, 430, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Restore original file(s)")
	GUICtrlSetImage(-1, "imageres.dll", -113, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idprogressbar = GUICtrlCreateProgress(10, 397, 575, 25, $PBS_SMOOTHREVERSE)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlCreateLabel($g_appversion, 10, 477, 575, 30, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM)
	GUICtrlCreateTabItem('')
	$hoptionstab = GUICtrlCreateTabItem("Options")
	$idfindacc = GUICtrlCreateCheckbox("Always search for ACC", 10, 50, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bfindacc = 1 Then
		GUICtrlSetState($idfindacc, $GUI_CHECKED)
	Else
		GUICtrlSetState($idfindacc, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idenablemd5 = GUICtrlCreateCheckbox("Enable MD5 Checksum", 10, 90, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $benablemd5 = 1 Then
		GUICtrlSetState($idenablemd5, $GUI_CHECKED)
	Else
		GUICtrlSetState($idenablemd5, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idonlyadobefolders = GUICtrlCreateCheckbox("Search for files only in Adobe/Acrobat folders", 10, 130, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bonlyadobefolders = 1 Then
		GUICtrlSetState($idonlyadobefolders, $GUI_CHECKED)
	Else
		GUICtrlSetState($idonlyadobefolders, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idcustomdomainlistlabel = GUICtrlCreateLabel("Hosts List URL:", 10, 180, 100, 20)
	$idcustomdomainlistinput = GUICtrlCreateInput($scurrentdomainlisturl, 90, 175, 490, 20, BitOR($ES_LEFT, $ES_WANTRETURN, $ES_AUTOHSCROLL))
	GUICtrlSetLimit($idcustomdomainlistinput, 255)
	$idbtnsaveoptions = GUICtrlCreateButton("Save Options", 247, 430, 100, 30)
	GUICtrlSetTip(-1, "Save options to config.ini")
	GUICtrlSetImage(-1, "imageres.dll", 5358, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlCreateTabItem('')
	$hpopuptab = GUICtrlCreateTabItem("Pop-up Tools")
	$idbtnagsinfo = GUICtrlCreateButton("?", 385, 38, 20, 20)
	GUICtrlSetFont($idbtnagsinfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idbtnagsinfo, $GUI_DOCKAUTO)
	$sremoveagstext = "ADOBE GENUINE SERVICES"
	$idlabelremoveags = GUICtrlCreateLabel($sremoveagstext, 5, 40, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idlabelremoveags, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnremoveags = GUICtrlCreateButton("Remove AGS", 225, 65, 140, 30)
	GUICtrlSetTip(-1, "Remove AGS-related files/services to remove AGS pop-up")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnfirewallinfo = GUICtrlCreateButton("?", 330, 113, 20, 20)
	GUICtrlSetFont($idbtnfirewallinfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idbtnfirewallinfo, $GUI_DOCKAUTO)
	$scleanfirewalltext = "FIREWALL"
	$idlabelcleanfirewall = GUICtrlCreateLabel($scleanfirewalltext, 5, 115, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idlabelcleanfirewall, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtncreatefw = GUICtrlCreateButton("Add Rules", 10, 140, 140, 30)
	GUICtrlSetTip(-1, "Add new firewall rules")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtntogglefw = GUICtrlCreateButton("Toggle Rules", 155, 140, 140, 30)
	GUICtrlSetTip(-1, "Enable/Disable all AdobeGenP firewall rules")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnremovefw = GUICtrlCreateButton("Remove Rules", 300, 140, 140, 30)
	GUICtrlSetTip(-1, "Remove all AdobeGenP firewall rules")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnopenwf = GUICtrlCreateButton("Open Windows Firewall", 445, 140, 140, 30)
	GUICtrlSetTip(-1, "Open Windows Firewall with Advanced Security console")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnhostsinfo = GUICtrlCreateButton("?", 320, 188, 20, 20)
	GUICtrlSetFont($idbtnhostsinfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idbtnhostsinfo, $GUI_DOCKAUTO)
	$sedithoststext = "HOSTS"
	$idlabeledithosts = GUICtrlCreateLabel($sedithoststext, 5, 190, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idlabeledithosts, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnupdatehosts = GUICtrlCreateButton("Update hosts", 10, 215, 140, 30)
	GUICtrlSetTip(-1, "Update hosts with domains from hosts list URL")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnedithosts = GUICtrlCreateButton("Edit hosts", 155, 215, 140, 30)
	GUICtrlSetTip(-1, "Manually edit hosts in notepad")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtncleanhosts = GUICtrlCreateButton("Clean hosts", 300, 215, 140, 30)
	GUICtrlSetTip(-1, "Remove hosts added by AdobeGenP")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnrestorehosts = GUICtrlCreateButton("Restore hosts", 445, 215, 140, 30)
	GUICtrlSetState($idbtnrestorehosts, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Restore hosts from hosts.bak")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnruntimeinfo = GUICtrlCreateButton("?", 365, 263, 20, 20)
	GUICtrlSetFont($idbtnruntimeinfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idbtnruntimeinfo, $GUI_DOCKAUTO)
	$sruntimeinstallertext = "RUNTIME INSTALLER"
	$idlabelruntimeinstaller = GUICtrlCreateLabel($sruntimeinstallertext, 5, 265, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idlabelruntimeinstaller, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtntoggleruntimeinstaller = GUICtrlCreateButton("Unpack", 225, 290, 140, 30)
	GUICtrlSetTip(-1, "Unpack RuntimeInstaller.dll")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtnwintrustinfo = GUICtrlCreateButton("?", 333, 338, 20, 20)
	GUICtrlSetFont($idbtnwintrustinfo, 10, 400, 0, "Arial")
	GUICtrlSetResizing($idbtnwintrustinfo, $GUI_DOCKAUTO)
	$swintrusttext = "WINTRUST"
	$idlabelwintrust = GUICtrlCreateLabel($swintrusttext, 5, 340, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idlabelwintrust, 10, 700)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtntogglewintrust = GUICtrlCreateButton("Toggle WinTrust", 155, 365, 140, 30)
	GUICtrlSetTip(-1, "Enable/disable wintrust.dll override")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$idbtndevoverride = GUICtrlCreateButton("Toggle Reg Key", 300, 365, 140, 30)
	GUICtrlSetTip(-1, "Add/remove DevOverrideEnable registry key")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlCreateTabItem('')
	$hlogtab = GUICtrlCreateTabItem("Log")
	$idmemo = GUICtrlCreateEdit('', 10, 35, 575, 355, BitOR($ES_READONLY, $ES_CENTER, $WS_DISABLED))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	$idlog = GUICtrlCreateEdit('', 10, 35, 575, 355, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetState($idlog, $GUI_HIDE)
	GUICtrlSetData($idlog, "Activity Log" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "AdobeGenP Version: " & $g_version & '' & @CRLF & "Config Version: " & $configvervar & '' & @CRLF)
	$idbtncopylog = GUICtrlCreateButton("Copy", 257, 430, 80, 30)
	GUICtrlSetTip(-1, "Copy log to clipboard")
	GUICtrlSetImage(-1, "imageres.dll", -77, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlCreateLabel($g_appversion, 10, 477, 575, 30, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM)
	GUICtrlCreateTabItem('')
	memowrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $mydefpath & @CRLF & "---" & @CRLF & "Waiting for user action.")
	GUICtrlSetState($idbuttonsearch, 256)
	GUISetState(@SW_SHOW)
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
EndFunc   ;==>maingui

Func recursivefilesearch($instartdir, $depth, $filecount)
	_GUICtrlListView_SetItemText($idlistview, 1, "Searching for files.", 1)
	Local $recursivefilesearch_maxdeep = 8
	If $depth > $recursivefilesearch_maxdeep Then Return
	Local $startdir = $instartdir & "\"
	$filesearchedcount += 1
	Local $hsearch = FileFindFirstFile($startdir & "*.*")
	If @error Then Return
	Local $next, $ipath, $isdir
	While $finterrupt = 0
		$next = FileFindNextFile($hsearch)
		$filesearchedcount += 1
		If @error Then ExitLoop
		$isdir = StringInStr(FileGetAttrib($startdir & $next), "D")
		If $isdir Then
			Local $targetdepth
			$targetdepth = recursivefilesearch($startdir & $next, $depth + 1, $filecount)
		Else
			$ipath = $startdir & $next
			Local $filenamecropped, $pathtocheck
			If (IsArray($targetfilelist_adobe)) Then
				For $adobefiletarget In $targetfilelist_adobe
					If StringInStr($adobefiletarget, "$") Then
						$adobefiletarget = StringSplit($adobefiletarget, "$", $STR_ENTIRESPLIT)
						$pathtocheck = $adobefiletarget[2]
						$adobefiletarget = $adobefiletarget[1]
					EndIf
					$filenamecropped = StringSplit(StringLower($ipath), StringLower($adobefiletarget), $STR_ENTIRESPLIT)
					If @error <> 1 Then
						If Not StringInStr($ipath, ".bak") And Not StringInStr(StringLower($ipath), "wintrust") Then
							If (StringInStr($ipath, "Adobe") Or StringInStr($ipath, "Acrobat")) Or $bonlyadobefolders = 0 Then
								If $pathtocheck = '' Then
									_ArrayAdd($filestopatch, $ipath)
								Else
									If StringInStr($ipath, $pathtocheck) Then
										_ArrayAdd($filestopatch, $ipath)
									EndIf
								EndIf
							EndIf
						ElseIf StringInStr($ipath, ".bak") Then
							_ArrayAdd($filestorestore, $ipath)
						EndIf
					EndIf
					$pathtocheck = ''
				Next
			EndIf
		EndIf
	WEnd
	If 1 = Random(0, 10, 1) Then
		memowrite(@CRLF & "Searching in " & $filecount & " files" & @TAB & @TAB & "Found : " & UBound($filestopatch) & @CRLF & "---" & @CRLF & "Level: " & $depth & " Time elapsed : " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s)" & @TAB & @TAB & "Excluded because of *.bak: " & UBound($filestorestore) & @CRLF & "---" & @CRLF & $instartdir)
		progresswrite($progressfilecountscale * $filesearchedcount)
	EndIf
	FileClose($hsearch)
EndFunc   ;==>recursivefilesearch

Func filllistviewwithinfo()
	_GUICtrlListView_DeleteAllItems($g_idlistview)
	_GUICtrlListView_SetExtendedListViewStyle($idlistview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
	_expand_all_click()
	_GUICtrlListView_SetGroupInfo($idlistview, 1, "Info", 1, $LVGS_COLLAPSIBLE)
	For $i = 0 To 4
		_GUICtrlListView_AddItem($idlistview, '', $i)
		_GUICtrlListView_SetItemGroupID($idlistview, $i, 1)
	Next
	_GUICtrlListView_AddSubItem($idlistview, 0, '', 1)
	_GUICtrlListView_AddSubItem($idlistview, 1, "Adobe Generic Patcher", 1)
	_GUICtrlListView_AddSubItem($idlistview, 2, "---------------", 1)
	_GUICtrlListView_AddSubItem($idlistview, 3, "Press 'Search' to find installed products; 'Patch' to patch selected products/files", 1)
	_GUICtrlListView_AddSubItem($idlistview, 4, "Default search path: C:\Program Files\Adobe -- press 'Path' to change", 1)
	$ffileslisted = 0
EndFunc   ;==>filllistviewwithinfo

Func filllistviewwithfiles()
	_GUICtrlListView_DeleteAllItems($g_idlistview)
	_GUICtrlListView_SetExtendedListViewStyle($idlistview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))
	If UBound($filestopatch) > 0 Then
		Global $aitems[UBound($filestopatch)][2]
		For $i = 0 To UBound($aitems) - 1
			$aitems[$i][0] = $i
			$aitems[$i][1] = $filestopatch[$i][0]
		Next
		_GUICtrlListView_AddArray($idlistview, $aitems)
		memowrite(@CRLF & UBound($filestopatch) & " File(s) were found in " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s) at:" & @CRLF & "---" & @CRLF & $mydefpath & @CRLF & "---" & @CRLF & "Press the 'Patch Files'")
		logwrite(1, UBound($filestopatch) & " File(s) were found in " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s)" & @CRLF)
		$ffileslisted = 1
	Else
		memowrite(@CRLF & "Nothing was found in" & @CRLF & "---" & @CRLF & $mydefpath & @CRLF & "---" & @CRLF & "waiting for user action")
		logwrite(1, "Nothing was found in " & $mydefpath)
		$ffileslisted = 0
	EndIf
EndFunc   ;==>filllistviewwithfiles

Func memowrite($smessage)
	GUICtrlSetData($idmemo, $smessage)
EndFunc   ;==>memowrite

Func logwrite($bts, $smessage)
	guictrlsetdataex($idlog, $smessage, $bts)
EndFunc   ;==>logwrite

Func togglelog($bshow)
	If $bshow = 1 Then
		GUICtrlSetState($idmemo, $GUI_HIDE)
		GUICtrlSetState($idlog, $GUI_SHOW)
	Else
		GUICtrlSetState($idlog, $GUI_HIDE)
		GUICtrlSetState($idmemo, $GUI_SHOW)
	EndIf
EndFunc   ;==>togglelog

Func sendtoclipboard()
	If BitAND(GUICtrlGetState($idmemo), $GUI_HIDE) = $GUI_HIDE Then
		ClipPut(GUICtrlRead($idlog))
	Else
		ClipPut(GUICtrlRead($idmemo))
	EndIf
EndFunc   ;==>sendtoclipboard

Func guictrlsetdataex($hwnd, $stext, $bts)
	If Not IsHWnd($hwnd) Then $hwnd = GUICtrlGetHandle($hwnd)
	Local $ilength = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hwnd, "uint", 14, "wparam", 0, "lparam", 0)
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hwnd, "uint", 177, "wparam", $ilength[0], "lparam", $ilength[0])
	If $bts = 1 Then
		Local $idata = @CRLF & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " " & $stext
	Else
		Local $idata = $stext
	EndIf
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hwnd, "uint", 194, "wparam", True, "wstr", $idata)
EndFunc   ;==>guictrlsetdataex

Func progresswrite($msg_progress)
	GUICtrlSetData($idprogressbar, $msg_progress)
EndFunc   ;==>progresswrite

Func myfileopendialog()
	Local Const $smessage = "Select a Path"
	Local $mytemppath = FileSelectFolder($smessage, $mydefpath, 0, $mydefpath, $myhgui)
	If @error Then
		memowrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $mydefpath & @CRLF & "---" & @CRLF & "waiting for user action")
	Else
		GUICtrlSetState($idbtncure, 128)
		$mydefpath = $mytemppath
		IniWrite($sinipath, "Default", "Path", $mydefpath)
		_GUICtrlListView_DeleteAllItems($g_idlistview)
		_GUICtrlListView_SetExtendedListViewStyle($idlistview, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT, $LVS_EX_SUBITEMIMAGES))
		_GUICtrlListView_AddItem($idlistview, '', 0)
		_GUICtrlListView_AddItem($idlistview, '', 1)
		_GUICtrlListView_AddItem($idlistview, '', 2)
		_GUICtrlListView_AddItem($idlistview, '', 3)
		_GUICtrlListView_AddItem($idlistview, '', 4)
		_GUICtrlListView_AddItem($idlistview, '', 5)
		_GUICtrlListView_AddItem($idlistview, '', 6)
		_GUICtrlListView_AddSubItem($idlistview, 0, '', 1)
		_GUICtrlListView_AddSubItem($idlistview, 1, "Path:", 1)
		_GUICtrlListView_AddSubItem($idlistview, 2, " " & $mydefpath, 1)
		_GUICtrlListView_AddSubItem($idlistview, 3, "Step 1:", 1)
		_GUICtrlListView_AddSubItem($idlistview, 4, " Press 'Search' - wait until search completes", 1)
		_GUICtrlListView_AddSubItem($idlistview, 5, "Step 2:", 1)
		_GUICtrlListView_AddSubItem($idlistview, 6, " Press 'Patch' - wait until patching completes", 1)
		_GUICtrlListView_SetItemGroupID($idlistview, 0, 1)
		_GUICtrlListView_SetItemGroupID($idlistview, 1, 1)
		_GUICtrlListView_SetItemGroupID($idlistview, 2, 1)
		_GUICtrlListView_SetItemGroupID($idlistview, 3, 1)
		_GUICtrlListView_SetItemGroupID($idlistview, 4, 1)
		_GUICtrlListView_SetItemGroupID($idlistview, 5, 1)
		_GUICtrlListView_SetItemGroupID($idlistview, 6, 1)
		_GUICtrlListView_SetGroupInfo($idlistview, 1, "Info", 1, $LVGS_COLLAPSIBLE)
		memowrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $mydefpath & @CRLF & "---" & @CRLF & "Press the Search button")
		GUICtrlSetState($idbtnupdatehosts, 64)
		GUICtrlSetState($idbtncleanhosts, 64)
		GUICtrlSetState($idbtnedithosts, 64)
		GUICtrlSetState($idbtncreatefw, 64)
		GUICtrlSetState($idbtntogglefw, 64)
		GUICtrlSetState($idbtnremovefw, 64)
		GUICtrlSetState($idbtnopenwf, 64)
		GUICtrlSetState($idbtntoggleruntimeinstaller, 64)
		GUICtrlSetState($idbtntogglewintrust, 64)
		GUICtrlSetState($idbtndevoverride, 64)
		GUICtrlSetState($idbtnremoveags, 64)
		GUICtrlSetState($idbtnrestorehosts, 64)
		GUICtrlSetState($idbtnrestore, 128)
		GUICtrlSetState($idbtnagsinfo, 64)
		GUICtrlSetState($idbtnfirewallinfo, 64)
		GUICtrlSetState($idbtnhostsinfo, 64)
		GUICtrlSetState($idbtnruntimeinfo, 64)
		GUICtrlSetState($idbtnwintrustinfo, 64)
		$ffileslisted = 0
	EndIf
EndFunc   ;==>myfileopendialog

Func _processcloseex($sname)
	Local $ipid = Run("TASKKILL /F /T /IM " & $sname, @TempDir, @SW_HIDE)
	ProcessWaitClose($ipid)
EndFunc   ;==>_processcloseex

Func myglobalpatternsearch($myfiletoparse)
	$ainhexarray = $anullarray
	$aouthexglobalarray = $anullarray
	progresswrite(0)
	$myregexpglobalpatternsearchcount = 0
	$count = 15
	Local $sfilename = StringRegExpReplace($myfiletoparse, "^.*\\", '')
	Local $sext = StringRegExpReplace($sfilename, "^.*\.", '')
	memowrite(@CRLF & $myfiletoparse & @CRLF & "---" & @CRLF & "Preparing to Analyze" & @CRLF & "---" & @CRLF & "*****")
	logwrite(1, "Checking File: " & $sfilename & " ")
	If $sext = "exe" Then
		_processcloseex('"' & $sfilename & '"')
	EndIf
	If $sfilename = "Adobe Desktop Service.exe" Then
		_processcloseex('"Creative Cloud.exe"')
		Sleep(100)
	EndIf
	If $sfilename = "AppsPanelBL.dll" Then
		_processcloseex('"Creative Cloud.exe"')
		_processcloseex('"Adobe Desktop Service.exe"')
		Sleep(100)
	EndIf
	If $sfilename = "HDPIM.dll" Then
		_processcloseex('"Creative Cloud.exe"')
		_processcloseex('"Adobe Desktop Service.exe"')
		Sleep(100)
	EndIf
	If StringInStr($sspecialfiles, $sfilename) Then
		logwrite(0, " - using Custom Patterns")
		executesearchpatterns($sfilename, 0, $myfiletoparse)
	Else
		logwrite(0, " - using Default Patterns")
		executesearchpatterns($sfilename, 1, $myfiletoparse)
	EndIf
	Sleep(100)
EndFunc   ;==>myglobalpatternsearch

Func executesearchpatterns($filename, $defaultpatterns, $myfiletoparse)
	Local $apatterns, $spattern, $sdata, $aarray, $ssearch, $sreplace, $ipatternlength
	If $defaultpatterns = 0 Then
		$apatterns = inireadarray($sinipath, "CustomPatterns", $filename, '')
	Else
		$apatterns = inireadarray($sinipath, "DefaultPatterns", "Values", '')
	EndIf
	For $i = 0 To UBound($apatterns) - 1
		$spattern = $apatterns[$i]
		$sdata = IniRead($sinipath, "Patches", $spattern, '')
		If StringInStr($sdata, "|") Then
			$aarray = StringSplit($sdata, "|")
			If UBound($aarray) = 3 Then
				$ssearch = StringReplace($aarray[1], '"', '')
				$sreplace = StringReplace($aarray[2], '"', '')
				$ipatternlength = StringLen($ssearch)
				If $ipatternlength <> StringLen($sreplace) Or Mod($ipatternlength, 2) <> 0 Then
					MsgBox($MB_SYSTEMMODAL, "Error", "Pattern Error in config.ini:" & $spattern & @CRLF & $ssearch & @CRLF & $sreplace)
					Exit
				EndIf
				logwrite(1, "Searching for: " & $spattern & ": " & $ssearch)
				myregexpglobalpatternsearch($myfiletoparse, $ssearch, $sreplace, $spattern)
			EndIf
		EndIf
	Next
EndFunc   ;==>executesearchpatterns

Func myregexpglobalpatternsearch($filetoparse, $patterntosearch, $patterntoreplace, $patternname)
	Local $hfileopen = FileOpen($filetoparse, $FO_READ + $FO_BINARY)
	FileSetPos($hfileopen, 60, 0)
	$sz_type = FileRead($hfileopen, 4)
	FileSetPos($hfileopen, Number($sz_type) + 4, 0)
	$sz_type = FileRead($hfileopen, 2)
	If $sz_type = "0x4C01" And StringInStr($filetoparse, "Acrobat", 2) > 0 Then
		memowrite(@CRLF & $filetoparse & @CRLF & "---" & @CRLF & "File is 32-bit. Aborting..." & @CRLF & "---")
		FileClose($hfileopen)
		Sleep(100)
		$bfoundacro32 = True
	ElseIf $sz_type = "0x64AA" Then
		memowrite(@CRLF & $filetoparse & @CRLF & "---" & @CRLF & "File is ARM. Aborting..." & @CRLF & "---")
		FileClose($hfileopen)
		Sleep(100)
		$bfoundgenericarm = True
	Else
		FileSetPos($hfileopen, 0, 0)
		Local $sfileread = FileRead($hfileopen)
		Local $genequestionmark, $anynumofbytes, $outstringforregexp
		For $i = 256 To 1 Step -2
			$genequestionmark = _StringRepeat("??", $i / 2)
			$anynumofbytes = "(.{" & $i & "})"
			$outstringforregexp = StringReplace($patterntosearch, $genequestionmark, $anynumofbytes)
			$patterntosearch = $outstringforregexp
		Next
		Local $ssearchpattern = $outstringforregexp
		Local $areplacepattern = $patterntoreplace
		Local $swildcardsearchpattern = '', $swildcardreplacepattern = '', $sfinalreplacepattern = ''
		Local $ainhextemparray[0]
		Local $ssearchcharacter = '', $sreplacecharacter = ''
		$ainhextemparray = $anullarray
		$ainhextemparray = StringRegExp($sfileread, $ssearchpattern, $STR_REGEXPARRAYGLOBALFULLMATCH, 1)
		For $i = 0 To UBound($ainhextemparray) - 1
			$ainhexarray = $anullarray
			$ssearchcharacter = ''
			$sreplacecharacter = ''
			$swildcardsearchpattern = ''
			$swildcardreplacepattern = ''
			$sfinalreplacepattern = ''
			$ainhexarray = $ainhextemparray[$i]
			If @error = 0 Then
				$swildcardsearchpattern = $ainhexarray[0]
				$swildcardreplacepattern = $areplacepattern
				If StringInStr($swildcardreplacepattern, "?") Then
					For $j = 1 To StringLen($swildcardreplacepattern) + 1
						$ssearchcharacter = StringMid($swildcardsearchpattern, $j, 1)
						$sreplacecharacter = StringMid($swildcardreplacepattern, $j, 1)
						If $sreplacecharacter <> "?" Then
							$sfinalreplacepattern &= $sreplacecharacter
						Else
							$sfinalreplacepattern &= $ssearchcharacter
						EndIf
					Next
				Else
					$sfinalreplacepattern = $swildcardreplacepattern
				EndIf
				_ArrayAdd($aouthexglobalarray, $swildcardsearchpattern)
				_ArrayAdd($aouthexglobalarray, $sfinalreplacepattern)
				ConsoleWrite($patternname & "---" & @TAB & $swildcardsearchpattern & "	" & @CRLF)
				ConsoleWrite($patternname & "R" & "--" & @TAB & $sfinalreplacepattern & "	" & @CRLF)
				memowrite(@CRLF & $filetoparse & @CRLF & "---" & @CRLF & $patternname & @CRLF & "---" & @CRLF & $swildcardsearchpattern & @CRLF & $sfinalreplacepattern)
				logwrite(1, "Replacing with: " & $sfinalreplacepattern)
			Else
				ConsoleWrite($patternname & "---" & @TAB & "No" & "	" & @CRLF)
				memowrite(@CRLF & $filetoparse & @CRLF & "---" & @CRLF & $patternname & "---" & "No")
			EndIf
			$myregexpglobalpatternsearchcount += 1
		Next
		FileClose($hfileopen)
		$sfileread = ''
		progresswrite(Round($myregexpglobalpatternsearchcount / $count * 100))
		Sleep(100)
	EndIf
EndFunc   ;==>myregexpglobalpatternsearch

Func myglobalpatternpatch($myfiletopatch, $myarraytopatch)
	progresswrite(0)
	Local $irows = UBound($myarraytopatch)
	If $irows > 0 Then
		memowrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $myfiletopatch & @CRLF & "---" & @CRLF & "medication :)")
		Local $hfileopen = FileOpen($myfiletopatch, $FO_READ + $FO_BINARY)
		Local $sfileread = FileRead($hfileopen)
		Local $sstringout
		For $i = 0 To $irows - 1 Step 2
			$sstringout = StringReplace($sfileread, $myarraytopatch[$i], $myarraytopatch[$i + 1], 0, 1)
			$sfileread = $sstringout
			$sstringout = $sfileread
			progresswrite(Round($i / $irows * 100))
		Next
		FileClose($hfileopen)
		FileMove($myfiletopatch, $myfiletopatch & ".bak", $FC_OVERWRITE)
		Local $hfileopen1 = FileOpen($myfiletopatch, $FO_OVERWRITE + $FO_BINARY)
		FileWrite($hfileopen1, Binary($sstringout))
		FileClose($hfileopen1)
		progresswrite(0)
		Sleep(100)
		logwrite(1, "File patched by AdobeGenP " & $g_version & " + config " & $configvervar)
		If $benablemd5 = 1 Then
			_Crypt_Startup()
			Local $smd5checksum = _Crypt_HashFile($myfiletopatch, $calg_md5)
			If Not @error Then
				logwrite(1, "MD5 Checksum: " & $smd5checksum & @CRLF)
			EndIf
			_Crypt_Shutdown()
		EndIf
	Else
		memowrite(@CRLF & "No patterns were found" & @CRLF & "---" & @CRLF & "or" & @CRLF & "---" & @CRLF & "file is already patched.")
		Sleep(100)
		logwrite(1, "No patterns were found or file already patched." & @CRLF)
	EndIf
EndFunc   ;==>myglobalpatternpatch

Func restorefile($myfiletodelete)
	If FileExists($myfiletodelete & ".bak") Then
		If $myfiletodelete = "AppsPanelBL.dll" Or $myfiletodelete = "Adobe Desktop Service.exe" Then
			_processcloseex('"Creative Cloud.exe"')
			_processcloseex('"Adobe Desktop Service.exe"')
			Sleep(100)
		EndIf
		FileDelete($myfiletodelete)
		FileMove($myfiletodelete & ".bak", $myfiletodelete, $FC_OVERWRITE)
		Sleep(100)
		memowrite(@CRLF & "File restored" & @CRLF & "---" & @CRLF & $myfiletodelete)
		logwrite(1, $myfiletodelete)
		logwrite(1, "File restored.")
	Else
		Sleep(100)
		memowrite(@CRLF & "No backup file found" & @CRLF & "---" & @CRLF & $myfiletodelete)
		logwrite(1, $myfiletodelete)
		logwrite(1, "No backup file found.")
	EndIf
EndFunc   ;==>restorefile

Func _listview_leftclick($hlistview, $lparam)
	Local $tinfo = DllStructCreate($tagNMITEMACTIVATE, $lparam)
	Local $iindex = DllStructGetData($tinfo, "Index")
	If $iindex <> -1 Then
		Local $ix = DllStructGetData($tinfo, "X")
		Local $aiconrect = _GUICtrlListView_GetItemRect($hlistview, $iindex, 1)
		If $ix < $aiconrect[0] And $ix >= 5 Then
			Return 0
		Else
			Local $ahit
			$ahit = _GUICtrlListView_HitTest($g_idlistview)
			If $ahit[0] <> -1 Then
				Local $groupidofhititem = _GUICtrlListView_GetItemGroupID($idlistview, $ahit[0])
				If _GUICtrlListView_GetItemChecked($g_idlistview, $ahit[0]) = 1 Then
					For $i = 0 To _GUICtrlListView_GetItemCount($idlistview) - 1
						If _GUICtrlListView_GetItemGroupID($idlistview, $i) = $groupidofhititem Then
							_GUICtrlListView_SetItemChecked($g_idlistview, $i, 0)
						EndIf
					Next
				Else
					For $i = 0 To _GUICtrlListView_GetItemCount($idlistview) - 1
						If _GUICtrlListView_GetItemGroupID($idlistview, $i) = $groupidofhititem Then
							_GUICtrlListView_SetItemChecked($g_idlistview, $i, 1)
						EndIf
					Next
				EndIf
			EndIf
		EndIf
	EndIf
EndFunc   ;==>_listview_leftclick

Func _listview_rightclick()
	Local $ahit
	$ahit = _GUICtrlListView_HitTest($g_idlistview)
	If $ahit[0] <> -1 Then
		If _GUICtrlListView_GetItemChecked($g_idlistview, $ahit[0]) = 1 Then
			_GUICtrlListView_SetItemChecked($g_idlistview, $ahit[0], 0)
		Else
			_GUICtrlListView_SetItemChecked($g_idlistview, $ahit[0], 1)
		EndIf
	EndIf
EndFunc   ;==>_listview_rightclick

Func _assign_groups_to_found_files()
	ConsoleWrite("Entering _Assign_Groups_To_Found_Files()" & @CRLF)
	Local $mylistitemcount = _GUICtrlListView_GetItemCount($idlistview)
	ConsoleWrite("Item Count in ListView: " & $mylistitemcount & @CRLF)
	Local $itemfromlist
	Local $agroups[0]
	Local $igroupid = 1
	ReDim $g_agroupids[0]
	For $i = 0 To $mylistitemcount - 1
		$itemfromlist = _GUICtrlListView_GetItemText($idlistview, $i, 1)
		ConsoleWrite("Item Text (Column 2): " & $itemfromlist & @CRLF)
		Local $sgroupname = ''
		Select
			Case StringInStr($itemfromlist, "AppsPanel") Or StringInStr($itemfromlist, "Adobe Desktop Service") Or StringInStr($itemfromlist, "HDPIM")
				$sgroupname = "Creative Cloud"
			Case StringInStr($itemfromlist, "Acrobat")
				$sgroupname = "Acrobat"
			Case StringInStr($itemfromlist, "Aero")
				$sgroupname = "Aero"
			Case StringInStr($itemfromlist, "After Effects")
				$sgroupname = "After Effects"
			Case StringInStr($itemfromlist, "Animate")
				$sgroupname = "Animate"
			Case StringInStr($itemfromlist, "Audition")
				$sgroupname = "Audition"
			Case StringInStr($itemfromlist, "Adobe Bridge")
				$sgroupname = "Bridge"
			Case StringInStr($itemfromlist, "Character Animator")
				$sgroupname = "Character Animator"
			Case StringInStr($itemfromlist, "Dimension")
				$sgroupname = "Dimension"
			Case StringInStr($itemfromlist, "Dreamweaver")
				$sgroupname = "Dreamweaver"
			Case StringInStr($itemfromlist, "Illustrator")
				$sgroupname = "Illustrator"
			Case StringInStr($itemfromlist, "InCopy")
				$sgroupname = "InCopy"
			Case StringInStr($itemfromlist, "InDesign")
				$sgroupname = "InDesign"
			Case StringInStr($itemfromlist, "Lightroom CC")
				$sgroupname = "Lightroom CC"
			Case StringInStr($itemfromlist, "Lightroom Classic")
				$sgroupname = "Lightroom Classic"
			Case StringInStr($itemfromlist, "Media Encoder")
				$sgroupname = "Media Encoder"
			Case StringInStr($itemfromlist, "Photoshop")
				$sgroupname = "Photoshop"
			Case StringInStr($itemfromlist, "Premiere Pro")
				$sgroupname = "Premiere Pro"
			Case StringInStr($itemfromlist, "Premiere Rush")
				$sgroupname = "Premiere Rush"
			Case StringInStr($itemfromlist, "Substance 3D Designer")
				$sgroupname = "Substance 3D Designer"
			Case StringInStr($itemfromlist, "Substance 3D Modeler")
				$sgroupname = "Substance 3D Modeler"
			Case StringInStr($itemfromlist, "Substance 3D Painter")
				$sgroupname = "Substance 3D Painter"
			Case StringInStr($itemfromlist, "Substance 3D Sampler")
				$sgroupname = "Substance 3D Sampler"
			Case StringInStr($itemfromlist, "Substance 3D Stager")
				$sgroupname = "Substance 3D Stager"
			Case StringInStr($itemfromlist, "Substance 3D Viewer")
				$sgroupname = "Substance 3D Viewer"
			Case Else
				$sgroupname = "Else"
		EndSelect
		ConsoleWrite("Group Name Assigned: " & $sgroupname & @CRLF)
		Local $igroupindex = _ArraySearch($agroups, $sgroupname)
		If $igroupindex = -1 Then
			_ArrayAdd($agroups, $sgroupname)
			_GUICtrlListView_InsertGroup($idlistview, $i, $igroupid, '', 1)
			_GUICtrlListView_SetItemGroupID($idlistview, $i, $igroupid)
			_GUICtrlListView_SetGroupInfo($idlistview, $igroupid, $sgroupname, 1, $LVGS_COLLAPSIBLE)
			_ArrayAdd($g_agroupids, $igroupid)
			ConsoleWrite("New Group Created - ID: " & $igroupid & @CRLF)
			$igroupid += 1
		Else
			_GUICtrlListView_SetItemGroupID($idlistview, $i, $igroupindex + 1)
			ConsoleWrite("Assigned to Existing Group: " & $sgroupname & " (ID: " & $igroupindex + 1 & ")" & @CRLF)
		EndIf
	Next
	For $i = 0 To $mylistitemcount - 1
		_GUICtrlListView_SetItemChecked($idlistview, $i, 1)
	Next
	ConsoleWrite("Exiting _Assign_Groups_To_Found_Files()" & @CRLF)
	ConsoleWrite("Number of Groups in $g_aGroupIDs: " & UBound($g_agroupids) & @CRLF)
	For $i = 0 To UBound($g_agroupids) - 1
		ConsoleWrite("Group ID in $g_aGroupIDs: " & $g_agroupids[$i] & @CRLF)
	Next
EndFunc   ;==>_assign_groups_to_found_files

Func _collapse_all_click()
	Local $ainfo, $acount = _GUICtrlListView_GetGroupCount($idlistview)
	If $acount > 0 Then
		If $mylvgroupisexpanded = 1 Then
			_sendmessagel($idlistview, $WM_SETREDRAW, False, 0)
			For $i = 1 To 25
				$ainfo = _GUICtrlListView_GetGroupInfo($idlistview, $i)
				If IsArray($ainfo) Then
					_GUICtrlListView_SetGroupInfo($idlistview, $i, $ainfo[0], $ainfo[1], $LVGS_COLLAPSED)
				EndIf
			Next
			_sendmessagel($idlistview, $WM_SETREDRAW, True, 0)
			_redrawwindow($idlistview)
		Else
			_expand_all_click()
		EndIf
		$mylvgroupisexpanded = Not $mylvgroupisexpanded
	EndIf
EndFunc   ;==>_collapse_all_click

Func _expand_all_click()
	Local $ainfo, $acount = _GUICtrlListView_GetGroupCount($idlistview)
	If $acount > 0 Then
		_sendmessagel($idlistview, $WM_SETREDRAW, False, 0)
		For $i = 1 To 25
			$ainfo = _GUICtrlListView_GetGroupInfo($idlistview, $i)
			If IsArray($ainfo) Then
				_GUICtrlListView_SetGroupInfo($idlistview, $i, $ainfo[0], $ainfo[1], $LVGS_NORMAL)
				_GUICtrlListView_SetGroupInfo($idlistview, $i, $ainfo[0], $ainfo[1], $LVGS_COLLAPSIBLE)
			EndIf
		Next
		_sendmessagel($idlistview, $WM_SETREDRAW, True, 0)
		_redrawwindow($idlistview)
	EndIf
EndFunc   ;==>_expand_all_click

Func _sendmessagel($hwnd, $msg, $wparam, $lparam)
	Return DllCall("user32.dll", "LRESULT", "SendMessageW", "HWND", GUICtrlGetHandle($hwnd), "UINT", $msg, "WPARAM", $wparam, "LPARAM", $lparam)[0]
EndFunc   ;==>_sendmessagel

Func _redrawwindow($hwnd)
	DllCall("user32.dll", "bool", "RedrawWindow", "hwnd", GUICtrlGetHandle($hwnd), "ptr", 0, "ptr", 0, "uint", 256)
EndFunc   ;==>_redrawwindow

Func wm_command($hwnd, $msg, $wparam, $lparam)
	If BitAND($wparam, 65535) = $idbuttonstop Then $finterrupt = 1
	Return $GUI_RUNDEFMSG
EndFunc   ;==>wm_command

Func wm_notify($hwnd, $imsg, $wparam, $lparam)
	#forceref $hwnd, $imsg, $wparam, $lparam
	Local $tnmhdr = DllStructCreate($tagNMHDR, $lparam)
	Local $hwndfrom = HWnd(DllStructGetData($tnmhdr, "hWndFrom"))
	Local $icode = DllStructGetData($tnmhdr, "Code")
	Switch $hwndfrom
		Case $g_idlistview
			Switch $icode
				Case $LVN_COLUMNCLICK
					_collapse_all_click()
				Case $NM_CLICK
					_listview_leftclick($g_idlistview, $lparam)
				Case $NM_RCLICK
					_listview_rightclick()
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>wm_notify

Func _exit()
	Exit
EndFunc   ;==>_exit

Func inireadarray($filename, $section, $key, $default)
	Local $sini = IniRead($filename, $section, $key, $default)
	$sini = StringReplace($sini, '"', '')
	StringReplace($sini, ",", ",")
	Local $asize = @extended
	Local $areturn[$asize + 1]
	Local $asplit = StringSplit($sini, ",")
	For $i = 0 To $asize
		$areturn[$i] = $asplit[$i + 1]
	Next
	Return $areturn
EndFunc   ;==>inireadarray

Func _ischecked($idcontrolid)
	Return BitAND(GUICtrlRead($idcontrolid), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_ischecked

Func saveoptionstoconfig()
	If _ischecked($idfindacc) Then
		IniWrite($sinipath, "Options", "FindACC", "1")
	Else
		IniWrite($sinipath, "Options", "FindACC", "0")
	EndIf
	If _ischecked($idenablemd5) Then
		IniWrite($sinipath, "Options", "EnableMD5", "1")
	Else
		IniWrite($sinipath, "Options", "EnableMD5", "0")
	EndIf
	If _ischecked($idonlyadobefolders) Then
		IniWrite($sinipath, "Options", "OnlyAdobeFolders", "1")
	Else
		IniWrite($sinipath, "Options", "OnlyAdobeFolders", "0")
	EndIf
	Local $snewdomainlisturl = StringStripWS(GUICtrlRead($idcustomdomainlistinput), 1)
	If $snewdomainlisturl = '' Then
		$snewdomainlisturl = $sdefaultdomainlisturl
		GUICtrlSetData($idcustomdomainlistinput, $snewdomainlisturl)
		MsgBox(0, "Empty URL", "The custom domain list URL cannot be empty. Default URL set.")
	EndIf
	If $snewdomainlisturl <> $scurrentdomainlisturl Then
		IniWrite($sinipath, "Options", "CustomDomainListURL", $snewdomainlisturl)
		$scurrentdomainlisturl = $snewdomainlisturl
	EndIf
EndFunc   ;==>saveoptionstoconfig

Func showinfopopup($stext)
	Local $amainpos = WinGetPos($myhgui)
	If @error Then
		Local $ipopupx = -1
		Local $ipopupy = -1
	Else
		Local $ipopupx = $amainpos[0] + ($amainpos[2] - 300) / 2
		Local $ipopupy = $amainpos[1] + ($amainpos[3] - 100) / 2
	EndIf
	Local $hpopup = GUICreate('', 300, 100, $ipopupx, $ipopupy, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOPMOST)
	Local $idedit = GUICtrlCreateEdit($stext, 10, 10, 280, 80, BitOR($ES_READONLY, $ES_MULTILINE, $ES_AUTOVSCROLL), 0)
	GUICtrlSetBkColor($idedit, 15790320)
	GUISetState(@SW_SHOW, $hpopup)
	_GUICtrlEdit_SetSel($idedit, -1, -1)
	While WinActive($hpopup)
		If GUIGetMsg() = $GUI_EVENT_CLOSE Then ExitLoop
	WEnd
	GUIDelete($hpopup)
EndFunc   ;==>showinfopopup

Func removeags()
	GUICtrlSetState($idbtnremoveags, $GUI_DISABLE)
	_GUICtrlTab_SetCurFocus($htab, 3)
	memowrite(@CRLF & "Removing AGS from this Computer" & @CRLF & "---" & @CRLF & "Please wait...")
	Local $aservices = ["AGMService", "AGSService"]
	Local $programfilesx86 = EnvGet("ProgramFiles(x86)")
	Local $publicdir = EnvGet("PUBLIC")
	Local $windir = @WindowsDir
	Local $localappdata = EnvGet("LOCALAPPDATA")
	Local $apaths[9] = [$programfilesx86 & "\Common Files\Adobe\Adobe Desktop Common\AdobeGenuineClient\AGSService.exe", $programfilesx86 & "\Common Files\Adobe\AdobeGCClient", $programfilesx86 & "\Common Files\Adobe\OOBE\PDApp\AdobeGCClient", $publicdir & "\Documents\AdobeGCData", $windir & "\System32\Tasks\AdobeGCInvoker-1.0", $windir & "\System32\Tasks_Migrated\AdobeGCInvoker-1.0", $programfilesx86 & "\Adobe\Adobe Creative Cloud\Utils\AdobeGenuineValidator.exe", $windir & "\Temp\adobegc.log", $localappdata & "\Temp\adobegc.log"]
	Local $iservicesuccess = 0
	For $sservice In $aservices
		Local $iexistcode = RunWait("sc query " & $sservice, '', @SW_HIDE)
		If $iexistcode = 1060 Then
			logwrite(1, "Service not found: " & $sservice)
			ContinueLoop
		ElseIf $iexistcode <> 0 Then
			logwrite(1, "Error checking service " & $sservice & " (exit code: " & $iexistcode & ")")
			ContinueLoop
		EndIf
		logwrite(1, "Service found: " & $sservice)
		Local $istoppid = Run("sc stop " & $sservice, '', @SW_HIDE, $STDERR_CHILD)
		Local $itimeout = 10000
		Local $iwaitresult = ProcessWaitClose($istoppid, $itimeout)
		If $iwaitresult = 0 Then
			ProcessClose($istoppid)
			logwrite(1, "Warning: Failed to stop " & $sservice & " - timed out after " & $itimeout & "ms")
		Else
			Local $istopcode = @error ? 1 : 0
			If $istopcode = 0 Or StringInStr(StderrRead($istoppid), "1052") Then
				logwrite(1, "Service stopped: " & $sservice)
			Else
				logwrite(1, "Failed to stop service " & $sservice & " (possible error)")
			EndIf
		EndIf
		Local $ideletepid = Run("sc delete " & $sservice, '', @SW_HIDE, $STDERR_CHILD)
		$iwaitresult = ProcessWaitClose($ideletepid, $itimeout)
		If $iwaitresult = 0 Then
			ProcessClose($ideletepid)
			logwrite(1, "Warning: Failed to delete " & $sservice & " - timed out after " & $itimeout & "ms")
		Else
			Local $ideletecode = @error ? 1 : 0
			If $ideletecode = 0 Then
				logwrite(1, "Service deleted: " & $sservice)
				$iservicesuccess += 1
			Else
				logwrite(1, "Failed to delete service " & $sservice & " (possible error)")
			EndIf
		EndIf
	Next
	Local $ifilesuccess = 0
	For $spath In $apaths
		If FileExists($spath) Then
			If StringInStr(FileGetAttrib($spath), "D") Then
				If DirRemove($spath, 1) Then
					logwrite(1, "Deleted directory: " & $spath)
					$ifilesuccess += 1
				Else
					logwrite(1, "Failed to delete directory: " & $spath)
				EndIf
			Else
				If FileDelete($spath) Then
					logwrite(1, "Deleted file: " & $spath)
					$ifilesuccess += 1
				Else
					logwrite(1, "Failed to delete file: " & $spath)
				EndIf
			EndIf
		Else
			logwrite(1, "File or folder not found: " & $spath)
		EndIf
	Next
	memowrite("AGS removal completed. Successfully processed " & $iservicesuccess & " of " & UBound($aservices) & " services and " & $ifilesuccess & " of " & UBound($apaths) & " files.")
	logwrite(1, "AGS removal completed. Services: " & $iservicesuccess & "/" & UBound($aservices) & ", Files: " & $ifilesuccess & "/" & UBound($apaths) & @CRLF)
	togglelog(1)
	GUICtrlSetState($idbtnremoveags, $GUI_ENABLE)
EndFunc   ;==>removeags

Func removehostsentries()
	_GUICtrlTab_SetCurFocus($htab, 3)
	Local $shostspath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $stemphosts = @TempDir & "\temp_hosts_remove.tmp"
	Local $smarkerstart = "# START - Adobe Blocklist"
	Local $smarkerend = "# END - Adobe Blocklist"
	FileSetAttrib($shostspath, "-R")
	Local $shostscontent = FileRead($shostspath)
	If @error Then
		memowrite("Error reading hosts file." & @CRLF)
		FileSetAttrib($shostspath, "+R")
		Return False
	EndIf
	If Not StringInStr($shostscontent, $smarkerstart) Or Not StringInStr($shostscontent, $smarkerend) Then
		logwrite(1, "No Adobe entries to remove." & @CRLF)
		FileSetAttrib($shostspath, "+R")
		togglelog(1)
		Return True
	EndIf
	$shostscontent = StringRegExpReplace($shostscontent, "(?s)" & $smarkerstart & ".*?" & $smarkerend, '')
	Local $htempfile = FileOpen($stemphosts, 2)
	If $htempfile = -1 Then
		memowrite("Error creating temp hosts file for removal." & @CRLF)
		FileSetAttrib($shostspath, "+R")
		Return False
	EndIf
	FileWrite($htempfile, $shostscontent)
	FileClose($htempfile)
	If Not FileCopy($stemphosts, $shostspath, 1) Then
		memowrite("Error writing updated hosts file." & @CRLF)
		memowrite("Attempting to copy from: " & $stemphosts & " to: " & $shostspath & @CRLF)
		FileDelete($stemphosts)
		FileSetAttrib($shostspath, "+R")
		Return False
	EndIf
	FileDelete($stemphosts)
	FileSetAttrib($shostspath, "+R")
	logwrite(1, "Hosts file cleaned of existing entries." & @CRLF)
	togglelog(1)
	Return True
EndFunc   ;==>removehostsentries

Func scandnscache(ByRef $shostscontent)
	Local $smarkerstart = "# START - Adobe Blocklist"
	Local $smarkerend = "# END - Adobe Blocklist"
	Local $sblocksection = StringRegExp($shostscontent, "(?s)" & $smarkerstart & "(.*?)" & $smarkerend, 1)
	If @error Or UBound($sblocksection) = 0 Then
		memowrite("Error parsing Adobe blocklist from hosts content." & @CRLF)
		Return 0
	EndIf
	Local $acurrentdomains = StringSplit(StringStripWS($sblocksection[0], 8), @CRLF, 2)
	Local $ahostsdomains[0]
	For $i = 0 To UBound($acurrentdomains) - 1
		Local $sline = StringStripWS($acurrentdomains[$i], 3)
		If StringRegExp($sline, "^\d+\.\d+\.\d+\.\d+\s+(.+)$") Then
			_ArrayAdd($ahostsdomains, StringRegExpReplace($sline, "^\d+\.\d+\.\d+\.\d+\s+(.+)$", "$1"))
		EndIf
	Next
	_ArraySort($ahostsdomains)
	_ArrayUnique($ahostsdomains)
	Local $stempdns = @TempDir & "\dns_cache.txt"
	Local $ipid = Run(@ComSpec & " /c ipconfig /displaydns > " & $stempdns, '', @SW_HIDE)
	Local $itimeout = 5000
	Local $iwaitresult = ProcessWaitClose($ipid, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipid)
		memowrite("Warning: ipconfig /displaydns timed out after " & $itimeout & "ms." & @CRLF)
	EndIf
	Local $sdnscache = FileRead($stempdns)
	If @error Then
		memowrite("Error reading DNS cache." & @CRLF)
		FileDelete($stempdns)
		Return 0
	EndIf
	FileDelete($stempdns)
	Local $adnsdomains = StringRegExp($sdnscache, "Record Name[^\n]*?\n\s*:\s*([^\n]*adobestats\.io[^\n]*)", 3)
	If UBound($adnsdomains) = 0 Then
		Return 0
	EndIf
	_ArraySort($adnsdomains)
	_ArrayUnique($adnsdomains)
	Local $anewdomains[0]
	For $i = 0 To UBound($adnsdomains) - 1
		Local $sdomain = StringStripWS($adnsdomains[$i], 3)
		If _ArraySearch($ahostsdomains, $sdomain) = -1 Then
			_ArrayAdd($anewdomains, $sdomain)
		EndIf
	Next
	If UBound($anewdomains) = 0 Then
		Return 0
	EndIf
	Local $sprompt = "Found " & UBound($anewdomains) & " new adobestats.io domain(s) in DNS cache:" & @CRLF & _ArrayToString($anewdomains, @CRLF) & @CRLF & "Add to hosts file?"
	Local $iresponse = MsgBox($MB_YESNO + $MB_ICONQUESTION, "New Domains Detected", $sprompt)
	If $iresponse = $IDNO Then
		memowrite("User declined to add new DNS domains." & @CRLF)
		Return 0
	EndIf
	Return $anewdomains
EndFunc   ;==>scandnscache

Func updatehostsfile()
	_GUICtrlTab_SetCurFocus($htab, 3)
	removehostsentries()
	GUICtrlSetState($idbtnupdatehosts, $GUI_DISABLE)
	memowrite(@CRLF & "Starting hosts file update..." & @CRLF)
	Local $shostspath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sbackuppath = $shostspath & ".bak"
	Local $smarkerstart = "# START - Adobe Blocklist"
	Local $smarkerend = "# END - Adobe Blocklist"
	Local $sdomainlisturl = $scurrentdomainlisturl
	Local $stempfiledownload, $sdomainlist, $shostscontent, $hfile
	FileSetAttrib($shostspath, "-R")
	If Not FileExists($sbackuppath) Then
		If Not FileCopy($shostspath, $sbackuppath, 1) Then
			memowrite("Error creating hosts backup." & @CRLF)
			GUICtrlSetState($idbtnupdatehosts, $GUI_ENABLE)
			FileSetAttrib($shostspath, "+R")
			Return
		EndIf
		memowrite("Hosts file backed up." & @CRLF)
	EndIf
	$stempfiledownload = _TempFile(@TempDir & "\domain_list")
	Local $iinetresult = InetGet($sdomainlisturl, $stempfiledownload, 1)
	If @error Or $iinetresult = 0 Then
		memowrite("Download Error: " & @error & ", InetGet Result: " & $iinetresult & @CRLF)
		FileDelete($stempfiledownload)
		GUICtrlSetState($idbtnupdatehosts, $GUI_ENABLE)
		FileSetAttrib($shostspath, "+R")
		Return
	EndIf
	$sdomainlist = FileRead($stempfiledownload)
	FileDelete($stempfiledownload)
	memowrite("Downloaded remote list:" & @CRLF & $sdomainlist & @CRLF)
	$shostscontent = FileRead($shostspath)
	If @error Then
		memowrite("Error reading hosts file." & @CRLF)
		GUICtrlSetState($idbtnupdatehosts, $GUI_ENABLE)
		FileSetAttrib($shostspath, "+R")
		Return
	EndIf
	$shostscontent = StringStripWS($shostscontent, 2)
	Local $snewcontent = $smarkerstart & @CRLF & $sdomainlist & @CRLF & $smarkerend
	If StringLen($shostscontent) > 0 Then
		$shostscontent &= @CRLF & $snewcontent
	Else
		$shostscontent = $snewcontent
	EndIf
	memowrite(@CRLF & "Scanning DNS cache for additional adobestats.io domains..." & @CRLF)
	Local $adnsdomainsadded = scandnscache($shostscontent)
	If IsArray($adnsdomainsadded) And UBound($adnsdomainsadded) > 0 Then
		Local $sdnsentries = ''
		For $i = 0 To UBound($adnsdomainsadded) - 1
			$sdnsentries &= "0.0.0.0 " & $adnsdomainsadded[$i] & @CRLF
		Next
		$shostscontent = StringRegExpReplace($shostscontent, "(?s)(" & $smarkerstart & ".*?)(" & $smarkerend & ")", "$1" & $sdnsentries & "$2")
		memowrite("Added from DNS cache:" & @CRLF & _ArrayToString($adnsdomainsadded, @CRLF) & @CRLF)
		logwrite(1, "Added from DNS cache: " & _ArrayToString($adnsdomainsadded, ", ") & @CRLF)
	Else
		memowrite("No new adobestats.io domains found in DNS cache." & @CRLF)
	EndIf
	$hfile = FileOpen($shostspath, 2)
	If $hfile = -1 Then
		Local $ilasterror = _WinAPI_GetLastError()
		memowrite("Error opening hosts file for writing: Last Error = " & $ilasterror & @CRLF)
		GUICtrlSetState($idbtnupdatehosts, $GUI_ENABLE)
		FileSetAttrib($shostspath, "+R")
		Return
	EndIf
	FileWrite($hfile, $shostscontent)
	FileClose($hfile)
	FileSetAttrib($shostspath, "+R")
	logwrite(1, "Hosts file updated successfully." & @CRLF)
	togglelog(1)
	GUICtrlSetState($idbtnupdatehosts, $GUI_ENABLE)
EndFunc   ;==>updatehostsfile

Func edithosts()
	Local $shostspath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sbackuppath = @WindowsDir & "\System32\drivers\etc\hosts.bak"
	FileSetAttrib($shostspath, "-R")
	If Not FileExists($sbackuppath) Then
		FileCopy($shostspath, $sbackuppath)
	EndIf
	Local $ipid = Run("notepad.exe " & $shostspath)
	If $ipid = 0 Then
		memowrite("Error launching Notepad." & @CRLF)
		FileSetAttrib($shostspath, "+R")
		Return
	EndIf
	Local $itimeout = 300000
	Local $iwaitresult = ProcessWaitClose($ipid, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipid)
		memowrite("Warning: Notepad timed out after " & $itimeout / 1000 & " seconds." & @CRLF)
	EndIf
	FileSetAttrib($shostspath, "+R")
EndFunc   ;==>edithosts

Func restorehosts()
	_GUICtrlTab_SetCurFocus($htab, 3)
	memowrite(@CRLF & "Restoring the hosts file from backup..." & @CRLF & "---" & @CRLF & "Please wait..." & @CRLF)
	Local $shostspath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sbackuppath = @WindowsDir & "\System32\drivers\etc\hosts.bak"
	If FileExists($sbackuppath) Then
		FileSetAttrib($shostspath, "-R")
		If FileCopy($sbackuppath, $shostspath, 1) Then
			FileSetAttrib($shostspath, "+R")
			FileDelete($sbackuppath)
			logwrite(1, "Restoring the hosts file from backup: Success!" & @CRLF)
		Else
			memowrite("Error restoring hosts file from backup." & @CRLF)
			FileSetAttrib($shostspath, "+R")
			logwrite(1, "Restoring the hosts file from backup: Failed." & @CRLF)
		EndIf
	Else
		logwrite(1, "Restoring the hosts file from backup: No backup file found." & @CRLF)
	EndIf
	togglelog(1)
EndFunc   ;==>restorehosts

Func checkthirdpartyfirewall()
	Local $scmd = 'powershell.exe -Command "Get-CimInstance -ClassName FirewallProduct -Namespace ''root\SecurityCenter2'' | Where-Object { $_.ProductName -notlike ''*Windows*'' } | Select-Object -Property ProductName"'
	Local $ipid = Run(@ComSpec & " /c " & $scmd, '', @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $soutput = ''
	Local $itimeout = 5000
	Local $iwaitresult = ProcessWaitClose($ipid, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipid)
		memowrite("Warning: Third-party firewall check timed out after " & $itimeout & "ms.")
	EndIf
	$soutput = StdoutRead($ipid)
	$soutput = StringStripWS($soutput, 3)
	If $soutput <> '' Then
		$g_sthirdpartyfirewall = $soutput
		memowrite("Third-party firewall detected: " & $g_sthirdpartyfirewall)
		Return True
	Else
		$g_sthirdpartyfirewall = ''
		memowrite("Windows Firewall is the default firewall.")
		Return False
	EndIf
EndFunc   ;==>checkthirdpartyfirewall

Func findadobeapps($bforlocaldll = False)
	Local $tfirewallpaths = IniReadSection($sinipath, "FirewallTrust")
	If @error Then
		memowrite("Error reading [FirewallTrust] section from config.")
		logwrite(1, "Error reading [FirewallTrust] section from config.")
		Local $empty[0]
		Return $empty
	EndIf
	Local $foundfiles[0]
	For $i = 1 To $tfirewallpaths[0][0]
		Local $basepath = $mydefpath & StringReplace($tfirewallpaths[$i][1], '"', '')
		If StringStripWS($basepath, 3) = '' Then ContinueLoop
		If $bforlocaldll And (StringInStr($basepath, "AcroCEF.exe", 0) Or StringInStr($basepath, "Acrobat.exe", 0)) Then
			ContinueLoop
		EndIf
		If StringInStr($basepath, "*") Then
			Local $pathparts = StringSplit($basepath, "\", 1)
			Local $searchdir = ''
			For $j = 1 To $pathparts[0] - 1
				If StringInStr($pathparts[$j], "*") Then
					$searchdir = StringTrimRight($searchdir, 1)
					Local $searchpattern = StringReplace($pathparts[$j], "*", "*")
					Local $subpath = StringMid($basepath, StringInStr($basepath, $pathparts[$j]) + StringLen($pathparts[$j]))
					Local $hsearch = FileFindFirstFile($searchdir & "\" & $searchpattern)
					If $hsearch = -1 Then ContinueLoop
					While 1
						Local $folder = FileFindNextFile($hsearch)
						If @error Then ExitLoop
						Local $fullpath = $searchdir & "\" & $folder & $subpath
						$fullpath = StringRegExpReplace($fullpath, "\\\\+", "\\")
						If FileExists($fullpath) And StringStripWS($fullpath, 3) <> '' Then
							_ArrayAdd($foundfiles, $fullpath)
						EndIf
					WEnd
					FileClose($hsearch)
					ExitLoop
				Else
					$searchdir &= $pathparts[$j] & "\"
				EndIf
			Next
		Else
			If FileExists($basepath) And StringStripWS($basepath, 3) <> '' Then
				_ArrayAdd($foundfiles, $basepath)
			EndIf
		EndIf
	Next
	If UBound($foundfiles) > 0 Then
		$foundfiles = _ArrayUnique($foundfiles, 0, 0, 0, 0)
		Local $cleanedfiles[0]
		For $file In $foundfiles
			If StringStripWS($file, 3) <> '' And Not StringIsInt($file) Then
				_ArrayAdd($cleanedfiles, $file)
			EndIf
		Next
		$foundfiles = $cleanedfiles
	EndIf
	Return $foundfiles
EndFunc   ;==>findadobeapps

Func ruleexists($rulename)
	Local $scmd = 'powershell.exe -Command "Get-NetFirewallRule -DisplayName ''Adobe-Block - ' & $rulename & ''' | Measure-Object | Select-Object -ExpandProperty Count"'
	Local $ipid = Run(@ComSpec & " /c " & $scmd, '', @SW_HIDE, $STDOUT_CHILD)
	Local $itimeout = 5000
	Local $iwaitresult = ProcessWaitClose($ipid, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipid)
		logwrite(1, "Warning: Rule check for '" & $rulename & "' timed out after " & $itimeout & "ms.")
	EndIf
	Local $soutput = StdoutRead($ipid)
	Return Number(StringStripWS($soutput, 3)) > 0
EndFunc   ;==>ruleexists

Func showfirewallstatus()
	_GUICtrlTab_SetCurFocus($htab, 3)
	memowrite("Checking Windows Firewall status...")
	logwrite(1, "Checking Windows Firewall status...")
	memowrite("Scanning firewall profiles...")
	Local $sprofilecmd = 'powershell.exe -Command "Get-NetFirewallProfile | Select-Object -Property Name,Enabled | Format-Table -HideTableHeaders"'
	Local $ipid = Run(@ComSpec & " /c " & $sprofilecmd, '', @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sprofileoutput = ''
	Local $itimeout = 5000
	Local $iwaitresult = ProcessWaitClose($ipid, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipid)
		memowrite("Warning: Firewall profile check timed out after " & $itimeout & "ms.")
	EndIf
	$sprofileoutput = StdoutRead($ipid)
	Local $aprofiles = StringSplit(StringStripWS($sprofileoutput, 3), @CRLF, 1)
	Local $sprofilesummary = ''
	For $i = 1 To $aprofiles[0]
		Local $line = StringStripWS($aprofiles[$i], 3)
		If $line <> '' Then
			Local $aparts = StringRegExp($line, "^(\S+)\s+(\S+)$", 1)
			If @error = 0 Then
				Local $profilename = $aparts[0]
				Local $enabled = $aparts[1]
				$sprofilesummary &= $profilename & ": " & ($enabled = "True" ? "Enabled" : "Disabled") & @CRLF
			EndIf
		EndIf
	Next
	memowrite("Firewall Profiles:" & @CRLF & StringTrimRight($sprofilesummary, StringLen(@CRLF)))
	logwrite(1, "Firewall Profiles - " & StringReplace(StringTrimRight($sprofilesummary, StringLen(@CRLF)), @CRLF, " | "))
	memowrite("Checking firewall service...")
	Local $sservicecmd = 'powershell.exe -Command "Get-Service MpsSvc | Select-Object -Property Status,DisplayName | Format-List"'
	$ipid = Run(@ComSpec & " /c " & $sservicecmd, '', @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sserviceoutput = ''
	$iwaitresult = ProcessWaitClose($ipid, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipid)
		memowrite("Warning: Firewall service check timed out after " & $itimeout & "ms.")
	EndIf
	$sserviceoutput = StdoutRead($ipid)
	Local $sservicestatus = "Unknown"
	Local $aservicelines = StringSplit(StringStripWS($sserviceoutput, 3), @CRLF, 1)
	For $line In $aservicelines
		If StringInStr($line, "Status") Then
			Local $astatus = StringSplit($line, ":", 1)
			If $astatus[0] > 1 Then
				$sservicestatus = StringStripWS($astatus[2], 3)
			EndIf
			ExitLoop
		EndIf
	Next
	memowrite("Firewall Service (MpsSvc): " & $sservicestatus)
	logwrite(1, "Firewall Service (MpsSvc): " & $sservicestatus)
EndFunc   ;==>showfirewallstatus

Func removefirewallrules()
	_GUICtrlTab_SetCurFocus($htab, 3)
	memowrite("Starting firewall rule removal process...")
	logwrite(1, "Starting firewall rule removal process.")
	If checkthirdpartyfirewall() Then
		memowrite("Third-party firewall detected. Cannot remove rules.")
		logwrite(1, "Third-party firewall detected" & ($g_sthirdpartyfirewall <> '' ? " (" & $g_sthirdpartyfirewall & ")" : '') & ". This option only supports Windows Firewall.")
		logwrite(1, "Firewall rule removal process completed." & @CRLF)
		togglelog(1)
		Return
	EndIf
	memowrite("Scanning for Adobe-Block firewall rules...")
	Local $scmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $ipid = Run(@ComSpec & " /c " & $scmd, '', @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $soutput = ''
	Local $itimeout = 5000
	Local $iwaitresult = ProcessWaitClose($ipid, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipid)
		memowrite("Warning: Rule scan timed out after " & $itimeout & "ms.")
	EndIf
	$soutput = StdoutRead($ipid)
	Local $arules = StringSplit(StringStripWS($soutput, 3), @CRLF, 1)
	Local $irulecount = 0
	For $i = 1 To $arules[0]
		If StringInStr($arules[$i], "Adobe-Block") Then $irulecount += 1
	Next
	If $irulecount = 0 Then
		memowrite("No Adobe-Block firewall rules found.")
		logwrite(1, "No Adobe-Block firewall rules found to remove.")
		logwrite(1, "Firewall rule removal process completed." & @CRLF)
		togglelog(1)
		Return
	EndIf
	memowrite("Removing " & $irulecount & " rule(s)...")
	logwrite(1, "Removing " & $irulecount & " rule(s):")
	For $i = 1 To $arules[0]
		If StringInStr($arules[$i], "Adobe-Block") Then
			logwrite(1, "- " & StringStripWS($arules[$i], 3))
		EndIf
	Next
	Local $sremovecmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Remove-NetFirewallRule"'
	Local $ipidremove = Run($sremovecmd, '', @SW_HIDE, $STDERR_CHILD)
	$iwaitresult = ProcessWaitClose($ipidremove, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipidremove)
		memowrite("Warning: Rule removal timed out after " & $itimeout & "ms.")
		logwrite(1, "Error: Rule removal timed out.")
	ElseIf @error Then
		memowrite("Error removing firewall rules.")
		logwrite(1, "Error removing firewall rules.")
	Else
		memowrite("Adobe-Block firewall rules removed successfully.")
		logwrite(1, "Firewall rules removed successfully.")
	EndIf
	logwrite(1, "Firewall rule removal process completed." & @CRLF)
	togglelog(1)
EndFunc   ;==>removefirewallrules

Func createfirewallrules()
	memowrite("Starting firewall rule creation process...")
	logwrite(1, "Starting firewall rule creation process.")
	If checkthirdpartyfirewall() Then
		memowrite("Third-party firewall detected. Skipping GUI and listing found applications.")
		Local $foundadobeapps = findadobeapps()
		If UBound($foundadobeapps) = 0 Then
			logwrite(1, "No Adobe applications found to block.")
		Else
			logwrite(1, "Found " & UBound($foundadobeapps) & " Adobe applications:")
			For $app In $foundadobeapps
				logwrite(1, "- " & $app)
			Next
			logwrite(1, "Third-party firewall detected" & ($g_sthirdpartyfirewall <> '' ? " (" & $g_sthirdpartyfirewall & ")" : '') & ". Please manually add these paths to your firewall.")
		EndIf
		logwrite(1, "Firewall rule creation process completed." & @CRLF)
		togglelog(1)
		Return
	EndIf
	memowrite("Scanning for Adobe applications...")
	Local $foundadobeapps = findadobeapps()
	Local $selectedapps = showappselectiongui($foundadobeapps)
	If Not IsArray($selectedapps) Then
		memowrite("Firewall rule process cancelled by user.")
		logwrite(1, "Firewall rule process cancelled by user." & @CRLF)
		Return
	EndIf
	showfirewallstatus()
	_GUICtrlTab_SetCurFocus($htab, 3)
	If UBound($selectedapps) = 0 Then
		memowrite("No applications selected by the user.")
		logwrite(1, "No applications selected.")
		logwrite(1, "Firewall rule creation process completed." & @CRLF)
		togglelog(1)
		Return
	EndIf
	memowrite("User selected " & UBound($selectedapps) & " file(s).")
	Local $pscmdcomposite = ''
	Local $rulesadded = 0
	Local $addedapps[0]
	For $app In $selectedapps
		$app = StringStripWS($app, 3)
		If $app = '' Then
			memowrite("Skipping empty or invalid selected path.")
			ContinueLoop
		EndIf
		If FileExists($app) Then
			Local $rulename = $app
			If Not ruleexists($rulename) Then
				Local $rulecmd = "New-NetFirewallRule -DisplayName 'Adobe-Block - " & $rulename & "' -Direction Outbound -Program '" & $app & "' -Action Block;"
				$pscmdcomposite &= $rulecmd
				memowrite("Adding firewall rule for: " & $app)
				_ArrayAdd($addedapps, $app)
				$rulesadded += 1
			Else
				memowrite("Rule already exists for: " & $app & " - Skipping.")
			EndIf
		Else
			memowrite("File not found: " & $app)
			logwrite(1, "File not found: " & $app)
		EndIf
	Next
	If $rulesadded > 0 Then
		logwrite(1, "Selected " & $rulesadded & " files(s) for new firewall rule(s):")
		For $app In $addedapps
			logwrite(1, "- " & $app)
		Next
		Local $ipid = Run('powershell.exe -Command "' & $pscmdcomposite & '"', '', @SW_HIDE, $STDERR_CHILD)
		Local $itimeout = 10000
		Local $iwaitresult = ProcessWaitClose($ipid, $itimeout)
		If $iwaitresult = 0 Then
			ProcessClose($ipid)
			memowrite("Warning: Rule creation timed out after " & $itimeout & "ms.")
			logwrite(1, "Error: Rule creation timed out.")
		ElseIf @error Then
			memowrite("Error applying firewall rules.")
			logwrite(1, "Error applying firewall rules.")
		Else
			memowrite("Firewall rules applied successfully.")
			logwrite(1, "Firewall rules applied successfully.")
		EndIf
	Else
		memowrite("No new firewall rules to add.")
		logwrite(1, "No new firewall rules were added (all selected rules already exist).")
	EndIf
	logwrite(1, "Firewall rule creation process completed." & @CRLF)
	togglelog(1)
EndFunc   ;==>createfirewallrules

Func showappselectiongui($foundfiles)
	If UBound($foundfiles) = 0 Then
		memowrite("No Adobe applications found.")
		logwrite(1, "No Adobe applications found to block.")
		Return ''
	EndIf
	Local $amainpos = WinGetPos($myhgui)
	Local $ipopupx = $amainpos[0] + ($amainpos[2] - 500) / 2
	Local $ipopupy = $amainpos[1] + ($amainpos[3] - 400) / 2
	Local $hgui = GUICreate("Select File(s) to Firewall", 500, 400, $ipopupx, $ipopupy)
	Local $hselectall = GUICtrlCreateCheckbox("Select All", 10, 10)
	Local $htreeview = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hokbutton = GUICtrlCreateButton("OK", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)
	Local $defpathclean = StringStripWS($mydefpath, 3)
	If StringRight($defpathclean, 1) = "\" Then
		$defpathclean = StringTrimRight($defpathclean, 1)
	EndIf
	Local $defpathparts = StringSplit($defpathclean, "\", 1)
	Local $defpathdepth = $defpathparts[0]
	Local $appnodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundfiles
		Local $filenobak = StringReplace($file, ".bak", '')
		Local $fileparts = StringSplit($filenobak, "\", 1)
		Local $appname = "Unknown"
		If $fileparts[0] >= $defpathdepth + 1 Then
			$appname = $fileparts[$defpathdepth + 1]
		EndIf
		If Not $appnodes.Exists($appname) Then
			Local $happnode = GUICtrlCreateTreeViewItem($appname, $htreeview)
			$appnodes($appname) = $happnode
			_GUICtrlTreeView_SetChecked($htreeview, $happnode, False)
		EndIf
		Local $hitem = GUICtrlCreateTreeViewItem($file, $appnodes($appname))
		_GUICtrlTreeView_SetChecked($htreeview, $hitem, False)
	Next
	logwrite(1, "Found " & UBound($foundfiles) & " file(s) across " & $appnodes.Count & " Adobe application(s).")
	Global $prevstates = ObjCreate("Scripting.Dictionary")
	Global $ghtreeview = $htreeview
	Local $hitem = _GUICtrlTreeView_GetFirstItem($htreeview)
	While $hitem <> 0
		Local $itemtext = _GUICtrlTreeView_GetText($htreeview, $hitem)
		If _GUICtrlTreeView_GetChildCount($htreeview, $hitem) > 0 Then
			$prevstates($itemtext) = False
		EndIf
		$hitem = _GUICtrlTreeView_GetNext($htreeview, $hitem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 250)
	Local $bpaused = False
	While 1
		Local $nmsg = GUIGetMsg()
		Switch $nmsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hgui)
				Return ''
			Case $hselectall
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedstate = (GUICtrlRead($hselectall) = $GUI_CHECKED)
				Local $hitem = _GUICtrlTreeView_GetFirstItem($htreeview)
				While $hitem <> 0
					_GUICtrlTreeView_SetChecked($htreeview, $hitem, $checkedstate)
					Local $itemtext = _GUICtrlTreeView_GetText($htreeview, $hitem)
					If _GUICtrlTreeView_GetChildCount($htreeview, $hitem) > 0 Then
						$prevstates($itemtext) = $checkedstate
					EndIf
					$hitem = _GUICtrlTreeView_GetNext($htreeview, $hitem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 250)
			Case $hokbutton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedapps[0]
				Local $hitem = _GUICtrlTreeView_GetFirstItem($htreeview)
				memowrite("Scanning for selected items...")
				While $hitem <> 0
					If _GUICtrlTreeView_GetChecked($htreeview, $hitem) Then
						Local $itemtext = _GUICtrlTreeView_GetText($htreeview, $hitem)
						Local $childcount = _GUICtrlTreeView_GetChildCount($htreeview, $hitem)
						If $childcount = -1 And StringStripWS($itemtext, 3) <> '' Then
							_ArrayAdd($selectedapps, $itemtext)
						EndIf
					EndIf
					$hitem = _GUICtrlTreeView_GetNext($htreeview, $hitem)
				WEnd
				_GUICtrlTab_SetCurFocus($htab, 3)
				memowrite("Selected " & UBound($selectedapps) & " file(s) for firewall rules.")
				GUIDelete($hgui)
				Return $selectedapps
			Case $GUI_EVENT_PRIMARYDOWN
				Local $acursor = GUIGetCursorInfo($hgui)
				If IsArray($acursor) And $acursor[4] = $htreeview Then
					If Not $bpaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bpaused = True
					EndIf
				EndIf
			Case Else
				If $bpaused Then
					AdlibRegister("CheckParentCheckboxes", 250)
					$bpaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>showappselectiongui

Func checkparentcheckboxes()
	Local $hitem = _GUICtrlTreeView_GetFirstItem($ghtreeview)
	While $hitem <> 0
		Local $itemtext = _GUICtrlTreeView_GetText($ghtreeview, $hitem)
		Local $childcount = _GUICtrlTreeView_GetChildCount($ghtreeview, $hitem)
		If $childcount > 0 Then
			Local $currentstate = _GUICtrlTreeView_GetChecked($ghtreeview, $hitem)
			Local $prevstate = $prevstates($itemtext)
			If $currentstate <> $prevstate Then
				$prevstates($itemtext) = $currentstate
				Local $hchild = _GUICtrlTreeView_GetFirstChild($ghtreeview, $hitem)
				While $hchild <> 0
					_GUICtrlTreeView_SetChecked($ghtreeview, $hchild, $currentstate)
					$hchild = _GUICtrlTreeView_GetNextChild($ghtreeview, $hchild)
				WEnd
			EndIf
		EndIf
		$hitem = _GUICtrlTreeView_GetNext($ghtreeview, $hitem)
	WEnd
EndFunc   ;==>checkparentcheckboxes

Func showtogglerulesgui()
	memowrite("Opening firewall rule toggle options...")
	Local $amainpos = WinGetPos($myhgui)
	Local $ipopupx = $amainpos[0] + ($amainpos[2] - 300) / 2
	Local $ipopupy = $amainpos[1] + ($amainpos[3] - 150) / 2
	Local $htogglegui = GUICreate("Toggle Rules", 300, 150, $ipopupx, $ipopupy)
	Local $henablebutton = GUICtrlCreateButton("Enable All", 50, 50, 100, 30)
	Local $hdisablebutton = GUICtrlCreateButton("Disable All", 150, 50, 100, 30)
	Local $hcancelbutton = GUICtrlCreateButton("Cancel", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hcancelbutton
				memowrite("Toggle rules operation cancelled.")
				GUIDelete($htogglegui)
				Return
			Case $henablebutton
				_GUICtrlTab_SetCurFocus($htab, 3)
				GUIDelete($htogglegui)
				enablealladoberules()
				Return
			Case $hdisablebutton
				_GUICtrlTab_SetCurFocus($htab, 3)
				GUIDelete($htogglegui)
				disablealladoberules()
				Return
		EndSwitch
	WEnd
EndFunc   ;==>showtogglerulesgui

Func enablealladoberules()
	memowrite("Enabling all AdobeGenP firewall rules...")
	logwrite(1, "Starting process to enable all AdobeGenP firewall rules.")
	If checkthirdpartyfirewall() Then
		memowrite("Third-party firewall detected. Cannot modify rules.")
		logwrite(1, "Third-party firewall detected" & ($g_sthirdpartyfirewall <> '' ? " (" & $g_sthirdpartyfirewall & ")" : '') & ". This option only supports Windows Firewall.")
		logwrite(1, "Enable rules process completed." & @CRLF)
		togglelog(1)
		Return
	EndIf
	Local $scmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $ipid = Run(@ComSpec & " /c " & $scmd, '', @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $soutput = ''
	Local $itimeout = 5000
	Local $iwaitresult = ProcessWaitClose($ipid, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipid)
		memowrite("Warning: Rule scan timed out after " & $itimeout & "ms.")
	EndIf
	$soutput = StdoutRead($ipid)
	Local $arules = StringSplit(StringStripWS($soutput, 3), @CRLF, 1)
	Local $irulecount = 0
	For $i = 1 To $arules[0]
		If StringInStr($arules[$i], "Adobe-Block") Then $irulecount += 1
	Next
	If $irulecount = 0 Then
		memowrite("No AdobeGenP firewall rules found to enable.")
		logwrite(1, "No AdobeGenP firewall rules found.")
		logwrite(1, "Enable rules process completed." & @CRLF)
		togglelog(1)
		Return
	EndIf
	memowrite("Enabling " & $irulecount & " Adobe-Block rule(s)...")
	logwrite(1, "Enabling " & $irulecount & " rule(s):")
	For $i = 1 To $arules[0]
		If StringInStr($arules[$i], "Adobe-Block") Then
			logwrite(1, "- " & StringStripWS($arules[$i], 3))
		EndIf
	Next
	Local $senablecmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Enable-NetFirewallRule"'
	Local $ipidenable = Run($senablecmd, '', @SW_HIDE, $STDERR_CHILD)
	$iwaitresult = ProcessWaitClose($ipidenable, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipidenable)
		memowrite("Warning: Rule enabling timed out after " & $itimeout & "ms.")
		logwrite(1, "Error: Rule enabling timed out.")
	ElseIf @error Then
		memowrite("Error enabling firewall rules.")
		logwrite(1, "Error enabling firewall rules.")
	Else
		memowrite("All AdobeGenP firewall rules enabled successfully.")
		logwrite(1, "All AdobeGenP firewall rules enabled successfully.")
	EndIf
	logwrite(1, "Enable rules process completed." & @CRLF)
	togglelog(1)
EndFunc   ;==>enablealladoberules

Func disablealladoberules()
	memowrite("Disabling all AdobeGenP firewall rules...")
	logwrite(1, "Starting process to disable all AdobeGenP firewall rules.")
	If checkthirdpartyfirewall() Then
		memowrite("Third-party firewall detected. Cannot modify rules.")
		logwrite(1, "Third-party firewall detected" & ($g_sthirdpartyfirewall <> '' ? " (" & $g_sthirdpartyfirewall & ")" : '') & ". This option only supports Windows Firewall.")
		logwrite(1, "Disable rules process completed." & @CRLF)
		togglelog(1)
		Return
	EndIf
	Local $scmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $ipid = Run(@ComSpec & " /c " & $scmd, '', @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $soutput = ''
	Local $itimeout = 5000
	Local $iwaitresult = ProcessWaitClose($ipid, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipid)
		memowrite("Warning: Rule scan timed out after " & $itimeout & "ms.")
	EndIf
	$soutput = StdoutRead($ipid)
	Local $arules = StringSplit(StringStripWS($soutput, 3), @CRLF, 1)
	Local $irulecount = 0
	For $i = 1 To $arules[0]
		If StringInStr($arules[$i], "Adobe-Block") Then $irulecount += 1
	Next
	If $irulecount = 0 Then
		memowrite("No AdobeGenP firewall rules found to disable.")
		logwrite(1, "No AdobeGenP firewall rules found.")
		logwrite(1, "Disable rules process completed." & @CRLF)
		togglelog(1)
		Return
	EndIf
	memowrite("Disabling " & $irulecount & " Adobe-Block rule(s)...")
	logwrite(1, "Disabling " & $irulecount & " rule(s):")
	For $i = 1 To $arules[0]
		If StringInStr($arules[$i], "Adobe-Block") Then
			logwrite(1, "- " & StringStripWS($arules[$i], 3))
		EndIf
	Next
	Local $sdisablecmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Disable-NetFirewallRule"'
	Local $ipiddisable = Run($sdisablecmd, '', @SW_HIDE, $STDERR_CHILD)
	$iwaitresult = ProcessWaitClose($ipiddisable, $itimeout)
	If $iwaitresult = 0 Then
		ProcessClose($ipiddisable)
		memowrite("Warning: Rule disabling timed out after " & $itimeout & "ms.")
		logwrite(1, "Error: Rule disabling timed out.")
	ElseIf @error Then
		memowrite("Error disabling firewall rules.")
		logwrite(1, "Error disabling firewall rules.")
	Else
		memowrite("All AdobeGenP firewall rules disabled successfully.")
		logwrite(1, "All AdobeGenP firewall rules disabled successfully.")
	EndIf
	logwrite(1, "Disable rules process completed." & @CRLF)
	togglelog(1)
EndFunc   ;==>disablealladoberules

Func findruntimeinstallerfiles()
	Local $truntimepaths = IniReadSection($sinipath, "RuntimeInstallers")
	Local $dllpaths[0]
	If Not @error Then
		ReDim $dllpaths[$truntimepaths[0][0]]
		For $i = 1 To $truntimepaths[0][0]
			$dllpaths[$i - 1] = $mydefpath & StringReplace($truntimepaths[$i][1], '"', '')
		Next
	Else
		memowrite("Warning: [RuntimeInstallers] section not found in config.ini")
		logwrite(1, "Warning: [RuntimeInstallers] section not found in config.ini")
	EndIf
	Local $foundfiles[0]
	For $basepath In $dllpaths
		If StringStripWS($basepath, 3) = '' Then ContinueLoop
		Local $pathparts = StringSplit($basepath, "\", 1)
		Local $searchdir = ''
		For $i = 1 To $pathparts[0] - 1
			If StringInStr($pathparts[$i], "*") Then
				$searchdir = StringTrimRight($searchdir, 1)
				Local $searchpattern = StringReplace($pathparts[$i], "*", "*")
				Local $subpath = StringMid($basepath, StringInStr($basepath, $pathparts[$i]) + StringLen($pathparts[$i]))
				Local $hsearch = FileFindFirstFile($searchdir & "\" & $searchpattern)
				If $hsearch = -1 Then ContinueLoop
				While 1
					Local $folder = FileFindNextFile($hsearch)
					If @error Then ExitLoop
					Local $fullpath = $searchdir & "\" & $folder & $subpath
					$fullpath = StringRegExpReplace($fullpath, "\\\\+", "\\")
					If FileExists($fullpath) And StringStripWS($fullpath, 3) <> '' Then
						_ArrayAdd($foundfiles, $fullpath)
					EndIf
				WEnd
				FileClose($hsearch)
				ExitLoop
			Else
				$searchdir &= $pathparts[$i] & "\"
			EndIf
		Next
	Next
	If UBound($foundfiles) > 0 Then
		$foundfiles = _ArrayUnique($foundfiles, 0, 0, 0, 0)
	EndIf
	Return $foundfiles
EndFunc   ;==>findruntimeinstallerfiles

Func unpackruntimeinstallers()
	memowrite("Scanning for RuntimeInstaller.dll files...")
	Local $foundfiles = findruntimeinstallerfiles()
	If UBound($foundfiles) = 0 Then
		_GUICtrlTab_SetCurFocus($htab, 3)
		memowrite("No RuntimeInstaller.dll files found to unpack.")
		logwrite(1, "No RuntimeInstaller.dll files found to unpack.")
		Return
	EndIf
	Local $selectedfiles = runtimedllselectiongui($foundfiles, "Unpack")
	If Not IsArray($selectedfiles) Or UBound($selectedfiles) = 0 Then
		memowrite("No RuntimeInstaller.dll files selected to unpack.")
		logwrite(1, "No files selected to unpack.")
		Return
	EndIf
	Local $upxpath = @ScriptDir & "\upx.exe"
	If Not FileExists($upxpath) Then
		FileInstall("upx.exe", $upxpath, 1)
		If Not FileExists($upxpath) Then
			memowrite("Error: Failed to extract upx.exe to " & $upxpath)
			logwrite(1, "Error: Failed to extract upx.exe.")
			Return
		EndIf
	EndIf
	memowrite("Unpacking " & UBound($selectedfiles) & " file(s)...")
	logwrite(1, "Unpacking " & UBound($selectedfiles) & " file(s):")
	Local $successcount = 0
	For $file In $selectedfiles
		$file = StringStripWS($file, 3)
		If $file = '' Or Not FileExists($file) Then
			memowrite("Skipping invalid or missing file: " & $file)
			logwrite(1, "Skipping invalid or missing file: " & $file)
			ContinueLoop
		EndIf
		logwrite(1, "- Processing: " & $file)
		If Not isupxpacked($file) Then
			memowrite("Skipped: " & $file & " is not a UPX-packed file.")
			logwrite(1, "Skipped: " & $file & " is not a UPX-packed file.")
			ContinueLoop
		EndIf
		Local $iresult = RunWait('"' & $upxpath & '" -d "' & $file & '"', '', @SW_HIDE)
		If $iresult = 0 Then
			memowrite("Successfully unpacked: " & $file)
			logwrite(1, "Successfully unpacked: " & $file)
			$successcount += 1
		Else
			memowrite("Failed to unpack: " & $file & " (UPX error code: " & $iresult & ")")
			logwrite(1, "Failed to unpack: " & $file & " (UPX error code: " & $iresult & ")")
		EndIf
	Next
	If FileExists($upxpath) Then
		If FileDelete($upxpath) Then
			memowrite("Deleted upx.exe from " & $upxpath & ".")
		Else
			memowrite("Warning: Failed to delete upx.exe from " & $upxpath & ".")
			logwrite(1, "Warning: Failed to delete upx.exe from " & $upxpath & ".")
		EndIf
	EndIf
	memowrite("Unpack completed. Successfully unpacked " & $successcount & " file(s).")
	logwrite(1, "Unpack process completed.")
	If $successcount > 0 Then
		logwrite(1, $successcount & " file(s) successfully unpacked and can now be patched.")
	EndIf
	togglelog(1)
EndFunc   ;==>unpackruntimeinstallers

Func isupxpacked($sfilepath)
	Local $hfile = FileOpen($sfilepath, 16)
	If $hfile = -1 Then
		logwrite(1, "Error: Failed to open file for UPX check: " & $sfilepath)
		Return False
	EndIf
	Local $bdata = FileRead($hfile)
	FileClose($hfile)
	If @error Then
		logwrite(1, "Error: Failed to read file for UPX check: " & $sfilepath)
		Return False
	EndIf
	If StringInStr(BinaryToString($bdata), "UPX!") Or StringInStr($bdata, "0x55505821") Then
		Return True
	EndIf
	Return False
EndFunc   ;==>isupxpacked

Func runtimedllselectiongui($foundfiles, $operation)
	If UBound($foundfiles) = 0 Then
		memowrite("No RuntimeInstaller.dll files found to unpack.")
		logwrite(1, "No RuntimeInstaller.dll files found to unpack.")
		Return ''
	EndIf
	Local $amainpos = WinGetPos($myhgui)
	Local $ipopupx = $amainpos[0] + ($amainpos[2] - 500) / 2
	Local $ipopupy = $amainpos[1] + ($amainpos[3] - 400) / 2
	Local $hgui = GUICreate("Unpack RuntimeInstaller", 500, 400, $ipopupx, $ipopupy)
	Local $hselectall = GUICtrlCreateCheckbox("Select All", 10, 10)
	Local $htreeview = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hokbutton = GUICtrlCreateButton("OK", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)
	Local $defpathclean = StringStripWS($mydefpath, 3)
	If StringRight($defpathclean, 1) = "\" Then
		$defpathclean = StringTrimRight($defpathclean, 1)
	EndIf
	Local $defpathparts = StringSplit($defpathclean, "\", 1)
	Local $defpathdepth = $defpathparts[0]
	Local $appnodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundfiles
		Local $fileparts = StringSplit($file, "\", 1)
		Local $appname = "Unknown"
		If $fileparts[0] >= $defpathdepth + 1 Then
			$appname = $fileparts[$defpathdepth + 1]
		EndIf
		If Not $appnodes.Exists($appname) Then
			Local $happnode = GUICtrlCreateTreeViewItem($appname, $htreeview)
			$appnodes($appname) = $happnode
			_GUICtrlTreeView_SetChecked($htreeview, $happnode, False)
		EndIf
		Local $hitem = GUICtrlCreateTreeViewItem($file, $appnodes($appname))
		_GUICtrlTreeView_SetChecked($htreeview, $hitem, False)
	Next
	Global $prevstates = ObjCreate("Scripting.Dictionary")
	Global $ghtreeview = $htreeview
	Local $hitem = _GUICtrlTreeView_GetFirstItem($htreeview)
	While $hitem <> 0
		Local $itemtext = _GUICtrlTreeView_GetText($htreeview, $hitem)
		If _GUICtrlTreeView_GetChildCount($htreeview, $hitem) > 0 Then
			$prevstates($itemtext) = False
		EndIf
		$hitem = _GUICtrlTreeView_GetNext($htreeview, $hitem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 250)
	Local $bpaused = False
	While 1
		Local $nmsg = GUIGetMsg()
		Switch $nmsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hgui)
				memowrite("Runtime installer unpacking cancelled.")
				logwrite(1, "Runtime installer unpacking cancelled.")
				Return ''
			Case $hselectall
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedstate = (GUICtrlRead($hselectall) = $GUI_CHECKED)
				Local $hitem = _GUICtrlTreeView_GetFirstItem($htreeview)
				While $hitem <> 0
					_GUICtrlTreeView_SetChecked($htreeview, $hitem, $checkedstate)
					Local $itemtext = _GUICtrlTreeView_GetText($htreeview, $hitem)
					If _GUICtrlTreeView_GetChildCount($htreeview, $hitem) > 0 Then
						$prevstates($itemtext) = $checkedstate
					EndIf
					$hitem = _GUICtrlTreeView_GetNext($htreeview, $hitem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 250)
			Case $hokbutton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedfiles[0]
				Local $hitem = _GUICtrlTreeView_GetFirstItem($htreeview)
				While $hitem <> 0
					Local $itemtext = _GUICtrlTreeView_GetText($htreeview, $hitem)
					Local $ischecked = _GUICtrlTreeView_GetChecked($htreeview, $hitem)
					If $ischecked And StringInStr($itemtext, "RuntimeInstaller.dll") Then
						_ArrayAdd($selectedfiles, $itemtext)
					EndIf
					$hitem = _GUICtrlTreeView_GetNext($htreeview, $hitem)
				WEnd
				GUIDelete($hgui)
				If UBound($selectedfiles) = 0 Then
					memowrite("No RuntimeInstaller.dll files selected to unpack.")
					logwrite(1, "No RuntimeInstaller.dll files selected to unpack.")
					Return ''
				EndIf
				_GUICtrlTab_SetCurFocus($htab, 3)
				Return $selectedfiles
			Case $GUI_EVENT_PRIMARYDOWN
				Local $acursor = GUIGetCursorInfo($hgui)
				If IsArray($acursor) And $acursor[4] = $htreeview Then
					If Not $bpaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bpaused = True
					EndIf
				EndIf
			Case Else
				If $bpaused Then
					AdlibRegister("CheckParentCheckboxes", 250)
					$bpaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>runtimedllselectiongui

Func adddevoverride()
	Local $skey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $svaluename = "DevOverrideEnable"
	Local $iexpectedvalue = 1
	If Not IsAdmin() Then
		memowrite("Error: Administrator rights required to set registry key.")
		logwrite(1, "Error: Administrator rights required for registry access.")
		Return False
	EndIf
	Local $icurrentvalue = RegRead($skey, $svaluename)
	If @error = 0 And $icurrentvalue = $iexpectedvalue Then
		memowrite("Registry key " & $svaluename & " already enabled.")
		logwrite(1, "Registry key " & $svaluename & " already set to " & $iexpectedvalue & ".")
		Return True
	EndIf
	If RegWrite($skey, $svaluename, "REG_DWORD", $iexpectedvalue) Then
		memowrite("Enabled registry key " & $svaluename & " for WinTrust override.")
		logwrite(1, "Set registry key " & $svaluename & " = " & $iexpectedvalue & ".")
		showrebootpopup()
		Return True
	Else
		memowrite("Error: Failed to enable registry key " & $svaluename & ".")
		logwrite(1, "Error: Failed to set registry key " & $svaluename & " (Error: " & @error & ").")
		Return False
	EndIf
EndFunc   ;==>adddevoverride

Func removedevoverride()
	Local $skey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $svaluename = "DevOverrideEnable"
	Local $iexpectedvalue = 1
	If Not IsAdmin() Then
		memowrite("Error: Administrator rights required to remove registry key.")
		logwrite(1, "Error: Administrator rights required for registry access.")
		Return False
	EndIf
	Local $icurrentvalue = RegRead($skey, $svaluename)
	If @error <> 0 Then
		memowrite("No registry key " & $svaluename & " found to remove.")
		logwrite(1, "No registry key " & $svaluename & " found.")
		Return True
	EndIf
	If $icurrentvalue <> $iexpectedvalue Then
		memowrite("Registry key " & $svaluename & " not enabled; no action taken.")
		logwrite(1, "Registry key " & $svaluename & " not set to " & $iexpectedvalue & ".")
		Return True
	EndIf
	If RegDelete($skey, $svaluename) Then
		memowrite("Disabled registry key " & $svaluename & ".")
		logwrite(1, "Removed registry key " & $svaluename & ".")
		showrebootpopup()
		Return True
	Else
		memowrite("Error: Failed to disable registry key " & $svaluename & ".")
		logwrite(1, "Error: Failed to remove registry key " & $svaluename & " (Error: " & @error & ").")
		Return False
	EndIf
EndFunc   ;==>removedevoverride

Func showrebootpopup()
	Local $amainpos = WinGetPos($myhgui)
	Local $ipopupx = $amainpos[0] + ($amainpos[2] - 200) / 2
	Local $ipopupy = $amainpos[1] + ($amainpos[3] - 100) / 2
	Local $hpopup = GUICreate('', 200, 100, $ipopupx, $ipopupy, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOPMOST)
	GUICtrlCreateLabel("System reboot required for changes to take effect.", 10, 10, 180, 40, $SS_CENTER)
	Local $IDOK = GUICtrlCreateButton("OK", 50, 60, 100, 30)
	GUISetState(@SW_SHOW)
	While 1
		If GUIGetMsg() = $IDOK Then ExitLoop
	WEnd
	GUIDelete($hpopup)
EndFunc   ;==>showrebootpopup

Func managewintrust()
	Local $amainpos = WinGetPos($myhgui)
	Local $ipopupx = $amainpos[0] + ($amainpos[2] - 300) / 2
	Local $ipopupy = $amainpos[1] + ($amainpos[3] - 150) / 2
	Local $hgui = GUICreate("Manage WinTrust", 300, 150, $ipopupx, $ipopupy)
	Local $htrustbutton = GUICtrlCreateButton("Trust", 50, 50, 100, 30)
	Local $huntrustbutton = GUICtrlCreateButton("Untrust", 150, 50, 100, 30)
	Local $hcancelbutton = GUICtrlCreateButton("Cancel", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hcancelbutton
				memowrite("WinTrust management cancelled.")
				GUIDelete($hgui)
				Return
			Case $htrustbutton
				GUIDelete($hgui)
				trustexes()
				Return
			Case $huntrustbutton
				GUIDelete($hgui)
				untrustexes()
				Return
		EndSwitch
	WEnd
EndFunc   ;==>managewintrust

Func findtrustexes()
	Local $foundapps = findadobeapps(True)
	Local $foundexes[0]
	For $app In $foundapps
		Local $appdir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appname = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localdir = $appdir & "\" & $appname & ".local"
		Local $dllpath = $localdir & "\wintrust.dll"
		If FileExists($dllpath) Then
			_ArrayAdd($foundexes, $app)
		EndIf
	Next
	Return $foundexes
EndFunc   ;==>findtrustexes

Func trustexes()
	memowrite("Scanning for applications to trust...")
	Local $foundapps = findadobeapps(True)
	If UBound($foundapps) = 0 Then
		memowrite("No applications found to trust.")
		logwrite(1, "No applications found to trust.")
		Return
	EndIf
	Local $selectedapps = trustselectiongui($foundapps, "Trust")
	If Not IsArray($selectedapps) Or UBound($selectedapps) = 0 Then
		memowrite("No applications selected to trust.")
		logwrite(1, "No applications selected to trust.")
		Return
	EndIf
	If Not adddevoverride() Then
		memowrite("WinTrust operation aborted due to registry error.")
		Return
	EndIf
	Local $dllsourcepath = @ScriptDir & "\wintrust.dll"
	If Not FileExists($dllsourcepath) Or FileGetSize($dllsourcepath) <> 382712 Then
		FileInstall("wintrust.dll", $dllsourcepath, 1)
		If Not FileExists($dllsourcepath) Then
			memowrite("Error: Failed to extract wintrust.dll to " & $dllsourcepath)
			logwrite(1, "Error: Failed to extract wintrust.dll.")
			Return
		EndIf
	EndIf
	If FileGetSize($dllsourcepath) <> 382712 Then
		memowrite("Error: wintrust.dll size mismatch (expected 382,712 bytes).")
		logwrite(1, "Error: wintrust.dll size mismatch (expected 382,712 bytes).")
		FileDelete($dllsourcepath)
		Return
	EndIf
	memowrite("Trusting " & UBound($selectedapps) & " application(s)...")
	logwrite(1, "Trusting " & UBound($selectedapps) & " application(s):")
	Local $successcount = 0
	For $app In $selectedapps
		$app = StringStripWS($app, 3)
		If $app = '' Or Not FileExists($app) Then
			memowrite("Skipping invalid or missing file: " & $app)
			logwrite(1, "Skipping invalid or missing file: " & $app)
			ContinueLoop
		EndIf
		Local $appdir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appname = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localdir = $appdir & "\" & $appname & ".local"
		Local $dllpath = $localdir & "\wintrust.dll"
		logwrite(1, "- Processing: " & $app)
		If Not DirCreate($localdir) Then
			memowrite("Failed to create directory: " & $localdir)
			logwrite(1, "Failed to create directory: " & $localdir)
			ContinueLoop
		EndIf
		If FileExists($dllpath) Then
			If FileGetSize($dllpath) = 382712 Then
				memowrite("wintrust.dll already exists at: " & $dllpath & " - Skipping.")
				logwrite(1, "wintrust.dll already exists at: " & $dllpath & " - Skipping.")
				$successcount += 1
			Else
				FileDelete($dllpath)
				If FileCopy($dllsourcepath, $dllpath, 1) And FileGetSize($dllpath) > 0 Then
					memowrite("Replaced wintrust.dll at: " & $dllpath)
					logwrite(1, "Replaced wintrust.dll at: " & $dllpath)
					$successcount += 1
				Else
					memowrite("Failed to replace wintrust.dll to: " & $dllpath)
					logwrite(1, "Failed to replace wintrust.dll to: " & $dllpath)
				EndIf
			EndIf
			ContinueLoop
		EndIf
		If FileCopy($dllsourcepath, $dllpath, 1) And FileGetSize($dllpath) > 0 Then
			memowrite("Successfully trusted: " & $appname)
			logwrite(1, "Successfully trusted: " & $appname)
			$successcount += 1
		Else
			memowrite("Failed to trust: " & $appname)
			logwrite(1, "Failed to trust: " & $appname)
		EndIf
	Next
	If FileExists($dllsourcepath) Then
		If FileDelete($dllsourcepath) Then
			memowrite("Deleted wintrust.dll from " & $dllsourcepath & ".")
		Else
			memowrite("Warning: Failed to delete wintrust.dll from " & $dllsourcepath & ".")
		EndIf
	EndIf
	memowrite("Trust completed. Successfully processed " & $successcount & " of " & UBound($selectedapps) & " applications.")
	logwrite(1, "Trust completed. Successfully processed " & $successcount & " of " & UBound($selectedapps) & " applications.")
	togglelog(1)
EndFunc   ;==>trustexes

Func untrustexes()
	memowrite("Scanning for trusted applications...")
	Local $foundexes = findtrustexes()
	If UBound($foundexes) = 0 Then
		memowrite("No trusted applications found to untrust.")
		logwrite(1, "No trusted applications found to untrust.")
		Return
	EndIf
	Local $selectedapps = trustselectiongui($foundexes, "Untrust")
	If Not IsArray($selectedapps) Or UBound($selectedapps) = 0 Then
		memowrite("No applications selected to untrust.")
		logwrite(1, "No applications selected to untrust.")
		Return
	EndIf
	memowrite("Untrusting " & UBound($selectedapps) & " application(s)...")
	logwrite(1, "Untrusting " & UBound($selectedapps) & " application(s):")
	Local $successcount = 0
	For $app In $selectedapps
		$app = StringStripWS($app, 3)
		If $app = '' Or Not FileExists($app) Then
			memowrite("Skipping invalid or missing file: " & $app)
			logwrite(1, "Skipping invalid or missing file: " & $app)
			ContinueLoop
		EndIf
		Local $appdir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appname = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localdir = $appdir & "\" & $appname & ".local"
		Local $dllpath = $localdir & "\wintrust.dll"
		logwrite(1, "- Processing: " & $app)
		If Not FileExists($dllpath) Then
			memowrite("No wintrust.dll found at: " & $dllpath & " - Skipping.")
			logwrite(1, "No wintrust.dll found at: " & $dllpath & " - Skipping.")
			ContinueLoop
		EndIf
		If DirRemove($localdir, 1) Then
			memowrite("Successfully untrusted: " & $appname)
			logwrite(1, "Successfully untrusted: " & $appname)
			$successcount += 1
		Else
			memowrite("Failed to untrust: " & $appname)
			logwrite(1, "Failed to untrust: " & $appname)
		EndIf
	Next
	memowrite("Untrust completed. Successfully processed " & $successcount & " of " & UBound($selectedapps) & " application(s).")
	logwrite(1, "Untrust completed. Successfully processed " & $successcount & " of " & UBound($selectedapps) & " application(s).")
	togglelog(1)
EndFunc   ;==>untrustexes

Func trustselectiongui($foundfiles, $operation)
	If UBound($foundfiles) = 0 Then
		memowrite("No applications found to " & StringLower($operation) & ".")
		logwrite(1, "No applications found to " & StringLower($operation) & ".")
		Return ''
	EndIf
	Local $amainpos = WinGetPos($myhgui)
	Local $ipopupx = $amainpos[0] + ($amainpos[2] - 500) / 2
	Local $ipopupy = $amainpos[1] + ($amainpos[3] - 400) / 2
	Local $hgui = GUICreate($operation, 500, 400, $ipopupx, $ipopupy)
	Local $hselectall = GUICtrlCreateCheckbox("Select All", 10, 10)
	Local $htreeview = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hokbutton = GUICtrlCreateButton("OK", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)
	Local $defpathclean = StringStripWS($mydefpath, 3)
	If StringRight($defpathclean, 1) = "\" Then
		$defpathclean = StringTrimRight($defpathclean, 1)
	EndIf
	Local $defpathparts = StringSplit($defpathclean, "\", 1)
	Local $defpathdepth = $defpathparts[0]
	Local $appnodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundfiles
		Local $fileparts = StringSplit($file, "\", 1)
		Local $appname = "Unknown"
		If $fileparts[0] >= $defpathdepth + 1 Then
			$appname = $fileparts[$defpathdepth + 1]
		EndIf
		If Not $appnodes.Exists($appname) Then
			Local $happnode = GUICtrlCreateTreeViewItem($appname, $htreeview)
			$appnodes($appname) = $happnode
			_GUICtrlTreeView_SetChecked($htreeview, $happnode, False)
		EndIf
		Local $hitem = GUICtrlCreateTreeViewItem($file, $appnodes($appname))
		_GUICtrlTreeView_SetChecked($htreeview, $hitem, False)
	Next
	Global $prevstates = ObjCreate("Scripting.Dictionary")
	Global $ghtreeview = $htreeview
	Local $hitem = _GUICtrlTreeView_GetFirstItem($htreeview)
	While $hitem <> 0
		Local $itemtext = _GUICtrlTreeView_GetText($htreeview, $hitem)
		If _GUICtrlTreeView_GetChildCount($htreeview, $hitem) > 0 Then
			$prevstates($itemtext) = False
		EndIf
		$hitem = _GUICtrlTreeView_GetNext($htreeview, $hitem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 250)
	Local $bpaused = False
	While 1
		Local $nmsg = GUIGetMsg()
		Switch $nmsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hgui)
				Return ''
			Case $hselectall
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedstate = (GUICtrlRead($hselectall) = $GUI_CHECKED)
				Local $hitem = _GUICtrlTreeView_GetFirstItem($htreeview)
				While $hitem <> 0
					_GUICtrlTreeView_SetChecked($htreeview, $hitem, $checkedstate)
					Local $itemtext = _GUICtrlTreeView_GetText($htreeview, $hitem)
					If _GUICtrlTreeView_GetChildCount($htreeview, $hitem) > 0 Then
						$prevstates($itemtext) = $checkedstate
					EndIf
					$hitem = _GUICtrlTreeView_GetNext($htreeview, $hitem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 250)
			Case $hokbutton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedfiles[0]
				Local $hitem = _GUICtrlTreeView_GetFirstItem($htreeview)
				memowrite("Scanning for selected items...")
				While $hitem <> 0
					If _GUICtrlTreeView_GetChecked($htreeview, $hitem) Then
						Local $itemtext = _GUICtrlTreeView_GetText($htreeview, $hitem)
						If StringInStr($itemtext, ".exe") Then
							_ArrayAdd($selectedfiles, $itemtext)
						EndIf
					EndIf
					$hitem = _GUICtrlTreeView_GetNext($htreeview, $hitem)
				WEnd
				_GUICtrlTab_SetCurFocus($htab, 3)
				GUIDelete($hgui)
				Return $selectedfiles
			Case $GUI_EVENT_PRIMARYDOWN
				Local $acursor = GUIGetCursorInfo($hgui)
				If IsArray($acursor) And $acursor[4] = $htreeview Then
					If Not $bpaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bpaused = True
					EndIf
				EndIf
			Case Else
				If $bpaused Then
					AdlibRegister("CheckParentCheckboxes", 250)
					$bpaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>trustselectiongui

Func managedevoverride()
	Local $amainpos = WinGetPos($myhgui)
	Local $ipopupx = $amainpos[0] + ($amainpos[2] - 300) / 2
	Local $ipopupy = $amainpos[1] + ($amainpos[3] - 150) / 2
	Local $hgui = GUICreate("Manage DevOverride", 300, 150, $ipopupx, $ipopupy)
	Local $skey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $svaluename = "DevOverrideEnable"
	Local $sstatus
	Local $ivalue = RegRead($skey, $svaluename)
	If @error <> 0 Then
		$sstatus = "Registry key not found."
	ElseIf $ivalue = 1 Then
		$sstatus = "Registry key is enabled."
	Else
		$sstatus = "Registry key is disabled."
	EndIf
	GUICtrlCreateLabel($sstatus, 10, 20, 280, 20, $SS_CENTER)
	Local $haddbutton = GUICtrlCreateButton("Enable Reg Key", 50, 50, 100, 30)
	Local $hremovebutton = GUICtrlCreateButton("Remove Reg Key", 150, 50, 100, 30)
	Local $hcancelbutton = GUICtrlCreateButton("Cancel", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hcancelbutton
				memowrite("DevOverride registry management cancelled.")
				GUIDelete($hgui)
				Return
			Case $haddbutton
				GUIDelete($hgui)
				adddevoverride()
				Return
			Case $hremovebutton
				GUIDelete($hgui)
				removedevoverride()
				Return
		EndSwitch
	WEnd
EndFunc   ;==>managedevoverride

Func openwf()
	Local $swfpath = @SystemDir & "\wf.msc"
	Run("mmc.exe " & $swfpath)
	ConsoleWrite("Opening Windows Firewall...")
EndFunc   ;==>openwf
