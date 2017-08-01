---
title: "Google Vision API in R"
author: "Scott Stoltzman"
date: "7/29/2017"
output: html_document
---

## Using the Google Vision API in R  

### Utilizing RoogleVision  

After doing my post last month on OpenCV and face detection, I started looking into other algorithms used for pattern detection in images. As it turns out, Google has done a phenomenal job with their Vision API. It's absolutely incredible the amount of information it can spit back to you by simply sending it a picture.  

Also, it's 100% free! I believe that includes 1000 images per month. Amazing!  

In this post I'm going to walk you through the absolute basics of accessing the power of the Google Vision API using the RoogleVision package in R.

As always, we'll start off loading some libraries. I wrote some extra notation around where you can install them within the code.  


```r
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
```

#### Google Authentication  

In order to use the API, you have to authenticate. There is plenty of documentation out there about how to setup an account, create a project, download credentials, etc. Head over to [Google Cloud Console](https://console.cloud.google.com) if you don't have an account already.


```r
# Credentials file I downloaded from the cloud console
creds = fromJSON('credentials.json')

# Google Authentication - Use Your Credentials
# options("googleAuthR.client_id" = "xxx.apps.googleusercontent.com")
# options("googleAuthR.client_secret" = "")

options("googleAuthR.client_id" = creds$installed$client_id)
options("googleAuthR.client_secret" = creds$installed$client_secret)
options("googleAuthR.scopes.selected" = c("https://www.googleapis.com/auth/cloud-platform"))
googleAuthR::gar_auth()
```

```
## 2017-07-31 11:30:34> Token cache file: .httr-oauth
```

```
## 2017-07-31 11:30:34> Scopes: https://www.googleapis.com/auth/cloud-platform
```
  
  
### Now You're Ready to Go  

The function getGoogleVisionResponse takes three arguments:

  1. imagePath
  2. feature
  3. numResults

Numbers 1 and 3 are self-explanatory, "feature" has 5 options:  

  * LABEL_DETECTION
  * LANDMARK_DETECTION
  * FACE_DETECTION
  * LOGO_DETECTION
  * TEXT_DETECTION  

These are self-explanatory but it's nice to see each one in action. 

As a side note: there are also other features that the API has which aren't included (yet) in the RoogleVision package such as "Safe Search" which identifies inappropriate content, "Properties" which identifies dominant colors and aspect ratios and a few others can be found at the [Cloud Vision website](https://cloud.google.com/vision/)

----  

#### Label Detection  

This is used to help determine content within the photo. It can basically add a level of metadata around the image.  

Here is a photo of our dog when we hiked up to Audubon Peak in Colorado:  

![plot of chunk unnamed-chunk-2](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-2-1.png)




```r
dog_mountain_label = getGoogleVisionResponse('dog_mountain.jpg',
                                              feature = 'LABEL_DETECTION')
head(dog_mountain_label)
```

```
##            mid           description     score
## 1     /m/09d_r              mountain 0.9188690
## 2 /g/11jxkqbpp mountainous landforms 0.9009549
## 3    /m/023bbt            wilderness 0.8733696
## 4     /m/0kpmf             dog breed 0.8398435
## 5    /m/0d4djn            dog hiking 0.8352048
```
  
  
All 5 responses were incredibly accurate! The "score" that is returned is how confident the Google Vision algorithms are, so there's a 91.9% chance a mountain is prominent in this photo. I like "dog hiking" the best - considering that's what we were doing at the time. Kind of a little bit too accurate...  

----  

#### Landmark Detection   

This is a feature designed to specifically pick out a recognizable landmark! It provides the position in the image along with the geolocation of the landmark (in longitude and latitude).  

My wife and I took this selfie in at the Linderhof Castle in Bavaria, Germany. 


```r
us_castle <- readImage('us_castle_2.jpg')
plot(us_castle)
```

![plot of chunk unnamed-chunk-4](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-4-1.png)
  

The response from the Google Vision API was spot on. It returned "Linderhof Palace" as the description. It also provided a  score (I reduced the resolution of the image which hurt the score), a boundingPoly field and locations.  

  * Bounding Poly - gives x,y coordinates for a polygon around the landmark in the image
  * Locations - provides longitude,latitude coordinates  


```r
us_landmark = getGoogleVisionResponse('us_castle_2.jpg',
                                      feature = 'LANDMARK_DETECTION')
head(us_landmark)
```

```
##         mid      description     score
## 1 /m/066h19 Linderhof Palace 0.4665011
##                               vertices          locations
## 1 25, 382, 382, 25, 178, 178, 659, 659 47.57127, 10.96072
```
  
I plotted the polygon over the image using the coordinates returned. It does a great job (certainly not perfect) of getting the castle identified. It's a bit tough to say what the actual "landmark" would be in this case due to the fact the fountains, stairs and grounds are certainly important and are a key part of the castle.


```r
us_castle <- readImage('us_castle_2.jpg')
plot(us_castle)
xs = us_landmark$boundingPoly$vertices[[1]][1][[1]]
ys = us_landmark$boundingPoly$vertices[[1]][2][[1]]
polygon(x=xs,y=ys,border='red',lwd=4)
```

![plot of chunk unnamed-chunk-6](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-6-1.png)
  
  
Turning to the locations - I plotted this using the leaflet library. If you haven't used leaflet, start doing so immediately. I'm a huge fan of it due to speed and simplicity. There are a lot of customization options available as well that you can check out.  

The location = spot on! While it isn't a shock to me that Google could provide the location of "Linderhof Castle" - it is amazing to me that I don't have to write a web crawler search function to find it myself! That's just one of many little luxuries they have built into this API.


```r
latt = us_landmark$locations[[1]][[1]][[1]]
lon = us_landmark$locations[[1]][[1]][[2]]
m = leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  setView(lng = lon, lat = latt, zoom = 5) %>%
  addMarkers(lng = lon, lat = latt)
m
```

```
## Error in loadNamespace(name): there is no package called 'webshot'
```


----  

#### Face Detection  

My last blog post showed the OpenCV package utilizing the haar cascade algorithm in action. I didn't dig into Google's algorithms to figure out what is under the hood, but it provides similar results. However, rather than layering in each subsequent "find the eyes" and "find the mouth" and ...etc... it returns more than you ever needed to know.

  * Bounding Poly = highest level polygon
  * FD Bounding Poly = polygon surrounding each face
  * Landmarks = (funny name) includes each feature of the face (left eye, right eye, etc.)
  * Roll Angle, Pan Angle, Tilt Angle = all of the different angles you'd need per face
  * Confidence (detection and landmarking) = how certain the algorithm is that it's accurate
  * Joy, sorrow, anger, surprise, under exposed, blurred, headwear likelihoods = how likely it is that each face contains that emotion or characteristic

The likelihoods is another amazing piece of information returned! I have run about 20 images through this API and every single one has been accurate - very impressive!

I wanted to showcase the face detection and headwear first. Here's a picture of my wife and I at "The Bean" in Chicago (side note: it's awesome! I thought it was going to be really silly, but you can really have a lot of fun with all of the angles and reflections):


