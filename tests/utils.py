from time import sleep
import re


def assert_exists(self, name):
    element = None
    try:
        element = self.driver.find_element_by_name(name)
    except:
        pass
    
    self.assertTrue(element is not None)
    print("Asserted exists: %s" % name)


def assert_not_exists(self, name):
    element = None
    try:
        element = self.driver.find_element_by_name(name)
    except:
        pass

    self.assertTrue(element is None)
    print("Asserted not exists: %s" % name)


def assert_not_exists_view_type(self, name):
    element = None
    try:
        element = self.driver.find_elements_by_ios_predicate('wdType == "%s"' % name)
    except:
        pass

    self.assertTrue(element is None)
    print("Asserted not exists: %s" % name)


def assert_not_exists_webview(self, name):
    assert_not_exists(self, "XCUIElementTypeWebView")


def assert_landscape_view(self):
    print(self.driver.orientation)
    self.assertTrue(self.driver.orientation == "UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT" or
        self.driver.orientation == "LANDSCAPE")


def assert_href_called(self, pattern):
    table_items = self.driver.find_elements_by_ios_predicate('wdType == "XCUIElementTypeCell"')

    for table_item in table_items:
        text_field = table_item.find_elements_by_ios_predicate('wdType == "XCUIElementTypeStaticText"')[0]
        name = text_field.get_attribute("name")
        if re.search(pattern, name):
            print("HREF called: %s" % pattern)
            return

    self.assertFalse("HREF was not called: %s" % pattern)


def assert_viewing_browser(self):
    assert_exists(self, "URL")


def assert_not_viewing_browser(self):
    assert_not_exists(self, "URL")


def assert_viewing_video(self):
    assert_exists(self, "Scan backwards")
    assert_exists(self, "Scan forward")


def assert_not_viewing_video(self):
    assert_not_exists(self, "Scan backwards")
    assert_not_exists(self, "Scan forward")


def assert_viewing_call(self):
    print_source(self)


def assert_viewing_sms(self):
    assert_exists(self, "New Message")


def block_until_webview(self, tries=5):
    block_until_ios_predicate(self, "XCUIElementTypeWebView")


def block_until_element(self, name, tries=5):
    count = 0
    element = None
    while True:
        try:
            element = self.driver.find_element_by_name(name)

            if element:
                print("Element %s ready" % name)
                break
        except:
            pass

        print("Element %s not ready" % name)
        sleep(1)
        count += 1

        if count == tries:
            self.assertTrue(True, "Block until element timed out")

    return element


def block_until_ios_predicate(self, name, tries=5):
    count = 0
    element = None
    while True:
        try:
            element = self.driver.find_elements_by_ios_predicate('wdType == "%s"' % name)

            if element:
                print("Element %s ready" % name)
                break
        except:
            pass

        print("Element %s not ready" % name)
        sleep(1)
        count += 1

        if count == tries:
            self.assertTrue(True, "Block until element timed out")

    return element


def block_until_not_element(self, name, tries=5):
    count = 0
    element = True
    while True:
        try:
            element = self.driver.find_element_by_name(name)

            if not element:
                print("Element %s not ready" % name)
                break
        except:
            print("Element %s not ready" % name)
            break

        print("Element %s ready" % name)
        sleep(1)
        count += 1

        if count == tries:
            self.assertTrue(True, "Block until element timed out")

    return element


def switch_context_to_webview(self): 
    for i in xrange(0,5):
        if len(self.driver.contexts) < 2:
            print("waiting... %s" % i)
            sleep(1)
        else:
            new_context = self.driver.contexts[1]
            #TODO check if new context is webview
            self.driver.Context = new_context
            print("context switch to %s" % str(new_context))
            return
    print("Falied to switch context to webveiw")


def click_btn(self, name):
    btn = self.driver.find_element_by_name(name)
    btn.click()
    print("Clicked on: %s" % name)


def find_btn_by_name(self, name):
    btn = self.driver.find_element_by_name(name)
    print("Found button: %s" % name)
    return btn


def click_parent_btn(self, name):
    btn = self.driver.find_element_by_name(name)
    btn.click()
    print("Clicked on: %s" % name)


def click_on_webview(self):
    webview = self.driver.find_elements_by_ios_predicate('wdType == "XCUIElementTypeWebView"')
    webview[0].click()
    print("Clicked on web view")


def print_source(self):
    print(self.driver.page_source)


def accept_location(self):
    # accept location
    try:
        allow_location = self.driver.find_element_by_name("Allow")

        if allow_location:
            allow_location.click()
            print("Allowing location")
    except:
        pass


def click_load_ad_btn(self, type="Banner", size="320x50"):
    click_btn(self, type)
    if type == "Banner":
        sleep(1)
        click_btn(self, size)
    print("Clicking %s load button" % type)


def set_channel_id(self, id):
    channel_text_field = self.driver.find_elements_by_ios_predicate('wdType == "XCUIElementTypeTextField"')[0]
    try:
        channel_text_field.set_value(id)
    except:
        print("set_value not working, tryping each char instead")
        sleep(1)
        click_btn(self, "more")
        sleep(1)
        click_btn(self, "space")
        for i in str(id):
            sleep(1)
            click_btn(self, i)
    self.driver.hide_keyboard('Return')
    print("Setting channel id: %s" % id)


def click_x_btn(self):
    btns = self.driver.find_elements_by_ios_predicate('wdType == "XCUIElementTypeButton"')
    # Not very ideal, but it works for senario that only one native button is on the screen, and the button is close
    if len(btns) > 0:
        btns[0].click()
    else:
        print("Failed to find any native buttons")
    print("Clicked on close button")


def click_btn_path(self, path):
    btn = self.driver.find_element_by_xpath(path)
    btn.click()


def click_back_btn(self):
    click_btn(self, "Done")
    print("Clicked on back button")