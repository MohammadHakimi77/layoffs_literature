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

# Table 1
# Col 1 - News articles
# Col 2 - News articles in mega-ban months
# Col 3 - Tweets
# Col 4 - Tweets in mega-ban months

news_sal_dt <- fread("./data/replication_data/news_salience_data.csv")

m_news <- feols(ln_num_articles ~ is_top_25_title | month, cluster = "title", 
                news_sal_dt[month >= ymd(20211001)])
m_news_mb <- feols(ln_num_articles ~ is_top_25_title | month, cluster = "title", 
                   news_sal_dt[is_mega_ban_month == 1 & month >= ymd(20211001)])

tweet_sal_dt <- fread("./data/replication_data/tweet_salience_data.csv")

m_twt <- feols(ln_count ~ is_top_25_title | month, cluster = "title", 
               tweet_sal_dt[month >= ymd(20211001)])
m_twt_mb <- feols(ln_count ~ is_top_25_title | month, cluster = "title", 
                  tweet_sal_dt[is_mega_ban_month == 1 & month >= ymd(20211001)])


setFixest_dict(c(ln_num_articles = "Log(News Article Count)", ln_count = "Log(Tweet Count)", 
                 is_top_25_title = "Top-25", 
                 high_visibility = "High Visibility", unpop_author = "Less-experienced Author",
                 is_banned_ever = "Banned", state = "State", month = "Year Month", title = "Title"))
etable(m_news, m_news_mb, m_twt, m_twt_mb,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Impact of Ban Events on Coverage",
       fitstat = ~ r2 + n, placement = "h", se.row = F, 
       se.below = T, headers = list(c("All Months", "Mega Ban Months", "All Months", "Mega Ban Months")))

# Table 2
# Col 1 - Ban related shelves
# Col 2 - LGBTQ related shelves
# Col 3 - School related shelves
shelf_dt <- fread("./data/replication_data/shelf_data.csv")
m1 <- feols(ban_shelved ~ is_top_25_title, shelf_dt[is_ban == 1 & is_lgbt == 0 & is_school == 0])
m2 <- feols(lgbt_shelved ~ is_top_25_title, shelf_dt[is_ban == 0 & is_lgbt == 1 & is_school == 0])
m3 <- feols(school_shelved ~ is_top_25_title, shelf_dt[is_ban == 0 & is_lgbt == 0 & is_school == 1])

setFixest_dict(c(ln_num_articles = "Log(News Article Count)", ln_count = "Log(Tweet Count)", 
                 is_top_25_title = "Top-25", 
                 high_visibility = "High Visibility", unpop_author = "Less-experienced Author",
                 is_banned_ever = "Banned", state = "State", month = "Year Month", title = "Title"))
etable(m1, m2, m3,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Shelving on Goodreads", order = "!Intercept",
       fitstat = ~ r2 + n, placement = "h", se.row = F, depvar = F,
       se.below = T, headers = list(c("Ban-Related", "LGBTQ-Related", "School-Related")))

# Table 3
# Col 1 - Average TWFE with all titles
# Col 2 - Average TWFE with top-25 titles
# Col 3 - Average TWFE with all but top-25 titles
# Col 4 - Average TWFE with intensity of ban as interaction
lib_circ_dt <- fread("./data/replication_data/lib_circ_data.csv")

m1 <- feols(ln_circ ~ post_ban:is_banned_ever | state + title + running_month, 
                   cluster = c('state'), 
                   data = lib_circ_dt[(is_banned_title == 1 | is_control_title == 1) &
                                      months_since_first_ban >= -4 & months_since_first_ban <= 6])

m2 <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                  cluster = c('state'), 
                  data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                     months_since_first_ban >= -4 & months_since_first_ban <= 6])

m3 <- feols(ln_circ ~ post_ban:is_banned_ever | state + title + running_month, 
                   cluster = c('state'), 
                   data = lib_circ_dt[((is_banned_title == 1 & is_top_25_title == 0) | is_control_title == 1) &
                                      months_since_first_ban >= -4 & months_since_first_ban <= 6])

