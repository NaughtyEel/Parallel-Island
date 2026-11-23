# 平行之岛（Parallel Island）

表面是恋爱 galgame，背后是悬疑：一周目必死，二周目回环，三周目破局。
本仓库是 **可运行的剧情骨架**（第一章 demo），剧情按「事件」组织，重点在引擎与模块。

## 事件系统（2026-11 新增）

- `data/events/*.json`：事件流。每个事件带 `time_slots / loop / location / requires / affinity_min` 触发条件，
  `next` 是满足条件时的候选，`fallback` 是不满足时的兜底事件。
- 事件内容：`scene`（场景图）、`bgm`（背景音乐）、`chars`（立绘）、`props`（道具）、`nodes`（对白/选择/反馈）。
- 判定顺序：时间段 → 地点 → 周目前置 → 前置事件 → 好感度阈值；命中则进入，否则进入 fallback。
- 第一章「上岛」：`e01_arrive`（船上）→ `e02_dock`（码头）；二周目走 `e01_alt`（既视感版本）。

## 运行

```bash
/Volumes/5TSolid/Godot.app/Contents/MacOS/Godot --path .
```

或把整个 `Donglai/` 目录导入 Godot 4.6 后按 F5。

## 目录

```
Donglai/
├── project.godot          # 主配置，autoload：Game / Saves / Story / Settings
├── main.tscn              # 唯一场景：Node + main.gd
├── main.gd                # 路由：标题 / 游戏 / 分支树
├── autoload/
│   ├── events.gd         # 事件系统（条件判定 + 事件流）
│   ├── audio.gd          # BGM 占位
│   ├── game_state.gd      # 世界线状态（好感度、旗标、死亡、舞台、历史）
│   ├── save_manager.gd    # 3 个存档槽 + 跨周目分支/结局记录
│   ├── story_db.gd        # 读 data/*.json：剧本、角色、场景、道具
│   └── settings.gd        # 字幕大小 / 文本速度 / 自动间隔
├── story/story_engine.gd  # 节点执行器（line / choice / jump / scene / stage / branch / death / ending）
├── ui/
│   ├── kit.gd             # UI 小工具（按钮/面板/渐变背景）
│   ├── title_screen.gd    # 标题 + 继续 + 设置
│   ├── game_screen.gd     # 舞台 + 字幕 + 选项 + 存读档 + 日志 + 调试面板
│   └── branch_tree_screen.gd  # 分支树 + 结局一览
├── data/
│   ├── events/chapter1.json   # 第一章事件（上岛）
│   ├── story/prologue.json    # 序章剧本（由 tools/build_story.py 生成）
│   ├── characters.json        # 20 个角色的登记表（名字/类型/主题色）
│   ├── scenes.json            # 场景（白天/黄昏/赤色/夜晚/军舰）
│   └── props.json             # 道具（吉他/音箱/香槟/收音机/军舰剪影）
└── tools/build_story.py       # 剧本生成器（改剧情后重跑）
```

## 操作

| 操作 | 按键 |
|---|---|
| 推进对话 | 空格 / 回车 / 鼠标左键 |
| 快进 | 右上角「快进」 |
| 自动播放 | 右上角「自动」 |
| 日志 | 右上角「日志」 |
| 存/读档 | 右上角「保存 / 读取」 |
| 分支树 | 右上角「分支树」/ 标题界面 |
| 调试面板（场景/道具预览） | F1 |

## 剧本格式

`data/story/prologue.json` 是 `{id, title, nodes: [...]}`，节点按顺序执行，支持：

- `{"type":"line","speaker":"莱拉","text":"...","char":"leila"}`
- `{"type":"stage","chars":[{"id":"leila","slot":"left"}],"props":[{"id":"guitar"}]}`
- `{"type":"scene","bg":"island_dusk","sky":"dusk"}`（sky: day/dusk/red/night）
- `{"type":"choice","prompt":"...","options":[{"text":"...","goto":"label_name","aff":{"leila":2},"flags":{"harsh":true}}]}`
- `{"type":"label","name":"label_name"}` / `{"type":"jump","goto":"label_name"}`
- `{"type":"branch","id":"b_1","title":"分支标题"}`（触发时自动记录快照，供分支树回跳）
- `{"type":"dynamic_death","chars":["leila","yangyang"],"text":"{victim} 没有出来。"}`
- `{"type":"death_fixed","char":"jiaoguan","text":"..."}`
- `{"type":"ending","id":"bad_all","title":"...","text":"..."}`

## 角色表（12 岛上 + 8 群聊）

- **岛上 12 人**：后备箱（leila）、洋洋（yangyang）、吉娘姐（jiaoguan）、茜师傅（qianshi）、
  牢J（laoj）、東清（dongqing）、八级大狂风（kuangfeng）、副驾驶（aja）、小万（wanjiang）、
  希腊奶（nianai）、汉灵帝（lingdi）、莫邪（moqie）。
- **群聊 8 人**（只在对话框出场，无立绘）：狗王（gouwang）、副驾驶回应了你的消息（tongzhi）、
  8J（jjiang）、无名（wuming）、junzchen（junchen）、怀揣（huaichuai）、高纯度铋（bijiang）、Time limit（limit）。
- 角色名与原型昵称的对应写在 `data/characters.json`；`on_island` 区分是否上岛，`role` 区分攻略/嫌疑/支援/客串。

## 与设计文档的对应

- 首名死者按「互动最多」（好感度最高）动态判定：`dynamic_death`。
- 第二名死者固定为教官：`death_fixed`。
- 「严惩 → 全灭」与「调查 → 二周目」两条分支已跑通，可作为悬疑主干骨架。
- 分支树里点「从此刻重来」会恢复当时的好感度、旗标、死亡名单与历史，便于多周目测试。

## 已知边界（骨架阶段）

- 角色立绘、背景图、音乐都还是占位（纯色/渐变），后续把图片放进 `assets/` 并在 `characters.json` / `scenes.json` 里补 `texture` 路径即可。
- 分支树目前是列表式，还没做真正的树形连线图。
- 三周目「带着教官上军舰启动锚定仪」的分支还没有写，等剧情细化。
