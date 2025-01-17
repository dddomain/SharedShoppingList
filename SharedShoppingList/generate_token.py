from google.cloud import secretmanager

def get_service_account_json():
    project_id = "sharedshoppinglist-feecd"
    secret_name = "firebase-service-account"
    
    client = secretmanager.SecretManagerServiceClient()
    secret_path = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
    response = client.access_secret_version(name=secret_path)
    service_account_json = response.payload.data.decode("UTF-8")
    
    return service_account_json
