import os
import boto3
import json
import fitz
import ExtractTables as extract_tables
import base64
import cv2
import numpy as np
import pytesseract
import copy
import pymongo
import ssl

region = os.environ.get('AWS_REGION')
aws_access_key = os.environ.get('AWS_ACCESS_KEY')
aws_secret_access_key = os.environ.get('AWS_SECRET_ACCESS_KEY')
table_corners_key_prefix = os.environ.get("BBOX_IMAGES_KEY_PREFIX")
table_masked_key_prefix = os.environ.get("MASKED_IMAGES_KEY_PREFIX")
target_key_prefix = os.environ.get("TARGET_KEY_PREFIX")
table_corners_key_prefix = os.environ.get("TABLE_CORNERS_KEY_PREFIX")
db_name = os.environ.get("DOCDB_DB_NAME")
collection_name = os.environ.get("DOCDB_COLLECTION_NAME")
docdb_instance_class_name=os.environ.get("DOCDB_INSTANCE_CLASS_NAME")
docdb_cluster_id=os.environ.get("DOCDB_CLUSTER_ID")
docdb_username=os.environ.get("DOCDB_CLUSTER_USERNAME")
docdb_password=os.environ.get("DOCDB_CLUSTER_PASSWORD")
#bucket_name = os.environ.get("BUCKET_NAME")

#endpoint_id = "vpce-017159da4524c0a1e"

#s3_client = boto3.resource('s3', endpoint_url=f'https://s3.{region}.amazonaws.com')
# Create an S3 client that connects to the VPC endpoint
#s3_client = boto3.client('s3', endpoint_url=f'https://{endpoint_id}.s3.amazonaws.com')
s3_client = boto3.client('s3')
sqs_client = boto3.client('sqs')
docdb_client = boto3.client('docdb', region_name=region, aws_access_key_id=aws_access_key,
                      aws_secret_access_key=aws_secret_access_key)

#docdb_client = pymongo.MongoClient(f"mongodb+srv://{docdb_username}:{docdb_password}@docdb-cluster-demo.cluster-cnlqc9m8opvy.us-east-2.docdb.amazonaws.com/test?retryWrites=true&w=majority")
#    db = client["mydatabase"]
#    collection = db["mycollection"]

TEXT_BLOCK_TYPE = 0
IMG_BLOCK_TYPE = 1

#def extract_images(block_l):
#    images_xy = []
#    for block in block_l:
#        x0, y0, x1, y1, lines, block_no, block_type = block
#        if block_type == IMG_BLOCK_TYPE:
#            images_xy.append((x0, y0, x1, y1))
#    return images_xy

def get_documentdb_endpoint(cluster_name):
    # Create a DocumentDB client object
    client = boto3.client("docdb")

    # Get a list of all DocumentDB clusters
    response = client.describe_db_clusters()

    # Find the cluster with the specified name
    cluster = None
    for db_cluster in response["DBClusters"]:
        if db_cluster["DBClusterIdentifier"] == cluster_name:
            cluster = db_cluster
            break

    # If the cluster was not found, raise an exception
    if cluster is None:
        raise Exception("DocumentDB cluster not found: {}".format(cluster_name))

    # Return the cluster endpoint URL
    return cluster["Endpoint"]

def connect_to_documentdb(host, port, username, password, db_name):
    # Set the path to the certificate file
#    ca_file_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "rds-combined-ca-bundle.pem")
    ca_file_path = "./rds-combined-ca-bundle.pem"

    print(pymongo.__version__)

    ssl_context = ssl.create_default_context(cafile=ca_file_path)

    # Set up the MongoClient with SSL options
    client = pymongo.MongoClient(
        host=host,
        port=port,
        username=username,
        password=password,
        ssl=True,
        ssl_context=ssl_context
#        ssl_ca_certs=ca_file_path
    )

    # Get the specified database
    db = client[db_name]

    # Return the database object
    return db

def extract_paragraphs(block_l):
    paragraph_bbox_l = []
    for block in block_l:
        x0, y0, x1, y1, lines, block_no, block_type = block
        print(f'extract paragraph = {block}')
        if block_type == TEXT_BLOCK_TYPE:
