library(ggplot2)

# for i in `find -name \*iostat`; do ts=`echo ${i##*/} | sed 's/-iostat//'`; cat $i | sed '/Linux/d' | sed '/Device/d' | sed '/^$/d' | sed 's/ \{1,\}/,/g' | sed "s/^/$ts,/" > ${i##*/}; done

# create database iostat;

# create table iostat(id int not null auto_increment, ts datetime, device varchar(32), rrqm_s decimal (10,2), wrqm_s decimal(10,2), r_s decimal(10,2), w_s decimal(10,2), rkb_s decimal(10,2), wkb_s decimal(10,2), avgrq_sz decimal (10,2), avgqu_sz decimal(10,2), await decimal(10,2), r_await decimal(10,2), w_await decimal(10,2), svctm decimal(10,2), util decimal(10,2), primary key(id)) engine=innodb;

# cp *-iostat /home/sveta/build/mysql-5.6-fb/mysql-test/var/mysqld.1/data/iostat/

# load data infile '2018_07_23_01_14_13-iostat' into table iostat fields terminated by ',' (ts, device, rrqm_s, wrqm_s, r_s, w_s, rkb_s, wkb_s, avgrq_sz, avgqu_sz, await, r_await, w_await, svctm, util);

# create procedure update_time(disks int) begin DECLARE done INT DEFAULT FALSE; declare ts_read datetime; declare c cursor for select distinct ts from iostat; DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;  open c;  update_loop: loop  fetch c into ts_read;  if done then  leave update_loop; end if;  set @sec = 1; repeat set @stmt= concat('update iostat set ts = addtime(ts, ', @sec, ') where ts = \'', ts_read, '\' limit ', disks); prepare stmt from @stmt; execute stmt; set @sec = @sec + 1; until @sec > 30 end repeat; end loop; close c; end|

# select count(distinct device) from iostat;

# call update_time(14); 

# select distinct device from iostat;

# select device from iostat where w_s = (select max(w_s) from iostat);

# select * into outfile 'sdb_test'  FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' from iostat where device='sdb' order by ts, id; 

# /home/sveta/build/mysql-5.6-fb/mysql-test/var/mysqld.1/data/iostat/sdb_test

cnames <- c("id", "ts", "device", "rrqm_s", "wrqm_s", "r_s", "w_s", "rkb_s", "wkb_s", "avgrq_sz", "avgqu_sz", "await", "r_await", "w_await", "svctm", "util")
df <- read.csv("/home/sveta/build/mysql-5.6-fb/mysql-test/var/mysqld.1/data/iostat/sdb_test", col.names = cnames)
df

rqm_s = data.frame(df["ts"], stack(df, select = c("rrqm_s","wrqm_s")))
ggplot(rqm_s, aes_string(x="ts",y="values", color="ind", group="ind")) + geom_point() + geom_line() + theme(axis.text.x = element_text(angle=90,vjust=0.5)) + labs(x = "Time", y = "r/wrqm_s", title = paste("iostat - ", "r/wrqm_s")) 

rw_s = data.frame(df["ts"], stack(df, select = c("r_s","w_s")))
ggplot(rw_s, aes_string(x="ts",y="values", color="ind", group="ind")) + geom_point() + geom_line() + theme(axis.text.x = element_text(angle=90,vjust=0.5)) + labs(x = "Time", y = "r/wr_s", title = paste("iostat - ", "r/w_s")) 

kb_s = data.frame(df["ts"], stack(df, select = c("rkb_s","wkb_s")))
ggplot(kb_s, aes_string(x="ts",y="values", color="ind", group="ind")) + geom_point() + geom_line() + theme(axis.text.x = element_text(angle=90,vjust=0.5)) + labs(x = "Time", y = "r/wkb_s", title = paste("iostat - ", "r/wkb_s")) 

avgr = data.frame(df["ts"], stack(df, select = c("avgrq_sz","avgqu_sz")))
ggplot(avgr, aes_string(x="ts",y="values", color="ind", group="ind")) + geom_point() + geom_line() + theme(axis.text.x = element_text(angle=90,vjust=0.5)) + labs(x = "Time", y = "avgrq/u_sz", title = paste("iostat - ", "avgrq/u_sz")) 

awaits = data.frame(df["ts"], stack(df, select = c("await","r_await", "w_await")))
ggplot(awaits, aes_string(x="ts",y="values", color="ind", group="ind")) + geom_point() + geom_line() + theme(axis.text.x = element_text(angle=90,vjust=0.5)) + labs(x = "Time", y = "r/w_await", title = paste("iostat - ", "r/w_await")) 

qplot(x = df["id"], y = df["await"], data = df, geom = "path")
qplot(x = df["id"], y = df["r_await"], data = df, geom = "path")
qplot(x = df["id"], y = df["w_await"], data = df, geom = "path")

qplot(x = df["id"], y = df["svctm"], data = df, geom = "path")

qplot(x = df["id"], y = df["util"], data = df, geom = "path")

overall  = data.frame(df["ts"], stack(df, select = c("rrqm_s", "wrqm_s", "r_s", "w_s", "rkb_s", "wkb_s", "avgrq_sz", "avgqu_sz", "await", "r_await", "w_await", "svctm", "util")))
ggplot(overall, aes_string(x="ts",y="values", color="ind", group="ind")) + geom_point() + theme(axis.text.x = element_text(angle=90,vjust=0.5)) + labs(x = "Time", y = "Requests", title = paste("iostat - ", "overall")) 


setwd("/home/sveta/issues/230804/fifa19-lt-db-main-01_0130-0230/pt-stalk")

break_names <- c("rrqm_s", "wrqm_s", "r_s", "w_s", "rkb_s", "wkb_s", "avgrq_sz", "avgqu_sz", "await", "r_await", "w_await", "svctm", "util")
ggplot(overall, aes(ts, values, color=ind, group=ind)) +
    ylab("Trx/s") +
    xlab("Threads") +
    scale_colour_discrete(breaks = break_names, labels = break_names, name = "Data") +
    theme(axis.text.x = element_text(angle=90,vjust=0.5)) + labs(x = "Time", y = "Requests", title = paste("iostat - ", "overall")) +
    geom_line()
ggsave("overall.png")
