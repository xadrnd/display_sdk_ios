from test_base import DisplaySDKTest
from utils import *


SLEEP_INTERVAL = 2


class BruteForceTest(DisplaySDKTest):
    def test_video_rotation(self):
        for i in range(50):
            set_channel_id(self, "24383")

            click_load_ad_btn(self, "Video")

            accept_location(self)

            block_until_not_element(self, "Banner")

            btn = block_until_ios_predicate(self, "XCUIElementTypeButton")

            assert_landscape_view(self)

            btn[0].click()
            
            sleep(SLEEP_INTERVAL)

            self.driver.orientation = 'PORTRAIT'