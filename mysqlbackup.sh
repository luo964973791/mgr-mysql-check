#!/bin/bash

#执行脚本前先设置密码: mysql_config_editor set --login-path=backup --host=localhost --user=root --password

# 配置部分
BACKUP_DIR="/data/mysqlbackup"    # 备份存储目录
DATE=$(date +%Y%m%d_%H%M%S)  # 备份文件的时间戳

# 颜色设置函数
set_green() {
    echo -e "\e[01;32m$1\e[01;00m"
}

set_red() {
    echo -e "\e[01;31m$1\e[01;00m"
}

# 安装 shellcheck 的函数
install_shellcheck() {
    set_green "shellcheck not found, attempting to download and install..."
    wget -qO- "https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz" | tar -xJv -C /tmp/
    if cp "/tmp/shellcheck-stable/shellcheck" /usr/bin/; then
        set_green "shellcheck installed successfully."
        rm -rf /tmp/shellcheck-stable/
    else
        set_red "shellcheck installation failed."
        exit 1
    fi
}

# 运行 shellcheck 进行语法检查
run_shellcheck() {
    local script_name="$1"
    if command -v shellcheck > /dev/null; then
        if shellcheck "$script_name"; then
            set_green "Syntax is correct"
        else
            set_red "Syntax error"
            exit 1
        fi
    else
        install_shellcheck
    fi
}

# 创建备份目录
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR" && set_green "Backup directory created at $BACKUP_DIR"
    else
        set_green "Backup directory already exists at $BACKUP_DIR"
    fi
}

# 备份单个 MySQL 数据库
backup_single_database() {
    local db_name="$1"
    set_green "Backing up database: $db_name"
    
    # 直接在 if 语句中运行 mysqldump 命令并检查其返回值
    if mysqldump --login-path=backup "$db_name" > "$BACKUP_DIR/$db_name-$DATE.sql"; then
        set_green "Backup completed for database: $db_name"
    else
        set_red "Backup failed for database: $db_name"
        exit 1
    fi
}

# 获取所有数据库并逐一备份
backup_all_databases_individually() {
    # 获取所有数据库名称，排除系统数据库
    databases=$(mysql --login-path=backup -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|sys)")

    for db in $databases; do
        backup_single_database "$db"
    done
}

# 删除超过7天的旧备份文件
delete_old_backups() {
    set_green "Deleting backups older than 7 days..."
    
    # 直接在 if 语句中运行 find 命令并检查其返回值
    if find "$BACKUP_DIR" -name "*.sql" -type f -mtime +7 -exec rm -f {} \;; then
        set_green "Old backups deleted successfully."
    else
        set_red "Failed to delete old backups."
        exit 1
    fi
}

# 主函数
main() {
    run_shellcheck "$(basename "$0")"   # 检查脚本语法
    create_backup_dir                   # 创建备份目录
    backup_all_databases_individually    # 逐个备份所有数据库
    delete_old_backups                  # 删除超过7天的备份
}

# 执行主函数
main
