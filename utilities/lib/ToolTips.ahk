; _ToolTips.ahk
;; Improved ToolTips on mouse hover;\

#Requires AutoHotkey v2.0

;************************************************
; Credits - I believe that unless otherwise attributed,
; this AutoHotkey code is original
; (other than sample code from the documentation)
;
; thanks-
; https://www.autohotkey.com/board/topic/81915-solved-gui-control-tooltip-on-hover/#entry529556
;************************************************

;************************************************
; This code is free software; you can redistribute it and/or
; modify it under the terms of the GNU Lesser General Public
; License as published by the Free Software Foundation; either
; version 2.1 of the License, or (at your option) any later version.
;
; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
; Lesser General Public License for more details.
;************************************************

;; (Table of Contents)
;  On_WM_MOUSEMOVE()
;  On_WM_MOUSELEAVE()

/**************************************************
 * based on
 * https://www.autohotkey.com/docs/v2/lib/Gui.htm#ExToolTip
 *
 * ##### Gui creation - Setting the tool tip
 * ```Autohotkey
 * ctlEdit1 := MyGui.Add("Edit", "vctEdit1")
 * ctlEdit1.ToolTip := "This is a tooltip" ; tooltip can be changed later
 * ```
 * ##### After Gui Show - Initialization
 * ```Autohotkey
 * OnMessage(0x200, On_WM_MOUSEMOVE)
 * OnMessage(0x2A3, On_WM_MOUSELEAVE)
 * ```
 * <!--
 * @ version 2023-11-19
 * @ version 2023-12-03 WM_MOUSELEAVE
 * @ version 2025-10-08 simplified
 * -->
 */
On_WM_MOUSEMOVE(_wParam, _lParam, _msg, Hwnd)
{
    static PrevHwnd := 0
    if (Hwnd != PrevHwnd)
    {
        ToolTip() ; Turn off any previous tooltip.
        Text := ""
        CurrControl := GuiCtrlFromHwnd(Hwnd)
        if (CurrControl)
        {
            if (!CurrControl.HasProp("ToolTip"))
                return ; No tooltip for this control.
            Text := CurrControl.ToolTip
            SetTimer () => ToolTip(Text), -500
            SetTimer () => ToolTip()    , -4000 ; Remove the tooltip.
        }
        PrevHwnd := Hwnd
    }
}

/**********************************************
 */
On_WM_MOUSELEAVE(_wParam, _lParam, _msg, _Hwnd)
{
    ToolTip()
    return
}

; (end)