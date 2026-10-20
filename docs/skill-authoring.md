# 添加自己的 Skills

遵循 https://agentskills.io/specification

目录约定：

    skills/
      my-new-skill/
        SKILL.md
        references/
        scripts/
        assets/

SKILL.md 文件开头需包含 YAML frontmatter，name 与目录名一致（小写字母、数字、连字符，最多 64 字符），description 在 1–1024 字符内，描述什么时候触发。正文优先写执行步骤与可验收产物，少写空泛角色扮演。

要求：
1. 一个 Skill 聚焦一个任务领域，不复制其他 Skill 大段正文。
2. 知识的真伪优先通过真实仓库、SDK 文档和实验结果判断。
3. 外部依赖只提供可选安装建议，不强制自动下载、运行不透明脚本。
4. 危险设备动作必须具备独立安全审批。
5. 提交前运行 scripts/validate-skills.ps1，再使用 OpenCode/Codex/Claude 各做一个触发测试。

如果需要增加“个人决策风格”或特定工作方法，先从明确写出的原则及实际范例建立 references 文件，不要凭 AI 想象用户规则。
