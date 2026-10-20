# MyWorkSkills · 工业软件与工程交付 Agent Skills

面向工业自动化软件、机器视觉、设备控制和工程交付的可复用 Agent Skills 工具箱。

> 状态：v0.1 初始版。所有 Skill 只提供任务流程、审查清单、文档模板与交付规则；不会自动取得项目设备权限、编译环境、HALCON 许可证或视频素材。

## Skills 总览

| Skill | 触发场景 | 主要交付 |
| --- | --- | --- |
| [engineering-constraints](skills/engineering-constraints/SKILL.md) | 工程决策、改动范围、项目隔离 | 约束清单、决策记录 |
| [industrial-cpp-architecture](skills/industrial-cpp-architecture/SKILL.md) | C++20/Qt 架构、模块重构 | 接口设计、依赖图、生命周期分析 |
| [qt-industrial-ui](skills/qt-industrial-ui/SKILL.md) | Qt Widgets 工业界面设计 | 页面结构、状态模型、交互验收 |
| [halcon-vision-engineer](skills/halcon-vision-engineer/SKILL.md) | HALCON 视觉、标定、模板识别 | 算法方案、参数表、验证记录 |
| [motion-plc-safety](skills/motion-plc-safety/SKILL.md) | PLC、运动控制、设备联锁 | 时序、状态机、故障合同 |
| [nodeflow-engineer](skills/nodeflow-engineer/SKILL.md) | 节点式编排、流程运行时 | 节点契约、执行模型、序列化 |
| [industrial-code-review](skills/industrial-code-review/SKILL.md) | 代码审查、缺陷复现、回归 | 分级问题清单、验证矩阵 |
| [industrial-project-proposal](skills/industrial-project-proposal/SKILL.md) | 方案选型、项目立项、实施评审 | 技术方案、风险、里程碑、验收 |
| [industrial-test-report](skills/industrial-test-report/SKILL.md) | FAT/SAT、性能测试、验收 | 可追溯报告、缺陷与证据 |
| [industrial-presentation](skills/industrial-presentation/SKILL.md) | 领导汇报、客户技术交流 | PPT 大纲、讲解备注、数据图 |
| [industrial-promo-video](skills/industrial-promo-video/SKILL.md) | 产品宣传、设备演示、原理动画 | 脚本、分镜、素材表、成片 QA |

## 目录

```text
MyWorkSkills/
├── skills/<skill-name>/SKILL.md   # 可按需调用
├── templates/                    # 文档、报告、汇报与视频分镜模板
├── docs/                         # 工作流与交付标准
└── scripts/                      # PowerShell 安装与校验（含校验器自测）
```

## Windows / PowerShell 安装

克隆仓库后在仓库根目录执行：

```powershell
git clone https://github.com/2774326573/MyWorkSkills.git
cd MyWorkSkills
./scripts/validate-skills.ps1        # 结构校验，退出码 0 才算通过
./scripts/install.ps1 -Target OpenCode -Scope User
```

`./scripts/test-validate-skills.ps1` 是校验器的自测脚本：在系统临时目录生成合法与故意损坏的样例，验证校验器能正确报错，跑完自动清理。

如需项目级安装，指定要安装的工程目录：

```powershell
./scripts/install.ps1 -Target OpenCode -Scope Project -ProjectPath 'D:\Work\MyProject'
```

参数：

| 参数 | 取值 | 说明 |
| --- | --- | --- |
| `-Target` | `OpenCode` / `Codex` / `Claude` / `All` | 目标客户端，默认 `OpenCode` |
| `-Scope` | `User` / `Project` | 用户级或项目级，默认 `User` |
| `-ProjectPath` | 目录 | 项目级安装的工程根目录，默认当前目录 |
| `-Names` | 逗号分隔的 Skill 名 | 只安装指定 Skill，默认全部 |
| `-Force` | 开关 | 覆盖同名目录；覆盖前自动备份到系统临时目录 `MyWorkSkills-backups` |

安装目录（2026-10 按各官方文档核对）：

