#!/usr/bin/env python3
"""生成 data/story/prologue.json。改剧情改这里，然后 python3 tools/build_story.py。"""
import json, pathlib

nodes = []

def line(speaker, text, char=None):
    n = {"type": "line", "speaker": speaker, "text": text}
    if char: n["char"] = char
    nodes.append(n)

def stage(chars=None, props=None, **kw):
    n = {"type": "stage"}
    if chars is not None: n["chars"] = chars
    if props is not None: n["props"] = props
    n.update(kw)
    nodes.append(n)

def scene(bg, sky):
    nodes.append({"type": "scene", "bg": bg, "sky": sky})

def label(name):
    nodes.append({"type": "label", "name": name})

def choice(prompt, options):
    nodes.append({"type": "choice", "prompt": prompt, "options": options})

def branch(bid, title):
    nodes.append({"type": "branch", "id": bid, "title": title})

def death(chars, text):
    nodes.append({"type": "dynamic_death", "chars": chars, "text": text})

def fixed_death(char, text):
    nodes.append({"type": "death_fixed", "char": char, "text": text})

def ending(eid, title, text):
    nodes.append({"type": "ending", "id": eid, "title": title, "text": text})

# ── 序章：上岛 ──────────────────────────────────────────────
scene("island_day", "day")
stage(chars=[])
line("旁白", "十月的最后一个周末，我坐上了开往东莱岛的渡轮。")
line("旁白", "出发前，群里还在为「年度合奏曲目」吵得不可开交——有人说要弹《诗超绊》，有人说弹点能出片的，还有人只想弹自己会的那四小节。")
line("旁白", "东莱岛不大，地图上只是海面上一粒不起眼的点。岛的正中央，是洋洋家的别墅。")
stage(chars=[{"id":"yangyang","slot":"center"}])
line("洋洋", "欢迎来到我的小岛——虽然一年也住不了几天。别客气，反正也不值几个钱。", "yangyang")
stage(chars=[{"id":"leila","slot":"left"},{"id":"yangyang","slot":"center"},{"id":"aja","slot":"right"}])
line("后备箱", "……这房子比我们学校操场还大。", "leila")
line("副驾驶", "主人的钱，和我的加班费，是两个物种。", "aja")
stage(chars=[{"id":"qianshi","slot":"center"}])
line("茜师傅", "都别感慨了，先把器材搬进去！合奏只剩两天准备时间，谁再磨蹭我就把他名字写进群公告。", "qianshi")

choice("器材堆在门口。你决定先帮谁？", [
    {"text": "帮后备箱搬音箱", "goto": "a1", "aff": {"leila": 2}},
    {"text": "陪洋洋调试新琴", "goto": "a2", "aff": {"yangyang": 2}},
    {"text": "和吉娘姐对一遍谱子", "goto": "a3", "aff": {"jiaoguan": 2}},
])

label("a1")
stage(chars=[{"id":"leila","slot":"center"}])
line("后备箱", "（她一把扛起音箱，回头看你）……发什么呆，搭把手啊。你、你别盯着我手臂看，我这是干活练出来的。", "leila")
line("旁白", "音箱比想象中沉。她一个人扛了两台，你只搬得动一台。")
line("后备箱", "行啊，比群里那几个只会「电子琴」的强。晚上我请你吃鸡架。", "leila")
goto_merge = len(nodes)
nodes.append({"type": "jump", "goto": "after_choice_a"})

label("a2")
stage(chars=[{"id":"yangyang","slot":"center"}])
line("洋洋", "（她把琴递给你，像递一张餐巾纸）帮我听听，这个音色是不是有点「穷」？", "yangyang")
line("旁白", "你还没听过「穷」的音色。")
line("洋洋", "就是那种……不够贵的音色。算了，你随便弹，我听听手感。", "yangyang")
nodes.append({"type": "jump", "goto": "after_choice_a"})

label("a3")
stage(chars=[{"id":"jiaoguan","slot":"center"}])
line("吉娘姐", "你来得正好。第三段的转调我改了两版，你更喜欢哪一版？", "jiaoguan")
line("旁白", "她把谱子摊在桌上，用笔点着那两行音。你忽然发现，她讲这些的时候，眼睛很亮。")
line("吉娘姐", "选不出来也没关系。排练的时候，耳朵会替你选。", "jiaoguan")
nodes.append({"type": "jump", "goto": "after_choice_a"})

