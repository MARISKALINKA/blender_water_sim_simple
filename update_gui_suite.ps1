<#
update_gui_suite.ps1 — Git GUI Suite (wide layout, EN-only)

Features:
  • Buttons: Fetch, Pull, Stage All, Commit, Push, Change Branch, Refresh
  • Branch selector (ComboBox) + Change Branch (checkout)
  • Remote branches list + Create New Branch (from typed name or tracking selected remote)
  • Select Folder (work with any repo without moving the script)
  • Staged / Untracked files panels (index viewer)
  • Auto‑pull toggle with interval (minutes)
  • Status indicators (lights): Git, Repo, Origin, Branch, Credentials
  • Auto‑refresh indicators every 5 seconds
  • RichTextBox log with colored levels; auto‑scroll
  • Continuous log file (append): <repo>\logs\git_client_log.txt

Usage:
  1) Run in PowerShell: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  2) Start: ./update_gui_suite.ps1
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------ Globals ------------
$script:CurrentRepoDir = (Get-Location).Path
$script:LogDir  = Join-Path $script:CurrentRepoDir 'logs'
$script:LogFile = Join-Path $script:LogDir 'git_client_log.txt'
$script:AutoPullTimer   = $null
$script:AutoPullHandler = $null
$script:StatusTimer     = $null
$script:Status = @{}   # map: key -> @{Panel=..., Label=...}

# ------------ Logging ------------
function Ensure-LogContext {
  if (-not (Test-Path $script:LogDir)) { New-Item -ItemType Directory -Path $script:LogDir | Out-Null }
  if (-not (Test-Path $script:LogFile)) { New-Item -ItemType File -Path $script:LogFile | Out-Null }
}

function Write-LogFile([string]$line){
  try { Add-Content -Path $script:LogFile -Value $line -Encoding UTF8 } catch {}
}

function Log-Write([string]$text, [string]$level="INFO"){
  if (-not $global:LogBox) { return }
  $time = (Get-Date).ToString('HH:mm:ss')
  switch ($level) {
    "INFO" { $global:LogBox.SelectionColor = [System.Drawing.Color]::Black }
    "WARN" { $global:LogBox.SelectionColor = [System.Drawing.Color]::Goldenrod }
    "ERRO" { $global:LogBox.SelectionColor = [System.Drawing.Color]::Crimson }
    default { $global:LogBox.SelectionColor = [System.Drawing.Color]::Black }
  }
  $line = "[$time] [$level] $text"
  $global:LogBox.AppendText($line + "`r`n")
  $global:LogBox.SelectionStart = $global:LogBox.TextLength
  $global:LogBox.ScrollToCaret()
  Write-LogFile $line
}

function Log-Info($t){ Log-Write $t "INFO" }
function Log-Warn($t){ Log-Write $t "WARN" }
function Log-Err ($t){ Log-Write $t "ERRO" }

# ------------ Git helpers ------------
function In-Repo([string]$dir){ Test-Path (Join-Path $dir '.git') }

function Run-Git([string]$args){
  if (-not (Test-Path $script:CurrentRepoDir)) { Log-Err "Repo folder not found"; return 1 }
  Log-Info "> git $args"
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "git"
  $psi.Arguments = $args
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.WorkingDirectory = $script:CurrentRepoDir
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  if($stdout){ Log-Info ($stdout.TrimEnd()) }
  if($stderr){ Log-Warn ($stderr.TrimEnd()) }
  Log-Info ("Exit code: " + $p.ExitCode)
  return $p.ExitCode
}

function Get-CurrentBranch(){ try{ (git -C $script:CurrentRepoDir rev-parse --abbrev-ref HEAD) 2>$null | Select-Object -First 1 } catch{ $null } }
function Get-LocalBranches(){ try{ git -C $script:CurrentRepoDir for-each-ref --format='%(refname:short)' refs/heads 2>$null } catch{ @() } }
function Get-RemoteBranches(){ try{ git -C $script:CurrentRepoDir for-each-ref --format='%(refname:short)' refs/remotes 2>$null } catch{ @() } }

