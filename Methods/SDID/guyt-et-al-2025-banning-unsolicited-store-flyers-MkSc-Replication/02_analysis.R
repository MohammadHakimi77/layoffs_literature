###################################
##### This file will generate all output tables in paper. See readme file for more information on structure of the code
###################################


if (table_2==TRUE){
  # Create summary tables for treated and control groups
  temp_data <- rbindlist(dt_combined)
  table_2a_paper <- temp_data[group == "treated", .(Pre_Mean = mean(Y[period == "pre"]),
                                                          Pre_SD = sd(Y[period == "pre"]),
                                                          Post_Mean = mean(Y[period == "post"]),
                                                          Post_SD = sd(Y[period == "post"])), 
                                    by = Variable]
  
  table_2b_paper <- temp_data[group == "control", .(Pre_Mean = mean(Y[period == "pre"]),
                                                          Pre_SD = sd(Y[period == "pre"]),
                                                          Post_Mean = mean(Y[period == "post"]),
                                                          Post_SD = sd(Y[period == "post"])), 
                                    by = Variable]
  
  rm(temp_data)
  # Print the summary tables
  cat("Treated Group Summary:\n")
  print(table_2a_paper)
  
  cat("\nControl Group Summary:\n")
  print(table_2b_paper)
}



if (table_6 == TRUE | table_7 == TRUE | table_8 == TRUE){
  ## List to store everything
  Ys_cohorts <- list()
  N0s_cohorts <- list()
  T0s_cohorts <- list()
  estimates_sdid <- list()
  
  for (cohort in 1:5){
    ## Restructure the data to estimate a synthdid model
    dt_combined[[cohort]][, treat_post := as.numeric(group=="treated" & period=="post")]
    
    # create an empty Y_s list
    Ys_cohorts[[cohort]] <- list()
    N0s_cohorts[[cohort]] <- list()
    T0s_cohorts[[cohort]] <- list()
    estimates_sdid[[cohort]] <- list()
    
    ### now loop over all the other variables
    for (var in 1:9){
      setup <- panel.matrices(dt_combined[[cohort]][Variable==variables[var,1], c("unit","time","Y","treat_post")], time='time')
      
      Ys_cohorts[[cohort]][[var]] <- setup$Y  
      N0s_cohorts[[cohort]][[var]] <- setup$N0 
      T0s_cohorts[[cohort]][[var]] <- setup$T0
      
      estimates_sdid[[cohort]][[var]] <- synthdid_estimate(Ys_cohorts[[cohort]][[var]], N0s_cohorts[[cohort]][[var]], T0s_cohorts[[cohort]][[var]])
      
      cat("\nCohort:", cohort, "\n", "\nVariable:", var, "\n")
    }
  }
  
  # jackknife
  # setup 
  estimates_sdid_ATEs <- NULL # this creates a data.table that includes all ATEs, no of observations, and variable and cohort names for easy access below
  for (cohort in 1:5){
    for (var in 1:9){
      estimates_sdid_ATEs <- rbind(estimates_sdid_ATEs, c(estimates_sdid[[cohort]][[var]][[1]], nrow(Ys_cohorts[[cohort]][[var]]), nrow(Ys_cohorts[[cohort]][[var]])-N0s_cohorts[[cohort]][[var]], variables$Variable[var], cohort))
    }
  }
  estimates_sdid_ATEs <- data.table(estimates_sdid_ATEs)
  colnames(estimates_sdid_ATEs) <- c("ATE", "N_obs", "N_treated", "DV", "Cohort")
  estimates_sdid_ATEs[, ":="(ATE = as.numeric(ATE),
                             N_obs = as.numeric(N_obs),
                             N_treated = as.numeric(N_treated))]
  
  # Clark et al. (2022) jackknife (see https://docs.iza.org/dp15907.pdf algorithm 3, p. 12, for more details)
  cl <- parallel::makeCluster(15) # running the jackknife in parallel across 15 cores, if ran not in parallel one can change %dopar% to %do% below
  doParallel::registerDoParallel(cl)
  estimates_sdid_jackknife <- vector("list", 5) ## we will fill in the jackknifed ATTs for the focal cohort, the weighted version across the 5 cohorts, and the weighted version across the 4 cohorts (all but Amsterdam) (3 columns)
  for (cohort in 1:5){ ## we will loop over cohorts here and apply the jackknife to each cohort, because the estimates for the non-focal doesn't change by leaving one unit out (they're stable) we don't have to re-estimate them, see below
    estimates_sdid_jackknife[[cohort]] <- vector("list", 9)
    for (var in 1:9){
      omegas  <- attr(estimates_sdid[[cohort]][[var]], "weights")$omega # the unit weights from the previous estimation (treated as fixed as per Clark et al. 2022, p. 12)
      lambdas <- attr(estimates_sdid[[cohort]][[var]], "weights")$lambda # the time weights from the previous estimation
      out <- foreach(i=1:nrow(Ys_cohorts[[cohort]][[var]]), .combine=rbind, .packages=c("synthdid")) %dopar% { # loop over all treated and control households creating an output of estimates for each iteration and number of treated households
        if (i <= N0s_cohorts[[cohort]][[var]]){ # if control unit if left out
          c(synthdid_estimate(Ys_cohorts[[cohort]][[var]][-i,], 
                              N0s_cohorts[[cohort]][[var]]-1, 
                              T0s_cohorts[[cohort]][[var]], 
                              weights = list(omega = omegas[-i]/sum(omegas[-i]), # ensure they sum to 1 again after leavinout the ith household
                                             lambda = lambdas))[[1]],
            nrow(Ys_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]])
        } else { # if treated is left out
          c(estimates_sdid_jackknife[[cohort]][[var]], 
            synthdid_estimate(Ys_cohorts[[cohort]][[var]][-i,], 
                              N0s_cohorts[[cohort]][[var]], 
                              T0s_cohorts[[cohort]][[var]], 
                              weights = list(omega = omegas, 
                                             lambda = lambdas))[[1]],
            nrow(Ys_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]] - 1)
        }
      }
      estimates_sdid_jackknife[[cohort]][[var]] <- out[,1]
      N_treated_temp <- out[,2]
      
      # the ATEs for the other cohorts are stable and can be precalculated
      # we need the N_treated for the other cohorts and the ATEs for the other cohorts
      temp_ATEs <- estimates_sdid_ATEs[Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                       N_treated = sum(N_treated))]
      temp_ATEs2 <- estimates_sdid_ATEs[Cohort>=2 & Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                                    N_treated = sum(N_treated))] # we exclude Amsterdam (cohort 1) here for the RC
      
      
      # this computes the jackknifed ATEs for each iteration (for the focal cohort, the weighted version across the 5 cohorts, and the weighted version across the 4 cohorts (all but Amsterdam))
      # formula: ATE * N_treated + weighted_ATE (which is sum of the same for other cohorts) / N_treated focal + N_treated other cohorts
      estimates_sdid_jackknife[[cohort]][[var]] <- cbind(estimates_sdid_jackknife[[cohort]][[var]], # focal cohort
                                                         (estimates_sdid_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs$weighted_ATE ) / (N_treated_temp + temp_ATEs$N_treated), # across the 5 cohorts
                                                         (estimates_sdid_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs2$weighted_ATE ) / (N_treated_temp + temp_ATEs2$N_treated)) # across 4 cohorts (all but Amsterdam)
      print(paste0("Jackknifing the SDID estimates for cohort ", cohort, " and var ", var, " completed"))
    }
  }
  stopCluster(cl=cl)
  
  # combine to compute the variance across the jackknifed ATEs (Clarke et al. 2022, algorithm 3, step 2, p. 12)
  var_sdid_jackknife_per_cohort <- vector("list", 9)
  var_sdid_jackknife_5_cohorts <- as.list(numeric(9))
  var_sdid_jackknife_4_cohorts <- as.list(numeric(9))
  for (var in 1:9){
    for (cohort in 1:5){
      var_sdid_jackknife_per_cohort[[var]][[cohort]] <- ((estimates_sdid_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated]-1)/estimates_sdid_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated])*sum((estimates_sdid_jackknife[[cohort]][[var]][, 1]-estimates_sdid_ATEs[Cohort==cohort & DV==variables$Variable[var], ATE])^2) # for the focal cohort
      var_sdid_jackknife_5_cohorts[[var]] <- var_sdid_jackknife_5_cohorts[[var]] + ((sum(estimates_sdid_ATEs[DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_ATEs[DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_jackknife[[cohort]][[var]][, 2]-estimates_sdid_ATEs[DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2) # across the 5 cohorts
      if (cohort!=1){
        var_sdid_jackknife_4_cohorts[[var]] <- var_sdid_jackknife_4_cohorts[[var]] + ((sum(estimates_sdid_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_jackknife[[cohort]][[var]][, 3]-estimates_sdid_ATEs[Cohort!=1 & DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)  # across 4 cohorts (all but Amsterdam)
      }
    }
  }
  
  if (table_6==TRUE){
    table_6_paper_cohorts <- list()
    for (cohort in 1:5) {
      # Aggregate data by time and group to calculate correlation
      aggregated_data <- dt_combined[[cohort]][, .(Y_mean = mean(Y)), by = .(Variable, time, group)]
      corr_table <- aggregated_data[time %in% pre_periods, .(Correlation = cor(Y_mean[group == "treated"], Y_mean[group == "control"])), by = Variable]
      # add a final row called "Average" that contains the average of the correlations across all variables
      corr_table <- rbind(corr_table, data.table(Variable = "Average", Correlation = mean(corr_table$Correlation)))
      
      ## calculate the SynthDID correlations (easiest is to call SynthDID package to create a plot of series for control & treated and extract that data)
      correlations_sdid <- NULL
      for (i in 1:9){
        temp <- estimates_sdid[[cohort]][[i]] # note, one can look at plots of the estimates by calling plot(temp)
        temp <- plot(temp, se.method="none", control.name="synthDID control", line.width=0.5, guide.linetype=0, point.size=0, diagram.alpha=0.25, effect.alpha=0, trajectory.linetype=c(rep(1, 104), rep(2, 104)))
        temp <- ggplot_build(temp)
        correlations_sdid[i] <- cor(temp$data[[1]]$y[temp$data[[1]]$group==1][1:52],temp$data[[1]]$y[temp$data[[1]]$group==2][1:52])    
      }
      
      correlations_sdid[10] <- mean(correlations_sdid)
      
      # calculate the weighted average for Y based on the omegas
      corr_table <- cbind(corr_table, data.table(Correlation_sdid = correlations_sdid))
      
      table_6_paper_cohorts[[cohort]] <- data.table(corr_table[,1], round(corr_table[, 2:3], 2))
    }
    # Average across cohorts
    table_6_paper <- rbindlist(table_6_paper_cohorts)[
      , lapply(.SD, mean), by = Variable, .SDcols = c("Correlation", "Correlation_sdid")
    ]
    
    # Print the correlation table (round to 3 decimal places)
    cat("\nCorrelation between Treated and Control Groups by Variable (SynthDID):\n")
    print(data.table(table_6_paper[,1], round(table_6_paper[, 2:3], 2)))
  }
  if (table_7==TRUE){
    # Create a summary table
    results_table_sdid <- data.table(
      Variable = variables$Variable,
      Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_ATEs[DV==x, ATE]*estimates_sdid_ATEs[DV==x, N_treated])/sum(estimates_sdid_ATEs[DV==x, N_treated])}, USE.NAMES=FALSE),
      Std.Error = sqrt(unlist(var_sdid_jackknife_5_cohorts))
    )
    
    results_table_sdid[, CI_low := Estimate - 1.96 * Std.Error]
    results_table_sdid[, CI_high := Estimate + 1.96 * Std.Error]
    
    # calculate a p-value based on the normal distribution
    results_table_sdid[, p.value := 2 * (1 - pnorm(abs(Estimate / Std.Error)))]
    
    # print the results
    cat("\nSummary of SynthDID Results:\n")
    table_7_paper <- data.table(results_table_sdid[,1], round(results_table_sdid[, 2:6], 2))
    print(data.table(table_7_paper[,1], round(table_7_paper[, 2:6], 2)))
  }
}


if (table_8 == TRUE){
  ## robustness table
  
  # this will create the data required for the RC's
  Ys_LN_cohorts <- list()
  Ys_26_cohorts <- list()
  Ys_13_cohorts <- list()
  T0s_26_cohorts <- list()
  T0s_13_cohorts <- list()
  
  for (cohort in 1:5) {
    Ys_LN_cohorts[[cohort]] <- list()
    Ys_26_cohorts[[cohort]] <- list()
    Ys_13_cohorts[[cohort]] <- list()
    T0s_26_cohorts[[cohort]] <- list()
    T0s_13_cohorts[[cohort]] <- list()
    for (var in 1:9) {
      setup_26 <- panel.matrices(dt_combined[[cohort]][Variable==variables[var,1] & (time > 52-25) &  (time < 53+26), c("unit","time","Y","treat_post")], time='time')
      setup_13 <- panel.matrices(dt_combined[[cohort]][Variable==variables[var,1] & (time > 52-12) &  (time < 53+13), c("unit","time","Y","treat_post")], time='time')
      Ys_26_cohorts[[cohort]][[var]] <- setup_26$Y  
      Ys_13_cohorts[[cohort]][[var]] <- setup_13$Y  
      T0s_26_cohorts[[cohort]][[var]] <- setup_26$T0
      T0s_13_cohorts[[cohort]][[var]] <- setup_13$T0
    }
  }
  
  # create log-transformed variables for the Y_s that allow for it (and ensure they're positive prior to transforming (due to random draws they can be negative))
  for (cohort in 1:5) {
    for (var in uncond_vars){
      Ys_LN_cohorts[[cohort]][[var]] <- Ys_cohorts[[cohort]][[var]]
      Ys_LN_cohorts[[cohort]][[var]][Ys_LN_cohorts[[cohort]][[var]] <= 0] <- 0.01
      Ys_LN_cohorts[[cohort]][[var]] <- log(Ys_LN_cohorts[[cohort]][[var]])
    }
  }
  
  # LN
  if (TRUE==TRUE) {
    # sdid
    estimates_sdid_LN <- list()
    for (cohort in 1:5) {
      estimates_sdid_LN[[cohort]] <- list()
      for (var in uncond_vars){
        estimates_sdid_LN[[cohort]][[var]] <- synthdid_estimate(Ys_LN_cohorts[[cohort]][[var]], N0s_cohorts[[cohort]][[var]], T0s_cohorts[[cohort]][[var]])
        cat("\nCohort:", cohort, "\n", "\nVariable:", var, "\n")
      }
    }
    
    # jackknife
    # setup
    estimates_sdid_LN_ATEs <- NULL
    for (cohort in 1:5){
      for (var in uncond_vars){
        estimates_sdid_LN_ATEs <- rbind(estimates_sdid_LN_ATEs, c(estimates_sdid_LN[[cohort]][[var]][[1]], nrow(Ys_LN_cohorts[[cohort]][[var]]), nrow(Ys_LN_cohorts[[cohort]][[var]])-N0s_cohorts[[cohort]][[var]], variables$Variable[var], cohort))
      }
    }
    estimates_sdid_LN_ATEs <- data.table(estimates_sdid_LN_ATEs)
    colnames(estimates_sdid_LN_ATEs) <- c("ATE", "N_obs", "N_treated", "DV", "Cohort")
    estimates_sdid_LN_ATEs[, ":="(ATE = as.numeric(ATE),
                                  N_obs = as.numeric(N_obs),
                                  N_treated = as.numeric(N_treated))]
    
    # Clark et al. (2022) jackknife
    cl <- parallel::makeCluster(15)
    doParallel::registerDoParallel(cl)
    estimates_sdid_LN_jackknife <- vector("list", 5) ## we will fill in the jackknifed ATTs for the focal cohort, the weighted version across the 5 cohorts, and the weighted version across the 4 cohorts (all but Amsterdam) (3 columns)
    for (cohort in 1:5){
      estimates_sdid_LN_jackknife[[cohort]] <- vector("list", 9)
      for (var in uncond_vars){
        omegas  <- attr(estimates_sdid_LN[[cohort]][[var]], "weights")$omega
        lambdas <- attr(estimates_sdid_LN[[cohort]][[var]], "weights")$lambda
        out <- foreach(i=1:nrow(Ys_LN_cohorts[[cohort]][[var]]), .combine=rbind, .packages=c("synthdid")) %dopar% { # for (i in 1:nrow(Ys_LN_cohorts[[cohort]][[var]])){
          if (i <= N0s_cohorts[[cohort]][[var]]){
            c(synthdid_estimate(Ys_LN_cohorts[[cohort]][[var]][-i,], 
                                N0s_cohorts[[cohort]][[var]]-1, 
                                T0s_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas[-i]/sum(omegas[-i]), 
                                               lambda = lambdas))[[1]],
              nrow(Ys_LN_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]])
          } else {
            c(estimates_sdid_LN_jackknife[[cohort]][[var]], 
              synthdid_estimate(Ys_LN_cohorts[[cohort]][[var]][-i,], 
                                N0s_cohorts[[cohort]][[var]], 
                                T0s_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas, 
                                               lambda = lambdas))[[1]],
              nrow(Ys_LN_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]] - 1)
          }
        }
        estimates_sdid_LN_jackknife[[cohort]][[var]] <- out[,1]
        N_treated_temp <- out[,2]
        
        # the ATEs for the other cohorts are stable and can be precalculated
        # we need the N_treated for the other cohorts and the ATEs for the other cohorts
        temp_ATEs <- estimates_sdid_LN_ATEs[Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                            N_treated = sum(N_treated))]
        temp_ATEs2 <- estimates_sdid_LN_ATEs[Cohort>=2 & Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                                         N_treated = sum(N_treated))]    
        
        # formula: ATE * N_treated + weighted_ATE (which is sum of the same for other cohorts) / N_treated focal + N_treated other cohorts
        estimates_sdid_LN_jackknife[[cohort]][[var]] <- cbind(estimates_sdid_LN_jackknife[[cohort]][[var]],
                                                              (estimates_sdid_LN_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs$weighted_ATE ) / (N_treated_temp + temp_ATEs$N_treated),
                                                              (estimates_sdid_LN_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs2$weighted_ATE ) / (N_treated_temp + temp_ATEs2$N_treated))
        print(paste0("Jackknifing the SDID estimates for cohort ", cohort, " and var ", var, " completed"))
      }
    }
    stopCluster(cl=cl)
    
    # combine
    var_sdid_LN_jackknife_per_cohort <- vector("list", 9)
    var_sdid_LN_jackknife_5_cohorts <- as.list(numeric(9))
    var_sdid_LN_jackknife_4_cohorts <- as.list(numeric(9))
    for (var in uncond_vars){
      for (cohort in 1:5){
        var_sdid_LN_jackknife_per_cohort[[var]][[cohort]] <- ((estimates_sdid_LN_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated]-1)/estimates_sdid_LN_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated])*sum((estimates_sdid_LN_jackknife[[cohort]][[var]][, 1]-estimates_sdid_LN_ATEs[Cohort==cohort & DV==variables$Variable[var], ATE])^2)
        var_sdid_LN_jackknife_5_cohorts[[var]] <- var_sdid_LN_jackknife_5_cohorts[[var]] + ((sum(estimates_sdid_LN_ATEs[DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_LN_ATEs[DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_LN_jackknife[[cohort]][[var]][, 2]-estimates_sdid_LN_ATEs[DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        if (cohort!=1){
          var_sdid_LN_jackknife_4_cohorts[[var]] <- var_sdid_LN_jackknife_4_cohorts[[var]] + ((sum(estimates_sdid_LN_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_LN_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_LN_jackknife[[cohort]][[var]][, 3]-estimates_sdid_LN_ATEs[Cohort!=1 & DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        }
      }
    }
    
    # Create a summary table
    results_table_sdid_LN <- data.table(
      Variable = variables$Variable,
      Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_LN_ATEs[DV==x, ATE]*estimates_sdid_LN_ATEs[DV==x, N_treated])/sum(estimates_sdid_LN_ATEs[DV==x, N_treated])}, USE.NAMES=FALSE),
      Std.Error = sqrt(unlist(var_sdid_LN_jackknife_5_cohorts))
    )
    
    results_table_sdid_LN[, CI_low := Estimate - 1.96 * Std.Error]
    results_table_sdid_LN[, CI_high := Estimate + 1.96 * Std.Error]
  } # just to allow (un)folding the code
  
  # 26 weeks
  if (TRUE==TRUE) {
    # sdid
    estimates_sdid_26 <- list()
    for (cohort in 1:5) {
      estimates_sdid_26[[cohort]] <- list()
      for (var in 1:9){
        estimates_sdid_26[[cohort]][[var]] <- synthdid_estimate(Ys_26_cohorts[[cohort]][[var]], N0s_cohorts[[cohort]][[var]], T0s_26_cohorts[[cohort]][[var]])
        cat("\nCohort:", cohort, "\n", "\nVariable:", var, "\n")
      }
    }
    
    # jackknife
    # setup
    estimates_sdid_26_ATEs <- NULL
    for (cohort in 1:5){
      for (var in 1:9){
        estimates_sdid_26_ATEs <- rbind(estimates_sdid_26_ATEs, c(estimates_sdid_26[[cohort]][[var]][[1]], nrow(Ys_26_cohorts[[cohort]][[var]]), nrow(Ys_26_cohorts[[cohort]][[var]])-N0s_cohorts[[cohort]][[var]], variables$Variable[var], cohort))
      }
    }
    estimates_sdid_26_ATEs <- data.table(estimates_sdid_26_ATEs)
    colnames(estimates_sdid_26_ATEs) <- c("ATE", "N_obs", "N_treated", "DV", "Cohort")
    estimates_sdid_26_ATEs[, ":="(ATE = as.numeric(ATE),
                                  N_obs = as.numeric(N_obs),
                                  N_treated = as.numeric(N_treated))]
    
    # Clark et al. (2022) jackknife
    cl <- parallel::makeCluster(15)
    doParallel::registerDoParallel(cl)
    estimates_sdid_26_jackknife <- vector("list", 5) ## we will fill in the jackknifed ATTs for the focal cohort, the weighted version across the 5 cohorts, and the weighted version across the 4 cohorts (all but Amsterdam) (3 columns)
    for (cohort in 1:5){
      estimates_sdid_26_jackknife[[cohort]] <- vector("list", 9)
      for (var in 1:9){
        omegas  <- attr(estimates_sdid_26[[cohort]][[var]], "weights")$omega
        lambdas <- attr(estimates_sdid_26[[cohort]][[var]], "weights")$lambda
        out <- foreach(i=1:nrow(Ys_26_cohorts[[cohort]][[var]]), .combine=rbind, .packages=c("synthdid")) %dopar% { # for (i in 1:nrow(Ys_26_cohorts[[cohort]][[var]])){
          if (i <= N0s_cohorts[[cohort]][[var]]){
            c(synthdid_estimate(Ys_26_cohorts[[cohort]][[var]][-i,], 
                                N0s_cohorts[[cohort]][[var]]-1, 
                                T0s_26_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas[-i]/sum(omegas[-i]), 
                                               lambda = lambdas))[[1]],
              nrow(Ys_26_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]])
          } else {
            c(estimates_sdid_26_jackknife[[cohort]][[var]], 
              synthdid_estimate(Ys_26_cohorts[[cohort]][[var]][-i,], 
                                N0s_cohorts[[cohort]][[var]], 
                                T0s_26_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas, 
                                               lambda = lambdas))[[1]],
              nrow(Ys_26_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]] - 1)
          }
        }
        estimates_sdid_26_jackknife[[cohort]][[var]] <- out[,1]
        N_treated_temp <- out[,2]
        
        # the ATEs for the other cohorts are stable and can be precalculated
        # we need the N_treated for the other cohorts and the ATEs for the other cohorts
        temp_ATEs <- estimates_sdid_26_ATEs[Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                            N_treated = sum(N_treated))]
        temp_ATEs2 <- estimates_sdid_26_ATEs[Cohort>=2 & Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                                         N_treated = sum(N_treated))]    
        
        # formula: ATE * N_treated + weighted_ATE (which is sum of the same for other cohorts) / N_treated focal + N_treated other cohorts
        estimates_sdid_26_jackknife[[cohort]][[var]] <- cbind(estimates_sdid_26_jackknife[[cohort]][[var]],
                                                              (estimates_sdid_26_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs$weighted_ATE ) / (N_treated_temp + temp_ATEs$N_treated),
                                                              (estimates_sdid_26_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs2$weighted_ATE ) / (N_treated_temp + temp_ATEs2$N_treated))
        print(paste0("Jackknifing the SDID estimates for cohort ", cohort, " and var ", var, " completed"))
      }
    }
    stopCluster(cl=cl)
    
    # combine
    var_sdid_26_jackknife_per_cohort <- vector("list", 9)
    var_sdid_26_jackknife_5_cohorts <- as.list(numeric(9))
    var_sdid_26_jackknife_4_cohorts <- as.list(numeric(9))
    for (var in 1:9){
      for (cohort in 1:5){
        var_sdid_26_jackknife_per_cohort[[var]][[cohort]] <- ((estimates_sdid_26_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated]-1)/estimates_sdid_26_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated])*sum((estimates_sdid_26_jackknife[[cohort]][[var]][, 1]-estimates_sdid_26_ATEs[Cohort==cohort & DV==variables$Variable[var], ATE])^2)
        var_sdid_26_jackknife_5_cohorts[[var]] <- var_sdid_26_jackknife_5_cohorts[[var]] + ((sum(estimates_sdid_26_ATEs[DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_26_ATEs[DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_26_jackknife[[cohort]][[var]][, 2]-estimates_sdid_26_ATEs[DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        if (cohort!=1){
          var_sdid_26_jackknife_4_cohorts[[var]] <- var_sdid_26_jackknife_4_cohorts[[var]] + ((sum(estimates_sdid_26_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_26_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_26_jackknife[[cohort]][[var]][, 3]-estimates_sdid_26_ATEs[Cohort!=1 & DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        }
      }
    }
    
    # Create a summary table
    results_table_sdid_26 <- data.table(
      Variable = variables$Variable,
      Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_26_ATEs[DV==x, ATE]*estimates_sdid_26_ATEs[DV==x, N_treated])/sum(estimates_sdid_26_ATEs[DV==x, N_treated])}, USE.NAMES=FALSE),
      Std.Error = sqrt(unlist(var_sdid_26_jackknife_5_cohorts))
    )
    
    results_table_sdid_26[, CI_low := Estimate - 1.96 * Std.Error]
    results_table_sdid_26[, CI_high := Estimate + 1.96 * Std.Error]
  } # just to allow (un)folding the code
  
  # 13 weeks
  if (TRUE==TRUE) {
    # sdid
    estimates_sdid_13 <- list()
    for (cohort in 1:5) {
      estimates_sdid_13[[cohort]] <- list()
      for (var in 1:9){
        estimates_sdid_13[[cohort]][[var]] <- synthdid_estimate(Ys_13_cohorts[[cohort]][[var]], N0s_cohorts[[cohort]][[var]], T0s_13_cohorts[[cohort]][[var]])
        cat("\nCohort:", cohort, "\n", "\nVariable:", var, "\n")
      }
    }
    
    # jackknife
    # setup
    estimates_sdid_13_ATEs <- NULL
    for (cohort in 1:5){
      for (var in 1:9){
        estimates_sdid_13_ATEs <- rbind(estimates_sdid_13_ATEs, c(estimates_sdid_13[[cohort]][[var]][[1]], nrow(Ys_13_cohorts[[cohort]][[var]]), nrow(Ys_13_cohorts[[cohort]][[var]])-N0s_cohorts[[cohort]][[var]], variables$Variable[var], cohort))
      }
    }
    estimates_sdid_13_ATEs <- data.table(estimates_sdid_13_ATEs)
    colnames(estimates_sdid_13_ATEs) <- c("ATE", "N_obs", "N_treated", "DV", "Cohort")
    estimates_sdid_13_ATEs[, ":="(ATE = as.numeric(ATE),
                                  N_obs = as.numeric(N_obs),
                                  N_treated = as.numeric(N_treated))]
    
    # Clark et al. (2022) jackknife
    cl <- parallel::makeCluster(15)
    doParallel::registerDoParallel(cl)
    estimates_sdid_13_jackknife <- vector("list", 5) ## we will fill in the jackknifed ATTs for the focal cohort, the weighted version across the 5 cohorts, and the weighted version across the 4 cohorts (all but Amsterdam) (3 columns)
    for (cohort in 1:5){
      estimates_sdid_13_jackknife[[cohort]] <- vector("list", 9)
      for (var in 1:9){
        omegas  <- attr(estimates_sdid_13[[cohort]][[var]], "weights")$omega
        lambdas <- attr(estimates_sdid_13[[cohort]][[var]], "weights")$lambda
        out <- foreach(i=1:nrow(Ys_13_cohorts[[cohort]][[var]]), .combine=rbind, .packages=c("synthdid")) %dopar% { # for (i in 1:nrow(Ys_13_cohorts[[cohort]][[var]])){
          if (i <= N0s_cohorts[[cohort]][[var]]){
            c(synthdid_estimate(Ys_13_cohorts[[cohort]][[var]][-i,], 
                                N0s_cohorts[[cohort]][[var]]-1, 
                                T0s_13_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas[-i]/sum(omegas[-i]), 
                                               lambda = lambdas))[[1]],
              nrow(Ys_13_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]])
          } else {
            c(estimates_sdid_13_jackknife[[cohort]][[var]], 
              synthdid_estimate(Ys_13_cohorts[[cohort]][[var]][-i,], 
                                N0s_cohorts[[cohort]][[var]], 
                                T0s_13_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas, 
                                               lambda = lambdas))[[1]],
              nrow(Ys_13_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]] - 1)
          }
        }
        estimates_sdid_13_jackknife[[cohort]][[var]] <- out[,1]
        N_treated_temp <- out[,2]
        
        # the ATEs for the other cohorts are stable and can be precalculated
        # we need the N_treated for the other cohorts and the ATEs for the other cohorts
        temp_ATEs <- estimates_sdid_13_ATEs[Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                            N_treated = sum(N_treated))]
        temp_ATEs2 <- estimates_sdid_13_ATEs[Cohort>=2 & Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                                         N_treated = sum(N_treated))]    
        
        # formula: ATE * N_treated + weighted_ATE (which is sum of the same for other cohorts) / N_treated focal + N_treated other cohorts
        estimates_sdid_13_jackknife[[cohort]][[var]] <- cbind(estimates_sdid_13_jackknife[[cohort]][[var]],
                                                              (estimates_sdid_13_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs$weighted_ATE ) / (N_treated_temp + temp_ATEs$N_treated),
                                                              (estimates_sdid_13_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs2$weighted_ATE ) / (N_treated_temp + temp_ATEs2$N_treated))
        print(paste0("Jackknifing the SDID estimates for cohort ", cohort, " and var ", var, " completed"))
      }
    }
    stopCluster(cl=cl)
    
    # combine
    var_sdid_13_jackknife_per_cohort <- vector("list", 9)
    var_sdid_13_jackknife_5_cohorts <- as.list(numeric(9))
    var_sdid_13_jackknife_4_cohorts <- as.list(numeric(9))
    for (var in 1:9){
      for (cohort in 1:5){
        var_sdid_13_jackknife_per_cohort[[var]][[cohort]] <- ((estimates_sdid_13_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated]-1)/estimates_sdid_13_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated])*sum((estimates_sdid_13_jackknife[[cohort]][[var]][, 1]-estimates_sdid_13_ATEs[Cohort==cohort & DV==variables$Variable[var], ATE])^2)
        var_sdid_13_jackknife_5_cohorts[[var]] <- var_sdid_13_jackknife_5_cohorts[[var]] + ((sum(estimates_sdid_13_ATEs[DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_13_ATEs[DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_13_jackknife[[cohort]][[var]][, 2]-estimates_sdid_13_ATEs[DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        if (cohort!=1){
          var_sdid_13_jackknife_4_cohorts[[var]] <- var_sdid_13_jackknife_4_cohorts[[var]] + ((sum(estimates_sdid_13_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_13_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_13_jackknife[[cohort]][[var]][, 3]-estimates_sdid_13_ATEs[Cohort!=1 & DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        }
      }
    }
    
    # Create a summary table
    results_table_sdid_13 <- data.table(
      Variable = variables$Variable,
      Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_13_ATEs[DV==x, ATE]*estimates_sdid_13_ATEs[DV==x, N_treated])/sum(estimates_sdid_13_ATEs[DV==x, N_treated])}, USE.NAMES=FALSE),
      Std.Error = sqrt(unlist(var_sdid_13_jackknife_5_cohorts))
    )
    
    results_table_sdid_13[, CI_low := Estimate - 1.96 * Std.Error]
    results_table_sdid_13[, CI_high := Estimate + 1.96 * Std.Error]
  } # just to allow (un)folding the code
  
  # equal time weights
  if (TRUE==TRUE) {
    # sdid
    estimates_sdid_eq_tweights <- list()
    for (cohort in 1:5) {
      estimates_sdid_eq_tweights[[cohort]] <- list()
      for (var in 1:9){
        estimates_sdid_eq_tweights[[cohort]][[var]] <- synthdid_estimate(Ys_cohorts[[cohort]][[var]], N0s_cohorts[[cohort]][[var]], T0s_cohorts[[cohort]][[var]], weights = list(lambda = rep(1/T0s_cohorts[[cohort]][[var]], T0s_cohorts[[cohort]][[var]])))
        cat("\nCohort:", cohort, "\n", "\nVariable:", var, "\n")
      }
    }
    
    # jackknife
    # setup
    estimates_sdid_eq_tweights_ATEs <- NULL
    for (cohort in 1:5){
      for (var in 1:9){
        estimates_sdid_eq_tweights_ATEs <- rbind(estimates_sdid_eq_tweights_ATEs, c(estimates_sdid_eq_tweights[[cohort]][[var]][[1]], nrow(Ys_cohorts[[cohort]][[var]]), nrow(Ys_cohorts[[cohort]][[var]])-N0s_cohorts[[cohort]][[var]], variables$Variable[var], cohort))
      }
    }
    estimates_sdid_eq_tweights_ATEs <- data.table(estimates_sdid_eq_tweights_ATEs)
    colnames(estimates_sdid_eq_tweights_ATEs) <- c("ATE", "N_obs", "N_treated", "DV", "Cohort")
    estimates_sdid_eq_tweights_ATEs[, ":="(ATE = as.numeric(ATE),
                                           N_obs = as.numeric(N_obs),
                                           N_treated = as.numeric(N_treated))]
    
    # Clark et al. (2022) jackknife
    cl <- parallel::makeCluster(15)
    doParallel::registerDoParallel(cl)
    estimates_sdid_eq_tweights_jackknife <- vector("list", 5) ## we will fill in the jackknifed ATTs for the focal cohort, the weighted version across the 5 cohorts, and the weighted version across the 4 cohorts (all but Amsterdam) (3 columns)
    for (cohort in 1:5){
      estimates_sdid_eq_tweights_jackknife[[cohort]] <- vector("list", 9)
      for (var in 1:9){
        omegas  <- attr(estimates_sdid_eq_tweights[[cohort]][[var]], "weights")$omega
        lambdas <- attr(estimates_sdid_eq_tweights[[cohort]][[var]], "weights")$lambda
        out <- foreach(i=1:nrow(Ys_cohorts[[cohort]][[var]]), .combine=rbind, .packages=c("synthdid")) %dopar% { # for (i in 1:nrow(Ys_cohorts[[cohort]][[var]])){
          if (i <= N0s_cohorts[[cohort]][[var]]){
            c(synthdid_estimate(Ys_cohorts[[cohort]][[var]][-i,], 
                                N0s_cohorts[[cohort]][[var]]-1, 
                                T0s_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas[-i]/sum(omegas[-i]), 
                                               lambda = rep(1/T0s_cohorts[[cohort]][[var]], T0s_cohorts[[cohort]][[var]])))[[1]],
              nrow(Ys_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]])
          } else {
            c(estimates_sdid_eq_tweights_jackknife[[cohort]][[var]], 
              synthdid_estimate(Ys_cohorts[[cohort]][[var]][-i,], 
                                N0s_cohorts[[cohort]][[var]], 
                                T0s_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas, 
                                               lambda = rep(1/T0s_cohorts[[cohort]][[var]], T0s_cohorts[[cohort]][[var]])))[[1]],
              nrow(Ys_cohorts[[cohort]][[var]]) - N0s_cohorts[[cohort]][[var]] - 1)
          }
        }
        estimates_sdid_eq_tweights_jackknife[[cohort]][[var]] <- out[,1]
        N_treated_temp <- out[,2]
        
        # the ATEs for the other cohorts are stable and can be precalculated
        # we need the N_treated for the other cohorts and the ATEs for the other cohorts
        temp_ATEs <- estimates_sdid_eq_tweights_ATEs[Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                                     N_treated = sum(N_treated))]
        temp_ATEs2 <- estimates_sdid_eq_tweights_ATEs[Cohort>=2 & Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                                                  N_treated = sum(N_treated))]    
        
        # formula: ATE * N_treated + weighted_ATE (which is sum of the same for other cohorts) / N_treated focal + N_treated other cohorts
        estimates_sdid_eq_tweights_jackknife[[cohort]][[var]] <- cbind(estimates_sdid_eq_tweights_jackknife[[cohort]][[var]],
                                                                       (estimates_sdid_eq_tweights_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs$weighted_ATE ) / (N_treated_temp + temp_ATEs$N_treated),
                                                                       (estimates_sdid_eq_tweights_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs2$weighted_ATE ) / (N_treated_temp + temp_ATEs2$N_treated))
        print(paste0("Jackknifing the SDID estimates for cohort ", cohort, " and var ", var, " completed"))
      }
    }
    stopCluster(cl=cl)
    
    # combine
    var_sdid_eq_tweights_jackknife_per_cohort <- vector("list", 9)
    var_sdid_eq_tweights_jackknife_5_cohorts <- as.list(numeric(9))
    var_sdid_eq_tweights_jackknife_4_cohorts <- as.list(numeric(9))
    for (var in 1:9){
      for (cohort in 1:5){
        var_sdid_eq_tweights_jackknife_per_cohort[[var]][[cohort]] <- ((estimates_sdid_eq_tweights_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated]-1)/estimates_sdid_eq_tweights_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated])*sum((estimates_sdid_eq_tweights_jackknife[[cohort]][[var]][, 1]-estimates_sdid_eq_tweights_ATEs[Cohort==cohort & DV==variables$Variable[var], ATE])^2)
        var_sdid_eq_tweights_jackknife_5_cohorts[[var]] <- var_sdid_eq_tweights_jackknife_5_cohorts[[var]] + ((sum(estimates_sdid_eq_tweights_ATEs[DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_eq_tweights_ATEs[DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_eq_tweights_jackknife[[cohort]][[var]][, 2]-estimates_sdid_eq_tweights_ATEs[DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        if (cohort!=1){
          var_sdid_eq_tweights_jackknife_4_cohorts[[var]] <- var_sdid_eq_tweights_jackknife_4_cohorts[[var]] + ((sum(estimates_sdid_eq_tweights_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_eq_tweights_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_eq_tweights_jackknife[[cohort]][[var]][, 3]-estimates_sdid_eq_tweights_ATEs[Cohort!=1 & DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        }
      }
    }
    
    # Create a summary table
    results_table_sdid_eq_tweights <- data.table(
      Variable = variables$Variable,
      Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_eq_tweights_ATEs[DV==x, ATE]*estimates_sdid_eq_tweights_ATEs[DV==x, N_treated])/sum(estimates_sdid_eq_tweights_ATEs[DV==x, N_treated])}, USE.NAMES=FALSE),
      Std.Error = sqrt(unlist(var_sdid_eq_tweights_jackknife_5_cohorts))
    )
    
    results_table_sdid_eq_tweights[, CI_low := Estimate - 1.96 * Std.Error]
    results_table_sdid_eq_tweights[, CI_high := Estimate + 1.96 * Std.Error]
  } # just to allow (un)folding the code
  
  # cohort 1
  results_table_sdid_cohort1 <- data.table(
    Variable = variables$Variable,
    Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_ATEs[DV==x&Cohort==1, ATE]*estimates_sdid_ATEs[DV==x&Cohort==1, N_treated])/sum(estimates_sdid_ATEs[DV==x&Cohort==1, N_treated])}, USE.NAMES=FALSE),
    Std.Error = sqrt(unlist(lapply(var_sdid_jackknife_per_cohort, function(x) x[[1]])))
  )
  
  results_table_sdid_cohort1[, CI_low := Estimate - 1.96 * Std.Error]
  results_table_sdid_cohort1[, CI_high := Estimate + 1.96 * Std.Error]
  
  # w/o cohort 1
  results_table_sdid_not_cohort1 <- data.table(
    Variable = variables$Variable,
    Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_ATEs[DV==x&Cohort!=1, ATE]*estimates_sdid_ATEs[DV==x&Cohort!=1, N_treated])/sum(estimates_sdid_ATEs[DV==x&Cohort!=1, N_treated])}, USE.NAMES=FALSE),
    Std.Error = sqrt(unlist(var_sdid_jackknife_4_cohorts))
  )
  
  results_table_sdid_not_cohort1[, CI_low := Estimate - 1.96 * Std.Error]
  results_table_sdid_not_cohort1[, CI_high := Estimate + 1.96 * Std.Error]
  
  # Estimate TWFE DID models for each variable
  if (TRUE==TRUE){
    feols_results <- lapply(1:5, function(cohort) {
      lapply(unique(dt_combined[[cohort]]$Variable), function(var) {
        data_subset <- dt_combined[[cohort]][Variable == var]
        data_subset[, treated_indicator := ifelse(group == "treated", 1, 0)]
        data_subset[, post_indicator := ifelse(period == "post", 1, 0)]
        model <- feols(Y ~ treated_indicator:post_indicator | unit + time, data = data_subset, vcov="twoway")
        cat("\nCohort:", cohort, "\n", "\nVariable:", var, "\n")
        #print(summary(model))
        return(model)
      })
    })
    
    # Combine
    N_treated_var_unlisted <- matrix(unlist(N_treated_var), nrow=5, byrow=TRUE)
    weights_treated <- N_treated_var_unlisted/matrix(rep(colSums(N_treated_var_unlisted), 5), nrow=5, byrow=TRUE)
    estimate_matrix <- do.call(rbind, lapply(feols_results, function(model_list) {
      sapply(model_list, function(model) model$coeftable[1,1])
    }))
    se_matrix <- do.call(rbind, lapply(feols_results, function(model_list) {
      sapply(model_list, function(model) model$coeftable[1,2])
    }))
    estimates_twfe_did_weighted_aggregate <- cbind(colSums(estimate_matrix*weights_treated),
                                                   sqrt(colSums((se_matrix^2)*(weights_treated^2))))
    
    # Create a summary table
    results_table_did <- data.table(
      Variable = variables$Variable,
      Estimate = estimates_twfe_did_weighted_aggregate[,1],
      Std.Error = estimates_twfe_did_weighted_aggregate[,2]
    )
    
    results_table_did[, CI_low := Estimate - 1.96 * Std.Error]
    results_table_did[, CI_high := Estimate + 1.96 * Std.Error]
    
    # calculate a p-value based on the normal distribution
    results_table_did[, p.value := 2 * (1 - pnorm(abs(Estimate / Std.Error)))]
    
    # Print the summary table
    #cat("\nSummary of TWFE DID Results:\n")
    #print(results_table_did)
  }
  
  # Results table
  results_table_RC <- data.table(
    Variable = variables$Variable,
    Focal_Estimate = results_table_sdid$Estimate,
    Focal_CI_low = results_table_sdid$CI_low,
    Focal_CI_high = results_table_sdid$CI_high,
    LN_Estimate = results_table_sdid_LN$Estimate,
    LN_CI_low = results_table_sdid_LN$CI_low,
    LN_CI_high = results_table_sdid_LN$CI_high,
    x26_Estimate = results_table_sdid_26$Estimate,
    x26_CI_low = results_table_sdid_26$CI_low,
    x26_CI_high = results_table_sdid_26$CI_high,
    x13_Estimate = results_table_sdid_13$Estimate,
    x13_CI_low = results_table_sdid_13$CI_low,
    x13_CI_high = results_table_sdid_13$CI_high,
    Cohort1_only_Estimate = results_table_sdid_cohort1$Estimate,
    Cohort1_only_CI_low = results_table_sdid_cohort1$CI_low,
    Cohort1_only_CI_high = results_table_sdid_cohort1$CI_high,
    Not_cohort1_Estimate = results_table_sdid_not_cohort1$Estimate,
    Not_cohort1_CI_low = results_table_sdid_not_cohort1$CI_low,
    Not_cohort1_CI_high = results_table_sdid_not_cohort1$CI_high,
    DID_Estimate = results_table_did$Estimate,
    DID_CI_low = results_table_did$CI_low,
    DID_CI_high = results_table_did$CI_high,
    Eq_tweights_Estimate = results_table_sdid_eq_tweights$Estimate,
    Eq_tweights_CI_low = results_table_sdid_eq_tweights$CI_low,
    Eq_tweights_CI_high = results_table_sdid_eq_tweights$CI_high
  )
  
  # Formatted table
  table_8_paper <- data.table(
    Variable = results_table_RC$Variable,
    Focal = paste0(round(results_table_RC$Focal_Estimate, 2)," [", round(results_table_RC$Focal_CI_low, 2), ", ", round(results_table_RC$Focal_CI_high,2), "] "),
    LN = paste0(round(results_table_RC$LN_Estimate, 2)," [", round(results_table_RC$LN_CI_low, 2), ", ", round(results_table_RC$LN_CI_high,2), "] "),
    x26 = paste0(round(results_table_RC$x26_Estimate, 2)," [", round(results_table_RC$x26_CI_low, 2), ", ", round(results_table_RC$x26_CI_high,2), "] "),
    x13 = paste0(round(results_table_RC$x13_Estimate, 2)," [", round(results_table_RC$x13_CI_low, 2), ", ", round(results_table_RC$x13_CI_high,2), "] "),
    Cohort1_only = paste0(round(results_table_RC$Cohort1_only_Estimate, 2)," [", round(results_table_RC$Cohort1_only_CI_low, 2), ", ", round(results_table_RC$Cohort1_only_CI_high,2), "] "),
    Not_cohort1 = paste0(round(results_table_RC$Not_cohort1_Estimate, 2)," [", round(results_table_RC$Not_cohort1_CI_low, 2), ", ", round(results_table_RC$Not_cohort1_CI_high,2), "] "),
    DID = paste0(round(results_table_RC$DID_Estimate, 2)," [", round(results_table_RC$DID_CI_low, 2), ", ", round(results_table_RC$DID_CI_high,2), "] "),
    Eq_tweights = paste0(round(results_table_RC$Eq_tweights_Estimate, 2)," [", round(results_table_RC$Eq_tweights_CI_low, 2), ", ", round(results_table_RC$Eq_tweights_CI_high,2), "] ")
  )
  
  # print the results
  cat("\nSummary of RC Results:\n")
  print(table_8_paper)
}


