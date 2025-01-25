function Get-CallPosition
{
    $caller = $( Get-PSCallStack )[2]
    $functionName = $caller.FunctionName
    $lineNumber = $caller.Position.StartLineNumber

    return @{
        FunctionName = $functionName
        LineNumber = $lineNumber
    }
}

function Write-LogMessage
{
    param (
        [string]$Msg
    )

    $callPosition = Get-CallPosition
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

    Write-Host $time -ForegroundColor Green -NoNewline
    Write-Host " | " -NoNewline
    Write-Host " INFO    " -ForegroundColor White -NoNewline
    Write-Host " | " -NoNewline
    Write-Host $callPosition.FunctionName -ForegroundColor Cyan -NoNewline
    Write-Host ":" -ForegroundColor Cyan -NoNewline
    Write-Host $callPosition.LineNumber -ForegroundColor Cyan -NoNewline
    Write-Host " - " -NoNewline
    Write-Host $Msg -ForegroundColor White
}

function Exit-WithPause
{
    param (
        [Int16]$ExitCode
    )
    Pause
    exit $ExitCode
}

function Request-ROCM
{
    Write-LogMessage "Please select the ROCM version:"
    Write-LogMessage "1. ROCM 5"
    Write-LogMessage "2. ROCM 6"
    $choice = Read-Host "Enter your choice (1 or 2)"
    if ($choice -eq "1")
    {
        $downloadUrl = "https://github.com/lshqqytiger/ZLUDA/releases/download/rel.c0804ca624963aab420cb418412b1c7fbae3454b/ZLUDA-windows-rocm5-amd64.zip"
    }
    elseif ($choice -eq "2")
    {
        $downloadUrl = "https://github.com/lshqqytiger/ZLUDA/releases/download/rel.c0804ca624963aab420cb418412b1c7fbae3454b/ZLUDA-windows-rocm6-amd64.zip"
    }
    else
    {
        Write-Output "Invalid choice. Exiting script."
        exit 1
    }
    return $downloadUrl
}

function Set-Requirements
{
    Write-LogMessage "Installing pip v24.0"
    python -m pip install pip==24.0 | Out-Null
    Write-LogMessage "Installing raw requirements..."
    pip install -r requirements.txt | Out-Null
    Write-LogMessage "Uninstalling unsupported requirements..."
    pip uninstall torch torchvision torchaudio -y | Out-Null
    Write-LogMessage "Installing new requirements..."
    pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 --upgrade --index-url https://download.pytorch.org/whl/cu118 | Out-Null
}

function Set-Patches
{
    # https://github.com/IAHispano/Applio/blob/main/assets/zluda/patch-zluda-hip57.bat
    # https://github.com/IAHispano/Applio/blob/main/assets/zluda/patch-zluda-hip61.bat

    param (
        [String]$ROCM_URL
    )

    if (Test-Path -Path "zluda")
    {
        Remove-Item -Path "zluda" -Recurse -Force
    }

    $zipFilePath = "zluda.zip"

    Write-LogMessage "Downloading from $ROCM_URL..."
    try
    {
        Invoke-WebRequest -Uri $ROCM_URL -OutFile $zipFilePath
    }
    catch
    {
        Write-LogMessage "Failed to download the file from $ROCM_URL. Please check the URL and your network connection."
        Exit-WithPause
    }

    Write-LogMessage "Unzipping..."
    Expand-Archive -Path $zipFilePath -DestinationPath "."
    Remove-Item -Path $zipFilePath -Force

    Write-LogMessage "Copying..."
    $destinationPath = ".venv\Lib\site-packages\torch\lib"
    Copy-Item -Path "zluda\cublas.dll" -Destination "$destinationPath\cublas64_11.dll" -Force
    Copy-Item -Path "zluda\cusparse.dll" -Destination "$destinationPath\cusparse64_11.dll" -Force
    Copy-Item -Path "zluda\nvrtc.dll" -Destination "$destinationPath\nvrtc64_112_0.dll" -Force
}

function Main
{
    if (-not $env:VIRTUAL_ENV)
    {
        Write-LogMessage "Please run the script in venv."
        Exit-WithPause 1
    }

    $rocm_url = Request-ROCM

    Write-LogMessage "Setting requirements..."
    Set-Requirements

    Write-LogMessage "Setting patches..."
    Set-Patches $rocm_url

    Write-LogMessage "Successful!"
    Exit-WithPause
}

Main