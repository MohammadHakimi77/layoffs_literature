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

plot_est <- function(model) {
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
    scale_x_continuous(breaks = seq(-4, 7, 1)) +
    xlab("Relative Month") +
    ylab("Estimate")
  return(p)
}

plot_2_est <- function(m1, text1, m2, text2) {
  output1 <- tidy(m1, conf.int = T, conf.level = 0.95)
  output1 <- output1 %>%
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
  output1$model <- text1
  
  output2 <- tidy(m2, conf.int = T, conf.level = 0.95)
  output2 <- output2 %>%
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
  output2$model <- text2
  
  output <- rbind(output1, output2)
  
  colors <- c("#211f20", "#a64341")
  names(colors) <- c(text1, text2)
  
  p <- ggplot(data = output, mapping = aes(x = week, y = estimate, ymin = conf.low, ymax = conf.high, color = model)) +
    geom_hline(yintercept = 0, color = "grey", size = 1.5) +
    geom_line(size = 1) +
    geom_errorbar(width = 0.2, size = 1) +
    scale_colour_manual(name="", values = colors) +
    geom_vline(xintercept = -0, color = "red", linetype = "dashed", size = 1) +
    geom_point(size = 3) +
    theme_bw() +
    scale_x_continuous(breaks = seq(-4, 7, 1)) +
    xlab("Relative Month") +
    ylab("Estimate") +
    theme(legend.position = "top", axis.title = element_text(size = 14), legend.text = element_text(size = 14))
  
  return(p)
}

# Figure 1 - Descriptive

# Figure 2 - Descriptive

# Figure 3 - Number of bans per per for 5 titles
bans_dt <- fread("./data/replication_data/num_bans_data.csv")

ggplot(bans_dt, aes(x = month, y = num_bans, color = title)) + geom_line(size = 1) +
  xlab("Month") + ylab("# Bans per Title") + scale_color_brewer(palette = "Dark2") + 
  theme_bw() + theme(legend.position = "none", axis.title = element_text(size = 14)) +
  scale_x_date(breaks = c(seq(as.Date("2021-01-01"), by = "6 months", length.out = 3), as.Date("2022-06-01")))

# Figure 4 - DiD estimates
lib_circ_dt <- fread("./data/replication_data/lib_circ_data.csv")

m_twfe <- feols(ln_circ ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
                cluster = c('state'),
                data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                  months_since_first_ban >= -4 & months_since_first_ban <= 6])

did_data <- lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                          months_since_first_ban >= -4 & months_since_first_ban <= 6]
did_data[, time_to_treatment := months_since_first_ban]
did_data[is_banned_ever == 0, time_to_treatment := -1000]

did_data[, month_treated := min(running_month[months_since_first_ban == 0]), by = "title"]
did_data[is.infinite(month_treated), month_treated := 1000]
did_data[is.na(month_treated), month_treated := 1000]

m_sa <- feols(ln_circ ~ sunab(month_treated, running_month, ref.p = -1) | state + title + running_month, 
                  cluster = c('state'),
                  data = did_data[(is_top_25_title == 1 | is_control_title == 1) &
                                    months_since_first_ban >= -4 & months_since_first_ban <= 6])

did_data <- lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
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


did_data <- lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
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

# Figure 5 - TWFE alternate control group
m_close_ctrl <- feols(ln_circ ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
                      cluster = c('state'), 
                      data = lib_circ_dt[(is_top_25_title == 1 | (is_control_title == 1 & grepl("FICTION", genre, ignore.case = T))) &
                                        months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_far_ctrl <- feols(ln_circ ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
                    cluster = c('state'), 
                    data = lib_circ_dt[(is_top_25_title == 1 | (is_control_title == 1 & grepl("BUSINESS & ECONOMICS", genre, ignore.case = T))) &
                                      months_since_first_ban >= -4 & months_since_first_ban <= 6])

plot_2_est(m_close_ctrl, "Similar Control", m_far_ctrl, "Dissimilar Control")

# Figure 6 - TWFE heterogeneity
m_unpop_author <- feols(ln_circ ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
                        cluster = c('state'),
                        data = lib_circ_dt[((is_top_25_title == 1 & unpop_author == 1) | (is_control_title == 1)) &
                                             months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_pop_author <- feols(ln_circ ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
                      cluster = c('state'),
                      data = lib_circ_dt[((is_top_25_title == 1 & unpop_author == 0) | (is_control_title == 1)) &
                                           months_since_first_ban >= -4 & months_since_first_ban <= 6])
plot_2_est(m_unpop_author, "Less-experienced Author", m_pop_author, "More-experienced Author")

m_high_twt_vis <- feols(ln_circ ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
                        cluster = c('state'),
                        data = lib_circ_dt[((is_top_25_title == 1 & high_visibility == 1) | (is_control_title == 1)) &
                                             months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_low_twt_vis <- feols(ln_circ ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
                       cluster = c('state'),
                       data = lib_circ_dt[((is_top_25_title == 1 & high_visibility == 0) | (is_control_title == 1)) &
                                            months_since_first_ban >= -4 & months_since_first_ban <= 6])
plot_2_est(m_high_twt_vis, "High Visibility", m_low_twt_vis, "Low Visibility")

# Figure 7 - Twitter chatter DiD
tweet_dt <- fread("./data/replication_data/tweet_data.csv")

m1 <- feols(ln_count ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
            cluster = c('state'),
            data = tweet_dt[months_since_first_ban >= -4 & months_since_first_ban <= 6])
plot_est(m1)


m1 <- feols(ln_impressions ~ i(months_since_first_ban, is_banned_ever, -1) | state + running_month + title, 
            cluster = c('state'),
            data = tweet_dt[months_since_first_ban >= -4 & months_since_first_ban <= 6])
plot_est(m1)

# Figure 8 - Number of news articles per month
news_dt <- fread("./data/replication_data/news_by_region_data.csv")
ggplot(news_dt[abs(months_since_event) <= 10], aes(x = months_since_event, y = num_articles, fill = is_national)) + 
  geom_bar(stat="identity") + theme_bw() +
  ylab("Mean # Articles Per Event") +
  xlab("Months Since Event") + guides(fill = guide_legend(title = "")) +
  scale_fill_discrete(name = "is_national")

# Figure 9 - Amazon Sales Rank
sales_rank_dt <- fread("./data/replication_data/sales_rank_data.csv")

m_twfe_sr <- feols(ln_min_sales_rank ~ i(months_since_first_ban, is_banned_ever, -1) | title + running_month,
                   cluster = c('title'),
                   data = sales_rank_dt[months_since_first_ban >= -4 & months_since_first_ban <= 6])
plot_est(m_twfe_sr)

# Figure 10 - Number of book ban emails

emails_dt <- fread("./data/replication_data/campaign_email_data.csv")
emails_dt[, post := as.character(post)]
ggplot(emails_dt, aes(x = post, y = num_mails, fill = party)) +
  geom_bar(stat = "identity", position = position_dodge()) + 
  xlab("Time Period") + ylab("Mean Monthly # E-mails") + 
  scale_fill_manual(name="", values=c("D" = "#0042ca", "R" = "#e1141e")) +
  scale_x_discrete(labels=c("1" = "Post Jul 2021", "0" = "Pre Jul 2021")) + theme_bw() +
  theme(axis.title = element_text(size = 14))
