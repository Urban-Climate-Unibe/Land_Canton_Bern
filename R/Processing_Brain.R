#Brain of what to do

# We want to know, if a certain file already exists
name.of.file <- "../data/Combined.csv"



# If do not exists such a file, we create it
if (file.exists(name.of.file)){
  repeat{
  print("Basefile exists, data processing not required.")
  processing = readline(prompt = "Would you still like to redo the processing? [y/n] ")
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


    # Remove all Tiffs when processing
    if (length(files) > 0) {
      unlink(files, recursive = TRUE)


    }



     repeat{
      print("File will be processed. There is the option to run it normally (time intensive) or in demo mode.")
      demo = readline(prompt = "Would you like to run it in demo mode? [y/n] ")
      if(demo %in% c("y","n")){break}
     }
    if (demo == "y") {


      source("../R/demo_download.R")


      }else{
        repeat{
        print("File will be processed in full version. there is the option to run it with layers as in BURGER et al.2019 or with all layers.")
        full = readline(prompt = "Would you like to run with all layers? [y/n] ")
        if(full %in% c("y","n")){break}
        }
    if (full == "y") {
      source("../R/raw_tif_processing_2.R")
    }else{
      source("../R/raw_tif_processing.R")
    }


  }
    #do in any case when processing of tiffs
    source("../R/data_combination.R")
    data_combination()



  }else{
    print("there will be no processing")
  }



