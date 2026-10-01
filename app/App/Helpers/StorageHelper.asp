<%
'=======================================================================================================================
' STORAGE HELPER (RustFS Object Storage Integration)
'=======================================================================================================================
Class StorageHelper_Class
    Private m_internalUrl
    Private m_publicUrl
    Private m_bucketName

    Private Sub Class_Initialize()
        m_internalUrl = "http://rustfs:9000"
        m_publicUrl   = "http://localhost:9000"
        m_bucketName  = "uploads"
    End Sub

    Public Property Get InternalUrl
        InternalUrl = m_internalUrl
    End Property
    Public Property Let InternalUrl(val)
        m_internalUrl = val
    End Property

    Public Property Get PublicUrl
        PublicUrl = m_publicUrl
    End Property
    Public Property Let PublicUrl(val)
        m_publicUrl = val
    End Property

    Public Property Get BucketName
        BucketName = m_bucketName
    End Property
    Public Property Let BucketName(val)
        m_bucketName = val
    End Property

    Public Function GetExtension(ByVal fileName)
        Dim dotPos : dotPos = InStrRev(fileName, ".")
        If dotPos > 0 Then
            GetExtension = LCase(Mid(fileName, dotPos))
        Else
            GetExtension = ""
        End If
    End Function

    Public Function IsValidImageExtension(ByVal ext)
        Select Case LCase(ext)
            Case ".jpg", ".jpeg", ".png", ".gif", ".webp"
                IsValidImageExtension = True
            Case Else
                IsValidImageExtension = False
        End Select
    End Function

    Public Function GetMimeType(ByVal ext)
        Select Case LCase(ext)
            Case ".jpg", ".jpeg": GetMimeType = "image/jpeg"
            Case ".png":          GetMimeType = "image/png"
            Case ".gif":          GetMimeType = "image/gif"
            Case ".webp":         GetMimeType = "image/webp"
            Case Else:            GetMimeType = "application/octet-stream"
        End Select
    End Function

    Private Function GenerateUniqueFileName(ByVal ext)
        Dim y, m, d, t, r
        y = Year(Now)
        m = Right("0" & Month(Now), 2)
        d = Right("0" & Day(Now), 2)
        t = Right("00000" & CLng(Timer() * 100) Mod 100000, 5)
        Randomize
        r = Right("0000" & Hex(Int(Rnd() * 65535)), 4)
        GenerateUniqueFileName = "img_" & y & m & d & "_" & t & "_" & r & LCase(ext)
    End Function

    Public Function UploadFile(ByVal physicalPath, ByVal originalName, ByVal mimeType)
        Dim result : Set result = Server.CreateObject("Scripting.Dictionary")
        result("Success") = False
        result("Url") = ""
        result("RelativeUrl") = ""
        result("FileName") = ""
        result("ErrorMessage") = ""

        Dim ext : ext = GetExtension(originalName)
        If Not IsValidImageExtension(ext) Then
            result("ErrorMessage") = "Invalid image type. Supported formats: JPG, PNG, GIF, WEBP."
            Set UploadFile = result
            Exit Function
        End If

        Dim fso : Set fso = Server.CreateObject("Scripting.FileSystemObject")
        If Not fso.FileExists(physicalPath) Then
            result("ErrorMessage") = "Upload source file not found."
            Set UploadFile = result
            Exit Function
        End If

        Dim newFileName : newFileName = GenerateUniqueFileName(ext)
        If mimeType = "" Or mimeType = "application/octet-stream" Then
            mimeType = GetMimeType(ext)
        End If

        ' Transfer binary file to RustFS via curl --data-binary
        Dim targetUrl : targetUrl = m_internalUrl & "/" & m_bucketName & "/" & newFileName
        Dim statusStr : statusStr = ""

        On Error Resume Next
        Dim sh, execObj, cmd
        Set sh = Server.CreateObject("WScript.Shell")
        cmd = "curl -s -S -o /dev/null -w ""%{http_code}"" -X PUT -H ""Content-Type: " & mimeType & """ --data-binary @" & physicalPath & " " & targetUrl
        Set execObj = sh.Exec(cmd)
        If Err.Number = 0 And Not execObj Is Nothing Then
            statusStr = Trim(execObj.StdOut.ReadAll())
            Set execObj = Nothing
        End If
        Set sh = Nothing
        Err.Clear

        ' Fallback to MSXML2.ServerXMLHTTP if curl did not return a status code
        If statusStr = "" Then
            Dim stream, body, http
            Set stream = Server.CreateObject("ADODB.Stream")
            stream.Type = 1 ' adTypeBinary
            stream.Open
            stream.LoadFromFile physicalPath
            stream.Position = 0
            body = stream.Read()
            stream.Close
            Set stream = Nothing

            Set http = Server.CreateObject("MSXML2.ServerXMLHTTP")
            http.Open "PUT", targetUrl, False
            http.setRequestHeader "Content-Type", mimeType
            http.Send body
            If Err.Number = 0 Then
                statusStr = CStr(http.Status)
            End If
            Set http = Nothing
            Err.Clear
        End If

        If statusStr = "200" Or statusStr = "201" Then
            result("Success") = True
            result("FileName") = newFileName
            result("Url") = m_publicUrl & "/" & m_bucketName & "/" & newFileName
            result("RelativeUrl") = "/uploads/" & newFileName
        Else
            result("ErrorMessage") = "RustFS returned HTTP " & statusStr & " while storing image."
        End If

        Set UploadFile = result
    End Function

    Public Function ProcessFormUpload(ByVal fieldName)
        Dim result : Set result = Server.CreateObject("Scripting.Dictionary")
        result("Success") = False
        result("Url") = ""
        result("RelativeUrl") = ""
        result("FileName") = ""
        result("ErrorMessage") = ""

        Dim tempFolder : tempFolder = Server.MapPath("/temp")
        Dim fso : Set fso = Server.CreateObject("Scripting.FileSystemObject")
        If Not fso.FolderExists(tempFolder) Then
            On Error Resume Next
            fso.CreateFolder tempFolder
            Err.Clear
            On Error Goto 0
        End If

        Dim uploader, uploadResult
        Set uploader = Server.CreateObject("G3FILEUPLOADER")
        uploader.MaxFileSize = 10485760 ' 10MB
        uploader.AllowAbsolutePaths = True

        On Error Resume Next
        Set uploadResult = uploader.Process(fieldName, tempFolder)
        If Err.Number <> 0 Then
            result("ErrorMessage") = "File upload processing failed: " & Err.Description
            Err.Clear
            Set ProcessFormUpload = result
            Exit Function
        End If

        If Not uploadResult("IsSuccess") Then
            result("ErrorMessage") = uploadResult("ErrorMessage")
            Set ProcessFormUpload = result
            Exit Function
        End If

        Dim tempFilePath : tempFilePath = uploadResult("FinalPath")
        Dim origFileName : origFileName = uploadResult("OriginalFileName")
        Dim mimeType     : mimeType     = uploadResult("MimeType")

        ' Transfer to RustFS
        Dim s3Result : Set s3Result = UploadFile(tempFilePath, origFileName, mimeType)

        ' Clean up local temporary file
        If fso.FileExists(tempFilePath) Then
            On Error Resume Next
            fso.DeleteFile tempFilePath, True
            Err.Clear
            On Error Goto 0
        End If
        Set fso = Nothing

        Set ProcessFormUpload = s3Result
    End Function
End Class

Dim Storage : Set Storage = New StorageHelper_Class
%>
