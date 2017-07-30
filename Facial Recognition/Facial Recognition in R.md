---
title: "Facial Recognition in R"
author: "Scott Stoltzman"
date: "6/22/2017"
output: html_document
---

### Facial Recognition in R

![Original](originalWebcamShot.png) ![FaceDetection](modifiedWebcamShot.png)

OpenCV is an incredibly powerful tool to have in your toolbox. I have had a lot of success using it in Python but very little success in R. I haven't done too much other than searching Google but it seems as if "imager" and "videoplayR" provide a lot of the functionality but not all of it.  

I have never actually called Python functions from R before. Initially, I tried the "rPython" library - that has a lot of advantages, but was completely unecessary for me so system() worked absolutly fine. While this example is extremely simple, it should help to illustrate how easy it is to utilize the power of Python from within R.  

Using videoplayR I created a function which would take a picture with my webcam and save it as "originalWebcamShot.png"  

**Note:** saving images and then loading them isn't very efficient but works in this case and is extremely easy to implement. It saves us from passing variables, functions, objects, and/or methods between R and Python in this case.    

I'll trace my steps backward through this post (I think it's easier to understand what's going on in this case).  

#### The main.R file:  

  1. Calls my user-defined function 
    * Turns on the camera
    * Takes a picture
    * Saves it as "originalWebcamShot.png"
  2. Runs the Python script 
    * Loads the previously saved image
    * Loads the Haar Cascade algorithms
    * Detects faces and eyes
    * Draws colored rectangles around them
    * Saves the new image as "modifiedWebcamShot.png"
  3. Reads new image into R
  4. Displays both images  



```r
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
```
  

The user-defined function:  

  1. Function inputs  
    * rollFrames is the number of pictures to take (allows the camera to adjust)
    * showImage gives the option to display the image
    * saveImageToWD saves the image generated to the current working directory
  2. Turns the webcam on
  3. Takes pictures (number of rollFrames)
  4. Uses basic logic to determine to show images and/or save them
  5. Returns the image




```r
library("videoplayR")

webcamImage = function(rollFrames = 4, showImage = FALSE, saveImageToWD = NA){
  
  # rollFrames runs through multiple pictures - allows camera to adjust
  # showImage allows opportunity to display image within function
  
  # Turn on webcam
  stream = readStream(0)
  
  # Take pictures
  print("Video stream initiated.")
  for(i in seq(rollFrames)){
    img = nextFrame(stream)
  }
  
  # Turn off camera
  release(stream)
  
  # Display image if requested
  if(showImage == TRUE){
    imshow(img)
  }
  
  if(!is.na(saveImageToWD)){
    fileName = paste(getwd(),"/",saveImageToWD,sep='')
    print(paste("Saving Image To: ",fileName, sep=''))
    writeImg(fileName,img)
  }
  
  return(img)
  
}
```


The Python script:

  1. Loads the algorithms from xml files
  2. Loads the image from "originalWebcamShot.png"
  3. Converts the image to grayscale
  4. Runs the facial detection algorithm
  5. Runs the eye detection algorithm (within the face)
  6. Draws rectangles around the face and eyes (different colors)
  7. Saves the new image as "modifiedWebcamShot.png"



```python
import numpy as np
import cv2

def main():

  # I followed Harrison Kingsley's work for this
  # Much of the source code is found https://pythonprogramming.net/haar-cascade-face-eye-detection-python-opencv-tutorial/

	face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')
	eye_cascade = cv2.CascadeClassifier('haarcascade_eye.xml')

	img = cv2.imread('originalWebcamShot.png')

	gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
	faces = face_cascade.detectMultiScale(gray, 1.3, 5)

	for (x,y,w,h) in faces:
	    cv2.rectangle(img,(x,y),(x+w,y+h),(0,0,255),2)
	    roi_gray = gray[y:y+h, x:x+w]
	    roi_color = img[y:y+h, x:x+w]
	    
	    eyes = eye_cascade.detectMultiScale(roi_gray)
	    for (ex,ey,ew,eh) in eyes:
	        cv2.rectangle(roi_color,(ex,ey),(ex+ew,ey+eh),(0,255,0),2)

	cv2.imwrite('modifiedWebcamShot.png',img)

if __name__ == '__main__':
	main()
```

The Python code was entirely based off of Harrison Kingsley's work:  

  * @sentdex [Twitter](https://twitter.com/Sentdex) | [YouTube](https://www.youtube.com/sentdex)
  * Website: [PythonProgramming.net](https://pythonprogramming.net/haar-cascade-face-eye-detection-python-opencv-tutorial/)
