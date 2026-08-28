# KLShareLink 演示应用

> <span lang="zh-CN">[English](../en/README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLShareLink 是一个不含第三方运行时依赖、同步且确定性的 Swift 包。它返回通过 scheme 与 host 过滤的 HTTP(S) URL 及可选的提供方名称。

## Link Inspector

通过过滤的显式 URL 优先 · 按文本出现顺序检测 HTTP(S) 候选 · 优先选择命中配置提供方的候选

## Policy Playground

优先选择命中配置提供方的候选 · 拒绝 `localhost`、`.local`、`::1` 与文档列出的直接 IPv4 范围 · 无 URL 时可报告旧版提供方，但绝不虚构目标

两个演示 App 都有独立的 `Package.swift` 和应用入口，仅依赖仓库根目录中的软件包，不会导入 wondays 的代码或资源。

只负责选择输入，不发起请求、不展开重定向、不清理跟踪参数、不持久化历史，也不替网络层完成 SSRF 防护。除 `::1` 外，其他本地或私有 IPv6 直接地址不会被过滤器拒绝。网络层必须验证解析后的地址与每次重定向目标。
