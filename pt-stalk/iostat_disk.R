#!/usr/bin/Rscript
# Usage: iostat_disk.R disk sourcedir targetdir

library(ggplot2)

ptstalk.iostat.graph <- function(df, break_names, disk, suffix, data_scale)
{
    dt <- data.frame(df["ts"], stack(df, select = break_names))
    
    ggplot(dt, aes(ts, values, color=ind, group=ind)) +
        scale_colour_discrete(breaks = break_names, labels = break_names, name = "Metrics") +
        theme(axis.text.x = element_text(angle=90,vjust=0.5)) + labs(x = "Time", y = "Requests", title = paste0("iostat - ", suffix)) +
        scale_y_continuous(labels = scales::comma) +
        geom_line()
    ggsave(paste0(disk, "_", suffix, ".png"), width = data_scale * 4, units = "mm")
}

ptstalk.iostat.graph_all <- function(df, disk, data_scale)
{
    break_names <- c("rrqm_s", "wrqm_s", "r_s", "w_s", "rkb_s", "wkb_s", "avgrq_sz", "avgqu_sz", "await", "r_await", "w_await", "svctm", "util")
    
    ptstalk.iostat.graph(df, break_names, disk, "all", data_scale)
}

ptstalk.iostat.graph_rwrqm_s <- function(df, disk, data_scale)
{
    break_names <- c("rrqm_s", "wrqm_s")
    
    ptstalk.iostat.graph(df, break_names, disk, "rrqm_s-wrqm_s", data_scale)
}

ptstalk.iostat.graph_rw_s <- function(df, disk, data_scale)
{
    break_names <- c("r_s", "w_s")
    
    ptstalk.iostat.graph(df, break_names, disk, "r_s-w_s", data_scale)
}

ptstalk.iostat.graph_rwkb_s <- function(df, disk, data_scale)
{
    break_names <- c("rkb_s", "wkb_s")
    
    ptstalk.iostat.graph(df, break_names, disk, "rkb_s-wkb_s", data_scale)
}

ptstalk.iostat.graph_avgs <- function(df, disk, data_scale)
{
    break_names <- c("avgrq_sz", "avgqu_sz")
    
    ptstalk.iostat.graph(df, break_names, disk, "averages", data_scale)
}

ptstalk.iostat.graph_waits <- function(df, disk, data_scale)
{
    break_names <- c("await", "r_await", "w_await")
    
    ptstalk.iostat.graph(df, break_names, disk, "waits", data_scale)
}

ptstalk.iostat.graph_svctm <- function(df, disk, data_scale)
{
    break_names <- c("svctm")
    
    ptstalk.iostat.graph(df, break_names, disk, "svctm", data_scale)
}

ptstalk.iostat.graph_util <- function(df, disk, data_scale)
{
    break_names <- c("util")
    
    ptstalk.iostat.graph(df, break_names, disk, "util", data_scale)
}

args <- commandArgs(trailingOnly = TRUE)

if (3 > length(args))
{
    stop("You must specify source directory, target directory and disk data file to proceed!\n")
}

setwd(args[3])

cnames <- c("id", "ts", "device", "rrqm_s", "wrqm_s", "r_s", "w_s", "rkb_s", "wkb_s", "avgrq_sz", "avgqu_sz", "await", "r_await", "w_await", "svctm", "util")
df <- read.csv(paste0(args[2], "/", args[1]), col.names = cnames)
data_scale <- nrow(df)

ptstalk.iostat.graph_all(df, tools::file_path_sans_ext(args[1]), data_scale)
ptstalk.iostat.graph_rwrqm_s(df, tools::file_path_sans_ext(args[1]), data_scale)
ptstalk.iostat.graph_rw_s(df, tools::file_path_sans_ext(args[1]), data_scale)
ptstalk.iostat.graph_rwkb_s(df, tools::file_path_sans_ext(args[1]), data_scale)
ptstalk.iostat.graph_avgs(df, tools::file_path_sans_ext(args[1]), data_scale)
ptstalk.iostat.graph_waits(df, tools::file_path_sans_ext(args[1]), data_scale)
ptstalk.iostat.graph_svctm(df, tools::file_path_sans_ext(args[1]), data_scale)
ptstalk.iostat.graph_util(df, tools::file_path_sans_ext(args[1]), data_scale)