#            rect = fitz.Rect(x0, y0, x1, y1)
#            textpage = page.get_textpage_ocr(flags=7, language='eng', rect = rect, dpi=600, full=True)
#            lines = textpage.extractText()
            paragraph_bbox_l.append((x0, y0, x1, y1, lines))
#            paragraph_l.append(text)
    return paragraph_bbox_l

def prepare_image_data(image_bbox_l, image):
    base64_jpg_l = []
    for image_bbox in image_bbox_l:
        jpg = extract_tables.jpg_in_bounding_box(image_bbox_l, image)
        base64_jpg = base64.b64encode(jpg)
        base64_jpg_l.append(base64_jpg)
    return base64_jpg_l

def prepare_paragraph_data(paragraph_bbox_l, image):
    paragraph_l = []
    for paragraph_bbox in paragraph_bbox_l:
        paragraph_l.append(paragraph_bbox[4])
    return paragraph_l

def prepare_table_data(table_dim_l, image):
    # copy image vector to protect it against modification
    image_content = copy.deepcopy(image)
    print(f'table_dim_l = {table_dim_l}')
    table_obj_l = []
    for table_dim in table_dim_l:
        table_obj = []
        for row in table_dim:
            row_arr = []
            for cell in row:
                x0, y0 = cell[0]
                x1, y1 = cell[1]

                # Extract the cell from the image
                cell_image = image_content[y0:y1, x0:x1]

                # Convert the cell image to grayscale
                gray = cv2.cvtColor(cell_image, cv2.COLOR_BGR2GRAY)

                # Apply thresholding to the cell image
                thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)[1]

                # Apply dilation to the thresholded image
                kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (2,2))
                dilate = cv2.dilate(thresh, kernel, iterations=2)

                # Extract text from the cell using PyTesseract
                text = pytesseract.image_to_string(dilate, config='--psm 6')
                print(f"table data: row = {row}, cell = {cell}, text = {text}")

                row_arr.append(text)
            table_obj.append(row_arr)
        table_obj_l.append(table_obj)
    return table_obj_l

#def extract_text_from_image(image, bbox):
#    _, encoded_img = cv2.imencode('.jpg', image)
#
#    # Convert the binary data to a bytes object
#    image_data = encoded_img.tobytes()
#
#    # Create fitz PDF document from masked image
#    with fitz.open(stream=image_data, filetype="jpg") as img_file:
#
#        x0, y0, x1, y1 = bbox
#
#        # Get pixmap for page insert
#        page = list(img_file.pages())[0]
#        pix = page.get_pixmap()
#
#        # Create a new document with a single page
#        doc = fitz.open()
#        page = doc.new_page()
#
#        # Draw the image onto the page
#        page.insert_image(fitz.Rect(x0, y0, x1, y1), pixmap=pix)
#
#        textpage = page.get_textpage_ocr(flags=7, language='eng', dpi=600, full=True)
#
#        # Extract the text from the OCR result
#        text = textpage.extractText()
#
#        return text

#RES_RATIO = 600/72

# Debugging
def save_bboximages(image, bucket, filename, suffix):
    base_filename = os.path.splitext(filename)[0]
    key = f"{table_corners_key_prefix}{base_filename}_{suffix}.jpg"
    print(f'temp: key={key}')
    _, buffer = cv2.imencode('.jpg', image)
    image_b = buffer.tobytes()
    s3_client.put_object(Bucket=bucket, Key=key, Body=image_b)

# Debugging
def save_masked_image(image, bucket, filename):
    success_f, encoded_img = cv2.imencode('.jpg', image)

    # Convert the binary data to a bytes object
    image_b = encoded_img.tobytes()

    base_filename = os.path.splitext(filename)[0]
    key = f"{table_masked_key_prefix}{base_filename}_masked.jpg"
    print(f'mask: key={key}')
    s3_client.put_object(Bucket=bucket, Key=key, Body=image_b)

def prepare_document_data(page_num, image_l, paragraph_bbox_l, table_dim_l, image, bucket, filename):
    save_bboximages(image, bucket, filename, 'table')
    table_obj_l = prepare_table_data(table_dim_l, image)
    paragraph_l = prepare_paragraph_data(paragraph_bbox_l, image)

    docdata = {}
    docdata['page'] = page_num
    docdata['paragraphs'] = paragraph_l
    docdata['images'] = image_l
    docdata['tables'] = table_obj_l
    return docdata

