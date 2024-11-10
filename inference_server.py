import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify
import requests

# Configure logging
logging.basicConfig(
    filename='sentiment_api.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

app = Flask(__name__)

def log_request(request_data, response_data, response_status):
    """Log request and response data to file with enhanced request metadata"""
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "request": {
            # Client information
            "ip_address": request.remote_addr,
            "client_info": {
                "user_agent": request.user_agent.string,
                "platform": request.user_agent.platform,
                "browser": request.user_agent.browser,
                "version": request.user_agent.version,
            },
            # Request metadata
            "method": request.method,
            "url": request.url,
            "base_url": request.base_url,
            "path": request.path,
            "headers": dict(request.headers),
            "args": dict(request.args),
            "body": request_data,
            # Environment info
            "protocol": request.environ.get('SERVER_PROTOCOL'),
            "request_id": request.environ.get('REQUEST_ID', ''),
            "remote_port": request.environ.get('REMOTE_PORT'),
        },
        "response": {
            "status_code": response_status,
            "data": response_data,
        },
        # Additional context
        "server_timestamp": datetime.now().isoformat(),
        "processing_time": request.environ.get('REQUEST_TIME', 0)
    }
    
    # If there's an X-Forwarded-For header, include the original client IP
    if request.headers.get('X-Forwarded-For'):
        log_entry["request"]["original_ip"] = request.headers.get('X-Forwarded-For')

    logging.info(json.dumps(log_entry, indent=2))

@app.route('/analyze-sentiment', methods=['POST'])
@app.route('/models/cardiffnlp/twitter-roberta-base-sentiment-latest', methods=['POST'])
def analyze_sentiment():
    """
    Proxy endpoint for sentiment analysis
    Expects POST request with JSON body containing 'inputs' field with text to analyze
    """
    try:
        # Get request data
        request_data = request.get_json()
        
        # HuggingFace API configuration
        API_URL = "https://api-inference.huggingface.co/models/cardiffnlp/twitter-roberta-base-sentiment-latest"
        headers = {
            "Authorization": "Bearer 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",
            "Content-Type": "application/json"
        }
        
        # Make request to HuggingFace API
        response = requests.post(API_URL, headers=headers, json=request_data)
        response_data = response.json()
        
        # Log the request and response with status code
        log_request(request_data, response_data, response.status_code)
        
        return jsonify(response_data), response.status_code
        
    except Exception as e:
        error_response = {
            "error": str(e),
            "status": "error"
        }
        logging.error(f"Error processing request: {str(e)}")
        log_request(request_data, error_response, 500)
        return jsonify(error_response), 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80, debug=True)


