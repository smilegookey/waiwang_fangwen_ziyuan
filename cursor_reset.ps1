# �����������Ϊ UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ��ɫ����
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# �����ļ�·��
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"

# ������ԱȨ��
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "$RED[����]$NC ���Թ���Ա������д˽ű�"
    Write-Host "���Ҽ�����ű���ѡ��'�Թ���Ա�������'"
    Read-Host "���س����˳�"
    exit 1
}

# ��ʾ Logo
Clear-Host
Write-Host @"

    �������������[�����[   �����[�������������[ ���������������[ �������������[ �������������[ 
   �����X�T�T�T�T�a�����U   �����U�����X�T�T�����[�����X�T�T�T�T�a�����X�T�T�T�����[�����X�T�T�����[
   �����U     �����U   �����U�������������X�a���������������[�����U   �����U�������������X�a
   �����U     �����U   �����U�����X�T�T�����[�^�T�T�T�T�����U�����U   �����U�����X�T�T�����[
   �^�������������[�^�������������X�a�����U  �����U���������������U�^�������������X�a�����U  �����U
    �^�T�T�T�T�T�a �^�T�T�T�T�T�a �^�T�a  �^�T�a�^�T�T�T�T�T�T�a �^�T�T�T�T�T�a �^�T�a  �^�T�a

"@
Write-Host "$BLUE================================$NC"
Write-Host "$GREEN   Cursor �豸ID �޸Ĺ���          $NC"
Write-Host "$YELLOW  ��עƴ���:����ľ���� $NC"
Write-Host "$BLUE================================$NC"
Write-Host ""

# ��ȡ����ʾ Cursor �汾
function Get-CursorVersion {
    try {
        # ��Ҫ���·��
        $packagePath = "$env:LOCALAPPDATA\Programs\cursor\resources\app\package.json"
        
        if (Test-Path $packagePath) {
            $packageJson = Get-Content $packagePath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[��Ϣ]$NC ��ǰ��װ�� Cursor �汾: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        # ����·�����
        $altPath = "$env:LOCALAPPDATA\cursor\resources\app\package.json"
        if (Test-Path $altPath) {
            $packageJson = Get-Content $altPath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[��Ϣ]$NC ��ǰ��װ�� Cursor �汾: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        Write-Host "$YELLOW[����]$NC �޷���⵽ Cursor �汾"
        Write-Host "$YELLOW[��ʾ]$NC ��ȷ�� Cursor ����ȷ��װ"
        return $null
    }
    catch {
        Write-Host "$RED[����]$NC ��ȡ Cursor �汾ʧ��: $_"
        return $null
    }
}

# ��ȡ����ʾ�汾��Ϣ
$cursorVersion = Get-CursorVersion
Write-Host ""

Write-Host "$YELLOW[��Ҫ��ʾ]$NC ���µ� 0.47.x (��֧��)"
Write-Host ""

# ��鲢�ر� Cursor ����
Write-Host "$GREEN[��Ϣ]$NC ��� Cursor ����..."

function Get-ProcessDetails {
    param($processName)
    Write-Host "$BLUE[����]$NC ���ڻ�ȡ $processName ������ϸ��Ϣ��"
    Get-WmiObject Win32_Process -Filter "name='$processName'" | 
        Select-Object ProcessId, ExecutablePath, CommandLine | 
        Format-List
}

# ����������Դ����͵ȴ�ʱ��
$MAX_RETRIES = 5
$WAIT_TIME = 1

# ������̹ر�
function Close-CursorProcess {
    param($processName)
    
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "$YELLOW[����]$NC ���� $processName ��������"
        Get-ProcessDetails $processName
        
        Write-Host "$YELLOW[����]$NC ���Թر� $processName..."
        Stop-Process -Name $processName -Force
        
        $retryCount = 0
        while ($retryCount -lt $MAX_RETRIES) {
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (-not $process) { break }
            
            $retryCount++
            if ($retryCount -ge $MAX_RETRIES) {
                Write-Host "$RED[����]$NC �� $MAX_RETRIES �γ��Ժ����޷��ر� $processName"
                Get-ProcessDetails $processName
                Write-Host "$RED[����]$NC ���ֶ��رս��̺�����"
                Read-Host "���س����˳�"
                exit 1
            }
            Write-Host "$YELLOW[����]$NC �ȴ����̹رգ����� $retryCount/$MAX_RETRIES..."
            Start-Sleep -Seconds $WAIT_TIME
        }
        Write-Host "$GREEN[��Ϣ]$NC $processName �ѳɹ��ر�"
    }
}

# �ر����� Cursor ����
Close-CursorProcess "Cursor"
Close-CursorProcess "cursor"

# ��������Ŀ¼
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

# ������������
if (Test-Path $STORAGE_FILE) {
    Write-Host "$GREEN[��Ϣ]$NC ���ڱ��������ļ�..."
    $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $STORAGE_FILE "$BACKUP_DIR\$backupName"
}

# �����µ� ID
Write-Host "$GREEN[��Ϣ]$NC ���������µ� ID..."

# ����ɫ�������Ӵ˺���
function Get-RandomHex {
    param (
        [int]$length
    )
    
    $bytes = New-Object byte[] ($length)
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($bytes)
    $hexString = [System.BitConverter]::ToString($bytes) -replace '-',''
    $rng.Dispose()
    return $hexString
}

# �Ľ� ID ���ɺ���
function New-StandardMachineId {
    $template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    $result = $template -replace '[xy]', {
        param($match)
        $r = [Random]::new().Next(16)
        $v = if ($match.Value -eq "x") { $r } else { ($r -band 0x3) -bor 0x8 }
        return $v.ToString("x")
    }
    return $result
}

# ������ ID ʱʹ���º���
$MAC_MACHINE_ID = New-StandardMachineId
$UUID = [System.Guid]::NewGuid().ToString()
# �� auth0|user_ ת��Ϊ�ֽ������ʮ������
$prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
$prefixHex = -join ($prefixBytes | ForEach-Object { '{0:x2}' -f $_ })
# ����32�ֽ�(64��ʮ�������ַ�)���������Ϊ machineId ���������
$randomPart = Get-RandomHex -length 32
$MACHINE_ID = "$prefixHex$randomPart"
$SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

# ��Update-MachineGuid����ǰ���Ȩ�޼��
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "$RED[����]$NC ��ʹ�ù���ԱȨ�����д˽ű�"
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Update-MachineGuid {
    try {
        # ���ע���·���Ƿ���ڣ��������򴴽�
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        if (-not (Test-Path $registryPath)) {
            Write-Host "$YELLOW[����]$NC ע���·��������: $registryPath�����ڴ���..."
            New-Item -Path $registryPath -Force | Out-Null
            Write-Host "$GREEN[��Ϣ]$NC ע���·�������ɹ�"
        }

        # ��ȡ��ǰ�� MachineGuid�������������ʹ�ÿ��ַ�����ΪĬ��ֵ
        $originalGuid = ""
        try {
            $currentGuid = Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction SilentlyContinue
            if ($currentGuid) {
                $originalGuid = $currentGuid.MachineGuid
                Write-Host "$GREEN[��Ϣ]$NC ��ǰע���ֵ��"
                Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography" 
                Write-Host "    MachineGuid    REG_SZ    $originalGuid"
            } else {
                Write-Host "$YELLOW[����]$NC MachineGuid ֵ�����ڣ���������ֵ"
            }
        } catch {
            Write-Host "$YELLOW[����]$NC ��ȡ MachineGuid ʧ��: $($_.Exception.Message)"
        }

        # ��������Ŀ¼����������ڣ�
        if (-not (Test-Path $BACKUP_DIR)) {
            New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
        }

        # ���������ļ�������ԭʼֵ����ʱ��
        if ($originalGuid) {
            $backupFile = "$BACKUP_DIR\MachineGuid_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
            $backupResult = Start-Process "reg.exe" -ArgumentList "export", "`"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`"", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($backupResult.ExitCode -eq 0) {
                Write-Host "$GREEN[��Ϣ]$NC ע������ѱ��ݵ���$backupFile"
            } else {
                Write-Host "$YELLOW[����]$NC ���ݴ���ʧ�ܣ�����ִ��..."
            }
        }

        # ������GUID
        $newGuid = [System.Guid]::NewGuid().ToString()

        # ���»򴴽�ע���ֵ
        Set-ItemProperty -Path $registryPath -Name MachineGuid -Value $newGuid -Force -ErrorAction Stop
        
        # ��֤����
        $verifyGuid = (Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop).MachineGuid
        if ($verifyGuid -ne $newGuid) {
            throw "ע�����֤ʧ�ܣ����º��ֵ ($verifyGuid) ��Ԥ��ֵ ($newGuid) ��ƥ��"
        }

        Write-Host "$GREEN[��Ϣ]$NC ע�����³ɹ���"
        Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
        Write-Host "    MachineGuid    REG_SZ    $newGuid"
        return $true
    }
    catch {
        Write-Host "$RED[����]$NC ע������ʧ�ܣ�$($_.Exception.Message)"
        
        # ���Իָ����ݣ�������ڣ�
        if (($backupFile -ne $null) -and (Test-Path $backupFile)) {
            Write-Host "$YELLOW[�ָ�]$NC ���ڴӱ��ݻָ�..."
            $restoreResult = Start-Process "reg.exe" -ArgumentList "import", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($restoreResult.ExitCode -eq 0) {
                Write-Host "$GREEN[�ָ��ɹ�]$NC �ѻ�ԭԭʼע���ֵ"
            } else {
                Write-Host "$RED[����]$NC �ָ�ʧ�ܣ����ֶ����뱸���ļ���$backupFile"
            }
        } else {
            Write-Host "$YELLOW[����]$NC δ�ҵ������ļ��򱸷ݴ���ʧ�ܣ��޷��Զ��ָ�"
        }
        return $false
    }
}

# ��������������ļ�
Write-Host "$GREEN[��Ϣ]$NC ���ڸ�������..."

try {
    # ��������ļ��Ƿ����
    if (-not (Test-Path $STORAGE_FILE)) {
        Write-Host "$RED[����]$NC δ�ҵ������ļ�: $STORAGE_FILE"
        Write-Host "$YELLOW[��ʾ]$NC ���Ȱ�װ������һ�� Cursor ����ʹ�ô˽ű�"
        Read-Host "���س����˳�"
        exit 1
    }

    # ��ȡ���������ļ�
    try {
        $originalContent = Get-Content $STORAGE_FILE -Raw -Encoding UTF8
        
        # �� JSON �ַ���ת��Ϊ PowerShell ����
        $config = $originalContent | ConvertFrom-Json 

        # ���ݵ�ǰֵ
        $oldValues = @{
            'machineId' = $config.'telemetry.machineId'
            'macMachineId' = $config.'telemetry.macMachineId'
            'devDeviceId' = $config.'telemetry.devDeviceId'
            'sqmId' = $config.'telemetry.sqmId'
        }

        # �����ض���ֵ
        $config.'telemetry.machineId' = $MACHINE_ID
        $config.'telemetry.macMachineId' = $MAC_MACHINE_ID
        $config.'telemetry.devDeviceId' = $UUID
        $config.'telemetry.sqmId' = $SQM_ID

        # �����º�Ķ���ת���� JSON ������
        $updatedJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($STORAGE_FILE), 
            $updatedJson, 
            [System.Text.Encoding]::UTF8
        )
        Write-Host "$GREEN[��Ϣ]$NC �ɹ����������ļ�"
    } catch {
        # ����������Իָ�ԭʼ����
        if ($originalContent) {
            [System.IO.File]::WriteAllText(
                [System.IO.Path]::GetFullPath($STORAGE_FILE), 
                $originalContent, 
                [System.Text.Encoding]::UTF8
            )
        }
        throw "���� JSON ʧ��: $_"
    }
    # ֱ��ִ�и��� MachineGuid������ѯ��
    Update-MachineGuid
    # ��ʾ���
    Write-Host ""
    Write-Host "$GREEN[��Ϣ]$NC �Ѹ�������:"
    Write-Host "$BLUE[����]$NC machineId: $MACHINE_ID"
    Write-Host "$BLUE[����]$NC macMachineId: $MAC_MACHINE_ID"
    Write-Host "$BLUE[����]$NC devDeviceId: $UUID"
    Write-Host "$BLUE[����]$NC sqmId: $SQM_ID"

    # ��ʾ�ļ����ṹ
    Write-Host ""
    Write-Host "$GREEN[��Ϣ]$NC �ļ��ṹ:"
    Write-Host "$BLUE$env:APPDATA\Cursor\User$NC"
    Write-Host "������ globalStorage"
    Write-Host "��   ������ storage.json (���޸�)"
    Write-Host "��   ������ backups"

    # �г������ļ�
    $backupFiles = Get-ChildItem "$BACKUP_DIR\*" -ErrorAction SilentlyContinue
    if ($backupFiles) {
        foreach ($file in $backupFiles) {
            Write-Host "��       ������ $($file.Name)"
        }
    } else {
        Write-Host "��       ������ (��)"
    }

    # ��ʾ���ں���Ϣ
    Write-Host ""
    Write-Host "$GREEN================================$NC"
    Write-Host "$YELLOW ��ӭ��עpdd����:����ľ����  $NC"
    Write-Host "$GREEN================================$NC"
    Write-Host ""
    Write-Host "$GREEN[��Ϣ]$NC ������ Cursor ��Ӧ���µ�����"
    Write-Host ""

    # ѯ���Ƿ�Ҫ�����Զ�����
    Write-Host ""
    Write-Host "$YELLOW[ѯ��]$NC �Ƿ�Ҫ���� Cursor �Զ����¹��ܣ�"
    Write-Host "0) �� - ����Ĭ������ (���س���)"
    Write-Host "1) �� - �����Զ�����"
   # $choice = Read-Host "������ѡ�� (0)"
    $choice = 1 
    if ($choice -eq "1") {
        Write-Host ""
        Write-Host "$GREEN[��Ϣ]$NC ���ڴ����Զ�����..."
        $updaterPath = "$env:LOCALAPPDATA\cursor-updater"

        # �����ֶ����ý̳�
        function Show-ManualGuide {
            Write-Host ""
            Write-Host "$YELLOW[����]$NC �Զ�����ʧ��,�볢���ֶ�������"
            Write-Host "$YELLOW�ֶ����ø��²��裺$NC"
            Write-Host "1. �Թ���Ա��ݴ� PowerShell"
            Write-Host "2. ����ճ���������"
            Write-Host "$BLUE����1 - ɾ������Ŀ¼��������ڣ���$NC"
            Write-Host "Remove-Item -Path `"$updaterPath`" -Force -Recurse -ErrorAction SilentlyContinue"
            Write-Host ""
            Write-Host "$BLUE����2 - ������ֹ�ļ���$NC"
            Write-Host "New-Item -Path `"$updaterPath`" -ItemType File -Force | Out-Null"
            Write-Host ""
            Write-Host "$BLUE����3 - ����ֻ�����ԣ�$NC"
            Write-Host "Set-ItemProperty -Path `"$updaterPath`" -Name IsReadOnly -Value `$true"
            Write-Host ""
            Write-Host "$BLUE����4 - ����Ȩ�ޣ���ѡ����$NC"
            Write-Host "icacls `"$updaterPath`" /inheritance:r /grant:r `"`$($env:USERNAME):(R)`""
            Write-Host ""
            Write-Host "$YELLOW��֤������$NC"
            Write-Host "1. �������Get-ItemProperty `"$updaterPath`""
            Write-Host "2. ȷ�� IsReadOnly ����Ϊ True"
            Write-Host "3. �������icacls `"$updaterPath`""
            Write-Host "4. ȷ��ֻ�ж�ȡȨ��"
            Write-Host ""
            Write-Host "$YELLOW[��ʾ]$NC ��ɺ������� Cursor"
        }

        try {
            # ���cursor-updater�Ƿ����
            if (Test-Path $updaterPath) {
                # ������ļ�,˵���Ѿ���������ֹ����
                if ((Get-Item $updaterPath) -is [System.IO.FileInfo]) {
                    Write-Host "$GREEN[��Ϣ]$NC �Ѵ�����ֹ�����ļ�,�����ٴ���ֹ"
                    return
                }
                # �����Ŀ¼,����ɾ��
                else {
                    try {
                        Remove-Item -Path $updaterPath -Force -Recurse -ErrorAction Stop
                        Write-Host "$GREEN[��Ϣ]$NC �ɹ�ɾ�� cursor-updater Ŀ¼"
                    }
                    catch {
                        Write-Host "$RED[����]$NC ɾ�� cursor-updater Ŀ¼ʧ��"
                        Show-ManualGuide
                        return
                    }
                }
            }

            # ������ֹ�ļ�
            try {
                New-Item -Path $updaterPath -ItemType File -Force -ErrorAction Stop | Out-Null
                Write-Host "$GREEN[��Ϣ]$NC �ɹ�������ֹ�ļ�"
            }
            catch {
                Write-Host "$RED[����]$NC ������ֹ�ļ�ʧ��"
                Show-ManualGuide
                return
            }

            # �����ļ�Ȩ��
            try {
                # ����ֻ������
                Set-ItemProperty -Path $updaterPath -Name IsReadOnly -Value $true -ErrorAction Stop
                
                # ʹ�� icacls ����Ȩ��
                $result = Start-Process "icacls.exe" -ArgumentList "`"$updaterPath`" /inheritance:r /grant:r `"$($env:USERNAME):(R)`"" -Wait -NoNewWindow -PassThru
                if ($result.ExitCode -ne 0) {
                    throw "icacls ����ʧ��"
                }
                
                Write-Host "$GREEN[��Ϣ]$NC �ɹ������ļ�Ȩ��"
            }
            catch {
                Write-Host "$RED[����]$NC �����ļ�Ȩ��ʧ��"
                Show-ManualGuide
                return
            }

            # ��֤����
            try {
                $fileInfo = Get-ItemProperty $updaterPath
                if (-not $fileInfo.IsReadOnly) {
                    Write-Host "$RED[����]$NC ��֤ʧ�ܣ��ļ�Ȩ�����ÿ���δ��Ч"
                    Show-ManualGuide
                    return
                }
            }
            catch {
                Write-Host "$RED[����]$NC ��֤����ʧ��"
                Show-ManualGuide
                return
            }

            Write-Host "$GREEN[��Ϣ]$NC �ɹ������Զ�����"
        }
        catch {
            Write-Host "$RED[����]$NC ����δ֪����: $_"
            Show-ManualGuide
        }
    }
    else {
        Write-Host "$GREEN[��Ϣ]$NC ����Ĭ�����ã������и���"
    }

    # ������Ч��ע������
    Update-MachineGuid

} catch {
    Write-Host "$RED[����]$NC ��Ҫ����ʧ��: $_"
    Write-Host "$YELLOW[����]$NC ʹ�ñ�ѡ����..."
    
    try {
        # ��ѡ������ʹ�� Add-Content
        $tempFile = [System.IO.Path]::GetTempFileName()
        $config | ConvertTo-Json | Set-Content -Path $tempFile -Encoding UTF8
        Copy-Item -Path $tempFile -Destination $STORAGE_FILE -Force
        Remove-Item -Path $tempFile
        Write-Host "$GREEN[��Ϣ]$NC ʹ�ñ�ѡ�����ɹ�д������"
    } catch {
        Write-Host "$RED[����]$NC ���г��Զ�ʧ����"
        Write-Host "��������: $_"
        Write-Host "Ŀ���ļ�: $STORAGE_FILE"
        Write-Host "��ȷ�������㹻��Ȩ�޷��ʸ��ļ�"
        Read-Host "���س����˳�"
        exit 1
    }
}

Write-Host ""
Read-Host "���س����˳�"
exit 0

# ���ļ�д�벿���޸�
function Write-ConfigFile {
    param($config, $filePath)
    
    try {
        # ʹ�� UTF8 �� BOM ����
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $jsonContent = $config | ConvertTo-Json -Depth 10
        
        # ͳһʹ�� LF ���з�
        $jsonContent = $jsonContent.Replace("`r`n", "`n")
        
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($filePath),
            $jsonContent,
            $utf8NoBom
        )
        
        Write-Host "$GREEN[��Ϣ]$NC �ɹ�д�������ļ�(UTF8 �� BOM)"
    }
    catch {
        throw "д�������ļ�ʧ��: $_"
    }
}

# ��ȡ����ʾ�汾��Ϣ
$cursorVersion = Get-CursorVersion
Write-Host ""
if ($cursorVersion) {
    Write-Host "$GREEN[��Ϣ]$NC ��⵽ Cursor �汾: $cursorVersion������ִ��..."
} else {
    Write-Host "$YELLOW[����]$NC �޷����汾��������ִ��..."
} 