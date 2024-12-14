
import os
import time
import json
import shutil
from PIL import Image
from pathlib import Path
from urllib.parse import urlparse

from selenium.webdriver import Firefox
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

start_time = time.perf_counter()
#
options=Options()
options.profile = '///'
options.set_preference('network.proxy.type', 1)
options.set_preference('network.proxy.socks', '0')
options.set_preference('network.proxy.socks_port', 0)
options.set_preference('network.proxy.socks_remote_dns', True)
options.set_preference('browser.altClickSave', True)
options.set_preference("browser.download.folderList", 2)  # Use custom folder
options.set_preference("browser.download.dir", '///')
options.set_preference("browser.helperApps.neverAsk.saveToDisk", "image/jpeg,image/png,image/webp,image/gif")  # Add MIME types
options.set_preference("pdfjs.disabled", True)  # Disable PDF viewer
driver = Firefox(options=options)
driver.set_window_position(0, 0, windowHandle ='current')
driver.implicitly_wait(10)
#
driver.get("https://ipinfo.io/")
if os.path.exists("cookies.json"):
    cookies = json.load(open("cookies.json", "r"))
    for cookie in cookies:
        driver.add_cookie(cookie)
driver.get("https://ipinfo.io/")
json.dump(driver.get_cookies(), open("cookies.json", "w"))
driver.get("https://ipinfo.io/")
#
driver.get("about:config")
driver.execute_script(
     'var prefs = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);'
     'prefs.setCharPref("network.proxy.socks", "0");'
     'prefs.setIntPref("network.proxy.socks_port", "0");'
)
time.sleep(1)
#
driver.get("https://ipinfo.io")
#
folder = driver.find_element("tag name","h1").text
folder = Path("../1/" + folder.replace("|","_"))
folder.mkdir(parents=True, exist_ok=True)
wait = WebDriverWait(driver, 10)
root = Path('///')
while True:
    #
    t = driver.find_elements("xpath","//span")
    index = t[0].text
    last = t[1].text
    #
    image_low = driver.find_element("id","img")
    wait.until( lambda d: d.execute_script(
        "var img = arguments[0]; return img.complete && img.naturalWidth > 0;", image_low
    ) )
    #
    image = driver.find_elements("xpath", '//a[contains(text(), "Download original")]')
    if image:
        image = image[0]
        url = image.get_attribute('href')
        driver.execute_script("arguments[0].scrollIntoView(true);", image)
    else:
        url = image_low.get_attribute('src')
        image = driver.execute_script(
            'var i=document.getElementById("my_href");if (i) {i.remove()}'
            f'var a=document.createElement("a");a.setAttribute("href","{url}");a.innerHTML = "my";'
            'a.setAttribute("id","my_href");document.getElementsByTagName("body")[0].appendChild(a);return a'
        )
    #        
    image.send_keys(Keys.ALT,Keys.ENTER)
    #
    name = os.path.basename(urlparse(url).path)
    img_path = root.joinpath(name)
    img_path_new = root.joinpath(index+"_"+last+"_"+name)
    done = False
    while not done:
        try:
            img_path.rename(img_path_new)
            done = True
        except (FileNotFoundError, PermissionError):
            time.sleep(1)
        except Exception as e:
            print(repr(e))
            time.sleep(1)
    try:
        width, height = Image.open(img_path_new).size
    except:
        with open(img_path_new, 'r', encoding="utf-8") as f:
            raise Exception(f.read())
    f_size = f"{os.stat(img_path_new).st_size/1024/1024:.2f}MB"
    min, sec = divmod(int(time.perf_counter()-start_time), 60)
    print(f"{min:02}:{sec:02}",index,last,url,f"{width}x{height}={width*height/1024/1024:.2f}M",f_size)
    #
    if index == last:
        break
    #
    image_low.click()
    wait.until(EC.staleness_of(image_low))
    wait.until(EC.staleness_of(t[0]))
    #
    time.sleep(2)

#
driver.quit()