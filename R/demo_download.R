options(timeout=4000)
download.file("https://www.dropbox.com/scl/fi/mgnv29w6ghgd6ot5j7xwh/Archiv.zip?rlkey=n3qioppphwrmqas8qdhclfpaj&dl=1", destfile = paste0(tempdir(),"demo_tiffs.zip"))


unzip(paste0(tempdir(),"demo_tiffs.zip"),exdir = "../data/Tiffs")

unlink("../data/Tiffs/__MACOSX/",recursive =T)
