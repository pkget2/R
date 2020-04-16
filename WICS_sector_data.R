library(httr)
library(rvest)
library(readr)
library(stringr)
library(jsonlite)

url = 'https://finance.naver.com/sise/sise_deposit.nhn'

biz_day = GET(url) %>%
  read_html(encoding = 'EUC-KR') %>%
               '//*[@id="type_1"]/div/ul[2]/li/span') %>%
  html_text() %>%
  str_match(('[0-9]+.[0-9]+.[0-9]+') ) %>%
  str_replace_all('\\.', '')

url = 'http://www.wiseindex.com/Index/GetIndexComponets?ceil_yn=0&dt=20200414&sec_cd=G10'
data = fromJSON(url)

lapply(data, head)

sector_code = c('G25', 'G35', 'G50', 'G40 ', 'G10',
                'G20', 'G55', 'G30', 'G15', 'G45')
data_sector = list()

for (i in sector_code) {
  url = paste0(
    'http://www.wiseindex.com/Index/GetIndexComponets', 
    '?ceil_yn=0&dt=',biz_day,'&sec_cd=', i)
  data = fromJSON(url)
  data = data$list
  data_sector[[i]] = data
  
  Sys.sleep(1)
}

data_sector = do.call(rbind, data_sector)
write.csv(data_sector, 'data/KOR_sector.csv')
