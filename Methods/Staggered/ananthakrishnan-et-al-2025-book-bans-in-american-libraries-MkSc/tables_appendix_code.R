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

# Table A1 - Descriptive

# Table A2
# Col 1 - Other books of same genre as banned books
# Col 2 - Other books of same BISAC as banned books
# Col 3 - Other books by authors of banned books
other_circ_dt <- fread("./data/replication_data/other_circ_data.csv")
m_avg_same_genre <- feols(ln_circ ~ post_ban*same_genre_title | state + title + running_month, 
                          cluster = c('state'),
                          data = other_circ_dt[((same_genre_title == 1) | 
                                             is_control_title == 1) &
                                            months_since_first_state_ban >= -4 & months_since_first_state_ban <= 6])

m_avg_same_bisac <- feols(ln_circ ~ post_ban*same_bisac_title | state + title + running_month, 
                          cluster = c('state'),
                          data = other_circ_dt[((same_bisac_title == 1) | 
                                             is_control_title == 1) &
                                            months_since_first_state_ban >= -4 & months_since_first_state_ban <= 6])

m_avg_same_author <- feols(ln_circ ~ post_ban*same_author_title | state + title + running_month, 
                           cluster = c('state'),
                           data = other_circ_dt[((same_author_title == 1) | 
                                              is_control_title == 1) &
                                             months_since_first_state_ban >= -4 & months_since_first_state_ban <= 6])

setFixest_dict(c(ln_circ = "Log(Circulation)", post_ban = "PostBan $\\times$ Banned", is_banned = "Banned", 
                 same_genre_title = "SameGenre", same_bisac_title = "SameBISAC", 
                 sam_author_title = "SameAuthor",
                 is_banned_ever = "Banned", state = "State", running_month = "Year Month", title = "Title"))
etable(m_avg_same_genre, m_avg_same_bisac, m_avg_same_author,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Impact of Ban Events on Circulation of Other Books",
       fitstat = ~ r2 + n, placement = "h", se.below = T, se.row = F,
       headers = list(list("Genre", "BISAC", "Author")))

# Table A3
# Col 1 - Average TWFE
# Col 2 - Average TWFE in banned states only
# Col 3 - Average TWFE in non-banned states only
# Col 4 - Heterogeneity with author experience
# Col 5 - Heterogeneity with twitter visibility
# Col 6 - Average TWFE in blue states only
# Col 7 - Average TWFE in red states only
lib_circ_dt <- fread("./data/replication_data/lib_circ_data.csv")

m_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
               cluster = c('state'), 
               data = lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
                                    months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_avg_ban <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                   cluster = c('state'),
                   data = lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
                                        months_since_first_ban >= -4 & months_since_first_ban <= 6 &
                                        is_ban_state == 1])

m_avg_non_ban <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                       cluster = c('state'),
                       data = lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
                                            months_since_first_ban >= -4 & months_since_first_ban <= 6 & 
                                            is_ban_state == 0])

m_avg_gr_pop <- feols(ln_circ ~ post_ban*is_banned_ever*unpop_author | state + title + running_month, 
                      cluster = c('state'),
                      data = lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
                                           months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_avg_vis <- feols(ln_circ ~ post_ban*is_banned_ever*high_visibility | state + title + running_month, 
                   cluster = c('state'),
                   data = lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) & 
                                        months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_avg_blue <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                    cluster = c('state'),
                    data = lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
                                         months_since_first_ban >= -4 & months_since_first_ban <= 6 &
                                         is_blue_state == 1])

m_avg_red <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                   cluster = c('state'),
                   data = lib_circ_dt[(is_top_25_title == 1 | is_matched_control_title == 1) &
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

# Table A4
# Col 1 - Inverse hyperbolic sine transformation
# Col 2 - Negative binomial distribution assumption
# Col 3 - Category lift
# Col 4 - Mean lift
# Col 5 - Organic growth assumption
# Col 6 - False treatment check
# Col 7 - Alternate pre-treatment window
m_ihs_avg <- feols(asinh(circ) ~ post_ban*is_banned_ever | state + title + running_month, 
                   cluster = c('state'),
                   data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                     months_since_first_ban >= -4 & months_since_first_ban <= 6])