function Test-Credentials(){
  $env:GIT_TERMINAL_PROMPT = '0'
  $code = Run-Git "ls-remote --heads origin"
  Remove-Item Env:\GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
  return ($code -eq 0)
}

# ------------ UI helpers ------------
function Add-StatusLight([string]$key,[string]$text,[int]$x,[int]$y){
  $panel = New-Object System.Windows.Forms.Panel
  $panel.Size = New-Object System.Drawing.Size(16,16)
  $panel.Location = New-Object System.Drawing.Point($x,$y)
  $panel.BackColor = [System.Drawing.Color]::LightGray

  $label = New-Object System.Windows.Forms.Label
  $label.Text = $text
  $label.Location = New-Object System.Drawing.Point($x+22,$y-2)
  $label.AutoSize = $true

  $form.Controls.Add($panel)
  $form.Controls.Add($label)
  $script:Status[$key] = @{ Panel = $panel; Label = $label }
}

function Set-StatusColor([string]$key,[bool]$ok){
  $item = $script:Status[$key]
  if($item -and $item.Panel){
    if($ok){ $item.Panel.BackColor = [System.Drawing.Color]::PaleGreen }
    else   { $item.Panel.BackColor = [System.Drawing.Color]::Salmon }
  }
}

function Set-StatusText([string]$key,[string]$text){
  $item = $script:Status[$key]
  if($item -and $item.Label){ $item.Label.Text = $text }
}

# ------------ Build UI (wide layout) ------------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Git GUI Suite (Branch + Remotes + Files + Log)"
$form.Size          = New-Object System.Drawing.Size(1200,780)
$form.StartPosition = "CenterScreen"

# Top bar
$btnFolder = New-Object System.Windows.Forms.Button
$btnFolder.Text = "Select Folder"
$btnFolder.Location = New-Object System.Drawing.Point(12,12)
$btnFolder.Size = New-Object System.Drawing.Size(120,28)
$form.Controls.Add($btnFolder)

$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text = "Repo: $script:CurrentRepoDir"
$lblPath.Location = New-Object System.Drawing.Point(140,16)
$lblPath.AutoSize = $true
$form.Controls.Add($lblPath)

# Status lights (left column)
Add-StatusLight -key 'Git'    -text 'Git'          -x 12 -y 52
Add-StatusLight -key 'Repo'   -text 'Repo'         -x 12 -y 78
Add-StatusLight -key 'Origin' -text 'Origin'       -x 12 -y 104
Add-StatusLight -key 'Branch' -text 'Branch'       -x 12 -y 130
Add-StatusLight -key 'Creds'  -text 'Credentials'  -x 12 -y 156

# Branch selector row
$lblSel = New-Object System.Windows.Forms.Label
$lblSel.Text = "Select branch:"
$lblSel.Location = New-Object System.Drawing.Point(180,52)
$lblSel.AutoSize = $true
$form.Controls.Add($lblSel)

$BranchCombo = New-Object System.Windows.Forms.ComboBox
$BranchCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$BranchCombo.Location = New-Object System.Drawing.Point(280,48)
$BranchCombo.Size = New-Object System.Drawing.Size(260,24)
$form.Controls.Add($BranchCombo)

$btnCheckout = New-Object System.Windows.Forms.Button
$btnCheckout.Text = "Change Branch"
$btnCheckout.Location = New-Object System.Drawing.Point(548,46)
$btnCheckout.Size = New-Object System.Drawing.Size(120,28)
$form.Controls.Add($btnCheckout)

# Remote branches
$lblRem = New-Object System.Windows.Forms.Label
$lblRem.Text = "Remote branches:"
$lblRem.Location = New-Object System.Drawing.Point(180,82)
$lblRem.AutoSize = $true
$form.Controls.Add($lblRem)

