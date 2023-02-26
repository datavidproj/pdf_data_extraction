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
ARG BBOX_IMAGES_KEY_PREFIX
ARG MASKED_IMAGES_KEY_PREFIX
ARG TABLE_CORNERS_KEY_PREFIX
ARG AWS_ACCOUNT_ID
ARG AWS_REGION
#ARG sqs_queue_name
ARG BATCH_SIZE
ARG RES_HIGH
ARG RES_LOW
ARG BUCKET_NAME

RUN echo "TARGET_KEY_PREFIX=$TARGET_KEY_PREFIX"
RUN echo "TARGET_IMG_KEY_PREFIX=$TARGET_IMG_KEY_PREFIX"
RUN echo "BBOX_IMAGES_KEY_PREFIX=$BBOX_IMAGES_KEY_PREFIX"
RUN echo "MASKED_IMAGES_KEY_PREFIX=$MASKED_IMAGES_KEY_PREFIX"
RUN echo "TABLE_CORNERS_KEY_PREFIX=$TABLE_CORNERS_KEY_PREFIX"
RUN echo "AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID"
RUN echo "AWS_REGION=$AWS_REGION"
RUN echo "BATCH_SIZE=$BATCH_SIZE"
RUN echo "RES_HIGH=$RES_HIGH"
RUN echo "RES_LOW=$RES_LOW"
RUN echo "BUCKET_NAME=$BUCKET_NAME"

ENV RES_HIGH=$RES_HIGH
ENV RES_LOW=$RES_LOW
ENV BATCH_SIZE=$BATCH_SIZE
ENV BUCKET_NAME=$BUCKET_NAME
ENV TARGET_KEY_PREFIX=$TARGET_KEY_PREFIX
ENV TARGET_IMG_KEY_PREFIX=$TARGET_IMG_KEY_PREFIX
ENV BBOX_IMAGES_KEY_PREFIX=$BBOX_IMAGES_KEY_PREFIX
ENV MASKED_IMAGES_KEY_PREFIX=$MASKED_IMAGES_KEY_PREFIX
ENV TABLE_CORNERS_KEY_PREFIX=$TABLE_CORNERS_KEY_PREFIX
ENV AWS_REGION=$AWS_REGION
ENV SQS_QUEUE_URL=https://sqs.$AWS_REGION.amazonaws.com/$AWS_ACCOUNT_ID/$SQS_QUEUE_NAME
#ENV TESSDATA_PREFIX=tessdata

RUN wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
RUN echo -e "[mongodb-org-4.0] \nname=MongoDB Repository\nbaseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/4.0/x86_64/\ngpgcheck=1 \nenabled=1 \ngpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc" | sudo tee /etc/yum.repos.d/mongodb-org-4.0.repo
RUN sudo yum install -y mongodb-org

# setting the CMD to your handler file_name.function_name
CMD [ "lambda_function.lambda_handler" ]
