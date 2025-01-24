import pyautogui
import pyscreeze

import time
import keyboard

def get_cursor_xy():
    x, y = pyautogui.position()  # Get current cursor position
    print(x, y)
    time.sleep(0.5)

def subprocess_preprocess():
    time.sleep(0.5)
    pyautogui.leftClick(275, 80)  # Click button 'Preprocess'
    time.sleep(0.5)
    pyautogui.leftClick(386, 125)  # Click up button to increase 'Spatial downsampling multiplier' 1 -> 2
    time.sleep(0.3)
    pyautogui.leftClick(386, 125)  # 'Spatial downsampling multiplier' 2 -> 3
    time.sleep(0.3)
    pyautogui.leftClick(386, 125)  # 'Spatial downsampling multiplier' 3 -> 4
    time.sleep(0.3)
    pyautogui.leftClick(65, 125)  # Click button 'Apply'
    while True:
        time.sleep(5.0)  # Check every 5 seconds to see if it is done
        if(pyautogui.pixel(2500, 140) == (237, 247, 225)):
            print("1. Preprocessing is done")
            break

def subprocess_spatialfilter():
    time.sleep(0.5)
    pyautogui.leftClick(396, 80)  # Click button 'Spatial Filter'
    time.sleep(0.5)
    pyautogui.leftClick(65, 125)  # Click button 'Apply'
    while True:
        time.sleep(5.0)  # Check every 5 seconds to see if it is done
        if(pyautogui.pixel(2500, 140) == (237, 247, 225)):
            print("2. Spatial filtering is done")
            break

def subprocess_motioncorrect():
    time.sleep(0.5)
    pyautogui.leftClick(524, 80)  # Click button 'Motion Correct'
    time.sleep(0.5)
    pyautogui.leftClick(65, 125)  # Click button 'Apply'
    while True:
        time.sleep(5.0)  # Check every 5 seconds to see if it is done
        if(pyautogui.pixel(2500, 140) == (237, 247, 225)):
            print("3. Motion correction is done")
            break

def subprocess_PCAICA():
    time.sleep(0.5)
    pyautogui.leftClick(716, 80)  # Click button 'Identify Cells'
    time.sleep(0.5)
    pyautogui.leftClick(716, 106)  # Click button 'PCA-ICA'
    time.sleep(0.5)
    pyautogui.leftClick(65, 125)  # Click button 'Apply'
    while True:
        time.sleep(10.0)  # Check every 10 seconds to see if it is done
        if((pyautogui.pixel(2500, 140) == (237, 247, 225)) | (pyautogui.pixel(2500, 140) == (252, 236, 200))):
            print("4. PCAICA cell identification is done")
            break

def subprocess_export_PCAICA(filePath, fileName):
    time.sleep(0.5)
    pyautogui.leftClick(1328, 80)  # Click button 'Export'
    time.sleep(0.5)
    pyautogui.leftClick(350, 125)  # Click button 'Cell traces File name for exporting...'
    time.sleep(0.5)
    pyautogui.leftClick(1620, 365)  # Click explorer file path box and change path
    time.sleep(0.5)
    pyautogui.typewrite(filePath)
    time.sleep(0.5)
    pyautogui.press('enter')
    time.sleep(0.5)
    pyautogui.leftClick(1100, 1345)  # Click explorer file name box and change name
    time.sleep(0.5)
    pyautogui.typewrite(fileName)
    time.sleep(0.5)
    pyautogui.press('enter')
    time.sleep(5.0)
    pyautogui.leftClick(65, 125)  # Click button 'Export'
    while True:
        time.sleep(5.0)  # Check every 10 seconds to see if it is done
        if((pyautogui.pixel(2500, 140) == (237, 247, 225))):
            print("PCAICA.csv is exported")
            break

def subprocess_export_IMUGPIO(filePath, fileName):
    time.sleep(0.5)
    pyautogui.leftClick(1328, 80)  # Click button 'Export'
    time.sleep(0.5)
    pyautogui.leftClick(350, 142)  # Click button 'IMU/GPIO traces File name for exporting...'
    time.sleep(0.5)
    pyautogui.leftClick(1620, 365)  # Click explorer file path box and change path
    time.sleep(0.5)
    pyautogui.typewrite(filePath)
    time.sleep(0.5)
    pyautogui.press('enter')
    time.sleep(0.5)
    pyautogui.leftClick(1100, 1345)  # Click explorer file name box and change name
    time.sleep(0.5)
    pyautogui.typewrite(fileName)
    time.sleep(0.5)
    pyautogui.press('enter')
    time.sleep(5.0)
    pyautogui.leftClick(65, 125)  # Click button 'Export'
    while True:
        time.sleep(5.0)  # Check every 10 seconds to see if it is done
        if((pyautogui.pixel(2500, 140) == (237, 247, 225))):
            print("IMU/GPIO.csv is exported")
            break

while True:
    if keyboard.is_pressed('ctrl+alt+m'):  # Execute analysis macro
        print("Starting automatic inscopix analysis...")
        time.sleep(0.5) # Short delay to prevent multiple triggering
        subprocess_preprocess()
        time.sleep(0.5)
        subprocess_spatialfilter()
        time.sleep(0.5)
        subprocess_motioncorrect()
        time.sleep(0.5)
        subprocess_PCAICA()
        print("===== DONE =====\n")
        time.sleep(5.0)

    if keyboard.is_pressed('ctrl+alt+s'):  # Execute save macro, be sure to hover over analyzed PCAICA file on file tree
        locX, locY = pyautogui.position()
        print("Input folder path of the original video file")
        filePath = input()
        fileName = filePath.split('\\')[-1]
        print("Starting automatic inscopix csv saves...")
        fileNamePCAICA = fileName + "_PCAICA"
        pyautogui.leftClick(locX, locY)
        time.sleep(3.0)
        subprocess_export_PCAICA(filePath, fileNamePCAICA)
        fileNameIMU = fileName + "_IMU"
        pyautogui.leftClick(locX, locY+25)
        time.sleep(3.0)
        subprocess_export_IMUGPIO(filePath, fileNameIMU)
        fileNameGPIO = fileName + "_GPIO"
        pyautogui.leftClick(locX, locY+50)
        time.sleep(3.0)
        subprocess_export_IMUGPIO(filePath, fileNameGPIO)
        print("===== DONE =====\n")        

    if keyboard.is_pressed('ctrl+alt+l'):  # Execute show cursor position
        get_cursor_xy()