$RemoteList = New-Object System.Windows.Forms.ListBox
$RemoteList.Location = New-Object System.Drawing.Point(180,100)
$RemoteList.Size = New-Object System.Drawing.Size(300,120)
$form.Controls.Add($RemoteList)

$btnRefRem = New-Object System.Windows.Forms.Button
$btnRefRem.Text = "Refresh Remotes"
$btnRefRem.Location = New-Object System.Drawing.Point(488,100)
$btnRefRem.Size = New-Object System.Drawing.Size(120,26)
$form.Controls.Add($btnRefRem)

$txtNewBranch = New-Object System.Windows.Forms.TextBox
$txtNewBranch.Location = New-Object System.Drawing.Point(488,132)
$txtNewBranch.Size = New-Object System.Drawing.Size(180,24)
$form.Controls.Add($txtNewBranch)

$btnCreateBranch = New-Object System.Windows.Forms.Button
$btnCreateBranch.Text = "Create New Branch"
$btnCreateBranch.Location = New-Object System.Drawing.Point(488,162)
$btnCreateBranch.Size = New-Object System.Drawing.Size(180,28)
$form.Controls.Add($btnCreateBranch)

# Auto-pull controls
$chkAutoPull = New-Object System.Windows.Forms.CheckBox
$chkAutoPull.Text = "Auto-pull"
$chkAutoPull.Location = New-Object System.Drawing.Point(690,48)
$chkAutoPull.AutoSize = $true
$form.Controls.Add($chkAutoPull)

$lblInterval = New-Object System.Windows.Forms.Label
$lblInterval.Text = "Interval (min):"
$lblInterval.Location = New-Object System.Drawing.Point(780,52)
$lblInterval.AutoSize = $true
$form.Controls.Add($lblInterval)

$nudInterval = New-Object System.Windows.Forms.NumericUpDown
$nudInterval.Location = New-Object System.Drawing.Point(870,48)
$nudInterval.Size = New-Object System.Drawing.Size(60,24)
$nudInterval.Minimum = 1
$nudInterval.Maximum = 120
$nudInterval.Value = 5
$form.Controls.Add($nudInterval)

# Buttons toolbar
$btnFetch = New-Object System.Windows.Forms.Button
$btnFetch.Text = "Fetch"
$btnFetch.Location = New-Object System.Drawing.Point(690,100)
$btnFetch.Size = New-Object System.Drawing.Size(100,32)
$form.Controls.Add($btnFetch)

$btnPull = New-Object System.Windows.Forms.Button
$btnPull.Text = "Pull"
$btnPull.Location = New-Object System.Drawing.Point(796,100)
$btnPull.Size = New-Object System.Drawing.Size(100,32)
$form.Controls.Add($btnPull)

$btnStageAll = New-Object System.Windows.Forms.Button
$btnStageAll.Text = "Stage All"
$btnStageAll.Location = New-Object System.Drawing.Point(902,100)
$btnStageAll.Size = New-Object System.Drawing.Size(100,32)
$form.Controls.Add($btnStageAll)

$btnCommit = New-Object System.Windows.Forms.Button
$btnCommit.Text = "Commit"
$btnCommit.Location = New-Object System.Drawing.Point(1008,100)
$btnCommit.Size = New-Object System.Drawing.Size(100,32)
$form.Controls.Add($btnCommit)

$lblMsg = New-Object System.Windows.Forms.Label
$lblMsg.Text = "Commit message:"
$lblMsg.Location = New-Object System.Drawing.Point(690,140)
$lblMsg.AutoSize = $true
$form.Controls.Add($lblMsg)

$MsgBox = New-Object System.Windows.Forms.TextBox
$MsgBox.Location = New-Object System.Drawing.Point(690,160)
$MsgBox.Size = New-Object System.Drawing.Size(418,24)
$form.Controls.Add($MsgBox)

