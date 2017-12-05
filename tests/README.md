# Testing

## Testing on Simulator

### Step 1 - Install Appium

```
brew install node
npm install -g appium
npm install -g wd
sudo pip install Appium-Python-Client
```

### Step 2 - Start Appium

`appium`

### Step 3 - Add demo app bundle into `tests` root directory

### Step 4 - Run tests

All tests:

`python -m unittest test_specific.SpecificTest`
`python -m unittest test_mraid.MRAIDTest`
`python -m unittest test_random.RandomTest`

Individual test:

`python -m unittest test_specific.SpecificTest.test_banner`

## Testing on Real Device

### Step 1 - Install extra libs beside the appium libs installed for simulator testing

```
brew install libimobiledevice
npm install -g ios-deploy
```

### Step 2 - Install WebDriverAgent on phone
Follow instruction on `https://appium.readthedocs.io/en/stable/en/appium-setup/real-devices-ios/`, `Full manual configuration` section till the end.

### Step 3 - Start Appium
`appium -U <udid> --app "<app bundle id>"`

### Step 4 - Add demo app bundle into `tests` root directory

### Step 5 - Run tests

All tests:

`python -m unittest test_specific.SpecificTest`
`python -m unittest test_mraid.MRAIDTest`
`python -m unittest test_random.RandomTest`

Individual test:

`python -m unittest test_specific.SpecificTest.test_banner`
