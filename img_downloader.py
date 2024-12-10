
import os
import time
import json
import shutil
import pathlib
from urllib.parse import urlparse

from seleniumrequests import Firefox
from selenium.webdriver import ActionChains
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.options import Options

#
pathlib.Path("../1/tmp00").mkdir(parents=True, exist_ok=True)

#
options=Options()
options.set_preference('network.proxy.type', 1)
options.set_preference('network.proxy.socks', '')
options.set_preference('network.proxy.socks_port', 0)
options.set_preference('network.proxy.socks_remote_dns', True)
driver = Firefox(options=options)
driver.get("https://ipinfo.io/")
if os.path.exists("cookies.json"):
    cookies = json.load(open("cookies.json", "r"))
    for cookie in cookies:
        driver.add_cookie(cookie)
#
driver.get("https://ipinfo.io/")
json.dump(driver.get_cookies(), open("cookies.json", "w"))
#
driver.get("https://ipinfo.io/")
driver.get("https://ipinfo.io/")

last_url = ""
i = 1000
while i > 0:
    i = i - 1
    #
    t = driver.find_elements("xpath","//span")
    index = t[0].text
    last = t[1].text
    #
    required_image = driver.find_elements("xpath", '//a[contains(text(), "Download original")]')
    if required_image:
        required_image = required_image[0]
        url = required_image.get_attribute('href')
    else:
        required_image = driver.find_element("id","img")
        url = required_image.get_attribute('src')
    #
    if url == last_url:
        time.sleep(0.2)
        continue
    else:
        last_url = url
    #
    driver.execute_script("arguments[0].scrollIntoView(true);", required_image)
    response = driver.request("GET", url, stream=True)
    response.raise_for_status()
    if "text" in response.headers['Content-Type']:
        raise Exception("response type error: " + response.text)
    with open("../1/tmp00/" + index + "_" + last + "_" + os.path.basename(urlparse(url).path), 'wb') as f:
        response.raw.decode_content = True
        shutil.copyfileobj(response.raw, f) 
    #
    print(index,last,url)
    if index == last:
        break
    #
    driver.find_element("id","img").click()
    #
    time.sleep(1)

#
driver.quit()