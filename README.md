<div align="center">
<img width="284" height="147" alt="DE-CPOS-Logo" src="https://github.com/user-attachments/assets/1d0f84de-c196-4447-a26e-276853f3f209" />

<h1 align="center">DE-CPOS</h1>
[![Deep Learning Corporation](https://img.shields.io/badge/Deep%20Learning%20Corporation-官方网站-2ea44f?style=flat-square)](https://image.cursorhub.org/user-upload/1768915970177-a1bab351-c8d7-4b8a-97d0-4679bb6942e0.html)


# 简介
DE-CPOS (Deep Learning Command Prompt Operating System) 是 Omege UOS 操作系统的前身。
编写语言全部由汇编 Assembly(Netwide Assembler)进行编写
此操作系统类似 MS-DOS (Microsoft Disk Operating System)

# 贡献
OmegeUOS (BiliBili UP) (https://space.bilibili.com/3493294325631048?spm_id_from=333.1007.0.0)
杜雨本雨 (BiliBili UP) (https://space.bilibili.com/3546734724647772)

# 编译与运行
如果要编译，你需要安装：
-Windows 环境(编译是.cmd Windows 命令脚本)
-Netwide Assembler (nasm，代码由 nasm 编写)
如果要运行，你需要安装：
-Windows 环境 (以下载 DOSBox)
-DOSBox (可以测试无图形化界面的操作系统,QEMU 也可以)
# 许可
此操作系统 (DE-CPOS) 开源许可证为 MIT License (麻省理工学院许可)

# 启动
本操作系统由 BIOS 启动，启动过程如下：
计算机加电 -> BIOS -> 启动设备 -> DE-CPOS
BIOS 启动过程如下：
1. 上电自检 (POST)
2. 初始化硬件
3. 查找启动设备 (软盘/硬盘/USB)
4. 读取第一个扇区(512字节)到内存 0x7C00
5. 跳转到 0x7C00 执行
# 架构
DE-CPOS 架构为 16 位实模式，信息如下：
模式: 16位实模式 (Real Mode)
CPU: 兼容 Intel 8086 及以上
内存: 常规内存 < 1MB
寻址: 20位地址线 (segment:offset)
最大内存: 640KB + 384KB (保留)

# 贡献
如果你想加入我们，可以加入 QQ 群，群号为：1026732566 (名称为 Omege UOS)
@ 群主表明来意
如果加入了我们，你可以：
-贡献代码
-贡献资料信息
......

# 致谢
谢谢你阅读我们 DE-CPOS 操作系统的 README！
