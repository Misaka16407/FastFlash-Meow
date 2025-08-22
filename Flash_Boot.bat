@echo off
chcp 65001 >nul
title Boot刷机脚本

:: 显示脚本说明
echo ========================================
echo          Boot刷机脚本 - 版本1.0
echo ========================================
echo 这是为了加速刷平板而写的脚本
echo 请确保:
echo 1. 已打开平板的USB调试(ADB)功能
echo 2. 已授权此电脑的ADB连接
echo 3. 该文件夹下或环境变量中有ADB和fastboot工具
echo 4. 镜像文件小于等于Boot分区大小
echo ========================================

:: 检查ADB和fastboot工具是否可用
where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: 未找到ADB工具，请确保ADB在PATH环境变量中或当前目录下
    pause
    exit /b 1
)

where fastboot >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: 未找到fastboot工具，请确保fastboot在PATH环境变量中或当前目录下
    pause
    exit /b 1
)

:: 检查设备ADB连接
echo 正在检查ADB设备连接...
adb devices | find "device" >nul
if %errorlevel% neq 0 (
    echo 错误: 未检测到已连接的ADB设备
    echo 请确保:
    echo 1. USB调试已开启
    echo 2. 已授权此电脑
    echo 3. USB线已连接
    pause
    exit /b 1
)

echo ADB设备连接正常
echo.

:: 获取镜像文件路径
:input_loop
set /p "a=请拖入镜像文件: "
if "%a%"=="" (
    echo 错误：未输入任何内容，请重新输入
    goto input_loop
)

:: 验证文件类型和存在性
for %%i in ("%a%") do (
    if /i not "%%~xi"==".img" if /i not "%%~xi"==".bin" (
        echo 错误：文件类型必须是 .img 或 .bin
        set "a="
        goto input_loop
    )
    
    if not exist "%%i" (
        echo 错误：文件不存在，请重新输入
        set "a="
        goto input_loop
    )
    
    :: 显示文件信息
    echo 已选择文件: %%~nxi
    echo 文件大小: %%~zi 字节
)

echo.
echo 确认开始刷机吗？错误的Boot镜像会导致系统无法启动！(Y/N)
choice /c YN /n
if %errorlevel% equ 2 (
    echo 操作已取消
    pause
    exit /b 0
)

echo.
echo 正在重启到FASTBOOT模式...
adb reboot bootloader
echo 等待设备进入FASTBOOT模式...

:: 等待设备进入fastboot模式并检查连接
set "fastboot_connected=0"
for /l %%i in (1,1,30) do (
    timeout /t 2 >nul
    fastboot devices | find "fastboot" >nul
    if not errorlevel 1 (
        set "fastboot_connected=1"
        echo FASTBOOT设备连接正常
        goto :fastboot_ready
    )
)

if %fastboot_connected% equ 0 (
    echo 错误: 无法检测到FASTBOOT设备连接
    echo 请检查设备是否已进入FASTBOOT模式
    pause
    exit /b 1
)

:fastboot_ready
echo.
echo 开始刷入Boot镜像...
fastboot flash system "%a%"

if %errorlevel% neq 0 (
    echo 错误: 刷入Boot镜像失败
    pause
    exit /b 1
)

echo Boot镜像刷入成功
echo.

echo 重启设备...
fastboot reboot

echo.
echo 所有操作已完成！
echo.
pause
exit /b 0