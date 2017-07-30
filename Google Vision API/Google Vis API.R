# Normal Libraries
library(tidyverse)

# devtools::install_github("flovv/RoogleVision")
library(RoogleVision)
library(jsonlite) # to import credentials

# For image processing
# source("http://bioconductor.org/biocLite.R")
# biocLite("EBImage")
library(EBImage)

# For Latitude Longitude Map
library(leaflet)

creds = fromJSON('credentials.json')

# Google Authentication - Use Your Credentials
# options("googleAuthR.client_id" = "xxx.apps.googleusercontent.com")
# options("googleAuthR.client_secret" = "")

options("googleAuthR.client_id" = creds$installed$client_id)
options("googleAuthR.client_secret" = creds$installed$client_secret)
options("googleAuthR.scopes.selected" = c("https://www.googleapis.com/auth/cloud-platform"))
googleAuthR::gar_auth()

dog_mountain_label = getGoogleVisionResponse('dog_mountain.jpg',
                                              feature = 'LABEL_DETECTION')
dog_mountain_label

us_landmark = getGoogleVisionResponse('us_castle_2.jpg',
                                      feature = 'LANDMARK_DETECTION')
us_landmark
us_castle <- readImage('us_castle_2.jpg')
plot(us_castle)
xs = us_landmark$boundingPoly$vertices[[1]][1][[1]]
ys = us_landmark$boundingPoly$vertices[[1]][2][[1]]
polygon(x=xs,y=ys,border='red',lwd=4)

latt = us_landmark$locations[[1]][[1]][[1]]
lon = us_landmark$locations[[1]][[1]][[2]]

m = leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  setView(lng = lon, lat = latt, zoom = 5) %>%
  addMarkers(lng = lon, lat = latt)
m


us_dog_mountain_face = getGoogleVisionResponse('us_dog_mountain.jpg',
                                            feature = 'FACE_DETECTION')
us_dog_mountain_face

dog_mountain_logo = getGoogleVisionResponse('dog_mountain.jpg',
                                              feature = 'LOGO_DETECTION')
dog_mountain_logo

dog_mountain_labels = getGoogleVisionResponse('dog_mountain.jpg',
                                              feature = 'TEXT_DETECTION')


o <- getGoogleVisionResponse("brandlogos.png")
o <- getGoogleVisionResponse(imagePath="brandlogos.png", 
                             feature="LOGO_DETECTION", 
                             numResults=4)
getGoogleVisionResponse("https://media-cdn.tripadvisor.com/media/photo-s/02/6b/c2/19/filename-48842881-jpg.jpg", 
                        feature="LANDMARK_DETECTION")

