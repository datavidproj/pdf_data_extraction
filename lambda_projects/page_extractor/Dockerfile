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

ARG TF_VAR_target_key_prefix
ARG TF_VAR_bbox_images_key_prefix
ARG TF_VAR_masked_images_key_prefix
ARG TF_VAR_table_corners_key_prefix
ARG AWS_ACCOUNT_ID
ARG AWS_REGION
ARG TF_VAR_sqs_queue_name
ARG BATCH_SIZE
ARG RES_HIGH
ARG RES_LOW

ENV RES_HIGH=$RES_HIGH
ENV RES_LOW=$RES_LOW
ENV BATCH_SIZE=$BATCH_SIZE
ENV TARGET_KEY_PREFIX=$TF_VAR_target_key_prefix
ENV BBOX_KEY_PREFIX=$TF_VAR_bbox_images_key_prefix
ENV MASKED_KEY_PREFIX=TF_VAR_masked_images_key_prefix
ENV TABLE_CORNERS_KEY_PREFIX=TF_VAR_table_corners_key_prefix
ENV SQS_QUEUE_URL=https://sqs.$AWS_REGION.amazonaws.com/$AWS_ACCOUNT_ID/$TF_VAR_sqs_queue_name
#ENV TESSDATA_PREFIX=tessdata

# setting the CMD to your handler file_name.function_name
CMD [ "lambda_function.lambda_handler" ]
