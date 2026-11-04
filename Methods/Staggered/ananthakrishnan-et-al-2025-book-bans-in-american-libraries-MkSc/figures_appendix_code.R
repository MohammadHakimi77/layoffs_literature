library(data.table)
library(ggplot2)
library(lubridate)
library(fixest)
library(dplyr)
library(did)
library(RColorBrewer)
library(ggthemes)
library(directlabels)
library(DIDmultiplegt)
library(didimputation)
library(stringr)
library(MatchIt)

# Set the root directory here #
setwd("D:/nthotada/BookBans")

# Figure A1 - Descriptive

# Figure A2 - Histogram of number of bans - top-25
ban_count_dt <- fread("./data/replication_data/ban_counts_data.csv")
ggplot(ban_count_dt, aes(x = reorder(title, -num_bans), y = num_bans)) +
  geom_bar(stat = "identity", width = .75) + xlab("Title") + ylab("# Bans per Title") +
  annotate("rect", xmin = 0, xmax = 25, ymin = 0, ymax = 41, alpha = .2, fill = "black") +
  theme_bw() + theme(axis.text.x = element_blank(), axis.ticks = element_blank(), axis.title = element_text(size = 14)) +
  scale_y_continuous(expand = c(0,0))

# Figure A3 - Alternate identification + DiD
bans_dt <- fread("./data/replication_data/ban_events_data.csv")
ggplot(bans_dt, aes(x = month, y = num_events)) + geom_line(size = 1.2, alpha = 0.7) +
  xlab("Month") + ylab("# Book Ban Instances") + 
  theme(axis.title = element_text(size = 14), legend.text = element_text(size = 14)) +
  scale_x_date(breaks = c(seq(as.Date("2021-01-01"), by = "6 months", length.out = 3), as.Date("2022-06-01")))

lib_circ_dt <- fread("./data/replication_data/lib_circ_data.csv")
m_se <- feols(ln_circ ~ i(months_since_single_ban, is_banned_ever, -1) | state + running_month + title, 
              cluster = c('state'),
              data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                   months_since_single_ban >= -4 & months_since_single_ban <= 6])

m_tse <- feols(ln_circ ~ i(months_since_ban, is_banned, -1) | state + running_month + title, 
               cluster = c('state'),
               data = lib_circ_dt[((is_top_25_title == 1 & is_banned == 1) | is_control_title == 1) &
                                    months_since_ban >= -4 & months_since_ban <= 6 & is_ban_state == 1])

plot_alt_id_est <- function(m_se, m_tse) {
  coefs <- data.table("rel_week" = seq(-4, 6))
  coefs[, est_se := c(m_se$coefficients[1:3], 0, m_se$coefficients[4:10])]
  coefs[, se_se := c(m_se$se[1:3], 0, m_se$se[4:10])]
  y_min <- unlist(tidy(m_se, conf.int = T, conf.level = .95)[, 6])
  coefs[, y_min_se := c(y_min[1:3], 0, y_min[4:10])]
  y_max <- unlist(tidy(m_se, conf.int = T, conf.level = .95)[, 7])
  coefs[, y_max_se := c(y_max[1:3], 0, y_max[4:10])]
  
  coefs[, est_tse := c(m_tse$coefficients[1:3], 0, m_tse$coefficients[4:10])]
  coefs[, se_tse := c(m_tse$se[1:3], 0, m_tse$se[4:10])]
  y_min <- unlist(tidy(m_tse, conf.int = T, conf.level = .95)[, 6])
  coefs[, y_min_tse := c(y_min[1:3], 0, y_min[4:10])]
  y_max <- unlist(tidy(m_tse, conf.int = T, conf.level = .95)[, 7])
  coefs[, y_max_tse := c(y_max[1:3], 0, y_max[4:10])]
  
  # coefs[, (names(coefs)[2:13]) := round(.SD, 3), .SDcols = names(coefs)[2:13]]
  
  p <- ggplot(coefs) + geom_hline(yintercept = 0, color = "black", size = .5) +
    
    geom_point(aes(x = rel_week + 0, y = est_se, color = "Maximal spillover"), shape = 15, size = 2) +
    geom_errorbar(width = 0.2, size = 1, aes(x = rel_week + 0, ymin = y_min_se, ymax = y_max_se, 
                                             color = "Maximal spillover")) +
    
    geom_point(aes(x = rel_week + 0.1, y = est_tse, color = "Minimal spillover"), shape = 15, size = 2) +
    geom_errorbar(width = 0.2, size = 1, aes(x = rel_week + 0.1, ymin = y_min_tse, ymax = y_max_tse, 
                                             color = "Minimal spillover")) +
    geom_vline(xintercept = -0, color = "red", linetype = "dashed", size = 1) +
    theme_bw() +
    scale_x_continuous(breaks = seq(-4, 7, 1)) +
    xlab("Relative Month") +
    ylab("Estimate") +
    scale_colour_manual(name="",
                        values=c("Maximal spillover" = "#211f20", "Minimal spillover" = "#a64341")) +
    theme(legend.position = "top", axis.title = element_text(size = 14), legend.text = element_text(size = 14))
  
  return(p)
  
}
plot_alt_id_est(m_se, m_tse)

