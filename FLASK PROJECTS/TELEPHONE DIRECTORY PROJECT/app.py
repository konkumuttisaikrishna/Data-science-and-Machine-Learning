from flask import Flask, render_template, request,redirect,url_for
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
import os

app = Flask(__name__)

basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'contact.sqlite')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
Migrate(app, db)

class Contacts(db.Model):
    __tablename__ = 'contacts'
    id = db.Column(db.Integer, primary_key = True)
    name = db.Column(db.Text)
    phone = db.Column(db.Integer)

    def __init__(self, name, phone):
        self.name = name
        self.phone = phone
    def __repr__(self):
        return "{}  {}".format(self.name,self.phone)


@app.route("/index")
def index():
    return render_template("index.html")

@app.route("/add", methods=['GET','POST'])
def add():
    if request.method == "POST":
        name = request.form.get("enter_name")
        phone = request.form.get("enter_phone_number")
        logs = Contacts(name,phone)
        db.session.add(logs)
        db.session.commit()
        print("Contact added Sucessfully")
        print(name, phone)
    return render_template("add.html")

@app.route("/display")
def display():
    info= Contacts.query.all()
    return render_template("display.html",items=info)

@app.route("/search",methods=["GET","POST"])
def search():
    inp1 = request.form.get("input")
    search = Contacts.query.filter_by(name=inp1).all()
    return render_template("search.html",search1=search)

@app.route("/delete",methods=["GET","POST"])
def delete():
    inp1 = request.form.get("input1")
    log =Contacts.query.filter_by(name=inp1).first()
    if log:
        db.session.delete(log)
        db.session.commit()
        return render_template("delete.html")
    return render_template("delete.html")

if __name__ == "__main__":
    db.create_all()
    app.run(debug=True)
