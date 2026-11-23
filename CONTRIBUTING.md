# 协作指南（平行之岛）

## 1. 本机首次接入

```bash
# 已配置：仓库使用专用 SSH key（~/.ssh/id_ed25519_github）
git remote -v          # 应指向 git@github.com:NaughtyEel/Parallel-Island.git
ssh -T git@github.com  # 首次会问 yes，看到 "Hi NaughtyEel!" 即成功
```

## 2. 日常提交流程

```bash
git pull --rebase        # 先同步远程
git add -A
git commit -m "一句话说明改了什么"
git push
```

建议提交粒度：一个事件 / 一个角色 / 一个系统模块一次提交，message 用「模块: 改动」，例如
`events: 补第二章码头事件`、`ui: 字幕支持行距设置`。

## 3. 好友参与开发

### 邀请权限（仓库管理员操作）

1. 打开 https://github.com/NaughtyEel/Parallel-Island/settings/access
2. **Add people** → 输入对方的 GitHub 用户名或邮箱
3. 角色选 **Write**（可推送代码）；只读参观选 **Read**
4. 对方接受邮件邀请后即可 clone 并推送

> 公开仓库的免费账号协作人数不限；私有仓库免费版最多 3 人协作。

### 对方克隆并运行

```bash
git clone git@github.com:NaughtyEel/Parallel-Island.git
# 或用 HTTPS：git clone https://github.com/NaughtyEel/Parallel-Island.git
cd Parallel-Island
# 用 Godot 4.6 打开该目录，按 F5 运行
```

> 仓库根目录就是 Godot 工程目录，克隆后直接打开 `project.godot` 即可。

### 推荐协作方式

- `main` 保持可运行；每个人在 `feature/xxx` 分支上开发，推上去开 Pull Request。
- PR 至少一个人看过再合并；合并前跑一次 `Godot --headless --path . --scene res://tests/smoke.tscn`。
- 剧情 JSON 冲突多，建议按事件文件（`data/events/*.json`）分工，一人一个文件。

## 4. 美术资源与大文件

- 立绘、BGM、CG 建议放 `assets/`，超过 10MB 的文件用 **Git LFS**：
  ```bash
  git lfs install
  git lfs track "assets/**/*.png" "assets/**/*.ogg"
  git add .gitattributes
  ```
- `.godot/` 是本地缓存，已在 `.gitignore` 中忽略，不要提交。

## 5. 分支保护（可选，推荐）

Settings → Branches → Add branch protection rule：
- 保护 `main`，要求 PR 合并、禁止直接 push；
- 适合多人后开启；单人开发阶段可以先不设。
