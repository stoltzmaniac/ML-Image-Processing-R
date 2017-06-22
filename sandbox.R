source('imageFunctions.R')
library(videoplayR)

img = webcamImage(rollFrames = 10, 
                  showImage = TRUE,
                  saveImageToWD = 'newImage.png')


