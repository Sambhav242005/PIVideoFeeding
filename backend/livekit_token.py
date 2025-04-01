from flask import Flask, jsonify
from livekit import api

app = Flask(__name__)

# LiveKit credentials (replace with actual values)
LIVEKIT_API_KEY = "APICCkhdkmdH5AS"
LIVEKIT_API_SECRET = "jdXtEBiCMSwDliHeAnSisN0kt1ImyEtcIVoS93WzfeUBxxx"

# Room name
ROOM_NAME = "1"

def generate_token(identity, can_publish=False, can_subscribe=False):
    """Generates a LiveKit token with the specified permissions using livekit-api."""
    token = api.AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET) \
        .with_identity(identity) \
        .with_grants(api.VideoGrants(
            room=ROOM_NAME,
            room_join=True,
            can_publish=can_publish,
            can_subscribe=can_subscribe
        )).to_jwt()
    
    return token

@app.route('/generate_tokens', methods=['GET'])
def generate_tokens():
    """Generates and returns both a streamer and a viewer token."""
    streamer_token = generate_token("Streamer", can_publish=True, can_subscribe=False)
    viewer_token = generate_token("Subscriber", can_publish=False, can_subscribe=True)

    return jsonify({
        "streamer_token": streamer_token,
        "viewer_token": viewer_token
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=6969, debug=True)  # Debug mode for testing
