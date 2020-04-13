library(httr)
library(rvest)
library(readr)
library(stringr)

url = 'https://finance.naver.com/sise/sise_deposit.nhn'

biz_day = GET(url) %>%
  read_html(encoding = 'EUC-KR') %>%
  html_nodes(xpath =
               '//*[@id="type_1"]/div/ul[2]/li/span') %>%
  html_text() %>%
  str_match(('[0-9]+.[0-9]+.[0-9]+') ) %>%
  str_replace_all('\\.', '')

#산업별 현황

gen_otp_url =
  'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',
  url = 'MKD/03/0303/03030103/mkd03030103',
  tp_cd = 'ALL',
  date = biz_day,
  lang = 'ko',
  pagePath = '/contents/MKD/03/0303/03030103/MKD03030103.jsp')

otp = POST(gen_otp_url, query= gen_otp_data) %>%
  read_html() %>%
  html_text()

down_url = 'http://file.krx.co.kr/download.jspx'
down_sector = POST(down_url, query = list(code = otp),
                   add_headers(referer = gen_otp_url)) %>%
  read_html() %>%
  html_text() %>%
  read_csv()

#print(down_sector)

ifelse(dir.exists('data'), FALSE, dir.create('data'))
write.csv(down_sector, 'data/krx_sector.csv')

#개별종목

gen_otp_url =
  'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',
  url = "MKD/13/1302/13020401/mkd13020401",
  schdate = biz_day,
  market_gubun = 'ALL',
  gubun = '1',
  pagePath = "/contents/MKD/13/1302/13020401/MKD13020401.jsp")

otp = POST(gen_otp_url, query = gen_otp_data) %>%
  read_html() %>%
  html_text()

down_url = 'http://file.krx.co.kr/download.jspx'
down_ind = POST(down_url, query = list(code = otp),
                add_headers(referer = gen_otp_url)) %>%
  read_html() %>%
  html_text() %>%
  read_csv()

# print(down_ind)
write.csv(down_ind, 'data/krx_ind.csv')

down_sector = read.csv('data/krx_sector.csv', row.names = 1,
                       stringsAsFactors = FALSE)
down_ind = read.csv('data/krx_ind.csv', row.names = 1,
                    stringsAsFactors = FALSE)

intersect(names(down_sector), names(down_ind))
setdiff(down_sector[, '종목명'], down_ind[, '종목명'])

KOR_ticker = merge(down_sector, down_ind,
                   by = intersect(names(down_sector),
                                   names(down_ind)),
                   all = FALSE
                   )

KOR_ticker = KOR_ticker[order(-KOR_ticker['시가총액.원.']), ]
print(head(KOR_ticker))

KOR_ticker[grepl('스팩', KOR_ticker[, '종목명']), '종목명']
KOR_ticker[str_sub(KOR_ticker[, '종목코드'], -1, -1) !=0, '종목명']

KOR_ticker[!grepl('스팩', KOR_ticker[, '종목명']), ]
KOR_ticker[str_sub(KOR_ticker[, '종목코드'], -1, -1) ==0, ]

rownames(KOR_ticker) = NULL
write.csv(KOR_ticker, 'data/KOR_ticker.csv')
