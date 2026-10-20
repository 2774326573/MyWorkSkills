---
name: nodeflow-engineer
description: 设计节点式流程编辑器、Orchestrator、执行器、节点类型与运行时 ABI，适用于 C++/Qt 的工业编排与视觉工具链接入。
---
# NodeFlow Engineer

## 系统分层
UI Editor（视图、拖拽、配置）与 Graph Model（节点、端口、边）分离；Graph Validator 校验静态合同；Orchestrator 安排执行；Runtime/Adapter 执行设备与算法；Persistence 保存版本化配置。

## 节点契约
定义 node_type、版本、input/output ports、数据类型（标量、矩阵、图像帧、bundle）、参数 schema、允许空值、线程要求、超时、错误与取消语义。节点的视觉外观不得等同运行语义。

## 流程执行
1. 检查依赖图、循环与分支；无环流程可拓扑调度，有循环需显式 Loop/条件/停止限制。
2. 对并发节点维护 run_id、node_instance_id 和 generation，防止晚到结果覆盖新流程。
3. 端口类型转换只能通过显式规则，禁止静默数据丢失。
4. 设备动作节点须具备等待确认、超时、取消和物理安全互锁；NoResult 与失败节点分流。
5. Workflow 保存图结构、参数版本、位置与边信息；加载时做 schema migration、缺失插件报告和配置校验。
6. 编辑授权与执行授权、项目资源权限区分处理；不能把 UI 禁用等同安全或许可证 enforcement。

## 与宿主的关系
先明确 ABI 版本、插件所有权、DLL 依赖、图像内存生命周期及卸载顺序。没有所有权/授权不得将个人或第三方模块代码复制进其他项目。

## 交付
图 JSON 示例、节点契约表、调度时序、失败恢复策略、ABI 兼容矩阵和基本运行测试：加载、启动、取消、异常、重启、版本迁移。
