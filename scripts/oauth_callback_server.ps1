param(
    [int]$Port = 18321,
    [string]$OutputFile = ""
)

if ($OutputFile -eq "") {
    $OutputFile = Join-Path $env:TEMP "godot_oauth_callback.txt"
}

# Clean up old callback file
if (Test-Path $OutputFile) {
    Remove-Item $OutputFile -Force
}

$listener = $null
try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")
    $listener.Start()

    Write-Host "OAuth callback server listening on port $Port"

    $context = $listener.GetContext()
    $requestUrl = $context.Request.Url.ToString()

    # Use ASCII to avoid BOM issues with UTF-8 on Windows PowerShell 5.1
    [System.IO.File]::WriteAllText($OutputFile, $requestUrl, [System.Text.Encoding]::ASCII)

    # Send a friendly response to the browser
    $html = @"
<!DOCTYPE html>
<html>
<head><title>Login Successful</title></head>
<body style="font-family:Arial,sans-serif;text-align:center;padding-top:100px;">
<h1>Login Successful!</h1>
<p>You can close this tab and return to the game.</p>
</body>
</html>
"@
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    $context.Response.ContentLength64 = $buffer.Length
    $context.Response.ContentType = "text/html; charset=utf-8"
    $context.Response.StatusCode = 200
    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $context.Response.Close()
} catch {
    Write-Host "Error: $_"
} finally {
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
        $listener.Close()
    }
}