label("after_choice_a")
stage(chars=[])
line("旁白", "下午，琴声在别墅里绕来绕去。有人在楼上练solo，有人在厨房煮面，有人在露台上睡着了。")
stage(chars=[{"id":"jiaoguan","slot":"left"},{"id":"aja","slot":"center"},{"id":"laoj","slot":"right"}])
line("吉娘姐", "这一段，我按大家的水平拆成了三个声部。谁跟不上就降八度，别硬撑。", "jiaoguan")
line("副驾驶", "这个编曲……你确定不是想让我们集体翻车？", "aja")
line("牢 J", "别吵，先弹一遍。弹完再吵。", "laoj")

branch("b_dinner", "第一夜 · 合奏前的晚餐")
stage(chars=[{"id":"gouwang","slot":"left"},{"id":"nianai","slot":"center"},{"id":"huaichuai","slot":"right"}])
line("小万", "我琴头昨天摔断过一次。今天要是再断，我就当场退群。", "wanjiang")
line("希腊奶", "……你今天已经说过三次了。", "nianai")
line("汉灵帝", "先吃饭吧，吃完再摔。", "lingdi")
line("旁白", "众人都笑了。那大概是这座岛上最后一个毫无负担的笑。")
stage(chars=[])
line("旁白", "晚饭后，茜师傅把大家赶到排练厅，一直练到手指发麻。")
stage(chars=[{"id":"qianshi","slot":"center"}])
line("茜师傅", "明天上午最后合一遍，下午录视频。谁要是拖后腿，我就把他的part发到群里公开处刑。", "qianshi")

choice("晚饭的位子只剩三个。你坐在谁旁边？", [
    {"text": "后备箱旁边（她刚烤好鸡架）", "goto": "b1", "aff": {"leila": 2}},
    {"text": "洋洋旁边（她带了香槟）", "goto": "b2", "aff": {"yangyang": 2}},
    {"text": "吉娘姐旁边（她想聊编曲）", "goto": "b3", "aff": {"jiaoguan": 2}},
])
label("b1")
line("后备箱", "（她把鸡架往你这边推了推）……吃啊。看着我干嘛。", "leila")
nodes.append({"type":"jump","goto":"after_b"})
label("b2")
line("洋洋", "这瓶不算贵，也就四位数。来，敬这座岛。", "yangyang")
nodes.append({"type":"jump","goto":"after_b"})
label("b3")
line("吉娘姐", "你听这一段，如果换成人声，会不会更好？", "jiaoguan")
nodes.append({"type":"jump","goto":"after_b"})

label("after_b")
scene("island_dusk", "dusk")
stage(chars=[])
line("旁白", "天色暗下来的时候，海面上出现了一艘军舰。")
stage(chars=[{"id":"leila","slot":"left"},{"id":"aja","slot":"center"},{"id":"yangyang","slot":"right"}])
line("副驾驶", "那是什么船？锚地不是应该在外海吗？", "aja")
line("后备箱", "不像我们见过的任何一种型号……舰岛太高了，桅杆也不太对。", "leila")
line("洋洋", "东大的船？可这个轮廓，我在新闻里没见过。", "yangyang")
line("旁白", "那艘军舰安静地停在雾里，像一件被忘在海上的巨大仪器。")
branch("b_quake", "地震 · 世界线偏移")

scene("quake_red", "red")
stage(chars=[])
line("旁白", "然后，地震来了。")
line("旁白", "6.5 级。吊灯在晃，餐具从桌上滑下去，墙皮簌簌地落。")
line("旁白", "天空和海面同时变红。不是晚霞的红，是某种更深的、会流动的红。")
stage(chars=[{"id":"leila","slot":"left"},{"id":"jiaoguan","slot":"right"}])
line("后备箱", "抓住桌子！别站在玻璃旁边！", "leila")
line("吉娘姐", "所有人到一楼大厅集合！少一个都不行！", "jiaoguan")
line("旁白", "耳鸣。恶心。视线在抖。你扶着墙，感觉整座岛像是被谁轻轻提起来，又放下。")
death(["leila", "yangyang", "moqie", "wanjiang"], "等到震动停下，{victim}没有出来。")
line("旁白", "她的房间门虚掩着。人倒在床边，后脑有一处钝器伤。")
line("旁白", "凶器就在房间中央——{victim}自己的乐器。")
line("旁白", "没有人尖叫。所有人只是看着，像在等一个不会出现的解释。")
branch("b_after_quake", "震后 · 第一具尸体")