def extract_message(message_body):
    # Extract the filename, filename_lres, bucket, key prefix, and timestamp from the message
    message = json.loads(message_body)
    filename = message['filename']
    filename_lres = message['filename_lres']
    page_num = message['page_num']
    bucket = message['bucket']
    key_prefix = message['key_prefix']
    return filename, filename_lres, page_num, bucket, key_prefix

def get_np_image(bucket, key):
    print(f'bucket={bucket}, key={key}')
    response = s3_client.get_object(Bucket=bucket, Key=key)
    content_b = response['Body'].read()

    # Decode the JPG data into a numpy array
    image = cv2.imdecode(np.frombuffer(content_b, np.uint8), cv2.IMREAD_COLOR)
    return image

#def process_pdf(pdf_content):
#    pdf_file = fitz.open(stream=pdf_content, filetype="pdf")
#    page = list(pdf_file.pages())[0]
#    textpage = page.get_textpage_ocr(flags=7, language='eng', dpi=300, full=True)
#
#    # Extract the text blocks from the OCR result
#    block_l = textpage.extractBLOCKS()
#
#    images = extract_images(block_l)
#    paragraphs = extract_paragraphs(block_l)
#    tables = extract_tables(block_l)
#    return images, paragraphs, tables
#
def process_img(image, image_lres):
    print(f'Entered process img')
    corners, table_corners, arr, horizontal_lines, vertical_lines = extract_tables.detect_table(image_lres)

    # Debugging: Check if mapping is correct
    output_map_lres = extract_tables.get_lowres_ouput(image_lres, arr, horizontal_lines, vertical_lines)
    output_map = extract_tables.get_ouput(image, arr, horizontal_lines, vertical_lines)

    table_dim_l = extract_tables.get_table_dim_list(arr)

    print('table_dim_l = ', table_dim_l)

    masked_tbl_img = extract_tables.remove_bbox_from_image(image, [table_corners])

    # convert image verctor to base64 string
    base64_jpg_l = []

    _, encoded_img = cv2.imencode('.jpg', image)

    # Convert the binary data to a bytes object
    image_data = encoded_img.tobytes()
    base64_jpg = base64.b64encode(image_data).decode('ascii')
    base64_jpg_l.append(base64_jpg)

    # Create fitz PDF document from masked image
    _, encoded_img = cv2.imencode('.jpg', masked_tbl_img)

    # Convert the binary data to a bytes object
    masked_tbl_img_b = encoded_img.tobytes()

    with fitz.open(stream=masked_tbl_img_b, filetype="jpg") as img_file:

        # Get pixmap for page insert
        page_image = list(img_file.pages())[0]
        pix = page_image.get_pixmap(dpi=150, alpha=False)

#        # Set the image resolution
#        page = list(doc.pages())[0]
##        page.set_dpi(600, 600)
#
#        # Perform OCR on the first page of the image using Tesseract
#        page = doc[0]
#        textpage = page.textpage_ocr(engine="tesseract", dpi=600, full=True)

        # Create a new document with a single page
        doc = fitz.open()
        page = doc.new_page(width=page_image.rect.width, height=page_image.rect.height)

        # Draw the image onto the page
        page.insert_image(fitz.Rect(0, 0, page.rect.width, page.rect.height), pixmap=pix)

        print(f'page_size: width = {page.rect.width}, height = {page.rect.height}')

        textpage = page.get_textpage_ocr(flags=7, language='eng', dpi=150, full=True)

        # Extract the text blocks from the OCR result
        block_l = textpage.extractBLOCKS()

#        paragraph_bbox_l = extract_paragraphs(block_l, textpage)
        paragraph_bbox_l = extract_paragraphs(block_l)

    return base64_jpg_l, paragraph_bbox_l, table_dim_l, output_map_lres, output_map, masked_tbl_img