m4 <- feols(ln_circ ~ post_ban + post_ban:is_banned_ever:cum_num_bans | state + title + running_month,
                       cluster = c('state'),
                       data = lib_circ_dt[(is_banned_title == 1 | is_control_title == 1) &
                                         months_since_first_ban >= -4 & months_since_first_ban <= 6])

setFixest_dict(c(ln_circ = "Log(Circulation)", post_ban = "PostBan $\\times$ Banned", 
                 "post_ban:is_banned_ever" = "PostBan $\\times$ Banned",
                 "post_ban:is_banned_ever:cum_num_bans" = "PostBan $\\times$ Banned $\\times$ Intensity of Ban",
                 "post_ban:is_banned_ever:more_bans" = "PostBan $\\times$ Banned $\\times$ $>=$ Five Bans",
                 unpop_author = "Less-experienced Author", cum_num_bans = "Intensity of Ban",
                 is_banned_ever = "Banned", state = "State", running_month = "Year Month", title = "Title",
                 more_bans = "$>=$ Five Bans", is_banned = "Banned"))
etable(m1, m2, m3, m4,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "All Titles: Impact of Ban Events on Circulation",
       fitstat = ~ r2 + n, placement = "h", se.below = T, se.row = F, 
       headers = list(list("All", "Top-25 ", "Non-Top-25", "Impact"),
                      c("Titles", "Titles ", "Titles", "Per Ban")))

# Table 4
# Col 1 - Average TWFE
# Col 2 - Average TWFE in banned states only
# Col 3 - Average TWFE in non-banned states only
# Col 4 - Heterogeneity with author experience
# Col 5 - Heterogeneity with twitter visibility
# Col 6 - Average TWFE in blue states only
# Col 7 - Average TWFE in red states only

m_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
               cluster = c('state'), 
               data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                 months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_avg_ban <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                   cluster = c('state'),
                   data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                     months_since_first_ban >= -4 & months_since_first_ban <= 6 &
                                     is_ban_state == 1])

m_avg_non_ban <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                       cluster = c('state'),
                       data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                         months_since_first_ban >= -4 & months_since_first_ban <= 6 & 
                                         is_ban_state == 0])

m_avg_gr_pop <- feols(ln_circ ~ post_ban*is_banned_ever*unpop_author | state + title + running_month, 
                      cluster = c('state'),
                      data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                        months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_avg_vis <- feols(ln_circ ~ post_ban*is_banned_ever*high_visibility | state + title + running_month, 
                   cluster = c('state'),
                   data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) & 
                                     months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_avg_blue <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                    cluster = c('state'),
                    data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                      months_since_first_ban >= -4 & months_since_first_ban <= 6 &
                                      is_blue_state == 1])

m_avg_red <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                   cluster = c('state'),
                   data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                     months_since_first_ban >= -4 & months_since_first_ban <= 6 & running_month >= 12 &
                                     is_red_state == 1])

setFixest_dict(c(ln_circ = "Log(Circulation)", post_ban = "PostBan $\\times$ Banned", is_banned = "Banned", 
                 high_visibility = "High Visibility", unpop_author = "Less-experienced Author",
                 is_banned_ever = "Banned", state = "State", running_month = "Year Month", title = "Title"))
etable(m_avg, m_avg_ban, m_avg_non_ban, m_avg_gr_pop, m_avg_vis, m_avg_blue, m_avg_red,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Impact of Ban Events on Circulation",
       fitstat = ~ r2 + n, placement = "h", adjustbox = 0.95, se.row = F, 
       se.below = T, headers = list(list("All", "Banned", "Non-banned", "Author", "Twitter", "Blue", "Red"),
                                    c("States", "States ", "States", "Experience", "Visibility", "States", "States ")))


