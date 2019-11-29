import cv2
import numpy as np
import configRecogn as config

cap = cv2.VideoCapture("rtsp://" + config.RecognitionConfig['user'] + ':' + config.RecognitionConfig['password'] + '@' + config.RecognitionConfig['camera'])

frame_width = int( cap.get(cv2.CAP_PROP_FRAME_WIDTH))

frame_height =int( cap.get( cv2.CAP_PROP_FRAME_HEIGHT))

fourcc = cv2.VideoWriter_fourcc('X','V','I','D')

xMin = 450
xMax = frame_width - 50
yMin = 70
yMax = 300

out = cv2.VideoWriter("output.avi", fourcc, 5.0, (frame_width,frame_height))

ret, frame1 = cap.read()
ret, frame2 = cap.read()

while cap.isOpened():
    diff = cv2.absdiff(frame1, frame2)
    gray = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5,5), 0)
    _, thresh = cv2.threshold(blur, 20, 255, cv2.THRESH_BINARY)
    dilated = cv2.dilate(thresh, None, iterations=3)
    contours, _ = cv2.findContours(dilated, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    message = "Not found"
    color = (255, 255, 255)

    for contour in contours:
        (x, y, w, h) = cv2.boundingRect(contour)

        message = "Not found"
        color = (255, 255, 255)

        if w < 50 or h < 50:
            continue

        if y + h / 2 > yMin and y + h / 2 < yMax and x + w / 2 > xMin and x + w / 2 < xMax:
            message = "400"
            color = (255, 0, 0)
            break

        if cv2.contourArea(contour) < 900:
            continue

    if message != "Not found":
        cv2.rectangle(frame1, (x, y), (x+w, y+h), color, 2)
        cv2.putText(frame1, "Status: {} x: {} y: {} w: {} h: {}".format(message, x + w / 2, y + h / 2, w, h), (10, 20), cv2.FONT_HERSHEY_COMPLEX_SMALL,
            1, (0, 0, 255), 3)

    image = cv2.resize(frame1, (frame_width,frame_height))
    out.write(image)
    cv2.imshow("feed", frame1) # [yMin:yMax, xMin:xMax]
    frame1 = frame2
    ret, frame2 = cap.read()

    if cv2.waitKey(40) == 27:
        break

cv2.destroyAllWindows()
cap.release()
out.release()