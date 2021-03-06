print(Sys.getpid())
print('reading data')
# nats genes are same as L1000
L1000geneAnnots = readRDS('analysis/00.cmapRanks/FWDgeneAnnots.rds')
inst = readRDS('analysis/00.cmapRanks/FWDinstances.rds')



library(cmapQuery)
library(dplyr)
library(magrittr)
calculateKs = TRUE
calculateSpecificity = FALSE
if(calculateKs){
    print('pre-calcing random Ks')
    L1000PreCalc = preCalcRandomKs(inst$pert_iname)
    
    saveRDS(L1000PreCalc,'analysis/00.cmapRanks/FWDPreCalc.rds')
}


if(calculateSpecificity){
    L1000PreCalc = readRDS('analysis/00.cmapRanks/FWDPreCalc.rds')
    
    print('getting msigdb groups')
    
    rankMatrix = readRDS('analysis/00.cmapRanks/FWDranks.rds')
    
    gpl96 = gemmaAPI::getAnnotation('GPL96')
    MSigDBLegacyL1000IDs = MSigDBLegacy %>% lapply(function(x){
        x$upTags = gemmaAPI::annotationGeneMatch(x$upTags,gpl96,removeNAs = TRUE)
        x$downTags = gemmaAPI::annotationGeneMatch(x$downTags,gpl96,removeNAs = TRUE)
        x$downTags = L1000geneAnnots %>% filter(pr_gene_symbol %in% x$downTags) %$% pr_gene_id
        x$upTags = L1000geneAnnots %>% filter(pr_gene_symbol %in% x$upTags) %$% pr_gene_id
        
        return(x)
    })
    print('pre-calcing specificity for legacy msigdb')
    L1000MsigDBLegacyPreCalc = specificityPreCalculation(signatures = MSigDBLegacyL1000IDs,
                                                         rankMatrix = rankMatrix,
                                                         chems = inst$pert_iname,
                                                         preCalc = L1000PreCalc,
                                                         cores = 2)
    saveRDS(L1000MsigDBPreCalc,'analysis/00.cmapRanks/L1000MsigDBLegacyPreCalc.rds')
    
    # print('pre-calcing specificity for new msigdb')
    # 
    # MSigDB62L1000IDs = MSigDB62 %>% lapply(function(x){
    #     x$downTags = L1000geneAnnots %>% filter(pr_gene_symbol %in% x$downTags) %$% pr_gene_id
    #     x$upTags = L1000geneAnnots %>% filter(pr_gene_symbol %in% x$upTags) %$% pr_gene_id
    #     return(x)
    # })
    # L1000MsigDB62PreCalc = specificityPreCalculation(signatures = MSigDB62L1000IDs,
    #                                                rankMatrix = rankMatrix,
    #                                                chems = inst$pert_iname,
    #                                                preCalc = L1000PreCalc,
    #                                                cores = 2)
    # 
    # saveRDS(L1000MsigDBPreCalc,'analysis/00.cmapRanks/L1000MsigDBPreCalc.rds')
    
}
