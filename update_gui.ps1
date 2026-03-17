<#!
GUI Update Script — update_gui.ps1
Vienkāršs GUI ar pogām skolotājam:
  ✔ Pull (lejupielāde no GitHub)
  ✔ Add + Commit + Push (augšupielāde uz GitHub)
  ✔ Rāda statusu logā
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Log form
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Git Update GUI"
$form.Size          = New-Object System.Drawing.Size(520,420)
$form.StartPosition = "CenterScreen"

# Output box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline  = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Size       = New-Object System.Drawing.Size(480,260)
$outputBox.Location   = New-Object System.Drawing.Point(10,10)
$outputBox.ReadOnly   = $true
$form.Controls.Add($outputBox)

function Log($msg){
    $outputBox.AppendText("$msg`r`n")
}

# Buttons
$btnPull = New-Object System.Windows.Forms.Button
$btnPull.Text      = "Pull (Saņemt izmaiņas)"
$btnPull.Size      = New-Object System.Drawing.Size(220,40)
$btnPull.Location  = New-Object System.Drawing.Point(10,290)
$form.Controls.Add($btnPull)

$btnPush = New-Object System.Windows.Forms.Button
$btnPush.Text      = "Add + Commit + Push"
$btnPush.Size      = New-Object System.Drawing.Size(220,40)
$btnPush.Location  = New-Object System.Drawing.Point(260,290)
$form.Controls.Add($btnPush)

# Commit message box
$msgLabel = New-Object System.Windows.Forms.Label
$msgLabel.Text     = "Commit ziņa:"
$msgLabel.Location = New-Object System.Drawing.Point(10,340)
$msgLabel.Size     = New-Object System.Drawing.Size(100,20)
$form.Controls.Add($msgLabel)

$msgBox = New-Object System.Windows.Forms.TextBox
$msgBox.Location = New-Object System.Drawing.Point(110,340)
$msgBox.Size     = New-Object System.Drawing.Size(360,20)
$form.Controls.Add($msgBox)

# Git functions
function RunGit($cmd){
    Log("> git $cmd")
    $result = git $cmd 2>&1
    Log($result)
}

# Pull handler
$btnPull.Add_Click({
    Log("=== GIT PULL START ===")
    RunGit "pull"
    Log("=== DONE ===")
})

# Push handler
$btnPush.Add_Click({
    Log("=== GIT PUSH START ===")

    $commitMsg = $msgBox.Text
    if([string]::IsNullOrWhiteSpace($commitMsg)){
        $commitMsg = "Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Log("Nav commit ziņas — izmantošu automātisko: $commitMsg")
    }

    RunGit "add ."
    RunGit "commit -m '$commitMsg'"
    RunGit "push"

    Log("=== DONE ===")
})

[void]$form.ShowDialog()
