#!/bin/bash

# 询问用户输入公司名称
read -p "请输入公司名称（纯英文小写字母，不允许用-连接）: " company_name
while [[ ! "$company_name" =~ ^[a-z]+$ ]]; do
    read -p "输入无效，请重新输入公司名称（纯英文小写字母）: " company_name
done

# 询问用户输入项目名称
read -p "请输入项目名称（纯英文小写字母，不允许用-连接）: " project_name
while [[ ! "$project_name" =~ ^[a-z]+$ ]]; do
    read -p "输入无效，请重新输入项目名称（纯英文小写字母）: " project_name
done

# 定义克隆的固定目录
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac 的固定目录
    clone_dir="/Users/$(whoami)/Downloads/example-service"
else
    # Windows 的固定目录（假设使用 Git Bash 或 WSL）
    clone_dir="/c/Users/$(whoami)/Downloads/example-service"
fi

# 克隆代码到固定目录
git clone http://home.magicvector.cn:30080/common/example-service.git "$clone_dir"

# 检查克隆是否成功
if [ $? -ne 0 ]; then
    echo "克隆代码失败，请检查网络或仓库地址。"
    exit 1
fi

# 复制到当前目录并重命名
cp -r "$clone_dir" "./${project_name}-service"

# 遍历所有目录和文件，替换内容
find "./${project_name}-service" -type f -exec sed -i "s/exampleaaa/${company_name}/g" {} \;
find "./${project_name}-service" -type f -exec sed -i "s/exampleeee/${project_name}/g" {} \;

# 遍历所有目录，重命名目录
find "./${project_name}-service" -depth -type d -name "*exampleaaa*" | while read -r dir; do
    new_dir=$(echo "$dir" | sed "s/exampleaaa/${company_name}/g")
    mv "$dir" "$new_dir"
done

find "./${project_name}-service" -depth -type d -name "*exampleeee*" | while read -r dir; do
    new_dir=$(echo "$dir" | sed "s/exampleeee/${project_name}/g")
    mv "$dir" "$new_dir"
done

echo "脚本执行完成！项目已创建为 ${project_name}-service。"
