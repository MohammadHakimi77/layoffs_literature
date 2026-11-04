# Aggregate cohort-specific synthetic DiD results

# Load packages
library(data.table)
library(dplyr)
library(synthdid)
library(haven) 
library(abind)

### load all available synthdid results
ncpus = 16

if (ncpus>1) {
  library(parallel)
  cl <<- makePSOCKcluster(ncpus)
  void<-clusterEvalQ(cl, library(synthdid))
  void<-clusterEvalQ(cl, library(data.table))
  
}

result_files = list.files('../output', pattern='^synthdid_results', full.names = T)

result_list <- lapply(result_files, function(fn) {
  cat(paste0('Loading ', fn, '...\n'))
  load(file = fn)

  get_results <- function(x, list_name) {
    results=x$estimates
    ssize = rbindlist(lapply(x$samplesize, function(y) y$ids))[, list(.N),by=c('treated_unit','id','date')]
    ssize_num = nrow(ssize)
    result_df=rbindlist(results)
   
    result_df <- result_df[!is.na(result_df$tau_hat)]
    result_df[, weight:= post_treat_days / sum(post_treat_days)]
    result_df[, cum_treat:=cumsum(current_treat)]
    
    ndonors = weighted.mean(x = result_df$ndonors, w = result_df$weight)
    
    treatment_window = (unique(result_df$post_treat_days/result_df$current_treat)-1)*2+1
    
    overall_estimator <- sum(result_df$weight * result_df$tau_hat, na.rm = T)
    overall_se=sqrt(sum((result_df$weight^2)*as.numeric(result_df$standard_error)^2, na.rm = T))
    overall_p=2*pt(q=sqrt(((overall_estimator/overall_se)^2)), df=(ndonors*treatment_window-treatment_window-ndonors), lower.tail=FALSE)
    
    tau_hat_list <- lapply(results, function(x) x$tau_hat_list)
    
    cat('. Starting computation of stats\n')
    if(ncpus==1) {
      tau_hat_list_plot <- lapply(tau_hat_list, plot)
    } else {
      tau_hat_list_plot=clusterApplyLB(cl, tau_hat_list, plot)
    }
    
    cat('   Summarizing...\n')
    #add sum of weights to plot
    MSPE <- data.frame()
    
    MSPE = rbindlist(lapply(1:length(tau_hat_list_plot), function(z) {
      #add Mean squared prediction error
      foo <- filter(tau_hat_list_plot[[z]][["layers"]][[1]][["data"]], x < result_df$treatment_period[z]) |>
          group_by(color) |>
          mutate(y = y - mean(y)) |>
          ungroup() |>
          group_by(x) |>
          summarise(y = diff(y, lag = 1)) |>
          ungroup() |>
          summarise(MSPE = sum(y^2),
                    days_num = n())
        return(foo)
      }))
    
    MSPE[, MSPE:=MSPE/days_num]
    weighted.mean(x = MSPE$MSPE, w = MSPE$days_num)
    
    final_results <- c()
    
    
    final_results$filename=fn
    final_results$ATT <- paste0(round(overall_estimator,8), ifelse(overall_p <= .05 & overall_p > .01,"**",
                                                                    ifelse(overall_p < .1 & overall_p > .05,"*",
                                                                           ifelse(overall_p <= .01,"***",""))))
    final_results$SE <- paste0(round(overall_se,8))
    final_results$P <- paste0(round(overall_p,8))
    final_results$MSPE <- round(weighted.mean(x = MSPE$MSPE, w = MSPE$days_num),10)
    final_results$`Treated playlists` <- sum(result_df$current_treat) 
    final_results$`Post-treated observations` <- sum(result_df$current_treat)*(15+1)
    final_results$type <- list_name
    final_results$samplesize <- ssize_num
    list(final_results = final_results, MSPE=MSPE,tau_hat_list_plot=tau_hat_list_plot, result_df=result_df, fn=fn, type = list_name)
    
  }
  
  resobjects = grep('^synthdid',ls(),value=T)
  print(resobjects)
  list_obj = mget(resobjects)
  
  res <- mapply(get_results, list_obj, list_name=gsub('^synthdid_','',resobjects), SIMPLIFY=F)
  rm(list=resobjects)
  return(res)
})

syndid_summary = rbindlist(lapply(result_list, function(x) rbindlist(lapply(x, function(x) x$final_results))))

synthdid_results <- result_list
  
fwrite(syndid_summary, file = '../output/syndid_summary.csv')

save(synthdid_results, syndid_summary, file = '../output/syndid_results.RData')
