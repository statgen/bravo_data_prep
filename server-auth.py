from flask import Flask, request, jsonify, abort, url_for
import requests
from pymongo import MongoClient
from webargs import fields
from webargs.flaskparser import parser
import functools
import urllib
import jwt
from datetime import datetime
import hashlib
import os

app = Flask(__name__)

api_version = 'v1'

port = 7776


mongo_host = 'localhost'
mongo_port = 27017
mongo_db_name = 'topmed_freeze5_hg38_testing'


GOOGLE_CLIENT_ID = '27789452673-oi53pfnke1a6mk8shbg7uf5ooe24bdsq.apps.googleusercontent.com'
GOOGLE_CLIENT_SECRET = '-2f288sVZVIuxNUTtNzglLzJ'
GOOGLE_AUTH_API = 'https://accounts.google.com/o/oauth2/v2/auth'
GOOGLE_TOKEN_API = 'https://www.googleapis.com/oauth2/v4/token'
GOOGLE_TOKENINFO_API = 'https://www.googleapis.com/oauth2/v3/tokeninfo'
GOOGLE_AUTH_SCOPE = 'https://www.googleapis.com/auth/userinfo.email'
GOOGLE_ACCESS_TYPE = 'offline'
GOOGLE_RESPONSE_TYPE = 'code'


BRAVO_AUTH_SECRET = '8pSYh4AXudNuN7IIIc06'
BRAVO_ACCESS_SECRET = '0y66U2gtPk1YGZrFoIBO'


def setup_auth_tokens_collection(mongo, db_name):
    db = mongo[db_name]
    if 'auth_tokens' not in db.collection_names():
        db.create_collection('auth_tokens')
    db.auth_tokens.create_index('issued_at', expireAfterSeconds = 3 * 60)


mongo = MongoClient(mongo_host, mongo_port, connect = True)
setup_auth_tokens_collection(mongo, mongo_db_name)

def get_db():
   return mongo[mongo_db_name]


def validate_google_access_token(access_token):
    google_response = requests.get(GOOGLE_TOKENINFO_API, params = { 'access_token': access_token })
    if google_response.status_code != 200:
        return (None, None)
    access_token_data = google_response.json()
    expires_in = access_token_data.get('expires_in', None)
    if expires_in is None or int(expires_in) <= 0:
        return (None, None)
    scope = access_token_data.get('scope', None)
    if scope is None or GOOGLE_AUTH_SCOPE not in scope.split():
        return (None, None)
    if access_token_data.get('email_verified', '') != 'true':
        return (None, None)
    return (access_token_data.get('email', None), access_token_data.get('aud', None))


def authorize_user(token_email, token_client_id):
    document = get_db().users.find_one({ 'email': token_email, 'agreed_to_terms': True, 'enabled_api': True }, projection = {'_id': False})
    if not document:
        return False
    if token_client_id != GOOGLE_CLIENT_ID:
        return False
    return True


class UserError(Exception):
    status_code = 400
    def __init__(self, message, status_code = None):
        Exception.__init__(self)
        self.message = message


@app.errorhandler(UserError)
def handle_user_error(error):
    response = jsonify({ 'error': error.message })
    response.status_code = error.status_code
    return response


@app.route('/auth', methods = ['GET'])
def auth():
    issued_at = datetime.utcnow()
    auth_token = jwt.encode({'ip': request.remote_addr, 'iat': issued_at}, BRAVO_AUTH_SECRET, algorithm = 'HS256')
    payload = {
        'client_id': GOOGLE_CLIENT_ID,
        'redirect_uri': url_for('auth_callback', _external = True),
        'access_type': GOOGLE_ACCESS_TYPE,
        'response_type': GOOGLE_RESPONSE_TYPE,
        'scope': GOOGLE_AUTH_SCOPE,
        'state': auth_token
    }
    auth_url = '{}?{}'.format(GOOGLE_AUTH_API, urllib.urlencode(payload))
    get_db().auth_tokens.insert({'auth_token': auth_token, 'issued_at': issued_at, 'access_token': None, 'error': None })
    response = jsonify({
        'auth_url': auth_url,
        'auth_token': auth_token
    })
    response.status_code = 200
    return response