# Figure A4 - DiD estimates with matched control

m_twfe <- feols(ln_circ ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
                cluster = c('state'),
                data = lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
                                     months_since_first_ban >= -4 & months_since_first_ban <= 6])

did_data <- lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
                          months_since_first_ban >= -4 & months_since_first_ban <= 6]
did_data[, time_to_treatment := months_since_first_ban]
did_data[is_banned_ever == 0, time_to_treatment := -1000]

did_data[, month_treated := min(running_month[months_since_first_ban == 0]), by = "title"]
did_data[is.infinite(month_treated), month_treated := 1000]
did_data[is.na(month_treated), month_treated := 1000]

m_sa <- feols(ln_circ ~ sunab(month_treated, running_month, ref.p = -1) | state + title + running_month, 
              cluster = c('state'),
              data = did_data[(is_top_25_title == 1 | is_matched_control_title == 1) &
                                months_since_first_ban >= -4 & months_since_first_ban <= 6])

did_data <- lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
                          months_since_first_ban >= -4 & months_since_first_ban <= 6]
did_data[is_control == 1, months_since_ban := 0]
did_data <- did_data[, c("title", "state", "circ", "ln_circ", "months_since_ban", "is_banned", "event_id",
                         "running_month", "clean_ban_date", "date", "months_since_first_ban")]
did_data[, state_title := paste0(state, title)]
did_data[, ban_group := min(running_month[months_since_first_ban == 0]), by = "title"]
did_data[is.infinite(ban_group), ban_group := 0]
did_data[is.na(ban_group), ban_group := 0]
setorder(did_data, clean_ban_date)
state_title <- unique(did_data$state_title)
temp_dt <- data.table("state_title" = state_title, "id" = seq(1, length(state_title)))
did_data <- merge.data.table(did_data, temp_dt, by = "state_title")
did_data[is.na(id), id := 0]
m_cs <- att_gt(yname = "ln_circ",
               tname = "running_month",
               idname = "id",
               gname = "ban_group",
               xformla = ~1,
               control_group = "notyettreated",
               allow_unbalanced_panel = T,
               data = did_data)
m_cs <- aggte(m_cs, type = "dynamic", na.rm = T)


did_data <- lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
                          months_since_first_ban >= -4 & months_since_first_ban <= 6]
did_data[is_control == 1, months_since_ban := 0]
did_data <- did_data[, c("title", "state", "circ", "ln_circ", "months_since_ban", "is_banned", "event_id",
                         "running_month", "clean_ban_date", "date", "months_since_first_ban")]
did_data[, state_title := paste0(state, title)]
did_data[, ban_group := min(running_month[months_since_first_ban == 0]), by = "title"]
did_data[is.infinite(ban_group), ban_group := 0]
did_data[is.na(ban_group), ban_group := 0]
setorder(did_data, clean_ban_date)
state_title <- unique(did_data$state_title)
temp_dt <- data.table("state_title" = state_title, "id" = seq(1, length(state_title)))
did_data <- merge.data.table(did_data, temp_dt, by = "state_title")
did_data[is.na(id), id := 0]

