

WHAT DRIVES DEMAND FOR PLAYLISTS ON SPOTIFY?


Replication files for “What drives demand for playlists on Spotify”,
_Marketing Science_, forthcoming.

by Max Pachali (m.j.pachali@tilburguniversity.edu) and Hannes Datta
(h.datta@tilburguniversity.edu)

Links:

-   Paper available at [LINK HERE]
-   Replication files available at https://doi.org/10.34894/UWGH5S
-   Publicly available data does contain _all_ of the datasets available
    to replicate the analysis and reporting (\analysis and reporting).
    Files necessary to build these final data files (derived) are
    available to the co-authors but have not been edited for public
    release (e.g., to preserve the personal identity of some of the
    playlist curators).


Abstract

We provide estimates of the drivers of playlist followers on Spotify. We
base our analysis on a unique panel data set for 30,000+ popular
playlists and combine it with data on how prominently these playlists
are featured in the Spotify app. Using two-way fixed effects and
staggered synthetic difference in difference models, we compare the
short-term effect of two important demand factors in our data—featuring
playlists on Spotify’s Search Page and adding songs by exceptionally
popular major label artists to playlists. We find that users prefer to
follow playlists featured in the app. According to our estimates, being
featured on the Search Page raises daily playlist followers by
0.95%—which is about two times larger than the effect on followers of
including a song by an exceptionally popular major label artist (0.45%).
Our examination of playlist demand has two important implications.
First, Spotify can effectively guide user attention to certain
playlists, supporting industry executives’ and artists’ concerns that
the platform has the potential to favor some producers by selectively
promoting their content. Second, popular artists signed with major
labels play an important role in attracting followers to playlists on
Spotify.


Overview of this Replication Package

This replication package is based on the replication guidelines from
Tilburg School of Economics and Management (TiSEM).

1) Metadata and data collection

a)  File logs are available in docs/files_in_repository.csv. Hannes
    Datta and Max Pachali created and edited all files except those
    explicitly mentioned for some selected raw data files.

b)  Access was available to all coauthors; Hannes Datta compiled the
    final replication package. Copies of the replication package are
    stored at Dataverse and are available from each of the coauthors.

c)  No ethical review for this project was conducted when starting this
    project.

d)  Role of coauthors: Hannes Datta (data collection, data preparation,
    data analysis, article writing), Max Pachali (data preparation, data
    analysis, article writing).

e)  Data sources and preparation: as described in paper; key data sets
    are from Chartmetric (playlist meta data and performance),
    everynoise.com (promotions), and Kaggle (Billboard Charts, Spotify
    Charts); supplementary data compiled by coauthors.

f)  Reliance on external data sources: If applicable, sources noted in
    the paper.

g)  The authors acknowledge financial support from the Dutch Research
    Council (NWO 451-17-028) and research support from Tilburg Science
    Hub.

h)  Date of acceptance: 22 April 2024.

This project contains a set of _self-contained_ submodules to replicate
the data preparation and analysis.

2) Raw data

-   The project relies on data purchased via an API subscription from
    Chartmetric, scraped via everynoise.com, and downloaded from Kaggle
    (Billboard, Spotify Charts). The data is stored in
    derived\externals. This data is not available to the general public,
    as it contains personal data (e.g., usernames and user IDs of
    persons who have created playlists). Deintentifying persons is
    beyond the scope of creating this replication package.
-   All data can be shared for replication purposes in the event of an
    investigation into alleged research misconduct (see also Netherlands
    Code of Conduct for Research Integrity and TiSEM’s replication
    policy).
-   All files are stored at Tilburg University
    (\\stafffiles.campus.uvt.nl\files\shared\research\platformpower-mktsci),
    and copies are available with all the coauthors.
-   The dataset docs/files_in_repository.csv contains a list with all
    files in the package, along with their dates of creation and other
    relevant meta data.
-   This replication file contains all data relevant to computationally
    reproduce the analysis and reporting stage (documented in
    corresponding PDF files), covering
    -   (a) meta data on all 1.2m playlists
            (analysis\temp\playlists.csv),

    -   (b) daily playlist panel with 30k+ playlists observed between
            Oct. 2019 and March 2020 (analysis\temp\panel.csv),

    -   (c) dynamic playlist categories
            (analysis\temp\playlist-categories.csv)

    -   (c) promotional data on playlists at Spotify’s Search Page
            (Oct. 2019 until March 2021) (analysis\temp\promotions.csv),

    -   (d) information of tracks available on playlists on Spotify
            (analysis\temp\placements-selected-only.csv and
            analysis\temp\top_artists_placements.csv), and

    -   (e) meta data on superstar artists
            (analysis\temp\top_artists.csv).

3) Material

This project can be entirely replicated using computer code (code) and
any files contained in the externals directory of one of the main
submodules.

4) Programming code

