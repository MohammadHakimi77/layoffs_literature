#############################
##### SETUP SYNTHETIC DATA
#############################

# Setup parameters
N_treated <- list(174,293,183,29,213) # from Table 4
N_control <- list(7336,7001,6027,5971,5968) # from Table 4
T <- 104 # number of time periods
pre_periods <- 1:52 # number of pre-periods
post_periods <- 53:104 # number of post-periods
uncond_vars <- c(1,2,5,8,9) # variables that are always observed
cond_vars <- c(3,4,6,7) # variables that are observed conditionally

ratio_cond_to_total <- 361 / 982 # ratio of households for which conditional variables are observed (see Table 5)

compliers_uncond <- 344 / (344 + 372 + 176) # share across all cohorts (see Table 9)
defiers_uncond <- 372 / (344 + 372 + 176) # share across all cohorts (see Table 9)
always_takers_uncond <- 176 / (344 + 372 + 176) # share across all cohorts (see Table 9)

compliers_cond <- 136 / (136 + 168 + 57) # share across all cohorts (see Table 9)
defiers_cond <- 168 / (136 + 168 + 57) # share across all cohorts (see Table 9)
always_takers_cond <- 57 / (136 + 168 + 57) # share across all cohorts (see Table 9)


# Function to generate data for a single variable
generate_variable_data <- function(N_treated, N_control, N_treated_cumsum, N_control_cumsum,
                                   T, pre_NEperiods, post_periods, 
                                   mu_treated_pre, mu_treated_post, 
                                   mu_control_pre, mu_control_post, 
                                   sd_treated_pre, sd_treated_post, 
                                   sd_control_pre, sd_control_post, 
                                   correlation=0.8) {
  
  total_units <- N_treated + N_control
  
  rho <- 200/total_units         # common correlation between units (which allows for correlated time series as per table 6)
  
  # Generate errors using the factor model representation
  common_shocks <- rnorm(T)  # For each time point, generate one common shock:
  common_matrix <- matrix(common_shocks, nrow = T, ncol = total_units)  # Create a matrix where each row (time point) has the common shock repeated for all units
  independent_shocks <- matrix(rnorm(T * total_units), nrow = T, ncol = total_units)  # Generate independent shocks for each unit at each time point
  errors <- sqrt(rho) * common_matrix + sqrt(1 - rho) * independent_shocks  # Combine to form the error terms
  
  # Simulate the AR(1) processes
  Y <- matrix(0, nrow = T, ncol = total_units)
  Y[1, ] <- errors[1, ]  # initial state for each unit
  
  for (t in 2:T) {
    Y[t, ] <- correlation * Y[t - 1, ] + errors[t, ]
  }
  Y_treated <- t(Y[, 1:N_treated])
  Y_control <- t(Y[, (N_treated+1):total_units])
  
  #combine data into a table
  dt <- data.table(
    unit = c(rep(paste0("treated_", 1:N_treated), each = T),
             rep(paste0("control_", 1:N_control), each = T)),
    time = rep(1:T, N_treated + N_control),
    Y = c(as.vector(t(Y_treated)), as.vector(t(Y_control))),
    group = c(rep("treated", N_treated*T), rep("control", N_control*T))
  )
  dt[, period := ifelse(time %in% pre_periods, "pre", "post")]
  
  # Partial adjustments to ensure that the means and standard deviations match those in table 2
  adjust_mean_and_sd <- function(DT, grp, per, target_mu, target_sd) {
    current_mu <- DT[group == grp & period == per, mean(Y)]
    current_sd <- DT[group == grp & period == per, sd(Y)]
    DT[group == grp & period == per, Y := (Y - current_mu) / current_sd * target_sd + target_mu]
  }
  
  adjust_mean_and_sd(dt, "treated", "pre", mu_treated_pre, sd_treated_pre)
  adjust_mean_and_sd(dt, "treated", "post", mu_treated_post, sd_treated_post)
  adjust_mean_and_sd(dt, "control", "pre", mu_control_pre, sd_control_pre)
  adjust_mean_and_sd(dt, "control", "post", mu_control_post, sd_control_post)
  
  return(dt)
}

N_treated_cond <- lapply(N_treated, function(x) round(x * ratio_cond_to_total))
N_control_cond <- lapply(N_control, function(x) round(x * ratio_cond_to_total))
N_treated_var <- mapply(function(x, y) c(x,x,y,y,x,y,y,x,x), N_treated, N_treated_cond, SIMPLIFY=FALSE)
N_control_var <- mapply(function(x, y) c(x,x,y,y,x,y,y,x,x), N_control, N_control_cond, SIMPLIFY=FALSE)