```r
us_hats_pic <- readImage('us_hats.jpg')
plot(us_hats_pic)
```

![plot of chunk unnamed-chunk-8](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-8-1.png)



```r
us_hats = getGoogleVisionResponse('us_hats.jpg',
                                      feature = 'FACE_DETECTION')
head(us_hats)
```

```
##                                 vertices
## 1 295, 410, 410, 295, 164, 164, 297, 297
## 2 353, 455, 455, 353, 261, 261, 381, 381
##                                 vertices
## 1 327, 402, 402, 327, 206, 206, 280, 280
## 2 368, 439, 439, 368, 298, 298, 370, 370
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           landmarks
## 1 LEFT_EYE, RIGHT_EYE, LEFT_OF_LEFT_EYEBROW, RIGHT_OF_LEFT_EYEBROW, LEFT_OF_RIGHT_EYEBROW, RIGHT_OF_RIGHT_EYEBROW, MIDPOINT_BETWEEN_EYES, NOSE_TIP, UPPER_LIP, LOWER_LIP, MOUTH_LEFT, MOUTH_RIGHT, MOUTH_CENTER, NOSE_BOTTOM_RIGHT, NOSE_BOTTOM_LEFT, NOSE_BOTTOM_CENTER, LEFT_EYE_TOP_BOUNDARY, LEFT_EYE_RIGHT_CORNER, LEFT_EYE_BOTTOM_BOUNDARY, LEFT_EYE_LEFT_CORNER, LEFT_EYE_PUPIL, RIGHT_EYE_TOP_BOUNDARY, RIGHT_EYE_RIGHT_CORNER, RIGHT_EYE_BOTTOM_BOUNDARY, RIGHT_EYE_LEFT_CORNER, RIGHT_EYE_PUPIL, LEFT_EYEBROW_UPPER_MIDPOINT, RIGHT_EYEBROW_UPPER_MIDPOINT, LEFT_EAR_TRAGION, RIGHT_EAR_TRAGION, FOREHEAD_GLABELLA, CHIN_GNATHION, CHIN_LEFT_GONION, CHIN_RIGHT_GONION, 352.00974, 380.68124, 340.27664, 363.16348, 378.64938, 393.6553, 370.78906, 371.99802, 366.30664, 364.23642, 349.47012, 377.17905, 364.7603, 375.62842, 357.7237, 367.20822, 352.4306, 358.9425, 351.23474, 343.64124, 351.10004, 384.32953, 388.21667, 382.08743, 375.90262, 383.87732, 353.08627, 387.7416, 312.06622, 384.56946, 371.5381, 360.62714, 318.48486, 383.87354, 225.86505, 229.50423, 216.51169, 219.28635, 220.92139, 222.02762, 227.35771, 248.94884, 259.51044, 272.9798, 261.36096, 263.89874, 265.76828, 251.38408, 248.46135, 253.8837, 223.93387, 227.20102, 228.33765, 225.31805, 226.13412, 227.22661, 229.89023, 231.8548, 229.34843, 229.54358, 213.85588, 217.43123, 236.95158, 244.45172, 219.76247, 287.00592, 260.99124, 267.68896, -0.0009269835, 12.904515, -2.3585303, -3.3569832, 3.4166863, 20.891703, -0.10083569, -8.568332, -0.32282636, 2.7426949, 3.1502135, 14.79839, 2.401884, 8.115268, 0.19641992, -0.7506992, -2.5084567, 2.8466656, -0.38294473, -0.05908208, -1.2792722, 11.411656, 19.373985, 13.421982, 10.900102, 12.992137, -5.2635217, 9.859322, 31.33588, 62.9466, -1.213793, 7.9232774, 20.887934, 49.40408
## 2 LEFT_EYE, RIGHT_EYE, LEFT_OF_LEFT_EYEBROW, RIGHT_OF_LEFT_EYEBROW, LEFT_OF_RIGHT_EYEBROW, RIGHT_OF_RIGHT_EYEBROW, MIDPOINT_BETWEEN_EYES, NOSE_TIP, UPPER_LIP, LOWER_LIP, MOUTH_LEFT, MOUTH_RIGHT, MOUTH_CENTER, NOSE_BOTTOM_RIGHT, NOSE_BOTTOM_LEFT, NOSE_BOTTOM_CENTER, LEFT_EYE_TOP_BOUNDARY, LEFT_EYE_RIGHT_CORNER, LEFT_EYE_BOTTOM_BOUNDARY, LEFT_EYE_LEFT_CORNER, LEFT_EYE_PUPIL, RIGHT_EYE_TOP_BOUNDARY, RIGHT_EYE_RIGHT_CORNER, RIGHT_EYE_BOTTOM_BOUNDARY, RIGHT_EYE_LEFT_CORNER, RIGHT_EYE_PUPIL, LEFT_EYEBROW_UPPER_MIDPOINT, RIGHT_EYEBROW_UPPER_MIDPOINT, LEFT_EAR_TRAGION, RIGHT_EAR_TRAGION, FOREHEAD_GLABELLA, CHIN_GNATHION, CHIN_LEFT_GONION, CHIN_RIGHT_GONION, 389.67215, 419.01474, 378.68497, 397.29074, 411.57373, 430.68024, 404.34882, 402.9257, 402.77734, 402.28552, 388.3598, 418.2969, 402.50266, 411.8417, 394.88547, 403.11188, 388.78043, 395.5202, 389.06342, 382.62268, 388.21332, 419.86707, 425.98645, 419.21088, 413.45447, 420.1578, 387.80508, 421.56183, 369.29388, 439.9703, 404.44498, 401.90457, 371.50647, 435.39258, 319.11594, 320.14157, 310.8753, 313.32437, 313.59402, 313.3107, 318.78964, 337.8581, 347.607, 360.56134, 350.5411, 351.10315, 354.41702, 339.4301, 339.11786, 342.46072, 317.141, 320.19537, 321.22644, 318.473, 319.0922, 318.58655, 320.64886, 322.44992, 320.4701, 320.58286, 308.29236, 309.85825, 328.25885, 331.54816, 312.85385, 372.5355, 349.82388, 352.82462, 0.00018637085, -0.63476753, 2.1497552, -7.1008844, -7.460493, 1.0756116, -7.027477, -13.670173, -5.1229305, -1.0671108, 4.793461, 4.4603314, -1.8998832, -1.677745, -1.2933732, -5.9320116, -2.3477247, 0.03832738, 0.0054741018, 2.9924247, -0.7714207, -2.9816942, 2.079318, -0.6419869, -0.3527427, -1.4552351, -5.0709085, -5.7559977, 40.608036, 39.10855, -8.547456, 4.8426514, 30.500828, 29.191824
##   rollAngle panAngle tiltAngle detectionConfidence landmarkingConfidence
## 1  7.103324 23.46835 -2.816312           0.9877176             0.7072066
## 2  2.510939 -1.17956 -7.393063           0.9997375             0.7268016
##   joyLikelihood sorrowLikelihood angerLikelihood surpriseLikelihood
## 1   VERY_LIKELY    VERY_UNLIKELY   VERY_UNLIKELY      VERY_UNLIKELY
## 2   VERY_LIKELY    VERY_UNLIKELY   VERY_UNLIKELY      VERY_UNLIKELY
##   underExposedLikelihood blurredLikelihood headwearLikelihood
## 1          VERY_UNLIKELY     VERY_UNLIKELY        VERY_LIKELY
## 2          VERY_UNLIKELY     VERY_UNLIKELY        VERY_LIKELY
```



