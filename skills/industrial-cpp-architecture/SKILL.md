---
name: industrial-cpp-architecture
description: 为工业软件进行 C++20、Qt Widgets、插件及设备抽象的架构设计与重构。侧重线程、资源生命周期、异步安全、状态机和可测试接口。
---
# Industrial C++ Architecture

## 适用
C++20、Qt Widgets、xmake/CMake、插件、图像采集、PLC通讯、算法执行器或资源管理架构；先从实际项目构建文件与版本出发，不将 Qt6 API 强加于 Qt5 项目。

## 实施工作流
1. 读取构建入口、依赖、公共接口、对象所有权、线程创建/退出与真实调用链。画出生产者、队列、消费者和停止顺序。
2. 用模块边界拆分 UI、Application/Orchestrator、Domain、Device Adapters、Algorithm、Persistence。依赖应从业务策略指向抽象，设备 SDK 不能污染纯业务数据结构。
3. 定义 API：输入输出类型、错误语义、超时、线程亲和性、取消行为、幂等性和生命周期。
4. 优先 RAII 与确定性回收；异步回调应持有安全生命周期令牌，不得在对象析构后解引用 this。
5. 对设备调用设置超时、重连、失败计数与硬故障停止策略；不要把“发送调用成功”等同“动作实际完成”。
6. 界面线程只负责呈现；耗时识别/通讯放工作线程，通过 queued connection 或线程安全消息传输状态。

## 状态机与结果契约
- 状态：Idle、Preparing、Running、Stopping、Stopped、Faulted；每个转移定义条件、原子性、恢复/清理动作。
- 结果：检测结论 OK/NG/NoResult 与系统错误码分开表示；每周期数据带 generation/cycle id，避免上周期结果残留。
- 日志：事件时间、通道/设备 ID、周期 ID、错误码、耗时；避免泄漏敏感图像或凭据。

## 输出清单
目录/依赖关系、关键接口 C++ 签名、线程模型、状态转换表、改动迁移清单、单测和硬件仿真测试点。

## 验证
至少检查启动/停止重入、停止中重连、设备返回慢/异常、无效索引、相机断连、UI退出、并行结果乱序。未执行编译或现场运行时必须明示。
