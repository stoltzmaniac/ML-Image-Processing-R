source('imageFunctions.R')
library("videoplayR")

# Take a picture and save it
img = webcamImage(rollFrames = 10, 
                  showImage = FALSE,
                  saveImageToWD = 'originalWebcamShot.png')

# Run Python script to detect faces, draw rectangles, return new image
system('python3 facialRecognition.py')

# Read in new image
img.face = readImg("modifiedWebcamShot.png")

# Display images
imshow(img)
imshow(img.face)