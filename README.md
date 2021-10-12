# Xliff Tool For Xcode

Xliff Tool For Xcode, short for Xliff Tool, is a translation tool for developers. It supports version 1.2 .xliff files that are used by Xcode. If you installed Xcode 13, .xliff files are contained in .xcloc packages. 

> Before Xcode 13, .xcloc files in Finder were shown as directories.

## How to use
1. In Xcode, Export Localizations
2. In Xliff Tool, Open Files
3. [Choose Project](#ChooseProject)
4. [Translate](#Translate)
5. [Audit](#Audit)
6. [Save](#Save)
7. In Xcode, Import Localizations

### <span id="ChooseProject">3. Choose Project</span>
Choose "New Project" if it is a new project. Or choose the exist one that it was last used. If you want to create another version, you can choose "New Project" again.

### <span id="Translate">4. Translate</span>
Different colors mean differences.
* <font color=blue>Blue for Source</font>
* <font color=#13938F>Dark Green for Target(Unaudited)</font>
* <font color=green>Light Green for Target(Audited)</font>

![03 translate light-w1228](assets/03%20translate%20light.png)

### <span id="Audit">5. Audit</span>
To audit is to double check the translation. Whenever the Target is changed, it becomes unaudited. You must click verify button to pass the audit. 

### <span id="Save">6. Save</span>
When you close the project or the app, the project will save automatically. You can save manually at any time.

## Features
### Versioning
You can create multiple projects from one project.
### Auto Backup
Each time you open a project, Xliff Tool create a backup for it. The amount of backups is up to latest 5. You can use File-> Open Database Directory to open the directory in Finder. Those .realm files in backups folder are backups, you can copy them out and rename and restore data.
### Smart
Xliff Tool will replace Targets that are duplicated while you translate one of them. Then you can audit the rest so you don't need to input again.
### Shortcuts
You can use cmd+enter to finish audit.
### Index and Search
Using index and search, you can find source and target quickly. You can search by Source/Target/Notes, with/without case.

## Thanks

[XMLCoder](https://github.com/MaxDesiatov/XMLCoder)

When developing Xliff Tool, I found some issues are related to XMLCoder, [MaxDesiatov](https://github.com/MaxDesiatov) helps me a lot by adding new features that I needed to XMLCoder.

![app icon](xliff_tool_icon.png)

The icon of this app is from below.

Icons made by <a href="https://www.flaticon.com/authors/freepik" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>

## License
Xliff Tool's license is MIT, except for the icon. As the icon is from the website above mentioned.

## macOS
You will need macOS 11 or later to install Xliff Tool.

## Support
You can added issues by Github Issues. Or you can send mail to owenzx+feedback@gmail.com.

