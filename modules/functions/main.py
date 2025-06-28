import json
import os
from google.cloud import storage

def process_data(event, context):
    input_bucket_name = event['bucket']
    input_file_name = event['name']
    output_bucket_name = os.environ['OUTPUT_BUCKET']
    
    storage_client = storage.Client()
    
    input_bucket = storage_client.bucket(input_bucket_name)
    input_blob = input_bucket.blob(input_file_name)
    
    content = input_blob.download_as_text()
    
    try:
        data = json.loads(content)
        
        # データ加工処理
        processed_data = {
            'source_file': input_file_name,
            'record_count': len(data) if isinstance(data, list) else 1,
            'processed_at': context.timestamp,
            'data': data
        }
        
        output_bucket = storage_client.bucket(output_bucket_name)
        output_blob = output_bucket.blob(f"processed/{input_file_name}")
        output_blob.upload_from_string(
            json.dumps(processed_data),
            content_type='application/json'
        )
        
        print(f"Processed {input_file_name} successfully")
        
    except Exception as e:
        print(f"Error processing {input_file_name}: {str(e)}")
        raise e