m_bea <- did_imputation(data = did_data, yname = "ln_circ", gname = "ban_group",
                        tname = "running_month", idname = "id", horizon = T, pretrends = -4:-1)

plot_all_est <- function(m_twfe, m_cs, m_sa, m_bea) {
  coefs <- data.table("rel_week" = seq(-4, 6))
  coefs[, est_twfe := c(m_twfe$coefficients[1:3], 0, m_twfe$coefficients[4:10])]
  coefs[, se_twfe := c(m_twfe$se[1:3], 0, m_twfe$se[4:10])]
  y_min <- unlist(tidy(m_twfe, conf.int = T, conf.level = .95)[, 6])
  coefs[, y_min_twfe := c(y_min[1:3], 0, y_min[4:10])]
  y_max <- unlist(tidy(m_twfe, conf.int = T, conf.level = .95)[, 7])
  coefs[, y_max_twfe := c(y_max[1:3], 0, y_max[4:10])]
  
  coefs[, est_cs := c(NA, m_cs$att.egt)]
  coefs[, se_cs := c(NA, m_cs$se.egt)]
  y_min <- tidy(m_cs)[, 6]
  coefs[, y_min_cs := c(NA, y_min)]
  y_max <- tidy(m_cs)[, 7]
  coefs[, y_max_cs := c(NA, y_max)]
  
  coefs[, est_sa := c(m_sa[["coeftable"]][,1][1:3], 0, m_sa[["coeftable"]][,1][4:10])]
  coefs[, se_sa := c(m_sa[["coeftable"]][,2][1:3], 0, m_sa[["coeftable"]][,2][4:10])]
  y_min <- unlist(tidy(m_sa, conf.int = T, conf.level = .95)[, 6])
  coefs[, y_min_sa := c(y_min[1:3], 0, y_min[4:10])]
  y_max <- unlist(tidy(m_sa, conf.int = T, conf.level = .95)[, 7])
  coefs[, y_max_sa := c(y_max[1:3], 0, y_max[4:10])]
  
  coefs[, est_bea := c(m_bea$estimate[1:3], 0, m_bea$estimate[4:10])]
  coefs[, se_bea := c(m_bea$std.error[1:3], 0, m_bea$std.error[4:10])]
  coefs[, y_min_bea := c(m_bea$conf.low[1:3], 0, m_bea$conf.low[4:10])]
  coefs[, y_max_bea := c(m_bea$conf.high[1:3], 0, m_bea$conf.high[4:10])]
  
  # coefs[, (names(coefs)[2:13]) := round(.SD, 3), .SDcols = names(coefs)[2:13]]
  
  p <- ggplot(coefs) + geom_hline(yintercept = 0, color = "black", size = .5) +
    
    geom_point(aes(x = rel_week, y = est_twfe, color = "TWFE"), shape = 15, size = 2) +
    geom_errorbar(width = 0.2, size = 1, 
                  aes(x = rel_week, ymin = y_min_twfe, ymax = y_max_twfe, color = "TWFE")) +
    
    geom_point(aes(x = rel_week + 0.1, y = est_cs, color = "Callaway-Sant'Anna"), shape = 15, size = 2) +
    geom_errorbar(width = 0.2, size = 1, 
                  aes(x = rel_week + 0.1, ymin = y_min_cs, ymax = y_max_cs, color = "Callaway-Sant'Anna")) +
    
    geom_point(aes(x = rel_week + 0.2, y = est_sa, color = "Sun-Abraham"), shape = 15, size = 2) +
    geom_errorbar(width = 0.2, size = 1, 
                  aes(x = rel_week + 0.2, ymin = y_min_sa, ymax = y_max_sa, color = "Sun-Abraham")) + 
    
    geom_point(aes(x = rel_week + 0.4, y = est_bea, color = "Borusyak et al."), shape = 15, size = 2) +
    geom_errorbar(width = 0.2, size = 1, aes(x = rel_week + 0.4, ymin = y_min_bea, ymax = y_max_bea, 
                                             color = "Borusyak et al.")) +
    
    geom_vline(xintercept = -0, color = "red", linetype = "dashed", size = 1) +
    theme_bw() +
    scale_x_continuous(breaks = seq(-4, 7, 1)) +
    xlab("Relative Month") +
    ylab("Estimate") +
    scale_colour_manual(name="",
                        values=c("TWFE" = "#211f20", "Callaway-Sant'Anna" = "#a64341", "Borusyak et al." = "#2d538a",
                                 "Sun-Abraham" = "#4f8c51")) +
    theme(legend.position = "top", axis.title = element_text(size = 14))
  
  return(p)
}
plot_all_est(m_twfe, m_cs, m_sa, m_bea)

