from flask import Flask, request
from flask_httpauth import HTTPBasicAuth
from werkzeug.security import generate_password_hash, check_password_hash
import pymongo


app = Flask(__name__)
# source https://flask-httpauth.readthedocs.io/en/latest/ for all basic auth
auth = HTTPBasicAuth()

# setup pymongo
# mongoDB is just logs
mongo = pymongo.MongoClient()
# make client variable and pick collection (db)
# cursor is used to add commands to database (cursor lets us insert and remove from database)
dbUsers = mongo.userData  # big list with 2 cursors (dbUsers is big list)

cursorUser = dbUsers.user  # two smaller lists
cursorNurse = dbUsers.nurse

userList = cursorNurse.find()
if len(list(userList)) == 0:
    defaultUser = {"username": "admin",
                   "password": generate_password_hash("12345")}
    cursorNurse.insert_one(defaultUser)


@auth.verify_password
def verify_password(username, password):
    for item in cursorNurse.find():
        if item['username'] == username and check_password_hash(item['password'], password):
            return username

 # check every user in the nursedatabase
 # if there is a user with matching username/pw, return their username


@app.route('/AddUser', methods=['POST'])
@auth.login_required
def add_user():
    user = request.form['user']
    data = {"key": user}
    cursorUser.insert_one(data)
    return "success"


# checks to make sure nurse's log in WORKS
@app.route('/Authenticate', methods=['GET'])
@auth.login_required
def authenticate():
    return "success"


# anyone can use without username / pw
@app.route('/CheckUser', methods=['GET'])
def check_user():
    user = request.args['user']
    found = cursorUser.find({'key': user})
    if found:
        return "success"
    else:
        return "failure"


@app.route('/AddNurse', methods=['POST'])
@auth.login_required
def add_nurse():
    new_nurse = request.form['new_nurse']
    new_pass = request.form['new_pass']
    data = {"username": new_nurse,
            "password": generate_password_hash(new_pass)}
    cursorNurse.insert_one(data)
    return "success"


@auth.error_handler
def errorHandler(status):
    return "error"


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8085)
    # services; 0.0.0.0 whatever IP
