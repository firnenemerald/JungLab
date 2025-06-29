<#
.SYNOPSIS
    Creates folders in a destination directory that match the names of folders in a source directory.
    The newly created folders will be empty.

.DESCRIPTION
    This script iterates through all folders in a specified source directory.
    For each folder found in the source, it creates a corresponding empty folder
    in the specified destination directory. If a folder with the same name already
    exists in the destination, it will not be modified or overwritten, but a
    warning will be displayed.

.PARAMETER SourceDirectory
    The full path to the directory containing the original folders (dir1).
    This parameter is mandatory.

.PARAMETER DestinationDirectory
    The full path to the directory where the new empty folders will be created (dir2).
    This parameter is mandatory.

.EXAMPLE
    .\Create-MatchingFolders.ps1 -SourceDirectory "C:\SourceFolders" -DestinationDirectory "C:\DestinationFolders"

    This command will look for folders in "C:\SourceFolders". If it finds "C:\SourceFolders\ProjectA"
    and "C:\SourceFolders\ProjectB", it will create "C:\DestinationFolders\ProjectA" and
    "C:\DestinationFolders\ProjectB" (if they don't already exist). These new folders
    will be empty.

.NOTES
    Author: Your Name/AI Assistant
    Date:   2025-06-02
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$true,
               HelpMessage="Enter the full path to the source directory (dir1).")]
    [string]$SourceDirectory,

    [Parameter(Mandatory=$true,
               HelpMessage="Enter the full path to the destination directory (dir2).")]
    [string]$DestinationDirectory
)

# Validate that the source directory exists
if (-not (Test-Path -Path $SourceDirectory -PathType Container)) {
    Write-Error "Source directory '$SourceDirectory' not found or is not a directory. Please check the path."
    exit 1 # Exit with an error code
}

# Validate that the destination directory exists. If not, offer to create it.
if (-not (Test-Path -Path $DestinationDirectory -PathType Container)) {
    Write-Warning "Destination directory '$DestinationDirectory' not found."
    if ($PSCmdlet.ShouldProcess("Create destination directory '$DestinationDirectory'?", "The destination directory does not exist. Do you want to create it?")) {
        try {
            New-Item -Path $DestinationDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Verbose "Successfully created destination directory: $DestinationDirectory"
        }
        catch {
            Write-Error "Failed to create destination directory '$DestinationDirectory'. Please check permissions and path. Error: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Error "Destination directory not found and not created. Script cannot continue."
        exit 1
    }
}

# Get all folders from the source directory
try {
    $sourceFolders = Get-ChildItem -Path $SourceDirectory -Directory -ErrorAction Stop
}
catch {
    Write-Error "Error accessing source directory '$SourceDirectory'. Error: $($_.Exception.Message)"
    exit 1
}

if ($sourceFolders.Count -eq 0) {
    Write-Warning "No folders found in the source directory: $SourceDirectory"
    exit 0 # Exit successfully as there's nothing to do
}

Write-Host "Starting to process folders from '$SourceDirectory' to '$DestinationDirectory'..."

# Loop through each folder in the source directory
foreach ($folder in $sourceFolders) {
    $sourceFolderName = $folder.Name
    $destinationFolderPath = Join-Path -Path $DestinationDirectory -ChildPath $sourceFolderName

    Write-Verbose "Processing source folder: $($folder.FullName)"
    Write-Verbose "Target destination path: $destinationFolderPath"

    # Check if a folder with the same name already exists in the destination
    if (Test-Path -Path $destinationFolderPath -PathType Container) {
        Write-Warning "Folder '$sourceFolderName' already exists in '$DestinationDirectory'. Skipping."
    }
    else {
        # Create the new empty folder in the destination directory
        if ($PSCmdlet.ShouldProcess("Create empty folder '$destinationFolderPath'", "Create folder '$sourceFolderName' in '$DestinationDirectory'?")) {
            try {
                New-Item -Path $destinationFolderPath -ItemType Directory -ErrorAction Stop | Out-Null
                Write-Host "Successfully created empty folder: $destinationFolderPath"
            }
            catch {
                Write-Error "Failed to create folder '$destinationFolderPath'. Error: $($_.Exception.Message)"
                # Optionally, you might want to continue with other folders or stop
                # continue
            }
        }
    }
}

Write-Host "Folder creation process completed."
