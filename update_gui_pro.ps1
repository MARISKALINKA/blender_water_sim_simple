<#
update_gui_pro.ps1 — Professional Git panel GUI (mini Git client)

Features:
  • Buttons: Fetch, Pull, Stage All, Commit, Push, Change Branch
  • Branch selector (ComboBox) + Checkout
  • Status indicators (lights): Git, Repo, Origin, Branch
  • Live indicators via timer (auto refresh)
  • RichTextBox log with colored levels; auto-scroll
  • Auto commit message when empty (timestamp)

Usage:
  1) Place this script in your repo root (next to the .git folder)
  2) PowerShell (current session):  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  3) Run:  ./update_gui_pro.ps1

Note:
  • This script uses only ASCII in strings to avoid locale parser issues.
  • If you see auth prompts, use a GitHub Personal Access Token as password.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Ensure current directory is the script location
try {
  $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  if ($scriptDir) { Set-Location -Path $scriptDir }
} catch {}

# ----------------- Helpers -----------------
function New-StatusLight([string]$text, [int]$x, [int]$y){
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

function Set-Light($panel, [bool]$ok){
  if($ok){ $panel.BackColor = [System.Drawing.Color]::PaleGreen }
  else   { $panel.BackColor = [System.Drawing.Color]::Salmon }
}

# Rich log helpers
function Log-Write([string]$text, [string]$level="INFO"){
  $time = (Get-Date).ToString('HH:mm:ss')
  switch ($level) {
    "INFO" { $Log.SelectionColor = [System.Drawing.Color]::Black }
    "WARN" { $Log.SelectionColor = [System.Drawing.Color]::Goldenrod }
    "ERRO" { $Log.SelectionColor = [System.Drawing.Color]::Crimson }
    default { $Log.SelectionColor = [System.Drawing.Color]::Black }
  }
  $Log.AppendText("[$time] [$level] $text`r`n")
  $Log.SelectionStart = $Log.TextLength
  $Log.ScrollToCaret()
}

function Log-Info($t){ Log-Write $t "INFO" }
function Log-Warn($t){ Log-Write $t "WARN" }
function Log-Err ($t){ Log-Write $t "ERRO" }

function Run-Git([string]$args){
  Log-Info "> git $args"
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
  if($stdout){ Log-Info ($stdout.TrimEnd()) }
  if($stderr){ Log-Warn ($stderr.TrimEnd()) }
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

function Refresh-Status{
  # Git present
  $global:GitOK = $false
  $ver = (& git --version) 2>$null
  if($LASTEXITCODE -eq 0 -and $ver){
    $GitLabel.Text = "Git: $ver"
    Set-Light $GitLight $true
    $global:GitOK = $true
  } else {
    $GitLabel.Text = "Git not found (install git-scm.com)"
    Set-Light $GitLight $false
  }

  # Repo present
  $global:RepoOK = $false
  $root = (& git rev-parse --show-toplevel) 2>$null
  if($LASTEXITCODE -eq 0 -and $root){
    $RepoLabel.Text = "Repo: $root"
    Set-Light $RepoLight $true
    $global:RepoOK = $true
  } else {
    $RepoLabel.Text = "Not a git repo here (.git missing)"
    Set-Light $RepoLight $false
  }

  # Origin set
  $global:OriginOK = $false
  $origin = (& git remote get-url origin) 2>$null
  if($LASTEXITCODE -eq 0 -and $origin){
    $OriginLabel.Text = "Origin: $origin"
    Set-Light $OriginLight $true
    $global:OriginOK = $true
  } else {
    $OriginLabel.Text = "Origin not set (git remote add origin <URL>)"
    Set-Light $OriginLight $false
  }

  # Branch info
  $global:BranchOK = $false
  $cur = Get-CurrentBranch
  if(-not [string]::IsNullOrWhiteSpace($cur)){
    $BranchLabel.Text = "Branch: $cur"
    Set-Light $BranchLight $true
    $global:BranchOK = $true
  } else {
    $BranchLabel.Text = "Branch unknown"
    Set-Light $BranchLight $false
  }

  # Fill branch combo
  $BranchCombo.Items.Clear()
  if($global:RepoOK){
    $list = Get-LocalBranches
    foreach($b in $list){ [void]$BranchCombo.Items.Add($b) }
    if($cur){ $BranchCombo.SelectedItem = $cur }
  }
}

# ----------------- UI -----------------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Git Update Pro (Branch + Status + Log)"
$form.Size          = New-Object System.Drawing.Size(900,640)
$form.StartPosition = "CenterScreen"

# Status lights row
$GitLight,$GitLabel       = New-StatusLight "Git"    12  12
$RepoLight,$RepoLabel     = New-StatusLight "Repo"   12  40
$OriginLight,$OriginLabel = New-StatusLight "Origin" 12  68
$BranchLight,$BranchLabel = New-StatusLight "Branch" 12  96
$form.Controls.AddRange(@($GitLight,$GitLabel,$RepoLight,$RepoLabel,$OriginLight,$OriginLabel,$BranchLight,$BranchLabel))

# Branch selector
$lblSel = New-Object System.Windows.Forms.Label
$lblSel.Text = "Select branch:"
$lblSel.Location = New-Object System.Drawing.Point(12,132)
$lblSel.AutoSize = $true
$form.Controls.Add($lblSel)

$BranchCombo = New-Object System.Windows.Forms.ComboBox
$BranchCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$BranchCombo.Location = New-Object System.Drawing.Point(110,128)
$BranchCombo.Size = New-Object System.Drawing.Size(260,24)
$form.Controls.Add($BranchCombo)

$btnCheckout = New-Object System.Windows.Forms.Button
$btnCheckout.Text = "Change Branch"
$btnCheckout.Location = New-Object System.Drawing.Point(380,126)
$btnCheckout.Size = New-Object System.Drawing.Size(130,28)
$form.Controls.Add($btnCheckout)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Refresh"
$btnRefresh.Location = New-Object System.Drawing.Point(520,126)
$btnRefresh.Size = New-Object System.Drawing.Size(100,28)
$form.Controls.Add($btnRefresh)

# Buttons bar
$btnFetch = New-Object System.Windows.Forms.Button
$btnFetch.Text = "Fetch"
$btnFetch.Location = New-Object System.Drawing.Point(12,170)
$btnFetch.Size = New-Object System.Drawing.Size(100,32)
$form.Controls.Add($btnFetch)

$btnPull = New-Object System.Windows.Forms.Button
$btnPull.Text = "Pull"
$btnPull.Location = New-Object System.Drawing.Point(118,170)
$btnPull.Size = New-Object System.Drawing.Size(100,32)
$form.Controls.Add($btnPull)

$btnStage = New-Object System.Windows.Forms.Button
$btnStage.Text = "Stage All"
$btnStage.Location = New-Object System.Drawing.Point(224,170)
$btnStage.Size = New-Object System.Drawing.Size(100,32)
$form.Controls.Add($btnStage)

$btnCommit = New-Object System.Windows.Forms.Button
$btnCommit.Text = "Commit"
$btnCommit.Location = New-Object System.Drawing.Point(330,170)
$btnCommit.Size = New-Object System.Drawing.Size(100,32)
$form.Controls.Add($btnCommit)

$btnPush = New-Object System.Windows.Forms.Button
$btnPush.Text = "Push"
$btnPush.Location = New-Object System.Drawing.Point(436,170)
$btnPush.Size = New-Object System.Drawing.Size(100,32)
$form.Controls.Add($btnPush)

# Commit message
$lblMsg = New-Object System.Windows.Forms.Label
$lblMsg.Text = "Commit message:"
$lblMsg.Location = New-Object System.Drawing.Point(12,212)
$lblMsg.AutoSize = $true
$form.Controls.Add($lblMsg)

$MsgBox = New-Object System.Windows.Forms.TextBox
$MsgBox.Location = New-Object System.Drawing.Point(120,210)
$MsgBox.Size = New-Object System.Drawing.Size(760,24)
$form.Controls.Add($MsgBox)

# Log (RichTextBox)
$Log = New-Object System.Windows.Forms.RichTextBox
$Log.Location = New-Object System.Drawing.Point(12,244)
$Log.Size = New-Object System.Drawing.Size(868,346)
$Log.ReadOnly = $true
$Log.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($Log)

# ----------------- Events -----------------
$btnRefresh.Add_Click({ Refresh-Status })

$btnCheckout.Add_Click({
  if(-not $RepoOK){ Log-Err "Repo not active (.git missing)"; return }
  $sel = $BranchCombo.SelectedItem
  if([string]::IsNullOrWhiteSpace($sel)){ Log-Warn "No branch selected"; return }
  $code = Run-Git "checkout `"$sel`""
  if($code -eq 0){ Refresh-Status }
})

$btnFetch.Add_Click({
  if(-not $RepoOK){ Log-Err "Repo not active (.git missing)"; return }
  Log-Info "=== FETCH ==="
  Run-Git "fetch --all --prune"
  Log-Info "Done"
})

$btnPull.Add_Click({
  if(-not $RepoOK){ Log-Err "Repo not active (.git missing)"; return }
  Log-Info "=== PULL ==="
  Run-Git "pull"
  Log-Info "Done"
})

$btnStage.Add_Click({
  if(-not $RepoOK){ Log-Err "Repo not active (.git missing)"; return }
  Log-Info "=== STAGE ALL ==="
  Run-Git "add ."
  Log-Info "Done"
})

$btnCommit.Add_Click({
  if(-not $RepoOK){ Log-Err "Repo not active (.git missing)"; return }
  $msg = $MsgBox.Text
  if([string]::IsNullOrWhiteSpace($msg)){
    $msg = "Update: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Log-Warn ("No commit message, using: " + $msg)
  }
  Log-Info "=== COMMIT ==="
  $code = Run-Git "commit -m `"$msg`""
  if($code -ne 0){ Log-Warn "Nothing to commit or commit error" } else { Log-Info "Committed" }
})

$btnPush.Add_Click({
  if(-not $RepoOK){ Log-Err "Repo not active (.git missing)"; return }
  if(-not $OriginOK){ Log-Err "Origin not set"; return }
  $cur = Get-CurrentBranch
  if([string]::IsNullOrWhiteSpace($cur)){ $cur = "main" }
  Log-Info "=== PUSH ==="
  $code = Run-Git "push -u origin `"$cur`""
  if($code -eq 0){ Log-Info "Done" } else { Log-Err "Push failed (check auth/URL/branch)" }
})

# Live status via timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.Add_Tick({ Refresh-Status })
$timer.Start()

# Initial
Refresh-Status

[void]$form.ShowDialog()
