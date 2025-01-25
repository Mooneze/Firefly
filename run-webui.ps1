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

function Main
{
    if (-not $env:VIRTUAL_ENV)
    {
        Write-LogMessage "Please run the script in venv."
        Exit-WithPause 1
    }

    $env:HIP_VISIBLE_DEVICES = "0"
    $env:ZLUDA_COMGR_LOG_LEVEL = "1"

    & ".\zluda\zluda.exe" -- ".venv\Scripts\python.exe" "webUI.py"
}

Main