$btnPush = New-Object System.Windows.Forms.Button
$btnPush.Text = "Push"
$btnPush.Location = New-Object System.Drawing.Point(1008,158)
$btnPush.Size = New-Object System.Drawing.Size(100,28)
$form.Controls.Add($btnPush)

# Files panels
$lblStaged = New-Object System.Windows.Forms.Label
$lblStaged.Text = "Staged files"
$lblStaged.Location = New-Object System.Drawing.Point(12,240)
$lblStaged.AutoSize = $true
$form.Controls.Add($lblStaged)

$gridStaged = New-Object System.Windows.Forms.ListView
$gridStaged.View = [System.Windows.Forms.View]::Details
$gridStaged.FullRowSelect = $true
$gridStaged.Location = New-Object System.Drawing.Point(12,260)
$gridStaged.Size = New-Object System.Drawing.Size(560,220)
$colS = New-Object System.Windows.Forms.ColumnHeader
$colS.Text = "File"
$colS.Width = 530
[void]$gridStaged.Columns.Add($colS)
$form.Controls.Add($gridStaged)

$lblUntracked = New-Object System.Windows.Forms.Label
$lblUntracked.Text = "Untracked files"
$lblUntracked.Location = New-Object System.Drawing.Point(590,240)
$lblUntracked.AutoSize = $true
$form.Controls.Add($lblUntracked)

$gridUntracked = New-Object System.Windows.Forms.ListView
$gridUntracked.View = [System.Windows.Forms.View]::Details
$gridUntracked.FullRowSelect = $true
$gridUntracked.Location = New-Object System.Drawing.Point(590,260)
$gridUntracked.Size = New-Object System.Drawing.Size(520,220)
$colU = New-Object System.Windows.Forms.ColumnHeader
$colU.Text = "File"
$colU.Width = 490
[void]$gridUntracked.Columns.Add($colU)
$form.Controls.Add($gridUntracked)

$btnRefreshFiles = New-Object System.Windows.Forms.Button
$btnRefreshFiles.Text = "Refresh Files"
$btnRefreshFiles.Location = New-Object System.Drawing.Point(12,488)
$btnRefreshFiles.Size = New-Object System.Drawing.Size(120,28)
$form.Controls.Add($btnRefreshFiles)

# Log box
$global:LogBox = New-Object System.Windows.Forms.RichTextBox
$global:LogBox.Location = New-Object System.Drawing.Point(12,524)
$global:LogBox.Size = New-Object System.Drawing.Size(1098,210)
$global:LogBox.ReadOnly = $true
$global:LogBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($global:LogBox)

# ------------ Refresh helpers ------------
function Update-RepoContext([string]$newDir){
  if (-not (Test-Path $newDir)) { Log-Err "Folder not found"; return }
  $script:CurrentRepoDir = (Resolve-Path $newDir).Path
  $lblPath.Text = "Repo: $script:CurrentRepoDir"
  $script:LogDir  = Join-Path $script:CurrentRepoDir 'logs'
  $script:LogFile = Join-Path $script:LogDir 'git_client_log.txt'
  Ensure-LogContext
  Refresh-Status
  Refresh-Remotes
  Refresh-Files
}

