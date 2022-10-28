### 一、在mgr mysql 集群执行两个用户的权限设置.
```javascript
CREATE USER 'monitor'@'%' IDENTIFIED BY 'Monitor&@2022';
CREATE USER 'proxysql'@'%' IDENTIFIED BY 'Proxysql&@2022';
GRANT ALL PRIVILEGES ON *.* TO 'monitor'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'proxysql'@'%';
flush privileges;
```

### 二、proxysql服务器上执行,插入服务器信息.
```javascript
mysql -uadmin -padmin -h 127.0.0.1 -P6032 --prompt='Admin> '
insert into mysql_servers(hostgroup_id,hostname,port) values (10,'172.27.0.3',3306);
insert into mysql_servers(hostgroup_id,hostname,port) values (10,'172.27.0.4',3306);
insert into mysql_servers(hostgroup_id,hostname,port) values (10,'172.27.0.5',3306);
load mysql servers to runtime;
save mysql servers to disk;
select * from mysql_servers;
```

### 三、在proxysql服务器上执行，设置用户权限并写入磁盘.
```javascript
UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_username';
UPDATE global_variables SET variable_value='Monitor&@2022' WHERE variable_name='mysql-monitor_password';
load mysql variables to runtime;
save mysql variables to disk;
select * from monitor.mysql_server_connect_log;
```


### 四、在proxysql服务器上执行，设置用户权限并写入磁盘.
```javascript
UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_username';
UPDATE global_variables SET variable_value='Monitor&@2022' WHERE variable_name='mysql-monitor_password';
load mysql variables to runtime;
save mysql variables to disk;
select * from monitor.mysql_server_connect_log;
insert into mysql_users(username,password,active,default_hostgroup,transaction_persistent) values ('proxysql','Proxysql&@2022',1,10,1);
insert into mysql_group_replication_hostgroups (writer_hostgroup,backup_writer_hostgroup,reader_hostgroup,offline_hostgroup,active,max_writers,writer_is_also_reader,max_transactions_behind) values (10,20,30,40,1,1,0,100);
load mysql servers to runtime;
save mysql servers to disk;
load mysql users to runtime;
save mysql users to disk;
load mysql variables to runtime;
save mysql variables to disk;
select hostgroup_id,hostname,port,status from runtime_mysql_servers;
select hostname,port,viable_candidate,read_only,transactions_behind,error from mysql_server_group_replication_log order by time_start_us desc;
```


### 五、在proxysql服务器上执行，设置读写分离
```javascript
INSERT INTO mysql_query_rules (rule_id,active,match_digest,destination_hostgroup,apply) VALUES (1,1,'^SELECT.*FOR UPDATE$',10,1),(2,1,'^SELECT',30,1);
load mysql query rules to runtime;
save mysql query rules to disk;
```


### 五、在proxysql服务器上执行，设置读写分离
```javascript
INSERT INTO mysql_query_rules (rule_id,active,match_digest,destination_hostgroup,apply) VALUES (1,1,'^SELECT.*FOR UPDATE$',10,1),(2,1,'^SELECT',30,1);
load mysql query rules to runtime;
save mysql query rules to disk;
```


### 六、直接在服务器上登录,注意端口号是6033
```javascript
mysql -uproxysql -p'Proxysql&@2022' -h 127.0.0.1 -P6033
```
