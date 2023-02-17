# Clean variables
rm(list = ls())
gc()

# set time 
Sys.setenv(TZ = "GMT")

# load libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load("sp", "rgdal", "stringr", "ncdf4", "here", "NCmisc", "raster", "utils", "readr", "ncdf4", "abind", "reticulate")

# set working directory
wkdir<-"E:/RScripts_Clean/ME_Gridded_Rainfall_csv2netcdf/Script_Stack/"
setwd(paste0(wkdir, "/RR81_csv_format"))

# list files with NI  prefix
fle_nme<-dir(pattern="RR81*")

# loop through all days
for (fle_sel in seq(1, length(fle_nme))){
  
  # empty raster stack
  ras_stck_pr<-stack()
  
  # empty date stamp
  date_stmp = .POSIXct(as.character())  
  
  print(fle_nme[fle_sel])
  
  # read in file
  RR81<-read_csv(fle_nme[fle_sel])
  
  for (dy_sel in seq(3, dim(RR81)[2])){
    # process column
    print(dy_sel)
    pts<-RR81[, dy_sel]
    pts$x<-RR81$east
    pts$y<-RR81$north
    pts = data.frame(cbind(x = pts$x, y = pts$y, Gridded_Rainfall = RR81[, dy_sel]/10))
    coordinates(pts)=~x+y
    gridded(pts) = TRUE
    r = raster(pts)
    ras_stck_pr = stack(ras_stck_pr, r)  
  }
  # concatenate date stamp
  date_stmp<-as.POSIXct(str_remove(colnames(RR81)[3:dim(RR81)[2]], "X"), format="%Y%m%d", tz = "UTC")
  
  # add date 
  ras_stck_pr<-setZ(ras_stck_pr, date_stmp, "Date")
  
  # reorder the data based on the time stamp
  ras_stck_pr = ras_stck_pr[[order(date_stmp)]]

    # set projection (29903) https://epsg.io/29903-1042
  projection(ras_stck_pr) <- CRS("+init=epsg:29903")

  outfile <- paste0(wkdir, "/RR81_netcdf_format/", str_remove(fle_nme[fle_sel], ".csv"), ".nc", sep="")
  writeRaster(ras_stck_pr, outfile, overwrite=TRUE, format="CDF",
              varname="pr", varunit="cm", longname="Daily Gridded Rainfall RR81D -- raster layer to netCDF",
              xname="Easting", yname="Northing",
              zname="time", zunit="seconds")
  
}  
