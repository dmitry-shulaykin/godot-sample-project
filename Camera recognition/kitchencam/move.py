import cv2
import numpy as np
import configRecogn as config

cap = cv2.VideoCapture("rtsp://" + config.RecognitionConfig['user'] + ':' + config.RecognitionConfig['password'] + '@' + config.RecognitionConfig['camera'])

frame_width = int( cap.get(cv2.CAP_PROP_FRAME_WIDTH))

frame_height =int( cap.get( cv2.CAP_PROP_FRAME_HEIGHT))

fourcc = cv2.VideoWriter_fourcc('X','V','I','D')

xMin = 470
xMax = frame_width - 50
yMin = 70
yMax = 300

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

            if y + h / 2 > yMin and y + h / 2 < yMax and x + w / 2 > xMin and x + w / 2 < xMax:
                room = 499
                break

            if cv2.contourArea(contour) < 900:
                continue

        if room != -1:
            pause = 15
            req = {'camId': config.RecognitionConfig['camId'], 'roomId': room}
            requests.post(config.RecognitionConfig['serverUrl'], data = req)
    else: 
        pause = pause - 1

    frame1 = frame2
    ret, frame2 = cap.read()

    if cv2.waitKey(40) == 27:
        break

cv2.destroyAllWindows()
cap.release()
out.release()