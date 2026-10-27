# 聊天助手 · ChatTranslatorProbe_Mcode

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a-blue) ![完全离线](https://img.shields.io/badge/翻译-内置词典-informational)

给在英文服务器游玩的中文玩家使用的魔兽世界聊天插件。把组队喊话、交易和常见游戏术语中的已知表达替换成中文，并提供可选的信息屏蔽和重复消息去重。

适用于 **WoW 3.3.5a（TOC 30300）**，接入默认聊天框和 ElvUI Chat。内置词典随插件提供，游戏内完全离线运行。

[下载安装包](https://github.com/MuyuQ/ChatTranslatorProbe_Mcode/releases/latest) · [详细使用说明](docs/USAGE.md) · [更新记录](CHANGELOG.md) · [反馈问题](https://github.com/MuyuQ/ChatTranslatorProbe_Mcode/issues)

## 游戏内效果

![聊天助手在游戏中翻译组队与交易频道的示例](docs/images/chat-example.png)

玩家提供的实际聊天截图：已识别的招募、副本、职业和分配用语在原位置显示为中文，行尾的 `[原文]` 可查看原句。截图中仍有未识别的英文或其他语言片段；插件采用有限词典和句式匹配，不保证完整翻译每句话。

## 功能

| 功能 | 用法 |
|---|---|
| 常见术语翻译 | 识别 LFM / LFG、职业与专精缩写、副本、装备要求及明确的掉落分配表达 |
| WLK 游戏词汇 | 包含副本首领、机制、职业技能和团队增益；有歧义的缩写结合聊天语境判断 |
| 三种显示方式 | 替换原文、注释保留、术语列表；已知词翻译，未知片段保留 |
| 分类着色 | 分别设置副本、职业／职责和其他文本的颜色，保留游戏链接自身颜色 |
| 重复消息去重 | 同一玩家完全相同的消息按统一间隔隐藏，可合并所选公共频道与喊话 |
| 可选信息屏蔽 | 公会招募、四类广告、自定义屏蔽词与白名单，按需开启 |
| 本地漏译记录 | 保存未识别和部分翻译样本，供后续人工分析、扩充词典 |

例如，`LFM` 表示队伍招人，`LFG` 表示玩家求组；`disc / disco` 在对应语境下表示戒牧。数字、玩家名、链接和未识别条件会保留，避免把局部术语替换当成整句理解。

## 安装

1. 从 [Releases](https://github.com/MuyuQ/ChatTranslatorProbe_Mcode/releases/latest) 下载插件 ZIP，并完全退出游戏。
2. 解压后把 **`ChatTranslatorProbe_Mcode`** 文件夹放入游戏的 `Interface/AddOns/`。
3. 重新登录，在插件管理器中启用“聊天助手”，输入 `/chatassist` 打开设置。
4. 在“翻译设置”中勾选 **开启聊天翻译**。新装翻译默认关闭，升级保留已有设置。

安装后的目录应为：

```text
Interface/
└── AddOns/
    └── ChatTranslatorProbe_Mcode/
        ├── ChatTranslatorProbe_Mcode.toc
        ├── Engine.lua
        └── Probe.lua
```

若下载的是 GitHub 的 Source code ZIP，请把带分支或版本后缀的目录改名为 `ChatTranslatorProbe_Mcode`，确认 TOC 直接位于该目录下。ElvUI 为可选接入，不要求安装。

## 初次使用

输入 `/chatassist`，或打开 **ESC → 界面 → 插件 → 聊天助手**。插件启用状态在 **ESC → 插件管理** 中管理。

| 设置 | 新装默认值 |
|---|---|
| 聊天翻译 | 关闭，手动开启 |
| 按类别着色 | 开启，三类颜色均可调整 |
| 重复消息去重 | 开启，默认 30 秒，可选 10–300 秒档位 |
| 合并公共频道与喊话去重 | 开启；其他来源按设置选择 |
| 屏蔽通用语 | 开启；按游戏语言标记识别，正常文字也可能受该标记影响 |
| 屏蔽公会招募／金币、账号、代练、付费代刷广告 | 关闭，按需开启 |
| 本地样本采集 | 开启，可在“本地记录”关闭或清空 |

翻译、过滤、去重和采集分别设置。`/chatassist off` 只关闭翻译，其余功能需要在对应设置中调整。

常用命令：

| 命令 | 作用 |
|---|---|
| `/chatassist` | 打开设置 |
| `/chatassist on` / `/chatassist off` | 开启／关闭翻译 |
| `/chatassist status` | 查看版本、接入状态与计数 |
| `/chatassist demo` | 在本地查看示例，不发送频道消息 |

`/ctprobe` 与 `/chatassist` 等效。显示模式、屏蔽词、白名单、去重来源和性能诊断的完整用法见 [使用说明](docs/USAGE.md)。

## 词典与反馈

运行词典内置于 `Engine.lua`，无需另外下载，也不调用网络翻译服务。英文大小写与已收录别名共用匹配规则；技能和职责短缩写会按语境区分。当前主要覆盖英文，仅包含有限的其他语言固定表达，不提供完整俄语翻译。

遇到漏译、错译或显示异常，可在 [Issues](https://github.com/MuyuQ/ChatTranslatorProbe_Mcode/issues) 提供原句、期望含义、插件版本和截图。若提供本地记录，请先检查并移除不希望公开的私聊、玩家名等内容；插件不会自动上传记录。

## 项目文件

- [`Engine.lua`](Engine.lua)：内置词典、翻译匹配、过滤、去重和记录处理。
- [`Probe.lua`](Probe.lua)：聊天接入、设置页和命令。
- [`docs/USAGE.md`](docs/USAGE.md)：详细使用与排查说明。
- [`CHANGELOG.md`](CHANGELOG.md)：历次版本更新记录。

作者：Mcode。
