#!/bin/bash
eval ${PRELOAD_FLAG} ${BIN_DIR}/darknet detect ${DATASET_DIR}/coco.data ${DATASET_DIR}/yolov3.cfg ${DATASET_DIR}/yolov3.weights ${DATASET_DIR}/dog.jpg > stdout.txt 2> stderr.txt