```r
us_hats_pic <- readImage('us_hats.jpg')
plot(us_hats_pic)

xs1 = us_hats$fdBoundingPoly$vertices[[1]][1][[1]]
ys1 = us_hats$fdBoundingPoly$vertices[[1]][2][[1]]

xs2 = us_hats$fdBoundingPoly$vertices[[2]][1][[1]]
ys2 = us_hats$fdBoundingPoly$vertices[[2]][2][[1]]

polygon(x=xs1,y=ys1,border='red',lwd=4)
polygon(x=xs2,y=ys2,border='green',lwd=4)
```

![plot of chunk unnamed-chunk-10](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-10-1.png)


Here's a shot that should be familiar (copied directly from my last blog) - and I wanted to highlight the different features that can be detected. Look at how many points are perfectly placed:


```r
my_face_pic <- readImage('my_face.jpg')
plot(my_face_pic)
```

![plot of chunk unnamed-chunk-11](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-11-1.png)




```r
my_face = getGoogleVisionResponse('my_face.jpg',
                                      feature = 'FACE_DETECTION')
head(my_face)
```

```
##                               vertices
## 1 456, 877, 877, 456, NA, NA, 473, 473
##                               vertices
## 1 515, 813, 813, 515, 98, 98, 395, 395
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             landmarks
## 1 LEFT_EYE, RIGHT_EYE, LEFT_OF_LEFT_EYEBROW, RIGHT_OF_LEFT_EYEBROW, LEFT_OF_RIGHT_EYEBROW, RIGHT_OF_RIGHT_EYEBROW, MIDPOINT_BETWEEN_EYES, NOSE_TIP, UPPER_LIP, LOWER_LIP, MOUTH_LEFT, MOUTH_RIGHT, MOUTH_CENTER, NOSE_BOTTOM_RIGHT, NOSE_BOTTOM_LEFT, NOSE_BOTTOM_CENTER, LEFT_EYE_TOP_BOUNDARY, LEFT_EYE_RIGHT_CORNER, LEFT_EYE_BOTTOM_BOUNDARY, LEFT_EYE_LEFT_CORNER, LEFT_EYE_PUPIL, RIGHT_EYE_TOP_BOUNDARY, RIGHT_EYE_RIGHT_CORNER, RIGHT_EYE_BOTTOM_BOUNDARY, RIGHT_EYE_LEFT_CORNER, RIGHT_EYE_PUPIL, LEFT_EYEBROW_UPPER_MIDPOINT, RIGHT_EYEBROW_UPPER_MIDPOINT, LEFT_EAR_TRAGION, RIGHT_EAR_TRAGION, FOREHEAD_GLABELLA, CHIN_GNATHION, CHIN_LEFT_GONION, CHIN_RIGHT_GONION, 598.7636, 723.16125, 556.1954, 628.8224, 693.0257, 767.7514, 661.2344, 661.9072, 662.7698, 662.2978, 603.21814, 722.5995, 662.66486, 700.5242, 626.14417, 663.0441, 597.7986, 624.5084, 597.13776, 572.32404, 596.0174, 725.61145, 751.531, 725.60315, 701.6699, 727.3262, 591.74457, 730.4487, 525.0554, 814.0723, 660.71075, 664.25146, 536.8293, 798.8593, 192.19489, 192.49554, 165.28363, 159.90292, 160.66797, 164.28062, 185.05746, 260.90063, 310.77585, 348.6693, 322.57773, 317.35153, 325.9983, 274.28345, 275.32834, 284.49515, 185.37177, 194.59952, 203.61258, 197.56845, 194.79561, 183.56104, 195.62381, 203.60477, 194.94687, 193.0094, 147.70262, 145.74747, 276.10037, 270.00323, 158.95798, 409.86185, 350.27, 346.58624, -0.0018592946, -4.8054757, 15.825399, -23.345352, -25.614508, 7.637372, -29.068363, -74.15371, -48.44018, -43.53211, -10.572805, -14.504428, -40.966953, -26.340576, -23.933197, -46.457916, -8.027897, -0.8318569, -2.181139, 12.514983, -3.5412567, -12.764345, 5.530805, -7.038474, -3.6184528, -8.517615, -10.674338, -15.85011, 152.71716, 142.93324, -29.311995, -31.410963, 93.14353, 83.41843
##    rollAngle  panAngle tiltAngle detectionConfidence landmarkingConfidence
## 1 -0.6375801 -2.120439  5.706552            0.996818             0.8222974
##   joyLikelihood sorrowLikelihood angerLikelihood surpriseLikelihood
## 1   VERY_LIKELY    VERY_UNLIKELY   VERY_UNLIKELY      VERY_UNLIKELY
##   underExposedLikelihood blurredLikelihood headwearLikelihood
## 1          VERY_UNLIKELY     VERY_UNLIKELY      VERY_UNLIKELY
```




