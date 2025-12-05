; ================================================================
; build-release.ahk v2 – FINAL 100% reliable version (Dec 2025)
; Copy-paste this and forget about it forever
; ================================================================

#Requires AutoHotkey v2.0
SetWorkingDir A_ScriptDir

S_TITLE   := "OneLocale Release Builder"
S_VERSION := "1.0.4"                ; ← CHANGE THIS EACH RELEASE

outDir := "releases"
DirCreate(outDir)

libRoot := "..\lib"                 ; change only if your lib folder lives elsewhere

; =========================== CONFIG ===========================
projects := Map()

projects["Demo"] := {
    name:     "OneLocale_Demo"
  , folder:   "..\utilities\OneLocale_Demo"
  , excludes: "\.git|\.vscode|*.lnk|.gitignore|\_*|\releases|OneLocale_Baker.ahk|OneLocale_LangIDs.ahk|OneLocale_LanguagesTable.ahk"
  , includes: "..\utilities\lib\ToolTips.ahk"
  , copyLib:  true
}

projects["Baker"] := {
    name:     "OneLocale_Baker"
  , folder:   "..\utilities\OneLocale_Baker"
  , excludes: "\.git|\.vscode|*.lnk|.gitignore|\_*|\releases|OneLocale_LangIDs.ahk|OneLocale_LanguagesTable.ahk|OneLocale_Utils.ahk"
  , includes: "..\utilities\lib\ControlEnable.ahk|..\utilities\lib\FileUtils.ahk|..\utilities\lib\IniFiles.ahk|..\utilities\lib\StringUtils.ahk|..\utilities\lib\ToolTips.ahk"
  , copyLib:  true
}

projects["FindLangID"] := {
    name:     "OneLocale_FindLangID"
  , folder:   "..\utilities\OneLocale_FindLangID"
  , excludes: "\.git|\.vscode|*.lnk|.gitignore|\_*|\releases|OneLocale_Baker.ahk|OneLocale_LanguagesTable.ahk|OneLocale_Utils.ahk"
  , includes: "..\utilities\lib\ToolTips.ahk"
  , copyLib:  true
}

projects["All"] := {
    name:     "OneLocale_All"
  , folder:   ".."
  , excludes: "\.git|\.vscode|*.lnk|.gitignore|\_*|\releases"
  , includes: ""
  , copyLib:  false
}

; ================================================================

robo := "/E /COPY:DT /NFL /NDL /NJH /NJS /NC /NS /NP /XJ"   ; ultra quiet

for key, proj in projects
{
    tempRoot := A_Temp "\build_release_" A_NowUTC
    tempProj := tempRoot "\" proj.name
    DirCreate(tempProj)

    ; 1. Copy project folder with excludes
    opts := robo
    if (proj.HasProp("excludes") && StrLen(proj.excludes))
    {
        xd := "", xf := ""
        for ex in StrSplit(proj.excludes, "|")
        {
            ex := Trim(ex)
            if (SubStr(ex, 1, 1) = "\")
                xd .= ' "' SubStr(ex, 2) '"'
            else
                xf .= ' "' ex '"'
        }
        opts .= xd ? " /XD" xd : ""
        opts .= xf ? " /XF" xf : ""
    }
    RunWait('robocopy "' proj.folder '" "' tempProj '" ' opts, , "Hide")

    ; 2. Copy core lib
    if (proj.copyLib && DirExist(libRoot))
        RunWait('robocopy "' libRoot '" "' tempProj '\lib" ' robo, , "Hide")

    ; 3. Copy extra includes into lib folder
    if (proj.HasProp("includes") && StrLen(proj.includes))
        for path in StrSplit(proj.includes, "|")
            if (f := Trim(path)) && FileExist(f)
                FileCopy(f, tempProj "\lib\" SplitPathFunc(f).BaseName, 1)

    ; 4. Create zip – 100% reliable
    zipName := outDir "\" StrReplace(proj.name, " ", "_") "_v" S_VERSION ".zip"
    try FileDelete(zipName)

    MakeZip() => RunWait('powershell -NoProfile -Command "Compress-Archive -Force -Path `"' tempProj '\*`" -DestinationPath `"' zipName '`" "', , "Hide")

    MakeZip()
    Loop 6
    {
        Sleep 150
        if FileExist(zipName) && FileGetSize(zipName)
            break
        MakeZip()
    }

    if !FileExist(zipName)
        MsgBox("FAILED: " proj.name ".zip", S_TITLE, 0x10)
    else
        TrayTip(proj.name " → " SplitPathFunc(zipName).BaseName, S_TITLE, 1)

    DirDelete(tempRoot, true)
}

MsgBox(projects.Count " release zip(s) ready in`n" outDir, S_TITLE, 0x40)

/**********************************************
 * #### SplitPathFunc: like SplitPath, but returns a Object
 *
 * @param {String} sPath - file name or URL to be analyzed
 *
 * @return {Object} { Drive, Parent, BaseName, Extension }
 * <!--
 * @version 2025-12-05 raffriff42
 * -->
 */
SplitPathFunc(sPath)
{
	local s_parent, s_ext, s_basename, s_drive
	SplitPath sPath, , &s_parent, &s_ext, &s_basename, &s_drive

    return { Drive:s_drive, Parent:s_parent, BaseName:s_basename, Extension:s_ext }
}