# Table 5
# Col 1 - Callaway Sant'Anna ATE
# Col 2 - Sun & Abraham ATE
# Col 3 - Borusyak et al. ATE
# Col 4 - TWFE ATE with state population weights
# Col 5 - Complete Spillover ATE
# Col 6 - No Spillover ATE

did_data <- lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                       months_since_first_ban >= -4 & months_since_first_ban <= 6]
did_data[, time_to_treatment := months_since_first_ban]
did_data[is_banned_ever == 0, time_to_treatment := -1000]

did_data[, month_treated := min(running_month[months_since_first_ban == 0]), by = "title"]
did_data[is.infinite(month_treated), month_treated := 1000]
did_data[is.na(month_treated), month_treated := 1000]

m_sa_avg <- feols(ln_circ ~ sunab(month_treated, running_month, ref.p = -1) | state + title + running_month, 
                  cluster = c('state'),
                  data = did_data[(is_top_25_title == 1 | is_control_title == 1) &
                                    months_since_first_ban >= -4 & months_since_first_ban <= 6])
m_sa_avg <- summary(m_sa_avg, agg = "ATT")


did_data <- lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                       months_since_first_ban >= -4 & months_since_first_ban <= 6]
setorder(did_data, state, title, running_month)
did_data[is_control_title == 1, months_since_ban := 0]
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
did_data <- fread("./data/replication_data/cs_did_data.csv")
m_cs <- att_gt(yname = "ln_circ",
               tname = "running_month",
               idname = "id",
               gname = "ban_group",
               xformla = ~1,
               control_group = "notyettreated",
               allow_unbalanced_panel = T,
               data = did_data)

agg.simple <- aggte(m_cs, type = "simple", na.rm = T)
m_cs_avg <- copy(m_sa_avg)
m_cs_avg$coeftable[1] <- agg.simple$overall.att
m_cs_avg$coeftable[2] <- agg.simple$overall.se
m_cs_avg$nobs <- m_cs$nobs
m_cs_avg$sq.cor <- NA
m_cs_avg$ssr <- NA

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
                        tname = "running_month", idname = "id")
m_bea_avg <- copy(m_sa_avg)
m_bea_avg$coeftable[1] <- m_bea$estimate
m_bea_avg$coeftable[2] <- m_bea$std.error
m_bea_avg$nobs <- nrow(did_data)
m_bea_avg$sq.cor <- NA
m_bea_avg$ssr <- NA

lib_circ_dt[, post_ban := as.integer(months_since_first_ban >= 0)]
m_pop_wt_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                      cluster = c('state'), weights = ~pop_wt,
                      data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                        months_since_first_ban >= -4 & months_since_first_ban <= 6])

lib_circ_dt[, post_ban := as.integer(months_since_single_ban >= 0)]
m_se_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                  cluster = c('state'),
                  data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                    months_since_single_ban >= -4 & months_since_single_ban <= 6])

lib_circ_dt[, post_ban := as.integer(months_since_ban >= 0)]
m_tse_avg <- feols(ln_circ ~ post_ban*is_banned | state + title + running_month, 
                   cluster = c('state'),
                   data = lib_circ_dt[((is_top_25_title == 1 & is_banned == 1) | is_control_title == 1) &
                                     months_since_ban >= -4 & months_since_ban <= 6 & is_ban_state == 1])

setFixest_dict(c(ln_circ = "Log(Circulation)", "asinh(circ)" = "Circulation", post_ban = "PostBan $\\times$ Banned", 
                 circ = "Circulation", is_banned = "Banned", ATT = "PostBan $\\times$ Banned", 
                 "post_ban:is_banned_ever" = "PostBan $\\times$ Banned",
                 is_banned_ever = "Banned", state = "State", running_month = "Year Month", title = "Title",
                 quarter = "Quarter"))
