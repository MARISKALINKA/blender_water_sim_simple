<#
update_gui_adv.ps1 — Git GUI with branch selection and status indicators

Features:
  • Branch selector (ComboBox) + Checkout button
  • Pull, Add+Commit+Push buttons
  • Status indicators: Git, Repo, Origin, Branch
  • Console log with command output
  • Auto commit message if empty

Usage:
  1) Place this script in your repo root (next to the .git folder)
  2) PowerShell (current session):  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  3) Run:  ./update_gui_adv.ps1
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Ensure script runs from its own folder
try {
  $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  if ($scriptDir) { Set-Location -Path $scriptDir }
} catch {}

# ---------- Helpers ----------
function New-StatusLabel([string]$text,[int]$x,[int]$y){
  $panel = New-Object System.Windows.Forms.Panel
  $panel.Size = New-Object System.Drawing.Size(18,18)
  $panel.Location = New-Object System.Drawing.Point($x,$y)
  $panel.BackColor = [System.Drawing.Color]::LightGray

  $label = New-Object System.Windows.Forms.Label
  $label.Text = $text
  $label.Location = New-Object System.Drawing.Point($x+24,$y)
  $label.AutoSize = $true

  return @($panel,$label)
}

function Set-Status($panel,[bool]$ok){
  if($ok){ $panel.BackColor = [System.Drawing.Color]::PaleGreen }
  else   { $panel.BackColor = [System.Drawing.Color]::Salmon }
}

function Log($msg){
  $ts = (Get-Date).ToString('HH:mm:ss')
  $global:OutBox.AppendText("[$ts] $msg`r`n")
}

function Run-Git([string]$args){
  Log "> git $args"
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "git"
  $psi.Arguments = $args
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  if($stdout){ Log $stdout.TrimEnd() }
  if($stderr){ Log $stderr.TrimEnd() }
  return $p.ExitCode
}

function Get-CurrentBranch(){
  try{ (git rev-parse --abbrev-ref HEAD) 2>$null | Select-Object -First 1 }
  catch{ $null }
}

function Get-LocalBranches(){
  try{ git for-each-ref --format='%(refname:short)' refs/heads 2>$null }
  catch{ @() }
}

function Refresh-Status(){
  # Git
  $global:GitOK = $false
  $gitVer = (& git --version) 2>$null
  if($LASTEXITCODE -eq 0 -and $gitVer){
    $GitLabel.Text = "Git: $gitVer"
    Set-Status $GitLight $true
    $global:GitOK = $true
  } else {
    $GitLabel.Text = "Git not found (install: git-scm.com)"
    Set-Status $GitLight $false
  }

  # Repo
  $global:RepoOK = $false
  $top = (& git rev-parse --show-toplevel) 2>$null
  if($LASTEXITCODE -eq 0 -and $top){
    $RepoLabel.Text = "Repo: $top"
    Set-Status $RepoLight $true
    $global:RepoOK = $true
  } else {
    $RepoLabel.Text = ".git not found in this folder"
    Set-Status $RepoLight $false
  }

  # Origin
  $global:OriginOK = $false
  $origin = (& git remote get-url origin) 2>$null
  if($LASTEXITCODE -eq 0 -and $origin){
    $OriginLabel.Text = "Origin: $origin"
    Set-Status $OriginLight $true
    $global:OriginOK = $true
  } else {
    $OriginLabel.Text = "Origin not set (use: git remote add origin <URL>)"
    Set-Status $OriginLight $false
  }

  # Branch
  $global:BranchOK = $false
  $cur = Get-CurrentBranch
  if(-not [string]::IsNullOrWhiteSpace($cur)){
    $BranchLabel.Text = "Branch: $cur"
    Set-Status $BranchLight $true
    $global:BranchOK = $true
  } else {
    $BranchLabel.Text = "Branch unknown"
    Set-Status $BranchLight $false
  }

  # ComboBox fill
  $BranchesCombo.Items.Clear()
  if($RepoOK){
    $branches = Get-LocalBranches
    foreach($b in $branches){ [void]$BranchesCombo.Items.Add($b) }
    if($cur){ $BranchesCombo.SelectedItem = $cur }
  }
}

# ---------- UI ----------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Git Update GUI (Branch + Status)"
$form.Size          = New-Object System.Drawing.Size(780,560)
$form.StartPosition = "CenterScreen"

# Status indicators
$GitLight,$GitLabel       = New-StatusLabel "Git"    10  10
$RepoLight,$RepoLabel     = New-StatusLabel "Repo"   10  40
$OriginLight,$OriginLabel = New-StatusLabel "Origin" 10  70
$BranchLight,$BranchLabel = New-StatusLabel "Branch" 10 100