```r
head(my_face$landmarks)
```

```
## [[1]]
##                            type position.x position.y    position.z
## 1                      LEFT_EYE   598.7636   192.1949  -0.001859295
## 2                     RIGHT_EYE   723.1612   192.4955  -4.805475700
## 3          LEFT_OF_LEFT_EYEBROW   556.1954   165.2836  15.825399000
## 4         RIGHT_OF_LEFT_EYEBROW   628.8224   159.9029 -23.345352000
## 5         LEFT_OF_RIGHT_EYEBROW   693.0257   160.6680 -25.614508000
## 6        RIGHT_OF_RIGHT_EYEBROW   767.7514   164.2806   7.637372000
## 7         MIDPOINT_BETWEEN_EYES   661.2344   185.0575 -29.068363000
## 8                      NOSE_TIP   661.9072   260.9006 -74.153710000
## 9                     UPPER_LIP   662.7698   310.7758 -48.440180000
## 10                    LOWER_LIP   662.2978   348.6693 -43.532110000
## 11                   MOUTH_LEFT   603.2181   322.5777 -10.572805000
## 12                  MOUTH_RIGHT   722.5995   317.3515 -14.504428000
## 13                 MOUTH_CENTER   662.6649   325.9983 -40.966953000
## 14            NOSE_BOTTOM_RIGHT   700.5242   274.2835 -26.340576000
## 15             NOSE_BOTTOM_LEFT   626.1442   275.3283 -23.933197000
## 16           NOSE_BOTTOM_CENTER   663.0441   284.4952 -46.457916000
## 17        LEFT_EYE_TOP_BOUNDARY   597.7986   185.3718  -8.027897000
## 18        LEFT_EYE_RIGHT_CORNER   624.5084   194.5995  -0.831856900
## 19     LEFT_EYE_BOTTOM_BOUNDARY   597.1378   203.6126  -2.181139000
## 20         LEFT_EYE_LEFT_CORNER   572.3240   197.5685  12.514983000
## 21               LEFT_EYE_PUPIL   596.0174   194.7956  -3.541256700
## 22       RIGHT_EYE_TOP_BOUNDARY   725.6114   183.5610 -12.764345000
## 23       RIGHT_EYE_RIGHT_CORNER   751.5310   195.6238   5.530805000
## 24    RIGHT_EYE_BOTTOM_BOUNDARY   725.6032   203.6048  -7.038474000
## 25        RIGHT_EYE_LEFT_CORNER   701.6699   194.9469  -3.618452800
## 26              RIGHT_EYE_PUPIL   727.3262   193.0094  -8.517615000
## 27  LEFT_EYEBROW_UPPER_MIDPOINT   591.7446   147.7026 -10.674338000
## 28 RIGHT_EYEBROW_UPPER_MIDPOINT   730.4487   145.7475 -15.850110000
## 29             LEFT_EAR_TRAGION   525.0554   276.1004 152.717160000
## 30            RIGHT_EAR_TRAGION   814.0723   270.0032 142.933240000
## 31            FOREHEAD_GLABELLA   660.7107   158.9580 -29.311995000
## 32                CHIN_GNATHION   664.2515   409.8619 -31.410963000
## 33             CHIN_LEFT_GONION   536.8293   350.2700  93.143530000
## 34            CHIN_RIGHT_GONION   798.8593   346.5862  83.418430000
```