m_avg_lift <- feols(lift ~ post_ban*is_banned_ever | state + title + running_month, 
                    cluster = c('state'), 
                    data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                      months_since_first_ban >= -4 & months_since_first_ban <= 6])


m_avg_cat_lift <- feols(cat_lift ~ post_ban*is_banned_ever | state + title + running_month, 
                        cluster = c('state'), 
                        data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                          months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_nb_avg <- fenegbin(circ ~ post_ban:is_banned_ever | state + title + running_month, 
                     cluster = c("state"), 
                     data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                       months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_org_gwt_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + quarter^state + quarter, 
                       cluster = c('state'),
                       data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                         months_since_first_ban >= -4 & months_since_first_ban <= 6])

rand_circ_dt <- fread("./data/replication_data/rand_circ_data.csv")
m_false_avg <- feols(ln_circ ~ post_rand_ban*is_rand_banned | state + title + running_month, 
                     cluster = c('state'),
                     data = rand_circ_dt)

m_alt_pre_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                       cluster = c('state'),
                       data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                         months_since_first_ban >= -6 & months_since_first_ban <= 6])

setFixest_dict(c(ln_circ = "Log(Circulation)", "asinh(circ)" = "Circulation", lift = "Lift", cat_lift = "Lift", post_ban = "PostBan $\\times$ Banned", 
                 circ = "Circulation", is_banned = "Banned", "post_ban:is_banned_ever" = "PostBan $\\times$ Banned",
                 is_banned_ever = "Banned", state = "State", running_month = "Year Month", title = "Title", post_rand_ban = "PostBan $\\times$ Banned", 
                 quarter = "Quarter"))
etable(m_ihs_avg, m_nb_avg, m_avg_cat_lift, m_avg_lift, m_org_gwt_avg, m_false_avg, m_alt_pre_avg,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Impact of Ban Events on Circulation",
       fitstat = ~ r2 + n, placement = "h", se.below = T, adjustbox = 0.95, family = F, se.row = F,
       headers = list(list("IHS", "Negative","Category", "Mean", "Organic", "False", "Alternate"),
                      list("", "Binomial", "Lift", "Lift ", "Growth", "Treatment", "Pre-period")))

# Table A5
# Col 1 - At least 4 bans
# Col 2 - At least 3 bans
# Col 3 - At least 4 bans and no spillover assumption
# Col 4 - At least 3 bans and no spillover assumption
# Col 5 - Intensity of ban
# Col 6 - More vs less bans

m_ban_int_avg <- feols(ln_circ ~ post_ban + post_ban:is_banned_ever:cum_num_bans | state + title + running_month,
                       cluster = c('state'),
                       data = lib_circ_dt[(is_top_25_title == 1 | is_control_title == 1) &
                                         months_since_first_ban >= -4 & months_since_first_ban <= 6])