etable(m_cs_avg, m_sa_avg, m_bea_avg, m_pop_wt_avg, m_se_avg, m_tse_avg,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Additional Estimators: Impact of Ban Events on Circulation",
       fitstat = ~ r2 + n, placement = "h", se.below = T, se.row = F,
       headers = list(list(" " = 3, "Population", "Complete", "No"),
                      list("Callaway", "Sun &", "Borusyak", "Weighted", "Spillover  ", "Spillover"),
                      list("Sant'Anna", "Abraham", "et al.", "TWFE",  "TWFE ", "TWFE")))

# Table 6 - Additional Robustness 
# Col 1 - Alternate first ban month event
# Col 2 - Alternate Author experience
# Col 3 - Banned Red states only
# Col 4 - Non-banned Res states only
# Col 5 - Controls with same genre as banned
# Col 6 - Controls with different genre as banned
# Col 7 - Banned BISAC controls
# Col 8 - Banned BISAC controls using PSM

lib_circ_dt[, post_ban := as.integer(months_since_first_ban >= 0)]
m_avg_red_ban <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                       cluster = c('state'),
                       data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                         months_since_first_ban >= -4 & months_since_first_ban <= 6 &
                                         is_red_state == 1 & is_ban_state == 1])

m_avg_red_non_ban <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                           cluster = c('state'),
                           data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                             months_since_first_ban >= -4 & months_since_first_ban <= 6 & 
                                             is_red_state == 1 & is_ban_state == 0])
