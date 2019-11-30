import cv2
import numpy as np
import configRecogn as config
import requests

cap = cv2.VideoCapture("rtsp://" + config.RecognitionConfig['user'] + ':' + config.RecognitionConfig['password'] + '@' + config.RecognitionConfig['camera'])

frame_width = int( cap.get(cv2.CAP_PROP_FRAME_WIDTH))

frame_height =int( cap.get( cv2.CAP_PROP_FRAME_HEIGHT))

fourcc = cv2.VideoWriter_fourcc('X','V','I','D')

xMin400 = 750
xMax400 = 950
yMin400 = 300
yMax400 = frame_height

xMin401 = 1100
xMax401 = 1300
yMin401 = 250
yMax401 = frame_height - 250

xMin402 = 1500
xMax402 = 1600
yMin402 = 200
yMax402 = frame_height - 500

out = cv2.VideoWriter("output.avi", fourcc, 5.0, (frame_width,frame_height))
pause = 0

ret, frame1 = cap.read()
ret, frame2 = cap.read()

while cap.isOpened():
    if pause == 0:
        diff = cv2.absdiff(frame1, frame2)
        gray = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
        blur = cv2.GaussianBlur(gray, (5,5), 0)
        _, thresh = cv2.threshold(blur, 20, 255, cv2.THRESH_BINARY)
        dilated = cv2.dilate(thresh, None, iterations=3)
        contours, _ = cv2.findContours(dilated, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

        room = -1

        for contour in contours:
            (x, y, w, h) = cv2.boundingRect(contour)

            room = -1

            if w < 50 or h < 100:
                continue

            if y + h / 2 > yMin400 and y + h / 2 < yMax400 and x + w / 2 > xMin400 and x + w / 2 < xMax400:
                room = 400
                break

            if y + h / 2 > yMin401 and y + h / 2 < yMax401 and x + w / 2 > xMin401 and x + w / 2 < xMax401:
                room = 401
                break

            if y + h / 2 > yMin402 and y + h / 2 < yMax402 and x + w / 2 > xMin402 and x + w / 2 < xMax402:
                room = 402
                break

            if cv2.contourArea(contour) < 900:
                continue

        if room != -1:
            req = {'camId': config.RecognitionConfig['camId'], 'roomId': room}
            requests.post(config.RecognitionConfig['serverUrl'], data = req)
            pause = 12
    else: 
        pause = pause - 1

    frame1 = frame2
    ret, frame2 = cap.read()

    if cv2.waitKey(40) == 27:
        break

cv2.destroyAllWindows()
cap.release()
out.release()