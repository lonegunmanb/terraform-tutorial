# 第四步：terraform get 与 terraform graph

## 查看当前的模块目录

工作目录中预置了一个本地模块 modules/greet：

```bash
cd /root/workspace
ls modules/greet/
cat modules/greet/main.tf
```

这个模块接收一个 name 变量，输出一条问候消息。此时 main.tf 还没有引用它。

## 在 main.tf 中添加 module 块

向 main.tf 尾部追加一个 module 块引用这个本地模块：

```bash
cat >> main.tf <<'EOF'

module "greeting" {
  source = "./modules/greet"
  name   = local.name_prefix
}
EOF
```

## 运行 terraform get

现在运行 terraform get 安装新增的模块：

```bash
terraform get
```

你会看到类似输出：

```text
- greeting in modules/greet
```

这表明 Terraform 已经将本地模块安装到 .terraform/modules/ 目录中。

如果模块有更新版本可用，加 -update 强制刷新：

```bash
terraform get -update
```

## 运行 terraform graph

生成当前配置的资源依赖关系图（DOT 格式）：

```bash
terraform graph
```

输出是一个 DOT 格式的文本图，可以看到 null_resource.setup 和 null_resource.deploy 之间的依赖关系，以及 module.greeting 节点。

保存到文件以便查阅：

```bash
terraform graph > /tmp/graph.dot
cat /tmp/graph.dot
```

使用 grep 确认其中包含资源节点：

```bash
grep -E 'null_resource|module' /tmp/graph.dot
```

## 可选：安装 graphviz 渲染图片

```bash
apt-get install -y graphviz -qq && terraform graph | dot -Tpng > /tmp/graph.png && echo "graph.png 已生成" || echo "graphviz 安装失败，仅展示 DOT 文本即可"
```


## 用 -type 生成不同类型的图

terraform graph 支持通过 -type 参数生成不同阶段的依赖图：

```bash
terraform graph -type=plan
```

```bash
terraform graph -type=apply
```

对比默认输出和 -type=plan 的差异——plan 图会额外包含数据源读取节点，apply 图则侧重资源创建顺序。把两者保存下来对比：

```bash
terraform graph -type=plan > /tmp/graph-plan.dot
terraform graph -type=apply > /tmp/graph-apply.dot
diff /tmp/graph-plan.dot /tmp/graph-apply.dot | head -30
```
