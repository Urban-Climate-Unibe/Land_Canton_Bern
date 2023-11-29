
preprocessing <- function(){
#Brain of what to do in main for preprocessing

# We want to know, if a certain file already exists
name.of.file <- "../data/Combined.csv"



# If do not exists such a file, we create it
if (file.exists(name.of.file)){
  repeat{
  print("Basefile exists, data processing not required.")
  processing = readline(prompt = "Would you still like to redo the processing of the data? [y/n] ")
  if(processing %in% c("y","n")){break}
  }

}else{

  print("Basefile doesnt exist, data processing required.")
  processing <- "y"
}


  if (processing == "y") {

    dir.create("../data-raw/", showWarnings = FALSE) #create data-raw if missing...
    dir.create("../data/Tiffs/", showWarnings = FALSE) #create data-raw if missing...

    # List all files within Tiffs
    files <- list.files(path = "../data/Tiffs", full.names = TRUE)


    # Remove all Tiffs when processing, to keep organised
    if (length(files) > 0) {
      unlink(files, recursive = TRUE)
    }



     repeat{
      print("File will be processed. There is the option to generate the Tiff files from scratch (time intensive) or download the Tiffs from an external source (quick).")
      print("The download version will result in all Tiffs being downloaded.")
      demo = readline(prompt = "Would you like to download the Tiffs? [y/n] ")
      if(demo %in% c("y","n")){break}
     }
    if (demo == "y") {


      source("../R/demo_download.R")


      }else{
        repeat{
        print("Tiffs will be generated. there is the option to generate the Tiffs as in BURGER et al. 2019 or with all Tiffs ( 3 classes; 25/150/1000 meters per source).")
        full = readline(prompt = "Would you like to generate all Tiffs? [y/n] ")
        if(full %in% c("y","n")){break}
        }
    if (full == "y") {
      print("all Tiffs are generated.")
      source("../R/raw_tif_processing_2.R")
    }else{
      print("Tiffs from Burger et al. 2019 are generated.")
      source("../R/raw_tif_processing.R")
    }


  }
    #do in any case when processing of tiffs
    print("CSV files is being created...")
    source("../R/data_combination.R")
    data_combination()



  }else{
    print("there will be no processing")
  }



}
