#!/bin/bash

# 询问用户输入公司名称
read -p "请输入公司名称（纯英文小写字母，不允许用-连接）: " company_name
while [[ ! "$company_name" =~ ^[a-z]+$ ]]; do
    read -p "输入无效，请重新输入公司名称（纯英文小写字母）: " company_name
done

# 询问用户输入父项目名称（可选）
read -p "请输入父项目名称（纯英文小写字母，不允许用-连接，可以为空，直接回车即可）: " parent_name
while [[ -n "$parent_name" ]] && [[ ! "$parent_name" =~ ^[a-z]+$ ]]; do
    read -p "输入无效，请重新输入父项目名称（纯英文小写字母，或留空直接回车）: " parent_name
done

# 询问用户输入项目名称
read -p "请输入项目名称（纯英文小写字母，不允许用-连接）: " project_name
while [[ ! "$project_name" =~ ^[a-z]+$ ]]; do
    read -p "输入无效，请重新输入项目名称（纯英文小写字母）: " project_name
done

# 生成的项目目录名：有父项目则为 父项目名-项目名-service，否则为 项目名-service
if [[ -n "$parent_name" ]]; then
    output_root="${parent_name}-${project_name}-service"
else
    output_root="${project_name}-service"
fi

# pom 中 <artifactId> / <module> 前缀：有父项目为 父-子，否则为项目名（与目录名后缀规则一致）
if [[ -n "$parent_name" ]]; then
    artifact_slug="${parent_name}-${project_name}"
else
    artifact_slug="${project_name}"
fi

# 定义克隆的固定目录
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac 的固定目录
    clone_dir="/Users/$(whoami)/Downloads/example-service"
else
    # Windows 的固定目录（假设使用 Git Bash 或 WSL）
    clone_dir="/c/Users/$(whoami)/Downloads/example-service"
fi

clone_url="https://github.com/superthem/example-service.git"

# 准备模板：若本地已有非空模板目录则询问
if [[ -d "$clone_dir" ]] && [[ -n "$(ls -A "$clone_dir" 2>/dev/null)" ]]; then
    echo "检测到本地已存在模板目录（非空）：$clone_dir"
    read -p "是否直接使用该本地模板？[Y/n]: " use_local_tpl
    if [[ "$use_local_tpl" =~ ^[Nn]$ ]]; then
        rm -rf "$clone_dir"
        git clone "$clone_url" "$clone_dir" || {
            echo "重新克隆模板失败，请检查网络或仓库地址。"
            exit 1
        }
    else
        echo "将使用本地模板目录。"
    fi
else
    git clone "$clone_url" "$clone_dir" || {
        echo "克隆代码失败，请检查网络或仓库地址。"
        exit 1
    }
fi

if [[ ! -d "$clone_dir" ]] || [[ -z "$(ls -A "$clone_dir" 2>/dev/null)" ]]; then
    echo "模板目录不可用（不存在或为空）。"
    exit 1
fi

# 复制到当前目录并重命名
cp -r "$clone_dir" "./${output_root}"

# 遍历所有文件，只对文本文件替换内容（排除二进制文件）
find "./${output_root}" -type f | while read -r file; do
    # 使用 file 命令检查是否为文本文件，排除二进制文件
    if file "$file" | grep -qE "(text|ASCII|UTF-8|empty)"; then
        # 使用 LC_ALL=C 避免编码问题，2>/dev/null 忽略错误
        # macOS 上 sed -i 需要加 '' 参数
        if [[ "$OSTYPE" == "darwin"* ]]; then
            LC_ALL=C sed -i '' "s/exampleaaa/${company_name}/g" "$file" 2>/dev/null
            LC_ALL=C sed -i '' "s|<artifactId>exampleeee|<artifactId>${artifact_slug}|g" "$file" 2>/dev/null
            LC_ALL=C sed -i '' "s|<module>exampleeee|<module>${artifact_slug}|g" "$file" 2>/dev/null
            LC_ALL=C sed -i '' "s/exampleeee-api/${artifact_slug}-api/g" "$file" 2>/dev/null
            LC_ALL=C sed -i '' "s/exampleeee-server/${artifact_slug}-server/g" "$file" 2>/dev/null
            LC_ALL=C sed -i '' "s/exampleeee/${project_name}/g" "$file" 2>/dev/null
        else
            LC_ALL=C sed -i "s/exampleaaa/${company_name}/g" "$file" 2>/dev/null
            LC_ALL=C sed -i "s|<artifactId>exampleeee|<artifactId>${artifact_slug}|g" "$file" 2>/dev/null
            LC_ALL=C sed -i "s|<module>exampleeee|<module>${artifact_slug}|g" "$file" 2>/dev/null
            LC_ALL=C sed -i "s/exampleeee-api/${artifact_slug}-api/g" "$file" 2>/dev/null
            LC_ALL=C sed -i "s/exampleeee-server/${artifact_slug}-server/g" "$file" 2>/dev/null
            LC_ALL=C sed -i "s/exampleeee/${project_name}/g" "$file" 2>/dev/null
        fi
    fi
done

# 遍历所有目录，重命名目录（需要多次遍历直到没有更多匹配）
# 先处理 exampleaaa
while true; do
    dirs_to_rename=$(find "./${output_root}" -depth -type d | grep "exampleaaa" || true)
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
    dirs_to_rename=$(find "./${output_root}" -depth -type d | grep "exampleeee" || true)
    if [ -z "$dirs_to_rename" ]; then
        break
    fi
    echo "$dirs_to_rename" | while read -r dir; do
        if [[ "$dir" == *"exampleeee"* ]]; then
            new_dir=$(echo "$dir" | sed "s/exampleeee-api/${artifact_slug}-api/g; s/exampleeee-server/${artifact_slug}-server/g; s/exampleeee/${project_name}/g")
            if [ "$dir" != "$new_dir" ]; then
                mv "$dir" "$new_dir" 2>/dev/null || true
            fi
        fi
    done
done

# 遍历所有文件，重命名文件名中包含变量的文件
find "./${output_root}" -type f -name "*exampleaaa*" | while read -r file; do
    dir=$(dirname "$file")
    filename=$(basename "$file")
    new_filename=$(echo "$filename" | sed "s/exampleaaa/${company_name}/g")
    mv "$file" "$dir/$new_filename"
done

find "./${output_root}" -type f -name "*exampleeee*" | while read -r file; do
    dir=$(dirname "$file")
    filename=$(basename "$file")
    new_filename=$(echo "$filename" | sed "s/exampleeee-api/${artifact_slug}-api/g; s/exampleeee-server/${artifact_slug}-server/g; s/exampleeee/${project_name}/g")
    mv "$file" "$dir/$new_filename"
done

echo "脚本执行完成！项目已创建为 ${output_root}。"
