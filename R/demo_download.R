options(timeout=4000)
download.file("https://www.dropbox.com/scl/fi/589yd0lm792cvxudzsocq/Archiv.zip?rlkey=bj5i6elawuvay5ltf9nfqq04z&dl=1", destfile = paste0(tempdir(),"demo_tiffs.zip"))


unzip(paste0(tempdir(),"demo_tiffs.zip"),exdir = "../data/Tiffs")

unlink("../data/Tiffs/__MACOSX/",recursive =T)