-   The programming code is fully available; see subfolder code\.
-   Submodules are \derived (for converting the raw data to data sets
    for analysis), \analysis (for running the sales response models),
    reporting (for creating figures and tables), and paper (for the
    source files of the Latex paper and slides).
-   The order of execution in each submodule is made explicit in a
    makefile (see https://tilburgsciencehub.com/learn/makefile).

5) Processed database(s)

-   Any processed information is available in the subfolders of each
    main module.
-   Processed files include temporary files (temp/), auditing files
    (audit/), and output files (output/). All these files are
    exclusively produced based on code.

6) Accepted or published manuscript or publication

Published manuscript available at [INSERT LINK HERE]


Replication Instructions

Build instructions

Before you run any of the code, please follow the setup instructions
below.

The project uses the following tool stack: - R 4.3 - Python 3 - GNU Make
4.4 (see https://www.gnu.org/software/make/) - older versions of make
lead to very inefficient builds (AWS calls get repeatedly executed,
causing the pipeline to “never be done”) - AWS S3 for raw data storage -
Git for versioning

Install software

Automatic installation on Linux server

Open the terminal, and paste - one after another - the following
commands.

    ######## RUN THESE SCRIPTS TOGETHER #######

    # (e.g., copy them to a `.sh` file and execute it using `bash <filename.sh>` on Linux)

    # Install AWS client
    sudo apt install -y awscli

    # Install packages required for some R packages
    sudo apt-get install -y libfontconfig1-dev
    sudo apt-get install -y libgsl-dev

    # Install tex live to convert .tex documents to PDF
    sudo apt-get install -y texlive
    sudo apt-get install -y texlive-science 
    sudo apt install -y texinfo
    sudo apt-get install -y texlive-fonts-recommended
    sudo apt install -y texlive-latex-extra
    sudo apt-get install -y texlive-fonts-extra
    sudo apt-get install -y libcairo2-dev
    sudo apt install -y libfontconfig1-dev
    sudo apt install -y libharfbuzz-dev libfribidi-dev
    sudo apt-get install -y libtiff-dev
    sudo apt install -y libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev

    # Git LFS
    sudo apt-get install -y git-lfs

    sudo apt-get install -y python3-pip

    pip3 install --upgrade awscli
    pip3 install numpy
    pip3 install pandas


    ######## RUN THESE SCRIPTS ONE-BY-ONE #######

    ## setup AWS credentials
    aws configure 

    ## clone repository and configure Git

    # clone this repository
    git clone https://github.com/hannesdatta/platformpower

    # make Git configuration permanent
    git config credential.helper store

    # if you're the only user of the machine, you may prefer making the Git settings permanent
    git config --global credential.helper store

    # set Git email address and user name
    git config --global user.email "you@example.com"
    git config --global user.name "Your Name"

    ## Install all relevant R packages

    # navigate to the repostiory's root directory, and install the required R packages
    Rscript install_packages.R

    # Download and install GNU Make 4.4
    # see https://www.gnu.org/software/make/ (instructions in INSTALL)

Manual installation

-   follow the installation instructions on
    https://tilburgsciencehub.com for
    -   Git
    -   Make (remember to add it to your PATH variable)
    -   R (remember to add it to your PATH variable)
    -   Latex
    -   TableFill
-   in addition, install AWS Command Line Interface from
    https://aws.amazon.com/cli/, used for obtained large-scale
    (gb-intensive) pre-builds of part of the project.

-   run the following code to install packages in R: install.packages.R

-   install the following Python packages, using pip or pip3

    pip3 install numpy
    pip3 install pandas
    pip3 install pandas

-   verify that the user environment variable R_LIBS_USER is set
    (especially on the Tilburg Blade server); otherwise, packages cannot
    be found when running make. Set R_LIBS_USER to the location of your
    user libraries, e.g.,
    E:/users/YOUR-USERNAME/documents/R/win-library/4.1

-   setup AWS Command Line Interface
    -   install AWS Command Line Interface

    -   type

    aws configure

    Then, enter the following information:

        AWS Access Key ID [None]: [your access key here]
        AWS Secret Access Key [None]: [your secret key here]
        Default region name [None]: eu-central-1
        Default output format [None]: [just hit enter]

    -   see also
        http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html
        for more details and instructions

Check out the repository

Please create a fresh root directory for this project, now referred to
as \root.

\root\platformpower <- GitHub repository, containing code

Navigate to \root, and checkout the Git code repository.

git clone https://github.com/hannesdatta/platformpower

Recall, for the repository to be checked out, you require a username and
password (sign up with GitHub first), and you need to be registered as a
contributor/viewer of this repository (contact the authors).

Running instructions

To execute code in any of the submodules, follow the steps below: * on
Windows computers, open anaconda prompt * navigate to the \code
directory in the submodule * run make to download relevant data and
build the module * you will find output files in \output (e.g.,
datasets, analyses, …)


Documentation

The documentation for this project has been built using the tools
available in docs.
