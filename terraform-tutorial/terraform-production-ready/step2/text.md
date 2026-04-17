# 第二步：提取网络层和 Web 层

## 查看预备好的模块文件

我们已经为你准备好了重构后的模块文件。先看看目录结构：

```bash
find /root/stage/step2 -name "*.tf" | sort
```

两个模块——networking 和 web——分别封装了网络层和 Web 层的资源。

## 理解 moved 块

重构的关键是 moved 块。看看我们为这次重构准备的 moved 声明：

```bash
cat /root/stage/step2/moved.tf
```

每个 moved 块告诉 Terraform：旧地址的资源现在搬到了新地址。例如：

```
moved {
  from = aws_vpc.main
  to   = module.networking.aws_vpc.this
}
```

意思是：原来根模块的 aws_vpc.main 现在由 module.networking 管理，资源名改为 aws_vpc.this。Terraform 会更新状态文件里的地址，但不会销毁或重建 VPC。

注意子网的地址变化——从独立资源变成了 for_each：

```
from = aws_subnet.public_a
to   = module.networking.aws_subnet.public["10.0.1.0/24"]
```

moved 块能处理从单独命名到 for_each 键的转换。这是生产环境重构最常见的场景之一。

## 查看网络层模块

```bash
cat /root/stage/step2/modules/networking/main.tf
```

注意 for_each 的使用——以 CIDR 为 key、可用区为 value 的 map 驱动子网创建，而不是原来手写 4 个独立的 resource 块。好处：从列表中间删一个 CIDR 只销毁那一个子网，不会因下标位移触发其他子网的 destroy/recreate。

## 查看 Web 层模块

```bash
cat /root/stage/step2/modules/web/main.tf
```

三组安全组（ALB / App / Data）和 ALB 现在集中在一个模块里，引用链一目了然。

## 应用重构

复制模块文件和新的根配置到工作目录：

```bash
cp -r /root/stage/step2/modules /root/workspace/
cp /root/stage/step2/main.tf /root/workspace/
cp /root/stage/step2/moved.tf /root/workspace/
```

初始化模块（本地模块不需要网络下载）：

```bash
terraform init
```

## 验证零变更

这是最关键的一步——plan 不应该有任何 create 或 destroy：

```bash
terraform plan
```

你会看到类似：

```
Plan: 0 to add, N to change, 0 to destroy.
```

重点看：**0 to add, 0 to destroy**——没有资源被销毁或重建。少量 update in-place 是 MiniStack 模拟器的状态偏差（例如安全组的 ingress 引用），在真实 AWS 上这些也不会出现。moved 块精确完成了"搬家"。

```bash
terraform apply -auto-approve -parallelism=2
```

## 查看重构后的状态

```bash
terraform state list
```

现在资源地址带有 module 前缀：

```
module.networking.aws_vpc.this
module.networking.aws_subnet.public["10.0.1.0/24"]
module.web.aws_lb.this
module.web.aws_security_group.alb
module.web.aws_instance.app
```

谁属于哪一层，一看便知。比较一下 main.tf 的变化：

```bash
wc -l main.tf
```

网络和 Web 层的约 160 行代码被两个 module 调用块替代了。

下一步，继续提取数据层和存储层。
