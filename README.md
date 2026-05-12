# Seat Setup Scripts

공용/공유 컴퓨터에서 **자리를 옮길 때마다** 반복되는 셋업/정리 작업을 자동화하는 PowerShell 스크립트 모음.
새 자리에서 이 저장소를 클론한 뒤 `setup.ps1` → `login.ps1` → `setup_claude.ps1` 순서로 실행하면 작업 환경이 복원되고, 자리를 비울 때는 `logout.ps1`, 자리를 옮길 때는 `remove.ps1`을 실행해서 흔적을 지운다.

---

## 사용 시나리오

| 상황                           | 실행할 스크립트                                |
| ------------------------------ | ---------------------------------------------- |
| 새 자리로 옮긴 직후            | `setup.ps1` → `login.ps1` → `setup_claude.ps1` |
| 평소 자리를 잠깐 비울 때       | (아무것도 안 해도 됨)                          |
| 자리를 길게 비울 때 (로그아웃) | `logout.ps1`                                   |
| 다른 자리로 옮기기 전 (정리)   | `remove.ps1`                                   |

---

## 첫 사용 준비

1. 이 저장소를 적당한 위치에 클론한다. (스크립트는 어느 폴더에서 실행해도 동작한다)
2. Personal Access Token을 발급한다.
   - **GitHub**: Settings → Developer Settings → Personal Access Tokens. scope: `repo`, `read:org`, `gist`, `workflow`
   - **GitLab** (lab.ssafy.com 등): User Settings → Access Tokens. scope: `read_repository`, `write_repository`
3. `tokens.example.txt`를 복사해서 `tokens.txt`로 이름을 바꾸고 토큰을 채워 넣는다.
   - 형식: 한 줄에 `<host> <token>` (예: `github.com ghp_xxx`, `lab.ssafy.com glpat_xxx`)
   - host 생략 시 github.com으로 간주됨
   - `tokens.txt`는 `.gitignore`에 등록되어 있어 깃에 올라가지 않는다.

---

## 스크립트 설명

### `setup.ps1` — 새 자리 셋업

winget으로 필수 앱을 설치하고 PowerShell 프로필에 유틸리티 함수를 등록한다.

설치 항목:

- Claude Desktop, Claude Code CLI
- Obsidian
- GitHub CLI

프로필 등록:

- `git-push-all` 함수 — 현재 폴더의 모든 하위 폴더를 돌면서 변경사항이 있으면 `"실습"` 메시지로 commit·push한다. (실습 과제 일괄 푸시용)

### `login.ps1` — git 호스트 자동 로그인

`tokens.txt`의 각 줄을 읽어 host에 따라 분기한다:

- **github.com** → `gh auth login --with-token`으로 로그인, `gh auth setup-git`으로 git credential helper 연결
- **그 외 (GitLab 등)** → `git credential approve`로 Windows 자격 증명 관리자에 저장 (이후 git push/pull 시 자동 사용)

여러 호스트/계정을 한 파일에 같이 적어도 한 번에 처리된다.

### `setup_claude.ps1` — Claude 스킬/에이전트 적용

이 저장소의 `claude_home/skills`와 `claude_home/agents`를 `~/.claude/skills`, `~/.claude/agents`로 복사한다.

옵션:

- `-Merge` 플래그를 주면 같은 이름의 폴더는 건너뛴다. (기본 동작은 덮어쓰기)

### `logout.ps1` — 자리를 길게 비울 때

각 단계마다 진행 여부를 물어보고 `y` 입력 시에만 실행한다. 총 8단계:

1. Obsidian vault commit/push 후 폴더 삭제
2. Obsidian 앱 캐시 삭제 (`%APPDATA%\obsidian`) — vault 자동 연결 방지
3. gh CLI 로그아웃 (모든 계정)
4. Windows 자격 증명 관리자에서 git/gh 항목 제거
5. Claude Code 로그아웃 (수동)
6. Claude Desktop 로그아웃 (수동)
7. Chrome 프로필 전체 삭제
8. `~/Pictures/Screenshots` 폴더 비우기

### `remove.ps1` — 자리를 옮기기 전 정리

설치된 앱을 모두 제거하고 PowerShell 프로필에서 `git-push-all`도 제거한다. `setup.ps1`의 정확한 반대 동작.

---

## `claude_home/` — Claude 설정 백업

`~/.claude` 폴더의 일부를 git으로 버전 관리하기 위한 디렉토리.

```
claude_home/
├── skills/           # ~/.claude/skills 에 복사됨
│   └── image-to-md/  # 이미지 폴더를 마크다운으로 변환하는 스킬
└── agents/           # ~/.claude/agents 에 복사됨
    └── lecture-images-to-md.md  # 부모 폴더 아래 하위 폴더들을
                                  # 병렬로 image-to-md 변환하는 Haiku 에이전트
```

새로운 스킬이나 에이전트를 추가하려면 해당 디렉토리에 파일을 넣고 commit하면 된다. 다음 자리에서 클론 후 `setup_claude.ps1`을 돌리면 자동 적용된다.

`settings.json`이나 `.credentials.json`은 환경 의존적이고 민감 정보가 있어서 일부러 백업 대상에서 제외했다.

---

## 파일 구조

```
.
├── README.md
├── .gitignore               # tokens.txt, .claude 제외
├── setup.ps1                # 1) 새 자리 앱 설치
├── login.ps1                # 2) gh 자동 로그인
├── setup_claude.ps1         # 3) Claude 스킬/에이전트 적용
├── logout.ps1               # 자리를 길게 비울 때 정리
├── remove.ps1               # 자리를 옮기기 전 앱 제거
├── tokens.example.txt       # tokens.txt 작성 양식
├── tokens.txt               # (사용자가 직접 작성, git 제외)
└── claude_home/
    ├── skills/
    └── agents/
```

---

## 주의사항

- 스크립트들은 winget이 PATH에 있어야 동작한다. (Windows 10/11 기본 설치됨)
- `logout.ps1`의 Claude Code / Claude Desktop 로그아웃 단계는 수동 조작이 필요하다. 안내 메시지를 따라 직접 로그아웃한 뒤 Enter를 누르면 된다.
- `tokens.txt`는 절대 깃에 올리지 않는다. `.gitignore`로 막혀 있지만 혹시 모르니 확인 후 커밋한다.
