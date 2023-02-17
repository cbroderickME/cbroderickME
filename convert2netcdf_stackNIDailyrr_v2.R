
# if necessary to unzip 
# # # # zipF<-dir(pattern="*.gz")
# # # # ldply(.data = zipF, .fun = gunzip)
# # # # fle_lst<-dir(pattern="*.csv")

# Clean variables
rm(list = ls())
gc()

# set time 
Sys.setenv(TZ = "GMT")

# load libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load("sp", "rgdal", "stringr", "ncdf4", "dplyr", "NCmisc", "raster", "utils", "readr")

# set working directory
wkdir<-"E:/RScripts_Clean/ME_Gridded_Rainfall_csv2netcdf/Script_Stack/"
setwd(paste0(wkdir, "/NIDailyrr_csv_format"))

# list files with NI  prefix
fle_nme<-dir(pattern="NIDailyrr*")

# empty raster stack
ras_stck_pr<-stack()

date_stmp = .POSIXct(as.character())

# loop through all days
for (fle_sel in seq(1, length(fle_nme))){  
  print(fle_sel)
  # extract info on date
  yr<-str_match(fle_nme[fle_sel], "rr\\s*(.*?)\\s*m")[2]
  mth<-str_match(fle_nme[fle_sel], "m\\s*(.*?)\\s*d")[2]
  dy<-str_match(fle_nme[fle_sel], "d\\s*(.*?)\\s*grid")[2]
  
  # read in csv file
  NIDrr<-tibble(read.csv(fle_nme[fle_sel]))
  
  # create time stamp
  date_stmp<-c(date_stmp, as.POSIXct(paste(yr, mth, dy, sep="-"), format="%Y-%m-%d"))
  
  
    for (dy_sel in seq(3, dim(NIDrr)[2])){
      print(dy_sel)
      # process column
      pts<-NIDrr[, dy_sel]
      pts$x<-NIDrr$east
      pts$y<-NIDrr$north
      pts = data.frame(cbind(x = pts$x, y = pts$y, Gridded_Rainfall = NIDrr[, dy_sel]/10))
      coordinates(pts)=~x+y
      gridded(pts) = TRUE
      r = raster(pts)
      ras_stck_pr = stack(ras_stck_pr, r)  
    }
  
  # add date 
  ras_stck_pr<-setZ(ras_stck_pr, date_stmp, "Date")
   
  # set projection (29903) https://epsg.io/29903-1042
  #projection(ras_stck_pr) <- CRS("+proj=tmerc +lat_0=53.5 +lon_0=-8 +k=1.000035 +x_0=200000 +y_0=250000 +ellps=mod_airy +towgs84=482.5,-130.6,564.6,-1.042,-0.214,-0.631,8.15 +units=m +no_defs")
  crs(ras_stck_pr) <- CRS('+init=EPSG:29903')
  
  # reorder the data based on the time stamp
  ras_stck_pr = ras_stck_pr[[order(date_stmp)]]
  
  outfile <- paste0(wkdir, "/IRL_DLY_RR_netcdf_format/", str_remove(fle_nme[fle_sel], ".csv"), ".nc",sep="")
  writeRaster(ras_stck_pr, outfile, overwrite=TRUE, format="CDF", 
               varname="pr", varunit="mm", longname="Daily Gridded Rainfall IRL_DLY_RR -- raster layer to netCDF", 
               xname="Easting", yname="Northing",
               zname="time", zunit="seconds")
}