# Figure A5 - TWFE alternate time window
plot_ext_est <- function(model) {
  output <- tidy(model, conf.int = T, conf.level = 0.95)
  
  # Adding the observation corresponding to week -4
  output <- output %>%
    tail(19) %>%
    add_row(term = '::-1',
            estimate = 0,
            std.error = 0,
            statistic = NA,
            p.value = NA,
            conf.low = NA,
            conf.high = NA,
            .before = 1) %>%
    dplyr::mutate(estimate = ifelse(is.na(estimate), 0, estimate),
                  week = as.integer(tstrsplit(term, ":")[[3]]))
  
  # Plotting estimates
  p <- ggplot(data = output, mapping = aes(x = week, y = estimate, ymin = conf.low, ymax = conf.high)) +
    geom_hline(yintercept = 0, color = "grey", size = 1.5) +
    geom_line(size = 1) +
    geom_errorbar(width = 0.2, size = 1) +
    geom_vline(xintercept = -0, color = "red", linetype = "dashed", size = 1) +
    geom_point(size = 3) +
    theme_bw() +
    theme(axis.title = element_text(size = 14), legend.text = element_text(size = 14)) +
    scale_x_continuous(breaks = seq(-6, 7, 1)) +
    xlab("Relative Month") +
    ylab("Estimate")
  return(p)
}

alt_time_circ_dt <- fread("./data/replication_data/alt_time_lib_circ_data.csv")
m_ext_twfe <- feols(ln_circ ~ i(months_since_first_ban, is_banned_ever, -1) | state + title + running_month, 
                    cluster = c('state'),
                    data = alt_time_circ_dt)
plot_ext_est(m_ext_twfe)

# Figure A6 - Leave one out estimates
top_25_titles <- unique(lib_circ_dt[is_top_25_title == 1]$title)
stacked_estimates <- data.table()
for(a_title in top_25_titles) {
  event_title = a_title
  try(
    {m1 <- summary(feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                         cluster = c('state'), 
                         data = lib_circ_dt[((is_top_25_title == 1 & title != a_title) | is_control_title == 1) &
                                           months_since_first_ban >= -4 & months_since_first_ban <= 6]))
    stacked_estimates <- rbind(stacked_estimates, 
                               data.table(excluded_title = event_title,
                                          est = coef(m1)[1],
                                          se = m1$se[1],
                                          p_val = pvalue(m1)[1]))
    })
}
stacked_estimates[, lower_ci := est - 1.96*se]
stacked_estimates[, upper_ci := est + 1.96*se]
stacked_estimates[, signif := p_val < 0.05]

ggplot(stacked_estimates, aes(est, reorder(excluded_title, est), color = signif)) +
  geom_point(size = 2) +
  geom_errorbarh(
    aes(xmin = lower_ci, xmax = upper_ci),
    alpha = 1/2
  ) +
  scale_color_manual(values = c("#B2182B", "#878787")) +
  labs(
    x = 'Estimate', 
    y = 'Excluded Title',
  ) +
  guides(color = guide_legend(title = 'p < .05')) +
  theme_minimal()

