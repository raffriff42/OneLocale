; ================================================================
; build-release.ahk v2 – 100% reliable release builder (2025 edition)
; ================================================================
; @version 2025-12-05 wrote it
; @version 2025-12-08 move configuration to external script

#Requires AutoHotkey v2.0
SetWorkingDir A_ScriptDir

; ======================= CONFIG =================================

#Include "build-release-config.ahk"

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
