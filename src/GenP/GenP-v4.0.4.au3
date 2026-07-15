#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Skull.ico
#AutoIt3Wrapper_Outfile_x64=GenP-v4.0.4.exe
#AutoIt3Wrapper_Res_Comment=GenP
#AutoIt3Wrapper_Res_CompanyName=GenP
#AutoIt3Wrapper_Res_Description=GenP
#AutoIt3Wrapper_Res_Fileversion=4.0.4
#AutoIt3Wrapper_Res_LegalCopyright=GenP 2026
#AutoIt3Wrapper_Res_LegalTradeMarks=GenP 2026
#AutoIt3Wrapper_Res_ProductName=GenP
#AutoIt3Wrapper_Res_ProductVersion=4.0.4
#AutoIt3Wrapper_Res_Field=ID|GenP-%date%-%time%
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_Run_Tidy=n
#AutoIt3Wrapper_UseUpx=y
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
#include <ListBoxConstants.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <String.au3>
#include <TreeViewConstants.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>
#include <WinAPITheme.au3>

AutoItSetOption("GUICloseOnESC", 0)

Global $g_Version = "4.0.4"
Global $g_AppWndTitle = "GenP v" & $g_Version
Global $g_AppVersion = "GenP" & @CRLF & "原版作者 uncia"

Global $patchStatesINI = @ScriptDir & "\patch_states.ini"
Global $g_aStateQueue[0][5]
Global $g_bCryptActive = False
Global $g_mAppVersionQueue  = ObjCreate("Scripting.Dictionary")
Global $g_mWinTrustQueue    = ObjCreate("Scripting.Dictionary")
Global $g_mAppPrimaryExe    = ObjCreate("Scripting.Dictionary")
Global $idSubProgress = -1
Global $idShowBetaApps = -1
Global $idEnableGood1 = -1
Global $idLabelRuntimeAuto = -1

Global $g_aAllFiles[0][5]
Global $g_mCheckedState = ObjCreate("Scripting.Dictionary")
Global $g_bSearchCompleted = False
Global $g_sRequiresGood1Files = "|"

Global Const $g_iLogTabIndex = 6

Global $g_idStatusTitle = -1, $g_idStatusDetail = -1
Global $g_sCurrentSearchPath = ""

If _Singleton($g_AppWndTitle, 1) = 0 Then
	Exit
EndIf

Global $MyLVGroupIsExpanded = True
Global $g_aGroupIDs[0]
Global $fInterrupt = 0
Global $FilesToPatch[0][1], $FilesToPatchNull[0][1]
Global $FilesToRestore[0][1], $fFilesListed = 0
Global $MyhGUI, $hTab, $hMainTab, $hLogTab, $idMsg, $idListview, $g_idListview, $idButtonSearch, $idButtonStop
Global $idButtonCustomFolder, $idBtnCure, $idBtnDeselectAll, $ListViewSelectFlag = 1
Global $idBtnModified = 0
Global $idBtnUpdateHosts, $idMemo, $timestamp, $idLog, $idBtnRestore, $idBtnCopyLog, $idFindACC
Global $idEnableMD5, $idOnlyAFolders, $idBtnSaveOptions, $idCustomDomainListLabel, $idCustomDomainListInput
Global $hPopupTab, $idBtnRemoveAGS, $idBtnCleanHosts, $idBtnEditHosts, $idLabelEditHosts, $sEditHostsText, $idBtnRestoreHosts
Global $sRemoveAGSText, $idLabelRemoveAGS, $sCleanFirewallText, $idLabelCleanFirewall, $idBtnOpenWF, $idBtnCreateFW, $idBtnRemoveFW, $idBtnToggleFW
Global $sRuntimeInstallerText, $idLabelRuntimeInstaller, $idBtnToggleRuntimeInstaller, $sWinTrustText, $idLabelWinTrust, $idBtnToggleWinTrust, $idBtnDevOverride
Global $idBtnAGSInfo, $idBtnFirewallInfo, $idBtnHostsInfo, $idBtnRuntimeInfo, $idBtnWintrustInfo
Global $g_idHyperlinkMain, $g_idHyperlinkOptions, $g_idHyperlinkPopup, $g_idHyperlinkLog
Global $g_idHyperlinkFW = 0, $g_idHyperlinkHosts = 0, $g_idHyperlinkWT = 0, $g_idHyperlinkAGS = 0

Global $idBtnCollapseAll = 0, $idBtnExpandAll = 0
Global $idBtnCheckAll = 0, $idBtnUncheckAll = 0
Global $idBtnCheckUnpatched = 0, $idBtnCheckPatched = 0, $idBtnRefresh = 0

Global $idResetOnSave = 0
Global $idReconcileStates = 0
Global $idCreateStates = 0
Global $idUseCustomDefault = 0
Global $idBtnSetCustomPath = 0
Global $idOptionsReminder = 0
Global $g_mOptionsSnapshot = 0
Global $g_bOptionsDirty = False
Global $g_iOptionsPollTick = 0
Global $g_bIsPatching = False
Global $g_bUxpHandledFile = False
Global $g_bPendingInfoReset = False
Global $g_bInModifiedMode = False
Global $g_bAutoPatchPending = False

Global $g_AppCount = 0
Global $g_FilesToPatchCount = 0
Global $g_dotCounter = 0
Global $g_mScannedApps = 0
Global $g_mBlockedParents = 0
Global $g_mBlockedAppPaths = 0
Global $g_sLastScanDir = ""
Global $g_bStatusScreenReady = False

Global $idBtnDummyAGS = 0
Global $idBtnSetTrustPath = 0
Global $idLabelTrustPath = 0
Global $g_sWinTrustPath

Global $sINIPath = @ScriptDir & "\config.ini"
If Not FileExists($sINIPath) Then
	FileInstall("config.ini", @ScriptDir & "\config.ini")
EndIf
Global $ConfigVerVar = IniRead($sINIPath, "Info", "ConfigVer", "????")

$g_sWinTrustPath = IniRead($sINIPath, "Options", "WinTrustPath", @ProgramFilesDir & "\Adobe")

Global $bUseCustomDefault = Number(IniRead($sINIPath, "Options", "UseCustomDefault", "0"))
Global $g_sCustomDefaultPath = StringRegExpReplace(IniRead($sINIPath, "Custom_Default", "Path", ""), "\\\\+", "\\")
Global $g_sPendingCustomPath = $g_sCustomDefaultPath

Global $MyDefPath
If $bUseCustomDefault = 1 And $g_sCustomDefaultPath <> "" And FileExists($g_sCustomDefaultPath) Then
	$MyDefPath = $g_sCustomDefaultPath
Else
	$MyDefPath = @ProgramFilesDir & "\Adobe"
EndIf
$MyDefPath = StringRegExpReplace($MyDefPath, "\\\\+", "\\")

IniWrite($sINIPath, "Default", "Path", @ProgramFilesDir & "\Adobe")

If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
	$MyDefPath = StringRegExpReplace(@ProgramFilesDir & "\Adobe", "\\\\+", "\\")
EndIf

Global $MyRegExpGlobalPatternSearchCount = 0, $Count = 0, $idProgressBar
Global $aOutHexGlobalArray[0], $aNullArray[0], $aInHexArray[0]
Global $MyFileToParse = "", $MyFileToParsSweatPea = "", $MyFileToParseEaclient = ""
Global $sz_type, $bFoundAcro32 = False, $bFoundGenericARM = False, $aSpecialFiles, $sSpecialFiles = "|"
Global $ProgressFileCountScale, $FileSearchedCount

Global $bFindACC = IniRead($sINIPath, "Options", "FindACC", "1")
Global $bEnableMD5 = 1
Global $bOnlyAFolders = IniRead($sINIPath, "Options", "OnlyDefaultFolders", "1")
Global $bShowBetaApps = IniRead($sINIPath, "Options", "ShowBetaApps", "1")
Global $bEnableGood1 = IniRead($sINIPath, "Options", "EnableGood1", "1")
Global $g_sEdition = IniRead($sINIPath, "Options", "Edition", "GenP")

Global $g_sThirdPartyFirewall = ""
Global $fwc = ""
Global $SelectedApps = []

Global $sDefaultDomainListURL = "https://a.dove.isdumb.one/list.txt"
Global $sCurrentDomainListURL = IniRead($sINIPath, "Options", "CustomDomainListURL", $sDefaultDomainListURL)

Global $g_iHyperlinkClickTime = 0
Global Const $STN_CLICKED = 0

Local $tTargetFileList = IniReadSection($sINIPath, "TargetFiles")
Global $TargetFileList[0]
If Not @error Then
	ReDim $TargetFileList[$tTargetFileList[0][0]]
	For $i = 1 To $tTargetFileList[0][0]
		$TargetFileList[$i - 1] = StringReplace($tTargetFileList[$i][1], '"', "")
	Next
EndIf

$aSpecialFiles = IniReadSection($sINIPath, "CustomPatterns")
For $i = 1 To UBound($aSpecialFiles) - 1
	$sSpecialFiles = $sSpecialFiles & $aSpecialFiles[$i][0] & "|"
	Local $sPatternList = StringLower(StringReplace(StringReplace($aSpecialFiles[$i][1], '"', ''), ' ', ''))
	If $sPatternList = "good1" Then
		$g_sRequiresGood1Files = $g_sRequiresGood1Files & StringLower($aSpecialFiles[$i][0]) & "|"
	EndIf
Next
Global $g_aSignature = "r~~z}D99""sus8nl%o|:8myw9qoxz7q sno}9"

If $CmdLine[0] = 1 And $CmdLine[1] = "-updatehosts" Then
	UpdateHostsFile()
	Exit
EndIf

GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")

MainGui()

Local $bHostsbakExists = False
If FileExists(@WindowsDir & "\System32\drivers\etc\hosts.bak") Then
	GUICtrlSetState($idBtnRestoreHosts, $GUI_ENABLE)
	$bHostsbakExists = True
EndIf

While 1
	Local $bHostsbakExistsNow
	If FileExists(@WindowsDir & "\System32\drivers\etc\hosts.bak") Then
		$bHostsbakExistsNow = True
	Else
		$bHostsbakExistsNow = False
	EndIf

	If $bHostsbakExistsNow <> $bHostsbakExists Then
		If $bHostsbakExistsNow Then
			GUICtrlSetState($idBtnRestoreHosts, $GUI_ENABLE)
		Else
			GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
		EndIf
		$bHostsbakExists = $bHostsbakExistsNow
	EndIf

	$g_iOptionsPollTick += 1
	If $g_iOptionsPollTick >= 50 And Not $g_bIsPatching Then
		$g_iOptionsPollTick = 0
		CheckOptionsChanged()
	EndIf

	$idMsg = GUIGetMsg()

	If $g_bAutoPatchPending Then
		$g_bAutoPatchPending = False
		$idMsg = $idBtnCure
	EndIf

	Select
		Case $idMsg = $GUI_EVENT_CLOSE
			GUIDelete($MyhGUI)
			_Exit()
		Case $idMsg = $GUI_EVENT_RESIZED
			ContinueCase
		Case $idMsg = $GUI_EVENT_RESTORE
			ContinueCase
		Case $idMsg = $GUI_EVENT_MAXIMIZE
			Local $iWidth
			Local $aGui = WinGetPos($MyhGUI)
			Local $aRect = _GUICtrlListView_GetViewRect($g_idListview)
			If ($aRect[2] > $aGui[2]) Then
				$iWidth = $aGui[2] - 75
			Else
				$iWidth = $aRect[2] - 25
			EndIf
			GUICtrlSendMsg($idListview, $LVM_SETCOLUMNWIDTH, 1, $iWidth)

		Case $idMsg = $idButtonStop
			$ListViewSelectFlag = 0
			$fInterrupt = 1
			_ShowStatusScreen("stopped", $g_sLastScanDir)
			Sleep(1500)
			ReDim $g_aAllFiles[0][5]
			$g_bSearchCompleted = False
			$g_mCheckedState.RemoveAll()
			_ResetScanCounters()
			FillListViewWithInfo()
			MemoWrite(@CRLF & "路径" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作.")
			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)

		Case $idMsg = $idButtonSearch
			$fInterrupt = 0
			$g_bIsPatching = True
			GUICtrlSetData($idLog, "操作日志" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP 版本: " & $g_Version & @CRLF & "配置版本: " & $ConfigVerVar & @CRLF)
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnModified, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnCheckAll, 128)
			GUICtrlSetState($idBtnUncheckAll, 128)
			GUICtrlSetState($idBtnCheckUnpatched, 128)
			GUICtrlSetState($idBtnCheckPatched, 128)
			GUICtrlSetState($idBtnRefresh, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
			_ResetScanCounters()
			_ShowStatusScreen("scanning", $MyDefPath)

			$FilesToPatch = $FilesToPatchNull
			$FilesToRestore = $FilesToPatchNull
			ReDim $g_aAllFiles[0][5]
			$g_bSearchCompleted = False
			$g_mCheckedState.RemoveAll()

			$timestamp = TimerInit()

			Local $FileCount

			If $bFindACC = 1 Then
				Local $aACCDirs[2]
				$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
				$aACCDirs[1] = EnvGet('ProgramFiles')      & "\Common Files\Adobe"
				For $sAppsPanelDir In $aACCDirs
					If Not FileExists($sAppsPanelDir) Then ContinueLoop
					Local $aSize = DirGetSize($sAppsPanelDir, $DIR_EXTENDED)
					If UBound($aSize) >= 2 Then
						$FileCount = $aSize[1]
						RecursiveFileSearch($sAppsPanelDir, 0, $FileCount)
						ProgressWrite(0)
					EndIf
				Next
			EndIf

			$aSize = DirGetSize($MyDefPath, $DIR_EXTENDED)
			If UBound($aSize) >= 2 Then
				$FileCount = $aSize[1]
				$ProgressFileCountScale = 100 / $FileCount
				$FileSearchedCount = 0
				ProgressWrite(0)
				RecursiveFileSearch($MyDefPath, 0, $FileCount)
				Sleep(100)
				ProgressWrite(0)
			EndIf

			If $fInterrupt = 0 Then
				_ShowStatusScreen("complete", $MyDefPath)
				_SubProgressWrite(0)
				Sleep(3000)
			EndIf

			FillListViewWithFiles()

			_VerifyListedFiles(True)

			UpdateUIState()

			If _GUICtrlListView_GetItemCount($idListview) > 0 Then

				$ListViewSelectFlag = 1
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)

				If UBound($FilesToRestore) > 0 Then
					GUICtrlSetState($idBtnUpdateHosts, 128)
					GUICtrlSetState($idBtnCleanHosts, 128)
					GUICtrlSetState($idBtnEditHosts, 128)
					GUICtrlSetState($idBtnCreateFW, 128)
					GUICtrlSetState($idBtnToggleFW, 128)
					GUICtrlSetState($idBtnRemoveFW, 128)
					GUICtrlSetState($idBtnOpenWF, 128)
					GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
					GUICtrlSetState($idBtnToggleWinTrust, 128)
					GUICtrlSetState($idBtnDevOverride, 128)
					GUICtrlSetState($idBtnRemoveAGS, 128)
					GUICtrlSetState($idBtnRestoreHosts, 128)
					GUICtrlSetState($idBtnRestore, 64)
					GUICtrlSetState($idBtnAGSInfo, 128)
					GUICtrlSetState($idBtnFirewallInfo, 128)
					GUICtrlSetState($idBtnHostsInfo, 128)
					GUICtrlSetState($idBtnRuntimeInfo, 128)
					GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
				EndIf
			Else
				$ListViewSelectFlag = 0
				FillListViewWithInfo()
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)
			EndIf

			_Expand_All_Click()

			GUICtrlSetState($idBtnDeselectAll, 64)
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)
			$g_bIsPatching = False

		Case $idMsg = $idButtonCustomFolder
			ToggleLog(0)
			MyFileOpenDialog()
			_Expand_All_Click()
			If $fFilesListed = 0 Then
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)
			Else
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 64)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)
			EndIf

		Case $idMsg = $idBtnCheckAll
			ToggleLog(0)
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
				_GUICtrlListView_SetItemChecked($idListview, $i, 1)
			Next
			$ListViewSelectFlag = 1

		Case $idMsg = $idBtnUncheckAll
			ToggleLog(0)
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
				_GUICtrlListView_SetItemChecked($idListview, $i, 0)
			Next
			$ListViewSelectFlag = 0

		Case $idMsg = $idBtnCheckUnpatched
			ToggleLog(0)
			Local $iCt = _GUICtrlListView_GetItemCount($idListview)
			Local $iChecked = 0
			For $i = 0 To $iCt - 1
				Local $sStatus = _GUICtrlListView_GetItemText($idListview, $i, 2)
				If $sStatus <> "已修补" Then
					_GUICtrlListView_SetItemChecked($idListview, $i, 1)
					$iChecked += 1
				Else
					_GUICtrlListView_SetItemChecked($idListview, $i, 0)
				EndIf
			Next
			MemoWrite(@CRLF & "已选中 " & $iChecked & " / " & $iCt & " 个未修补文件.")
			$ListViewSelectFlag = ($iChecked > 0) ? 1 : 0

		Case $idMsg = $idBtnCheckPatched
			Local $iCt = _GUICtrlListView_GetItemCount($idListview)
			Local $iChecked = 0
			For $i = 0 To $iCt - 1
				Local $sStatus = _GUICtrlListView_GetItemText($idListview, $i, 2)
				If $sStatus = "已修补" Then
					_GUICtrlListView_SetItemChecked($idListview, $i, 1)
					$iChecked += 1
				Else
					_GUICtrlListView_SetItemChecked($idListview, $i, 0)
				EndIf
			Next
			MemoWrite(@CRLF & "已选中 " & $iChecked & " / " & $iCt & " 个已修补文件.")
			$ListViewSelectFlag = ($iChecked > 0) ? 1 : 0

		Case $idMsg = $idBtnRefresh
			ToggleLog(0)
			$fInterrupt = 0
			_RefreshSearch()

		Case $idMsg = $idBtnCure
			Local $bPSE2026 = False, $bPRE2026 = False, $bORG2026 = False
			Local $aOrgItems[0], $aPseItems[0], $aPreItems[0]
			Local $iCountAll = _GUICtrlListView_GetItemCount($idListview)
			For $i = 0 To $iCountAll - 1
				If Not _GUICtrlListView_GetItemChecked($idListview, $i) Then ContinueLoop
				Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
				Local $sGrp = _GetAppGroupName($sPath)
				If $sGrp = "Elements 2026 Organizer" Then
					$bORG2026 = True
					_ArrayAdd($aOrgItems, $i)
				ElseIf $sGrp = "Photoshop Elements 2026" Then
					$bPSE2026 = True
					_ArrayAdd($aPseItems, $i)
				ElseIf $sGrp = "Premiere Elements 2026" Then
					$bPRE2026 = True
					_ArrayAdd($aPreItems, $i)
				EndIf
			Next
			If ($bPSE2026 Or $bPRE2026 Or $bORG2026) And Not ($bPSE2026 And $bPRE2026 And $bORG2026) Then
				Local $bHasPSE = False, $bHasPRE = False, $bHasORG = False
				For $i = 0 To $iCountAll - 1
					Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
					Local $sGrp = _GetAppGroupName($sPath)
					If $sGrp = "Photoshop Elements 2026" Then $bHasPSE = True
					If $sGrp = "Premiere Elements 2026"  Then $bHasPRE = True
					If $sGrp = "Elements 2026 Organizer" Then $bHasORG = True
				Next
				Local $sMissing = ""
				If $bHasPSE And Not $bPSE2026 Then $sMissing &= "  - Photoshop Elements 2026" & @CRLF
				If $bHasPRE And Not $bPRE2026 Then $sMissing &= "  - Premiere Elements 2026" & @CRLF
				If $bHasORG And Not $bORG2026 Then $sMissing &= "  - Elements 2026 Organizer" & @CRLF
				Local $iAns = MsgBox($MB_YESNOCANCEL, _
						"是否一并修补 Elements 2026?", _
						"Photoshop Elements、Premiere Elements 和 Organizer 共用部分组件，" & @CRLF & _
						"应作为整体一并修补." & @CRLF & @CRLF & _
						"以下项目尚未选中:" & @CRLF & $sMissing & @CRLF & _
						"是 = 自动选中并继续" & @CRLF & _
						"否 = 仍然继续 (不推荐)" & @CRLF & _
						"取消 = 终止修补")
				If $iAns = $IDCANCEL Then
					$g_bIsPatching = False
					ContinueLoop
				ElseIf $iAns = $IDYES Then
					For $i = 0 To $iCountAll - 1
						Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
						Local $sGrp = _GetAppGroupName($sPath)
						If ($sGrp = "Photoshop Elements 2026" And $bHasPSE) Or _
						   ($sGrp = "Premiere Elements 2026"  And $bHasPRE) Or _
						   ($sGrp = "Elements 2026 Organizer" And $bHasORG) Then
							_GUICtrlListView_SetItemChecked($idListview, $i, 1)
						EndIf
					Next
					MemoWrite(@CRLF & "已自动选中尚未选择的 Elements 2026 组件.")
				EndIf
			EndIf

			ToggleLog(0)
			$g_bIsPatching = True
			GUICtrlSetState($idFindACC, $GUI_DISABLE)
			GUICtrlSetState($idOnlyAFolders, $GUI_DISABLE)
			GUICtrlSetState($idEnableGood1, $GUI_DISABLE)
			GUICtrlSetState($idShowBetaApps, $GUI_DISABLE)
			GUICtrlSetState($idResetOnSave, $GUI_DISABLE)
			GUICtrlSetState($idReconcileStates, $GUI_DISABLE)
			GUICtrlSetState($idCreateStates, $GUI_DISABLE)
			GUICtrlSetState($idUseCustomDefault, $GUI_DISABLE)
			GUICtrlSetState($idBtnSetCustomPath, $GUI_DISABLE)
			GUICtrlSetState($idCustomDomainListInput, $GUI_DISABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckAll, $GUI_DISABLE)
			GUICtrlSetState($idBtnUncheckAll, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckUnpatched, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckPatched, $GUI_DISABLE)
			GUICtrlSetState($idBtnRefresh, $GUI_DISABLE)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
			_Expand_All_Click()

			Local $ItemFromList
			Local $iTotalChecked = 0, $iDone = 0
			Local $iFirstChecked = -1
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then
					$iTotalChecked += 1
					If $iFirstChecked = -1 Then $iFirstChecked = $i
				EndIf
			Next

			If $iFirstChecked >= 0 Then
				_GUICtrlListView_EnsureVisible($idListview, $iFirstChecked, 0)
			EndIf

			ProgressWrite(0)
			_SubProgressWrite(0)
			If $bEnableMD5 = 1 Then
				_Crypt_Startup()
				$g_bCryptActive = True
			EndIf

			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)
					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)

					_GUICtrlListView_SetItemText($idListview, $i, "修补中...", 2)

					_GUICtrlListView_EnsureVisible($idListview, $i, 0)

					MyGlobalPatternSearch($ItemFromList)
					If Not $g_bUxpHandledFile Then
						MemoWrite(@CRLF & "路径" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "开始用药 :)")
						LogWrite(1, $ItemFromList)
					EndIf

					MyGlobalPatternPatch($ItemFromList, $aOutHexGlobalArray)

					If FileExists($ItemFromList & ".bak") Then
						_GUICtrlListView_SetItemText($idListview, $i, "已修补", 2)
					Else
						_GUICtrlListView_SetItemText($idListview, $i, "未改动", 2)
					EndIf

					$iDone += 1
					If $iTotalChecked > 0 Then ProgressWrite(Round($iDone / $iTotalChecked * 100))

					Sleep(50)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			If $g_bCryptActive Then
				_Crypt_Shutdown()
				$g_bCryptActive = False
			EndIf

			_FlushStateQueue()

			ProgressWrite(0)
			_SubProgressWrite(0)

			$g_bIsPatching = False
			GUICtrlSetState($idFindACC, $GUI_ENABLE)
			GUICtrlSetState($idOnlyAFolders, $GUI_ENABLE)
			GUICtrlSetState($idEnableGood1, $GUI_ENABLE)
			GUICtrlSetState($idShowBetaApps, $GUI_ENABLE)
			GUICtrlSetState($idResetOnSave, $GUI_ENABLE)
			GUICtrlSetState($idReconcileStates, $GUI_ENABLE)
			GUICtrlSetState($idCreateStates, $GUI_ENABLE)
			GUICtrlSetState($idUseCustomDefault, $GUI_ENABLE)
			GUICtrlSetState($idBtnSetCustomPath, $GUI_ENABLE)
			GUICtrlSetState($idCustomDomainListInput, $GUI_ENABLE)
			CheckOptionsChanged()

			If $g_bInModifiedMode Then
				_VerifyListedFiles(True)

				Local $iStillTodo = 0
				Local $iRow = _GUICtrlListView_GetItemCount($g_idListview) - 1
				_SendMessageL($g_idListview, $WM_SETREDRAW, False, 0)
				While $iRow >= 0
					Local $sStatusMod = _GUICtrlListView_GetItemText($g_idListview, $iRow, 2)
					If $sStatusMod = "已修补" Then
						_GUICtrlListView_DeleteItem($g_idListview, $iRow)
					Else
						$iStillTodo += 1
					EndIf
					$iRow -= 1
				WEnd
				_SendMessageL($g_idListview, $WM_SETREDRAW, True, 0)
				_RedrawWindow($g_idListview)

				If $iStillTodo = 0 Then
					MemoWrite(@CRLF & "待修补列表已清空.")
					LogWrite(1, "待修补列表已处理完毕，所有文件均已修补.")
					_ShowEmptyModifiedNotice()
					$g_bIsPatching = False
					$g_bPendingInfoReset = False
					_RestorePostOpUI()
					UpdateUIState()
					ToggleLog(1)
					_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
					ContinueLoop
				Else
					MemoWrite(@CRLF & "仍有 " & $iStillTodo & " 个文件尚未修补，请再次点击 '修补'.")
					LogWrite(1, "修补结束后仍有 " & $iStillTodo & " 个文件未修补.")
					$g_bIsPatching = False
					$g_bPendingInfoReset = True
					_RestorePostOpUI()
					UpdateUIState()
					ToggleLog(1)
					_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
					ContinueLoop
				EndIf
			EndIf

			$g_bPendingInfoReset = True

			UpdateUIState()

			MemoWrite(@CRLF & "路径" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 256)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)
			FillListViewWithInfo()

			If $bFoundAcro32 = True Then
				MsgBox($MB_SYSTEMMODAL, "提示", "GenP 不支持 x32 版本的 Acrobat，请用 x64 版本.")
				LogWrite(1, "GenP 不支持 x32 版本的 Acrobat，请用 x64 版本.")
			EndIf
			If $bFoundGenericARM = True Then
				MsgBox($MB_SYSTEMMODAL, "提示", "GenP 不支持 ARM 版本，仅支持 x64 版本.")
				LogWrite(1, "GenP 不支持 ARM 版本，仅支持 x64 版本.")
			EndIf

			ToggleLog(1)
			GUICtrlSetState($hLogTab, $GUI_SHOW)
			_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)

		Case $idMsg = $idBtnModified
			$fInterrupt = 0
			$g_bIsPatching = True
			GUICtrlSetData($idLog, "操作日志" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP 版本: " & $g_Version & @CRLF & "配置版本: " & $ConfigVerVar & @CRLF)
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnModified, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnCheckAll, 128)
			GUICtrlSetState($idBtnUncheckAll, 128)
			GUICtrlSetState($idBtnCheckUnpatched, 128)
			GUICtrlSetState($idBtnCheckPatched, 128)
			GUICtrlSetState($idBtnRefresh, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)

			MemoWrite(@CRLF & "变更检查: 正在扫描并核验...")
			_RefreshSearch()

			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)

			Local $iKept = _ApplyModifiedFilter()

			If $iKept = 0 Then
				$g_bIsPatching = False
				_ShowEmptyModifiedNotice()
			Else
				UpdateUIState()
			EndIf

		Case $idMsg = $idBtnRestore
			GUICtrlSetData($idLog, "操作日志" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP 版本: " & $g_Version & "" & @CRLF & "配置版本: " & $ConfigVerVar & "" & @CRLF)
			ToggleLog(0)
			$g_bIsPatching = True
			GUICtrlSetState($idFindACC, $GUI_DISABLE)
			GUICtrlSetState($idOnlyAFolders, $GUI_DISABLE)
			GUICtrlSetState($idEnableGood1, $GUI_DISABLE)
			GUICtrlSetState($idShowBetaApps, $GUI_DISABLE)
			GUICtrlSetState($idResetOnSave, $GUI_DISABLE)
			GUICtrlSetState($idReconcileStates, $GUI_DISABLE)
			GUICtrlSetState($idCreateStates, $GUI_DISABLE)
			GUICtrlSetState($idUseCustomDefault, $GUI_DISABLE)
			GUICtrlSetState($idBtnSetCustomPath, $GUI_DISABLE)
			GUICtrlSetState($idCustomDomainListInput, $GUI_DISABLE)
			GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckAll, $GUI_DISABLE)
			GUICtrlSetState($idBtnUncheckAll, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckUnpatched, $GUI_DISABLE)
			GUICtrlSetState($idBtnCheckPatched, $GUI_DISABLE)
			GUICtrlSetState($idBtnRefresh, $GUI_DISABLE)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnUpdateHosts, 128)
			GUICtrlSetState($idBtnCleanHosts, 128)
			GUICtrlSetState($idBtnEditHosts, 128)
			GUICtrlSetState($idBtnCreateFW, 128)
			GUICtrlSetState($idBtnToggleFW, 128)
			GUICtrlSetState($idBtnRemoveFW, 128)
			GUICtrlSetState($idBtnOpenWF, 128)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
			GUICtrlSetState($idBtnToggleWinTrust, 128)
			GUICtrlSetState($idBtnDevOverride, 128)
			GUICtrlSetState($idBtnRemoveAGS, 128)
			GUICtrlSetState($idBtnRestoreHosts, 128)
			GUICtrlSetState($idBtnAGSInfo, 128)
			GUICtrlSetState($idBtnFirewallInfo, 128)
			GUICtrlSetState($idBtnHostsInfo, 128)
			GUICtrlSetState($idBtnRuntimeInfo, 128)
			GUICtrlSetState($idBtnWintrustInfo, 128)
			GUICtrlSetState($idBtnDummyAGS, 128)
			GUICtrlSetState($idBtnSetTrustPath, 128)
			GUICtrlSetState($idFindACC, 128)
			GUICtrlSetState($idOnlyAFolders, 128)
			GUICtrlSetState($idShowBetaApps, 128)
			GUICtrlSetState($idEnableGood1, 128)
			GUICtrlSetState($idResetOnSave, 128)
			GUICtrlSetState($idReconcileStates, 128)
			GUICtrlSetState($idCreateStates, 128)
			GUICtrlSetState($idUseCustomDefault, 128)
			GUICtrlSetState($idBtnSetCustomPath, 128)
			GUICtrlSetState($idCustomDomainListInput, 128)
			GUICtrlSetState($idBtnSaveOptions, 128)
			_Expand_All_Click()

			Local $ItemFromList
			Local $iTotalChecked = 0, $iDone = 0
			Local $aRestoredPaths[0]
			Local $iFirstChecked = -1
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then
					$iTotalChecked += 1
					If $iFirstChecked = -1 Then $iFirstChecked = $i
				EndIf
			Next

			If $iFirstChecked >= 0 Then
				_GUICtrlListView_EnsureVisible($idListview, $iFirstChecked, 0)
			EndIf

			ProgressWrite(0)
			_SubProgressWrite(0)
			If $bEnableMD5 = 1 Then
				_Crypt_Startup()
				$g_bCryptActive = True
			EndIf

			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)

					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
					_ArrayAdd($aRestoredPaths, $ItemFromList)

					_GUICtrlListView_SetItemText($idListview, $i, "还原中...", 2)
					_SubProgressWrite(50)

					_GUICtrlListView_EnsureVisible($idListview, $i, 0)

					Local $bOk = RestoreFile($ItemFromList)

					If $bOk Then
						_GUICtrlListView_SetItemText($idListview, $i, "未修补", 2)
					Else
						_GUICtrlListView_SetItemText($idListview, $i, "无备份", 2)
					EndIf

					_SubProgressWrite(100)
					$iDone += 1
					If $iTotalChecked > 0 Then ProgressWrite(Round($iDone / $iTotalChecked * 100))

					MemoWrite(@CRLF & "路径" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "正在还原 :)")
					Sleep(50)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			If $g_bCryptActive Then
				_Crypt_Shutdown()
				$g_bCryptActive = False
			EndIf

			_CleanOrphanBaks($aRestoredPaths)

			_FlushStateQueue()

			ProgressWrite(0)
			_SubProgressWrite(0)

			$g_bIsPatching = False
			GUICtrlSetState($idFindACC, $GUI_ENABLE)
			GUICtrlSetState($idOnlyAFolders, $GUI_ENABLE)
			GUICtrlSetState($idEnableGood1, $GUI_ENABLE)
			GUICtrlSetState($idShowBetaApps, $GUI_ENABLE)
			GUICtrlSetState($idResetOnSave, $GUI_ENABLE)
			GUICtrlSetState($idReconcileStates, $GUI_ENABLE)
			GUICtrlSetState($idCreateStates, $GUI_ENABLE)
			GUICtrlSetState($idUseCustomDefault, $GUI_ENABLE)
			GUICtrlSetState($idBtnSetCustomPath, $GUI_ENABLE)
			GUICtrlSetState($idCustomDomainListInput, $GUI_ENABLE)
			CheckOptionsChanged()

			$g_bPendingInfoReset = True

			UpdateUIState()

			MemoWrite(@CRLF & "路径" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonSearch, 256)
			GUICtrlSetState($idBtnUpdateHosts, 64)
			GUICtrlSetState($idBtnCleanHosts, 64)
			GUICtrlSetState($idBtnEditHosts, 64)
			GUICtrlSetState($idBtnCreateFW, 64)
			GUICtrlSetState($idBtnToggleFW, 64)
			GUICtrlSetState($idBtnRemoveFW, 64)
			GUICtrlSetState($idBtnOpenWF, 64)
			GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
			GUICtrlSetState($idBtnToggleWinTrust, 64)
			GUICtrlSetState($idBtnDevOverride, 64)
			GUICtrlSetState($idBtnRemoveAGS, 64)
			GUICtrlSetState($idBtnRestoreHosts, 64)
			GUICtrlSetState($idBtnAGSInfo, 64)
			GUICtrlSetState($idBtnFirewallInfo, 64)
			GUICtrlSetState($idBtnHostsInfo, 64)
			GUICtrlSetState($idBtnRuntimeInfo, 64)
			GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)
			FillListViewWithInfo()

			ToggleLog(1)
			_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)

		Case $idMsg = $idBtnCopyLog
			SendToClipBoard()

		Case $idMsg = $idFindACC
			If _IsChecked($idFindACC) Then
				$bFindACC = 1
			Else
				$bFindACC = 0
			EndIf
			_ApplyVisibilityFilter()
			CheckOptionsChanged()

		Case $idMsg = $idOnlyAFolders
			If _IsChecked($idOnlyAFolders) Then
				$bOnlyAFolders = 1
			Else
				$bOnlyAFolders = 0
			EndIf
			If Not $g_bSearchCompleted Then FillListViewWithInfo()
			CheckOptionsChanged()

		Case $idMsg = $idShowBetaApps
			If _IsChecked($idShowBetaApps) Then
				$bShowBetaApps = 1
			Else
				$bShowBetaApps = 0
			EndIf
			_ApplyVisibilityFilter()
			CheckOptionsChanged()

		Case $idMsg = $idEnableGood1
			If _IsChecked($idEnableGood1) Then
				$bEnableGood1 = 1
			Else
				$bEnableGood1 = 0
			EndIf
			_ApplyVisibilityFilter()
			CheckOptionsChanged()

		Case $idMsg = $idResetOnSave
			CheckOptionsChanged()

		Case $idMsg = $idReconcileStates
			If _IsChecked($idReconcileStates) Then GUICtrlSetState($idCreateStates, $GUI_UNCHECKED)
			CheckOptionsChanged()

		Case $idMsg = $idCreateStates
			If _IsChecked($idCreateStates) Then GUICtrlSetState($idReconcileStates, $GUI_UNCHECKED)
			CheckOptionsChanged()

		Case $idMsg = $idUseCustomDefault
			If _IsChecked($idUseCustomDefault) Then
				Local $sSeedPick = GUICtrlRead($idBtnSetCustomPath)
				If $sSeedPick = "" Or Not FileExists($sSeedPick) Then $sSeedPick = $MyDefPath
				Local $sPickedPath = FileSelectFolder("选择程序启动时打开的文件夹", "", 7, $sSeedPick, $MyhGUI)
				If Not @error And $sPickedPath <> "" Then
					GUICtrlSetData($idBtnSetCustomPath, StringRegExpReplace($sPickedPath, "\\\\+", "\\"))
				EndIf
			EndIf
			CheckOptionsChanged()

		Case $idMsg = $idBtnSaveOptions
			SaveOptionsToConfig()

		Case $idMsg = $idBtnRemoveAGS
			RemoveAGS()

		Case $idMsg = $idBtnDummyAGS
			InstallAGSDummy()

		Case $idMsg = $idBtnSetTrustPath
			Local $sSelected = FileSelectFolder("选择用于 WinTrust 的 Adobe 安装文件夹", "", 7, $g_sWinTrustPath, $MyhGUI)
			If @error Then
				ContinueLoop
			EndIf
			If $sSelected = "" Then ContinueLoop
			$g_sWinTrustPath = $sSelected
			GUICtrlSetData($idLabelTrustPath, "路径: " & $g_sWinTrustPath)
			IniWrite($sINIPath, "Options", "WinTrustPath", $g_sWinTrustPath)
			_PinCustomDomainListURLLast()
			MemoWrite(@CRLF & "WinTrust 路径已设为: " & $g_sWinTrustPath)
			LogWrite(1, "WinTrust 路径已改为: " & $g_sWinTrustPath)

		Case $idMsg = $idBtnUpdateHosts
			ToggleLog(0)
			UpdateHostsFile()

		Case $idMsg = $idBtnCleanHosts
			RemoveHostsEntries()

		Case $idMsg = $idBtnEditHosts
			EditHosts()

		Case $idMsg = $idBtnRestoreHosts
			RestoreHosts()

		Case $idMsg = $idBtnCreateFW
			ToggleLog(0)
			CreateFirewallRules()

		Case $idMsg = $idBtnToggleFW
			ToggleLog(0)
			ShowToggleRulesGUI()

		Case $idMsg = $idBtnRemoveFW
			ToggleLog(0)
			RemoveFirewallRules()

		Case $idMsg = $idBtnOpenWF
			OpenWF()

		Case $idMsg = $idBtnToggleRuntimeInstaller

		Case $idMsg = $idBtnToggleWinTrust
			ToggleLog(0)
			ManageWinTrust()

		Case $idMsg = $idBtnDevOverride
			ToggleLog(0)
			ManageDevOverride()

		Case $idMsg = $idBtnAGSInfo
			ShowInfoPopup("移除 Adobe 正版服务及相关文件，用于移除标题为 '正版服务警告' 的弹窗。" & @CRLF & @CRLF & "对其他类型的正版弹窗无效。")

		Case $idMsg = $idBtnFirewallInfo
			ShowInfoPopup("通过 Windows 防火墙规则阻止 Adobe 软件联网来移除正版弹窗。可以一键为所有 Adobe 软件添加出站规则、切换开关、或删除所有规则。" & @CRLF & @CRLF & "软件被断网之后，部分功能可能会无法使用。")

		Case $idMsg = $idBtnHostsInfo
			ShowInfoPopup("在 hosts 文件中屏蔽与正版弹窗相关的域名。您可以选择从指定网址（在设置中可以修改）更新屏蔽条目、在记事本中手动编辑、移除所有屏蔽条目、恢复 hosts 备份。" & @CRLF & @CRLF & "请定期更新 Hosts 文件。")

		Case $idMsg = $idBtnWintrustInfo
			ShowInfoPopup("通过修改 WinTrust 绕过验证来移除正版弹窗。使用一个修改版 DLL + 注册表项来允许 DLL 重定向。可按需为每个软件进行修改/还原，以及添加/删除此注册表项。选择修改将会自动添加注册表项。" & @CRLF & @CRLF & "鸣谢 Team V.R！")
	EndSelect
