from test_base import DisplaySDKTest
from utils import *

SLEEP_INTERVAL = 2


class SpecificTest(DisplaySDKTest):
    def test_banner(self):
        set_channel_id(self, "22394")

        click_load_ad_btn(self, "Banner")

        accept_location(self)

        webview = block_until_webview(self)

        sleep(SLEEP_INTERVAL)

        # get web view
        webview = self.driver.find_elements_by_ios_predicate('wdType == "XCUIElementTypeWebView"')

        # if web view then click
        if len(webview) > 0:
            click_on_webview(self)

            sleep(5)

            # nagivate back
            try:
                click_back_btn(self)
            except:
                pass

        # Assert bid agent is called when clicked
        assert_href_called(self, r"/landingpage")

        # Assert impression pixel is called
        assert_href_called(self, r"notify.bidagent.xad.com")

    def test_interstitial(self):
        set_channel_id(self, "15999")

        click_load_ad_btn(self, "Interstitial")

        accept_location(self)

        block_until_webview(self)

        sleep(SLEEP_INTERVAL)

        # get web view
        webview = self.driver.find_elements_by_ios_predicate('wdType == "XCUIElementTypeWebView"')

        # if web view then click
        if len(webview) > 0:
            click_on_webview(self)

            sleep(5)

            # nagivate back
            try:
                click_back_btn(self)
            except:
                pass

        # find close button
        close_btn = self.driver.find_elements_by_ios_predicate('wdType == "XCUIElementTypeButton"')[0]

        close_btn.click()

        block_until_element(self, "Banner")

        # Assert impression pixel is called
        assert_href_called(self, r"eastads.simpli.fi")

        assert_href_called(self, r"notify.bidagent.xad.com")

    def test_vast_inline_linear(self):
        set_channel_id(self, "24373")
        
        click_load_ad_btn(self, "Video")

        accept_location(self)

        block_until_not_element(self, "Video")

        block_until_ios_predicate(self, "XCUIElementTypeButton")

        # Click middle video
        positions = []
        positions.append((5, 5))
        self.driver.tap(positions)

        block_until_element(self, "Done")

        assert_viewing_browser(self)

        click_btn(self, "Done")

        btn = block_until_ios_predicate(self, "XCUIElementTypeButton")

        sleep(40)

        btn[0].click()

        block_until_element(self, "Banner")

        assert_href_called(self, r"/click$")

        assert_href_called(self, r"/impression$")

        assert_href_called(self, r"/creativeView$")

        assert_href_called(self, r"/start$")

        assert_href_called(self, r"/firstQuartile$")

        assert_href_called(self, r"/midpoint$")

        assert_href_called(self, r"/thirdQuartile$")

        assert_href_called(self, r"/complete$")

    def test_vast_inline_linear_error(self):
        set_channel_id(self, "24403")
        
        click_load_ad_btn(self, "Video")

        accept_location(self)

        block_until_element(self, "Dismiss")

        # Accept error
        click_btn(self, "Dismiss")

        # Assert error url called
        assert_href_called(self, r"/error")

    def test_vast_inline_linear_wrong_mimetype(self):
        set_channel_id(self, "24408")
        
        click_load_ad_btn(self, "Video")

        accept_location(self)

        block_until_element(self, "Dismiss")

        # Accept error
        click_btn(self, "Dismiss")

        # Assert error url called
        assert_href_called(self, r"/error")

    def test_vast_urlencode_error(self):
        set_channel_id(self, "28228")
        
        click_load_ad_btn(self, "Video")

        accept_location(self)

        block_until_element(self, "Dismiss")

        # Accept error
        click_btn(self, "Dismiss")

    def test_vast_wrapper_linear_1_error(self):
        set_channel_id(self, "33838")
        
        click_load_ad_btn(self, "Video")

        accept_location(self)

        block_until_element(self, "Dismiss")

        # Accept error
        click_btn(self, "Dismiss")

        # Assert error url called
        assert_href_called(self, r"/wrapper/error$")

        assert_href_called(self, r"/error$")

    def test_vast_wrapper_linear_1(self):
        set_channel_id(self, "24383")
        
        click_load_ad_btn(self, "Video")

        accept_location(self)

        block_until_not_element(self, "Video")

        block_until_ios_predicate(self, "XCUIElementTypeButton")

        # Click middle video
        positions = []
        positions.append((5, 5))
        self.driver.tap(positions)

        block_until_element(self, "Done")

        assert_viewing_browser(self)

        click_btn(self, "Done")

        # Poll until video is done
        sleep(45)

        btn = block_until_ios_predicate(self, "XCUIElementTypeButton")

        btn[0].click()

        block_until_element(self, "Banner")

        assert_href_called(self, r"/click$")

        assert_href_called(self, r"/impression$")

        assert_href_called(self, r"/creativeView$")

        assert_href_called(self, r"/start$")

        assert_href_called(self, r"/firstQuartile$")

        assert_href_called(self, r"/midpoint$")

        assert_href_called(self, r"/thirdQuartile$")

        assert_href_called(self, r"/complete$")

        assert_href_called(self, r"/wrapper/click$")

        assert_href_called(self, r"/wrapper/impression$")

        assert_href_called(self, r"/wrapper/start$")

        assert_href_called(self, r"/wrapper/firstQuartile$")

        assert_href_called(self, r"/wrapper/pause$")

        assert_href_called(self, r"/wrapper/resume$")

        assert_href_called(self, r"/wrapper/midpoint$")

        assert_href_called(self, r"/wrapper/thirdQuartile$")

        assert_href_called(self, r"/wrapper/complete$")

    def test_vast_wrapper_linear_2(self):
        set_channel_id(self, "24388")
        
        click_load_ad_btn(self, "Video")

        block_until_not_element(self, "Video")

        block_until_ios_predicate(self, "XCUIElementTypeButton")

        # Click middle video
        positions = []
        positions.append((5, 5))
        self.driver.tap(positions)

        block_until_element(self, "Done")

        assert_viewing_browser(self)

        click_btn(self, "Done")

        # Poll until video is done
        sleep(45)

        btn = block_until_ios_predicate(self, "XCUIElementTypeButton")

        btn[0].click()

        block_until_element(self, "Banner")

        assert_href_called(self, r"/click$")

        assert_href_called(self, r"/impression$")

        assert_href_called(self, r"/creativeView$")

        assert_href_called(self, r"/start$")

        assert_href_called(self, r"/firstQuartile$")

        assert_href_called(self, r"/midpoint$")

        assert_href_called(self, r"/thirdQuartile$")

        assert_href_called(self, r"/complete$")

        assert_href_called(self, r"/wrapper/impression$")