if (table_9 == TRUE){
  ## subset hh analysis
  dt_combined <- lapply(dt_combined, function(x)
    x[, treat_post := as.numeric(group=="treated" & period=="post")]
  )
  
  # create an empty Y_s list
  Ys_com_cohorts <- list()
  Ys_alw_cohorts <- list()
  Ys_def_cohorts <- list()
  T0s_com_cohorts <- list()
  T0s_alw_cohorts <- list()
  T0s_def_cohorts <- list()
  N0s_com_cohorts <- list()
  N0s_alw_cohorts <- list()
  N0s_def_cohorts <- list()
  
  ### now loop over all the other variables
  for (cohort in 1:5) {
    Ys_com_cohorts[[cohort]] <- list()
    Ys_alw_cohorts[[cohort]] <- list()
    Ys_def_cohorts[[cohort]] <- list()
    T0s_com_cohorts[[cohort]] <- list()
    T0s_alw_cohorts[[cohort]] <- list()
    T0s_def_cohorts[[cohort]] <- list()
    N0s_com_cohorts[[cohort]] <- list()
    N0s_alw_cohorts[[cohort]] <- list()
    N0s_def_cohorts[[cohort]] <- list()
    for (var in 1:9){
      ## randomly sample from treated groups to create compliers, always takers, and defiers
      dt_temp <- dt_combined[[cohort]][Variable==variables[var,1]]                # select single variable
      treated_hhs <- unique(dt_temp[group=="treated", unit])          # get treated households
      if (var %in% uncond_vars){
        compliers <- sample(treated_hhs, 
                            round(compliers_uncond*length(treated_hhs))) # sample compliers
        always_takers <- sample(setdiff(treated_hhs, compliers), 
                                round((always_takers_uncond / (1 - compliers_uncond))*length(treated_hhs))) # sample always takers from remaining households (rescale sample rate)
      } else {
        compliers <- sample(treated_hhs, 
                            round(compliers_cond*length(treated_hhs)))
        always_takers <- sample(setdiff(treated_hhs, compliers), 
                                round((always_takers_cond / (1 - compliers_cond))*length(treated_hhs)))
      }
      defiers <- setdiff(treated_hhs, c(compliers, always_takers)) # remaining households are defiers
      
      ## prepare data for SynthDID on subgroup
      setup_compliers <- panel.matrices(dt_temp[unit %in% compliers | group == "control", c("unit","time","Y","treat_post")], time='time')
      setup_defiers <- panel.matrices(dt_temp[unit %in% defiers | group == "control", c("unit","time","Y","treat_post")], time='time')
      setup_always_takers <- panel.matrices(dt_temp[unit %in% always_takers | group == "control", c("unit","time","Y","treat_post")], time='time')
      Ys_com_cohorts[[cohort]][[var]] <- setup_compliers$Y  
      Ys_def_cohorts[[cohort]][[var]] <- setup_defiers$Y  
      Ys_alw_cohorts[[cohort]][[var]] <- setup_always_takers$Y  
      T0s_com_cohorts[[cohort]][[var]] <- setup_compliers$T0
      T0s_def_cohorts[[cohort]][[var]] <- setup_defiers$T0
      T0s_alw_cohorts[[cohort]][[var]] <- setup_always_takers$T0
      N0s_com_cohorts[[cohort]][[var]] <- setup_compliers$N0 
      N0s_def_cohorts[[cohort]][[var]] <- setup_defiers$N0 
      N0s_alw_cohorts[[cohort]][[var]] <- setup_always_takers$N0 
      
      cat("\nCohort:", cohort, "\n", "\nVariable:", var, "\n")
    }
  }
  
  # Compliers
  if (TRUE==TRUE) {
    # estimate
    estimates_sdid_com <- list()
    for (cohort in 1:5){
      estimates_sdid_com[[cohort]] <- list()
      for (var in 1:9){
        estimates_sdid_com[[cohort]][[var]] <- synthdid_estimate(Ys_com_cohorts[[cohort]][[var]], N0s_com_cohorts[[cohort]][[var]], T0s_com_cohorts[[cohort]][[var]])
      }
    }
    
    # jackknife
    # setup
    estimates_sdid_com_ATEs <- NULL
    for (cohort in 1:5){
      for (var in 1:9){
        estimates_sdid_com_ATEs <- rbind(estimates_sdid_com_ATEs, c(estimates_sdid_com[[cohort]][[var]][[1]], nrow(Ys_com_cohorts[[cohort]][[var]]), nrow(Ys_com_cohorts[[cohort]][[var]])-N0s_com_cohorts[[cohort]][[var]], variables$Variable[var], cohort))
      }
    }
    estimates_sdid_com_ATEs <- data.table(estimates_sdid_com_ATEs)
    colnames(estimates_sdid_com_ATEs) <- c("ATE", "N_obs", "N_treated", "DV", "Cohort")
    estimates_sdid_com_ATEs[, ":="(ATE = as.numeric(ATE),
                                   N_obs = as.numeric(N_obs),
                                   N_treated = as.numeric(N_treated))]
    
    # Clark et al. (2022) jackknife
    cl <- parallel::makeCluster(15)
    doParallel::registerDoParallel(cl)
    estimates_sdid_com_jackknife <- vector("list", 5) ## we will fill in the jackknifed ATTs for the focal cohort, the weighted version across the 5 cohorts, and the weighted version across the 4 cohorts (all but Amsterdam) (3 columns)
    for (cohort in 1:5){
      estimates_sdid_com_jackknife[[cohort]] <- vector("list", 9)
      for (var in 1:9){
        omegas  <- attr(estimates_sdid_com[[cohort]][[var]], "weights")$omega
        lambdas <- attr(estimates_sdid_com[[cohort]][[var]], "weights")$lambda
        out <- foreach(i=1:nrow(Ys_com_cohorts[[cohort]][[var]]), .combine=rbind, .packages=c("synthdid")) %dopar% { # for (i in 1:nrow(Ys_com_cohorts[[cohort]][[var]])){
          if (i <= N0s_com_cohorts[[cohort]][[var]]){
            c(synthdid_estimate(Ys_com_cohorts[[cohort]][[var]][-i,], 
                                N0s_com_cohorts[[cohort]][[var]]-1, 
                                T0s_com_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas[-i]/sum(omegas[-i]), 
                                               lambda = lambdas))[[1]],
              nrow(Ys_com_cohorts[[cohort]][[var]]) - N0s_com_cohorts[[cohort]][[var]])
          } else {
            c(estimates_sdid_com_jackknife[[cohort]][[var]], 
              synthdid_estimate(Ys_com_cohorts[[cohort]][[var]][-i,], 
                                N0s_com_cohorts[[cohort]][[var]], 
                                T0s_com_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas, 
                                               lambda = lambdas))[[1]],
              nrow(Ys_com_cohorts[[cohort]][[var]]) - N0s_com_cohorts[[cohort]][[var]] - 1)
          }
        }
        estimates_sdid_com_jackknife[[cohort]][[var]] <- out[,1]
        N_treated_temp <- out[,2]
        
        # the ATEs for the other cohorts are stable and can be precalculated
        # we need the N_treated for the other cohorts and the ATEs for the other cohorts
        temp_ATEs <- estimates_sdid_com_ATEs[Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                             N_treated = sum(N_treated))]
        temp_ATEs2 <- estimates_sdid_com_ATEs[Cohort>=2 & Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                                          N_treated = sum(N_treated))]    
        
        
        # formula: ATE * N_treated + weighted_ATE (which is sum of the same for other cohorts) / N_treated focal + N_treated other cohorts
        estimates_sdid_com_jackknife[[cohort]][[var]] <- cbind(estimates_sdid_com_jackknife[[cohort]][[var]],
                                                               (estimates_sdid_com_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs$weighted_ATE ) / (N_treated_temp + temp_ATEs$N_treated),
                                                               (estimates_sdid_com_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs2$weighted_ATE ) / (N_treated_temp + temp_ATEs2$N_treated))
        print(paste0("Jackknifing the SDID estimates for cohort ", cohort, " and var ", var, " completed"))
      }
    }
    stopCluster(cl=cl)
    
    # combine
    var_sdid_com_jackknife_per_cohort <- vector("list", 9)
    var_sdid_com_jackknife_5_cohorts <- as.list(numeric(9))
    var_sdid_com_jackknife_4_cohorts <- as.list(numeric(9))
    for (var in 1:9){
      for (cohort in 1:5){
        var_sdid_com_jackknife_per_cohort[[var]][[cohort]] <- ((estimates_sdid_com_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated]-1)/estimates_sdid_com_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated])*sum((estimates_sdid_com_jackknife[[cohort]][[var]][, 1]-estimates_sdid_com_ATEs[Cohort==cohort & DV==variables$Variable[var], ATE])^2)
        var_sdid_com_jackknife_5_cohorts[[var]] <- var_sdid_com_jackknife_5_cohorts[[var]] + ((sum(estimates_sdid_com_ATEs[DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_com_ATEs[DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_com_jackknife[[cohort]][[var]][, 2]-estimates_sdid_com_ATEs[DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        if (cohort!=1){
          var_sdid_com_jackknife_4_cohorts[[var]] <- var_sdid_com_jackknife_4_cohorts[[var]] + ((sum(estimates_sdid_com_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_com_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_com_jackknife[[cohort]][[var]][, 3]-estimates_sdid_com_ATEs[Cohort!=1 & DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        }
      }
    }
    
    # Create a summary table
    results_table_sdid_com <- data.table(
      Variable = variables$Variable,
      Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_com_ATEs[DV==x, ATE]*estimates_sdid_com_ATEs[DV==x, N_treated])/sum(estimates_sdid_com_ATEs[DV==x, N_treated])}, USE.NAMES=FALSE),
      Std.Error = sqrt(unlist(var_sdid_com_jackknife_5_cohorts))
    )
    
    results_table_sdid_com[, CI_low := Estimate - 1.96 * Std.Error]
    results_table_sdid_com[, CI_high := Estimate + 1.96 * Std.Error]
    
    # calculate a p-value based on the normal distribution
    results_table_sdid_com[, p.value := 2 * (1 - pnorm(abs(Estimate / Std.Error)))]
  } # just to allow (un)folding the code
  
  # Defiers
  if (TRUE==TRUE) {
    # estimate
    estimates_sdid_def <- list()
    for (cohort in 1:5){
      estimates_sdid_def[[cohort]] <- list()
      for (var in 1:9){
        estimates_sdid_def[[cohort]][[var]] <- synthdid_estimate(Ys_def_cohorts[[cohort]][[var]], N0s_def_cohorts[[cohort]][[var]], T0s_def_cohorts[[cohort]][[var]])
      }
    }
    
    # jackknife
    # setup
    estimates_sdid_def_ATEs <- NULL
    for (cohort in 1:5){
      for (var in 1:9){
        estimates_sdid_def_ATEs <- rbind(estimates_sdid_def_ATEs, c(estimates_sdid_def[[cohort]][[var]][[1]], nrow(Ys_def_cohorts[[cohort]][[var]]), nrow(Ys_def_cohorts[[cohort]][[var]])-N0s_def_cohorts[[cohort]][[var]], variables$Variable[var], cohort))
      }
    }
    estimates_sdid_def_ATEs <- data.table(estimates_sdid_def_ATEs)
    colnames(estimates_sdid_def_ATEs) <- c("ATE", "N_obs", "N_treated", "DV", "Cohort")
    estimates_sdid_def_ATEs[, ":="(ATE = as.numeric(ATE),
                                   N_obs = as.numeric(N_obs),
                                   N_treated = as.numeric(N_treated))]
    
    # Clark et al. (2022) jackknife
    cl <- parallel::makeCluster(15)
    doParallel::registerDoParallel(cl)
    estimates_sdid_def_jackknife <- vector("list", 5) ## we will fill in the jackknifed ATTs for the focal cohort, the weighted version across the 5 cohorts, and the weighted version across the 4 cohorts (all but Amsterdam) (3 columns)
    for (cohort in 1:5){
      estimates_sdid_def_jackknife[[cohort]] <- vector("list", 9)
      for (var in 1:9){
        omegas  <- attr(estimates_sdid_def[[cohort]][[var]], "weights")$omega
        lambdas <- attr(estimates_sdid_def[[cohort]][[var]], "weights")$lambda
        out <- foreach(i=1:nrow(Ys_def_cohorts[[cohort]][[var]]), .combine=rbind, .packages=c("synthdid")) %dopar% { # for (i in 1:nrow(Ys_def_cohorts[[cohort]][[var]])){
          if (i <= N0s_def_cohorts[[cohort]][[var]]){
            c(synthdid_estimate(Ys_def_cohorts[[cohort]][[var]][-i,], 
                                N0s_def_cohorts[[cohort]][[var]]-1, 
                                T0s_def_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas[-i]/sum(omegas[-i]), 
                                               lambda = lambdas))[[1]],
              nrow(Ys_def_cohorts[[cohort]][[var]]) - N0s_def_cohorts[[cohort]][[var]])
          } else {
            c(estimates_sdid_def_jackknife[[cohort]][[var]], 
              synthdid_estimate(Ys_def_cohorts[[cohort]][[var]][-i,], 
                                N0s_def_cohorts[[cohort]][[var]], 
                                T0s_def_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas, 
                                               lambda = lambdas))[[1]],
              nrow(Ys_def_cohorts[[cohort]][[var]]) - N0s_def_cohorts[[cohort]][[var]] - 1)
          }
        }
        estimates_sdid_def_jackknife[[cohort]][[var]] <- out[,1]
        N_treated_temp <- out[,2]
        
        # the ATEs for the other cohorts are stable and can be precalculated
        # we need the N_treated for the other cohorts and the ATEs for the other cohorts
        temp_ATEs <- estimates_sdid_def_ATEs[Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                             N_treated = sum(N_treated))]
        temp_ATEs2 <- estimates_sdid_def_ATEs[Cohort>=2 & Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                                          N_treated = sum(N_treated))]    
        
        
        # formula: ATE * N_treated + weighted_ATE (which is sum of the same for other cohorts) / N_treated focal + N_treated other cohorts
        estimates_sdid_def_jackknife[[cohort]][[var]] <- cbind(estimates_sdid_def_jackknife[[cohort]][[var]],
                                                               (estimates_sdid_def_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs$weighted_ATE ) / (N_treated_temp + temp_ATEs$N_treated),
                                                               (estimates_sdid_def_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs2$weighted_ATE ) / (N_treated_temp + temp_ATEs2$N_treated))
        print(paste0("Jackknifing the SDID estimates for cohort ", cohort, " and var ", var, " completed"))
      }
    }
    stopCluster(cl=cl)
    
    # combine
    var_sdid_def_jackknife_per_cohort <- vector("list", 9)
    var_sdid_def_jackknife_5_cohorts <- as.list(numeric(9))
    var_sdid_def_jackknife_4_cohorts <- as.list(numeric(9))
    for (var in 1:9){
      for (cohort in 1:5){
        var_sdid_def_jackknife_per_cohort[[var]][[cohort]] <- ((estimates_sdid_def_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated]-1)/estimates_sdid_def_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated])*sum((estimates_sdid_def_jackknife[[cohort]][[var]][, 1]-estimates_sdid_def_ATEs[Cohort==cohort & DV==variables$Variable[var], ATE])^2)
        var_sdid_def_jackknife_5_cohorts[[var]] <- var_sdid_def_jackknife_5_cohorts[[var]] + ((sum(estimates_sdid_def_ATEs[DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_def_ATEs[DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_def_jackknife[[cohort]][[var]][, 2]-estimates_sdid_def_ATEs[DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        if (cohort!=1){
          var_sdid_def_jackknife_4_cohorts[[var]] <- var_sdid_def_jackknife_4_cohorts[[var]] + ((sum(estimates_sdid_def_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_def_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_def_jackknife[[cohort]][[var]][, 3]-estimates_sdid_def_ATEs[Cohort!=1 & DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        }
      }
    }
    
    # Create a summary table
    results_table_sdid_def <- data.table(
      Variable = variables$Variable,
      Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_def_ATEs[DV==x, ATE]*estimates_sdid_def_ATEs[DV==x, N_treated])/sum(estimates_sdid_def_ATEs[DV==x, N_treated])}, USE.NAMES=FALSE),
      Std.Error = sqrt(unlist(var_sdid_def_jackknife_5_cohorts))
    )
    
    results_table_sdid_def[, CI_low := Estimate - 1.96 * Std.Error]
    results_table_sdid_def[, CI_high := Estimate + 1.96 * Std.Error]
    
    # calculate a p-value based on the normal distribution
    results_table_sdid_def[, p.value := 2 * (1 - pnorm(abs(Estimate / Std.Error)))]
  } # just to allow (un)folding the code
  
  # Always takers
  if (TRUE==TRUE) {
    # estimate
    estimates_sdid_alw <- list()
    for (cohort in 1:5){
      estimates_sdid_alw[[cohort]] <- list()
      for (var in 1:9){
        estimates_sdid_alw[[cohort]][[var]] <- synthdid_estimate(Ys_alw_cohorts[[cohort]][[var]], N0s_alw_cohorts[[cohort]][[var]], T0s_alw_cohorts[[cohort]][[var]])
      }
    }
    
    # jackknife
    # setup
    estimates_sdid_alw_ATEs <- NULL
    for (cohort in 1:5){
      for (var in 1:9){
        estimates_sdid_alw_ATEs <- rbind(estimates_sdid_alw_ATEs, c(estimates_sdid_alw[[cohort]][[var]][[1]], nrow(Ys_alw_cohorts[[cohort]][[var]]), nrow(Ys_alw_cohorts[[cohort]][[var]])-N0s_alw_cohorts[[cohort]][[var]], variables$Variable[var], cohort))
      }
    }
    estimates_sdid_alw_ATEs <- data.table(estimates_sdid_alw_ATEs)
    colnames(estimates_sdid_alw_ATEs) <- c("ATE", "N_obs", "N_treated", "DV", "Cohort")
    estimates_sdid_alw_ATEs[, ":="(ATE = as.numeric(ATE),
                                   N_obs = as.numeric(N_obs),
                                   N_treated = as.numeric(N_treated))]
    
    # Clark et al. (2022) jackknife
    cl <- parallel::makeCluster(15)
    doParallel::registerDoParallel(cl)
    estimates_sdid_alw_jackknife <- vector("list", 5) ## we will fill in the jackknifed ATTs for the focal cohort, the weighted version across the 5 cohorts, and the weighted version across the 4 cohorts (all but Amsterdam) (3 columns)
    for (cohort in 1:5){
      estimates_sdid_alw_jackknife[[cohort]] <- vector("list", 9)
      for (var in 1:9){
        omegas  <- attr(estimates_sdid_alw[[cohort]][[var]], "weights")$omega
        lambdas <- attr(estimates_sdid_alw[[cohort]][[var]], "weights")$lambda
        out <- foreach(i=1:nrow(Ys_alw_cohorts[[cohort]][[var]]), .combine=rbind, .packages=c("synthdid")) %dopar% { # for (i in 1:nrow(Ys_alw_cohorts[[cohort]][[var]])){
          if (i <= N0s_alw_cohorts[[cohort]][[var]]){
            c(synthdid_estimate(Ys_alw_cohorts[[cohort]][[var]][-i,], 
                                N0s_alw_cohorts[[cohort]][[var]]-1, 
                                T0s_alw_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas[-i]/sum(omegas[-i]), 
                                               lambda = lambdas))[[1]],
              nrow(Ys_alw_cohorts[[cohort]][[var]]) - N0s_alw_cohorts[[cohort]][[var]])
          } else {
            c(estimates_sdid_alw_jackknife[[cohort]][[var]], 
              synthdid_estimate(Ys_alw_cohorts[[cohort]][[var]][-i,], 
                                N0s_alw_cohorts[[cohort]][[var]], 
                                T0s_alw_cohorts[[cohort]][[var]], 
                                weights = list(omega = omegas, 
                                               lambda = lambdas))[[1]],
              nrow(Ys_alw_cohorts[[cohort]][[var]]) - N0s_alw_cohorts[[cohort]][[var]] - 1)
          }
        }
        estimates_sdid_alw_jackknife[[cohort]][[var]] <- out[,1]
        N_treated_temp <- out[,2]
        
        # the ATEs for the other cohorts are stable and can be precalculated
        # we need the N_treated for the other cohorts and the ATEs for the other cohorts
        temp_ATEs <- estimates_sdid_alw_ATEs[Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                             N_treated = sum(N_treated))]
        temp_ATEs2 <- estimates_sdid_alw_ATEs[Cohort>=2 & Cohort!=cohort & DV==variables$Variable[var], .(weighted_ATE = sum(ATE * N_treated),
                                                                                                          N_treated = sum(N_treated))]    
        
        # formula: ATE * N_treated + weighted_ATE (which is sum of the same for other cohorts) / N_treated focal + N_treated other cohorts
        estimates_sdid_alw_jackknife[[cohort]][[var]] <- cbind(estimates_sdid_alw_jackknife[[cohort]][[var]],
                                                               (estimates_sdid_alw_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs$weighted_ATE ) / (N_treated_temp + temp_ATEs$N_treated),
                                                               (estimates_sdid_alw_jackknife[[cohort]][[var]] * N_treated_temp + temp_ATEs2$weighted_ATE ) / (N_treated_temp + temp_ATEs2$N_treated))
        print(paste0("Jackknifing the SDID estimates for cohort ", cohort, " and var ", var, " completed"))
      }
    }
    stopCluster(cl=cl)
    
    # combine
    var_sdid_alw_jackknife_per_cohort <- vector("list", 9)
    var_sdid_alw_jackknife_5_cohorts <- as.list(numeric(9))
    var_sdid_alw_jackknife_4_cohorts <- as.list(numeric(9))
    for (var in 1:9){
      for (cohort in 1:5){
        var_sdid_alw_jackknife_per_cohort[[var]][[cohort]] <- ((estimates_sdid_alw_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated]-1)/estimates_sdid_alw_ATEs[Cohort==cohort & DV==variables$Variable[var], N_treated])*sum((estimates_sdid_alw_jackknife[[cohort]][[var]][, 1]-estimates_sdid_alw_ATEs[Cohort==cohort & DV==variables$Variable[var], ATE])^2)
        var_sdid_alw_jackknife_5_cohorts[[var]] <- var_sdid_alw_jackknife_5_cohorts[[var]] + ((sum(estimates_sdid_alw_ATEs[DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_alw_ATEs[DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_alw_jackknife[[cohort]][[var]][, 2]-estimates_sdid_alw_ATEs[DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        if (cohort!=1){
          var_sdid_alw_jackknife_4_cohorts[[var]] <- var_sdid_alw_jackknife_4_cohorts[[var]] + ((sum(estimates_sdid_alw_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated])-1)/sum(estimates_sdid_alw_ATEs[Cohort!=1 & DV==variables$Variable[var], N_treated]))*sum((estimates_sdid_alw_jackknife[[cohort]][[var]][, 3]-estimates_sdid_alw_ATEs[Cohort!=1 & DV==variables$Variable[var], .(ATE_weighted = sum(ATE*N_treated)/sum(N_treated))]$ATE_weighted)^2)
        }
      }
    }
    
    # Create a summary table
    results_table_sdid_alw <- data.table(
      Variable = variables$Variable,
      Estimate = sapply(variables$Variable, function(x){sum(estimates_sdid_alw_ATEs[DV==x, ATE]*estimates_sdid_alw_ATEs[DV==x, N_treated])/sum(estimates_sdid_alw_ATEs[DV==x, N_treated])}, USE.NAMES=FALSE),
      Std.Error = sqrt(unlist(var_sdid_alw_jackknife_5_cohorts))
    )
    
    results_table_sdid_alw[, CI_low := Estimate - 1.96 * Std.Error]
    results_table_sdid_alw[, CI_high := Estimate + 1.96 * Std.Error]
    
    # calculate a p-value based on the normal distribution
    results_table_sdid_alw[, p.value := 2 * (1 - pnorm(abs(Estimate / Std.Error)))]
  } # just to allow (un)folding the code
  
  # Results table
  results_table_subgroups <- data.table(
    Variable = variables$Variable,
    Com_Estimate = results_table_sdid_com$Estimate,
    Com_CI_low = results_table_sdid_com$CI_low,
    Com_CI_high = results_table_sdid_com$CI_high,
    Def_Estimate = results_table_sdid_def$Estimate,
    Def_CI_low = results_table_sdid_def$CI_low,
    Def_CI_high = results_table_sdid_def$CI_high,
    Alw_Estimate = results_table_sdid_alw$Estimate,
    Alw_CI_low = results_table_sdid_alw$CI_low,
    Alw_CI_high = results_table_sdid_alw$CI_high
  )
  
  # Formatted table
  table_9_paper <- data.table(
    Variable = results_table_RC$Variable,
    Compliers = paste0(round(results_table_sdid_com$Estimate, 2)," [", round(results_table_sdid_com$CI_low, 2), ", ", round(results_table_sdid_com$CI_high,2), "] "),
    Defiers = paste0(round(results_table_sdid_def$Estimate, 2)," [", round(results_table_sdid_def$CI_low, 2), ", ", round(results_table_sdid_def$CI_high,2), "] "),
    Always_takers = paste0(round(results_table_sdid_alw$Estimate, 2)," [", round(results_table_sdid_alw$CI_low, 2), ", ", round(results_table_sdid_alw$CI_high,2), "] ")
  )
  
  # print the results
  cat("\nSummary of Subgroup Analysis Results:\n")
  print(table_9_paper)
}


if (table_10 == TRUE) {
  model_results <- list()
  for (group in c("defiers", "compliers", "always_takers")) {
    # Fit logistic regression model
    model_results[[group]] <- glm(y ~ ., data = table_10_data[[group]], family = binomial)
  }
  
  # Results table
  results_table_optin_choice <- data.table(
    Variable = c("Intercept", colnames((table_10_data)[[1]])[-1]),
    Def_Estimate = coef(model_results$defiers),
    Def_Std.Error = sqrt(diag(vcov(model_results$defiers))),
    Def_Stars = ifelse(summary(model_results$defiers)$coefficients[,4] < 0.01, "**", ifelse(summary(model_results$defiers)$coefficients[,4] < 0.05, "*", "")),
    Com_Estimate = coef(model_results$compliers),
    Com_Std.Error = sqrt(diag(vcov(model_results$compliers))),
    Com_Stars = ifelse(summary(model_results$compliers)$coefficients[,4] < 0.01, "**", ifelse(summary(model_results$compliers)$coefficients[,4] < 0.05, "*", "")),
    Alw_Estimate = coef(model_results$always_takers),
    Alw_Std.Error = sqrt(diag(vcov(model_results$always_takers))),
    Alw_Stars = ifelse(summary(model_results$always_takers)$coefficients[,4] < 0.01, "**", ifelse(summary(model_results$always_takers)$coefficients[,4] < 0.05, "*", ""))
  )
  
  # Formatted table with estimate (2 digits), standard error (2 digits) in parentheses, and stars:
  table_10_paper <- data.table(
    Variable = results_table_optin_choice$Variable,
    Defiers = paste0(round(results_table_optin_choice$Def_Estimate, 2), " (", round(results_table_optin_choice$Def_Std.Error, 2), ") ", results_table_optin_choice$Def_Stars),
    Compliers = paste0(round(results_table_optin_choice$Com_Estimate, 2), " (", round(results_table_optin_choice$Com_Std.Error, 2), ") ", results_table_optin_choice$Com_Stars),
    Always_takers = paste0(round(results_table_optin_choice$Alw_Estimate, 2), " (", round(results_table_optin_choice$Alw_Std.Error, 2), ") ", results_table_optin_choice$Alw_Stars)
  )
  table_10_paper <- rbind(table_10_paper[2:24,], table_10_paper[1,])
  
  rm(results_table_optin_choice, model_results)
  
  # print the results
  cat("\nSummary of Opt-In Choice Results:\n")
  cat("\n(Note that we cannot give the distributions for all these
          detailed households characteristics per our NDA
          so we simulated 23 normal variables here.
          This means that the estimates and the significance
          levels are different. The code is meant to show how
          the analysis is done.)\n\n")
  print(table_10_paper)
}
