param (
    $progress = "none"
)

# Constants
$dockerURL = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" # endpoint for docker installer
$dockerInstaller = "docker-installer.exe" # Docker installer exe name
$dockerFeature = "Microsoft-Hyper-V" # for the unused check for docker compat
$dockerActivity = "Docker Installation" # for logging activity in tty
$dockerID = 1 # ID used for the progress bar
$RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" # Registry key for the startup task
$TaskName = "bloodhound" # ScheduledTask name

Function main {
    # Stupid shit, fixes glacially slow download
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # This loop allows for starting at a specified point after restart. It's super jank, but workflows suck
    echo $progress
    While (!($progress -eq "done")) {
        Switch ($progress) {
            "none" {
                Check-Privileges
                Install-Docker
                $progress = "post-docker"
                break
            }
            "post-docker" {
                Check-Privileges
                Docker-Log "Running post-docker routine"
                Write-Warning "Continuing to Bloodhound install. Please do not continue until docker engine has started. If unsure, open the docker GUI before continuing" -WarningAction Inquire
                Write-Warning "Windows Defender is likely to flag sharphound. Allow the file if it does. It will eventually fail, but this script will rerun if so" -WarningAction Inquire

                #####################################################
                # DEFENDER EXCLUSION ACTIVE
                Add-MpPreference -ExclusionPath "$($pwd | Select-Object -Expand Path)"
                Add-MpPreference -ExclusionPath "$($pwd | Select-Object -Expand Path)\sharphound"
                Docker-Log "Defender disabled in current directory"
                Start-Process "powershell" -ArgumentList ".\bloodhound.ps1 bloodhound-retry"
                # Start sharphound
                Install-Sharphound

                # DEFENDER EXCLUSION INACTIVE
                #####################################################
                Remove-MpPreference -ExclusionPath "$($pwd | Select-Object -Expand Path)"
                Remove-MpPreference -ExclusionPath "$($pwd | Select-Object -Expand Path)\sharphound"
                Docker-Log "Defender enabled in current directory"

                # Pause and wait for a response before moving on
                #Pause-ForWarning -Message "Retrying. Please ensure defender has been appeased before continuing. Would you like to continue now?" -PauseTimeInSeconds 60
                # Open a new window to host the

                # Change progress and move on
                $progress = "done"
                break
            }
            # Helper for when the install fails
            "bloodhound-retry" {
                Install-Bloodhound
                break
            }
            Default {
                $progress = "none"
                break;
            }
        }
    }
    # Docker installation requires elevated privileges
   # Check-Privileges
    # Run the installer
    #Install-Docker
}

# Install and run sharphound
Function Install-Sharphound {
    Docker-Log "Waiting for bloodhound before continuing (up to 2 minutes)"
    # this will fail because of authentication, but we just want to wait until it responds
    try {
    Invoke-WebRequest -UseBasicParsing "http://localhost:8080/api/v2/collectors/sharphound" -TimeoutSec 120
    } catch {}
    # pull the file from the docker container
    Docker-Log "Pulling sharphound from the docker container"
    docker cp 'desktop-bloodhound-1:/etc/bloodhound/collectors/sharphound/' .

    # get and move the file to the $PWD
    Get-ChildItem ".\sharphound\*.zip" | Rename-Item -NewName "sharphound.zip" -ErrorAction SilentlyContinue
    Move-Item ".\sharphound\sharphound.zip" -Destination ".\sharphound.zip" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force -Path ".\sharphound"
    Docker-Log "Expanding the zip archive"
    Expand-Archive "sharphound.zip" -Force
    Get-ChildItem ".\sharphound\*" | Move-Item -Destination "." -ErrorAction SilentlyContinue

    Add-MpPreference -ExclusionPath "."
    Start-Process -FilePath ".\SharpHound.exe" -NoNewWindow -Wait
    Remove-MpPreference -ExclusionPath "."
}

Function Install-Bloodhound {
    $filename = "compose.yaml"
    # 'docker compose up' requires admin
    Check-Privileges

    Docker-Log "Beginning Installation of Bloodhound via Docker Compose"
    Invoke-WebRequest -UseBasicParsing "https://github.com/SpecterOps/BloodHound/raw/main/examples/docker-compose/docker-compose.yml" -OutFile $filename
    Invoke-Expression "docker compose up"
    #Invoke-Expression 'curl -UseBasicParsing https://github.com/SpecterOps/BloodHound/raw/main/examples/docker-compose/docker-compose.yml | Select-Object -Expand Content | docker compose -f - up'
}

