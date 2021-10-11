# Xliff Tool For Xcode

Xliff Tool For Xcode（简称Xliff Tool）是一个为开发者制作的翻译工具，它支持Xcode所使用的1.2版的.xliff文件。特别的，如果你的系统中安装了Xcode 13，.xliff文件被包含在.xcloc文件包中。因此，Xliff Tool也可以直接打开.xcloc中的.xliff文件。

> 在Xcode 13之前，.xcloc显示为文件夹的形式，因此可以直接打开。

## 使用流程
1. Xcode导出语言文件
2. Xliff Tool打开文件
3. [选择项目版本](#选择项目版本)
4. [翻译](#翻译)
5. [审核](#审核)
6. [保存](#保存)
7. Xcode导入语言文件

### <span id="选择项目版本">3. 选择项目版本</span>
如果是新项目，就选择“新项目”。如果是已有项目，就选择之前使用时的名字。如果有特殊需要，想要新建一个版本，也可以再次选择新项目。

### <span id="翻译">4. 翻译</span>
不同的颜色表示不同的含义。
* <font color=blue>蓝色-源</font>
* <font color=#13938F>深绿色-目标（未审核）</font>
* <font color=green>浅绿色-目标（审核完成）</font>

![03 翻译 亮-w1228](assets/03%20%E7%BF%BB%E8%AF%91%20%E4%BA%AE.png)

### <span id="审核">5. 审核</span>
审核是对于翻译的二次确认。“目标”发生改变之后，自动成为未审核的状态，需要点击审核来完成二次确认。这样便于确认是否最终完成。

### <span id="保存">6. 保存</span>
当项目/应用关闭时，会自动保存，也可以手动随时保存进度。

## 应用特性
### 多版本
针对一个项目，可以创建一个或者多个项目。
### 自动备份
每次打开时项目时，Xliff Tool会自动备份之前的数据库，一共会备份最近5次的数据。如果需要恢复，可以使用文件菜单->打开数据库文件夹，然后手动修改backups文件夹中的.realm文件。将其复制到上一层文件夹，并修改为不带时间标志的文件名。之后在重新开启项目，就可以恢复数据了。
### 避免重复劳动
Xliff Tool在你进行翻译的同时，会同时搜索是否有相同的关键词，如果有，也会一同翻译。这样，你只需要再次审核，就可以完成翻译，不必进行重复劳动。
### 快捷键
通过cmd+回车可以快速完成审核。
### 索引和搜索
右侧的索引和搜索可以快速定位源和目标，搜索可以根据源、目标和备注进行搜索，并且可以设置是否区分大小写。

## 致谢
## Thanks

[XMLCoder](https://github.com/MaxDesiatov/XMLCoder)

When developing Xliff Tool, I found some issues are related to XMLCoder, [MaxDesiatov](https://github.com/MaxDesiatov) helps me a lot by adding new features that I needed to XMLCoder.

![app icon](xliff_tool_icon.png)

The icon of this app is from below.

Icons made by <a href="https://www.flaticon.com/authors/freepik" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>

## License
Xliff Tool's license is MIT, except for the icon. As the icon is from the website above mentioned.

## macOS
你需要macOS 11或更新版的系统来使用Xliff Tool。

