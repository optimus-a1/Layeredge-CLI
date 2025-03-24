本脚本来自https://github.com/TheyCallMeSecond/Layeredge-CLI-manager/blob/main/layeredge-cli.sh的翻译，请自行查找是否有后门程序

推荐代码：flSA6qDC

---

# 简介  
**LayerEdge Light Node 管理器** 简化了在 Ubuntu 服务器上设置、配置和管理 LayerEdge 轻节点的流程。该脚本提供了一个交互式菜单系统，引导您完成安装过程，并提供后续的节点管理功能。

---

# 功能特色  

- 彩色交互式菜单界面  
- 所有必需组件的一键完整安装流程  
- 服务管理（启动、停止、重启、查看状态）  
- 日志与监控工具，用于排查故障  
- 配置管理（更新私钥、环境变量等）  
- 指导您如何将节点连接到 LayerEdge Dashboard  

---

# 前置条件  

- Ubuntu 24.04.2 LTS（或兼容的 Linux 发行版）  
- 拥有 root 权限或 sudo 权限  
- 可连接互联网  

---

# 快速开始指南  

## 安装步骤  

1. 下载脚本：  
   ```bash  


   wget -O layeredge-cli.sh https://raw.githubusercontent.com/optimus-a1/Layeredge-CLI/main/layeredge-cli.sh  
   ```

2. 赋予脚本可执行权限：  
   ```bash  
   chmod +x layeredge-cli.sh  
   ```

3. 使用 sudo 运行脚本：  
   ```bash  
   sudo ./layeredge-cli.sh  
   ```

4. 在菜单中选择 `选项 1` 进行完整安装  

---

# 安装完成后  

- 访问 LayerEdge 仪表盘： [dashboard.layeredge.io](https://dashboard.layeredge.io)  
- 连接你的钱包  
- 绑定你的 CLI 节点公钥  
- 实时查看节点状态和赚取的积分  

---

# 菜单选项说明  

### 安装相关  

- **完整安装**：安装所有必要组件  
- **更新代码仓库**：从 GitHub 拉取最新代码  
- **构建/重建服务**：编译 Merkle 服务与 Light Node  

### 服务管理  

- **启动服务**：启动 LayerEdge 节点相关服务  
- **停止服务**：停止所有服务  
- **重启服务**：重新启动服务  
- **查看服务状态**：当前服务运行状态概览  

### 监控与配置  

- **查看节点状态**：当前节点运行状态  
- **查看日志**：访问日志文件，进行故障排查  
- **更新私钥**：更换节点私钥  
- **仪表盘连接信息**：如何连接 LayerEdge 仪表盘的说明  

---

# 系统组件  

LayerEdge Light Node 由以下两个核心组件组成：

- **Merkle 服务**：一个基于 Rust 的服务，用于生成零知识证明  
- **轻节点（Light Node）**：一个基于 Go 的应用程序，用于与 LayerEdge 网络通信  

---

# 脚本安装依赖  

- Go（版本 ≥ 1.18）  
- Rust（版本 ≥ 1.81.0）  
- Risc0 工具链  
- 系统依赖（如 git、curl、build-essential 等）  

---

# 目录结构  

```plaintext
~/light-node/              # 主目录  
├── risc0-merkle-service/  # Merkle 服务组件  
├── .env                   # 环境配置文件  
└── light-node             # 编译后的轻节点程序  

/var/log/layeredge/        # 日志目录  
├── merkle.log             # Merkle 服务日志  
├── merkle-error.log       # Merkle 服务错误日志  
├── node.log               # 轻节点日志  
└── node-error.log         # 轻节点错误日志  

/etc/systemd/system/       # systemd 服务定义  
├── layeredge-merkle.service  
└── layeredge-node.service  
```

---

# 故障排查  

如遇到问题：

- 使用菜单中的“查看日志”功能查看详细信息  
- 确认私钥是否设置正确  
- 确保 Merkle 服务在轻节点启动前已运行  
- 检查网络是否能连接到 LayerEdge gRPC 节点  

---

# 安全建议  

- 请妥善保管您的私钥，切勿泄露  
- 定期使用脚本更新节点代码  
- 按照常规的服务器安全操作规范进行配置与维护  

---

# 参与贡献  

欢迎大家提交 PR 一起完善脚本！  

---

# 开源许可  

本项目基于 MIT 许可证发布，详情请查看仓库中的 LICENSE 文件。  

---

# 鸣谢  

- 感谢 LayerEdge 团队提供的优质文档支持  
- 感谢所有参与开发与维护该管理脚本的贡献者  

---

# 免责声明  

本项目为非官方 LayerEdge 节点管理工具。请参考官方文档获取权威信息。  

---

