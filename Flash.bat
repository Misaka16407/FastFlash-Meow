@echo off
chcp 65001 >nul
title GSI刷机脚本

:: 显示脚本说明
echo ========================================
echo          GSI刷机脚本 - 版本1.0
echo ========================================
echo 这是为了加速刷平板而写的脚本
echo 请确保:
echo 1. 已打开平板的USB调试(ADB)功能
echo 2. 已授权此电脑的ADB连接
echo 3. 该文件夹下或环境变量中有ADB和fastboot工具
echo 4. 镜像文件小于等于system分区大小
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
echo 确认开始刷机吗？这将清除用户数据！(Y/N)
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
echo 开始刷入系统镜像...
fastboot flash system "%a%"

if %errorlevel% neq 0 (
    echo 错误: 刷入系统镜像失败
    pause
    exit /b 1
)

echo 系统镜像刷入成功
echo.
echo 清除用户数据...
fastboot erase userdata

echo.
echo 重启设备...
fastboot reboot

echo.
echo 刷机已完成，等待设备启动...
echo 设备启动后，将自动重置网络连通性测试服务器
echo.

:: 等待设备启动并重新连接ADB
set "adb_restored=0"
for /l %%i in (1,1,60) do (
    timeout /t 10 >nul
    adb devices | find "device" >nul
    if not errorlevel 1 (
        set "adb_restored=1"
        echo ADB连接已恢复
        goto :adb_ready
    )
)

if %adb_restored% equ 0 (
    echo 警告: 无法自动恢复ADB连接，请手动确认设备已启动并开启USB调试
    set /p "continue=设备已启动并开启USB调试了吗？(Y/N): "
    if /i not "%continue%"=="Y" (
        echo 操作已取消
        pause
        exit /b 0
    )
)

:adb_ready
echo.
echo 正在重置网络连通性测试服务器...
adb shell settings delete global captive_portal_https_url
adb shell settings delete global captive_portal_http_url
adb shell settings put global captive_portal_https_url https://connect.rom.miui.com/generate_204
adb shell settings put global captive_portal_http_url http://connect.rom.miui.com/generate_204

echo.
echo 网络连通性测试服务器已重置
echo 建议重启WiFi以使更改生效
echo.
echo 所有操作已完成！
echo.
pause
exit /b 0