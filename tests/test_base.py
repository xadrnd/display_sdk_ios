import unittest
import os
from appium import webdriver
from time import sleep
from utils import *

from selenium.webdriver.common.keys import Keys


class DisplaySDKTest(unittest.TestCase):

    def setUp(self):
        # set up appium
        app = os.path.join(os.path.dirname(__file__), 'XADDisplayDemo.app')
        app = os.path.abspath(app)

        ## This setting is used for resting in simulator
        # self.driver = webdriver.Remote(
        #     command_executor='http://127.0.0.1:4723/wd/hub',
        #     desired_capabilities={
        #         'automationName': 'XCUITest',
        #         'app': app,
        #         'deviceName': 'iPhone 8',
        #         'platformName': 'iOS',
        #         'showXcodeLog': True,
        #         'showIOSLog': True,
        #         'noReset': True,
        #         'preventWDAAttachments': False,
        #         'clearSystemFiles': True
        #     })

        ## This is used for resting in real device
        self.driver = webdriver.Remote(
        command_executor='http://127.0.0.1:4723/wd/hub',
        desired_capabilities={
            'boundId':'com.groundtruth.sdk.displaysdk.basic.demo.enterprise',
            'uuid': '2d86e9ddaca632f1901fbc118cc1eef6be6c7f2f',
            'automationName': 'XCUITest',
            'app': app,
            'deviceName': 'iPhone',
            'platformName': 'iOS',
            'showXcodeLog': True,
            'showIOSLog': True,
            'noReset': True,
            'preventWDAAttachments': False,
            'clearSystemFiles': True,
            'xcodeOrgId': '7S36YSK9RV',
            'xcodeSigningId': 'iPhone Developer'
            })

    def tearDown(self):
        #self.driver.quit()
        pass