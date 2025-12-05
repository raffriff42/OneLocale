; ================================================================
; build-release.ahk v2 – 100% reliable release builder (2025 edition)
; ================================================================
; @version 2025-12-05

#Requires AutoHotkey v2.0
SetWorkingDir A_ScriptDir

; ======================= CONFIG =================================

; GLOBAL OPTIONS
; • version  - change this to match release Tag
; • tempHome - parent temp folder for all releases
; • libRoot  - path to main /lib folder, relative to this script
; • outDir   - path to generated zip files, relative to this script
sVersion    := "1.0.4"
tempHome    := "OneLocale"
libRoot     := "..\lib"
outDir      := "releases"

; • delTemp - if true, delete temp files when finished.
;   Set to false to keep files under '%temp%\build_release\'
;   for troubleshooting purposes
delTemp     := true

; PROJECT OPTIONS
; • name    - zip file base name
; • folder  - main source folder
; • copyLib - if true, copy files from 'libRoot' to '/lib' subfolder

; • excludes & includes:
;   • wildcard '*' allowed
;   • leading '\' marks a folder
;   • items separated by '|'
; • excludes are excluded files and folders
; • includes are extra files and folders, not under 'main' folder

; • baseExcludes - excluded from all release builds
baseExcludes := "*.code-workspace|*.lnk|.gitignore|\.git|\.vscode|\_*|\make|\releases"

projects := []
projects.Push({
    name:     "OneLocale_Demo"
  , folder:   "..\utilities\OneLocale_Demo"
  , copyLib:  true
  , excludes: baseExcludes "|OneLocale_Baker.ahk"
                . "|OneLocale_LangIDs.ahk|OneLocale_LanguagesTable.ahk"
  , includes: "..\utilities\lib\ToolTips.ahk"
})

projects.Push({
    name:     "OneLocale_Baker"
  , folder:   "..\utilities\OneLocale_Baker"
  , copyLib:  true
  , excludes: baseExcludes "|OneLocale_LangIDs.ahk"
            . "|OneLocale_LanguagesTable.ahk|OneLocale_Utils.ahk"
  , includes: "..\utilities\lib\ControlEnable.ahk|..\utilities\lib\FileUtils.ahk"
            . "|..\utilities\lib\IniFiles.ahk|..\utilities\lib\StringUtils.ahk"
            . "|..\utilities\lib\ToolTips.ahk"
})

projects.Push({
    name:     "OneLocale_FindLangID"
  , folder:   "..\utilities\OneLocale_FindLangID"
  , copyLib:  true
  , excludes: baseExcludes "|OneLocale_Baker.ahk"
            . "|OneLocale_LanguagesTable.ahk|OneLocale_Utils.ahk"
  , includes: "..\utilities\lib\ToolTips.ahk"
})

projects.Push({
    name:     "OneLocale_All"
  , folder:   ".."
  , copyLib:  false
  , excludes: baseExcludes
  , includes: ""
})

; ======================== RUN ===================================
S_TITLE := "Release Builder"
A_IconTip := S_TITLE
if (!A_IsCompiled) {
    TraySetIcon("imageres.dll", 233) ; green check
}
DirCreate(outDir)

; one '%temp%\build_release\' folder for all projects and releases
; (making manual cleanup easier)
tempRoot := A_Temp "\build_release\" tempHome "-" A_NowUTC

; keep robocopy super quiet + no junction copies
RoboOpts := "/E /COPY:DT /E /NFL /NDL /NJH /NJS /NC /NS /NP /XJ"

for key, proj in projects
{
    tempProj := tempRoot "\" proj.name
    DirCreate(tempProj)

    ; ── 1. Copy main folder with excludes ─────────────────────
    opts := RoboOpts
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

    ; ── 2. Copy core lib folder ───────────────────────────────
    if (proj.copyLib && DirExist(libRoot))
        RunWait('robocopy "' libRoot '" "' tempProj '\lib" ' RoboOpts, , "Hide")

    ; ── 3. Copy extra includes into lib ───────────────────────
    if (proj.HasProp("includes") && StrLen(proj.includes))
        for ff in StrSplit(proj.includes, "|")
            if (f := Trim(ff)) && FileExist(f)
                FileCopy(f, tempProj "\lib\" SplitPathFunc(f).Name, 1)

    ; ── 4. Create zip – with proven retry logic ───────────────
    zipName := outDir "\" StrReplace(proj.name, " ", "_") "_v" sVersion ".zip"
    try FileDelete(zipName)

    TryZip() {
        RunWait('powershell -NoProfile -Command "Compress-Archive '
                    . '-Force -Path `"' tempProj '`" -DestinationPath `"' zipName '`"'
                    , , "Hide")
    }

    TryZip()
    Loop 6 { ; max 6 retries, 200 ms apart
        Sleep 200
        if FileExist(zipName) && (FileGetSize(zipName) > 0)
            break
        TryZip()
    }

    if !FileExist(zipName)
        MsgBox("FAILED to create " proj.name ".zip even after retries!", S_TITLE, 0x10)
;    else
;        TrayTip(proj.name " → " SplitPathFunc(zipName).BaseName, S_TITLE, 1)

    if (delTemp)
        DirDelete(tempProj, true)   ; clean up temp
}
if (delTemp)
    DirDelete(tempRoot, true)   ; clean up temp

MsgBox(projects.Length " release zip(s) ready in`n" outDir, S_TITLE, "iconi")
ExitApp

SplitPathFunc(sPath)
{
    SplitPath sPath, &name, &parent, &ext, &nameNoExt, &drive
    return {
        Drive:     drive
      , Parent:    parent
      , Name:      name
      , BaseName:  nameNoExt
      , Extension: ext
    }
}