| 客户端 | 用户级 | 项目级 |
| --- | --- | --- |
| OpenCode | `~/.config/opencode/skills` | `<project>/.opencode/skills` |
| Codex | `~/.agents/skills` | `<project>/.agents/skills` |
| Claude Code | `~/.claude/skills` | `<project>/.claude/skills` |

脚本不会联网安装任何东西，只做本地文件复制；不加 `-Force` 时已存在的同名 Skill 会被跳过，不会覆盖。

注意两点：

- `-Target All` 会向三个位置各复制一份。OpenCode 同时兼容读取 `.claude/skills` 和 `.agents/skills`，同项目装多份可能出现重复技能；只用一个客户端时建议只装对应目标。
- 目录被复制到正确位置不等于客户端一定加载。OpenCode/Codex/Claude 的加载规则随版本变化，装完应在目标 Agent 里做一次最小触发测试；VS2022 内嵌 AI 扩展是否支持 Agent Skills 需单独确认。

## 推荐使用方法

1. 提供项目目标、硬件/软件版本、边界、现有资料；不确定的前提先标记待确认。
2. 由 `engineering-constraints` 固化范围与不能违反的合同。
3. 开发工作调用对应技术 Skill；方案/报告/宣传调用交付 Skill。
4. 对产出执行审查：引用证据、验证结果、版本、权限和保密性。
5. 在任务关闭前列出已验证、未验证、遗留问题，不能把“计划测试”写成“测试通过”。

## 验证记录（2026-10-20）

| 检查项 | 方式 | 结果 |
| --- | --- | --- |
| Skills 结构校验 | `./scripts/validate-skills.ps1`，Windows PowerShell 5.1（5.1.26100）与 PowerShell 7.6.7，CRLF/LF 两种检出 | 11/11 通过，退出码 0 |
| 校验器自测 | `./scripts/test-validate-skills.ps1`：合法 LF、合法 CRLF 两个样例，另加 8 个样例（1 个健康对照 + 6 类结构错误 + 1 个 UTF-8 BOM） | 5.1 与 7 均通过：合法样例接受，6 类结构错误 + 1 条 BOM 警告一次报全，退出码 1 |
| 安装脚本 | `./scripts/install.ps1 -Target All -Scope Project -ProjectPath <临时目录>`；`-Names` 过滤；`-Force` 覆盖 | 复制 33 个 Skill 目录，退出码 0；备份写到系统临时目录，技能发现目录内不残留备份；未知 Skill 名报错退出 1 |
| 安装目录 | 对照 OpenCode / Codex / Claude Code 官方文档（2026-10 抓取） | 6 条路径一致，见上表 |
| 客户端加载与触发 | — | **未执行**：需要在 OpenCode/Codex/Claude 中实际加载后再判断，本仓库不声称已通过 |
| 宣传视频成片 | — | **未执行**：仓库只有脚本、分镜与规范，没有渲染完成的 MP4 |

没有实测过的项不会写成“已通过”；Skill 是否被客户端加载需在你的环境里单独验证。

## 外部 Skills（可选，非本仓库内置）

- [Superpowers](https://github.com/obra/superpowers)：系统调试、测试驱动、完成前验证。
- [Qt Agent Skills](https://github.com/TheQtCompanyRnD/agent-skills)：Qt 专项建议；检查 Qt5/Qt6 兼容。
- [Remotion Skills](https://github.com/remotion-dev/skills)：宣传视频项目创建、动画、字幕、渲染。
- [Agent Skills 规范](https://agentskills.io/specification)：SKILL.md 标准。

## 项目与知识产权隔离

本仓库是**通用方法库**，不自动包含任何公司的闭源代码、设备协议、项目文件、授权材料或客户资料。项目资料只能在有权访问与公开的范围内引入；不同项目的源码、设备接口与事实不得混用。

## 许可

本仓库为技能说明与示例文档集；发布和复用前应确认项目贡献者及第三方材料的许可归属。外部 Skills 由各自作者维护，不随本仓库复制。