# Figure A7 - Leave one out estimates - heterogeneity
top_25_titles <- unique(lib_circ_dt[is_top_25_title == 1]$title)
stacked_estimates <- data.table()
for(a_title in top_25_titles) {
  event_title = a_title
  try(
    {m1 <- summary(feols(ln_circ ~ post_ban*is_banned_ever*unpop_author | state + title + running_month, 
                         cluster = c('state'), 
                         data = lib_circ_dt[((is_top_25_title == 1 & title != a_title) | is_control_title == 1) &
                                              months_since_first_ban >= -4 & months_since_first_ban <= 6]))
    stacked_estimates <- rbind(stacked_estimates, 
                               data.table(excluded_title = event_title,
                                          est = coef(m1)[2],
                                          se = m1$se[2],
                                          p_val = pvalue(m1)[2]))
    })
}
stacked_estimates[, lower_ci := est - 1.96*se]
stacked_estimates[, upper_ci := est + 1.96*se]
stacked_estimates[, signif := p_val < 0.05]

ggplot(stacked_estimates, aes(est, reorder(excluded_title, est), color = signif)) +
  geom_point(size = 2) +
  geom_errorbarh(
    aes(xmin = lower_ci, xmax = upper_ci),
    alpha = 1/2
  ) +
  scale_color_manual(values = c("#B2182B", "#878787")) +
  labs(
    x = 'Estimate', 
    y = 'Excluded Title',
  ) +
  guides(color = guide_legend(title = 'p < .05')) +
  theme_minimal()

stacked_estimates <- data.table()
for(a_title in top_25_titles) {
  event_title = a_title
  try(
    {m1 <- summary(feols(ln_circ ~ post_ban*is_banned_ever*high_visibility | state + title + running_month, 
                         cluster = c('state'), 
                         data = lib_circ_dt[((is_top_25_title == 1 & title != a_title) | is_control_title == 1) &
                                              months_since_first_ban >= -4 & months_since_first_ban <= 6]))
    stacked_estimates <- rbind(stacked_estimates, 
                               data.table(excluded_title = event_title,
                                          est = coef(m1)[2],
                                          se = m1$se[2],
                                          p_val = pvalue(m1)[2]))
    })
}
stacked_estimates[, lower_ci := est - 1.96*se]
stacked_estimates[, upper_ci := est + 1.96*se]
stacked_estimates[, signif := p_val < 0.05]

ggplot(stacked_estimates, aes(est, reorder(excluded_title, est), color = signif)) +
  geom_point(size = 2) +
  geom_errorbarh(
    aes(xmin = lower_ci, xmax = upper_ci),
    alpha = 1/2
  ) +
  scale_color_manual(values = c("#B2182B", "#878787")) +
  labs(
    x = 'Estimate', 
    y = 'Excluded Title',
  ) +
  guides(color = guide_legend(title = 'p < .05')) +
  theme_minimal()

# Figure A8 - Histogram of number of bans - more than three and four bans
ban_count_dt <- fread("./data/replication_data/ban_counts_data.csv")
idx <- max(ban_count_dt[num_bans == 4]$ID)
ggplot(ban_count_dt, aes(x = reorder(title, -num_bans), y = num_bans)) +
  geom_bar(stat = "identity", width = .75) + xlab("Title") + ylab("# Bans per Title") +
  annotate("rect", xmin = 0, xmax = idx, ymin = 0, ymax = 41, alpha = .4, fill = "black") +
  theme_bw() + theme(axis.text.x = element_blank(), axis.ticks = element_blank(), axis.title = element_text(size = 14)) +
  scale_y_continuous(expand = c(0,0))

idx <- max(ban_count_dt[num_bans == 3]$ID)
ggplot(ban_count_dt, aes(x = reorder(title, -num_bans), y = num_bans)) +
  geom_bar(stat = "identity", width = .75) + xlab("Title") + ylab("# Bans per Title") +
  annotate("rect", xmin = 0, xmax = idx, ymin = 0, ymax = 41, alpha = .6, fill = "black") +
  theme_bw() + theme(axis.text.x = element_blank(), axis.ticks = element_blank(), axis.title = element_text(size = 14)) +
  scale_y_continuous(expand = c(0,0))