# Install docker if it is not present
Function Install-Docker {

    # Check to see if docker is running
    Docker-Log "Checking to see if docker service is present"
    Get-Service 'com.docker.service' -ErrorAction SilentlyContinue -ErrorVariable ProcessError

    # Docker is already running
    if (!$ProcessError) {
        Write-Information "Docker process found!" -InformationAction Continue
        Write-Progress -Activity "Docker Installation" -Status "Docker already present on system" -Completed -Id $dockerID
        Docker-Log "Docker already present on system"
        return
    }

    # Check if requirements for docker are met
    Docker-Requirements

    # Docker is not running and must be installed, so download installer
    Docker-Log "Docker process not running, attempting to install docker..."
    Docker-Log "Downloading Docker Installer"

    if (!(Test-Path $dockerInstaller)) {
        $ProgressPreference = 'SilentlyContinue' # Hacky solution to glacially slow install speeds on pwsh 5.1 (windows default)
        Invoke-WebRequest $dockerURL -OutFile $dockerInstaller
        Docker-Log "Docker installer downloaded" -dockerID $dockerID
    } else {
        Docker-Log "Docker installer already downloaded, skipping download"
    }

    # Run the installer
    Docker-Log "Running docker installer"
    Docker-Log "Once finished, you will be prompted to restart. The script should resume after the restart."


    Start-Process -FilePath ".\$($dockerInstaller)" -ArgumentList "install --quiet --noreboot --accept-license" -NoNewWindow -Wait
    Schedule-Script-Startup "post-docker"

    Restart-Computer -Confirm
}

# Check if the docker requirements are met
Function Docker-Requirements {
    # disabled for now
    return
    # Checking if virtualization is enabled
    Docker-Log "Checking docker requirements"


    $status = Get-WindowsOptionalFeature -Online -FeatureName $dockerFeature
    if ($status.State -eq "Enabled") {
        Docker-Log "requirements for docker installation met. Continuing..." -Completed
        return
    }
    # Virtualization isn't enabled 3:
    Docker-Log "Docker requires virtualization to be enabled. Please enable virtualization. If this is not possible, cry."
    throw ("Docker requirements not met! Panicking!")
}

####################################################### HELPERS ##############################################################
Function Check-Privileges {
    if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Start-Process -FilePath PowerShell.exe -WorkingDirectory $PWD -Verb Runas -ArgumentList "-NoExit -Command cd $PWD ; .\bloodhound.ps1 $($progress)"
        Exit
    }
}

# Update the status of the activity and also log it in the console
Function Docker-Log {
    param (
        $message,
        $dockerID = 1
    )

    Write-Progress -Activity $dockerActivity -Status $message -Id $dockerID @Args
    Write-Host "[Docker Install]: $($message)" -InformationAction Continue -ForegroundColor Cyan
}

# Schedule this script to run on next startup via a scheduled task.
Function Schedule-Script-Startup {
    param (
        $state
    )
    # Create the action
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoExit -Command '$($PSScriptRoot)\bloodhound.ps1 $($state)'"

    # Set to run as local system
    $principal = New-ScheduledTaskPrincipal -UserID "$($Env:COMPUTERNAME)\$($Env:USERNAME)" -LogonType Interactive -RunLevel Highest

    # set to run at startup could also do -AtLogOn for the trigger
    $trigger = New-ScheduledTaskTrigger -AtLogOn

    # register it (save it) and it will show up in default folder of task scheduler.
    Register-ScheduledTask -Action $action -TaskName $TaskName -TaskPath '\' -Principal $principal -Trigger $trigger

}

# You think I'd write this? I stole this off of github :3
function Pause-ForWarning {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [int]$PauseTimeInSeconds,

        [Parameter(Mandatory=$True)]
        $Message
    )

    Write-Warning $Message
    Write-Host "To answer in the affirmative, press 'y' on your keyboard."
    Write-Host "To answer in the negative, press any other key on your keyboard, OR wait $PauseTimeInSeconds seconds"

    $timeout = New-Timespan -Seconds ($PauseTimeInSeconds - 1)
    $stopwatch = [diagnostics.stopwatch]::StartNew()
    while ($stopwatch.elapsed -lt $timeout){
        if ([Console]::KeyAvailable) {
            $keypressed = [Console]::ReadKey("NoEcho").Key
            Write-Host "You pressed the `"$keypressed`" key"
            if ($keypressed -eq "y") {
                $Result = $true
                break
            }
            if ($keypressed -ne "y") {
                $Result = $false
                break
            }
        }

        # Check once every 1 second to see if the above "if" condition is satisfied
        Start-Sleep 1
    }

    if (!$Result) {
        $Result = $false
    }

    $Result
}
####################################################### SCRIPT START #########################################################
# Check to see if the previous task exists, removing it if so
Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue -ErrorVariable ScheduleError
if (!($ScheduleError)) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# start the script
main