function Refresh-Status{
  # Git
  $ver = (& git --version) 2>$null
  if($LASTEXITCODE -eq 0 -and $ver){ Set-StatusText 'Git' ("Git: " + $ver); Set-StatusColor 'Git' $true }
  else { Set-StatusText 'Git' 'Git not found (install git-scm.com)'; Set-StatusColor 'Git' $false }

  # Repo
  if(In-Repo $script:CurrentRepoDir){ Set-StatusText 'Repo' ("Repo: " + $script:CurrentRepoDir); Set-StatusColor 'Repo' $true }
  else { Set-StatusText 'Repo' 'Not a git repo here (.git missing)'; Set-StatusColor 'Repo' $false }

  # Origin
  $origin = (& git -C $script:CurrentRepoDir remote get-url origin) 2>$null
  if($LASTEXITCODE -eq 0 -and $origin){ Set-StatusText 'Origin' ("Origin: " + $origin); Set-StatusColor 'Origin' $true }
  else { Set-StatusText 'Origin' 'Origin not set (git remote add origin <URL>)'; Set-StatusColor 'Origin' $false }

  # Branch
  $cur = Get-CurrentBranch
  if(-not [string]::IsNullOrWhiteSpace($cur)){ Set-StatusText 'Branch' ("Branch: " + $cur); Set-StatusColor 'Branch' $true }
  else { Set-StatusText 'Branch' 'Branch unknown'; Set-StatusColor 'Branch' $false }

  # Credentials
  if($origin){
    if(Test-Credentials){ Set-StatusText 'Creds' 'Credentials: OK'; Set-StatusColor 'Creds' $true }
    else { Set-StatusText 'Creds' 'Credentials: missing/invalid'; Set-StatusColor 'Creds' $false }
  } else {
    Set-StatusText 'Creds' 'Credentials: N/A'; Set-StatusColor 'Creds' $false
  }

  # Branch combobox
  $BranchCombo.Items.Clear()
  if(In-Repo $script:CurrentRepoDir){
    $list = Get-LocalBranches
    foreach($b in $list){ [void]$BranchCombo.Items.Add($b) }
    if($cur){ $BranchCombo.SelectedItem = $cur }
  }
}

function Refresh-Remotes{
  $RemoteList.Items.Clear()
  if(In-Repo $script:CurrentRepoDir){
    $r = Get-RemoteBranches
    foreach($x in $r){ [void]$RemoteList.Items.Add($x) }
  }
}

function Refresh-Files{
  $gridStaged.Items.Clear(); $gridUntracked.Items.Clear()
  if(-not (In-Repo $script:CurrentRepoDir)){ return }
  $staged = (git -C $script:CurrentRepoDir diff --name-only --cached) 2>$null
  foreach($f in $staged){ if($f){ $item = New-Object System.Windows.Forms.ListViewItem($f); [void]$gridStaged.Items.Add($item) } }
  $untracked = (git -C $script:CurrentRepoDir ls-files --others --exclude-standard) 2>$null
  foreach($f in $untracked){ if($f){ $item = New-Object System.Windows.Forms.ListViewItem($f); [void]$gridUntracked.Items.Add($item) } }
}

