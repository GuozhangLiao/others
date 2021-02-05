# CentOS7如何创建和管理 services 服务

Systemd是一个系统和服务管理器，像大多数主要的Linux发行版一样，在CentOS  7中，init守护进程被Systemd取代。systemd的主要功能之一是管理Linux系统中的服务、设备、挂载点、套接字和其他实体。这些由systemd管理的实体中的每一个都被称为一个单元。每个单元由位于下列目录之一的单元文件(配置文件)定义。

## 相关的几个路径

| 路径                     | 描述                                                         |
| :----------------------- | ------------------------------------------------------------ |
| /usr/lib/systemd/system/ | 随已安装的软件包一起分发的单元文件。不要在此位置修改单位文件。 |
| /run/systemd/system/     | 在运行时动态创建的单元文件。这个目录中的更改在重新启动时丢失。 |
| /etc/systemd/system/     | 由systemctl创建的单元文件启用和定制由系统管理员创建的单元文件。 |

**您创建的所有定制单元文件都应放在 /etc/system/system/ 目录中。此目录优先于其他目录。**



***



## 单元文件的命名规则和类别

1. **单元文件命名规则：**

   *unit_name.unit_type*

2. **单元文件的类别**

   | 类别      | 描述                   |
   | --------- | ---------------------- |
   | device    | 设备单元               |
   | service   | 系统服务               |
   | socket    | 用于进程间通信的套接字 |
   | swap      | 交换文件或设备         |
   | target    | 一组单元               |
   | timer     | 系统计时器             |
   | snapshot  | systemd管理器的快照    |
   | mount     | 挂载点                 |
   | slice     | 管理系统进程的单元组   |
   | path      | 文件或目录             |
   | automount | 自动挂载点             |
   | scpoe     | 外部创建的进程         |



***

3 . **创建 service 服务（systemd 单元）**

要创建由管理的自定义服务`systemd`，您需要创建一个定义该服务配置的单位文件。例如要创建一个名为 `MyService` 的服务，请在**/ etc / systemd / system /中**创建一个名为`MyService.service`

`# vim /etc/systemd/system/MyService`

**service服务单元文件由三部分组成：Unit，Service，和 Install 。下面是一个非常简单的单位文件的示例。**

```
[Unit]
 Description=Service description
 
[Service]
 ExecStart=path_to_executable

[Install]
 WantedBy=default.target
```

**配置完所有必要选项后，保存文件并授权。**

`＃ chmod 664 /etc/systemd/system/MyService.service`

**重新加载所有单元文件，以便 systemd 了解新服务**

`# systemctl daemon-reload`

**最后运行 service 服务**

`# systemctl start MyService.service`

***

4. **配置文件说明**

**Unit 部分**
以下是 Unit 部分中指定的主要参数 

| 项目          | 说明                                                         |
| ------------- | ------------------------------------------------------------ |
| Description   | 单位的简短说明                                               |
| Documentation | 指向单元文档的URI列表                                        |
| Requires      | 必须与当前单元一起启动的单元列表。如果这些单元中的任何一个均无法启动，则当前单元将不会被激活（依赖）。 |
| Wants         | 与Requires指令相似，但区别在于即使依赖的单元无法启动，当前单元也会被激活。 |
| Before        | 当前单元之前无法启动的单元列表                               |
| After         | 当前单元只能在此处列出的单元之后启动                         |
| Conflicts     | 列出不能与当前单元同时运行的单元                             |

***

**Service 部分**

service部分的一些常见参数

| 项目          | 说明                                                         |
| ------------- | ------------------------------------------------------------ |
| Type          | 定义单元的启动类型，可以是以下值之一：<br>**Simple**: 这是默认设置。服务的主要过程是使用ExecStart启动的过程。<br>**Forking**: 以ExecStart开始的进程产生一个新的子进程，该子进程成为主进程，并且在启动完成后终止父进程。<br>**Onehot**: 与简单类似，但是systemd在继续其他单元之前等待进程退出。<br>**Dbus**: 类似于简单，但是systemd等待进程在dbus上取一个名字。<br>**Notify**: 类似于简单的Systemd，在继续其他单元之前，它将等待过程通知。<br>**Idle**: 类似于简单，但服务将在所有其他作业完成后才能运行。 |
| ExecStart     | 指定要执行的启动服务的命令                                   |
| ExecStartPre  | 指定在ExecStart中指定的主进程启动之前要执行的命令            |
| ExecStartPost | 指定在ExecStart中指定的主进程完成后要执行的命令              |
| ExecStop      | 指定停止服务时要执行的命令                                   |
| ExecReload    | 指定重新启动服务时要执行的命令                               |
| Restart       | 指定何时自动重启服务。取值为:always、on-success、on-failure、on-abnormal、on-abort或on-watchdog |

***

**Install 部分**

Install 部分提供使用 `systemctl` 命令启用或禁用单元所需的信息。常见的选项有：

| 选项       | 描述                                                         |
| ---------- | ------------------------------------------------------------ |
| RequiredBy | 需要单元的单元列表。这个单元的符号链接是在所列单元的.requires目录中创建的 |
| WantedBy   | 指定应在其下启动服务的目标列表。在列出的目标的.wants目录中创建了这个单元的符号链接 |



***



## 使用 `systemctl` 管理服务

**systemctl** 是可用于控制和管理systemd中的服务的命令行工具。下面是一些用于服务管理的重要`systemctl` 命令。



### 列出服务单元和单元文件

- 列出所有已加载的单元

  `# systemctl list-units`

- 仅列出服务类型的单位

  `# systemctl list-units -t service`

- 列出服务类型的所有已安装单元文件

  `# systemctl list-unit-files -t service`

- 您可以使用该 `--state` 选项按设备状态过滤输出。以下命令列出了所有已启用的服务。

  `# systemctl list-unit-files --state enabled`

  注意：**list-units** 和 **list-unit-files** 的区别是 list-unit 仅显示已加载的单元，而 list-unit-files 显示系统上已安装的所有单元文件。

  

### 启动和停止服务

- 启动服务

  `# systemctl start service_name.service`

- 停止服务

  `# systemctl stop service_name.service`

  

### 重新启动和重新加载服务

- **重新启动**选项将重新启动运行的服务。如果该服务未运行，它将被启动。

  `# systemctl restart service_name.service`

- 如果想只有在服务运行时才重新启动该服务，请使用**try-restart**选项。

  `# systemctl try-restart service_name.service`

- 重新加载服务的配置文件

  `# systemctl reload service_name.service`



### 设置服务开机启动和禁止

可以使用systemctl命令的enable或disable选项启用或禁用单元。启用单元时，将在单元文件的`Install`部分中指定的各个位置创建启用的符号链接。禁用设备将删除在启用该设备时创建的符号链接。

`# systemctl enable service_name.service`

`# systemctl disable service_name.service`



### 重新加载单位文件

每当您对单元文件进行任何更改时，都需要通过执行 **daemon-reload**（重新加载所有单元文件）让 `systemd` 知道。

`# systemctl daemon-reload`



***



## 修改系统服务

安装包附带的单元文件存储在/usr/lib/systemd/system/中。这个目录下的单元文件不应该被直接修改，因为当你更新包时，这些更改将会丢失。推荐的方法是首先将单元文件复制到/etc/systemd/system/中，然后在该位置进行更改。/etc/systemd/system/中的单元文件优先于/usr/lib/systemd/system/中的单元文件，因此原始的单元文件将被覆盖。



