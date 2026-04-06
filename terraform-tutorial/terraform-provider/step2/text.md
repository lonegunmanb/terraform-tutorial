# 第二步：练习与测验

现在来检验你对 Provider 概念的理解。

## 打开练习文件

```bash
cd /root/workspace/step2
cat exercises.tf
```

文件中有三道练习题，每道题都需要你将 "____" 替换为正确答案：

1. AWS Provider 的源地址是什么？
2. 资源类型 google_compute_instance 对应的 Provider 本地名称是什么？
3. hashicorp/aws 的完全限定源地址是什么？

## 编辑文件

用编辑器（左侧面板）打开 /root/workspace/step2/exercises.tf，将三个 "____" 替换为你的答案。

你也可以使用 sed 命令快速替换。例如，练习 1 的答案如果是 xxx/yyy：

```bash
sed -i 's|aws_provider_source = "____"|aws_provider_source = "xxx/yyy"|' exercises.tf
```

## 提示

- 练习 1：想想 AWS 是由哪个组织发布的，type 就是云平台名称
- 练习 2：Terraform 取资源类型名中第一个下划线之前的部分
- 练习 3：省略 hostname 时，默认值是什么？把它加在前面

## 验证答案

完成编辑后，运行测试验证：

```bash
terraform test
```

如果所有答案正确，你会看到：

```
Success! 1 passed, 0 failed.
```

如果有错误，terraform test 会告诉你哪道题答错了，以及正确答案的提示。根据提示修改后重新测试即可。

> 这三个概念是理解 Terraform Provider 系统的基础。掌握了源地址的结构，你就能正确配置任何 Provider 的 required_providers 声明。

✅ 所有测试通过后，本实验完成！