```r
my_face_pic <- readImage('my_face.jpg')
plot(my_face_pic)

xs1 = my_face$fdBoundingPoly$vertices[[1]][1][[1]]
ys1 = my_face$fdBoundingPoly$vertices[[1]][2][[1]]

xs2 = my_face$landmarks[[1]][[2]][[1]]
ys2 = my_face$landmarks[[1]][[2]][[2]]

polygon(x=xs1,y=ys1,border='red',lwd=4)
points(x=xs2,y=ys2,lwd=2, col='lightblue')
```

![plot of chunk unnamed-chunk-14](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-14-1.png)

----

#### Logo Detection
  
To continue along the Chicago trip, we drove by Wrigley field and I took a really bad photo of the sign from a moving car as it was under construction. It's nice because it has a lot of different lines and writing the Toyota logo isn't incredibly prominent or necessarily fit to brand colors.

This call returns:  

  * Description = Brand name of the logo detected
  * Score = Confidence of prediction accuracy
  * Bounding Poly = (Again) coordinates of the logo

  

```r
wrigley_image <- readImage('wrigley_text.jpg')
plot(wrigley_image)
```

![plot of chunk unnamed-chunk-15](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-15-1.png)




```r
wrigley_logo = getGoogleVisionResponse('wrigley_text.jpg',
                                   feature = 'LOGO_DETECTION')
head(wrigley_logo)
```

