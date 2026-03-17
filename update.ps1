from datetime import datetime
content = r'''<#
update.ps1 — vienas klikšķa Git atjaunināšanas skripts skolotājam

Ko dara:
 1) Pārbauda, vai instalēts Git
 2) Pārbauda, vai pašreizējā mape ir Git repozitorijs
 3) Nosaka pašreizējo zaru (branch)
 4) Piesaka visus izmaiņotos failus (git add .)
 5) Izveido commit ar Jūsu ziņu (vai automātisku ar datumu/laiku)
 6) Veic push uz attālināto repozitoriju (origin)

Lietošana:
 - Ar dubultklikšķi vai no PowerShell:  ./update.ps1
 - Var padot commit ziņu kā parametru:   ./update.ps1 -Message "Labots README"

Piezīmes:
 - Ja “origin” vai branch nav iestatīti, skripts mēģinās ieteikt risinājumu.
 - Ja tiek prasīta GitHub autentifikācija, ievadiet GitHub personal access token (paroles vietā).
#>

param(
  [string]$Message
)

function Write-Info($text){ Write-Host "[INFO] $text" -ForegroundColor Cyan }
function Write-Warn($text){ Write-Host "[WARN] $text" -ForegroundColor Yellow }
function Write-Err ($text){ Write-Host "[ERRO] $text" -ForegroundColor Red }

# 1) Git pārbaude
$gitVersion = & git --version 2>$null
if (-not $gitVersion) {
  Write-Err "Git nav atrodams. Lūdzu, instalējiet Git for Windows: https://git-scm.com/download/win"
  exit 1
}
Write-Info "Atrasts $gitVersion"

# 2) Vai šī ir Git mape?
$top = & git rev-parse --show-toplevel 2>$null
if (-not $top) {
  Write-Err "Pašreizējā mape nav Git repozitorijs. Atveriet projektu mapē ar .git vai klonējiet no GitHub."
  exit 1
}
Write-Info "Repozitorija sakne: $top"

# 3) Nosakām pašreizējo zaru
$branch = (& git rev-parse --abbrev-ref HEAD).Trim()
if (-not $branch) { $branch = "main" }
Write-Info "Pašreizējais zars: $branch"

# 4) Pārbaudām attālināto (origin)
$origin = (& git remote get-url origin) 2>$null
if (-not $origin) {
  Write-Warn "Nav iestatīts 'origin'. Iestatiet to ar:\n  git remote add origin https://github.com/<lietotajs>/<repo>.git"
  exit 1
}
Write-Info "Origin: $origin"

# 5) Pievienojam failus
Write-Info "Pievienoju izmaiņas (git add .)"
& git add .

# 6) Commit ziņa
if (-not $Message -or $Message.Trim().Length -eq 0) {
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $Message = "Update: $ts"
}
Write-Info "Veidoju commit: '$Message'"

# Ja nav ko commitot, git commit atgriezīs kļūdu – to apstrādājam saudzīgi
& git commit -m "$Message"
if ($LASTEXITCODE -ne 0) {
  Write-Warn "Iespējams, nav izmaiņu ko commitot. Turpinu ar push."
}

# 7) Pārbaudām, vai zars eksistē attālināti; ja lokāli nav nosaukts, normalizējam uz main
if ($branch -eq "HEAD" -or [string]::IsNullOrWhiteSpace($branch)) {
  Write-Warn "Zara nosaukumu nevar noteikt. Iestatu uz 'main'."
  & git branch -M main
  $branch = "main"
}

# 8) Push ar upstream, ja nepieciešams
Write-Info "Nosūtu izmaiņas uz GitHub: origin/$branch"
& git push -u origin $branch
if ($LASTEXITCODE -ne 0) {
  Write-Warn "Push neizdevās. Biežākie iemesli:"
  Write-Host " - Nepareizs origin URL (pārbaudiet: git remote -v)"
  Write-Host " - Nav tiesību uz rakstīšanu (Write) GitHub repozitorijā"
  Write-Host " - Nepareizs zars (piem.: lokāli 'master', attālināti 'main')"
  Write-Host " - Nepieciešama autentifikācija (ievadiet GitHub token paroles vietā)"
  exit 1
}

Write-Host "\n✔ Gatavs! Izmaiņas ir publicētas GitHub zarā '$branch'" -ForegroundColor Green
'''

with open('update.ps1', 'w', encoding='utf-8') as f:
    f.write(content)

'File created: update.ps1'
