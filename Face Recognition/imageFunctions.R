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