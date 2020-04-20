library(stringr)
library(lubridate)
library(timetk)
library(httr)
library(rvest)
library(xts)
library(readr)

KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)
print(KOR_ticker$'종목코드'[2])

KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

ifelse(dir.exists('data/KOR_price'), FALSE, 
       dir.create('data/KOR_price'))

for(i in 1 : nrow(KOR_ticker) ) {
  
  price = xts(NA, order.by = Sys.Date()) 
  name = KOR_ticker$'종목코드'[i] 
  
  tryCatch({
    url = paste0(
      'https://fchart.stock.naver.com/sise.nhn?symbol='
      ,name,'&timeframe=day&count=500&requestType=0')
    
    data = GET(url)
    data_html = read_html(data, encoding = 'EUC-KR') %>%
      html_nodes("item") %>%
      html_attr("data") 
    
    price = read_delim(data_html, delim = '|')
    
    price = price[c(1, 5)] 
    price = data.frame(price)
    colnames(price) = c('Date', 'Price')
    price[, 1] = ymd(price[, 1])
    
    rownames(price) = price[, 1]
    price[, 1] = NULL
    
  }, error = function(e) {
    
    warning(paste0("Error in Ticker: ", name))
  })
  
  write.csv(price, paste0('data/KOR_price/', name,
                          '_price.csv'))
  
  Sys.sleep(2)
}