$form.Controls.AddRange(@($GitLight,$GitLabel,$RepoLight,$RepoLabel,$OriginLight,$OriginLabel,$BranchLight,$BranchLabel))

# Branch select + Checkout
$lblChoose = New-Object System.Windows.Forms.Label
$lblChoose.Text = "Select branch:"
$lblChoose.Location = New-Object System.Drawing.Point(10,140)
$lblChoose.AutoSize = $true
$form.Controls.Add($lblChoose)

$BranchesCombo = New-Object System.Windows.Forms.ComboBox
$BranchesCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$BranchesCombo.Location = New-Object System.Drawing.Point(120,136)
$BranchesCombo.Size = New-Object System.Drawing.Size(290,22)
$form.Controls.Add($BranchesCombo)

$btnCheckout = New-Object System.Windows.Forms.Button
$btnCheckout.Text = "Checkout"
$btnCheckout.Location = New-Object System.Drawing.Point(420,134)
$btnCheckout.Size = New-Object System.Drawing.Size(100,26)
$form.Controls.Add($btnCheckout)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Refresh status"
$btnRefresh.Location = New-Object System.Drawing.Point(530,134)
$btnRefresh.Size = New-Object System.Drawing.Size(140,26)
$form.Controls.Add($btnRefresh)

# Commit message
$msgLabel = New-Object System.Windows.Forms.Label
$msgLabel.Text = "Commit message:"
$msgLabel.Location = New-Object System.Drawing.Point(10,175)
$msgLabel.AutoSize = $true
$form.Controls.Add($msgLabel)

$msgBox = New-Object System.Windows.Forms.TextBox
$msgBox.Location = New-Object System.Drawing.Point(120,172)
$msgBox.Size     = New-Object System.Drawing.Size(550,22)
$form.Controls.Add($msgBox)

# Buttons: Pull / Push
$btnPull = New-Object System.Windows.Forms.Button
$btnPull.Text = "Pull (fetch latest)"
$btnPull.Location = New-Object System.Drawing.Point(10,210)
$btnPull.Size = New-Object System.Drawing.Size(240,34)
$form.Controls.Add($btnPull)

$btnPush = New-Object System.Windows.Forms.Button
$btnPush.Text = "Add + Commit + Push"
$btnPush.Location = New-Object System.Drawing.Point(260,210)
$btnPush.Size = New-Object System.Drawing.Size(240,34)
$form.Controls.Add($btnPush)

# Output log
$OutBox = New-Object System.Windows.Forms.TextBox
$OutBox.Multiline  = $true
$OutBox.ScrollBars = "Vertical"
$OutBox.Location   = New-Object System.Drawing.Point(10,260)
$OutBox.Size       = New-Object System.Drawing.Size(740,250)
$OutBox.ReadOnly   = $true
$form.Controls.Add($OutBox)

# ---------- Events ----------
$btnRefresh.Add_Click({ Refresh-Status })

$btnCheckout.Add_Click({
  if(-not $RepoOK){ Log "Repo not active (.git missing)."; return }
  $sel = $BranchesCombo.SelectedItem
  if([string]::IsNullOrWhiteSpace($sel)){ Log "No branch selected."; return }
  $code = Run-Git "checkout `"$sel`""
  if($code -eq 0){ Refresh-Status }
})

$btnPull.Add_Click({
  if(-not $RepoOK){ Log "Repo not active (.git missing)."; return }
  Log "=== GIT PULL START ==="
  Run-Git "pull"
  Log "=== DONE ==="
})

$btnPush.Add_Click({
  if(-not $RepoOK){ Log "Repo not active (.git missing)."; return }
  if(-not $OriginOK){ Log "Origin not set."; return }

  $commitMsg = $msgBox.Text
  if([string]::IsNullOrWhiteSpace($commitMsg)){
    $commitMsg = "Update: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Log "No commit message — using: $commitMsg"
  }

  Log "=== GIT PUSH START ==="
  Run-Git "add ."
  $code = Run-Git "commit -m `"$commitMsg`""
  if($code -ne 0){ Log "(no changes or commit error)" }

  $cur = Get-CurrentBranch
  if([string]::IsNullOrWhiteSpace($cur)){ $cur = "main" }
  $code2 = Run-Git "push -u origin `"$cur`""
  if($code2 -eq 0){ Log "=== DONE ===" } else { Log "Push failed (check auth/URL/branch)" }
  Refresh-Status
})

# Initial
Refresh-Status

[void]$form.ShowDialog()
