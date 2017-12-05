# encoding: utf8

from test_base import DisplaySDKTest
from utils import *


SLEEP_INTERVAL = 2


class MRAIDTest(DisplaySDKTest):
    def test_mraid_single_expand_landscape_start(self):
        self.driver.orientation = 'LANDSCAPE'

        set_channel_id(self, "24338")

        click_load_ad_btn(self, "Banner")

        accept_location(self)

        block_until_webview(self)

        sleep(SLEEP_INTERVAL)

        click_on_webview(self)

        switch_context_to_webview(self)

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Rotate To Portrait")

        # Rotate phone back
        self.driver.orientation = 'PORTRAIT'

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Lock to Landscape")

        click_btn(self, "Lock to Landscape")

        assert_exists(self, "Lock to Portrait")

        self.driver.orientation = 'LANDSCAPE'

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Lock to Portrait")

        click_btn(self, "Lock to Portrait")

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Release Lock")

        # Rotate phone
        # self.driver.orientation = 'LANDSCAPE'

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Release Lock")

        # Rotate phone back
        self.driver.orientation = 'PORTRAIT'

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Release Lock")

        click_btn(self, "Release Lock")

        sleep(SLEEP_INTERVAL)

        assert_not_exists(self, "Lock to Portrait")
        assert_not_exists(self, "Lock To Landscape")
        assert_not_exists(self, "Release Lock")

        # Rotate phone
        self.driver.orientation = 'LANDSCAPE'

        sleep(SLEEP_INTERVAL)

        assert_not_exists(self, "Lock To Portrait")
        assert_not_exists(self, "Lock to Landscape")
        assert_not_exists(self, "Release Lock")

        # Rotate phone back
        self.driver.orientation = 'PORTRAIT'

        sleep(SLEEP_INTERVAL)

        click_x_btn(self)

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Expand!")

    def test_mraid_single_expand(self):
        set_channel_id(self, "24338")

        click_load_ad_btn(self, "Banner")

        accept_location(self)

        block_until_webview(self)

        sleep(SLEEP_INTERVAL)

        click_on_webview(self)

        switch_context_to_webview(self)

        assert_exists(self, "Lock to Landscape")

        # Rotate phone
        self.driver.orientation = 'LANDSCAPE'

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Rotate To Portrait")

        # Rotate phone back
        self.driver.orientation = 'PORTRAIT'

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Lock to Landscape")

        click_btn(self, "Lock to Landscape")

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Lock to Portrait")

        # self.driver.orientation = 'LANDSCAPE'

        # sleep(SLEEP_INTERVAL)

        click_btn(self, "Lock to Portrait")

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Release Lock")

        # Rotate phone
        #self.driver.orientation = 'LANDSCAPE'

        #sleep(SLEEP_INTERVAL)

        # assert_exists(self, "Release Lock")

        # Rotate phone back
        #self.driver.orientation = 'PORTRAIT'

        # sleep(SLEEP_INTERVAL)

        # assert_exists(self, "Release Lock")

        click_btn(self, "Release Lock")

        sleep(SLEEP_INTERVAL)

        assert_not_exists(self, "Lock to Portrait")
        assert_not_exists(self, "Lock To Landscape")
        assert_not_exists(self, "Release Lock")

        # Rotate phone
        self.driver.orientation = 'LANDSCAPE'

        sleep(SLEEP_INTERVAL)

        assert_not_exists(self, "Lock To Portrait")
        assert_not_exists(self, "Lock to Landscape")
        assert_not_exists(self, "Release Lock")

        # Rotate phone back
        self.driver.orientation = 'PORTRAIT'

        sleep(SLEEP_INTERVAL)

        click_x_btn(self)

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Expand!")

    def test_mraid_two_part_expand(self):
        set_channel_id(self, "24343")        

        click_load_ad_btn(self, "Banner")

        accept_location(self)

        block_until_webview(self)

        click_on_webview(self)

        sleep(SLEEP_INTERVAL)

        block_until_element(self, "Open IAB.net")

        self.driver.orientation = 'LANDSCAPE'

        sleep(SLEEP_INTERVAL)

        self.driver.orientation = 'PORTRAIT'

        sleep(SLEEP_INTERVAL)

        # Click on open iab.com button
        click_btn(self, "Open IAB.net")

        sleep(SLEEP_INTERVAL)

        assert_viewing_browser(self)

        # Close browser
        click_back_btn(self)

        # Play video
        click_btn(self, "PlayVideo")

        sleep(SLEEP_INTERVAL)

        assert_viewing_video(self)

        # Close video
        click_back_btn(self)

        # Assert expand again does nothing
        click_btn(self, "Expand Again")

        sleep(SLEEP_INTERVAL)

        assert_not_viewing_browser(self)

        # Close expanded view
        click_btn(self, "Click here to close.")

        sleep(SLEEP_INTERVAL)

        click_on_webview(self)

        sleep(SLEEP_INTERVAL)

        block_until_element(self, "Click here to close.")

        # TODO Click upper top corner and assert close
        click_btn(self, "Click here to close.")

        sleep(SLEEP_INTERVAL)

        assert_href_called(self, r"mraid://useCustomClose")

        assert_href_called(self, r"mraid://setOrientationProperties")

        assert_href_called(self, r"mraid://expand\?url=")

        assert_href_called(self, r"mraid://open\?url=")

        assert_href_called(self, r"mraid://playVideo")

        assert_href_called(self, r"mraid://close")

    def test_mraid_resize(self):
        set_channel_id(self, "24348")        

        click_load_ad_btn(self, "Banner")

        accept_location(self)

        block_until_webview(self)

        sleep(SLEEP_INTERVAL)

        click_on_webview(self)

        sleep(SLEEP_INTERVAL)

        assert_href_called(self, r"mraid://resize")

        # Click open url
        click_btn(self, "Open URL")

        sleep(SLEEP_INTERVAL)

        assert_viewing_browser(self)

        # Close browser
        click_back_btn(self)

        sleep(SLEEP_INTERVAL)

        assert_href_called(self, r"mraid://open\?url=.*www\.iab\.net")

        # Open map
        click_btn(self, "Click to Map")

        sleep(SLEEP_INTERVAL)

        assert_viewing_browser(self)

        # Close map
        click_back_btn(self)

        assert_href_called(self, r"mraid://open\?url=.*maps\.google\.com")

        # Open app
        click_btn(self, "Click to App")

        sleep(SLEEP_INTERVAL)

        try:
            click_btn(self, "OK")
        except:
            pass

        sleep(SLEEP_INTERVAL)

        try:
            assert_viewing_browser(self)

            click_back_btn(self)
        except:
            pass

        try:
            click_btn(self, "Return to Display Demo")

            sleep(SLEEP_INTERVAL)

            click_btn(self, "Done")
        except:
            pass

        assert_href_called(self, r"mraid://open\?url=.*itunes.apple.com")

        # Open video
        click_btn(self, "Play Video")

        sleep(SLEEP_INTERVAL)

        assert_viewing_video(self)

        # Close video
        click_back_btn(self)

        assert_href_called(self, r"mraid://playVideo")

        # Send sms
        click_btn(self, "SMS")

        sleep(SLEEP_INTERVAL)

        assert_viewing_sms(self)

        try:
            # Return to app
            click_btn(self, "Cancel")

            sleep(SLEEP_INTERVAL)
        except:
            pass

        click_btn(self, "Return to Display Demo")

        sleep(SLEEP_INTERVAL)

        assert_href_called(self, r"mraid://open\?url=sms")

        # Click to call
        click_btn(self, "Click to Call")

        sleep(SLEEP_INTERVAL)

        try:
            click_btn(self, "Cancel")
        except:
            pass

        try:
            assert_viewing_call(self)

            # Close call
            click_back_btn(self)
        except:
            pass

        sleep(SLEEP_INTERVAL)

        assert_href_called(self, r"mraid://open\?url=tel")

        click_x_btn(self)

    def test_mraid_full_page(self):
        set_channel_id(self, "24353")        

        click_load_ad_btn(self, "Banner")

        accept_location(self)

        block_until_webview(self)

        sleep(SLEEP_INTERVAL)

        click_btn(self, "Hide")

        sleep(SLEEP_INTERVAL)

        click_btn(self, "Show")

        # That on screen timer is not all zeros

        # Assert that off screen timer is not all zeros

    def test_mraid_resize_error(self):
        set_channel_id(self, "24358")        

        # Call specific size
        click_load_ad_btn(self, "Banner", "300x250")

        accept_location(self)

        block_until_webview(self)

        sleep(SLEEP_INTERVAL)

        # Click bad timing
        click_parent_btn(self, "bad timing")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "bad values")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "small")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "big")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "←")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "→")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "↑")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "↓")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "TRUE")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "←")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "→")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "↑")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "↓")

        sleep(SLEEP_INTERVAL)

        click_parent_btn(self, "X")

    def test_mraid_video_interstitial_full(self):
        set_channel_id(self, "24363")        

        click_load_ad_btn(self, "Interstitial")

        sleep(SLEEP_INTERVAL)

        accept_location(self)

        block_until_webview(self)

        block_until_element(self, "Video Playback")

        # Assert landscape view
        assert_landscape_view(self)

        block_until_not_element(self, "Video Playback")

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Banner")

    def test_mraid_video_interstitial(self):
        set_channel_id(self, "24363")

        click_load_ad_btn(self, "Interstitial")

        block_until_webview(self)

        # Assert that video exists
        block_until_element(self, "Video Playback")

        # Assert landscape view
        assert_landscape_view(self)

        # Click top right 50x50
        positions = []
        positions.append((-25, 25))
        self.driver.tap(positions)

        sleep(SLEEP_INTERVAL)

        click_btn(self, "Done")

        block_until_element(self, "Video Playback")

        # Click top right 50x50
        positions = []
        positions.append((-25, 25))
        self.driver.tap(positions)

        sleep(SLEEP_INTERVAL)

        assert_exists(self, "Banner")

    def test_mraid_video_interstitial_close_before_complete(self):
        set_channel_id(self, "24363")

        click_load_ad_btn(self, "Interstitial")

        # block_until_webview(self)

        # Assert that video exists
        block_until_element(self, "Video")

        # switch_context_to_webview(self)

        # Assert landscape view
        # assert_landscape_view(self)

        sleep(SLEEP_INTERVAL * 5)

        print_source(self)

        click_back_btn(self)

        assert_not_exists_webview(self)