WEnd

Func MainGui()
	$MyhGUI = GUICreate($g_AppWndTitle, 595, 580, -1, -1, BitOR($WS_MINIMIZEBOX, $GUI_SS_DEFAULT_GUI))
	$hTab = GUICtrlCreateTab(0, 1, 597, 580, $TCS_FIXEDWIDTH)
	_SendMessage(GUICtrlGetHandle($hTab), 0x1329, 0, 84)

	$hMainTab = GUICtrlCreateTabItem("主页")
	$idListview = GUICtrlCreateListView("", 10, 35, 575, 355)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$g_idListview = GUICtrlGetHandle($idListview)
	_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
	_GUICtrlListView_SetItemCount($idListview, UBound($FilesToPatch))
	_GUICtrlListView_AddColumn($idListview, "", 20)
	_GUICtrlListView_AddColumn($idListview, "  软件文件", 445, 2)
	_GUICtrlListView_AddColumn($idListview, "状态", 85, 2)

	_GUICtrlListView_EnableGroupView($idListview)
	_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)
	_GUICtrlListView_SetGroupInfo($idListview, 1, "", 1, $LVGS_COLLAPSIBLE)

	FillListViewWithInfo()

	$idBtnUncheckAll = GUICtrlCreateButton("取消全选", 28, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCheckAll = GUICtrlCreateButton("全选", 140, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCheckUnpatched = GUICtrlCreateButton("未修补", 251, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCheckPatched = GUICtrlCreateButton("已修补", 363, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRefresh = GUICtrlCreateButton("刷新", 475, 400, 94, 25)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCollapseAll = GUICtrlCreateDummy()
	$idBtnExpandAll   = GUICtrlCreateDummy()

	GUICtrlCreateLabel("", 9, 438, 577, 27, $SS_BLACKFRAME)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlCreateLabel("", 9, 462, 577, 7, $SS_BLACKFRAME)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idProgressBar = GUICtrlCreateProgress(10, 439, 575, 25, $PBS_SMOOTH)
	_WinAPI_SetWindowTheme(GUICtrlGetHandle($idProgressBar), "", "")
	GUICtrlSetColor($idProgressBar, 0x00FF00)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idSubProgress = GUICtrlCreateProgress(10, 463, 575, 5, $PBS_SMOOTH)
	_WinAPI_SetWindowTheme(GUICtrlGetHandle($idSubProgress), "", "")
	GUICtrlSetColor($idSubProgress, 0x00A2E8)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idButtonCustomFolder = GUICtrlCreateButton(" 路径", 28, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetImage(-1, "imageres.dll", -4, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonSearch = GUICtrlCreateButton(" 扫描", 140, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonStop = GUICtrlCreateButton(" 停止", 140, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCure = GUICtrlCreateButton(" 修补", 251, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetImage(-1, "imageres.dll", -102, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnModified = GUICtrlCreateButton(" 检查", 363, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetImage(-1, "imageres.dll", -25, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestore = GUICtrlCreateButton(" 还原", 475, 490, 94, 32)
	GUICtrlSetFont(-1, 10, 700)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetImage(-1, "imageres.dll", -113, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnDeselectAll = GUICtrlCreateDummy()

	$g_idHyperlinkMain = GUICtrlCreateLabel("GenP 维基与指南", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkMain, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkMain, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkMain, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkMain, 0)

	GUICtrlCreateTabItem("")

	$hOptionsTab = GUICtrlCreateTabItem("设置")

	GUICtrlCreateGroup("扫描设置", 5, 35, 585, 130)

	$idFindACC = GUICtrlCreateCheckbox("始终扫描 Creative Cloud", 15, 60, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bFindACC = 1 Then GUICtrlSetState($idFindACC, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableMD5 = GUICtrlCreateDummy()

	$idOnlyAFolders = GUICtrlCreateCheckbox("仅扫描名称含 Adobe/Acrobat 的文件夹", 15, 90, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bOnlyAFolders = 1 Then GUICtrlSetState($idOnlyAFolders, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idUseCustomDefault = GUICtrlCreateCheckbox("使用自定义默认扫描路径:", 15, 120, 175, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bUseCustomDefault = 1 Then GUICtrlSetState($idUseCustomDefault, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	Local $sInitialCustom = ($g_sPendingCustomPath <> "") ? $g_sPendingCustomPath : (@ProgramFilesDir & "\Adobe")
	$idBtnSetCustomPath = GUICtrlCreateLabel($sInitialCustom, 190, 125, 390, 20, $SS_LEFT)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlSetFont($idBtnSetCustomPath, 9, 400, 0, "Segoe UI")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("修补设置", 5, 175, 585, 130)

	$idShowBetaApps = GUICtrlCreateCheckbox("显示 Beta 版软件", 15, 200, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bShowBetaApps = 1 Then GUICtrlSetState($idShowBetaApps, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableGood1 = GUICtrlCreateCheckbox("启用 Good 修补", 15, 230, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bEnableGood1 = 1 Then GUICtrlSetState($idEnableGood1, $GUI_CHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idResetOnSave = GUICtrlCreateCheckbox("重置 patch_states.ini", 15, 260, 300, 25)
	GUICtrlSetState($idResetOnSave, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("Hosts 设置", 5, 315, 585, 55)

	$idCustomDomainListLabel = GUICtrlCreateLabel("Hosts 屏蔽列表地址:", 15, 340, 125, 20)
	$idCustomDomainListInput = GUICtrlCreateInput($sCurrentDomainListURL, 145, 337, 435, 22, BitOR($ES_LEFT, $ES_WANTRETURN, $ES_AUTOHSCROLL))
	GUICtrlSetLimit($idCustomDomainListInput, 255)
	GUICtrlSetResizing($idCustomDomainListInput, $GUI_DOCKWIDTH)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("初次运行设置", 5, 380, 585, 80)

	$idCreateStates = GUICtrlCreateCheckbox("新建 patch_states.ini (仅使用 '路径' 所设的位置)", 15, 401, 420, 22, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idCreateStates, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idReconcileStates = GUICtrlCreateCheckbox("同步导入的 patch_states.ini (仅使用 '路径' 所设的位置)", 15, 428, 420, 22, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	GUICtrlSetState($idReconcileStates, $GUI_UNCHECKED)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$idOptionsReminder = GUICtrlCreateLabel("保存后设置才会生效", 10, 470, 575, 20, $SS_CENTER)
	GUICtrlSetFont($idOptionsReminder, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($idOptionsReminder, 0xC62828)
	GUICtrlSetState($idOptionsReminder, $GUI_HIDE)

	$idBtnSaveOptions = GUICtrlCreateButton("保存设置", 247, 500, 110, 32)
	GUICtrlSetImage(-1, "imageres.dll", 5358, 0)
	GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkOptions = GUICtrlCreateLabel("GenP 维基与指南", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkOptions, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkOptions, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkOptions, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkOptions, 0)

	GUICtrlCreateTabItem("")

	Local $hWinTrustTab = GUICtrlCreateTabItem("WinTrust")

	$sWinTrustText = "WinTrust验证"
	$idLabelWinTrust = GUICtrlCreateLabel($sWinTrustText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelWinTrust, 10, 700)

	$idBtnToggleWinTrust = GUICtrlCreateButton("配置 WinTrust 修改", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnToggleWinTrust, 9, 400, 0, "Segoe UI")

	$idBtnDevOverride = GUICtrlCreateButton("配置注册表项修改", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnDevOverride, 9, 400, 0, "Segoe UI")

	$idBtnSetTrustPath = GUICtrlCreateButton("设置 WinTrust 路径", 227, 180, 140, 32)
	GUICtrlSetFont($idBtnSetTrustPath, 9, 400, 0, "Segoe UI")

	$idLabelTrustPath = GUICtrlCreateLabel("路径: " & $g_sWinTrustPath, 10, 225, 575, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelTrustPath, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($idLabelTrustPath, 0x555555)

	GUICtrlCreateLabel( _
			"对使用 DLL 重定向的软件进行 WinTrust 修改，可以减少弹窗." & @CRLF & @CRLF & _
			"程序会自动管理所需的注册表项." & @CRLF & @CRLF & _
			"可以随时修改或还原软件." & @CRLF & @CRLF & _
			"鸣谢 Team V.R.", _
			(595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnWintrustInfo           = GUICtrlCreateDummy()
	$idBtnRuntimeInfo            = GUICtrlCreateDummy()
	$idLabelRuntimeInstaller     = GUICtrlCreateDummy()
	$idBtnToggleRuntimeInstaller = GUICtrlCreateDummy()

	$g_idHyperlinkWT = GUICtrlCreateLabel("GenP 维基与指南", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkWT, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkWT, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkWT, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkWT, 0)

	GUICtrlCreateTabItem("")

	Local $hHostsTab = GUICtrlCreateTabItem("Hosts")

	$sEditHostsText = "Hosts"
	$idLabelEditHosts = GUICtrlCreateLabel($sEditHostsText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelEditHosts, 10, 700)

	$idBtnUpdateHosts = GUICtrlCreateButton("更新 hosts", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnUpdateHosts, 9, 400, 0, "Segoe UI")

	$idBtnEditHosts = GUICtrlCreateButton("编辑 hosts", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnEditHosts, 9, 400, 0, "Segoe UI")

	$idBtnCleanHosts = GUICtrlCreateButton("清理 hosts", 227, 180, 140, 32)
	GUICtrlSetFont($idBtnCleanHosts, 9, 400, 0, "Segoe UI")

	$idBtnRestoreHosts = GUICtrlCreateButton("还原 hosts", 227, 225, 140, 32)
	GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
	GUICtrlSetFont($idBtnRestoreHosts, 9, 400, 0, "Segoe UI")

	GUICtrlCreateLabel( _
			"管理 hosts 文件，屏蔽与弹窗有关的域名." & @CRLF & @CRLF & _
			"可从列表地址自动更新、手动编辑，或从备份还原 hosts 文件." & @CRLF & @CRLF & _
			"定期更新 hosts 文件，可保持屏蔽列表有效.", _
			(595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnHostsInfo = GUICtrlCreateDummy()

	$g_idHyperlinkHosts = GUICtrlCreateLabel("GenP 维基与指南", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkHosts, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkHosts, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkHosts, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkHosts, 0)

	GUICtrlCreateTabItem("")

	Local $hFirewallTab = GUICtrlCreateTabItem("防火墙")

	$sCleanFirewallText = "防火墙"
	$idLabelCleanFirewall = GUICtrlCreateLabel($sCleanFirewallText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelCleanFirewall, 10, 700)

	$idBtnCreateFW = GUICtrlCreateButton("添加规则", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnCreateFW, 9, 400, 0, "Segoe UI")

	$idBtnToggleFW = GUICtrlCreateButton("启用/禁用规则", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnToggleFW, 9, 400, 0, "Segoe UI")

	$idBtnRemoveFW = GUICtrlCreateButton("删除规则", 227, 180, 140, 32)
	GUICtrlSetFont($idBtnRemoveFW, 9, 400, 0, "Segoe UI")

	$idBtnOpenWF = GUICtrlCreateButton("打开防火墙控制台", 227, 225, 140, 32)
	GUICtrlSetFont($idBtnOpenWF, 9, 400, 0, "Segoe UI")

	GUICtrlCreateLabel( _
			"通过防火墙规则阻止软件联网，可以减少弹窗." & @CRLF & @CRLF & _
			"可添加或删除出站规则，也可启用、禁用或删除全部规则." & @CRLF & @CRLF & _
			"注意: 阻止联网后，部分软件功能可能无法使用.", _
			(595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnFirewallInfo = GUICtrlCreateDummy()

	$g_idHyperlinkFW = GUICtrlCreateLabel("GenP 维基与指南", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkFW, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkFW, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkFW, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkFW, 0)

	GUICtrlCreateTabItem("")

	$hPopupTab = GUICtrlCreateTabItem("AGS")

	$sRemoveAGSText = "正版服务"
	$idLabelRemoveAGS = GUICtrlCreateLabel($sRemoveAGSText, (595 - 580) / 2, 50, 580, 20, $SS_CENTER)
	GUICtrlSetFont($idLabelRemoveAGS, 10, 700)

	$idBtnRemoveAGS = GUICtrlCreateButton("删除 AGS", 227, 90, 140, 32)
	GUICtrlSetFont($idBtnRemoveAGS, 9, 400, 0, "Segoe UI")

	$idBtnDummyAGS = GUICtrlCreateButton("替换 AGS", 227, 135, 140, 32)
	GUICtrlSetFont($idBtnDummyAGS, 9, 400, 0, "Segoe UI")

	GUICtrlCreateLabel( _
			"删除 AGS 组件可停止 'Adobe Genuine Service Alert' 弹窗." & @CRLF & @CRLF & _
			"也可以用替代文件重定向相关服务，阻止后台运行." & @CRLF & @CRLF & _
			"注意: 此功能只处理标题为 'Genuine Service Alert' 的弹窗.", _
			(595 - 580) / 2, 320, 580, 110, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

	$idBtnAGSInfo = GUICtrlCreateDummy()

	$g_idHyperlinkAGS = GUICtrlCreateLabel("GenP 维基与指南", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkAGS, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkAGS, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkAGS, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkAGS, 0)
	$g_idHyperlinkPopup = $g_idHyperlinkAGS

	GUICtrlCreateTabItem("")

	$hLogTab = GUICtrlCreateTabItem("日志")
	$idMemo = GUICtrlCreateEdit("", 10, 35, 575, 442, BitOR($ES_READONLY, $ES_CENTER, $WS_DISABLED))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetLimit($idMemo, 0x7FFFFFFF)

	$idLog = GUICtrlCreateEdit("", 10, 35, 575, 442, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetLimit($idLog, 0x7FFFFFFF)
	GUICtrlSetState($idLog, $GUI_HIDE)
	GUICtrlSetData($idLog, "操作日志" & @CRLF & "- - - - - - - - - - -" & @CRLF & @CRLF & "GenP 版本: " & $g_Version & @CRLF & "配置版本: " & $ConfigVerVar & @CRLF)

	$idBtnCopyLog = GUICtrlCreateButton("复制", 247, 490, 110, 32)
	GUICtrlSetImage(-1, "imageres.dll", -77, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$g_idHyperlinkLog = GUICtrlCreateLabel("GenP 维基与指南", (595 - 160) / 2, 545, 160, 24, BitOR($SS_CENTER, $SS_NOTIFY))
	GUICtrlSetFont($g_idHyperlinkLog, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($g_idHyperlinkLog, 0x000000)
	GUICtrlSetBkColor($g_idHyperlinkLog, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetCursor($g_idHyperlinkLog, 0)

	GUICtrlCreateTabItem("")

	MemoWrite(@CRLF & "路径" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作.")

	GUICtrlSetState($idButtonSearch, 256)
	GUISetState(@SW_SHOW)

	GUIRegisterMsg($WM_COMMAND, "hL_WM_COMMAND")
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")

	_SnapshotOptions()
EndFunc

Func RecursiveFileSearch($INSTARTDIR, $DEPTH, $FileCount)
	Local $RecursiveFileSearch_MaxDeep = 8
	If $DEPTH > $RecursiveFileSearch_MaxDeep Then Return

	Local $STARTDIR = $INSTARTDIR & "\"
	$FileSearchedCount += 1

	Local $HSEARCH = FileFindFirstFile($STARTDIR & "*.*")
	If @error Then Return

	Local $NEXT, $IPATH, $isDir

	While $fInterrupt = 0
		$NEXT = FileFindNextFile($HSEARCH)
		$FileSearchedCount += 1

		If @error Then ExitLoop
		$isDir = StringInStr(FileGetAttrib($STARTDIR & $NEXT), "D")

		If $isDir Then
			Local $targetDepth
			$targetDepth = RecursiveFileSearch($STARTDIR & $NEXT, $DEPTH + 1, $FileCount)
		Else
			$IPATH = $STARTDIR & $NEXT
			Local $FileNameCropped, $PathToCheck
			If (IsArray($TargetFileList)) Then
				For $FileTarget In $TargetFileList
					$PathToCheck = ""
					If StringInStr($FileTarget, "|") Then
						Local $aFT = StringSplit($FileTarget, "|", $STR_ENTIRESPLIT)
						$PathToCheck = $aFT[2]
						$FileTarget = $aFT[1]
					ElseIf StringInStr($FileTarget, "$") Then
						Local $aFT = StringSplit($FileTarget, "$", $STR_ENTIRESPLIT)
						$PathToCheck = $aFT[2]
						$FileTarget = $aFT[1]
					EndIf
					$FileNameCropped = StringSplit(StringLower($IPATH), StringLower($FileTarget), $STR_ENTIRESPLIT)
					If @error <> 1 Then
						If Not StringInStr($IPATH, ".bak") And Not StringInStr(StringLower($IPATH), "wintrust") Then
							If (StringInStr($IPATH, "Adobe") Or StringInStr($IPATH, "Acrobat")) Or $bOnlyAFolders = 0 Then
								Local $bPathMatches = True
								If $PathToCheck <> "" Then
									If StringInStr($PathToCheck, "*") Then
										Local $sRegex = StringReplace($PathToCheck, "\", "\\")
										$sRegex = StringReplace($sRegex, ".", "\.")
										$sRegex = StringReplace($sRegex, "*", "[^\\]*")
										$bPathMatches = (StringRegExp($IPATH, "(?i)" & $sRegex) = 1)
									Else
										$bPathMatches = (StringInStr($IPATH, $PathToCheck) > 0)
									EndIf
								EndIf
								If $bPathMatches Then
									_StoreFileInMaster($IPATH)
								EndIf
							ElseIf StringInStr($IPATH, ".bak") Then
								_ArrayAdd($FilesToRestore, $IPATH)
							EndIf
						EndIf
					EndIf
				Next
			EndIf
		EndIf
	WEnd

	If 1 = Random(0, 10, 1) Then
		MemoWrite(@CRLF & "共 " & $FileCount & " 个文件" & @TAB & @TAB & "已找到: " & UBound($g_aAllFiles) & @CRLF & _
				"---" & @CRLF & _
				"深度: " & $DEPTH & " 用时: " & Round(TimerDiff($timestamp) / 1000, 0) & " 秒" & @TAB & @TAB & "排除 *.bak: " & UBound($FilesToRestore) & @CRLF & _
				"---" & @CRLF & _
				$INSTARTDIR _
				)
		ProgressWrite($ProgressFileCountScale * $FileSearchedCount)
		_ShowStatusScreen("scanning", $INSTARTDIR)
		_SubProgressWrite(Mod($g_dotCounter * 5, 101))
	EndIf

	FileClose($HSEARCH)
EndFunc

Func _StoreFileInMaster($sPath)
	For $k = 0 To UBound($g_aAllFiles) - 1
		If $g_aAllFiles[$k][0] = $sPath Then Return
	Next

	Local $sFileName = StringRegExpReplace($sPath, "^.*\\", "")
	Local $sFileNameLC = StringLower($sFileName)
	Local $sPathLC = StringLower($sPath)

	Local $bIsACC = StringInStr($sPathLC, "\common files\adobe\") > 0

	Local $bIsBeta = (StringInStr($sPath, "(Beta)") > 0) Or (StringInStr($sPath, " Beta\") > 0) Or (StringInStr($sPathLC, "\adobe animate beta") > 0)

	Local $bReqGood1 = (StringInStr($g_sRequiresGood1Files, "|" & $sFileNameLC & "|") > 0)

	Local $iIdx = UBound($g_aAllFiles)
	ReDim $g_aAllFiles[$iIdx + 1][5]
	$g_aAllFiles[$iIdx][0] = $sPath
	$g_aAllFiles[$iIdx][1] = $sFileName
	$g_aAllFiles[$iIdx][2] = $bIsACC
	$g_aAllFiles[$iIdx][3] = $bIsBeta
	$g_aAllFiles[$iIdx][4] = $bReqGood1

	_ArrayAdd($FilesToPatch, $sPath)

	_BumpScanCounters($sPath)
EndFunc

Func FillListViewWithInfo()
	$g_bStatusScreenReady = False
	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_RemoveAllGroups($g_idListview)
	_GUICtrlListView_EnableGroupView($g_idListview, False)

	_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER))

	While _GUICtrlListView_GetColumnCount($g_idListview) > 0
		_GUICtrlListView_DeleteColumn($g_idListview, 0)
	WEnd
	_GUICtrlListView_AddColumn($g_idListview, "", 0)
	_GUICtrlListView_AddColumn($g_idListview, "", 571, 2)

	Local $sTitle = "GenP v4.0.4", $sOptionsLine = ""
	If Number($bEnableGood1) Then $sOptionsLine &= "已启用 Good 修补"
	If Number($bShowBetaApps) Then
		$sOptionsLine &= ($sOptionsLine <> "" ? " / " : "") & "包含 Beta 版软件"
	EndIf

	Local $iTotalRows = 16
	If $sOptionsLine <> "" Then $iTotalRows += 1

	For $i = 0 To $iTotalRows - 1
		_GUICtrlListView_AddItem($g_idListview, "", $i)
	Next

	Local $line = 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "GenP", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "原版作者 uncia", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "--------------------", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, $sTitle, 1)
	$line += 1

	If $sOptionsLine <> "" Then
		_GUICtrlListView_SetItemText($g_idListview, $line, $sOptionsLine, 1)
		$line += 1
	EndIf

	_GUICtrlListView_SetItemText($g_idListview, $line, "--------------------", 1)
	$line += 2
	_GUICtrlListView_SetItemText($g_idListview, $line, "当前扫描路径:", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, $MyDefPath, 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "点击 '路径' 更改扫描位置", 1)

	$line += 2
	_GUICtrlListView_SetItemText($g_idListview, $line, "点击 '扫描' 扫描已安装的软件", 1)
	$line += 1
	_GUICtrlListView_SetItemText($g_idListview, $line, "点击 '修补' 修补所选文件", 1)

	Local $hHeader = _GUICtrlListView_GetHeader($g_idListview)
	_WinAPI_EnableWindow($hHeader, False)

	_WinAPI_RedrawWindow($g_idListview)

	$fFilesListed = 0
	UpdateUIState()
EndFunc

Func FillListViewWithFiles()
	$g_bStatusScreenReady = False
	While _GUICtrlListView_GetColumnCount($g_idListview) > 0
		_GUICtrlListView_DeleteColumn($g_idListview, 0)
	WEnd
	_GUICtrlListView_AddColumn($g_idListview, "", 20)
	_GUICtrlListView_AddColumn($g_idListview, "  软件文件                                                         全部折叠", 445, 0)
	_GUICtrlListView_AddColumn($g_idListview, "状态", 85, 2)
	_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
	_GUICtrlListView_EnableGroupView($g_idListview, True)

	Local $hHeader = _GUICtrlListView_GetHeader($g_idListview)
	_WinAPI_EnableWindow($hHeader, True)
	Local $iHdrStyle = _WinAPI_GetWindowLong($hHeader, $GWL_STYLE)
	_WinAPI_SetWindowLong($hHeader, $GWL_STYLE, BitOR($iHdrStyle, 0x0800))

	If UBound($g_aAllFiles) > 0 Then
		MemoWrite(@CRLF & "共找到 " & UBound($g_aAllFiles) & " 个文件，耗时 " & Round(TimerDiff($timestamp) / 1000, 0) & " 秒，扫描位置:" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "点击 '修补'")
		LogWrite(1, "共找到 " & UBound($g_aAllFiles) & " 个文件，耗时 " & Round(TimerDiff($timestamp) / 1000, 0) & " 秒" & @CRLF)
		$fFilesListed = 1
		$g_bSearchCompleted = True
		$g_mCheckedState.RemoveAll()
		_ApplyVisibilityFilter(True)
		_SyncWinTrustFromDisk()
		_RefreshGroupHeadersFromWT()
	Else
		MemoWrite(@CRLF & "找不到目标" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作")
		LogWrite(1, "找不到目标 " & $MyDefPath)
		$fFilesListed = 0
		$g_bSearchCompleted = False
		FillListViewWithInfo()
	EndIf
EndFunc

Func _ApplyVisibilityFilter($bInitial = False)
	If Not $g_bSearchCompleted Then
		FillListViewWithInfo()
		Return
	EndIf

	If Not $bInitial Then
		Local $iExistingCount = _GUICtrlListView_GetItemCount($idListview)
		For $i = 0 To $iExistingCount - 1
			Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
			If $sPath <> "" Then
				$g_mCheckedState.Item($sPath) = _GUICtrlListView_GetItemChecked($idListview, $i)
			EndIf
		Next
	EndIf

	ReDim $FilesToPatch[0][1]
	Local $aVisible[0][3]
	For $i = 0 To UBound($g_aAllFiles) - 1
		Local $sPath = $g_aAllFiles[$i][0]
		Local $bIsACC = $g_aAllFiles[$i][2]
		Local $bIsBeta = $g_aAllFiles[$i][3]
		Local $bReqGood1 = $g_aAllFiles[$i][4]

		If $bIsACC And $bFindACC = 0 Then ContinueLoop
		If $bIsBeta And $bShowBetaApps = 0 Then ContinueLoop
		If $bReqGood1 And $bEnableGood1 = 0 Then ContinueLoop

		Local $iV = UBound($aVisible)
		ReDim $aVisible[$iV + 1][3]
		$aVisible[$iV][0] = $iV
		$aVisible[$iV][1] = $sPath
		$aVisible[$iV][2] = FileExists($sPath & ".bak") ? "已修补" : "未修补"
		_ArrayAdd($FilesToPatch, $sPath)
	Next

	_SendMessageL($idListview, $WM_SETREDRAW, False, 0)
	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_RemoveAllGroups($idListview)
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))

	If UBound($aVisible) > 0 Then
		_GUICtrlListView_AddArray($idListview, $aVisible)
		_Assign_Groups_To_Found_Files()
		For $i = 0 To UBound($aVisible) - 1
			Local $sPath = $aVisible[$i][1]
			If $bInitial Then
				_GUICtrlListView_SetItemChecked($idListview, $i, True)
			Else
				If $g_mCheckedState.Exists($sPath) Then
					_GUICtrlListView_SetItemChecked($idListview, $i, $g_mCheckedState.Item($sPath))
				Else
					_GUICtrlListView_SetItemChecked($idListview, $i, True)
				EndIf
			EndIf
		Next
	Else
		_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)
		_GUICtrlListView_SetGroupInfo($idListview, 1, "当前筛选条件下没有文件", 1, $LVGS_COLLAPSIBLE)
	EndIf

	_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
	_RedrawWindow($idListview)
EndFunc

Func MemoWrite($sMessage)
	GUICtrlSetData($idMemo, $sMessage)
EndFunc

Func LogWrite($bTS, $sMessage)
	GUICtrlSetDataEx($idLog, $sMessage, $bTS)
EndFunc

Func ToggleLog($bShow)
	If $bShow = 1 Then
		GUICtrlSetState($idMemo, $GUI_HIDE)
		GUICtrlSetState($idLog, $GUI_SHOW)
	Else
		GUICtrlSetState($idLog, $GUI_HIDE)
		GUICtrlSetState($idMemo, $GUI_SHOW)
	EndIf
EndFunc

Func SendToClipBoard()
	If BitAND(GUICtrlGetState($idMemo), $GUI_HIDE) = $GUI_HIDE Then
		ClipPut(GUICtrlRead($idLog))
	Else
		ClipPut(GUICtrlRead($idMemo))
	EndIf
EndFunc

Func GUICtrlSetDataEx($hWnd, $sText, $bTS)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Local $iLength = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0x000E, "wparam", 0, "lparam", 0)
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xB1, "wparam", $iLength[0], "lparam", $iLength[0])
	If $bTS = 1 Then
		Local $iData = @CRLF & $sText
	Else
		Local $iData = $sText
	EndIf
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xC2, "wparam", True, "wstr", $iData)
EndFunc

Func ProgressWrite($msg_Progress)
	GUICtrlSetData($idProgressBar, $msg_Progress)
EndFunc

Func _SubProgressWrite($iPct)
	If $idSubProgress > 0 Then GUICtrlSetData($idSubProgress, $iPct)
EndFunc

Func _SnapshotOptions()
	If Not IsObj($g_mOptionsSnapshot) Then $g_mOptionsSnapshot = ObjCreate("Scripting.Dictionary")
	$g_mOptionsSnapshot.RemoveAll()
	$g_mOptionsSnapshot.Item("FindACC")            = _IsChecked($idFindACC)
	$g_mOptionsSnapshot.Item("EnableMD5")          = 1
	$g_mOptionsSnapshot.Item("OnlyDefaultFolders") = _IsChecked($idOnlyAFolders)
	$g_mOptionsSnapshot.Item("EnableGood1")        = _IsChecked($idEnableGood1)
	$g_mOptionsSnapshot.Item("ShowBetaApps")       = _IsChecked($idShowBetaApps)
	$g_mOptionsSnapshot.Item("ResetOnSave")        = _IsChecked($idResetOnSave)
	$g_mOptionsSnapshot.Item("ReconcileStates")    = _IsChecked($idReconcileStates)
	$g_mOptionsSnapshot.Item("CreateStates")       = _IsChecked($idCreateStates)
	$g_mOptionsSnapshot.Item("UseCustomDefault")   = _IsChecked($idUseCustomDefault)
	$g_mOptionsSnapshot.Item("PendingCustomPath")  = GUICtrlRead($idBtnSetCustomPath)
	$g_mOptionsSnapshot.Item("HostsURL")           = StringStripWS(GUICtrlRead($idCustomDomainListInput), 3)
	$g_bOptionsDirty = False
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	If $idOptionsReminder > 0 Then GUICtrlSetState($idOptionsReminder, $GUI_HIDE)
EndFunc

Func _ShowEmptyModifiedNotice()
	$g_bInModifiedMode = False
	$g_bStatusScreenReady = False
	_PrepStatusScreenLayout()

	_GUICtrlListView_SetItemText($g_idListview, 2, "所有文件均已修补.", 1)
	_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
	_GUICtrlListView_SetItemText($g_idListview, 4, "没有需要处理的变更.", 1)
	_GUICtrlListView_SetItemText($g_idListview, 6, "3 秒后返回主页...", 1)

	Sleep(3000)

	$fFilesListed = 0
	$g_bSearchCompleted = False
	ReDim $g_aAllFiles[0][5]
	$g_mCheckedState.RemoveAll()
	FillListViewWithInfo()
	UpdateUIState()
EndFunc

Func CheckOptionsChanged()
	If Not IsObj($g_mOptionsSnapshot) Then Return
	Local $bChanged = False
	If _IsChecked($idFindACC)       <> $g_mOptionsSnapshot.Item("FindACC")            Then $bChanged = True
	If _IsChecked($idOnlyAFolders)  <> $g_mOptionsSnapshot.Item("OnlyDefaultFolders") Then $bChanged = True
	If _IsChecked($idEnableGood1)   <> $g_mOptionsSnapshot.Item("EnableGood1")        Then $bChanged = True
	If _IsChecked($idShowBetaApps)  <> $g_mOptionsSnapshot.Item("ShowBetaApps")       Then $bChanged = True
	If _IsChecked($idResetOnSave)   <> $g_mOptionsSnapshot.Item("ResetOnSave")        Then $bChanged = True
	If _IsChecked($idReconcileStates) <> $g_mOptionsSnapshot.Item("ReconcileStates") Then $bChanged = True
	If _IsChecked($idCreateStates)    <> $g_mOptionsSnapshot.Item("CreateStates")    Then $bChanged = True
	If _IsChecked($idUseCustomDefault) <> $g_mOptionsSnapshot.Item("UseCustomDefault") Then $bChanged = True
	If GUICtrlRead($idBtnSetCustomPath) <> $g_mOptionsSnapshot.Item("PendingCustomPath") Then $bChanged = True
	If StringStripWS(GUICtrlRead($idCustomDomainListInput), 3) <> $g_mOptionsSnapshot.Item("HostsURL") Then $bChanged = True

	$g_bOptionsDirty = $bChanged
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $bChanged ? $GUI_ENABLE : $GUI_DISABLE)
	If $idOptionsReminder > 0 Then GUICtrlSetState($idOptionsReminder, $bChanged ? $GUI_SHOW : $GUI_HIDE)
EndFunc

Func _RestorePostOpUI()
	GUICtrlSetState($idListview, 64)
	GUICtrlSetState($idButtonSearch, 64)
	GUICtrlSetState($idButtonCustomFolder, 64)
	GUICtrlSetState($idBtnUpdateHosts, 64)
	GUICtrlSetState($idBtnCleanHosts, 64)
	GUICtrlSetState($idBtnEditHosts, 64)
	GUICtrlSetState($idBtnCreateFW, 64)
	GUICtrlSetState($idBtnToggleFW, 64)
	GUICtrlSetState($idBtnRemoveFW, 64)
	GUICtrlSetState($idBtnOpenWF, 64)
	GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
	GUICtrlSetState($idBtnToggleWinTrust, 64)
	GUICtrlSetState($idBtnDevOverride, 64)
	GUICtrlSetState($idBtnRemoveAGS, 64)
	GUICtrlSetState($idBtnRestoreHosts, 64)
	GUICtrlSetState($idBtnAGSInfo, 64)
	GUICtrlSetState($idBtnFirewallInfo, 64)
	GUICtrlSetState($idBtnHostsInfo, 64)
	GUICtrlSetState($idBtnRuntimeInfo, 64)
	GUICtrlSetState($idBtnWintrustInfo, 64)
	GUICtrlSetState($idBtnDummyAGS, 64)
	GUICtrlSetState($idBtnSetTrustPath, 64)
	GUICtrlSetState($idFindACC, 64)
	GUICtrlSetState($idOnlyAFolders, 64)
	GUICtrlSetState($idShowBetaApps, 64)
	GUICtrlSetState($idEnableGood1, 64)
	GUICtrlSetState($idResetOnSave, 64)
	GUICtrlSetState($idReconcileStates, 64)
	GUICtrlSetState($idCreateStates, 64)
	GUICtrlSetState($idUseCustomDefault, 64)
	GUICtrlSetState($idBtnSetCustomPath, 64)
	GUICtrlSetState($idCustomDomainListInput, 64)
EndFunc

Func _ApplyModifiedFilter()
	Local $iRemoved = 0, $iKept = 0
	Local $iRow = _GUICtrlListView_GetItemCount($g_idListview) - 1
	_SendMessageL($g_idListview, $WM_SETREDRAW, False, 0)
	While $iRow >= 0
		Local $sStatus = _GUICtrlListView_GetItemText($g_idListview, $iRow, 2)
		If $sStatus = "已修补" Then
			_GUICtrlListView_DeleteItem($g_idListview, $iRow)
			$iRemoved += 1
		Else
			_GUICtrlListView_SetItemChecked($g_idListview, $iRow, 1)
			$iKept += 1
		EndIf
		$iRow -= 1
	WEnd
	_SendMessageL($g_idListview, $WM_SETREDRAW, True, 0)
	_RedrawWindow($g_idListview)

	MemoWrite(@CRLF & "变更检查: " & $iKept & " 个文件需要修补，已隐藏 " & $iRemoved & " 个已修补文件.")
	LogWrite(1, "变更检查: 待修补 " & $iKept & " 个，已修补 " & $iRemoved & " 个.")

	If $iKept > 0 Then $g_bInModifiedMode = True
	Return $iKept
EndFunc

Func _LockOptionsUIForScan()
	If $idOptionsReminder > 0 Then
		GUICtrlSetData($idOptionsReminder, "正在扫描所设路径，请稍候...")
		GUICtrlSetState($idOptionsReminder, $GUI_SHOW)
	EndIf
	$g_bIsPatching = True
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, 128)
	GUICtrlSetState($idFindACC, 128)
	GUICtrlSetState($idOnlyAFolders, 128)
	GUICtrlSetState($idShowBetaApps, 128)
	GUICtrlSetState($idEnableGood1, 128)
	GUICtrlSetState($idResetOnSave, 128)
	GUICtrlSetState($idReconcileStates, 128)
	GUICtrlSetState($idCreateStates, 128)
	GUICtrlSetState($idUseCustomDefault, 128)
	GUICtrlSetState($idBtnSetCustomPath, 128)
	GUICtrlSetState($idCustomDomainListInput, 128)
	GUICtrlSetState($idButtonCustomFolder, 128)
	GUICtrlSetState($idButtonSearch, 128)
	GUICtrlSetState($idBtnCure, 128)
	GUICtrlSetState($idBtnRestore, 128)
	GUICtrlSetState($idBtnModified, 128)
	GUICtrlSetState($idBtnCheckAll, 128)
	GUICtrlSetState($idBtnUncheckAll, 128)
	GUICtrlSetState($idBtnCheckUnpatched, 128)
	GUICtrlSetState($idBtnCheckPatched, 128)
	GUICtrlSetState($idBtnRefresh, 128)
	GUICtrlSetState($idBtnUpdateHosts, 128)
	GUICtrlSetState($idBtnCleanHosts, 128)
	GUICtrlSetState($idBtnEditHosts, 128)
	GUICtrlSetState($idBtnRestoreHosts, 128)
	GUICtrlSetState($idBtnCreateFW, 128)
	GUICtrlSetState($idBtnToggleFW, 128)
	GUICtrlSetState($idBtnRemoveFW, 128)
	GUICtrlSetState($idBtnOpenWF, 128)
	GUICtrlSetState($idBtnToggleRuntimeInstaller, 128)
	GUICtrlSetState($idBtnToggleWinTrust, 128)
	GUICtrlSetState($idBtnDevOverride, 128)
	GUICtrlSetState($idBtnSetTrustPath, 128)
	GUICtrlSetState($idBtnRemoveAGS, 128)
	GUICtrlSetState($idBtnDummyAGS, 128)
	GUICtrlSetState($idBtnAGSInfo, 128)
	GUICtrlSetState($idBtnFirewallInfo, 128)
	GUICtrlSetState($idBtnHostsInfo, 128)
	GUICtrlSetState($idBtnRuntimeInfo, 128)
	GUICtrlSetState($idBtnWintrustInfo, 128)
EndFunc

Func _UnlockOptionsUIAfterScan()
	If $idOptionsReminder > 0 Then
		GUICtrlSetData($idOptionsReminder, "保存后设置才会生效")
		GUICtrlSetState($idOptionsReminder, $GUI_HIDE)
	EndIf
	$g_bIsPatching = False
	GUICtrlSetState($idFindACC, 64)
	GUICtrlSetState($idOnlyAFolders, 64)
	GUICtrlSetState($idShowBetaApps, 64)
	GUICtrlSetState($idEnableGood1, 64)
	GUICtrlSetState($idResetOnSave, 64)
	GUICtrlSetState($idReconcileStates, 64)
	GUICtrlSetState($idCreateStates, 64)
	GUICtrlSetState($idUseCustomDefault, 64)
	GUICtrlSetState($idBtnSetCustomPath, 64)
	GUICtrlSetState($idCustomDomainListInput, 64)
	GUICtrlSetState($idButtonCustomFolder, 64)
	GUICtrlSetState($idButtonSearch, 64)
	GUICtrlSetState($idBtnModified, 64)
	GUICtrlSetState($idBtnUpdateHosts, 64)
	GUICtrlSetState($idBtnCleanHosts, 64)
	GUICtrlSetState($idBtnEditHosts, 64)
	GUICtrlSetState($idBtnRestoreHosts, 64)
	GUICtrlSetState($idBtnCreateFW, 64)
	GUICtrlSetState($idBtnToggleFW, 64)
	GUICtrlSetState($idBtnRemoveFW, 64)
	GUICtrlSetState($idBtnOpenWF, 64)
	GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
	GUICtrlSetState($idBtnToggleWinTrust, 64)
	GUICtrlSetState($idBtnDevOverride, 64)
	GUICtrlSetState($idBtnSetTrustPath, 64)
	GUICtrlSetState($idBtnRemoveAGS, 64)
	GUICtrlSetState($idBtnDummyAGS, 64)
	GUICtrlSetState($idBtnAGSInfo, 64)
	GUICtrlSetState($idBtnFirewallInfo, 64)
	GUICtrlSetState($idBtnHostsInfo, 64)
	GUICtrlSetState($idBtnRuntimeInfo, 64)
	GUICtrlSetState($idBtnWintrustInfo, 64)
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)
	$fFilesListed = 0
	$g_bSearchCompleted = False
	ReDim $g_aAllFiles[0][5]
	$g_mCheckedState.RemoveAll()
	FillListViewWithInfo()
	UpdateUIState()
EndFunc

Func UpdateUIState()
	Local $bHasFiles = ($g_bSearchCompleted And _GUICtrlListView_GetItemCount($g_idListview) > 0)
	Local $iEnable   = $bHasFiles ? $GUI_ENABLE : $GUI_DISABLE

	If $idBtnCheckAll       > 0 Then GUICtrlSetState($idBtnCheckAll,       $iEnable)
	If $idBtnUncheckAll     > 0 Then GUICtrlSetState($idBtnUncheckAll,     $iEnable)
	If $idBtnCheckUnpatched > 0 Then GUICtrlSetState($idBtnCheckUnpatched, $iEnable)
	If $idBtnCheckPatched         > 0 Then GUICtrlSetState($idBtnCheckPatched,         $iEnable)
	If $idBtnRefresh        > 0 Then GUICtrlSetState($idBtnRefresh,        $iEnable)

	If $idBtnCure     > 0 Then GUICtrlSetState($idBtnCure,     $iEnable)
	If $idBtnRestore  > 0 Then GUICtrlSetState($idBtnRestore,  $iEnable)
	If $idBtnModified > 0 And Not $g_bIsPatching Then GUICtrlSetState($idBtnModified, $GUI_ENABLE)
EndFunc

Func _VerifyListedFiles($bSilent = False)
	Local $iCount = _GUICtrlListView_GetItemCount($idListview)
	If $iCount = 0 Then
		If Not $bSilent Then MemoWrite(@CRLF & "没有需要核验的文件.")
		Return
	EndIf

	If Not $bSilent Then
		ToggleLog(0)
		MemoWrite(@CRLF & "正在根据 patch_states.ini 核验 " & $iCount & " 个文件...")
	EndIf
	LogWrite(1, "开始核验 " & $iCount & " 个文件.")

	Local $mPatched  = ObjCreate("Scripting.Dictionary")
	Local $mOriginal = ObjCreate("Scripting.Dictionary")
	Local $aSecP = IniReadSection($patchStatesINI, "MD5_Patched")
	Local $aSecO = IniReadSection($patchStatesINI, "MD5_Original")
	If IsArray($aSecP) Then
		For $k = 1 To $aSecP[0][0]
			$mPatched.Item(StringLower($aSecP[$k][0])) = StringLower($aSecP[$k][1])
		Next
	EndIf
	If IsArray($aSecO) Then
		For $k = 1 To $aSecO[0][0]
			$mOriginal.Item(StringLower($aSecO[$k][0])) = StringLower($aSecO[$k][1])
		Next
	EndIf

	Local $bWeStartedCrypt = False
	If Not $g_bCryptActive Then
		_Crypt_Startup()
		$g_bCryptActive = True
		$bWeStartedCrypt = True
	EndIf
	ProgressWrite(0)
	_SubProgressWrite(0)

	Local $iDone = 0, $iPatched = 0, $iUnpatched = 0, $iModified = 0, $iUnknown = 0, $iMissing = 0

	For $i = 0 To $iCount - 1
		Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
		Local $sDisplayStatus = "未修补"

		If Not FileExists($sPath) Then
			$iMissing += 1
		Else
			If Not $bSilent Then _GUICtrlListView_SetItemText($idListview, $i, "核验中...", 2)
			_SubProgressWrite(50)
			Local $sMD5 = StringLower(StringTrimLeft(String(_Crypt_HashFile($sPath, $CALG_MD5)), 2))
			Local $sKey = StringLower($sPath)

			If $mPatched.Exists($sKey) And $mPatched.Item($sKey) = $sMD5 Then
				$sDisplayStatus = "已修补"
				$iPatched += 1
			ElseIf $mOriginal.Exists($sKey) And $mOriginal.Item($sKey) = $sMD5 Then
				$sDisplayStatus = "未修补"
				$iUnpatched += 1
			ElseIf $mPatched.Exists($sKey) Or $mOriginal.Exists($sKey) Then
				$iModified += 1
			Else
				$iUnknown += 1
			EndIf
		EndIf

		_GUICtrlListView_SetItemText($idListview, $i, $sDisplayStatus, 2)
		$iDone += 1
		ProgressWrite(Round($iDone / $iCount * 100))
		_SubProgressWrite(100)
	Next

	If $bWeStartedCrypt Then
		_Crypt_Shutdown()
		$g_bCryptActive = False
	EndIf

	ProgressWrite(0)
	_SubProgressWrite(0)

	Local $iUnpatchedSum = $iUnpatched + $iModified
	Local $sSummary = "核验完成: 已修补 " & $iPatched & " 个，未修补 " & $iUnpatchedSum & " 个，未知 " & _
			$iUnknown & " 个，缺失 " & $iMissing & " 个."
	If Not $bSilent Then MemoWrite(@CRLF & $sSummary)
	LogWrite(1, $sSummary)
	LogWrite(1, "")
	If Not $bSilent Then ToggleLog(1)
EndFunc

Func _RefreshSearch()
	_ResetScanCounters()
	_ShowStatusScreen("scanning", $MyDefPath)
	MemoWrite(@CRLF & "刷新: 正在重新扫描 " & $MyDefPath)

	$FilesToPatch = $FilesToPatchNull
	$FilesToRestore = $FilesToPatchNull
	ReDim $g_aAllFiles[0][5]
	$g_bSearchCompleted = False
	$g_mCheckedState.RemoveAll()

	$timestamp = TimerInit()

	Local $FileCount
	If $bFindACC = 1 Then
		Local $aACCDirs[2]
		$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
		$aACCDirs[1] = EnvGet('ProgramFiles')      & "\Common Files\Adobe"
		For $sAppsPanelDir In $aACCDirs
			If Not FileExists($sAppsPanelDir) Then ContinueLoop
			Local $aSize = DirGetSize($sAppsPanelDir, $DIR_EXTENDED)
			If UBound($aSize) >= 2 Then
				$FileCount = $aSize[1]
				RecursiveFileSearch($sAppsPanelDir, 0, $FileCount)
				ProgressWrite(0)
			EndIf
		Next
	EndIf

	Local $aSize = DirGetSize($MyDefPath, $DIR_EXTENDED)
	If UBound($aSize) >= 2 Then
		$FileCount = $aSize[1]
		$ProgressFileCountScale = 100 / $FileCount
		$FileSearchedCount = 0
		ProgressWrite(0)
		RecursiveFileSearch($MyDefPath, 0, $FileCount)
		ProgressWrite(0)
	EndIf

	_ShowStatusScreen("complete", $MyDefPath)
	Sleep(3000)
	FillListViewWithFiles()

	_VerifyListedFiles(True)

	UpdateUIState()
EndFunc

Func _ShowStatusScreen($sMode, $sDir = "")
	If Not $g_bStatusScreenReady Then
		_PrepStatusScreenLayout()
		$g_bStatusScreenReady = True
	EndIf

	_SendMessageL($g_idListview, $WM_SETREDRAW, False, 0)

	Local $sDisplayDir = _PrettifyScanDir($sDir)

	Switch $sMode
		Case "scanning"
			_GUICtrlListView_SetItemText($g_idListview, 1, "正在扫描已安装的软件:", 1)
			_GUICtrlListView_SetItemText($g_idListview, 2, "正在检查: " & $sDisplayDir, 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 4, "已找到软件: " & $g_AppCount, 1)
			_GUICtrlListView_SetItemText($g_idListview, 5, "可修补文件: " & _FormatNumber($g_FilesToPatchCount), 1)
			_GUICtrlListView_SetItemText($g_idListview, 6, "", 1)
			_GUICtrlListView_SetItemText($g_idListview, 7, "请稍候", 1)
			_GUICtrlListView_SetItemText($g_idListview, 8, _AnimatedDotsOnly(), 1)

		Case "complete"
			_GUICtrlListView_SetItemText($g_idListview, 1, "正在扫描已安装的软件:", 1)
			_GUICtrlListView_SetItemText($g_idListview, 2, "扫描完成.", 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 4, "已找到软件: " & $g_AppCount, 1)
			_GUICtrlListView_SetItemText($g_idListview, 5, "可修补文件: " & _FormatNumber($g_FilesToPatchCount), 1)
			_GUICtrlListView_SetItemText($g_idListview, 6, "", 1)
			_GUICtrlListView_SetItemText($g_idListview, 7, "正在加载找到的软件...", 1)
			_GUICtrlListView_SetItemText($g_idListview, 8, "", 1)

		Case "stopped"
			_GUICtrlListView_SetItemText($g_idListview, 1, "正在扫描已安装的软件:", 1)
			_GUICtrlListView_SetItemText($g_idListview, 2, "扫描已由用户停止.", 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 4, "已找到软件: " & $g_AppCount, 1)
			_GUICtrlListView_SetItemText($g_idListview, 5, "可修补文件: " & _FormatNumber($g_FilesToPatchCount), 1)
			_GUICtrlListView_SetItemText($g_idListview, 6, "", 1)
			If $sDir <> "" Then
				_GUICtrlListView_SetItemText($g_idListview, 7, "最后扫描的文件夹: " & $sDir, 1)
			Else
				_GUICtrlListView_SetItemText($g_idListview, 7, "", 1)
			EndIf
			_GUICtrlListView_SetItemText($g_idListview, 8, "", 1)

		Case "patching"
			_GUICtrlListView_SetItemText($g_idListview, 1, "正在修补文件...", 1)
			_GUICtrlListView_SetItemText($g_idListview, 3, "--------------------", 1)
			_GUICtrlListView_SetItemText($g_idListview, 7, "请稍候", 1)
			_GUICtrlListView_SetItemText($g_idListview, 8, _AnimatedDotsOnly(), 1)

		Case Else
			MemoWrite(@CRLF & $sMode & @CRLF & "---" & @CRLF & $sDir)
	EndSwitch

	_SendMessageL($g_idListview, $WM_SETREDRAW, True, 0)
	_RedrawWindow($g_idListview)

	If $sMode = "complete" Or $sMode = "stopped" Then
		MemoWrite(@CRLF & "扫描" & ($sMode = "complete" ? "完成" : "已停止") & ": 找到 " & $g_AppCount & " 个软件、" & _FormatNumber($g_FilesToPatchCount) & " 个文件.")
	EndIf
EndFunc

Func _PrepStatusScreenLayout()
	_SendMessageL($g_idListview, $WM_SETREDRAW, False, 0)

	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_RemoveAllGroups($g_idListview)
	_GUICtrlListView_EnableGroupView($g_idListview, False)
	_GUICtrlListView_SetExtendedListViewStyle($g_idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER))

	While _GUICtrlListView_GetColumnCount($g_idListview) > 0
		_GUICtrlListView_DeleteColumn($g_idListview, 0)
	WEnd
	_GUICtrlListView_AddColumn($g_idListview, "", 0)
	_GUICtrlListView_AddColumn($g_idListview, "", 571, 2)

	Local $hHeader = _GUICtrlListView_GetHeader($g_idListview)
	_WinAPI_EnableWindow($hHeader, False)

	For $i = 0 To 9
		_GUICtrlListView_AddItem($g_idListview, "", $i)
	Next

	_SendMessageL($g_idListview, $WM_SETREDRAW, True, 0)
	_RedrawWindow($g_idListview)
EndFunc

Func _PrettifyScanDir($sDir)
	If $sDir = "" Then Return "..."
	If StringRegExp($sDir, "(?i)Adobe Desktop Common|AppsPanel|AdobeGCClient|Common Files\\Adobe|ACC\\") Then
		Return "Creative Cloud"
	EndIf
	If StringInStr($sDir, "Acrobat") Then Return "Acrobat Pro"
	If StringInStr($sDir, "Elements 2026 Organizer") Then Return "Elements 2026 Organizer"
	Local $aMatch = StringRegExp($sDir, "(?i)\\Adobe\\([^\\]+)", 1)
	If Not @error Then
		Local $sLabel = StringRegExpReplace($aMatch[0], "(?i)^Adobe\s+", "")
		If StringInStr($sDir, "Beta") And Not StringInStr($sLabel, "Beta") Then
			$sLabel = StringStripWS($sLabel, 3) & " (Beta)"
		EndIf
		Return $sLabel
	EndIf
	Local $sLeaf = StringRegExpReplace($sDir, "^.*\\", "")
	Return ($sLeaf <> "") ? $sLeaf : $sDir
EndFunc

Func _AnimatedDots($sText)
	Local $iStep = Mod(Int($g_dotCounter / 3), 3)
	Local $iDots = $iStep + 1
	Local $iPad = 3 - $iDots
	Local $sDots = "", $sLead = ""
	For $k = 1 To $iDots
		$sDots &= "."
	Next
	For $k = 1 To $iPad
		$sLead &= " "
	Next
	$g_dotCounter += 1
	Return $sLead & $sText & $sDots
EndFunc

Func _AnimatedDotsOnly()
	Local $iStep = Mod(Int($g_dotCounter / 3), 3)
	Local $iDots = $iStep + 1
	Local $sOut = ""
	For $k = 1 To $iDots
		$sOut &= "."
	Next
	For $k = 1 To (3 - $iDots)
		$sOut &= " "
	Next
	$g_dotCounter += 1
	Return $sOut
EndFunc

Func _FormatNumber($iN)
	Local $s = String($iN)
	Local $sOut = "", $iLen = StringLen($s), $iPos = 0
	For $i = $iLen To 1 Step -1
		$sOut = StringMid($s, $i, 1) & $sOut
		$iPos += 1
		If Mod($iPos, 3) = 0 And $i > 1 Then $sOut = "," & $sOut
	Next
	Return $sOut
EndFunc

Func _ResetScanCounters()
	$g_AppCount = 0
	$g_FilesToPatchCount = 0
	$g_dotCounter = 0
	If Not IsObj($g_mScannedApps) Then $g_mScannedApps = ObjCreate("Scripting.Dictionary")
	$g_mScannedApps.RemoveAll()
	$g_sLastScanDir = ""
EndFunc

Func _BumpScanCounters($sFilePath)
	$g_FilesToPatchCount += 1
	Local $sApp = _GetAppGroupName($sFilePath)
	If $sApp <> "" And Not $g_mScannedApps.Exists($sApp) Then
		$g_mScannedApps.Item($sApp) = 1
		$g_AppCount += 1
	EndIf
	$g_sLastScanDir = $sFilePath
EndFunc

Func _HideStatusScreen()
EndFunc

Func _UpdateStatusDetail($sDetail)
	_ShowStatusScreen("scanning", $sDetail)
EndFunc

Func MyFileOpenDialog()
	Local Const $sMessage = "请选择路径"

	Local $MyTempPath = FileSelectFolder($sMessage, $MyDefPath, 0, $MyDefPath, $MyhGUI)

	If @error Then
		MemoWrite(@CRLF & "路径" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "等待用户操作")

	Else
		GUICtrlSetState($idBtnCure, 128)
		$MyDefPath = $MyTempPath
		IniWrite($sINIPath, "Default", "Path", $MyDefPath)

		FillListViewWithInfo()

		MemoWrite(@CRLF & "路径" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "点击扫描按钮")
		GUICtrlSetState($idBtnUpdateHosts, 64)
		GUICtrlSetState($idBtnCleanHosts, 64)
		GUICtrlSetState($idBtnEditHosts, 64)
		GUICtrlSetState($idBtnCreateFW, 64)
		GUICtrlSetState($idBtnToggleFW, 64)
		GUICtrlSetState($idBtnRemoveFW, 64)
		GUICtrlSetState($idBtnOpenWF, 64)
		GUICtrlSetState($idBtnToggleRuntimeInstaller, 64)
		GUICtrlSetState($idBtnToggleWinTrust, 64)
		GUICtrlSetState($idBtnDevOverride, 64)
		GUICtrlSetState($idBtnRemoveAGS, 64)
		GUICtrlSetState($idBtnRestoreHosts, 64)
		GUICtrlSetState($idBtnRestore, 128)
		GUICtrlSetState($idBtnAGSInfo, 64)
		GUICtrlSetState($idBtnFirewallInfo, 64)
		GUICtrlSetState($idBtnHostsInfo, 64)
		GUICtrlSetState($idBtnRuntimeInfo, 64)
		GUICtrlSetState($idBtnWintrustInfo, 64)
			GUICtrlSetState($idBtnDummyAGS, 64)
			GUICtrlSetState($idBtnSetTrustPath, 64)
			GUICtrlSetState($idFindACC, 64)
			GUICtrlSetState($idOnlyAFolders, 64)
			GUICtrlSetState($idShowBetaApps, 64)
			GUICtrlSetState($idEnableGood1, 64)
			GUICtrlSetState($idResetOnSave, 64)
			GUICtrlSetState($idReconcileStates, 64)
			GUICtrlSetState($idCreateStates, 64)
			GUICtrlSetState($idUseCustomDefault, 64)
			GUICtrlSetState($idBtnSetCustomPath, 64)
			GUICtrlSetState($idCustomDomainListInput, 64)
			GUICtrlSetState($idBtnSaveOptions, 64)
		$fFilesListed = 0

	EndIf

EndFunc

Func _ProcessCloseEx($sName)
	Local $iPID = Run("TASKKILL /F /T /IM " & $sName, @TempDir, @SW_HIDE)
	ProcessWaitClose($iPID)
EndFunc

Func MyGlobalPatternSearch($MyFileToParse)
	$aInHexArray = $aNullArray
	$aOutHexGlobalArray = $aNullArray
	$g_bUxpHandledFile = False
	_SubProgressWrite(0)
	$MyRegExpGlobalPatternSearchCount = 0
	$Count = 15
	Local $sFileName = StringRegExpReplace($MyFileToParse, "^.*\\", "")
	Local $sExt = StringRegExpReplace($sFileName, "^.*\.", "")
	Local $sLogSuffix = " - 使用默认/自定义特征"
	MemoWrite(@CRLF & $MyFileToParse & @CRLF & "---" & @CRLF & "分析中" & @CRLF & "---" & @CRLF & "*****")
	LogWrite(1, "正在检查文件: " & $sFileName & $sLogSuffix)
	If StringLower($sFileName) = "runtimeinstaller.dll" Then
		If Not _AutoUnpackIfRuntimeInstaller($MyFileToParse) Then
			MemoWrite(@CRLF & $MyFileToParse & @CRLF & "---" & @CRLF & "解除 UPX 保护失败，已跳过该文件." & @CRLF)
			Return
		EndIf
	EndIf
	If StringRegExp(StringLower($sExt), "^(js|json)$") Then
		Local $iUxpResult = _PatchAdobeUXPComponent($MyFileToParse)
		If $iUxpResult = 1 Then
			LogWrite(1, $MyFileToParse)
			LogWrite(1, "文件已由 GenP " & $g_Version & " + 配置 " & $ConfigVerVar & " 修补")
			If $bEnableMD5 = 1 And $g_bCryptActive Then
				Local $sUxpMD5 = StringTrimLeft(String(_Crypt_HashFile($MyFileToParse, $CALG_MD5)), 2)
				LogWrite(1, "MD5 校验值: " & $sUxpMD5 & @CRLF)
			EndIf
			$g_bUxpHandledFile = True
			Return
		ElseIf $iUxpResult = 2 Then
			LogWrite(1, $MyFileToParse)
			LogWrite(1, "文件已经由 GenP 修补." & @CRLF)
			$g_bUxpHandledFile = True
			Return
		EndIf
	EndIf
	If $sExt = "exe" Then
		_ProcessCloseEx("""" & $sFileName & """")
	EndIf
	If $sFileName = "Adobe Desktop Service.exe" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		Sleep(100)
	EndIf
	If $sFileName = "AppsPanelBL.dll" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		_ProcessCloseEx("""Adobe Desktop Service.exe""")
		Sleep(100)
	EndIf
	If $sFileName = "HDPIM.dll" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		_ProcessCloseEx("""Adobe Desktop Service.exe""")
		Sleep(100)
	EndIf
	If StringInStr($sSpecialFiles, $sFileName) Then
		ExecuteSearchPatterns($sFileName, 0, $MyFileToParse)
	Else
		ExecuteSearchPatterns($sFileName, 1, $MyFileToParse)
	EndIf
	Sleep(100)
EndFunc

Func ExecuteSearchPatterns($FileName, $DefaultPatterns, $MyFileToParse)

	Local $aPatterns, $sPattern, $sData, $aArray, $sSearch, $sReplace, $iPatternLength

	If $DefaultPatterns = 0 Then
		$aPatterns = IniReadArray($sINIPath, "CustomPatterns", $FileName, "")
	Else
		$aPatterns = IniReadArray($sINIPath, "DefaultPatterns", "Values", "")
	EndIf

	For $i = 0 To UBound($aPatterns) - 1
		$sPattern = StringStripWS($aPatterns[$i], 3)
		If $bEnableGood1 = 0 And StringLower($sPattern) = "good1" Then
			ContinueLoop
		EndIf
		$sData = IniRead($sINIPath, "Patches", $sPattern, "")
		If StringInStr($sData, "|") Then
			$aArray = StringSplit($sData, "|")
			If UBound($aArray) = 3 Then

				$sSearch = StringReplace($aArray[1], '"', '')
				$sReplace = StringReplace($aArray[2], '"', '')

				$iPatternLength = StringLen($sSearch)
				If $iPatternLength <> StringLen($sReplace) Or Mod($iPatternLength, 2) <> 0 Then
					MsgBox($MB_SYSTEMMODAL, "错误", "配置文件 config.ini 中的特征有误:" & $sPattern & @CRLF & $sSearch & @CRLF & $sReplace)
					Exit
				EndIf

				MyRegExpGlobalPatternSearch($MyFileToParse, $sSearch, $sReplace, $sPattern)

			EndIf
		EndIf

	Next

EndFunc

Func MyRegExpGlobalPatternSearch($FileToParse, $PatternToSearch, $PatternToReplace, $PatternName)
	Local $hFileOpen = FileOpen($FileToParse, $FO_READ + $FO_BINARY)

	Local $sExtLower = StringLower(StringRegExpReplace($FileToParse, "^.*\.", ""))
	Local $bSkipPECheck = ($sExtLower = "js" Or $sExtLower = "json" Or $sExtLower = "rpln")

	If Not $bSkipPECheck Then
		FileSetPos($hFileOpen, 60, 0)

		$sz_type = FileRead($hFileOpen, 4)
		FileSetPos($hFileOpen, Number($sz_type) + 4, 0)

		$sz_type = FileRead($hFileOpen, 2)
	Else
		$sz_type = "0x0000"
	EndIf

	If $sz_type = "0x4C01" And StringInStr($FileToParse, "Acrobat", 2) > 0 Then

		MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "程序文件为 32 位，终止操作..." & @CRLF & "---")
		FileClose($hFileOpen)
		Sleep(100)
		$bFoundAcro32 = True

	ElseIf $sz_type = "0x64AA" Then
		MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "程序文件为 ARM 架构，终止操作..." & @CRLF & "---")
		FileClose($hFileOpen)
		Sleep(100)
		$bFoundGenericARM = True

	Else

		FileSetPos($hFileOpen, 0, 0)

		Local $sFileRead = FileRead($hFileOpen)

		Local $GeneQuestionMark, $AnyNumOfBytes, $OutStringForRegExp
		For $i = 256 To 1 Step -2
			$GeneQuestionMark = _StringRepeat("??", $i / 2)
			$AnyNumOfBytes = "(.{" & $i & "})"
			$OutStringForRegExp = StringReplace($PatternToSearch, $GeneQuestionMark, $AnyNumOfBytes)
			$PatternToSearch = $OutStringForRegExp
		Next

		Local $sSearchPattern = $OutStringForRegExp
		Local $aReplacePattern = $PatternToReplace
		Local $sWildcardSearchPattern = "", $sWildcardReplacePattern = "", $sFinalReplacePattern = ""
		Local $aInHexTempArray[0]
		Local $sSearchCharacter = "", $sReplaceCharacter = ""

		$aInHexTempArray = $aNullArray
		$aInHexTempArray = StringRegExp($sFileRead, $sSearchPattern, $STR_REGEXPARRAYGLOBALFULLMATCH, 1)

		For $i = 0 To UBound($aInHexTempArray) - 1

			$aInHexArray = $aNullArray
			$sSearchCharacter = ""
			$sReplaceCharacter = ""
			$sWildcardSearchPattern = ""
			$sWildcardReplacePattern = ""
			$sFinalReplacePattern = ""


			$aInHexArray = $aInHexTempArray[$i]

			If @error = 0 Then
				$sWildcardSearchPattern = $aInHexArray[0]
				$sWildcardReplacePattern = $aReplacePattern

				If StringInStr($sWildcardReplacePattern, "?") Then
					For $j = 1 To StringLen($sWildcardReplacePattern) + 1
						$sSearchCharacter = StringMid($sWildcardSearchPattern, $j, 1)
						$sReplaceCharacter = StringMid($sWildcardReplacePattern, $j, 1)

						If $sReplaceCharacter <> "?" Then
							$sFinalReplacePattern &= $sReplaceCharacter
						Else
							$sFinalReplacePattern &= $sSearchCharacter
						EndIf

					Next
				Else
					$sFinalReplacePattern = $sWildcardReplacePattern
				EndIf

				_ArrayAdd($aOutHexGlobalArray, $sWildcardSearchPattern)
				_ArrayAdd($aOutHexGlobalArray, $sFinalReplacePattern)

				ConsoleWrite($PatternName & "---" & @TAB & $sWildcardSearchPattern & "	" & @CRLF)
				ConsoleWrite($PatternName & "R" & "--" & @TAB & $sFinalReplacePattern & "	" & @CRLF)
				MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & $PatternName & @CRLF & "---" & @CRLF & $sWildcardSearchPattern & @CRLF & $sFinalReplacePattern)
				LogWrite(1, $PatternName & ": 替换为: " & $sFinalReplacePattern)

			Else
				ConsoleWrite($PatternName & "---" & @TAB & "无" & "	" & @CRLF)
				MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & $PatternName & "---" & "无")
			EndIf
			$MyRegExpGlobalPatternSearchCount += 1

		Next
		FileClose($hFileOpen)
		$sFileRead = ""
		_SubProgressWrite(Round($MyRegExpGlobalPatternSearchCount / $Count * 50))
		Sleep(100)

	EndIf

EndFunc

Func _FileInitSync($sTargetFile)
	If Not FileExists($sTargetFile) Then Return False
	Local $sExt = StringLower(StringRegExpReplace($sTargetFile, "^.*\.", ""))
	If Not StringRegExp($sExt, "^(exe|dll)$") Then Return True

	Local $hFile = FileOpen($sTargetFile, 17)
	If $hFile = -1 Then Return False

	Local $sBuf = StringRegExpReplace($g_Version & "." & _NowCalc(), "\D", "")
	$sBuf = StringLeft($sBuf, 11)

	FileSetPos($hFile, 0, 2)
	FileWrite($hFile, Binary("0xAE" & _InternalXCore($sBuf) & "00"))
	FileClose($hFile)
	Return True
EndFunc

Func _InternalXCore($sVal)
	Local $a = StringToASCIIArray($sVal), $r = ""
	For $i = 0 To UBound($a) - 1
		$r &= Hex($a[$i], 2)
	Next
	Return $r
EndFunc

Func MyGlobalPatternPatch($MyFileToPatch, $MyArrayToPatch)
	_SubProgressWrite(50)
	Local $iRows = UBound($MyArrayToPatch)
	If $iRows > 0 Then
		MemoWrite(@CRLF & "路径" & @CRLF & "---" & @CRLF & $MyFileToPatch & @CRLF & "---" & @CRLF & "开始用药 :)")
		Local $iPrePatchSize = FileGetSize($MyFileToPatch)
		Local $hFileOpen = FileOpen($MyFileToPatch, $FO_READ + $FO_BINARY)
		Local $sFileRead = FileRead($hFileOpen)
		Local $sStringOut = $sFileRead

		Local $sMD5Orig = ""
		If $bEnableMD5 = 1 And $g_bCryptActive Then
			$sMD5Orig = StringTrimLeft(String(_Crypt_HashData($sFileRead, $CALG_MD5)), 2)
		EndIf

		For $i = 0 To $iRows - 1 Step 2
			$sStringOut = StringReplace($sFileRead, $MyArrayToPatch[$i], $MyArrayToPatch[$i + 1], 0, 1)
			$sFileRead = $sStringOut
			_SubProgressWrite(50 + Round(($i + 2) / $iRows * 50))
		Next

		FileClose($hFileOpen)

		Local $sBak = $MyFileToPatch & ".bak"
		If FileExists($sBak) Then
			Local $sBakMD5 = ""
			If $bEnableMD5 = 1 And $g_bCryptActive Then
				$sBakMD5 = StringTrimLeft(String(_Crypt_HashFile($sBak, $CALG_MD5)), 2)
			EndIf
			If $sBakMD5 <> "" And $sBakMD5 <> $sMD5Orig Then
				FileDelete($sBak)
				FileMove($MyFileToPatch, $sBak)
				FileSetTime($sBak, "", $FT_MODIFIED)
			Else
				FileDelete($MyFileToPatch)
			EndIf
		Else
			FileMove($MyFileToPatch, $sBak)
			FileSetTime($sBak, "", $FT_MODIFIED)
		EndIf

		Local $hFileOpen1 = FileOpen($MyFileToPatch, $FO_OVERWRITE + $FO_BINARY)
		Local $bPatchedData = Binary($sStringOut)
		FileWrite($hFileOpen1, $bPatchedData)
		FileClose($hFileOpen1)
		_SubProgressWrite(100)
		Sleep(100)

		LogWrite(1, "文件已由 GenP " & $g_Version & " + 配置 " & $ConfigVerVar & " 修补")

		_FileInitSync($MyFileToPatch)

		Local $sMD5Patched = ""
		If $bEnableMD5 = 1 And $g_bCryptActive Then
			$sMD5Patched = StringTrimLeft(String(_Crypt_HashFile($MyFileToPatch, $CALG_MD5)), 2)
			LogWrite(1, "MD5 校验值: " & $sMD5Patched & @CRLF)
		EndIf

		_QueueStateWrite($MyFileToPatch, _GetAppGroupName($MyFileToPatch), $sMD5Orig, $sMD5Patched, "Patched")

	Else
		If Not $g_bUxpHandledFile Then
			MemoWrite(@CRLF & "找不到特征" & @CRLF & "---" & @CRLF & "或者" & @CRLF & "---" & @CRLF & "文件已经修补过了.")
			Sleep(100)
			LogWrite(1, "找不到特征或文件已经修补过了." & @CRLF)

			Local $sBakCheck = $MyFileToPatch & ".bak"
			If $bEnableMD5 = 1 And $g_bCryptActive And FileExists($sBakCheck) Then
				Local $sBakMD5Now = StringTrimLeft(String(_Crypt_HashFile($sBakCheck, $CALG_MD5)), 2)
				Local $sLiveMD5Now = StringTrimLeft(String(_Crypt_HashFile($MyFileToPatch, $CALG_MD5)), 2)
				If $sBakMD5Now <> "" And $sLiveMD5Now <> "" And $sBakMD5Now <> $sLiveMD5Now Then
					LogWrite(1, "检测到文件已经修补 (当前 MD5 与 .bak 的 MD5 不同)，已在 patch_states.ini 中记为已修补.")
					_QueueStateWrite($MyFileToPatch, _GetAppGroupName($MyFileToPatch), $sBakMD5Now, $sLiveMD5Now, "Patched")
				EndIf
			EndIf
		EndIf
	EndIf
EndFunc

Func RestoreFile($MyFileToDelete)
	If FileExists($MyFileToDelete & ".bak") Then
		Local $sFileName = StringRegExpReplace($MyFileToDelete, "^.*\\", "")
		If StringLower($sFileName) = "appspanelbl.dll" Or StringLower($sFileName) = "adobe desktop service.exe" Then
			_ProcessCloseEx("""Creative Cloud.exe""")
			_ProcessCloseEx("""Adobe Desktop Service.exe""")
			Sleep(100)
		EndIf
		FileDelete($MyFileToDelete)
		FileMove($MyFileToDelete & ".bak", $MyFileToDelete, $FC_OVERWRITE)
		Sleep(100)
		MemoWrite(@CRLF & "文件已还原" & @CRLF & "---" & @CRLF & $MyFileToDelete)
		LogWrite(1, $MyFileToDelete)
		LogWrite(1, "文件已还原.")

		Local $sMD5 = ""
		If $bEnableMD5 = 1 And $g_bCryptActive Then
			$sMD5 = StringTrimLeft(String(_Crypt_HashFile($MyFileToDelete, $CALG_MD5)), 2)
		EndIf
		_QueueStateWrite($MyFileToDelete, _GetAppGroupName($MyFileToDelete), $sMD5, "", "Unpatched")
		Return True
	Else
		Sleep(100)
		MemoWrite(@CRLF & "未找到备份文件" & @CRLF & "---" & @CRLF & $MyFileToDelete)
		LogWrite(1, $MyFileToDelete)
		LogWrite(1, "未找到备份文件.")
		Return False
	EndIf
EndFunc

Func _QueueStateWrite($sPath, $sApp, $sMD5Orig, $sMD5Patched, $sStatus)
	Local $iIdx = UBound($g_aStateQueue)
	ReDim $g_aStateQueue[$iIdx + 1][5]
	$g_aStateQueue[$iIdx][0] = $sPath
	$g_aStateQueue[$iIdx][1] = $sApp
	$g_aStateQueue[$iIdx][2] = $sMD5Orig
	$g_aStateQueue[$iIdx][3] = $sMD5Patched
	$g_aStateQueue[$iIdx][4] = $sStatus

	If $sApp <> "" And $sStatus = "Patched" Then
		If Not $g_mAppPrimaryExe.Exists($sApp) Then
			If StringRight(StringLower($sPath), 4) = ".exe" Then
				$g_mAppPrimaryExe.Item($sApp) = $sPath
			EndIf
		Else
			If StringRight(StringLower($sPath), 4) = ".exe" Then
				Local $sCurrentExe = StringLower(StringRegExpReplace($g_mAppPrimaryExe.Item($sApp), "^.*\\", ""))
				Local $sNewExe = StringLower(StringRegExpReplace($sPath, "^.*\\", ""))
				If StringInStr(StringLower($sApp), StringTrimRight($sNewExe, 4)) And _
				   Not StringInStr(StringLower($sApp), StringTrimRight($sCurrentExe, 4)) Then
					$g_mAppPrimaryExe.Item($sApp) = $sPath
				EndIf
			EndIf
		EndIf

		If Not $g_mWinTrustQueue.Exists($sApp) Then
			Local $sFolder = StringRegExpReplace($sPath, "\\[^\\]+$", "")
			If FileExists($sFolder & "\wintrust.dll") Then
				$g_mWinTrustQueue.Item($sApp) = "1"
			Else
				$g_mWinTrustQueue.Item($sApp) = "0"
			EndIf
		ElseIf $g_mWinTrustQueue.Item($sApp) = "0" Then
			Local $sFolder = StringRegExpReplace($sPath, "\\[^\\]+$", "")
			If FileExists($sFolder & "\wintrust.dll") Then
				$g_mWinTrustQueue.Item($sApp) = "1"
			EndIf
		EndIf
	EndIf
EndFunc

Func _RecordDevOverrideStateToLedger()
	Local $sRegKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $iRegVal = RegRead($sRegKey, "DevOverrideEnable")
	Local $sLedgerVal = (Not @error And $iRegVal = 1) ? "1" : "0"
	IniWrite($patchStatesINI, "Info", "DevOverrideEnable", $sLedgerVal)
EndFunc

Func _PinCustomDomainListURLLast()
    Local $sLastURL = IniRead($sINIPath, "Options", "CustomDomainListURL", $sDefaultDomainListURL)
    IniDelete($sINIPath, "Options", "CustomDomainListURL")
    IniWrite($sINIPath, "Options", "CustomDomainListURL", $sLastURL)
EndFunc

Func _FlushStateQueue()
	Local $iN = UBound($g_aStateQueue)
	If $iN = 0 And $g_mAppPrimaryExe.Count = 0 Then Return

	Local $aSecStatus   = IniReadSection($patchStatesINI, "Patch_Status")
	Local $aSecOrig     = IniReadSection($patchStatesINI, "MD5_Original")
	Local $aSecPatch    = IniReadSection($patchStatesINI, "MD5_Patched")
	Local $aSecAppFiles = IniReadSection($patchStatesINI, "App_File")
	Local $aSecAppVer   = IniReadSection($patchStatesINI, "App_Version")
	Local $aSecWinTrust = IniReadSection($patchStatesINI, "WinTrust_Local")

	Local $mStatus   = ObjCreate("Scripting.Dictionary")
	Local $mOrig     = ObjCreate("Scripting.Dictionary")
	Local $mPatch    = ObjCreate("Scripting.Dictionary")
	Local $mAppFiles = ObjCreate("Scripting.Dictionary")
	Local $mAppVer   = ObjCreate("Scripting.Dictionary")
	Local $mWT       = ObjCreate("Scripting.Dictionary")

	If IsArray($aSecStatus) Then
		For $k = 1 To $aSecStatus[0][0]
			$mStatus.Item($aSecStatus[$k][0]) = $aSecStatus[$k][1]
		Next
	EndIf
	If IsArray($aSecOrig) Then
		For $k = 1 To $aSecOrig[0][0]
			$mOrig.Item($aSecOrig[$k][0]) = $aSecOrig[$k][1]
		Next
	EndIf
	If IsArray($aSecPatch) Then
		For $k = 1 To $aSecPatch[0][0]
			$mPatch.Item($aSecPatch[$k][0]) = $aSecPatch[$k][1]
		Next
	EndIf
	If IsArray($aSecAppFiles) Then
		For $k = 1 To $aSecAppFiles[0][0]
			Local $sKey = $aSecAppFiles[$k][0]
			Local $sVal = $aSecAppFiles[$k][1]
			If StringInStr($sKey, "\") Or StringRegExp($sKey, "^[A-Za-z]:") Then
				If Not $mAppFiles.Exists($sVal) Then
					$mAppFiles.Item($sVal) = $sKey
				ElseIf Not StringInStr(";" & $mAppFiles.Item($sVal) & ";", ";" & $sKey & ";") Then
					$mAppFiles.Item($sVal) = $mAppFiles.Item($sVal) & ";" & $sKey
				EndIf
			Else
				If Not $mAppFiles.Exists($sKey) Then
					$mAppFiles.Item($sKey) = $sVal
				Else
					Local $sExisting = $mAppFiles.Item($sKey)
					Local $aNewPaths = StringSplit($sVal, ";", 2)
					For $sP In $aNewPaths
						If $sP = "" Then ContinueLoop
						If Not StringInStr(";" & $sExisting & ";", ";" & $sP & ";") Then
							$sExisting = $sExisting & ";" & $sP
						EndIf
					Next
					$mAppFiles.Item($sKey) = $sExisting
				EndIf
			EndIf
		Next
	EndIf
	If IsArray($aSecAppVer) Then
		For $k = 1 To $aSecAppVer[0][0]
			$mAppVer.Item($aSecAppVer[$k][0]) = $aSecAppVer[$k][1]
		Next
	EndIf
	If IsArray($aSecWinTrust) Then
		For $k = 1 To $aSecWinTrust[0][0]
			$mWT.Item($aSecWinTrust[$k][0]) = $aSecWinTrust[$k][1]
		Next
	EndIf

	For $i = 0 To $iN - 1
		Local $sPath = $g_aStateQueue[$i][0]
		Local $sApp  = $g_aStateQueue[$i][1]
		$mStatus.Item($sPath) = $g_aStateQueue[$i][4]
		If $g_aStateQueue[$i][2] <> "" Then $mOrig.Item($sPath)  = $g_aStateQueue[$i][2]
		If $g_aStateQueue[$i][3] <> "" Then $mPatch.Item($sPath) = $g_aStateQueue[$i][3]
		If $sApp <> "" Then
			If Not $mAppFiles.Exists($sApp) Then
				$mAppFiles.Item($sApp) = $sPath
			ElseIf Not StringInStr(";" & $mAppFiles.Item($sApp) & ";", ";" & $sPath & ";") Then
				$mAppFiles.Item($sApp) = $mAppFiles.Item($sApp) & ";" & $sPath
			EndIf
		EndIf
	Next

	For $sApp In $mAppFiles.Keys()
		Local $sExe = ""

		Local $sFirstFile = $mAppFiles.Item($sApp)
		Local $iSepIdx = StringInStr($sFirstFile, ";")
		If $iSepIdx > 0 Then $sFirstFile = StringLeft($sFirstFile, $iSepIdx - 1)
		Local $sAppRoot = StringRegExpReplace($sFirstFile, "(?i)^(.+\\Adobe\\[^\\]+\\).*$", "$1")
		If $sAppRoot = $sFirstFile Then $sAppRoot = ""

		If $sAppRoot <> "" Then
			$sExe = _FindLauncherExe($sAppRoot, $sApp)
		EndIf

		If $sExe = "" Or Not FileExists($sExe) Then
			If $g_mAppPrimaryExe.Exists($sApp) Then
				$sExe = $g_mAppPrimaryExe.Item($sApp)
			EndIf
		EndIf

		If $sExe = "" Or Not FileExists($sExe) Then ContinueLoop

		Local $sVer = FileGetVersion($sExe)
		If @error Or $sVer = "" Then
			$sVer = FileGetVersion($sExe, $FV_PRODUCTVERSION)
		EndIf
		If $sVer = "" Then $sVer = "unknown"
		$mAppVer.Item($sApp) = "v" & $sVer
	Next

	For $sApp In $g_mWinTrustQueue.Keys()
		$mWT.Item($sApp) = $g_mWinTrustQueue.Item($sApp)
	Next

	_WriteSectionFromMap("Patch_Status",   $mStatus)
	_WriteSectionFromMap("MD5_Original",  $mOrig)
	_WriteSectionFromMap("MD5_Patched",   $mPatch)
	_WriteSectionFromMap("App_File",      $mAppFiles)
	_WriteSectionFromMap("App_Version",   $mAppVer)
	_WriteSectionFromMap("WinTrust_Local", $mWT)

	IniWrite($patchStatesINI, "Info", "GenPVersion",   $g_Version)
	IniWrite($patchStatesINI, "Info", "ConfigVersion", $ConfigVerVar)
	IniWrite($patchStatesINI, "Info", "LastRun",       @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC)
	_RecordDevOverrideStateToLedger()

	_MaintainInisAlphebeticalWithSpacing($patchStatesINI)

	ReDim $g_aStateQueue[0][5]
	$g_mAppPrimaryExe.RemoveAll()
	$g_mWinTrustQueue.RemoveAll()
	$g_mAppVersionQueue.RemoveAll()
EndFunc

Func _ReconcilePatchStates()
	Local $aResult[4] = [0, 0, 0, 0]

	If Not FileExists($patchStatesINI) Then
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "同步修补状态", "没有 patch_states.ini，无需同步.")
		Return $aResult
	EndIf

	_LockOptionsUIForScan()

	ToggleLog(0)
	MemoWrite(@CRLF & "正在根据当前安装内容同步 patch_states.ini...")
	LogWrite(1, "同步修补状态: 正在扫描 " & $MyDefPath)

	Local $aOrigSec  = IniReadSection($patchStatesINI, "MD5_Original")
	Local $aPatchSec = IniReadSection($patchStatesINI, "MD5_Patched")
	Local $aStatSec  = IniReadSection($patchStatesINI, "Patch_Status")
	Local $mOrig    = ObjCreate("Scripting.Dictionary")
	Local $mPatch   = ObjCreate("Scripting.Dictionary")
	Local $mStatus  = ObjCreate("Scripting.Dictionary")
	If IsArray($aOrigSec) Then
		For $k = 1 To $aOrigSec[0][0]
			$mOrig.Item($aOrigSec[$k][0]) = $aOrigSec[$k][1]
		Next
	EndIf
	If IsArray($aPatchSec) Then
		For $k = 1 To $aPatchSec[0][0]
			$mPatch.Item($aPatchSec[$k][0]) = $aPatchSec[$k][1]
		Next
	EndIf
	If IsArray($aStatSec) Then
		For $k = 1 To $aStatSec[0][0]
			$mStatus.Item($aStatSec[$k][0]) = $aStatSec[$k][1]
		Next
	EndIf
	$aResult[3] = $mStatus.Count

	Local $mIniSeen = ObjCreate("Scripting.Dictionary")

	_ResetScanCounters()
	$g_aAllFiles = $aNullArray
	ReDim $g_aAllFiles[0][5]
	$FileSearchedCount = 0
	If $bFindACC = 1 Then
		Local $aACCDirs[2]
		$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
		$aACCDirs[1] = EnvGet('ProgramFiles')      & "\Common Files\Adobe"
		For $sAccDir In $aACCDirs
			If FileExists($sAccDir) Then RecursiveFileSearch($sAccDir, 0, 0)
		Next
	EndIf
	RecursiveFileSearch($MyDefPath, 0, 0)

	Local $iTotal = UBound($g_aAllFiles, 1)
	If $iTotal = 0 Then
		LogWrite(1, "同步修补状态: 在 " & $MyDefPath & " 中找不到可处理的文件.")
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "同步修补状态", "在 " & $MyDefPath & " 中找不到可处理的文件，同步已取消.")
		_UnlockOptionsUIAfterScan()
		Return $aResult
	EndIf

	LogWrite(1, "同步修补状态: 磁盘中找到 " & $iTotal & " 个文件，INI 中有 " & $aResult[3] & " 条记录.")

	Local $bWeStartedCrypt = False
	If Not $g_bCryptActive Then
		_Crypt_Startup()
		$g_bCryptActive = True
		$bWeStartedCrypt = True
	EndIf

	Local $mRemovePaths = ObjCreate("Scripting.Dictionary")
	Local $mStatusChanges = ObjCreate("Scripting.Dictionary")
	Local $mNewEntries = ObjCreate("Scripting.Dictionary")

	For $i = 0 To $iTotal - 1
		Local $sPath = $g_aAllFiles[$i][0]
		If Not FileExists($sPath) Then ContinueLoop

		If Mod($i, 10) = 0 Then
			ProgressWrite(Round(($i + 1) / $iTotal * 100))
			_ShowStatusScreen("patching", "正在同步: " & StringRegExpReplace($sPath, "^.*\\", ""))
		EndIf

		Local $sCurMD5 = StringLower(StringTrimLeft(String(_Crypt_HashFile($sPath, $CALG_MD5)), 2))
		If $sCurMD5 = "" Then ContinueLoop

		If $mStatus.Exists($sPath) Then
			$mIniSeen.Item($sPath) = 1
			Local $sStat = $mStatus.Item($sPath)
			Local $sP = $mPatch.Exists($sPath) ? StringLower($mPatch.Item($sPath)) : ""
			Local $sO = $mOrig.Exists($sPath)  ? StringLower($mOrig.Item($sPath))  : ""

			If $sStat = "Patched" Then
				If $sP <> "" And $sCurMD5 = $sP Then
					$aResult[2] += 1
				ElseIf $sO <> "" And $sCurMD5 = $sO Then
					$mStatusChanges.Item($sPath) = "Unpatched"
					$aResult[1] += 1
					LogWrite(1, "  状态变化 已修补->未修补: " & $sPath)
				Else
					$mRemovePaths.Item($sPath) = 1
					$aResult[1] += 1
					LogWrite(1, "  文件已在外部修改: " & $sPath)
				EndIf
			Else
				If $sO <> "" And $sCurMD5 = $sO Then
					$aResult[2] += 1
				ElseIf $sP <> "" And $sCurMD5 = $sP Then
					$mStatusChanges.Item($sPath) = "Patched"
					$aResult[1] += 1
					LogWrite(1, "  状态变化 未修补->已修补: " & $sPath)
				Else
					$mRemovePaths.Item($sPath) = 1
					$aResult[1] += 1
					LogWrite(1, "  文件已在外部修改: " & $sPath)
				EndIf
			EndIf
		Else
			$mNewEntries.Item($sPath) = $sCurMD5
		EndIf
	Next

	For $sIniPath In $mStatus.Keys()
		If Not $mIniSeen.Exists($sIniPath) Then
			$mRemovePaths.Item($sIniPath) = 1
			$aResult[0] += 1
			LogWrite(1, "  文件缺失: " & $sIniPath)
		EndIf
	Next

	If $bWeStartedCrypt Then
		_Crypt_Shutdown()
		$g_bCryptActive = False
	EndIf

	Local $iNew = $mNewEntries.Count
	If $mRemovePaths.Count > 0 Or $mStatusChanges.Count > 0 Or $iNew > 0 Then
		Local $aSections[5] = ["Patch_Status", "MD5_Original", "MD5_Patched", "App_File", "WinTrust_Local"]
		For $sSec In $aSections
			For $sPath In $mRemovePaths.Keys()
				IniDelete($patchStatesINI, $sSec, $sPath)
			Next
		Next
		For $sPath In $mStatusChanges.Keys()
			IniWrite($patchStatesINI, "Patch_Status", $sPath, $mStatusChanges.Item($sPath))
		Next
		For $sPath In $mNewEntries.Keys()
			IniWrite($patchStatesINI, "Patch_Status", $sPath, "Unpatched")
			IniWrite($patchStatesINI, "MD5_Original", $sPath, $mNewEntries.Item($sPath))
		Next

		_MaintainInisAlphebeticalWithSpacing($patchStatesINI)
	EndIf

	ProgressWrite(0)
	_ShowStatusScreen("complete", $MyDefPath)
	Sleep(1500)
	$g_bStatusScreenReady = False

	Local $sSummary = "同步完成." & @CRLF & @CRLF & _
			"磁盘中的文件:       " & $iTotal & @CRLF & _
			"INI 状态记录:       " & $aResult[3] & @CRLF & _
			"状态正确:           " & $aResult[2] & @CRLF & _
			"已修正变化:         " & $aResult[1] & @CRLF & _
			"已移除缺失记录:     " & $aResult[0] & @CRLF & _
			"已加入新文件:       " & $iNew & @CRLF & @CRLF & _
			"请在主页检查结果." & @CRLF & _
			"如果发现异常，请按实际情况使用 '修补' 或 '还原'."
	LogWrite(1, "同步完成: 正确 " & $aResult[2] & " 个，已修正 " & $aResult[1] & " 个，缺失 " & $aResult[0] & " 个，新增 " & $iNew & " 个.")
	MemoWrite(@CRLF & $sSummary)
	MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "同步完成", $sSummary)

	If $idOptionsReminder > 0 Then
		GUICtrlSetData($idOptionsReminder, "保存后设置才会生效")
		GUICtrlSetState($idOptionsReminder, $GUI_HIDE)
	EndIf
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)

	$g_bSearchCompleted = True
	$fFilesListed = 1
	GUICtrlSetState($idListview, $GUI_ENABLE)
	FillListViewWithFiles()
	_VerifyListedFiles(True)
	Local $iKeptR = _ApplyModifiedFilter()

	_GUICtrlTab_SetCurFocus($hTab, 0)
	$g_bIsPatching = False
	_RestorePostOpUI()

	If $iKeptR = 0 Then
		$g_bInModifiedMode = False
		$fFilesListed = 0
		$g_bSearchCompleted = False
		ReDim $g_aAllFiles[0][5]
		$g_mCheckedState.RemoveAll()
		FillListViewWithInfo()
		UpdateUIState()
		MemoWrite(@CRLF & "同步修补状态: 所有文件状态均正确，无需处理.")
	Else
		UpdateUIState()
		MemoWrite(@CRLF & "同步后有 " & $iKeptR & " 个文件需要处理. 请检查列表，然后按实际情况点击 '修补' 或 '还原'.")
	EndIf

	Return $aResult
EndFunc

Func _CreateInitialPatchStates()
	If FileExists($patchStatesINI) Then
		MsgBox(BitOR($MB_OK, $MB_ICONERROR), "无法新建", "patch_states.ini 已存在，请改用 '同步导入的 patch_states.ini'.")
		Return
	EndIf

	_LockOptionsUIForScan()

	ToggleLog(0)
	MemoWrite(@CRLF & "正在根据当前磁盘状态建立 patch_states.ini...")
	LogWrite(1, "新建 patch_states.ini: 正在扫描 " & $MyDefPath)

	_ResetScanCounters()
	$g_aAllFiles = $aNullArray
	ReDim $g_aAllFiles[0][5]
	$FileSearchedCount = 0
	If $bFindACC = 1 Then
		Local $aACCDirs[2]
		$aACCDirs[0] = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
		$aACCDirs[1] = EnvGet('ProgramFiles')      & "\Common Files\Adobe"
		For $sAccDir In $aACCDirs
			If FileExists($sAccDir) Then RecursiveFileSearch($sAccDir, 0, 0)
		Next
	EndIf
	RecursiveFileSearch($MyDefPath, 0, 0)

	If UBound($g_aAllFiles, 1) = 0 Then
		MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "新建 patch_states.ini", "在 " & $MyDefPath & " 中找不到可处理的文件，未建立 patch_states.ini.")
		LogWrite(1, "新建 patch_states.ini 已取消: 在 " & $MyDefPath & " 中找不到可处理的文件.")
		Return
	EndIf

	Local $iTotal = UBound($g_aAllFiles, 1)
	LogWrite(1, "新建 patch_states.ini: 找到 " & $iTotal & " 个可处理文件.")

	Local $bWeStartedCrypt = False
	If Not $g_bCryptActive Then
		_Crypt_Startup()
		$g_bCryptActive = True
		$bWeStartedCrypt = True
	EndIf

	Local $mStatus    = ObjCreate("Scripting.Dictionary")
	Local $mOrig      = ObjCreate("Scripting.Dictionary")
	Local $mPatched   = ObjCreate("Scripting.Dictionary")
	Local $mAppFiles  = ObjCreate("Scripting.Dictionary")
	Local $mAppVer    = ObjCreate("Scripting.Dictionary")
	Local $mWT        = ObjCreate("Scripting.Dictionary")
	Local $mPrimaryExe = ObjCreate("Scripting.Dictionary")

	Local $iPatchedCount = 0, $iUnpatchedCount = 0
	ProgressWrite(0)
	_SubProgressWrite(0)

	For $i = 0 To $iTotal - 1
		Local $sPath = $g_aAllFiles[$i][0]
		If Not FileExists($sPath) Then ContinueLoop

		Local $sApp = _GetAppGroupName($sPath)
		Local $sFileName = StringRegExpReplace($sPath, "^.*\\", "")

		If $mAppFiles.Exists($sApp) Then
			$mAppFiles.Item($sApp) = $mAppFiles.Item($sApp) & ";" & $sPath
		Else
			$mAppFiles.Item($sApp) = $sPath
		EndIf

		If StringRight($sFileName, 4) = ".exe" Then
			If Not $mPrimaryExe.Exists($sApp) Then
				$mPrimaryExe.Item($sApp) = $sPath
			Else
				If StringInStr($sFileName, StringLeft($sApp, 6)) Then
					$mPrimaryExe.Item($sApp) = $sPath
				EndIf
			EndIf
		EndIf

		Local $sBakPath = $sPath & ".bak"

		If FileExists($sBakPath) Then
			Local $sLowerName = StringLower($sFileName)
			If $sLowerName = "appspanelbl.dll" Or $sLowerName = "adobe desktop service.exe" Or _
			   $sLowerName = "containerbl.dll" Then
				_ProcessCloseEx("""Creative Cloud.exe""")
				_ProcessCloseEx("""Adobe Desktop Service.exe""")
				Sleep(100)
			EndIf
			Local $bDel = FileDelete($sPath)
			Local $bMov = FileMove($sBakPath, $sPath, $FC_OVERWRITE)
			If Not $bMov And Not $bDel Then
				LogWrite(1, "已跳过还原步骤: " & $sPath & "，修补时会检测并记录其状态.")
			EndIf
		EndIf

		Local $sLiveMD5 = StringLower(StringTrimLeft(String(_Crypt_HashFile($sPath, $CALG_MD5)), 2))

		$mStatus.Item($sPath) = "Unpatched"
		$mOrig.Item($sPath)   = $sLiveMD5
		$iUnpatchedCount += 1

		If Mod($i, 10) = 0 Then
			ProgressWrite(Round(($i + 1) / $iTotal * 100))
			_ShowStatusScreen("patching", "正在记录: " & $sFileName)
		EndIf
	Next

	For $sApp In $mAppFiles.Keys()
		Local $sExe = ""

		Local $sFirstFile = $mAppFiles.Item($sApp)
		Local $iSepIdx = StringInStr($sFirstFile, ";")
		If $iSepIdx > 0 Then $sFirstFile = StringLeft($sFirstFile, $iSepIdx - 1)
		Local $sAppRootForExe = StringRegExpReplace($sFirstFile, "(?i)^(.+\\Adobe\\[^\\]+\\).*$", "$1")
		If $sAppRootForExe <> $sFirstFile And FileExists($sAppRootForExe) Then
			$sExe = _FindLauncherExe($sAppRootForExe, $sApp)
		EndIf

		If $sExe = "" Or Not FileExists($sExe) Then
			If $mPrimaryExe.Exists($sApp) Then
				$sExe = $mPrimaryExe.Item($sApp)
			EndIf
		EndIf

		If $sExe <> "" And FileExists($sExe) Then
			Local $sVer = FileGetVersion($sExe)
			If @error Or $sVer = "" Then $sVer = FileGetVersion($sExe, $FV_PRODUCTVERSION)
			If $sVer = "" Then $sVer = "unknown"
			$mAppVer.Item($sApp) = "v" & $sVer
		Else
			$mAppVer.Item($sApp) = "vunknown"
		EndIf
	Next

	For $sApp In $mAppFiles.Keys()
		Local $sFirstFile = $mAppFiles.Item($sApp)
		Local $iSepIdx = StringInStr($sFirstFile, ";")
		If $iSepIdx > 0 Then $sFirstFile = StringLeft($sFirstFile, $iSepIdx - 1)
		Local $sAppRoot = StringRegExpReplace($sFirstFile, "(?i)^(.+\\Adobe\\[^\\]+\\).*$", "$1")
		If $sAppRoot <> $sFirstFile And FileExists($sAppRoot) Then
			$mWT.Item($sApp) = _HasWinTrustDll($sAppRoot) ? "1" : "0"
		Else
			$mWT.Item($sApp) = "0"
		EndIf
	Next

	If $bWeStartedCrypt Then
		_Crypt_Shutdown()
		$g_bCryptActive = False
	EndIf

	_WriteSectionFromMap("Patch_Status",   $mStatus)
	_WriteSectionFromMap("MD5_Original",   $mOrig)
	_WriteSectionFromMap("MD5_Patched",    $mPatched)
	_WriteSectionFromMap("App_File",       $mAppFiles)
	_WriteSectionFromMap("App_Version",    $mAppVer)
	_WriteSectionFromMap("WinTrust_Local", $mWT)

	IniWrite($patchStatesINI, "Info", "GenPVersion",   $g_Version)
	IniWrite($patchStatesINI, "Info", "ConfigVersion", $ConfigVerVar)
	IniWrite($patchStatesINI, "Info", "Created",       _NowCalc())
	IniWrite($patchStatesINI, "Info", "Origin",        "create-new")
	_RecordDevOverrideStateToLedger()

	_MaintainInisAlphebeticalWithSpacing($patchStatesINI)

	ProgressWrite(0)
	_SubProgressWrite(0)
	_ShowStatusScreen("complete", $MyDefPath)
	Sleep(1500)
	$g_bStatusScreenReady = False

	Local $sSummary = "patch_states.ini 已完成初步建立." & @CRLF & @CRLF & _
			"已记录文件: " & $iTotal & @CRLF & _
			"  - 软件组: " & $mAppFiles.Count & @CRLF & @CRLF & _
			"还需处理找到的文件并核验结果." & @CRLF & _
			"点击 '确定' 继续. 可在主页查看进度，" & @CRLF & _
			"完成后会自动打开日志."

	LogWrite(1, "新建 patch_states.ini 完成: 已记录 " & $iTotal & " 个文件，初始状态均为未修补.")
	MemoWrite(@CRLF & $sSummary)
	MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "patch_states.ini 已建立", $sSummary)

	If $idOptionsReminder > 0 Then
		GUICtrlSetData($idOptionsReminder, "保存后设置才会生效")
		GUICtrlSetState($idOptionsReminder, $GUI_HIDE)
	EndIf
	If $idBtnSaveOptions > 0 Then GUICtrlSetState($idBtnSaveOptions, $GUI_DISABLE)

	$g_bSearchCompleted = True
	$fFilesListed = 1
	GUICtrlSetState($idListview, $GUI_ENABLE)
	FillListViewWithFiles()
	_SyncWinTrustFromDisk()
	_VerifyListedFiles(True)
	Local $iKept = _ApplyModifiedFilter()

	_GUICtrlTab_SetCurFocus($hTab, 0)

	If $iKept = 0 Then
		$g_bIsPatching = False
		_ShowEmptyModifiedNotice()
		_RestorePostOpUI()
		UpdateUIState()
	Else
		UpdateUIState()
		MemoWrite(@CRLF & $iKept & " 个文件准备完毕，正在自动修补以完成初始化...")
		$g_bAutoPatchPending = True
	EndIf
EndFunc

Func _MaintainInisAlphebeticalWithSpacing($sIniPath)
	If Not FileExists($sIniPath) Then Return

	Local $aOrder[7] = ["App_Version", "App_File", "Patch_Status", _
	                    "MD5_Original", "MD5_Patched", "WinTrust_Local", "Info"]

	Local $aAllSections = IniReadSectionNames($sIniPath)
	If @error Or Not IsArray($aAllSections) Then Return

	Local $mKnown = ObjCreate("Scripting.Dictionary")
	For $i = 0 To UBound($aOrder) - 1
		$mKnown.Item(StringLower($aOrder[$i])) = 1
	Next

	Local $aFinal[0]
	For $i = 0 To UBound($aOrder) - 1
		_ArrayAdd($aFinal, $aOrder[$i])
	Next
	For $k = 1 To $aAllSections[0]
		If Not $mKnown.Exists(StringLower($aAllSections[$k])) Then
			_ArrayAdd($aFinal, $aAllSections[$k])
		EndIf
	Next

	Local $sOut = "", $bFirstWritten = False
	For $i = 0 To UBound($aFinal) - 1
		Local $sSection = $aFinal[$i]
		Local $aPairs = IniReadSection($sIniPath, $sSection)
		If @error Or Not IsArray($aPairs) Then ContinueLoop
		If $aPairs[0][0] = 0 Then ContinueLoop

		Local $aSortable[$aPairs[0][0]][2]
		For $k = 1 To $aPairs[0][0]
			$aSortable[$k - 1][0] = $aPairs[$k][0]
			$aSortable[$k - 1][1] = $aPairs[$k][1]
		Next
		_ArraySort($aSortable, 0, 0, 0, 0)

		If $bFirstWritten Then $sOut &= @CRLF
		$sOut &= "[" & $sSection & "]" & @CRLF
		For $k = 0 To UBound($aSortable) - 1
			$sOut &= $aSortable[$k][0] & "=" & $aSortable[$k][1] & @CRLF
		Next
		$bFirstWritten = True
	Next

	Local $hFile = FileOpen($sIniPath, $FO_OVERWRITE)
	If $hFile <> -1 Then
		FileWrite($hFile, $sOut)
		FileClose($hFile)
	EndIf
EndFunc

Func _WriteSectionFromMap($sSection, $mMap)
	If $mMap.Count = 0 Then Return
	Local $aOut[$mMap.Count + 1][2]
	$aOut[0][0] = $mMap.Count
	$aOut[0][1] = ""
	Local $i = 1
	For $sKey In $mMap.Keys
		$aOut[$i][0] = $sKey
		$aOut[$i][1] = $mMap.Item($sKey)
		$i += 1
	Next
	IniWriteSection($patchStatesINI, $sSection, $aOut)
EndFunc

Func _CleanOrphanBaks(ByRef $aRestoredPaths)
	If UBound($aRestoredPaths) = 0 Then Return 0

	Local $mDirs = ObjCreate("Scripting.Dictionary")
	For $i = 0 To UBound($aRestoredPaths) - 1
		Local $sPath = $aRestoredPaths[$i]
		Local $iSlash = StringInStr($sPath, "\", 0, -1)
		If $iSlash > 0 Then
			Local $sDir = StringLeft($sPath, $iSlash - 1)
			If Not $mDirs.Exists($sDir) Then $mDirs.Item($sDir) = 1
		EndIf
	Next

	Local $iRemoved = 0, $iKept = 0
	Local $aKeptNames[0]
	For $sDir In $mDirs.Keys
		Local $hFind = FileFindFirstFile($sDir & "\*.bak")
		If $hFind = -1 Then ContinueLoop
		While 1
			Local $sName = FileFindNextFile($hFind)
			If @error Then ExitLoop
			Local $sBak = $sDir & "\" & $sName
			If StringInStr(FileGetAttrib($sBak), "D") Then ContinueLoop

			Local $sSibling = StringTrimRight($sBak, 4)
			If FileExists($sSibling) Then
				$iKept += 1
				ReDim $aKeptNames[$iKept]
				$aKeptNames[$iKept - 1] = $sBak
				ContinueLoop
			EndIf

			If FileDelete($sBak) Then
				$iRemoved += 1
				LogWrite(1, "已删除没有对应原文件的备份: " & $sBak)
			EndIf
		WEnd
		FileClose($hFind)
	Next

	If $iRemoved > 0 Then
		LogWrite(1, "已从还原后的文件夹清理 " & $iRemoved & " 个无对应原文件的 .bak 备份.")
	EndIf
	If $iKept > 0 Then
		LogWrite(1, "已保留仍处于修补状态的 " & $iKept & " 个 .bak 备份:")
		MemoWrite(@CRLF & "已保留仍在使用的 " & $iKept & " 个备份:")
		For $i = 0 To UBound($aKeptNames) - 1
			LogWrite(1, "  - " & $aKeptNames[$i])
			MemoWrite("  - " & $aKeptNames[$i])
		Next
	EndIf
	Return $iRemoved
EndFunc

Func _PatchAdobeUXPComponent($sFilePath)
	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then Return 0
	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If BinaryLen($bData) = 0 Then Return 0
	Local $sFileName = StringLower(StringRegExpReplace($sFilePath, "^.*\\", ""))
	Local $bIsJs = StringRegExp($sFileName, "(?i)\.js$")
	Local $bModified = False
	Local $bAlready  = False
	Local $sData = BinaryToString($bData, 1)
	If $bIsJs Then
		If StringInStr($sData, "XelationshipProfile") Then
			$bAlready = True
		ElseIf StringInStr($sData, "RelationshipProfile") Then
			$sData = StringReplace($sData, "RelationshipProfile", "XelationshipProfile")
			$bModified = True
			LogWrite(1, "已对 " & $sFileName & " 应用 JS5 代码内绕过修补.")
		EndIf
	EndIf
	If Not $bModified Then
		If $bAlready Then Return 2
		Return 0
	EndIf
	Local $iPrePatchSize = FileGetSize($sFilePath)
	Local $sBak = $sFilePath & ".bak"
	If FileExists($sBak) Then
		If FileGetSize($sBak) <> $iPrePatchSize Then
			FileDelete($sBak)
			FileMove($sFilePath, $sBak)
		Else
			FileDelete($sFilePath)
		EndIf
	Else
		FileMove($sFilePath, $sBak)
	EndIf
	FileSetAttrib($sFilePath, "-RHS")
	Local $hWrite = FileOpen($sFilePath, 18)
	If $hWrite = -1 Then
		LogWrite(1, "UXP 修补写入失败 (访问被拒绝?): " & $sFileName)
		FileMove($sBak, $sFilePath)
		Return 0
	EndIf
	FileWrite($hWrite, Binary($sData))
	FileClose($hWrite)
	Local $sMD5Orig = "", $sMD5New = ""
	If $g_bCryptActive Then
		$sMD5Orig = StringTrimLeft(String(_Crypt_HashFile($sBak,      $CALG_MD5)), 2)
		$sMD5New  = StringTrimLeft(String(_Crypt_HashFile($sFilePath, $CALG_MD5)), 2)
	EndIf
	_QueueStateWrite($sFilePath, "", $sMD5Orig, $sMD5New, "Patched")
	Return 1
EndFunc

Func _AutoUnpackIfRuntimeInstaller($sFilePath)
	Local $bInScope = StringRegExp($sFilePath, "(?i)\\Adobe After Effects [^\\]+\\") Or _
			StringRegExp($sFilePath, "(?i)\\Adobe Premiere Pro [^\\]+\\")
	If Not $bInScope Then
		Return True
	EndIf

	If Not FileExists($sFilePath) Then
		Return False
	EndIf

	If Not IsUPXPacked($sFilePath) Then
		LogWrite(1, "文件已经解除 UPX 保护，继续修补.")
		Return True
	EndIf

	Local $upxPath = @ScriptDir & "\upx.exe"
	If Not FileExists($upxPath) Then
		FileInstall("upx.exe", $upxPath, 1)
		If Not FileExists($upxPath) Then
			LogWrite(1, "无法提取 upx.exe，解除 UPX 保护失败.")
			Return False
		EndIf
	EndIf

	If Not PatchUPXHeader($sFilePath) Then
		LogWrite(1, "修改 UPX 文件头失败，无法解除保护.")
		Return False
	EndIf

	Local $iResult = RunWait('"' & $upxPath & '" -d "' & $sFilePath & '"', "", @SW_HIDE)

	If $iResult = 0 Then
		If FileExists($sFilePath & ".bak") Then FileDelete($sFilePath & ".bak")
		LogWrite(1, "已解除 UPX 保护，继续修补.")
		Return True
	ElseIf $iResult = 2 Then
		If FileExists($sFilePath & ".bak") Then FileDelete($sFilePath & ".bak")
		LogWrite(1, "文件已经解除 UPX 保护，继续修补.")
		Return True
	Else
		LogWrite(1, "严重错误: UPX 返回代码 " & $iResult & ".")
		If FileExists($sFilePath & ".bak") Then
			FileCopy($sFilePath & ".bak", $sFilePath, 1)
			FileDelete($sFilePath & ".bak")
		EndIf
		Return False
	EndIf
EndFunc

Func _ListView_LeftClick($hListView, $lParam)
	Local $tInfo = DllStructCreate($tagNMITEMACTIVATE, $lParam)
	Local $iIndex = DllStructGetData($tInfo, "Index")

	If $iIndex <> -1 Then
		Local $iX = DllStructGetData($tInfo, "X")
		Local $aIconRect = _GUICtrlListView_GetItemRect($hListView, $iIndex, 1)
		If $iX < $aIconRect[0] And $iX >= 5 Then
			Return 0
		Else
			Local $aHit
			$aHit = _GUICtrlListView_HitTest($g_idListview)
			If $aHit[0] <> -1 Then
				Local $GroupIdOfHitItem = _GUICtrlListView_GetItemGroupID($idListview, $aHit[0])
				If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
					For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
						If _GUICtrlListView_GetItemGroupID($idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 0)
						EndIf
					Next
				Else
					For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
						If _GUICtrlListView_GetItemGroupID($idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 1)
						EndIf
					Next
				EndIf
			EndIf
		EndIf
	EndIf
EndFunc

Func _ListView_RightClick()
	Local $aHit
	$aHit = _GUICtrlListView_HitTest($g_idListview)
	If $aHit[0] <> -1 Then
		If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 0)
		Else
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 1)
		EndIf
	EndIf
EndFunc

Func _GetAppGroupName($sFilePath)
	Local $sLower = StringLower($sFilePath)

	If StringInStr($sLower, "\acrobat dc\") Or StringInStr($sLower, "\adobe acrobat\") Or _
	   StringInStr($sLower, "acrotray") Or StringInStr($sLower, "acrodistdll") Or _
	   StringInStr($sLower, "acrobat.dll") Or StringInStr($sLower, "_wf_acro") Or _
	   StringInStr($sLower, "\acrocef\") Then
		Return "Acrobat"
	EndIf

	If StringInStr($sLower, "\elements 2026 organizer\") Or _
	   StringInStr($sLower, "photoshopelementsorganizer") Then
		Return "Elements 2026 Organizer"
	EndIf

	If StringInStr($sLower, "com.adobe.ccx.start") Then
		If StringInStr($sLower, "\common files\adobe\uxp\extensions\") Or _
		   StringInStr($sLower, "\adobe\acc\") Then
			Return "Creative Cloud"
		EndIf
	EndIf

	If StringInStr($sLower, "\common files\adobe\") Then
		If StringInStr($sLower, "appspanelbl") Or StringInStr($sLower, "containerbl") Or _
		   StringInStr($sLower, "adobe desktop service") Or StringInStr($sLower, "hdpim") Or _
		   (StringInStr($sLower, "adobe_licensing_wf") And Not StringInStr($sLower, "_acro")) Or _
		   StringInStr($sLower, "adobecollabsync") Then
			Return "Creative Cloud"
		EndIf
	EndIf

	Local $iMark = StringInStr($sFilePath, "\Adobe\")
	If $iMark > 0 Then
		Local $sRest = StringMid($sFilePath, $iMark + 7)
		Local $iSlash = StringInStr($sRest, "\")
		Local $sAppFolder = ($iSlash > 0) ? StringLeft($sRest, $iSlash - 1) : $sRest
		If StringLeft($sAppFolder, 6) = "Adobe " Then $sAppFolder = StringTrimLeft($sAppFolder, 6)
		If $sAppFolder <> "" Then Return _NormaliseAppGroupName($sAppFolder, $sFilePath)
	EndIf

	Return "Other"
EndFunc

Func _NormaliseAppGroupName($sAppFolder, $sFilePath)
	If StringRegExp($sAppFolder, "\d{4}") Then Return $sAppFolder

	Local $sBase = $sAppFolder
	Local $bIsBeta = False
	If StringInStr($sBase, "(Beta)") Then
		$sBase = StringStripWS(StringReplace($sBase, "(Beta)", ""), 3)
		$bIsBeta = True
	ElseIf StringRegExp($sBase, "(?i)\sBeta$") Then
		$sBase = StringRegExpReplace($sBase, "(?i)\sBeta$", "")
		$bIsBeta = True
	EndIf
	If Not $bIsBeta Then Return $sAppFolder

	Local $iMark = StringInStr($sFilePath, "\Adobe\")
	If $iMark <= 0 Then Return $sAppFolder
	Local $sAdobeRoot = StringLeft($sFilePath, $iMark + 6)

	Local $sYear = ""
	Local $hSearch = FileFindFirstFile($sAdobeRoot & "*")
	If $hSearch <> -1 Then
		While 1
			Local $sSibling = FileFindNextFile($hSearch)
			If @error Then ExitLoop
			Local $sSib = $sSibling
			If StringLeft($sSib, 6) = "Adobe " Then $sSib = StringTrimLeft($sSib, 6)
			If StringLeft($sSib, StringLen($sBase)) = $sBase Then
				Local $aMatch = StringRegExp($sSib, "(\d{4})", 1)
				If Not @error Then
					$sYear = $aMatch[0]
					ExitLoop
				EndIf
			EndIf
		WEnd
		FileClose($hSearch)
	EndIf

	If $sYear = "" Then Return $sAppFolder
	Return $sBase & " " & $sYear & " (Beta)"
EndFunc

Func _Assign_Groups_To_Found_Files()
	Local $MyListItemCount = _GUICtrlListView_GetItemCount($idListview)
	Local $ItemFromList, $sGroupName
	Local $aGroups[0]
	Local $iGroupID = 1

	ReDim $g_aGroupIDs[0]

	Local $mCount   = ObjCreate("Scripting.Dictionary")
	Local $mExe     = ObjCreate("Scripting.Dictionary")
	Local $mWT      = ObjCreate("Scripting.Dictionary")
	Local $mAppRoot = ObjCreate("Scripting.Dictionary")
	For $i = 0 To $MyListItemCount - 1
		$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
		$sGroupName = _GetAppGroupName($ItemFromList)
		If $sGroupName = "" Then $sGroupName = "Other"

		If $mCount.Exists($sGroupName) Then
			$mCount.Item($sGroupName) = $mCount.Item($sGroupName) + 1
		Else
			$mCount.Item($sGroupName) = 1
		EndIf

		If StringRight(StringLower($ItemFromList), 4) = ".exe" Then
			If Not $mExe.Exists($sGroupName) Then
				$mExe.Item($sGroupName) = $ItemFromList
			Else
				Local $sCur  = StringLower(StringRegExpReplace($mExe.Item($sGroupName), "^.*\\", ""))
				Local $sNew  = StringLower(StringRegExpReplace($ItemFromList, "^.*\\", ""))
				Local $sAppL = StringLower($sGroupName)
				If StringInStr($sAppL, StringTrimRight($sNew, 4)) And _
				   Not StringInStr($sAppL, StringTrimRight($sCur, 4)) Then
					$mExe.Item($sGroupName) = $ItemFromList
				EndIf
			EndIf
		EndIf

		If Not $mWT.Exists($sGroupName) Then
			Local $sFolder = StringRegExpReplace($ItemFromList, "\\[^\\]+$", "")
			If FileExists($sFolder & "\wintrust.dll") Then $mWT.Item($sGroupName) = 1
		EndIf

		If Not $mAppRoot.Exists($sGroupName) Then
			Local $iMark = StringInStr($ItemFromList, "\Adobe\")
			If $iMark > 0 Then
				Local $sAfter = StringMid($ItemFromList, $iMark + 7)
				Local $iSlash = StringInStr($sAfter, "\")
				If $iSlash > 0 Then
					$mAppRoot.Item($sGroupName) = StringLeft($ItemFromList, $iMark + 6 + $iSlash)
				EndIf
			EndIf
		EndIf
	Next

	For $i = 0 To $MyListItemCount - 1
		$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
		$sGroupName = _GetAppGroupName($ItemFromList)
		If $sGroupName = "" Then $sGroupName = "Other"

		Local $iGroupIndex = _ArraySearch($aGroups, $sGroupName)
		If $iGroupIndex = -1 Then
			Local $sHeader = ($sGroupName = "Other") ? "其他" : $sGroupName
			If $mWT.Exists($sGroupName) Then $sHeader = "[WT] " & $sHeader

			Local $sVerExe = ""
			If $mExe.Exists($sGroupName) Then $sVerExe = $mExe.Item($sGroupName)
			If $sVerExe = "" And $mAppRoot.Exists($sGroupName) Then
				$sVerExe = _FindLauncherExe($mAppRoot.Item($sGroupName), $sGroupName)
			EndIf
			If $sVerExe <> "" Then
				Local $sVer = FileGetVersion($sVerExe)
				If @error Or $sVer = "" Then $sVer = FileGetVersion($sVerExe, $FV_PRODUCTVERSION)
				If $sVer <> "" Then $sHeader &= " (v" & $sVer & ")"
			EndIf

			Local $iCount = $mCount.Item($sGroupName)
			$sHeader &= " (" & $iCount & " 个文件)"

			_ArrayAdd($aGroups, $sGroupName)
			_GUICtrlListView_InsertGroup($idListview, $i, $iGroupID, "", 1)
			_GUICtrlListView_SetItemGroupID($idListview, $i, $iGroupID)
			_GUICtrlListView_SetGroupInfo($idListview, $iGroupID, $sHeader, 1, $LVGS_COLLAPSIBLE)
			_ArrayAdd($g_aGroupIDs, $iGroupID)
			$iGroupID += 1
		Else
			_GUICtrlListView_SetItemGroupID($idListview, $i, $iGroupIndex + 1)
		EndIf
	Next
EndFunc

Func _FindLauncherExe($sAppRoot, $sGroupName)
	If Not FileExists($sAppRoot) Then Return ""

	Local $sBase = StringRegExpReplace($sGroupName, "\s*\d{4}", "")
	$sBase = StringRegExpReplace($sBase, "\s*\(Beta\)", "")
	$sBase = StringStripWS($sBase, 3)

	Local $aLaunchers[24][2] = [ _
		["Acrobat",                     "Acrobat.exe"], _
		["After Effects",               "AfterFX.exe"], _
		["Animate",                     "Animate.exe"], _
		["Audition",                    "Adobe Audition.exe"], _
		["Bridge",                      "Adobe Bridge.exe"], _
		["Character Animator",          "Character Animator.exe"], _
		["Dimension",                   "Adobe Dimension.exe"], _
		["Dreamweaver",                 "Dreamweaver.exe"], _
		["Elements 2026 Organizer",     "PhotoshopElementsOrganizer.exe"], _
		["Illustrator",                 "Illustrator.exe"], _
		["InCopy",                      "InCopy.exe"], _
		["InDesign",                    "InDesign.exe"], _
		["Lightroom Classic",           "Lightroom.exe"], _
		["Lightroom",                   "lightroom.exe"], _
		["Media Encoder",               "Adobe Media Encoder.exe"], _
		["Photoshop Elements 2026",     "PhotoshopElementsEditor.exe"], _
		["Photoshop",                   "Photoshop.exe"], _
		["Premiere Elements 2026",      "PremiereElementsEditor.exe"], _
		["Premiere Pro",                "Adobe Premiere Pro.exe"], _
		["Substance 3D Designer",       "Adobe Substance 3D Designer.exe"], _
		["Substance 3D Modeler",        "Adobe Substance 3D Modeler.exe"], _
		["Substance 3D Painter",        "Adobe Substance 3D Painter.exe"], _
		["Substance 3D Sampler",        "Adobe Substance 3D Sampler.exe"], _
		["Substance 3D Stager",         "Adobe Substance 3D Stager.exe"] _
	]

	If $sBase = "Creative Cloud" Then
		Local $aCCCandidates[3]
		$aCCCandidates[0] = EnvGet("ProgramFiles(x86)") & "\Adobe\Adobe Creative Cloud\ACC\Creative Cloud.exe"
		$aCCCandidates[1] = EnvGet("ProgramFiles") & "\Adobe\Adobe Creative Cloud\ACC\Creative Cloud.exe"
		Local $sCCInstall = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Adobe\Adobe Application Manager\ACC", "InstallLocation")
		If Not @error And $sCCInstall <> "" Then
			$aCCCandidates[2] = StringRegExpReplace($sCCInstall, "\\$", "") & "\ACC\Creative Cloud.exe"
		EndIf
		For $sCCExe In $aCCCandidates
			If $sCCExe <> "" And FileExists($sCCExe) Then Return $sCCExe
		Next
	EndIf

	Local $aRoots[3] = [$sAppRoot, $sAppRoot & "Support Files\", $sAppRoot & "Elements Home\"]

	If StringInStr($sBase, "Photoshop Elements") Or StringInStr($sBase, "Premiere Elements") Then
		Local $sStem = StringInStr($sBase, "Photoshop") ? "Adobe Photoshop Elements" : "Adobe Premiere Elements"
		Local $sHome = $sAppRoot & "Elements Home\"
		If FileExists($sHome) Then
			Local $hFind = FileFindFirstFile($sHome & $sStem & " *.exe")
			If $hFind <> -1 Then
				Local $sFound = FileFindNextFile($hFind)
				FileClose($hFind)
				If $sFound <> "" Then Return $sHome & $sFound
			EndIf
		EndIf
	EndIf

	For $i = 0 To UBound($aLaunchers) - 1
		If StringInStr($sBase, $aLaunchers[$i][0]) Then
			Local $sBetaName = StringRegExpReplace($aLaunchers[$i][1], "\.exe$", " (Beta).exe")
			For $sRoot In $aRoots
				If FileExists($sRoot & $aLaunchers[$i][1]) Then Return $sRoot & $aLaunchers[$i][1]
				If FileExists($sRoot & $sBetaName) Then Return $sRoot & $sBetaName
			Next
		EndIf
	Next

	For $sRoot In $aRoots
		If Not FileExists($sRoot) Then ContinueLoop
		Local $hFind = FileFindFirstFile($sRoot & "*.exe")
		If $hFind = -1 Then ContinueLoop
		While 1
			Local $sExe = FileFindNextFile($hFind)
			If @error Then ExitLoop
			If StringRegExp($sExe, "(?i)unins|setup|helper|worker|service|crashreporter|updater") Then ContinueLoop
			FileClose($hFind)
			Return $sRoot & $sExe
		WEnd
		FileClose($hFind)
	Next

	Return ""
EndFunc

Func _SyncWinTrustFromDisk()
	If Not IsObj($g_mWinTrustQueue) Then $g_mWinTrustQueue = ObjCreate("Scripting.Dictionary")
	$g_mWinTrustQueue.RemoveAll()

	Local $aExisting = IniReadSection($patchStatesINI, "WinTrust_Local")
	If Not @error And IsArray($aExisting) Then
		For $i = 1 To $aExisting[0][0]
			$g_mWinTrustQueue.Item($aExisting[$i][0]) = $aExisting[$i][1]
		Next
	EndIf

	Local $mRoots = ObjCreate("Scripting.Dictionary")
	Local $iCount = _GUICtrlListView_GetItemCount($idListview)
	For $i = 0 To $iCount - 1
		Local $sPath = _GUICtrlListView_GetItemText($idListview, $i, 1)
		Local $sApp = _GetAppGroupName($sPath)
		If $sApp = "" Then ContinueLoop

		If Not $mRoots.Exists($sApp) Then
			Local $iMark = StringInStr($sPath, "\Adobe\")
			If $iMark > 0 Then
				Local $sAfter = StringMid($sPath, $iMark + 7)
				Local $iSlash = StringInStr($sAfter, "\")
				If $iSlash > 0 Then $mRoots.Item($sApp) = StringLeft($sPath, $iMark + 6 + $iSlash)
			EndIf
		EndIf
	Next

	For $sApp In $mRoots.Keys()
		Local $bTrusted = _HasWinTrustDll($mRoots.Item($sApp))
		$g_mWinTrustQueue.Item($sApp) = $bTrusted ? "1" : "0"
	Next

	_WriteWinTrustImmediate()
EndFunc

Func _HasWinTrustDll($sAppRoot)
	If Not FileExists($sAppRoot) Then Return False

	If FileExists($sAppRoot & "wintrust.dll") Then Return True
	If FileExists($sAppRoot & "Support Files\wintrust.dll") Then Return True
	If FileExists($sAppRoot & "Support Files\Support Files\wintrust.dll") Then Return True
	If FileExists($sAppRoot & "Support Files\Contents\Windows\wintrust.dll") Then Return True

	Return _ScanForWinTrust($sAppRoot, 0, 4)
EndFunc

Func _ScanForWinTrust($sDir, $iDepth, $iMaxDepth)
	If $iDepth > $iMaxDepth Then Return False
	If FileExists($sDir & "wintrust.dll") Then Return True

	Local $hFind = FileFindFirstFile($sDir & "*")
	If $hFind = -1 Then Return False
	Local $bFound = False
	While 1
		Local $sName = FileFindNextFile($hFind)
		If @error Then ExitLoop
		If $sName = "." Or $sName = ".." Then ContinueLoop
		Local $sAttrib = FileGetAttrib($sDir & $sName)
		If Not StringInStr($sAttrib, "D") Then ContinueLoop
		If StringRegExp($sName, "(?i)^(Resources|Locales|Legal|Samples|Presets|Templates|Documentation|Help|ICC Profiles|ICU|Scripts|Configuration|Settings|data|docs|localization|locales)$") Then ContinueLoop
		If _ScanForWinTrust($sDir & $sName & "\", $iDepth + 1, $iMaxDepth) Then
			$bFound = True
			ExitLoop
		EndIf
	WEnd
	FileClose($hFind)
	Return $bFound
EndFunc

Func _WriteWinTrustImmediate()
	If Not IsObj($g_mWinTrustQueue) Or $g_mWinTrustQueue.Count = 0 Then Return
	_WriteSectionFromMap("WinTrust_Local", $g_mWinTrustQueue)
	_MaintainInisAlphebeticalWithSpacing($patchStatesINI)
EndFunc

Func _RefreshGroupHeadersFromWT()
	Local $iCount = _GUICtrlListView_GetGroupCount($idListview)
	If $iCount <= 0 Then Return
	For $iIdx = 0 To UBound($g_aGroupIDs) - 1
		Local $iGid = $g_aGroupIDs[$iIdx]
		Local $aInfo = _GUICtrlListView_GetGroupInfo($idListview, $iGid)
		If Not IsArray($aInfo) Then ContinueLoop
		Local $sHeader = $aInfo[0]
		If $sHeader = "" Then ContinueLoop

		Local $sStripped = StringRegExpReplace($sHeader, "^\[WT\]\s*", "")

		Local $sAppName = StringRegExpReplace($sStripped, "\s*\(v[^)]+\).*$", "")
		$sAppName = StringRegExpReplace($sAppName, "\s*\(\d+\s+file[s]?\)$", "")

		Local $sNewHeader = $sStripped
		If IsObj($g_mWinTrustQueue) And $g_mWinTrustQueue.Exists($sAppName) Then
			If $g_mWinTrustQueue.Item($sAppName) = "1" Then $sNewHeader = "[WT] " & $sStripped
		EndIf

		If $sNewHeader <> $sHeader Then
			_GUICtrlListView_SetGroupInfo($idListview, $iGid, $sNewHeader, $aInfo[1], $LVGS_COLLAPSIBLE)
		EndIf
	Next
EndFunc

Func _UpdateCollapseHeader()
	Local $sLabel = ($MyLVGroupIsExpanded = 1) ? "全部折叠" : "全部展开"
	_GUICtrlListView_SetColumn($idListview, 1, "  软件文件                                                         " & $sLabel)
EndFunc

Func _Collapse_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview)
	If $aCount > 0 Then
		If $MyLVGroupIsExpanded = 1 Then
			_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

			For $i = 0 To UBound($g_aGroupIDs) - 1
				$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $g_aGroupIDs[$i])
				If IsArray($aInfo) Then
					_GUICtrlListView_SetGroupInfo($idListview, $g_aGroupIDs[$i], $aInfo[0], $aInfo[1], $LVGS_COLLAPSED)
				EndIf
			Next
			_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
			_RedrawWindow($idListview)
		Else
			_Expand_All_Click()
		EndIf
		$MyLVGroupIsExpanded = Not $MyLVGroupIsExpanded
		_UpdateCollapseHeader()
	EndIf
EndFunc

Func _Expand_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview)
	If $aCount > 0 Then
		_SendMessageL($idListview, $WM_SETREDRAW, False, 0)

		For $i = 0 To UBound($g_aGroupIDs) - 1
			$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $g_aGroupIDs[$i])
			If IsArray($aInfo) Then
				_GUICtrlListView_SetGroupInfo($idListview, $g_aGroupIDs[$i], $aInfo[0], $aInfo[1], $LVGS_NORMAL)
				_GUICtrlListView_SetGroupInfo($idListview, $g_aGroupIDs[$i], $aInfo[0], $aInfo[1], $LVGS_COLLAPSIBLE)
			EndIf
		Next
		_SendMessageL($idListview, $WM_SETREDRAW, True, 0)
		_RedrawWindow($idListview)
	EndIf
EndFunc

Func _SendMessageL($hWnd, $Msg, $wParam, $lParam)
	Return DllCall("user32.dll", "LRESULT", "SendMessageW", "HWND", GUICtrlGetHandle($hWnd), "UINT", $Msg, "WPARAM", $wParam, "LPARAM", $lParam)[0]
EndFunc

Func _RedrawWindow($hWnd)
	DllCall("user32.dll", "bool", "RedrawWindow", "hwnd", GUICtrlGetHandle($hWnd), "ptr", 0, "ptr", 0, "uint", 0x0100)
EndFunc

Func WM_COMMAND($hWnd, $Msg, $wParam, $lParam)
	If BitAND($wParam, 0x0000FFFF) = $idButtonStop Then $fInterrupt = 1
	Return $GUI_RUNDEFMSG
EndFunc

Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam
	Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	Local $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	Local $iCode = DllStructGetData($tNMHDR, "Code")

	If $g_bIsPatching And $hWndFrom = GUICtrlGetHandle($hTab) Then
		If $iCode = -402 Then
			Local $iTarget = _GUICtrlTab_GetCurFocus($hTab)
			If $iTarget <> 0 And $iTarget <> $g_iLogTabIndex Then
				Return 1
			EndIf
		ElseIf $iCode = -551 Then
			Local $iNow = _GUICtrlTab_GetCurFocus($hTab)
			If $iNow <> 0 And $iNow <> $g_iLogTabIndex Then
				_GUICtrlTab_SetCurFocus($hTab, 0)
				MemoWrite(@CRLF & "修补或还原期间无法切换页面，正在返回主页.")
			EndIf
		EndIf
	EndIf

	If $g_bPendingInfoReset And Not $g_bIsPatching And $hWndFrom = GUICtrlGetHandle($hTab) Then
		If $iCode = -551 Then
			Local $iDest = _GUICtrlTab_GetCurFocus($hTab)
			If $iDest <> 0 Then
				$g_bPendingInfoReset = False
				$fFilesListed = 0
				$g_bSearchCompleted = False
				ReDim $g_aAllFiles[0][5]
				$g_mCheckedState.RemoveAll()
				FillListViewWithInfo()
				UpdateUIState()
			EndIf
		EndIf
	EndIf

	Switch $hWndFrom
		Case $g_idListview
			Switch $iCode
				Case $LVN_COLUMNCLICK
					_Collapse_All_Click()
				Case $NM_CLICK
					_ListView_LeftClick($g_idListview, $lParam)
				Case $NM_RCLICK
					_ListView_RightClick()
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc

Func hL_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	Local $iIDFrom = BitAND($wParam, 0xFFFF)
	Local $iCode = BitShift($wParam, 16)

	If $iCode = $STN_CLICKED Then
		If $iIDFrom = $g_idHyperlinkMain Or $iIDFrom = $g_idHyperlinkLog Or $iIDFrom = $g_idHyperlinkOptions _
				Or $iIDFrom = $g_idHyperlinkPopup Or $iIDFrom = $g_idHyperlinkFW _
				Or $iIDFrom = $g_idHyperlinkHosts Or $iIDFrom = $g_idHyperlinkWT Then
			Local $sUrl = Deloader($g_aSignature)
			If TimerDiff($g_iHyperlinkClickTime) > 500 Then
				ShellExecute($sUrl)
				$g_iHyperlinkClickTime = TimerInit()
			EndIf
			Return $GUI_RUNDEFMSG
		EndIf
	EndIf

	Return WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
EndFunc

Func _Exit()
	Exit
EndFunc

Func IniReadArray($FileName, $section, $key, $default)
	Local $sINI = IniRead($FileName, $section, $key, $default)
	$sINI = StringReplace($sINI, '"', '')
	StringReplace($sINI, ",", ",")
	Local $aSize = @extended
	Local $aReturn[$aSize + 1]
	Local $aSplit = StringSplit($sINI, ",")
	For $i = 0 To $aSize
		$aReturn[$i] = $aSplit[$i + 1]
	Next
	Return $aReturn
EndFunc

Func ReplaceToArray($sParam)
	Local $sString = StringReplace($sParam, '"', '')
	StringReplace($sString, ",", ",")
	Local $aSize = @extended
	Local $aReturn[$aSize + 1]
	Local $aSplit = StringSplit($sString, ",")
	For $i = 0 To $aSize
		$aReturn[$i] = $aSplit[$i + 1]
	Next
	Return $aReturn
EndFunc

Func _IsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc

Func SaveOptionsToConfig()
	If _IsChecked($idResetOnSave) Then
		Local $iConfirm = MsgBox(BitOR($MB_YESNO, $MB_ICONEXCLAMATION), _
				"重置修补状态?", _
				"是否删除 patch_states.ini? 其中记录的全部修补与还原历史" & @CRLF & _
				"(MD5、已修补/未修补状态、软件版本) 都会丢失." & @CRLF & @CRLF & _
				"磁盘中的文件不会改变，仅删除 GenP 的修补记录.")
		If $iConfirm = $IDYES Then
			If FileExists($patchStatesINI) Then
				If FileDelete($patchStatesINI) Then
					MemoWrite(@CRLF & "已按用户要求删除 patch_states.ini.")
					LogWrite(1, "重置修补状态: 已删除 " & $patchStatesINI)
				Else
					MemoWrite(@CRLF & "错误: 无法删除 patch_states.ini (文件正在使用?).")
					LogWrite(1, "重置修补状态失败: " & $patchStatesINI)
				EndIf
			Else
				LogWrite(1, "重置修补状态: 没有 patch_states.ini，无需删除.")
			EndIf
		EndIf
		GUICtrlSetState($idResetOnSave, $GUI_UNCHECKED)
	EndIf

	If _IsChecked($idCreateStates) Then
		If FileExists($patchStatesINI) Then
			MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION), "无法新建 patch_states.ini", _
					"以下位置已经存在 patch_states.ini:" & @CRLF & $patchStatesINI & @CRLF & @CRLF & _
					"请改用 '同步导入的 patch_states.ini'，根据当前安装内容" & @CRLF & _
					"核对并更新现有文件.")
		Else
			_CreateInitialPatchStates()
		EndIf
		GUICtrlSetState($idCreateStates, $GUI_UNCHECKED)
	EndIf

	If _IsChecked($idReconcileStates) Then
		_ReconcilePatchStates()
		GUICtrlSetState($idReconcileStates, $GUI_UNCHECKED)
	EndIf

	IniWrite($sINIPath, "Options", "FindACC",            _IsChecked($idFindACC)      ? "1" : "0")
	IniDelete($sINIPath, "Options", "EnableMD5")
	IniWrite($sINIPath, "Options", "OnlyDefaultFolders", _IsChecked($idOnlyAFolders) ? "1" : "0")
	IniWrite($sINIPath, "Options", "ShowBetaApps",       _IsChecked($idShowBetaApps) ? "1" : "0")
	IniWrite($sINIPath, "Options", "EnableGood1",        _IsChecked($idEnableGood1)  ? "1" : "0")
	IniWrite($sINIPath, "Options", "UseCustomDefault",   _IsChecked($idUseCustomDefault) ? "1" : "0")
	Local $sTypedPath = StringStripWS(GUICtrlRead($idBtnSetCustomPath), 3)
	Local $sDefaultPath = @ProgramFilesDir & "\Adobe"
	If _IsChecked($idUseCustomDefault) Then
		If $sTypedPath <> "" And FileExists($sTypedPath) And StringInStr(FileGetAttrib($sTypedPath), "D") Then
			IniWrite($sINIPath, "Custom_Default", "Path", $sTypedPath)
			$g_sCustomDefaultPath = $sTypedPath
			$g_sPendingCustomPath = $sTypedPath
		Else
			MsgBox($MB_OK, "未设置自定义路径", _
					"已经勾选 '使用自定义默认扫描路径'，但路径为空或无效." & @CRLF & @CRLF & _
					"下次启动时将恢复为 " & $sDefaultPath & "." & @CRLF & _
					"请设置有效文件夹并重新保存.")
			$g_sCustomDefaultPath = ""
			$g_sPendingCustomPath = ""
			IniDelete($sINIPath, "Custom_Default", "Path")
			IniDelete($sINIPath, "Custom_Default")
		EndIf
	Else
		$g_sPendingCustomPath = ""
		$g_sCustomDefaultPath = ""
		IniDelete($sINIPath, "Custom_Default", "Path")
		IniDelete($sINIPath, "Custom_Default")
		GUICtrlSetData($idBtnSetCustomPath, $sDefaultPath)
	EndIf

	Local $sNewDomainListURL = StringStripWS(GUICtrlRead($idCustomDomainListInput), 1)
	If $sNewDomainListURL = "" Then
		$sNewDomainListURL = $sDefaultDomainListURL
		GUICtrlSetData($idCustomDomainListInput, $sNewDomainListURL)
		MsgBox(0, "未填写 URL", "自定义屏蔽域名列表下载地址不能为空，已使用默认地址。")
	EndIf

	If $sNewDomainListURL <> $sCurrentDomainListURL Then
		IniWrite($sINIPath, "Options", "CustomDomainListURL", $sNewDomainListURL)
		$sCurrentDomainListURL = $sNewDomainListURL
	EndIf

	If $g_sWinTrustPath <> "" Then
		IniWrite($sINIPath, "Options", "WinTrustPath", $g_sWinTrustPath)
	EndIf
	_PinCustomDomainListURLLast()
	_SnapshotOptions()

	MemoWrite(@CRLF & "设置已保存到 config.ini.")
	LogWrite(1, "设置已保存.")
EndFunc

Func Deloader($sLoaded)
        Local $sDeloaded = ""
        For $i = 1 To StringLen($sLoaded)
                Local $iAscii = Asc(StringMid($sLoaded, $i, 1))
                Local $iShifted = $iAscii - 10
                If $iShifted < 32 Then
                      $iShifted = 126 - (31 - $iShifted)
                EndIf
                $sDeloaded &= Chr($iShifted)
        Next
        Return $sDeloaded
EndFunc

Func ShowInfoPopup($sText)
	Local $aMainPos = WinGetPos($MyhGUI)
	If @error Then
		Local $iPopupX = -1
		Local $iPopupY = -1
	Else
		Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
		Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 100) / 2
	EndIf

	Local $hPopup = GUICreate("", 300, 100, $iPopupX, $iPopupY, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOPMOST)
	Local $idEdit = GUICtrlCreateEdit($sText, 10, 10, 280, 80, BitOR($ES_READONLY, $ES_MULTILINE, $ES_AUTOVSCROLL), 0)
	GUICtrlSetBkColor($idEdit, 0xF0F0F0)
	GUISetState(@SW_SHOW, $hPopup)
	_GUICtrlEdit_SetSel($idEdit, -1, -1)
	While WinActive($hPopup)
		If GUIGetMsg() = $GUI_EVENT_CLOSE Then ExitLoop
	WEnd
	GUIDelete($hPopup)
EndFunc

Func RemoveAGS()
	GUICtrlSetState($idBtnRemoveAGS, $GUI_DISABLE)
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite(@CRLF & "正在删除 AGS" & @CRLF & "---" & @CRLF & "请稍候...")

	Local $aServices = ["AGMService", "AGSService"]
	Local $ProgramFilesX86 = EnvGet("ProgramFiles(x86)")
	Local $PublicDir = EnvGet("PUBLIC")
	Local $WinDir = @WindowsDir
	Local $LocalAppData = EnvGet("LOCALAPPDATA")
	Local $AcrobatDCAGS = _FindAcrobatDCAGS()
	Local $aPaths[10] = [ _
			$ProgramFilesX86 & "\Common Files\Adobe\Adobe Desktop Common\AdobeGenuineClient\AGSService.exe", _
			$ProgramFilesX86 & "\Common Files\Adobe\AdobeGCClient", _
			$ProgramFilesX86 & "\Common Files\Adobe\OOBE\PDApp\AdobeGCClient", _
			$PublicDir & "\Documents\AdobeGCData", _
			$WinDir & "\System32\Tasks\AdobeGCInvoker-1.0", _
			$WinDir & "\System32\Tasks_Migrated\AdobeGCInvoker-1.0", _
			$ProgramFilesX86 & "\Adobe\Adobe Creative Cloud\Utils\AdobeGenuineValidator.exe", _
			$WinDir & "\Temp\adobegc.log", _
			$LocalAppData & "\Temp\adobegc.log", _
			$AcrobatDCAGS _
			]

	Local $iServiceSuccess = 0
	For $sService In $aServices
		Local $iExistCode = RunWait("sc query " & $sService, "", @SW_HIDE)
		If $iExistCode = 1060 Then
			LogWrite(1, "服务不存在: " & $sService)
			ContinueLoop
		ElseIf $iExistCode <> 0 Then
			LogWrite(1, "无法检查服务 " & $sService & " (退出错误代码: " & $iExistCode & ")")
			ContinueLoop
		EndIf
		LogWrite(1, "服务已找到: " & $sService)

		Local $iStopPID = Run("sc stop " & $sService, "", @SW_HIDE, $STDERR_CHILD)
		Local $iTimeout = 10000
		Local $iWaitResult = ProcessWaitClose($iStopPID, $iTimeout)
		If $iWaitResult = 0 Then
			ProcessClose($iStopPID)
			LogWrite(1, "警告: 无法停止 " & $sService & " - 操作超时 " & $iTimeout & "ms")
		Else
			Local $iStopCode = @error ? 1 : 0
			If $iStopCode = 0 Or StringInStr(StderrRead($iStopPID), "1052") Then
				LogWrite(1, "服务已停止: " & $sService)
			Else
				LogWrite(1, "无法停止服务 " & $sService & " (可能存在错误)")
			EndIf
		EndIf

		Local $iDeletePID = Run("sc delete " & $sService, "", @SW_HIDE, $STDERR_CHILD)
		$iWaitResult = ProcessWaitClose($iDeletePID, $iTimeout)
		If $iWaitResult = 0 Then
			ProcessClose($iDeletePID)
			LogWrite(1, "警告: 无法删除 " & $sService & " - 操作超时 " & $iTimeout & "ms")
		Else
			Local $iDeleteCode = @error ? 1 : 0
			If $iDeleteCode = 0 Then
				LogWrite(1, "服务已删除: " & $sService)
				$iServiceSuccess += 1
			Else
				LogWrite(1, "无法删除服务 " & $sService & " (可能存在错误)")
			EndIf
		EndIf
	Next

	Local $iFileSuccess = 0
	For $sPath In $aPaths
		If $sPath = "" Then ContinueLoop
		If FileExists($sPath) Then
			If StringInStr(FileGetAttrib($sPath), "D") Then
				If DirRemove($sPath, 1) Then
					LogWrite(1, "已删除文件夹: " & $sPath)
					$iFileSuccess += 1
				Else
					LogWrite(1, "无法删除文件夹: " & $sPath)
				EndIf
			Else
				If FileDelete($sPath) Then
					LogWrite(1, "已删除文件: " & $sPath)
					$iFileSuccess += 1
				Else
					LogWrite(1, "无法删除文件: " & $sPath)
				EndIf
			EndIf
		Else
			LogWrite(1, "不存在: " & $sPath)
		EndIf
	Next

	MemoWrite("AGS 删除完成，已处理 " & $iServiceSuccess & " / " & UBound($aServices) & " 个服务和 " & $iFileSuccess & " / " & UBound($aPaths) & " 个文件.")
	LogWrite(1, "AGS 删除完成。服务: " & $iServiceSuccess & "/" & UBound($aServices) & ", 文件: " & $iFileSuccess & "/" & UBound($aPaths) & @CRLF)
	ToggleLog(1)
	GUICtrlSetState($idBtnRemoveAGS, $GUI_ENABLE)
EndFunc

Func _FindAcrobatDCAGS()
	Local $aCandidateRoots[4]
	$aCandidateRoots[0] = $MyDefPath & "\Acrobat DC\Acrobat"

	Local $sInstallPath = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Adobe\Adobe Acrobat\DC\InstallPath", "")
	If Not @error And $sInstallPath <> "" Then
		$aCandidateRoots[1] = StringRegExpReplace($sInstallPath, "\\$", "")
	EndIf

	Local $sAcroExe = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Acrobat.exe", "")
	If Not @error And $sAcroExe <> "" Then
		$aCandidateRoots[2] = StringRegExpReplace($sAcroExe, "\\[^\\]+$", "")
	EndIf

	$aCandidateRoots[3] = EnvGet("ProgramFiles") & "\Adobe\Acrobat DC\Acrobat"

	For $sRoot In $aCandidateRoots
		If $sRoot = "" Then ContinueLoop
		If FileExists($sRoot) Then Return $sRoot & "\GC\AGSService.exe"
	Next

	Return ""
EndFunc

Func InstallAGSDummy()
	Local $iFileSuccess = 0, $iRegSuccess = 0, $iConsentFileSuccess = 0, $iServiceSuccess = 0
	GUICtrlSetState($idBtnDummyAGS, $GUI_DISABLE)
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite(@CRLF & "正在配置 AGS 重定向 (替换模式)..." & @CRLF & "---" & @CRLF & "请稍候...")

	Local $ProgramFiles = EnvGet("ProgramFiles")
	Local $AGSFolder = EnvGet("ProgramFiles(x86)") & "\Common Files\Adobe\AdobeGCClient"
	Local $AcrobatDCAGS = _FindAcrobatDCAGS()
	Local $aFiles = ["AdobeGCClient.exe", "AGMService.exe", "AGSService.exe"]
	Local $aServices = ["AGMService", "AGSService"]
	Local $NotepadPath = @WindowsDir & "\System32\notepad.exe"
	Local $PublicConsentDir = EnvGet("PUBLIC") & "\Documents\AdobeGCInfo"
	Local $PublicConsentFile = $PublicConsentDir & "\ConsentRecord"

	For $sFile In $aFiles
		If ProcessExists($sFile) Then
			ProcessClose($sFile)
			ProcessWaitClose($sFile, 2000)
			LogWrite(1, "已终止进程: " & $sFile)
		EndIf
	Next

	For $sService In $aServices
		If RunWait("sc config " & $sService & " start= disabled", "", @SW_HIDE) = 0 Then
			LogWrite(1, "已禁用服务: " & $sService)
			$iServiceSuccess += 1
		EndIf
	Next

	If Not FileExists($AGSFolder) Then DirCreate($AGSFolder)
	For $sFile In $aFiles
		Local $Dest = $AGSFolder & "\" & $sFile
		FileSetAttrib($Dest, "-RASH")
		If FileCopy($NotepadPath, $Dest, 9) Then
			LogWrite(1, "已在 AdobeGCClient 路径创建替代文件: " & $Dest)
			$iFileSuccess += 1
		EndIf
	Next

	If $AcrobatDCAGS <> "" Then
		If ProcessExists("AGSService.exe") Then
			ProcessClose("AGSService.exe")
			ProcessWaitClose("AGSService.exe", 2000)
		EndIf
		Local $sAcroParent = StringRegExpReplace($AcrobatDCAGS, "\\[^\\]+$", "")
		If Not FileExists($sAcroParent) Then DirCreate($sAcroParent)
		FileSetAttrib($AcrobatDCAGS, "-RASH")
		If FileCopy($NotepadPath, $AcrobatDCAGS, 9) Then
			LogWrite(1, "已在 Acrobat DC 路径创建替代文件: " & $AcrobatDCAGS)
			$iFileSuccess += 1
		Else
			LogWrite(1, "无法在以下位置替换 Acrobat DC 的 AGSService.exe: " & $AcrobatDCAGS)
		EndIf
	Else
		LogWrite(1, "未检测到 Acrobat DC，已跳过其 AGSService.exe.")
	EndIf

	Local $RegPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Adobe\Adobe Genuine Service\Consent\Retail"
	Local $sMultiString = "UserType: GreenZone" & @LF & "Consent: Consented | DateAndTime: 1757294112 | DontAskAgain: Yes | ConsentedButtonText: OK | Retries: 0 | Pending: No"
	If RegWrite($RegPath, "ConsentInfo", "REG_MULTI_SZ", $sMultiString) Then
		LogWrite(1, "注册表已设为 GreenZone")
		$iRegSuccess = 1
	EndIf

	If Not FileExists($PublicConsentDir) Then DirCreate($PublicConsentDir)
	FileSetAttrib($PublicConsentFile, "-RASH")
	Local $hFile = FileOpen($PublicConsentFile, 2)
	If $hFile <> -1 Then
		FileWriteLine($hFile, "UserType: GreenZone | Source: 1757294112-CCD")
		FileWriteLine($hFile, "Consent: Consented | DateAndTime: 1757294112 | DontAskAgain: Yes | ConsentedButtonText: OK | Retries: 0 | Pending: No")
		FileClose($hFile)
		LogWrite(1, "ConsentRecord 文件已修改")
		$iConsentFileSuccess = 1
	EndIf

	MemoWrite("AGS 重定向完成. 已禁用服务: " & $iServiceSuccess & "，替代文件: " & $iFileSuccess & "，注册表: " & ($iRegSuccess ? "成功" : "失败") & "，ConsentRecord: " & ($iConsentFileSuccess ? "成功" : "失败"))
	LogWrite(1, "AGS 替换模式完成. 替代文件: " & $iFileSuccess & "，注册表: " & $iRegSuccess & "，ConsentRecord: " & $iConsentFileSuccess & @CRLF)

	ToggleLog(1)
	GUICtrlSetState($idBtnDummyAGS, $GUI_ENABLE)
EndFunc

Func RemoveHostsEntries()
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sTempHosts = @TempDir & "\temp_hosts_remove.tmp"
	Local $sMarkerStart = "# START - Adobe Blocklist"
	Local $sMarkerEnd = "# END - Adobe Blocklist"

	FileSetAttrib($sHostsPath, "-R")

	Local $sHostsContent = FileRead($sHostsPath)
	If @error Then
		MemoWrite("无法读取 hosts 文件." & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		Return False
	EndIf

	If Not StringInStr($sHostsContent, $sMarkerStart) Or Not StringInStr($sHostsContent, $sMarkerEnd) Then
		LogWrite(1, "未找到 Adobe 相关条目可删." & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		ToggleLog(1)
		Return True
	EndIf

	$sHostsContent = StringRegExpReplace($sHostsContent, "(?s)" & $sMarkerStart & ".*?" & $sMarkerEnd, "")

	Local $hTempFile = FileOpen($sTempHosts, 2)
	If $hTempFile = -1 Then
		MemoWrite("无法创建临时 hosts 文件." & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		Return False
	EndIf
	FileWrite($hTempFile, $sHostsContent)
	FileClose($hTempFile)

	If Not FileCopy($sTempHosts, $sHostsPath, 1) Then
		MemoWrite("无法写入更新后的 hosts 文件." & @CRLF)
		MemoWrite("尝试从: " & $sTempHosts & " 复制到: " & $sHostsPath & @CRLF)
		FileDelete($sTempHosts)
		FileSetAttrib($sHostsPath, "+R")
		Return False
	EndIf
	FileDelete($sTempHosts)

	FileSetAttrib($sHostsPath, "+R")
	LogWrite(1, "已清理 hosts 中的 Adobe 条目." & @CRLF)
	ToggleLog(1)
	Return True
EndFunc

Func ScanDNSCache(ByRef $sHostsContent)
	Local $sMarkerStart = "# START - Adobe Blocklist"
	Local $sMarkerEnd = "# END - Adobe Blocklist"

	Local $sBlockSection = StringRegExp($sHostsContent, "(?s)" & $sMarkerStart & "(.*?)" & $sMarkerEnd, 1)
	If @error Or UBound($sBlockSection) = 0 Then
		MemoWrite("无法从 hosts 中解析 Adobe 屏蔽列表." & @CRLF)
		Return 0
	EndIf
	Local $aCurrentDomains = StringSplit(StringStripWS($sBlockSection[0], 8), @CRLF, 2)
	Local $aHostsDomains[0]
	For $i = 0 To UBound($aCurrentDomains) - 1
		Local $sLine = StringStripWS($aCurrentDomains[$i], 3)
		If StringRegExp($sLine, "^\d+\.\d+\.\d+\.\d+\s+(.+)$") Then
			_ArrayAdd($aHostsDomains, StringRegExpReplace($sLine, "^\d+\.\d+\.\d+\.\d+\s+(.+)$", "$1"))
		EndIf
	Next
	_ArraySort($aHostsDomains)
	_ArrayUnique($aHostsDomains)

	Local $sTempDNS = @TempDir & "\dns_cache.txt"
	Local $iPID = Run(@ComSpec & " /c ipconfig /displaydns > " & $sTempDNS, "", @SW_HIDE)
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: ipconfig /displaydns 操作超时 " & $iTimeout & "ms." & @CRLF)
	EndIf

	Local $sDNSCache = FileRead($sTempDNS)
	If @error Then
		MemoWrite("无法读取 DNS 缓存." & @CRLF)
		FileDelete($sTempDNS)
		Return 0
	EndIf
	FileDelete($sTempDNS)

	Local $aDNSDomains = StringRegExp($sDNSCache, "Record Name[^\n]*?\n\s*:\s*([^\n]*adobestats\.io[^\n]*)", 3)
	If UBound($aDNSDomains) = 0 Then
		Return 0
	EndIf
	_ArraySort($aDNSDomains)
	_ArrayUnique($aDNSDomains)

	Local $aNewDomains[0]
	For $i = 0 To UBound($aDNSDomains) - 1
		Local $sDomain = StringStripWS($aDNSDomains[$i], 3)
		If _ArraySearch($aHostsDomains, $sDomain) = -1 Then
			_ArrayAdd($aNewDomains, $sDomain)
		EndIf
	Next

	If UBound($aNewDomains) = 0 Then
		Return 0
	EndIf

	Local $sPrompt = "在 DNS 缓存中发现 " & UBound($aNewDomains) & " 个新的 adobestats.io 域名:" & @CRLF & _
			_ArrayToString($aNewDomains, @CRLF) & @CRLF & "是否添加到 hosts 文件?"
	Local $iResponse = MsgBox($MB_YESNO + $MB_ICONQUESTION, "检测到新域名", $sPrompt)
	If $iResponse = $IDNO Then
		MemoWrite("用户拒绝添加新 DNS 域名." & @CRLF)
		Return 0
	EndIf

	Return $aNewDomains
EndFunc

Func UpdateHostsFile()
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	RemoveHostsEntries()
	GUICtrlSetState($idBtnUpdateHosts, $GUI_DISABLE)
	MemoWrite(@CRLF & "开始更新 hosts 文件..." & @CRLF)

	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = $sHostsPath & ".bak"
	Local $sMarkerStart = "# START - Adobe Blocklist"
	Local $sMarkerEnd = "# END - Adobe Blocklist"
	Local $sDomainListURL = $sCurrentDomainListURL
	Local $sTempFileDownload, $sDomainList, $sHostsContent, $hFile

	FileSetAttrib($sHostsPath, "-R")

	If Not FileExists($sBackupPath) Then
		If Not FileCopy($sHostsPath, $sBackupPath, 1) Then
			MemoWrite("无法创建 hosts 文件备份." & @CRLF)
			GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
			FileSetAttrib($sHostsPath, "+R")
			Return
		EndIf
		MemoWrite("已备份 hosts 文件." & @CRLF)
	EndIf

	$sTempFileDownload = _TempFile(@TempDir & "\domain_list")
	Local $iInetResult = InetGet($sDomainListURL, $sTempFileDownload, 1)
	If @error Or $iInetResult = 0 Then
		MemoWrite("下载失败: " & @error & ", InetGet 返回结果: " & $iInetResult & @CRLF)
		FileDelete($sTempFileDownload)
		GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	$sDomainList = FileRead($sTempFileDownload)
	FileDelete($sTempFileDownload)
	MemoWrite("已下载屏蔽列表:" & @CRLF & $sDomainList & @CRLF)

	$sHostsContent = FileRead($sHostsPath)
	If @error Then
		MemoWrite("无法读取 hosts 文件." & @CRLF)
		GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	$sHostsContent = StringStripWS($sHostsContent, 2)

	Local $sNewContent = $sMarkerStart & @CRLF & $sDomainList & @CRLF & $sMarkerEnd
	If StringLen($sHostsContent) > 0 Then
		$sHostsContent &= @CRLF & $sNewContent
	Else
		$sHostsContent = $sNewContent
	EndIf

	MemoWrite(@CRLF & "正在扫描 DNS 缓存以查找更多 adobestats.io 子域名..." & @CRLF)
	Local $aDNSDomainsAdded = ScanDNSCache($sHostsContent)
	If IsArray($aDNSDomainsAdded) And UBound($aDNSDomainsAdded) > 0 Then
		Local $sDNSEntries = ""
		For $i = 0 To UBound($aDNSDomainsAdded) - 1
			$sDNSEntries &= "0.0.0.0 " & $aDNSDomainsAdded[$i] & @CRLF
		Next
		$sHostsContent = StringRegExpReplace($sHostsContent, "(?s)(" & $sMarkerStart & ".*?)(" & $sMarkerEnd & ")", "$1" & $sDNSEntries & "$2")
		MemoWrite("从 DNS 缓存添加:" & @CRLF & _ArrayToString($aDNSDomainsAdded, @CRLF) & @CRLF)
		LogWrite(1, "从 DNS 缓存添加: " & _ArrayToString($aDNSDomainsAdded, ", ") & @CRLF)
	Else
		MemoWrite("在 DNS 缓存中未找到新的 adobestats.io 域名." & @CRLF)
	EndIf

	$hFile = FileOpen($sHostsPath, 2)
	If $hFile = -1 Then
		Local $iLastError = _WinAPI_GetLastError()
		MemoWrite("无法以追加模式打开 hosts 文件: 错误码 = " & $iLastError & @CRLF)
		GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf
	FileWrite($hFile, $sHostsContent)
	FileClose($hFile)

	FileSetAttrib($sHostsPath, "+R")
	LogWrite(1, "成功更新 hosts 文件." & @CRLF)
	ToggleLog(1)
	GUICtrlSetState($idBtnUpdateHosts, $GUI_ENABLE)
EndFunc

Func EditHosts()
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = @WindowsDir & "\System32\drivers\etc\hosts.bak"

	FileSetAttrib($sHostsPath, "-R")

	If Not FileExists($sBackupPath) Then
		FileCopy($sHostsPath, $sBackupPath)
	EndIf

	Local $iPID = Run("notepad.exe " & $sHostsPath)
	If $iPID = 0 Then
		MemoWrite("无法启动记事本." & @CRLF)
		FileSetAttrib($sHostsPath, "+R")
		Return
	EndIf

	Local $iTimeout = 300000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 记事本超时 " & $iTimeout / 1000 & " 秒." & @CRLF)
	EndIf

	FileSetAttrib($sHostsPath, "+R")
EndFunc

Func RestoreHosts()
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite(@CRLF & "正在从备份中还原 hosts 文件..." & @CRLF & "---" & @CRLF & "请稍候..." & @CRLF)
	Local $sHostsPath = @WindowsDir & "\System32\drivers\etc\hosts"
	Local $sBackupPath = @WindowsDir & "\System32\drivers\etc\hosts.bak"

	If FileExists($sBackupPath) Then
		FileSetAttrib($sHostsPath, "-R")
		If FileCopy($sBackupPath, $sHostsPath, 1) Then
			FileSetAttrib($sHostsPath, "+R")
			FileDelete($sBackupPath)
			LogWrite(1, "从备份中还原 hosts 文件: 命令执行成功!" & @CRLF)
		Else
			MemoWrite("无法从备份中还原 hosts 文件." & @CRLF)
			FileSetAttrib($sHostsPath, "+R")
			LogWrite(1, "从备份中还原 hosts: 命令执行失败." & @CRLF)
		EndIf
	Else
		LogWrite(1, "从备份中还原 hosts 文件: 未找到备份文件." & @CRLF)
	EndIf
	ToggleLog(1)
EndFunc

Func CheckThirdPartyFirewall()
	Local $sCmd = "powershell.exe -Command ""Get-CimInstance -ClassName FirewallProduct -Namespace 'root\SecurityCenter2' | Where-Object { $_.ProductName -notlike '*Windows*' } | Select-Object -Property ProductName"""
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 第三方防火墙检查超时 " & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	$sOutput = StringStripWS($sOutput, 3)
	$sOutput = StringRegExpReplace($sOutput, "[\r\n\t ]+", " ")
	$sOutput = StringStripWS($sOutput, 3)
	If $sOutput <> "" Then
		$g_sThirdPartyFirewall = $sOutput
		MemoWrite("检测到第三方防火墙: " & $g_sThirdPartyFirewall)
		Return True
	Else
		$g_sThirdPartyFirewall = ""
		MemoWrite("Windows 防火墙已是默认防火墙.")
		Return False
	EndIf
EndFunc

Func FindApps($bForLocalDLL = False, $sBasePathOverride = "")
	Local $sBase = ($sBasePathOverride <> "") ? $sBasePathOverride : $MyDefPath

	Local $tFirewallPaths = IniReadSection($sINIPath, "FirewallTrust")
	If @error Then
		MemoWrite("无法读取配置文件的 [FirewallTrust] 一节.")
		LogWrite(1, "无法读取配置文件中的 [FirewallTrust] 一节.")
		Local $empty[0]
		Return $empty
	EndIf

	Local $foundFiles[0]
	For $i = 1 To $tFirewallPaths[0][0]
		Local $relativePath = StringReplace($tFirewallPaths[$i][1], '"', "")
		If StringLeft($relativePath, 1) = "\" Then $relativePath = StringTrimLeft($relativePath, 1)
		Local $basePath = StringRegExpReplace($sBase & "\" & $relativePath, "\\\\+", "\\")
		If StringStripWS($basePath, 3) = "" Then ContinueLoop

		If $bForLocalDLL And (StringInStr($basePath, "AcroCEF.exe", 0) Or StringInStr($basePath, "Acrobat.exe", 0)) Then
			ContinueLoop
		EndIf

		If StringInStr($basePath, "*") Then
			Local $pathParts = StringSplit($basePath, "\", 1)
			Local $searchDir = ""
			For $j = 1 To $pathParts[0] - 1
				If StringInStr($pathParts[$j], "*") Then
					$searchDir = StringTrimRight($searchDir, 1)
					Local $searchPattern = StringReplace($pathParts[$j], "*", "*")
					Local $subPath = StringMid($basePath, StringInStr($basePath, $pathParts[$j]) + StringLen($pathParts[$j]))
					Local $HSEARCH = FileFindFirstFile($searchDir & "\" & $searchPattern)
					If $HSEARCH = -1 Then ContinueLoop
					While 1
						Local $folder = FileFindNextFile($HSEARCH)
						If @error Then ExitLoop
						Local $fullPath = $searchDir & "\" & $folder & $subPath
						$fullPath = StringRegExpReplace($fullPath, "\\\\+", "\\")
						If FileExists($fullPath) And StringStripWS($fullPath, 3) <> "" Then
							_ArrayAdd($foundFiles, $fullPath)
						EndIf
					WEnd
					FileClose($HSEARCH)
					ExitLoop
				Else
					$searchDir &= $pathParts[$j] & "\"
				EndIf
			Next
		Else
			If FileExists($basePath) And StringStripWS($basePath, 3) <> "" Then
				_ArrayAdd($foundFiles, $basePath)
			EndIf
		EndIf
	Next

	If UBound($foundFiles) > 0 Then
		$foundFiles = _ArrayUnique($foundFiles, 0, 0, 0, 0)
		Local $cleanedFiles[0]
		For $file In $foundFiles
			If StringStripWS($file, 3) <> "" And Not StringIsInt($file) Then
				_ArrayAdd($cleanedFiles, $file)
			EndIf
		Next
		$foundFiles = $cleanedFiles
	EndIf

	Return $foundFiles
EndFunc

Func RuleExists($ruleName)
	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -DisplayName ''Adobe-Block - ' & $ruleName & ''' | Measure-Object | Select-Object -ExpandProperty Count"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD)
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		LogWrite(1, "警告: 规则 '" & $ruleName & "' 的检查超时 " & $iTimeout & "ms.")
	EndIf
	Local $sOutput = StdoutRead($iPID)
	Return Number(StringStripWS($sOutput, 3)) > 0
EndFunc

Func ShowFirewallStatus()
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite("正在检查 Windows 防火墙状态...")
	LogWrite(1, "正在检查 Windows 防火墙状态...")

	MemoWrite("正在扫描防火墙配置文件...")
	Local $sProfileCmd = 'powershell.exe -Command "Get-NetFirewallProfile | Select-Object -Property Name,Enabled | Format-Table -HideTableHeaders"'
	Local $iPID = Run(@ComSpec & " /c " & $sProfileCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sProfileOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 防火墙配置文件检查超时 " & $iTimeout & "ms.")
	EndIf
	$sProfileOutput = StdoutRead($iPID)

	Local $aProfiles = StringSplit(StringStripWS($sProfileOutput, 3), @CRLF, 1)
	Local $sProfileSummary = ""
	For $i = 1 To $aProfiles[0]
		Local $line = StringStripWS($aProfiles[$i], 3)
		If $line <> "" Then
			Local $aParts = StringRegExp($line, "^(\S+)\s+(\S+)$", 1)
			If @error = 0 Then
				Local $profileName = $aParts[0]
				Local $enabled = $aParts[1]
				Switch $profileName
					Case "Domain"
						$profileName = "域网络"
					Case "Private"
						$profileName = "专用网络"
					Case "Public"
						$profileName = "公用网络"
				EndSwitch
				$sProfileSummary &= $profileName & ": " & ($enabled = "True" ? "已启用" : "已禁用") & @CRLF
			EndIf
		EndIf
	Next
	MemoWrite("防火墙配置文件:" & @CRLF & StringTrimRight($sProfileSummary, StringLen(@CRLF)))
	LogWrite(1, "防火墙配置文件 - " & StringReplace(StringTrimRight($sProfileSummary, StringLen(@CRLF)), @CRLF, " | "))

	MemoWrite("正在检查防火墙服务...")
	Local $sServiceCmd = 'powershell.exe -Command "Get-Service MpsSvc | Select-Object -Property Status,DisplayName | Format-List"'
	$iPID = Run(@ComSpec & " /c " & $sServiceCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sServiceOutput = ""
	$iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 防火墙服务检查超时 " & $iTimeout & "ms.")
	EndIf
	$sServiceOutput = StdoutRead($iPID)

	Local $sServiceStatus = "未知"
	Local $aServiceLines = StringSplit(StringStripWS($sServiceOutput, 3), @CRLF, 1)
	For $line In $aServiceLines
		If StringInStr($line, "Status") Then
			Local $aStatus = StringSplit($line, ":", 1)
			If $aStatus[0] > 1 Then
				$sServiceStatus = StringStripWS($aStatus[2], 3)
			EndIf
			ExitLoop
		EndIf
	Next
	Switch $sServiceStatus
		Case "Stopped"
			$sServiceStatus = "已停止"
		Case "StartPending"
			$sServiceStatus = "正在启动"
		Case "StopPending"
			$sServiceStatus = "正在停止"
		Case "Running"
			$sServiceStatus = "正在运行"
		Case "ContinuePending"
			$sServiceStatus = "正在继续"
		Case "PausePending"
			$sServiceStatus = "正在暂停"
		Case "Paused"
			$sServiceStatus = "已暂停"
	EndSwitch
	MemoWrite("防火墙服务 (MpsSvc): " & $sServiceStatus)
	LogWrite(1, "防火墙服务 (MpsSvc): " & $sServiceStatus)
EndFunc

Func RemoveFirewallRules()
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
	MemoWrite("开始删除防火墙规则...")
	LogWrite(1, "开始删除防火墙规则.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("检测到第三方防火墙，不支持删除规则.")
		LogWrite(1, "检测到第三方防火墙" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "." & @CRLF & "此功能仅支持 Windows 防火墙.")
		LogWrite(1, "已完成防火墙规则删除任务." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("正在扫描防火墙规则...")
	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 规则扫描超时 " & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	Local $aRules = StringSplit(StringStripWS($sOutput, 3), @CRLF, 1)
	Local $iRuleCount = 0
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then $iRuleCount += 1
	Next

	If $iRuleCount = 0 Then
		MemoWrite("未找到防火墙规则.")
		LogWrite(1, "未找到要删除的防火墙规则.")
		LogWrite(1, "已完成防火墙规则删除任务." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("删除 " & $iRuleCount & " 条规则...")
	LogWrite(1, "删除 " & $iRuleCount & " 条规则:")
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then
			LogWrite(1, "- " & StringStripWS($aRules[$i], 3))
		EndIf
	Next

	Local $sRemoveCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Remove-NetFirewallRule"'
	Local $iPIDRemove = Run($sRemoveCmd, "", @SW_HIDE, $STDERR_CHILD)
	$iWaitResult = ProcessWaitClose($iPIDRemove, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPIDRemove)
		MemoWrite("警告: 规则删除超时 " & $iTimeout & "ms.")
		LogWrite(1, "错误: 规则删除超时.")
	ElseIf @error Then
		MemoWrite("无法删除防火墙规则.")
		LogWrite(1, "无法删除防火墙规则.")
	Else
		MemoWrite("成功删除防火墙规则.")
		LogWrite(1, "成功删除防火墙规则.")
	EndIf

	LogWrite(1, "已完成防火墙规则删除任务." & @CRLF)
	ToggleLog(1)
EndFunc

Func CreateFirewallRules()
	MemoWrite("开始创建防火墙规则...")
	LogWrite(1, "开始创建防火墙规则.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("检测到第三方防火墙，跳过 GUI 并列出找到的软件.")
		Local $foundApps = FindApps()
		If UBound($foundApps) = 0 Then
			LogWrite(1, "找不到需要阻止联网的 Adobe 软件.")
		Else
			LogWrite(1, "已找到 " & UBound($foundApps) & " 个 Adobe 软件:")
			For $app In $foundApps
				LogWrite(1, "- " & $app)
			Next
			LogWrite(1, "检测到第三方防火墙" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & ". 请手动将这些路径添加到您的防火墙.")
		EndIf
		LogWrite(1, "已完成防火墙规则创建任务." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("正在扫描 Adobe 软件...")
	Local $foundApps = FindApps()
	Local $SelectedApps = ShowAppSelectionGUI($foundApps)

	If $SelectedApps = -1 Then
		Return
	ElseIf Not IsArray($SelectedApps) Then
		MemoWrite("防火墙规则任务被用户取消.")
		LogWrite(1, "防火墙规则任务被用户取消." & @CRLF)
		Return
	EndIf

	ShowFirewallStatus()
	_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)

	If UBound($SelectedApps) = 0 Then
		MemoWrite("用户未选择任何软件.")
		LogWrite(1, "未选择任何软件.")
		LogWrite(1, "已完成防火墙规则创建任务." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("用户选择了 " & UBound($SelectedApps) & " 个文件.")
	Local $psCmdComposite = ""
	Local $rulesAdded = 0
	Local $addedApps[0]
	For $app In $SelectedApps
		$app = StringStripWS($app, 3)
		If $app = "" Then
			MemoWrite("跳过空白或无效的路径.")
			ContinueLoop
		EndIf
		If FileExists($app) Then
			Local $ruleName = $app
			If Not RuleExists($ruleName) Then
				Local $ruleCmd = "New-NetFirewallRule -DisplayName 'Adobe-Block - " & $ruleName & "' -Direction Outbound -Program '" & $app & "' -Action Block;"
				$psCmdComposite &= $ruleCmd
				MemoWrite("添加防火墙规则: " & $app)
				_ArrayAdd($addedApps, $app)
				$rulesAdded += 1
			Else
				MemoWrite("已存在防火墙规则: " & $app & " - 跳过.")
			EndIf
		Else
			MemoWrite("找不到文件: " & $app)
			LogWrite(1, "找不到文件: " & $app)
		EndIf
	Next

	If $rulesAdded > 0 Then
		LogWrite(1, "已选择 " & $rulesAdded & " 个文件来创建防火墙规则:")
		For $app In $addedApps
			LogWrite(1, "- " & $app)
		Next
		Local $iPID = Run('powershell.exe -Command "' & $psCmdComposite & '"', "", @SW_HIDE, $STDERR_CHILD)
		Local $iTimeout = 10000
		Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
		If $iWaitResult = 0 Then
			ProcessClose($iPID)
			MemoWrite("警告: 规则创建超时 " & $iTimeout & "ms.")
			LogWrite(1, "错误: 规则创建超时.")
		ElseIf @error Then
			MemoWrite("无法应用防火墙规则.")
			LogWrite(1, "无法应用防火墙规则.")
		Else
			MemoWrite("成功应用防火墙规则.")
			LogWrite(1, "成功应用防火墙规则.")
		EndIf
	Else
		MemoWrite("无需添加新的防火墙规则.")
		LogWrite(1, "无需添加新的防火墙规则 (所有规则均已存在).")
	EndIf

	LogWrite(1, "已完成防火墙规则创建任务." & @CRLF)
	ToggleLog(1)
EndFunc

Func ShowAppSelectionGUI($foundFiles)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("错误: 路径无效: " & $MyDefPath)
		LogWrite(1, "错误: 路径无效: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("找不到文件: " & $MyDefPath)
		LogWrite(1, "找不到文件: " & $MyDefPath)
		ToggleLog(1)
		Return -1
	EndIf

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 500) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 400) / 2
	Local $hGUI = GUICreate("选择要断网的文件", 500, 400, $iPopupX, $iPopupY)
	Local $hSelectAll = GUICtrlCreateCheckbox("全选", 10, 10)
	Local $hTreeView = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hOkButton = GUICtrlCreateButton("确定", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)

	Local $defPathClean = StringStripWS($MyDefPath, 3)
	If StringRight($defPathClean, 1) = "\" Then
		$defPathClean = StringTrimRight($defPathClean, 1)
	EndIf
	Local $defPathParts = StringSplit($defPathClean, "\", 1)
	Local $defPathDepth = $defPathParts[0]

	Local $appNodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundFiles
		Local $fileNoBak = StringRegExpReplace(StringReplace($file, ".bak", ""), "\\\\+", "\\")
		Local $fileParts = StringSplit($fileNoBak, "\", 1)
		Local $appName = "未知"
		If $fileParts[0] >= $defPathDepth + 1 Then
			$appName = $fileParts[$defPathDepth + 1]
		Else
			LogWrite(1, "警告: 配置里的匹配路径不够完整，暂时归类到未知: " & $fileNoBak)
		EndIf

		If Not $appNodes.Exists($appName) Then
			Local $hAppNode = GUICtrlCreateTreeViewItem($appName, $hTreeView)
			$appNodes($appName) = $hAppNode
			_GUICtrlTreeView_SetChecked($hTreeView, $hAppNode, False)
		EndIf
		Local $hItem = GUICtrlCreateTreeViewItem($file, $appNodes($appName))
		_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
	Next
	LogWrite(1, "已从 " & $appNodes.Count & " 个软件中找出 " & UBound($foundFiles) & " 个文件.")

	Global $prevStates = ObjCreate("Scripting.Dictionary")
	Global $ghTreeView = $hTreeView
	Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
			$prevStates($itemText) = False
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 100)

	Local $bPaused = False
	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hGUI)
				Return ""
			Case $hSelectAll
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedState = (GUICtrlRead($hSelectAll) = $GUI_CHECKED)
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
						$prevStates($itemText) = $checkedState
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 100)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $SelectedApps[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				MemoWrite("正在扫描所选项...")
				While $hItem <> 0
					If _GUICtrlTreeView_GetChecked($hTreeView, $hItem) Then
						Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
						Local $childCount = _GUICtrlTreeView_GetChildCount($hTreeView, $hItem)
						If $childCount = -1 And StringStripWS($itemText, 3) <> "" Then
							_ArrayAdd($SelectedApps, $itemText)
						EndIf
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				MemoWrite("已选择 " & UBound($SelectedApps) & " 个文件要添加到防火墙规则.")
				GUIDelete($hGUI)
				Return $SelectedApps
			Case $GUI_EVENT_PRIMARYDOWN
				Local $aCursor = GUIGetCursorInfo($hGUI)
				If IsArray($aCursor) And $aCursor[4] = $hTreeView Then
					If Not $bPaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bPaused = True
					EndIf
				EndIf
			Case Else
				If $bPaused Then
					AdlibRegister("CheckParentCheckboxes", 100)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc

Func CheckParentCheckboxes()
	Local $hItem = _GUICtrlTreeView_GetFirstItem($ghTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($ghTreeView, $hItem)
		Local $childCount = _GUICtrlTreeView_GetChildCount($ghTreeView, $hItem)
		If $childCount > 0 Then
			If IsObj($g_mBlockedParents) And $g_mBlockedParents.Exists($itemText) Then
				_GUICtrlTreeView_SetChecked($ghTreeView, $hItem, False)
				Local $hBC = _GUICtrlTreeView_GetFirstChild($ghTreeView, $hItem)
				While $hBC <> 0
					_GUICtrlTreeView_SetChecked($ghTreeView, $hBC, False)
					$hBC = _GUICtrlTreeView_GetNextChild($ghTreeView, $hBC)
				WEnd
				$prevStates($itemText) = False
				$hItem = _GUICtrlTreeView_GetNext($ghTreeView, $hItem)
				ContinueLoop
			EndIf

			Local $currentState = _GUICtrlTreeView_GetChecked($ghTreeView, $hItem)
			Local $prevState = $prevStates($itemText)
			If $currentState <> $prevState Then
				$prevStates($itemText) = $currentState
				Local $hChild = _GUICtrlTreeView_GetFirstChild($ghTreeView, $hItem)
				While $hChild <> 0
					_GUICtrlTreeView_SetChecked($ghTreeView, $hChild, $currentState)
					$hChild = _GUICtrlTreeView_GetNextChild($ghTreeView, $hChild)
				WEnd
			EndIf
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($ghTreeView, $hItem)
	WEnd
EndFunc

Func ShowToggleRulesGUI()
	MemoWrite("正在打开防火墙规则开关窗口...")

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 150) / 2
	Local $hToggleGUI = GUICreate("防火墙规则开关", 300, 150, $iPopupX, $iPopupY)
	Local $hEnableButton = GUICtrlCreateButton("全部启用", 50, 50, 100, 30)
	Local $hDisableButton = GUICtrlCreateButton("全部禁用", 150, 50, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("取消", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hCancelButton
				MemoWrite("防火墙规则开关操作被取消.")
				GUIDelete($hToggleGUI)
				Return
			Case $hEnableButton
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				GUIDelete($hToggleGUI)
				EnableAllFWRules()
				Return
			Case $hDisableButton
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				GUIDelete($hToggleGUI)
				DisableAllFWRules()
				Return
		EndSwitch
	WEnd
EndFunc

Func EnableAllFWRules()
	MemoWrite("正在启用所有 GenP 防火墙规则...")
	LogWrite(1, "开始启用所有 GenP 防火墙规则.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("检测到第三方防火墙，无法修改规则.")
		LogWrite(1, "检测到第三方防火墙" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "." & @CRLF & "此功能仅支持 Windows 防火墙.")
		LogWrite(1, "已完成防火墙规则启用任务." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 规则扫描超时 " & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	Local $aRules = StringSplit(StringStripWS($sOutput, 3), @CRLF, 1)
	Local $iRuleCount = 0
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then $iRuleCount += 1
	Next

	If $iRuleCount = 0 Then
		MemoWrite("找不到可启用的 GenP 防火墙规则.")
		LogWrite(1, "找不到 GenP 防火墙规则.")
		LogWrite(1, "已完成防火墙规则启用任务." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("正在启用 " & $iRuleCount & " 条 Adobe-Block 规则...")
	LogWrite(1, "正在启用 " & $iRuleCount & " 条规则:")
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then
			LogWrite(1, "- " & StringStripWS($aRules[$i], 3))
		EndIf
	Next

	Local $sEnableCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Enable-NetFirewallRule"'
	Local $iPIDEnable = Run($sEnableCmd, "", @SW_HIDE, $STDERR_CHILD)
	$iWaitResult = ProcessWaitClose($iPIDEnable, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPIDEnable)
		MemoWrite("警告: 规则启用超时 " & $iTimeout & "ms.")
		LogWrite(1, "错误: 规则启用超时.")
	ElseIf @error Then
		MemoWrite("无法启用防火墙规则.")
		LogWrite(1, "无法启用防火墙规则.")
	Else
		MemoWrite("成功启用所有 GenP 防火墙规则.")
		LogWrite(1, "成功启用所有 GenP 防火墙规则.")
	EndIf

	LogWrite(1, "已完成防火墙规则启用任务." & @CRLF)
	ToggleLog(1)
EndFunc

Func DisableAllFWRules()
	MemoWrite("正在禁用所有 GenP 防火墙规则...")
	LogWrite(1, "开始禁用所有 GenP 防火墙规则.")

	If CheckThirdPartyFirewall() Then
		MemoWrite("检测到第三方防火墙，无法修改规则.")
		LogWrite(1, "检测到第三方防火墙" & ($g_sThirdPartyFirewall <> "" ? " (" & $g_sThirdPartyFirewall & ")" : "") & "." & @CRLF & "此功能仅支持 Windows 防火墙.")
		LogWrite(1, "已完成防火墙规则禁用任务." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	Local $sCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Select-Object -Property DisplayName"'
	Local $iPID = Run(@ComSpec & " /c " & $sCmd, "", @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
	Local $sOutput = ""
	Local $iTimeout = 5000
	Local $iWaitResult = ProcessWaitClose($iPID, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPID)
		MemoWrite("警告: 规则扫描超时 " & $iTimeout & "ms.")
	EndIf
	$sOutput = StdoutRead($iPID)

	Local $aRules = StringSplit(StringStripWS($sOutput, 3), @CRLF, 1)
	Local $iRuleCount = 0
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then $iRuleCount += 1
	Next

	If $iRuleCount = 0 Then
		MemoWrite("找不到可禁用的 GenP 防火墙规则.")
		LogWrite(1, "找不到 GenP 防火墙规则.")
		LogWrite(1, "已完成防火墙规则禁用任务." & @CRLF)
		ToggleLog(1)
		Return
	EndIf

	MemoWrite("正在禁用 " & $iRuleCount & " 条 Adobe-Block 规则...")
	LogWrite(1, "正在禁用 " & $iRuleCount & " 条规则:")
	For $i = 1 To $aRules[0]
		If StringInStr($aRules[$i], "Adobe-Block") Then
			LogWrite(1, "- " & StringStripWS($aRules[$i], 3))
		EndIf
	Next

	Local $sDisableCmd = 'powershell.exe -Command "Get-NetFirewallRule -Direction Outbound | Where-Object { $_.DisplayName -like ''Adobe-Block*'' } | Disable-NetFirewallRule"'
	Local $iPIDDisable = Run($sDisableCmd, "", @SW_HIDE, $STDERR_CHILD)
	$iWaitResult = ProcessWaitClose($iPIDDisable, $iTimeout)
	If $iWaitResult = 0 Then
		ProcessClose($iPIDDisable)
		MemoWrite("警告: 规则禁用超时 " & $iTimeout & "ms.")
		LogWrite(1, "错误: 规则禁用超时.")
	ElseIf @error Then
		MemoWrite("无法禁用防火墙规则.")
		LogWrite(1, "无法禁用防火墙规则.")
	Else
		MemoWrite("成功禁用所有 GenP 防火墙规则.")
		LogWrite(1, "成功禁用所有 GenP 防火墙规则.")
	EndIf

	LogWrite(1, "已完成防火墙规则禁用任务." & @CRLF)
	ToggleLog(1)
EndFunc

Func FindRuntimeInstallerFiles()
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("错误: 路径无效: " & $MyDefPath)
		LogWrite(1, "错误: 路径无效: " & $MyDefPath)
		Local $empty[0]
		ToggleLog(1)
		Return $empty
	EndIf

	Local $tRuntimePaths = IniReadSection($sINIPath, "RuntimeInstallers")
	Local $dllPaths[0]

	If @error Or $tRuntimePaths[0][0] = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("警告: 在 config.ini 配置文件中找不到 [RuntimeInstallers] 一节")
		LogWrite(1, "警告: 在 config.ini 配置文件中找不到 [RuntimeInstallers] 一节")
		Local $empty[0]
		ToggleLog(1)
		Return $empty
	EndIf

	ReDim $dllPaths[$tRuntimePaths[0][0]]
	For $i = 1 To $tRuntimePaths[0][0]
		Local $relativePath = StringReplace($tRuntimePaths[$i][1], '"', "")
		If StringLeft($relativePath, 1) = "\" Then $relativePath = StringTrimLeft($relativePath, 1)
		$dllPaths[$i - 1] = StringRegExpReplace($MyDefPath & "\" & $relativePath, "\\\\+", "\\")
	Next

	Local $foundFiles[0]
	For $basePath In $dllPaths
		If StringStripWS($basePath, 3) = "" Then ContinueLoop
		Local $pathParts = StringSplit($basePath, "\", 1)
		Local $searchDir = ""
		For $i = 1 To $pathParts[0] - 1
			If StringInStr($pathParts[$i], "*") Then
				$searchDir = StringTrimRight($searchDir, 1)
				Local $searchPattern = StringReplace($pathParts[$i], "*", "*")
				Local $subPath = StringMid($basePath, StringInStr($basePath, $pathParts[$i]) + StringLen($pathParts[$i]))
				Local $HSEARCH = FileFindFirstFile($searchDir & "\" & $searchPattern)
				If $HSEARCH = -1 Then
					ContinueLoop
				EndIf
				While 1
					Local $folder = FileFindNextFile($HSEARCH)
					If @error Then ExitLoop
					Local $fullPath = $searchDir & "\" & $folder & $subPath
					$fullPath = StringRegExpReplace($fullPath, "\\\\+", "\\")
					If FileExists($fullPath) And StringStripWS($fullPath, 3) <> "" Then
						_ArrayAdd($foundFiles, $fullPath)
					EndIf
				WEnd
				FileClose($HSEARCH)
				ExitLoop
			Else
				$searchDir &= $pathParts[$i] & "\"
			EndIf
		Next

		If Not StringInStr($basePath, "*") Then
			If FileExists($basePath) And StringStripWS($basePath, 3) <> "" Then
				_ArrayAdd($foundFiles, $basePath)
			EndIf
		EndIf
	Next

	If UBound($foundFiles) > 0 Then
		$foundFiles = _ArrayUnique($foundFiles, 0, 0, 0, 0)
	EndIf

	Return $foundFiles
EndFunc

Func UnpackRuntimeInstallers()
	MemoWrite("正在扫描 RuntimeInstaller.dll 文件...")
	Local $foundFiles = FindRuntimeInstallerFiles()

	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("找不到文件: " & $MyDefPath)
		LogWrite(1, "找不到文件: " & $MyDefPath)
		ToggleLog(1)
		Return
	EndIf

	Local $selectedFiles = RuntimeDllSelectionGUI($foundFiles, "Unpack")

	If Not IsArray($selectedFiles) Or UBound($selectedFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("未选择要解包的 RuntimeInstaller.dll 文件.")
		LogWrite(1, "未选择要解包的文件.")
		ToggleLog(1)
		Return
	EndIf

	Local $upxPath = @ScriptDir & "\upx.exe"
	If Not FileExists($upxPath) Then
		FileInstall("upx.exe", $upxPath, 1)
		If Not FileExists($upxPath) Then
			_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
			MemoWrite("错误: 无法将 upx.exe 解压到 " & $upxPath)
			LogWrite(1, "错误: 无法解压 upx.exe.")
			ToggleLog(1)
			Return
		EndIf
	EndIf

	MemoWrite("正在解包 " & UBound($selectedFiles) & " 个文件...")
	LogWrite(1, "正在解包 " & UBound($selectedFiles) & " 个文件:")
	Local $successCount = 0

	For $file In $selectedFiles
		$file = StringStripWS($file, 3)
		If $file = "" Or Not FileExists($file) Then
			MemoWrite("跳过无效或缺失的文件: " & $file)
			LogWrite(1, "跳过无效或缺失的文件: " & $file)
			ContinueLoop
		EndIf

		LogWrite(1, "处理: " & $file)

		If Not IsUPXPacked($file) Then
			MemoWrite("跳过: " & $file & " 未经 UPX 打包.")
			LogWrite(1, "跳过: " & $file & " 未经 UPX 打包.")
			ContinueLoop
		EndIf

		If Not PatchUPXHeader($file) Then
			MemoWrite("无法修正 UPX 段名: " & $file)
			LogWrite(1, "无法修正 UPX 段名: " & $file)
			ContinueLoop
		EndIf

		Local $iResult = RunWait('"' & $upxPath & '" -d "' & $file & '"', "", @SW_HIDE)
		If $iResult = 0 Then
			MemoWrite("解包成功: " & $file)
			LogWrite(1, "解包成功: " & $file)
			$successCount += 1
			Local $sBackupPath = $file & ".bak"
			If FileExists($sBackupPath) Then
				FileDelete($sBackupPath)
			EndIf
		Else
			MemoWrite("解包失败: " & $file & " (UPX 错误码: " & $iResult & ")")
			LogWrite(1, "解包失败: " & $file & " (UPX 错误码: " & $iResult & ")")
			Local $sBackupPath = $file & ".bak"
			If FileExists($sBackupPath) Then
				FileCopy($sBackupPath, $file, 1)
				FileDelete($sBackupPath)
				MemoWrite("已从备份中还原原始文件: " & $file)
				LogWrite(1, "已从备份中还原原始文件: " & $file)
			EndIf
		EndIf
	Next

	If FileExists($upxPath) Then
		If FileDelete($upxPath) Then
			MemoWrite("已从 " & $upxPath & " 中移除 upx.exe.")
		Else
			MemoWrite("警告: 无法从 " & $upxPath & " 中移除 upx.exe.")
			LogWrite(1, "警告: 无法从 " & $upxPath & " 中移除 upx.exe.")
		EndIf
	EndIf

	MemoWrite("解包结束，已成功处理 " & $successCount & " 个文件.")
	LogWrite(1, "已完成解包任务.")

	If $successCount > 0 Then
		LogWrite(1, $successCount & " 个文件已解包并可修补.")
	EndIf

	ToggleLog(1)
EndFunc

Func IsUPXPacked($sFilePath)
	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then
		LogWrite(1, "错误: 无法打开文件以进行 UPX 检查: " & $sFilePath)
		Return False
	EndIf

	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If @error Then
		LogWrite(1, "错误: 无法读取文件以进行 UPX 检查: " & $sFilePath)
		Return False
	EndIf

	Local $sHexData = String($bData)
	If StringInStr($sHexData, "55505821") Or StringInStr($sHexData, "007465787400") Or StringInStr($sHexData, "746578743100") Then
		Return True
	EndIf

	Return False
EndFunc

Func PatchUPXHeader($sFilePath)
	Local Const $sUPX0 = "005550583000"
	Local Const $sUPX1 = "555058310000"

	Local $aCustomHeaders1 = ["007465787400"]
	Local $aCustomHeaders2 = ["746578743100"]

	Local $sBackupPath = $sFilePath & ".bak"
	If Not FileCopy($sFilePath, $sBackupPath, 1) Then
		MemoWrite("错误: 无法创建备份: " & $sFilePath)
		LogWrite(1, "错误: 无法创建备份: " & $sFilePath)
		Return False
	EndIf

	Local $hFile = FileOpen($sFilePath, 16)
	If $hFile = -1 Then
		MemoWrite("错误: 无法打开文件以修补: " & $sFilePath)
		LogWrite(1, "错误: 无法打开文件以修补: " & $sFilePath)
		Return False
	EndIf
	Local $bData = FileRead($hFile)
	FileClose($hFile)
	If @error Then
		MemoWrite("错误: 无法读取文件以修补: " & $sFilePath)
		LogWrite(1, "错误: 无法读取文件以修补: " & $sFilePath)
		Return False
	EndIf

	Local $sHexData = String($bData)
	Local $bModified = False

	For $sHeader In $aCustomHeaders1
		If StringInStr($sHexData, $sHeader) Then
			$sHexData = StringReplace($sHexData, $sHeader, $sUPX0)
			$bModified = True
			ExitLoop
		EndIf
	Next

	For $sHeader In $aCustomHeaders2
		If StringInStr($sHexData, $sHeader) Then
			$sHexData = StringReplace($sHexData, $sHeader, $sUPX1)
			$bModified = True
			ExitLoop
		EndIf
	Next

	If Not $bModified Then
		MemoWrite("未找到自定义 UPX 段名: " & $sFilePath)
		FileDelete($sBackupPath)
		Return True
	EndIf

	Local $bModifiedData = Binary("0x" & StringMid($sHexData, 3))
	Local $hFileWrite = FileOpen($sFilePath, 18)
	If $hFileWrite = -1 Then
		MemoWrite("错误: 无法打开文件以写入: " & $sFilePath)
		LogWrite(1, "错误: 无法打开文件以写入: " & $sFilePath)
		FileCopy($sBackupPath, $sFilePath, 1)
		FileDelete($sBackupPath)
		Return False
	EndIf
	FileWrite($hFileWrite, $bModifiedData)
	FileClose($hFileWrite)
	If @error Then
		MemoWrite("错误: 无法写入修补完成的数据: " & $sFilePath)
		LogWrite(1, "错误: 无法写入修补完成的数据: " & $sFilePath)
		FileCopy($sBackupPath, $sFilePath, 1)
		FileDelete($sBackupPath)
		Return False
	EndIf

	MemoWrite("成功修正 UPX 段名: " & $sFilePath)
	Return True
EndFunc

Func RuntimeDllSelectionGUI($foundFiles, $operation)
	If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("错误: 路径无效: " & $MyDefPath)
		LogWrite(1, "错误: 路径无效: " & $MyDefPath)
		ToggleLog(1)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("找不到需要解包的 RuntimeInstaller.dll 文件.")
		LogWrite(1, "找不到需要解包的 RuntimeInstaller.dll 文件.")
		ToggleLog(1)
		Return ""
	EndIf

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 500) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 400) / 2
	Local $hGUI = GUICreate("RuntimeInstaller 解包", 500, 400, $iPopupX, $iPopupY)
	Local $hSelectAll = GUICtrlCreateCheckbox("全选", 10, 10)
	Local $hTreeView = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hOkButton = GUICtrlCreateButton("确定", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)

	Local $defPathClean = StringStripWS($MyDefPath, 3)
	If StringRight($defPathClean, 1) = "\" Then
		$defPathClean = StringTrimRight($defPathClean, 1)
	EndIf
	Local $defPathParts = StringSplit($defPathClean, "\", 1)
	Local $defPathDepth = $defPathParts[0]

	Local $appNodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundFiles
		Local $fileClean = StringRegExpReplace($file, "\\\\+", "\\")
		Local $fileParts = StringSplit($fileClean, "\", 1)
		Local $appName = "未知"
		If $fileParts[0] >= $defPathDepth + 1 Then
			$appName = $fileParts[$defPathDepth + 1]
		Else
			LogWrite(1, "警告: 配置里的匹配路径不够完整，暂时归类到未知: " & $fileClean)
		EndIf
		If Not $appNodes.Exists($appName) Then
			Local $hAppNode = GUICtrlCreateTreeViewItem($appName, $hTreeView)
			$appNodes($appName) = $hAppNode
			_GUICtrlTreeView_SetChecked($hTreeView, $hAppNode, False)
		EndIf
		Local $hItem = GUICtrlCreateTreeViewItem($fileClean, $appNodes($appName))
		_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
	Next

	Global $prevStates = ObjCreate("Scripting.Dictionary")
	Global $ghTreeView = $hTreeView
	Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
			$prevStates($itemText) = False
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 100)

	Local $bPaused = False
	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hGUI)
				MemoWrite("RuntimeInstaller 解包已取消.")
				LogWrite(1, "RuntimeInstaller 解包已取消.")
				Return ""
			Case $hSelectAll
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedState = (GUICtrlRead($hSelectAll) = $GUI_CHECKED)
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
						$prevStates($itemText) = $checkedState
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 100)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedFiles[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				While $hItem <> 0
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					Local $isChecked = _GUICtrlTreeView_GetChecked($hTreeView, $hItem)
					If $isChecked And StringInStr($itemText, "RuntimeInstaller.dll") Then
						_ArrayAdd($selectedFiles, $itemText)
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				GUIDelete($hGUI)
				If UBound($selectedFiles) = 0 Then
					_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
					MemoWrite("未选择要解包的 RuntimeInstaller.dll 文件.")
					LogWrite(1, "未选择要解包的 RuntimeInstaller.dll 文件.")
					ToggleLog(1)
					Return ""
				EndIf
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				Return $selectedFiles
			Case $GUI_EVENT_PRIMARYDOWN
				Local $aCursor = GUIGetCursorInfo($hGUI)
				If IsArray($aCursor) And $aCursor[4] = $hTreeView Then
					If Not $bPaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bPaused = True
					EndIf
				EndIf
			Case Else
				If $bPaused Then
					AdlibRegister("CheckParentCheckboxes", 100)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc

Func AddDevOverride()
	Local $sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $sValueName = "DevOverrideEnable"
	Local $iExpectedValue = 1
	If Not IsAdmin() Then
		MemoWrite("错误: 需要管理员权限才能设置注册表项.")
		LogWrite(1, "错误: 需要管理员权限才能访问注册表.")
		Return False
	EndIf
	Local $iCurrentValue = RegRead($sKey, $sValueName)
	If @error = 0 And $iCurrentValue = $iExpectedValue Then
		MemoWrite("注册表项 " & $sValueName & " 已经是启用的了.")
		LogWrite(1, "注册表项 " & $sValueName & " 已经是设为 " & $iExpectedValue & " 的了.")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "1")
		Return True
	EndIf
	If RegWrite($sKey, $sValueName, "REG_DWORD", $iExpectedValue) Then
		MemoWrite("已启用注册表项 " & $sValueName & " 以便进行 WinTrust 重定向.")
		LogWrite(1, "已设置注册表项 " & $sValueName & " = " & $iExpectedValue & ".")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "1")
		ShowRebootPopup()
		Return True
	Else
		MemoWrite("错误: 无法启用注册表项 " & $sValueName & ".")
		LogWrite(1, "错误: 无法设置注册表项 " & $sValueName & " (报错: " & @error & ").")
		Return False
	EndIf
EndFunc

Func RemoveDevOverride()
	Local $sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $sValueName = "DevOverrideEnable"
	Local $iExpectedValue = 1
	If Not IsAdmin() Then
		MemoWrite("错误: 需要管理员权限才能删除注册表项.")
		LogWrite(1, "错误: 需要管理员权限才能访问注册表.")
		Return False
	EndIf
	Local $iCurrentValue = RegRead($sKey, $sValueName)
	If @error <> 0 Then
		MemoWrite("不存在注册表项 " & $sValueName & " 可删.")
		LogWrite(1, "未找到注册表项 " & $sValueName & ".")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "0")
		Return True
	EndIf
	If $iCurrentValue <> $iExpectedValue Then
		MemoWrite("未启用注册表项 " & $sValueName & "，无需操作.")
		LogWrite(1, "注册表项 " & $sValueName & " 尚未设置为" & $iExpectedValue & ".")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "0")
		Return True
	EndIf
	If RegDelete($sKey, $sValueName) Then
		MemoWrite("已禁用注册表项 " & $sValueName & ".")
		LogWrite(1, "已删除注册表项 " & $sValueName & ".")
		IniWrite($patchStatesINI, "Info", "DevOverrideEnable", "0")
		ShowRebootPopup()
		Return True
	Else
		MemoWrite("错误: 无法禁用注册表项 " & $sValueName & ".")
		LogWrite(1, "错误: 无法删除注册表项 " & $sValueName & " (报错: " & @error & ").")
		Return False
	EndIf
EndFunc

Func ShowRebootPopup()
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 200) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 100) / 2
	Local $hPopup = GUICreate("", 200, 100, $iPopupX, $iPopupY, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOPMOST)
	GUICtrlCreateLabel("重启电脑后生效.", 10, 10, 180, 40, $SS_CENTER)
	Local $idOk = GUICtrlCreateButton("确定", 50, 60, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		If GUIGetMsg() = $idOk Then ExitLoop
	WEnd
	GUIDelete($hPopup)
EndFunc

Func ManageWinTrust()
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 150) / 2
	Local $hGUI = GUICreate("配置 WinTrust", 300, 150, $iPopupX, $iPopupY)
	Local $hTrustButton = GUICtrlCreateButton("修改", 50, 50, 100, 30)
	Local $hUntrustButton = GUICtrlCreateButton("还原", 150, 50, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("取消", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hCancelButton
				MemoWrite("WinTrust 配置已取消.")
				GUIDelete($hGUI)
				Return
			Case $hTrustButton
				GUIDelete($hGUI)
				TrustEXEs()
				Return
			Case $hUntrustButton
				GUIDelete($hGUI)
				UntrustEXEs()
				Return
		EndSwitch
	WEnd
EndFunc

Func _GetAfterFXVersion($sPathToExe)
	Local $aRet[2] = [0, 0]
	If Not FileExists($sPathToExe) Then Return $aRet
	Local $sVer = FileGetVersion($sPathToExe)
	If @error Or $sVer = "" Or StringRegExp($sVer, "^0\.0\.0\.0?") Then
		$sVer = FileGetVersion($sPathToExe, $FV_PRODUCTVERSION)
		If @error Then $sVer = ""
	EndIf
	If $sVer = "" Then Return $aRet
	Local $aParts = StringSplit($sVer, ".")
	If $aParts[0] >= 2 Then
		$aRet[0] = Number($aParts[1])
		$aRet[1] = Number($aParts[2])
	EndIf
	Return $aRet
EndFunc

Func _IsAEBlockedByVersion($iMajor, $iMinor)
	If $iMajor > 25 Then Return True
	If $iMajor = 25 And $iMinor >= 4 Then Return True
	Return False
EndFunc

Func _EvaluateAEBlock($hTreeView, $hParent, $sAppName)
	If Not StringInStr($sAppName, "After Effects") Then Return False

	Local $sAfterFXPath = ""
	Local $sAnyChildPath = ""
	Local $aChildPaths[0]
	Local $hChild = _GUICtrlTreeView_GetFirstChild($hTreeView, $hParent)
	While $hChild <> 0
		Local $sChildText = _GUICtrlTreeView_GetText($hTreeView, $hChild)
		_ArrayAdd($aChildPaths, $sChildText)
		If $sAnyChildPath = "" Then $sAnyChildPath = $sChildText
		If StringRegExp($sChildText, "(?i)\\AfterFX(Beta)?\.exe$") Then
			$sAfterFXPath = $sChildText
		EndIf
		$hChild = _GUICtrlTreeView_GetNextChild($hTreeView, $hChild)
	WEnd

	If $sAfterFXPath = "" Then
		If $sAnyChildPath <> "" Then
			Local $aMatch = StringRegExp($sAnyChildPath, "(?i)^(.*?\\Adobe After Effects[^\\]*\\)", 1)
			If IsArray($aMatch) Then
				Local $sAERoot = $aMatch[0]
				If FileExists($sAERoot & "Support Files\AfterFX.exe") Then
					$sAfterFXPath = $sAERoot & "Support Files\AfterFX.exe"
				ElseIf FileExists($sAERoot & "AfterFX.exe") Then
					$sAfterFXPath = $sAERoot & "AfterFX.exe"
				ElseIf FileExists($sAERoot & "Support Files\AfterFXBeta.exe") Then
					$sAfterFXPath = $sAERoot & "Support Files\AfterFXBeta.exe"
				ElseIf FileExists($sAERoot & "AfterFXBeta.exe") Then
					$sAfterFXPath = $sAERoot & "AfterFXBeta.exe"
				EndIf
			EndIf
		EndIf
	EndIf

	Local $aVer[2] = [0, 0]
	If $sAfterFXPath <> "" Then
		$aVer = _GetAfterFXVersion($sAfterFXPath)
	EndIf

	If $aVer[0] = 0 And $aVer[1] = 0 Then
		Local $sIniVer = ""

		$sIniVer = IniRead($patchStatesINI, "App_Version", $sAppName, "")

		If $sIniVer = "" Then
			Local $sStripName = StringRegExpReplace($sAppName, "^(?i)Adobe\s+", "")
			$sIniVer = IniRead($patchStatesINI, "App_Version", $sStripName, "")

			If $sIniVer = "" Then
				Local $sCore = StringRegExpReplace($sStripName, "\s*\(Beta\)", "")
				Local $bIsBeta = StringInStr($sStripName, "(Beta)") > 0
				Local $aSec = IniReadSection($patchStatesINI, "App_Version")
				If IsArray($aSec) Then
					For $k = 1 To $aSec[0][0]
						Local $sKey = $aSec[$k][0]
						If StringRegExp($sKey, "(?i)^" & $sCore & "(\s+\d{4})?(\s*\(Beta\))?$") Then
							Local $bKeyIsBeta = StringInStr($sKey, "(Beta)") > 0
							If $bKeyIsBeta = $bIsBeta Then
								$sIniVer = $aSec[$k][1]
								ExitLoop
							EndIf
						EndIf
					Next
				EndIf
			EndIf
		EndIf

		If $sIniVer <> "" Then
			Local $sIniStripped = StringRegExpReplace($sIniVer, "^v", "")
			Local $aIniParts = StringSplit($sIniStripped, ".")
			If $aIniParts[0] >= 2 Then
				$aVer[0] = Number($aIniParts[1])
				$aVer[1] = Number($aIniParts[2])
				LogWrite(1, "WinTrust: 已从 patch_states.ini 取得 '" & $sAppName & "' 的 AE 版本: v" & $aVer[0] & "." & $aVer[1])
			EndIf
		EndIf
	EndIf

	If $aVer[0] = 0 And $aVer[1] = 0 Then Return False
	If Not _IsAEBlockedByVersion($aVer[0], $aVer[1]) Then Return False

	Local $sNewLabel = $sAppName & "  (v25.4+ 不支持 WinTrust)"
	_GUICtrlTreeView_SetText($hTreeView, $hParent, $sNewLabel)
	If Not IsObj($g_mBlockedParents)  Then $g_mBlockedParents  = ObjCreate("Scripting.Dictionary")
	If Not IsObj($g_mBlockedAppPaths) Then $g_mBlockedAppPaths = ObjCreate("Scripting.Dictionary")
	$g_mBlockedParents.Item($sNewLabel) = True
	For $sPath In $aChildPaths
		$g_mBlockedAppPaths.Item(StringLower($sPath)) = True
	Next

	_GUICtrlTreeView_SetChecked($hTreeView, $hParent, False)
	$hChild = _GUICtrlTreeView_GetFirstChild($hTreeView, $hParent)
	While $hChild <> 0
		_GUICtrlTreeView_SetChecked($hTreeView, $hChild, False)
		$hChild = _GUICtrlTreeView_GetNextChild($hTreeView, $hChild)
	WEnd

	LogWrite(1, "WinTrust: 已阻止 AE 软件组 '" & $sAppName & "' (AfterFX.exe v" & $aVer[0] & "." & $aVer[1] & " 不支持 WinTrust)")
	Return True
EndFunc

Func FindTrustEXEs()
	Local $foundApps = FindApps(True, $g_sWinTrustPath)
	Local $foundEXEs[0]

	For $app In $foundApps
		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"
		If FileExists($dllPath) Then
			_ArrayAdd($foundEXEs, $app)
		EndIf
	Next

	Return $foundEXEs
EndFunc

Func FindUntrustedEXEs()
	Local $foundApps = FindApps(True, $g_sWinTrustPath)
	Local $foundEXEs[0]
	For $app In $foundApps
		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"
		If Not FileExists($dllPath) Then
			_ArrayAdd($foundEXEs, $app)
		EndIf
	Next
	Return $foundEXEs
EndFunc

Func TrustEXEs()
	MemoWrite("正在扫描可进行 WinTrust 修改的软件...")
	Local $foundApps = FindUntrustedEXEs()

	If UBound($foundApps) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("在 " & $g_sWinTrustPath & " 找不到需要修改的软件，所有可用软件都已经修改.")
		LogWrite(1, "找不到需要修改的软件: " & $g_sWinTrustPath)
		ToggleLog(1)
		Return
	EndIf

	Local $SelectedApps = TrustSelectionGUI($foundApps, "Trust")

	If Not IsArray($SelectedApps) Or UBound($SelectedApps) = 0 Then
		MemoWrite("未选择要修改的软件.")
		LogWrite(1, "未选择要修改的软件.")
		Return
	EndIf

	If Not AddDevOverride() Then
		MemoWrite("由于注册表错误，WinTrust 操作已终止.")
		Return
	EndIf

	Local $dllSourcePath = @ScriptDir & "\wintrust.dll"
	If Not FileExists($dllSourcePath) Or FileGetSize($dllSourcePath) <> 382712 Then
		FileInstall("wintrust.dll", $dllSourcePath, 1)
		If Not FileExists($dllSourcePath) Then
			MemoWrite("错误: 无法将 wintrust.dll 解压到 " & $dllSourcePath)
			LogWrite(1, "错误: 无法解压 wintrust.dll.")
			Return
		EndIf
	EndIf

	If FileGetSize($dllSourcePath) <> 382712 Then
		MemoWrite("错误: wintrust.dll 大小不匹配 (应为 382,712B).")
		LogWrite(1, "错误: wintrust.dll 大小不匹配 (应为 382,712B).")
		FileDelete($dllSourcePath)
		Return
	EndIf

	MemoWrite("正在修改 " & UBound($SelectedApps) & " 个软件...")
	LogWrite(1, "正在修改 " & UBound($SelectedApps) & " 个软件:")

	Local $successCount = 0
	For $app In $SelectedApps
		$app = StringStripWS($app, 3)
		If $app = "" Or Not FileExists($app) Then
			MemoWrite("跳过无效或缺失的文件: " & $app)
			LogWrite(1, "跳过无效或缺失的文件: " & $app)
			ContinueLoop
		EndIf
		If StringRegExp($app, "(?i)\\AfterFX(Beta)?\.exe$") Then
			Local $aAEVer = _GetAfterFXVersion($app)
			If _IsAEBlockedByVersion($aAEVer[0], $aAEVer[1]) Then
				MemoWrite("已跳过 " & $app & ": After Effects v" & $aAEVer[0] & "." & $aAEVer[1] & " 不支持 WinTrust 修改.")
				LogWrite(1, "已跳过不支持 WinTrust 的 AE 路径: " & $app & " (v" & $aAEVer[0] & "." & $aAEVer[1] & ")")
				ContinueLoop
			EndIf
		EndIf

		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"

		LogWrite(1, "- 处理: " & $app)

		If Not DirCreate($localDir) Then
			MemoWrite("无法创建目录: " & $localDir)
			LogWrite(1, "无法创建目录: " & $localDir)
			ContinueLoop
		EndIf

		If FileExists($dllPath) Then
			If FileGetSize($dllPath) = 382712 Then
				MemoWrite("wintrust.dll 已存在于: " & $dllPath & " - 跳过.")
				LogWrite(1, "wintrust.dll 已存在于: " & $dllPath & " - 跳过.")
				$successCount += 1
				Local $sAppGrp = _GetAppGroupName($app)
				If $sAppGrp <> "" Then $g_mWinTrustQueue.Item($sAppGrp) = "1"
			Else
				FileDelete($dllPath)
				If FileCopy($dllSourcePath, $dllPath, 1) And FileGetSize($dllPath) > 0 Then
					MemoWrite("wintrust.dll 已替换到: " & $dllPath)
					LogWrite(1, "wintrust.dll 已替换到: " & $dllPath)
					$successCount += 1
					Local $sAppGrp2 = _GetAppGroupName($app)
					If $sAppGrp2 <> "" Then $g_mWinTrustQueue.Item($sAppGrp2) = "1"
				Else
					MemoWrite("无法将 wintrust.dll 替换到: " & $dllPath)
					LogWrite(1, "无法将 wintrust.dll 替换到: " & $dllPath)
				EndIf
			EndIf
			ContinueLoop
		EndIf

		If FileCopy($dllSourcePath, $dllPath, 1) And FileGetSize($dllPath) > 0 Then
			MemoWrite("修改成功: " & $appName)
			LogWrite(1, "修改成功: " & $appName)
			$successCount += 1
			Local $sAppGrp3 = _GetAppGroupName($app)
			If $sAppGrp3 <> "" Then $g_mWinTrustQueue.Item($sAppGrp3) = "1"
		Else
			MemoWrite("修改失败: " & $appName)
			LogWrite(1, "修改失败: " & $appName)
		EndIf
	Next

	If FileExists($dllSourcePath) Then
		If FileDelete($dllSourcePath) Then
			MemoWrite("已从 " & $dllSourcePath & " 删除 wintrust.dll.")
		Else
			MemoWrite("警告: 无法从 " & $dllSourcePath & " 删除 wintrust.dll.")
		EndIf
	EndIf

	MemoWrite("修改已完成，已处理 " & $successCount & " / " & UBound($SelectedApps) & " 个软件.")
	LogWrite(1, "修改已完成，已处理 " & $successCount & " / " & UBound($SelectedApps) & " 个软件.")
	_WriteWinTrustImmediate()
	_SyncWinTrustFromDisk()
	_RefreshGroupHeadersFromWT()
	ToggleLog(1)
EndFunc

Func UntrustEXEs()
	MemoWrite("正在扫描已经过 WinTrust 修改的软件...")
	Local $foundEXEs = FindTrustEXEs()

	If UBound($foundEXEs) = 0 Then
		MemoWrite("找不到需要还原的软件.")
		LogWrite(1, "找不到需要还原的软件.")
		Return
	EndIf

	Local $SelectedApps = TrustSelectionGUI($foundEXEs, "Untrust")

	If Not IsArray($SelectedApps) Or UBound($SelectedApps) = 0 Then
		MemoWrite("未选择要还原的软件.")
		LogWrite(1, "未选择要还原的软件.")
		Return
	EndIf

	MemoWrite("正在还原 " & UBound($SelectedApps) & " 个软件...")
	LogWrite(1, "正在还原 " & UBound($SelectedApps) & " 个软件:")

	Local $successCount = 0
	For $app In $SelectedApps
		$app = StringStripWS($app, 3)
		If $app = "" Or Not FileExists($app) Then
			MemoWrite("跳过无效或缺失的文件: " & $app)
			LogWrite(1, "跳过无效或缺失的文件: " & $app)
			ContinueLoop
		EndIf

		Local $appDir = StringLeft($app, StringInStr($app, "\", 0, -1) - 1)
		Local $appName = StringMid($app, StringInStr($app, "\", 0, -1) + 1)
		Local $localDir = $appDir & "\" & $appName & ".local"
		Local $dllPath = $localDir & "\wintrust.dll"

		LogWrite(1, "- 处理: " & $app)

		If Not FileExists($dllPath) Then
			MemoWrite("未找到 wintrust.dll: " & $dllPath & " - 跳过.")
			LogWrite(1, "未找到 wintrust.dll: " & $dllPath & " - 跳过.")
			ContinueLoop
		EndIf

		If DirRemove($localDir, 1) Then
			MemoWrite("还原成功: " & $appName)
			LogWrite(1, "还原成功: " & $appName)
			$successCount += 1
			Local $sAppGrpU = _GetAppGroupName($app)
			If $sAppGrpU <> "" Then $g_mWinTrustQueue.Item($sAppGrpU) = "0"
		Else
			MemoWrite("还原失败: " & $appName)
			LogWrite(1, "还原失败: " & $appName)
		EndIf
	Next

	MemoWrite("还原已完成，已处理 " & $successCount & " / " & UBound($SelectedApps) & " 个软件.")
	LogWrite(1, "还原已完成，已处理 " & $successCount & " / " & UBound($SelectedApps) & " 个软件.")
	_WriteWinTrustImmediate()
	_SyncWinTrustFromDisk()
	_RefreshGroupHeadersFromWT()
	ToggleLog(1)
EndFunc

Func TrustSelectionGUI($foundFiles, $operation)
	Local $sOperationLabel = ($operation = "Trust") ? "修改" : "还原"
	If Not FileExists($g_sWinTrustPath) Or Not StringInStr(FileGetAttrib($g_sWinTrustPath), "D") Then
		MemoWrite("错误: WinTrust 路径无效: " & $g_sWinTrustPath)
		LogWrite(1, "错误: WinTrust 路径无效: " & $g_sWinTrustPath)
		Return ""
	EndIf
	If UBound($foundFiles) = 0 Then
		_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
		MemoWrite("在 " & $g_sWinTrustPath & " 找不到需要" & $sOperationLabel & "的软件.")
		LogWrite(1, "在 " & $g_sWinTrustPath & " 找不到需要" & $sOperationLabel & "的软件.")
		ToggleLog(1)
		Return ""
	EndIf

	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 500) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 400) / 2
	Local $hGUI = GUICreate("WinTrust " & $sOperationLabel, 500, 400, $iPopupX, $iPopupY)
	Local $hSelectAll = GUICtrlCreateCheckbox("全选", 10, 10)
	Local $hTreeView = GUICtrlCreateTreeView(10, 40, 480, 300, BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT))
	Local $hOkButton = GUICtrlCreateButton("确定", 200, 350, 100, 30)
	GUISetState(@SW_SHOW)

	$g_mBlockedParents  = ObjCreate("Scripting.Dictionary")
	$g_mBlockedAppPaths = ObjCreate("Scripting.Dictionary")

	Local $defPathClean = StringStripWS($g_sWinTrustPath, 3)
	If StringRight($defPathClean, 1) = "\" Then
		$defPathClean = StringTrimRight($defPathClean, 1)
	EndIf
	Local $defPathParts = StringSplit($defPathClean, "\", 1)
	Local $defPathDepth = $defPathParts[0]

	Local $iShownCount = 0
	Local $appNodes = ObjCreate("Scripting.Dictionary")
	For $file In $foundFiles
		Local $fileClean = StringRegExpReplace($file, "\\\\+", "\\")

		Local $appDir = StringLeft($fileClean, StringInStr($fileClean, "\", 0, -1) - 1)
		Local $appNameOnly = StringMid($fileClean, StringInStr($fileClean, "\", 0, -1) + 1)
		Local $dllPath = $appDir & "\" & $appNameOnly & ".local\wintrust.dll"
		Local $isCurrentlyTrusted = FileExists($dllPath)

		If $operation = "Trust" And $isCurrentlyTrusted Then ContinueLoop
		If $operation = "Untrust" And Not $isCurrentlyTrusted Then ContinueLoop

		Local $fileParts = StringSplit($fileClean, "\", 1)
		Local $appName = "未知"
		If $fileParts[0] >= $defPathDepth + 1 Then
			$appName = $fileParts[$defPathDepth + 1]
		Else
			LogWrite(1, "警告: 配置里的匹配路径不够完整，暂时归类到未知: " & $fileClean)
		EndIf
		If Not $appNodes.Exists($appName) Then
			Local $hAppNode = GUICtrlCreateTreeViewItem($appName, $hTreeView)
			$appNodes($appName) = $hAppNode
			_GUICtrlTreeView_SetChecked($hTreeView, $hAppNode, False)
		EndIf
		Local $hItem = GUICtrlCreateTreeViewItem($fileClean, $appNodes($appName))
		_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
	Next

	Local $hScanItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hScanItem <> 0
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hScanItem) > 0 Then
			Local $sParentText = _GUICtrlTreeView_GetText($hTreeView, $hScanItem)
			_EvaluateAEBlock($hTreeView, $hScanItem, $sParentText)
		EndIf
		$hScanItem = _GUICtrlTreeView_GetNext($hTreeView, $hScanItem)
	WEnd

	Global $prevStates = ObjCreate("Scripting.Dictionary")
	Global $ghTreeView = $hTreeView
	Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
	While $hItem <> 0
		Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
		If _GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0 Then
			$prevStates($itemText) = False
		EndIf
		$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
	WEnd
	AdlibRegister("CheckParentCheckboxes", 100)

	Local $bPaused = False
	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				AdlibUnRegister("CheckParentCheckboxes")
				GUIDelete($hGUI)
				MemoWrite($sOperationLabel & "已取消.")
				LogWrite(1, $sOperationLabel & "已取消.")
				Return ""
			Case $hSelectAll
				AdlibUnRegister("CheckParentCheckboxes")
				Local $checkedState = (GUICtrlRead($hSelectAll) = $GUI_CHECKED)
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				Local $sCurrentParent = ""
				While $hItem <> 0
					Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
					Local $bIsParent = (_GUICtrlTreeView_GetChildCount($hTreeView, $hItem) > 0)
					If $bIsParent Then $sCurrentParent = $itemText
					Local $bBlocked = False
					If IsObj($g_mBlockedParents) Then
						If $bIsParent And $g_mBlockedParents.Exists($itemText)        Then $bBlocked = True
						If (Not $bIsParent) And $g_mBlockedParents.Exists($sCurrentParent) Then $bBlocked = True
					EndIf
					If $bBlocked Then
						_GUICtrlTreeView_SetChecked($hTreeView, $hItem, False)
					Else
						_GUICtrlTreeView_SetChecked($hTreeView, $hItem, $checkedState)
					EndIf
					If $bIsParent Then
						If $bBlocked Then
							$prevStates($itemText) = False
						Else
							$prevStates($itemText) = $checkedState
						EndIf
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				AdlibRegister("CheckParentCheckboxes", 100)
			Case $hOkButton
				AdlibUnRegister("CheckParentCheckboxes")
				Local $selectedFiles[0]
				Local $hItem = _GUICtrlTreeView_GetFirstItem($hTreeView)
				MemoWrite("正在扫描所选项...")
				While $hItem <> 0
					If _GUICtrlTreeView_GetChecked($hTreeView, $hItem) Then
						Local $itemText = _GUICtrlTreeView_GetText($hTreeView, $hItem)
						If StringInStr($itemText, ".exe") Then
							Local $bSkip = False
							If IsObj($g_mBlockedAppPaths) And $g_mBlockedAppPaths.Exists(StringLower($itemText)) Then
								$bSkip = True
								LogWrite(1, "WinTrust: 已跳过不支持 WinTrust 的 AE 路径: " & $itemText)
							EndIf
							If Not $bSkip Then _ArrayAdd($selectedFiles, $itemText)
						EndIf
					EndIf
					$hItem = _GUICtrlTreeView_GetNext($hTreeView, $hItem)
				WEnd
				_GUICtrlTab_SetCurFocus($hTab, $g_iLogTabIndex)
				GUIDelete($hGUI)
				If UBound($selectedFiles) = 0 Then
					MemoWrite("未选择要" & $sOperationLabel & "的文件.")
					LogWrite(1, "未选择要" & $sOperationLabel & "的文件.")
				EndIf
				Return $selectedFiles
			Case $GUI_EVENT_PRIMARYDOWN
				Local $aCursor = GUIGetCursorInfo($hGUI)
				If IsArray($aCursor) And $aCursor[4] = $hTreeView Then
					If Not $bPaused Then
						AdlibUnRegister("CheckParentCheckboxes")
						$bPaused = True
					EndIf
				EndIf
			Case Else
				If $bPaused Then
					AdlibRegister("CheckParentCheckboxes", 100)
					$bPaused = False
				EndIf
		EndSwitch
	WEnd
EndFunc

Func ManageDevOverride()
	Local $aMainPos = WinGetPos($MyhGUI)
	Local $iPopupX = $aMainPos[0] + ($aMainPos[2] - 300) / 2
	Local $iPopupY = $aMainPos[1] + ($aMainPos[3] - 150) / 2
	Local $hGUI = GUICreate("配置 DevOverride", 300, 150, $iPopupX, $iPopupY)

	Local $sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
	Local $sValueName = "DevOverrideEnable"
	Local $sStatus
	Local $iValue = RegRead($sKey, $sValueName)
	If @error <> 0 Then
		$sStatus = "DevOverride 注册表项未找到."
	ElseIf $iValue = 1 Then
		$sStatus = "DevOverride 注册表项已启用."
	Else
		$sStatus = "DevOverride 注册表项已禁用."
	EndIf

	GUICtrlCreateLabel($sStatus, 10, 20, 280, 20, $SS_CENTER)

	Local $hAddButton = GUICtrlCreateButton("启用注册表项", 50, 50, 100, 30)
	Local $hRemoveButton = GUICtrlCreateButton("删除注册表项", 150, 50, 100, 30)
	Local $hCancelButton = GUICtrlCreateButton("取消", 100, 100, 100, 30)
	GUISetState(@SW_SHOW)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hCancelButton
				MemoWrite("DevOverride 注册表配置已取消.")
				GUIDelete($hGUI)
				Return
			Case $hAddButton
				GUIDelete($hGUI)
				AddDevOverride()
				Return
			Case $hRemoveButton
				GUIDelete($hGUI)
				RemoveDevOverride()
				Return
		EndSwitch
	WEnd
EndFunc

Func OpenWF()
	Local $sWFPath = @SystemDir & "\wf.msc"
	Run("mmc.exe " & $sWFPath)
	ConsoleWrite("正在打开 Windows 防火墙...")
EndFunc
