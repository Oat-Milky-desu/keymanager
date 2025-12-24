# SSH 公钥管理器

一个用于管理 VPS SSH 公钥的自动化脚本，支持从远程 JSON 配置同步公钥。

## ✨ 功能特点

- 🔄 从远程 URL 获取公钥配置
- 🔐 自动替换 `authorized_keys`，确保只有配置中的公钥有效
- 💾 更新前自动备份现有公钥
- ✅ 自动检查并安装依赖（jq）
- 🎨 彩色日志输出，操作状态一目了然

## 🚀 一键运行

在 VPS 上执行以下命令即可：

```bash
curl -sL https://ba.sh/amgt | bash
```

## 📋 公钥配置

公钥配置存储在远程 JSON 文件中，格式如下：

```json
{
  "devices": [
    {
      "name": "设备名称",
      "key": "ssh-ed25519 AAAA..."
    }
  ]
}
```

## ⚠️ 注意事项

1. **保持连接**：执行脚本后，请保持当前 SSH 连接，新开终端测试密钥登录是否正常
2. **自动备份**：脚本会自动备份原有的 `authorized_keys` 文件
3. **权限要求**：脚本需要有权限修改 `~/.ssh/authorized_keys`

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `update_ssh_keys.sh` | 主脚本文件 |
| `keys.json` | 公钥配置文件 |

## 🔗 相关链接

- 脚本地址：https://ba.sh/amgt
- 配置文件：https://ba.sh/8b2R