def save_docdata(bucket, filename, docdata):
    # Save the docdata to S3
    base_filename = os.path.splitext(filename)[0]
    json_key = f"{target_key_prefix}{base_filename}.json"
    print(f'text_key={json_key}')
    jsonobj = json.dumps(docdata)
    s3_client.put_object(Bucket=bucket, Key=json_key, Body=jsonobj)

#def save_paragraph_dim(bucket, filename, paragraph_dict_l):
#    text_dim_key_prefix = os.environ["TEXT_DIM_KEY_PREFIX"]
#    base_filename = os.path.splitext(filename)[0]
#    jpg_key = f"{text_dim_key_prefix}/{base_filename}_text_dim.jpg"
#    print(f'text_dim_key={jpg_key}')
#    s3_client.put_object(Bucket=bucket, Key=jpg_key, Body=content)

def delete_message(record):
    queue_url = record['eventSourceARN'].split(':')[5]
    print(f"queue_url={queue_url}")

    response = sqs_client.delete_message(
        QueueUrl=queue_url,
        ReceiptHandle=record['receiptHandle']
    )

# Debugging
def save_table_corner_files(bucket, filename, filename_lres, output, output_lres):
    base_filename = os.path.splitext(filename)[0]
    key = f"{table_corners_key_prefix}{base_filename}_corners.jpg"
    print(f'corner: key={key}')
    base_filename_lres = os.path.splitext(filename_lres)[0]
    key_lres = f"{table_corners_key_prefix}{base_filename_lres}_corners.jpg"
    s3_client.put_object(Bucket=bucket, Key=key, Body=output)
    s3_client.put_object(Bucket=bucket, Key=key_lres, Body=output_lres)

def docdb_operations(docdata: json):
#    docdb_client.create_db_instance(DBInstanceIdentifier=db_name)
    # Get the DocumentDB connection details from environment variables
#    host = os.environ["DOCUMENTDB_HOST"]

    #endpoint = get_documentdb_endpoint(docdb_cluster_id)
    endpoint = "docdb-cluster-demo.cluster-cnlqc9m8opvy.us-east-2.docdb.amazonaws.com"

    # Connect to the DocumentDB cluster
    db = connect_to_documentdb(endpoint, 27017, docdb_username, docdb_password, db_name)

#    response = docdb_client.describe_db_clusters(DBClusterIdentifier=docdb_cluster_id)

    # Get the endpoint and port for the primary instance
#    endpoint = response['DBClusters'][0]['Endpoint']
#    port = response['DBClusters'][0]['Port']

#    client = pymongo.MongoClient('mongodb://%s:%s' % (endpoint, port))
#    docdb_client.create_db_instance(DBInstanceIdentifier=db_name, DBClusterIdentifier=docdb_cluster_id, DBInstanceClass=docdb_instance_class_name, Engine='docdb')

#    docdb_client.create_collection(DBInstanceIdentifier=db_name, CollectionName=collection_name)
#    db =  client[db_name]
    collection = db[collection_name]
    result = collection.insert_one(docdata)
    print("create collection successful")

def lambda_handler(event, context):
    # Extract the records from the SQS event
    records = event['Records']

    for record in records:
        # Extract the message body from the record
        message_body = record['body']

        filename, filename_lres, page_num, bucket, key_prefix = extract_message(message_body)

        print(f'filename={filename}, filename_lres={filename_lres}, page_num={page_num}, bucket={bucket}, key_prefix={key_prefix}')

        key = f'{key_prefix}/{filename}'
        key_lres = f'{key_prefix}/{filename_lres}'
        image = get_np_image(bucket, key)
        image_lres = get_np_image(bucket, key_lres)

        image_l, paragraph_bbox_l, table_dim_l, output_lres, output, masked_tbl_img = process_img(image, image_lres)

        save_table_corner_files(bucket, filename, filename_lres, output, output_lres)

        save_masked_image(masked_tbl_img, bucket, filename)

        print(f'paragraph_bbox_l = {paragraph_bbox_l}')

        docdata = prepare_document_data(page_num, image_l, paragraph_bbox_l, table_dim_l, image, bucket, filename)

        # Save the extracted text to S3
        save_docdata(bucket, filename, docdata)

        # Perform docdb operations
        docdb_operations(docdata)

        delete_message(record)

    return {
        'statusCode': 200,
        'body': 'Success'
    }
