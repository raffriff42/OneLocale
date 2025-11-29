; ControlEnable.ahk

#Requires AutoHotkey v2.0

;************************************************
; Credits - I believe that unless otherwise attributed,
;  this AutoHotkey code is original
;  (other than sample code from the documentation)
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

/****************************************
 * #### ControlEnable: enable or disable a control using its Class name
 *
 * @param {String} GuiNameOrHwnd - [required] a Gui object, Gui name or window handle
 *
 * @param {String} sClassname - a control ID like "Button1" etc (found with WinSpy)
 *
 * @param {Boolean} enable - a boolean value that enables or disables the control
 *
 * @param {Boolean} ignoreError - if true, ignore 'specified control does not exist'
 *     errors etc; for use when being called by ControlEnableALL()
 * <!--
 * @version 2024-09-08
 * @version 2025-09-23 ported to AHKv2; signature change
 * -->
 */
ControlEnable(GuiNameOrHwnd, sClassname, enable, ignoreError:=false)
{
    local ee
    try {
        if (IsObject(GuiNameOrHwnd)) {
            GuiNameOrHwnd[sClassname].Enabled := enable
            return
        }
        else if (IsInteger(GuiNameOrHwnd)) {
            GuiFromHwnd(GuiNameOrHwnd)[sClassname].Enabled := enable
            return
        }
        else if (StrLen(GuiNameOrHwnd)) {
            %GuiNameOrHwnd%[sClassname].Enabled := enable
            return
        }
        Assert(false, "ControlEnable: empty 'GuiNameOrHwnd'")
    }
    catch Error as ee {
        if (!ignoreError) {
            Assert(false, "ControlEnable: " ee.Message)
            ;OutputDebug("ControlEnable(" sClassname "): " ee.Message "`n")
        }
    }
    return
}

/****************************************
 * #### ControlEnableRange: enable or disable a group of controls using their common Class name
 *
 * @param {String} GuiNameOrHwnd - [required] a Gui object, Gui name or window handle
 *
 * @param {String} sClassname - a control ID, without index, like "Button" etc (found with WinSpy)
 *
 * @param {Integer} first - index number of the first control in the group
 *
 * @param {Integer} last - the index number of the last control in the group
 *
 * @param {Boolean} enable - enables or disables the control
 *
 * @param {Boolean} ignoreError - if true, ignore 'specified control does not exist' errors
 *     etc; for use when being called by ControlEnableALL()
 * <!--
 * @version 2024-09-08
 * @version 2025-09-23 ported to AHKv2; signature change
 * -->
 */
ControlEnableRange(GuiNameOrHwnd, sClassname, nFirst, nLast, enable, ignoreError:=false)
{
    local idx
    idx := (nFirst - 1)
    while (idx++ <= nLast) {
        ControlEnable(GuiNameOrHwnd, sClassname idx, enable, ignoreError)
    }
    return
}

/**********************************************
 * #### ControlEnableALL: enable or disable [almost] all controls on a window
 *
 * @param {String} GuiNameOrHwnd - [required] a Gui object, Gui name or window handle
 *
 * @param {Boolean} enable - enables or disables the control
 * <!--
 * @version 2024-09-26
 * @version 2025-09-23 ported to AHKv2; signature change
 * -->
 */
ControlEnableALL(GuiNameOrHwnd, enable)
{
    ControlEnableRange(GuiNameOrHwnd, "Button", 1, 99, enable, true)
    ControlEnableRange(GuiNameOrHwnd, "Edit"  , 1, 99, enable, true)
    ControlEnableRange(GuiNameOrHwnd, "Static", 1, 99, enable, true)
    ControlEnableRange(GuiNameOrHwnd, "Text"  , 1, 99, enable, true)
    return
}

; (end)
