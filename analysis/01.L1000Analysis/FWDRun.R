print(Sys.getpid())
library(dplyr)
library(cmapQuery)
library(magrittr)
library(glue)
library(homologene)

dir.create('analysis/01.L1000Analysis/fwdResults/chemScores',showWarnings = FALSE,recursive = TRUE)
dir.create('analysis/01.L1000Analysis/fwdResults/instanceScores',showWarnings = FALSE,recursive = TRUE)


print("loading data")
load('data/genesEdgerNoOutlier.rda')
inst = readRDS('analysis/00.cmapRanks/FWDinstances.rds')
rankMatrix = readRDS('analysis/00.cmapRanks/FWDranks.rds')


L1000geneAnnots = readRDS('analysis/00.cmapRanks/FWDgeneAnnots.rds')
L1000PreCalc = readRDS('analysis/00.cmapRanks/FWDPreCalc.rds')
gc()

dataset = genesEdgerNoOutlier

groups = c("E12_1_week_IP_vs_naive_adult_3_IP",
           "E12_2_week_IP_vs_naive_adult_3_IP",
           "E12_3_day_IP_vs_naive_adult_3_IP",
           "naive_1_week_IP_vs_naive_adult_3_IP",
           "naive_2_weeks_IP_vs_naive_adult_3_IP",
           "naive_3_days_IP_vs_naive_adult_3_IP")


groupShorthands = c("E12_1_week_IP_vs_naive_adult_3_IP" = 'regen 1 week',
                    "E12_2_week_IP_vs_naive_adult_3_IP" = 'regen 2 week',
                    "E12_3_day_IP_vs_naive_adult_3_IP" = 'regen 3 days',
                    "naive_1_week_IP_vs_naive_adult_3_IP" = 'naive 1 week',
                    "naive_2_weeks_IP_vs_naive_adult_3_IP" = 'naive 2 weeks',
                    "naive_3_days_IP_vs_naive_adult_3_IP" = 'naive 3 days')

FDRLimit = 0.05

print('staring run')

groups %>% lapply(function(group){
    print(group)
    if(any(grepl('FDR_pVal',colnames(dataset)))){
        pVal = 'pVal_'
    } else{
        pVal = ''
    }
    filter_criteriaUp = lazyeval::interp(~FC > 0 & Pval < FDRLimit, 
                                         FC = as.name(glue('logFC_{group}')),
                                         Pval =  as.name(glue('FDR_{pVal}{group}')))
    
    upGenes = dataset %>%
        dplyr::filter_(filter_criteriaUp) %>% 
        dplyr::arrange_(.dots = c(glue('desc(logFC_{group})'))) %>% # this line won't be necessary later on
        dplyr::select(gene) %>% 
        unlist %>%
        mouse2human %>% {.$humanGene} %>% unique
    
    upTags = L1000geneAnnots %>% filter(pr_gene_symbol %in% upGenes) %$% pr_id
    
    filter_criteriaDown = lazyeval::interp(~FC < 0 & Pval < FDRLimit, 
                                           FC = as.name(glue('logFC_{group}')),
                                           Pval =  as.name(glue('FDR_{pVal}{group}')))
    
    downGenes = dataset %>%
        dplyr::filter_(filter_criteriaDown) %>% 
        dplyr::arrange_(.dots = c(glue('logFC_{group}'))) %>% # this line won't be necessary later on
        dplyr::select(gene) %>% 
        unlist %>%
        mouse2human %>% {.$humanGene} %>% unique 
    downTags = L1000geneAnnots %>% filter(pr_gene_symbol %in% downGenes) %$% pr_id
    print('up-genes down-genes acquired')
    analysis = connectivityMapEnrichment(upTags,
                                         downTags,
                                         rankMatrix,
                                         inst$pert_iname,
                                         preCalc = L1000PreCalc,
                                         vocal = TRUE)
    
    print('finished run. writing to file')
    write.table(analysis$chemScores,
                file = glue('analysis/01.L1000Analysis/fwdResults/chemScores/{groupShorthands[group]}'))
    write.table(analysis$instanceScores,
                file = glue('analysis/01.L1000Analysis/fwdResults/instanceScores/{groupShorthands[group]}'))
    
})