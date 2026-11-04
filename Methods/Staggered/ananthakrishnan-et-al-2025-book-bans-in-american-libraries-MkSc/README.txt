This file describes the datasets and scripts used to replicate the results reported in "Book Bans in American Libraries: Impact of Politics on Inclusive Content Consumption" by Uttara M. Ananthakrishnan, Naveen Basavaraj, Sabari Rajan Karmegam, Ananya Sen, Michael D. Smith.

There are four datasets included that are used to replicate the results. We are unable to provide any additional datasets, as they were shared with us under strict non-disclosure agreements. However, we are providing log files and markdown files that were produced by running the code using the R files provided.

1. campaign_email_data.csv
party: Name of the political party to which a political candidate belongs to
post: Dummy indicating whether the month is before or after July 2021
num_mails: Mean number of book ban-related emails per month


2. gr_reviews_data.csv
title: Book title ID
running_month: Month ID
ln_num_reviews: Log of count of reviews per title per month
ln_num_ban_reviews: Log of count of reviews that refer to words related to book bans per title per month
rating: Mean numeric rating per title per month
post_ban: Dummy indicating month is before or after first ban
is_banned_ever: Dummy indicating whether the title is banned or control title
months_since_first_ban: Relative count of months since first ban


3. news_by_region_data.csv
months_since_event: Relative count of months since ban event
is_national: Dummy variable that indicates focal state event (LF), non-focal state event (LNF), or national newspaper (N) coverage
num_articles: Mean number of articles per ban event

4. news_salience_data.csv
title: Book title ID
month: calendar month
is_top_25_title: Dummy variable indicating if a title is a top-25 title or not
is_mega_ban_month: Dummy variable indicating if a mega ban event happened during the given month or not
ln_num_articles: Log of count of news articles per month

There are four scripts

1. tables_main_code.R replicates tables in the main manuscript - Tables 1, 2, 3, 4, 5, 6, 7, 8

2. figures_main_code.R replicates figures in the main manuscript - Tables 3, 4, 5, 6, 7, 8, 9

3. tables_appendix_code.R replicates tables in the online appendix - Tables A2, A3, A4, A5, A6

4. figures_appendix_code.R replicates tables in the online appendix - Tables A2, A3, A4, A5, A6, A7, A8

There are four log and markdown files

1. tables_main_code.Rout - log file produced by running the code in tables_main_code.R file

2. figures_main_code.pdf - markdown file produced by running the code in figures_main_code.R file

3. tables_appendix_code.Rout - log file produced by running the code in tables_appendix_code.R file

4. figures_appendix_code.pdf - markdown file produced by running the code in figures_appendix_code.R file

Variable definitions for the log and markdown files - 
ln_num_articles: Log of count of news articles per title per month
ln_count: Log of count of tweets per title per month
is_top_25_title: Dummy variable indicating if a title is a top-25 title
is_control_title: Dummy indicating whether the title is a control title
month: Calendar month
ban_shelved: Number of times a title is added to a ban-related shelf on Goodreads
lgbt_shelved: Number of times a title is added to a LGBTQ-related shelf on Goodreads
school_shelved: Number of times a title is added to a school-related shelf on Goodreads
ln_circ: Log of circulation per title per state per month
post_ban: Dummy indicating month is before or after first ban
is_banned_ever: Dummy indicating whether the title is banned or control title
is_banned: Dummy indicating whether the title is banned in a state
state: State ID
title: Book title ID
running_month: Month ID
months_since_first_ban: Relative count of months since first ban
months_since_single_ban: Relative count of months since first significant ban event
months_since_ban: Relative count of months since first ban in a state
cum_num_bans: Cumulative monthly count of bans for each title
is_ban_state: Dummy variable indicating if the state had at least one book banned during the time period
unpop_author: Dummy variable indicating if the book was written by a less-experienced author
high_visibility: Dummy variable indicating if the title has high visibility on Twitter
is_blue_state: Dummy variable indicating if the majority vote in the state was for Joe Biden in the 2020 election
is_red_state: Dummy variable indicating if the majority vote in the state was for Donald Trump in the 2020 election
ln_amount: Log sum of small-dollar donation
is_rep_cmt: Dummy variable indicating if the political candidate is of the Republican party
cand_state: State of the political candidate
CAND_ID: Unique ID of the political candidate
same_genre_title: Dummy variable indicating if the title is of the same genre as that of the the banned titles
same_bisac_title: Dummy variable indicating if the title has the same BISAC code as that of the banned titles
same_author_title: Dummy variable indicating if the title is written by authors of banned book titles
lift: Ratio of circulation to mean circulation of the same title in the pre-ban period 
cat_lift: Ratio of circulation to mean pre-ban circulation of all the titles in the same category (BISAC) as that of the title
post_rand_ban: Dummy indicating month is before or after randomized ban month
is_rand_banned: Dummy indicating whether the title is banned or control title
more_bans: Dummy variable indicating if the title is banned more than five times or not
is_four_ban_title: Dummy variable indicating if the title is banned more than four times or not
is_three_ban_title: Dummy variable indicating if the title is banned more than three times or not