# ------------ Events ------------
$btnFolder.Add_Click({ $dlg = New-Object System.Windows.Forms.FolderBrowserDialog; $dlg.Description = 'Select a Git repository folder (must contain .git)'; $dlg.SelectedPath = $script:CurrentRepoDir; if($dlg.ShowDialog() -eq 'OK'){ Update-RepoContext $dlg.SelectedPath } })
$btnCheckout.Add_Click({ if(-not (In-Repo $script:CurrentRepoDir)){ Log-Err 'Not a git repo'; return }; $sel = $BranchCombo.SelectedItem; if([string]::IsNullOrWhiteSpace($sel)){ Log-Warn 'No branch selected'; return }; if(Run-Git "checkout `"$sel`"") { } else { Refresh-Status; Refresh-Files } })
$btnRefRem.Add_Click({ Refresh-Remotes })
$btnCreateBranch.Add_Click({ if(-not (In-Repo $script:CurrentRepoDir)){ Log-Err 'Not a git repo'; return }; $name = $txtNewBranch.Text; $remoteSel = $RemoteList.SelectedItem; if([string]::IsNullOrWhiteSpace($name) -and [string]::IsNullOrWhiteSpace($remoteSel)){ Log-Warn 'Provide a branch name or select a remote branch'; return }; if([string]::IsNullOrWhiteSpace($name) -and $remoteSel){ $parts = $remoteSel.Split('/'); if($parts.Length -gt 1){ $name = [string]::Join('/', $parts[1..($parts.Length-1)]) } else { $name = $remoteSel } }; if($remoteSel){ Run-Git "checkout -b `"$name`" --track `"$remoteSel`"" } else { Run-Git "checkout -b `"$name`"" }; Refresh-Status; Refresh-Remotes; Refresh-Files })

$chkAutoPull.Add_CheckedChanged({ if($chkAutoPull.Checked){ if(-not $script:AutoPullTimer){ $script:AutoPullTimer = New-Object System.Windows.Forms.Timer }; $intervalMs = [int]$nudInterval.Value * 60000; if($intervalMs -lt 60000){ $intervalMs = 60000 }; if($script:AutoPullHandler){ $script:AutoPullTimer.remove_Tick($script:AutoPullHandler) }; $script:AutoPullHandler = [System.EventHandler]{ if(In-Repo $script:CurrentRepoDir){ Log-Info '=== AUTO-PULL ==='; Run-Git 'pull' } }; $script:AutoPullTimer.add_Tick($script:AutoPullHandler); $script:AutoPullTimer.Interval = $intervalMs; $script:AutoPullTimer.Start(); Log-Info ("Auto-pull enabled (every " + $nudInterval.Value + " min)") } else { if($script:AutoPullTimer){ if($script:AutoPullHandler){ $script:AutoPullTimer.remove_Tick($script:AutoPullHandler) }; $script:AutoPullTimer.Stop() }; Log-Info 'Auto-pull disabled' } })

$nudInterval.Add_ValueChanged({ if($chkAutoPull.Checked -and $script:AutoPullTimer){ $script:AutoPullTimer.Stop(); $script:AutoPullTimer.Interval = [int]$nudInterval.Value * 60000; $script:AutoPullTimer.Start(); Log-Info ("Auto-pull interval set to " + $nudInterval.Value + " min") } })

$btnFetch.Add_Click({ if(In-Repo $script:CurrentRepoDir){ Log-Info '=== FETCH ==='; Run-Git 'fetch --all --prune'; Refresh-Remotes } })
$btnPull.Add_Click({ if(In-Repo $script:CurrentRepoDir){ Log-Info '=== PULL ==='; Run-Git 'pull' } })
$btnStageAll.Add_Click({ if(In-Repo $script:CurrentRepoDir){ Log-Info '=== STAGE ALL ==='; Run-Git 'add .'; Refresh-Files } })
$btnCommit.Add_Click({ if(-not (In-Repo $script:CurrentRepoDir)){ Log-Err 'Not a git repo'; return }; $msg = $MsgBox.Text; if([string]::IsNullOrWhiteSpace($msg)){ $msg = 'Update: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); Log-Warn ('No commit message, using: ' + $msg) }; Log-Info '=== COMMIT ==='; $code = Run-Git "commit -m `"$msg`""; if($code -ne 0){ Log-Warn 'Nothing to commit or commit error' } else { Log-Info 'Committed'; Refresh-Files } })
$btnPush.Add_Click({ if(-not (In-Repo $script:CurrentRepoDir)){ Log-Err 'Not a git repo'; return }; $cur = Get-CurrentBranch; if([string]::IsNullOrWhiteSpace($cur)){ $cur = 'main' }; Log-Info '=== PUSH ==='; $code = Run-Git "push -u origin `"$cur`""; if($code -eq 0){ Log-Info 'Done' } else { Log-Err 'Push failed (check auth/URL/branch)' } })

# ------------ Timers ------------
$script:StatusTimer = New-Object System.Windows.Forms.Timer
$script:StatusTimer.Interval = 5000
$script:StatusTimer.Add_Tick({ Refresh-Status })
$script:StatusTimer.Start()

# Init
Ensure-LogContext
Refresh-Status
Refresh-Remotes
Refresh-Files

[void]$form.ShowDialog()
