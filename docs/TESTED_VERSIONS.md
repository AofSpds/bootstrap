# 검증 환경과 버전

기준일: 2026-09-15. 목표 환경은 Windows 11 x64 / Windows PowerShell 5.1입니다.

## Node 설치판과 테스트판의 구분

공식 Node 사이트의 최신 LTS는 24.21.0이지만, 직접 조회한 WinGet LTS 카탈로그의 최상위 제공판은 24.19.0이었습니다. 24.21.0 manifest는 조회되지 않았습니다. 따라서 이 후보의 신규 설치는 **실제로 존재하는 24.19.0 x64 MSI**를 명시적으로 선택합니다. 공급판과 최신 보안 패치가 동일하다고 주장하지 않습니다. 정식 배포 전 카탈로그·보안 패치 현행성을 다시 확인해야 합니다.

Manifest: microsoft/winget-pkgs / manifests/o/OpenJS/NodeJS/LTS/24.19.0/OpenJS.NodeJS.LTS.installer.yaml
Blob: 2a487a4d2f0824bd53bc4728670a0d15b30afeb8
x64 installer SHA256: F0F66C2A80C08A30A5AB5179EE9EA9E45F9B46289436A8CC87FF833B852DB351
Source URL: https://nodejs.org/dist/v24.19.0/node-v24.19.0-x64.msi

WinGet가 다운로드와 hash 검사를 담당합니다. 이 파일에 적은 hash로 별도 다운로드 우회 경로를 만들지 않습니다. 기존 Node 22.16+ 또는 24는 유지합니다. Web Starter의 CI는 Node 24.21.0과 22.23.2를 별도로 사용합니다.

VS Code 최소 기능 호환 버전은 Claude 공식 확장 요구사항에 맞춰 1.98.0으로 수정했습니다. 최소 버전은 보안 최신성 보증이 아닙니다.

CI는 파서/설치기 mock/재실행/실패/로그마스킹을 실행합니다. Windows runner는 개발도구가 사전 설치된 Windows Server 이미지이며 깨끗한 Windows 11 PC가 아닙니다.

아직 별도 증거가 필요한 항목: 깨끗한 Windows 11 설치, 기존 설치 PC의 UAC/WinGet 실제 실행, 사용자 로그인, ARM64/관리 PC, IVA 독립검증. 문서나 CI 성공으로 이 항목을 PASS로 올리지 않습니다.
