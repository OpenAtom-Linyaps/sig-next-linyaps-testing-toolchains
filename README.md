# Next Linyaps Testing Toolchains
## 项目介绍
`Next Linyaps Testing Toolchains` 是一套shell脚本组成的玲珑应用测试工具链，旨在为玲珑应用测试带来更多便捷的方案
本项目部分功能借鉴 [Deepin Autotest](https://youqu.uniontech.com/)的正统精神传承，承诺永久开源

\* 当前仓库可以直接使用, 使用文档、代码解释需要等待后续更新

## 已实现功能

1. 将指定目录下零散的 `*binary.layer` 文件整理为一个具备规范化的目录结构: `xxx/id/package` 并生成存放玲珑应用id、应用版本号的两个表格

2. 指定整理完成的玲珑文件存放目录后，开启流水化安装进程

3. 指定资源存放目录和应用信息表格后，根据 `安装情况`、 `desktop文件存在状态` 、`窗口生成状态` 来模拟通过desktop文件启动应用，并对测试结果进行截图
\* 当前代码部分功能依赖 `deepin 23` 系统组件，在其他发行版使用时需要重新适配

4. 对已安装的玲珑应用进行图标文件扫描, 判断当前应用icons目录及文件是否符合 `Freedesktop XDG` 规范并收集图标

5. 对已安装的玲珑应用进行批量卸载

