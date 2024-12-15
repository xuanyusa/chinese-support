# chinese-support
全局插件，为vim添加中文拼音搜索支持

# 介绍
在vim中，搜索中文需要切换输入法，然后输入中文进行搜索。使用chinese-support可以不用切换输入法，直接使用拼音进行搜索。并且该插件支持首字母搜索，全拼搜索，或者两种方式的混合搜索。

# 依赖
使用vim脚本语言编写，没有额外依赖

# 支持的功能
- 全拼搜索
- 首字母简拼搜索
- 首字母简拼搜索支持区分平舌和翘舌音，如z、c、s和zh、ch、sh
- 全拼和首字母简拼混合搜索
- 不限制搜索长度
- 支持使用'进行拼音拆分，如把`xian`使用`xi'an`拆分识别为`xi an`两个拼音，这样可以识别西安或先类似的字符
- 支持正向，反向搜索
- 支持搜索后使用`n`,`N`命令导航
- 支持多音字搜索，如萝卜既可以使用`luobo`进行搜索，也可以使用`luobu`来进行搜索

# 缺省绑定
缺省情况下chinese-support使用`<leader>/`和`<leader>?`来映射正向搜索和反向搜索，可以设置`g:mapleader`变量来修改映射的首字符，如
```
let g:mapleader = ' '
```
把<leader>设置为空格。如果没有修改`g:mapleader`，缺省为`\`。
当然根据个人使用习惯也可以映射命令修改搜索使用的快捷键，只需要使用`nnoremap`来映射`<Plug>chinese-support-search-forward;`和`<Plug>chinese-support-search-backward;`即可。设置参考下面的例子，把`<leader>/`和`<leader>?`修改想要映射的按键。
```
" 正向搜索
nnoremap <leader>/ <Plug>chinese-support-search-forward;

" 反向搜索
nnoremap <leader>? <Plug>chinese-support-search-backward;

```
当使用中文搜索后，会自动映射`n`和`n`按键，不需要额外的配置

# 示例

## 全拼搜索
![全拼搜索演示](https://github.com/xuanyusa/reference/blob/89c9cb6b7e8b06caa3283e6e049f667f25f90b0f/vim/chinese-support/quanpin.gif)

## 首字母搜索
![首字母搜索演示](https://github.com/xuanyusa/reference/blob/89c9cb6b7e8b06caa3283e6e049f667f25f90b0f/vim/chinese-support/szm.gif)

## 混合搜索
![混合搜索演示](https://github.com/xuanyusa/reference/blob/89c9cb6b7e8b06caa3283e6e049f667f25f90b0f/vim/chinese-support/hunhe.gif)

## 单引号'拆分
![单引号拆分演示](https://github.com/xuanyusa/reference/blob/89c9cb6b7e8b06caa3283e6e049f667f25f90b0f/vim/chinese-support/danyinhao.gif)

