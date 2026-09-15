# 검증 환경과 버전

기준일: 2026-09-15. 목표 환경은 Windows 11 x64 / Windows PowerShell 5.1입니다.

Node 신규 설치는 공식 다운로드 페이지에서 확인한 LTS `24.21.0`으로 고정했습니다. 기존 Node 22.16+ 또는 24는 호환 major를 검사합니다. 다른 프로그램은 카탈로그의 최소 기능 호환 버전 이상이면 유지하고, 새 설치는 공식 WinGet source의 제공 버전을 사용합니다. 최소 기능 버전은 보안 최신성 보증이 아닙니다.

CI는 파서/설치기 mock/재실행/실패/로그마스킹을 실행합니다. GitHub Windows runner는 개발도구가 사전 설치된 환경이며 깨끗한 Windows 11 PC가 아닙니다. `TOTAL_PASS`는 이 자체 점검만 의미합니다.

아직 별도 증거가 필요한 항목: 깨끗한 Windows 11 설치, 기존 설치 PC의 UAC/WinGet 실제 실행, 사용자 로그인, ARM64/관리 PC, IVA 독립검증. 문서나 CI 성공으로 이 항목을 PASS로 올리지 않습니다.

정확한 최종 코드 commit/tree와 CI run은 AofSpds/mitchell의 실행 완료보고에서 고정합니다.
