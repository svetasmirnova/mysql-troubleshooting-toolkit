#!/usr/bin/Rscript

library("methods")

source('diskstats.R')
source('iostat.R')

args <- commandArgs(trailingOnly = TRUE)

if (1 > length(args))
{
	stop("You must specify source directory!\n")
}

#ptstalk.diskstats.graphs(args[1], args[2])
ptstalk.iostat.graphs(args[1], args[2])