# Define the variables and their means and SDs (see Table 2)
variables <- data.frame(
  Variable = c(
    "Total_grocery_expenditure",
    "Total_units_purchased",
    "Share_private_labels",
    "Share_purchases_promotion",
    "Number_shopping_trips",
    "Number_different_retail_chains",
    "Trip_share_HDs_vs_traditional",
    "Grocery_expenditure_primary_chain",
    "Number_shopping_trips_to_primary_chain"
  ),
  Mean_Treated_Pre = c(55.08, 45.02, 53.71, 21.58, 2.59, 1.96, 17.55, 37.44, 1.49),
  SD_Treated_Pre = c(40.58, 35.66, 22.92, 18.50, 1.88, 1.04, 27.13, 34.98, 1.19),
  Mean_Treated_Post = c(58.08, 45.68, 53.47, 21.17, 2.46, 1.91, 17.16, 38.18, 1.39),
  SD_Treated_Post = c(42.70, 35.75, 22.90, 17.94, 1.78, 1.02, 27.40, 37.28, 1.19),
  Mean_Control_Pre = c(60.30, 50.46, 55.98, 20.24, 2.64, 2.06, 23.77, 39.88, 1.46),
  SD_Control_Pre = c(41.54, 37.17, 23.57, 17.73, 1.85, 1.05, 29.49, 35.17, 1.14),
  Mean_Control_Post = c(62.17, 50.44, 56.06, 20.28, 2.49, 2.01, 23.66, 39.82, 1.35),
  SD_Control_Post = c(43.06, 37.05, 23.44, 17.52, 1.79, 1.04, 30.00, 36.85, 1.11)
)

###################################
# Generate data for all variables
###################################
N_treated_cumsums <- lapply(1:9, function(var) c(0, cumsum(sapply(1:5, function(cohort) N_treated_var[[cohort]][var]))))
N_control_cumsums <- lapply(1:9, function(var) c(0, cumsum(sapply(1:5, function(cohort) N_control_var[[cohort]][var]))))
dt_full <- lapply(1:9, function(var) {
  variable <- variables[var, ]
  Nt <- sum(sapply(1:5, function(cohort) N_treated_var[[cohort]][var]))
  Nc <- sum(sapply(1:5, function(cohort) N_control_var[[cohort]][var]))
  Nt_cumsum <- N_treated_cumsums[[var]]
  Nc_cumsum <- N_control_cumsums[[var]]
  generate_variable_data(Nt, Nc, Nt_cumsum, Nc_cumsum, T, pre_periods, post_periods, 
                         variable$Mean_Treated_Pre, variable$Mean_Treated_Post, 
                         variable$Mean_Control_Pre, variable$Mean_Control_Post, 
                         variable$SD_Treated_Pre, variable$SD_Treated_Post, 
                         variable$SD_Control_Pre, variable$SD_Control_Post)
})

# Create cohorts:
dt_list <- lapply(1:5, function(cohort) {
  lapply(1:9, function(var) {
    treated_units <- paste0("treated_", seq(N_treated_cumsums[[var]][cohort]+1, N_treated_cumsums[[var]][cohort+1]))
    control_units <- paste0("control_", seq(N_control_cumsums[[var]][cohort]+1, N_control_cumsums[[var]][cohort+1]))
    dt_full[[var]][unit %in% c(treated_units, control_units)]
  })
})

# Combine datasets, adding a column to distinguish variables
dt_combined <- lapply(1:5, function(cohort) {
  rbindlist(lapply(seq_along(dt_list[[cohort]]), function(var) {
    dt_list[[cohort]][[var]][, cohort := cohort]
    dt_list[[cohort]][[var]][, Variable := variables$Variable[var]]
  }))
})

rm(dt_full, dt_list, N_treated_cond, N_treated_cumsums, N_control_cond, N_control_cumsums, generate_variable_data)

## Data for table 10
n <- 620

# Define coefficients
coefficients <- list()
coefficients$defiers <- c(-0.01, 0.02, 0.19, 2.60, -0.04, 0.32, 0.73, 0.25, 0.24, 0.01, -0.18, -0.07, 0.10, 5.06, -0.63, -0.64, 0.69, -0.11, -0.09, 0.32, -0.03, 0.01, 0.08, -4.54)
coefficients$compliers <- c(-0.01, 0.01, -0.71, -0.70, -0.12, 0.04, 0.13, 0.11, 0.01, -0.01, -0.08, -0.08, 0.00, -4.16, -1.30, 0.38, 0.09, 0.05, 0.12, -0.03, 0.00, -0.15, -0.02, .16)
coefficients$always_takers <- c(0.03, -0.06, 1.21, -2.82, 0.23, -0.55, -1.19, -0.39, -0.22, 0.01, 0.11, 0.22, -0.04, -0.49, -0.77, 0.56, -0.45, 0.21, -0.12, -0.56, 0.03, 0.23, -0.07, 1.47)

# Generate data
table_10_data <- list()
for (group in c("defiers", "compliers", "always_takers")) {
  # We cannot give the distributions for all these detailed households characteristics per our NDA, 
  # so we simulate 23 normal variables here
  
  X <- data.table(matrix(rnorm(n*23, 0, 1), ncol = 23))
  
  # In simulating the outcomes we do not take the interdependencies between the outcomes into account,
  # one could use a MNL model for that
  
  # Simulate binary outcome using latent variable approach
  y <- data.table(y = (coefficients[[group]][24] + rowSums(X * matrix(coefficients[[group]][-24], nrow = n, ncol = 23, byrow = TRUE)) + rlogis(n, 0, 1)) > 0)
  
  # Combine into a data frame
  yX <- cbind(y, X)
  
  # Store in list
  table_10_data[[group]] <- yX
}

rm(coefficients, y, X, yX, group, n)

