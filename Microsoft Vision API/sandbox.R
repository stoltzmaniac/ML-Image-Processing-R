library(tidyverse)
library(RCurl)
library(httr)
library(EBImage)

credentials = read_csv('credentials.csv')
api_key = as.character(credentials$subscription_id) #api key is not subscription id
api_endpoint_url = "https://westcentralus.api.cognitive.microsoft.com/vision/v1.0/analyze"

image_url = 'https://imgur.com/rapIn0u.jpg'
visualFeatures = "Description,Tags,Categories,Faces"
# options = "Categories, Tags, Description, Faces, ImageType, Color, Adult"

details = "Landmarks"
# options = Landmarks, Celebrities

reqURL = paste(api_endpoint_url,
               "?visualFeatures=",
               visualFeatures,
               "&details=",
               details,
               sep="")

APIresponse = POST(url = reqURL,
                   content_type('application/json'),
                   add_headers(.headers = c('Ocp-Apim-Subscription-Key' = api_key)),
                   body=list(url = image_url),
                   encode = "json") 

df = content(APIresponse)
str(df)



description_tags = df$description$tags
description_tags_tib = tibble(tag = character())
for(tag in description_tags){
  for(text in tag){
    if(class(tag) != "list"){  ## To remove the extra caption from being included
      tmp = tibble(tag = tag)
      description_tags_tib = description_tags_tib %>% bind_rows(tmp)
    } 
  }
}

knitr::kable(description_tags_tib[1:5,])


captions = df$description$captions
captions_tib = tibble(text = character(), confidence = numeric())
for(caption in captions){
  tmp = tibble(text = caption$text, confidence = caption$confidence)
  captions_tib = captions_tib %>% bind_rows(tmp)
}
knitr::kable(captions_tib)


metadata = df$metadata
metadata_tib = tibble(width = metadata$width, height = metadata$height, format = metadata$format)
knitr::kable(metadata_tib)



faces = df$faces
faces_tib = tibble(faceID = numeric(),
                   age = numeric(), 
                   gender = character(),
                   x1 = numeric(),
                   x2 = numeric(),
                   y1 = numeric(),
                   y2 = numeric())

n = 0
for(face in faces){
  n = n + 1
  tmp = tibble(faceID = n,
               age = face$age, 
               gender = face$gender,
               x1 = face$faceRectangle$left,
               y1 = face$faceRectangle$top,
               x2 = face$faceRectangle$left + face$faceRectangle$width,
               y2 = face$faceRectangle$top + face$faceRectangle$height)
  faces_tib = faces_tib %>% bind_rows(tmp)
}
faces_tib
knitr::kable(faces_tib)



my_image <- readImage('SnoozeGenius.jpg')
plot(my_image)

coords = faces_tib %>% select(x1, y1, x2, y2)
for(i in 1:nrow(coords)){
  print(i)
  xs = c(coords$x1[i], coords$x1[i], coords$x2[i], coords$x2[i])
  ys = c(coords$y1[i], coords$y2[i], coords$y2[i], coords$y1[i])
  polygon(x = xs, y = ys, border = i+1, lwd = 4)
}