```
##           mid description     score                               vertices
## 1 /g/1tk6469q      Toyota 0.3126611 435, 551, 551, 435, 449, 449, 476, 476
```



```r
wrigley_image <- readImage('wrigley_text.jpg')
plot(wrigley_image)
xs = wrigley_logo$boundingPoly$vertices[[1]][[1]]
ys = wrigley_logo$boundingPoly$vertices[[1]][[2]]
polygon(x=xs,y=ys,border='green',lwd=4)
```

![plot of chunk unnamed-chunk-17](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-17-1.png)

----

#### Text Detection

I'll continue using the Wrigley Field picture. There is text all over the place and it's fun to see what is captured and what isn't. It appears as if the curved text at the top "field" isn't easily interpreted as text. However, the rest is caught and the words are captured.  

The response sent back is a bit more difficult to interpret than the rest of the API calls - it breaks things apart by word but also returns everything as one line. Here's what comes back:  

  * Locale = language, returned as source
  * Description = the text (the first line is everything, and then the rest are indiviudal words)
  * Bounding Poly = I'm sure you can guess by now


```r
wrigley_text = getGoogleVisionResponse('wrigley_text.jpg',
                                   feature = 'TEXT_DETECTION')
head(wrigley_text)
```

```
##   locale
## 1     en
## 2   <NA>
## 3   <NA>
## 4   <NA>
## 5   <NA>
## 6   <NA>
##                                                                                                        description
## 1 RIGLEY F\nICHICAGO CUBS\nORDER ONLINE AT GIORDANOS.COM\nTOYOTA\nMIDWEST\nFENCE\n773-722-6616\nCAUTION\nCAUTION\n
## 2                                                                                                           RIGLEY
## 3                                                                                                                F
## 4                                                                                                         ICHICAGO
## 5                                                                                                             CUBS
## 6                                                                                                            ORDER
##                                 vertices
## 1   55, 657, 657, 55, 210, 210, 852, 852
## 2 343, 482, 484, 345, 217, 211, 260, 266
## 3 501, 524, 526, 503, 211, 210, 259, 260
## 4 222, 503, 501, 220, 295, 307, 348, 336
## 5 527, 627, 625, 525, 308, 312, 353, 349
## 6 310, 384, 384, 310, 374, 374, 391, 391
```


```r
wrigley_image <- readImage('wrigley_text.jpg')
plot(wrigley_image)

for(i in 1:length(wrigley_text$boundingPoly$vertices)){
  xs = wrigley_text$boundingPoly$vertices[[i]]$x
  ys = wrigley_text$boundingPoly$vertices[[i]]$y
  polygon(x=xs,y=ys,border='green',lwd=2)
}
```

![plot of chunk unnamed-chunk-19](https://www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-19-1.png)

----

That's about it for the basics of using the Google Vision API with the RoogleVision library. I highly recommend tinkering around with it a bit, especially because it won't cost you a dime.  

While I do enjoy the math under the hood and the thinking required to understand alrgorithms, I do think these sorts of API's will become the way of the future for data science. Outside of specific use cases or special industries, it seems hard to imagine wanting to try and create algorithms that would be better than ones created for mass consumption. As long as they're fast, free and accurate, I'm all about making my life easier! From the hiring perspective, I much prefer someone who can get the job done over someone who can slightly improve performance (as always, there are many cases where this doesn't apply).

Please comment if you are utilizing any of the Google API's for business purposes, I would love to hear it!

As always you can find this on my [GitHub](https://github.com/stoltzmaniac/ML-Image-Processing-R)




