FROM 093487613626.dkr.ecr.us-east-2.amazonaws.com/tesseract_1_83_0_leptonica_5_3_0:latest

# Copy function code to container
COPY ExtractTables.py ./
COPY lambda_function.py ./
#COPY tessdata/eng.traineddata ./tessdata/eng.traineddata
COPY requirements.txt ./

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install pytesseract

ARG TARGET_KEY_PREFIX
ARG TARGET_IMG_KEY_PREFIX
ARG BBOX_IMAGES_KEY_PREFIx
ARG MASKED_IMAGES_KEY_PREFIX
ARG TABLE_CORNERS_KEY_PREFIx
ARG AWS_ACCOUNT_ID
ARG AWS_REGION
#ARG sqs_queue_name
ARG BATCH_SIZE
ARG RES_HIGH
ARG RES_LOW

ENV RES_HIGH=$RES_HIGH
ENV RES_LOW=$RES_LOW
ENV BATCH_SIZE=$BATCH_SIZE
ENV TARGET_KEY_PREFIX=$TARGET_KEY_PREFIX
ENV TARGET_IMG_KEY_PREFIX=$TARGET_IMG_KEY_PREFIX
ENV BBOX_KEY_PREFIX=$BBOX_IMAGES_KEY_PREFIx
ENV MASKED_KEY_PREFIX=MASKED_IMAGES_KEY_PREFIX
ENV TABLE_CORNERS_KEY_PREFIX=TABLE_CORNERS_KEY_PREFIX
ENV SQS_QUEUE_URL=https://sqs.$AWS_REGION.amazonaws.com/$AWS_ACCOUNT_ID/$SQS_QUEUE_NAMe
#ENV TESSDATA_PREFIX=tessdata

# setting the CMD to your handler file_name.function_name
CMD [ "lambda_function.lambda_handler" ]