lib_circ_dt[, post_ban := as.integer(months_since_first_ban >= 0)]
m_ban_hi_lo_avg <- feols(ln_circ ~ post_ban*is_banned_ever:more_bans | state + title + running_month, 
                         cluster = c('state'),
                         data = lib_circ_dt[(is_banned_title == 1 | is_control_title == 1) &
                                           months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_te_4ban_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                       cluster = c('state'),
                       data = lib_circ_dt[(is_four_ban_title == 1 | is_control_title == 1) &
                                         months_since_first_ban >= -4 & months_since_first_ban <= 6])
lib_circ_dt[, post_ban := as.integer(months_since_ban >= 0)]
m_tse_4ban_avg <- feols(ln_circ ~ post_ban*is_banned | state + title + running_month, 
                        cluster = c('state'),
                        data = lib_circ_dt[((is_four_ban_title == 1  & is_banned == 1) | is_control_title == 1) &
                                          months_since_ban >= -4 & months_since_ban <= 6 & 
                                            is_ban_state == 1])

lib_circ_dt[, post_ban := as.integer(months_since_first_ban >= 0)]
m_te_3ban_avg <- feols(ln_circ ~ post_ban*is_banned_ever | state + title + running_month, 
                       cluster = c('state'),
                       data = lib_circ_dt[(is_three_ban_title == 1 | is_control_title == 1) &
                                         months_since_first_ban >= -4 & months_since_first_ban <= 6])
lib_circ_dt[, post_ban := as.integer(months_since_ban >= 0)]
m_tse_3ban_avg <- feols(ln_circ ~ post_ban*is_banned | state + title + running_month, 
                        cluster = c('state'),
                        data = lib_circ_dt[((is_three_ban_title == 1  & is_banned == 1) | is_control_title == 1) &
                                          months_since_ban >= -4 & months_since_ban <= 6 & 
                                            is_ban_state == 1])

setFixest_dict(c(ln_circ = "Log(Circulation)", post_ban = "PostBan $\\times$ Banned", 
                 "post_ban:is_banned_ever:cum_num_bans" = "PostBan $\\times$ Banned $\\times$ Intensity of Ban",
                 "post_ban:is_banned_ever:more_bans" = "PostBan $\\times$ Banned $\\times$ $>=$ Five Bans",
                 unpop_author = "Less-experienced Author", cum_num_bans = "Intensity of Ban",
                 is_banned_ever = "Banned", state = "State", running_month = "Year Month", title = "Title",
                 more_bans = "$>=$ Five Bans", is_banned = "Banned"))
etable(m_te_4ban_avg, m_te_3ban_avg, m_tse_4ban_avg, m_tse_3ban_avg, m_ban_int_avg, m_ban_hi_lo_avg,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Additional Robustness: Impact of Ban Events on Circulation",
       fitstat = ~ r2 + n, placement = "h", se.below = T, se.row = F, 
       headers = list(list("At least", "At least ", "At least", "At least ", "Impact", "More"),
                      c("Four", "Three", "Four", "Three", "Per", "vs. Less"),
                      c("Bans", "Bans ", "Bans", "Bans ", "Ban", "Bans ")))

# Table A6
# Col 1 - Average TWFE with # reviews per month as DV
# Col 2 - Average TWFE with # reviews with ban like words as DV
# Col 3 - Average TWFE with ratings as DV

gr_dt <- fread("./data/replication_data/gr_reviews_data.csv")


m_gr_rev_avg <- feols(ln_num_reviews ~ post_ban*is_banned_ever | title + running_month, se = "hetero",
                      data = gr_dt[months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_gr_rat_avg <- feols(rating ~ post_ban*is_banned_ever | title + running_month, se = "hetero",
                      data = gr_dt[months_since_first_ban >= -4 & months_since_first_ban <= 6])

m_gr_ban_rev_avg <- feols(ln_num_ban_reviews ~ post_ban*is_banned_ever | title + running_month, se = "hetero",
                          data = gr_dt[months_since_first_ban >= -4 & months_since_first_ban <= 6])

setFixest_dict(c(ln_circ = "Log(Circulation)", post_ban = "PostBan $\\times$ Banned", is_banned = "Banned", 
                 high_visibility = "High Visibility", unpop_author = "Less-experienced Author",
                 is_banned_ever = "Banned", state = "State", running_month = "Year Month", title = "Title"))
etable(m_gr_rev_avg, m_gr_ban_rev_avg, m_gr_rat_avg,
       style.tex = style.tex(fixef.title = "", fixef.suffix = " Fixed Effect", yesNo = "Yes", 
                             model.title = "", main = "base", stats.title = "\\midrule"),
       tex = T, digits = 3, title = "Impact of Ban Events on Goodreads reviews",
       fitstat = ~ r2 + n, placement = "h", depvar = F, 
       se.below = T, headers = list(list("Reviews", "Reviews ", "Ratings"),
                                    c("", "with Bans", "")), se.row = F)
