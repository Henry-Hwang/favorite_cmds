#!/bin/bash
# =================配置区域=================
# 根据您之前的输出，您的网卡名称是 enp12s0
INTERFACE="enp12s0"
# =========================================

# 1. 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  exec sudo -E bash "$0" "$@"
fi

# 2. 检查网卡是否存在
if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
  echo "错误: 找不到网卡 $INTERFACE"
  exit 1
fi

# 3. 生成随机 MAC 地址
# 说明: 第一个字节固定为 02 (二进制 ....0010)
# 这样做是为了设置 "Locally Administered" 位，防止与正规厂商的 OUI 冲突，
# 并确保不是广播/多播地址。
NEW_MAC=$(printf '02:%02x:%02x:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

# 获取旧 MAC 用于显示
OLD_MAC=$(cat /sys/class/net/$INTERFACE/address)

echo "正在修改 $INTERFACE ..."
echo "旧 MAC: $OLD_MAC"
echo "目标 MAC: $NEW_MAC"

# 4. 执行修改 (关闭 -> 修改 -> 开启)
ip link set dev "$INTERFACE" down
if [ $? -ne 0 ]; then echo "无法关闭网卡"; exit 1; fi

ip link set dev "$INTERFACE" address "$NEW_MAC"
if [ $? -ne 0 ]; then 
    echo "修改 MAC 失败! 可能是硬件不支持或参数错误。"
    ip link set dev "$INTERFACE" up
    exit 1
fi

ip link set dev "$INTERFACE" up
if [ $? -ne 0 ]; then echo "无法重新启动网卡"; exit 1; fi

# 5. 验证结果
CURRENT_MAC=$(cat /sys/class/net/$INTERFACE/address)
echo "--------------------------------"
if [ "$CURRENT_MAC" == "$NEW_MAC" ]; then
    echo "✅ 成功! 当前 MAC 地址: $CURRENT_MAC"
else
    echo "❌ 失败。当前 MAC 仍为: $CURRENT_MAC"
fi

