; ================================================================
; build-release.ahk v2 – 100% reliable release builder (2025 edition)
; ================================================================
; @version 2025-12-05 Grok wrote it - I helped
; @version 2025-12-08 move configuration to external script
; @version 2025-12-11 move configuration to .ini file

#Requires AutoHotkey v2.0
SetWorkingDir A_ScriptDir

S_TITLE := "Release Builder"
A_IconTip := S_TITLE
if (!A_IsCompiled) {
    TraySetIcon("imageres.dll", 233) ; green check
}

BuildRelease()
{
    ; CONFIG =================================

    ini_path := SubStr(A_ScriptFullPath, 1, -4) ".ini"
    if (!StrLen(FileExist(ini_path))) {
        MsgBox("Ini file '" ini_path "' not found", S_TITLE, "iconx")
        ExitApp 1
    }
    sVersion := IniRead(ini_path, "general", "version" , "") ; must match release Tag
    tempHome := IniRead(ini_path, "general", "tempHome", "") ; parent temp folder for all releases
    libRoot  := IniRead(ini_path, "general", "libRoot" , "") ; adjust if your lib is somewhere else
    outDir   := IniRead(ini_path, "general", "outDir"  , "") ; output zip folder
    delTemp  := CBool(IniRead(ini_path, "general", "delTemp", 1))

    if (!StrLen(sVersion)) {
        MsgBox("'sVersion' not set!", S_TITLE, "iconx")
        ExitApp
    }
    if (!StrLen(tempHome)) {
        MsgBox("'tempHome' not set!", S_TITLE, "iconx")
        ExitApp
    }
    if (!StrLen(libRoot) || !StrLen(DirExist(libRoot))) {
        MsgBox("'libRoot' folder not found!", S_TITLE, "iconx")
        ExitApp
    }
    if (!StrLen(outDir) || !StrLen(DirExist(outDir))) {
        MsgBox("'outDir' folder not found!", S_TITLE, "iconx")
        ExitApp
    }

    sBaseExcludes := IniReadSection(ini_path, "baseExcludes", "")

    sProjList := IniReadSection(ini_path, "projects", "")
    arProjNames := StrSplit(sProjList, "`n", " ")
    if (!arProjNames.Length) {
        MsgBox("No projects listed - nothing to do!", S_TITLE, "iconx")
        ExitApp
    }
    arProjects := []
    for n, sName in arProjNames
    {
        sFolder   := IniRead(ini_path, sName, "folder" , "")
        copyLib   := CBool(IniRead(ini_path, sName, "copyLib", 0))

        sExcludes := IniReadSection(ini_path, sName "_excludes", "")
        sExcludes := StrReplace(sExcludes, ":baseExcludes:", sBaseExcludes)

        sIncludes := IniReadSection(ini_path, sName "_includes", "")

        if (!StrLen(sFolder) || !StrLen(DirExist(sFolder))) {
            MsgBox("'sName' folder not found!", S_TITLE, "iconx")
            ExitApp
        }
        arProjects.Push({name:sName, folder:sFolder, copyLib:copyLib
                , excludes:sExcludes, includes:sIncludes})
    }

    ; RUN ===================================
    DirCreate(outDir)

    MsgBox("Build in progress...`nsee green icon in System Tray", S_TITLE, "iconi T4")

    ; one '%temp%\build_release\' folder for all projects and releases
    ; (making manual cleanup easier)
    tempRoot := A_Temp "\build_release\" tempHome "-" A_NowUTC

    ; keep robocopy super quiet + no junction copies
    RoboOpts := "/E /COPY:DT /E /NFL /NDL /NJH /NJS /NC /NS /NP /XJ"

    for key, proj in arProjects
    {
        tempProj := tempRoot "\" proj.name
        DirCreate(tempProj)

        ; ── 1. Copy main folder with excludes ─────────────────────
        opts := RoboOpts
        if (proj.HasProp("excludes") && StrLen(proj.excludes))
        {
            ar :=  StrSplit(proj.excludes, "`n", " ")
            xd := "", xf := "" ; list of excluded directories, files
            for n, p in ar
            {
                if (SubStr(p, 1, 1) == "\")
                    xd .= ' "' SubStr(p, 2) '"'
                else
                    xf .= ' "' p '"'
            }
            opts .= xd ? " /XD" xd : "" ; list of excluded directories
            opts .= xf ? " /XF" xf : "" ; list of excluded  files
        }
        RunWait('robocopy "' proj.folder '" "' tempProj '" ' opts, , "Hide")

        ; ── 2. Copy core lib folder ───────────────────────────────
        if (proj.copyLib && DirExist(libRoot))
            RunWait('robocopy "' libRoot '" "' tempProj '\lib" ' RoboOpts, , "Hide")

        ; ── 3. Copy extra includes into lib ───────────────────────
        if (proj.HasProp("includes") && StrLen(proj.includes))
        {
            ar :=  StrSplit(proj.includes, "`n", " ")
            for n, p in ar
            {
                if (StrLen(FileExist(p)))
                    FileCopy(p, tempProj "\lib\" SplitPathFunc(p).Name, 1)
            }
        }

        ; ── 4. Create zip – with proven retry logic ───────────────
        zipName := outDir "\" StrReplace(proj.name, " ", "_") "_v" sVersion ".zip"
        try FileDelete(zipName)

        ;********************
        TryZip()
        {
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
            MsgBox("FAILED to create " proj.name ".zip even after retries!", S_TITLE, "iconx")
    ;    else
    ;        TrayTip(proj.name " → " SplitPathFunc(zipName).BaseName, S_TITLE, 1)

        if (delTemp)
            DirDelete(tempProj, true)   ; clean up temp
    }
    if (delTemp)
        DirDelete(tempRoot, true)   ; clean up temp

    MsgBox(arProjects.Length " release zip(s) ready in`n" outDir, S_TITLE, "iconi")
    ExitApp 0
}

/**************************************************
 * #### IniReadSection: read entire section
 *
 * @param {String} sPath - full path of .INI file
 *
 * @param {String} sSection - section name within .INI file; the heading
 *    that appears in square brackets (do not include the brackets)
 *
 * @param {String} sDefault - value to return in case of error; default="ERROR"
 */
IniReadSection(sPath, sSection, sDefault:="ERROR")
{
    local vv
    vv := IniRead(sPath, sSection, , sDefault)
    if (!StrLen(vv))
        vv := sDefault
    return vv
}

/**********************************************
 * #### SplitPathFunc: like SplitPath, but returns a Object
 *
 * @param {String} sPath - file name or URL to be analyzed
 *
 * @return {Object} { Drive, Parent, Name, BaseName, Extension }
 */
SplitPathFunc(sPath)
{
    local name, parent, ext, nameNoExt, drive
    SplitPath sPath, &name, &parent, &ext, &nameNoExt, &drive
    return {
        Drive:     drive
      , Parent:    parent
      , Name:      name
      , BaseName:  nameNoExt
      , Extension: ext
    }
}

/**********************************************
 * #### CBool: convert an unknown variable into a Boolean
 * - Object variables assumed False
 */
CBool(v)
{
    if (!IsSet(v))
        return false

    if (IsNumber(v)) {
        if (Round(v) != 0)
            return true
        return false
    }

    if (v = "true") ; non case sensitive
        return true
    return false
}

; (end)
