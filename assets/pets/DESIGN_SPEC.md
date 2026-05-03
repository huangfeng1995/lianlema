# 第一期宠物角色设计规范

## 设计原则
- **风格**：温暖治愈、圆润可爱的Q版角色
- **视角**：正面站立姿势，方便后续叠加配件
- **尺寸**：512×512 PNG透明背景
- **输出**：5个单帧PNG，后期可扩展为多帧动画

---

## 🦊 炭炭（狐狸）
**性格定位**：温暖鼓励型

### 设计要求
- 圆脸、大眼睛、蓬松的橙色尾巴
- 耳朵尖略带一点棕色
- 表情：温暖治愈的微笑，眼睛有高光
- 可选：小围巾或领结

### 配色方案
```
主色：#FF6B35（活力橙）
辅色：#FFB347（浅橙）
点缀：#8B4513（棕色耳朵/围巾）
背景：透明
高光：#FFFFFF（眼睛、脸部）
```

### AI生成Prompt
```
Cute cartoon fox character, round face, big sparkling eyes, fluffy orange tail, 
warm gentle smile, wearing a small red scarf, simple kawaii style, 
solid transparent background, centered composition, 512x512 PNG, 
high quality illustration, clean lines, pastel colors
```

---

## 🐺 闪焰（狼）
**性格定位**：激情驱动型

### 设计要求
- 健壮但可爱的形象，不要太凶
- 尖耳朵、银灰色毛发
- 表情：坚定有神的眼神，偶尔露出小尖牙显得酷
- 可选：火焰纹样或橙色元素

### 配色方案
```
主色：#6B7280（银灰）
辅色：#9CA3AF（浅灰）
点缀：#FF6B35（火焰橙）
背景：透明
高光：#E5E7EB（毛发高光）
```

### AI生成Prompt
```
Cute cartoon wolf character, strong but adorable, pointy ears, silver-gray fur, 
determined bright eyes, small fangs showing confident grin, 
cool pose, simple kawaii style, solid transparent background, 
centered composition, 512x512 PNG, high quality illustration, 
clean lines, cool gray color palette with orange accent
```

---

## 🐰 波波（兔子）
**性格定位**：温柔倾听型

### 设计要求
- 长长的大耳朵（可以是粉色内耳）
- 圆滚滚的身体，小短腿
- 表情：温柔害羞的微笑
- 可选：胡萝卜小配件或蝴蝶结

### 配色方案
```
主色：#FFB7C5（粉色）
辅色：#FFF0F5（淡粉）
点缀：#FF69B4（深粉蝴蝶结）
背景：透明
高光：#FFFFFF（眼睛、脸部）
```

### AI生成Prompt
```
Cute cartoon rabbit character, long floppy ears with pink inner ear, 
round fluffy body, short legs, gentle shy smile, big sparkly eyes, 
small pink bow on head, simple kawaii style, solid transparent background, 
centered composition, 512x512 PNG, high quality illustration, 
clean lines, pastel pink color palette
```

---

## 🦌 滴露（鹿）
**性格定位**：治愈陪伴型

### 设计要求
- 小巧的鹿角（不要太大）
- 温柔的大眼睛
- 表情：安静治愈的微笑
- 可选：花环或小草装饰

### 配色方案
```
主色：#D4A574（棕色）
辅色：#E8C9A0（浅棕）
点缀：#228B22（森林绿小草）
背景：透明
高光：#F5DEB3（毛发高光）
```

### AI生成Prompt
```
Cute cartoon deer character, small antlers, big gentle eyes, 
calm peaceful expression, soft brown fur, small forest green leaf decoration, 
simple kawaii style, solid transparent background, 
centered composition, 512x512 PNG, high quality illustration, 
clean lines, warm brown color palette with green accent
```

---

## 🖤 月影（黑猫）
**性格定位**：神秘智者型（用户必须要有）

### 设计要求
- 优雅的身姿，微微眯起的眼睛
- 尖尖的耳朵
- 表情：高冷神秘但偶尔露出一丝温柔
- 可选：月亮元素或星星项圈

### 配色方案
```
主色：#1F2937（深夜灰）
辅色：#374151（浅灰）
点缀：#FFD700（星星金）
背景：透明
高光：#4B5563（毛发高光）
眼睛：#FFD700（金色眼睛）
```

### AI生成Prompt
```
Elegant cartoon black cat character, sleek dark fur, mysterious half-closed eyes, 
尖尖的耳朵, subtle mysterious smile, golden eyes, small crescent moon accessory, 
simple kawaii style, solid transparent background, 
centered composition, 512x512 PNG, high quality illustration, 
clean lines, deep dark gray color palette with gold accent
```

---

## 通用输出要求

| 项目 | 规格 |
|------|------|
| 文件格式 | PNG透明背景 |
| 分辨率 | 512×512 像素 |
| 命名 | fox.png / wolf.png / rabbit.png / deer.png / blackcat.png |
| 保存位置 | `assets/pets/` |
| 背景 | 必须透明，不能有任何背景色 |

## 后续扩展（第二期）
- 多种表情（开心/思考/兴奋/睡觉）
- 进化形态（幼年期/成年期/完全体）
- 服装配件叠加层
- idle动画帧

---

## 推荐AI生成工具
1. **Midjourney**: 使用上面prompt，配合 `--v 6 --ar 1:1`
2. **DALL-E 3**: 直接使用prompt
3. **Stable Diffusion**: 配合 Detail Tweaker XL 模型
4. **Figma AI**: 导入草图生成

## 备选方案：使用现有素材
如果AI生成困难，可以考虑：
- [itch.io](https://itch.io/game-assets/tag-characters) - 免费游戏素材
- [OpenGameArt](https://opengameart.org/) - 开源游戏素材
- [Kenney.nl](https://kenney.nl/assets/category-animals) - 知名免费游戏素材包