did_data <- copy(lib_circ_dt)
did_data[is_banned_ever == 1, months_since_first_ban := months_since_first_ban + 1]
did_data[, post_ban := as.integer(months_since_first_ban >= 0)]
m_avg_cur <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                   cluster = c('state'),
                   data = did_data[(is_top_25_title == 1 | is_control_title == 1) &
                                     months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_avg_tw_pop <- feols(ln_circ ~ post_ban*is_banned_ever*alt_unpop_author | state + title + running_month, 
                      cluster = c('state'),
                      data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                        months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_close_ctrl_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                          cluster = c('state'),
                          data = lib_circ_dt[(is_top_25_title == 1 | (is_control_title == 1 & grepl("FICTION", genre, ignore.case = T))) &
                                               months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_far_ctrl_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                        cluster = c('state'),
                        data = lib_circ_dt[(is_top_25_title == 1 | (is_control_title == 1 & grepl("BUSINESS & ECONOMICS", genre, ignore.case = T))) &
                                             months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_bb_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                  cluster = c('state'),
                  data = lib_circ_dt[(is_top_25_title == 1 | is_ban_bisac_control_title == 1) &
                                    months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_smc_sb_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                      cluster = c('state'),
                      data = lib_circ_dt[(is_top_25_title == 1 | (is_ban_bisac == 1 & is_ban_bisac_matched_control_title == 1)) &
                                        months_since_first_ban >= -4 & months_since_first_ban <= 6])

setFixest_dict(c(ln_circ = "Log(Circulation)", post_ban = "PostBan $\\times$ Banned", is_banned = "Banned", 
                 alt_unpop_author = "\\\\ Less-experienced Author", cum_num_bans = "Intensity of Ban",
                 is_banned_ever = "Banned", state = "State", running_month = "Year Month", title = "Title"))
etable(m_avg_cur, m_avg_tw_pop, m_avg_red_ban, m_avg_red_non_ban, m_close_ctrl_avg, m_far_ctrl_avg, m_bb_avg, m_smc_sb_avg,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Additional Robustness: Impact of Ban Events on Circulation",
       fitstat = ~ r2 + n, placement = "h", se.below = T, se.row = F, 
       headers = list(list("Alternate", "Alternate ", "Banned", "Non-banned", "Same", "Different", "Banned", "Matched"),
                      c("First", "Author", "Red", "Red ", "Genre", "Genre ", "BISAC", "Banned BISAC "),
                      c("Ban Month", "Experience", "States", "States ", "Controls", "Controls ", "Controls", "Controls ")))

# Table 7
# Col 1 - Average TWFE with checkouts from all readers as DV
# Col 2 - Average TWFE with checkouts from inclusive readers as DV
# Col 3 - Average TWFE with checkouts from inclusive non-readers as DV
# Col 4 - Average TWFE with checkouts from all readers as DV, complete spillover DiD

spl_circ_dt <- fread("data/replication_data/spl_circ_data.csv")

m_te_avg <- feols(ln_circ ~ post_ban*is_banned_ever | Title + month, se = "hetero",
                  spl_circ_dt[rel_month >= -4 & rel_month <= 6])

did_dt <- copy(spl_circ_dt)
did_dt[, rel_month := interval(ymd(20211001), month) %/% months(1)]
did_dt[, post_ban := as.integer(rel_month >= 0)]
m_se_avg <- feols(ln_circ ~ post_ban*is_banned_ever | Title + month, se = "hetero",
                  did_dt[rel_month >= -4 & rel_month <= 6])

spl_circ_dt <- fread("data/replication_data/spl_inc_circ_data.csv")
m_ir_avg <- feols(ln_circ ~ post_ban*is_banned_ever | Title + month, se = "hetero",
                  spl_circ_dt[rel_month >= -4 & rel_month <= 6 & inclusive_reader == 1])

m_inr_avg <- feols(ln_circ ~ post_ban*is_banned_ever | Title + month, se = "hetero",
                   spl_circ_dt[rel_month >= -4 & rel_month <= 6 & inclusive_reader == 0 ])

setFixest_dict(c(ln_circ = "Log(Circulation)", "asinh(circ)" = "Circulation", post_ban = "PostBan $\\times$ Banned", 
                 circ = "Circulation", is_banned_ever = "Banned", 
                 "post_ban:is_banned_ever" = "PostBan $\\times$ Banned", month = "Year Month",
                 state = "State", running_month = "Year Month", title = "Title", quarter = "Quarter"))
etable(m_te_avg, m_ir_avg, m_inr_avg, m_se_avg, 
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Impact of Ban Events on Circulation",
       fitstat = ~ r2 + n, placement = "h", 
       se.below = T, se.row = F, headers = list(list("All", "Inclusive ", "Inclusive", "Alternate"),
                                                list("Readers", "Readers ", "Non-Readers", "Identification")))

# Table 8
# Col 1 - Average TWFE with donations in banned states as DV with Reps vs Dems as interaction
# Col 2 - Average TWFE with donations in banned Blue states as DV with Reps vs Dems as interaction
# Col 3 - Average TWFE with donations in banned Red states as DV with Reps vs Dems as interaction

pol_don_dt <- fread("data/replication_data/pol_don_data.csv")

m1 <- feols(ln_amount ~ post_ban*is_rep_cmt | cand_state + CAND_ID + month + cand_state^month, 
            cluster = c("cand_state"),
            data = pol_don_dt[months_since_first_ban >= -4 & months_since_first_ban <= 6])

m2 <- feols(ln_amount ~ post_ban*is_rep_cmt | cand_state + CAND_ID + month + cand_state^month, 
            cluster = c("cand_state"),
            data = pol_don_dt[months_since_first_ban >= -4 & months_since_first_ban <= 6 & 
                              is_red_state == 0])

m3 <- feols(ln_amount ~ post_ban*is_rep_cmt | cand_state + CAND_ID + month + cand_state^month, 
            cluster = c("cand_state"),
            data = pol_don_dt[months_since_first_ban >= -4 & months_since_first_ban <= 6 & 
                              is_red_state == 1])

setFixest_dict(c(ln_amount = "Log(Donations)", post_ban = "PostBan", is_dem_cmt = "Democrat", 
                 is_rep_cmt = "Republican", cand_state = "State", CAND_ID = "Candidate",
                 month = "Year Month"))
etable(m1, m2, m3, 
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Impact of Ban Events on Political Donations",
       fitstat = ~ r2 + n, placement = "h", 
       se.below = T, headers = list(list("All", "Blue", "Red"),
                                    c("States", "States ", "States")), se.row = F)
