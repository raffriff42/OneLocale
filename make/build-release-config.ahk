; configuration settings for build-release.ahk
#Requires AutoHotkey v2.0

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
/*
projects.Push({
    name:     "OneLocale_All"
  , folder:   ".."
  , copyLib:  false
  , excludes: baseExcludes
  , includes: ""
})
*/
; (end)