stage(chars=[{"id":"jiaoguan","slot":"center"}])
line("吉娘姐", "都别碰任何东西。从现在开始，谁离开我的视线，我就当谁是凶手。", "jiaoguan")
stage(chars=[{"id":"qianshi","slot":"left"},{"id":"laoj","slot":"right"}])
line("茜师傅", "电话打不通。网络也断了。整个岛，像是从地图上被撕下来了。", "qianshi")
line("牢 J", "先别慌。岛上就这么些人，事情总能查清楚。", "laoj")
line("旁白", "可你注意到，说这句话的时候，他的手在抖。")

branch("b_choice", "抉择 · 严惩还是调查")
choice("你准备怎么处理这件事？", [
    {"text": "严惩：把最可疑的人关押起来，逼问到底", "goto": "punish", "flags": {"harsh": True}},
    {"text": "调查：先弄清每个人之间的关系，再决定", "goto": "investigate", "flags": {"harsh": False}},
])

label("punish")
stage(chars=[{"id":"qianshi","slot":"center"}])
line("旁白", "你把最可疑的人反锁进了储藏室。")
line("茜师傅", "你凭什么？他说不定只是……", "qianshi")
line("旁白", "你没有听。你开始审问每一个人，声音越来越冷。")
line("旁白", "那一夜，别墅里没有一个人睡着。")
line("旁白", "第二天清晨，你听见自己的呼吸变得很重。某种东西在血管里涨潮。")
ending("bad_all", "坏结局 · 全灭", "你看着自己的手，觉得它们很陌生。\n身边的人也变了——他们的眼睛发红，像被什么东西从里面点亮。\n最后，你们互相撕碎了彼此。\n\n在意识熄灭之前，你听见一个声音：\n「观测对象死亡。开始回溯。」")

label("investigate")
stage(chars=[{"id":"jiaoguan","slot":"center"}])
line("吉娘姐", "先查动机。谁和她有过节，谁知道她的房间在哪，谁知道她的乐器在哪。", "jiaoguan")
line("旁白", "你们把所有人聚在大厅，一个一个问话。")
line("旁白", "有人哭，有人沉默，有人说着说着突然笑起来——笑得很短，像被掐断。")
line("旁白", "午夜，第二具尸体出现了。")
nodes.append({"type":"death_fixed","char":"jiaoguan","text":"吉娘姐被自己的乐器连接线勒死在排练厅。她的手里攥着一页谱子，上面只有四个字：「别相信海。」"})
line("旁白", "你跪在她身边，指尖发抖。")
line("旁白", "然后你听见了那个声音。不是从空气里来的，是从你的骨头里。")
line("旁白", "「观测对象：编号仍未收敛。开始回溯。」")
ending("demo_continue", "二周目 · 涨落（未完待续）", "你睁开眼。渡轮正在靠岸。\n东莱岛的轮廓在雾里，像一件还没被拆开的礼物。\n\n这一次，你知道谁会在夜里死去。\n也知道那艘军舰，正在等一个去打开它的人。")

# 修补 goto：把占位 jump 修好
for i, n in enumerate(nodes):
    if n.get("type") == "jump" and "goto" not in n:
        n["goto"] = ""

story = {
    "id": "prologue",
    "title": "序章 · 东莱岛",
    "nodes": nodes,
}
for i, n in enumerate(nodes):
    if n.get("type") == "jump":
        target = n["goto"]
        # 解析 label
        for j, m in enumerate(nodes):
            if m.get("type") == "label" and m.get("name") == target:
                n["jump_index"] = j
                break

path = pathlib.Path("data/story/prologue.json")
path.write_text(json.dumps(story, ensure_ascii=False, indent=2), encoding="utf-8")
print("nodes:", len(nodes), "->", path)