@app.route('/auth/callback', methods = ['GET'])
def auth_callback():
    auth_token = request.args.get('state', None)
    auth_code = request.args.get('code', None)
    try:
        decoded_auth_token = jwt.decode(auth_token, BRAVO_AUTH_SECRET)
    except jwt.InvalidTokenError:
        raise UserError('Bad authorization token.')
    document = get_db().auth_tokens.find_one({ 'auth_token': auth_token, 'access_token': None, 'error': None }, projection = {'_id': False}) 
    if not document:
        raise UserError('Expired authorization token.')
    payload = {
        'client_id': GOOGLE_CLIENT_ID,
        'client_secret': GOOGLE_CLIENT_SECRET,
        'code': auth_code,
        'redirect_uri': url_for('auth_callback', _external = True),
        'grant_type': 'authorization_code'
    }
    google_response = requests.post(GOOGLE_TOKEN_API, data = payload)
    google_response_data = google_response.json()
    if google_response.status_code != 200:
        get_db().auth_tokens.update_one({ 'auth_token': auth_token}, {'$set': {'error': google_response_data['error_description']}})
        raise UserError(google_response_data['error_description'])
    email, client_id = validate_google_access_token(google_response_data['access_token'])
    if email is None or client_id is None:
        get_db().auth_tokens.update_one({ 'auth_token': auth_token}, {'$set': {'error': 'Invalid Google access token.'}})
        raise UserError('Invalid Google access token.')
    if not authorize_user(email, client_id):
        get_db().auth_tokens.update_one({ 'auth_token': auth_token}, {'$set': {'error': 'You are not authorized for API access.'}})
        raise UserError('Not authorized')
    access_token = jwt.encode({'email': email, 'iat': datetime.utcnow()}, BRAVO_ACCESS_SECRET, algorithm = 'HS256')
    get_db().auth_tokens.update_one({ 'auth_token': auth_token}, {'$set': {'access_token': access_token}})
    return jsonify({'status': 'OK'}), 200


@app.route('/token', methods = ['POST'])
def get_token():
    auth_token = request.form.get('auth_token', None)
    if auth_token is None:
        raise UserError('Bad Request.')
    try:
        decoded_auth_token = jwt.decode(auth_token, BRAVO_AUTH_SECRET)
    except jwt.InvalidTokenError:
        raise UserError('Bad authorization token.')
    if decoded_auth_token['ip'] != request.remote_addr:
        raise UserError('This authorization token was issued for different IP address.') 
    document = get_db().auth_tokens.find_one({ 'auth_token': auth_token }, projection = {'_id': False})
    if not document:
        raise UserError('Expired authorization token.')
    if document['error'] is not None:
        get_db().auth_tokens.remove({ 'auth_token': auth_token })
        raise UserError(document['error'])
    if document['access_token'] is not None:
        get_db().auth_tokens.remove({ 'auth_token': auth_token })
        response = jsonify({'access_token': document['access_token'], 'token_type': 'Bearer'})
    else:    
        response = jsonify({'access_token': None})
    response.status_code = 200
    return response


@app.route('/revoke', methods = ['GET'])
def revoke_token():
    access_token = request.args.get('access_token', None)
    if access_token is None:
        raise UserError('Bad Request.')
    try:
        decoded_access_token = jwt.decode(access_token, BRAVO_ACCESS_SECRET)
    except jwt.InvalidTokenError:
        raise UserError('Bad access token.')
    email = decoded_access_token['email']
    issued_at = datetime.utcfromtimestamp(decoded_access_token['iat'])
    document = get_db().users.find_one({ 'email': email }, projection = {'_id': False})
    if not document:
        raise UserError('Bad access token.')
    revoked_at = document.get('access_token_revoked_at', None)
    if revoked_at is not None and revoked_at > issued_at:
        raise UserError('Bad access token.')
    get_db().users.update_one({ 'email': email }, {'$set': {'access_token_revoked_at': datetime.utcnow()}})
    response = jsonify({'revoked': True})
    response.status_code = 200
    return response


if __name__ == '__main__':   
   app.run(host = '0.0.0.0', port = port, debug = True)
