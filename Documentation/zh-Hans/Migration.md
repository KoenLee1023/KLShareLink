# KLShareLink 迁移

> <span lang="zh-CN">[English](../../README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

先用测试用例记录旧解析器对显式 URL、多个候选、提供方归属、被拒绝目标和空输入的行为。再把域名与旧版标记迁入配置，通过薄适配层比较新旧结果。确认只剩预期差异，并通过包测试与接入应用的回归测试后，再删除重复解析逻辑。

## 检查清单

- [ ] 在接入应用层定义有序的 `ShareLinkProvider`，或从 JSON 解码。
- [ ] 把显式 URL 与分享文本分别传入，不要自行拼接。
- [ ] 分别处理 URL+提供方、仅 URL、仅提供方、全空四种结果。
- [ ] 真正联网前再次验证 DNS 结果与每个重定向。
- [ ] 运行 KLShareLink 包测试。
- [ ] 运行接入应用的回归测试。
- [ ] 更新 API 参考与变更记录。
