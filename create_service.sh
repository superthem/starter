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

# 遍历所有文件，只对文本文件替换内容（排除二进制文件）
find "./${project_name}-service" -type f | while read -r file; do
    # 使用 file 命令检查是否为文本文件，排除二进制文件
    if file "$file" | grep -qE "(text|ASCII|UTF-8|empty)"; then
        # 使用 LC_ALL=C 避免编码问题，2>/dev/null 忽略错误
        # macOS 上 sed -i 需要加 '' 参数
        if [[ "$OSTYPE" == "darwin"* ]]; then
            LC_ALL=C sed -i '' "s/exampleaaa/${company_name}/g" "$file" 2>/dev/null
            LC_ALL=C sed -i '' "s/exampleeee/${project_name}/g" "$file" 2>/dev/null
        else
            LC_ALL=C sed -i "s/exampleaaa/${company_name}/g" "$file" 2>/dev/null
            LC_ALL=C sed -i "s/exampleeee/${project_name}/g" "$file" 2>/dev/null
        fi
    fi
done

# 遍历所有目录，重命名目录（需要多次遍历直到没有更多匹配）
# 先处理 exampleaaa
while true; do
    dirs_to_rename=$(find "./${project_name}-service" -depth -type d | grep "exampleaaa" || true)
    if [ -z "$dirs_to_rename" ]; then
        break
    fi
    echo "$dirs_to_rename" | while read -r dir; do
        if [[ "$dir" == *"exampleaaa"* ]]; then
            new_dir=$(echo "$dir" | sed "s/exampleaaa/${company_name}/g")
            if [ "$dir" != "$new_dir" ]; then
                mv "$dir" "$new_dir" 2>/dev/null || true
            fi
        fi
    done
done

# 再处理 exampleeee
while true; do
    dirs_to_rename=$(find "./${project_name}-service" -depth -type d | grep "exampleeee" || true)
    if [ -z "$dirs_to_rename" ]; then
        break
    fi
    echo "$dirs_to_rename" | while read -r dir; do
        if [[ "$dir" == *"exampleeee"* ]]; then
            new_dir=$(echo "$dir" | sed "s/exampleeee/${project_name}/g")
            if [ "$dir" != "$new_dir" ]; then
                mv "$dir" "$new_dir" 2>/dev/null || true
            fi
        fi
    done
done

# 遍历所有文件，重命名文件名中包含变量的文件
find "./${project_name}-service" -type f -name "*exampleaaa*" | while read -r file; do
    dir=$(dirname "$file")
    filename=$(basename "$file")
    new_filename=$(echo "$filename" | sed "s/exampleaaa/${company_name}/g")
    mv "$file" "$dir/$new_filename"
done

find "./${project_name}-service" -type f -name "*exampleeee*" | while read -r file; do
    dir=$(dirname "$file")
    filename=$(basename "$file")
    new_filename=$(echo "$filename" | sed "s/exampleeee/${project_name}/g")
    mv "$file" "$dir/$new_filename"
done

echo "脚本执行完成！项目已创建为 ${project_name}-service。"

# 询问用户是否删除临时文件
read -p "是否删除临时文件（克隆的固定目录）？[y/N]: " delete_temp
if [[ "$delete_temp" =~ ^[Yy]$ ]]; then
    rm -rf "$clone_dir"
    echo "临时文件已删除。"
else
    echo "保留临时文件。"
fi
