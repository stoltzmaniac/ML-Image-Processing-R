library(tidyverse)
library(RCurl)
library(httr)

credentials = read.csv('credentials.csv')
api_key = as.character(credentials$subscription_id) #api key is not subscription id
#imageURL <- "https://i1.wp.com/www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-2-1.png?zoom=2&w=620&ssl=1"
imageURL = 'https://i1.wp.com/www.stoltzmaniac.com/wp-content/uploads/2017/07/unnamed-chunk-4-1.png?zoom=2&w=620&ssl=1'
endpointURL = "https://westcentralus.api.cognitive.microsoft.com/vision/v1.0/analyze"


visualFeatures = "Description,Tags,Categories"
# options = Categories, Tags, Description, Faces, ImageType, Color, Adult

details = "Landmarks"
# options = Landmarks, Celebrities

reqURL = paste(endpointURL,
               "?visualFeatures=",
               visualFeatures,
               "&details=",
               details,
               sep="")

APIresponse = POST(url = reqURL,
                   content_type('application/json'),
                   add_headers(.headers = c('Ocp-Apim-Subscription-Key' = api_key)),
                   body=list(url = imageURL),
                   encode = "json") 

df = content(APIresponse)
df
