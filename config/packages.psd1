@{
    SchemaVersion = 1
    NodeMajors = @(22, 24)
    Packages = @(
        @{ Id='Git.Git'; Name='Git'; Group='Core'; Exe='git.exe'; Args=@('--version'); Paths=@('%ProgramFiles%\Git\cmd\git.exe','%LOCALAPPDATA%\Programs\Git\cmd\git.exe'); Names=@('Git','Git version*'); MinVersion='2.40.0' },
        @{ Id='GitHub.GitHubDesktop'; Name='GitHub Desktop'; Group='Core'; Probe='File'; Paths=@('%LOCALAPPDATA%\GitHubDesktop\GitHubDesktop.exe'); Names=@('GitHub Desktop'); MinVersion='3.0.0' },
        @{ Id='GitHub.cli'; Name='GitHub CLI'; Group='Core'; Exe='gh.exe'; Args=@('--version'); Paths=@('%ProgramFiles%\GitHub CLI\gh.exe'); Names=@('GitHub CLI'); MinVersion='2.0.0' },
        @{ Id='Microsoft.VisualStudioCode'; Name='VS Code'; Group='Core'; Exe='code.cmd'; Args=@('--version'); Scope='user'; Paths=@('%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd','%ProgramFiles%\Microsoft VS Code\bin\code.cmd'); Names=@('Microsoft Visual Studio Code','Microsoft Visual Studio Code (User)'); MinVersion='1.98.0' },
        @{ Id='OpenJS.NodeJS.LTS'; Name='Node.js LTS'; Group='Core'; Exe='node.exe'; Args=@('--version'); Paths=@('%ProgramFiles%\nodejs\node.exe'); Names=@('Node.js'); MinVersion='22.16.0'; AllowedMajors=@(22,24); PinnedVersion='24.19.0'; InstallerType='wix'; Scope='machine'; Companions=@('npm.cmd','npx.cmd') },
        @{ Id='Microsoft.PowerShell'; Name='PowerShell 7'; Group='Core'; Exe='pwsh.exe'; Args=@('--version'); Paths=@('%ProgramFiles%\PowerShell\7\pwsh.exe'); Names=@('PowerShell 7*'); MinVersion='7.4.0'; AllowedMajors=@(7) },
        @{ Id='Microsoft.WindowsTerminal'; Name='Windows Terminal'; Group='Core'; Probe='Appx'; AppxName='Microsoft.WindowsTerminal'; Paths=@(); Names=@(); MinVersion='1.20.0' },
        @{ Id='7zip.7zip'; Name='7-Zip'; Group='Core'; Probe='File'; Paths=@('%ProgramFiles%\7-Zip\7z.exe','%ProgramFiles(x86)%\7-Zip\7z.exe'); Names=@('7-Zip*'); MinVersion='24.0' },
        @{ Id='Python.Python.3.13'; Name='Python'; Group='Python'; Exe='python.exe'; Args=@('--version'); Paths=@('%LOCALAPPDATA%\Programs\Python\Python313\python.exe','%ProgramFiles%\Python313\python.exe'); Names=@('Python 3.13.*'); MinVersion='3.13.0'; AllowedMajors=@(3) },
        @{ Id='EclipseAdoptium.Temurin.21.JDK'; Name='JDK'; Group='JDK'; Exe='javac.exe'; Args=@('-version'); Paths=@(); Names=@('Eclipse Temurin JDK with Hotspot 21*'); MinVersion='21.0.0'; AllowedMajors=@(21) },
        @{ Id='Docker.DockerDesktop'; Name='Docker Desktop'; Group='Docker'; Probe='File'; Paths=@('%ProgramFiles%\Docker\Docker\Docker Desktop.exe'); Names=@('Docker Desktop'); MinVersion='4.0.0'; RequiresVirtualization=$true },
        @{ Id='DBeaver.DBeaver.Community'; Name='DBeaver'; Group='DBeaver'; Probe='File'; Paths=@('%ProgramFiles%\DBeaver\dbeaver.exe','%LOCALAPPDATA%\DBeaver\dbeaver.exe'); Names=@('DBeaver*'); MinVersion='24.0.0' }
    )
    Extensions = @{ Codex='openai.chatgpt'; Claude='anthropic.claude-code' }
}
